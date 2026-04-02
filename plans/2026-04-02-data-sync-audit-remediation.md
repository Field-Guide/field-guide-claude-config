# Data, Database & Sync Audit Remediation — Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Remediate 10 remaining pre-prod audit findings, resolve BLOCKER-38, and reduce A6 lint baseline in sync DI files.
**Spec:** `.claude/specs/2026-04-02-data-sync-audit-remediation-spec.md`
**Tailor:** `.claude/tailor/2026-04-02-data-sync-audit-remediation/`

**Architecture:** Dead code removal → schema migration hardening → boundary fixes (repository abstraction, datasource extension) → structural refactor (builder pattern, engine factory) → sign-out UX safety → tests & cleanup. Single PR, phased execution.
**Tech Stack:** Flutter/Dart, SQLite (sqflite), Supabase, Provider
**Blast Radius:** 18 direct, 14 dependent, 12 test files, 4 deletions

---

## Phase 1: Dead Code & Quick Fixes

### Sub-phase 1.1: F10 — Remove unused userId param from updateLastSyncedAt

**Files:**
- Modify: `lib/features/auth/data/datasources/remote/user_profile_sync_datasource.dart:33-35`
- Modify: `lib/features/sync/application/sync_orchestrator.dart:291`
- Test: `test/features/auth/data/datasources/remote/user_profile_sync_datasource_test.dart` (Phase 6)

**Agent**: `backend-data-layer-agent`

#### Step 1.1.1: Remove userId param from updateLastSyncedAt

In `user_profile_sync_datasource.dart`, change the method signature:

```dart
// WHY: RPC uses server-side auth.uid() — the userId param was always misleading
// and never used in the RPC call body.
Future<void> updateLastSyncedAt() async {
    await _client.rpc('update_last_synced_at');
}
```

#### Step 1.1.2: Update caller in SyncOrchestrator

In `sync_orchestrator.dart` (~line 291), remove the `userId` argument:

```dart
// WHY: updateLastSyncedAt no longer takes userId — RPC resolves it server-side
await _userProfileSyncDatasource!.updateLastSyncedAt();
```

#### Step 1.1.3: Verify no other callers

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

### Sub-phase 1.2: F12 — Delete dead query_mixins.dart

**Files:**
- Delete: `lib/shared/datasources/query_mixins.dart`
- Modify: `lib/shared/datasources/datasources.dart:6`

**Agent**: `backend-data-layer-agent`

#### Step 1.2.1: Delete query_mixins.dart

Delete `lib/shared/datasources/query_mixins.dart` — `BatchOperationsMixin` has zero importers (verified in tailor blast-radius).

#### Step 1.2.2: Remove re-export from datasources.dart

In `lib/shared/datasources/datasources.dart`, remove line 6:

```dart
// REMOVE this line:
export 'query_mixins.dart';
```

#### Step 1.2.3: Verify no breakage

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

### Sub-phase 1.3: F13 — Delete stale sync_queue migration test

**Files:**
- Delete: `test/features/sync/schema/sync_queue_migration_test.dart`

**Agent**: `backend-data-layer-agent`

#### Step 1.3.1: Delete stale test file

Delete `test/features/sync/schema/sync_queue_migration_test.dart` — the `sync_queue` table was dropped in migration v31. This test manually recreates it to test a completed migration path that no longer serves a purpose.

---

### Sub-phase 1.4: BLOCKER-38 — Remove clearLocalCompanyData from sign-OUT path, KEEP SwitchCompanyUseCase for sign-IN

**Files:**
- Modify: `lib/features/auth/domain/usecases/sign_in_use_case.dart` (verify SwitchCompanyUseCase.detectAndHandle() is still called)
- Modify: `test/features/auth/presentation/providers/auth_provider_test.dart` (minor cleanup only)

**Agent**: `auth-agent`

> **SEC-R1 NOTE**: The original plan deleted SwitchCompanyUseCase entirely, but it provides
> a real security function: detecting company switches on shared devices. When a different
> user from a different company signs in, `clearLocalCompanyData` wipes the previous
> company's data to prevent cross-tenant exposure. This is the ONLY valid caller of
> `clearLocalCompanyData`. The method must NOT be deleted from `AuthService` because
> `SwitchCompanyUseCase` still needs it.
>
> What BLOCKER-38 actually requires:
> - DO NOT call `clearLocalCompanyData` from sign-OUT (already not called -- BUG-17 fixed this)
> - KEEP `SwitchCompanyUseCase.detectAndHandle()` in `SignInUseCase` (company-switch detection at sign-in)
> - KEEP `clearLocalCompanyData` on `AuthService` (called by SwitchCompanyUseCase only)
> - ADD unsynced-change warning to sign-out (Phase 5)

#### Step 1.4.1: Verify clearLocalCompanyData is NOT called from sign-out path

Grep for all call sites of `clearLocalCompanyData`. Confirm it is ONLY called from
`SwitchCompanyUseCase`. If any sign-out path calls it, remove that call site only.

#### Step 1.4.2: Verify SwitchCompanyUseCase.detectAndHandle() is called in SignInUseCase

Read `sign_in_use_case.dart` and confirm `detectAndHandle` is still invoked during sign-in.
No changes needed if it is already there.

#### Step 1.4.3: Verify Phase 1 complete

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

## Phase 2: Schema & Migration Cleanup

### Sub-phase 2.1: F3 — Remove form_type DEFAULT via migration

**Files:**
- Modify: `lib/core/database/database_service.dart` (add migration v47, bump version)
- Modify: `lib/core/database/schema_verifier.dart:324` (update expectedSchema)

**Agent**: `backend-data-layer-agent`

#### Step 2.1.1: Write failing test for migration v47

Create `test/core/database/migration_v47_test.dart`:

```dart
// WHY: Verifies migration v47 removes the DEFAULT from form_responses.form_type
// so all inserts must provide explicit form_type values.
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/database/database_service.dart';

void main() {
  late DatabaseService service;

  setUp(() async {
    service = DatabaseService.forTesting();
  });

  test('form_responses.form_type has no DEFAULT after migration', () async {
    final db = await service.database;
    final columns = await db.rawQuery('PRAGMA table_info(form_responses)');
    final formTypeCol = columns.firstWhere(
      (c) => c['name'] == 'form_type',
    );
    // NOTE: After migration v47, dflt_value must be null (no DEFAULT)
    expect(formTypeCol['dflt_value'], isNull,
        reason: 'form_type should have no DEFAULT after migration v47');
  });
}
```

#### Step 2.1.2: Verify test fails

Run: `pwsh -Command "flutter test test/core/database/migration_v47_test.dart"`
Expected: FAIL — current schema has DEFAULT from migration v22.

#### Step 2.1.3: Implement migration v47

In `database_service.dart`:

1. Bump version from 46 to 47 (lines 58 and 84)
2. Add migration block in `_onUpgrade`:

