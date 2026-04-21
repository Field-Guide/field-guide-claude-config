# AutoRoute Routing + Provider Refactor Todo Spec

Date: 2026-04-20
Status: active child implementation spec under
`.codex/plans/2026-04-20-unified-routing-state-sync-soak-driver-spec.md`

## Decision

Start the AutoRoute migration lane now.

This is not just a router-package swap. The app also needs a routing boundary
and a provider refactor because the failure class is tied to route topology
plus volatile provider refreshes. AutoRoute becomes the target router, while
the app-owned navigation and route-access layers are the durable architecture.

The current GoRouter lane has crossed its decision threshold: narrowed router
refresh, explicit shell route intent, removed app-owned shell keys, stabilized
root wrappers, GoRouter upgrade, and compact shell replacement did not
eliminate duplicate GlobalKey / dirty build-scope / red-black screen failures.

## Deliverables

- [x] Create this spec in `.codex/plans/`.
- [x] Create `.codex/checkpoints/2026-04-20-autoroute-routing-provider-refactor-checkpoint.md`.
- [x] Update `.codex/research/2026-04-19-router-red-screen-architecture-research.md`.
- [x] Keep a visible on-screen checklist current while implementing.
- [x] Fold in only routing/provider-relevant items from the hygiene spec.
- [x] Leave unrelated hygiene work out of this lane: logger, database lifecycle,
  PDF extraction, model/freezed, OCR dictionary, and unrelated sync-engine
  decomposition.

## Phase 0: Baseline And Guard The Decision

- [x] Freeze new localized GoRouter hardening except comparison logging.
- [x] Record the GoRouter threshold-crossing evidence in the research memo.
- [x] Inventory direct router imports and direct navigation calls.
- [x] Inventory provider state used by routing:
  `isLoadingProfile`, `userRole`, `canManageProjects`,
  `canManageProjectFieldData`, `requiresUpdate`, `requiresReauth`, consent,
  password recovery, membership status, company presence, and display-name
  presence.
- [x] Inventory profile refresh calls from screen/sync surfaces:
  project list mount, project delete confirmation, pending approval, company
  setup, and sync initializer post-pull refresh.
- [ ] Preserve baseline device artifact paths for comparison.

## Phase 1: App-Owned Navigation Boundary

- [x] Add a router-neutral app navigation package.
- [x] Define `AppNavigator`.
- [x] Define `AppRouteId`.
- [x] Define `AppRouteIntent`.
- [x] Define typed route params and route results.
- [x] Define route observer/logging hooks.
- [x] Keep a temporary GoRouter adapter behind `AppNavigator`.
- [x] Add an AutoRoute adapter behind the same `AppNavigator`.
- [x] Keep feature widgets unaware of whether GoRouter or AutoRoute is active.
- [x] Replace direct `context.goNamed`, `context.pushNamed`, `context.go`, and
  `context.push` with app route intents.
- [x] Preserve driver route contracts through compatibility mapping until the
  full route migration is complete.
  - 2026-04-20 update: `DriverRouteContract` now declares `auto_route`
    support for screen-contract-derived routes, and targeted contract tests
    assert that every route contract includes the AutoRoute backend.

## Phase 2: Provider Refactor Required By Routing

- [ ] Keep `provider` and `ChangeNotifier`; do not add Riverpod, BLoC, GetX, or
  another state-management system.
- [x] Add immutable `RouteAccessSnapshot`.
- [x] Add `RouteAccessController` as the narrow route-reevaluation notifier.
- [x] Make route guards read only `RouteAccessSnapshot`, not broad presentation
  providers.
- [ ] Remove `isLoadingProfile` from route reevaluation unless it is part of the
  first auth bootstrap decision.
- [x] Extract role and permission logic from `AuthProvider` into `RolePolicy`.
- [x] Add an attribution/company/user cache for stable route and sync identity
  reads.
- [x] Add `ProfileRefreshScheduler`.
- [x] Move screen-mounted `refreshUserProfile()` calls behind the scheduler
  where possible.
- [ ] Prevent sync dirty markers and background pulls from directly causing
  router or guard reevaluation.
