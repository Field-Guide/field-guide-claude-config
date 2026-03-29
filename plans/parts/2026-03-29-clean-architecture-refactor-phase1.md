# Phase 1: Feature Module Extraction (Mechanical)

> **Size**: M — ~15 files touched, zero logic changes.
> **Goal**: Move provider registrations from `main.dart` into per-feature provider files and compose them in `lib/core/di/app_providers.dart`. The `_runApp()` god function and `ConstructionInspectorApp` constructor shrink dramatically.

---

## Phase 1: Feature Module Extraction

### Sub-phase 1.1: Create per-feature provider files (Tier 4 features)

**Files:**
- Create: `lib/features/settings/di/settings_providers.dart`
- Create: `lib/features/auth/di/auth_providers.dart`
- Create: `lib/features/projects/di/projects_providers.dart`
- Create: `lib/features/locations/di/locations_providers.dart`
- Create: `lib/features/contractors/di/contractors_providers.dart`
- Create: `lib/features/entries/di/entries_providers.dart`
- Create: `lib/features/quantities/di/quantities_providers.dart`
- Create: `lib/features/photos/di/photos_providers.dart`
- Create: `lib/features/forms/di/forms_providers.dart`
- Create: `lib/features/calculator/di/calculator_providers.dart`
- Create: `lib/features/gallery/di/gallery_providers.dart`
- Create: `lib/features/todos/di/todos_providers.dart`
- Create: `lib/features/pdf/di/pdf_providers.dart`
- Create: `lib/features/weather/di/weather_providers.dart`
- Create: `lib/features/sync/di/sync_providers.dart`

**Agent**: `general-purpose`

Each file exports a function that returns `List<SingleChildWidget>`. Parameters are the pre-initialized objects that the provider needs (repositories, services, etc.). No `context.read` inside these functions — dependencies are passed explicitly.

#### Step 1.1.1: Create `lib/features/settings/di/settings_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/shared/services/preferences_service.dart';
import 'package:construction_inspector/features/settings/presentation/providers/theme_provider.dart';

/// Settings feature providers (Tier 4).
/// WHY: PreferencesService is Tier 0 (async init) but its provider registration
/// is a simple .value wrapper — no creation logic needed.
List<SingleChildWidget> settingsProviders({
  required PreferencesService preferencesService,
}) {
  return [
    ChangeNotifierProvider.value(value: preferencesService),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
  ];
}
```

#### Step 1.1.2: Create `lib/features/auth/di/auth_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:construction_inspector/core/config/supabase_config.dart';
import 'package:construction_inspector/features/auth/services/auth_service.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';
import 'package:construction_inspector/features/settings/presentation/providers/admin_provider.dart';

/// Auth feature providers (Tier 3-4).
/// WHY: AuthProvider and AppConfigProvider are hoisted (created in _runApp) because
/// they need async init and are referenced by other tiers. Registered as .value.
List<SingleChildWidget> authProviders({
  required AuthService authService,
  required AuthProvider authProvider,
  required AppConfigProvider appConfigProvider,
}) {
  return [
    ChangeNotifierProvider.value(value: authProvider),
    ChangeNotifierProvider.value(value: appConfigProvider),
    Provider<AuthService>.value(value: authService),
    ChangeNotifierProvider(
      create: (_) => AdminProvider(
        SupabaseConfig.isConfigured
            ? Supabase.instance.client
            : SupabaseClient('', ''),
      ),
    ),
  ];
}
```

#### Step 1.1.3: Create `lib/features/projects/di/projects_providers.dart`

This is the largest provider file because ProjectProvider has complex init logic (loadAndRestore, auth listener).

```dart
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/projects/data/repositories/project_repository.dart';
import 'package:construction_inspector/features/projects/data/repositories/project_assignment_repository.dart';
import 'package:construction_inspector/features/projects/data/services/project_lifecycle_service.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_settings_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_sync_health_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_import_runner.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_assignment_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';
import 'package:construction_inspector/features/sync/application/sync_orchestrator.dart';

