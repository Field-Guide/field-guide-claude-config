# Grid Line Removal Adaptive Threshold Fix

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Fix the grid line removal adaptive threshold that masks ~77% of the page (should be ~2%), damaging OCR text and causing 3 item failures.
**Spec:** Investigation conducted in Session 523 via systematic-debugging skill (no separate spec file)
**Analysis:** `.claude/dependency_graphs/2026-03-08-grid-line-threshold-fix/`

**Architecture:** Single constant change in `grid_line_remover.dart` flips `_adaptiveC` from -2.0 to a positive value, so the adaptive threshold properly separates dark text/lines from light background. All downstream OCR stages benefit automatically.
**Tech Stack:** OpenCV (`opencv_dart`), Tesseract OCR, Dart/Flutter
**Blast Radius:** 1 direct, 0 dependent code changes, 30+ fixture regenerations, 2 test updates

---

## Context

### Problem
The `GridLineRemover` stage (2B-ii.6) uses OpenCV `adaptiveThreshold` with `C = -2.0`. With `THRESH_BINARY_INV`, this computes: `T(x,y) = mean(15x15 block) + 2`. On a clean white-background PDF, background pixels (~250) are below this threshold and become WHITE in the binary image along with text and grid lines. Result: ~77% of all page pixels are in the inpainting mask instead of the expected ~2%.

The TELEA inpainting reconstructs most text from surrounding pixels, but fails on specific characters:
- **Item 96**: Comma in "$177,133.00" damaged → misread as period → Tesseract word-splits → `"$177.1 33.00"` → null bid_amount → $177K checksum gap → quality 0.918
- **Item 121**: "Private" → "ae" (conf 0.40) — first word destroyed by inpainting
- **Item 130**: "Pavt" → "i" (conf 0.40) — first word destroyed by inpainting

### Root Cause
`_adaptiveC = -2.0` (line 15 of `grid_line_remover.dart`). The sign is wrong. With `ADAPTIVE_THRESH_MEAN_C` + `THRESH_BINARY_INV`:
- `C` negative → threshold ABOVE local mean → background included in mask
- `C` positive → threshold BELOW local mean → only dark features (text + lines) in binary

### Fix
Change `_adaptiveC` from `-2.0` to `+2.0` (or tune to 5-15 if needed). This makes the binary image contain only text and grid lines, so the morphological opening (85px horizontal / 109px vertical kernels) detects actual grid lines and nothing else. Expected mask coverage drops from ~77% to ~2%.

### Evidence
- `springfield_grid_line_removal.json`: mask_coverage_ratio 73-83% across all 6 pages
- Expected for grid lines only: ~1.7% (7h + 7v lines x 3-4px / 8.4M pixels)
- Items 121/130 garbled elements have 2x normal bounding box height + confidence 0.40
- Item 96 comma→period misread consistent with partial pixel reconstruction

---

## Dependency Graph

### Direct Change
| Symbol | File | Line | Impact |
|--------|------|------|--------|
| `_adaptiveC` | `lib/features/pdf/services/extraction/stages/grid_line_remover.dart` | 15 | MODIFY |

### Callers (no code changes needed — behavior improves automatically)
| Symbol | File | Line | Impact |
|--------|------|------|--------|
| `_removeGridLines()` | `grid_line_remover.dart` | 210 | Uses `_adaptiveC` |
| `GridLineRemover.remove()` | `grid_line_remover.dart` | 27 | Calls `_removeGridLines` |
| `ExtractionPipeline._runExtractionStages()` | `extraction_pipeline.dart` | 508 | Calls `remove()` |

### Tests
| File | Status | Action |
|------|--------|--------|
| `test/.../stages/grid_line_remover_test.dart` | EXISTS | Add mask coverage sanity assertion |
| `test/.../golden/springfield_benchmark_test.dart` | EXISTS | Re-run after fixture regen |
| `test/.../golden/stage_trace_diagnostic_test.dart` | EXISTS | Re-run after fixture regen |
| `test/.../pipeline/extraction_pipeline_test.dart` | EXISTS | Uses MockGridLineRemover — NOT affected |

