# 2026-04-12 Prerelease Architecture/Auth Final Audit TODOs

Source audit set:
- `.codex/plans/2026-04-11-final-s21-verification-adaptive-idr-plan.md`
- `.codex/plans/2026-04-11-pay-app-form-contractor-review-final-verification-spec.md`
- `.codex/plans/2026-04-11-pay-app-form-final-verification-plan.md`
- `.codex/plans/2026-04-11-prerelease-central-tracker.md`
- `C:\Users\rseba\AppData\Local\Temp\field_guide_preprod_audit_zip_review\Field Guide App - 2026-04-10 Comprehensive Pre-Production Audit.md`

CodeMunch/local scan notes:
- CodeMunch repo used: `local/Field_Guide_App-37debbe5`, commit `8cd861fe`.
- CodeMunch dependency cycles: `cycle_count=0`; reconfirmed after the
  2026-04-12 quantity-ordering and schema-verifier refactors.
- CodeMunch dead-code reachability is not reliable for this Flutter repo without framework entrypoint roots; do not use the raw dead-code percentage as a cleanup list.
- Three independent audit passes were reconciled: document/status truth, architecture/God-file seams, and auth/API/backend/session hardening.

## Release-Blocking / Must Close Before Prerelease

- [ ] Complete the final prerelease completeness review against the central tracker.
  - Evidence: `.codex/plans/2026-04-11-prerelease-central-tracker.md:40`, `:935` through `:938`, `:1005` through `:1014`.
  - Risk: several older source docs contain stale `OPEN` entries that are closed later in the central tracker, while a few true release gates remain active.
  - Done means: final evidence packet includes APK hash/install time, artifact paths, screenshots where appropriate, parsed PDF/workbook proof, DB proof, sync-status proof, explicit self-review, and a separate completeness review.

- [x] Finish Office Technician role proof.
  - Evidence: `.codex/plans/2026-04-11-prerelease-central-tracker.md:34`, `:164`, `:165`, `:167`, `:985` through `:989`.
  - Risk: role flow is still marked `PARTIAL / ACTIVE`; this is directly tied to the admin/Office Technician confusion and project assignment issues.
  - Done means: Windows admin can approve/update a user as Office Technician; S21 Office Technician can create a project, assign inspectors, review inspector entries, and cannot access admin-only account controls; real auth/backend state only.
  - Live proof added 2026-04-12: Windows admin role update changed the inspector profile to Office Technician through the UI and verified remote/local role state; S21 Office Technician created project `22600af9-fea4-4a96-bf94-c4e143b9089a`, assigned admin and inspector users, verified admin-only controls stayed hidden, created review-comment TODO `2c4b834d-0471-41be-8320-1f9bac11a2d6`, synced cleanly, and the profile was restored to `inspector` on both Windows and S21 local caches.

- [x] Finish review-comment TODO proof for inspector visibility and clearing.
  - Evidence: `.codex/plans/2026-04-11-prerelease-central-tracker.md:35`, `:173`, `:175`.
  - Risk: review comments are implemented and remotely seeded, but the final inspector TODO/dashboard/filter/clear path is still open.
  - Code/live proof added 2026-04-12: fixed stale local creator join from `user_profiles.user_id` to canonical `user_profiles.id`; added real SQLite datasource regression; S21 TODO screen now loads review comments without the SQL crash and displays creator account `E2E Test Admin`.
  - UI cleanup added 2026-04-12: review-comment cards decode percent-encoded comment bodies at the display boundary; S21 proof screenshot saved under `.codex/artifacts/2026-04-12/overnight_s21_verification/review_comments_after_decode_reload.png`.
  - Live clear proof added 2026-04-12: S21 TODO screen contained the two review-comment proof TODOs for Apr 18, 2026 assigned to inspector user `d1ca900e-d880-4915-9950-e29ba180b028`; both were completed through their checkbox UI. Local record verification showed `is_completed=1` for `c7e8e431-8342-43b5-932c-6cf8ebdfc56f` and `b8d995ad-0faa-4e8a-8c49-5423c0556809`.
  - Sync proof: `/driver/sync` pushed 2 changes with no errors; `/driver/sync-status` then reported `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`; `/driver/change-log?table=todo_items` returned `count=0`.
  - Screenshot evidence: `.codex/artifacts/2026-04-12/overnight_s21_verification/todos_after_auth_project_tests.png` and `.codex/artifacts/2026-04-12/overnight_s21_verification/review_comments_completed_s21.png`.

