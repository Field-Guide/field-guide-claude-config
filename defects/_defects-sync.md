# Defects: Sync

Active patterns for sync. Max 5 defects - oldest auto-archives.
Archive: .claude/logs/defects-archive.md

## Active Patterns

### [DATA] 2026-03-18: _refresh() silently skips sync based on stale _isOnline flag — BUG-006 (Session 591)
**Pattern**: `project_list_screen._refresh()` checks `orchestrator.isSupabaseOnline` before calling `syncLocalAgencyProjects()`. Once `_isOnline=false` (from any SocketException), `_refresh()` never calls `checkDnsReachability()` to re-test — it just reads the stale cached flag. Manual sync button becomes a no-op with zero user feedback. Only `fetchRemoteProjects()` (local SQLite read) runs, giving illusion of activity.
**Prevention**: Always call `checkDnsReachability()` in `_refresh()` before checking `isSupabaseOnline`. Or remove the gate entirely and let `syncLocalAgencyProjects()` handle connectivity internally via its retry logic.
**Ref**: @lib/features/projects/presentation/screens/project_list_screen.dart:73, @lib/features/sync/application/sync_orchestrator.dart:127

### [DATA] 2026-03-18: synced_projects enrollment gap — project exists locally but sync skips all child tables — BUG-005 (Session 591)
**Pattern**: Inspector device has `enrolled projects=1` in SQLite but `synced_projects entries=0`. The sync engine uses `synced_projects` to scope project-level pulls, so ALL 15 project-scoped tables are skipped ("Pull skip (no loaded projects)"). The project appears in the UI but is a dead shell with no data and no way to receive data via sync.
**Prevention**: Ensure every code path that inserts into the local `projects` table also creates a `synced_projects` row. Add a defensive check in `fetchRemoteProjects()` to detect and repair orphaned projects missing enrollment.
**Ref**: @lib/features/sync/engine/sync_engine.dart:1304, @lib/features/projects/presentation/providers/project_provider.dart

### [DATA] 2026-03-18: _pushUpsert writes back server updated_at without suppressing change_log trigger (Session 588)
**Pattern**: After successful Supabase upsert, `_pushUpsert()` writes the server-assigned `updated_at` back to local SQLite via `db.update()`. This fires the `AFTER UPDATE` trigger which inserts a new `change_log` row with `processed=0`. The original change gets marked processed, but the phantom entry doesn't — pending count never drops to 0.
**Prevention**: Wrap all local DB writes that are sync-engine bookkeeping (not user data) with `pulling=1` guard to suppress triggers. The photo push path (`_pushPhotoThreePhase`) already does this correctly.
**Ref**: @lib/features/sync/engine/sync_engine.dart:620-628

### [DATA] 2026-03-18: Permanent offline trap — _isOnline never recovers once false (Session 587)
**Pattern**: `_syncWithRetry()` only called `checkDnsReachability()` on retry attempts (attempt > 0), not the first attempt. `SyncLifecycleManager._handleResumed()` read cached `isSupabaseOnline` before calling `checkDnsReachability()`. Once `_isOnline=false`, no code path ever re-tested it → app stuck offline permanently even with good connectivity.
**Prevention**: Always call `checkDnsReachability()` before trusting `_isOnline`. Never gate a DNS re-check on the cached result of a previous DNS check. Every sync attempt (including first) must verify connectivity. Admin/UI retry must call the live check, not read the cache.
**Ref**: @lib/features/sync/application/sync_orchestrator.dart:288, @lib/features/sync/application/sync_lifecycle_manager.dart:88

### [DATA] 2026-03-18: Delete Forever skips Supabase — raw database.delete() bypasses change_log (Session 587)
**Pattern**: `TrashScreen._confirmDeleteForever()` called `database.delete()` directly instead of `SoftDeleteService.hardDeleteWithSync()`. No change_log entry created, so sync never pushed the delete to Supabase. Remote record persisted and was re-downloaded on next pull.
**Prevention**: Never use raw `database.delete()` for user-facing delete operations. Always use `SoftDeleteService.hardDeleteWithSync()` which suppresses triggers, hard-deletes, and manually inserts a change_log entry.
**Ref**: @lib/features/settings/presentation/screens/trash_screen.dart:316

<!-- Add defects above this line -->