### Fixtures to Regenerate (30+ files)
All `test/features/pdf/extraction/fixtures/springfield_*.json` — regenerated via:
```
pwsh -Command "flutter test integration_test/generate_golden_fixtures_test.dart --dart-define=SPRINGFIELD_PDF='C:\Users\rseba\OneDrive\Desktop\864130 Springfield DWSRF Water System Improvements CTC [16-23] Pay Items.pdf' -d windows"
```

---

## Phase 0: Pre-Change Baseline

**Agent**: `pdf-agent`

### Step 0.1: Run existing unit tests to confirm green baseline

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/grid_line_remover_test.dart -r expanded"`
Expected: All 4 tests PASS

### Step 0.2: Run existing golden scorecard to confirm current baseline

Run: `pwsh -Command "flutter test test/features/pdf/extraction/golden/springfield_benchmark_test.dart -r expanded"`
Expected: Scorecard shows 68 OK / 2 LOW / 1 BUG (current known state)

---

## Phase 1: Fix Adaptive Threshold

**Agent**: `pdf-agent`

**Files:**
- Modify: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart:15`

### Step 1.1: Change `_adaptiveC` from -2.0 to +2.0

```dart
// WHY: With THRESH_BINARY_INV, C is subtracted from the local mean to get the threshold.
// C = -2.0 → T = mean + 2 → background pixels (250) are BELOW threshold → included in mask
// C = +2.0 → T = mean - 2 → background pixels (250) are ABOVE threshold → excluded from mask
// This fixes the mask from covering ~77% of the page to only ~2% (actual grid lines).
const double _adaptiveC = 2.0;
```

File: `lib/features/pdf/services/extraction/stages/grid_line_remover.dart`
Line 15: change `-2.0` to `2.0`

That's it. One constant. The morphological kernels (85px horizontal, 109px vertical) and inpainting radius (2px) are correctly tuned — they just need a proper binary mask to work with.

### Step 1.2: Run grid_line_remover unit tests

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/grid_line_remover_test.dart -r expanded"`
Expected: All 4 tests PASS (tests use synthetic grid images that work with either C value)

---

## Phase 2: Add Mask Coverage Sanity Test

**Agent**: `pdf-agent`

**Files:**
- Modify: `test/features/pdf/extraction/stages/grid_line_remover_test.dart`

### Step 2.1: Add test asserting mask coverage is reasonable

Add a new test after the existing "processes grid pages" test (after line 127):

```dart
// WHY: Guard against regression — mask should only contain grid lines (~1-5%),
// not the entire page background (~77% was the bug). A synthetic image with
// 5 horizontal + 3 vertical lines on an 800x1000 canvas should produce
// coverage well under 10%.
test('mask coverage is reasonable for grid-only content', () async {
  final sourceBytes = _createGridImage(
    horizontalYs: const [0.15, 0.30, 0.45, 0.60, 0.75],
    verticalXs: const [0.2, 0.5, 0.8],
  );
  final page = _page(sourceBytes, pageIndex: 0);

  final (_, report) = await remover.remove(
    preprocessedPages: {0: page},
    gridLines: GridLines(
      pages: {
        0: const GridLineResult(
          pageIndex: 0,
          horizontalLines: [0.15, 0.30, 0.45, 0.60, 0.75],
          verticalLines: [0.2, 0.5, 0.8],
          hasGrid: true,
          confidence: 1.0,
        ),
      },
      detectedAt: DateTime.utc(2026, 2, 19),
    ),
  );

  final perPage = report.metrics['per_page'] as Map<String, dynamic>;
  final page0 = perPage['0'] as Map<String, dynamic>;
  final coverage = page0['mask_coverage_ratio'] as double;
  // Grid lines on an 800x1000 image: ~5h*3px*800 + ~3v*3px*1000 = 21,000px
  // Total pixels: 800,000. Expected ratio: ~2.6%. Allow up to 15% for dilation.
  // Lower bound: grid lines must still be detected (coverage > 0.5%)
  expect(coverage, greaterThan(0.005),
      reason: 'Mask should detect grid lines (not be empty)');
  // Upper bound: mask should not include background/text (coverage < 15%)
  expect(coverage, lessThan(0.15),
      reason: 'Mask should cover grid lines only, not background/text');
});
```

### Step 2.2: Run updated tests

