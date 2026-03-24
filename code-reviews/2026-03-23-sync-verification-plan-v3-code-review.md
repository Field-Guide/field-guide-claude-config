# Code Review v3: Sync Verification System Plan

**Date**: 2026-03-23
**Reviewer**: Code Review Agent (Opus 4.6)
**Previous**: v2 REJECT (5 Critical C5-C9, 6 Medium M1-M6, 5 Security SEC-001 to SEC-005)

## Verdict: REJECT

The v2 Critical fixes (C5-C9) and Security fixes (SEC-001, SEC-004, SEC-005) were applied correctly. However, three new Critical issues emerged from cross-referencing against actual schema files: (1) every Phase 1 SQL INSERT uses fabricated column names not present in the real schema, (2) trigger operation strings are lowercase but tests assert uppercase, and (3) `DatabaseService.database` is `Future<Database>` but the plan calls `.rawQuery()` on it without `await`. Several v2 Medium fixes were only partially applied. L3 code blocks remain entirely wrong despite filename corrections.

| Severity | Count |
|----------|-------|
| CRITICAL | 3 |
| HIGH | 4 |
| MEDIUM | 4 |
| LOW | 2 |

---

## Section 1: v2 Fix Verification

| Finding | Status | Notes |
|---------|--------|-------|
| C5 | **FIXED** | All Phase 1 tests use `late Database db`, no `.database.` accessor, `SqliteTestHelper.createDatabase()` returns `Database` |
| C6 | **FIXED** | `processed` not `is_processed`, `changed_at` not `created_at`, integer auto-IDs, `getChangeLogEntries(db, tableName)` two args |
| C7 | **FIXED** | `syncOrchestrator!.syncLocalAgencyProjects()`, `result.pushed`/`.pulled`/`.errorMessages`/`.hasErrors` all correct per `sync_types.dart` |
| C8 | **FIXED** | `deleted_at`/`deleted_by` used everywhere: plan:591-595, 1069-1073, 1391-1401, 1967-1969, 2234-2236 |
| C9 | **FIXED** | `resolver.resolve(tableName:, recordId:, local:, remote:)` returns `ConflictWinner` directly |
| M1 | **PARTIAL** | `DeviceOrchestrator` constructor defaults to 3948 (plan:1181). But `TestRunner` at plan:1513 passes `4948`. Help text at plan:1709 says `default: 4948`. Also, actual `DriverServer` default is 4948 (`driver_server.dart:48`) so DeviceOrchestrator at 3948 won't connect. |
| M2 | **FIXED** | `SELECT value FROM sync_metadata WHERE key = 'last_sync_time'` at plan:935 |
| M3 | **PARTIAL** | Plan:651 says 17 adapters (correct). Plan:5 says "16 synced tables". `triggeredTables` has 16 (no `project_assignments`). Variations table lists 17. Inconsistent but non-blocking. |
| M4 | **NOT FIXED** | File list at plan:1777-1781 has correct names. Code blocks at plan:1850/1888/1938/1999 have wrong filenames AND wrong semantics. Template import at plan:2070 uses `assert` not `verify`. |
| M5 | **PARTIAL** | Method names correct (`_sendJson`, `_readJsonBody`, `req.uri.queryParameters`). However, `req` is undefined in `_handleRequest` scope (parameter is `request`). Inline handler pattern diverges from existing separate-method pattern. |
| M6 | **PARTIAL** | `verify()` defined and exported at plan:1334/1456. But 6 code blocks still import `assert`: plan:2070, 2314, 2443, 2489, 2579, 2642. These will get `undefined` at runtime. |
| SEC-001 | **FIXED** | `require('dotenv').config({ path: require('path').join(__dirname, '.env.test') })` at plan:1671 |
| SEC-004 | **FIXED** | Generic error messages + `Logger.sync()` in all 5 catch blocks (plan:769-770, 815-816, 847-848, 904-905, 943-944) |
| SEC-005 | **FIXED** | `kReleaseMode || kProfileMode` guard at top of all 5 endpoints (plan:750, 780, 826, 858, 920) |

