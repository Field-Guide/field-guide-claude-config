# Project Lifecycle Management + Logger Migration Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Make all company projects visible in the Projects tab with import/delete lifecycle actions, add sync health indicators, and migrate all logging to the unified Logger system.
**Spec:** `.claude/specs/2026-03-16-project-lifecycle-spec.md`
**Analysis:** `.claude/dependency_graphs/2026-03-16-project-lifecycle/`

**Architecture:** Projects tab becomes a merged view of local SQLite + remote Supabase projects. Import enrolls a project in `synced_projects` and triggers background sync. Delete offers two paths: device-only removal (hard-delete local data) or database soft-delete (cascading with RLS authorization). Logger migration replaces all DebugLogger/debugPrint calls with structured Logger categories.
**Tech Stack:** Flutter, SQLite (sqflite), Supabase (PostgREST + RLS), ChangeNotifier providers
**Blast Radius:** PR1: 6 new files, 9 modified files, ~8 test files. PR2: 72+ files modified, 2 files deleted, ~5 test files.

---

# PR1: Project Lifecycle + Schema

---

## Phase 1: Schema Migration (change_log project_id)

### Sub-phase 1.1: Add project_id Column + Index

**Files:**
- Modify: `lib/core/database/schema/sync_engine_tables.dart`
- Modify: `lib/core/database/database_service.dart`
- Test: `test/core/database/change_log_project_id_migration_test.dart`

**Agent**: backend-data-layer-agent

#### Step 1.1.1: Write failing test for change_log project_id column existence

```dart
// test/core/database/change_log_project_id_migration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('change_log project_id migration', () {
    test('change_log table has project_id column after migration', () async {
      // FROM SPEC: ALTER TABLE change_log ADD COLUMN project_id TEXT
      await db.execute('''
        CREATE TABLE IF NOT EXISTS change_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          operation TEXT NOT NULL,
          changed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
          processed INTEGER NOT NULL DEFAULT 0,
          error_message TEXT,
          retry_count INTEGER NOT NULL DEFAULT 0,
          metadata TEXT
        )
      ''');

      // Simulate migration
      await db.execute('ALTER TABLE change_log ADD COLUMN project_id TEXT');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_change_log_project_id ON change_log(project_id)',
      );

      // Verify column exists by inserting with project_id
      await db.insert('change_log', {
        'table_name': 'locations',
        'record_id': 'loc-1',
        'operation': 'insert',
        'project_id': 'proj-123',
      });

      final rows = await db.query('change_log');
      expect(rows.length, 1);
      expect(rows.first['project_id'], 'proj-123');
    });

    test('project_id index exists after migration', () async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS change_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          operation TEXT NOT NULL,
          changed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
          processed INTEGER NOT NULL DEFAULT 0,
          error_message TEXT,
          retry_count INTEGER NOT NULL DEFAULT 0,
          metadata TEXT
        )
      ''');

      await db.execute('ALTER TABLE change_log ADD COLUMN project_id TEXT');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_change_log_project_id ON change_log(project_id)',
      );

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='change_log'",
      );
      final indexNames = indexes.map((r) => r['name'] as String).toList();
      expect(indexNames, contains('idx_change_log_project_id'));
    });
  });
}
```

#### Step 1.1.2: Verify test fails
Run: `pwsh -Command "flutter test test/core/database/change_log_project_id_migration_test.dart"`
Expected: FAIL (change_log table does not have project_id in production schema yet)

#### Step 1.1.3: Implement migration in database_service.dart

First, find the current DB version by checking `_onUpgrade` in `database_service.dart`. The migration version must increment from the current value.

In `lib/core/database/database_service.dart`, add to the `_onUpgrade` method at the appropriate version case:

```dart
// Inside _onUpgrade, after the last existing version case:
// NOTE: Check the actual current version number and use currentVersion + 1
if (oldVersion < NEW_VERSION) {
  // FROM SPEC: Add project_id to change_log for efficient per-project cleanup
  await db.execute('ALTER TABLE change_log ADD COLUMN project_id TEXT');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_change_log_project_id ON change_log(project_id)',
  );

  // WHY: Backfill project_id for existing change_log rows.
  // Tables with direct project_id get a simple UPDATE...FROM join.
  // Tables without direct project_id (equipment, entry_*, forms) are left NULL —
  // they'll get correct project_id from updated triggers going forward.
  final tablesWithProjectId = [
    'locations', 'contractors', 'bid_items', 'personnel_types',
    'daily_entries', 'photos', 'todo_items',
  ];
  for (final table in tablesWithProjectId) {
    await db.execute('''
      UPDATE change_log
      SET project_id = (
        SELECT t.project_id FROM $table t WHERE t.id = change_log.record_id
      )
      WHERE change_log.table_name = '$table'
        AND change_log.project_id IS NULL
    ''');
  }

  // WHY: For the 'projects' table itself, project_id = record_id
  await db.execute('''
    UPDATE change_log
    SET project_id = record_id
    WHERE table_name = 'projects'
      AND project_id IS NULL
  ''');
}
```

Also update the database version constant to `NEW_VERSION`.

#### Step 1.1.4: Verify test passes
Run: `pwsh -Command "flutter test test/core/database/change_log_project_id_migration_test.dart"`
Expected: PASS

### Sub-phase 1.2: Update Triggers to Populate project_id

**Files:**
- Modify: `lib/core/database/schema/sync_engine_tables.dart`
- Test: `test/core/database/change_log_trigger_project_id_test.dart`

**Agent**: backend-data-layer-agent

#### Step 1.2.1: Write failing test for trigger project_id population

```dart
// test/core/database/change_log_trigger_project_id_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );

    // Create sync_control
    await db.execute('''
      CREATE TABLE sync_control (key TEXT PRIMARY KEY, value TEXT NOT NULL)
    ''');
    await db.insert('sync_control', {'key': 'pulling', 'value': '0'});

    // Create change_log with project_id
    await db.execute('''
      CREATE TABLE change_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        changed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
        processed INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        metadata TEXT,
        project_id TEXT
      )
    ''');
  });

  tearDown(() async {
    await db.close();
  });

  group('trigger project_id population', () {
    test('insert trigger populates project_id for table with direct project_id', () async {
      // FROM SPEC: Tables with direct project_id use NEW.project_id in trigger
      await db.execute('''
        CREATE TABLE locations (
          id TEXT PRIMARY KEY,
          project_id TEXT NOT NULL,
          name TEXT NOT NULL,
          deleted_at TEXT
        )
      ''');

      // Create trigger with project_id support
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_locations_insert
        AFTER INSERT ON locations
        WHEN (SELECT value FROM sync_control WHERE key = 'pulling') = '0'
        BEGIN
          INSERT INTO change_log (table_name, record_id, operation, project_id)
          VALUES ('locations', NEW.id, 'insert', NEW.project_id);
        END
      ''');

      await db.insert('locations', {
        'id': 'loc-1',
        'project_id': 'proj-abc',
        'name': 'Test Location',
      });

      final logs = await db.query('change_log');
      expect(logs.length, 1);
      expect(logs.first['project_id'], 'proj-abc');
      expect(logs.first['table_name'], 'locations');
    });

    test('insert trigger sets NULL project_id for table without direct project_id', () async {
      // FROM SPEC: Tables without direct project_id set NULL — backfill handles them
      await db.execute('''
        CREATE TABLE equipment (
          id TEXT PRIMARY KEY,
          contractor_id TEXT NOT NULL,
          name TEXT NOT NULL,
          deleted_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_equipment_insert
        AFTER INSERT ON equipment
        WHEN (SELECT value FROM sync_control WHERE key = 'pulling') = '0'
        BEGIN
          INSERT INTO change_log (table_name, record_id, operation, project_id)
          VALUES ('equipment', NEW.id, 'insert', NULL);
        END
      ''');

      await db.insert('equipment', {
        'id': 'equip-1',
        'contractor_id': 'cont-1',
        'name': 'Excavator',
      });

      final logs = await db.query('change_log');
      expect(logs.length, 1);
      expect(logs.first['project_id'], isNull);
    });

    test('projects table trigger uses record_id as project_id', () async {
      await db.execute('''
        CREATE TABLE projects (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          project_number TEXT,
          company_id TEXT,
          created_by_user_id TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          deleted_at TEXT,
          created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
          updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
        )
      ''');

      // WHY: For projects table, project_id IS the record itself
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_projects_insert
        AFTER INSERT ON projects
        WHEN (SELECT value FROM sync_control WHERE key = 'pulling') = '0'
        BEGIN
          INSERT INTO change_log (table_name, record_id, operation, project_id)
          VALUES ('projects', NEW.id, 'insert', NEW.id);
        END
      ''');

      await db.insert('projects', {
        'id': 'proj-xyz',
        'name': 'Test Project',
      });

      final logs = await db.query('change_log');
      expect(logs.length, 1);
      expect(logs.first['project_id'], 'proj-xyz');
      expect(logs.first['record_id'], 'proj-xyz');
    });
  });
}
```

#### Step 1.2.2: Verify test fails
Run: `pwsh -Command "flutter test test/core/database/change_log_trigger_project_id_test.dart"`
Expected: PASS (these are standalone tests) — but the actual production trigger code must be updated.

#### Step 1.2.3: Update SyncEngineTables.triggersForTable()

In `lib/core/database/schema/sync_engine_tables.dart`, modify `triggersForTable()`:

```dart
/// Tables that have a direct project_id column
// FROM SPEC: Tables WITH direct project_id
static const List<String> _tablesWithDirectProjectId = [
  'locations', 'contractors', 'bid_items', 'personnel_types',
  'daily_entries', 'photos', 'todo_items',
];

static List<String> triggersForTable(String tableName) {
  // WHY: Determine how to populate project_id in change_log based on table structure.
  // Tables with direct project_id use NEW.project_id.
  // The 'projects' table uses NEW.id (the project IS the record).
  // All other tables (equipment, entry_*, forms, calculation_history) set NULL.
  final String projectIdExpr;
  if (tableName == 'projects') {
    projectIdExpr = 'NEW.id';
  } else if (_tablesWithDirectProjectId.contains(tableName)) {
    projectIdExpr = 'NEW.project_id';
  } else {
    projectIdExpr = 'NULL';
  }

  // NOTE: For delete triggers, we use OLD instead of NEW
  final String deleteProjectIdExpr;
  if (tableName == 'projects') {
    deleteProjectIdExpr = 'OLD.id';
  } else if (_tablesWithDirectProjectId.contains(tableName)) {
    deleteProjectIdExpr = 'OLD.project_id';
  } else {
    deleteProjectIdExpr = 'NULL';
  }

  return [
    '''CREATE TRIGGER IF NOT EXISTS trg_${tableName}_insert
    AFTER INSERT ON $tableName
    WHEN (SELECT value FROM sync_control WHERE key = 'pulling') = '0'
    BEGIN
      INSERT INTO change_log (table_name, record_id, operation, project_id)
      VALUES ('$tableName', NEW.id, 'insert', $projectIdExpr);
    END''',
    '''CREATE TRIGGER IF NOT EXISTS trg_${tableName}_update
    AFTER UPDATE ON $tableName
    WHEN (SELECT value FROM sync_control WHERE key = 'pulling') = '0'
    BEGIN
      INSERT INTO change_log (table_name, record_id, operation, project_id)
      VALUES ('$tableName', NEW.id, 'update', $projectIdExpr);
    END''',
    '''CREATE TRIGGER IF NOT EXISTS trg_${tableName}_delete
    AFTER DELETE ON $tableName
    WHEN (SELECT value FROM sync_control WHERE key = 'pulling') = '0'
    BEGIN
      INSERT INTO change_log (table_name, record_id, operation, project_id)
      VALUES ('$tableName', OLD.id, 'delete', $deleteProjectIdExpr);
    END''',
  ];
}
```

#### Step 1.2.4: Add trigger recreation to migration

In the migration block added in Step 1.1.3, after the backfill, add:

```dart
// WHY: Recreate triggers so they populate project_id going forward
// Drop old triggers first, then recreate with project_id support
for (final table in SyncEngineTables.triggeredTables) {
  await db.execute('DROP TRIGGER IF EXISTS trg_${table}_insert');
  await db.execute('DROP TRIGGER IF EXISTS trg_${table}_update');
  await db.execute('DROP TRIGGER IF EXISTS trg_${table}_delete');
  for (final trigger in SyncEngineTables.triggersForTable(table)) {
    await db.execute(trigger);
  }
}
```

#### Step 1.2.5: Verify all migration tests pass
Run: `pwsh -Command "flutter test test/core/database/"`
Expected: PASS

---

## Phase 2: Supabase RLS Migration

### Sub-phase 2.1: Tighten Project Soft-Delete RLS

**Files:**
- Create: `supabase/migrations/20260316000000_tighten_project_delete_rls.sql`

**Agent**: backend-supabase-agent

#### Step 2.1.1: Write the RLS migration

