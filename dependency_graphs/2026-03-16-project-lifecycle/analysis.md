# Dependency Graph: Project Lifecycle Management + Logger Migration

## PR1: Project Lifecycle

### Direct Changes

#### Schema / Database
| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/core/database/schema/sync_engine_tables.dart` | `SyncEngineTables` | 5-154 | MODIFY — add `project_id` column to `createChangeLogTable`, add index |
| `lib/core/database/database_service.dart` | `DatabaseService._onUpgrade` | 247-1560 | MODIFY — add migration to ALTER TABLE change_log ADD COLUMN project_id |
| `supabase/migrations/20260316000000_tighten_project_delete_rls.sql` | — | NEW | CREATE — new RLS migration for project soft-delete gate |

#### Triggers (change_log project_id population)
| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/core/database/schema/sync_engine_tables.dart` | `SyncEngineTables.triggersForTable` | 126-152 | MODIFY — INSERT/UPDATE triggers populate project_id column |

#### Data Layer — New
| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/features/projects/data/services/project_lifecycle_service.dart` | `ProjectLifecycleService` | NEW | CREATE — import, remove from device, delete from database |
| `lib/features/projects/presentation/providers/project_sync_health_provider.dart` | `ProjectSyncHealthProvider` | NEW | CREATE — cached Map<String,int> pending counts |

#### Data Layer — Modify
| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/features/projects/presentation/providers/project_provider.dart` | `ProjectProvider` | 12-387 | MODIFY — add merged local+remote project loading, unsynced detection |
| `lib/features/projects/data/repositories/project_repository.dart` | `ProjectRepository` | 11-170 | MODIFY — may need method for child table hard-delete |
| `lib/services/soft_delete_service.dart` | `SoftDeleteService.cascadeSoftDeleteProject` | 50-107 | MODIFY — add change_log/conflict_log cleanup |

#### Presentation Layer — Modify
| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_ProjectListScreenState` | 19-643 | MAJOR REWRITE — merged view, sync status icons, new delete bottom sheet, import action |
| `lib/features/settings/presentation/screens/settings_screen.dart` | `_SettingsScreenState.build` | 126-343 | MODIFY — remove "Manage Synced Projects" tile (lines ~199-203) |
| `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` | `_SyncDashboardScreenState._buildActionsSection` | 242-269 | MODIFY — make "Manage Synced Projects" link read-only |
| `lib/features/sync/presentation/screens/project_selection_screen.dart` | `_ProjectSelectionScreenState` | 22+ | MODIFY — add read-only mode flag |

#### Presentation Layer — New
| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/features/projects/presentation/widgets/project_import_banner.dart` | `ProjectImportBanner` | NEW | CREATE — import progress banner |
| `lib/features/projects/presentation/widgets/project_delete_sheet.dart` | `ProjectDeleteSheet` | NEW | CREATE — two-checkbox delete bottom sheet |
| `lib/features/projects/presentation/providers/project_import_runner.dart` | `ProjectImportRunner` | NEW | CREATE — ChangeNotifier for import state machine |

#### Router
| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/core/router/app_router.dart` | `AppRouter._buildRouter` | 125-622 | MODIFY — keep project-selection route, wire banner into shell |

#### Main
| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/main.dart` | — | — | MODIFY — register ProjectSyncHealthProvider, ProjectImportRunner |

### PR2: Logger Migration

