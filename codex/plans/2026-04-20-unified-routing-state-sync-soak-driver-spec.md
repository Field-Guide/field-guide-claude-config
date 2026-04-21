# Unified Routing, State, And Sync-Soak Driver Integration Todo Spec

Date: 2026-04-20
Status: active controlling integration spec
Checkpoint: `.codex/checkpoints/2026-04-20-unified-routing-state-sync-soak-driver-checkpoint.md`

## Decision

Build one standardized app-wide routing, state, driver, and sync-soak
integration system.

This replaces the current pattern where GoRouter/AutoRoute work, driver
screen contracts, PowerShell posture derivation, `/driver/ready`, sync-soak
state sentinels, and backend-pressure acceptance can each form their own
partial truth. Going forward, app navigation, route access, screen sentinels,
driver actions, device posture, sync evidence, and backend pressure must all
consume the same contract.

AutoRoute remains the target router, but the durable architecture is the
app-owned route contract and app-owned device state. The old system is not a
co-equal path. It is a temporary compatibility layer that must be marked,
tested, and retired behind replacement proof.

## Audit Inputs

- `.codex/AGENTS.md`
- `.codex/Context Summary.md`
- `.codex/PLAN.md`
- `.codex/CLAUDE_CONTEXT_BRIDGE.md`
- `.codex/plans/2026-04-20-autoroute-routing-provider-refactor-todo-spec.md`
- `.codex/checkpoints/2026-04-20-autoroute-routing-provider-refactor-checkpoint.md`
- `.codex/plans/2026-04-19-four-role-sync-hardening-scale-up-spec.md`
- `.codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`
- `.codex/research/2026-04-19-router-red-screen-architecture-research.md`
- Read-only routing/navigation audit on 2026-04-20
- Read-only driver/state/sentinel audit on 2026-04-20
- Read-only sync-soak orchestration audit on 2026-04-20
- Read-only active-plan/checkpoint reconciliation audit on 2026-04-20

## Current Problems This Spec Owns

- The app can select an AutoRoute host, but `context.appGo`,
  `context.appPush`, and `context.appReplace` are still bound to the GoRouter
  adapter.
- The app has Dart posture derivation in `device_state_machine.dart`, while
  PowerShell separately derives posture in `DevicePosture.ps1`.
- `/diagnostics/device_state` emits UI/app/data/sync regions but not the
  derived app-owned state-machine result that the harness should consume.
- `/driver/ready` can return `ready: true` without proving a route, screen
  contract, sentinel, app foreground state, or interaction readiness.
- Driver actions can still proceed with only broad process/foreground checks.
- Screen/route/action truth is split across route descriptors, GoRouter
  routes, AutoRoute routes, `screenContracts`, testing keys, generated
  PowerShell keys, and flow scripts.
- Parent soak artifacts can attach "latest" child summaries rather than
  child-owned outputs from the current run.
- Four-device runs have been attempted while emulator lanes were on the
  launcher, failed to attach, or ANR-blocked.
- Backend/RLS pressure, headless app-sync, and device UI evidence can still be
  discussed together even though only device UI proves local SQLite,
  `change_log`, Sync Dashboard, screenshots, and app route behavior.

## Non-Negotiables

- [ ] Real sessions only; no `MOCK_AUTH`.
- [ ] Device sync acceptance uses Sync Dashboard UI sync only.
- [ ] Direct `/driver/sync` is disqualifying for device UI acceptance.
- [ ] Backend/RLS-only success never satisfies device-sync acceptance.
- [ ] Headless app-sync success never satisfies device UI acceptance.
- [ ] Every accepted device action has route, screen, sentinel, and state
  proof.
- [ ] Every accepted run records clean screenshots, device state, route state,
  runtime logs, ADB/logcat evidence, queues, conflicts, reconciliation, and
  cleanup obligations.
- [ ] Legacy paths may exist temporarily only with explicit deprecation status,
  replacement, and removal condition.

## Public Contracts

### Route Contract

