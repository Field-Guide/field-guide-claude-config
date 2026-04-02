# Dependency Graph

## Direct Changes — Files and Symbols

### Phase 1: Dead Code & Quick Fixes
| File | Symbol | Change Type |
|------|--------|-------------|
| `lib/features/auth/data/datasources/remote/user_profile_sync_datasource.dart` | `updateLastSyncedAt` | MODIFY — remove `userId` param |
| `lib/features/sync/application/sync_orchestrator.dart` | caller of `updateLastSyncedAt` (~line 291) | MODIFY — remove `userId` arg |
| `lib/shared/datasources/query_mixins.dart` | entire file | DELETE |
| `lib/shared/datasources/datasources.dart:6` | re-export line | MODIFY — remove export |
| `test/features/sync/schema/sync_queue_migration_test.dart` | entire file | DELETE |
| `lib/features/auth/services/auth_service.dart:312-361` | `clearLocalCompanyData` | DELETE method |
| `lib/features/auth/domain/usecases/switch_company_use_case.dart` | entire file | DELETE |
| `lib/features/auth/domain/usecases/sign_in_use_case.dart` | `SwitchCompanyUseCase` dep | MODIFY — remove import, field, param |
| `lib/features/auth/di/auth_initializer.dart` | `SwitchCompanyUseCase` wiring | MODIFY — remove import, construction |

### Phase 2: Schema & Migration
| File | Symbol | Change Type |
|------|--------|-------------|
| `lib/core/database/database_service.dart` | `_onUpgrade` | MODIFY — add migration to rebuild form_responses |
| `lib/core/database/schema_verifier.dart:324` | `expectedSchema` form_type entry | MODIFY — remove DEFAULT |
| `lib/core/database/schema_verifier.dart:440-456` | ADD COLUMN repair logic | DELETE — make report-only |
| `lib/core/database/schema_verifier.dart` | `verify()` return type | MODIFY — return SchemaReport |

### Phase 3: Boundary Fixes
| File | Symbol | Change Type |
|------|--------|-------------|
| `lib/features/settings/data/datasources/local/user_certification_local_datasource.dart` | class | MODIFY — add upsert/delete methods |
| `lib/features/auth/data/datasources/remote/user_profile_sync_datasource.dart:86-101` | `pullUserCertifications` | MODIFY — delegate to local datasource |
| `lib/features/entries/data/repositories/entry_contractors_repository.dart` | new file | CREATE |
| `lib/features/entries/presentation/controllers/contractor_editing_controller.dart` | constructor | MODIFY — take repository |
| `lib/features/entries/presentation/widgets/entry_contractors_section.dart` | widget param | MODIFY — take repository |
| `lib/features/entries/presentation/controllers/pdf_data_builder.dart` | method params | MODIFY — take repository |
| `lib/features/entries/presentation/screens/home_screen.dart` | context.read calls | MODIFY — read repository |
| `lib/features/entries/di/entries_providers.dart` | `entryProviders()` | MODIFY — register repository |

### Phase 4: Structural
| File | Symbol | Change Type |
|------|--------|-------------|
| `lib/features/sync/application/sync_engine_factory.dart` | new file | CREATE |
| `lib/features/sync/application/sync_orchestrator_builder.dart` | new file | CREATE |
| `lib/features/sync/application/sync_orchestrator.dart` | constructor, setters | MODIFY — private constructor, remove setters |
| `lib/features/sync/di/sync_initializer.dart` | `create()` | MODIFY — use builder |
| `lib/features/sync/application/background_sync_handler.dart` | desktop timer path | MODIFY — use factory |

### Phase 4 (cont): A6 Baseline Reduction
| File | Symbol | Change Type |
|------|--------|-------------|
| `lib/features/sync/di/sync_initializer.dart` | `create()` | MODIFY — move await/try out of DI layer |
| `lib/features/sync/di/sync_providers.dart` | async wiring | MODIFY — review remaining awaits |
| `lint_baseline.json` | sync DI entries | MODIFY — reduce violation counts |

### Phase 5: Sign-Out Warning
| File | Symbol | Change Type |
|------|--------|-------------|
| `lib/features/auth/domain/usecases/sign_out_use_case.dart` | `execute()` | MODIFY — add unsynced check |
| `lib/features/settings/presentation/widgets/sign_out_dialog.dart` | dialog UI | MODIFY — three-action prompt |

---

## Key Dependency Chains

### SyncOrchestrator (102 nodes at depth 2)
```
sync_orchestrator.dart
  ├── imports: database_service, sync_engine, sync_registry, user_profile_sync_datasource,
  │            app_config_repository, form_type_constants, logger
  └── imported by: sync_initializer → sync_providers → app_initializer
                    sync_provider → scaffold_with_nav_bar
                    fcm_handler
                    sync_enrollment_service
                    driver_server
                    project_provider, project_list_screen
                    admin_dashboard_screen
```

### SchemaVerifier (5 nodes — isolated)
```
schema_verifier.dart
  ├── imports: logger, form_type_constants
  └── imported by: schema_verifier_drift_test.dart (only)
  NOTE: Called from database_service.dart but via direct method call, not import
```

### ContractorEditingController (16 nodes)
```
contractor_editing_controller.dart
  ├── imports: logger, contractors/models, contractors/local_datasources,
  │            contractor_provider, equipment_provider, personnel_type_provider
  └── imported by: entry_editor_screen, home_screen, entry_contractors_section,
                    contractor_editing_controller_test
```

### BackgroundSyncHandler (102 nodes at depth 2)
```
background_sync_handler.dart
  ├── imports: database_service, sync_engine, sync_registry, logger, supabase_config
  └── imported by: sign_out_use_case → auth_provider → many screens
                    app_bootstrap → app_initializer
```

### SwitchCompanyUseCase (7 nodes — small blast radius)
```
switch_company_use_case.dart
  ├── imports: auth_service, company_repository, database_service
  └── imported by: sign_in_use_case, auth_initializer
                    3 test files (sign_in_test, switch_company_test, auth_provider_test)
```

---

## Data Flow: Sign-Out with Unsynced Warning

```
SignOutDialog (UI)
  → checks unsynced count via SignOutUseCase or SyncOrchestrator.getPendingCount()
  → if count > 0: show 3-action dialog
    → "Sync & Sign Out": SyncOrchestrator.pushAndPull() → SignOutUseCase.execute()
    → "Sign Out Anyway": SignOutUseCase.execute() directly
    → "Cancel": dismiss
  → SignOutUseCase.execute()
    → AuthService.signOut() (Supabase session only)
    → BackgroundSyncHandler.dispose()
    → clear preferences + secure storage
```
