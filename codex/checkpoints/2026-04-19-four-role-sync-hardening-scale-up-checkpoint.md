# Four-Role Sync Hardening Scale-Up Checkpoint

Date: 2026-04-19
Status: active checkpoint
Controlling spec:
`.codex/plans/2026-04-19-four-role-sync-hardening-scale-up-spec.md`

## How To Use This File

Append one entry per implementation or verification slice. Record what changed,
what evidence was reviewed or produced, exact artifact paths, and what remains
open. Do not mark a checkbox complete without artifact-backed evidence.

The older sync-soak specs, live task list, and implementation log are now audit
inputs. Continue the remaining work here.

## Audit Consolidation - 2026-04-19

Reviewed source set:

- Maintained Codex context and sync rules.
- Role permission matrix.
- April 16 sync-system hardening spec and plan.
- April 17-18 sync-soak plans, completed plans, result indexes, and research.
- April 18 unified implementation log, 5068 lines.
- April 18 live task list, 2054 lines.
- April 19 decomposition/state-machine specs and progress logs.
- Latest `.codex/checkpoints/Checkpoint.md` closeout evidence.

Excluded:

- `.codex/plans/2026-04-19-codebase-hygiene-refactor-todo-spec.md`.

Audit decisions:

- The decomposition/state-machine specs are implemented from the ED/ES endpoint
  and lock-in perspective. They are no longer the active implementation source.
- The old live task list contains stale open items. The most important stale
  item is the simultaneous four-role gate: the live task list says it is open,
  but `.codex/checkpoints/Checkpoint.md` records the accepted honest four-role
  account-switch run
  `20260419-four-role-after-app-lock-disabled-root-builder-and-surface-classifier-fix`.
- The remaining scope is scale/hardening: concurrent four-role traffic,
  operation history/checkers, 15-20 app actors, backend/device overlap,
  fault/liveness windows, staging/perf, diagnostics/alerts, and the
  consistency contract.

Latest accepted evidence carried forward:

- ES-2 physical account-switch:
  `20260419-s21-s10-es2-after-android-surface-false-positive-fix`.
- Four-role account-switch:
  `20260419-four-role-after-app-lock-disabled-root-builder-and-surface-classifier-fix`.
- S10 inspector to S21 office-technician role seams:
  daily-entry/review, quantity, document/storage, photo/storage/local-cache
  visual gate, and MDOT 0582B form.
- Real non-admin RLS denials:
  `rls-denial-probes-20260419T0935Z`.
- Headless app-sync scale proof:
  12 virtual users, 6 concurrent workers, isolated SQLite stores, real
  sessions, real `SyncEngine`, 174/174 actions, zero failures/errors/RLS
  denials.

## Active Checklist

### P0 - Canonical Source

- [x] Audit old specs/todos/checkpoints and identify stale open items.
- [x] Exclude codebase hygiene.
- [x] Create the new controlling spec.
- [x] Create this checkpoint.
- [x] Update `.codex/PLAN.md` to point to this spec/checkpoint as the active
  continuation source.

### P1 - Harness Entrypoint Inventory

- [x] Inventory commands/scripts for:
  four-role UI account/role flows, S21/S10 role collaboration, headless
  app-sync, backend/RLS pressure, local performance, staging performance, and
  nightly soak.
- [x] Identify the smallest next code slice needed for mixed evidence:
  operation history/checker output or a parent wrapper that preserves evidence
  layers separately.

### P1 - Four-Role Concurrent Traffic

- [ ] Design the first four-role concurrent write/read run.
- [ ] Include admin, engineer, office technician, and inspector real sessions.
- [ ] Include concurrent field-data writes, peer review/project-data actions,
  denied/hidden checks, storage proof, and final reconciliation.
- [ ] Accept only with clean runtime/logging/queue/conflict/UI evidence and
  no direct `/driver/sync`.

### P1 - Operation History And Checkers

- [x] Add seedable operation history if missing.
  Current Dart soak operation history records action, iteration, virtual user,
  start/end time, result, latency, burst-window state, and classified failure
  details. Actor/user/role/project/table/object/invariant enrichment remains
  open with checker output.
- [x] Add headless app-sync operation intent enrichment.
  Headless operation history now carries actor kind/index, user, role,
  company, project scope, project id, table/record/object family, and expected
  invariant impact where the executor can identify them.
- [x] Add Dart result-level invariant checker output.
- [x] Save failing seeds/schedules for replay.
  `replayMetadata` carries seed/config/action weights, operation schedule, and
  failing schedule.

### P1 - Headless App-Sync Scale

- [ ] Expand fixture toward 15 projects and realistic records/files.
- [x] Run a short 15-actor/8-worker local headless app-sync pressure proof.
- [ ] Run 15-20 isolated app actors with operation history/checker output.
- [ ] Layer S21/S10 UI actors over headless pressure without conflating
  evidence.

### P1 - Backend/Device Overlap

- [ ] Run backend/RLS pressure concurrently with device or headless app-sync.
- [ ] Keep backend/RLS, UI-device, headless app-sync, and checker summaries
  separate.

### P2 - Faults, Liveness, Staging, And Ops

- [ ] Add offline/network/auth/storage/lifecycle/realtime fault windows.
- [ ] Add explicit quiescence thresholds.
- [ ] Run local and staging performance gates.
- [ ] Prove staging schema/RLS/storage parity.
- [ ] Collect three consecutive green full-system staging or
  staging-equivalent runs.
- [ ] Add operational alerts, especially stale `sync_hint_subscriptions`.
- [ ] Write `docs/sync-consistency-contract.md`.

## Enterprise-Scale On-Screen Checklist - 2026-04-19

This is the active execution list for scaling from the current S21/S10 and
headless proofs to an enterprise-level mixed sync lab. It mirrors the visible
plan and the controlling spec.

