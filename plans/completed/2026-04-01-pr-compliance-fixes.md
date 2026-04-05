# PR Compliance Fixes Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Fix CI blockers, decompose god objects, replace false-confidence tests with real verification, and remove dead code — closing the gap between the wiring-routing spec and what was delivered.
**Spec:** `.claude/specs/2026-04-01-pr-compliance-fixes-spec.md`
**Tailor:** `.claude/tailor/2026-04-01-pr-compliance-fixes/`

**Architecture:** Extract initializer modules from AppInitializer.initialize() and route modules from AppRouter._buildRouter(). Each module follows existing patterns (feature-initializer for DI, top-level function returning List<RouteBase> for routes). Public APIs unchanged — callers see no difference.
**Tech Stack:** Flutter/Dart, GoRouter, SQLite, Supabase, WorkManager
**Blast Radius:** 10 direct, 5 deleted, ~14 created, 5 test rewrites, 1 test deleted

---

## Phase 1: CI Fixes

### Sub-phase 1.1: Remove AUTOINCREMENT from Sync Engine Tables

**Files:**
- Modify: `lib/core/database/schema/sync_engine_tables.dart:22,38,89`
- Modify: `lib/core/database/schema_verifier.dart:265,270,277`

**Agent**: `backend-data-layer-agent`

#### Step 1.1.1: Remove AUTOINCREMENT from change_log DDL

In `lib/core/database/schema/sync_engine_tables.dart`, change line 22:
```dart
// WHY: Sync engine orders by changed_at, not id. AUTOINCREMENT is unnecessary
// overhead and triggers CI grep failure.
// BEFORE: id INTEGER PRIMARY KEY AUTOINCREMENT,
// AFTER:
'id INTEGER PRIMARY KEY,'
```

#### Step 1.1.2: Remove AUTOINCREMENT from conflict_log DDL

Same file, line 38: `INTEGER PRIMARY KEY AUTOINCREMENT` → `INTEGER PRIMARY KEY`

#### Step 1.1.3: Remove AUTOINCREMENT from storage_cleanup_queue DDL

Same file, line 89: `INTEGER PRIMARY KEY AUTOINCREMENT` → `INTEGER PRIMARY KEY`

#### Step 1.1.4: Update schema_verifier expected columns

In `lib/core/database/schema_verifier.dart`, update lines 265, 270, 277:
```dart
// WHY: Expected columns must match the actual DDL after AUTOINCREMENT removal
'id': 'INTEGER PRIMARY KEY',  // was 'INTEGER PRIMARY KEY AUTOINCREMENT'
```

#### Step 1.1.5: Run targeted tests

Run: `pwsh -Command "flutter test test/core/database/"`
Expected: PASS (schema verification tests should still pass with updated expectations)

---

### Sub-phase 1.2: Fix Supabase Singleton CI Grep

**Files:**
- Modify: `.github/workflows/quality-gate.yml:198`

**Agent**: `general-purpose`

#### Step 1.2.1: Add comment-line exclusion to Supabase grep

In `.github/workflows/quality-gate.yml`, the Supabase singleton audit grep at line 198. Add a `grep -v` to exclude comment lines:

```yaml
# WHY: 7 comment-only matches cause false CI failure. The AST-based custom
# lint rule (avoid_supabase_singleton) handles real code violations.
run: |
  VIOLATIONS=$(grep -rn "Supabase\.instance\.client" lib/ --include="*.dart" \
    | grep -v "app_initializer\.dart" \
    | grep -v "background_sync_handler\.dart" \
    | grep -v "// ignore: avoid_supabase_singleton" \
    | grep -v "^[^:]*:[0-9]*:\s*//" || true)
  if [ -n "$VIOLATIONS" ]; then
    echo "::error::Supabase.instance.client violations found outside DI root:"
    echo "$VIOLATIONS"
    exit 1
  fi
```

### Sub-phase 1.3: Fix Flutter/Dart Version

**Files:**
- Modify: `.github/workflows/quality-gate.yml:19`

**Agent**: `general-purpose`

#### Step 1.3.1: Update Flutter version

```yaml
# WHY: pubspec requires sdk: ^3.10.7. Flutter 3.32.2 ships Dart 3.8.1 which
# is too old. Use latest stable that ships Dart ≥3.10.7.
FLUTTER_VERSION: '3.29.3'
```

> NOTE: The implementing agent must verify the correct Flutter version that ships Dart ≥3.10.7. Check https://docs.flutter.dev/release/archive or run `flutter --version` locally. If 3.29.3 is not correct, use the appropriate version.

#### Step 1.3.2: Verify analyze still passes locally

Run: `pwsh -Command "flutter analyze"`
Expected: No issues found

---

## Phase 2: Dead Code Removal & Cleanup

### Sub-phase 2.1: Delete test_harness Directory

**Files:**
- Delete: `lib/test_harness/flow_registry.dart`
- Delete: `lib/test_harness/harness_seed_data.dart`
- Delete: `lib/test_harness/screen_registry.dart`
- Delete: `lib/test_harness/stub_router.dart`
- Delete: `lib/test_harness/stub_services.dart`

**Agent**: `general-purpose`

#### Step 2.1.1: Verify zero importers

Run a grep to confirm no file imports from `test_harness/`:
```
Grep for: import.*test_harness
```
Expected: Zero matches in `lib/` and `test/` (confirmed dead by tailor — 0 importers each)

#### Step 2.1.2: Delete all 5 files

Delete the entire `lib/test_harness/` directory.

#### Step 2.1.3: Verify analyze passes

Run: `pwsh -Command "flutter analyze"`
Expected: No issues found

---

### Sub-phase 2.2: Remove InitOptions.isDriverMode

**Files:**
- Modify: `lib/core/di/init_options.dart`

**Agent**: `backend-data-layer-agent`

#### Step 2.2.1: Verify isDriverMode is never read

Grep for `isDriverMode` across the codebase. Expected: only the definition in `init_options.dart` and possibly test files that will be rewritten.

#### Step 2.2.2: Remove isDriverMode field and constructor param

```dart
// lib/core/di/init_options.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration options for app initialization.
///
/// Passed to AppInitializer.initialize().
class InitOptions {
  /// WHY: Override for debug log directory.
  final String logDirOverride;

  /// WHY: Allows tests to inject a mock SupabaseClient without real network.
  final SupabaseClient? supabaseClientOverride;

  const InitOptions({
    this.logDirOverride = '',
    this.supabaseClientOverride,
  });
}
```

#### Step 2.2.3: Remove any isDriverMode references in callers

Check `main.dart` and `main_driver.dart` — neither should pass `isDriverMode` (confirmed: `main.dart:47` passes `const InitOptions(logDirOverride: kAppLogDirOverride)` — no isDriverMode).

#### Step 2.2.4: Update init_options_test.dart

In `test/core/di/init_options_test.dart`, remove all tests that reference `isDriverMode` (the field no longer exists). Update remaining tests to verify the two remaining fields (`logDirOverride`, `supabaseClientOverride`) and their defaults without referencing the removed field.

---

### Sub-phase 2.3: Update Stale test_harness References

**Files:**
- Modify: `.claude/rules/testing/patrol-testing.md` (9 references)
- Modify: `fg_lint_packages/.../avoid_raw_database_delete.dart:28`
- Modify: `fg_lint_packages/.../no_stale_patrol_references.dart:29,31`

**Agent**: `general-purpose`

#### Step 2.3.1: Update patrol-testing.md references

