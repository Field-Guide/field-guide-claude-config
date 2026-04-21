# Unified Routing, State, Auth, And Four-Device Live-Testing Reset Checkpoint

Date: 2026-04-20
Status: active append-only checkpoint for the unified reset lane
Spec: `.codex/plans/2026-04-20-unified-routing-state-auth-live-testing-reset-plan.md`

## Purpose

This file is the append-only implementation log for the unified routing/state/
auth/live-testing reset lane. Keep adding dated entries instead of replacing
older notes so continuation work can recover exact decisions, progress, and
remaining blockers.

## Current Focus

1. Save the controlling spec and durable checkpoint.
2. Land canonical auth runtime snapshots:
   `AuthSessionState`, `ProfileState`, and `SyncAuthContext`.
3. Surface those snapshots through device-state diagnostics and driver-facing
   readiness data.
4. Move auth-sync bootstrap scheduling to the stable sync auth context instead
   of broad presentation-owned auth reads.

## Progress

- [x] Controlling spec saved to `.codex/plans/2026-04-20-unified-routing-state-auth-live-testing-reset-plan.md`.
- [x] Append-only checkpoint created.
- [x] Canonical auth runtime snapshot types landed.
- [x] `AuthProvider` exposes auth runtime snapshots and sync context.
- [x] Device-state app/auth diagnostics emit auth runtime snapshots.
- [x] Device-state state machine emits auth runtime snapshots.
- [x] Auth-sync bootstrap uses `SyncAuthContext`.
- [x] Targeted tests updated for the new auth runtime diagnostics.
- [x] Host readiness classification consumes canonical device-state auth/runtime fields.
- [x] `wait-for-driver`, driver interaction preflight, and pre-pressure readiness now report typed readiness classes.
- [x] Concurrent lane startup writes per-lane readiness manifest with Android surface and app-state evidence.

## 2026-04-20 Initial Entry

- The plan was expanded and saved after the earlier compressed draft lost too
  much decision context.
- The first implementation slice is intentionally narrow and high leverage:
  canonical auth runtime state in Dart, diagnostics exposure, and sync/bootstrap
  consumption.
- Auth platform migration and Riverpod migration remain explicitly out of scope
  for this lane.

## 2026-04-20 Implementation Entry 01

### Landed

- Added `auth_runtime_state.dart` with:
  - `AuthSessionState`
  - `ProfileState`
  - `AuthSyncContext`
- `AuthProvider` now exposes:
  - `sessionState`
  - `profileState`
  - `isRecoverySessionValid`
  - `syncContext`
- App/device diagnostics now emit auth runtime fields:
  - app auth region
  - driver actor auth diagnostics
  - device-state state-machine payload
- Sync/bootstrap auth consumption was narrowed:
  - `AuthSyncListenerBootstrap`
  - `AuthProviderSessionService`
  now read the stable sync auth context instead of re-deriving company/user
  from multiple broad provider seams.
- `RouteAccessSnapshot` now records `sessionState` and `profileState` so route
  diagnostics can see the same auth-runtime-state vocabulary as device-state
  diagnostics.

### Verification

- `flutter analyze` on the touched auth/router/driver/bootstrap files: passed.
- Targeted Flutter tests passed:
  - route access snapshot/policy
  - AutoRoute guard slice
  - device-state snapshot/machine/endpoint
  - app bootstrap and initializer
  - auth provider

### Next Slice

- Push these auth runtime states into startup/readiness classification so the
  host can explicitly distinguish:
  - signed out,
  - authenticating,
  - authenticated but profile bootstrap pending,
  - recovery route required,
  - consent blocked,
  - permission blocked.
- Then tighten the four-device startup gate around those explicit states before
  resuming broader live pressure work.

## 2026-04-20 Implementation Entry 02

### Landed

- Added a shared host-side readiness classifier in
  `tools/sync-soak/DeviceStateSnapshot.ps1`.
- The classifier reads only the app-owned `device_state.stateMachine` payload
  and reports typed readiness classes instead of re-deriving posture from
  routes, sync phase, or raw UI regions.
- The current classifications now include:
  - `ready`
  - `booting`
  - `launcher_home`
  - `sign_in_required`
  - `sign_in_submitting`
  - `profile_bootstrap_pending`
  - `pending_approval`
  - `profile_setup_required`
  - `consent_blocked`
  - `permission_blocked`
  - `password_recovery_required`
  - `auth_session_expired`
  - `authenticated_on_auth_route`
  - `route_contract_mismatch`
  - `route_missing`
  - `screen_id_missing`
  - `sentinel_missing`
  - `sentinel_not_visible`
  - `syncing`
  - `tripped`
  - `errored`
- `wait-for-driver.ps1` now validates the canonical device-state schema,
  computes readiness class, and reports `readinessClass`,
  `authSessionState`, and `profileState` in timeout/success output.
- `DriverClient.ps1` interaction preflight and readiness waits now use the
  canonical readiness classification for first-failure messages instead of
  flattening every state-machine refusal into generic
  `interactionReady=false`.
- `enterprise-sync-concurrent-soak.ps1` pre-pressure readiness now records the
  typed readiness result per lane and blocks backend pressure on that canonical
  classification.
- Host schema validation now requires the auth runtime fields on the
  `stateMachine` payload:
  - `authSessionState`
  - `profileState`
  - `isRecoverySessionValid`

### Verification

- `./tools/test-sync-soak-harness.ps1` passed:
  22 test files, all assertions green.
- New self-tests cover host classification for:
  - ready,
  - signed out,
  - authenticating/sign-in submitting,
  - profile bootstrap pending,
  - consent blocked,
  - permission blocked,
  - launcher/home.

### Remaining

- Integrate Android-surface classifications into startup manifests so system
  permission dialogs and launcher/home posture show up as canonical lane
  readiness evidence even before Dart diagnostics are reachable.
- Continue Phase 6 four-lane startup hardening: every lane should start
  concurrently, converge to the same readiness class, and refuse pressure if
  any lane is not in the accepted readiness set.
- Continue broader AutoRoute route-contract expansion by user-flow family;
  this slice only tightened readiness classification and did not claim full
  router cutover.

## 2026-04-20 Implementation Entry 03

### Landed

- Four-lane startup now writes `startup-lanes/startup-lanes-readiness.json`
  after concurrent lane startup jobs complete or fail.
- Each lane result now carries the parsed `wait-for-driver` readiness JSON
  when available, including:
  - Android foreground/process status,
  - startup reason,
  - canonical app readiness class,
  - auth session state,
  - profile state,
  - state-machine blockers.
- Startup failures now include the readiness manifest path in the thrown
  message so failed lanes are inspectable without scraping the whole terminal
  transcript.
- `wait-for-driver.ps1` now classifies Android system startup blockers when
  the app is not foreground:
  - runtime permission dialog,
  - launcher/home surface,
  - ANR dialog,
  - other Android system overlays.

### Verification

- `./tools/test-sync-soak-harness.ps1` passed:
  22 test files, all assertions green.

### Remaining

- The next four-device proof should use the new startup readiness manifest as
  the first artifact to inspect.
- The next implementation slice should make the persona readiness/sign-in flow
  consume the same typed readiness result before and after sign-in, so a lane
  with credentials typed but no completed session is classified instead of
  being treated like a generic login failure.
