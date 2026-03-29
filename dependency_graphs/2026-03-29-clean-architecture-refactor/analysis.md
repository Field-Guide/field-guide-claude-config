# Clean Architecture Refactor — Dependency Analysis

## Blast Radius Summary
- **Direct changes**: ~100 new files, ~50 modified files
- **Dependent files**: ~30 test files need updates
- **Layer violations**: 12 total (5 Supabase direct, 7 raw DB in presentation)
- **Silent catch blocks**: 30 files (only ~18 in scope — presentation/data layers)

---

## Direct Changes

### main.dart (1,069 lines → ~30 lines)
- `_runApp()` (lines 126-596) → extracted into feature modules + `app_providers.dart`
- `ConstructionInspectorApp` (lines 733-1069, 37 constructor params) → simplified to use `context.read`
- `seedBuiltinForms()` (line 651) → moves to forms module
- `_registerFormScreens()` (line 602) → moves to forms module
- `updateSyncContext()` (line 349) → moves to sync module
- `_initDebugLogging()` (line 677) → moves to core module
- 102 import statements → reduced to ~10

### Feature Modules (17 new files)
Each feature gets `<name>_providers.dart` exporting `List<SingleChildWidget>`:
- `lib/features/auth/auth_providers.dart`
- `lib/features/calculator/calculator_providers.dart`
- `lib/features/contractors/contractors_providers.dart`
- `lib/features/dashboard/dashboard_providers.dart`
- `lib/features/entries/entries_providers.dart`
- `lib/features/forms/forms_providers.dart`
- `lib/features/gallery/gallery_providers.dart`
- `lib/features/locations/locations_providers.dart`
- `lib/features/pdf/pdf_providers.dart`
- `lib/features/photos/photos_providers.dart`
- `lib/features/projects/projects_providers.dart`
- `lib/features/quantities/quantities_providers.dart`
- `lib/features/settings/settings_providers.dart`
- `lib/features/sync/sync_providers.dart`
- `lib/features/todos/todos_providers.dart`
- `lib/features/toolbox/toolbox_providers.dart`
- `lib/features/weather/weather_providers.dart`

### Composition File
- `lib/core/di/app_providers.dart` — imports and spreads all feature module lists in tier order

---

## Providers Extending BaseListProvider (5 — all need migration)
- `LocationProvider extends BaseListProvider<Location, LocationRepository>` (location_provider.dart:10)
- `ContractorProvider extends BaseListProvider<Contractor, ContractorRepository>` (contractor_provider.dart:10)
- `DailyEntryProvider extends BaseListProvider<DailyEntry, DailyEntryRepository>` (daily_entry_provider.dart:10)
- `PersonnelTypeProvider extends BaseListProvider<PersonnelType, PersonnelTypeRepository>` (personnel_type_provider.dart:10)
- `BidItemProvider extends BaseListProvider<BidItem, BidItemRepository>` (bid_item_provider.dart:51)

---

## Layer Violations (12 total)

### Supabase Direct (5)
| File:Line | Call | Fix |
|-----------|------|-----|
| `settings/presentation/screens/settings_screen.dart:72` | `Supabase.instance.client.from('user_profiles').update({'gauge_number': ...})` | UserProfileRepository.updateGaugeNumber() |
| `settings/presentation/screens/settings_screen.dart:118` | `Supabase.instance.client.from('user_profiles').update({'initials': ...})` | UserProfileRepository.updateInitials() |
| `auth/presentation/providers/app_config_provider.dart:148` | `Supabase.instance.client.from('app_config').select()` | AppConfigRepository.getConfig() |
| `projects/presentation/providers/project_provider.dart:585` | `Supabase.instance.client.rpc('admin_soft_delete_project')` | DeleteProjectUseCase |
| `projects/presentation/screens/project_setup_screen.dart:181` | `Supabase.instance.client.from('user_profiles').select()` | CompanyMembersRepository or UserProfileRepository |

### Raw DB Direct (7)
| File:Line | Call | Fix |
|-----------|------|-----|
| `settings/presentation/screens/trash_screen.dart:54` | `_dbService.database` raw query | TrashRepository |
| `settings/presentation/screens/trash_screen.dart:68` | `_dbService.database` raw query | TrashRepository |
| `projects/presentation/screens/project_setup_screen.dart:985` | `dbService.database` raw query | ProjectRepository method |
| `projects/presentation/providers/project_provider.dart:223` | `dbService.database` query project_assignments | ProjectAssignmentRepository |
| `projects/presentation/providers/project_provider.dart:255` | `dbService.database` query synced_projects | ProjectRepository method |
| `projects/presentation/providers/project_provider.dart:275` | `dbService.database` query projects | ProjectRepository method |
| `auth/presentation/providers/auth_provider.dart:323` | `dbService.database` query companies | CompanyRepository method |

