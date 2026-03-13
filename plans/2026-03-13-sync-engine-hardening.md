# Sync Engine Hardening Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Fix 2 active blockers (BLOCKER-24, BLOCKER-29), 4 critical data integrity bugs, 9 robustness improvements, and 1 admin UI fix
**Spec:** `.claude/specs/2026-03-13-sync-engine-hardening-spec.md`
**Analysis:** `.claude/dependency_graphs/2026-03-13-sync-engine-hardening/`

**Architecture:** Sync engine hardening across push/pull/infrastructure layers. Supabase migrations for server-side triggers and RPC. Admin dashboard gets join request display with name/email.
**Tech Stack:** Dart/Flutter, SQLite, Supabase (PostgreSQL), RLS
**Blast Radius:** 14 direct, 6 dependent, 7+7 tests, 4 cleanup

## Agent Routing Table

| File Pattern | Agent |
|-------------|-------|
| `lib/features/sync/**` | `backend-supabase-agent` |
| `lib/core/database/**` | `backend-data-layer-agent` |
| `lib/features/settings/data/**` | `backend-data-layer-agent` |
| `lib/features/auth/data/models/**` | `backend-data-layer-agent` |
| `lib/features/settings/presentation/**` | `frontend-flutter-specialist-agent` |
| `lib/features/sync/presentation/**` | `frontend-flutter-specialist-agent` |
| `supabase/**` | `backend-supabase-agent` |
| `test/**` | `qa-testing-agent` |

---

## Phase 1: Supabase Migrations (server-side first)

Server-side changes that have no app dependencies. Deploy independently.

### Phase 1A: stamp_deleted_by Trigger + RLS Tightening + Email Backfill

**File:** `supabase/migrations/20260313100000_sync_hardening_triggers.sql`

#### Step 1A.1: Create the stamp_deleted_by() trigger function

```sql
-- WHY: Prevents deleted_by spoofing (MF-5). Server enforces auth.uid() regardless
-- of what the client sends. Defense-in-depth: client sets it too, but server overwrites.
CREATE OR REPLACE FUNCTION stamp_deleted_by()
RETURNS TRIGGER AS $$
BEGIN
  -- Only stamp when deleted_at transitions from NULL to non-NULL
  IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
    NEW.deleted_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

#### Step 1A.2: Apply trigger to all 16 synced tables

```sql
-- FROM SPEC: All 16 tables in SyncEngineTables.triggeredTables
-- NOTE: Using BEFORE UPDATE so we can modify NEW.deleted_by before it hits disk
DO $$
DECLARE
  tbl TEXT;
  tbls TEXT[] := ARRAY[
    'projects', 'locations', 'contractors', 'equipment', 'bid_items',
    'personnel_types', 'daily_entries', 'photos', 'entry_equipment',
    'entry_quantities', 'entry_contractors', 'entry_personnel_counts',
    'inspector_forms', 'form_responses', 'todo_items', 'calculation_history'
  ];
BEGIN
  FOREACH tbl IN ARRAY tbls LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%I_stamp_deleted_by
       BEFORE UPDATE ON %I
       FOR EACH ROW
       EXECUTE FUNCTION stamp_deleted_by()',
      tbl, tbl
    );
  END LOOP;
END;
$$;
```

#### Step 1A.3: Tighten RLS — view_own_request uses is_approved_admin()

```sql
-- WHY: Current policy may allow non-admins to view requests. Tighten to admin-only.
-- FROM SPEC: Section 2.2 — RLS fix
DROP POLICY IF EXISTS "view_own_request" ON company_join_requests;

CREATE POLICY "view_own_request" ON company_join_requests
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR is_approved_admin()
  );
```

#### Step 1A.4: Backfill email from auth.users into user_profiles

```sql
-- WHY: user_profiles.email may be NULL for users created before email was tracked.
-- FROM SPEC: Section 2.2 — email backfill
UPDATE user_profiles up
SET email = au.email
FROM auth.users au
WHERE up.user_id = au.id
  AND (up.email IS NULL OR up.email = '');
