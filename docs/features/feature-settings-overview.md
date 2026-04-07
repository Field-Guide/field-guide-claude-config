---
feature: settings
type: overview
scope: Consent, Legal, Help/Support, Admin, Trash, Theme & Profile Management
updated: 2026-04-07
---

# Settings Feature Overview

## Purpose

The settings feature is the app’s configuration, consent, support, admin, and
soft-delete recovery hub.

## Current UI Structure

- `settings_providers.dart` owns long-lived settings providers
- `settings_screen_providers.dart` owns `SettingsScreen`, `TrashScreen`,
  `PersonnelTypesScreen`, and member-detail controller scopes
- `ThemeProvider` now supports only light and dark modes

## Key Files

| File | Purpose |
|------|---------|
| `lib/features/settings/di/settings_providers.dart` | Root settings DI wiring |
| `lib/features/settings/di/settings_screen_providers.dart` | Screen-local controller scopes |
| `lib/features/settings/presentation/providers/theme_provider.dart` | Theme state |
| `lib/features/settings/presentation/providers/admin_provider.dart` | Admin state |
| `lib/features/settings/presentation/providers/consent_provider.dart` | Consent state |
| `lib/features/settings/presentation/providers/support_provider.dart` | Support state |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Settings shell |
| `lib/features/settings/presentation/screens/trash_screen.dart` | Trash shell |
| `lib/features/settings/presentation/screens/personnel_types_screen.dart` | Personnel types shell |

## Integration Points

- auth supplies identity and sign-out context
- sync supplies pending/sync status display
- trash and personnel type screens are part of the stable verification surface
