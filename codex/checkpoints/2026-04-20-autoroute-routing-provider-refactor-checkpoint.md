# AutoRoute Routing + Provider Refactor Checkpoint

Date: 2026-04-20
Status: active checkpoint

## Purpose

Append concise implementation notes here while executing
`.codex/plans/2026-04-20-autoroute-routing-provider-refactor-todo-spec.md`.

This checkpoint replaces scattered routing/red-screen notes for the current
AutoRoute and provider-snapshot refactor lane. Keep entries factual: what
changed, what was verified, what failed, and which checklist item remains open.

## 2026-04-20 Kickoff

- Created the consolidated implementation lane for:
  - AutoRoute migration target;
  - app-owned navigation boundary;
  - route-access snapshot and provider refactor;
  - routing/design-system lint guardrails;
  - device proof with backend pressure.
- The provider refactor is in scope only where provider volatility affects
  route decisions, guard reevaluation, shell rebuilds, or route-triggered UI
  failures.
- Unrelated codebase hygiene work remains out of scope for this lane.
- Initial implementation order:
  1. make the spec and research decision durable;
  2. add route/provider boundary scaffolding;
  3. add lints to prevent new direct router coupling;
  4. add AutoRoute dependencies and vertical-slice scaffolding;
  5. migrate route callsites and guards in focused batches;
  6. run live physical-device proof.

## 2026-04-20 First Implementation Slice

- Baseline counts from `lib/`:
  - 74 files imported `package:go_router/go_router.dart`.
  - 97 direct `context.go*` / `context.push*` / `context.replace*` calls.
  - 10 direct `refreshUserProfile()` callsites.
  - 6 direct `context.watch<AuthProvider>().can...` permission reads.
- Added `auto_route` plus generator/build dependencies. The generator must stay
  on `auto_route_generator ^10.4.0` while the patched custom-lint stack depends
  on analyzer 8.x; `^10.5.0` requires analyzer 9+ and does not solve.
- Added router-neutral navigation scaffolding:
  - `AppRouteId`;
  - `AppRouteIntent`;
  - `AppNavigator`;
  - temporary `GoRouterAppNavigator`;
  - `AutoRouteAppNavigator` path adapter for the vertical-slice lane.
- Added stable route-access scaffolding:
  - `RouteAccessSnapshot`;
  - `RouteAccessController`;
  - `RouterRefreshNotifier` now wraps the route-access controller.
- Important behavior change: `isLoadingProfile` is no longer part of the
  router refresh snapshot, so profile refresh start/finish churn no longer
  forces route reevaluation when stable access facts did not change.
- Added `RolePolicy` as a `ChangeNotifierProxyProvider` fed from
  `AuthProvider`. Widget migration to `RolePolicy` is still open.
- Added lint guardrails:
  - `no_auto_route_import_outside_navigation_layer`;
  - `no_volatile_route_access_snapshot_fields`.
- Migrated `ScaffoldWithNavBar` off direct GoRouter calls and onto
  `AppRouteIntent` through `GoRouterAppNavigator`.
- Verification:
  - `flutter pub get`: passed with `auto_route_generator ^10.4.0`.
  - `flutter analyze` on touched navigation/router/auth-provider files: passed.
  - New route snapshot/navigation tests: passed.
  - New lint rule tests: passed.
  - `dart run custom_lint`: passed.

## 2026-04-20 Navigation/Guard Migration Batch

- Added `AppNavigationBuildContextX` so feature widgets can route through
  app-owned `AppRouteId`/`AppRouteIntent` calls without importing router
  packages directly.
- Migrated these surfaces off direct GoRouter context calls:
  - `ScaffoldWithNavBar`;
  - `ShellBanners`;
  - Settings sync/data, account, and about sections;
  - sync status icon;
  - deletion notification banner;
  - sync dashboard action tiles.
- Direct production GoRouter import count dropped from 74 to 67.
- Direct production context navigation call count dropped from 97 to 76.
- Updated `RouteAccessSnapshot` with `hasProfile` and
  `isProfileBootstrapPending`.
- Added `AuthProvider.isProfileBootstrapPending` so the router can distinguish
  first auth/profile bootstrap from ordinary profile refresh churn.
- `AppRedirect` now reads route decisions from `RouteAccessSnapshot` instead
  of directly reading broad `AuthProvider` state for guards.
- Regular `isLoadingProfile` is no longer a router refresh field. A profile
  refresh with an existing profile should not force route reevaluation unless a
  stable access fact changes.
- Verification:
  - `flutter analyze` on touched routing/navigation/sync/settings files:
    passed.
  - `flutter test test/core/router/app_redirect_test.dart
    test/core/router/router_refresh_notifier_test.dart
    test/core/router/route_access_snapshot_test.dart`: passed.
  - `flutter test test/core/router/app_router_test.dart`: passed.
  - `dart run custom_lint`: passed.

## 2026-04-20 Auth Navigation Migration Batch

- Migrated auth/onboarding presentation screens off direct `go_router` imports
  and direct `context.goNamed` / `context.pushNamed` calls:
  - login;
  - register;
  - forgot password;
  - OTP verification;
  - update password;
  - profile setup;
  - company setup;
  - pending approval;
  - account status.
- `pendingApproval` navigation now passes `requestId` and `companyName`
  through query parameters, with the existing `extra` payload still accepted as
  a compatibility fallback in `auth_routes.dart`.
- `accountStatus` rejected-state navigation now uses the existing `reason`
  query parameter instead of `extra`.
- Direct production GoRouter import count dropped from 67 to 58.
- Direct production context navigation call count dropped from 76 to 66.
- Verification:
  - `flutter analyze lib/features/auth/presentation/screens
    lib/core/router/routes/auth_routes.dart lib/core/navigation
    lib/core/router/route_access_snapshot.dart
    lib/core/router/route_access_controller.dart`: passed.
  - `dart run custom_lint`: passed.
  - `flutter test test/core/router/app_router_test.dart
    test/core/router/app_redirect_test.dart
    test/core/router/router_refresh_notifier_test.dart
    test/core/router/route_access_snapshot_test.dart
    test/core/navigation/app_route_id_test.dart`: passed.

## 2026-04-20 Dashboard/Toolbox Navigation Migration Batch

- Migrated dashboard presentation screens/widgets off direct GoRouter imports
  and context navigation calls:
  - project dashboard body;
  - tracked items section;
  - drafts pill;
  - dashboard sliver app bar;
  - dashboard quick stats row;
  - dashboard empty state;
  - approaching limit section.
- Migrated toolbox home navigation cards off direct GoRouter calls.
- Added `AppNavigator.canPop` and `BuildContext.appCanPop()` so shared
  back/fallback behavior can route through the app navigation boundary.
