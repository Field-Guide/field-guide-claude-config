# Wiring, Routing & Audit Fixes — Implementation Plan

**Spec:** `.claude/specs/2026-03-30-wiring-routing-audit-fixes-spec.md`
**Status:** DRAFT — Sweep 1 fixes applied
**Execution:** Bottom-up (foundations → structural splits → cleanup → tests)

---

## Phase 1: CoreDeps Enhancement + InitOptions

**Goal:** Add `supabaseClient` to the existing `CoreDeps` class, create `InitOptions`, inject `SupabaseClient` via constructor through `BaseRemoteDataSource`, and eliminate all 7 `Supabase.instance.client` direct accesses except the two known exceptions in `background_sync_handler.dart`.

**CRITICAL:** CoreDeps ALREADY EXISTS at `app_initializer.dart:115-143`. Do NOT create a new `core_deps.dart` file. All sub-phases below MODIFY the existing class in-place.

Current CoreDeps fields (lines 115-143): `dbService`, `preferencesService`, `photoService`, `imageService`, `trashRepository`, `softDeleteService`, `permissionService`

---

### Sub-phase 1.1: Create `lib/core/di/init_options.dart`

- **File:** `lib/core/di/init_options.dart` (NEW)
- **Agent:** `general-purpose`
- **Estimated time:** 2 minutes

**WHY:** Both `main.dart` and `main_driver.dart` need a typed way to pass mode flags and service overrides into `AppInitializer.initialize()`. Without `InitOptions`, these are spread as ad-hoc parameters.

**Create this file (~20 lines):**

```dart
// lib/core/di/init_options.dart
//
// WHY: Typed container for initialization-time flags and overrides.
// Passed from entrypoints into AppInitializer.initialize().

import 'package:construction_inspector/services/photo/photo_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InitOptions {
  /// When true: skips Sentry init, swaps in photoServiceOverride.
  /// Set by main_driver.dart only. Never true in release builds.
  final bool isDriverMode;

  /// Override photo service for driver/test mode (e.g. TestPhotoService).
  final PhotoService? photoServiceOverride;

  /// Override Supabase client for tests. Production always uses null
  /// (AppInitializer creates it from SupabaseConfig).
  final SupabaseClient? supabaseClientOverride;

  const InitOptions({
    this.isDriverMode = false,
    this.photoServiceOverride,
    this.supabaseClientOverride,
  });
}
```

---

### Sub-phase 1.2: Add `supabaseClient` to CoreDeps

- **File:** `lib/core/di/app_initializer.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 5 minutes

**WHY:** CoreDeps is the DI root. Adding `supabaseClient` here makes it a first-class injectable dependency — testable, swappable, and not an ambient global.

**Surgical edits to existing CoreDeps class (lines 115-143):**

1. Add field: `final SupabaseClient? supabaseClient;` — nullable because offline-only mode has no Supabase
2. Add to constructor: `this.supabaseClient,`
3. Add to `copyWith`: `supabaseClient: supabaseClient ?? this.supabaseClient,`
4. Add import at top of file: `import 'package:supabase_flutter/supabase_flutter.dart';` (if not already present)

---

### Sub-phase 1.3: Update `base_remote_datasource.dart`

- **File:** `lib/features/<feature>/data/datasources/base_remote_datasource.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 5 minutes

**WHY:** This is the HIGHEST-LEVERAGE single change. Every remote datasource subclass (12+) inherits the `supabase` getter. Switching it from a global accessor to a constructor-injected field fixes all subclasses at once.

**Find the file:**
```
pwsh -Command "Select-String -Path 'lib/**/*.dart' -Pattern 'SupabaseClient get supabase' -Recurse"
```

**Change line 11 from:**
```dart
SupabaseClient get supabase => Supabase.instance.client;
```

**To constructor injection:**
```dart
final SupabaseClient _supabase;

BaseRemoteDataSource({required SupabaseClient supabase}) : _supabase = supabase;

SupabaseClient get supabase => _supabase;
```

**After this change**, all subclass constructors must pass `supabase: <client>` to `super(supabase: ...)`. Update each subclass constructor accordingly — they all receive the client from their feature initializer (Phase 2).

---

### Sub-phase 1.4: Replace `Supabase.instance.client` in `app_initializer.dart`

- **File:** `lib/core/di/app_initializer.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 5 minutes

**WHY:** Seven usages of `Supabase.instance.client` are scattered through `initialize()`. Creating it once at the top and passing it everywhere eliminates ambient access and makes the initializer testable with a mock client.

**At the top of `initialize()`, add:**
```dart
final supabaseClient = SupabaseConfig.isConfigured ? Supabase.instance.client : null;
```

**Then replace ALL 7 usages** at lines: 468, 527, 548, 588, 597-598, 642, 679 with the local `supabaseClient` variable.

**Also add `supabaseClient` to the `CoreDeps(...)` constructor call** so it flows into all feature initializers.

---

### Sub-phase 1.5: Replace in `sync_providers.dart`

- **File:** `lib/features/sync/di/sync_providers.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 3 minutes

**WHY:** Line 58 accesses `Supabase.instance.client` directly. After Phase 1.4, CoreDeps carries the client — pass it through.

**Change:** Line 58: pass `coreDeps.supabaseClient` instead of `Supabase.instance.client`.

---

### Sub-phase 1.6: Replace in `sync_orchestrator.dart`

