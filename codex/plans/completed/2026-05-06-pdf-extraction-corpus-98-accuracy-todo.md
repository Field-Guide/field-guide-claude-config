# PDF Extraction Corpus 98% Accuracy Todo Spec

Status: active
Created: 2026-05-06
Updated: 2026-05-07

## Summary

- Goal: make the full 28-contract PDF extraction corpus replay fast,
  unambiguous, and exact-comparison driven.
- Active target: reach at least `99%` exact row accuracy for each cached
  pay-item PDF, while preserving at least `98%` aggregate exact field accuracy
  and zero trace-contract failures. The original `98%` filename is retained as
  the historical workstream path, but the active gate is per-PDF `99%` unless
  explicitly lowered by the user.
- Comparator standard: byte-for-byte exact comparison against trusted ground
  truth. No normalization, tolerance, coercion, rounding, checksum-only
  acceptance, or fixture repair.
- Current baseline evidence:
  `tools/testing/test-results/2026-05-06/pdf-extraction-corpus-142648/`
  completed as a 28-document cached replay acceptance run, but failed at
  `0.6142` row accuracy and `0.6612` field accuracy.

## Todo

- [x] Re-scope acceptance after user clarification: each of the 14 cached
  pay-item PDFs must independently reach exact row accuracy `>= 0.98`; aggregate
  row accuracy alone is not sufficient.
- [x] Update the replay harness so per-document row accuracy below `0.98`
  fails the acceptance gate even when aggregate accuracy passes.
- [x] Triage remaining below-threshold PDFs from structured artifacts only.
  No cached pay-item PDF remains below `99%` exact row accuracy in the verified
  canonical replay
  `.tmp/google_ocr_research/canonical_14_pdf_replay_20260507_1135`.
- [x] Clarify the active acceptance lane as cached OCR replay only. Native
  Measurement and Payment/PDF-text extraction is out of scope for this lane and
  must not be run as part of the fast replay gate.
- [x] Rename the canonical local OCR replay cache to an obvious single path:
  `.tmp/pdf_extraction_corpus_ocr_cache`.
- [x] Populate that canonical cache path from the valid protected cache files.
- [x] Update all active commands, docs, tests, runner defaults, and usage
  strings to use only `.tmp/pdf_extraction_corpus_ocr_cache`.
- [x] Remove all old active references to `.tmp/gocr_ocr_cache*`.
- [x] Delete or clearly prune deprecated local cache directories after the
  canonical cache is verified.
- [x] Do not leave compatibility wrappers, alternate blessed paths, or
  "also works with" instructions.
- [x] Add cache coverage reporting to the corpus report:
  cache files used, pay-item documents requiring OCR replay, skipped
  non-pay-item cache files, missing cache files, duplicate legacy cache
  directories, and active cache path.
- [x] Add or update the accepted-baseline file under `tools/pdf-extraction/`
  only after the first verified canonical replay that satisfies the corrected
  per-PDF row accuracy gate, so future reports show truthful deltas instead of
  `Prior accepted baseline: missing`.
- [x] Run the full unfiltered cached pay-item OCR replay with:
  `PDF_CORPUS_OCR_CACHE_MODE=replay`,
  `PDF_CORPUS_OCR_CACHE_DIR=.tmp/pdf_extraction_corpus_ocr_cache`, no project
  filter, and no document-kind filter/native extraction path.
- [x] Confirm the report shows:
  `acceptance_run: true`, `document_count: 14`,
  `expected_document_count: 14`, no missing documents, no unexpected documents,
  exact per-document row accuracy `>= 0.99` for all 14 PDFs, exact field
  accuracy, and zero trace-contract failures.
- [x] Triage failures only from structured artifacts:
  `summary.json`, document metrics, mismatch files, stage traces, and compact
  audit reports.
- [x] Pick the largest general failure bucket first.
- [x] Classify the first bad stage before changing production code.
- [x] Add focused helper or stage tests for each rule change.
- [x] Implement only broad algorithmic fixes based on geometry, row/column
  structure, labels, units, numeric consistency, sequence evidence, and
  provenance.
- [x] Reject document-specific fixes based on PDF name, project key, agency,
  county, contractor, fixture path, literal expected text, or one-off item
  numbers.
- [x] After every rule change, run focused tests first, then the full cached
  pay-item OCR replay.
- [x] Accept an iteration only if it improves or preserves non-target
  documents, adds no trace-contract failures, and moves row/field accuracy
  toward the 98% target.
- [x] Stop this lane only when every cached pay-item PDF has exact row accuracy
  at least `0.99`, aggregate field accuracy is at least `0.98`, and
  trace-contract failures are zero.

## Confirmed Implementation Path

- [x] Use the downstream no-render OCR replay harness as the only acceptance
  gate for this lane:
  `test/features/pdf/extraction/integration/gocr_downstream_replay_test.dart`.
- [x] Keep native extraction and live OCR out of the acceptance gate.
- [x] Preserve the current full-page Google Vision replay as the safe baseline;
  page-local row-band and cell-grid captures are diagnostic only until proven.
- [x] Start implementation from the largest structured failure bucket:
  numeric interpretation on Berrien-like punctuation/digit grouping, only when
  the raw OCR text already contains the needed evidence.
- [x] Treat true OCR source errors as candidates for targeted hybrid crop OCR
  capture, not as math/checksum repair opportunities.
