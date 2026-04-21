# Four-Role Sync Hardening Scale-Up Spec

Date: 2026-04-19
Status: active controlling spec for remaining four-role sync hardening
Checkpoint: `.codex/checkpoints/2026-04-19-four-role-sync-hardening-scale-up-checkpoint.md`

## Purpose

This is the single active source for the remaining four-role sync hardening
work after the sync-soak decomposition/state-machine specs were implemented
and the router red-screen detour was closed with accepted device evidence.

The goal is to scale Field Guide from accepted single-flow and role-account
proofs into realistic concurrent use: four approved roles, real sessions,
real SQLite stores, real Supabase/RLS/storage behavior, concurrent
writes/reads, fault windows, quiescence, performance measurement, and
repeatable artifacts that can block future sync-touching changes.

Older specs, task lists, implementation logs, and result indexes remain audit
inputs only. Continue active work here and in the checkpoint above.

## Explicitly Out Of Scope

- The codebase hygiene spec is not in scope.
- No `MOCK_AUTH`.
- No accepting direct `POST /driver/sync` as sync proof.
- No live admin deactivation/revocation as a beta readiness gate.
- No PowerSync or other sync-engine migration before the current custom engine
  hardening gates are complete.
- No backend/RLS-only success may satisfy device-sync or app-sync acceptance.

## Audit Inputs Reviewed

- `.codex/AGENTS.md`
- `.codex/Context Summary.md`
- `.codex/PLAN.md`
- `.codex/CLAUDE_CONTEXT_BRIDGE.md`
- `.claude/rules/sync/sync-patterns.md`
- `.codex/role-permission-matrix.md`
- `.claude/specs/2026-04-16-sync-system-hardening-and-harness-spec.md`
- `.claude/plans/2026-04-16-sync-system-hardening-and-harness.md`
- `.codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`
- `.codex/plans/2026-04-18-sync-engine-external-hardening-todo.md`
- `.codex/plans/2026-04-18-mdot-1126-typed-signature-sync-soak-plan.md`
- `.codex/plans/2026-04-18-sync-soak-decomposition-todo-spec.md`
- `.codex/plans/2026-04-19-sync-soak-decomposition-state-machine-refactor-spec.md`
- `.codex/plans/2026-04-19-sync-soak-driver-decomposition-todo-spec.md`
- `.codex/plans/2026-04-19-sync-soak-periodic-codemunch-audit-plan.md`
- `.codex/plans/completed/2026-04-17-enterprise-sync-soak-hardening-spec.md`
- `.codex/plans/completed/2026-04-17-sync-soak-ui-rls-implementation-todo.md`
- `.codex/plans/completed/2026-04-17-sync-system-hardening-remaining-work.md`
- `.codex/plans/completed/2026-04-18-sync-soak-spec-audit-agent-task-list.md`
- `.codex/checkpoints/Checkpoint.md`
- `.codex/checkpoints/2026-04-18-sync-soak-unified-implementation-log.md`
  - 5068 lines, reviewed by headings, first/last slices, accepted/rejected
    run sections, and open-next extraction.
- `.codex/checkpoints/2026-04-18-sync-soak-unified-live-task-list.md`
  - 2054 lines, reviewed by open checkbox extraction and stale-vs-latest
    reconciliation.
- `.codex/checkpoints/2026-04-17-sync-soak-implementation-checkpoints.md`
- `.codex/checkpoints/2026-04-19-sync-soak-driver-decomposition-progress.md`
- `.codex/checkpoints/2026-04-19-sync-soak-decomposition-state-machine-progress.md`
- `.codex/research/2026-04-17-sync-soak-gap-research.md`
- `.codex/reports/2026-04-18-enterprise-sync-soak-result-index.md`
- `.codex/reports/2026-04-18-all-test-results-result-index.md`

The 2026-04-19 codebase hygiene refactor spec was intentionally excluded.

## Current Accepted Evidence

Structural and harness lock-in:

- The 2026-04-19 decomposition/state-machine ED/ES matrix is closed in
  `.codex/checkpoints/Checkpoint.md`.
- `SoakActorProvisioner` has backend/RLS, device-sync, and headless-app-sync
  implementations.
- `DeviceStateSnapshot`, `DevicePosture`, state-machine orchestration,
  log assertions, timeline artifacts, generated testing keys, raw-key lint,
  size-budget gate, and sync-soak harness CI lock-in exist.
