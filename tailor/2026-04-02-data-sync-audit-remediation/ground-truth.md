# Ground Truth

## CRITICAL FLAGS

### FLAG-1: UserCertificationLocalDatasource ALREADY EXISTS
The spec proposes creating `lib/features/auth/data/datasources/local/user_certification_local_datasource.dart`.
**A datasource already exists at** `lib/features/settings/data/datasources/local/user_certification_local_datasource.dart` (line 8).
- It's read-only: only `getByUserId(String userId)` method
- Has a companion model: `lib/features/settings/data/models/user_certification.dart`
- **Plan must**: Extend the existing datasource with `upsertCertifications()` and `deleteCertificationsForUser()` methods instead of creating a duplicate. OR move it to auth/ if that's the better domain home.

### FLAG-2: Canonical schema DDL has NO DEFAULT on form_type
`lib/core/database/schema/toolbox_tables.dart:34` defines:
```
form_type TEXT NOT NULL,
```
No DEFAULT. The DEFAULT only exists in:
- Migration v22 (`database_service.dart:807-808`): `TEXT NOT NULL DEFAULT '$kFormTypeMdot0582b'`
- SchemaVerifier (`schema_verifier.dart:324`): `TEXT NOT NULL DEFAULT '$kFormTypeMdot0582b'`
**Plan must**: The table rebuild migration may be unnecessary if the canonical DDL is already correct. Verify whether existing databases from migration v22 carry the DEFAULT in their schema. If so, the rebuild is still needed to remove it from existing installations.

### FLAG-3: SyncOrchestrator.forTesting used by 5 test files, not 2
The spec says "2 files." Actual consumers via direct call or `super.forTesting()`:
1. `test/features/sync/presentation/providers/sync_provider_test.dart:16` — `super.forTesting()`
2. `test/features/sync/engine/sync_engine_delete_test.dart:109` — `SyncOrchestrator.forTesting()`
3. `test/features/sync/application/fcm_handler_test.dart:11` — `super.forTesting()`
4. `test/features/sync/application/sync_enrollment_service_test.dart:16` — `super.forTesting()`
5. `test/features/sync/engine/sync_engine_circuit_breaker_test.dart:12` — `super.forTesting()`

All 5 must be updated when moving `forTesting` to a test helper.

---

## Verified Literals

### Table Names
| Literal | File:Line | Status |
|---------|-----------|--------|
| `user_certifications` | `sync_engine_tables.dart:73` | VERIFIED |
| `form_responses` | `toolbox_tables.dart:32` | VERIFIED |
| `change_log` | `sync_engine_tables.dart` | VERIFIED |
| `query_mixins.dart` (file) | `lib/shared/datasources/query_mixins.dart` | VERIFIED — exists, dead code |
| `sync_queue_migration_test.dart` (file) | `test/features/sync/schema/sync_queue_migration_test.dart` | VERIFIED — exists |

### Symbol Names
| Symbol | File:Line | Status |
|--------|-----------|--------|
| `clearLocalCompanyData` | `auth_service.dart:312` | VERIFIED — static method |
| `SwitchCompanyUseCase` | `switch_company_use_case.dart:15` | VERIFIED — class exists |
| `updateLastSyncedAt(String userId)` | `user_profile_sync_datasource.dart:33` | VERIFIED — userId param present |
| `BatchOperationsMixin` | `query_mixins.dart:4` | VERIFIED — 0 importers |
| `SyncOrchestrator.forTesting` | `sync_orchestrator.dart:113` | VERIFIED |
| `registerSyncAdapters()` | `sync_registry.dart:29` | VERIFIED — called from orchestrator:165, bg handler:44 |
| `SyncEngine.createForBackgroundSync` | `sync_engine.dart:177` | VERIFIED — static factory |
| `getPendingCount()` | `sync_orchestrator.dart:608` | VERIFIED — queries change_log |
| `kFormTypeMdot0582b` | `form_type_constants.dart` | VERIFIED |
| `BaseLocalDatasource<T>` | `base_local_datasource.dart:5` | VERIFIED — abstract class |
| `GenericLocalDatasource<T>` | `generic_local_datasource.dart:22` | VERIFIED — extends BaseLocalDatasource |
| `BaseRemoteDatasource<T>` | `base_remote_datasource.dart:9` | VERIFIED — constructor injection |

