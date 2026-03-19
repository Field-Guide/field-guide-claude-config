# Session State

**Last Updated**: 2026-03-19 | **Session**: 592

## Current Phase
- **Phase**: E2E sync verification system designed and spec'd. Ready for /writing-plans → /implement.
- **Status**: S590 Project State UI work still uncommitted. 14 bugs from S591 still open.

## HOT CONTEXT - Resume Here

### What Was Done This Session (592)

1. **Researched existing testing infrastructure** — 488 testing keys across 12 files, test harness with flutter_driver, debug server on port 3947
2. **Identified ~30 missing testing keys** across sync dashboard, project list tabs, filter chips, dialogs, assignment step, project switcher
3. **Brainstormed + spec'd E2E sync verification system** — 42 test flows across 7 tiers covering all 17 synced tables
4. **Adversarial review** (code-review + security) found 10 MUST-FIX items — all resolved in spec:
   - 5 table name mismatches corrected (daily_entries, todo_items, entry_personnel_counts, entry_equipment, inspector_forms)
   - flutter_driver for driving app (not custom HTTP server) + debug server for diagnostics
   - SERVICE_ROLE_KEY in `.env.secret` (not `.env`)
   - T31 RLS test must use user JWT, not service role key
   - Cleanup enforces `E2E ` prefix
5. **Spec saved**: `.claude/specs/2026-03-19-e2e-sync-verification-spec.md`
6. **Review saved**: `.claude/adversarial_reviews/2026-03-19-e2e-sync-verification/review.md`

### Key Decisions (S592)
- Hybrid approach: flutter_driver for coordinates/taps + HTTP debug server for diagnostics/logs
- New `/sync/status` endpoint on existing debug server (port 3947) for sync completion polling
- E2E prefix on all test data, existing account (no separate test company)
- `flow_registry.md` in `.claude/test_results/` (persists in config repo, not gitignored)
- Windows-only testing for now; device-adaptable when phone available

### What Needs to Happen Next

1. **Run /writing-plans** on the e2e sync verification spec
2. **Run /implement** to build the verification system (testing keys, debug server sync status, verify-sync.ps1, flow registry)
3. **Fix BUG-006** — sticky `_isOnline` flag (critical, blocks all sync testing)
4. **Fix BUG-005** — `synced_projects` enrollment gap
5. **Fix BUG-007 + BUG-008** — route guards + `canWrite` permission model
6. **Still pending from S590**: flutter test, analyze, commit Project State UI work

### KNOWN PROBLEMS
- **OrphanScanner crash**: `column photos.company_id does not exist` — needs join fix
- **Unknown display name**: `handle_new_user()` trigger only inserts `id`, no `display_name` from metadata
- **Repair migration needed** — remote DB has pre-review SQL; local files corrected post-review
- **14 bugs in `bugs_report.md`** — see file for full details

## Blockers

### BLOCKER-22: Location Field Stuck "Loading"
**Status**: FIXED (S587)

### BLOCKER-34: Item 38 — Superscript `th` → `"` (Tesseract limitation)
**Status**: OPEN

### BLOCKER-36: Item 130 — Whitewash destroys `y` descender
**Status**: OPEN

### BLOCKER-28: SQLite Encryption (sqlcipher)
**Status**: OPEN

### BLOCKER-23: Flutter Keys Not Propagating to Android resource-id
**Status**: OPEN — MEDIUM

## Recent Sessions

### Session 592 (2026-03-19)
**Work**: Designed E2E sync verification system. Researched testing keys (488 existing, ~30 missing). Brainstormed + spec'd 42-flow test checklist covering 17 tables. Adversarial review (10 MUST-FIX resolved). Architecture: flutter_driver + debug server hybrid.
**Decisions**: flutter_driver for driving, debug server for diagnostics. E2E prefix for test data. `.env.secret` for service role key. flow_registry in .claude/.
**Next**: /writing-plans → /implement verification system. Fix BUG-006 (blocks sync testing). Commit S590 work.

