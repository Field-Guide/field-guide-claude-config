# Data Layer — Procedure Guide

> Loaded on-demand by workers. For constraints and invariants, see .claude/rules/backend/data-layer.md

## Common Commands
```bash
pwsh -Command "flutter test test/features/projects/"        # Test specific feature
pwsh -Command "flutter test test/features/"                 # Test all features
pwsh -Command "flutter test test/"                          # Run all tests
npx supabase db diff                        # Check schema changes
npx supabase migration new name             # Create migration
# Database location (Windows): %LOCALAPPDATA%\construction_inspector\construction_inspector.db
```

## Architecture

### Feature-First Organization
**All data layer implementation** lives in feature modules:
```
lib/features/[feature]/data/
├── models/         # Entity classes (*.dart)
├── repositories/   # Business logic + validation
└── datasources/    # CRUD operations (local + remote)
```

**Note**: This is an idealized example structure. Actual feature directories may not have all files shown.

**Example Feature Structure** (Projects feature):
```
lib/features/projects/
├── data/
│   ├── data.dart                      # Barrel export
│   ├── models/
│   │   └── project.dart               # Project model
│   ├── repositories/
│   │   └── project_repository.dart    # Business logic
│   └── datasources/
│       ├── local/
│       │   └── project_local_datasource.dart
│       └── remote/
│           └── project_remote_datasource.dart
├── domain/
│   ├── domain.dart                    # Barrel export
│   └── use_cases/
│       └── get_projects_use_case.dart
├── presentation/
│   ├── presentation.dart              # Barrel export
│   ├── providers/
│   │   └── project_provider.dart
│   ├── screens/
│   │   └── project_list_screen.dart
│   └── widgets/
│       └── project_card.dart
└── di/
    └── projects_providers.dart        # Dependency injection wiring
```

**17 Features** (all follow same pattern):
auth, calculator, contractors, dashboard, entries, forms, gallery, locations, pdf, photos, projects, quantities, settings, sync, todos, toolbox, weather

### Database Schema Organization
```
lib/core/database/
├── database_service.dart      # Main database class (version 50)
└── schema/                    # Modular table definitions
    ├── schema.dart             # Barrel export (imports all tables)
    ├── core_tables.dart        # projects, locations
    ├── entry_tables.dart       # daily_entries, entry_contractors, entry_equipment
    ├── contractor_tables.dart  # contractors, equipment
    ├── personnel_tables.dart   # personnel_types, entry_personnel, entry_personnel_counts
    ├── quantity_tables.dart    # bid_items, entry_quantities
    ├── photo_tables.dart       # photos
    ├── toolbox_tables.dart     # toolbox talks
    ├── extraction_tables.dart  # OCR extraction data
    ├── sync_tables.dart        # legacy sync metadata
    ├── sync_engine_tables.dart # change_log, sync engine state
    ├── form_export_tables.dart # form export records
    ├── entry_export_tables.dart # entry export records
    ├── document_tables.dart    # documents
    ├── consent_tables.dart     # user consent records
    └── support_tables.dart     # support/diagnostic data
```

## Shared Base Classes

### Repositories (`lib/shared/repositories/`)
- `BaseRepository<T>` — abstract CRUD contract (getAll, getById, insert, update, delete)
- `ProjectScopedRepository<T>` — extends `BaseRepository`, scopes all queries to a project ID

### Datasources (`lib/shared/datasources/`)
- `BaseLocalDatasource<T>` — abstract SQLite CRUD interface
- `GenericLocalDatasource<T>` — implements `BaseLocalDatasource` with standard sqflite operations
  - `getAll()`, `getById()`, and all read methods auto-prepend `deleted_at IS NULL` filter
  - `delete(id)` performs soft-delete (sets `deleted_at` timestamp), NOT hard-delete
  - `hardDelete(id)` is required for permanent removal
  - `getDeleted()` returns soft-deleted records (for Trash screen)
  - `restore(id)` clears `deleted_at`
  - `purgeExpired(retentionDays)` hard-deletes records past TTL (default 30 days)
- `ProjectScopedDatasource<T>` — extends `GenericLocalDatasource`, filters by `project_id`

## Code Style

### Model Pattern
See `lib/features/projects/data/models/project.dart` for reference implementation.

```dart
// Example: lib/features/projects/data/models/project.dart
class Project {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Project copyWith({String? name}) => Project(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    updatedAt: DateTime.now(),  // Always update
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Project.fromMap(Map<String, dynamic> map) => Project(
    id: map['id'] as String,
    name: map['name'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}
```

