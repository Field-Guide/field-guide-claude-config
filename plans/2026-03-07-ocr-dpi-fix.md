# Fix: Thread DPI to Tesseract in V2 OCR Engine

**Date**: 2026-03-07
**Priority**: HIGH — directly causes OCR accuracy regression on Android
**Effort**: Small (2 files, ~10 lines)

## Problem

The V2 OCR engine (`tesseract_engine_v2.dart`) computes source DPI via `_computeSourceDpi()` but **never passes it to Tesseract**. The V1 engine did this correctly via `tess.setVariable("user_defined_dpi", dpi)`.

### Impact
- Tesseract defaults to **70 DPI** on images that are actually **300 DPI** (4.3x mismatch)
- Page segmentation degrades: text regions misdetected, characters misread
- On **Windows tests**: `Printing.raster()` embeds DPI metadata in PNG → Tesseract auto-detects it → masks the bug
- On **Android device**: `pdfx` does NOT embed DPI metadata → Tesseract always hits 70 DPI fallback → degraded accuracy
- Causes intermittent OCR failures: "95" not recognized, "$177,135.00" → "$177.1 33.00", "50" → "S50"

### Evidence (device stage dumps vs fixtures, 2026-03-07)
- **Page 4 confidence**: device=0.950 vs fixture=0.960
- **Total OCR elements**: device=1238 vs fixture=1242 (4 fewer)
- **Items 94+95 merged**: OCR dropped item number "95" entirely
- **Item 96 amount zeroed**: "$177,135.00" misread as "$177.1 33.00"
- **Item 91 qty zeroed**: "50" misread as "S50"
- **Net financial impact**: $457,291 checksum discrepancy

## Root Cause Chain

```
pdfx renders page at 300 DPI (no DPI metadata in PNG)
  → V2 engine computes DPI = 300 via _computeSourceDpi()
  → V2 engine DOES NOT call tess.setVariable("user_defined_dpi", "300")
  → flusseract.cpp SetPixImage() checks user_defined_dpi → not set
  → flusseract.cpp checks embedded resolution → not present (pdfx)
  → Falls back to 70 DPI (line 105 of flusseract.cpp)
  → Tesseract processes 300 DPI image as if it were 70 DPI
  → Page segmentation and character recognition degraded
```

## Fix

### Phase 1: Thread DPI to Tesseract (the fix)

**File**: `lib/features/pdf/services/extraction/ocr/tesseract_engine_v2.dart`

#### Change 1: `recognizeImage()` (line ~70, before `hocrText` call)

Add DPI variable after PSM/whitelist setup:

```dart
// Apply PSM per call so reused engine instance can switch modes.
tess.setPageSegMode(cfg.pageSegMode);
tess.setWhiteList(cfg.whitelist ?? '');

// NEW: Tell Tesseract the actual DPI of this image
final sourceDpi = _computeSourceDpi(renderSize, pageSize);
tess.setVariable('user_defined_dpi', sourceDpi.toString());
```

#### Change 2: `recognizeCrop()` (line ~114, before `hocrText` call)

Add DPI variable, using `effectiveDpi` when available (crop upscaler provides this):

```dart
// Apply PSM per call so reused engine instance can switch modes.
tess.setPageSegMode(cfg.pageSegMode);
tess.setWhiteList(cfg.whitelist ?? '');

// NEW: Tell Tesseract the actual DPI of this crop
final sourceDpi = effectiveDpi?.round() ?? _computeSourceDpi(renderSize, pageSize);
tess.setVariable('user_defined_dpi', sourceDpi.toString());
```

### Phase 2: Verify (test + device)

1. Run `flutter test test/features/pdf/extraction/golden/stage_trace_diagnostic_test.dart` — should still pass
2. Run `flutter test test/features/pdf/extraction/golden/springfield_golden_test.dart` — should still pass (or improve)
3. Deploy to device, re-import Springfield PDF
4. Pull stage dumps, re-run `tools/compare_stage_dumps.py`
5. **Expected**: page 4 confidence ≥0.960, total elements ≥1242, 131 items, checksum match

### Phase 3: Cleanup (after verification)

1. Remove temporary stage dump code from `pdf_import_service.dart` (marked with `BEGIN TEMPORARY` / `END TEMPORARY`)
2. Delete `tools/compare_golden.py` and `tools/compare_stage_dumps.py`
3. Delete `Troubleshooting/device_stage_dumps/`

## Files Modified

| File | Change | Lines |
|------|--------|-------|
| `lib/features/pdf/services/extraction/ocr/tesseract_engine_v2.dart` | Add `setVariable("user_defined_dpi", ...)` to both `recognizeImage()` and `recognizeCrop()` | ~70, ~114 |

## Files NOT Modified

- `packages/flusseract/` — C++ already handles `user_defined_dpi` correctly (lines 95-108)
- `pdfx` — replaced by `pdfrx` in renderer migration (2026-03-08). DPI fix remains as defensive code; the renderer divergence (pdfx AOSP fork vs upstream PDFium) was the actual root cause of the $457K OCR discrepancy, not the DPI threading bug
- Pipeline stages — all deterministic given OCR input; fixing the input fixes everything downstream
- Test fixtures — should still pass; may want to regenerate after verifying improvement

## Risk Assessment

- **Low risk**: `setVariable` is an existing API used elsewhere (whitelist, blacklist, debug file)
- **No behavioral change on Windows**: Tesseract already auto-detects DPI from Printing.raster metadata; setting it explicitly is a no-op when the value matches
- **Positive change on Android**: Tesseract goes from 70 DPI → 300 DPI (correct), improving all segmentation
- **For upscaled crops**: Goes from 70 DPI → 600 DPI (correct), matching the actual crop resolution

## Validation Criteria

- [ ] Stage trace test passes
- [ ] Golden test passes
- [ ] Device extraction: 131 items (not 130)
- [ ] Device checksum: $0 discrepancy (not $457K)
- [ ] Device page 4 confidence ≥ 0.960
- [ ] No regressions on other test PDFs
