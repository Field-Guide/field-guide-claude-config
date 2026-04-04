# Pattern: Stage Names Constants

## How We Do It
The PDF extraction pipeline has 18 stage classes, each logging structured messages with `Logger.pdf()`. All stages use `$runtimeType` in log strings for stage identification. The `StageNames` abstract class already holds canonical string constants for each stage, used in `StageReport` creation. The fix unifies logging with the same constants.

## Exemplar

### StageNames (lib/features/pdf/services/extraction/stages/stage_names.dart:5)

```dart
abstract class StageNames {
  static const documentAnalysis = 'document_analysis';
  static const pageRendering = 'page_rendering';
  static const imagePreprocessing = 'image_preprocessing';
  static const gridLineDetection = 'grid_line_detection';
  static const gridLineRemoval = 'grid_line_removal';
  static const textRecognition = 'text_recognition';
  static const elementValidation = 'element_validation';
  static const elementClamping = 'element_clamping';
  static const rowClassification = 'row_classification';
  static const headerConsolidationProvisional = 'header_consolidation_provisional';
  static const headerConsolidationFinal = 'header_consolidation_final';
  static const rowMerging = 'row_merging';
  static const rowPathways = 'row_pathways';
  static const orphanElements = 'orphan_elements';
  static const postColumnRefinement = 'post_column_refinement';
  static const regionDetection = 'region_detection';
  static const columnDetection = 'column_detection';
  static const columnDetectionLayers = 'column_detection_layers';
  static const cellExtraction = 'cell_extraction';
  static const numericInterpretation = 'numeric_interpretation';
  static const rowParsing = 'row_parsing';
  static const fieldConfidenceScoring = 'field_confidence_scoring';
  static const postNormalize = 'post_normalize';
  static const postSplit = 'post_split';
  static const postValidate = 'post_validate';
  static const postSequenceCorrect = 'post_sequence_correct';
  static const postDeduplicate = 'post_deduplicate';
  static const postProcessing = 'post_processing';
  static const qualityValidation = 'quality_validation';
}
```

### Current Pattern (to be replaced)
```dart
Logger.pdf('STAGE_START stage=$runtimeType');            // <-- no_runtimetype_tostring
Logger.pdf('STAGE_COMPLETE stage=$runtimeType elapsed=${sw.elapsedMilliseconds}ms');
```

### Target Pattern
```dart
static const _logTag = StageNames.cellExtraction;        // or appropriate constant
Logger.pdf('STAGE_START stage=$_logTag');
Logger.pdf('STAGE_COMPLETE stage=$_logTag elapsed=${sw.elapsedMilliseconds}ms');
```

## Imports
```dart
import 'package:construction_inspector/features/pdf/services/extraction/stages/stage_names.dart';
```
