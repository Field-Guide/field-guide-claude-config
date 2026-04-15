---
paths:
  - "lib/features/pdf/services/extraction/**/*.dart"
  - "test/features/pdf/extraction/**/*.dart"
  - "test/features/pdf/services/mp/**/*.dart"
  - "tools/gocr_trace_viewer.html"
---

# PDF Extraction Heuristic Gate

Before changing extraction heuristics, read:
`docs/testing/pdf-extraction-heuristic-testing-standard.md`.

- Keep comparison exact. No normalization, tolerance, coercion, rounding, or
  checksum-only acceptance.
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
  `powershell -ExecutionPolicy Bypass -File scripts/audit_pdf_extraction_replay.ps1 -RunDir .tmp/google_ocr_research/<run_id>`
  and use the dated `.claude/test-results/YYYY-MM-DD/pdf-extraction-replay-audit-*`
  summary/CSVs for routine benchmark review.
- Do not broad-audit giant replay JSON with ad hoc
  `Get-Content -Raw | ConvertFrom-Json` or dump nested mismatch JSON through
  `ConvertTo-Json`; use compact CSVs first and open large JSON only for one
  targeted provenance row.
- Standard loop: classify first bad stage, add focused tests, implement the
  general rule, run touched/adjacent tests, run original-four replay, run full
  cached-corpus replay, then record deltas.
- Accept only if the target improves or a trace contract closes with no
  original-four or full-corpus regressions.
