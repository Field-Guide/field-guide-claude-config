# Table-Bounded Text Protection Dilation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Restrict text protection dilation to within detected grid table bounds, preventing boilerplate text outside the table from inflating OCR elements and confusing the row classifier.
**Spec:** Research-driven (no separate spec file)
**Analysis:** `.claude/dependency_graphs/2026-03-12-table-bounded-text-protection/`

**Architecture:** Single-file change in grid_line_remover.dart. Computes table bounding rect from existing sortedH/sortedV data, creates a mask, ANDs with textPixels before dilation. Falls back to global protection for degenerate grids.
**Blast Radius:** 1 direct, 0 dependent, 6 tests to verify, 0 cleanup

---

## Phase 1: Implement Table-Bounded Text Protection

### Sub-phase 1.1: Add table bounds mask to `_removeGridLines()`

**Files:**
- Modify: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart`

**Agent**: pdf-agent

#### Step 1.1.1: Add `tableBoundsMask` to native object tracking (line ~306)

Add the new Mat variable to the nullable tracking list at the top of `_removeGridLines()`.

**Find this code** (around line 306-311):
```dart
  cv.Mat? textPixels;
  cv.Mat? textDilateKernel;
  cv.Mat? textProtection;
  cv.Mat? notTextProtection;
  cv.Mat? removalMask;
  cv.Mat? maskedRemovalMask;
```

**Replace with:**
```dart
  cv.Mat? textPixels;
  cv.Mat? tableBoundsMask;  // WHY: Restricts text protection to table interior
  cv.Mat? boundedTextPixels;  // WHY: textPixels AND'd with tableBoundsMask
  cv.Mat? textDilateKernel;
  cv.Mat? textProtection;
  cv.Mat? notTextProtection;
  cv.Mat? removalMask;
  cv.Mat? maskedRemovalMask;
```

**WHY:** Every `cv.Mat` allocated must be tracked for disposal in the finally block. Declaring them here ensures they're in scope for both the try body and the finally cleanup.

#### Step 1.1.2: Add disposal for new Mats in finally block (line ~580-598)

**Find this code** (around line 586-589):
```dart
    textDilateKernel?.dispose();
    textProtection?.dispose();
    textPixels?.dispose();
    notGridMask?.dispose();
```

**Replace with:**
```dart
    textDilateKernel?.dispose();
    textProtection?.dispose();
    boundedTextPixels?.dispose();
    tableBoundsMask?.dispose();
    textPixels?.dispose();
    notGridMask?.dispose();
```

**WHY:** Dispose in reverse allocation order. `boundedTextPixels` and `tableBoundsMask` are allocated between `textPixels` and `textProtection`, so they must be disposed between them. If the table bounds guard falls back (hasTableBounds=false), these remain null and `?.dispose()` is a no-op.

#### Step 1.1.3: Move `white` Scalar initialization earlier (line ~478 and ~493)

The `white` Scalar is currently initialized at line 493, AFTER where the table bounds code needs it. Move it before the textPixels block so `cv.line` can use it for the filled rectangle.

**IMPORTANT: Apply this step BEFORE Step 1.1.4.** Step 1.1.4's code uses `white!` which requires this initialization to exist.

**Find this code** (around line 477-478):
```dart
    // gridMask = hMask | vMask (all morphologically-detected grid pixels)
    gridMask = cv.bitwiseOR(hMask, vMask);
```

**Replace with:**
```dart
    // gridMask = hMask | vMask (all morphologically-detected grid pixels)
    gridMask = cv.bitwiseOR(hMask, vMask);

    // WHY: Initialize white Scalar early -- needed by both table bounds mask
    // drawing (Step 1.1.4) and removal mask line drawing below.
    white = cv.Scalar(255, 0, 0, 0);
```

**Also**, remove the now-duplicate `white` initialization from line ~493.

**Find this code** (around line 491-493):
```dart
    // Build removal mask from merged line coordinates.
    removalMask = cv.Mat.zeros(rows, cols, cv.MatType.CV_8UC1);
    white = cv.Scalar(255, 0, 0, 0);
```

**Replace with:**
```dart
    // Build removal mask from merged line coordinates.
    removalMask = cv.Mat.zeros(rows, cols, cv.MatType.CV_8UC1);