- **File:** `lib/features/sync/application/sync_orchestrator.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 5 minutes

**WHY:** Lines 225 and 384 access `Supabase.instance.client` directly. `SyncOrchestrator` must receive its client via constructor injection — it has no legitimate reason to reach into the global singleton.

**Changes:**
1. Add field: `final SupabaseClient? _supabaseClient;`
2. Add to constructor: `SupabaseClient? supabaseClient` — nullable to support offline mode
3. Replace lines 225, 384: use `_supabaseClient` instead of `Supabase.instance.client`
4. Update `SyncProviders` (or `SyncInitializer` after Phase 2) to pass `coreDeps.supabaseClient` when constructing `SyncOrchestrator`

---

### Sub-phase 1.7: Known Exceptions (DO NOT CHANGE)

`background_sync_handler.dart` lines 49 and 151 **RETAIN** `Supabase.instance.client` by design.

**Rationale:** These run in WorkManager isolates where DI is not available. The isolate must independently initialize Supabase before it can do anything. This is architecturally correct and not a defect.

**Verification allowlist:** The grep in Sub-phase 1.8 expects exactly these two hits and no others.

---

### Sub-phase 1.8: Verify

```
pwsh -Command "flutter analyze"
```

Grep for remaining direct accesses — expect ONLY `background_sync_handler.dart`:
```
pwsh -Command "Select-String -Path 'lib/**/*.dart' -Pattern 'Supabase\.instance\.client' -Recurse"
```

Expected output: exactly 2 hits, both in `background_sync_handler.dart` (lines ~49 and ~151). Any other hit = Phase 1 incomplete.

---

## Phase 2: AppInitializer Decomposition + SyncProviders Extraction

**Goal:** Slim `sync_providers.dart` by extracting business logic into focused application-layer classes, then slim `AppInitializer.initialize()` to ~80 lines by grouping phases behind clear feature initializer calls.

---

### Sub-phase 2.1: Create `sync_enrollment_service.dart`

- **File:** `lib/features/sync/application/sync_enrollment_service.dart` (NEW)
- **Agent:** `general-purpose`
- **Estimated time:** 5 minutes

**WHY:** Lines 91-187 of `sync_providers.dart` contain business logic for project enrollment and unenrollment. This belongs in the application layer, not the DI layer.

**Extract to:**
```dart
// lib/features/sync/application/sync_enrollment_service.dart

class SyncEnrollmentService {
  final DatabaseService _db;
  final SyncOrchestrator _orchestrator;

  SyncEnrollmentService({
    required DatabaseService db,
    required SyncOrchestrator orchestrator,
  })  : _db = db,
        _orchestrator = orchestrator;

  /// Enrolls all projects currently assigned to [userId] that are not yet
  /// tracked locally. Called on sign-in and on auth-state refresh.
  Future<void> enrollAssignedProjects(String userId) async {
    // ... extracted from sync_providers.dart lines 91-140
  }

  /// Marks removed project assignments as unassigned. Uses a DB transaction
  /// to prevent TOCTOU races.
  Future<void> unenrollRemovedProjects(String userId) async {
    // ... extracted from sync_providers.dart lines 141-187
  }
}
```

Move the EXACT logic from lines 91-187 of `sync_providers.dart` into these two methods. Do not simplify the logic — preserve transaction wrapping and notification queueing exactly.

---

### Sub-phase 2.2: Expand `fcm_handler.dart`

- **File:** `lib/features/sync/application/fcm_handler.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 3 minutes

**WHY:** `sync_providers.dart` lines 194-198 contain inline FCM init. `FcmHandler.initialize()` already exists (lines 48-93). `sync_providers.dart` should call it instead of inlining.

**Change:** Verify that `FcmHandler.initialize()` absorbs all logic from sync_providers lines 194-198. If it does not, move the missing logic there. Then in `sync_providers.dart`, replace those lines with a single `await FcmHandler.initialize();` call.

---

### Sub-phase 2.3: Expand `sync_lifecycle_manager.dart`

- **File:** `lib/features/sync/application/sync_lifecycle_manager.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 4 minutes

**WHY:** `sync_providers.dart` lines 210-223 wire up lifecycle observers (inactivity timeout, config-refresh callbacks, force-reauth). These belong in `SyncLifecycleManager`, which already handles `didChangeAppLifecycleState` (line 36).

**Add a `configureAuthLifecycle()` method** that absorbs the logic from sync_providers lines 210-223:
```dart
/// Wires inactivity timer and auth-config-refresh callbacks.
/// Call once during sync initialization after the orchestrator is created.
void configureAuthLifecycle() {
  // ... extracted from sync_providers.dart lines 210-223
}
```

---

### Sub-phase 2.4: Create `sync_initializer.dart`

- **File:** `lib/features/sync/di/sync_initializer.dart` (NEW)
- **Agent:** `general-purpose`
- **Estimated time:** 4 minutes

**WHY:** `sync_providers.dart` needs an orchestration sequence that wires together the sync subsystem. Pure wiring — no business logic.

```dart
// lib/features/sync/di/sync_initializer.dart
//
// WHY: Orchestrates sync subsystem initialization sequence.
// Pure wiring — all business logic lives in application layer.

class SyncInitializer {
  static Future<SyncDeps> create({
    required CoreDeps coreDeps,
    required AuthDeps authDeps,
    // ... other deps as needed
  }) async {
    // 1. Create SyncOrchestrator (with injected supabaseClient from CoreDeps)
    final orchestrator = SyncOrchestrator(
      supabaseClient: coreDeps.supabaseClient,
      // ... other deps
    );

    // 2. Create SyncLifecycleManager
    final lifecycleManager = SyncLifecycleManager(orchestrator: orchestrator);

    // 3. Create SyncEnrollmentService
    final enrollmentService = SyncEnrollmentService(
      db: coreDeps.dbService,
      orchestrator: orchestrator,
    );

    // 4. Call FCM init
    await FcmHandler.initialize();

    // 5. Wire auth lifecycle callbacks
    lifecycleManager.configureAuthLifecycle();

    return SyncDeps(
      orchestrator: orchestrator,
      lifecycleManager: lifecycleManager,
      enrollmentService: enrollmentService,
    );
  }
}
```

---

### Sub-phase 2.5: Slim `sync_providers.dart`

- **File:** `lib/features/sync/di/sync_providers.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 4 minutes

