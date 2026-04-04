# Pattern: Model Serialization (copyWith/toMap/fromMap)

## How We Do It
Domain models are plain Dart classes with `final` fields, a named constructor, sentinel-based `copyWith`, `toMap()` returning snake_case keys, and `factory fromMap()` reading the same keys. Nullable fields use `Object? = _sentinel` in copyWith to distinguish "not provided" from "set to null".

## Exemplar: DailyEntry

**File**: `lib/features/entries/data/models/daily_entry.dart`

Key aspects:
- `static const _sentinel = Object()` at class level
- `copyWith` uses `identical(param, _sentinel)` check — not null check
- `toMap()` maps camelCase → snake_case: `locationId` → `'location_id'`
- `fromMap()` factory reads snake_case, casts with `as Type?`
- Enums stored as `.name` string, parsed via `.values.byName()`
- DateTime stored as ISO8601 string
- `getMissingFields()` returns user-facing validation messages

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `DailyEntry.copyWith` | `daily_entry.dart:64` | `DailyEntry copyWith({Object? locationId = _sentinel, ...})` | Immutable updates |
| `DailyEntry.toMap` | `daily_entry.dart:110` | `Map<String, dynamic> toMap()` | Serialize to SQLite/JSON |
| `DailyEntry.fromMap` | `daily_entry.dart:153` | `factory DailyEntry.fromMap(Map<String, dynamic> map)` | Deserialize from SQLite/JSON |
| `DailyEntry.getMissingFields` | `daily_entry.dart:141` | `List<String> getMissingFields()` | Validation for submission |

## Adaptation for locationId Removal
- Remove `locationId` field declaration
- Remove `locationId` from constructor
- Remove `locationId` from `copyWith` parameters and body
- Remove `'location_id'` from `toMap()` output
- Remove `location_id` read from `fromMap()`
- Remove `locationId == null` check from `getMissingFields()`
- Keep `activities` field as-is (same type `String?`, new content format)
