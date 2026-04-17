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

None in production code. Phase 3 is repro-only; fixes land in Phase 6.

### Files Preserved (Must Not Regress)

- `test/features/sync/characterization/` — all 15 characterization tests (pull cursor, pull conflict, pull dirty scope, pull scope, pull tombstone, pull trigger suppression, pull upsert, push company_id, push delete, push LWW, push skip, push upsert, realtime hint, retry policy, error classification, sync modes, lifecycle trigger, diagnostics, `SyncStatus` contract). These coexist with the matrix; deletion is case-by-case only when a matrix test proves the same contract more honestly, with the commit message citing the replacement test.
- `lib/core/driver/driver_diagnostics_handler.dart` — routes `/diagnostics/screen_contract`, `/diagnostics/sync_transport`, `/diagnostics/sync_runtime` are read-only consumers for the matrix; no route renames, no new routes in this phase.
- `lib/core/driver/screen_registry.dart`, `lib/core/driver/screen_contract_registry.dart`, `lib/core/driver/flow_registry.dart` — the driver contract surface stays backward-compatible; the `screen_registry_contract_sync` lint stays green.
- `SyncCoordinator`, `SyncEngine`, `SyncErrorClassifier`, `SyncStatus`, `SyncRegistry` adapter order, `change_log` trigger ownership, `sync_control.pulling` suppression bracket, `42501` non-retryable classification — all stay untouched.
- `test/helpers/sync/sync_test_data.dart` — `SyncTestData` map factories and `seedFkGraph` stay intact. The matrix reuses these factories; do not fork them. If a matrix test needs a new shape, extend `SyncTestData` with the new factory method in the same PR as the test that calls it.
- `lib/shared/testing_keys/testing_keys.dart` — `TestingKeys` stays the only source of key values. Never hardcode `Key('...')` in a matrix test.

### Step-by-step Implementation

1. **Matrix harness bootstrap helper.** In `integration_test/sync/matrix/`, add a private `_matrix_test_bootstrap.dart` (library-private conventions) that wraps the Phase 2 harness entrypoints into a single `setUpAll` / `tearDownAll` pair: `harnessAuth.signIn(role:, userId:)`, `harnessDriverClient.connect()`, `harnessFixtureCursor.load()`. Every matrix file imports this bootstrap so per-file boilerplate stays one line. Do not introduce a new driver route; this is purely a test-side helper.

2. **Per-role parameterization.** Each matrix file defines a top-level `const List<UserRole> _roles = [UserRole.admin, UserRole.engineer, UserRole.officeTechnician, UserRole.inspector];` and iterates every scenario across all four via `group(role.name, () { ... })`. For each role: sign in as a seeded user of that role from the Phase 1 fixture (the fixture guarantees at least 1 admin, at least 2 engineers, at least 1 office_technician, at least 5 inspectors per company), drive the feature flow, assert RLS-real response set.

3. **Cross-role leakage assertion (every matrix file).** Every scenario that renders a sync-backed list must call `harnessAssertions.assertNoCrossRoleLeakage(...)` against the active screen's state keys resolved via `GET /diagnostics/screen_contract`. For inspector-role scenarios, the expected id set is `SyncedScopeStore.getActiveAssignmentProjectIds` intersected with the fixture's enumerated assignments. For admin/engineer/office_technician scenarios, the expected id set is the full company-scoped list for their role. Any id outside the expected set is a leakage failure.

4. **`auth_matrix_test.dart`.** For each role: sign in, assert profile load, assert role getters on `AuthProvider` (`isAdmin`, `isEngineer`, `isOfficeTechnician`, `isInspector`) match the fixture. Sign out, assert `_currentUser` null and the realtime hint channel has been deactivated (inspect via `/diagnostics/sync_transport` transportHealth). Exercise token refresh (fixture-driven expiry) and `AuthChangeEvent.passwordRecovery`. All four `AuthChangeEvent` branches must appear at least once across the file so Phase 4's `LogEventClasses.authStateTransition` audit has coverage in the matrix fixture traffic as well.

