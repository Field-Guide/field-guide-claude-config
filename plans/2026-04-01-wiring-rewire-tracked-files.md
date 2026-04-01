# Wiring Re-Wire: Tracked File Modifications Only

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Re-wire existing tracked files to import and use the 32 new files that survived the S697 data loss. NO new file creation — every file referenced as a dependency already exists and passed review.
**Context:** S697 implemented the full wiring-routing plan (8 phases, 3 reviews each). `git checkout --` destroyed tracked file modifications but left untracked new files intact. This plan replays ONLY the tracked-file edits.
**Original Plan:** `.claude/plans/2026-03-31-wiring-routing-audit-fixes.md`
**Spec:** `.claude/specs/2026-03-30-wiring-routing-audit-fixes-spec.md`

**Architecture:** Bottom-up. Phase 1 modifies the DI root, Phase 2 migrates callers, Phase 3 delegates feature init, Phase 4 splits the router, Phase 5 extracts sync, Phase 6 consolidates entrypoints, Phase 7 cleans up dead code.
**Tech Stack:** Flutter, Dart, GoRouter, Provider, Supabase, Sentry, SQLite
**Blast Radius:** ~10 tracked files modified, 3 deleted, 0 new files created

**CRITICAL CONSTRAINT:** Do NOT create, overwrite, or modify any of the 32 surviving new files listed below. They are COMPLETE and reviewed. Only modify the tracked files listed in each phase.

### Surviving New Files (DO NOT TOUCH)
```
lib/core/di/core_deps.dart
lib/core/di/init_options.dart
lib/core/di/app_bootstrap.dart
lib/core/di/app_dependencies.dart
lib/core/router/app_redirect.dart
lib/core/router/scaffold_with_nav_bar.dart
lib/core/config/sentry_pii_filter.dart
lib/features/auth/di/auth_initializer.dart
lib/features/entries/di/entry_initializer.dart
lib/features/forms/di/form_initializer.dart
lib/features/projects/di/project_initializer.dart
lib/features/sync/di/sync_initializer.dart
lib/features/sync/application/sync_enrollment_service.dart
lib/features/forms/data/registries/form_type_constants.dart
lib/core/driver/flow_registry.dart
lib/core/driver/harness_seed_data.dart  (has syntax fix needed — Phase 7)
lib/core/driver/screen_registry.dart
lib/core/driver/stub_router.dart
lib/core/driver/test_db_factory.dart
test/core/di/core_deps_test.dart
test/core/di/init_options_test.dart
test/core/di/app_bootstrap_test.dart
test/core/di/app_providers_consent_test.dart
test/core/di/app_initializer_test.dart
test/core/di/entrypoint_equivalence_test.dart
test/core/di/sentry_integration_test.dart
test/core/di/analytics_integration_test.dart
test/core/router/app_redirect_test.dart
test/core/router/app_router_test.dart
test/core/router/scaffold_with_nav_bar_test.dart
test/core/router/form_screen_registry_test.dart
test/features/sync/di/sync_providers_test.dart
test/features/sync/application/sync_enrollment_service_test.dart
```

---

## Phase 1: AppInitializer — Extract Types & Capture Supabase Client

Modify `lib/core/di/app_initializer.dart` to use the already-existing `CoreDeps`, `InitOptions`, and `AppDependencies` types. Remove inline type definitions and dead code. Capture `supabaseClient` once and thread it through.

---

### Sub-phase 1.1: Remove inline types and import new ones