```dart
// WHY: F3 — Remove DEFAULT on form_responses.form_type so all inserts
// must provide explicit form_type. The canonical DDL in toolbox_tables.dart
// already has no DEFAULT, but databases created via migration v22 carry it.
// FROM SPEC: Table rebuild required because SQLite cannot ALTER COLUMN.
if (oldVersion < 47) {
  // Step 1: Backfill any null/empty form_type before rebuild
  await db.execute('''
    UPDATE form_responses
    SET form_type = '$kFormTypeMdot0582b'
    WHERE form_type IS NULL OR form_type = ''
  ''');

  // Step 2: Rebuild table without DEFAULT
  await db.execute('ALTER TABLE form_responses RENAME TO form_responses_old');

  // Step 3: Recreate with canonical DDL (no DEFAULT on form_type)
  // NOTE: Must match toolbox_tables.dart createFormResponsesTable exactly
  await db.execute('''
    CREATE TABLE form_responses (
      id TEXT PRIMARY KEY,
      form_type TEXT NOT NULL,
      form_id TEXT,
      entry_id TEXT,
      project_id TEXT NOT NULL,
      header_data TEXT NOT NULL DEFAULT '{}',
      response_data TEXT NOT NULL,
      table_rows TEXT,
      response_metadata TEXT,
      status TEXT NOT NULL DEFAULT 'open',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      created_by_user_id TEXT,
      deleted_at TEXT,
      deleted_by TEXT,
      FOREIGN KEY (entry_id) REFERENCES daily_entries(id) ON DELETE SET NULL,
      FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
    )
  ''');

  // Step 4: Copy data (column list must match both old and new schemas)
  // NOTE: The implementing agent must verify the old table's columns via
  // PRAGMA table_info(form_responses_old) and map them to the new schema.
  // Columns that exist in new but not old must be given defaults.
  await db.execute('''
    INSERT INTO form_responses (
      id, form_type, form_id, entry_id, project_id,
      header_data, response_data, table_rows, response_metadata,
      status, created_at, updated_at, created_by_user_id,
      deleted_at, deleted_by
    )
    SELECT
      id, form_type, form_id, entry_id, project_id,
      header_data, response_data, table_rows, response_metadata,
      status, created_at, updated_at, created_by_user_id,
      deleted_at, deleted_by
    FROM form_responses_old
  ''');

  // Step 5: Drop old table
  await db.execute('DROP TABLE form_responses_old');

  // Step 6: Recreate ALL 6 indexes (table rebuild drops them)
  // NOTE: Must match toolbox_tables.dart indexes list exactly
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_form_responses_type '
    'ON form_responses(form_type)'
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_form_responses_form '
    'ON form_responses(form_id)'
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_form_responses_entry '
    'ON form_responses(entry_id)'
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_form_responses_project '
    'ON form_responses(project_id)'
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_form_responses_status '
    'ON form_responses(status)'
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_form_responses_deleted_at '
    'ON form_responses(deleted_at)'
  );

  // Step 7: Recreate change_log triggers (table rebuild destroys them)
  // NOTE: Uses SyncEngineTables.triggersForTable('form_responses') pattern.
  // form_responses is in triggeredTables but NOT in tablesWithDirectProjectId,
  // so project_id in change_log will be NULL for these triggers.
  for (final trigger in SyncEngineTables.triggersForTable('form_responses')) {
    await db.execute(trigger);
  }

  Logger.db('Migration v47: Rebuilt form_responses without form_type DEFAULT');
}
```

**IMPORTANT**: Before writing the migration, verify the exact column list and indexes on `form_responses` by reading `toolbox_tables.dart` to ensure the rebuilt table matches the canonical DDL exactly. The table rebuild destroys change_log triggers -- Step 7 above recreates them using `SyncEngineTables.triggersForTable('form_responses')`. The implementing agent must add the import: `import 'package:construction_inspector/core/database/schema/sync_engine_tables.dart';` at the top of the migration file or in database_service.dart if not already present.

#### Step 2.1.4: Audit all form_responses INSERT call sites for explicit form_type

Grep all `INSERT INTO form_responses` and all `db.insert('form_responses'` call sites across the codebase. Verify every one provides an explicit `form_type` value. Since the DEFAULT has been removed, any insert that omits `form_type` will now fail with a NOT NULL constraint violation.

```
# Audit commands for the implementing agent:
# Grep for raw SQL inserts:
#   pattern: "INSERT INTO form_responses"
# Grep for sqflite inserts:
#   pattern: "insert\('form_responses'"
# Grep for batch inserts:
#   pattern: "form_responses.*insert"
```

If any call site omits `form_type`, add the explicit value (typically `kFormTypeMdot0582b` for existing forms, or the appropriate constant for the form type being created).

> FROM SPEC: "Audit all INSERT INTO form_responses call sites to confirm they already provide explicit form_type"

#### Step 2.1.5: Update SchemaVerifier expectedSchema

In `schema_verifier.dart`, update the `_columnTypes` entry for `form_responses.form_type` (line 324):

```dart
// WHY: Migration v47 removed the DEFAULT — verifier must match
'form_type': 'TEXT NOT NULL',
```

#### Step 2.1.6: Verify test passes

Run: `pwsh -Command "flutter test test/core/database/migration_v47_test.dart"`
Expected: PASS

---

### Sub-phase 2.2: F11 — SchemaVerifier becomes report-only

**Files:**
- Modify: `lib/core/database/schema_verifier.dart:413-519`
- Modify: `lib/core/database/database_service.dart:73,93`
- Test: `test/core/database/schema_verifier_report_test.dart` (Phase 6)

**Agent**: `backend-data-layer-agent`

#### Step 2.2.1: Create SchemaReport class

Add to `schema_verifier.dart` (after the `ColumnDrift` class, before `SchemaVerifier`):

```dart
/// Report from schema verification — diagnostics only, no repair.
class SchemaReport {
  /// Columns that exist but have wrong type/default/nullability.
  final List<ColumnDrift> driftFindings;

  /// Columns expected but missing from the database.
  final List<({String table, String column, String type})> missingColumns;

  /// Tables expected but missing from the database.
  final List<String> missingTables;

  const SchemaReport({
    this.driftFindings = const [],
    this.missingColumns = const [],
    this.missingTables = const [],
  });

  /// True if any issues were found.
  bool get hasIssues =>
      driftFindings.isNotEmpty ||
      missingColumns.isNotEmpty ||
      missingTables.isNotEmpty;

  @override
  String toString() =>
      'SchemaReport(drift=${driftFindings.length}, '
      'missing_cols=${missingColumns.length}, '
      'missing_tables=${missingTables.length})';
}
```

#### Step 2.2.2: Refactor verify() to return SchemaReport

Replace the `verify()` method body (lines 413-519) to collect missing columns instead of repairing them:

```dart
// WHY: F11 — Migrations are authoritative. SchemaVerifier reports problems
// instead of silently patching. If a migration is skipped, the app logs
// clear warnings at startup.
static Future<SchemaReport> verify(Database db) async {
  final stopwatch = Stopwatch()..start();
  final driftFindings = <ColumnDrift>[];
  final missingColumns = <({String table, String column, String type})>[];
  final missingTables = <String>[];

  for (final entry in expectedSchema.entries) {
    final table = entry.key;
    final expectedColumns = entry.value;

    // Check if table exists
    final tableCheck = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    if (tableCheck.isEmpty) {
      missingTables.add(table);
      Logger.db('SchemaVerifier: table $table does not exist');
      continue;
    }

    // Get actual columns
    final actualColumns = await db.rawQuery('PRAGMA table_info($table)');
    final actualByName = <String, Map<String, Object?>>{};
    for (final row in actualColumns) {
      actualByName[row['name'] as String] = row;
    }

    for (final col in expectedColumns) {
      if (!actualByName.containsKey(col)) {
        // IMPORTANT: Report missing column instead of repairing
        final colType = _columnTypes[table]?[col] ?? 'TEXT';
        missingColumns.add((table: table, column: col, type: colType));
        Logger.db('SchemaVerifier: missing column $table.$col ($colType)');
        continue;
      }

      // --- Definition drift detection (unchanged) ---
      final expectedDef = _columnTypes[table]?[col];
      if (expectedDef == null) continue;

      final actual = actualByName[col]!;
      final expected = _parseColumnDef(expectedDef);

      final actualType = (actual['type'] as String? ?? '').toUpperCase();
      if (actualType != expected.type) {
        driftFindings.add(ColumnDrift(
          table: table, column: col, field: 'type',
          expected: expected.type, actual: actualType,
        ));
        Logger.db('SchemaVerifier: drift — ${driftFindings.last}');
      }

      final actualNotnull = actual['notnull'] as int? ?? 0;
      if (actualNotnull != expected.notnull) {
        driftFindings.add(ColumnDrift(
          table: table, column: col, field: 'notnull',
          expected: '${expected.notnull}', actual: '$actualNotnull',
        ));
        Logger.db('SchemaVerifier: drift — ${driftFindings.last}');
      }

      final actualDefault = actual['dflt_value']?.toString();
      if (actualDefault != expected.dfltValue) {
        driftFindings.add(ColumnDrift(
          table: table, column: col, field: 'dflt_value',
          expected: '${expected.dfltValue}', actual: '$actualDefault',
        ));
        Logger.db('SchemaVerifier: drift — ${driftFindings.last}');
      }
    }
  }

  stopwatch.stop();
  final report = SchemaReport(
    driftFindings: driftFindings,
    missingColumns: missingColumns,
    missingTables: missingTables,
  );
  Logger.db(
    'SchemaVerifier: verified ${expectedSchema.length} tables '
    'in ${stopwatch.elapsedMilliseconds}ms — $report',
  );

  return report;
}
```

