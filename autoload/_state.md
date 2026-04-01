# Session State

**Last Updated**: 2026-04-01 | **Session**: 700

## Current Phase
- **Phase**: WIRING RE-WIRE COMPLETE — S697 re-done. Lint cleanup (S698 redo) next.
- **Status**: Wiring-routing tracked file rewiring done. 3769 tests pass (4 pre-existing form_sub_screens failures). 0 analyze errors. NOT YET COMMITTED.

## HOT CONTEXT - Resume Here

### What Was Done This Session (700)

1. Audited all 33 surviving new files from S697 (32 COMPLETE, 1 BROKEN — harness_seed_data.dart em-dash syntax)
2. Wrote targeted re-wiring plan: `.claude/plans/2026-04-01-wiring-rewire-tracked-files.md`
3. Executed all 8 phases — directly, no orchestrator overhead:
   - **Phase 1**: AppInitializer — extracted types, InitOptions, captured supabaseClient (done by orchestrator)
   - **Phase 2**: Caller migration — all callers use qualified paths (deps.core.X, deps.auth.X), compat extension removed
   - **Phase 3**: Feature initializer delegation — app_initializer.dart 644→268 lines, delegates to AuthInitializer, ProjectInitializer, EntryInitializer, FormInitializer
   - **Phase 4**: Router split — redirect delegated to AppRedirect, ScaffoldWithNavBar removed from app_router.dart (~200 lines removed)
   - **Phase 5**: SyncProviders extraction — ~200 lines of inline logic replaced with SyncInitializer.create() delegation
   - **Phase 6**: AppBootstrap consolidation — main.dart 224→88 lines, main_driver.dart 122→72 lines
   - **Phase 7**: Cleanup — deleted 3 stale files, fixed harness_seed_data.dart syntax, added FakeSupabaseClient to mock_services.dart
   - **Phase 8**: Full test suite — 3769 pass, 4 pre-existing failures in form_sub_screens_test.dart
4. Fixed 3 test issues: FakeSupabaseClient missing from mock_services.dart, app_initializer_test.dart capture pattern, ChangeNotifierProvider.value for SupportProvider
5. Saved feedback: always use opus model for subagents

### Files Modified (10 tracked files)
- `lib/core/di/app_initializer.dart` — 644→268 lines (feature initializer delegation + compat extension removed)
- `lib/core/di/app_providers.dart` — qualified paths + consent/support params
- `lib/main.dart` — 224→88 lines (AppBootstrap + sentry_pii_filter)
- `lib/main_driver.dart` — 122→72 lines (AppBootstrap)
- `lib/core/router/app_router.dart` — redirect→AppRedirect, ScaffoldWithNavBar→import
- `lib/features/sync/di/sync_providers.dart` — inline logic→SyncInitializer delegation
- `lib/core/driver/harness_seed_data.dart` — em-dash syntax fix
- `test/helpers/mocks/mock_services.dart` — added FakeSupabaseClient
- `test/core/di/app_initializer_test.dart` — fixed structural test pattern

### Files Deleted (3)
- `lib/driver_main.dart` — stale flutter_driver shim
- `lib/test_harness.dart` — replaced by DriverServer HTTP harness
- `lib/test_harness/harness_providers.dart` — only used by test_harness.dart

### 32 Surviving New Files (UNTOUCHED)
All 32 new files from S697 confirmed intact and untouched. See plan for full list.

### What Needs to Happen Next
1. **COMMIT IMMEDIATELY** — on a feature branch, then PR
2. **Re-run lint cleanup** (session 698 redo) — violation map exists at `tmp_lint_fix_map.md`
3. **Remove ignore comments** SAFELY — use Python, not PowerShell
4. **Clean up temp files**: `tmp_*.ps1`, `tmp_*.txt`, `parse_violations.py` in project root

### Key Decisions Made (S700)
- **Targeted re-wiring plan** instead of full `/implement` re-run — preserved 32 existing new files, only modified tracked files
- **Phases 2+6 combined** for main.dart/main_driver.dart — rewrote both with AppBootstrap in one pass
- **Phase 3 done correctly** — delegated to all 4 feature initializers (auth, project, entry, form)
- **Direct edits** instead of orchestrator — much faster for mechanical tracked-file rewiring
- **Always use opus for subagents** — user feedback, saved to memory

