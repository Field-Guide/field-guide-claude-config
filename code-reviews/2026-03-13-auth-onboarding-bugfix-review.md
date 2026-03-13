# Code Review: Auth/Onboarding Bugfix Plan

**Plan:** `.claude/plans/2026-03-13-auth-onboarding-bugfix.md`
**Date:** 2026-03-13
**Reviewer:** code-review (inline)

## Completeness

- [x] Bug 1 (router flash) fully addressed with correct guard placement
- [x] Bug 2 (search) root cause (SQL return type mismatch) correctly identified and fixed
- [x] Error logging added to prevent silent failures in future
- [x] All file paths verified against codebase

## Edge Cases Verified

| Scenario | Result |
|----------|--------|
| Cold start with cached session | isLoadingProfile set in constructor (line 74-76), never hits line 128 on auth route |
| Sign-in from login screen | Guard holds user on /login until profile loads, then redirects |
| Sign-up from register screen | Same as sign-in |
| Authenticated user navigating to /login | isLoadingProfile=false, redirects to / immediately (correct) |
| Mock auth mode | Lines 90-101 bypass entire redirect chain, no impact |
| isLoadingProfile stuck true | Cannot happen -- finally block at auth_provider.dart:551-554 always clears |
| search_companies with < 3 chars | Returns empty (preserved from original) |
| User already has company searching | Returns empty (preserved from original) |

## Findings

### MEDIUM: Test coverage is minimal
The proposed test in Phase 3 only verifies `isLoadingProfile` state transitions. It does NOT test the actual router redirect behavior because testing GoRouter redirect requires widget test setup with mock providers. The test is more of a documentation exercise than a regression gate.

**Recommendation:** Add a note that a Patrol E2E test of the sign-up flow would be the real regression gate. The unit test is acceptable as a first pass.

### LOW: Migration file naming
The migration timestamp `20260313000000` should follow the existing pattern. The latest migration is `20260306000000`. The gap is fine but verify no other migrations have been added between sessions.

### LOW: REVOKE statement may be redundant
`CREATE OR REPLACE` on a function with the same signature preserves existing grants. The `REVOKE` is defensive and harmless but technically unnecessary since the original function already had this applied.

**Recommendation:** Keep the REVOKE -- defensive security is appropriate here.

## Verdict: APPROVE

No critical or high findings. The plan is correct, minimal, and safe to implement.
