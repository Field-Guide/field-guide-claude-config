---
paths:
  - "lib/features/pdf/services/extraction/**/*.dart"
  - "test/features/pdf/extraction/**/*.dart"
  - "test/features/pdf/services/mp/**/*.dart"
  - "tools/pdf-extraction/gocr_trace_viewer.html"
---

# PDF Extraction Heuristic Gate

Before changing extraction heuristics, read:
`docs/testing/pdf-extraction-heuristic-testing-standard.md`.

- Keep comparison exact. No normalization, tolerance, coercion, rounding, or
  checksum-only acceptance.
- Treat math and checksum as validation only. They may flag or block a result,
  but must never repair extracted numeric fields or expected/ground-truth
  fixtures.
- Do not use row math or checksum evidence to change, infer, overwrite, derive,
  normalize, or select `quantity`, `unitPrice`, `bidAmount`, expected values, or
  ground truth. The executable guard is
  `flutter test test/features/pdf/extraction/contracts/pdf_math_validation_only_guardrail_test.dart -d windows`.
- Use broad algorithmic rules only: geometry, row/column structure, labels,
  source IDs, units, numeric consistency, sequence evidence, and provenance.
- Never branch on document key, PDF name, fixture path, agency, contractor,
  county, expected text, or one item number.
- Fixture edits require visual PDF evidence or explicit user confirmation and
  review-ledger/status updates.
- Every changed final field needs traceable stage data: stable `rule_name`,
  `reason_code`, mutation kind, before/after values, and source provenance.
- Evidence comes from mismatch JSON/CSV and stage trace artifacts, not console
  text.
- After replay, run
  `powershell -ExecutionPolicy Bypass -File tools/pdf-extraction/audit_pdf_extraction_replay.ps1 -RunDir .tmp/google_ocr_research/<run_id>`
  and use the dated `tools/testing/test-results/YYYY-MM-DD/pdf-extraction-replay-audit-*`
  summary/CSVs for routine benchmark review.
- Do not broad-audit giant replay JSON with ad hoc
  `Get-Content -Raw | ConvertFrom-Json` or dump nested mismatch JSON through
  `ConvertTo-Json`; use compact CSVs first and open large JSON only for one
  targeted provenance row.
- Standard loop: classify first bad stage, add focused tests, implement the
  general rule, run touched/adjacent tests, run the protected full-corpus
  replay, then record deltas. The protected corpus is every project listed in
  `test/features/pdf/extraction/fixtures/pdf_extraction_corpus_manifest.json`
  under `regression_policy.protected_project_ids`; filtered runs are diagnostic
  only.
- The active full-corpus replay cache path is
  `.tmp/pdf_extraction_corpus_ocr_cache`; run acceptance with
  `PDF_CORPUS_OCR_CACHE_MODE=replay` and
  `PDF_CORPUS_OCR_CACHE_DIR=.tmp/pdf_extraction_corpus_ocr_cache`.
- Protected corpus PDFs are tracked through Git LFS under
  `test/features/pdf/extraction/corpus/protected/`; manifest entries must not
  depend on `.tmp`, OneDrive, Desktop, or another machine-local location.
- Accept only if the target improves or a trace contract closes with no
  protected full-corpus regressions.
