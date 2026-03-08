# .claude/ Audit Report -- 2026-03-08

**Branch**: `feat/sync-engine-rewrite`
**Commit**: `ad486c0f72ea0550d1e37ea79606f1c25a3ebaf8`
**Scanned**: ~163 .claude/ files against 646 codebase files (5237 symbols)

---

## Summary

- **Broken file paths**: 24 unique broken paths across in-scope files
- **Stale content areas**: 3 major (sync_service.dart removal, entry_personnel system, toolbox sub-feature paths)
- **Orphaned config files**: 1 (empty `agent-memory/test-orchestrator-agent/` directory)
- **Missing from CLAUDE.md**: 2 items (test-wave-agent, test skill)
- **New skill to create**: 1 (audit-config)
- **Security invariants**: Pre-check PASS (will verify post-fix in Phase 4)

---

## 1. Codebase Snapshot

### Branch & Commit
- Branch: `feat/sync-engine-rewrite`
- Commit: `ad486c0f72ea0550d1e37ea79606f1c25a3ebaf8`
- CodeMunch index: 646 files, 5237 symbols

### Feature Directories (17)
auth, calculator, contractors, dashboard, entries, forms, gallery, locations, pdf, photos, projects, quantities, settings, sync, todos, toolbox, weather

### Core Directories (5)
config/, database/, logging/, router/, theme/

### Shared Directories (10)
datasources/, models/, providers/, repositories/, services/, testing_keys/, utils/, validation/, widgets/, time_provider.dart

### Services (5 files)
image_service.dart, permission_service.dart, photo_service.dart, soft_delete_service.dart, startup_cleanup_service.dart

**NOTE**: `lib/services/sync_service.dart` has been DELETED on this branch.

### Database Schema (10 table files)
contractor_tables.dart, core_tables.dart, entry_tables.dart, extraction_tables.dart, personnel_tables.dart, photo_tables.dart, quantity_tables.dart, sync_engine_tables.dart, sync_tables.dart, toolbox_tables.dart

### Sync Feature -- New Architecture [BRANCH: feat/sync-engine-rewrite]
```
lib/features/sync/
  adapters/     (17 table adapters + table_adapter.dart + type_converters.dart)
  application/  (background_sync_handler.dart, sync_orchestrator.dart)
  config/       (sync_config.dart)
  data/         (adapters/mock_sync_adapter.dart, supabase_sync_adapter.dart)
  domain/       (sync_adapter.dart, sync_types.dart)
  engine/       (change_tracker.dart, conflict_resolver.dart, integrity_checker.dart,
                 orphan_scanner.dart, scope_type.dart, storage_cleanup.dart,
                 sync_engine.dart, sync_mutex.dart, sync_registry.dart)
  presentation/ (providers/sync_provider.dart, screens/conflict_viewer_screen.dart,
                 sync_dashboard_screen.dart, project_selection_screen.dart,
                 widgets/deletion_notification_banner.dart, sync_status_banner.dart,
                 sync_status_icon.dart)
```

---

## 2. Broken File Path References

### Confirmed Broken Paths (files that DO NOT exist on disk)

