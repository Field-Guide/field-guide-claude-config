# Tooling Consolidation And PDF Extraction Corpus Standardization

Status: completed
Created: 2026-05-06
Completed: 2026-05-06

## Goal

Standardize repo tooling under `tools/`, clean out deprecated scripts, and make
PDF extraction iteration use one canonical corpus path with cached OCR replay
and exact 28-PDF reporting.

## Phase 1: PDF Extraction Corpus Naming

- [x] Rename `pre_release_pdf_corpus` surfaces to `pdf_extraction_corpus`.
- [x] Rename the integration harness to `integration_test/pdf_extraction_corpus_test.dart`.
- [x] Rename the helper folder to `integration_test/pdf_extraction_corpus/`.
- [x] Rename corpus fixture files to `pdf_extraction_corpus_manifest.json` and `pdf_extraction_corpus_expected.json`.
- [x] Update tests, docs, AGENTS files, rules, and command examples to use the new names.
- [x] Keep `PDF_CORPUS_*` env vars.

## Phase 2: Canonical PDF Extraction Gate

- [x] Make `PDF_CORPUS_OCR_CACHE_MODE=replay` the only cached trust path.
- [x] Ensure replay runs full local extraction with cached OCR responses.
- [x] Ensure replay does not start from normalized OCR or captured stage outputs.
- [x] Remove `fast_replay` from the corpus harness and cache enum.
- [x] Remove `PDF_CORPUS_FAST_REPLAY_TRACE_DIR`.
- [x] Demote `deleted cached-stage extraction API` and `gocr_downstream_replay_test.dart` to diagnostics only.
- [x] Remove the one-document tracked corpus baseline from the trust path.

## Phase 3: Canonical PDF Reporting

- [x] Add canonical corpus report output under `tools/testing/test-results/YYYY-MM-DD/`.
- [x] Report document counts, expected rows, actual rows, exact rows, exact field counts, row accuracy, field accuracy, missing rows, unexpected rows, unit violations, and failure buckets.
- [x] Report deltas versus the prior accepted baseline.
- [x] Support focused diagnostic runs, but mark them clearly as non-acceptance.
- [x] Require full unfiltered 28-PDF corpus results before accepting extraction rule changes.

## Phase 4: Move PDF Tooling Under `tools/pdf-extraction/`

- [x] Move `scripts/audit_pdf_extraction_replay.ps1` to `tools/pdf-extraction/`.
- [x] Move `scripts/run_s21_pdf_corpus_capture_with_mirror.ps1` to `tools/pdf-extraction/`.
- [x] Move `scripts/verify_pdf_ground_truth_fidelity.py` to `tools/pdf-extraction/`.
- [x] Move `scripts/generate_pdf_corpus_row_review_ledgers.py` to `tools/pdf-extraction/`.
- [x] Move `scripts/generate_mdot_ground_truth.py` to `tools/pdf-extraction/`.
- [x] Move `scripts/generate_mdot_schedule_samples.ps1` to `tools/pdf-extraction/`.
- [x] Move `scripts/generate_mdot_companion_mp_pdfs.py` to `tools/pdf-extraction/`.
- [x] Move `scripts/download_mdot_public_pdf_corpus.ps1` to `tools/pdf-extraction/`.
- [x] Move `tool/google_ocr_cache_inspector.dart` to `tools/pdf-extraction/`.
- [x] Move `tools/gocr_trace_viewer.html` to `tools/pdf-extraction/`.
- [x] Move `tools/pipeline_comparator.dart` to `tools/pdf-extraction/`.
- [x] Move `tools/debug-server/watch-pdf-extraction.ps1` to `tools/pdf-extraction/`.
- [x] Update every command, test, doc, and usage string for the new paths.
- [x] Do not leave compatibility wrappers.

## Phase 5: Move PDF/Form/Pay-App Probes

- [x] Move `tool/inspect_pdf_form_fields.dart` to `tools/pdf-tools/`.
- [x] Move `tool/testing/pdf_contract_probe.dart` to `tools/pdf-tools/`.
- [x] Move `tool/testing/pay_app_xlsx_contract_probe.dart` to `tools/pay-app/`.
- [x] Move or classify `tools/verify_idr_mapping.py`.
- [x] Update PowerShell harness references and usage strings.
- [x] Remove the empty `tool/` root.

## Phase 6: Consolidate Remaining Tooling Roots

- [x] Move CI scripts from `scripts/ci/` to `tools/ci/`.
- [x] Move schema, migration, rollback, and Supabase verification scripts into `tools/ci/` or `tools/supabase/`.
- [x] Move build/security/native asset scripts into `tools/build/`.
- [x] Move driver start/stop/flutter-run helpers into `tools/driver/`.
- [x] Move local Supabase helpers into `tools/supabase/`.
- [x] Move sync soak wrappers into `tools/sync/` or existing `tools/testing/`.
- [x] Keep `tools/testing/` as the canonical testing harness root.
- [x] Keep `tools/gen-keys/` as-is.
- [x] Move git hook files to `tools/git-hooks/` or `.githooks/`.

## Phase 7: Delete Deprecated One-Off Tools

- [x] Delete unreferenced local window/taskbar helpers.
- [x] Delete old loose failure-parsing helpers superseded by test-result reports.
- [x] Delete unreferenced lock/debug scratch helpers.
- [x] Delete `tools/debug-server/upload-test.json` if still unreferenced.
- [x] Classify `tools/vcpkg/` as vendor tooling or move it out of the general tooling bucket after verifying Windows OCR build requirements.

## Phase 8: Verification

- [x] Run `rg "scripts/|scripts\\\\|tool/|tool\\\\"` and resolve all active references.
- [x] Run PDF corpus manifest and fixture contract tests.
- [x] Run MDOT corpus manifest test.
- [x] Run ground-truth fidelity verification.
- [x] Run canonical cached PDF extraction corpus replay.
- [x] Run `tools/testing/Test-TestingHarness.ps1` after testing/driver/sync path moves.
- [x] Check GitHub workflow paths.
- [x] Check Dart CLI usage strings.
- [x] Commit in logical slices: PDF naming, PDF trust-path cleanup, PDF tooling moves, reporting upgrade, docs, remaining tooling consolidation.
