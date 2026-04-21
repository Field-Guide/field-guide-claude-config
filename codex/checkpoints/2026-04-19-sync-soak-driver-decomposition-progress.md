# Sync Soak Driver Decomposition Progress

## 2026-04-19 16:27 - Scope Reset

Reviewed the driver decomposition spec as the structural subset of the newer
state-machine refactor spec.

Current repo facts:

- `lib/core/driver/harness_seed_data.dart` no longer exists; seed fixture data
  lives under `integration_test/sync/harness/seed/`.
- `rg` found no remaining `lib/core/driver/**/*.dart` imports of
  `features/*/data/datasources/local`.
- `DriverDataSyncHandler.handle` is already route-table based.
- `driver_diagnostics_handler.dart` is currently 423 lines, below the 500-line
  driver budget.
- `screen_contract_registry.dart` remains intentionally registry-shaped and has
  an inline exception note expiring 2026-09-30.

Next driver-specific action:

- Add `lib/core/driver/**/*.dart` to the size-budget gate and create
  `lib/core/driver/size-budget-exceptions.json` only for intentional current
  exceptions.

## 2026-04-19 16:35 - Driver Size Lock-In

Changed:

- Added recursive `lib/core/driver/**/*.dart` coverage to the shared size gate.
- Created `lib/core/driver/size-budget-exceptions.json` with the single
  registry-shaped `screen_contract_registry.dart` exception.
- Split `driver_data_sync_handler_query_routes.dart` into:
  - `driver_data_sync_handler_query_routes.dart` for route registration.
  - `driver_data_sync_handler_local_query_routes.dart` for local read,
    queue, and sync-status routes.
  - `driver_data_sync_handler_remote_query_routes.dart` for remote record and
    reconciliation routes.

Verification:

- `dart analyze lib\core\driver test\core\driver` passed.
- `flutter test test\core\driver` passed: 76 tests.
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
  passed; the former query-route file no longer needs an exception.

## 2026-04-19 16:39 - Driver Data-Sync DI Tidy-Up

Changed:

- `DriverDataSyncHandler` now takes non-null `SyncCoordinator`,
  `DatabaseService`, `ProjectLifecycleService`, `SyncPoisonStateService`,
  `SyncRecoveryService`, and `SupabaseClient` dependencies.
- Removed route-level fallback branches that returned 500 for missing required
  dependencies.
- Confirmed `DriverServer` and `DriverSetup` already explicitly wire every
  required dependency.

Verification:

- `dart analyze lib\core\driver test\core\driver` passed.
- `flutter test test\core\driver` passed: 76 tests.
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
  passed with `blocked_excepted=17`, `ok=110`, `review=12`.
- `dart analyze lib integration_test test\harness test\core\driver` passed.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed:
  21 test files, all assertions green.

## 2026-04-19 16:41 - Soak Facade Confirmation

Driver-decomposition P2 facade-shape check is now closed:

- `integration_test/sync/soak/soak_driver.dart` remains the external import
  surface for soak harness consumers.
- The facade is 79 lines, under the 80-line target.
- `test/harness/soak_driver_test.dart` no longer imports the metrics collector
  directly; it reaches that public test surface through `soak_driver.dart`.

Verification:

- `dart analyze lib integration_test test\harness test\core\driver` passed.
- `flutter test test\harness test\core\driver` passed: 104 tests, 21 skipped
  local/live gates.

## 2026-04-19 16:56 - Driver Closeout Lint Fixes

Changed:

- `driver_data_sync_handler_local_query_routes.dart` now keeps local
  file-head and local-record diagnostics from returning soft-deleted rows for
  tables with a `deleted_at` column.
- `DriverDataSyncPolicy` now exposes `tablesWithoutSoftDelete` /
  `hasSoftDeleteColumn` so driver diagnostics can choose the active-record
  query path without guessing table schema.
- `no_raw_supabase_sync_table_io_outside_supabase_sync` now lists
  `driver_data_sync_handler_remote_query_routes.dart` as the approved owner
  created by the query-route split.

Verification:

- `dart analyze lib integration_test test\harness test\core\driver` passed.
- `dart run custom_lint` passed.
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
  passed with `blocked_excepted=17`, `ok=110`, `review=12`.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed:
  21 test files, all assertions green.
- `flutter test test\harness test\core\driver test\core\router\app_router_test.dart test\core\app_widget_test.dart`
  passed: 123 tests, 21 skipped live/local gates.

## 2026-04-19 17:23 - Spec Audit Lock-In Pass

Changed:

- Added CI lock-in steps for generated testing-key idempotency, sync-soak size
  budget enforcement, and sync-soak harness self-tests.
- Added `.github/pull_request_template.md` with the driver `_handle*`,
  state-machine region-builder, real-auth, and no-direct-`/driver/sync`
  checklist.
- Added `.codex/plans/2026-04-19-sync-soak-periodic-codemunch-audit-plan.md`
  as the durable CodeMunch periodic audit command reference.
- Extracted `SoakDriver._prepareExecutor` so `SoakDriver.run` meets the
  CodeMunch body-length target.
- Updated `scripts/check_sync_soak_file_sizes.ps1` so documented review-size
  exceptions surface as `review_excepted`, then documented the two intentional
  integration soak executor review exceptions.

Audit:

- `harness_seed_defaults.dart` is gone by consolidation rather than a missed
  relocation; the heavy seed fixture is now
  `integration_test/sync/harness/seed/harness_seed_data.dart`.
- Shell audit found no feature local-datasource imports under
  `lib/core/driver`.
- CodeMunch after re-index:
  - `SoakDriver.run` is cyclomatic 1, nesting 1, 36 lines.
  - `LocalSupabaseSoakActionExecutor.execute` is cyclomatic 3, nesting 2,
    7 lines.
  - `HeadlessAppSyncActionExecutor.execute` is cyclomatic 3, nesting 2,
    7 lines.
  - `DriverDataSyncHandler.handle` is cyclomatic 3, nesting 2, 10 lines.
  - `DriverDiagnosticsHandler._handleActorContext` is cyclomatic 4, nesting 3,
    18 lines.
  - `get_hotspots` top 25 has no `lib/core/driver/**` symbol.

Verification:

- `dart analyze lib integration_test test\harness test\core\driver` passed.
- `dart run custom_lint` passed.
- `pwsh -NoProfile -File scripts\check_sync_soak_file_sizes.ps1 -FailOnBlocked`
  passed with `blocked_excepted=17`, `ok=110`, `review=10`,
  `review_excepted=2`.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed:
  21 test files, all assertions green.
- `pwsh -NoProfile -File tools\gen-keys\verify-idempotent.ps1` passed:
  typed key outputs are byte-identical.
- `flutter test test\harness test\core\driver test\core\router\app_router_test.dart test\core\app_widget_test.dart`
  passed: 123 tests, 21 skipped live/local gates.
- `git diff --check` passed; only line-ending normalization warnings.