- [x] Resolve the final DB/Supabase checklist contradiction with fresh evidence or tracker cleanup.
  - Evidence: central tracker records Office Technician/review-comment migration proof at `.codex/plans/2026-04-11-prerelease-central-tracker.md:977` through `:983`, but the final checklist still lists DB/Supabase migrations unchecked at `:935`.
  - Risk: prerelease signoff should not leave remote schema status ambiguous.
  - Done 2026-04-12: central tracker logical checklist now marks the Office Technician/review-comment migrations closed, matching the existing remote schema/RPC proof recorded in the tracker.

- [x] Add schema drift guardrails for live Supabase and local platform parity.
  - Evidence: Windows sync failed when the app sync schema expected `support_tickets.issue_code` but the live Supabase schema had not applied migration `20260409193000`.
  - Fix 2026-04-12: live Supabase was repaired by adding the missing column and repairing remote migration history; `scripts/verify_live_supabase_schema_contract.py` now checks live Supabase columns against app sync registry/metadata in CI when `SUPABASE_DATABASE_URL` is available.
  - Local platform guard 2026-04-12: `scripts/verify_database_schema_platform_parity.py` now blocks Android/iOS/Windows local schema divergence by failing the quality gate if database schema or migration code branches by platform, except the desktop FFI database-factory initialization.
  - Verification: `python scripts\verify_database_schema_platform_parity.py`, `python scripts\verify_live_supabase_schema_contract.py`, and targeted `flutter analyze` passed.

- [x] Verify inspector project field-data permissions end to end.
  - Evidence: `.codex/plans/2026-04-11-prerelease-central-tracker.md:193`.
  - Risk: user-observed symptom was inspector/Springfield assignment uncertainty; this must be proven through real app state, not just provider tests.
  - Live proof added 2026-04-12: S21 inspector session can see Springfield project `75ae3283-d4b2-4035-ba2f-7b4adb018199`; `/projects` does not expose `project_create_button`, `project_archive_toggle_<projectId>`, or the database-delete sheet. The field-data edit affordance is available, and the project Contractors tab exposes contractor, personnel-type, and equipment add controls; project-level contractor import remains hidden.
  - Mutation proof added 2026-04-12: S21 inspector created contractor `43581791-5ca8-49ef-b738-7ed8d034943a` (`S21 Inspector Proof Contractor 0412`) on Springfield through the UI; the local record shows `created_by_user_id=d1ca900e-d880-4915-9950-e29ba180b028`. Creation also generated default personnel types `cd75c815-892c-4708-8a16-84e8fbb4de55`, `e17a34b3-0f58-4a5a-8cdc-7655b90bef77`, and `5f3f43d7-e206-4a61-9157-0eeb7b8743ae`. `/driver/sync` pushed 4 changes with no errors; contractor and personnel-type change logs then returned `count=0`.
  - Equipment proof added 2026-04-12: contractor editor add-equipment/personnel buttons now have contractor-scoped driver keys. After hot reload, the S21 inspector opened `contractor_add_equipment_button_43581791-5ca8-49ef-b738-7ed8d034943a`, added equipment `055910dd-b136-4f58-9a1c-91ca12f5c205` (`S21 Inspector Proof Loader 0412`), and `/driver/sync` pushed 1 change with no errors; equipment change log then returned `count=0`.
  - Screenshot evidence: `.codex/artifacts/2026-04-12/overnight_s21_verification/inspector_projects_permissions_s21.png`, `.codex/artifacts/2026-04-12/overnight_s21_verification/inspector_project_contractors_field_data_s21.png`, `.codex/artifacts/2026-04-12/overnight_s21_verification/inspector_project_contractors_add_controls_s21.png`, `.codex/artifacts/2026-04-12/overnight_s21_verification/inspector_added_contractor_s21.png`, `.codex/artifacts/2026-04-12/overnight_s21_verification/inspector_added_equipment_s21.png`.

