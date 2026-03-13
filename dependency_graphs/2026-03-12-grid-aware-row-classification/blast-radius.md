# Blast Radius Analysis: Grid-Aware Row Classification
**Date**: 2026-03-12
**Feature**: Pass gridLines to RowClassifierV3 for grid-aware row grouping

## Entry Points (DIRECT changes)

### 1. RowClassifierV3.classify()
- **File**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart:55-172`
- **Change**: Add optional `GridLines? gridLines` parameter
- **Impact**: Signature change propagates to all callers and all overrides

### 2. RowClassifierV3._groupElementsByRow()
- **File**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart:612-649`
- **Change**: New `_groupElementsByGridRows()` method; `classify()` dispatches to it when gridLines present
- **Impact**: Internal only, no external callers

### 3. ExtractionPipeline._runExtractionStages()
- **File**: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart:371-755`
- **Change**: Pass `gridLines` at line 574 (provisional) and line 661 (final)
- **Impact**: Internal, gridLines already exists as local variable

## Callers (DEPENDENT changes)

### Direct callers of classify()
| Caller | File:Line | Change Required |
|--------|-----------|-----------------|
| ExtractionPipeline._runExtractionStages | extraction_pipeline.dart:574 | Add `gridLines: gridLines` |
| ExtractionPipeline._runExtractionStages | extraction_pipeline.dart:661 | Add `gridLines: gridLines` |

### Mock overrides of classify()
| Mock Class | File:Line | Change Required |
|------------|-----------|-----------------|
| MockRowClassifierV3 | mock_stages.dart:283-319 | Add `GridLines? gridLines` param |
| _MixedPageRowClassifier | extraction_pipeline_test.dart:349-419 | Add `GridLines? gridLines` param |
| _HeaderFragmentingRowClassifier | extraction_pipeline_test.dart:421-??? | Add `GridLines? gridLines` param |

## Downstream Consumers (NO changes required)
These consume ClassifiedRows output but are format-unchanged:
- HeaderConsolidator.consolidate() - consumes ClassifiedRows
- RowMerger.merge() - consumes ClassifiedRows
- CellExtractorV2.extract() - consumes MergedRows
- RowParserV3.parse() - consumes CellGrid
- RegionDetectorV2.detect() - consumes ClassifiedRows

## Category Summary

| Category | Files | Count |
|----------|-------|-------|
| DIRECT | row_classifier_v3.dart, extraction_pipeline.dart | 2 |
| DEPENDENT (mocks) | mock_stages.dart, extraction_pipeline_test.dart | 2 |
| TEST (new/modified) | row_classifier_v3_test.dart | 1 |
| CLEANUP | none | 0 |
| **Total** | | **5** |

## Risk Assessment
- **Low risk**: Optional parameter with null default = backward compatible
- **Low risk**: No model changes (ClassifiedRow, ClassifiedRows unchanged)
- **Low risk**: Non-grid pages fall back to existing Y-proximity logic
- **Medium risk**: Grid-aware grouping may surface new rows previously hidden as boilerplate, affecting continuation chaining. _splitRowWithMultipleItemNumbers() still needed for multi-item grid rows.
