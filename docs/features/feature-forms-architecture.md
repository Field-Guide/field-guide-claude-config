---
feature: forms
type: architecture
updated: 2026-04-07
---

# Forms Feature Architecture

The forms feature now combines registry-driven form behavior with thin screens
and screen-local controllers. The refactor kept the registry model intact while
splitting provider/controller responsibilities so MDOT-heavy screens no longer
collapse into god classes.

## Directory Structure

```text
lib/features/forms/
├── di/
│   ├── forms_providers.dart
│   └── form_screen_providers.dart
├── data/
│   ├── registries/
│   ├── services/
│   ├── validators/
│   └── pdf/
├── domain/
└── presentation/
    ├── providers/
    │   ├── inspector_form_provider.dart
    │   ├── inspector_form_provider_form_actions.dart
    │   ├── inspector_form_provider_response_actions.dart
    │   ├── inspector_form_provider_loading.dart
    │   ├── form_export_provider.dart
    │   └── document_provider.dart
    ├── controllers/
    │   ├── forms_list_controller.dart
    │   ├── form_viewer_controller.dart
    │   ├── mdot_hub_controller.dart
    │   ├── mdot_hub_controller_actions.dart
    │   ├── mdot_hub_controller_draft.dart
    │   ├── mdot_hub_controller_hydration.dart
    │   └── mdot_hub_controller_mutators.dart
    ├── screens/
    └── widgets/
```

## Root DI vs Screen DI

### `di/forms_providers.dart`

Registers long-lived providers, repositories, and services:
- `InspectorFormProvider`
- `FormExportProvider`
- `DocumentProvider`
- form repositories
- `AutoFillService`
- `FormPdfService`
- `FormStateHasher`

### `di/form_screen_providers.dart`

Registers screen-local controller scopes:
- `FormsListControllerScope`
- `FormViewerControllerScope`
- `MdotHubControllerScope`

These scopes are the composition roots for per-screen UI state and load
behavior.

## Provider Shape

### InspectorFormProvider

Still owns template/response loading and response mutations, but the
implementation is split into:
- loading helpers
- form/template actions
- response actions

This keeps the provider API stable without allowing it to regrow into a single
large file.

## Controllers

### FormsListController

Owns the lightweight list-screen orchestration that previously lived too close
to the screen widget.

### FormViewerController

Owns response loading/edit/viewer orchestration and depends on:
- `InspectorFormProvider`
- `ProjectProvider`
- `AuthProvider`
- `FormPdfService`

### MdotHubController

The MDOT hub is now explicitly decomposed into hydration, draft, mutator, and
action files so the hub UI remains testable and bounded.

## Registry Pattern

The registry model remains the core architectural choice:
- `FormScreenRegistry`
- `FormQuickActionRegistry`
- `FormPdfFillerRegistry`
- `FormValidatorRegistry`
- `FormCalculatorRegistry`
- `FormInitialDataFactory`

Adding a new form type still means registering capabilities rather than
rewiring orchestration code.

## Sync / Driver Surface

Forms screens that participate in verification flows must stay aligned with the
driver surface:
- `FormsListScreen`
- `FormViewerScreen`
- `MdotHubScreen`

That means keeping `TestingKeys`, screen contracts, and flow definitions in
sync when routes or screen shells change.

## Key Files

- `lib/features/forms/di/forms_providers.dart`
- `lib/features/forms/di/form_screen_providers.dart`
- `lib/features/forms/data/registries/form_screen_registry.dart`
- `lib/features/forms/presentation/providers/inspector_form_provider.dart`
- `lib/features/forms/presentation/controllers/form_viewer_controller.dart`
- `lib/features/forms/presentation/controllers/mdot_hub_controller.dart`
- `lib/features/forms/presentation/screens/forms_list_screen.dart`
- `lib/features/forms/presentation/screens/form_viewer_screen.dart`
- `lib/features/forms/presentation/screens/mdot_hub_screen.dart`