- [x] Add a capture-only targeted hybrid OCR scaffold behind
  `PDF_CORPUS_GOOGLE_OCR_PAGE_STRATEGY=targeted_crop`. It runs full-page OCR
  first, uses grid geometry plus numeric-shape/math-inconsistency signals only
  to select supplemental crop OCR cells, and preserves the full-page OCR
  elements as the final output so the scaffold cannot alter cached replay
  extraction results.
- [x] Update the targeted hybrid default crop mode from raw split numeric cells
  to merged numeric row-band crops. This keeps full-page OCR as the final
  extraction output and records row-band crop OCR only as supplemental evidence,
  so the canonical cached replay cannot regress while focused live captures
  gather better Berrien-style numeric evidence.
- [x] Add focused helper/stage tests before every production rule change.
- [x] After each rule change, run focused tests first, then the full unfiltered
  14-PDF cached OCR replay and replay audit.

## Non-Negotiables

- [x] Ground truth is not edited unless visual PDF evidence or explicit user
  confirmation proves the fixture is wrong.
- [x] Math and checksum may validate, flag, or block output, but must never
  repair extracted fields or fixtures.
- [x] Focused project/document runs are diagnostic only.
- [x] The full cached pay-item OCR replay is the acceptance gate for this lane;
  native PDF extraction is not part of this replay.
- [x] Deprecated paths must be fully removed once replacement paths are
  verified; no duplicate source of truth remains.

## Completion Evidence

- Current iteration map:
  - [x] Remove synthetic AASHTOWare bid-tab `Section` suffix restoration. The
    structured artifacts show these suffixes are parser-created footer/header
    artifacts, not OCR evidence from the description field.
  - [x] Tighten AASHTOWare bid-tab footer geometry so `Section Total(s)` footer
    bands stop before the `Section` token itself, rather than retaining
    `Section` and dropping only `Total(s)`.
  - [x] Guard leading item-number-fragment cleanup so it cannot delete a
    leading measurement expression such as `12 Inch x 12 inch...` when the
    item number merely shares the same digits.
  - [x] Replace the blanket currency-context override that turns fixed-decimal
    quantities like `2.500` or `110.000` into thousands. Keep fixed-decimal
    quantities as decimals, and only treat a single period as grouping when
    row numeric consistency independently supports that raw-text
    interpretation.
  - [x] Verify these as broad row/description rules with focused tests before
    running the full cached no-native replay.
- Last aggregate-only cached OCR replay:
  `.tmp/google_ocr_research/pay_item_ocr_replay_canonical_20260506_12_final_threshold_gate`.
- Previous aggregate metrics: exact row accuracy `0.9809`, exact field accuracy
  `0.9970`, exact rows `4058/4137`, exact fields `28873/28959`.
- This aggregate run is no longer sufficient because several individual PDFs
  remain below `0.98` exact row accuracy.
- The aggregate-only accepted baseline artifact was removed from
  `tools/pdf-extraction/` until a corrected per-PDF acceptance run exists.
- Cache status: active cache path `.tmp/pdf_extraction_corpus_ocr_cache`, 18
  cache files present, 14 pay-item cache files used, 4 non-pay-item cache files
  skipped by the OCR-only lane.
- Legacy local cache directories matching `.tmp/gocr_ocr_cache*` were pruned
  after canonical replay verification.
- Added normalized OCR replay capture support so a live render/OCR run can
  store final page-normalized OCR elements in `deleted cached-stage replay key`, and the
  deleted cached-stage replay can consume those elements instead of reconstructing from raw
  provider calls.
- Added replay reporting for `deleted cached-stage replay key_used`,
  `deleted cached-stage replay key_source`, `replay_ocr_source`, crop call count, image call
  count, and full-page-only replay status.
- Focused Berrien full-page Google Vision capture still used only full-page
  OCR: `strategy=full_page_google_assisted_ocr`, `grid_pages_processed=0`,
  `planned_cell_crops=0`, `mapped_crop_elements=0`, `crop_call_count=0`.
- Added corpus diagnostic switch
  `PDF_CORPUS_GOOGLE_OCR_PAGE_STRATEGY=page_local` so focused capture can use
  the real page-local crop OCR executor without changing the production
  Google-assisted default.
- Focused Berrien row-band page-local capture completed with 1,111 provider
  calls: 1,107 crop calls, 4 full-page image calls, 3,412 normalized replay
  elements, `grid_pages_processed=4`, `planned_cell_crops=980`, and
  `row_band_fallback_rows=88`.
- Berrien row-band deleted cached-stage replay from the captured normalized cache was fast
  but failed badly: exact row accuracy `0.585`, exact field accuracy `0.6921`.
  This is worse than the existing full-page cache path and is not acceptable.
- Focused Berrien cell-grid capture was stopped as non-viable after exceeding
  2,155 live provider calls without writing final normalized replay pages.
  Current cell-grid crop OCR is too expensive for the corpus loop as-is.
- Targeted hybrid scaffold focused verification passed:
  `flutter test test/features/pdf/extraction/stages/ocr_targeted_hybrid_recognition_strategy_test.dart -d windows`.
  Adjacent OCR/numeric verification also passed:
  `ocr_full_page_recognition_strategy_test.dart`,
  `ocr_page_recognition_executor_test.dart`, `ocr_text_recognizer_test.dart`,
  and `numeric_interpreter_test.dart`.