Replace all 9 occurrences of `lib/test_harness/` with `lib/core/driver/` in `.claude/rules/testing/patrol-testing.md`.

#### Step 2.3.2: Update lint rule allowlists

In `fg_lint_packages/.../avoid_raw_database_delete.dart` line 28: remove the line (the `test_harness` path is now covered by the existing `core/driver` entry at line 29, so updating it would create a duplicate).

In `fg_lint_packages/.../no_stale_patrol_references.dart` lines 11, 23, 29, 31: update doc comment (line 11) and correction message (line 23) from `test_harness` to `core/driver`, and update allowlist paths (lines 29, 31).

#### Step 2.3.3: Run lint package tests

Run: `pwsh -Command "flutter test fg_lint_packages/field_guide_lints/test/"`
Expected: All 86 tests pass

---

## Phase 3: AppInitializer Decomposition

### Sub-phase 3.1: Create core_services_initializer.dart

**Files:**
- Create: `lib/core/di/initializers/core_services_initializer.dart`
- Modify: `lib/core/di/app_initializer.dart`

**Agent**: `backend-data-layer-agent`

#### Step 3.1.1: Create the initializer module

```dart
// lib/core/di/initializers/core_services_initializer.dart
//
// WHY: Extracted from AppInitializer.initialize() steps 1-2 to reduce
// initialize() from 226 lines to ~60-70 lines of sequenced calls.
// FROM SPEC: God object decomposition — AppInitializer

import 'package:aptabase_flutter/aptabase_flutter.dart' hide InitOptions;
import 'package:construction_inspector/core/analytics/analytics.dart';
import 'package:construction_inspector/core/config/test_mode_config.dart';
import 'package:construction_inspector/core/config/config_validator.dart';
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/settings/data/repositories/trash_repository.dart';
import 'package:construction_inspector/services/soft_delete_service.dart';
import 'package:construction_inspector/shared/services/preferences_service.dart';

/// Products of core services initialization (steps 1-2).
class CoreServicesResult {
  final PreferencesService preferencesService;
  final DatabaseService dbService;
  final TrashRepository trashRepository;
  final SoftDeleteService softDeleteService;

  const CoreServicesResult({
    required this.preferencesService,
    required this.dbService,
    required this.trashRepository,
    required this.softDeleteService,
  });
}

/// Initializes core services: preferences, analytics, logging, database.
class CoreServicesInitializer {
  CoreServicesInitializer._();

  /// FROM SPEC: Steps 1-2 of AppInitializer.initialize().
  static Future<CoreServicesResult> create({
    required String logDirOverride,
    required Future<void> Function(PreferencesService, {String logDirOverride}) initDebugLogging,
  }) async {
    // Step 1: Core services
    final preferencesService = PreferencesService();
    await preferencesService.initialize();

    final consentAccepted = preferencesService.getBool('consent_accepted') ?? false;
    const aptabaseKey = String.fromEnvironment('APTABASE_APP_KEY');
    if (consentAccepted && aptabaseKey.isNotEmpty) {
      await Aptabase.init(aptabaseKey);
      Analytics.enable();
      Logger.lifecycle('Aptabase analytics initialized');
    } else {
      Logger.lifecycle(
        'Aptabase analytics skipped '
        '(consent=$consentAccepted, keyConfigured=${aptabaseKey.isNotEmpty})',
      );
    }

    await initDebugLogging(preferencesService, logDirOverride: logDirOverride);
    TestModeConfig.logStatus();
    ConfigValidator.logValidation();

    // Step 2: Database
    DatabaseService.initializeFfi();
    Logger.db('Initializing SQLite database...');
    final dbService = DatabaseService();
    final db = await dbService.database;
    Logger.db('Database initialized successfully');

    final trashRepository = TrashRepository(dbService);
    final softDeleteService = SoftDeleteService(db);

    return CoreServicesResult(
      preferencesService: preferencesService,
      dbService: dbService,
      trashRepository: trashRepository,
      softDeleteService: softDeleteService,
    );
  }
}
```

#### Step 3.1.2: Verify file compiles

Run: `pwsh -Command "flutter analyze lib/core/di/initializers/core_services_initializer.dart"`
Expected: No issues

---

### Sub-phase 3.2: Create platform_initializer.dart

**Files:**
- Create: `lib/core/di/initializers/platform_initializer.dart`

**Agent**: `backend-data-layer-agent`

#### Step 3.2.1: Create the initializer module

```dart
// lib/core/di/initializers/platform_initializer.dart
//
// WHY: Extracted from AppInitializer.initialize() steps 3-4.
// FROM SPEC: God object decomposition — AppInitializer

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:construction_inspector/core/config/supabase_config.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/pdf/services/ocr/tesseract_initializer.dart';

/// Initializes platform services: OCR, Supabase, Firebase.
class PlatformInitializer {
  PlatformInitializer._();

  /// FROM SPEC: Steps 3-4 of AppInitializer.initialize().
  /// Returns the resolved SupabaseClient (nullable if not configured).
  static Future<SupabaseClient?> create({
    SupabaseClient? supabaseClientOverride,
  }) async {
    // Step 3: OCR
    try {
      Logger.ocr('Initializing Tesseract OCR engine...');
      final tessdataPath = await TesseractInitializer.initialize();
      final languages = await TesseractInitializer.getLanguages();
      Logger.ocr(
        'Tesseract initialized successfully',
        data: {'tessdataPath': tessdataPath, 'languages': languages},
      );
    } catch (e, stack) {
      Logger.error('Tesseract initialization failed', error: e, stack: stack);
      Logger.ocr('PDF import features may not work correctly');
    }

    // Step 4: Supabase
    if (SupabaseConfig.isConfigured) {
      Logger.auth('Initializing Supabase with configured credentials');
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      Logger.auth('Supabase initialized successfully');
    } else {
      Logger.auth('Supabase credentials not configured - running in offline-only mode');
    }

    final supabaseClient = supabaseClientOverride ??
        (SupabaseConfig.isConfigured ? Supabase.instance.client : null);

    // Firebase (mobile only)
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await Firebase.initializeApp();
        Logger.sync('Firebase initialized successfully');
      } catch (e) {
        Logger.error('Firebase initialization failed: $e');
      }
    } else {
      Logger.sync('Desktop platform — Firebase not initialized');
    }

    return supabaseClient;
  }
}
```

---

### Sub-phase 3.3: Create media_services_initializer.dart

**Files:**
- Create: `lib/core/di/initializers/media_services_initializer.dart`

**Agent**: `backend-data-layer-agent`

#### Step 3.3.1: Create the initializer module