---

## Silent catch(_) in scope (presentation + data layer)
Files in presentation layer:
- `entries/presentation/screens/entry_editor_screen.dart`
- `settings/presentation/screens/trash_screen.dart`
- `projects/presentation/screens/project_list_screen.dart`
- `auth/presentation/providers/app_config_provider.dart`
- `auth/presentation/screens/pending_approval_screen.dart`
- `projects/presentation/providers/project_settings_provider.dart`

Files in data/services layer:
- `forms/data/services/form_pdf_service.dart`
- `photos/data/datasources/remote/photo_remote_datasource.dart`
- `services/soft_delete_service.dart`
- `services/image_service.dart`
- `shared/services/preferences_service.dart`
- `shared/utils/field_formatter.dart`

Files in sync (DO NOT TOUCH logic):
- `sync/engine/sync_engine.dart`
- `sync/application/sync_orchestrator.dart`
- `sync/engine/sync_mutex.dart`
- `sync/adapters/type_converters.dart`
- `sync/presentation/screens/sync_dashboard_screen.dart`
- `sync/presentation/screens/conflict_viewer_screen.dart`

Files in core/other (touch during cleanup):
- `core/driver/driver_server.dart`
- `core/logging/logger.dart`
- `core/config/config_validator.dart`
- `test_harness.dart`

Files in pdf (out of scope):
- `pdf/services/extraction/stages/*.dart` (5 files)
- `pdf/services/ocr/*.dart` (2 files)

---

## Existing Test Files (need updates)

### Provider tests (9)
- `test/features/auth/presentation/providers/auth_provider_test.dart`
- `test/features/projects/presentation/providers/project_provider_merged_view_test.dart`
- `test/features/projects/presentation/providers/project_provider_tabs_test.dart`
- `test/features/projects/presentation/providers/project_assignment_provider_test.dart`
- `test/features/projects/presentation/providers/project_import_runner_test.dart`
- `test/features/projects/presentation/providers/project_sync_health_provider_test.dart`
- `test/features/projects/presentation/providers/project_settings_provider_test.dart`
- `test/features/entries/presentation/providers/calendar_format_provider_test.dart`
- `test/features/sync/presentation/providers/sync_provider_test.dart`

### Repository tests (10)
- `test/features/locations/data/repositories/location_repository_test.dart`
- `test/features/contractors/data/repositories/contractor_repository_test.dart`
- `test/features/contractors/data/repositories/equipment_repository_test.dart`
- `test/features/contractors/data/repositories/personnel_type_repository_test.dart`
- `test/features/projects/data/repositories/project_repository_test.dart`
- `test/features/settings/data/repositories/admin_repository_test.dart`
- `test/features/forms/data/repositories/form_export_repository_test.dart`
- `test/features/entries/data/repositories/document_repository_test.dart`
- `test/features/entries/data/repositories/entry_export_repository_test.dart`
- `test/features/forms/data/repositories/form_response_repository_test.dart`

### Mock files
- `test/helpers/mocks/mock_providers.dart` (MockProjectProvider, MockLocationProvider, MockDailyEntryProvider, MockBidItemProvider, etc.)

---

## Cross-Feature Dependencies (Critical for ordering)

