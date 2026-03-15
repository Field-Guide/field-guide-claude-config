# Defects: Sync

Active patterns for sync. Max 5 defects - oldest auto-archives.
Archive: .claude/logs/defects-archive.md

## Active Patterns

### [CONFIG] 2026-03-13: Migration used wrong column name for user_profiles PK (Session 563)
**Pattern**: Email backfill SQL used `up.user_id` but `user_profiles` PK is `id` (1:1 with `auth.users.id`). Migration failed on deploy.
**Prevention**: `user_profiles` uses `id` as PK/FK to auth.users, NOT `user_id`. Always verify column names against actual schema before writing SQL.
**Ref**: @supabase/migrations/20260313100000_sync_hardening_triggers.sql:98

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

<!-- Add defects above this line -->
