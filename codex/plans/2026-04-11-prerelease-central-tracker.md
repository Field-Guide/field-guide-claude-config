# 2026-04-11 Pre-Release Central Tracker

Canonical tracker for the final pre-release hardening wave. This replaces the
old beta central tracker after auditing the active Codex plans, the 2026-04-10
pre-production/Notion audit, the downloaded audit zip, the 2026-04-11 evidence
manifest, and a refreshed CodeMunch structural audit.

## Operating Rules

- Do not use `MOCK_AUTH`; auth and sync verification must use real sessions and
  real backend state.
- Use the Samsung S21 for primary mobile verification: forms, PDF
  preview/export, Android storage/attachments, background/resume, and sync
  recovery.
- Use the Windows build/device as a second real client for faster account,
  admin, Office Technician, Engineer, and Inspector role verification. Windows
  proof can supplement but not replace S21 proof for mobile-specific behavior.
- Fix root analyzer and quality-gate honesty before continuing the forms lane.
- Add or tighten custom lint rules for structural boundaries before relying on
  manual review to keep the architecture intact.
- Forms validation remains the first product verification lane after the gate
  is trustworthy.

## Current Status Snapshot

| Lane | Status | Notes |
| --- | --- | --- |
| Pay app company `Quantities` workbook | PASS | Workbook generation, exact S21 replacement export, Android Excel open proof, public Android copies, and formatting/spacing are proven. The direct Pay App artifact and saved Springfield project workbook both preserve the Windows/canonical frozen-left view at the first date pane (`G1`); Android Excel cannot comfortably pan this wide frozen layout on the S21, which is accepted as a mobile Excel limitation for this format. Both are one company-format `Quantities` sheet with 131/131 bid-item rows, active pay apps #1-#5, continuous horizontal date columns through `2026-04-18`, header rows expanded to avoid clipping, logo/drawing parts, valid OOXML formulas for editable quantity totals, and no old `G703 Ledger` sheet. |
| Contractor comparison and quantity ordering | PASS | Excel/OCR import parity, exported reports, lazy layout, and natural item ordering have device evidence. 2026-04-12 follow-up locked equal-numeric item-number ordering, entry-quantity display ordering, IDR materials ordering, and pay-app workbook row/quantity alignment with focused tests. |
| 1126 all-cell verification | PASS | Device proof records seven SESC rows, signature completion, editable export, read-only preview, field-count equality, and no-double-write evidence. |
| 1174R all-cell verification | PASS | Device proof records full printed row capacity, read-only preview, editable export, field-count equality, and no-double-write evidence. |
| 0582B all-cell verification | PASS | Device export after the missing-field rerun preserves 269/269 fields, proves agency/company, remarks, signature field preservation, 20/10 weights, chart/operating standards, F/G/H values, and no-double-write occurrence counts. |
| Daily Entry / IDR all-cell verification | PASS | S21 exports prove five contractor blocks, five material quantities, continuation text fitted into AcroForm fields, form attachments, photo attachments, editable fields, field-count/name preservation, and `yyyy-MM-dd Photo (<name>) <job number>.pdf` filename policy. Latest post-red-screen retest writes the full IDR/form/photo bundle without Flutter assertion, logger recursion, or ANR. |
| Office Technician role | PASS | Remote schema/RPC migration, Windows admin UI role update proof, S21 Office Technician create-project/assignment proof, S21 review-comment proof, admin-control negative proof, and role restoration are complete against real backend state. |
| Review-comment TODOs | PASS | Local implementation/tests/UI smoke, remote schema migration, S21 Office Technician review-comment creation into remote `todo_items`, post-fix S21 clean sync, S21 inspector Springfield assignment/data backfill, inspector TODO filter visibility, dashboard notification clearing, and completion sync are proven. |
| Photo name edit | PASS | S21 live-run proof verifies remote-backed photo filename/notes metadata editing, clean sync, DB proof, screenshots, focused test, and targeted analyzer. |
| Personnel picker | PASS | S21 live-run proof verifies contractor edit mode, personnel counters, and the contained personnel-type manager dialog on the compact S21 viewport without data mutation or runtime errors. |
| Calculators | PASS | HMA Yield/weighback and the unified entry Quantity Calculator were verified on the S21 real-auth driver build; quantity calculator exposes no HMA unit/tab and supports unit switching for the generic Calculator flow. |
| Sync/background resume | PASS | Current-source S21 build verifies controlled blocked-queue poison survives warm background/resume without connectivity breakage, repair clears it to zero, real sync stays clean, and warm resume returns ready in under 400 ms. |
| Schema drift guardrails | PASS | Live Supabase drift is now blocked by `scripts/verify_live_supabase_schema_contract.py` in the quality gate, and local Android/iOS/Windows SQLite schema divergence is blocked by `scripts/verify_database_schema_platform_parity.py`. |
| Final completeness review | OPEN | Requires a separate completeness-agent review against this tracker after implementation and verification. |

## Gate Honesty And Analyzer First

- [x] Re-review the 2026-04-10 Notion/pre-production audit before changing
  analyzer/lint configuration.
- [x] Fix root `flutter analyze` so the result represents app/repo readiness,
  not vendored third-party noise.
- [x] Keep `flutter analyze lib test` green.
- [x] Fix CI custom-lint weakness by removing or replacing the
  `dart run custom_lint ... || true` false-pass pattern.
- [x] Ensure custom-lint process failures fail the gate separately from normal
  lint violations.
- [x] Re-run and record `flutter analyze`, `flutter analyze lib test`, and
  `dart run custom_lint`.

Verification:

- `flutter analyze`: PASS, no issues found.
- `flutter analyze lib test`: PASS, no issues found.
- `dart run custom_lint`: PASS, no issues found.
- CI custom-lint step now captures the process exit code instead of blanket
  `|| true`, so tool failures are no longer silently treated as success.
- Root analysis now excludes vendored `third_party/**` patched packages so the
  analyzer gate reports Field Guide readiness.

## Custom Lint Enforcement Backlog

Use these to lock in the structural changes instead of relying on memory.

- [x] Add or tighten a lint that prevents direct auth/session state mutation
  outside approved auth owners.
- [x] Add or tighten a lint that prevents role/permission checks from being
  scattered outside centralized role/profile/provider permission getters.
- [x] Add or tighten a lint that prevents sync repair failures from being
  swallowed without an explicit policy state.
- [x] Add or tighten a lint that prevents direct PDF template/output ownership
  outside approved PDF owners.
- [x] Add or tighten a lint that prevents heavy collapsed form-section bodies
  from staying alive in standardized form entry wizards.
- [x] Add or tighten a lint/CI check for oversized UI endpoints/providers after
  the current refactor pass establishes practical thresholds.
- [x] Add tests for any new lint rule in the custom lint package and run
  `dart run custom_lint` after each rule is wired.

Current lint coverage:

- Existing: `no_animated_crossfade_in_form_workflows`.
- Existing: `max_ui_file_length` and `max_ui_callable_length`.
- Existing: `no_direct_idr_template_usage`, `no_direct_printing_output_usage`,
  `no_direct_form_pdf_actions_outside_owner`, and
  `no_direct_entry_pdf_actions_outside_owner`.
- Existing: `no_sync_state_repair_job_outside_repairs_directory` and
  `no_sync_state_repair_runner_instantiation_outside_approved_owners`.
- Added: `no_mock_auth_references`, targeting banned `MOCK_AUTH`,
  `mock_auth`, and mock-autologin runtime/build seam references without
  blocking ordinary isolated unit-test mock classes.
- Added: `no_auth_session_state_mutation_outside_provider`, keeping
  `_currentUser`, `_userProfile`, and `_company` mutation inside AuthProvider
  owner files.
- Added: `no_direct_user_role_permission_checks_outside_owners`, keeping direct
  `UserRole` equality checks out of arbitrary UI files. The first violation was
  removed from `project_list_tab_views.dart` by routing through
  `AuthProvider.isInspector`.
- Existing PDF lint ownership covers template/output boundaries:
  `no_direct_idr_template_usage`, `no_direct_printing_output_usage`,
  `no_direct_form_pdf_actions_outside_owner`,
  `no_direct_entry_pdf_actions_outside_owner`, and
  `no_direct_export_artifact_file_service_usage_outside_owner`.
- Added: `sync_repair_failure_requires_policy_state`, keeping
  `SyncStateRepairRunner` catch blocks from continuing unless they persist
  explicit repair-failure policy state through `failureMetadataPrefix` or an
  approved repair-failure recorder.
- Added: `no_immediate_dialog_controller_dispose_in_screens`, preventing
  feature presentation screens from disposing a local `TextEditingController`
  immediately after an awaited `AppDialog.show()` or `AppDialog.showCustom()`;
  use `AppDialog.disposeTextEditingControllerAfterExit(controller)` so dialog
  reverse animations cannot rebuild with a disposed controller.
- Added CI schema guardrails: `verify_live_supabase_schema_contract.py` checks
  the live Supabase public schema against app sync registry/metadata when
  `SUPABASE_DATABASE_URL` is present, and
  `verify_database_schema_platform_parity.py` blocks platform-specific local
  database schema/migration branches for Android, iOS, and Windows.

## Forms First Verification

- [x] Finish Daily Entry/IDR full-capacity S21 verification with realistic
  Springfield demo data.
- [x] IDR must prove five active contractors and at least five equipment records
  per contractor can be represented correctly.
- [x] IDR activity continuation rows must stay inside the intended AcroForm
  fields and not write outside the activity field area.
- [x] IDR materials section must show five different quantities used for that
  day.
- [x] IDR must include signature, agency/company, remarks, photos, and attached
  forms.
- [x] IDR attachment filenames must follow the exported form label and
  `yyyy-MM-dd Photo ({user supplied photo name}) {job number}.pdf` for photos.
- [x] Final all-form pass must cover IDR, 0582B, 1126, and 1174R.
- [x] For every form, verify preview and exported PDF: all intended cells are
  filled via UI-driven interactions, no double-written text, editable AcroForm
  fields are preserved, field names and field counts match the template,
  original field formatting is preserved as closely as the template allows,
  preview is read-only with pan/zoom, and exported artifacts are inspected.

## Office Technician And Review Comments

- [x] Apply or confirm remote Supabase migration
  `20260411040000_add_office_technician_role.sql`.
- [x] Apply or confirm remote Supabase migration
  `20260411040500_todo_review_comment_metadata.sql`.