- [x] Define `RouteContract` as the single driver-facing route truth.
- [x] Include `routeId`, path template, required path params, optional query
  params, expected screen contract id, expected root sentinel key, shell/tab
  placement, access policy, supports `extra`, supports route result, supported
  router backends, and deprecation status.
- [x] Generate or assert `RouteContract` coverage from existing app route
  descriptors and screen contracts.
- [x] Add a test that no route path used by sync-soak exists only in a flow
  script.
- [x] Add a test that every contracted route is supported by the active router
  backend or explicitly marked unsupported for that slice.
- [x] Unsupported AutoRoute slice routes must fail loudly with a typed driver
  error instead of wildcard redirecting to `/projects`.
- 2026-04-20 update: `driver_route_contract.dart` now derives the
   driver-facing route contract list from `screenContracts`, resolves repeated
   route templates by active screen id, and exposes unsupported backend state.
   `/driver/navigate` refuses undeclared paths with `unsupported_driver_route`
   and unsupported active-backend slices with `unsupported_backend_route`.

### Route Access Contract

- [x] Extract `RouteAccessPolicy`.
- [x] Make GoRouter redirects and AutoRoute guards call the same policy over
  `RouteAccessSnapshot`.
- [x] Cover auth, password recovery, update required, reauth, consent, profile
  setup, company setup, membership status, admin-only routes, project create,
  project management, and field-data access.
- [x] Add route-access decision tests independent of GoRouter and AutoRoute.
- [x] Add adapter tests proving each router calls the shared policy.
- [x] Expose sanitized route-access diagnostics: current snapshot,
  reevaluation count, last changed fields, last decision, and last denial.
- 2026-04-20 update: `RouteAccessPolicy` now owns the redirect/guard decision
  matrix. `AppRedirect` is a GoRouter adapter, the AutoRoute vertical-slice
  guard calls the same policy, `RouteAccessController` records sanitized
  decision diagnostics, and device-state UI/state-machine payloads include
  route-access decision/change fields.

### Device State Contract

- [ ] `/diagnostics/device_state` is the canonical app-owned device state
  endpoint.
- [x] Add `stateMachine` to the endpoint payload.
- [x] Include `schemaVersion`, `posture`, `interactionReady`,
  `interactionBlockers`, `currentRoute`, `activeRouteId`, `routerBackend`,
  `routerIdentity`, `activeTab`, `screenId`, `sentinelKey`,
  `visibleRootKeys`, `lastGuardDecision`, and `routeAccessChangedFields`.
- 2026-04-20 update: `lastGuardDecision`, `routeAccessChangedFields`, and
  `activeTab` are emitted through the UI region and copied into
  `stateMachine`; host schema validation now requires the `activeTab` property
  to exist on interaction-ready snapshots while allowing null for full-screen
  routes.
- [ ] Keep UI/app/data/sync regions as inputs, but do not require host scripts
  to rederive posture from them.
- [ ] Add typed interaction blockers for booting, errored, tripped, syncing
  where unsafe, route missing, screen id missing, sentinel missing, sentinel not
  visible, Android surface blocked, app not foreground, and route contract
  mismatch.
- [ ] Version the `stateMachine` shape separately if it needs to evolve.

### Driver Readiness Contract

- [ ] Treat `/driver/ready` as transport readiness only, or replace it with a
  readiness response that embeds canonical device state.
- [ ] Startup readiness must require ADB device visibility, app process
  running, app foreground, driver port mapped, router attached, valid device
  state schema, expected posture, resolved screen contract, visible sentinel,
  clean queue/conflict state, sync runtime idle, sync-hint health, and clean
  Android surface.
- [ ] A lane that only proves `ready: true` is not eligible for soak
  acceptance.

## Deprecation Policy

- [ ] Add a `legacy` or `deprecated` marker to old route/state/driver paths
  that are temporarily retained.
- [ ] Every deprecated path must list an owner, replacement, and removal
  condition.
- [ ] Deprecated paths can support rollback or comparison, but cannot satisfy
  acceptance gates unless explicitly whitelisted in this spec.
- [ ] Add tests that fail if deprecated paths are used by acceptance presets.
- [ ] Remove legacy code only after replacement tests and device proof pass.

