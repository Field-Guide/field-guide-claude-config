# Migration: Replace pdfx with pdfrx for Unified PDF Rendering

**Date**: 2026-03-07 | **Updated**: 2026-03-08
**Priority**: HIGH — root cause of Android OCR accuracy regression ($457K checksum discrepancy)
**Effort**: Medium (3 production files, 1 data class update, 1 pipeline fix, config changes, fixture regeneration)
**Reviewed**: Two-round adversarial review completed (code-review-agent + blast-radius audit + 3-agent performance analysis). All findings addressed below.

## Problem

The app uses **two different PDF rendering engines** depending on platform:
- **Windows**: `Printing.raster()` → bundled PDFium (upstream)
- **Android**: `pdfx` → `android.graphics.pdf.PdfRenderer` (AOSP-forked PDFium, version-locked to OS)
- **iOS**: `pdfx` → CoreGraphics/Quartz 2D (Apple's proprietary renderer)

This causes **OCR result divergence**: Windows fixtures (generated with upstream PDFium) don't match Android device output (generated with Android's old PDFium fork). The pixel-level rendering differences propagate through the OCR pipeline, causing character misrecognition, merged items, and a $457K financial discrepancy on the Springfield test PDF.

## Solution

Replace `pdfx` with `pdfrx` in the rendering pipeline. `pdfrx` **bundles upstream PDFium 144.0.7520.0 on all platforms** (Android, iOS, Windows, macOS, Linux), using the same FreeType-based rasterization engine everywhere.

Additionally, eliminate the wasteful PNG encode/decode roundtrip by passing **raw BGRA pixel data** directly from the renderer to the preprocessor, saving 7-14 seconds per extraction.

**Key design decisions** (from adversarial review):
- Diagnostic image callbacks receive PNG-encoded data (BGRA→PNG conversion in renderer before calling `onDiagnosticImage`)
- Preprocessor fallback paths encode BGRA→PNG before passing to downstream stages
- No runtime feature flag — git-level rollback is sufficient
- Pipeline performance optimizations deferred to a **separate plan** (see Related Plans)

## Root Cause Evidence

- DPI fix (prior plan) confirmed DPI is set correctly (dpi=600 for crops via `setVariable`)
- `recognizeImage()` is never called for grid-based PDFs — all OCR goes through `recognizeCrop()`
- Stage dump comparison: identical crop dimensions (822 cells, 2x upscale, avg 784x208 OCR size) but 4 fewer elements on Android (1238 vs 1242)
- Element-level comparison: items 94+95 merged, item 91 qty "50"→"S50", item 96 amount "$177,135"→"$0", item 97 "5EL"→"SEL"
- These are classic font-rendering-induced OCR errors from different anti-aliasing between AOSP PdfRenderer and upstream PDFium

## Research Findings (Verified)

### pdfrx API (from pub.dev docs + source)

| API | Signature | Notes |
|-----|-----------|-------|
| Open PDF | `PdfDocument.openData(Uint8List data)` → `Future<PdfDocument>` | Async |
| Access pages | `document.pages[index]` → `PdfPage` | **0-based** (pdfx was 1-based) |
| Page dimensions | `page.width`, `page.height` → `double` | PDF points (72 DPI) |
| Render | `page.render(fullWidth:, fullHeight:, backgroundColor:)` → `Future<PdfImage?>` | Returns raw pixels |
| Pixel data | `pdfImage.pixels` → `Uint8List` | **BGRA8888 format** (not RGBA!) |
| Pixel dimensions | `pdfImage.width`, `pdfImage.height` → `int` | Rendered pixel size |
| Dispose image | `pdfImage.dispose()` | **Required** — no NativeFinalizer, native malloc leaks without this |
| Dispose document | `document.dispose()` → `Future<void>` | Async dispose |
| Version | `pdfrx: ^2.2.24` (latest) | Bundles PDFium 144.0.7520.0 |

### Thread Safety (SAFE)

pdfrx serializes **all** PDFium FFI calls through a single background worker isolate (since v1.0.58). No concurrent PDFium access is possible. Safe to call `render()` from any isolate — requests are queued sequentially. No mutex needed on our side.

