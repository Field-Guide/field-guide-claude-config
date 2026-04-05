# Schema Patterns — Procedure Guide

> Loaded on-demand by workers. For constraints and invariants, see `.claude/rules/database/schema-patterns.md`

## Table Naming Conventions

### Standard Tables
- Plural snake_case: `daily_entries`, `bid_items`, `entry_personnel`
- Junction tables: `entry_` prefix + related entity

### Column Names
- snake_case: `project_id`, `created_at`
- Foreign keys: `{entity}_id` pattern
- Timestamps: `created_at`, `updated_at`, `synced_at`

## Schema Definition Pattern

### Table Creation
```dart
// In schema/[domain]_tables.dart
const String createProjectsTable = '''
  CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    contract_number TEXT,
    start_date TEXT,
    end_date TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
''';
```

### Index Creation
```dart
// Always index: FK columns, frequently filtered columns, search columns
const String createProjectsIndexes = '''
  CREATE INDEX IF NOT EXISTS idx_projects_name ON projects(name);
''';
```

### Foreign Keys
```dart
// Enable in onConfigure (rawQuery for Android API 36)
await db.rawQuery('PRAGMA foreign_keys = ON');

const String createDailyEntriesTable = '''
  CREATE TABLE IF NOT EXISTS daily_entries (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    location_id TEXT NOT NULL,
    date TEXT NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
  )
''';
```

## Migration Pattern

### Version Increment
```dart
final db = await openDatabase(
  path,
  version: 50,  // Increment for each migration
  onCreate: _onCreate,
  onUpgrade: _onUpgrade,
  onConfigure: (db) async {
    await db.rawQuery('PRAGMA journal_mode=WAL');
    await db.rawQuery('PRAGMA foreign_keys=ON');
  },
);
```

### Safe Migration — `_addColumnIfNotExists`
```dart
Future<void> _addColumnIfNotExists(
  Database db, String table, String column, String type,
) async {
  final result = await db.rawQuery('PRAGMA table_info($table)');
  final columnExists = result.any((row) => row['name'] == column);
  if (!columnExists) {
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }
}

// Usage:
await _addColumnIfNotExists(db, 'photos', 'caption', 'TEXT');
```

### Data Migration
```dart
if (oldVersion < 20) {
  await db.execute('ALTER TABLE entries ADD COLUMN status TEXT DEFAULT "draft"');
  await db.execute("UPDATE entries SET status = 'complete' WHERE activities IS NOT NULL");
}
```

## SchemaVerifier

`lib/core/database/schema_verifier.dart` — runs after every database open (report-only). Detects missing tables, missing columns, and column definition drift. **Must be updated** alongside any schema change.

## onOpen Callback

Resets `sync_control.pulling` to `'0'` on every startup — crash recovery for stuck trigger suppression.

## Common Patterns

### Timestamps
```sql
created_at TEXT NOT NULL,
updated_at TEXT NOT NULL,
synced_at TEXT
```

### Soft Delete
```sql
deleted_at TEXT,
deleted_by TEXT
```

## Anti-Patterns

### Missing Indexes on FKs
```dart
// BAD
'project_id TEXT REFERENCES projects(id)'
// GOOD — add index
// + CREATE INDEX idx_entries_project ON entries(project_id);
```

### Hardcoded IDs
```dart
// BAD
'SELECT * FROM projects WHERE id = "abc123"'
// GOOD
await db.query('projects', where: 'id = ?', whereArgs: [projectId]);
```

## Debugging
```dart
// List all tables
final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

// Show table schema
final schema = await db.rawQuery("PRAGMA table_info(projects)");

// Check indexes
final indexes = await db.rawQuery("SELECT name, tbl_name FROM sqlite_master WHERE type='index'");
```

## Quality Checklist
- [ ] Indexes on all FKs and filtered columns
- [ ] Foreign keys have ON DELETE CASCADE where appropriate
- [ ] Timestamps use ISO 8601 (TEXT)
- [ ] TEXT IDs (not INTEGER autoincrement)
- [ ] Version incremented
- [ ] Migration tested from previous version
- [ ] SchemaVerifier updated

## PR Template
```markdown
## Database Changes
- [ ] Schema tables affected: [list]
- [ ] Version bump: [old] -> [new]
- [ ] Migration tested (upgrade from previous version)
- [ ] Indexes added for new FKs/filters
```