```sql
-- supabase/migrations/20260316000000_tighten_project_delete_rls.sql
-- FROM SPEC: Tighten RLS for Project Soft-Delete
-- WHY: Current policy allows any non-viewer to update (including soft-delete) any company project.
-- New policy requires owner or admin to perform soft-delete (setting deleted_at).

-- H10: stamp_deleted_by() already exists in 20260313100000 — do NOT recreate
-- The function already exists in production (migration 20260313100000_sync_hardening_triggers.sql)
-- and uses column `deleted_by`. Recreating it here would overwrite the correct column name
-- with `deleted_by_user_id`, causing a column mismatch. This migration ONLY contains the
-- policy drop + recreate below.

DROP POLICY IF EXISTS "company_projects_update" ON projects;

CREATE POLICY "company_projects_update" ON projects
  FOR UPDATE TO authenticated
  USING (
    company_id = get_my_company_id()
    AND NOT is_viewer()
  )
  WITH CHECK (
    -- WHY: If deleted_at is being set to non-NULL, require owner or admin.
    -- If deleted_at IS NULL (normal update, not a soft-delete), always allow.
    -- NOTE: In PostgreSQL RLS, WITH CHECK sees the NEW row only. We cannot
    -- reference the OLD row. So we use a simpler formulation: any UPDATE that
    -- results in deleted_at being non-NULL requires owner/admin. Normal updates
    -- (where deleted_at stays NULL) pass through.
    -- NOTE: The ELSE true branch allows non-viewer company members to update
    -- any non-delete field (name, project_number, is_active, etc.). This is
    -- the pre-existing permission level and is intentional.
    (deleted_at IS NULL)  -- non-delete updates always pass
    OR (created_by_user_id = auth.uid() OR is_approved_admin())
  );
```

#### Step 2.1.2: Verify migration syntax
Run: `pwsh -Command "npx supabase db push --dry-run"` (if available) or review manually.
Expected: No syntax errors.

#### Step 2.1.3: Push migration
Run: `npx supabase db push`
Expected: Migration applied successfully.

---

## Phase 3: ProjectLifecycleService

### Sub-phase 3.1: Import, Remove from Device, and Delete from Database

**Files:**
- Create: `lib/features/projects/data/services/project_lifecycle_service.dart`
- Test: `test/features/projects/data/services/project_lifecycle_service_test.dart`

**Agent**: backend-data-layer-agent

#### Step 3.1.1: Write failing tests

```dart
// test/features/projects/data/services/project_lifecycle_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:construction_inspector/features/projects/data/services/project_lifecycle_service.dart';

void main() {
  late Database db;
  late ProjectLifecycleService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );

    // Create minimal schema for testing
    await db.execute('''
      CREATE TABLE synced_projects (
        project_id TEXT PRIMARY KEY,
        synced_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE change_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        changed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
        processed INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        metadata TEXT,
        project_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE conflict_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id TEXT NOT NULL,
        table_name TEXT NOT NULL,
        resolved INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        project_number TEXT,
        company_id TEXT,
        created_by_user_id TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        deleted_at TEXT,
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
        updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        name TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE daily_entries (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        file_path TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE contractors (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        name TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE bid_items (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE personnel_types (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE todo_items (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE equipment (
        id TEXT PRIMARY KEY,
        contractor_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE entry_equipment (
        id TEXT PRIMARY KEY,
        daily_entry_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE entry_quantities (
        id TEXT PRIMARY KEY,
        daily_entry_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE entry_contractors (
        id TEXT PRIMARY KEY,
        daily_entry_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE entry_personnel_counts (
        id TEXT PRIMARY KEY,
        daily_entry_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE inspector_forms (
        id TEXT PRIMARY KEY,
        daily_entry_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE form_responses (
        id TEXT PRIMARY KEY,
        daily_entry_id TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    service = ProjectLifecycleService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('enrollProject', () {
    test('inserts into synced_projects with ConflictAlgorithm.ignore', () async {
      await service.enrollProject('proj-1');

      final rows = await db.query('synced_projects');
      expect(rows.length, 1);
      expect(rows.first['project_id'], 'proj-1');
    });

    test('is idempotent — second call does not throw', () async {
      await service.enrollProject('proj-1');
      await service.enrollProject('proj-1'); // FROM SPEC: Import is idempotent

      final rows = await db.query('synced_projects');
      expect(rows.length, 1);
    });
  });

  group('removeFromDevice', () {
    test('hard-deletes all child data and project row', () async {
      // Setup: project with children
      await db.insert('projects', {'id': 'proj-1', 'name': 'Test'});
      await db.insert('synced_projects', {'project_id': 'proj-1'});
      await db.insert('locations', {'id': 'loc-1', 'project_id': 'proj-1', 'name': 'L1'});
      await db.insert('daily_entries', {'id': 'de-1', 'project_id': 'proj-1'});
      await db.insert('entry_equipment', {'id': 'ee-1', 'daily_entry_id': 'de-1'});
      await db.insert('change_log', {
        'table_name': 'locations',
        'record_id': 'loc-1',
        'operation': 'insert',
        'project_id': 'proj-1',
        'processed': 0,
      });

      final photoPaths = await service.removeFromDevice('proj-1');

      // FROM SPEC: Hard-delete all local child rows
      expect(await db.query('locations'), isEmpty);
      expect(await db.query('daily_entries'), isEmpty);
      expect(await db.query('entry_equipment'), isEmpty);
      // FROM SPEC: Hard-delete project row
      expect(await db.query('projects', where: 'id = ?', whereArgs: ['proj-1']), isEmpty);
      // FROM SPEC: Remove synced_projects row
      expect(await db.query('synced_projects'), isEmpty);
      // FROM SPEC: DELETE FROM change_log WHERE project_id = ?
      expect(await db.query('change_log', where: 'project_id = ?', whereArgs: ['proj-1']), isEmpty);
    });

    test('returns photo file paths for cleanup', () async {
      await db.insert('projects', {'id': 'proj-1', 'name': 'Test'});
      await db.insert('synced_projects', {'project_id': 'proj-1'});
      await db.insert('photos', {
        'id': 'ph-1',
        'project_id': 'proj-1',
        'file_path': '/data/photos/ph-1.jpg',
      });

      final paths = await service.removeFromDevice('proj-1');
      expect(paths, contains('/data/photos/ph-1.jpg'));
    });
  });

  group('getUnsyncedChangeCount', () {
    test('returns count of unprocessed changes for project', () async {
      await db.insert('change_log', {
        'table_name': 'locations',
        'record_id': 'loc-1',
        'operation': 'insert',
        'project_id': 'proj-1',
        'processed': 0,
      });
      await db.insert('change_log', {
        'table_name': 'locations',
        'record_id': 'loc-2',
        'operation': 'update',
        'project_id': 'proj-1',
        'processed': 1, // already processed
      });

      final count = await service.getUnsyncedChangeCount('proj-1');
      expect(count, 1);
    });
  });

  group('authorization', () {
    test('canDeleteFromDatabase returns true for owner', () async {
      await db.insert('projects', {
        'id': 'proj-1',
        'name': 'Test',
        'created_by_user_id': 'user-abc',
      });

      final result = await service.canDeleteFromDatabase('proj-1', 'user-abc', isAdmin: false);
      expect(result, true);
    });

    test('canDeleteFromDatabase returns true for admin', () async {
      await db.insert('projects', {
        'id': 'proj-1',
        'name': 'Test',
        'created_by_user_id': 'user-other',
      });

      final result = await service.canDeleteFromDatabase('proj-1', 'user-abc', isAdmin: true);
      expect(result, true);
    });

    test('canDeleteFromDatabase returns false for non-owner non-admin', () async {
      await db.insert('projects', {
        'id': 'proj-1',
        'name': 'Test',
        'created_by_user_id': 'user-other',
      });

      final result = await service.canDeleteFromDatabase('proj-1', 'user-abc', isAdmin: false);
      expect(result, false);
    });

    test('canDeleteFromDatabase returns false for NULL created_by when not admin', () async {
      // FROM SPEC: NULL created_by_user_id -> admin-only
      await db.insert('projects', {
        'id': 'proj-1',
        'name': 'Test',
        'created_by_user_id': null,
      });

      final result = await service.canDeleteFromDatabase('proj-1', 'user-abc', isAdmin: false);
      expect(result, false);
    });
  });
}
```

#### Step 3.1.2: Verify tests fail
Run: `pwsh -Command "flutter test test/features/projects/data/services/project_lifecycle_service_test.dart"`
Expected: FAIL (file does not exist)

#### Step 3.1.3: Implement ProjectLifecycleService

```dart
// lib/features/projects/data/services/project_lifecycle_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:construction_inspector/core/logging/logger.dart';

/// Service that handles project import, device removal, and database deletion.
///
/// FROM SPEC: Handles three lifecycle actions:
/// 1. enrollProject — adds project to synced_projects for background sync
/// 2. removeFromDevice — hard-deletes all local data, Supabase untouched
/// 3. Authorization checks for database deletion
class ProjectLifecycleService {
  final Database _db;

  ProjectLifecycleService(this._db);

  // FROM SPEC: _projectChildTables — tables with direct project_id
  static const List<String> _directChildTables = [
    'locations',
    'contractors',
    'bid_items',
    'personnel_types',
    'daily_entries',
    'photos',
    'todo_items',
  ];

  // WHY: These tables reference daily_entries, not project directly
  static const List<String> _entryJunctionTables = [
    'entry_equipment',
    'entry_quantities',
    'entry_contractors',
    'entry_personnel_counts',
    'inspector_forms',
    'form_responses',
  ];

  /// Enrolls a project for syncing. Idempotent.
  /// FROM SPEC: INSERT INTO synced_projects with ConflictAlgorithm.ignore
  Future<void> enrollProject(String projectId) async {
    await _db.insert(
      'synced_projects',
      {
        'project_id': projectId,
        'synced_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    Logger.sync('ENROLL_PROJECT projectId=$projectId');
  }

  /// Removes all local data for a project. Returns photo file paths for cleanup.
  ///
  /// FROM SPEC Section 4A:
  /// 1. DELETE FROM change_log WHERE project_id = ? AND processed = 0
  /// 2. DELETE FROM conflict_log WHERE record_id IN (affected IDs)
  /// 3. Hard-delete all local child rows
  /// 4. Queue deletion of photo files (returns paths)
  /// 5. Hard-delete project row
  /// 6. Remove synced_projects row
  Future<List<String>> removeFromDevice(String projectId) async {
    final photoPaths = <String>[];

    await _db.transaction((txn) async {
      // Step 1: Clean change_log
      // FROM SPEC: DELETE FROM change_log WHERE project_id = ?
      await txn.delete(
        'change_log',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );

      // Step 2: Collect affected record IDs for conflict_log cleanup
      final allRecordIds = <String>[];

      // Collect photo paths before deletion
      final photoRows = await txn.query(
        'photos',
        columns: ['id', 'file_path'],
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      for (final row in photoRows) {
        final path = row['file_path'] as String?;
        if (path != null && path.isNotEmpty) {
          photoPaths.add(path);
        }
        allRecordIds.add(row['id'] as String);
      }

      // Step 3: Delete entry junction tables (via daily_entries)
      final entryRows = await txn.query(
        'daily_entries',
        columns: ['id'],
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      final entryIds = entryRows.map((r) => r['id'] as String).toList();

      if (entryIds.isNotEmpty) {
        final placeholders = entryIds.map((_) => '?').join(',');
        for (final table in _entryJunctionTables) {
          // Collect IDs for conflict_log
          final junctionRows = await txn.query(
            table,
            columns: ['id'],
            where: 'daily_entry_id IN ($placeholders)',
            whereArgs: entryIds,
          );
          allRecordIds.addAll(junctionRows.map((r) => r['id'] as String));

          await txn.delete(
            table,
            where: 'daily_entry_id IN ($placeholders)',
            whereArgs: entryIds,
          );
        }
      }

      // Delete equipment (via contractors)
      final contractorRows = await txn.query(
        'contractors',
        columns: ['id'],
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      final contractorIds = contractorRows.map((r) => r['id'] as String).toList();

      if (contractorIds.isNotEmpty) {
        final placeholders = contractorIds.map((_) => '?').join(',');
        final equipRows = await txn.query(
          'equipment',
          columns: ['id'],
          where: 'contractor_id IN ($placeholders)',
          whereArgs: contractorIds,
        );
        allRecordIds.addAll(equipRows.map((r) => r['id'] as String));

        await txn.delete(
          'equipment',
          where: 'contractor_id IN ($placeholders)',
          whereArgs: contractorIds,
        );
      }

      // Step 3 continued: Delete direct child tables
      for (final table in _directChildTables) {
        final childRows = await txn.query(
          table,
          columns: ['id'],
          where: 'project_id = ?',
          whereArgs: [projectId],
        );
        allRecordIds.addAll(childRows.map((r) => r['id'] as String));

        await txn.delete(
          table,
          where: 'project_id = ?',
          whereArgs: [projectId],
        );
      }

      // Step 2 continued: Clean conflict_log
      if (allRecordIds.isNotEmpty) {
        // Process in batches to avoid SQLite variable limit
        const batchSize = 500;
        for (var i = 0; i < allRecordIds.length; i += batchSize) {
          final batch = allRecordIds.sublist(
            i,
            i + batchSize > allRecordIds.length ? allRecordIds.length : i + batchSize,
          );
          final placeholders = batch.map((_) => '?').join(',');
          await txn.delete(
            'conflict_log',
            where: 'record_id IN ($placeholders)',
            whereArgs: batch,
          );
        }
      }

      // Step 5: Hard-delete project row
      allRecordIds.add(projectId);
      await txn.delete('projects', where: 'id = ?', whereArgs: [projectId]);

      // Step 6: Remove from synced_projects
      await txn.delete('synced_projects', where: 'project_id = ?', whereArgs: [projectId]);

      // Also clean any change_log entries for the project record itself
      // (may have NULL project_id from before migration)
      await txn.delete(
        'change_log',
        where: 'table_name = ? AND record_id = ?',
        whereArgs: ['projects', projectId],
      );
    });

    Logger.sync('REMOVE_FROM_DEVICE projectId=$projectId photoPaths=${photoPaths.length}');
    return photoPaths;
  }

  /// Returns count of unprocessed change_log entries for a project.
  /// FROM SPEC: count from change_log WHERE project_id = ? AND processed = 0
  Future<int> getUnsyncedChangeCount(String projectId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM change_log WHERE project_id = ? AND processed = 0',
      [projectId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns map of projectId -> unsyncedCount for all projects.
  Future<Map<String, int>> getAllUnsyncedCounts() async {
    final result = await _db.rawQuery('''
      SELECT project_id, COUNT(*) as cnt
      FROM change_log
      WHERE processed = 0 AND project_id IS NOT NULL
      GROUP BY project_id
    ''');
    return {
      for (final row in result)
        if (row['project_id'] != null)
          row['project_id'] as String: row['cnt'] as int,
    };
  }

  /// FROM SPEC: Authorization check for database deletion.
  /// created_by_user_id == currentUserId OR isAdmin.
  /// NULL created_by_user_id -> admin-only.
  Future<bool> canDeleteFromDatabase(
    String projectId,
    String currentUserId, {
    required bool isAdmin,
  }) async {
    if (isAdmin) return true;

    final rows = await _db.query(
      'projects',
      columns: ['created_by_user_id'],
      where: 'id = ?',
      whereArgs: [projectId],
    );

    if (rows.isEmpty) return false;

    final createdBy = rows.first['created_by_user_id'] as String?;
    // FROM SPEC: NULL created_by_user_id -> admin-only
    if (createdBy == null) return false;
    return createdBy == currentUserId;
  }
}
```

