# Adversarial Review (v2): Sync Verification System Plan

**Plan**: `.claude/plans/2026-03-22-sync-verification-system.md`
**Spec**: `.claude/specs/2026-03-22-sync-verification-system-spec.md`
**Date**: 2026-03-23
**Reviewer**: Code Review Agent (Opus 4.6)
**Previous review**: v1 (12 findings: 4 Critical + 7 High + 1 inline)

---

## Verdict: REJECT

The v1 review findings are correctly placed and mostly actionable, but the plan contains 5 additional Critical issues the v1 review missed -- all involving wrong API signatures, wrong column names, or wrong types that cause compile or runtime failures across every Phase 1 test and every Phase 2 driver endpoint. These are not style issues; they are hard blockers that make every code sample in the plan non-functional as written.

| Severity | v1 Findings | New Findings | Total |
|----------|------------|-------------|-------|
| CRITICAL | 4 (C1-C4) | 5 (C5-C9) | 9 |
| HIGH | 7 (H1-H6) | 0 | 7 |
| MEDIUM | 0 | 6 (M1-M6) | 6 |
| LOW | 0 | 2 (L1-L2) | 2 |

---

## Section 1: Audit of 12 Existing REVIEW FINDING Blocks

**[C1] L3 scenarios completely wrong** (plan:2129)
- Correctly placed: Yes. Accurate vs spec: Yes.
- Gap: Finding omits how TestRunner constructs two DeviceOrchestrator instances (spec ports 3948/3949 vs plan default 4948). Also omits ADB airplane-mode helper module needed for X5-X7.

**[C2] L1 test files have wrong names** (plan:19)
- Correctly placed: Yes. Accurate: Yes. Actionable: Yes, table is clear and complete.

**[C3] SupabaseVerifier missing per-role JWT** (plan:978)
- Correctly placed: Yes. Accurate: Yes.
- Gap: Does not mention JWT expiration handling (1h default; long test runs could expire mid-run).

**[C4] Missing `/driver/remove-from-device` endpoint** (plan:929)
- Correctly placed: Yes. Accurate: Yes.
- Gap: Does not mention that `ProjectLifecycleService` is a NEW DriverServer constructor dependency, requiring Phase 2A update too.

**[H1] S1-S5 semantics reordered** (plan:1749)
- Correctly placed: Yes. Accurate: Yes.
- Gap: Template at plan:2070-2074 and filename patterns at plan:2106-2110 STILL use the old wrong semantics. The implementer will generate 79 files with wrong names. See M4 below.

**[H2] Phase 7 cleanup empty** (plan:2774)
- Correctly placed: Yes. Accurate: Yes. Fully actionable.

**[H3a] SYNCTEST- naming not implemented** (plan:1301)
- Correctly placed: Yes. Accurate: Yes. Fully actionable.

**[H3b] CLI missing --clean and --scenario** (plan:1635)
- Correctly placed: Yes. Accurate: Yes. Fully actionable.

**[H4] SQL injection in column names** (plan:909)
- Correctly placed: Yes. Fully actionable with inline regex fix.

**[H5] No auth token between orchestrator and driver** (plan:1163)
- Correctly placed: Yes. Accurate: Yes.
- Context note: DriverServer already binds to loopback only, so this is defense-in-depth, not an open network exposure.

**[H6 inline] Hardcoded company_id in L1 tests** (plan:68)
- Duplicate ID with H6 block at plan:988. Should be H6a/H6b.
- For L1 unit tests (SQLite-only, no RLS), hardcoded values are acceptable.

**[H6 block] Hardcoded company_id breaks RLS tests** (plan:988)
- Correctly placed: Yes. Fully actionable.

---

## Section 2: NEW Critical Issues (Missed by v1 Review)

### [C5] Tests use `DatabaseService` but `SqliteTestHelper.createDatabase()` returns `Database`

Every Phase 1 test declares `late DatabaseService db` and uses `db.database.rawInsert(...)`. The actual `SqliteTestHelper.createDatabase()` returns `Database` (from sqflite_common_ffi), not `DatabaseService`. Additionally, `ChangeTracker` takes `Database`, `ConflictResolver` takes `Database`.

- **Evidence**: `test/helpers/sync/sqlite_test_helper.dart:11` -- `static Future<Database> createDatabase()`
- **Affected lines**: plan:57-58, 184-189, 248-258, 334-339, and every Phase 1 setUp block
- **Impact**: Every Phase 1 test fails to compile
- **Fix**: `late Database db` instead of `late DatabaseService db`. Remove `.database` accessor.

### [C6] Wrong column names in change_log schema

Actual change_log schema (`lib/core/database/schema/sync_engine_tables.dart:20-33`):
- `processed INTEGER` (plan uses `is_processed`)
- `changed_at TEXT` (plan uses `created_at`)
- `id INTEGER PRIMARY KEY AUTOINCREMENT` (plan uses TEXT UUID like `'cl-$i'`)

Also, `SqliteTestHelper.getChangeLogEntries()` requires TWO args `(Database db, String tableName)` but plan calls it with one arg.

- **Evidence**: `sync_engine_tables.dart:22-30`, `sqlite_test_helper.dart:149-158`
- **Affected lines**: plan:83, 201-203, 270-271, 872, and all `getChangeLogEntries` calls
- **Impact**: Every change_log test and driver endpoint fails at runtime
- **Fix**: `is_processed` -> `processed`, `created_at` -> `changed_at`, use integer auto-IDs, fix `getChangeLogEntries(db, tableName)` calls.

### [C7] `SyncOrchestrator` has no `pushAndPull()` method; wrong return type fields

Plan:811 calls `syncOrchestrator!.pushAndPull()` -- this method does not exist on `SyncOrchestrator`. The orchestrator has `syncLocalAgencyProjects()`, which internally calls `engine.pushAndPull()`.

