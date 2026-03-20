# Plan Review: Bug Triage Fix (2026-03-19)

**Plan**: `.claude/plans/2026-03-19-bug-triage-fix.md`
**Spec**: `.claude/specs/2026-03-19-bug-triage-fix-spec.md`
**Reviewers**: code-review-agent, security-agent
**Date**: 2026-03-19

## Initial Verdict: REJECT (both reviewers)

## Findings Addressed (all fixed in plan)

### CRITICAL (3) — All Fixed
1. **RLS policy names were placeholders** → Fixed: exact names `company_projects_insert/update/delete`
2. **UPDATE policy dropped soft-delete guards** → Fixed: preserved `deleted_at`/`created_by_user_id`/`is_approved_admin()` clauses
3. **DELETE policy not tightened (SEC-002)** → Fixed: added Step 4 to tighten to `is_admin_or_engineer()`

### HIGH (5) — All Fixed
4. **Timer callback missing async + DNS check** → Fixed: `async` callback with `checkDnsReachability()` + `_disposed` guard
5. **Missing bulk canWrite migration (~87+ sites)** → Fixed: added Phase 8
6. **`_checkNetwork` async conversion breaks caller** → Fixed: dual sync/async methods, explicit `_handleImport` fix
7. **Orphan cleaner snippet unclosed braces** → Fixed: complete structure with `else` branch + contractor loading note
8. **Route guard before profile null check (SEC-003)** → Fixed: placed inside `if (profile != null)` block near admin-dashboard guard

### MEDIUM (4) — All Fixed
9. **`toggleActive()` no provider guard** → Fixed: added `_canManageProjects` callback + defense-in-depth guard
10. **Timer use-after-dispose (SEC-005)** → Fixed: `_disposed` flag
11. **No Details tab read-only test** → Fixed: added Sub-phase 7.4
12. **No-op Sub-phase 2.3** → Fixed: removed

### Acknowledged (not fixed — acceptable)
- SEC-004: TOCTOU between JWT and profile (verified: user_profiles UPDATE policy restricts self-role-escalation)
- SEC-006: `canEditFieldData` is a no-op (acceptable: semantically correct, future-proof)
- SEC-007: No RLS integration tests (deferred: requires Supabase test infrastructure)
- SEC-008: Orphan cleaner per-instance flag (acceptable: SyncMutex prevents concurrent engines)
- SEC-009: Mock auth bypasses route guards (acceptable: test-only)

## Final Verdict: APPROVED (after all fixes applied)