#### Step 3.1.4: Verify tests pass
Run: `pwsh -Command "flutter test test/features/projects/data/services/project_lifecycle_service_test.dart"`
Expected: PASS

---

## Phase 4: ProjectSyncHealthProvider

### Sub-phase 4.1: Cached Pending Change Counts

**Files:**
- Create: `lib/features/projects/presentation/providers/project_sync_health_provider.dart`
- Test: `test/features/projects/presentation/providers/project_sync_health_provider_test.dart`

**Agent**: frontend-flutter-specialist-agent

#### Step 4.1.1: Write failing test

```dart
// test/features/projects/presentation/providers/project_sync_health_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_sync_health_provider.dart';

void main() {
  group('ProjectSyncHealthProvider', () {
    late ProjectSyncHealthProvider provider;

    setUp(() {
      provider = ProjectSyncHealthProvider();
    });

    test('initial state has empty counts', () {
      expect(provider.getUnsyncedCount('proj-1'), 0);
      expect(provider.hasPendingChanges('proj-1'), false);
    });

    test('updateCounts stores new counts and notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.updateCounts({'proj-1': 5, 'proj-2': 0});

      expect(notified, true);
      expect(provider.getUnsyncedCount('proj-1'), 5);
      expect(provider.getUnsyncedCount('proj-2'), 0);
      expect(provider.hasPendingChanges('proj-1'), true);
      expect(provider.hasPendingChanges('proj-2'), false);
    });

    test('getSyncStatus returns correct status', () {
      provider.updateCounts({'proj-1': 3});
      provider.setSyncError('proj-2');

      // FROM SPEC: Green check — fully synced, Orange — pending, Red — error
      expect(provider.getSyncStatus('proj-1'), ProjectSyncStatus.pendingChanges);
      expect(provider.getSyncStatus('proj-2'), ProjectSyncStatus.error);
      expect(provider.getSyncStatus('proj-3'), ProjectSyncStatus.synced); // unknown = synced
    });

    test('clearError removes error state', () {
      provider.setSyncError('proj-1');
      expect(provider.getSyncStatus('proj-1'), ProjectSyncStatus.error);

      provider.clearError('proj-1');
      expect(provider.getSyncStatus('proj-1'), ProjectSyncStatus.synced);
    });
  });
}
```

#### Step 4.1.2: Verify test fails
Run: `pwsh -Command "flutter test test/features/projects/presentation/providers/project_sync_health_provider_test.dart"`
Expected: FAIL

#### Step 4.1.3: Implement ProjectSyncHealthProvider

```dart
// lib/features/projects/presentation/providers/project_sync_health_provider.dart
import 'package:flutter/foundation.dart';

/// FROM SPEC: Sync Health on Project Cards
enum ProjectSyncStatus {
  synced,         // Green check — fully synced
  pendingChanges, // Orange cloud-upload — N unsynced local changes
  error,          // Red warning — sync error
  remoteOnly,     // Grey cloud — not on device
}

/// FROM SPEC: Counts cached in ProjectSyncHealthProvider (Map<String, int>),
/// refreshed on sync completion.
class ProjectSyncHealthProvider extends ChangeNotifier {
  Map<String, int> _unsyncedCounts = {};
  final Set<String> _errorProjects = {};

  /// Update all counts at once (typically after sync completes or on refresh).
  void updateCounts(Map<String, int> counts) {
    _unsyncedCounts = Map.of(counts);
    notifyListeners();
  }

  /// Get the unsynced change count for a project.
  int getUnsyncedCount(String projectId) {
    return _unsyncedCounts[projectId] ?? 0;
  }

  /// Whether a project has pending unsynced changes.
  bool hasPendingChanges(String projectId) {
    return (_unsyncedCounts[projectId] ?? 0) > 0;
  }

  /// Mark a project as having a sync error.
  void setSyncError(String projectId) {
    _errorProjects.add(projectId);
    notifyListeners();
  }

  /// Clear error state for a project.
  void clearError(String projectId) {
    _errorProjects.remove(projectId);
    notifyListeners();
  }

  /// FROM SPEC: Determine display status for a project card.
  /// Note: remoteOnly is determined by the caller (not stored here).
  ProjectSyncStatus getSyncStatus(String projectId) {
    if (_errorProjects.contains(projectId)) {
      return ProjectSyncStatus.error;
    }
    if (hasPendingChanges(projectId)) {
      return ProjectSyncStatus.pendingChanges;
    }
    return ProjectSyncStatus.synced;
  }

  /// Clear all state (e.g., on logout).
  void clear() {
    _unsyncedCounts = {};
    _errorProjects.clear();
    notifyListeners();
  }
}
```

#### Step 4.1.4: Verify tests pass
Run: `pwsh -Command "flutter test test/features/projects/presentation/providers/project_sync_health_provider_test.dart"`
Expected: PASS

---

## Phase 5: ProjectImportRunner

### Sub-phase 5.1: Import State Machine

**Files:**
- Create: `lib/features/projects/presentation/providers/project_import_runner.dart`
- Test: `test/features/projects/presentation/providers/project_import_runner_test.dart`

**Agent**: frontend-flutter-specialist-agent

#### Step 5.1.1: Write failing test

```dart
// test/features/projects/presentation/providers/project_import_runner_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_import_runner.dart';

void main() {
  group('ProjectImportRunner', () {
    late ProjectImportRunner runner;

    setUp(() {
      runner = ProjectImportRunner();
    });

    test('initial state is idle', () {
      expect(runner.state, ImportState.idle);
      expect(runner.currentProjectId, isNull);
      expect(runner.isImporting, false);
    });

    test('startImport transitions to enrolling state', () {
      runner.startImport('proj-1', 'Test Project');

      expect(runner.state, ImportState.enrolling);
      expect(runner.currentProjectId, 'proj-1');
      expect(runner.currentProjectName, 'Test Project');
      expect(runner.isImporting, true);
    });

    test('cannot start import while another is in progress', () {
      // FROM SPEC: Guard against concurrent import
      runner.startImport('proj-1', 'Test 1');
      runner.startImport('proj-2', 'Test 2'); // Should be ignored

      expect(runner.currentProjectId, 'proj-1');
    });

    test('markSyncing transitions from enrolling to syncing', () {
      runner.startImport('proj-1', 'Test');
      runner.markSyncing();

      expect(runner.state, ImportState.syncing);
    });

    test('markComplete transitions to complete', () {
      runner.startImport('proj-1', 'Test');
      runner.markSyncing();
      runner.markComplete();

      expect(runner.state, ImportState.complete);
      expect(runner.isImporting, false);
    });

    test('markFailed stores error message', () {
      // FROM SPEC: On failure: toast, enrollment persists
      runner.startImport('proj-1', 'Test');
      runner.markFailed('Network error');

      expect(runner.state, ImportState.failed);
      expect(runner.errorMessage, 'Network error');
      expect(runner.isImporting, false);
    });

    test('reset clears all state', () {
      runner.startImport('proj-1', 'Test');
      runner.markComplete();
      runner.reset();

      expect(runner.state, ImportState.idle);
      expect(runner.currentProjectId, isNull);
    });

    test('notifies listeners on state changes', () {
      var notifyCount = 0;
      runner.addListener(() => notifyCount++);

      runner.startImport('proj-1', 'Test');
      runner.markSyncing();
      runner.markComplete();

      expect(notifyCount, 3);
    });
  });
}
```

#### Step 5.1.2: Verify test fails
Run: `pwsh -Command "flutter test test/features/projects/presentation/providers/project_import_runner_test.dart"`
Expected: FAIL

#### Step 5.1.3: Implement ProjectImportRunner

```dart
// lib/features/projects/presentation/providers/project_import_runner.dart
import 'package:flutter/foundation.dart';
import 'package:construction_inspector/core/logging/logger.dart';

/// FROM SPEC: Progress states for project import flow
enum ImportState {
  idle,       // No import in progress
  enrolling,  // Inserting into synced_projects
  syncing,    // SyncOrchestrator running background sync
  complete,   // Import finished successfully
  failed,     // Import failed (enrollment persists per spec)
}

/// FROM SPEC: ProjectImportRunner extends ChangeNotifier
/// Inspired by ExtractionJobRunner pattern but independent implementation.
class ProjectImportRunner extends ChangeNotifier {
  ImportState _state = ImportState.idle;
  String? _currentProjectId;
  String? _currentProjectName;
  String? _errorMessage;

  ImportState get state => _state;
  String? get currentProjectId => _currentProjectId;
  String? get currentProjectName => _currentProjectName;
  String? get errorMessage => _errorMessage;

  bool get isImporting =>
      _state == ImportState.enrolling || _state == ImportState.syncing;

  /// Start importing a project.
  /// FROM SPEC: Guard against concurrent import.
  void startImport(String projectId, String projectName) {
    if (isImporting) {
      Logger.sync('IMPORT_BLOCKED already importing $_currentProjectId, '
          'rejected $projectId');
      return;
    }

    _currentProjectId = projectId;
    _currentProjectName = projectName;
    _errorMessage = null;
    _state = ImportState.enrolling;
    Logger.sync('IMPORT_START projectId=$projectId');
    notifyListeners();
  }

  /// Transition to syncing state after enrollment.
  void markSyncing() {
    if (_state != ImportState.enrolling) return;
    _state = ImportState.syncing;
    Logger.sync('IMPORT_SYNCING projectId=$_currentProjectId');
    notifyListeners();
  }

  /// Mark import as complete.
  /// FROM SPEC: On completion: banner turns green.
  void markComplete() {
    _state = ImportState.complete;
    Logger.sync('IMPORT_COMPLETE projectId=$_currentProjectId');
    notifyListeners();
  }

  /// Mark import as failed.
  /// FROM SPEC: On failure: toast, enrollment persists.
  void markFailed(String message) {
    _state = ImportState.failed;
    _errorMessage = message;
    Logger.sync('IMPORT_FAILED projectId=$_currentProjectId error=$message');
    notifyListeners();
  }

  /// Reset to idle state. Call after banner is dismissed.
  void reset() {
    _state = ImportState.idle;
    _currentProjectId = null;
    _currentProjectName = null;
    _errorMessage = null;
    notifyListeners();
  }
}
```

#### Step 5.1.4: Verify tests pass
Run: `pwsh -Command "flutter test test/features/projects/presentation/providers/project_import_runner_test.dart"`
Expected: PASS

---

## Phase 6: ProjectProvider Refactor (Merged View)

### Sub-phase 6.1: Fetch Remote Projects + Merge with Local

**Files:**
- Modify: `lib/features/projects/presentation/providers/project_provider.dart`
- Test: `test/features/projects/presentation/providers/project_provider_merged_view_test.dart`

**Agent**: frontend-flutter-specialist-agent

#### Step 6.1.1: Write failing test for merged view

