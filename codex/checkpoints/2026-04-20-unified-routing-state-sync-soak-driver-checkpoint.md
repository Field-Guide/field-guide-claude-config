# Unified Routing, State, And Sync-Soak Driver Checkpoint

Date: 2026-04-20
Spec: `.codex/plans/2026-04-20-unified-routing-state-sync-soak-driver-spec.md`

Use this checkpoint for factual implementation notes only: what changed, what
was verified, what failed, and which checklist items moved. Keep the spec as
the controlling todo list.

## 2026-04-20 Initialization

- Created the unified controlling spec after the route/state/sentinel and
  sync-soak audits.
- Decision recorded:
  - one standardized route/state/driver contract going forward;
  - AutoRoute remains the target router behind app-owned contracts;
  - app-owned device state is the posture source of truth;
  - host-side posture derivation is deprecated;
  - old route/readiness/state paths may exist only as marked compatibility;
  - four-device backend pressure is blocked until every device exposes
    deterministic route/state/sentinel proof.
- Immediate implementation order:
  1. update the active plan index;
  2. expose app-owned `stateMachine` in `/diagnostics/device_state`;
  3. make PowerShell posture code consume the app-owned state;
  4. add tests for schema, fixture, and posture consumption;
  5. only then strengthen interaction readiness and device startup gates.

## 2026-04-20 App-Owned State Machine Slice

- Created the durable checklist-style spec and checkpoint.
- Updated `.codex/PLAN.md` so the unified spec is the first active
  continuation source.
- Added `stateMachine` to `/diagnostics/device_state` by deriving it in Dart
  from the app-owned `DeviceStateSnapshot`.
- The state-machine payload now includes:
  - `schemaVersion`;
  - `posture`;
  - `interactionReady`;
  - `interactionBlockers`;
  - `currentRoute`;
  - `screenId`;
  - `sentinelKey`;
  - `visibleRootKeys`.
- Replaced duplicated PowerShell posture derivation with an app-owned posture
  reader:
  - `DevicePosture.ps1` now reads `device_state.stateMachine.posture`;
  - route/sync/app inference helpers were removed from the host posture
    module.
- Tightened `DeviceStateSnapshot.ps1` schema validation:
  - requires top-level schema v1;
  - requires `stateMachine`;
  - requires `stateMachine.schemaVersion`;
  - requires `stateMachine.posture`;
  - requires `stateMachine.interactionReady`.
- Host-side driver action wrappers now query canonical device state before
  tap/text/scroll/navigation and refuse interaction when
  `stateMachine.interactionReady` is false.
- Load order now sources `DeviceStateSnapshot.ps1` before `DriverClient.ps1`
  in the module loader and harness self-test runner.
- Verification:
  - `flutter test test/core/driver/device_state_machine_test.dart test/core/driver/device_state_endpoint_test.dart test/core/driver/device_state_snapshot_test.dart`
    passed.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed.
  - PowerShell parser checks for touched sync-soak modules passed.
  - `git diff --check` passed with line-ending warnings only.

## 2026-04-20 App-Side Readiness Slice

- Extracted device-state construction into `DriverDeviceStateProvider` so
  diagnostics, `/driver/ready`, `/driver/current-route`, and mutating
  interaction endpoints consume the same app-owned state payload.
- Added router identity fields to the app route host contract:
  - `routerBackend` is now exposed by the GoRouter and AutoRoute hosts;
  - `DriverRouteProbe` exposes `routerBackend` and `routerIdentity`;
  - `UiRegionBuilder` includes `activeRouteId`, `routerBackend`,
    `routerIdentity`, and `routeContractMatched`.
- Expanded `stateMachine` with:
  - `activeRouteId`;
  - `routerBackend`;
  - `routerIdentity`;
  - `route_contract_mismatch` interaction blocker.
- `/driver/ready` now returns transport readiness plus the canonical
  `stateMachine`; when the provider is present, `ready` is true only when
  `stateMachine.interactionReady` is true.
- Mutating app-side driver endpoints now run an app-owned readiness preflight
  before tapping, typing, scrolling, navigating, dismissing keyboard, or
  dismissing overlays. Unsafe actions return HTTP 409 with
  `error=state_sentinel_failed` and the state-machine payload. `/driver/wait`
  remains a read-only sentinel wait; `GET /driver/current-route` remains
  diagnostics.
