# Blast Radius: pdfrx Parity Migration

**Date**: 2026-03-09
**Last verified**: 2026-03-09 (CodeMunch re-index confirmed all entries)
**Scope**: Replace `package:pdfx` with `package:pdfrx` in the PDF extraction pipeline
**Analysis method**: CodeMunch index of `lib/features/pdf/` (87 files, 805 symbols)

---

## 1. Current Package Usage

### pdfx (TO BE REMOVED)

| Location | Usage |
|----------|-------|
| `pubspec.yaml:75` | `pdfx: ^2.9.2` |
| `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart:7` | `import 'package:pdfx/pdfx.dart' as pdfx;` |

**pdfx is imported in exactly ONE file.** All pdfx API usage is contained within `PageRendererV2._renderWithPdfx()`.

### printing (MUST STAY)

| Location | Usage |
|----------|-------|
| `page_renderer_v2.dart:8` | `import 'package:printing/printing.dart';` -- `Printing.raster()` for Windows primary rendering |
| `pdf_service.dart:5` | `import 'package:printing/printing.dart';` -- `Printing.layoutPdf()`, `Printing.sharePdf()` |
| `form_pdf_service.dart:4` | `import 'package:printing/printing.dart';` -- `Printing.layoutPdf()`, `Printing.sharePdf()` |
| `mdot_hub_screen.dart:5` | `import 'package:printing/printing.dart';` |
| `form_viewer_screen.dart:6` | `import 'package:printing/printing.dart';` |

**Verdict**: `printing` is used for PDF preview/sharing across `forms` and `pdf` features. It MUST remain. Only the `Printing.raster()` usage in `page_renderer_v2.dart` is related to the rendering pipeline.

### syncfusion_flutter_pdf (UNRELATED)

`PdfDocument` used in the pipeline is from `package:syncfusion_flutter_pdf/pdf.dart` (line 14 of `extraction_pipeline.dart`), NOT from pdfx. This is for PDF text extraction / metadata and is unaffected by the migration.

---

## 2. Core Classes & Data Flow

### Full Pipeline Call Chain

```
pdf_import_service.dart
  └── ExtractionPipeline.extract()              [extraction_pipeline.dart:220]
        └── _runExtractionStages()               [extraction_pipeline.dart:371]
              │
              ├── Stage 2B-i:  PageRendererV2.render()
              │     ├── _renderSinglePage()
              │     │     ├── [Windows] _renderWithPrinting()  → RenderedPage
              │     │     └── [Fallback] _renderWithPdfx()     → RenderedPage  ← PDFX LIVES HERE
              │     └── Returns: Map<int, RenderedPage>
              │
              ├── Stage 2B-ii: ImagePreprocessorV2.preprocess()
              │     ├── Reads: RenderedPage.imageBytes, RenderedPage.imageSizePixels
              │     └── Returns: Map<int, PreprocessedPage>
              │
              ├── Stage 2B-ii.5: GridLineDetector.detect()
              │     ├── Reads: PreprocessedPage.enhancedImageBytes
              │     └── Returns: GridLines
              │
              ├── Stage 2B-ii.6: GridLineRemover.remove()
              │     ├── Reads: PreprocessedPage.enhancedImageBytes
              │     ├── Writes: new PreprocessedPage (with cleaned bytes)
              │     └── Returns: Map<int, PreprocessedPage> (cleaned)
              │
              ├── Stage 2B-iii: TextRecognizerV2.recognize()
              │     ├── Reads: PreprocessedPage.enhancedImageBytes (cleaned)
              │     ├── Reads: RenderedPage (originalPages for DPI/size)
              │     └── Returns: Map<int, List<OcrElement>>
              │
              └── Stages 3-4E: downstream processing (unaffected)
```

### Alternate Pipeline (MP Extraction)

```
mp_extraction_service.dart
  └── _ocrPage()                                  [mp_extraction_service.dart:210]
        └── OcrTextExtractor.extractPageText()    [ocr_text_extractor.dart:98]
              ├── PageRendererV2.render()           ← SAME RENDERER
              ├── ImagePreprocessorV2.preprocess()
              └── TextRecognizerV2.recognize()
```

---

## 3. Symbol Dependency Map

### RenderedPage (class) — `page_renderer_v2.dart:14`

**Fields**: `imageBytes` (Uint8List), `imageSizePixels` (Size), `dpi` (int), `pageIndex` (int)