/// Project feature providers (Tier 4).
/// WHY: ProjectProvider creation includes loadAndRestore logic and auth listener
/// wiring. This is a mechanical move — all logic is identical to main.dart lines 827-901.
List<SingleChildWidget> projectProviders({
  required ProjectRepository projectRepository,
  required ProjectAssignmentProvider projectAssignmentProvider,
  required ProjectSettingsProvider projectSettingsProvider,
  required ProjectSyncHealthProvider projectSyncHealthProvider,
  required ProjectImportRunner projectImportRunner,
  required ProjectLifecycleService projectLifecycleService,
  required AuthProvider authProvider,
  required AppConfigProvider appConfigProvider,
  required SyncOrchestrator syncOrchestrator,
  required DatabaseService dbService,
}) {
  return [
    ChangeNotifierProvider.value(value: projectSettingsProvider),
    ChangeNotifierProvider(
      create: (_) {
        // FROM SPEC (BUG-009): Wire role check for project management defense-in-depth.
        final provider = ProjectProvider(
          projectRepository,
          canManageProjects: () => authProvider.canManageProjects,
        );
        // Link settings provider for persisting project selection
        provider.setSettingsProvider(projectSettingsProvider);

        // Helper: load projects by company and restore the last-selected project.
        Future<void> loadAndRestore(String? companyId) async {
          await provider.loadProjectsByCompany(companyId);
          if (projectSettingsProvider.autoLoadEnabled &&
              projectSettingsProvider.lastProjectId != null) {
            provider.setRestoringProject(true);
            final project = provider.getProjectById(
              projectSettingsProvider.lastProjectId!,
            );
            if (project != null) {
              provider.setSelectedProject(project);
            } else {
              projectSettingsProvider.setLastProjectId(null);
            }
            provider.setRestoringProject(false);
          }
          provider.setInitializing(false);
        }

        final initialCompanyId = authProvider.userProfile?.companyId;
        loadAndRestore(initialCompanyId);

        String? lastLoadedCompanyId = initialCompanyId;
        void onAuthChanged() {
          final newCompanyId = authProvider.userProfile?.companyId;
          final isAuth = authProvider.isAuthenticated;
          // FIX T95/T96: Reset lastLoadedCompanyId on sign-out
          if (!isAuth) {
            lastLoadedCompanyId = null;
            provider.clearScreenCache();
          }
          if (newCompanyId != null && newCompanyId != lastLoadedCompanyId) {
            lastLoadedCompanyId = newCompanyId;
            provider.setInitializing(true);
            loadAndRestore(newCompanyId);
            // FIX T95/T96: Trigger sync on login
            unawaited(syncOrchestrator.syncLocalAgencyProjects());
          }
          if (isAuth) {
            unawaited(appConfigProvider.checkConfig());
          }
        }
        authProvider.addListener(onAuthChanged);

        return provider;
      },
    ),
    // FIX 1 (HIGH): ProjectAssignmentProvider registered AFTER ProjectProvider.
    // FIX 2 (HIGH): Hoisted and registered with .value so clear() is called on sign-out.
    ChangeNotifierProvider.value(value: projectAssignmentProvider),
    Provider<ProjectLifecycleService>.value(value: projectLifecycleService),
    ChangeNotifierProvider.value(value: projectSyncHealthProvider),
    ChangeNotifierProvider.value(value: projectImportRunner),
  ];
}
```

#### Step 1.1.4: Create `lib/features/locations/di/locations_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/locations/data/repositories/location_repository.dart';
import 'package:construction_inspector/features/locations/presentation/providers/location_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';

/// Location feature providers (Tier 4).
List<SingleChildWidget> locationProviders({
  required LocationRepository locationRepository,
  required AuthProvider authProvider,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) {
        final p = LocationProvider(locationRepository);
        p.canWrite = () => authProvider.canEditFieldData;
        return p;
      },
    ),
  ];
}
```

#### Step 1.1.5: Create `lib/features/contractors/di/contractors_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/contractors/data/repositories/contractor_repository.dart';
import 'package:construction_inspector/features/contractors/data/repositories/equipment_repository.dart';
import 'package:construction_inspector/features/contractors/data/repositories/personnel_type_repository.dart';
import 'package:construction_inspector/features/contractors/presentation/providers/contractor_provider.dart';
import 'package:construction_inspector/features/contractors/presentation/providers/equipment_provider.dart';
import 'package:construction_inspector/features/contractors/presentation/providers/personnel_type_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';

/// Contractor feature providers (Tier 4).
List<SingleChildWidget> contractorProviders({
  required ContractorRepository contractorRepository,
  required EquipmentRepository equipmentRepository,
  required PersonnelTypeRepository personnelTypeRepository,
  required AuthProvider authProvider,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) {
        final p = ContractorProvider(contractorRepository);
        p.canWrite = () => authProvider.canEditFieldData;
        return p;
      },
    ),
    ChangeNotifierProvider(
      create: (_) {
        final p = EquipmentProvider(equipmentRepository);
        p.canWrite = () => authProvider.canEditFieldData;
        return p;
      },
    ),
    ChangeNotifierProvider(
      create: (_) {
        final p = PersonnelTypeProvider(personnelTypeRepository);
        p.canWrite = () => authProvider.canEditFieldData;
        return p;
      },
    ),
  ];
}
```

#### Step 1.1.6: Create `lib/features/entries/di/entries_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/entries/data/repositories/daily_entry_repository.dart';
import 'package:construction_inspector/features/entries/data/repositories/entry_export_repository.dart';
import 'package:construction_inspector/features/entries/data/repositories/document_repository.dart';
import 'package:construction_inspector/features/entries/presentation/providers/daily_entry_provider.dart';
import 'package:construction_inspector/features/entries/presentation/providers/calendar_format_provider.dart';
import 'package:construction_inspector/features/entries/presentation/providers/entry_export_provider.dart';
import 'package:construction_inspector/features/forms/data/repositories/form_response_repository.dart';
import 'package:construction_inspector/features/forms/presentation/providers/form_export_provider.dart';
import 'package:construction_inspector/features/forms/presentation/providers/document_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/services/document_service.dart';