### File Paths
| Path | Status |
|------|--------|
| `lib/features/auth/domain/usecases/switch_company_use_case.dart` | VERIFIED |
| `lib/features/auth/services/auth_service.dart` | VERIFIED |
| `lib/features/auth/domain/usecases/sign_in_use_case.dart` | VERIFIED |
| `lib/features/auth/di/auth_initializer.dart` | VERIFIED |
| `lib/shared/datasources/datasources.dart` | VERIFIED |
| `lib/features/sync/application/sync_orchestrator.dart` | VERIFIED |
| `lib/features/sync/application/background_sync_handler.dart` | VERIFIED |
| `lib/features/sync/di/sync_initializer.dart` | VERIFIED |
| `lib/features/sync/engine/sync_registry.dart` | VERIFIED |
| `lib/features/entries/presentation/controllers/contractor_editing_controller.dart` | VERIFIED |
| `lib/features/entries/presentation/widgets/entry_contractors_section.dart` | VERIFIED |
| `lib/features/entries/presentation/controllers/pdf_data_builder.dart` | VERIFIED |
| `lib/features/entries/presentation/screens/home_screen.dart` | VERIFIED |
| `lib/features/settings/presentation/widgets/sign_out_dialog.dart` | VERIFIED |
| `lib/features/auth/domain/usecases/sign_out_use_case.dart` | VERIFIED |
| `lib/core/database/schema_verifier.dart` | VERIFIED |

### DI / Provider Registrations
| Registration | File:Line | Status |
|-------------|-----------|--------|
| `SwitchCompanyUseCase` constructed | `auth_initializer.dart:61` | VERIFIED |
| `SwitchCompanyUseCase` injected to SignInUseCase | `auth_initializer.dart` (via constructor) | VERIFIED |
| `entryProviders()` takes 3 datasources | `entries_providers.dart:27` | VERIFIED — takes EntryPersonnelCountsLocalDatasource, EntryEquipmentLocalDatasource, EntryContractorsLocalDatasource |

---

## Lint Rules for New Files

| Proposed New File Path | Active Rules | Key Constraints |
|----------------------|-------------|-----------------|
| `lib/features/sync/application/sync_engine_factory.dart` | A1, A2, A9, S2, S4, S8 | No singletons, no silent catches |
| `lib/features/sync/application/sync_orchestrator_builder.dart` | A1, A2, A9, S2, S4, S8 | No singletons, no silent catches |
| `lib/features/entries/data/repositories/entry_contractors_repository.dart` | A1, A2, A9, D2, S5 | No singletons, soft-delete awareness, project_id scoping |
| `test/helpers/sync_orchestrator_test_helper.dart` | T2, T3, T4, T5 | Test rules only |
| `test/shared/datasources/base_remote_datasource_test.dart` | T2, T3, T4, T5 | Test rules only |
| `test/features/auth/data/datasources/remote/user_profile_sync_datasource_test.dart` | T2, T3, T4, T5 | Test rules only |
| `test/features/sync/application/sync_orchestrator_builder_test.dart` | T2, T3, T4, T5 | Test rules only |
| `test/features/sync/application/sync_engine_factory_test.dart` | T2, T3, T4, T5 | Test rules only |
| `test/core/database/schema_verifier_report_test.dart` | T2, T3, T4, T5 | Test rules only |

Note: `lib/features/auth/data/datasources/local/user_certification_local_datasource.dart` — DO NOT CREATE. Extend existing one at `lib/features/settings/data/datasources/local/user_certification_local_datasource.dart` instead (see FLAG-1).
