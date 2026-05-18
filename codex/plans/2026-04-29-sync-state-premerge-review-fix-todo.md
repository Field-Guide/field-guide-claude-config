# sync-state Premerge Review Fix Todo

Branch: `sync-state`
Base: `origin/main...HEAD`
Created: 2026-04-29

## Current Implementation Status

- [x] Local code fixes implemented for sync status settling, support/Sentry
  reporting, Help & Support send failure state, entry draft visibility,
  delete follow-up retry, foreign draft file purge, maintenance phase
  reporting, bid-item generated keys, M&P normalization, Saugatuck M&P fixture
  body normalization, fixture provenance contracts, decimal-comma currency
  traces, and stale custom-lint references.
- [x] Local static and focused test gates passed; see final turn summary for
  command list.
- [ ] Live Supabase real-auth sync/RLS proof not run in this workspace session.
- [ ] Enabled original-four/full-corpus GOCR replay not run because the default
  normalized OCR cache (`.tmp/pdf_extraction_corpus_ocr_cache`) is not present; the opt-in
  harness helper tests were run and passed.

## Merge Blockers

- [ ] Fix stale sync status overwrite.
  - Issue: `SyncRunExecutor` captures `currentStatus`, awaits
    `onSyncComplete`, then writes stale `settledStatus` over the provider's
    refreshed pending/conflict counts.
  - Fix: build the final non-syncing status from `_statusStore.current` after
    `onSyncComplete`, or move the status settle before the completion callback
    without losing refreshed diagnostics.
  - Verify:
    - [ ] Add/adjust a focused unit test proving async `onSyncComplete`
      updates to `pendingUploadCount`, `undismissedConflictCount`, and
      `lastSyncedAt` survive the final status settle.
    - [ ] Run
      `flutter test test/features/sync/engine/sync_engine_status_test.dart test/features/sync/presentation/providers/sync_provider_test.dart --reporter=compact`.
    - [ ] Run one live UI-triggered sync and confirm driver diagnostics show
      final `pending=0`, `blocked=0`, `unprocessed=0`, `errors=0`.

- [ ] Fix support-report Sentry privacy and delivery contract.
  - Issue: feedback events can be dropped by global Sentry filtering,
    reporter correlation is stripped, and `problem_report` contexts bypass
    scrubbing.
  - Fix:
    - [ ] Exempt `category=feedback` events from drop-only runtime filters, or
      send feedback through a dedicated path with equivalent protection.
    - [ ] Store a non-PII correlation value, such as a generated report ID or
      scrubbed internal user reference, that survives `beforeSend`.
    - [ ] Scrub all Sentry feedback contexts, including `projectId`,
      `subject`, `issueCode`, `issueTitle`, `deviceInfo`, and log snippets.
    - [ ] Log/display the Sentry event/report ID enough for support
      correlation.
  - Verify:
    - [ ] Add tests to `test/core/config/sentry_pii_filter_test.dart` for
      feedback exemption, context scrubbing, user/request stripping, and
      retained correlation.
    - [ ] Add Help & Support tests for a successful report path and disabled
      unavailable path.
    - [ ] Run
      `flutter test test/core/config/sentry_pii_filter_test.dart test/features/settings/presentation/screens/help_support_screen_test.dart test/features/settings/about_section_test.dart --reporter=compact`.

- [ ] Fix Help & Support send failure handling.
  - Issue: `_isSendingReport` can remain true if log reading or
    `Sentry.captureMessage` throws.
  - Fix: wrap send in `try/catch/finally`, reset sending state when mounted,
    set a user-facing error, and log through `Logger.error`.
  - Verify:
    - [ ] Add a widget/provider test where the launcher throws and the form
      returns to an enabled state with an error message.
    - [ ] Run
      `flutter test test/features/settings/presentation/screens/help_support_screen_test.dart --reporter=compact`.

- [ ] Decide and restore support fallback behavior.
  - Issue: the branch removes the local SQLite `support_tickets` submission
    path and makes Sentry availability a hard dependency for manual reports.
  - Fix: either restore an app-owned durable fallback queue, or document and
    test the product decision that no report can be sent without Sentry.
  - Verify:
    - [ ] If fallback is restored, add datasource/repository/provider tests
      proving queued local reports sync through existing support adapter.
    - [ ] If fallback is intentionally removed, add UI tests for clear
      unavailable state and update sync adapter/docs to make legacy-only scope
      explicit.

- [ ] Fix draft entry visibility leak.
  - Issue: `DailyEntryProvider.loadItems()` calls `super.loadItems()` and
    notifies listeners with all entries before filtering foreign drafts.
  - Fix: load/filter before assigning provider state, or move owner/status
    filtering into a production data/use-case seam that cannot notify
    unfiltered rows.
  - Verify:
    - [ ] Add a provider test with a listener that fails if foreign drafts are
      ever visible during load.
    - [ ] Add/keep tests proving own drafts and submitted entries remain
      visible.
    - [ ] Run
      `flutter test test/features/entries/presentation/providers/daily_entry_provider_filter_test.dart --reporter=compact`.