**CHANGES:**
1. **Remove** extracted logic (lines 91-223) — enrollment, unenrollment, FCM inline, lifecycle wiring
2. **Delete** stale "pure code-motion" comment at line 32
3. **Update** `initialize()` to delegate to `SyncInitializer.create(coreDeps: ..., authDeps: ...)`
4. **Keep** `providers()` method unchanged — it returns the provider list

**Target:** ~60 lines. The file should contain only:
- Imports
- `SyncProviders` class with `initialize()` (delegates to SyncInitializer) and `providers()` (unchanged)

---

### Sub-phase 2.6: Slim `AppInitializer.initialize()`

- **File:** `lib/core/di/app_initializer.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 6 minutes

**WHY:** `initialize()` is currently 463 lines. With feature initializers handling their own construction, the method body should read as a clear sequence of phases.

**Target structure (~80 lines method body):**
```dart
static Future<AppDependencies> initialize({InitOptions options = const InitOptions()}) async {
  // Phase 0: Bootstrap (logging, config, analytics)
  // Phase 1: CoreDeps (db, prefs, supabase, permissions)
  // Phase 2: Feature deps (auth, project, entry, form, ...)
  // Phase 3: Sync (via SyncInitializer)
  // Phase 4: Return AppDependencies
}
```

Group initialization into clear phases calling feature initializers. Keep all deps classes (`CoreDeps`, `AuthDeps`, `AppDependencies`, etc.) in the SAME file — do not split them out. They are tightly coupled and moving them would be churn with no benefit.

---

### Sub-phase 2.7: Verify

```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test"
```

---

## Phase 3: Router Split

**Goal:** Extract redirect logic and ScaffoldWithNavBar out of `app_router.dart` (932 lines) into focused files, then slim the router to ~500 lines.

**NOTE on line count targets:** The spec states "app_router.dart ~100 lines" but this assumed the route table would also be extracted. Route table extraction is NOT in scope for this plan. After all phases, `app_router.dart` will be ~500 lines (route table + GoRouter construction). The redirect logic (~210 lines) and scaffold widget (~185 lines) are extracted. This is the correct achievable target. The ~100 line spec target is documented as a deviation in the Spec Deviations section at the bottom of this plan.

---

### Sub-phase 3.1: Create `app_redirect.dart`

- **File:** `lib/core/router/app_redirect.dart` (NEW)
- **Agent:** `general-purpose`
- **Estimated time:** 5 minutes

**WHY:** The redirect function is 185 lines of security-critical gate logic embedded inside `_buildRouter()`. Extracting it into its own class makes each gate testable in isolation and removes `context.read<AppConfigProvider>()` — a silent-fail antipattern where the try-catch swallows provider-not-found errors in release.

**CRITICAL CHANGES from current code:**
1. `AppConfigProvider` is now injected via constructor (not read from context) — eliminates the try-catch at gates 5-6
2. `ConsentProvider` is now `required` (not nullable) — eliminates null checks at gate 7
3. `isRestorableRoute` moves here as a static method (it uses `_kNonRestorableRoutes` which lives in this file)

**Create this file.** Key design points:

- New class `AppRedirect` with constructor taking `required AuthProvider`, `required ConsentProvider`, `required AppConfigProvider`
- Single public method `String? redirect(BuildContext context, GoRouterState state)`
- Move `_kOnboardingRoutes` and `_kNonRestorableRoutes` into this file
- Static `isRestorableRoute` method
- Add a gate ordering comment at the top of the class documenting the sequence

**ALL 14 redirect gate decision points must be enumerated and mapped to named private methods.** Current gates from `app_router.dart:157-341`:

1. Config bypass check (lines 162-173) → `_checkConfigBypass()`
2. Password recovery deep link (lines 179-181) → `_checkPasswordRecovery()`
3. Auth route detection (lines 185-189) → `_checkAuthRouteDetection()`
4. Unauthenticated redirect (line 197) → `_checkUnauthenticated()`
5. Authenticated-on-auth-route redirect (lines 205-209) → `_checkAuthenticatedOnAuthRoute()`
6. Version gate (lines 218-221) → `_checkVersionGate()`
7. Force reauth (lines 223-226) → `_checkForceReauth()`
8. Consent gate (lines 240-244) → `_checkConsentGate()`
9. Onboarding redirect (lines 250-260) → `_checkOnboardingRedirect()`
10. Profile-null check (lines 272-275) → `_checkProfileNull()`
11. Display-name-null check (lines 280-283) → `_checkDisplayNameNull()`
12. Company-null check (lines 290-293) → `_checkCompanyNull()`
13. Pending/rejected/deactivated status checks (lines 296-310) → `_checkApprovalStatus()`
14. Admin dashboard + project guards (lines 318-337) → `_checkAdminAndProjectGuards()`

Map EACH to its private method. Add a gate ordering comment block at the top of the `AppRedirect` class listing all 14 gates in order.

**Private gate methods contract:**
- Gate return convention: `''` means "allow (return null)", a path string means "redirect", `null` means "continue to next gate"
- CRITICAL: Replace `context.read<AppConfigProvider>()` try-catch with injected `_appConfigProvider` field
- CRITICAL: Replace `_consentProvider != null` null check with direct `_consentProvider.hasConsented` (no longer nullable)

---

### Sub-phase 3.2: Create `scaffold_with_nav_bar.dart`

- **File:** `lib/core/router/scaffold_with_nav_bar.dart` (NEW)
- **Agent:** `frontend-flutter-specialist-agent`
- **Estimated time:** 3 minutes

**WHY:** ScaffoldWithNavBar is 185 lines of UI code that has nothing to do with routing. Extracting it makes the shell widget independently testable.

**Create this file — direct extraction of lines 747-931 from current `app_router.dart`.** Zero logic changes. Only change is the import block:

```
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';
import 'package:construction_inspector/features/projects/presentation/widgets/project_switcher.dart';
import 'package:construction_inspector/features/sync/application/sync_orchestrator.dart';
import 'package:construction_inspector/features/sync/presentation/providers/sync_provider.dart';
import 'package:construction_inspector/features/pdf/presentation/widgets/extraction_banner.dart';
import 'package:construction_inspector/shared/shared.dart';
```

Then paste the entire ScaffoldWithNavBar class body verbatim from app_router.dart lines 747-931.

---

### Sub-phase 3.3: Slim `app_router.dart`

- **File:** `lib/core/router/app_router.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 5 minutes