- `/driver/current-route` now includes the current `stateMachine` route fields
  in addition to the legacy raw route fields.
- `tools/wait-for-driver.ps1` no longer accepts `/driver/ready` alone. It now
  requires:
  - `/driver/ready.transportReady=true`;
  - `/diagnostics/device_state.schemaVersion=1`;
  - `/diagnostics/device_state.stateMachine.schemaVersion=1`;
  - `/diagnostics/device_state.stateMachine.interactionReady=true`.
- Verification:
  - `flutter analyze lib/core/driver lib/core/router test/core/driver` passed.
  - `flutter test test/core/driver/device_state_machine_test.dart test/core/driver/device_state_endpoint_test.dart test/core/driver/device_state_snapshot_test.dart test/core/driver/driver_interaction_readiness_contract_test.dart test/core/driver/driver_shell_handler_timeout_contract_test.dart test/core/driver/state/ui_region_builder_test.dart` passed.
  - PowerShell parser checks for `tools/wait-for-driver.ps1`,
    `tools/sync-soak/DriverClient.ps1`, and
    `tools/sync-soak/DeviceStateSnapshot.ps1` passed.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed.

## 2026-04-20 Screen-Contract Key Discipline Slice

- Added `ScreenContractKeyValidation` and `validateDriverKeyForActiveContract`
  as the shared key validator over the existing app-owned `screenContracts`
  table. It supports exact keys plus generated dynamic templates using
  `<param>`, `${param}`, and `$param` forms so driver contracts can match both
  hand-written and generated testing-key shapes.
- Refactored `DriverInteractionHandler` readiness preflight to return a
  per-request `DriverInteractionPreflight` containing the canonical
  `stateMachine`, avoiding a second route/screen resolver.
- Mutating key-based app driver endpoints now refuse off-contract keys before
  widget lookup or dispatch:
  - `/driver/tap`;
  - `/driver/text`;
  - `/driver/drag`;
  - `/driver/scroll`;
  - `/driver/scroll-to-key` for both scrollable and target keys.
- Off-contract key failures return HTTP 409 with:
  - `error=screen_contract_key_failed`;
  - operation and key;
  - active screen-contract validation details;
  - canonical `stateMachine`.
- Filled the screen-contract gaps required by current sync-soak flows:
  - expanded `EntryEditor*` contracts for report activity, quantity, photo,
    document, contractor, attached-form, and dialog keys;
  - expanded `MdotHubScreen` for 0582B hub sections and fields;
  - added first-class `Mdot1126FormScreen` and `Mdot1174RFormScreen`
    contracts and screen-registry entries so `/form/:responseId` no longer
    has to misclassify those visible root sentinels as generic form screens;
  - added common form-export dialog/action contracts;
  - added missing settings, consent, sync-dashboard, and form-gallery keys used
    by accepted or in-flight harness flows.
- Updated the state machine so MDOT 1126 and MDOT 1174R form screens count as
  wizard-active screens.
- Host diagnostics now classify `screen_contract_key_failed` distinctly, and
  interaction-ready device-state schema validation requires current route,
  active route id, screen id, sentinel key, and visible root keys.
- Verification:
  - `flutter analyze lib/core/driver lib/core/router test/core/driver` passed.
  - `flutter test test/core/driver/screen_contract_key_validator_test.dart test/core/driver/registry_alignment_test.dart test/core/driver/driver_interaction_readiness_contract_test.dart test/core/driver/device_state_machine_test.dart test/core/driver/state/ui_region_builder_test.dart` passed.
  - PowerShell parser checks for `DeviceStateSnapshot.ps1`,
    `FailureClassification.ps1`, and `FlowWiring.Tests.ps1` passed.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed.

## 2026-04-20 Tap-Text Deprecation And Target Diagnostics Slice

- Deprecated blind text-only tapping in the app driver:
  - `/driver/tap-text` now requires `contractKey`;
  - missing `contractKey` returns HTTP 410 with
    `error=blind_tap_text_deprecated`;
  - the supplied `contractKey` must pass the same active screen-contract
    validation as `/driver/tap`.
- Updated the refactored host wrapper so `Invoke-SoakDriverTapText` requires
  `-ContractKey` and sends it in the request body.