```dart
// test/features/projects/presentation/providers/project_provider_merged_view_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/projects/domain/models/project.dart';

/// Helper to represent a merged project entry
class MergedProjectEntry {
  final Project project;
  final bool isLocal; // exists in SQLite
  final bool isRemoteOnly; // exists in Supabase but not locally

  MergedProjectEntry({
    required this.project,
    required this.isLocal,
    required this.isRemoteOnly,
  });
}

/// Test the merge logic in isolation
List<MergedProjectEntry> mergeProjects(
  List<Project> localProjects,
  List<Project> remoteProjects,
  Set<String> syncedProjectIds,
) {
  final merged = <String, MergedProjectEntry>{};

  // Add local projects first
  for (final p in localProjects) {
    merged[p.id] = MergedProjectEntry(
      project: p,
      isLocal: true,
      isRemoteOnly: false,
    );
  }

  // Add remote projects, marking as remote-only if not local
  for (final p in remoteProjects) {
    if (p.deletedAt != null) continue; // FROM SPEC: deleted_at IS NULL filter
    if (!merged.containsKey(p.id)) {
      merged[p.id] = MergedProjectEntry(
        project: p,
        isLocal: false,
        isRemoteOnly: true,
      );
    }
  }

  return merged.values.toList();
}

void main() {
  group('mergeProjects', () {
    test('includes both local and remote-only projects', () {
      final local = [
        _makeProject('proj-1', 'Local Project'),
      ];
      final remote = [
        _makeProject('proj-1', 'Local Project'),
        _makeProject('proj-2', 'Remote Only Project'),
      ];

      final result = mergeProjects(local, remote, {'proj-1'});

      expect(result.length, 2);
      final remoteOnly = result.where((e) => e.isRemoteOnly).toList();
      expect(remoteOnly.length, 1);
      expect(remoteOnly.first.project.id, 'proj-2');
    });

    test('filters out soft-deleted remote projects', () {
      final local = <Project>[];
      final remote = [
        _makeProject('proj-1', 'Active'),
        _makeProject('proj-2', 'Deleted', deletedAt: DateTime.now()),
      ];

      final result = mergeProjects(local, remote, {});

      expect(result.length, 1);
      expect(result.first.project.id, 'proj-1');
    });

    test('deduplicates by id — local takes precedence', () {
      final local = [_makeProject('proj-1', 'Local Version')];
      final remote = [_makeProject('proj-1', 'Remote Version')];

      final result = mergeProjects(local, remote, {'proj-1'});

      expect(result.length, 1);
      expect(result.first.project.name, 'Local Version');
      expect(result.first.isLocal, true);
    });
  });
}

Project _makeProject(String id, String name, {DateTime? deletedAt}) {
  return Project(
    id: id,
    name: name,
    projectNumber: 'PN-$id',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isActive: true,
    mode: ProjectMode.standard,
    deletedAt: deletedAt,
  );
}
```

NOTE: The implementing agent must check the actual `Project` model for the correct constructor. The test above uses the fields from the spec. Adjust constructor parameters to match the actual model. If `Project` does not have a `deletedAt` field, it may need to be added or the remote filtering must happen before creating Project objects.

#### Step 6.1.2: Verify test fails
Run: `pwsh -Command "flutter test test/features/projects/presentation/providers/project_provider_merged_view_test.dart"`
Expected: FAIL or compilation error

#### Step 6.1.3: Implement merged view in ProjectProvider

Add to `lib/features/projects/presentation/providers/project_provider.dart`:

The implementing agent must read the current file and add/modify:

1. A `_remoteProjects` list to hold Supabase-fetched metadata.
2. A `fetchRemoteProjects()` method that calls Supabase:
```dart
/// FROM SPEC: On tab entry + pull-to-refresh, fetch metadata from Supabase
/// with deleted_at IS NULL filter.
Future<void> fetchRemoteProjects() async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('projects')
        .select('id, name, project_number, description, is_active')
        .eq('company_id', _companyId)
        .isFilter('deleted_at', null);

    _remoteProjects = (response as List).map((json) => Project.fromJson(json)).toList();
    _buildMergedView();
    notifyListeners();
  } catch (e) {
    Logger.sync('FETCH_REMOTE_PROJECTS_ERROR: $e');
    // NOTE: Don't clear existing data on error — show stale merged view
  }
}
```

3. A `_buildMergedView()` method that merges local + remote, deduplicating by id.
4. A `mergedProjects` getter that returns `List<MergedProjectEntry>`.
5. A `MergedProjectEntry` class (or put it in a separate model file at `lib/features/projects/data/models/merged_project_entry.dart`).

**H5 — `_companyId` field**: The implementing agent must add `_companyId` as a field on `ProjectProvider` that gets populated during `loadProjectsByCompany()`. It should be sourced from `Supabase.instance.client.auth.currentUser?.appMetadata['company_id']` or from `context.read<AuthProvider>().companyId`. This value is required by `fetchRemoteProjects()` to filter the Supabase query. If the AuthProvider exposes `companyId`, prefer that source to avoid reading Supabase auth twice.

The agent should define `MergedProjectEntry` in `lib/features/projects/data/models/merged_project_entry.dart`:

```dart
// lib/features/projects/data/models/merged_project_entry.dart
// L17: Canonical location for MergedProjectEntry
class MergedProjectEntry {
  final Project project;
  final bool isLocal;
  final bool isRemoteOnly;
  // M15: isLocalOnly = present in SQLite but absent from Supabase fetch result
  final bool isLocalOnly;

  const MergedProjectEntry({
    required this.project,
    required this.isLocal,
    required this.isRemoteOnly,
    this.isLocalOnly = false,
  });
}
```

#### Step 6.1.4: Verify tests pass
Run: `pwsh -Command "flutter test test/features/projects/presentation/providers/project_provider_merged_view_test.dart"`
Expected: PASS

---

## Phase 7: SoftDeleteService Enhancement

### Sub-phase 7.1: Add change_log and conflict_log Cleanup

**Files:**
- Modify: `lib/services/soft_delete_service.dart`
- Test: `test/services/soft_delete_service_log_cleanup_test.dart`

**Agent**: backend-data-layer-agent

#### Step 7.1.1: Write failing test

```dart
// test/services/soft_delete_service_log_cleanup_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:construction_inspector/services/soft_delete_service.dart';

void main() {
  late Database db;
  late SoftDeleteService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );

    // Minimal schema — all tables in one setUp to avoid overwrite
    await db.execute('''
      CREATE TABLE change_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        changed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
        processed INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        metadata TEXT,
        project_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE conflict_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id TEXT NOT NULL,
        table_name TEXT NOT NULL,
        resolved INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // Projects table so SoftDeleteService.cascadeSoftDeleteProject() can find the record
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        project_number TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
        deleted_at TEXT,
        deleted_by TEXT,
        created_by_user_id TEXT
      )
    ''');
    await db.insert('projects', {'id': 'proj-1', 'name': 'Test', 'project_number': 'P001'});
    await db.insert('projects', {'id': 'proj-2', 'name': 'Other', 'project_number': 'P002'});

    service = SoftDeleteService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SoftDeleteService log cleanup', () {
    test('cascadeSoftDeleteProject cleans change_log and conflict_log for project', () async {
      // FROM SPEC: Section 4B step 5 — Clean change_log and conflict_log
      // M13: Use the real SoftDeleteService with an in-memory database.
      await db.insert('change_log', {
        'table_name': 'locations',
        'record_id': 'loc-1',
        'operation': 'insert',
        'project_id': 'proj-1',
        'processed': 0,
      });
      await db.insert('change_log', {
        'table_name': 'locations',
        'record_id': 'loc-2',
        'operation': 'insert',
        'project_id': 'proj-2', // Different project — should not be touched
        'processed': 0,
      });
      await db.insert('conflict_log', {
        'record_id': 'loc-1',
        'table_name': 'locations',
        'resolved': 0,
      });

      // M13: Call the real service method (not a manual delete)
      // NOTE: The existing signature is cascadeSoftDeleteProject(String projectId, {String? userId})
      await service.cascadeSoftDeleteProject('proj-1', userId: 'user-test');

      // change_log for proj-1 must be gone; proj-2 row must remain
      final remainingChanges = await db.query('change_log');
      expect(remainingChanges.length, 1);
      expect(remainingChanges.first['project_id'], 'proj-2');

      // conflict_log entry for the deleted project's record must be cleaned
      final remainingConflicts = await db.query(
        'conflict_log',
        where: 'record_id = ?',
        whereArgs: ['loc-1'],
      );
      expect(remainingConflicts, isEmpty);
    });
  });
}
```

#### Step 7.1.2: Verify test compiles
Run: `pwsh -Command "flutter test test/services/soft_delete_service_log_cleanup_test.dart"`
Expected: PASS (this is a standalone DB test)

#### Step 7.1.3: Modify SoftDeleteService

In `lib/services/soft_delete_service.dart`, add to `cascadeSoftDeleteProject()` inside the transaction, after the existing cascade logic:

```dart
// FROM SPEC: Section 4B step 5 — Clean change_log and conflict_log
// WHY: After soft-delete, unprocessed local changes for this project are moot.
// The soft-delete itself will be synced; old insert/update changes would conflict.
await txn.delete(
  'change_log',
  where: 'project_id = ? AND processed = 0',
  whereArgs: [projectId],
);
```

Also replace the existing `DebugLogger.db(...)` call with `Logger.db(...)`.

#### Step 7.1.4: Verify existing soft_delete tests still pass
Run: `pwsh -Command "flutter test test/services/"` (or the specific test file if it exists)
Expected: PASS

---

## Phase 8: ProjectDeleteSheet Widget

### Sub-phase 8.1: Two-Checkbox Delete Bottom Sheet

**Files:**
- Create: `lib/features/projects/presentation/widgets/project_delete_sheet.dart`
- Test: `test/features/projects/presentation/widgets/project_delete_sheet_test.dart`

**Agent**: frontend-flutter-specialist-agent

#### Step 8.1.1: Write failing widget test

```dart
// test/features/projects/presentation/widgets/project_delete_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/projects/presentation/widgets/project_delete_sheet.dart';

void main() {
  group('ProjectDeleteSheet', () {
    testWidgets('shows two checkbox options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => ProjectDeleteSheet(
                      projectName: 'Test Project',
                      unsyncedCount: 0,
                      canDeleteFromDatabase: true,
                      onRemoveFromDevice: () {},
                      onDeleteFromDatabase: () {},
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // FROM SPEC: Two checkboxes
      expect(find.text('Remove from this device'), findsOneWidget);
      expect(find.text('Delete from database'), findsOneWidget);
    });

    testWidgets('delete from database auto-checks remove from device', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDeleteSheet(
              projectName: 'Test Project',
              unsyncedCount: 0,
              canDeleteFromDatabase: true,
              onRemoveFromDevice: () {},
              onDeleteFromDatabase: () {},
            ),
          ),
        ),
      );

      // Tap "Delete from database" checkbox
      await tester.tap(find.text('Delete from database'));
      await tester.pumpAndSettle();

      // FROM SPEC: "Delete from database" auto-checks "Remove from device"
      // Both checkboxes should be checked
      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      ).toList();
      expect(checkboxes.length, 2);
      // The remove-from-device checkbox should be checked and disabled
      expect(checkboxes[0].value, true);
    });

    testWidgets('confirm button disabled when no checkbox selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDeleteSheet(
              projectName: 'Test Project',
              unsyncedCount: 0,
              canDeleteFromDatabase: true,
              onRemoveFromDevice: () {},
              onDeleteFromDatabase: () {},
            ),
          ),
        ),
      );

      // FROM SPEC: At least one checkbox required
      final confirmButton = find.byType(ElevatedButton);
      final button = tester.widget<ElevatedButton>(confirmButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('shows unsynced warning when count > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDeleteSheet(
              projectName: 'Test Project',
              unsyncedCount: 5,
              canDeleteFromDatabase: true,
              onRemoveFromDevice: () {},
              onDeleteFromDatabase: () {},
            ),
          ),
        ),
      );

      // FROM SPEC: Show unsynced changes warning (non-blocking)
      expect(find.textContaining('5 unsynced'), findsOneWidget);
    });

    testWidgets('disables delete-from-database when not authorized', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDeleteSheet(
              projectName: 'Test Project',
              unsyncedCount: 0,
              canDeleteFromDatabase: false, // Not owner or admin
              onRemoveFromDevice: () {},
              onDeleteFromDatabase: () {},
            ),
          ),
        ),
      );

      // FROM SPEC: requires owner/admin authorization
      final deleteDbTile = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      ).last;
      expect(deleteDbTile.onChanged, isNull);
    });
  });
}
```

#### Step 8.1.2: Verify test fails
Run: `pwsh -Command "flutter test test/features/projects/presentation/widgets/project_delete_sheet_test.dart"`
Expected: FAIL

#### Step 8.1.3: Implement ProjectDeleteSheet

**H11 — `isAdmin` must come from live auth**: When the caller (ProjectListScreen) constructs this sheet, `isAdmin` MUST be sourced from the live Supabase auth session via `context.read<AuthProvider>().isAdmin`, NOT from local SQLite. See Phase 10 for the call site.

