# Forms Infrastructure Dependency Graph

## Direct Changes

### New Files (29 files)

**Feature: form_exports**
- `lib/features/form_exports/data/models/form_export.dart` — Model class
- `lib/features/form_exports/data/datasources/local/form_export_local_datasource.dart` — extends ProjectScopedDatasource
- `lib/features/form_exports/data/datasources/remote/form_export_remote_datasource.dart` — extends BaseRemoteDatasource
- `lib/features/form_exports/data/repositories/form_export_repository.dart` — extends BaseRepository
- `lib/features/form_exports/presentation/providers/form_export_provider.dart` — ChangeNotifier

**Feature: entry_exports**
- `lib/features/entry_exports/data/models/entry_export.dart`
- `lib/features/entry_exports/data/datasources/local/entry_export_local_datasource.dart`
- `lib/features/entry_exports/data/datasources/remote/entry_export_remote_datasource.dart`
- `lib/features/entry_exports/data/repositories/entry_export_repository.dart`
- `lib/features/entry_exports/presentation/providers/entry_export_provider.dart`

**Feature: documents**
- `lib/features/documents/data/models/document.dart`
- `lib/features/documents/data/datasources/local/document_local_datasource.dart`
- `lib/features/documents/data/datasources/remote/document_remote_datasource.dart`
- `lib/features/documents/data/repositories/document_repository.dart`
- `lib/features/documents/presentation/providers/document_provider.dart`

**Schema files**
- `lib/core/database/schema/form_export_tables.dart` — CREATE TABLE + indexes
- `lib/core/database/schema/entry_export_tables.dart`
- `lib/core/database/schema/document_tables.dart`

**Sync adapters**
- `lib/features/sync/adapters/form_export_adapter.dart` — extends TableAdapter, isFileAdapter
- `lib/features/sync/adapters/entry_export_adapter.dart`
- `lib/features/sync/adapters/document_adapter.dart`

**Form registry**
- `lib/features/forms/data/models/builtin_form_config.dart` — Config class
- `lib/features/forms/data/registry/form_calculator_registry.dart`
- `lib/features/forms/data/registry/form_validator_registry.dart`
- `lib/features/forms/data/registry/form_initial_data_factory.dart`
- `lib/features/forms/data/registry/form_pdf_filler_registry.dart`
- `lib/features/forms/data/registry/form_screen_registry.dart`

**UI**
- `lib/features/forms/presentation/screens/form_gallery_screen.dart` — replaces forms_list_screen

**Supabase**
- `supabase/migrations/YYYYMMDD_forms_infrastructure.sql`

### Modified Files (22 files)

| File | Lines | Change Type |
|------|-------|-------------|
| `lib/core/database/database_service.dart` | 249+ (v43 migration) | ADD migration block |
| `lib/core/database/schema/sync_engine_tables.dart` | 145-168 | ADD to triggeredTables + tablesWithDirectProjectId |
| `lib/core/router/app_router.dart` | 611-618 | MODIFY form-fill route dispatch |
| `lib/main.dart` | 240, 562-586 | MODIFY seedBuiltinForms to registry loop |
| `lib/main_driver.dart` | 82, 229 | MODIFY seed call |
| `lib/features/sync/engine/sync_registry.dart` | 24-44 | ADD 3 new adapters in FK order |
| `lib/features/sync/engine/sync_engine.dart` | 45, 537, 1048, 1158, 1678 | RENAME isPhotoAdapter→isFileAdapter, generalize three-phase push, update _applyScopeFilter for builtin forms, update path validation |
| `lib/features/sync/engine/orphan_scanner.dart` | 12, 21+ | GENERALIZE to multi-bucket |
| `lib/features/sync/engine/storage_cleanup.dart` | 14, 23+ | GENERALIZE to multi-bucket |
| `lib/features/sync/adapters/table_adapter.dart` | 45 | RENAME isPhotoAdapter→isFileAdapter |
| `lib/features/sync/adapters/photo_adapter.dart` | 30 | RENAME isPhotoAdapter→isFileAdapter |
| `lib/features/sync/adapters/inspector_form_adapter.dart` | 15 | ADD custom pull filter for builtins |
| `lib/features/sync/application/sync_orchestrator.dart` | 37-46 | UPDATE syncBuckets map |
| `lib/features/forms/data/models/form_response.dart` | 108 | REMOVE default formType |
| `lib/features/forms/data/repositories/form_response_repository.dart` | 355-419 | DELEGATE to FormValidatorRegistry |
| `lib/features/forms/data/services/form_pdf_service.dart` | 87-94, 400-530 | DELEGATE to FormPdfFillerRegistry |
| `lib/features/forms/presentation/providers/inspector_form_provider.dart` | 354, 383 | DELEGATE to FormCalculatorRegistry |
| `lib/features/forms/presentation/screens/forms_list_screen.dart` | ENTIRE | REPLACE with FormGalleryScreen import |
| `lib/features/entries/presentation/widgets/entry_forms_section.dart` | 40-54 | DELEGATE to FormInitialDataFactory |
| `lib/features/entries/presentation/widgets/entry_form_card.dart` | 26, 75 | DELEGATE to FormScreenRegistry |
| `lib/services/soft_delete_service.dart` | 15-44 | ADD inspector_forms + 3 new tables |
| `lib/features/forms/presentation/screens/form_viewer_screen.dart` | 135, 259 | REMOVE hardcoded 0582B references |