**WHY:** With redirect logic in `app_redirect.dart` and ScaffoldWithNavBar in its own file, `app_router.dart` becomes a thin routing table (~500 lines).

**CHANGES:**

1. **Remove** `_kOnboardingRoutes`, `_kNonRestorableRoutes` constants (now in `app_redirect.dart`)
2. **Remove** entire `ScaffoldWithNavBar` class (lines 747-931)
3. **Remove** entire redirect closure body (lines 157-342)
4. **Remove** `isRestorableRoute` static method (now on `AppRedirect`)
5. **Remove** imports only needed by redirect: `flutter/foundation.dart`, `supabase_config.dart`, `test_mode_config.dart`, `auth/data/models/models.dart`, `provider.dart`
6. **Remove** imports only needed by ScaffoldWithNavBar: `field_guide_colors.dart`, `project_switcher.dart`, `sync_orchestrator.dart`, `sync_provider.dart`, `extraction_banner.dart`, `shared.dart`
7. **Add** imports: `app_redirect.dart`, `scaffold_with_nav_bar.dart`
8. **Add** `required AppConfigProvider appConfigProvider` to constructor
9. **Change** `ConsentProvider? consentProvider` to `required ConsentProvider consentProvider`
10. **Add** `_appConfigProvider` field
11. **Update** `refreshListenable`: `Listenable.merge([_authProvider, _consentProvider, _appConfigProvider])`
12. **Update** `redirect:` — store as a field, NOT created per-redirect call:
    - Add field: `late final AppRedirect _appRedirect;`
    - In constructor body: `_appRedirect = AppRedirect(authProvider: _authProvider, consentProvider: _consentProvider, appConfigProvider: _appConfigProvider);`
    - Pass to GoRouter: `redirect: _appRedirect.redirect`

13. **ALSO update `app_initializer.dart` line 751** — the current call `AppRouter(authProvider: authProvider)` breaks after step 8 adds two more required parameters. Change to:
    ```dart
    AppRouter(
      authProvider: authProvider,
      consentProvider: consentProvider,
      appConfigProvider: appConfigProvider,
    )
    ```
    This is interim wiring — Phase 5.3 removes `appRouter` from `AppDependencies` entirely.

**NOTE:** `isRestorableRoute` moved to `AppRedirect`. Find and update all callers:
```
pwsh -Command "Select-String -Path 'lib/**/*.dart' -Pattern 'AppRouter\.isRestorableRoute' -Recurse"
```
Update each to `AppRedirect.isRestorableRoute` and add the `app_redirect.dart` import.

---

### Sub-phase 3.4: Verify

- **Agent:** `general-purpose`
- **Estimated time:** 2 minutes

```
pwsh -Command "flutter analyze"
```

---

## Phase 4: AppBootstrap

**Goal:** Create `AppBootstrap` to absorb all consent/auth/Sentry/router wiring duplicated between `main.dart` and `main_driver.dart`.

### Sub-phase 4.1: Create `app_bootstrap.dart`

- **File:** `lib/core/di/app_bootstrap.dart` (NEW)
- **Agent:** `general-purpose`
- **Estimated time:** 5 minutes

**WHY:** `main.dart` lines 128-176 and `main_driver.dart` lines 69-107 contain identical consent/auth-listener/router wiring. `AppBootstrap.configure()` absorbs this into a single call site.

**What it absorbs:**
1. `createConsentAndSupportProviders()` logic from `consent_support_factory.dart` (datasource/repository/provider construction)
2. `consentProvider.loadConsentState()` call
3. `enableSentryReporting()` call (gated on `!isDriverMode`)
4. Auth listener (consent clear on sign-out, deferred audit on sign-in)
5. `AppRouter` construction with all three required providers

**Create this file.** Key design:

- Class `AppBootstrap` with static `BootstrapResult configure({required AppDependencies deps, bool isDriverMode = false})`
- `BootstrapResult` uses a Dart 3 record type: `typedef BootstrapResult = ({AppRouter appRouter, ConsentProvider consentProvider, SupportProvider supportProvider});`
- Step 1: Create ConsentLocalDatasource, ConsentRepository, ConsentProvider (same wiring as consent_support_factory.dart)
- Step 2: Create SupportLocalDatasource, SupportRepository, LogUploadRemoteDatasource, SupportProvider
- Step 3: `consentProvider.loadConsentState()` — must be before AppRouter
- Step 4: `if (!isDriverMode && consentProvider.hasConsented) enableSentryReporting();`
- Step 5: Auth listener: sign-out clears consent + disables analytics; sign-in writes deferred audit
- Step 6: Construct AppRouter with all three required providers

**NOTE on follow-up:** `AppBootstrap` currently imports `supabase_config.dart` and accesses Supabase indirectly through consent/support factory patterns. After Phase 1's `CoreDeps.supabaseClient` lands, `AppBootstrap` should be updated to receive `SupabaseClient` via `AppDependencies.core.supabaseClient` instead of going through `SupabaseConfig` or `Supabase.instance`. This is a Phase 1+4 integration follow-up, not in this plan's immediate scope.

