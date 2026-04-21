# Sync Engine Test Decomposition Checklist

Date: 2026-04-19

Opened from the sync-soak state-machine refactor P3 closeout. This is a
separate track; do not mix it into the soak/driver decomposition.

## Scope

Large sync/test files to decompose:

- `test/features/sync/engine/sync_engine_test.dart`
- `test/features/sync/engine/file_sync_handler_test.dart`
- `test/features/projects/presentation/screens/project_list_screen_test.dart`

## Guardrails

- Preserve existing behavioral assertions.
- Prefer fixture builders and scenario helpers over inline setup blocks.
- Do not add test-only hooks to production sync code.
- Keep `SyncCoordinator` as the production sync entrypoint.
- Keep `change_log` trigger-owned; no manual test inserts except existing
  migration/repair fixtures that explicitly validate trigger behavior.

## Ordered Work

- [ ] Inventory current scenario groups and shared setup duplication.
- [ ] Extract fixture builders for users, projects, sync rows, files, and local
  database state.
- [ ] Split `sync_engine_test.dart` into focused scenario files without
  changing the underlying engine contract.
- [ ] Split `file_sync_handler_test.dart` by metadata, storage, retry, and
  cleanup contracts.
- [ ] Split `project_list_screen_test.dart` into provider setup, rendering,
  sync-state, and action-intent groups.
- [ ] Run the full sync engine and project-list test suites.
- [ ] Re-run `dart analyze` and `dart run custom_lint`.
