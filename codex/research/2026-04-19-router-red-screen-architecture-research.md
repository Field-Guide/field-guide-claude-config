# Router Red-Screen Architecture Research

Date: 2026-04-19
Branch: `gocr-integration`
Status: active routing architecture memo for the current sync-hardening lane

## Purpose

This memo captures the red-screen / duplicate-`GlobalKey` investigation so the
team can iterate on a single durable routing standard instead of re-learning
the same failure class from device runs.

It is intentionally opinionated. The goal is not to describe every possible
Flutter routing option. The goal is to record what actually failed in this app,
what partial fixes were rejected by evidence, what app-wide invariants now
exist, and when a router migration would become justified.

## Short decision

Stay on `go_router` for this release lane.

Do **not** start an `auto_route` migration as the immediate fix for the current
red screens.

Lock the app to a hardened `go_router` architecture instead:

1. keep `MaterialApp.router` ancestor shape stable;
2. keep `GoRouter` refresh narrow and route-driven;
3. keep shared shells dumb and route-intent-driven;
4. let `go_router` own navigator keys;
5. enforce the invariants with custom lints;
6. upgrade to the latest compatible `go_router` before re-running device proof.

`auto_route` becomes a justified lane only if the full-device UI proof still
shows the same router failure class after the hardened architecture and the
current compatible `go_router` release are both in place.

## What actually failed

Recent device artifacts repeatedly showed:

- duplicate `GlobalObjectKey int#...` failures;
- stale `InheritedGoRouter` parents;
- `InheritedElement.notifyClients` assertions;
- detached render object / blank-red-screen cascades;
- failures across phone and tablet surfaces, not one breakpoint only.

This made the bug app-wide, not flow-local.

## Rejected partial fixes

The following did **not** eliminate the failure class:

1. removing the app-owned root navigator key;
2. removing the production `ShellRoute`;
3. tweaking root responsive wrappers without narrowing router refresh;
4. disabling app lock alone;
5. page-key-only fixes in one flow.

These changes moved the failure around but did not remove the underlying churn.

## Root-cause hypothesis that fit the evidence

The strongest repo-backed hypothesis was:

1. `GoRouter` was refreshing from broad provider notifications instead of only
   route-affecting state.
2. The shared nav shell was reading `GoRouterState.of(context)` directly in
   `build()`, which re-subscribed a high-level shell to router state churn.
3. Startup and sync flows were generating frequent provider updates while the
   router was also evaluating redirects and shell rendering.
4. `go_router`'s internal navigator keys were therefore being forced through
   too much rebuild / redirect churn around boot and navigation transitions.

That aligns with the observed artifact timing: failures appeared before the
form flow itself did meaningful work and while the app was already on core
shell routes like `/projects`.

## Current local hardening in the repo

The current tree now has these app-wide fixes:

### 1. Narrow router refresh contract

`lib/core/router/router_refresh_notifier.dart`

- `GoRouter.refreshListenable` no longer listens directly to merged providers.
- A dedicated `RouterRefreshNotifier` captures only route-affecting auth,
  consent, and config state.
- Non-routing provider chatter no longer refreshes the router.

### 2. Shared shell no longer reads router state directly

`lib/core/router/scaffold_with_nav_bar.dart`

- `ScaffoldWithNavBar` now receives `PrimaryNavTab activeTab`.
- It no longer calls `GoRouterState.of(context)` in `build()`.
- Route intent is owned by route configuration, not inferred reactively inside
  the shared shell.

### 3. App router owns route intent explicitly

`lib/core/router/app_router.dart`

- primary tab routes pass explicit `PrimaryNavTab` values;
- `refreshListenable` now uses the narrowed notifier;
- the route surface stays top-level and avoids reintroducing nested router
  ownership drift.

### 4. Lints now enforce the routing rules

New or relevant custom lints:

- `no_direct_provider_refresh_listenable_in_app_router`
- `no_go_router_state_lookup_in_shared_shell`
- `no_material_app_router_builder_theme_wrapper`
- `no_explicit_shell_route_navigator_key`
- `no_go_router_state_page_key_in_shell_routes`
- `no_conditional_root_shell_child_wrapper`

These rules are intentionally path-scoped. They are not generic style rules;
they exist to block this exact failure class from returning.

### 5. Related harness cleanups found by the lint sweep

While making the router lint pass honest, the sweep also exposed soak issues:

- headless app-sync queries now apply soft-delete filtering where required;
- auth-readiness retries are logged instead of silently swallowed;
- serialized actor-queue failure carryover is now logged instead of silently
  swallowed.

Those were not the root cause of the router issue, but they were legitimate
guardrail failures uncovered during the same standardization pass.

## Package research

As of 2026-04-19:

- `go_router` on pub.dev was `17.2.1`, published 6 days earlier, with the
  package described as feature-complete and focused on bug fixes/stability:
  <https://pub.dev/packages/go_router>
- `auto_route` on pub.dev was `11.1.0`, published 4 months earlier:
  <https://pub.dev/packages/auto_route>

Relevant official `go_router` changelog items:

- `17.2.1`: fixes chained top-level redirects not being fully resolved and
  route-level redirects not triggering top-level redirect re-evaluation.
- `17.2.0`: fixes navigation callbacks being lost when triggered by
  `refreshListenable` due to re-entrant route processing.
- `17.0.1`: fixes stale state restoration loss when `onEnter` blocks.

Official changelog:
<https://github.com/flutter/packages/blob/main/packages/go_router/CHANGELOG.md>

Those `17.2.x` fixes overlap the same redirect / refresh churn surface we were
already hardening locally, so upgrading within the same major was warranted.

## Repo package state

Before this pass:

- `pubspec.yaml`: `go_router: ^17.0.1`
- `pubspec.lock`: `17.0.1`

After the bounded upgrade:

- `pubspec.lock`: `17.2.1`

This keeps the app on the same routing stack while pulling in upstream bug
fixes relevant to redirect and `refreshListenable` behavior.

## Why not jump straight to AutoRoute

`auto_route` is a real option, but not the right immediate fix here.

Why:

1. our strongest failure evidence pointed to app-owned routing architecture,
   not to an inability to express routes with `go_router`;
2. a migration would add codegen, route-model churn, and route declaration
   rewrites across a large app while we are still in sync hardening;
3. a router swap can mask ownership mistakes without proving they are gone;
4. the current `go_router` lane now has both local guardrails and a relevant
   upstream patch release.

So the right order is:

1. harden the architecture;
2. upgrade within `go_router`;
3. rerun device proof;
4. only then decide whether the router package itself remains the bottleneck.

## When AutoRoute becomes justified

Open a bounded `auto_route` migration spike only if **all** of the following
become true:

1. the current tree still reproduces duplicate-key / red-screen failures on
   rebuilt device apps after the narrowed refresh contract and latest compatible
   `go_router` upgrade;
2. the failure is still router-topology-related rather than a specific widget,
   overlay, or state-ownership bug;
3. the failure can be reproduced on a minimal shell/navigation slice;
4. the spike is evaluated as an architectural migration lane, not as an
   opportunistic “maybe a different router helps” patch.

If that threshold is met, the spike must answer:

- route declaration ergonomics;
- nested-shell behavior;
- redirect/guard ownership;
- deep-link handling;
- observer/support tooling;
- migration blast radius;
- generated-code impact on iteration speed;
- how we preserve current driver/testing-key contracts.

## Working architectural rules going forward

These rules are now the standard until replaced by an explicit migration
decision:

1. `MaterialApp.router` must not wrap the router child in mutable inherited
   theme shells.
2. Shared router shells must not read `GoRouterState` directly in `build()`.
3. Shared shells receive explicit route intent from the route table.
4. The app must not own `ShellRoute` navigator keys.
5. Router refresh must be driven by a narrow, route-affecting snapshot, not by
   broad provider merges.