5. **`projects_matrix_test.dart`.** Per role: sign in, load `ProjectListScreen`, assert `_projects` / `_assignedProjectIds` / `_mergedProjects` are consistent with the fixture. Assert inspector role sees only assigned projects; admin/engineer/office_technician see company-scoped list. Exercise project create for roles with `canCreateProject = canManageProjects`. Exercise soft-delete and restore.

6. **`assignments_matrix_test.dart` (includes defect c).** Per role: drive the assignment wizard via the driver, call `ProjectAssignmentProvider.buildMutationPlan()` shape through the diagnostics payload, then commit via the driver. Defect (c) failing repro: seed a fixture user `new-user-c` whose `auth.users` row is created *after* an existing project `old-project-c`, attempt to assign `new-user-c` to `old-project-c` via the assignment wizard flow. Current bug causes the assignment propagation to fail; test asserts success shape (id set includes `old-project-c` for `new-user-c`) and therefore fails pre-fix. Mark the test with a tag `@defect-c` so CI can opt in/out.

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

13. **Frame-capture plumbing.** `harnessDriverClient.captureFrames(duration:)` (already added in Phase 2) must return a list of `{timestamp, activeRoute, visibleRootKeys, stateKeyValues}` tuples. The matrix uses `stateKeyValues['project_list_state']` etc. Every state key referenced from a matrix test must already exist in `screen_contract_registry.dart` `stateKeys` and in `TestingKeys`. If a needed state key is missing, add it to both in a preparatory commit before the matrix test lands — same-PR rule from the driver-route pattern.

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
- `SyncErrorClassifier._classifyPostgrestError` at `lib/features/sync/engine/sync_error_classifier.dart:189` is the detection site for PostgreSQL `42501` (RLS denial). `42501` stays non-retryable — this phase adds a log call, not a classification change.
- `AuthProvider._authSubscription` listener at `lib/features/auth/presentation/providers/auth_provider.dart:101` is the auth state-change seam.
- `ProjectProviderAuthController.onAuthChanged` and `initWithAuth` are the project/auth-change seams.

### Files Created

- `lib/core/logging/log_event_classes.dart` — authoritative must-log class registry. Declares the locked event-class constants listed in this plan and is the file the audit script parses. The list is allowed to grow during audit/implementation per Scope.
- `lib/core/logging/logger_sentry_dedup_middleware.dart` — class `LoggerSentryDedupMiddleware` with `bool accept({required String fingerprint, required String userId, required SentryLevel level})`. 60-second fingerprint window; rate limit 50 events/user/day; breadcrumb budget 30/event.
- `lib/core/logging/logger_sampling_filter.dart` — class `LoggerSamplingFilter` with `bool accept({required String eventClass, required SentryLevel level})`. Drops 90–95 percent of non-error high-volume event classes (5–10 percent sampling rate); never drops error-level events.
- `scripts/audit_logging_coverage.ps1` — PowerShell canonical per CLAUDE.md. Walks `lib/features/sync/**`, `lib/features/auth/**`, `lib/features/projects/**`; for every constant in `LogEventClasses` that is required by the must-log set, asserts at least one `Logger.<category>(LogEventClasses.<name>, ...)` call exists. Exits 1 on gap; prints dashed error list per the Python CI validator shape; writes summary to `$GITHUB_STEP_SUMMARY` when run in CI.
- `scripts/audit_logging_coverage.py` — optional Python mirror; added ONLY if the PowerShell path proves awkward on CI ubuntu runners. PowerShell is canonical.
- `supabase/functions/_shared/log_drain_sink.ts` — sink handler for Supabase Log Drains forwarding `postgres_logs`, `auth_logs`, `edge_logs` into Sentry. Sink format (Logflare, Datadog, or custom HTTP) is a Phase 4 decision — see Step 13.

### Files Modified