- [x] Historical blocker from earlier on 2026-04-11: `supabase migration list`
  reached the remote pooler but failed SASL auth even when
  `SUPABASE_DB_PASSWORD` was injected from local env files; service-role REST
  schema checks also returned `401 Invalid API key`. This blocker is superseded
  by the credential-refresh proof below.
- [x] Rechecked remote migration path after credential refresh on 2026-04-11:
  service-role REST checks pass, `.env.secret` `DATABASE_URL` works with
  `supabase ... --db-url`, and the two target migrations are now applied and
  recorded in remote migration history. Remote proof shows
  `user_profiles_role_check` includes `office_technician`,
  `is_admin_or_engineer()`, `approve_join_request()`, and
  `update_member_role()` mention `office_technician`, and `todo_items` has
  `assigned_to_user_id`, `source_type`, `source_id`,
  `idx_todo_items_assigned_to`, and `idx_todo_items_source`.
- [x] Backend admin-session role update proof on 2026-04-11: a real admin
  password session called production `update_member_role`, changed the
  inspector profile from `inspector` to `office_technician`, verified the
  remote role, then restored it to `inspector`. No secrets were printed.
- [x] On Windows, verify admin can approve/update a user as Office Technician.
  2026-04-12 live proof: Windows admin dashboard opened the inspector member
  detail, selected `office_technician`, saved through production
  `update_member_role`, verified remote and local Windows role state, then
  restored the profile to `inspector`.
- [x] On Windows, verify Office Technician can create projects and assign
  inspectors but cannot access admin-only account controls.
- [x] On S21, verify Office Technician can create projects, assign inspectors,
  and review inspector entries. Partial S21 proof on 2026-04-11 shows the
  temporary Office Technician profile hides `settings_admin_dashboard_tile`,
  exposes `project_create_button`, can open existing project assignments at
  `/project/75ae3283-d4b2-4035-ba2f-7b4adb018199/edit?tab=4`, and exposes
  `report_menu_button` for inspector entry review.
  2026-04-12 live proof: S21 Office Technician created project
  `22600af9-fea4-4a96-bf94-c4e143b9089a`, assigned both admin and inspector
  users, proved no admin dashboard tile after the Windows role update, and
  created review-comment TODO `2c4b834d-0471-41be-8320-1f9bac11a2d6` for an
  inspector entry through the real review-comment dialog.
- [x] On S21, verify Engineer and Office Technician can leave review comments
  on inspector entries.
- [x] On S21, verify review comments sync into inspector TODOs, appear under the
  review-comments filter, drive the dashboard notification card, and clear after
  completion. Partial 2026-04-11 proof created remote `todo_items` row
  `b8d995ad-0faa-4e8a-8c49-5423c0556809` with
  `source_type=review_comment`, `source_id` equal to entry
  `fdd89344-165d-4001-ae64-e7a933659028`, assigned to inspector
  `d1ca900e-d880-4915-9950-e29ba180b028`, and created by the temporary
  Office Technician session. 2026-04-12 S21 proof completed both review-comment
  proof TODOs through the checkbox UI, verified local `is_completed=1` for
  `b8d995ad-0faa-4e8a-8c49-5423c0556809` and
  `c7e8e431-8342-43b5-932c-6cf8ebdfc56f`, pushed both changes with
  `/driver/sync` (`pushed=2`, no errors), verified `todo_items` change log
  `count=0`, and verified the dashboard no longer contained the review-comment
  attention text. Screenshots:
  `.codex/artifacts/2026-04-12/overnight_s21_verification/todos_after_auth_project_tests.png`,
  `.codex/artifacts/2026-04-12/overnight_s21_verification/review_comments_completed_s21.png`,
  and `.codex/artifacts/2026-04-12/overnight_s21_verification/dashboard_after_review_comment_clear.png`.
- [x] S21 shared-device inspector assignment/data sync regression fixed and
  verified on 2026-04-12. The inspector remained assigned to Springfield
  (`75ae3283-d4b2-4035-ba2f-7b4adb018199`), but a stale device-global
  `manual_project_removal_<projectId>` marker from prior admin/inspector
  testing blocked `synced_projects` enrollment. Manual removal markers are now
  user-scoped, legacy global markers no longer block a signed-in user's
  assignment backfill, and the S21 proof shows Springfield enrolled locally
  with 29 active Springfield `daily_entries`, including `2026-04-12` through
  `2026-04-18`.
- [x] Verify Inspectors can add contractors, personnel, and equipment to
  project/field data, but still cannot create/delete/archive projects. S21
  inspector proof on 2026-04-12 shows Springfield visible on `/projects`, with
  `project_create_button`, `project_archive_toggle_<projectId>`, and database
  delete sheet absent; project-level contractor import remains hidden. The same
  inspector created contractor `43581791-5ca8-49ef-b738-7ed8d034943a`
  (`S21 Inspector Proof Contractor 0412`) through the UI, generated default
  personnel types `cd75c815-892c-4708-8a16-84e8fbb4de55`,
  `e17a34b3-0f58-4a5a-8cdc-7655b90bef77`, and
  `5f3f43d7-e206-4a61-9157-0eeb7b8743ae`, added equipment
  `055910dd-b136-4f58-9a1c-91ca12f5c205` (`S21 Inspector Proof Loader 0412`),
  and synced all five inserts cleanly with zero remaining queue/change-log
  rows.

## Auth, Sync, DB, And Pre-Production Blockers

- [x] Fix sign-out fail-soft behavior so local auth state cannot silently
  diverge from backend session state.
- [x] Fix inactivity timeout fail-open behavior with an explicit product policy
  and tests.
- [x] Fix sync repair fail-soft behavior with an explicit recovery/quarantine/
  repair-required policy and tests.
- [x] Verify bad-sync/background-resume recovery on S21.
- [x] Reconcile schema/migration tests through runtime DB version `60`.
- [x] Restore full `flutter test` credibility or document a tiny intentional
  exception set with owners and follow-up IDs.
- [x] Re-audit stale `FormsListScreen` compatibility surface after
  higher-priority gates are green. Removed the unregistered legacy
  `FormsListScreen`, its controller scope, response tile, stale exports, stale
  test-only logic, and obsolete testing keys while preserving the current
  `FormGalleryScreen` route contract.
- [ ] Re-audit broad `shared.dart` barrel exports after higher-priority gates
  are green. Current audit still shows many legacy imports across UI surfaces,
  so this needs a deliberate allowlist or phased direct-import migration rather
  than a risky one-shot deletion.

Local auth hardening verification:

- `AuthProvider.signOut()` now preserves current user/profile/company state and
  sets `Failed to sign out` when backend sign-out fails, instead of clearing
  local auth state into a split-session condition.
- `CheckInactivityUseCase.execute()` now fails closed on secure-storage
  read/parse/initial-write failures by returning timed-out/force-reauth.
- `StartupGate.run()` no longer refreshes `last_active_at` after the timeout
  path or after auth is no longer active.
- `SyncStateRepairRunner` now writes explicit
  `sync_repair_failure::<job id>` metadata when a repair job fails and clears
  that marker after the same job later succeeds.
- Sync diagnostics now surface `failedRepairCount`,
  `latestFailedRepairJobId`, and `latestRepairFailureAt`; the Sync Status issue
  report classifies this as `sync_repair_required` so the state is
  operator-visible instead of log-only.
- Current-source S21 verification on `RFCNC0Y975L` installed APK SHA-256
  `67392B77C3E3F8FDB321702F3FDD98FB1C565D0CAD6F1D8969DFB5D5468F108F`,
  `lastUpdateTime=2026-04-11 15:43:38`, driver port `4948`.
- S21 controlled stale-state cycle 1: injected
  `project_assignment_residue`, observed `blockedCount=1`, ran
  `/driver/run-sync-repairs`, then observed `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`.
