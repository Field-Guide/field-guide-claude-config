# Pattern: DI Initializer

## How We Do It
Each feature has an initializer class in `features/<feature>/di/` that constructs and wires dependencies. Initializers are static or factory methods, called from `app_initializer.dart` during startup. They receive cross-cutting deps (DatabaseService, SupabaseClient) as parameters and return the feature's top-level dependencies.

## Exemplars

### SyncInitializer (`lib/features/sync/di/sync_initializer.dart`)
Multi-step creation with the current setter pattern (to be replaced by Builder):
```dart
class SyncInitializer {
  static Future<SyncOrchestrator> create({
    required DatabaseService dbService,
    SupabaseClient? supabaseClient,
    required AppConfigProvider appConfigProvider,
    // ... other deps
  }) async {
    // Step 1: construct orchestrator
    final orchestrator = SyncOrchestrator(dbService, supabaseClient: supabaseClient);
    await orchestrator.initialize();
    // Steps 2-8: setter injection (to be replaced by builder)
    orchestrator.setUserProfileSyncDatasource(...);
    orchestrator.setSyncContextProvider(...);
    orchestrator.setAppConfigProvider(appConfigProvider);
    orchestrator.setAdapterCompanyContext(...);
    return orchestrator;
  }
}
```

### AuthInitializer (`lib/features/auth/di/auth_initializer.dart`)
Standard pattern — constructs use cases and services:
```dart
class AuthInitializer {
  static AuthInitializerResult create({
    required DatabaseService dbService,
    SupabaseClient? supabaseClient,
    // ...
  }) {
    final authService = AuthService(...);
    final signInUseCase = SignInUseCase(
      authService: authService,
      switchCompanyUseCase: switchCompanyUseCase, // ← being removed
    );
    // ... returns result containing all auth dependencies
  }
}
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `SyncInitializer.create` | `sync_initializer.dart:16` | `static Future<SyncOrchestrator> create(...)` | App startup sync wiring |
| `AuthInitializer.create` | `auth_initializer.dart` | `static AuthInitializerResult create(...)` | App startup auth wiring |

## Imports
```dart
import 'package:construction_inspector/features/sync/di/sync_initializer.dart';
import 'package:construction_inspector/features/auth/di/auth_initializer.dart';
```
