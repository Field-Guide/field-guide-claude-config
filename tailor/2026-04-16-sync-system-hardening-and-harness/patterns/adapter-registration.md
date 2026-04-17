# Pattern — Adapter Registration

## How the repo does it

Every synced table has an adapter. Simple adapters live as `AdapterConfig` entries in a single data-driven list; complex adapters are separate classes extending `TableAdapter`. Both are registered once, in strict FK-dependency order, via `registerSyncAdapters()` in `sync_registry.dart`. A CI script (`scripts/validate_sync_adapter_registry.py`) enforces that the three surfaces (trigger list, adapter declarations, registry call) stay in sync.

## Exemplars

- `lib/features/sync/adapters/simple_adapters.dart` — the data-driven `simpleAdapters` list with 17 `AdapterConfig` entries.
- `lib/features/sync/engine/sync_registry.dart:23–61` — `registerSyncAdapters` interleaves simple lookups with complex adapter constructors.
- `lib/features/sync/adapters/daily_entry_adapter.dart` — canonical complex adapter shape (custom `validate()`, `extractRecordName`, `userStampColumns`).

## Reusable surface

```dart
// AdapterConfig signature (from adapter_config.dart)
const AdapterConfig({
  required String table,
  required ScopeType scope,               // direct | viaProject | viaEntry
  List<String> fkDeps = const [],
  Map<String, String> fkColumnMap = const {},
  List<String> naturalKeyColumns = const [],
  Map<String, dynamic> converters = const {},
  List<String> localOnlyColumns = const [],
  List<String> remoteOnlyColumns = const [],
  String? storageBucket,
  String? localFilePathColumn,
  bool isFileAdapter = false,
  bool stripExifGps = true,
  bool skipPush = false,
  bool skipPull = false,
  bool skipIntegrityCheck = false,
  String Function(String companyId, Map<String, dynamic> record)? buildStoragePath,
  String Function(Map<String, dynamic> record)? extractRecordName,
});

// Registry call shape (sync_registry.dart)
targetRegistry.registerAdapters([
  simpleByTable['projects']!,
  simpleByTable['project_assignments']!,
  // ... complex adapters interleaved by FK position ...
  EquipmentAdapter(),
  DailyEntryAdapter(),
  PhotoAdapter(),
  // ...
]);
```

## Ownership boundaries

- The `triggeredTables` list in `sync_engine_tables.dart` is the source of truth for which tables trigger `change_log`. Any new adapter must match.
- `LOCAL_ONLY_REGISTRY_TABLES` in `validate_sync_adapter_registry.py` lists adapters that are registered but not trigger-backed (exports/artifacts).
- Registration order is load-bearing. FK parents come before children. The validator catches order violations.
- Harness fixture seeds must match adapter registration order when using triggers-off seeding (`sync_control.pulling='1'`).

## Imports

```dart
import 'package:construction_inspector/features/sync/adapters/adapter_config.dart';
import 'package:construction_inspector/features/sync/adapters/type_converters.dart';
import 'package:construction_inspector/features/sync/engine/scope_type.dart';
import 'package:construction_inspector/features/sync/engine/delete_graph_registry.dart';
```
