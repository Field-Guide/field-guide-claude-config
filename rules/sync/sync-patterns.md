---
paths:
  - "lib/features/sync/**/*.dart"
---

# Sync Invariants

- `change_log` is trigger-owned. Never insert into it manually and do not reintroduce `sync_status`.
- Trigger suppression must be restored in `finally`; never leave `sync_control.pulling` stuck on.
- `SyncErrorClassifier` is the only owner of sync error classification.
- `SyncStatus` is the single source of truth for transport state.
- `SyncRegistry` ordering is load-bearing for dependency-safe push and pull behavior.
- Treat `is_builtin=1` rows as server-seeded data with the existing sync skips intact.
- Use `SyncCoordinator`; do not revive `SyncOrchestrator` or other parallel coordinators.
- Push-side sync hints must flow through `SyncHintRemoteEmitter`.
- Client-side sync-hint subscription ownership stays inside `RealtimeHintHandler`.
- Client Dart code must not call raw Realtime broadcast HTTP endpoints.