### Cross-Platform Rendering Consistency (STRONG)

- All platforms use PDFium 144.0.7520.0 from `bblanchon/pdfium-binaries`
- All platforms use bundled FreeType for rasterization (AGG backend)
- No platform-specific rendering flags in the build
- **One risk**: Non-embedded fonts use platform-specific font discovery. For embedded-font PDFs (which construction bid schedules should be), rendering is pixel-identical.

### Binary Size Impact

- PDFium arm64 `.so`: ~3.1MB compressed, ~7-9MB uncompressed
- Net APK download increase: **~3-4MB** (Android only — pdfx used native PdfRenderer, not bundled PDFium)
- Windows: near-zero change (pdfx already bundled PDFium on Windows)

### Pixel Format: BGRA8888

pdfrx returns pixels in **BGRA8888** format (Blue-Green-Red-Alpha). The `image` package supports this via `Image.fromBytes(order: ChannelOrder.bgra)`. Channel swap cost: ~30-60ms per page (trivial). **Grayscale conversion will produce wrong luminance values if BGRA is treated as RGBA** (asymmetric weights: 0.299*R vs 0.114*B).

## Blast Radius Analysis

### Files That MUST Change

| File | Change | Scope |
|------|--------|-------|
| `pubspec.yaml` | Add `pdfrx: ^2.2.24`, remove `pdfx: ^2.9.2` | 2 lines |
| `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart` | Rewrite rendering, add raw BGRA output path, update RenderedPage class, add diagnostic PNG encoding helper | ~130 lines |
| `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart` | Handle BGRA raw bytes in happy path + encode BGRA→PNG in fallback paths | ~25 lines |
| `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart` | Update `onDiagnosticImage` callback to handle BGRA format from RenderedPage | ~5 lines |
| `integration_test/printing_diagnostic_test.dart` | Rewrite as pdfrx diagnostic or delete | Entire file |
| `integration_test/rendering_diagnostic_test.dart` | Update to handle BGRA format in diagnostic output | ~10 lines |
| `test/features/pdf/extraction/golden/springfield_benchmark_test.dart` | Remove `net.nfet.printing` mock channel handler | Lines 83-91 |

### Files That Will NOT Change

All pipeline stages downstream of preprocessing are insulated:
- `grid_line_detector.dart`, `grid_line_remover.dart`, `text_recognizer_v2.dart`
- `element_validator.dart`, `row_classifier.dart`, `column_detector.dart`, etc.
- `post_processor_v2.dart`, `quality_validator.dart`
- `ocr_text_extractor.dart`, `pdf_import_service.dart`
- `tesseract_engine_v2.dart` — DPI fix stays as defensive code

### Files That Need Re-Running (Not Code Changes)

| File | Action |
|------|--------|
| `integration_test/generate_golden_fixtures_test.dart` | Regenerate all fixtures |
| `tool/generate_springfield_fixtures.dart` | Re-run (verify it still works — may need Flutter bindings for pdfrx FFI) |
| All `test/features/pdf/extraction/fixtures/springfield_*.json` | Will be regenerated |

### CRITICAL: `printing` Package Must Stay

The `printing` package is used for `Printing.layoutPdf()`, `Printing.sharePdf()`, and `PdfPreview` widget in 4 files:
- `lib/features/pdf/services/pdf_service.dart`
- `lib/features/forms/data/services/form_pdf_service.dart`
- `lib/features/forms/presentation/screens/form_viewer_screen.dart`
- `lib/features/forms/presentation/screens/mdot_hub_screen.dart`

Only remove its import from `page_renderer_v2.dart`.

### `PdfDocument` Namespace Collision

Both `syncfusion_flutter_pdf` and `pdfrx` export `PdfDocument`. Import pdfrx with alias: `import 'package:pdfrx/pdfrx.dart' as pdfrx;`

### `pubspec.lock` Changes

Adding pdfrx and removing pdfx will significantly change `pubspec.lock`. Commit lock file changes in a dedicated, easily-identifiable commit to minimize merge conflict risk on the active branch.