## Ordered Todo

### Phase 0 - Canonicalize And Freeze Legacy Expansion

- [x] Create this controlling spec.
- [x] Create the matching checkpoint.
- [x] Update `.codex/PLAN.md` so this spec is the first continuation source.
- [x] Preserve the prior AutoRoute spec as a child input, not a competing
  source of truth.
- [x] Freeze new feature work on legacy route-driver paths.
- [x] Freeze new host-side posture derivation.
- [x] Freeze new `/driver/ready`-only acceptance checks for
  `tools/wait-for-driver.ps1`; startup now requires canonical
  `/diagnostics/device_state.stateMachine.interactionReady`.
- [x] Freeze `-Flow legacy` as non-acceptance.
- [ ] Reconcile accepted-flow truth before claiming evidence, especially MDOT
  1174R drift between current context and newer four-role docs.
- [ ] Record the invalid four-lane facts: emulator startup/ANR, launcher
  visible failures, stale process risk, and blind-tap behavior.

### Phase 1 - Route And User-Flow Model

- [ ] Inventory all user journeys forward and backward:
  auth/onboarding, project selection, dashboard tabs, daily entry/report,
  forms, pay apps, sync/conflicts/trash, settings/admin/help, exports, and
  gallery.
- [ ] For each journey, define route entry, legal back behavior, guard policy,
  shell/tab ownership, expected root sentinel, modal states, and driver-safe
  actions.
- [ ] Convert the AutoRoute vertical slice from a package experiment into a
  route-contract slice.
- [ ] Cover at minimum `/login`, `/`, `/calendar`, `/projects`, `/settings`,
  `/project/new`, `/project/:projectId/edit`, `/report/:entryId`, and
  `/sync/dashboard`.
- [x] Add parity tests that every driver path has backend support or an
  explicit unsupported marker.
- [x] Add route contract validation to sync-soak preflight.

### Phase 2 - One State Machine

- [x] Move posture derivation into `/diagnostics/device_state.stateMachine`.
- [x] Deprecate PowerShell posture derivation immediately.
- [x] Change `DevicePosture.ps1` so it only reads
  `stateMachine.posture`.
- [x] Keep `StateMachine.ps1` as orchestration transition recording only.
- [x] Add tests that fail if host scripts reintroduce posture rules matching
  Dart posture logic.
- [x] Add device-state fixture coverage for `stateMachine`.
- [x] Add interaction readiness tests for visible sentinel and missing
  sentinel cases.

### Phase 3 - Driver Action Discipline

- [x] Every host-side driver interaction wrapper must validate canonical
  interaction readiness.
- [x] Every app-side mutating driver interaction endpoint must validate
  canonical interaction readiness. `/driver/wait` remains a read-only sentinel
  wait and `GET /driver/current-route` remains diagnostics.
- [x] Every mutating key-based app driver action must belong to the active
  screen contract. The enforced endpoints are `/driver/tap`, `/driver/text`,
  `/driver/drag`, `/driver/scroll`, and `/driver/scroll-to-key`; `/driver/wait`
  remains read-only observation. `/driver/tap-text` is no longer a blind
  text-only action: it must include a declared `contractKey` that is valid for
  the active screen contract.
- [x] Targets must be visible, enabled, hit-testable, and unblocked.
- 2026-04-20 update: tap/text/drag/scroll endpoints now return typed
  refusals for missing, detached, invisible, read-only, locally
  non-hit-testable, globally blocked, or ambiguous duplicate visible targets.
  Global hit testing returns `target_center_blocked`; duplicate visible key
  resolution returns `target_key_ambiguous`.
- [x] Ban blind `tap-text` except through a screen-scoped action contract or
  explicit modal contract.
- Raw `/driver/tap-text` now returns `blind_tap_text_deprecated`, the
  refactored `Invoke-SoakDriverTapText` wrapper requires `-ContractKey`, and
  refactored flow tests fail if any `Flow.*.ps1` call omits that key. The only
  retained contracted text selection is MDOT 0582B `HMA` via
  `hub_proctor_mode_toggle`.
