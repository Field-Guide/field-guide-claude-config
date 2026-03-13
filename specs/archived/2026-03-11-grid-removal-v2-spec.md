# Grid Removal v2 — Endpoint-Anchored Straight-Line Masking

**Date:** 2026-03-11
**Status:** Approved
**Supersedes:** `.claude/specs/2026-03-11-grid-removal-fix-spec.md` (polyline approach — regression confirmed)
**Research:** `.claude/docs/research/2026-03-11-grid-removal-verification-report.md`
**Drift Measurement:** `integration_test/grid_line_drift_test.dart`

---

## Overview

### Purpose
Fix the grid removal regression (81/131 → target 130+/131) by replacing the current intersection-refined polyline masking with endpoint-anchored straight-line masking. Each grid line is measured at its first and last perpendicular intersection, then masked with a single straight line between those two points. This handles the real ~0.04° tilt from PDF rendering while eliminating the polyline zigzag, page-edge extension, and crop inset problems.

### Scope
**Included:**
- Rewrite `GridLineRemover._removeGridLines()` — endpoint-anchored straight lines
- Revert crop insets in `TextRecognizerV2._computeCellCrops()` to center-to-center
- Matched filter window expansion (`lineWidth + 2`) for better endpoint measurement
- Remove page-edge extension logic entirely

**Excluded:**
- GridLine struct changes (already done in Session 540, keeping)
- Unit normalization R1 (already done in Session 540, keeping)
- Deskewing (research confirms harmful at 0.04° angle)
- Run-length intersection skipping (v2 enhancement, not needed now)

### Success Criteria
- Pipeline report: 130+/131 items (matching or exceeding pre-rewrite baseline)
- Excess mask pixels: <5% per page (down from 10-35%)
- No page-edge text damage on Page 0

---

## Background: Drift Measurement

Grid lines in rendered PDF pages show a smooth monotonic tilt caused by PDFium's scan-conversion mapping floating-point PDF coordinates to integer pixels.

Measured on Springfield PDF (all 6 pages):
- H-lines: avg max drift **1.8px**, worst **4.6px** over ~2550px width
- V-lines: avg max drift **3.3px**, worst **6.8px** over ~3300px height
- Average angle: **~0.04°** (well below 0.5° deskewing threshold)
- Pattern: monotonic (smooth linear tilt), NOT zigzag/noise

A single straight line from first to last perpendicular intersection tracks this linear tilt accurately.

---

## Technical Design: Endpoint-Anchored Straight-Line Masking

### Current Flow (being replaced)
```
For each line:
  1. At every perpendicular intersection, scan ±10px window
  2. Compute dark-pixel centroid → refined anchor point
  3. Draw polyline through ALL anchors (cv.line between consecutive pairs)
  4. Extend polyline to page edges
```

### New Flow
```
For each line:
  1. Find first and last perpendicular intersection positions
  2. At each: scan matched-filter strip (lineWidth + 2) to find actual center
  3. Draw ONE cv.line() from first anchor to last anchor
  4. thickness = lineWidth (no expansion)
```

### Endpoint Measurement Algorithm

For a **horizontal line H** at its intersection with the **first vertical line V[0]**:
```
sampleX = V[0].position * imageWidth
approxY = H.position * imageHeight
Scan strip: x ∈ [sampleX - stripHalfW, sampleX + stripHalfW]
            y ∈ [approxY - maxDrift, approxY + maxDrift]
bandHeight = H.widthPixels + 2  (captures anti-aliasing fringe)
Slide band vertically, score = count of dark pixels (value < 128)
Best-scoring Y = endpoint anchor
```

Same at **last vertical line V[last]** → second endpoint anchor. Draw `cv.line(mask, anchor1, anchor2, white, thickness: H.widthPixels)`.

Mirror logic for vertical lines (sample at first/last H-line, scan horizontally).

### Sampling at Intersections

Previous implementation sampled at cell midpoints to avoid perpendicular line contamination. For endpoints, we sample AT the first/last perpendicular line. Contamination is handled by the matched filter — the perpendicular line's dark pixels are present at ALL candidate positions in the scan window, so they contribute equal score to every band and don't shift the maximum.

### Fallback
If matched filter score < 35% of theoretical max, fall back to detector's global position for that endpoint.

### Key Differences from Previous Implementation

