# Sync Soak Decomposition Todo Spec

Date: 2026-04-18
Branch: `gocr-integration`

## Purpose

Create a decomposition backlog for the sync-soak system after the recent
device-lab and refactored-flow expansion. This is not a replacement for the
unified hardening checklist. It is the structural debt companion: keep the
current soak acceptance path intact while splitting the largest scripts and
mixed-responsibility files into smaller runtime, evidence, mutation, cleanup,
storage, form, and orchestration helpers.

Primary hardening tracker:
`.codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`

Append implementation notes to:
`.codex/checkpoints/2026-04-18-sync-soak-unified-implementation-log.md`

## Guardrails

- [ ] Do not change acceptance semantics while decomposing.
- [ ] Do not call `POST /driver/sync` for acceptance paths; UI-triggered sync
  remains the accepted device-sync path.
- [ ] Do not use `MOCK_AUTH`; every auth/sync proof stays on real sessions and
  real backend state.
- [ ] Keep backend/RLS soak evidence separate from device-sync evidence.
- [ ] Keep result artifacts backward compatible until all active result-index
  readers are updated.
- [ ] Prefer behavior-preserving extraction before adding new soak flows.
- [ ] Every extraction slice must pass `tools/test-sync-soak-harness.ps1`.
- [ ] Every extraction slice that touches a live accepted flow must rerun the
  narrowest accepted S21 gate or record why a doc-only/plumbing-only slice did
  not require a device run.

## Audit Baseline

Repo-wide sync/soak/driver/harness sweep found the real largest file and the
main decomposition queue:

- [ ] `tools/enterprise-sync-soak-lab.ps1` is the current largest soak file at
  1,922 lines. It owns parameter validation, environment loading, refactored
  flow dispatch, readable-index export, legacy device-lab actor conversion,
  driver HTTP calls, screenshots, ADB/debug logs, failure injection, storage
  proof, mutation target resolution, local mutation flows, UI sync measurement,
  final summary aggregation, and pass/fail policy.
- [ ] `tools/sync-soak/Flow.Mdot1126Signature.ps1` is 1,063 lines. It mixes
  MDOT 1126 form creation, signature submission, signature row waits,
  signature storage proof, draft cleanup, ledger cleanup, summary completion,
  actor/round loops, and failure evidence.
- [ ] `integration_test/sync/soak/soak_driver.dart` is 998 lines. CodeMunch
  maps it as a mixed Dart soak model/runner/executor file: `SoakDriver`,
  `SoakActionMix`, `SoakResult`, `SoakActorReport`,
  `DriverSoakActionExecutor`, `LocalSupabaseSoakActionExecutor`, fixture
  personas, action classification, concurrency, actor reports, direct
  Supabase/RLS actions, and driver-app actions all live together.
- [ ] `tools/sync-soak/Flow.Contractors.ps1` is 826 lines and mixes contractor
  graph creation, personnel/equipment saves, local/remote assertions, cleanup,
  actor/round loops, and summary policy.
- [ ] `tools/sync-soak/Flow.Photo.ps1` is 740 lines and mixes storage auth,
  object proof, delete/absence checks, photo creation, cleanup, actor/round
  loops, and summary policy.
- [ ] `tools/sync-soak/Flow.Mdot1174R.ps1` is 692 lines and is still on the
  critical path because MDOT 1174R is implemented but not accepted. Avoid broad
  refactors here until the row-section key/state failure is fixed or the
  extraction directly reduces that risk.
- [ ] `tools/sync-soak/Flow.DailyEntryActivity.ps1` is 688 lines and shares
  target resolution, change-log waits, cleanup, and actor/round loop patterns
  with quantity/photo/contractors.
- [ ] `tools/sync-soak/Flow.Quantity.ps1` is 648 lines and duplicates the same
  target resolution, mutation, cleanup, sync, and summary skeleton.
- [ ] `tools/sync-soak/Flow.Mdot0582B.ps1` is 645 lines and contains form
  marker building/assertion, report-attached form creation, generic
  form-response cleanup, actor/round loops, and summary policy.
