# Session State

**Last Updated**: 2026-03-26 | **Session**: 647

## Current Phase
- **Phase**: Sync Verification — S01 partial, blocked by 5 bugs
- **Status**: Ran `/test sync` S01 partial. Found 5 bugs (2 dropdown, 1 assignment save, 1 RLS permissions, 1 guide/UX). Stopped for the night.

## HOT CONTEXT - Resume Here

### What Was Done This Session (647)

1. **Launched dual-device environment** — S21+ (Android, port 4948 admin) + Windows (port 4949 inspector). Manual launch since `wait-for-driver.ps1` was missing.
2. **Pre-run cleanup** — No leftover VRF- data in Supabase. Clean slate confirmed.
3. **S01 partial execution** — Created project VRF-Oakridge mhaz3 (ID ec9f002f), 2 locations, 2 contractors, 2 equipment, 1 pay item. All synced to Supabase (pushed=7).
4. **5 BUGS FOUND:**
   - **BUG-1**: Contractor type dropdown saves wrong value (Sub → Prime)
   - **BUG-2**: Pay item unit dropdown saves wrong value (TON → CY)
   - **BUG-3**: Project assignment toggle not persisted to local SQLite — record never created, so triggers (v40) are irrelevant
   - **BUG-4**: Inspector pulls unassigned project via company-level pull — RLS/permissions bypass (SECURITY)
   - **BUG-5**: Personnel types cannot be added in project setup — only in entry wizard. Guide needs update. Project edit contractor cards should be redesigned to match entry wizard contractor cards.

### Key Decisions Made

1. **Personnel types are entry-wizard-only** — not in project setup or Settings. Guide step 8 is wrong.
2. **Project edit contractor cards need redesign** — should match entry wizard contractor cards (user request).

### What Needs to Happen Next

1. **Fix BUG-1 & BUG-2** (dropdown selection bugs) — likely driver tap on DropdownMenuItem not working, or dropdown value binding issue
2. **Fix BUG-3** (assignment save) — project edit Assignments tab toggle doesn't persist to SQLite
3. **Investigate BUG-4** (RLS permissions) — inspector should NOT pull projects they aren't assigned to
4. **Fix BUG-5** (UX) — add personnel type management to project edit contractor cards
5. **Update sync verification guide** — remove step 8 (Settings personnel types), correct guide for per-contractor personnel in entry wizard
6. **Re-run `/test sync` S01-S10** after fixes
7. **Commit** all changes after verification passes

### Test Run Context
- Run tag: mhaz3
- Results: `.claude/test_results/2026-03-26_00-39/`
- Checkpoint + report written with all entity IDs for resume

## Uncommitted Changes

