# Implementation Plan: Grid-Aware Row Classification

## Goal
Pass existing `gridLines` to `RowClassifierV3.classify()` so that horizontal grid line positions serve as row boundaries instead of Y-proximity heuristics. This fixes the 137-grid-row to 329-classified-row fragmentation that drops 93/131 items.

## Analysis
- **Dependency graph**: `.claude/dependency_graphs/2026-03-12-grid-aware-row-classification/blast-radius.md`
- **Root cause**: `_groupElementsByRow()` uses `medianHeight * 0.35` Y-proximity threshold. OCR elements from the same grid row can have Y-position variance that exceeds this threshold, causing one grid row to split into 2-3 classified rows. Only 38 get classified as "data" while 212 become "boilerplate".
- **Fix**: When `gridLines` are available for a page, use horizontal line positions as definitive row boundaries. Each pair of consecutive H-lines defines a grid row. Elements whose `yCenter` falls between two H-lines belong to that row.

## Blast Radius Summary
| Category | Files | Description |
|----------|-------|-------------|
| DIRECT | 2 | row_classifier_v3.dart, extraction_pipeline.dart |
| DEPENDENT | 2 | mock_stages.dart, extraction_pipeline_test.dart (mock overrides) |
| TEST | 1 | row_classifier_v3_test.dart (new tests) |
| **Total** | **5** | |

## Ground Truth Baseline
- **Current**: 35/131 items (16.8%), 329 classified rows, 38 data rows
- **Expected**: ~131/131 items, ~137 classified rows matching grid rows
- **Pipeline test**: `integration_test/springfield_report_test.dart`
- **GT checksum**: $7,882,927

---

## Phase 1: Core Implementation (row_classifier_v3.dart)
**Agent**: `pdf-agent`
**Files**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart`

### Phase 1.1: Add gridLines parameter to classify()

**Step 1.1.1**: Add optional GridLines? parameter to classify() signature

**File**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart`
**Action**: Edit the `classify` method signature to accept optional gridLines

```dart
// WHY: GridLines is nullable because non-grid PDFs should fall back to
// existing Y-proximity grouping. Making it optional preserves backward
// compatibility — all existing callers continue to work without changes
// until they're explicitly wired up.
Future<(ClassifiedRows, StageReport)> classify({
  required UnifiedExtractionResult extractionResult,
  required ColumnMap columnMap,
  GridLines? gridLines,
}) async {
```

**Step 1.1.2**: Update the per-page loop to dispatch to grid-aware grouping when available

**File**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart`
**Action**: Replace the `_groupElementsByRow(pageElements)` call at line 79 with dispatch logic

Replace:
```dart
      final pageColumns = columnMap.columnsForPage(pageIndex);
      final zones = _computeZones(pageColumns);
      final pageRows = _groupElementsByRow(pageElements);
```

With:
```dart
      final pageColumns = columnMap.columnsForPage(pageIndex);
      final zones = _computeZones(pageColumns);

      // WHY: When grid lines are available for this page, use them as
      // definitive row boundaries instead of Y-proximity heuristics.
      // Grid H-lines give exact row boundaries; Y-proximity fragments
      // rows when OCR elements have slight Y-variance within the same
      // grid cell.
      final pageGridResult = gridLines?.pages[pageIndex];
      final List<List<OcrElement>> pageRows;
      if (pageGridResult != null &&
          pageGridResult.hasGrid &&
          pageGridResult.horizontalLines.length >= 2) {
        pageRows = _groupElementsByGridRows(
          pageElements,
          pageGridResult.horizontalLines,
        );
      } else {
        pageRows = _groupElementsByRow(pageElements);
      }
```

**NOTE**: The threshold `horizontalLines.length >= 2` ensures we have at least two H-lines (defining at least one row band). A single H-line provides no bands.

### Phase 1.2: Implement _groupElementsByGridRows()

**Step 1.2.1**: Add new method _groupElementsByGridRows()

**File**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart`
**Action**: Add new method after `_groupElementsByRow()` (after line 649)

