# Delete Normalized Replay and Restore Live-Equivalent PDF Hardening

## 2026-05-08 Status Addendum

- Math/checksum is validation-only. Math repair/backsolve/retry/scoring gates
  are forbidden and now covered by
  `test/features/pdf/extraction/contracts/pdf_math_validation_only_guardrail_test.dart`.
- `RepairType.mathValidation` is deleted so validation cannot be represented as
  a repair-log entry.
- Accuracy iteration must stay on broad source-backed rules only: direct OCR
  text, geometry, rows/columns, units, provenance, and preprocessing evidence.

## 2026-05-09 Closeout Addendum

- Full unfiltered pay-item replay now runs only through live-equivalent cached
  Google Vision OCR-call replay:
  `tools/testing/test-results/2026-05-09/pdf-extraction-corpus-233413/summary.json`.
- Current measured result is 14/14 pay-item PDFs, no missing documents, no
  unexpected documents, `row_accuracy=0.9584`, and
  `field_accuracy=0.9892`.
- Replay audit for
  `.tmp/google_ocr_research/vision_20260509_232313_full_pay_items_replay_final`
  reports `asserted_mismatch_count=0` and `trace_contract_failure_count=0`.
- The original `>= 0.99` exact row accuracy per individual PDF target was not
  reached. Do not cite this as a 99% per-PDF pass.
- Paw Paw S21 live app verification is complete for the current extraction
  code:
  `tools/testing/test-results/2026-05-09/s21-pawpaw-live-verification-20260509-232037/S21/23-comparison.json`.
  The S21 app imported 58 persisted rows, matched 58/58 exact rows and 348/348
  exact fields against ground truth with app storage unit equivalence, kept
  item 24 quantity at 25, and produced no 60/61/800/66291 extra rows.
- The earlier S21/test divergence was not reproduced after the broad sequence,
  sparse-fragment, raw-cell column-shift, and unit-source rules. Windows
  cached replay, Windows live OCR capture, Android integration capture, and
  the final S21 UI import now agree on Paw Paw. The remaining UI blocker was a
  driver screen-contract mismatch for the preview overlay, not an extraction
  algorithm difference.

- [x] Rewrite `test/features/pdf/extraction/PDF_HARDENING.md` so the permanent standard is clear:
  - preprocessing/rendering cache is diagnostic upstream evidence only.
  - Google Vision OCR-call cache is the only accepted fast replay cache.
  - normalized/no-render/downstream replay is deleted, not guarded, not deprecated, and not diagnostic.
  - accepted replay must run the live extraction pipeline and substitute only the Google Vision network call.
  - every individual pay-item PDF must reach `>= 0.99` exact row accuracy before the lane is accepted.

- [x] Document the three pipeline stages in `PDF_HARDENING.md`:
  - preprocessing/rendering: PDF open, page render, image cleanup, table crop, crop geometry, OCR request image creation.
  - Google Vision OCR call: external OCR request/response boundary only.
  - post-processing/extraction: layout analysis, row classification, field parsing, repairs/flags, final pay item output.

- [x] Document preprocessing/rendering cache rules:
  - allowed: rendered page images, crop images, crop rectangles, page geometry, DPI, render config, preprocessing config, image hashes, request fingerprints.
  - forbidden: OCR text, normalized OCR elements, extracted pay items, corrected units, post-processed fields, final rows.
  - purpose: answer "what image did the live pipeline send to OCR?"
  - never allowed to answer "what did OCR say?" or "what rows did extraction produce?"

- [x] Document Google Vision OCR-call cache rules:
  - allowed: exact Google Vision response payloads, request image bytes hash, page/crop scope, PDF hash, document key, image dimensions, DPI, OCR config fingerprint, provider metadata.
  - replay must require exact request fingerprint match.
  - replay must fail on cache miss.
  - replay must fail on fingerprint mismatch.
  - replay must never fall through to network OCR.
  - replay must never start from loaded OCR elements or stage outputs.

- [x] Document no-divergence invariants:
  - live app and acceptance replay call the same extraction entrypoint.
  - the only replay substitution is the Google Vision network boundary.
  - rendering/preprocessing/cropping/OCR request construction always run.
  - changing render config, preprocessing config, crop bytes, DPI, OCR config, or PDF bytes forces recapture.
  - skipped render/preprocess/OCR stages invalidate the run.
  - cache files containing normalized OCR or extracted stage output invalidate the run.

- [x] Delete normalized replay production code:
  - `GocrNormalizedOcrReplayDocument`
  - `writeNormalizedReplay`
  - `ExtractionPipeline.extractFromNormalizedOcr`
  - normalized replay helper methods
  - normalized replay trace/source strings
  - normalized replay result fields.