- [x] Replace widget permission reads from `AuthProvider` with
  `context.select<RolePolicy, bool>`.
- [x] Replace `ProjectProvider` permission callbacks that close over
  `AuthProvider`.
- [ ] Remove `ignore_for_file: unused_element` from `project_provider_*` files
  while cleaning provider internals.
- [ ] Measure rebuild pressure on the project list before and after the split.

## Phase 3: AutoRoute Vertical Slice

- [x] Add dependencies: `auto_route`, `auto_route_generator ^10.4.0`, and
  `build_runner`.
- [x] Document the generated-route output convention.
  - Generated AutoRoute output lives beside its router under
    `lib/core/router/autoroute/*.gr.dart`; generated files are never edited by
    hand.
- [x] Build a production-shaped AutoRoute slice:
  auth/login gate, Projects tab, Settings tab, one project detail route, one
  report/editor route, compact shell, and tablet shell.
- [x] Use `AutoTabsRouter` for primary tabs.
- [x] Use guards backed only by `RouteAccessSnapshot`.
- [x] Do not connect AutoRoute guard reevaluation directly to `AuthProvider`.
- [x] Preserve testing keys and driver screen contracts for the slice.
- [x] Add route-build, tab-switch, guard, and reevaluation logs.
- [x] Add driver/debug build switch for the AutoRoute slice:
  `tools/start-driver.ps1 -UseAutoRouteVerticalSlice` and
  `tools/build.ps1 -UseAutoRouteVerticalSlice`.
- [x] Key Android driver reinstall freshness on `dartDefinesHash` so changing
  routing backends cannot reuse a stale APK on devices.
- [ ] Run S21/S10/emulator repro against the slice.
- [ ] Continue full migration only if the slice eliminates duplicate GlobalKey,
  dirty build-scope, stale router scope, red screen, and black screen failures.

## Phase 4: Full Route Migration

- [x] Convert core route declarations into AutoRoute definitions.
  - 2026-04-20 update: the AutoRoute route surface now covers
    auth/onboarding, primary tabs, projects, entries/reports, forms,
    pay apps, sync/conflicts/trash/exports, settings/admin/help/legal/profile,
    toolbox, gallery, todos, analytics, quantities, and calculator routes.
- [x] Move route ownership toward feature route modules.
  - 2026-04-20 update: route-neutral ownership is now in feature route
    catalogs, while AutoRoute-specific `@RoutePage` wrappers are split by
    route family under the approved `core/router/autoroute` composition layer.
    Feature code still does not import `auto_route`; that boundary is enforced
    by lint.
- [x] Replace `core/router/routes/*` with feature-owned route contributors or
  generated route declarations.
  - 2026-04-20 update: the legacy GoRouter page-builder/data-guard modules
    under `core/router/routes/*` are deleted. Production route assembly now
    lives in AutoRoute declarations plus the route-family page-wrapper seam
    under `core/router/autoroute/pages/`.
  - 2026-04-20 update: route-specific access checks that were previously split
    across compatibility redirects now live in the shared `RouteAccessPolicy`
    using feature-owned `AppRouteAccessPolicy` metadata.
- [x] Stop core router/composition from importing arbitrary feature
  presentation screens outside approved composition seams.
  - 2026-04-20 update: the former monolithic
    `app_auto_router_pages.dart` file is now only an export barrel. Screen
    imports live in focused AutoRoute page-wrapper files under
    `core/router/autoroute/pages/`, which is the approved router-package
    composition seam.
- [x] Convert auth/onboarding routes.
- [x] Convert primary tabs: dashboard/home, calendar, projects, settings.
- [x] Convert project routes.
- [x] Convert entry/report/editor routes.
- [x] Convert form routes.
  - 2026-04-20 update: PDF import preview and M&P import preview now render
    the real preview screens under AutoRoute and carry the same payloads as the
    GoRouter compatibility routes.
- [x] Convert pay-application routes.
- [x] Convert sync dashboard/conflict/trash/export routes.
- [x] Convert toolbox routes.
- [x] Convert settings/admin/profile/help/legal routes.
- [x] Convert dashboard quick-action navigation.
  - 2026-04-20 update: feature navigation remains on `AppRouteIntent` through
    `BuildContext.appGo/appPush`, and those extensions now consume the scoped
    router-backed `AppNavigator` instead of hard-wiring GoRouter.
