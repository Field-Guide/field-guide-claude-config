# Pattern: Feature Initializer

## How We Do It

Feature initializers are static factory classes with a private constructor (`ClassName._()`) and a static `create()` method that accepts `CoreDeps` and returns a typed deps object. They construct all datasources, repositories, use cases, and providers for their feature domain. The pattern ensures zero `Supabase.instance.client` access — the client comes from `coreDeps.supabaseClient`.

## Exemplars

### AuthInitializer (lib/features/auth/di/auth_initializer.dart:28-118)

```dart
class AuthInitializer {
  AuthInitializer._();

  /// Constructs all auth-layer dependencies from CoreDeps.
  static Future<AuthDeps> create(CoreDeps coreDeps) async {
    final supabaseClient = coreDeps.supabaseClient;
    final dbService = coreDeps.dbService;
    final preferencesService = coreDeps.preferencesService;

    // Datasources
    final companyLocalDs = CompanyLocalDatasource(dbService);
    final companyRepository = CompanyRepository(companyLocalDs);
    final userProfileLocalDatasource = UserProfileLocalDatasource(dbService);
    final userProfileRemoteDs = supabaseClient != null
        ? UserProfileRemoteDatasource(supabaseClient)
        : null;
    final userProfileRepository = UserProfileRepository(
      userProfileLocalDatasource,
      remoteDatasource: userProfileRemoteDs,
    );

    // Service
    final authService = AuthService(supabaseClient);

    // Use cases
    final signInUseCase = SignInUseCase(authService: authService, ...);
    final signOutUseCase = SignOutUseCase(authService: authService, ...);
    // ... more use cases ...

    // Provider
    final authProvider = AuthProvider(...all use cases...);
    final appConfigProvider = AppConfigProvider(...);

    return AuthDeps(
      authService: authService,
      authProvider: authProvider,
      appConfigProvider: appConfigProvider,
      companyLocalDatasource: companyLocalDs,
    );
  }
}
```

### ProjectInitializer (lib/features/projects/di/project_initializer.dart:25-107)

Same pattern: `ProjectInitializer._()` + `static Future<ProjectDeps> create(CoreDeps coreDeps)`.

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `AuthInitializer.create` | auth_initializer.dart:35 | `static Future<AuthDeps> create(CoreDeps coreDeps)` | Auth feature construction |
| `ProjectInitializer.create` | project_initializer.dart:33 | `static Future<ProjectDeps> create(CoreDeps coreDeps)` | Project feature construction |
| `EntryInitializer.create` | entry_initializer.dart:22 | `static EntryDeps create(CoreDeps coreDeps)` | Entry feature construction (sync, no async) |
| `FormInitializer.create` | form_initializer.dart:16 | `static Future<FormDeps> create(CoreDeps coreDeps)` | Form feature construction |
| `SyncProviders.initialize` | sync_providers.dart:27 | `static Future<({SyncOrchestrator, SyncLifecycleManager})> initialize({...})` | Sync subsystem (takes more params than CoreDeps) |

## Imports

```dart
import 'package:construction_inspector/core/di/core_deps.dart';
import 'package:construction_inspector/core/di/app_dependencies.dart';
// Feature-specific datasource/repository/service imports
```

## Key Conventions

1. Private constructor: `ClassName._()`
2. Static factory: `static Future<FeatureDeps> create(CoreDeps coreDeps)`
3. Extract `supabaseClient`, `dbService`, `preferencesService` from `coreDeps` first
4. Null-safe Supabase handling: `supabaseClient != null ? RemoteDs(client) : null`
5. Return typed deps object (e.g., `AuthDeps`, `ProjectDeps`)
6. No business logic — pure construction
