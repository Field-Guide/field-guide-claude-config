# Sync Soak Periodic CodeMunch Audit

Run this audit after sync-soak or driver-decomposition changes before declaring
the spec closed.

## Required Checks

1. `mcp__jcodemunch__get_hotspots` on `local/Field_Guide_App-37debbe5` with
   `top_n=25`, `min_complexity=10`, `days=60`.
   - Pass condition: no `lib/core/driver/**` symbol appears in the top 25.
2. `mcp__jcodemunch__get_symbol_complexity` for:
   - `integration_test/sync/soak/soak_runner.dart::SoakDriver.run#method`
   - `integration_test/sync/soak/backend_rls_soak_action_executor.dart::LocalSupabaseSoakActionExecutor.execute#method`
   - `integration_test/sync/soak/headless_app_sync_action_executor.dart::HeadlessAppSyncActionExecutor.execute#method`
   - `lib/core/driver/driver_data_sync_handler.dart::DriverDataSyncHandler.handle#method`
   - `lib/core/driver/driver_diagnostics_handler.dart::DriverDiagnosticsHandler._handleActorContext#method`
3. `mcp__jcodemunch__get_coupling_metrics` on the relocated seed-data path:
   `integration_test/sync/harness/seed/harness_seed_data.dart`.
   - Pass condition: no production `lib/core/driver/**` dependency on feature
     local data sources is reintroduced.

Record the exact results in `.claude/codex/checkpoints/Checkpoint.md` and the
active `.codex/checkpoints/*progress.md` file.
