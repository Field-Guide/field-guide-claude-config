# Plan Review: Project Management E2E

**Plan**: `.claude/plans/2026-03-17-project-management-e2e.md`
**Spec**: `.claude/specs/2026-03-17-project-management-e2e-spec.md`
**Date**: 2026-03-17

## Code Review: REJECT → FIXED (all CRIT/HIGH addressed)

### CRITICAL (Fixed)
- CR-CRIT-1: SQL parameter names mismatch (p_request_id vs request_id) → Fixed: matched existing signatures
- CR-CRIT-2: 13 `isViewer` references in entry_editor_screen.dart not addressed → Fixed: listed all locations

### HIGH (Fixed)
- CR-HIGH-3: `is_viewer()` function becomes dead code → Fixed: added TODO comment in migration
- CR-HIGH-4: `get_my_role()` doesn't exist → Fixed: inlined subquery
- CR-HIGH-5: `_loadSyncedProjectIds()` reload removal breaks child sync → Fixed: keep reload, only remove auto-enroll
- CR-HIGH-6: Failed import card state missing implementation → Fixed: added Step 7.1.8

### MEDIUM (Noted)
- CR-MED-7: Minimal change for RPC safer than full rewrite → Accepted: kept minimal
- CR-MED-8: async VoidCallback in SyncProvider → Noted: fire-and-forget acceptable
- CR-MED-9: `_handleAuthError` logging missing → Fixed: added Step 3.3.2
- CR-MED-10: Orphan cleanup on Projects screen open → Deferred to Phase 7 _refresh()
- CR-MED-11: `canDeleteProject` signature differs from spec → Acceptable: plan approach is better
- CR-MED-12: `canEditProject` deferred → Acceptable for v1

### LOW (Noted)
- Line numbers are approximate, skeleton tests need implementation detail

## Security Review: APPROVE WITH CONDITIONS → FIXED

### CONDITIONS (Fixed)
- SEC-C-1: `get_my_role()` doesn't exist → Fixed: inlined subquery
- SEC-C-2: RPC parameter name mismatch → Fixed: matched existing signatures
- SEC-C-3: `is_viewer()` dead code → Fixed: added TODO comment
- SEC-C-4: Missing `SET search_path = public` → Fixed: added to both RPCs

### OBSERVATIONS (Noted)
- O-1: No child cascade in admin RPC → Acceptable: client handles
- O-2: Boolean admin parameter pattern → Server enforces
- O-3: Trigger suppression pattern → Correctly wrapped in try/finally
