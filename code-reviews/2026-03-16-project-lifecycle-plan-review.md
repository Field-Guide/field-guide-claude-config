# Plan Review: Project Lifecycle Management + Logger Migration

**Date**: 2026-03-16
**Plan**: `.claude/plans/2026-03-16-project-lifecycle.md`
**Spec**: `.claude/specs/2026-03-16-project-lifecycle-spec.md`

## Code Review — REJECT → FIXED

### Critical (3) — ALL FIXED
1. **Phase 10 tests were `expect(true, true)` TODOs** → Replaced with real widget tests (synced icons, remote cards, import tap, delete sheet)
2. **Phase 10 inline `DatabaseService()` bypasses DI** → Changed to `context.read<ProjectLifecycleService>()`, added ProxyProvider in Phase 13
3. **Phase 10 `_currentUserId`/`_isAdmin` unsourced** → Now sourced from `context.read<AuthProvider>()`

### High (6) — ALL FIXED
4. **Phase 12 wrong agent** → Changed to `frontend-flutter-specialist-agent`
5. **Phase 6 `_companyId` field missing** → Added as field, sourced from auth session `appMetadata['company_id']`
6. **Phase 16.2 wrong path `post_processor_v2.dart`** → Fixed to `stages/post_processor_v2.dart`
7. **Phase 16.2 wrong path `grid_line_remover.dart`** → Fixed to `stages/grid_line_remover.dart`
8. **Phase 16.3 `schema_verifier.dart` doesn't exist** → Removed, only exists inside `database_service.dart`
9. **Phase 15 `project_name` test contradiction** → Fixed assertion to `true`, matching spec

### Medium (5) — ALL FIXED
10. **Phase 11/12 tests were TODOs** → Real assertions: tile absence, switches disabled
11. **Phase 7 test tested raw SQL** → Rewrote to test actual `SoftDeleteService`
12. **ProjectDeleteSheet missing offline check** → Added `isOffline` param, disables checkbox
13. **No test for `isLocalOnly` error state** → Added red warning icon test
14. **Phase 13 no tests** → Added provider wiring smoke test

### Low (2) — ALL FIXED
15. **`MergedProjectEntry` placement unspecified** → Canonical path: `lib/features/projects/data/models/merged_project_entry.dart`
16. **bash `grep -r` violates CLAUDE.md** → Replaced with Grep tool / `pwsh -Command "rg ..."`

## Security Review — REJECT → FIXED

### High (2) — ALL FIXED
1. **`stamp_deleted_by()` column mismatch** → Removed function recreation from migration entirely. Existing function in `20260313100000` is correct.
2. **`isAdmin` caller-supplied with no source guidance** → Explicitly sourced from live auth session `context.read<AuthProvider>().isAdmin`

### Medium (2) — ALL FIXED
3. **Logger scrubbing test contradicts spec** → Fixed (same as code review #9)
4. **`_companyId` provenance unknown** → Fixed (same as code review #5)

### Low (2) — NOTED
5. **No offline gate at service layer for delete-from-database** → Acceptable: outcome is correct (queues for sync). Added note.
6. **Conflict_log cleanup edge case with FK inconsistency** → Pre-existing defect, no blocking change needed.

## Round 2 — Code Review: REJECT → FIXED

All 18 first-round fixes verified present.

### New findings (3 fixed, 4 LOW noted)
1. **[H] Phase 7 double `setUp`** → Merged into single `setUp` block with all table creation + service init
2. **[M] RLS `WITH CHECK` self-join bug** → Rewrote to simpler correct form: `(deleted_at IS NULL) OR (owner OR admin)`. Added doc comment about ELSE true branch.
3. **[M] Phase 7 `deletedBy:` vs `userId:` param mismatch** → Fixed to `userId:` matching existing signature
4. [L] Phase 6 test defines local `MergedProjectEntry` diverging from model — noted
5. [L] Phase 13 `ProxyProvider` async `database` getter — noted
6. [L] Phase 9 banner test `AnimatedContainer` assertion fragile — noted
7. [L] Phase 12 query param vs constructor param inconsistency — noted

## Round 2 — Security Review: APPROVE

All 4 first-round fixes verified present.

### New findings (noted, non-blocking)
1. [M] RLS `ELSE true` allows non-owner updates to non-delete fields — intentional pre-existing permission, documented in policy comment
2. [M] `project_name` scrubbing only works on `data:` maps, not message strings — current code doesn't log names in messages, but gap exists
3. [L] `fetchRemoteProjects()` no explicit auth session check — mitigated by provider scoping to auth routes
4. [L] `canDeleteFromDatabase` is UX-only gate — documented, RLS is hard enforcement

## Positive Observations
- Phases 1-5, 8-9, 14 well-structured with real TDD cycles
- ProjectLifecycleService thorough: batched cleanup, equipment cascade, photo paths
- RLS migration correctly handles NULL→non-NULL transition (fixed in round 2)
- PR1/PR2 boundary clean
- Backfill strategy correct
- No scope creep into targeted sync (future work honored)
- All first-round fixes landed correctly and cleanly