### Dart files (production code — from prior sessions + this session):
- `lib/features/sync/engine/sync_engine.dart` — Fix A (idempotent delete), Fix B callsite (purgeOrphans), Fix C (transient error default), LWW push guard, fetchServerUpdatedAt, _shouldSkipLwwPush, upsertRemote extraction, skippedPush counter, **NEW: _reconcileSyncedProjects(), _rescueParentProject()**
- `lib/features/sync/application/sync_orchestrator.dart` — Fix C (transient error default), skippedPush mapping
- `lib/features/sync/engine/integrity_checker.dart` — Fix B (purgeOrphans method)
- `lib/features/sync/engine/change_tracker.dart` — getPendingRecordIds
- `lib/features/sync/domain/sync_types.dart` — SyncResult.skippedPush field
- `lib/features/sync/presentation/providers/sync_provider.dart` — LWW skip notification
- `lib/features/sync/presentation/widgets/deletion_notification_banner.dart` — testing key, TODO comments, Logger.db for startup race
- `lib/features/projects/data/services/project_lifecycle_service.dart` — **PRODUCTION BUG FIX**: `daily_entry_id` → `entry_id`, `inspector_forms` moved to `_directChildTables`
- `lib/features/projects/presentation/screens/project_list_screen.dart` — DeletionNotificationBanner wired in
- `lib/features/projects/presentation/screens/project_setup_screen.dart` — location/equipment edit buttons
- `lib/features/projects/presentation/widgets/add_location_dialog.dart` — edit mode, ScaffoldMessenger fix
- `lib/features/projects/presentation/widgets/add_equipment_dialog.dart` — edit mode, ScaffoldMessenger fix
- `lib/features/projects/presentation/widgets/equipment_chip.dart` — onEdit callback
- `lib/features/calculator/presentation/screens/calculator_screen.dart` — per-tab keys, extracted shared widgets, history delete
- `lib/shared/testing_keys/locations_keys.dart`, `contractors_keys.dart`, `toolbox_keys.dart`, `sync_keys.dart`, `testing_keys.dart` — new testing keys + facade delegations
- `lib/shared/testing_keys/entries_keys.dart`, `navigation_keys.dart` — widget key verification
- `lib/features/entries/presentation/screens/entry_editor_screen.dart` — widget keys
- `lib/core/driver/driver_server.dart` — expanded create-record allowlist + DRIVER_PORT dart-define + **change_log, user_profiles added to allowlist**
- `lib/main_driver.dart` — dynamic port log message
- `lib/core/database/schema/sync_engine_tables.dart` — **NEW: project_assignments added to triggeredTables + tablesWithDirectProjectId**
- `lib/core/database/database_service.dart` — **NEW: v40 migration (project_assignments triggers), CRIT-2 comment updated, version bump 39→40**

### Dart files (tests):
- `test/features/sync/engine/sync_engine_delete_test.dart` — 12 delete tests
- `test/features/sync/engine/sync_engine_lww_test.dart` — 5 LWW tests (NEW)
- `test/features/sync/engine/sync_engine_test.dart` — updated for shared helpers
- `test/helpers/sync/sync_engine_test_helpers.dart` — shared test helpers (NEW)
- `test/helpers/sync/sync_test_helpers.dart` — shared test helpers (NEW)
- `test/features/projects/presentation/screens/project_list_screen_test.dart` — pre-existing test fix

### JS files (test infrastructure — cleaned up by /implement S645):
- `tools/debug-server/server.js` — updated (removed old scenario references)
- `tools/debug-server/supabase-verifier.js` — cleanup-only (setupSharedFixture/teardownFixture removed)
- `tools/debug-server/run-tests.js` — stripped to cleanup-only mode
- Old files DELETED: scenario-helpers.js, integrity-runner.js, device-orchestrator.js, test-runner.js, all scenario files, deprecated/

### Other:
- `.gitignore` — .env.test, tools/debug-server/reports/
- `supabase/migrations/20260323000000_add_get_server_time_rpc.sql` (from prior session)

## Blockers

### BLOCKER-34: Item 38 — Superscript `th` → `"` (Tesseract limitation)
**Status**: OPEN (parked, cosmetic)

### BLOCKER-36: Item 130 — Whitewash destroys `y` descender
**Status**: OPEN (parked, cosmetic)

### BLOCKER-28: SQLite Encryption (sqlcipher)
**Status**: OPEN — production readiness blocker

### BLOCKER-23: Flutter Keys Not Propagating to Android resource-id
**Status**: OPEN — MEDIUM

## Recent Sessions

### Session 647 (2026-03-26)
**Work**: Ran /test sync S01 partial. Launched dual-device env (S21+ android:4948, Windows:4949). Created VRF-Oakridge mhaz3 project with entities. Found 5 bugs: dropdown saves wrong values (contractor type, pay item unit), assignment toggle not persisted to SQLite, inspector pulls unassigned project (RLS bypass), personnel types missing from project setup.
**Decisions**: Personnel types are entry-wizard-only. Project edit contractor cards need redesign to match entry wizard.
**Next**: Fix 5 bugs → re-run /test sync S01-S10 → commit.

