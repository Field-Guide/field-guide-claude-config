# Blast Radius — Sync System Hardening And Harness

Files and symbols that will be created, modified, or preserved by each phase. Keyed to the seven-phase sequencing in Scope.

## Preserved (invariant) across every phase

These must not regress. Lint rules + CI validators enforce most of them.

- `SyncCoordinator` remains the single sync entrypoint. (`lib/features/sync/application/sync_coordinator.dart`)
- `SyncEngine` remains the mode-routing/mutex owner. (`lib/features/sync/engine/sync_engine.dart`)
- `SyncErrorClassifier` remains the sole sync error classifier. (`lib/features/sync/engine/sync_error_classifier.dart`)
- `SyncStatus` remains the transport-state source of truth. (`lib/features/sync/domain/sync_status.dart`)
- `SyncRegistry` + adapter-registration order remain load-bearing. (`lib/features/sync/engine/sync_registry.dart`, `scripts/validate_sync_adapter_registry.py`)
- `change_log` is trigger-owned; `sync_control.pulling` suppression bracket remains the only way to bypass triggers.
- `SyncHintRemoteEmitter` owns `emit_sync_hint` RPC calls; `RealtimeHintHandler` owns subscription lifecycle.
- RLS stays company-scoped via `get_my_company_id()`. `42501` stays non-retryable.
- Driver contracts: `screen_registry`, `screen_contract_registry`, `flow_registry`, `/diagnostics/screen_contract` HTTP route.
- Custom lint enforcement stays green: `push_handler_requires_sync_hint_emitter`, `no_sync_hint_rpc_outside_approved_owners`, `no_sync_hint_broadcast_subscription_outside_realtime_handler`, `no_client_sync_hint_broadcast_http`, `max_ui_callable_length`, `max_ui_file_length`, `screen_registry_contract_sync`.
- `flutter analyze`, `dart run custom_lint`, `scripts/audit_ui_file_sizes.ps1`, `scripts/validate_sync_adapter_registry.py` stay clean.

---

## Phase 1 — Local Docker Supabase + seeded fixture

**Goal:** boot local Supabase from current migrations with a seeded ~10–20 user multi-project fixture.

### Created
- `supabase/seed.sql` is currently empty. Replace with deterministic seed inserts for:
  - 1 company
  - ~10–20 `auth.users` rows (requires `supabase functions deploy` or SQL insert path using service role)
  - matching `user_profiles` with role distribution: ≥1 admin, ≥2 engineer, ≥1 office_technician, ≥5 inspector
  - ≥5 `projects` in the company
  - `project_assignments` matrix — at least one project every inspector IS on, at least one project every inspector is NOT on (for leakage test)
  - Seed entries (`daily_entries`), `bid_items`, `personnel_types`, `equipment`, `contractors`, `locations`, `photos` under a subset of projects to exercise FK chain.
- `tools/supabase_local_reset.ps1` — PowerShell wrapper to `supabase db reset` (to sidestep `supabase` CLI defaulting to Git Bash-incompatible paths).
- `tools/supabase_local_start.ps1` — wrapper around `supabase start`.

### Modified
- `supabase/config.toml` — no change expected unless the harness needs non-default ports. Flag if port collision surfaces during local boot.
- `.env.secret` keys (local only, outside repo) for the local Supabase `SUPABASE_DATABASE_URL` if different from default.

### Preserved
- All 71 existing migrations — seeded fixture must be migration-compatible.

### Exit criteria
- `pwsh -File tools/supabase_local_reset.ps1` boots Supabase, applies all migrations, and seeds the fixture without error.
- A manual `psql` check confirms role distribution, assignment matrix, and FK chain integrity.

---

## Phase 2 — Harness driver skeleton

**Goal:** authenticate as any of four roles, drive the real Flutter client, and assert against real RLS responses.

### Created
- `integration_test/sync/harness/` (new subtree):
  - `harness_auth.dart` — sign-in helpers per role, uses local-Docker Supabase, never prod.
  - `harness_driver_client.dart` — thin wrapper around the existing driver HTTP endpoints.
  - `harness_assertions.dart` — cross-role visibility invariant helpers (e.g., `assertNoCrossRoleLeakage(inspectorClient)`).
  - `harness_fixture_cursor.dart` — walks the seeded fixture to resolve "what projects can inspector X see".