- [x] Add focused auth/project-state regression coverage for role switch and assignment refresh.
  - Evidence: `lib/features/projects/presentation/providers/project_provider.dart:609` through `:665`; `AuthProvider` remains a central seam at CodeMunch importance rank 19; `ProjectProvider` is 611 lines with 58 methods.
  - Risk: `ProjectProvider.initWithAuth` wires auth listener, project loading, restoration, app-config refresh, and quick sync in one provider; stale selected project or role state could lock users into the wrong UI after role/assignment changes.
  - Code proof added 2026-04-12: `project_provider_sync_mode_test.dart` now covers same-company admin -> Office Technician -> admin role switching without losing the valid selected project, and sign-out/sign-in on a shared device clearing stale project state before reloading the next inspector's assignments. Existing `project_provider_test.dart` covers stale inspector selection repair after assignments arrive and after role changes.
  - Verification: `flutter test test\features\projects\presentation\providers\project_provider_sync_mode_test.dart test\features\projects\presentation\providers\project_provider_test.dart --reporter=compact` passed; the broader prerelease-focused provider/TODO/calculator/sync bundle passed; `flutter analyze test\features\projects\presentation\providers\project_provider_sync_mode_test.dart` passed; `dart run custom_lint` passed.

- [x] Prove sync repair failure policy surfaces a hard operational state.
  - Evidence: older audit blocker at extracted audit `:296`; central tracker marks repair hardening done at `.codex/plans/2026-04-11-prerelease-central-tracker.md:206`; implementation records failure metadata in `lib/features/sync/application/sync_state_repair_runner.dart:78` through `:89`.
  - Code proof added 2026-04-12: `SyncProvider` now reads failed repair metadata into top-level sync attention, `buildSyncStatusText()` returns `Repair required`, and `SyncStatusIcon` turns red with `Sync repair required`. Focused provider/widget tests passed.
  - Live S21 proof added 2026-04-12: `/diagnostics/sync_runtime` now exposes the same read-only `SyncStateFingerprint` used by the UI; S21 reported `schemaVersion=60`, `repairCatalogVersion=2026-04-11.1`, `appliedRepairCount=8`, and `failedRepairCount=0`.
  - Live Windows proof added 2026-04-12: seeded one failed repair metadata row directly into the live local SQLite `sync_metadata` table, verified `/diagnostics/sync_runtime` reported `failedRepairCount=1` and `latestFailedRepairJobId=synthetic_live_proof_2026_04_12`, captured the Windows sync dashboard in repair-required state, removed the seeded metadata, and verified diagnostics returned to `failedRepairCount=0`.
  - Done means: induced repair failure creates the failure metadata, sync diagnostics classify it as repair-required, and S21/Windows UI visibly reports repair-required until repair succeeds.

- [x] Keep official fixed-template AcroForm IDR as the release baseline unless adaptive IDR editability is proven.
  - Evidence: `.codex/plans/2026-04-11-final-s21-verification-adaptive-idr-plan.md:21`, `:57`, `:86`; `.codex/plans/2026-04-11-prerelease-central-tracker.md:990` through `:993`.
  - Risk: an adaptive IDR export that looks correct but is not editable would regress the release path.
  - Done means: fixed-template IDR remains the accepted baseline, or the adaptive export has explicit post-export editable AcroForm proof.
  - Proof added 2026-04-12: fixed-template IDR remains the release baseline; focused tests for "IDR export preserves editable field structure from the canonical template" and "IDR adaptive editable export removes only unused continuation page" passed.

- [x] Finish remaining S21 product proof for compact form/table-entry layout and ordering.
  - Evidence: `.codex/plans/2026-04-11-prerelease-central-tracker.md:477`, `:480`, `:994` through `:999`; `.codex/plans/2026-04-11-pay-app-form-final-verification-plan.md:487`.
  - Risk: user-facing S21 proof is mostly closed, but final layout stability and natural ordering checks are still listed as open.
  - Done means: quantity item ordering is verified in every affected list, keyboard/next-field progression remains clean, and compact form/table-entry controls do not reintroduce overlapping bubble headers or cramped controls.
  - Proof added 2026-04-12: S21 screenshots captured 0582B hub compact layout, 1174R compact layout, 1174R quantities/table route attempt, and 1126 compact layout; focused compact layout tests for hub content, 1174R two-column row composer, and active 1126 collapsed section header passed.
  - Quantity-ordering follow-up added 2026-04-12: `EntryQuantityOrdering` now gives entry cards and IDR materials the same stable bid-item-number ordering; `naturalCompare` now tie-breaks equal numeric segments with leading zeros; the pay-app workbook row/quantity alignment test locks row order by item number while applying quantities by bid-item ID.