/// Entry feature providers (Tier 4).
/// WHY: EntryExportProvider depends on FormExportProvider via context.read —
/// it MUST be registered AFTER forms_providers in the MultiProvider list.
/// DocumentProvider also lives here because it's entry-scoped (documents attach to entries).
List<SingleChildWidget> entryProviders({
  required DailyEntryRepository dailyEntryRepository,
  required EntryExportRepository entryExportRepository,
  required FormResponseRepository formResponseRepository,
  required DocumentRepository documentRepository,
  required DocumentService documentService,
  required AuthProvider authProvider,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) {
        final p = DailyEntryProvider(dailyEntryRepository);
        p.canWrite = () => authProvider.canEditFieldData;
        return p;
      },
    ),
    ChangeNotifierProvider(create: (_) => CalendarFormatProvider()),
    // WHY: EntryExportProvider uses context.read<FormExportProvider>() — the forms
    // module MUST be registered before this module in app_providers.dart.
    ChangeNotifierProvider(
      create: (context) => EntryExportProvider(
        entryRepository: dailyEntryRepository,
        entryExportRepository: entryExportRepository,
        formResponseRepository: formResponseRepository,
        formExportProvider: context.read<FormExportProvider>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => DocumentProvider(
        repository: formResponseRepository,
        documentRepository: documentRepository,
        documentService: documentService,
      ),
    ),
  ];
}
```

#### Step 1.1.7: Create `lib/features/quantities/di/quantities_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/quantities/data/repositories/bid_item_repository.dart';
import 'package:construction_inspector/features/quantities/data/repositories/entry_quantity_repository.dart';
import 'package:construction_inspector/features/quantities/presentation/providers/bid_item_provider.dart';
import 'package:construction_inspector/features/quantities/presentation/providers/entry_quantity_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';

/// Quantity feature providers (Tier 4).
List<SingleChildWidget> quantityProviders({
  required BidItemRepository bidItemRepository,
  required EntryQuantityRepository entryQuantityRepository,
  required AuthProvider authProvider,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) {
        final p = BidItemProvider(bidItemRepository);
        p.canWrite = () => authProvider.canEditFieldData;
        return p;
      },
    ),
    ChangeNotifierProvider(
      create: (_) => EntryQuantityProvider(entryQuantityRepository),
    ),
  ];
}
```

#### Step 1.1.8: Create `lib/features/photos/di/photos_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/photos/data/repositories/photo_repository.dart';
import 'package:construction_inspector/features/photos/presentation/providers/photo_provider.dart';
import 'package:construction_inspector/services/photo_service.dart';
import 'package:construction_inspector/services/image_service.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';

/// Photo feature providers (Tier 4).
List<SingleChildWidget> photoProviders({
  required PhotoRepository photoRepository,
  required PhotoService photoService,
  required ImageService imageService,
  required AuthProvider authProvider,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) => PhotoProvider(
        photoRepository,
        canWrite: () => authProvider.canEditFieldData,
      ),
    ),
    Provider<PhotoService>.value(value: photoService),
    Provider<ImageService>.value(value: imageService),
  ];
}
```

#### Step 1.1.9: Create `lib/features/forms/di/forms_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/forms/forms.dart';
import 'package:construction_inspector/features/forms/data/registries/form_calculator_registry.dart';
import 'package:construction_inspector/features/forms/data/repositories/form_export_repository.dart';
import 'package:construction_inspector/features/forms/presentation/providers/form_export_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';

/// Form feature providers (Tier 4).
/// WHY: FormExportProvider MUST be registered before EntryExportProvider (entries module)
/// because EntryExportProvider uses context.read<FormExportProvider>().
List<SingleChildWidget> formProviders({
  required InspectorFormRepository inspectorFormRepository,
  required FormResponseRepository formResponseRepository,
  required FormExportRepository formExportRepository,
  required FormPdfService formPdfService,
  required AuthProvider authProvider,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) {
        final p = InspectorFormProvider(
          inspectorFormRepository,
          formResponseRepository,
          FormCalculatorRegistry.instance,
        );
        p.canWrite = () => authProvider.canEditFieldData;
        return p;
      },
    ),
    Provider<FormPdfService>.value(value: formPdfService),
    // WHY: Must be registered before entries module (EntryExportProvider reads this).
    ChangeNotifierProvider(
      create: (_) => FormExportProvider(
        repository: formResponseRepository,
        formExportRepository: formExportRepository,
        pdfService: formPdfService,
      ),
    ),
  ];
}
```

#### Step 1.1.10: Create `lib/features/calculator/di/calculator_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/calculator/calculator.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';

