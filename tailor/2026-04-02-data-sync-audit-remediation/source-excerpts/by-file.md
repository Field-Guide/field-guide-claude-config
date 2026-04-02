# Source Excerpts by File

## lib/features/auth/services/auth_service.dart
- `clearLocalCompanyData` (line 312-361): Static method, hard-deletes 31 tables. Full source in tool results.

## lib/features/auth/domain/usecases/switch_company_use_case.dart
- `SwitchCompanyUseCase` (line 15-72): Full class. detectAndHandle() checks cached company ID, calls clearLocalCompanyData on mismatch. Also defines SwitchCompanyResult.

## lib/features/auth/domain/usecases/sign_in_use_case.dart
- Lines 5, 42, 46, 71-73: SwitchCompanyUseCase import, field, constructor param, call site.

## lib/features/auth/di/auth_initializer.dart
- Line 18: SwitchCompanyUseCase import
- Line 61: `SwitchCompanyUseCase(companyRepository: ..., databaseService: ..., authService: ...)`

## lib/features/auth/data/datasources/remote/user_profile_sync_datasource.dart
- `UserProfileSyncDatasource` (line 15-102): Full class with 4 methods. Constructor takes SupabaseClient, UserProfileLocalDatasource, optional CompanyLocalDatasource, optional DatabaseService.
- `updateLastSyncedAt(String userId)` (line 33-35): Ignores userId param.
- `pullUserCertifications(String userId)` (line 86-101): Raw db.insert into user_certifications.

## lib/features/auth/domain/usecases/sign_out_use_case.dart
- `SignOutUseCase` (line 13-53): Full class. execute() calls authService.signOut(), BackgroundSyncHandler.dispose(), clears prefs + secure storage.

## lib/features/settings/data/datasources/local/user_certification_local_datasource.dart
- `UserCertificationLocalDatasource` (line 8-23): Read-only, only getByUserId(). Needs upsert/delete for F4/F7 fix.

## lib/shared/datasources/query_mixins.dart
- `BatchOperationsMixin` (line 4-33): Dead mixin with insertBatch/deleteBatch. Zero consumers.

## lib/shared/datasources/datasources.dart
- Line 6: `export 'query_mixins.dart';` — dead re-export.

## lib/core/database/schema_verifier.dart
- `SchemaVerifier` (line 49-519): Full class. verify() at line 413. ColumnDrift at line 7. expectedSchema map. _columnTypes map. ADD COLUMN repair at 440-456. Drift detection at 458-506.
- Line 324: `'form_type': "TEXT NOT NULL DEFAULT '$kFormTypeMdot0582b'"` — needs DEFAULT removed.

## lib/core/database/database_service.dart
- Line 73, 93: Calls `SchemaVerifier.verify(db)` after open.
- Lines 807-826: Migration v22 — adds form_type column with DEFAULT, backfills.
- Line 272-283: `_addColumnIfNotExists` helper (81 call sites).

## lib/core/database/schema/toolbox_tables.dart
- Line 32-34: Canonical DDL — `form_type TEXT NOT NULL` (NO DEFAULT).

## lib/features/sync/application/sync_orchestrator.dart
- `SyncOrchestrator` (line 30-655): Full class. Constructor at 104. forTesting at 113. 4 setters at 119-136. _createEngine at 195. getPendingCount at 608.

## lib/features/sync/application/background_sync_handler.dart
- `backgroundSyncCallback` (line 20-68): Mobile isolate — full bootstrap.
- `BackgroundSyncHandler` (line 76-183): Desktop timer at _performDesktopSync (line 139).

## lib/features/sync/di/sync_initializer.dart
- `SyncInitializer.create()`: Multi-step setter wiring sequence. Calls orchestrator setters.

## lib/features/entries/presentation/controllers/contractor_editing_controller.dart
- `ContractorEditingController` (line 30-347): ChangeNotifier. Constructor takes 3 datasource types directly.

## lib/features/entries/presentation/widgets/entry_contractors_section.dart
- `EntryContractorsSection`: Widget taking EntryContractorsLocalDatasource as param.

## lib/features/entries/presentation/controllers/pdf_data_builder.dart
- `PdfDataBuilder`: Takes EntryPersonnelCountsLocalDatasource, EntryEquipmentLocalDatasource as method params.

## lib/features/entries/presentation/screens/home_screen.dart
- Lines 186-188: `context.read<EntryPersonnelCountsLocalDatasource>()`, etc.

## lib/features/entries/di/entries_providers.dart
- `entryProviders()` (line 27): Function taking 3 datasource types as required params.

## lib/features/settings/presentation/widgets/sign_out_dialog.dart
- Simple AlertDialog. Calls `AuthProvider.signOut()` on confirm.

## lib/features/sync/engine/sync_registry.dart
- `registerSyncAdapters()` (line 29): Top-level function registering all table adapters.
