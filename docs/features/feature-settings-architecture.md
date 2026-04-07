---
feature: settings
type: architecture
scope: User Preferences, Consent, Support, Admin & Legal
updated: 2026-04-07
---

# Settings Feature Architecture

Settings still owns theme, consent, support, admin, trash recovery, and profile
editing, but its screen layer is now explicitly decomposed around controller
scopes and the two-theme design-system model.

## Directory Structure

```text
lib/features/settings/
├── di/
│   ├── settings_providers.dart
│   ├── settings_screen_providers.dart
│   └── consent_support_factory.dart
├── data/
├── domain/
└── presentation/
    ├── providers/
    │   ├── theme_provider.dart
    │   ├── admin_provider.dart
    │   ├── consent_provider.dart
    │   └── support_provider.dart
    ├── controllers/
    │   ├── settings_screen_controller.dart
    │   ├── trash_screen_controller.dart
    │   ├── personnel_types_controller.dart
    │   └── member_detail_controller.dart
    ├── screens/
    └── widgets/
```

## Root DI vs Screen DI

### `di/settings_providers.dart`

Registers long-lived settings state and dependencies:
- `ThemeProvider`
- settings repositories/services needed at app scope

### `di/settings_screen_providers.dart`

Registers screen-local controller scopes:
- `SettingsScreenControllerScope`
- `TrashScreenControllerScope`
- `PersonnelTypesControllerScope`
- `MemberDetailControllerScope`

These scopes keep transient screen state out of the screen widget files.

## Providers

### ThemeProvider

The design-system overhaul removed high-contrast mode. `ThemeProvider` now
supports only:
- `AppThemeMode.light`
- `AppThemeMode.dark`

It also consumes `FieldGuideSpacing` so theme density can follow the responsive
layout system at the app root.

### Consent / Support / Admin

These providers remain long-lived feature services and still belong in root DI.
They should not absorb screen-specific orchestration that belongs in the new
screen controllers.

## Sync / Driver Surface

Settings contains several sync-relevant or verification-relevant screens:
- `TrashScreen`
- `PersonnelTypesScreen`
- `SettingsScreen` sync section

Those screens must keep their root sentinels and driver contracts aligned with
the core driver registries.

## Key Files

- `lib/features/settings/di/settings_providers.dart`
- `lib/features/settings/di/settings_screen_providers.dart`
- `lib/features/settings/presentation/providers/theme_provider.dart`
- `lib/features/settings/presentation/controllers/settings_screen_controller.dart`
- `lib/features/settings/presentation/controllers/trash_screen_controller.dart`
- `lib/features/settings/presentation/controllers/personnel_types_controller.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/settings/presentation/screens/trash_screen.dart`
- `lib/features/settings/presentation/screens/personnel_types_screen.dart`
