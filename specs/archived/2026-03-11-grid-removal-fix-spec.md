# Grid Removal Fix + Unit Normalization (R1+R5)

**Date:** 2026-03-11
**Status:** Approved (post-adversarial review)
**Research:** `.claude/docs/research/2026-03-11-grid-removal-root-cause-analysis.md`
**Adversarial Review:** `.claude/adversarial_reviews/2026-03-11-grid-removal-fix/review.md`

---

## Overview

### Purpose
Eliminate grid line removal text damage (upstream cause of ~10 description FAILs, 2 MISS, 1 BOGUS, $280K checksum delta) by replacing morphological re-detection with intersection-anchored polyline masking + inpainting. Bundle R1 unit normalization fix (26 unit FAILs).

### Scope
**Included:**
- Introduce `GridLine` paired struct to replace parallel position/width arrays in `GridLineResult`
- Rewrite `GridLineRemover._removeGridLines()` — intersection-anchored polyline mask + inpaint(radius=1.0)
- Add minimal cell crop inset in `TextRecognizerV2._computeCellCrops()` — `ceil(lineWidth/2)` per edge
- Remove destructive aliases from `UnitRegistry.unitAliases` and LS-prefix fallback (R1)
- Update all 4 downstream `== 'LS'` checks to use new `isLumpSum()` helper
- Re-run pipeline report to measure impact

**Excluded:**
- R2 (row classifier for items 94/95) — deferred until post-measurement
- R3 (validation gate), R4 (math backsolve) — independent, not in this pass
- GridLineDetector changes — detector works correctly, no changes needed

### Measurement (not pass/fail gates)
The pipeline report test shows us results. We measure and adjust:
- Excess mask pixels (currently 25-38%)
- Unit accuracy (currently 79.8%)
- Description accuracy (currently 89.1%)
- Checksum delta (currently -$280K)
- Items 94/95 separation
- Regression count (currently 87 PASS)

---

## Data Model: GridLine Paired Struct

### Problem
`GridLineResult` uses parallel arrays (`horizontalLines` + `horizontalLineWidths`) where index alignment is fragile. Sorting positions (as `_computeCellCrops()` does) breaks the correspondence.

### Solution
Introduce a paired struct and replace parallel arrays:

```dart
class GridLine {
  final double position;   // normalized 0.0-1.0
  final int widthPixels;   // detected pixel thickness
  const GridLine({required this.position, required this.widthPixels});
}
```

`GridLineResult` changes:
```dart
// Before:
List<double> horizontalLines;
List<int> horizontalLineWidths;
List<double> verticalLines;
List<int> verticalLineWidths;

// After:
List<GridLine> horizontalLines;
List<GridLine> verticalLines;
```

### Consumer updates
All consumers change from `lines[i]` + `widths[i]` to `lines[i].position` + `lines[i].widthPixels`:
- `GridLineDetector` — output construction
- `GridLineRemover` — mask construction
- `TextRecognizerV2._computeCellCrops()` — crop boundaries + inset
- `SyntheticRegionBuilder` — table Y-bounds
- `GridLineColumnDetector` — column boundaries
- `grid_removal_diagnostic_test.dart` — diagnostic overlays
- `GridLineResult.fromMap()` / `toMap()` — serialization

### Files Changed
- `lib/features/pdf/services/extraction/models/grid_lines.dart` — add `GridLine` class, update `GridLineResult`
- `lib/features/pdf/services/extraction/stages/grid_line_detector.dart` — output `List<GridLine>` instead of parallel lists
- All consumers listed above

---

## Technical Design: Intersection-Anchored Polyline Mask

### Current Flow (being replaced)
```
_removeGridLines(imageBytes):
  decode → adaptive threshold → H-MORPH_OPEN → V-MORPH_OPEN
  → combine → dilate(3x3, 1iter) → inpaint(radius=2.0)
```