#### Step 2.2.3: Update callers in database_service.dart

At lines 73 and 93, update to handle `SchemaReport` instead of `List<ColumnDrift>`:

```dart
// WHY: SchemaVerifier now returns SchemaReport (report-only, no repair).
// Missing columns/tables are logged as warnings for investigation.
final report = await SchemaVerifier.verify(db);
if (report.hasIssues) {
  Logger.db('SchemaVerifier found issues: $report');
  if (report.missingColumns.isNotEmpty) {
    Logger.db('WARNING: ${report.missingColumns.length} missing columns detected. '
        'Check migration history.');
  }
  if (report.missingTables.isNotEmpty) {
    Logger.db('WARNING: ${report.missingTables.length} missing tables detected. '
        'Check migration history.');
  }
}
```

#### Step 2.2.4: Update existing schema_verifier_drift_test.dart

The existing test imports `SchemaVerifier` and checks `verify()` return. Update assertions to use `SchemaReport` instead of `List<ColumnDrift>`:
- `report.driftFindings` instead of the raw list
- Add assertion that missing columns appear in `report.missingColumns` instead of being silently repaired

#### Step 2.2.5: Verify Phase 2 complete

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

## Phase 3: Boundary Fixes

### Sub-phase 3.1: F4/F7 — Extend UserCertificationLocalDatasource

**Files:**
- Modify: `lib/features/settings/data/datasources/local/user_certification_local_datasource.dart`
- Modify: `lib/features/auth/data/datasources/remote/user_profile_sync_datasource.dart:86-101`
- Modify: `lib/features/sync/di/sync_initializer.dart` (inject datasource)
- Test: `test/features/settings/data/datasources/local/user_certification_local_datasource_test.dart` (Phase 6)

**Agent**: `backend-data-layer-agent`

> **FLAG-1 RESOLUTION**: The spec proposed creating a new file in `auth/`. Per tailor FLAG-1, a `UserCertificationLocalDatasource` already exists at `lib/features/settings/data/datasources/local/`. We extend it with upsert/delete methods instead of creating a duplicate.

#### Step 3.1.1: Write failing test for upsert/delete methods

Create `test/features/settings/data/datasources/local/user_certification_local_datasource_test.dart`:

```dart
// WHY: F4/F7 — Validates the new upsert and delete methods added to
// the existing UserCertificationLocalDatasource.
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/features/settings/data/datasources/local/user_certification_local_datasource.dart';

void main() {
  late DatabaseService dbService;
  late UserCertificationLocalDatasource datasource;

  setUp(() async {
    dbService = DatabaseService.forTesting();
    datasource = UserCertificationLocalDatasource(dbService);
  });

  test('upsertCertifications inserts rows', () async {
    // NOTE: cert_number is NOT NULL in user_certifications schema
    // (see sync_engine_tables.dart createUserCertificationsTable)
    final rows = [
      {
        'id': 'cert-1',
        'user_id': 'user-1',
        'cert_type': 'OSHA-30',
        'cert_number': 'OSH-2024-001',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];
    await datasource.upsertCertifications(rows);
    final result = await datasource.getByUserId('user-1');
    expect(result.length, 1);
  });

  test('upsertCertifications replaces on conflict', () async {
    final rows = [
      {
        'id': 'cert-1',
        'user_id': 'user-1',
        'cert_type': 'OSHA-30',
        'cert_number': 'OSH-2024-001',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];
    await datasource.upsertCertifications(rows);
    // Update cert_type
    rows[0]['cert_type'] = 'OSHA-10';
    await datasource.upsertCertifications(rows);
    final result = await datasource.getByUserId('user-1');
    expect(result.length, 1);
    expect(result.first.certType, 'OSHA-10');
  });

  test('deleteCertificationsForUser removes user rows only', () async {
    final rows = [
      {
        'id': 'cert-1',
        'user_id': 'user-1',
        'cert_type': 'OSHA-30',
        'cert_number': 'OSH-2024-001',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'cert-2',
        'user_id': 'user-2',
        'cert_type': 'First Aid',
        'cert_number': 'FA-2024-002',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];
    await datasource.upsertCertifications(rows);
    await datasource.deleteCertificationsForUser('user-1');
    final result1 = await datasource.getByUserId('user-1');
    final result2 = await datasource.getByUserId('user-2');
    expect(result1, isEmpty);
    expect(result2.length, 1);
  });
}
```

#### Step 3.1.2: Verify test fails

Run: `pwsh -Command "flutter test test/features/settings/data/datasources/local/user_certification_local_datasource_test.dart"`
Expected: FAIL — methods don't exist yet

#### Step 3.1.3: Add upsert and delete methods

In `user_certification_local_datasource.dart`, add:

```dart
/// WHY: F4/F7 — Encapsulates cert writes that were previously raw SQL
/// in UserProfileSyncDatasource.pullUserCertifications().
/// Uses ConflictAlgorithm.replace for upsert semantics (matches sync pattern).
Future<void> upsertCertifications(List<Map<String, dynamic>> rows) async {
  final db = await _db.database;
  final batch = db.batch();
  for (final row in rows) {
    batch.insert('user_certifications', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
  await batch.commit(noResult: true);
}

/// WHY: Clean delete for user-scoped cert replacement during sync pull.
Future<void> deleteCertificationsForUser(String userId) async {
  final db = await _db.database;
  await db.delete('user_certifications',
      where: 'user_id = ?', whereArgs: [userId]);
}
```

Add the necessary import at top: `import 'package:sqflite/sqflite.dart';`

#### Step 3.1.4: Verify test passes

Run: `pwsh -Command "flutter test test/features/settings/data/datasources/local/user_certification_local_datasource_test.dart"`
Expected: PASS

#### Step 3.1.5: Refactor UserProfileSyncDatasource to delegate

In `user_profile_sync_datasource.dart`:

1. Add constructor param for `UserCertificationLocalDatasource`
2. Refactor `pullUserCertifications` (lines 86-101) to delegate:

```dart
// WHY: F4/F7 — Delegate cert persistence to UserCertificationLocalDatasource
// instead of raw db.insert. Centralizes cert writes behind a single datasource.
final UserCertificationLocalDatasource? _certLocalDatasource;

// Update constructor to accept it:
UserProfileSyncDatasource(
  this._client,
  this._userProfileLocalDatasource, {
  CompanyLocalDatasource? companyLocalDatasource,
  DatabaseService? dbService,
  UserCertificationLocalDatasource? certLocalDatasource,
}) : _companyLocalDatasource = companyLocalDatasource,
     _dbService = dbService,
     _certLocalDatasource = certLocalDatasource;

// Refactored method:
Future<void> pullUserCertifications(String userId) async {
    final response = await _client
        .from('user_certifications').select().eq('user_id', userId);

    if (_certLocalDatasource != null) {
      await _certLocalDatasource.upsertCertifications(
        (response as List).cast<Map<String, dynamic>>(),
      );
    } else {
      // WHY: SEC-A2 — No raw-SQL fallback path. If the datasource is null,
      // log a warning and skip the cert pull rather than bypassing the datasource layer.
      Logger.sync('WARNING: pullUserCertifications skipped — '
          'certLocalDatasource is null. Ensure DI wiring is complete.');
    }
}
```