/// Calculator feature providers (Tier 4).
List<SingleChildWidget> calculatorProviders({
  required CalculationHistoryLocalDatasource calculationHistoryDatasource,
  required AuthProvider authProvider,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) {
        final p = CalculatorProvider(calculationHistoryDatasource);
        p.canWrite = () => authProvider.canEditFieldData;
        return p;
      },
    ),
  ];
}
```

#### Step 1.1.11: Create `lib/features/gallery/di/gallery_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/photos/data/repositories/photo_repository.dart';
import 'package:construction_inspector/features/entries/data/repositories/daily_entry_repository.dart';
import 'package:construction_inspector/features/gallery/gallery.dart';

/// Gallery feature providers (Tier 4).
/// WHY: GalleryProvider has cross-feature deps (photo + entry repositories).
/// This is acceptable — gallery is a read-only aggregation view.
List<SingleChildWidget> galleryProviders({
  required PhotoRepository photoRepository,
  required DailyEntryRepository dailyEntryRepository,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) => GalleryProvider(photoRepository, dailyEntryRepository),
    ),
  ];
}
```

#### Step 1.1.12: Create `lib/features/todos/di/todos_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/todos/todos.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';

/// Todo feature providers (Tier 4).
List<SingleChildWidget> todoProviders({
  required TodoItemLocalDatasource todoItemDatasource,
  required AuthProvider authProvider,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) {
        final p = TodoProvider(todoItemDatasource);
        p.canWrite = () => authProvider.canEditFieldData;
        return p;
      },
    ),
  ];
}
```

#### Step 1.1.13: Create `lib/features/pdf/di/pdf_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/pdf/services/services.dart';
import 'package:construction_inspector/features/pdf/services/extraction/runner/extraction_job_runner.dart';

/// PDF feature providers (Tier 4).
List<SingleChildWidget> pdfProviders({
  required PdfService pdfService,
}) {
  return [
    Provider<PdfService>.value(value: pdfService),
    ChangeNotifierProvider(create: (_) => ExtractionJobRunner()),
  ];
}
```

#### Step 1.1.14: Create `lib/features/weather/di/weather_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/features/weather/services/weather_service.dart';

/// Weather feature providers (Tier 4).
List<SingleChildWidget> weatherProviders({
  required WeatherService weatherService,
}) {
  return [
    Provider<WeatherService>.value(value: weatherService),
  ];
}
```

#### Step 1.1.15: Create `lib/features/sync/di/sync_providers.dart`

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/sync/application/sync_orchestrator.dart';
import 'package:construction_inspector/features/sync/application/sync_lifecycle_manager.dart';
import 'package:construction_inspector/features/sync/engine/sync_registry.dart';
import 'package:construction_inspector/features/sync/presentation/providers/sync_provider.dart';
import 'package:construction_inspector/features/projects/data/services/project_lifecycle_service.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_sync_health_provider.dart';

/// Sync feature providers (Tier 5).
/// WHY: SyncProvider wiring includes lifecycle manager callbacks and
/// health provider post-sync hook. All moved AS-IS from main.dart lines 960-993.
List<SingleChildWidget> syncProviders({
  required SyncOrchestrator syncOrchestrator,
  required SyncLifecycleManager syncLifecycleManager,
  required ProjectLifecycleService projectLifecycleService,
  required ProjectSyncHealthProvider projectSyncHealthProvider,
  required DatabaseService dbService,
}) {
  return [
    Provider<DatabaseService>.value(value: dbService),
    Provider<SyncRegistry>.value(value: SyncRegistry.instance),
    Provider<SyncOrchestrator>.value(value: syncOrchestrator),
    ChangeNotifierProvider(
      create: (_) {
        final syncProvider = SyncProvider(syncOrchestrator);
        // Wire lifecycle manager callbacks to SyncProvider
        syncLifecycleManager.onStaleDataWarning = (isStale) {
          syncProvider.setStaleDataWarning(isStale);
        };
        syncLifecycleManager.onForcedSyncInProgress = (inProgress) {
          syncProvider.setForcedSyncInProgress(inProgress);
        };
        // FROM SPEC: Wire ProjectSyncHealthProvider after sync
        syncProvider.onSyncCycleComplete = () async {
          try {
            final counts =
                await projectLifecycleService.getAllUnsyncedCounts();
            projectSyncHealthProvider.updateCounts(counts);
          } catch (e) {
            Logger.sync('Health provider update failed: $e');
          }
        };
        // FROM SPEC SC-9: Wire notification queue
        syncOrchestrator.onNewAssignmentDetected = (message) {
          syncProvider.addNotification(message);
        };
        return syncProvider;
      },
    ),
  ];
}
```