- [x] Add scroll contract validation: declared scrollable, target inside
  scrollable, unique key, attached render object before and after scroll, and
  structured failure artifact.
- 2026-04-20 update: `/driver/scroll-to-key` validates declared scrollable and
  target keys against the active screen contract, refuses duplicate/ambiguous
  key resolution, refuses `scroll_target_outside_scrollable`, returns
  target/scrollable diagnostics on success, and emits structured
  `scroll_target_not_found` lookup artifacts on failure.
- [x] Make `/driver/navigate` and `/driver/current-route` return route
  contract fields, not only raw path.
- [x] Add the first `/driver/current-route` route-state expansion:
  `activeRouteId`, `routerBackend`, `routerIdentity`, `screenId`,
  `sentinelKey`, `interactionReady`, `interactionBlockers`, and
  `stateMachine`.
- [x] Add the first `/driver/current-route` route-contract expansion:
  `routeContract.matched`, backend support, exact contract when screen id
  resolves a single route, or candidates when the path is route-family
  ambiguous.
- [ ] Add first-failure extraction for guard denial, unexpected redirect,
  missing sentinel, wrong active tab, duplicate key, dirty build scope, red
  screen, black surface, stale router identity, and unsupported backend route.

### Phase 4 - Phasing Out The Old Routing System

- [ ] Make `AppNavigator` injectable or provider-backed.
- [ ] Ensure `context.appGo`, `context.appPush`, and `context.appReplace`
  dispatch through the active backend.
- [ ] Deprecate GoRouter-bound navigation extensions after active-backend
  dispatch is wired.
- [ ] Deprecate GoRouter fallback lookup in driver runtime/navigation once
  `DriverRouteProbe` is mandatory.
- [ ] Keep GoRouter production route table only as compatibility during
  migration.
- [ ] Expand AutoRoute by user-flow families, not by arbitrary files.
- [ ] Resolve every `extra` route explicitly as path/query state, generated
  typed args, or typed result object.
- [ ] Remove GoRouter only after full route-contract parity, driver flows,
  screenshots, sync evidence, and lints pass.

### Phase 5 - Four-Device Startup Gate

- [x] Kill stale wrapper, Flutter, app, and driver processes before a clean
  run.
- [x] Remove stale ADB forwards and reverses before a clean run.
- [ ] Restart ADB only when needed and record that action.
- [ ] Start each lane with recorded build fingerprint, dart defines hash,
  Supabase target, driver port, device serial, role, and expected project
  scope.
- [ ] Require readiness per device:
  ADB visible, app foreground, driver reachable, router attached, device state
  schema valid, expected posture, screen contract resolved, visible sentinel,
  queue/conflict clean, sync runtime idle, sync-hint health clean, Android
  surface clean.
- [x] Refuse `-SkipDriverStart` acceptance unless the existing lane proves the
  same build/backend/state contract.
- [x] Do not start backend pressure until all declared device lanes pass
  readiness.
- 2026-04-20 update: `enterprise-sync-concurrent-soak.ps1` now runs
  `prePressureReadiness` before `Start-BackendRlsSoakJob`. The gate calls
  `/driver/ready`, canonical `/diagnostics/device_state.stateMachine`, and
  `/driver/current-route.routeContract` for every declared lane and writes
  `pre-pressure-device-readiness.json`; a failed lane blocks backend pressure
  before it starts.

### Phase 6 - Sync-Soak Flow Integration

- [ ] Promote device posture, screen contract, no-conflict,
  provider/local visibility, selected-project, and sync-hint sentinels to
  standard pre/post gates for all accepted flows.
- [ ] Require UI-driver operation history equivalent to headless app-sync:
  actor, device, role, user, company, project, route id, screen id, action
  intent, table/object family, record id, cleanup obligation, and expected
  invariant.
- [ ] Replace parent "latest summary" lookup with child-owned output paths and
  manifest validation.
- [ ] Normalize parent evidence layer names so device UI, headless app-sync,
  and backend/RLS pressure cannot be conflated.
- [ ] Keep device sync proof on Sync Dashboard UI sync.
- [ ] Keep direct `/driver/sync` disqualifying.