```dart
// lib/core/di/initializers/media_services_initializer.dart
//
// WHY: Extracted from AppInitializer.initialize() step 5.
// FROM SPEC: God object decomposition — AppInitializer

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/core/di/core_deps.dart';
import 'package:construction_inspector/features/photos/data/datasources/local/photo_local_datasource.dart';
import 'package:construction_inspector/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:construction_inspector/features/settings/data/repositories/trash_repository.dart';
import 'package:construction_inspector/services/image_service.dart';
import 'package:construction_inspector/services/permission_service.dart';
import 'package:construction_inspector/services/photo_service.dart';
import 'package:construction_inspector/services/soft_delete_service.dart';
import 'package:construction_inspector/shared/services/preferences_service.dart';

/// Products of media services initialization.
class MediaServicesResult {
  final CoreDeps coreDeps;
  final PhotoRepositoryImpl photoRepository;

  const MediaServicesResult({
    required this.coreDeps,
    required this.photoRepository,
  });
}

/// Creates CoreDeps with photo chain, image service, permission service.
class MediaServicesInitializer {
  MediaServicesInitializer._();

  /// FROM SPEC: Step 5 of AppInitializer.initialize().
  static MediaServicesResult create({
    required DatabaseService dbService,
    required PreferencesService preferencesService,
    required TrashRepository trashRepository,
    required SoftDeleteService softDeleteService,
    required SupabaseClient? supabaseClient,
  }) {
    final photoDatasource = PhotoLocalDatasource(dbService);
    final photoRepository = PhotoRepositoryImpl(photoDatasource);
    final photoService = PhotoService(photoRepository);
    final imageService = ImageService();
    final permissionService = PermissionService();

    final coreDeps = CoreDeps(
      dbService: dbService,
      preferencesService: preferencesService,
      photoService: photoService,
      imageService: imageService,
      trashRepository: trashRepository,
      softDeleteService: softDeleteService,
      permissionService: permissionService,
      supabaseClient: supabaseClient,
    );

    return MediaServicesResult(
      coreDeps: coreDeps,
      photoRepository: photoRepository,
    );
  }
}
```

---

### Sub-phase 3.4: Create remaining_deps_initializer.dart

**Files:**
- Create: `lib/core/di/initializers/remaining_deps_initializer.dart`

**Agent**: `backend-data-layer-agent`

#### Step 3.4.1: Create the initializer module

```dart
// lib/core/di/initializers/remaining_deps_initializer.dart
//
// WHY: Extracted from AppInitializer.initialize() step 10.
// FROM SPEC: God object decomposition — AppInitializer

import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/core/di/app_dependencies.dart';
import 'package:construction_inspector/features/locations/data/datasources/local/location_local_datasource.dart';
import 'package:construction_inspector/features/locations/data/repositories/location_repository_impl.dart';
import 'package:construction_inspector/features/contractors/data/datasources/local/contractor_local_datasource.dart';
import 'package:construction_inspector/features/contractors/data/datasources/local/equipment_local_datasource.dart';
import 'package:construction_inspector/features/contractors/data/datasources/local/personnel_type_local_datasource.dart';
import 'package:construction_inspector/features/contractors/data/repositories/contractor_repository_impl.dart';
import 'package:construction_inspector/features/contractors/data/repositories/equipment_repository_impl.dart';
import 'package:construction_inspector/features/contractors/data/repositories/personnel_type_repository_impl.dart';
import 'package:construction_inspector/features/quantities/data/datasources/local/bid_item_local_datasource.dart';
import 'package:construction_inspector/features/quantities/data/datasources/local/entry_quantity_local_datasource.dart';
import 'package:construction_inspector/features/quantities/data/repositories/bid_item_repository_impl.dart';
import 'package:construction_inspector/features/quantities/data/repositories/entry_quantity_repository_impl.dart';
import 'package:construction_inspector/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:construction_inspector/features/calculator/calculator.dart';
import 'package:construction_inspector/features/todos/todos.dart';
import 'package:construction_inspector/features/pdf/services/services.dart';
import 'package:construction_inspector/features/weather/services/weather_service.dart';

/// Constructs remaining feature dependencies that don't have their own initializer.
class RemainingDepsInitializer {
  RemainingDepsInitializer._();

  /// FROM SPEC: Step 10 of AppInitializer.initialize().
  static FeatureDeps create({
    required DatabaseService dbService,
    required PhotoRepositoryImpl photoRepository,
  }) {
    final locationRepository = LocationRepositoryImpl(LocationLocalDatasource(dbService));
    final contractorRepository = ContractorRepositoryImpl(ContractorLocalDatasource(dbService));
    final equipmentRepository = EquipmentRepositoryImpl(EquipmentLocalDatasource(dbService));
    final personnelTypeRepository = PersonnelTypeRepositoryImpl(PersonnelTypeLocalDatasource(dbService));
    final bidItemRepository = BidItemRepositoryImpl(BidItemLocalDatasource(dbService));
    final entryQuantityRepository = EntryQuantityRepositoryImpl(EntryQuantityLocalDatasource(dbService));
    final calculationHistoryRepository = CalculationHistoryRepositoryImpl(CalculationHistoryLocalDatasource(dbService));
    final todoItemRepository = TodoItemRepositoryImpl(TodoItemLocalDatasource(dbService));

    return FeatureDeps(
      locationRepository: locationRepository,
      contractorRepository: contractorRepository,
      equipmentRepository: equipmentRepository,
      personnelTypeRepository: personnelTypeRepository,
      bidItemRepository: bidItemRepository,
      entryQuantityRepository: entryQuantityRepository,
      photoRepository: photoRepository,
      calculationHistoryRepository: calculationHistoryRepository,
      todoItemRepository: todoItemRepository,
      pdfService: PdfService(),
      weatherService: WeatherService(),
    );
  }
}
```

---

### Sub-phase 3.5: Create startup_gate.dart

**Files:**
- Create: `lib/core/di/initializers/startup_gate.dart`

**Agent**: `backend-data-layer-agent`

#### Step 3.5.1: Create the startup gate module

```dart
// lib/core/di/initializers/startup_gate.dart
//
// WHY: Extracted from AppInitializer.initialize() step 9 only.
// FROM SPEC: God object decomposition — AppInitializer.
// NOTE: Step 8 (auth listener wiring) stays inline in app_initializer.dart
// per spec: "Steps 6, 7, and 8 stay inline as one-liner delegations."

import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';

/// Handles startup gate checks: inactivity timeout, config check, force reauth.
class StartupGate {
  StartupGate._();

  /// FROM SPEC: Step 9 of AppInitializer.initialize().
  /// Runs startup checks (inactivity, config, reauth).
  static Future<void> run({
    required AuthProvider authProvider,
    required AppConfigProvider appConfigProvider,
  }) async {
    // Step 9: Startup gate
    if (authProvider.isAuthenticated) {
      final timedOut = await authProvider.checkInactivityTimeout();
      if (!timedOut) {
        await appConfigProvider.checkConfig();
        if (appConfigProvider.requiresReauth) {
          await authProvider.handleForceReauth(appConfigProvider.reauthReason);
        }
      }
      await authProvider.updateLastActive();
    }
  }
}
```

---

### Sub-phase 3.6: Rewire AppInitializer to Use Modules

**Files:**
- Modify: `lib/core/di/app_initializer.dart`

**Agent**: `backend-data-layer-agent`

#### Step 3.6.1: Replace initialize() body with module calls

Rewrite `AppInitializer.initialize()` to delegate to the 5 modules. The method becomes ~60-70 lines of sequenced calls. Keep `_initDebugLogging` and `_ensureLogDirectoryWritable` as private helpers (they stay in this file since `CoreServicesInitializer` receives `_initDebugLogging` as a parameter).

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/core/di/app_dependencies.dart';
import 'package:construction_inspector/core/di/init_options.dart';
import 'package:construction_inspector/core/di/initializers/core_services_initializer.dart';
import 'package:construction_inspector/core/di/initializers/platform_initializer.dart';
import 'package:construction_inspector/core/di/initializers/media_services_initializer.dart';
import 'package:construction_inspector/core/di/initializers/remaining_deps_initializer.dart';
import 'package:construction_inspector/core/di/initializers/startup_gate.dart';
import 'package:construction_inspector/features/auth/di/auth_initializer.dart';
import 'package:construction_inspector/features/projects/di/project_initializer.dart';
import 'package:construction_inspector/features/entries/di/entry_initializer.dart';
import 'package:construction_inspector/features/forms/di/form_initializer.dart';
import 'package:construction_inspector/features/sync/application/background_sync_handler.dart';
import 'package:construction_inspector/features/sync/di/sync_providers.dart';
import 'package:construction_inspector/services/startup_cleanup_service.dart';
import 'package:construction_inspector/shared/services/preferences_service.dart';

