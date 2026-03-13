# Code Review: Sync Engine Hardening Plan

**Verdict: CONDITIONAL APPROVE** — 2 CRITICAL, 3 HIGH, 6 MEDIUM, 4 LOW
**Reviewer**: code-review-agent (Opus)
**Date**: 2026-03-13

## CRITICAL (Must Fix)

1. **RPC missing company ownership check — privilege escalation**
   - Phase 1B: `get_pending_requests_with_profiles` checks `is_approved_admin()` but does NOT verify caller's company matches `p_company_id`. Admin of Company A could query Company B's requests.
   - Fix: Add company-match guard after `is_approved_admin()` check.

2. **Both SQL functions missing `SET search_path = public`**
   - Phase 1A `stamp_deleted_by()` and Phase 1B RPC both declared as SECURITY DEFINER without `SET search_path = public`. Search-path injection risk.
   - Spec explicitly includes it. Plan omits it.

## HIGH (Should Fix)

3. **RPC missing REVOKE/GRANT and STABLE volatility**
   - No `REVOKE FROM anon` / `GRANT TO authenticated`. Spec requires both.

4. **Orphan auto-delete never activated — call site not updated**
   - Phase 5F rewrites OrphanScanner with `autoDelete` flag but never updates `sync_engine.dart:196` to pass `autoDelete: true`.

5. **Sync dashboard circuit breaker banner has no UI step**
   - Spec 3L requires dismissable banner. Plan Phase 7A exposes state but no widget step.

## MEDIUM

6. Wrong file path: `entry_contractor_adapter.dart` → `entry_contractors_adapter.dart` (plural)
7. `user_certification_adapter.dart` doesn't exist — table not synced, pre-check moot
8. Migration timestamps mismatch (spec: 20260313*, plan: 20260314*)
10. Phase 5D (FK per-record blocking) underspecified — defers design to implementer
11. Phase 4B (conflict race fix) no-op correct but needs code comment referencing Spec 3G

## LOW

12. assert() line number off by 1 (117 vs 118)
13. Double cursor reset paths (IntegrityChecker.run + pushAndPull)
14. Orphan scanner `file.createdAt` API needs verification against SDK
15. Missing company_id validation test (Phase 8 gap)

## Positive Observations
- 15/16 fixes covered (16th correctly identified as no-op)
- Phase ordering correct
- WHY/NOTE/FROM SPEC annotations on every code block
- TOCTOU safety net properly implemented
- Agent routing correct
- 9 dispatch groups well-structured