- S21 controlled stale-state/background cycle 2: injected
  `builtin_form_change_log`, backgrounded the app, resumed to `/projects` in
  `377 ms` while `blockedCount=1` remained visible, ran repairs, then observed
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`.
- S21 real sync after repairs returned `success=true`, `pushed=0`, `pulled=0`,
  `errors=[]`, and final status `lastSyncTime=2026-04-11T19:47:22.593719Z`.
- S21 evidence artifacts: `.codex/artifacts/2026-04-11/s21_after_auth_sync_hardening_resume_clean.png`,
  `.codex/artifacts/2026-04-11/s21_after_bad_sync_resume_repair_clean.png`,
  `.codex/artifacts/2026-04-11/s21_auth_sync_hardening_verification_logcat.txt`,
  `.codex/artifacts/2026-04-11/s21_auth_sync_hardening_screen_contract.json`,
  `.codex/artifacts/2026-04-11/s21_auth_sync_hardening_sync_transport.json`,
  and `.codex/artifacts/2026-04-11/s21_auth_sync_hardening_sync_status.json`.
- Focused verification on 2026-04-11: `flutter analyze` for the changed auth
  and sync repair files passed; `flutter test
  test/features/auth/domain/use_cases/sign_out_use_case_test.dart
  test/features/auth/domain/use_cases/check_inactivity_use_case_test.dart
  test/features/auth/presentation/providers/auth_provider_test.dart --reporter
  expanded` passed; `flutter test
  test/features/sync/application/sync_state_repair_runner_test.dart
  test/features/sync/application/sync_query_service_test.dart
  test/features/sync/presentation/support/sync_issue_report_draft_test.dart
  --reporter expanded` passed.
- Sync repair policy lint verification on 2026-04-11: `dart test
  test/sync_integrity/sync_repair_failure_requires_policy_state_test.dart`
  passed in `fg_lint_packages/field_guide_lints`; full
  `fg_lint_packages/field_guide_lints` `dart test` passed; root
  `flutter analyze lib test` and `dart run custom_lint` passed.

## CodeMunch Structural Audit Backlog

### CodeMunch Toolchain Recovery

- [x] Investigate the `Transport closed` MCP failure before continuing
  CodeMunch-backed structural verification.
- [x] Confirmed Codex config points to
  `C:\Users\rseba\Projects\jcodemunch-mcp\.venv\Scripts\python.exe` with
  `args = ["-m", "jcodemunch_mcp"]`.
- [x] Confirmed the local CodeMunch CLI starts on the maintained fork after
  preserving `src/jcodemunch_mcp/__main__.py`; both
  `uv run python -m jcodemunch_mcp --help` and
  `.venv\Scripts\python.exe -m jcodemunch_mcp --help` pass.
- [x] Preserved the local fork work in
  `C:\Users\rseba\Projects\jcodemunch-mcp` with commit `62901e4`
  (`fix: preserve mcp module startup and kotlin calls`) and pushed it to
  `RobertoChavez2433/dart_tree_sitter_fork` branch
  `feat/dart-first-class-support-2026-04-11-safety`.
- [x] Updated the Dart-support branch onto upstream CodeMunch `v1.34.0`
  (`MCP progress notifications for long-running tools`) with merge commit
  `e8a63fe` and pushed it to
  `RobertoChavez2433/dart_tree_sitter_fork` branch
  `feat/dart-first-class-support-v1.34.0`.
- [x] CodeMunch fork test gates on the v1.34 update branch:
  `uv run python -m pytest tests\test_dart_imports.py
  tests\test_languages.py::test_parse_dart
  tests\test_hardening.py::TestDeterminism::test_deterministic_ids_and_hashes -q`
  passed `28` tests; `uv run python -m pytest tests\test_languages.py -k
  "kotlin" -q` passed `1`; `uv run python -m pytest tests\test_progress.py
  tests\test_server.py -q` passed `64`; full
  `uv run python -m pytest -q` passed `2588` with `9` skipped.
- [x] Direct CodeMunch CLI indexing against Field Guide Dart sources works on
  the v1.34 update branch:
  `uv run python -m jcodemunch_mcp index
  C:\Users\rseba\Projects\Field_Guide_App --no-ai-summaries --extra-ignore
  build/ .dart_tool/ *.g.dart *.freezed.dart` returned `success=true`, repo
  `local/Field_Guide_App-37debbe5`, `symbol_count=14916`, and completed in
  `8.54` seconds.
- [x] After a session restart, live MCP core tools worked again:
  `jcodemunch/list_repos`, `search_symbols`, `search_text`, `get_file_tree`,
  `get_ranked_context`, `get_dependency_cycles`, `get_symbol_complexity`,
  `get_context_bundle`, `get_call_hierarchy`, `find_references`,
  `get_hotspots`, and `get_repo_outline` returned successfully against
  `local/Field_Guide_App-37debbe5`.
- [x] Found and fixed a v1.34 dead-code regression in the CodeMunch fork:
  `get_dead_code_v2.py` imported `ENTRY_POINT_DECORATOR_RE` but referenced
  `_ENTRY_POINT_DECORATOR_RE`, causing `get_dead_code_v2` and
  `get_repo_health` to fail on decorated symbols. Fixed in fork commit
  `7c830f8` (`fix: prevent dead code decorator crash`) and pushed to
  `feat/dart-first-class-support-v1.34.0`.
- [x] CodeMunch fork test gates after that fix: focused
  `uv run python -m pytest tests\test_dead_code_v2.py tests\test_repo_health.py
  tests\test_parse_warnings.py -q` passed `28`; full
  `uv run python -m pytest -q` passed `2589` with `9` skipped.
- [x] Direct Field Guide tool smoke matrix after the fix passed for `26/26`
  checked feature families when exact symbol IDs are used:
  repo discovery/outline/health, symbol search, text search, file tree/content/
  outline, symbol source/complexity, context bundle, ranked context,
  references, blast radius, call hierarchy, dependency cycles/graph/importers,
  hotspots, dead-code v1/v2, untested symbols, symbol importance, coupling, and
  cross-repo map. The first blast-radius attempt failed only because the bare
  `ConflictViewerScreen` name was ambiguous; rerunning with the symbol ID
  passed with `direct_dependents_count=3` and `potential_count=0`.
- [x] Restart this Codex session/MCP host again after commit `7c830f8`. Live
  MCP calls in the current session now work again: `list_repos`,
  `search_symbols`, `get_file_content`, `register_edit`,
  `get_dependency_cycles`, `get_symbol_complexity`, and `get_repo_health`
  returned successfully against `local/Field_Guide_App-37debbe5`.

Refreshed CodeMunch index: `local/Field_Guide_App-37debbe5`, indexed
2026-04-11 19:01, `14,916` symbols.

Hotspots to review/split or test-harden:

- [x] `ColumnDetectorV2.detect`. Closed by earlier extraction into
  `ColumnDetectionWorkflow`; refreshed CodeMunch reports complexity `4`, max
  nesting `3`, `28` lines, assessment `low`.
- [x] `mdot_0582b_pdf_filler.dart` row builders. `_buildDraftTestRow`
  complexity reduced from `80` / high to `10` / medium by extracting repeated
  string/default selection helpers; focused 0582B PDF filler and form PDF
  service tests pass. The top-level filler remains on the oversized-file
  watchlist below for a larger split.
- [x] `AppInitializer.initialize`. Extracted auth/sync listener state into
  `AuthSyncListenerBootstrap` with separate ready-context sync scheduling and
  realtime hint subscription state. CodeMunch now reports
  `AppInitializer.initialize` complexity `5` / medium and
  `AuthSyncListenerBootstrap.wire` complexity `5` / medium; no extracted helper
  method is high complexity.
- [x] `DriverServer._handleRequest`. Moved interaction endpoint dispatch into
  `DriverInteractionHandler.handle()` using an endpoint table. CodeMunch now
  reports `_handleRequest` complexity `10` / medium and the new interaction
  dispatch method complexity `2` / low.
- [x] `AppRedirect.performRedirect`. Extracted ordered redirect gate decisions
  into private helpers while preserving security-critical gate order; complexity
  reduced from `69` / high to `8` / medium. `app_redirect_test`, analyzer, and
  custom lint pass.
- [x] `SyncInitializer.create`. Split into bootstrap/runtime wiring helpers;
  refreshed CodeMunch reports complexity `10`, max nesting `4`, `76` lines,
  assessment `medium`.
- [x] `PdfDataBuilder.generate`. Extracted permission, contractor/equipment,
  personnel, bid-item, inspector-name, and form-attachment assembly helpers
  while preserving the same IDR export data flow. CodeMunch now reports
  `generate` complexity `9` / medium; the newly extracted personnel helpers
  are medium/low.
- [x] `ExportPayAppUseCase.execute`. Export collection, workbook build, and
  artifact persistence now live in dedicated use cases; refreshed CodeMunch
  reports complexity `5`, max nesting `1`, `36` lines, assessment `medium`.
- [x] `DatabaseUpgradeRepairs.applyLateMigrations`. Late migration dispatch now
  delegates to extracted repair helpers; refreshed CodeMunch reports complexity
  `1`, max nesting `0`, `2` lines, assessment `low`.
- [x] `ConflictViewerScreen._buildConflictCard`. Implementation refactor is
  complete: extracted the inline card body into `_ConflictCard` render helpers,
  preserving existing conflict keys and dismiss/restore callbacks. Focused
  screen tests, `flutter analyze lib test`, and `dart run custom_lint` pass.
  After the MCP host restart, CodeMunch verified
  `_buildConflictCard` at cyclomatic `5`, max nesting `2`, `14` lines,
  assessment `medium`.

Oversized production files to review:

- [x] `lib/core/database/schema_verifier.dart`. Static schema metadata now lives
  in `database_schema_metadata.dart`, and verification behavior is split across
  table, column, missing-column, and drift-recording helpers. Current file is
  `291` lines; focused schema verifier tests and live/local schema guards pass.
- [ ] `lib/features/pdf/services/extraction/shared/post_process_utils.dart`
- [ ] `lib/features/sync/engine/local_sync_store.dart`
- [ ] `lib/features/forms/presentation/screens/mdot_1126_form_screen.dart`
- [ ] `lib/features/pdf/services/idr_pdf_template_writer.dart`
- [ ] `lib/features/forms/presentation/screens/mdot_1174r_sections.dart`
- [x] `lib/core/driver/driver_data_sync_handler.dart`
- [ ] `lib/features/forms/presentation/screens/mdot_1174r_form_screen.dart`
- [x] `lib/features/projects/presentation/providers/project_provider.dart`
- [x] `lib/features/forms/data/pdf/mdot_0582b_pdf_filler.dart`

Dependency cycles to review:

- [x] Driver harness seed data cycle. Resolved by moving shared driver seed IDs
  to `lib/core/driver/harness_seed_defaults.dart`; refreshed CodeMunch cycle
  count dropped from 3 to 2.
- [x] Form attachment/display filename policy cycle. Resolved by extracting
  shared attachment filename key/extension handling to
  `lib/features/forms/data/services/form_attachment_filename_policy_support.dart`;
  refreshed CodeMunch cycle count dropped from 6 to 5.
- [x] Quantity calculator screen/tab cycle. Resolved by extracting
  `QuantityCalculatorResult` to
  `lib/features/quantities/presentation/models/quantity_calculator_result.dart`;
  refreshed CodeMunch cycle count dropped from 7 to 6.
- [x] TODO provider/sorting cycle. Resolved by moving `TodoFilter` and
  `TodoSort` to `lib/features/todos/presentation/providers/todo_filter_sort.dart`
  and re-exporting from `todo_provider.dart`; refreshed CodeMunch cycle count
  dropped from 5 to 4.
- [x] PDF extraction pipeline/stage/import-service cycle. Resolved by keeping
  `models.dart` model-only, adding
  `lib/features/pdf/services/extraction/pipeline/pipeline.dart` as the
  pipeline-facing barrel, moving pipeline/import tests to explicit pipeline
  imports, and extracting `PdfImportResult`/`ParserType` to
  `lib/features/pdf/services/pdf_import_result.dart`; refreshed CodeMunch
  reports `cycle_count=0`.
- [x] PDF quality report/thresholds cycle. Resolved by moving
  `QualityStatus` and `ReExtractionStrategy` to
  `lib/features/pdf/services/extraction/models/quality_types.dart` and
  re-exporting for compatibility; refreshed CodeMunch cycle count dropped from
  2 to 1.
- [x] Weather service/interface cycle. Resolved by moving `WeatherData` to
  `lib/features/weather/domain/weather_data.dart` and exporting it from the
  existing service/domain surfaces for compatibility; refreshed CodeMunch cycle
  count dropped from 4 to 3.

Structural cleanup verification, 2026-04-11:

- `flutter analyze lib test`: PASS.
- `dart run custom_lint`: PASS.
- `flutter test test/features/pdf/extraction/pipeline test/features/pdf/services/mp/mp_extraction_service_test.dart --reporter expanded`: PASS.
- `flutter test test/features/pdf/extraction/integration/type_round_trip_test.dart test/features/pdf/extraction/helpers/report_generator_test.dart --reporter expanded`: PASS.
- `flutter test test/core/di/app_initializer_test.dart --reporter expanded`: PASS.
- `flutter analyze lib test`: PASS after `AppInitializer` extraction.
- `dart run custom_lint`: PASS after `AppInitializer` extraction.
- `flutter test test/core/driver --reporter expanded`: PASS after
  `DriverServer` dispatch extraction.
- `flutter analyze lib test`: PASS after `DriverServer` dispatch extraction.
- `dart run custom_lint`: PASS after `DriverServer` dispatch extraction.
- `flutter test test/features/entries/domain/usecases/export_entry_use_case_test.dart test/features/entries/presentation/support/entry_pdf_action_owner_test.dart --reporter expanded`: PASS after
  `PdfDataBuilder` extraction.
- `flutter analyze lib test`: PASS after `PdfDataBuilder` extraction.
- `dart run custom_lint`: PASS after `PdfDataBuilder` extraction.
- `flutter test test/features/sync/presentation/screens/conflict_viewer_screen_test.dart --reporter expanded`: PASS after
  `ConflictViewerScreen` card extraction.
- `flutter analyze lib test`: PASS after `ConflictViewerScreen` card
  extraction.
- `dart run custom_lint`: PASS after `ConflictViewerScreen` card extraction.
- CodeMunch MCP refresh initially failed during `ConflictViewerScreen`
  verification with `Transport closed`; rerun after the current MCP host
  restart passed and reported `_buildConflictCard` complexity `5` / medium.
- CodeMunch `get_dependency_cycles` after incremental reindex:
  `cycle_count=0`.

Central seams to keep on the watchlist:

- [ ] `Logger`
- [ ] `DatabaseService`
- [ ] `LocalSyncStore`
- [ ] `AuthProvider`
- [ ] `DailyEntry`
- [ ] `SyncRegistry`
- [ ] `BidItem`

## UX Follow-Ups

- [x] Verify photo filename editing on S21.
- [x] Verify contained personnel picker on S21.
- [x] Verify HMA Yield Calculator numeric flows on S21.
- [x] Verify HMA weighback calculator uses last calculated or manually entered
  assumed yield.
- [x] Verify concrete Area / Volume Calculator unit switching and numeric
  results on S21.
- [x] Verify quantity item ordering in every affected list after the natural
  sort fix. 2026-04-12 follow-up: `naturalCompare` now gives deterministic
  ordering for equal numeric segments with leading zeros; `EntryQuantityOrdering`
  is the shared production ordering seam for entry quantity cards and IDR
  materials; pay-app workbooks keep natural bid-item row order and apply
  quantities by bid-item ID. Focused tests passed for the ordering helper,
  natural sort, bid-item repository ordering, and workbook row/quantity
  alignment.
- [x] Verify keyboard/next-field progression in form fillers.
- [x] Verify compact form filler layout does not reintroduce overlapping bubble
  headers or cramped table-entry controls. 2026-04-12 proof captured 0582B hub,
  1174R compact/table route, and 1126 compact layout screenshots on S21; focused
  compact layout tests passed.

Calculator evidence addendum:

- HMA Yield Calculator is now scoped to the toolbox calculator only. The
  quantity-entry calculator no longer exposes an HMA tab and opens on the
  generic `Calculator` tab.
- HMA Yield Calculator formula now uses inspector-entered length, width,
  thickness, and truck tonnage: `(length x width) / 9 = whole SY`;
  `truck tons x 2000 / whole SY = actual lb/SY`; target is
  `thickness x 110 lb/SY`.
- S21 current-source build installed on `RFCNC0Y975L`: SHA-256
  `EAEBC5A1DC1F7C2F4CBD4F86192892A58059093F3C2ECB774DBB62CA68D3CA81`,
  package `com.fieldguideapp.inspector`, `versionCode=3`,
  `versionName=0.1.2`, `lastUpdateTime=2026-04-11 16:11:46`.
- S21 HMA keyed entry verified `length=325`, `width=14`, `thickness=2`,
  `truck_tons=47.29`; result card appeared and app-pid log sample contained
  no `FlutterError`, failed assertion, duplicate `GlobalKey`, `RenderFlex`
  overflow, `ANR`, or `FATAL` app lines.
- S21 HMA weighback keyed entry verified remaining length/width flow using the
  last calculated lb/SY yield.
- S21 quantity calculator route proof:
  `/quantity-calculator/s21-calculator-smoke` reports
  `quantity_calculator_screen` present, `calculator_concrete_tab` present, and
  `calculator_hma_tab` absent.
- S21 live-run toolbox concrete calculator proof on 2026-04-12 verified
  length `27`, width `18`, thickness `6`: default `SY/CY` result showed
  `9 CY` and `Area: 54.00 SY`; switching to `SF/CF` recalculated to `243 CF`
  and `Area: 486.00 SF`. Sync stayed clean and the app-specific error scan was
  empty. Screenshots:
  `.codex/artifacts/2026-04-12/s21_concrete_calculator_sy_cy_result.png` and
  `.codex/artifacts/2026-04-12/s21_concrete_calculator_sf_cf_result.png`;
  log scan:
  `.codex/artifacts/2026-04-12/s21_concrete_calculator_app_error_scan.txt`.
- Evidence screenshots:
  `.codex/artifacts/2026-04-11/s21_hma_yield_calculator_result_20260411.png`,
  `.codex/artifacts/2026-04-11/s21_hma_weighback_calculator_result_20260411.png`,
  and `.codex/artifacts/2026-04-11/s21_quantity_calculator_no_hma_tab_20260411.png`.
- Local verification: `flutter test
  test/features/calculator/services/calculator_service_test.dart
  test/features/calculator/presentation/screens/calculator_screen_test.dart
  --reporter expanded` passed; `flutter analyze lib test` passed;
  `dart run custom_lint` passed.
- Device automation note: do not use repeated Android `uiautomator dump` while
  the Flutter driver is active on the S21; it crashed the UI/accessibility
  stack during the previous calculator inspection. Use driver-keyed input and
  screenshots instead.

## Canonical Spec Append - Calculator And Pay-App Template

Status: `IMPLEMENTED / DEVICE VERIFIED` for the calculator and pay-app workbook
scope. Completeness-agent review remains required before closing the broader
pre-release tracker.

- Calculator correction remains active: HMA Yield and HMA weighback are
  toolbox-only; the quantity calculator must not expose HMA.
- HMA Yield inputs are inspector-entered length, width, thickness, and truck
  tonnage. Formula: `(length x width) / 9 = whole SY`;
  `truck tons x 2000 / whole SY = actual lb/SY`; target is
  `thickness x 110 lb/SY`.
- Quantity calculator must be a single generic `Calculator`, not separate
  `Calculator`, `Area`, `Volume`, and `Linear` tabs.
- Quantity calculator must switch units for `LF`, `SF`, `SY`, `CF`, and `CY`;
  it remembers the last selected unit and falls back to `SY`.
- Quantity calculator results must return the selected value and unit through
  `QuantityCalculatorResult` so entry quantities store the correct unit.
- Pay-app project workbooks must use the company `Quantities` workbook format
  from `C:\Users\rseba\Downloads\864130 Quantities (version 1).xlsb.xlsx` as a
  formatting reference only.
- Create and use a sanitized blank canonical workbook template with the
  reference workbook's layout, styles, frozen panes after column `F`, row `7`
  weekday/header band, row `8` date band, left block `A:F`, print setup, and
  logo preserved.
- Strip all reference project data from the template: project names, bid item
  data, quantities, date values, comments/threaded comments, source paths, and
  existing daily/pay-app values.
- Generated pay-app workbooks must be one sheet named `Quantities`, adapt to
  the current project's bid item count, keep bid items vertical and dates/pay
  apps horizontal, and use `bid_items`, `entry_quantities`, and
  `pay_applications` as the only quantity/pay-app data sources.
- The old simplified `G703 Ledger` workbook layout is no longer sufficient for
  final acceptance and must be replaced or guarded against in tests.
- After calculator and pay-app workbook repairs, continue the final real-auth
  S21 e2e lane: all-form UI-driven fill/preview/export for IDR, 0582B, 1126,
  and 1174R; photo/form attachments; Springfield pay-app workbook and
  contractor comparison; Office Technician/review-comment gates when remote
  credentials are unblocked; UX follow-ups; structural lint/CodeMunch backlog;
  final self-review; and completeness-agent review.

Implementation/evidence addendum, 2026-04-11:

- Fresh S21 real-auth driver APK installed on `RFCNC0Y975L`: SHA-256
  `8356740B391245D282EEB30D58E66130916511B0F0E1BCA3472F1976C86AB0DF`,
  package `com.fieldguideapp.inspector`, `versionCode=3`,
  `versionName=0.1.2`, `lastUpdateTime=2026-04-11 16:59:14`.
- HMA Yield S21 proof used length `325`, width `14`, thickness `2`, and truck
  tonnage `47.29`, then verified the result card and weighback flow:
  `.codex/artifacts/2026-04-11/s21_hma_yield_after_template_workbook_change.png`
  and
  `.codex/artifacts/2026-04-11/s21_hma_weighback_after_template_workbook_change.png`.
- Quantity Calculator S21 proof verified `/quantity-calculator/s21-calculator-smoke`,
  `quantity_calculator_unified`, absent `quantity_calculator_unit_HMA`,
  `SY` calculation result, and `CY` unit switching with thickness field:
  `.codex/artifacts/2026-04-11/s21_quantity_calculator_unified_sy_after_template_workbook_change.png`
  and
  `.codex/artifacts/2026-04-11/s21_quantity_calculator_unified_cy_after_template_workbook_change.png`.
- Pay-app S21 proof exported
  `/data/user/0/com.fieldguideapp.inspector/app_flutter/exports/pay-applications/pay_app_4_2026-04-06_2026-04-11.xlsx`
  and refreshed
  `/data/user/0/com.fieldguideapp.inspector/app_flutter/exports/pay-applications/project-workbooks/75ae3283_d4b2_4035_ba2f_7b4adb018199_Springfield_DWSRF_pay_applications.xlsx`.
- Pulled workbook evidence:
  `.codex/artifacts/2026-04-11/s21_springfield_project_workbook_after_template_change.xlsx`;
  inspection proof:
  `.codex/artifacts/2026-04-11/s21_springfield_project_workbook_after_template_change_db_comparison.json`.
  That proof records one sheet `Quantities`, dimension `A1:RX142`, freeze pane
  `KJ1`, logo drawing present, no `G703 Ledger`, reference metadata strings
  stripped, 131 Springfield bid items compared, and
  `mismatchCountFirst131=0`.
- Active S21 pay-app proof:
  `.codex/artifacts/2026-04-11/s21_active_pay_apps_after_template_export.txt`
  records four active pay apps: #1 `2026-03-16..2026-03-22`, #2
  `2026-03-23..2026-03-29`, #3 `2026-03-30..2026-04-05`, and #4
  `2026-04-06..2026-04-11`.
- Completeness review result for this lane: `PASS`. The only issue found
  during review was stale `G703-style` terminology in the pay-app workbook
  use-case comment; that comment was corrected, and a focused analyzer pass on
  `lib/features/pay_applications/domain/usecases/build_project_pay_app_workbook_use_case.dart`
  reported no issues.

Pay-app public save audit addendum, 2026-04-11:

- `PASS / BASELINE` Before the public-save retest, the existing S21
  app-private workbook was pulled and inspected at
  `.codex/artifacts/2026-04-11/pay_app_s21_public_save_audit/s21_private_Springfield_DWSRF_pay_applications.xlsx`.
  It is the correct new company workbook format: one sheet named `Quantities`,
  dimension `A1:RX142`, drawing/logo parts present, and no `G703` text.
- `GAP FOUND / FIXED` The initial S21 public storage search found only
  `/storage/emulated/0/Documents/Live_0582B_Verification_pay_applications.xlsx`;
  no public Springfield/DWSRF/Quantities workbook copy existed in Documents or
  Downloads even though the private canonical workbook existed under
  `app_flutter/exports/pay-applications/project-workbooks/`.
- `PASS` Fixed the post-export save feedback in
  `lib/features/quantities/presentation/widgets/quantities_pay_app_exporter.dart`:
  `Save Project Workbook` now reports the actual saved path when Android
  returns one, and warns `Project workbook was not saved` when the picker is
  cancelled or no copy path is returned instead of showing a generic export
  success.
- `PASS` Focused verification after the fix:
  `flutter test test/features/quantities/presentation/screens/quantities_screen_pay_app_export_flow_test.dart test/features/quantities/presentation/screens/quantities_screen_export_flow_test.dart --reporter expanded`;
  targeted analyzer over the touched pay-app export files; root
  `flutter analyze lib test`; and `dart run custom_lint` all passed.
- `HISTORICAL PROBE` Installed an earlier patched real-auth driver build on S21
  `RFCNC0Y975L`, APK SHA-256
  `A5765275FABEE480CD6E69D3EDEDCFBC837E3DE91536063F831CF9182B136DCE`,
  package `lastUpdateTime=2026-04-11 19:20:53`, and verified
  `/driver/ready` at `/projects`. The non-mutating device probe reached the
  pay-app date dialog and was cancelled without creating a Pay App #5; S21 DB
  still shows active Springfield Pay Apps #1-#4 and sync status stayed clean.
- `CLOSED` The safe exact-replacement and manual S21 save-copy retest for the
  Springfield `Quantities` workbook is completed in the newer S21 pass below.
- `PASS` Exact Springfield Pay App #4 replacement on S21 uncovered and then
  verified the missing-artifact repair path. The active Pay App #4 previously
  pointed at soft-deleted artifact `e8fe54a0-207a-4760-b4d1-8872061fa471`;
  `ExportPayAppUseCase` now creates a fresh export artifact when the pay app
  exists but its artifact row is missing, updates the pay app to that artifact,
  and rolls back the artifact if the pay-app update fails.
- `PASS` Patched real-auth driver build installed on S21 `RFCNC0Y975L`:
  APK SHA-256
  `128160F30C5B70E76CED408055C8B353601FF16C114F7212FBFB56F2F548EC20`,
  package `com.fieldguideapp.inspector`, `versionCode=3`,
  `versionName=0.1.2`, `lastUpdateTime=2026-04-11 19:37:59`.
- `PASS` Exact replacement export for Springfield Pay App #4
  `2026-04-06..2026-04-11` completed on S21 after the patch. The S21 DB shows
  active Pay Apps #1-#4 only; Pay App #4 now points to non-deleted artifact
  `f2630c36-33e8-4390-8b02-2965ee145105`, updated
  `2026-04-11T23:45:18.631167+00:00`.
- `PASS` Public Android save-copy is verified. The S21 snackbar reported:
  `Exported Pay Application #4. Saved project workbook to /storage/emulated/0/Documents/04-11/04-11/03-31-signature-stamp/Springfield_DWSRF_pay_applications.xlsx.`
  The public file exists on-device at that path, size `203379`, timestamp
  `2026-04-11 19:45`, and was pulled to
  `.codex/artifacts/2026-04-11/pay_app_s21_public_save_audit/s21_public_saved_Springfield_DWSRF_pay_applications.xlsx`.
