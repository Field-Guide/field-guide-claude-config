# Security Review: Sync Engine Hardening Plan

**Verdict: APPROVE WITH REQUIRED FIXES** — 3 HIGH, 3 MEDIUM, 2 LOW
**Reviewer**: security-agent (Opus)
**Date**: 2026-03-13

## HIGH (Must Fix Before Implementation)

1. **H-1: `stamp_deleted_by()` missing `SET search_path = public`**
   - SECURITY DEFINER without search_path. `auth.uid()` could be hijacked via schema-squatting.

2. **H-2: `get_pending_requests_with_profiles` missing `SET search_path`, `REVOKE`, `GRANT`**
   - Anonymous callers could invoke the RPC. Same search_path risk as H-1.

3. **H-3: `get_pending_requests_with_profiles` missing company-match guard**
   - Admin of Company A can pass Company B's UUID → cross-company PII exposure.

## MEDIUM

- M-1: Conflict log `lost_data` stores PII field values (not just column names)
- M-2: `user_certifications` adapter referenced but doesn't exist
- M-3: Email backfill permanently copies email into user-visible `user_profiles` table

## LOW

- L-1: Orphan scanner delete lacks path format validation
- L-2: `debugPrint` in AdminRepository exposes raw error details

## Auth Assessment
- stamp_deleted_by: PASS (SECURITY DEFINER, auth.uid(), BEFORE UPDATE, NULL→non-NULL guard)
- stamp_deleted_by SET search_path: **FAIL** (H-1)
- RPC is_approved_admin: PASS
- RPC company match: **FAIL** (H-3)
- RPC SET search_path: **FAIL** (H-2)
- RPC REVOKE/GRANT: **FAIL** (H-2)
- assert→throw: PASS (all 6 locations)

## OWASP Mobile Top 10
- M3 Insecure Auth: PARTIAL (H-3 cross-company RPC)
- M4 Input Validation: PASS
- M6 Privacy: PARTIAL (M-1 conflict PII, M-3 email backfill)
- M8 Security Misconfiguration: PARTIAL (H-1, H-2 missing search_path)

## Positive Observations
1. Server-side `stamp_deleted_by()` correctly prevents client spoofing
2. Pre-check explicitly documented as NOT a security boundary
3. Changed-columns-only conflict diff minimizes PII
4. Pull cursor safety margin kept (preventing data loss)
5. Circuit breaker with auto-purge prevents runaway push loops
6. Orphan scanner has 24h age threshold + 50-per-cycle cap