- Migrated `safeGoBack()` from `go_router` to `AppRouteId` +
  `AppNavigationBuildContextX`, keeping the existing string route-name API as a
  compatibility layer while failing loudly for unknown fallback routes.
- Direct production GoRouter import count dropped from 58 to 49.
- Direct production context navigation call count dropped from 66 to 49.
- Verification:
  - `flutter analyze lib/features/dashboard/presentation
    lib/features/toolbox/presentation/screens/toolbox_home_screen.dart
    lib/shared/utils/navigation_utils.dart lib/core/navigation`: passed.
  - `dart run custom_lint`: passed.
  - `flutter test test/core/navigation/app_route_id_test.dart`: passed.

## 2026-04-20 Settings Navigation Migration Batch

- Migrated remaining settings presentation direct router usage:
  - settings screen trash navigation;
  - consent accept redirect;
  - consent Terms/Privacy legal-document links;
  - edit-profile pop.
- Settings presentation now routes through `AppRouteId` and
  `AppNavigationBuildContextX` instead of importing `go_router`.
- Direct production GoRouter import count dropped from 49 to 46.
- Direct production context navigation call count dropped from 49 to 45.
- Verification:
  - `flutter analyze lib/features/settings/presentation/screens
    lib/features/settings/presentation/widgets lib/core/navigation`: passed.
  - `dart run custom_lint`: passed.

## 2026-04-20 Projects Navigation Migration Batch

- Migrated projects presentation direct router usage:
  - project list select/new-project navigation;
  - project switcher view-all/new-project actions;
  - project card edit action;
  - contractors tab personnel-types action;
  - project setup save/back navigation.
- Added app-navigation `canPop`/`pop` usage to project setup controllers so
  wizard fallback routing no longer imports `go_router`.
- Corrected `AppRouteId.personnelTypes` from `:contractorId` to `:projectId`
  to match the actual route declaration.
- Direct production GoRouter import count dropped from 46 to 40.
- Direct production context navigation call count dropped from 45 to 36.
- Verification:
  - `flutter analyze lib/features/projects/presentation
    lib/core/navigation/app_route_id.dart lib/shared/utils/navigation_utils.dart`:
    passed.
  - `flutter test test/core/navigation/app_route_id_test.dart`: passed.
  - `dart run custom_lint`: passed.

## 2026-04-20 Entries Navigation Migration Batch

- Migrated `EntryFlowRouteIntents` from GoRouter calls to `AppRouteId` and
  `AppNavigationBuildContextX`.
- Migrated remaining entries presentation direct router usage:
  - home project header;
  - no-projects/no-selection CTA;
  - attached form open action;
  - quantity calculator open action.
- Corrected app route templates to match the actual route table:
  - `entry` now uses `/entry/:projectId/:date`;
  - `quantityCalculator` now uses `/quantity-calculator/:entryId`;
  - import preview routes now use `:projectId`;
  - `formNew` now uses `/form/new/:formId`;
  - `formFill` now uses `/form/:responseId`.
- Direct production GoRouter import count dropped from 40 to 35.
- Direct production context navigation call count dropped from 36 to 24.
- Verification:
  - `flutter analyze lib/features/entries/presentation
    lib/core/navigation/app_route_id.dart`: passed.
  - `flutter test test/core/navigation/app_route_id_test.dart`: passed.
  - `dart run custom_lint`: passed.

## 2026-04-20 Forms Navigation Migration Batch

- Migrated forms presentation direct router usage:
  - weekly SESC route intents;
  - form-new dispatcher redirects;
  - form gallery create/open saved-form actions;
  - saved response tile;
  - form viewer quick-action navigation;
  - MDOT 1126 dirty-pop fallback;
  - MDOT 1126 and MDOT 1174R attach-step pop handling.
- Form quick actions now resolve named routes through `AppRouteId` and fail
  loudly when a registered quick action references an unknown route name.
- Direct production GoRouter import count dropped from 35 to 27.
- Direct production context navigation call count dropped from 24 to 14.
- Verification:
  - `flutter analyze lib/features/forms/presentation
    lib/core/navigation/app_route_id.dart`: passed.
  - `flutter test test/core/navigation/app_route_id_test.dart`: passed.
  - `dart run custom_lint`: passed.

## 2026-04-20 Quantities/Pay-App/PDF Navigation Migration Batch

- Migrated remaining quantities, pay-application, and PDF presentation/helper
  direct router usage:
  - quantities analytics and no-project CTA;
  - pay-app export open-detail actions;
  - pay-app detail contractor comparison action;
  - export-artifact history pay-app detail link;
  - extraction banner import-preview links;
  - PDF and M&P import preview navigation.
- Corrected app route templates to match the actual route table:
  - `contractorComparison` now uses `/pay-app/:payAppId/compare`;
  - `projectAnalytics` now uses `/analytics/:projectId`.
- Replaced clustered pay-app imports in `quantities_pay_app_export_flow.dart`
  with the existing pay-app feature barrel to keep the import-count lint green
  after adding route-intent imports.
- Direct production GoRouter import count dropped from 27 to 20.
- Direct production context navigation call count dropped from 14 to 3. The
  remaining three calls are in the temporary `GoRouterAppNavigator` adapter.
- Verification:
  - `flutter analyze lib/features/quantities lib/features/pay_applications
    lib/features/pdf/presentation lib/core/navigation/app_route_id.dart`:
    passed.
  - `dart run custom_lint`: passed.
  - `flutter test test/core/navigation/app_route_id_test.dart`: passed.

## 2026-04-20 Router Import Guardrail Batch

- Removed unused `SharedAxisTransitionPage`, which was the remaining
  design-system wrapper importing `go_router`.
- Added `no_go_router_import_outside_approved_owners`.
  - Allows current temporary owners only:
    `GoRouterAppNavigator`, `lib/core/router/**`, and `lib/core/driver/**`.
  - Fails feature, shared, and design-system code that imports `go_router`
    directly.
- Feature presentation code has no remaining direct `go_router` imports.
- Design-system code has no remaining direct `go_router` imports.
- Direct production GoRouter import count dropped from 20 to 19.
- Direct production context navigation call count remains 3; all are in
  `GoRouterAppNavigator`.
- Verification:
  - `dart test
    fg_lint_packages/field_guide_lints/test/architecture/no_go_router_import_outside_approved_owners_test.dart
    fg_lint_packages/field_guide_lints/test/architecture/no_auto_route_import_outside_navigation_layer_test.dart`:
    passed.
  - `flutter analyze lib/core/design_system lib/core/navigation
    fg_lint_packages/field_guide_lints/lib/architecture`: passed.
  - `dart run custom_lint`: passed.