```dart
  /// Groups OCR elements into rows using horizontal grid line positions.
  ///
  /// Each pair of consecutive horizontal lines defines a row band.
  /// Elements are assigned to the band whose Y-range contains their yCenter.
  /// Elements above the first H-line or below the last H-line are placed
  /// in edge bands (before-first, after-last).
  ///
  /// WHY: Grid line positions are exact (detected at pixel level in Stage
  /// 2B-ii.5), while Y-proximity heuristics use medianHeight * 0.35 which
  /// fragments rows when OCR elements have slight vertical scatter.
  /// Springfield: 137 grid rows -> 329 Y-proximity rows, but 137 -> ~137
  /// with grid-aware grouping.
  List<List<OcrElement>> _groupElementsByGridRows(
    List<OcrElement> elements,
    List<GridLine> horizontalLines,
  ) {
    if (elements.isEmpty) {
      return const <List<OcrElement>>[];
    }

    // NOTE: horizontalLines are already sorted by position (normalized Y)
    // per GridLineResult contract. Extract positions for band computation.
    final hPositions = horizontalLines.map((l) => l.position).toList();

    // Build N+1 bands from N horizontal lines:
    //   Band 0: [0.0, hPositions[0]]         - above first line
    //   Band i: [hPositions[i-1], hPositions[i]] - between consecutive lines
    //   Band N: [hPositions[N-1], 1.0]        - below last line
    //
    // WHY: Elements can exist above the first grid line (headers) or
    // below the last (totals). Edge bands capture these without losing them.
    final bandCount = hPositions.length + 1;
    final bands = List.generate(bandCount, (_) => <OcrElement>[]);

    // No pre-sort needed: band assignment is position-based (each element's
    // yCenter determines its band independently), unlike _groupElementsByRow
    // which requires sorted input for its sequential sweep.
    for (final element in elements) {
      final y = element.yCenter;
      int bandIndex = _findBandIndex(y, hPositions);
      bands[bandIndex].add(element);
    }

    // Convert to rows, preserving left-to-right order within each band.
    // Apply _splitRowWithMultipleItemNumbers for multi-item grid rows.
    // WHY: A single grid row may contain two item numbers stacked vertically
    // if the grid cell is tall. _splitRowWithMultipleItemNumbers handles this
    // by detecting multiple item-number anchors within one band.
    final rows = <List<OcrElement>>[];
    for (final band in bands) {
      if (band.isEmpty) continue;
      band.sort((a, b) => a.xCenter.compareTo(b.xCenter));
      rows.addAll(_splitRowWithMultipleItemNumbers(band));
    }

    return rows;
  }

  /// Find the band index for a Y position given sorted H-line positions.
  ///
  /// Returns 0 if y is above the first line, N if y is below the last line,
  /// or the index of the band between hPositions[i-1] and hPositions[i].
  ///
  /// Convention: elements at exactly a line position (y == hPositions[i])
  /// are assigned to the band BELOW the line (band i+1). This is consistent
  /// with the strict less-than comparison. In practice, text centers never
  /// land exactly on a line center because the grid line remover inpaints
  /// the line region, pushing text away from line centers.
  ///
  /// NOTE: Band boundaries use line center positions only; line widths
  /// (GridLine.widthPixels) are not factored in. Line thickness is typically
  /// 1-3px (~0.001-0.003 normalized), far smaller than text element heights
  /// (~0.01-0.02). If boundary misassignment is observed, widen bands by
  /// half the line width in a follow-up.
  int _findBandIndex(double y, List<double> hPositions) {
    // Linear scan is fine for typical grid pages (10-30 H-lines).
    // WHY: Binary search adds complexity for minimal gain when N < 50.
    // If profiling shows this is a bottleneck, switch to binary search.
    for (int i = 0; i < hPositions.length; i++) {
      if (y < hPositions[i]) {
        return i;
      }
    }
    return hPositions.length;
  }
```

### Phase 1.3: Add grid-aware metrics to the StageReport

**Step 1.3.1**: Add grid_aware_pages metric to the stage report

**File**: `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart`
**Action**: Track how many pages used grid-aware grouping vs Y-proximity

In the `classify()` method, add a counter before the per-page loop:

```dart
    var gridAwarePages = 0;
    var yProximityPages = 0;
```

After the dispatch decision (inside the per-page loop), increment the appropriate counter:

