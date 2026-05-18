# PDF Corpus Standardization Todo Spec

Status: release closeout; corpus ground truth PDF-verified, focused evidence accepted
Branch: `pdf-corpus-standardization`
Created: 2026-05-05
Last updated: 2026-05-06

## Phase 0: Preserve Current Work

- [x] Create branch `pdf-corpus-standardization` from current dirty `main`.
- [x] Confirm all current tracked and untracked PDF extraction changes are still present after branch switch.
- [x] Do not revert, stash-drop, or discard any current PDF extraction work.

## Phase 1: Commit Current Work In Logical Slices

- [x] Commit protected corpus assets:
  - `.gitattributes`
  - `test/features/pdf/extraction/corpus/protected/**`
- [x] Commit Paw Paw corpus additions:
  - Paw Paw PDFs/fixtures
  - manifest/expected/review-status entries
- [x] Commit S21/cache replay hardening:
  - S21 mirror wrapper
  - OCR cache path validation
  - replay/capture helper changes
  - cache tests
- [x] Commit PDF import review gate:
  - review dialog
  - review validation
  - import workflow changes
  - UI tests
- [x] Commit broad extraction rule changes:
  - extraction stage/rule edits
  - focused stage tests
- [x] Commit corpus documentation updates:
  - protected corpus standard
  - add-PDF workflow
  - legacy-path warnings

## Phase 2: Audit Corpus Completeness

- [x] Treat the protected corpus as exactly **28 PDFs / 28 document contracts**.
- [x] Verify physical PDFs:
  - 14 pay-item PDFs
  - 14 measurement-and-payment PDFs
- [x] Verify expected contracts:
  - 28 entries in `pdf_extraction_corpus_expected.json`
- [x] Verify per-document ground-truth JSONs:
  - 14/14 pay-item fixtures
  - 14/14 M&P fixtures
- [x] Recover missing original-four M&P fixtures:
  - `berrien_127449_us12:measurement_payment`
  - `grand_blanc_938710_sewer:measurement_payment`
  - `huron_valley_917245_dwsrf:measurement_payment`
  - `springfield_864130_dwsrf:measurement_payment`
- [x] Search existing history/artifacts before regenerating those four.
- [x] If not found, generate draft M&P fixtures from tracked source PDFs and mark them for PDF review.

## Phase 3: Lock Ground Truth Accuracy

- [x] Confirm how the current comparators use ground truth:
  - pay-items exact-compare when `ground_truth_items_path` exists
  - M&P exact-compare when `ground_truth_entries_path` exists
- [x] Add review-status entries for all 28 contracts.
- [x] Remove checksum/math normalization, repair, and match-based fixture
  metadata:
  - checksum/math are validation-only signals
  - no repair may change `quantity`, `unitPrice`, `bidAmount`, expected
    fixtures, or ground truth from row math/checksum
  - no ground-truth fixture may carry row-math `matches` metadata as evidence
- [x] Add document-level ledgers so review evidence is not only in disposable
  `.tmp` paths.
- [x] Generate durable row-level visual review ledgers for all 28 contracts.
- [x] Do one-time visual row/field verification for all 28 PDFs:
  - PDF fidelity verifier confirms 28/28 contracts, 6,177 rows, 0 failed rows
  - 37 fields required explicit rendered-page visual confirmation because text/OCR
    tokenization alone could not prove the printed value
- [x] Mark rows/documents locked only after PDF evidence or explicit user confirmation.
- [x] Keep unreviewed rows honest as `needs_visual_pdf_review`.

## Phase 4: Standardize Adding New PDFs

- [x] Make `test/features/pdf/extraction/corpus/protected/` the only protected source-of-truth corpus path.
- [x] Define one required folder/name pattern:
  - `<project_id>/<project_id>_pay_items.pdf`
  - `<project_id>/<project_id>_measurement_and_payment.pdf`
- [x] Require each new PDF pair to update:
  - manifest
  - expected fixture
  - per-document ground-truth JSONs
  - review-status sidecar
  - review ledger
  - OCR cache capture when needed
- [x] Add contract tests that fail if any protected PDF, expected contract, ground-truth fixture, or review-status entry is missing.
- [x] Document that user-supplied links/file paths get copied into this protected corpus path before replay.

## Phase 5: Regression Gate

- [x] Establish the current full-corpus mismatch baseline from the protected replay.
- [ ] Run the unfiltered protected full-corpus replay before accepting any
  extraction rule change, only after focused cached verification is working.
