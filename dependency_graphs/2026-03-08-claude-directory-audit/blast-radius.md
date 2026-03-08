# Blast Radius: .claude/ Directory Baseline Audit

**Branch**: `feat/sync-engine-rewrite`
**CodeMunch Index**: 646 files, 5237 symbols (2026-03-08)

## Blast Radius Summary

**Direct Changes**: ~163 `.claude/` files
**Codebase Files Scanned**: 411 lib/ files
**New Files Created**: 1 (audit-config skill)
**Deleted Files**: 0-1 (orphaned agent-memory dir if it exists)

---

## Current Codebase Structure (Reference for Agents)

### lib/features/ — 17 directories

| Feature | Has data/ | Has presentation/ | Has services/ | Key Models |
|---------|-----------|-------------------|---------------|------------|
| auth | Yes (local/remote split) | Yes (10 screens) | Yes (auth_service, password_validator) | UserProfile, Company, CompanyJoinRequest, UserRole |
| calculator | Yes | Yes | No | CalculationHistory |
| contractors | Yes (6 local, 4 remote DS) | Yes (3 providers, no screens) | No | Contractor, Equipment, PersonnelType, EntryEquipment, EntryPersonnel |
| dashboard | No | Yes (1 screen, 4 widgets) | No | N/A |
| entries | Yes (1 local, 1 remote DS) | Yes (5 controllers, 6 screens, 22 widgets) | No | DailyEntry |
| forms | Yes | Yes | No | InspectorForm, FormResponse |
| gallery | No | Yes | No | N/A |
| locations | Yes | Yes | No | Location |
| pdf | Yes (models only) | Yes (2 screens, helpers, widgets) | Yes (extraction pipeline, mp, ocr) | ParsedBidItem + extraction models |
| photos | Yes | Yes | No | Photo |
| projects | Yes (local/remote DS) | Yes (2 providers, 2 screens, 8 widgets) | No | Project, ProjectMode |
| quantities | Yes | Yes | No | BidItem, EntryQuantity |
| settings | No | Yes | No | N/A |
| sync | Yes + adapters/ + application/ + config/ + domain/ + engine/ | Yes (1 provider, 3 screens, 2 widgets) | No | SyncEngine, SyncOrchestrator, TableAdapter, ChangeTracker, etc. |
| todos | Yes | Yes | No | TodoItem |
| toolbox | No | Yes | No | N/A (hub for calculator/forms/gallery/todos) |
| weather | No | Yes | Yes (weather_service) | N/A |

### lib/core/ — 5 directories