```dart
      if (pageGridResult != null &&
          pageGridResult.hasGrid &&
          pageGridResult.horizontalLines.length >= 2) {
        pageRows = _groupElementsByGridRows(
          pageElements,
          pageGridResult.horizontalLines,
        );
        gridAwarePages++;
      } else {
        pageRows = _groupElementsByRow(pageElements);
        yProximityPages++;
      }
```

Then add these to the `metrics` map in the StageReport:

```dart
        'grid_aware_pages': gridAwarePages,
        'y_proximity_pages': yProximityPages,
```

**Verification** (Phase 1 complete):
```
pwsh -Command "flutter test test/features/pdf/extraction/stages/row_classifier_v3_test.dart"
```
Expected: All existing tests pass (gridLines param is optional, defaults to null, so existing tests use Y-proximity path unchanged).

---

## Phase 2: Pipeline Wiring (extraction_pipeline.dart)
**Agent**: `pdf-agent`
**Files**: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`

### Phase 2.1: Wire gridLines to final classify() call

**Step 2.1.1**: Pass gridLines at extraction_pipeline.dart line 661

**File**: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`
**Action**: Add `gridLines: gridLines` to the final classify() call

Replace:
```dart
    final (classifiedRows, stage4AReport) = await rowClassifier.classify(
      extractionResult: extractionResult,
      columnMap: columnMap,
    );
```

With:
```dart
    // WHY: Pass gridLines so RowClassifierV3 can use horizontal line positions
    // as row boundaries on grid pages, fixing the 137->329 row fragmentation.
    final (classifiedRows, stage4AReport) = await rowClassifier.classify(
      extractionResult: extractionResult,
      columnMap: columnMap,
      gridLines: gridLines,
    );
```

**NOTE**: The local variable `gridLines` is already in scope at line 661 (created at line 480 in Stage 2B-ii.5). However, notice that the pipeline builds `ocrGridLines` at line 510 which adjusts for grid removal failures. For row classification, we want the **original** detected gridLines (not the OCR-adjusted version), because we need the original H-line positions as row boundaries. The `ocrGridLines` version zeroes out grid data for pages where removal failed, which would cause those pages to lose grid-aware grouping. Since grid removal failure doesn't affect line detection accuracy, using the original `gridLines` is correct.

### Phase 2.2: Wire gridLines to provisional classify() call

**Step 2.2.1**: Pass gridLines at extraction_pipeline.dart line 574

**File**: `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`
**Action**: Add `gridLines: gridLines` to the provisional classify() call

Replace:
```dart
    final (provisionalRows, _) = await rowClassifier.classify(
      extractionResult: extractionResult,
      columnMap: provisionalColumnMap,
    );
```

With:
```dart
    // WHY: Provisional classification also benefits from grid-aware grouping.
    // This improves region detection (Stage 4B) which depends on provisional rows.
    final (provisionalRows, _) = await rowClassifier.classify(
      extractionResult: extractionResult,
      columnMap: provisionalColumnMap,
      gridLines: gridLines,
    );
```

**Verification** (Phase 2 complete):
```
pwsh -Command "flutter test test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart"
```
Expected: All existing pipeline tests pass. The mock classifiers don't use gridLines but accept it (optional param in override).

---

## Phase 3: Update Mock Overrides
**Agent**: `qa-testing-agent`
**Files**: `test/features/pdf/extraction/helpers/mock_stages.dart`, `test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart`

### Phase 3.1: Update MockRowClassifierV3

**Step 3.1.1**: Add gridLines parameter to MockRowClassifierV3.classify()

**File**: `test/features/pdf/extraction/helpers/mock_stages.dart`
**Action**: Add optional `GridLines? gridLines` to the mock override

Replace:
```dart
class MockRowClassifierV3 extends RowClassifierV3 {
  @override
  Future<(ClassifiedRows, StageReport)> classify({
    required UnifiedExtractionResult extractionResult,
    required ColumnMap columnMap,
  }) async {
```

With:
```dart
class MockRowClassifierV3 extends RowClassifierV3 {
  @override
  Future<(ClassifiedRows, StageReport)> classify({
    required UnifiedExtractionResult extractionResult,
    required ColumnMap columnMap,
    GridLines? gridLines,
  }) async {
```

**NOTE**: The mock ignores gridLines -- it always returns a canned response. This is correct because mock tests verify pipeline orchestration, not classifier logic.