- [ ] E0. Refresh the spec/checkpoint with this checklist and record current
  Docker/Supabase, role-secret, device, emulator, and git baseline.
- [ ] E1. Confirm S21 and S10 through `adb devices`, then confirm two
  emulator serials can run beside them.
- [ ] E2. Define the first four-lane role/project map:
  S21 admin, S10 inspector, emulator engineer, emulator office technician,
  with one primary synced project per lane plus shared visibility checks.
- [ ] E3. Extend the parent enterprise orchestrator to preserve backend/RLS,
  headless app-sync, and device UI child evidence layers in one manifest.
- [ ] E4. Add parent-script controls for headless app-sync pressure:
  enable/disable, duration, user count, concurrency, action delay, and action
  weights.
- [ ] E5. Add manifest-level overlap timing and pass/fail rules so backend-only
  or headless-only success cannot satisfy device UI acceptance.
- [ ] E6. Add fixture/project scale controls:
  three to four projects for the first realistic baseline, then 15 projects
  for final 15-20 actor acceptance.
- [ ] E7. Run a local parent smoke with backend/RLS plus headless app-sync and
  no UI devices to validate manifest separation.
- [ ] E8. Run S21 plus S10 UI role traffic over backend/headless pressure with
  current accepted refactored flows.
- [ ] E9. Bring up two emulators, install/run real-auth debug apps, and
  register them as engineer and office-technician actors.
- [ ] E10. Run four-lane UI traffic across S21, S10, emulator engineer, and
  emulator office technician, one synced project per lane.
- [ ] E11. Add the narrow backend-to-device marker contract:
  backend stamps one deterministic project-scoped `daily_entries.site_safety`
  marker per lane, each device proves local SQLite visibility after UI sync,
  and the parent fails fast when a device session cannot see the intended
  marker fixture.
- [ ] E12. Add checker/read-only phases for unauthorized metadata, Trash
  scoping, project visibility, blocked queues, conflicts, and storage
  row/object consistency.
- [ ] E13. Add the quiescence gate:
  stop writes, heal faults, wait for queues/conflicts/downloads idle, then
  reconcile project hashes.
- [ ] E14. Scale headless app-sync to 15-20 actors while device UI traffic is
  active.
- [ ] E15. Add fault windows:
  offline/reconnect, background/foreground, auth refresh, storage transient
  failure, and realtime hint loss/duplication.
- [ ] E16. Capture p50/p95/p99 convergence and storage availability timings,
  then compare against performance baselines.
- [ ] E17. Repeat as staging-equivalent or staging and collect three
  consecutive green full-system runs at one commit.
- [ ] E18. Write/update the sync consistency contract and operational
  diagnostics/alert checklist.

## Next Exact Action

Extend the parent enterprise orchestrator so one run can launch and preserve
backend/RLS, headless app-sync, and device UI evidence layers separately. Then
run a no-device parent smoke with backend/RLS plus headless app-sync to prove
manifest separation before adding S21/S10 UI traffic.

## 2026-04-19 - Harness Inventory And Operation History

Work completed:

- Reconciled the audited specs/checkpoints into the new controlling spec and
  this checkpoint.
- Inventoried the active harness entrypoints:
  - `tools/enterprise-sync-soak-lab.ps1` for device UI role/account,
    role-collaboration, documents, MDOT, and related refactored flow runs.
  - `tools/enterprise-sync-concurrent-soak.ps1` for preserving backend/RLS
    and device-sync child summaries in one parent manifest.
  - `scripts/soak_headless_app_sync.ps1` for local headless app-sync actors
    using real sessions, isolated SQLite stores, and real `SyncEngine`.
  - `scripts/soak_local.ps1` for backend/RLS local soak.
  - `.github/workflows/quality-gate.yml` for staging backend/RLS soak and
    sync performance measurement.
  - `.github/workflows/nightly-soak.yml` for the 15-minute staging/nightly
    soak lane.
  - `.github/workflows/staging-schema-gate.yml` for schema hash parity.
  - `test/harness/sync_performance_local_test.dart`,
    `scripts/check_perf_regression.py`, and `scripts/perf_baseline.json` for
    local performance/regression work.
- Implemented the first missing artifact primitive:
  `integration_test/sync/soak/soak_operation_history.dart`.
- Wired operation history through the Dart soak driver result path:
  `soak_driver.dart`, `soak_models.dart`, `soak_run_state.dart`,
  `soak_summary_builder.dart`, and `soak_worker_pool.dart`.
- Added harness test coverage in `test/harness/soak_driver_test.dart`.

Verification:

- `dart format integration_test\sync\soak\soak_driver.dart integration_test\sync\soak\soak_operation_history.dart integration_test\sync\soak\soak_models.dart integration_test\sync\soak\soak_run_state.dart integration_test\sync\soak\soak_summary_builder.dart integration_test\sync\soak\soak_worker_pool.dart test\harness\soak_driver_test.dart`
- `dart analyze integration_test\sync\soak test\harness\soak_driver_test.dart`
- `flutter test test\harness\soak_driver_test.dart -r expanded`
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
- `flutter test test\harness\headless_app_sync_actor_test.dart -r expanded`
  skipped as designed without `RUN_HEADLESS_APP_SYNC=true`.
- `dart analyze lib integration_test test\harness test\core\driver`
- `flutter test test\harness -r expanded`
- `git diff --check`

## 2026-04-19 - Checker Output And Headless Intent Enrichment

Work completed:

- Added `integration_test/sync/soak/soak_invariant_checker.dart`.
- Added `checkerOutput` to `SoakResult.toJson()`.
- Checker output currently validates:
  operation-history count, operation failure count, action count totals,
  successful/failed count totals, actor report totals, ordered timestamps,
  nonnegative latencies, zero failed actions/errors/RLS denials, all-or-none
  operation intent capture, and evidence-layer sync-engine honesty.