## Architecture Cleanup / High-Priority If Touched Before Release

- [x] Split `SyncInitializer.create` and runtime wiring.
  - Evidence: `SyncCoordinatorBootstrapper` owns store/query/coordinator construction, `SyncInitializerRuntimeWiring` delegates transport and lifecycle setup to `SyncRuntimeTransportWiring` and `SyncLifecycleRuntimeWiring`; CodeMunch now reports `SyncInitializer.create` complexity 10, `SyncInitializerRuntimeWiring.wire` complexity 3, runtime lifecycle `wire` complexity 4, and runtime transport `wire` complexity 3.
  - Verification: focused analyzer passed for the split files; `flutter test test/features/sync/application/sync_initializer_runtime_wiring_test.dart test/features/sync/application/sync_initializer_bootstrapper_test.dart --reporter=compact` passed.

- [x] Promote `ProjectProvider` auth/listener responsibilities into a true controller owner.
  - Evidence: `project_provider.dart` is now a thin state shell with most behavior in focused files, and auth listener/selection restoration moved out of same-library extension code into `ProjectProviderAuthController`.
  - Code proof added 2026-04-12: `ProjectProviderAuthController` threads same-company role/user changes into provider state and reloads assignments so project gating repairs without relying only on `ProjectListScreen._refresh()`.
  - Verification: focused analyzer passed; project provider tests passed, including same-company role change into inspector gating.
  - Watchlist: filter/mutation/data-action behavior still uses same-library extension parts, but the high-risk auth/assignment seam now has a concrete controller owner.

- [x] Split `LocalSyncStore`.
  - Evidence: change-log cleanup/mutation, raw sync SQL, repair debug, and queue diagnostics were moved into focused store collaborators including `SyncChangeLogStore`, `SyncQueueDiagnosticsStore`, and `SyncRepairDebugStore`; `local_sync_store.dart` is now 529 lines rather than the earlier 724-line seam.
  - Verification: sync store collaborator tests and focused sync/provider tests passed in the current audit wave.

- [x] Split `ExportPayAppUseCase.execute`.
  - Evidence: export range/data collection, workbook build, and artifact persistence now live in `CollectPayAppExportDataUseCase`, `BuildPayAppExportWorkbookUseCase`, and `PersistPayAppExportUseCase`.
  - Evidence added 2026-04-12: `CollectPayAppExportDataUseCase` now delegates sorted bid-item loading, totals calculation, replacement-target loading, pay-application creation, and ledger assembly to helper methods. Focused collector tests and pay-app workbook tests passed.
  - Watchlist: CodeMunch's Dart outline still overcounts the collector helper boundaries in this file; source structure and focused tests are the authoritative proof for the split.

- [x] Split database upgrade repair methods by migration/version family.
  - Evidence: late migration steps and repair actions were extracted to `database_late_migration_steps.dart` and `database_upgrade_repair_actions.dart`.
  - Verification: database schema metadata/upgrade tests passed in the current audit wave.

- [x] Split `schema_verifier.dart` static schema metadata from verification behavior.
  - Evidence: static schema metadata moved to `database_schema_metadata.dart`; verifier behavior remains in `schema_verifier.dart`.
  - Evidence added 2026-04-12: verifier behavior is also split into table-existence, PRAGMA column loading, column verification, missing-column recording, and drift-recording helpers. `schema_verifier.dart` is now `291` lines.
  - Verification: focused schema verifier tests, platform schema parity, live Supabase schema contract, targeted analyzer, and custom lint passed in the current audit wave.

- [x] Continue PDF extraction stage decomposition.
  - Evidence: extraction workflows/helpers now include column detection, grid-line column detection, row parsing, item deduplication, numeric-like normalization, OCR default strategy building, post-processing stage runner, consistency rule applier, and grid-line map helpers.
  - Watchlist: extraction remains algorithmically dense, but the audit-targeted God-method seams and dependency cycles have been split.
  - Verification: focused OCR/grid-line/post-processing/contract tests and targeted analyzer passed.

- [x] Split driver data/shell handlers after prerelease gates are stable.
  - Evidence: data-sync route groups and interaction route groups moved into focused route files such as `driver_data_sync_handler_query_routes.dart`, `driver_data_sync_handler_mutation_routes.dart`, `driver_interaction_handler_navigation_routes.dart`, `driver_interaction_handler_gesture_routes.dart`, and system-route helpers.
  - Verification: focused driver route/data-sync tests passed in the current audit wave.