## 2026-04-20 Feature Route Catalog Batch

- Added route-neutral feature route catalogs for:
  - auth;
  - dashboard;
  - projects;
  - entries;
  - quantities;
  - forms;
  - PDF import;
  - pay applications;
  - settings;
  - toolbox;
  - sync.
- Added `AppRouteDescriptor`, `FeatureRouteCatalog`,
  `AppRouteAccessPolicy`, and `AppRouteShellPlacement` as the feature-owned
  metadata layer that does not import `go_router` or `auto_route`.
- Added `appFeatureRouteCatalogs`, `appRouteDescriptors`, and
  `appRouteDescriptorById` as the app-level aggregation point for the later
  generated-route assembly.
- Added route-catalog tests that require every `AppRouteId` to be described
  exactly once and require declared path params to match each route template.
- Verification:
  - `flutter analyze lib/core/navigation ... test/core/navigation/app_route_catalog_test.dart`:
    passed.
  - `flutter test test/core/navigation/app_route_id_test.dart
    test/core/navigation/app_route_catalog_test.dart`: passed.

## 2026-04-20 Profile Refresh Scheduler Batch

- Added `ProfileRefreshScheduler`, a production seam that coalesces concurrent
  profile refresh requests and labels each request with a reason.
- Registered the scheduler in auth DI as a provider backed by `AuthProvider`.
- Moved screen/sync profile refresh callsites behind the scheduler:
  - pending approval polling;
  - company setup preflight and already-in-company recovery;
  - project list open refresh;
  - project delete TOCTOU role refresh;
  - sync initializer post-company-member pull refresh.
- `refreshUserProfile()` direct callsites now remain only inside
  `AuthProvider` internals and the scheduler implementation.
- Verification:
  - `flutter analyze` on the scheduler, touched auth/project/sync files, and
    scheduler test: passed.
  - `flutter test
    test/features/auth/presentation/providers/profile_refresh_scheduler_test.dart`:
    passed.
  - `dart run custom_lint`: passed.

## 2026-04-20 Role Policy Selector Batch

- Expanded `RolePolicySnapshot` with stable role predicates:
  `isEngineer`, `isOfficeTechnician`, and `isInspector`.
- Migrated permission-only UI branches from broad `AuthProvider` watches to
  `RolePolicy` selectors in project list/tab content, project setup tabs,
  quantities, todos, draft review, entry review comment visibility, pay-app
  detail actions, and settings account tiles.
- Narrowed settings account/form profile reads to auth selectors so role
  changes and identity/profile updates do not force unrelated route-shell
  decisions through the same broad listener.
- Remaining broad `AuthProvider` consumers are intentionally identity/session
  surfaces: auth forms, edit profile email, trash scope loading, and selected
  entry review user-id comparison.
- Verification:
  - `flutter analyze` on the touched RolePolicy and feature/widget files:
    passed.

## 2026-04-20 Attribution Cache And Project Permission Batch

- Added `AttributionCache` as the named cache service for user display-name
  attribution.
  - Caches profile and raw display-name entries.
  - Coalesces duplicate in-flight lookups for the same user id.
  - Provides batch lookup de-duplication for future attribution-heavy screens.
- `UserAttributionUseCase` now owns the cache seam and delegates remote lookup
  through `UserAttributionRepository`.
- `AuthInitializer` constructs the cache explicitly and injects it into the use
  case.
- Removed the `ProjectProvider` permission callback closure over
  `AuthProvider`.
  - `ProjectProvider` now stores current `canManageProjects` state.
  - `ProjectProviderAuthController` updates that state from auth changes along
    with user id and role.
- Verification:
  - `flutter test test/features/auth/data/services/attribution_cache_test.dart`:
    passed.
  - `flutter analyze` on attribution cache/use case/auth initializer and
    project provider auth wiring: passed.

## 2026-04-20 AutoRoute Vertical Slice Batch

- Added switchable router-host seam:
  - `AppRouterHost` is now the root app routing interface.
  - Existing `AppRouter` implements the host and remains the default GoRouter
    backend.
  - `AppBootstrap` can opt into the AutoRoute slice with
    `--dart-define=FG_USE_AUTOROUTE_VERTICAL_SLICE=true`.
- Added AutoRoute generated slice under `lib/core/router/autoroute/`.
  - Generated convention: keep `*.gr.dart` beside the router under
    `lib/core/router/autoroute/`; do not hand-edit generated output.
  - Routes covered: login, primary shell, dashboard/calendar/projects/settings
    tabs, project setup new/edit, and report/editor.
  - Primary shell uses `AutoTabsRouter`.
  - Guard reevaluation uses `RouteAccessController`/`RouteAccessSnapshot`, not
    `AuthProvider` directly.
  - Added route/guard/tab logging via `Logger.nav`.
- `ScaffoldWithNavBar` now accepts an optional tab-selection callback so the
  same shell chrome can be used by GoRouter and AutoRoute without feature code
  importing router packages.
- Verification:
  - `dart run build_runner build --delete-conflicting-outputs`: passed.
  - `flutter analyze` on AutoRoute slice, app router host, app widget, app
    bootstrap, and touched tests: passed.
  - `flutter test test/core/router/autoroute/app_auto_router_test.dart`: passed.
  - `flutter test test/core/di/app_bootstrap_test.dart`: passed.
  - `flutter test test/core/app_widget_test.dart`: passed.
  - `dart run custom_lint`: passed.

## 2026-04-20 Verification Batch

- Full static analysis:
  - `flutter analyze`: passed.
  - `dart run custom_lint`: passed.
- Focused router/provider/widget regression suite:
  - `flutter test test/core/navigation test/core/router
    test/core/app_widget_test.dart test/core/di/app_bootstrap_test.dart
    test/features/auth/data/services/attribution_cache_test.dart
    test/features/auth/presentation/providers/profile_refresh_scheduler_test.dart
    test/features/projects/presentation/providers/project_provider_test.dart
    test/features/projects/presentation/screens/project_save_navigation_test.dart`:
    passed.
- Custom lint rule unit tests:
  - `dart test` for GoRouter import, AutoRoute import, and volatile
    RouteAccessSnapshot lint tests: passed.

## 2026-04-20 Driver AutoRoute Slice Wiring Batch

- Added explicit debug/driver switch:
  - `tools/start-driver.ps1 -UseAutoRouteVerticalSlice`
  - `tools/build.ps1 -UseAutoRouteVerticalSlice`
- The switch appends
  `--dart-define=FG_USE_AUTOROUTE_VERTICAL_SLICE=true`.
- Guarded the switch to debug builds only so normal release builds do not pick
  up the experimental routing backend by accident.
