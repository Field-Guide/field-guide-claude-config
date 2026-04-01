# Blast Radius

## AppInitializer (risk: 0.85)

- **Direct dependents**: 3 (main.dart, main_driver.dart, app_bootstrap.dart)
- **Confirmed references**: 4 files
- **Potential (indirect)**: 1 file (app_bootstrap_test.dart)
- **Risk assessment**: HIGH but contained. Only 3 files import it. Decomposition is internal — the public API (`AppInitializer.initialize()`) stays the same, returning `AppDependencies`.

## AppRouter (risk: 0.80)

- **Direct dependents**: 3 (main.dart, app_bootstrap.dart, app_router_test.dart)
- **Confirmed references**: 3 files
- **Risk assessment**: MEDIUM. Route modules are an internal decomposition. `AppRouter` class keeps the same constructor and `router` getter. Callers see no change.

## BackgroundSyncHandler (risk: 0.64)

- **Direct dependents**: 4 (app_initializer.dart, sign_out_use_case.dart, auth_provider.dart, background_sync_handler_test.dart)
- **Confirmed references**: 4 files
- **Potential (indirect)**: 57 files (through import chains)
- **Risk assessment**: LOW for the change. Adding an optional `SupabaseClient?` parameter to `initialize()` is backwards-compatible. `_performDesktopSync` change is internal.

## InitOptions (risk: 0.50)

- **Direct dependents**: 5 (app_initializer.dart, main.dart, main_driver.dart, 2 test files)
- **Risk assessment**: LOW. Removing `isDriverMode` — no callers set it, no code reads it. The 2 test files that reference it will be rewritten anyway.

## Dead Code Targets

| Target | Confidence | Action |
|--------|-----------|--------|
| `lib/test_harness/` (5 files) | 1.0 | DELETE |
| `InitOptions.isDriverMode` | 1.0 (never read) | REMOVE |

## Summary Counts

| Category | Count |
|----------|-------|
| Files directly modified | 10 |
| Files deleted | 5 |
| New files created | ~14 (5 initializer modules, 7 route modules, 1 app_widget.dart, test rewrites) |
| Test files rewritten | 5 |
| Test files deleted | 1 (entrypoint_equivalence_test.dart) |
| Total blast radius (direct) | ~35 files |