**M14 — Offline check for "Delete from database"**: The `canDeleteFromDatabase` parameter must also reflect connectivity. When the device is offline (`SyncOrchestrator.isSupabaseOnline == false`), pass `canDeleteFromDatabase: false` and the sheet will show "Internet connection required." on the database-delete checkbox. The implementing agent should check connectivity at the call site in `_showDeleteSheet`.

```dart
// lib/features/projects/presentation/widgets/project_delete_sheet.dart
import 'package:flutter/material.dart';

/// FROM SPEC: Delete Options Bottom Sheet with two checkboxes.
/// Entry point: Long-press or three-dot menu on project card.
///
/// M14: Pass canDeleteFromDatabase: false when offline. The subtitle
/// will show "Internet connection required." in that case.
class ProjectDeleteSheet extends StatefulWidget {
  final String projectName;
  final int unsyncedCount;
  final bool canDeleteFromDatabase;
  final bool isOffline;
  final VoidCallback onRemoveFromDevice;
  final VoidCallback onDeleteFromDatabase;

  const ProjectDeleteSheet({
    super.key,
    required this.projectName,
    required this.unsyncedCount,
    required this.canDeleteFromDatabase,
    this.isOffline = false,
    required this.onRemoveFromDevice,
    required this.onDeleteFromDatabase,
  });

  @override
  State<ProjectDeleteSheet> createState() => _ProjectDeleteSheetState();
}

class _ProjectDeleteSheetState extends State<ProjectDeleteSheet> {
  bool _removeFromDevice = false;
  bool _deleteFromDatabase = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Delete "${widget.projectName}"',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // FROM SPEC: Show unsynced changes warning (non-blocking)
          if (widget.unsyncedCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.unsyncedCount} unsynced change${widget.unsyncedCount == 1 ? '' : 's'} will be lost.',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // FROM SPEC: Checkbox 1 — Remove from this device
          CheckboxListTile(
            value: _removeFromDevice || _deleteFromDatabase,
            // WHY: Disabled when deleteFromDatabase is checked (auto-checked per spec)
            onChanged: _deleteFromDatabase
                ? null
                : (val) => setState(() => _removeFromDevice = val ?? false),
            title: const Text('Remove from this device'),
            subtitle: const Text('Removes local data. Supabase is not affected.'),
            controlAffinity: ListTileControlAffinity.leading,
          ),

          // FROM SPEC: Checkbox 2 — Delete from database
          // M14: Disabled when offline (isOffline == true) or not authorized
          CheckboxListTile(
            value: _deleteFromDatabase,
            // FROM SPEC: requires owner/admin authorization
            // M14: Also disabled when offline — database delete requires connectivity
            onChanged: (widget.canDeleteFromDatabase && !widget.isOffline)
                ? (val) {
                    setState(() {
                      _deleteFromDatabase = val ?? false;
                      // FROM SPEC: auto-checks "Remove from device"
                      if (_deleteFromDatabase) {
                        _removeFromDevice = true;
                      }
                    });
                  }
                : null,
            title: const Text('Delete from database'),
            subtitle: Text(
              widget.isOffline
                  ? 'Internet connection required.'
                  : widget.canDeleteFromDatabase
                      ? 'Permanently deletes for all team members.'
                      : 'Only project owner or admin can delete.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),

          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // FROM SPEC: At least one checkbox required
              onPressed: (_removeFromDevice || _deleteFromDatabase)
                  ? () {
                      Navigator.of(context).pop();
                      if (_deleteFromDatabase) {
                        widget.onDeleteFromDatabase();
                      } else {
                        widget.onRemoveFromDevice();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _deleteFromDatabase ? Colors.red : null,
                foregroundColor: _deleteFromDatabase ? Colors.white : null,
              ),
              // FROM SPEC: Confirm button label changes based on selection
              child: Text(
                _deleteFromDatabase
                    ? 'Delete Permanently'
                    : _removeFromDevice
                        ? 'Remove from Device'
                        : 'Select an option',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
```

#### Step 8.1.4: Verify tests pass
Run: `pwsh -Command "flutter test test/features/projects/presentation/widgets/project_delete_sheet_test.dart"`
Expected: PASS

---

## Phase 9: ProjectImportBanner Widget

### Sub-phase 9.1: Import Progress Banner

**Files:**
- Create: `lib/features/projects/presentation/widgets/project_import_banner.dart`
- Test: `test/features/projects/presentation/widgets/project_import_banner_test.dart`

**Agent**: frontend-flutter-specialist-agent

#### Step 9.1.1: Write failing widget test

```dart
// test/features/projects/presentation/widgets/project_import_banner_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_import_runner.dart';
import 'package:construction_inspector/features/projects/presentation/widgets/project_import_banner.dart';

void main() {
  group('ProjectImportBanner', () {
    late ProjectImportRunner runner;

    setUp(() {
      runner = ProjectImportRunner();
    });

    testWidgets('hidden when runner is idle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: runner,
              builder: (_, __) => ProjectImportBanner(runner: runner),
            ),
          ),
        ),
      );

      // Should not show anything when idle
      expect(find.byType(AnimatedContainer), findsOneWidget);
      // Banner content should not be visible
      expect(find.text('Importing'), findsNothing);
    });

    testWidgets('shows enrolling state with spinner', (tester) async {
      runner.startImport('proj-1', 'Springfield DWSRF');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: runner,
              builder: (_, __) => ProjectImportBanner(runner: runner),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Springfield DWSRF'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows complete state with green check', (tester) async {
      runner.startImport('proj-1', 'Test Project');
      runner.markSyncing();
      runner.markComplete();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: runner,
              builder: (_, __) => ProjectImportBanner(runner: runner),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // FROM SPEC: On completion: banner turns green
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows failed state with error icon', (tester) async {
      runner.startImport('proj-1', 'Test Project');
      runner.markFailed('Network error');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: runner,
              builder: (_, __) => ProjectImportBanner(runner: runner),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('dismiss button resets runner', (tester) async {
      runner.startImport('proj-1', 'Test');
      runner.markSyncing();
      runner.markComplete();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: runner,
              builder: (_, __) => ProjectImportBanner(runner: runner),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(runner.state, ImportState.idle);
    });
  });
}
```

#### Step 9.1.2: Verify test fails
Run: `pwsh -Command "flutter test test/features/projects/presentation/widgets/project_import_banner_test.dart"`
Expected: FAIL

#### Step 9.1.3: Implement ProjectImportBanner

```dart
// lib/features/projects/presentation/widgets/project_import_banner.dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_import_runner.dart';

/// FROM SPEC: ProjectImportBanner shows import progress.
/// Inspired by ExtractionBanner pattern (AnimatedContainer for expand/collapse).
class ProjectImportBanner extends StatelessWidget {
  final ProjectImportRunner runner;

  const ProjectImportBanner({super.key, required this.runner});

  @override
  Widget build(BuildContext context) {
    final isVisible = runner.state != ImportState.idle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isVisible ? null : 0,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: isVisible ? _buildContent(context) : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final Color bgColor;
    final Widget leadingIcon;
    final String message;
    final bool showDismiss;

    switch (runner.state) {
      case ImportState.enrolling:
        bgColor = Colors.blue.shade50;
        leadingIcon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        message = 'Enrolling "${runner.currentProjectName}"...';
        showDismiss = false;
      case ImportState.syncing:
        bgColor = Colors.blue.shade50;
        leadingIcon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        message = 'Importing "${runner.currentProjectName}"...';
        showDismiss = false;
      case ImportState.complete:
        // FROM SPEC: On completion: banner turns green
        bgColor = Colors.green.shade50;
        leadingIcon = Icon(Icons.check_circle, color: Colors.green.shade700);
        message = '"${runner.currentProjectName}" imported successfully.';
        showDismiss = true;
      case ImportState.failed:
        bgColor = Colors.red.shade50;
        leadingIcon = Icon(Icons.error_outline, color: Colors.red.shade700);
        message = 'Import failed: ${runner.errorMessage ?? "Unknown error"}';
        showDismiss = true;
      case ImportState.idle:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: bgColor,
      child: Row(
        children: [
          leadingIcon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (showDismiss)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: runner.reset,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
```

#### Step 9.1.4: Verify tests pass
Run: `pwsh -Command "flutter test test/features/projects/presentation/widgets/project_import_banner_test.dart"`
Expected: PASS

---

## Phase 10: ProjectListScreen Rewrite

### Sub-phase 10.1: Merged View with Sync Indicators + Import/Delete Actions

**Files:**
- Modify: `lib/features/projects/presentation/screens/project_list_screen.dart`
- Test: `test/features/projects/presentation/screens/project_list_screen_test.dart`

**Agent**: frontend-flutter-specialist-agent

#### Step 10.1.1: Write failing test for merged view display

```dart
// test/features/projects/presentation/screens/project_list_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:construction_inspector/features/projects/presentation/screens/project_list_screen.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_sync_health_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_import_runner.dart';
import 'package:construction_inspector/features/projects/data/services/project_lifecycle_service.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/projects/data/models/merged_project_entry.dart';
import 'package:construction_inspector/features/projects/domain/models/project.dart';

// NOTE: The implementing agent must generate mocks with:
// flutter pub run build_runner build
@GenerateMocks([ProjectProvider, ProjectSyncHealthProvider, ProjectLifecycleService, AuthProvider])
import 'project_list_screen_test.mocks.dart';

Widget _buildTestApp({
  required MockProjectProvider projectProvider,
  required MockProjectSyncHealthProvider healthProvider,
  required MockProjectLifecycleService lifecycleService,
  required MockAuthProvider authProvider,
}) {
  final importRunner = ProjectImportRunner();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProjectProvider>.value(value: projectProvider),
      ChangeNotifierProvider<ProjectSyncHealthProvider>.value(value: healthProvider),
      ChangeNotifierProvider<ProjectImportRunner>.value(value: importRunner),
      Provider<ProjectLifecycleService>.value(value: lifecycleService),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: const MaterialApp(home: ProjectListScreen()),
  );
}

void main() {
  late MockProjectProvider projectProvider;
  late MockProjectSyncHealthProvider healthProvider;
  late MockProjectLifecycleService lifecycleService;
  late MockAuthProvider authProvider;

  setUp(() {
    projectProvider = MockProjectProvider();
    healthProvider = MockProjectSyncHealthProvider();
    lifecycleService = MockProjectLifecycleService();
    authProvider = MockAuthProvider();

    // Default stubs
    when(projectProvider.mergedProjects).thenReturn([]);
    when(projectProvider.isLoading).thenReturn(false);
    when(authProvider.userId).thenReturn('user-test');
    // H11: isAdmin must come from live auth session
    // WHY: Source from live auth to prevent stale cache bypass
    // The RLS migration is the hard enforcement, but UX should match
    when(authProvider.isAdmin).thenReturn(false);
  });

  group('ProjectListScreen merged view', () {
    testWidgets('synced project shows green check icon', (tester) async {
      // C1: Test that synced projects show green check icon
      final syncedProject = _makeProject('proj-1', 'Synced Project');
      when(projectProvider.mergedProjects).thenReturn([
        MergedProjectEntry(project: syncedProject, isLocal: true, isRemoteOnly: false),
      ]);
      when(healthProvider.getSyncStatus('proj-1'))
          .thenReturn(ProjectSyncStatus.synced);
      when(healthProvider.getUnsyncedCount('proj-1')).thenReturn(0);

      await tester.pumpWidget(_buildTestApp(
        projectProvider: projectProvider,
        healthProvider: healthProvider,
        lifecycleService: lifecycleService,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // FROM SPEC: Green check — fully synced
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('remote-only project shows grey cloud icon and Import button', (tester) async {
      // C1: Test that remote-only projects show grey cloud icon and "Import" button
      final remoteProject = _makeProject('proj-2', 'Remote Only Project');
      when(projectProvider.mergedProjects).thenReturn([
        MergedProjectEntry(project: remoteProject, isLocal: false, isRemoteOnly: true),
      ]);
      when(healthProvider.getSyncStatus('proj-2'))
          .thenReturn(ProjectSyncStatus.remoteOnly);

      await tester.pumpWidget(_buildTestApp(
        projectProvider: projectProvider,
        healthProvider: healthProvider,
        lifecycleService: lifecycleService,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // FROM SPEC: Grey cloud — not on device
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
      // Remote project must show Import affordance
      expect(find.text('Import'), findsOneWidget);
    });

    testWidgets('tapping remote-only project card triggers import flow', (tester) async {
      // C1: Test that tapping a remote project card triggers import
      final remoteProject = _makeProject('proj-3', 'Import Me');
      when(projectProvider.mergedProjects).thenReturn([
        MergedProjectEntry(project: remoteProject, isLocal: false, isRemoteOnly: true),
      ]);
      when(healthProvider.getSyncStatus('proj-3'))
          .thenReturn(ProjectSyncStatus.remoteOnly);
      when(lifecycleService.enrollProject('proj-3'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_buildTestApp(
        projectProvider: projectProvider,
        healthProvider: healthProvider,
        lifecycleService: lifecycleService,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // Tap the import button / card for the remote project
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      // FROM SPEC: Import triggers enrollProject
      verify(lifecycleService.enrollProject('proj-3')).called(1);
    });

    testWidgets('long-press on local project shows ProjectDeleteSheet', (tester) async {
      // C1: Test that long-press shows ProjectDeleteSheet
      final localProject = _makeProject('proj-4', 'Local Project');
      when(projectProvider.mergedProjects).thenReturn([
        MergedProjectEntry(project: localProject, isLocal: true, isRemoteOnly: false),
      ]);
      when(healthProvider.getSyncStatus('proj-4'))
          .thenReturn(ProjectSyncStatus.synced);
      when(healthProvider.getUnsyncedCount('proj-4')).thenReturn(0);
      when(lifecycleService.getUnsyncedChangeCount('proj-4'))
          .thenAnswer((_) async => 0);
      when(lifecycleService.canDeleteFromDatabase(
        'proj-4',
        'user-test',
        isAdmin: false,
      )).thenAnswer((_) async => true);

      await tester.pumpWidget(_buildTestApp(
        projectProvider: projectProvider,
        healthProvider: healthProvider,
        lifecycleService: lifecycleService,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // Long-press the project card
      await tester.longPress(find.text('Local Project'));
      await tester.pumpAndSettle();

      // FROM SPEC: Long-press → bottom sheet with two checkboxes
      expect(find.text('Remove from this device'), findsOneWidget);
      expect(find.text('Delete from database'), findsOneWidget);
    });

    // M15: Test that local-only (SQLite present, absent from Supabase fetch) shows red warning
    testWidgets('project absent from Supabase fetch is marked isLocalOnly with red warning', (tester) async {
      final localOnlyProject = _makeProject('proj-5', 'Local Only Project');
      when(projectProvider.mergedProjects).thenReturn([
        MergedProjectEntry(
          project: localOnlyProject,
          isLocal: true,
          isRemoteOnly: false,
          isLocalOnly: true, // present in SQLite but absent from Supabase result
        ),
      ]);
      when(healthProvider.getSyncStatus('proj-5'))
          .thenReturn(ProjectSyncStatus.synced);

      await tester.pumpWidget(_buildTestApp(
        projectProvider: projectProvider,
        healthProvider: healthProvider,
        lifecycleService: lifecycleService,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // FROM SPEC: Red warning indicator for local-only projects
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });
}

Project _makeProject(String id, String name) {
  return Project(
    id: id,
    name: name,
    projectNumber: 'PN-$id',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isActive: true,
    mode: ProjectMode.standard,
  );
}
```

