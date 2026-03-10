# pdfrx Parity + Grid Line Threshold Restore

**Date**: 2026-03-09
**Priority**: HIGH
**Goal**: All 3 devices (S21+, S25 Ultra, Windows) produce identical extraction results on the Springfield PDF.

## Problem

Two Android phones running the same APK on the same PDF produce different results:

| Metric | S21+ (Android 15) | S25 Ultra (Android 16) | Windows |
|--------|-------------------|------------------------|---------|
| OCR elements | 1243 | **1238 (-5)** | 1243 |
| Parsed items | 131 | **130 (-1)** | 131 |
| Quality score | 0.993 | **0.918** | 0.993 |
| Checksum | MATCHED | **$457,291 gap** | MATCHED |

**Cause 1**: `pdfx` delegates to Android's native `PdfRenderer` which differs between OS versions. Android 16's renderer produces 5 fewer OCR elements, losing 1 item worth $457K.

**Cause 2**: `_adaptiveC = -2.0` in the grid line remover creates 77% mask coverage, destroying text via aggressive inpainting. This fix to 10.0 was proven in Session 524 but lost to a destructive revert.

## Solution

1. **Replace `pdfx` with `pdfrx`** — bundles PDFium 144.0.7520.0 on ALL platforms. Same renderer everywhere.
2. **Restore `_adaptiveC = 10.0`** — reduces mask coverage from 77% to 5.3%. Proven fix.
3. **Validate parity** on all 3 devices via GT trace, stage trace, scorecard, and benchmark.

## Architecture

### Dependency Graph (CodeMunch verified)

```
pdf_import_service → ExtractionPipeline.extract()
                       └── PageRendererV2.render()          ← pdfx lives HERE ONLY
                             └── _renderWithPdfx()          ← rewrite to _renderWithPdfrx()
                                   └── Returns RenderedPage  ← FIREWALL (contract boundary)
                       └── ImagePreprocessorV2.preprocess()  ← BGRA input handling needed
                             └── Returns PreprocessedPage    ← always PNG output
                       └── GridLineDetector.detect()         ← receives PNG, no change
                       └── GridLineRemover.remove()          ← receives PNG, no change; threshold fix here
                       └── TextRecognizerV2.recognize()      ← receives PNG, no change
                       └── Stages 3-6                        ← no change
```

**Key insight**: The preprocessor always outputs PNG (`img.encodePng` at the end). So BGRA handling is confined to 4 sites: preprocessor input, 2 preprocessor fallback paths, and diagnostic callbacks. All downstream stages (grid detection, grid removal, OCR) receive PNG and are untouched.

### RenderedPage Contract Change

```dart
// NEW: format-aware output
enum RenderedImageFormat { png, bgraRaw }

class RenderedPage {
  final Uint8List imageBytes;       // PNG or raw BGRA pixels
  final Size imageSizePixels;
  final int dpi;
  final int pageIndex;
  final RenderedImageFormat format; // NEW — default png for backward compat
}
```

### PdfImage Lifecycle (mandatory pattern)

```dart
final pdfImage = await page.render(fullWidth: w, fullHeight: h, backgroundColor: 0xFFFFFFFF);
if (pdfImage == null) return null;
try {
  final pixels = Uint8List.fromList(pdfImage.pixels); // MUST copy before dispose
  assert(pixels.length == pdfImage.width * pdfImage.height * 4);
  return RenderedPage(imageBytes: pixels, ..., format: RenderedImageFormat.bgraRaw);
} finally {
  pdfImage.dispose(); // ALWAYS — no NativeFinalizer, leaks 33MB/page
}
```

### BGRA Handling Sites

| Site | File | Action |
|------|------|--------|
| Preprocessor happy path | `image_preprocessor_v2.dart:196` | Check format → `Image.fromBytes(order: ChannelOrder.bgra)` |
| Preprocessor catch fallback | `image_preprocessor_v2.dart:130-144` | Encode BGRA→PNG before storing |
| Preprocessor `_createFallbackPage` | `image_preprocessor_v2.dart:258-272` | Encode BGRA→PNG before storing |
| Diagnostic callbacks | `extraction_pipeline.dart:438-443` | Encode BGRA→PNG before callback |

## Files Changed