- Fixed Android driver install freshness:
  - device state now records `dartDefinesHash`;
  - reinstall checks compare `dartDefinesHash` with the current driver build
    manifest;
  - this prevents stale APK reuse when only compile-time routing flags change.
- Verification:
  - PowerShell parser check for `tools/build.ps1`: passed.
  - PowerShell parser check for `tools/start-driver.ps1`: passed.
- Next:
  - start S21/tablet/two-emulator drivers with
    `-UseAutoRouteVerticalSlice`;
  - run the four-lane enterprise smoke with backend/device markers and real
    auth;
  - inspect device logs/screenshots first if any red or black screen appears.

## 2026-04-20 Sync Hydration And Driver Startup Recovery

- Fixed a real sync hydration gap found on the tablet inspector lane:
  - symptom: device session could see three remote projects/assignments, but
    local `projects` and `project_assignments` stayed empty and the previous
    sentinel passed because zero local projects equaled zero provider projects;
  - root cause: stale root pull cursors could survive a fresh/empty local root
    scope, so `projects` and `project_assignments` pulled zero rows;
  - fix: `PullScopeState.initialize()` now clears stale `projects` and
    `project_assignments` cursors when local projects, assignments, and
    materialized scope are all empty.
- Tightened the sync dashboard project visibility sentinel:
  - it now reads the remote `projects` snapshot through the device session;
  - if remote-visible projects exist but local/provider project counts are
    zero, the run fails loudly instead of passing the zero-zero state.
- Evidence:
  - `build\soak\tablet-local-hydration-proof-20260420-064651`
  - tablet inspector remote/local/provider project counts all matched at 3.
- Verification:
  - `flutter test test\features\sync\engine\pull_scope_state_test.dart`:
    passed.
  - `dart analyze lib\features\sync\engine\pull_scope_state.dart
    test\features\sync\engine\pull_scope_state_test.dart`: passed.
  - `.\tools\test-sync-soak-harness.ps1`: passed.
- Driver startup problem found while trying to scale back to four lanes:
  - S21 updated cleanly.
  - `emulator-5554` did not become a valid lane after reinstall.
  - First blocker was the Android notification permission dialog.
  - After manual permission recovery, the app process ANRed during startup
    (`ANR in com.fieldguideapp.inspector`, reason `failed to complete startup`)
    under very high emulator CPU pressure.
  - This invalidates the attempted four-lane proof; do not count it.
- Harness fix applied:
  - `tools/start-driver.ps1` now attempts to grant
    `android.permission.POST_NOTIFICATIONS` before launch.
  - On driver wait timeout it classifies the startup failure as
    `notification_permission_dialog`, `app_start_anr`,
    `app_process_start_timeout`, `app_not_running_launcher_visible`,
    `flutter_runtime_error_visible_or_logged`, or
    `driver_endpoint_unreachable_process_running`.
  - Parser check for `tools/start-driver.ps1`: passed.
- Next:
  - do not run soak flows against `emulator-5554` until the driver startup gate
    reports a healthy app/driver;
  - recover or restart the emulator lane, then rerun the four-lane proof.

## 2026-04-20 Device Harness Guardrail Correction

- Current user-visible state:
  - the prior multi-device script attempt was invalid and must not count as
    sync hardening evidence;
  - automation was still capable of starting downstream jobs even when an
    emulator was on launcher, killed, or ANR-blocked.
- Fix applied:
  - `tools/start-driver.ps1` now distinguishes launcher/backgrounded app
    startup failures:
    `app_not_running_launcher_visible`,
    `app_process_running_but_launcher_visible`, and
    `app_process_running_not_foreground`;
  - `tools/sync-soak/AndroidSurface.ps1` now treats launcher / non-Field-Guide
    UIAutomator surfaces as `android_app_not_foreground`;
  - `Invoke-SoakAndroidSurfacePreflight` now records foreground window and app
    process state, and fails before a flow if Field Guide is not foreground or
    the app process is not running;
  - `tools/sync-soak/DriverClient.ps1` now guards driver gestures
    (`navigate`, `tap`, `tap-text`, `text`, `scroll`, `scroll-to-key`) and
    refuses to interact if Android focus is not `com.fieldguideapp.inspector`;
  - failure classification now has a named `app_not_foreground` bucket.
- Verification:
  - PowerShell parser check on touched soak/start-driver files: passed.
  - `.\tools\test-sync-soak-harness.ps1`: passed.
- Follow-up correction after retry:
  - fixed a PowerShell bug where `$pid` collided with the read-only `$PID`
    automatic variable in startup/foreground guard code;
  - Android startup readiness now uses a fast-fail loop instead of waiting the
    full timeout while the device sits on launcher;
  - `emulator-5554` now fails startup in about 10 seconds with
    `app_process_running_but_launcher_visible` instead of waiting 180 seconds;
  - passive logs still show the underlying emulator lane problem: the Field
    Guide process later ANRs with `failed to complete startup` and is killed.
- Next:
  - run diagnostics/recovery on `emulator-5554` only;
  - do not run four-lane backend/device marker proof until every lane passes
    the hardened ready/preflight gate.

## 2026-04-20 Overnight Run Status And Router Decision

- AutoRoute status:
  - AutoRoute was **not proven as failed** overnight.
  - AutoRoute was also **not proven ready for full cutover**.
  - Current decision remains: keep AutoRoute as the target migration lane, but
    do not delete the GoRouter backend or fully migrate every route until the
    vertical slice passes physical-device and emulator proof.
  - The implemented slice is real and switchable through
    `FG_USE_AUTOROUTE_VERTICAL_SLICE=true` / `tools/start-driver.ps1
    -UseAutoRouteVerticalSlice`.
  - The slice has passed static/unit/custom-lint gates, but not the required
    S21/S10/two-emulator red-screen/black-screen proof.
- Why the overnight proof did not answer the router question:
  - the device-lab run was blocked by harness and device readiness failures,
    not by a clean AutoRoute-vs-GoRouter comparison;
  - `emulator-5554` stayed on launcher, then the Field Guide process ANRed
    during startup (`failed to complete startup`);
  - that invalidates the attempted four-lane run as routing acceptance
    evidence.
- Background agent results:
  - Agent `019da9f9-5c8f-72e1-92aa-dbb4b9150586` reported the
    PowerShell driver error wrapper was masking real driver/network failures
    with `The property 'Message' cannot be found on this object`; current
    `DriverClient.ps1` now uses guarded `ErrorDetails` extraction.
  - The same agent also flagged a separate real S21
    `projectVisibilitySentinel` mismatch: provider project sample was narrower
    than local active projects. Treat this as a sync/provider visibility lane,
    not a router proof.
  - Agent `019daa19-beb0-7f43-b20c-c350b79d3033` reported enterprise soak
    gaps that still need implementation before the baseline is trustworthy:
    Flutter `--dart-define` args can be passed after the test path,
    backend/RLS direct pressure still lacks exposed action-weight controls,
    backend-device markers default into a row likely used by device UI writes,
    and device UI mutation target selection still needs explicit baseline
    partitioning versus a named same-row collision lane.
