# Adversarial Review: Pipeline Report Redesign

**Spec**: `.claude/specs/2026-03-13-pipeline-report-redesign-spec.md`
**Date**: 2026-03-13
**Reviewers**: code-review-agent, security-agent

## MUST-FIX (addressed in spec update)

1. **Stage metrics data gap**: `inputCount`/`outputCount`/`excludedCount` not serialized to JSON. Fixed: spec now requires additive JSON change to `_buildStageMetrics`.
2. **Pipe character escaping**: OCR text containing `|` breaks markdown tables. Fixed: spec now requires escaping `|` to `\|` in all cell values.

## SHOULD-CONSIDER (addressed in spec update)

3. **Regressions section missing**: Added back between Header and Stage Summary (conditional on gate failure).
4. **"All classified rows" claim inaccurate**: Boilerplate/blank rows filtered by row_merging before cell extraction. Spec updated to say "all rows that reach cell extraction."
5. **Description truncation**: Clean Grid truncates to 40 chars. OCR Grid untruncated (noise visibility > formatting).
6. **Row index clarification**: Documented as sequential position (loop counter), not original classified row index.
7. **NaN/Infinity confidence**: Spec now requires clamping to 0.0-1.0 before formatting.

## NICE-TO-HAVE (not addressed — implement if time allows)

- Row type abbreviation mapping as a named constant map in code
- Page row count in section headers (e.g., "Page 1 (23 rows)")
- Factor out shared page-grouping logic between Clean Grid and OCR Grid builders

## Security Review Summary

- **No security concerns**. Test-only output, gitignored, not shipped in APK.
- **No PII**: Public bid data from publicly-bid construction contract.
- **No OWASP relevance**: Test infrastructure only.