#### Step 3.1.6: Wire datasource in SyncInitializer

> NOTE: Spec says inject via AuthInitializer. Plan injects via SyncInitializer because
> the consumer (UserProfileSyncDatasource) is constructed here. This is a deliberate
> deviation -- the datasource is wired where its consumer lives.

In `sync_initializer.dart`, inside the `if (supabaseClient != null)` block (~line 46), add the cert datasource:

```dart
// WHY: F4/F7 — Wire UserCertificationLocalDatasource into sync datasource
// so cert pulls go through the proper datasource instead of raw SQL.
final certLocalDs = UserCertificationLocalDatasource(dbService);
final userProfileSyncDs = UserProfileSyncDatasource(
  supabaseClient,
  userProfileLocalDs,
  companyLocalDatasource: companyLocalDs,
  dbService: dbService,
  certLocalDatasource: certLocalDs,
);
```

Add import: `import 'package:construction_inspector/features/settings/data/datasources/local/user_certification_local_datasource.dart';`

#### Step 3.1.7: Verify no breakage

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

### Sub-phase 3.2: F14 — Create EntryContractorsRepository

**Files:**
- Create: `lib/features/entries/data/repositories/entry_contractors_repository.dart`
- Modify: `lib/features/entries/presentation/controllers/contractor_editing_controller.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_contractors_section.dart`
- Modify: `lib/features/entries/presentation/controllers/pdf_data_builder.dart`
- Modify: `lib/features/entries/presentation/screens/home_screen.dart`
- Modify: `lib/features/entries/presentation/screens/entry_editor_screen.dart`
- Modify: `lib/features/entries/di/entries_providers.dart`

**Agent**: `backend-data-layer-agent`

#### Step 3.2.1: Create EntryContractorsRepository

Create `lib/features/entries/data/repositories/entry_contractors_repository.dart`:

```dart
// WHY: F14 — Presentation layer was importing datasource types directly,
// violating the architecture boundary. This repository wraps the 3 contractor-
// related datasources behind a domain API.
// NOTE: Matches repository pattern from FormResponseRepositoryImpl.
// NOTE: Method signatures match the ACTUAL datasource APIs (verified from source).
import 'package:construction_inspector/features/contractors/data/datasources/local/entry_contractors_local_datasource.dart';
import 'package:construction_inspector/features/contractors/data/datasources/local/entry_equipment_local_datasource.dart';
import 'package:construction_inspector/features/contractors/data/datasources/local/entry_personnel_counts_local_datasource.dart';
import 'package:construction_inspector/features/contractors/data/models/models.dart';

class EntryContractorsRepository {
  final EntryContractorsLocalDatasource _contractorsDatasource;
  final EntryEquipmentLocalDatasource _equipmentDatasource;
  final EntryPersonnelCountsLocalDatasource _personnelCountsDatasource;

  EntryContractorsRepository({
    required EntryContractorsLocalDatasource contractorsDatasource,
    required EntryEquipmentLocalDatasource equipmentDatasource,
    required EntryPersonnelCountsLocalDatasource personnelCountsDatasource,
  })  : _contractorsDatasource = contractorsDatasource,
        _equipmentDatasource = equipmentDatasource,
        _personnelCountsDatasource = personnelCountsDatasource;

  // --- Contractors (entry-scoped junction table) ---
  // WHY: EntryContractorsLocalDatasource uses entry-scoped APIs, NOT generic CRUD.
  // The table is a junction table (entry_contractors) with add/remove semantics.
  Future<List<EntryContractor>> getByEntryId(String entryId) =>
      _contractorsDatasource.getByEntryId(entryId);

  Future<List<String>> getContractorIdsByEntryId(String entryId) =>
      _contractorsDatasource.getContractorIdsByEntryId(entryId);

  Future<bool> exists(String entryId, String contractorId) =>
      _contractorsDatasource.exists(entryId, contractorId);

  Future<void> addContractor(String entryId, String contractorId) =>
      _contractorsDatasource.add(entryId, contractorId);

  Future<void> removeContractor(String entryId, String contractorId) =>
      _contractorsDatasource.remove(entryId, contractorId);

  Future<void> removeAllContractorsForEntry(String entryId) =>
      _contractorsDatasource.removeAllForEntry(entryId);

  Future<void> setContractorsForEntry(String entryId, List<String> contractorIds) =>
      _contractorsDatasource.setForEntry(entryId, contractorIds);

  // --- Equipment (entry-scoped) ---
  Future<List<EntryEquipment>> getEquipmentByEntryId(String entryId) =>
      _equipmentDatasource.getByEntryId(entryId);

  Future<List<String>> getUsedEquipmentIds(String entryId) =>
      _equipmentDatasource.getUsedEquipmentIds(entryId);

  Future<void> upsertEquipment(EntryEquipment item) =>
      _equipmentDatasource.upsert(item);

  Future<void> saveEquipmentForEntry(String entryId, List<EntryEquipment> equipment,
      {String? deletedBy}) =>
      _equipmentDatasource.saveForEntry(entryId, equipment, deletedBy: deletedBy);

  Future<void> softDeleteEquipmentByEntryId(String entryId, {String? userId}) =>
      _equipmentDatasource.softDeleteByEntryId(entryId, userId: userId);

  // --- Personnel Counts (entry+contractor scoped) ---
  // WHY: Returns Map<String, Map<String, int>> (contractorId -> typeId -> count),
  // NOT a list of model objects. This is the actual datasource API.
  Future<Map<String, Map<String, int>>> getCountsByEntryId(String entryId) =>
      _personnelCountsDatasource.getCountsByEntryId(entryId);

  Future<void> saveCountsForEntryContractor(
    String entryId,
    String contractorId,
    Map<String, int> counts, {
    String? projectId,
    String? createdByUserId,
    String? deletedBy,
  }) =>
      _personnelCountsDatasource.saveCountsForEntryContractor(
        entryId, contractorId, counts,
        projectId: projectId,
        createdByUserId: createdByUserId,
        deletedBy: deletedBy,
      );

  Future<void> deleteCountsByEntryId(String entryId, {String? deletedBy}) =>
      _personnelCountsDatasource.deleteCountsByEntryId(entryId, deletedBy: deletedBy);

  Future<int> getTotalCountForEntry(String entryId) =>
      _personnelCountsDatasource.getTotalCountForEntry(entryId);
}
```

#### Step 3.2.2: Blast-radius verification + Update entries_providers.dart

**Before modifying providers**, grep for ALL consumers of the 3 datasource types to verify the full consumer list. There are 5 known presentation-layer consumers (not 4):

```
# Blast-radius check — find all consumers:
# pattern: "EntryContractorsLocalDatasource"
# pattern: "EntryEquipmentLocalDatasource"
# pattern: "EntryPersonnelCountsLocalDatasource"
# Search in: lib/features/entries/presentation/
```

Known consumers (5 total):
1. `contractor_editing_controller.dart` — constructor injection
2. `entry_contractors_section.dart` — widget param
3. `pdf_data_builder.dart` — method param
4. `home_screen.dart` — context.read
5. `entry_editor_screen.dart` — context.read

> **NOTE (CR-11):** Because there are 5+ consumers of the individual datasource types, KEEP BOTH
> the repository Provider AND the 3 individual datasource Providers in `entries_providers.dart`.
> The repository is for NEW code and incremental migration; existing consumers can migrate
> one at a time without breaking. Only remove the individual datasource Providers once all
> consumers have been migrated to the repository.

In `entries_providers.dart`:

1. Add import for `EntryContractorsRepository`
2. Construct the repository from the 3 datasource params
3. ADD the repository Provider alongside (NOT replacing) the 3 individual datasource Providers:

```dart
// WHY: F14 — Expose repository for new code while keeping individual datasource
// Providers for incremental migration of 5 existing consumers.
final entryContractorsRepository = EntryContractorsRepository(
  contractorsDatasource: entryContractorsDatasource,
  equipmentDatasource: entryEquipmentDatasource,
  personnelCountsDatasource: entryPersonnelCountsDatasource,
);

// In the return list, ADD (do not replace existing datasource Providers):
Provider<EntryContractorsRepository>.value(value: entryContractorsRepository),
// KEEP existing:
// Provider<EntryContractorsLocalDatasource>.value(value: entryContractorsDatasource),
// Provider<EntryEquipmentLocalDatasource>.value(value: entryEquipmentDatasource),
// Provider<EntryPersonnelCountsLocalDatasource>.value(value: entryPersonnelCountsDatasource),
```

Keep the 3 datasource params in `entryProviders()` function signature — they're still needed to construct the repository.

#### Step 3.2.3: Update ContractorEditingController

In `contractor_editing_controller.dart`, change constructor to take `EntryContractorsRepository` instead of 3 datasources:

```dart
// WHY: F14 — Controller now depends on repository, not raw datasources.
ContractorEditingController({
  required EntryContractorsRepository contractorsRepository,
})
```

Update all internal method calls to use repository methods instead of direct datasource calls. The implementing agent must read the full controller to identify all call sites.

#### Step 3.2.4: Update EntryContractorsSection

In `entry_contractors_section.dart`, change the widget param from `EntryContractorsLocalDatasource` to `EntryContractorsRepository`.

#### Step 3.2.5: Update PdfDataBuilder

In `pdf_data_builder.dart`, change method params from individual datasource types to `EntryContractorsRepository`.

#### Step 3.2.6: Update home_screen.dart

Replace `context.read` calls (lines 186-188):

```dart
// WHY: F14 — Read repository instead of raw datasources
// BEFORE:
// context.read<EntryPersonnelCountsLocalDatasource>()
// context.read<EntryEquipmentLocalDatasource>()
// context.read<EntryContractorsLocalDatasource>()
// AFTER:
context.read<EntryContractorsRepository>()
```

Pass the single repository to `ContractorEditingController` and other consumers.

#### Step 3.2.7: Update entry_editor_screen.dart

> **NOTE (CR-11):** This is a 5th consumer of the datasource types, missed in the original plan.

In `entry_editor_screen.dart`, replace `context.read` calls for the 3 datasource types with
`context.read<EntryContractorsRepository>()`. The implementing agent must grep for all
`EntryContractorsLocalDatasource`, `EntryEquipmentLocalDatasource`, and
`EntryPersonnelCountsLocalDatasource` references in this file and migrate them to repository calls.

#### Step 3.2.8: Update contractor_editing_controller_test.dart

Update test setup to construct `EntryContractorsRepository` from the 3 datasources and pass it to the controller.

#### Step 3.2.9: Verify Phase 3 complete

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

## Phase 4: Structural

### Sub-phase 4.1: F5 — Extract SyncEngineFactory

**Files:**
- Create: `lib/features/sync/application/sync_engine_factory.dart`
- Modify: `lib/features/sync/application/sync_orchestrator.dart:195` (use factory)
- Modify: `lib/features/sync/application/background_sync_handler.dart:164` (use factory)

**Agent**: `backend-supabase-agent`

#### Step 4.1.1: Write failing test for SyncEngineFactory

Create `test/features/sync/application/sync_engine_factory_test.dart`:

```dart
// WHY: F5 — Verifies the factory creates a configured engine with adapters.
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/features/sync/application/sync_engine_factory.dart';
import 'package:construction_inspector/features/sync/engine/sync_registry.dart';

void main() {
  test('SyncEngineFactory.create registers adapters and returns engine', () async {
    final dbService = DatabaseService.forTesting();
    final db = await dbService.database;

    // NOTE: Cannot create real SyncEngine without Supabase client.
    // Verify factory registers adapters.
    // NOTE (CR-13): Factory create() and createForBackground() paths require
    // a live Supabase client and cannot be unit-tested here. They are covered
    // indirectly by existing sync_engine tests. The implementing agent may add
    // integration-level coverage if desired.
    final factory = SyncEngineFactory();
    factory.ensureAdaptersRegistered();
    expect(SyncRegistry.instance.adapters, isNotEmpty);
  });
}
```

#### Step 4.1.2: Create SyncEngineFactory

Create `lib/features/sync/application/sync_engine_factory.dart`:

```dart
// WHY: F5 — Centralizes sync engine creation logic that was duplicated between
// SyncOrchestrator._createEngine() and BackgroundSyncHandler._performDesktopSync().
// NOTE: Matches sync-engine-creation pattern from tailor.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:construction_inspector/features/sync/engine/sync_engine.dart';
import 'package:construction_inspector/features/sync/engine/sync_registry.dart';

class SyncEngineFactory {
  bool _adaptersRegistered = false;

  /// Ensure sync adapters are registered (idempotent).
  void ensureAdaptersRegistered() {
    if (!_adaptersRegistered) {
      registerSyncAdapters();
      _adaptersRegistered = true;
    }
  }

  /// Create a SyncEngine for foreground sync operations.
  ///
  /// NOTE: SyncEngine constructor requires db, supabase, companyId, userId
  /// (see sync_engine.dart lines 153-160). lockedBy defaults to 'foreground'.
  Future<SyncEngine?> create({
    required Database db,
    required SupabaseClient supabase,
    required String companyId,
    required String userId,
  }) async {
    ensureAdaptersRegistered();
    return SyncEngine(
      db: db,
      supabase: supabase,
      companyId: companyId,
      userId: userId,
    );
  }

  /// Create a SyncEngine for background sync operations.
  ///
  /// Delegates to [SyncEngine.createForBackgroundSync] which resolves
  /// companyId/userId internally from the Supabase auth session.
  /// WHY: createForBackgroundSync only takes {database, supabase} —
  /// it reads userId from auth and companyId from user_profiles.
  Future<SyncEngine?> createForBackground({
    required Database database,
    required SupabaseClient supabase,
  }) async {
    ensureAdaptersRegistered();
    return SyncEngine.createForBackgroundSync(
      database: database,
      supabase: supabase,
    );
  }
}
```

**IMPORTANT**: The implementing agent must read `SyncEngine` constructor and `createForBackgroundSync` to verify the exact params and return types before writing this factory.

#### Step 4.1.3: Verify test passes

Run: `pwsh -Command "flutter test test/features/sync/application/sync_engine_factory_test.dart"`
Expected: PASS

#### Step 4.1.4: Refactor SyncOrchestrator._createEngine to use factory

In `sync_orchestrator.dart`, add a `SyncEngineFactory` field and update `_createEngine()`:

```dart
// WHY: F5 — Factory centralizes engine creation, eliminating duplication.
final SyncEngineFactory _engineFactory;

// Update constructor to accept factory:
SyncOrchestrator(this._dbService, {
  SupabaseClient? supabaseClient,
  SyncEngineFactory? engineFactory,
}) : _supabaseClient = supabaseClient,
     _engineFactory = engineFactory ?? SyncEngineFactory() {
  // ... existing mock mode logic
}

// Update _createEngine:
Future<SyncEngine?> _createEngine() async {
  // ... keep existing auth context retry logic (lines 196-219) ...

  final db = await _dbService.database;
  // WHY: SyncEngine constructor requires companyId and userId (see sync_engine.dart:153-160).
  // The syncContextProvider callback returns live values from AuthProvider.
  final ctx = _syncContextProvider();
  if (ctx.companyId == null || ctx.userId == null) return null;
  return _engineFactory.create(
    db: db,
    supabase: _supabaseClient!,
    companyId: ctx.companyId!,
    userId: ctx.userId!,
  );
}
```

Remove the standalone `registerSyncAdapters()` call from `initialize()` (line 165) since the factory handles it.

#### Step 4.1.5: Refactor BackgroundSyncHandler to use factory

In `background_sync_handler.dart`, update `_performDesktopSync()` to use factory:

```dart
// WHY: F5 — Use shared factory instead of direct SyncEngine.createForBackgroundSync
static SyncEngineFactory? _engineFactory;

// In initialization, accept factory:
// ... and in _performDesktopSync:
final factory = _engineFactory ?? SyncEngineFactory();
// WHY: createForBackgroundSync resolves companyId/userId internally from
// the Supabase auth session — callers only provide database + supabase.
final engine = await factory.createForBackground(
  database: db,
  supabase: client,
);
```

**NOTE**: The mobile isolate path (`backgroundSyncCallback`) cannot use the factory because it runs in a separate isolate with its own bootstrap. This is by design — platform constraint documented in spec.

#### Step 4.1.6: Verify no breakage

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

### Sub-phase 4.2: F9 — SyncOrchestrator Builder Pattern

**Files:**
- Create: `lib/features/sync/application/sync_orchestrator_builder.dart`
- Modify: `lib/features/sync/application/sync_orchestrator.dart` (private constructor, remove setters)
- Modify: `lib/features/sync/di/sync_initializer.dart` (use builder)

**Agent**: `backend-supabase-agent`

#### Step 4.2.1: Write failing test for SyncOrchestratorBuilder

Create `test/features/sync/application/sync_orchestrator_builder_test.dart`:

```dart
// WHY: F9 — Verifies builder enforces required fields and produces
// a fully configured orchestrator.
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/features/sync/application/sync_orchestrator_builder.dart';

void main() {
  late DatabaseService dbService;

  setUp(() async {
    dbService = DatabaseService.forTesting();
  });

  test('build() succeeds with all required fields', () {
    final builder = SyncOrchestratorBuilder()
      ..dbService = dbService
      ..syncContextProvider = () => (companyId: null, userId: null);

    final orchestrator = builder.build();
    expect(orchestrator, isNotNull);
  });

  test('build() throws when dbService is missing', () {
    final builder = SyncOrchestratorBuilder()
      ..syncContextProvider = () => (companyId: null, userId: null);

    expect(() => builder.build(), throwsStateError);
  });

  test('build() throws when syncContextProvider is missing', () {
    final builder = SyncOrchestratorBuilder()
      ..dbService = dbService;

    expect(() => builder.build(), throwsStateError);
  });

  test('optional supabaseClient defaults to null', () {
    final builder = SyncOrchestratorBuilder()
      ..dbService = dbService
      ..syncContextProvider = () => (companyId: null, userId: null);

    // Should create orchestrator in offline/mock mode
    final orchestrator = builder.build();
    expect(orchestrator, isNotNull);
  });
}
```

#### Step 4.2.2: Verify test fails

Run: `pwsh -Command "flutter test test/features/sync/application/sync_orchestrator_builder_test.dart"`
Expected: FAIL — builder doesn't exist yet

#### Step 4.2.3: Create SyncOrchestratorBuilder

Create `lib/features/sync/application/sync_orchestrator_builder.dart`:

```dart
// WHY: F9 — Eliminates post-construction setters on SyncOrchestrator.
// All required deps are validated at build() time, preventing partial-state bugs.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/features/auth/data/datasources/remote/user_profile_sync_datasource.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';
import 'package:construction_inspector/features/sync/application/sync_engine_factory.dart';
import 'package:construction_inspector/features/sync/application/sync_orchestrator.dart';

class SyncOrchestratorBuilder {
  DatabaseService? dbService;
  SupabaseClient? supabaseClient;
  SyncEngineFactory? engineFactory;
  UserProfileSyncDatasource? userProfileSyncDatasource;
  ({String? companyId, String? userId}) Function()? syncContextProvider;
  AppConfigProvider? appConfigProvider;
  String? companyId;
  String? userId;

  // WHY: SEC-A3 — Prevent accidental reuse of a builder after build().
  // A builder that has already produced an orchestrator should not be
  // mutated and built again, as that could lead to shared-state bugs.
  bool _built = false;

  /// Build a fully configured [SyncOrchestrator].
  ///
  /// Throws [StateError] if required fields are not set or if called twice.
  SyncOrchestrator build() {
    if (_built) {
      throw StateError('SyncOrchestratorBuilder: build() already called. '
          'Create a new builder for each orchestrator instance.');
    }
    if (dbService == null) {
      throw StateError('SyncOrchestratorBuilder: dbService is required');
    }
    if (syncContextProvider == null) {
      throw StateError('SyncOrchestratorBuilder: syncContextProvider is required');
    }

    _built = true;
    return SyncOrchestrator.fromBuilder(
      dbService: dbService!,
      supabaseClient: supabaseClient,
      engineFactory: engineFactory ?? SyncEngineFactory(),
      userProfileSyncDatasource: userProfileSyncDatasource,
      syncContextProvider: syncContextProvider!,
      appConfigProvider: appConfigProvider,
      companyId: companyId,
      userId: userId,
    );
  }
}
```

#### Step 4.2.4: Refactor SyncOrchestrator constructor

In `sync_orchestrator.dart`:

1. Make current constructor private: `SyncOrchestrator._internal(...)`
2. Add named constructor `fromBuilder` that takes all deps as final fields:

```dart
// WHY: F9 — All deps are final, set at construction time via builder.
// No more nullable late-bound fields or post-construction setters.
final SyncEngineFactory _engineFactory;
final UserProfileSyncDatasource? _userProfileSyncDatasource;
final ({String? companyId, String? userId}) Function() _syncContextProvider;
final AppConfigProvider? _appConfigProvider;

/// Internal constructor — use [SyncOrchestratorBuilder] for production code.
SyncOrchestrator.fromBuilder({
  required DatabaseService dbService,
  SupabaseClient? supabaseClient,
  required SyncEngineFactory engineFactory,
  UserProfileSyncDatasource? userProfileSyncDatasource,
  required ({String? companyId, String? userId}) Function() syncContextProvider,
  AppConfigProvider? appConfigProvider,
  String? companyId,
  String? userId,
}) : _dbService = dbService,
     _supabaseClient = supabaseClient,
     _engineFactory = engineFactory,
     _userProfileSyncDatasource = userProfileSyncDatasource,
     _syncContextProvider = syncContextProvider,
     _appConfigProvider = appConfigProvider,
     _companyId = companyId,
     _userId = userId {
  if (_isMockMode) {
    _mockAdapter = MockSyncAdapter();
  }
}
```

3. Remove the 4 setter methods (lines 119-138):
   - `setUserProfileSyncDatasource`
   - `setSyncContextProvider`
   - `setAppConfigProvider`
   - `setAdapterCompanyContext`

4. Keep `forTesting` constructor (will be moved to test helper in Phase 6):
```dart
/// Test-only constructor — bypasses builder for unit tests.
SyncOrchestrator.forTesting(this._dbService)
    : _supabaseClient = null,
      _engineFactory = SyncEngineFactory(),
      _userProfileSyncDatasource = null,
      _syncContextProvider = (() => (companyId: null, userId: null)),
      _appConfigProvider = null,
      _companyId = null,
      _userId = null {
  _mockAdapter = MockSyncAdapter();
}
```

5. Update `_syncContextProvider` usage: anywhere that reads `_companyId`/`_userId` (e.g., `_createEngine`) should call `_syncContextProvider()` to get fresh values. The `setAdapterCompanyContext` calls in SyncInitializer used to update `_companyId`/`_userId` directly — now the context provider callback returns live values.

**IMPORTANT**: The implementing agent must carefully audit ALL references to `_companyId`, `_userId`, `_userProfileSyncDatasource`, `_syncContextProvider`, and `_appConfigProvider` throughout the orchestrator to ensure they work with the new final-field + callback pattern. Key locations: `_createEngine()`, `_doSync()`, `_handleSyncComplete()`.

#### Step 4.2.5: Verify builder test passes

Run: `pwsh -Command "flutter test test/features/sync/application/sync_orchestrator_builder_test.dart"`
Expected: PASS

#### Step 4.2.6: Verify no breakage

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

### Sub-phase 4.3: F9 cont + A6 — Refactor SyncInitializer to use builder

