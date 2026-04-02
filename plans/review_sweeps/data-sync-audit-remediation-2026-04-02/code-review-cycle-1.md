# Code Review: Data, Database & Sync Audit Remediation Plan

**Plan**: `.claude/plans/2026-04-02-data-sync-audit-remediation.md`
**Spec**: `.claude/specs/2026-04-02-data-sync-audit-remediation-spec.md`
**Ground Truth**: `.claude/tailor/2026-04-02-data-sync-audit-remediation/ground-truth.md`
**Reviewer**: Code Review Agent
**Date**: 2026-04-01
**Cycle**: 1
**Verdict**: **REJECT** — 3 CRITICAL, 4 HIGH, 1 MEDIUM, 1 LOW

---

## Critical Issues

### CR-1: Migration v47 destroys change_log triggers (silent sync data loss)

**Phase**: 2.1 (F3)

`form_responses` is in `SyncEngineTables.triggeredTables` (sync_engine_tables.dart:148) with 3 triggers. The table rebuild drops them. Plan recreates indexes but not triggers.

**Impact**: Form responses silently stop syncing after migration.

**Fix**: Add trigger recreation after index recreation:
```dart
for (final trigger in SyncEngineTables.triggersForTable('form_responses')) {
  await db.execute(trigger);
}
```

### CR-2: `SyncProvider.syncAll()` does not exist

**Phase**: 5.2

Plan line in `_syncThenSignOut`: `await syncProvider.syncAll();`
Actual method: `sync_provider.dart:283`: `Future<SyncResult> sync() async`

**Impact**: Compile error.
**Fix**: `await syncProvider.sync();`

### CR-3: Test fixtures missing `cert_number` column

**Phase**: 3.1

Test fixtures in Step 3.1.1 omit `cert_number`. `sync_engine_tables.dart:77`: `cert_number TEXT NOT NULL`.

**Impact**: All 3 tests crash with NOT NULL constraint.
**Fix**: Add `'cert_number': 'CERT-001'` to all test fixture maps.

---

## High Issues

### CR-4: SyncEngineFactory.create() wrong param names + missing required params

**Phase**: 4.1

Plan: `SyncEngine(database: database, supabase: supabase);`
Actual constructor: `SyncEngine({required this.db, required this.supabase, required this.companyId, required this.userId, ...})`

Param is `db:` not `database:`. Also missing required `companyId` and `userId`.

**Fix**: Factory must accept and pass companyId/userId, use `db:` not `database:`.

### CR-5: Migration DDL missing 6 columns, has phantom column

**Phase**: 2.1

Plan DDL has: `id, form_id, form_type, entry_id, project_id, data, created_at, updated_at, deleted_at, deleted_by`
Actual canonical DDL (toolbox_tables.dart:32-51) has: `id, form_type, form_id, entry_id, project_id, header_data, response_data, table_rows, response_metadata, status, created_at, updated_at, created_by_user_id, deleted_at, deleted_by`

Missing: `header_data`, `response_data`, `table_rows`, `response_metadata`, `status`, `created_by_user_id`
Phantom: `data` column doesn't exist. `project_id` nullability wrong.

**Impact**: Catastrophic data loss — 6 columns' data destroyed.
**Fix**: Replace migration DDL with exact copy from `toolbox_tables.dart:31-51`.

### CR-6: Migration missing 3 of 6 indexes, 1 name wrong

**Phase**: 2.1

Plan recreates 3 indexes. Actual (toolbox_tables.dart:97-102): 6 indexes.
Missing: `idx_form_responses_type`, `idx_form_responses_status`, `idx_form_responses_deleted_at`
Name mismatch: `idx_form_responses_form_id` should be `idx_form_responses_form`

**Fix**: Recreate all 6 indexes matching toolbox_tables.dart.

### CR-7: entries_providers.dart — verify no other datasource consumers before removing Providers

**Phase**: 3.2

Plan removes the 3 individual datasource `Provider.value()` lines. If any other consumer in the widget tree reads these types directly (beyond the 4 files listed), they break.

**Fix**: Add blast-radius verification step — grep for ALL `context.read<EntryContractorsLocalDatasource>` etc. before removing.

---

## Medium Issues

### CR-8: Phase 5 contains dead code (self-contradicting steps)

Steps 5.1.1-5.1.2 add SyncOrchestrator to SignOutUseCase, then immediately say "Revised approach: revert changes." Remove the dead path and show only the final approach.

---

## Minor Issues

### CR-9: `@visibleForTesting` import source

Plan says `package:flutter/foundation.dart` but it's from `package:meta/meta.dart`. Works via re-export but comment is misleading.

---

## KISS/DRY

- **SyncEngineFactory may be over-engineered**: wraps 2 lines + mobile isolate can't use it. Consider static helper.
- **pullUserCertifications fallback**: null fallback to raw SQL defeats F4/F7 purpose. Make cert datasource required or remove fallback.

---

## Summary

| # | Severity | Phase | Finding |
|---|----------|-------|---------|
| CR-1 | CRITICAL | 2.1 | Migration drops change_log triggers |
| CR-2 | CRITICAL | 5.2 | syncAll() doesn't exist → sync() |
| CR-3 | CRITICAL | 3.1 | Test fixtures missing cert_number |
| CR-4 | HIGH | 4.1 | Factory wrong params + missing required |
| CR-5 | HIGH | 2.1 | Migration DDL missing 6 columns |
| CR-6 | HIGH | 2.1 | Migration missing indexes |
| CR-7 | HIGH | 3.2 | Verify datasource Provider consumers |
| CR-8 | MEDIUM | 5 | Dead code in Phase 5 steps |
| CR-9 | LOW | 6.2 | @visibleForTesting import |

**Migration v47 code block needs full rewrite — DDL, indexes, and triggers all wrong.**