## RenderedPage Contract Change

### Current (PNG-only)
```dart
class RenderedPage {
  final Uint8List imageBytes;      // PNG-encoded
  final Size imageSizePixels;
  final int dpi;
  final int pageIndex;
}
```

### New (format-aware)
```dart
enum RenderedImageFormat { png, bgraRaw }

class RenderedPage {
  final Uint8List imageBytes;       // PNG or raw BGRA pixels
  final Size imageSizePixels;
  final int dpi;
  final int pageIndex;
  final RenderedImageFormat format; // NEW — indicates byte format
}
```

### Preprocessor Change (happy path)
```dart
// In image_preprocessor_v2.dart _preprocessIsolate():
img.Image? image;
if (params.format == RenderedImageFormat.bgraRaw) {
  image = img.Image.fromBytes(
    width: params.pageSize.width.toInt(),
    height: params.pageSize.height.toInt(),
    bytes: params.imageBytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );
} else {
  image = img.decodeImage(params.imageBytes);
}
```

### Preprocessor Change (fallback paths)
```dart
// In both catch block (~line 127) and _createFallbackPage (~line 258):
Uint8List fallbackBytes = renderedPage.imageBytes;
if (renderedPage.format == RenderedImageFormat.bgraRaw) {
  final image = img.Image.fromBytes(
    width: renderedPage.imageSizePixels.width.toInt(),
    height: renderedPage.imageSizePixels.height.toInt(),
    bytes: renderedPage.imageBytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );
  fallbackBytes = Uint8List.fromList(img.encodePng(image));
}
// Use fallbackBytes in PreprocessedPage.enhancedImageBytes
```

### Diagnostic Image Callback Handling
```dart
// In extraction_pipeline.dart where onDiagnosticImage is called with rendered pages:
// Convert BGRA to PNG before passing to diagnostic callback
if (entry.value.format == RenderedImageFormat.bgraRaw) {
  final image = img.Image.fromBytes(
    width: entry.value.imageSizePixels.width.toInt(),
    height: entry.value.imageSizePixels.height.toInt(),
    bytes: entry.value.imageBytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );
  onDiagnosticImage?.call(
    'page_${entry.key}_rendered',
    Uint8List.fromList(img.encodePng(image)),
  );
} else {
  onDiagnosticImage?.call(
    'page_${entry.key}_rendered',
    entry.value.imageBytes,
  );
}
```

## Risk Assessment (Updated from Adversarial Review)

| Risk | Level | Mitigation |
|------|-------|------------|
| Page indexing off-by-one (pdfx 1-based → pdfrx 0-based) | HIGH | Verified: pdfrx uses `document.pages[index]` (0-based). Explicit test. |
| BGRA pixel format treated as RGBA | HIGH | Use `Image.fromBytes(order: ChannelOrder.bgra)`. Research confirmed asymmetric grayscale weights. |
| `page.render()` returns null (force-unwrap crash) | HIGH | Guard with `if (pdfImage == null) return null;` before accessing `.pixels`. Do NOT force-unwrap. |
| BGRA buffer size mismatch after internal rounding | HIGH | Assert `pixels.length == w * h * 4` after render. Prevents silent `Image.fromBytes` corruption. |
| `PdfImage.dispose()` not called → native memory leak | HIGH | Always dispose in finally block. No NativeFinalizer — must be explicit. |
| `Uint8List.fromList()` copy semantics undocumented | HIGH | Always copy before dispose. Add inline comment: `// MUST copy — dispose() frees native buffer`. |
| `onDiagnosticImage` receives BGRA instead of PNG | HIGH | Encode BGRA→PNG in renderer/pipeline before calling diagnostic callbacks. |
| Preprocessor fallback passes raw BGRA to downstream | HIGH | Encode BGRA→PNG in both fallback paths (catch block + `_createFallbackPage`). |
| `printing` accidentally removed from pubspec | HIGH | Explicit verification step. Used by 4 other files. |
| Memory: raw BGRA ~33MB/page, 6 pages = ~200MB | MEDIUM | Monitor on device. Pages processed sequentially (verified). Can optimize in perf plan if OOM occurs. |
| PdfDocument namespace collision (syncfusion + pdfrx) | MEDIUM | Use `as pdfrx` alias import. |
| `backgroundColor: 0xFFFFFFFF` format unverified | MEDIUM | Verify ARGB int format in Phase 0.1 by reading pdfrx source. |
| ProGuard stripping pdfrx JNI/FFI methods | MEDIUM | Check pdfrx docs for required ProGuard rules in Phase 0.2. |
| iOS Podfile changes for pdfrx | MEDIUM | Run `pod install` after pubspec change. Verify in Phase 0.2. |
| `tool/generate_springfield_fixtures.dart` may not run standalone | MEDIUM | Verify it works with pdfrx FFI. May need to become an integration test. |
| Non-embedded fonts render differently per platform | LOW | Construction bid schedules embed fonts. Verify with `pdffonts` if issues arise. |
| PDFium thread safety | RESOLVED | pdfrx serializes all FFI calls through single worker isolate (v1.0.58+). |
| APK size increase | LOW | ~3-4MB compressed on Android (not the 10-15MB originally estimated). |
| Isolate `compute()` with raw BGRA bytes (~33MB copy) | MEDIUM | Larger than PNG copy but still sub-100ms. Addressed in separate perf plan. |