- Added `SoakOperationIntent` and a `SoakActionContext.recordOperationIntent`
  channel so executors can attach intent metadata without changing the
  executor interface.
- Wired headless app-sync actions to record actor/user/role/company/project
  scope plus table/record/object family and expected invariant impact for
  read, daily entry, quantity, photo metadata, form response, delete/restore,
  assignment churn, and auth refresh actions.

Verification:

- `dart format integration_test\sync\soak\soak_models.dart integration_test\sync\soak\soak_operation_history.dart integration_test\sync\soak\soak_worker_pool.dart integration_test\sync\soak\headless_app_sync_action_executor.dart integration_test\sync\soak\soak_invariant_checker.dart test\harness\soak_driver_test.dart`
- `dart analyze integration_test\sync\soak test\harness\soak_driver_test.dart`
- `flutter test test\harness\soak_driver_test.dart -r expanded`
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
- `dart analyze lib integration_test test\harness test\core\driver`
- `flutter test test\harness -r expanded`
- `git diff --check`

Blocked live proof:

- Attempted
  `pwsh -NoProfile -File scripts\soak_headless_app_sync.ps1 -DurationSeconds 0 -UserCount 4 -Concurrency 1 -ActionDelayMilliseconds 0`.
- It failed before running the test because Docker Desktop was not available:
  Docker could not connect to `dockerDesktopLinuxEngine`.
- The next real-session local headless proof must be rerun after Docker
  Desktop is started.

Resolved live proof:

- Reran
  `pwsh -NoProfile -File scripts\soak_headless_app_sync.ps1 -DurationSeconds 0 -UserCount 4 -Concurrency 1 -ActionDelayMilliseconds 0`
  after Docker Desktop was available.
- Artifact:
  `build/soak/headless-app-sync-summary.json`.
- Summary:
  `wasSuccessful=true`, `soakLayer=device_sync`,
  `syncEngineExercised=true`, `attemptedActions=1`, `failedActions=0`,
  `errors=0`, `rlsDenials=0`, `operationHistory=1`,
  `checkerOutput.passed=true`, `failedCheckCount=0`.
- First operation intent was emitted from `headless_app_sync` with role
  `admin` and expected invariant impact
  `form_responses acknowledged metadata write converges remotely`.

Open next:

- Extend operation intent enrichment to UI-driver and backend/RLS executors.
- Extend the 15-actor proof into a longer 15-20 actor acceptance run with
  fixture expansion, backend overlap, UI layering, faults, and quiescence.

## 2026-04-19 - Replay Metadata, Actor Serialization, And 15-Actor Proof

Work completed:

- Added `integration_test/sync/soak/soak_replay_metadata.dart`.
- Added `replayMetadata` to `SoakResult.toJson()`.
- `replayMetadata` now records:
  seed when known, requested duration, virtual users, concurrent workers,
  action delay, burst settings, action weights, operation schedule, and
  failing schedule.
- Added per-virtual-actor serialization in `SoakWorkerPool`.
  Cross-actor concurrency remains, but one virtual app actor no longer runs
  multiple local-store/sync operations concurrently.
- Added `soak driver run serializes actions per virtual actor` coverage.
- Updated `test/harness/headless_app_sync_actor_test.dart` to write both the
  stable latest summary and a timestamped summary copy.

Pressure evidence:

- Short smoke proof after replay metadata:
  `pwsh -NoProfile -File scripts\soak_headless_app_sync.ps1 -DurationSeconds 0 -UserCount 4 -Concurrency 1 -ActionDelayMilliseconds 0`
  passed and emitted:
  `operationHistory=1`, `checkerOutput.passed=true`,
  `replayMetadata.hasReplayableSeed=true`, `randomSeed=42`,
  `failingSchedule=0`.
- First 15-actor/8-worker run before per-actor serialization failed:
  `DurationSeconds=20`, `UserCount=15`, `Concurrency=8`,
  `ActionDelayMilliseconds=0`; summary showed `attemptedActions=148`,
  `successfulActions=83`, `failedActions=65`, `errors=65`,
  `rlsDenials=0`, `checkerOutput.passed=false`,
  `failingSchedule=65`.
  Representative failures were overlapping actor sync failures and missing
  pending `change_log` rows after concurrent same-actor pressure. This run is
  not accepted evidence.
- Same 15-actor/8-worker command after per-actor serialization passed:
  `attemptedActions=94`, `successfulActions=94`, `failedActions=0`,
  `errors=0`, `rlsDenials=0`, `maxActionLatencyMs=6829`,
  `averageActionLatencyMs=1338`, `operationHistory=94`,
  `checkerOutput.passed=true`, `failedCheckCount=0`,
  `replayMetadata.hasReplayableSeed=true`, `randomSeed=42`,
  `operationSchedule=94`, `failingSchedule=0`.
- Timestamped artifact proof exists for the latest smoke run:
  `build/soak/headless-app-sync-summary-2026-04-19T221508473131Z.json`.

Verification:

- `dart analyze integration_test\sync\soak test\harness\soak_driver_test.dart`
- `flutter test test\harness\soak_driver_test.dart -r expanded`
- `dart analyze test\harness\headless_app_sync_actor_test.dart integration_test\sync\soak`
- `flutter test test\harness\headless_app_sync_actor_test.dart -r expanded`
  skipped without `RUN_HEADLESS_APP_SYNC=true`.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
- `dart analyze lib integration_test test\harness test\core\driver`
- `flutter test test\harness -r expanded`
- `git diff --check`

Open next:

- Extend operation intent enrichment to UI-driver and backend/RLS executors.
- Run backend/RLS pressure concurrently with headless app-sync while preserving
  evidence-layer summaries separately.
- Layer S21/S10 UI role traffic over headless pressure.
- Increase duration and actor count toward the full 15-20 actor acceptance run
  and then add fault/quiescence windows.

