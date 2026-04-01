# Source Excerpts by File

## lib/core/di/app_initializer.dart (341 lines)

**Key symbol**: `AppInitializer.initialize` (lines 61-286, 226 lines)
- Full source available in by-concern.md, broken by step
- Private helpers: `_initDebugLogging` (lines 288-329), `_ensureLogDirectoryWritable` (lines 331-341)

## lib/core/router/app_router.dart (540 lines)

**Key symbols**:
- `_kNonRestorableRoutes` (line 33): Set of 6 route paths
- `AppRouter` constructor (line 60): Takes AuthProvider, AppConfigProvider, ConsentProvider
- `setInitialLocation` (line 74): Sets `_initialLocation` field
- `isRestorableRoute` (line 82): Static, checks against `_kNonRestorableRoutes`
- `_mpResultFromJobResult` (line 90): Deserializes MpExtractionResult from MpJobResult — moves to form_routes.dart
- `_buildRouter` (line 125): The 410-line route table — decomposed into 8 route modules

## lib/core/di/init_options.dart (33 lines)

```dart
class InitOptions {
  final bool isDriverMode;         // ← DEAD CODE, remove
  final String logDirOverride;
  final SupabaseClient? supabaseClientOverride;

  const InitOptions({
    this.isDriverMode = false,     // ← DEAD CODE, remove
    this.logDirOverride = '',
    this.supabaseClientOverride,
  });
}
```

## lib/features/sync/application/background_sync_handler.dart (185 lines)

**Key symbols**:
- `kBackgroundSyncTaskName` (line 13): `'com.fieldguideapp.inspector.sync'`
- `backgroundSyncCallback` (line 20): Top-level function for WorkManager isolate — uses `Supabase.instance.client` (line 49, UNAVOIDABLE)
- `BackgroundSyncHandler.initialize` (line 89): Currently `{DatabaseService? dbService}` — add `SupabaseClient? supabaseClient`
- `BackgroundSyncHandler._performDesktopSync` (line 131): Uses `Supabase.instance.client` at line 151 — FIXABLE

## lib/core/di/app_bootstrap.dart (137 lines)

**Key symbols**:
- `AppBootstrapResult` (line 17): Value object with consentProvider, supportProvider, appRouter
- `AppBootstrap.configure` (line 53): Static method taking `AppDependencies`, returns `AppBootstrapResult`
- `AppBootstrap.resetForTesting` (line 43): Resets the configured guard

## lib/main.dart (92 lines)

- `kAppLogDirOverride` (line 17): String.fromEnvironment constant
- `main()` (line 22): Sentry wrapper
- `_runApp()` (line 45): AppInitializer → AppBootstrap → runApp
- `ConstructionInspectorApp` (line 65): Extract to `lib/core/app_widget.dart`

## lib/main_driver.dart (77 lines)

- Same `kAppLogDirOverride` constant (line 22)
- `main()` (line 27): No Sentry wrapper
- `_runApp()` (line 40): Same flow but adds TestPhotoService swap + DriverServer start

## lib/core/database/schema/sync_engine_tables.dart

Lines with AUTOINCREMENT:
- Line 22: `id INTEGER PRIMARY KEY AUTOINCREMENT,` (change_log)
- Line 38: `id INTEGER PRIMARY KEY AUTOINCREMENT,` (conflict_log)
- Line 89: `id INTEGER PRIMARY KEY AUTOINCREMENT,` (storage_cleanup_queue)

## lib/core/database/schema_verifier.dart

Lines with AUTOINCREMENT:
- Line 265: `'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',` (change_log expected)
- Line 270: `'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',` (conflict_log expected)
- Line 277: `'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',` (storage_cleanup_queue expected)