#### Logger Enhancement
| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/core/logging/logger.dart` | `Logger._log` | 482-532 | MODIFY — add release-only file transport scrubbing |
| `lib/core/logging/logger.dart` | `Logger._isSensitiveKey` | 772-781 | MODIFY — add construction-domain PII keys |
| `lib/core/logging/logger.dart` | `Logger._sendHttp` | 686-756 | MODIFY — scrub before truncation check |
| `lib/core/logging/logger.dart` | `Logger._doInit` | 251-344 | MODIFY — add log retention (14 days, 50MB cap) |

#### DebugLogger Migration (22 files)
| Category | Files |
|----------|-------|
| Sync (6) | `sync_engine.dart`, `sync_orchestrator.dart`, `sync_lifecycle_manager.dart`, `change_tracker.dart`, `orphan_scanner.dart`, `integrity_checker.dart` |
| PDF (5) | `extraction_pipeline.dart`, `post_processor_v2.dart`, `pdf_import_service.dart`, `pdf_import_helper.dart` (already in `lib/features/pdf/presentation/helpers/`), `grid_line_remover.dart` |
| Database (2) | `database_service.dart`, `schema_verifier.dart` |
| Services (3) | `soft_delete_service.dart`, `startup_cleanup_service.dart`, `storage_cleanup.dart` |
| Projects (2) | `project_repository.dart`, `project_local_datasource.dart` |
| Quantities (2) | `bid_item_provider.dart`, `budget_sanity_checker.dart` |
| Shared (1) | `generic_local_datasource.dart` |

Note: `debug_logger.dart` itself is a thin wrapper and is NOT counted above.

#### debugPrint Migration (47 files)
See grep output — 47 files with `debugPrint` calls. Logger itself uses `_originalDebugPrint` which is excluded.

#### Deletion
| File | Change Type |
|------|-------------|
| `lib/core/logging/debug_logger.dart` | DELETE |
| `lib/core/logging/app_logger.dart` | DELETE |

---

## Dependent Files (callers, consumers — 2+ levels)

### ProjectProvider consumers
- `lib/features/projects/presentation/screens/project_list_screen.dart` (direct)
- `lib/features/projects/presentation/widgets/project_switcher.dart` (direct)
- `lib/features/dashboard/presentation/screens/project_dashboard_screen.dart` (reads selected project)
- `lib/features/entries/presentation/controllers/pdf_data_builder.dart` (reads project for PDF)
- `lib/main.dart` (registers provider)

### SyncOrchestrator consumers
- `lib/features/sync/application/sync_lifecycle_manager.dart` (manages lifecycle)
- `lib/features/sync/presentation/providers/sync_provider.dart` (wraps for UI)
- `lib/main.dart` (initializes)

### SoftDeleteService consumers
- `lib/features/projects/presentation/providers/project_provider.dart` (calls cascadeSoftDeleteProject)
- `lib/features/settings/presentation/screens/trash_screen.dart` (restore, purge)
- `lib/services/startup_cleanup_service.dart` (auto-purge)

### change_log consumers
- `lib/features/sync/engine/change_tracker.dart` (reads/writes)
- `lib/features/sync/engine/sync_engine.dart` (pushes changes)
- `lib/features/sync/application/sync_orchestrator.dart` (getPendingCount, getPendingBuckets)
- `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` (displays pending)
- `test/helpers/sync/sqlite_test_helper.dart` (test utils)

### ProjectSelectionScreen consumers
- `lib/features/settings/presentation/screens/settings_screen.dart` (navigates to)
- `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` (navigates to)
- `lib/core/router/app_router.dart` (route registration)

---

## Test Files

### Existing tests to update
- `test/features/projects/presentation/screens/project_list_screen_test.dart`
- `test/features/settings/presentation/screens/settings_screen_test.dart`
- `test/features/sync/presentation/screens/project_selection_screen_test.dart`
- `test/features/sync/engine/change_tracker_test.dart`
- `test/features/sync/schema/sync_queue_migration_test.dart`
- `test/helpers/sync/sqlite_test_helper.dart`

### New tests needed
- `test/features/projects/data/services/project_lifecycle_service_test.dart`
- `test/features/projects/presentation/providers/project_sync_health_provider_test.dart`
- `test/features/projects/presentation/providers/project_import_runner_test.dart`
- `test/features/projects/presentation/widgets/project_delete_sheet_test.dart`
- `test/features/projects/presentation/widgets/project_import_banner_test.dart`
- `test/core/logging/logger_release_scrub_test.dart`
- `test/core/logging/logger_retention_test.dart`

---

## Data Flow Diagram

```
                    ┌──────────────────────────┐
                    │    Supabase (Remote)      │
                    │  - projects table (RLS)   │
                    │  - stamp_deleted_by()     │
                    └─────────┬────────────────┘
                              │ Fetch metadata
                              │ (id, name, project_number, description, is_active)
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                   ProjectProvider (merged view)                   │
│  _localProjects + _remoteProjects → dedup by id → 3 states     │
│  synced | remote-only | local-only(error)                        │
└──────────┬──────────────────────────────────┬───────────────────┘
           │                                  │
     ┌─────▼──────┐                   ┌──────▼────────┐
     │ Import Flow │                   │  Delete Flow  │
     │ (tap card)  │                   │ (long-press)  │
     └─────┬──────┘                   └──────┬────────┘
           │                                  │
           ▼                                  ▼
  ┌──────────────────┐             ┌────────────────────────┐
  │ synced_projects   │             │ ProjectDeleteSheet      │
  │ INSERT + sync     │             │ □ Remove from device    │
  │ ProjectImportRunner│            │ □ Delete from database  │
  └────────┬─────────┘             └───────┬────────────────┘
           │                                │
           ▼                          ┌─────┴─────┐
  ┌─────────────────┐                 │           │
  │ SyncOrchestrator │          4A: Remove   4B: Soft-delete
  │ .syncLocal...()  │          from device  from database
  └─────────────────┘                 │           │
                                      ▼           ▼
                              ┌──────────┐  ┌───────────────┐
                              │ Hard-del  │  │ SoftDeleteSvc │
                              │ children  │  │ .cascadeSoft  │
                              │ + cleanup │  │ DeleteProject │
                              │ change_log│  │ + cleanup logs│
                              │ conflict_ │  └───────────────┘
                              │ log       │
                              │ photo file│
                              └──────────┘