### Phase 3.2: Update _MixedPageRowClassifier

**Step 3.2.1**: Add gridLines parameter to _MixedPageRowClassifier.classify()

**File**: `test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart`
**Action**: Add optional `GridLines? gridLines` to the override

Replace:
```dart
class _MixedPageRowClassifier extends MockRowClassifierV3 {
  @override
  Future<(ClassifiedRows, StageReport)> classify({
    required UnifiedExtractionResult extractionResult,
    required ColumnMap columnMap,
  }) async {
```

With:
```dart
class _MixedPageRowClassifier extends MockRowClassifierV3 {
  @override
  Future<(ClassifiedRows, StageReport)> classify({
    required UnifiedExtractionResult extractionResult,
    required ColumnMap columnMap,
    GridLines? gridLines,
  }) async {
```

### Phase 3.3: Update _HeaderFragmentingRowClassifier

**Step 3.3.1**: Add gridLines parameter to _HeaderFragmentingRowClassifier.classify()

**File**: `test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart`
**Action**: Add optional `GridLines? gridLines` to the override

Replace:
```dart
class _HeaderFragmentingRowClassifier extends MockRowClassifierV3 {
  @override
  Future<(ClassifiedRows, StageReport)> classify({
    required UnifiedExtractionResult extractionResult,
    required ColumnMap columnMap,
  }) async {
```

With:
```dart
class _HeaderFragmentingRowClassifier extends MockRowClassifierV3 {
  @override
  Future<(ClassifiedRows, StageReport)> classify({
    required UnifiedExtractionResult extractionResult,
    required ColumnMap columnMap,
    GridLines? gridLines,
  }) async {
```

**Verification** (Phase 3 complete):
```
pwsh -Command "flutter test test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart"
```
Expected: All existing pipeline tests pass.

---

## Phase 4: Unit Tests for Grid-Aware Grouping
**Agent**: `qa-testing-agent`
**Files**: `test/features/pdf/extraction/stages/row_classifier_v3_test.dart`

### Phase 4.1: Add grid-aware grouping test group

**Step 4.1.1**: Add import for grid_lines.dart (if not already imported via models.dart)

**File**: `test/features/pdf/extraction/stages/row_classifier_v3_test.dart`
**Action**: Verify that the existing `models.dart` barrel export includes `grid_lines.dart`. It does (confirmed in analysis). No import changes needed.

**Step 4.1.2**: Add helper to create GridLines test fixtures

**File**: `test/features/pdf/extraction/stages/row_classifier_v3_test.dart`
**Action**: Add helper function after the existing `_CellSeed` class (after line 462)

```dart
/// Creates a GridLines fixture with the given horizontal line positions.
/// WHY: Simulates a grid page with known H-line positions for testing
/// that elements are grouped by grid bands rather than Y-proximity.
GridLines _gridLines({
  required List<double> horizontalPositions,
  List<double> verticalPositions = const [],
  int pageIndex = 0,
}) {
  return GridLines(
    pages: {
      pageIndex: GridLineResult(
        pageIndex: pageIndex,
        horizontalLines: horizontalPositions
            .map((p) => GridLine(position: p, widthPixels: 2))
            .toList(),
        verticalLines: verticalPositions
            .map((p) => GridLine(position: p, widthPixels: 2))
            .toList(),
        hasGrid: true,
        confidence: 0.95,
      ),
    },
    detectedAt: DateTime.now(),
  );
}
```

**Step 4.1.3**: Add test: grid-aware grouping keeps elements in same grid row together

**File**: `test/features/pdf/extraction/stages/row_classifier_v3_test.dart`
**Action**: Add test inside the existing `group('RowClassifierV3', () {` block

