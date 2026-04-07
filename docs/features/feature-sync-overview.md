---
feature: sync
type: overview
scope: Cloud Synchronization & Multi-Backend Support
updated: 2026-04-07
---

# Sync Feature Overview

## Purpose

The sync feature keeps the app SQLite-first while reconciling local changes
with Supabase when connectivity and auth context are available.

Primary goals:
- never lose offline work
- keep foreground sync fast by default
- make failures visible instead of silent
- keep transport state, diagnostics, and UI verification independently inspectable

## Public Entry Points

- `SyncCoordinator` is the application-layer sync entry point
- `SyncProvider` is the presentation-layer transport state and action surface
- `SyncQueryService` serves diagnostics reads
- `screen_registry.dart`, `screen_contract_registry.dart`, and `flow_registry.dart`
  expose the UI surface to the sync driver
- `/diagnostics/screen_contract` exposes the active route + screen contract payload

## Key Files

| File | Purpose |
|------|---------|
| `lib/features/sync/application/sync_coordinator.dart` | Main sync coordinator |
| `lib/features/sync/application/sync_query_service.dart` | Typed diagnostics query surface |
| `lib/features/sync/presentation/providers/sync_provider.dart` | UI-facing sync state and actions |
| `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` | Diagnostics dashboard |
| `lib/features/sync/presentation/screens/conflict_viewer_screen.dart` | Conflict review UI |
| `lib/core/driver/screen_registry.dart` | Bootstrappable screen builders |
| `lib/core/driver/screen_contract_registry.dart` | Stable screen verification contracts |
| `lib/core/driver/flow_registry.dart` | Declarative sync/UI journeys |
| `lib/core/driver/driver_diagnostics_handler.dart` | Diagnostics endpoints including `/diagnostics/screen_contract` |

## Verification Model

Sync verification now relies on:
- provider/widget tests
- declarative driver flows
- stable testing keys
- screen contracts

It should not rely on widget-tree archaeology or implicit route assumptions.
