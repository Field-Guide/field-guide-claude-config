# Pattern: Sync Engine Creation

## How We Do It
The SyncEngine is created via static factory methods. Adapters must be registered before use via `registerSyncAdapters()` from `sync_registry.dart`. The engine is not a singleton — a new instance is created per sync cycle. Two creation paths currently exist: foreground (orchestrator) and background (handler).

## Exemplars

### SyncEngine.createForBackgroundSync (`lib/features/sync/engine/sync_engine.dart:177`)
Factory for background contexts:
```dart
static Future<SyncEngine?> createForBackgroundSync({
  required Database database,
  required SupabaseClient supabase,
}) async {
  // ... creates engine, registers adapters, returns ready instance
}
```

### SyncOrchestrator._createEngine (`lib/features/sync/application/sync_orchestrator.dart:195`)
Foreground creation path:
```dart
Future<SyncEngine?> _createEngine() async {
  if (_supabaseClient == null) return null;
  registerSyncAdapters();
  final db = await _dbService.database;
  return SyncEngine(database: db, supabase: _supabaseClient!);
}
```

### backgroundSyncCallback (`lib/features/sync/application/background_sync_handler.dart:20`)
Mobile isolate path — must re-bootstrap everything:
```dart
void backgroundSyncCallback() {
  DatabaseService.initializeFfi();
  final dbService = DatabaseService();
  await Supabase.initialize(...);
  registerSyncAdapters();
  final engine = await SyncEngine.createForBackgroundSync(...);
  await engine.pushAndPull();
}
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `registerSyncAdapters()` | `sync_registry.dart:29` | `void registerSyncAdapters()` | Before any SyncEngine creation |
| `SyncEngine.createForBackgroundSync` | `sync_engine.dart:177` | `static Future<SyncEngine?> create...` | Background/isolate contexts |
| `SyncEngine.pushAndPull` | `sync_engine.dart` | `Future<SyncEngineResult> pushAndPull()` | Execute sync cycle |

## Imports
```dart
import 'package:construction_inspector/features/sync/engine/sync_engine.dart';
import 'package:construction_inspector/features/sync/engine/sync_registry.dart';
```