- [ ] Convert design-system route actions into callbacks or route intents.
- [x] Remove the GoRouter adapter after production routes no longer use it.
  - 2026-04-20 update: `AppRouter`, `AppRedirect`,
    `RouterRefreshNotifier`, and `GoRouterAppNavigator` are removed from the
    production app path. `AppBootstrap` now builds `AppAutoRouterHost`
    directly, and `ConstructionInspectorApp` always scopes `AutoRouteAppNavigator`.
- [ ] Remove the GoRouter dependency after tests and driver flows no longer
  require it.

## Phase 5: Feature Boundary Hygiene

- [x] Add `FeatureRouteCatalog` or equivalent route contribution interface.
  - 2026-04-20 update: route descriptors already live under feature
    presentation navigation folders and are assembled by
    `core/navigation/app_route_catalog.dart`.
- [ ] Require feature routes to declare route id, path, typed params, access
  policy, page factory, and shell/tab metadata where applicable.
  - 2026-04-20 partial: descriptors now gate route id, path template,
    declared path/query params, extra-payload allowance, access policy, and
    shell/tab metadata. Page factory ownership is still in the router/page
    assembly layer and remains open.
  - 2026-04-20 update: AutoRoute page wrappers are now split by route family,
    but they intentionally remain in the app router composition layer because
    production feature modules are lint-blocked from importing router
    packages. A future route-neutral page-factory abstraction can be added
    without weakening that lint boundary.
- [x] Decide page-factory ownership.
  - 2026-04-20 update: page/widget factories do **not** belong in feature
    route catalogs. Feature catalogs remain router-neutral metadata only, and
    page assembly stays in the approved `core/router/autoroute/**`
    composition seam.
- [x] Add feature-local route tests.
  - 2026-04-20 update: `test/features/navigation/feature_route_catalogs_test.dart`
    locks each feature catalog's owned `AppRouteId` set, path-parameter
    declarations, non-empty feature ids/routes, and the intentional public
    route set.
- [x] Keep one app-level route assembly test.
  - 2026-04-20 update: app-level route catalog tests assert every `AppRouteId`
    is described exactly once, path params match the route template, and route
    intents are rejected if they violate the owning feature descriptor.
- [ ] Add or update lints for core-feature, data-presentation, and domain purity
  boundaries where the routing migration touches those seams.

## Phase 6: Design-System And Shell Rules

- [x] Design-system components cannot import router packages.
  - 2026-04-20 update: router package imports are lint-blocked outside
    approved navigation/router owners; design-system code is not an approved
    owner.
- [x] Design-system components cannot call route navigation directly.
  - 2026-04-20 update: `no_raw_navigator` is now an error-level app
    navigation rule for route-level `Navigator.push*` calls outside approved
    navigation/router owners. Local `Navigator.pop` remains allowed for
    dialog/sheet/modal result ownership.
- [ ] Design-system components receive callbacks, commands, or route intents.
- [ ] Modal helpers own dialog/sheet navigation.
- [x] Route-level navigation cannot use raw `Navigator.push`.
  - 2026-04-20 update: route-level `Navigator.push*` is lint-blocked outside
    approved app navigation/router owners; app code must route through
    `AppNavigator` / `AppRouteIntent`.
- [ ] `Navigator.pop` is allowed only for approved local modal/pop ownership.
- [ ] Shared shells cannot read router state in `build`.
- [ ] Shared shells receive active tab or route intent explicitly.
- [ ] Avoid animated primary route transitions until the failure class is gone.
- [ ] Avoid mutable inherited wrappers below the app router root.
- [ ] Audit `GlobalKey` usage in route/shell/design-system surfaces.

## Phase 7: Lints And Enforcement

- [x] Add lint: production features cannot import `go_router`.
- [x] Add lint: production features cannot import `auto_route`.
- [x] Add lint: only app navigation layer may import router packages.
  - 2026-04-20 update: `no_go_router_import_outside_approved_owners` and
    `no_auto_route_import_outside_navigation_layer` are present and their lint
    rule unit tests pass.