- `test/harness/` (new subtree, unit-test-fast variant for driver-less validation):
  - `harness_auth_helpers_test.dart`
  - `harness_assertions_test.dart`

### Modified
- `lib/core/driver/driver_data_sync_handler.dart` — **read-only consumer of existing routes**. No route additions unless the spec's correctness matrix needs inspection keys that aren't yet published by `/diagnostics/screen_contract` / `/diagnostics/sync_transport` / `/diagnostics/sync_runtime`.
- `lib/core/driver/screen_contract_registry.dart` — if the harness needs a new state key (e.g., `inspector_visible_project_count`), add it here + the matching `TestingKeys` entry.
- `lib/shared/testing_keys/testing_keys.dart` — add keys for any new inspectable state the harness needs.

### Preserved
- The driver HTTP interface remains backward-compatible. No existing route is renamed.
- Existing `test/helpers/sync/sync_test_data.dart` factories are reused for any new client-side seed helpers.

### Exit criteria
- Harness can authenticate as admin/engineer/office_technician/inspector, drive a real Flutter app instance connected to local Docker Supabase, and make an RLS-real assertion (e.g., "inspector A's Supabase `select * from projects` returns only their assigned projects").

---

## Phase 3 — Full-surface correctness matrix

**Goal:** cover every sync-adjacent flow × every role with zero cross-role visibility violations.

### Created
- `integration_test/sync/matrix/` (new subtree) — one file per feature area:
  - `auth_matrix_test.dart`
  - `projects_matrix_test.dart` — includes the five enumerated defects as failing repros before their fixes.
  - `assignments_matrix_test.dart` — includes defect (c) new-user-to-old-project assignment failure.
  - `entries_matrix_test.dart`
  - `photos_matrix_test.dart`
  - `signatures_matrix_test.dart`
  - `forms_matrix_test.dart` (0582B, 1174R, 1126, IDR)
  - `pay_apps_matrix_test.dart`
  - `quantities_matrix_test.dart`
  - `equipment_matrix_test.dart`
  - `contractors_matrix_test.dart`
  - `personnel_matrix_test.dart`
  - `locations_matrix_test.dart`
  - `todos_matrix_test.dart`
  - `consent_matrix_test.dart`
  - `support_matrix_test.dart`
  - `documents_matrix_test.dart`
  - `exports_matrix_test.dart`
  - `flashing_repro_test.dart` — includes defects (a), (b), (e).
  - `download_on_click_test.dart` — defect (d).

### Modified
- None in production code until Phase 6. The matrix lands first; fixes land in Phase 6.

### Preserved
- Existing `test/features/sync/characterization/` tests coexist with the matrix. Delete only when the matrix proves the same contract more honestly (spec line: "characterization test is deleted only if the harness proves the same contract in a more honest way").

### Exit criteria
- Five enumerated defects have deterministic failing repros committed.
- Matrix runs green for every non-defect flow before Phase 4 begins.

---

## Phase 4 — Logging event-class audit + Sentry dual-feed

**Goal:** unify logging across the must-log event classes; add five-layer Sentry filter; wire Supabase Log Drains; ship in-app "Report a problem".

### Created
- `lib/core/logging/log_event_classes.dart` — the authoritative must-log class registry. Example sketch:
  ```dart
  class LogEventClasses {
    static const syncEngineEntry = 'sync.engine.entry';
    static const syncEngineExit = 'sync.engine.exit';
    static const syncEngineError = 'sync.engine.error';
    static const changeLogWrite = 'sync.change_log.write';
    static const changeLogRollback = 'sync.change_log.rollback';
    static const triggerFire = 'sync.trigger.fire';
    static const rlsDenial = 'sync.rls.denied';
    static const projectAssignmentMutation = 'projects.assignment.mutation';
    static const authStateTransition = 'auth.state.transition';
    static const pullScopeEnrollment = 'sync.scope.enroll';
    static const pullScopeTeardown = 'sync.scope.teardown';
    static const realtimeHintEmit = 'sync.hint.emit';
    static const realtimeHintReceive = 'sync.hint.receive';
    static const realtimeHintConsume = 'sync.hint.consume';
    static const downloadInitiate = 'projects.download.initiate';
    static const downloadComplete = 'projects.download.complete';
    static const downloadFail = 'projects.download.fail';
    static const conflictResolution = 'sync.conflict.resolution';
    static const fkRescue = 'sync.fk_rescue.action';
    static const edgeFunctionCall = 'sync.edge_function.call';
    static const retryPolicyDecision = 'sync.retry.decision';
    // List is allowed to grow during audit and implementation per Scope.
  }
  ```