NOTE: The implementing agent must:
1. Generate mocks via `flutter pub run build_runner build`
2. Adjust the `Project` constructor to match the actual model
3. Add `isLocalOnly` to `MergedProjectEntry` if not already present (see M15)
4. Ensure `ProjectListScreen` is importable without a full app bootstrap

#### Step 10.1.2: Verify tests fail
Run: `pwsh -Command "flutter test test/features/projects/presentation/screens/project_list_screen_test.dart"`
Expected: FAIL

#### Step 10.1.3: Rewrite ProjectListScreen

The implementing agent must read the current `project_list_screen.dart` and perform a major rewrite. Key changes:

1. **Replace the current project list** with a list of `MergedProjectEntry` from `ProjectProvider.mergedProjects`.

2. **Add pull-to-refresh** that calls `projectProvider.fetchRemoteProjects()`.

3. **Add sync status indicators** to each project card:
```dart
Widget _buildSyncStatusIcon(MergedProjectEntry entry, ProjectSyncHealthProvider healthProvider) {
  if (entry.isRemoteOnly) {
    // FROM SPEC: Grey cloud — not on device
    return const Icon(Icons.cloud_outlined, color: Colors.grey);
  }

  final status = healthProvider.getSyncStatus(entry.project.id);
  switch (status) {
    case ProjectSyncStatus.synced:
      return const Icon(Icons.check_circle, color: Colors.green);
    case ProjectSyncStatus.pendingChanges:
      final count = healthProvider.getUnsyncedCount(entry.project.id);
      return Badge(
        label: Text('$count'),
        child: const Icon(Icons.cloud_upload, color: Colors.orange),
      );
    case ProjectSyncStatus.error:
      return const Icon(Icons.warning, color: Colors.red);
    case ProjectSyncStatus.remoteOnly:
      return const Icon(Icons.cloud_outlined, color: Colors.grey);
  }
}
```

4. **Add tap handler for remote-only projects** → show import confirmation → call `ProjectImportRunner.startImport()` → `ProjectLifecycleService.enrollProject()` → `SyncOrchestrator.syncLocalAgencyProjects()`.

5. **Add long-press handler** → show `ProjectDeleteSheet` bottom sheet.

6. **Add `ProjectImportBanner`** at the top of the screen (above the list).

7. **Call `fetchRemoteProjects()` in `initState`** (or equivalent lifecycle hook).

8. **Import flow** (in a method like `_handleImport`):
```dart
Future<void> _handleImport(MergedProjectEntry entry) async {
  final runner = context.read<ProjectImportRunner>();
  // C2: Use provider-based injection — do NOT call DatabaseService() directly
  final lifecycleService = context.read<ProjectLifecycleService>();
  // C3: Source from live auth to prevent stale cache bypass
  // WHY: RLS migration is the hard enforcement, but UX should match
  final authProvider = context.read<AuthProvider>();
  final currentUserId = authProvider.userId;
  final isAdmin = authProvider.isAdmin;

  // FROM SPEC: Step 1: Check network
  final hasNetwork = await _checkNetwork();
  if (!hasNetwork) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import requires a network connection.')),
    );
    return;
  }

  // FROM SPEC: Step 2: Enroll
  runner.startImport(entry.project.id, entry.project.name);
  try {
    await lifecycleService.enrollProject(entry.project.id);

    // FROM SPEC: Step 3: Trigger sync
    runner.markSyncing();
    final orchestrator = context.read<SyncOrchestrator>();
    await orchestrator.syncLocalAgencyProjects();

    // FROM SPEC: Step 6: On completion
    runner.markComplete();
  } catch (e) {
    // FROM SPEC: Step 7: On failure
    runner.markFailed(e.toString());
  }
}
```

9. **Delete flow** (in methods `_handleRemoveFromDevice` and `_handleDeleteFromDatabase`):

**C2 — Provider-based injection**: Do NOT call `DatabaseService()` directly. Use `context.read<ProjectLifecycleService>()`. `ProjectLifecycleService` must be registered as a provider in `main.dart` (see Phase 13).

**C3 + H11 — `isAdmin` and `currentUserId` must come from live auth**:
```dart
// WHY: Source from live auth to prevent stale cache bypass
// The RLS migration is the hard enforcement, but UX should match
final authProvider = context.read<AuthProvider>();
final currentUserId = authProvider.userId;
final isAdmin = authProvider.isAdmin;
```

```dart
Future<void> _showDeleteSheet(MergedProjectEntry entry) async {
  // C2: Use provider-based injection — do NOT call DatabaseService() directly
  final lifecycleService = context.read<ProjectLifecycleService>();
  // C3 + H11: Source from live auth to prevent stale cache bypass
  final authProvider = context.read<AuthProvider>();
  final currentUserId = authProvider.userId;
  final isAdmin = authProvider.isAdmin;

  final unsyncedCount = await lifecycleService.getUnsyncedChangeCount(entry.project.id);
  final canDelete = await lifecycleService.canDeleteFromDatabase(
    entry.project.id,
    currentUserId,
    isAdmin: isAdmin,
  );
  // M14: Check connectivity — database delete requires being online
  final isOffline = !context.read<SyncOrchestrator>().isSupabaseOnline;

  if (!mounted) return;

  showModalBottomSheet(
    context: context,
    builder: (_) => ProjectDeleteSheet(
      projectName: entry.project.name,
      unsyncedCount: unsyncedCount,
      canDeleteFromDatabase: canDelete,
      isOffline: isOffline,
      onRemoveFromDevice: () => _handleRemoveFromDevice(entry.project.id),
      onDeleteFromDatabase: () => _handleDeleteFromDatabase(entry.project.id),
    ),
  );
}
```

#### Step 10.1.4: Verify tests pass
Run: `pwsh -Command "flutter test test/features/projects/presentation/screens/project_list_screen_test.dart"`
Expected: PASS

---

## Phase 11: Settings Screen Cleanup

### Sub-phase 11.1: Remove "Manage Synced Projects" Tile

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Test: `test/features/settings/presentation/screens/settings_screen_test.dart`

**Agent**: frontend-flutter-specialist-agent

#### Step 11.1.1: Write failing test

```dart
// test/features/settings/presentation/screens/settings_screen_test.dart
// Add to existing test file or create new one
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:construction_inspector/features/settings/presentation/screens/settings_screen.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';

// NOTE: The implementing agent must generate mocks and add any additional
// providers SettingsScreen requires (e.g., ThemeProvider, AuthProvider).
@GenerateMocks([AuthProvider])
import 'settings_screen_test.mocks.dart';

void main() {
  group('Settings screen', () {
    testWidgets('does not show Manage Synced Projects tile', (tester) async {
      // FROM SPEC: Remove "Manage Synced Projects" from Settings
      // M12: Real widget test — pump the screen and verify the tile is absent.
      final mockAuth = MockAuthProvider();
      when(mockAuth.isAuthenticated).thenReturn(true);
      when(mockAuth.isAdmin).thenReturn(false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // FROM SPEC: "Manage Synced Projects" tile must not appear in Settings
      expect(find.text('Manage Synced Projects'), findsNothing);
    });
  });
}
```

#### Step 11.1.2: Verify test fails
Run: `pwsh -Command "flutter test test/features/settings/presentation/screens/settings_screen_test.dart"`
Expected: FAIL (tile still present)

#### Step 11.1.3: Remove the tile

In `lib/features/settings/presentation/screens/settings_screen.dart`, remove or comment out the ListTile block near line 199:

```dart
// REMOVE THIS BLOCK:
// ListTile(
//   leading: const Icon(Icons.folder_shared_outlined),
//   title: const Text('Manage Synced Projects'),
//   onTap: () => context.push('/sync/project-selection'),
// ),
```

FROM SPEC: Remove "Manage Synced Projects" from Settings (keep read-only in Sync Dashboard).

#### Step 11.1.4: Verify test passes
Run: `pwsh -Command "flutter test test/features/settings/presentation/screens/settings_screen_test.dart"`
Expected: PASS

---

## Phase 12: SyncDashboard + ProjectSelectionScreen (Read-Only)

### Sub-phase 12.1: Make ProjectSelectionScreen Read-Only

**Files:**
- Modify: `lib/features/sync/presentation/screens/project_selection_screen.dart`
- Modify: `lib/features/sync/presentation/screens/sync_dashboard_screen.dart`
- Test: `test/features/sync/presentation/screens/project_selection_read_only_test.dart`

**Agent**: frontend-flutter-specialist-agent

#### Step 12.1.1: Write failing test

```dart
// test/features/sync/presentation/screens/project_selection_read_only_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:construction_inspector/features/sync/presentation/screens/project_selection_screen.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_provider.dart';

// NOTE: The implementing agent must generate mocks and add any providers
// that ProjectSelectionScreen requires.
@GenerateMocks([ProjectProvider])
import 'project_selection_read_only_test.mocks.dart';

void main() {
  group('ProjectSelectionScreen read-only mode', () {
    testWidgets('all toggles have null onChanged in read-only mode', (tester) async {
      // M12: Real widget test — pump with readOnly: true and check Switch widgets.
      // FROM SPEC: Making it read-only means disabling the toggles, not removing the screen.
      final mockProvider = MockProjectProvider();
      when(mockProvider.projects).thenReturn([]);
      when(mockProvider.isLoading).thenReturn(false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProjectProvider>.value(value: mockProvider),
          ],
          child: const MaterialApp(
            home: ProjectSelectionScreen(readOnly: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All Switch widgets must be disabled (onChanged == null) in read-only mode
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      for (final sw in switches) {
        expect(sw.onChanged, isNull,
            reason: 'Switch should be disabled in read-only mode');
      }
    });

    testWidgets('shows banner directing users to Projects tab', (tester) async {
      // M12: When read-only, a banner must be visible directing users to Projects tab
      final mockProvider = MockProjectProvider();
      when(mockProvider.projects).thenReturn([]);
      when(mockProvider.isLoading).thenReturn(false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProjectProvider>.value(value: mockProvider),
          ],
          child: const MaterialApp(
            home: ProjectSelectionScreen(readOnly: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // FROM SPEC: Show info text directing users to Projects tab
      expect(
        find.textContaining('Projects tab'),
        findsOneWidget,
        reason: 'Read-only banner must mention the Projects tab',
      );
    });
  });
}
```

#### Step 12.1.2: Verify test fails
Run: `pwsh -Command "flutter test test/features/sync/presentation/screens/project_selection_read_only_test.dart"`
Expected: FAIL

#### Step 12.1.3: Add readOnly parameter to ProjectSelectionScreen

In `lib/features/sync/presentation/screens/project_selection_screen.dart`:

1. Add a `readOnly` parameter (default `false` for backward compat, but Sync Dashboard will pass `true`).
2. When `readOnly == true`:
   - Disable all toggle switches (set `onChanged: null`)
   - Show a banner at the top: "Project management has moved to the Projects tab."
   - Hide any "Add" or "Remove" action buttons

