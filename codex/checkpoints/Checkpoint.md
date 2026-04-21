# Sync Soak Decomposition + State Machine Refactor — Checkpoint

**Branch:** `gocr-integration`
**Opened:** 2026-04-19
**Comprehensive spec (source of truth):** `.claude/codex/plans/2026-04-19-sync-soak-decomposition-state-machine-refactor-spec.md`
**Driver-decomposition spec (superseded working copy):** `.claude/codex/plans/2026-04-19-sync-soak-driver-decomposition-todo-spec.md`
**Predecessor (closed P0/P1):** `.claude/codex/plans/2026-04-18-sync-soak-decomposition-todo-spec.md`
**Primary hardening tracker:** `.codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`

> This file is the iteration log. Update it every time a slice lands, stalls, or uncovers new context. When "done" is claimed, re-open the comprehensive spec and walk the **Measurable End Goals** + **Endpoint Definition** sections as a verification gate. Anything unchecked there is not done.

---

## How to use this file

1. **Before starting a slice:** skim the matching P-lane section in the spec. Copy its bullet list here under "Current Slice" and tick items as they land.
2. **When claiming completion:** walk every **ED-n** / **ES-n** acceptance criterion in the spec's *Measurable End Goals* section. Record the verification command + its actual output (not a summary — real text). If anything is unverifiable, say so.
3. **When uncertain:** read *Guardrails*, *Out of shape (non-goals)*, *Risk Register*, and *Open Questions* in the spec. They exist precisely to answer "should I do X?"
4. **Never mark a task done** without re-reading the guardrails. The spec explicitly forbids:
   - Calling `POST /driver/sync` for acceptance paths.
   - `MOCK_AUTH` anywhere.
   - Test-only methods/lifecycle hooks on production classes.
   - Re-introducing `sync_status` columns/indexes.
   - Manual `change_log` inserts.
   - Weakening custom_lint rules or adding `// ignore:` to pass.
   - Bypassing `SyncCoordinator`-as-entrypoint in production.
   - Introducing a runtime statechart library (XState/fsm2).
   - Network/protocol changes; OTel; Appium/Maestro/Patrol; TLA+.

---

## Implementation order (from spec §Suggested Implementation Order)

Tick these as each slice's on-screen task flips to completed.

- [x] 1. **P0-1** Relocate `harness_seed_data.dart` + siblings to `integration_test/sync/harness/seed/`.
- [x] 2. **P0-2** Close `SyncStatus.undismissedConflictCount` gap; unblock dead-code sentinel.
- [x] 3. **P0-3** Extract `SoakRunState` + `SoakWorkerPool` + `SoakSampler`; reduce `SoakDriver.run`.
- [x] 4. **P0-4** Split `_handleActorContext` into `_buildAuthDiagnostics` + `_buildProjectDiagnostics`.
- [x] 5. **P1-1** Land `DeviceStateSnapshot` + 4 region builders + `GET /diagnostics/device_state`.
- [x] 6. **P1-2** Extract `SoakFixtureRepair` from the headless executor.
- [x] 7. **P1-3** Hoist `_HeadlessAppSyncActor` to its own part file.
- [x] 8. **P1-4** Strategy-map the two `SoakActionExecutor.execute` dispatchers.
- [x] 9. **P1-5** Route-table the `DriverDataSyncHandler.handle` dispatcher.
- [x] 10. **P1-6** `SoakActorProvisioner` interface + scale manifest.
- [x] 11. **P1-7** `DevicePosture` derivation + `Assert-EventuallyDevicePosture` + port `Flow.SyncDashboard.ps1`.
- [x] 12. **P2-1** `DriverServer` DI tidy-up (remove nullable back-compat).
- [x] 13. **P2-2** Split `driver_file_injection_handler.dart` by photo vs document.
- [x] 14. **P2-3** Review `screen_contract_registry.dart` — split or documented exception.
- [x] 15. **P2-4** Build typed key catalog generator + YAML + `no_raw_key_outside_generated` lint.
- [x] 16. **P2-5** Cut over 16 feature testing-keys modules (one PR per feature, documented order).
- [x] 17. **P2-6** Confirm `soak_driver.dart` facade shape after all P0/P1 slices.
- [x] 18. **P3-1** Orchestrator state machine + first cross-device invariant (project convergence).
- [x] 19. **P3-2** Fail-loud log engine + 5 seeded fatal rules + `loggingGaps` enforcement.
- [x] 20. **P3-3** Unified cross-device `timeline.json` + `timeline.html`.
- [x] 21. **P3-4** Three acceptance drills (failure injection, key rename, observability).
- [x] 22. **P3-5** Hardening docs (`state-harness.md`, `sync-patterns.md`) + GlobalKey audit.
- [x] 23. **P3-6** Open separate sync-engine test decomposition checklist.
- [x] 24. **Final** Walk every ED-1..ED-8 and ES-1..ES-14 as a verification gate.

---

## Current slice

**In flight:**
- Local implementation and deterministic harness verification are complete.
- **Closeout reconciliation:** later evidence in this checkpoint accepts the ES-2
  physical lane after the app-lock/root-builder and Android-surface fixes:
  `20260419-s21-s10-es2-after-android-surface-false-positive-fix`.
- Current slice is a fresh closeout pass against the current dirty tree:
  analyzer, custom lint, size gate, harness self-tests, focused driver/harness
  Flutter tests, and progress-log updates.

---

## Session log

### 2026-04-19 — Bootstrap
- Created on-screen task list (24 tasks) from the comprehensive spec §Suggested Implementation Order.
- Created this Checkpoint.md as the iteration scratchpad + verification gate.

### 2026-04-19 — Resumed live device hardening / ES-2 + four-role gate
- User explicitly authorized the real ES-2 gate, two-device testing, and the
  honest four-device role run covering admin, engineer, office technician, and
  inspector.
- Created a fresh on-screen checklist for this resumed slice:
  1. reconcile prior soak logs/checklists and current specs;
  2. refresh checkpoint notes;
  3. inventory connected devices/emulators, branch, and backend/auth
     prerequisites;
  4. run two-device ES-2 against real sessions/backend;
  5. run true four-device role soak;
  6. triage failures, patch hardening issues, and rerun targeted gates;
  7. update checkpoint/live evidence.
- Re-read:
  - `.claude/codex/checkpoints/2026-04-18-sync-soak-unified-implementation-log.md`;
  - `.claude/codex/checkpoints/2026-04-18-sync-soak-unified-live-task-list.md`;
  - `.claude/codex/checkpoints/Checkpoint.md`;
  - both 2026-04-19 decomposition/state-machine specs.
- Current handoff confirmed:
  - decomposition/state-machine local implementation is closed except **ES-2**;
  - latest completed four-role UI run remains rejected:
    `20260419-four-role-ui-endpoint-wiring-after-shell-key-blank-surface-fix`;
  - patches after that rejected run are local-only until the device apps are
    rebuilt/restarted: root theme moved above `MaterialApp.router`, logcat
    windows cleared before preflight/steps, and benign UIAutomator
    `AndroidRuntime` noise filtered.
- Current branch verified with `git branch --show-current`: `gocr-integration`.
- Dirty tree is broad and expected from the decomposition/state-machine work.
  Do not revert unrelated files. Continue working with the existing changes.
- Next device action: inventory ADB/flutter devices, forwards/reverses, driver
  readiness, actor context, sync status, Android surface, and required
  role-account secrets before any acceptance run.

### 2026-04-19 — First wave kicked off
- Launched **P0-1** and **P0-3** in parallel worktree agents; began **P0-4** in the main tree.
- P0-4 edit landed: `_handleActorContext` is now a 14-line coordinator delegating to three named helpers (`_buildAuthDiagnostics`, `_buildProjectDiagnostics`, `_sampleMergedProjects`). `dart analyze lib/core/driver/driver_diagnostics_handler.dart` reports `No issues found!`.
- P0-4 structural test for auth/project sub-object shape was **deferred**. The spec suggests a test in `test/core/driver/driver_diagnostics_routes_test.dart` or `tools/sync-soak/tests/`, but both require either (a) `@visibleForTesting` on the new private helpers or (b) HTTP-level plumbing with provider mocks. `rules/testing.md` forbids test-only methods on production classes. Revisit during the broader sync-inspection test pass (post-P1-1 when `DeviceStateSnapshot` integration tests arrive — that fixture-based test is the right home for the shape assertion).

### 2026-04-19 — P0-1 blocker discovered, scope expanded
- First P0-1 agent returned a blocker report: `screen_registry.dart`, `verification_flow_definitions.dart`, and `repair_sync_state_v2026_04_17_harness_seed_residue.dart` import `HarnessSeedData.*` as production code. A pure relocation to `integration_test/` breaks the build because Dart's `package:` imports can't cross from `lib/` into `integration_test/`.
- I verified the finding in the main tree with `grep harness_seed lib/` — confirmed.
- **Spec baseline error documented:** comprehensive spec line 182 ("Zero production callers") is wrong on `gocr-integration`. The driver-decomposition spec line 155 carries the same error. Future verification needs to re-grep rather than trust the spec baseline.
- **Scope-expansion decision (user-approved, Option A):** P0-1 now has two steps. (1) Extract the production-visible seed IDs (`defaultProjectId`, `defaultEntryId`, etc.) to a new `lib/core/driver/harness_seed_identifiers.dart` that stays in `lib/`, update the three production callers to import from it. (2) Relocate the heavy fixture classes (`HarnessSeedData`, `HarnessSeedDefaults`, `HarnessSeedPayAppData`) to `integration_test/sync/harness/seed/`; `driver_seed_handler.dart` stays in `lib/core/driver/` and imports from `integration_test/`. Also: `fg_lint_packages/field_guide_lints/lib/data_safety/rules/avoid_raw_database_delete.dart` hardcodes `'lib/core/driver/harness_seed_data.dart'` in an allowlist — update to the new path, do not widen.
- Relaunched P0-1 as a new worktree agent with the expanded brief + a pre-flight check (`git rev-parse HEAD`, `ls`) so a stale worktree can't cost us another round.