### Committed Changes
- No commits yet — MUST COMMIT before session ends

## Blockers

### BLOCKER-39: Data Loss — Sessions 697-698 Destroyed
**Status**: PARTIALLY RESOLVED — S697 (wiring-routing) re-done. S698 (lint cleanup) still pending.
**Impact**: Lint cleanup (~1,200 code fixes) still needs re-doing.

### BLOCKER-38: Sign-Out Data Wipe Bug
**Status**: OPEN — discovered during lint cleanup
**Impact**: Sign-out destroys all local data via hard delete
**Location**: `lib/features/auth/services/auth_service.dart:354`
**Priority**: HIGH — data loss risk

### BLOCKER-37: Agent Write/Edit Permission Inheritance
**Status**: MITIGATED

### BLOCKER-34: Item 38 — Superscript `th` → `"` (Tesseract limitation)
**Status**: OPEN (parked, cosmetic)

### BLOCKER-36: Item 130 — Whitewash destroys `y` descender
**Status**: OPEN (parked, cosmetic)

### BLOCKER-28: SQLite Encryption (sqlcipher)
**Status**: OPEN — production readiness blocker

### BLOCKER-23: Flutter Keys Not Propagating to Android resource-id
**Status**: OPEN — MEDIUM

## Recent Sessions

### Session 700 (2026-04-01)
**Work**: Re-wired tracked files for wiring-routing plan. 10 files modified, 3 deleted, 32 new files untouched. app_initializer.dart 644→268 lines. main.dart 224→88 lines.
**Decisions**: Targeted re-wiring plan. Direct edits. Opus subagents only.
**Bugs Found**: 3 test fixes needed (FakeSupabaseClient, capture pattern, ChangeNotifierProvider.value).
**Next**: COMMIT → lint cleanup (S698 redo).

### Session 699 (2026-04-01)
**Work**: Lint rule allowlists (8 rules, ~150 paths). DATA LOSS: `git checkout --` destroyed sessions 697-698. Recovered 681-696 from dangling commit.
**Decisions**: File-level allowlists only. NEVER run destructive git commands.

### Session 698 (2026-04-01)
**Work**: Custom lint cleanup. 1,851→45 violations. ~1,200 real code fixes. **ALL LOST IN S699 INCIDENT.**

### Session 697 (2026-04-01)
**Work**: Ran `/implement` on wiring-routing plan. 8 phases, 94 new tests. **ALL LOST IN S699 INCIDENT.**

### Session 696 (2026-03-31)
**Work**: Fixed 72 dart analyze issues (clean). Config repo committed. **RECOVERED via dangling commit.**

## Active Debug Session

None active.

## Test Results

### Flutter Unit Tests
- **Full suite (S700)**: 3769 pass, 4 pre-existing fail (form_sub_screens_test.dart)
- **Analyze (S700)**: 0 errors, 189 infos/warnings (all pre-existing)
- **DI/Router/Sync tests (S700)**: 98/98 PASSING
- **Lint package**: 86/86 PASSING (S699)

### Sync Verification (S668 — 2026-03-28)
- **S01**: PASS | **S02**: PASS | **S03**: PASS
- **S04**: BLOCKED (no form seed) | **S05**: PASS | **S06**: PASS
- **S07**: PASS | **S08**: PASS | **S09**: FAIL (delete no push) | **S10**: PASS

## Reference
- **Re-Wiring Plan (DONE)**: `.claude/plans/2026-04-01-wiring-rewire-tracked-files.md`
- **Original Wiring/Routing Plan**: `.claude/plans/2026-03-31-wiring-routing-audit-fixes.md`
- **Quality Gates Plan (IMPLEMENTED)**: `.claude/plans/2026-03-31-automated-quality-gates.md`
- **Implement Checkpoint**: `.claude/state/implement-checkpoint.json`
- **Lint Package**: `fg_lint_packages/field_guide_lints/` (91 dart files, 43 custom rules)
- **Lint Fix Map**: `tmp_lint_fix_map.md` (original violation map from S698)
- **Temp files to clean up**: `tmp_*.ps1`, `tmp_*.txt`, `parse_violations.py` in project root