| Consumer | File | What it reads |
|----------|------|---------------|
| `ImagePreprocessorV2.preprocess()` | `image_preprocessor_v2.dart:97` | `imageBytes`, `imageSizePixels` |
| `TextRecognizerV2.recognize()` | `text_recognizer_v2.dart:72` | `originalPages` param -- used for render DPI/size metadata |
| `ExtractionPipeline._runExtractionStages()` | `extraction_pipeline.dart:438-441` | `imageSizePixels` (stage output), `imageBytes` (diagnostic) |
| `OcrTextExtractor.extract()` | `ocr_text_extractor.dart:54-68` | Passes through to preprocessor and recognizer |

**Constructors** (where RenderedPage is created):
- `_renderWithPrinting()` at `page_renderer_v2.dart:210`
- `_renderWithPdfx()` at `page_renderer_v2.dart:291`

### PageRendererV2 (class) — `page_renderer_v2.dart:66`

| Caller | File | How it's used |
|--------|------|---------------|
| `ExtractionPipeline` (field) | `extraction_pipeline.dart:146` | `final PageRendererV2 pageRenderer;` |
| `ExtractionPipeline` (constructor) | `extraction_pipeline.dart:169,189` | `pageRenderer ?? PageRendererV2()` |
| `OcrTextExtractor` (field) | `ocr_text_extractor.dart:13` | `final PageRendererV2 _renderer;` |
| `OcrTextExtractor` (constructor) | `ocr_text_extractor.dart:19,23` | `renderer ?? PageRendererV2()` |
| `MpExtractionService` (field) | `mp_extraction_service.dart:40` | `PageRendererV2? _renderer;` |
| `MpExtractionService` (constructor) | `mp_extraction_service.dart:54,222` | `_renderer ??= PageRendererV2()` |

### ImagePreprocessorV2 (class) — `image_preprocessor_v2.dart:88`

| Caller | File | How it's used |
|--------|------|---------------|
| `ExtractionPipeline` (field) | `extraction_pipeline.dart:147` | `final ImagePreprocessorV2 imagePreprocessor;` |
| `ExtractionPipeline` (constructor) | `extraction_pipeline.dart:170,190` | `imagePreprocessor ?? ImagePreprocessorV2()` |
| `OcrTextExtractor` (field) | `ocr_text_extractor.dart:14` | `final ImagePreprocessorV2 _preprocessor;` |
| `OcrTextExtractor` (constructor) | `ocr_text_extractor.dart:20,24` | `preprocessor ?? ImagePreprocessorV2()` |
| `MpExtractionService` (field) | `mp_extraction_service.dart:41` | `ImagePreprocessorV2? _preprocessor;` |
| `MpExtractionService` (constructor) | `mp_extraction_service.dart:55,223` | `_preprocessor ??= ImagePreprocessorV2()` |

### PreprocessedPage (class) — `image_preprocessor_v2.dart:12`

**Fields**: `enhancedImageBytes` (Uint8List), `enhancedSizePixels` (Size), `pageIndex` (int), `stats` (PreprocessingStats), `preprocessingApplied` (bool)

| Consumer | File | What it reads |
|----------|------|---------------|
| `GridLineDetector.detect()` | `grid_line_detector.dart:25` | `enhancedImageBytes` |
| `GridLineRemover.remove()` | `grid_line_remover.dart:27` | `enhancedImageBytes`, `pageIndex`, `stats`, `preprocessingApplied` |
| `TextRecognizerV2.recognize()` | `text_recognizer_v2.dart:72` | `enhancedImageBytes` (via `pages` param) |
| `TextRecognizerV2._recognizeFullPage()` | `text_recognizer_v2.dart:236,246` | `enhancedImageBytes` |
| `TextRecognizerV2._recognizeWithCellCrops()` | `text_recognizer_v2.dart:256,281` | `enhancedImageBytes` |
| `ExtractionPipeline._runExtractionStages()` | `extraction_pipeline.dart:455-479` | `enhancedSizePixels`, `preprocessingApplied`, `stats`, `enhancedImageBytes` (diagnostic) |

**Constructors** (where PreprocessedPage is created):
- `ImagePreprocessorV2._preprocessIsolate()` at `image_preprocessor_v2.dart:238`
- `ImagePreprocessorV2._createFallbackPage()` at `image_preprocessor_v2.dart:260`
- `GridLineRemover.remove()` at `grid_line_remover.dart:88` (wraps cleaned bytes)