- `PASS` Formatting/spacing audit of the public S21-saved workbook against
  `assets/templates/pay_app_quantities_template.xlsx` passed at XML level:
  same sheets, dimension `A1:RX142`, frozen pane `KJ1`, column widths, row
  layout attributes/heights, merges, style counts, page margins, page setup,
  print options, media, drawing parts, and logo image part. Audit JSON:
  `.codex/artifacts/2026-04-11/pay_app_s21_public_save_audit/s21_public_saved_formatting_audit.json`.
- `PASS` Public workbook content spot-checks after the formatting audit:
  `A1=Springfield DWSRF`, `A4=Quantities`, `A9=1`,
  `B9=Mobilization, Bonds, & Insurance (5% Max)`, `G7=Monday`, `G8=46097`,
  `formula_E9='=SUM(G9:AA9)'`, `formula_F9='=SUM(AA9)'`,
  `xl/media/image1.png` present, and no old `G703 Ledger` sheet.
- `PASS` Next-week append regression added in
  `test/features/pay_applications/domain/usecases/build_project_pay_app_workbook_use_case_test.dart`:
  Pay Apps #1-#5 from `2026-03-16..2026-04-18` keep the workbook starting at
  `G8=46097`, preserve prior-period quantities through `AA/AG`, extend the new
  week through `AN8=46130`, keep the template dimension `A1:RX142` and freeze
  pane `KJ1`, set total-to-date formula `formula_E9='=SUM(G9:AN9)'`, and set
  current pay-period formula
  `formula_F9='=SUM(AH9,AI9,AJ9,AK9,AL9,AM9,AN9)'`.
