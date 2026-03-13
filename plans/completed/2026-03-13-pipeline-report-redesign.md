# Pipeline Report Redesign Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Replace the verbose 1,039-line scorecard with a scannable report featuring two visual grids (Clean Grid and OCR Grid) that mirror the PDF table layout, plus a compressed one-row-per-stage summary.
**Spec:** `.claude/specs/2026-03-13-pipeline-report-redesign-spec.md`
**Analysis:** `.claude/dependency_graphs/2026-03-13-pipeline-report-redesign/`

**Architecture:** Single-file rewrite of the markdown report generator. Phase 1 adds missing fields to the JSON trace layer (`_buildStageMetrics`). Phase 2 rewrites `generateScorecard()` sections 3-6, replacing multi-row stage statistics and the 700-line cell extraction detail dump with a compact stage summary table and two per-page grid views. Phase 3 runs the integration test to verify output.
**Tech Stack:** Dart, Markdown generation, JSON trace data
**Blast Radius:** 1 direct, 0 dependent, 1 integration test to verify, 2 helpers to delete

---

## Phase 1: JSON Trace Layer Fix

### Sub-phase 1.1: Add Stage Counts to `_buildStageMetrics()`

**Files:**
- Modify: `test/features/pdf/extraction/helpers/report_generator.dart` (lines 350-362)

**Agent**: pdf-agent

#### Step 1.1.1: Add `input_count`, `output_count`, `excluded_count` to stage metrics map

At `report_generator.dart:350-362`, modify `_buildStageMetrics()` to include the three count fields from `StageReport`:

```dart
Map<String, dynamic> _buildStageMetrics(
    List<StageReport> stageReports,
    Map<String, Map<String, dynamic>> stageOutputs,
  ) {
    final metrics = <String, dynamic>{};
    for (final report in stageReports) {
      metrics[report.stageName] = {
        'elapsed_ms': report.elapsed.inMilliseconds,
        // WHY: Stage Summary table needs In/Out/Excl columns.
        // FROM SPEC: "Add input_count, output_count, excluded_count to _buildStageMetrics()"
        'input_count': report.inputCount,
        'output_count': report.outputCount,
        'excluded_count': report.excludedCount,
        ...report.metrics,
      };
    }
    return metrics;
  }
```

#### Step 1.1.2: Verify

Run: `pwsh -Command "flutter test test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart"`
Expected: All existing tests pass — this is a non-breaking additive change to the JSON trace.

---

## Phase 2: Scorecard Rewrite

### Sub-phase 2.1: Add Constants and New Helpers

**Files:**
- Modify: `test/features/pdf/extraction/helpers/report_generator.dart`

**Agent**: pdf-agent

#### Step 2.1.1: Add `_kRowTypeAbbrev` constant map

Add near the top of the class (after existing static members):

```dart
// FROM SPEC: Row type abbreviations for compact grid display
static const _kRowTypeAbbrev = <String, String>{
  'header': 'hdr',
  'data': 'data',
  'priceContinuation': 'cont-p',
  'descContinuation': 'cont-d',
  'blank': 'blnk',
  'boilerplate': 'boil',
  'sectionHeader': 'sect',
  'total': 'totl',
};
```

#### Step 2.1.2: Add `_escapePipe()` helper

```dart
// FROM SPEC: "All cell values must have | escaped to \| and newlines replaced with spaces"
static String _escapePipe(String s) {
  return s.replaceAll('|', r'\|').replaceAll('\n', ' ').replaceAll('\r', ' ');
}
```

#### Step 2.1.3: Add `_clampConfidence()` helper

```dart
// FROM SPEC: "Clamp to 0.0-1.0 before formatting (guards against NaN/Infinity)"
static double _clampConfidence(dynamic value) {
  if (value == null || value is! num) return 0.0;
  final d = value.toDouble();
  if (d.isNaN || d.isInfinite) return 0.0;
  return d.clamp(0.0, 1.0);
}
```

#### Step 2.1.4: Verify

Run: `pwsh -Command "flutter test test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart"`
Expected: Passes — only added constants and static helpers, no behavioral change yet.

### Sub-phase 2.2: Rewrite `generateScorecard()` Sections

**Files:**
- Modify: `test/features/pdf/extraction/helpers/report_generator.dart` (lines 126-346)

**Agent**: pdf-agent

#### Step 2.2.1: Replace Stage Statistics section (lines ~177-207) with Stage Summary

Remove the multi-row stage statistics table and replace with a one-row-per-stage table:

```dart
// FROM SPEC: "Stage Summary — one row per stage: Stage, In, Out, Excl, Time(ms), Status"
buf.writeln('## Stage Summary');
buf.writeln();
buf.writeln('| Stage | In | Out | Excl | Time(ms) | Status |');
buf.writeln('|-------|---:|----:|-----:|---------:|--------|');

final stageMetrics = jsonTrace['stage_metrics'] as Map<String, dynamic>? ?? {};
final previousStageMetrics = previousReport?['stage_metrics'] as Map<String, dynamic>? ?? {};

for (final stageName in stageMetrics.keys) {
  final current = stageMetrics[stageName] as Map<String, dynamic>? ?? {};
  final previous = previousStageMetrics[stageName] as Map<String, dynamic>?;

  final inputCount = current['input_count'] ?? '-';
  final outputCount = current['output_count'] ?? '-';
  final excludedCount = current['excluded_count'] ?? '-';
  final elapsedMs = current['elapsed_ms'] ?? '-';

  // WHY: Status compares output_count to detect regressions vs previous run
  String status;
  if (previous == null) {
    status = 'NEW';
  } else {
    final prevOutput = previous['output_count'];
    status = _metricStatus(outputCount, prevOutput);
  }

  buf.writeln('| ${_escapePipe(stageName)} | $inputCount | $outputCount | $excludedCount | $elapsedMs | $status |');
}
buf.writeln();
```

#### Step 2.2.2: Replace Cell Extraction Detail (lines ~254-323) with Clean Grid + OCR Grid

Remove the `<details>` dump and replace with two grid tables per page:

```dart
// --- Clean Grid ---
// FROM SPEC: "Clean Grid (per page) — mirrors PDF table"
final cellGrid = jsonTrace['cell_grid'] as List? ?? [];

// WHY: Group rows by page_index for per-page sections
final pageGroups = <int, List<Map<String, dynamic>>>{};
for (final row in cellGrid) {
  final r = row as Map<String, dynamic>;
  final pageIndex = r['page_index'] as int? ?? 0;
  pageGroups.putIfAbsent(pageIndex, () => []).add(r);
}

final sortedPages = pageGroups.keys.toList()..sort();

buf.writeln('## Clean Grid');
buf.writeln();

for (final pageIdx in sortedPages) {
  final rows = pageGroups[pageIdx]!;
  buf.writeln('### Page ${pageIdx + 1} (${rows.length} rows)');
  buf.writeln();
  buf.writeln('| Row | Type | Item No. | Description | Unit | Est. Quantity | Unit Price | Bid Amount |');
  buf.writeln('|----:|------|----------|-------------|------|---------------|------------|------------|');

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final rowType = _kRowTypeAbbrev[row['type'] as String? ?? ''] ?? row['type'] ?? '';
    final cells = row['cells'] as List? ?? [];

    // WHY: Column order matches PDF table layout.
    // FROM SPEC: "Item No., Description (40 char trunc), Unit, Est. Quantity, Unit Price, Bid Amount"
    String cellValue(int colIndex, {int? truncLen}) {
      if (colIndex >= cells.length) return '';
      final cell = cells[colIndex] as Map<String, dynamic>;
      var val = _escapePipe((cell['value'] as String?) ?? '');
      if (truncLen != null) val = _truncate(val, truncLen);
      return val;
    }

    // NOTE: 0-based row index per spec example (Row 0 = header row)
    buf.writeln(
      '| $i '
      '| $rowType '
      '| ${cellValue(0)} '
      '| ${cellValue(1, truncLen: 40)} ' // FROM SPEC: 40 char truncation for description
      '| ${cellValue(2)} '
      '| ${cellValue(3)} '
      '| ${cellValue(4)} '
      '| ${cellValue(5)} |',
    );
  }
  buf.writeln();
}

// --- OCR Grid ---
// FROM SPEC: "OCR Grid (per page) — same structure but text(confidence) per element"
buf.writeln('## OCR Grid');
buf.writeln();

for (final pageIdx in sortedPages) {
  final rows = pageGroups[pageIdx]!;
  // FROM SPEC: OCR Grid headers use "Page N — OCR" format to distinguish from Clean Grid
  buf.writeln('### Page ${pageIdx + 1} — OCR (${rows.length} rows)');
  buf.writeln();
  buf.writeln('| Row | Type | Item No. | Description | Unit | Est. Quantity | Unit Price | Bid Amount |');
  buf.writeln('|----:|------|----------|-------------|------|---------------|------------|------------|');

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final rowType = _kRowTypeAbbrev[row['type'] as String? ?? ''] ?? row['type'] ?? '';
    final cells = row['cells'] as List? ?? [];

    // WHY: Each cell shows raw Tesseract elements as "text(conf)" with bold for low confidence
    String ocrCellValue(int colIndex) {
      if (colIndex >= cells.length) return '';
      final cell = cells[colIndex] as Map<String, dynamic>;
      final elements = cell['elements'] as List? ?? [];
      if (elements.isEmpty) return '';

      final parts = <String>[];
      for (final elem in elements) {
        final e = elem as Map<String, dynamic>;
        final text = _escapePipe((e['text'] as String?) ?? '');
        final conf = _clampConfidence(e['confidence']);
        final confStr = conf.toStringAsFixed(2);
        // FROM SPEC: "bold if conf < 0.50"
        if (conf < 0.50) {
          parts.add('**$text($confStr)**');
        } else {
          parts.add('$text($confStr)');
        }
      }
      return parts.join(' ');
    }

    // NOTE: 0-based row index per spec example
    buf.writeln(
      '| $i '
      '| $rowType '
      '| ${ocrCellValue(0)} '
      '| ${ocrCellValue(1)} ' // WHY: No truncation in OCR Grid — need full raw output for debugging
      '| ${ocrCellValue(2)} '
      '| ${ocrCellValue(3)} '
      '| ${ocrCellValue(4)} '
      '| ${ocrCellValue(5)} |',
    );
  }
  buf.writeln();
}
```