```
AuthProvider (977 lines, 48 methods)
  ├─ consumed by: 12+ providers (via canWrite closure)
  ├─ consumed by: AppRouter
  ├─ deps: AuthService, PreferencesService, DatabaseService, CompanyRepository
  └─ DB direct: companies table query (line 323)

ProjectProvider (800 lines, 54 symbols)
  ├─ deps: ProjectRepository, AuthProvider, ProjectSettingsProvider, SyncOrchestrator, AppConfigProvider
  ├─ DB direct: project_assignments, synced_projects, projects queries (lines 223, 255, 275)
  ├─ Supabase direct: admin_soft_delete_project RPC (line 585)
  └─ consumed by: ProjectSetupScreen, ProjectListScreen, HomeScreen

FormResponseRepository
  ├─ consumed by: InspectorFormProvider, FormExportProvider, EntryExportProvider, DocumentProvider, GalleryProvider
  └─ 5 consumers across 4 features

GalleryProvider
  ├─ deps: PhotoRepository (photos feature), DailyEntryRepository (entries feature)
  └─ cross-feature dependency

EntryExportProvider
  ├─ deps: DailyEntryRepository, EntryExportRepository, FormResponseRepository, FormExportProvider
  └─ context.read<FormExportProvider>() — ordering-sensitive
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          main.dart                               │
│  _runApp() 470 lines → app_providers.dart (~50 lines)           │
│  ConstructionInspectorApp 37 params → context.read              │
└─────────────┬───────────────────────────────────────────────────┘
              │ spreads
┌─────────────▼───────────────────────────────────────────────────┐
│                     app_providers.dart                            │
│  Tier 0: core (DB, Prefs)                                       │
│  Tier 1: datasources                                             │
│  Tier 2: repositories                                            │
│  Tier 3: use cases                                               │
│  Tier 4: auth (AuthService, AuthProvider)                        │
│  Tier 5: feature providers                                       │
│  Tier 6: sync, router                                            │
└─────────────┬───────────────────────────────────────────────────┘
              │ imports
┌─────────────▼───────────────────────────────────────────────────┐
│              Per-Feature Provider Modules (17)                    │
│  auth_providers.dart    → datasources, repos, use cases, provider│
│  projects_providers.dart                                         │
│  entries_providers.dart                                           │
│  forms_providers.dart                                            │
│  ...                                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Source Reference

### BaseListProvider signature
```dart
abstract class BaseListProvider<T, R extends ProjectScopedRepository<T>> extends ChangeNotifier {
  final R repository;
  BaseListProvider(this.repository);
  // loadItems, createItem, updateItem, deleteItem, canWrite, checkWritePermission
}
```

### LocationRepository (example CRUD repo — implements ProjectScopedRepository)
```dart
class LocationRepository implements ProjectScopedRepository<Location> {
  final LocationLocalDatasource _datasource;
  LocationRepository(this._datasource);
  // 15 methods: getById, getAll, getByProjectId, search, save, create, update, delete, etc.
}
```

### LocationProvider (example CRUD provider — extends BaseListProvider)
```dart
class LocationProvider extends BaseListProvider<Location, LocationRepository> {
  LocationProvider(LocationRepository repository) : super(repository);
  // 11 methods: loadLocations, createLocation, updateLocation, deleteLocation, etc.
  // Thin delegates to BaseListProvider which calls repository
}
```

### EquipmentProvider (NOT extending BaseListProvider — standalone ChangeNotifier)
```dart
class EquipmentProvider extends ChangeNotifier {
  final EquipmentRepository _repository;
  bool Function() canWrite = () => true;
  // 15 methods: loadEquipmentForContractor, createEquipment, updateEquipment, deleteEquipment, etc.
  // Manually manages _isLoading, _error, _equipmentByContractor map
}
```

### ContractorProvider (extends BaseListProvider)
```dart
class ContractorProvider extends BaseListProvider<Contractor, ContractorRepository> {
  ContractorProvider(ContractorRepository repository) : super(repository);
  // 16 methods including loadFrequentContractorIds (extra beyond base)
}
```

### AuthProvider (977 lines, 48 methods — heaviest)
- Fields: _authService, _preferencesService, _databaseService, _companyRepository, _authSubscription
- State: _currentUser, _isLoading, _error, _userProfile, _company, _isPasswordRecovery, _mockUserId, _mockUserEmail
- Methods include: signIn, signOut, signUp, loadUserProfile, _initMockAuth, _handleCompanySwitchIfNeeded, checkInactivityTimeout, migratePreferencesIfNeeded, canEditFieldData, canManageProjects, isAdmin, etc.

### ProjectProvider (800 lines, 54 symbols — second heaviest)
- Fields: projectRepository, _authCanWrite, projectSettingsProvider, syncOrchestrator, appConfigProvider, dbService
- Raw DB access at lines 223, 255, 275 (project_assignments, synced_projects, projects tables)
- Supabase RPC at line 585 (admin_soft_delete_project)
- Methods include: loadProjects, selectProject, createProject, deleteProject, loadAssignments, loadRemoteProjects, getMergedProjectList, etc.
