# Clean Architecture Refactor Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Decompose main.dart god function into feature-scoped DI modules and introduce Clean Architecture domain layer across all 17 features.
**Spec:** `.claude/specs/2026-03-29-clean-architecture-refactor-spec.md`
**Analysis:** `.claude/dependency_graphs/2026-03-29-clean-architecture-refactor/`

**Architecture:** Top-down refactor: extract main.dart into feature modules first, then add domain layer (use cases + repository interfaces) feature-by-feature. Provider package retained, no DI framework.
**Tech Stack:** Flutter, Dart, Provider, SQLite (drift), Supabase
**Blast Radius:** ~100 new files, ~50 modified, ~30 tests updated, 0 deleted

---

## Phase 8: Sync Module Registration (Minimal Touch)

**Goal:** Move all sync-related instantiation and provider registration out of `main.dart` into a dedicated `sync_providers.dart` module. Zero logic changes — pure code-motion refactor.

**Why this is last:** Sync is the most complex wiring in `main.dart` (lines 278–542, 956–992). It has 10 setter injections, a 100-line `onPullComplete` lambda, lifecycle observer registration, FCM initialization, and cross-cutting dependencies on `AuthProvider`, `AppConfigProvider`, `DatabaseService`, and `ProjectLifecycleService`. Moving it last means all its dependencies are already modularized by earlier phases.

### Sub-phase 8.1: Create SyncProviders Module

**Files:**
- `lib/features/sync/di/sync_providers.dart` (NEW)
- `lib/features/sync/di/di.dart` (NEW — barrel export)

**Agent:** backend-supabase-agent

**Steps:**

1. Create `lib/features/sync/di/sync_providers.dart` with a `SyncProviders` class containing two static methods:

   ```dart
   /// Pre-widget-tree initialization. Called from main() before runApp().
   /// Returns a record of the initialized sync objects that main() passes
   /// to ConstructionInspectorApp.
   static Future<({
     SyncOrchestrator orchestrator,
     SyncLifecycleManager lifecycleManager,
   })> initialize({
     required DatabaseService dbService,
     required AuthProvider authProvider,
     required AppConfigProvider appConfigProvider,
   }) async { ... }
   ```

   ```dart
   /// Returns the list of Provider entries for MultiProvider.
   /// Called from ConstructionInspectorApp.build().
   static List<SingleChildWidget> providers({
     required SyncOrchestrator syncOrchestrator,
     required SyncLifecycleManager syncLifecycleManager,
     required ProjectLifecycleService projectLifecycleService,
     required ProjectSyncHealthProvider projectSyncHealthProvider,
   }) { ... }
   ```

2. Move the following code blocks **AS-IS** from `main.dart` `_runApp()` into `SyncProviders.initialize()`:

   - `SyncOrchestrator` instantiation + `await syncOrchestrator.initialize()` (line 279–280)
   - `CompanyLocalDatasource` + `CompanyRepository` instantiation (lines 284–285) — these exist solely for sync wiring, so they move with it
   - `UserProfileSyncDatasource` conditional creation + `setUserProfileSyncDatasource()` (lines 289–297)
   - `SyncLifecycleManager` instantiation (line 300)
   - `updateSyncContext()` closure + `authProvider.addListener(updateSyncContext)` (lines 349–358)
   - `setSyncContextProvider()` call (lines 361–364)
   - `onPullComplete` 100-line lambda **AS-IS** (lines 369–465)
   - FCM initialization block — conditional mobile-only (lines 468–471)
   - `setAppConfigProvider()` call (line 479)
   - `isReadyForSync` wiring (lines 520–523)
   - `onAppResumed` wiring (lines 526–539)
   - `WidgetsBinding.instance.addObserver(syncLifecycleManager)` (line 542)

   **CRITICAL:** The `onPullComplete` lambda (lines 369–465) must move character-for-character. It contains security fixes (FIX 3, FIX 4, FIX 5, FIX 6, CRIT-4) and transaction logic. Do NOT refactor, rename, or reformat it.

   **CRITICAL:** `BackgroundSyncHandler.initialize()` (line 211) stays in `main.dart` — it runs before sync orchestrator exists and only needs `dbService`. Do NOT move it.

3. Move the following provider registrations **AS-IS** from `ConstructionInspectorApp.build()` into `SyncProviders.providers()`:

   - `Provider<SyncRegistry>.value(value: SyncRegistry.instance)` (line 956)
   - `Provider<SyncOrchestrator>.value(value: syncOrchestrator)` (lines 958–959)
   - `ChangeNotifierProvider` for `SyncProvider` including all wiring (lines 960–992): `onStaleDataWarning`, `onForcedSyncInProgress`, `onSyncCycleComplete`, `onNewAssignmentDetected`

4. Create barrel export `lib/features/sync/di/di.dart`:
   ```dart
   export 'sync_providers.dart';
   ```

**Verification:**
- `SyncProviders.initialize()` returns a record — no global state, no singletons
- `SyncProviders.providers()` returns `List<SingleChildWidget>` — composable with other modules
- The `onPullComplete` lambda is byte-identical to the original
- `CompanyRepository` is returned from `initialize()` if `AuthProvider` still needs it (check if auth phase already provides it — if so, accept it as a parameter instead of creating it)

### Sub-phase 8.2: Wire SyncProviders into main.dart

**Files:**
- `lib/main.dart` (MODIFY)

**Agent:** backend-supabase-agent

**Steps:**

1. Add import for `sync_providers.dart`:
   ```dart
   import 'package:construction_inspector/features/sync/di/sync_providers.dart';
   ```