## 2026-04-19 - Enterprise Parent Manifest, Four-Project Fixture, And Argument Guard

Work completed:

- Added the enterprise-scale checklist to the controlling spec and this
  checkpoint.
- Extended `tools/enterprise-sync-concurrent-soak.ps1` so one parent run can
  preserve separate child evidence layers for:
  backend/RLS pressure, headless app-sync pressure, and device UI sync.
- Added parent-script headless app-sync controls:
  enable/disable, duration, user count, concurrency, action delay, and action
  weights.
- Added `actorTopology` to the parent manifest with normalized
  label/driver-port/role/project-index fields.
- Added no-device parent smoke mode with `-SkipDeviceSync` for backend plus
  headless manifest validation before tying up phones.
- Added manifest pass/fail rules so backend/RLS and headless app-sync are
  independently checked. Headless app-sync must report `device_sync`,
  `syncEngineExercised=true`, and `checkerOutput.passed=true`.
- Expanded the mutable soak fixture from projects 1-3 to projects 1-4:
  `supabase/seed.sql` now seeds project-4 locations, contractors, equipment,
  bid items, personnel types, daily entries, form responses, and photos.
- Updated the Dart soak helpers so backend/RLS and headless app-sync choose
  from the shared four-project mutable window.
- Updated `soakFixtureVersion`/`soakFixtureHash` to
  `harness-seed-2026-04-19-v2` /
  `users12-projects15-seededchildren-projects1to4`.
- Added a focused harness test proving the mutable photo repair window covers
  80 rows through project 4.
- Added a temporary size-budget exception for the active parent orchestrator
  and updated the headless app-sync executor exception after the four-project
  fixture expansion.
- Fixed the recurring PowerShell actor argument hazard:
  `tools/enterprise-sync-concurrent-soak.ps1` now uses
  `CmdletBinding(PositionalBinding = $false)`, trims accidental literal quote
  characters from actor specs, and documents the safe invocation forms.

Safe actor invocation going forward:

- From an existing PowerShell session, call the script directly:
  `& .\tools\enterprise-sync-concurrent-soak.ps1 -Actors @("S21:4968:admin:1", "Tablet:4949:inspector:2") ...`
- When crossing a `pwsh -File` process boundary, pass actors as one
  comma-separated string:
  `pwsh -File tools\enterprise-sync-concurrent-soak.ps1 -Actors "S21:4968:admin:1,Tablet:4949:inspector:2" ...`
- Do not use `pwsh -File ... -Actors $actors` where `$actors` is a
  PowerShell array. That flattens into argv before the script can bind the
  full array.

Evidence:

- `supabase db reset --local` initially failed after a partial fixture edit
  with `equipment_contractor_id_fkey`, proving project 4 needed supporting
  contractor/equipment rows. After aligning all supporting project-scoped seed
  CTEs, `supabase db reset --local` passed.
- No-device parent smoke passed:
  `build/soak/codex-parent-headless-backend-smoke-20260419-183316/manifest.json`.
  Parent summary:
  `passed=true`, backend/RLS child `passed=true`, headless app-sync child
  `passed=true`, device UI child disabled.
- Backend/RLS child summary:
  `attemptedActions=9031`, `failedActions=0`, `errors=0`, `rlsDenials=0`,
  `checkerOutput.passed=true`, `operationHistory=9031`,
  `failingSchedule=0`.
- Headless app-sync child summary:
  `attemptedActions=3`, `failedActions=0`, `errors=0`, `rlsDenials=0`,
  `checkerOutput.passed=true`, `operationHistory=3`, `failingSchedule=0`.
- `adb devices -l` saw four targets:
  S21 `RFCNC0Y975L`, physical tablet `R52X90378YB`, emulator `5554`, and
  emulator `5556`.
- Driver diagnostics were live on:
  `4968` admin, `4949` inspector, `4972` engineer, and `4973`
  office technician; all reported pending/blocked/conflict counts as zero.
- A four-lane overlay attempt was interrupted by the user after launch. The
  leftover parent process was stopped. This is not accepted evidence.

Verification:

