---
feature: projects
type: architecture
scope: Project Management & Setup
updated: 2026-04-07
---

# Projects Feature Architecture

Projects remain the central context feature, but the presentation layer has
been decomposed so the setup/list flows are easier to test and easier for the
sync system to observe.

## Directory Shape

```text
lib/features/projects/
├── di/
│   ├── projects_providers.dart
│   └── project_screen_providers.dart
├── data/
├── domain/
└── presentation/
    ├── providers/
    │   ├── project_provider.dart
    │   ├── project_provider_auth_init.dart
    │   ├── project_provider_data_actions.dart
    │   ├── project_provider_filters.dart
    │   ├── project_provider_mutations.dart
    │   ├── project_provider_selection.dart
    │   ├── project_assignment_provider.dart
    │   ├── project_sync_health_provider.dart
    │   ├── project_import_runner.dart
    │   └── project_settings_provider.dart
    ├── controllers/
    │   ├── project_setup_controller.dart
    │   ├── project_setup_loader.dart
    │   ├── project_setup_save_service.dart
    │   ├── project_setup_back_handler.dart
    │   └── project_contractors_tab_controller.dart
    ├── screens/
    └── widgets/
```

## Root DI vs Screen DI

### `di/projects_providers.dart`

Registers long-lived feature state:
- `ProjectProvider`
- `ProjectAssignmentProvider`
- `ProjectSettingsProvider`
- `ProjectSyncHealthProvider`
- `ProjectImportRunner`
- lifecycle/use-case wiring

### `di/project_screen_providers.dart`

Registers screen-local controller scopes:
- `ProjectSetupControllerScope`
- `ProjectContractorsTabControllerScope`

This file is the composition root for project setup/list UI state. Screens
should not construct these controllers inline.

## ProjectProvider

`ProjectProvider` is now explicitly split by responsibility:
- auth bootstrap and reload behavior
- data loading actions
- filter/search state
- mutation flows
- selection/restoration logic

The provider still owns:
- project lists and merged remote/local view
- selected-project state
- assignment-aware filtering for inspector roles
- project CRUD and selection

But the implementation is no longer allowed to collapse back into a single
monolithic file.

## Screen Controllers

### ProjectSetupController

`ProjectSetupController` owns transient wizard state for create/edit flows.
Loader, save, and back-navigation behavior are extracted into separate files so
the controller stays focused and testable.

### ProjectContractorsTabController

This controller owns only the setup-tab contractor state. It is injected
through `project_screen_providers.dart` so the tab remains bootstrappable and
screen-local.

## Cross-Feature / Sync Surfaces

Projects remain the anchor for:
- project selection used by entries, forms, quantities, photos, and dashboard
- sync enrollment through `ProjectLifecycleService`
- per-project sync health through `ProjectSyncHealthProvider`

Because the project list is sync-relevant UI, its root sentinel and driver
contract must stay aligned with the driver registries.

## Key Files

- `lib/features/projects/di/projects_providers.dart`
- `lib/features/projects/di/project_screen_providers.dart`
- `lib/features/projects/presentation/providers/project_provider.dart`
- `lib/features/projects/presentation/controllers/project_setup_controller.dart`
- `lib/features/projects/presentation/controllers/project_setup_loader.dart`
- `lib/features/projects/presentation/controllers/project_setup_save_service.dart`
- `lib/features/projects/presentation/controllers/project_contractors_tab_controller.dart`
- `lib/features/projects/presentation/screens/project_list_screen.dart`
- `lib/features/projects/presentation/screens/project_setup_screen.dart`