```

**WHY:** The `white` Scalar is used by `cv.line` when drawing the filled rectangle for table bounds. It must exist before the table bounds block executes. Moving it here is safe because it's already tracked in the finally block for disposal. Single allocation, single disposal -- no leak.

#### Step 1.1.4: Insert table bounds computation and masking (line ~482-487)

This is the core change. Insert the table bounds logic AFTER `textPixels` is computed (line 482) and BEFORE the dilation at line 486-487.

**Find this code** (lines 480-487):
```dart
    // textPixels = binary & ~gridMask (dark pixels that are NOT grid lines)
    notGridMask = cv.bitwiseNOT(gridMask);
    textPixels = cv.bitwiseAND(binary, notGridMask);

    // textProtection = dilate(textPixels, 5x5 rect kernel)
    // FROM SPEC: "2px safety margin"
    textDilateKernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
    textProtection = cv.dilate(textPixels, textDilateKernel);
```

**Replace with:**
```dart
    // textPixels = binary & ~gridMask (dark pixels that are NOT grid lines)
    notGridMask = cv.bitwiseNOT(gridMask);
    textPixels = cv.bitwiseAND(binary, notGridMask);

    // WHY: Restrict text protection to within the detected table bounds.
    // Text outside the table (headers, footers, page numbers, boilerplate)
    // was inflating OCR element count (1411->1625) and confusing the row
    // classifier (203/324 boilerplate). By masking textPixels to the table
    // interior before dilation, only text within table cells gets protection.
    //
    // Degenerate guard: need at least 2 H-lines (top/bottom) and 2 V-lines
    // (left/right) to define table bounds. Falls back to global protection
    // (original behavior) when the grid is too sparse.
    final hasTableBounds = sortedH.length >= 2 && sortedV.length >= 2;
    final cv.Mat textForDilation;

    if (hasTableBounds) {
      // Compute table bounding rectangle in pixel coordinates.
      // sortedH/sortedV are already sorted by position (line 359-360).
      final tableTop = (sortedH.first.position * rows).round();
      final tableBottom = (sortedH.last.position * rows).round();
      final tableLeft = (sortedV.first.position * cols).round();
      final tableRight = (sortedV.last.position * cols).round();

      // WHY: Expand by half the max line width + 3px safety margin.
      // This ensures text that touches the outer border lines (which have
      // nonzero width) is still within the mask. The +3 accounts for
      // the 5x5 dilation kernel radius (2px) + 1px rounding tolerance.
      final maxLineWidth = math.max(
        sortedH.map((l) => l.widthPixels).reduce(math.max),
        sortedV.map((l) => l.widthPixels).reduce(math.max),
      );
      final margin = maxLineWidth ~/ 2 + 3;

      // Clamp to image bounds.
      final clampedTop = math.max(0, tableTop - margin);
      final clampedBottom = math.min(rows - 1, tableBottom + margin);
      final clampedLeft = math.max(0, tableLeft - margin);
      final clampedRight = math.min(cols - 1, tableRight + margin);

      // Build table bounds mask: white rectangle on black background.
      // WHY: Use cv.line with full-height thickness to draw a filled
      // rectangle. This avoids depending on cv.rectangle which may not
      // be available in all opencv_dart builds. OpenCV's line() with
      // large thickness draws a filled rectangle centered on the line.
      // +2 on thickness ensures full coverage even with even heights
      // (OpenCV centers even-thickness lines asymmetrically by 1px).
      tableBoundsMask = cv.Mat.zeros(rows, cols, cv.MatType.CV_8UC1);
      final midY = (clampedTop + clampedBottom) ~/ 2;
      final rectHeight = clampedBottom - clampedTop + 2; // +2 for even-height safety
      cv.Point? rectP1;
      cv.Point? rectP2;
      try {
        rectP1 = cv.Point(clampedLeft, midY);
        rectP2 = cv.Point(clampedRight, midY);
        cv.line(tableBoundsMask!, rectP1, rectP2, white!, thickness: rectHeight);
      } finally {
        rectP2?.dispose();
        rectP1?.dispose();
      }

      // AND textPixels with table bounds mask: only text inside the table survives.
      boundedTextPixels = cv.bitwiseAND(textPixels, tableBoundsMask!);
      textForDilation = boundedTextPixels!;
    } else {
      // FALLBACK: Degenerate grid (< 2 H or < 2 V lines).
      // Use global text protection (original v3 behavior).
      textForDilation = textPixels;
    }

    // textProtection = dilate(textForDilation, 5x5 rect kernel)
    // FROM SPEC: "2px safety margin"
    textDilateKernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
    textProtection = cv.dilate(textForDilation, textDilateKernel);
