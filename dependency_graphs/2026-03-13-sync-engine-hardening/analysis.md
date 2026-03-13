# Sync Engine Hardening — Dependency Graph & Blast Radius

**Date**: 2026-03-13
**Spec**: `.claude/specs/2026-03-13-sync-engine-hardening-spec.md`

## Direct Changes

### Push Flow (Sections 3A-3E)

| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/features/sync/engine/sync_engine.dart` | `_pushDelete` | 327-339 | REWRITE: hard delete → detect soft-delete UPDATE |
| `lib/features/sync/engine/sync_engine.dart` | `_push` | 243-325 | MODIFY: add soft-delete detection, company_id validation, pre-check routing |
| `lib/features/sync/engine/sync_engine.dart` | `_pushUpsert` | 341-400 | MODIFY: add pre-check before upsert for UNIQUE-constrained tables |
| `lib/features/sync/engine/sync_engine.dart` | `_pushPhotoThreePhase` | 407-480 | MODIFY: add cleanup on Phase 2 failure, soft-delete detection for photo records |
| `lib/features/sync/engine/sync_engine.dart` | `_handlePushError` | 529-588 | REWRITE: add error categorization (23505, 42501, 23503, auth, rate-limit, network) |
| `lib/features/sync/engine/sync_engine.dart` | `pushAndPull` | 151-213 | MODIFY: add orphan auto-cleanup call |

### Pull Flow (Sections 3F-3I)

| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/features/sync/engine/sync_engine.dart` | `_pullTable` | 675-810 | MODIFY: handle soft-deleted records on pull, conflict snapshot |
| `lib/features/sync/engine/conflict_resolver.dart` | `resolve` | 24-67 | MODIFY: null timestamp handling (Spec 3I) |

### Infrastructure (Sections 3J-3O)

| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/features/sync/engine/sync_mutex.dart` | `SyncMutex` | 10-55 | MODIFY: add heartbeat, increase stale timeout to 15min |
| `lib/features/sync/engine/integrity_checker.dart` | `IntegrityChecker.run` | 66-112 | MODIFY: add max reset guard (3 consecutive resets) |
| `lib/features/sync/engine/change_tracker.dart` | `ChangeTracker` | 43-142 | MODIFY: add circuit breaker (1000 threshold), auto-purge old failures |
| `lib/features/sync/engine/orphan_scanner.dart` | `OrphanScanner` | 12-71 | MODIFY: add autoDelete flag, 24h age filter, 50-cap |
| `lib/features/sync/config/sync_config.dart` | `SyncEngineConfig` | 5-49 | MODIFY: add circuit breaker threshold, stale timeout→15min, cursor reset tolerance |
| `lib/core/database/schema/sync_engine_tables.dart` | `SyncEngineTables` | 5-151 | MODIFY: add last_heartbeat to sync_lock schema |
| `lib/core/database/database_service.dart` | `_onUpgrade` | 247-1520 | MODIFY: add migration for sync_lock.last_heartbeat, personnel_types UNIQUE verification |

### Admin Dashboard (Section 4)

| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/features/auth/data/models/company_join_request.dart` | `CompanyJoinRequest` | 9-144 | MODIFY: add displayName, email fields + fromJson parsing |
| `lib/features/settings/data/repositories/admin_repository.dart` | `AdminRepository` | 12-141 | MODIFY: use RPC, replace assert() with runtime checks |
| `lib/features/settings/presentation/screens/admin_dashboard_screen.dart` | `_buildRequestTile` | 159-188 | MODIFY: show displayName + email |
| `lib/features/settings/presentation/providers/admin_provider.dart` | `loadPendingRequests` | 51-65 | NO CHANGE (provider delegates to repository) |

### Supabase Migrations (NEW files)

| File | Change Type |
|------|-------------|
| `supabase/migrations/20260313100000_sync_engine_hardening.sql` | CREATE: stamp_deleted_by trigger, RLS tightening, email backfill |
| `supabase/migrations/20260313100001_get_pending_requests_with_profiles.sql` | CREATE: new RPC |

### Sync Provider (UI state)