### New Flow
```
_removeGridLines(imageBytes, gridLineResult):
  1. decode image to sourceGray (cv.IMREAD_GRAYSCALE)
  2. create empty mask: cv.Mat.zeros(height, width, CV_8UC1)
  3. enumerate all intersections (H × V line pairs)
  4. for each intersection (approxX, approxY):
       scan ±10px window in sourceGray
       compute dark-pixel centroid → (refinedX, refinedY)
  5. for each horizontal line:
       collect refined Y at each vertical line's X → anchor points
       draw polyline mask: cv.line() between consecutive anchors
       thickness = line.widthPixels
  6. for each vertical line:
       collect refined X at each horizontal line's Y → anchor points
       draw polyline mask: cv.line() between consecutive anchors
       thickness = line.widthPixels
  7. inpaint(sourceGray, mask, radius=1.0, INPAINT_TELEA)
```

### Why Intersection Anchoring

The detector reports one center position per line for the entire page. But lines can drift ±1-3px locally. Instead of adding a static buffer, we **refine the actual line position at each grid intersection** by scanning the real pixels.

This gives us anchor points where we know the exact local center. The mask is drawn as connected line segments through these anchors, following the actual line path — even if it wobbles.

### Intersection Refinement Algorithm

```dart
// For each intersection of horizontal line H and vertical line V:
final approxX = (vLine.position * imageWidth).round();
final approxY = (hLine.position * imageHeight).round();
final halfWindow = max(hLine.widthPixels, vLine.widthPixels) * 2; // ~10px

// Scan dark pixels in window, compute centroid
int sumX = 0, sumY = 0, count = 0;
for (var y = max(0, approxY - halfWindow); y <= min(height - 1, approxY + halfWindow); y++) {
  for (var x = max(0, approxX - halfWindow); x <= min(width - 1, approxX + halfWindow); x++) {
    if (sourceGray.at<int>(y, x) < 128) {
      sumX += x; sumY += y; count++;
    }
  }
}
// refinedX, refinedY = centroid (or approx if no dark pixels found)
```

**Performance:** 7V × 20H = 140 intersections × ~441 pixel reads = 62K reads. Negligible (<1% of full-page scan cost, ~5ms).

### Mask Drawing

Use `cv.line()` between consecutive anchor points per line:

```dart
final mask = cv.Mat.zeros(imageHeight, imageWidth, cv.MatType.CV_8UC1);
final white = cv.Scalar(255, 0, 0, 0);

// For each horizontal line through its refined anchor points:
for (var i = 0; i < anchors.length - 1; i++) {
  cv.line(mask, anchors[i], anchors[i + 1], white,
    thickness: hLine.widthPixels);
}
```

`cv.line()` applies thickness perpendicular to line direction — confirmed available in `dartcv4 2.2.1+3` with all parameters forwarded correctly.

### Edge Cases in Mask Construction

1. **Edge clamping** — All pixel coordinates MUST be clamped to `[0, dimension-1]` BEFORE any `cv.Mat` operation or `cv.line()` call. This is a hard requirement, not a design note.

2. **Width array length guard** — Assert `grid.horizontalLines` is non-empty before iterating. The `GridLine` struct eliminates the parallel-array mismatch risk.

3. **Fallback** — If an intersection refinement finds zero dark pixels (degenerate case), use the unrefined approximate position.

4. **Lines extending beyond intersection range** — Horizontal lines extend from the leftmost to rightmost vertical line. Add extension segments from page edge to first/last vertical line at the nearest refined Y.

### Key Changes

| Aspect | Before | After |
|--------|--------|-------|
| Mask source | Morphological re-detection | Intersection-refined polyline anchors |
| Mask precision | ~25-38% excess | Follows actual line path |
| Drift handling | None (fixed center) | Per-intersection centroid refinement |
| Dilation | 3x3, 1 iteration | None |
| Inpaint radius | 2.0 | 1.0 |
| Detector data used | `hasGrid` boolean only | positions, widths, hasGrid |
| Drawing API | Morphological ops | `cv.line()` per segment |

### Removed Code
- Adaptive threshold, MORPH_OPEN (H + V), mask dilation
- Constants: `_adaptiveBlockSize`, `_adaptiveC`, `_kernelDivisor`, `_maskDilateIterations`
- `_GridRemovalResult` fields: `horizontalKernelWidth`, `verticalKernelHeight` (replaced with actual mask metrics)

### Files Changed
- `lib/features/pdf/services/extraction/stages/grid_line_remover.dart` — rewrite `_removeGridLines()`, update `remove()` to pass `GridLineResult`

