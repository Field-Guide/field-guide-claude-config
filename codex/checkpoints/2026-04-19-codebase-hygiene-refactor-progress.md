# Codebase Hygiene Refactor Progress

Date: 2026-04-22
Spec: `.codex/plans/2026-04-19-codebase-hygiene-refactor-todo-spec.md`
Branch: `gocr-integration`
Status: complete

## 2026-04-22 Runtime Re-baseline

### Lane 0: Architecture Guardrails

Status: complete

- Landed and verified:
  - `core_must_not_import_feature_presentation`
  - `data_must_not_import_presentation`
  - `domain_must_be_pure_dart`
- Removed the stale permanent allowlist for `lib/core/router/shell_banners.dart`
  after moving shell-banner ownership out of `core/router`.
- Current permanent exceptions are back to composition-root, driver-owned, and
  route-adapter seams only.

### Lane 1: Router/Auth Boundary Split

Status: complete

- `RouteAccessSnapshot` now captures from:
  - `AuthAccessSnapshot`
  - `AppConfigAccessSnapshot`
  - `ConsentAccessSnapshot`
- `RouteAccessController` listens to source seams instead of concrete provider
  classes.
- `lib/core/router/autoroute/pages/pdf_auto_route_pages.dart` no longer reads
  auth/provider state directly.
- `ScaffoldWithNavBar` is now provider-agnostic.
- The old shell banner coupling was fully removed from `core/router`:
  - provider-backed banner ownership moved into
    `lib/features/sync/presentation/widgets/primary_shell_banner_stack.dart`
  - project-selection shell gating moved into
    `lib/features/projects/presentation/widgets/primary_shell_scaffold_adapter.dart`
  - `AutoPrimaryShellPage` now only composes widgets and tab routing; it does
    not read feature providers directly.

### Lane 2: Data and Domain Boundary Cleanup

Status: complete

- `AuthProviderSessionService` is replaced by
  `AuthSyncContextSessionService`.
- form screen registration moved out of `form_seed_service.dart`.
- sync domain files are on pure-Dart imports; no Flutter/plugin imports remain
  under `lib/features/**/domain/`.
- secure-storage access is behind `SecureStorageGateway`.
- support-ticket platform data is now passed in via
  `SubmitSupportTicketCommand.platform`.

### Lane 3: Live Production Hotspots

Status: complete

- Completed earlier in this branch and preserved as baseline:
  - router/auth snapshot split
  - auth session/storage boundary cleanup
  - form registration extraction
  - sync value-type purity cleanup
  - push planner/executor split
  - PDF extraction hotspot decomposition
  - model `copyWith` sentinel migration
  - logger follow-up from file-wide suppressions to localized ignores only
- Completed in this slice:
  - replaced the legacy PDF and M&P extraction-progress stack with the shared
    `ImportProgressDialog` / `ImportProgressSnapshot` contract
  - deleted the old extraction progress infrastructure:
    - `ExtractionJobRunner`
    - `ExtractionProgress`
    - `ExtractionBanner`
    - `ExtractionDetailSheet`
    - runner/result/progress tests tied only to that path
  - fixed the hung import-dialog widget suite by removing the router-host test
    harness and replacing it with a lightweight `AppNavigatorScope` +
    `MaterialApp` harness

### Lane 4: Whole-Repo Secondary Queue

Status: complete

- Oversized integration diagnostics were decomposed without changing the test
  entrypoints:
  - `test/features/forms/services/form_export_mapping_matrix_test.dart`
    dropped from 2339 LOC to 709 LOC by moving the IDR, 0582B, 1126, and
    1174R matrix bodies into focused `part` files.
  - `test/features/sync/application/sync_state_repair_runner_test.dart`
    dropped from 1246 LOC to 227 LOC by moving queue-residue and conflict
    repair assertions into focused `part` files.
- The shared sync harness helper was decomposed while preserving the
  `SyncTestData.*` API used across the suite:
  - `test/helpers/sync/sync_test_data.dart` dropped from 732 LOC to 476 LOC
    by moving table-factory and FK-seed ownership into domain-specific part
    files.
- Shared testing-key facade ownership moved off the handwritten monolith:
  - `lib/shared/testing_keys/testing_keys.dart` dropped from 1565 LOC to 20 LOC
    and is now a thin compatibility library.
  - the compatibility `TestingKeys` class now comes from the generated
    `generated/testing_keys_facade.g.dart`, owned by
    `tools/gen-keys/generate_keys.dart`.
  - `dart run tools/gen-keys/generate_keys.dart --check` is green, proving the
    new facade path is idempotent.
- Route/router secondary audit:
  - no stale GoRouter or legacy route-surface mirroring remains in the active
    router tests; current coverage stays on `RouteAccessSnapshot`,
    `RouteAccessController`, and `AppAutoRouter`.
- Live app code still has no explicit imports of
  `shared/testing_keys/testing_keys.dart`; the compatibility facade remains for
  older tests only.

## Audit Outcome

### Complete

- runtime routing/auth seams
- runtime data/domain purity seams
- runtime hotspot refactors
- shared import dialog rewrite
- Lane 4 secondary queue
- repo-wide `flutter analyze`
- repo-wide `dart run custom_lint`

### Superseded

- the smaller “PDF import workflow/progress hardening” remainder is replaced by
  the shared import-dialog rewrite and legacy stack deletion
- stale GoRouter/form-routes decomposition language is no longer controlling
  for the current tree

### Still Open

- none

## Verification

- `flutter analyze`
- `dart run custom_lint`
- `dart run tools/gen-keys/generate_keys.dart --check`
- `flutter test test/core/router/scaffold_with_nav_bar_test.dart test/core/router/autoroute/app_auto_router_test.dart test/core/router/route_access_snapshot_test.dart test/core/router/route_access_controller_test.dart test/core/router/route_access_policy_test.dart test/features/pdf/presentation/helpers/import_progress_dialog_test.dart`
  - 34 tests passed under active watchdog monitoring
- `flutter test test/features/forms/services/form_export_mapping_matrix_test.dart test/features/sync/application/sync_state_repair_runner_test.dart test/features/sync/triggers/change_log_trigger_test.dart`
  - 83 tests passed under active watchdog monitoring
- `dart test fg_lint_packages/field_guide_lints/test/architecture/core_must_not_import_feature_presentation_test.dart`