- Removed blind tap-text fallbacks from accepted/refactored flows:
  - daily-entry activity edit dismisses the keyboard directly after keyed text
    entry;
  - quantity save uses `quantity_dialog_save` only;
  - photo source selection uses `photo_capture_gallery` only;
  - report photo detail close now uses new key `report_photo_close_button`;
  - MDOT 1126 expanded/signature flows use section/action keys only;
  - MDOT 1174R section selection uses section header/nav keys only.
- Kept one explicit contracted text selection for the MDOT 0582B HMA segment:
  `Invoke-SoakDriverTapText -Text "HMA" -ContractKey "hub_proctor_mode_toggle"`.
  This is not accepted as a blind text tap because the active screen contract
  must allow the named action key first.
- Added `report_photo_close_button` to the generated testing-key catalog and
  wired it into the report photo detail dialog and entry-editor screen
  contract.
- Filled screen-contract gaps found while removing tap-text:
  `activity_location_field_$locationId`, `hub_proctor_send_button`, and
  `hub_proctor_hma_max_density`.
- Added target usability diagnostics:
  - tap/tap-text/drag/scroll targets now fail with typed `target_not_*`
    errors when the resolved element is missing a render box, detached,
    invisible, zero-sized, read-only, or locally not hit-testable;
  - `/driver/scroll-to-key` now returns `scroll_target_not_found` with
    initial/final target and scrollable presence diagnostics.
- Host classification now distinguishes:
  - `deprecated_driver_action` for raw tap-text attempts;
  - `widget_target_not_usable` for typed target usability failures.
- Verification:
  - `dart run tools/gen-keys/generate_keys.dart --check` passed.
  - `flutter analyze lib/core/driver lib/shared/testing_keys lib/features/entries/presentation/screens/report_widgets test/core/driver` passed.
  - `flutter test test/core/driver/screen_contract_key_validator_test.dart test/core/driver/registry_alignment_test.dart test/core/driver/driver_interaction_readiness_contract_test.dart test/core/driver/device_state_machine_test.dart test/core/driver/state/ui_region_builder_test.dart test/core/driver/device_state_endpoint_test.dart test/core/driver/device_state_snapshot_test.dart test/core/driver/driver_shell_handler_timeout_contract_test.dart` passed.
  - PowerShell parser checks for changed sync-soak flow/client/classification
    files passed.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed.
- Still open:
  - actual device route/state smoke and four-device backend-pressure soak.

## 2026-04-20 Target/Scroll, Route Contract, And Clean Lab Startup Slice

- Closed the remaining target usability gaps:
  - `DriverWidgetInspector` now reports all matching `ValueKey` elements and
    emits key lookup diagnostics;
  - keyed mutating endpoints refuse ambiguous visible targets with
    `target_key_ambiguous`;
  - global hit testing detects overlays or other widgets blocking the target
    center and returns `target_center_blocked`;
  - inspector widget tests cover duplicate visible keys and globally blocked
    targets.
- Strengthened contracted tap-text:
  - the declared `contractKey` must resolve to a real unique widget target;
  - the selected text must be inside that declared contract target;
  - mismatches return `tap_text_target_outside_contract`.
- Completed the first scroll contract proof:
  - scrollable and target keys still validate against the active screen
    contract;
  - duplicate/ambiguous target or scrollable key resolution is refused;
  - when both target and scrollable are built, the target must be a descendant
    of the declared scrollable or the app returns
    `scroll_target_outside_scrollable`;
  - success and failure responses include target/scrollable render diagnostics
    and structured lookup artifacts.
- Added the first driver-facing route contract layer:
  - new `driver_route_contract.dart` derives `DriverRouteContract` entries from
    `screenContracts`;
  - contracts include route id, path template, required params, expected screen
    contract, expected root sentinel, shell placement, access policy, extra/result
    flags, supported router backends, and deprecation status;
  - repeated route families such as `/form/:responseId` resolve by active
    screen id;
  - `/driver/current-route` now returns `routeContract` diagnostics;
  - `/driver/navigate` refuses undeclared paths with `unsupported_driver_route`
    and active-backend unsupported slices with `unsupported_backend_route`.
