# Dependency Graph

## Direct Changes

| File | Symbols | Change Type |
|------|---------|-------------|
| `lib/core/di/app_initializer.dart` | `AppInitializer.initialize` | Decompose — extract steps to initializer modules |
| `lib/core/router/app_router.dart` | `AppRouter._buildRouter` | Decompose — extract route table to 7 modules |
| `lib/core/di/init_options.dart` | `InitOptions.isDriverMode` | Remove dead field |
| `lib/main.dart` | `ConstructionInspectorApp` | Extract widget to `lib/core/app_widget.dart` |
| `lib/main_driver.dart` | `_runApp` | Slim down, import shared setup |
| `lib/core/database/schema/sync_engine_tables.dart` | DDL strings | Remove AUTOINCREMENT |
| `lib/core/database/schema_verifier.dart` | Expected column defs | Remove AUTOINCREMENT |
| `.github/workflows/quality-gate.yml` | Supabase grep, Flutter version | Fix CI checks |
| `lib/features/sync/application/background_sync_handler.dart` | `initialize`, `_performDesktopSync` | Accept injected SupabaseClient |
| `lib/test_harness/*` (5 files) | All | DELETE |

## Upstream Dependencies (what app_initializer.dart imports)

```
app_initializer.dart
├── init_options.dart
├── app_dependencies.dart
│   ├── core_deps.dart
│   ├── AuthDeps, ProjectDeps, EntryDeps, FormDeps, SyncDeps, FeatureDeps
├── core_deps.dart
├── auth_initializer.dart
├── project_initializer.dart
├── entry_initializer.dart
├── form_initializer.dart
├── sync_providers.dart
├── background_sync_handler.dart
├── database_service.dart
├── preferences_service.dart
├── photo_service.dart, image_service.dart, permission_service.dart
├── supabase_flutter, firebase_core
├── tesseract_initializer.dart
└── ~20 repository/datasource imports (for Step 10 inline construction)
```

## Upstream Dependencies (what app_router.dart imports — 28 files)

```
app_router.dart
├── app_redirect.dart
├── scaffold_with_nav_bar.dart
├── logger.dart, app_route_observer.dart
├── auth screens (7): login, register, forgot_password, otp_verification, update_password, screens.dart
├── onboarding screens: profile_setup, company_setup, pending_approval, account_status
├── feature screens: dashboard, entries, projects, quantities, settings, pdf, forms, toolbox, sync
├── models: daily_entry.dart, mp_models.dart
├── services: extraction_pipeline, result_converter, extraction_result
├── providers: auth_provider, app_config_provider, consent_provider
└── registries: form_screen_registry
```

## Downstream Dependents (who imports these files)

| File | Importers |
|------|-----------|
| `app_initializer.dart` | `main.dart`, `main_driver.dart`, `app_bootstrap.dart` (3) |
| `app_router.dart` | `main.dart`, `app_bootstrap.dart`, `app_router_test.dart` (3) |
| `init_options.dart` | `app_initializer.dart`, `main.dart`, `main_driver.dart`, `app_initializer_test.dart`, `init_options_test.dart` (5) |
| `app_bootstrap.dart` | `main.dart`, `main_driver.dart`, `app_bootstrap_test.dart` (3) |
| `app_dependencies.dart` | `app_initializer.dart`, `app_providers.dart`, 4 feature initializers (6) |
| `core_deps.dart` | `app_dependencies.dart`, `core_deps_test.dart` (2) |
| `app_providers.dart` | `main.dart`, `main_driver.dart`, `app_providers_consent_test.dart`, `entrypoint_equivalence_test.dart` (4) |
| `scaffold_with_nav_bar.dart` | `app_router.dart`, `scaffold_with_nav_bar_test.dart` (2) |
| `background_sync_handler.dart` | `app_initializer.dart`, `sign_out_use_case.dart`, `auth_provider.dart`, `background_sync_handler_test.dart` (4) |
| `lib/test_harness/*` | **0 importers each** (confirmed dead) |

## Data Flow

```
main.dart / main_driver.dart
  → AppInitializer.initialize(InitOptions)
    → CoreServices (prefs, analytics, logging)
    → Database (FFI, DatabaseService)
    → Platform (OCR, Supabase, Firebase)
    → CoreDeps (photo chain, image, permission)
    → Feature initializers (auth, project, entry, form)
    → SyncProviders.initialize()
    → BackgroundSyncHandler.initialize()
    → Auth listener wiring
    → Startup gate
    → Remaining feature deps
    → returns AppDependencies
  → AppBootstrap.configure(AppDependencies)
    → ConsentProvider, SupportProvider
    → AppRouter construction
    → Auth listener for sign-out cleanup
    → returns AppBootstrapResult
  → runApp(ConstructionInspectorApp)
```