---

## Section 2: New Issues

### [C10] Phase 1 SQL INSERTs use fabricated column names — every test fails at runtime

- **Severity**: CRITICAL
- **Location**: plan:71, 86, 104, 120, 126, 132, 138, 144, 158, 575, 580, 585, 610, 615
- **Issue**: All `INSERT INTO projects` statements use columns `project_name`, `status`, `created_by` which do not exist in the actual schema. Actual columns per `core_tables.dart:7-28`: `name` (not `project_name`), `is_active` (not `status`), `created_by_user_id` (not `created_by`). Additionally, `created_at TEXT NOT NULL` is missing from every INSERT across all tables (projects, locations, contractors, daily_entries, todo_items). The `daily_entries` INSERT uses `entry_date` but actual column is `date`. The `contractors` INSERT is missing required `type TEXT NOT NULL`.
- **Impact**: Every Phase 1A, 1B, 1C test that inserts data into any table will fail with SQLite errors. 100% of Phase 1 tests are affected.
- **Fix**: For each table, cross-reference the actual schema in `lib/core/database/schema/`:
  - `projects`: `name` not `project_name`, `is_active` not `status`, `created_by_user_id` not `created_by`, add `created_at`
  - `locations`: add `created_at`
  - `contractors`: add `type`, `created_at`
  - `daily_entries`: `date` not `entry_date`, `created_by_user_id` not `created_by`, add `created_at`
  - `todo_items`: add `created_at`

### [C11] Trigger operations are lowercase but tests assert uppercase

- **Severity**: CRITICAL
- **Location**: plan:79, 97, 112
- **Issue**: `sync_engine_tables.dart:199/206/213` produces `'insert'`, `'update'`, `'delete'` (lowercase). Plan tests assert `'INSERT'`, `'UPDATE'`, `'DELETE'` (uppercase). `ChangeEntry.operation` at `change_tracker.dart:10` documents `// 'insert', 'update', 'delete'`.
- **Impact**: The three core trigger verification tests in Phase 1A will fail with assertion errors despite triggers working correctly.
- **Fix**: Change expectations to lowercase: `expect(changes.first['operation'], 'insert')`, etc.

### [C12] `DatabaseService.database` is `Future<Database>` — all 5 driver endpoints fail

- **Severity**: CRITICAL
- **Location**: plan:806, 844, 884, 898, 930, 934
- **Issue**: `database_service.dart:37` defines `Future<Database> get database async`. The plan calls `databaseService!.database.rawQuery(...)` which invokes `.rawQuery()` on a `Future<Database>`, not a `Database`. This is a type error — `Future<Database>` has no `rawQuery` method.
- **Impact**: All 5 new driver endpoints (`/driver/local-record`, `/driver/change-log`, `/driver/create-record`, `/driver/sync-status`, and the PRAGMA check) will fail at compile time or throw `NoSuchMethodError` at runtime.
- **Fix**: Add `final db = await databaseService!.database;` at the top of each endpoint handler, then use `db.rawQuery(...)`.

---

### [H7] `getUnprocessedChanges()` returns `Map` not `List` — batch limit test is vacuous

- **Severity**: HIGH
- **Location**: plan:235-236
- **Issue**: `ChangeTracker.getUnprocessedChanges()` returns `Map<String, List<ChangeEntry>>` (grouped by table). The test does `expect(changes.length, lessThanOrEqualTo(500))`. On a `Map`, `.length` is the number of keys (table groups). With 600 entries all in the `'projects'` table, `changes.length == 1`, which trivially passes. The test proves nothing about the batch limit.
- **Fix**: Flatten the map: `final total = changes.values.expand((v) => v).length; expect(total, lessThanOrEqualTo(500));`

### [H8] `hasFailedRecord` test uses wrong retry threshold

