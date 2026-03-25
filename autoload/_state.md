# Session State

**Last Updated**: 2026-03-25 | **Session**: 641

## Current Phase
- **Phase**: Sync & Data Integrity Verification — plan complete, ready for /implement
- **Status**: Writing-plans complete. Plan written (5 phases, ~15 sub-phases, 2260 lines). Code review REJECTED → all 3 CRITICAL + 5 HIGH + 6 missing requirements fixed. Security APPROVED with 2 conditions (both applied).

## HOT CONTEXT - Resume Here

### What Was Done This Session (641)

1. **Full writing-plans pipeline** — CodeMunch indexed 6008 symbols, traced all affected files
2. **Dependency graph** saved to `.claude/dependency_graphs/2026-03-25-sync-data-integrity-verification/`
3. **Plan written** (opus) — 5 phases: UI additions (Dart), JS infrastructure, flow scenarios, update/delete/PDF, cleanup
4. **Code review** (opus) — REJECTED with 3 CRIT, 5 HIGH, 4 MEDIUM, 6 missing requirements
5. **Security review** (sonnet) — APPROVED with 2 conditions (SEC-002 name length cap, SEC-004 .gitignore fix)
6. **Fixer agent** (opus) — applied all CRITICAL/HIGH fixes + missing requirements + security conditions

### Key Decisions Made

1. **copyWith nullability**: Use `.trim()` not `null` for empty descriptions — avoids model changes
2. **PDF verification**: Use `pdftk dump_data_fields_utf8` NOT `pdf-parse` — pdf-parse can't read AcroForm fields
3. **Sweep coverage**: Two-pass sweep — named tables by VRF- prefix, then child tables by collected project IDs
4. **L2/L3 deprecation**: Move to `deprecated/` folder, NOT delete — safety net until integrity suite proven
5. **personnel_types cascade**: Skip in cascade check if company-scoped (no project_id match)

### What Needs to Happen Next

1. **Run `/implement`** with plan path `.claude/plans/2026-03-25-sync-data-integrity-verification.md`
2. **Build + deploy** driver APK to S21+, Windows driver app on port 4949
3. **Run full integrity suite** — `node tools/debug-server/run-tests.js --suite=integrity --devices=dual`

## Uncommitted Changes

### Dart files (production code):
- `lib/features/sync/engine/sync_engine.dart` — Fix A (idempotent delete), Fix B callsite (purgeOrphans), Fix C (transient error default), LWW push guard, fetchServerUpdatedAt, _shouldSkipLwwPush, upsertRemote extraction, skippedPush counter
- `lib/features/sync/application/sync_orchestrator.dart` — Fix C (transient error default), skippedPush mapping
- `lib/features/sync/engine/integrity_checker.dart` — Fix B (purgeOrphans method)
- `lib/features/sync/engine/change_tracker.dart` — getPendingRecordIds
- `lib/features/sync/domain/sync_types.dart` — SyncResult.skippedPush field
- `lib/features/sync/presentation/providers/sync_provider.dart` — LWW skip notification
- `lib/features/projects/data/services/project_lifecycle_service.dart` — **PRODUCTION BUG FIX**: `daily_entry_id` → `entry_id`, `inspector_forms` moved to `_directChildTables`
- `lib/features/projects/presentation/screens/project_list_screen.dart` — pre-existing test fix
- `lib/shared/testing_keys/entries_keys.dart`, `testing_keys.dart`, `navigation_keys.dart` — widget key verification
- `lib/features/entries/presentation/screens/entry_editor_screen.dart` — widget keys
- `lib/core/driver/driver_server.dart` — expanded create-record allowlist to all 17 synced tables

### Dart files (tests):
- `test/features/sync/engine/sync_engine_delete_test.dart` — 12 delete tests
- `test/features/sync/engine/sync_engine_lww_test.dart` — 5 LWW tests (NEW)
- `test/features/sync/engine/sync_engine_test.dart` — updated for shared helpers
- `test/helpers/sync/sync_engine_test_helpers.dart` — shared test helpers (NEW)
- `test/helpers/sync/sync_test_helpers.dart` — shared test helpers (NEW)
- `test/features/projects/presentation/screens/project_list_screen_test.dart` — pre-existing test fix

### JS files (test infrastructure):
- `tools/debug-server/scenario-helpers.js` — TestContext, 8 factories, runConflictPhase sleep fix, updateRecord auto-stamp
- `tools/debug-server/device-orchestrator.js` — updateRecord(), removeLocalRecord()
- `tools/debug-server/supabase-verifier.js` — sweep, setupSharedFixture, teardownFixture
- `tools/debug-server/run-tests.js` — CLI flags, lifecycle, RLS pre-check
- `tools/debug-server/test-runner.js` — S5 re-sync logic, context threading
- 58+ L2 scenario files rewritten (to be replaced by new UI-driven flows)
- 10 L3 scenario files rewritten
- Various scenario-specific fixes

### Other:
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

### Session 641 (2026-03-25)
**Work**: Full writing-plans pipeline for sync data integrity verification. CodeMunch indexed, dependency graph built, plan written (5 phases, 2260 lines). Code review REJECTED (3 CRIT, 5 HIGH) → fixer applied all fixes + 6 missing requirements. Security APPROVED with 2 conditions (applied).
**Decisions**: Use pdftk not pdf-parse for AcroForm fields. Two-pass sweep for child tables. Move L2/L3 to deprecated/ not delete. Use .trim() for copyWith nullability.
**Next**: /implement → build + deploy → run integrity suite.