| Broken Path | Referenced In (in-scope) | Correct Path / Note |
|-------------|--------------------------|---------------------|
| `lib/core/theme/spacing.dart` | skills/interface-design/references/flutter-tokens.md | File does not exist; use `lib/core/theme/design_constants.dart` |
| `lib/features/entries/presentation/screens/entry_wizard_screen.dart` | (entries docs/PRDs) | File does not exist; was likely renamed or merged into `entry_editor_screen.dart` |
| `lib/features/entries/presentation/screens/report_screen.dart` | (entries docs) | File does not exist; check if renamed |
| `lib/features/pdf/services/extraction/scoring/field_confidence_scorer.dart` | (pdf docs) | Moved to `stages/field_confidence_scorer.dart` |
| `lib/features/pdf/services/extraction/stages/structure_preserver.dart` | (pdf docs) | File does not exist on disk |
| `lib/features/settings/presentation/widgets/inspector_profile_section.dart` | (settings docs) | File does not exist; was likely refactored |
| `lib/features/toolbox/data/models/calculation_history.dart` | (toolbox docs) | Actual: `lib/features/calculator/data/models/calculation_history.dart` |
| `lib/features/toolbox/data/models/form_response.dart` | (toolbox docs) | Actual: `lib/features/forms/data/models/form_response.dart` |
| `lib/features/toolbox/data/models/inspector_form.dart` | (toolbox docs) | Actual: `lib/features/forms/data/models/inspector_form.dart` |
| `lib/features/toolbox/data/models/todo_item.dart` | (toolbox docs) | Actual: `lib/features/todos/data/models/todo_item.dart` |
| `lib/features/toolbox/data/repositories/form_response_repository.dart` | (toolbox docs) | Actual: `lib/features/forms/data/repositories/form_response_repository.dart` |
| `lib/features/toolbox/data/repositories/inspector_form_repository.dart` | (toolbox docs) | Not found; check forms feature |
| `lib/features/toolbox/data/services/calculator_service.dart` | (toolbox docs) | File does not exist |
| `lib/features/toolbox/data/services/form_parsing_service.dart` | (toolbox docs) | File does not exist |
| `lib/features/toolbox/presentation/providers/calculator_provider.dart` | (toolbox docs) | Actual: `lib/features/calculator/presentation/providers/calculator_provider.dart` |
| `lib/features/toolbox/presentation/providers/inspector_form_provider.dart` | (toolbox docs) | Actual: `lib/features/forms/presentation/providers/inspector_form_provider.dart` |
| `lib/features/toolbox/presentation/providers/todo_provider.dart` | (toolbox docs) | Actual: `lib/features/todos/presentation/providers/todo_provider.dart` |
| `lib/features/toolbox/presentation/screens/calculator_screen.dart` | (toolbox docs) | Actual: `lib/features/calculator/presentation/screens/calculator_screen.dart` |
| `lib/features/toolbox/presentation/screens/form_fill_screen.dart` | (toolbox docs) | Actual: `lib/features/forms/presentation/screens/form_fill_screen.dart` |
| `lib/features/toolbox/presentation/screens/form_viewer_screen.dart` | (toolbox docs) | Actual: `lib/features/forms/presentation/screens/form_viewer_screen.dart` |
| `lib/features/toolbox/presentation/screens/forms_list_screen.dart` | (toolbox docs) | Actual: `lib/features/forms/presentation/screens/forms_list_screen.dart` |
| `lib/features/toolbox/presentation/screens/gallery_screen.dart` | (toolbox docs) | Actual: `lib/features/gallery/presentation/screens/gallery_screen.dart` (verify) |
| `lib/services/database_service.dart` | rules/backend/data-layer.md (already noted as non-existent) | Correct: `lib/core/database/database_service.dart` |
| `lib/services/sync_service.dart` | Multiple: sync docs, rules, agent-memory, guides | DELETED on this branch. Replaced by sync engine architecture. |

### Files In-Scope with Broken References

**Feature Docs (docs/features/)**:
- `feature-sync-overview.md` -- references `lib/services/sync_service.dart` (deleted)
- `feature-sync-architecture.md` -- references `lib/services/sync_service.dart`, old sync architecture
- `feature-toolbox-overview.md` -- references `lib/features/toolbox/data/*` paths (wrong; sub-features are in separate dirs)
- `feature-toolbox-architecture.md` -- same toolbox path issues
- `feature-entries-overview.md` / `feature-entries-architecture.md` -- may reference entry_wizard_screen, report_screen
- `feature-settings-architecture.md` -- may reference inspector_profile_section.dart

**Rules**:
- `rules/sync/sync-patterns.md` -- references `lib/services/sync_service.dart` (deleted) and old sync architecture
- `rules/backend/data-layer.md` -- already notes `lib/services/database_service.dart` does NOT exist (self-aware)

**Agent Files**:
- `agents/security-agent.md` -- references `sync_service.dart`, `entry_personnel` table

**Agent Memory**:
- `agent-memory/code-review-agent/MEMORY.md` -- references `lib/services/sync_service.dart`

**Guides**:
- `docs/guides/implementation/chunked-sync-usage.md` -- references `lib/services/sync_service.dart`, old sync patterns