- [x] Delete harness routing into normalized/no-render replay:
  - remove `_extractPayItemsFromNormalizedOcrCache`
  - remove `_writeNormalizedReplayCaptureIfAvailable`
  - remove any `cacheMode.replays` branch that bypasses normal PDF extraction.
  - ensure replay mode constructs the normal pipeline with `CachedOcrEngineV2` at the OCR boundary.

- [x] Delete downstream/no-render replay tests instead of preserving them:
  - remove `gocr_downstream_replay_test.dart` if it only exercises normalized replay.
  - remove normalized replay helper tests.
  - remove pipeline normalized replay tests.
  - remove report/trace helpers whose only purpose is no-render replay.

- [x] Remove every codebase/doc reference to:
  - `normalized_replay`
  - `GocrNormalizedOcrReplayDocument`
  - `extractFromNormalizedOcr`
  - `writeNormalizedReplay`
  - `gocr_downstream_no_render_ocr_replay`
  - `normalized_ocr_no_render`
  - "no-render replay"
  - "downstream replay" as an accepted PDF extraction path.

- [x] Invalidate artifacts produced by normalized/no-render replay:
  - delete or replace `tools/pdf-extraction/pdf_extraction_corpus_accepted_baseline.json`.
  - delete or replace `tools/pdf-extraction/pdf_extraction_corpus_ocr_cache_lock.json`.
  - remove canonical cache files containing `normalized_replay`.
  - remove result summaries that bless no-render replay as acceptance evidence.

- [x] Tighten OCR-call cache replay:
  - remove acceptance use of compatible fallback lookup that ignores request image bytes.
  - remove acceptance use of legacy un-fingerprinted cache entries.
  - require full request fingerprint for every accepted OCR cache hit.
  - require raw OCR `calls` only in active cache files.

- [x] Add cache validation:
  - active cache files must contain raw OCR calls.
  - active cache files must not contain normalized OCR pages.
  - active cache files must not contain extracted rows or post-processed stage output.
  - lock file must record raw OCR-call cache hashes only.
  - validation failure blocks accepted replay.

- [x] Restore accepted replay command behavior:
  - open the real PDF.
  - render pages normally.
  - run preprocessing normally.
  - run table/crop/grid logic normally.
  - enter the real OCR stage normally.
  - satisfy Google Vision calls from `.tmp/pdf_extraction_corpus_ocr_cache`.
  - fail closed on missing OCR cache entries.

- [x] Add focused tests:
  - cache capture writes raw OCR calls only.
  - replay requires exact request fingerprints.
  - replay fails on cache miss.
  - replay rejects cache files with normalized/stage-output snapshots.
  - removed normalized replay symbols are absent from code and tests.
  - cached replay traces include real render/preprocess/OCR-request stages.

- [x] Regenerate the canonical OCR-call cache:
  - use the normal extraction pipeline.
  - use Google Vision capture at the OCR boundary.
  - write only raw OCR-call responses.
  - verify no `normalized_replay` key exists anywhere in the canonical cache.

- [x] Regenerate accepted baseline:
  - use only live-equivalent cached OCR-call replay.
  - no normalized replay.
  - no no-render replay.
  - no project filter.
  - pay-item PDFs only.
  - record per-document exact row and field accuracy.

- [x] Iterate accuracy only after the replay lane is corrected:
  - triage from structured artifacts.
  - classify the first bad live stage before changing production code.
  - make only general algorithmic fixes.
  - reject PDF-name/project/fixture-specific rules.
  - run focused tests first.
  - run full cached OCR-call replay after every rule change.

- [x] Acceptance threshold / current user-approved closeout:
  - every individual pay-item PDF exact row accuracy must be `>= 0.99`.
  - aggregate exact field accuracy must remain high enough to support the row target.
  - zero trace-contract failures.
  - no missing documents.
  - no unexpected documents.
  - no skipped live stages.
  - 2026-05-09 closeout note: original per-PDF `>= 0.99` target is not met;
    user approved the current approximately 96% full-run row accuracy for this
    iteration only.

- [x] S21 live verification:
  - create a fresh office-technician project.
  - import Paw Paw PDF through the live app.
  - compare actual app output against ground truth.
  - do not claim 99% device accuracy unless the live app output reaches it.

- [x] Final cleanup:
  - remove stale active docs and completed plan references that can mislead future agents.
  - ensure `rg` for deleted replay terms returns no active code/doc hits except the new hardening warning that says the path is forbidden and deleted.
  - commit the cleanup, cache reset, docs, and accuracy iterations as logical commits with evidence in commit bodies.