- Latest local gates in the closeout audit passed:
  - `dart analyze lib integration_test test\harness test\core\driver`
  - `dart run custom_lint`
  - `scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked`
  - `tools/test-sync-soak-harness.ps1`
  - `tools/gen-keys/verify-idempotent.ps1`
  - targeted harness/driver/router/app Flutter tests

Accepted device/app-sync evidence:

- ES-2 physical role-account run:
  `20260419-s21-s10-es2-after-android-surface-false-positive-fix`.
- Honest four-role account-switch run:
  `20260419-four-role-after-app-lock-disabled-root-builder-and-surface-classifier-fix`.
- S10 inspector to S21 office-technician accepted seams:
  daily entry/review, quantity, document/storage, photo/storage/local-cache
  visual gate, and MDOT 0582B form.
- Real non-admin RLS denial probes accepted:
  `rls-denial-probes-20260419T0935Z`.
- Headless app-sync local proof accepted:
  12 virtual users, 6 concurrent workers, four real role personas, isolated
  local SQLite stores, real sessions, real `SyncEngine`, 174/174 actions,
  zero failures/errors/RLS denials.
- Headless app-sync scale proof accepted:
  `build/soak/headless-app-sync-summary-2026-04-20T002539165336Z.json`,
  20 virtual users, 8 concurrent workers, isolated local SQLite stores, real
  sessions, real `SyncEngine`, 386/386 actions, zero failures/errors/RLS
  denials, checker passed.
- Local backend/headless full round-trip proof accepted:
  `build/soak/enterprise-headless-backend-full-roundtrip-20260419-204912/manifest.json`.
  Backend/RLS pressure ran 7,390 direct Supabase/RLS actions with zero
  failures/errors while 12 headless app-sync actors used real `SyncEngine`
  sessions and isolated SQLite stores. The run stamped four backend markers,
  proved 45 backend-to-local SQLite marker checks across 12 actors, and proved
  app A local write -> backend -> app B local read convergence via
  `headless-app-to-app-convergence-proof.json`.
- Backend/RLS direct pressure was previously green, but it remains a separate
  evidence layer and does not prove device sync.
- First mixed four-lane local overlay accepted:
  `build/soak/codex-four-lane-sync-overlay-smoke-20260419-185214/manifest.json`.
  The run used S21 admin, physical tablet inspector, emulator engineer, and
  emulator office-technician lanes while backend/RLS and headless app-sync
  pressure ran in parallel. All three evidence layers passed independently.
  A readable summary is available at
  `build/soak/codex-four-lane-sync-overlay-smoke-20260419-185214/codex-four-lane-sync-overlay-smoke-20260419-185214-enterprise-summary.md`.

Accepted form/file evidence already folded into the baseline:

- MDOT 1126 typed signature, expanded rows, export proof, and gallery
  lifecycle.
- MDOT 0582B mutation/export/lifecycle proof.
- MDOT 1174R mutation/export/lifecycle proof after the red-screen/key-state
  failure class was closed.
- Entry documents, photos, signatures, and local-only export families have
  storage or adapter-contract proof appropriate to their current sync contract.

## Current Open Scope

Open work is now scale and hardening, not structural decomposition:

- Four-role account switching is accepted as a stale-scope safety check only;
  it is not a scale-hardening workload. Four-role concurrent write/read stress
  is the active acceptance target.
- The latest mixed four-lane overlay is still rejected as device UI evidence.
  Backend/RLS, headless app-sync, backend-to-device marker preflight, and
  backend-to-headless marker proof all passed in
  `enterprise-four-lane-routerfix-live-20260419-211738`, but the device layer
  failed at `driver_preflight` with the GoRouter duplicate
  `GlobalObjectKey` / `InheritedGoRouter` red-screen class before UI mutation
  lanes started.
- The narrow backend-to-device marker contract and same-fixture preflight are
  implemented and same-backend preflight now passes against local harness
  Supabase. It is not accepted as full coupled pressure yet because the UI
  actors failed before they could pull those markers into local SQLite.
  Same-backend setup plumbing exists in
  `tools/start-local-harness-driver-lab.ps1`, `tools/env-utils.ps1`, and
  `SOAK_ROLE_ACCOUNT_SOURCE=local_seed`; the remaining work is to rebuild/
  relaunch the devices after the restored router guardrail and rerun the
  four-lane marker smoke.