**Skills**:
- `skills/interface-design/references/flutter-tokens.md` -- references `lib/core/theme/spacing.dart` (doesn't exist)

---

## 3. Stale Content

### 3.1 sync_service.dart Removal
`lib/services/sync_service.dart` has been deleted on `feat/sync-engine-rewrite`. All references to this file are stale. The sync feature now uses:
- `lib/features/sync/engine/sync_engine.dart` (core engine)
- `lib/features/sync/application/sync_orchestrator.dart` (orchestration)
- `lib/features/sync/adapters/table_adapter.dart` (base adapter, 17 concrete adapters)
- `lib/features/sync/engine/change_tracker.dart`, `conflict_resolver.dart`, `integrity_checker.dart`, `sync_mutex.dart`, `sync_registry.dart`

**Affected in-scope files**: feature-sync-overview.md, feature-sync-architecture.md, rules/sync/sync-patterns.md, agents/security-agent.md, agent-memory/code-review-agent/MEMORY.md, docs/guides/implementation/chunked-sync-usage.md

### 3.2 entry_personnel System
The `entry_personnel` table schema was removed in commit `8551571`. However, `lib/features/contractors/data/datasources/local/entry_personnel_local_datasource.dart` still exists on disk (manages both legacy entry_personnel AND active entry_personnel_counts). The `entry_personnel_counts` system is active and has a sync adapter.

**Affected in-scope files**: prds/contractors-prd.md, prds/entries-prd.md, agents/security-agent.md (multi-tenant table list)

### 3.3 Toolbox Sub-Feature Paths
Docs reference `lib/features/toolbox/data/models/*` but the actual model files live in their respective sub-feature directories:
- `calculator/data/models/`, `forms/data/models/`, `todos/data/models/`

**Affected**: feature-toolbox-overview.md, feature-toolbox-architecture.md, toolbox-prd.md, toolbox-constraints.md, feature-toolbox.json

---

## 4. Orphaned Files

| Item | Type | Status |
|------|------|--------|
| `agent-memory/test-orchestrator-agent/` | Empty directory | Orphaned -- no matching agent file. Delete. |
| `test-wave-agent` | Agent file exists | NOT in CLAUDE.md agent table. Add or document. |
| `test` skill | Skill file exists | NOT in CLAUDE.md skills table. Add. |

---

## 5. Cross-Reference Map

### CLAUDE.md References
- Agent table references 8 agents; actual agents/ dir has 9 (missing `test-wave-agent`)
- Skills table references 8 skills; actual skills/ dir has 9 (missing `test`)
- Feature count: "17 features" in project structure (includes sub-features as directories)

### Feature Docs -> Architecture Decisions
Each feature-{name}-overview.md typically references architecture-decisions/{name}-constraints.md

### State JSONs -> Feature Docs
Each feature-{name}.json references docs/features/feature-{name}-overview.md and architecture-decisions/{name}-constraints.md

### Agent Files -> Rules
Agent files reference rule files via `@` references (e.g., `@.claude/rules/architecture.md`)

### Guides -> Source Code
guides/implementation/chunked-sync-usage.md references sync code (stale)
guides/testing/e2e-test-setup.md references test harness code

---

## 6. Branch-Only Files

The following files exist on `feat/sync-engine-rewrite` but NOT on `main`. Any .claude/ references to these should be tagged `[BRANCH: feat/sync-engine-rewrite]`:

### Sync Engine (entirely new)
- All files in `lib/features/sync/adapters/` (17 adapters + base + type_converters)
- `lib/features/sync/application/background_sync_handler.dart`
- `lib/features/sync/application/sync_orchestrator.dart`
- `lib/features/sync/config/sync_config.dart`
- `lib/features/sync/data/adapters/` (mock + supabase)
- `lib/features/sync/domain/` (sync_adapter.dart, sync_types.dart)
- `lib/features/sync/engine/` (8 files: change_tracker, conflict_resolver, integrity_checker, orphan_scanner, scope_type, storage_cleanup, sync_engine, sync_mutex, sync_registry)
- `lib/features/sync/presentation/` (provider, 3 screens, 3 widgets)

### Modified on branch (changed since diverging from main)
- Database schema files (database_service.dart, several schema/*.dart)
- Multiple feature datasources, repositories, providers, screens (see git diff above)
- `lib/services/sync_service.dart` -- DELETED
- `lib/main.dart` -- modified

---

## Top 10 Most-Affected Files (by broken reference count)

1. `docs/features/feature-toolbox-overview.md` / `feature-toolbox-architecture.md` -- ~15 broken toolbox/data paths
2. `docs/features/feature-sync-overview.md` / `feature-sync-architecture.md` -- sync_service.dart + old architecture
3. `rules/sync/sync-patterns.md` -- sync_service.dart + old patterns
4. `docs/guides/implementation/chunked-sync-usage.md` -- sync_service.dart + old usage
5. `agents/security-agent.md` -- sync_service.dart, entry_personnel table
6. `agent-memory/code-review-agent/MEMORY.md` -- sync_service.dart
7. `state/feature-sync.json` -- likely stale sync file inventory
8. `state/feature-toolbox.json` -- likely stale toolbox file paths
9. `prds/sync-prd.md` -- old sync architecture references
10. `prds/toolbox-prd.md` -- toolbox sub-feature path references
