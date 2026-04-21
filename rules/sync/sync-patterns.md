---
paths:
  - "lib/features/sync/**/*.dart"
---

# Sync Invariants

- `change_log` is trigger-owned. Never insert into it manually and do not reintroduce `sync_status`.
- Trigger suppression must be restored in `finally`; never leave `sync_control.pulling` stuck on.
- `SyncErrorClassifier` is the only owner of sync error classification.
- `SyncStatus` is the single source of truth for transport state.
- Driver sync inspection uses `GET /diagnostics/device_state` as the canonical
  read-only snapshot. It aggregates UI, app, data, and sync regions without
  introducing mutable state.
- Harness sentinels should assert stable state through typed keys and
  `DevicePosture`/`Assert-EventuallyDevicePosture` before falling back to raw
  route or widget probes.
- Testing key IDs live in `tools/gen-keys/keys.yaml` and generated Dart/
  PowerShell/JSON outputs. Do not hand-write raw `Key('...')` testing IDs in
  `lib/` outside `lib/shared/testing_keys/generated/keys.g.dart`.
- Cross-device sync evidence must include orchestrator/timeline artifacts when
  a flow uses multi-actor invariants.
- `SyncRegistry` ordering is load-bearing for dependency-safe push and pull behavior.
- Treat `is_builtin=1` rows as server-seeded data with the existing sync skips intact.
- Use `SyncCoordinator`; do not revive `SyncOrchestrator` or other parallel coordinators.
- Push-side sync hints must flow through `SyncHintRemoteEmitter`.
- Client-side sync-hint subscription ownership stays inside `RealtimeHintHandler`.
- Client Dart code must not call raw Realtime broadcast HTTP endpoints.