### Outstanding anomaly (not blocking)
- First P0-1 agent's worktree didn't see `driver_seed_handler.dart` even though it's committed (`23eab1e7`). Unable to reproduce; second P0-1 agent's pre-flight will confirm whether worktree creation is flaky. Park as a low-priority diagnostic; does not block P0-1.

### 2026-04-19 — P0 wave reconciled and closed
- Re-read both 2026-04-19 specs and reconciled the interrupted worktree state. No active background agents were available in this Codex session, so the landed code was verified in the main tree directly.
- **P0-1 closed with the expanded Option A shape:** heavy fixtures now live under `integration_test/sync/harness/seed/`; production-visible IDs now live in `lib/core/driver/harness_seed_identifiers.dart`; the old `lib/core/driver/harness_seed_defaults.dart` was removed. `lib/core/driver` no longer imports `harness_seed_data.dart`, `harness_seed_pay_app_data.dart`, `harness_seed_defaults.dart`, or `features/*/data/datasources/local`.
- **P0-2 closed:** `SyncStatus` now owns `undismissedConflictCount` in ctor/copyWith/equality/hash/toString plus `hasUndismissedConflicts`; `SyncProvider` publishes diagnostics refresh conflict counts into the status store.
- **P0-3 closed:** `SoakRunState`, `SoakSampler`, and `SoakWorkerPool` are wired as part files; result assembly moved to `buildSoakResult` so `SoakDriver.run` is 38 lines by CodeMunch.
- **P0-4 closed:** `_handleActorContext` remains split into `_buildAuthDiagnostics`, `_buildProjectDiagnostics`, and `_sampleMergedProjects`; route constants moved to `driver_diagnostics_routes.dart`; visual diagnostic payload helpers moved to `driver_visual_diagnostics_payloads.dart`; `driver_diagnostics_handler.dart` is now 476 LOC.
- Analyzer/test evidence:
  - `dart analyze lib integration_test test/harness test/core/driver` → `No issues found!`
  - `dart run custom_lint` → `No issues found!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test-sync-soak-harness.ps1` → `sync-soak harness self-tests passed (14 test files, all assertions green)`
  - `powershell -ExecutionPolicy Bypass -File tools/test-sync-soak-harness.ps1` fails on Windows PowerShell 5.1 because `System.IO.Path.GetRelativePath` is unavailable. Treat the harness command as PowerShell 7+ (`pwsh`) unless/until `ArtifactRetention.ps1` is backported.
  - `powershell -ExecutionPolicy Bypass -File scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` exited 0; it still reports pre-existing blocked/exception PowerShell files plus `headless_app_sync_action_executor.dart` at 619 LOC for later P1-2/P1-3.
  - `flutter test test/harness/soak_driver_test.dart test/harness/soak_ci_10min_test.dart test/harness/soak_nightly_15min_test.dart test/features/sync/characterization/sync_status_contract_test.dart test/features/sync/presentation/providers/sync_provider_test.dart` → `All tests passed!` with two local-harness tests skipped unless `RUN_LOCAL_HARNESS=true`.
  - `flutter test test/core/driver/driver_seed_handler_test.dart test/features/sync/application/sync_state_repair_runner_test.dart` → `All tests passed!`
- CodeMunch evidence after `index_folder(incremental=true)`:
  - `get_coupling_metrics(local/Field_Guide_App-37debbe5, lib/core/driver/harness_seed_data.dart)` → `File not found in index: lib/core/driver/harness_seed_data.dart`
  - `_handleActorContext` → cyclomatic 4, max_nesting 3, 18 lines.
  - `SoakDriver.run` → cyclomatic 3, max_nesting 1, 38 lines.

### 2026-04-19 — P1-1 device-state snapshot landed
- **P1-1 closed locally:** added `DeviceStateSnapshot`, UI/app/data/sync region builders, `GET /diagnostics/device_state`, `HarnessDriverClient.fetchDeviceState`, `tools/sync-soak/DeviceStateSnapshot.ps1`, and `Get-SoakDeviceStateSnapshot` schema guard.
- **Registry correction:** `DataRegionBuilder` now reads bounded sync row-count tables from `SyncRegistry.diagnosticRowCountTables` instead of carrying sync table literals in the driver layer. Driver-only counts remain `change_log` and `conflict_log`.
- **Bug fixed while testing:** `DataRegionBuilder._readLastLocalWriteAt` now reads `change_log.changed_at`; `created_at` is not a real `change_log` column.
- **Diagnostics budget kept:** `driver_diagnostics_handler.dart` is 457 LOC after extracting `DriverGocrTraceDiagnostics` and `DriverProviderLookup`.
- Analyzer/test evidence:
  - `flutter test test/core/driver/state/ui_region_builder_test.dart test/core/driver/state/app_region_builder_test.dart test/core/driver/state/data_region_builder_test.dart test/core/driver/state/sync_region_builder_test.dart test/core/driver/device_state_endpoint_test.dart test/core/driver/device_state_snapshot_test.dart test/core/driver/driver_diagnostics_routes_test.dart` → `All tests passed!`
  - `dart analyze lib/core/driver lib/features/sync/engine/sync_registry.dart lib/features/sync/domain/sync_status.dart integration_test/sync/harness/harness_driver_client.dart test/core/driver test/features/sync/characterization/sync_status_contract_test.dart` → `No issues found!`
  - `dart run custom_lint` → `No issues found!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test-sync-soak-harness.ps1` → `sync-soak harness self-tests passed (15 test files, all assertions green)`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` exited 0; still reports pre-existing blocked files including `integration_test/sync/soak/headless_app_sync_action_executor.dart` at 619 LOC for P1-2/P1-3.
- Caveat: no real two-device smoke was run in this local slice. The P-lane risk gate still requires S21/S10 smoke at the next device-sync touchpoint.

### 2026-04-19 — P1-2 fixture repair extracted
- **P1-2 closed:** added `integration_test/sync/soak/soak_fixture_repair.dart` as a `soak_driver.dart` part. It owns mutable seeded-photo repair, summary creation, and `fixture_repair.json` writing.
- The headless executor still owns the admin-actor precondition and now delegates repair execution via `repairMutableSeedState(adminActor.supabase, artifactRoot: root, authUserId: adminActor.userId)`.
- Added `test/harness/soak_fixture_repair_test.dart` for seeded-photo ID coverage, real-session summary shape, and existing artifact filename/JSON contract.
- Evidence:
  - `flutter test test/harness/soak_fixture_repair_test.dart test/harness/soak_driver_test.dart` → `All tests passed!`
  - `dart analyze integration_test test/harness` → `No issues found!`
  - `dart run custom_lint` → `No issues found!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test-sync-soak-harness.ps1` → `sync-soak harness self-tests passed (15 test files, all assertions green)`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` exited 0. `headless_app_sync_action_executor.dart` is now 566 LOC and `[review]` instead of the previous 619 LOC `[blocked]`; P1-3 should reduce it further.

### 2026-04-19 — P1-3 headless actor hoisted
- **P1-3 closed:** added `integration_test/sync/soak/headless_app_sync_actor.dart` as a `part of 'soak_driver.dart'` file with a file-level dartdoc. `_HeadlessAppSyncActor` remains underscore-private to the soak library.
- `headless_app_sync_action_executor.dart` now owns execution behavior only; the private actor value holder moved out verbatim.
- Evidence:
  - `flutter test test/harness/soak_fixture_repair_test.dart test/harness/soak_driver_test.dart test/harness/headless_app_sync_actor_test.dart` → `All tests passed!` (`headless_app_sync_actor_test.dart` skipped unless `RUN_HEADLESS_APP_SYNC=true`)
  - `dart analyze integration_test test/harness` → `No issues found!`
  - `dart run custom_lint` → `No issues found!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test-sync-soak-harness.ps1` → `sync-soak harness self-tests passed (15 test files, all assertions green)`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` exited 0. `headless_app_sync_action_executor.dart` is now 543 LOC `[review]`; `headless_app_sync_actor.dart` is 30 LOC `[ok]`.

### 2026-04-19 — P1-4 action dispatchers strategy-mapped
- **P1-4 closed:** `LocalSupabaseSoakActionExecutor.execute` and `HeadlessAppSyncActionExecutor.execute` now dispatch through constructor-populated `Map<SoakActionKind, Future<void> Function(SoakActionContext)>` tables. Missing future action kinds throw `StateError`.
- Existing action counting and failure mapping remain in `SoakWorkerPool`; `SoakActionContext` is passed unchanged to every strategy.
- Evidence:
  - `dart analyze integration_test test/harness` → `No issues found!`
  - `flutter test test/harness/soak_fixture_repair_test.dart test/harness/soak_driver_test.dart test/harness/headless_app_sync_actor_test.dart` → `All tests passed!` (`headless_app_sync_actor_test.dart` skipped unless `RUN_HEADLESS_APP_SYNC=true`)
  - `dart run custom_lint` → `No issues found!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test-sync-soak-harness.ps1` → `sync-soak harness self-tests passed (15 test files, all assertions green)`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` exited 0. `backend_rls_soak_action_executor.dart` is 436 LOC `[review]`; `headless_app_sync_action_executor.dart` is 590 LOC `[review]`.