export 'package:construction_inspector/core/di/app_dependencies.dart';

/// Performs all async initialization required before [runApp].
/// Returns all created dependencies in [AppDependencies].
class AppInitializer {
  static Future<AppDependencies> initialize([
    InitOptions options = const InitOptions(),
  ]) async {
    Logger.lifecycle('Application starting...');

    // Steps 1-2: Core services + database
    final coreServices = await CoreServicesInitializer.create(
      logDirOverride: options.logDirOverride,
      initDebugLogging: _initDebugLogging,
    );

    // Steps 3-4: OCR, Supabase, Firebase
    final supabaseClient = await PlatformInitializer.create(
      supabaseClientOverride: options.supabaseClientOverride,
    );

    // Step 5: CoreDeps + photo chain
    final mediaResult = MediaServicesInitializer.create(
      dbService: coreServices.dbService,
      preferencesService: coreServices.preferencesService,
      trashRepository: coreServices.trashRepository,
      softDeleteService: coreServices.softDeleteService,
      supabaseClient: supabaseClient,
    );
    final coreDeps = mediaResult.coreDeps;

    // Step 6: Feature initializers
    final authDeps = await AuthInitializer.create(coreDeps);

    // App lifecycle: detect fresh install vs cold start vs upgrade
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final storedVersion = coreServices.preferencesService.getString('app_version');
    final isUpgrade = storedVersion != null && storedVersion != currentVersion;
    final isFreshInstall = storedVersion == null;

    if (isUpgrade) {
      Logger.auth(
        'App upgrade detected: $storedVersion -> $currentVersion. '
        'Forcing re-auth (preserving local data).',
      );
      await authDeps.authProvider.forceReauthOnly();
      await coreServices.preferencesService.clearLastRoute();
    } else if (isFreshInstall) {
      Logger.auth('Fresh install detected (v$currentVersion).');
    }
    await coreServices.preferencesService.setString('app_version', currentVersion);

    final projectDeps = await ProjectInitializer.create(coreDeps);
    final entryDeps = EntryInitializer.create(coreDeps);
    final formDeps = await FormInitializer.create(coreDeps);

    await StartupCleanupService(projectDeps.projectRepository).run();

    // Step 7: Sync
    final syncResult = await SyncProviders.initialize(
      dbService: coreServices.dbService,
      authProvider: authDeps.authProvider,
      appConfigProvider: authDeps.appConfigProvider,
      companyLocalDs: authDeps.companyLocalDatasource,
      authService: authDeps.authService,
      supabaseClient: supabaseClient,
    );

    await BackgroundSyncHandler.initialize(
      dbService: coreServices.dbService,
      supabaseClient: supabaseClient,
    );

    // Step 8: Auth listener wiring (stays inline per spec)
    // SEC-102: Clear app config cache on sign-out.
    // FIX-1: Initialize projectSettingsProvider when auth is ready.
    if (authDeps.authProvider.isAuthenticated && authDeps.authProvider.userId != null) {
      await projectDeps.projectSettingsProvider.initialize(userId: authDeps.authProvider.userId);
    }

    bool wasAuthenticated = authDeps.authProvider.isAuthenticated;
    authDeps.authProvider.addListener(() {
      final isNowAuthenticated = authDeps.authProvider.isAuthenticated;
      if (wasAuthenticated && !isNowAuthenticated) {
        authDeps.appConfigProvider.clearOnSignOut();
        projectDeps.projectSyncHealthProvider.clear();
        projectDeps.projectImportRunner.reset();
        projectDeps.projectAssignmentProvider.clear();
      }
      if (isNowAuthenticated && authDeps.authProvider.userId != null) {
        projectDeps.projectSettingsProvider.initialize(userId: authDeps.authProvider.userId);
      }
      wasAuthenticated = isNowAuthenticated;
    });

    // Step 9: Startup gate
    await StartupGate.run(
      authProvider: authDeps.authProvider,
      appConfigProvider: authDeps.appConfigProvider,
    );

    // Step 10: Remaining feature deps
    final featureDeps = RemainingDepsInitializer.create(
      dbService: coreServices.dbService,
      photoRepository: mediaResult.photoRepository,
    );

    return AppDependencies(
      core: coreDeps,
      auth: authDeps,
      project: projectDeps,
      entry: entryDeps,
      form: formDeps,
      sync: SyncDeps(
        syncOrchestrator: syncResult.orchestrator,
        syncLifecycleManager: syncResult.lifecycleManager,
      ),
      feature: featureDeps,
    );
  }