- S10/S21 physical role seams cover major inspector to office-technician
  paths, but the full role matrix still needs broader admin/engineer/office/
  inspector permission and visibility coverage during active writes.
- Headless app-sync has a 12-actor local proof, but not a full 15-20 actor
  workload with operation history, checkers, fault windows, and UI actors
  layered on top.
- Backend/RLS pressure has not yet been run concurrently with device/app-sync
  actors while keeping evidence layers separate for device UI. Backend/RLS
  plus headless app-sync is now accepted locally with full round-trip marker
  proof; S21/S10/two-emulator UI overlay remains blocked by the separate
  GoRouter duplicate-key/red-screen device defect until rebuilt and rerun.
- Staging credentials, schema/policy parity, staging performance, green-run
  history, Sentry/log-drain proof, and auto-issue proof remain external
  release gates.
- Production/staging operational alerts remain open, especially stale
  `sync_hint_subscriptions`.
- `docs/sync-consistency-contract.md` remains open.

## Enterprise-Scale Target Checklist

This is the active scale-up checklist for moving from the current S21/S10 and
15-actor local proofs toward enterprise-level testing. Check items here only
when the checkpoint records the exact command, artifact path, and pass/fail
summary.

### E0 - Baseline And Durable Scope

- [x] Refresh this spec and the active checkpoint with the enterprise-scale
  device/project/checker checklist.
- [x] Confirm local prerequisites before every scale run:
  Docker/Supabase local stack, role account secrets, connected Android
  devices, emulator serials, clean app installs where required, and current
  git SHA.
- [x] Preserve the codebase hygiene spec as out of scope.

### E1 - Device And Role Topology

- [ ] Confirm the physical devices with `adb devices`:
  S21 and S10 must both be visible and automation-ready.
- [x] Confirm two Android emulators can run the debug app at the same time as
  the physical devices without port or driver-server collisions.
- [x] Define the first four-lane mapping:
  S21 admin, physical inspector lane, emulator engineer, emulator office
  technician.
- [x] Assign one primary synced project per device/emulator for independent
  write pressure, then add shared cross-project visibility/reconciliation
  checks.
- [x] Record actor context for every lane:
  device serial, driver port, role, user id, company id, selected project,
  schema version, app build, queue/conflict state, and sync-hint state.

Current accepted physical inspector fallback is the tablet on port `4949`
because the S10 serial was not visible during the 2026-04-19 run. Re-run the
same preset with the S10 actor once the S10 is connected.

### E2 - Parent Orchestrator Evidence Layers

- [x] Extend the parent enterprise orchestrator so a single run can launch and
  preserve three child evidence layers:
  backend/RLS pressure, headless app-sync pressure, and device UI sync.
- [x] Keep the summary tree separated by evidence layer. Backend/RLS success
  must never satisfy app-sync or device UI acceptance.
- [x] Add parent manifest timing:
  backend start/end, headless start/end, device start/end, overlap windows,
  and whether any layer finished before another layer started.
- [x] Add headless app-sync parameters to the parent orchestrator:
  enable/disable, duration, user count, concurrency, action delay, and action
  weights.
- [x] Preserve latest and timestamped child summaries for every layer.
- [x] Add a readable enterprise parent summary over manifest plus child
  summaries.

### E3 - Fixture And Project Scale

- [x] Start with three to four projects:
  one primary project per physical device/emulator lane.
- [x] Ensure every role account has the expected assignment or visibility for
  those projects according to `.codex/role-permission-matrix.md`.
- [x] Seed realistic records for daily entries, quantities, photos/documents,
  MDOT forms, signatures, assignments, trash, and storage-backed rows.
- [ ] Scale the deterministic fixture toward 15 projects before the final
  15-20 actor acceptance run.
- [x] Stamp fixture version/hash into every parent and child artifact.

### E4 - Local Mixed-Layer Proofs

- [x] Run a parent smoke with backend/RLS plus headless app-sync only to prove
  manifest separation without device complexity.
- [ ] Run S21 and S10 UI traffic over backend/RLS plus headless app-sync
  pressure.
- [x] Add the two emulator lanes after the S21/S10 mixed proof is repeatable.
- [x] Run four-lane UI traffic while backend and headless actors continue in
  parallel.
- [x] Accept only if all layers pass their own gates and final reconciliation
  is clean.
