# Code Review: Data, Database & Sync Audit Remediation Plan

**Plan**: `.claude/plans/2026-04-02-data-sync-audit-remediation.md`
**Reviewer**: Code Review Agent
**Date**: 2026-04-01
**Cycle**: 2
**Verdict**: **REJECT** — 2 HIGH, 1 MEDIUM, 1 LOW (all cycle 1 criticals resolved)

---

## Cycle 1 Findings — All Resolved

CR-1 triggers FIXED, CR-2 syncAll FIXED, CR-3 cert_number FIXED, CR-4 partially fixed, CR-5 DDL FIXED, CR-6 indexes FIXED, CR-7 partially fixed, CR-8 dead code FIXED, CR-9 import FIXED.

---

## New Issues

### CR-10 (HIGH): SyncEngineFactory.createForBackground signature mismatch

`createForBackground` takes companyId/userId and passes to `SyncEngine.createForBackgroundSync`, but that static factory only takes `{required Database database, required SupabaseClient supabase}` and resolves auth internally. Also param name mismatch: factory uses `db:` but static factory uses `database:`.

**Fix**: Remove companyId/userId from createForBackground. Use `database:` param name.

### CR-11 (HIGH): EntryContractorsRepository API fundamentally wrong + missing consumer

Repository assumes GenericLocalDatasource CRUD but actual datasources have entry-scoped, junction-table APIs (e.g., `add(entryId, contractorId)` not `saveContractor(EntryContractor)`). Also `entry_editor_screen.dart` (lines 124-126, 159-161) is a 5th consumer not listed in plan.

**Fix**: Redesign repository to expose actual datasource methods. Add entry_editor_screen.dart to consumer list.

### CR-12 (MEDIUM): Silent catch violates A9

`catch (_)` in `_checkUnsyncedChanges` needs Logger call.

### CR-13 (LOW): Factory test doesn't test create path

Acceptable if implementing agent adds coverage. Note in plan.