  // NOTE: _initDebugLogging and _ensureLogDirectoryWritable stay here unchanged
  // (existing private helpers, lines 288-341)
```

> IMPORTANT: The implementing agent must preserve the existing `_initDebugLogging` and `_ensureLogDirectoryWritable` private methods at the bottom of this file. They are passed to `CoreServicesInitializer.create()` as a callback.

#### Step 3.6.2: Verify analyze passes

Run: `pwsh -Command "flutter analyze"`
Expected: No issues found

---

## Phase 4: AppRouter Decomposition

### Sub-phase 4.1: Create auth_routes.dart

**Files:**
- Create: `lib/core/router/routes/auth_routes.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.1.1: Create auth route module

```dart
// lib/core/router/routes/auth_routes.dart
//
// WHY: Extracted from app_router.dart to decompose the 540-line god object.
// FROM SPEC: Route modules by feature domain.

import 'package:go_router/go_router.dart';
import 'package:construction_inspector/features/auth/presentation/screens/screens.dart';

/// Auth routes: login, register, password recovery, consent, onboarding.
/// FROM SPEC: auth module includes "Login, register, password recovery, onboarding"
List<RouteBase> authRoutes() => [
  GoRoute(
    path: '/login',
    name: 'login',
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: '/register',
    name: 'register',
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: '/forgot-password',
    name: 'forgotPassword',
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: '/verify-otp',
    name: 'verifyOtp',
    builder: (context, state) {
      final email = state.uri.queryParameters['email'] ?? '';
      return OtpVerificationScreen(email: email);
    },
  ),
  GoRoute(
    path: '/update-password',
    name: 'updatePassword',
    builder: (context, state) => const UpdatePasswordScreen(),
  ),
  GoRoute(
    path: '/update-required',
    name: 'updateRequired',
    builder: (context, state) => const UpdateRequiredScreen(),
  ),
  GoRoute(
    path: '/consent',
    name: 'consent',
    builder: (context, state) => const ConsentScreen(),
  ),
  // Onboarding routes (part of auth module per spec)
  GoRoute(
    path: '/profile-setup',
    name: 'profileSetup',
    builder: (context, state) => const ProfileSetupScreen(),
  ),
  GoRoute(
    path: '/company-setup',
    name: 'companySetup',
    builder: (context, state) => const CompanySetupScreen(),
  ),
  GoRoute(
    path: '/pending-approval',
    name: 'pendingApproval',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return PendingApprovalScreen(
        requestId: extra?['requestId'] as String? ?? '',
        companyName: extra?['companyName'] as String? ?? 'your company',
      );
    },
  ),
  GoRoute(
    path: '/account-status',
    name: 'accountStatus',
    builder: (context, state) {
      final reason =
          state.uri.queryParameters['reason'] ??
          (state.extra as Map<String, dynamic>?)?['reason'] as String? ??
          'rejected';
      return AccountStatusScreen(reason: reason);
    },
  ),
];
```

---

### Sub-phase 4.2: Create entry_routes.dart

**Files:**
- Create: `lib/core/router/routes/entry_routes.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.2.1: Create entry route module

```dart
// lib/core/router/routes/entry_routes.dart

import 'package:go_router/go_router.dart';
import 'package:construction_inspector/features/entries/data/models/daily_entry.dart';
import 'package:construction_inspector/features/entries/presentation/screens/screens.dart';
import 'package:construction_inspector/features/settings/presentation/screens/screens.dart';

/// Entry routes: editor, report, list, drafts, review, personnel types.
List<RouteBase> entryRoutes() => [
  GoRoute(
    path: '/entry/:projectId/:date',
    name: 'entry',
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      final date = state.pathParameters['date']!;
      final locationId = state.uri.queryParameters['locationId'];
      final entryId = state.uri.queryParameters['entryId'];
      return EntryEditorScreen(
        projectId: projectId,
        date: DateTime.parse(date),
        locationId: locationId,
        entryId: entryId,
      );
    },
  ),
  GoRoute(
    path: '/report/:entryId',
    name: 'report',
    builder: (context, state) {
      final entryId = state.pathParameters['entryId']!;
      return EntryEditorScreen(
        projectId: '',
        entryId: entryId,
      );
    },
  ),
  GoRoute(
    path: '/entries',
    name: 'entries',
    builder: (context, state) => const EntriesListScreen(),
  ),
  GoRoute(
    path: '/drafts/:projectId',
    name: 'drafts',
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      return DraftsListScreen(projectId: projectId);
    },
  ),
  GoRoute(
    path: '/review',
    name: 'review',
    redirect: (context, state) {
      if (state.extra == null) return '/';
      return null;
    },
    builder: (context, state) {
      final entries = state.extra as List<DailyEntry>;
      return EntryReviewScreen(entries: entries);
    },
  ),
  GoRoute(
    path: '/review-summary',
    name: 'review-summary',
    redirect: (context, state) {
      if (state.extra == null) return '/';
      return null;
    },
    builder: (context, state) {
      final data = state.extra as Map<String, dynamic>;
      return ReviewSummaryScreen(
        readyEntries: data['ready'] as List<DailyEntry>,
        skippedEntries: data['skipped'] as List<DailyEntry>,
      );
    },
  ),
  GoRoute(
    path: '/personnel-types/:projectId',
    name: 'personnel-types',
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      return PersonnelTypesScreen(projectId: projectId);
    },
  ),
];
```

---

### Sub-phase 4.3: Create project_routes.dart

**Files:**
- Create: `lib/core/router/routes/project_routes.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.3.1: Create project route module

```dart
// lib/core/router/routes/project_routes.dart

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:construction_inspector/features/calculator/calculator.dart';
import 'package:construction_inspector/features/projects/presentation/screens/screens.dart';
import 'package:construction_inspector/features/quantities/presentation/screens/screens.dart';

/// Project routes: create, edit, quantities, quantity calculator.
List<RouteBase> projectRoutes() => [
  GoRoute(
    path: '/project/new',
    name: 'project-new',
    builder: (context, state) => const ProjectSetupScreen(),
  ),
  GoRoute(
    path: '/project/:projectId/edit',
    name: 'project-edit',
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      final tabParam = state.uri.queryParameters['tab'];
      final initialTab = tabParam != null ? int.tryParse(tabParam) : null;
      return ProjectSetupScreen(
        key: ValueKey(projectId),
        projectId: projectId,
        initialTab: initialTab,
      );
    },
  ),
  GoRoute(
    path: '/quantities',
    name: 'quantities',
    builder: (context, state) => const QuantitiesScreen(),
  ),
  GoRoute(
    path: '/quantity-calculator/:entryId',
    name: 'quantity-calculator',
    builder: (context, state) {
      final entryId = state.pathParameters['entryId']!;
      final typeParam = state.uri.queryParameters['type'];
      final type = typeParam != null
          ? CalculationType.values.byName(typeParam)
          : null;
      return QuantityCalculatorScreen(entryId: entryId, initialType: type);
    },
  ),
];
```

---

### Sub-phase 4.4: Create form_routes.dart

**Files:**
- Create: `lib/core/router/routes/form_routes.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.4.1: Create form route module

```dart
// lib/core/router/routes/form_routes.dart
//
// NOTE: Owns _mpResultFromJobResult helper (moved from app_router.dart:90-122).

import 'package:go_router/go_router.dart';
import 'package:construction_inspector/features/forms/forms.dart';
import 'package:construction_inspector/features/forms/data/registries/form_screen_registry.dart';
import 'package:construction_inspector/features/pdf/presentation/screens/screens.dart';
import 'package:construction_inspector/features/pdf/services/mp/mp_models.dart';
import 'package:construction_inspector/features/pdf/services/services.dart';
import 'package:construction_inspector/features/pdf/services/extraction/runner/extraction_result.dart';
import 'package:construction_inspector/features/pdf/services/extraction/pipeline/extraction_pipeline.dart';
import 'package:construction_inspector/features/pdf/services/extraction/pipeline/result_converter.dart';

/// Form and PDF import routes.
List<RouteBase> formRoutes() => [
  GoRoute(
    path: '/import/preview/:projectId',
    name: 'import-preview',
    redirect: (context, state) {
      if (state.extra == null) return '/projects';
      if (state.extra is! BidItemJobResult && state.extra is! PdfImportResult) return '/projects';
      return null;
    },
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      final extra = state.extra;
      final PdfImportResult importResult;
      if (extra is BidItemJobResult) {
        final pipelineResult = PipelineResult.fromMap(extra.resultMap);
        importResult = ResultConverter.toPdfImportResult(
          pipelineResult,
          projectId,
        );
      } else {
        importResult = extra as PdfImportResult;
      }
      return PdfImportPreviewScreen(
        importResult: importResult,
        projectId: projectId,
      );
    },
  ),
  GoRoute(
    path: '/mp-import/preview/:projectId',
    name: 'mp-import-preview',
    redirect: (context, state) {
      final extra = state.extra;
      if (extra is! MpJobResult && extra is! MpExtractionResult) {
        return '/projects';
      }
      return null;
    },
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      final extra = state.extra;
      final MpExtractionResult extractionResult;
      if (extra is MpJobResult) {
        extractionResult = _mpResultFromJobResult(extra);
      } else {
        extractionResult = extra as MpExtractionResult;
      }
      return MpImportPreviewScreen(
        extractionResult: extractionResult,
        projectId: projectId,
      );
    },
  ),
  GoRoute(
    path: '/form/:responseId',
    name: 'form-fill',
    builder: (context, state) {
      final responseId = state.pathParameters['responseId']!;
      final projectId = state.uri.queryParameters['projectId'] ?? '';
      final formType = state.uri.queryParameters['formType'];

      if (formType != null && formType.isNotEmpty) {
        final registry = FormScreenRegistry.instance;
        final builder = registry.get(formType);
        if (builder != null) {
          return builder(
            formId: formType,
            responseId: responseId,
            projectId: projectId,
          );
        }
      }

      return FormViewerScreen(responseId: responseId);
    },
  ),
];

