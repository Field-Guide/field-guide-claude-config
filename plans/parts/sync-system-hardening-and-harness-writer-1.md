## Phase 1: Local Docker Supabase + Seeded Fixture

### Goal

Boot local Docker Supabase from the current 71 migrations with a deterministic, seeded multi-project fixture (one company, ~10–20 `auth.users` with matching `user_profiles`, ≥5 projects, a `project_assignments` matrix that exercises cross-role leakage, and FK-connected child rows across `daily_entries`, `bid_items`, `personnel_types`, `equipment`, `contractors`, `locations`, `photos`). The output is a reproducible local environment the Phase 2 harness can authenticate into.

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
   - Resolve the repo root.
   - `Push-Location` to the repo root.
   - Run `supabase db reset` (the CLI applies every file in `supabase/migrations/` in timestamp order, then executes `supabase/seed.sql`).
   - `Pop-Location` in a `finally` block.
   - Exit non-zero on CLI failure so CI catches migration regressions.

3. Author `supabase/seed.sql` as a deterministic, idempotent seed script. Use fixed UUIDs (hand-picked constant UUID literals, not `gen_random_uuid()`) so every reseed produces the same IDs and the harness can reference them directly. Structure the file as:
   - Header comment block stating: "Harness fixture — seeded via `supabase db reset`. Service-role context. No `change_log` or `sync_control` interaction — those are local SQLite constructs only."
   - One `INSERT INTO public.companies (id, name, created_at, updated_at) VALUES (...)` for a single fixture company (e.g., id `00000000-0000-0000-0000-000000000001`, name `"Harness Test Co"`).
   - A block of 12 `INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)` rows — 1 admin, 2 engineer, 1 office_technician, 8 inspector (total 12, satisfying the ≥1 admin, ≥2 engineer, ≥1 office_technician, ≥5 inspector distribution and landing inside the 10–20 band). Use deterministic UUIDs whose low bits encode the role (e.g., `...-a001` admin, `...-e001`/`...-e002` engineers, `...-o001` office_technician, `...-i001`..`...-i008` inspectors) and emails of the form `admin@harness.test`, `engineer1@harness.test`, `inspector1@harness.test`, etc. Set `email_confirmed_at = now()` so the harness can sign in without a mail flow. Store `encrypted_password` by calling `crypt('HarnessPass!1', gen_salt('bf'))` (the `pgcrypto` extension is already available via earlier migrations).
   - A matching `INSERT INTO public.user_profiles (id, user_id, company_id, role, full_name, is_approved, can_manage_projects, can_edit_field_data, can_manage_project_field_data, created_at, updated_at)` for every `auth.users` row. Use `UserRole` values that map 1:1 to the Dart enum in `lib/features/auth/data/models/user_role.dart`: `'admin'`, `'engineer'`, `'office_technician'`, `'inspector'`. Every profile has `is_approved = true`. Capability flags match what `AuthProvider` exposes: admin/engineer/office_technician get `can_manage_projects = true`; inspector/engineer/office_technician get `can_edit_field_data = true`; engineer/office_technician/admin get `can_manage_project_field_data = true`. Do not fabricate new capability columns — use only columns present after the 71 migrations.
   - A block of 6 `INSERT INTO public.projects (id, company_id, name, created_at, updated_at, ...)` rows (project ids `...-p001`..`...-p006`). Use only columns declared by the migrations. No `sync_status` column (prohibited by `no_sync_status_column` lint and by the sync rules in CLAUDE.md).
   - A `project_assignments` matrix sized so that:
     - Every inspector (i001..i008) has at least one project they ARE assigned to.
     - Every inspector has at least one project they are NOT assigned to (for cross-role leakage tests in Phase 3).
     - Concretely: assign i001..i004 to projects p001/p002; assign i005..i008 to projects p003/p004; leave p005 and p006 unassigned to any inspector (admin/engineer-only visibility check).
     - Assign both engineers (e001, e002) to p001..p004.
     - Assign office_technician (o001) to p005, p006.
     - Admin (a001) gets no explicit assignment row (admin access comes through role, not `project_assignments`).
   - Under projects p001, p002, p003: seed an FK-connected child graph to exercise the FK chain exactly the way `scripts/validate_sync_adapter_registry.py` expects. Seed in strict FK-parent-first order matching the registry sequence in `lib/features/sync/engine/sync_registry.dart`:
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