```

**WHY annotations embedded in code above explain each decision:**
- Table bounds from first/last sorted lines = proven reliable detector data
- Margin = maxLineWidth/2 + 3 covers border line width + dilation radius + rounding
- `cv.line` with large thickness fills a rectangle (avoids unverified `cv.rectangle` API)
- `+2` on rectHeight ensures full coverage for even-height rectangles (OpenCV's even-thickness centering asymmetry)
- Degenerate guard preserves backward compatibility for edge cases
- `textForDilation` avoids duplicating the dilate call for both branches
- `textForDilation` is NOT a new allocation -- it's a reference to either `boundedTextPixels` or `textPixels`, both of which are tracked for disposal separately

### Sub-phase 1.2: Add `tableBoundsApplied` metric

**Agent**: pdf-agent

#### Step 1.2.1: Add metric to per-page metrics map

The implementing agent should know whether the table bounds optimization fired. Add a boolean metric to the per-page metrics map.

**Find this code** (around line 131-145, inside the try block of the page loop):
```dart
        perPageMetrics['$pageIndex'] = {
          'has_grid': true,
          'processed': true,
          'mask_pixels': processed.maskPixels,
          'mask_coverage_ratio': processed.maskCoverage,
          // WHY: v3 morph/hough metrics replace matched-filter scores
          'morph_h_segments': processed.morphHSegments,
          'morph_v_segments': processed.morphVSegments,
          'hough_accepted': processed.houghAccepted,
          'hough_rejected': processed.houghRejected,
          'hough_fallback_lines': processed.houghFallbackLines,
          'text_protection_pixels': processed.textProtectionPixels,
          'foreground_fraction': processed.foregroundFraction,
          'inpaint_applied': true,
        };
```

**Replace with:**
```dart
        perPageMetrics['$pageIndex'] = {
          'has_grid': true,
          'processed': true,
          'mask_pixels': processed.maskPixels,
          'mask_coverage_ratio': processed.maskCoverage,
          // WHY: v3 morph/hough metrics replace matched-filter scores
          'morph_h_segments': processed.morphHSegments,
          'morph_v_segments': processed.morphVSegments,
          'hough_accepted': processed.houghAccepted,
          'hough_rejected': processed.houghRejected,
          'hough_fallback_lines': processed.houghFallbackLines,
          'text_protection_pixels': processed.textProtectionPixels,
          'table_bounds_applied': processed.tableBoundsApplied,
          'foreground_fraction': processed.foregroundFraction,
          'inpaint_applied': true,
        };
```

#### Step 1.2.2: Add `tableBoundsApplied` field to `_GridRemovalResult`

**Find this code** (around line 248-249):
```dart
  final int textProtectionPixels; // Pixels in text protection mask
  final double foregroundFraction; // countNonZero(binary) / (h*w) — threshold health check
```

**Replace with:**
```dart
  final int textProtectionPixels; // Pixels in text protection mask
  final bool tableBoundsApplied;  // Whether table bounds mask restricted text protection
  final double foregroundFraction; // countNonZero(binary) / (h*w) — threshold health check
```

And update the constructor accordingly.

**Find this code** (around line 266-268):
```dart
    required this.textProtectionPixels,
    required this.foregroundFraction,
```

**Replace with:**
```dart
    required this.textProtectionPixels,
    required this.tableBoundsApplied,
    required this.foregroundFraction,
```

#### Step 1.2.3: Pass `hasTableBounds` into the result constructor

**Find this code** (around line 574):
```dart
      textProtectionPixels: textProtectionPixels,
      foregroundFraction: foregroundFraction,
```

**Replace with:**
```dart
      textProtectionPixels: textProtectionPixels,
      tableBoundsApplied: hasTableBounds,
      foregroundFraction: foregroundFraction,