/// Deserialize [MpExtractionResult] from a [MpJobResult] produced by the
/// worker isolate.
MpExtractionResult _mpResultFromJobResult(MpJobResult job) {
  final m = job.resultMap;
  final matchesList = (m['matches'] as List).cast<Map<String, dynamic>>();
  return MpExtractionResult(
    totalParsed: m['total_parsed'] as int,
    totalMatched: m['total_matched'] as int,
    totalUnmatched: m['total_unmatched'] as int,
    nativePages: m['native_pages'] as int,
    ocrPages: m['ocr_pages'] as int,
    overallConfidence: (m['overall_confidence'] as num).toDouble(),
    elapsed: Duration(milliseconds: m['elapsed_ms'] as int),
    warnings: List<String>.from(m['warnings'] as List),
    qualityMetrics: Map<String, dynamic>.from(m['quality_metrics'] as Map),
    matches: matchesList.map((entry) {
      final strategy = MpExtractionStrategy.values.byName(
        entry['strategy'] as String,
      );
      return MpMatch(
        entry: MpEntry(
          itemNumber: entry['item_number'] as String,
          title: entry['title'] as String,
          body: entry['body'] as String,
          pageIndex: entry['page_index'] as int,
          strategy: strategy,
          confidence: (entry['entry_confidence'] as num).toDouble(),
        ),
        bidItemId: entry['bid_item_id'] as String?,
        bidItemDescription: entry['bid_item_description'] as String?,
        confidence: (entry['match_confidence'] as num).toDouble(),
        isMatched: entry['is_matched'] as bool,
      );
    }).toList(),
  );
}
```

---

### Sub-phase 4.5: Create toolbox_routes.dart

**Files:**
- Create: `lib/core/router/routes/toolbox_routes.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.5.1: Create toolbox route module

```dart
// lib/core/router/routes/toolbox_routes.dart

import 'package:go_router/go_router.dart';
import 'package:construction_inspector/features/toolbox/toolbox.dart';
import 'package:construction_inspector/features/calculator/calculator.dart';
import 'package:construction_inspector/features/gallery/gallery.dart';
import 'package:construction_inspector/features/todos/todos.dart';
import 'package:construction_inspector/features/forms/forms.dart';

/// Toolbox routes: home, forms gallery, calculator, gallery, todos.
List<RouteBase> toolboxRoutes() => [
  GoRoute(
    path: '/toolbox',
    name: 'toolbox',
    builder: (context, state) => const ToolboxHomeScreen(),
  ),
  GoRoute(
    path: '/forms',
    name: 'forms',
    builder: (context, state) => const FormGalleryScreen(),
  ),
  GoRoute(
    path: '/calculator',
    name: 'calculator',
    builder: (context, state) => const CalculatorScreen(),
  ),
  GoRoute(
    path: '/gallery',
    name: 'gallery',
    builder: (context, state) => const GalleryScreen(),
  ),
  GoRoute(
    path: '/todos',
    name: 'todos',
    builder: (context, state) => const TodosScreen(),
  ),
];
```

---

### Sub-phase 4.6: Create settings_routes.dart

**Files:**
- Create: `lib/core/router/routes/settings_routes.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.6.1: Create settings route module

```dart
// lib/core/router/routes/settings_routes.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:construction_inspector/features/settings/presentation/screens/screens.dart';

/// Settings routes (outside shell). Requires rootNavigatorKey for /settings/trash.
List<RouteBase> settingsRoutes({required GlobalKey<NavigatorState> rootNavigatorKey}) => [
  GoRoute(
    // FIX T77: parentNavigatorKey prevents /settings prefix from colliding
    // with the shell route, which would resolve to the wrong navigator.
    parentNavigatorKey: rootNavigatorKey,
    path: '/settings/trash',
    name: 'trash',
    builder: (context, state) => const TrashScreen(),
  ),
  GoRoute(
    path: '/edit-profile',
    name: 'editProfile',
    builder: (context, state) => const EditProfileScreen(),
  ),
  GoRoute(
    path: '/admin-dashboard',
    name: 'admin-dashboard',
    builder: (context, state) => const AdminDashboardScreen(),
  ),
  GoRoute(
    path: '/help-support',
    name: 'help-support',
    builder: (context, state) => const HelpSupportScreen(),
  ),
  GoRoute(
    path: '/legal-document',
    name: 'legal-document',
    builder: (context, state) {
      final rawType = state.uri.queryParameters['type'] ?? 'tos';
      final type = {'tos', 'privacy'}.contains(rawType) ? rawType : 'tos';
      return LegalDocumentScreen(type: type);
    },
  ),
  GoRoute(
    path: '/oss-licenses',
    name: 'oss-licenses',
    builder: (context, state) => const OssLicensesScreen(),
  ),
];
```

---

### Sub-phase 4.7: Create sync_routes.dart

**Files:**
- Create: `lib/core/router/routes/sync_routes.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.7.1: Create sync route module

```dart
// lib/core/router/routes/sync_routes.dart

import 'package:go_router/go_router.dart';
import 'package:construction_inspector/features/sync/presentation/screens/sync_dashboard_screen.dart';
import 'package:construction_inspector/features/sync/presentation/screens/conflict_viewer_screen.dart';

/// Sync routes: dashboard, conflict resolution.
List<RouteBase> syncRoutes() => [
  GoRoute(
    path: '/sync/dashboard',
    name: 'sync-dashboard',
    builder: (context, state) => const SyncDashboardScreen(),
  ),
  GoRoute(
    path: '/sync/conflicts',
    name: 'sync-conflicts',
    builder: (context, state) => const ConflictViewerScreen(),
  ),
];
```

---

### Sub-phase 4.8: Rewire AppRouter to Use Route Modules

**Files:**
- Modify: `lib/core/router/app_router.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.8.1: Replace _buildRouter() with module composition

Rewrite `app_router.dart` to import and compose the 7 route modules. Remove all screen imports. Keep: class declaration, `_kNonRestorableRoutes`, constructor, `setInitialLocation`, `isRestorableRoute`, `router` getter.

Remove `_mpResultFromJobResult` (moved to `form_routes.dart`).

The new `_buildRouter()`:

```dart
GoRouter _buildRouter() => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: _initialLocation,
  observers: Logger.isEnabled ? [AppRouteObserver()] : const [],
  refreshListenable: Listenable.merge([
    _authProvider,
    _appConfigProvider,
    _consentProvider,
  ]),
  redirect: _appRedirect.redirect,
  routes: [
    ...authRoutes(),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProjectDashboardScreen()),
        ),
        GoRoute(
          path: '/calendar',
          name: 'home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/projects',
          name: 'projects',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProjectListScreen()),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
    ...settingsRoutes(rootNavigatorKey: _rootNavigatorKey),
    ...entryRoutes(),
    ...projectRoutes(),
    ...formRoutes(),
    ...toolboxRoutes(),
    ...syncRoutes(),
  ],
);
```

> NOTE: Shell routes (4 routes with bottom nav) stay inline because they are children of the ShellRoute widget, not standalone route modules. The 4 shell screen imports remain in app_router.dart.

New imports for app_router.dart:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/core/logging/app_route_observer.dart';
import 'package:construction_inspector/core/router/app_redirect.dart';
import 'package:construction_inspector/core/router/scaffold_with_nav_bar.dart';
import 'package:construction_inspector/core/router/routes/auth_routes.dart';
import 'package:construction_inspector/core/router/routes/entry_routes.dart';
import 'package:construction_inspector/core/router/routes/project_routes.dart';
import 'package:construction_inspector/core/router/routes/form_routes.dart';
import 'package:construction_inspector/core/router/routes/toolbox_routes.dart';
import 'package:construction_inspector/core/router/routes/settings_routes.dart';
import 'package:construction_inspector/core/router/routes/sync_routes.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/settings/presentation/providers/consent_provider.dart';
// Shell screen imports (4 — stay because they're ShellRoute children)
import 'package:construction_inspector/features/dashboard/presentation/screens/screens.dart';
import 'package:construction_inspector/features/entries/presentation/screens/screens.dart';
import 'package:construction_inspector/features/projects/presentation/screens/screens.dart';
import 'package:construction_inspector/features/settings/presentation/screens/screens.dart';
```