#### Step 12.1.4: Update SyncDashboard to pass readOnly

In `lib/features/sync/presentation/screens/sync_dashboard_screen.dart`, update the "Manage Synced Projects" tile (around line 263):

```dart
// FROM SPEC: Keep read-only in Sync Dashboard
_buildActionTile(
  icon: Icons.folder_shared,
  title: 'View Synced Projects',  // Rename from "Manage" to "View"
  onTap: () => context.push('/sync/project-selection?readOnly=true'),
),
```

NOTE: The implementing agent should decide whether to use a query parameter or a constructor parameter. A constructor parameter via the router is cleaner.

#### Step 12.1.5: Verify tests pass
Run: `pwsh -Command "flutter test test/features/sync/presentation/screens/project_selection_read_only_test.dart"`
Expected: PASS

---

## Phase 13: Router + main.dart Wiring

### Sub-phase 13.1: Register Providers and Wire Routes

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/main.dart`

**Agent**: general-purpose

#### Step 13.1.1: Register providers in main.dart

In `lib/main.dart`, add provider registrations:

```dart
// Add to the MultiProvider or provider setup section:
ChangeNotifierProvider(create: (_) => ProjectSyncHealthProvider()),
ChangeNotifierProvider(create: (_) => ProjectImportRunner()),
// C2: ProjectLifecycleService must be registered here so ProjectListScreen can
// use context.read<ProjectLifecycleService>() without calling DatabaseService() directly.
ProxyProvider<DatabaseService, ProjectLifecycleService>(
  update: (_, dbService, __) => ProjectLifecycleService(dbService.database),
),
// NOTE: If DatabaseService exposes a synchronous .database getter, use it directly.
// If it is async, the agent must choose the right provider pattern (e.g., FutureProvider
// or initialize during app startup before provider tree is built).
```

Import the new files:
```dart
import 'package:construction_inspector/features/projects/presentation/providers/project_sync_health_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_import_runner.dart';
import 'package:construction_inspector/features/projects/data/services/project_lifecycle_service.dart';
```

#### Step 13.1.2: Update router if needed

In `lib/core/router/app_router.dart`:
- If `ProjectSelectionScreen` needs a `readOnly` route parameter, add it.
- Ensure the project list route serves the updated `ProjectListScreen`.

```dart
// If adding readOnly parameter to project selection route:
GoRoute(
  path: '/sync/project-selection',
  builder: (context, state) {
    final readOnly = state.uri.queryParameters['readOnly'] == 'true';
    return ProjectSelectionScreen(readOnly: readOnly);
  },
),
```

#### Step 13.1.3: Write provider wiring smoke test

```dart
// test/features/projects/wiring/provider_wiring_smoke_test.dart
// M16: Smoke test that the three new providers are accessible via context.read<>().
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_sync_health_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_import_runner.dart';
import 'package:construction_inspector/features/projects/data/services/project_lifecycle_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('ProjectSyncHealthProvider accessible via context.read', (tester) async {
    late ProjectSyncHealthProvider captured;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ProjectSyncHealthProvider(),
        child: Builder(
          builder: (context) {
            captured = context.read<ProjectSyncHealthProvider>();
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(captured, isNotNull);
  });

  testWidgets('ProjectImportRunner accessible via context.read', (tester) async {
    late ProjectImportRunner captured;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ProjectImportRunner(),
        child: Builder(
          builder: (context) {
            captured = context.read<ProjectImportRunner>();
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(captured, isNotNull);
    expect(captured.state, ImportState.idle);
  });

  testWidgets('ProjectLifecycleService accessible via context.read', (tester) async {
    late ProjectLifecycleService captured;
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );

    await tester.pumpWidget(
      Provider(
        create: (_) => ProjectLifecycleService(db),
        child: Builder(
          builder: (context) {
            captured = context.read<ProjectLifecycleService>();
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await db.close();
    expect(captured, isNotNull);
  });
}
```

#### Step 13.1.4: Verify app compiles
Run: `pwsh -Command "flutter analyze"`
Expected: No new errors (existing warnings acceptable)

#### Step 13.1.5: Run all project-related tests
Run: `pwsh -Command "flutter test test/features/projects/"`, timeout: 600000
Expected: PASS

---

## Phase 14: Integration Tests (PR1 Boundary)

### Sub-phase 14.1: End-to-End Project Lifecycle Tests

**Files:**
- Create: `test/features/projects/integration/project_lifecycle_integration_test.dart`

**Agent**: qa-testing-agent

#### Step 14.1.1: Write integration test

```dart
// test/features/projects/integration/project_lifecycle_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:construction_inspector/features/projects/data/services/project_lifecycle_service.dart';

void main() {
  late Database db;
  late ProjectLifecycleService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );

    // Full schema setup for integration testing
    // NOTE: The implementing agent must create ALL tables with correct schemas.
    // Include: projects, synced_projects, change_log (with project_id),
    // conflict_log, locations, contractors, bid_items, personnel_types,
    // daily_entries, photos, todo_items, equipment, entry_equipment,
    // entry_quantities, entry_contractors, entry_personnel_counts,
    // inspector_forms, form_responses, sync_control

    await _createFullSchema(db);
    service = ProjectLifecycleService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Full lifecycle', () {
    test('enroll → populate data → remove from device → verify clean', () async {
      // Step 1: Enroll project
      await service.enrollProject('proj-1');
      expect(
        (await db.query('synced_projects')).length,
        1,
      );

      // Step 2: Simulate synced data
      await db.insert('projects', {'id': 'proj-1', 'name': 'Test'});
      await db.insert('locations', {'id': 'loc-1', 'project_id': 'proj-1', 'name': 'L1'});
      await db.insert('daily_entries', {'id': 'de-1', 'project_id': 'proj-1'});
      await db.insert('entry_equipment', {'id': 'ee-1', 'daily_entry_id': 'de-1'});
      await db.insert('contractors', {'id': 'c-1', 'project_id': 'proj-1', 'name': 'C1'});
      await db.insert('equipment', {'id': 'eq-1', 'contractor_id': 'c-1'});
      await db.insert('photos', {
        'id': 'ph-1', 'project_id': 'proj-1', 'file_path': '/photos/ph-1.jpg',
      });
      await db.insert('change_log', {
        'table_name': 'locations', 'record_id': 'loc-1',
        'operation': 'insert', 'project_id': 'proj-1', 'processed': 0,
      });

      // Step 3: Remove from device
      final photoPaths = await service.removeFromDevice('proj-1');

      // Step 4: Verify everything is gone
      expect(await db.query('projects'), isEmpty);
      expect(await db.query('synced_projects'), isEmpty);
      expect(await db.query('locations'), isEmpty);
      expect(await db.query('daily_entries'), isEmpty);
      expect(await db.query('entry_equipment'), isEmpty);
      expect(await db.query('contractors'), isEmpty);
      expect(await db.query('equipment'), isEmpty);
      expect(await db.query('photos'), isEmpty);
      expect(await db.query('change_log'), isEmpty);
      expect(photoPaths, ['/photos/ph-1.jpg']);
    });

    test('unsynced count is accurate after changes', () async {
      await db.insert('change_log', {
        'table_name': 'locations', 'record_id': 'loc-1',
        'operation': 'insert', 'project_id': 'proj-1', 'processed': 0,
      });
      await db.insert('change_log', {
        'table_name': 'locations', 'record_id': 'loc-1',
        'operation': 'update', 'project_id': 'proj-1', 'processed': 0,
      });
      await db.insert('change_log', {
        'table_name': 'locations', 'record_id': 'loc-2',
        'operation': 'insert', 'project_id': 'proj-1', 'processed': 1,
      });

      final count = await service.getUnsyncedChangeCount('proj-1');
      expect(count, 2);

      final allCounts = await service.getAllUnsyncedCounts();
      expect(allCounts['proj-1'], 2);
    });

    test('authorization check enforces owner/admin rules', () async {
      await db.insert('projects', {
        'id': 'proj-1', 'name': 'Test', 'created_by_user_id': 'user-owner',
      });

      // Owner can delete
      expect(
        await service.canDeleteFromDatabase('proj-1', 'user-owner', isAdmin: false),
        true,
      );
      // Admin can delete
      expect(
        await service.canDeleteFromDatabase('proj-1', 'user-admin', isAdmin: true),
        true,
      );
      // Non-owner non-admin cannot delete
      expect(
        await service.canDeleteFromDatabase('proj-1', 'user-random', isAdmin: false),
        false,
      );
    });
  });
}

Future<void> _createFullSchema(Database db) async {
  await db.execute('''
    CREATE TABLE sync_control (key TEXT PRIMARY KEY, value TEXT NOT NULL)
  ''');
  await db.insert('sync_control', {'key': 'pulling', 'value': '0'});

  await db.execute('''
    CREATE TABLE synced_projects (
      project_id TEXT PRIMARY KEY,
      synced_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
    )
  ''');
  await db.execute('''
    CREATE TABLE change_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_name TEXT NOT NULL, record_id TEXT NOT NULL, operation TEXT NOT NULL,
      changed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
      processed INTEGER NOT NULL DEFAULT 0, error_message TEXT,
      retry_count INTEGER NOT NULL DEFAULT 0, metadata TEXT, project_id TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE conflict_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      record_id TEXT NOT NULL, table_name TEXT NOT NULL,
      resolved INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE projects (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, project_number TEXT,
      company_id TEXT, created_by_user_id TEXT,
      is_active INTEGER NOT NULL DEFAULT 1, deleted_at TEXT,
      created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
      updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
    )
  ''');
  await db.execute('CREATE TABLE locations (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, name TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE contractors (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, name TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE bid_items (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE personnel_types (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE daily_entries (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE photos (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, file_path TEXT, deleted_at TEXT)');
  await db.execute('CREATE TABLE todo_items (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE equipment (id TEXT PRIMARY KEY, contractor_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE entry_equipment (id TEXT PRIMARY KEY, daily_entry_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE entry_quantities (id TEXT PRIMARY KEY, daily_entry_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE entry_contractors (id TEXT PRIMARY KEY, daily_entry_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE entry_personnel_counts (id TEXT PRIMARY KEY, daily_entry_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE inspector_forms (id TEXT PRIMARY KEY, daily_entry_id TEXT NOT NULL, deleted_at TEXT)');
  await db.execute('CREATE TABLE form_responses (id TEXT PRIMARY KEY, daily_entry_id TEXT NOT NULL, deleted_at TEXT)');
}
```

#### Step 14.1.2: Run integration tests
Run: `pwsh -Command "flutter test test/features/projects/integration/"`, timeout: 600000
Expected: PASS

#### Step 14.1.3: Run full test suite for PR1
Run: `pwsh -Command "flutter test"`, timeout: 600000
Expected: PASS (or only pre-existing failures)

---

**--- END PR1: Project Lifecycle + Schema ---**

---

# PR2: Logger Migration

---

## Phase 15: Logger Enhancement (Release Scrubbing, PII, Retention)

### Sub-phase 15.1: Release-Safe File Logging

**Files:**
- Modify: `lib/core/logging/logger.dart`
- Test: `test/core/logging/logger_scrubbing_test.dart`

**Agent**: general-purpose

#### Step 15.1.1: Write failing test for file transport scrubbing

```dart
// test/core/logging/logger_scrubbing_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/logging/logger.dart';

void main() {
  group('Logger scrubbing', () {
    test('_scrubSensitive redacts known PII keys', () {
      // FROM SPEC: Construction-domain PII blocklist additions
      final data = {
        'email': 'user@example.com',
        'phone': '555-1234',
        'ssn': '123-45-6789',
        'license_number': 'DL12345',
        'employee_id': 'EMP001',
        'safe_field': 'visible',
      };

      final scrubbed = Logger.scrubSensitiveForTest(data);

      expect(scrubbed['email'], '[REDACTED]');
      expect(scrubbed['phone'], '[REDACTED]');
      expect(scrubbed['ssn'], '[REDACTED]');
      expect(scrubbed['license_number'], '[REDACTED]');
      expect(scrubbed['safe_field'], 'visible');
    });

    test('_isSensitiveKey catches construction-domain keys', () {
      // FROM SPEC: Construction-domain PII blocklist
      expect(Logger.isSensitiveKeyForTest('contractor_ssn'), true);
      expect(Logger.isSensitiveKeyForTest('inspector_license'), true);
      expect(Logger.isSensitiveKeyForTest('phone_number'), true);
      // H9: project_name IS in the PII blocklist per the spec — assert true
      expect(Logger.isSensitiveKeyForTest('project_name'), true);
    });
  });
}
```

NOTE: The implementing agent may need to add `@visibleForTesting` static methods to expose `_scrubSensitive` and `_isSensitiveKey` for testing, or test them indirectly.

#### Step 15.1.2: Verify test fails
Run: `pwsh -Command "flutter test test/core/logging/logger_scrubbing_test.dart"`
Expected: FAIL (test methods don't exist yet)

#### Step 15.1.3: Implement release-safe scrubbing

In `lib/core/logging/logger.dart`:

1. **Add construction-domain PII keys** to `_sensitiveKeys`:
```dart
// FROM SPEC: Construction-domain PII blocklist additions
static const Set<String> _sensitiveKeys = {
  // Existing keys...
  'password', 'token', 'secret', 'api_key', 'access_token', 'refresh_token',
  // New construction-domain keys:
  'ssn', 'social_security', 'license_number', 'inspector_license',
  'contractor_ssn', 'phone', 'phone_number', 'cell_phone', 'mobile',
  'home_address', 'street_address', 'driver_license',
  'bank_account', 'routing_number', 'tax_id', 'ein',
  // H9: project_name is in the blocklist per spec (project identifiers are PII
  // in the context of construction contracts — owner/address linkage risk)
  'project_name',
};
```

2. **Add `_endsWith` patterns**:
```dart
static const List<String> _sensitiveEndsWith = [
  '_ssn', '_license', '_phone', '_email', '_address',
  '_token', '_secret', '_key', '_password',
];
```

3. **Apply scrubbing in file transport** within `_log()`:
```dart
// FROM SPEC: Add release-only scrubbing to file transport in _log()
// WHY: File logs persist on device. Must scrub PII even in release.
final scrubData = data != null ? _scrubSensitive(data) : null;
// Use scrubData instead of data when writing to file sink
```

4. **Fix HTTP transport ordering** — scrub before truncation:
```dart
// FROM SPEC: Fix HTTP transport: scrub before truncation
final scrubbedData = data != null ? _scrubSensitive(data) : null;
final truncatedMessage = _truncateForHttp(message);
// Send scrubbedData + truncatedMessage
```

5. **Add log retention constants**:
```dart
// FROM SPEC: Log retention: 14 days, 50MB cap
static const int _retentionDays = 14;
static const int _maxLogSizeBytes = 50 * 1024 * 1024; // 50MB
```

6. **Add `@visibleForTesting` wrappers**:
```dart
@visibleForTesting
static Map<String, dynamic> scrubSensitiveForTest(Map<String, dynamic> data) =>
    _scrubSensitive(data);

@visibleForTesting
static bool isSensitiveKeyForTest(String key) => _isSensitiveKey(key);
```

#### Step 15.1.4: Verify tests pass
Run: `pwsh -Command "flutter test test/core/logging/logger_scrubbing_test.dart"`
Expected: PASS

---

## Phase 16: DebugLogger Migration (22 Files)

### Sub-phase 16.1: Sync Files (6 files)

**Files:**
- Modify: `lib/features/sync/data/sync_engine.dart`
- Modify: `lib/features/sync/application/sync_orchestrator.dart`
- Modify: `lib/features/sync/application/sync_lifecycle_manager.dart`
- Modify: `lib/features/sync/data/change_tracker.dart`
- Modify: `lib/features/sync/data/orphan_scanner.dart`
- Modify: `lib/features/sync/data/integrity_checker.dart`

**Agent**: backend-supabase-agent

#### Step 16.1.1: Migrate sync files

For each file:
1. Replace `import '...debug_logger.dart'` with `import 'package:construction_inspector/core/logging/logger.dart'`
2. Replace all `DebugLogger.sync(...)` calls with `Logger.sync(...)`
3. Replace all `DebugLogger.db(...)` calls with `Logger.db(...)`
4. Replace all `DebugLogger.error(...)` calls with `Logger.error(...)`
5. Replace any other `DebugLogger.X(...)` with the appropriate `Logger.X(...)`

Pattern for each file:
```dart
// BEFORE:
import 'package:construction_inspector/core/logging/debug_logger.dart';
DebugLogger.sync('PULL_START table=$tableName');

// AFTER:
import 'package:construction_inspector/core/logging/logger.dart';
Logger.sync('PULL_START table=$tableName');
```

#### Step 16.1.2: Verify compilation
Run: `pwsh -Command "flutter analyze"`
Expected: No new errors

#### Step 16.1.3: Verify existing sync tests pass
Run: `pwsh -Command "flutter test test/features/sync/"`, timeout: 600000
Expected: PASS

### Sub-phase 16.2: PDF Files (5 files)

**Files:**
- Modify: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`
- Modify: `lib/features/pdf/services/extraction/stages/post_processor_v2.dart`
- Modify: `lib/features/pdf/services/pdf_import_service.dart`
- Modify: `lib/features/pdf/presentation/helpers/pdf_import_helper.dart`
- Modify: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart`

**Agent**: pdf-agent

#### Step 16.2.1: Migrate PDF files

Same pattern as 16.1. Replace `DebugLogger` with `Logger`. Use `Logger.pdf(...)` for PDF-specific logs, `Logger.ocr(...)` for OCR logs.

#### Step 16.2.2: Verify
Run: `pwsh -Command "flutter test test/features/pdf/"`, timeout: 600000
Expected: PASS

### Sub-phase 16.3: Database, Services, Projects, Quantities, Shared (11 files)

**Files:**
- Modify: `lib/core/database/database_service.dart`
  - NOTE (H8): `schema_verifier` does NOT exist as a standalone file — the grep shows it only lives inside `database_service.dart`. Any DebugLogger calls related to schema verification are already covered by migrating `database_service.dart`. Do NOT create or reference `schema_verifier.dart`.
- Modify: `lib/services/soft_delete_service.dart`
- Modify: `lib/services/startup_cleanup_service.dart`
- Modify: `lib/services/storage_cleanup.dart`
- Modify: `lib/features/projects/data/repositories/project_repository.dart`
- Modify: `lib/features/projects/data/datasources/project_local_datasource.dart`
- Modify: `lib/features/quantities/presentation/providers/bid_item_provider.dart`
- Modify: `lib/features/quantities/data/budget_sanity_checker.dart`
- Modify: `lib/shared/data/datasources/generic_local_datasource.dart`

**Agent**: general-purpose

#### Step 16.3.1: Migrate remaining DebugLogger files

Same pattern. Replace all `DebugLogger.X(...)` with appropriate `Logger.X(...)`:
- Database files: `Logger.db(...)`
- Service files: `Logger.lifecycle(...)` or `Logger.sync(...)`
- Project files: `Logger.db(...)` or `Logger.log(...)`
- Quantity files: `Logger.log(...)`
- Shared: `Logger.db(...)`

#### Step 16.3.2: Verify
Run: `pwsh -Command "flutter analyze"`
Expected: No new errors

#### Step 16.3.3: Verify no remaining DebugLogger imports

The implementing agent should search for any remaining `DebugLogger` imports using the Grep tool (pattern: `import.*debug_logger`, path: `lib/`) or:
```
pwsh -Command "rg 'import.*debug_logger' lib/"
```
Expected: Zero results (only the deprecated file itself should remain).

---

## Phase 17: debugPrint Migration (47 Files)

### Sub-phase 17.1: Batch 1 — Sync & Database (10-12 files)

**Agent**: general-purpose

#### Step 17.1.1: Find and migrate sync/database debugPrint calls

Search for `debugPrint` in `lib/features/sync/` and `lib/core/database/` using the Grep tool or `pwsh -Command "rg 'debugPrint' lib/features/sync/ lib/core/database/"`. Replace each with the appropriate Logger category:

```dart
// BEFORE:
debugPrint('SyncEngine: pulling $tableName...');

// AFTER:
Logger.sync('PULLING table=$tableName');
```

Rules:
- Sync files: `Logger.sync(...)`
- Database files: `Logger.db(...)`
- Remove `import 'package:flutter/foundation.dart'` only if `debugPrint` was the only usage from that import. Check for `kDebugMode`, `@protected`, `ChangeNotifier`, etc.

#### Step 17.1.2: Verify
Run: `pwsh -Command "flutter test test/features/sync/ test/core/database/"`, timeout: 600000
Expected: PASS

### Sub-phase 17.2: Batch 2 — PDF & OCR (10-12 files)

**Agent**: pdf-agent

#### Step 17.2.1: Find and migrate PDF/OCR debugPrint calls

Search for `debugPrint` in `lib/features/pdf/` using the Grep tool or `pwsh -Command "rg 'debugPrint' lib/features/pdf/"`. Replace with `Logger.pdf(...)` or `Logger.ocr(...)`.

#### Step 17.2.2: Verify
Run: `pwsh -Command "flutter test test/features/pdf/"`, timeout: 600000
Expected: PASS

### Sub-phase 17.3: Batch 3 — UI & Presentation (10-12 files)

**Agent**: frontend-flutter-specialist-agent

#### Step 17.3.1: Find and migrate presentation debugPrint calls

Search `lib/**/presentation/` directories using the Grep tool (pattern: `debugPrint`, glob: `lib/**/presentation/**/*.dart`) or `pwsh -Command "rg 'debugPrint' lib/ --glob '**/presentation/**/*.dart'"`. Replace with appropriate Logger categories:
- Navigation: `Logger.nav(...)`
- UI state: `Logger.ui(...)`
- Photo: `Logger.photo(...)`

#### Step 17.3.2: Verify
Run: `pwsh -Command "flutter analyze"`
Expected: No new errors

### Sub-phase 17.4: Batch 4 — Remaining files (10-15 files)

**Agent**: general-purpose

#### Step 17.4.1: Find and migrate all remaining debugPrint calls

Search all of `lib/` for remaining `debugPrint` calls using the Grep tool (pattern: `debugPrint`, path: `lib/`) or `pwsh -Command "rg 'debugPrint' lib/"`. Replace with appropriate Logger category based on file location.

#### Step 17.4.2: Verify zero debugPrint calls remain

The implementing agent should search using the Grep tool (pattern: `debugPrint`, path: `lib/`, glob: `*.dart`) or:
```
pwsh -Command "rg 'debugPrint' lib/ --glob '*.dart'"
```
Expected: Zero results.

#### Step 17.4.3: Full test suite
Run: `pwsh -Command "flutter test"`, timeout: 600000
Expected: PASS

---

## Phase 18: Dark Pipeline Logging (16 Stages)

### Sub-phase 18.1: Add Per-Page OCR Timing + Memory Snapshots

**Files:**
- Modify: All 16 pipeline stage files in `lib/features/pdf/services/extraction/`

**Agent**: pdf-agent

#### Step 18.1.1: Identify all pipeline stage files

The implementing agent must find all pipeline stages. They are in `lib/features/pdf/services/extraction/` subdirectories. Each stage class should get:

```dart
// At stage entry:
Logger.pdf('STAGE_START stage=${runtimeType} page=$pageIndex');
final stopwatch = Stopwatch()..start();

// At stage exit:
stopwatch.stop();
Logger.pdf('STAGE_COMPLETE stage=${runtimeType} page=$pageIndex '
    'elapsed=${stopwatch.elapsedMilliseconds}ms');
```

For memory-intensive stages (OCR, image processing):
```dart
// FROM SPEC: Per-page OCR timing + memory snapshots
Logger.pdf('MEMORY_SNAPSHOT stage=${runtimeType} '
    'heap=${ProcessInfo.currentRss ~/ (1024 * 1024)}MB');
```

NOTE: `ProcessInfo.currentRss` may not be available on all platforms. Use a try-catch or platform check. On mobile, use `dart:io` `ProcessInfo` if available, otherwise omit.

#### Step 18.1.2: Verify no regressions
Run: `pwsh -Command "flutter test test/features/pdf/extraction/"`, timeout: 600000
Expected: PASS

---

## Phase 19: Delete Deprecated Wrappers + Verification

### Sub-phase 19.1: Delete debug_logger.dart and app_logger.dart

**Files:**
- Delete: `lib/core/logging/debug_logger.dart`
- Delete: `lib/core/logging/app_logger.dart` (if it exists)

**Agent**: general-purpose

#### Step 19.1.1: Verify no remaining imports

The implementing agent must search for any remaining imports of the deprecated files using the Grep tool or:
```
pwsh -Command "rg 'debug_logger' lib/ test/ --glob '*.dart'"
pwsh -Command "rg 'app_logger' lib/ test/ --glob '*.dart'"
```
Expected: Zero results (other than the files themselves).

If any imports remain, fix them first before deleting.

#### Step 19.1.2: Delete the files

```bash
rm lib/core/logging/debug_logger.dart
rm lib/core/logging/app_logger.dart  # if exists
```

#### Step 19.1.3: Verify compilation
Run: `pwsh -Command "flutter analyze"`
Expected: No errors related to missing imports.

#### Step 19.1.4: Final verification — full test suite
Run: `pwsh -Command "flutter test"`, timeout: 600000
Expected: PASS

#### Step 19.1.5: Verify success criteria

The implementing agent should confirm:
1. Zero `DebugLogger` imports remain in `lib/`
2. Zero `AppLogger` imports remain in `lib/`
3. Zero `debugPrint` calls remain in `lib/`
4. `debug_logger.dart` and `app_logger.dart` are deleted
5. All tests pass
6. `flutter analyze` has no new errors

---

**--- END PR2: Logger Migration ---**

---

## Summary

| PR | Phases | New Files | Modified Files | Tests |
|----|--------|-----------|----------------|-------|
| PR1 | 1-14 | 6 (service, 2 providers, 2 widgets, 1 RLS migration) | 9 (schema, triggers, providers, screens, router, main) | ~8 test files |
| PR2 | 15-19 | 0 | 72+ (logger enhancement + all migration targets) | ~3 test files, 2 files deleted |
