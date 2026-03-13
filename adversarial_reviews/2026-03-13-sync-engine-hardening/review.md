# Adversarial Review: Sync Engine Hardening

**Spec**: `.claude/specs/2026-03-13-sync-engine-hardening-spec.md`
**Date**: 2026-03-13
**Reviewers**: code-review-agent (Opus), security-agent (Opus)
**Verdict**: APPROVE with findings (all addressed)

## MUST-FIX (all resolved in spec v2)

| # | Finding | Source | Resolution |
|---|---------|--------|-----------|
| MF-1 | 5 of 6 UNIQUE constraints were invalid (3 already exist, 2 target nonexistent tables) | Code review | Corrected. Only personnel_types needs verification. |
| MF-2 | Soft-delete trigger design ambiguous (UPDATE vs DELETE locally) | Code review | Resolved: Option A (local soft-delete via UPDATE). |
| MF-3 | Removing pull safety margin creates data loss from transaction skew | Code review | Section 3H changed to "keep existing." No code change. |
| MF-4 | 23505 after clean pre-check treated as permanent (should be retryable) | Code review | Now retryable. Re-runs pre-check next cycle. |
| MF-5 | `deleted_by` can be spoofed (no server enforcement) | Security review | `stamp_deleted_by()` trigger added to all 16 tables. |
| MF-6 | `assert()` in AdminRepository stripped in release builds | Security review | Replace with runtime `throw StateError()`. |

## SHOULD-CONSIDER (all resolved)

| # | Finding | Source | Resolution |
|---|---------|--------|-----------|
| SC-2 | company_id validation scope unclear for non-project tables | Security | Clarified: only projects has company_id column. |
| SC-3 | view_own_request RLS allows deactivated admins | Security | Tightened to use is_approved_admin(). |
| SC-4 | user_profiles.email not backfilled from auth.users | Security | One-time migration added. |
| SC-5 | Pre-check described as if it were a security boundary | Security | Documented: UX optimization only. UNIQUE constraint is real guard. |
| A2 | onConflict approach is simpler and atomic vs pre-check | Code review | User chose pre-check for friendlier UX. Dropped adapter architecture. |
| A3 | Keep pull safety margin instead of strict greater-than | Code review | Accepted. Cursor logic unchanged. |

## NICE-TO-HAVE (noted for future)

| # | Finding | Source |
|---|---------|--------|
| NH-1 | Rate limiting on new RPC | Security |
| NH-2 | Include file paths in orphan deletion audit log | Security |
| NH-3 | Circuit breaker threshold should be configurable | Security |
| NH-4 | lock_created_by() trigger interaction evaluated (safe) | Security |
| NH-5 | Soft-deleted project children remain accessible via RLS (intentional) | Security |

## Security Review — RLS Compatibility Matrix

All 16 synced tables verified compatible with soft-delete UPDATE:
- All have `deleted_at`/`deleted_by` columns (added in migrations 20260304*)
- All have UPDATE RLS policies with USING clause (no WITH CHECK)
- Soft-delete UPDATE will pass RLS on all tables
- No policy migration needed for the UPDATE path

## OWASP Mobile Top 10 (this spec)

| # | Risk | Status |
|---|------|--------|
| M3 | Insecure Auth/Authz | FIXED (assert→runtime, stamp_deleted_by trigger) |
| M4 | Insufficient Input Validation | PASS (pre-check + 23505 safety net) |
| M6 | Inadequate Privacy | PASS (email only to is_approved_admin) |
| M8 | Security Misconfiguration | PASS (SECURITY DEFINER + SET search_path) |