- Added clean four-device lab restart behavior to
  `tools/start-local-harness-driver-lab.ps1`:
  - clean restart is the default when starting drivers;
  - stale host app/debug/build/wrapper processes are stopped;
  - each target app is force-stopped;
  - per-lane ADB forwards and reverses are removed before startup;
  - `-SkipDriverStart` is refused unless `-AllowExistingDriverLane` is supplied
    as an explicit non-acceptance/comparison path;
  - a `startup-clean-reset.json` manifest is written under the run output root.
- Host classification now maps route-contract navigation failures to
  `route_mismatch`, and target/scroll contract failures to
  `widget_target_not_usable`.
- Verification:
  - `flutter analyze` on the touched driver/route files and tests passed.
  - `flutter test test/core/driver/screen_contract_key_validator_test.dart test/core/driver/registry_alignment_test.dart test/core/driver/driver_interaction_readiness_contract_test.dart test/core/driver/device_state_machine_test.dart test/core/driver/state/ui_region_builder_test.dart test/core/driver/device_state_endpoint_test.dart test/core/driver/device_state_snapshot_test.dart test/core/driver/driver_shell_handler_timeout_contract_test.dart test/core/driver/driver_widget_inspector_test.dart test/core/driver/driver_route_contract_test.dart`
    passed.
  - PowerShell parser checks for changed startup/client/classification tests
    passed.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed with 22
    test files.
- Still open:
  - real S21/S10/emulator route-state smoke;
  - four-device no-pressure proof;
  - four-device backend-pressure sync soak;
  - route access policy extraction and GoRouter/AutoRoute guard parity.

## 2026-04-20 Route Access Policy Slice

- Extracted `RouteAccessPolicy` as the shared route-access decision object over
  `RouteAccessSnapshot`.
- Replaced the old GoRouter-owned redirect matrix in `AppRedirect` with a thin
  adapter over `RouteAccessPolicy` while preserving the existing redirect tests.
- Wired the AutoRoute vertical-slice guard through the same policy. Unsupported
  redirect targets in the current slice still fall back to the supported
  login/projects/settings shell routes until the AutoRoute route table expands.
- Added `RouteAccessDecision` diagnostics:
  - `allowed`;
  - reason;
  - redirect location;
  - force-reauth side-effect flag.
- `RouteAccessController` now records reevaluation count, last changed fields,
  and last decision without notifying again.
- `AppRouterHost`, `DriverRouteProbe`, `DriverRuntimeInspector`, and
  `UiRegionBuilder` now surface sanitized route-access diagnostics into the UI
  device-state region.
- `buildDeviceStateMachinePayload` now copies `lastGuardDecision` and
  `routeAccessChangedFields` into canonical `stateMachine`.
- PowerShell device-state schema validation now requires
  `stateMachine.routeAccessChangedFields` for interaction-ready snapshots.
- Verification:
  - `flutter analyze lib/core/router lib/core/driver test/core/router test/core/driver`
    passed.
  - `flutter test test/core/router/app_redirect_test.dart test/core/router/route_access_policy_test.dart test/core/router/route_access_snapshot_test.dart test/core/router/autoroute/app_auto_router_test.dart test/core/driver/state/ui_region_builder_test.dart test/core/driver/device_state_machine_test.dart test/core/driver/device_state_endpoint_test.dart`
    passed.
  - PowerShell parser checks for `DeviceStateSnapshot.ps1` passed.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed with 22
    test files.
- Still open:
  - `activeTab` in canonical state-machine payload;
  - full AutoRoute route table parity;
  - real-device route-state smoke and backend-pressure soak.

## 2026-04-20 Active Tab, Route-Contract Preflight, And Pressure Gate Slice

- Added `activeTab` to the canonical app-owned state pipeline:
  - `DriverRuntimeInspector` reads the visible `ScaffoldWithNavBar.activeTab`;
  - `UiRegionBuilder` includes `activeTab` in the UI region;
  - `buildDeviceStateMachinePayload` copies `activeTab` into
    `stateMachine`;
  - `/driver/current-route`, screen-contract diagnostics, and actor-context
    diagnostics expose the same value where applicable;
  - PowerShell schema validation now requires the `activeTab` property to
    exist on interaction-ready snapshots while allowing null for full-screen
    routes.