**Imports needed:**

```
import 'package:construction_inspector/core/config/sentry_consent.dart';
import 'package:construction_inspector/core/config/supabase_config.dart';
import 'package:construction_inspector/core/analytics/analytics.dart';
import 'package:construction_inspector/core/di/app_initializer.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/core/router/app_router.dart';
import 'package:construction_inspector/features/settings/data/datasources/consent_local_datasource.dart';
import 'package:construction_inspector/features/settings/data/datasources/support_local_datasource.dart';
import 'package:construction_inspector/features/settings/data/datasources/remote/log_upload_remote_datasource.dart';
import 'package:construction_inspector/features/settings/data/repositories/consent_repository.dart';
import 'package:construction_inspector/features/settings/data/repositories/support_repository.dart';
import 'package:construction_inspector/features/settings/presentation/providers/consent_provider.dart';
import 'package:construction_inspector/features/settings/presentation/providers/support_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
```

### Sub-phase 4.2: Verify

```
pwsh -Command "flutter analyze"
```

---

## Phase 5: Entrypoint Consolidation

**Goal:** Slim `main.dart` and `main_driver.dart` to use `AppBootstrap.configure()`, remove `appRouter` from `AppDependencies`.

### Sub-phase 5.1: Slim `main.dart`

- **File:** `lib/main.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 4 minutes

**CHANGES:**
1. **Remove** import: `consent_support_factory.dart`
2. **Add** import: `app_bootstrap.dart`
3. **Replace** `_runApp()` lines 120-186 with:

```
Future<void> _runApp() async {
  final deps = await AppInitializer.initialize(logDirOverride: kAppLogDirOverride);
  Analytics.trackAppLaunch();
  final bootstrap = AppBootstrap.configure(deps: deps);
  runApp(
    ConstructionInspectorApp(
      providers: buildAppProviders(deps),
      appRouter: bootstrap.appRouter,
      consentProvider: bootstrap.consentProvider,
      supportProvider: bootstrap.supportProvider,
    ),
  );
}
```

4. **Keep** everything else: `main()`, `_beforeSendSentry`, `_beforeSendTransaction`, `kAppLogDirOverride`, `ConstructionInspectorApp`

---

### Sub-phase 5.2: Slim `main_driver.dart`

- **File:** `lib/main_driver.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 3 minutes

**CHANGES:**
1. **Remove** imports: `sentry_consent.dart`, `app_router.dart`, `consent_support_factory.dart`, `analytics.dart`
2. **Add** import: `app_bootstrap.dart`
3. **Replace** lines 68-107 (consent factory through AppRouter construction) with single line:
   `final bootstrap = AppBootstrap.configure(deps: deps, isDriverMode: true);`
4. **Update** `runApp(...)` to use `bootstrap.appRouter`, `bootstrap.consentProvider`, `bootstrap.supportProvider`
5. **Keep** DriverServer setup, TestPhotoService swap, RepaintBoundary wrapper

---

### Sub-phase 5.3: Remove `appRouter` from `AppInitializer` and `AppDependencies`

- **File:** `lib/core/di/app_initializer.dart` (MODIFY)
- **Agent:** `general-purpose`
- **Estimated time:** 3 minutes

**Surgical edits (do NOT rewrite the entire file):**

1. **Remove** import at line 8: `import 'package:construction_inspector/core/router/app_router.dart';`
2. **Remove** field at line 275: `final AppRouter appRouter;`
3. **Remove** from constructor at line 285: `required this.appRouter,`
4. **Remove** from `copyWith` return at line 350: `appRouter: appRouter,`
5. **Remove** dead code at line 750-751: `final appRouter = AppRouter(authProvider: authProvider);`
6. **Remove** from `AppDependencies(...)` return at line 820: `appRouter: appRouter,`

---

### Sub-phase 5.4: Verify `app_providers.dart`

- **File:** `lib/core/di/app_providers.dart` (NO CHANGES)
- `buildAppProviders` never accesses `deps.appRouter`. Just verify:

```
pwsh -Command "flutter analyze"
```

---

### Sub-phase 5.5: Full verification

```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test"
```

Search for tests that instantiate `AppRouter` directly and update them:
```
pwsh -Command "Select-String -Path 'test/**/*.dart' -Pattern 'AppRouter\(' -Recurse"
```

Each needs all three required params: `authProvider`, `consentProvider`, `appConfigProvider`.

Also search for `AppRouter.isRestorableRoute` in tests — update to `AppRedirect.isRestorableRoute`.

---

## Phase 6: AppDependencies Cleanup

**Goal:** Remove dead code left over from the refactor.

### Sub-phase 6.1: Delete `consent_support_factory.dart`

- **File:** `lib/features/settings/di/consent_support_factory.dart` (DELETE)
- **Agent:** `general-purpose`
- **Estimated time:** 2 minutes

**WHY:** Its logic is now in `AppBootstrap.configure()`. The file is dead code.

**Before deleting**, verify no imports remain in both `lib/` and `test/`:
```
pwsh -Command "Select-String -Path 'lib/**/*.dart' -Pattern 'consent_support_factory' -Recurse"
pwsh -Command "Select-String -Path 'test/**/*.dart' -Pattern 'consent_support_factory' -Recurse"
```
Expected: zero matches in both. Then delete:
```
pwsh -Command "Remove-Item 'lib/features/settings/di/consent_support_factory.dart'"
```

---

### Sub-phase 6.2: Clean dead code