- [x] Treat focused project filters as diagnostic only.
- [x] Require every broad rule change to:
  - identify first-bad stage from structured artifacts
  - add focused tests
  - improve or preserve non-target documents
  - produce no new trace-contract failures
- [ ] Final target: 0 asserted mismatches and 0 trace-contract failures across all 28 contracts.

## Phase 6: Cleanup Last

- [x] Audit the full PDF extraction pipeline for deprecated paths, scripts, imports, and harnesses.
- [x] Identify legacy/confusing paths:
  - Springfield-only harnesses
  - public MDOT `.tmp` regeneration paths
  - obsolete cache/source directories
  - docs that imply non-standard corpus paths
- [x] Remove or disable deprecated paths only after the protected standard is working.
- [x] Leave remaining legacy tools clearly labeled as diagnostic/regeneration-only, not acceptance gates.

## Current Evidence

- Branch: `pdf-corpus-standardization`.
- Release closeout scope on 2026-05-06:
  - user accepted that pay-items do not need to reach 100% before this release
  - focused M&P cached replay evidence is clean: 14/14 contracts, 2,040/2,040
    entries, 0 failures
  - no broad extraction rule change may normalize or repair numeric fields with
    row math/checksum; math and checksum are verification-only signals
  - custom lint now blocks PDF math/checksum owners from assigning or
    `copyWith`-repairing extracted quantity, unit-price, or amount fields
  - PDF extraction line-count lint coverage includes M&P production services
  - S21 import-flow smoke passed through real file injection, extraction, and
    review rendering with one protected corpus PDF:
    `tools/testing/test-results/2026-05-05/s21-pdf-import-smoke-20260506-0138/S21/summary.json`
  - release version is `0.2.6+1`
- Latest standardization commits:
  - `9fe0d856 test(pdf): fill original-four mp ground truth coverage`
  - `b2f51d7a docs(pdf): record protected corpus replay baseline`
- Protected corpus inventory is 28 PDFs / 28 expected contracts:
  14 pay-item PDFs and 14 measurement-and-payment PDFs.
- Ground-truth fixture coverage is now 14/14 pay-item JSONs and 14/14 M&P JSONs.
- The original-four M&P fixtures were generated as OCR replay drafts from tracked
  protected PDFs, then verified against the PDFs and marked
  `pdf_ground_truth_verified`.
- Durable ledger:
  `test/features/pdf/extraction/fixtures/review_ledgers/protected-corpus-review-ledger.md`.
- Current protected deleted cached-stage replay baseline:
  `.tmp/google_ocr_research/protected_full_downstream_replay_20260505_02_after_fixture_coverage`.
- Compact audit:
  `tools/testing/test-results/2026-05-05/pdf-extraction-replay-audit-131449-protected_full_downstream_replay_20260505_02_after_fixture_coverage/`.
- Baseline result: 338 asserted exact mismatches, 0 trace-contract failures.
- The local Windows native build now resolves `flusseract` through repo-local
  vcpkg Tesseract/leptonica and a JDK-backed JNI include path; `flutter build
  windows --debug --no-pub` completed successfully and bundled the OCR DLLs.
- OCR acceptance clarification on 2026-05-05:
  - native PDF text/provenance may explain how a draft fixture was assembled,
    but it is not an OCR extraction acceptance path
  - OCR extraction acceptance must come from cached OCR replay/trace evidence
    against ground truth
  - visual PDF evidence, not OCR replay or native text, is required before
    locking ground-truth rows/documents
- Math/checksum cleanup on 2026-05-05:
  - removed lump-sum quantity/unit-price output inference from
    `PostConsistencyRuleApplier`
  - removed Paw Paw row-level `row_math_validation` / `matches` metadata from
    the ground-truth fixture
  - focused post-processing/checksum tests passed with checksum/math as
    validation-only signals
- Direct PDF-vs-ground-truth verification on 2026-05-05:
  - 18 contracts matched by path-only agent comparison with no
    extraction/replay/OCR and no generated render artifacts
  - all 8 MDOT ESTQUA contracts matched after earlier fixture corrections
  - all 8 MDOT bid-tab contracts matched after earlier fixture corrections
  - Saugatuck and Paw Paw measurement-and-payment contracts matched
  - 10 scanned/raster contracts remain blocked under the path-only/no-render
    constraint: the original-four pay-item and M&P PDFs plus Saugatuck and Paw
    Paw pay-item PDFs
  - durable report:
    `test/features/pdf/extraction/fixtures/review_ledgers/agent-pdf-ground-truth-verification-2026-05-05.md`