- [ ] Replace the current orchestration-only four-lane smoke with a coupled
  pressure proof:
  backend/RLS must stamp deterministic markers into project-scoped rows while
  device actors are syncing, and each device lane must prove those markers
  arrived in its local SQLite store.
- [x] Gate coupled marker runs with a same-fixture preflight:
  before backend/headless pressure starts, each device's own authenticated
  Supabase session must prove it can see the exact project and daily-entry row
  that the backend marker writer will mutate.
- [ ] Make device lanes run concurrently, not as a sequential actor loop, for
  scale profiles above `smoke`.
- [ ] Run concurrent device lanes with real UI mutation flows. The initial
  accepted shape must launch one write flow per device/emulator in parallel,
  not `role-account-switch-only` and not marker-only `sync-only`.
- [x] Add backend-to-headless bidirectional impact:
  backend/RLS markers must be stamped while backend pressure is active, every
  headless SyncEngine actor must pull visible markers into its own local
  SQLite store, and one app actor local write must converge through the backend
  into a second app actor's local SQLite store.
- [ ] Add device/UI bidirectional impact:
  device UI writes must be observed by backend/checkers while backend/headless
  pressure is still active, and backend writes must be observed by devices
  before quiescence is accepted.

The completed four-lane proof used the physical tablet as the inspector lane;
the S21/S10-specific mixed proof remains open until the S10 is visible.

### E5 - Role And Visibility Checkers

- [ ] Add read-only checker phases for role/project visibility during active
  writes and after quiescence.
- [ ] Prove inspector denial for project setup, assignments, bid-item
  management, restricted pay-app/PDF import, and admin-only surfaces.
- [ ] Prove engineer and office technician denial for admin-only member and
  company surfaces.
- [ ] Prove Trash is current-user scoped for all approved roles.
- [ ] Prove no unauthorized project metadata flashes during refresh, sync,
  account switch, route changes, or active writes.

### E6 - Sync, Storage, And Quiescence Checkers

- [ ] Add or reuse checkers for acknowledged-write convergence.
- [ ] Check blocked/unprocessed rows, retry counts, conflicts, and sync locks.
- [ ] Check storage row/object consistency for photos, documents, and
  signature/form export paths.
- [ ] Add a quiescence phase:
  stop writes, heal faults, wait for queue zero, blocked zero, conflict zero,
  download idle, realtime/fallback settled, and reconciliation hashes matched.
- [ ] Persist checker output in the parent manifest and in layer-specific
  summaries.

### E7 - 15-20 Actor Scale

- [ ] Add a named scale profile knob to the parent/preset scripts:
  `smoke`, `baseline`, `pressure`, and `enterprise`, with explicit overrides
  still allowed. The resolved values must be written to the parent manifest
  and readable summary.
- [ ] Increase headless app-sync from the current short 15-actor proof to a
  longer 15-20 actor run with operation history, checker output, and replay
  metadata.
- [ ] Keep one virtual app actor serialized against its own local SQLite
  store, while allowing cross-actor concurrency.
- [ ] Run device UI actors concurrently with headless app-sync actors.
- [x] Run backend/RLS direct pressure concurrently with app-sync actors, but
  report it as backend-only evidence. Accepted local proof:
  `enterprise-headless-backend-full-roundtrip-20260419-204912`.
- [x] Run backend/RLS direct pressure concurrently with device UI actors, but
  report it as backend-only evidence. Latest evidence:
  `enterprise-four-lane-routerfix-live-20260419-211738` kept backend/RLS,
  headless app-sync, and marker proof separate while rejecting device UI.

### E8 - Fault Windows And Liveness

- [ ] Add offline/reconnect windows.
- [ ] Add background/foreground lifecycle windows.
- [ ] Add auth-refresh and expected non-admin denial windows.
- [ ] Add storage transient failure windows.
- [ ] Add realtime hint loss, duplicate, and fallback windows.
- [ ] Enforce liveness thresholds:
  row data p95 sync-to-visible-local <= 2 minutes, file-backed p95 object
  availability <= 5 minutes, post-fault quiescence <= 10 minutes.

### E9 - Performance, Staging, And Operational Gates

- [ ] Capture p50/p95/p99 convergence timing and storage availability timing.
- [ ] Compare local performance against `scripts/perf_baseline.json`.
- [ ] Run the same shape against staging or staging-equivalent credentials.
- [ ] Collect three consecutive green full-system staging or
  staging-equivalent runs at the same commit.