### Phase 7 - Scale And Pressure Proof

- [ ] Define scale profiles: `smoke`, `baseline`, `pressure`, and
  `enterprise`.
- [ ] Record actor mix, device count, backend/headless concurrency, marker
  behavior, duration, fault windows, artifact requirements, and liveness
  thresholds for every profile.
- [ ] Run four devices with no backend pressure first.
- [ ] Add backend-to-device marker proof after deterministic state passes.
- [ ] Add concurrent backend/RLS and headless app-sync pressure while device UI
  actors run real flows.
- [ ] Accept only with clean screenshots, logs, route/state snapshots,
  queue/conflict state, reconciliation, storage proofs, cleanup ledgers, and
  readable result index.

### Phase 8 - Staging, Faults, And Operational Closure

- [ ] Add force-stop restart with preserved SQLite.
- [ ] Add process kill during dirty queue.
- [ ] Add offline/reconnect.
- [ ] Add auth refresh and expected denial windows.
- [ ] Add stale sync locks and stale `pulling=1` checks.
- [ ] Add stale `sync_hint_subscriptions` production/staging alert coverage.
- [ ] Enforce post-fault quiescence thresholds.
- [ ] Complete `docs/sync-consistency-contract.md`.
- [ ] Collect three consecutive green full-system staging or
  staging-equivalent runs before release readiness.

## Test Plan

- [x] Dart unit tests for `RouteAccessPolicy`.
- [x] Dart unit tests for `RouteContract`.
- [x] Dart tests for route descriptor and screen contract coverage.
- [x] Dart tests for `DeviceStateSnapshot.stateMachine` payload.
- [ ] Flutter tests for GoRouter and AutoRoute adapter parity on the vertical
  slice.
- [ ] Custom lint tests banning production feature/design-system router
  imports.
- [ ] Custom lint tests banning volatile provider fields in route guards.
- [x] PowerShell tests for device-state schema validation.
- [x] PowerShell tests for posture consumption from `stateMachine`.
- [x] PowerShell tests rejecting legacy posture derivation.
- [x] Dart contract tests for app-side interaction readiness refusal.
- [x] Dart unit tests for app-side screen-contract key validation.
- [x] PowerShell wiring tests that `wait-for-driver` requires canonical
  device-state readiness.
- [x] PowerShell tests classify screen-contract key refusal and require
  interaction-ready snapshots to carry route, screen, sentinel, and visible
  root key fields. They now also classify `blind_tap_text_deprecated` and
  `target_not_*` driver refusals distinctly.
- [x] PowerShell tests assert actor preflight validates the current route
  contract and parent backend pressure is blocked until device lane readiness
  passes.
- [x] Dart route-contract tests scan sync-soak flow scripts and fail if a
  route literal is not covered by an app-owned `DriverRouteContract`.
- [x] PowerShell wiring tests assert legacy `-Flow legacy` is no longer a
  default acceptance path and concurrent enterprise acceptance rejects it.
- [ ] PowerShell behavior tests for interaction readiness refusal.
- [ ] PowerShell tests for child summary path validation.
- [x] PowerShell static tests for clean four-device startup gate behavior.
- [ ] PowerShell tests for startup readiness classification.
- [ ] Device proof sequence:
  S21 route/state smoke, tablet or S10 route/state smoke, emulator-5554
  route/state smoke, emulator-5556 route/state smoke, four-device no-pressure
  proof, then four-device backend-pressure soak.

## Acceptance Criteria

- [x] The active spec and checkpoint exist and are referenced from
  `.codex/PLAN.md`.
- [x] The AutoRoute spec is treated as a child input to this unified lane.
- [x] No host script derives app posture independently from UI/app/sync/data
  regions.
- [x] `/diagnostics/device_state` exposes the canonical app-owned state
  machine.
- [x] Host-side driver action wrappers refuse to run when canonical interaction
  readiness fails.
- [x] App-side driver endpoints refuse to run when canonical interaction
  readiness fails.
- [x] App-side mutating key-based driver endpoints refuse off-contract keys
  with `screen_contract_key_failed`.
