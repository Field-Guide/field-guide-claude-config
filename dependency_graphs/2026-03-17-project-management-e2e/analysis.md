# Dependency Graph: Project Management E2E Fix

## Direct Changes

### 1. lib/main.dart (lines 590-780)
- **Change**: Add `Provider<SyncOrchestrator>.value(value: syncOrchestrator)` to MultiProvider tree
- **Type**: ADD (1 line)
- **Risk**: LOW — additive only

### 2. lib/features/auth/data/models/user_role.dart (lines 5-52)
- **Change**: Remove `viewer` enum value, update `displayName`, update `fromString`
- **Type**: MODIFY
- **Risk**: LOW — `canWrite` kept, `fromString('viewer')` already defaults to inspector

### 3. lib/features/auth/presentation/providers/auth_provider.dart (lines 172-184)
- **Change**: Add `canCreateProject`, `canDeleteProject()`, `canEditProject()`. Keep `canWrite`/`isViewer`.
- **Type**: ADD
- **Risk**: LOW — additive only, no existing code changes

### 4. lib/features/sync/engine/sync_engine.dart
- **_pullTable()** (lines 1082-1088): REMOVE auto-enrollment insert into synced_projects
- **_pull()** (lines 977-981): REMOVE _loadSyncedProjectIds() reload after projects adapter
- **_handlePushError()** (lines 824-920): ADD Logger calls for each error category
- **pushAndPull()** (line 164-242): ADD push/pull result summary logging
- **_push()** (line 273-392): ADD push result summary logging
- **Type**: MODIFY + REMOVE
- **Risk**: MEDIUM — removing BLOCKER-38 code reverses recent fix, but intentional per spec

### 5. lib/features/projects/presentation/screens/project_list_screen.dart (lines 17-692)
- **Change**: Major rewrite — two-section layout, download confirmation dialog, role-based permissions, failed import state, long-press admin delete for remote-only
- **Type**: REWRITE
- **Risk**: HIGH — most complex UI change

### 6. lib/features/projects/presentation/providers/project_provider.dart
- **fetchRemoteProjects()** (lines 444-465): REMOVE Supabase query, replace with local SQLite query
- **_buildMergedView()** (lines 472-500): MODIFY to source from local SQLite
- **Add**: `myProjects`, `availableProjects` computed lists
- **Type**: MODIFY
- **Risk**: MEDIUM

### 7. lib/features/projects/data/services/project_lifecycle_service.dart
- **Add**: `deleteFromSupabase()` method for admin remote-only delete
- **Add**: Logging for each step in removeFromDevice()
- **Add**: canDeleteFromDatabase() logging
- **Type**: ADD + MODIFY
- **Risk**: LOW

### 8. lib/services/soft_delete_service.dart (lines 50-140)
- **cascadeSoftDeleteProject()**: ADD synced_projects cleanup after soft-delete
- **Type**: MODIFY
- **Risk**: LOW — additive within existing transaction

### 9. lib/features/projects/presentation/screens/project_setup_screen.dart
- **_saveProject()** (lines 759-893): ADD immediate push after save (fire-and-forget with offline check)
- **_handleBackNavigation()** (lines 223-230): REPLACE with draft save/discard prompt
- **Type**: MODIFY
- **Risk**: MEDIUM — changes creation flow

### 10. lib/features/sync/presentation/providers/sync_provider.dart
- **_setupListeners()**: ADD ProjectSyncHealthProvider.updateCounts() call after sync
- **Type**: MODIFY
- **Risk**: LOW

### 11. lib/features/auth/data/models/user_profile.dart (line 64)
- **canWrite**: Keep as-is (returns true for all non-viewer roles)
- **Type**: NO CHANGE (viewer removal makes it always true)

### 12. Supabase Migrations (3 new files)
- `20260317100000_remove_viewer_role.sql`: Convert viewer→inspector, update CHECK, update RPCs
- `20260317100001_admin_soft_delete_rpc.sql`: Create admin_soft_delete_project() RPC
- `20260317100002_inspector_delete_guard.sql`: Update projects UPDATE WITH CHECK for inspector
- **Type**: CREATE
- **Risk**: MEDIUM — RLS changes affect live database