The return type `SyncResult` has fields `pushed`/`pulled`/`errors`(int)/`errorMessages`(List). Plan uses `result.pushCount`, `result.pullCount`, `result.errors.map(...)` -- all wrong.

- **Evidence**: `sync_orchestrator.dart:221` (no pushAndPull), `sync_types.dart:2-17` (SyncResult fields)
- **Affected lines**: plan:811-817
- **Impact**: `/driver/sync` endpoint will not compile, blocking ALL of Layer 2 and Layer 3
- **Fix**: `syncOrchestrator!.syncLocalAgencyProjects()`, `result.pushed`, `result.pulled`, `result.errorMessages`.

### [C8] `is_deleted` column does not exist -- schema uses `deleted_at`/`deleted_by`

The schema uses `deleted_at TEXT` (nullable timestamp) and `deleted_by TEXT` across all tables. There is no `is_deleted` column anywhere in the schema.

- **Evidence**: `core_tables.dart:26-27`, `toolbox_tables.dart:24`, zero results for `is_deleted` in schema
- **Affected lines**: plan:650, 659, 1072-1073, 1400, 1959, 1975-1976, 2225, 2239-2240, and all `makeProject` calls
- **Impact**: All soft-delete tests and scenarios fail. `makeProject()` includes nonexistent column.
- **Fix**: Replace `is_deleted: 0/1/true` with `deleted_at: null` (not deleted) or `deleted_at: '<timestamp>'` (deleted). Add `deleted_by` field per spec S3.

### [C9] `ConflictResolver.resolve()` API signature mismatch

Actual signature (`conflict_resolver.dart:27-31`):
```dart
Future<ConflictWinner> resolve({
  required String tableName,
  required String recordId,
  required Map<String, dynamic> local,
  required Map<String, dynamic> remote,
})
```

Plan uses fabricated parameters: `localUpdatedAt: DateTime`, `remoteUpdatedAt: DateTime`, `localData`/`remoteData`. Return type is `ConflictWinner` directly, not an object with `.winner` field.

- **Affected lines**: plan:348-441, 476-504 (all Phase 1B tests)
- **Impact**: All conflict resolver tests fail to compile
- **Fix**: Use `local: {'updated_at': '...', ...}` and `remote: {...}`. Return is `ConflictWinner` directly.

---

## Section 3: NEW Medium/Low Issues

### MEDIUM

**[M1]** DeviceOrchestrator default port 4948 conflicts with spec ports 3948/3949 (plan:1183)

**[M2]** `sync_metadata` query uses wrong column name. Plan queries `MAX(last_sync_time)`. Actual table has `key TEXT PRIMARY KEY, value TEXT`. Fix: `SELECT value FROM sync_metadata WHERE key = 'last_sync_time'`

**[M3]** Phase 5C file count says "16 tables" but there are 17. Correct: 17 x 5 - 1 = 84.

**[M4]** Template still uses wrong S2-S5 semantics after H1 finding. H1 fixes 5 project files but leaves the template that generates the other 79 files untouched.

**[M5]** Driver endpoint code uses non-existent APIs:
- `_jsonResponse(request, statusCode, data)` → actual is `_sendJson(res, statusCode, data)`
- `params['table']` → actual is `request.uri.queryParameters['table']`
- `_parseJsonBody(request)` → actual is `_readJsonBody(req)`
- Plan uses inline handlers; existing code uses separate `_handleX(request, res)` methods

**[M6]** `assert` name in scenario-helpers.js shadows Node.js built-in. Rename to `verify()`.

### LOW

**[L1]** Spec report format says "80/80" but actual count is 84. Spec inconsistency.

**[L2]** `/driver/inject-photo` already exists on DriverServer. Plan implies it needs creation.

---

## Section 4: Spec Coverage Gaps

| Spec Section | Covered? | Gap |
|-------------|---------|-----|
| Layer 1: 8 new + 3 enhanced test files | File names wrong (C2) | Content must match spec risk mappings |
| Layer 2: 5 scenarios x 17 tables | S2-S5 semantics wrong (H1, M4) | Template + filenames not updated |
| Layer 3: 10 multi-device scenarios | Completely wrong (C1) | Single-device tests written instead |
| Convergence check after every L3 scenario | Missing | Spec:315-319 requires 3-way diff |
| Failure handling: S1 fail skips S2-S5 | Missing | Spec:377; TestRunner has no skip logic |
| Report saved to file | Missing | Spec:401 requires `reports/sync-verify-{timestamp}.txt` |
| Driver endpoint: remove-from-device | Missing (C4) | Only 4 of 5 spec endpoints present |
| Per-role JWT auth | Missing (C3) | SupabaseVerifier only has service role |
| SYNCTEST- data naming | Missing (H3a) | Helpers use plain UUIDs |
| --clean / --scenario / --step CLI flags | Missing (H3b) | Only --layer/--table/--filter/--dry-run |
| Obsolete flow cleanup (T78-T84, T50, M06) | Steps added by H2 finding | Actionable |

---

## Recommendations

1. **Fix C5-C9 before implementation** -- compile failures in every code sample. The plan's Dart code is unusable without correcting types, column names, API signatures, and soft-delete columns.
2. **Update template and filename patterns** (M4) -- H1 fixes 5 project files but leaves 79-file template untouched.
3. **Address DriverServer API mismatches** (M5) -- follow existing patterns: `_sendJson`, `_readJsonBody`, `req.uri.queryParameters`, separate handler methods.
4. **Fix port defaults** (M1) to match spec (3948/3949).
5. The 4 v1 Critical findings (C1-C4) remain valid and should also be addressed.