- Current router cutover rule:
  - continue implementing the app-owned navigation boundary and AutoRoute
    slice;
  - block full migration/removal of GoRouter until:
    S21, S10/tablet, and both emulators start with the AutoRoute slice,
    fail-fast harness gates pass, no red/black/global-key/dirty-build errors
    appear, and backend-device marker proof completes with real auth.

## 2026-04-20 AutoRoute-First Redirect And Navigation Boundary Cutover

- User correction accepted:
  - pause harness-lane iteration for now;
  - follow the AutoRoute/refactor spec order;
  - fully implement the app-owned AutoRoute route surface and navigation
    boundary before returning to four-device harness pressure.
- Audit finding:
  - feature widgets had already moved to `context.appGo` / `context.appPush`;
  - the extension was still hard-wired to `GoRouterAppNavigator`, so the
    app-owned navigation boundary was not actually selecting the active router
    backend.
- Implementation:
  - added `AppNavigatorScope`;
  - `ConstructionInspectorApp` now installs a router-backed navigator selected
    from `AppRouterHost.routerBackend`;
  - `app_navigation_extensions.dart` now consumes the scoped app navigator and
    keeps the GoRouter adapter only as a temporary compatibility fallback for
    older tests/widgets that are not mounted under the app root;
  - `AutoRouteAppNavigator` now maps every `AppRouteId` to generated
    `PageRouteInfo` classes instead of relying on path-only navigation;
  - extra-bearing flows now have typed AutoRoute mappings:
    draft review, review summary, PDF import preview, and M&P import preview;
  - AutoRoute PDF/M&P import preview pages now render the real preview screens
    and convert the same `BidItemJobResult`, `PdfImportResult`,
    `MpJobResult`, and `MpExtractionResult` payloads handled by the GoRouter
    compatibility routes;
  - stale feature comments that described route actions as GoRouter-specific
    were updated to app-navigation wording.
- Current route-cutover status:
  - AutoRoute definitions now cover the active app route families in the spec:
    auth/onboarding, tabs, projects, entries/reports, forms, pay apps,
    sync/conflicts/trash/exports, settings/admin/help/legal/profile, toolbox,
    gallery, todos, analytics, quantities, and calculator;
  - production feature/design-system search shows no direct `go_router` or
    `auto_route` package imports;
  - GoRouter remains as the compatibility backend and must not be removed until
    the spec's route-contract parity, lints, and live-device proof gates are
    completed.
- Verification:
  - `dart run build_runner build --delete-conflicting-outputs`: passed;
  - targeted `flutter analyze` on app widget, navigation adapters/scope,
    AutoRoute router/pages/generated output, quick-action registry, and the new
    navigation test: passed;
  - `flutter test test/core/navigation/app_navigation_extensions_test.dart
    test/core/router/autoroute/app_auto_router_test.dart
    test/core/driver/driver_route_contract_test.dart`: passed.
- Still open before harness resumes:
  - move route ownership toward feature route modules/catalog contributors;
  - add/enforce lints for router package imports and raw route-level
    navigation ownership;
  - finish route-access/provider churn cleanup that is still listed in the
    spec;
  - only then return to S21/tablet/two-emulator route smoke and four-device
    proof.

## 2026-04-20 Route Catalog Validation Slice

- Audit finding:
  - feature-owned `FeatureRouteCatalog` files already exist for auth,
    dashboard, projects, entries, forms, PDF import, pay applications,
    quantities, settings, sync, and toolbox;
  - the catalogs described route ids, access policies, declared path/query
    params, extra-payload allowance, and shell/tab placement, but navigation
    adapters were not validating route intents against that catalog.
- Implementation:
  - added `validateAppRouteIntent`;
  - GoRouter and AutoRoute app navigators now validate every
    `AppRouteIntent` against the owning feature descriptor before dispatch;
  - unexpected path/query params and unexpected extras now fail before the
    router package sees the navigation request;
  - AutoRoute pending approval and account status route mappings now honor the
    same query-or-extra map payload shape as the GoRouter compatibility routes;
  - AutoRoute route-surface tests now assert the generated route table contains
    every catalog path template, not just the hardcoded migration sample.
- Lint/enforcement evidence:
  - existing router-package import lints are active:
    `no_go_router_import_outside_approved_owners` and
    `no_auto_route_import_outside_navigation_layer`;
  - lint unit tests for those two rules plus `no_raw_navigator` pass.
- Verification:
  - targeted `flutter analyze` on route intent validation, GoRouter/AutoRoute
    app navigators, consent sentinel spacing cleanup, and route tests: passed;
  - `flutter test test/core/navigation/app_route_catalog_test.dart
    test/core/navigation/app_navigation_extensions_test.dart
    test/core/router/autoroute/app_auto_router_test.dart
    test/core/driver/driver_route_contract_test.dart`: passed;
  - `dart test` for the router import lint tests and `no_raw_navigator`: passed;
  - scoped `dart run custom_lint --no-fatal-infos --no-fatal-warnings ...`:
    exit code 0, with only existing `max_import_count` warnings for
    `screen_registry.dart` and `app_auto_router_pages.dart`.
- Still open:
  - route page factories still live in central router/page assembly rather than
  the feature catalogs;
  - the AutoRoute page file now has a known import-count warning because it
  centralizes the expanded generated route surface. Split route pages by
  feature before treating Phase 5 as fully done.

## 2026-04-20 AutoRoute Page Wrapper Split

- Spec-order focus:
  - continued Phase 4/5 AutoRoute route ownership work;
  - kept harness/device proof paused per user direction.
- Implementation:
  - split the monolithic `app_auto_router_pages.dart` route wrapper file into
    focused route-family files under `lib/core/router/autoroute/pages/`;
  - kept `app_auto_router_pages.dart` as a small export barrel so
    `AppAutoRouter` and the generated part still see the same route page
    classes;
  - moved auth, dashboard/calendar, projects, entries, quantities, PDF import,
    forms, pay applications, analytics, sync, settings, toolbox, calculator,
    gallery, and todos wrappers out of the central file;
  - kept primary shell and missing-route wrappers in the approved core
    AutoRoute composition layer;
  - preserved every generated route class name and path contract.
