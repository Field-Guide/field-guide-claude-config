# Sync Engine Refactor Spec

**Date**: 2026-04-04
**Status**: Approved
**Size**: L (Large)
**Security-sensitive**: Yes (sync integrity, data loss risk, RLS enforcement)

---

## 1. Overview

### Purpose

Refactor the sync engine from a monolithic God Object (2,374-line SyncEngine with 42 methods and 35+ responsibilities) into focused, independently testable classes with clean I/O boundaries — while preserving every existing capability and maintaining zero data loss.

### Motivation

- **Maintainability**: SyncEngine is a God Object mixing push, pull, file upload, EXIF stripping, auth refresh, error categorization, enrollment, FK rescue, debug logging, and cursor management in one class
- **Testability**: 9 `@visibleForTesting` hacks needed to test the monolith; 6 code paths are completely untestable (FK rescue, enrollment, orchestrator retry, dirty-scope pull, DNS check, pending buckets)
- **Performance**: Cannot optimize push/pull independently when they're interleaved in one class; architecture must support future concurrent push/pull

### Research Basis

Compared against PowerSync, Brick, ElectricSQL, synclayer, syncitron, and Flutter official recommendations. Key findings:

- Every surveyed package separates push and pull into independent subsystems
- PowerSync's `SyncStatus` (immutable value class with stream, separate upload/download errors) is the gold standard for status exposure
- PowerSync separates file/attachment sync into a dedicated state machine
- "Functional Core, Imperative Shell" — decision classes do no I/O, I/O classes make no decisions
- Your engine is more sophisticated than any surveyed package (FK ordering, multi-tenant scoping, trigger-based change log, circuit breaker). The refactor preserves all of this.

### Scope

**In scope:**
- Decompose SyncEngine into ~10 focused classes with clean I/O boundaries
- Consolidate triple status tracking into single immutable SyncStatus value class with stream
- Consolidate triplicated error classification into SyncErrorClassifier
- Fix layer violations (SQL in orchestrator, raw orchestrator exposure in provider, Postgres knowledge in provider)
- Reduce 13 boilerplate adapters to data-driven configuration
- Update all existing sync tests to target new class boundaries
- Write new tests for currently untestable code paths
- Write characterization tests before refactor begins
- Full 2-device sync verification flows via test driver infrastructure
- Update all sync-related documentation in `.claude/`

**Out of scope:**
- Changing sync behavior (LWW, trigger-based change log, scope filtering all stay)
- Schema changes (no database migration)
- Supabase backend changes (no new migrations or RLS changes)
- Adding new sync capabilities (concurrent push/pull is a future follow-up the architecture supports)
- Changing the application or presentation layers beyond fixing layer violations
- Rewriting ChangeTracker, ConflictResolver, IntegrityChecker, DirtyScopeTracker, OrphanScanner, StorageCleanup, or SyncMutex (already well-scoped)
- CRDT or alternative conflict strategies (LWW stays)

### Success Criteria

- [ ] Zero behavior change — every sync operation produces identical results before and after
- [ ] Every extracted class has dedicated unit tests with >90% branch coverage
- [ ] No `@visibleForTesting` methods remain on any class
- [ ] SyncEngine coordinator is under 250 lines
- [ ] No class exceeds 500 lines
- [ ] Error classification exists in exactly one place (SyncErrorClassifier)
- [ ] Sync status has exactly one source of truth (SyncStatus)
- [ ] All 6 currently untestable code paths have dedicated tests
- [ ] CI green: analyzer zero, all existing tests pass, all new tests pass
- [ ] Adapter file count reduced from 24 to ~12
- [ ] All sync documentation updated
- [ ] Full 2-device sync verification flows passing

---

## 2. Current Architecture (Problems)

### SyncEngine God Object (2,374 lines, 42 methods)

35+ responsibilities including:
- Push orchestration (FK ordering, per-record routing, skip/block decisions)
- Pull orchestration (scope filtering, cursor pagination, tombstone protection)
- All Supabase row I/O (upsert, delete, select, auth refresh)
- All sync-related SQLite I/O (record reads/writes, trigger suppression, cursors)
- Three-phase file upload + EXIF GPS stripping
- Error categorization (Postgres codes, network, auth, rate limit)
- LWW conflict detection during push
- Natural key (UNIQUE constraint) pre-check
- Company ID / User ID stamping
- Enrollment from assignments + reconciliation
- FK rescue (fetch missing parents mid-pull)
- Deletion notification creation
- Debug server HTTP POST
- Maintenance orchestration (integrity, orphans, pruning)
- Background sync factory method

