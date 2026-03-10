# Dependency Graph: pdfrx Parity Migration

**Date**: 2026-03-09
**Method**: CodeMunch index (681 files, 5341 symbols) + manual source verification

---

## Symbol: RenderedPage (class)
- **File**: `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart:14-30`
- **Fields**: `imageBytes` (Uint8List), `imageSizePixels` (Size), `dpi` (int), `pageIndex` (int)
- **Impact**: MODIFY — add `format` field + `RenderedImageFormat` enum
- **Callers (consumers)**:
  - `ImagePreprocessorV2.preprocess()` at `image_preprocessor_v2.dart:97` — reads `imageBytes`, `imageSizePixels`
  - `_preprocessIsolate()` at `image_preprocessor_v2.dart:194` — reads `imageBytes` via `_PreprocessParams`
  - `_createFallbackPage()` at `image_preprocessor_v2.dart:258` — reads `imageBytes` via `_PreprocessParams`
  - `TextRecognizerV2.recognize()` at `text_recognizer_v2.dart:72` — reads `originalPages` for DPI/size
  - `ExtractionPipeline._runExtractionStages()` at `extraction_pipeline.dart:438-443` — reads `imageBytes` for diagnostic callback
  - `OcrTextExtractor.extract()` at `ocr_text_extractor.dart:54-68` — passes through
- **Test constructors**:
  - `mock_stages.dart:67` — `MockPageRendererV2.render()`
  - `stage_2b_text_recognizer_test.dart:1814` — `_renderedPage()` helper
  - `stage_2b_image_preprocessor_test.dart:36,69,105,140,180,209,215,241,272,278` — inline constructors

## Symbol: PageRendererV2 (class)
- **File**: `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart:66-304`
- **Impact**: MODIFY — rewrite `_renderWithPdfx()` → `_renderWithPdfrx()`, simplify `_renderSinglePage()`
- **Callers**:
  - `ExtractionPipeline` field at `extraction_pipeline.dart:146`
  - `OcrTextExtractor` field at `ocr_text_extractor.dart:13`
  - `MpExtractionService` field at `mp_extraction_service.dart:40`

## Symbol: PageRendererV2._renderWithPdfx()
- **File**: `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart:243-303`
- **Impact**: DELETE — replace with `_renderWithPdfrx()`
- **Callers**: `_renderSinglePage()` at line 178

## Symbol: PageRendererV2._renderWithPrinting()
- **File**: `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart:194-240`
- **Impact**: DELETE — pdfrx replaces all rendering paths
- **Callers**: `_renderSinglePage()` at line 166

## Symbol: PageRendererV2._renderSinglePage()
- **File**: `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart:158-185`
- **Impact**: MODIFY — remove Platform.isWindows gate, single pdfrx path
- **Callers**: `render()` at line 94

## Symbol: _preprocessIsolate()
- **File**: `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart:194-255`
- **Impact**: MODIFY — add BGRA format detection before `img.decodeImage()`
- **Callers**: `ImagePreprocessorV2.preprocess()` at line 111 (via `compute()`)

## Symbol: _createFallbackPage()
- **File**: `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart:258-272`
- **Impact**: MODIFY — encode BGRA→PNG before storing as fallback
- **Callers**: `_preprocessIsolate()` at lines 198, 253

## Symbol: _PreprocessParams (class)
- **File**: `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart:174-183`
- **Impact**: MODIFY — add `format` field (RenderedImageFormat)

## Symbol: ImagePreprocessorV2.preprocess()
- **File**: `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart:97-170`
- **Impact**: MODIFY — pass `format` through to `_PreprocessParams`, encode BGRA→PNG in catch fallback

## Symbol: _adaptiveC (constant)
- **File**: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart:15`
- **Impact**: MODIFY — change from -2.0 to 10.0
- **Callers**: `_removeGridLines()` at `grid_line_remover.dart:216` (file-private only)

## Symbol: ExtractionPipeline._runExtractionStages() — diagnostic callback
- **File**: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart:438-443`
- **Impact**: MODIFY — encode BGRA→PNG before passing to `onDiagnosticImage`

## Symbols NOT changed (downstream firewall)
- `GridLineDetector.detect()` — receives PNG from preprocessor
- `GridLineRemover.remove()` — receives PNG from preprocessor (except _adaptiveC fix)
- `TextRecognizerV2.recognize()` — receives PNG from preprocessor
- All stages 3-6 — no image data, only structured data
