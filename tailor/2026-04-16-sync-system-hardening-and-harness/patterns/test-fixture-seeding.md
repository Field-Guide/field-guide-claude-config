# Pattern — Test Fixture Seeding (Triggers-Off)

## How the repo does it

Client-side test fixtures seed the local SQLite via `SyncTestData` static factories. To avoid polluting `change_log` with test rows, seed code brackets inserts with `UPDATE sync_control SET value = '1' WHERE key = 'pulling'` before the inserts and `'0'` after. The canonical recipe is `SyncTestData.seedFkGraph(Database)` which seeds a full company → project → location → entry FK chain.

## Exemplar

- `test/helpers/sync/sync_test_data.dart:664–764` — `seedFkGraph(Database db)` pattern.

## Reusable surface

```dart
Future<Map<String, String>> seedMyFixture(Database db) async {
  await db.execute("UPDATE sync_control SET value = '1' WHERE key = 'pulling'");

  final companyId = _uuid.v4();
  final projectId = _uuid.v4();
  // ... build IDs up front so you can return the graph

  await db.insert('companies', {
    'id': companyId,
    'name': 'Test Co',
    'created_at': _ts(),
    'updated_at': _ts(),
  });
  await db.insert('projects', projectMap(id: projectId, companyId: companyId));
  // ... FK-ordered inserts using SyncTestData factories ...

  await db.execute("UPDATE sync_control SET value = '0' WHERE key = 'pulling'");

  return {'companyId': companyId, 'projectId': projectId, /* ... */};
}
```

## Server-side (Supabase seed.sql) seeding

Server-side seed runs after migrations via `supabase db reset`. For the harness fixture (~10–20 users), the seed file must:

1. Insert one company.
2. Insert ~10–20 `auth.users` rows via the admin path. Supabase seed supports this via `auth.users` table inserts **only when the migration has already provisioned the auth schema** — check for the `auth_logs` migration presence.
3. Insert matching `user_profiles` with role distribution.
4. Insert ≥5 `projects` with the company_id.
5. Insert `project_assignments` with the matrix (some inspectors on, some off).
6. Insert FK-connected entries, photos, forms, etc. for realistic action-mix inputs.

Because this runs server-side, trigger suppression is not needed — the triggers in `sync_engine_tables.dart` are **local-only** (SQLite). Server-side tables have their own RLS policies; seed data must be admin-inserted (service role) to bypass RLS during seeding.

## Ownership boundaries

- Never fork the map factories. Extend `SyncTestData` if the harness needs a new shape; do not hand-build row maps that diverge from `fromMap` expectations.
- Tests must not assume a specific `sync_control.pulling` state. Always bracket with explicit `'1'`/`'0'` if you need triggers off.
- Server-side seed runs once per `supabase db reset`. Do not mutate rows outside the seed path in tests — tests get a fresh fixture per run (Phase 1 CI config), not per test.
- FK order in the insert sequence must match `SyncEngineTables.triggeredTables` when triggers are on.

## Imports

```dart
import 'package:construction_inspector/features/sync/engine/sync_engine_tables.dart'; // triggeredTables
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
// relative path to sync_test_data.dart or a new tailored fixture file
```

## Why triggers-off matters

With triggers on, every fixture insert creates a `change_log` row. A soak fixture of 20 users × multi-project × photos would leave tens of thousands of stale `change_log` rows before the first test action runs. The harness would push those rows as "pending changes" when it starts, drowning out the signal it's trying to measure.
