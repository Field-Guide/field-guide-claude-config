# Dependency Graph: Workflow Improvements

**Date**: 2026-03-22
**Spec**: `.claude/specs/2026-03-22-workflow-improvements-spec.md`

---

## Direct Changes

### Category 1: Config Remediation (.claude/ files only)

| File | Change Type | Lines |
|------|------------|-------|
| `.claude/.gitignore` | ADD patterns | `test_results/`, `autoload/_state.md`, `state/*.json` |
| `.claude/agents/implement-orchestrator.md:89` | EDIT | `haiku` → `sonnet` |
| `.claude/CLAUDE.md` | EDIT | "9 definitions" → "10 definitions" in Pointers table |
| `.claude/docs/INDEX.md:14,111` | EDIT | "13 features" → "17 features" |
| `.claude/docs/guides/README.md:49` | EDIT | "13 features" → "17 features" |
| `.claude/docs/features/README.md:3` | EDIT | "13 features" → "17 features" |
| `.claude/state/AGENT-FEATURE-MAPPING.json:234` | EDIT | "9 of 13 features" → correct count |
| `.claude/docs/directory-reference.md:9` | EDIT | "9 agents" → "10 agents" |
| `.claude/rules/pdf/pdf-generation.md:180,201,206` | EDIT | `debugPrint` → `Logger.pdf()` |
| `.claude/rules/database/schema-patterns.md:201,205,211` | EDIT | `debugPrint` → `Logger.db()` |
| `.claude/rules/frontend/flutter-ui.md:12-15,107` | EDIT | bare flutter → `pwsh -Command`, `debugPrint` → `Logger.ui()` |
| `.claude/rules/auth/supabase-auth.md:152,159,161` | EDIT | `debugPrint` → `Logger.auth()` |
| `.claude/rules/backend/data-layer.md:12-14,250` | EDIT | bare flutter → `pwsh -Command`, `debugPrint` → `Logger.db()` |
| `.claude/rules/platform-standards.md:194,231,236` | EDIT | bare flutter → `pwsh -Command` (lower priority — example blocks) |

### Category 2: Stale Defect Resolution (.claude/ files only)

| File | Change Type | Lines |
|------|------------|-------|
| `.claude/defects/_defects-auth.md:35-38` | EDIT | Wrap in RESOLVED comment |
| `.claude/defects/_defects-projects.md:49-53` | EDIT | Wrap in RESOLVED comment |
| `lib/features/projects/data/datasources/local/project_local_datasource.dart:112` | EDIT | Remove stale "PRAGMA foreign_keys is never enabled" comment |
| `lib/features/projects/data/repositories/project_repository.dart:152` | EDIT | Remove stale "PRAGMA foreign_keys is never enabled" comment |

### Category 3: Constraint Reconciliation (.claude/ files only, except V5)

| File | Change Type | Details |
|------|------------|---------|
| `.claude/architecture-decisions/sync-constraints.md:6` | EDIT | "SHA256" → "hash-based change detection (djb2)" |
| `.claude/architecture-decisions/sync-constraints.md:8` | EDIT | "max 3 attempts" → "max 5 attempts" + document engine vs orchestrator |
| `.claude/architecture-decisions/toolbox-constraints.md:34-37` | EDIT | Remove "No persistence" hard rule, document actual 4-table persistence |
| `.claude/architecture-decisions/entries-constraints.md:20-21` | EDIT | Allow SUBMITTED→DRAFT reversal, document undoSubmission() |

### Category 4: V5 — Raw SQL to Repository (Dart code change)

**Direct files:**
| File | Change Type | Lines |
|------|------------|-------|
| `lib/features/projects/presentation/screens/project_setup_screen.dart:118-127` | REMOVE | `_initEagerDraft()` raw SQL — move to repository |
| `lib/features/projects/presentation/screens/project_setup_screen.dart:355-378` | REMOVE | `_discardDraft()` raw SQL — move to repository |
| `lib/features/projects/data/repositories/project_repository.dart` | ADD | `saveDraftSuppressed()` and `discardDraft()` methods |
| `lib/features/projects/presentation/providers/project_provider.dart` | ADD | `saveDraftSuppressed()` and `discardDraft()` proxy methods |

**Dependent files (callers of project_setup_screen methods):**
- None — `_initEagerDraft()` and `_discardDraft()` are private methods only called within the screen itself.

**Data flow:**
```
CURRENT (violation):
  project_setup_screen.dart → db.execute("UPDATE sync_control...") → SQLite

AFTER FIX:
  project_setup_screen.dart → ProjectProvider.saveDraftSuppressed() → ProjectRepository.saveDraftSuppressed() → SQLite
  project_setup_screen.dart → ProjectProvider.discardDraft() → ProjectRepository.discardDraft() → SQLite
```

### Category 5: Anti-Pattern Fixes (Dart code)