- Full cached pay-item replay after the scaffold:
  `.tmp/google_ocr_research/pay_item_ocr_replay_20260506_2021_targeted_hybrid_scaffold`.
  It completed as the intended no-render cached OCR lane with
  `acceptance_run=true`, `document_count=14`, `expected_document_count=14`,
  active cache path `.tmp/pdf_extraction_corpus_ocr_cache`, no missing cache
  files, no duplicate legacy cache directories, no native/no-OCR documents,
  exact row accuracy `4064/4137 = 0.9824`, exact field accuracy
  `28879/28959 = 0.9972`, and still fails only the corrected per-PDF `0.99`
  gate.
- Latest replay audit:
  `tools/testing/test-results/2026-05-06/pdf-extraction-replay-audit-202614-pay_item_ocr_replay_20260506_2021_targeted_hybrid_scaffold/audit-summary.md`.
  Trace-contract failures remained `0`. The largest remaining structured
  bucket is still Berrien numeric interpretation / OCR-source evidence, so the
  next iteration should use targeted crop capture evidence rather than
  math validation-only triage.
- Focused live diagnostic capture with
  `PDF_CORPUS_GOOGLE_OCR_PAGE_STRATEGY=targeted_crop`:
  `.tmp/google_ocr_research/berrien_targeted_hybrid_capture_20260506_203019`
  and cache
  `.tmp/pdf_extraction_corpus_ocr_cache_berrien_targeted_hybrid_20260506_203019`.
  This was not an acceptance run. It stayed pay-items only and generated
  `8` full-page image calls plus `151` supplemental crop calls across `4`
  targeted pages. The extraction result was worse than the protected cached
  baseline (`195` items, many blank bid amounts), so it must not replace the
  canonical cache.
- The focused capture proved the selector fires, but it also exposed the next
  architectural issue: raw detected vertical grid lines over-segment Berrien's
  numeric lanes, so rightmost-cell crops capture fragments such as `30,5`,
  blank, and `.0` instead of a semantic bid-amount cell. The next crop OCR
  slice should target merged numeric row bands or post-cell-extraction semantic
  cell bounds, not raw split grid cells, while still preserving full-page OCR
  as the baseline and using crop OCR only as supplemental evidence.
- Added merged numeric row-band crop diagnostics to the targeted hybrid
  strategy and focused coverage for the geometry contract:
  `flutter test test/features/pdf/extraction/stages/ocr_targeted_hybrid_recognition_strategy_test.dart -d windows`.
  The new test confirms a suspicious row produces one merged crop beginning at
  the description/numeric boundary, preserves final full-page OCR output, and
  records supplemental `targetedNumericRowBand` diagnostics.
- Focused verification after merged row-band patch passed:
  `dart analyze lib/features/pdf/services/extraction/stages/ocr_targeted_hybrid_recognition_strategy.dart integration_test/pdf_extraction_corpus_test.dart test/features/pdf/extraction/stages/ocr_targeted_hybrid_recognition_strategy_test.dart`,
  plus adjacent OCR/numeric tests:
  `ocr_full_page_recognition_strategy_test.dart`,
  `ocr_page_recognition_executor_test.dart`, `ocr_text_recognizer_test.dart`,
  and `numeric_interpreter_test.dart`.
- Full cached pay-item replay after the merged row-band scaffold:
  `.tmp/google_ocr_research/pay_item_ocr_replay_20260506_2050_targeted_row_band_scaffold`.
  It completed in the intended no-render cached OCR lane with
  `acceptance_run=true`, `document_count=14`, `expected_document_count=14`,
  active cache path `.tmp/pdf_extraction_corpus_ocr_cache`, `14` cache files
  used, no missing cache files, no duplicate legacy cache directories, no
  native/no-OCR documents, aggregate exact row accuracy `4064/4137 = 0.9824`,
  and aggregate exact field accuracy `28879/28959 = 0.9972`.
- Latest replay audit after the merged row-band scaffold:
  `tools/testing/test-results/2026-05-06/pdf-extraction-replay-audit-205003-pay_item_ocr_replay_20260506_2050_targeted_row_band_scaffold/audit-summary.md`.
  Trace-contract failures remained `0`. The replay still fails only the
  corrected per-PDF `0.99` gate, with the same below-threshold PDFs:
  Berrien `167/200 = 0.835`, Paw Paw `50/58 = 0.8621`, Saugatuck
  `147/162 = 0.9074`, MDOT 04003 `22/23 = 0.9565`, MDOT 03001
  `76/78 = 0.9744`, and MDOT 03002 `110/112 = 0.9821`.
- Added a stricter targeted row-band numeric consistency gate that parses the
  raw crop OCR number tokens directly and accepts only independently
  math-consistent quantity, unit-price, and bid-amount evidence. It accepts
  raw crop patterns like `EA 2 $ 680.0 | $ 1,360.0` and rejects near-miss math
  such as `FT 1,375 $ 4.50 $ 6,185`; it does not compute or repair any output
  field.
- Focused tests for the retained row-band token gate passed:
  `flutter test test/features/pdf/extraction/stages/ocr_targeted_hybrid_recognition_strategy_test.dart -d windows`.
  Analyzer and adjacent OCR/numeric tests also passed after the retained
  change.
- Full cached no-render pay-item replay for the retained row-band token gate:
  `.tmp/google_ocr_research/pay_item_ocr_replay_20260506_2134_row_band_token_gate_final`.
  It remained on the canonical cache path `.tmp/pdf_extraction_corpus_ocr_cache`,
  excluded native extraction, used `14` pay-item cache files, used `0` crop
  cache calls, and kept aggregate exact row accuracy `4064/4137 = 0.9824` and
  exact field accuracy `28879/28959 = 0.9972`.