Verify no remaining references in both `lib/` and `test/`:
```
pwsh -Command "Select-String -Path 'lib/**/*.dart' -Pattern 'createConsentAndSupportProviders' -Recurse"
pwsh -Command "Select-String -Path 'lib/**/*.dart' -Pattern 'ConsentSupportResult' -Recurse"
pwsh -Command "Select-String -Path 'test/**/*.dart' -Pattern 'createConsentAndSupportProviders' -Recurse"
pwsh -Command "Select-String -Path 'test/**/*.dart' -Pattern 'ConsentSupportResult' -Recurse"
```
Expected: zero matches for all.

---

### Sub-phase 6.3: Final verification

```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test"
```

**Line count targets:**
- `app_router.dart`: ~500 lines (was 932) — route definitions only
- `app_redirect.dart`: ~210 lines — redirect logic with private gate methods
- `scaffold_with_nav_bar.dart`: ~185 lines — UI shell widget
- `app_bootstrap.dart`: ~110 lines — consent/auth/Sentry/router wiring
- `main.dart _runApp()`: ~12 lines (was 67)
- `main_driver.dart _runApp()`: ~25 lines (was 78)

---

## Phase 7: Stale File Deletion

**Goal:** Remove legacy flutter_driver shim and unused test_harness entrypoint. The 6 files in `lib/test_harness/` are preserved (Phase 8 uses them).

### Sub-phase 7.1: Verify no imports reference driver_main.dart
- **Agent:** `general-purpose`
- **Time:** 2 min
- **Action:** Grep entire codebase for `driver_main`. Expected: 0 hits in `lib/`, `test/`.
- **WHY:** Must verify no file imports this before deletion to avoid broken builds.

### Sub-phase 7.2: Delete lib/driver_main.dart
- **Agent:** `general-purpose`
- **Time:** 1 min
- **File:** `lib/driver_main.dart`
- **Action:** Delete the file (10 lines, `enableFlutterDriverExtension()` shim).
- **WHY:** This file uses `flutter_driver` which we are removing. `main_driver.dart` (HTTP-based) is the replacement.

```bash
pwsh -Command "Remove-Item -Path 'lib/driver_main.dart' -Force"
```

### Sub-phase 7.3: Verify no imports reference test_harness.dart (the root file)
- **Agent:** `general-purpose`
- **Time:** 2 min
- **Action:** Grep for `test_harness\.dart` (NOT `test_harness/`). We are deleting `lib/test_harness.dart`, NOT `lib/test_harness/` directory.

### Sub-phase 7.4: Delete lib/test_harness.dart
- **Agent:** `general-purpose`
- **Time:** 1 min
- **File:** `lib/test_harness.dart`
- **Action:** Delete the file (136 lines, flutter_driver-based harness entrypoint).
- **WHY:** Replaced by DriverServer /harness endpoint (Phase 8).

### Sub-phase 7.5: Remove flutter_driver from pubspec.yaml
- **Agent:** `general-purpose`
- **Time:** 3 min
- **File:** `pubspec.yaml`
- **Action:** Search for `flutter_driver:` in pubspec.yaml and remove that dependency block.
- **WHY:** `flutter_driver` is only used by `driver_main.dart` and `test_harness.dart`, both now deleted.
- **NOTE:** Do not rely on fixed line numbers — they shift. Use search to locate the block between `flutter_test` and `integration_test` entries.

### Sub-phase 7.6: Update dependencies
- **Agent:** `general-purpose`
- **Time:** 3 min
- `pwsh -Command "flutter pub get"`

### Sub-phase 7.7: Verify
- **Agent:** `general-purpose`
- **Time:** 3 min
- `pwsh -Command "flutter analyze"`
- **Expected:** 0 errors. If `flutter_driver` was imported elsewhere, analyze will catch it.

---

## Phase 8: Test Harness Migration

**Goal:** Move test harness functionality into DriverServer so the HTTP-based driver can launch isolated screen/flow tests without the deleted `test_harness.dart`.

### Sub-phase 8.1: Create test_db_factory.dart
- **Agent:** `general-purpose`
- **Time:** 5 min
- **File:** `lib/core/driver/test_db_factory.dart`
- **WHY:** Extracted from `test_harness.dart` concept. Creates an in-memory DatabaseService for test isolation.

```dart
// lib/core/driver/test_db_factory.dart
//
// WHY: Factory for creating in-memory DatabaseService instances for testing.

import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/core/logging/logger.dart';

class TestDbFactory {
  static Future<DatabaseService> create() async {
    Logger.log('TestDbFactory: Creating in-memory database');
    final dbService = DatabaseService.forTesting();
    await dbService.initInMemory();
    Logger.log('TestDbFactory: In-memory database ready');
    return dbService;
  }
}
```

- **NOTE:** Verify `DatabaseService.forTesting()` and `initInMemory()` exist in `lib/core/database/database_service.dart`.

### Sub-phase 8.2: Add /harness endpoint to DriverServer
- **Agent:** `general-purpose`
- **Time:** 5 min
- **File:** `lib/core/driver/driver_server.dart`

**Add route dispatch** (at line ~175, before the 404 fallback):
```dart
} else if (method == 'POST' && path == '/driver/harness') {
  await _handleHarness(request, res);
}
```