6. New router hardening must land with a lint or test, not only with a code
   comment.
7. Device UI proof remains the real gate. Passing local widget tests does not
   close the lane.

## Relevant repo history

These commits are part of the reasoning trail:

- `98ae3eef` `fix(core): stabilize responsive root shell`
- `38815ba6` `fix(router): stop reparenting router GlobalKeys across auth redirects`
- `f350a26f` `feat(lints): enforce shell-route invariants behind the router GlobalKey fix`
- `5d38e569` `refactor(router): promote auth page ValueKeys into AuthTestingKeys`

They show the progression from local surface fixes toward enforced router
ownership invariants.

## Current next steps

1. keep the router architecture doc and lints as the source of truth;
2. finish the post-upgrade test cleanup;
3. rebuild device apps on the upgraded `go_router` tree;
4. rerun the live device lane with backend-device marker proof;
5. only open an `auto_route` spike if the hardened + upgraded `go_router` tree
   still reproduces the same class.

## Late 2026-04-19 live rerun addendum

The later four-lane rerun gave us a tighter failure window than the earlier
research pass.

### What changed in observability

- The soak harness now correctly fails loud on duplicate-key evidence even when
  `Save-SoakEvidenceBundle` returns an ordered dictionary instead of a
  PSCustomObject.
- That means duplicate-key failures are now classified immediately as
  `runtime_log_error` instead of being hidden behind a later widget wait
  timeout.

### What the live device evidence says now

- `build/soak/enterprise-four-lane-smoke-20260419-231123/` is the decisive
  rerun.
- On S21, preflight is healthy:
  `/projects`, `hasBottomNav=true`, `project_list_screen.rootPresent=true`,
  and the captured screenshot matches the Projects screen.
- By the first state-machine pre-sentinel, before the route mutation action
  runs, S21 is already broken:
  `/projects`, `hasBottomNav=false`, `project_list_screen.rootPresent=false`.
- The tablet runs the same lane and survives the same `/report/:entryId`
  navigation, so the failure is not just “driver navigated to report”.
- Live capture after the failed run shows:
  - S21: black surface on `MainActivity`, current route still reports
    `/report/...`, screen contract root is absent.
  - Tablet: rendered `/report/...`, entry editor root present.

### What this rules out

- The driver-only `pushReplacement` experiment is not a sufficient fix.
- The problem is not “lack of logs”; the current logging stack already
  identifies the failure class, the precise before/after window, and the
  device-specific divergence.

### What remains missing

We still do not log the exact router-build trigger that created the second
GoRouter-owned navigator subtree. The narrow remaining observability gap is:

- which route page builder was rebuilt;
- whether the app shell rebuilt with the same route and a different router
  identity; and
- whether the compact `/projects` tab overlap occurred before the explicit
  `/report` driver navigation.

### Updated architectural conclusion

The next bounded fix should remove the remaining animated overlap path in
`lib/core/router/app_router.dart` by making the primary app-owned tab pages
swap immediately, and it should land with:

1. router breadcrumb logging for shell/page rebuilds; and
2. a lint that forbids `CustomTransitionPage` in `app_router.dart`.

If the rebuilt device apps still reproduce the same duplicate-key collapse
after that change, then the `auto_route` migration threshold becomes much
closer, because the remaining evidence would point to a router package limit
rather than an app-owned transition invariant.

## Late 2026-04-19 compact-shell addendum

The next live repro tightened the root cause further than the earlier
`AppRouter`/primary-page analysis.

### What the live repro proved

- The S21 failure is still app-side after the earlier primary-route fix:
  live driver state reports `/report/...`, but the screen contract root is
  absent and the widget tree collapses to
  `WidgetsApp -> _LocalizationsScope -> ErrorWidget`.
- The large tablet remains the control:
  on the same report route it still has a healthy `_CustomNavigator ->
  AppScaffold` subtree and no comparable Flutter assertions.
