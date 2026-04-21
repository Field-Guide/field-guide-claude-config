# State Harness

This note documents the sync-soak state harness surface added in the 2026-04-19
decomposition/state-machine refactor.

## Snapshot Schema

`GET /diagnostics/device_state` returns schema version `1` and aggregates four
read-only regions:

- `ui`: current route, screen contract, sentinel key, modal/loading/focus hints.
- `app`: lifecycle, auth/session/company role, active wizards, network hints.
- `data`: local DB readiness, schema version, seeded timestamp, bounded row
  counts, pending migrations.
- `sync`: `SyncStatus`, phase, pending queue counts, conflict count, per-table
  sync metadata.

The snapshot introduces no mutable state. It only reads existing owners.

## Sentinels

Use typed sentinels for acceptance gates:

- `Assert-SoakRouteSentinel` for route + root key.
- `Assert-SoakNoUndismissedConflictsSentinel` for conflict-log closeout.
- `Assert-EventuallyDevicePosture` for stable device readiness.

Eventually semantics are:

- `-AtMostMs`: total deadline.
- `-PollIntervalMs`: polling cadence.
- `-DuringMs`: stability window after the first matching posture.

## DevicePosture

`DevicePosture` is derived, never stored. Add a new posture by updating:

- `lib/core/driver/device_state_machine.dart`
- `test/core/driver/device_state_machine_test.dart`
- `tools/sync-soak/DevicePosture.ps1`
- `tools/sync-soak/tests/DevicePosture.Tests.ps1`

## Typed Keys

`tools/gen-keys/keys.yaml` is the single source for test key IDs. Regenerate
with:

```powershell
dart run .\tools\gen-keys\generate_keys.dart
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\gen-keys\verify-idempotent.ps1
```

Generated outputs:

- `lib/shared/testing_keys/generated/keys.g.dart`
- `tools/sync-soak/generated/Keys.ps1`
- `tools/sync-soak/generated/keys.json`

## Log Assertions

`tools/sync-soak/LogAssertions.ps1` evaluates evidence bundles with fatal rules:

- `no_global_key_duplicate`
- `no_flutter_error_widget`
- `no_unhandled_exception`
- `no_rls_denial_42501`
- `no_sync_control_stuck_pulling`

Unallowed `loggingGaps` are fatal. Use an explicit allowed-gap list only with a
documented reason in the flow.

## Orchestrator Invariants

`tools/sync-soak/OrchestratorStateMachine.ps1` owns cross-device invariants.
The first reference invariant is project convergence: after a project is
created on one actor, every actor must observe the project locally within the
convergence window.

## Timeline

`tools/sync-soak/Timeline.ps1` merges actor transition JSON, orchestrator
transition JSON, and evidence summaries into:

- `timeline.json`
- `timeline.html`

Each event carries `actorId`, `transitionIndex`, UTC timestamps, pass/fail
state, and a source artifact link.

## GlobalKey Audit

Current remaining `GlobalKey` sites are intentional state/scroll anchors, not
testing IDs:

- `lib/features/entries/presentation/screens/entry_editor_state_mixin.dart`
- `lib/features/forms/presentation/screens/mdot_hub_screen_widgets.dart`
- `lib/features/forms/presentation/screens/mdot_1126_form_screen.dart`

Do not add new `GlobalKey` sites for test targeting. Add typed keys to the
generated catalog instead.
