# Session State

**Last Updated**: 2026-03-18 | **Session**: 589

## Current Phase
- **Phase**: All S585-S588 work committed (5 logical commits). Project State UI plan written + reviewed + fixed.
- **Status**: Plan ready for /implement. 4 CRITICAL + 5 HIGH review findings fixed inline in plan.

## HOT CONTEXT - Resume Here

### What Was Done This Session (589)

1. **Committed all S585-S588 work** — 5 logical app commits + 1 config commit:
   - `ac1cfaa` feat(supabase): migrations for viewer removal, admin soft-delete RPC, and type fix (8 files)
   - `5cffe44` feat(auth): remove viewer role, add role-based project permissions (16 files)
   - `0da85f7` fix(sync): phantom pending changes, DNS recovery, hard-delete push, tombstone guard (4 files)
   - `d1d139d` feat(projects): list UI overhaul with download flow, role controls, offline admin (12 files)
   - `7e791e7` test: project lifecycle delete flows, project list UI, setup screen, and sync fixes (6 files)
2. **Wrote Project State UI implementation plan** — 11-phase, 2460-line plan via /writing-plans skill
3. **Adversarial review (code + security)** — both REJECT'd with 4 CRITICAL + 5 HIGH findings, all fixed inline:
   - CRIT-1: `enforce_created_by()` writes wrong column → dedicated `enforce_assignment_assigned_by()` function
   - CRIT-2: `triggeredTables` causes RLS denial storm on inspectors → removed, adapter-driven push only
   - CRIT-4: Missing `unassigned_at` deletion detection → added to onPullComplete callback
   - HIGH: `display_name` not `full_name`, creator lock, `isOnline` guard, null guard on assignedBy

### Key Decisions (S589)
- `project_assignments` NOT in triggeredTables — adapter-driven push for admin/engineer only
- Dedicated `enforce_assignment_assigned_by()` trigger (not reusing `enforce_created_by()`)
- Creator always locked in assignment wizard (can't be unchecked)
- RemovalDialog requires `isOnline` — Sync & Remove greyed out when offline

### What Needs to Happen Next

1. **Invoke /implement** for project state UI plan → execute 11 phases
2. **Fix OrphanScanner bug** — `photos.company_id` doesn't exist, needs join through daily_entries
3. **Fix `handle_new_user()` trigger** — doesn't populate display_name from auth metadata
4. **Build + device test** after implementation

### KNOWN PROBLEMS
- **OrphanScanner crash**: `column photos.company_id does not exist` — needs join fix
- **Unknown display name**: `handle_new_user()` trigger only inserts `id`, no `display_name` from metadata
- **Repair migration needed** — remote DB has pre-review SQL; local files corrected post-review

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

### Session 588 (2026-03-18)
**Work**: Fixed admin dashboard RPC type mismatch + sync phantom-pending bug. Brainstormed + spec'd Project State UI (3-tab layout, project_assignments table, assignment wizard, auto-enrollment). Adversarial review complete (6 MUST-FIX resolved, 8 SHOULD-CONSIDER decided). Debug APK on GitHub.
**Decisions**: Assignments = organizational not access-control. Scoped SELECT RLS. Archived respects assignments. In-memory wizard state.
**Next**: Commit. /writing-plans for project state UI. Fix OrphanScanner + display_name bugs.

### Session 587 (2026-03-18)
**Work**: Device testing bug fixes (P1 location, P2 weather, P4/P8 delete-sync, P6/P7 admin offline). CRITICAL: found and fixed sync permanent offline trap (_isOnline never recovers). Debug APK v0.1.2-debug-s587 on GitHub.
**Decisions**: Tombstone check via change_log not separate table. P3/P5 are network, not code.
**Next**: Device test new APK. Commit.

### Session 586 (2026-03-18)
**Work**: /implement project management E2E plan (11 phases, 6 orchestrator launches, 0 handoffs). 30 files modified, 3032 tests passing. All reviews PASS. Bug found: code.contains('503') masks 23503 FK errors.
**Decisions**: Batched final 4 phases into one orchestrator launch. Repair migration deferred as tech debt.
**Next**: Commit. Push Supabase migrations. Build + device test. Fix BLOCKER-22. Fix 503 bug.

### Session 585 (2026-03-17)
**Work**: Implemented sync hardening plan (4 orchestrator launches, 2962 tests passing). Device testing found Import broken (missing Provider). Full project lifecycle audit (13 issues). Brainstormed + spec'd + planned project management E2E fix (11 phases). Committed 7 app commits + 2 config commits.
**Decisions**: Metadata auto-sync only (no auto-enroll). Keep canWrite (add new methods alongside). SECURITY DEFINER RPC for remote delete. Remove viewer role. Available Projects from local SQLite.
**Next**: /implement project management E2E plan. Build + device test. Fix BLOCKER-22.

### Session 589 (2026-03-18)
**Work**: Committed all S585-S588 work (5 app commits, 1 config commit). /writing-plans produced 11-phase project state UI plan. Adversarial review (code+security) found 4 CRITICAL + 5 HIGH — all fixed inline. Plan ready for /implement.
**Decisions**: project_assignments NOT in triggeredTables (adapter-driven push). Dedicated enforce_assignment_assigned_by() trigger. Creator locked in wizard. RemovalDialog requires isOnline.
**Next**: /implement project state UI. Fix OrphanScanner + display_name bugs. Build + device test.

## Active Plans

### Project State UI & Assignments — PLAN COMPLETE, READY FOR /IMPLEMENT
- **Spec**: `.claude/specs/2026-03-18-project-state-ui-spec.md`
- **Plan**: `.claude/plans/2026-03-18-project-state-ui.md`
- **Review**: `.claude/code-reviews/2026-03-18-project-state-ui-plan-review.md`
- **Status**: 11-phase plan written, adversarial reviewed (4 CRIT + 5 HIGH fixed). Ready for /implement.

### Project Management E2E Fix — COMMITTED (Session 589)
- **Spec**: `.claude/specs/2026-03-17-project-management-e2e-spec.md`
- **Plan**: `.claude/plans/2026-03-17-project-management-e2e.md`
- **Status**: All 11 phases implemented. Committed in 5 logical commits. Needs device test.

### Sync Hardening & RLS Enforcement — IMPLEMENTED + COMMITTED (Session 585)
- **Plan**: `.claude/plans/2026-03-17-sync-hardening-and-rls.md`
- **Status**: All 6 phases implemented. 2962 tests passing. Committed.

## Reference
- **Project State UI Spec**: `.claude/specs/2026-03-18-project-state-ui-spec.md`
- **Project Management E2E Spec**: `.claude/specs/2026-03-17-project-management-e2e-spec.md`
- **Project Lifecycle Spec**: `.claude/specs/2026-03-16-project-lifecycle-spec.md`
- **Pipeline UX Spec**: `.claude/specs/2026-03-15-pipeline-ux-overhaul-spec.md`
- **Defects**: `.claude/defects/_defects-pdf.md`, `_defects-sync.md`, `_defects-entries.md`
- **Debug build tag**: `debug-admin-dashboard-v0.1.2` on GitHub releases
- **Release build tag**: `v0.1.1` on GitHub releases