- **Severity**: HIGH
- **Location**: plan:294-303
- **Issue**: Test inserts a change_log entry with `retry_count: 3` then asserts `hasFailedRecord` returns `true`. Actual `hasFailedRecord` (`change_tracker.dart:187`) checks `retry_count >= SyncEngineConfig.maxRetryCount` which is `5`. With `retry_count: 3`, the method returns `false` and the test fails.
- **Fix**: Use `retry_count: 5` (or `SyncEngineConfig.maxRetryCount`) in the test data.

### [H9] L3 code blocks still implement wrong single-device scenarios

- **Severity**: HIGH
- **Location**: plan:2174-2768 (all 10 X1-X10 code blocks)
- **Issue**: The file list at plan:2161-2170 was corrected to multi-device names (e.g., `X1-admin-creates-inspector-pulls.js`). But code blocks still implement the old single-device scenarios: X1 is cascade-soft-delete (plan:2174), X2 is FK-ordering-push (plan:2262), X3 is deep-FK-chain (plan:2308), etc. None use `{ verifier, adminDevice, inspectorDevice }` signature. No ADB airplane mode control. X8/X9 don't use per-role JWT.
- **Fix**: The implementing agent MUST follow the C1 REVIEW FINDING text, not the code blocks.

### [H10] `req` variable undefined in `_handleRequest` inline code

- **Severity**: HIGH
- **Location**: plan:789, 790, 835, 867
- **Issue**: The `_handleRequest` method parameter is `request` (`driver_server.dart:81`). The plan's inline endpoint code uses `req.uri.queryParameters` and `_readJsonBody(req)` where `req` is undefined. This causes a compile error.
- **Fix**: Either (a) use `request.uri.queryParameters` and `_readJsonBody(request)`, or (b) extract each endpoint into a separate `_handleXxx(HttpRequest req, HttpResponse res)` method following the existing pattern.

---

### [M7] Port mismatch: DeviceOrchestrator defaults to 3948 but DriverServer is 4948

- **Severity**: MEDIUM
- **Location**: plan:1181 (DeviceOrchestrator default=3948), plan:722 (DriverServer default=4948), plan:1513 (TestRunner passes 4948)
- **Issue**: The M1 fix changed DeviceOrchestrator's default to 3948. But the actual DriverServer defaults to 4948 (`driver_server.dart:48`). The TestRunner at plan:1513 passes `4948`, contradicting the DeviceOrchestrator default. The help text at plan:1709 says `default: 4948`. These three values must agree.
- **Fix**: Either change DriverServer port to 3948 per spec, or change DeviceOrchestrator back to 4948 to match reality. Pick one and be consistent across all references.

### [M8] S2-S5 code blocks have wrong filenames AND wrong semantics

- **Severity**: MEDIUM
- **Location**: plan:1850 (says `projects-S2-pull.js`), plan:1888 (says `projects-S3-update-sync.js`), plan:1938 (says `projects-S4-delete-sync.js`), plan:1999 (says `projects-S5-conflict.js`)
- **Issue**: The file list at plan:1777-1781 has correct names (S2-update-push, S3-delete-push, S4-conflict, S5-fresh-pull). But the actual code blocks use old wrong filenames and implement wrong semantics: S2 does pull, S3 does update-sync, S4 does delete-sync, S5 does conflict.
- **Fix**: Rewrite code blocks to match the file list AND spec semantics. This is the same as H1/M4 but now must be done in the code, not just the file list.

### [M9] Template and 6 L3 scenarios import `assert` instead of `verify`

- **Severity**: MEDIUM
- **Location**: plan:2070, 2314, 2443, 2489, 2579, 2642
- **Issue**: `scenario-helpers.js` exports `verify` (plan:1456), not `assert`. Six code blocks destructure `assert` which will be `undefined` at runtime.
- **Fix**: Replace `assert` with `verify` in all import destructuring.

### [M10] JS `makeProject` uses `project_name` — may fail on Supabase if column differs

