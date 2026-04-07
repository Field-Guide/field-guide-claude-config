---
feature: forms
type: overview
scope: Inspection form management and PDF generation
updated: 2026-04-07
---

# Forms Feature Overview

## Purpose

The forms feature manages built-in inspection forms, response entry, registry-
driven calculations, and form PDF export.

## Current UI Structure

- `forms_providers.dart` owns long-lived form providers and services
- `form_screen_providers.dart` owns `FormsListController`, `FormViewerController`, and `MdotHubController` scopes
- `InspectorFormProvider` is split into loading, form-action, and response-action surfaces
- `MdotHubController` is decomposed into hydration, draft, mutator, and action files

## Key Files

| File | Purpose |
|------|---------|
| `lib/features/forms/di/forms_providers.dart` | Root forms DI wiring |
| `lib/features/forms/di/form_screen_providers.dart` | Screen-local controller scopes |
| `lib/features/forms/data/registries/form_screen_registry.dart` | Form-type to screen mapping |
| `lib/features/forms/presentation/providers/inspector_form_provider.dart` | Form/template/response state |
| `lib/features/forms/presentation/controllers/form_viewer_controller.dart` | Viewer/edit controller |
| `lib/features/forms/presentation/controllers/mdot_hub_controller.dart` | MDOT hub controller |
| `lib/features/forms/presentation/screens/forms_list_screen.dart` | Forms list shell |
| `lib/features/forms/presentation/screens/form_viewer_screen.dart` | Viewer shell |
| `lib/features/forms/presentation/screens/mdot_hub_screen.dart` | MDOT hub shell |

## Integration Points

- entries attach form responses to reports
- projects scope responses
- PDF feature handles the lower-level PDF infrastructure
- sync verification depends on stable forms screen contracts