- [x] Add lint: generated AutoRoute files are allowed only in the configured
  output location.
  - 2026-04-20 update: `no_autoroute_generated_file_outside_router` allows
    only `lib/core/router/autoroute/app_auto_router.gr.dart` for AutoRoute
    `*.gr.dart` output. The generated file is intentionally contained rather
    than hand-split; hand-owned route wrappers are already split by route
    family under `lib/core/router/autoroute/pages/`.
- [x] Add lint: design-system package cannot navigate directly.
  - 2026-04-20 update: direct router imports are already blocked, and
    route-level raw `Navigator.push*` is now blocked outside approved app
    navigation/router owners. Modal `Navigator.pop` remains allowed.
- [x] Add lint: route guards cannot depend on volatile provider fields.
  - 2026-04-20 update: `no_volatile_route_guard_provider_fields` blocks route
    guard and router-reevaluation owners from reading profile loading,
    refresh-in-flight, or sync-progress fields directly. Guards must consume
    `RouteAccessSnapshot`.
- [x] Add lint: route reevaluation cannot depend on `isLoadingProfile`.
  - 2026-04-20 update: `no_volatile_route_access_snapshot_fields` keeps
    `isLoadingProfile` out of `RouteAccessSnapshot`, and
    `no_volatile_route_guard_provider_fields` blocks the same volatile field
    from direct guard/reevaluation code.
- [x] Add lint: screen init/mount cannot call profile refresh APIs that trigger
  route reevaluation.
  - 2026-04-20 update:
    `no_direct_profile_refresh_in_screen_lifecycle` blocks direct
    `refreshUserProfile()` / `refreshUserProfileIfDue()` calls from feature
    presentation screens/widgets/controllers. Screen refresh work must use
    `ProfileRefreshScheduler`.
- [x] Add lint: raw route-level `Navigator` usage is banned outside approved
  modal owners.
  - 2026-04-20 update: `no_raw_navigator` is now error-level and app-owned
    navigation worded; it bans route-level `Navigator.push*` outside approved
    navigation/router owners while preserving local modal `pop` ownership.
- [ ] Add lint tests for every rule.
  - 2026-04-20 update: lint tests now cover the newly added AutoRoute
    generated-output, raw route-level Navigator, volatile route guard, and
    screen lifecycle profile-refresh rules. This remains open until every
    remaining Phase 7 rule exists and has tests.
- [ ] Run `flutter analyze` and `dart run custom_lint` after every slice.

## Phase 8: Observability

- [ ] Log every route guard evaluation.
- [ ] Log every route reevaluation trigger.
- [ ] Log previous and next `RouteAccessSnapshot`.
- [ ] Log changed snapshot fields.
- [ ] Log current route before and after navigation.
- [ ] Log tab switch source and target.
- [ ] Log shell builds with breakpoint and route id.
- [ ] Log route page builds with route id and params.
- [ ] Add first-failure extraction for duplicate GlobalKey, dirty build-scope,
  stale inherited router scope, detached render object, no-frame black screen,
  and Flutter red screen.

## Phase 9: Device And Sync-Hardening Proof

- [ ] Run route unit tests.
- [ ] Run provider snapshot tests.
- [ ] Run custom lint tests.
- [ ] Run compact/tablet shell widget tests.
- [ ] Run S21 physical device route smoke.
- [ ] Run S10 physical device route smoke.
- [ ] Run two-emulator route smoke.
- [ ] Start all device-lab driver apps with `-UseAutoRouteVerticalSlice`.
- [ ] Confirm driver build manifests include
  `FG_USE_AUTOROUTE_VERTICAL_SLICE=<redacted>`.
- [ ] Run four-lane backend-device marker proof with real auth.
- [ ] Run backend pressure concurrently with device UI proof.
- [ ] Verify sync markers prove backend-to-device visibility.
- [ ] Verify no route reevaluation occurs from non-route-affecting provider
  updates.
- [ ] Fail loudly on red screen, black screen, duplicate GlobalKey, dirty
  build-scope assertion, stale router scope, missing screen contract, mock auth,
  screenshot mismatch, or missing sync marker.

