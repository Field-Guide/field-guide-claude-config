# Code Review: Springfield 100% Accuracy Implementation Plan

**Date**: 2026-03-09
**Reviewer**: code-review-agent (Opus)
**Scope**: Plan vs spec vs actual source code (12 files verified line-by-line)
**Verdict**: DO NOT EXECUTE until C1, C2, C3 resolved

## CRITICAL

### C1: R2a fix is negated by `_rescueBoilerplateRows` -- items 94/95 will NOT be recovered

`_rescueBoilerplateRows` (row_classifier_v3.dart:345-402) runs AFTER initial classification and rescues boilerplate rows with price content back to priceContinuation. Row 214 ("Boy" + prices) would be rescued right back, undoing the fix.

**Fix**: Add the same item-column-text guard to `_rescueBoilerplateRows`.

### C2: R2c (downstream rescue for item 95) is in spec but NOT in plan

Even after fixing C1, row 214 becomes boilerplate. Without R2c, there is no path for row 214 to become a data row. Item 95 ($26,656) remains MISSING.

**Fix**: Add sub-phase implementing R2c — classify rows with item-column text + price columns as `data` with reduced confidence.

### C3: R3 uses non-existent `excludedCount` variable

Same as security H1. Will cause StateError crash. Must use `skippedRows.add()` pattern.

## HIGH

### H1: Merger grid-line guard mixes all pages without page filtering

Same as security M1. Flattened list causes false merge-blocking on multi-page PDFs.

### H2: R4 regex is DRY violation

Plan defines new loose regex instead of reusing `_EuropeanPeriodsCurrencyRule._pattern` from `currency_rules.dart:125`.

## MEDIUM

- M1: R5 may not fix description accuracy (trailing words are OCR limit, not mask problem)
- M2: Test helpers use wrong types (OcrElement needs Rect not BoundingBox, missing pageIndex)
- M3: isLumpSum LS-prefix matching overly broad

## POSITIVE

- File/line references are accurate across all 12 source files
- R1 is well-designed (all 5 LS checks correctly identified)
- R4 logic is sound (pattern-gated + relative-error-gated)
- R5 architecture is solid (position-based masking, 70% fewer Mat allocations)
- Data-accounting awareness preserved in merger changes