- [x] Blind text-only tapping cannot run through the refactored driver path;
  `tap-text` requires a screen-contract `contractKey` and raw calls fail with
  `blind_tap_text_deprecated`.
- [ ] Every accepted driver action proves route, screen, sentinel, and state.
- [x] Legacy readiness, legacy posture derivation, and legacy flow entrypoints
  cannot satisfy acceptance gates.
- [x] Parent backend pressure cannot start until every declared device lane
  proves driver readiness, canonical state-machine interaction readiness, and
  current route-contract support.
- [ ] S21, tablet or S10, emulator-5554, and emulator-5556 all pass
  route/state/sentinel smoke before backend pressure starts.
- [ ] Full soak acceptance includes backend pressure, headless app-sync
  pressure where requested, device UI proof, clean queues/conflicts, clean
  screenshots/logs, and explicit evidence-layer separation.

## Spec Audit Addendum - 2026-04-20

This addendum reconciles the active route/state/driver/soak specs after the
long-running four-device attempts. It is the bottom-of-list reference for what
remains open. Older specs stay useful as audit inputs, but this unified spec is
the checklist to update going forward.

### Audited Sources

- [x] `.codex/plans/2026-04-20-unified-routing-state-sync-soak-driver-spec.md`
- [x] `.codex/checkpoints/2026-04-20-unified-routing-state-sync-soak-driver-checkpoint.md`
- [x] `.codex/plans/2026-04-20-autoroute-routing-provider-refactor-todo-spec.md`
- [x] `.codex/checkpoints/2026-04-20-autoroute-routing-provider-refactor-checkpoint.md`
- [x] `.codex/plans/2026-04-19-four-role-sync-hardening-scale-up-spec.md`
- [x] `.codex/checkpoints/2026-04-19-four-role-sync-hardening-scale-up-checkpoint.md`
- [x] `.codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`
- [x] `.codex/plans/2026-04-18-sync-soak-decomposition-todo-spec.md`
- [x] `.codex/plans/2026-04-19-sync-soak-decomposition-state-machine-refactor-spec.md`
- [x] `.codex/plans/2026-04-19-sync-soak-driver-decomposition-todo-spec.md`
- [x] `.codex/plans/2026-04-19-sync-soak-periodic-codemunch-audit-plan.md`

### Source-Of-Truth Hierarchy

- [x] This unified 2026-04-20 spec is the controlling route/state/driver/
  sync-soak integration checklist.
- [x] The AutoRoute spec is a child routing/provider implementation input, not
  a competing top-level source.
- [x] The four-role scale-up spec remains the supporting source for actor
  mix, backend/headless pressure, role/RLS checkers, fault windows, staging,
  and operational gates.
- [x] The April 18 unified sync-soak todo remains historical/evidence context;
  its still-valid scale, role, RLS, staging, and consistency-contract work is
  folded into the open items below.
- [x] The April 18 and April 19 decomposition specs are structural-debt inputs,
  not blockers for the immediate four-device route/state/pressure proof unless
  they touch the current driver/readiness path.

### Confirmed Completed Work To Preserve

- [x] App-owned `stateMachine` is emitted through
  `/diagnostics/device_state` and copied into `/driver/ready` /
  `/driver/current-route` diagnostics.
- [x] Host posture derivation now consumes `stateMachine.posture`; host
  re-derivation is deprecated.
- [x] Route access policy has been extracted behind shared GoRouter and
  AutoRoute guard adapters.
- [x] Driver route contracts exist, are validated by tests, and reject
  undeclared or unsupported backend routes.
- [x] Mutating driver actions enforce canonical interaction readiness and
  active screen-contract keys.
- [x] Blind `tap-text` is deprecated; the refactored path requires a
  screen-contract `contractKey`.
- [x] Target usability, duplicate visible key, global center hit-test, and
  scroll-to-key diagnostics are typed failure paths.
- [x] Parent backend pressure is gated on declared device-lane readiness.
- [x] Legacy `-Flow legacy` and readiness-only acceptance are blocked from
  acceptance presets by default.