2. In `_runApp()`, replace the sync initialization block (lines 278–542) with:
   ```dart
   // Initialize sync module (orchestrator, lifecycle manager, FCM, all wiring)
   final syncResult = await SyncProviders.initialize(
     dbService: dbService,
     authProvider: authProvider,
     appConfigProvider: appConfigProvider,
   );
   final syncOrchestrator = syncResult.orchestrator;
   final syncLifecycleManager = syncResult.lifecycleManager;
   ```

   **Note:** `authProvider` must be created BEFORE this call (it currently is — line 309). Verify ordering is preserved.

   **Note:** `CompanyRepository` is also needed by `AuthProvider` (line 313). If `AuthProvider` creates it internally or receives it from an earlier phase's module, then `SyncProviders` can create its own instance. If `AuthProvider` receives the same instance, then `SyncProviders.initialize()` must either accept it as a parameter or return it. Check the dependency: `AuthProvider` constructor takes `companyRepository` (line 313) — so the `CompanyLocalDatasource` + `CompanyRepository` instantiation (lines 284–285) must stay in `main.dart` (or move to an auth module in an earlier phase). **Resolve this by keeping `companyRepository` creation in `main.dart` and passing it into `SyncProviders.initialize()`:**

   Update the `initialize()` signature to accept `companyRepository`:
   ```dart
   static Future<...> initialize({
     required DatabaseService dbService,
     required AuthProvider authProvider,
     required AppConfigProvider appConfigProvider,
     required CompanyLocalDatasource companyLocalDs,
   }) async { ... }
   ```

3. In `ConstructionInspectorApp.build()`, replace the three sync-related provider entries (lines 956–992) with a spread:
   ```dart
   ...SyncProviders.providers(
     syncOrchestrator: syncOrchestrator,
     syncLifecycleManager: syncLifecycleManager,
     projectLifecycleService: projectLifecycleService,
     projectSyncHealthProvider: projectSyncHealthProvider,
   ),
   ```

4. Remove now-unused sync imports from `main.dart`:
   - `sync_orchestrator.dart` — accessed via `SyncProviders` return value
   - `sync_lifecycle_manager.dart` — accessed via `SyncProviders` return value
   - `user_profile_local_datasource.dart` — moved into `SyncProviders`
   - `user_profile_sync_datasource.dart` — moved into `SyncProviders`
   - `fcm_handler.dart` — moved into `SyncProviders`
   - `sync_registry.dart` — moved into `SyncProviders`
   - `sync_provider.dart` — moved into `SyncProviders`

   **Keep** these imports in `main.dart` (still used directly):
   - `background_sync_handler.dart` — `BackgroundSyncHandler.initialize()` stays in `main.dart`
   - `company_local_datasource.dart` — passed to both `AuthProvider` and `SyncProviders`
   - `company_repository.dart` — passed to `AuthProvider`

5. Remove `syncOrchestrator` and `syncLifecycleManager` fields from `ConstructionInspectorApp` if they are no longer passed through (check: they may still be needed as constructor params if `SyncProviders.providers()` receives them). **Decision:** Keep them as constructor params since `SyncProviders.providers()` needs them. The fields stay; only the provider registration code in `build()` changes.

### Sub-phase 8.3: Verify and Clean Up

**Files:**
- `lib/features/sync/di/sync_providers.dart` (VERIFY)
- `lib/main.dart` (VERIFY)

**Agent:** backend-supabase-agent

**Steps:**

1. Run static analysis:
   ```
   pwsh -Command "flutter analyze"
   ```
   Fix any unused import warnings or type mismatches.

2. Run full test suite:
   ```
   pwsh -Command "flutter test"
   ```
   All existing tests must pass with zero changes. If any test fails, it means a dependency was broken during the move — fix the wiring, do NOT modify test expectations.

3. Verify `main.dart` line count reduction. Expected: ~180 lines removed from `_runApp()` (sync init block) + ~35 lines removed from `build()` (provider registrations) = ~215 fewer lines. `main.dart` should now be under ~850 lines (down from ~1070).

4. Verify `sync_providers.dart` has NO logic changes:
   - No renamed variables
   - No reordered statements
   - No added/removed null checks
   - No modified lambda bodies
   - Comments preserved (especially security fix annotations: FIX 3, FIX 4, FIX 5, FIX 6, CRIT-4, SEC-101, SEC-102)

5. Grep for orphaned references:
   - Search `main.dart` for `syncOrchestrator.set` — should be zero (all setter calls moved)
   - Search `main.dart` for `syncOrchestrator.on` — should be zero (all callback wiring moved)
   - Search `main.dart` for `syncLifecycleManager.` — should only be in `ConstructionInspectorApp` constructor/field declarations and the `providers:` spread call
   - Search `main.dart` for `FcmHandler` — should be zero (moved)

**Commands:**
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test"
```

---

## Validation Checklist

- [ ] `main.dart` under 50 lines
- [ ] Zero `Supabase.instance.client` in any `presentation/` file
- [ ] Zero raw `dbService.database` in any `presentation/` file
- [ ] Every feature has `domain/` directory
- [ ] All providers have `dispose()` override
- [ ] Zero `catch(_)` in refactored files
- [ ] `pwsh -Command "flutter analyze"` — clean
- [ ] `pwsh -Command "flutter test"` — all pass
- [ ] App cold-starts correctly on device
- [ ] Auth sign-in/sign-out/switch-company works
- [ ] Project create/delete/select works
- [ ] Sync push/pull works