| File | Symbol | Lines | Change Type |
|------|--------|-------|-------------|
| `lib/features/sync/presentation/providers/sync_provider.dart` | `SyncProvider` | 17-180 | MODIFY: expose circuit breaker state, integrity reset diagnostics |

## Dependent Files (Callers / Consumers — 2+ levels)

| File | Dependency | Impact |
|------|-----------|--------|
| `lib/features/sync/application/sync_orchestrator.dart` | Calls `SyncEngine.pushAndPull()` | LOW: no API change |
| `lib/features/sync/presentation/providers/sync_provider.dart` | Reads SyncOrchestrator status | MEDIUM: new circuit breaker state |
| `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` | Reads SyncProvider | MEDIUM: display circuit breaker banner + integrity diagnostics |
| `lib/services/soft_delete_service.dart` | Uses change_log triggers | LOW: triggers still fire normally |
| `lib/features/sync/engine/storage_cleanup.dart` | Called from pushAndPull | LOW: no API change |
| `lib/features/settings/presentation/providers/admin_provider.dart` | Calls AdminRepository | LOW: return type gains new fields (nullable, backward compatible) |

## Test Files

### Existing Tests to Update

| File | Reason |
|------|--------|
| `test/features/sync/engine/sync_engine_test.dart` | Push/pull behavior changes |
| `test/features/sync/engine/change_tracker_test.dart` | Circuit breaker, auto-purge |
| `test/features/sync/engine/sync_mutex_test.dart` | Heartbeat, 15-min timeout |
| `test/features/sync/engine/conflict_resolver_test.dart` | Null timestamp handling |
| `test/features/sync/engine/integrity_checker_test.dart` | Max reset guard |
| `test/features/sync/engine/orphan_scanner_test.dart` | Auto-delete, age filter, cap |
| `test/features/sync/engine/storage_cleanup_test.dart` | Photo cleanup on partial failure |

### New Tests to Create

| File | Scope |
|------|-------|
| `test/features/sync/engine/soft_delete_push_test.dart` | Soft-delete detection, push as UPDATE |
| `test/features/sync/engine/pre_check_test.dart` | Upsert pre-check (same ID, different ID, no match, TOCTOU) |
| `test/features/sync/engine/error_categorization_test.dart` | PostgrestException code parsing |
| `test/features/sync/engine/company_id_validation_test.dart` | Company ID mismatch rejection |
| `test/features/sync/engine/circuit_breaker_test.dart` | Threshold, pause, dismiss, auto-purge |
| `test/features/sync/engine/cursor_reset_tolerance_test.dart` | Below/above threshold behavior |
| `test/features/settings/data/repositories/admin_repository_test.dart` | RPC call, assert→runtime check |

## Dead Code to Clean Up

| Item | Location | Action |
|------|----------|--------|
| Hard delete in `_pushDelete` | sync_engine.dart:329 | Replace with soft-delete detection |
| Generic "Permanent: $message" | sync_engine.dart:569-572 | Replace with categorized error handler |
| Log-only orphan scanner | orphan_scanner.dart:22 | Add auto-delete capability |
| `assert(companyId != null)` × 6 | admin_repository.dart:46,60,92,106,119,132 | Replace with `if (companyId == null) throw StateError(...)` |

## Data Flow (Soft-Delete)

```
User taps Delete
  → App sets deleted_at on SQLite row (UPDATE, not DELETE)
  → SQLite UPDATE trigger fires → change_log (operation='update')
  → Push: detect deleted_at NULL→non-NULL → send .update({deleted_at, deleted_by})
  → Supabase stamp_deleted_by() trigger → force deleted_by = auth.uid()
  → Pull: remote has deleted_at → set locally with trigger suppression
  → All local queries: WHERE deleted_at IS NULL
```

## Blast Radius Summary

| Category | Count |
|----------|-------|
| Direct files modified | 14 |
| New files created | 2 (Supabase migrations) |
| Dependent files | 6 |
| Existing test files to update | 7 |
| New test files | 7 |
| Dead code items | 4 |
| **Total files affected** | **~36** |