- **Severity**: MEDIUM
- **Location**: plan:1396
- **Issue**: Local SQLite column is `name`. If Supabase mirrors this schema, `project_name` will fail. If Supabase has its own column naming, this may be fine. Cannot verify without Supabase schema access.
- **Fix**: Verify Supabase `projects` table column name. If `name`, update `makeProject()`.

---

### [L3] Missing `created_at` in JS helper factories

- **Severity**: LOW
- **Location**: plan:1390-1435 (`makeProject`, `makeDailyEntry`, `makeLocation`)
- **Issue**: None include `created_at`. If Supabase has a server-side default, this works. If not, inserts will fail with NOT NULL violations.
- **Fix**: Add `created_at: new Date().toISOString()` to all factories.

### [L4] calculation_history variations table uses wrong column names

- **Severity**: LOW
- **Location**: plan:2112
- **Issue**: Variations table says `{ id, project_id, expression, result, variables, updated_at }`. Actual schema (`toolbox_tables.dart:76-90`) has `calc_type`, `input_data`, `result_data`, `notes` — no `expression`, `result`, or `variables` columns.
- **Fix**: Update variations table to match actual schema.

---

## Section 3: Summary

**What's working well:**
- v2 Critical fixes (C5-C9) were applied thoroughly and correctly across all Phase 1 tests and Phase 2 endpoints
- Security fixes (SEC-001, SEC-004, SEC-005) are complete and correct
- The overall architecture (3-layer testing, DriverServer endpoints, SupabaseVerifier, DeviceOrchestrator, TestRunner) is sound
- REVIEW FINDING blocks provide clear remediation guidance for the implementing agent
- `deleted_at`/`deleted_by` pattern is now consistent throughout
- `SyncResult` field usage is correct

**What still blocks implementation:**
1. **C10**: Every Phase 1 SQL INSERT uses wrong column names. This is the single largest issue — it affects every test in the plan's Dart code. The implementer cannot use these INSERTs as-is.
2. **C11**: Lowercase vs uppercase operation strings — simple fix but causes 100% of trigger tests to fail.
3. **C12**: `Future<Database>` without `await` — prevents all 5 driver endpoints from compiling.
4. **H9**: L3 code blocks are entirely wrong (single-device, wrong scenarios). The implementer must ignore them and follow C1 review text.
5. **H10**: `req` vs `request` compile error in all inline endpoint code.

**Recommendation**: Fix C10, C11, C12, and H10 in the plan code (these are mechanical fixes). For H9 and M8, either rewrite the code blocks or add a prominent disclaimer that the implementer must follow REVIEW FINDING text over code blocks. After those fixes, this plan should be APPROVE WITH CONDITIONS.

---

**Files cross-referenced during this review:**

| File | Purpose |
|------|---------|
| `lib/core/database/schema/sync_engine_tables.dart` | change_log schema, trigger SQL, triggeredTables list |
| `lib/core/database/schema/core_tables.dart` | projects and locations table schemas |
| `lib/core/database/schema/entry_tables.dart` | daily_entries schema |
| `lib/core/database/schema/contractor_tables.dart` | contractors schema |
| `lib/core/database/schema/toolbox_tables.dart` | todo_items and calculation_history schemas |
| `lib/features/sync/engine/change_tracker.dart` | ChangeTracker API, purgeOldFailures, hasFailedRecord |
| `lib/features/sync/engine/conflict_resolver.dart` | ConflictResolver.resolve() signature, getConflictCount |
| `lib/features/sync/domain/sync_types.dart` | SyncResult fields |
| `lib/features/sync/application/sync_orchestrator.dart` | syncLocalAgencyProjects() |
| `lib/features/sync/config/sync_config.dart` | maxRetryCount=5, circuitBreakerThreshold=1000 |
| `lib/core/driver/driver_server.dart` | _handleRequest param name, _sendJson/_readJsonBody signatures, port default |
| `lib/core/database/database_service.dart` | Future<Database> get database |
| `test/helpers/sync/sqlite_test_helper.dart` | createDatabase(), getChangeLogEntries() signatures |