### Triple Status Tracking

| State | SyncEngine | SyncOrchestrator | SyncProvider |
|-------|-----------|-----------------|-------------|
| Is syncing | `_insidePushOrPull` | `_isSyncing` | `_isSyncing` |
| Status enum | none | `_status` | `_status` |
| Last sync time | writes to sync_metadata | `_lastSyncTime` (from DB) | `_lastSyncTime` (from orchestrator OR DateTime.now()) |

Three divergent sources of truth for the same values.

### Triplicated Error Handling

Error classification exists in:
1. `SyncEngine._handlePushError()` — classifies Postgres errors, decides retry
2. `SyncOrchestrator._isTransientError()` — re-classifies for retry decisions
3. `SyncProvider._sanitizeSyncError()` — re-classifies for UI display

All three pattern-match on overlapping strings: `'42501'`, `'23505'`, `'23503'`, `'SocketException'`, `'auth'`.

### Layer Violations

- SyncOrchestrator contains direct SQL queries (pending buckets, integrity results)
- SyncProvider exposes raw orchestrator via `get orchestrator`
- SyncProvider contains Postgres error code knowledge (`_sanitizeSyncError`)
- SyncOrchestrator calls `AppConfigProvider.recordSyncSuccess()` (upward dependency)
- SyncOrchestrator calls `UserProfileSyncDatasource.pullCompanyMembers()` (unrelated concern)
- SyncEngine depends on `image` package for EXIF stripping

### Adapter Boilerplate

13 of 22 adapters are pure configuration with zero custom logic. They could be data-driven.

### Testability Gaps