- The host/compositor warnings are downstream noise. The first decisive app
  failures happen inside Flutter before any host-side draw complaint matters.

### New upstream evidence

Fresh S21 adb logs show the first compact-lane assertions in this order:

1. `renderObject.child == child` assertion failure
2. `Tried to build dirty widget in the wrong build scope`
3. offending element: `AnimatedPhysicalModel`
4. `Duplicate GlobalKey detected in widget tree`
5. stale parent: `InheritedGoRouter(goRouter: Instance of 'GoRouter')`

That sequence is materially better than the old evidence because it identifies
the first stale widget class before the router subtree truncates.

### Why this now points at the compact shell

The healthy S21 preflight tree shows the compact shell contains:

- `LayoutId key=[<_ScaffoldSlot.bottomNavigationBar>]`
- `NavigationBar key=[<'bottom_navigation_bar'>]`
- child `Material`
- child `AnimatedPhysicalModel`

This repo uses `NavigationBar` only in one place:

- `lib/core/router/scaffold_with_nav_bar.dart`

The large tablet path uses `NavigationRail`, not `NavigationBar`, and it is the
stable control in the same run. That makes the compact router shell the
strongest remaining app-owned cause.

### Updated root-cause statement

The remaining red/black-screen lane is best explained as:

- compact router shell uses animated Material 3 `NavigationBar`;
- that compact shell can remain dirty during router refresh/route replacement
  windows;
- once that stale `AnimatedPhysicalModel` path is left in the wrong build
  scope, `go_router`'s internal navigator `GlobalObjectKey` duplication is the
  downstream collapse, not the first cause.

### Updated architectural rule

Treat animated compact bottom-nav surfaces as part of router topology, not as
cosmetic UI. The compact shell must use a route-safe implementation with no
known dirty-widget carryover during router refresh/replacement.

Until proven otherwise, this means:

1. keep the hardened `go_router` architecture;
2. replace the compact `NavigationBar` path in
   `lib/core/router/scaffold_with_nav_bar.dart`;
3. keep `NavigationRail` for larger breakpoints;
4. add lint/test/doc guardrails so the compact animated shell path does not
   return silently.

### Impact on the AutoRoute decision

This evidence moves the immediate next step away from `auto_route`.

We still keep the migration threshold documented earlier, but the current most
upstream app-owned bug is now the compact shell implementation, not a proven
router-package ceiling. The right order stays:

1. remove the compact animated shell path;
2. rerun physical devices and four-lane proof;
3. only reopen `auto_route` if the same router-collapse class survives that.

## 2026-04-20 threshold update

The compact-shell fix did not close the failure class. The later rebuilt
four-lane proof still reproduced duplicate `GlobalObjectKey`, dirty build-scope,
and red/black screen collapse across the live-device/emulator matrix.

That crosses the migration threshold defined earlier in this memo:

1. the tree had already narrowed router refreshes;
2. the shell no longer read `GoRouterState.of(context)`;
3. app-owned shell navigator keys had been removed;
4. root responsive/theme wrappers had been stabilized;
5. `go_router` had been upgraded within the compatible major line;
6. primary route transitions and the compact animated bottom-nav path had been
   removed as active suspects; and
7. rebuilt device proof still reproduced the same router-topology failure
   class.

Updated decision: start an `auto_route` migration lane now, but do not treat it
as a package-only swap. The required architecture is:

- app-owned navigation intents and an `AppNavigator` boundary;
- AutoRoute as the target router behind that boundary;
- a temporary GoRouter adapter only for parity and rollback during migration;
- stable route-access snapshots for guards;
- provider cleanup so route reevaluation does not listen to broad
  `AuthProvider`/sync/profile churn; and
- custom lints that prevent feature and design-system widgets from depending
  directly on either router package.

If an AutoRoute vertical slice reproduces the same failure class while guards
are driven only by a stable route-access snapshot, the next root-cause lane is
provider/topology churn outside the router package rather than more GoRouter
hardening.
