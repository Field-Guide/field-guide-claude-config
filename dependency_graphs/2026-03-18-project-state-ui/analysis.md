# Dependency Graph: Project State UI & Assignments

## Direct Changes

### NEW FILES (Create)

| File | Purpose | Agent |
|------|---------|-------|
| `supabase/migrations/20260319100000_create_project_assignments.sql` | Supabase migration: table + RLS + triggers + helper function + audit logging | backend-supabase-agent |
| `supabase/rollbacks/20260319100000_rollback.sql` | Rollback script | backend-supabase-agent |
| `lib/features/projects/data/models/project_assignment.dart` | ProjectAssignment model (id, project_id, user_id, assigned_by, company_id, assigned_at, updated_at) | backend-data-layer-agent |
| `lib/features/projects/data/repositories/project_assignment_repository.dart` | CRUD for project_assignments SQLite table | backend-data-layer-agent |
| `lib/features/sync/adapters/project_assignment_adapter.dart` | TableAdapter subclass: `ScopeType.direct`, no fkDependencies (root-level table) | backend-supabase-agent |
| `lib/features/projects/presentation/providers/project_assignment_provider.dart` | In-memory wizard state: loadForProject, toggleAssignment, save, isAssigned, assignedCount | frontend-flutter-specialist-agent |
| `lib/features/projects/presentation/widgets/assignments_step.dart` | Wizard step: searchable member list, checkboxes, role badges, creator locked, counter | frontend-flutter-specialist-agent |
| `lib/features/projects/presentation/widgets/project_tab_bar.dart` | 3-tab TabBar with badge counts | frontend-flutter-specialist-agent |
| `lib/features/projects/presentation/widgets/project_filter_chips.dart` | Company tab filter chips: All / On Device / Not Downloaded | frontend-flutter-specialist-agent |
| `lib/features/projects/presentation/widgets/removal_dialog.dart` | Multi-step removal flow: Sync & Remove / Delete from Device / Cancel | frontend-flutter-specialist-agent |
| `lib/features/projects/presentation/widgets/project_empty_state.dart` | Empty state with icon + message + CTA button | frontend-flutter-specialist-agent |

### MODIFIED FILES

| File | Lines | Change | Agent |
|------|-------|--------|-------|
| `lib/core/database/database_service.dart:53,79` | Version 36→37 | Add project_assignments table creation in _onCreate + _onUpgrade migration (new table + synced_projects.unassigned_at column + change_log triggers) | backend-data-layer-agent |
| `lib/core/database/schema/sync_engine_tables.dart:5-196` | Add createProjectAssignmentsTable constant, add to triggeredTables list | backend-data-layer-agent |
| `lib/features/sync/engine/sync_registry.dart:23-42` | Add ProjectAssignmentAdapter() to registration list (position: after projects, before locations) | backend-supabase-agent |
| `lib/features/sync/engine/sync_engine.dart:1022-1089` | Add onPullComplete callback invocation after each table's _pullTable call | backend-supabase-agent |
| `lib/features/sync/presentation/providers/sync_provider.dart:18-260` | Add pendingNotifications list, expose/clear after sync | backend-supabase-agent |
| `lib/features/projects/presentation/providers/project_provider.dart:14-547` | Add tab state (_currentTabIndex, CompanyFilter), computed lists (myProjects, companyProjects, archivedProjects), single-pass _buildMergedView, enroll/unenroll methods | frontend-flutter-specialist-agent |
| `lib/features/projects/data/models/merged_project_entry.dart:10-30` | Add isArchived getter, unassignedAt field | backend-data-layer-agent |
| `lib/features/projects/presentation/screens/project_list_screen.dart:20-897` | Major rewrite: 3-tab layout, tab bar, filter chips, empty states, updated card badges, removal dialog integration | frontend-flutter-specialist-agent |
| `lib/features/projects/presentation/screens/project_setup_screen.dart:38-849` | Add Assignments tab (5th tab), wire ProjectAssignmentProvider, save assignments on project save | frontend-flutter-specialist-agent |
| `lib/main.dart:525-750` | Register ProjectAssignmentProvider, wire pending notifications display | general-purpose |
| `lib/core/router/app_router.dart:125-625` | Remove /sync/project-selection route (lines ~616-625), audit all references | general-purpose |

### DELETE FILES

| File | Reason |
|------|--------|
| `lib/features/sync/presentation/screens/project_selection_screen.dart` | Legacy screen replaced by project_list_screen 3-tab layout (SC-14) |

### TEST FILES

