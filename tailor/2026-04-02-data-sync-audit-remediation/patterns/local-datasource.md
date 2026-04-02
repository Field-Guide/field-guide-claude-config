# Pattern: Local Datasource

## How We Do It
Local datasources extend `GenericLocalDatasource<T>` (which implements `BaseLocalDatasource<T>`) for standard CRUD, or implement `BaseLocalDatasource<T>` directly for custom query patterns. They take `DatabaseService` via constructor injection, never access the singleton directly. Entity-specific queries go on the concrete class.

## Exemplars

### EntryEquipmentLocalDatasource (`lib/features/contractors/data/datasources/local/entry_equipment_local_datasource.dart`)
Standard pattern — extends GenericLocalDatasource, overrides tableName/fromMap/toMap:
```dart
class EntryEquipmentLocalDatasource extends GenericLocalDatasource<EntryEquipment> {
  EntryEquipmentLocalDatasource(this.db);
  @override final DatabaseService db;
  @override String get tableName => 'entry_equipment';
  @override EntryEquipment fromMap(Map<String, dynamic> map) => EntryEquipment.fromMap(map);
  @override Map<String, dynamic> toMap(EntryEquipment item) => item.toMap();
  // + entity-specific methods: getByEntryId, deleteByEntryId, etc.
}
```

### UserCertificationLocalDatasource (`lib/features/settings/data/datasources/local/user_certification_local_datasource.dart`)
Simpler pattern — direct DatabaseService access without GenericLocalDatasource (read-only, no CRUD needed):
```dart
class UserCertificationLocalDatasource {
  final DatabaseService _db;
  UserCertificationLocalDatasource(this._db);
  Future<List<UserCertification>> getByUserId(String userId) async {
    final db = await _db.database;
    final rows = await db.query('user_certifications', where: 'user_id = ?', whereArgs: [userId], orderBy: 'cert_type ASC');
    return rows.map(UserCertification.fromMap).toList();
  }
}
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `GenericLocalDatasource.getById` | `generic_local_datasource.dart:38` | `Future<T?> getById(String id)` | Standard single-record fetch |
| `GenericLocalDatasource.getAll` | `generic_local_datasource.dart:50` | `Future<List<T>> getAll()` | Full table scan |
| `GenericLocalDatasource.upsert` | `generic_local_datasource.dart:90` | `Future<void> upsert(T item)` | Insert or replace |
| `GenericLocalDatasource.delete` | `generic_local_datasource.dart:102` | `Future<void> delete(String id)` | Soft-delete by ID |
| `GenericLocalDatasource.insertAll` | `generic_local_datasource.dart:115` | `Future<void> insertAll(List<T> items)` | Batch insert in transaction |

## Imports
```dart
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/shared/datasources/generic_local_datasource.dart';
// OR for simple cases:
import 'package:construction_inspector/shared/datasources/base_local_datasource.dart';
```