```dart
    test('grid-aware grouping keeps elements in same grid row together', () async {
      // WHY: This is the core regression test. Without grid-aware grouping,
      // elements at y=0.100 and y=0.118 would be split into 2 rows
      // (threshold = ~0.007). With grid lines at 0.08 and 0.13, both
      // elements fall in the same band and stay in one row.
      final extraction = _extraction([
        _rowAt(0.100, [
          _cell('1', 0.02, 0.10),
          _cell('Mobilization', 0.15, 0.50),
        ]),
        // Same grid row but slightly different Y (OCR scatter)
        _rowAt(0.118, [
          _cell('LS', 0.60, 0.66),
          _cell('1', 0.70, 0.76),
        ]),
      ]);

      // Grid lines bracket both elements in the same band: [0.08, 0.13]
      final grid = _gridLines(
        horizontalPositions: [0.08, 0.13, 0.18, 0.23],
      );

      final (classified, report) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        gridLines: grid,
      );

      // All 4 elements should be in a single row (same grid band)
      expect(classified.rows.length, 1);
      expect(classified.rows.first.elements.length, 4);
      expect(classified.rows.first.type, RowType.data);
      expect(report.metrics['grid_aware_pages'], 1);
      expect(report.metrics['y_proximity_pages'], 0);
    });
```

**Step 4.1.4**: Add test: grid-aware grouping separates elements in different grid rows

```dart
    test('grid-aware grouping separates elements in different grid rows', () async {
      // WHY: Elements in adjacent grid rows must NOT be merged, even if
      // Y-proximity would group them (e.g., bottom of row 1 and top of
      // row 2 are close together).
      final extraction = _extraction([
        _rowAt(0.12, [
          _cell('1', 0.02, 0.10),
          _cell('Mobilization', 0.15, 0.50),
        ]),
        _rowAt(0.17, [
          _cell('2', 0.02, 0.10),
          _cell('Traffic control', 0.15, 0.50),
        ]),
      ]);

      // Grid line at 0.15 separates the two rows
      final grid = _gridLines(
        horizontalPositions: [0.08, 0.15, 0.22],
      );

      final (classified, _) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        gridLines: grid,
      );

      expect(classified.rows.length, 2);
      expect(classified.rows[0].elements.length, 2);
      expect(classified.rows[1].elements.length, 2);
    });
```

**Step 4.1.5**: Add test: falls back to Y-proximity when no grid lines for page

```dart
    test('falls back to Y-proximity when no grid lines for page', () async {
      // WHY: Non-grid pages (or pages not in gridLines.pages) must use
      // the existing Y-proximity algorithm to avoid regressions.
      final extraction = _extraction([
        _rowAt(0.10, [
          _cell('1', 0.02, 0.10),
          _cell('Mobilization', 0.15, 0.50),
          _cell('LS', 0.60, 0.66),
          _cell('1', 0.70, 0.76),
        ]),
      ]);

      // Grid lines for page 5, but our data is on page 0 -> no grid for page 0
      final grid = _gridLines(
        horizontalPositions: [0.08, 0.15],
        pageIndex: 5,
      );

      final (classified, report) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        gridLines: grid,
      );

      expect(classified.rows.length, 1);
      expect(classified.rows.first.type, RowType.data);
      expect(report.metrics['grid_aware_pages'], 0);
      expect(report.metrics['y_proximity_pages'], 1);
    });
```

**Step 4.1.6**: Add test: falls back to Y-proximity when gridLines is null

```dart
    test('falls back to Y-proximity when gridLines is null', () async {
      // WHY: Backward compatibility. Callers that don't pass gridLines
      // must get identical behavior to pre-change code.
      final extraction = _extraction([
        _rowAt(0.10, [
          _cell('1', 0.02, 0.10),
          _cell('Mobilization', 0.15, 0.50),
          _cell('LS', 0.60, 0.66),
          _cell('1', 0.70, 0.76),
        ]),
      ]);

      final (classified, report) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        // gridLines omitted (null)
      );

      expect(classified.rows.length, 1);
      expect(classified.rows.first.type, RowType.data);
      expect(report.metrics['grid_aware_pages'], 0);
      expect(report.metrics['y_proximity_pages'], 1);
    });
```

**Step 4.1.7**: Add test: edge bands capture elements above first / below last H-line