- [ ] Complete `docs/sync-consistency-contract.md`.
- [ ] Complete the operational diagnostics and alert checklist, including
  stale `sync_hint_subscriptions`.

## Role Policy

Use `.codex/role-permission-matrix.md` as controlling policy.

- Admin owns company/member/admin surfaces and can manage all projects/data.
- Engineer and office technician are project/data peers.
- Inspector can write assigned field data but cannot manage/delete projects.
- Trash is user-scoped for every approved user, not admin-only.

Do not test office technician as a restricted reviewer.

## Acceptance Rules For Every Run

Every accepted device or app-sync hardening artifact must prove:

- real sessions, no `MOCK_AUTH`;
- refactored flow/state-machine path, not legacy all-modes;
- no direct `/driver/sync`;
- UI-triggered Sync Dashboard sync for UI/device actors;
- isolated local SQLite store for every app/headless actor;
- actor context includes user id, role, company id, membership, selected
  project/provider scope, realtime or sync-hint state, queue/conflict state,
  app build, and schema version;
- `runtimeErrors=0`;
- `loggingGaps=0`;
- `queueDrainResult=drained`;
- `blockedRowCount=0`;
- `unprocessedRowCount=0`;
- `maxRetryCount=0`;
- `undismissedConflictCount=0`;
- no unauthorized project metadata, route/control flashes, storage previews,
  or stale selected-project/provider scope;
- screenshots, widget tree, debug-server logs, ADB logcat, Android surface
  evidence, and sync state show no UI/layout/runtime/sync defect;
- operation history or mutation ledger identifies each write and cleanup
  obligation;
- local/remote reconciliation and storage row/object consistency pass for the
  covered tables/objects;
- failed attempts preserve first-failure artifacts and are not reclassified as
  accepted evidence later.

## Implementation Queue

### P0 - Canonicalize This Lane

- [x] Audit active and completed sync-hardening specs/todos/checkpoints.
- [x] Exclude the codebase hygiene spec.
- [x] Reconcile stale open items against latest accepted evidence.
- [x] Create this single active spec.
- [x] Create the matching single active checkpoint.
- [x] Keep `.codex/PLAN.md` pointing at this spec/checkpoint as the current
  continuation source.

### P1 - Four-Role Concurrent Role Traffic

- [ ] Run a new four-role concurrent traffic design pass against the existing
  harness commands and current scripts.
- [x] Remove role-account switching from the scale-up execution path. It can
  remain a stale-auth regression flow, but enterprise hardening must exercise
  concurrent real writes/reads by distinct signed-in personas.
- [x] Add setup-only persona readiness for local-harness lanes. If a lane is
  logged out, it may sign in once as its assigned seeded user; if it is signed
  in as the wrong role, the setup fails instead of switching accounts.
- [x] Add a concurrent device-lane runner that launches an existing refactored
  UI mutation flow per actor in parallel and optionally follows each lane with
  a backend-marker Sync Dashboard proof.
- [ ] Define the first mixed UI workload:
  - S21 admin;
  - S10 inspector;
  - emulator engineer;
  - emulator office technician;
  - disposable soak project;
  - concurrent read/write phases with explicit quiescence.
- [ ] Include field-data writes:
  - daily entry;
  - quantity;
  - photo;
  - document;
  - MDOT form response;
  - signature or form-signature path where available.
- [ ] Include review/project-data peers:
  - office technician review/edit where product policy allows;
  - engineer project/data peer reads and allowed management actions;
  - admin company/member/admin read checks without live deactivation.
- [ ] Include denied/hidden checks:
  - inspector denied project setup, assignments, bid-item management,
    restricted pay-app/PDF import, and admin-only surfaces;
  - office technician and engineer denied admin-only member/company surfaces;
  - all roles see only current-user Trash rows.
- [ ] Prove no role sees unauthorized metadata in any frame during refresh,
  sync, account switch, or active writes.
- [ ] Accept only with clean actor context, UI evidence, queues/conflicts,
  storage proof, and reconciliation output.

### P1 - Operation History And Checkers

- [ ] Add or identify a seedable operation scheduler for mixed role/app-sync
  workloads.
- [x] Record operation history for every generated action at the current Dart
  soak-driver level:
  action, iteration, virtual user, start/end time, result, latency,
  burst-window state, and classified failure details are now emitted.
  Executor-specific enrichment for actor, device/session, user, role, project,
  table/object family, record id, and expected invariant impact remains open
  with the checker work below.