- Boundary decision:
  - an initial feature-folder split correctly reduced the central imports but
    violated `no_auto_route_import_outside_navigation_layer`;
  - corrected approach keeps package-specific AutoRoute annotations in
    `core/router/autoroute/**`;
  - feature ownership remains route-neutral through the feature route catalogs,
    while AutoRoute wrappers are grouped by feature route family in the app
    router composition seam.
- Verification:
  - `dart run build_runner build --delete-conflicting-outputs`: passed;
  - generated output remains only at
    `lib/core/router/autoroute/app_auto_router.gr.dart`;
  - targeted `flutter analyze` on AutoRoute router, barrel, split wrapper
    files, generated output, and router test: passed;
  - `flutter test test/core/navigation/app_route_catalog_test.dart
    test/core/navigation/app_navigation_extensions_test.dart
    test/core/router/autoroute/app_auto_router_test.dart
    test/core/driver/driver_route_contract_test.dart`: passed;
  - `dart test` for GoRouter import, AutoRoute import, and raw Navigator lint
    unit tests: passed;
  - scoped `dart run custom_lint --no-fatal-infos --no-fatal-warnings ...`:
    exit code 0, with only the pre-existing `screen_registry.dart`
    `max_import_count` warning.
- Still open:
  - replace legacy `core/router/routes/*` GoRouter declarations with the
    app-owned route catalog/adapter model before removing GoRouter;
  - add feature-local route tests around the route catalogs and page-wrapper
    expectations;
  - continue Phase 6/7 design-system/raw-navigation lint enforcement before
    returning to device proof.

## 2026-04-20 Legacy GoRouter Metadata Alignment

- Spec-order focus:
  - continued the open Phase 4 item to replace `core/router/routes/*` with
    route-catalog/generator-owned declarations;
  - did not remove GoRouter yet because it remains the compatibility backend.
- Implementation:
  - updated every legacy GoRouter route module under `lib/core/router/routes/`
    to use `AppRouteId.pathTemplate` and `AppRouteId.routeName` instead of
    local string literals;
  - updated primary tab GoRoutes in `AppRouter` to use the same `AppRouteId`
    metadata;
  - updated route restoration defaults and non-restorable root route sets to
    read from `AppRouteId` where those are exact app routes;
  - updated redirect targets in compatibility route modules to use
    `AppRouteId` paths instead of duplicated route strings.
- Boundary status:
  - this is a partial replacement only: `core/router/routes/*` still owns
    GoRouter page builders and temporary data guards;
  - the durable route name/path source is now `AppRouteId` and the feature
    route catalogs, which reduces drift while the GoRouter backend remains.
- Verification:
  - targeted `flutter analyze` on `AppRouter`, legacy route modules,
    `AppRouteId`, and router tests: passed;
  - `flutter test test/core/router/app_router_test.dart
    test/core/navigation/app_route_id_test.dart`: passed;
  - full targeted router/navigation suite passed:
    `test/core/navigation/app_route_catalog_test.dart`,
    `test/core/navigation/app_navigation_extensions_test.dart`,
    `test/core/router/autoroute/app_auto_router_test.dart`,
    `test/core/driver/driver_route_contract_test.dart`,
    `test/core/router/app_router_test.dart`, and
    `test/core/navigation/app_route_id_test.dart`;
  - scoped `dart run custom_lint --no-fatal-infos --no-fatal-warnings ...`:
    exit code 0, with only the pre-existing `screen_registry.dart`
    `max_import_count` warning.
- Still open:
  - remove or replace the GoRouter page-builder modules after the AutoRoute
    backend becomes the production backend;
  - move remaining page-builder-only behavior into adapter-specific
    composition or route-neutral helpers without weakening feature/router
    import lints.

## 2026-04-20 AutoRoute Generated Output And Navigation Lint Lock-In

- Spec-order focus:
  - continued Phase 6/7 architecture lock-in before returning to device proof;
  - addressed the generated `app_auto_router.gr.dart` size concern by
    containing generated output instead of hand-editing generator output.
- Implementation:
  - added `no_autoroute_generated_file_outside_router`;
  - the new lint allows only
    `lib/core/router/autoroute/app_auto_router.gr.dart` for AutoRoute
    `*.gr.dart` output;
  - tightened `no_auto_route_import_outside_navigation_layer` so arbitrary
    `.gr.dart` files are no longer implicitly allowed;
  - upgraded `no_raw_navigator` from advisory GoRouter wording to an
    error-level app-navigation rule;
  - `no_raw_navigator` now bans route-level `Navigator.push*` outside approved
    navigation/router owners, while intentionally preserving local
    `Navigator.pop` for dialogs, sheets, and modal result ownership.
- Architecture decision:
  - do not manually split or edit `app_auto_router.gr.dart`; it is generator
    output and will naturally grow with route count;
  - keep generated output isolated to one configured file, and keep
    hand-owned page wrappers split by route family under
    `lib/core/router/autoroute/pages/`.
- Verification:
  - `dart test` for GoRouter import, AutoRoute import, AutoRoute generated
    output, and raw Navigator lint tests: passed;
  - `dart analyze` on the touched lint rules, architecture registry, and tests:
    passed;
  - `flutter analyze` on AutoRoute/navigation plus touched lint files: passed;
  - scoped `dart run custom_lint --no-fatal-infos --no-fatal-warnings
    lib/core/router lib/core/navigation lib/core/design_system lib/shared
    lib/features`: exit code 0, with only the pre-existing
    `screen_registry.dart` `max_import_count` warning;
  - repository scan found only one `*.gr.dart` under `lib/`:
    `lib/core/router/autoroute/app_auto_router.gr.dart`.
- Still open:
  - add route-guard/provider volatility lints for guard dependencies,
    `isLoadingProfile` reevaluation, and screen-mounted profile refresh calls;
  - add feature-local route tests around the feature route catalogs;
  - continue replacing or isolating the temporary GoRouter page-builder
    compatibility modules after AutoRoute is the production backend.

## 2026-04-20 Feature Route Catalog Tests

- Spec-order focus:
  - completed the open Phase 5 feature-local route test item;
  - kept the existing app-level route assembly test as the single global
    catalog parity gate.
- Implementation:
  - added `test/features/navigation/feature_route_catalogs_test.dart`;
  - the test locks each feature catalog's expected `AppRouteId` ownership set;
  - the test verifies each feature catalog has a stable non-empty feature id
    and route list;
  - the test verifies descriptor path parameters match each route template;
  - the test locks the intentionally public route set to auth and legal
    surfaces only.
- Verification:
  - `flutter test test/features/navigation/feature_route_catalogs_test.dart
    test/core/navigation/app_route_catalog_test.dart`: passed;
  - `flutter analyze` on the feature navigation catalogs plus the new test:
    passed.