---

### Sub-phase 1.2: Create `app_providers.dart` composition root

**Files:**
- Create: `lib/core/di/app_providers.dart`

**Agent**: `backend-data-layer-agent`

#### Step 1.2.1: Create `lib/core/di/app_providers.dart`

This file composes all per-feature provider lists in tier order. It takes the same hoisted objects that `_runApp()` creates and spreads the feature lists into a single flat `List<SingleChildWidget>`.

```dart
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/shared/services/preferences_service.dart';
import 'package:construction_inspector/features/auth/services/auth_service.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';
import 'package:construction_inspector/features/projects/data/repositories/project_repository.dart';
import 'package:construction_inspector/features/projects/data/repositories/project_assignment_repository.dart';
import 'package:construction_inspector/features/projects/data/services/project_lifecycle_service.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_settings_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_sync_health_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_import_runner.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_assignment_provider.dart';
import 'package:construction_inspector/features/locations/data/repositories/location_repository.dart';
import 'package:construction_inspector/features/contractors/data/repositories/contractor_repository.dart';
import 'package:construction_inspector/features/contractors/data/repositories/equipment_repository.dart';
import 'package:construction_inspector/features/contractors/data/repositories/personnel_type_repository.dart';
import 'package:construction_inspector/features/entries/data/repositories/daily_entry_repository.dart';
import 'package:construction_inspector/features/entries/data/repositories/entry_export_repository.dart';
import 'package:construction_inspector/features/entries/data/repositories/document_repository.dart';
import 'package:construction_inspector/features/quantities/data/repositories/bid_item_repository.dart';
import 'package:construction_inspector/features/quantities/data/repositories/entry_quantity_repository.dart';
import 'package:construction_inspector/features/photos/data/repositories/photo_repository.dart';
import 'package:construction_inspector/features/forms/forms.dart';
import 'package:construction_inspector/features/forms/data/repositories/form_export_repository.dart';
import 'package:construction_inspector/features/calculator/calculator.dart';
import 'package:construction_inspector/features/todos/todos.dart';
import 'package:construction_inspector/features/pdf/services/services.dart';
import 'package:construction_inspector/features/weather/services/weather_service.dart';
import 'package:construction_inspector/services/photo_service.dart';
import 'package:construction_inspector/services/image_service.dart';
import 'package:construction_inspector/services/document_service.dart';
import 'package:construction_inspector/features/sync/application/sync_orchestrator.dart';
import 'package:construction_inspector/features/sync/application/sync_lifecycle_manager.dart';

// Per-feature provider files
import 'package:construction_inspector/features/settings/di/settings_providers.dart';
import 'package:construction_inspector/features/auth/di/auth_providers.dart';
import 'package:construction_inspector/features/projects/di/projects_providers.dart';
import 'package:construction_inspector/features/locations/di/locations_providers.dart';
import 'package:construction_inspector/features/contractors/di/contractors_providers.dart';
import 'package:construction_inspector/features/entries/di/entries_providers.dart';
import 'package:construction_inspector/features/quantities/di/quantities_providers.dart';
import 'package:construction_inspector/features/photos/di/photos_providers.dart';
import 'package:construction_inspector/features/forms/di/forms_providers.dart';
import 'package:construction_inspector/features/calculator/di/calculator_providers.dart';
import 'package:construction_inspector/features/gallery/di/gallery_providers.dart';
import 'package:construction_inspector/features/todos/di/todos_providers.dart';
import 'package:construction_inspector/features/pdf/di/pdf_providers.dart';
import 'package:construction_inspector/features/weather/di/weather_providers.dart';
import 'package:construction_inspector/features/sync/di/sync_providers.dart';

/// Composes all feature provider lists in tier order.
///
/// TIER ORDER (must be preserved):
/// - Tier 0: Settings (PreferencesService — async init, .value wrapper)
/// - Tier 3: Auth (AuthProvider, AppConfigProvider — hoisted, .value wrappers)
/// - Tier 4: Feature providers (depend on auth + repositories)
///   - projects → locations → contractors → quantities → entries
///   - photos → forms → entries (forms before entries: EntryExportProvider reads FormExportProvider)
///   - calculator → gallery → todos → pdf → weather
/// - Tier 5: Sync (depends on auth + feature providers)
///
/// WHY: Tier 1 (datasources) and Tier 2 (repositories) are created in _runApp()
/// and passed as parameters — they don't appear as providers in the widget tree.
List<SingleChildWidget> buildAppProviders({
  // Tier 0
  required PreferencesService preferencesService,
  required DatabaseService dbService,
  // Tier 3
  required AuthService authService,
  required AuthProvider authProvider,
  required AppConfigProvider appConfigProvider,
  // Tier 4 dependencies (repositories + services created in _runApp)
  required ProjectRepository projectRepository,
  required ProjectAssignmentProvider projectAssignmentProvider,
  required ProjectSettingsProvider projectSettingsProvider,
  required ProjectSyncHealthProvider projectSyncHealthProvider,
  required ProjectImportRunner projectImportRunner,
  required ProjectLifecycleService projectLifecycleService,
  required LocationRepository locationRepository,
  required ContractorRepository contractorRepository,
  required EquipmentRepository equipmentRepository,
  required PersonnelTypeRepository personnelTypeRepository,
  required DailyEntryRepository dailyEntryRepository,
  required EntryExportRepository entryExportRepository,
  required DocumentRepository documentRepository,
  required DocumentService documentService,
  required BidItemRepository bidItemRepository,
  required EntryQuantityRepository entryQuantityRepository,
  required PhotoRepository photoRepository,
  required PhotoService photoService,
  required ImageService imageService,
  required InspectorFormRepository inspectorFormRepository,
  required FormResponseRepository formResponseRepository,
  required FormExportRepository formExportRepository,
  required FormPdfService formPdfService,
  required CalculationHistoryLocalDatasource calculationHistoryDatasource,
  required TodoItemLocalDatasource todoItemDatasource,
  required PdfService pdfService,
  required WeatherService weatherService,
  // Tier 5
  required SyncOrchestrator syncOrchestrator,
  required SyncLifecycleManager syncLifecycleManager,
}) {
  return [
    // ── Tier 0: Settings ──
    ...settingsProviders(preferencesService: preferencesService),

    // ── Tier 3: Auth ──
    ...authProviders(
      authService: authService,
      authProvider: authProvider,
      appConfigProvider: appConfigProvider,
    ),

    // ── Tier 4: Feature providers (order matters for context.read deps) ──
    ...projectProviders(
      projectRepository: projectRepository,
      projectAssignmentProvider: projectAssignmentProvider,
      projectSettingsProvider: projectSettingsProvider,
      projectSyncHealthProvider: projectSyncHealthProvider,
      projectImportRunner: projectImportRunner,
      projectLifecycleService: projectLifecycleService,
      authProvider: authProvider,
      appConfigProvider: appConfigProvider,
      syncOrchestrator: syncOrchestrator,
      dbService: dbService,
    ),
    ...locationProviders(
      locationRepository: locationRepository,
      authProvider: authProvider,
    ),
    ...contractorProviders(
      contractorRepository: contractorRepository,
      equipmentRepository: equipmentRepository,
      personnelTypeRepository: personnelTypeRepository,
      authProvider: authProvider,
    ),
    ...quantityProviders(
      bidItemRepository: bidItemRepository,
      entryQuantityRepository: entryQuantityRepository,
      authProvider: authProvider,
    ),
    ...photoProviders(
      photoRepository: photoRepository,
      photoService: photoService,
      imageService: imageService,
      authProvider: authProvider,
    ),
    // WHY: forms MUST come before entries — EntryExportProvider reads FormExportProvider.
    ...formProviders(
      inspectorFormRepository: inspectorFormRepository,
      formResponseRepository: formResponseRepository,
      formExportRepository: formExportRepository,
      formPdfService: formPdfService,
      authProvider: authProvider,
    ),
    ...entryProviders(
      dailyEntryRepository: dailyEntryRepository,
      entryExportRepository: entryExportRepository,
      formResponseRepository: formResponseRepository,
      documentRepository: documentRepository,
      documentService: documentService,
      authProvider: authProvider,
    ),
    ...calculatorProviders(
      calculationHistoryDatasource: calculationHistoryDatasource,
      authProvider: authProvider,
    ),
    ...galleryProviders(
      photoRepository: photoRepository,
      dailyEntryRepository: dailyEntryRepository,
    ),
    ...todoProviders(
      todoItemDatasource: todoItemDatasource,
      authProvider: authProvider,
    ),
    ...pdfProviders(pdfService: pdfService),
    ...weatherProviders(weatherService: weatherService),

    // ── Tier 5: Sync ──
    ...syncProviders(
      syncOrchestrator: syncOrchestrator,
      syncLifecycleManager: syncLifecycleManager,
      projectLifecycleService: projectLifecycleService,
      projectSyncHealthProvider: projectSyncHealthProvider,
      dbService: dbService,
    ),
  ];
}
```

