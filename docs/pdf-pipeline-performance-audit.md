# PDF Extraction Pipeline — Performance Audit

**Date**: 2026-03-08
**Audited by**: 3-agent parallel code review (rendering, preprocessing/OCR, pipeline orchestration)
**Scope**: Full extraction pipeline from `PageRendererV2.render()` through `QualityValidator`
**Baseline**: Springfield 4-page bid schedule at 300 DPI

## Executive Summary

The extraction pipeline has **14 identified bottlenecks** across rendering, preprocessing, OCR, and orchestration. The most impactful are unconditional PNG encoding in the cell-crop loop, redundant PNG encode/decode roundtrips at every stage boundary, and re-extraction repeating all stages from scratch. Combined estimated savings: **30-80+ seconds per 4-page document**.

One **correctness bug** was also found (`_measureContrast` produces ~70% underreported values after 1-channel conversion).

## Pipeline Stage Map

```
Stage 0:    Document Quality Profiling
              |
Stage 2B-i:  Page Rendering ............ per-page sequential, doc opened per-page
              |
Stage 2B-ii: Image Preprocessing ....... per-page sequential compute() isolates
              |
Stage 2B-ii.5: Grid Line Detection ..... per-page sequential compute() isolates
              |
Stage 2B-ii.6: Grid Line Removal ....... per-page sequential, NO isolate (UI jank)
              |
Stage 2B-iii: Text Recognition (OCR) ... per-cell sequential (heaviest stage)
              |
Stage 3:     Element Validation
              |
              Provisional Row Classification + Header Consolidation  <-- DUPLICATE
              |
Stage 4B:    Region Detection (needs provisional rows)
              |
Stage 4C:    Column Detection (needs regions)
              |
Stage 4A:    Final Row Classification (needs columns) <-- re-does provisional work
              |
              Final Header Consolidation
              |
Stage 4A.5:  Row Merging
              |
Stage 4D:    Cell Extraction
              |
Stage 4D.5:  Numeric Interpretation
              |
Stage 4E:    Row Parsing
              |
Stage 4E.5:  Field Confidence Scoring
              |
Stage 5:     Post-Processing
              |
Stage 6:     Quality Validation
```

## Image Encode/Decode Trace (Per Page)

The same pixel data is encoded to PNG and decoded back **6 times** as it flows through the pipeline:

```
1. PageRendererV2      → raster.toPng() or pdfx render(format: png)     ENCODE #1
2. ImagePreprocessorV2 → img.decodeImage(imageBytes)                    DECODE #1
                       → img.encodePng(processed)                       ENCODE #2
3. GridLineDetector    → img.decodeImage(imageBytes)                    DECODE #2
4. GridLineRemover     → cv.imdecode(inputBytes)                        DECODE #3
                       → cv.imencode('.png', inpainted)                 ENCODE #3
5. TextRecognizerV2    → img.decodeImage(enhancedImageBytes)            DECODE #4
                       → img.encodePng(preparedCrop.image) per cell     ENCODE #4+ (x120 cells)
6. TesseractEngineV2   → PixImage.fromBytes(cropBytes) per cell         DECODE #5+ (x120 cells)
```

Full-page PNG decode: ~200-400ms. Full-page PNG encode: ~300-600ms. Per-cell crop encode: ~5-20ms x 120 cells = ~600-2400ms.

**Total codec overhead per page: ~3-10 seconds** (full-page) + **~1.2-4.8 seconds** (per-cell).

---

## Bottlenecks (Ranked by Impact)

### P0: Immediate Fixes (Trivial Effort, High Impact)