- `lib/core/logging/logger_sentry_dedup_middleware.dart` — 60-second fingerprint buffer, rate limit 50 events/user/day, breadcrumb budget 30/event.
- `lib/core/logging/logger_sampling_filter.dart` — 5–10% sampling for high-volume non-error classes.
- `scripts/audit_logging_coverage.ps1` — walks sync, auth, project-selection code, fails CI if any method in the must-log set has no log seam.
- `scripts/audit_logging_coverage.py` (if PowerShell proves awkward in CI; PowerShell is canonical per spec, Python mirror optional).
- `supabase/functions/_shared/log_drain_sink.ts` (if Log Drain uses an Edge Function sink; alternatively Logflare/Datadog per deferred decision).

### Modified
- `lib/core/logging/logger.dart` — routes error-level calls through the dedup middleware before `LoggerSentryTransport.report`.
- `lib/core/logging/logger_sentry_transport.dart` — consume dedup middleware, honor rate limit, enforce breadcrumb budget.
- `lib/core/config/sentry_runtime.dart` — add feature flag for each of the five filter layers so the dev-mode override can disable them individually.
- `lib/main.dart` — wire dedup middleware + log-level filter into `SentryFlutter.init`.
- `lib/features/sync/engine/**` — any must-log event class without a current seam gets a single-line `Logger.sync(LogEventClasses.xxx, data: {...})` call. Audit script enumerates gaps.
- `lib/features/auth/presentation/providers/auth_provider.dart` — ensure every `AuthChangeEvent` (sign-in, sign-out, token refresh, session expire, role change, `passwordRecovery`) hits `Logger.auth(LogEventClasses.authStateTransition, ...)`.
- `lib/features/projects/presentation/providers/project_provider_auth_controller.dart` — log `onAuthChanged` with the before/after company + user + role tuple.
- `.github/workflows/quality-gate.yml` — add a `Logging event-class audit` step in the `architecture-validation` job that runs the audit script.

### Preserved
- Existing PII filter (`beforeSendSentry`, `beforeSendTransaction`) untouched. New filters layer beneath, not above.
- Consent gate remains the top-level kill switch. All five layers are no-ops when consent not granted.

### Exit criteria
- Audit script reports zero must-log gaps.
- Sentry ingestion stays under 5,000 errors/month on local Docker + nightly soak workload.
- Log Drain forwarding `postgres_logs`, `auth_logs`, `edge_logs` verified end-to-end (Supabase project console shows drain healthy; Sentry receives server-side events).

---

## Phase 5 — Property-based concurrency + soak

**Goal:** prove invariants hold under generated concurrent scenarios and sustained load.

### Created
- `pubspec.yaml` — add `glados` under `dev_dependencies`.
- `integration_test/sync/concurrency/` (new subtree):
  - `glados_invariants_test.dart` — property-based tests for LWW, cursor advancement, assignment-scope enrollment/teardown, tombstone propagation.
  - `table_driven_fallback_test.dart` — scenarios `glados` cannot express cleanly.
- `integration_test/sync/soak/` (new subtree):
  - `soak_driver.dart` — weighted action mix (30% reads, 30% entry mutations, 15% photo uploads, 20% deletes/restores, 5% role/assignment changes). 20 virtual users.
  - `soak_ci_10min_test.dart` — CI pre-merge gate.
  - `soak_nightly_15min_test.dart` — nightly auto-run.
  - `soak_metrics_collector.dart` — collects pushed/pulled/errors/rlsDenials/duration from `/diagnostics/sync_transport`.
- `scripts/soak_local.ps1` — local developer utility (not a gate).

