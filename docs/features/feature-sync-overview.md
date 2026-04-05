---
feature: sync
type: overview
scope: Cloud Synchronization & Multi-Backend Support
updated: 2026-04-05
---

# Sync Feature Overview

## Purpose

The sync feature keeps the app SQLite-first while reconciling local changes
with Supabase when connectivity and auth context are available.

Primary goals:
- never lose offline work
- keep foreground sync fast by default
- make failures visible instead of silent
- keep transport state and diagnostics independently inspectable

## Core Behavior

### Sync Modes

- `quick`: push local changes and pull only dirty scopes when possible
- `full`: broader recovery/manual refresh path
- `maintenance`: deferred integrity/cleanup work

### Transport vs Diagnostics

- `SyncStatus` is the live transport-state model
- `SyncDiagnosticsSnapshot` is the dashboard/debug snapshot model
- `SyncEvent` is the transient lifecycle/event stream

### Public Entry Points

- `SyncCoordinator` is the application-layer sync entry point
- `SyncProvider` is the presentation-layer consumer for transport state and
  user-triggered sync actions
- `SyncQueryService` serves dashboard diagnostics reads

## Key Files

### Application

| File | Purpose |
|------|---------|
| `lib/features/sync/application/sync_coordinator.dart` | Main sync coordinator; replaces `SyncOrchestrator` |
| `lib/features/sync/application/sync_query_service.dart` | Typed diagnostics query surface |
| `lib/features/sync/application/sync_lifecycle_manager.dart` | Startup/resume lifecycle triggers |
| `lib/features/sync/application/background_sync_handler.dart` | Background callback entry point |
| `lib/features/sync/application/fcm_handler.dart` | Background invalidation hint handling |
| `lib/features/sync/application/realtime_hint_handler.dart` | Foreground invalidation hint handling |

### Engine

| File | Purpose |
|------|---------|
| `lib/features/sync/engine/sync_engine.dart` | Slim engine coordinator |
| `lib/features/sync/engine/push_handler.dart` | Push orchestration |
| `lib/features/sync/engine/pull_handler.dart` | Pull orchestration |
| `lib/features/sync/engine/local_sync_store.dart` | SQLite sync boundary |
| `lib/features/sync/engine/supabase_sync.dart` | Remote sync boundary |
| `lib/features/sync/engine/integrity_checker.dart` | Drift detection / cursor reset logic |
| `lib/features/sync/engine/sync_error_classifier.dart` | Error classification source of truth |

### Presentation

| File | Purpose |
|------|---------|
| `lib/features/sync/presentation/providers/sync_provider.dart` | UI-facing sync state/actions |
| `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` | Diagnostics dashboard |
| `lib/features/sync/presentation/screens/conflict_viewer_screen.dart` | Conflict review UI |

## Data Flow

```text
Local write
  -> SQLite trigger
  -> change_log row
  -> next sync cycle pushes change

Remote change hint
  -> RealtimeHintHandler / FcmHandler
  -> dirty scope
  -> quick sync follow-up
```

Diagnostics flow:

```text
SQLite sync metadata / change_log / conflict_log
  -> LocalSyncStore queries
  -> SyncQueryService
  -> SyncDiagnosticsSnapshot
  -> SyncDashboardScreen
```

## Offline / Recovery Behavior

- local writes remain queued until sync succeeds
- quick sync is the normal catch-up path
- full sync is the explicit recovery path
- stale/offline resume logic lives in `SyncLifecycleManager`
- retry/backoff logic lives in `SyncRetryPolicy`
- lock contention and auth-context gaps must surface as explicit failures

## Invalidation Strategy

- foreground: opaque per-device Supabase hint channels
- background/closed: FCM data messages
- fallback: manual full sync remains available from app chrome/dashboard

## Reference Docs

- `.claude/docs/features/feature-sync-architecture.md`
- `.claude/docs/guides/implementation/sync-architecture.md`
- `.claude/rules/sync/sync-patterns.md`