| Directory | Key Files |
|-----------|-----------|
| config/ | supabase_config.dart, app_terminology.dart, config_validator.dart, test_mode_config.dart |
| database/ | database_service.dart, schema_verifier.dart, schema/*.dart (10 table files) |
| logging/ | app_logger.dart, debug_logger.dart, app_route_observer.dart |
| router/ | app_router.dart |
| theme/ | app_theme.dart, colors.dart, design_constants.dart |

### lib/shared/ — 8 directories

| Directory | Key Files |
|-----------|-----------|
| datasources/ | base_local_datasource.dart, base_remote_datasource.dart, generic_local_datasource.dart, project_scoped_datasource.dart, query_mixins.dart |
| models/ | paged_result.dart |
| providers/ | base_list_provider.dart, paged_list_provider.dart |
| repositories/ | base_repository.dart |
| services/ | preferences_service.dart |
| testing_keys/ | testing_keys.dart + 11 feature-specific key files |
| utils/ | date_utils, enum_utils, field_formatter, math_utils, natural_sort, navigation_utils, snackbar_helper, string_utils, validators |
| validation/ | unique_name_validator.dart |
| widgets/ | confirmation_dialog, contextual_feedback_overlay, empty_state_widget, permission_dialog, search_bar_field, stale_config_warning, version_banner, view_only_banner |

### lib/services/ — 5 files
photo_service.dart, image_service.dart, permission_service.dart, soft_delete_service.dart, startup_cleanup_service.dart

---

## Known Changes Since Feb 13 (Docs Last Updated)

### Major Changes
1. **Sync engine rewrite** — Entirely new architecture: `engine/`, `adapters/`, `application/`, `domain/`, `config/` directories. Old `sync_service.dart` replaced by `SyncEngine`, `SyncOrchestrator`, `TableAdapter` pattern, `ChangeTracker`, `ConflictResolver`, `IntegrityChecker`.
2. **Entry personnel removal** — `entry_personnel` system removed from DB schema (commit 8551571), but `contractors/data/models/entry_personnel.dart` still exists on disk.
3. **Provider/screen updates** — Providers and screens refactored for sync engine compatibility (commit ad486c0).
4. **Schema alignment** — Database schema tables reorganized (commit 8551571).
5. **Legacy PII migration removed** — Stale references to PII migration code (commit 3676de8).
6. **Deprecated tests purged** — Old test files removed (commit 1341d86).

### Feature-Specific Changes to Investigate
- **sync**: Completely rewritten — docs are entirely stale
- **entries**: entry_personnel removed, controllers added
- **contractors**: entry_personnel_counts replaces old entry_personnel system
- **dashboard**: project_dashboard_screen.dart (verify if new)
- **pdf**: extraction pipeline may have evolved
- **auth**: user_attribution_repository.dart (possibly new)
- **projects**: project_mode.dart, project_settings_provider.dart (possibly new)

---

## .claude/ Files In Scope Per Agent

### Agent #1: Feature Docs A (10 files)
- docs/features/feature-auth-overview.md
- docs/features/feature-auth-architecture.md
- docs/features/feature-contractors-overview.md
- docs/features/feature-contractors-architecture.md
- docs/features/feature-dashboard-overview.md
- docs/features/feature-dashboard-architecture.md
- docs/features/feature-entries-overview.md
- docs/features/feature-entries-architecture.md
- docs/features/feature-locations-overview.md
- docs/features/feature-locations-architecture.md

### Agent #2: Feature Docs B (10 files)
- docs/features/feature-pdf-overview.md
- docs/features/feature-pdf-architecture.md
- docs/features/feature-photos-overview.md
- docs/features/feature-photos-architecture.md
- docs/features/feature-projects-overview.md
- docs/features/feature-projects-architecture.md
- docs/features/feature-quantities-overview.md
- docs/features/feature-quantities-architecture.md
- docs/features/feature-settings-overview.md
- docs/features/feature-settings-architecture.md

### Agent #3: Feature Docs C (7 files)
- docs/features/feature-sync-overview.md
- docs/features/feature-sync-architecture.md
- docs/features/feature-toolbox-overview.md
- docs/features/feature-toolbox-architecture.md
- docs/features/feature-weather-overview.md
- docs/features/feature-weather-architecture.md
- docs/features/README.md

### Agent #4: PRDs (14 files)
- prds/auth-prd.md
- prds/contractors-prd.md
- prds/dashboard-prd.md
- prds/entries-prd.md
- prds/locations-prd.md
- prds/photos-prd.md
- prds/projects-prd.md
- prds/quantities-prd.md
- prds/settings-prd.md
- prds/sync-prd.md
- prds/weather-prd.md
- prds/toolbox-prd.md
- prds/pdf-extraction-v2-prd-2.0.md
- prds/2026-02-21-project-based-architecture-prd.md

### Agent #5: Arch-Decisions (15 files)
- architecture-decisions/auth-constraints.md
- architecture-decisions/contractors-constraints.md
- architecture-decisions/dashboard-constraints.md
- architecture-decisions/entries-constraints.md
- architecture-decisions/locations-constraints.md
- architecture-decisions/photos-constraints.md
- architecture-decisions/projects-constraints.md
- architecture-decisions/quantities-constraints.md
- architecture-decisions/settings-constraints.md
- architecture-decisions/sync-constraints.md
- architecture-decisions/weather-constraints.md
- architecture-decisions/toolbox-constraints.md
- architecture-decisions/pdf-v2-constraints.md
- architecture-decisions/data-validation-rules.md
- (any other constraint files found)

### Agent #6: Agents + Memories (19 files)
- agents/auth-agent.md
- agents/backend-data-layer-agent.md
- agents/backend-supabase-agent.md
- agents/code-review-agent.md
- agents/frontend-flutter-specialist-agent.md
- agents/pdf-agent.md
- agents/qa-testing-agent.md
- agents/security-agent.md
- agents/test-wave-agent.md
- agent-memory/auth-agent/MEMORY.md
- agent-memory/backend-data-layer-agent/MEMORY.md
- agent-memory/backend-supabase-agent/MEMORY.md
- agent-memory/code-review-agent/MEMORY.md
- agent-memory/frontend-flutter-specialist-agent/MEMORY.md
- agent-memory/pdf-agent/MEMORY.md
- agent-memory/pdf-agent/stage-4c-implementation.md
- agent-memory/qa-testing-agent/MEMORY.md
- agent-memory/security-agent/MEMORY.md
- (verify if agent-memory/test-orchestrator-agent/ exists — delete if orphaned)

### Agent #7: Rules (9 files)
- rules/architecture.md
- rules/platform-standards.md
- rules/auth/supabase-auth.md
- rules/backend/data-layer.md
- rules/backend/supabase-sql.md
- rules/database/schema-patterns.md
- rules/frontend/flutter-ui.md
- rules/frontend/ui-prototyping.md
- rules/pdf/pdf-generation.md
- rules/sync/sync-patterns.md
- rules/testing/patrol-testing.md

### Agent #8: State JSONs (17 files)
- state/feature-auth.json
- state/feature-contractors.json
- state/feature-dashboard.json
- state/feature-entries.json
- state/feature-locations.json
- state/feature-pdf.json
- state/feature-photos.json
- state/feature-projects.json
- state/feature-quantities.json
- state/feature-settings.json
- state/feature-sync.json
- state/feature-toolbox.json
- state/feature-weather.json
- state/AGENT-CHECKLIST.json
- state/AGENT-FEATURE-MAPPING.json
- state/FEATURE-MATRIX.json
- state/PROJECT-STATE.json

### Agent #9: Skills + Audit Skill (9 existing + new)
- skills/brainstorming/SKILL.md (+ references/)
- skills/end-session/SKILL.md
- skills/implement/SKILL.md
- skills/interface-design/SKILL.md (+ references/)
- skills/pdf-processing/SKILL.md (+ references/ + scripts/)
- skills/resume-session/SKILL.md
- skills/systematic-debugging/SKILL.md (+ references/)
- skills/test/SKILL.md (+ references/)
- skills/writing-plans/SKILL.md
- NEW: skills/audit-config/SKILL.md

### Agent #10: CLAUDE.md + Misc Config (~17 files)
- CLAUDE.md (SINGLE OWNER)
- docs/INDEX.md
- docs/2026-03-06-ui-refactor-decisions.md
- docs/ui-audit-theme-tokens-2026-03-06.md
- docs/ui-dependency-map.md
- docs/ui-refactor-reference-2026-03-06.md
- docs/pdf-pipeline-performance-audit.md
- docs/guides/README.md
- docs/guides/ui-prototyping-workflow.md
- docs/guides/implementation/chunked-sync-usage.md
- docs/guides/implementation/pagination-widgets-guide.md
- docs/guides/testing/manual-testing-checklist.md
- docs/guides/testing/e2e-test-setup.md
- hooks/post-agent-coding.sh
- hooks/pre-agent-dispatch.sh
- autoload/_state.md
- memory/MEMORY.md

### Agent #11: Defects (~15 files, PATH FIXES ONLY)
- defects/_defects-auth.md
- defects/_defects-contractors.md
- defects/_defects-dashboard.md
- defects/_defects-database.md
- defects/_defects-entries.md
- defects/_defects-forms.md
- defects/_defects-locations.md
- defects/_defects-pdf.md
- defects/_defects-photos.md
- defects/_defects-projects.md
- defects/_defects-quantities.md
- defects/_defects-settings.md
- defects/_defects-sync.md
- defects/_defects-toolbox.md
- defects/_defects-weather.md