**`.firstWhere` without safety — 8 instances, all in PDF extraction models:**
| File | Line | Pattern |
|------|------|---------|
| `lib/features/pdf/services/extraction/models/classified_rows.dart` | 71 | `RowType.values.firstWhere` |
| `lib/features/pdf/services/extraction/models/classified_rows.dart` | 148 | `RowType.values.firstWhere` |
| `lib/features/pdf/services/extraction/models/classified_rows.dart` | 314 | `RowType.values.firstWhere` |
| `lib/features/pdf/services/extraction/models/document_checksum.dart` | 165 | `ChecksumStatus.values.firstWhere` |
| `lib/features/pdf/services/extraction/models/ocr_element.dart` | 74 | `CoordinateSystem.values.firstWhere` |
| `lib/features/pdf/services/extraction/models/processed_items.dart` | 78 | `RepairType.values.firstWhere` |
| `lib/features/pdf/services/extraction/models/quality_report.dart` | 103 | `QualityStatus.values.firstWhere` |
| `lib/features/pdf/services/extraction/models/quality_report.dart` | 110 | `ReExtractionStrategy.values.firstWhere` |

**Fix pattern:** Replace with `.firstWhereOrNull((e) => e.name == value) ?? EnumType.defaultValue` or try/catch `byName()`.

**`catch (_)` silent swallowing — 92 instances across 30+ files:**
Updated count from original 55 to 92 (includes `catch(e)` where `e` is never used). Must be fixed case-by-case:
- Logger internals (9 instances): KEEP — intentional, logging can't log its own failures
- Test driver (7 instances): KEEP — test infrastructure, acceptable
- ProcessInfo.currentRss (5 instances): KEEP — optional memory stat
- Table-may-not-exist guards (4 instances in soft_delete_service): KEEP — intentional
- sync_mutex.dart (1 instance): KEEP — INSERT conflict = lock held, by design
- **Auth providers (6 instances)**: FIX — production auth errors must be logged
- **Entry providers (3 instances)**: FIX — entry operations silently failing
- **Sync dashboard/conflict screens (3 instances)**: FIX — load errors invisible
- **Photo remote datasource (2 instances)**: FIX — storage failures invisible
- **Image service (3 instances)**: FIX — image operations silently returning null
- **Theme/calendar providers (4 instances)**: FIX — preference failures invisible
- **JSON decode fallbacks (9+ instances in forms/models)**: REVIEW — may be intentional for schema migration
- **Other (remaining)**: REVIEW case-by-case

**Estimated fixable instances: ~30-40 (add Logger.error() or Logger.* category)**
**Estimated keep-as-is: ~50-55 (intentional suppression)**

### Category 6: Skill Updates (.claude/ files only)

| File | Change Type |
|------|------------|
| `.claude/skills/brainstorming/skill.md` | EDIT — remove adversarial review sections (lines 157-270) |
| `.claude/skills/writing-plans/skill.md` | EDIT — add spec-as-source-of-truth language |
| `.claude/skills/spike/skill.md` | CREATE — new skill |

### Category 7: Pre-Commit Hooks

| File | Change Type |
|------|------------|
| `.claude/hooks/pre-commit.ps1` | CREATE — tiered pre-commit hook |

### Category 8: Agent Memory Population

| File | Change Type |
|------|------------|
| `.claude/agents/backend-supabase-agent.memory.md` | EDIT — populate from codebase patterns |
| `.claude/agents/auth-agent.memory.md` | EDIT — populate from codebase patterns |
| `.claude/agents/backend-data-layer-agent.memory.md` | EDIT — populate from codebase patterns |

### Category 9: Anti-Pattern Table Update (architecture.md)

Current anti-patterns in `rules/architecture.md:121-131`:
```
| setState() in dispose() | Widget already deactivated | Use WidgetsBindingObserver lifecycle |
| Provider.of(context) after async | Context may be invalid | Check mounted first |
| Hardcoded colors | Inconsistent theming | Use AppTheme.* constants |
| Skip barrel exports | Breaks imports | Update models.dart, providers.dart |
| firstWhere without orElse | Throws on empty | Use .where(...).firstOrNull |
| Save in dispose() | Context deactivated | Use WidgetsBindingObserver.didChangeAppLifecycleState |
| .first on empty list | Throws exception | Check .isEmpty or use .firstOrNull |
```

**Additions needed (from current codebase audit):**
- `catch (_)` without logging — Hides errors, makes debugging impossible → Add `Logger.error()` or rethrow
- `debugPrint` in production code — Not captured by Logger system → Use `Logger.*()` category methods
- Raw SQL in presentation layer — Violates separation of concerns → Use repository pattern
- `db.delete()` without soft-delete check — May bypass trash system → Use `SoftDeleteService`

---

## Blast Radius Summary

| Category | Direct | Dependent | Test | Cleanup |
|----------|--------|-----------|------|---------|
| Config remediation | 14 .claude/ files | 0 | 0 | 0 |
| Stale defects | 2 .claude/ files, 2 .dart files | 0 | 0 | 0 |
| Constraint docs | 4 .claude/ files | 0 | 0 | 0 |
| V5 raw SQL fix | 3 .dart files | 0 | 1 (new test) | 0 |
| firstWhere fix | 5 .dart files | 0 | 0 | 0 |
| catch(_) fix | ~20 .dart files | 0 | 0 | 0 |
| Skill updates | 2 .claude/ files + 1 new | 0 | 0 | 0 |
| Pre-commit hook | 1 new .ps1 file | 0 | 0 | 0 |
| Agent memories | 3 .claude/ files | 0 | 0 | 0 |
| Anti-pattern table | 1 .claude/ file | 0 | 0 | 0 |
| **Total** | **~50 files** | **0** | **1** | **0** |

Note: This is an unusually low-risk spec — most changes are config/doc updates with zero code dependencies. The only production code changes are V5 (3 files, self-contained) and anti-pattern fixes (mechanical, per-file).