### Deleted Files (1)
- `lib/features/forms/data/models/form_field_entry.dart` — dead code since v22

## Dependent Files (callers affected by changes)

| File | Depends On | Impact |
|------|-----------|--------|
| `lib/features/forms/data/services/auto_fill_service.dart` | form_field_entry.dart (AutoFillSource import) | MUST move enum |
| `lib/features/forms/data/models/auto_fill_result.dart` | form_field_entry.dart | MUST update import |
| `lib/features/toolbox/presentation/screens/toolbox_home_screen.dart` | forms_list_screen (navigation) | UPDATE route to form_gallery |
| `lib/features/sync/config/sync_config.dart` | Referenced by OrphanScanner | MAY need bucket configs |
| `lib/features/sync/engine/integrity_checker.dart:323` | triggeredTables list | AUTO via SyncEngineTables |
| `lib/core/database/schema_verifier.dart:265` | 'mdot_0582b' default value | KEEP (migration compat) |
| `test/features/sync/presentation/providers/sync_provider_test.dart` | syncBuckets structure | UPDATE mock |
| `test/features/sync/presentation/widgets/sync_status_icon_test.dart` | syncBuckets structure | UPDATE mock |

## Test Files

### Existing tests to verify (must still pass)
- `test/features/sync/engine/cascade_soft_delete_test.dart` — soft delete cascade
- `test/services/soft_delete_service_log_cleanup_test.dart` — purge + cleanup

### New tests needed
- `test/features/form_exports/` — model, datasource, repository
- `test/features/entry_exports/` — model, datasource, repository
- `test/features/documents/` — model, datasource, repository
- `test/features/sync/adapters/form_export_adapter_test.dart`
- `test/features/sync/adapters/entry_export_adapter_test.dart`
- `test/features/sync/adapters/document_adapter_test.dart`
- `test/features/forms/data/registry/` — all 5 registries
- `test/features/forms/presentation/screens/form_gallery_screen_test.dart`

## Data Flow

```
                    ┌──────────────────┐
                    │    App Startup    │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ seedBuiltinForms │ iterates BuiltinFormConfig list
                    │  (registry loop) │ checks each by ID
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌──────────────┐ ┌──────────┐ ┌──────────────┐
     │ FormScreen   │ │ FormCalc │ │ FormPdfFiller │
     │  Registry    │ │ Registry │ │   Registry    │
     │ type→Widget  │ │ type→Calc│ │ type→Filler   │
     └──────────────┘ └──────────┘ └──────────────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                    ┌────────▼─────────┐
                    │   Export Flow     │
                    │ PDF generated     │
                    │ → saved locally   │
                    │ → form_exports row│
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  Three-Phase Sync │
                    │ 1. Upload file    │
                    │ 2. Upsert metadata│
                    │ 3. Mark synced    │
                    └──────────────────┘
```

## Blast Radius Summary