- [ ] Preserve null-owner legacy draft behavior or explicitly migrate it.
  - Issue: `_isEntryVisibleToCurrentUser()` hides draft entries with
    `createdByUserId == null`, conflicting with the existing legacy editable
    contract.
  - Fix: either keep null-owner drafts visible to the current local user until
    migration ownership is assigned, or add a migration/repair that assigns
    ownership before enforcing visibility.
  - Verify:
    - [ ] Add provider tests for null-owner drafts.
    - [ ] Add migration/repair test if choosing ownership backfill.

- [ ] Fix Entry Review driver/sentinel contract.
  - Issue: the screen contract still requires the review-comment action, but
    the UI now hides it for draft/current-user entries.
  - Fix: update the driver contract and fixture posture to a submitted
    reviewable entry, or make the sentinel conditional on entry status and
    reviewer role.
  - Verify:
    - [ ] Repair `entry_review_sentinel_test.dart`.
    - [ ] Run
      `flutter test test/features/entries/presentation/screens/entry_review_sentinel_test.dart --reporter=compact`.

## Sync / Delete Follow-Up

- [ ] Fix delete follow-up sync gate race.
  - Issue: `DeleteFollowUpSyncService` retries when the pre-check sees an
    active gate, but drops the request when the coordinator returns a skipped
    `SyncResult(errors: 1, "already in progress")`.
  - Fix: inspect the result and requeue retryable skipped/in-progress results.
  - Verify:
    - [ ] Add a test where `requestFullSync` returns a skipped/in-progress
      error after the gate pre-check returns false.
    - [ ] Run
      `flutter test test/features/sync/application/delete_follow_up_sync_service_test.dart --reporter=compact`.

- [ ] Clean local files when purging foreign draft rows.
  - Issue: `LocalSyncStore.purgeForeignDraftEntries()` hard-deletes rows from
    file-backed tables without collecting/deleting local paths.
  - Fix: reuse the same file-path collection/deletion seam used by project
    local eviction, or route foreign draft cleanup through a dedicated
    file-aware executor.
  - Verify:
    - [ ] Add a test with foreign draft `photos`, `documents`,
      `form_exports`, or `entry_exports` containing local file paths and prove
      files are removed.
    - [ ] Run
      `flutter test test/features/sync/application/sync_recovery_service_test.dart --reporter=compact`.

- [ ] Improve maintenance error phase reporting.
  - Issue: escaped orphan-scan/metadata failures are logged as
    `integrity check failed` and can suppress independent local orphan purge.
  - Fix: give orphan maintenance its own error boundary and phase-specific log
    message; preserve local orphan purge when storage scan fails and purge is
    still appropriate.
  - Verify:
    - [ ] Add tests for storage orphan scan failure still recording a
      phase-specific error and running or skipping local purge deliberately.
    - [ ] Run
      `flutter test test/features/sync/engine/maintenance_handler_test.dart test/features/sync/engine/maintenance_handler_contract_test.dart --reporter=compact`.

- [ ] Add live RLS proof for draft entry visibility.
  - Issue: SQL migration `can_select_entry_content()` lacks live RLS proof.
  - Verify:
    - [ ] Against real Supabase auth/session, prove foreign drafts and child
      rows are not selectable.
    - [ ] Prove own drafts are selectable.
    - [ ] Prove submitted entries remain visible to project/company peers.
    - [ ] Capture screenshots/debug logs and final sync diagnostics with
      `errors=0`, `rlsDenials=0`.

## Projects / Testing Keys

- [ ] Fix bid-item unit key drift.
  - Issue: default units now render `LFT/SFT/SYD/CYD/LSUM`, but generated
    testing keys still target old `FT/LF/SY/CY/LS` options.
  - Fix: update `tools/gen-keys/keys.yaml`, regenerate Dart/PowerShell/JSON
    key outputs, and map keys to the rendered standard units.
  - Verify:
    - [ ] Add/update dialog tests to select new standard units by generated
      key, not visible text only.
    - [ ] Run key generation idempotence check.
    - [ ] Run
      `flutter test test/features/projects/presentation/widgets/bid_item_dialog_test.dart --reporter=compact`.

## PDF / M&P Extraction

- [ ] Fix M&P single-letter over-join.
  - Issue: `_repairMpSingleLetterSplits()` repairs `D ewatering` but can
    corrupt legitimate designators such as `Type B aggregate`.
  - Fix: constrain the repair to hard-line/native fracture evidence or a small
    allowlist of known OCR-fractured words instead of any single letter plus
    lowercase word.
  - Verify:
    - [ ] Add tests for `D ewatering` staying repaired.
    - [ ] Add tests for `Type B aggregate`, `Class C concrete`, and similar
      designators staying unchanged.
    - [ ] Run
      `flutter test test/features/pdf/services/mp/mp_extraction_service_test.dart --reporter=compact`.