- `lib/core/logging/logger.dart` — route error-level calls through the new middleware pipeline before invoking `LoggerSentryTransport.report`. Preserve: category method surface, part-file split (`logger_file_transport.dart`, `logger_http_transport.dart`, `logger_runtime_hooks.dart`), session directory, per-category rotated log files, flat `app_session.log`, 14-day retention, 50 MB cap, `_retentionDays`, `_maxLogSizeBytes`, `Logger.zoneSpec()`, `Logger.sessionDirectory`, consent-gated routing.
- `lib/core/logging/logger_sentry_transport.dart` — consume dedup middleware; honor rate limit; enforce breadcrumb budget. Preserve: `withScope` tag `'category'`, `logger_message` context, `extra` context shape, consent gate via `isSentryReportingEnabled`, behavior parity between `captureException` (non-null `error`) and `captureMessage` (null `error`).
- `lib/core/config/sentry_runtime.dart` — add per-layer feature flags (`isLoggerLogLevelFilterEnabled`, `isLoggerSamplingFilterEnabled`, `isLoggerDedupMiddlewareEnabled`, `isLoggerRateLimitEnabled`, `isLoggerBreadcrumbBudgetEnabled`) for dev override; each flag defaults to the production value and can be flipped via `String.fromEnvironment` dart-defines. Preserve: `sentryDsn`, `isSentryConfigured`, `isSentryReportingEnabled`, `isSentryFeedbackAvailable`.
- `lib/main.dart` — wire dedup middleware + log-level filter into `SentryFlutter.init` via `options.beforeBreadcrumb` (breadcrumb budget layer) and via the new middleware hook on `LoggerSentryTransport`. Preserve exactly: `options.tracesSampleRate = 0.1`, `options.attachScreenshot = false`, `options.attachViewHierarchy = false`, `options.replay.sessionSampleRate = 1.0`, `options.replay.onErrorSampleRate = 1.0`, `options.privacy.maskAllText = true`, `options.privacy.maskAllImages = true`, `options.beforeSend = beforeSendSentry`, `options.beforeSendTransaction = beforeSendTransaction`, `runApp(SentryWidget(...))`, `runZonedGuarded` block, `Logger.zoneSpec()` wiring.
- `lib/features/sync/engine/sync_error_classifier.dart` — at the `42501` detection site inside `_classifyPostgrestError` (line ~189), add `Logger.sync(LogEventClasses.rlsDenial, data: {...})` capturing `{'tableName', 'recordId', 'retryCount', 'context', 'postgrestCode': '42501'}`. Preserve: the existing non-retryable classification for `42501`, the existing user-safe message via `_sanitizeForUi`, the `classify` entrypoint signature at line 126, and the static helper surface (`isRemoteSchemaCompatibilityError`, `isMissingRemoteTableError`, `remoteSchemaMissingTableMessage`, `isTransientResult`).
- `lib/features/sync/engine/**` — for each must-log event class without a current seam, add a single-line `Logger.sync(LogEventClasses.<name>, data: {...})` call. Anchors from dependency-graph heavy-caller list: `sync_lifecycle_manager.dart` (currently 13 Logger calls), `background_sync_handler.dart` (10), `fcm_handler.dart` (10), `dirty_scope_tracker.dart` (6), `sync_coordinator.dart` (6), `sync_enrollment_service.dart` (5), `sync_background_retry_scheduler.dart` (5), `connectivity_probe.dart` (4). Audit script drives the gap list. Preserve: `SyncCoordinator` as the sole sync entrypoint, `SyncEngine` mode router, `SyncRegistry` adapter order, `change_log` trigger ownership, `sync_control.pulling` bracket as the only suppression path.
- `lib/features/auth/presentation/providers/auth_provider.dart` — inside the `_authSubscription` listener at line ~101, every `AuthChangeEvent` branch (sign-in including the first-time-profile-load branch, sign-out, token refresh, session expire, role change, `passwordRecovery`) must log `LogEventClasses.authStateTransition` with `data: {'event': state.event.name, 'userId': <scrubbed>, 'companyId': <if known>, 'role': <if known>}`. Preserve: `notifyListeners()` call sites, recovery handling, capability getters (`isAdmin`, `isEngineer`, `isOfficeTechnician`, `isInspector`, `canManageProjects`, `canEditFieldData`, `canManageProjectFieldData`, `canReviewInspectorWork`), profile freshness windows (`_cachedProfileFieldWorkWindow`, `_sharedManagementFreshnessWindow`, `_profileRefreshAttemptInterval`).
- `lib/features/projects/presentation/providers/project_provider_auth_controller.dart` — in `onAuthChanged`, emit `Logger.auth(LogEventClasses.authStateTransition, data: {...})` with before/after `{companyId, userId, role}` tuple. Preserve: `initWithAuth` call shape; `_loadAssignments`, `_loadProjectsByCompany`, and `syncCoordinator.syncLocalAgencyProjects(mode: SyncMode.quick)` trigger chain (Phase 6 handles the ordering fix, not Phase 4).
- `lib/core/config/sentry_feedback_launcher.dart` — extend `SentryFeedbackLauncher` to capture the last 30 breadcrumbs (already enforced by the breadcrumb budget layer), tail of recent logs from `Logger.sessionDirectory`, scrubbed user id (no email), current project id selection, and device info via `device_info_plus` (existing dependency). Preserve: `isSentryFeedbackAvailable` gate; consent gate short-circuits the capture to a no-op when consent not granted.
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