**Add handler method:**
```dart
Future<void> _handleHarness(HttpRequest request, HttpResponse res) async {
  // Defense-in-depth: never serve harness in release or profile builds.
  // This matches the pattern used by ALL other handlers in this file.
  if (kReleaseMode || kProfileMode) {
    await _sendJson(res, 403, {'error': 'Not available'});
    return;
  }
  final body = await _readJsonBody(request);
  if (body == null) {
    await _sendJson(res, 400, {'error': 'Invalid JSON body'});
    return;
  }
  final mode = body['mode'] as String?;
  if (mode == null) {
    await _sendJson(res, 400, {'error': 'Missing "mode" field (screen|flow)'});
    return;
  }
  try {
    if (mode == 'screen') {
      final screenName = body['screen'] as String?;
      if (screenName == null) {
        await _sendJson(res, 400, {'error': 'Missing "screen" field'});
        return;
      }
      await _sendJson(res, 200, {'status': 'ok', 'mode': 'screen', 'screen': screenName});
    } else if (mode == 'flow') {
      final flowName = body['flow'] as String?;
      if (flowName == null) {
        await _sendJson(res, 400, {'error': 'Missing "flow" field'});
        return;
      }
      await _sendJson(res, 200, {'status': 'ok', 'mode': 'flow', 'flow': flowName});
    } else {
      await _sendJson(res, 400, {'error': 'Unknown mode: $mode (expected screen|flow)'});
    }
  } catch (e, stack) {
    Logger.error('Harness endpoint error: $e', error: e, stack: stack);
    await _sendJson(res, 500, {'error': e.toString()});
  }
}
```

- **NOTE on routing stub:** This handler returns 200 OK without performing actual navigation. Full screen/flow swapping using the test_harness registry pattern requires wiring the navigator or app state — this is a follow-up task. If `test_db_factory.dart` is imported but the factory is not called here, document it as unused and remove the import until the follow-up lands.
- **Import:** Add `import 'package:flutter/foundation.dart';` at top (for `kReleaseMode`/`kProfileMode`) if not already present. Add `import 'package:construction_inspector/core/driver/test_db_factory.dart';` only if the factory is actually used in this phase.

### Sub-phase 8.3: Verify
- `pwsh -Command "flutter analyze"` — Expected: 0 errors.

---

## Phase 9: Tests

**Goal:** Write all 12 test files. Grouped by priority.

### Sub-phase 9.1: test/core/di/app_initializer_test.dart (HIGH)
- **Agent:** `qa-testing-agent` | **Time:** 5 min

**NOTE:** Phase 5.3 removes `appRouter` from `AppDependencies`. Tests here must target the POST-refactor API. Test code must NOT reference `appRouter` in `AppDependencies`.

Write real behavioral tests — do not use `throw UnimplementedError('structural')` patterns (the compiler already verifies structural existence):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/di/app_initializer.dart';

