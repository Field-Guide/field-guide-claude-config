# Sync System Hardening And Harness Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Stand up a harness-gated hardened sync subsystem — local Docker + staging Supabase proving grounds, full-surface correctness matrix, five-layer Sentry observability, property-based concurrency + soak, targeted sync engine rewrite to the 2-second ceiling, and a persistent CI gate — so every future sync-touching PR is provable before it reaches production.

**Spec:** `.claude/specs/2026-04-16-sync-system-hardening-and-harness-spec.md`
**Tailor:** `.claude/tailor/2026-04-16-sync-system-hardening-and-harness/`

**Architecture:** Seven-phase sequential single-track (Scope Option 1, safety-first). Each phase lands as one or more focused PRs that can be reverted independently. The sync engine rewrite preserves `SyncCoordinator` as single entrypoint, adapter-registration order, `SyncErrorClassifier` classification semantics, `SyncStatus` transport authority, `change_log` trigger ownership, `sync_control.pulling` suppression bracket, RLS company-scope via `get_my_company_id()`, `42501` non-retryable classification, and driver contract parity enforced by the `screen_registry_contract_sync` custom lint.

**Tech Stack:** Flutter + `provider` + `ChangeNotifier` (no Riverpod). Feature-first `data/domain/presentation/di/` split; pure-Dart domain. Supabase (local Docker + Pro-tier staging). `glados` for property-based concurrency (new). Sentry Flutter + Supabase Log Drains. PowerShell wrappers for all Flutter/Dart/supabase CLI invocations.

**Blast Radius:** Touches `lib/features/sync/**`, `lib/features/auth/**`, `lib/features/projects/**`, `lib/core/logging/**`, `lib/core/config/sentry_*`, `lib/core/driver/**`, `lib/main.dart`, `supabase/migrations/**`, `supabase/seed.sql`, `supabase/functions/_shared/**`, `scripts/**`, `.github/workflows/**`, `tools/**`, `pubspec.yaml`, `integration_test/sync/**` (new tree), `test/harness/**` (new tree). Multi-PR rollback: each phase reverts independently; MVP ships only when all five ship-bar conditions from Scope success criterion 11 hold simultaneously.

## Phase Ranges

| Phase | Name | Start | End |
| --- | --- | --- | --- |
| 1 | Local Docker Supabase + Seeded Fixture | 30 | 159 |
| 2 | Harness Driver Skeleton | 162 | 307 |
| 3 | Full-Surface Correctness Matrix | 310 | 428 |
| 4 | Logging Event-Class Audit + Sentry Dual-Feed | 431 | 612 |
| 5 | Property-Based Concurrency + Soak | 615 | 750 |
| 6 | Sync Engine Rewrite (Targeted Hotspots + Flashing Fix) | 753 | 932 |
| 7 | Staging Supabase + CI Gate + GitHub Auto-Issue Policy | 935 | 1072 |

---

## Phase 1: Local Docker Supabase + Seeded Fixture

### Goal

Boot local Docker Supabase from the current 71 migrations with a deterministic, seeded multi-project fixture (one company, ~10–20 `auth.users` with matching `user_profiles`, **15 projects** (p001..p015), a `project_assignments` matrix that exercises cross-role leakage, and FK-connected child rows across `daily_entries`, `bid_items`, `personnel_types`, `equipment`, `contractors`, `locations`, `photos`). The output is a reproducible local environment the Phase 2 harness can authenticate into.

### Prerequisites

- Supabase CLI installed and on `PATH`. `supabase/config.toml` already declares `project_id = "Field_Guide_App"`, API port `54321`, DB port `54322`, `major_version = 17`.
- `supabase/migrations/` contains the full 71 migration set, beginning with `20260101000000_bootstrap_base_schema.sql` and ending with `20260412150000_add_company_cloud_ocr_config.sql`. Rollbacks live in `supabase/rollbacks/`.
- `supabase/seed.sql` currently contains only a header comment (no seeded data). This phase fills it.
- PowerShell is available (`pwsh`). Per CLAUDE.md, all Flutter/Dart/supabase CLI invocations must go through PowerShell wrappers; never invoke the `supabase` CLI directly from Git Bash.

### Files Created

- `supabase/seed.sql` — Replaces the existing header-only file with the deterministic seed fixture (company, `auth.users`, `user_profiles`, projects, `project_assignments`, entries, bid items, personnel types, equipment, contractors, locations, photos). Service-role-inserted to bypass RLS during the seed. No `sync_control` bracketing — the `sync_control` table is local SQLite only; Postgres has no `change_log` triggers to suppress.
- `tools/supabase_local_reset.ps1` — PowerShell wrapper around `supabase db reset` that boots the local stack if needed, applies all 71 migrations in order, and runs `supabase/seed.sql`.
- `tools/supabase_local_start.ps1` — PowerShell wrapper around `supabase start` for cases where the implementer only wants to bring the stack up without a reset.

### Files Modified

- None expected. `supabase/config.toml` is left untouched. Contingency: if `supabase start` reports a port collision on `54321` or `54322`, the implementer records the collision and bumps the ports in a follow-up — but this plan does not pre-modify `config.toml`.
- `.env.secret` (developer-local, not in repo) may be set for `SUPABASE_DATABASE_URL` if the implementer uses a non-default local URL. Not a tracked file change.

### Files Preserved (Must Not Regress)

- All 71 migrations under `supabase/migrations/`. The seed must be migration-compatible — no forward schema assumptions, no hand-patched columns.
- `supabase/rollbacks/` — unchanged. `scripts/validate_migration_rollbacks.py` and `scripts/check_changed_migration_rollbacks.py` must stay green.
- `supabase/config.toml` — `project_id`, API port, DB port, schemas, `extra_search_path`, `max_rows = 1000` remain as-is.
- `supabase/functions/daily-sync-push`, `supabase/functions/google-cloud-vision-ocr`, `supabase/functions/google-document-ai-ocr` — untouched.
- RLS policies established by the migrations. The seed inserts via service role; it does not `ALTER POLICY` anything.
- `change_log` remains trigger-owned on the client side (not a Postgres concern). The seed must not insert into any `change_log` table on either side.
- `is_builtin = 1` rows on `inspector_forms` are server-seeded by existing migrations; the harness seed must not add client-visible builtins (per `tablesWithBuiltinFilter = ['inspector_forms']` in `lib/core/database/schema/sync_engine_tables.dart`).

### Step-by-step Implementation

1. Create `tools/supabase_local_start.ps1` as a thin PowerShell wrapper. Contents:
   - `$ErrorActionPreference = 'Stop'`.
   - Resolve the repo root (`Split-Path -Parent $PSScriptRoot`).
   - `Push-Location` to the repo root, run `supabase start`, then `Pop-Location` in a `finally` block.
   - Exit non-zero if the CLI exits non-zero.

2. Create `tools/supabase_local_reset.ps1`. Contents:
   - `$ErrorActionPreference = 'Stop'`.
   - **Host guard (first statement):** assert `$env:SUPABASE_DATABASE_URL` contains `127.0.0.1` or `localhost` (or is empty, in which case the CLI uses the local-Docker default). Abort with a clear error if the URL points at any `*.supabase.co` host. The seed password is `HarnessPass!1`; this guard prevents the seed from ever provisioning predictable accounts on staging or prod.
   - Resolve the repo root.
   - `Push-Location` to the repo root.
   - Run `supabase db reset` (the CLI applies every file in `supabase/migrations/` in timestamp order, then executes `supabase/seed.sql`).
   - `Pop-Location` in a `finally` block.
   - Exit non-zero on CLI failure so CI catches migration regressions.