#### Step 2.2.3: Delete unused helper methods

Remove these two methods that are no longer called:
- `_stageLabel()` (lines ~556-560) — was used by old Stage Statistics multi-row section
- `_formatDelta()` (lines ~562-570) — was used by old Stage Statistics multi-row section

NOTE: `_capitalize()` is KEPT — still used by Performance Summary section.

```dart
// WHY: These helpers were only used by the old multi-row Stage Statistics table
// which has been replaced by the one-row-per-stage Stage Summary.
// Verify no other callers exist before deleting.
```

#### Step 2.2.4: Verify

Run: `pwsh -Command "flutter test test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart"`
Expected: All tests pass. The scorecard output format changes but the test assertions should be on structure/data, not exact formatting.

---

## Phase 3: Integration Verification + Cleanup

### Sub-phase 3.1: Run Springfield Integration Test

**Files:**
- No modifications — verification only

**Agent**: pdf-agent

#### Step 3.1.1: Run full pipeline with report generation

Run: `pwsh -Command "flutter test integration_test/springfield_report_test.dart -d windows --dart-define=SPRINGFIELD_PDF=\"C:\Users\rseba\OneDrive\Desktop\864130 Springfield DWSRF Water System Improvements CTC [16-23] Pay Items.pdf\" --dart-define=NO_GATE=true"`

Expected:
- Test passes (NO_GATE=true skips regression gate)
- Scorecard file generated at `test/features/pdf/extraction/diagnostics/` or equivalent output path
- Report contains: Header, Stage Summary (one-row-per-stage), Performance Summary (kept), Clean Grid (per page), OCR Grid (per page), Item Verdicts, Summary Footer
- No `<details>` tags in output
- No multi-row Stage Statistics section

#### Step 3.1.2: Manually inspect generated scorecard

Read the generated scorecard file and verify:
1. **Stage Summary** has columns: Stage | In | Out | Excl | Time(ms) | Status
2. **Clean Grid** per page has columns: Row | Type | Item No. | Description | Unit | Est. Quantity | Unit Price | Bid Amount
3. **OCR Grid** per page has same columns but with `text(confidence)` format
4. Low-confidence elements (< 0.50) are **bold**
5. No pipe characters (`|`) leak into cell values (would break table formatting)
6. Description column in Clean Grid is truncated to 40 chars
7. Description column in OCR Grid is NOT truncated
8. Row type abbreviations are correct (data, hdr, cont-p, etc.)

### Sub-phase 3.2: Verify No Dead Code

**Files:**
- Verify: `test/features/pdf/extraction/helpers/report_generator.dart`

**Agent**: pdf-agent

#### Step 3.2.1: Confirm deleted methods have no remaining callers

Search the file for any references to `_stageLabel` or `_formatDelta`. Confirm they are fully removed and no compile errors exist. `_capitalize()` should still be present (used by Performance Summary).

#### Step 3.2.2: Run static analysis

Run: `pwsh -Command "flutter analyze test/features/pdf/extraction/helpers/report_generator.dart"`
Expected: No errors or warnings related to the changed file.

#### Step 3.2.3: Run unit tests one final time

Run: `pwsh -Command "flutter test test/features/pdf/extraction/"`
Expected: All tests in the extraction test suite pass.