- Latest retained replay audit:
  `tools/testing/test-results/2026-05-06/pdf-extraction-replay-audit-213810-pay_item_ocr_replay_20260506_2134_row_band_token_gate_final/audit-summary.md`.
  Trace-contract failures remained `0`; the most upstream observed first-bad
  stage remains `text_recognition` via `ocr_source_error`.
- Focused Berrien targeted-crop diagnostics remain diagnostic only. The raw
  row-band token gate increased accepted crop evidence, but direct raw crop
  word-box replacement still loses many bid amounts downstream. A synthetic
  numeric-token geometry experiment was tried and rejected because focused
  Berrien regressed from `196` items / score `0.786` to `195` items / score
  `0.779`. Do not revive that exact approach without a stronger geometry
  contract and focused downstream cell-extraction tests.
- The accepted-baseline artifact under `tools/pdf-extraction/` is now set to
  `tools/pdf-extraction/pdf_extraction_corpus_accepted_baseline.json` from the
  verified canonical cached pay-item replay
  `.tmp/google_ocr_research/canonical_14_pdf_replay_20260507_1135`.
  The run used `.tmp/pdf_extraction_corpus_ocr_cache`, reported
  `acceptance_run=true`, `document_count=14`, `expected_document_count=14`, no
  missing cache files, aggregate exact row accuracy `4125/4137 = 0.9971`,
  aggregate exact field accuracy `28946/28959 = 0.9996`, minimum per-PDF exact
  row accuracy `0.9929`, and zero trace-contract failures.
- The local canonical OCR replay cache is locked by
  `tools/pdf-extraction/pdf_extraction_corpus_ocr_cache_lock.json`. The lock
  records all `18` canonical cache files, the `14` files used by the accepted
  pay-item replay, byte counts, SHA-256 values, and a manifest checksum. Verify
  the local `.tmp/pdf_extraction_corpus_ocr_cache` baseline before adding new
  corpus PDFs with
  `tools/pdf-extraction/verify_pdf_extraction_corpus_cache_lock.ps1`.
- Retained parser/description/numeric iteration:
  - Focused tests passed:
    `row_parser_bid_tab_by_item_parser_test.dart`,
    `row_parser_cell_field_parser_test.dart`, and
    `artifact_cleaning_description_repair_test.dart`.
  - Broader row parser tests passed:
    `flutter test test/features/pdf/extraction/stages/row_parser -d windows`.
  - Adjacent numeric/stage tests passed:
    `numeric_interpreter_test.dart`, `row_parser_stage_test.dart`, and
    `row_parser_stage_isolated_test.dart`.
  - Post-processing artifact/repair tests passed for description, unit, and
    construction OCR rule coverage.
  - Full cached no-render pay-item replay:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260506_2151_parser_section_quantity`.
    It used replay mode on `.tmp/pdf_extraction_corpus_ocr_cache`, excluded
    native extraction, used no crop calls, had `acceptance_run=true`,
    `document_count=14`, `expected_document_count=14`, no missing cache files,
    no duplicate legacy cache directories, and no native/no-OCR documents.
  - Replay metrics improved to exact row accuracy `4068/4137 = 0.9833` and
    exact field accuracy `28883/28959 = 0.9974`. The MDOT bid-tab PDFs are now
    exact-row clean: `03001` `78/78`, `03002` `112/112`, and `04003` `23/23`.
  - Latest audit:
    `tools/testing/test-results/2026-05-06/pdf-extraction-replay-audit-215530-pay_item_ocr_replay_20260506_2151_parser_section_quantity/audit-summary.md`.
    Trace-contract failures remained `0`. The run still fails the per-PDF
    `0.99` gate for Berrien `167/200`, Paw Paw `50/58`, Saugatuck `147/162`,
    and Springfield `129/131`.
- Retained Springfield/post-normalization iteration from the retained audit:
  - [x] Extend the single-period quantity consistency gate to handle
    period-grouped currency amounts such as `$ 113.220.00` without treating
    arbitrary merged currency text as one number.
  - [x] Add stable punctuation normalization for descriptions with a missing
    space after a standalone hyphen, e.g. `Valve -Helmer` to
    `Valve - Helmer`.
  - [x] Run focused parser/post-processing tests, row parser stage tests, and
    then the full cached no-native replay.
  - Full cached no-render pay-item replay:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260506_2200_springfield_quantity_hyphen`.
    It stayed on replay mode with `.tmp/pdf_extraction_corpus_ocr_cache`,
    excluded native extraction, used `14` pay-item cache files, used `0` crop
    calls, and reported `acceptance_run=true`, `document_count=14`,
    `expected_document_count=14`, no missing cache files, no duplicate legacy
    cache directories, and no native/no-OCR documents.
  - Replay metrics improved to exact row accuracy `4070/4137 = 0.9838` and
    exact field accuracy `28885/28959 = 0.9974`. Springfield is now exact-row
    clean at `131/131`, and the MDOT bid-tab PDFs remain exact-row clean.
  - Latest audit:
    `tools/testing/test-results/2026-05-06/pdf-extraction-replay-audit-220454-pay_item_ocr_replay_20260506_2200_springfield_quantity_hyphen/audit-summary.md`.
    Trace-contract failures remained `0`. The run still fails the per-PDF
    `0.99` gate only for Berrien `167/200`, Paw Paw `50/58`, and Saugatuck
    `147/162`.