- [ ] Re-audit broad `shared.dart` barrel imports and shrink where practical.
  - Evidence: `.codex/plans/2026-04-11-prerelease-central-tracker.md:217`; `lib/shared/shared.dart:1` through `:10` exports datasources, domain, providers, repositories, preferences, testing keys, time provider, utils, validation, and widgets; imports are widespread.
  - Risk: broad shared imports hide dependency growth and can preserve stale abstractions.
  - Done means: new code imports direct shared surfaces; high-churn feature files migrate away from `shared/shared.dart` opportunistically; no broad mechanical churn during release-critical fixes.
  - 2026-04-12 progress: touched quantity-ordering files now import direct shared surfaces (`testing_keys` and `natural_sort`) instead of `shared/shared.dart`; the broader legacy import migration remains intentionally phased.

- [x] Split the new concrete/shape calculator tab after behavior stabilizes.
  - Evidence: `lib/features/calculator/presentation/widgets/concrete_calculator_tab.dart` is now a 490-line state coordinator; shape/trench input cards live in `concrete_shape_input_cards.dart`, and layered equation/result rendering lives in `concrete_layered_result_card.dart`.
  - Verification: focused analyzer passed; shape/trench math tests passed; S21 hot-reload and calculator-tab screenshot passed after the split.
  - Watchlist: the tab is still the calculator state owner, but shape-card UI and layered result rendering no longer live in the main tab file.

## Watchlist / Deferred Cleanup

- [ ] Keep `Logger` central seam watchlisted.
  - Evidence: `.codex/plans/2026-04-11-prerelease-central-tracker.md:460`; CodeMunch importance rank 1, in-degree 306.
  - Risk: central by design; do not split during prerelease unless logging bugs appear.
  - Done means: sanitizer/reporting transports stay isolated; no feature logic enters logger.

- [ ] Keep `DatabaseService`, `DailyEntry`, `SyncRegistry`, and `BidItem` on watchlist.
  - Evidence: `.codex/plans/2026-04-11-prerelease-central-tracker.md:461`, `:464`, `:465`, `:466`; CodeMunch importance ranks include `DatabaseService` rank 9, `DailyEntry` rank 13, `SyncRegistry` rank 25, `BidItem` rank 27.
  - Risk: central domain seams, not necessarily current blockers.
  - Done means: avoid widening these APIs during final release work; add targeted regression tests when touched.

## Closed/Verified From This Audit

- [x] Sync startup runtime wiring is now decomposed into focused collaborators.
  - Evidence: `SyncInitializerRuntimeWiring` delegates assignment backfill, transport setup, and lifecycle/startup scheduling to smaller owners; CodeMunch reports low complexity for each `wire` method.
  - Verification: focused analyzer passed; sync initializer runtime/bootstrapper tests passed.

- [x] Same-company auth role changes now update project-provider gating.
  - Evidence: `ProjectProvider.initWithAuth` updates current user id/role on auth notifications and reloads assignments when the user or role changes, so an admin/Office Technician/inspector role flip no longer depends only on `ProjectListScreen._refresh()`.
  - Verification: `project_provider_sync_mode_test.dart` now covers same-company role change into inspector gating; focused project-provider tests passed.

- [x] Sync repair-required metadata now reaches the top-level sync UI.
  - Evidence: `SyncProvider` reads failed repair count from `SyncStateFingerprint`; status text and `SyncStatusIcon` surface repair-required attention before idle/synced messaging.
  - Verification: sync provider and sync status icon tests cover the repair-required state; focused tests passed.

- [x] Current extracted architecture seams are recorded.
  - 2026-04-12 reconfirmation: CodeMunch reports `cycle_count=0`; `SyncInitializer.create` is `medium`, `ExportPayAppUseCase.execute` is `medium`, `DatabaseUpgradeRepairs.applyLateMigrations` is `low`, `ColumnDetectorV2.detect` is `low`, and `PdfDataBuilder.generate` is `medium`. Current release watchlist is centrality/API ownership, not active God-method blockers.
  - Evidence: new extracted owners include `SoftDeleteProjectCascadeSupport`, `FileSyncThreePhaseWorkflow`, `PdfImportWorkflow`, `PdfExtractionProgressDialog`, `PostProcessingStageRunner`, `PostConsistencyRuleApplier`, `AutoFillHeaderDataBuilder`, `OcrDefaultPageRecognitionStrategyBuilder`, and `GridLinesMapHelpers`.
  - Verification: focused soft-delete, file-sync, PDF/OCR/post-processing, project-provider, and form auto-fill tests passed in this audit wave.