### Session 591 (2026-03-18)
**Work**: Live 2-device testing (S25 admin + Windows inspector). Filed 14 bugs in `bugs_report.md`. Critical: sticky _isOnline kills sync (BUG-006), synced_projects gap (BUG-005), no route guards (BUG-007), canWrite=true for inspector (BUG-008). Permission audit found 10 inspector role gaps.
**Decisions**: BUG-013 dismissed (inspector remove-from-device is intentional). Session ended early — S25 sync blocked.
**Next**: Fix BUG-006 (sticky _isOnline). Fix BUG-005/007/008. Re-run untested flows. Commit S590 work.

### Session 590 (2026-03-18)
**Work**: /implement project state UI plan (11 phases, 9 orchestrator launches, 0 handoffs). 38 files modified. All reviews PASS. New: project_assignments table, adapter, provider, 3-tab list screen, assignment wizard.
**Decisions**: None new — followed S588-S589 spec/plan decisions.
**Next**: flutter test + analyze. Commit. Fix OrphanScanner + display_name bugs. Build + device test.

### Session 589 (2026-03-18)
**Work**: Committed all S585-S588 work (5 app commits, 1 config commit). /writing-plans produced 11-phase project state UI plan. Adversarial review (code+security) found 4 CRITICAL + 5 HIGH — all fixed inline. Plan ready for /implement.
**Decisions**: project_assignments NOT in triggeredTables (adapter-driven push). Dedicated enforce_assignment_assigned_by() trigger. Creator locked in wizard. RemovalDialog requires isOnline.
**Next**: /implement project state UI. Fix OrphanScanner + display_name bugs. Build + device test.

### Session 588 (2026-03-18)
**Work**: Fixed admin dashboard RPC type mismatch + sync phantom-pending bug. Brainstormed + spec'd Project State UI (3-tab layout, project_assignments table, assignment wizard, auto-enrollment). Adversarial review complete (6 MUST-FIX resolved, 8 SHOULD-CONSIDER decided). Debug APK on GitHub.
**Decisions**: Assignments = organizational not access-control. Scoped SELECT RLS. Archived respects assignments. In-memory wizard state.
**Next**: Commit. /writing-plans for project state UI. Fix OrphanScanner + display_name bugs.

## Active Plans

### E2E Sync Verification System — SPEC COMPLETE (Session 592)
- **Spec**: `.claude/specs/2026-03-19-e2e-sync-verification-spec.md`
- **Review**: `.claude/adversarial_reviews/2026-03-19-e2e-sync-verification/review.md`
- **Status**: Spec approved. Needs /writing-plans → /implement.

### Project State UI & Assignments — IMPLEMENTED (Session 590)
- **Spec**: `.claude/specs/2026-03-18-project-state-ui-spec.md`
- **Plan**: `.claude/plans/2026-03-18-project-state-ui.md`
- **Review**: `.claude/code-reviews/2026-03-18-project-state-ui-plan-review.md`
- **Status**: All 11 phases implemented (9 orchestrator launches). 38 files modified. Needs commit + device test.

### Project Management E2E Fix — COMMITTED (Session 589)
- **Spec**: `.claude/specs/2026-03-17-project-management-e2e-spec.md`
- **Plan**: `.claude/plans/2026-03-17-project-management-e2e.md`
- **Status**: All 11 phases implemented. Committed in 5 logical commits. Needs device test.

### Sync Hardening & RLS Enforcement — IMPLEMENTED + COMMITTED (Session 585)
- **Plan**: `.claude/plans/2026-03-17-sync-hardening-and-rls.md`
- **Status**: All 6 phases implemented. 2962 tests passing. Committed.

## Reference
- **E2E Sync Verification Spec**: `.claude/specs/2026-03-19-e2e-sync-verification-spec.md`
- **Project State UI Spec**: `.claude/specs/2026-03-18-project-state-ui-spec.md`
- **Project Management E2E Spec**: `.claude/specs/2026-03-17-project-management-e2e-spec.md`
- **Project Lifecycle Spec**: `.claude/specs/2026-03-16-project-lifecycle-spec.md`
- **Pipeline UX Spec**: `.claude/specs/2026-03-15-pipeline-ux-overhaul-spec.md`
- **Defects**: `.claude/defects/_defects-pdf.md`, `_defects-sync.md`, `_defects-entries.md`
- **Debug build tag**: `debug-admin-dashboard-v0.1.2` on GitHub releases
- **Release build tag**: `v0.1.1` on GitHub releases