- CodeMunch evidence after re-indexing the two executor files:
  - `LocalSupabaseSoakActionExecutor.execute` → cyclomatic 3, max_nesting 2, 7 lines.
  - Backend per-action methods: `_executeRead` CC 1, `_executeDailyEntryEdit` CC 4, `_executeQuantityRead` CC 1, `_executePhotoMetadataEdit` CC 4, `_executeFormResponseEdit` CC 4, `_executeDeleteRestoreRemoval` CC 7, `_executeProjectAssignment` CC 1, `_executeAuthSessionRefresh` CC 1, `_executeRoleAssignment` CC 4.
  - `HeadlessAppSyncActionExecutor.execute` → cyclomatic 3, max_nesting 2, 7 lines.

### 2026-04-19 — P1-5 driver data-sync route table landed
- **P1-5 closed:** `DriverDataSyncHandler.handle` now dispatches through a route table assembled from query, mutation, and maintenance route part files.
- Added `test/core/driver/driver_data_sync_handler_route_table_test.dart`, asserting every accepted driver data-sync method/path is registered and still accepted by `DriverDataSyncRoutes.matches`.
- Evidence:
  - `dart analyze lib/core/driver test/core/driver` → `No issues found!`
  - `flutter test test/core/driver/driver_data_sync_handler_route_table_test.dart test/core/driver/driver_data_sync_routes_test.dart test/core/driver/driver_data_sync_handler_test.dart test/core/driver/driver_server_sync_status_test.dart` → `All tests passed!`
  - `dart run custom_lint` → `No issues found!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test-sync-soak-harness.ps1` → `sync-soak harness self-tests passed (15 test files, all assertions green)`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` exited 0.
  - CodeMunch after `index_folder(incremental=true)`: `DriverDataSyncHandler.handle` → cyclomatic 3, max_nesting 2, 10 lines.

### 2026-04-19 — P1-6 SoakActorProvisioner landed
- **P1-6 closed:** added `integration_test/sync/soak/soak_actor_provisioner.dart` with `SoakActorProvisioner`, scale-manifest metadata, and `writeSoakScaleManifest`.
- `LocalSupabaseSoakActionExecutor`, `DriverSoakActionExecutor`, and `HeadlessAppSyncActionExecutor` now implement `SoakActorProvisioner`. `SoakDriver.run` calls `provision(...)` when available and writes `build/soak/scale_manifest_<actorKind>.json`.
- Added `test/harness/soak_actor_provisioner_test.dart` for the three evidence-layer implementations, device-sync scale metadata, and manifest artifact shape.
- Kept the spec guardrail: no external 15-20 actor readiness claim was made; real headless nightly remains the gate.
- Evidence:
  - `dart analyze integration_test test/harness` → `No issues found!`
  - `flutter test test/harness/soak_actor_provisioner_test.dart test/harness/soak_driver_test.dart test/harness/soak_fixture_repair_test.dart` → `All tests passed!`
  - `rg -n "implements SoakActorProvisioner" .\integration_test\sync\soak` → three matches: `driver_soak_action_executor.dart`, `headless_app_sync_action_executor.dart`, `backend_rls_soak_action_executor.dart`.
  - `dart run custom_lint` → `No issues found!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test-sync-soak-harness.ps1` → `sync-soak harness self-tests passed (15 test files, all assertions green)`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` exited 0. `headless_app_sync_action_executor.dart` is 533 LOC `[review]`; actor construction moved to `headless_app_sync_actor.dart` (137 LOC `[ok]`).

### 2026-04-19 — P1-7 closed
- Added `lib/core/driver/device_state_machine.dart` with `DevicePosture` and pure `derive(DeviceStateSnapshot)`.
- Added `test/core/driver/device_state_machine_test.dart`; table-driven cases cover all 8 enum values (**ES-5**).
- Added `tools/sync-soak/DevicePosture.ps1` with `Get-SoakDevicePosture`, `Assert-SoakDevicePosture`, and `Assert-EventuallyDevicePosture -AtMostMs -PollIntervalMs -DuringMs`.
- Added `tools/sync-soak/tests/DevicePosture.Tests.ps1`; deliberately broken posture path fails inside `AtMostMs` through `Invoke-SoakSentinelBlock` with one `state_sentinel_failed` result (**ES-9**).
- Ported stable sync-dashboard route/key sentinels to `Assert-EventuallyDevicePosture` in `Flow.SyncDashboard.ps1`. The immediate post-tap sentinel intentionally remains route/key based because valid posture there is transient (`syncing` or already idle) and the later measurement loop owns sync observation evidence.
- Tightened `FailureClassification.ps1` precedence so explicit state-sentinel failures win over broad widget-wait matching (`awaitingSignIn` previously matched `wait.*failed`).
- Evidence:
  - `flutter test .\test\core\driver\device_state_machine_test.dart` → `All tests passed!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\test-sync-soak-harness.ps1` → `sync-soak harness self-tests passed (16 test files, all assertions green)`
  - `dart analyze lib integration_test test/harness test/core/driver` → `No issues found!`
  - `dart run custom_lint` → `No issues found!`

### 2026-04-19 — P2-1 closed
- Made `DriverServer`'s sync/database/project lifecycle/Supabase/document seams required and non-nullable.
- Updated `DriverSetup.configure(...)` to fail early if driver mode lacks an initialized Supabase client instead of passing a nullable seam into `DriverServer`.
- Removed the stale nullable-back-compat comments and updated `driver_server_sync_status_test.dart` so it no longer asserts the old null-coordinator fallback.
- Evidence:
  - `rg -n "nullable for backward compat|NEW — nullable|SyncCoordinator\?|SyncQueryService\?|SyncPoisonStateService\?|SyncRecoveryService\?|SupabaseClient\?|DatabaseService\?|ProjectLifecycleService\?|DocumentRepository\?" .\lib\core\driver\driver_server.dart` → no matches.
  - `(Get-Content .\lib\core\driver\driver_server.dart | Measure-Object -Line).Lines` → `189`
  - `flutter test .\test\core\driver\driver_server_sync_status_test.dart` → `All tests passed!`
  - `flutter test .\test\core\driver` → `All tests passed!`
  - `dart analyze .\lib\core\driver\driver_server.dart .\lib\core\driver\driver_setup.dart .\test\core\driver\driver_server_sync_status_test.dart` → `No issues found!`

### 2026-04-19 — P2-2 closed
- Replaced `driver_file_injection_handler.dart` with a 30-line compatibility dispatcher.
- Added `driver_photo_injection_handler.dart` for `/driver/inject-photo` and `/driver/inject-photo-direct`.
- Added `driver_document_injection_handler.dart` for `/driver/inject-file` and `/driver/inject-document-direct`.
- Added `driver_injection_shared.dart` for shared JSON/body helpers, filename validation, size limits, allowed extensions, and UUID pattern.
- Preserved the 32 MiB injected-file limit, 45 MiB base64 body limit, photo/document extension sets, and UUID regex; added tests for those contracts.
- Evidence:
  - `flutter test .\test\core\driver\driver_file_injection_test.dart` → `All tests passed!`
  - `dart analyze lib integration_test test/harness test/core/driver` → `No issues found!`
  - `flutter test .\test\core\driver` → `All tests passed!`
  - File sizes: `driver_file_injection_handler.dart` 30 LOC, `driver_photo_injection_handler.dart` 180 LOC, `driver_document_injection_handler.dart` 194 LOC, `driver_injection_shared.dart` 78 LOC.

### 2026-04-19 — P2-3 closed
- Read `screen_contract_registry.dart` and reviewed every registered contract. Current table has 53 screen contracts across auth/onboarding, project/dashboard/settings, entries/review, forms/MDOT, PDF/import, sync/conflict/trash, quantities/pay apps/contractors, toolbox/calculator/gallery/todos, admin/help/legal/analytics.
- Decision: keep the table centralized and document a size-budget exception instead of splitting. All entries are shape-isomorphic (`ScreenContract` with `id`, `rootKey`, `routes`, `seedArgs`, `actionKeys`, `stateKeys`), and the diagnostics layer consumes the whole map/root-key set for route matching and the upcoming typed-key catalog.
- Added a source-level size-budget exception above `screenContracts`; expiry `2026-09-30`, intentionally registry-shaped around the driver screen contract cluster.
- Evidence:
  - `(Get-Content .\lib\core\driver\screen_contract_registry.dart | Measure-Object -Line).Lines` → `709`
  - Contract count: `53`
  - `dart analyze .\lib\core\driver\screen_contract_registry.dart .\test\core\driver\registry_alignment_test.dart` → `No issues found!`
  - `flutter test .\test\core\driver\registry_alignment_test.dart .\test\core\driver\driver_route_contract_test.dart` → `All tests passed!`

