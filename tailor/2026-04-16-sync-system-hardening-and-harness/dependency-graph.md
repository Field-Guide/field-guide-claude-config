# Dependency Graph — Sync System Hardening And Harness

Map of which files depend on which, focused on the surfaces Scope will touch. Use this to choose integration seams and to bound the blast radius for each phase.

## Sync engine core

```
lib/main.dart
  └── lib/core/bootstrap/app_initializer.dart
        ├── lib/core/di/app_bootstrap.dart
        │     └── lib/features/sync/di/sync_providers.dart
        │           └── lib/features/sync/application/sync_coordinator.dart  ← entrypoint
        │                 ├── lib/features/sync/application/sync_engine_factory.dart
        │                 │     └── lib/features/sync/engine/sync_engine.dart
        │                 │           ├── lib/features/sync/engine/pull_handler.dart
        │                 │           │     ├── pull_scope_state.dart
        │                 │           │     ├── pull_record_applicator.dart
        │                 │           │     ├── pull_fk_violation_resolver.dart
        │                 │           │     └── dirty_scope_tracker.dart
        │                 │           ├── lib/features/sync/engine/push_handler.dart
        │                 │           │     ├── push_execution_router.dart
        │                 │           │     ├── push_error_handler.dart
        │                 │           │     └── push_table_planner.dart
        │                 │           ├── lib/features/sync/engine/maintenance_handler.dart
        │                 │           ├── lib/features/sync/engine/sync_run_lifecycle.dart
        │                 │           ├── lib/features/sync/engine/sync_status_store.dart ← state of truth
        │                 │           └── lib/features/sync/engine/sync_mutex.dart
        │                 ├── lib/features/sync/application/sync_run_executor.dart
        │                 ├── lib/features/sync/application/sync_retry_policy.dart
        │                 ├── lib/features/sync/application/sync_trigger_policy.dart
        │                 ├── lib/features/sync/application/post_sync_hooks.dart
        │                 ├── lib/features/sync/application/connectivity_probe.dart
        │                 └── lib/features/sync/application/sync_query_service.dart
        ├── lib/features/sync/application/sync_lifecycle_manager.dart
        │     └── lib/features/sync/application/realtime_hint_handler.dart
        │           └── lib/features/sync/application/realtime_hint_transport_controller.dart
        └── lib/features/sync/application/sync_initializer.dart
              └── sync_initializer_runtime_wiring.dart

lib/features/sync/engine/sync_registry.dart  ← adapter list (load-bearing order)
  ├── lib/features/sync/adapters/simple_adapters.dart (17 configs)
  ├── lib/features/sync/adapters/daily_entry_adapter.dart
  ├── lib/features/sync/adapters/photo_adapter.dart
  ├── lib/features/sync/adapters/entry_equipment_adapter.dart
  ├── lib/features/sync/adapters/equipment_adapter.dart
  ├── lib/features/sync/adapters/inspector_form_adapter.dart
  ├── lib/features/sync/adapters/form_response_adapter.dart
  ├── lib/features/sync/adapters/document_adapter.dart
  ├── lib/features/sync/adapters/support_ticket_adapter.dart
  └── lib/features/sync/adapters/consent_record_adapter.dart
```

Load order matters. FK parents come first. `scripts/validate_sync_adapter_registry.py` enforces parity with `SyncEngineTables.triggeredTables` at CI time.

## Error classification

```
Callers of SyncErrorClassifier.classify (blast radius for any change):
  lib/features/sync/engine/push_handler.dart
  lib/features/sync/engine/pull_handler.dart
  lib/features/sync/engine/push_error_handler.dart
  lib/features/sync/engine/sync_run_lifecycle.dart
  lib/features/sync/application/sync_retry_policy.dart
  lib/features/sync/application/sync_run_executor.dart
```

`42501` (RLS denial) is treated as non-retryable here. Any rewrite must keep that invariant.

## SyncStatus transport state

```
lib/features/sync/domain/sync_status.dart
  └── consumed by:
        lib/features/sync/engine/sync_status_store.dart
        lib/features/sync/presentation/providers/sync_provider.dart
        lib/features/sync/presentation/providers/sync_provider_controls.dart
        lib/features/sync/presentation/providers/sync_provider_listeners.dart
        lib/features/sync/presentation/controllers/sync_dashboard_controller.dart
        lib/features/sync/presentation/widgets/sync_dashboard_status_widgets.dart
        lib/features/sync/presentation/widgets/sync_status_icon.dart
        lib/features/sync/application/sync_query_service.dart (transportHealth)
        lib/core/driver/driver_diagnostics_handler.dart (_handleSyncTransport)
```