### Session 640 (2026-03-25)
**Work**: Full brainstorming for sync & data integrity verification. 6 research agents (opus) audited all 17 sync tables, UI paths, RLS policies, PDF field mappings, remote-delete notification. Wrote comprehensive spec covering sync verification (6 UI-driven flows), PDF export verification (IDR + 0582B), and UI additions (location/equipment edit, calc history delete, deletion notification banner).
**Decisions**: Scrap 84 L2 scenarios + S4 conflicts. Two real devices (S21+ admin, Windows inspector). Single chained run. VRF- prefix test data. Second project for unassignment test.
**Next**: /writing-plans → /implement → build + deploy → run full integrity suite.

### Session 639 (2026-03-25)
**Work**: Implemented Category B plan (22 JS files, 7 phases, 3 orchestrator launches). Built driver APK, deployed to S21+. Ran full L2: 7/84 (regression from 11/84). Debug research agent identified sync pull=0 root cause: `seedAndSync` does 1 sync round but project-scoped adapters need 2 (first round enrolls projects, second pulls child tables).
**Decisions**: None — diagnostic session. Root cause identified but not fixed.
**Next**: Fix seedAndSync double-sync, fix projects-S4/S5 assigned_by, re-run L2.

### Session 638 (2026-03-25)
**Work**: Full brainstorming → writing-plans pipeline for L2 Category B conversion. 3 opus research agents mapped 20 Category B files + one-off issues. Spec approved. Plan written (7 phases, 22 files). Both reviews APPROVE.
**Decisions**: All S4 create scenario-local records. projects-S4/S5 gets scenario-local project + try/finally cleanup. Valid 1x1 JPEG for photos-S1.
**Next**: /implement the plan, re-run full L2 (target 84/84), commit everything.

### Session 637 (2026-03-25)
**Work**: Massive implementation session. Executed sync test redesign plan (8 phases, ~97 files) — all 7 code phases DONE. Smoke test revealed no LWW on push. Built + implemented LWW push guard (5 phases). Found + fixed production bug in ProjectLifecycleService. Full L2: 11/84.
**Decisions**: LWW push guard: pre-fetch server updated_at, skip if server newer. Soft-delete excluded from LWW.
**Next**: Convert Category B files, fix photos-S1/project-assignments-S5.

## Active Debug Session

None active.

## Test Results

### Flutter Unit Tests
- **Sync engine**: 288/288 passing (delete tests + LWW tests)
- **project_list_screen_test**: Fixed (missing mock stub + production code gates)
- **Full suite**: Needs retest after all changes

### Sync Verification
- **Old L2 system**: DEPRECATED — 84 direct-injection scenarios scrapped
- **New integrity suite**: Not yet built — spec complete, awaiting plan + implementation

## Reference
- **Data Integrity Verification Spec (APPROVED)**: `.claude/specs/2026-03-25-sync-data-integrity-verification-spec.md`
- **Data Integrity Verification Plan (READY)**: `.claude/plans/2026-03-25-sync-data-integrity-verification.md`
- **Plan Review**: `.claude/code-reviews/2026-03-25-sync-data-integrity-verification-plan-review.md`
- **Dependency Graph**: `.claude/dependency_graphs/2026-03-25-sync-data-integrity-verification/`
- **Category B Conversion Spec**: `.claude/specs/2026-03-25-l2-category-b-conversion-spec.md`
- **Category B Conversion Plan**: `.claude/plans/2026-03-25-l2-category-b-conversion.md`
- **Redesign Plan (EXECUTED)**: `.claude/plans/2026-03-24-sync-test-redesign-and-delete-fix.md`
- **LWW Plan (EXECUTED)**: `.claude/plans/2026-03-24-lww-push-guard-and-test-fixes.md`
- **Test Registry**: `.claude/test-flows/registry.md`
- **Defects**: `.claude/defects/_defects-{feature}.md`

## Architecture Notes for Next Session

### New integrity suite structure:
```
run-tests.js --suite=integrity --devices=dual
  → Login both devices (admin on S21+:4948, inspector on Windows:4949)
  → F1: Project Setup (7 tables) — create via UI → sync → verify push → pull to Windows
  → F2: Daily Entry (5 tables) — create via UI → sync → verify → pull
  → F3: Photos (1 table + storage) — inject-photo-direct → sync → verify
  → F4: Forms (2 tables) — fill 0582B via UI → sync → verify
  → F5: Todos (1 table) — create via UI → sync → verify
  → F6: Calculator (1 table) — calculate + save → sync → verify
  → Update Phase — update all updatable tables via UI → sync → verify
  → PDF Export — IDR + 0582B → adb pull → field-value verification
  → Delete Phase — cascade delete → verify all child tables → notification banner
  → Unassignment — 2nd project → unassign inspector → verify removal
  → Cleanup Sweep — safety net hard-delete of VRF- prefixed records
```

### UI additions needed (Workstream C):
- C1: Location edit button (`location_edit_button_<id>`)
- C2: Equipment edit button (`equipment_edit_button_<id>`)
- C3: Calculation history delete button (`calculation_history_delete_button_<id>`)
- C4: Wire `DeletionNotificationBanner` into `ProjectListScreen` (widget exists, just not placed)

### DeletionNotificationBanner status:
- Widget: `lib/features/sync/presentation/widgets/deletion_notification_banner.dart` — COMPLETE
- Trigger: `sync_engine.dart:1547-1552` `_createDeletionNotification()` — WORKS (creates `deletion_notifications` row)
- Problem: Banner not placed in any widget tree. Inspector sees nothing when project deleted.
- Fix: Add to `ProjectListScreen` body alongside `ProjectImportBanner`
