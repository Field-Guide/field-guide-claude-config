# Paw Paw / Lounsbury PDF Import Review And Corpus Hardening

## Summary

- Restore the PDF pay-item review gate before any import writes.
- Add Paw Paw/Lounsbury as a paired corpus project after the review UX is safe.
- Diagnose extraction issues upstream from structured OCR/table traces, not by adding document-specific fixes.

## UI Review Gate

- [ ] Reintroduce the in-place `PdfImportReviewDialog` behavior from commit `f0270f26`, adapted to current `HEAD`.
- [ ] Change the normal PDF import path so `_completeImport` opens the review dialog instead of routing directly to `import-preview`.
- [ ] Show all extracted pay items before import, with item number, description, quantity, unit, unit price, bid amount, confidence, warnings, edit, delete, select/deselect, cancel, and import.
- [ ] Keep zero-item imports fail-closed with a visible "No pay items found" dialog.
- [ ] Ensure low confidence, warnings, and math/total validation failures are visible before the user can import.
- [ ] Keep the full-screen `PdfImportPreviewScreen` only for route/debug compatibility unless later removed deliberately.
- [ ] Add a regression guard: no PDF pay-item import path may write to `BidItemProvider.importBatch` until the user confirms from the review surface.

## Validation And Confidence Rules

- [ ] Use row math only as validation/confidence evidence: `quantity * unit_price == bid_amount`.
- [ ] Use the printed bid total only as validation/confidence evidence.
- [ ] Do not mutate, normalize, repair, coerce, or overwrite parsed values from math checks.
- [ ] If row math and printed total line up, raise confidence / support acceptance.
- [ ] If row math or printed total does not line up, surface the mismatch in the review gate and keep import user-confirmed.
- [ ] Preserve raw parsed values, raw cell values, warnings, confidence, and trace provenance.

## Paw Paw / Lounsbury Corpus

- [ ] Add project key `pawpaw_866291_lounsbury`.
- [ ] Add manifest pair:
  - Pay items: `pawpaw_866291_lounsbury/pawpaw_866291_lounsbury_pay_items.pdf`
  - M&P: `pawpaw_866291_lounsbury/pawpaw_866291_lounsbury_measurement_and_payment.pdf`
- [ ] Add expected metadata:
  - `expected_item_count: 58`
  - `item_number_start: 1`
  - `item_number_end: 58`
  - `expected_bid_amount_total: 534021.00`
  - `ground_truth_verification_status: needs_visual_review_ledger`
- [ ] Add review-status entries and ledgers under the existing ground-truth review pattern.
- [ ] Generate M&P ground-truth entries from the native text layer.
- [ ] Generate pay-item draft fixtures from OCR/replay output only with `needs_visual_pdf_review` provenance.
- [ ] Keep every fixture row traceable to source PDF/page/row evidence before marking it reviewed.

## Protected Corpus Ownership

- [ ] Track the full protected PDF repertoire through Git LFS under `test/features/pdf/extraction/corpus/protected/`.
- [ ] Keep `pdf_extraction_corpus_manifest.json/default_directory` pointed at the repo-owned corpus directory, not `.tmp`, OneDrive, Desktop, or device staging.
- [ ] Add a manifest contract guard that fails if any protected pay-item or M&P PDF is missing from the tracked corpus.
- [ ] Treat `PDF_CORPUS_PROJECT_FILTER` runs as diagnostic only; extraction rule acceptance requires an unfiltered protected replay.

## Extraction Hardening

- [x] Replace Lounsbury's pay-item source with the user-supplied clean 4-page
  raster bid form from 2026-05-06. It keeps rotation `270`; rendered pages 1-4
  hash-match the prior 11-page source's bid-table pages, and support pages are
  no longer part of the protected pay-item PDF.
- [ ] Add page-span detection so pages after the bid table cannot become pay-item rows.
- [ ] Improve rotated raster OCR coordinate handling without file/project-name branching.
- [ ] Improve row grouping for repeated table headers and multi-line descriptions.
- [ ] Improve cell assignment for separated dollar signs, blue typed values, right-aligned prices, and compact numeric columns.
- [ ] Keep all production rules broad: geometry, table structure, labels, units, numeric consistency, sequence evidence, and provenance only.

## Test Plan

- [ ] Add widget tests proving PDF import opens the review dialog from the normal quantities/project import flow.
- [ ] Add a 58-item review test proving rows are visible/scrollable and confidence/edit controls are available before import.
- [ ] Add tests proving `BidItemProvider.importBatch` is not called until review-dialog import is tapped.
- [ ] Add tests for low-confidence, warning, row-math mismatch, and printed-total mismatch visibility.
- [ ] Add tests proving math validation does not mutate parsed item values.
- [ ] Run focused UI tests:
  - `flutter test test/features/pdf/presentation/helpers/import_progress_dialog_test.dart -d windows`
  - `flutter test test/features/pdf/presentation/screens/pdf_import_preview_screen_test.dart -d windows`
- [ ] Run corpus contract tests after fixture changes.
- [ ] Run Paw Paw focused replay, then the protected full-corpus replay with no regressions. The protected corpus is every project listed in `pdf_extraction_corpus_manifest.json/regression_policy.protected_project_ids`; focused `PDF_CORPUS_PROJECT_FILTER` runs are diagnostic only.

## Assumptions

- The intended import UX is the `f0270f26` confidence-review dialog flow.
- High-confidence imports may still be reviewed; low-confidence or math/total mismatch imports must always be reviewed.
- Math is an acceptance signal, not a repair mechanism.
