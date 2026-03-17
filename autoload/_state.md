# Session State

**Last Updated**: 2026-03-17 | **Session**: 584

## Current Phase
- **Phase**: Sync hardening plan WRITTEN + REVIEWED
- **Status**: Plan at `.claude/plans/2026-03-17-sync-hardening-and-rls.md` is ready for `/implement`. 8 prior bugfixes still uncommitted from S583.

## HOT CONTEXT - Resume Here

### What Was Done This Session (584)

1. **Systematic debugging** — loaded debugging skill, ran Phase 1 triage (no orphaned hypothesis markers)
2. **Launched 2 deep research agents in parallel**:
   - Agent 1: BLOCKER-38 root cause trace + proactive sync audit (10 findings)
   - Agent 2: BLOCKER-39 RLS audit + Supabase schema review
3. **CodeMunch indexed** — 5520 symbols, traced all affected symbols via get_file_outline + get_symbols
4. **Dependency graph saved** — `.claude/dependency_graphs/2026-03-17-sync-hardening-and-rls/analysis.md`
5. **Plan written** — Opus plan-writer produced 6-phase, 10-commit plan
6. **Adversarial review** — code-review-agent + security-agent ran in parallel:
   - Code review: REJECT (2 CRIT, 5 HIGH, 4 MED)
   - Security review: APPROVE WITH CONDITIONS (2 CRIT, 4 HIGH, 4 MED)
7. **All findings fixed inline** — 14 specific fixes applied directly to plan text
8. **Review report saved** — `.claude/code-reviews/2026-03-17-sync-hardening-and-rls-plan-review.md`

### Key Decisions (S584)
- ConflictResolver keeps `Future<ConflictWinner>` return type — uses `getConflictCount()` query instead of breaking API
- Offline removal guard at BOTH service layer (throws StateError) AND UI (early-exit dialog)
- Supabase migration uses `DROP POLICY IF EXISTS` for all known policy name variants — defensive against partial migration state
- Step 1.2.2 covers 5 tables (not 3) — entry_equipment and entry_contractors also had USING(true) history
- Magic number 3 → `SyncEngineConfig.conflictPingPongThreshold`
- EntryPersonnelCountsAdapter fkColumnMap: `type_id` not `personnel_type_id`

### What Needs to Happen Next

1. **Commit 8 bugfixes from S583** — still uncommitted (auth, sync, admin, project_setup)
2. **`/implement` the sync hardening plan** — `.claude/plans/2026-03-17-sync-hardening-and-rls.md`
3. **Test on device** after implementation
4. **Fix BLOCKER-22**: Location field stuck "Loading" — HIGH PRIORITY

### What Was Done Prior Session (583)

1. **Pushed Supabase migrations** — already up to date (2 RLS migrations pushed in prior session)
2. **Version bumped to 0.1.1+2** — `pubspec.yaml` updated
3. **GitHub releases cleaned** — deleted 4 old releases, created v0.1.1 release APK
4. **VS Code launch config updated** — added `--dart-define=DEBUG_SERVER=true` to Windows Desktop config
5. **8 bugfixes applied** (uncommitted):
   - `join_request_remote_datasource.dart`: `created_at` → `requested_at`
   - `admin_provider.dart`: lazy repository with dynamic companyId, null-safety guards on all actions
   - `main.dart`: removed AdminRepository import, simplified AdminProvider construction
   - `sync_engine.dart`: company_id stamping moved before pre-check, FK cascade on ID remap with `_childFkColumns()`, trigger suppression during remap, `_UniqueConflict` result type
   - `pending_approval_screen.dart`: fallback polling via profile refresh when requestId is empty
   - `auth_provider.dart`: added `forceReauthOnly()` method (re-auth without data wipe)
   - `main.dart`: upgrade handler uses `forceReauthOnly()` instead of `signOutLocally()`
   - `project_setup_screen.dart`: draft INSERT suppresses change_log trigger
6. **REVERTED auto-enrollment** — pulled projects should NOT auto-enroll in synced_projects. Selective import is by design — only metadata pulls, child data pulls after user explicitly imports.

### KNOWN PROBLEM (must fix next session)
- **Sync auto-enrollment was reverted** — the auto-enrollment of pulled projects into `synced_projects` was wrong. The design is: pull project metadata only, user explicitly imports to get child data. However, the investigation revealed that pulled-but-not-enrolled projects show in the project list but can't be imported (isRemoteOnly=false since they exist in local SQLite). This UX gap needs fixing — either show an "Import" option for pulled-but-unenrolled projects, or mark them differently.
- **Ghost change_log entries** — on admin phone, 1 pending project change from old forced sign-out still persists. User needs to sign out + sign back in to clear it, then test with new build.

### What Needs to Happen Next

1. **Commit all valid fixes** — 8 bugfixes listed above are uncommitted
2. **Fix project import UX gap** — pulled projects exist locally but aren't enrolled; need "Import" action visible for them
3. **RLS ENABLE migration** — 8 tables have policies but RLS not enabled (UNRESTRICTED in Supabase dashboard)
4. **Test admin dashboard** — with new APK, verify join request approval flow works end-to-end
5. **BLOCKER-22**: Location field stuck "Loading" — HIGH PRIORITY

## Blockers

### BLOCKER-38: Pulled Projects Can't Be Imported
**Status**: PLAN READY — Root cause: sync_engine._pullTable() inserts projects but never enrolls in synced_projects. Fix in plan Phase 2.1.