5. Verify the fixture content matches the matrix with `psql`-style probes (run via `supabase db query` or `psql $SUPABASE_DATABASE_URL`):
   - `SELECT role, COUNT(*) FROM public.user_profiles GROUP BY role;` returns admin=1, engineer=2, office_technician=1, inspector=8.
   - `SELECT COUNT(*) FROM public.projects WHERE company_id = '<harness company id>';` returns 6.
   - `SELECT user_id, COUNT(project_id) FROM public.project_assignments GROUP BY user_id;` shows every inspector on at least one project.
   - `SELECT p.id FROM public.projects p WHERE NOT EXISTS (SELECT 1 FROM public.project_assignments a WHERE a.project_id = p.id AND a.user_id IN (<inspector ids>));` returns a non-empty set (proves unassigned-to-inspectors projects exist for leakage tests).
   - `SELECT l.project_id, COUNT(*) FROM public.locations l GROUP BY l.project_id;` shows ≥2 for each of p001/p002/p003.
   - `SELECT de.project_id, de.location_id FROM public.daily_entries de;` shows each entry's `location_id` refers to a row in `locations` with the same `project_id` (FK chain integrity).
   - `SELECT COUNT(*) FROM public.photos;` returns ≥3 (one per seeded daily entry).

6. Confirm the seed preserves migration compatibility:
   - Run `python scripts/validate_sync_adapter_registry.py` from the repo root. It must still pass — the seed must not introduce a table name that is in `triggeredTables` but missing from an adapter (it only uses existing tables).
   - Run `python scripts/verify_live_supabase_schema_contract.py` against the local Docker URL (`SUPABASE_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:54322/postgres`). It must confirm that registered tables exist, RLS is enabled, and RLS policy count > 0 — all already true because the seed does not alter schema.

### Exit Criteria

- `pwsh -File tools/supabase_local_reset.ps1` boots the local stack, applies all 71 migrations, and executes `supabase/seed.sql` end-to-end without error.
- Manual `psql` probe (step 5) confirms: 1 company, 12 `auth.users`, role distribution 1/2/1/8, 6 projects, assignment matrix covers "every inspector IS on at least one project" and "every inspector is NOT on at least one project", FK chain integrity across locations/contractors/equipment/bid_items/personnel_types/daily_entries/photos for the seeded subset.
- `scripts/validate_sync_adapter_registry.py` and `scripts/verify_live_supabase_schema_contract.py` (local URL) stay green.
- No `sync_status` column referenced anywhere in `supabase/seed.sql` (ripgrep must return zero matches for `sync_status` in the seed).
- No `is_builtin = 1` inserts anywhere in `supabase/seed.sql`.

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
  - `Future<void> assertLocalScopeMatchesServerAssignment({required HarnessDriverClient driver, required HarnessFixtureCursor fixture})` — pulls the local `synced_scope_store` state (via `SyncedScopeStore.getActiveAssignmentProjectIds` exposed through existing diagnostics) and checks equality against the server-side `project_assignments` for the signed-in user.
- `integration_test/sync/harness/harness_fixture_cursor.dart` — Walks the Phase 1 seeded fixture. Loads the deterministic UUIDs declared in `supabase/seed.sql` (hard-coded as constants mirrored from the SQL file — single source of truth: a `HarnessFixtureIds` class that the SQL comments reference for cross-check). Exposes `Iterable<String> projectsAssignedTo(String userId)`, `Iterable<String> projectsNotAssignedTo(String userId)`, `Iterable<String> inspectorUserIds`, etc. Read-only; no mutation of the fixture.
- `test/harness/harness_auth_helpers_test.dart` — Unit-speed test (no driver, no Flutter integration binding) that validates `HarnessFixtureIds` constants match the fixture counts from the spec (1 admin, 2 engineer, 1 office_technician, 8 inspector; 6 projects) and that the `HarnessAuth` helper exposes the four role entrypoints with correct signatures. Does not hit Supabase.
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
   - Define `class HarnessFixtureIds` with `static const` String fields for every deterministic UUID seeded in `supabase/seed.sql` (`companyId`, `adminUserId`, `engineer1UserId`, `engineer2UserId`, `officeTechnicianUserId`, `inspector1UserId` .. `inspector8UserId`, `project1Id` .. `project6Id`). The values must match the SQL exactly; add a doc comment at the top of both files cross-referencing each other as the source-of-truth pair.
   - Define `class HarnessFixtureCursor` with pure-Dart methods:
     - `Set<String> projectsAssignedTo(String userId)` — returns the assignment matrix from Phase 1 step 3 (i001..i004 → {p001, p002}; i005..i008 → {p003, p004}; e001/e002 → {p001..p004}; o001 → {p005, p006}; admin → empty, admin visibility is role-based).
     - `Set<String> projectsNotAssignedTo(String userId)` — complement within the 6-project set.
     - `List<String> get inspectorUserIds`, `List<String> get engineerUserIds`, `String get officeTechnicianUserId`, `String get adminUserId`.
     - `Set<String> get allProjectIds`.
   - No Flutter imports in this file (it is pure Dart). No SDK calls. This lets `test/harness/*` import it at unit-test speed.