3. Author `supabase/seed.sql` as a deterministic, idempotent seed script. Use fixed UUIDs (hand-picked constant UUID literals, not `gen_random_uuid()`) so every reseed produces the same IDs and the harness can reference them directly. Structure the file as:
   - Header comment block stating: "Harness fixture — LOCAL DOCKER ONLY. Seeded via `supabase db reset` via `tools/supabase_local_reset.ps1`, which enforces a `127.0.0.1`/`localhost` host guard. Password `HarnessPass!1` is a known local-only credential and must never reach staging or prod. Service-role context. No `change_log` or `sync_control` interaction — those are local SQLite constructs only."
   - One `INSERT INTO public.companies (id, name, created_at, updated_at) VALUES (...)` for a single fixture company (e.g., id `00000000-0000-0000-0000-000000000001`, name `"Harness Test Co"`).
   - A block of 12 paired `INSERT INTO auth.users` + `INSERT INTO auth.identities` rows — 1 admin, 2 engineer, 1 office_technician, 8 inspector (total 12, satisfying the ≥1 admin, ≥2 engineer, ≥1 office_technician, ≥5 inspector distribution and landing inside the 10–20 band). Direct writes into `auth.users` alone are insufficient — Supabase GoTrue requires a matching `auth.identities` row with `provider='email'` for `signInWithPassword` to succeed; seed both atomically per user. Columns on `auth.users`: `id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data`. Columns on `auth.identities`: `id, user_id, provider_id (= user_id stringified), provider ('email'), identity_data (`jsonb_build_object('sub', user_id::text, 'email', email)`), last_sign_in_at, created_at, updated_at`. Use deterministic UUIDs whose low bits encode the role (e.g., `...-a001` admin, `...-e001`/`...-e002` engineers, `...-o001` office_technician, `...-i001`..`...-i008` inspectors) and emails of the form `admin@harness.test`, `engineer1@harness.test`, `inspector1@harness.test`, etc. Set `email_confirmed_at = now()` so the harness can sign in without a mail flow. Store `encrypted_password` by calling `crypt('HarnessPass!1', gen_salt('bf'))` (the `pgcrypto` extension is already available via earlier migrations).
   - A matching `INSERT INTO public.user_profiles (id, user_id, company_id, role, full_name, is_approved, can_manage_projects, can_edit_field_data, can_manage_project_field_data, created_at, updated_at)` for every `auth.users` row. Use `UserRole` values that map 1:1 to the Dart enum in `lib/features/auth/data/models/user_role.dart`: `'admin'`, `'engineer'`, `'office_technician'`, `'inspector'`. Every profile has `is_approved = true`. Capability flags match what `AuthProvider` exposes: admin/engineer/office_technician get `can_manage_projects = true`; inspector/engineer/office_technician get `can_edit_field_data = true`; engineer/office_technician/admin get `can_manage_project_field_data = true`. Do not fabricate new capability columns — use only columns present after the 71 migrations.
   - **Deprecated-viewer fallback row.** Spec Scope line 43 requires the deprecated-viewer fallback path to be exercised. The `20260317100000_remove_viewer_role.sql` migration removes `viewer` from the enum, making the row unreachable at the schema layer post-migration — so the seed **must not** insert a `viewer` profile. Instead, add an inline SQL comment in `supabase/seed.sql` right after the `user_profiles` block: `-- Deprecated 'viewer' role is unreachable after 20260317100000_remove_viewer_role.sql; fallback path is exercised in auth_matrix_test.dart via a JWT stub, not via seeded rows.` The matrix test for viewer fallback lives in Phase 3.
   - A block of 15 `INSERT INTO public.projects (id, company_id, name, created_at, updated_at, ...)` rows (project ids `...-p001`..`...-p015`). Use only columns declared by the migrations. No `sync_status` column (prohibited by `no_sync_status_column` lint and by the sync rules in CLAUDE.md).
   - A `project_assignments` matrix sized so that:
     - Every inspector (i001..i008) has at least one project they ARE assigned to.
     - Every inspector has at least one project they are NOT assigned to (for cross-role leakage tests in Phase 3) — with 15 projects and per-inspector assignment counts between 2 and 3, each inspector has ≥12 unassigned projects.
     - Concrete inspector matrix (pairs share a scope so two inspectors can hit the same rows in concurrent tests):
       - i001, i002 → {p001, p002, p003}
       - i003, i004 → {p004, p005, p006}
       - i005, i006 → {p007, p008, p009}
       - i007       → {p010, p011}
       - i008       → {p012, p013}  (i008 is NOT on p001 at seed time; the defect-c wizard adds it)
     - Leave {p014, p015} unassigned to any inspector (admin/engineer/office_technician-only visibility check).
     - Assign both engineers (e001, e002) to p001..p013 (company-wide engineer scope for the project-bearing subset).
     - Assign office_technician (o001) to {p014, p015} (exercises the office-technician-only visibility leg).
     - Admin (a001) gets no explicit assignment row (admin access comes through role, not `project_assignments`).
     - **Defect (c) fixture tie-in:** inspector8 (i008) serves as the "new-user-c" fixture consumed by `integration_test/sync/matrix/assignments_matrix_test.dart`. Set i008's `auth.users.created_at` and `user_profiles.created_at` to a timestamp strictly AFTER p001's `created_at`. Project p001 serves as "old-project-c" (it predates i008 and is outside i008's seed-time assignment set, so the wizard flow is the only path that binds them). The Phase 3 repro exercises "assign i008 to p001 via the assignment wizard"; the Phase 6 fix in `lib/features/sync/engine/enrollment_handler.dart` flips it to passing.
   - Under projects p001, p002, p003 (i001/i002's scope, which also contains the defect-c target p001): seed an FK-connected child graph to exercise the FK chain exactly the way `scripts/validate_sync_adapter_registry.py` expects. Remaining projects (p004..p015) stay free of child rows in Phase 1; Phase 3 matrix tests seed additional rows on demand via `test/helpers/sync/sync_test_data.dart`. Seed in strict FK-parent-first order matching the registry sequence in `lib/features/sync/engine/sync_registry.dart`:
     1. `locations` (≥2 per seeded project)
     2. `contractors` (≥2 per seeded project)
     3. `equipment` (≥2 per seeded project)
     4. `bid_items` (≥2 per seeded project)
     5. `personnel_types` (≥2 per seeded project)
     6. `daily_entries` (≥1 per seeded project, referencing a seeded location)
     7. `photos` (≥1 per seeded daily_entry; use deterministic storage-path strings — do not insert into storage, the seed only touches DB rows)
   - Leave `inspector_forms`, `form_responses`, `pay_applications`, `entry_exports`, `form_exports`, `export_artifacts`, `documents`, `support_tickets`, `consent_records`, `signature_files`, `signature_audit_log`, `todo_items`, `calculation_history`, `entry_equipment`, `entry_quantities`, `entry_contractors`, `entry_personnel_counts` un-seeded in Phase 1 — the spec scope only mandates the FK chain above. Phase 3 matrix tests will seed these on demand via the existing `test/helpers/sync/sync_test_data.dart` factories.
   - Do NOT insert into any `change_log` table. Do NOT touch `sync_control` (it does not exist server-side). Do NOT set `is_builtin = 1` on any seeded row.
   - Wrap the entire seed body in a single `BEGIN; ... COMMIT;` block so a mid-seed failure rolls back cleanly.
   - Make every `INSERT` idempotent with `ON CONFLICT (id) DO NOTHING` so repeated `supabase db reset` calls (which already drop first, but a `psql`-only reapply path may exist in CI) remain safe.

4. Verify the seed boots cleanly from a fresh state:
   - `pwsh -File tools/supabase_local_reset.ps1` from the repo root.
   - Expect: "Applying migration..." log lines for 71 migrations, then "Seeding data from supabase/seed.sql..." without error.

5. **Sign-in smoke (critical gate for Phase 2 handoff).** Before declaring Phase 1 done, run a minimal sign-in verification: `curl -X POST "$LOCAL_SUPABASE_URL/auth/v1/token?grant_type=password" -H "apikey: $LOCAL_ANON" -H "Content-Type: application/json" -d '{"email":"admin@harness.test","password":"HarnessPass!1"}'` must return a non-null `access_token`. Repeat for one inspector (`inspector1@harness.test`). If either returns `400 invalid_credentials`, the `auth.identities` rows are missing or malformed — fix the seed before Phase 2 begins. This smoke catches the GoTrue identity-row footgun that a `psql` probe cannot detect.

6. Verify the fixture content matches the matrix with `psql`-style probes (run via `supabase db query` or `psql $SUPABASE_DATABASE_URL`):
   - `SELECT role, COUNT(*) FROM public.user_profiles GROUP BY role;` returns admin=1, engineer=2, office_technician=1, inspector=8.
   - `SELECT COUNT(*) FROM public.projects WHERE company_id = '<harness company id>';` returns 15.
   - `SELECT user_id, COUNT(project_id) FROM public.project_assignments GROUP BY user_id;` shows every inspector on at least one project (i001..i006 on 3 each, i007..i008 on 2 each).
   - `SELECT p.id FROM public.projects p WHERE NOT EXISTS (SELECT 1 FROM public.project_assignments a WHERE a.project_id = p.id AND a.user_id IN (<inspector ids>));` returns exactly `{p014, p015}` (proves unassigned-to-inspectors projects exist for leakage tests).
   - `SELECT project_id FROM public.project_assignments WHERE user_id = '<i008>' AND project_id = '<p001>';` returns zero rows at seed time (the defect-c wizard flow is the binding path).
   - `SELECT l.project_id, COUNT(*) FROM public.locations l GROUP BY l.project_id;` shows ≥2 for each of p001/p002/p003.
   - `SELECT de.project_id, de.location_id FROM public.daily_entries de;` shows each entry's `location_id` refers to a row in `locations` with the same `project_id` (FK chain integrity).
   - `SELECT COUNT(*) FROM public.photos;` returns ≥3 (one per seeded daily entry).

7. Confirm the seed preserves migration compatibility:
   - Run `python scripts/validate_sync_adapter_registry.py` from the repo root. It must still pass — the seed must not introduce a table name that is in `triggeredTables` but missing from an adapter (it only uses existing tables).
   - Run `python scripts/verify_live_supabase_schema_contract.py` against the local Docker URL (`SUPABASE_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:54322/postgres`). It must confirm that registered tables exist, RLS is enabled, and RLS policy count > 0 — all already true because the seed does not alter schema.

8. **Create `scripts/validate_harness_fixture_parity.py`** — stdlib-only Python validator (per `patterns/python-ci-validator.md`). Parses:
   - `supabase/seed.sql` — extracts user UUIDs/emails/roles, project UUIDs, and `project_assignments (user_id, project_id)` tuples.
   - `integration_test/sync/harness/harness_fixture_cursor.dart` (created in Phase 2) — extracts `HarnessFixtureIds` constants and the `projectsAssignedTo` matrix.
   Emits dashed error list on drift; exits 1. Wired into CI in the Phase 4 workflow edits (see Phase 4 step 15). For Phase 1 the script is a stub that prints a one-line message noting the harness-side fixture does not yet exist; it becomes enforcing as soon as Phase 2 lands.

### Exit Criteria

- `pwsh -File tools/supabase_local_reset.ps1` boots the local stack, applies all 71 migrations, and executes `supabase/seed.sql` end-to-end without error. Host guard aborts cleanly when `$env:SUPABASE_DATABASE_URL` points at a non-local host.
- Sign-in smoke (step 5) returns an `access_token` for `admin@harness.test` and `inspector1@harness.test` against the local GoTrue endpoint.
- Manual `psql` probe (step 6) confirms: 1 company, 12 `auth.users`, matching 12 `auth.identities` with `provider='email'`, role distribution 1/2/1/8, 15 projects, assignment matrix covers "every inspector IS on at least one project" and "every inspector is NOT on at least one project", {p014, p015} unassigned to any inspector, FK chain integrity across locations/contractors/equipment/bid_items/personnel_types/daily_entries/photos for the seeded subset (p001..p003), i008 `created_at` strictly after p001 `created_at` and no seed-time `project_assignments` row pairs (i008, p001) (defect-c fixture tie-in).
- `scripts/validate_sync_adapter_registry.py` and `scripts/verify_live_supabase_schema_contract.py` (local URL) stay green.
- `scripts/validate_harness_fixture_parity.py` exists (stub in Phase 1; enforcing after Phase 2).
- No `sync_status` column referenced anywhere in `supabase/seed.sql` (ripgrep must return zero matches for `sync_status` in the seed).
- No `is_builtin = 1` inserts anywhere in `supabase/seed.sql`.
- No `viewer` role inserted anywhere in `supabase/seed.sql` (the enum no longer accepts it; the comment in the `user_profiles` block documents this).

### Local Verification

- `pwsh -File tools/build.ps1 -- analyze` (the repo's PowerShell wrapper for `flutter analyze`) stays green. Phase 1 introduces no Dart changes, so this is a regression gate only.
- `pwsh -File tools/supabase_local_reset.ps1` completes with exit code 0.
- `python scripts/validate_sync_adapter_registry.py` exits 0.
- `python scripts/verify_live_supabase_schema_contract.py` (with `DATABASE_URL` pointing at the local Docker Postgres) exits 0.
- `rg -n "sync_status" supabase/seed.sql` returns zero matches.
- `rg -n "is_builtin\s*=\s*1" supabase/seed.sql` returns zero matches.

---

## Phase 2: Harness Driver Skeleton

### Goal

Stand up a harness tree under `integration_test/sync/harness/` that can authenticate a real Flutter client as any of the four seeded roles (admin, engineer, office_technician, inspector) against the local Docker Supabase from Phase 1, drive the app through the existing driver HTTP endpoints, and assert cross-role RLS invariants against real server responses. Add a small `test/harness/` unit-speed tree for driver-less validation of the harness helpers themselves.

### Prerequisites

- Phase 1 complete. `supabase/seed.sql` produces the deterministic fixture and the local stack boots via `pwsh -File tools/supabase_local_reset.ps1`.
- Known fixture identities from Phase 1 (emails `admin@harness.test`, `engineer1@harness.test`, `engineer2@harness.test`, `office_technician@harness.test`, `inspector1@harness.test` .. `inspector8@harness.test`; password `HarnessPass!1`; deterministic UUIDs).
- Existing driver HTTP surface from `lib/core/driver/driver_diagnostics_handler.dart`:
  - `GET /diagnostics/screen_contract`
  - `GET /diagnostics/sync_transport`
  - `GET /diagnostics/sync_runtime`
- Existing `SyncCoordinator` entrypoint at `lib/features/sync/application/sync_coordinator.dart:221` (`syncLocalAgencyProjects({SyncMode, bool recordManualTrigger, bool requireDirtyScopes})`).
- Existing `AuthProvider` / `AuthService` seams at `lib/features/auth/presentation/providers/auth_provider.dart` (role getters `isAdmin`, `isEngineer`, `isOfficeTechnician`, `isInspector`; `authStateChanges` subscription at line 101).
- Existing assignment-scope store at `lib/features/sync/engine/synced_scope_store.dart` — the harness reads `SyncedScopeStore.getActiveAssignmentProjectIds` for "what projects is this user enrolled to sync".
- Existing `TestingKeys` registry at `lib/shared/testing_keys/testing_keys.dart`. No hardcoded `Key('...')` is permitted (enforced by the `test_quality` lint rules and by CLAUDE.md's testing rule).
- Existing fixture helpers at `test/helpers/sync/sync_test_data.dart` (`SyncTestData` static map factories, `seedFkGraph(Database)` for client-side SQLite seeding). The harness reuses these where applicable and does not fork them.

### Files Created

- `integration_test/sync/harness/harness_auth.dart` — Sign-in helpers keyed to the Phase 1 fixture (one function per role: `signInAsAdmin`, `signInAsEngineer`, `signInAsOfficeTechnician`, `signInAsInspector({required int inspectorIndex})`). Uses the local Docker Supabase URL + anon key; never points at prod. All calls drive through `AuthProvider` / `AuthService` seams — never through `SyncEngine` directly (per the Pattern doc and CLAUDE.md's "Use `SyncCoordinator` as the sync entrypoint" rule).
- `integration_test/sync/harness/harness_driver_client.dart` — Thin HTTP wrapper around the three read-only diagnostic routes. Exposes `Future<Map<String, dynamic>> fetchScreenContract()`, `fetchSyncTransport()`, `fetchSyncRuntime()`. No mutation endpoints. No new driver routes are added in Phase 2 — the harness is a read-only consumer.
- `integration_test/sync/harness/harness_assertions.dart` — Cross-role visibility invariant helpers:
  - `Future<void> assertInspectorSeesOnlyAssigned({required HarnessAuth auth, required HarnessFixtureCursor fixture})` — queries Supabase via the signed-in client's `select()` and asserts the returned project list equals the fixture's expected assignment set for that inspector.
  - `Future<void> assertNoCrossRoleLeakage({required HarnessAuth auth, required HarnessFixtureCursor fixture})` — signs in as each inspector in turn and verifies none of them sees a project that belongs to a different inspector's exclusive set.
  - `assertLocalScopeMatchesServerAssignment` is **not** added in Phase 2 — the diagnostic route needed to surface `SyncedScopeStore.getActiveAssignmentProjectIds` is deferred to Phase 3 (which adds it together with the matching `screen_contract_registry.dart` + `screen_registry.dart` + `TestingKeys` counterparts in one PR, per the `screen_registry_contract_sync` lint). Phase 2 asserts only what the existing `/diagnostics/sync_runtime` publishes (`dirtyScopes[]`, `stateFingerprint`).
- `integration_test/sync/harness/harness_fixture_cursor.dart` — Walks the Phase 1 seeded fixture. Loads the deterministic UUIDs declared in `supabase/seed.sql` (hard-coded as constants mirrored from the SQL file — single source of truth: a `HarnessFixtureIds` class that the SQL comments reference for cross-check). Exposes `Iterable<String> projectsAssignedTo(String userId)`, `Iterable<String> projectsNotAssignedTo(String userId)`, `Iterable<String> inspectorUserIds`, etc. Read-only; no mutation of the fixture.
- `test/harness/harness_auth_helpers_test.dart` — Unit-speed test (no driver, no Flutter integration binding) that validates `HarnessFixtureIds` constants match the fixture counts from the spec (1 admin, 2 engineer, 1 office_technician, 8 inspector; 15 projects) and that the `HarnessAuth` helper exposes the four role entrypoints with correct signatures. Does not hit Supabase.
- `test/harness/harness_assertions_test.dart` — Unit-speed test that feeds `HarnessAssertions` a fake `HarnessFixtureCursor` and fake server-query result to confirm the leakage / scope-mismatch detection logic actually fires when the inputs diverge. No live HTTP, no live Supabase.

### Files Modified

- `lib/core/driver/driver_data_sync_handler.dart` — Read-only consumer. **No route additions in Phase 2.** If Phase 3's correctness matrix later proves a new inspection key is required (e.g., `inspector_visible_project_count` surfaced through `/diagnostics/screen_contract`), that change lands in Phase 3 along with its matching `screen_contract_registry.dart` + `screen_registry.dart` + `TestingKeys` + targeted test updates in the same PR (as required by the `screen_registry_contract_sync` custom lint). Phase 2 makes no such addition.
- `lib/core/driver/screen_contract_registry.dart` — Same rule. Not modified in Phase 2. Any new state key lands in the phase that requires it.
- `lib/shared/testing_keys/testing_keys.dart` — Same rule. Not modified in Phase 2. The harness consumes the existing registry; it does not add keys pre-emptively.

Invariant that must be preserved by any future change to these files: every `TestingKeys` addition is accompanied by a matching `ScreenContract` entry and a matching `screenRegistryEntries` entry in the same PR. The `screen_registry_contract_sync` lint rule (in `fg_lint_packages/field_guide_lints/lib/architecture/rules/screen_registry_contract_sync.dart`) catches drift.

### Files Preserved (Must Not Regress)

- `lib/core/driver/driver_diagnostics_handler.dart` — No existing route is renamed or removed. `DriverDiagnosticsRoutes.screenContract`, `syncTransport`, `syncRuntime` keep their current paths.
- `lib/core/driver/screen_registry.dart`, `screen_contract_registry.dart`, `flow_registry.dart` — All 39 screen registry entries and 32 screen contract entries preserved. No rename, no removal.
- `lib/features/sync/application/sync_coordinator.dart` — `SyncCoordinator` remains the single sync entrypoint. The harness never calls `SyncEngine.pushAndPull`, `pushOnly`, or `pullOnly` directly.
- `lib/features/sync/engine/sync_registry.dart` — `registerSyncAdapters()` registration order unchanged. The harness uses `SyncRegistry.instance` (per the non-obvious invariant flagged in `ground-truth.md`: background + foreground share the same registry).
- `test/helpers/sync/sync_test_data.dart` — `SyncTestData` factories and `seedFkGraph(Database)` remain the client-side fixture seam. Phase 2 helpers reuse them where applicable. No fork.
- `SyncErrorClassifier` ownership of sync error classification. `42501` stays non-retryable (harness assertions may read it via `/diagnostics/sync_transport` `lastRun.rlsDenials`, but do not re-implement classification).
- `SyncStatus` as transport-state source of truth. Harness reads it through `/diagnostics/sync_transport`; does not introduce a parallel state.

### Step-by-step Implementation

1. Create the `integration_test/sync/harness/` directory (no existing `integration_test/sync/` tree — this is new).

2. Author `integration_test/sync/harness/harness_fixture_cursor.dart`:
   - Define `class HarnessFixtureIds` with `static const` String fields for every deterministic UUID seeded in `supabase/seed.sql` (`companyId`, `adminUserId`, `engineer1UserId`, `engineer2UserId`, `officeTechnicianUserId`, `inspector1UserId` .. `inspector8UserId`, `project1Id` .. `project15Id`). The values must match the SQL exactly; add a doc comment at the top of both files cross-referencing each other as the source-of-truth pair. `scripts/validate_harness_fixture_parity.py` (Phase 1 step 8) is the enforcement layer for drift.
   - Define `class HarnessFixtureCursor` with pure-Dart methods:
     - `Set<String> projectsAssignedTo(String userId)` — returns the assignment matrix from Phase 1 step 3: i001/i002 → {p001, p002, p003}; i003/i004 → {p004, p005, p006}; i005/i006 → {p007, p008, p009}; i007 → {p010, p011}; i008 → {p012, p013}; e001/e002 → {p001..p013}; o001 → {p014, p015}; admin → empty (admin visibility is role-based, not via `project_assignments`).
     - `Set<String> projectsNotAssignedTo(String userId)` — complement within the 6-project set.
     - `List<String> get inspectorUserIds`, `List<String> get engineerUserIds`, `String get officeTechnicianUserId`, `String get adminUserId`.
     - `Set<String> get allProjectIds`.
   - No Flutter imports in this file (it is pure Dart). No SDK calls. This lets `test/harness/*` import it at unit-test speed.

3. Author `integration_test/sync/harness/harness_auth.dart`:
   - Import `package:supabase_flutter/supabase_flutter.dart`.
   - Import the existing `AuthProvider` from `lib/features/auth/presentation/providers/auth_provider.dart` so sign-in flows the same state-change path the production app uses (`_authService.authStateChanges` listener at line 101 of `auth_provider.dart`).
   - Define `class HarnessAuthConfig` with constants: `supabaseUrl` defaults to `http://127.0.0.1:54321` and may be overridden via `--dart-define=HARNESS_SUPABASE_URL` (for the Phase 7 staging gate); `supabaseAnonKey` read via `--dart-define=HARNESS_SUPABASE_ANON_KEY` (baked at build time) or a local-dev default; `password` (`'HarnessPass!1'` — the seed password from Phase 1, only ever provisioned on local Docker per Phase 1's host guard).
   - **URL allowlist guard.** Replace any substring check with an allowlist assertion: `assert(supabaseUrl == 'http://127.0.0.1:54321' || supabaseUrl == const String.fromEnvironment('STAGING_SUPABASE_URL'));`. This both (a) blocks prod (`*.supabase.co` other than staging) and (b) reconciles with Phase 7 staging reuse. `STAGING_SUPABASE_URL` is dart-defined by the staging CI workflow — never read from `Platform.environment` so it cannot silently drift at runtime. Additionally assert `!Platform.environment.containsKey('STAGING_SUPABASE_SERVICE_ROLE_KEY')` to refuse to run if the service-role key was mis-injected into the harness process env (defense against the service-role-bypasses-RLS failure mode named in Phase 7).
   - Define `class HarnessAuth`:
     - Constructor takes an injected `SupabaseClient` + `AuthProvider`.
     - `Future<void> signInAsAdmin()` — calls `supabaseClient.auth.signInWithPassword(email: 'admin@harness.test', password: config.password)`, awaits `authProvider.authStateChanges` emitting a non-null user, then asserts `authProvider.isAdmin == true`.
     - `Future<void> signInAsEngineer({int engineerIndex = 1})` — same shape; engineer1 or engineer2.
     - `Future<void> signInAsOfficeTechnician()` — same shape.
     - `Future<void> signInAsInspector({required int inspectorIndex})` — `inspectorIndex` in 1..8. Asserts `authProvider.isInspector == true`.
     - `Future<void> signOut()` — calls `supabaseClient.auth.signOut()`; awaits `authProvider.currentUser == null`.
   - All assertions are over `AuthProvider` role getters, not over raw JWT claims — keeps the harness aligned with the production role resolution seam.

4. Author `integration_test/sync/harness/harness_driver_client.dart`:
   - Thin wrapper over `package:http`. Base URL defaults to `http://127.0.0.1:<driverPort>` (driver port is discovered from the existing `tools/wait-for-driver.ps1` conventions; the harness accepts it via constructor).
   - `Future<Map<String, dynamic>> fetchScreenContract()` — `GET /diagnostics/screen_contract`, returns the decoded JSON body (shape: `{route, rootPresent, actions, states, seedArgs, ...}` per `source-excerpts/by-concern.md`).
   - `Future<Map<String, dynamic>> fetchSyncTransport()` — `GET /diagnostics/sync_transport`, returns the `{transportHealth, lastRun: {pushed, pulled, errors, rlsDenials, durationMs, completedAt, wasSuccessful}}` payload.
   - `Future<Map<String, dynamic>> fetchSyncRuntime()` — `GET /diagnostics/sync_runtime`, returns `{lastRequestedMode, lastRunHadDirtyScopesBeforeSync, stateFingerprint, dirtyScopeCount, dirtyScopes}`.
   - No POST endpoints. No mutation. The class is explicitly read-only.

5. Author `integration_test/sync/harness/harness_assertions.dart`:
   - `Future<void> assertInspectorSeesOnlyAssigned({required HarnessAuth auth, required HarnessFixtureCursor fixture, required int inspectorIndex, required SupabaseClient supabaseClient})`:
     - Call `auth.signInAsInspector(inspectorIndex: inspectorIndex)`.
     - Query `supabaseClient.from('projects').select('id')` — this is a real RLS-gated call.
     - Collect the returned project ids into a `Set<String>`.
     - Compute the expected set from `fixture.projectsAssignedTo(inspectorUserIdFor(inspectorIndex))`.
     - `expect(returned, equals(expected))`.
     - On inequality, include the fixture's expected set and the returned set in the failure message. No silent fallbacks.
   - `Future<void> assertNoCrossRoleLeakage({required HarnessAuth auth, required HarnessFixtureCursor fixture, required SupabaseClient supabaseClient})`:
     - For each inspector index 1..8, sign in, query `projects`, ensure the returned set is disjoint from every other inspector's exclusive-only set (i.e., inspector1's list must not contain any project that fixture says belongs only to inspector5..8's assignment group).
     - Sign out between iterations.
   - `assertLocalScopeMatchesServerAssignment` is **deferred to Phase 3**. Phase 3 publishes `activeAssignmentProjectIds` on `/diagnostics/sync_runtime` alongside the matching `screen_contract_registry.dart` + `screen_registry.dart` + `TestingKeys` additions in a single PR (per the `screen_registry_contract_sync` lint). Until that diagnostic field exists, Phase 2 omits the helper entirely rather than ship a helper whose contract the route cannot satisfy.

6. Create `test/harness/` directory. Author `test/harness/harness_auth_helpers_test.dart`:
   - Unit test. Imports `package:flutter_test/flutter_test.dart` and the pure-Dart `harness_fixture_cursor.dart`. No `integration_test` import, no `SupabaseClient` construction.
   - `test('HarnessFixtureIds matches spec role distribution', () { ... })` — asserts `fixture.inspectorUserIds.length == 8`, `fixture.engineerUserIds.length == 2`, `fixture.allProjectIds.length == 15`, and the admin/office_technician ids are non-empty.
   - `test('projectsAssignedTo + projectsNotAssignedTo partition allProjectIds', () { ... })` — for every seeded user id, the union equals `allProjectIds` and the intersection is empty.
   - `test('every inspector has at least one assigned project', () { ... })` and `test('every inspector has at least one unassigned project', () { ... })` — proves the leakage-test precondition holds for Phase 3.

7. Author `test/harness/harness_assertions_test.dart`:
   - Unit test using a hand-rolled fake `SupabaseClient`-like seam injected into `HarnessAssertions`. The fake is a closure `Future<List<Map<String, dynamic>>> Function(String table)` so the assertion file takes a functional seam rather than a mocked class. (Per CLAUDE.md "Test real behavior, not mock presence" and "Prefer real production seams over large mock stacks" — the seam is the narrowest functional type.)
   - `test('assertInspectorSeesOnlyAssigned passes when returned set equals expected', () async { ... })`.
   - `test('assertInspectorSeesOnlyAssigned fails with a clear message when returned set differs', () async { ... })` — expects a failure whose message names both the expected and returned sets.
   - `test('assertNoCrossRoleLeakage flags when inspector1 sees inspector5-only project', () async { ... })` — seeds the fake so inspector1's query returns a project belonging only to the inspector5..8 group; expects the assertion to throw.

8. Verify the harness compiles, analyzes clean, and the unit-speed suite passes (unit-speed verification only — this plan body never runs `flutter test`, as the writing-style rule requires):
   - `pwsh -File tools/build.ps1 -- analyze` — `flutter analyze` through the PowerShell wrapper stays green.
   - `pwsh -File tools/build.ps1 -- custom-lint` (or whichever subcommand the wrapper exposes for `dart run custom_lint`) — custom lints stay green. In particular, `screen_registry_contract_sync` must not fire (because this phase does not modify registries) and `no_sync_hint_rpc_outside_approved_owners` must not fire (because the harness does not call `emit_sync_hint`).
   - `rg -n "Key\\('" integration_test/sync/harness test/harness` returns zero matches (no hardcoded `Key('...')` — per CLAUDE.md testing rule and the `test_quality` lint rules).
   - `rg -n "SyncEngine\\." integration_test/sync/harness` returns zero matches (the harness must go through `SyncCoordinator`, not `SyncEngine` directly).
   - `rg -n "supabase\\.co" integration_test/sync/harness` — substring appearance is permitted ONLY inside the allowlist assertion (which references `STAGING_SUPABASE_URL` by symbol, not by substring); otherwise zero matches expected. The allowlist itself is the enforcement seam, not a `*.co` substring grep.
   - `rg -n "emit_sync_hint" integration_test/sync/harness test/harness scripts supabase/functions` returns zero matches outside `supabase/migrations/**` — the RPC ownership stays on `SyncHintRemoteEmitter`.

9. End-to-end manual smoke (documented here as the exit criterion for Phase 2, not executed via a repo script):
   - Start local Docker Supabase: `pwsh -File tools/supabase_local_start.ps1`.
   - Reset + seed: `pwsh -File tools/supabase_local_reset.ps1`.
   - Start the Flutter driver: `pwsh -File tools/start-driver.ps1`, wait with `pwsh -File tools/wait-for-driver.ps1`.
   - From a Dart REPL or a developer-driver script, instantiate `HarnessAuth`, sign in as each of the four roles, confirm `AuthProvider.isAdmin` / `isEngineer` / `isOfficeTechnician` / `isInspector` flips correctly.
   - For inspector1, call `HarnessAssertions.assertInspectorSeesOnlyAssigned` — the real Supabase `select * from public.projects` returns exactly `{project1Id, project2Id, project3Id}` (the fixture's inspector1 assignment). RLS is enforcing this; the harness is reading real server truth.

### Exit Criteria

- `integration_test/sync/harness/` contains `harness_auth.dart`, `harness_driver_client.dart`, `harness_assertions.dart`, `harness_fixture_cursor.dart`.
- `test/harness/` contains `harness_auth_helpers_test.dart` and `harness_assertions_test.dart`, both passing under the project's standard unit-test runner (verified at Phase 3 gate; not executed in this plan body).
- Harness can authenticate as admin, engineer1, engineer2, office_technician, and each of inspector1..inspector8 against local Docker Supabase with no prod-URL leakage.
- Harness can issue a real `select('*').from('projects')` through the signed-in `SupabaseClient` and assert the returned set equals the Phase 1 fixture's expected assignment set for that user. Cross-role leakage assertion actually fires on a seeded divergence.
- Driver HTTP interface is backward-compatible — no route is renamed or removed; no new route is added unless the matrix proves it necessary (deferred to Phase 3).
- `flutter analyze` and `dart run custom_lint` stay green. `screen_registry_contract_sync`, `no_sync_hint_rpc_outside_approved_owners`, `no_sync_hint_broadcast_subscription_outside_realtime_handler`, `no_client_sync_hint_broadcast_http`, `no_sync_status_column` all remain non-firing.
- `TestingKeys` is the sole source of widget keys referenced anywhere in the harness; no hardcoded `Key('...')` literals.
- `SyncCoordinator` remains the harness's only sync entrypoint. No direct `SyncEngine` invocation anywhere under `integration_test/sync/harness/` or `test/harness/`.

### Local Verification

- `pwsh -File tools/build.ps1 -- analyze` exits 0.
- `pwsh -File tools/build.ps1 -- custom-lint` (or the equivalent wrapper subcommand for `dart run custom_lint`) exits 0.
- `rg -n "Key\\('" integration_test/sync/harness test/harness` — zero matches.
- `rg -n "SyncEngine\\." integration_test/sync/harness test/harness` — zero matches.
- `rg -n "supabase\\.co" integration_test/sync/harness` — zero matches.
- `rg -n "emit_sync_hint" integration_test/sync/harness test/harness` — zero matches (the harness must not call the hint RPC directly; that is owned by `SyncHintRemoteEmitter`).
- `python scripts/validate_sync_adapter_registry.py` exits 0 (Phase 2 touches no adapter files, so this is a regression gate only).


---

## Phase 3: Full-Surface Correctness Matrix

### Goal

Cover every sync-adjacent flow multiplied by every role (`admin`, `engineer`, `officeTechnician`, `inspector`) with zero cross-role visibility violations on any frame. Land deterministic failing repros for the five enumerated defects (a through e). No production code changes — the matrix lands first; Phase 6 fixes.

### Prerequisites

- Phase 1 complete: local Docker Supabase boots from `supabase/config.toml` via `tools/supabase_local_start.ps1` and `tools/supabase_local_reset.ps1`, with `supabase/seed.sql` producing the ~10–20 user, multi-project, role-distributed fixture.
- Phase 2 complete: `integration_test/sync/harness/harness_auth.dart`, `harness_driver_client.dart`, `harness_assertions.dart`, and `harness_fixture_cursor.dart` are in place and can authenticate the four roles against the local Docker Supabase, call `/diagnostics/screen_contract`, `/diagnostics/sync_transport`, and `/diagnostics/sync_runtime`, and assert RLS-real responses.
- `lib/shared/testing_keys/testing_keys.dart` carries every state key referenced by matrix assertions (no hardcoded `Key('...')`).
- `lib/features/sync/engine/synced_scope_store.dart` exposes `SyncedScopeStore.getActiveAssignmentProjectIds` (and `LocalSyncStoreScope.getActiveAssignmentProjectIds`) as the baseline for assigned-project assertions.
- `SyncCoordinator` is reachable through the existing driver endpoints only; matrix tests must not construct a second coordinator.

### Files Created

New subtree `integration_test/sync/matrix/`, one file per feature area:

- `integration_test/sync/matrix/auth_matrix_test.dart` — sign-in / sign-out / token refresh / session expire / role change / `passwordRecovery` for all four roles.
- `integration_test/sync/matrix/projects_matrix_test.dart` — project list visibility, project detail access, role-gated mutations for all four roles.
- `integration_test/sync/matrix/assignments_matrix_test.dart` — assignment wizard mutation flows per role; includes defect (c) "new-user-to-old-project assignment failure" as a failing repro before the Phase 6 fix.
- `integration_test/sync/matrix/entries_matrix_test.dart` — `daily_entries` create / edit / soft-delete / restore per role, with visibility assertions keyed to `SyncedScopeStore.getActiveAssignmentProjectIds`.
- `integration_test/sync/matrix/photos_matrix_test.dart` — photo upload / deletion / visibility across roles.
- `integration_test/sync/matrix/signatures_matrix_test.dart` — `signature_files` and `signature_audit_log` create / read across roles.
- `integration_test/sync/matrix/forms_matrix_test.dart` — `inspector_forms` and `form_responses` for forms 0582B, 1174R, 1126, and IDR across roles; respects `is_builtin=1` skip behavior on `inspector_forms`.
- `integration_test/sync/matrix/pay_apps_matrix_test.dart` — `pay_applications` create / edit / visibility across roles.
- `integration_test/sync/matrix/quantities_matrix_test.dart` — `entry_quantities` and `bid_items` visibility across roles.
- `integration_test/sync/matrix/equipment_matrix_test.dart` — `equipment` and `entry_equipment` across roles.
- `integration_test/sync/matrix/contractors_matrix_test.dart` — `contractors` and `entry_contractors` across roles.
- `integration_test/sync/matrix/personnel_matrix_test.dart` — `personnel_types` and `entry_personnel_counts` across roles.
- `integration_test/sync/matrix/locations_matrix_test.dart` — `locations` create / edit / visibility across roles.
- `integration_test/sync/matrix/todos_matrix_test.dart` — `todo_items` across roles.
- `integration_test/sync/matrix/consent_matrix_test.dart` — `consent_records` create / read across roles.
- `integration_test/sync/matrix/support_matrix_test.dart` — `support_tickets` create / read across roles.
- `integration_test/sync/matrix/documents_matrix_test.dart` — `documents` create / read / delete across roles.
- `integration_test/sync/matrix/exports_matrix_test.dart` — `form_exports`, `entry_exports`, `export_artifacts` (local-only) across roles; confirms these never round-trip via the harness driver.
- `integration_test/sync/matrix/flashing_repro_test.dart` — covers defect (a) inspector sees unassigned projects on refresh, defect (b) flashing metadata when a new project is created, defect (e) single-account refresh bleed. Uses the per-frame capture pattern from source-excerpts "Concern: role-visibility assertion".
- `integration_test/sync/matrix/download_on_click_test.dart` — covers defect (d) download-on-click failure.

### Files Modified

Phase 3 is repro-only for production logic — fixes land in Phase 6. However, the matrix requires two driver-side state additions, which must land with their contract counterparts in the same PR (`screen_registry_contract_sync` lint):

- `lib/core/driver/driver_diagnostics_handler.dart` — extend `_handleSyncRuntime` payload with `activeAssignmentProjectIds: List<String>` (reads from `SyncedScopeStore.getActiveAssignmentProjectIds` through the existing query-service seam). Add a new route `DriverDiagnosticsRoutes.frameCapture = '/diagnostics/frame_capture'` serving a short-lived SSE/polling stream of `{timestamp, activeRoute, visibleRootKeys, stateKeyValues}` tuples for the window duration supplied by the client. Stream closes when the window elapses.
- `lib/core/driver/screen_contract_registry.dart` — add `activeAssignmentProjectIds` to the `stateKeys` list on every screen contract whose Phase 3 matrix reads it (at minimum `ProjectListScreen`).
- `lib/core/driver/screen_registry.dart` — touch if a matrix seed-args path requires a new entry; otherwise untouched.
- `lib/shared/testing_keys/testing_keys.dart` — add `ProjectsTestingKeys.projectListAssignedIdsState` (or equivalent) so the matrix can resolve the surfaced state by key rather than magic string.
- `integration_test/sync/harness/harness_driver_client.dart` — extend with `Future<List<FrameSample>> captureFrames({required Duration duration})` that calls `GET /diagnostics/frame_capture?durationMs=...` and decodes to typed samples. Preserve read-only posture (no mutation endpoints added).
- `integration_test/sync/harness/harness_assertions.dart` — add `Future<void> assertLocalScopeMatchesServerAssignment(...)` now that `activeAssignmentProjectIds` is published.

### Files Preserved (Must Not Regress)

- `test/features/sync/characterization/` — all 15 characterization tests (pull cursor, pull conflict, pull dirty scope, pull scope, pull tombstone, pull trigger suppression, pull upsert, push company_id, push delete, push LWW, push skip, push upsert, realtime hint, retry policy, error classification, sync modes, lifecycle trigger, diagnostics, `SyncStatus` contract). These coexist with the matrix; deletion is case-by-case only when a matrix test proves the same contract more honestly, with the commit message citing the replacement test.
- `lib/core/driver/driver_diagnostics_handler.dart` — routes `/diagnostics/screen_contract`, `/diagnostics/sync_transport`, `/diagnostics/sync_runtime` are read-only consumers for the matrix; no route renames, no new routes in this phase.
- `lib/core/driver/screen_registry.dart`, `lib/core/driver/screen_contract_registry.dart`, `lib/core/driver/flow_registry.dart` — the driver contract surface stays backward-compatible; the `screen_registry_contract_sync` lint stays green.
- `SyncCoordinator`, `SyncEngine`, `SyncErrorClassifier`, `SyncStatus`, `SyncRegistry` adapter order, `change_log` trigger ownership, `sync_control.pulling` suppression bracket, `42501` non-retryable classification — all stay untouched.
- `test/helpers/sync/sync_test_data.dart` — `SyncTestData` map factories and `seedFkGraph` stay intact. The matrix reuses these factories; do not fork them. If a matrix test needs a new shape, extend `SyncTestData` with the new factory method in the same PR as the test that calls it.
- `lib/shared/testing_keys/testing_keys.dart` — `TestingKeys` stays the only source of key values. Never hardcode `Key('...')` in a matrix test.

### Step-by-step Implementation

1. **Matrix harness bootstrap helper.** In `integration_test/sync/matrix/`, add `matrix_test_bootstrap.dart` (plain Dart file — Dart has no file-name library privacy, scope is enforced by import discipline; only matrix files import it). Wraps the Phase 2 harness entrypoints into a single `setUpAll` / `tearDownAll` pair: `harnessAuth.signIn(role:, userId:)`, `harnessDriverClient.connect()`, `harnessFixtureCursor.load()`. Every matrix file imports this bootstrap so per-file boilerplate stays one line.

2. **Per-role parameterization.** Each matrix file defines a top-level `const List<UserRole> _roles = [UserRole.admin, UserRole.engineer, UserRole.officeTechnician, UserRole.inspector];` and iterates every scenario across all four via `group(role.name, () { ... })`. For each role: sign in as a seeded user of that role from the Phase 1 fixture (the fixture guarantees at least 1 admin, at least 2 engineers, at least 1 office_technician, at least 5 inspectors per company), drive the feature flow, assert RLS-real response set.

3. **Cross-role leakage assertion (every matrix file).** Every scenario that renders a sync-backed list must call `harnessAssertions.assertNoCrossRoleLeakage(...)` against the active screen's state keys resolved via `GET /diagnostics/screen_contract`. For inspector-role scenarios, the expected id set is `SyncedScopeStore.getActiveAssignmentProjectIds` intersected with the fixture's enumerated assignments. For admin/engineer/office_technician scenarios, the expected id set is the full company-scoped list for their role. Any id outside the expected set is a leakage failure.

4. **`auth_matrix_test.dart`.** For each role: sign in, assert profile load, assert role getters on `AuthProvider` (`isAdmin`, `isEngineer`, `isOfficeTechnician`, `isInspector`) match the fixture. Sign out, assert `_currentUser` null and the realtime hint channel has been deactivated (inspect via `/diagnostics/sync_transport` transportHealth). Exercise the full `AuthChangeEvent` enum surface referenced by the spec's locked must-log list: `signedIn`, `signedOut`, `tokenRefreshed`, `userUpdated`, `passwordRecovery`, session-expire (produced by expiring the token and observing GoTrue emit the corresponding enum value in the current supabase_flutter version). Each enum value emits at least one `LogEventClasses.authStateTransition` event so Phase 4's audit has matrix-produced traffic for every must-log branch. Additionally, a **deprecated-viewer fallback** sub-test stubs a JWT with `role: 'viewer'` (the enum was removed by `20260317100000_remove_viewer_role.sql`) and asserts `AuthProvider` demotes the session to the safe fallback (no elevated capabilities) — this exercises Scope line 43 without seeding an unreachable row.

5. **`projects_matrix_test.dart`.** Per role: sign in, load `ProjectListScreen`, assert `_projects` / `_assignedProjectIds` / `_mergedProjects` are consistent with the fixture. Assert inspector role sees only assigned projects; admin/engineer/office_technician see company-scoped list. Exercise project create for roles with `canCreateProject = canManageProjects`. Exercise soft-delete and restore.

6. **`assignments_matrix_test.dart` (includes defect c).** Per role: drive the assignment wizard via the driver. To observe the wizard's mutation plan without breaking the single-composition-root rule, the matrix instantiates `ProjectAssignmentProvider` directly in the test's `setUp` using the existing DI factory (`AppBootstrap.buildAssignmentProvider(...)` or the nearest equivalent — the implementer confirms the factory symbol at tailor-verify time) and calls `buildMutationPlan()` on the constructed instance. No new diagnostics route is needed; commit via the driver as before. Defect (c) failing repro uses the Phase 1 fixture's i008 (new-user-c) + p001 (old-project-c): the wizard-flow assertion checks the returned assignment set includes p001 for i008 post-commit. Current bug causes propagation to fail; test fails pre-fix. Tagged `@defect-c`.

7. **`entries_matrix_test.dart`, `photos_matrix_test.dart`, `signatures_matrix_test.dart`.** Per role: create / edit / soft-delete / restore flows. Assert no cross-role leakage on the list screens. For inspectors, assert visibility is scoped by `SyncedScopeStore.getActiveAssignmentProjectIds`. `signatures_matrix_test.dart` covers both `signature_files` and `signature_audit_log` (both registered in `simpleAdapters`).

8. **`forms_matrix_test.dart` (0582B, 1174R, 1126, IDR).** Per form type per role: load the form, fill it via the driver using `TestingKeys` only, submit, assert the `form_responses` row lands with the correct `project_id` and visibility. Respect `is_builtin=1` skip — fixture must not introduce client-visible built-in rows (the Phase 1 seed guards this; the matrix asserts it).

9. **`pay_apps_matrix_test.dart`, `quantities_matrix_test.dart`, `equipment_matrix_test.dart`, `contractors_matrix_test.dart`, `personnel_matrix_test.dart`, `locations_matrix_test.dart`, `todos_matrix_test.dart`, `consent_matrix_test.dart`, `support_matrix_test.dart`, `documents_matrix_test.dart`.** Per role: list / create / edit / soft-delete flows, leakage assertion on every list render.

10. **`exports_matrix_test.dart`.** Per role: drive the export flow, confirm `form_exports`, `entry_exports`, `export_artifacts` rows land locally and are NOT pushed (these are `localOnlyExportHistoryTables` per `SyncEngineTables.localOnlyExportHistoryTables`). Assert via `/diagnostics/sync_transport` that `lastRun.pushed` does not include these table names.

11. **`flashing_repro_test.dart` (defects a, b, e).** Use the `captureFrames(duration:)` pattern from source-excerpts by-concern. For each defect scenario:

    - **Defect (a) "inspector sees unassigned projects on refresh":** sign in as inspector, trigger pull-to-refresh on `ProjectListScreen`, capture every frame for ~5 seconds, assert on each frame that the visible project id set is a subset of the inspector's assignments (pulled from `SyncedScopeStore.getActiveAssignmentProjectIds`). Frames that include an unassigned id produce a leakage failure and cite `frame.timestamp`.
    - **Defect (b) "flashing metadata when a new project is created":** sign in as admin, create a new project via the driver, while the background sync cascades into the inspector session (second harness client authenticated as an assigned inspector), capture frames on the inspector client during the propagation window. Assert no frame shows the new project's metadata for the inspector until the inspector's assignment list contains it.
    - **Defect (e) "single-account refresh bleed":** sign in as inspector A, navigate to project list, sign out, sign in as inspector B (same device), capture frames. Assert no frame on inspector B shows any project from inspector A's assignment set.

    All three defect scenarios land as failing tests pre-fix; Phase 6 flips them to passing. Mark with `@defect-a`, `@defect-b`, `@defect-e` tags.

12. **`download_on_click_test.dart` (defect d).** Per role that can initiate a project download: click the download control via the driver using the `TestingKeys` entry for the download action, assert the download completes end-to-end and the `SyncStatus.downloadProgress` trails from non-null back to null with no stalled state. Current bug causes the click to no-op or stall; test fails pre-fix. Mark with `@defect-d`.

13. **Frame-capture plumbing.** `harnessDriverClient.captureFrames(duration:)` is added in this phase (see Files Modified above — added together with `DriverDiagnosticsRoutes.frameCapture = '/diagnostics/frame_capture'` and the matching `screen_contract_registry.dart` / `TestingKeys` additions in a single PR to satisfy `screen_registry_contract_sync`). The method returns a list of `{timestamp, activeRoute, visibleRootKeys, stateKeyValues}` tuples over the supplied window; the matrix reads `stateKeyValues['project_list_state']`, `stateKeyValues['project_list_assigned_ids']`, etc. Every state key referenced must exist in `screen_contract_registry.dart` `stateKeys` and in `TestingKeys`.

14. **`TestingKeys` enforcement.** Every `find.byKey(...)` or key-resolving driver call in the matrix must reference `TestingKeys.<entry>`. Zero hardcoded `Key('...')`. Zero test-only methods or lifecycle hooks on production classes. `fg_lint_packages/field_guide_lints/lib/test_quality/rules/` enforces this at lint time.

15. **Fixture reuse.** For any matrix-local helper map factory, extend `test/helpers/sync/sync_test_data.dart` `SyncTestData` rather than fork. If a matrix file needs a new map shape, add the factory method to `SyncTestData` in the same commit as the matrix test that first calls it. Do not copy factories into `integration_test/`.

16. **Coexistence gate for characterization tests.** When a matrix test proves a specific contract more honestly than a characterization counterpart, delete the characterization test in its own commit with the commit message citing the matrix file and test name that replaces it. No bulk deletions. Until such a deletion, both layers run.

17. **Final matrix green before Phase 4 begins.** All non-defect flows in the matrix must be green. Defect (a) through (e) tests are expected to fail and are tagged as such. Run sequence gate: every matrix file (excluding `@defect-*` tags) passes locally through `tools/run_tests_capture.ps1` targeting `integration_test/sync/matrix/`; gate is satisfied when zero non-tagged failures remain.

### Exit Criteria

- Every file in `integration_test/sync/matrix/` exists and is committed.
- Defects (a), (b), (c), (d), (e) each have at least one deterministic failing repro committed and tagged.
- Every non-defect matrix test runs green against local Docker Supabase with the Phase 1 fixture.
- `flutter analyze` and `dart run custom_lint` stay green. `screen_registry_contract_sync` lint stays green. `test_quality` lints stay green — no hardcoded `Key('...')`, no test-only production hooks.
- All 15 characterization tests under `test/features/sync/characterization/` still pass. No deletions in Phase 3.

### Local Verification

- `pwsh -File tools/build.ps1` — confirms the build stays clean.
- `flutter analyze` (via the project's standard PowerShell entrypoint) — zero analyzer findings.
- `dart run custom_lint` — zero custom lint violations, including `screen_registry_contract_sync` and the `test_quality` rules.
- `pwsh -File tools/supabase_local_reset.ps1` — re-seeds the fixture before matrix runs.
- `pwsh -File tools/run_tests_capture.ps1` targeting `integration_test/sync/matrix/` excluding `@defect-*` tags — matrix green.
- `pwsh -File tools/run_tests_capture.ps1` targeting `integration_test/sync/matrix/` including `@defect-*` tags — defect tests fail as designed; counts match the five enumerated defects.
- `python scripts/validate_sync_adapter_registry.py` — adapter registry parity stays clean.

---

## Phase 4: Logging Event-Class Audit + Sentry Dual-Feed

### Goal

Close all must-log event-class gaps across sync, auth, and project-selection code. Add the five-layer Sentry filter (log-level, sampling, dedup, rate-limit, breadcrumb budget) composed BELOW the Sentry SDK and ABOVE the existing `beforeSendSentry` PII scrub. Wire Supabase Log Drains into Sentry. Ship the in-app "Report a problem" capture. Keep consent gate and PII filter as the outer kill switch and the final stop before Sentry.

### Prerequisites

- Phase 3 matrix is in place; logging assertions can be co-verified by the matrix traffic.
- Existing `Logger` class API (`sync`, `auth`, `pdf`, `db`, `ocr`, `nav`, `ui`, `photo`, plus `error`, `warn`, `info`) is the single public logging surface — Phase 4 does not introduce a new static API.
- Existing `LoggerSentryTransport.report({message, error, stack, category, data})` is the only path into Sentry from `Logger`.
- `beforeSendSentry` / `beforeSendTransaction` in `lib/core/config/sentry_pii_filter.dart` remain the last stop before the Sentry SDK — untouched by this phase.
- `sentryConsentGranted` in `lib/core/config/sentry_consent.dart` remains the top-level kill switch; every new middleware is a no-op when consent is not granted.
- `SyncErrorClassifier._classifyPostgrestError` in `lib/features/sync/engine/sync_error_classifier.dart` (declaration at line 189; the `42501` branch is around line 246) is the detection site for PostgreSQL `42501` (RLS denial). `42501` stays non-retryable — this phase adds a log call, not a classification change.
- `AuthProvider._authSubscription` listener at `lib/features/auth/presentation/providers/auth_provider.dart:101` is the auth state-change seam.
- `ProjectProviderAuthController.onAuthChanged` and `initWithAuth` are the project/auth-change seams.

### Files Created

- `lib/core/logging/log_event_classes.dart` — authoritative must-log class registry. Declares the locked event-class constants listed in this plan and is the file the audit script parses. The list is allowed to grow during audit/implementation per Scope.
- `lib/core/logging/logger_sentry_dedup_middleware.dart` — class `LoggerSentryDedupMiddleware` with `bool accept({required String fingerprint, required String userId, required SentryLevel level})`. 60-second fingerprint window; rate limit 50 events/user/day; breadcrumb budget 30/event.
- `lib/core/logging/logger_sampling_filter.dart` — class `LoggerSamplingFilter` with `bool accept({required String eventClass, required SentryLevel level})`. Drops 90–95 percent of non-error high-volume event classes (5–10 percent sampling rate); never drops error-level events.
- `scripts/audit_logging_coverage.ps1` — PowerShell canonical per CLAUDE.md. Walks `lib/features/sync/**`, `lib/features/auth/**`, `lib/features/projects/**`; for every constant in `LogEventClasses` that is required by the must-log set, asserts at least one `Logger.<category>(LogEventClasses.<name>, ...)` call exists. Exits 1 on gap; prints dashed error list per the Python CI validator shape; writes summary to `$GITHUB_STEP_SUMMARY` when run in CI.
- (Contingency, not a default deliverable) If the PowerShell path proves unworkable on CI — e.g. an ubuntu runner image without `pwsh` — drop in `scripts/audit_logging_coverage.py` as a parity mirror. PowerShell stays canonical; ubuntu-latest has `pwsh` preinstalled so this contingency should not fire.
- `supabase/functions/_shared/log_drain_sink.ts` — sink handler for Supabase Log Drains forwarding `postgres_logs`, `auth_logs`, `edge_logs` into Sentry. Sink format (Logflare, Datadog, or custom HTTP) is a Phase 4 decision — see Step 13.

### Files Modified

- `lib/core/logging/logger.dart` — route error-level calls through the new middleware pipeline before invoking `LoggerSentryTransport.report`. Preserve: category method surface, part-file split (`logger_file_transport.dart`, `logger_http_transport.dart`, `logger_runtime_hooks.dart`), session directory, per-category rotated log files, flat `app_session.log`, 14-day retention, 50 MB cap, `_retentionDays`, `_maxLogSizeBytes`, `Logger.zoneSpec()`, `Logger.sessionDirectory`, consent-gated routing.
- `lib/core/logging/logger_sentry_transport.dart` — consume dedup middleware; honor rate limit; enforce breadcrumb budget. Preserve: `withScope` tag `'category'`, `logger_message` context, `extra` context shape, consent gate via `isSentryReportingEnabled`, behavior parity between `captureException` (non-null `error`) and `captureMessage` (null `error`).
- `lib/core/config/sentry_runtime.dart` — add per-layer feature flags (`isLoggerLogLevelFilterEnabled`, `isLoggerSamplingFilterEnabled`, `isLoggerDedupMiddlewareEnabled`, `isLoggerRateLimitEnabled`, `isLoggerBreadcrumbBudgetEnabled`) for dev override; each flag defaults to the production value and can be flipped via `String.fromEnvironment` dart-defines. Preserve: `sentryDsn`, `isSentryConfigured`, `isSentryReportingEnabled`, `isSentryFeedbackAvailable`.
- `lib/main.dart` — wire dedup middleware + log-level filter into `SentryFlutter.init` via `options.beforeBreadcrumb` (breadcrumb budget layer) and via the new middleware hook on `LoggerSentryTransport`. Preserve exactly: `options.tracesSampleRate = 0.1`, `options.attachScreenshot = false`, `options.attachViewHierarchy = false`, `options.replay.sessionSampleRate = 1.0`, `options.replay.onErrorSampleRate = 1.0`, `options.privacy.maskAllText = true`, `options.privacy.maskAllImages = true`, `options.beforeSend = beforeSendSentry`, `options.beforeSendTransaction = beforeSendTransaction`, `runApp(SentryWidget(...))`, `runZonedGuarded` block, `Logger.zoneSpec()` wiring.
- `lib/features/sync/engine/sync_error_classifier.dart` — at the `42501` branch inside `_classifyPostgrestError` (around line 246; declaration at line 189), add `Logger.sync(LogEventClasses.rlsDenial, data: {...})` capturing `{'tableName', 'recordIdHash': sha256(recordId ?? '').take(8), 'retryCount', 'context', 'postgrestCode': '42501'}`. **Do not log raw `recordId`** — the RLS denial is proof the caller is not authorized to see that row, and a Sentry/Log-Drain payload carrying it leaks the protected identifier off-device. `beforeSendSentry` must assert that any `rlsDenial` event's `data` map does not contain a `recordId` key (add the assertion to `sentry_pii_filter.dart` as part of this phase). Preserve: the existing non-retryable classification for `42501`, the existing user-safe message via `_sanitizeForUi`, the `classify` entrypoint signature at line 126, and the static helper surface.
- `lib/features/sync/engine/**` — for each must-log event class without a current seam, add a single-line `Logger.sync(LogEventClasses.<name>, data: {...})` call. Anchors from dependency-graph heavy-caller list: `sync_lifecycle_manager.dart` (currently 13 Logger calls), `background_sync_handler.dart` (10), `fcm_handler.dart` (10), `dirty_scope_tracker.dart` (6), `sync_coordinator.dart` (6), `sync_enrollment_service.dart` (5), `sync_background_retry_scheduler.dart` (5), `connectivity_probe.dart` (4). Audit script drives the gap list. Preserve: `SyncCoordinator` as the sole sync entrypoint, `SyncEngine` mode router, `SyncRegistry` adapter order, `change_log` trigger ownership, `sync_control.pulling` bracket as the only suppression path.
- `lib/features/auth/presentation/providers/auth_provider.dart` — inside the `_authSubscription` listener at line ~101, every `AuthChangeEvent` branch must log `LogEventClasses.authStateTransition`. **Scrub rules (enforced, not advisory):**
  - `userId` = `state.currentUser?.id` (UUID) ONLY. Never `state.currentUser?.email` or any substring of it.
  - `companyId` = `_sha256Prefix8(companyId)` (first 8 hex chars of SHA-256) — avoid direct customer-id correlation in Sentry/Log Drain.
  - `role` = `_userProfile?.role.name` (enum label is safe, not PII).
  - No `raw_user_meta_data`, no `phone`, no `email` token anywhere in `data`.
  `beforeSendSentry` asserts any `authStateTransition` event's `data` map contains no substring matching `@` (email-shape). A unit test in `test/core/config/sentry_pii_filter_test.dart` feeds a synthetic `authStateTransition` event with `email`-shaped content and asserts the filter drops or scrubs it. Preserve: `notifyListeners()` call sites, recovery handling, capability getters, profile freshness windows.
- `lib/features/projects/presentation/providers/project_provider_auth_controller.dart` — in `onAuthChanged`, emit `Logger.auth(LogEventClasses.authStateTransition, data: {...})` with the same scrub rules above: before/after `{companyIdHash, userId (UUID only), role.name}` tuple. No raw companyId, no email. Preserve: `initWithAuth` call shape; `_loadAssignments`, `_loadProjectsByCompany`, and `syncCoordinator.syncLocalAgencyProjects(mode: SyncMode.quick)` trigger chain (Phase 6 handles the ordering fix).
- `lib/core/config/sentry_feedback_launcher.dart` — extend `SentryFeedbackLauncher` to capture the last 30 breadcrumbs (already enforced by the breadcrumb budget layer), a tail of recent logs from `Logger.sessionDirectory` (cap: last 200 lines) that is **passed through a scrubbing pass equivalent to `beforeSendSentry` before attachment** — email-shape tokens, UUIDs in `WHERE id = '...'` substrings, and `raw_user_meta_data` blobs are stripped. This prevents feedback capture from exfiltrating pre-filter log content that would have been dropped on the live stream. User id is UUID only (no email); current project id selection; device info via `device_info_plus` (existing dependency). Preserve: `isSentryFeedbackAvailable` gate; consent gate short-circuits the capture to a no-op when consent not granted.
- `lib/features/settings/presentation/screens/help_support_screen.dart` — extend `_openSentryFeedback()` (line ~200) to call the expanded `SentryFeedbackLauncher` capture path. Preserve: existing UI flow, `TestingKeys` references (no hardcoded `Key('...')`), feature flag gating.
- `.github/workflows/quality-gate.yml` — add a `Logging event-class audit` step inside the `architecture-validation` job that runs `pwsh -File scripts/audit_logging_coverage.ps1` (ubuntu runners invoke `pwsh`). Wire output to `$GITHUB_STEP_SUMMARY` per the Python CI validator pattern. Preserve: the three-job layout (`analyze-and-test`, `architecture-validation`, `security-scanning`); the existing `validate_sync_adapter_registry.py`, `check_changed_migration_rollbacks.py`, `validate_migration_rollbacks.py`, `verify_database_schema_platform_parity.py`, `verify_live_supabase_schema_contract.py` steps; the existing lint auto-issue step and its per-rule dedup semantics.

### Files Preserved (Must Not Regress)

- `lib/core/config/sentry_pii_filter.dart` — `beforeSendSentry` and `beforeSendTransaction` are the last stop before Sentry; they stay unchanged. The new middlewares layer BENEATH the Sentry SDK (i.e., fire before Sentry sees the event), not above.
- `lib/core/config/sentry_consent.dart` — `sentryConsentGranted` is the top-level kill switch. All five layers must no-op when consent is not granted.
- `lib/main.dart` sampling + replay + privacy + consent settings listed in Files Modified — unchanged values.
- `SyncCoordinator`, `SyncEngine`, `SyncErrorClassifier` (classification semantics), `SyncStatus`, `SyncRegistry`, `sync_control.pulling` suppression bracket, `change_log` trigger ownership, `42501` non-retryable rule.
- `fg_lint_packages/field_guide_lints/lib/` — `sync_integrity/rules/`, `architecture/rules/`, `data_safety/rules/`, `test_quality/rules/` — all stay green.
- `scripts/validate_sync_adapter_registry.py`, `scripts/verify_live_supabase_schema_contract.py`, `scripts/check_changed_migration_rollbacks.py`, `scripts/validate_migration_rollbacks.py`, `scripts/verify_database_schema_platform_parity.py` — unchanged.
- Existing 15 characterization tests under `test/features/sync/characterization/`.
- All PowerShell wrappers under `tools/` — `build.ps1`, `start-driver.ps1`, `stop-driver.ps1`, `wait-for-driver.ps1`, `verify-sync.ps1`, `run_and_tail_logs.ps1`, `run_tests_capture.ps1`, and the Phase 1 additions `supabase_local_start.ps1` / `supabase_local_reset.ps1`.

### Step-by-step Implementation

1. **Declare the event-class registry.** Create `lib/core/logging/log_event_classes.dart` with a `LogEventClasses` class of static const strings for every locked name from the spec: `syncEngineEntry`, `syncEngineExit`, `syncEngineError`, `changeLogWrite`, `changeLogRollback`, `triggerFire`, `rlsDenial`, `projectAssignmentMutation`, `authStateTransition`, `pullScopeEnrollment`, `pullScopeTeardown`, `realtimeHintEmit`, `realtimeHintReceive`, `realtimeHintConsume`, `downloadInitiate`, `downloadComplete`, `downloadFail`, `conflictResolution`, `fkRescue`, `edgeFunctionCall`, `retryPolicyDecision`. Each constant's string value follows the `category.subject.action` dotted shape (e.g., `'sync.engine.entry'`). The file is the sole source parsed by the audit script.

2. **Implement the sampling filter.** Create `lib/core/logging/logger_sampling_filter.dart`. `LoggerSamplingFilter.accept({eventClass, level})` returns `true` unconditionally when `level == SentryLevel.error` or higher. For non-error events, apply a deterministic sample-rate pattern (5–10 percent) keyed by eventClass so high-volume `sync.*` info-level events drop predictably. The filter reads the per-layer feature flag from `sentry_runtime.dart` and no-ops (returns true) when the flag is off. No runtime mutable state on this class; it is stateless.

3. **Implement the dedup middleware.** Create `lib/core/logging/logger_sentry_dedup_middleware.dart`. `LoggerSentryDedupMiddleware({fingerprintWindow: Duration(seconds: 60), maxEventsPerUserPerDay: 50, maxBreadcrumbsPerEvent: 30})`. Keep three internal structures:

    - `Map<String, DateTime> _fingerprintFirstSeen` — drops repeat fingerprints inside the 60-second window.
    - `Map<String, int> _perUserDailyCount` with midnight reset — drops events beyond 50/user/day.
    - Breadcrumb budget is applied at the `beforeBreadcrumb` seam in `main.dart`, not here; this class exposes `trimBreadcrumbs(List<Breadcrumb>)` returning the last 30 so both the feedback launcher and the transport can reuse it.

    Public method: `bool accept({required String fingerprint, required String userId, required SentryLevel level})`. Consent gate check at the top returns `true` and short-circuits (i.e., no-op when consent not granted — events dropped will be dropped by the existing consent check inside `LoggerSentryTransport.report`, not here; this layer only filters when consent is granted).

4. **Wire the middleware pipeline into the transport.** Modify `lib/core/logging/logger_sentry_transport.dart`. Before invoking `Sentry.captureException` / `Sentry.captureMessage`, run in order:

    1. Log-level filter (drop below `SentryLevel.warning`) — honor `isLoggerLogLevelFilterEnabled`.
    2. `LoggerSamplingFilter.accept(eventClass, level)` — honor `isLoggerSamplingFilterEnabled`.
    3. `LoggerSentryDedupMiddleware.accept(fingerprint, userId, level)` — honor `isLoggerDedupMiddlewareEnabled` and `isLoggerRateLimitEnabled` (the rate-limit and dedup checks live inside the same middleware but are flag-gated independently).
    4. Proceed to existing `Sentry.captureException` / `Sentry.captureMessage` path, which will invoke `beforeSendSentry` unchanged.

    Fingerprint is derived as `'${category}.${eventClass}.${errorType ?? 'message'}'` at the transport boundary. Rate-limit user key is `userId ?? 'anonymous'`. Preserve the `withScope` tag / contexts shape so Sentry event triage keeps working.

5. **Wire breadcrumb budget at SDK boundary.** Modify `lib/main.dart` `SentryFlutter.init`. Add `options.beforeBreadcrumb` callback that defers to `LoggerSentryDedupMiddleware.trimBreadcrumbs`-equivalent logic (keep the last 30 breadcrumbs ordered by timestamp). Honor `isLoggerBreadcrumbBudgetEnabled`. Keep `options.beforeSend = beforeSendSentry` and `options.beforeSendTransaction = beforeSendTransaction` exactly as they are. Do not touch `tracesSampleRate`, `replay.*`, `privacy.*`, `attachScreenshot`, `attachViewHierarchy`.

6. **Add per-layer dev override flags.** Modify `lib/core/config/sentry_runtime.dart`. Add five `bool` getters gated on `String.fromEnvironment` dart-defines: `isLoggerLogLevelFilterEnabled`, `isLoggerSamplingFilterEnabled`, `isLoggerDedupMiddlewareEnabled`, `isLoggerRateLimitEnabled`, `isLoggerBreadcrumbBudgetEnabled`. Defaults match production (all on). Any dev override (e.g., `--dart-define=FG_LOGGER_DEDUP=off`) flips one layer to off so local repro of Sentry ingestion stays possible. Preserve: existing `sentryDsn`, `isSentryConfigured`, `isSentryReportingEnabled`, `isSentryFeedbackAvailable`.

7. **Emit RLS denial log at the classifier boundary.** Modify `lib/features/sync/engine/sync_error_classifier.dart`. Inside `_classifyPostgrestError` at the `42501` branch (around line 246), immediately before returning the classified error, add `Logger.sync(LogEventClasses.rlsDenial, data: {'tableName': tableName, 'recordIdHash': _sha256Prefix8(recordId), 'retryCount': retryCount, 'context': context, 'postgrestCode': '42501'})`. **Raw `recordId` is not logged** — the RLS denial is proof the caller is not authorized to see that row, so emitting it to Sentry/Log Drain leaks the protected identifier off-device. Add an assertion in `lib/core/config/sentry_pii_filter.dart` `beforeSendSentry` that drops any event whose `data` contains a `recordId` key when the event class is `rlsDenial`. The classification itself (non-retryable) does not change. The existing `_sanitizeForUi` path continues to produce the user-safe message. Do not re-throw; do not alter return shape. Do not move the log call outside the `42501` branch.

8. **Emit `authStateTransition` for every auth event.** Modify `lib/features/auth/presentation/providers/auth_provider.dart`. Inside the `_authSubscription` listener at line ~101, ensure every `AuthChangeEvent` branch logs `Logger.auth(LogEventClasses.authStateTransition, data: {...})`:

    - `AuthChangeEvent.passwordRecovery` — already a distinct branch; add the log at entry.
    - First-time sign-in path (`!wasAuthenticated && _userProfile == null && !_isLoadingProfile`) — log before `unawaited(loadUserProfile())`.
    - Sign-out path (`_currentUser == null`) — log before `_notifyStateChanged()`.
    - Subsequent notify (`_notifyStateChanged()` fallthrough) — log with `event: state.event.name` so token refresh and session expire are distinguished.

    Every log includes `{'event': state.event.name, 'userId': <scrubbed — no email>, 'companyId': _userProfile?.companyId, 'role': _userProfile?.role.name}`. Preserve: `notifyListeners` timing, role getters, capability getters, freshness windows.

9. **Emit `authStateTransition` on project auth change.** Modify `lib/features/projects/presentation/providers/project_provider_auth_controller.dart`. Inside `onAuthChanged`, log `Logger.auth(LogEventClasses.authStateTransition, data: {'from': {'companyId': prevCompanyId, 'userId': prevUserId, 'role': prevRole?.name}, 'to': {'companyId': newCompanyId, 'userId': newUserId, 'role': newRole?.name}})` before the `_loadAssignments(newUserId)` and `_loadProjectsByCompany(newCompanyId)` calls fire. Preserve: the existing unawaited-future shape; Phase 6 fixes the ordering, Phase 4 only observes it.

10. **Close gaps across the sync engine.** For every must-log event class in `LogEventClasses` without a current seam, add a single-line `Logger.sync(LogEventClasses.<name>, data: {...})` call at the appropriate site. Drive the gap list by running the audit script (Step 12) iteratively:

    - `syncEngineEntry` / `syncEngineExit` — inside `SyncEngine.pushAndPull` at lines 92 and just before each return path.
    - `syncEngineError` — inside `sync_run_lifecycle.dart` at the classified-error sink.
    - `changeLogWrite` / `changeLogRollback` — inside the push handler's transactional write seam; `triggerFire` is server-side only (trigger-authored in Postgres). Mark `LogEventClasses.triggerFire` with a doc comment `/// Server-side event — audit script exempts. E2E coverage: Phase 4 step 13a verifies a fixture-induced trigger reaches Sentry via Log Drain.`  The audit script in step 11 reads that doc-comment tag and skips enforcement for client-side seam coverage on this class.
    - `projectAssignmentMutation` — inside `lib/features/projects/presentation/providers/project_assignment_provider.dart` at `markSaved` after `buildMutationPlan()` commits.
    - `pullScopeEnrollment` / `pullScopeTeardown` — inside `sync_enrollment_service.dart` on enroll/teardown paths.
    - `realtimeHintEmit` — inside `RpcSyncHintRemoteEmitter.emit`.
    - `realtimeHintReceive` — inside `realtime_hint_handler.dart` `_handleHint`.
    - `realtimeHintConsume` — inside `_triggerQuickSync` / `_drainQueuedQuickSync`.
    - `downloadInitiate` / `downloadComplete` / `downloadFail` — inside the project download controller path touched by defect (d).
    - `conflictResolution` — inside the LWW winner / clock-skew fallback seam in `push_handler.dart`.
    - `fkRescue` — inside `fk_rescue_handler.dart` / `pull_fk_violation_resolver.dart`.
    - `edgeFunctionCall` — at each call site that invokes `supabase.functions.invoke` for `daily-sync-push`, `google-cloud-vision-ocr`, `google-document-ai-ocr`.
    - `retryPolicyDecision` — inside `sync_retry_policy.dart` at each decision branch.

    Every call is additive; do not remove any existing `Logger.sync(...)` calls. Keep the public entrypoint (`SyncCoordinator`) the sole caller surface from outside `lib/features/sync/`.

11. **Author the audit script (PowerShell canonical).** Create `scripts/audit_logging_coverage.ps1`. The script:

    - Parses `lib/core/logging/log_event_classes.dart` to extract the list of `LogEventClasses.<name>` constants.
    - Recursively walks `lib/features/sync/**`, `lib/features/auth/**`, `lib/features/projects/**`.
    - For each must-log constant, searches for at least one occurrence of `LogEventClasses.<name>` passed into a `Logger.<category>(...)` call.
    - Emits a dashed list of gaps on stderr (`- LogEventClasses.xxx has no Logger.<category> call in <expected-area>`).
    - Exits 1 when gap count > 0; exits 0 otherwise.
    - When `$env:GITHUB_STEP_SUMMARY` is set, appends a summary table row matching the Python CI validator shape.

    Keep the script stdlib-only (built-in PowerShell commands; no external modules). Follow the dashed-error, exit-1-on-drift shape from `patterns/python-ci-validator.md`.

12. **Optional Python mirror.** Only if PowerShell on ubuntu-latest proves awkward (e.g., `pwsh` unavailable on a runner image), add `scripts/audit_logging_coverage.py` with the same contract: same constant list extraction, same gap list on stderr, same exit code semantics. PowerShell remains canonical per CLAUDE.md.

13. **Name the Log Drain sink decision — do not defer.** Before merging Phase 4, the implementer must record in the commit message (or a dedicated ADR under `.claude/docs/`) the chosen sink among Logflare, Datadog, and custom HTTP endpoint, and the rationale. Create `supabase/functions/_shared/log_drain_sink.ts` implementing the chosen sink: accept the Supabase Log Drain webhook payload, forward `postgres_logs`, `auth_logs`, `edge_logs` into Sentry via the Sentry ingest API with a scoped tag `'source': 'supabase.log_drain'`. The sink honors the same consent gate at the edge — events forwarded from server-side only when staging/prod consent is in place.

13a. **Log Drain sink scrubbing pass (mandatory, before Sentry ingest).** The edge sink **must** run a scrubbing pass on every payload before the Sentry ingest call, because server-side log sources routinely contain raw PII that `beforeSendSentry` (a client-only SDK hook) never sees:
   - Strip email-shape tokens from every log line (regex sanitizer).
   - Strip UUID literals that appear in `WHERE id = '...'` (and `WHERE user_id = '...'`, `project_id`, `company_id`, `record_id`) clauses of `postgres_logs` SQL statements.
   - Strip `raw_user_meta_data` blobs from `auth_logs` (the column name is known; scrub by key).
   - Drop any payload whose source-side consent flag is absent.
   Add `supabase/functions/_shared/log_drain_sink.test.ts` that feeds representative `auth_logs` + `postgres_logs` + `edge_logs` fixtures and asserts no email token, bare UUID in a WHERE clause, or `raw_user_meta_data` payload survives. End-to-end verification against real staging is Phase 7's job; the Phase 4 commit ships the sink + its scrubbing test green against fixtures.

13b. **`triggerFire` E2E coverage.** To close the locked must-log class for `triggerFire` (which has no client seam), add a Phase 4 verification step: insert a row into a seeded table via service role while Log Drain is active, query Sentry for an event tagged `source: supabase.log_drain` carrying the `trigger_fire` postgres-log line within 2 minutes. This is a one-time verification, not a CI loop — record the screenshot/log in the Phase 4 PR description. Without this, `LogEventClasses.triggerFire` is declared but unverified end-to-end.

14. **Extend in-app "Report a problem".** Modify `lib/core/config/sentry_feedback_launcher.dart`. Extend `SentryFeedbackLauncher` with a capture path that:

    - Reads the last 30 breadcrumbs (already enforced by the breadcrumb budget middleware `trimBreadcrumbs` helper from Step 3).
    - Tails recent log lines from `Logger.sessionDirectory` — **cap the tail at the last 200 lines** and **run the tail content through the same scrubbing pass as `beforeSendSentry`** (email tokens, UUIDs in WHERE clauses, `raw_user_meta_data` blobs stripped). The live Logger-to-Sentry stream applies five-layer filtering; the file transport writes unfiltered, so feedback capture would otherwise exfiltrate content the live stream would have dropped.
    - Attaches `userId` (UUID only — no email, no companyId raw); current project id (via active project provider selection); device info via `device_info_plus` (existing `pubspec.yaml` dependency — no new dep).
    - Honors `isSentryFeedbackAvailable` and `sentryConsentGranted` as short-circuits.

    Modify `lib/features/settings/presentation/screens/help_support_screen.dart` `_openSentryFeedback()` (line ~200) to invoke the extended capture path. Preserve `TestingKeys` usage; no hardcoded keys.

15. **Wire the audit + fixture-parity into CI.** Modify `.github/workflows/quality-gate.yml` `architecture-validation` job. Add two steps in sequence:
    - `Logging event-class audit` — invokes `pwsh -File scripts/audit_logging_coverage.ps1 2>&1 | tee /tmp/logging_audit.txt || EXIT_CODE=$?` then posts a summary table row to `$GITHUB_STEP_SUMMARY` following the shape from `patterns/python-ci-validator.md`. Non-zero exit fails the job.
    - `Harness fixture parity` — invokes `python scripts/validate_harness_fixture_parity.py` (created as a stub in Phase 1; now enforcing because `integration_test/sync/harness/harness_fixture_cursor.dart` exists after Phase 2). Emits the same summary-table pattern. Fails if `supabase/seed.sql` and `HarnessFixtureIds` drift on users, projects, or assignments.
    Preserve the rest of the workflow: the `analyze-and-test` job, the `security-scanning` job, and all existing architecture-validation steps.

16. **Bootstrap sequencing in `main.dart`.** In `lib/main.dart`, instantiate the dedup middleware and sampling filter before `SentryFlutter.init`, and hand references to `LoggerSentryTransport` (via a static setter or a `LoggerSentryTransport.configureMiddleware(...)` entrypoint added in Step 4). Do not run any logging through Sentry until consent is resolved; the middleware no-ops anyway but the wiring must be in place. Keep `runZonedGuarded` and `Logger.zoneSpec()` at the outer scope — no structural change.

17. **Verification against matrix traffic.** Run the Phase 3 matrix with dev-override flags flipped one at a time: confirm each layer actually filters as expected (log-level only, sampling only, dedup only, rate-limit only, breadcrumb budget only). Matrix traffic must continue to pass; Sentry ingestion during a matrix run must stay well below the 5,000/month budget extrapolated to the matrix window.

### Exit Criteria

- `scripts/audit_logging_coverage.ps1` exits 0 — zero must-log gaps.
- `lib/core/logging/log_event_classes.dart` compiles and is the single source of event-class names.
- `lib/core/logging/logger_sentry_dedup_middleware.dart` and `lib/core/logging/logger_sampling_filter.dart` compile and pass analyzer + custom lints.
- `lib/main.dart` preserved settings unchanged (`tracesSampleRate: 0.1`, replay sample rates 1.0, privacy masking on, `beforeSendSentry`, `beforeSendTransaction`, consent gate).
- `beforeSendSentry` PII filter still the last stop before Sentry; dedup + sampling + rate limit + breadcrumb budget + log-level filter all fire before `beforeSend`.
- `sentryConsentGranted` still the top-level kill switch; every new layer no-ops when consent is not granted.
- `SyncErrorClassifier` still classifies `42501` as non-retryable; the new `rlsDenial` log is additive at the detection site.
- `SyncCoordinator`, `SyncEngine`, `SyncRegistry`, `SyncStatus`, `change_log` trigger ownership, and `sync_control.pulling` bracket remain unchanged.
- CI workflow shows the `Logging event-class audit` step green.
- Log Drain sink implementation decided (Logflare / Datadog / custom HTTP) with rationale recorded; `supabase/functions/_shared/log_drain_sink.ts` compiles.
- In-app "Report a problem" captures breadcrumbs + session logs + scrubbed user id + current project id + device info.
- Sentry ingestion on local Docker + nightly soak workload projects < 5,000 errors/month (final verification gated on Phase 5 soak running and Phase 7 staging project being live).

### Local Verification

- `flutter analyze` — zero findings.
- `dart run custom_lint` — zero violations; `sync_integrity`, `architecture`, `data_safety`, and `test_quality` rules stay green.
- `pwsh -File scripts/audit_logging_coverage.ps1` — exits 0, prints `Logging event-class audit passed.`.
- `python scripts/validate_sync_adapter_registry.py` — adapter registry parity unchanged.
- `python scripts/verify_database_schema_platform_parity.py` — schema parity unchanged.
- `pwsh -File tools/build.ps1` — clean build.
- Per-layer dev-override sanity: launch the app with `--dart-define=FG_LOGGER_DEDUP=off` (and the other four flags, one at a time); confirm Sentry ingestion changes shape as expected against a local Docker Supabase session. No other behavior regresses.


---

## Phase 5: Property-Based Concurrency + Soak

### Goal

Prove sync invariants hold under generated concurrent scenarios, and sustain a 10-minute CI soak (pre-merge gate) plus a 15-minute nightly soak against local Docker Supabase (and, after Phase 7 provisioning, against staging). Invariants under test: Last-Write-Wins resolution, cursor advancement monotonicity, assignment-scope enrollment/teardown correctness, and tombstone propagation across soft-delete.

### Prerequisites

- Phase 1 seeded fixture (`supabase/seed.sql` with ~10–20 users across 15 projects, assignment matrix with inspectors both on and off specific projects) is in place and `pwsh -File tools/supabase_local_reset.ps1` boots cleanly.
- Phase 2 harness skeleton is merged: `integration_test/sync/harness/harness_auth.dart`, `harness_driver_client.dart`, `harness_assertions.dart`, `harness_fixture_cursor.dart` exist and can authenticate each of the four roles against local Docker.
- Phase 3 correctness matrix has landed under `integration_test/sync/matrix/`, including the failing repros for defects (a), (b), (c), (d), (e). These repros stay failing through Phase 5.
- Phase 4 logging event-class audit + Sentry dedup middleware is green. Soak metrics rely on Phase 4's RLS-denial event class (`LogEventClasses.rlsDenial`) and the transport diagnostics already published at `/diagnostics/sync_transport` and `/diagnostics/sync_runtime`.
- `glados` is not yet a repo dependency (per ground-truth gap #1). This phase adds it.
- `scripts/soak_local.ps1` does not yet exist (per ground-truth gap #5). This phase creates it.
- Existing 60+ sync unit tests under `test/features/sync/**` and 15 characterization tests under `test/features/sync/characterization/` stay green; this phase does not modify them.

### Files Created

- `integration_test/sync/concurrency/glados_invariants_test.dart`
- `integration_test/sync/concurrency/table_driven_fallback_test.dart`
- `integration_test/sync/soak/soak_driver.dart`
- `integration_test/sync/soak/soak_metrics_collector.dart`
- `integration_test/sync/soak/soak_ci_10min_test.dart`
- `integration_test/sync/soak/soak_nightly_15min_test.dart`
- `scripts/soak_local.ps1`
- `.github/workflows/nightly-soak.yml`

### Files Modified

- `pubspec.yaml` — add `glados` under `dev_dependencies`.
- `.github/workflows/quality-gate.yml` — add `Soak test (10-min)` step gated on sync-touching PRs via a path filter.

### Files Preserved (Must Not Regress)

- All 26 adapters registered in `lib/features/sync/engine/sync_registry.dart` and their FK-dependency order.
- `lib/features/sync/engine/sync_error_classifier.dart` classification contract — `42501` stays non-retryable when the soak driver encounters an RLS denial.
- `lib/features/sync/domain/sync_status.dart` as the single source of truth for transport state; soak metrics read from it via `/diagnostics/sync_transport`, not by probing internals.
- `lib/features/sync/application/sync_coordinator.dart` `syncLocalAgencyProjects(...)` remains the only sync entrypoint the soak driver calls.
- `lib/features/sync/engine/sync_engine_tables.dart` trigger behavior: `sync_control.pulling = '1'` remains the only trigger-suppression bracket; soak fixture never inserts into `change_log` manually.
- `RealtimeHintHandler._minSyncInterval = Duration(seconds: 30)` stays as-is in this phase (Phase 6 may revisit only if profiling forces it).
- The existing "Sync lint violations to GitHub Issues" step in `.github/workflows/quality-gate.yml` — the nightly-soak workflow created here stays separate until Phase 7 unifies it under `scripts/github_auto_issue_policy.py`.
- All 15 characterization tests under `test/features/sync/characterization/`.

### Step-by-step Implementation

1. **Add `glados` as a dev dependency.**
   - Repo SDK constraint at tailor time: `environment.sdk: ^3.10.7` (from `pubspec.yaml:22`). `glados: ^1.1.6` is compatible.
   - Edit `pubspec.yaml`. Under `dev_dependencies:` add `glados: ^1.1.6`.
   - Run `pwsh -Command "flutter pub get"`.
   - Confirm `flutter analyze` and `dart run custom_lint` stay green.

2. **Create `integration_test/sync/concurrency/glados_invariants_test.dart`.**
   - Import `package:glados/glados.dart`, the harness (`integration_test/sync/harness/harness_auth.dart`, `harness_driver_client.dart`, `harness_assertions.dart`), and `package:construction_inspector/features/sync/engine/sync_error_classifier.dart`.
   - Define four property-based tests:
     - **LWW property**: generate pairs of competing mutations with varying `updated_at` deltas, push both, assert the winner at the server matches the later `updated_at`. Cross-check against `SyncErrorClassifier.classify` so any unexpected classification surfaces. Target sites: `lib/features/sync/engine/push_handler.dart` (LWW winner selection) and `SyncErrorClassifier` contract.
     - **Cursor advancement monotonicity**: generate sequences of pulls interleaved with local mutations, assert the cursor recorded by `lib/features/sync/engine/change_tracker.dart` only advances and never rewinds.
     - **Assignment-scope enrollment/teardown**: generate add/remove sequences against `project_assignments` for a given user; assert `lib/features/sync/engine/enrollment_handler.dart` plus `lib/features/sync/engine/pull_scope_state.dart` converge to the correct scope set regardless of ordering, and that `SyncedScopeStore.getActiveAssignmentProjectIds` reflects the final state.
     - **Tombstone propagation**: generate soft-delete + restore sequences, assert tombstones propagate to every subscribed device's local DB with no ghost rows and no double-deletes.
   - Each property reads sync state only via `/diagnostics/sync_transport` and `/diagnostics/sync_runtime` or via `SyncCoordinator.status` / `SyncCoordinator.statusStore` — never by reaching into `SyncEngine` directly.
   - Use `TestingKeys` for any UI-driven setup; never hardcode `Key('...')`.

3. **Create `integration_test/sync/concurrency/table_driven_fallback_test.dart`.**
   - For invariants `glados` cannot express cleanly (e.g., scenarios that require specific real-time timing from `RealtimeHintHandler._handleHint` plus a throttle window), enumerate a small static table of scenarios — each row a `(setup, action sequence, expected invariant)` triple.
   - Drive each row through the harness. Keep this file time-boxed: if the PBT coverage above already exercises the scenario, delete the row.

4. **Create `integration_test/sync/soak/soak_metrics_collector.dart`.**
   - Class `SoakMetricsCollector` with a `sample()` method that issues HTTP GETs against the driver's `/diagnostics/sync_transport` and `/diagnostics/sync_runtime` endpoints (paths sourced from `lib/core/driver/driver_diagnostics_handler.dart`'s `DriverDiagnosticsRoutes`).
   - From `/diagnostics/sync_transport` capture the `lastRun` payload: `pushed`, `pulled`, `errors`, `rlsDenials`, `durationMs`, `completedAt`, `wasSuccessful`, and the `transportHealth` map.
   - From `/diagnostics/sync_runtime` capture: `lastRequestedMode`, `lastRunHadDirtyScopesBeforeSync`, `stateFingerprint`, `dirtyScopeCount`, `dirtyScopes`.
   - Expose `Stream<SoakSample>` for per-minute sampling and a `SoakSummary finalize()` for end-of-run totals.
   - No mutation; pure read over the existing driver HTTP surface.

5. **Create `integration_test/sync/soak/soak_driver.dart`.**
   - Class `SoakDriver` with fields `userCount` (default `20`), `duration` (passed in — 5 / 10 / 15 minutes), and `actionMix` with default weights `readWeight: 30`, `entryMutationWeight: 30`, `photoUploadWeight: 15`, `deleteRestoreWeight: 20`, `roleAssignmentWeight: 5`.
   - Authenticate each of the 20 virtual users against a seeded fixture user (from Phase 1's `supabase/seed.sql`). Reuse `integration_test/sync/harness/harness_auth.dart`; do not introduce a second auth path.
   - Per virtual user, loop until `duration` elapses: pick a weighted action; execute it through `harness_driver_client.dart` against the real Flutter client; every 60s, sample metrics via `SoakMetricsCollector`.
   - On error: call `SyncErrorClassifier.classify(error, tableName: ..., recordId: ..., retryCount: ...)`. If the resulting kind is RLS denial (`42501` path), increment `rlsDenials` and continue. For any transient classification, continue. Never swallow the error; always record it in the summary.
   - `run()` returns a `SoakResult` containing per-minute samples, aggregate counters, and the `SoakSummary`.
   - No new call into `SyncEngine` or `SyncCoordinator` internals; all sync work goes through `SyncCoordinator.syncLocalAgencyProjects(...)` via the driver.

6. **Create `integration_test/sync/soak/soak_ci_10min_test.dart`.**
   - Single test that constructs `SoakDriver(duration: Duration(minutes: 10), userCount: 20, actionMix: SoakDriver.defaultMix)`, calls `run()`, and asserts:
     - `result.summary.wasSuccessful == true` on the final `lastRun`.
     - `result.summary.errors` (excluding classified-RLS denials) is zero.
     - No sample reports `lastRun.rlsDenials` exceeding the per-minute ceiling defined by the seeded fixture's legitimate denial rate (the fixture has known-unassigned inspectors, so some RLS denials are expected and legitimate — the assertion is rate-bounded, not zero).
   - Wire into `.github/workflows/quality-gate.yml` in step 8.

7. **Create `integration_test/sync/soak/soak_nightly_15min_test.dart`.**
   - Same shape as the 10-min CI test, with `duration: Duration(minutes: 15)`.
   - Stricter assertion: records a metrics snapshot to a workflow artifact for trend analysis (fed into Phase 7's auto-issue policy once stability is reached).

8. **Modify `.github/workflows/quality-gate.yml`: add `Soak test (10-min)` step.**
   - Add a `paths` filter at the job level (or a per-step `if` using `dorny/paths-filter`) that runs the new step only when the PR touches any of:
     - `lib/features/sync/**`
     - `lib/core/driver/**`
     - `supabase/migrations/**`
     - `supabase/seed.sql`
     - `lib/features/sync/adapters/**`
   - The step name is `Soak test (10-min)`. It runs after the existing `analyze-and-test` job's test steps and before architecture validation. Invocation uses the PowerShell test-runner wrapper (the existing `tools/run_tests_capture.ps1` pattern, extended if needed to pass dart-defines) targeting `integration_test/sync/soak/soak_ci_10min_test.dart` with dart-defines for `HARNESS_SUPABASE_URL` + `HARNESS_SUPABASE_ANON_KEY` supplied from workflow secrets. **Do not invoke `flutter test` as a literal command in the plan or workflow body** — delegate to the wrapper, per `rules/testing/testing.md` and the writing-plans skill body rule.
   - **Staging handoff.** Until Phase 7 provisions staging, this step runs against local Docker Supabase (spun up in the runner via `tools/supabase_local_reset.ps1`, executed as the job's first real step per Scope line 46: "reset-and-seed sequence run as a single job at the start of each nightly"). Phase 7 step 5 flips the dart-defines to `STAGING_SUPABASE_URL` + `STAGING_SUPABASE_ANON_KEY`; this is the same step, not a second parallel step. Do not introduce a duplicate soak step in Phase 7.
   - Until three consecutive green CI runs are observed, mark the step `continue-on-error: true`. Remove that flag in the commit that declares the gate official.

9. **Create `scripts/soak_local.ps1`.**
   - PowerShell wrapper for local developers. Accepts `-DurationMinutes` (default 5), `-UserCount` (default 20). Boots local Docker Supabase via `tools/supabase_local_start.ps1` if not already running, then runs `integration_test/sync/soak/soak_ci_10min_test.dart` with the supplied duration.
   - Emits a readable summary to stdout from the test's `SoakResult`.
   - Not a CI gate. Document this with a leading comment block: `# Local developer utility; not invoked by CI.`

10. **Create `.github/workflows/nightly-soak.yml`.**
    - Trigger: `schedule: - cron: '0 7 * * *'` (nightly UTC) and `workflow_dispatch`.
    - **Step 1 (first real step, per Scope line 46):** `pwsh -File tools/supabase_local_reset.ps1` — reset and seed the local Docker Supabase as a single job action before any soak invocation. This is the "reset-and-seed sequence run as a single job at the start of each nightly" mandate.
    - Step 2: invoke the soak via the PowerShell wrapper targeting `integration_test/sync/soak/soak_nightly_15min_test.dart` (no literal `flutter test` invocation in the workflow body).
    - On failure, upload the `SoakMetricsCollector` samples as a workflow artifact.
    - Do NOT wire auto-issue creation here in Phase 5. Mark the placement with a plain YAML comment: `# auto-issue creation wired in phase 7 via scripts/github_auto_issue_policy.py after three-night stability`. No runtime TODO markers.
    - Three consecutive green nights are the gate before Phase 7 allows this workflow to auto-file issues.

11. **Run `flutter analyze`, `dart run custom_lint`, and `python scripts/validate_sync_adapter_registry.py` locally.** All three must be green — this phase adds no production code, so the custom-lint-baseline must not grow.

### Exit Criteria

- `glados` is present under `dev_dependencies` in `pubspec.yaml` and `flutter pub get` succeeds.
- All four properties in `glados_invariants_test.dart` pass on the local harness before being added to CI.
- `integration_test/sync/concurrency/table_driven_fallback_test.dart` passes locally.
- `integration_test/sync/soak/soak_ci_10min_test.dart` runs green three consecutive CI runs; the `continue-on-error` flag in `.github/workflows/quality-gate.yml` is removed in the commit that declares the soak step the official pre-merge gate.
- `.github/workflows/nightly-soak.yml` runs green three consecutive nights before Phase 7 wires auto-issue filing.
- `flutter analyze` and `dart run custom_lint` stay green; `python scripts/validate_sync_adapter_registry.py` stays green.
- No changes to the 60+ sync unit tests or 15 characterization tests; they remain green.

### Local Verification

- `pwsh -Command "flutter pub get"`
- `pwsh -Command "flutter analyze"`
- `pwsh -Command "dart run custom_lint"`
- `pwsh -File tools/supabase_local_reset.ps1`
- `pwsh -File scripts/soak_local.ps1 -DurationMinutes 5`
- `python scripts/validate_sync_adapter_registry.py`

---

## Phase 6: Sync Engine Rewrite (Targeted Hotspots + Flashing Fix)

### Goal

Hit the 2-second full-sync ceiling on the Phase 1 seeded fixture (cold start, empty SQLite, fresh auth, all tables). Hit the foreground unblock ceilings (warm ≤ 500ms, cold empty-state placeholder ≤ 500ms plus fill ≤ 2s). Fix the five enumerated defects — (a), (b), (c), (d), (e) — so their Phase 3 failing repros now pass. Preserve every sync invariant; do not invoke the architectural-rewrite escape clause unless profiling against the seeded fixture demonstrates the targeted rewrite cannot clear the 2s ceiling.

### Prerequisites

- Phase 1 seeded fixture is the profiling fixture; `pwsh -File tools/supabase_local_reset.ps1` is deterministic.
- Phase 3 correctness matrix is merged; every failing repro for defects (a)–(e) is committed and stays failing until this phase fixes them.
- Phase 5 PBT + 10-min CI soak are stable on main so regressions introduced here surface immediately.
- A profiling methodology has been chosen and recorded (see step 1) — tool, fixture size, and measurement procedure are written down in a sibling doc referenced by the PR description. This is an explicit implementer decision made at the start of the phase; it is not deferred past this step.

### Files Created

None.

### Files Modified

**Sync engine hotspot rewrite:**

- `lib/features/sync/engine/pull_handler.dart`
- `lib/features/sync/engine/change_tracker.dart`
- `lib/features/sync/engine/pull_scope_state.dart`
- `lib/features/sync/application/realtime_hint_handler.dart`
- `lib/features/sync/application/realtime_hint_transport_controller.dart`
- `lib/features/sync/engine/enrollment_handler.dart`
- `lib/features/sync/engine/fk_rescue_handler.dart`
- `lib/features/sync/engine/pull_fk_violation_resolver.dart`

**Flashing fix (defects a, b, e):**

- `lib/features/projects/presentation/providers/project_provider_auth_controller.dart`
- `lib/features/projects/presentation/providers/project_provider_auth_init.dart`
- `lib/features/projects/presentation/screens/project_list_screen.dart`
- `lib/features/projects/presentation/providers/project_provider_filters.dart`

**Download-on-click fix (defect d):**

- `lib/features/projects/presentation/widgets/project_list_actions.dart` — `ProjectListActions.showDownloadConfirmation(...)` (line 82) is the confirmed click-handler entry (wired via `lib/features/projects/presentation/screens/project_list_screen.dart:211` and consumed by `project_card.dart:123` / `project_list_tab_views.dart`). The download execution path continues into `handleImport(context, entry, onRefresh: onRefresh)` on line 109 — that is the method that currently no-ops or stalls on the defect (d) repro. The fix applies inside `handleImport` (same file if defined there; otherwise trace to the import-actions companion). The `ProjectsTestingKeys.projectDownloadDialogConfirm` key already exists at line 101 — the Phase 3 repro test must drive it via that key, not a hardcoded `Key('...')`.

**Escape-clause candidates (only if profiling forces it):**

- `lib/features/sync/application/sync_coordinator.dart` (public surface) — allowed only under the escape clause and only when the escape-clause preservation list below is upheld.
- `lib/features/sync/engine/sync_engine.dart` (public surface) — same gate.

### Files Preserved (Must Not Regress)

- `lib/features/sync/engine/sync_registry.dart` and the 26-adapter FK-ordered `registerAdapters([...])` call. `scripts/validate_sync_adapter_registry.py` stays green.
- `lib/features/sync/engine/sync_error_classifier.dart` — `42501` stays non-retryable; `_classifyPostgrestError` path unchanged.
- `lib/features/sync/domain/sync_status.dart` — `SyncStatus` remains the single source of truth for transport state.
- `lib/features/sync/application/sync_coordinator.dart` — `syncLocalAgencyProjects(...)` at line 221 remains the sole public sync entrypoint (modifiable only under the escape clause, with the preservation list intact).
- `change_log` is trigger-owned; `sync_control.pulling = '1'`/`'0'` stays the only trigger-suppression bracket.
- `lib/features/sync/engine/sync_hint_remote_emitter.dart` — `emit_sync_hint` RPC ownership stays on `RpcSyncHintRemoteEmitter`.
- `lib/features/sync/application/realtime_hint_handler.dart` subscription lifecycle ownership stays with `RealtimeHintHandler`; `_minSyncInterval = Duration(seconds: 30)` stays unless profiling proves it blocks the 2s ceiling (see step 4 — explicit flag, not silent change).
- RLS company-scope via `get_my_company_id()` in all migrations under `supabase/migrations/**`.
- `SyncEngineTables.tablesWithBuiltinFilter = ['inspector_forms']`; `is_builtin = 1` skip behavior stays intact.
- Driver contract parity: `lib/core/driver/screen_registry.dart` and `lib/core/driver/screen_contract_registry.dart` stay in lockstep; `screen_registry_contract_sync` lint stays green.
- Custom lint rules: `push_handler_requires_sync_hint_emitter`, `no_sync_hint_rpc_outside_approved_owners`, `no_sync_hint_broadcast_subscription_outside_realtime_handler`, `no_client_sync_hint_broadcast_http`, `no_sync_status_column`, `sync_control_inside_transaction`, `sync_time_on_success_only`, `tomap_includes_project_id`, `max_ui_callable_length`, `max_ui_file_length`, `screen_registry_contract_sync`. No ignore comments added; no allowlist widening; no rule weakening.
- `ProjectRestoreFailureHandler` typedef and its callback signature on `ProjectProviderAuthController` (per `patterns/provider-changenotifier.md`).
- Sign-out cleanup: `AuthProvider`'s sign-out path must continue to call `RealtimeHintHandler.deactivateChannelForSignOut(...)` and clear `SyncedScopeStore`'s active assignments for the departing user. Phase 6 must not elide either — they are the hard boundary that defect (e) relies on. If the rewrite touches `AuthProvider` or `ProjectProviderAuthController`, verify both calls remain on the sign-out path.
- All 15 characterization tests under `test/features/sync/characterization/` stay green; deletions of individual characterization tests happen only when the Phase 3 harness matrix proves the same contract more honestly, each in a dedicated commit citing the replacement.

### Step-by-step Implementation

1. **Record profiling methodology.**
   - Choose the profiling tool (e.g., Dart DevTools timeline, `dart --observe`, `flutter --profile` + captured traces). Document the choice.
   - Use the Phase 1 seeded fixture as the sole profiling fixture — 1 company, 10–20 users, 15 projects, assignment matrix, FK chain. Document the row counts from the actual seeded fixture.
   - Document the measurement procedure: cold-start sequence (empty SQLite, fresh auth, first launch), three runs per condition, median reported. Warm-foreground-unblock and cold-empty-state-placeholder measurements use the same fixture with the app resumed vs. cold-launched.
   - Write this down in a sibling doc referenced by the PR description (not in `CLAUDE.md`, not as a spec edit, not in `.claude/memory/`). The doc lives in the PR body or in `docs/` if the implementer prefers a committed record.

2. **Capture baseline measurements.**
   - Run the profiling procedure against `main` (or the branch point) on the seeded fixture. Record cold-start full-sync duration, warm foreground unblock duration, and cold empty-state placeholder timing.
   - Also run the Phase 3 matrix repros for defects (a)–(e) and capture their current failure signatures. These are the regression guards.

3. **Parallelize `pull_handler.dart` where FK safety allows.**
   - In `lib/features/sync/engine/pull_handler.dart`, group tables into independent-subgraphs using `SyncRegistry.instance.dependencyOrder` and `childFkColumnsFor(...)`. FK parents still come before FK children; siblings that share no parent can pull in parallel.
   - Bound parallelism per subgraph to avoid saturating the local SQLite writer.
   - Do not change the adapter order in `sync_registry.dart`. Do not reorder `simpleAdapters` in `lib/features/sync/adapters/simple_adapters.dart`.
   - Re-run `python scripts/validate_sync_adapter_registry.py` after the change; it must stay green.

4. **Optimize `change_tracker.dart` cursor advancement.**
   - In `lib/features/sync/engine/change_tracker.dart`, profile the cursor-advance path during a full sync. If batching cursor writes (one write per table, not one per record) clears the hotspot without weakening monotonicity, apply that.
   - Verify the monotonicity property from Phase 5's `glados_invariants_test.dart` still passes.

5. **Optimize `pull_scope_state.dart` enrollment efficiency.**
   - In `lib/features/sync/engine/pull_scope_state.dart`, eliminate redundant re-reads of `SyncedScopeStore.getActiveAssignmentProjectIds` per table during a single pull. Cache the scope set for the duration of one `_executePull(...)` cycle in `SyncEngine`.
   - Confirm `LocalSyncStoreScope.getActiveAssignmentProjectIds` is not shadowed — presentation code must still see the same scope set.

6. **Fix defect (c): new-user-to-old-project assignment propagation.**
   - In `lib/features/sync/engine/enrollment_handler.dart`, ensure that when a new assignment row lands during a pull, the pull extends scope to include the newly-assigned project within the same run (not deferred to the next cycle). Coordinate with `SyncedScopeStore` so the enrollment takes effect before the first record for that project is pulled.
   - The Phase 3 repro in `integration_test/sync/matrix/assignments_matrix_test.dart` must now pass.

7. **Harden `fk_rescue_handler.dart` and `pull_fk_violation_resolver.dart`.**
   - Ensure integrity + propagation: when a child record arrives before its parent, rescue-fetch the parent in-cycle rather than dropping or deferring. Log every rescue via `Logger.sync(LogEventClasses.fkRescue, data: {...})` (Phase 4 event class).
   - No manual inserts into `change_log`; any state mutation goes through normal adapter write paths with `sync_control.pulling = '1'` where triggers must be suppressed.

8. **Tune realtime-hint fan-out.**
   - In `lib/features/sync/application/realtime_hint_handler.dart` and `lib/features/sync/application/realtime_hint_transport_controller.dart`, profile `_handleHint(Map)` + `_triggerQuickSync(...)` + `_drainQueuedQuickSync()` for fan-out latency.
   - `_minSyncInterval = Duration(seconds: 30)` is a warm-path throttle, not a cold-start constraint; it is not expected to affect the 2-second cold-start ceiling. If profiling nevertheless shows it as a binding constraint, any change to the constant is a deliberate tuning decision that must be called out explicitly in the PR description — do not bury it inside a hotspot commit.
   - Subscription lifecycle ownership and `deactivate_sync_hint_channel` RPC calls stay with `RealtimeHintHandler`; do not relocate.

9. **Flashing fix — atomic `_loadAssignments` + `_loadProjectsByCompany`.**
   - In `lib/features/projects/presentation/providers/project_provider_auth_controller.dart`, replace the two independent `unawaited(...)` calls in `onAuthChanged` (and the initial-load path in `initWithAuth`) with a single awaited `Future.wait([...])` barrier before `_setInitializing(false)` and before the first `notifyListeners()` call on this auth transition. Follow the exact shape in `source-excerpts/by-concern.md`:

     ```dart
     if ((userOrRoleChanged && newUserId != null) ||
         (newCompanyId != null && newCompanyId != lastLoadedCompanyId)) {
       lastLoadedCompanyId = newCompanyId;
       _setInitializing(true);
       await Future.wait([
         if (userOrRoleChanged && newUserId != null) _loadAssignments(newUserId),
         if (newCompanyId != null) _loadProjectsByCompany(newCompanyId),
       ]);
       _setInitializing(false);
       unawaited(syncCoordinator.syncLocalAgencyProjects(mode: SyncMode.quick));
     }
     ```

   - Preserve the `ProjectRestoreFailureHandler` typedef and the callback signature on the controller. Do not rename or retype it.
   - Do not introduce a skeleton-then-filter pattern; per Scope, the first render must see the filtered list.

10. **Flashing fix — initial state application.**
    - In `lib/features/projects/presentation/providers/project_provider_auth_init.dart`, ensure the initial assignment filter is applied to the initial state BEFORE the first `notifyListeners()` call fires. Read `_assignedProjectIds` at the point of initial list materialization; do not populate `_projects` first and filter later.

11. **Flashing fix — screen first-frame guarantee.**
    - In `lib/features/projects/presentation/screens/project_list_screen.dart`, confirm the first render path consumes the filtered list exposed by `ProjectProviderFilters.visibleProjects` (or equivalent getter), not `_projects` directly. If the screen currently references the unfiltered list in any branch, switch it to the filtered getter. `mounted` checks after async gaps stay intact.

12. **Flashing fix — defense-in-depth client filter.**
    - In `lib/features/projects/presentation/providers/project_provider_filters.dart`, confirm the client filter already applied by `visibleProjects` remains authoritative on the presentation side. RLS is the hard boundary; the client filter is defense-in-depth for the server-to-client propagation window (per Scope "Concurrent-mutation source of truth"). Do not weaken either.

13. **Fix defect (d): download-on-click.**
    - Edit `lib/features/projects/presentation/widgets/project_list_actions.dart`. `showDownloadConfirmation` (line 82) dispatches to `handleImport(context, entry, onRefresh: onRefresh)` on line 109 when the user confirms. Trace `handleImport` and apply the fix at the site where the download currently no-ops or stalls (missing await, missing `SyncStatus.downloadProgress` advancement, or an early `return` on a guard that should be non-fatal).
    - Log `LogEventClasses.downloadInitiate`, `downloadComplete`, `downloadFail` at the confirmed + completed + error branches (per Phase 4 event classes).
    - Drive the Phase 3 repro through `ProjectsTestingKeys.projectDownloadDialogConfirm` (already present at line 101); no hardcoded `Key('...')`.
    - Confirm `integration_test/sync/matrix/download_on_click_test.dart` now passes.

14. **Re-run profiling against the rewritten code.**
    - Execute the same measurement procedure from step 1 against the seeded fixture. Capture: cold-start full-sync duration, warm foreground unblock, cold empty-state placeholder + fill.
    - If any of the three ceilings is missed, iterate on steps 3–8. The escape clause (step 15) is available only after targeted iteration has been exhausted.

15. **Escape clause gate (conditional).**
    - Only if profiling after step 14 shows the 2s ceiling cannot be reached by targeted hotspot rewrite, consider contract-level changes to `SyncCoordinator.syncLocalAgencyProjects` or `SyncEngine.pushAndPull` public surface.
    - Even under the escape clause, preserve: `SyncRegistry` adapter-registration order and the 26-adapter FK sequence; `scripts/validate_sync_adapter_registry.py` stays green; all custom lint rules stay green; `SyncErrorClassifier` ownership of classification and `42501` non-retryable; `SyncStatus` as state of truth; `change_log` trigger ownership; `sync_control.pulling` bracket; `is_builtin = 1` skip. Document the contract change explicitly in the PR description; the change is not silent.

16. **Re-run Phase 3 matrix and Phase 5 PBT/soak locally.**
    - All five defect repros now pass. No matrix regression for non-defect flows.
    - `glados_invariants_test.dart` stays green (LWW, cursor monotonicity, enrollment/teardown, tombstone propagation).
    - Local 10-min soak via `scripts/soak_local.ps1` stays green.

17. **Run all lint + validator checks locally before PR.**
    - `flutter analyze`, `dart run custom_lint`, `python scripts/validate_sync_adapter_registry.py`, `python scripts/verify_database_schema_platform_parity.py`. All green. No custom-lint-baseline growth.

### Exit Criteria

- Cold-start full sync completes ≤ 2 seconds on the Phase 1 seeded fixture (median of three runs).
- Foreground unblock warm path completes ≤ 500ms.
- Cold empty-state placeholder renders ≤ 500ms with fill completing ≤ 2s.
- All five enumerated defect repros committed in Phase 3 now pass:
  - (a) flashing on refresh — `integration_test/sync/matrix/flashing_repro_test.dart`
  - (b) flashing on app resume — `integration_test/sync/matrix/flashing_repro_test.dart`
  - (c) new-user-to-old-project assignment — `integration_test/sync/matrix/assignments_matrix_test.dart`
  - (d) download-on-click — `integration_test/sync/matrix/download_on_click_test.dart`
  - (e) flashing on auth transition — `integration_test/sync/matrix/flashing_repro_test.dart`
- No new lint violations; `flutter analyze` and `dart run custom_lint` green; custom-lint-baseline file unchanged or shrunk, never grown.
- `python scripts/validate_sync_adapter_registry.py` green; adapter registration order unchanged.
- All 15 characterization tests under `test/features/sync/characterization/` still green (or deleted case-by-case with commits citing the replacing harness test).
- The Phase 5 `glados` properties and 10-min soak stay green.
- Profiling methodology + baseline and post-rewrite numbers are recorded in the PR description.

### Local Verification

- `pwsh -Command "flutter analyze"`
- `pwsh -Command "dart run custom_lint"`
- `python scripts/validate_sync_adapter_registry.py`
- `python scripts/verify_database_schema_platform_parity.py`
- `pwsh -File tools/supabase_local_reset.ps1`
- `pwsh -File scripts/soak_local.ps1 -DurationMinutes 10`
- `pwsh -File scripts/audit_logging_coverage.ps1` to confirm Phase 4 coverage still passes against the rewritten files.

---

## Phase 7: Staging Supabase + CI Gate + GitHub Auto-Issue Policy

### Goal

Make harness-green the mergeable gate for every sync-touching PR. Make the Sentry → GitHub pipeline the triage gate. Ship MVP to pre-alpha users when all five ship-bar conditions hold simultaneously: correctness matrix green (Phase 3), all five enumerated defects fixed (Phase 6), soak green (Phases 5 + 7), 2-second full-sync met (Phase 6), logging/Sentry/GitHub pipeline live (Phases 4 + 7).

### Prerequisites

- Phase 5 10-min CI soak has run green three consecutive CI runs and is no longer `continue-on-error: true`.
- Phase 5 nightly 15-min soak has run green three consecutive nights.
- Phase 6 is merged: 2s ceiling met, all five defect repros pass, lint + validators green.
- Phase 4 Sentry dedup middleware + event-class audit are live.
- External provisioning (outside repo — called out here as explicit ops steps, not code changes):
  - Dedicated staging Supabase project provisioned on Pro plan ($25/month).
  - Secrets populated in GitHub Actions repository secrets and Codemagic env-var groups: `STAGING_SUPABASE_DATABASE_URL`, `STAGING_SUPABASE_URL`, `STAGING_SUPABASE_ANON_KEY`, `STAGING_SUPABASE_SERVICE_ROLE_KEY`.
  - Sentry Log Drain ingestion endpoint wired in coordination with the Phase 4 sink decision.
  - Sentry → GitHub webhook configured at the Sentry project level; webhook target is the repository's `Issues` API scoped to a GitHub App with minimum-required permissions.

### Files Created

- `.github/workflows/staging-schema-gate.yml`
- `scripts/hash_schema.py`
- `scripts/github_auto_issue_policy.py`
- `scripts/check_perf_regression.py`
- `scripts/perf_baseline.json`

### Files Modified

- `.github/workflows/quality-gate.yml`
- `.github/workflows/nightly-soak.yml` (created in Phase 5)

### Files Preserved (Must Not Regress)

- The existing `Sync lint violations to GitHub Issues` step behavior in `.github/workflows/quality-gate.yml` — the new shared policy generalizes it, it does not replace the fingerprint-by-rule dedup the step currently implements.
- Every CI job currently green stays green: `analyze-and-test`, `architecture-validation`, `security-scanning`.
- `python scripts/validate_sync_adapter_registry.py`, `python scripts/check_changed_migration_rollbacks.py`, `python scripts/validate_migration_rollbacks.py`, `python scripts/verify_database_schema_platform_parity.py`, `python scripts/verify_live_supabase_schema_contract.py` all stay green on their existing triggers.
- `lib/features/sync/application/sync_coordinator.dart` as the single sync entrypoint; the new gates exercise it, they do not bypass it.
- Adapter-registration order in `lib/features/sync/engine/sync_registry.dart`.
- `SyncErrorClassifier` ownership, `SyncStatus` authority, `change_log` trigger ownership, `sync_control.pulling` bracket, RLS company-scope via `get_my_company_id()`, `42501` non-retryable, `is_builtin = 1` skip.
- Existing custom lint rules; no ignore comments; no allowlist widening.
- PowerShell wrappers under `tools/` remain canonical for local developer flows.

### Step-by-step Implementation

1. **Capture external provisioning as explicit ops steps in the PR description.**
   - Staging Supabase project on Pro plan provisioned (owner, region, cost attribution recorded).
   - Repository and workflow secrets populated: `STAGING_SUPABASE_DATABASE_URL`, `STAGING_SUPABASE_URL`, `STAGING_SUPABASE_ANON_KEY`, `STAGING_SUPABASE_SERVICE_ROLE_KEY`. Codemagic env-var groups updated in parallel.
   - Sentry Log Drain endpoint live and healthy on the staging Supabase project console (inherits Phase 4's sink decision).
   - Sentry → GitHub webhook configured at the Sentry project level; target is the GitHub App-gated Issues API path.
   - These are not code changes; they block the code changes below from going live.

2. **Create `scripts/hash_schema.py`.**
   - Stdlib-only per `patterns/python-ci-validator.md`; zero pip installs.
   - Takes `--db-url` (repeatable) arguments for each database to hash (local Docker, staging, and prod when `PROD_SUPABASE_DATABASE_URL` is set).
   - For each database, queries via `supabase db query --db-url ...` (same invocation pattern as `scripts/verify_live_supabase_schema_contract.py`) to fetch:
     - Normalized `information_schema.columns` rows for `public` schema, ordered by `table_name`, `column_name`.
     - `pg_policies` rows for `public` schema, ordered by `tablename`, `policyname`.
   - Computes a SHA-256 of the concatenated normalized output for each DB. Emits one line per DB: `<db-label>: <hash>`.
   - Exit code 1 on drift between any two DBs; exit code 0 only when all provided DBs hash identically.
   - Hand-rolled parsing only; no third-party SQL libraries. Follow the `validate() → list[str]` / `main()` pattern in `patterns/python-ci-validator.md`.

3. **Create `.github/workflows/staging-schema-gate.yml`.**
   - Triggers: `pull_request` on branches touching `supabase/migrations/**` or `lib/core/database/schema/**`, plus `workflow_dispatch`.
   - Steps:
     - Install `supabase` CLI.
     - Spin up local Docker Supabase via `tools/supabase_local_reset.ps1` to capture the local hash.
     - Run `python scripts/hash_schema.py --db-url <local> --db-url <staging> --db-url <prod-if-set>`.
     - On nonzero exit, append the failure summary to `$GITHUB_STEP_SUMMARY` per the shape in `patterns/python-ci-validator.md` and exit 1.
   - **Migration-promotion rule**: the job fails (blocking prod apply) on any commit where the prod hash lags behind staging's hash — i.e., prod has a migration not applied cleanly on staging, or staging has a migration not yet applied to prod that the commit intends to promote. This enforces Scope success criterion 9.

4. **Create `scripts/github_auto_issue_policy.py`.**
   - Stdlib-only per `patterns/python-ci-validator.md`.
   - Exposes a callable interface invoked by CI: reads input events from stdin (JSON lines), writes decisions to stdout, exits 0.
   - Input event shape (minimum): `{source: 'lint'|'sentry'|'nightly-soak', fingerprint: <stable string>, severity: 'fatal'|'error'|'warning', userIdHashes: [<sha256-first-8-hex>], occurrences: N, firstSeen: ISO8601, lastSeen: ISO8601}`. The field is `userIdHashes`, not `userIds` — GitHub Issues are readable by all repo collaborators (and world-readable if the repo is public); raw Supabase UUIDs or email-shaped identifiers must never reach issue titles/bodies. Caller-side feeds (lint wrapper, Sentry webhook receiver, nightly-soak output) MUST hash userIds before stdin injection. The script refuses (exits 1 with a clear error) to emit any field matching an email-shape regex or bare UUID into the generated issue title/body.
   - Policy implemented per Scope success criterion 10:
     - **Fingerprint grouping**: dedup by `(source, fingerprint)`.
     - **Rate limit**: 1 issue per fingerprint per 24 hours (no reopen spam).
     - **Creation threshold**: create an issue only when `distinct userIdHashes ≥ 2` OR `occurrences ≥ 5 within 15 minutes`.
     - **Auto-close**: close 7 days after the last event if zero new events.
     - **Severity routing**: `fatal` creates immediately (bypasses threshold); `error` follows threshold; `warning` is digest-only (no individual issue).
     - **Stability grace**: for `source: 'nightly-soak'`, require three consecutive green nights before the policy is allowed to auto-file for that source. Reject (no-op) events from that source until the stability flag is set. **Storage mechanism (committed to this decision): a GitHub Actions repository variable** named `AUTO_ISSUE_SOAK_STABILITY_FLAG` (values `'pending'` / `'armed'`). The nightly-soak workflow increments a green-nights counter variable `AUTO_ISSUE_SOAK_GREEN_STREAK` via `gh variable set` on each green run and flips `AUTO_ISSUE_SOAK_STABILITY_FLAG` to `'armed'` on reaching 3. The policy script reads both via `gh variable get`. No committed JSON state file (avoids CI write-back commits, permission churn, and racy `git` writes).
   - Labels on created issues: `automated`. Additional source-specific labels: `lint,tech-debt` for lint; `sentry,triage` for Sentry; `soak,regression` for nightly soak.
   - Dedup must not conflict with existing lint issues created by the current `Sync lint violations to GitHub Issues` step — the policy generalizes the existing shape rather than replacing it, so pre-existing open issues are honored and deduped against.

5. **Modify `.github/workflows/quality-gate.yml`.**
   - Extend the existing `Sync lint violations to GitHub Issues` step: pipe its per-rule FILE-LINE enumeration into `scripts/github_auto_issue_policy.py` as `source: 'lint'` events. The script becomes the issue-creation author; the current inline logic is replaced by the script delegation. Existing per-rule dedup behavior is preserved because the new policy generalizes fingerprinting.
   - **Retarget the Phase 5 `Soak test (10-min)` step to staging** (do not add a second soak step). Flip the dart-defines from `HARNESS_SUPABASE_URL`=local to `STAGING_SUPABASE_URL` + `STAGING_SUPABASE_ANON_KEY`, so PRs are gated against real staging RLS and a real network path. Rename the step to `Soak test (10-min, staging)` in the same commit. This is the single canonical 10-min soak gate that satisfies Success criteria 3 and 12; Scope's "10-min CI soak against staging" requirement is met by this step, not by a parallel workflow.
   - **Service-role exclusion.** The `Soak test (10-min, staging)` step (and every Flutter-run step on sync-touching PRs) MUST pass only `STAGING_SUPABASE_URL` and `STAGING_SUPABASE_ANON_KEY` into the Flutter process env. `STAGING_SUPABASE_SERVICE_ROLE_KEY` stays scoped to `scripts/hash_schema.py` and seed/reset ops; it must not be exposed as an env var on any step that invokes `flutter` or `flutter drive`. Add a workflow-level preflight step that fails if `${{ env.STAGING_SUPABASE_SERVICE_ROLE_KEY }}` is non-empty at the time the Flutter step is reached. The harness's `HarnessAuthConfig` assertion (Phase 2) is the runtime defense-in-depth for this.
   - Add a `Staging schema-hash gate` step that invokes the new `.github/workflows/staging-schema-gate.yml` workflow (via `uses:` or an equivalent reusable-workflow call) so migration drift blocks merge.
   - Add a `Perf regression gate (+10%)` step (Success criterion 6). Invokes `python scripts/check_perf_regression.py --baseline scripts/perf_baseline.json --actual <post-soak-metrics-path>`. The soak step emits a metrics JSON artifact (cold-start-sync-ms median) which the regression script consumes. Fails if measured cold-start full-sync exceeds `baseline × 1.10` OR exceeds the 2000ms ceiling. Baseline is committed at Phase 6 merge time and rolled forward by a dedicated commit (documented in the script header) when a legitimate regression is accepted.

6. **Modify `.github/workflows/nightly-soak.yml`.**
   - Wire the nightly soak output through `scripts/github_auto_issue_policy.py` as `source: 'nightly-soak'` events.
   - The policy's stability grace prevents auto-filing until three consecutive green nights have been recorded after the policy goes live; remove the plain YAML comment placed in Phase 5 step 10 now that the wiring exists.

7. **Wire Sentry webhook events into the policy.**
   - The Sentry → GitHub webhook configured in step 1 posts payloads to a small receiver (a GitHub Actions workflow triggered on `repository_dispatch`, or the GitHub App's webhook endpoint).
   - Receiver normalizes Sentry payloads into the `scripts/github_auto_issue_policy.py` input shape as `source: 'sentry'` events.
   - The policy's severity routing maps Sentry event `level: fatal | error | warning` directly.

8. **Re-run the 2-second ceiling measurement against staging.** Spec Success criterion 4 names the 2s target "against staging," not local Docker. After staging is provisioned and the seed has run via `supabase db reset` against `STAGING_SUPABASE_DATABASE_URL`, re-execute the Phase 6 profiling procedure (cold-start full sync, warm foreground unblock, cold empty-state placeholder + fill) with the Flutter client pointed at `STAGING_SUPABASE_URL`. Record the staging numbers alongside the Phase 6 Docker numbers in the PR description. The ship-bar bullet "2-second full-sync met" (step 9) refers explicitly to the staging measurement, not the Docker measurement.

9. **Run the ship-bar conjunctive check.**
   - Before cutting the pre-alpha user release, confirm in the PR description (as a checklist) that ALL FIVE conditions below hold simultaneously:
     - Correctness matrix green (Phase 3).
     - All five enumerated defects fixed (Phase 6).
     - Soak green — canonical 10-min CI soak (retargeted at staging in step 5) + nightly 15-min soak both passing three consecutive times.
     - 2-second full-sync met **against staging** (step 8 above).
     - Logging/Sentry/GitHub pipeline live (Phases 4 + 7), +10% perf regression gate wired (step 5).
   - If any condition fails, do not cut the release. Do not ship partial.

10. **Cut the pre-alpha user release.**
    - Tag the commit that satisfies the ship-bar. The delivery mechanism for pre-alpha users is explicitly handled outside this spec per Open Questions — this step simply marks the commit as ship-eligible.

11. **Local + CI verification.**
    - Run the new workflows end-to-end in a test PR and confirm: staging schema hash gate blocks merge on a synthetic drift; the shared auto-issue policy creates, dedups, and auto-closes correctly for a synthetic lint event, a synthetic Sentry event, and a synthetic nightly-soak event; the perf regression gate fails on a seeded +15% regression and passes on a seeded +5% delta.

### Exit Criteria

- Every sync-touching PR (per the path filter) runs the single canonical harness matrix + PBT + 10-min soak step **against staging** before merge (the Phase 5 step, retargeted in step 5). No duplicate local-Docker soak step survives on the sync-touching path.
- The staging schema-hash gate blocks any prod migration on a commit whose migration is not already applied cleanly on staging.
- The `+10%` perf regression gate (`scripts/check_perf_regression.py`) is wired into the workflow; it fails on measured cold-start regressions above baseline × 1.10 or above 2000ms.
- `scripts/github_auto_issue_policy.py` is the single auto-issue author for lint, Sentry, and nightly-soak sources; it enforces fingerprint grouping, 1-issue-per-fingerprint-per-24h rate limit, ≥2-user-or-≥5-occurrences-in-15-min creation threshold, 7-day auto-close on zero new events, severity routing (`fatal` immediate / `error` threshold / `warning` digest-only), and a three-night stability grace for nightly-soak (mechanism: `AUTO_ISSUE_SOAK_STABILITY_FLAG` + `AUTO_ISSUE_SOAK_GREEN_STREAK` GitHub Actions repository variables). Issue payloads carry only hashed user identifiers; no raw emails or UUIDs.
- `STAGING_SUPABASE_SERVICE_ROLE_KEY` is never exposed to any Flutter-invoking workflow step; preflight guard confirms this on every run.
- Staging-targeted 2-second cold-start measurement (step 8) recorded in the ship-bar PR; ≤ 2s median of three runs.
- All pre-existing CI jobs stay green. `scripts/validate_sync_adapter_registry.py`, `check_changed_migration_rollbacks.py`, `validate_migration_rollbacks.py`, `verify_database_schema_platform_parity.py`, and `verify_live_supabase_schema_contract.py` continue to pass on their existing triggers.
- All five ship-bar conditions hold simultaneously; the pre-alpha release tag is cut from the commit where they all hold.
- `flutter analyze` and `dart run custom_lint` remain green; no custom-lint-baseline growth.

### Local Verification

- `pwsh -Command "flutter analyze"`
- `pwsh -Command "dart run custom_lint"`
- `python scripts/hash_schema.py --db-url "$env:STAGING_SUPABASE_DATABASE_URL"` (with local Docker running alongside for comparison)
- `python scripts/github_auto_issue_policy.py < test/fixtures/auto_issue_policy_sample_events.jsonl` (implementer supplies a local fixture file of synthetic events; not committed unless useful as a regression seed)
- `python scripts/validate_sync_adapter_registry.py`
- `python scripts/verify_database_schema_platform_parity.py`
- `python scripts/verify_live_supabase_schema_contract.py` (when `LIVE_SUPABASE_DATABASE_URL` is set locally)