- `dart analyze integration_test\sync\soak test\harness\soak_driver_test.dart`
- `flutter test test\harness\soak_driver_test.dart -r expanded`
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`
- `supabase db reset --local`
- `dart analyze lib integration_test test\harness test\core\driver`
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
- `flutter test test\harness\headless_app_sync_actor_test.dart -r expanded`
  skipped as designed without `RUN_HEADLESS_APP_SYNC=true`.
- `git diff --check`

Open next:

- Rerun the four-lane overlay with the safe direct-script or single
  comma-string actor invocation.
- Decide whether the physical inspector lane should remain the current tablet
  or wait for the S10 to be connected; `adb` did not show an S10 serial in
  this slice.
- Extend the parent manifest with same-backend/staging awareness before
  treating backend/headless pressure as pressure on the same backend used by
  device UI actors.

## 2026-04-19 - Four-Lane Overlay Acceptance, Auth Readiness, And Preset Summary

Work completed:

- Investigated the failed four-lane parent run
  `build/soak/codex-four-lane-sync-overlay-smoke-20260419-184355/manifest.json`.
  Device UI and headless app-sync passed, but backend/RLS failed on the first
  operation with `PGRST303: JWT issued at future`.
- Added `integration_test/sync/soak/soak_auth_readiness.dart`.
  Backend/RLS and headless app-sync actors now wait for PostgREST to accept
  the freshly issued real Supabase JWT before the workload starts. The wait is
  scoped to the specific JWT clock-skew condition; unrelated auth, RLS, or
  data failures still fail normally.
- Added `tools/enterprise-sync-four-lane-smoke.ps1`, a preset wrapper that
  constructs the four actor strings internally so the recurring PowerShell
  `-Actors` array-spill/quote issue cannot occur for the standard smoke.
- Added `tools/summarize-enterprise-sync-soak.ps1`.
  The parent orchestrator now computes `durationMs` and writes readable JSON
  and Markdown summaries for the parent manifest plus backend/RLS, headless
  app-sync, and device UI child summaries.

Accepted evidence:

- Backend/headless isolated parent smoke after auth-readiness fix:
  `build/soak/codex-backend-headless-auth-ready-smoke-20260419-185035/manifest.json`.
  Parent passed with backend/RLS and headless app-sync enabled and device UI
  skipped.
- Four-lane mixed overlay accepted:
  `build/soak/codex-four-lane-sync-overlay-smoke-20260419-185214/manifest.json`.
  Parent result `passed=true`; backend started before device, headless started
  before device, and neither finished before device start.
- Backend/RLS child:
  `attemptedActions=8687`, `failedActions=0`, `errors=0`, `rlsDenials=0`,
  `checkerOutput.passed=true`, `failingSchedule=0`,
  `fixtureVersion=harness-seed-2026-04-19-v2`,
  `fixtureHash=users12-projects15-seededchildren-projects1to4`.
- Headless app-sync child:
  `attemptedActions=3`, `failedActions=0`, `errors=0`, `rlsDenials=0`,
  `checkerOutput.passed=true`, `syncEngineExercised=true`,
  `failingSchedule=0`.
- Device UI child:
  four actors, `flow=sync-only`, `passed=true`, `failedActorRounds=0`,
  `queueDrainResult=drained`, `runtimeErrors=0`, `loggingGaps=0`,
  `blockedRowCount=0`, `unprocessedRowCount=0`, `maxRetryCount=0`.
- Actor topology:
  S21/admin/project 1 on port `4968`; tablet/inspector/project 2 on port
  `4949`; emulator engineer/project 3 on port `4972`; emulator
  office-technician/project 4 on port `4973`.
- Readable summary:
  `build/soak/codex-four-lane-sync-overlay-smoke-20260419-185214/codex-four-lane-sync-overlay-smoke-20260419-185214-enterprise-summary.md`.

Verification:

- `dart analyze integration_test\sync\soak test\harness\soak_driver_test.dart`
- `flutter test test\harness\soak_driver_test.dart -r expanded`
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
- `pwsh -NoProfile -File tools\enterprise-sync-four-lane-smoke.ps1 -DryRun`
- `pwsh -NoProfile -File tools\summarize-enterprise-sync-soak.ps1 -ManifestPath build\soak\codex-four-lane-sync-overlay-smoke-20260419-185214\manifest.json -OutputRoot build\soak\codex-four-lane-sync-overlay-smoke-20260419-185214 -ReportName codex-four-lane-sync-overlay-smoke-20260419-185214`
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`
- `git diff --check`

Open next:

- Re-run the preset with the S10 as the inspector lane once the S10 is visible
  in `adb devices -l`.
- Increase the mixed-layer run from smoke to 2 minutes, then 5 minutes, before
  increasing headless users/concurrency toward the 15-20 actor acceptance
  target.
- Add role/visibility checker phases during active writes and after
  quiescence, then add fault windows.

## 2026-04-19 - Backend Pressure Coupling Reassessment

Finding:

- The current accepted four-lane run is a useful orchestration smoke, but it
  is not enough for scale acceptance.
- Backend/RLS pressure is real load against the same local Supabase backend:
  it uses real anon sessions and PostgREST/RLS to read projects/bid items,
  mutate seeded `daily_entries`, `photos`, and `form_responses`, soft-delete
  and restore seeded photos, refresh sessions, and churn one project assignment.
- The weakness is coupling:
  the device `sync-only` flow currently walks actors sequentially, triggers
  the Sync Dashboard UI, and proves clean final queue/runtime state. It does
  not prove that a backend-pressure marker written during the run was pulled
  into the device's local SQLite store.
- Therefore the next scale step must not simply raise durations/concurrency.
  It must add a coupled-pressure proof first.

Added to the active spec/checklist:

- Add a named scale profile knob:
  `smoke`, `baseline`, `pressure`, and `enterprise`, while preserving explicit
  duration/user/concurrency overrides.
- Replace the orchestration-only four-lane smoke with a coupled pressure proof:
  backend/RLS stamps deterministic project-scoped markers while devices sync,
  and each device lane proves those markers arrived locally.
- Make device lanes concurrent for profiles above `smoke`.
- Add bidirectional impact:
  device UI writes must be observed by backend/checkers while backend/headless
  pressure is still active, and backend writes must be observed by devices
  before quiescence is accepted.

Open next:

- Implement the first backend-to-device marker contract. Recommended narrow
  first cut:
  backend writes a deterministic `daily_entries.activities` marker per project
  lane, parent records those marker IDs, and device lanes query
  `/driver/query-records` after UI sync to prove local visibility.
- After backend-to-device proof works, add the reverse device-to-backend proof
  using an existing UI mutation lane instead of `sync-only`.

## 2026-04-19 - Backend-To-Device Marker Contract And Same-Fixture Preflight

Work completed:

- Added the narrow backend-to-device marker contract to the active checklist.
- Added `tools/sync-soak/BackendDeviceMarkers.ps1`.
  The marker writer uses a real anon/admin harness session, patches one
  deterministic project-scoped `daily_entries.site_safety` marker per actor
  lane, and writes `backend-device-markers.json`.
- Wired `-EnableBackendDeviceMarkers` through:
  `tools/enterprise-sync-concurrent-soak.ps1`,
  `tools/enterprise-sync-four-lane-smoke.ps1`,
  `tools/enterprise-sync-soak-lab.ps1`,
  `tools/sync-soak/DeviceLab.RefactoredDispatcher.ps1`, and
  `tools/sync-soak/Flow.SyncDashboard.ps1`.