**Files:**
- Modify: `lib/features/sync/di/sync_initializer.dart`
- Modify: `lib/features/sync/di/sync_providers.dart` (if needed)
- Modify: `lint_baseline.json`

**Agent**: `backend-supabase-agent`

#### Step 4.3.1: Refactor SyncInitializer.create() to use builder

Replace the multi-step setter pattern with builder:

```dart
// WHY: F9 + A6 — Builder replaces setter injection. Async wiring moved
// out of DI layer to reduce no_business_logic_in_di violations.
static Future<({
  SyncOrchestrator orchestrator,
  SyncLifecycleManager lifecycleManager,
})> create({
  required DatabaseService dbService,
  required AuthProvider authProvider,
  required AppConfigProvider appConfigProvider,
  required CompanyLocalDatasource companyLocalDs,
  required AuthService authService,
  SupabaseClient? supabaseClient,
}) async {
  // Step 1: Prepare builder
  final builder = SyncOrchestratorBuilder()
    ..dbService = dbService
    ..supabaseClient = supabaseClient
    ..appConfigProvider = appConfigProvider
    ..syncContextProvider = () => (
          companyId: authProvider.userProfile?.companyId,
          userId: authProvider.userId,
        )
    ..companyId = authProvider.userProfile?.companyId
    ..userId = authProvider.userId;

  // Step 2: Wire UserProfileSyncDatasource if online
  if (supabaseClient != null) {
    final userProfileLocalDs = UserProfileLocalDatasource(dbService);
    final certLocalDs = UserCertificationLocalDatasource(dbService);
    final userProfileSyncDs = UserProfileSyncDatasource(
      supabaseClient,
      userProfileLocalDs,
      companyLocalDatasource: companyLocalDs,
      dbService: dbService,
      certLocalDatasource: certLocalDs,
    );
    builder.userProfileSyncDatasource = userProfileSyncDs;
  }

  // Step 3: Build orchestrator (fully configured, no setters)
  final syncOrchestrator = builder.build();
  await syncOrchestrator.initialize();

  // Step 4: Create lifecycle manager
  final syncLifecycleManager = SyncLifecycleManager(syncOrchestrator);

  // Step 5: Wire auth listener for context updates
  // NOTE: The builder's syncContextProvider callback returns live values
  // from authProvider, so we don't need setAdapterCompanyContext anymore.
  // But we still listen for auth changes to update companyId/userId
  // on the orchestrator if it stores them for non-callback usage.

  // Step 6: Wire enrollment service
  final enrollmentService = SyncEnrollmentService(
    dbService: dbService,
    orchestrator: syncOrchestrator,
  );
  syncOrchestrator.onPullComplete = (tableName, pulledCount) async {
    if (tableName != 'project_assignments') return;
    if (pulledCount == 0) return;
    final userId = authProvider.userId;
    if (userId == null) return;
    await enrollmentService.handleAssignmentPull(userId: userId);
  };

  // Step 7: FCM initialization (mobile only, non-blocking)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    final fcmHandler = FcmHandler(
        authService: authService, syncOrchestrator: syncOrchestrator);
    fcmHandler
        .initialize(userId: authProvider.userId)
        .catchError((e) => Logger.sync('FCM init failed: $e'));
  }

  // Step 8: Wire lifecycle callbacks
  syncLifecycleManager.isReadyForSync = () {
    return authProvider.isAuthenticated &&
        authProvider.userProfile?.companyId != null;
  };

  syncLifecycleManager.onAppResumed = () async {
    if (!authProvider.isAuthenticated) return;
    final timedOut = await authProvider.checkInactivityTimeout();
    if (timedOut) return;
    await authProvider.updateLastActive();
    if (appConfigProvider.isRefreshDue) {
      await appConfigProvider.checkConfig();
      if (appConfigProvider.requiresReauth) {
        await authProvider.handleForceReauth(appConfigProvider.reauthReason);
      }
    }
  };

  // Step 9: Register lifecycle observer
  WidgetsBinding.instance.addObserver(syncLifecycleManager);

  Logger.sync('SyncInitializer.create() complete');

  return (
    orchestrator: syncOrchestrator,
    lifecycleManager: syncLifecycleManager,
  );
}
```

**IMPORTANT**: The `onAppResumed` callback contains async logic that may still trigger A6 violations since it's in a DI file. The implementing agent should evaluate whether this callback can be extracted to an application-layer class. If it can't be cleanly extracted without over-engineering, leave it and update the baseline.

#### Step 4.3.2: Review sync_providers.dart for A6 violations

Read `sync_providers.dart` and evaluate whether remaining `await`/`try` blocks can move to the application layer. If they are purely DI wiring (Provider construction), they may be acceptable.

#### Step 4.3.3: Update lint_baseline.json

After the refactor, run custom lints and update the baseline to reflect reduced violation counts:
- `sync_initializer.dart`: target 6→0 (or as low as achievable)
- `sync_providers.dart`: target 2→0 (or as low as achievable)

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

## Phase 5: Sign-Out Warning (BLOCKER-38)

### Sub-phase 5.1: SignOutDialog three-action variant

> **Architecture note**: The spec proposed checking unsynced changes in `SignOutUseCase`,
> but `SignOutUseCase` is constructed in `AuthInitializer` which runs BEFORE
> `SyncInitializer`. Injecting `SyncOrchestrator` into `SignOutUseCase` would create a
> circular initialization dependency. Instead, the dialog reads the orchestrator directly
> from Provider context. This is a deliberate deviation from the spec's layering suggestion,
> chosen to avoid circular init deps while preserving the same user-facing behavior.

**Files:**
- Modify: `lib/features/settings/presentation/widgets/sign_out_dialog.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 5.1.1: Convert SignOutDialog to StatefulWidget with unsynced check

```dart
// WHY: BLOCKER-38 — Show three-action dialog when unsynced changes exist.
// "Sign Out Anyway" is safe because BUG-17 ensures local data persists.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/shared/shared.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/sync/application/sync_orchestrator.dart';
import 'package:construction_inspector/features/sync/presentation/providers/sync_provider.dart';

class SignOutDialog extends StatefulWidget {
  const SignOutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SignOutDialog(),
    );
  }

  @override
  State<SignOutDialog> createState() => _SignOutDialogState();
}