## Role / assignment flow (flashing fix target)

```
AuthChangeEvent → AuthProvider._authService.authStateChanges (auth_provider.dart:101)
  └── AuthProvider.notifyListeners()
        └── ProjectProviderAuthController.onAuthChanged (auth_controller.dart:85)
              ├── _loadAssignments(newUserId)
              │     └── LoadAssignmentsUseCase
              │           └── ProjectAssignmentRepository (data/repositories)
              │                 └── sync pull → local mirror (synced_scope_store)
              └── _loadProjectsByCompany(newCompanyId)
                    └── ProjectCatalogUseCase → ProjectRepository

ProjectProvider state:
  _assignedProjectIds  ←── flashing fix requires this set
  _projects                 to be populated pre-first-render,
  _remoteProjects           and the filter applied atomically
  _mergedProjects           before the list ever renders.
  _companyFilter        ←── used by ProjectProviderFilters
```

Current gap: `_loadAssignments` and `_loadProjectsByCompany` fire as two independent `unawaited(...)` calls in `ProjectProviderAuthController.initWithAuth` and in `onAuthChanged`. Between them, the project list can render unfiltered for one frame. Phase 3 (correctness matrix) captures this; Phase 6 (rewrite) fixes it.

## Logging + observability

```
lib/main.dart
  ├── SentryFlutter.init(options)
  │     ├── options.beforeSend = beforeSendSentry  ← sentry_pii_filter.dart
  │     └── options.beforeSendTransaction = beforeSendTransaction
  └── runZonedGuarded with Logger.zoneSpec()
        └── Logger.error routes to file + runtime hooks

Logger class graph:
  lib/core/logging/logger.dart (library)
    ├── part 'logger_file_transport.dart'  (File + category rotation)
    ├── part 'logger_http_transport.dart'   (dev DEBUG_SERVER=true only)
    └── part 'logger_runtime_hooks.dart'    (AppLifecycleLogger)
    ├── lib/core/logging/log_payload_sanitizer.dart
    ├── lib/core/logging/logger_error_reporter.dart
    │     └── uses Sentry via logger_sentry_transport.dart
    └── lib/core/logging/app_route_observer.dart (NavigatorObserver)

Sentry config:
  lib/core/config/sentry_runtime.dart   ← DSN + feature flags
  lib/core/config/sentry_consent.dart   ← private flag + getter + mutators
  lib/core/config/sentry_pii_filter.dart ← beforeSendSentry + beforeSendTransaction
  lib/core/config/sentry_feedback_launcher.dart ← in-app feedback UI
```

Sync-touching code that logs today (heavy callers — 91 Logger calls across 20 sync files):
- `sync_lifecycle_manager.dart` (13 calls) — lifecycle transitions
- `background_sync_handler.dart` (10 calls) — background path
- `fcm_handler.dart` (10 calls)
- `dirty_scope_tracker.dart` (6 calls)
- `sync_coordinator.dart` (6 calls)
- `sync_enrollment_service.dart` (5 calls)
- `sync_background_retry_scheduler.dart` (5 calls)
- `connectivity_probe.dart` (4 calls)

These are the anchors for the logging event-class audit (Phase 4).

## Driver contract

```
lib/core/driver/driver_setup.dart
  └── lib/core/driver/driver_server.dart
        └── lib/core/driver/driver_port_binding.dart
              ├── lib/core/driver/driver_data_sync_handler.dart (routes.dart, _routes/*)
              ├── lib/core/driver/driver_diagnostics_handler.dart ← screen contract + sync-transport endpoints
              ├── lib/core/driver/driver_interaction_handler.dart
              ├── lib/core/driver/driver_delete_propagation_handler.dart
              ├── lib/core/driver/driver_file_injection_handler.dart
              └── lib/core/driver/driver_shell_handler.dart

Contract files (load-bearing for sync harness):
  lib/core/driver/screen_registry.dart          ← builder factories (39 screens)
  lib/core/driver/screen_contract_registry.dart ← diagnostic contracts (32 screens) + resolver
  lib/core/driver/flow_registry.dart            ← forms + navigation + verification flows
  lib/core/driver/harness_seed_data.dart + harness_seed_defaults.dart + harness_seed_pay_app_data.dart
```