## Rollback Plan

If pdfrx validation fails at any phase:
1. Revert `pubspec.yaml` (restore pdfx, remove pdfrx)
2. Revert `page_renderer_v2.dart`
3. Revert `image_preprocessor_v2.dart`
4. Revert `extraction_pipeline.dart` diagnostic callback changes
5. Run `flutter pub get` + `flutter clean`
6. No downstream files need reverting (RenderedPage format field is additive)

---

## Implementation Phases

### Phase 0: API Verification + Baseline Performance

**Goal**: Install pdfrx, verify API and native build compatibility, capture pre-migration timing baseline.

#### Step 0.1: Install pdfrx alongside pdfx
- Add `pdfrx: ^2.2.24` to `pubspec.yaml` (keep `pdfx` for now)
- Run `pwsh -Command "flutter pub get"`
- Read actual pdfrx source at `~/.pub-cache/hosted/pub.dev/pdfrx-*/` to verify:
  - `PdfDocument.openData()` signature
  - `page.render()` parameters — specifically `backgroundColor` type (confirm it accepts `int` in ARGB format, confirm `0xFFFFFFFF` = opaque white)
  - `PdfImage.pixels` format (confirm BGRA8888)
  - `PdfImage.dispose()` existence and behavior
  - `document.dispose()` signature

#### Step 0.2: Verify builds on all targets
- Run `pwsh -Command "flutter analyze"` — confirm no import conflicts
- Run `pwsh -Command "flutter build apk --debug"` — confirm Android builds
- Measure APK size before and after (note the delta, expect ~3-4MB)
- Check pdfrx documentation for required **ProGuard rules** — add to `android/app/proguard-rules.pro` if needed
- Run `pwsh -Command "flutter build apk --release"` — verify release build with ProGuard doesn't strip pdfrx
- For iOS: run `cd ios && pod install` to ensure pdfrx CocoaPod resolves cleanly

#### Step 0.3: Capture pre-migration performance baseline
- Import Springfield PDF on device with CURRENT renderer
- Query `stage_metrics` SQLite table for per-stage elapsed times
- Record: rendering time, preprocessing time, OCR time, total pipeline time
- This becomes the baseline for post-migration comparison

#### Step 0.4: Cross-platform rendering baseline
- Write a minimal test that renders Springfield page 4 with pdfrx on Windows
- Compare pixel output with current Printing.raster output (same page, same DPI)
- If significantly different: investigate PDFium version mismatch before proceeding
- If identical or near-identical: proceed (this validates the core premise)

### Phase 1: Update RenderedPage Contract

**Goal**: Add format-awareness to RenderedPage and update preprocessor without breaking anything.

