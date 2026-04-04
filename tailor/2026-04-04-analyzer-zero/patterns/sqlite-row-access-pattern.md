# Pattern: SQLite Row Access Pattern

## How We Do It
SQLite queries via sqflite return `List<Map<String, Object?>>`. Every column access requires a cast from `Object?` to the target type (`as String`, `as int`), triggering `cast_nullable_to_non_nullable`. This pattern appears in ~120 places across database_service, sync_engine, change_tracker, integrity_checker, schema_verifier, driver_server, and various datasources.

## Exemplars

### PRAGMA table_info access (database_service.dart)
```dart
final columns = await db.rawQuery('PRAGMA table_info($table)');
for (final c in columns) {
  final name = c['name'] as String;     // <-- cast_nullable_to_non_nullable
  final type = c['type'] as String;     // <-- cast_nullable_to_non_nullable
}
```

### Aggregate query (change_tracker.dart)
```dart
final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM change_log WHERE ...');
final count = result.first['cnt'] as int;  // <-- cast_nullable_to_non_nullable
```

### Row iteration (sync_engine.dart)
```dart
final rows = await _db.query('projects', columns: ['id', 'name']);
for (final row in rows) {
  final id = row['id'] as String;       // <-- cast_nullable_to_non_nullable
  final name = row['name'] as String;   // <-- cast_nullable_to_non_nullable
}
```

## Proposed SafeRow Extension

```dart
/// Type-safe accessors for SQLite query result rows.
extension SafeRow on Map<String, Object?> {
  /// Get a non-null String value or throw StateError.
  String requireString(String key) {
    final value = this[key];
    if (value == null) throw StateError('Column "$key" is null');
    return value as String;  // Object -> String (not Object? -> String)
  }

  /// Get a non-null int value or throw StateError.
  int requireInt(String key) {
    final value = this[key];
    if (value == null) throw StateError('Column "$key" is null');
    return value as int;
  }

  /// Get a non-null double value or throw StateError.
  double requireDouble(String key) {
    final value = this[key];
    if (value == null) throw StateError('Column "$key" is null');
    return value as double;
  }

  /// Get a nullable String value.
  String? optionalString(String key) => this[key] as String?;

  /// Get a nullable int value.
  int? optionalInt(String key) => this[key] as int?;

  /// Get an int value with default (common for COUNT queries).
  int intOrDefault(String key, [int defaultValue = 0]) {
    final value = this[key];
    return value != null ? value as int : defaultValue;
  }
}
```

**Why this works**: The null check (`if (value == null) throw ...`) promotes `value` from `Object?` to `Object`. Casting `Object` to `String` is NOT a nullable-to-non-nullable cast, so the lint is eliminated.

## Reusable Methods

| Method | Signature | When to Use |
|--------|-----------|-------------|
| `requireString` | `String requireString(String key)` | Non-null text columns |
| `requireInt` | `int requireInt(String key)` | Non-null integer columns |
| `requireDouble` | `double requireDouble(String key)` | Non-null decimal columns |
| `optionalString` | `String? optionalString(String key)` | Nullable text columns |
| `optionalInt` | `int? optionalInt(String key)` | Nullable integer columns |
| `intOrDefault` | `int intOrDefault(String key, [int defaultValue = 0])` | COUNT/SUM aggregates |

## Imports
```dart
import 'package:construction_inspector/shared/utils/safe_row.dart';
```
