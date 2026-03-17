# Plan Review: Sync Hardening & RLS Enforcement

**Plan**: `.claude/plans/2026-03-17-sync-hardening-and-rls.md`
**Date**: 2026-03-17

## Code Review Verdict: REJECT → FIXED
- 2 CRITICAL, 5 HIGH, 4 MEDIUM findings
- All CRITICAL and HIGH findings addressed inline in plan revision

## Security Review Verdict: APPROVE WITH CONDITIONS → CONDITIONS MET
- 2 CRITICAL, 4 HIGH, 4 MEDIUM findings
- All CRITICAL and blocking findings addressed inline in plan revision

## Key Fixes Applied
1. Offline removal guard moved to service layer (ProjectLifecycleService)
2. ConflictResolver keeps `Future<ConflictWinner>` return type — uses `getConflictCount()` query
3. DB version bumped to 36, createConflictLogTable constant updated
4. Supabase migration uses `DROP POLICY IF EXISTS` defensively
5. Step 1.2.2 expanded to cover entry_equipment and entry_contractors
6. company_id comparison uses `?.toString()` to prevent type mismatches
7. Phases 2.1.1 and 3.2.1 consolidated into single final code block
8. All SyncEngineResult construction sites enumerated
9. Magic number 3 → `SyncEngineConfig.conflictPingPongThreshold`
10. EntryPersonnelCountsAdapter fkColumnMap corrected to `type_id`
11. Conflict_log cleanup for circuit-broken records added
12. Migration rollback block documented

## Accepted Risks (Not Fixed)
- HIGH-4 (per-record FK blocking TOCTOU): Existing pattern, caught by error handler
- MED-1 (RLS error message in logs): Logger release scrubbing handles this per S582
- MED-3 (project UUID in sync logs): Acceptable given existing Logger scrubbing
- LOW-2 (conflict_count DEFAULT 0): Correct mitigation already in plan
- LOW-3 (old app version transition): Expected behavior — users update app
