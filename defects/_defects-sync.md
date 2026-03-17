# Defects: Sync

Active patterns for sync. Max 5 defects - oldest auto-archives.
Archive: .claude/logs/defects-archive.md

## Active Patterns

### [CONFIG] 2026-03-16: InternetAddress.lookup fails on Android despite good connectivity (Session 580)
**Pattern**: `SyncOrchestrator.checkDnsReachability()` used `InternetAddress.lookup(hostname)` which fails with errno=7 on Android even when `ping` from device shell resolves fine. Known Android issue — Dart's DNS lookup doesn't bind to the correct network interface after fresh install or process restart. Caused "Sync error - Device is offline" with good WiFi.
**Prevention**: Use HTTP HEAD request to the actual endpoint instead of raw DNS lookup. `http.head(Uri.parse('${SupabaseConfig.url}/rest/v1/'))` uses the HTTP client which properly binds to the active network interface. Also add `ACCESS_NETWORK_STATE` permission.
**Ref**: @lib/features/sync/application/sync_orchestrator.dart:420-447

### [DATA] 2026-03-16: RLS UPDATE policy allows any non-viewer to soft-delete any project (Session 580)
**Pattern**: `company_projects_update` policy at `20260222100000_multi_tenant_foundation.sql:454-456` only checks `NOT is_viewer()`. Any inspector/engineer can `UPDATE projects SET deleted_at = NOW()` on any project in the company. The owner/admin authorization gate claimed in the spec does not exist at the RLS layer.
**Prevention**: Tighten WITH CHECK: when `deleted_at` transitions NULL→non-NULL, require `created_by_user_id = auth.uid() OR is_approved_admin()`. New migration needed — see project lifecycle spec Section 12.
**Ref**: @supabase/migrations/20260222100000_multi_tenant_foundation.sql:454-456

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

<!-- Add defects above this line -->