- The Sync Dashboard `sync-only` flow now verifies the marker after UI-triggered
  sync through `/driver/query-records` and writes
  `round-*-backend-device-marker-proof.json`.
- Added a same-fixture preflight before backend/headless pressure starts:
  each device's own authenticated Supabase session must see the exact marker
  project and daily-entry row through `/driver/remote-record`.
- Added debug-only backend target diagnostics to `/diagnostics/actor_context`.
  Rebuilt apps will report configured Supabase URL/host with anon key redacted
  so future marker proofs can distinguish backend mismatch from RLS/sync
  timing.
- Added same-backend setup support for the next live attempt:
  - `tools/env-utils.ps1` can now prefer process environment dart-defines when
    `FIELD_GUIDE_PREFER_PROCESS_ENV=true`, so local harness builds do not
    silently reuse `.env.secret` backend settings.
  - `tools/sync-soak/RoleAccounts.ps1` now supports
    `SOAK_ROLE_ACCOUNT_SOURCE=local_seed`, returning the seeded local
    `@harness.test` role accounts with redaction preserved.
  - `tools/start-local-harness-driver-lab.ps1` records the four lane/device
    mapping, points app builds and role-account helpers at local Supabase, can
    start all four driver lanes, and can optionally run the
    `role-account-switch-only` flow after startup.
- Updated `tools/summarize-enterprise-sync-soak.ps1` to surface
  backend-device marker and preflight fields.
- Locked the wiring with `tools/sync-soak/tests/FlowWiring.Tests.ps1`.

Verification:

- `dart format lib\core\driver\driver_diagnostics_handler.dart`
- `dart analyze lib\core\driver\driver_diagnostics_handler.dart`
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
- `pwsh -NoProfile -File tools\start-local-harness-driver-lab.ps1 -RunRoleSwitch -DryRun`
- `git diff --check`

Live marker smoke:

- Command:
  `pwsh -NoProfile -File tools\enterprise-sync-four-lane-smoke.ps1 -RunId enterprise-four-lane-marker-preflight-20260419-193223`
- Result: failed loudly before launching backend/RLS, headless app-sync, or
  device UI sync jobs.
- Manifest:
  `build/soak/enterprise-four-lane-marker-preflight-20260419-193223/manifest.json`
- Preflight artifact:
  `build/soak/enterprise-four-lane-marker-preflight-20260419-193223/backend-device-marker-fixture-preflight.json`
- Summary:
  `fixturePreflightPassed=false`, `passed=false`, `failedCheckCount=4`.
- All four actors returned 404 for the local harness marker projects and
  daily-entry rows:
  `20000000-0000-0000-0000-000000000001` through project 4 and
  `80000000-0000-0000-0000-000000000120` through entry 420.
- The devices were authenticated into the beta/live company/project set, not
  the local harness fixture. Actor context/local SQLite showed only:
  `75ae3283-d4b2-4035-ba2f-7b4adb018199` and
  `a3433d2f-11b2-5866-bed8-010f8c41c325`.

Finding:

- The harness now fails at the correct level. Backend stress is not meaningful
  for the device lanes until the backend marker writer and device apps target
  the same backend and fixture.
- The next accepted coupled-pressure run must either:
  1. run rebuilt device apps against local harness Supabase and harness role
     accounts; or
  2. deliberately stamp safe disposable markers into the same staging/live
     backend/project set currently used by the devices, with cleanup policy and
     role/account ownership documented first.

Open next:

- Prefer the local harness route for the next proof:
  rebuild/relaunch the four device apps with `SUPABASE_URL=http://127.0.0.1:54321`
  and the local anon key, keep each lane signed in to its assigned seeded
  harness persona, then run concurrent write/read stress and marker proof.
  Do not run `role-account-switch-only` as a scale-hardening step.
- Once preflight passes, rerun the marker smoke and require both
  `backend-device-markers.json` and per-device local marker proof artifacts.
- After backend-to-device proof works, add the reverse device-to-backend proof
  using an existing UI mutation lane instead of `sync-only`.

## 2026-04-19 - Corrected Device Scale Direction: Concurrent Writes, Not Account Switching

Finding:

- `role-account-switch-only` is not a meaningful enterprise scale workload.
  It is only useful as a stale auth/project-scope regression check. It does not
  simulate concurrent users writing to SQLite, change_log, Supabase, or storage
  while other roles are reading and syncing.
- The current hardening path must use signed-in personas on separate
  devices/emulators and then run real UI mutation flows concurrently.

Work completed:

- Updated the active spec/checklist to remove account switching from the
  scale-up execution path.
- Added `tools/enterprise-sync-device-concurrent-stress.ps1`.
  It starts one refactored UI mutation flow per actor lane in parallel, writes
  per-actor artifacts, aggregates a device-sync summary, and can follow each
  mutation lane with the backend-marker Sync Dashboard proof.
- Added `-ConcurrentDeviceLanes` to
  `tools/enterprise-sync-concurrent-soak.ps1`. The parent now rejects
  `legacy`, `sync-only`, and `role-account-switch-only` for concurrent device
  lanes because those do not create real UI write pressure.
- Updated `tools/enterprise-sync-four-lane-smoke.ps1` so the default device
  layer is now concurrent `daily-entry-only` mutation lanes, with optional
  backend marker proof after each lane.
- Retired `-RunRoleSwitch` in `tools/start-local-harness-driver-lab.ps1`.
  The wrapper now starts local-harness driver lanes only; stress flows own
  persona readiness and real writes.
- Added `-EnsurePersonaReady` to
  `tools/start-local-harness-driver-lab.ps1`. This is setup-only: if a lane is
  logged out, it signs in once as the assigned seeded local role account; if a
  lane is already signed in as the wrong role, it fails instead of switching
  accounts.

Live attempt note:

- `tools/start-local-harness-driver-lab.ps1 -EnsureLocalSupabase -RunRoleSwitch -ForceRebuild`
  was stopped by the corrected direction and an emulator storage blocker before
  role switching could matter. S21 and tablet relaunched; `emulator-5554`
  failed APK install with `Requested internal only, but not enough space`.

Open next:

- Free or recreate `emulator-5554` storage, then start the four driver lanes
  with `-EnsurePersonaReady` and without `-RunRoleSwitch`.
- Rerun the four-lane parent smoke with concurrent device mutation lanes:
  backend/RLS pressure + headless app-sync + four UI mutation lanes + backend
  marker local SQLite proof.

## 2026-04-19 - Headless Full Round-Trip Sync Proof Under Backend Pressure

Question answered:

- Backend pressure alone is not sync hardening evidence. The accepted local
  shape now has to prove full round-trip sync:
  1. backend/Supabase write -> app `SyncEngine` pull -> local SQLite;
  2. app local SQLite write -> `SyncEngine` push -> backend/Supabase;
  3. app A local write -> backend/Supabase -> app B `SyncEngine` pull ->
     app B local SQLite.

Implementation completed:

- Added `-EnableBackendHeadlessMarkers` to
  `tools/enterprise-sync-concurrent-soak.ps1`.
  The parent now starts backend/RLS pressure, stamps deterministic backend
  marker rows, passes the marker manifest into the headless app-sync lane, and
  fails the parent if the marker proof is absent or false.
- Added marker-manifest support to `scripts/soak_headless_app_sync.ps1` and
  `test/harness/headless_app_sync_actor_test.dart`.
- Added `SoakRunFinalizer` and implemented it in
  `HeadlessAppSyncActionExecutor`.
  The finalizer now:
  - syncs each actor with the real `SyncEngine`;
  - proves every visible backend marker exists in that actor's local SQLite
    store;
  - writes `backend-headless-marker-proof.json`;
  - performs one app-to-app convergence check by writing `daily_entries.site_safety`
    through one actor's local SQLite/change_log, pushing through SyncEngine,
    then pulling and verifying the same marker in another actor's local SQLite;
  - writes `headless-app-to-app-convergence-proof.json`.
- Extended backend marker manifest creation so the same helper can stamp
  backend-to-device and backend-to-headless marker contracts without changing
  the device contract.
- Serialized backend/RLS per-record direct write assertions so the baseline
  pressure lane does not accidentally become an unscoped same-row collision
  test. Same-row collision/LWW/conflict behavior remains a separate open lane.
- Extended the parent readable summary to show backend-headless markers and
  the app convergence proof path.

Earlier pressure evidence folded in:

- Headless-only app-sync scale proof:
  `build/soak/headless-app-sync-summary-2026-04-20T002539165336Z.json`
  passed with 20 actors, 8 workers, 386/386 actions, zero failures/errors/RLS
  denials, real sessions, isolated SQLite stores, and real `SyncEngine`.
- Partitioned backend/headless baseline:
  `build/soak/enterprise-headless-backend-partitioned-pressure-20260419-202835/manifest.json`
  passed with backend/RLS and headless SyncEngine layers separated.

Accepted full round-trip local proof:

- Command:
  `pwsh -NoProfile -File tools\enterprise-sync-concurrent-soak.ps1 -RunId enterprise-headless-backend-full-roundtrip-20260419-204912 -OutputRoot build\soak\enterprise-headless-backend-full-roundtrip-20260419-204912 -EnsureLocalSupabase -SkipDeviceSync -EnableHeadlessAppSync -EnableBackendHeadlessMarkers -HeadlessDurationSeconds 30 -HeadlessUserCount 12 -HeadlessConcurrency 4 -HeadlessActionDelayMilliseconds 0 -BackendDurationMinutes 1 -BackendUserCount 6 -BackendConcurrency 3 -BackendActionDelayMilliseconds 0`
- Parent manifest:
  `build/soak/enterprise-headless-backend-full-roundtrip-20260419-204912/manifest.json`
- Result: passed.
- Backend/RLS layer:
  7,390 attempted actions, 0 failures, 0 errors, checker passed, evidence
  layer `backend_rls`, `syncEngineExercised=false`.
- Headless app-sync layer:
  36 attempted actions, 0 failures, 0 errors, checker passed, evidence layer
  `device_sync`, `syncEngineExercised=true`.
- Backend-to-headless marker proof:
  `build/soak/enterprise-headless-backend-full-roundtrip-20260419-204912/headless-app-sync/backend-headless-marker-proof.json`
  passed with 12 actors, 4 markers, and 45 local SQLite marker checks.
- App-to-app convergence proof:
  `build/soak/enterprise-headless-backend-full-roundtrip-20260419-204912/headless-app-sync/headless-app-to-app-convergence-proof.json`
  passed with `remoteMatched=true` and `readerLocalMatched=true`.

Verification:

- `dart format integration_test\sync\soak\backend_rls_soak_action_executor.dart integration_test\sync\soak\headless_app_sync_action_executor.dart integration_test\sync\soak\soak_runner.dart test\harness\headless_app_sync_actor_test.dart`
- `dart analyze integration_test\sync\soak\backend_rls_soak_action_executor.dart integration_test\sync\soak\headless_app_sync_action_executor.dart integration_test\sync\soak\soak_executors.dart integration_test\sync\soak\soak_runner.dart test\harness\headless_app_sync_actor_test.dart`
- `dart analyze integration_test\sync\soak test\harness\headless_app_sync_actor_test.dart test\harness\soak_driver_test.dart`
- `flutter test test\harness\soak_driver_test.dart test\harness\headless_app_sync_actor_test.dart -r expanded`
  passed; the headless live test is skipped unless
  `RUN_HEADLESS_APP_SYNC=true`.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