### Production Code (4 files)

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `pdfrx: 2.2.24` (pinned), remove `pdfx: ^2.9.2` |
| `page_renderer_v2.dart` | Rewrite: remove pdfx/Printing.raster, single pdfrx path, RenderedImageFormat enum, format field, PdfImage lifecycle |
| `image_preprocessor_v2.dart` | Handle BGRA input (happy path + 2 fallback paths) |
| `extraction_pipeline.dart` | Encode BGRA→PNG for diagnostic callbacks |

### One-Line Fix (1 file)

| File | Change |
|------|--------|
| `grid_line_remover.dart:15` | `_adaptiveC = -2.0` → `10.0` |

### Cleanup (2 files)

| File | Change |
|------|--------|
| `springfield_benchmark_test.dart` | Remove printing mock, populate with real data |
| `android/app/proguard-rules.pro` | Add keep rules for pdfrx, opencv_dart, flusseract |

### NOT Changed

All stages downstream of preprocessing (grid detector, grid remover, text recognizer, row classifier, post processor, etc.) — they receive PNG from the preprocessor. Also: `printing` stays in pubspec (used by 4 other files for PDF preview/share).

## Phases

### Phase 0: Pre-flight
Confirm 906+ tests green. Device baselines already saved in `device-baselines/`.

### Phase 1: Contract Update
Add `RenderedImageFormat` enum + `format` field to `RenderedPage`. Update preprocessor BGRA handling (happy path + 2 fallbacks). Update diagnostic callbacks. Add BGRA grayscale channel-order test. All tests still pass (format defaults to png).

### Phase 2: pdfrx Swap
Add `pdfrx: 2.2.24` to pubspec. Rewrite `PageRendererV2`: remove `Platform.isWindows` gate, remove `_renderWithPrinting()`, remove `_renderWithPdfx()`, add `_renderWithPdfrx()` with PdfImage lifecycle. Remove pdfx from pubspec. Add renderer validation tests. Verify release build.

### Phase 3: Grid Line Threshold
`_adaptiveC = -2.0` → `10.0`. **Gate**: mask coverage must be 3%-10% with pdfrx images. If outside range, re-tune using known progression (2→5→10→15).

### Phase 4: Fixture Regen & Test Suite
Regenerate all Springfield fixtures. Run GT trace (131 items, $0 delta), stage trace (0 BUG), scorecard (>= 0.99), benchmark (real data). Full test suite 906+ pass.

### Phase 5: Three-Device Validation
Build debug APK. Run Springfield extraction on S21+, S25 Ultra, Windows. Compare GT/stage/scorecard/benchmark across all 3. Save to `device-baselines/post-migration/`. **GATE: All 3 must match before any R1-R5 work.**

### Phase 6: Cleanup
Remove pdfx references. Remove printing mock from benchmark test. Verify `architecture.md` accuracy. Add ProGuard keep rules. Verify release build. Commit.

## Success Criteria

- [ ] All 3 devices: 131 items, $0 checksum, score >= 0.99
- [ ] GT trace: 131/131 matched, $0 delta on all 3
- [ ] Stage trace: 0 BUG on all 3
- [ ] Scorecard + benchmark: parity across all 3
- [ ] Mask coverage 3%-10%
- [ ] 906+ tests pass, 0 regressions
- [ ] BGRA channel-order test passes
- [ ] Release APK builds clean

## Risks

| Risk | Mitigation |
|------|------------|
| pdfrx pixel output differs from pdfx | Expected — regenerate fixtures, re-baseline |
| BGRA/RGBA channel swap (wrong grayscale) | Channel-order unit test with known-color image |
| Memory: ~66MB/page peak (BGRA + isolate copy) | Pages sequential; 6 pages = ~396MB peak; S21+ has 6GB |
| Grid threshold 10.0 needs re-tuning with pdfrx | Gate in Phase 3; known progression 2→5→10→15 |
| ProGuard strips pdfrx JNI | Keep rules in Phase 6; test release build |

## Rollback

Revert pubspec.yaml + page_renderer_v2.dart + image_preprocessor_v2.dart + extraction_pipeline.dart. Run `flutter pub get`. Downstream stages untouched.

## Related

- **Adversarial review**: `.claude/adversarial_reviews/2026-03-09-pdfrx-parity/review.md`
- **Dependency graph**: `.claude/dependency_graphs/2026-03-09-pdfrx-parity/blast-radius.md`
- **Device baselines**: `test/features/pdf/extraction/device-baselines/`
- **Deferred plans**: R1-R5 accuracy fixes (re-evaluate after parity confirmed)