- [x] Clean-lab startup now clears stale driver/app processes and ADB
  forwards/reverses, and can clear Android app data for clean persona starts.
- [x] Android notification/location permission prompts are handled in startup
  and surface preflight.
- [x] Runtime scanning no longer counts unrelated UIAutomator AndroidRuntime
  launcher noise as app runtime evidence.
- [x] Daily-entry mutation target selection is current-user/role aware; it
  preserves the product rule that users cannot write other users' entries.
- [x] Local update timestamps for generic and daily-entry local writes are
  monotonic against the existing local row, reducing false LWW cleanup
  conflicts after sync.

### Audit Corrections And Stale Items

- [x] The old "route access policy extraction still open" checkpoint note is
  stale; the later route-access slice completed that work.
- [x] The old "MDOT 1174R not accepted" note is stale for current scale-up
  context; later April 18 evidence accepted MDOT 1174R mutation/export/gallery
  paths on S21/S10. Current four-device work must not reopen that as the next
  blocker unless new evidence does.
- [x] The April 19 state-machine/decomposition specs contain many unchecked
  boxes because they were superseded as working sources. Their valid design
  intent is folded here; do not try to close those old files line-by-line.
- [x] The invalid four-lane attempts remain rejected evidence when a lane was
  on launcher, ANR-blocked, not foreground, black/red-screened, or using stale
  process/build state.
- [x] Backend/RLS-only and headless-only passes remain valuable pressure
  evidence but never satisfy device UI sync acceptance.

### Current Immediate Blockers From Latest Evidence

- [ ] Fix clean persona readiness on consent screens when the accept button is
  disabled until the consent scroll view reaches the bottom. The driver must
  use sentinel/contracted scrolling, not blind tap retries.
- [ ] Rerun clean four-device lab after the consent-readiness fix:
  S21 admin on `4968`, tablet or S10 inspector on `4949`, engineer emulator on
  `4972`, office-technician emulator on `4973`.
- [ ] Preserve a startup manifest proving build fingerprint, dart-defines
  hash, Supabase target, driver port, device serial, role, project scope, ADB
  restart action if any, and clean Android app-data reset policy.
- [ ] Require all four lanes to pass route/state/sentinel smoke before
  backend/headless pressure starts.
- [ ] Run four-device no-pressure proof before accepting coupled pressure.
- [ ] Run full four-device backend-pressure soak only after no-pressure proof
  passes.

### Open Work Folded Forward

- [ ] Finish the formal `/driver/ready` contract: decide whether it is
  transport-only or always embeds canonical state; then add behavior tests for
  startup readiness classification.
- [ ] Complete typed interaction blockers for booting, errored, tripped,
  unsafe syncing, missing route/screen/sentinel, sentinel not visible, Android
  surface blocked, app not foreground, route-contract mismatch, permission
  dialog, disabled target, and consent-scroll-not-complete.
- [ ] Add deprecated/legacy metadata with owner, replacement, and removal
  condition for retained route/state/driver paths.
- [ ] Add tests that fail if deprecated paths are used by acceptance presets.
- [ ] Complete the forward/backward user-flow route model for auth/onboarding,
  tabs, projects, daily entry/report, forms, pay apps, sync/conflicts/trash,
  settings/admin/help, exports, and gallery.
- [ ] Promote device posture, route contract, screen contract, no-conflict,
  provider/local visibility, selected-project, sync-hint, and Android surface
  sentinels into standard pre/post gates for every accepted flow.
- [ ] Extend UI-driver operation history to match headless app-sync evidence:
  actor, device, role, user, company, project, route id, screen id, action
  intent, table/object family, record id, cleanup obligation, and expected
  invariant.
- [ ] Replace parent "latest summary" lookup with child-owned output paths and
  manifest validation for backend, headless, and device layers.
- [ ] Normalize evidence-layer names so device UI, headless app-sync, and
  backend/RLS pressure cannot be conflated.
- [ ] Define scale profiles `smoke`, `baseline`, `pressure`, and `enterprise`
  with actor mix, device count, backend/headless concurrency, marker behavior,
  durations, fault windows, artifacts, and liveness thresholds.