Lint `screen_registry_contract_sync` keeps both registries in lockstep.

## Schema + migrations

```
lib/core/database/
  ├── database_service.dart (local SQLite bootstrap)
  ├── database_bootstrap.dart
  ├── schema_verifier.dart ← single source of truth for local schema shape
  └── schema/
        ├── sync_engine_tables.dart (triggered tables + triggers generator)
        ├── core_tables.dart, consent_tables.dart, contractor_tables.dart,
        ├── document_tables.dart, entry_tables.dart, entry_export_tables.dart,
        ├── export_artifact_tables.dart, extraction_tables.dart, form_export_tables.dart,
        ├── personnel_tables.dart, photo_tables.dart, quantity_tables.dart,
        ├── signature_tables.dart, support_tables.dart, sync_tables.dart, toolbox_tables.dart

supabase/migrations/ (71 files) ← applied to local Docker + staging + prod in order
supabase/rollbacks/ (15 files)  ← validated by validate_migration_rollbacks.py
supabase/seed.sql               ← currently empty; Phase 1 seeds fixture here
```

## CI + validators

```
.github/workflows/quality-gate.yml
  ├── Job 1: analyze-and-test
  │     └── verify_live_supabase_schema_contract.py (when LIVE_SUPABASE_DATABASE_URL set)
  ├── Job 2: architecture-validation
  │     ├── validate_sync_adapter_registry.py       ← drift guard
  │     ├── check_changed_migration_rollbacks.py
  │     ├── validate_migration_rollbacks.py
  │     └── verify_database_schema_platform_parity.py
  └── Job 3: security-scanning (grep-based heuristics)

fg_lint_packages/field_guide_lints/lib/
  ├── sync_integrity/rules/  (13 sync invariants)
  ├── architecture/rules/     (design-system + composition + screen contract)
  ├── data_safety/rules/      (toMap, soft-delete filter, etc.)
  └── test_quality/rules/     (TestingKeys usage, no-hardcoded-Key, etc.)

tools/ (PowerShell)
  build.ps1, start-driver.ps1, stop-driver.ps1, wait-for-driver.ps1,
  verify-sync.ps1, run_and_tail_logs.ps1, run_tests_capture.ps1
```

## External provisioning (outside repo)

- Local Docker Supabase: driven by `supabase/config.toml` (`supabase start` via CLI).
- Staging Supabase project: Pro plan, DSN + URL lands in CI secrets `SUPABASE_DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`.
- Sentry project: free tier retained; adds Log Drain ingestion endpoint in Phase 4.
- GitHub Actions secrets already used: `SUPABASE_DATABASE_URL`.

## Blast-radius summary (one-liner per phase)

- Phase 1 (local Docker + fixture): touches `supabase/seed.sql`, adds `scripts/*` and `tools/*` helpers, no Dart changes.
- Phase 2 (harness skeleton): adds `integration_test/sync/harness/**` (new tree), consumes existing driver endpoints.
- Phase 3 (correctness matrix): adds `integration_test/sync/matrix/**`, writes against real driver + real Supabase (local Docker).
- Phase 4 (logging audit + Sentry dual-feed): modifies `lib/core/logging/**`, `lib/core/config/sentry_*`, `lib/main.dart`; adds `scripts/audit_logging_coverage.ps1` and `lib/core/logging/log_event_classes.dart`.
- Phase 5 (PBT + soak): adds `pubspec.yaml` `glados` dep, `integration_test/sync/concurrency/**`, `integration_test/sync/soak/**`, `scripts/soak_local.ps1`.
- Phase 6 (rewrite): targeted edits in `lib/features/sync/engine/**` and `lib/features/sync/application/**`, plus the render-order fix in `lib/features/projects/presentation/providers/project_provider*` and `lib/features/projects/presentation/screens/project_list_screen.dart`.
- Phase 7 (staging + CI gate + noise policy): `.github/workflows/quality-gate.yml` extension + new workflow(s) for soak, Sentry + GitHub webhook glue.