- `PASS` Focused verification after the missing-artifact repair, save-copy UI
  feedback, and next-week append regression: `flutter test
  test/features/pay_applications/domain/usecases/build_project_pay_app_workbook_use_case_test.dart
  test/features/pay_applications/domain/usecases/export_pay_app_use_case_test.dart
  test/features/quantities/presentation/screens/quantities_screen_pay_app_export_flow_test.dart
  test/features/quantities/presentation/screens/quantities_screen_export_flow_test.dart
  --reporter expanded` passed `16` tests; targeted `flutter analyze` over the
  six touched pay-app/export test files passed; `dart run custom_lint` passed;
  and `flutter analyze lib test` passed.
- `GAP FOUND / FIXED` User comparison against
  `C:\Users\rseba\OneDrive\Desktop\pay_app_4_2026-04-06_2026-04-11.xlsx`
  exposed that the primary pay-app artifact still used the old small
  Syncfusion `G703` workbook path even though the optional project-workbook
  save-copy used the canonical `Quantities` template.
- `PASS` Fixed `ExportPayAppUseCase` so the primary artifact export now builds
  bytes through `PayAppProjectWorkbookBuilder` and
  `pay_app_quantities_template.xlsx`, inserts the current pay application into
  the project pay-application history before resolving the workbook date range,
  and still uses the existing artifact persistence/rollback path.
- `PASS` Removed the legacy `PayAppExcelExporter.generate` workbook generator;
  `PayAppExcelExporter` now only owns safe file writing for workbook bytes
  produced by the canonical template builder.
- `PASS` Added custom lint
  `no_legacy_pay_app_workbook_export` in
  `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_legacy_pay_app_workbook_export.dart`.
  It errors on pay-app feature code that reintroduces raw `G703` sheet literals,
  raw Syncfusion `Workbook(...)` construction, or direct legacy Excel
  `generate` calls instead of the canonical `Quantities` template path.
- `PASS` Replaced the Desktop comparison file
  `C:\Users\rseba\OneDrive\Desktop\pay_app_4_2026-04-06_2026-04-11.xlsx`
  with the corrected canonical `Quantities` workbook. The old 16,950-byte
  `G703` workbook is backed up at
  `.codex/artifacts/2026-04-11/pay_app_s21_public_save_audit/desktop_old_pay_app_4_2026-04-06_2026-04-11_G703_backup.xlsx`.
- `PASS` Post-fix XML formatting compare of the corrected Desktop workbook
  against `C:\Users\rseba\Downloads\864130 Quantities (version 1).xlsb.xlsx`
  passed for sheets, dimension `A1:RX142`, freeze pane `KJ1`, column widths,
  row layout attributes/heights, merges, page margins, page setup, print
  options, style counts, and media/logo part. Remaining package differences
  are non-format: stripped comments/threaded comments, associated VML drawing
  part, and file size. Compare JSON:
  `.codex/artifacts/2026-04-11/pay_app_desktop_after_fix_formatting_compare.json`.
- `PASS` Verification after the artifact-export canonical-template fix and
  lint rule: `dart test` in `fg_lint_packages/field_guide_lints` passed `220`
  tests; focused pay-app workbook/export tests passed `19` tests; targeted
  `flutter analyze` over touched pay-app export files passed;
  `flutter analyze lib test` passed; and `dart run custom_lint` passed with
  the new lint active.
- `GAP FOUND / FIXED` S21 Excel verification uncovered two workbook issues
  after the primary artifact-template fix. First, the append logic in
  both `BuildProjectPayAppWorkbookUseCase` and `ExportPayAppUseCase` derived
  date columns from quantity postings, so no-entry dates inside a saved pay-app
  range such as `2026-04-06..2026-04-10` were dropped from the workbook.
  Both paths now create one workbook column for every calendar date from the
  first active pay app through the latest active pay app, using empty quantity
  maps for no-entry days. Second, the original template's frozen pane pointed
  at far-right `KJ1`; generated workbooks now preserve the canonical frozen-left
  view but reset the scrollable pane to the first date column with
  `topLeftCell=G1`. Android Excel on S21 still cannot comfortably pan this wide
  frozen-left layout; that is accepted as a mobile Excel limitation for this
  canonical format.
- `PASS` Header and workbook performance repair: rows `7` and `8` now use
  explicit `16.2` heights to avoid cramped day/date labels, and
  `PayAppProjectWorkbookBuilder` indexes rows/cells once per build instead of
  repeatedly scanning XML. The S21 exact-replacement export dropped from long
  spinner stalls to about five seconds while still showing a non-dismissible
  `Creating Pay Application` progress dialog.
