# Pattern: Route Module

## How We Do It

This is a NEW pattern being introduced. Route modules will be top-level functions returning `List<RouteBase>` that the router composes. Each module owns the screen imports for its feature domain.

## Proposed Pattern (based on existing GoRouter usage in app_router.dart)

```dart
// lib/core/router/routes/auth_routes.dart
import 'package:go_router/go_router.dart';
import 'package:construction_inspector/features/auth/presentation/screens/screens.dart';

List<RouteBase> authRoutes() => [
  GoRoute(
    path: '/login',
    name: 'login',
    builder: (context, state) => const LoginScreen(),
  ),
  // ... more auth routes
];
```

## Route Categories (from ground-truth.md)

| Module | Routes | Key Imports |
|--------|--------|-------------|
| `auth_routes.dart` | 7 routes: /login, /register, /forgot-password, /verify-otp, /update-password, /update-required, /consent | `auth/presentation/screens/screens.dart` |
| `project_routes.dart` | 4 routes: /project/new, /project/:id/edit, /quantities, /quantity-calculator/:id | `projects/presentation/screens/screens.dart`, `quantities/presentation/screens/screens.dart` |
| `entry_routes.dart` | 6 routes: /entry/:pid/:date, /report/:id, /entries, /drafts/:pid, /review, /review-summary, /personnel-types/:pid | `entries/presentation/screens/screens.dart`, `entries/data/models/daily_entry.dart` |
| `form_routes.dart` | 3 routes: /import/preview/:pid, /mp-import/preview/:pid, /form/:responseId | `forms/forms.dart`, `pdf/services/mp/mp_models.dart`, extraction pipeline imports, `forms/data/registries/form_screen_registry.dart`. Owns `_mpResultFromJobResult` helper. |
| `toolbox_routes.dart` | 4 routes: /toolbox, /forms, /calculator, /gallery | `toolbox/toolbox.dart`, `calculator/calculator.dart`, `gallery/gallery.dart`, `forms/forms.dart` |
| `settings_routes.dart` | 6 routes: /settings/trash, /edit-profile, /admin-dashboard, /help-support, /legal-document, /oss-licenses | `settings/presentation/screens/screens.dart`. Note: /settings/trash needs `parentNavigatorKey: rootNavigatorKey` |
| `sync_routes.dart` | 2 routes: /sync/dashboard, /sync/conflicts | `sync/presentation/screens/sync_dashboard_screen.dart`, `conflict_viewer_screen.dart` |
| `onboarding_routes.dart` | 4 routes: /profile-setup, /company-setup, /pending-approval, /account-status | `auth/presentation/screens/screens.dart` (same screens barrel) |

**Note**: Auth and onboarding routes share the same screen barrel import. Could be merged into one module or kept separate for clarity.

## Composition in app_router.dart

```dart
GoRouter _buildRouter() => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: _initialLocation,
  observers: Logger.isEnabled ? [AppRouteObserver()] : const [],
  refreshListenable: Listenable.merge([_authProvider, _appConfigProvider, _consentProvider]),
  redirect: _appRedirect.redirect,
  routes: [
    ...authRoutes(),
    ...onboardingRoutes(),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: shellRoutes(),  // dashboard, calendar, projects, settings
    ),
    ...entryRoutes(),
    ...projectRoutes(),
    ...formRoutes(),
    ...toolboxRoutes(),
    ...settingsRoutes(rootNavigatorKey: _rootNavigatorKey),
    ...syncRoutes(),
  ],
);
```

## Key Considerations

1. **Shell routes** (4 routes with bottom nav) stay inline or get their own `shellRoutes()` function — they're part of the `ShellRoute` children
2. **Navigator key passing**: `/settings/trash` needs `parentNavigatorKey: _rootNavigatorKey` — the settings route module needs the key as a parameter
3. **`_mpResultFromJobResult`**: Moves to `form_routes.dart` since it's only used by the MP import preview route
4. **Imports**: Each route module only imports the screens/models it needs — this is the main win (app_router.dart currently imports 28 files)

## Imports (for app_router.dart after decomposition)

```dart
import 'package:construction_inspector/core/router/routes/auth_routes.dart';
import 'package:construction_inspector/core/router/routes/onboarding_routes.dart';
import 'package:construction_inspector/core/router/routes/entry_routes.dart';
import 'package:construction_inspector/core/router/routes/project_routes.dart';
import 'package:construction_inspector/core/router/routes/form_routes.dart';
import 'package:construction_inspector/core/router/routes/toolbox_routes.dart';
import 'package:construction_inspector/core/router/routes/settings_routes.dart';
import 'package:construction_inspector/core/router/routes/sync_routes.dart';
// Only core imports remain: go_router, app_redirect, scaffold_with_nav_bar, logger
```