```dart
    test('edge bands capture elements above first and below last H-line', () async {
      // WHY: Header elements typically sit above the first H-line, and
      // total elements below the last. They must not be silently dropped.
      final extraction = _extraction([
        // Above first H-line (header)
        _rowAt(0.03, [
          _cell('ITEM', 0.02, 0.10),
          _cell('DESCRIPTION', 0.15, 0.40),
          _cell('UNIT', 0.60, 0.66),
        ]),
        // In grid band
        _rowAt(0.12, [
          _cell('1', 0.02, 0.10),
          _cell('Mobilization', 0.15, 0.50),
        ]),
        // Below last H-line (total)
        _rowAt(0.90, [
          _cell('TOTAL BID', 0.20, 0.50),
          _cell('\$7,882,926.73', 0.90, 0.99),
        ]),
      ]);

      final grid = _gridLines(
        horizontalPositions: [0.08, 0.15, 0.22],
      );

      final (classified, _) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        gridLines: grid,
      );

      // 3 bands with elements: above-first, between 0.08-0.15, below-last
      expect(classified.rows.length, 3);
      // Verify all elements accounted for
      final totalElements = classified.rows.fold<int>(
        0, (sum, row) => sum + row.elements.length,
      );
      expect(totalElements, 8);
    });
```

**Step 4.1.8**: Add test: grid page with hasGrid=false falls back to Y-proximity

```dart
    test('grid page with hasGrid=false falls back to Y-proximity', () async {
      // WHY: A page might be in gridLines.pages but have hasGrid=false
      // (e.g., grid detection confidence was too low). Must fall back.
      final extraction = _extraction([
        _rowAt(0.10, [
          _cell('1', 0.02, 0.10),
          _cell('Mobilization', 0.15, 0.50),
        ]),
      ]);

      final grid = GridLines(
        pages: {
          0: GridLineResult(
            pageIndex: 0,
            horizontalLines: const [],
            verticalLines: const [],
            hasGrid: false,
            confidence: 0.2,
          ),
        },
        detectedAt: DateTime.now(),
      );

      final (classified, report) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        gridLines: grid,
      );

      expect(classified.rows.length, 1);
      expect(report.metrics['grid_aware_pages'], 0);
      expect(report.metrics['y_proximity_pages'], 1);
    });
```

**Step 4.1.9**: Add test: single H-line falls back to Y-proximity

```dart
    test('single horizontal line falls back to Y-proximity', () async {
      // WHY: With only 1 H-line, we can't form meaningful bands.
      // The >= 2 threshold ensures at least one real inter-line band.
      final extraction = _extraction([
        _rowAt(0.10, [
          _cell('1', 0.02, 0.10),
          _cell('Mobilization', 0.15, 0.50),
        ]),
      ]);

      final grid = _gridLines(
        horizontalPositions: [0.50], // Only 1 line
      );

      final (classified, report) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        gridLines: grid,
      );

      expect(classified.rows.length, 1);
      expect(report.metrics['grid_aware_pages'], 0);
      expect(report.metrics['y_proximity_pages'], 1);
    });
```

**Step 4.1.10**: Add test: multi-item grid row is split by _splitRowWithMultipleItemNumbers

```dart
    test('multi-item grid row triggers _splitRowWithMultipleItemNumbers', () async {
      // WHY: A tall grid row may contain two items stacked vertically.
      // _splitRowWithMultipleItemNumbers detects multiple item-number
      // anchors and splits the band into sub-rows.
      final extraction = _extraction([
        // Two items in the same grid band (between 0.08 and 0.20)
        _rowAt(0.10, [
          _cell('1', 0.02, 0.10),
          _cell('Mobilization', 0.15, 0.50),
          _cell('LS', 0.60, 0.66),
          _cell('1', 0.70, 0.76),
        ]),
        _rowAt(0.16, [
          _cell('2', 0.02, 0.10),
          _cell('Traffic control', 0.15, 0.50),
          _cell('LS', 0.60, 0.66),
          _cell('1', 0.70, 0.76),
        ]),
      ]);

      // Single wide grid band containing both items
      final grid = _gridLines(
        horizontalPositions: [0.08, 0.20, 0.30],
      );

      final (classified, _) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        gridLines: grid,
      );

      // _splitRowWithMultipleItemNumbers should split the single band into 2 rows
      expect(classified.rows.length, greaterThanOrEqualTo(2));
    });
```

**Step 4.1.11**: Add test: element at exact grid line position goes to band below