- Still open:
  - feature catalogs still do not own route-neutral page factories; the
    AutoRoute page wrappers remain in the approved app router composition
    layer;
  - continue route guard/provider volatility lint work before device proof.

## 2026-04-20 Route Guard Volatility Lint

- Spec-order focus:
  - advanced the Phase 7 guard/reevaluation lint items without touching device
    harness work.
- Implementation:
  - added `no_volatile_route_guard_provider_fields`;
  - the lint applies to `AppRedirect`, `AppRouter`, `RouteAccessController`,
    `RouterRefreshNotifier`, and `core/router/autoroute/**`;
  - the lint blocks direct reads of `isLoadingProfile`, sync-progress,
    refresh-in-flight, and direct profile-refresh methods from route guard and
    router-reevaluation owners;
  - existing `no_volatile_route_access_snapshot_fields` remains the snapshot
    guardrail, and the new lint protects the guard/reevaluation layer around
    it.
- Verification:
  - `dart test` for volatile route guard and snapshot lint tests: passed;
  - `dart analyze` on the new lint, architecture registry, and lint test:
    passed;
  - scoped `dart run custom_lint --no-fatal-infos --no-fatal-warnings
    lib/core/router`: exit code 0, with only the pre-existing
    `screen_registry.dart` `max_import_count` warning.
- Still open:
  - screen init/mount profile-refresh lint;
  - replacing compatibility GoRouter page-builder/data guard modules after the
    AutoRoute backend is the production backend.

## 2026-04-20 Screen Lifecycle Profile Refresh Lint

- Spec-order focus:
  - closed the Phase 7 lint item that prevents screen init/mount code from
    calling profile refresh APIs that can churn route-facing auth state.
- Implementation:
  - added `no_direct_profile_refresh_in_screen_lifecycle`;
  - the lint applies to feature presentation screens, widgets, and
    controllers;
  - it blocks direct `refreshUserProfile()` and `refreshUserProfileIfDue()`
    method calls;
  - scheduler-based refresh calls remain allowed so refresh requests stay
    coalesced and reason-labeled.
- Verification:
  - `dart test` for direct profile-refresh lifecycle and volatile route guard
    lint tests: passed;
  - `dart analyze` on the new lint, architecture registry, and lint test:
    passed;
  - scoped `dart run custom_lint --no-fatal-infos --no-fatal-warnings
    lib/features/auth/presentation lib/features/projects/presentation
    lib/features/sync/presentation`: exit code 0, with only the pre-existing
    `screen_registry.dart` `max_import_count` warning.
- Still open:
  - broad compatibility GoRouter data guards still need replacement/isolation;
  - route-neutral page-factory ownership remains deferred until after the
    AutoRoute backend is production-proven.

## 2026-04-20 AutoRoute Production Cutover And Compatibility Module Removal

- Spec-order focus:
  - completed the open pass to replace the remaining GoRouter compatibility
    page-builder/data-guard layer before returning to any device-proof work;
  - resolved the open page-factory ownership question in the same pass.
- Implementation:
  - deleted the production GoRouter compatibility router path:
    `AppRouter`, `AppRedirect`, `RouterRefreshNotifier`,
    `GoRouterAppNavigator`, and `core/router/routes/*`;
  - moved route restoration rules into
    `lib/core/router/app_route_restoration_policy.dart`;
  - added `lib/core/navigation/app_route_matcher.dart` so route templates can
    be matched back to feature-owned route descriptors;
  - `RouteAccessPolicy` now enforces route-specific access centrally from
    `AppRouteAccessPolicy` metadata, covering the project-management,
    project-field-data, admin, and debug-only routes that used to rely on
    compatibility redirects;
  - `AppBootstrap` now constructs `AppAutoRouterHost` directly and restores
    the last restorable route through the AutoRoute host;
  - `AppAutoRouterHost` now owns current-route persistence through
    `PreferencesService`;
  - `ConstructionInspectorApp` always scopes `AutoRouteAppNavigator`;
  - route-neutral page factories are now a resolved architectural decision:
    keep them out of feature route catalogs and in the approved
    `core/router/autoroute/**` composition seam.
- Verification:
  - `flutter test test/core/app_widget_test.dart
    test/core/di/app_bootstrap_test.dart
    test/core/router/app_route_restoration_policy_test.dart
    test/core/router/route_access_policy_test.dart
    test/core/router/route_access_controller_test.dart
    test/core/router/autoroute/app_auto_router_test.dart
    test/core/navigation/app_route_catalog_test.dart
    test/features/navigation/feature_route_catalogs_test.dart`: passed.
  - `dart analyze lib/core/navigation lib/core/router lib/core/di
    lib/features test/core/app_widget_test.dart
    test/core/di/app_bootstrap_test.dart test/core/router
    test/features/navigation`: passed.
  - `dart run custom_lint --no-fatal-infos --no-fatal-warnings
    lib/core/navigation lib/core/router lib/core/di lib/features`:
    exit code 0, with only the pre-existing
    `lib/core/driver/screen_registry.dart` `max_import_count` warning.
- Still open:
  - `go_router` no longer exists in production, but historical driver/test/lint
    references still need a final audit/isolation pass;
  - do not return to device proof until the remaining auth-route
    forward/backward verification and driver parity work is completed.

## 2026-04-20 Post-Cutover Spec Audit And Visible Checklist

- Audit scope:
  - reviewed the active April 20 AutoRoute/provider spec and checkpoint;
  - reviewed the latest routing commits through
    `7532dcc4`, `ca42f998`, `34b9a6bf`, and `04d84cb9`;
  - audited current routing/auth/driver surfaces:
    `AppRouteId`, `AutoRouteAppNavigator`, `AppAutoRouter`,
    `RouteAccessPolicy`, `RouteAccessController`, `DriverRouteContract`,
    `screen_contract_registry.dart`, and `device_state_machine.dart`;
  - ran focused verification:
    `flutter test test/core/navigation/app_route_catalog_test.dart
    test/core/router/autoroute/app_auto_router_test.dart
    test/core/router/route_access_policy_test.dart
    test/core/router/route_access_controller_test.dart
    test/core/driver/registry_alignment_test.dart
    test/core/driver/driver_route_contract_test.dart
    test/core/driver/root_sentinel_auth_widget_test.dart
    test/core/driver/device_state_machine_test.dart`