## Dependent Files (callers — NOT modified, but affected)

| File | Dependency | Impact |
|------|-----------|--------|
| `lib/features/contractors/presentation/providers/contractor_provider.dart` | `canWrite` callback | NO CHANGE — canWrite kept, returns true |
| `lib/features/contractors/presentation/providers/equipment_provider.dart` | `canWrite` callback | NO CHANGE |
| `lib/features/contractors/presentation/providers/personnel_type_provider.dart` | `canWrite` callback | NO CHANGE |
| `lib/features/entries/presentation/providers/daily_entry_provider.dart` | `canWrite` callback | NO CHANGE |
| `lib/features/entries/presentation/screens/entries_list_screen.dart` | `authProvider.canWrite` | NO CHANGE |
| `lib/features/entries/presentation/screens/entry_editor_screen.dart` | `authProvider.canWrite` | NO CHANGE |
| `lib/features/entries/presentation/screens/home_screen.dart` | `authProvider.canWrite` | NO CHANGE |
| `lib/features/calculator/presentation/providers/calculator_provider.dart` | `canWrite` callback | NO CHANGE |
| `lib/features/sync/application/sync_orchestrator.dart` | Consumed by new Provider registration | NO CHANGE to file |
| `lib/features/sync/presentation/screens/project_selection_screen.dart` | synced_projects enrollment | May need review (manual toggle screen) |

## Test Files

| Test File | What It Tests | Action |
|-----------|-------------|--------|
| `test/features/sync/engine/sync_engine_test.dart` | Sync engine push/pull | UPDATE — add mock-Supabase tests, error category tests |
| `test/features/projects/data/services/project_lifecycle_service_test.dart` | Lifecycle service | UPDATE — add deleteFromSupabase, photo cleanup tests |
| `test/features/projects/presentation/screens/project_list_screen_test.dart` | Project list UI | UPDATE — sections, download dialog, role tests |
| `test/features/projects/integration/project_lifecycle_integration_test.dart` | Integration | UPDATE — import→enroll→sync cycle |
| `test/features/sync/engine/conflict_resolver_test.dart` | Conflict resolver | NO CHANGE |
| `test/features/sync/presentation/providers/sync_provider_test.dart` | SyncProvider | UPDATE — RLS denial toast test |
| `test/features/projects/presentation/providers/project_provider_merged_view_test.dart` | Merged view | UPDATE — myProjects/availableProjects from SQLite |

## Data Flow

```
User Action                    Provider              Service/Engine          Storage
─────────────────────────────────────────────────────────────────────────────────────
Tap Download (Available)  →  ProjectImportRunner  →  enrollProject()     →  synced_projects INSERT
                          →  SyncOrchestrator     →  pushAndPull()       →  Pull child data
                          →  ProjectProvider      →  refresh sections    →  SQLite query

Tap New Project (FAB)     →  ProjectSetupScreen   →  _insertDraftProject →  projects INSERT (suppressed)
Save Project              →  ProjectProvider      →  updateProject()     →  change_log trigger
                          →  enrollProject()      →  synced_projects INSERT
                          →  SyncOrchestrator     →  syncLocalAgencyProjects() (fire-and-forget)

Long-press (My Project)   →  _showDeleteSheet()   →  Remove from Device  →  removeFromDevice() + photo delete
                                                  →  Delete from DB      →  cascadeSoftDeleteProject() + synced_projects DELETE

Long-press (Available)    →  Admin: delete dialog  →  deleteFromSupabase() →  Supabase RPC
  [admin only]            →  Refresh list          →  Remove from local projects table

Background Sync Pull      →  SyncEngine._pull()    →  _pullTable()       →  projects INSERT (NO auto-enroll)
                                                                          →  Child data ONLY for enrolled
```

## Blast Radius Summary

| Category | Count |
|----------|-------|
| Direct file changes | 12 files (10 Dart + 2-3 SQL migrations) |
| Dependent files (no change needed) | 10 files |
| Test files to update | 7 files |
| New test files | 2-3 (mock Supabase, photo push) |
| Total files touched | ~22-25 |