### GridLineRemover (class) — `grid_line_remover.dart:24`

| Caller | File | How it's used |
|--------|------|---------------|
| `ExtractionPipeline` (field) | `extraction_pipeline.dart:149` | `final GridLineRemover gridLineRemover;` |
| `ExtractionPipeline` (constructor) | `extraction_pipeline.dart:172,192` | `gridLineRemover ?? GridLineRemover()` |
| `ExtractionPipeline._runExtractionStages()` | `extraction_pipeline.dart:492` | `gridLineRemover.remove(...)` |

### _adaptiveC (constant) — `grid_line_remover.dart:15`

| Usage | File | Line |
|-------|------|------|
| Declaration | `grid_line_remover.dart:15` | `const double _adaptiveC = -2.0;` |
| Usage | `grid_line_remover.dart:216` | Passed to adaptive thresholding |

**Scope**: File-private constant. Only used within `grid_line_remover.dart`. Zero external dependents.

### onDiagnosticImage (callback)

| Acceptor | File | Line |
|----------|------|------|
| `ExtractionPipeline.extract()` | `extraction_pipeline.dart:220` | Top-level entry, passes down |
| `ExtractionPipeline._runExtractionStages()` | `extraction_pipeline.dart:371` | Passes to stages |
| `GridLineRemover.remove()` | `grid_line_remover.dart:27` | Emits mask + cleaned images |
| `TextRecognizerV2.recognize()` | `text_recognizer_v2.dart:72` | Emits OCR diagnostic images |
| `TextRecognizerV2._recognizeWithCellCrops()` | `text_recognizer_v2.dart:256` | Emits cell crop images |

---

## 4. Test Files Impacted

| Test File | What it tests |
|-----------|---------------|
| `test/features/pdf/extraction/stages/stage_2b_page_renderer_test.dart` | `PageRendererV2`, `RenderedPage` |
| `test/features/pdf/extraction/stages/stage_2b_image_preprocessor_test.dart` | `ImagePreprocessorV2`, `PreprocessedPage` |
| `test/features/pdf/extraction/stages/grid_line_remover_test.dart` | `GridLineRemover` |
| `test/features/pdf/extraction/stages/stage_2b_text_recognizer_test.dart` | `TextRecognizerV2` (uses `PreprocessedPage`, `RenderedPage`) |
| `test/features/pdf/extraction/stages/stage_2b_grid_line_detector_test.dart` | `GridLineDetector` (uses `PreprocessedPage`) |
| `test/features/pdf/extraction/stages/luminance_diagnostic_test.dart` | Luminance analysis |
| `test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart` | Full pipeline integration |
| `test/features/pdf/extraction/pipeline/re_extraction_loop_test.dart` | Re-extraction loop |
| `test/features/pdf/extraction/helpers/mock_stages.dart` | Mock implementations |

---

## 5. Migration Impact Summary

### DIRECT CHANGES (must modify)

| File | Change Required | Risk |
|------|----------------|------|
| `pubspec.yaml` | Replace `pdfx: ^2.9.2` with `pdfrx: <version>` | LOW - dependency swap |
| `page_renderer_v2.dart` | Replace `import 'package:pdfx/pdfx.dart'` with pdfrx import; rewrite `_renderWithPdfx()` method | **HIGH** - core rendering API changes |

### INTERFACE-STABLE (no changes needed IF RenderedPage contract is preserved)

| File | Why it's safe |
|------|---------------|
| `image_preprocessor_v2.dart` | Consumes `RenderedPage.imageBytes` / `imageSizePixels` -- unchanged contract |
| `grid_line_detector.dart` | Consumes `PreprocessedPage.enhancedImageBytes` -- downstream of preprocessor |
| `grid_line_remover.dart` | Consumes `PreprocessedPage.enhancedImageBytes` -- downstream of preprocessor |
| `text_recognizer_v2.dart` | Consumes both `PreprocessedPage` and `RenderedPage` -- unchanged contracts |
| `extraction_pipeline.dart` | Orchestrates stages -- no direct pdfx dependency |
| `ocr_text_extractor.dart` | Lightweight pipeline -- delegates to same stages |
| `mp_extraction_service.dart` | MP extraction -- delegates to `OcrTextExtractor` |
| `pdf_import_service.dart` | Entry point -- delegates to `ExtractionPipeline` |

