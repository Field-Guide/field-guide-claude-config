# pdfrx Parity + Grid Line Threshold Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** All 3 devices (S21+, S25 Ultra, Windows) produce identical extraction results on the Springfield PDF.
**Spec:** `.claude/specs/2026-03-09-pdfrx-parity-spec.md`
**Analysis:** `.claude/dependency_graphs/2026-03-09-pdfrx-parity/`

**Architecture:** Replace `pdfx` (delegates to Android's native PdfRenderer, which differs across OS versions) with `pdfrx` (bundles PDFium 144.0.7520.0 on all platforms). Restore `_adaptiveC = 10.0` to fix 77% mask coverage destroying text. The preprocessor always outputs PNG, so all downstream stages are untouched.

**Tech Stack:** Flutter/Dart, pdfrx (PDFium), image package, OpenCV (grid removal), Tesseract OCR
**Blast Radius:** 5 direct files, 1 test file modified, 2 test files created, 18+ fixture files regenerated

**CRITICAL**: NEVER run `flutter clean`. It is prohibited by the user. If a build issue occurs, try `flutter pub get` or targeted fixes first.

---

## Phase 0: Pre-flight Verification

**Agent**: `qa-testing-agent`

### Sub-phase 0.1: Confirm Green Test Suite

#### Step 0.1.1: Run full test suite

Run: `pwsh -Command "flutter test"`
Expected: 906+ tests pass, 0 failures

If any tests fail, STOP and report. Do not proceed with a broken baseline.

---

## Phase 1: Contract Update — RenderedImageFormat + BGRA Handling

**Goal:** Add format awareness to `RenderedPage` so the preprocessor can distinguish PNG from raw BGRA pixels. All tests still pass because `format` defaults to `png`.

### Sub-phase 1.1: Add RenderedImageFormat Enum and Update RenderedPage

**Files:**
- Modify: `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart:1-30`

**Agent**: `pdf-agent`

#### Step 1.1.1: Write failing test for RenderedImageFormat enum and format field

Create test file: `test/features/pdf/extraction/stages/rendered_image_format_test.dart`

```dart
// WHY: Verifies the new format-aware contract before any production code uses it.
// This test ensures RenderedPage can carry format metadata and defaults to png.
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/pdf/services/extraction/stages/stages.dart';

void main() {
  group('RenderedImageFormat', () {
    test('enum has expected values', () {
      expect(RenderedImageFormat.values, contains(RenderedImageFormat.png));
      expect(RenderedImageFormat.values, contains(RenderedImageFormat.bgraRaw));
      expect(RenderedImageFormat.values.length, 2);
    });
  });

  group('RenderedPage format field', () {
    test('defaults to png when not specified', () {
      final page = RenderedPage(
        imageBytes: Uint8List(100),
        imageSizePixels: const Size(800, 1000),
        dpi: 300,
        pageIndex: 0,
      );
      expect(page.format, RenderedImageFormat.png);
    });

    test('can be set to bgraRaw', () {
      final page = RenderedPage(
        imageBytes: Uint8List(800 * 1000 * 4),
        imageSizePixels: const Size(800, 1000),
        dpi: 300,
        pageIndex: 0,
        format: RenderedImageFormat.bgraRaw,
      );
      expect(page.format, RenderedImageFormat.bgraRaw);
    });

    test('toString includes format', () {
      final page = RenderedPage(
        imageBytes: Uint8List(100),
        imageSizePixels: const Size(800, 1000),
        dpi: 300,
        pageIndex: 0,
        format: RenderedImageFormat.bgraRaw,
      );
      expect(page.toString(), contains('bgraRaw'));
    });
  });
}
```

#### Step 1.1.2: Verify test fails

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/rendered_image_format_test.dart"`
Expected: FAIL — `RenderedImageFormat` not found

#### Step 1.1.3: Add RenderedImageFormat enum and format field to RenderedPage

Modify `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart`.

Replace lines 13-30 (the RenderedPage class) with:

```dart
/// Image format indicator for rendered page output.
///
/// FROM SPEC: pdfrx returns raw BGRA pixels (no PNG header). The preprocessor
/// needs to know the format to decode correctly.
enum RenderedImageFormat { png, bgraRaw }

/// Rendered page data for OCR processing.
class RenderedPage {
  final Uint8List imageBytes;
  final Size imageSizePixels;
  final int dpi;
  final int pageIndex;

  /// Image format — png (default, backward-compatible) or bgraRaw (pdfrx output).
  /// FROM SPEC: BGRA handling confined to preprocessor + diagnostics only.
  final RenderedImageFormat format;

  const RenderedPage({
    required this.imageBytes,
    required this.imageSizePixels,
    required this.dpi,
    required this.pageIndex,
    this.format = RenderedImageFormat.png,
  });

  /// Convert imageBytes to PNG, handling BGRA format if needed.
  /// WHY: DRY helper — BGRA→PNG conversion needed in preprocessor fallbacks
  /// and diagnostic callbacks. Centralizing here keeps format knowledge with
  /// the enum definition.
  Uint8List toPngBytes() {
    if (format == RenderedImageFormat.png) return imageBytes;
    try {
      final w = imageSizePixels.width.toInt();
      final h = imageSizePixels.height.toInt();
      final image = img.Image.fromBytes(
        width: w,
        height: h,
        bytes: imageBytes.buffer,
        order: img.ChannelOrder.bgra,
      );
      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      debugPrint('[RenderedPage] BGRA→PNG encoding failed: $e');
      return imageBytes; // Best-effort: return raw bytes
    }
  }

  @override
  String toString() =>
      'RenderedPage(page=$pageIndex, size=${imageSizePixels.width.toInt()}x${imageSizePixels.height.toInt()}, dpi=$dpi, format=${format.name})';
}
```

**NOTE**: `toPngBytes()` requires `import 'package:image/image.dart' as img;` at the top of the file. This centralizes BGRA→PNG conversion in one place (DRY — addresses code review M-1).

**IMPORTANT**: The `format` parameter has a default value of `RenderedImageFormat.png`, so ALL existing constructors (in production code and tests) continue to work without changes.

#### Step 1.1.4: Verify test passes

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/rendered_image_format_test.dart"`
Expected: PASS

#### Step 1.1.5: Verify all existing tests still pass

Run: `pwsh -Command "flutter test"`
Expected: 906+ pass — the default `format: png` means zero breakage.

---

### Sub-phase 1.2: Update Preprocessor for BGRA Input Handling

**Files:**
- Modify: `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart:174-272`

**Agent**: `pdf-agent`

#### Step 1.2.1: Write failing test for BGRA grayscale channel-order

Create test file: `test/features/pdf/extraction/stages/bgra_channel_order_test.dart`

```dart
// WHY: FROM SPEC (adversarial review SC-2): BGRA/RGBA swap produces wrong
// luminance values. This test uses a known-color pixel to verify correct
// channel extraction: BGRA blue channel (byte 0) ≠ red channel (byte 2).
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:construction_inspector/features/pdf/services/extraction/stages/stages.dart';

void main() {
  group('BGRA channel-order parity', () {
    test('BGRA red pixel produces correct grayscale (not blue-biased)', () {
      // WHY: A pure red pixel in BGRA is [0, 0, 255, 255] (B=0, G=0, R=255, A=255).
      // If decoded as RGBA, red would be misread as blue → wrong luminance.
      // Correct luminance for pure red ≈ 54 (0.2126*255 + 0.7152*0 + 0.0722*0).
      // Wrong (blue-biased) luminance ≈ 18 (0.2126*0 + 0.7152*0 + 0.0722*255).
      const w = 2;
      const h = 2;
      final bgraBytes = Uint8List(w * h * 4);
      for (int i = 0; i < w * h; i++) {
        bgraBytes[i * 4 + 0] = 0;   // B
        bgraBytes[i * 4 + 1] = 0;   // G
        bgraBytes[i * 4 + 2] = 255; // R
        bgraBytes[i * 4 + 3] = 255; // A
      }

      // Decode as BGRA using the image package
      final image = img.Image.fromBytes(
        width: w,
        height: h,
        bytes: bgraBytes.buffer,
        order: img.ChannelOrder.bgra,
      );

      // Convert to grayscale
      final gray = img.grayscale(image);
      final pixel = gray.getPixel(0, 0);
      final luminance = pixel.r.toInt(); // grayscale → all channels equal

      // Correct red luminance: ~54 (BT.709: 0.2126*255)
      // Wrong blue luminance: ~18 (BT.709: 0.0722*255)
      expect(luminance, greaterThan(40),
          reason: 'Red pixel luminance should be ~54, not ~18 (blue-biased)');
      expect(luminance, lessThan(70),
          reason: 'Red pixel luminance should be ~54');
    });

    test('BGRA blue pixel produces correct grayscale (not red-biased)', () {
      // Pure blue in BGRA is [255, 0, 0, 255] (B=255, G=0, R=0, A=255).
      const w = 2;
      const h = 2;
      final bgraBytes = Uint8List(w * h * 4);
      for (int i = 0; i < w * h; i++) {
        bgraBytes[i * 4 + 0] = 255; // B
        bgraBytes[i * 4 + 1] = 0;   // G
        bgraBytes[i * 4 + 2] = 0;   // R
        bgraBytes[i * 4 + 3] = 255; // A
      }

      final image = img.Image.fromBytes(
        width: w,
        height: h,
        bytes: bgraBytes.buffer,
        order: img.ChannelOrder.bgra,
      );

      final gray = img.grayscale(image);
      final pixel = gray.getPixel(0, 0);
      final luminance = pixel.r.toInt();

      // Correct blue luminance: ~18 (BT.709: 0.0722*255)
      expect(luminance, lessThan(30),
          reason: 'Blue pixel luminance should be ~18, not ~54 (red-biased)');
    });
  });
}
```

#### Step 1.2.2: Verify BGRA channel-order test passes

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/bgra_channel_order_test.dart"`
Expected: PASS — this tests the `image` package's `ChannelOrder.bgra` which already exists. This is a **validation test**, not a failing-first test.

#### Step 1.2.3: Write failing test for preprocessor BGRA handling

Add to existing test file: `test/features/pdf/extraction/stages/stage_2b_image_preprocessor_test.dart`

Append this test group at the end, inside the existing `main()`:

```dart
  group('BGRA format handling', () {
    test('preprocesses BGRA raw bytes into valid PNG output', () async {
      // WHY: When pdfrx returns raw BGRA pixels, the preprocessor must
      // decode them with ChannelOrder.bgra, not pass raw bytes through.
      // The output must always be a valid PNG.
      const w = 100;
      const h = 100;
      final bgraBytes = Uint8List(w * h * 4);
      // Fill with a gray pattern (B=128, G=128, R=128, A=255)
      for (int i = 0; i < w * h; i++) {
        bgraBytes[i * 4 + 0] = 128; // B
        bgraBytes[i * 4 + 1] = 128; // G
        bgraBytes[i * 4 + 2] = 128; // R
        bgraBytes[i * 4 + 3] = 255; // A
      }

      final preprocessor = ImagePreprocessorV2();
      final (result, report) = await preprocessor.preprocess(
        renderedPages: {
          0: RenderedPage(
            imageBytes: bgraBytes,
            imageSizePixels: const Size(w.toDouble(), h.toDouble()),
            dpi: 300,
            pageIndex: 0,
            format: RenderedImageFormat.bgraRaw,
          ),
        },
      );

      expect(result.length, 1);
      final page = result[0]!;

      // Output must be a valid PNG (starts with PNG magic bytes)
      expect(page.enhancedImageBytes.length, greaterThan(8));
      expect(page.enhancedImageBytes[0], 0x89); // PNG signature byte 1
      expect(page.enhancedImageBytes[1], 0x50); // 'P'
      expect(page.enhancedImageBytes[2], 0x4E); // 'N'
      expect(page.enhancedImageBytes[3], 0x47); // 'G'

      // Should have applied preprocessing (not fallback)
      expect(page.preprocessingApplied, true);
      expect(page.stats.fellBackToOriginal, false);
    });
  });
```

#### Step 1.2.4: Verify preprocessor BGRA test fails

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/stage_2b_image_preprocessor_test.dart --name 'BGRA format handling'"`
Expected: FAIL — `format` parameter not recognized OR preprocessing fails on raw BGRA bytes (no PNG header → `img.decodeImage()` returns null → fallback)

#### Step 1.2.5: Update _PreprocessParams to carry format

Modify `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart`.

Replace lines 173-183 (the `_PreprocessParams` class):

```dart
/// Parameters for preprocessing isolate.
class _PreprocessParams {
  final Uint8List imageBytes;
  final int pageIndex;
  final Size pageSize;

  /// FROM SPEC: Format indicator so isolate knows how to decode the bytes.
  final RenderedImageFormat format;

  const _PreprocessParams({
    required this.imageBytes,
    required this.pageIndex,
    required this.pageSize,
    this.format = RenderedImageFormat.png,
  });
}
```

#### Step 1.2.6: Update preprocess() to pass format through

Modify `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart`.

In the `preprocess()` method (line 97-170), update the `_PreprocessParams` constructor call at line 113-117 to include format:

Replace:
```dart
          _PreprocessParams(
            imageBytes: renderedPage.imageBytes,
            pageIndex: pageIndex,
            pageSize: renderedPage.imageSizePixels,
          ),
```

With:
```dart
          _PreprocessParams(
            imageBytes: renderedPage.imageBytes,
            pageIndex: pageIndex,
            pageSize: renderedPage.imageSizePixels,
            format: renderedPage.format,
          ),
```

Also update the catch-block fallback at lines 132-144. When the format is `bgraRaw`, raw bytes must be encoded to PNG before storing as fallback:

Replace lines 132-144:
```dart
        preprocessedPages[pageIndex] = PreprocessedPage(
          enhancedImageBytes: renderedPage.imageBytes,
          enhancedSizePixels: renderedPage.imageSizePixels,
          pageIndex: pageIndex,
          stats: const PreprocessingStats(
            skewAngle: 0.0,
            contrastBefore: 0.5,
            contrastAfter: 0.5,
            borderRemoved: false,
            fellBackToOriginal: true,
          ),
          preprocessingApplied: false,
        );
```

With:
```dart
        // WHY: FROM SPEC (MF-3 in adversarial review) — raw BGRA bytes have no
        // PNG header, so downstream stages would crash. Must encode to PNG even
        // in the fallback path. Uses RenderedPage.toPngBytes() for DRY.
        final fallbackBytes = renderedPage.format == RenderedImageFormat.bgraRaw
            ? renderedPage.toPngBytes()
            : renderedPage.imageBytes;
        preprocessedPages[pageIndex] = PreprocessedPage(
          enhancedImageBytes: fallbackBytes,
          enhancedSizePixels: renderedPage.imageSizePixels,
          pageIndex: pageIndex,
          stats: const PreprocessingStats(
            skewAngle: 0.0,
            contrastBefore: 0.5,
            contrastAfter: 0.5,
            borderRemoved: false,
            fellBackToOriginal: true,
          ),
          preprocessingApplied: false,
        );
```

#### Step 1.2.7: Update _preprocessIsolate() for BGRA decoding

Modify `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart`.

Replace lines 194-199 (the beginning of `_preprocessIsolate`):

```dart
PreprocessedPage _preprocessIsolate(_PreprocessParams params) {
  try {
    final image = img.decodeImage(params.imageBytes);
    if (image == null) {
      return _createFallbackPage(params);
    }
```

With:
```dart
PreprocessedPage _preprocessIsolate(_PreprocessParams params) {
  try {
    // WHY: FROM SPEC — pdfrx returns raw BGRA pixels (no PNG header).
    // img.decodeImage() expects encoded formats (PNG/JPEG) and would return
    // null for raw BGRA. We must construct the Image directly from the byte
    // buffer with explicit channel order.
    final img.Image? image;
    if (params.format == RenderedImageFormat.bgraRaw) {
      final w = params.pageSize.width.toInt();
      final h = params.pageSize.height.toInt();
      final expectedLength = w * h * 4;
      // FROM SPEC (MF-3): Validate buffer length to catch corruption early
      if (params.imageBytes.length != expectedLength) {
        debugPrint(
          '[ImagePreprocessorV2] BGRA buffer length mismatch: '
          'expected=$expectedLength, actual=${params.imageBytes.length}',
        );
        return _createFallbackPage(params);
      }
      image = img.Image.fromBytes(
        width: w,
        height: h,
        bytes: params.imageBytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    } else {
      image = img.decodeImage(params.imageBytes);
      if (image == null) {
        return _createFallbackPage(params);
      }
    }
```

**NOTE**: The `import` for `page_renderer_v2.dart` already exists at line 8 of this file, so `RenderedImageFormat` is already accessible.

#### Step 1.2.8: Update _createFallbackPage() for BGRA encoding

Modify `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart`.

Replace lines 257-272 (the `_createFallbackPage` function):

```dart
/// Create fallback page using original image.
///
/// WHY: FROM SPEC (adversarial review hole #3) — fallback paths must encode
/// BGRA→PNG because downstream stages expect PNG headers.
PreprocessedPage _createFallbackPage(_PreprocessParams params) {
  Uint8List bytes = params.imageBytes;
  if (params.format == RenderedImageFormat.bgraRaw) {
    try {
      final w = params.pageSize.width.toInt();
      final h = params.pageSize.height.toInt();
      final fallbackImage = img.Image.fromBytes(
        width: w,
        height: h,
        bytes: params.imageBytes.buffer,
        order: img.ChannelOrder.bgra,
      );
      bytes = Uint8List.fromList(img.encodePng(fallbackImage));
    } catch (e) {
      // NOTE: Logged per security review H-2. Raw BGRA bytes will likely
      // fail downstream, but this is a last-resort fallback.
      debugPrint('[ImagePreprocessorV2] BGRA fallback encoding failed: $e');
    }
  }
  return PreprocessedPage(
    enhancedImageBytes: bytes,
    enhancedSizePixels: params.pageSize,
    pageIndex: params.pageIndex,
    stats: const PreprocessingStats(
      skewAngle: 0.0,
      contrastBefore: 0.5,
      contrastAfter: 0.5,
      borderRemoved: false,
      fellBackToOriginal: true,
    ),
    preprocessingApplied: false,
  );
}
```

#### Step 1.2.9: Verify preprocessor BGRA test passes

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/stage_2b_image_preprocessor_test.dart --name 'BGRA format handling'"`
Expected: PASS

#### Step 1.2.10: Verify BGRA channel-order test still passes

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/bgra_channel_order_test.dart"`
Expected: PASS

### Sub-phase 1.3: Update Diagnostic Callback for BGRA

**Files:**
- Modify: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart:438-443`

**Agent**: `pdf-agent`

#### Step 1.3.1: Encode BGRA→PNG for diagnostic callbacks

Modify `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`.

Replace lines 438-443:
```dart
    for (final entry in renderedPages.entries) {
      onDiagnosticImage?.call(
        'page_${entry.key}_rendered',
        entry.value.imageBytes,
      );
    }
```

With:
```dart
    // WHY: FROM SPEC — diagnostic callbacks expect PNG for image viewers.
    // Uses RenderedPage.toPngBytes() for DRY format-aware conversion.
    for (final entry in renderedPages.entries) {
      onDiagnosticImage?.call(
        'page_${entry.key}_rendered',
        entry.value.toPngBytes(),
      );
    }
```

**NOTE**: No new imports needed in `extraction_pipeline.dart`. The `toPngBytes()` method lives on `RenderedPage` (in `page_renderer_v2.dart`), which is already accessible via the `stages.dart` barrel import. This avoids leaking the `image` package dependency into the pipeline orchestrator (code review H-2).

#### Step 1.3.2: Verify full test suite passes

Run: `pwsh -Command "flutter test"`
Expected: 906+ pass, 0 failures. Phase 1 is backward-compatible.

---

## Phase 2: pdfrx Swap — Replace pdfx with pdfrx

**Goal:** Swap the rendering backend. pdfrx bundles PDFium so all platforms get identical pixel output.

### Sub-phase 2.1: Update Dependencies

**Files:**
- Modify: `pubspec.yaml:75`

**Agent**: `pdf-agent`

#### Step 2.1.1: Replace pdfx with pdfrx in pubspec.yaml

In `pubspec.yaml`, replace line 75:

```yaml
  pdfx: ^2.9.2
```

With:
```yaml
  pdfrx: 2.2.24
```

**NOTE**: Pinned to exact version `2.2.24` (no caret) per spec — FROM SPEC: "Pin pdfrx to exact 2.2.24". This prevents accidental upgrades that could change pixel output.

#### Step 2.1.2: Run pub get

Run: `pwsh -Command "flutter pub get"`
Expected: SUCCESS — dependencies resolve. If there are version conflicts, resolve them before proceeding.

#### Step 2.1.3: Verify pdfrx API signatures

**IMPORTANT** (code review C-2): pdfrx is not yet in the dependency tree. Before writing code in Step 2.2.1, the implementer MUST:

1. Locate the pdfrx package source: check `.dart_tool/package_config.json` for the pdfrx path
2. Verify the following API contracts against the actual pdfrx 2.2.24 source:
   - `PdfDocument.openData(Uint8List)` — returns `Future<PdfDocument>`
   - `pdfDoc.pages[index]` — 0-based or 1-based? (plan assumes 0-based)
   - `page.render(fullWidth: int, fullHeight: int, backgroundColor: PdfColor)` — exact signature
   - `PdfColor` constructor — `PdfColor(r, g, b)` or `PdfColor(0xFFFFFFFF)` or other?
   - `pdfImage.pixels` — returns `Uint8List` or `ByteBuffer`?
   - `pdfImage.width` / `pdfImage.height` — int or double?
   - `pdfImage.dispose()` — exists and is void?
   - `pdfDoc.dispose()` — exists and is void?

3. Adjust the code in Step 2.2.1 if any API signatures differ from what's written

This step prevents compile errors from incorrect API assumptions.

### Sub-phase 2.2: Rewrite PageRendererV2

**Files:**
- Modify: `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart:1-304`

**Agent**: `pdf-agent`

#### Step 2.2.1: Rewrite page_renderer_v2.dart

Replace the ENTIRE file content of `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart` with:

```dart
import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/models.dart';
import 'stage_names.dart';

/// Image format indicator for rendered page output.
///
/// FROM SPEC: pdfrx returns raw BGRA pixels (no PNG header). The preprocessor
/// needs to know the format to decode correctly.
enum RenderedImageFormat { png, bgraRaw }

/// Rendered page data for OCR processing.
class RenderedPage {
  final Uint8List imageBytes;
  final Size imageSizePixels;
  final int dpi;
  final int pageIndex;

  /// Image format — png (default, backward-compatible) or bgraRaw (pdfrx output).
  /// FROM SPEC: BGRA handling confined to preprocessor + diagnostics only.
  final RenderedImageFormat format;

  const RenderedPage({
    required this.imageBytes,
    required this.imageSizePixels,
    required this.dpi,
    required this.pageIndex,
    this.format = RenderedImageFormat.png,
  });

  /// Convert imageBytes to PNG, handling BGRA format if needed.
  /// WHY: DRY helper — BGRA→PNG conversion needed in preprocessor fallbacks
  /// and diagnostic callbacks. Centralizing here keeps format knowledge with
  /// the enum definition.
  Uint8List toPngBytes() {
    if (format == RenderedImageFormat.png) return imageBytes;
    try {
      final w = imageSizePixels.width.toInt();
      final h = imageSizePixels.height.toInt();
      final image = img.Image.fromBytes(
        width: w,
        height: h,
        bytes: imageBytes.buffer,
        order: img.ChannelOrder.bgra,
      );
      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      debugPrint('[RenderedPage] BGRA→PNG encoding failed: $e');
      return imageBytes; // Best-effort: return raw bytes
    }
  }

  @override
  String toString() =>
      'RenderedPage(page=$pageIndex, size=${imageSizePixels.width.toInt()}x${imageSizePixels.height.toInt()}, dpi=$dpi, format=${format.name})';
}

/// Stage 2B-i: PDF Page Rendering.
///
/// Renders PDF pages to images for OCR processing using pdfrx (bundled PDFium).
/// Single rendering path for all platforms — no platform-specific branches.
///
/// ## Input:
/// - PdfDocument (Syncfusion — for page count/metadata)
/// - pdfBytes (Uint8List for pdfrx rendering)
/// - List of OCR page indices from DocumentProfile
/// - Optional DPI override (defaults to adaptive)
///
/// ## Output:
/// - `Map<int, RenderedPage>`: Page index → rendered image + metadata
/// - StageReport with rendering metrics
///
/// ## DPI Strategy:
/// - ≤10 pages: 300 DPI (high quality)
/// - 11-25 pages: 250 DPI (balanced)
/// - >25 pages: 200 DPI (memory-efficient)
/// - Force DPI: Override adaptive strategy
///
/// ## Rendering:
/// Uses pdfrx (bundled PDFium) on ALL platforms. Returns raw BGRA pixels
/// for maximum fidelity — PNG encoding deferred to preprocessor.
///
/// ## Usage:
/// ```dart
/// final renderer = PageRendererV2();
/// final (pages, report) = await renderer.render(
///   document: pdfDoc,
///   pdfBytes: bytes,
///   pageIndices: [3, 5], // OCR pages only
/// );
/// ```
class PageRendererV2 {
  /// Maximum pixel budget to prevent memory blowups.
  static const int kMaxPixels = 12000000; // ~3464 x 3464 at 200 DPI

  /// Render PDF pages to images for OCR.
  ///
  /// Returns a record containing:
  /// - `Map<int, RenderedPage>`: Page index → rendered image with metadata
  /// - StageReport: Rendering metrics and validation
  Future<(Map<int, RenderedPage>, StageReport)> render({
    required PdfDocument document,
    required Uint8List pdfBytes,
    required List<int> pageIndices,
    int? forceDpi,
  }) async {
    final startTime = DateTime.now();
    final renderedPages = <int, RenderedPage>{};
    final warnings = <String>[];

    // Calculate DPI (adaptive or forced)
    final dpi = forceDpi ?? calculateAdaptiveDpi(document.pages.count);

    for (final pageIndex in pageIndices) {
      try {
        final page = document.pages[pageIndex];
        final pageSize = Size(page.size.width, page.size.height);

        // Render page with pdfrx
        final result = await _renderSinglePage(
          pdfBytes: pdfBytes,
          pageIndex: pageIndex,
          pageSize: pageSize,
          dpi: dpi,
        );

        if (result != null) {
          renderedPages[pageIndex] = result;
        } else {
          warnings.add('Failed to render page ${pageIndex + 1}');
        }
      } catch (e) {
        warnings.add('Error rendering page ${pageIndex + 1}: $e');
        debugPrint('[PageRendererV2] Error rendering page ${pageIndex + 1}: $e');
      }
    }

    final elapsed = DateTime.now().difference(startTime);

    // Create stage report
    final report = StageReport(
      stageName: StageNames.pageRendering,
      elapsed: elapsed,
      stageConfidence: 1.0, // Rendering is deterministic
      inputCount: pageIndices.length,
      outputCount: renderedPages.length,
      excludedCount: pageIndices.length - renderedPages.length,
      warnings: warnings,
      metrics: {
        'dpi': dpi,
        'totalPages': pageIndices.length,
        'successfulPages': renderedPages.length,
        'failedPages': pageIndices.length - renderedPages.length,
        'avgRenderTime':
            pageIndices.isNotEmpty ? '${elapsed.inMilliseconds ~/ pageIndices.length}ms' : '0ms',
        'renderer': 'pdfrx',
      },
      completedAt: DateTime.now(),
    );

    return (renderedPages, report);
  }

  /// Calculate adaptive DPI based on page count.
  ///
  /// Balances quality vs memory/performance:
  /// - ≤10 pages: 300 DPI (high quality for small docs)
  /// - 11-25 pages: 250 DPI (balanced quality)
  /// - >25 pages: 200 DPI (memory-efficient for large docs)
  int calculateAdaptiveDpi(int totalPages) {
    if (totalPages <= 10) {
      return 300;
    } else if (totalPages <= 25) {
      return 250;
    } else {
      return 200;
    }
  }

  /// Render a single page using pdfrx (bundled PDFium).
  ///
  /// FROM SPEC: Single rendering path for all platforms. No Platform.isWindows
  /// branching. Returns raw BGRA pixels — preprocessor handles encoding.
  Future<RenderedPage?> _renderSinglePage({
    required Uint8List pdfBytes,
    required int pageIndex,
    required Size pageSize,
    required int dpi,
  }) async {
    return _renderWithPdfrx(
      pdfBytes: pdfBytes,
      pageIndex: pageIndex,
      pageSize: pageSize,
      dpi: dpi,
    );
  }

  /// Render using pdfrx (bundled PDFium, all platforms).
  ///
  /// FROM SPEC: PdfImage lifecycle — copy pixels before dispose.
  /// PdfImage has NO NativeFinalizer, so failure to dispose leaks ~33MB/page.
  Future<RenderedPage?> _renderWithPdfrx({
    required Uint8List pdfBytes,
    required int pageIndex,
    required Size pageSize,
    required int dpi,
  }) async {
    pdfrx.PdfDocument? pdfDoc;

    try {
      // Open PDF document from bytes
      pdfDoc = await pdfrx.PdfDocument.openData(pdfBytes);

      // Get page (pdfrx uses 1-based indexing)
      final page = pdfDoc.pages[pageIndex];

      // Calculate target dimensions based on DPI
      final scale = dpi / 72.0;
      final fullWidth = (page.width * scale).toInt();
      final fullHeight = (page.height * scale).toInt();

      // FROM SPEC (MF-1, MF-2): Render and immediately copy pixels before dispose.
      // PdfImage.dispose() frees native memory — use-after-free if pixels read after.
      final pdfImage = await page.render(
        fullWidth: fullWidth,
        fullHeight: fullHeight,
        backgroundColor: const pdfrx.PdfColor(0xFF, 0xFF, 0xFF),
      );

      if (pdfImage == null) {
        debugPrint('[PageRendererV2] pdfrx returned null for page ${pageIndex + 1}');
        return null;
      }

      try {
        // FROM SPEC (MF-1): MUST copy pixels before dispose — Uint8List.fromList
        // creates a Dart-heap copy that survives native deallocation.
        final pixels = Uint8List.fromList(pdfImage.pixels);

        // FROM SPEC (MF-3): Validate BGRA buffer length at RUNTIME
        // NOTE: Uses runtime check, NOT assert — assert is stripped in release builds
        // (security review H-1, code review L-1)
        final expectedLength = pdfImage.width * pdfImage.height * 4;
        if (pixels.length != expectedLength) {
          debugPrint(
            '[PageRendererV2] BGRA buffer length mismatch: '
            'expected=$expectedLength, actual=${pixels.length}',
          );
          return null;
        }

        return RenderedPage(
          imageBytes: pixels,
          imageSizePixels: Size(
            pdfImage.width.toDouble(),
            pdfImage.height.toDouble(),
          ),
          dpi: dpi,
          pageIndex: pageIndex,
          format: RenderedImageFormat.bgraRaw,
        );
      } finally {
        // FROM SPEC (MF-2): ALWAYS dispose — no NativeFinalizer, leaks 33MB/page
        pdfImage.dispose();
      }
    } catch (e) {
      debugPrint('[PageRendererV2] pdfrx error for page ${pageIndex + 1}: $e');
      return null;
    } finally {
      pdfDoc?.dispose();
    }
  }
}
```

**KEY CHANGES from old code:**
1. Removed `import 'dart:io'` (no more `Platform.isWindows`)
2. Removed `import 'package:pdfx/pdfx.dart'` → replaced with `import 'package:pdfrx/pdfrx.dart'`
3. Removed `import 'package:printing/printing.dart'` (not needed in renderer anymore)
4. Removed `import 'package:flutter/services.dart'` (no more isolate token)
5. Removed `_renderWithPrinting()` entirely
6. Removed `_renderWithPdfx()` → replaced with `_renderWithPdfrx()`
7. `_renderSinglePage()` simplified to single pdfrx path
8. Returns `RenderedImageFormat.bgraRaw` instead of PNG
9. PdfImage lifecycle: copy-before-dispose in try/finally

#### Step 2.2.2: Verify renderer test still passes

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/stage_2b_page_renderer_test.dart"`
Expected: PASS — DPI calculation tests are pure logic, unaffected by renderer change.

#### Step 2.2.3: Verify RenderedImageFormat test still passes

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/rendered_image_format_test.dart"`
Expected: PASS

#### Step 2.2.4: Verify full test suite passes

Run: `pwsh -Command "flutter test"`
Expected: 906+ pass. Mock renderers in tests don't use pdfx — they return fake `RenderedPage` instances directly.

---

## Phase 3: Grid Line Threshold Restore

**Goal:** Restore `_adaptiveC = 10.0` to reduce mask coverage from 77% to 3-10%.

### Sub-phase 3.1: Fix _adaptiveC

**Files:**
- Modify: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart:15`

**Agent**: `pdf-agent`

#### Step 3.1.1: Change _adaptiveC from -2.0 to 10.0

Modify `lib/features/pdf/services/extraction/stages/grid_line_remover.dart`.

Replace line 15:
```dart
const double _adaptiveC = -2.0;
```

With:
```dart
/// FROM SPEC: Restored from -2.0 to 10.0. The -2.0 value created 77% mask
/// coverage, destroying text via aggressive inpainting. 10.0 reduces mask
/// coverage to ~5.3% (proven in Session 524, lost to destructive revert in 527).
const double _adaptiveC = 10.0;
```

#### Step 3.1.2: Verify grid line remover tests pass

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/grid_line_remover_test.dart"`
Expected: PASS — tests use mock images, threshold value doesn't affect test assertions.

#### Step 3.1.3: Verify full test suite passes

Run: `pwsh -Command "flutter test"`
Expected: 906+ pass.

---

## Phase 4: Fixture Regeneration & Test Validation

**Goal:** Regenerate all Springfield fixtures with the new pdfrx renderer and verify the full pipeline.

**IMPORTANT**: This phase requires the Springfield PDF at runtime. The fixture generation test uses `-D SPRINGFIELD_PDF=path/to/file.pdf` define. This is a local-only step — CI cannot run it.

### Sub-phase 4.1: Regenerate Golden Fixtures

**Agent**: `qa-testing-agent`

#### Step 4.1.1: Regenerate Springfield fixtures

Run on Windows (where the Springfield PDF is available):

```
pwsh -Command "flutter test integration_test/generate_golden_fixtures_test.dart -D SPRINGFIELD_PDF=path/to/springfield.pdf"
```

**NOTE**: The exact path to the Springfield PDF must be provided by the user. Ask if unsure.

Expected: Generates updated fixture files in `test/features/pdf/extraction/fixtures/` and `test/features/pdf/extraction/golden/`.

#### Step 4.1.2: Run GT trace (131 items, $0 delta)

Run: `pwsh -Command "flutter test test/features/pdf/extraction/golden/stage_trace_diagnostic_test.dart"`
Expected:
- 131 parsed items
- $0 checksum delta
- 36/36 trace tests pass

#### Step 4.1.3: Run full test suite with regenerated fixtures

Run: `pwsh -Command "flutter test"`
Expected: 906+ pass. Fixture files will have changed content (pdfrx pixel output differs from pdfx) but test assertions should still hold.

**GATE**: If GT trace shows fewer than 131 items or non-zero checksum delta, STOP and investigate. The pdfrx renderer may produce different OCR results that require fixture tuning.

### Sub-phase 4.2: Validate Mask Coverage

**Agent**: `qa-testing-agent`

#### Step 4.2.1: Check mask coverage in stage trace output

In the GT trace output from Step 4.1.2, look for the grid line removal stage metrics:
- `mask_coverage_ratio_avg` should be between 0.03 and 0.10 (3%-10%)

**GATE (FROM SPEC)**: If mask coverage is outside 3%-10%:
- If > 10%: Try `_adaptiveC = 15.0`
- If < 3%: Try `_adaptiveC = 5.0`
- Known progression: 2 → 5 → 10 → 15

---

## Phase 5: Three-Device Validation

**Goal:** Build debug APK and verify parity on S21+, S25 Ultra, and Windows.

**IMPORTANT**: This phase requires physical devices and manual verification.

### Sub-phase 5.1: Build Debug APK

**Agent**: `qa-testing-agent`

#### Step 5.1.1: Build debug APK

Run: `pwsh -File tools/build.ps1 -Platform android -BuildType debug`
Expected: Build succeeds, APK at `releases/android/debug/`

### Sub-phase 5.2: Three-Device Extraction

#### Step 5.2.1: Run Springfield extraction on all 3 devices

Install debug APK on:
1. S21+ (SM-G996U, serial RFCNC0Y975L) — Android 15
2. S25 Ultra (SM-S938U, serial R5CY12JTTPX) — Android 16
3. Windows desktop

Run Springfield PDF extraction on each device. Record:
- Item count (expect: 131)
- Quality score (expect: >= 0.99)
- Checksum (expect: MATCHED across all 3)

#### Step 5.2.2: Save post-migration baselines

Save extraction results to `test/features/pdf/extraction/device-baselines/post-migration/`:
- `s21plus_summary.json`
- `s25ultra_summary.json`
- `windows_summary.json`

**GATE**: All 3 must produce identical:
- 131 items
- $0 checksum delta
- Score >= 0.99

If ANY device diverges, STOP and investigate before proceeding.

---

## Phase 6: Cleanup & Hardening

### Sub-phase 6.1: ProGuard Keep Rules

**Files:**
- Modify: `android/app/proguard-rules.pro`

**Agent**: `pdf-agent`

#### Step 6.1.1: Add ProGuard keep rules

Replace the content of `android/app/proguard-rules.pro` with:

```
# Proguard rules for Construction Inspector App

# pdfrx — JNI bridge to bundled PDFium
# FROM SPEC: Defensive keep rules for when R8/ProGuard is enabled
-keep class com.nicholaswilliams.pdfium.** { *; }
-keep class io.github.nicholaswilliams.pdfium.** { *; }
-keep class io.nicholaswilliams.pdfium.** { *; }

# opencv_dart — JNI bridge to bundled OpenCV
-keep class org.opencv.** { *; }

# flusseract — JNI bridge to bundled Tesseract
-keep class com.rmawatson.flutterlibrary.** { *; }
```

**NOTE**: ProGuard/R8 is currently disabled in this project (as noted in adversarial review). These are defensive keep rules for future-proofing.

### Sub-phase 6.2: Benchmark Test Cleanup

**Files:**
- Modify: `test/features/pdf/extraction/golden/springfield_benchmark_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.2.1: Verify benchmark test does not import pdfx or printing

Read `test/features/pdf/extraction/golden/springfield_benchmark_test.dart` and verify:
- No `import 'package:pdfx/...'` references
- No `import 'package:printing/...'` references used for rendering mocks
- If the test has a printing mock for rendering, remove it — pdfrx handles all rendering now

FROM SPEC: "Remove printing mock, populate with real data" (spec line 106)

### Sub-phase 6.3: Verify architecture.md Accuracy

**Agent**: `pdf-agent`

#### Step 6.3.1: Verify architecture.md says pdfrx (not pdfx)

Read `.claude/rules/architecture.md` and verify the Key Packages table lists `pdfrx` (not `pdfx`). Per adversarial review item #6, it already says pdfrx — verify, do not blindly update.

### Sub-phase 6.4: Build Release APK

**Agent**: `qa-testing-agent`

#### Step 6.4.1: Build release APK

Run: `pwsh -File tools/build.ps1 -Platform android`
Expected: Release APK builds clean. If ProGuard strips pdfrx JNI, the keep rules from 6.1.1 should prevent this.

#### Step 6.4.2: Final full test suite

Run: `pwsh -Command "flutter test"`
Expected: 906+ pass, 0 failures.

---

## Summary

| Phase | Files Changed | Tests | Agent |
|-------|--------------|-------|-------|
| 0: Pre-flight | 0 | Run all 906+ | qa-testing-agent |
| 1: Contract Update | 3 production + 2 new test | +2 new test files, modify 1 test | pdf-agent |
| 2: pdfrx Swap | 2 (pubspec + renderer) | Existing pass + API verify | pdf-agent |
| 3: Grid Threshold | 1 (grid_line_remover) | Existing pass | pdf-agent |
| 4: Fixture Regen | 18+ fixture files | GT trace + full suite | qa-testing-agent |
| 5: Three-Device | 0 (manual) | Device extraction | qa-testing-agent |
| 6: Cleanup | 3 (proguard + benchmark test + release) | Full suite | pdf-agent + qa-testing-agent |

**Total production files modified**: 5 (`pubspec.yaml`, `page_renderer_v2.dart`, `image_preprocessor_v2.dart`, `extraction_pipeline.dart`, `grid_line_remover.dart`)
**Total cleanup files**: 2 (`proguard-rules.pro`, `springfield_benchmark_test.dart`)
**Total new test files**: 2 (`rendered_image_format_test.dart`, `bgra_channel_order_test.dart`)
**Total modified test files**: 1 (`stage_2b_image_preprocessor_test.dart`)

## Adversarial Review Findings Addressed

**Code Review** (2 CRITICAL, 3 HIGH → all addressed):
- C-1: Added `import 'dart:ui' show Size;` to renderer rewrite
- C-2: Added Step 2.1.3 — pdfrx API verification after pub get
- H-1: Added benchmark test cleanup (Sub-phase 6.2)
- H-2: Added `toPngBytes()` to RenderedPage — pipeline no longer imports `image` package
- H-3: BGRA fallback-of-fallback tested via existing fallback test + new BGRA test

**Security Review** (0 CRITICAL, 2 HIGH → all addressed):
- H-1: Replaced `assert` with runtime `if` check in renderer buffer validation
- H-2: Added `debugPrint` logging to all `catch` blocks (no more silent swallows)

**Medium findings noted for implementation**: DRY helper centralized in `toPngBytes()`, agent routing fixed, ProGuard rules should be verified against actual AAR class names

**Success criteria** (from spec):
- [ ] All 3 devices: 131 items, $0 checksum, score >= 0.99
- [ ] GT trace: 131/131 matched, $0 delta on all 3
- [ ] Stage trace: 0 BUG on all 3
- [ ] Scorecard + benchmark: parity across all 3
- [ ] Mask coverage 3%-10%
- [ ] 906+ tests pass, 0 regressions
- [ ] BGRA channel-order test passes
- [ ] Release APK builds clean