#### Step 1.1: Add `RenderedImageFormat` enum and `format` field to `RenderedPage`
- File: `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart`
- Add `enum RenderedImageFormat { png, bgraRaw }` above `RenderedPage`
- Add `final RenderedImageFormat format;` field with default `RenderedImageFormat.png`
- Add to constructor: `this.format = RenderedImageFormat.png`
- This is backward-compatible — existing code that creates RenderedPage without `format` gets `png` default

#### Step 1.2: Update `ImagePreprocessorV2` to handle both formats (happy path + fallback paths)
- File: `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart`
- Update `_PreprocessParams` to include `format` field
- In `_preprocessIsolate()` **happy path**: if `format == bgraRaw`, use `Image.fromBytes(order: ChannelOrder.bgra)`; else use `img.decodeImage()` as before
- In `_preprocessIsolate()` **catch block** (~line 127-141): if `renderedPage.format == bgraRaw`, encode BGRA→PNG before storing in `PreprocessedPage.enhancedImageBytes`
- In `_createFallbackPage()` (~line 258-272): same BGRA→PNG encoding before storing in fallback `PreprocessedPage`
- Verify `import 'package:image/image.dart' as img;` is already present (it is at line 5)

#### Step 1.3: Update diagnostic image callback in `ExtractionPipeline`
- File: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`
- At ~line 439-442 where `onDiagnosticImage` is called with `entry.value.imageBytes`:
  - Check `entry.value.format` — if `bgraRaw`, convert to PNG before passing to callback
  - This ensures all diagnostic consumers (tests, file dumps) receive valid PNG data

#### Step 1.4: Verify all tests still pass
- Run `pwsh -Command "flutter test"` — all tests should pass (format defaults to png)
- Run `pwsh -Command "flutter analyze"` — clean

### Phase 2: Rewrite PageRendererV2

**Goal**: Replace pdfx/Printing.raster rendering with pdfrx. This is the core change.

#### Step 2.1: Rewrite imports
- Remove: `import 'package:pdfx/pdfx.dart' as pdfx;`
- Remove: `import 'package:printing/printing.dart';`
- Remove: `import 'package:flutter/services.dart';` (BackgroundIsolateBinaryMessenger was for pdfx isolates)
- Add: `import 'package:pdfrx/pdfrx.dart' as pdfrx;` (**use alias to avoid PdfDocument collision with syncfusion**)
- Verify: `import 'dart:async';` — check if still needed by remaining code; remove if only used by Completer
- Verify: `import 'dart:io';` — check if still needed; remove if only used for `Platform.isWindows`
- Do NOT add `import 'package:image/image.dart' as img;` to the renderer — the preprocessor handles BGRA→Image conversion

#### Step 2.2: Open document once, iterate pages
- Restructure `render()` to open `pdfrx.PdfDocument` once before the page loop
- Pass the document into `_renderWithPdfrx()` instead of `pdfBytes`
- Close document in a `finally` block after all pages are rendered
- This fixes the per-page document open/close bottleneck (0.5-5s savings)

#### Step 2.3: Rewrite `_renderSinglePage()` (lines 158-185)
- Remove the `if (Platform.isWindows)` branch entirely
- Remove the `_renderWithPrinting()` call and fallback logic
- Replace with a single `_renderWithPdfrx()` call for ALL platforms
- No `useIsolate` parameter needed (pdfrx handles threading internally via BackgroundWorker)

#### Step 2.4: Delete `_renderWithPrinting()` method (lines 187-239)
- Delete the entire method (~51 lines)
- This eliminates: `Printing.raster()`, `runZonedGuarded`, `Completer`, `PdfRaster`

#### Step 2.5: Rewrite `_renderWithPdfx()` → `_renderWithPdfrx()` (lines 243-303)
- Rename method to `_renderWithPdfrx()`
- Accept `pdfrx.PdfDocument doc` parameter instead of `Uint8List pdfBytes`
- Remove `useIsolate` parameter and `BackgroundIsolateBinaryMessenger` setup
- Access page: `final page = doc.pages[pageIndex];` (0-based, was 1-based with pdfx)
- Get dimensions: `page.width`, `page.height` (doubles, PDF points)
- Compute target size: `fullWidth = page.width * (dpi / 72.0)`, `fullHeight = page.height * (dpi / 72.0)`
- Render: `final pdfImage = await page.render(fullWidth: fullWidth, fullHeight: fullHeight, backgroundColor: 0xFFFFFFFF);`
- **Null guard**: `if (pdfImage == null) return null;` — do NOT force-unwrap
- Extract pixels: `final pixels = Uint8List.fromList(pdfImage.pixels);` — add comment: `// MUST copy — dispose() frees native buffer`
- Get dimensions: `final w = pdfImage.width; final h = pdfImage.height;`
- **Buffer integrity assertion**: `assert(pixels.length == w * h * 4, 'BGRA buffer size mismatch: expected ${w * h * 4}, got ${pixels.length}');`
- **Dispose PdfImage immediately**: `pdfImage.dispose();` in finally block (required — no NativeFinalizer)
- Construct RenderedPage with raw BGRA:
  ```dart
  return RenderedPage(
    imageBytes: pixels,
    imageSizePixels: Size(w.toDouble(), h.toDouble()),
    dpi: dpi,
    pageIndex: pageIndex,
    format: RenderedImageFormat.bgraRaw,
  );
  ```