- [ ] Add backend-to-device marker proof after deterministic route/state
  passes, then add device-to-backend proof using real UI mutation flows.
- [ ] Add role/visibility checkers for admin, engineer, office technician, and
  inspector during active writes and after quiescence.
- [ ] Prove Trash is current-user scoped for all approved roles without
  weakening the daily-entry/report ownership policy.
- [ ] Add quiescence checkers for blocked/unprocessed rows, retry counts,
  conflicts, sync locks, storage row/object consistency, and reconciliation
  hashes.
- [ ] Expand deterministic fixture scale toward 15 projects and realistic
  records/binary/export artifacts before final 15-20 actor acceptance.
- [ ] Layer 15-20 headless app-sync actors and backend/RLS pressure over
  device UI actors without counting either layer as device UI proof.
- [ ] Add fault windows: force-stop with preserved SQLite, process kill during
  dirty queue, offline/reconnect, background/foreground, auth refresh,
  expected denial windows, storage transient failures, stale sync locks,
  stale `pulling=1`, realtime hint loss/duplicate/fallback.
- [ ] Capture p50/p95/p99 convergence and storage availability timings and
  compare against `scripts/perf_baseline.json`.
- [ ] Complete `docs/sync-consistency-contract.md`.
- [ ] Complete operational diagnostics/alerts, especially stale
  `sync_hint_subscriptions`, blocked queue rows, retry growth, stale locks,
  storage cleanup backlog, per-device sync timeout, RLS denials, and backend
  log-drain failures.
- [ ] Collect three consecutive green full-system staging or
  staging-equivalent runs at the same commit before release readiness.

### AutoRoute Child Work Still Open

- [ ] Preserve baseline device artifact paths for router comparison.
- [ ] Prove the AutoRoute vertical slice on S21, tablet/S10, and two
  emulators before full migration.
- [ ] Keep GoRouter as compatibility until route-contract parity, driver flows,
  screenshots, sync evidence, lints, and device proof pass.
- [ ] Finish provider-churn cleanup: ensure profile refresh, sync dirty
  markers, and background pulls do not cause unrelated route reevaluation.
- [ ] Measure project-list rebuild pressure after the provider split.
- [ ] Add/finish lints for production feature/design-system router imports,
  route guards depending on volatile provider fields, raw route-level
  navigation, and profile refresh APIs in screen init/mount paths.
- [ ] Add first-failure extraction for guard denial, unexpected redirect,
  stale router identity/scope, wrong active tab, duplicate key, dirty build
  scope, red screen, black surface, and unsupported backend route.

### Structural Debt Deferred Until Proof Is Stable

- [ ] Review or split `screen_contract_registry.dart` only after current
  route/state proof is stable, or add a time-bounded registry-shaped size
  exception.
- [ ] Continue sync-soak decomposition only where it reduces current failure
  risk: child-owned summary paths, evidence-layer naming, readiness
  classification, operation history, and artifact validation are higher
  priority than broad file-shape cleanup.
- [ ] Keep the CodeMunch audit plan as a closeout gate for structural work:
  hotspots, symbol complexity, and coupling checks should be recorded after
  decomposition slices, not before the current consent/startup blocker is
  fixed.

### Next Exact Implementation Order

1. [ ] Patch consent-screen persona readiness so the script scrolls to a
   contracted bottom sentinel or otherwise proves the scroll-complete state
   before tapping `consent_accept_button`.
2. [ ] Add/adjust tests for the consent readiness blocker: disabled accept
   button is a startup/setup state, not a random widget-target failure.
3. [ ] Run the no-device harness tests and focused Flutter/Dart tests touched
   by the consent fix.
4. [ ] Reset local Supabase, rebuild/clear app data, and restart all four
   lanes from a clean lab.
5. [ ] Run four-device route/state/sentinel smoke with no backend pressure.
6. [ ] Run four-device backend/headless pressure only after the no-pressure
   proof passes.
7. [ ] Append exact commands, artifact paths, pass/fail summary, and remaining
   blockers to the checkpoint.