```

---

## Phase 2: Verify Existing Tests Pass

### Sub-phase 2.1: Run unit tests

**Agent**: qa-testing-agent

#### Step 2.1.1: Run all Flutter unit tests

```powershell
pwsh -Command "flutter test"
```

**Expected:** All existing tests pass. The morph tests, contract tests, and remover tests should all still pass because:
- No API surface changed
- Degenerate guard (< 2 lines) falls back to global protection
- Synthetic test images with >= 2 H and >= 2 V lines will now use table bounds, but the table covers the entire grid so behavior is equivalent
- Tests with 1 H-line and 2 V-lines (or similar) fall back to global protection

**If tests fail:** Check whether any test uses a grid with >= 2 H and >= 2 V lines but places text blocks OUTSIDE the table bounds rectangle. Such text would no longer be protected. If this happens, either:
1. Move the text block inside the table bounds in the test fixture, OR
2. Add the test to the "expected behavior change" list (text outside tables should NOT be protected -- that's the whole point)

---

## Phase 3: Verify Pipeline Improvement

### Sub-phase 3.1: Run Springfield pipeline report

**Agent**: qa-testing-agent

#### Step 3.1.1: Run integration test on Windows

```powershell
pwsh -Command "flutter test integration_test/springfield_report_test.dart --timeout 600s"
```

**Expected output changes from baseline (35/131 items, 212/329 boilerplate, 1601 OCR elements):**
- OCR element count should DECREASE (fewer boilerplate text fragments protected and surviving inpainting)
- Boilerplate row count should DECREASE (fewer external text rows parsed)
- Item match count should be EQUAL or HIGHER (table text unchanged or improved)
- `table_bounds_applied: true` should appear in per-page metrics for all 6 grid pages

**Record the new metrics.** This is empirical verification -- if OCR elements don't decrease, Option C may need to be combined with other improvements (the user's hypothesis about boilerplate inside table bounds would be confirmed).

#### Step 3.1.2: Run grid removal diagnostic test

```powershell
pwsh -Command "flutter test integration_test/grid_removal_diagnostic_test.dart --timeout 600s"
```

**Expected:** Diagnostic images generated at `test/features/pdf/extraction/diagnostics/`. Visual inspection should show:
- Text protection mask is now bounded to the table region
- No text protection outside the table area (headers, footers, page numbers)

---

## Adversarial Review Notes

### Code Review Findings
| Severity | Finding | Resolution |
|----------|---------|------------|
| **MEDIUM** | `cv.line` even-thickness centering asymmetry could miss 1px at table edge | Added `+2` to `rectHeight` in Step 1.1.4. The margin already provides +3px buffer, so this is double-safe. |
| **MEDIUM** | `textProtectionPixels` metric changes meaning (now table-bounded, not global) | Acceptable. The metric now reflects the actual protection applied. Add `table_bounds_applied` boolean metric (Step 1.2.1) so consumers can distinguish. |
| **LOW** | Step ordering: Step 1.1.3 (`white` init) must run before Step 1.1.4 (table bounds uses `white!`) | Fixed: Reordered to 1.1.3 first, added explicit note in plan. |
| **LOW** | `textForDilation` is a local Mat reference, not a new allocation | Correct by design. Added WHY comment in Step 1.1.4 code. No disposal needed for the reference itself. |

### Security Review Findings
| Severity | Finding | Resolution |
|----------|---------|------------|
| **PASS** | Input validation: `sortedH/sortedV` positions clamped 0.0-1.0 by `GridLine` constructor | No action needed. |
| **PASS** | Image bounds clamping: `math.max(0,...)` / `math.min(rows-1,...)` prevents out-of-bounds | No action needed. |
| **PASS** | Mat disposal: `tableBoundsMask` and `boundedTextPixels` tracked in finally block | No action needed. |
| **PASS** | Point disposal: `rectP1`/`rectP2` disposed in scoped try/finally | No action needed. |
| **PASS** | Degenerate guard: `hasTableBounds` check prevents reduce-on-empty-list crash | `sortedH.length >= 2` guarantees `.reduce(math.max)` has input. |
| **PASS** | No privilege escalation or data leak vectors in image processing change | No action needed. |

---

## Rollback Plan

If Option C produces worse results or breaks tests:

1. Revert Step 1.1.3 (remove the table bounds block, restore original textPixels -> dilate flow)
2. Revert Step 1.1.4 (move `white` initialization back to after removalMask)
3. Revert Step 1.1.1 and 1.1.2 (remove tableBoundsMask/boundedTextPixels declarations and disposal)
4. Revert Step 1.2.* (remove tableBoundsApplied metric)

Total: 4 targeted reverts in 1 file. No downstream impact.

---

## Summary

| Property | Value |
|----------|-------|
| Total phases | 3 |
| Total steps | 10 (7 implementation + 3 verification) |
| Source files modified | 1 (`grid_line_remover.dart`) |
| Test files modified | 0 |
| New files created | 0 |
| Tests to verify | 6 (all existing) |
| Estimated implementation time | 15-20 minutes |
| Risk level | Low (single file, fallback guard, no API change) |