- Added host-side route-contract validation:
  - new `Assert-SoakCurrentRouteContract` validates
    `/driver/current-route.routeContract`;
  - it refuses missing, unmatched, ambiguous, unsupported-backend, screen-id
    mismatch, and root-sentinel mismatch states before a flow proceeds;
  - `Invoke-SoakActorPreflightCapture` now writes
    `route-contract-before.json` and fails preflight when that contract is not
    valid.
- Added backend-pressure readiness gating:
  - `enterprise-sync-concurrent-soak.ps1` sources the canonical state/driver
    helpers and runs `Invoke-EnterpriseDeviceLaneReadinessGate` before
    `Start-BackendRlsSoakJob`;
  - each declared actor must prove `/driver/ready`, canonical
    `device_state.stateMachine.interactionReady`, and current route-contract
    support;
  - the gate writes `pre-pressure-device-readiness.json` and records
    `manifest.prePressureReadiness`;
  - backend pressure is blocked before it starts if any declared lane fails.
- Host classification now maps `route_contract_mismatch` and
  `route_contract_ambiguous` to `route_mismatch`.
- Verification:
  - PowerShell parser checks passed for the touched PowerShell scripts.
  - `flutter analyze lib/core/driver lib/core/router test/core/driver test/core/router`
    passed.
  - `flutter test test/core/driver/device_state_machine_test.dart test/core/driver/state/ui_region_builder_test.dart test/core/driver/device_state_endpoint_test.dart test/core/driver/device_state_snapshot_test.dart test/core/driver/driver_route_contract_test.dart test/core/router/route_access_policy_test.dart test/core/router/autoroute/app_auto_router_test.dart`
    passed.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed with 22
    test files.
  - `git diff --check` passed with CRLF warnings only.
- Still open:
  - actual four-device route/state smoke;
  - four-device no-pressure proof;
  - four-device backend-pressure sync soak.

## 2026-04-20 Route Parity And Legacy Freeze Slice

- Added route parity tests to `driver_route_contract_test.dart`:
  - scans sync-soak flow scripts for route path literals;
  - ignores driver/diagnostics endpoints and embedded non-route payloads;
  - verifies every route literal matches an app-owned
    `DriverRouteContract`;
  - verifies each contract declares explicit current-router support and that
    `auto_route` support matches the current vertical slice only.
- Froze legacy flow acceptance:
  - `enterprise-sync-soak-lab.ps1` now defaults to `sync-only`, not
    `legacy`;
  - `-Flow legacy` is rejected by the shared device-lab argument validator
    unless `-AllowLegacyNonAcceptance` is passed explicitly;
  - `enterprise-sync-concurrent-soak.ps1` now defaults to `sync-only` and
    rejects `-Flow legacy` for concurrent enterprise acceptance.
- Verification:
  - PowerShell parser checks passed for the touched entrypoint/argument/test
    scripts.
  - `flutter test test/core/driver/driver_route_contract_test.dart` passed.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed with 22
    test files.
- Still open:
  - actual route/state smoke on the four device lanes;
  - no-pressure four-device proof;
  - backend-pressure four-device sync soak.

## 2026-04-20 Spec Audit Reconciliation

- Audited the active unified spec/checkpoint, the AutoRoute child
  spec/checkpoint, the four-role scale-up spec/checkpoint, the April 18
  unified sync-soak todo, the sync-soak decomposition specs, and the periodic
  CodeMunch audit plan.
- Updated the AutoRoute spec status to explicitly mark it as a child
  implementation input under the unified route/state/driver/sync-soak spec.
- Appended `Spec Audit Addendum - 2026-04-20` to the unified spec with:
  completed work to preserve, stale audit corrections, current immediate
  blockers, open work folded forward, AutoRoute child work still open,
  structural debt deferred until proof is stable, and the next exact
  implementation order.
- Reconciled stale notes:
  - route-access policy extraction is complete;
  - MDOT 1174R is no longer the current blocker in this lane;
  - old April 19 decomposition/state-machine checklists are audit inputs, not
    the live checklist to close line-by-line;
  - invalid four-lane attempts stay rejected whenever a lane was on launcher,
    ANR-blocked, not foreground, black/red-screened, or stale.
- Current immediate blocker remains consent-screen persona readiness: emulator
  lanes can reach `/consent` with `consent_screen` visible, but
  `consent_accept_button` is disabled until the consent scroll view reaches the
  bottom. The next code slice should make this sentinel/contract driven before
  rerunning the four-device lab.
