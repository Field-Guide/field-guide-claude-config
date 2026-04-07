# Session State

**Last Updated**: 2026-04-07
**Branch**: `sync-engine-refactor`
**Status**: UI design-system refactor is merged, and `sync-engine-refactor` is active again to absorb that UI baseline before sync refactor work continues.

## Current State

- PR `#249` merged the UI design-system refactor, including the 300-line presentation ceiling enforced by `scripts/audit_ui_file_sizes.ps1`.
- Sync-driving UI now has explicit contracts through:
  - `lib/core/driver/screen_registry.dart`
  - `lib/core/driver/screen_contract_registry.dart`
  - `lib/core/driver/flow_registry.dart`
  - `lib/core/driver/driver_diagnostics_handler.dart`
- `/diagnostics/screen_contract` is the unified sync-facing UI inspection endpoint.
- Screen-local controller composition now lives in `di/*screen_providers.dart` files across auth, entries, forms, projects, quantities, settings, dashboard, pay applications, and similar refactored features.
- CI now enforces sync adapter drift with `scripts/validate_sync_adapter_registry.py` against `sync_engine_tables.dart`, `simple_adapters.dart`, and `sync_registry.dart`.
- Local workspace is back on `sync-engine-refactor`; the only remaining local noise is untracked `.lint_filtered.txt` and `.lint_out.txt`.

## Quality Gates

- `flutter analyze` must stay clean.
- `dart run custom_lint` must stay clean.
- `scripts/audit_ui_file_sizes.ps1` must stay green.
- `python scripts/validate_sync_adapter_registry.py` must stay green.
- No ignore comments, analyzer excludes, or severity downgrades are permitted to bypass the lint gates.

## New Architecture Enforcement

Custom lint now explicitly enforces:
- `max_ui_callable_length`
- `max_ui_file_length`
- `screen_registry_contract_sync`

Existing rules still enforce:
- single composition roots
- no business logic in DI
- no datasource imports in presentation
- design-system widget/token usage

Cross-file sync drift is now guarded in CI by:
- `scripts/validate_sync_adapter_registry.py`

## Resume Priorities

1. Catch `sync-engine-refactor` up to the merged UI design-system baseline before landing more sync-engine edits.
2. Refactor sync orchestration against the new screen contracts, registries, diagnostics, and composed provider/controller endpoints instead of older screen internals.
3. Keep driver registries, testing keys, screen contracts, and sync adapter validation aligned in the same change when UI/sync seams move.

### Session 747 (2026-04-07, Codex)
**Work**: Merged the UI design-system refactor, closed the last UI issues, added structural sync adapter drift validation, and switched the workspace back to `sync-engine-refactor`.
**Decisions**: Treat GitHub issues as the defect system of record; do not use `.claude/defects`. Enforce sync adapter drift with a structural validator instead of count-based CI checks.
**Next**: Catch `sync-engine-refactor` up to the merged UI baseline, then continue the sync delete-orchestration split against the new UI orchestrator/provider/controller endpoints.