- Retained abbreviation punctuation iteration:
  - [x] Add focused post-processing coverage that preserves `Adj. Case` as a
    stable construction abbreviation rather than converting the spaced period
    to a comma.
  - [x] Preserve `Adj . Case` as `Adj. Case` before the broader OCR punctuation
    spacing rule converts other spaced periods to comma separators.
  - [x] Run focused and adjacent post-processing tests, analyzer, then the full
    cached no-native replay.
  - Full cached no-render pay-item replay:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260506_2211_adj_abbrev_punctuation`.
    It stayed on the canonical cache path `.tmp/pdf_extraction_corpus_ocr_cache`,
    excluded native extraction, used `14` pay-item cache files, used `0` crop
    calls, and reported no missing cache files, no duplicate legacy cache
    directories, and no native/no-OCR documents.
  - Replay metrics improved to exact row accuracy `4071/4137 = 0.9840` and
    exact field accuracy `28886/28959 = 0.9975`. Paw Paw improved from
    `50/58` to `51/58`; non-target exact-row-clean documents remained clean.
  - Latest audit:
    `tools/testing/test-results/2026-05-06/pdf-extraction-replay-audit-221557-pay_item_ocr_replay_20260506_2211_adj_abbrev_punctuation/audit-summary.md`.
    Trace-contract failures remained `0`. The run still fails the per-PDF
    `0.99` gate only for Berrien `167/200`, Paw Paw `51/58`, and Saugatuck
    `147/162`.
  - Structured triage after this run: Berrien remains dominated by numeric
    OCR-source/digit evidence (`37` numeric interpretation mismatches plus
    one confidence mismatch), Paw Paw has `6` source-unit casing mismatches and
    `2` row-parsing description mismatches, and Saugatuck has `14`
    description row-parsing casing/word mismatches plus one post-normalization
    mismatch. Berrien and Paw Paw unit casing should not be repaired by
    checksum/math or document-specific unit casing rules.
- Rejected document-local square-yard unit casing iteration:
  - Tried a conservative post-normalization pass that would harmonize `Syd` to
    `SYd` from document-local square-yard OCR casing evidence, then ran the
    full cached no-render pay-item replay:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260506_2224_doc_unit_casing`.
  - The run used replay mode on `.tmp/pdf_extraction_corpus_ocr_cache`,
    excluded native extraction, used `14` pay-item cache files, used `0` crop
    calls, and had `0` trace-contract failures. Replay metrics did not move:
    exact row accuracy remained `4071/4137 = 0.9840` and exact field accuracy
    remained `28886/28959 = 0.9975`; Paw Paw stayed `51/58`.
  - Audit:
    `tools/testing/test-results/2026-05-06/pdf-extraction-replay-audit-222832-pay_item_ocr_replay_20260506_2224_doc_unit_casing/audit-summary.md`.
    The Paw Paw cache/trace shows mixed square-yard display styles in the same
    document: some rows legitimately match expected `Syd` while rows `6`, `8`,
    `9`, `12`, `13`, and `36` expect `SYd`. A document-wide casing rule is
    therefore the wrong generalization.
  - Decision: removed the attempted production rule and synthetic harmonization
    tests. Do not retry document-wide `Syd`/`SYd` harmonization. Future Paw Paw
    unit work needs geometry/provenance evidence at the row or local table-band
    level, not a document-level display-casing majority.