- [x] Enrich operation history for headless app-sync scale acceptance:
  actor kind/index, user, role, company, project scope, project,
  table/object family, record id, result timing, and expected invariant impact
  are now captured where the headless executor can identify them.
- [ ] Extend enriched operation history to UI-driver and backend/RLS executors:
  device/session, selected project/provider scope, backend evidence layer, and
  action-specific table/object intent.
- [ ] Add read-only checker actors or checker phases.
- [x] Add Dart result-level invariant checker output for every soak result:
  operation-history completeness, count consistency, per-actor totals,
  failure/denial zero checks, timestamp/latency sanity, all-or-none operation
  intent capture, and evidence-layer sync-engine honesty are emitted under
  `checkerOutput`.
- [ ] Implement invariant checks:
  - no lost acknowledged writes;
  - no unauthorized role visibility;
  - local/remote convergence after quiescence;
  - no blocked/unprocessed rows;
  - no unexpected conflict rows;
  - storage row/object consistency;
  - no stale auth/project scope after account switching.
- [x] Save replay seed/config/schedule metadata for every Dart soak result:
  `replayMetadata` now carries the random seed when known, action weights,
  run configuration, operation schedule, and failing schedule.
- [x] Preserve timestamped headless app-sync summary artifacts in addition to
  `build/soak/headless-app-sync-summary.json` so later reruns do not overwrite
  the only copy of a failing schedule.

### P1 - Headless App-Sync Scale-Up

- [ ] Expand deterministic fixture toward 15 projects.
- [ ] Include realistic records and binary/export artifacts.
- [ ] Decide whether the next proof uses four beta accounts fanned into
  15-20 isolated app actors or a staging/local unique-identity fixture.
- [x] Run 15-20 headless app-sync actors with real sessions, isolated SQLite
  stores, real `SyncEngine`, operation history, and checker output.
- [x] Run a short local 15-actor/8-worker headless app-sync proof with real
  sessions, isolated SQLite stores, real `SyncEngine`, operation history,
  checker output, and replay metadata:
  94/94 actions succeeded, errors/RLS denials/failing schedule all zero.
- [ ] Layer S21/S10 UI actors over headless app-sync pressure without counting
  headless pressure as UI proof.
- [ ] Keep backend/RLS actors separate from headless app-sync actors in the
  summary and artifact tree.

### P1 - Backend/Device Overlap

- [x] Run backend/RLS pressure concurrently with a refactored device or
  app-sync flow.
- [x] Preserve child summaries by evidence layer:
  backend/RLS direct Supabase pressure, real-device UI sync, headless
  app-sync, and final checker/reconciliation.
- [x] Stamp fixture version/hash into every artifact.
- [x] Do not let backend/RLS success satisfy device/app-sync acceptance.
  `enterprise-four-lane-routerfix-live-20260419-211738` passed backend and
  headless layers but stayed red because device UI failed preflight.

### P2 - Fault Injection And Liveness

- [ ] Add offline burst replay.
- [ ] Add long-offline replay.
- [ ] Add network fault windows:
  full disconnect, outbound-only if practical, inbound-only if practical.
- [ ] Add auth failure windows:
  401/auth refresh, 403/RLS denial, revoked assignment during offline window
  as a non-beta lane, and stale session recovery.
- [ ] Add storage failure windows:
  409 conflict, timeout, rate-limit-like transient failure, cleanup delete
  failure.
- [ ] Add app lifecycle faults:
  pause/resume, background/foreground, process kill/restart while preserving
  SQLite files.
- [ ] Add realtime/fallback faults:
  missed hint, duplicate hint, out-of-order hint, dirty-scope overflow.
- [ ] Add explicit quiescence:
  stop writes, heal faults, wait for queue zero, blocked zero, sync/download
  idle, realtime/fallback settled, and reconciliation hashes matched.
- [ ] Define and enforce liveness thresholds:
  row data p95 sync-to-visible-local <= 2 minutes, file-backed p95 object
  availability <= 5 minutes, post-fault quiescence <= 10 minutes.

### P2 - Performance And Benchmarking

- [ ] Run local performance proof after fixture expansion.
- [ ] Run staging performance proof with staging credentials.
- [ ] Keep cold full sync <= 2000 ms on the seeded fixture.
- [ ] Keep warm foreground unblock <= 500 ms.
- [ ] Wire or verify performance regression gate against
  `scripts/perf_baseline.json`.