- 9 `@visibleForTesting` seams on SyncEngine
- SyncOrchestrator retry loop untestable (can't inject fake SyncEngine)
- FK rescue, enrollment, dirty-scope pull, DNS check, pending buckets — all untestable private methods

---

## 3. Target Architecture (Decomposition)

### New Class Map — Engine Layer

| Class | File | Responsibility | Dependencies | Lines (~) |
|-------|------|---------------|--------------|-----------|
| `SyncEngine` | `engine/sync_engine.dart` | Slim coordinator: mutex, heartbeat, mode routing, delegates to handlers | PushHandler, PullHandler, SyncMutex, MaintenanceHandler | ~200 |
| `PushHandler` | `engine/push_handler.dart` | Push orchestration: reads changes, FK ordering, per-record routing, skip/block decisions | LocalSyncStore, SupabaseSync, ChangeTracker, SyncRegistry, SyncErrorClassifier | ~300 |
| `PullHandler` | `engine/pull_handler.dart` | Pull orchestration: iterates adapters, applies scope filters, manages cursors, tombstone protection, conflict delegation | LocalSyncStore, SupabaseSync, ConflictResolver, SyncRegistry, DirtyScopeTracker | ~350 |
| `SupabaseSync` | `engine/supabase_sync.dart` | All Supabase row I/O: upsert, delete, select, auth refresh, rate limit handling | SupabaseClient, SyncErrorClassifier | ~250 |
| `LocalSyncStore` | `engine/local_sync_store.dart` | All sync-related SQLite I/O: record reads/writes, cursor management, trigger suppression, column cache, server timestamp writeback | Database | ~300 |
| `FileSyncHandler` | `engine/file_sync_handler.dart` | Three-phase file upload, EXIF stripping, storage path validation | SupabaseSync (storage), LocalSyncStore, image package | ~200 |
| `SyncErrorClassifier` | `engine/sync_error_classifier.dart` | Single source of truth for error categorization (Postgres codes, network, auth, rate limit) | None (pure logic) | ~120 |
| `EnrollmentHandler` | `engine/enrollment_handler.dart` | synced_projects enrollment from assignments, reconciliation, orphan cleanup | LocalSyncStore | ~150 |
| `FkRescueHandler` | `engine/fk_rescue_handler.dart` | Fetches missing FK parents from Supabase during pull | SupabaseSync, LocalSyncStore | ~80 |
| `MaintenanceHandler` | `engine/maintenance_handler.dart` | Integrity check, orphan scan, conflict/change_log pruning, storage cleanup orchestration | IntegrityChecker, OrphanScanner, StorageCleanup, ChangeTracker | ~100 |

### Existing Engine Classes (Unchanged)

- `ChangeTracker` — already well-scoped
- `ConflictResolver` — already well-scoped
- `IntegrityChecker` — already well-scoped
- `DirtyScopeTracker` — already well-scoped
- `OrphanScanner` — already well-scoped
- `StorageCleanup` — already well-scoped
- `SyncMutex` — already well-scoped
- `SyncRegistry` — refactored from singleton to injectable instance
- `ScopeType` — unchanged
- `SyncControlService` — unchanged

### New Domain Types

| Class | File | Purpose |
|-------|------|---------|
| `SyncStatus` | `domain/sync_status.dart` | Immutable value class: separate `uploadError`/`downloadError`, `downloadProgress`, push/pull state. Stream with deduplication. Replaces mutable fields across 3 classes. |
| `SyncError` | `domain/sync_error.dart` | Classified error enum: `rlsDenial`, `fkViolation`, `uniqueViolation`, `rateLimited`, `authExpired`, `networkError`, `transient`, `permanent` |

### Adapter Simplification

**Current**: 22 adapter class files + base + type_converters = 24 files

**After**:
- `TableAdapter` base class — kept, slightly slimmed
- 9 adapter classes with genuine custom logic (file adapters, consent, support, inspector form, form response, daily entry, equipment, entry equipment, document)
- `AdapterConfig` — data class for simple adapter registration
- Data-driven registration for 13 simple adapters:

```dart
static final simpleAdapters = [
  AdapterConfig(table: 'contractors', scope: ScopeType.viaProject, fkDeps: ['projects']),
  AdapterConfig(table: 'locations', scope: ScopeType.viaProject, fkDeps: ['projects']),
  AdapterConfig(table: 'bid_items', scope: ScopeType.viaProject, fkDeps: ['projects']),
  // ... 10 more
];
```

**File count**: 24 → ~12 adapter files

### Application Layer Fixes

| Current Problem | Fix |
|----------------|-----|
| SyncOrchestrator contains SQL queries (pending buckets, integrity results) | Move to `LocalSyncStore` or new `SyncQueryService` datasource |
| SyncOrchestrator calls `AppConfigProvider.recordSyncSuccess()` | Replace with callback |
| SyncOrchestrator calls `UserProfileSyncDatasource.pullCompanyMembers()` | Extract to post-sync hook |

### Presentation Layer Fixes

| Current Problem | Fix |
|----------------|-----|
| SyncProvider exposes raw orchestrator (`get orchestrator`) | Remove. Expose specific methods/getters instead. |
| SyncProvider contains `_sanitizeSyncError()` with Postgres codes | Delete. Use SyncErrorClassifier output. |
| SyncProvider tracks status independently | Subscribe to SyncStatus stream. |

### Dependency Flow (After)

```
SyncProvider ──listens──> SyncStatus stream
     |
     | triggers
     v
SyncOrchestrator ──creates──> SyncEngine (slim coordinator)
                                   |
                          +--------+--------+
                          v        v        v
                    PushHandler PullHandler MaintenanceHandler
                          |        |
                    +-----+--------+-----+
                    v                    v
              SupabaseSync         LocalSyncStore
                    |                    |
                    v                    v
             SupabaseClient          Database
```

No class reaches more than 2 layers down. Every arrow is an injectable dependency.

---

## 4. Testing & Verification Strategy

Testing and verification is the most important aspect of this refactor. The strategy is a 6-layer verification pyramid where every layer must be green before proceeding.

### 4.1 Characterization Tests (Layer 1 — Written Before Any Code Changes)

Capture current behavior as immutable contracts. Named `characterization_*_test.dart`.

**Push characterization:**

| Test File | What It Captures |
|-----------|-----------------|
| `characterization_push_upsert_test.dart` | For each adapter: given change_log INSERT/UPDATE + local record -> exact Supabase upsert payload |
| `characterization_push_delete_test.dart` | Soft-delete: UPDATE with deleted_at. Hard-delete: DELETE. Idempotent cases. |
| `characterization_push_ordering_test.dart` | Changes across multiple tables push in FK dependency order |
| `characterization_push_skip_test.dart` | Builtin forms, adapter shouldSkipPush, FK-blocked records -> markProcessed without Supabase call |
| `characterization_push_file_test.dart` | For each file adapter: 3-phase sequence (storage upload, metadata upsert, local bookmark) |
| `characterization_push_lww_test.dart` | Server has newer updated_at -> push skipped, change_log marked processed |

**Pull characterization:**

| Test File | What It Captures |
|-----------|-----------------|
| `characterization_pull_scope_test.dart` | For each scope type + adapter -> exact Supabase query filter |
| `characterization_pull_upsert_test.dart` | Supabase rows -> exact SQLite upsert (column mapping, type conversion, stripping) |
| `characterization_pull_conflict_test.dart` | Local newer updated_at -> LWW local-wins, conflict_log entry |
| `characterization_pull_cursor_test.dart` | Paginated pull -> cursor advancement and rollback on error |
| `characterization_pull_tombstone_test.dart` | Pending local delete + same record in pull -> skip (no re-insert) |
| `characterization_pull_trigger_suppression_test.dart` | pulling='1' set before writes, '0' reset in finally, even on error |
| `characterization_pull_dirty_scope_test.dart` | Dirty scopes -> only dirty tables/projects pulled in quick mode |

**Error & mode characterization:**

| Test File | What It Captures |
|-----------|-----------------|
| `characterization_error_classification_test.dart` | Every known error pattern -> classification + change_log state |
| `characterization_sync_modes_test.dart` | quick/full/maintenance -> exact operation sequence per mode |

**Estimated: ~15 test files, ~120-150 test cases.** Written against current monolith. Run unchanged against refactored code.

### 4.2 Interface Contract Tests (Layer 2 — Written Before Implementation)

Written TDD-style before each class exists. Define public API and expected behavior.

| Contract Test File | Key Contracts |
|-------------------|---------------|
| `supabase_sync_contract_test.dart` | upsert calls, delete sends UPDATE with deleted_at, fetchPage applies filters+cursor+limit, refreshAuth on 401 |
| `local_sync_store_contract_test.dart` | readLocalRecord queries by id, upsertPulledRecord with trigger suppression in try/finally, writeBackServerTimestamp, cursor atomicity |
| `push_handler_contract_test.dart` | Given changes -> calls SupabaseSync in FK order, skips blocked records, uses FileSyncHandler for file adapters, accurate counts |
| `pull_handler_contract_test.dart` | Given pages -> calls LocalSyncStore.upsertPulledRecord, invokes ConflictResolver, calls EnrollmentHandler after assignments, respects dirty scopes |
| `file_sync_handler_contract_test.dart` | Three-phase sequence, EXIF strip when flagged, storage path validated, phase-2 failure cleans up phase-1 |
| `sync_error_classifier_contract_test.dart` | Exhaustive: every Postgres code, network pattern, auth pattern -> correct SyncError variant |
| `sync_status_contract_test.dart` | Immutability, stream deduplication, separate uploadError/downloadError, copyWith, equality |
| `enrollment_handler_contract_test.dart` | New assignments -> synced_projects inserts, already-enrolled -> no-op, orphan cleanup |
| `fk_rescue_handler_contract_test.dart` | Missing parent -> fetch + write + return true, not on server -> return false |
| `maintenance_handler_contract_test.dart` | Correct call order, respects integrityCheckInterval, logs to sync_metadata |

**Estimated: ~10 test files, ~80-100 test cases.** All start red.

### 4.3 Equivalence Testing (Layer 3 — During Refactor)

Process, not separate test files:

1. Extract class N from SyncEngine
2. Wire into coordinator
3. Run all characterization tests (Layer 1) -> must be 100% green
4. Run all existing sync tests via CI -> must be 100% green
5. If red -> revert extraction, investigate, retry
6. Commit only when green

Each extraction step is a separate commit. If any step breaks equivalence, `git diff` shows which extraction caused it.

### 4.4 Isolation Tests (Layer 4 — Post-Extraction)

Per-class focused tests that go deeper than characterization:

| Test File | Focus Areas |
|-----------|------------|
| `push_handler_test.dart` | FK blocking with 3-level chains, adapter skip + FK block on same record, circuit breaker entry/exit, empty change_log fast path, batch limit |
| `pull_handler_test.dart` | Pagination across 3+ pages, cursor rollback on mid-page error, dirty scope company-wide degradation, tombstone timing edge case, null project_id builtins |
| `supabase_sync_test.dart` | 401->refresh->retry, 429->backoff->retry, 23505 idempotent, empty delete response, connection vs response timeout |
| `local_sync_store_test.dart` | Trigger suppression survives exception, column cache invalidation, unknown column stripping, cursor read-after-write |
| `file_sync_handler_test.dart` | EXIF strip on corrupt image, storage 409, upload timeout, phase-1 success + phase-2 failure cleanup, zero-byte file |
| `sync_error_classifier_test.dart` | Every Supabase error code, compound errors, unknown codes -> permanent default |
| `sync_status_test.dart` | Rapid state transitions, concurrent updates, stream deduplication |
| `enrollment_handler_test.dart` | Multiple new assignments, already-enrolled no-op, orphan with pending changes |
| `fk_rescue_handler_test.dart` | Rescue during trigger suppression, different company rejection, recursive rescue |
| `maintenance_handler_test.dart` | Interval skip, zero orphans, zero expired entries |

**Estimated: ~10 test files, ~100-120 test cases.** All use mocked I/O.

### 4.5 Integration Verification (Layer 5 — Pre-Merge)

Full 2-device sync flows via the test driver infrastructure:

| Flow | What It Verifies |
|------|-----------------|
| **Create-Sync-Verify** | Device A: create project + entry + photos + forms + quantities. Sync. Device B: sync. Verify every field matches exactly, including timestamps, GPS data, file presence. |
| **Edit-Conflict-Resolve** | Device A: edit entry field X. Device B: edit same entry field Y (no conflict) and field X (LWW conflict). Both sync. Verify winner correct, conflict_log exists, loser data preserved. |
| **Delete-Sync-Verify** | Device A: soft-delete entry. Sync. Device B: sync. Verify deleted, deletion notification created. |
| **File-Sync-Roundtrip** | Device A: attach photo with GPS EXIF. Sync. Verify storage path, EXIF stripped in cloud, bookmark updated. Device B: sync. Verify photo downloads. |
| **Quick-Sync-Dirty-Scope** | Trigger realtime hint for specific project+table. Quick sync. Verify only dirty scope pulled. |
| **Enrollment-Flow** | Admin assigns user to new project via Supabase. User syncs. Verify auto-enrolled, data begins pulling. |
| **Circuit-Breaker-Recovery** | Create ping-pong conflict. Verify circuit breaker trips. Dismiss. Verify sync resumes. |

These update existing `.claude/test-flows/sync/` flow definitions.

### 4.6 CI Strategy

- **During development**: Run only targeted test file for the class being worked on
- **On PR**: CI runs full suite (analyzer + all tests)
- **Never**: Run `flutter test` with all tests locally

### 4.7 Ongoing Testability Guarantees

Architectural rules enforced permanently:

- No class in `engine/` may depend on `SupabaseClient` or `Database` directly — only through `SupabaseSync` and `LocalSyncStore`
- No `@visibleForTesting` methods — use interfaces or constructor injection
- Every new sync class must have a corresponding `_test.dart` file before merge
- SyncStatus is the only source of truth for sync state
- SyncErrorClassifier is the only error classifier — no Postgres code matching elsewhere

---

## 5. Migration & Sequencing

### Phase Order

Each phase is a separate PR. No phase starts until the previous phase's PR is merged.

| Phase | What | Depends On |
|-------|------|-----------|
| **P0** | Write characterization tests against current monolith | Nothing |
| **P1** | Extract `SyncErrorClassifier` + `SyncStatus` + `SyncError` (domain types) | P0 |
| **P2** | Extract `LocalSyncStore` + `SupabaseSync` (I/O boundaries) | P1 |
| **P3** | Extract `PushHandler` + `FileSyncHandler` | P2 |
| **P4** | Extract `PullHandler` + `EnrollmentHandler` + `FkRescueHandler` | P2 |
| **P5** | Extract `MaintenanceHandler` + slim down `SyncEngine` coordinator | P3, P4 |
| **P6** | Fix layer violations (orchestrator SQL, provider exposure, status consolidation) | P5 |
| **P7** | Adapter simplification (data-driven config for 13 simple adapters) | P5 |
| **P8** | Integration verification (L5 2-device flows) + documentation updates | P6, P7 |

### Why This Order

- **P0 first**: Characterization tests are the safety net. Everything after depends on them.
- **P1 (domain types)**: No behavior change — just extracting types. Low risk, unblocks all subsequent phases.
- **P2 (I/O boundaries)**: Most important extraction. Once LocalSyncStore and SupabaseSync exist, every subsequent handler can be tested against mocks.
- **P3 and P4 can be parallelized** if working in separate branches.
- **P6 after P5**: Layer violations easier to fix once engine is decomposed.
- **P7 (adapters)**: Independent of engine decomposition, sequenced to avoid merge conflicts.
- **P8 last**: Integration verification validates the complete system.

### Per-Phase Verification Gate

Every phase must pass:
- All characterization tests green
- All existing sync tests green (via CI on PR)
- All new contract + isolation tests for that phase green
- `flutter analyze` zero violations

---

## 6. Documentation Updates

| File | Changes |
|------|---------|
| `.claude/rules/sync/sync-patterns.md` | Full rewrite: new layer diagram, class relationships, file organization, data flow, engine components table |
| `.claude/CLAUDE.md` | Update sync architecture section, key files table, gotchas |
| `.claude/test-flows/sync/framework.md` | Update to reference new class boundaries and test approach |
| `.claude/test-flows/sync/*.md` | Update individual flow files for 2-device verification |
| `.claude/docs/directory-reference.md` | Update sync directory listing |

---

## 7. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Characterization tests miss a behavior | Medium | High | Write for every code path in the 42-method inventory |
| Extraction changes trigger suppression timing | Medium | Critical | LocalSyncStore owns all trigger suppression. Dedicated characterization test. |
| SyncRegistry singleton migration breaks adapter order | Low | High | Inject registry. Characterization test verifies FK order preserved. |
| Adapter config-driven registration loses subtle override | Low | Medium | Diff each adapter against AdapterConfig fields. Any with logic stays as class. |
| 2-device flows reveal integration issue | Medium | Medium | This is why L5 exists. Fix before merge. |
| Long-lived branch with merge conflicts | Medium | Medium | Each phase is a separate PR. Merge frequently. |

---

## 8. Success Metrics

| Metric | Before | After |
|--------|--------|-------|
| SyncEngine lines | 2,374 | <250 (coordinator) |
| Largest sync class | 2,374 lines | <500 lines |
| `@visibleForTesting` methods | 9 | 0 |
| Adapter files | 24 | ~12 |
| Status sources of truth | 3 | 1 (SyncStatus) |
| Error classifier locations | 3 | 1 (SyncErrorClassifier) |
| Untestable code paths | 6 | 0 |
| Test files (sync) | 77 | ~105 |
| Test cases (sync) | 683 | ~1,000+ |

---

## Decisions Log

| Decision | Chosen | Rejected | Rationale |
|----------|--------|----------|-----------|
| Refactor approach | Architectural (C) — rethink layer boundaries | Surgical (A) or Moderate (B) | User wants proper modularity and testability, not band-aids |
| Decomposition direction | Engine-first (Option A) | Consolidation-first or Vertical slices | Attacks biggest pain point first; status/error consolidation is easier after |
| I/O separation | Separate SupabaseSync + LocalSyncStore | Keep I/O mixed in handlers | Maximum testability — mock either I/O boundary independently |
| Granularity | Fine-grained (10 classes) with EnrollmentHandler + FkRescueHandler extracted | Coarser (5 classes) keeping enrollment/rescue in PullHandler | User requested maximum granularity; each concern independently testable |
| Adapter reduction | Data-driven config for simple adapters | Keep all 22 class files | 13 adapters are pure boilerplate; config is less code to maintain |
| New patterns | None — reduce complexity, don't add it | Command pattern, event sourcing | User explicitly rejected adding depth; goal is flatter, not deeper |
| Testing strategy | 6-layer verification pyramid with characterization-first | Test-after or test-alongside | Testing is the top priority; characterization tests are the safety net |
| Test execution | CI on PR only; targeted local runs | Full `flutter test` locally or per-commit CI | Full suite is too slow locally; CI on PR is sufficient |
| L5 integration | Full 2-device flows via test driver | Manual smoke testing | Must match existing test skill rigor |