### Repository Pattern
Extend `BaseRepository` or `ProjectScopedRepository` from `lib/shared/repositories/`:

```dart
class ProjectRepository extends BaseRepository<Project> {
  final ProjectLocalDatasource _local;
  final ProjectRemoteDatasource _remote;

  @override
  Future<List<Project>> getAll() => _local.getAll();

  @override
  Future<void> insert(Project item) => _local.insert(item);
  // ...
}
```

### Datasource Pattern
See `lib/features/projects/data/datasources/` for reference implementations.

```dart
// Local (SQLite): lib/features/projects/data/datasources/local/project_local_datasource.dart
class ProjectLocalDatasource {
  final DatabaseService _db;

  Future<List<Project>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('projects', orderBy: 'name ASC');
    return maps.map((m) => Project.fromMap(m)).toList();
  }

  Future<void> insert(Project project) async {
    final db = await _db.database;
    await db.insert('projects', project.toMap());
  }
}

// Remote (Supabase): lib/features/projects/data/datasources/remote/project_remote_datasource.dart
class ProjectRemoteDatasource {
  final SupabaseClient _client;

  Future<List<Project>> getAll() async {
    final response = await _client
        .from('projects')
        .select()
        .order('name', ascending: true);
    return (response as List).map((m) => Project.fromMap(m)).toList();
  }
}
```

## State Management

### Provider Base Classes (`lib/shared/providers/`)
- `BaseListProvider<T, R>` — base for list-style providers with CRUD operations
- `PagedListProvider<T, R>` — extends base with pagination support (infinite scroll)
- Both extend `ChangeNotifier` and are parameterized on `ProjectScopedRepository<T>`
- ~32 total `ChangeNotifier` providers in the app

### Provider for Data
See `lib/features/projects/presentation/providers/project_provider.dart` for reference.

```dart
// lib/features/projects/presentation/providers/project_provider.dart
class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _repository;
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _projects = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
```

## Database

### Schema Files
Schema definitions: `lib/core/database/schema/` (modular table definitions)
Database service: `lib/core/database/database_service.dart`
Current version: 50 (see `lib/core/database/database_service.dart`)

### SchemaVerifier
`lib/core/database/schema_verifier.dart` — runs after every database open (report-only, no auto-repair). Detects missing tables, missing columns, and column definition drift. Must be updated when adding tables or columns.

### Indexes
Add indexes on:
- Foreign key columns
- Frequently filtered columns (date, status)
- Search columns (name, title)

### Migrations
Use `_addColumnIfNotExists` helper for safe ALTER TABLE migrations (checks `PRAGMA table_info` first). This is the standard pattern used throughout the codebase.

```dart
// Preferred: safe column addition
await _addColumnIfNotExists(db, 'photos', 'caption', 'TEXT');

// Raw alternative (only when _addColumnIfNotExists is unavailable)
if (oldVersion < 9) {
  await db.execute('ALTER TABLE examples ADD COLUMN new_field TEXT');
}
```

## Sync (Offline-First)

### Sync Architecture
Sync uses a `change_log` table populated by SQLite triggers. There is NO `SyncStatus` enum per model. The sync engine reads from `change_log` and pushes changes to Supabase.

### Sync Flow
1. Save locally first (immediate)
2. SQLite trigger writes to `change_log`
3. Sync engine reads `change_log` when online
4. Use last-write-wins (updated_at)

## Error Handling
```dart
class RepositoryResult<T> {
  final T? data;
  final String? error;
  bool get isSuccess => error == null;
}
```

## Logging
```dart
Logger.db('DB: Query executed in ${sw.elapsed}');
```

## Pull Request Template
```markdown
## Data Layer Changes
- [ ] Feature module: [auth/contractors/entries/etc.]
- [ ] Model changes: [description]
- [ ] Repository changes: [description]
- [ ] Datasource changes: [Local/Remote/Both]
- [ ] Migration required: Yes/No
- [ ] Sync impact: None/Local/Remote/Both
- [ ] Database version bump: [current] -> [new]

## Files Changed
- [ ] lib/features/[feature]/data/models/
- [ ] lib/features/[feature]/data/repositories/
- [ ] lib/features/[feature]/data/datasources/
- [ ] lib/core/database/database_service.dart (if migration)
- [ ] lib/core/database/schema/ (if schema change)

## Testing
- [ ] Unit tests for models (toMap/fromMap)
- [ ] Repository tests with mocks
- [ ] Migration tested (upgrade path from previous version)
- [ ] Existing data preserved after migration
```