| File | Type | Agent |
|------|------|-------|
| `test/features/projects/data/repositories/project_assignment_repository_test.dart` | NEW — unit test | qa-testing-agent |
| `test/features/projects/presentation/providers/project_assignment_provider_test.dart` | NEW — unit test | qa-testing-agent |
| `test/features/projects/presentation/providers/project_provider_tab_test.dart` | NEW — unit test for tab filtering | qa-testing-agent |
| `test/features/projects/presentation/widgets/assignments_step_test.dart` | NEW — widget test | qa-testing-agent |
| `test/features/projects/presentation/widgets/project_tab_bar_test.dart` | NEW — widget test | qa-testing-agent |
| `test/features/projects/presentation/widgets/removal_dialog_test.dart` | NEW — widget test | qa-testing-agent |
| `test/features/projects/presentation/screens/project_list_screen_test.dart` | MODIFY — update for 3-tab layout | qa-testing-agent |
| `test/features/sync/presentation/screens/project_selection_screen_test.dart` | DELETE — screen deleted | qa-testing-agent |
| `test/features/sync/presentation/screens/sync_dashboard_screen_test.dart` | MODIFY — update route reference | qa-testing-agent |

## Dependent Files (Callers/Consumers — 2+ levels)

| File | Dependency | Impact |
|------|-----------|--------|
| `lib/features/sync/presentation/screens/sync_dashboard_screen.dart:267` | References `/sync/project-selection` route | Must update or remove navigation |
| `lib/features/projects/presentation/providers/project_sync_health_provider.dart` | Used by project_list_screen for badge rendering | No change needed — API stable |
| `lib/features/projects/presentation/providers/project_import_runner.dart` | Used by project_list_screen for import progress | No change needed — API stable |
| `lib/features/projects/data/services/project_lifecycle_service.dart` | Used for enroll/unenroll/remove operations | No change needed — API stable |

## Data Flow

```
                    ┌───────────────────────────────┐
                    │      Supabase (remote)         │
                    │  project_assignments table     │
                    │  + RLS + triggers + audit      │
                    └──────────┬────────────────────┘
                               │ pull/push via SyncEngine
                               ▼
┌──────────────────────────────────────────────────────┐
│                   SyncEngine                          │
│  ProjectAssignmentAdapter (ScopeType.direct)          │
│  onPullComplete → auto-enroll + notification queue    │
└──────────┬───────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────┐
│              SQLite (local)                            │
│  project_assignments table (new)                      │
│  synced_projects.unassigned_at (new column)           │
│  change_log triggers for project_assignments          │
└──────────┬───────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────┐
│           Repositories / Providers                    │
│  ProjectAssignmentRepository → CRUD                   │
│  ProjectAssignmentProvider → wizard state              │
│  ProjectProvider → tab lists, CompanyFilter            │
│  SyncProvider → pendingNotifications                   │
└──────────┬───────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────┐
│                 UI Layer                               │
│  ProjectListScreen → 3 tabs + badges + dialogs        │
│  ProjectSetupScreen → Assignments tab (wizard)        │
│  AssignmentsStep, ProjectTabBar, FilterChips          │
│  RemovalDialog, ProjectEmptyState                     │
└──────────────────────────────────────────────────────┘
```

## Blast Radius Summary

| Category | Count |
|----------|-------|
| Direct new files | 11 |
| Direct modified files | 11 |
| Files to delete | 1 |
| New test files | 6 |
| Modified test files | 2 |
| Deleted test files | 1 |
| Dependent files (stable API) | 4 |
| **Total affected** | **36** |

## Key Patterns & Constraints

1. **DB version**: Currently 36 → bump to 37
2. **SyncEngineTables.triggeredTables**: Currently 16 tables → add project_assignments = 17
3. **registerSyncAdapters**: Currently 16 adapters → add ProjectAssignmentAdapter = 17
4. **TableAdapter pattern**: Extend `TableAdapter`, override tableName/scopeType/fkDependencies/converters
5. **ProjectAdapter pattern**: `ScopeType.direct` (company-level scoping via RLS, not FK)
6. **MergedProjectEntry**: Immutable class with isLocal/isRemoteOnly/isLocalOnly flags
7. **_buildMergedView**: Single-pass merge of local + remote projects
8. **Project setup wizard**: TabController with SingleTickerProviderStateMixin, currently 4 tabs (Details, Locations, Contractors, Bid Items)
9. **app_router.dart**: project-selection route at line 616-625, referenced from sync_dashboard at line 267
10. **is_admin_or_engineer()**: New Supabase helper function — does NOT exist yet
11. **SyncProvider.onSyncCycleComplete**: Already wired — used for health provider updates, can extend for notifications