class _SignOutDialogState extends State<SignOutDialog> {
  int _unsyncedCount = 0;
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _checkUnsyncedChanges();
  }

  Future<void> _checkUnsyncedChanges() async {
    try {
      final orchestrator = context.read<SyncOrchestrator>();
      final count = await orchestrator.getPendingCount();
      if (mounted) {
        setState(() {
          _unsyncedCount = count;
          _loading = false;
        });
      }
    // WHY: A9 lint rule — silent catch blocks are forbidden.
    // Log the error so debugging is possible when getPendingCount fails.
    } catch (e) {
      Logger.sync('SignOutDialog: getPendingCount failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthProvider>();
    final nav = GoRouter.of(context);
    Navigator.pop(context);
    final success = await auth.signOut();
    if (context.mounted) {
      if (success) {
        nav.go('/login');
      } else {
        SnackBarHelper.showError(context, 'Failed to sign out');
      }
    }
  }

  Future<void> _syncThenSignOut() async {
    setState(() => _syncing = true);
    try {
      final syncProvider = context.read<SyncProvider>();
      await syncProvider.sync();
    } catch (e) {
      // WHY: Sync failure should not silently proceed to sign-out.
      // Show error and let user decide.
      if (mounted) {
        setState(() => _syncing = false);
        SnackBarHelper.showError(context, 'Sync failed: $e');
        return; // Stay on dialog — user can tap "Sign Out Anyway" or "Cancel"
      }
    }
    if (mounted) await _signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_syncing) {
      return AlertDialog(
        title: const Text('Syncing...'),
        content: const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    }

    // No unsynced changes — standard dialog
    if (_unsyncedCount == 0) {
      return AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: TestingKeys.signOutConfirmButton,
            onPressed: _signOut,
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      );
    }

    // Unsynced changes exist — three-action dialog
    return AlertDialog(
      title: const Text('Unsynced Changes'),
      content: Text(
        'You have $_unsyncedCount unsynced change${_unsyncedCount == 1 ? '' : 's'}. '
        'Sync now before signing out?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _signOut,
          // NOTE: "Sign Out Anyway" is safe — BUG-17 ensures data persists.
          // Changes sync on next sign-in.
          child: const Text('Sign Out Anyway'),
        ),
        FilledButton(
          onPressed: _syncThenSignOut,
          child: const Text('Sync & Sign Out'),
        ),
      ],
    );
  }
}
```

**IMPORTANT**: The implementing agent must verify:
1. `SyncProvider` is available in the widget tree where `SignOutDialog` is shown
2. `SyncOrchestrator` is available via Provider
3. `SyncProvider.sync()` exists with the expected signature
4. The `TestingKeys.signOutConfirmButton` key is preserved on the appropriate button

#### Step 5.1.2: Verify Phase 5 complete

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

#### Step 5.1.3: Update _defects-auth.md BLOCKER-38 entry

Update `.claude/defects/_defects-auth.md` BLOCKER-38 entry:
- Mark the original data-wipe issue as resolved (clearLocalCompanyData no longer called from sign-out path)
- Note that SwitchCompanyUseCase is retained for sign-in company-switch detection (SEC-R1)
- Record that unsynced-change warning has been added to SignOutDialog
- Set status to FIXED with this PR's branch name

---

## Phase 6: Tests & Cleanup

### Sub-phase 6.1: New test files

**Files:**
- Create: `test/shared/datasources/base_remote_datasource_test.dart`
- Create: `test/features/auth/data/datasources/remote/user_profile_sync_datasource_test.dart`
- Create: `test/core/database/schema_verifier_report_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.1.1: Create base_remote_datasource_test.dart

```dart
// WHY: Spec requires test coverage for BaseRemoteDatasource constructor injection.
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/shared/datasources/base_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// NOTE: Implementing agent must create a concrete test subclass since
// BaseRemoteDatasource is abstract. Verify the exact constructor signature
// by reading base_remote_datasource.dart.

void main() {
  test('BaseRemoteDatasource subclass receives injected SupabaseClient', () {
    // Test that constructor injection works — the client is stored and accessible
    // to subclasses via the protected field.
    // Implementing agent: create a minimal concrete subclass for testing.
  });
}
```

**IMPORTANT**: Implementing agent must read `base_remote_datasource.dart` to understand the exact class structure, constructor, and protected field name before writing this test.

#### Step 6.1.2: Create user_profile_sync_datasource_test.dart

```dart
// WHY: Tests the refactored UserProfileSyncDatasource after F4/F7/F10 changes.
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test 1: updateLastSyncedAt calls RPC with no params (F10)
  // Test 2: pullUserCertifications delegates to certLocalDatasource (F4/F7)
  // Test 3: pullCompanyMembers delegates to local datasource

  // NOTE: These tests require mocking SupabaseClient. Implementing agent
  // must determine the mocking approach (mocktail or manual mock) based
  // on existing test patterns in the codebase.
}
```

#### Step 6.1.3: Create schema_verifier_report_test.dart

```dart
// WHY: Tests SchemaVerifier report-only behavior after F11 changes.
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/core/database/schema_verifier.dart';

void main() {
  late DatabaseService dbService;

  setUp(() async {
    dbService = DatabaseService.forTesting();
  });

  test('verify returns SchemaReport with no issues on healthy DB', () async {
    final db = await dbService.database;
    final report = await SchemaVerifier.verify(db);
    expect(report.missingColumns, isEmpty);
    expect(report.missingTables, isEmpty);
    // NOTE: driftFindings may or may not be empty depending on
    // SchemaVerifier.expectedSchema vs actual DDL alignment
  });

  test('verify detects missing columns without repairing', () async {
    final db = await dbService.database;
    // Drop a known column, then verify
    // NOTE: SQLite can't drop columns directly. Use table rebuild or
    // test with an in-memory DB that skips a migration.
    // Implementing agent: determine the best approach for this test.
  });

  test('SchemaReport.hasIssues returns true when issues exist', () {
    final report = SchemaReport(
      missingColumns: [(table: 'test', column: 'col', type: 'TEXT')],
    );
    expect(report.hasIssues, isTrue);
  });

  test('SchemaReport.hasIssues returns false when clean', () {
    const report = SchemaReport();
    expect(report.hasIssues, isFalse);
  });
}
```

---

### Sub-phase 6.2: Move forTesting to test helper

**Files:**
- Create: `test/helpers/sync_orchestrator_test_helper.dart`
- Modify: `lib/features/sync/application/sync_orchestrator.dart` (keep forTesting for now, add deprecation)
- Modify: 5 test files (update imports)

**Agent**: `qa-testing-agent`

> **FLAG-3 RESOLUTION**: 5 test files use `forTesting`, not 2 as spec originally stated.

#### Step 6.2.1: Create test helper

Create `test/helpers/sync_orchestrator_test_helper.dart`:

```dart
// WHY: Move test-only construction out of production code.
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/features/sync/application/sync_orchestrator.dart';

/// Creates a SyncOrchestrator configured for unit testing.
/// Uses MockSyncAdapter internally, bypassing Supabase.
SyncOrchestrator createTestOrchestrator(DatabaseService dbService) {
  return SyncOrchestrator.forTesting(dbService);
}

/// Base class for test orchestrator subclasses that need to override methods.
/// Use `extends SyncOrchestrator` with `super.forTesting()` pattern.
// NOTE: This is a documentation-only class — the actual pattern uses
// SyncOrchestrator.forTesting directly. Subclasses in tests continue
// to use `super.forTesting()`.
```

#### Step 6.2.2: Update 5 test files

Update imports in all 5 consumer test files:

1. `test/features/sync/presentation/providers/sync_provider_test.dart:16`
2. `test/features/sync/engine/sync_engine_delete_test.dart:109`
3. `test/features/sync/application/fcm_handler_test.dart:11`
4. `test/features/sync/application/sync_enrollment_service_test.dart:16`
5. `test/features/sync/engine/sync_engine_circuit_breaker_test.dart:12`

For files using `super.forTesting()` (files 1, 3, 4, 5): These subclass `SyncOrchestrator` and call `super.forTesting()` in the constructor. The `forTesting` constructor must remain on `SyncOrchestrator` for this pattern to work. Add a `@visibleForTesting` annotation instead of removing it.

> NOTE: `super.forTesting()` in 4 test files requires the constructor to remain on the
> production class. `@visibleForTesting` is the correct Dart idiom for this constraint --
> it keeps the constructor accessible to tests while flagging production usage as a warning.

For file 2 (direct `SyncOrchestrator.forTesting()`): Import the test helper and use `createTestOrchestrator()`.

#### Step 6.2.3: Add @visibleForTesting annotation

In `sync_orchestrator.dart`, add annotation to `forTesting`:

```dart
@visibleForTesting
SyncOrchestrator.forTesting(this._dbService)
```

Add import: `import 'package:meta/meta.dart';` (if not already imported — `@visibleForTesting` is from the `meta` package, re-exported by `package:flutter/foundation.dart`). Check existing imports and use whichever is already present.

---

### Sub-phase 6.3: Final validation

**Agent**: `qa-testing-agent`

#### Step 6.3.1: Run full analyze

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

#### Step 6.3.2: Run targeted tests for modified files

Run tests for each modified area:

```
pwsh -Command "flutter test test/core/database/"
pwsh -Command "flutter test test/features/auth/"
pwsh -Command "flutter test test/features/sync/"
pwsh -Command "flutter test test/features/entries/"
pwsh -Command "flutter test test/features/settings/"
```

Expected: All pass (except 4 pre-existing `form_sub_screens_test.dart` failures)

#### Step 6.3.3: Verify lint baseline

Run custom lints and confirm the baseline reflects actual violations. No new violations should be introduced.
