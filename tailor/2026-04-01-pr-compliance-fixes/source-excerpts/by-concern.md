# Source Excerpts by Concern

## Concern 1: AppInitializer Decomposition

### Steps 1-2: Core Services (lines 66-97) — extract to `core_services_initializer.dart`

```dart
// Step 1: Core services
final preferencesService = PreferencesService();
await preferencesService.initialize();
final consentAccepted = preferencesService.getBool('consent_accepted') ?? false;
const aptabaseKey = String.fromEnvironment('APTABASE_APP_KEY');
if (consentAccepted && aptabaseKey.isNotEmpty) {
  await Aptabase.init(aptabaseKey);
  Analytics.enable();
}
await _initDebugLogging(preferencesService, logDirOverride: options.logDirOverride);
TestModeConfig.logStatus();
ConfigValidator.logValidation();

// Step 2: Database
DatabaseService.initializeFfi();
final dbService = DatabaseService();
final db = await dbService.database;
final trashRepository = TrashRepository(dbService);
final softDeleteService = SoftDeleteService(db);
```

Returns: `(PreferencesService, DatabaseService, Database, TrashRepository, SoftDeleteService)`

### Steps 3-4: Platform Init (lines 99-145) — extract to `platform_initializer.dart`

```dart
// Step 3: OCR
try {
  final tessdataPath = await TesseractInitializer.initialize();
  final languages = await TesseractInitializer.getLanguages();
} catch (e, stack) {
  Logger.error('Tesseract initialization failed', error: e, stack: stack);
}

// Step 4: Supabase + Firebase
if (SupabaseConfig.isConfigured) {
  await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey, ...);
}
final supabaseClient = options.supabaseClientOverride ??
    (SupabaseConfig.isConfigured ? Supabase.instance.client : null);
if (Platform.isAndroid || Platform.isIOS) {
  try { await Firebase.initializeApp(); } catch (e) { ... }
}
```

Returns: `SupabaseClient?`

### Step 5: CoreDeps (lines 147-166) — extract to `media_services_initializer.dart`

```dart
final photoDatasource = PhotoLocalDatasource(dbService);
final photoRepository = PhotoRepositoryImpl(photoDatasource);
final photoService = PhotoService(photoRepository);
final imageService = ImageService();
final permissionService = PermissionService();
final coreDeps = CoreDeps(dbService: dbService, preferencesService: preferencesService, ...);
```

Returns: `(CoreDeps, PhotoRepositoryImpl)` — photoRepository needed for FeatureDeps

### Steps 8-9: Auth Wiring + Startup Gate (lines 215-249) — extract to `startup_gate.dart`

```dart
// Step 8: Auth listener
bool wasAuthenticated = authProvider.isAuthenticated;
authProvider.addListener(() {
  final isNowAuthenticated = authProvider.isAuthenticated;
  if (wasAuthenticated && !isNowAuthenticated) {
    appConfigProvider.clearOnSignOut();
    projectDeps.projectSyncHealthProvider.clear();
    // ...
  }
  wasAuthenticated = isNowAuthenticated;
});

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
```

### Step 10: Remaining Deps (lines 251-260) — extract to `remaining_deps_initializer.dart`

```dart
final locationRepository = LocationRepositoryImpl(LocationLocalDatasource(dbService));
final contractorRepository = ContractorRepositoryImpl(ContractorLocalDatasource(dbService));
final equipmentRepository = EquipmentRepositoryImpl(EquipmentLocalDatasource(dbService));
final personnelTypeRepository = PersonnelTypeRepositoryImpl(PersonnelTypeLocalDatasource(dbService));
final bidItemRepository = BidItemRepositoryImpl(BidItemLocalDatasource(dbService));
final entryQuantityRepository = EntryQuantityRepositoryImpl(EntryQuantityLocalDatasource(dbService));
final calculationHistoryRepository = CalculationHistoryRepositoryImpl(CalculationHistoryLocalDatasource(dbService));
final todoItemRepository = TodoItemRepositoryImpl(TodoItemLocalDatasource(dbService));
```

Returns: `FeatureDeps`

---

## Concern 2: BackgroundSyncHandler Fix

### Current _performDesktopSync (line 131-168)

Uses `Supabase.instance.client` at line 151. Needs to accept stored client instead.

### Current initialize (line 89-128)

```dart
static Future<void> initialize({DatabaseService? dbService}) async {
```

Needs: `static Future<void> initialize({DatabaseService? dbService, SupabaseClient? supabaseClient})`

---

## Concern 3: Route Table Categories

See ground-truth.md for the full 42-route table with categories already assigned to modules.

---

## Concern 4: main.dart Widget Extraction

### ConstructionInspectorApp (lib/main.dart:65-91)

```dart
class ConstructionInspectorApp extends StatelessWidget {
  const ConstructionInspectorApp({
    super.key,
    required this.providers,
    required this.appRouter,
  });
  final List<SingleChildWidget> providers;
  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp.router(
        title: 'Construction Inspector',
        theme: AppThemeData.lightTheme,
        darkTheme: AppThemeData.darkTheme,
        highContrastTheme: AppThemeData.highContrastTheme,
        highContrastDarkTheme: AppThemeData.highContrastDarkTheme,
        routerConfig: appRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

Extract to `lib/core/app_widget.dart`.