- `PASS` Final S21/Excel evidence for the split workbook view:
  `pay_app_5_2026-04-12_2026-04-18.xlsx` and
  `Springfield_DWSRF_pay_applications.xlsx` were generated by the rebuilt S21
  app, pulled from app-private storage, copied to Desktop, and pushed to
  `/sdcard/Documents/04-11/04-11/03-31-signature-stamp/`. XML/package checks
  show `testzip=null`, `leading_equals_count=0`, `formula_count=298`,
  rows `7/8/9` at height `16.2`, and Apr `06..12` visible across `AB:AH`.
  The Pay App artifact and project workbook now both have `freeze=G1` for the
  canonical Windows-style view after the mobile-only no-freeze variant was
  rejected.
- `FORMULA AUDIT` The workbook is editable for quantity changes: item rows use
  generated E/F formulas such as `E9=SUM(G9:AN9)` and
  `F9=SUM(AH9,AI9,AJ9,AK9,AL9,AM9,AN9)`, and row `140` contains per-day
  formulas such as `AN140=SUM(AN9:AN139)`. The export does not preserve every
  original formula verbatim because the original template formulas point to the
  historical/far-future range (`G:RA`, `IS:JU`, etc.); formulas are regenerated
  to the actual exported date span while preserving the company workbook layout
  and editability.
- `PASS` Focused verification after the S21 repair: `flutter test
  test/features/pay_applications/data/services/pay_app_project_workbook_builder_test.dart
  test/features/pay_applications/domain/usecases/build_project_pay_app_workbook_use_case_test.dart
  test/features/pay_applications/domain/usecases/export_pay_app_use_case_excel_proof_test.dart
  test/features/pay_applications/domain/usecases/export_pay_app_use_case_test.dart
  --reporter expanded` passed `11` tests; targeted `flutter analyze` over the
  touched pay-app builder/export files passed; and
  `dart test test/architecture/no_legacy_pay_app_workbook_export_test.dart`
  passed with behavior fixtures for `G703`, raw `Workbook(...)`, and legacy
  `generate` calls.

## 2026-04-12 Auth And Report Review Follow-Up

- `PASS / LOCAL AUTH AUDIT` Current source keeps auth/session state threaded
  through `AuthProvider`, `AuthService`, `LoadProfileUseCase`,
  `AppRedirect`, and sync runtime wiring. `AuthProvider` remains the central
  permission seam for `canEditFieldData`, `canManageProjectFieldData`,
  `canReviewInspectorWork`, `canEditEntry`, and `canDeleteProject`; sync uses
  injected `authProvider.userId` / `authProvider.userProfile?.companyId`
  providers instead of storing an independent user. Local search found no
  `MOCK_AUTH`, `mock_auth`, `mock auth`, or `MockAuth` runtime seams under
  `lib`, `supabase`, or `integration_test`.
- `PASS / SEAM CLEANUP` Removed the leftover duplicate
  `AuthProvider.loadUserProfile` / `refreshUserProfile` implementation from
  the class body so the extracted company/profile action part is the single
  profile-load owner. This is a hygiene fix, not a behavior change; sign-in,
  startup auth-state listener, sync post-hook refresh, and role refresh calls
  still resolve through the same production auth/profile use case.
- `PASS / LOCAL REPORT REVIEW FIX` The review screen now carries a focused
  entry-editor route intent for `Site Safety`, `SESC Measures`,
  `Traffic Control`, `Visitors`, and `Extras/Overruns`. The entry editor parses
  that intent, scrolls the Safety & Site Conditions section into view, opens it
  in edit mode when the current user can edit the entry, and focuses the SESC
  field for SESC edits. Local verification:
  `flutter analyze lib/features/auth/presentation/providers/auth_provider.dart
  lib/features/auth/presentation/providers/auth_provider_company_profile_actions.dart
  lib/features/entries/presentation/navigation/entry_flow_route_intents.dart
  lib/core/router/routes/entry_routes.dart
  lib/features/entries/presentation/screens/entry_editor_screen.dart
  lib/features/entries/presentation/screens/entry_editor_state_mixin.dart
  lib/features/entries/presentation/widgets/entry_editor_body.dart
  lib/features/entries/presentation/widgets/entry_editor_sections_list.dart
  lib/features/entries/presentation/widgets/editable_safety_card.dart
  lib/features/entries/presentation/screens/entry_review_screen.dart
  test/features/entries/presentation/screens/entry_editor_route_binding_test.dart`
  passed, and `flutter test
  test/features/entries/presentation/screens/entry_editor_route_binding_test.dart
  --reporter=compact` passed. Follow-up gates also passed:
  `dart run custom_lint`, `flutter test
  test/core/router/app_redirect_test.dart test/core/router/app_router_test.dart
  test/features/entries/presentation/screens/entry_editor_route_binding_test.dart
  --reporter=compact`, and `flutter test
  test/features/projects/presentation/providers/project_provider_sync_mode_test.dart
  test/features/projects/presentation/providers/project_provider_test.dart
  --reporter=compact`.
- `OPEN / S21 PROOF` Re-run the inspector draft review flow on the S21 when
  the driver or `flutter run` endpoint is alive: select a draft report, tap
  `SESC Measures` from the review screen, verify the editor lands on Safety &
  Site Conditions with the SESC field editable, save, return to Mark
  Ready/Review, submit, sync, and capture screenshot/log proof. The previous
  S21 control server reported `hasExited=true` and the driver port refused
  connections, so this local fix is not yet counted as device-closed.
- `OPEN / UX NITPICK LAST` Mark Ready/Review remains functionally usable, but
  the compact review preview is still tight and hard to scan by section. After
  release blockers, improve the review preview density/section grouping without
  changing the submit workflow.

## Required Evidence Per Closed Item

- S21 screenshot or Windows screenshot where appropriate.
- Build hash and package `lastUpdateTime` for S21 evidence.
- Sync status proof for synced behavior.
- Exported artifact path for every PDF/workbook verification.
- Field-inspection JSON for every all-cell form export.
- Test/analyzer/custom-lint command and result.
- Explicit `PASS`, `PARTIAL`, `OPEN`, or `BLOCKED` status with the blocker
  named.

## Latest Local Gate Evidence

- `flutter analyze`: PASS on 2026-04-11.
- `flutter analyze lib test`: PASS on 2026-04-11.
- `dart run custom_lint`: PASS on 2026-04-11.
- `flutter test --reporter expanded`: PASS on 2026-04-11.

## Latest Real-Auth S21 Evidence

- Red-screen regression repair build installed on `RFCNC0Y975L`: SHA-256
  `93D9871F02978F827D61B95C5D35F363F1F88D250132719CDC6205332385833D`,
  package `com.fieldguideapp.inspector`, `versionCode=3`,
  `versionName=0.1.2`, `lastUpdateTime=2026-04-11 23:31:44`.
- S21 Office Technician review-comment regression proof on 2026-04-11:
  after rebuilding with `.env` dart-defines and `DEBUG_SERVER=true`, the app
  picked up the temporary live Office Technician role, exposed
  `report_menu_button` on
  `/report/fdd89344-165d-4001-ae64-e7a933659028`, saved the Add Review Comment
  dialog, and remained on the report screen. Screenshot:
  `.codex/artifacts/2026-04-11/office_tech_review_verification/s21_redscreen_regression_after_fix.png`;
  logcat:
  `.codex/artifacts/2026-04-11/office_tech_review_verification/s21_redscreen_regression_after_fix_logcat.txt`.
  The sampled log contains no `TextEditingController was used after being
  disposed`, `_dependents.isEmpty`, `Failed assertion`, `FlutterError`, or
  `EXCEPTION CAUGHT` matches. The remote admin account was restored to `admin`
  after the proof.
- `GAP FOUND / FIXED` The first manual `/driver/sync` after the Office
  Technician proof exposed two cleanup/runtime issues: scope-revocation project
  eviction tried to acquire a second `sync_lock` while already running inside
  sync, and the shell sync-error toast callback retained a disposed shell
  `BuildContext` after navigation. `ScopeRevocationCleaner` now calls
  `removeFromDevice(..., acquireSyncLock: false)` only for internal sync-scope
  cleanup, while normal user-triggered removal still refuses to run under an
  active sync lock. `ShellBanners` now owns and clears the toast callback with
  widget lifecycle instead of registering it once with `??=`.
- `PASS` Follow-up S21 sync proof after those fixes: rebuilt APK SHA-256
  `1640C6E9B1EB69C0EE2810157F82285E9A84EAE6577FB24D283CBE5BDAE495E7`,
  `lastUpdateTime=2026-04-11 23:42:00`; `/driver/sync` returned
  `success=true`, `pushed=0`, `pulled=0`, `errors=[]`, and final
  `/driver/sync-status` returned `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`, `isSyncing=false`,
  `lastSyncTime=2026-04-12T03:42:23.089519Z`. Log proof:
  `.codex/artifacts/2026-04-11/office_tech_review_verification/s21_sync_after_lock_context_fix_logcat.txt`;
  the scanned window contains no sync-lock collision, deactivated-widget
  ancestor lookup, disposed-controller, `_dependents.isEmpty`, failed-assertion,
  `FlutterError`, or `EXCEPTION CAUGHT` matches.
- `GAP FOUND / FIXED` S21 shared-device user-scope sync bug: Springfield was
  assigned to inspector `d1ca900e-d880-4915-9950-e29ba180b028` remotely and
  locally, but a stale device-global
  `manual_project_removal_75ae3283-d4b2-4035-ba2f-7b4adb018199` marker kept
  `synced_projects` empty after an admin/inspector session switch. The fix
  scopes manual device-removal markers by signed-in user and ignores legacy
  global markers for assignment backfill.
- `PASS` Follow-up S21 proof on 2026-04-12: rebuilt driver APK
  `field-guide-android-debug-0.1.2-2026-04-12.apk` installed on
  `RFCNC0Y975L`, route `/projects`. Logs show `Reconciled synced_projects` for
  Springfield at `00:03:58`, cleared `18` project-scoped cursors, then a quick
  sync pulled `447` rows with `errors=0`. Device DB proof
  `.codex/artifacts/2026-04-12/s21_inspector_after_user_scoped_marker_fix.db`
  shows Springfield in `synced_projects`, the active inspector assignment, and
  `29` active Springfield daily entries including `2026-04-12` through
  `2026-04-18`; screenshot proof:
  `.codex/artifacts/2026-04-12/s21_project_list_after_sync_fix.png`; log proof:
  `.codex/artifacts/2026-04-12/s21_sync_user_scoped_marker_fix_flutter_logcat.txt`.