```dart
    test('element at exact grid line position is assigned to band below', () async {
      // WHY (FROM REVIEW MEDIUM-1): Verifies the boundary convention.
      // An element with yCenter exactly at a grid line position (0.15)
      // should go to the band below the line, not above.
      final extraction = _extraction([
        _rowAt(0.12, [
          _cell('1', 0.02, 0.10),
          _cell('Above line', 0.15, 0.50),
        ]),
        // Element exactly ON the grid line at 0.15
        _rowAt(0.15, [
          _cell('2', 0.02, 0.10),
          _cell('On line', 0.15, 0.50),
        ]),
        _rowAt(0.18, [
          _cell('3', 0.02, 0.10),
          _cell('Below line', 0.15, 0.50),
        ]),
      ]);

      // Grid line at exactly 0.15
      final grid = _gridLines(
        horizontalPositions: [0.08, 0.15, 0.22],
      );

      final (classified, _) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        gridLines: grid,
      );

      // Item 1 (y=0.12) -> band [0.08, 0.15) = band 1
      // Item 2 (y=0.15) -> band [0.15, 0.22) = band 2 (at line position, goes below)
      // Item 3 (y=0.18) -> band [0.15, 0.22) = band 2
      expect(classified.rows.length, 2);
      // First row has item 1 only
      expect(classified.rows[0].elements.length, 2);
      // Second row has items 2 and 3 (both in band 2)
      expect(classified.rows[1].elements.length, 4);
    });
```

**Step 4.1.12**: Add test: data loss assertion still holds with grid-aware grouping

```dart
    test('data loss assertion holds: input elements == output elements', () async {
      // WHY: The Stage 4A data loss check (line 143-147) must still pass.
      // Grid-aware grouping must not lose or duplicate any elements.
      final extraction = _extraction([
        _rowAt(0.10, [
          _cell('1', 0.02, 0.10),
          _cell('Mobilization', 0.15, 0.50),
        ]),
        _rowAt(0.20, [
          _cell('2', 0.02, 0.10),
          _cell('Traffic control', 0.15, 0.50),
        ]),
      ]);

      final grid = _gridLines(
        horizontalPositions: [0.08, 0.15, 0.25],
      );

      final (classified, _) = await classifier.classify(
        extractionResult: extraction,
        columnMap: columnMap,
        gridLines: grid,
      );

      final totalElements = classified.rows.fold<int>(
        0, (sum, row) => sum + row.elements.length,
      );
      // 4 input elements must all appear in output
      expect(totalElements, 4);
    });
```

**Verification** (Phase 4 complete):
```
pwsh -Command "flutter test test/features/pdf/extraction/stages/row_classifier_v3_test.dart"
```
Expected: All tests pass (existing + new grid-aware tests).

---

## Phase 5: Full Test Suite Verification
**Agent**: `qa-testing-agent`

### Phase 5.1: Run all unit tests

**Step 5.1.1**: Run the full test suite

```
pwsh -Command "flutter test"
```
Expected: All tests pass.

### Phase 5.2: Run Springfield pipeline test (integration)

**Step 5.2.1**: Run the pipeline report test on Windows

```
pwsh -Command "flutter test integration_test/springfield_report_test.dart -d windows --dart-define=SPRINGFIELD_PDF='C:\Users\rseba\OneDrive\Desktop\864130 Springfield DWSRF Water System Improvements CTC [16-23] Pay Items.pdf' --dart-define=NO_GATE=true"
```

**NOTE**: Use `NO_GATE=true` for the first run after the change to establish a new baseline. The grid-aware grouping will dramatically change the metrics (more data rows, fewer boilerplate rows, more items extracted).

Expected output changes:
- classified_rows: ~329 -> ~137-145 (close to grid row count)
- data_rows: ~38 -> significantly higher (target: ~131)
- items: 35 -> significantly higher (target: 131)
- grid_aware_pages metric: > 0 (new metric)

---

## Phase 6: Documentation and Cleanup
**Agent**: general-purpose

### Phase 6.1: No cleanup needed

This change is self-contained:
- No new models
- No new files (only modified existing)
- No barrel export changes needed
- No config changes needed

---

## Appendix: Key Design Decisions

### Why use original gridLines (not ocrGridLines) for classification?

The pipeline builds `ocrGridLines` at line 510 that zeroes out grid data for pages where grid removal failed. Row classification needs the **original** H-line positions because:
1. Grid removal failure doesn't affect detection accuracy (lines were detected correctly)
2. Classification uses positions as row boundaries, not for visual rendering
3. Zeroing out grid data would cause those pages to fall back to Y-proximity, losing the benefit

