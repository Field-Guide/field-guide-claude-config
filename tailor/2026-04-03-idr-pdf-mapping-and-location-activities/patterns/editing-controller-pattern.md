# Pattern: Editing Controller

## How We Do It
The `EntryEditingController` encapsulates all `TextEditingController`s and `FocusNode`s for a form, providing `populateFrom(entry)`, `buildEntry(base)`, and `save(provider, entry)` methods. It extends `ChangeNotifier` for reactive state (dirty tracking, editing section).

## Exemplar: EntryEditingController

**File**: `lib/features/entries/presentation/controllers/entry_editing_controller.dart:19-254`

Key aspects:
- 8 private `TextEditingController`s + 8 private `FocusNode`s
- Public getters expose them (never final fields — encapsulated)
- `populateFrom(DailyEntry)` — sets all controller `.text` from model, resets dirty
- `buildEntry(DailyEntry base)` — returns `base.copyWith(...)` using controller values, normalizes empty to null
- `save(provider, base)` — calls `buildEntry`, then `provider.updateEntry`, clears dirty
- `markDirty()` — only notifies on first transition (avoids rebuild per keystroke)
- `copyFieldsFrom(Map)` — copies non-empty fields into empty controllers (for "copy from last entry")
- `isEmptyDraft` — checks all controllers empty
- `dispose()` — disposes all controllers + focus nodes

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `populateFrom` | `entry_editing_controller.dart:108` | `void populateFrom(DailyEntry entry)` | Initialize controllers from model |
| `buildEntry` | `entry_editing_controller.dart:118` | `DailyEntry buildEntry(DailyEntry base)` | Build updated model from controllers |
| `save` | `entry_editing_controller.dart:148` | `Future<void> save(DailyEntryProvider provider, DailyEntry base)` | Persist and clear dirty |
| `markDirty` | `entry_editing_controller.dart:230` | `void markDirty()` | Mark form dirty (idempotent) |
| `copyFieldsFrom` | `entry_editing_controller.dart:170` | `int copyFieldsFrom(Map<String, String?> fields)` | Copy from previous entry |

## Imports
```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/features/entries/data/models/daily_entry.dart';
import 'package:construction_inspector/features/entries/presentation/providers/daily_entry_provider.dart';
```

## Adaptation for Per-Location Activities
The controller needs:
- Replace `_activitiesController` (single) with `Map<String, TextEditingController>` keyed by locationId
- Add `_activeLocationId` state
- Add `switchLocation(String locationId)` method
- Add `getActivitiesJson()` → serializes map to JSON string
- Add `loadActivitiesJson(String?)` → parses JSON or wraps legacy text
- `populateFrom` calls `loadActivitiesJson(entry.activities)`
- `buildEntry` calls `getActivitiesJson()` for the activities field
- `dispose()` must iterate and dispose all map entries
- Keep `_activitiesFocus` as a single FocusNode (shared across locations)