### 2026-04-19 — P2 typed-key catalog and P2-6 closed
- **P2-4/P2-5 closed locally:** added `tools/gen-keys/seed_keys_yaml.dart`, `tools/gen-keys/generate_keys.dart`, `tools/gen-keys/cutover_feature_modules.dart`, and `tools/gen-keys/verify-idempotent.ps1`.
- Seeded `tools/gen-keys/keys.yaml` mechanically from the existing `lib/shared/testing_keys/*.dart` source. The catalog currently has `929` entries after restoring the pre-existing `NavigationTestingKeys.bottomNavCalendar` compatibility alias.
- Generated:
  - `lib/shared/testing_keys/generated/keys.g.dart`
  - `tools/sync-soak/generated/Keys.ps1`
  - `tools/sync-soak/generated/keys.json`
- Cut over all 16 feature testing-key modules (`common`, `navigation`, `auth`, `sync`, `consent`, `projects`, `settings`, `documents`, `photos`, `contractors`, `locations`, `entries`, `quantities`, `pay_app`, `support`, `toolbox`) into generated-catalog re-export shims (**ES-7**).
- Cleaned the `TestingKeys` facade raw-key leftovers by delegating facade-only `Key(...)` constants/methods to `generated.GeneratedTestingKeys`. Left existing `ValueKey<String>` facade keys alone because the lint explicitly allows typed `ValueKey`.
- Added `NoRawKeyOutsideGenerated` at `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_key_outside_generated.dart`, registered it in `architecture_rules.dart`, and added positive/negative fixtures in `no_raw_key_outside_generated_test.dart` (**ES-8**).
- Adjusted `AppDialog._getConfirmButtonKey` fallback from raw `Key(...)` to `ValueKey<String>(...)`; this is framework identity, not a generated testing key.
- **P2-6 closed:** `integration_test/sync/soak/soak_driver.dart` remains a 71-line facade with the expected part layout. All external references found by `rg` import `soak_driver.dart`; no external importer targets a part file directly.
- Evidence:
  - `dart analyze lib/shared/testing_keys lib/core/design_system/surfaces/app_dialog.dart tools/gen-keys` → `No issues found!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\gen-keys\verify-idempotent.ps1` → `Typed key outputs are byte-identical.`
  - `dart test fg_lint_packages/field_guide_lints/test/architecture/no_raw_key_outside_generated_test.dart` → `All tests passed!`
  - `dart run custom_lint` → `No issues found!`
  - `(Get-Content integration_test/sync/soak/soak_driver.dart | Measure-Object -Line).Lines` → `71`
  - `rg -n "sync/soak/[^'\"]+\.dart" integration_test test lib -g "*.dart"` → no matches.

### 2026-04-19 — P3 local implementation closed
- **P3-1 closed:** added `tools/sync-soak/OrchestratorStateMachine.ps1` with transition-index allocation, orchestrator transition artifacts, invariant wrappers, and the first project-convergence invariant.
- **P3-2 closed:** added `tools/sync-soak/LogAssertions.ps1`, wired it into `StepRunner.ps1`, and made fatal log assertions fail the step with the rule classification. Fatal seeded rules cover duplicate GlobalKey, Flutter ErrorWidget, unhandled exception, RLS `42501`, stuck `sync_control.pulling`, and strict `loggingGaps`.
- **P3-3 closed:** added `tools/sync-soak/Timeline.ps1` and wired `Complete-SoakDeviceSummary` to emit `timeline.json` + `timeline.html` for every completed run summary. Actor state transitions, step JSON, evidence bundles, and orchestrator transitions now carry the `runId` / `actorId` / `transitionIndex` triple.
- **P3-4 closed:** added deterministic acceptance coverage in `tools/sync-soak/tests/AcceptanceDrills.Tests.ps1` plus a dedicated script at `tools/sync-soak/drills/Invoke-AcceptanceDrills.ps1`. The script writes failed transition artifacts, renders a timeline, and verifies three distinct root classifications: `state_sentinel_failed`, `sync_control_stuck`, `auth_rls_denial`.
- **P3-5 closed:** updated `.claude/rules/sync/sync-patterns.md` and added `.claude/docs/state-harness.md` documenting the canonical snapshot, sentinels, typed-key generation, log assertions, orchestrator invariant, timeline artifacts, and current GlobalKey audit.
- **P3-6 closed:** opened `.codex/plans/2026-04-19-sync-engine-test-decomposition-checklist.md` as a separate checklist for sync-engine test decomposition.
- **Driver hotspot follow-up:** `mcp__jcodemunch__get_hotspots` initially showed `_handleRemoteReconciliationSnapshotRoute` in the repo top 25. Split its parameter parsing and payload construction into private helpers; the top 25 now has no `lib/core/driver/**` symbols.
- Evidence:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\test-sync-soak-harness.ps1` → `sync-soak harness self-tests passed (20 test files, all assertions green)`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\sync-soak\drills\Invoke-AcceptanceDrills.ps1` → `sync-soak acceptance drills passed`; classifications: `state_sentinel_failed, sync_control_stuck, auth_rls_denial`; timeline written under `build/sync-soak-drills/.../timeline.html`.
  - `dart analyze lib integration_test test/harness test/core/driver` → `No issues found!`
  - `dart run custom_lint` → `No issues found!`
  - `flutter test .\test\core\driver` → `All tests passed!` (76 tests)
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\gen-keys\verify-idempotent.ps1` → `Typed key outputs are byte-identical.`
  - `dart test .\fg_lint_packages\field_guide_lints\test\architecture\no_raw_key_outside_generated_test.dart` → `All tests passed!`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked` exited 0. New/changed modules remain `[ok]`: `OrchestratorStateMachine.ps1` 164 LOC, `Timeline.ps1` 146 LOC, `LogAssertions.ps1` 145 LOC, `StepRunner.ps1` 199 LOC, `StateMachine.ps1` 151 LOC, `EvidenceBundle.ps1` 127 LOC.
  - `mcp__jcodemunch__get_hotspots` top 25 after incremental re-index: no `_handleActorContext` and no `lib/core/driver/**` symbols.
- Not run:
  - Real S21/S10 two-device soak is now reconciled through accepted run
    `20260419-s21-s10-es2-after-android-surface-false-positive-fix`, recorded
    later in this checkpoint with zero runtime/logging gaps and drained queues.

---

## Measurable End Goals — running scorecard

Each row is unchecked until verified with the spec-specified command. Do not mark a row done from inference.

### Structural decomposition

- [x] **ED-1** `harness_seed_data.dart` relocated; `mcp__jcodemunch__get_coupling_metrics` reports Ce=0 from `lib/core/driver/`.
- [x] **ED-2** `_handleActorContext` CC ≤ 10, body ≤ 30 LOC; file ≤ 500 lines.
- [x] **ED-3** `SoakDriver.run` CC ≤ 8, nesting ≤ 4, body ≤ 40 LOC; `soak_runner.dart` ≤ 200 lines.
- [x] **ED-4** `LocalSupabaseSoakActionExecutor.execute` CC ≤ 12; each per-action method CC ≤ 10.
- [x] **ED-5** `DriverDataSyncHandler.handle` CC ≤ 6; route-table test present.
- [x] **ED-6** `_handleActorContext` not in `mcp__jcodemunch__get_hotspots` top 25. 2026-04-19 re-indexed hotspot check also has no `lib/core/driver/**` symbols in the top 25.
- [x] **ED-7** `DriverServer` constructor zero nullable "backward compat" params.
- [x] **ED-8** Three `SoakActorProvisioner` implementations (backend/RLS, device-sync, headless-app-sync).

### State machine

- [x] **ES-1** `SyncStatus.undismissedConflictCount` in ctor/copyWith/==/hashCode + unit tests.
- [x] **ES-2** `Assert-SoakNoUndismissedConflictsSentinel` passes in a real soak run (no `hasConflictField` error). Reconciled against accepted physical run `20260419-s21-s10-es2-after-android-surface-false-positive-fix`: `passed=true`, `runtimeErrors=0`, `loggingGaps=0`, queue drained, blocked `0`, unprocessed `0`, max retry `0`, `directDriverSyncEndpointUsed=false`.
- [x] **ES-3** `GET /diagnostics/device_state` returns valid v1 snapshot on any built driver binary; integration test against fixture.
- [x] **ES-4** Schema-version mismatch detected + aborted ≤ 5s per actor with `schema_mismatch` classification (Pester).
- [x] **ES-5** `DevicePosture` derivation covers ≥ 8 enum values with table-driven tests.
- [x] **ES-6** Typed-key generator byte-identical across 3 runs (`verify-idempotent.ps1`).
- [x] **ES-7** All 16 feature testing-keys modules are re-exports of generated catalog.
- [x] **ES-8** `no_raw_key_outside_generated` custom_lint rule live with +/- fixtures; zero false positives on `lib/`.
- [x] **ES-9** `Assert-EventuallyDevicePosture` fails a deliberately broken state within `-AtMostMs` — one classified failure, no cascade.
- [x] **ES-10** Log-assertion rules fire on all 5 seeded fingerprints.
- [x] **ES-11** `loggingGaps` non-empty fails the run unless opted-in by name.
- [x] **ES-12** `timeline.html` + `timeline.json` generated every run, chronological, one swimlane per actor, links to evidence.
- [x] **ES-13** Every transition JSON + orchestrator JSON + evidence bundle carries `runId` / `actorId` / `transitionIndex`.
- [x] **ES-14** Failure injection drill: 3 seeded failures → 3 distinct root classified failures + visible divergence in timeline.

---

## Open questions snapshot (from spec §Open Questions)

Resolve each **before** the lane that depends on it. Mark with ✅ + date once resolved.