- Wrap in try/finally to ensure `pdfImage?.dispose()` is always called
- Note: document disposal happens in the caller (`render()` method), not here

#### Step 2.6: Update class docstring
- Remove platform-specific rendering docs
- Document: "Uses pdfrx (PDFium 144.0.7520.0) on all platforms for consistent cross-platform rendering"
- Document: "Returns raw BGRA8888 pixel data (not PNG) for performance — preprocessor handles format detection"

#### Step 2.7: Build and analyze
- Run `pwsh -Command "flutter clean"` — clear stale compiled artifacts from pdfx
- Run `pwsh -Command "flutter pub get"`
- Run `pwsh -Command "flutter analyze"` — fix any errors
- Run `pwsh -Command "flutter build apk --debug"` — verify APK builds

### Phase 3: Remove pdfx Dependency

**Goal**: Clean removal of pdfx from the project.

#### Step 3.1: Remove pdfx from pubspec.yaml
- Remove `pdfx: ^2.9.2` from dependencies
- Run `pwsh -Command "flutter pub get"` — verify clean resolution
- **Verify `printing` is still present in pubspec.yaml** (used by pdf_service, form_pdf_service, mdot_hub_screen, form_viewer_screen)

#### Step 3.2: Commit pubspec.lock separately
- `pubspec.lock` changes from adding pdfrx + removing pdfx should be committed as a separate, easily-identifiable commit to minimize merge conflict risk

#### Step 3.3: Verify no remaining pdfx references in Dart code
- Search codebase for `package:pdfx` — should find zero results
- Search for `PdfPageImageFormat`, `PdfPageImage` (pdfx types) — should find zero results
- Run `pwsh -Command "flutter analyze"` — confirm clean

#### Step 3.4: Clean auto-generated plugin files
- Run `pwsh -Command "flutter clean"` then `pwsh -Command "flutter pub get"`
- Verify `windows/flutter/generated_plugin_registrant.cc` no longer references pdfx
- Verify `windows/flutter/generated_plugins.cmake` no longer lists pdfx

### Phase 4: Update Tests

**Goal**: Fix tests affected by the migration.

#### Step 4.1: Rewrite `printing_diagnostic_test.dart`
- File: `integration_test/printing_diagnostic_test.dart`
- Rewrite as `pdfrx_rendering_diagnostic_test.dart`:
  - Remove pdfx and printing imports
  - Use pdfrx API to render Springfield page 4
  - Verify: non-null PdfImage, dimensions match expected, pixel data non-empty
  - Compare rendering time vs baseline from Phase 0.3