- [x] Current app/runtime scan found no `MOCK_AUTH` seam in `lib`, `supabase`, or `integration_test`.
  - Evidence: `rg -n "MOCK_AUTH|mock_auth|mock auth|MockAuth" lib supabase integration_test --glob "!**/*.g.dart"` returned no matches; test-only `MockAuthProvider` and `MockAuthService` classes remain in `test/`.

- [x] Pay app Quantities workbook export lane is closed unless a regression is found.
  - Evidence: central tracker status table marks Quantities workbook `PASS`; later work restored canonical formatting, formulas, pane behavior on Windows, and S21 mobile-view limitations are documented as Excel limitations rather than export defects.

- [x] Contractor comparison, 1126, 1174R, 0582B, Daily Entry/IDR, photo-name edit, personnel picker, calculators, and sync/background resume lanes are closed unless a regression is found.
  - Evidence: central tracker status table marks these lanes `PASS`; do not reopen older source-doc `OPEN` entries unless new live proof fails.

- [x] PDF extraction dependency cycles are no longer open.
  - Evidence: CodeMunch `get_dependency_cycles` returned `cycle_count=0`; central tracker `.codex/plans/2026-04-11-prerelease-central-tracker.md:413` through `:419`.

- [x] Old stale `FormsListScreen` driver surface appears closed.
  - Evidence: CodeMunch/local search found only negative assertions in `test/core/driver/driver_route_contract_test.dart`; no production `FormsListScreen` registration.

- [x] Old sign-out fail-soft auth blocker appears fixed in current source.
  - Evidence: `lib/features/auth/presentation/providers/auth_provider_auth_actions.dart:71` through `:84` only clears local auth state when `SignOutUseCase.execute()` succeeds; `lib/features/auth/domain/usecases/sign_out_use_case.dart:46` through `:55` returns false on auth-service sign-out failure.

- [x] Old inactivity fail-open blocker appears fixed in current source.
  - Evidence: `lib/features/auth/domain/usecases/check_inactivity_use_case.dart:25` through `:44` returns true on untrusted secure-storage read/parse/write errors.

- [x] Driver/debug server release exposure has layered guards.
  - Evidence: `lib/core/driver/driver_server.dart:6` through `:15`, `:113` through `:126`; `lib/core/driver/driver_data_sync_handler.dart:320` through `:345`; `tools/build.ps1` blocks `DEBUG_SERVER=true` in release builds.

## 2026-04-12 Addendum - Auth And Report Review

- [x] Reconfirmed the auth/session seam locally after the final prerelease audit pass.
  - Evidence: runtime auth state still threads through `AuthProvider`, `AuthService`, `LoadProfileUseCase`, `AppRedirect`, sync lifecycle/runtime wiring, and feature providers that receive `authProvider.userId` / permission getters. Local search found no `MOCK_AUTH`, `mock_auth`, `mock auth`, or `MockAuth` runtime seam under `lib`, `supabase`, or `integration_test`.
  - Cleanup: removed the duplicate class-body `AuthProvider.loadUserProfile` / `refreshUserProfile` implementation so the extracted company/profile action part is the single profile-load owner.

- [ ] Complete S21 live proof for the report review SESC edit path.
  - Code fix: review-row edit now carries a focused editor target; `SESC Measures` opens Safety & Site Conditions, enters edit mode when the user can edit the entry, and focuses the SESC field.
  - Local verification: focused `flutter analyze` over the touched auth/entry route/editor/review files passed; `dart run custom_lint` passed; `flutter test test/features/entries/presentation/screens/entry_editor_route_binding_test.dart --reporter=compact` passed; auth/router slice and project-provider role-switch slices passed.
  - Remaining evidence: when the S21 driver or `flutter run` endpoint is alive, run inspector draft review -> tap SESC edit -> verify field edit/save -> Mark Ready/Review -> submit/sync with screenshot/log proof.

- [ ] Improve Mark Ready/Review preview density after blockers.
  - Scope: compact review preview is still tight and hard to scan by section; keep this as a last UX nitpick so it does not disrupt the report-submit flow during auth/sync closure.
