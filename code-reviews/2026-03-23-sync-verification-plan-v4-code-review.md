# Code Review v4: Sync Verification System Plan

**Date**: 2026-03-23
**Reviewer**: Code Review Agent (Opus 4.6)
**Previous**: v3 REJECT (3 Critical C10-C12, 4 High H7-H10, 4 Medium, 2 Low)

## Verdict: APPROVE WITH CONDITIONS

All v3 Critical and High findings were fixed correctly. The plan is implementable for Phase 1 (L1 tests) and Phase 2 (driver endpoints) as-is. Phase 5C variations table has widespread wrong column names for 10+ tables that will generate incorrect scenario code, but this is addressable by the implementing agent cross-referencing schema files. No compile-time or runtime blockers remain.

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 3 |
| LOW | 2 |

---

## Section 1: v3 Fix Verification

| Finding | Status | Notes |
|---------|--------|-------|
| C10 | **FIXED** | All Phase 1 SQL INSERTs now use correct schema columns: `name` (not `project_name`), `is_active` (not `status`), `created_by_user_id` (not `created_by`), `created_at` present everywhere. |
| C11 | **FIXED** | All trigger operation assertions use lowercase: `'insert'`, `'update'`, `'delete'`. Matches `sync_engine_tables.dart:199/206/213`. |
| C12 | **FIXED** | All 5 driver endpoints now do `final db = await databaseService!.database;` before queries. |
| H7 | **FIXED** | Batch test uses `changes.values.expand((v) => v).length` to flatten the `Map<String, List<ChangeEntry>>`. |
| H8 | **FIXED** | `hasFailedRecord` test uses `retry_count: 5`, matching `SyncEngineConfig.maxRetryCount`. |
| H9 | **FIXED** | All 10 L3 scenarios (X1-X10) use `{ verifier, adminDevice, inspectorDevice }` multi-device signature. X5-X7 use ADB airplane mode. X8-X9 use `verifier.authenticateAs()` for per-role JWT. |
| H10 | **FIXED** | All driver endpoint code uses `request.uri.queryParameters` and `_readJsonBody(request)`. No remaining `req.` references. |
| M1/M7 | **FIXED** | DeviceOrchestrator default port changed to 4948, matching DriverServer default. TestRunner and help text also 4948. All agree. |
| M4/M8 | **FIXED** | File list AND code block filenames AND semantics all align: S2=update-push, S3=delete-push, S4=conflict, S5=fresh-pull. |
| M6/M9 | **FIXED** | All scenario imports use `verify` not `assert`. Zero `assert` imports remain. |
| M10 | **FIXED** | `makeProject()` uses `name` (not `project_name`). |
| SEC-002 | **FIXED** | `queryRecords()` validates filter keys + `encodeURIComponent()`. |
| SEC-003 | **FIXED** | `SYNCED_TABLES` allowlist + validation on all CRUD methods. |
| SEC-006 | **FIXED** | RegExp try/catch + 100-char length limit. |
| SEC-007 | **FIXED** | Cleanup retry with backoff (3 attempts) + post-cleanup verification. |
| SEC-013 | **FIXED** | `.gitignore` step in Phase 7A adds `**/.env.test`. |
| SEC-015 | **FIXED** | `X-Driver-Token` header in DeviceOrchestrator `_request()`. |
| L3 | **FIXED** | All JS factories include `created_at: new Date().toISOString()`. |
| L4 | **FIXED** | `calculation_history` uses correct columns: `calc_type`, `input_data`, `result_data`, `notes`. |

---

## Section 2: New Issues

### [H11] Variations table has wrong column names for 10+ tables — will generate broken scenarios

- **Severity**: HIGH
- **Location**: plan:2189-2206 (Phase 5C variations table)
- **Issue**: The variations table that guides the implementing agent for 79 generated scenario files contains fabricated column names for multiple tables:

  | Table | Variations Field | Actual Column |
  |-------|-----------------|---------------|
  | `equipment` | `type` | no `type` column (has `name`, `description`) |
  | `bid_items` | missing `bid_quantity` | `bid_quantity REAL NOT NULL` |
  | `photos` | `daily_entry_id` | `entry_id` |
  | `photos` | missing `filename`, `captured_at` | both NOT NULL |
  | `entry_equipment` | `daily_entry_id`, `hours` | `entry_id`, `was_used` |
  | `entry_quantities` | `daily_entry_id` | `entry_id` |
  | `entry_contractors` | `daily_entry_id` | `entry_id` |
  | `entry_personnel_counts` | `daily_entry_id`, `personnel_type_id` | `entry_id`, `type_id` + missing `contractor_id` NOT NULL |
  | `form_responses` | `inspector_form_id`, `daily_entry_id`, `responses` | `form_id`, `entry_id`, `response_data` + missing `form_type`, `project_id` NOT NULL |
  | `project_assignments` | `role` | no `role` column (has `assigned_by`, `company_id`) |

- **Impact**: The implementing agent will generate 79 scenario files with wrong field names.
- **Fix**: Update the Required Fields column in the variations table to match actual schema.

### [M11] DeviceOrchestrator `find()` uses POST but driver expects GET

- **Severity**: MEDIUM
- **Location**: plan:1288-1289
- **Issue**: `find(key)` sends `this._request('POST', '/driver/find', { key })`. Actual DriverServer handles `GET /driver/find?key=...`. POST will return 404.
- **Fix**: Change to `this._request('GET', '/driver/find?key=${encodeURIComponent(key)}')`.

### [M12] DeviceOrchestrator `navigate()` sends `{ route }` but driver expects `{ path }`

- **Severity**: MEDIUM
- **Location**: plan:1273-1274
- **Issue**: `navigate(route)` sends `{ route }` in body. DriverServer reads `body['path']`. Since `body['path']` will be `undefined`, driver returns 400.
- **Fix**: Change to `{ path: route }`.

### [M13] `authenticateAs()` and `resetAuth()` called in X8/X9 but never defined in SupabaseVerifier

- **Severity**: MEDIUM
- **Location**: plan:2828, 2866, 2903, 2912, 2921, 2927 vs plan:1001-1186
- **Issue**: X8 and X9 call `verifier.authenticateAs('inspector')` and `verifier.resetAuth()` but SupabaseVerifier class doesn't implement these. C3 REVIEW FINDING (plan:972-980) describes the requirement.
- **Fix**: Implementer must add these methods per C3 review finding text.

### [L5] Conflict resolver test data uses `project_name` key

- **Severity**: LOW
- **Location**: plan:355-451
- **Issue**: Functionally correct (resolver only reads `updated_at`) but cosmetically misleading.
- **Fix**: Replace `project_name` with `name`.

### [L6] SupabaseVerifier uses `https` module — fails with non-SSL URLs

- **Severity**: LOW
- **Location**: plan:1005, 1163
- **Issue**: `require('https')` hardcoded. Local Docker Supabase uses HTTP.
- **Fix**: Dynamic protocol detection.

---

## Section 3: Summary

**Conditions for approval:**
1. **H11 (variations table)**: Implementing agent MUST cross-reference actual schema files when generating 79 scenario files. Alternatively, fix the variations table before implementation.
2. **M12 (navigate body key)**: Must change `{ route }` to `{ path: route }`.
3. **M11 (find method)**: Must change from POST to GET with query params.
4. **M13 (authenticateAs)**: Must add methods to SupabaseVerifier per C3 review finding.

**Recommendation**: These 4 conditions are all implementer-actionable. The plan is now structurally sound. APPROVE WITH CONDITIONS.