## Acceptance Criteria

- [x] No production feature widget imports `go_router`.
- [x] No production feature widget imports `auto_route`.
- [x] No design-system component imports router packages.
- [ ] Route guards read only stable route-access snapshots.
- [ ] Screen/sync profile refreshes do not churn router reevaluation.
- [ ] AutoRoute vertical slice passes on S21, S10, and emulators.
- [ ] Full migration passes four-lane live device proof.
- [ ] Real auth only; no `MOCK_AUTH`.
- [ ] Device screenshots, screen contracts, runtime logs, and sync marker proof
  all pass.

## Spec Audit Addendum - 2026-04-20 Post-Cutover

This addendum reconciles the April 20 spec against the current branch after
the latest AutoRoute/auth-route commits. Use this section as the live
remaining-work reference instead of reading the older unchecked boxes
literally.

### Audited Inputs

- [x] `.claude/codex/plans/2026-04-20-autoroute-routing-provider-refactor-todo-spec.md`
- [x] `.claude/codex/checkpoints/2026-04-20-autoroute-routing-provider-refactor-checkpoint.md`
- [x] recent commits through `7532dcc4`, `ca42f998`, `34b9a6bf`, and
  `04d84cb9`
- [x] current routing/auth/driver surfaces:
  `AppRouteId`, `AutoRouteAppNavigator`, `AppAutoRouter`,
  `RouteAccessPolicy`, `RouteAccessController`, `DriverRouteContract`,
  `screen_contract_registry.dart`, and `device_state_machine.dart`
- [x] focused verification on 2026-04-20:
  `app_route_catalog_test.dart`, `app_auto_router_test.dart`,
  `route_access_policy_test.dart`, `route_access_controller_test.dart`,
  `registry_alignment_test.dart`, `driver_route_contract_test.dart`,
  `root_sentinel_auth_widget_test.dart`, and `device_state_machine_test.dart`

### Confirmed Completed Work To Preserve

- [x] AutoRoute is now the only production routing backend.
- [x] `go_router` is removed from `pubspec.yaml`; it no longer backs the app.
- [x] auth/onboarding routes are present in `AppRouteId`,
  feature route catalogs, AutoRoute page wrappers, and the generated route
  surface.
- [x] auth runtime state is integrated into route access, device-state
  diagnostics, and host readiness through `AuthSessionState`, `ProfileState`,
  and sync auth context capture.
- [x] driver route contracts and screen contracts cover the auth/onboarding
  route family.
- [x] current focused route/auth/driver verification is green.

### Audit Corrections And Stale Items

- [x] The Phase 1 temporary GoRouter adapter work is historical. The app no
  longer ships a parallel GoRouter backend.
- [x] The Phase 4 item “remove the GoRouter dependency” is complete.
- [x] The Phase 9 `-UseAutoRouteVerticalSlice` /
  `FG_USE_AUTOROUTE_VERTICAL_SLICE` checklist items are stale. The flag was
  retired in `7532dcc4` and now survives only as a no-op warning for old local
  scripts.
- [x] Remaining `go_router` strings are audit/test/lint history or driver
  backend normalization, not active production routing.

### Actual Remaining Work

#### 1. Auth/Onboarding Forward-Backward Verification

- [ ] Add explicit navigator mapping tests for every auth/onboarding route:
  login, register, forgot password, verify OTP, update password, consent,
  profile setup, company setup, pending approval, and account status.
- [ ] Add explicit forward/back behavior tests for auth/onboarding flows,
  especially query-driven routes (`verify-otp`, `pending-approval`,
  `account-status`) and back/pop behavior after successful transitions.
- [ ] Extend auth root-sentinel widget coverage to include the still-missing
  screen set: `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`,
  `OtpVerificationScreen`, and `ConsentScreen`.
- [ ] Tighten Company Setup auth widget proof beyond the current
  initial-frame-only sentinel check so the screen is exercised with its
  required provider seam in a fully mounted state.

#### 2. Driver/Auth Route Parity

- [ ] Add explicit driver route-contract resolution tests for the
  auth/onboarding family, not only broad registry alignment.