7. **Emit RLS denial log at the classifier boundary.** Modify `lib/features/sync/engine/sync_error_classifier.dart`. Inside `_classifyPostgrestError` at the `42501` branch (line ~189), immediately before returning the classified error, add `Logger.sync(LogEventClasses.rlsDenial, data: {'tableName': tableName, 'recordId': recordId, 'retryCount': retryCount, 'context': context, 'postgrestCode': '42501'})`. The classification itself (non-retryable) does not change. The existing `_sanitizeForUi` path continues to produce the user-safe message. Do not re-throw; do not alter return shape. Do not move the log call outside the `42501` branch — every other PostgREST code retains its existing handling.

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
    - `changeLogWrite` / `changeLogRollback` — inside the push handler's transactional write seam; `triggerFire` is server-side only (trigger-authored in Postgres) and is covered by Log Drains (Step 13), not client logging.
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

13. **Name the Log Drain sink decision — do not defer.** Before merging Phase 4, the implementer must record in the commit message (or a dedicated ADR under `.claude/docs/`) the chosen sink among Logflare, Datadog, and custom HTTP endpoint, and the rationale. Create `supabase/functions/_shared/log_drain_sink.ts` implementing the chosen sink: accept the Supabase Log Drain webhook payload, forward `postgres_logs`, `auth_logs`, `edge_logs` into Sentry via the Sentry ingest API with a scoped tag `'source': 'supabase.log_drain'`. The sink honors the same consent gate at the edge — events forwarded from server-side only when staging/prod consent is in place. Verification end-to-end is gated on the Phase 7 staging project; Phase 4 ships the client-side and sink-side integration with verification in isolation against local Docker.

14. **Extend in-app "Report a problem".** Modify `lib/core/config/sentry_feedback_launcher.dart`. Extend `SentryFeedbackLauncher` with a capture path that:

    - Reads the last 30 breadcrumbs (already enforced by the breadcrumb budget middleware `trimBreadcrumbs` helper from Step 3).
    - Tails recent log lines from `Logger.sessionDirectory` (respecting 14-day retention / 50 MB cap).
    - Attaches scrubbed `userId` (strip email), current project id (via the active project provider selection), and device info via `device_info_plus` (existing `pubspec.yaml` dependency — no new dep).
    - Honors `isSentryFeedbackAvailable` and `sentryConsentGranted` as short-circuits.

    Modify `lib/features/settings/presentation/screens/help_support_screen.dart` `_openSentryFeedback()` (line ~200) to invoke the extended capture path. Preserve `TestingKeys` usage; no hardcoded keys.

15. **Wire the audit into CI.** Modify `.github/workflows/quality-gate.yml` `architecture-validation` job. Add a step named `Logging event-class audit` that invokes `pwsh -File scripts/audit_logging_coverage.ps1 2>&1 | tee /tmp/logging_audit.txt || EXIT_CODE=$?` then posts a summary table row to `$GITHUB_STEP_SUMMARY` following the shape from `patterns/python-ci-validator.md`. Non-zero exit fails the job. Preserve the rest of the workflow: the `analyze-and-test` job, the `security-scanning` job, and all existing architecture-validation steps.

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