```

**Verification:** Deploy via Supabase dashboard or CLI. Verify trigger exists:
```sql
SELECT tgname FROM pg_trigger WHERE tgname LIKE 'trg_%_stamp_deleted_by';
-- Should return 16 rows
```

### Phase 1B: get_pending_requests_with_profiles RPC

**File:** `supabase/migrations/20260313100001_pending_requests_rpc.sql`

#### Step 1B.1: Create the RPC function

```sql
-- WHY: Admin dashboard needs display_name + email for join requests.
-- Current UI shows truncated UUID. RPC joins with user_profiles in one call.
-- FROM SPEC: Section 2.2, Section 4
-- SECURITY: SECURITY DEFINER guarded by is_approved_admin() check
CREATE OR REPLACE FUNCTION get_pending_requests_with_profiles(p_company_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  company_id UUID,
  company_name TEXT,
  status TEXT,
  requested_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  display_name TEXT,
  email TEXT
) AS $$
BEGIN
  -- Guard: caller must be an approved admin
  IF NOT is_approved_admin() THEN
    RAISE EXCEPTION 'Access denied: caller is not an approved admin';
  END IF;

  -- Guard: caller's company must match the requested company (H-3 fix)
  -- WHY: Without this, admin of Company A could query Company B's join requests
  IF p_company_id != (SELECT up.company_id FROM user_profiles up WHERE up.user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Access denied: company mismatch';
  END IF;

  RETURN QUERY
  SELECT
    cjr.id,
    cjr.user_id,
    cjr.company_id,
    cjr.company_name,
    cjr.status,
    cjr.requested_at,
    cjr.resolved_at,
    cjr.resolved_by,
    COALESCE(up.display_name, 'Unknown') AS display_name,
    COALESCE(up.email, au.email, '') AS email
  FROM company_join_requests cjr
  LEFT JOIN user_profiles up ON up.user_id = cjr.user_id
  LEFT JOIN auth.users au ON au.id = cjr.user_id
  WHERE cjr.company_id = p_company_id
    AND cjr.status = 'pending'
  ORDER BY cjr.requested_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- H-2 fix: Restrict access to authenticated users only
REVOKE ALL ON FUNCTION get_pending_requests_with_profiles(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION get_pending_requests_with_profiles(UUID) TO authenticated;
```

**Verification:** Call from Supabase SQL editor:
```sql
SELECT * FROM get_pending_requests_with_profiles('<your-company-uuid>');
```

---

## Phase 2: SyncEngineConfig + Schema Updates (foundation)

Local config and schema changes that later phases depend on.

### Phase 2A: Add New Config Constants

**File:** `lib/features/sync/config/sync_config.dart` (lines 1-49)

#### Step 2A.1: Update staleLockTimeout and add new constants

Add after line 31 (`staleLockTimeout`), and add new constants at the end of the class.

```dart
// WHY: 5 min was too aggressive — long syncs on slow connections get killed.
// FROM SPEC: Section 3J
static const Duration staleLockTimeout = Duration(minutes: 15); // was 5

// -- Circuit Breaker --
// WHY: Runaway change_log can flood push and starve other operations.
// FROM SPEC: Section 3L
static const int circuitBreakerThreshold = 1000;

// -- Cursor Reset --
// WHY: Minor count diffs shouldn't trigger expensive full re-pulls.
// FROM SPEC: Section 3N
static const int cursorResetMinDiff = 5;
static const double cursorResetPercentThreshold = 0.10;

// -- Integrity --
// WHY: Infinite reset loops when data is genuinely different server-side.
// FROM SPEC: Section 3K
static const int maxConsecutiveResets = 3;

// -- Orphan Cleanup --
// WHY: Auto-cleanup needs bounds to avoid runaway deletion.
// FROM SPEC: Section 3O
static const Duration orphanMinAge = Duration(hours: 24);
static const int orphanMaxPerCycle = 50;
```

Full file after edit — `sync_config.dart`:

```dart
class SyncEngineConfig {
  SyncEngineConfig._();

  // -- Push --
  static const int pushBatchLimit = 500;
  static const int pushAnomalyThreshold = 1000;
  static const int maxRetryCount = 5;

  // -- Pull --
  static const int pullPageSize = 100;
  static const Duration pullSafetyMargin = Duration(seconds: 5);

  // -- Integrity --
  static const Duration integrityCheckInterval = Duration(hours: 4);
  static const int maxConsecutiveResets = 3;

  // -- Lock --
  static const Duration staleLockTimeout = Duration(minutes: 15);

  // -- Pruning --
  static const Duration changeLogRetention = Duration(days: 7);
  static const Duration conflictLogRetention = Duration(days: 7);
  static const Duration conflictWarningAge = Duration(days: 30);

  // -- Retry backoff --
  static const Duration retryBaseDelay = Duration(seconds: 1);
  static const Duration retryMaxDelay = Duration(seconds: 16);

  // -- Circuit Breaker --
  static const int circuitBreakerThreshold = 1000;

  // -- Cursor Reset Tolerance --
  static const int cursorResetMinDiff = 5;
  static const double cursorResetPercentThreshold = 0.10;

  // -- Orphan Cleanup --
  static const Duration orphanMinAge = Duration(hours: 24);
  static const int orphanMaxPerCycle = 50;
}
```

**Verification:** `pwsh -Command "flutter analyze lib/features/sync/config/sync_config.dart"`

### Phase 2B: Update SyncEngineTables — Add last_heartbeat to sync_lock

**File:** `lib/core/database/schema/sync_engine_tables.dart` (lines 49-55)

#### Step 2B.1: Add last_heartbeat column to sync_lock schema

Update the `createSyncLockTable` constant:

```dart
// WHY: Heartbeat enables stale detection based on activity, not just lock age.
// FROM SPEC: Section 3J — heartbeat every 60s, stale if >2 min ago
static const String createSyncLockTable = '''
  CREATE TABLE IF NOT EXISTS sync_lock (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    locked_at TEXT NOT NULL,
    locked_by TEXT NOT NULL,
    last_heartbeat TEXT NOT NULL
  )
''';
```

**NOTE:** Fresh installs get this automatically. Existing installs need the migration in Phase 2C.

### Phase 2C: DatabaseService._onUpgrade — Version 34 Migration

**File:** `lib/core/database/database_service.dart`

#### Step 2C.1: Bump version from 33 to 34

Change both `version: 33` occurrences to `version: 34`.

#### Step 2C.2: Add migration block for version 34

Add to the `_onUpgrade` method:

```dart
if (oldVersion < 34) {
  // Sync Engine Hardening: Phase 2C
  // 1. Add last_heartbeat column to sync_lock
  // WHY: Heartbeat-based stale detection (Spec 3J)
  final lockCols = await db.rawQuery("PRAGMA table_info(sync_lock)");
  final hasHeartbeat = lockCols.any((c) => c['name'] == 'last_heartbeat');
  if (!hasHeartbeat) {
    await db.execute("ALTER TABLE sync_lock ADD COLUMN last_heartbeat TEXT NOT NULL DEFAULT ''");
  }

  // 2. Verify personnel_types has UNIQUE(project_id, semantic_name)
  // WHY: Spec 2.1 — only table that needs verification. Others already have constraints.
  // NOTE: SQLite cannot ADD CONSTRAINT after table creation. If missing, recreate.
  final ptIndexes = await db.rawQuery(
    "SELECT sql FROM sqlite_master WHERE type='index' AND tbl_name='personnel_types'"
  );
  final hasUniqueConstraint = ptIndexes.any((idx) =>
    (idx['sql'] as String? ?? '').contains('project_id') &&
    (idx['sql'] as String? ?? '').contains('semantic_name')
  );
  if (!hasUniqueConstraint) {
    // Check table_info for the constraint in the CREATE TABLE statement
    final tableInfo = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name='personnel_types'"
    );
    final createSql = tableInfo.first['sql'] as String? ?? '';
    if (!createSql.contains('UNIQUE')) {
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_personnel_types_unique '
        'ON personnel_types(project_id, semantic_name)'
      );
    }
  }
}
```

**Verification:** `pwsh -Command "flutter test test/core/database/"` (if DB tests exist), otherwise `pwsh -Command "flutter analyze lib/core/database/"`

---

## Phase 3: Push Flow Hardening (BLOCKER-24, BLOCKER-29)

Core data integrity fixes. This is the most critical phase.

### Phase 3A: Soft-Delete Push Detection (BLOCKER-29 fix)

**File:** `lib/features/sync/engine/sync_engine.dart`

#### Step 3A.1: Rewrite _pushDelete to send UPDATE instead of DELETE

Replace the entire `_pushDelete` method (lines 327-339):

```dart
/// Push a soft-delete: sends UPDATE with deleted_at/deleted_by instead of
/// hard DELETE. This prevents the resurrection bug (BLOCKER-29) where
/// hard-deleted records get re-created on next pull.
///
/// WHY: Hard delete removes the record from Supabase. Next pull sees it's
/// missing locally (soft-deleted, still in SQLite), pulls nothing, but the
/// local soft-deleted record persists. If another device pulls, the record
/// is gone. Inconsistent state across devices.
/// FROM SPEC: Section 3A — Soft-Delete Push
Future<void> _pushDelete(TableAdapter adapter, ChangeEntry change) async {
  // Read local record to get deleted_at and deleted_by values
  final localRows = await db.query(
    adapter.tableName,
    where: 'id = ?',
    whereArgs: [change.recordId],
  );

  if (localRows.isEmpty) {
    // Record truly gone from SQLite — already cleaned up
    DebugLogger.sync(
      'Soft-delete skip: ${adapter.tableName}/${change.recordId} — '
      'no local record',
    );
    return;
  }

  final localRecord = localRows.first;
  final deletedAt = localRecord['deleted_at'];

  if (deletedAt == null) {
    // Record exists but is NOT soft-deleted. The change_log says 'delete'
    // but the record was restored before push ran. Skip.
    DebugLogger.sync(
      'Soft-delete skip: ${adapter.tableName}/${change.recordId} — '
      'record not deleted (restored?)',
    );
    return;
  }

  // Send UPDATE with only deleted_at and deleted_by
  // NOTE: stamp_deleted_by() trigger on Supabase will overwrite deleted_by
  // with auth.uid() for security, but we send it anyway for consistency.
  await supabase.from(adapter.tableName).update({
    'deleted_at': deletedAt,
    'deleted_by': localRecord['deleted_by'] ?? userId,
    'updated_at': localRecord['updated_at'],
  }).eq('id', change.recordId);
}
```

#### Step 3A.2: Update _push to detect soft-deletes in change_log 'update' operations

In the `_push` method (line 283), add soft-delete detection before the operation check. The change_log will have operation='update' when the app sets deleted_at via UPDATE (not DELETE). We need to detect this.

Replace the operation routing block (lines 282-287):

```dart
for (final change in tableChanges) {
  try {
    // Detect soft-delete: operation is 'update' but record has deleted_at
    // WHY: App sets deleted_at via UPDATE → trigger fires with operation='update'
    // FROM SPEC: Section 3A — "SQLite UPDATE trigger fires → change_log operation='update'"
    if (change.operation == 'delete') {
      await _pushDelete(adapter, change);
    } else if (change.operation == 'update') {
      // Check if this is a soft-delete (deleted_at set)
      final localRows = await db.query(
        adapter.tableName,
        columns: ['deleted_at'],
        where: 'id = ?',
        whereArgs: [change.recordId],
      );
      if (localRows.isNotEmpty && localRows.first['deleted_at'] != null) {
        await _pushDelete(adapter, change);
      } else {
        await _pushUpsert(adapter, change);
      }
    } else {
      await _pushUpsert(adapter, change);
    }
```

**NOTE:** The closing braces and error handling remain the same as the existing code.

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/sync_engine_test.dart"`

### Phase 3B: Upsert Pre-Check for UNIQUE-Constrained Tables (BLOCKER-24 fix)

**File:** `lib/features/sync/engine/sync_engine.dart`

#### Step 3B.1: Add natural key definitions to TableAdapter

**File:** `lib/features/sync/adapters/table_adapter.dart`

Add after line 51 (after `userStampColumns`):

```dart
/// Natural key columns for UNIQUE constraint pre-check.
/// If non-empty, the engine will query Supabase for existing records
/// matching these columns before upserting, to prevent 23505 errors.
/// FROM SPEC: Section 3B — Upsert Pre-Check
///
/// Example: projects returns ['company_id', 'project_number']
/// meaning the engine checks: "does a record with this company_id AND
/// project_number already exist with a DIFFERENT id?"
List<String> get naturalKeyColumns => const [];
```

#### Step 3B.2: Override naturalKeyColumns in affected adapters

**File:** `lib/features/sync/adapters/project_adapter.dart` — add override:
```dart
@override
List<String> get naturalKeyColumns => const ['company_id', 'project_number'];
```

**File:** `lib/features/sync/adapters/entry_contractors_adapter.dart` — add override:
```dart
@override
List<String> get naturalKeyColumns => const ['entry_id', 'contractor_id'];
```

**NOTE:** `user_certifications` has no sync adapter (table is not synced via SyncEngine).
Pre-check is not needed — the UNIQUE constraint in SQLite is sufficient. Skipped per review M-7.

**File:** `lib/features/sync/adapters/personnel_type_adapter.dart` — add override:
```dart
@override
List<String> get naturalKeyColumns => const ['project_id', 'semantic_name'];
```

#### Step 3B.3: Add _preCheckUniqueConstraint method to SyncEngine

**File:** `lib/features/sync/engine/sync_engine.dart`

Add new method after `_pushUpsert` (after line 400):

```dart
/// Pre-check for UNIQUE constraint violations before upsert.
///
/// Returns null if safe to proceed, or an error message if a different
/// record already occupies the natural key slot.
///
/// WHY: Prevents 23505 crash (BLOCKER-24) by detecting conflicts before
/// they happen. Gives the user a meaningful error message instead of a
/// cryptic PostgreSQL constraint violation.
/// FROM SPEC: Section 3B — Upsert Pre-Check
///
/// TOCTOU note: If pre-check passes but upsert still hits 23505, the error
/// handler treats it as retryable (another device raced us).
Future<String?> _preCheckUniqueConstraint(
  TableAdapter adapter,
  Map<String, dynamic> payload,
) async {
  if (adapter.naturalKeyColumns.isEmpty) return null;

  // Build the query: match all natural key columns
  var query = supabase.from(adapter.tableName).select('id');
  for (final col in adapter.naturalKeyColumns) {
    final value = payload[col];
    if (value == null) return null; // Can't pre-check with null keys
    query = query.eq(col, value);
  }

  final existing = await query.maybeSingle();
  if (existing == null) return null; // No conflict

  final existingId = existing['id'] as String?;
  if (existingId == payload['id']) return null; // Same record — update is fine

  // Different record occupies the slot
  final keyDesc = adapter.naturalKeyColumns
      .map((col) => '$col=${payload[col]}')
      .join(', ');
  return 'Duplicate: ${adapter.tableName} with $keyDesc already exists '
      '(id=$existingId). Cannot create another with id=${payload["id"]}.';
}
```

#### Step 3B.4: Call pre-check in _pushUpsert

**File:** `lib/features/sync/engine/sync_engine.dart`

In `_pushUpsert`, add after `var payload = adapter.convertForRemote(localRecord);` (line 363) and before the user stamp columns block (line 366):

```dart
    // Pre-check UNIQUE constraints before upsert
    // WHY: Prevents 23505 crash with meaningful error (BLOCKER-24)
    // FROM SPEC: Section 3B
    final preCheckError = await _preCheckUniqueConstraint(adapter, payload);
    if (preCheckError != null) {
      throw StateError(preCheckError);
    }
```

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/sync_engine_test.dart"`

### Phase 3C: Company ID Validation

**File:** `lib/features/sync/engine/sync_engine.dart`

#### Step 3C.1: Add company ID validation in _pushUpsert

In `_pushUpsert`, replace the existing company_id stamping block (lines 371-374) with validation + stamping:

```dart
    // Company ID validation + stamping
    // WHY: Defense-in-depth. RLS enforces server-side, but catching it client-side
    // gives a clear error message and avoids wasting a network round-trip.
    // FROM SPEC: Section 3C — Company ID Validation
    if (adapter.tableName == 'projects') {
      if (payload['company_id'] == null || payload['company_id'] == '') {
        payload['company_id'] = companyId;
      } else if (payload['company_id'] != companyId) {
        throw StateError(
          'Company ID mismatch: record has ${payload["company_id"]} '
          'but current user belongs to $companyId. '
          'Refusing to push cross-company data.',
        );
      }
    }
```

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/sync_engine_test.dart"`

### Phase 3D: Photo Cleanup on Partial Failure

**File:** `lib/features/sync/engine/sync_engine.dart`

#### Step 3D.1: Add cleanup in _pushPhotoThreePhase

In `_pushPhotoThreePhase`, wrap Phase 2 (metadata upsert at line 459-460) in a try-catch that cleans up Phase 1's upload on failure:

Replace lines 458-460:

```dart
    // Phase 2: Upsert metadata with FRESH remote_path
    payload['remote_path'] = remotePath;
    try {
      await supabase.from(adapter.tableName).upsert(payload);
    } catch (e) {
      // WHY: If Phase 2 fails, Phase 1's uploaded file becomes orphaned.
      // Clean up immediately rather than waiting for OrphanScanner.
      // FROM SPEC: Section 3D — Photo Cleanup on Partial Failure
      DebugLogger.sync(
        'Photo ${change.recordId}: Phase 2 failed, cleaning up uploaded file at $remotePath',
      );
      try {
        await supabase.storage.from('entry-photos').remove([remotePath!]);
      } catch (cleanupError) {
        // Best-effort cleanup. If this also fails, OrphanScanner will catch it.
        DebugLogger.sync(
          'Photo ${change.recordId}: cleanup also failed: $cleanupError',
        );
      }
      rethrow;
    }
```

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/photo_sync_test.dart"`

### Phase 3E: Error Categorization

**File:** `lib/features/sync/engine/sync_engine.dart`

#### Step 3E.1: Rewrite _handlePushError with proper categorization

Replace the entire `_handlePushError` method (lines 529-588):

```dart
/// Categorize push errors and determine retry strategy.
///
/// Error categories (FROM SPEC Section 3E):
/// - 23505 → constraint violation (retryable if TOCTOU race after clean pre-check)
/// - 42501 → RLS denied (permanent — user lacks permission)
/// - 23503 → FK violation (permanent — parent record missing)
/// - 401/403/PGRST301 → auth error (retry after refresh)
/// - 429/503 → rate limited (retry with backoff)
/// - network → retry with backoff
Future<bool> _handlePushError(Object error, ChangeEntry change) async {
  if (error is PostgrestException) {
    final code = error.code ?? '';
    final message = error.message;

    // Auth error: refresh token and retry
    if (code.contains('401') ||
        code == 'PGRST301' ||
        message.contains('JWT')) {
      final refreshed = await _handleAuthError();
      if (refreshed) {
        return true; // Retry — do NOT increment retry_count
      }
      throw StateError('Auth refresh failed, aborting sync');
    }

    // Rate limit / service unavailable: retryable with backoff
    if (code.contains('429') ||
        code.contains('503') ||
        message.contains('Too Many') ||
        message.contains('Service Unavailable')) {
      final delay = _computeBackoff(change.retryCount);
      await Future.delayed(delay);
      if (change.retryCount == 0) {
        await _changeTracker.markFailed(
          change.id,
          'Retryable (rate limited): $message',
        );
        return true;
      }
      await _changeTracker.markFailed(change.id, 'Rate limited: $message');
      return false;
    }

    // Constraint violation (23505): retryable if TOCTOU race
    // WHY: Pre-check passed but another device inserted between check and upsert
    // FROM SPEC: Section 3B — "if pre-check passes but upsert hits 23505 → retryable"
    if (code == '23505') {
      if (change.retryCount < 2) {
        await _changeTracker.markFailed(
          change.id,
          'Constraint race (23505): $message — will retry',
        );
        return true;
      }
      await _changeTracker.markFailed(
        change.id,
        'Constraint violation (23505): $message',
      );
      return false;
    }

    // RLS denied (42501): permanent
    if (code == '42501') {
      await _changeTracker.markFailed(
        change.id,
        'RLS denied (42501): $message',
      );
      return false;
    }

    // FK violation (23503): permanent — parent record missing
    if (code == '23503') {
      await _changeTracker.markFailed(
        change.id,
        'FK violation (23503): $message',
      );
      return false;
    }

    // All other PostgrestException: permanent
    await _changeTracker.markFailed(
      change.id,
      'Permanent ($code): $message',
    );
    return false;
  }

  if (error is SocketException || error is TimeoutException) {
    final delay = _computeBackoff(change.retryCount);
    await Future.delayed(delay);
    if (change.retryCount == 0) {
      await _changeTracker.markFailed(
        change.id,
        'Network error: $error',
      );
      return true;
    }
    await _changeTracker.markFailed(change.id, 'Network: $error');
    return false;
  }

  // Unknown error
  await _changeTracker.markFailed(change.id, error.toString());
  return false;
}
```

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/sync_engine_test.dart"`

---

## Phase 4: Pull Flow Hardening

### Phase 4A: Soft-Delete Pull Handling

**File:** `lib/features/sync/engine/sync_engine.dart`

#### Step 4A.1: Handle soft-deleted records during pull

The existing pull code at lines 727-740 already handles the case where a remote record has `deleted_at` set and doesn't exist locally (skips it at line 731). For records that DO exist locally, the conflict resolver runs and remote wins, applying the soft-delete. This is correct behavior per Spec 3F.

No code change needed for the basic case. The existing `_pullTable` method at line 729-732 already does:
```dart
if (remote['deleted_at'] != null) {
  // Skip already-deleted records
  continue;
}
```

And for existing local records, the conflict resolution at lines 758-774 already applies the remote (including deleted_at/deleted_by).

**NOTE:** This step confirms the pull flow is already correct for soft-delete. No modifications required.

### Phase 4B: Conflict Resolution Race Fix

**File:** `lib/features/sync/engine/sync_engine.dart`

#### Step 4B.1: Snapshot updated_at when local wins conflict

In `_pullTable`, when local wins (line 775-783), snapshot the record's updated_at so that on later push, we use the current version, not a stale one.

Replace the local-wins block (lines 775-783):

```dart
          } else {
            // Local wins: keep local version, push it back
            // WHY: Snapshot updated_at so that when this change_log entry is
            // pushed, we re-read the local record. If updated_at has changed
            // since we made this decision, we use the newer version.
            // FROM SPEC: Section 3G — Conflict Resolution Race Fix
            await _changeTracker.insertManualChange(
              adapter.tableName,
              recordId,
              'update',
            );
            // NOTE: The _pushUpsert method already re-reads the local record
            // at push time (line 343-347), so it always pushes the latest
            // version. No additional snapshot storage is needed.
          }
```

**ANALYSIS:** On review, `_pushUpsert` already re-reads the local record at push time (lines 343-355). The "race fix" from the spec is already inherently handled because we never cache the record — we always read fresh from SQLite before pushing. The manual change_log entry created here will cause `_pushUpsert` to re-read the current state at push time.

**No code change needed.** The existing architecture already handles this correctly. Document this in a comment for clarity.

### Phase 4C: Null Timestamp Conflict Resolution

**File:** `lib/features/sync/engine/conflict_resolver.dart` (lines 35-37)

#### Step 4C.1: Update null timestamp handling per Spec 3I

Replace the null check block (lines 35-37):

```dart
    // Null timestamp handling (FROM SPEC: Section 3I)
    // WHY: Previous behavior (either null → remote wins) was too aggressive.
    // If we have a valid local timestamp and remote is null, local should win.
    if (localUpdatedAt == null && remoteUpdatedAt == null) {
      // Both null: remote wins (safety default)
      winner = ConflictWinner.remote;
    } else if (remoteUpdatedAt == null) {
      // Null remote + valid local → local wins
      winner = ConflictWinner.local;
    } else if (localUpdatedAt == null) {
      // Null local + valid remote → remote wins
      winner = ConflictWinner.remote;
    } else if (remoteUpdatedAt.compareTo(localUpdatedAt) >= 0) {
```

The full method after edit becomes:

```dart
    if (localUpdatedAt == null && remoteUpdatedAt == null) {
      winner = ConflictWinner.remote;
    } else if (remoteUpdatedAt == null) {
      winner = ConflictWinner.local;
    } else if (localUpdatedAt == null) {
      winner = ConflictWinner.remote;
    } else if (remoteUpdatedAt.compareTo(localUpdatedAt) >= 0) {
      winner = ConflictWinner.remote;
    } else {
      winner = ConflictWinner.local;
    }
```

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/conflict_resolver_test.dart"`

---

## Phase 5: Infrastructure Hardening

### Phase 5A: Sync Mutex Heartbeat

**File:** `lib/features/sync/engine/sync_mutex.dart`

#### Step 5A.1: Add heartbeat support to SyncMutex

Rewrite the entire file:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:construction_inspector/features/sync/config/sync_config.dart';

/// SQLite advisory lock for cross-isolate sync mutex.
///
/// Uses the sync_lock table (single-row, id=1) to ensure only one
/// sync process runs at a time, even across foreground and background isolates.
///
/// The lock has a stale timeout (15 minutes) with heartbeat-based detection.
/// FROM SPEC: Section 3J — heartbeat every 60s, stale if >2 min ago
class SyncMutex {
  final Database _db;

  SyncMutex(this._db);

  /// Try to acquire the lock. Returns true if successful.
  ///
  /// Steps:
  /// 1. Expire stale locks (heartbeat > 2 min ago OR locked_at > 15 min ago)
  /// 2. INSERT the lock row. If row already exists, return false.
  Future<bool> tryAcquire(String lockedBy) async {
    // Expire stale locks: either heartbeat is stale (>2 min) or lock age exceeds timeout
    // WHY: Heartbeat-based detection catches stuck processes faster than lock age alone
    final timeoutMinutes = SyncEngineConfig.staleLockTimeout.inMinutes;
    await _db.execute(
      "DELETE FROM sync_lock WHERE "
      "locked_at < strftime('%Y-%m-%dT%H:%M:%f', 'now', '-$timeoutMinutes minutes') "
      "OR (last_heartbeat != '' AND last_heartbeat < strftime('%Y-%m-%dT%H:%M:%f', 'now', '-2 minutes'))",
    );

    try {
      final now = "strftime('%Y-%m-%dT%H:%M:%f', 'now')";
      await _db.execute(
        "INSERT INTO sync_lock (id, locked_at, locked_by, last_heartbeat) "
        "VALUES (1, $now, ?, $now)",
        [lockedBy],
      );
      return true;
    } catch (_) {
      // Row already exists — another process holds the lock
      return false;
    }
  }

  /// Update the heartbeat timestamp. Call every ~60 seconds during long syncs.
  /// FROM SPEC: Section 3J — "Update every 60s"
  Future<void> heartbeat() async {
    await _db.execute(
      "UPDATE sync_lock SET last_heartbeat = strftime('%Y-%m-%dT%H:%M:%f', 'now') WHERE id = 1",
    );
  }

  /// Release the lock.
  Future<void> release() async {
    await _db.execute('DELETE FROM sync_lock WHERE id = 1');
  }

  /// Force-clear locks owned by this process. Called on app startup.
  Future<void> forceReset(String lockedBy) async {
    await _db.execute(
      'DELETE FROM sync_lock WHERE locked_by = ?',
      [lockedBy],
    );
  }
}
```

#### Step 5A.2: Add heartbeat timer to SyncEngine.syncAll

In `sync_engine.dart`, in the main sync orchestration method, add a periodic heartbeat timer that runs during push+pull. Find the `syncAll()` or equivalent method and add:

```dart
// Start heartbeat timer during sync
// WHY: Long syncs (large photo batches) can exceed stale timeout.
// FROM SPEC: Section 3J — "Update every 60s"
final heartbeatTimer = Timer.periodic(
  const Duration(seconds: 60),
  (_) => _mutex.heartbeat(),
);
try {
  // ... existing push/pull logic ...
} finally {
  heartbeatTimer.cancel();
}
```

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/sync_mutex_test.dart"`

### Phase 5B: Integrity Checker — Max Reset Guard

**File:** `lib/features/sync/engine/integrity_checker.dart`

#### Step 5B.1: Track consecutive resets per table and cap at 3

Add a field and modify the `run()` method:

Add after line 44 (`IntegrityChecker(this._db, this._supabase);`):

```dart
  // Track consecutive resets to prevent infinite re-pull loops
  // WHY: If data is genuinely different server-side (e.g., different RLS view),
  // resetting the cursor every 4 hours just wastes bandwidth.
  // FROM SPEC: Section 3K — Max Reset Guard
  final Map<String, int> _consecutiveResets = {};
```

Replace the drift handling block (lines 74-84):

```dart
        if (!result.passed) {
          DebugLogger.sync(
            'INTEGRITY DRIFT: ${adapter.tableName} - ${result.mismatchReason}',
          );

          // Max reset guard: stop resetting after N consecutive failures
          // FROM SPEC: Section 3K
          final resets = _consecutiveResets[adapter.tableName] ?? 0;
          if (resets >= SyncEngineConfig.maxConsecutiveResets) {
            DebugLogger.sync(
              'INTEGRITY GUARD: ${adapter.tableName} has drifted '
              '${resets}x consecutively. Skipping cursor reset. '
              'Manual investigation needed.',
            );
          } else {
            // Reset pull cursor to trigger full re-pull
            await _db.delete(
              'sync_metadata',
              where: 'key = ?',
              whereArgs: ['last_pull_${adapter.tableName}'],
            );
            _consecutiveResets[adapter.tableName] = resets + 1;
          }
        } else {
          // Table passed — reset the consecutive counter
          _consecutiveResets.remove(adapter.tableName);
        }
```

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/integrity_checker_test.dart"`

### Phase 5C: Change Tracker Circuit Breaker

**File:** `lib/features/sync/engine/change_tracker.dart`

#### Step 5C.1: Add circuit breaker check and auto-purge methods

Add after the `pruneProcessed` method (after line 141):

```dart
  /// Check if the circuit breaker should trip.
  ///
  /// Returns true if unprocessed change_log count exceeds the threshold.
  /// FROM SPEC: Section 3L — Circuit Breaker
  Future<bool> isCircuitBreakerTripped() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM change_log WHERE processed = 0',
    );
    final count = result.first['cnt'] as int;
    return count > SyncEngineConfig.circuitBreakerThreshold;
  }

  /// Get the current unprocessed change count.
  Future<int> getPendingCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM change_log WHERE processed = 0',
    );
    return result.first['cnt'] as int;
  }

  /// Auto-purge old failed entries that have exhausted retries.
  ///
  /// Removes entries >7 days old with 3+ retries. This prevents the
  /// circuit breaker from staying tripped due to ancient failures.
  /// FROM SPEC: Section 3L — "Auto-purge entries >7 days with 3+ retries"
  Future<int> purgeOldFailures() async {
    final retentionDays = SyncEngineConfig.changeLogRetention.inDays;
    final result = await _db.rawDelete(
      "DELETE FROM change_log WHERE processed = 0 "
      "AND retry_count >= 3 "
      "AND changed_at < strftime('%Y-%m-%dT%H:%M:%f', 'now', '-$retentionDays days')",
    );
    if (result > 0) {
      DebugLogger.sync('Circuit breaker: purged $result old failed entries');
    }
    return result;
  }
```

#### Step 5C.2: Add circuit breaker check in SyncEngine._push

In `_push()` (line 243), add circuit breaker check at the top, after getting changes:

```dart
  Future<SyncEngineResult> _push() async {
    // Circuit breaker: refuse to push if change_log is flooded
    // WHY: Prevents runaway push loops from overwhelming Supabase.
    // FROM SPEC: Section 3L
    if (await _changeTracker.isCircuitBreakerTripped()) {
      // Auto-purge old failures first
      await _changeTracker.purgeOldFailures();
      // Re-check after purge
      if (await _changeTracker.isCircuitBreakerTripped()) {
        DebugLogger.sync(
          'CIRCUIT BREAKER: change_log exceeds ${SyncEngineConfig.circuitBreakerThreshold}. '
          'Push suspended. User action required.',
        );
        return SyncEngineResult(
          errors: 1,
          errorMessages: ['Circuit breaker tripped: too many pending changes'],
        );
      }
    }

    final changes = await _changeTracker.getUnprocessedChanges();
    // ... rest of method unchanged ...
```

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/change_tracker_test.dart"`

### Phase 5D: FK Per-Record Blocking

**File:** `lib/features/sync/engine/change_tracker.dart`

#### Step 5D.1: Add per-record FK failure check

Add method:

```dart
  /// Check if a specific parent record has failed in the change_log.
  ///
  /// Unlike [hasFailedEntries] which checks the entire table, this checks
  /// a specific record_id. Used for per-record FK blocking.
  /// FROM SPEC: Section 3M — "Only block children whose specific parent has failed"
  Future<bool> hasFailedRecord(String tableName, String recordId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM change_log '
      'WHERE processed = 0 AND table_name = ? AND record_id = ? AND retry_count >= ?',
      [tableName, recordId, SyncEngineConfig.maxRetryCount],
    );
    return (result.first['cnt'] as int) > 0;
  }
```

#### Step 5D.2: Update FK blocking in SyncEngine._push to use per-record check

In `_push()`, replace the table-level FK blocking (lines 260-278) with per-record blocking:

```dart
      // FK dependency pre-check: per-record blocking
      // WHY: Table-level blocking is too coarse. One failed project shouldn't
      // block entries for other projects.
      // FROM SPEC: Section 3M — Per-Record Blocking
      //
      // NOTE: For tables with FK dependencies, we check each change's specific
      // parent record rather than blocking the entire table.
      // The old table-level check is kept as a fast-path for tables where
      // ALL parents have failed (unlikely but possible).
```

**IMPLEMENTATION NOTE:** Per-record FK blocking requires knowing which column is the FK for each parent dependency. This is complex to implement generically. A simpler approach: keep the existing table-level blocking but add a per-record override for the common case (entries blocked by projects).

The implementer should evaluate whether the table-level blocking is sufficient for the initial release, or if per-record blocking is needed immediately. If table-level is kept, add a TODO comment referencing the spec.

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/change_tracker_test.dart"`

### Phase 5E: Cursor Reset Tolerance

**File:** `lib/features/sync/engine/integrity_checker.dart`

#### Step 5E.1: Add tolerance check before resetting cursor

In the drift handling block (inside `run()`), before resetting the cursor, check if the drift exceeds the tolerance threshold:

Replace the cursor reset logic with:

```dart
          if (resets >= SyncEngineConfig.maxConsecutiveResets) {
            DebugLogger.sync(
              'INTEGRITY GUARD: ${adapter.tableName} has drifted '
              '${resets}x consecutively. Skipping cursor reset.',
            );
          } else {
            // Cursor reset tolerance: only reset if count diff is significant
            // WHY: Minor diffs from transaction timing shouldn't trigger re-pulls
            // FROM SPEC: Section 3N
            final countDiff = (result.localCount - result.remoteCount).abs();
            final threshold = max(
              SyncEngineConfig.cursorResetMinDiff,
              (result.remoteCount * SyncEngineConfig.cursorResetPercentThreshold).round(),
            );

            if (countDiff <= threshold && result.mismatchReason!.contains('Count')) {
              DebugLogger.sync(
                'INTEGRITY TOLERATED: ${adapter.tableName} count diff '
                '$countDiff <= threshold $threshold. Not resetting cursor.',
              );
            } else {
              await _db.delete(
                'sync_metadata',
                where: 'key = ?',
                whereArgs: ['last_pull_${adapter.tableName}'],
              );
              _consecutiveResets[adapter.tableName] = resets + 1;
            }
          }
```

Add `import 'dart:math' show max;` at the top of the file.

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/integrity_checker_test.dart"`

### Phase 5F: Orphan Auto-Cleanup

**File:** `lib/features/sync/engine/orphan_scanner.dart`

#### Step 5F.1: Add auto-delete capability with age filter and cap

Rewrite the `scan` method to accept `autoDelete` flag and add a new `_getFileAge` helper:

```dart
import 'package:construction_inspector/core/logging/debug_logger.dart';
import 'package:construction_inspector/features/sync/config/sync_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Scans Supabase Storage for orphaned photo files.
///
/// Queries the REMOTE photos table to get all known remote_paths. Then lists
/// all files in storage under the company prefix and flags any files that have
/// no corresponding DB row.
class OrphanScanner {
  final SupabaseClient _client;
  static const String _bucket = 'entry-photos';

  OrphanScanner(this._client);

  /// Scan for orphaned storage files under the company prefix.
  ///
  /// If [autoDelete] is true, deletes orphans older than 24h, capped at
  /// 50 per cycle. Returns list of orphaned paths (deleted or not).
  /// FROM SPEC: Section 3O — Orphan Auto-Cleanup
  Future<List<String>> scan(String companyId, {bool autoDelete = false}) async {
    try {
      // 1. Query REMOTE photos table
      final remotePhotos = await _client
          .from('photos')
          .select('remote_path')
          .not('remote_path', 'is', null)
          .neq('remote_path', '');

      final knownPaths = (remotePhotos as List)
          .map((r) => r['remote_path'] as String)
          .toSet();

      // 2. List storage files under company prefix
      final prefix = 'entries/$companyId/';
      final storageFiles =
          await _client.storage.from(_bucket).list(path: prefix);

      // 3. Recursively list entry subdirectories
      final allStorageFiles = <_StorageFileInfo>[];
      for (final dir in storageFiles) {
        if (dir.name.isEmpty) continue;
        final entryPrefix = '$prefix${dir.name}/';
        final files =
            await _client.storage.from(_bucket).list(path: entryPrefix);
        for (final file in files) {
          if (file.name.isNotEmpty) {
            allStorageFiles.add(_StorageFileInfo(
              path: '$entryPrefix${file.name}',
              createdAt: file.createdAt != null
                  ? DateTime.tryParse(file.createdAt!)
                  : null,
            ));
          }
        }
      }

      // 4. Diff: storage paths not in known remote paths
      final orphans = allStorageFiles
          .where((f) => !knownPaths.contains(f.path))
          .toList();

      if (orphans.isNotEmpty) {
        DebugLogger.sync(
          'OrphanScanner: found ${orphans.length} orphaned files under $prefix',
        );
      }

      // 5. Auto-delete if requested
      if (autoDelete && orphans.isNotEmpty) {
        final now = DateTime.now().toUtc();
        final minAge = SyncEngineConfig.orphanMinAge;
        final maxPerCycle = SyncEngineConfig.orphanMaxPerCycle;

        final deletable = orphans
            .where((f) =>
                f.createdAt != null &&
                now.difference(f.createdAt!) > minAge)
            .take(maxPerCycle)
            .toList();

        if (deletable.isNotEmpty) {
          final paths = deletable.map((f) => f.path).toList();
          try {
            await _client.storage.from(_bucket).remove(paths);
            DebugLogger.sync(
              'OrphanScanner: auto-deleted ${paths.length} orphaned files',
            );
            for (final path in paths) {
              DebugLogger.sync('OrphanScanner: deleted $path');
            }
          } catch (e) {
            DebugLogger.error('OrphanScanner: auto-delete failed', error: e);
          }
        }
      }

      return orphans.map((f) => f.path).toList();
    } catch (e) {
      DebugLogger.error('OrphanScanner: scan failed', error: e);
      return [];
    }
  }
}

class _StorageFileInfo {
  final String path;
  final DateTime? createdAt;
  _StorageFileInfo({required this.path, this.createdAt});
}
```

#### Step 5F.2: Update call site in pushAndPull to enable auto-delete

**File:** `lib/features/sync/engine/sync_engine.dart` (line ~196)

Replace the orphan scanner call inside `pushAndPull()`:

```dart
// BEFORE:
final orphans = await _orphanScanner.scan(companyId);

// AFTER:
// WHY: H-4 fix — orphan scanner was scan-only, never deleted.
// FROM SPEC: Section 3O — auto-delete files >24h with no DB match
final orphans = await _orphanScanner.scan(companyId, autoDelete: true);
```

**Verification:** `pwsh -Command "flutter test test/features/sync/engine/orphan_scanner_test.dart"`

---

## Phase 6: Admin Dashboard (UI + RPC)

### Phase 6A: CompanyJoinRequest Model Update

**File:** `lib/features/auth/data/models/company_join_request.dart`

#### Step 6A.1: Add displayName and email fields

Add fields after `resolvedBy` (line 23):

```dart
  /// Display name from user_profiles (populated by RPC join).
  /// FROM SPEC: Section 2.3
  final String? displayName;

  /// Email from user_profiles or auth.users (populated by RPC join).
  /// FROM SPEC: Section 2.3
  final String? email;
```

#### Step 6A.2: Update constructor

Add `this.displayName` and `this.email` to the constructor parameter list.

#### Step 6A.3: Update copyWith

Add `String? displayName` and `String? email` parameters.

#### Step 6A.4: Update fromJson

Add parsing for the RPC response fields:

```dart
  factory CompanyJoinRequest.fromJson(Map<String, dynamic> json) {
    return CompanyJoinRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String?,
      status: JoinRequestStatus.fromString(json['status'] as String? ?? 'pending'),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
    );
  }
```

**Verification:** `pwsh -Command "flutter analyze lib/features/auth/data/models/company_join_request.dart"`

### Phase 6B: AdminRepository — RPC + assert() Removal

**File:** `lib/features/settings/data/repositories/admin_repository.dart`

#### Step 6B.1: Replace getPendingJoinRequests with RPC call

Replace lines 22-38:

```dart
  /// Get all pending join requests with user profile data via RPC.
  ///
  /// WHY: RPC joins company_join_requests with user_profiles in one call,
  /// giving us display_name and email for the admin UI.
  /// FROM SPEC: Section 4
  Future<List<CompanyJoinRequest>> getPendingJoinRequests(
      String companyId) async {
    try {
      final response = await _supabase.rpc(
        'get_pending_requests_with_profiles',
        params: {'p_company_id': companyId},
      );

      return (response as List)
          .map((json) => CompanyJoinRequest.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    } catch (e) {
      debugPrint('[AdminRepository] getPendingJoinRequests error: $e');
      rethrow;
    }
  }
```

#### Step 6B.2: Replace all assert() with throw StateError()

Replace all 6 `assert()` calls (lines 45, 59, 91, 105, 117, 131) with runtime checks.

Pattern — replace each:
```dart
assert(companyId != null, 'Company ID required for admin operations');
```
with:
```dart
// WHY: assert() is stripped in release builds. Runtime check ensures
// admin operations always validate company context.
// FROM SPEC: Section 7 — "assert() → runtime checks" (MF-6)
if (companyId == null) {
  throw StateError('Company ID required for admin operations');
}
```

**Verification:** `pwsh -Command "flutter analyze lib/features/settings/data/repositories/admin_repository.dart"`

### Phase 6C: Admin Dashboard UI — Show Name + Email

**File:** `lib/features/settings/presentation/screens/admin_dashboard_screen.dart`

#### Step 6C.1: Update _buildRequestTile to show displayName + email

Replace the `_buildRequestTile` method (lines 159-188):

```dart
  Widget _buildRequestTile(
      BuildContext context, CompanyJoinRequest request) {
    // FROM SPEC: Section 4 — "UI shows displayName + email with initials avatar"
    final name = request.displayName ?? 'Unknown User';
    final emailText = request.email ?? '';
    final initials = _initials(name);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.statusWarning.withValues(alpha: 0.2),
        child: Text(
          initials,
          style: TextStyle(
            color: AppTheme.statusWarning,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(name),
      subtitle: Text(
        emailText.isNotEmpty
            ? '$emailText\nRequested ${_formatDate(request.createdAt)}'
            : 'Requested ${_formatDate(request.createdAt)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      isThreeLine: emailText.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ApproveButton(
            onApprove: (role) => _handleApprove(request.id, role),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.close, color: AppTheme.statusError),
            tooltip: 'Reject',
            onPressed: () => _handleReject(request.id),
          ),
        ],
      ),
    );
  }
```

**NOTE:** The `_initials` helper method already exists in the file (used by `_buildMemberTile` at line 197).

**Verification:** `pwsh -Command "flutter analyze lib/features/settings/presentation/screens/admin_dashboard_screen.dart"`

---

## Phase 7: SyncProvider UI State

### Phase 7A: Expose Circuit Breaker State

**File:** `lib/features/sync/presentation/providers/sync_provider.dart`

#### Step 7A.1: Add circuit breaker state tracking

Add fields and getters:

```dart
  bool _circuitBreakerTripped = false;

  /// Whether the circuit breaker has tripped (too many pending changes).
  /// FROM SPEC: Section 3L — "Show banner. User dismisses → resumes."
  bool get circuitBreakerTripped => _circuitBreakerTripped;

  /// Dismiss the circuit breaker and allow sync to resume.
  void dismissCircuitBreaker() {
    _circuitBreakerTripped = false;
    notifyListeners();
  }
```

#### Step 7A.2: Update sync completion handler to check circuit breaker

In the `onSyncComplete` callback, add circuit breaker detection:

```dart
    _syncOrchestrator.onSyncComplete = (result) {
      _lastSyncTime = DateTime.now();
      if (result.hasErrors) {
        _consecutiveFailures++;
        _lastError = result.errorMessages.isNotEmpty
            ? result.errorMessages.first
            : 'Sync completed with errors';
        // Check for circuit breaker message
        if (result.errorMessages.any((m) => m.contains('Circuit breaker'))) {
          _circuitBreakerTripped = true;
        }
        if (hasPersistentSyncFailure) {
          onSyncErrorToast?.call(_lastError!);
        }
      } else {
        _consecutiveFailures = 0;
        _lastError = null;
        _circuitBreakerTripped = false;
      }
      _refreshPendingCount();
      notifyListeners();
    };
```

**Verification:** `pwsh -Command "flutter analyze lib/features/sync/presentation/providers/sync_provider.dart"`

### Phase 7B: Circuit Breaker Banner in Sync Dashboard

**File:** `lib/features/sync/presentation/screens/sync_dashboard_screen.dart`
**Agent:** `frontend-flutter-specialist-agent`

#### Step 7B.1: Add dismissable circuit breaker banner

Add at the top of the body (before existing content) in the `build` method:

```dart
// WHY: H-5 fix — Spec 3L requires dismissable banner when circuit breaker trips.
// FROM SPEC: Section 3L — "Sync dashboard shows a dismissable banner"
final syncProvider = context.watch<SyncProvider>();

if (syncProvider.circuitBreakerTripped) ...[
  MaterialBanner(
    content: const Text(
      'Sync paused: unusually high number of pending changes',
    ),
    leading: const Icon(Icons.warning_amber, color: Colors.orange),
    actions: [
      TextButton(
        onPressed: () => syncProvider.dismissCircuitBreaker(),
        child: const Text('RESUME SYNC'),
      ),
    ],
  ),
],
```

**Verification:** `pwsh -Command "flutter analyze lib/features/sync/presentation/screens/sync_dashboard_screen.dart"`

---

## Phase 8: Tests

### Phase 8A: Soft-Delete Push Tests

**File:** `test/features/sync/engine/sync_engine_test.dart`

Add test cases:

```dart
group('Soft-delete push (BLOCKER-29)', () {
  test('sends UPDATE with deleted_at instead of DELETE', () async {
    // Setup: insert a record with deleted_at set
    // Act: trigger push for this record
    // Assert: Supabase received .update() not .delete()
  });

  test('skips push when record has no deleted_at', () async {
    // Setup: change_log says 'delete' but record is restored (deleted_at is null)
    // Act: trigger push
    // Assert: no Supabase call made
  });

  test('skips push when record not found locally', () async {
    // Setup: change_log entry for a record truly deleted from SQLite
    // Act: trigger push
    // Assert: no Supabase call, no error
  });
});
```

### Phase 8B: Upsert Pre-Check Tests

**File:** `test/features/sync/engine/sync_engine_test.dart`

```dart
group('Upsert pre-check (BLOCKER-24)', () {
  test('allows upsert when no conflict exists', () async {
    // Setup: no matching record on Supabase
    // Assert: upsert proceeds normally
  });

  test('allows upsert when same ID matches', () async {
    // Setup: Supabase returns same ID for natural key
    // Assert: upsert proceeds (it's an update)
  });

  test('rejects upsert when different ID occupies natural key', () async {
    // Setup: Supabase returns different ID for natural key
    // Assert: StateError thrown with descriptive message
  });

  test('23505 after clean pre-check is retryable', () async {
    // Setup: pre-check passes, upsert throws 23505
    // Assert: error handler returns true (retryable)
  });
});
```

### Phase 8C: Conflict Resolver Tests

**File:** `test/features/sync/engine/conflict_resolver_test.dart`

```dart
group('Null timestamp handling (Spec 3I)', () {
  test('both null → remote wins', () async {
    // Assert: ConflictWinner.remote
  });

  test('null remote + valid local → local wins', () async {
    // Assert: ConflictWinner.local
  });

  test('null local + valid remote → remote wins', () async {
    // Assert: ConflictWinner.remote
  });
});
```

### Phase 8D: Circuit Breaker Tests

**File:** `test/features/sync/engine/change_tracker_test.dart`

```dart
group('Circuit breaker (Spec 3L)', () {
  test('trips when count exceeds threshold', () async {
    // Setup: insert > 1000 change_log entries
    // Assert: isCircuitBreakerTripped() returns true
  });

  test('purgeOldFailures removes old failed entries', () async {
    // Setup: insert entries with retry_count >= 3 and old changed_at
    // Assert: purgeOldFailures() removes them
  });

  test('push returns error when tripped', () async {
    // Assert: SyncEngineResult has circuit breaker error message
  });
});
```

### Phase 8E: Mutex Heartbeat Tests

**File:** `test/features/sync/engine/sync_mutex_test.dart`

```dart
group('Heartbeat (Spec 3J)', () {
  test('heartbeat updates last_heartbeat column', () async {
    // Setup: acquire lock
    // Act: call heartbeat()
    // Assert: last_heartbeat is updated
  });

  test('stale heartbeat expires lock', () async {
    // Setup: acquire lock, set last_heartbeat to 3 min ago
    // Act: another process tries to acquire
    // Assert: succeeds (stale lock expired)
  });
});
```

### Phase 8F: Integrity Checker Tests

**File:** `test/features/sync/engine/integrity_checker_test.dart`

```dart
group('Max reset guard (Spec 3K)', () {
  test('stops resetting after N consecutive failures', () async {
    // Setup: trigger drift N+1 times
    // Assert: cursor NOT deleted on the (N+1)th run
  });

  test('resets counter when table passes', () async {
    // Setup: trigger drift 2 times, then pass
    // Assert: counter back to 0
  });
});

group('Cursor reset tolerance (Spec 3N)', () {
  test('skips reset when count diff below threshold', () async {
    // Setup: local=100, remote=102 (diff=2, threshold=10)
    // Assert: cursor NOT deleted
  });

  test('resets when count diff exceeds threshold', () async {
    // Setup: local=100, remote=120 (diff=20, threshold=10)
    // Assert: cursor deleted
  });
});
```

### Phase 8G: Admin Repository Tests

**File:** `test/features/settings/data/repositories/admin_repository_test.dart` (new if needed)

```dart
group('AdminRepository', () {
  test('getPendingJoinRequests calls RPC', () async {
    // Assert: _supabase.rpc('get_pending_requests_with_profiles') called
  });

  test('approveJoinRequest throws StateError when companyId is null', () async {
    // Setup: AdminRepository with companyId: null
    // Assert: throws StateError (not assertion error)
  });
});
```

**Verification:** `pwsh -Command "flutter test test/features/sync/"`

---

## Phase 9: Cleanup

### Phase 9A: Dead Code Removal

#### Step 9A.1: Remove any remaining hard-delete references

Search for `supabase.from(.*).delete()` patterns in sync engine code. The only legitimate hard delete should be in test cleanup. Any production hard-delete calls should have been replaced by Phase 3A.

#### Step 9A.2: Remove old orphan scan-only TODO comments

The OrphanScanner now supports auto-delete. Remove any "Does NOT auto-delete" comments or TODOs.

### Phase 9B: Final Verification

```
pwsh -Command "flutter test test/features/sync/"
pwsh -Command "flutter analyze lib/features/sync/"
pwsh -Command "flutter analyze lib/core/database/"
pwsh -Command "flutter analyze lib/features/settings/"
pwsh -Command "flutter analyze lib/features/auth/data/models/"
```

All must pass with zero errors before considering this plan complete.

---

## Summary of Files Modified

| File | Phase | Change |
|------|-------|--------|
| `supabase/migrations/20260313100000_sync_hardening_triggers.sql` | 1A | NEW — triggers, RLS, email backfill |
| `supabase/migrations/20260313100001_pending_requests_rpc.sql` | 1B | NEW — RPC function |
| `lib/features/sync/config/sync_config.dart` | 2A | Add 7 new constants, update staleLockTimeout |
| `lib/core/database/schema/sync_engine_tables.dart` | 2B | Add last_heartbeat to sync_lock |
| `lib/core/database/database_service.dart` | 2C | Version 33→34, migration for heartbeat + personnel_types |
| `lib/features/sync/engine/sync_engine.dart` | 3A-3E | Soft-delete push, pre-check, company validation, photo cleanup, error categorization |
| `lib/features/sync/adapters/table_adapter.dart` | 3B | Add naturalKeyColumns getter |
| `lib/features/sync/adapters/project_adapter.dart` | 3B | Override naturalKeyColumns |
| `lib/features/sync/adapters/entry_contractors_adapter.dart` | 3B | Override naturalKeyColumns |
| `lib/features/sync/adapters/personnel_type_adapter.dart` | 3B | Override naturalKeyColumns |
| `lib/features/sync/engine/conflict_resolver.dart` | 4C | Null timestamp handling |
| `lib/features/sync/engine/sync_mutex.dart` | 5A | Heartbeat support |
| `lib/features/sync/engine/integrity_checker.dart` | 5B, 5E | Max reset guard, cursor tolerance |
| `lib/features/sync/engine/change_tracker.dart` | 5C, 5D | Circuit breaker, per-record FK check |
| `lib/features/sync/engine/orphan_scanner.dart` | 5F | Auto-delete with age filter + cap |
| `lib/features/auth/data/models/company_join_request.dart` | 6A | Add displayName, email fields |
| `lib/features/settings/data/repositories/admin_repository.dart` | 6B | RPC call, assert→throw |
| `lib/features/settings/presentation/screens/admin_dashboard_screen.dart` | 6C | Show name + email |
| `lib/features/sync/presentation/providers/sync_provider.dart` | 7A | Circuit breaker state |
| `test/features/sync/engine/sync_engine_test.dart` | 8A, 8B | Soft-delete + pre-check tests |
| `test/features/sync/engine/conflict_resolver_test.dart` | 8C | Null timestamp tests |
| `test/features/sync/engine/change_tracker_test.dart` | 8D | Circuit breaker tests |
| `test/features/sync/engine/sync_mutex_test.dart` | 8E | Heartbeat tests |
| `test/features/sync/engine/integrity_checker_test.dart` | 8F | Max reset guard + tolerance tests |

## Dispatch Groups

For the `/implement` skill, phases should be dispatched in these groups:

| Group | Phases | Rationale |
|-------|--------|-----------|
| 1 | 1A, 1B | Supabase migrations — independent of app code |
| 2 | 2A, 2B, 2C | Foundation — config + schema |
| 3 | 3A, 3B, 3C, 3D, 3E | Push hardening — core blockers |
| 4 | 4A, 4B, 4C | Pull hardening |
| 5 | 5A, 5B, 5C, 5D, 5E, 5F | Infrastructure |
| 6 | 6A, 6B, 6C | Admin dashboard |
| 7 | 7A | SyncProvider state |
| 8 | 8A, 8B, 8C, 8D, 8E, 8F, 8G | Tests |
| 9 | 9A, 9B | Cleanup + final verification |

**Quality gate after each group:** `pwsh -Command "flutter test test/features/sync/"`
