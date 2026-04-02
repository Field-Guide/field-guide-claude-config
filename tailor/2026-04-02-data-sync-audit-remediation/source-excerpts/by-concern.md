# Source Excerpts by Concern

## Phase 1: Dead Code & Quick Fixes

### F10 — updateLastSyncedAt (user_profile_sync_datasource.dart:33-35)
```dart
Future<void> updateLastSyncedAt(String userId) async {
    await _client.rpc('update_last_synced_at');
}
```
Caller in sync_orchestrator.dart (~line 291):
```dart
await _userProfileSyncDatasource!.updateLastSyncedAt(userId);
```

### F12 — BatchOperationsMixin (query_mixins.dart:4-33)
```dart
mixin BatchOperationsMixin {
  DatabaseService get db;
  String get tableName;
  Future<void> insertBatch(List<Map<String, dynamic>> items) async { ... }
  Future<void> deleteBatch(List<String> ids) async { ... }
}
```
Re-export in datasources.dart:6: `export 'query_mixins.dart';`

### BLOCKER-38 — clearLocalCompanyData (auth_service.dart:312-361)
Full source in tool results. Key: static method, hard-deletes 31 tables, only called from SwitchCompanyUseCase:61.

### BLOCKER-38 — SwitchCompanyUseCase (switch_company_use_case.dart:15-72)
Full source in tool results. Key: only purpose is detecting company switch and calling clearLocalCompanyData.

### BLOCKER-38 — SwitchCompanyUseCase in SignInUseCase (sign_in_use_case.dart)
Lines 5, 42, 46, 71-73:
```dart
import '...switch_company_use_case.dart';      // line 5
final SwitchCompanyUseCase _switchCompanyUseCase; // line 42
required SwitchCompanyUseCase switchCompanyUseCase, // line 46
// FIX-5: SwitchCompanyUseCase is always injected    // line 73
```

---

## Phase 2: Schema & Migration

### F3 — Current DDL (toolbox_tables.dart:32-34)
```dart
CREATE TABLE form_responses (
    id TEXT PRIMARY KEY,
    form_type TEXT NOT NULL,    // <-- NO DEFAULT in canonical DDL
```

### F3 — SchemaVerifier expected (schema_verifier.dart:324)
```dart
'form_type': "TEXT NOT NULL DEFAULT '$kFormTypeMdot0582b'",
```

### F3 — Migration v22 (database_service.dart:807-826)
```dart
_addColumnIfNotExists(db, 'form_responses', 'form_type',
    "TEXT NOT NULL DEFAULT '$kFormTypeMdot0582b'");
// Backfill form_type from form_id for existing responses.
await db.execute('''
    UPDATE form_responses
    SET form_type = COALESCE(form_type, form_id, '$kFormTypeMdot0582b')
    WHERE form_type IS NULL OR form_type = ''
''');
```

### F11 — SchemaVerifier.verify() structure
Lines 413-519: verify() does:
1. Missing column repair (440-456) — `ALTER TABLE ADD COLUMN` ← TO BE REMOVED
2. Drift detection (458-506) — type, notnull, default comparison ← KEEP
3. Returns List<ColumnDrift> (518) ← CHANGE to SchemaReport

### F11 — SchemaVerifier called from database_service.dart
```dart
// Line 73 (persistent DB):
final drifts = await SchemaVerifier.verify(db);
// Line 93 (in-memory DB):
final drifts = await SchemaVerifier.verify(db);
```

---

## Phase 3: Boundary Fixes

### F4/F7 — Existing UserCertificationLocalDatasource (settings/data/datasources/local/)
```dart
class UserCertificationLocalDatasource {
  final DatabaseService _db;
  UserCertificationLocalDatasource(this._db);
  Future<List<UserCertification>> getByUserId(String userId) async { ... }
}
```
NEEDS: `upsertCertifications(List<Map<String, dynamic>> rows)`, `deleteCertificationsForUser(String userId)`