### Session 646 (2026-03-25)
**Work**: Attempted /test sync S01. Found 3 blocking sync bugs: (1) synced_projects reconciliation gap after removeFromDevice, (2) FK chicken-and-egg on project_assignments pull, (3) project_assignments had NO change_log triggers so assignments never pushed. Fixed all 3. Trigger approach chosen over complex adapter-driven push.
**Decisions**: Add triggers to project_assignments (simpler than adapter-driven push). Personnel types are per-contractor (guide needs update).
**Next**: Rebuild both apps → clean slate → /test sync S01-S10.

### Session 645 (2026-03-25)
**Work**: Executed /implement for Claude-driven sync verification plan. 4 phases, 3 orchestrator launches, 0 handoffs. Deleted ~105 old JS files, stripped run-tests.js, updated skill/registry refs, created sync-verification-guide.md.
**Decisions**: supabase-verifier.js setupSharedFixture/teardownFixture removed (no callers).
**Next**: /test sync → commit.

### Session 644 (2026-03-25)
**Work**: Full /writing-plans pipeline. CodeMunch indexed, dependency graph built, plan written (1188 lines, 4 phases). 5 adversarial reviews (2 code, 2 security, 1 completeness). 13 findings fixed across 2 rounds — ground-truth mismatches (widget keys, driver params, port numbers, dropdown vs text).
**Decisions**: Toolbox via dashboard card. inject-photo-direct camelCase vs remove-from-device snake_case. Log scanning on port 3947. VRF sweep added to cleanup utility. Report has 8 sections.
**Next**: /implement → /test sync → commit.

### Session 643 (2026-03-25)
**Work**: Attempted JS integrity suite run — failed (widget timing, ADB hangs, data collisions). Pivoted: 3 opus research agents mapped full system. Brainstorming approved spec for Claude-driven sync verification (S01-S10). Dart: DRIVER_PORT dart-define for dual-device.
**Decisions**: Scrap JS-driven approach. Claude-driven curl flows like /test skill. Delete old JS infra. Keep cleanup-only utility. Post-run sweep = test failure if leftovers found.
**Next**: /writing-plans → /implement → /test sync.

### Session 642 (2026-03-25)
**Work**: Executed /implement for sync data integrity verification plan (5 phases, 4 orchestrator launches). Two integration review sweeps (code + completeness). All CRITICAL/HIGH/MEDIUM findings fixed across 2 fixer rounds. Calculator per-tab keys, shared widget extraction, ScaffoldMessenger fix, PDF field verification expanded (IDR 18 fields, 0582B 6 fields).
**Decisions**: Per-tab calculator keys. DeletionNotificationBanner raw SQL left as TODO. sweepVrfRecordsByPrefix rename.
**Next**: Build + deploy → run integrity suite → commit.


## Active Debug Session

None active.

## Test Results

### Flutter Unit Tests
- **Sync engine**: 288/288 passing (delete tests + LWW tests + reconciliation + FK rescue)
- **project_list_screen_test**: Fixed (missing mock stub + production code gates)
- **Full suite**: Needs retest after all changes

### Sync Verification
- **Old L2 system**: DELETED (Phase 1 of /implement)
- **JS integrity suite**: DELETED (scenarios, runners all removed)
- **Claude-driven sync (S01-S10)**: S01 PARTIAL — 5 bugs blocking. Report: `.claude/test_results/2026-03-26_00-39/report.md`

## Reference
- **Claude-Driven Sync Spec (APPROVED)**: `.claude/specs/2026-03-25-sync-verification-claude-driven-spec.md`
- **Claude-Driven Sync Plan (APPROVED)**: `.claude/plans/2026-03-25-sync-verification-claude-driven.md`
- **Plan Review Report**: `.claude/code-reviews/2026-03-25-sync-verification-claude-driven-plan-review.md`
- **Dependency Graph**: `.claude/dependency_graphs/2026-03-25-sync-verification-claude-driven/`
- **Old Data Integrity Spec (SUPERSEDED)**: `.claude/specs/2026-03-25-sync-data-integrity-verification-spec.md`
- **Old Plan (SUPERSEDED)**: `.claude/plans/2026-03-25-sync-data-integrity-verification.md`
- **Test Registry**: `.claude/test-flows/registry.md`
- **Defects**: `.claude/defects/_defects-{feature}.md`