Run: `pwsh -Command "flutter test test/features/pdf/extraction/stages/grid_line_remover_test.dart -r expanded"`
Expected: All 5 tests PASS (including new coverage test)

---

## Phase 3: Regenerate Golden Fixtures

**Agent**: `pdf-agent`

### Step 3.1: Regenerate all Springfield fixtures

Run:
```
pwsh -Command "flutter test integration_test/generate_golden_fixtures_test.dart --dart-define=SPRINGFIELD_PDF='C:\Users\rseba\OneDrive\Desktop\864130 Springfield DWSRF Water System Improvements CTC [16-23] Pay Items.pdf' -d windows"
```
Expected: All 30+ fixture JSON files regenerated in `test/features/pdf/extraction/fixtures/`

### Step 3.2: Verify mask coverage dropped in regenerated fixture

Read `test/features/pdf/extraction/fixtures/springfield_grid_line_removal.json` and verify:
- `mask_coverage_ratio_avg` is now < 0.10 (was 0.77)
- Per-page coverage is < 0.15 (was 0.73-0.83)

### Step 3.3: Verify item 96 bid_amount is now correct in parsed items

Read `test/features/pdf/extraction/fixtures/springfield_parsed_items.json` and verify:
- Item 96 `bid_amount` is `177133.0` (was `null`)
- Item 96 `raw_bid_amount` no longer contains a space

### Step 3.4: Verify items 121/130 descriptions are correct

Read `test/features/pdf/extraction/fixtures/springfield_parsed_items.json` and verify:
- Item 121 description starts with "Private" (was "ae")
- Item 130 description starts with "Pavt" (was "i")

---

## Phase 4: Run Golden Scorecard

**Agent**: `pdf-agent`

### Step 4.1: Run the benchmark scorecard

Run: `pwsh -Command "flutter test test/features/pdf/extraction/golden/springfield_benchmark_test.dart -r expanded"`
Expected: Scorecard improves from 68 OK / 2 LOW / 1 BUG to **70+ OK / 0 BUG**

### Step 4.2: Run the stage trace diagnostic

Run: `pwsh -Command "flutter test test/features/pdf/extraction/golden/stage_trace_diagnostic_test.dart -r expanded"`
Expected: PASS with improved checksum match

### Step 4.3: Run full test suite to check for regressions

Run: `pwsh -Command "flutter test"` (use Bash tool timeout: 600000)
Expected: All tests PASS (or same baseline failures as before)

---

## Phase 5: Tuning (if needed)

**Agent**: `pdf-agent`

> **Only execute this phase if Phase 3/4 show problems.**

If `C = 2.0` still produces too many non-line pixels in the mask (coverage > 10%), increase C.
If grid lines are not fully detected (coverage too low or lines remain visible after inpainting), decrease C toward 1.0.

Candidate values:
- `C = 5.0` — moderate separation
- `C = 10.0` — strong separation (common in document processing)
- `C = 15.0` — very aggressive (may miss faint/thin lines)

After each change, re-run Phase 3 Steps 3.1-3.4 and Phase 4 Step 4.1.

> **Note**: All verification is against the Springfield PDF. C=2.0 is conservative and should work for any clean digital PDF. Noisy scans with gray backgrounds may require further tuning.

The correct value produces:
1. mask_coverage < 10%
2. Grid lines fully removed (no visible lines in OCR crops)
3. Text undamaged (item 96 bid_amount correct, items 121/130 descriptions correct)
4. Scorecard: 68+ OK / 0 BUG

---

## Verification Summary

| Check | How | Expected |
|-------|-----|----------|
| Unit tests | `flutter test .../grid_line_remover_test.dart` | 5/5 PASS |
| Mask coverage fixture | Read `springfield_grid_line_removal.json` | avg < 0.10 |
| Item 96 bid_amount | Read `springfield_parsed_items.json` | `177133.0` (not null) |
| Item 121 description | Read `springfield_parsed_items.json` | Starts with "Private" |
| Item 130 description | Read `springfield_parsed_items.json` | Starts with "Pavt" |
| Scorecard | `flutter test .../springfield_benchmark_test.dart` | 70+ OK / 0 BUG |
| Full suite | `flutter test` | No regressions |
