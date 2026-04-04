# Pattern: Tap-to-Edit Section

## How We Do It
Entry editor sections use a tap-to-edit pattern: read-only display by default, inline editing on tap, auto-save on focus loss. The `alwaysEditing` flag bypasses this for create mode where sections start open. Each section is a `StatefulWidget` that takes the `EntryEditingController` and `DailyEntryProvider`.

## Exemplar: EntryActivitiesSection

**File**: `lib/features/entries/presentation/widgets/entry_activities_section.dart:15-144`

Key aspects:
- Constructor: `entry`, `controller`, `entryProvider`, `alwaysEditing`
- State: `_isEditing` bool, computed `_showEditMode`
- `_startEditing()` — copies entry text to controller, sets editing, requests focus
- `_saveAndStopEditing()` — calls `controller.save(entryProvider, entry)`, clears editing
- Build: `Card > InkWell > Column > [header, padding(editField or readText), doneButton]`
- Uses `AppTextField` (design system) with `controller.activitiesController` and `controller.activitiesFocus`
- `Focus.onFocusChange` triggers auto-save when focus leaves
- `onChanged: (_) => widget.controller.markDirty()` for dirty tracking
- Keyed: `TestingKeys.reportActivitiesSection`, `TestingKeys.reportActivitiesField`

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `EntryActivitiesSection` | `entry_activities_section.dart:23` | `const EntryActivitiesSection({entry, controller, entryProvider, alwaysEditing})` | Activities card widget |
| `_startEditing` | `entry_activities_section.dart:38` | `void _startEditing()` | Enter edit mode |
| `_saveAndStopEditing` | `entry_activities_section.dart:48` | `Future<void> _saveAndStopEditing()` | Save and exit edit mode |

## Imports
```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/app_text_field.dart';
import 'package:construction_inspector/features/entries/data/models/daily_entry.dart';
import 'package:construction_inspector/features/entries/presentation/controllers/entry_editing_controller.dart';
import 'package:construction_inspector/features/entries/presentation/providers/daily_entry_provider.dart';
import 'package:construction_inspector/shared/shared.dart';
```