#### Step 4.2: Update `rendering_diagnostic_test.dart`
- File: `integration_test/rendering_diagnostic_test.dart`
- This test writes `entry.value.imageBytes` to disk as PNG files (line 78)
- After migration, `imageBytes` will be raw BGRA — files would be corrupted
- Update to check `entry.value.format` and encode BGRA→PNG before writing to disk
- Also update `img.decodeImage()` calls to handle BGRA format (line 136)

#### Step 4.3: Update `springfield_benchmark_test.dart`
- File: `test/features/pdf/extraction/golden/springfield_benchmark_test.dart`
- Remove the `setMockMethodCallHandler` for `net.nfet.printing` channel (lines 83-91)
- This mock forced the old Windows path to fall through to pdfx; no longer relevant

#### Step 4.4: Update MockPageRendererV2 if needed
- File: `test/features/pdf/extraction/helpers/mock_stages.dart`
- The mock creates `RenderedPage` with PNG bytes — this still works (format defaults to `png`)
- Verify mock compiles with the new `format` field (it should — default value)

#### Step 4.5: Verify `tool/generate_springfield_fixtures.dart`
- This is a standalone Dart script that imports `ExtractionPipeline` which uses `PageRendererV2`
- pdfrx requires Flutter bindings and native FFI — verify it runs with `flutter run`
- If it fails standalone: convert to an integration test or add Flutter binding initialization

#### Step 4.6: Run full test suite
- Run `pwsh -Command "flutter test"` — all should pass
- Run `pwsh -Command "flutter analyze"` — clean

### Phase 5: Regenerate Golden Fixtures + Device Validation

**Goal**: Regenerate fixtures and validate cross-platform parity.

#### Step 5.1: Capture pre-regeneration rendering baseline on Windows
- Run `integration_test/rendering_diagnostic_test.dart` — captures pdfrx rendering output on Windows
- Compare pixel output with Phase 0.4 baseline (should be identical — same PDFium on Windows)

#### Step 5.2: Regenerate all golden fixtures
- Run `integration_test/generate_golden_fixtures_test.dart` on Windows
- Also run `tool/generate_springfield_fixtures.dart` (also uses PageRendererV2)
- This regenerates ALL `test/features/pdf/extraction/fixtures/springfield_*.json` files

#### Step 5.3: Run stage trace + golden tests
- Run `pwsh -Command "flutter test test/features/pdf/extraction/golden/stage_trace_diagnostic_test.dart"` — expect 36/36 pass
- Run `pwsh -Command "flutter test test/features/pdf/extraction/golden/springfield_golden_test.dart"` — expect 131 items, $0 delta, quality >= 0.99

#### Step 5.4: Deploy to Android device and validate
- Build: `pwsh -Command "flutter build apk --debug"`
- Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
- Import Springfield PDF on device
- Pull stage dumps, run `python tools/compare_stage_dumps.py`
- **Expected**: 1242 elements, 131 items, $0 delta, page 4 confidence >= 0.960
- **This is the KEY validation** — if Android matches Windows, the migration succeeded
- Monitor device memory usage during extraction — watch for OOM with raw BGRA buffers

#### Step 5.5: Performance comparison
- Query `stage_metrics` SQLite table on device after extraction
- Compare per-stage timing with Phase 0.3 baseline:
  - Rendering stage: expect faster (no PNG encoding overhead + document opened once)
  - Preprocessing stage: expect faster (no PNG decoding overhead)
  - OCR stage: expect similar (Tesseract processing unchanged)
  - Total pipeline: expect 7-14s improvement

#### Step 5.6: iOS validation (if device available)
- Run `cd ios && pod install` to pick up pdfrx CocoaPod
- Deploy to iOS device
- Import Springfield PDF
- Compare results with Windows fixtures
- Verify font rendering matches (PDFium on iOS uses same FreeType as Android/Windows)

### Phase 6: Cleanup + Documentation

**Goal**: Remove temporary artifacts and update documentation.

#### Step 6.1: Remove DPI fix debug artifacts
- The `setVariable('user_defined_dpi', ...)` calls in `tesseract_engine_v2.dart` STAY (defensive, correct)
- Remove any remaining debug prints if present