#### Step 4.8.2: Verify analyze passes

Run: `pwsh -Command "flutter analyze"`
Expected: No issues found

---

## Phase 5: BackgroundSyncHandler Fix & Entrypoint Slimming

### Sub-phase 5.1: Inject SupabaseClient into BackgroundSyncHandler

**Files:**
- Modify: `lib/features/sync/application/background_sync_handler.dart`

**Agent**: `backend-supabase-agent`

#### Step 5.1.1: Add supabaseClient parameter to initialize()

Add `SupabaseClient? supabaseClient` parameter and store it:

```dart
static SupabaseClient? _supabaseClient;

static Future<void> initialize({
  DatabaseService? dbService,
  SupabaseClient? supabaseClient,
}) async {
  if (_isInitialized) return;

  _dbService = dbService;
  _supabaseClient = supabaseClient;
  // ... rest unchanged
```

#### Step 5.1.2: Use stored client in _performDesktopSync

Replace `Supabase.instance.client` at line 151 with the stored client:

```dart
// WHY: Use injected client instead of singleton. Eliminates the last
// fixable Supabase.instance.client usage outside DI root.
final client = _supabaseClient;
if (client == null) {
  Logger.sync('No SupabaseClient for desktop sync, skipping');
  return;
}

final engine = await SyncEngine.createForBackgroundSync(
  database: db,
  supabase: client,
);
```

> NOTE: The `backgroundSyncCallback()` top-level function (line 49) still uses `Supabase.instance.client` — this is the documented WorkManager isolate exception. Fresh isolate cannot access main isolate's DI state.

#### Step 5.1.3: Verify the call site passes the client

In the rewired `app_initializer.dart` (Phase 3.6), confirm BackgroundSyncHandler.initialize receives `supabaseClient`:

```dart
await BackgroundSyncHandler.initialize(
  dbService: coreServices.dbService,
  supabaseClient: supabaseClient,
);
```

This was already included in the Phase 3.6 rewrite.

---

### Sub-phase 5.2: Extract ConstructionInspectorApp Widget

**Files:**
- Create: `lib/core/app_widget.dart`
- Modify: `lib/main.dart`
- Modify: `lib/main_driver.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 5.2.1: Create app_widget.dart

```dart
// lib/core/app_widget.dart
//
// WHY: Extracted from main.dart to slim the entrypoint to ~50 lines.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:construction_inspector/core/router/app_router.dart';
import 'package:construction_inspector/features/settings/presentation/providers/theme_provider.dart';

/// Root application widget. Wraps MaterialApp.router with provider tree.
class ConstructionInspectorApp extends StatelessWidget {
  final List<SingleChildWidget> providers;
  final AppRouter appRouter;

  const ConstructionInspectorApp({
    super.key,
    required this.providers,
    required this.appRouter,
  });

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

#### Step 5.2.2: Update main.dart

Remove the `ConstructionInspectorApp` class definition. Import from `app_widget.dart` instead. Also remove unnecessary imports that were only for the widget (ThemeProvider, Provider, SingleChildWidget).

Updated main.dart (~50 lines):

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:construction_inspector/core/config/sentry_pii_filter.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/core/di/app_providers.dart';
import 'package:construction_inspector/core/di/app_initializer.dart';
import 'package:construction_inspector/core/di/app_bootstrap.dart';
import 'package:construction_inspector/core/di/init_options.dart';
import 'package:construction_inspector/core/analytics/analytics.dart';
import 'package:construction_inspector/core/app_widget.dart';

const String kAppLogDirOverride = String.fromEnvironment(
  'APP_LOG_DIR',
  defaultValue: '',
);

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 0.1;
      options.beforeSendTransaction = beforeSendTransaction;
      options.beforeSend = beforeSendSentry;
      options.attachScreenshot = false;
      options.attachViewHierarchy = false;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      runZonedGuarded(
        () => _runApp(),
        (error, stack) {
          Logger.error('Uncaught zone error: $error', error: error, stack: stack);
        },
        zoneSpecification: Logger.zoneSpec(),
      );
    },
  );
}

Future<void> _runApp() async {
  final deps = await AppInitializer.initialize(
    const InitOptions(logDirOverride: kAppLogDirOverride),
  );
  Analytics.trackAppLaunch();

  final bootstrap = AppBootstrap.configure(deps);

  runApp(
    ConstructionInspectorApp(
      providers: buildAppProviders(
        deps,
        consentProvider: bootstrap.consentProvider,
        supportProvider: bootstrap.supportProvider,
      ),
      appRouter: bootstrap.appRouter,
    ),
  );
}
```

#### Step 5.2.3: Update main_driver.dart

Change the import from `'package:construction_inspector/main.dart' show ConstructionInspectorApp'` to `'package:construction_inspector/core/app_widget.dart'`:

```dart
import 'package:construction_inspector/core/app_widget.dart';
```

Remove the `show ConstructionInspectorApp` since `app_widget.dart` only exports that one class.

#### Step 5.2.4: Verify analyze passes

Run: `pwsh -Command "flutter analyze"`
Expected: No issues found

---

### Sub-phase 5.3: Slim main_driver.dart via Driver Setup Extraction

**Files:**
- Create: `lib/core/driver/driver_setup.dart`
- Modify: `lib/main_driver.dart`

**Agent**: `backend-data-layer-agent`

> FROM SPEC: `main_driver.dart` (77 lines) target ~35 lines. "Import shared setup from core/driver/"

#### Step 5.3.1: Create driver_setup.dart

Extract the driver-specific setup logic from `main_driver.dart` into a reusable module:

```dart
// lib/core/driver/driver_setup.dart
//
// WHY: Extracted from main_driver.dart to slim the entrypoint to ~35 lines.
// FROM SPEC: Entrypoint slimming — main_driver.dart ≤ 40 lines.

import 'package:construction_inspector/core/di/app_dependencies.dart';
import 'package:construction_inspector/core/driver/driver_server.dart';
import 'package:construction_inspector/services/photo_service.dart';

/// Builds driver-specific overrides and constructs the [DriverServer].
class DriverSetup {
  DriverSetup._();

  /// Creates a TestPhotoService, patches deps via copyWith, and returns the DriverServer.
  // NOTE: TestPhotoService takes PhotoRepository, not PhotoService.
  // NOTE: AppDependencies.copyWith() accepts photoService:, not core:.
  // NOTE: DriverServer takes individual named params, not a single deps: param.
  static ({AppDependencies deps, DriverServer server}) configure({
    required AppDependencies baseDeps,
  }) {
    final testPhotoService = TestPhotoService(baseDeps.feature.photoRepository);
    final patchedDeps = baseDeps.copyWith(photoService: testPhotoService);
    final server = DriverServer(
      testPhotoService: testPhotoService,
      photoRepository: patchedDeps.feature.photoRepository,
      documentRepository: patchedDeps.entry.documentRepository,
      syncOrchestrator: patchedDeps.sync.syncOrchestrator,
      databaseService: patchedDeps.core.dbService,
      projectLifecycleService: patchedDeps.project.projectLifecycleService,
    );
    return (deps: patchedDeps, server: server);
  }
}
```