```

---

## Blast Radius Summary

| Category | Count |
|----------|-------|
| **PR1 Direct changes** | 15 files (6 new, 9 modify) |
| **PR1 Dependent files** | ~12 files |
| **PR1 Test files** | 12 (6 existing, 6 new) |
| **PR2 Direct changes** | 72 files (22 DebugLogger + 47 debugPrint + 2 delete + 1 Logger modify) |
| **PR2 Test files** | 2 new |
| **Supabase migrations** | 1 new SQL file |
| **Total blast radius** | ~95 files |

---

## Key Source Excerpts (for plan-writer)

### change_log schema (current — NO project_id)
```sql
CREATE TABLE IF NOT EXISTS change_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  changed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
  processed INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,
  metadata TEXT
)
```

### Triggers (current — no project_id in INSERT)
```dart
static List<String> triggersForTable(String tableName) {
  return [
    '''CREATE TRIGGER IF NOT EXISTS trg_${tableName}_insert
    AFTER INSERT ON $tableName
    WHEN (SELECT value FROM sync_control WHERE key = 'pulling') = '0'
    BEGIN
      INSERT INTO change_log (table_name, record_id, operation)
      VALUES ('$tableName', NEW.id, 'insert');
    END''',
    // ... update and delete triggers similar
  ];
}
```

### Existing RLS policy (too permissive)
```sql
CREATE POLICY "company_projects_update" ON projects
  FOR UPDATE TO authenticated
  USING (company_id = get_my_company_id() AND NOT is_viewer());