3. Author `integration_test/sync/harness/harness_auth.dart`:
   - Import `package:supabase_flutter/supabase_flutter.dart`.
   - Import the existing `AuthProvider` from `lib/features/auth/presentation/providers/auth_provider.dart` so sign-in flows the same state-change path the production app uses (`_authService.authStateChanges` listener at line 101 of `auth_provider.dart`).
   - Define `class HarnessAuthConfig` with local-Docker constants: `supabaseUrl` (`http://127.0.0.1:54321`), `supabaseAnonKey` (read from a Phase 1 `.env.harness` file or a hard-coded dev anon key — never the prod key), `password` (`'HarnessPass!1'` — the seed password from Phase 1). A guard `assert(!supabaseUrl.contains('supabase.co'))` ensures the harness never points at prod or staging.
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
   - `Future<void> assertLocalScopeMatchesServerAssignment({required HarnessDriverClient driver, required HarnessFixtureCursor fixture, required String signedInUserId})`:
     - Fetch `/diagnostics/sync_runtime` via the driver client.
     - Read the dirty-scope / active-scope list from the payload. If the harness needs `SyncedScopeStore.getActiveAssignmentProjectIds` surfaced and the current `/diagnostics/sync_runtime` does not already publish it, do NOT extend the driver route in Phase 2 — instead, record the gap in the plan's Phase 3 intake and have Phase 3 add the new state key together with its `screen_contract_registry.dart` + `TestingKeys` counterparts. Phase 2 asserts against what the current routes already publish (`dirtyScopes[]` projects, `stateFingerprint`).
     - Expected: the set of project ids in the local scope equals `fixture.projectsAssignedTo(signedInUserId)`.

6. Create `test/harness/` directory. Author `test/harness/harness_auth_helpers_test.dart`:
   - Unit test. Imports `package:flutter_test/flutter_test.dart` and the pure-Dart `harness_fixture_cursor.dart`. No `integration_test` import, no `SupabaseClient` construction.
   - `test('HarnessFixtureIds matches spec role distribution', () { ... })` — asserts `fixture.inspectorUserIds.length == 8`, `fixture.engineerUserIds.length == 2`, `fixture.allProjectIds.length == 6`, and the admin/office_technician ids are non-empty.
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
   - `rg -n "supabase\\.co" integration_test/sync/harness` returns zero matches (prod-URL guard).

9. End-to-end manual smoke (documented here as the exit criterion for Phase 2, not executed via a repo script):
   - Start local Docker Supabase: `pwsh -File tools/supabase_local_start.ps1`.
   - Reset + seed: `pwsh -File tools/supabase_local_reset.ps1`.
   - Start the Flutter driver: `pwsh -File tools/start-driver.ps1`, wait with `pwsh -File tools/wait-for-driver.ps1`.
   - From a Dart REPL or a developer-driver script, instantiate `HarnessAuth`, sign in as each of the four roles, confirm `AuthProvider.isAdmin` / `isEngineer` / `isOfficeTechnician` / `isInspector` flips correctly.
   - For inspector1, call `HarnessAssertions.assertInspectorSeesOnlyAssigned` — the real Supabase `select * from public.projects` returns exactly `{project1Id, project2Id}` (the fixture's inspector1 assignment). RLS is enforcing this; the harness is reading real server truth.

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
