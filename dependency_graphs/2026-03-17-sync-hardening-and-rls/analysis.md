# Dependency Graph: Sync Hardening & RLS Enforcement

**Date**: 2026-03-17
**Scope**: BLOCKER-38, BLOCKER-39, + 10 proactive sync audit findings

## Direct Changes

### 1. sync_engine.dart (MAJOR — 8 fixes)
- `_pullTable()` :1037-1042 — Add synced_projects enrollment after project insert
- `_pull()` :915-975 — Reload _syncedProjectIds after projects adapter completes
- `_push()` :259-365 — Implement per-record FK blocking (replace table-level)
- `_pushUpsert()` :475-485 — Extend company_id stamping to child records
- `_pullTable()` :1040 — Log when ConflictAlgorithm.ignore silently drops insert
- `_pullTable()` :1079-1084 — Add conflict ping-pong circuit breaker
- `_loadSyncedProjectIds()` :1138-1148 — Already filters deleted_at IS NULL (verified OK)
- `pushAndPull()` :158-229 — Document pulling=1 crash recovery (comment only)

### 2. Supabase migration (NEW FILE)
- `supabase/migrations/20260317000000_enable_rls_core_tables.sql`
  - ENABLE ROW LEVEL SECURITY on 8 tables
  - Replace USING(true) policies on personnel_types, entry_personnel_counts, entry_personnel
  - Add performance indexes on project_id/contractor_id for 6 tables

### 3. project_lifecycle_service.dart :70-222
- `removeFromDevice()` — Block removal when offline + unsyncedCount > 0

### 4. project_list_screen.dart :93-130
- `_showDeleteSheet()` — Enforce hard block on unsynced removal when offline

### 5. conflict_resolver.dart :26-78
- `resolve()` — Add per-record conflict counter, circuit breaker after N consecutive local-wins

### 6. change_tracker.dart
- Add `getConflictCount()` method for per-record conflict tracking
- Add `incrementConflictCount()` method

### 7. sync_engine_tables.dart :5-195
- Add `conflict_count` column to conflict_log (or new table) for ping-pong detection

## Dependent Files (callers/consumers)

| File | Relationship |
|------|-------------|
| `sync_orchestrator.dart` | Calls pushAndPull(), receives SyncEngineResult |
| `sync_provider.dart` | Exposes error state to UI, has SyncErrorToastCallback |
| `sync_lifecycle_manager.dart` | Triggers sync on resume, calls orchestrator |
| `project_provider.dart` | Calls _buildMergedView(), fetchRemoteProjects() |
| `sync_section.dart` | Displays sync errors via _friendlyErrorMessage() |
| `conflict_viewer_screen.dart` | Reads conflict_log, may need conflict_count display |

## Test Files

| File | What it tests |
|------|--------------|
| `test/features/sync/engine/sync_engine_test.dart` | Core push/pull logic |
| `test/features/sync/engine/change_tracker_test.dart` | Change tracking |
| `test/features/sync/engine/conflict_resolver_test.dart` | Conflict resolution |
| `test/features/projects/data/services/project_lifecycle_service_test.dart` | Lifecycle ops |

## Data Flow Diagram

```
[Supabase] --pull--> [SyncEngine._pullTable()]
                          |
                          +-- INSERT INTO projects (existing)
                          +-- INSERT INTO synced_projects (NEW - BLOCKER-38 fix)
                          |
                          +-- Reload _syncedProjectIds (NEW - stale cache fix)
                          |
                          +-- Child adapters now see new project IDs
                          |
[SyncEngine._push()] --per-record FK check--> [ChangeTracker.hasFailedRecord()]
                          |                        (NEW - replaces table-level check)
                          |
                          +-- company_id stamp on ALL tables with company_id column
                          |
                          +-- ConflictAlgorithm.ignore logging
                          |
[ConflictResolver.resolve()] --conflict count--> circuit breaker after N repeats
                          |
[ProjectLifecycleService.removeFromDevice()] --block if offline + unsynced-->
                          |
[Supabase RLS] --ENABLE ROW LEVEL SECURITY--> 8 core tables enforced
               --Replace USING(true)--> 3 tables get company-scoped policies
               --Add indexes--> 6 tables get project_id/contractor_id indexes
```

## Blast Radius Summary

| Category | Count |
|----------|-------|
| Direct changes | 7 files (1 new migration) |
| Dependent files | 6 files (read-only impact) |
| Test files | 4 files (need updates) |
| Cleanup | 0 files |

## Verified Non-Issues

- **Audit #4 (trigger coverage)**: 16 triggered tables match 16 registered adapters exactly. `user_certifications` is synced via separate `UserProfileSyncDatasource`, not the engine. No gap.
- **Audit #9 (soft-deleted contractors)**: `_loadSyncedProjectIds()` already filters `deleted_at IS NULL` at line 1144. Verified OK.
- **Audit #7 (pulling=1 crash recovery)**: `pushAndPull()` resets pulling=0 at entry (line 160). `resetState()` also resets. Low risk — document explicitly.