- [ ] `tools/sync-soak/Flow.Mdot1126Expanded.ps1` is 607 lines and duplicates
  MDOT 1126 form open/edit/assert/loop behavior already adjacent to the
  signature flow.
- [ ] `tools/test-sync-soak-harness.ps1` is 434 lines and is becoming a
  catch-all structural self-test instead of a focused test runner.
- [ ] Adjacent sync tests are also large, but they are not the first sync-soak
  decomposition target: `test/features/sync/engine/sync_engine_test.dart`
  1,433 lines, `cascade_soft_delete_test.dart` 1,054 lines, and several
  pull/file/integrity tests above 800 lines. Track separately unless they block
  soak refactors.

## Target Shape

The target is a thin set of orchestrators with reusable helpers:

- `tools/enterprise-sync-soak-lab.ps1` should become parameter validation plus
  high-level dispatch only.
- `tools/enterprise-sync-concurrent-soak.ps1` should remain a parent
  orchestrator that starts backend/RLS and device-sync child runs and writes a
  manifest.
- Each `tools/sync-soak/Flow.*.ps1` file should own only flow-specific user
  actions, marker definitions, and flow-specific assertions.
- Shared actor/round loops, preflight/final capture, summary updates, failure
  artifacts, queue-drain policy, cleanup dispatch, storage proof, and form
  route helpers should live in named helper modules.
- Dart backend/RLS soak code should split models, runner, local Supabase
  executor, driver-app executor, persona fixtures, and artifact serialization.

## Size Goals

These are practical budgets, not arbitrary purity rules. A file can exceed the
target briefly during an extraction slice, but the endpoint should fit these
limits unless there is a written exception.

- [ ] Top-level PowerShell entrypoint scripts should be 150-250 lines.
  Examples: `tools/enterprise-sync-soak-lab.ps1`,
  `tools/enterprise-sync-concurrent-soak.ps1`,
  `tools/test-sync-soak-harness.ps1`.
- [ ] Public PowerShell flow facade files should be 150-300 lines.
  A facade should expose the public `Invoke-Soak<Name>OnlyRun` entrypoint and
  flow-specific sequencing, not own generic runtime mechanics.
- [ ] PowerShell helper modules should usually be 100-300 lines and should
  have one reason to change: storage proof, cleanup ledger, form navigation,
  artifact capture, change-log assertions, mutation targets, actor scheduling,
  or result indexing.
- [ ] Any non-generated PowerShell file over 350 lines should trigger a review
  question: is this a cohesive module, or did another helper boundary emerge?
- [ ] Any non-generated PowerShell file over 500 lines should require either
  an immediate decomposition task or a documented exception.
- [ ] PowerShell functions should usually be 20-70 lines.
- [ ] PowerShell functions over 100 lines should be treated as extraction
  candidates unless they are a simple data catalog or a deliberately linear
  orchestration function with no hidden branching.
- [ ] Dart model/value files should usually be under 250 lines.
- [ ] Dart runners/executors should usually be under 300 lines.
- [ ] Dart files over 400 lines in `integration_test/sync/soak/` should require
  a decomposition task or exception.
- [ ] Dart classes over 250 lines should trigger a split unless they are
  intentionally table/registry-shaped.
- [ ] Test files should usually stay under 300-400 lines by moving scenario
  builders, fixtures, and assertion helpers out of the test body.

## Endpoint Definition

The endpoint is reached when the sync-soak system has clear facades, cohesive
helpers, and low-friction tests. This is the target we should check off before
declaring the decomposition lane complete:

- [ ] `tools/enterprise-sync-soak-lab.ps1` is a thin facade under 250 lines.
- [ ] The legacy device-lab path is either removed or quarantined in a clearly
  named legacy module that cannot be confused with current acceptance evidence.
- [ ] Every accepted `-Flow` value is wired through a shared dispatcher and a
  shared module loader.
- [ ] Every `Flow.*.ps1` public file is under 350 lines or has a written
  exception in this spec.
- [ ] No `Flow.*.ps1` file owns generic actor/round loops, artifact capture,
  queue-drain aggregation, storage HTTP proof, or cleanup dispatch.