- Retained utility/sidewalk inch-casing iteration:
  - [x] Add focused post-processing coverage for stable utility/sidewalk
    `Inch` to `inch` casing after punctuation cleanup.
  - [x] Preserve mixed contexts without row-local evidence, including `Sewer
    Tap, 21 Inch`, dimension-chain `Tee` descriptions, and pavement-marking
    descriptions.
  - [x] Run focused and adjacent post-processing tests, analyzer, then the full
    cached no-native replay.
  - Full cached no-render pay-item replay:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260506_2236_utility_inch_casing`.
    It stayed on the canonical cache path `.tmp/pdf_extraction_corpus_ocr_cache`,
    excluded native extraction, used `14` pay-item cache files, used `0` crop
    calls, and reported no missing cache files, no duplicate legacy cache
    directories, and no native/no-OCR documents.
  - Replay metrics improved to exact row accuracy `4078/4137 = 0.9857` and
    exact field accuracy `28893/28959 = 0.9977`. Saugatuck improved from
    `147/162 = 0.9074` to `154/162 = 0.9506`; non-target exact-row-clean
    documents remained clean.
  - Latest audit:
    `tools/testing/test-results/2026-05-06/pdf-extraction-replay-audit-224021-pay_item_ocr_replay_20260506_2236_utility_inch_casing/audit-summary.md`.
    Trace-contract failures remained `0`. The run still fails the per-PDF
    `0.99` gate for Berrien `167/200`, Paw Paw `51/58`, and Saugatuck
    `154/162`.
  - Remaining Saugatuck mismatches are the intentionally deferred mixed casing
    or lexical cases: `Guardralt` vs `Guardrall`, `Sewer Tap 12 Inch`, `Dr
    Structure Tap 3 Inch`, `Pavt Mrkg ... 4 inch, Yellow`, `45 Deg Bend 6
    Inch`, `12 Inch x 12 ... Tee` dimension-chain casing, and `Insertatee 6
    inch`. Do not add literal item-number or expected-text patches for these.
- Retained targeted crop OCR scaffold iteration:
  - [x] Add focused coverage that suspicious rows can plan alternate merged
    numeric row-band crops: a wider description/numeric boundary candidate and
    a narrower numeric-column fallback candidate.
  - [x] Keep the merge gate strict: a candidate can replace full-page OCR
    evidence only when the raw crop OCR text independently contains quantity,
    unit-price, and bid-amount tokens whose arithmetic is consistent. The rule
    records candidate kind/priority and does not compute, repair, or infer any
    output field from arithmetic.
  - [x] Deduplicate accepted crop evidence to one candidate per row, preferring
    the narrower numeric fallback when multiple candidates pass.
  - [x] Add report telemetry for targeted row-band candidate count and accepted
    candidate count so focused live captures expose the crop experiment
    directly.
  - Focused tests passed:
    `flutter test test/features/pdf/extraction/stages/ocr_targeted_hybrid_recognition_strategy_test.dart -d windows`
    and
    `flutter test test/features/pdf/extraction/stages/ocr_text_recognizer_test.dart -d windows`.
  - Analyzer passed:
    `dart analyze lib/features/pdf/services/extraction/stages/ocr_targeted_hybrid_recognition_strategy.dart lib/features/pdf/services/extraction/stages/ocr_text_recognition_models.dart lib/features/pdf/services/extraction/stages/ocr_substage_metrics.dart test/features/pdf/extraction/stages/ocr_targeted_hybrid_recognition_strategy_test.dart test/features/pdf/extraction/stages/ocr_text_recognizer_test.dart test/features/pdf/extraction/stages/ocr_text_recognizer/stage_report_metrics_tests.dart`.
  - Adjacent OCR/numeric tests passed:
    `flutter test test/features/pdf/extraction/stages/ocr_targeted_hybrid_recognition_strategy_test.dart test/features/pdf/extraction/stages/ocr_full_page_recognition_strategy_test.dart test/features/pdf/extraction/stages/ocr_page_recognition_executor_test.dart test/features/pdf/extraction/stages/ocr_text_recognizer_test.dart test/features/pdf/extraction/stages/numeric_interpreter_test.dart -d windows`.
  - Full cached no-render pay-item replay:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260506_2253_targeted_row_band_candidates`.
    It stayed on replay mode with `.tmp/pdf_extraction_corpus_ocr_cache`,
    excluded native extraction, used `14` pay-item cache files, used `0` crop
    calls, had `acceptance_run=true`, `document_count=14`,
    `expected_document_count=14`, no missing cache files, no duplicate legacy
    cache directories, and no native/no-OCR documents.
  - Replay metrics were unchanged from the prior retained iteration:
    exact row accuracy `4078/4137 = 0.9857` and exact field accuracy
    `28893/28959 = 0.9977`. The change is retained because it is inactive in
    canonical cached replay and improves the opt-in focused crop-capture
    evidence path without regressing any cached document.
  - Latest audit:
    `tools/testing/test-results/2026-05-06/pdf-extraction-replay-audit-225643-pay_item_ocr_replay_20260506_2253_targeted_row_band_candidates/audit-summary.md`.
    Trace-contract failures remained `0`. The run still fails the per-PDF
    `0.99` gate for Berrien `167/200`, Paw Paw `51/58`, and Saugatuck
    `154/162`.
  - Next diagnostic step: run a focused Berrien `targeted_crop` live capture
    into a temporary cache and compare the normalized replay against the
    canonical cache. Do not replace `.tmp/pdf_extraction_corpus_ocr_cache`
    unless the full cached replay improves and non-target documents preserve
    exact-row status.