---

## Cell Crop Inset

### Current Behavior
`TextRecognizerV2._computeCellCrops()` uses grid line center positions as exact crop boundaries — half the grid line pixels are included in the OCR input.

### New Behavior
Per-edge inset of `ceil(line.widthPixels / 2)` using each boundary line's actual detected width.

```
leftEdge   = vLines[i].position * imageWidth   + ceil(vLines[i].widthPixels / 2)
rightEdge  = vLines[i+1].position * imageWidth - ceil(vLines[i+1].widthPixels / 2)
topEdge    = hLines[j].position * imageHeight  + ceil(hLines[j].widthPixels / 2)
bottomEdge = hLines[j+1].position * imageHeight - ceil(hLines[j+1].widthPixels / 2)
```

### Practical Impact (Springfield PDF)
- Vertical lines (4-6px): 2-3px inset per side → 4-6px lost per cell (~0.3-0.4% of cell width)
- Horizontal lines (1-3px): 1-2px inset per side → negligible
- Minimum possible footprint — exactly half the grid line rounded up

### Safety Guard
If cell dimension < 10px after insets, skip insets for that cell and use original boundaries.

### Sort Safety
With `GridLine` struct, sorting by position preserves width data automatically:
```dart
final sorted = [...gridPage.horizontalLines]..sort((a, b) => a.position.compareTo(b.position));
// sorted[i].widthPixels is correct for sorted[i].position
```

### Files Changed
- `lib/features/pdf/services/extraction/stages/text_recognizer_v2.dart` — update `_computeCellCrops()`

---

## Unit Normalization Fix (R1)

### Changes
1. **Remove destructive aliases** from `UnitRegistry.unitAliases` — delete LSUM→LS, SYD→SY, CYD→CY, SFT→SF, HOUR→HR
2. **Remove LS-prefix fallback** at `unit_registry.dart:81` — `if (upper.startsWith('LS') && upper.length > 2) return 'LS'` also converts LSUM→LS
3. **Keep `toUpperCase()`** — case normalization is acceptable
4. **Keep OCR artifact cleanup** — strip periods, pipes, brackets
5. **Create `UnitRegistry.isLumpSum()` helper** — accepts both `LS` and `LSUM`
6. **Update all 4 downstream `== 'LS'` checks** to use `isLumpSum()`:
   - `consistency_checker.dart:72`
   - `row_parser_v3.dart:247`
   - `post_process_utils.dart:305`
   - `post_processor_v2.dart:724`
7. **Double-normalization stays** — both call sites remain, now idempotent (just toUpperCase + artifact cleanup)

### Files Changed
- `lib/features/pdf/services/extraction/shared/unit_registry.dart` — remove aliases + LS fallback, add `isLumpSum()`
- `lib/features/pdf/services/extraction/stages/consistency_checker.dart` — use `isLumpSum()`
- `lib/features/pdf/services/extraction/stages/row_parser_v3.dart` — use `isLumpSum()`
- `lib/features/pdf/services/extraction/shared/post_process_utils.dart` — use `isLumpSum()`
- `lib/features/pdf/services/extraction/stages/post_processor_v2.dart` — use `isLumpSum()`

---

## Testing & Verification

### Verification Sequence
1. **Grid removal diagnostic test** — `integration_test/grid_removal_diagnostic_test.dart` on Windows. Compare diff images for excess reduction.
2. **Full pipeline report** — `integration_test/springfield_report_test.dart` on Windows. Compare scorecard against current baseline.
3. **Pipeline comparator** — `tools/pipeline_comparator.dart`. Diff old vs new, identify regressions.
4. **Android device baselines** — S21+ and S25 Ultra (if Windows clean).

### What We Measure
The pipeline report tells us the results. No rigid pass/fail gates — we measure, compare against the baseline (87 PASS / 42 FAIL / 2 MISS / 1 BOGUS), and adjust.

### Existing Infrastructure
No new test files needed — diagnostic test + pipeline report test cover everything.

---