- [ ] Add auth-route driver diagnostics tests that prove `/driver/current-route`
  and route-contract resolution stay aligned on login, consent, profile setup,
  pending approval, and account status surfaces.
- [ ] Verify forward and backward driver-safe navigation for auth redirect and
  recovery paths, especially login -> consent, login -> profile setup, and
  pending-approval/account-status redirects.

#### 3. Provider And Reevaluation Cleanup

- [ ] Remove the remaining
  `ignore_for_file: unused_element{,_parameter}` directives from the split
  `project_provider_*` files.
- [ ] Add proof that non-route-affecting auth/profile refresh churn and
  background sync noise do not trigger route reevaluation.
- [ ] Measure project-list rebuild pressure after the provider split and record
  the baseline/result in the checkpoint.
- [ ] Preserve baseline device artifact paths for router-comparison evidence
  before live-device proof resumes.

#### 4. Design-System, Shell, And Lint Closeout

- [ ] Finish the lint-test matrix for the remaining navigation-ownership rules
  still referenced by this spec.
- [ ] Audit remaining modal/pop ownership surfaces and decide whether they stay
  as approved local modal ownership or need tighter linting.
- [ ] Audit primary-shell/runtime risk areas still named by the spec:
  animated primary-route transitions, mutable inherited wrappers under the
  router root, and route/shell/design-system `GlobalKey` usage.

#### 5. Live Proof And Final Acceptance

- [ ] Run the full route/auth/provider/driver verification slice:
  `flutter analyze`, `dart run custom_lint`, the expanded route/auth/driver
  tests, and compact/tablet shell widget tests.
- [ ] Run S21 physical route smoke on the AutoRoute-only backend.
- [ ] Run S10/tablet physical route smoke on the AutoRoute-only backend.
- [ ] Run the two-emulator AutoRoute-only route smoke.
- [ ] Run four-lane live proof with real auth and current driver contracts.
- [ ] Run backend/device marker proof and concurrent pressure only after the
  no-pressure route proof is green.

### Current Priority Order

1. [ ] Finish auth/onboarding forward/backward route tests.
2. [ ] Finish auth-route driver parity tests.
3. [ ] Close the remaining provider reevaluation cleanup and project-provider
   hygiene items.
4. [ ] Run the full static/targeted verification slice.
5. [ ] Resume live device proof only after the above are green.

### 2026-04-21 Audit Update

- Implemented after the post-cutover audit:
  - the auth/onboarding local-proof slice now has a stateful fake auth service,
    bounded consent scrolling, explicit AutoRoute auth/onboarding path mapping,
    expanded root-sentinel auth coverage, and explicit auth/onboarding driver
    route-contract plus current-route diagnostics coverage;
  - `RouteAccessSnapshot` no longer includes `profileState`, and controller
    tests now prove that non-bootstrap profile refresh churn does not trigger
    route reevaluation;
  - the split `project_provider_*` mixins now bind directly to the concrete
    `ProjectProvider` library scope, removing the remaining
    `ignore_for_file: unused_element{,_parameter}` directives;
  - provider notification-hygiene tests now lock the no-op behavior for
    unchanged role/permission/init/search writes so repeated auth/controller
    sync does not generate unnecessary rebuild pressure;
  - lingering live code/test/tooling `go_router` references were removed so
    the branch no longer advertises dual-backend support.
- Still open after that implementation slice:
  - measure and record widget-level project-list rebuild-pressure evidence once
    the Flutter toolchain is healthy enough to run the relevant tests;
  - restore a healthy local Flutter toolchain, then run the full
    `flutter analyze` / `custom_lint` / route-auth-driver verification slice;
  - resume device/emulator/live proof only after the local toolchain is
    healthy again.
- Verification blocker discovered during this audit:
  - the local Flutter tool hangs even on `flutter --version` and direct
    `flutter_tools.snapshot --version`, spawning orphaned SDK `cmd.exe` /
    `dart.exe` workers;
  - the new auth-flow suite also contained an unbounded consent scroll helper,
    which has been replaced with a bounded loop so future failures fail fast
    instead of pinning the runner.