- `GAP FOUND / FIXED` S21 photo filename editing initially failed for
  remote-backed photos because synced/imported photos intentionally have
  `file_path = NULL`, while `PhotoService.renamePhoto` required a local file
  before updating the user-facing filename. The service now keeps local disk
  rename behavior for local files and performs a metadata-only filename update
  when a photo has `remote_path` but no local path.
- `PASS` S21 live-run photo proof on 2026-04-12: `flutter run` on
  `RFCNC0Y975L` with `lib/main_driver.dart`, `DEBUG_SERVER=true`, and driver
  port `4948` edited photo
  `07ba2941-1191-4c10-8518-1728a8adfd50` on
  `/report/8111ed52-fb97-4647-936d-5559a6309024`. Screenshots:
  `.codex/artifacts/2026-04-12/s21_live_run_photo_thumbnail_visible.png`,
  `.codex/artifacts/2026-04-12/s21_live_run_photo_dialog_edited.png`, and
  `.codex/artifacts/2026-04-12/s21_live_run_photo_after_save.png`. Pulled DB
  proof `.codex/artifacts/2026-04-12/s21_live_run_after_photo_rename_synced.db`
  shows `filename = S21_rename_proof_2026-04-12.jpg`, `file_path` still null,
  original `remote_path` preserved, updated notes saved, and both photo update
  change-log rows processed. `/driver/sync` returned `success=true`,
  `pushed=2`, `pulled=0`, `errors=[]`, and `/driver/sync-status` returned
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`; log proof
  `.codex/artifacts/2026-04-12/s21_live_run_photo_rename_sync_logcat.txt`
  records `Sync cycle (full): pushed=2 pulled=0 errors=0`.
- `PASS` S21 contained personnel proof on 2026-04-12: the same live-run S21
  session opened Hoffman Brothers contractor edit mode, exposed Foreman,
  Laborer, and Operator counter controls, then opened the contained
  `Manage Personnel Types` dialog with the current type list and delete icons
  visible without mutating data. Screenshots:
  `.codex/artifacts/2026-04-12/s21_personnel_counter_edit_mode.png` and
  `.codex/artifacts/2026-04-12/s21_personnel_type_manager_dialog_contained.png`;
  sync stayed clean and error scan
  `.codex/artifacts/2026-04-12/s21_personnel_dialog_error_scan.txt` is empty.
- `PASS` Focused local verification for the photo fix:
  `flutter test test/services/photo_service_test.dart --reporter expanded`
  passed 9 tests, including remote-backed metadata rename and no-local/no-remote
  rejection cases; `flutter analyze lib/services/photo_service.dart
  test/services/photo_service_test.dart` passed with no issues.
- Post-red-screen IDR photo export repair build installed on `RFCNC0Y975L`:
  SHA-256
  `F6FCC022B8786FF217BFA85FC638CA1FCAD440B520A904A274C0363A62AFED6D`,
  package `com.fieldguideapp.inspector`, `versionCode=3`,
  `versionName=0.1.2`, `lastUpdateTime=2026-04-11 15:25:00`.
- Red-screen evidence captured before repair:
  `.codex/artifacts/2026-04-11/s21_current_after_redscreen_before_fix_install.png`;
  post-repair preview/export screenshots:
  `.codex/artifacts/2026-04-11/s21_idr_photo_preview_after_fix.png` and
  `.codex/artifacts/2026-04-11/s21_current_after_final_build_export_completed.png`.
- Post-repair IDR/photo bundle proof:
  `.codex/artifacts/2026-04-11/s21_idr_photo_policy_export_final_build/`
  contains `IDR_04-11.pdf`, `2026-04-11 0582B Density 864130.pdf`,
  `2026-04-11 1174R Concrete 864130.pdf`, and
  `2026-04-11 Photo (North approach demo photo) 864130.pdf`.
- Post-repair parsed proof:
  `.codex/artifacts/2026-04-11/s21_idr_photo_policy_export_final_build_inspection.json`
  records `IDR` `exportFieldCount=179`, `templateFieldCount=179`,
  `fieldNamesEqual=true`; `0582B` `exportFieldCount=270`,
  `templateFieldCount=270`, `fieldNamesEqual=true`; the photo PDF is present
  as a one-page exported attachment.
- Post-repair log proof:
  `.codex/artifacts/2026-04-11/s21_idr_photo_policy_export_final_build_logcat.txt`
  records `Folder export complete` and the expected photo filename; the sampled
  post-fix window contains no matching `Failed assertion`,
  `RenderObject.getTransformTo`, `StreamSink is bound`, `Platform error`, or
  `ANR in` lines.
- Sync status after the post-repair export stayed clean:
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.
- Real-auth driver APK installed on `RFCNC0Y975L`: SHA-256
  `D1500233F6871839DAAADEE4ECF4DEE879AA9C20B8FE7A53D4AB1BAF6784DC7F`,
  package `com.fieldguideapp.inspector`, `versionCode=3`,
  `versionName=0.1.2`, `lastUpdateTime=2026-04-11 14:57:21`.
- Startup route proof: `/driver/ready` reports `screen=/projects`; the
  screen-contract diagnostic reports `ProjectListScreen`, `hasBottomNav=true`,
  `canPop=false`, and compact S21 dimensions `384x853.333`.
- Real sync proof after explicit sync: `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`, `isSyncing=false`, and sync transport
  `wasSuccessful=true` with `errors=0`.
- Screenshot proof:
  `.codex/artifacts/2026-04-11/s21_after_real_auth_install.png`.

## Logical Commit Plan

- [ ] Docs/tracker consolidation.
- [ ] Analyzer and CI quality-gate repair.
- [ ] Custom lint enforcement.
- [x] DB/Supabase Office Technician and review-comment migrations.
- [ ] Auth/project role and permission behavior.
- [x] TODO/review-comment behavior.
- [ ] Forms/PDF/IDR behavior.
- [x] Pay-app/order fixes if any remain.
- [ ] Calculator/photo/personnel UX.
- [ ] Sync/auth hardening and resume recovery.
- [ ] CodeMunch structural cleanup.
- [ ] Final test/CI triage.

## Three-Agent Reconciliation Addendum - 2026-04-11

This addendum reconciles the central tracker against:

- `.codex/plans/2026-04-11-final-s21-verification-adaptive-idr-plan.md`
- `.codex/plans/2026-04-11-pay-app-form-contractor-review-final-verification-spec.md`
- `.codex/plans/2026-04-11-pay-app-form-final-verification-plan.md`
- `C:\Users\rseba\Downloads\Field Guide App - 2026-04-10 Comprehensive Pre-Production Audit.zip`

Findings:

- `PASS / CLOSED` The old 2026-04-10 blockers for analyzer/CI honesty,
  schema-version drift, sign-out fail-soft, inactivity fail-open, sync-repair
  fail-soft, full-suite credibility, stale `FormsListScreen`, and PDF
  extraction dependency cycles are already closed or superseded by later tracker
  evidence.
- `PASS / CLOSED` Pay app workbook/export, contractor comparison, quantity
  ordering, fixed-template 0582B/1126/1174R/IDR all-cell proof, calculators,
  and sync/background-resume hardening remain closed unless a new regression is
  found.
- `DOC CLEANUP` Pay-app evidence must use the singular current truth:
  canonical company `Quantities` workbook, no legacy `G703` workbook path, and
  generated workbooks frozen at `G1`; older `KJ1` and `G703-style` references
  are historical evidence only.
- `DOC CLEANUP` Calculator evidence must keep the scope explicit: HMA Yield and
  HMA weighback are toolbox calculators; the quantity-entry calculator is the
  generic `Calculator` with unit switching across quantity units and no HMA
  tab.
- `PASS / CLOSED` Supabase credential and target migration blocker is closed:
  service-role REST checks pass, `.env.secret` has a working `DATABASE_URL`,
  migrations `20260411040000_add_office_technician_role.sql` and
  `20260411040500_todo_review_comment_metadata.sql` are applied remotely, and
  schema/RPC proof shows the Office Technician role and review-comment TODO
  metadata are present.
- `PASS / CLOSED` Review-comment verification preserves the later privacy
  and assignment-scoping rules: review comments are synced `todo_items`, gated
  by `AuthProvider.canReviewInspectorWork`, assigned through
  `assigned_to_user_id`, sourced by `source_type = review_comment` and
  `source_id = entryId`, visible only in the correct inspector TODO/dashboard
  views, and cleared when the assigned inspector completes the TODO. 2026-04-12
  S21 proof completed the assigned review-comment TODOs, synced the completion,
  and verified the dashboard notification cleared.
- `PASS / CLOSED` Office Technician proof completed live Windows and S21
  verification: admin can approve/update Office Technician users; Office
  Technician can create projects and assign inspectors; Office Technician can
  review inspector entries; Office Technician does not gain admin-only account
  controls; the temporary role was restored after proof.
- `PASS / RELEASE BASELINE` The official fixed-template AcroForm IDR export
  remains the release baseline. Adaptive IDR editability is not required for
  prerelease replacement unless that lane is explicitly promoted later.
- `PASS / CLOSED` S21 product proof for compact form/table-entry layout,
  photo filename editing, the contained personnel picker, toolbox concrete
  Area/Volume unit switching, and quantity ordering is closed by 2026-04-12
  S21 live-run proof plus focused tests.
- `OPEN / RELEASE GATE` Final evidence must include APK hash/install time,
  artifact paths, screenshots where appropriate, parsed PDF/workbook proof, DB
  proof, sync-status proof, explicit self-review, and a separate
  completeness-agent review.

Execution order:

1. Keep the saved `.env.secret` `DATABASE_URL` and GitHub
   `SUPABASE_DATABASE_URL` schema guard active.
2. Keep the real-auth S21 driver build as the preferred live proof surface; use
   hot reload for Dart/UI iteration when possible.
3. Treat `shared.dart` barrel cleanup and central seam watchlist items as
   phased hygiene unless a release-blocking regression appears.
4. Run the final completeness review last.

## 2026-04-12 Auth And Provider Seam Security Audit

- `PASS / BROADENED AUDIT` The auth review was expanded beyond the prior
  mock-auth search. Audited seams now include `AuthProvider`, router redirect
  order, inactivity/reauth, profile/company derivation, `SessionService`,
  project mutation gates, daily-entry ownership gates, review-comment TODO
  scoping, quantity writes, pay-app/export providers, photo/calculator write
  defaults, and sync payload stamping. Remaining watchlist items are offline
  cached-profile permission staleness and force-reauth local/backend sign-out
  divergence; neither was changed in this pass because both need policy
  decisions around offline behavior and upgrade recovery.
- `PASS / DAILY ENTRY OWNER GATE` `DailyEntryProvider` now enforces entry
  ownership at the provider mutation boundary, not only in the UI. `createEntry`
  blocks forged `createdByUserId`, stamps missing ownership from the current
  user, `updateEntry` stamps `updatedByUserId`, and update/delete/submit/batch
  submit/undo-submit all verify the loaded entry owner before mutating.
- `PASS / TODO PRIVACY GATE` Review-comment TODO visibility now fails closed
  when `currentUserId` is unavailable. Assigned review comments are counted as
  visible only when the active user matches `assignedToUserId`.
- `PASS / PROJECT ROLE GATE` `ProjectProvider.createProject` and
  `ProjectProvider.updateProject` now use the same `canManageProjects` provider
  boundary as archive/activate. This closes the previous UI-only management
  gate for project create/update.
- `PASS / QUANTITY WRITE GATE` `EntryQuantityProvider` now requires an
  AuthProvider-derived `canWrite` callback and blocks all quantity mutation
  methods before repository writes: add, update, remove, save-for-entry,
  delete-for-entry, and delete-for-bid-item.
- `PASS / SYNC CONTEXT FALLBACK CLOSED` `SyncCoordinatorBuilder` now requires
  an auth-derived `syncContextProvider`; the raw static `companyId`/`userId`
  fallback was removed so sync cannot be accidentally initialized with
  arbitrary tenant/user context.
- `PASS / FAIL-CLOSED DEFAULTS` Provider write guard defaults were changed from
  allow-by-default to deny-by-default for shared `BaseListProvider`,
  `TodoProvider`, `EquipmentProvider`, `CalculatorProvider`, `PhotoProvider`,
  and pay-app export/comparison providers. App DI still wires the real
  `AuthProvider.canEditFieldData` permission at composition roots.
- `PASS / LINT LOCK` Added custom lint rules
  `provider_write_guards_fail_closed` and `auth_provider_write_contract_sync`.
  They block provider write guards from drifting back to default-allow and keep
  the auth-sensitive prerelease seams above locally gated.
- `PASS / LOCAL VERIFICATION` Passed:
  `dart run custom_lint`; targeted `flutter analyze` for touched auth/provider
  files and tests; `dart test` for the new lint rule tests from
  `fg_lint_packages/field_guide_lints`; and focused provider/security tests for
  daily entries, TODOs, projects, quantities, pay applications, export
  artifacts, photos, and contractor editing. Later logging hardening also
  passed focused logging/Sentry sanitizer tests and the strengthened live
  Supabase schema/RLS/storage contract.
- `PASS / RLS POLICY DRIFT GUARD` The live Supabase schema contract now checks
  registered sync tables for live RLS enabled plus policies and registered file
  buckets for private storage plus object policies. First run found live drift:
  `entry_equipment` had RLS disabled. Fixed live with
  `ALTER TABLE public.entry_equipment ENABLE ROW LEVEL SECURITY;`, added
  migration `20260412120000_enable_entry_equipment_rls.sql`, marked that
  migration applied in remote history, and reran the live contract to green.
- `PASS / LOGGING SECURITY SEAM` Audited the logging facade, file/HTTP
  transports, Sentry transport, Sentry before-send PII filter, and support log
  upload seam. Tightened freeform log scrubbing so key/value secrets are
  redacted before category logs, flat app logs, debug HTTP, Sentry, and
  support-upload paths; changed Sentry error reporting to receive sanitized
  error/stack payloads; and updated support log bundles to include both flat
  app logs and detailed per-category session logs. Added
  `logging_security_contract_sync` so these contracts are lint-locked.
- `PASS / DEVICE PROOF` S21 live proof resumed on 2026-04-12 through
  `scripts/flutter_run_endpoint.ps1` control port `4953`, app driver port
  `4951`, and host forward `4954 -> 4951`. After one required hot restart for
  route-table closure refresh, `/driver/sync` returned
  `success=true,pushed=0,pulled=0,errors=[]`, `/driver/sync-status` returned
  `pendingCount=0,blockedCount=0,unprocessedCount=0,isSyncing=false`, and the
  post-restart log scan found no fatal/assertion/overflow/ANR/platform/null-
  route errors.
- `PASS / ENTRY PAY ITEM EDIT UX` Entry editor "Pay Items Used" rows now treat
  bid item names as canonical/read-only. The entry-row edit action only edits
  entered quantity plus entry-specific description/notes; pay item name changes
  remain in the Pay Items/Bid Items screen. S21 proof added a quantity,
  entered edit mode, confirmed the locked pay-item label, confirmed quantity
  and description fields were enabled, confirmed the old swap key was absent,
  saved `2.00 LS` with `S21 entry quantity description proof`, and synced the
  change cleanly. Local regression:
  `flutter test test/features/entries/presentation/widgets/entry_quantity_editing_row_test.dart`.
- `PASS / REVIEW SESC ACTION` The Mark Ready/Review preview rows now use a
  taller preview layout and stable per-field action keys. S21 proof selected
  the April 6 draft, tapped `review_field_action_sesc_measures`, and verified
  `report_sesc_field` opened visible/enabled in Safety & Site Conditions on
  the restarted build. Local regressions:
  `flutter test test/features/entries/presentation/widgets/review_field_row_test.dart
  test/features/entries/presentation/screens/entry_editor_route_binding_test.dart`.
- `PASS / REVIEW ROUTE FAIL-SOFT` Live S21 sync exposed a red-screen route
  bug: `/review` could rebuild after GoRouter lost `state.extra`, causing
  `Null check operator used on a null value` in
  `lib/core/router/routes/entry_routes.dart`. The review and review-summary
  builders now fail soft when `extra` is missing or malformed instead of
  force-unwrapping. Local regression:
  `flutter test test/core/router/app_router_test.dart` covers review routes
  without extra data.

## 2026-04-12 Items 3 And 4 Closure Addendum

- `PASS / OFFLINE AUTH FRESHNESS POLICY` Cached inspector profiles now preserve
  normal offline-first field-data edits for a 7-day window, using the most
  recent remote profile confirmation or cached `last_synced_at` as the
  freshness reference. Shared management actions now require a remote-confirmed
  profile within the 24-hour server-contact window: project create/manage,
  project delete, and review/office-tech shared-review capabilities no longer
  rely on stale cached roles. `AuthProvider.updateLastActive()` triggers a
  best-effort profile refresh when the 24-hour attempt window is due, aligning
  with the existing forced-sync-on-resume policy without blocking inspector
  daily workflow while offline.
- `PASS / FORCE REAUTH LOCAL LOCKOUT` Force-reauth now routes through
  `AuthProvider.forceReauthOnly()` instead of ordinary `signOut()`, so local
  auth/UI state, profile/company state, secure activity/profile freshness
  markers, attribution cache, and background sync are cleared even if backend
  Supabase sign-out throws. Ordinary user sign-out still preserves local auth
  state on backend sign-out failure.
- `PASS / LINT LOCK` `auth_provider_write_contract_sync` now locks the
  offline-auth freshness and force-reauth local-lockout contract, and
  `max_sync_component_file_length` no longer grandfathers
  `lib/features/sync/engine/local_sync_store.dart`.
- `PASS / LOCALSYNCSTORE SEAM SPLIT` `LocalSyncStore` is now a thin 65-line
  composed facade; record/trigger, metadata/diagnostic, and synced-scope
  delegates live in `local_sync_store_records.dart`,
  `local_sync_store_metadata.dart`, and `local_sync_store_scope.dart`. Each new
  sync seam is below the 300-line sync component cap.
- `PASS / PROJECT PROVIDER SEAM SPLIT` `ProjectProvider` extension-owned
  behavior is now composed through real mixins, so mocks and implementers see
  the same provider API that production uses. This fixed the private
  `_mergedProjects` extension-dispatch drift exposed by broad widget tests
  without adding test-only hooks.
- `PASS / LOGGING SENTINEL SCRUBBING` JWT scrubbing now preserves the intended
  `[JWT]` sentinel after freeform key/value redaction instead of re-redacting
  it as a generic token value. Focused logging/Sentry tests cover the sanitizer
  and logger paths.
- `PASS / SYNC DASHBOARD PHONE OVERFLOW` The long conflict-code badge in the
  Sync Dashboard status row now flexes and ellipsizes on phone width, closing
  the overflow found during the broad widget sweep.
- `PASS / CONTRACTOR COMPARISON SCREEN REGRESSION` The contractor comparison
  driver-file injection widget test now uses mocked use cases/parser seams for
  the screen layer, leaving real file parsing to the parser/provider tests.
  This avoids real file I/O inside `testWidgets` fake async while still proving
  injected contractor files bypass the platform picker.
- `PASS / LOCAL VERIFICATION` Passed:
  `flutter test test/features/auth/presentation/providers/auth_provider_test.dart
  test/features/auth/domain/use_cases/load_profile_use_case_test.dart
  --reporter expanded`; `flutter test
  test/features/sync/application/post_sync_hooks_test.dart
  test/features/auth/presentation/providers/auth_provider_test.dart
  test/features/auth/domain/use_cases/load_profile_use_case_test.dart
  --reporter expanded`; focused `flutter analyze` for touched auth/sync files;
  `flutter analyze lib test`; `flutter test
  test/features/sync/engine/maintenance_handler_test.dart
  test/features/sync/engine/maintenance_handler_contract_test.dart --reporter
  expanded`;
  `dart test test/architecture/auth_provider_write_contract_sync_test.dart
  test/architecture/logging_security_contract_sync_test.dart --reporter
  expanded` inside `fg_lint_packages/field_guide_lints`; and `dart run
  custom_lint`. Final follow-up on 2026-04-12 also passed:
  `flutter test test/features/entries/presentation/widgets/entry_activities_section_test.dart
  test/features/pay_applications/presentation/screens/contractor_comparison_screen_test.dart
  test/features/projects/presentation/screens/project_save_navigation_test.dart
  test/features/quantities/presentation/screens/quantities_screen_export_flow_test.dart
  test/features/sync/presentation/screens/sync_dashboard_screen_test.dart
  --reporter expanded`; `flutter analyze lib test`; `dart run custom_lint`;
  full `dart test --reporter expanded` inside
  `fg_lint_packages/field_guide_lints`; and full `flutter test --reporter
  expanded`.