- [ ] Shared PowerShell helpers exist for:
  - module loading;
  - argument normalization;
  - environment/secret loading;
  - actor/session modeling;
  - flow runtime and actor/round execution;
  - artifacts/evidence bundles;
  - runtime and widget failure classification;
  - mutation target lookup;
  - change-log assertions;
  - cleanup ledger and cleanup dispatch;
  - storage object proof;
  - form creation/open/edit/assertion mechanics;
  - result-index export.
- [ ] `integration_test/sync/soak/soak_driver.dart` is reduced to a compatibility
  facade or removed after imports are migrated.
- [ ] Dart soak code has separate files for action mix, models, runner,
  backend/RLS executor, driver-app executor, personas/fixtures, and metrics.
- [ ] The no-device PowerShell self-tests are split by concern and still run
  through `tools/test-sync-soak-harness.ps1`.
- [ ] Each helper module has at least one cheap no-device test where its logic
  can be tested without S21/S10/Supabase.
- [ ] The current accepted S21/S10 evidence gates still produce compatible
  artifacts after the decomposition.
- [ ] The 15-20 actor scale work can add actors by composing actor providers
  and flow/runtime helpers instead of growing a monolithic script.

## Lock-In Plan

Use soft enforcement first, then make it harder to regress once the initial
split is done.

- [ ] Add a `scripts/check_sync_soak_file_sizes.ps1` advisory script that
  reports line counts for:
  - `tools/*sync*soak*.ps1`;
  - `tools/sync-soak/**/*.ps1`;
  - `integration_test/sync/soak/**/*.dart`;
  - `test/harness/*soak*.dart`.
- [ ] Have the script mark files as:
  - `ok` under target;
  - `review` over 350 PowerShell lines or 400 Dart lines;
  - `blocked` over 500 PowerShell lines or 600 Dart lines unless listed in an
    exception file.
- [ ] Add a checked-in exception file, for example
  `tools/sync-soak/size-budget-exceptions.json`, with fields:
  `path`, `currentLines`, `budgetLines`, `reason`, `owner`, `expiresAfter`.
- [ ] Start the size script as a local/documented command and a non-blocking CI
  artifact.
- [ ] After the P0/P1 decomposition slices are complete, make `blocked` results
  fail CI for the sync-soak paths.
- [ ] Add a PR checklist item: any change adding more than 75 lines to a
  sync-soak file must explain why it belongs in that file instead of a helper.
- [ ] Add a CodeMunch-backed periodic audit step or local command to list
  newly oversized Dart symbols in `integration_test/sync/soak/` and
  `lib/core/driver/`.
- [ ] Keep PowerShell size enforcement filesystem-based because CodeMunch does
  not currently index the `.ps1` soak scripts as symbols in this repo.
- [ ] Add focused self-tests for every helper boundary before enforcing the
  line budget strictly.
- [ ] Treat a new god file as a failed architecture review even if tests pass.

## Decomposition Philosophy

- [ ] Decompose by responsibility, not by arbitrary line chunks.
- [ ] Keep high-level files readable as narratives: parse inputs, choose flow,
  call helpers, write summary, exit.
- [ ] Prefer named helpers around concepts that we test or discuss:
  actor, flow, mutation, sync, ledger, cleanup, artifact, storage proof,
  marker, failure classification.
- [ ] Avoid micro-functions that hide a three-line operation with no domain
  name or test value.
- [ ] Extract long conditional blocks when each branch maps to a domain concept
  or a reusable assertion.
- [ ] Extract pure functions first because they are cheap to test.
- [ ] Extract side-effect helpers second, behind narrow contracts that can be
  covered by no-device structural tests.
- [ ] Leave flow-specific business intent in the flow file so reviewers can
  still understand what the soak scenario proves.

## P0: Freeze Contracts Before Refactor

- [ ] Write down the current public PowerShell entrypoints and parameters:
  - `tools/enterprise-sync-soak-lab.ps1`
  - `tools/enterprise-sync-concurrent-soak.ps1`
  - `tools/test-sync-soak-harness.ps1`
  - every accepted `-Flow` value.
- [ ] Capture the current artifact contract from a representative accepted run:
  `summary.json`, `timeline.json`, `change-log-*.json`, `sync-runtime*.json`,
  screenshots, debug logs, mutation ledger, storage proof, result index.