### Why >= 2 H-lines threshold?

A single horizontal line divides the page into 2 zones but doesn't define meaningful row bands. Two lines create at least one inter-line band (the first grid row). In practice, Springfield has 20+ H-lines per page.

### Why keep _splitRowWithMultipleItemNumbers?

Grid rows can be tall enough to contain multiple items stacked vertically. The existing splitter detects this pattern and subdivides. Without it, multi-item grid rows would be classified as a single data row, potentially missing items.

### Why optional GridLines parameter?

The system processes both grid PDFs (bid schedules with table lines) and non-grid PDFs (freeform documents). The optional parameter ensures:
1. Non-grid PDFs continue working unchanged
2. Existing callers don't need modification until explicitly wired
3. Test mocks that don't care about grid grouping need minimal changes

### Continuation detection with grid-aware rows

The `_gapWithinThreshold()` method uses `medianHeight * kMaxRowGapMultiplier` (2.0) to determine if two rows are close enough for continuation chaining. With grid-aware grouping, rows align to grid bands, so the gap between consecutive rows should be approximately one grid row height. This is naturally within the gap threshold, so continuation detection should work without modification.

However, if testing reveals that continuation chaining is disrupted, consider adding a grid-aware gap check that uses the grid row height as the reference instead of medianHeight.

**FROM REVIEW (MEDIUM-3)**: With grid-aware grouping, the "bottom" of a row is the bottom-most element in the entire grid band, which may extend further down than a tightly-clustered Y-proximity row. This could make gaps between consecutive rows appear smaller, potentially causing more aggressive continuation chaining. Monitor the Springfield results for unexpected continuation counts. If problematic, the fix is to compute gap using grid band boundaries instead of element bounding boxes.

## Files Modified Summary

| File | Change Type | Lines Changed (est.) |
|------|------------|---------------------|
| `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart` | DIRECT | +85 (new method + dispatch logic + metrics) |
| `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart` | DIRECT | +4 (2 call sites, 2 gridLines params) |
| `test/features/pdf/extraction/helpers/mock_stages.dart` | DEPENDENT | +1 (parameter addition) |
| `test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart` | DEPENDENT | +2 (parameter additions to 2 mock classes) |
| `test/features/pdf/extraction/stages/row_classifier_v3_test.dart` | TEST | +230 (10 new tests + helper) |
| **Total** | | **~322 lines** |

## Phases Summary

| Phase | Description | Agent | Steps |
|-------|-------------|-------|-------|
| 1 | Core Implementation (classify + _groupElementsByGridRows) | pdf-agent | 4 |
| 2 | Pipeline Wiring (pass gridLines at 2 call sites) | pdf-agent | 2 |
| 3 | Update Mock Overrides (3 mock classes) | qa-testing-agent | 3 |
| 4 | Unit Tests (10 new tests + helper) | qa-testing-agent | 12 |
| 5 | Full Test Suite Verification | qa-testing-agent | 2 |
| 6 | Documentation/Cleanup | general-purpose | 1 |
| **Total** | | **3 agents** | **24 steps** |

## Adversarial Review Findings

### Code Review (`.claude/code-reviews/2026-03-12-grid-aware-row-classification-review.md`)
| ID | Severity | Finding | Resolution |
|----|----------|---------|------------|
| MEDIUM-1 | MEDIUM | _findBandIndex boundary convention undocumented | FIXED: Added doc comment to _findBandIndex (Phase 1.2) |
| MEDIUM-2 | MEDIUM | Line widths not factored into band boundaries | FIXED: Added NOTE comment to _findBandIndex (Phase 1.2) |
| MEDIUM-3 | MEDIUM | Continuation chaining behavior change risk | NOTED: Added monitoring note in Appendix. Defer to empirical testing. |
| LOW-1 | LOW | No boundary condition test | FIXED: Added test 4.1.11 (element at exact grid line position) |
| LOW-2 | LOW | No comment about pre-sort not needed | FIXED: Added comment in _groupElementsByGridRows |

### Security Review (`.claude/code-reviews/2026-03-12-grid-aware-row-classification-security.md`)
| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |

No security concerns. Pure data-processing algorithm change with no external interfaces.
