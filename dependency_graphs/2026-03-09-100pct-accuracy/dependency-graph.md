# Dependency Graph: 100% Accuracy Fixes

**Source**: 6 Opus research agents (Session 526) with file:line verification

## R1: Unit Normalization (26 items)

### Symbol: UnitRegistry.normalize
- **File**: `lib/features/pdf/services/extraction/shared/unit_registry.dart:73-84`
- **Callers**:
  - `RowParserV3._parseRow()` at `row_parser_v3.dart:179`
  - `PostProcessUtils._normalizeUnitInternal()` at `post_process_utils.dart:284-285`
- **Callees**: `unitAliases` map (lines 8-60), accent stripping regex
- **Impact**: MODIFY — remove alias remapping, keep accent cleanup

### Symbol: UnitRegistry.unitAliases
- **File**: `lib/features/pdf/services/extraction/shared/unit_registry.dart:8-60`
- **Callers**: `normalize()` at line 79
- **Impact**: MODIFY — either remove or reverse direction

### Symbol: UnitRegistry.knownUnits
- **File**: `lib/features/pdf/services/extraction/shared/unit_registry.dart:63-66`
- **Callers**: `RowParserV3._parseRow()` at `row_parser_v3.dart:200-203`
- **Impact**: VERIFY — already contains both long and short forms

### Symbol: PostProcessUtils.normalizeUnit
- **File**: `lib/features/pdf/services/extraction/shared/post_process_utils.dart:243-246`
- **Callers**: `ValueNormalizer._normalizeUnit()` at `value_normalizer.dart:42-57`
- **Callees**: `_cleanUnitText()`, `_normalizeUnitInternal()` -> `UnitRegistry.normalize()`
- **Impact**: VERIFY — chains to normalize(), will inherit fix

### Symbol: PostProcessUtils.isValidQuantity (LS check)
- **File**: `lib/features/pdf/services/extraction/shared/post_process_utils.dart:305`
- **Callers**: `ValueNormalizer` quantity validation
- **Impact**: MODIFY — change `== 'LS'` to `UnitRegistry.isLumpSum()`

### Symbol: RowParserV3 LS check at line 207
- **File**: `lib/features/pdf/services/extraction/stages/row_parser_v3.dart:207`
- **Impact**: MODIFY — change `!= 'LS'` to `!UnitRegistry.isLumpSum()`

### Symbol: RowParserV3 LS check at line 247
- **File**: `lib/features/pdf/services/extraction/stages/row_parser_v3.dart:247`
- **Impact**: MODIFY — change `== 'LS'` to `UnitRegistry.isLumpSum()`

### Symbol: ConsistencyChecker LS check at line 72
- **File**: `lib/features/pdf/services/extraction/stages/consistency_checker.dart:72`
- **Impact**: MODIFY — change `== 'LS'` to `UnitRegistry.isLumpSum()`

### Symbol: PostProcessorV2 LS check at line 724
- **File**: `lib/features/pdf/services/extraction/stages/post_processor_v2.dart:724`
- **Impact**: MODIFY — change `== 'LS'` to `UnitRegistry.isLumpSum()`

---

## R2: Row Classifier/Merger (2 MISS + 1 BOGUS)

### Symbol: RowClassifierV3._isMinorTextContent
- **File**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart:320-343`
- **Callers**: `_classifyRowType()` at line 280
- **Callees**: `_itemNumberPattern` regex, `zones.itemNumberColumn`
- **Impact**: MODIFY — return false when ANY text in itemNumber column (not just numeric matches)

### Symbol: RowClassifierV3._classifyRowType
- **File**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart:206-317`
- **Callers**: `classifyRows()` public method
- **Impact**: VERIFY — upstream caller of _isMinorTextContent

### Symbol: RowClassifierV3._groupElementsByRow
- **File**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart:612-649`
- **Constants**: `kAdaptiveRowYMultiplier=0.35`, `kMinRowYThreshold=0.002`
- **Impact**: VERIFY — row grouping is correct per research

### Symbol: RowMerger.merge
- **File**: `lib/features/pdf/services/extraction/stages/row_merger.dart:8-10` (signature), `29-42` (loop)
- **Callers**: `ExtractionPipeline` stage 4B
- **Impact**: MODIFY — add grid line parameter, add boundary guard

### Symbol: ClassifiedRows (model)
- **File**: Passed from RowClassifierV3 to RowMerger
- **Impact**: MODIFY — may need to carry grid line positions

---

## R3: Validation Gate (defense-in-depth)

### Symbol: RowParserV3 item number validation
- **File**: `lib/features/pdf/services/extraction/stages/row_parser_v3.dart:196-198`
- **Impact**: MODIFY — convert warning to `continue` (skip item)

### Symbol: ExtractionPatterns.itemNumberLoose
- **File**: `lib/features/pdf/services/extraction/shared/extraction_patterns.dart:24`
- **Pattern**: `^\d+(\.\d+)?[A-Za-z]?\.?$`
- **Impact**: USE — broader pattern for validation gate

---

## R4: bidAmount Backsolve (1 item)

### Symbol: ConsistencyChecker.applyConsistencyRules
- **File**: `lib/features/pdf/services/extraction/stages/consistency_checker.dart:92-138`
- **Callers**: PostProcessorV2 pipeline
- **Impact**: MODIFY — add bidAmount correction branch at line 128

### Symbol: PostProcessUtils.roundCurrency
- **File**: `lib/features/pdf/services/extraction/shared/post_process_utils.dart`
- **Impact**: USE — existing utility for rounding

### Symbol: ConfidenceConstants.kAdjMathBacksolve
- **File**: `lib/features/pdf/services/extraction/shared/confidence_model.dart:27`
- **Value**: -0.03
- **Impact**: USE — existing penalty constant

### Symbol: RepairType.mathValidation
- **File**: `lib/features/pdf/services/extraction/models/processed_items.dart:17`
- **Impact**: USE — existing repair type

---

## R5: Position-Based Grid Line Removal (5-8 description items)

### Symbol: GridLineRemover.removeGridLines
- **File**: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart:198-278`
- **Callers**: `ExtractionPipeline` at stage 2B-ii.6
- **Impact**: MODIFY — replace morphological mask-building with position-based masking

### Symbol: GridLineRemover constants
- **File**: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart:12-30`
- **Constants**: `_adaptiveBlockSize=15`, `_adaptiveC=10.0`, `_kernelDivisor=30`, `_inpaintRadius=2.0`, `_maskDilateIterations=1`
- **Impact**: MODIFY — remove morphological constants, keep/reduce inpaint radius

### Symbol: GridLineResult (model)
- **File**: `lib/features/pdf/services/extraction/models/grid_line_result.dart` (or similar)
- **Contains**: line positions (normalized), line widths, hasGrid boolean
- **Callers**: ExtractionPipeline passes to downstream stages
- **Impact**: USE — pass to remover (currently only hasGrid boolean is used)

### Symbol: ExtractionPipeline stage wiring
- **File**: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`
- **Impact**: MODIFY — pass full GridLineResult to remover instead of just hasGrid

### Symbol: GridLineDetector
- **File**: `lib/features/pdf/services/extraction/stages/grid_line_detector.dart`
- **Output**: GridLineResult with line positions and widths
- **Impact**: VERIFY — confirm output contains per-line width data needed by remover
