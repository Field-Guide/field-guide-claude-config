# Defects: Sync

Active patterns for sync. Max 5 defects - oldest auto-archives.
Archive: .claude/logs/defects-archive.md

## Active Patterns

### [DATA] 2026-03-13: Sync pushes hard DELETE instead of soft-delete UPDATE — BLOCKER-29 (Session 558)
**Pattern**: `_pushDelete()` calls `.delete().eq('id', recordId)` (hard delete) but SQLite uses soft-delete (`deleted_at`). Record disappears from server. Next pull re-creates it locally. Deleted data resurrects.
**Prevention**: Push soft-delete as `.update({'deleted_at': timestamp, 'deleted_by': userId})`. Pull must respect `deleted_at`. Add `stamp_deleted_by()` server trigger.
**Ref**: @lib/features/sync/engine/sync_engine.dart:327-339

### [DATA] 2026-03-13: Upsert uses PRIMARY KEY conflict but tables have compound UNIQUE — BLOCKER-24 (Session 558)
**Pattern**: `.upsert(payload)` defaults to `id` as conflict target. `projects` has `UNIQUE(company_id, project_number)`. Different UUID + same project number → INSERT → duplicate key crash. Blocks all child table sync.
**Prevention**: Pre-check for existing match on natural key before upsert. Categorize `23505` as retryable (TOCTOU safety net). SQLite constraints already exist for projects/entry_contractors/user_certifications.
**Ref**: @lib/features/sync/engine/sync_engine.dart:398-399

### [FLUTTER] 2026-03-06: Mock SyncOrchestrator missing getPendingBuckets() causes test hang (Session 511)
**Pattern**: `MockSyncOrchestrator` overrode `getPendingCount()` but not `getPendingBuckets()`. Hits real DB init → hangs forever in test binding.
**Prevention**: When mocking SyncOrchestrator, ALWAYS override both methods. Remove unnecessary `Future.delayed()` from mocks.
**Ref**: @test/features/sync/presentation/widgets/sync_status_icon_test.dart:170

### [ASYNC] 2026-03-06: _lastSyncTime persisted on failure creates 24h dead zone (Session 511)
**Pattern**: `_lastSyncTime = DateTime.now()` ran unconditionally after sync — even on failure. Lifecycle manager saw recent timestamp and wouldn't force retry for 24 hours.
**Prevention**: Only update `_lastSyncTime` inside the success block. Failed syncs should leave old timestamp.
**Ref**: @lib/features/sync/application/sync_orchestrator.dart:224-237

### [CONFIG] 2026-03-06: Stale config banner checks only checkConfig() timestamp (Session 508)
**Pattern**: `AppConfigProvider.isConfigStale` only checks `_lastConfigCheckAt`. Successful sync also proves server reachability but doesn't reset the clock.
**Prevention**: Unify staleness to `max(lastConfigCheck, lastSyncSuccess) > 24h`.
**Ref**: @lib/features/auth/presentation/providers/app_config_provider.dart:57-61

<!-- Add defects above this line -->