1. [x] Where does `DevicePosture` live? Resolved 2026-04-19: `lib/core/driver/device_state_machine.dart`. — gate for **P1-7**.
2. [x] YAML catalog vs Dart-first? Resolved 2026-04-19: YAML source at `tools/gen-keys/keys.yaml`, generated Dart/PowerShell/JSON outputs. — gate for **P2-4**.
3. [x] Row-count allowlist for `DataRegion.rowCountsByTable`. Resolved 2026-04-19: sync row counts live in `SyncRegistry.diagnosticRowCountTables` (`projects`, `daily_entries`, `photos`, `todo_items`) plus driver-local `change_log` / `conflict_log`. — gate for **P1-1**.
4. [x] Full vs partial cut-over for typed key catalog. Resolved 2026-04-19: full cut-over for all 16 feature modules before P3. — gate for **P3-1**.
5. [x] Keep `driver_seed_handler.dart` in `lib/core/driver/` or move with fixture? Resolved 2026-04-19: keep production seed route in `lib/core/driver/`; move heavy fixture data to integration harness seed modules. — gate for **P0-1**.
6. [x] `loggingGaps` strictness at first landing. Resolved 2026-04-19: strict/fatal by default with explicit allow-list support. — gate for **P3-2**.

---

## Risk watchlist (from spec §Risk Register — highest-impact first)

- **HIGH — Runtime impact not verified on a real device.** Per CLAUDE.md: every P-lane exit requires real 2-device smoke, not just unit tests. Don't close a slice without it.
- **High-if-rushed — Cut-over PRs break live soak runs.** P2-5 must be feature-by-feature with a soak-gate per PR.
- **Medium — `SoakDriver.run` extraction regresses burst/sample pacing.** Preserve counters exactly; reuse existing soak tests unchanged.
- **Medium — `DeviceStateSnapshot` perf on low-end emulators.** Bounded row-count allowlist; opt-in expensive fields; measure in P1-1 integration test.
- **Medium — Typed-key Dart/PS drift.** One YAML source; JSON index consumed by both; idempotency gate in CI.
- **Medium — PS `OrchestratorStateMachine` becomes a god-module.** Coordinator only; per-flow matrices injected.
- **Medium — Log-assertion false positives on existing runs.** Warning-only first, then flip to fatal.
- **Medium — Schema-version bump pain.** Version bump is a deliberate PR, never accidental; byte-identical output gate.
- **Low — `harness_seed_data` relocation breaks unlisted caller.** Mitigated by single-commit move + full `dart analyze lib integration_test test` before merge.
- **Low — `undismissedConflictCount` query expensive.** Reuse existing conflict-log query path; no new joins.

---

## Iteration-gate protocol

When I think the work is done, run this exact checklist before declaring it:

1. [ ] Every task in the on-screen list is `completed` (not skipped, not deferred without a spec reference).
2. [ ] Every **ED-n** and **ES-n** row above is ticked, with the verification command output pasted in a log entry below.
3. [ ] `dart analyze lib integration_test test/harness test/core/driver` — zero issues.
4. [ ] `dart run custom_lint` — zero new warnings.
5. [ ] `tools/test-sync-soak-harness.ps1` — green.
6. [ ] `pwsh scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` — exits 0 (exceptions documented in exception file AND motivated in this log).
7. [ ] `mcp__jcodemunch__get_hotspots` top 25 — no `lib/core/driver/**` method.
8. [ ] S21 smoke on the next device-sync touchpoint — pass, OR a written plumbing-only note exists per guardrail.
9. [ ] Re-read spec §Guardrails + §Out of shape. Nothing violated.
10. [ ] Re-read spec §Endpoint Definition. Every bullet ticked.

If any step fails: do **not** declare done. Re-open the relevant P-lane task and iterate.

---

## Dependency edges (don't start out of order)

- **P1-1** (DeviceStateSnapshot) depends on **P0-4** landing first (clean `_handleActorContext` is where the composed endpoint lives).
- **P1-7** (DevicePosture) depends on **P1-1** (needs the snapshot).
- **P2-4** (typed-key generator) depends on **P2-3** (registry shape must be stable).
- **P2-5** (feature cut-overs) depends on **P2-4** (generator + lint must exist).
- **P3-1** (orchestrator) depends on **P1-7** (posture primitive in use) + **P2-5** (stable keys).
- **P3-3** (timeline) depends on **P3-1** + **P3-2** (needs orchestrator JSON + fatal rule hits to render).
- **P3-4** (drills) depends on **P3-3** (observability drill needs timeline).
- **P2-6** (facade-shape confirmation) runs after all P0/P1 part-file extractions.

---

## Non-goals (from spec §Out of shape — do NOT do these)