---

### Sub-phase 1.3: Rewire `ConstructionInspectorApp` to use `buildAppProviders()`

**Files:**
- Modify: `lib/main.dart:557-596` (runApp call)
- Modify: `lib/main.dart:733-1069` (ConstructionInspectorApp class)

**Agent**: `general-purpose`

#### Step 1.3.1: Slim down the `ConstructionInspectorApp` constructor

Replace the 37-parameter constructor with a single `providers` parameter and an `appRouter` parameter. The class no longer holds references to repositories or services — those are in the provider list.

New constructor (replaces lines 733-808):

```dart
class ConstructionInspectorApp extends StatelessWidget {
  final List<SingleChildWidget> providers;
  final AppRouter appRouter;

  const ConstructionInspectorApp({
    super.key,
    required this.providers,
    required this.appRouter,
  });
```

#### Step 1.3.2: Replace the `build()` method's inline provider list

Replace the 38-entry `MultiProvider(providers: [...])` block (lines 812-1056) with:

```dart
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Field Guide',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
```

#### Step 1.3.3: Update the `runApp()` call in `_runApp()`

Replace lines 557-595 with:

```dart
  runApp(
    ConstructionInspectorApp(
      providers: buildAppProviders(
        preferencesService: preferencesService,
        dbService: dbService,
        authService: authService,
        authProvider: authProvider,
        appConfigProvider: appConfigProvider,
        projectRepository: projectRepository,
        projectAssignmentProvider: projectAssignmentProvider,
        projectSettingsProvider: projectSettingsProvider,
        projectSyncHealthProvider: projectSyncHealthProvider,
        projectImportRunner: projectImportRunner,
        projectLifecycleService: projectLifecycleService,
        locationRepository: locationRepository,
        contractorRepository: contractorRepository,
        equipmentRepository: equipmentRepository,
        personnelTypeRepository: personnelTypeRepository,
        dailyEntryRepository: dailyEntryRepository,
        entryExportRepository: entryExportRepository,
        documentRepository: documentRepository,
        documentService: documentService,
        bidItemRepository: bidItemRepository,
        entryQuantityRepository: entryQuantityRepository,
        photoRepository: photoRepository,
        photoService: photoService,
        imageService: imageService,
        inspectorFormRepository: inspectorFormRepository,
        formResponseRepository: formResponseRepository,
        formExportRepository: formExportRepository,
        formPdfService: formPdfService,
        calculationHistoryDatasource: calculationHistoryDatasource,
        todoItemDatasource: todoItemDatasource,
        pdfService: pdfService,
        weatherService: weatherService,
        syncOrchestrator: syncOrchestrator,
        syncLifecycleManager: syncLifecycleManager,
      ),
      appRouter: appRouter,
    ),
  );
```

