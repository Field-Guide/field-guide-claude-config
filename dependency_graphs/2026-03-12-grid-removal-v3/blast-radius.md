# Grid Removal v3: Dependency Graph & Blast Radius

**Date**: 2026-03-12
**Spec**: `.claude/specs/2026-03-12-grid-removal-v3-spec.md`

## Affected Symbols

### DIRECT (Modified)

| Symbol | File | Lines | Change |
|--------|------|-------|--------|
| `_removeGridLines()` | `grid_line_remover.dart:216-446` | 230 | **REPLACE** entire function with morph+HoughLinesP algorithm |
| `_GridRemovalResult` | `grid_line_remover.dart:180-202` | 22 | **REPLACE** `sampleCount` and `matchScoreStats` with morph/hough metrics |
| `_matchedFilterY()` | `grid_line_remover.dart:460-504` | 44 | **DELETE** - no longer needed |
| `_matchedFilterX()` | `grid_line_remover.dart:517-558` | 41 | **DELETE** - no longer needed |
| `GridLineRemover.remove()` | `grid_line_remover.dart:31-174` | 143 | **MODIFY** per-page metrics keys + diagnostic image emissions |
| `_inpaintRadius` | `grid_line_remover.dart:15` | 1 | KEEP (same value 1.0) |
| `_kDarkPixelThreshold` | `grid_line_remover.dart:19` | 1 | KEEP (same value 128) |

### DEPENDENT (Consumers - verify no breakage)

| Symbol | File | Impact |
|--------|------|--------|
| `ExtractionPipeline._runExtractionStages()` | `extraction_pipeline.dart:371` | Calls `gridLineRemover.remove()` - signature UNCHANGED |
| `ExtractionPipeline._buildGridLinesForOcr()` | `extraction_pipeline.dart:757` | Reads `per_page` metrics from report - keys UNCHANGED |
| `TextRecognizerV2.recognize()` | `text_recognizer_v2.dart:72` | Consumes cleaned pages - format UNCHANGED |
| `MockGridLineRemover.remove()` | `mock_stages.dart:160` | Mock metrics include `mask_pixels_total`, `mask_coverage_ratio_avg` - UNCHANGED |

### TEST (Directly affected test files)

| File | Impact |
|------|--------|
| `grid_line_remover_test.dart` | **MODIFY** - update metric expectations, add new tests |
| `grid_removal_diagnostic_test.dart` | **MODIFY** - add new diagnostic image outputs |
| `extraction_pipeline_test.dart` | VERIFY ONLY - remover is mocked, no changes |
| `re_extraction_loop_test.dart` | VERIFY ONLY - remover is mocked |
| `mock_stages.dart` | VERIFY ONLY - mock metrics stay compatible |

### NEW FILES

| File | Purpose |
|------|---------|
| `test/.../contracts/stage_2b5_to_2b6_contract_test.dart` | Contract: detector -> remover |
| `test/.../contracts/stage_2b6_to_2biii_contract_test.dart` | Contract: remover -> OCR |
| `test/.../stages/grid_line_remover_morph_test.dart` | Synthetic text-contact tests |

### CLEANUP (Dead code after migration)

| Symbol | File | Lines Removed |
|--------|------|---------------|
| `_matchedFilterY()` | `grid_line_remover.dart:460-504` | ~44 lines |
| `_matchedFilterX()` | `grid_line_remover.dart:517-558` | ~41 lines |
| `sampleCount` field | `_GridRemovalResult` | replaced |
| `matchScoreStats` field | `_GridRemovalResult` | replaced |
| `matchScoreValues` accumulation | `_removeGridLines()` | ~40 lines |

**Total**: ~130 lines removed, ~250 lines added (net +120)

## Cross-Cutting Concerns

1. **opencv_dart API usage**: All new API calls verified in opencv_dart 2.2.1+3 (spec section)
2. **Native memory**: ~16 Mat objects per page, all tracked in try/finally (spec section)
3. **StageReport metrics**: Keys change in per-page metrics (`sample_count` -> morph/hough keys). Aggregate keys (`mask_pixels_total`, `mask_coverage_ratio_avg`, `per_page`) UNCHANGED.
4. **Diagnostic images**: 3 new callback names added. 2 existing names unchanged.

## Callers of GridLineRemover (complete list)

1. `ExtractionPipeline._runExtractionStages()` - production caller
2. `GridLineRemover` unit tests - direct instantiation
3. `grid_removal_diagnostic_test.dart` - integration test
4. `old_grid_removal_diagnostic_test.dart` - legacy diagnostic
5. `MockGridLineRemover` - mock for pipeline tests (extends GridLineRemover)
