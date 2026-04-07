---
feature: entries
type: architecture
scope: Daily Job Site Entry Management
updated: 2026-04-07
---

# Entries Feature Architecture

Entries is still one of the most complex features in the app, but the
presentation layer is now structured around thin screens, screen-local
controllers, and extracted provider/controller actions.

## Directory Shape

```text
lib/features/entries/
├── di/
│   ├── entries_providers.dart
│   └── entry_screen_providers.dart
├── domain/
├── data/
└── presentation/
    ├── providers/
    │   ├── daily_entry_provider.dart
    │   ├── daily_entry_provider_calendar_actions.dart
    │   ├── daily_entry_provider_submission_actions.dart
    │   ├── entry_export_provider.dart
    │   └── calendar_format_provider.dart
    ├── controllers/
    │   ├── home_screen_controller.dart
    │   ├── entries_list_controller.dart
    │   ├── entry_editing_controller.dart
    │   ├── contractor_editing_controller.dart
    │   ├── contractor_editing_controller_data_actions.dart
    │   ├── contractor_editing_loader.dart
    │   ├── contractor_editing_save.dart
    │   ├── photo_attachment_manager.dart
    │   ├── form_attachment_manager.dart
    │   └── pdf_data_builder.dart
    ├── screens/
    │   ├── home_screen.dart
    │   ├── home_screen_actions.dart
    │   └── other entry screens
    └── widgets/
```

## Root DI vs Screen DI

### `di/entries_providers.dart`

Registers long-lived feature providers and repositories:
- `DailyEntryProvider`
- `EntryExportProvider`
- `CalendarFormatProvider`
- entry use cases
- contractor-related repository exposure needed by controllers

### `di/entry_screen_providers.dart`

Registers screen-local controller scopes:
- `HomeScreenControllerScope`
- `EntriesListControllerScope`

These are the composition roots for screen-owned UI state.

## Providers

### DailyEntryProvider

`DailyEntryProvider` is no longer a single god file. Calendar-specific and
submission-specific behavior live in separate part files so entry loading,
calendar state, and submit flows remain bounded.

### EntryExportProvider / CalendarFormatProvider

These stay small and focused. They should not absorb screen-level behavior.

## Controllers

### HomeScreenController

Owns screen-local calendar and expansion state so `HomeScreen` can remain a
thin shell that wires project selection and delegates rendering.

### ContractorEditingController

This controller no longer depends on raw `DatabaseService` access in
`didChangeDependencies`. It now depends on `EntryContractorsRepository` and
keeps load/save/data-mutation behavior split across:
- `contractor_editing_loader.dart`
- `contractor_editing_save.dart`
- `contractor_editing_controller_data_actions.dart`

That change removes one of the major testing and sync-verification pain points
from the old entries stack.

### EntryEditingController

Still owns transient editor state for a single report. It remains the correct
place for in-progress entry editing rather than pushing form state into
`DailyEntryProvider`.

## Screen Shape

`HomeScreen` is now intentionally thin:
- root screen shell
- controller scope wrapper
- project selection gate
- handoff into extracted body/actions/widgets

Large screen actions live outside the shell file so the screen stays within the
UI size ceiling and remains easy to expose to driver flows.

## Cross-Feature Contracts

Entries still coordinate with:
- contractors
- locations
- quantities
- photos
- forms
- PDF export

Because entries and review flows are sync-relevant, the root screen sentinels
for `EntriesListScreen`, `EntryReviewScreen`, and `ReviewSummaryScreen` must
remain aligned with the driver registries and testing keys.

## Key Files

- `lib/features/entries/di/entries_providers.dart`
- `lib/features/entries/di/entry_screen_providers.dart`
- `lib/features/entries/presentation/providers/daily_entry_provider.dart`
- `lib/features/entries/presentation/controllers/home_screen_controller.dart`
- `lib/features/entries/presentation/controllers/entries_list_controller.dart`
- `lib/features/entries/presentation/controllers/contractor_editing_controller.dart`
- `lib/features/entries/presentation/screens/home_screen.dart`
- `lib/features/entries/presentation/screens/entries_list_screen.dart`
- `lib/features/entries/presentation/screens/entry_editor_screen.dart`