#### Step 1.3.4: Add import for `buildAppProviders`

Add to the imports section of `main.dart`:

```dart
import 'package:construction_inspector/core/di/app_providers.dart';
```

#### Step 1.3.5: Clean up unused imports from `main.dart`

Remove all provider-specific imports that are no longer directly referenced in `main.dart`. These include:
- `ThemeProvider` import (line 77)
- `AdminProvider` import (line 78)
- `CalendarFormatProvider` import (line 83)
- `GalleryProvider` import (line 84)
- `SyncRegistry` import (line 80)
- `SyncProvider` import (line 81)
- All other provider imports that were only used in the `ConstructionInspectorApp.build()` method

Keep imports that are still used in `_runApp()` (e.g., `AuthProvider`, `AppConfigProvider`, `SyncOrchestrator`, etc.).

#### Step 1.3.6: Move `seedBuiltinForms()` and `_registerFormScreens()` to forms module

Move `seedBuiltinForms()` (lines 651-675) and `_registerFormScreens()` (lines 602-644) from `main.dart` into a new file:

**Create**: `lib/features/forms/di/forms_init.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/forms/forms.dart';
import 'package:construction_inspector/features/forms/data/registries/builtin_forms.dart';
import 'package:construction_inspector/features/forms/data/registries/form_screen_registry.dart';
import 'package:construction_inspector/features/forms/data/registries/form_quick_action_registry.dart';

/// Seeds builtin forms if not already present and registers their capabilities.
/// WHY: Registry-driven seeding checks each form by ID instead of using
/// hasBuiltinForms() which only checks "any exist". This is additive —
/// new builtin forms get seeded even if older ones already exist.
/// Public so main_driver.dart can call it too (BUG-S04 fix).
Future<void> seedBuiltinForms(InspectorFormRepository formRepository) async {
  for (final config in builtinForms) {
    try {
      final existingResult = await formRepository.getFormById(config.id);
      if (existingResult.isSuccess && existingResult.data != null) {
        config.registerCapabilities();
        continue;
      }
      final result = await formRepository.createForm(config.toInspectorForm());
      if (result.isSuccess) {
        config.registerCapabilities();
      } else {
        Logger.db('Failed to seed ${config.id}: ${result.error}');
      }
    } catch (e) {
      Logger.db('seedBuiltinForms threw for ${config.id}: $e');
    }
  }
}

/// Register form-specific screen builders and quick actions in the UI layer.
/// WHY: Screen/action registration uses Flutter widgets/navigation, must happen in UI layer.
/// Called once after seedBuiltinForms during app startup.
void registerFormScreens() {
  FormScreenRegistry.instance.register(
    'mdot_0582b',
    ({required String formId, required String responseId, required String projectId}) {
      return MdotHubScreen(responseId: responseId);
    },
  );

  FormQuickActionRegistry.instance.register('mdot_0582b', [
    FormQuickAction(
      icon: Icons.add,
      label: '+ Test',
      execute: (context, response) {
        context.pushNamed(
          'quick-test-entry',
          pathParameters: {'responseId': response.id},
        );
      },
    ),
    FormQuickAction(
      icon: Icons.science_outlined,
      label: '+ Proctor',
      execute: (context, response) {
        context.pushNamed(
          'proctor-entry',
          pathParameters: {'responseId': response.id},
        );
      },
    ),
    FormQuickAction(
      icon: Icons.scale_outlined,
      label: '+ Weights',
      execute: (context, response) {
        context.pushNamed(
          'weights-entry',
          pathParameters: {'responseId': response.id},
        );
      },
    ),
  ]);
}
```