**Files:**
- Modify: `lib/core/di/app_initializer.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 1.1.1: Read current state

Read `lib/core/di/app_initializer.dart` in full. Also read `lib/core/di/core_deps.dart`, `lib/core/di/init_options.dart`, and `lib/core/di/app_dependencies.dart` to understand the target types.

#### Step 1.1.2: Remove inline CoreDeps class

Delete the `CoreDeps` class definition (approximately lines 115-143 in app_initializer.dart). Replace with:
```dart
import 'package:construction_inspector/core/di/core_deps.dart';
```

The existing `CoreDeps` in `core_deps.dart` has the same fields plus a `supabaseClient` field. Verify field compatibility before deleting.

#### Step 1.1.3: Remove inline AuthDeps, ProjectDeps, EntryDeps, FormDeps, SyncDeps, FeatureDeps, AppDependencies classes

Delete ALL 7 dependency container class definitions AND the `AppDependencies` class from `app_initializer.dart`. Replace with:
```dart
import 'package:construction_inspector/core/di/app_dependencies.dart';
```

`app_dependencies.dart` already exports `core_deps.dart`, so the CoreDeps import from step 1.1.2 becomes redundant — use only the `app_dependencies.dart` import.

**WHY:** `app_dependencies.dart` defines all 7 DTOs (`AuthDeps`, `ProjectDeps`, etc.) plus `AppDependencies` with qualified accessor paths (`deps.core.dbService`, `deps.auth.authProvider`). The old inline `AppDependencies` had flat compatibility getters — those are gone.

#### Step 1.1.4: Remove dead appRouter field and construction

- Delete the `appRouter` field from any remaining `AppDependencies` references in `app_initializer.dart`
- Delete the dead `AppRouter(...)` construction call (approximately line 754)
- Remove the `import 'package:construction_inspector/core/router/app_router.dart'` if it was only used for that

#### Step 1.1.5: Change initialize() signature to accept InitOptions

Change:
```dart
static Future<AppDependencies> initialize({String logDirOverride = ''}) async {
```
To:
```dart
static Future<AppDependencies> initialize([InitOptions options = const InitOptions()]) async {
```

Add import:
```dart
import 'package:construction_inspector/core/di/init_options.dart';
```

Replace all references to `logDirOverride` parameter with `options.logDirOverride`. Replace `isDriverMode` conditionals (if any) with `options.isDriverMode`.

#### Step 1.1.6: Capture supabaseClient once after Supabase.initialize()

Find the line where `Supabase.initialize()` completes (approximately line 337). Immediately after, capture:
```dart
final supabaseClient = options.supabaseClientOverride ?? Supabase.instance.client;
```

Then replace ALL remaining `Supabase.instance.client` references (approximately 9 occurrences at lines 470, 529, 550, 590, 599, 644, 681, 694) with the local `supabaseClient` variable.

**WHY:** This eliminates the singleton pattern and makes the supabase client injectable for testing.

#### Step 1.1.7: Pass supabaseClient into CoreDeps

At the `CoreDeps(...)` construction site (approximately line 762), add `supabaseClient: supabaseClient` to the constructor call.

#### Step 1.1.8: Verify compilation

Run `pwsh -Command "flutter analyze lib/core/di/app_initializer.dart"` to check for errors. Fix any issues.

---

## Phase 2: Caller Migration — Qualified Accessor Paths

Update all callers of `AppDependencies` to use qualified paths (`deps.core.X`, `deps.auth.X`, etc.) instead of flat compatibility getters that no longer exist.

---

### Sub-phase 2.1: Migrate app_providers.dart

**Files:**
- Modify: `lib/core/di/app_providers.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 2.1.1: Read current state

Read `lib/core/di/app_providers.dart` and `lib/core/di/app_dependencies.dart` to map old accessor names to new qualified paths.

#### Step 2.1.2: Replace all flat accessors with qualified paths

Replace every `deps.<field>` call with the correct qualified path. The mapping is:

**Core:**
- `deps.dbService` → `deps.core.dbService`
- `deps.preferencesService` → `deps.core.preferencesService`
- `deps.photoService` → `deps.core.photoService`
- `deps.imageService` → `deps.core.imageService`
- `deps.trashRepository` → `deps.core.trashRepository`
- `deps.softDeleteService` → `deps.core.softDeleteService`
- `deps.permissionService` → `deps.core.permissionService`
- `deps.supabaseClient` → `deps.core.supabaseClient`

**Auth:**
- `deps.authProvider` → `deps.auth.authProvider`
- `deps.appConfigProvider` → `deps.auth.appConfigProvider`
- `deps.authService` → `deps.auth.authService`

**Project:**
- `deps.projectRepository` → `deps.project.projectRepository`
- `deps.projectLifecycleService` → `deps.project.projectLifecycleService`
- `deps.projectAssignmentRepository` → `deps.project.projectAssignmentRepository`
- `deps.syncedProjectRepository` → `deps.project.syncedProjectRepository`

**Entry:**
- `deps.dailyEntryRepository` → `deps.entry.dailyEntryRepository`
- `deps.documentRepository` → `deps.entry.documentRepository`
- `deps.entryExportRepository` → `deps.entry.entryExportRepository`

**Form:**
- `deps.inspectorFormRepository` → `deps.form.inspectorFormRepository`
- `deps.formResponseRepository` → `deps.form.formResponseRepository`
- `deps.formExportRepository` → `deps.form.formExportRepository`

**Sync:**
- `deps.syncOrchestrator` → `deps.sync.syncOrchestrator`

**Feature (remaining):**
- `deps.locationRepository` → `deps.feature.locationRepository`
- `deps.contractorRepository` → `deps.feature.contractorRepository`
- `deps.equipmentRepository` → `deps.feature.equipmentRepository`
- `deps.bidItemRepository` → `deps.feature.bidItemRepository`
- `deps.entryQuantityRepository` → `deps.feature.entryQuantityRepository`
- `deps.calculationHistoryRepository` → `deps.feature.calculationHistoryRepository`
- `deps.todoItemRepository` → `deps.feature.todoItemRepository`
- `deps.photoRepository` → `deps.feature.photoRepository`
- `deps.weatherService` → `deps.feature.weatherService`
- `deps.personnelTypeRepository` → `deps.feature.personnelTypeRepository`

#### Step 2.1.3: Update import

Change import from `app_initializer.dart` to `app_dependencies.dart`:
```dart
import 'package:construction_inspector/core/di/app_dependencies.dart';
```

---

### Sub-phase 2.2: Migrate main.dart and main_driver.dart

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/main_driver.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 2.2.1: Read both files

Read `lib/main.dart` and `lib/main_driver.dart` in full.

#### Step 2.2.2: Replace flat accessors in main.dart

Apply the same accessor mapping from step 2.1.2 to all `deps.<field>` calls in `main.dart`. Key replacements:
- `deps.authProvider` → `deps.auth.authProvider`
- `deps.appConfigProvider` → `deps.auth.appConfigProvider`
- `deps.dbService` → `deps.core.dbService`
- `deps.preferencesService` → `deps.core.preferencesService`
- `deps.supabaseClient` → `deps.core.supabaseClient`

Update import from `app_initializer.dart` to `app_dependencies.dart`.

#### Step 2.2.3: Replace flat accessors in main_driver.dart

Apply the same mapping. Key replacements:
- `deps.authProvider` → `deps.auth.authProvider`
- `deps.appConfigProvider` → `deps.auth.appConfigProvider`
- `deps.photoRepository` → `deps.feature.photoRepository`
- `deps.documentRepository` → `deps.entry.documentRepository`
- `deps.syncOrchestrator` → `deps.sync.syncOrchestrator`
- `deps.dbService` → `deps.core.dbService`
- `deps.projectLifecycleService` → `deps.project.projectLifecycleService`
- `deps.preferencesService` → `deps.core.preferencesService`
- `deps.supabaseClient` → `deps.core.supabaseClient`

Update import from `app_initializer.dart` to `app_dependencies.dart`.

#### Step 2.2.4: Verify compilation

Run `pwsh -Command "flutter analyze lib/main.dart lib/main_driver.dart lib/core/di/app_providers.dart"` to check for errors. Fix any issues.

---

## Phase 3: Feature Initializer Delegation

Replace ~380 lines of inline feature construction in `app_initializer.dart` with delegation calls to the already-existing feature initializer classes.

---

### Sub-phase 3.1: Delegate to feature initializers

**Files:**
- Modify: `lib/core/di/app_initializer.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 3.1.1: Read current state and initializers

Read `lib/core/di/app_initializer.dart` (post-Phase 1 edits). Also read all 4 feature initializers:
- `lib/features/auth/di/auth_initializer.dart`
- `lib/features/projects/di/project_initializer.dart`
- `lib/features/entries/di/entry_initializer.dart`
- `lib/features/forms/di/form_initializer.dart`

#### Step 3.1.2: Replace inline auth construction with AuthInitializer.create()

Find the section in `initialize()` that constructs auth datasources, repositories, use cases, auth provider, auth service, and app config provider. Replace the entire block with:
```dart
final authDeps = await AuthInitializer.create(coreDeps);
```

Add import:
```dart
import 'package:construction_inspector/features/auth/di/auth_initializer.dart';
```

Remove all auth-specific imports that are no longer directly referenced (datasources, repositories, use cases, etc.).

#### Step 3.1.3: Replace inline project construction with ProjectInitializer.create()

Find the section that constructs project datasources, repositories, lifecycle service, use cases, and providers. Replace with:
```dart
final projectDeps = await ProjectInitializer.create(coreDeps);
```

Add import:
```dart
import 'package:construction_inspector/features/projects/di/project_initializer.dart';
```

Remove project-specific imports no longer directly referenced.

#### Step 3.1.4: Replace inline entry construction with EntryInitializer.create()

Replace entry construction block with:
```dart
final entryDeps = EntryInitializer.create(coreDeps);
```

Note: `EntryInitializer.create()` is synchronous (no `await`).

Add import:
```dart
import 'package:construction_inspector/features/entries/di/entry_initializer.dart';
```

#### Step 3.1.5: Replace inline form construction with FormInitializer.create()

Replace form construction block with:
```dart
final formDeps = await FormInitializer.create(coreDeps);
```

Add import:
```dart
import 'package:construction_inspector/features/forms/di/form_initializer.dart';
```

#### Step 3.1.6: Assemble AppDependencies from feature deps

After all initializer calls, construct the return value:
```dart
return AppDependencies(
  core: coreDeps,
  auth: authDeps,
  project: projectDeps,
  entry: entryDeps,
  form: formDeps,
  sync: SyncDeps(...),  // sync is handled in Phase 5
  feature: FeatureDeps(...),  // remaining feature deps
);
```

**Note:** The sync and feature deps construction may still be inline at this point. That's fine — Phase 5 handles sync extraction. The remaining feature deps (location, contractor, equipment, bid item, quantity, calculator, todo, photo, weather, personnel type) stay inline until a future plan addresses them.

#### Step 3.1.7: Verify compilation

Run `pwsh -Command "flutter analyze lib/core/di/app_initializer.dart"`. Fix any issues.

---

## Phase 4: Router Split

Modify `lib/core/router/app_router.dart` to delegate redirect logic to `AppRedirect` and remove the inline `ScaffoldWithNavBar` class (already exists in its own file).

---

### Sub-phase 4.1: Slim down app_router.dart

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/main.dart`
- Modify: `lib/main_driver.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 4.1.1: Read current state

Read `lib/core/router/app_router.dart` in full. Also read `lib/core/router/app_redirect.dart` and `lib/core/router/scaffold_with_nav_bar.dart` to understand the target API.

#### Step 4.1.2: Update AppRouter constructor

Change the constructor to require all three providers:
```dart
AppRouter({
  required AuthProvider authProvider,
  required AppConfigProvider appConfigProvider,
  required ConsentProvider consentProvider,
  String? initialLocation,
})
```

Make `ConsentProvider` required (was nullable). Add `AppConfigProvider` parameter (was missing — previously read from context).

#### Step 4.1.3: Replace inline redirect with AppRedirect delegation

Create an `_appRedirect` field:
```dart
late final _appRedirect = AppRedirect(
  authProvider: _authProvider,
  appConfigProvider: _appConfigProvider,
  consentProvider: _consentProvider,
);
```

Replace the ~185-line inline redirect closure in `_buildRouter()` with:
```dart
redirect: (context, state) => _appRedirect.performRedirect(state.matchedLocation),
```

Add import:
```dart
import 'package:construction_inspector/core/router/app_redirect.dart';
```

#### Step 4.1.4: Remove inline ScaffoldWithNavBar class

Delete the entire `ScaffoldWithNavBar` class (approximately lines 747-931). Add import:
```dart
import 'package:construction_inspector/core/router/scaffold_with_nav_bar.dart';
```

#### Step 4.1.5: Update refreshListenable

Ensure `refreshListenable` merges ALL 3 providers:
```dart
refreshListenable: Listenable.merge([
  _authProvider,
  _appConfigProvider,
  _consentProvider,
]),
```

#### Step 4.1.6: Remove now-unused imports

After extracting redirect and scaffold, many imports become unused. Remove them. The route table still needs screen imports, but redirect-only imports (supabase_config, test_mode_config, auth models) and scaffold-only imports (field_guide_colors, sync_provider, extraction_banner) can go.

#### Step 4.1.7: Update main.dart AppRouter construction

Find the `AppRouter(...)` construction in `main.dart` and add the `appConfigProvider` parameter:
```dart
final router = AppRouter(
  authProvider: deps.auth.authProvider,
  appConfigProvider: deps.auth.appConfigProvider,
  consentProvider: consentProvider,
);
```

#### Step 4.1.8: Update main_driver.dart AppRouter construction

Same change in `main_driver.dart`.

#### Step 4.1.9: Verify compilation

Run `pwsh -Command "flutter analyze lib/core/router/app_router.dart lib/main.dart lib/main_driver.dart"`. Fix any issues.

---

## Phase 5: SyncProviders Extraction

Replace the business logic in `sync_providers.dart` `initialize()` with delegation to `SyncInitializer.create()`.

---

### Sub-phase 5.1: Delegate sync initialization

**Files:**
- Modify: `lib/features/sync/di/sync_providers.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 5.1.1: Read current state

Read `lib/features/sync/di/sync_providers.dart` in full. Also read `lib/features/sync/di/sync_initializer.dart` to understand the target API.

#### Step 5.1.2: Replace initialize() body

Replace the entire `initialize()` method body (~200 lines of raw SQL, enrollment logic, FCM init, lifecycle wiring, auth context wiring) with delegation to `SyncInitializer.create()`. The method should become approximately:
```dart
static Future<({SyncOrchestrator orchestrator, SyncLifecycleManager lifecycleManager})> initialize({
  required DatabaseService dbService,
  required AuthProvider authProvider,
  required AppConfigProvider appConfigProvider,
  // ... other params as needed by SyncInitializer
}) async {
  return SyncInitializer.create(
    dbService: dbService,
    authProvider: authProvider,
    appConfigProvider: appConfigProvider,
    // ... pass through
  );
}
```

Read `SyncInitializer.create()` signature carefully to match parameters.

Add import:
```dart
import 'package:construction_inspector/features/sync/di/sync_initializer.dart';
```

#### Step 5.1.3: Remove stale docstring

Remove the "Phase 8: Pure code-motion refactor" comment (approximately line 31).

#### Step 5.1.4: Remove unused imports

After replacing the body, many imports become unused (raw SQL helpers, datasources, etc.). Remove them.

#### Step 5.1.5: Verify compilation

Run `pwsh -Command "flutter analyze lib/features/sync/di/sync_providers.dart"`. Fix any issues.

---

## Phase 6: AppBootstrap & Entrypoint Consolidation

Consolidate `main.dart` and `main_driver.dart` to use `AppBootstrap.configure()`, eliminating duplicated consent/auth/router wiring. Extract PII scrubbing to the already-existing `sentry_pii_filter.dart`.

---

### Sub-phase 6.1: Consolidate main.dart

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/core/di/app_providers.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 6.1.1: Read current state

Read `lib/main.dart`, `lib/core/di/app_bootstrap.dart`, `lib/core/config/sentry_pii_filter.dart`, and `lib/core/di/app_providers.dart`.

#### Step 6.1.2: Update app_providers.dart to accept consent/support

Add optional parameters to `buildAppProviders()`:
```dart
List<SingleChildWidget> buildAppProviders(
  AppDependencies deps, {
  ConsentProvider? consentProvider,
  SupportProvider? supportProvider,
}) {
```

Insert the consent and support providers at Tier 0.5 (after core, before auth) when non-null:
```dart
if (consentProvider != null)
  ChangeNotifierProvider<ConsentProvider>.value(value: consentProvider),
if (supportProvider != null)
  Provider<SupportProvider>.value(value: supportProvider),
```

Add imports for `ConsentProvider` and `SupportProvider`.

#### Step 6.1.3: Rewrite main.dart to use AppBootstrap

Replace the current ~224-line `main()` with a slim version that:
1. Calls `AppInitializer.initialize(InitOptions())`
2. Calls `AppBootstrap.configure(deps)` to get `AppBootstrapResult` (consent, support, router)
3. Passes consent/support into `buildAppProviders(deps, consentProvider: result.consentProvider, supportProvider: result.supportProvider)`
4. Runs the app with `result.router`

Replace inline PII scrubbing functions with imports from `sentry_pii_filter.dart`:
```dart
import 'package:construction_inspector/core/config/sentry_pii_filter.dart';
```

Use `beforeSendSentry` and `beforeSendTransaction` directly in `SentryFlutter.init()`.

The `ConstructionInspectorApp` widget should slim down — it no longer needs `consentProvider`/`supportProvider` constructor params since those are in the provider tree.

Target: main.dart shrinks to ~45-60 lines.

#### Step 6.1.4: Verify compilation

Run `pwsh -Command "flutter analyze lib/main.dart lib/core/di/app_providers.dart"`.

---

### Sub-phase 6.2: Consolidate main_driver.dart

**Files:**
- Modify: `lib/main_driver.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 6.2.1: Rewrite main_driver.dart to use AppBootstrap

Replace ~122 lines with a slim version that:
1. Calls `AppInitializer.initialize(InitOptions(isDriverMode: true, logDirOverride: ...))`
2. Swaps PhotoService via `deps.copyWith(photoService: TestPhotoService(...))`
3. Starts `DriverServer`
4. Calls `AppBootstrap.configure(deps)` to get `AppBootstrapResult`
5. Passes consent/support into `buildAppProviders()`
6. Runs the app

Remove all duplicated consent/auth-listener/router wiring.

Target: main_driver.dart shrinks to ~55 lines.

#### Step 6.2.2: Verify compilation

Run `pwsh -Command "flutter analyze lib/main_driver.dart"`.

---

## Phase 7: Cleanup & Dead Code Removal

Delete stale files, fix the broken harness_seed_data.dart, update driver_server.dart, and clean pubspec.yaml.

---

### Sub-phase 7.1: Delete stale files

**Files:**
- Delete: `lib/driver_main.dart`
- Delete: `lib/test_harness.dart`
- Delete: `lib/test_harness/harness_providers.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 7.1.1: Verify no remaining imports

Search the codebase for imports of these three files:
```
grep -r "driver_main" lib/ test/
grep -r "test_harness.dart" lib/ test/
grep -r "harness_providers" lib/ test/
```

If any imports are found, they must be removed before deleting.

#### Step 7.1.2: Delete the files

Delete `lib/driver_main.dart`, `lib/test_harness.dart`, and `lib/test_harness/harness_providers.dart`.

---

### Sub-phase 7.2: Fix harness_seed_data.dart syntax errors

**Files:**
- Modify: `lib/core/driver/harness_seed_data.dart`

**Agent:** `frontend-flutter-specialist-agent`

**EXCEPTION TO DO-NOT-TOUCH RULE:** This is the ONE surviving file flagged BROKEN. Fix only the syntax errors — do not change logic.

#### Step 7.2.1: Fix em-dash comments

Read `lib/core/driver/harness_seed_data.dart`. Find all lines where an em-dash (`—`) appears after a semicolon without `//` prefix. Fix each by either:
- Adding `//` before the em-dash: `); // — harness seed cleanup`
- Or removing the comment entirely if it adds no value

Affected lines: approximately 134, 140, 145, 150, 158, 163, 168, 176, 219, 220.

---

### Sub-phase 7.3: Update pubspec.yaml and driver_server.dart

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/driver/driver_server.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 7.3.1: Remove flutter_driver dependency

In `pubspec.yaml`, remove the `flutter_driver:` entry from `dev_dependencies`. It was only used by `test_harness.dart` and `driver_main.dart`, both now deleted.

#### Step 7.3.2: Add harness endpoint to driver_server.dart

Read `lib/core/driver/driver_server.dart`. Add imports for:
```dart
import 'package:construction_inspector/core/driver/test_db_factory.dart';
import 'package:construction_inspector/core/driver/harness_seed_data.dart';
import 'package:construction_inspector/core/driver/screen_registry.dart';
```

Add a `/driver/harness` endpoint handler that:
1. Creates an in-memory DB via `TestDbFactory.createInMemory()`
2. Seeds data via `HarnessSeedData.seedBaseData(db)`
3. Returns success response

Read `lib/core/driver/screen_registry.dart` and `lib/core/driver/harness_seed_data.dart` to understand the APIs before adding the endpoint.

#### Step 7.3.3: Verify compilation

Run `pwsh -Command "flutter analyze"` on the full project.

---

### Sub-phase 7.4: Remove stale sync_providers docstring

**Files:**
- Modify: `lib/features/sync/di/sync_providers.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 7.4.1: Remove stale comment

If the "Phase 8: Pure code-motion refactor" docstring comment still exists at approximately line 31, remove it. (May have already been removed in Phase 5.)

---

## Phase 8: Full Test Suite Verification

Run the complete test suite and fix any failures.

---

### Sub-phase 8.1: Run flutter analyze + flutter test

**Files:** None (verification only)

**Agent:** `frontend-flutter-specialist-agent`

#### Step 8.1.1: Run analyze

Run `pwsh -Command "flutter analyze"`. Report all errors. Warnings are acceptable.

#### Step 8.1.2: Run tests

Run `pwsh -Command "flutter test"`. Report pass/fail count and any failures.

#### Step 8.1.3: Fix failures

If any tests fail, read the failing test files AND the production files they test. Fix the root cause. Re-run the specific failing tests to confirm.

Do NOT modify the 32 surviving new files unless a test reveals a genuine bug introduced by the tracked-file rewiring (not a pre-existing issue). If modification is needed, document why.

#### Step 8.1.4: Re-run full suite

After fixes, re-run `pwsh -Command "flutter test"` to confirm all green.
