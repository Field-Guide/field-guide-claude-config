# Blast Radius

## Summary

| Category | Count |
|----------|-------|
| Files created | 1 |
| Files deleted | 19 (18 defect files + 1 workflow) |
| Files updated | 18 |
| Dart code changes | 0 |
| Total files affected | 38 |

## Impact by Phase

### Phase 1: Setup (low risk)
- **Create**: `tools/create-defect-issue.ps1` — new file, no existing dependencies
- **Create**: GitHub labels — additive only, no existing label conflicts except `defect` (already exists from sync-defects.yml)

### Phase 2: Migration (medium risk)
- **Audit**: 17 defect files — manual review, no code changes
- **Create**: GitHub Issues — additive only
- **Update**: `.claude/autoload/_state.md` — blocker format change (append issue numbers)
- **Write**: `.claude/logs/defects-archive.md` — append migrated entries

### Phase 3: Writer Updates (medium risk)
- 6 files modified (3 skills + 3 agents)
- Risk: If script path or params are wrong, defect filing silently fails
- Mitigation: Test script manually before updating callers

### Phase 4: Reader Simplifications (low risk)
- 9 files modified (6 agents + 2 skills + 1 rule)
- All changes are REMOVALS — delete lines referencing defect files
- Risk: Nearly zero. Removing context loading that is being eliminated.

### Phase 5: Cleanup (medium risk)
- **Delete**: `.claude/defects/` directory — irreversible after archive step
- **Delete**: `.github/workflows/sync-defects.yml` — stop CI sync
- **Update**: `.claude/CLAUDE.md` — 2 line changes
- Mitigation: Phase 2 archives everything before Phase 5 deletes

## Dead Code Targets

After migration completes, these become dead:
- `.claude/defects/` — entire directory (18 files)
- `.github/workflows/sync-defects.yml` — entire workflow
- References to `defects-archive.md` in agents that read it (qa-testing, code-review) — archive still exists as historical record but no longer actively written to

## No Dart Code Impact

No Dart files are modified. BLOCKER- references in `sync_engine.dart`, `sync_engine_test.dart`, `sync_engine_e2e_test.dart`, and `no_skip_without_issue_ref.dart` are historical documentation comments and test names — they remain valid regardless of where blocker tracking lives.