```

### synced_projects table
```sql
CREATE TABLE IF NOT EXISTS synced_projects (
  project_id TEXT PRIMARY KEY,
  synced_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
)
```

### SyncEngine._loadSyncedProjectIds
```dart
Future<void> _loadSyncedProjectIds() async {
  final rows = await db.query('synced_projects');
  _syncedProjectIds = rows.map((r) => r['project_id'] as String).toList();
  // ... also loads contractor IDs
}
```

### SyncEngine._applyScopeFilter
```dart
PostgrestFilterBuilder _applyScopeFilter(query, adapter) {
  switch (adapter.scopeType) {
    case ScopeType.direct:
      return query.eq('company_id', companyId);
    case ScopeType.viaProject:
    case ScopeType.viaEntry:
      return query.inFilter('project_id', _syncedProjectIds);
    case ScopeType.viaContractor:
      return query.inFilter('contractor_id', _syncedContractorIds);
  }
}
```

### Existing _showLoadProjectDialog (current import — basic)
```dart
Future<void> _showLoadProjectDialog(Project project) async {
  // ... show dialog ...
  final db = await dbService.database;
  await db.insert('synced_projects', {
    'project_id': project.id,
    'synced_at': DateTime.now().toUtc().toIso8601String(),
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
  projectProvider.selectProject(project.id);
  context.goNamed('dashboard');
}
```

### Existing _showDeleteConfirmation (current — simple soft-delete only)
```dart
// Single "Move to Trash" dialog
// Calls provider.deleteProject(project.id)
// Which calls SoftDeleteService.cascadeSoftDeleteProject
```

### SoftDeleteService.cascadeSoftDeleteProject (current)
```dart
// Transaction: soft-delete children, equipment, entry junctions, project
// Tables: _projectChildTables + equipment + entry_contractors/equipment/personnel_counts/quantities
// Does NOT clean change_log or conflict_log
// Uses DebugLogger.db (needs migration)
```

### Settings "Manage Synced Projects" tile (line ~199-203)
```dart
ListTile(
  leading: const Icon(Icons.folder_shared_outlined),
  title: const Text('Manage Synced Projects'),
  subtitle: const Text('Choose which projects to sync locally'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/sync/project-selection'),
),
```

### SyncDashboard "Manage Synced Projects" action tile (line 263-265)
```dart
_buildActionTile(
  icon: Icons.folder_shared,
  title: 'Manage Synced Projects',
  subtitle: 'Choose which projects to sync',
  onTap: () => context.push('/sync/project-selection'),
),
```

### ExtractionBanner pattern (reference for ProjectImportBanner)
```dart
class ExtractionBanner extends StatefulWidget // line 17
// Uses ExtractionJobRunner (ChangeNotifier) for state
// Listens to runner, shows banner with progress
// AnimatedContainer for expand/collapse
```

### Project model fields
```dart
class Project {
  final String id;
  final String name;
  final String projectNumber;
  final String? clientName;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final ProjectMode mode;
  // ... MDOT fields ...
  final String? companyId;
  final String? createdByUserId;
}
```

### ProjectProvider.deleteProject (current)
```dart
Future<bool> deleteProject(String id) async {
  final softDeleteService = SoftDeleteService(DatabaseService());
  await softDeleteService.cascadeSoftDeleteProject(id, userId: _currentUserId);
  _projects.removeWhere((p) => p.id == id);
  // ... cleanup ...
}
```

### DatabaseService._onUpgrade (latest version marker)
See `database_service.dart:247` — need to find current DB version to add migration.

### Triggered tables list
```dart
static const List<String> triggeredTables = [
  'projects', 'locations', 'contractors', 'equipment', 'bid_items',
  'personnel_types', 'daily_entries', 'photos', 'entry_equipment',
  'entry_quantities', 'entry_contractors', 'entry_personnel_counts',
  'inspector_forms', 'form_responses', 'todo_items', 'calculation_history',
];
```

### Tables with direct project_id column
- `locations`, `contractors`, `bid_items`, `personnel_types`, `daily_entries`, `photos`, `todo_items`

### Tables without direct project_id (via join)
- `equipment` (via `contractors.project_id`)
- `entry_equipment`, `entry_quantities`, `entry_contractors`, `entry_personnel_counts` (via `daily_entries.project_id`)
- `inspector_forms`, `form_responses` (via daily_entries)
- `calculation_history` (no project scope)
- `projects` itself (IS the project)