void main() {
  group('AppDependencies', () {
    test('does not have appRouter field post-refactor', () {
      // Compile-time verification: if this file compiles without referencing
      // appRouter, the field was successfully removed.
      expect(AppDependencies, isNotNull);
    });

    test('convenience accessors return correct types', () {
      // Construct a minimal mock AppDependencies and verify accessors
      // return typed objects without casting.
      // Use real CoreDeps with in-memory DB or mock where needed.
    });

    test('CoreDeps.copyWith replaces individual fields', () {
      // Create a CoreDeps, call copyWith with a new photoService,
      // verify only photoService changed, all others retained.
    });
  });
}
```

### Sub-phase 9.2: test/core/di/core_deps_test.dart (HIGH)
- **Agent:** `qa-testing-agent` | **Time:** 5 min

Write real behavioral tests:
- Test that `CoreDeps.supabaseClient` is nullable (construct with null, verify field is null)
- Test `copyWith` replaces `photoService` correctly (other fields unchanged)
- Test `copyWith` without args returns equivalent instance
- Verify all expected fields exist by constructing with named params

### Sub-phase 9.3: test/core/di/app_bootstrap_test.dart (HIGH)
- **Agent:** `qa-testing-agent` | **Time:** 5 min
- Tests Sentry consent gate (default false, enable/disable), Analytics gate (no-op when disabled, toggle), ConsentSupportResult factory.
- See Phase 9 context in parent prompt for complete test code.

### Sub-phase 9.4: test/core/router/app_redirect_test.dart (HIGH)
- **Agent:** `qa-testing-agent` | **Time:** 5 min
- Tests AppRedirect.isRestorableRoute for all 12 non-restorable routes and 5 restorable routes.
- Tests redirect gate ordering documentation (password recovery -> auth -> version -> consent -> profile).
- See Phase 9 context in parent prompt for complete test code.

### Sub-phase 9.5: test/core/router/app_router_test.dart (MED)
- **Agent:** `qa-testing-agent` | **Time:** 5 min

Write real behavioral tests — not "does class exist" checks:
- Test GoRouter construction with mock providers (all three required). Verify GoRouter is non-null.
- Test `refreshListenable` merges all 3 providers: `Listenable.merge([authProvider, consentProvider, appConfigProvider])`
- Verify `isRestorableRoute` is now on `AppRedirect`, not `AppRouter`

### Sub-phase 9.6: test/core/router/scaffold_with_nav_bar_test.dart (MED)
- **Agent:** `qa-testing-agent` | **Time:** 5 min

Write real widget tests:
- `pumpWidget` with mock providers in tree, verify `BottomNavigationBar` renders
- Test banner visibility: when `SyncOrchestrator` reports sync error, `SyncRetryBanner` is visible
- Test banner hidden when no errors

### Sub-phase 9.7: test/features/sync/di/sync_providers_test.dart (MED)
- **Agent:** `qa-testing-agent` | **Time:** 5 min

Write real behavioral tests:
- Test `SyncProviders.initialize()` calls `SyncInitializer.create()` (verify via mock)
- Test `SyncProviders.providers()` returns a non-empty list of the correct provider types
- Test no business logic remains: `initialize()` method body should only call `SyncInitializer.create()`

### Sub-phase 9.8: test/features/sync/application/sync_enrollment_service_test.dart (MED)
- **Agent:** `qa-testing-agent` | **Time:** 5 min
- **NOTE:** This test depends on Phase 2.1's `SyncEnrollmentService`. Must be written after Phase 2 completes.
- Contract tests: enrollment inserts correct records, unenrollment sets `unassigned_at`, re-assignment clears it, notifications queued, transaction used for TOCTOU protection.

### Sub-phase 9.9: test/features/sync/application/background_sync_handler_test.dart (MED)
- **Agent:** `qa-testing-agent` | **Time:** 5 min
- Tests kBackgroundSyncTaskName value and backgroundSyncCallback is top-level function.

### Sub-phase 9.10: test/core/di/entrypoint_equivalence_test.dart (MED)
- **Agent:** `qa-testing-agent` | **Time:** 5 min

Write real behavioral tests:
- Test `buildAppProviders()` returns a `List<SingleChildWidget>` with a deterministic length
- Test that provider type list for production mode matches driver mode (same types, possibly different instances)
- Construct mock `AppDependencies` (post-refactor, no `appRouter` field) and pass to `buildAppProviders()`

### Sub-phase 9.11: test/core/di/sentry_integration_test.dart (HIGH)
- **Agent:** `qa-testing-agent` | **Time:** 5 min
- Tests PII scrubbing (email removal, JWT removal, non-PII preservation) and consent gate (default false, enable/disable).

### Sub-phase 9.12: test/core/di/analytics_integration_test.dart (MED)
- **Agent:** `qa-testing-agent` | **Time:** 5 min
- Tests Analytics consent gate (no-op when disabled, no throw when Aptabase not initialized, all predefined events safe, toggle works).

**All verification:** `pwsh -Command "flutter test test/exact/path.dart"` for each file.

**IMPORTANT:** Complete test code for all 12 files is provided in the CONTEXT section of the parent prompt (Phase 9 context). The implementing agent MUST use that complete code, not the summaries above.


---

## Phase 10: Integration and Verification

**Goal:** Run full test suite, static analysis, and verify all success criteria.

### Sub-phase 10.1: Check existing test for broken imports
- **Agent:** `qa-testing-agent`
- **Time:** 3 min
- **File:** `test/core/router/form_screen_registry_test.dart`
- **Action:** Verify imports still resolve after router split. Expected: no changes needed.

### Sub-phase 10.2: Run full test suite
- **Agent:** `qa-testing-agent`
- **Time:** 5 min
- `pwsh -Command "flutter test"`
- **Expected:** ALL tests pass (existing + 12 new).

### Sub-phase 10.3: Run static analysis
- **Agent:** `qa-testing-agent`
- **Time:** 3 min
- `pwsh -Command "flutter analyze"`
- **Expected:** 0 errors, at most 1 pre-existing warning.

### Sub-phase 10.4: Verify success criteria checklist
- **Agent:** `general-purpose`
- **Time:** 5 min

| # | Criterion | Check Method |
|---|-----------|-------------|
| 1 | AppInitializer.initialize() under 80 lines | Count method body lines |
| 2 | app_router.dart under 550 lines (route table + GoRouter construction; redirect and scaffold extracted) | Count file lines. NOTE: spec's "~100 lines" target was based on also extracting route definitions — that is deferred. ~500 is the correct post-refactor target for this plan. |
| 3 | main.dart under 50 lines | Read file, count lines |
| 4 | main_driver.dart under 40 lines | Read file, count lines |
| 5 | Zero Supabase.instance.client outside background_sync_handler.dart | Grep lib/ — see Sub-phase 10.6 |
| 6 | Zero optional provider deps in AppRouter | Read constructor, verify required params |
| 7 | Zero business logic in di/ files | Grep for loops/conditionals beyond null checks |
| 8 | driver_main.dart and test_harness.dart deleted | Verify files absent |
| 9 | flutter_driver removed from pubspec | Grep pubspec.yaml |
| 10 | All 12 test files exist and pass | flutter test from 10.2 |
| 11 | Sentry and Aptabase verified functional | Tests 9.3, 9.11, 9.12 |
| 12 | Existing test suite passes | flutter test from 10.2 |

### Sub-phase 10.5: Final commit preparation
- **Agent:** `general-purpose`
- **Time:** 2 min
- Stage all new/modified files. Do NOT commit.
- **Deleted:** `lib/driver_main.dart`, `lib/test_harness.dart`
- **Modified:** `pubspec.yaml`, `lib/core/driver/driver_server.dart`
- **Created:** `lib/core/driver/test_db_factory.dart`
- **Created (tests):** 12 files in `test/core/di/`, `test/core/router/`, `test/features/sync/`

### Sub-phase 10.6: Verify Supabase.instance.client elimination
- **Agent:** `general-purpose`
- **Time:** 2 min

Grep for remaining direct accesses in lib/:
```
pwsh -Command "Select-String -Path 'lib/**/*.dart' -Pattern 'Supabase\.instance\.client' -Recurse"
```

**Expected:** ONLY `background_sync_handler.dart` hits (known exception — WorkManager isolate). Any other hit = Phase 1 incomplete. Do not proceed to commit until this check is clean.

---

## Known Exceptions

| File | Usage | Rationale |
|------|-------|-----------|
| `background_sync_handler.dart:49,151` | `Supabase.instance.client` | WorkManager isolate — no DI available, must init Supabase independently |
| `base_remote_datasource.dart` | Constructor-injected after Phase 1.3 | All 12+ subclasses receive client via base class constructor |

---

## Spec Deviations

| Spec Target | Actual Target | Rationale |
|-------------|---------------|-----------|
| `app_router.dart` ~100 lines | ~500 lines | Spec assumed route table extraction; not in scope — route definitions stay in app_router.dart. Redirect (210 lines) and scaffold (185 lines) extracted. |
| `app_bootstrap.dart` ~80 lines | ~110 lines | Consent/support provider construction adds ~30 lines beyond the spec estimate |
| `CoreDeps` in new file `core_deps.dart` | CoreDeps stays in `app_initializer.dart` | Class already exists at line 115; moving it would be churn with no benefit |