- [ ] Add a contract section to the decomposition spec after the first
  implementation slice if any artifact field needs to be stabilized.
- [ ] Add a cheap structural self-test that asserts refactored module loading
  still exposes every accepted flow function.
- [ ] Add a cheap structural self-test that every accepted flow summary still
  includes `soakLayer`, `evidenceLayer`, `syncEngineExercised`,
  `directDriverSyncEndpointUsed`, queue counts, runtime/logging counts, and
  failure classifications.

## P0: Split The 1,922-Line Device Lab Script

- [ ] Create a shared module loader, for example
  `tools/sync-soak/ModuleLoader.ps1`, that dot-sources the refactored modules
  once and lets scripts avoid repeated import blocks.
- [ ] Move argument normalization and validation from
  `tools/enterprise-sync-soak-lab.ps1` into
  `tools/sync-soak/DeviceLab.Arguments.ps1`.
- [ ] Move `.env`/secret loading into `tools/sync-soak/Environment.ps1`.
- [ ] Move readable result-index export wrapper into
  `tools/sync-soak/ResultIndex.ps1`.
- [ ] Move refactored `-Flow` dispatch into
  `tools/sync-soak/DeviceLab.RefactoredDispatcher.ps1`.
- [ ] Move the remaining legacy device-lab implementation into an explicitly
  named quarantine file such as `tools/sync-soak/DeviceLab.Legacy.ps1`.
- [ ] Add a TODO banner to the legacy path stating it is not a substitute for
  refactored flow acceptance.
- [ ] After the split, keep `tools/enterprise-sync-soak-lab.ps1` under 250
  lines and make it read like a shell: validate, load env, dispatch, export,
  exit.
- [ ] Run `tools/test-sync-soak-harness.ps1` after the split.
- [ ] Run a `-PrintS10RegressionRunGuide` smoke after the split because that
  path currently exits before normal flow execution.

## P0: Extract Shared Flow Runtime

The large `Flow.*.ps1` files duplicate actor conversion, output directory
setup, preflight capture, round loops, event bookkeeping, failure handling,
final capture, summary aggregation, and pass/fail policy.

- [ ] Create `tools/sync-soak/FlowRuntime.ps1` for:
  - actor spec conversion;
  - output-root and actor-dir creation;
  - summary creation;
  - preflight evidence capture;
  - final evidence capture;
  - queue count aggregation;
  - common failure event shaping;
  - runtime/logging gap updates.
- [ ] Provide one generic runner function, for example
  `Invoke-SoakActorRoundFlow`, that accepts script blocks for:
  - preflight validation;
  - mutation;
  - sync;
  - post-sync assertions;
  - cleanup.
- [ ] Convert `Flow.SyncDashboard.ps1` first because it is smaller and proves
  the runtime seam without form or cleanup complexity.
- [ ] Convert `Flow.Quantity.ps1` second because it exercises local mutation,
  change-log proof, UI sync, cleanup, and final queue drain without storage.
- [ ] Convert `Flow.Photo.ps1` third because it adds storage proof.
- [ ] Convert form flows only after the basic runtime seam is stable.
- [ ] Keep every converted flow's public `Invoke-Soak<Flow>OnlyRun` signature
  backward compatible.
- [ ] Confirm converted flows still write the same summary/timeline/ledger
  artifact names.

## P0: Extract Common Mutation Target Helpers

- [ ] Create `tools/sync-soak/MutationTargets.ps1` for shared project, entry,
  location, bid item, photo, and form-response lookup helpers.
- [ ] Move duplicated local row query helpers out of contractor and daily-entry
  flows.
- [ ] Move change-log record matching and wait helpers into
  `tools/sync-soak/ChangeLogAssertions.ps1`.
- [ ] Replace per-flow `Get-SoakNew*ChangeLogRecordId` functions with one
  typed helper that accepts table, expected project/entry ids, and expected
  marker fields.
- [ ] Keep all target helpers fail-loud: no silent fallbacks to stale fixture
  ids when the local app state disagrees.

## P1: Extract Cleanup And Ledger Responsibilities