#### Step 6.2: Keep comparison tools for now
- **Do NOT delete** `tools/compare_golden.py` and `tools/compare_stage_dumps.py` yet
- These may be needed if post-migration issues are discovered later
- Delete only after the migration is fully validated in production
- Delete `Troubleshooting/device_stage_dumps/` if it exists after Phase 5.4
- Check `pdf_import_service.dart` for any `BEGIN TEMPORARY` / `END TEMPORARY` markers — remove if present (may not exist)

#### Step 6.3: Update documentation and references
- Update `page_renderer_v2.dart` class docstring
- Update `.claude/rules/architecture.md`: replace `pdfx` with `pdfrx` in Key Packages table
- Update `tools/dump_inspect.py`: replace `pdfx` with `pdfrx` in plugin name list (line 32)
- Update `.claude/plans/2026-03-07-ocr-dpi-fix.md` with note that DPI was not the root cause; renderer divergence was

#### Step 6.4: Final verification
- Run `pwsh -Command "flutter analyze"` — 0 issues
- Run `pwsh -Command "flutter test"` — all pass
- Run `pwsh -Command "flutter build apk --debug"` — builds clean
- Run `pwsh -Command "flutter build apk --release"` — verify release builds with ProGuard
- Search for any remaining `pdfx` references — should be zero
- Verify `printing` package still in pubspec.yaml

## Files Modified (Complete List)

| File | Change Type |
|------|------------|
| `pubspec.yaml` | Add pdfrx, remove pdfx |
| `pubspec.lock` | Updated dependencies (separate commit) |
| `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart` | Rewrite rendering + update RenderedPage class + diagnostic PNG helper (~130 lines) |
| `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart` | Handle BGRA format in happy path + fallback paths (~25 lines) |
| `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart` | Update diagnostic image callback for BGRA format (~5 lines) |
| `integration_test/printing_diagnostic_test.dart` | Rewrite as pdfrx diagnostic |
| `integration_test/rendering_diagnostic_test.dart` | Update for BGRA format handling |
| `test/features/pdf/extraction/golden/springfield_benchmark_test.dart` | Remove printing channel mock |
| `test/features/pdf/extraction/fixtures/springfield_*.json` (all) | Regenerate via golden test |
| `.claude/rules/architecture.md` | Update pdfx → pdfrx reference |
| `tools/dump_inspect.py` | Update pdfx → pdfrx reference |
| `android/app/proguard-rules.pro` | Add pdfrx ProGuard rules (if needed) |

## Files NOT Modified

- `printing` package — stays in pubspec.yaml (used by 4 other files)
- All pipeline stages downstream of preprocessing (insulated by fallback PNG encoding)
- All test mocks (MockPageRendererV2 — format defaults to png)
- All presentation layer code
- `tesseract_engine_v2.dart` — DPI fix stays as defensive code
- `flusseract` package — no changes
- `ocr_text_extractor.dart` — no pdfx imports
- `tools/compare_golden.py`, `tools/compare_stage_dumps.py` — kept until post-production validation

## Validation Criteria

- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — all pass
- [ ] Stage trace test: 36/36 pass
- [ ] Springfield golden test: 131 items, $0 delta, quality >= 0.99
- [ ] Android device: 1242 elements, 131 items, $0 checksum discrepancy
- [ ] Android device: page 4 confidence >= 0.960
- [ ] No `pdfx` references remain in codebase
- [ ] `printing` package still present (used for preview/share)
- [ ] APK size increase documented (~3-4MB from bundled PDFium on Android)
- [ ] Release APK builds with ProGuard (pdfrx native library not stripped)
- [ ] Per-stage timing compared with pre-migration baseline
- [ ] PdfImage.dispose() called in all code paths (no native memory leaks)
- [ ] Buffer integrity assertion passes: `pixels.length == w * h * 4`
- [ ] Diagnostic image callbacks produce valid PNG files
- [ ] Preprocessor fallback paths produce valid PNG bytes for downstream stages
- [ ] Device memory usage during extraction does not cause OOM