- Retained targeted crop numeric-only provenance guards:
  - [x] Ran the focused Berrien `targeted_crop` live capture into temporary
    caches only; the canonical cache was not replaced.
  - [x] Classified the first failed focused attempt from structured artifacts:
    accepted alternate row-band crops spatially swept in rejected crop elements,
    duplicating bid amounts such as `8500.0` to `850008500.0`.
  - [x] Added focused coverage proving accepted row-band evidence must merge
    only the mapped elements from the accepted crop candidate, not overlapping
    rejected alternate crops.
  - [x] Added focused coverage proving targeted row-band OCR may replace only
    numeric lanes; item number, description, and unit evidence stay from the
    full-page OCR unless a later general rule has its own provenance evidence.
  - [x] Implemented the merge with per-candidate mapped-element provenance and
    numeric-lane replacement bounds. This is a general geometry/provenance
    guard, not a document-key or expected-value rule.
  - Focused and adjacent tests passed:
    `flutter test test/features/pdf/extraction/stages/ocr_targeted_hybrid_recognition_strategy_test.dart -d windows`,
    `dart analyze lib/features/pdf/services/extraction/stages/ocr_targeted_hybrid_recognition_strategy.dart test/features/pdf/extraction/stages/ocr_targeted_hybrid_recognition_strategy_test.dart`,
    and
    `flutter test test/features/pdf/extraction/stages/ocr_full_page_recognition_strategy_test.dart test/features/pdf/extraction/stages/ocr_page_recognition_executor_test.dart test/features/pdf/extraction/stages/ocr_text_recognizer_test.dart test/features/pdf/extraction/stages/numeric_interpreter_test.dart -d windows`.
  - Rejected focused attempt before the provenance guard:
    `.tmp/google_ocr_research/berrien_targeted_crop_candidates_replay_20260507_060529`
    regressed Berrien to exact row accuracy `142/200 = 0.7100` and field
    accuracy `1333/1400 = 0.9521`.
  - Focused replay after candidate provenance improved Berrien to
    `174/200 = 0.8700` exact row accuracy and `1367/1400 = 0.9764` exact field
    accuracy, but introduced unit OCR-source regressions on rows where a wide
    crop replaced the unit lane:
    `.tmp/google_ocr_research/berrien_targeted_crop_provenance_replay_20260507_061500`.
  - Focused replay after numeric-lane-only replacement preserved the Berrien
    focused improvement at `174/200 = 0.8700` exact row accuracy and
    `1367/1400 = 0.9764` exact field accuracy, removed OCR-source regressions,
    and left the remaining first-bad stage at `numeric_interpretation`:
    `.tmp/google_ocr_research/berrien_targeted_crop_numeric_only_replay_20260507_062144`.
    Compared with the canonical Berrien cache, it fixes `9` previously bad
    items and creates `2` new numeric misses; it is useful evidence but still
    not a replacement cache.
  - Full canonical cached replay after these guards:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260507_062525_targeted_crop_numeric_only_guard`.
    It stayed on `.tmp/pdf_extraction_corpus_ocr_cache`, used `14` pay-item
    cache files, used `0` crop calls, had no missing cache files, no duplicate
    legacy cache directories, no native/no-OCR documents, and `0`
    trace-contract failures. Metrics were unchanged: exact row accuracy
    `4078/4137 = 0.9857`, exact field accuracy `28893/28959 = 0.9977`;
    Berrien remains `167/200`, Paw Paw `51/58`, and Saugatuck `154/162`.
  - Next iteration target: use the structured focused Berrien numeric-only
    replay to decide whether crop OCR can resolve the remaining leading-digit
    numeric misses without creating new misses. Do not replace the canonical
    cache until a focused cache exceeds canonical Berrien and the full
    canonical replay preserves every non-target document.
- Corrected three-PDF iteration scope after user clarification:
  - [x] Do not continue as a Berrien-only lane. Every future rule change must
    be justified against the remaining failing PDFs together:
    `berrien_127449_us12-pay-items`, `pawpaw_866291_lounsbury-pay-items`, and
    `saugatuck_859772-pay-items`.
  - [x] Latest canonical structured map from
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260507_062525_targeted_crop_numeric_only_guard`
    and
    `tools/testing/test-results/2026-05-07/pdf-extraction-replay-audit-062957-pay_item_ocr_replay_20260507_062525_targeted_crop_numeric_only_guard/audit-summary.md`:
    Berrien remains `167/200` with `37` numeric interpretation mismatches plus
    one fields-present miss; Paw Paw remains `51/58` with `6` unit OCR-source
    mismatches and `2` row-parsing description truncation mismatches;
    Saugatuck remains `154/162` with `7` row-parsing description mismatches
    and `1` post-normalization description mismatch.
  - [x] Treat the shared next rule as row-local field evidence selection, not
    as Berrien numeric repair. The general candidate is to extend targeted
    focused OCR from numeric-only row bands into field-lane candidates:
    numeric lanes for Berrien-style amount/price/quantity evidence, unit lane
    for Paw Paw-style row-local unit glyph/casing evidence, and description
    lane for Paw Paw/Saugatuck truncation or casing evidence.
  - [x] Focused tests for the next production change must span at least two
    failing documents or field families. A Berrien-only test is insufficient
    unless paired with Paw Paw/Saugatuck unit or description evidence coverage.
  - [x] Acceptance remains the full 14-PDF canonical deleted cached-stage replay. Focused
    captures across any one PDF are diagnostic only and must not replace the
    canonical cache unless the resulting cache improves all relevant failing
    PDFs and preserves non-target documents.
- Retained row-local cell field evidence seam:
  - [x] Added `cell_field_evidence_selection` as an explicit traceable stage
    after cell materialization and before numeric interpretation. The stage is
    wired through `CellExtractorV2`, the stage registry, the stage barrel, and
    the GOCR trace-artifact contract.
  - [x] Added focused tests proving the intended row-local shape can prepend a
    description-continuation prefix only when a short item-lane bridge token
    such as `and` is present, while preserving numeric lanes.
  - [x] Added a regression test for the production failure found during replay:
    already-materialized description continuations such as
    `Concrete, Pavement, Non- Reinforced` must not be duplicated.
  - Rejected the first broad selector attempt. Full replay
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260507_0715_cell_field_evidence_selection`
    regressed aggregate exact row accuracy to `0.8927` and field accuracy to
    `0.9707` by duplicating continuation text across multiple documents,
    including bid-tab and Paw Paw rows. The rule was narrowed before retention.
  - Focused verification after narrowing passed:
    `flutter test test/features/pdf/extraction/stages/cell_field_evidence_selection_stage_test.dart -d windows`,
    `flutter test test/features/pdf/extraction/stages/cell_extraction_stage_test.dart -d windows`,
    `flutter test test/features/pdf/extraction/contracts/cell_extraction_to_row_parsing_contract_test.dart -d windows`,
    `flutter test test/features/pdf/extraction/stages/numeric_interpreter_test.dart -d windows`,
    `flutter test test/features/pdf/extraction/stages/row_parser/row_parser_cell_field_parser_test.dart -d windows`,
    `flutter test test/features/pdf/extraction/stages/row_parser/row_parser_bid_tab_by_item_parser_test.dart -d windows`,
    and analyzer on the new selector/cell extractor files.
  - Full canonical deleted cached-stage replay after narrowing:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260507_0724_cell_field_evidence_selection_narrowed`.
    It stayed on `.tmp/pdf_extraction_corpus_ocr_cache`, excluded native
    extraction, used the 14 pay-item cache files, wrote full traces, and failed
    only the corrected per-PDF `0.99` gate. Aggregate exact row accuracy was
    `4078/4137 = 0.9857`; aggregate field accuracy was
    `28893/28959 = 0.9977`.
  - Latest audit for the retained narrowed run:
    `tools/testing/test-results/2026-05-07/pdf-extraction-replay-audit-072851-pay_item_ocr_replay_20260507_0724_cell_field_evidence_selection_narrowed/audit-summary.md`.
    Trace-contract failures remained `0`. The remaining below-threshold PDFs
    are unchanged: Berrien `167/200 = 0.8350`, Paw Paw `51/58 = 0.8793`, and
    Saugatuck `154/162 = 0.9506`.
