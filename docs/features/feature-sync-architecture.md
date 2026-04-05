---
feature: sync
type: architecture
scope: Cloud Synchronization & Multi-Backend Support
updated: 2026-04-05
---

# Sync Feature Architecture

## Current Shape

The sync system is organized into four explicit layers:

```text
Presentation
  SyncProvider
  SyncDashboardScreen / ConflictViewerScreen
  SyncStatusIcon / dashboard widgets

Application
  SyncCoordinator
  SyncLifecycleManager
  SyncRetryPolicy / ConnectivityProbe / SyncTriggerPolicy / PostSyncHooks
  SyncQueryService
  BackgroundSyncHandler / FcmHandler / RealtimeHintHandler

Engine
  SyncEngine
  PushHandler / PullHandler / MaintenanceHandler
  LocalSyncStore / SupabaseSync / FileSyncHandler
  EnrollmentHandler / FkRescueHandler / SyncErrorClassifier
  ChangeTracker / ConflictResolver / IntegrityChecker / DirtyScopeTracker
  SyncMutex / SyncStatusStore / SyncRunLifecycle / SyncRegistry

Adapters + Domain
  AdapterConfig + simple adapter registry
  complex adapter classes
  SyncResult / SyncStatus / SyncDiagnosticsSnapshot / SyncEvent / SyncMode
```

The detailed implementation guide is:
- `.claude/docs/guides/implementation/sync-architecture.md`

## Application Layer

### SyncCoordinator

`lib/features/sync/application/sync_coordinator.dart`

This is the top-level sync entry point. It replaces `SyncOrchestrator`.

Responsibilities:
- accept foreground sync requests
- resolve runtime auth/context before engine creation
- run retry/backoff policy
- schedule background retry after retry exhaustion
- run post-sync hooks after successful full/maintenance work
- expose a single transport-state stream through `SyncStatusStore`

It must not:
- run SQL queries directly
- own dashboard diagnostics assembly
- duplicate error classification logic

### SyncQueryService

`lib/features/sync/application/sync_query_service.dart`

This is the typed diagnostics surface for dashboard/query reads.

Responsibilities:
- pending bucket counts
- integrity metadata reads
- undismissed conflict counts
- persisted `last_sync_time`
- `SyncDiagnosticsSnapshot` assembly

If diagnostics metadata is malformed, it must fail explicitly instead of
silently dropping rows.

### Lifecycle / Background

- `SyncLifecycleManager` decides startup/resume trigger behavior.
- `BackgroundSyncHandler` runs background entrypoints.
- `FcmHandler` and `RealtimeHintHandler` convert remote invalidation hints into
  dirty scopes / follow-up sync requests.

## Engine Layer

### SyncEngine

`lib/features/sync/engine/sync_engine.dart`

`SyncEngine` is now a slim coordinator. It owns:
- mutex acquisition / release
- run lifecycle checkpoints
- mode routing (`quick`, `full`, `maintenance`)
- last-success persistence only after a truly successful cycle

It delegates all real work to extracted collaborators.

### I/O Boundaries

- `LocalSyncStore`: SQLite sync boundary
- `SupabaseSync`: remote row/storage boundary

These remain under `features/sync/engine/` as an approved sync-specific
exception to the generic feature data-layer rule.

### Handlers

- `PushHandler`: `change_log` → FK-ordered remote writes
- `PullHandler`: scoped per-table pull orchestration
- `FileSyncHandler`: storage upload/download flow
- `MaintenanceHandler`: integrity/orphan/cleanup work
- `EnrollmentHandler`: assignment-driven project enrollment
- `FkRescueHandler`: missing-parent recovery

### Core Shared Services

- `SyncErrorClassifier`: single error classification source of truth
- `SyncMutex`: cross-owner lock + stale-lock recovery
- `SyncStatusStore`: shared transport-state store
- `SyncRunLifecycle`: status/event emission around a sync cycle
- `IntegrityChecker`: drift detection with cursor reset guardrails

## Adapters

Simple tables are registered through `AdapterConfig` data rather than
one-class-per-table boilerplate. Complex tables remain class-backed where
custom validation, conversion, storage, or scope logic still matters.

Key invariants:
- registry order is FK order
- adapter metadata declares FK dependencies and scope rules
- file adapters keep storage-specific behavior out of `SyncEngine`

## Status vs Diagnostics

The refactor intentionally split sync state into three shapes:

- `SyncStatus`: live transport state for provider/UI status badges
- `SyncDiagnosticsSnapshot`: point-in-time operational diagnostics
- `SyncEvent`: transient lifecycle events emitted during a run

`SyncStatusStore` is the transport-state source of truth. Dashboard diagnostics
must come from `SyncQueryService`, not ad hoc SQL or duplicated provider state.

## Operation Flow

```text
SyncProvider / lifecycle / background trigger
  -> SyncCoordinator
  -> ConnectivityProbe + SyncRetryPolicy
  -> SyncEngineResolver creates SyncEngine
  -> SyncEngine
     -> PushHandler
     -> PullHandler
     -> MaintenanceHandler (when applicable)
  -> SyncRunLifecycle emits status/events
  -> SyncStatusStore updates transport state
  -> SyncQueryService serves diagnostics reads
```

## Invalidation Model

Foreground invalidation uses opaque per-device channels from
`register_sync_hint_channel()`. Background/closed-app invalidation uses FCM.
Quick sync consumes dirty scopes; full sync remains the explicit safety-net
path for broad recovery.

## Verification Bar

The intended verification model for sync is:
- characterization tests for legacy behavior contracts
- contract/isolation tests for extracted engine and application classes
- widget/provider tests for transport and diagnostics surfaces
- full sync test suite green with no silent failure paths

## Key Files

- `lib/features/sync/application/sync_coordinator.dart`
- `lib/features/sync/application/sync_query_service.dart`
- `lib/features/sync/engine/sync_engine.dart`
- `lib/features/sync/engine/local_sync_store.dart`
- `lib/features/sync/engine/supabase_sync.dart`
- `lib/features/sync/domain/sync_status.dart`
- `lib/features/sync/domain/sync_diagnostics.dart`
- `.claude/rules/sync/sync-patterns.md`
- `.claude/docs/guides/implementation/sync-architecture.md`
