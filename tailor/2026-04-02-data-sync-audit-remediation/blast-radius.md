# Blast Radius

## Per-Symbol Impact

### clearLocalCompanyData (DELETE)
- **Risk score**: 0.724
- **Confirmed consumers**: 1 (`switch_company_use_case.dart` — also being deleted)
- **Potential (wildcard imports)**: 77 files import `auth_service.dart` but don't reference this method
- **Impact**: SAFE — only consumer is also being deleted. No cascade risk.

### SwitchCompanyUseCase (DELETE)
- **Risk score**: 0.890
- **Confirmed consumers**: 5
  - `auth_initializer.dart` (construction) — MODIFY
  - `sign_in_use_case.dart` (import + field + param) — MODIFY
  - `sign_in_use_case_test.dart` (mock) — MODIFY
  - `switch_company_use_case_test.dart` (direct test) — DELETE
  - `auth_provider_test.dart` (mock) — MODIFY
- **Impact**: MODERATE — 3 prod files, 3 test files. All modifications are mechanical removal.

### SyncOrchestrator (MODIFY — constructor change)
- **Risk score**: 0.782
- **Confirmed consumers**: 23 (12 prod + 11 test)
- **Key prod consumers**: sync_initializer, sync_providers, sync_provider, driver_server, fcm_handler, sync_enrollment_service, project_provider, project_list_screen, scaffold_with_nav_bar, admin_dashboard_screen, app_dependencies
- **Impact**: HIGH — constructor change affects all instantiation sites. Builder pattern isolates the change to SyncInitializer.create() (the only place the constructor is called directly). Downstream consumers receive the orchestrator via Provider, unaffected.
- **forTesting consumers**: 5 test files (see ground-truth FLAG-3)

### SchemaVerifier (MODIFY — return type change)
- **Risk score**: 1.0 (isolated)
- **Confirmed consumers**: 1 (`schema_verifier_drift_test.dart`)
- **Impact**: LOW — called from database_service.dart via method call (no import). Only 1 test file directly imports it. Callers in database_service.dart need to handle new return type.

### BatchOperationsMixin (DELETE)
- **Risk score**: 0.0
- **Confirmed consumers**: 0
- **Impact**: NONE — provably dead code.

### BaseRemoteDatasource (ADD TEST)
- **Descendants**: 20 subclasses across all features
- **Impact**: Test-only addition, no prod change.

---

## Dead Code Targets

| Target | File | Confidence | Action |
|--------|------|------------|--------|
| `BatchOperationsMixin` | `lib/shared/datasources/query_mixins.dart` | 1.0 | DELETE file |
| `query_mixins.dart` re-export | `lib/shared/datasources/datasources.dart:6` | 1.0 | REMOVE line |
| `clearLocalCompanyData` | `auth_service.dart:312-361` | 1.0 (after SwitchCompanyUseCase removed) | DELETE method |
| `SwitchCompanyUseCase` | `switch_company_use_case.dart` | 1.0 (no remaining callers after sign_in fix) | DELETE file |
| `switch_company_use_case_test.dart` | `test/features/auth/domain/use_cases/` | 1.0 | DELETE file |
| `sync_queue_migration_test.dart` | `test/features/sync/schema/` | N/A (stale, not dead) | DELETE file |
| `SwitchCompanyResult` | `switch_company_use_case.dart` (if defined there) | 1.0 | Verify location, delete with file |

---

## Test Files Requiring Modification

| Test File | Reason |
|-----------|--------|
| `test/features/auth/domain/use_cases/sign_in_use_case_test.dart` | Remove SwitchCompanyUseCase mock/references |
| `test/features/auth/domain/use_cases/switch_company_use_case_test.dart` | DELETE entirely |
| `test/features/auth/presentation/providers/auth_provider_test.dart` | Remove SwitchCompanyUseCase mock |
| `test/features/sync/presentation/providers/sync_provider_test.dart` | Update forTesting import |
| `test/features/sync/engine/sync_engine_delete_test.dart` | Update forTesting import |
| `test/features/sync/application/fcm_handler_test.dart` | Update forTesting import |
| `test/features/sync/application/sync_enrollment_service_test.dart` | Update forTesting import |
| `test/features/sync/engine/sync_engine_circuit_breaker_test.dart` | Update forTesting import |
| `test/features/entries/presentation/controllers/contractor_editing_controller_test.dart` | Update to use repository |