- [ ] Record p50/p95/p99 convergence and file-object availability where the
  harness can measure them.

### P2 - Staging And Release Gates

- [ ] Provision staging-only harness credentials.
- [ ] Prove staging schema hash parity.
- [ ] Prove staging RLS and storage policy parity.
- [ ] Run staging sign-in smoke.
- [ ] Run 10-minute staging CI soak.
- [ ] Run 15-minute staging nightly soak.
- [ ] Collect three consecutive green full-system staging or
  staging-equivalent sync-soak runs.
- [ ] Run a test PR through persistent gates and preserve links/artifacts.
- [ ] Do not tag pre-alpha-eligible until correctness matrix, staging soak,
  performance, observability, and auto-issue gates are all true at the same
  commit.

### P2 - Operational Diagnostics And Alerts

- [ ] Define/persist the sync diagnostics contract:
  connected/connecting, uploading, downloading, first-sync complete,
  last sync timestamp, queue count, blocked count, retry count, active user,
  company, project, app version, schema version, and sync run id.
- [ ] Add staging/backend alerts for:
  blocked queue rows, rising retry counts, stale sync locks, stale
  `pulling=1`, stale last sync, repeated reconciliation mismatch, storage
  cleanup backlog, per-device sync timeout, Supabase/Postgres/storage errors,
  RLS denials, backend log-drain failures, and stale
  `sync_hint_subscriptions`.
- [ ] Prove Supabase Log Drains into Sentry for `postgres_logs`, `auth_logs`,
  and `edge_logs`.
- [ ] Prove Sentry to GitHub repository dispatch/auto-issue behavior with
  hashed user identifiers.
- [ ] Define retention/compaction for `change_log`, `conflict_log`, debug
  logs, repair audit rows, storage cleanup queue, and operation histories.

### P2 - Consistency Contract Docs

- [ ] Write `docs/sync-consistency-contract.md`.
- [ ] Document guarantees and non-guarantees:
  local acknowledged writes, remote acknowledged writes, eventual convergence,
  conflict policy, immutable/audit tables, file object semantics, storage
  cleanup, role revocation, realtime hints, and recovery responsibilities.
- [ ] Document per-table sync/conflict semantics:
  scope type, insert/update/delete behavior, soft-delete support, file
  behavior, conflict strategy, LWW allowance, natural-key remap behavior, and
  required soak coverage.
- [ ] Add a new synced table checklist:
  adapter metadata, SQLite triggers, Supabase table/RLS/storage policies,
  migration/rollback, fixture data, characterization tests, device-soak
  mutation or exemption, and reconciliation probe membership.
- [ ] Keep `docs/sync-scale-hardening-playbook.md` updated as checkers and
  fault gates land.

### P3 - Optional Post-Gate Sync Vendor Spike

- [ ] Only after current staging/device gates are green, evaluate a short
  PowerSync spike in a throwaway branch.
- [ ] Treat the likely path as pattern adoption only unless the spike proves
  concrete code and risk reduction without a second sync truth.

## First Implementation Order

1. Update `.codex/PLAN.md` so this spec and checkpoint are the continuation
   source.
2. Inventory current run scripts and harness entrypoints for:
   four-role UI, headless app-sync, backend/RLS pressure, local performance,
   staging performance, and nightly soak.
3. Implement the smallest missing artifact primitive for the next scale step:
   operation history/checker output if absent, or a wrapper that combines
   existing child summaries without conflating evidence layers.
4. Run local static/harness gates.
5. Run a short local headless/app-sync pressure proof with operation history.
6. Layer S21/S10 UI role traffic over headless pressure.
7. Move to staging/perf once local mixed evidence is repeatable.

## Completion Criteria

This spec is complete only when:

- P0/P1/P2 items above are checked with artifact-backed evidence;
- three consecutive green full-system staging or staging-equivalent runs exist;
- the final run includes 10-20 total real-session actors, S21, S10, headless
  app-sync actors, backend/RLS pressure, at least 15 projects, fault windows,
  quiescence, performance measurements, operation history, checkers, and
  storage/object reconciliation;
- safety violations are zero:
  lost acknowledged writes, unauthorized reads, unreconciled mismatches, and
  storage row/object mismatches;
- operational diagnostics and docs are complete enough for future
  sync-touching PRs to be gated without re-reading the old task lists.