#### Step 5.3.2: Update main_driver.dart to use DriverSetup

Replace the inline TestPhotoService creation, `deps.copyWith`, and DriverServer construction with a single call to `DriverSetup.configure()`. The resulting `main_driver.dart` should be ≤ 40 lines.

#### Step 5.3.3: Verify analyze passes

Run: `pwsh -Command "flutter analyze"`
Expected: No issues found

---

## Phase 6: Test Rewrites

### Sub-phase 6.1: Delete entrypoint_equivalence_test.dart

**Files:**
- Delete: `test/core/di/entrypoint_equivalence_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.1.1: Delete the file

Delete `test/core/di/entrypoint_equivalence_test.dart` (6 tests — 5 source-text + 1 trivial type check). Concerns covered by app_bootstrap_test.dart rewrites and lint rules.

---

### Sub-phase 6.2: Rewrite app_bootstrap_test.dart

**Files:**
- Modify: `test/core/di/app_bootstrap_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.2.1: Read existing test to understand structure

Read `test/core/di/app_bootstrap_test.dart` to understand current test structure and imports.

#### Step 6.2.2: Rewrite with runtime verification tests

Replace all source-text grep tests with ~6 real runtime tests:

1. `configure() with mocked deps produces valid AppBootstrapResult with non-null router, providers`
2. `configure() called twice throws StateError`
3. `Auth state change authenticated→unauthenticated triggers sign-out cleanup callback`
4. `Auth state change unauthenticated→authenticated triggers deferred audit write callback`
5. `Consent state loads before router construction (verified via mock call ordering)`
6. `consentProvider mid-session change enables Sentry reporting`

> NOTE: These tests require mocking AuthProvider, AppConfigProvider, ConsentProvider, and the deps objects. The implementing agent should use `mocktail` for mocking (already a dev dependency). It should also call `AppBootstrap.resetForTesting()` in setUp/tearDown to reset the configured guard.

#### Step 6.2.3: Run targeted tests

Run: `pwsh -Command "flutter test test/core/di/app_bootstrap_test.dart"`
Expected: All 6 tests PASS

---

### Sub-phase 6.3: Rewrite app_initializer_test.dart

**Files:**
- Modify: `test/core/di/app_initializer_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.3.1: Read existing test

Read `test/core/di/app_initializer_test.dart` to understand current structure.

#### Step 6.3.2: Rewrite with runtime verification tests

Replace all source-text and trivial tests with ~5 real runtime tests:

1. `initialize() returns AppDependencies with all fields populated (core, auth, project, entry, form, sync, feature non-null)`
2. `initialize() with Supabase unconfigured returns AppDependencies with null supabaseClient`
3. `initialize() OCR failure is caught and logged, doesn't crash initialization`
4. `initialize() delegates to CoreServicesInitializer, PlatformInitializer, MediaServicesInitializer, RemainingDepsInitializer (verify via type checks on returned deps)`
5. `InitOptions.supabaseClientOverride is passed through to CoreDeps`

> NOTE: Full AppInitializer.initialize() is hard to unit test due to platform dependencies (SQLite FFI, Supabase, Firebase). Tests should focus on what can be verified without real platform init — use InitOptions.supabaseClientOverride for injection, and verify the returned AppDependencies shape. The implementing agent may need to skip tests that require actual platform initialization and focus on verifiable behavior.

#### Step 6.3.3: Run targeted tests

Run: `pwsh -Command "flutter test test/core/di/app_initializer_test.dart"`
Expected: All tests PASS

---

### Sub-phase 6.4: Rewrite app_router_test.dart

**Files:**
- Modify: `test/core/router/app_router_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.4.1: Read existing test

Read `test/core/router/app_router_test.dart` to understand current structure.

#### Step 6.4.2: Rewrite with runtime verification tests

Replace constructor-only tests with ~5 real tests:

1. `Router construction with valid mock deps produces a GoRouter instance`
2. `isRestorableRoute() returns true for dashboard (/), false for auth routes (/profile-setup, /consent, /update-required)`
3. `All 7 route modules register at least one route (compositional check — verify routes list length > 0)`
4. `setInitialLocation() changes initial location`
5. `Non-restorable routes set matches expected auth/onboarding paths`

> NOTE: Tests 1, 3 require mocking AuthProvider, AppConfigProvider, ConsentProvider to construct AppRouter. Tests 2, 4, 5 can be static/unit tests since isRestorableRoute is static and _kNonRestorableRoutes is a const set. The implementing agent should import route modules directly and verify their output.

#### Step 6.4.3: Run targeted tests

Run: `pwsh -Command "flutter test test/core/router/app_router_test.dart"`
Expected: All tests PASS

---

### Sub-phase 6.5: Rewrite background_sync_handler_test.dart

**Files:**
- Modify: `test/features/sync/application/background_sync_handler_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.5.1: Read existing test

Read `test/features/sync/application/background_sync_handler_test.dart`.

#### Step 6.5.2: Rewrite with runtime verification tests

Replace trivial tests with ~3 real tests:

1. `initialize() with injected SupabaseClient stores it for desktop sync`
2. `initialize() with injected SupabaseClient stores it — verify _performDesktopSync uses injected client via mock verification (e.g., trigger desktop sync and confirm the mock client receives calls, not Supabase.instance.client)`
3. `cancelAll() disposes desktop timer`

> NOTE: Test 2 is the key behavioral test from the spec. The implementing agent should use a mock SupabaseClient injected via initialize(), then trigger _performDesktopSync (which may require exposing a @visibleForTesting entry point or testing indirectly through the desktop sync timer). The kBackgroundSyncTaskName constant can be verified as part of test 1 or as an assertion within another test if needed.

#### Step 6.5.3: Run targeted tests

Run: `pwsh -Command "flutter test test/features/sync/application/background_sync_handler_test.dart"`
Expected: All tests PASS

---

### Sub-phase 6.6: Rewrite scaffold_with_nav_bar_test.dart

**Files:**
- Modify: `test/core/router/scaffold_with_nav_bar_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.6.1: Read existing test

Read `test/core/router/scaffold_with_nav_bar_test.dart`.

#### Step 6.6.2: Rewrite with widget tests

Replace trivial type checks with ~3 widget tests:

1. `pumpWidget renders child widget`
2. `Bottom navigation bar shows expected 4 tab items (Dashboard, Calendar, Projects, Settings)`
3. `Tab selection triggers correct route navigation (use tester.tap() on nav bar items and verify GoRouter location change)`

> NOTE: ScaffoldWithNavBar is a presentation widget. Use `tester.pumpWidget()` with a MaterialApp.router wrapper and a real or mock GoRouter. The implementing agent should read `lib/core/router/scaffold_with_nav_bar.dart` to understand the widget's structure and tap behavior.

#### Step 6.6.3: Run targeted tests

Run: `pwsh -Command "flutter test test/core/router/scaffold_with_nav_bar_test.dart"`
Expected: All tests PASS

---

### Sub-phase 6.7: Final Verification

**Agent**: `qa-testing-agent`

#### Step 6.7.1: Run flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues found

#### Step 6.7.2: Verify app_redirect_test.dart untouched

Run: `pwsh -Command "flutter test test/core/router/app_redirect_test.dart"`
Expected: All 27 tests PASS (untouched per spec)

> NOTE: The orchestrator runs `flutter test` (full suite) after each phase. This sub-phase only runs targeted checks to confirm the test rewrites didn't break anything.