- Do not split `HeadlessAppSyncActionExecutor` into provisioner/dispatcher/asserter. Only `_HeadlessAppSyncActor` moves out.
- Do not route the headless executor through `SyncCoordinator`. Direct `SyncEngineFactory().create(...)` is the engine-in-isolation seam.
- Do not broadly refactor `Flow.Mdot1174R.ps1` — still blocked on S21 acceptance (2026-04-18 spec item #42).
- Do not touch `SyncCoordinator`'s entrypoint contract. Observer-extraction is a separate spec.
- Do not introduce a runtime statechart library (XState, fsm2). `DevicePosture` is pure enum derivation.
- Do not adopt OpenTelemetry / W3C traceparent. `runId / actorId / transitionIndex` is sufficient.
- Do not migrate to Appium / Maestro / Patrol / Detox.
- Do not adopt TLA+ or formal model checking.
- Do not reintroduce `sync_status` columns or indexes. `undismissedConflictCount` lives on the in-memory `SyncStatus` immutable.
- Do not restructure `driver_interaction_handler_gesture_routes.dart`, `driver_data_sync_handler_query_routes.dart`, or `driver_widget_inspector.dart` until after P0/P1 land.

---

## 2026-04-19 — Router Red-Screen Zoom-Out Reset

### Why this reset happened

The S21 physical ES-2 rerun `20260419-s21-s10-es2-role-account-after-gorouter-pagekey-hardening`
still flashed red/blank after the narrow GoRouter page-key patch. Treat that patch as
ineffective for the failure class, not as evidence that the app is healthier.

Latest confirmed failure signature:

- `FlutterError: Failed assertion ... InheritedElement.notifyClients`
- `Duplicate GlobalKey detected in widget tree`
- duplicated key shape: `[GlobalObjectKey int#...]`
- stale parent: `InheritedGoRouter(goRouter: Instance of 'GoRouter')`
- affects S21 and tablet-sized surfaces, so this is not only compact breakpoint logic.

### New investigation rule

Do not keep making one-route or one-flow changes. The next work must be an app-wide
root/router architecture decision backed by a failure matrix and a minimal reproduction.

Current high-priority suspects to prove or eliminate:

1. `MaterialApp.router.builder` wraps the router child in `AppLockGate` even though
   `lib/core/app_widget.dart` already warns mutable wrappers there can reparent
   GoRouter-owned global keys.
2. `_ResponsiveMaterialAppShell` rebuilds the whole `MaterialApp.router` from a
   `LayoutBuilder` when breakpoint/theme density changes.
3. ShellRoute nested navigators use GoRouter-owned `GlobalObjectKey(navigatorKey.hashCode)`;
   repeated root/router/shell rebuilds can produce duplicate navigator widgets in one frame.
4. The soak harness still has a fail-loud gap: run summary records `runtimeErrors > 0`,
   but step-level `logAssertions` can remain green for blank/red screen evidence.

### Visible checklist replacement

- [x] Freeze current evidence and mark last GoRouter page-key patch as ineffective.
- [x] Build app-wide red-screen failure matrix across recent ES-2/four-role artifacts.
- [x] Audit root widget/router architecture: `MaterialApp.builder`, `AppLockGate`,
      `LayoutBuilder`/theme rebuilds, router lifetime, ShellRoute navigators.
- [x] Audit navigation APIs and route modules for duplicate stacks, parent navigator misuse,
      and imperative navigation during auth/sync transitions.
- [x] Create minimal reproduction tests outside the soak flow.
- [x] Patch root cause as one app-wide routing decision.
- [x] Verify with router/widget tests and ES-2 physical rerun.
- [x] Rebuild emulators and run honest four-device role soak.

---

## 2026-04-19 — App Lock Disabled Stub

User decision: biometric/app-lock is unfinished and not used. Disable it now instead of
letting partial lifecycle/biometric/root-wrapper behavior keep interfering with sync
hardening and router red-screen testing.

Implemented disabled contract:

- `lib/features/settings/app_lock_feature_flags.dart` is the central switch; it returns
  disabled.
- `AppLockGate` is pass-through only and cannot overlay the root router.
- `AppLockProvider` initializes inertly when disabled:
  - no auth-provider listener registration
  - no `WidgetsBindingObserver` registration
  - no biometric availability/authentication calls
  - no lock state mutation from lifecycle transitions
  - mutating APIs return unavailable/no-op state instead of enabling locks
- Settings hides the App Lock tile while the feature is disabled.
- Sync runtime wiring ignores stale app-lock secure-storage state so old local PIN config
  cannot skip resume or startup sync.

Evidence run:

- `dart analyze` targeted app-lock/settings/sync files: passed.
- `flutter test` app-lock provider, app-lock gate, settings screen, and sync runtime
  wiring tests: passed, 30 tests.

Next red-screen work must continue from the app-wide router/root checklist above. Do not
attribute future red screens to app-lock unless new logs prove it; the feature is now inert.

---

## 2026-04-19 — ES-2 And Four-Role Closure After App-Lock Disable

Changes in this closure pass:

- Removed `MaterialApp.router.builder` from `lib/core/app_widget.dart`; app lock no
  longer wraps GoRouter's root child at all.
- Added `test/core/app_widget_test.dart` to prove the root app does not contain
  `AppLockGate` and survives a breakpoint resize with the same router child.
- Confirmed the router is constructed once in `AppBootstrap` and reused by
  `ConstructionInspectorApp`; no second app-owned router stack found.
- Retained the narrow auth-route page-key/auth-success navigation cleanup from the
  earlier pass, but the accepted evidence below is the real decision point.

Harness correction:

- Run `20260419-s21-s10-es2-after-app-lock-disabled-root-builder-removed` failed with
  `runtimeErrors=2`, both `android_app_blank_surface`.
- Manual screenshot review showed both surfaces were valid UI:
  - S21: Sync Status screen visible after sync tap.
  - S10: Projects screen visible in expanded layout.
- Root cause was the Android UIAutomator classifier treating a normal Flutter
  `android.view.View` with no native text semantics as blank. That is not evidence of
  a red/blank Flutter screen.
- Fixed `AndroidSurface.ps1` so UIAutomator proves Android system overlays only.
  Red/blank app failures still come from Flutter logs, widget-tree classification,
  screenshot evidence, and log assertions.

Verification:

- `dart analyze` targeted app/root/app-lock/sync/settings files: passed.
- `flutter test` targeted app root, router, settings/app-lock, and sync runtime tests:
  passed, 53 tests.
- `tools/test-sync-soak-harness.ps1`: passed, 21 test files.
- Rebuilt physical driver apps:
  - S21 `RFCNC0Y975L` on port `4968`.
  - S10 `R52X90378YB` on port `4949`.
- Accepted ES-2 physical run:
  - `20260419-s21-s10-es2-after-android-surface-false-positive-fix`
  - flow `role-account-switch-only`
  - `passed=true`, `runtimeErrors=0`, `loggingGaps=0`
  - queue `drained`, blocked `0`, unprocessed `0`, max retry `0`
  - `directDriverSyncEndpointUsed=false`
  - screenshots `16`, logs `22`, steps `20`
- Rebuilt emulator driver apps after clearing emulator storage:
  - `emulator-5554` on port `4972`.
  - `emulator-5556` on port `4973`.
- Accepted honest four-role run:
  - `20260419-four-role-after-app-lock-disabled-root-builder-and-surface-classifier-fix`
  - actors: S21 admin, S10 inspector, EMU1 engineer, EMU2 office technician
  - flow `role-account-switch-only`
  - `passed=true`, `runtimeErrors=0`, `loggingGaps=0`
  - queue `drained`, blocked `0`, unprocessed `0`, max retry `0`
  - `directDriverSyncEndpointUsed=false`
  - actor count `4`, screenshots `30`, logs `42`, steps `38`

Residual risk / next scope:

- This closes the repeated red-screen gate for the role/account-switch soak lane.
- It does not by itself complete every remaining sync-soak decomposition spec item;
  continue with the decomposition TODO/spec backlog after preserving this evidence.

---

## 2026-04-19 — Decomposition Spec Scope Reset After Red-Screen Detour

Active specs reviewed:

- `.claude/codex/plans/2026-04-19-sync-soak-decomposition-state-machine-refactor-spec.md`
- `.claude/codex/plans/2026-04-19-sync-soak-driver-decomposition-todo-spec.md`

Current visible checklist:

- [x] Rebuild the scope from both specs and the latest checkpoint evidence.
- [x] Audit implemented vs open P0/P1/P2 items in the repo.
- [x] Update lock-in tooling so `scripts/check_sync_soak_file_sizes.ps1` covers
      `lib/core/driver/**/*.dart` with a separate driver exception file.
- [x] Document current over-budget files honestly instead of leaving the gate
      permanently red or silently out of scope.
- [x] Run the file-size gate after the lock-in update.
- [x] Continue with the next structural gap after the gate is honest.

Audit notes:

- P0/P1 decomposition items already present in the tree include seed fixture
  relocation, `SyncStatus.undismissedConflictCount`, `SoakRunState`,
  `SoakWorkerPool`, `SoakSampler`, `SoakFixtureRepair`,
  `SoakActorProvisioner`, `headless_app_sync_actor.dart`, route-table
  `DriverDataSyncHandler.handle`, `DeviceStateSnapshot`, `DevicePosture`,
  `OrchestratorStateMachine`, `LogAssertions`, `Timeline`, and generated keys.
- `rg` found no `lib/core/driver/**/*.dart` import of
  `features/*/data/datasources/local`; the original seed-data layering breach
  appears closed.
- `screen_contract_registry.dart` already contains an inline written exception
  explaining why it is intentionally registry-shaped, but the size-budget gate
  does not read a driver-specific exception file yet.
- `scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` currently fails
  before any new work because multiple newer PowerShell flow modules exceed the
  blocked threshold without documented exceptions. The next slice must make
  that gate explicit and actionable before treating future decomposition
  evidence as complete.

Implementation slice:

- Extended `scripts/check_sync_soak_file_sizes.ps1` to cover
  `lib/core/driver/**/*.dart` recursively and to read separate exception files:
  `tools/sync-soak/size-budget-exceptions.json` and
  `lib/core/driver/size-budget-exceptions.json`.
- Fixed the file-size summary output; it now reports status counts instead of
  `summary: =N`.
- Added explicit exceptions for existing over-budget PowerShell flow/helper
  files so `-FailOnBlocked` is actionable again.
- Added the driver exception file with only
  `screen_contract_registry.dart` as a registry-shaped exception.
- Split the formerly oversized
  `driver_data_sync_handler_query_routes.dart` into route registration,
  local-query routes, and remote-query routes; removed its temporary exception.

Verification:

- `pwsh -NoProfile -File scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked`
  passed with `blocked_excepted=17`, `ok=109`, `review=13`.
- `dart analyze lib\core\driver test\core\driver` passed.
- `flutter test test\core\driver` passed: 76 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed:
  21 test files, all assertions green.

Follow-on implementation slice:

- Tightened `DriverDataSyncHandler` constructor and stored dependencies from
  nullable required values to non-null required values.
- Removed the route-level `not available` fallback branches that only existed
  for the nullable driver data-sync constructor shape.
- `DriverServer` and `DriverSetup` were already explicitly wiring these seams;
  no ad-hoc wiring was needed.

Verification:

- `dart analyze lib\core\driver test\core\driver` passed.
- `flutter test test\core\driver` passed: 76 tests.
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
  passed with `blocked_excepted=17`, `ok=110`, `review=12`.
- `dart analyze lib integration_test test\harness test\core\driver` passed.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed:
  21 test files, all assertions green.
- `git diff --check` passed; only existing line-ending normalization warnings
  were reported.

Facade-shape slice:

- Added `export 'soak_metrics_collector.dart';` to
  `integration_test/sync/soak/soak_driver.dart`.
- Removed the direct `soak_metrics_collector.dart` import from
  `test/harness/soak_driver_test.dart`.
- Confirmed external imports now go through `soak_driver.dart`; the only
  remaining `integration_test/sync/soak/*` match is a comment inside the
  facade itself.
- `soak_driver.dart` remains under the spec budget at 79 lines.

Verification:

- `dart analyze lib integration_test test\harness test\core\driver` passed.
- `flutter test test\harness test\core\driver` passed: 104 tests, 21 skipped
  local/live gates.
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
  passed with `blocked_excepted=17`, `ok=110`, `review=12`.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed:
  21 test files, all assertions green.
- `git diff --check` passed; only line-ending normalization warnings were
  reported.

---

## 2026-04-19 — Spec Closeout Checklist Reconciliation

Repo audit after the latest scope reset found the remaining spec work is
evidence closeout, not another structural extraction:

- `driver_file_injection_handler.dart` is already a 30-line compatibility
  dispatcher; photo/document injection handlers and shared injection helpers
  exist separately.
- `tools/gen-keys/`, generated Dart/PowerShell/JSON key artifacts, generated
  feature re-exports, and `no_raw_key_outside_generated` exist.
- `DevicePosture`, `OrchestratorStateMachine`, `LogAssertions`, `Timeline`,
  `.claude/docs/state-harness.md`, and the separate sync-engine test
  decomposition checklist all exist.
- `lib/core/driver` line-budget state is honest: only
  `screen_contract_registry.dart` is over 500 lines, with the documented
  driver-specific exception.

Current visible checklist:

- [x] Refresh remaining scope from specs/checkpoints.
- [x] Document current live checklist in `Checkpoint.md`.
- [x] Reconcile ES-2 status with the later accepted physical evidence.
- [x] Run final static/custom-lint/size/harness gates on the current tree.
- [x] Run focused driver/harness Flutter tests on the current tree.
- [x] Record final closeout evidence in both progress logs.
- [x] Leave the next acceptance lane explicit: no extra device run is needed
      for this plumbing/evidence-only closeout unless a gate fails or a live
      accepted flow is touched.

Closeout fixes from the gate rerun:

- `custom_lint` caught missing active-record filters after the local
  data-sync query-route split. `_handleLocalFileHeadRoute` and
  `_handleLocalRecordRoute` now filter `deleted_at IS NULL` for soft-delete
  tables; non-soft-delete diagnostic tables use the validated-table raw query
  path.
- The raw Supabase sync-table owner lint now approves the new
  `driver_data_sync_handler_remote_query_routes.dart` split file, preserving
  the same driver diagnostics owner that was previously approved when the code
  lived in `driver_data_sync_handler_query_routes.dart`.
- Auth route page keys are now generated testing-key catalog entries with the
  exact prior values (`auth-*-page`). `auth_routes.dart` imports the
  testing-key facade and no longer carries hardcoded page-key literals.

Final verification:

- `dart analyze lib integration_test test\harness test\core\driver`:
  `No issues found!`
- `dart run custom_lint`: `No issues found!`
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`:
  passed with `blocked_excepted=17`, `ok=110`, `review=12`.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`:
  `sync-soak harness self-tests passed (21 test files, all assertions green)`.
- `pwsh -NoProfile -File tools\gen-keys\verify-idempotent.ps1`:
  `Typed key outputs are byte-identical.`
- `flutter test test\harness test\core\driver test\core\router\app_router_test.dart test\core\app_widget_test.dart`:
  passed, `123` tests plus `21` skipped live/local gates.
- `git diff --check`: passed; only line-ending normalization warnings were
  reported.

Device note:

- No new device run was started in this closeout slice because the final edits
  were lint/diagnostic-key plumbing and preserved the prior auth route page-key
  values. The existing accepted ES-2 physical run and honest four-role run
  remain the current device evidence for the red-screen/account-switch lane.

---

## 2026-04-19 — Spec Audit Closeout Pass

Current visible checklist:

- [x] Rebuild ED/ES audit matrix from both specs.
- [x] Verify repo artifacts, size budgets, lint contracts, and CI hooks against
      the matrix.
- [x] Patch CI, PR checklist, size-exception, and `SoakDriver.run` body gaps.
- [x] Run required gates after audit fixes.
- [x] Update checkpoint and progress logs with audit outcome.

Audit findings and fixes:

- The structural ED/ES implementation is present: seed fixture data is out of
  `lib/core/driver`, device-state snapshot/posture/orchestrator/log/timeline
  artifacts exist, generated testing keys and feature re-exports are in place,
  data-sync dispatch is route-table based, and the driver screen-contract
  exception is documented.
- The audit found real lock-in gaps: CI did not run key idempotency, the
  sync-soak size gate, or sync-soak harness self-tests; no PR checklist existed
  for new high-complexity driver handlers; and CodeMunch still reported
  `SoakDriver.run` as 45 lines against the 40-line target.
- Fixed those gaps by adding CI steps to `.github/workflows/quality-gate.yml`,
  adding `.github/pull_request_template.md`, documenting the periodic
  CodeMunch audit in
  `.codex/plans/2026-04-19-sync-soak-periodic-codemunch-audit-plan.md`,
  extracting `SoakDriver._prepareExecutor`, and making review-size exceptions
  explicit for the backend/RLS and headless app-sync executors.
- `harness_seed_defaults.dart` is absent by consolidation, not a relocation
  miss; the seed defaults are no longer a production driver file and the
  current heavy seed fixture is `integration_test/sync/harness/seed/harness_seed_data.dart`.

Audit evidence:

- `rg` found no `lib/core/driver/**/*.dart` import of feature local
  datasources and no hardcoded raw `Key('...')` / `ValueKey('...')` in `lib/`
  outside generated keys.
- CodeMunch after re-index:
  - `SoakDriver.run`: cyclomatic 1, nesting 1, 36 lines.
  - `LocalSupabaseSoakActionExecutor.execute`: cyclomatic 3, nesting 2, 7 lines.
  - `HeadlessAppSyncActionExecutor.execute`: cyclomatic 3, nesting 2, 7 lines.
  - `DriverDataSyncHandler.handle`: cyclomatic 3, nesting 2, 10 lines.
  - `DriverDiagnosticsHandler._handleActorContext`: cyclomatic 4, nesting 3,
    18 lines.
  - `get_hotspots top_n=25 min_complexity=10 days=60`: no
    `lib/core/driver/**` symbols.
  - Relocated seed-data coupling: `ca=0`, `ce=18`; shell grep confirms
    `lib/core/driver` has no feature local-datasource import.

Verification:

- `dart analyze lib integration_test test\harness test\core\driver`: passed.
- `dart run custom_lint`: passed.
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`:
  passed with `blocked_excepted=17`, `ok=110`, `review=10`,
  `review_excepted=2`.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`: passed,
  21 test files.
- `pwsh -NoProfile -File tools\gen-keys\verify-idempotent.ps1`: passed,
  typed key outputs byte-identical.
- `flutter test test\harness test\core\driver test\core\router\app_router_test.dart test\core\app_widget_test.dart`:
  passed, 123 tests plus 21 skipped live/local gates.
- `git diff --check`: passed; only line-ending normalization warnings.

---

## 2026-04-19 — Router Architecture Standardization Follow-On

Durable research memo created:

- `.codex/research/2026-04-19-router-red-screen-architecture-research.md`

What this memo now locks in:

- the current red-screen lane stays on `go_router`, not an immediate
  `auto_route` migration;
- router refresh must stay narrow and route-affecting;
- shared shells must receive explicit route intent and must not read
  `GoRouterState` in `build()`;
- router ownership invariants must be enforced by custom lints, not memory;
- `auto_route` only becomes justified if rebuilt device proof still reproduces
  the same router failure class after the hardened `go_router` lane is in
  place.

Current visible checklist:

- [x] Capture the router failure timeline, rejected fixes, and package research
      in a durable repo document.
- [x] Land app-wide router hardening (`RouterRefreshNotifier`,
      explicit `PrimaryNavTab`, shell-state decoupling).
- [x] Add lint-backed architectural rules for router refresh and shared-shell
      ownership.
- [x] Use the lint sweep to close newly exposed soak guardrail gaps
      (soft-delete filters, no-silent-catch).
- [x] Upgrade `go_router` within the current major line (`17.0.1` ->
      `17.2.1`) before another device proof pass.
- [x] Re-run the post-upgrade router/app widget Flutter suite cleanly.
- [ ] Rebuild the device apps on the upgraded router tree.
- [ ] Re-run the live backend-device marker lane on physical devices.
- [ ] Re-run the concurrent multi-device sync-hardening lane.
- [ ] Open an `auto_route` spike only if the rebuilt, hardened, upgraded tree
      still reproduces the same router failure class.

Post-upgrade verification:

- `flutter pub upgrade go_router` moved `pubspec.lock` from `17.0.1` to
  `17.2.1`.
- `dart analyze lib/core/router lib/core/app_widget.dart integration_test/sync/soak test/core/router test/core/app_widget_test.dart test/harness/soak_driver_test.dart fg_lint_packages/field_guide_lints/lib/architecture/rules fg_lint_packages/field_guide_lints/test/architecture`:
  passed.
- `dart run custom_lint`: passed.
- `flutter test test/core/router/app_router_test.dart test/core/router/scaffold_with_nav_bar_test.dart test/core/router/router_refresh_notifier_test.dart test/core/app_widget_test.dart test/core/driver/driver_route_contract_test.dart test/harness/soak_driver_test.dart -r expanded`:
  passed.

---

## 2026-04-19 — Live Black-Screen RCA, Compact Device Lane

Current visible checklist:

- [x] Capture live S21/tablet state and latest four-lane artifacts.
- [x] Fix the harness fail-loud gap for ordered evidence bundles.
- [x] Prove the compact-device break happens after healthy preflight and before
      the first mutation action.
- [ ] Remove the remaining primary-route overlap path in `AppRouter`.
- [ ] Add router breadcrumb logging plus a lint so the same route-ownership
      regression cannot land silently again.
- [ ] Rebuild S21/tablet/emulators and rerun the physical-device smoke.
- [ ] Resume backend-device marker proof and concurrent hardening once device
      UI is stable again.

What the evidence now says:

- `enterprise-four-lane-smoke-20260419-231123` proved the fail-loud patch is
  working: the run now stops on `runtime_log_error` for duplicate GlobalKey
  evidence instead of timing out silently.
- S21 preflight is healthy:
  `/projects`, `hasBottomNav=true`, `project_list_screen.rootPresent=true`,
  and `screenshot-before.png` shows the expected Projects screen.
- Roughly one second later, before the first mutation action executes, S21 is
  already broken at the state-machine pre-sentinel:
  `/projects`, `hasBottomNav=false`, `project_list_screen.rootPresent=false`.
- Live capture confirms the current failure class is still router collapse, not
  a generic draw failure: S21 stays on `MainActivity`, reports a `/report/...`
  route, and shows a pure black surface while the tablet renders the same
  report route normally.
- The recurring runtime fingerprint is still
  `Multiple widgets used the same GlobalKey` on
  `InheritedGoRouter(goRouter: Instance of 'GoRouter')`.

Decision for the next patch:

- Treat the remaining animated primary-tab page path as the active app-wide
  overlap suspect.
- Revert the driver-only `pushReplacement` experiment so the next device rerun
  tests one router change at a time.
- Add router breadcrumb logging and a lint that forbids
  `CustomTransitionPage` in `lib/core/router/app_router.dart`.

---

## 2026-04-19 — Compact Shell Router RCA Addendum

Current visible checklist:

- [x] Prove the remaining failure is app-side Flutter/router corruption, not a
      host compositor-only glitch.
- [x] Compare the compact S21 tree against the large tablet control after the
      same lane/run.
- [x] Identify the first upstream Flutter assertion before the duplicate
      `InheritedGoRouter` crash.
- [ ] Replace the compact shell `NavigationBar` path with a non-problematic
      router-shell implementation and lock that rule in lint/tests/docs.
- [ ] Rebuild the device apps and rerun the four-lane smoke plus backend-device
      marker proof.

What the evidence says now:

- Live S21 driver state after the failed run still reports
  `/report/80000000-0000-0000-0000-000000000120`, but
  `screen_contract.rootPresent=false`.
- The live S21 widget tree is truncated to
  `WidgetsApp -> _LocalizationsScope -> ErrorWidget`, while the tablet still
  has a healthy `_CustomNavigator -> AppScaffold` tree on the report route.
- Fresh S21 adb logs on the broken compact lane show a more upstream failure
  before the duplicate GlobalKey crash:
  - `renderObject.child == child` assertion;
  - `Tried to build dirty widget in the wrong build scope`;
  - offending element: `AnimatedPhysicalModel`;
  - then `Duplicate GlobalKey detected in widget tree` on
    `InheritedGoRouter(goRouter: Instance of 'GoRouter')`.
- The healthy compact preflight tree proves that `AnimatedPhysicalModel`
  belongs to the compact shell `NavigationBar` in
  `lib/core/router/scaffold_with_nav_bar.dart`.
- The tablet control does not reproduce this path because the large layout uses
  `NavigationRail`, not the compact `NavigationBar`.

Current architectural conclusion:

- The remaining blocker is not the sync state machine and not a generic
  Windows/Android draw issue.
- The compact router shell still owns an animated bottom-nav surface that can
  stay dirty while the router refreshes or replaces routes, and that stale
  compact shell then cascades into the `go_router` duplicate-GlobalKey tree
  truncation.
- This keeps the lane on `go_router` for now, but it shifts the next fix from
  “more router package research” to “remove the compact animated shell path and
  standardize a safer compact nav implementation.”
## 2026-04-20 AutoRoute-First Implementation Checkpoint

- Harness/device-pressure work is paused by user direction until the
  AutoRoute/refactor spec order is further complete.
- AutoRoute route declarations now cover the app route families named in the
  spec, including auth/onboarding, tabs, projects, entries/reports, forms,
  pay apps, sync/conflicts/trash/exports, settings/admin/help/legal/profile,
  toolbox, gallery, todos, analytics, quantities, and calculator.
- `ConstructionInspectorApp` now provides an `AppNavigatorScope` selected from
  `AppRouterHost.routerBackend`, so `context.appGo` / `context.appPush` use
  AutoRoute when the AutoRoute host is active instead of always using
  GoRouter.
- `AutoRouteAppNavigator` now maps app route intents to generated AutoRoute
  route classes and carries the extra-bearing flows needed by entry review,
  review summary, PDF import preview, and M&P import preview.
- AutoRoute import-preview pages now render the real preview screens and
  convert the same payload types as the GoRouter compatibility routes.
- Persistent plan updated:
  `.codex/plans/2026-04-20-autoroute-routing-provider-refactor-todo-spec.md`.
- Detailed checkpoint updated:
  `.codex/checkpoints/2026-04-20-autoroute-routing-provider-refactor-checkpoint.md`.
- Verification passed:
  `dart run build_runner build --delete-conflicting-outputs`,
  targeted `flutter analyze`, and
  `flutter test test/core/navigation/app_navigation_extensions_test.dart
  test/core/router/autoroute/app_auto_router_test.dart
  test/core/driver/driver_route_contract_test.dart`.
- Follow-up route catalog slice:
  `validateAppRouteIntent` now gates GoRouter and AutoRoute app navigators
  against the feature-owned route descriptors before dispatch, and route tests
  assert AutoRoute contains every catalog path template.
- Additional verification passed:
  `flutter test test/core/navigation/app_route_catalog_test.dart
  test/core/navigation/app_navigation_extensions_test.dart
  test/core/router/autoroute/app_auto_router_test.dart
  test/core/driver/driver_route_contract_test.dart`,
  router-import lint unit tests, and scoped `custom_lint` with only
  max-import-count warnings.

## 2026-04-20 AutoRoute Page Wrapper Split

- Split the large AutoRoute page-wrapper file into route-family files under
  `lib/core/router/autoroute/pages/`.
- Kept feature modules free of `auto_route` imports; the package-specific
  `@RoutePage` annotations stay in the approved app router composition layer.
- `app_auto_router_pages.dart` is now a barrel only, and generated output still
  lives only at `lib/core/router/autoroute/app_auto_router.gr.dart`.
- Verification passed: build runner, targeted analyzer, router/navigation/
  driver-contract tests, router import lint tests, and scoped custom-lint with
  only the pre-existing `screen_registry.dart` import-count warning.
- Next AutoRoute-first task: continue legacy GoRouter route declaration
  replacement and Phase 6/7 navigation/design-system lint enforcement before
  returning to device proof.

## 2026-04-20 Legacy GoRouter Metadata Alignment

- Legacy GoRouter route modules now consume `AppRouteId.pathTemplate` and
  `AppRouteId.routeName` instead of owning duplicate path/name strings.
- Primary GoRouter tab routes, exact restoration route sets, and compatibility
  redirects also read from `AppRouteId` where applicable.
- This is intentionally partial: `core/router/routes/*` still exists as the
  GoRouter compatibility page-builder surface until the backend is removed.
- Verification passed: targeted analyzer, `app_router_test`,
  `app_route_id_test`, the broader router/navigation/driver-contract suite,
  router import lint tests, and scoped custom-lint with only the pre-existing
  `screen_registry.dart` import-count warning.

## 2026-04-20 AutoRoute Generated Output And Navigation Lint Lock-In

- Added `no_autoroute_generated_file_outside_router` so AutoRoute `*.gr.dart`
  output is allowed only at
  `lib/core/router/autoroute/app_auto_router.gr.dart`.
- Tightened `no_auto_route_import_outside_navigation_layer`; arbitrary
  generated `.gr.dart` files are no longer an implicit escape hatch for
  AutoRoute imports.
- Upgraded `no_raw_navigator` to an error-level app-navigation rule banning
  route-level `Navigator.push*` outside approved navigation/router owners.
  Local `Navigator.pop` remains allowed for dialogs, sheets, and modal result
  ownership.
- Architecture decision: do not hand-split generated
  `app_auto_router.gr.dart`; contain it to the configured generated path and
  keep hand-owned AutoRoute wrappers split under
  `lib/core/router/autoroute/pages/`.
- Verification passed: targeted lint unit tests, targeted Dart/Flutter
  analyzer, scoped custom-lint with only the existing `screen_registry.dart`
  import-count warning, and a `lib/` scan showing only the configured
  `app_auto_router.gr.dart` generated output.

## 2026-04-20 Feature Route Catalog Tests

- Added `test/features/navigation/feature_route_catalogs_test.dart` to lock
  feature-local route ownership.
- The new test verifies each feature catalog owns the expected `AppRouteId`
  set, has non-empty feature metadata, declares path params matching the route
  template, and keeps public routes limited to auth/legal surfaces.
- Verification passed:
  `flutter test test/features/navigation/feature_route_catalogs_test.dart
  test/core/navigation/app_route_catalog_test.dart` and targeted
  `flutter analyze` on feature navigation catalogs plus the new test.

## 2026-04-20 Route Guard Volatility Lint

- Added `no_volatile_route_guard_provider_fields`.
- The lint applies to route guard and router-reevaluation owners and blocks
  direct reads of `isLoadingProfile`, refresh-in-flight fields, sync-progress
  fields, and direct profile-refresh methods.
- This complements `no_volatile_route_access_snapshot_fields`: the snapshot
  cannot grow volatile fields, and the guard layer cannot bypass the snapshot
  to read those fields directly.
- Verification passed: volatile guard/snapshot lint unit tests, targeted
  analyzer, and scoped custom-lint on `lib/core/router` with only the existing
  `screen_registry.dart` import-count warning.

## 2026-04-20 Screen Lifecycle Profile Refresh Lint

- Added `no_direct_profile_refresh_in_screen_lifecycle`.
- The lint blocks direct `refreshUserProfile()` and
  `refreshUserProfileIfDue()` calls from feature presentation screens/widgets/
  controllers, preserving `ProfileRefreshScheduler` as the screen-facing
  refresh seam.
- Verification passed: lint unit tests, targeted analyzer, and scoped
  custom-lint on auth/projects/sync presentation paths with only the existing
  `screen_registry.dart` import-count warning.

## 2026-04-20 AutoRoute Production Cutover And Compatibility Removal

- Deleted the production GoRouter compatibility router path:
  `AppRouter`, `AppRedirect`, `RouterRefreshNotifier`,
  `GoRouterAppNavigator`, and `core/router/routes/*`.
- Added `app_route_restoration_policy.dart` and `app_route_matcher.dart` so
  restoration and route-template matching survive after the GoRouter backend
  removal.
- `RouteAccessPolicy` now enforces route-specific access from feature-owned
  `AppRouteAccessPolicy` metadata instead of scattered compatibility redirects.
- `AppBootstrap` now constructs `AppAutoRouterHost` directly, and the host now
  owns last-route restore/persist behavior.
- Page-factory ownership is now a locked decision: keep page/widget factories
  out of feature catalogs and inside the approved
  `core/router/autoroute/**` composition seam.
- Verification passed:
  focused AutoRoute/bootstrap/restoration/policy/controller/catalog tests,
  targeted `dart analyze`, and scoped `custom_lint` with only the existing
  `screen_registry.dart` import-count warning.
