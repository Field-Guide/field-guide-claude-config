# Session State

**Last Updated**: 2026-03-26 | **Session**: 650

## Current Phase
- **Phase**: Sync Verification — ready for `/test sync` S01-S10
- **Status**: Schema divergence fix implemented, all tests pass, migration pushed. 3 commits on feat/sync-engine-rewrite. Need to rebuild both apps and run sync verification.

## HOT CONTEXT - Resume Here

### What Was Done This Session (650)

1. **`/implement` schema divergence fix** — 3 orchestrator launches (G1: Supabase migration, G2: SQLite+model+dependent updates, G3: verification). All 4 phases passed reviews. 0 handoffs.
2. **Supabase migration pushed** — `20260326100000_schema_divergence_fix.sql` applied successfully.
3. **Flutter tests + analyze** — all passing.
4. **Committed 3 logical commits** to `feat/sync-engine-rewrite`:
   - `38227eb` fix(ui): S01 test bugs in project setup and contractor editor
   - `cee8c4b` fix(sync): align project_assignments schema across SQLite and Supabase
   - `ce61620` fix(tools): PSBoundParameters for -Driver flag guard

### What Needs to Happen Next

1. **Rebuild both apps** (Android + Windows)
2. **Re-run `/test sync` S01-S10** on clean slate
3. **Commit** any further fixes after verification passes

### Test Run Context
- Previous run tag: etq76 (blocked by schema divergence)
- Results dir: `.claude/test_results/2026-03-26_08-11/`
- Next run: fresh after rebuild

## Uncommitted Changes

None — all changes committed in S650.

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

### Session 650 (2026-03-26)
**Work**: Executed /implement for schema divergence fix. 3 orchestrator launches, 4 phases, 0 handoffs. All reviews passed. Migration pushed. Tests + analyze passing. Committed 3 logical commits (UI fixes, schema divergence, build.ps1).
**Decisions**: None new — executing approved plan.
**Next**: Rebuild both apps → /test sync S01-S10.

### Session 649 (2026-03-26)
**Work**: Schema divergence audit + fix plan. Pushed RLS migration, launched dual-device, S01 failed on PGRST204 (created_by_user_id missing). 2 opus agents audited all 17 tables. Writing-plans pipeline: plan + 4 review rounds (8 opus reviews). Fixed CRITICAL (soft-deleted assignments grant project visibility), 2 HIGH (column immutability, _directChildTables), 4 MEDIUM (purge, repository filters, test fixtures). Also fixed build.ps1 -Driver flag bug.
**Decisions**: project_assignments moves to soft-delete. Column immutability via trigger (not client trust). company_projects_select RLS updated for soft-delete.
**Next**: /implement plan → push migration → rebuild → /test sync S01-S10.

### Session 648 (2026-03-26)
**Work**: Fixed 4 of 5 S01 bugs. BUG-2 (dropdown setState interference), BUG-3 (assignment creator not persisted), BUG-4 (RLS SELECT too broad — SECURITY), BUG-5 (personnel types added to project setup via ContractorEditorWidget setupMode). BUG-1 was already fixed (stale APK).
**Decisions**: setupMode flag on ContractorEditorWidget to suppress entry-specific counters. RLS-only fix for BUG-4 (no adapter change). Default type seeding on contractor creation.
**Next**: Rebuild + push RLS migration → /test sync S01-S10 → commit.

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

## Active Debug Session

None active.

## Test Results

### Flutter Unit Tests
- **Full suite**: PASSING (verified in S650 /implement Phase 4)
- **Analyze**: PASSING (0 issues)

### Sync Verification
- **Claude-driven sync (S01-S10)**: Ready for fresh run — schema divergence fixed, migration pushed.
- **Previous run (etq76)**: `.claude/test_results/2026-03-26_08-11/` — blocked at S01 (now fixed)
- **Next**: Rebuild apps → `/test sync` S01-S10

## Reference
- **Schema Divergence Fix Plan (APPROVED, 4 rounds)**: `.claude/plans/2026-03-26-schema-divergence-fix.md`
- **Schema Divergence Reviews**: `.claude/code-reviews/2026-03-26-schema-divergence-fix-plan-review.md`
- **Schema Audit (Supabase)**: `.claude/test_results/2026-03-26_08-11/supabase_schema.md`
- **Schema Audit (SQLite)**: `.claude/test_results/2026-03-26_08-11/sqlite_schema.md`
- **Dependency Graph**: `.claude/dependency_graphs/2026-03-26-schema-divergence-fix/`
- **Claude-Driven Sync Spec (APPROVED)**: `.claude/specs/2026-03-25-sync-verification-claude-driven-spec.md`
- **Claude-Driven Sync Plan (APPROVED)**: `.claude/plans/2026-03-25-sync-verification-claude-driven.md`
- **Plan Review Report**: `.claude/code-reviews/2026-03-25-sync-verification-claude-driven-plan-review.md`
- **Dependency Graph**: `.claude/dependency_graphs/2026-03-25-sync-verification-claude-driven/`
- **Old Data Integrity Spec (SUPERSEDED)**: `.claude/specs/2026-03-25-sync-data-integrity-verification-spec.md`
- **Old Plan (SUPERSEDED)**: `.claude/plans/2026-03-25-sync-data-integrity-verification.md`
- **Test Registry**: `.claude/test-flows/registry.md`
- **Defects**: `.claude/defects/_defects-{feature}.md`
