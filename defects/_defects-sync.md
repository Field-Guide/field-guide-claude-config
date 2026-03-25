# Defects: Sync

Active patterns for sync. Max 5 defects - oldest auto-archives.
Archive: .claude/logs/defects-archive.md

## Active Patterns

### [BUG] 2026-03-24: Sync engine crashes on server-side hard-deleted records
**Pattern**: When records exist in local SQLite but have been hard-deleted from Supabase (not soft-deleted), the sync engine fails and puts the app into a permanent "offline" state. App requires Settings > Clear Data to recover. Discovered when test cleanup hard-deleted SYNCTEST-* projects from Supabase — the phone app that had synced them could no longer sync at all.
**Root cause**: Sync engine doesn't handle the case where local records reference server records that no longer exist. Likely the push path tries to push a change for a record the server rejects, or the pull path encounters an inconsistency it can't resolve.
**Impact**: Any server-side hard-delete (admin purge, data migration, etc.) can brick the app for affected users.
**Fix needed**: Sync engine must detect orphaned local records (exist locally but not on server) and purge them gracefully instead of crashing. Consider adding an orphan-detection pass to the pull cycle.
**Ref**: Discovered in S635 during sync verification testing.

### [CONFIG] 2026-03-23: Sync verification scenarios use assumed names instead of actual codebase values
**Pattern**: All 94 L2/L3 scenarios hardcode route paths (`/projects/create`), widget keys (`save_project_button`), and API names that don't exist in the app. Passed 14 review sweeps because reviews checked internal consistency (spec ↔ plan) but never cross-referenced against live code (`app_router.dart`, `testing_keys/*.dart`).
**Prevention**: Ground Truth Verification added to writing-plans skill. Every string literal in plan code must be looked up against the actual source of truth before approval.
**Ref**: `tools/debug-server/scenarios/L2/*.js`, `.claude/skills/writing-plans/skill.md`

## Recently Fixed (Session 614)

### BUG-A: _pushDelete missing server timestamp writeback (Session 613→614)
**Fix**: Added `.select('updated_at, deleted_by')` + writeback with `pulling='1'` suppression. Added `conflicts`/`skippedFk` to `SyncEngineResult`. Verified via H001-H005 hypothesis markers.

### BUG-17: Re-login wipes all data (Session 608→610)
**Fix**: Removed `clearLocalCompanyData` from logout. Added company-switch guard in `signIn()`. Auto-enrollment via `_enrollProjectsFromAssignments()`.

### BUG-15: Integrity RPC cascade failure (Session 608→610)
**Fix**: Migration `20260320000003` added `entry_contractors` to allowlist, switched to `RETURNS TABLE`, fixed alias bug.

### BUG-006: Stale _isOnline flag (Session 591→610)
**Fix**: `checkDnsReachability()` called before every `isSupabaseOnline` read in `project_list_screen.dart` + defense-in-depth inside `_syncWithRetry()`.

### BUG-005: synced_projects enrollment gap (Session 591→610)
**Fix**: `_enrollProjectsFromAssignments()` runs unconditionally after `project_assignments` pull. Fresh-restore cursor guard. Orphan cleaner deadlock prevention via `_projectsAdapterCompleted`.

<!-- Add defects above this line -->