### F4/F7 — Raw cert inserts to refactor (user_profile_sync_datasource.dart:86-101)
```dart
Future<void> pullUserCertifications(String userId) async {
    final response = await _client
        .from('user_certifications').select().eq('user_id', userId);
    final db = await _dbService!.database;
    for (final cert in (response as List)) {
      final map = cert as Map<String, dynamic>;
      await db.insert('user_certifications', map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
}
```

### F14 — ContractorEditingController constructor (contractor_editing_controller.dart:39-42)
```dart
ContractorEditingController({
    required EntryPersonnelCountsLocalDatasource countsDatasource,
    required EntryEquipmentLocalDatasource equipmentDatasource,
    required EntryContractorsLocalDatasource contractorsDatasource,
})
```

### F14 — entryProviders function (entries_providers.dart:27)
```dart
List<SingleChildWidget> entryProviders({
  required DailyEntryRepository dailyEntryRepository,
  required EntryExportRepository entryExportRepository,
  required FormResponseRepository formResponseRepository,
  required AuthProvider authProvider,
  required EntryPersonnelCountsLocalDatasource entryPersonnelCountsDatasource,
  required EntryEquipmentLocalDatasource entryEquipmentDatasource,
  required EntryContractorsLocalDatasource entryContractorsDatasource,
})
```

### F14 — home_screen.dart datasource reads (~line 186-188)
```dart
context.read<EntryPersonnelCountsLocalDatasource>()
context.read<EntryEquipmentLocalDatasource>()
context.read<EntryContractorsLocalDatasource>()
```

---

## Phase 4: Structural

### F5 — SyncOrchestrator._createEngine (sync_orchestrator.dart:195)
Current foreground engine creation (to be replaced by factory):
```dart
Future<SyncEngine?> _createEngine() async {
  if (_supabaseClient == null) return null;
  registerSyncAdapters();
  final db = await _dbService.database;
  return SyncEngine(database: db, supabase: _supabaseClient!);
  // ... additional config
}
```

### F5 — BackgroundSyncHandler desktop path (background_sync_handler.dart:139-183)
```dart
Future<void> _performDesktopSync() async {
  // Uses injected _dbService and _supabaseClient
  final engine = await SyncEngine.createForBackgroundSync(
    database: await _dbService!.database,
    supabase: _supabaseClient!,
  );
  await engine?.pushAndPull();
}
```

### F9 — SyncOrchestrator setters (sync_orchestrator.dart)
```dart
// Line 52: UserProfileSyncDatasource? _userProfileSyncDatasource;
// Line 56: Function? _syncContextProvider;
// Line 60: AppConfigProvider? _appConfigProvider;
// Line 63-64: String? _companyId; String? _userId;

// Lines 119-136:
void setUserProfileSyncDatasource(UserProfileSyncDatasource ds) { ... }
void setSyncContextProvider(Function provider) { ... }
void setAppConfigProvider(AppConfigProvider provider) { ... }
void setAdapterCompanyContext({String? companyId, String? userId}) { ... }
```

### F9 — SyncInitializer.create() (sync_initializer.dart)
Multi-step wiring sequence that will become a builder chain.

---

## Phase 5: Sign-Out Warning

### SignOutUseCase.execute() (sign_out_use_case.dart:30-43)
```dart
Future<bool> execute() async {
    try {
      await _authService.signOut();
      BackgroundSyncHandler.dispose();
      // WHY: BUG-17 — Don't clear local data on logout.
      await _preferencesService?.clearPasswordRecoveryActive();
      await _clearSecureStorage();
      return true;
    } catch (e) { ... }
}
```

### SyncOrchestrator.getPendingCount (sync_orchestrator.dart:608)
```dart
Future<int> getPendingCount() async {
  final db = await _dbService.database;
  final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM change_log WHERE processed = 0');
  return Sqflite.firstIntValue(result) ?? 0;
}
```

### SignOutDialog (sign_out_dialog.dart)
Current: simple AlertDialog with Sign Out / Cancel buttons. Needs three-action variant when unsynced count > 0.