- [ ] Expand `tools/sync-soak/Cleanup.ps1` or split it into:
  - `MutationLedger.ps1`;
  - `CleanupDispatch.ps1`;
  - `RecordCleanupAssertions.ps1`.
- [ ] Move `Invoke-SoakQuantityLedgerCleanup`,
  `Invoke-SoakDailyEntryLedgerCleanup`,
  `Invoke-SoakPhotoLedgerCleanup`, and
  `Invoke-SoakContractorGraphLedgerCleanup` behind a shared cleanup interface.
- [ ] Move generic form-response cleanup out of
  `Flow.Mdot0582B.ps1` into shared form cleanup support.
- [ ] Keep the MDOT 1126 signature cleanup contract separate from generic form
  cleanup because it must prove `form_responses`, `signature_files`,
  `signature_audit_log`, and storage `remotePath` integrity together.
- [ ] Require every cleanup helper to record:
  - original row state;
  - cleanup mutation requested;
  - change-log row created;
  - UI cleanup sync observed;
  - local soft-delete/restore state;
  - remote soft-delete or storage absence.
- [ ] Keep cleanup-only replay compatible with existing mutation ledgers.

## P1: Extract Storage Proof

- [ ] Move storage auth, URI path conversion, HTTP status extraction, object
  proof, object deletion, and absence assertions out of `Flow.Photo.ps1`.
- [ ] Reuse the same storage proof helper for photo storage and signature
  storage.
- [ ] Remove the duplicate legacy storage proof implementation from
  `tools/enterprise-sync-soak-lab.ps1` after the legacy path is quarantined or
  converted.
- [ ] Make storage proof accept a typed object contract:
  bucket, remote path, min bytes, content hash when available, owning row id,
  and cleanup requirement.
- [ ] Fail closed when an expected storage `remotePath` is missing or mismatched.

## P1: Extract Form Flow Support

- [ ] Create `tools/sync-soak/FormFlow.ps1` for shared report-attached form
  creation, created-form route opening, form screen readiness, section open,
  visible text entry, and form-response id discovery.
- [ ] Create `tools/sync-soak/FormMarkers.ps1` for marker construction and
  marker assertion helpers.
- [ ] Keep form-specific marker definitions near each flow, but move generic
  traversal/assertion mechanics out of:
  - `Flow.Mdot1126Signature.ps1`;
  - `Flow.Mdot1126Expanded.ps1`;
  - `Flow.Mdot0582B.ps1`;
  - `Flow.Mdot1174R.ps1`.
- [ ] Extract MDOT 1126 shared support so signature-only and expanded-only do
  not duplicate form-open and cleanup setup.
- [ ] Do not broadly refactor `Flow.Mdot1174R.ps1` until either:
  - the S21 MDOT 1174R acceptance blocker is fixed; or
  - the refactor is directly targeted at reducing the row-section key/state
    failure surface.
- [ ] After form support extraction, rerun the currently accepted form gates
  before attempting new form coverage.

## P1: Split Artifact Writing And Failure Classification

- [ ] Split `tools/sync-soak/ArtifactWriter.ps1` into smaller helpers:
  - JSON writing;
  - ADB/logcat capture;
  - debug-server text/json capture;
  - runtime-error scanning;
  - runtime-error fingerprinting;
  - widget-tree classification;
  - evidence-bundle assembly.
- [ ] Move `Get-SoakFailureClassification` out of `SoakModels.ps1` if it keeps
  growing; classification belongs with evidence/failure policy, not summary
  models.
- [ ] Keep classifier tests in `tools/test-sync-soak-harness.ps1` or split
  them into `tools/sync-soak/tests/FailureClassification.Tests.ps1`.
- [ ] Add regression cases for the current MDOT 1174R failure family:
  duplicate `GlobalKey`, detached render object, red-screen widget tree,
  logging gap, queue residue, and widget visibility timeout.

## P1: Split The 998-Line Dart Soak Driver

Use CodeMunch outlines as the guide: `integration_test/sync/soak/soak_driver.dart`
currently owns models, action mix, runner, backend/RLS executor, driver-app
executor, fixture personas, actor reports, and serialization.

- [ ] Create `integration_test/sync/soak/soak_action_mix.dart` for
  `SoakActionKind`, `SoakActionMix`, and action selection.