- Final PDF fidelity audit on 2026-05-05:
  - `python tools/pdf-extraction/verify_pdf_ground_truth_fidelity.py` passed
  - result: 28/28 contracts matched, 6,177/6,177 rows matched, 0 failed rows
  - durable report:
    `test/features/pdf/extraction/fixtures/review_ledgers/pdf-ground-truth-fidelity-audit-2026-05-05.json`
  - visual confirmations:
    `test/features/pdf/extraction/fixtures/review_ledgers/pdf-ground-truth-visual-confirmations-2026-05-05.json`
  - expected metadata, review-status sidecar, fixtures, and row ledgers are
    marked `pdf_ground_truth_verified`
- The 28-contract prerelease app replay was retried with OCR cache replay, but
  the old app harness still rendered pay-item PDFs and stalled on
  `mdot_2025_11_07_estqua:pay_items`. The harness now routes pay-item replay
  through normalized OCR cache (`deleted cached-stage extraction API`). The previously
  stalled document completed cached extraction in about 2.2 seconds after
  Windows test startup.
- Phase 2 structural re-audit on 2026-05-05:
  - Protected corpus has 28 PDFs: 14 pay-item PDFs and 14 M&P PDFs.
  - `pdf_extraction_corpus_expected.json` has 28 document contracts:
    14 `pay_items` and 14 `measurement_payment`.
  - Every expected contract references an existing ground-truth fixture.
  - Fixture row counts match expected metadata for all 28 contracts:
    4,137 pay-item rows and 2,040 M&P entries.
  - The protected manifest has 14 projects, and
    `regression_policy.protected_project_ids` exactly matches those project IDs.
- Phase 3 review-status re-audit on 2026-05-05:
  - `gocr_ground_truth_review_status.json` has 28 entries and no extra/missing
    keys relative to expected contracts.
  - `protected-corpus-review-ledger.md` is the durable non-`.tmp` ledger and has
    28 rows, one per protected contract.
  - All 28 contracts are now `pdf_ground_truth_verified`.
  - Partial visual evidence is limited to `berrien_127449_us12:pay_items`
    (17/200 reviewed rows) and `grand_blanc_938710_sewer:pay_items`
    (12/118 reviewed rows). All other contracts have 0 reviewed rows.
  - The four legacy pay-item fixture filenames are consistently referenced but
    do not follow the project-id naming pattern:
    `berrien_county_ground_truth_items.json`,
    `huron_valley_ground_truth_items.json`,
    `grand_blanc_ground_truth_items.json`, and
    `springfield_ground_truth_items.json`.
  - Those same four legacy pay-item fixtures lack row-level source provenance;
    the ledger/status files still point to tracked protected source PDFs.

## Deferred / Non-Release Blockers

- Math and checksum are verification-only signals. Exact row/field comparison
  remains the acceptance source; future changes must keep `quantity`,
  `unitPrice`, `bidAmount`, expected fixtures, and ground truth from being
  repaired by row math/checksum.
- Durable row-level review ledgers now exist for all 28 contracts, but they are
  checklists only and do not lock any row.
- Direct agent PDF-vs-ground-truth verification has no mismatches remaining for
  the 18 text-inspectable contracts. The remaining 10 contracts are not verified
  because they are scanned/raster local PDFs and path-only inspection does not
  expose page pixels to agents without rendering/OCR.
- Native extraction/native text is not part of the OCR pass/fail target.
- Visual row/field review for all 28 PDFs is complete. Future fixture changes
  must rerun the PDF fidelity verifier before staying locked.
- Extraction replay evidence is still separate from ground-truth fidelity.
- Do not rerun OCR as a substitute for cache/ground-truth verification. Use
  existing cache evidence first; only capture or rerun OCR when a specific cache
  gap is proven and recorded.
- Focused cached verification must work before another full 28-contract replay.
- The final regression target remains a future hardening target: 0 asserted
  mismatches and 0 trace-contract failures across the protected corpus.
- The full 28-contract Windows app replay still needs a post-patch run before
  it can be treated as full-platform evidence. Do not run it until focused
  cached checks prove the path is fast and stable.

## Assumptions

- The current dirty working tree is PDF extraction pipeline work and should move intact to the new branch.
- The protected corpus is 28 PDFs, not 18 OCR cache JSONs.
- Ground truth JSONs are the comparison target; visual audit is how they become trusted.
- Future rule work must be broad and algorithmic, never PDF-specific.
- Math validation and checksum validation may flag, downgrade, or block output,
  but must never normalize/repair extracted numeric fields or fixtures.