## Edge Cases & Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Line drift beyond intersection range | Medium | Extend mask segments from page edge to first/last intersection at nearest refined Y |
| Intersection refinement finds no dark pixels | Very low | Fall back to unrefined approximate position |
| Character strokes overlap grid pixels | Medium | Crop inset excludes damage zone from OCR. Inpaint provides smooth fill. |
| Inpaint radius=1.0 minor artifacts | Low | Crop inset excludes influence zone |
| Detector misses a line entirely | Very low | Missed line stays in image, no worse than no removal |
| Degenerate cell after inset | None for Springfield | Safety guard: skip if <10px |
| `isLumpSum()` helper incomplete | Low | Grep codebase for all `== 'LS'` patterns during implementation |

### Not Fixed by This Spec
- Pure OCR character confusion (item 99: 5→S)
- Missing punctuation (items 52, 58, 59, 63, 65) — may improve, need to measure
- R2 classifier patches — deferred pending measurement

### Rollback
Simple `git checkout` of changed files. No schema/data/dependency changes.

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Removal strategy | Intersection-anchored polyline mask + inpaint | Follows actual line path, handles drift dynamically, no static buffers |
| Drift handling | Per-intersection centroid refinement | More accurate than fixed buffer, uses actual pixel data |
| Data model | `GridLine` paired struct | Eliminates sort-alignment bug class, clean API |
| Inpaint radius | 1.0 (down from 2.0) | Minimal influence zone, smooth healing |
| Crop inset | ceil(lineWidth/2) per edge | Minimum footprint, uses actual detector widths |
| Drawing API | `cv.line()` per segment | All params forwarded correctly (unlike `cv.polylines()` which drops lineType/shift) |
| R2 timing | Fix R5 first, measure, decide | Root cause is upstream — R2 may be unnecessary |
| R1 bundling | Include in same pass | Trivial, independent, 26 free PASSes |
| R1 scope | Remove aliases + LS-prefix fallback + update 4 downstream checks | Adversarial review found the fallback and downstream `== 'LS'` gaps |
| Alternatives rejected | Pure white fill (no healing), minimal morph fix (still imprecise), simple rectangle mask (doesn't handle drift) |

---

## Files Changed (Summary)

| File | Change |
|------|--------|
| `models/grid_lines.dart` | Add `GridLine` struct, update `GridLineResult` to use `List<GridLine>` |
| `stages/grid_line_detector.dart` | Output `List<GridLine>` instead of parallel lists |
| `stages/grid_line_remover.dart` | Rewrite: intersection-anchored polyline mask + inpaint(1.0) |
| `stages/text_recognizer_v2.dart` | Add per-edge crop inset, sort-safe with `GridLine` struct |
| `shared/unit_registry.dart` | Remove destructive aliases + LS fallback, add `isLumpSum()` |
| `stages/consistency_checker.dart` | Use `isLumpSum()` instead of `== 'LS'` |
| `stages/row_parser_v3.dart` | Use `isLumpSum()` instead of `== 'LS'` |
| `shared/post_process_utils.dart` | Use `isLumpSum()` instead of `== 'LS'` |
| `stages/post_processor_v2.dart` | Use `isLumpSum()` instead of `== 'LS'` |
| `pipeline/synthetic_region_builder.dart` | Update for `GridLine` struct access pattern |
| `stages/column_detector_v2.dart` | Update for `GridLine` struct access pattern |
| `integration_test/grid_removal_diagnostic_test.dart` | Update for `GridLine` struct access pattern |

---

## Adversarial Review Resolutions

| Finding | Resolution |
|---------|-----------|
| MF1: Grid center drift | Resolved by intersection-anchored refinement — no static buffer needed |
| MF2: Sort destroys width alignment | Resolved by `GridLine` paired struct |
| MF3: Downstream `== 'LS'` checks | Added `isLumpSum()` helper + 4 call site updates |
| MF4: LS-prefix fallback | Added to removal scope |
| MF5: Width array length guard | Eliminated by `GridLine` struct (no parallel arrays) |
| MF6: Explicit pixel clamping | Made hard requirement in spec |
| SC1: White fill vs inpaint | Kept inpaint — provides smooth healing + drift coverage |
| SC3: Items 94/95 criterion | Changed to measurement, not pass/fail gate |
| SC4: Paired struct | Adopted as `GridLine` struct |
| SC5: Dead fields cleanup | Added to scope — remove morphological metric fields |
