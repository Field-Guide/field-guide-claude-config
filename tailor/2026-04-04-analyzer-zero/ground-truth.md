# Ground Truth

All literals, paths, and symbols verified against codebase on 2026-04-04.

## analysis_options.yaml Structure

| Item | Line | Verified |
|------|------|----------|
| `do_not_use_environment: true` | 57 | VERIFIED |
| `strict_raw_type: true` | 65 | VERIFIED (undefined_lint — not recognized) |
| `avoid_catches_without_on_clauses: true` | 78 | VERIFIED |
| `cast_nullable_to_non_nullable: true` | 63 | VERIFIED |
| `avoid_equals_and_hash_code_on_mutable_classes: true` | 71 | VERIFIED |
| `no_runtimetype_toString: true` | 102 | VERIFIED |
| `discarded_futures: true` | 36 | VERIFIED |
| `avoid_dynamic_calls: true` | 64 | VERIFIED |
| Existing exclude patterns | 12-20 | VERIFIED (no test/ exclusion exists) |

## Key Class Locations

| Class | File | Line | Verified |
|-------|------|------|----------|
| `RepositoryResult<T>` | `lib/shared/repositories/base_repository.dart` | 56 | VERIFIED |
| `BaseRepository<T>` | `lib/shared/repositories/base_repository.dart` | 7 | VERIFIED |
| `ProjectScopedRepository<T>` | `lib/shared/repositories/base_repository.dart` | 34 | VERIFIED |
| `BaseListProvider<T, R>` | `lib/shared/providers/base_list_provider.dart` | 14 | VERIFIED |
| `PagedListProvider<T, R>` | `lib/shared/providers/paged_list_provider.dart` | 15 | VERIFIED |
| `StageNames` | `lib/features/pdf/services/extraction/stages/stage_names.dart` | 5 | VERIFIED |
| `TodoProvider` | `lib/features/todos/presentation/providers/todo_provider.dart` | 33 | VERIFIED |
| `FormResponseRepositoryImpl` | `lib/features/forms/data/repositories/form_response_repository.dart` | 10 | VERIFIED |
| `Logger` | `lib/core/logging/logger.dart` | (static methods) | VERIFIED |

## StageNames Constants Mapping

| Stage Class | File | StageNames Constant | Verified |
|-------------|------|---------------------|----------|
| `CellExtractorV2` | `cell_extractor_v2.dart` | `StageNames.cellExtraction` | VERIFIED |
| `ColumnDetectorV2` | `column_detector_v2.dart` | `StageNames.columnDetection` | VERIFIED |
| `DocumentQualityProfiler` | `document_quality_profiler.dart` | `StageNames.documentAnalysis` | VERIFIED |
| `ElementValidator` | `element_validator.dart` | `StageNames.elementValidation` | VERIFIED |
| `FieldConfidenceScorer` | `field_confidence_scorer.dart` | `StageNames.fieldConfidenceScoring` | VERIFIED |
| `GridLineDetector` | `grid_line_detector.dart` | `StageNames.gridLineDetection` | VERIFIED |
| `GridLineRemover` | `grid_line_remover.dart` | `StageNames.gridLineRemoval` | VERIFIED |
| `HeaderConsolidator` | `header_consolidator.dart` | `StageNames.headerConsolidationFinal` | VERIFIED |
| `ImagePreprocessorV2` | `image_preprocessor_v2.dart` | `StageNames.imagePreprocessing` | VERIFIED |
| `NumericInterpreter` | `numeric_interpreter.dart` | `StageNames.numericInterpretation` | VERIFIED |
| `PageRendererV2` | `page_renderer_v2.dart` | `StageNames.pageRendering` | VERIFIED |
| `PostProcessorV2` | `post_processor_v2.dart` | `StageNames.postProcessing` | VERIFIED |
| `QualityValidator` | `quality_validator.dart` | `StageNames.qualityValidation` | VERIFIED |
| `RegionDetectorV2` | `region_detector_v2.dart` | `StageNames.regionDetection` | VERIFIED |
| `RowClassifierV3` | `row_classifier_v3.dart` | `StageNames.rowClassification` | VERIFIED |
| `RowMerger` | `row_merger.dart` | `StageNames.rowMerging` | VERIFIED |
| `RowParserV3` | `row_parser_v3.dart` | `StageNames.rowParsing` | VERIFIED |
| `TextRecognizerV2` | `text_recognizer_v2.dart` | `StageNames.textRecognition` | VERIFIED |

## RepositoryResult API

| Member | Signature | Verified |
|--------|-----------|----------|
| `data` | `T? data` | VERIFIED |
| `error` | `String? error` | VERIFIED |
| `isSuccess` | `bool isSuccess` | VERIFIED |
| `success` | `factory RepositoryResult.success(T data)` | VERIFIED |
| `failure` | `factory RepositoryResult.failure(String error)` | VERIFIED |
| `empty` | `factory RepositoryResult.empty()` | VERIFIED |
| `safeCall` | **DOES NOT EXIST YET** — to be added | N/A |

## BaseListProvider State Fields

| Field | Type | Verified |
|-------|------|----------|
| `_items` | `List<T>` | VERIFIED |
| `_currentProjectId` | `String?` | VERIFIED |
| `_isLoading` | `bool` | VERIFIED |
| `_error` | `String?` | VERIFIED |

## CopyWith Sentinel Pattern

| Element | Value | Verified |
|---------|-------|----------|
| Sentinel declaration | `static const _sentinel = Object();` | VERIFIED (all models) |
| Parameter type | `Object? fieldName = _sentinel` | VERIFIED |
| Check pattern | `identical(fieldName, _sentinel) ? this.fieldName : fieldName as TargetType` | VERIFIED |
| Cast triggering lint | `fieldName as TargetType` (when TargetType is non-nullable) | VERIFIED |

## Lint Rules for New Files

| New File Path | Applicable Custom Lint Rules |
|---------------|------------------------------|
| `lib/shared/utils/safe_row.dart` | A10 (max_file_length), A11 (max_import_count) |
| `lib/shared/providers/safe_action_mixin.dart` | A10, A11, A9 (no_silent_catch — Logger required in catch) |

## matching_super_parameters Violations

| Pattern | Example | Count |
|---------|---------|-------|
| `super.supabaseClient` vs parent's `supabase` | Remote datasource constructors | ~17 |
| `super.dbService` vs parent's `_dbService` | Various constructors | ~7 |
| Other mismatches | Misc | ~1 |
