# Dependency Graph: Grid Line Threshold Fix

## Symbol: _adaptiveC (top-level constant)
- **File**: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart:15`
- **Callers**: `_removeGridLines()` at line 210 (same file)
- **Callees**: None (constant)
- **Impact**: MODIFY

## Symbol: _removeGridLines (top-level function)
- **File**: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart:193`
- **Callers**: `GridLineRemover.remove()` at line 87 (same file)
- **Callees**: `cv.adaptiveThreshold()`, `cv.morphologyEx()`, `cv.inpaint()`, `cv.countNonZero()`
- **Impact**: VERIFY (behavior changes via `_adaptiveC`)

## Symbol: GridLineRemover.remove (method)
- **File**: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart:27`
- **Callers**: `ExtractionPipeline._runExtractionStages()` at `extraction_pipeline.dart:508`
- **Callees**: `_removeGridLines()`
- **Impact**: VERIFY

## Symbol: ExtractionPipeline._runExtractionStages (method)
- **File**: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart:372`
- **Callers**: `ExtractionPipeline.run()` at `extraction_pipeline.dart:210`
- **Callees**: `GridLineRemover.remove()`, `TextRecognizerV2.recognize()`, and 12 other stages
- **Impact**: VERIFY (improved OCR quality propagates through all downstream stages)

## Symbol: MockGridLineRemover (test mock)
- **File**: `test/features/pdf/extraction/helpers/mock_stages.dart:158`
- **Callers**: `extraction_pipeline_test.dart:140,195`, `re_extraction_loop_test.dart:311`
- **Callees**: None (mock returns canned data)
- **Impact**: NOT AFFECTED (mock bypasses real GridLineRemover)
