# Plan Review: Project State UI & Assignments

**Date:** 2026-03-18
**Plan:** `.claude/plans/2026-03-18-project-state-ui.md`
**Reviewers:** code-review-agent, security-agent

## Review Verdict: REJECT → Fixed Inline

### CRITICAL Fixes Applied

1. **CRIT-1**: `enforce_created_by()` writes to `created_by_user_id`, not `assigned_by` → Created dedicated `enforce_assignment_assigned_by()` trigger function
2. **CRIT-2**: `project_assignments` in `triggeredTables` causes RLS denial storm on inspector devices → Removed from `triggeredTables`, change_log triggers only installed for admin/engineer push; adapter marked pull-only for inspectors
3. **CRIT-3**: Missing `fix_auto_enrollment` migration → Noted as already fixed in prior commits (v30 backfill already removed)
4. **CRIT-4**: `onPullComplete` missing deletion detection for `unassigned_at` → Added deletion detection logic

### HIGH Fixes Applied

5. **HIGH-1**: `full_name` → `display_name` column mismatch in `_loadAssignments()` Supabase query
6. **HIGH-2**: Creator auto-assignment not implemented (locked checkbox) → Added `lockedUserId` field + logic
7. **HIGH-3**: `RemovalDialog` needs `isOnline` parameter for offline Sync & Remove check
8. **HIGH-4**: `assignedBy` can be empty string → Added non-null assertion
9. **HIGH-5**: `enrollProject`/`unenrollProject` pass `DatabaseService` as parameter → Noted for implementing agent to use instance field

### MEDIUM Noted (for implementing agent)

- Schema verifier may need `unassigned_at` column entry
- Auto-enrollment callback should move to repository (not raw DB in main.dart)
- Filter chip counts not shown (minor UX gap)
- `companyProjectsCount` shows unfiltered total (intentional per spec)
- Audit log `RAISE LOG` is not durable (tracked as follow-up)