- [ ] Fix Saugatuck M&P fixture expectations.
  - Issue: expected M&P bodies include page header/footer text that production
    strips, so exact comparisons may not test normalized production output.
  - Fix: update expected entries from production-normalized visual review, or
    adjust the contract to compare the correct normalized field.
  - Verify:
    - [ ] Run fixture contract tests.
    - [ ] Run exact M&P extraction comparison for Saugatuck.

- [ ] Fill Saugatuck fixture provenance.
  - Issue: fixture rows contain provenance fields but leave `source_page`,
    `source_row_y`, and `source_item_id` empty/null.
  - Fix: populate usable source provenance from visual review or exported
    trace data.
  - Verify:
    - [ ] Strengthen fixture contract to reject empty/null provenance for
      reviewed rows.
    - [ ] Run
      `flutter test test/features/pdf/extraction/integration/gocr_ground_truth_fixture_contract_test.dart --reporter=compact`.

- [ ] Add decimal-comma currency interpretation trace.
  - Issue: `$ 8,000,00` is repaired silently in
    `NumericLikeNormalizer`, bypassing `CurrencyRuleSet` numeric interpretation
    trace.
  - Fix: add a currency rule with stable `matched_pattern`, parsed counts, and
    stage trace details that matches the final parsed behavior.
  - Verify:
    - [ ] Add tests in numeric interpreter and row parser cell-field parser.
    - [ ] Run
      `flutter test test/features/pdf/extraction/shared/post_process_utils_test.dart test/features/pdf/extraction/stages/row_parser_cell_field_parser_test.dart --reporter=compact`.

- [ ] Run PDF replay gates after heuristic/fixture fixes.
  - Verify:
    - [ ] Run touched/adjacent PDF unit tests.
    - [ ] Run original-four cached replay.
    - [ ] Run full cached-corpus replay.
    - [ ] Run replay audit:
      `powershell -ExecutionPolicy Bypass -File tools/pdf-extraction/audit_pdf_extraction_replay.ps1 -RunDir <run_dir>`.
    - [ ] Confirm no original-four or full-corpus regression before merge.

## Lint / Guardrails

- [ ] Remove stale custom-lint references to deleted support files.
  - Issue: lint guardrails still reference deleted support local datasource and
    submit support ticket use case.
  - Fix: update allowlists/contracts to point to the current Sentry feedback
    owner or restored support fallback seam.
  - Verify:
    - [ ] Run
      `dart run custom_lint`.
    - [ ] Run targeted lint package tests if present.

## Hygiene Extraction Completed

- [x] Extract maintenance orphan planning/execution from
  `maintenance_handler.dart`.
- [x] Extract maintenance phase timing/metrics recording.
- [x] Extract generic delete/restore/purge storage cleanup support from
  `generic_local_datasource.dart`.
- [x] Verify extraction:
  - [x] `flutter analyze`
  - [x] `dart run custom_lint`
  - [x] `git diff --check`
  - [x] `flutter test test/features/sync/engine/maintenance_handler_test.dart test/features/sync/engine/maintenance_handler_contract_test.dart test/features/pay_applications/data/datasources/local/export_artifact_local_datasource_test.dart --reporter=compact`

## Final Premerge Gate

- [ ] Run full static checks:
  - [ ] `flutter analyze`
  - [ ] `dart run custom_lint`
  - [ ] `git diff --check`
- [ ] Run focused branch tests:
  - [ ] `flutter test test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/maintenance_handler_test.dart test/features/sync/engine/maintenance_handler_contract_test.dart test/features/sync/application/delete_follow_up_sync_service_test.dart test/features/sync/application/sync_recovery_service_test.dart test/features/sync/domain/sync_run_metrics_test.dart --reporter=compact`
  - [ ] `flutter test test/core/config/sentry_pii_filter_test.dart test/features/settings/about_section_test.dart test/features/settings/presentation/screens/help_support_screen_test.dart test/features/sync/adapters/support_ticket_adapter_test.dart --reporter=compact`
  - [ ] `flutter test test/features/entries/presentation/providers/daily_entry_provider_filter_test.dart test/features/entries/presentation/screens/entry_review_sentinel_test.dart --reporter=compact`
  - [ ] `flutter test test/features/projects/presentation/widgets/bid_item_dialog_test.dart --reporter=compact`
  - [ ] `flutter test test/features/pdf/extraction/integration/gocr_ground_truth_fixture_contract_test.dart test/features/pdf/extraction/shared/post_process_utils_test.dart test/features/pdf/extraction/stages/post_processing/data_consistency_test.dart test/features/pdf/extraction/stages/quality_status_selection_stage_test.dart test/features/pdf/extraction/stages/row_rescue_adjustment_stage_test.dart test/features/pdf/services/mp/mp_extraction_service_test.dart --reporter=compact`
- [ ] Run live Supabase real-auth sync proof:
  - [ ] Clean no-op warm sync.
  - [ ] Dirty row-backed sync.
  - [ ] Dirty file/delete-backed sync.
  - [ ] Confirm screenshots/logs show `pending=0`, `blocked=0`,
    `unprocessed=0`, `errors=0`, `rlsDenials=0`, pull timings, maintenance
    timings, run classification, and storage orphan-scan state.