- Rejected fitting-dimension casing attempt:
  - Tried a general post-normalization rule that propagated repeated `Inch`
    casing through pipe-fitting dimension chains. Focused tests passed, but the
    full replay
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260507_0731_fitting_dimension_casing`
    fixed Saugatuck rows `124` and `125` while creating new Saugatuck
    regressions on rows `122` and `123`.
  - Decision: removed the rule and restored the prior focused expectations.
    Do not retry a first-token casing propagation rule without row-local or
    group-level evidence that distinguishes the mixed fitting rows.
- Retained leading text-prefix row-merger iteration:
  - [x] Classified Paw Paw description truncation from structured traces before
    editing production code. The missing text was in same-page leading
    boilerplate rows immediately before structured price payload rows, not in
    native extraction and not in the expected fixture.
  - [x] Added focused row-merger helper/stage tests proving a text-only
    description prefix may attach only when local sequence evidence and a
    following structured payload complete the anchor row. Numeric boilerplate
    such as `Alt No. 2` remains rejected.
  - [x] Implemented the rule as a general row/geometry/sequence rule in the
    row-merger leading-continuation path, without document keys, expected
    literals, or item-number patches.
  - Focused verification passed:
    `flutter test test/features/pdf/extraction/stages/row_merger/leading_text_continuation_rule_evaluator_test.dart test/features/pdf/extraction/stages/row_merger/row_merger_leading_description_attachment_test.dart -d windows`,
    `flutter test test/features/pdf/extraction/stages/row_merger -d windows`,
    and adjacent cell/row-parser contract tests.
  - Full canonical deleted cached-stage replay:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260507_0757_leading_boilerplate_prefix`.
    It stayed on `.tmp/pdf_extraction_corpus_ocr_cache`, excluded native
    extraction, used the full 14 pay-item cache set, and had `0`
    trace-contract failures. Aggregate exact row accuracy stayed
    `4078/4137 = 0.9857`, exact field accuracy improved to
    `28894/28959 = 0.9978`, and the run still failed only the per-PDF `0.99`
    gate for Berrien `167/200`, Paw Paw `51/58`, and Saugatuck `154/162`.
  - Audit:
    `tools/testing/test-results/2026-05-07/pdf-extraction-replay-audit-080114-pay_item_ocr_replay_20260507_0757_leading_boilerplate_prefix/audit-summary.md`.
- Retained row-local bridge placement after materialized prefixes:
  - [x] Classified the next Paw Paw row from structured artifacts: the leading
    text prefix was present, but a short item-lane bridge token such as `and`
    was left before the materialized prefix instead of after it.
  - [x] Added focused `cell_field_evidence_selection` coverage proving a
    bridge token can move after an already-materialized source-row prefix while
    numeric lanes and non-bridge item text remain unchanged.
  - [x] Implemented the selector rule as row-local field evidence placement
    with traceable rule/reason names, not as a Paw Paw-specific description
    patch.
  - Focused and adjacent verification passed:
    `flutter test test/features/pdf/extraction/stages/cell_field_evidence_selection_stage_test.dart -d windows`,
    `flutter test test/features/pdf/extraction/stages/cell_extraction_stage_test.dart test/features/pdf/extraction/contracts/cell_extraction_to_row_parsing_contract_test.dart test/features/pdf/extraction/stages/row_parser/row_parser_cell_field_parser_test.dart test/features/pdf/extraction/stages/row_merger -d windows`,
    and analyzer on the touched selector/row-merger files.
  - Full canonical deleted cached-stage replay:
    `.tmp/google_ocr_research/pay_item_ocr_replay_20260507_0804_leading_prefix_bridge`.
    It stayed on `.tmp/pdf_extraction_corpus_ocr_cache`, excluded native
    extraction, used the full 14 pay-item cache set, and had `0`
    trace-contract failures. Aggregate exact row accuracy improved to
    `4079/4137 = 0.9860`; exact field accuracy improved to
    `28895/28959 = 0.9978`. Paw Paw improved to `52/58 = 0.8966`; Berrien
    remains `167/200 = 0.8350`; Saugatuck remains `154/162 = 0.9506`.
  - Audit:
    `tools/testing/test-results/2026-05-07/pdf-extraction-replay-audit-080819-pay_item_ocr_replay_20260507_0804_leading_prefix_bridge/audit-summary.md`.
  - Current blocker state: the latest replay still fails only the corrected
    per-PDF `0.99` gate. Remaining work must target Berrien numeric evidence,
    Paw Paw row-local unit casing evidence, and Saugatuck mixed description
    casing/lexical evidence as a combined multi-PDF lane.

## Assumptions

- The 98% goal applies to both exact row accuracy and exact field accuracy.
- Byte-for-byte accuracy refers to comparator strictness, not a requirement that
  extraction reach 100% before this workstream can make progress.
- The canonical cache path should be clearer than `.tmp/gocr_ocr_cache`; use
  `.tmp/pdf_extraction_corpus_ocr_cache`.
