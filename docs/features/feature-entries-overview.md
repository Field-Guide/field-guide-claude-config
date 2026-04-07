---
feature: entries
type: overview
scope: Daily Job Site Entry Management
updated: 2026-04-07
---

# Entries Feature Overview

## Purpose

The entries feature owns daily job-site reports, review flows, and the main
calendar/list surfaces used by inspectors.

## Current UI Structure

- `entries_providers.dart` owns long-lived entry providers and use cases
- `entry_screen_providers.dart` owns `HomeScreenController` and `EntriesListController` scopes
- `DailyEntryProvider` is split into calendar and submission action parts
- `ContractorEditingController` now works through `EntryContractorsRepository` and extracted load/save/action files
- `HomeScreen` is a thin shell backed by `HomeScreenController`

## Key Files

| File | Purpose |
|------|---------|
| `lib/features/entries/di/entries_providers.dart` | Root entries DI wiring |
| `lib/features/entries/di/entry_screen_providers.dart` | Screen-local controller scopes |
| `lib/features/entries/presentation/providers/daily_entry_provider.dart` | Entry list and mutation state |
| `lib/features/entries/presentation/controllers/home_screen_controller.dart` | Home screen UI state |
| `lib/features/entries/presentation/controllers/contractor_editing_controller.dart` | Contractor editing state |
| `lib/features/entries/presentation/screens/home_screen.dart` | Calendar shell |
| `lib/features/entries/presentation/screens/entries_list_screen.dart` | Entry list shell |
| `lib/features/entries/presentation/screens/entry_editor_screen.dart` | Entry editor shell |

## Integration Points

- depends on projects, contractors, locations, quantities, photos, weather, and forms
- supplies review and submission surfaces used by sync verification flows