### BLOCKER-39: 8 Supabase Tables Missing ENABLE ROW LEVEL SECURITY
**Status**: PLAN READY — Fix in plan Phase 1.2. Migration also covers 5 tables with USING(true) policies and adds 6 performance indexes.

### BLOCKER-34: Item 38 — Superscript `th` → `"` (Tesseract limitation)
**Status**: OPEN — Ordinal suffix recovery rule needed in post-processing.

### BLOCKER-36: Item 130 — Whitewash destroys `y` descender
**Status**: OPEN — Threshold-based whitewash needed (skip dark text pixels).

### BLOCKER-28: SQLite Encryption (sqlcipher)
**Status**: OPEN — tracked separately.

### BLOCKER-22: Location Field Stuck "Loading"
**Status**: OPEN — HIGH PRIORITY

### BLOCKER-23: Flutter Keys Not Propagating to Android resource-id
**Status**: OPEN — MEDIUM

## Recent Sessions

### Session 584 (2026-03-17)
**Work**: Systematic debugging for BLOCKER-38 + BLOCKER-39 + proactive sync audit. Launched 2 deep research agents (found 10 additional sync issues). /writing-plans produced 6-phase plan. Adversarial review (code + security) found 2+2 CRITICAL, 5+4 HIGH findings — all fixed inline. Plan ready for /implement.
**Decisions**: ConflictResolver keeps Future<ConflictWinner> (query-based conflict count). Offline removal guard at service + UI layers. Migration uses DROP POLICY IF EXISTS defensively. fkColumnMap corrected for EntryPersonnelCountsAdapter.
**Next**: Commit S583 bugfixes. /implement sync hardening plan. Test on device.

### Session 583 (2026-03-17)
**Work**: Device testing session. Version bump to 0.1.1. Pushed Supabase migrations (already current). Built release + debug APKs. Set up VS Code launch config with DEBUG_SERVER. Fixed 8 bugs across auth, sync, and admin flows. Discovered root cause of all sync errors: version-upgrade forced signOutLocally() which wiped all local data, creating duplicate projects on re-sync. Fixed by adding forceReauthOnly() method. Also found draft project INSERT fires sync trigger (fixed with pulling=1 suppression). Reverted auto-enrollment of pulled projects (selective import is by design). Identified UX gap: pulled-but-unenrolled projects can't be imported.
**Decisions**: forceReauthOnly() preserves local data on upgrade. Draft INSERTs must suppress triggers. Auto-enrollment of pulled projects is WRONG — selective import is intentional. Debug builds (no clean) are ~13s vs ~6min for release.
**Next**: Commit fixes. Fix project import UX gap. RLS migration. Test admin dashboard.

### Session 582 (2026-03-16)
**Work**: /implement for project lifecycle (19 phases, 11 orchestrator launches, 0 handoffs). All reviews PASS. Committed 6 logical commits to app repo + 1 to config repo. ~140 files changed total.
**Decisions**: Merged PR2 phases (15-19) into single orchestrator launch for speed — worked without context exhaustion.
**Next**: Rebuild + test on device. Push Supabase migrations. Fix BLOCKER-22.

### Session 581 (2026-03-16)
**Work**: /writing-plans for project lifecycle. CodeMunch indexed 850 files/5469 symbols. Opus plan-writer produced 19-phase plan.
**Next**: /implement the plan.

### Session 580 (2026-03-16)
**Work**: Implemented pipeline UX overhaul (9 phases via /implement). Fixed 3 critical bugs. Built + installed APK on S25 Ultra. Brainstormed project lifecycle spec.
**Next**: /writing-plans for project lifecycle.

## Active Plans

### Sync Hardening & RLS Enforcement — PLAN READY (Session 584)
- **Plan**: `.claude/plans/2026-03-17-sync-hardening-and-rls.md`
- **Reviews**: `.claude/code-reviews/2026-03-17-sync-hardening-and-rls-plan-review.md`
- **Status**: Plan written, reviewed (code + security), all findings fixed inline. Ready for `/implement`.
- **Scope**: BLOCKER-38, BLOCKER-39, + 8 audit fixes. 6 phases, 10 commits, 8 modified files.

### Project Lifecycle Management — IMPLEMENTED + COMMITTED (Session 582)
- **Spec**: `.claude/specs/2026-03-16-project-lifecycle-spec.md`
- **Plan**: `.claude/plans/2026-03-16-project-lifecycle.md`
- **Status**: All 19 phases implemented. Needs device test after bugfixes.

### Pipeline UX Overhaul — IMPLEMENTED + COMMITTED (Session 582)
- **Spec**: `.claude/specs/2026-03-15-pipeline-ux-overhaul-spec.md`
- **Plan**: `.claude/plans/2026-03-16-pipeline-ux-overhaul.md`
- **Status**: All 9 phases complete. Needs device test.

## Reference
- **Project Lifecycle Spec**: `.claude/specs/2026-03-16-project-lifecycle-spec.md`
- **Pipeline UX Spec**: `.claude/specs/2026-03-15-pipeline-ux-overhaul-spec.md`
- **Defects**: `.claude/defects/_defects-pdf.md`, `_defects-sync.md`, `_defects-projects.md`
- **Debug build tag**: `v0.1.1-debug` on GitHub releases
- **Release build tag**: `v0.1.1` on GitHub releases