- [ ] Create `integration_test/sync/soak/soak_models.dart` for
  `SoakLayer`, `SoakActionContext`, `SoakResult`, `SoakActorReport`, and
  serialization helpers.
- [ ] Create `integration_test/sync/soak/soak_runner.dart` for the
  `SoakDriver` concurrency loop and sampling cadence.
- [ ] Create `integration_test/sync/soak/soak_executors.dart` for the
  `SoakActionExecutor` interface plus `NoopSoakActionExecutor`.
- [ ] Create `integration_test/sync/soak/driver_soak_action_executor.dart`
  for driver-app actions.
- [ ] Create `integration_test/sync/soak/backend_rls_soak_action_executor.dart`
  for direct Supabase backend/RLS actions.
- [ ] Create `integration_test/sync/soak/soak_personas.dart` for harness
  emails/user ids used by 15-20 virtual backend actors.
- [ ] Extract role-assignment churn and project-scope assertions into a helper
  owned by the backend/RLS executor.
- [ ] Preserve current factories by leaving a small compatibility facade in
  `soak_driver.dart` or updating all imports in one commit.
- [ ] Keep the tests in `test/harness/soak_driver_test.dart`,
  `test/harness/soak_ci_10min_test.dart`, and
  `test/harness/soak_nightly_15min_test.dart` green after each Dart split.

## P1: Split Harness Self-Tests

- [ ] Convert `tools/test-sync-soak-harness.ps1` from a 434-line all-in-one
  file into a small runner plus focused test files under
  `tools/sync-soak/tests/`.
- [ ] Suggested test files:
  - `RuntimeErrorClassification.Tests.ps1`;
  - `Sentinels.Tests.ps1`;
  - `CleanupLedger.Tests.ps1`;
  - `S10RegressionGuide.Tests.ps1`;
  - `FlowWiring.Tests.ps1`;
  - `MdotSignatureCleanup.Tests.ps1`;
  - `FormFlowWiring.Tests.ps1`.
- [ ] Keep `tools/test-sync-soak-harness.ps1` as the stable public command that
  loads and runs those focused tests.
- [ ] Ensure the self-test runner does not need a driver, device, or Supabase.

## P2: Normalize Flow Module Boundaries

- [ ] Set a soft target of under 350 lines for any `Flow.*.ps1` file.
- [ ] If a flow exceeds 350 lines after shared runtime extraction, split by
  responsibility:
  - `Flow.<Name>.Markers.ps1`;
  - `Flow.<Name>.Actions.ps1`;
  - `Flow.<Name>.Assertions.ps1`;
  - `Flow.<Name>.Cleanup.ps1`.
- [ ] Keep each public flow file as a readable entrypoint that imports its
  helpers and exposes one `Invoke-Soak<Name>OnlyRun`.
- [ ] Add a local check that prints files over the agreed line threshold for
  `tools/sync-soak/`, `tools/*sync*soak*.ps1`, and
  `integration_test/sync/soak/`.
- [ ] Do not fail CI on the threshold until the initial decomposition queue is
  complete; start as an advisory report.

## P2: Clean Up Legacy Paths

- [ ] Decide whether the legacy `-Flow legacy` path in
  `tools/enterprise-sync-soak-lab.ps1` is still needed.
- [ ] If needed, move it into `DeviceLab.Legacy.ps1` and label its artifacts
  `legacy_device_lab_non_acceptance` unless it uses the same acceptance
  discipline as refactored flows.
- [ ] If not needed, remove the legacy path after:
  - S21 accepted refactored flows cover daily entry, quantity, photo,
    contractors, MDOT 1126, MDOT 0582B, and MDOT 1174R;
  - S10 refactored regression guide covers the accepted subset;
  - cleanup-only replay works for accepted ledgers.
- [ ] Remove duplicate helper implementations from the legacy path once the
  shared modules cover them.

## P2: Prepare For 15-20 Actor Scale

- [ ] Introduce an explicit actor model that distinguishes:
  - real device actors;
  - emulator actors;
  - headless app-sync actors;
  - backend/RLS virtual actors.