- **Direct**: 29 new + 22 modified + 1 deleted = 52 files
- **Dependent**: 8 files
- **Tests**: 2 existing (must pass) + ~15 new
- **Supabase**: 1 migration (3 tables, 3 buckets, 4 RLS policy sets, 3 storage policies)

## Key Patterns to Follow

### Model: follow Photo model pattern
- `lib/features/photos/data/models/photo.dart`
- Immutable fields, UUID, copyWith, toMap/fromMap

### Local Datasource: extend ProjectScopedDatasource
- `lib/shared/datasources/project_scoped_datasource.dart` (line 15)
- Gets soft-delete, pagination, project-scoping for free

### Remote Datasource: extend BaseRemoteDatasource
- `lib/shared/datasources/base_remote_datasource.dart` (line 9)
- Gets standard CRUD, pagination

### Sync Adapter: extend TableAdapter
- `lib/features/sync/adapters/photo_adapter.dart` — best reference for file adapters
- isFileAdapter, localOnlyColumns, validate, fkColumnMap

### Repository: implement BaseRepository
- `lib/shared/repositories/base_repository.dart` (line 7)
- Wraps local datasource, RepositoryResult pattern

### Supabase RLS: follow multi-tenant pattern
- `supabase/migrations/20260222100000_multi_tenant_foundation.sql` (lines 692-710)
- company_inspector_forms_* policies as base template

### SyncBuckets: current map at sync_orchestrator.dart:37-46
```dart
static const Map<String, List<String>> syncBuckets = {
  'Projects': ['projects', 'bid_items', 'locations', 'todo_items'],
  'Entries': ['daily_entries', 'contractors', 'equipment',
    'entry_contractors', 'entry_equipment',
    'entry_quantities', 'entry_personnel_counts'],
  'Forms': ['inspector_forms', 'form_responses'],
  'Photos': ['photos'],
};
```

### SyncEngineTables.triggeredTables — current list (17 tables)
```dart
static const List<String> triggeredTables = [
  'projects', 'project_assignments', 'locations', 'contractors',
  'equipment', 'bid_items', 'personnel_types', 'daily_entries',
  'photos', 'entry_equipment', 'entry_quantities', 'entry_contractors',
  'entry_personnel_counts', 'inspector_forms', 'form_responses',
  'todo_items', 'calculation_history',
];
```

### SyncEngineTables.tablesWithDirectProjectId — current list
```dart
static const List<String> tablesWithDirectProjectId = [
  'project_assignments', 'locations', 'contractors', 'bid_items',
  'personnel_types', 'daily_entries', 'photos', 'todo_items',
  'entry_contractors', 'entry_quantities', 'entry_equipment',
];
```

### registerSyncAdapters — current 17 adapters in FK order
```dart
void registerSyncAdapters() {
  SyncRegistry.instance.registerAdapters([
    ProjectAdapter(),              // 1
    ProjectAssignmentAdapter(),    // 2
    LocationAdapter(),             // 3
    ContractorAdapter(),           // 4
    EquipmentAdapter(),            // 5
    BidItemAdapter(),              // 6
    PersonnelTypeAdapter(),        // 7
    DailyEntryAdapter(),           // 8
    PhotoAdapter(),                // 9
    EntryEquipmentAdapter(),       // 10
    EntryQuantitiesAdapter(),      // 11
    EntryContractorsAdapter(),     // 12
    EntryPersonnelCountsAdapter(), // 13
    InspectorFormAdapter(),        // 14
    FormResponseAdapter(),         // 15
    TodoItemAdapter(),             // 16
    CalculationHistoryAdapter(),   // 17
  ]);
}
```

### SoftDeleteService._projectChildTables — current list
```dart
static const List<String> _projectChildTables = [
  'locations', 'contractors', 'daily_entries', 'bid_items',
  'personnel_types', 'photos', 'form_responses', 'todo_items',
  'calculation_history',
];
```

### SoftDeleteService._childToParentOrder — current list
```dart
static const List<String> _childToParentOrder = [
  'entry_quantities', 'entry_equipment', 'entry_personnel_counts',
  'entry_contractors', 'photos', 'form_responses', 'todo_items',
  'calculation_history', 'equipment', 'personnel_types', 'bid_items',
  'daily_entries', 'contractors', 'locations', 'projects',
];
```