| Aspect | Previous (polyline) | New (straight line) |
|--------|-------------------|-------------------|
| Anchor points per line | ~20-29 (every intersection) | **2** (first + last) |
| Mask shape | Polyline (zigzags with noise) | Single straight line |
| Page-edge extension | Extended to page edge | **None** — starts/ends at outermost perpendicular |
| Filter window | lineWidth | **lineWidth + 2** (anti-alias fringe) |
| Fallback threshold | 50% | **35%** |
| Wobble risk | High (each anchor adds noise) | **Zero** (straight line) |

### Edge Cases

1. **Only 1 perpendicular line detected** — both endpoints at same position. Draw a single-point line at measured position.
2. **Matched filter finds no dark pixels** — fall back to detector position for that endpoint.
3. **Edge clamping** — all pixel coordinates clamped to `[0, dimension-1]` before any cv.Mat operation.

---

## Crop Insets — Revert to Center-to-Center

### Current Behavior (causing regression)
`TextRecognizerV2._computeCellCrops()` adds `ceil(widthPixels/2)` per edge after inpainting. Since lines are already inpainted away, this cuts 3-6px of clean background/text per cell. Result: +216 OCR elements, 26 re-OCR attempts, 50 missed items.

### New Behavior
Revert to center-to-center crop boundaries (old behavior). After inpainting, the half-line zone is clean white background that provides natural padding around text.

```
leftEdge   = vLines[i].position * imageWidth
rightEdge  = vLines[i+1].position * imageWidth
topEdge    = hLines[j].position * imageHeight
bottomEdge = hLines[j+1].position * imageHeight
```

### Rationale
- No table extraction library does inpaint-then-trim
- Tesseract wants 10px white border — center-to-center after inpainting provides ~2-3px naturally
- Old morphological approach used center-to-center and got 130/131 items

---

## Files Changed

| File | Change |
|------|--------|
| `stages/grid_line_remover.dart` | Rewrite `_removeGridLines()`: endpoint-anchored straight lines. Remove page-edge extension. Matched filter window `lineWidth + 2`. Fallback threshold 50% → 35%. |
| `stages/text_recognizer_v2.dart` | Revert `_computeCellCrops()` to center-to-center boundaries. Remove per-edge inset logic. |

### Code Removed
- All intersection refinement loop (iterating every H×V pair for centroid)
- Page-edge extension segments (both H and V directions)
- Cell-center matched filter multi-anchor logic (replaced with 2-endpoint measurement)
- Crop inset calculations in `_computeCellCrops()`

### Code Kept (from Session 540)
- `GridLine` paired struct and all consumer updates
- Unit normalization R1 (`isLumpSum()` helper + 4 downstream fixes)
- `cv.line()` drawing with correct thickness
- Inpaint radius 1.0 + TELEA
- `_GridRemovalResult` updated fields

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Line shape | Straight line (2 endpoints) | Drift is monotonic/linear; polyline adds noise without improving accuracy |
| Endpoint location | At first/last perpendicular intersection | Natural grid boundary; no page-edge extension needed |
| Filter window | lineWidth + 2 | Anti-aliasing fringe extends 1-2px beyond nominal stroke; improves center measurement |
| Mask thickness | Exact lineWidth | Research: over-masking damages adjacent text; mask should cover line body only |
| Fallback threshold | 35% (down from 50%) | Research: 30-50% range for binary images; 35% catches faint lines at page edges |
| Crop insets | Center-to-center (revert) | Lines are inpainted; half-line zone is clean background providing natural OCR padding |
| Deskewing | Not used | 0.04° angle is 10x below practical threshold; interpolation artifacts worse than drift |
| Polyline | Rejected | 2-29 anchors introduce cumulative noise; straight line is more accurate for linear tilt |

---

## Testing & Verification

Same infrastructure — no new test files needed:
1. **Diagnostic test** — `integration_test/grid_removal_diagnostic_test.dart` on Windows. Visual check of mask overlay/diff images.
2. **Pipeline report** — `integration_test/springfield_report_test.dart` on Windows. Target: 130+/131 items.
3. **Pipeline comparator** — `tools/pipeline_comparator.dart` to diff against baseline.
4. **Android baselines** — S21+ and S25 Ultra after Windows is clean.

### Rollback
Simple `git checkout` of the two modified files. No schema/data/dependency changes.