- [ ] Keep backend/RLS virtual actors out of device-sync pass/fail accounting.
- [ ] Move actor scheduling/ramp-up policy out of individual flow files.
- [ ] Add per-actor fixture/session ownership helpers so headless app-sync
  actors can have isolated local stores and real sessions.
- [ ] Add a scale manifest that records actor type, auth user, project scope,
  local store path, driver port when applicable, and evidence layer.
- [ ] Add one parent orchestration helper that can run:
  - S21;
  - S10;
  - optional emulator;
  - headless app-sync actors;
  - backend/RLS pressure actors.
- [ ] Keep the final 15-20 actor claim blocked until headless app-sync actors
  exercise the actual sync engine and isolated local storage.

## P2: Decompose Adjacent Driver Support Only If Needed

The app-side driver server has already been split substantially. Do not churn it
while MDOT 1174R is blocked unless a soak decomposition slice needs a cleaner
driver contract.

- [ ] Keep `lib/core/driver/driver_server.dart` as a thin dispatch shell.
- [ ] Review `lib/core/driver/screen_contract_registry.dart` separately if it
  keeps growing; it is 705 lines and registry-shaped, not a soak runner.
- [ ] Review `lib/core/driver/harness_seed_data.dart` separately if fixture
  setup starts blocking headless actor scale; it is 584 lines.
- [ ] Keep driver endpoints production-like and avoid test-only lifecycle hooks.

## P3: Decompose Adjacent Sync Engine Tests Separately

The repo-wide sweep found large sync tests that are not sync-soak orchestration
files. Track them separately after the soak harness decomposition is underway.

- [ ] Create a separate sync-engine test decomposition checklist for:
  - `test/features/sync/engine/sync_engine_test.dart`;
  - `test/features/sync/engine/cascade_soft_delete_test.dart`;
  - `test/features/sync/engine/pull_handler_test.dart`;
  - `test/features/sync/engine/file_sync_handler_test.dart`;
  - `test/features/sync/engine/integrity_checker_test.dart`.
- [ ] Prefer fixture builders and scenario helpers over huge inline test setup.
- [ ] Do not mix this test cleanup into the device-soak harness refactor unless
  a shared fixture helper is clearly needed by both.

## Suggested Implementation Order

1. [ ] Split `tools/enterprise-sync-soak-lab.ps1` into loader, args/env,
   refactored dispatcher, result-index wrapper, and quarantined legacy module.
2. [ ] Extract shared flow runtime using `Flow.SyncDashboard.ps1` and
   `Flow.Quantity.ps1` as the first proving slices.
3. [ ] Extract mutation target and change-log helpers across daily entry,
   quantity, photo, and contractors.
4. [ ] Extract cleanup/ledger helpers while preserving cleanup-only replay.
5. [ ] Extract storage proof and reuse it for photos and signatures.
6. [ ] Extract form-flow helpers, then reduce MDOT 1126 signature/expanded and
   MDOT 0582B duplication.
7. [ ] Fix/accept MDOT 1174R if still blocked, then reduce the 1174R flow with
   the now-stable form helpers.
8. [ ] Split `integration_test/sync/soak/soak_driver.dart` into Dart model,
   runner, executor, persona, and serialization files.
9. [ ] Split the PowerShell self-test runner into focused no-device tests.
10. [ ] Add advisory line-count reporting for the soak system.
11. [ ] Revisit legacy removal and 15-20 actor scale orchestration.

## Acceptance Gates

- [ ] `tools/test-sync-soak-harness.ps1` passes after each PowerShell slice.
- [ ] `dart test test/harness/soak_driver_test.dart` or the repo's approved
  wrapper equivalent passes after each Dart soak-driver split.
- [ ] No accepted flow loses required artifact fields.
- [ ] No accepted flow starts using direct `/driver/sync` as acceptance proof.
- [ ] Backend/RLS and device-sync summaries remain separately labeled.
- [ ] The next S21 accepted flow attempted after each behavioral extraction has
  `runtimeErrors=0`, `loggingGaps=0`, final queue drained, and no direct driver
  sync acceptance.
- [ ] The decomposition log records every file moved, every public function
  preserved, and every verification command/artifact.