### KEY CONSTRAINT

**The `RenderedPage` class is the firewall.** As long as `_renderWithPdfx()` continues to return `RenderedPage(imageBytes: Uint8List, imageSizePixels: Size, dpi: int, pageIndex: int)`, ALL downstream stages are unaffected. The migration is entirely contained within `PageRendererV2._renderWithPdfx()`.

### pdfx API Surface Used

From `_renderWithPdfx()` (lines 243-303):

```dart
// APIs that must be mapped to pdfrx equivalents:
pdfx.PdfDocument.openData(pdfBytes)         // Open PDF from bytes
pdfDoc.getPage(pageIndex + 1)               // Get page (1-based index)
page.width / page.height                    // Page dimensions
page.render(                                // Render to image
  width: targetWidth,
  height: targetHeight,
  format: pdfx.PdfPageImageFormat.png,
  quality: 100,
  backgroundColor: '#FFFFFF',
)
pageImage.bytes                             // Get PNG bytes
pageImage.width / pageImage.height          // Rendered dimensions
// Cleanup:
page.close()                                // Close page
pdfDoc.close()                              // Close document
```

### Printing.raster() (Windows Primary Path)

`_renderWithPrinting()` (lines 194-240) uses `Printing.raster()` which is the PRIMARY renderer on Windows. pdfx is the FALLBACK. After migration to pdfrx, the fallback path changes but the primary Windows path (`Printing.raster`) is untouched.

---

## 6. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| pdfrx API incompatibility | MEDIUM | pdfrx has different API surface; must verify `PdfDocument.openData`, page rendering, and PNG export equivalents |
| Image quality regression | **HIGH** | pdfrx uses PDFium (bundled native library) which may produce different pixel output than pdfx; golden test fixtures may need regeneration |
| Platform-specific behavior | MEDIUM | pdfx had platform-specific rendering paths; pdfrx bundles its own PDFium, which should be MORE consistent cross-platform |
| Test breakage | LOW | Tests mock `PageRendererV2` -- only `stage_2b_page_renderer_test.dart` directly tests the renderer |
| Memory/performance regression | LOW | pdfrx is generally more efficient than pdfx; monitor memory during large document extraction |

---

## 7. Import Graph (who imports the key files)

### `page_renderer_v2.dart` (defines `RenderedPage` + `PageRendererV2`)

Imported by:
- `services/extraction/stages/image_preprocessor_v2.dart` (relative: `import 'page_renderer_v2.dart';`)
- `services/extraction/stages/text_recognizer_v2.dart` (relative: `import 'page_renderer_v2.dart';`)
- `services/extraction/pipeline/ocr_text_extractor.dart` (absolute package import)
- `services/mp/mp_extraction_service.dart` (absolute package import)

NOT imported by: `extraction_pipeline.dart` (imports via barrel `stages/stages.dart`)

### `image_preprocessor_v2.dart` (defines `PreprocessedPage` + `ImagePreprocessorV2`)

Imported by:
- `services/extraction/stages/grid_line_detector.dart` (relative: `import 'image_preprocessor_v2.dart';`)
- `services/extraction/stages/grid_line_remover.dart` (relative: `import 'image_preprocessor_v2.dart';`)
- `services/extraction/stages/text_recognizer_v2.dart` (relative: `import 'image_preprocessor_v2.dart';`)
- `services/extraction/pipeline/ocr_text_extractor.dart` (absolute package import)
- `services/mp/mp_extraction_service.dart` (absolute package import)

### `grid_line_remover.dart` (defines `GridLineRemover`)

Imported via barrel `stages/stages.dart` by `extraction_pipeline.dart` only.

---

## 8. Recommended Migration Steps

1. Add `pdfrx` to `pubspec.yaml`, remove `pdfx`
2. Update `page_renderer_v2.dart` import from `package:pdfx/pdfx.dart` to pdfrx equivalent
3. Rewrite `_renderWithPdfx()` to use pdfrx API (the ONLY method using pdfx)
4. Verify `RenderedPage` output contract unchanged (imageBytes, imageSizePixels, dpi, pageIndex)
5. Run `stage_2b_page_renderer_test.dart` to validate rendering
6. Run full pipeline golden tests to check for image quality regression
7. If golden fixtures change, regenerate via `generate_golden_fixtures_test.dart`