Then update `main.dart` to import and call `registerFormScreens()` (renamed from `_registerFormScreens()`) and `seedBuiltinForms()` from the new location:

```dart
import 'package:construction_inspector/features/forms/di/forms_init.dart';
```

And replace the calls at lines 269-273:
```dart
  await seedBuiltinForms(inspectorFormRepository);
  registerFormScreens();
```

Remove the old function bodies from `main.dart` (lines 599-675).

**IMPORTANT**: Check if `main_driver.dart` imports `seedBuiltinForms` from `main.dart`. If so, update that import to point to `forms_init.dart`.

---

### Sub-phase 1.4: Update `main_driver.dart`

**Files:**
- Modify: `lib/core/driver/main_driver.dart` (if it imports `seedBuiltinForms` from `main.dart`)

**Agent**: `general-purpose`

#### Step 1.4.1: Update `seedBuiltinForms` import

If `main_driver.dart` imports `seedBuiltinForms` from `package:construction_inspector/main.dart`, change it to:

```dart
import 'package:construction_inspector/features/forms/di/forms_init.dart';
```

---

### Sub-phase 1.5: Verification

**Agent**: `general-purpose`

#### Step 1.5.1: Run static analysis

```
pwsh -Command "flutter analyze"
```

Expected: 0 errors. Warnings about unused imports are acceptable and will be cleaned in the next step.

#### Step 1.5.2: Fix any unused import warnings

Remove any imports flagged as unused by the analyzer.

#### Step 1.5.3: Re-run static analysis

```
pwsh -Command "flutter analyze"
```

Expected: 0 errors, 0 new warnings.

#### Step 1.5.4: Run tests

```
pwsh -Command "flutter test"
```

Expected: Same pass/fail count as before this phase. This is a mechanical move — no logic changed.

#### Step 1.5.5: Verify provider count

Manual check: count the providers in `buildAppProviders()` return list. The total spread entries must equal the 38 providers from the original `MultiProvider` in `ConstructionInspectorApp.build()`. Use grep to count:

```
Grep for "Provider" in app_providers.dart and count spread lists.
Grep for "Provider" in original main.dart MultiProvider block.
```

---

## Summary of Changes

| Metric | Before | After |
|--------|--------|-------|
| `main.dart` lines | ~1,069 | ~600 (estimated) |
| `ConstructionInspectorApp` constructor params | 37 | 2 (`providers`, `appRouter`) |
| Provider registration location | Inline in `build()` | 15 per-feature `di/` files |
| Composition root | None | `lib/core/di/app_providers.dart` |
| `_runApp()` logic changes | N/A | Zero — mechanical move only |
| `seedBuiltinForms` + `_registerFormScreens` | In `main.dart` | In `lib/features/forms/di/forms_init.dart` |

## Files Created (17)
1. `lib/features/settings/di/settings_providers.dart`
2. `lib/features/auth/di/auth_providers.dart`
3. `lib/features/projects/di/projects_providers.dart`
4. `lib/features/locations/di/locations_providers.dart`
5. `lib/features/contractors/di/contractors_providers.dart`
6. `lib/features/entries/di/entries_providers.dart`
7. `lib/features/quantities/di/quantities_providers.dart`
8. `lib/features/photos/di/photos_providers.dart`
9. `lib/features/forms/di/forms_providers.dart`
10. `lib/features/calculator/di/calculator_providers.dart`
11. `lib/features/gallery/di/gallery_providers.dart`
12. `lib/features/todos/di/todos_providers.dart`
13. `lib/features/pdf/di/pdf_providers.dart`
14. `lib/features/weather/di/weather_providers.dart`
15. `lib/features/sync/di/sync_providers.dart`
16. `lib/core/di/app_providers.dart`
17. `lib/features/forms/di/forms_init.dart`

## Files Modified (1-2)
1. `lib/main.dart` — Slim constructor, use `buildAppProviders()`, remove moved functions
2. `lib/core/driver/main_driver.dart` — Update `seedBuiltinForms` import (if applicable)