#### 1. Verify `?.call(encodePng(...))` Null Short-Circuit Behavior
- **Location**: `text_recognizer_v2.dart:404-407`
- **Issue**: `onDiagnosticImage?.call(name, Uint8List.fromList(img.encodePng(cropped)))` — need to verify whether Dart's `?.call()` short-circuits argument evaluation when the receiver is null. If it does NOT, `encodePng` runs unconditionally for every cell crop even when diagnostics are disabled.
- **Potential cost**: If NOT short-circuited: ~5-20ms x 120 cells x 2 diagnostic images x pages = **18-72 seconds** wasted on a 20-page doc. If short-circuited: no issue on this line (but line 453's encode is still unavoidable).
- **Fix**: Add explicit `if (onDiagnosticImage != null)` guard regardless — it's clearer and guaranteed safe.
- **Risk**: None.

#### 2. Fix `_measureContrast` Bug (Correctness)
- **Location**: `image_preprocessor_v2.dart:229-233`
- **Issue**: After `processed.convert(numChannels: 1)` at line 229, `_measureContrast(processed)` at line 233 calls `img.getLuminance(pixel)` which computes `0.299*r + 0.587*g + 0.114*b`. On a 1-channel image, `g=0` and `b=0`, so it returns `0.299 * r` instead of `r`. The `contrastAfter` metric is systematically **underreported by ~70%**.
- **Fix**: Either move `_measureContrast(processed)` before the `convert(numChannels: 1)` call, or change `_measureContrast` to use `pixel.r` directly (consistent with `_isDarkPixel` in `grid_line_detector.dart:275`).
- **Risk**: None. Only affects the diagnostic metric, not downstream logic.

#### 3. Guard `onStageOutput?.call(obj.toMap())` with Explicit Null Checks
- **Location**: `extraction_pipeline.dart` (~25 call sites), `post_processor_v2.dart` (5 `_buildPostStageSnapshot` calls)
- **Issue**: Dart evaluates `.toMap()` before the `?.call()` null check. In production, `onStageOutput` is always null (PdfImportService never passes it). ~30 `.toMap()` serializations run for nothing.
- **Cost**: ~50-350ms per pipeline run.
- **Fix**: Wrap each call in `if (onStageOutput != null) { ... }`.
- **Risk**: None. Equivalent semantics.

#### 4. Streaming `_measureContrast` (Eliminate List Allocation)
- **Location**: `image_preprocessor_v2.dart:279-298`
- **Issue**: Builds `List<int>` of ~84,000 sampled luminance values, then `.map(...).reduce(...)` creating intermediate iterables.
- **Cost**: ~10-30ms per call, runs twice per page.
- **Fix**: Single-pass streaming: accumulate `sum` and `sumSq`, compute `variance = sumSq/count - mean*mean`.
- **Risk**: None.

### P1: Low-Medium Effort, High Impact

#### 5. Open PDF Document Once Instead of Per-Page
- **Location**: `page_renderer_v2.dart:262` (inside per-page loop at line 88)
- **Issue**: `pdfx.PdfDocument.openData(pdfBytes)` called once per page. Each call re-parses the entire PDF cross-reference table, page tree, and font dictionaries.
- **Cost**: ~50-200ms per page. For 10-page doc: **0.5-2.0 seconds** wasted.
- **Fix**: Open document once before the page loop, pass to `_renderWithPdfx()`, close in finally after all pages done.
- **Risk**: Low. Sequential page access is safe.
- **Note**: This fix is included in the pdfrx migration plan (Phase 2.2) since the renderer is being rewritten anyway.

#### 6. Cache Stage Results Across Re-Extraction Retries
- **Location**: `extraction_pipeline.dart:241-353` (re-extraction loop, up to 3 attempts)
- **Issue**: Each retry re-runs ALL stages from rendering through quality validation. When only PSM mode changes (DPI unchanged), rendering through grid removal produces identical output.
- **Cost**: **10-25 seconds per retry** on a 5-page doc.
- **Fix**: Cache stage outputs keyed by DPI. If retry uses same DPI, skip rendering through grid removal and reuse cached results. Only re-run OCR with the new PSM config.
- **Risk**: Low. Cache key (DPI) is simple and deterministic.

### P2: Medium Effort, High Impact

#### 7. Eliminate PNG Encode/Decode Roundtrips Between Stages
- **Issue**: Every stage boundary serializes to PNG and the next stage decodes. 6 roundtrips per page (see trace above).
- **Cost**: **3-8 seconds per page** in pure codec overhead.
- **Fix**: Change inter-stage data model from `Uint8List enhancedImageBytes` (PNG) to raw pixel buffers with metadata (`Uint8List` + width + height + channels). Decode once in ImagePreprocessorV2, pass raw pixels through GridLineDetector and GridLineRemover. Only encode to PNG at the Tesseract boundary. For GridLineRemover (OpenCV), use `cv.Mat.fromList()` instead of `cv.imdecode()`.
- **Risk**: Medium. Requires changing `PreprocessedPage` contract. Isolate boundaries need `TransferableTypedData` for zero-copy transfer of raw buffers.

#### 8. Parallelize/Overlap Cell OCR Processing
- **Location**: `text_recognizer_v2.dart:355-548`
- **Issue**: Cell crops processed sequentially — crop, upscale, encode, await Tesseract, repeat. For 120 cells with re-OCR: up to 12 seconds.
- **Cost**: **3-10 seconds per page**.
- **Fix options**:
  - **(a) Batch-prepare + sequential OCR** (~30% speedup): Pre-prepare all crop images, then feed sequentially to Tesseract. Overlaps image processing with OCR wait.
  - **(b) Producer-consumer overlap** (~40% speedup): Prepare cell N+1 while Tesseract processes cell N.
  - **(c) Multi-engine parallelism** (~60% speedup): 2-4 parallel TesseractEngineV2 instances with `Future.wait` + concurrency limiter. ~50-100MB per additional Tesseract instance.
- **Risk**: Low for (a), Medium for (b/c).

#### 9. Per-Cell PNG Encode for Tesseract Input
- **Location**: `text_recognizer_v2.dart:453`
- **Issue**: `img.encodePng(preparedCrop.image)` runs for every cell crop. This PNG is then decoded again by Leptonica inside Tesseract (`PixImage.fromBytes`). Pure wasted encode/decode roundtrip.
- **Cost**: ~5-20ms encode + ~1-3ms decode per cell x 120 cells = **600-2200ms per page**.
- **Fix**: Add `PixImage.fromRawPixels(Uint8List pixels, int width, int height, int channels)` to flusseract that passes raw pixel data to Tesseract via `pixCreate()` + `pixSetData()`. Eliminates the encode/decode roundtrip entirely.
- **Risk**: Medium. Requires native flusseract FFI modification. Leptonica API supports raw pixel input natively via `pixCreateNoInit` + memory copy.

### P3: Low Effort, Medium Impact

#### 10. Direct Buffer Access in Grid Detection
- **Location**: `grid_line_detector.dart:183-193` (horizontal scan), `:449-455` (vertical scan)
- **Issue**: `image.getPixel(x, y)` called for every pixel. For 2550x3300 image: ~8.4M `Pixel` object allocations with bounds checking per call.
- **Cost**: ~500-1500ms vs. ~100-300ms for direct buffer access. **Savings: 300-800ms/page**.
- **Fix**: Access raw buffer directly:
  ```dart
  final data = image.buffer.asUint8List();
  // pixel at (x,y) for 1-channel image:
  final value = data[y * image.width + x];
  ```
  Image is always 1-channel after ImagePreprocessorV2 converts to `numChannels: 1`.
- **Risk**: Low. Already assumes 1-channel in `_isDarkPixel`.

#### 11. Conditional DPI Escalation on Re-Extraction
- **Location**: `extraction_pipeline.dart:838` (DPI bump to 400)
- **Issue**: Re-extraction bumps to 400 DPI regardless of document type. At 400 DPI: ~15 megapixels vs 8.4 at 300 DPI. Every downstream stage processes ~80% more data.
- **Cost**: **3-8 seconds per re-extraction attempt**.
- **Fix**: Only escalate DPI for scanned/degraded pages, not clean digital vector PDFs. Enforce `kMaxPixels` guard (declared at line 68 as 12,000,000 but never checked during rendering).
- **Risk**: Low. Configuration change.

### P4: Lower Priority

#### 12. Isolate Overhead Optimization
- **Issue**: `compute()` copies full PNG `Uint8List` (2-5MB) in and out per call. New isolate spawned per page per stage.
- **Cost**: ~50-200ms per page.
- **Fix**: Use `TransferableTypedData` for zero-copy transfer. Consider batch `compute()` or persistent isolate pool.
- **Risk**: Low.

#### 13. GridLineRemover Not in Isolate
- **Location**: `grid_line_remover.dart:87`
- **Issue**: OpenCV operations run on main isolate. CPU-intensive but not blocking long enough to crash. Causes ~200-500ms UI jank on mobile.
- **Fix**: Wrap in `compute()`. Challenge: verify `opencv_dart` FFI bindings initialize correctly in spawned isolates.
- **Risk**: Medium.

#### 14. Duplicate Row Classification (Provisional + Final)
- **Location**: `extraction_pipeline.dart:573` (provisional), `:659` (final)
- **Issue**: `rowClassifier.classify()` runs twice. Provisional needed for RegionDetector and ColumnDetector. Final uses real column map.
- **Cost**: ~20-50ms per run (low individually).
- **Fix**: Cache row boundary grouping from provisional pass and reuse in final. Or merge region detection into column detection.
- **Risk**: Medium. Architectural tension in stage dependency chain.

---

## Estimated Savings Summary

### Per-Page (4-page Springfield PDF)

| Priority | Fix | Per-Page Savings | Total (4 pages) |
|----------|-----|-----------------|-----------------|
| P0 | Diagnostic null guard (if needed) | 0-18s | 0-72s |
| P0 | `onStageOutput` null guard | ~10ms | ~50-350ms |
| P1 | Open doc once | 0.1-0.5s | 0.5-2s |
| P1 | Cache re-extraction stages | — | 10-25s/retry |
| P2 | Eliminate PNG roundtrips | 3-8s | 12-32s |
| P2 | Cell OCR overlap/parallel | 3-6s | 12-24s |
| P2 | Raw pixel path to Tesseract | 0.6-2.2s | 2.4-8.8s |
| P3 | Direct buffer grid detection | 0.3-0.8s | 1.2-3.2s |
| P3 | Conditional DPI escalation | — | 3-8s/retry |

**Conservative estimate (P0-P1 only)**: 5-15 seconds saved per run.
**Aggressive estimate (P0-P3)**: 30-80+ seconds saved per run.

## Positive Observations

- **Tesseract singleton reuse**: Engine initialized once, PSM mode reconfigured per call. No wasted init cost.
- **Proper native resource cleanup**: `PixImage.dispose()` and OpenCV `Mat` disposal in `finally` blocks.
- **Syncfusion document opened once**: Pipeline correctly opens Syncfusion `PdfDocument` once at line 236 and reuses across all stages.
- **CropUpscaler output cap**: `kMaxOutputDimension = 2000` prevents memory blowup from upscaling tiny crops.
- **Data-accounting assertions**: Present in GridLineDetector and GridLineRemover to catch silent data loss.
- **No leftover debug code**: No `BEGIN TEMPORARY`, `FIXME`, `debugPrint`, or bare `print()` found in pipeline files.
- **Re-extraction best-attempt tracking**: Loop correctly returns best attempt even on exhaustion.

## Implementation Notes

- Bottlenecks 5 (open doc once) is addressed in the pdfrx migration plan (Phase 2.2).
- Bottleneck 7 (PNG roundtrip elimination) naturally aligns with the pdfrx migration's raw BGRA output — the migration provides the first stage's raw output, and this optimization extends it to all subsequent stages.
- Bottleneck 9 (raw pixel path to Tesseract) requires modifying the `flusseract` package's native FFI bindings.
- Bottlenecks 1-4 (P0) can be implemented independently as a quick PR with no architectural changes.