- Audit conclusions:
  - AutoRoute is now the only production backend; `go_router` is removed from
    `pubspec.yaml`.
  - auth/onboarding routes are present in app route ids, feature route
    catalogs, AutoRoute page wrappers, route access policy, driver screen
    contracts, and registry-alignment coverage.
  - auth runtime state is integrated into route access, device-state
    diagnostics, and host readiness.
  - the remaining work is no longer “finish bringing in auth routes”; it is
    now proof depth, auth-route driver parity, and the last provider/shell
    cleanup items.
  - the root-sentinel auth widget suite is green, but it still does not
    explicitly render the full auth surface; login/register/forgot-password/
    OTP/consent need first-class widget proof instead of relying only on broad
    registry alignment.

Current visible checklist:

- [ ] Add explicit AutoRoute navigator tests for every auth/onboarding route:
  login, register, forgot password, verify OTP, update password, consent,
  profile setup, company setup, pending approval, and account status.
- [ ] Add explicit forward/back behavior tests for auth/onboarding flows,
  including query-driven routes and post-success navigation.
- [ ] Add root-sentinel widget tests for `LoginScreen`, `RegisterScreen`,
  `ForgotPasswordScreen`, `OtpVerificationScreen`, and `ConsentScreen`.
- [ ] Promote Company Setup auth proof from initial-frame-only sentinel
  coverage to a fully mounted provider-backed widget proof.
- [ ] Add explicit driver route-contract resolution tests for the auth/
  onboarding route family.
- [ ] Add auth-route `/driver/current-route` and route-contract diagnostics
  tests for login, consent, profile setup, pending approval, and account
  status.
- [ ] Verify driver-safe redirect/recovery behavior for auth transitions:
  login -> consent, login -> profile setup, pending approval, and account
  status.
- [ ] Remove the remaining
  `ignore_for_file: unused_element{,_parameter}` directives from the split
  `project_provider_*` files.
- [ ] Add proof that non-route-affecting auth/profile refresh churn and
  background sync noise do not trigger route reevaluation.
- [ ] Measure project-list rebuild pressure after the provider split and record
  the baseline/result.
- [ ] Preserve baseline device artifact paths for router-comparison evidence.
- [ ] Finish the remaining navigation ownership lint-test matrix and modal/pop
  ownership audit.
- [ ] Audit the remaining shell-risk items named by the spec:
  animated primary-route transitions, mutable inherited wrappers, and route/
  shell/design-system `GlobalKey` usage.
- [ ] Run the full static/targeted verification slice:
  `flutter analyze`, `dart run custom_lint`, expanded route/auth/driver tests,
  and compact/tablet shell widget tests.
- [ ] After all local proof is green, run S21 route smoke, S10/tablet route
  smoke, two-emulator route smoke, then four-lane live proof with real auth.

### 2026-04-20 Auth Forward/Back Verification In Progress

- [~] The auth/onboarding forward-backward verification lane is now active.
- [~] The new auth screen-level widget-router matrix is intentional and
  complementary: it is a fast ownership/back-stack proof for `appGo` /
  `appPush`, not a replacement for the driver or the testing-skill E2E lane.
- [~] Driver flows and testing-skill E2E remain the acceptance gates; this
  matrix exists to make every auth branch verifiable without waiting on a
  live-device loop for each route permutation.
- [~] First concrete result from this lane: it exposed real auth-shell UI
  regressions in `LoginScreen` and `RegisterScreen` footer actions, both of
  which were overflowing at the constrained auth-shell width and were
  corrected during this pass.

## 2026-04-21 Audit Refresh And Freeze Investigation

- Re-audited the April 20 spec/checkpoint against the live branch instead of
  trusting the stale boxes literally.
- Confirmed the branch is already AutoRoute-only in the live app path:
  `AppAutoRouterHost` is the active host, `go_router` is no longer present in
  repo code or package manifests, and the remaining open work is proof depth
  plus provider hygiene rather than router-package migration.
- Implemented the missing auth/onboarding local-proof code called out by the
  audit:
  - replaced the broken mock-only auth flow harness with a stateful fake auth
    service in
    `test/features/auth/presentation/screens/auth_onboarding_navigation_flow_test.dart`;
  - bounded the consent-scroll helper so the test fails fast instead of
    spinning indefinitely on `dragUntilVisible`;
  - promoted `CompanySetupScreen` root-sentinel proof from initial-frame-only
    to a mounted assertion in `root_sentinel_auth_widget_test.dart`;
  - added explicit AutoRoute auth/onboarding path-to-page assertions in
    `app_auto_router_test.dart`;
  - added explicit driver route-contract and current-route diagnostics coverage
    for login, consent, profile setup, pending approval, and account status.
- Implemented the routing/provider cleanup slice from the audit:
  - `RouteAccessSnapshot` no longer carries `profileState`, so ordinary
    non-bootstrap profile refresh churn does not participate in route
    reevaluation;
  - `route_access_controller_test.dart` now proves that non-bootstrap profile
    refresh churn is ignored;
  - the split `project_provider_*` mixins no longer rely on
    `ignore_for_file: unused_element{,_parameter}` headers; they now bind to
    the concrete `ProjectProvider` library scope directly;
  - `project_provider_test.dart` now includes notification-hygiene coverage so
    unchanged role/permission/init/search writes stay no-op and changed writes
    notify once per real state transition;
  - remaining live code/test/tooling references to `go_router` were removed so
    the branch no longer advertises a split router backend.
- Freeze investigation findings:
  - the new auth-flow suite contained an unbounded consent scroll helper that
    could spin indefinitely when the bottom sentinel never became visible;
  - the local Flutter tool is also unhealthy outside the repo tests:
    `flutter --version` and direct `flutter_tools.snapshot --version` both
    hang and spawn orphaned Flutter SDK `cmd.exe` / `dart.exe` processes;
  - those orphaned Flutter workers contend on the shared SDK lock and are a
    plausible machine-freeze amplifier independent of the test code itself.
- Verification status:
  - code and test slices above are landed in the working tree;
  - full `flutter test` / `flutter analyze` verification is currently blocked
    by the local Flutter tool hang and must not be retried blindly until the
    SDK/tool bootstrap issue is cleared.

Visible checklist refresh:

- [x] Re-audit the April 20 spec/checkpoint against the live branch.
- [x] Remove stale `go_router` backend assumptions from code/test/tooling.
- [x] Add explicit AutoRoute auth/onboarding route mapping coverage.
- [x] Add explicit auth/onboarding driver route-contract coverage.
- [x] Add auth current-route diagnostics coverage for login, consent, profile
  setup, pending approval, and account status.
- [x] Promote Company Setup from initial-frame-only sentinel proof to a mounted
  proof.
- [x] Stop non-bootstrap profile refresh churn from triggering route
  reevaluation.
- [x] Remove the remaining `project_provider_*` ignore directives.
- [~] Add provider-side notification/rebuild-pressure evidence.
- [ ] Restore a healthy Flutter toolchain, then run local static/targeted
  verification and live route smoke.
