# Security Review: Auth/Onboarding Bugfix Plan

**Plan:** `.claude/plans/2026-03-13-auth-onboarding-bugfix.md`
**Date:** 2026-03-13
**Reviewer:** security (inline)

## Bug 1: Router Guard Change

### Auth Bypass Risk Assessment

**Question:** Could the `isLoadingProfile` guard at line 128 create an authentication bypass?

**Answer: No.**

The guard only returns `null` (stay on current route) when the user IS authenticated but profile is still loading. The flow is:
1. User is authenticated (line 122 check passed)
2. User is on an auth route (login/register)
3. Profile is loading -> stay on auth route (safe -- user sees login screen)

The worst case if `isLoadingProfile` gets stuck is the user is trapped on the auth screen. They would need to sign out and back in. There is no path where an unauthenticated user bypasses login.

**Mitigating control:** `loadUserProfile()` has a `finally` block (auth_provider.dart:551-554) that ALWAYS sets `_isLoadingProfile = false`, so stuck-state is not a realistic scenario.

### Privilege Escalation Risk: None

The change does not modify any profile-based routing (company check, status check, admin check). Those guards at lines 166-217 are unaffected.

## Bug 2: SQL Migration

### Data Exposure Assessment

**Question:** Does adding `created_at` and `updated_at` to search results expose sensitive data?

**Answer: No.**

These are standard audit timestamps on a company entity. They reveal when a company was created/updated, which is not sensitive. The company `name` is already exposed by the search. No PII or security-relevant data is added.

### RLS Implications

- Function remains `SECURITY DEFINER` -- runs as function owner, bypassing RLS
- This is correct and required -- the `companies` table has RLS policies that restrict access to same-company users, but search must show companies the user does NOT belong to
- Existing guards preserved:
  - `auth.uid() IS NULL` check prevents unauthenticated access
  - `caller_company_id IS NOT NULL` check prevents already-in-company users from searching
  - `length(query) < 3` prevents enumeration via single-character queries
  - `LIMIT 10` prevents full table dump

### Grant Verification

- `REVOKE EXECUTE ON FUNCTION search_companies FROM anon;` re-applied
- `CREATE OR REPLACE` preserves the function OID but best practice is to re-apply REVOKE
- No new GRANT statements -- function remains callable only by `authenticated` role

## Findings

### No Critical or High findings.

### MEDIUM: CREATE OR REPLACE resets function body but may affect cached query plans
PostgreSQL may cache query plans for functions called via RPC. After `CREATE OR REPLACE`, cached plans are invalidated. This could cause a brief performance blip on first call. Not a security issue, but noted for completeness.

## Verdict: APPROVE

No security concerns. The router change preserves all existing auth guards. The SQL migration maintains the security posture of the original function while fixing the return type.