### Modified
- `.github/workflows/quality-gate.yml` — add `Soak test (10-min)` step in the test job (gated on sync-touching PRs — see finding #2 pending).
- New workflow `.github/workflows/nightly-soak.yml` — scheduled 15-min soak, auto-files GitHub issues after three-night stability period.

### Preserved
- Existing 60+ sync unit tests + 15 characterization tests. No coexistence problems expected.

### Exit criteria
- PBT passes on local harness before being added to CI.
- 10-min CI soak runs green three consecutive runs before declared gate.
- Nightly soak runs green three consecutive nights before allowed to auto-file GitHub issues.

---

## Phase 6 — Sync engine rewrite (targeted; escape clause for architectural)

**Goal:** hit the 2-second full-sync ceiling; fix the five enumerated defects.

### Modified (targeted hotspot rewrite — likely)
- `lib/features/sync/engine/pull_handler.dart` — parallelize table pulls where FK safety allows.
- `lib/features/sync/engine/change_tracker.dart` — cursor advancement optimization.
- `lib/features/sync/engine/pull_scope_state.dart` — pull-scope enrollment efficiency.
- `lib/features/sync/application/realtime_hint_handler.dart` + `realtime_hint_transport_controller.dart` — fan-out throughput.
- `lib/features/sync/engine/enrollment_handler.dart` — new-user-to-old-project assignment path (defect c).
- `lib/features/sync/engine/fk_rescue_handler.dart`, `pull_fk_violation_resolver.dart` — integrity + propagation.

### Modified (flashing-fix)
- `lib/features/projects/presentation/providers/project_provider_auth_controller.dart` — make `_loadAssignments` + `_loadProjectsByCompany` complete as a single atomic unit before `_setInitializing(false)`. No skeleton-then-filter pattern per Scope.
- `lib/features/projects/presentation/providers/project_provider_auth_init.dart` — apply the assignment filter to the initial state before first notify.
- `lib/features/projects/presentation/screens/project_list_screen.dart` — ensure first render sees the filtered list only.
- `lib/features/projects/presentation/providers/project_provider_filters.dart` — defense-in-depth client filter per concurrent-mutation source of truth.

### Modified (download-on-click — defect d)
- `lib/features/projects/presentation/providers/project_download_controller.dart` (or equivalent — search for the current click handler; path to confirm during plan-writing).

### Possibly modified (if escape clause invoked)
- Contract-level changes to `SyncCoordinator` or `SyncEngine` public surface. Preserve adapter registry + lint rules + validator script.

### Preserved
- `SyncRegistry` order, `SyncErrorClassifier` ownership, `SyncStatus` authority, `change_log` trigger ownership.

### Exit criteria
- 2-second full-sync on seeded fixture (cold-start, empty SQLite, fresh auth, all tables).
- Five defects' failing repros from Phase 3 now pass.
- No new lint violations; no custom-lint-baseline growth.

---

## Phase 7 — Staging Supabase + CI gate + GitHub auto-issue noise policy

**Goal:** make harness green the mergeable gate and make Sentry → GitHub the triage gate.

### Created
- External: dedicated staging Supabase project on Pro plan. Secrets land in GitHub Actions secrets + Codemagic env-var groups.
- `.github/workflows/staging-schema-gate.yml` — hashes local + staging + prod schemas, fails if drift.
- `scripts/hash_schema.py` (if staging gate needs a hashing helper).
- `scripts/github_auto_issue_policy.py` — shared noise policy for any auto-filer (lint, Sentry, nightly soak). Fingerprint grouping, rate limit 1/fingerprint/24h, ≥2-user or ≥5/15-min threshold, 7-day auto-close, severity routing.
- Sentry → GitHub webhook (external).

### Modified
- `.github/workflows/quality-gate.yml`:
  - Extend the existing lint auto-issue step to delegate to `scripts/github_auto_issue_policy.py` so lint and Sentry and nightly-soak share the same policy.
  - Add the harness + soak gate on sync-touching PRs.
- `.github/workflows/nightly-soak.yml` — wire through the same policy for auto-issue creation.

### Preserved
- Existing lint-auto-issue dedup behavior remains the baseline shape. The new policy generalizes it.
- Existing CI jobs stay green.

### Exit criteria
- Every sync-touching PR runs harness matrix + PBT + 10-min soak against staging before merge.
- All five ship-bar conditions hold simultaneously: matrix green, five defects fixed, soak green, 2s met, logging/Sentry/GitHub pipeline live.
- Pre-alpha user release cut from this commit.

---

## Cleanup targets (post-MVP, not this phase)

- Characterization tests under `test/features/sync/characterization/` that the harness now proves more honestly. Delete case-by-case with the commit message citing the harness test that replaces them.
- Any repair-ish code under `lib/features/sync/application/repairs/*` that the harness proves is no longer load-bearing. Do not delete pre-ship.
- Any ad-hoc sync inspection endpoints in `driver_diagnostics_handler.dart` that the screen-contract path now covers.
