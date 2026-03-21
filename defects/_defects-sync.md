# Defects: Sync

Active patterns for sync. Max 5 defects - oldest auto-archives.
Archive: .claude/logs/defects-archive.md

## Active Patterns

_No active defects._

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