- `git diff --check`
- PowerShell parser checks for:
  `tools\enterprise-sync-concurrent-soak.ps1`,
  `scripts\soak_headless_app_sync.ps1`,
  `tools\sync-soak\BackendDeviceMarkers.ps1`,
  `tools\summarize-enterprise-sync-soak.ps1`.

Important remaining scope:

- Device UI is still not accepted for the full marker contract. The latest
  four-lane device attempt was blocked by the GoRouter duplicate GlobalKey
  red-screen class, so the router fix must be rebuilt onto devices and rerun.
- The accepted full round-trip proof is headless SyncEngine evidence, not a UI
  proof. It hardens the sync engine and local SQLite/Supabase path, then the
  same contract must be layered onto S21, S10/tablet, and two emulators.
- Same-row collision/LWW/conflict semantics remain open and must be tested in
  a named collision lane, not hidden inside the baseline pressure lane.

## 2026-04-19 - Four-Lane UI Marker Attempt Rejected On Router Runtime Blocker

Purpose:

- Move the accepted backend/headless full round-trip contract back onto live UI
  devices with concurrent mutation lanes, not account switching.
- Require all layers to run against the same local harness backend and fixture:
  S21, tablet/S10 fallback, two emulators, backend/RLS pressure, headless
  app-sync pressure, backend-to-device markers, and backend-to-headless markers.

Setup completed:

- Recovered the shared emulator AVD storage by wiping it once in writable mode,
  then relaunched `emulator-5554` and `emulator-5556` as read-only instances.
- Started the local harness driver lab against local Supabase with seeded
  personas:
  `build/soak/local-harness-driver-lab-routerfix-retry2-20260419-211243`.
- Persona readiness passed without account switching:
  `build/soak/local-harness-driver-lab-routerfix-retry2-20260419-211243/persona-readiness/summary.json`.
- Device contexts confirmed all four lanes were on
  `http://127.0.0.1:54321` with driver ports:
  S21 `4968`, tablet `4949`, engineer emulator `4972`, office emulator `4973`.

Rejected run:

- Command:
  `pwsh -NoProfile -File tools\enterprise-sync-four-lane-smoke.ps1 -RunId enterprise-four-lane-routerfix-live-20260419-211738 -BackendDurationMinutes 1 -BackendUserCount 4 -BackendConcurrency 2 -HeadlessDurationSeconds 10 -HeadlessUserCount 4 -HeadlessConcurrency 2 -DeviceFlow daily-entry-only`
- Parent manifest:
  `build/soak/enterprise-four-lane-routerfix-live-20260419-211738/manifest.json`
- Readable summary:
  `build/soak/enterprise-four-lane-routerfix-live-20260419-211738/enterprise-four-lane-routerfix-live-20260419-211738-enterprise-summary.md`
- Result: failed and rejected as UI evidence.

What passed:

- Backend/RLS pressure passed:
  7,756 actions, 0 failures, 0 errors, checker passed.
- Headless app-sync pressure passed:
  9 actions, 0 failures, 0 errors, real `SyncEngine` exercised.
- Backend-to-device marker fixture preflight passed:
  `backend_to_device_daily_entries_site_safety_v1`, 4 markers.
- Backend-to-headless marker proof passed:
  `backend_to_headless_daily_entries_site_safety_v1`, 4 markers, with app
  convergence proof preserved.

Why the run is rejected:

- Device UI failed at `driver_preflight` before any UI mutation lane started.
- Device summary:
  `build/soak/enterprise-four-lane-routerfix-live-20260419-211738/device-sync/summary.json`
  reported `failedActorRounds=4`, `failedActionCount=4`,
  `runtimeErrors=28`, and `queueDrainResult=drained`.
- First-failure evidence shows the app-wide GoRouter runtime signature:
  `Duplicate GlobalKey detected in widget tree`, key shape
  `[GlobalObjectKey int#...]`, stale parent
  `InheritedGoRouter(goRouter: Instance of 'GoRouter')`.
- S21 first-failure artifact:
  `build/soak/enterprise-four-lane-routerfix-live-20260419-211738/device-sync/S21/mutation/S21/preflight-failure-adb-logcat.txt`.

Follow-up performed:

- Audited the local `go_router-17.0.1` source. The duplicated key shape is
  GoRouter's `_CustomNavigator` key:
  `GlobalObjectKey(configuration.navigatorKey.hashCode)` or shell
  `GlobalObjectKey(navigatorKey.hashCode)`.
- Found the working tree had reintroduced `state.pageKey` into production
  router files even though the earlier UI stability gate required stable local
  route keys.
- Restored the app-wide route-key guardrail:
  production `lib/core/router/` no longer uses `state.pageKey`; it remains only
  in lint rule documentation/tests.
- Verification after restoring the guardrail:
  `dart analyze lib\core\router\app_router.dart lib\core\router\routes\auth_routes.dart lib\core\router\routes\entry_routes.dart lib\core\router\routes\sync_routes.dart fg_lint_packages\field_guide_lints\lib\architecture\rules\no_go_router_state_page_key_in_shell_routes.dart`;
  `dart test fg_lint_packages\field_guide_lints\test\architecture\no_go_router_state_page_key_in_shell_routes_test.dart fg_lint_packages\field_guide_lints\test\architecture\no_explicit_shell_route_navigator_key_test.dart fg_lint_packages\field_guide_lints\test\architecture\no_material_app_router_builder_theme_wrapper_test.dart`;
  `flutter test test\core\router\app_router_test.dart test\core\router\scaffold_with_nav_bar_test.dart -r expanded`.

Open next:

- Rebuild/relaunch S21, tablet/S10 fallback, `emulator-5554`, and
  `emulator-5556` from the restored router guardrail.
- Rerun the same four-lane coupled smoke and do not accept device evidence
  unless preflight is clean and backend-device marker proof reaches local
  SQLite through the UI app.
