# Security Review: Data, Database & Sync Audit Remediation Plan

**Plan**: `.claude/plans/2026-04-02-data-sync-audit-remediation.md`
**Spec**: `.claude/specs/2026-04-02-data-sync-audit-remediation-spec.md`
**Reviewer**: Security Agent
**Date**: 2026-04-01
**Cycle**: 1
**Verdict**: **REJECT** — 2 blocking findings, 3 advisory findings

---

## Blocking Findings

### SEC-R1: Cross-Tenant Data Exposure — Company-Switch Detection Removed Without Replacement

**Severity**: HIGH
**Phase**: 1.4 (BLOCKER-38)
**Domain**: Auth (multi-tenant isolation)

**Issue**: The plan deletes `SwitchCompanyUseCase` and `clearLocalCompanyData` entirely (Steps 1.4.1-1.4.4), with the rationale "Users never switch companies needing same data — method has no valid use case" (Decisions Log, spec line 249).

This is incorrect. The `SwitchCompanyUseCase` exists for a real threat model: **device handoff between inspectors at different companies**. Construction inspectors share tablets. When Inspector A (Company X) signs out and Inspector B (Company Y) signs in, `SwitchCompanyUseCase.detectAndHandle()` (switch_company_use_case.dart:57) checks whether the incoming user's `companyId` differs from the cached company and clears local data if so.

The plan removes this detection and the data wipe simultaneously:
- Step 1.4.1: Deletes `clearLocalCompanyData`
- Step 1.4.2: Deletes `SwitchCompanyUseCase` (including the detection logic)
- Step 1.4.3: Removes the `detectAndHandle` call from `SignInUseCase`

After this change, when Inspector B (Company Y) signs in on a device that has Inspector A's (Company X) data cached in SQLite, all of Company X's projects, daily entries, photos, bid items, and contractor data remain readable in the local database. The sync engine will eventually pull Company Y's data, but Company X's data persists indefinitely in SQLite with no scoping mechanism.

This is a violation of the CLAUDE.md hard constraint: "No shortcuts that bypass approval flows, weaken RLS, or create privilege escalation paths."

**Note**: RLS protects the *remote* Supabase side. The issue is *local* SQLite, which has no RLS. All local queries return data from whatever company previously synced.

**Remediation options (pick one before approval)**:
1. **Keep detection, replace the wipe**: Keep `SwitchCompanyUseCase.detectAndHandle()` but replace `clearLocalCompanyData` with a scoped query that filters/hides previous company data at the repository level (e.g., all local queries include `WHERE company_id = ?`).
2. **Keep the wipe for cross-company only**: Delete it from the sign-out path (BUG-17 fix), but retain it for the company-switch case detected at sign-in.
3. **Document the accepted risk**: If the product decision is that shared devices across companies is not a supported scenario, add an explicit risk acceptance note to the plan and spec with the product owner's sign-off.

Option 2 is the lowest-effort fix that preserves the security property.

---

### SEC-R2: Migration v47 Table Rebuild Drops change_log Triggers — Silent Sync Data Loss

**Severity**: HIGH
**Phase**: 2.1 (F3)
**Domain**: Sync Integrity

**Issue**: The migration v47 (Step 2.1.3) rebuilds `form_responses` via `ALTER TABLE RENAME` + `CREATE TABLE` + `INSERT INTO ... SELECT` + `DROP TABLE`. SQLite drops all triggers attached to a table when the table is dropped.

The `form_responses` table has 3 change_log triggers (`trg_form_responses_insert`, `trg_form_responses_update`, `trg_form_responses_delete`) registered by `SyncEngineTables.triggeredTables` (sync_engine_tables.dart:148). After migration v47 executes:

1. `ALTER TABLE form_responses RENAME TO form_responses_old` — triggers stay on `form_responses_old`
2. `CREATE TABLE form_responses (...)` — new table, no triggers
3. `INSERT INTO form_responses SELECT ... FROM form_responses_old` — copies data
4. `DROP TABLE form_responses_old` — triggers destroyed

After this migration, all INSERT/UPDATE/DELETE operations on `form_responses` will silently skip change_log entries. Form responses will never sync to Supabase again until the app is reinstalled (which re-runs `onCreate` which creates triggers).

The plan mentions recreating indexes (Step 2.1.3, lines 278-290) but does NOT mention recreating the change_log triggers.

**Remediation**: Add trigger recreation to migration v47, after the index recreation:

```dart
// Step 7: Recreate change_log triggers (table rebuild drops them)
for (final trigger in SyncEngineTables.createTriggersForTable('form_responses')) {
  await db.execute(trigger);
}
```

This must be added to the plan before implementation.

---

## Advisory Findings (non-blocking, should be addressed)

### SEC-A1: SignOutDialog Sync-Then-SignOut Race Condition

**Severity**: MEDIUM
**Phase**: 5.2 (BLOCKER-38)

**Issue**: The `_syncThenSignOut` method (plan Step 5.2.1) catches sync errors silently and proceeds to sign out. When sync fails, the user sees the "Syncing..." spinner, then gets signed out without knowing their data did not sync. The "Sync & Sign Out" button implicitly promises the data will sync, but this catch block breaks that promise silently.

**Remediation**: On sync failure, show a snackbar or update the dialog to inform the user that sync failed, and let them choose "Sign Out Anyway" or "Cancel" rather than auto-proceeding to sign-out.

### SEC-A2: UserProfileSyncDatasource Fallback Path Bypasses Datasource Layer

**Severity**: MEDIUM
**Phase**: 3.1 (F4/F7)

**Issue**: Step 3.1.5 introduces a fallback `else` branch in `pullUserCertifications` that uses raw `db.insert` when `_certLocalDatasource` is null. The comment says "should not happen in production after DI wiring is complete" but the code path exists and would bypass the datasource abstraction this phase is meant to establish.

**Remediation**: Remove the fallback branch. If `_certLocalDatasource` is null, throw a `StateError` or log and skip the cert pull. A fallback to raw SQL defeats the purpose of F4/F7 and introduces a code path that is never tested.

### SEC-A3: SyncOrchestratorBuilder Fields Are Publicly Mutable After Build

**Severity**: LOW
**Phase**: 4.2 (F9)

**Issue**: The `SyncOrchestratorBuilder` uses publicly settable fields. After `build()` is called, nothing prevents the caller from mutating builder fields and calling `build()` again with different configuration.

**Remediation**: Consider making `build()` idempotent (throw if called twice) or making the builder single-use. Low priority since the builder is only used in `SyncInitializer.create()`.

---

## Summary

| ID | Severity | Blocking? | Phase | Finding |
|----|----------|-----------|-------|---------|
| SEC-R1 | HIGH | YES | 1.4 | Cross-tenant local data exposure after removing company-switch detection |
| SEC-R2 | HIGH | YES | 2.1 | Migration v47 drops change_log triggers, breaking form_responses sync |
| SEC-A1 | MEDIUM | No | 5.2 | Sync-then-signout silently proceeds on failure |
| SEC-A2 | MEDIUM | No | 3.1 | Raw SQL fallback path bypasses datasource layer |
| SEC-A3 | LOW | No | 4.2 | Builder fields publicly mutable after build |

**The plan requires revisions to address SEC-R1 and SEC-R2 before implementation can proceed.**
