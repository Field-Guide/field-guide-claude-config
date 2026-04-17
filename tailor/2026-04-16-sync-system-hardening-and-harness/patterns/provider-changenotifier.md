# Pattern — Provider + ChangeNotifier (Sync-Facing Features)

## How the repo does it

Every sync-visible feature has a `ChangeNotifier`-based provider with decomposed mixins for separate concerns. Composition is mixin-based (`with SafeAction, ProjectProviderFilters, ProjectProviderDataActions, ...`) with each mixin declared in a `part` file of the main provider library. Auth-driven reloads run through a dedicated controller class (`ProjectProviderAuthController`) that owns the `AuthProvider.addListener` lifecycle and returns a cleanup thunk.

## Exemplars

- `lib/features/projects/presentation/providers/project_provider.dart` — composes 6 mixins via `part` directives.
- `lib/features/projects/presentation/providers/project_provider_auth_controller.dart` — owns listener lifecycle, returns `VoidCallback` for cleanup.
- `lib/features/sync/presentation/providers/sync_provider.dart` — 74 symbols composed across `sync_provider_controls.dart`, `sync_provider_listeners.dart`, `sync_provider_status_text.dart` part files.
- `lib/features/auth/presentation/providers/auth_provider.dart` — part files for auth, company-profile, recovery, security actions.

## Reusable surface

```dart
// Main provider file (library)
import 'package:flutter/foundation.dart';
import 'package:construction_inspector/shared/providers/safe_action_mixin.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'project_provider_auth_controller.dart';

part 'project_provider_auth_init.dart';
part 'project_provider_filters.dart';

class ProjectProvider extends ChangeNotifier with SafeAction, ProjectProviderFilters {
  // Private fields used by mixins live on the main class.
  // Mixins read them through private abstract getters:
  //   @override List<Project> _projects = [];

  ProjectProvider(this._useCase);

  void _notifyStateChanged() => notifyListeners();

  @override
  void dispose() {
    _authListenerCleanup?.call();
    super.dispose();
  }
}

// Part file — project_provider_filters.dart
part of 'project_provider.dart';

mixin ProjectProviderFilters {
  List<Project> get _projects;
  Set<String> get _assignedProjectIds;
  CompanyFilter get _companyFilter;

  Iterable<Project> get visibleProjects =>
      _projects.where((p) => _assignedProjectIds.contains(p.id));
}

// Auth-driven reloads
class ProjectProviderAuthController {
  const ProjectProviderAuthController({
    required Future<void> Function(String? companyId) loadProjectsByCompany,
    required Future<void> Function(String userId) loadAssignments,
    // ... callbacks for every state mutation
  });

  VoidCallback initWithAuth({
    required AuthProvider authProvider,
    required ProjectSettingsProvider settingsProvider,
    required SyncCoordinator syncCoordinator,
  }) {
    // Initial load on construction
    // Subscribe to authProvider changes
    void onAuthChanged() { /* ... */ }
    authProvider.addListener(onAuthChanged);
    return () => authProvider.removeListener(onAuthChanged);
  }
}
```

## Ownership boundaries

- State lives on the main provider class as private fields. Mixins access via private abstract getters. This keeps the mixin testable and the main class the single composition point.
- Auth listener lifecycle lives in a dedicated controller, not inline in the provider. The provider stores the cleanup thunk and calls it in `dispose()`.
- `SyncCoordinator` is the sync entrypoint the controller calls. Never call `SyncEngine` directly from presentation.
- `mounted` checks are not needed on `ChangeNotifier` itself — notify is fire-and-forget. Listeners handle their own unmounted cases.

## Flashing-fix shape (Phase 6)

Current bug: `_loadAssignments(userId)` and `_loadProjectsByCompany(companyId)` run as independent `unawaited(...)` futures in `onAuthChanged`. The project list can render before `_assignedProjectIds` is populated, showing unfiltered data for one frame.

Fix shape: await both loads (or `Future.wait([...])`) before the first `_setInitializing(false)` / `notifyListeners` call, so the first render already has `_assignedProjectIds` populated and the filter applied. No skeleton-then-filter pattern per Scope.

```dart
// Before (leakable):
if (userOrRoleChanged && newUserId != null) {
  unawaited(_loadAssignments(newUserId));
}
if (newCompanyId != null && newCompanyId != lastLoadedCompanyId) {
  lastLoadedCompanyId = newCompanyId;
  _setInitializing(true);
  unawaited(_loadProjectsForCompanyAndRestoreSelection(newCompanyId, settingsProvider));
  unawaited(syncCoordinator.syncLocalAgencyProjects(mode: SyncMode.quick));
}

// After (atomic):
if ((userOrRoleChanged && newUserId != null) ||
    (newCompanyId != null && newCompanyId != lastLoadedCompanyId)) {
  lastLoadedCompanyId = newCompanyId;
  _setInitializing(true);
  await Future.wait([
    if (userOrRoleChanged && newUserId != null) _loadAssignments(newUserId),
    if (newCompanyId != null) _loadProjectsByCompany(newCompanyId),
  ]);
  _setInitializing(false);
  // notifyListeners happens inside _setInitializing(false) or wrap this call.
  unawaited(syncCoordinator.syncLocalAgencyProjects(mode: SyncMode.quick));
}
```

The exact async shape must keep `ProjectProviderAuthController` callbacks aligned with the new atomicity. The plan writer should preserve the typedef `ProjectRestoreFailureHandler` callback signature.
