# Data, Database & Sync Audit Remediation Spec

**Date**: 2026-04-02
**Source Audit**: `.claude/code-reviews/2026-03-30-preprod-audit-layer-data-database-sync-codex-review.md`
**Approach**: Single PR, phased execution (6 phases)
**Branch**: New branch off main

## Overview

Remediate 10 remaining findings from the 2026-03-30 data/database/sync pre-prod audit, resolve BLOCKER-38, and close coverage gaps. Single PR, phased execution.

The data layer passed its 4 High-severity audit items (findings 1, 2, 6, 8 — all FIXED by PR #7). What remains is 8 Medium-severity findings (2 partially fixed, 6 still present), BLOCKER-38 (stale destructive method + missing unsynced-change warning), and test coverage gaps.

### Success Criteria

- Zero direct datasource imports in presentation layer
- Zero dead code files in shared datasources
- Zero stale test files for removed schema surfaces
- SyncOrchestrator fully constructed via Builder (no post-construction setters)
- SchemaVerifier reports drift but does not repair
- `clearLocalCompanyData` and `SwitchCompanyUseCase` deleted
- Sign-out prompts user when unsynced changes exist
- `form_type` column has no DEFAULT — all inserts explicit
- New tests for `base_remote_datasource`, `user_profile_sync_datasource`
- `SyncOrchestrator.forTesting` moved to test utility
- A6 baseline violations reduced in sync DI files (target: 6→0 in sync_initializer, 2→0 in sync_providers)
- All existing tests pass (3771+), zero analyzer issues

### Findings Map

| Finding | Severity | Status Pre-Fix | Phase |
|---------|----------|----------------|-------|
| F3: `mdot_0582b` schema DEFAULT | High | Partially fixed | 2 |
| F4: UserProfileSyncDatasource raw cert inserts | Medium | Still present | 3 |
| F5: Background sync duplicates bootstrap | Medium | Still present | 4 |
| F7: Sync reconciliation — cert path raw SQL | Medium | Partially fixed | 3 |
| F9: SyncOrchestrator post-construction setters | Medium | Still present | 4 |
| F10: `updateLastSyncedAt` ignores userId | Medium | Still present | 1 |
| F11: Dual-path schema repair | Medium | Still present | 2 |
| F12: Dead `query_mixins.dart` | Medium | Still present | 1 |
| F13: Legacy `sync_queue` migration test | Medium | Still present | 1 |
| F14: Presentation imports datasource types | Medium | Still present | 3 |
| BLOCKER-38: Destructive method + no unsync warning | High | Stale defect | 1, 5 |

---

## Phase 1: Dead Code & Quick Fixes

### F10 — Remove unused `userId` param

- `UserProfileSyncDatasource.updateLastSyncedAt(String userId)` → `updateLastSyncedAt()`
- Update caller in `SyncOrchestrator` (~line 291) to stop passing `userId`
- RPC uses server-side `auth.uid()` — param was always misleading

### F12 — Delete dead `query_mixins.dart`

- Delete `lib/shared/datasources/query_mixins.dart`
- Remove re-export from `lib/shared/datasources/datasources.dart` line 6

### F13 — Delete stale sync_queue migration test

- Delete `test/features/sync/schema/sync_queue_migration_test.dart`
- Table was dropped in migration v31, test manually recreates it to test a completed migration path

### BLOCKER-38 — Remove destructive method + dead use case

- Delete `AuthService.clearLocalCompanyData()` (lines 312-360) — hard-deletes 28 tables, no remaining valid use case
- Delete `SwitchCompanyUseCase` class entirely (`lib/features/auth/domain/usecases/switch_company_use_case.dart`)
- Remove from `SignInUseCase`: import, field, constructor param, and call site (~lines 5, 42, 46, 71-73)
- Remove from `AuthInitializer`: import, construction, and injection (~line 18, 61)

**Validation**: Run full test suite to confirm no breakage.

---

## Phase 2: Schema & Migration Cleanup

### F3 — Remove `mdot_0582b` DEFAULT from schema

- New migration (next version number): table rebuild to remove DEFAULT
  - `ALTER TABLE form_responses RENAME TO form_responses_old`
  - `CREATE TABLE form_responses(...form_type TEXT NOT NULL...)` — no DEFAULT
  - Backfill: existing rows with null/empty `form_type` get set to `kFormTypeMdot0582b` before rebuild
  - `INSERT INTO form_responses SELECT ... FROM form_responses_old`
  - `DROP TABLE form_responses_old`
- Update `SchemaVerifier.expectedSchema` entry for `form_responses.form_type` from `TEXT NOT NULL DEFAULT '$kFormTypeMdot0582b'` to `TEXT NOT NULL`
- Audit all `INSERT INTO form_responses` call sites to confirm they already provide explicit `form_type` — any that don't must be updated

### F11 — SchemaVerifier becomes report-only

- Remove `ALTER TABLE ... ADD COLUMN` logic from `SchemaVerifier.verify()` (lines ~440-456)
- `verify()` returns `SchemaReport` containing: missing tables, missing columns, column drift — all as diagnostic data
- Callers (`database_service.dart` lines 73, 93) log the report. Missing columns or drift log as warnings, not silent fixes
- The 81 `_addColumnIfNotExists` calls in migrations remain — they ARE the authority
- `SchemaVerifier` keeps its `expectedSchema` and `_columnTypes` maps as the reference for what "correct" looks like

**Impact**: If a migration is ever skipped, the app will log clear warnings at startup instead of silently patching.

---

## Phase 3: Boundary Fixes

### F4/F7 — Create `UserCertificationLocalDatasource`

- New file: `lib/features/auth/data/datasources/local/user_certification_local_datasource.dart`
- Extends `BaseLocalDatasource` pattern already used by other auth datasources
- Methods: `upsertCertifications(List<Map<String, dynamic>> rows)`, `getCertificationsForUser(String userId)`, `deleteCertificationsForUser(String userId)`
- `UserProfileSyncDatasource.pullUserCertifications()` refactored to delegate to this new datasource instead of raw `db.insert`
- Datasource injected via `AuthInitializer`, same as existing auth datasources

### F14 — Create `EntryContractorsRepository`

- New file: `lib/features/entries/data/repositories/entry_contractors_repository.dart`
- Wraps `EntryContractorsLocalDatasource`, `EntryPersonnelCountsLocalDatasource`, `EntryEquipmentLocalDatasource` behind a domain API
- Methods mirror what presentation currently calls directly: `addContractor`, `removeContractor`, `getContractorsForEntry`, `getPersonnelCounts`, `getEquipment`, etc.
- Update 4 presentation files to use repository instead of datasource types:
  - `contractor_editing_controller.dart` — constructor takes repository
  - `entry_contractors_section.dart` — widget takes repository
  - `pdf_data_builder.dart` — method takes repository
  - `home_screen.dart` — `context.read<EntryContractorsRepository>()`
- Register in entries DI/provider setup

---

## Phase 4: Structural

### F5 — Extract `SyncEngineFactory`

- New file: `lib/features/sync/application/sync_engine_factory.dart`
- Single method: `SyncEngine create({required DatabaseService db, required SupabaseClient client})` — registers adapters, configures engine, returns ready-to-use instance
- `SyncOrchestrator` uses factory for foreground sync
- `BackgroundSyncHandler` desktop timer path uses factory instead of duplicating engine setup
- Mobile isolate path uses factory after its own local bootstrap (still bootstraps DB/Supabase independently — platform constraint)

### F9 — SyncOrchestrator Builder Pattern

New file: `lib/features/sync/application/sync_orchestrator_builder.dart`

```
SyncOrchestratorBuilder
  .required: DatabaseService, SyncEngineFactory
  .required: UserProfileSyncDatasource
  .required: SyncContextProvider (Function)
  .required: AppConfigProvider
  .optional: SupabaseClient? (null for offline-only)
  .optional: String? companyId, String? userId
  .build() → SyncOrchestrator (throws if required fields missing)
```

**Changes to `SyncOrchestrator`:**
- Constructor becomes `SyncOrchestrator._internal(...)` with all deps as required (non-nullable where possible)
- Remove all 4 setter methods (`setUserProfileSyncDatasource`, `setSyncContextProvider`, `setAppConfigProvider`, `setAdapterCompanyContext`)
- Remove nullable late-bound fields — replaced with final fields set at construction

**Changes to `SyncInitializer.create()`:**
- Replace multi-step setter calls with builder chain
- Builder resolves the circular dep by accepting the auth context provider as a function/callback rather than a concrete dependency — same runtime behavior, but the orchestrator is fully configured at construction time
- Move async initialization logic out of `SyncInitializer.create()` and into the builder or orchestrator internals, reducing A6 (`no_business_logic_in_di`) baseline violations in `sync_initializer.dart` (currently 6 violations)

### A6 Baseline Reduction
- Goal: eliminate or minimize `await`/`try` usage in `/di/` files touched by this PR
- `sync_initializer.dart` (6 violations): Builder pattern naturally moves async wiring out of DI
- `sync_providers.dart` (2 violations): Review whether remaining awaits can move to application layer
- Update `lint_baseline.json` to reflect reduced violation counts

---

## Phase 5: Sign-Out Warning (BLOCKER-38)

### Unsynced change check

Before executing sign-out, `SignOutUseCase` checks `change_log` for pending entries:

- Query: `SELECT COUNT(*) FROM change_log WHERE synced = 0`
- If count == 0: proceed with sign-out as normal
- If count > 0: return an `UnsyncedChangesResult` to the caller with the count

### UI change in `SignOutDialog`

- When unsynced count > 0, show a modified dialog: "You have X unsynced changes. Sync now before signing out?"
- Three actions:
  - **Sync & Sign Out** — triggers a sync push, waits for completion, then signs out
  - **Sign Out Anyway** — proceeds without syncing (data stays local, syncs on next sign-in)
  - **Cancel** — dismisses dialog
- When unsynced count == 0: current dialog behavior unchanged

**Why "Sign Out Anyway" is safe:** BUG-17 fix ensures local data persists across sign-out. The changes will sync when the user signs back in. The warning is about visibility, not prevention.

### Defect update

- Update `_defects-auth.md` BLOCKER-38 entry: mark original data-wipe issue as resolved, reclassify as narrower "unsynced warning added" closure note

---

## Phase 6: Tests & Cleanup

### New test files

1. **`test/shared/datasources/base_remote_datasource_test.dart`**
   - Verifies constructor injection of `SupabaseClient`
   - Verifies subclasses receive the injected client (not a singleton)

2. **`test/features/auth/data/datasources/remote/user_profile_sync_datasource_test.dart`**
   - Tests `pullCompanyMembers` delegates to local datasource
   - Tests `pullUserCertifications` delegates to new `UserCertificationLocalDatasource`
   - Tests `updateLastSyncedAt` calls RPC with no params (userId removed)

3. **`test/features/sync/application/sync_orchestrator_builder_test.dart`**
   - Tests `build()` succeeds with all required fields
   - Tests `build()` throws when required fields missing
   - Tests optional fields default correctly

4. **`test/features/sync/application/sync_engine_factory_test.dart`**
   - Tests factory creates configured engine
   - Tests adapters are registered

5. **`test/features/auth/data/datasources/local/user_certification_local_datasource_test.dart`**
   - Tests upsert, get, delete operations against in-memory SQLite

6. **`test/core/database/schema_verifier_report_test.dart`**
   - Tests verifier detects missing columns but does NOT repair them
   - Tests verifier detects drift and returns `SchemaReport`
   - Extends existing `schema_verifier_drift_test.dart`

### Moved to test utility

- `SyncOrchestrator.forTesting` → `test/helpers/sync_orchestrator_test_helper.dart`
- Update all existing test consumers (2 files) to import from new location

### Validation

- All 3771+ existing tests pass
- Zero analyzer issues
- Zero new lint violations
- 4 pre-existing `form_sub_screens_test.dart` failures remain (out of scope)

---

## Decisions Log

| Decision | Rationale | Alternatives Rejected |
|----------|-----------|----------------------|
| Remove `form_type` DEFAULT entirely (Option A) | Forces explicit form type on every insert — adding new form types is just a new constant | Neutral sentinel, keep as-is |
| Builder pattern for SyncOrchestrator (Option A) | Eliminates partial states at compile time, cleanest architecturally | Two-phase factory, runtime guard |
| Migrations authoritative, SchemaVerifier report-only (Option A) | Production needs to KNOW about problems, not silently patch them | Verifier-authoritative |
| Extract SyncEngineFactory (Option A) | Shared factory, platform-specific bootstrap stays isolated | Desktop delegates to orchestrator |
| New EntryContractorsRepository (Option A) | Personnel counts and equipment are always contractor-scoped — single domain boundary | Extend existing repo, use cases |
| Single PR phased execution (Option A) | Changes are interdependent, proven pattern from PR #7 | 2 or 3 separate PRs |
| Delete clearLocalCompanyData entirely | Users never switch companies needing same data — method has no valid use case | Add guards, keep for edge cases |
| Reduce A6 baseline in Phase 4 | Builder pattern naturally moves async wiring out of /di/ files — take the win | Leave as baselined debt |
