# Pipeline Test Suite Restructure — Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Replace the fragmented, assertion-weak PDF extraction test suite with a unified report-first system that traces every item through every pipeline stage, detects regressions automatically, and produces machine-readable (JSON) and human-readable (MD) outputs.

**Spec:** `.claude/specs/2026-03-10-pipeline-test-restructure-spec.md`
**Analysis:** `.claude/dependency_graphs/2026-03-10-pipeline-test-restructure/`

**Architecture:** New integration test runs the full extraction pipeline, captures all 27 stage outputs per item, generates a JSON trace + MD scorecard, then runs a regression gate against the previous platform-specific baseline. A single comparison library replaces 3 duplicate implementations (Dart matcher, CLI tool, Python scripts). Reports are gitignored and platform-specific.

**Tech Stack:** Dart, Flutter integration tests, JSON/MD file I/O, `ExtractionPipeline.extract()`, `onStageOutput` callbacks, `dart:io` for file system operations.

**Blast Radius:** 4 direct (new files), 2 dependent (modified), 8 tests (deleted), 3 cleanup (deleted tools) = 17 total files. Net delta: -5,500 to -6,050 lines.

---

## Phase 1: Build Comparison Library (`pipeline_comparator.dart`)

**Agent:** `qa-testing-agent`
**Why first:** Both the report generator and integration test depend on comparison logic. This is the foundation.

### Sub-phase 1.1: Create Core Data Structures

**File:** `test/features/pdf/extraction/golden/pipeline_comparator.dart` (NEW)

**Step 1.1.1:** Create the file with imports and comparison result data structures.

```dart
// WHY: Single comparison implementation replacing 3 separate tools
// (golden_file_matcher.dart, gt_trace.dart, compare_golden.py).
// FROM SPEC: "No normalization — LSUM vs LS is a real mismatch, reported as-is"

import 'dart:convert';
import 'dart:io';

import 'package:construction_inspector/features/pdf/services/extraction/models/parsed_items.dart';
import 'package:construction_inspector/features/pdf/services/extraction/models/quality_report.dart';

// ============================================================================
// Comparison Result Types
// ============================================================================

/// Verdict for a single item comparison against ground truth.
enum ItemVerdict { pass, fail, miss, bogus }

/// Per-field comparison result.
class FieldComparison {
  final String fieldName;
  final dynamic expected;
  final dynamic actual;
  final bool matches;
  final double? delta; // For numeric fields: actual - expected

  const FieldComparison({
    required this.fieldName,
    required this.expected,
    required this.actual,
    required this.matches,
    this.delta,
  });

  Map<String, dynamic> toMap() => {
    'field': fieldName,
    'expected': expected,
    'actual': actual,
    'matches': matches,
    if (delta != null) 'delta': delta,
  };
}

/// Comparison result for a single item.
class ItemComparison {
  final String itemNumber;
  final ItemVerdict verdict;
  final List<FieldComparison> fields;

  const ItemComparison({
    required this.itemNumber,
    required this.verdict,
    this.fields = const [],
  });

  Map<String, dynamic> toMap() => {
    'item_number': itemNumber,
    'verdict': verdict.name.toUpperCase(),
    'fields': fields.map((f) => f.toMap()).toList(),
  };
}

/// Overall comparison result.
class ComparisonResult {
  final int groundTruthCount;
  final int extractedCount;
  final int passCount;
  final int failCount;
  final int missCount;
  final int bogusCount;
  final double matchRate; // (pass + fail) / groundTruthCount
  final Map<String, double> fieldAccuracy; // field name -> accuracy (0.0-1.0)
  final double checksumExtracted;
  final double checksumGroundTruth;
  final List<ItemComparison> items;

  const ComparisonResult({
    required this.groundTruthCount,
    required this.extractedCount,
    required this.passCount,
    required this.failCount,
    required this.missCount,
    required this.bogusCount,
    required this.matchRate,
    required this.fieldAccuracy,
    required this.checksumExtracted,
    required this.checksumGroundTruth,
    required this.items,
  });

  Map<String, dynamic> toMap() => {
    'ground_truth_count': groundTruthCount,
    'extracted_count': extractedCount,
    'pass': passCount,
    'fail': failCount,
    'miss': missCount,
    'bogus': bogusCount,
    'match_rate': matchRate,
    'field_accuracy': fieldAccuracy,
    'checksum_extracted': checksumExtracted,
    'checksum_ground_truth': checksumGroundTruth,
    'items': items.map((i) => i.toMap()).toList(),
  };
}

/// Regression gate result.
class RegressionResult {
  final bool passed;
  final List<String> regressions; // Human-readable regression descriptions
  final String? schemaWarning; // Set if schema versions differ

  const RegressionResult({
    required this.passed,
    this.regressions = const [],
    this.schemaWarning,
  });
}
```

**Verification:** File compiles — will verify after Step 1.1.2.

### Sub-phase 1.2: Implement Comparison Logic

**Step 1.2.1:** Add the `PipelineComparator` class with `compare()` method.

Append to `test/features/pdf/extraction/golden/pipeline_comparator.dart`:

```dart
// ============================================================================
// Comparison Tolerances
// FROM SPEC: "tolerance of 0.01 for currency, 0.001 for quantity"
// ============================================================================

class ComparisonTolerances {
  /// Currency tolerance (unit_price, bid_amount): $0.01
  static const double currency = 0.01;
  /// Quantity tolerance: 0.001
  static const double quantity = 0.001;

  ComparisonTolerances._();
}

// ============================================================================
// Pipeline Comparator
// FROM SPEC: "Single comparison implementation used everywhere"
// ============================================================================

class PipelineComparator {
  /// Compare extracted items against ground truth.
  ///
  /// FROM SPEC:
  /// - String fields: exact match. Mismatch = FAIL with both values shown.
  /// - Numeric fields: tolerance of 0.01 for currency, 0.001 for quantity.
  /// - Item matching: by item_number (exact). Not found = MISS. Extra = BOGUS.
  /// - No normalization: LSUM vs LS is a real mismatch.
  ComparisonResult compare(
    List<ParsedBidItem> extracted,
    List<ParsedBidItem> groundTruth,
  ) {
    // Build lookup from ground truth by item_number
    final gtByNumber = <String, ParsedBidItem>{};
    for (final gt in groundTruth) {
      if (gt.itemNumber != null) {
        gtByNumber[gt.itemNumber!] = gt;
      }
    }

    // Build lookup from extracted by item_number
    final extByNumber = <String, ParsedBidItem>{};
    for (final ext in extracted) {
      if (ext.itemNumber != null) {
        extByNumber[ext.itemNumber!] = ext;
      }
    }

    final items = <ItemComparison>[];
    int passCount = 0;
    int failCount = 0;
    int missCount = 0;
    int bogusCount = 0;

    // Per-field accuracy tracking
    final fieldMatches = <String, int>{};
    final fieldTotal = <String, int>{};
    const fieldNames = ['description', 'unit', 'quantity', 'unit_price', 'bid_amount'];
    for (final f in fieldNames) {
      fieldMatches[f] = 0;
      fieldTotal[f] = 0;
    }

    // Compare each ground truth item
    for (final gt in groundTruth) {
      final itemNum = gt.itemNumber ?? '';
      final ext = extByNumber[itemNum];

      if (ext == null) {
        // MISS: ground truth item not found in extraction
        items.add(ItemComparison(
          itemNumber: itemNum,
          verdict: ItemVerdict.miss,
        ));
        missCount++;
        continue;
      }

      // Compare fields
      final fields = <FieldComparison>[];
      bool allMatch = true;

      // String fields: exact match, no normalization
      for (final sf in [
        ('description', ext.description, gt.description),
        ('unit', ext.unit, gt.unit),
      ]) {
        final matches = sf.$2 == sf.$3;
        fields.add(FieldComparison(
          fieldName: sf.$1,
          expected: sf.$3,
          actual: sf.$2,
          matches: matches,
        ));
        fieldTotal[sf.$1] = fieldTotal[sf.$1]! + 1;
        if (matches) fieldMatches[sf.$1] = fieldMatches[sf.$1]! + 1;
        if (!matches) allMatch = false;
      }

      // Numeric fields: tolerance-based
      for (final nf in [
        ('quantity', ext.quantity, gt.quantity, ComparisonTolerances.quantity),
        ('unit_price', ext.unitPrice, gt.unitPrice, ComparisonTolerances.currency),
        ('bid_amount', ext.bidAmount, gt.bidAmount, ComparisonTolerances.currency),
      ]) {
        final delta = (nf.$2 != null && nf.$3 != null) ? nf.$2! - nf.$3! : null;
        final matches = _numericMatch(nf.$2, nf.$3, nf.$4);
        fields.add(FieldComparison(
          fieldName: nf.$1,
          expected: nf.$3,
          actual: nf.$2,
          matches: matches,
          delta: delta,
        ));
        fieldTotal[nf.$1] = fieldTotal[nf.$1]! + 1;
        if (matches) fieldMatches[nf.$1] = fieldMatches[nf.$1]! + 1;
        if (!matches) allMatch = false;
      }

      final verdict = allMatch ? ItemVerdict.pass : ItemVerdict.fail;
      items.add(ItemComparison(
        itemNumber: itemNum,
        verdict: verdict,
        fields: fields,
      ));
      if (allMatch) passCount++ ; else failCount++;
    }

    // BOGUS: extracted items not in ground truth
    for (final ext in extracted) {
      final itemNum = ext.itemNumber ?? '';
      if (!gtByNumber.containsKey(itemNum)) {
        items.add(ItemComparison(
          itemNumber: itemNum,
          verdict: ItemVerdict.bogus,
        ));
        bogusCount++;
      }
    }

    // Compute field accuracy
    final fieldAccuracy = <String, double>{};
    for (final f in fieldNames) {
      fieldAccuracy[f] = fieldTotal[f]! > 0
          ? fieldMatches[f]! / fieldTotal[f]!
          : 0.0;
    }

    // Compute checksums
    final checksumExtracted = extracted.fold<double>(
      0.0, (sum, item) => sum + (item.bidAmount ?? 0.0),
    );
    final checksumGroundTruth = groundTruth.fold<double>(
      0.0, (sum, item) => sum + (item.bidAmount ?? 0.0),
    );

    // Match rate: fraction of GT items found (pass + fail) / total GT
    final matchRate = groundTruth.isEmpty
        ? 0.0
        : (passCount + failCount) / groundTruth.length;

    return ComparisonResult(
      groundTruthCount: groundTruth.length,
      extractedCount: extracted.length,
      passCount: passCount,
      failCount: failCount,
      missCount: missCount,
      bogusCount: bogusCount,
      matchRate: matchRate,
      fieldAccuracy: fieldAccuracy,
      checksumExtracted: checksumExtracted,
      checksumGroundTruth: checksumGroundTruth,
      items: items,
    );
  }

  /// Numeric comparison with tolerance.
  /// Both null = match. One null = no match.
  static bool _numericMatch(double? a, double? b, double tolerance) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a - b).abs() <= tolerance;
  }

  /// Load ground truth items from JSON file.
  ///
  /// Expected format: JSON array of objects with item_number, description,
  /// unit, quantity, unit_price, bid_amount, confidence, fields_present.
  static List<ParsedBidItem> loadGroundTruth(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('Ground truth file not found', path);
    }
    final json = jsonDecode(file.readAsStringSync());
    final list = json is List ? json : (json as Map)['items'] as List;
    return list
        .map((e) => ParsedBidItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}
```

**Verification:** `pwsh -Command "flutter test test/features/pdf/extraction/golden/pipeline_comparator.dart"` — should fail (no test cases yet, but file should parse).

### Sub-phase 1.3: Implement Regression Gate Logic

**Step 1.3.1:** Add regression gate to `pipeline_comparator.dart`.

Append to the file:

```dart
// ============================================================================
// Regression Gate
// FROM SPEC: "Compare to previous run's platform-specific baseline.
//             No hardcoded thresholds. Ratchet effect."
// ============================================================================

class RegressionTolerances {
  /// Item count: no regression allowed (tolerance = 0)
  static const int itemCount = 0;
  /// Quality score: can drop by 1% (tolerance = -0.01)
  static const double qualityScore = -0.01;
  /// Per-field accuracy: can drop by 2% (tolerance = -0.02)
  static const double fieldAccuracy = -0.02;
  /// Checksum delta: $0.01 x GT item count
  /// FROM SPEC: "derived: numericTolerance x itemCount = $0.01 x 131 = $1.31"
  static double checksumDelta(int gtItemCount) => 0.01 * gtItemCount;
  /// Per-stage element counts: no loss (tolerance = 0)
  static const int stageElementCount = 0;

  RegressionTolerances._();
}

class RegressionGate {
  /// Compare current report against previous baseline.
  ///
  /// Returns [RegressionResult] with pass/fail and list of regressions.
  /// First run (no previous baseline) always passes.
  ///
  /// FROM SPEC: "schema_version check — if different, warn and skip"
  RegressionResult evaluate({
    required Map<String, dynamic> currentReport,
    required Map<String, dynamic>? previousReport,
  }) {
    // First run: no baseline -> always pass
    if (previousReport == null) {
      return const RegressionResult(passed: true);
    }

    // Schema version check
    final currentSchema = currentReport['schema_version'] as int? ?? 1;
    final previousSchema = previousReport['schema_version'] as int? ?? 1;
    if (currentSchema != previousSchema) {
      return RegressionResult(
        passed: true, // Can't compare different schemas
        schemaWarning:
            'Schema version mismatch: current=$currentSchema, '
            'previous=$previousSchema. Baseline must be regenerated.',
      );
    }

    final regressions = <String>[];

    final curSummary = currentReport['summary'] as Map<String, dynamic>? ?? {};
    final prevSummary = previousReport['summary'] as Map<String, dynamic>? ?? {};

    // Item count regression
    final curItems = curSummary['items_extracted'] as int? ?? 0;
    final prevItems = prevSummary['items_extracted'] as int? ?? 0;
    if (curItems < prevItems - RegressionTolerances.itemCount) {
      regressions.add(
        'Item count regressed: $curItems (was $prevItems, '
        'tolerance=${RegressionTolerances.itemCount})',
      );
    }

    // Quality score regression
    final curQuality = (curSummary['overall_quality'] as num?)?.toDouble() ?? 0.0;
    final prevQuality = (prevSummary['overall_quality'] as num?)?.toDouble() ?? 0.0;
    if (curQuality < prevQuality + RegressionTolerances.qualityScore) {
      regressions.add(
        'Quality score regressed: '
        '${curQuality.toStringAsFixed(3)} (was ${prevQuality.toStringAsFixed(3)}, '
        'tolerance=${RegressionTolerances.qualityScore})',
      );
    }

    // Field accuracy regression
    final curFields = curSummary['field_accuracy'] as Map<String, dynamic>? ?? {};
    final prevFields = prevSummary['field_accuracy'] as Map<String, dynamic>? ?? {};
    for (final field in prevFields.keys) {
      final curAcc = (curFields[field] as num?)?.toDouble() ?? 0.0;
      final prevAcc = (prevFields[field] as num?)?.toDouble() ?? 0.0;
      if (curAcc < prevAcc + RegressionTolerances.fieldAccuracy) {
        regressions.add(
          'Field "$field" accuracy regressed: '
          '${curAcc.toStringAsFixed(3)} (was ${prevAcc.toStringAsFixed(3)}, '
          'tolerance=${RegressionTolerances.fieldAccuracy})',
        );
      }
    }

    // Checksum delta regression
    final gtCount = curSummary['ground_truth_items'] as int? ?? 131;
    final curChecksum = (curSummary['checksum_extracted'] as num?)?.toDouble() ?? 0.0;
    final prevChecksum = (prevSummary['checksum_extracted'] as num?)?.toDouble() ?? 0.0;
    final checksumTolerance = RegressionTolerances.checksumDelta(gtCount);
    final checksumDelta = (curChecksum - prevChecksum).abs();
    // NOTE: Only regresses if current is FURTHER from GT than previous was
    final curChecksumGT = (curSummary['checksum_ground_truth'] as num?)?.toDouble() ?? 0.0;
    final curDist = (curChecksum - curChecksumGT).abs();
    final prevDist = (prevChecksum - curChecksumGT).abs();
    if (curDist > prevDist + checksumTolerance) {
      regressions.add(
        'Checksum distance from GT regressed: '
        '\$${curDist.toStringAsFixed(2)} (was \$${prevDist.toStringAsFixed(2)}, '
        'tolerance=\$${checksumTolerance.toStringAsFixed(2)})',
      );
    }

    // Per-stage element count regression
    final curStages = currentReport['stage_metrics'] as Map<String, dynamic>? ?? {};
    final prevStages = previousReport['stage_metrics'] as Map<String, dynamic>? ?? {};
    for (final stageKey in prevStages.keys) {
      final curStage = curStages[stageKey] as Map<String, dynamic>?;
      final prevStage = prevStages[stageKey] as Map<String, dynamic>?;
      if (curStage == null || prevStage == null) continue;

      // Check element/item counts within each stage
      for (final countKey in ['elements_total', 'data_rows', 'items_parsed',
                              'cells_assigned', 'regions', 'columns']) {
        final curCount = curStage[countKey] as int?;
        final prevCount = prevStage[countKey] as int?;
        if (curCount != null && prevCount != null &&
            curCount < prevCount - RegressionTolerances.stageElementCount) {
          regressions.add(
            'Stage "$stageKey" $countKey regressed: $curCount (was $prevCount)',
          );
        }
      }
    }

    return RegressionResult(
      passed: regressions.isEmpty,
      regressions: regressions,
    );
  }
}
```

**Step 1.3.2:** Add backward-compatible API for `full_pipeline_integration_test.dart` migration.

Append to the file:

```dart
// ============================================================================
// Backward-compatible API for full_pipeline_integration_test.dart migration
// WHY: full_pipeline_integration_test.dart uses GoldenFileMatcher.compare()
//      which returns MatchResult with .matchRate, .unmatchedActual, .unmatchedExpected.
//      We provide the same API surface so the migration is a simple import swap.
// ============================================================================

extension PipelineComparatorCompat on PipelineComparator {
  /// Compare two lists and return a compat result matching old GoldenFileMatcher API.
  /// Used only by full_pipeline_integration_test.dart during migration.
  CompatMatchResult compareCompat(
    List<ParsedBidItem> actual,
    List<ParsedBidItem> expected,
  ) {
    final result = compare(actual, expected);
    final unmatchedActual = result.items
        .where((i) => i.verdict == ItemVerdict.bogus)
        .map((i) => i.itemNumber)
        .toList();
    final unmatchedExpected = result.items
        .where((i) => i.verdict == ItemVerdict.miss)
        .map((i) => i.itemNumber)
        .toList();

    return CompatMatchResult(
      matchRate: result.matchRate,
      unmatchedActual: unmatchedActual,
      unmatchedExpected: unmatchedExpected,
    );
  }
}

/// Backward-compatible result matching old GoldenFileMatcher.MatchResult API.
class CompatMatchResult {
  final double matchRate;
  final List<String> unmatchedActual;
  final List<String> unmatchedExpected;

  const CompatMatchResult({
    required this.matchRate,
    required this.unmatchedActual,
    required this.unmatchedExpected,
  });
}
```

**Verification:**
```
pwsh -Command "flutter analyze test/features/pdf/extraction/golden/pipeline_comparator.dart"
```
Expected: No analysis issues (or only info-level).

### Sub-phase 1.4: Write Unit Tests for Comparator

**Step 1.4.1:** The comparator tests will be written alongside the existing test infrastructure. However, the old `golden_file_matcher_test.dart` tests the old matcher — we do NOT need a separate test file for this because the integration test itself exercises the comparator end-to-end. The comparator's logic is simple enough (exact match + tolerance) that the integration test serves as verification.

**IMPORTANT:** If the implementing agent determines a unit test file IS needed (because the comparator logic is more nuanced than expected), create `test/features/pdf/extraction/golden/pipeline_comparator_test.dart` with tests for: exact string match, numeric tolerance, miss/bogus detection, checksum computation, regression gate first-run, and schema version mismatch.

---

## Phase 2: Build Report Generator (`report_generator.dart`)

**Agent:** `qa-testing-agent`
**Why second:** The integration test depends on the report generator. The report generator depends on the comparator (Phase 1).

### Sub-phase 2.1: Create Report Generator with Version Metadata

**File:** `test/features/pdf/extraction/golden/report_generator.dart` (NEW)

**Step 2.1.1:** Create the file with imports, version collection, and JSON trace generation.

```dart
// WHY: Produces JSON trace + MD scorecard from pipeline stage data.
// FROM SPEC: "Report-first, assert-second: Pipeline always saves full report
//             regardless of pass/fail. Assertions evaluate the report."

import 'dart:convert';
import 'dart:io';

import 'package:construction_inspector/features/pdf/services/extraction/models/models.dart';
import 'package:construction_inspector/features/pdf/services/extraction/pipeline/extraction_pipeline.dart';
import 'package:construction_inspector/features/pdf/services/extraction/stages/stage_names.dart';

import 'pipeline_comparator.dart';

// ============================================================================
// Version Metadata Collection
// FROM SPEC: "A helper function collectVersionMetadata() will centralize this."
// ============================================================================

/// Collect tool versions for report metadata.
///
/// FROM SPEC:
/// - tesseract: from Tesseract.version (runtime)
/// - dart: from Platform.version (runtime)
/// - flutter/pdfrx/flusseract: from dart-define or "unknown"
Map<String, String> collectVersionMetadata() {
  // NOTE: Tesseract.version requires flusseract import which pulls native libs.
  // In integration test context this is available. In unit test context, use "unknown".
  String tesseractVersion;
  try {
    // Import is done conditionally to avoid native lib issues in unit tests
    tesseractVersion = _getTesseractVersion();
  } catch (_) {
    tesseractVersion = 'unknown';
  }

  return {
    'tesseract': tesseractVersion,
    'dart': Platform.version.split(' ').first,
    'flutter': const String.fromEnvironment('FLUTTER_VERSION', defaultValue: 'unknown'),
    'pdfrx': const String.fromEnvironment('PDFRX_VERSION', defaultValue: 'unknown'),
    'flusseract': const String.fromEnvironment('FLUSSERACT_VERSION', defaultValue: 'unknown'),
  };
}

// Separated so it can be overridden in tests
String _getTesseractVersion() {
  // IMPORTANT: This import chain pulls native FFI. Only works in integration tests.
  // The caller catches exceptions for unit test fallback.
  try {
    // Use dynamic invocation to avoid hard import dependency
    return 'unknown'; // Will be replaced with actual Tesseract.version call in integration test
  } catch (_) {
    return 'unknown';
  }
}

// ============================================================================
// Report Generator
// ============================================================================

/// Schema version for the JSON trace format.
/// FROM SPEC: "schema_version starts at 1. Breaking changes increment it."
const int reportSchemaVersion = 1;

class ReportGenerator {
  /// Tesseract version override (set before calling generate).
  /// WHY: Avoids native FFI dependency in the generator itself.
  /// The integration test sets this from Tesseract.version before calling.
  String tesseractVersion = 'unknown';

  /// Generate JSON trace from pipeline result and stage outputs.
  ///
  /// [result] - PipelineResult from ExtractionPipeline.extract()
  /// [stageOutputs] - Map of stageName -> stage output data (from onStageOutput)
  /// [groundTruth] - Ground truth items for comparison
  /// [previousReport] - Previous report.json for regression comparison (null = first run)
  /// [bestAttemptIndex] - Which attempt was selected as best
  /// [totalAttempts] - Total number of pipeline attempts
  Map<String, dynamic> generateJsonTrace({
    required PipelineResult result,
    required Map<String, Map<String, dynamic>> stageOutputs,
    required List<ParsedBidItem> groundTruth,
    Map<String, dynamic>? previousReport,
    required int bestAttemptIndex,
    required int totalAttempts,
  }) {
    final comparator = PipelineComparator();
    final comparison = comparator.compare(result.processedItems.items, groundTruth);

    // Build stage metrics from StageReports
    final stageMetrics = _buildStageMetrics(result.stageReports, stageOutputs);

    // Build per-item trace
    final itemsTrace = _buildItemsTrace(
      result.processedItems.items,
      groundTruth,
      stageOutputs,
      comparison,
    );

    // Build performance section
    final performance = _buildPerformance(result);

    // Get git hash
    String gitHash;
    try {
      final gitResult = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
      gitHash = gitResult.stdout.toString().trim();
    } catch (_) {
      gitHash = 'unknown';
    }

    // Determine platform
    final platform = _detectPlatform();

    return {
      'schema_version': reportSchemaVersion,
      'metadata': {
        'date': DateTime.now().toIso8601String(),
        'platform': platform,
        'device_model': Platform.isAndroid ? _getDeviceModel() : null,
        'git_hash': gitHash,
        'pipeline_duration_ms': result.totalElapsed.inMilliseconds,
        'pdf_document_id': result.documentId,
        'attempt_selected': bestAttemptIndex,
        'total_attempts': totalAttempts,
        'versions': {
          'tesseract': tesseractVersion,
          ...collectVersionMetadata()..remove('tesseract'),
        },
      },
      'summary': {
        'items_extracted': result.processedItems.items.length,
        'ground_truth_items': groundTruth.length,
        'overall_quality': result.qualityReport.overallScore,
        'checksum_extracted': comparison.checksumExtracted,
        'checksum_ground_truth': comparison.checksumGroundTruth,
        'match_rate': comparison.matchRate,
        'field_accuracy': comparison.fieldAccuracy,
      },
      'stage_metrics': stageMetrics,
      'performance': performance,
      'items': itemsTrace,
    };
  }

  /// Generate MD scorecard from the JSON trace.
  String generateScorecard({
    required Map<String, dynamic> jsonTrace,
    required Map<String, dynamic>? previousReport,
    required bool noGate,
    required bool resetBaseline,
    required RegressionResult regressionResult,
  }) {
    final metadata = jsonTrace['metadata'] as Map<String, dynamic>;
    final summary = jsonTrace['summary'] as Map<String, dynamic>;
    final stageMetrics = jsonTrace['stage_metrics'] as Map<String, dynamic>;
    final performance = jsonTrace['performance'] as Map<String, dynamic>;
    final items = jsonTrace['items'] as Map<String, dynamic>;
    final versions = metadata['versions'] as Map<String, dynamic>;

    final buf = StringBuffer();

    // Header
    final durationSec = (metadata['pipeline_duration_ms'] as int) / 1000;
    final regressionCount = regressionResult.regressions.length;
    String verdict;
    if (noGate) {
      verdict = '(NO-GATE MODE — assertions skipped)';
    } else if (resetBaseline) {
      verdict = '(BASELINE RESET — previous baseline archived)';
    } else if (regressionResult.passed) {
      verdict = 'PASS (0 regressions)';
    } else {
      verdict = 'FAIL ($regressionCount regressions)';
    }

    buf.writeln('# Springfield Extraction Scorecard');
    buf.writeln('> Date: ${metadata['date']} | Platform: ${metadata['platform']} | Tesseract: ${versions['tesseract']}');
    buf.writeln('> Git: ${metadata['git_hash']} | Duration: ${durationSec.toStringAsFixed(0)}s | Verdict: $verdict');
    buf.writeln('> Versions: Flutter ${versions['flutter']} | Dart ${versions['dart']} | pdfrx ${versions['pdfrx']} | flusseract ${versions['flusseract']}');
    buf.writeln();

    // Regressions section (if any)
    if (regressionResult.regressions.isNotEmpty) {
      buf.writeln('## Regressions');
      buf.writeln();
      for (final r in regressionResult.regressions) {
        buf.writeln('- $r');
      }
      buf.writeln();
    }

    if (regressionResult.schemaWarning != null) {
      buf.writeln('> **Warning:** ${regressionResult.schemaWarning}');
      buf.writeln();
    }

    // Stage Statistics Table
    buf.writeln('## Stage Statistics');
    buf.writeln();
    buf.writeln('| Stage | Metric | Current | Previous | Delta | Time (ms) | Status |');
    buf.writeln('|-------|--------|---------|----------|-------|-----------|--------|');

    final prevStageMetrics = previousReport != null
        ? previousReport['stage_metrics'] as Map<String, dynamic>? ?? {}
        : <String, dynamic>{};

    for (final stageEntry in stageMetrics.entries) {
      final stageKey = stageEntry.key;
      final stageData = stageEntry.value as Map<String, dynamic>;
      final prevStageData = prevStageMetrics[stageKey] as Map<String, dynamic>?;
      final elapsedMs = stageData['elapsed_ms'];
      bool firstMetricInStage = true;

      for (final metricEntry in stageData.entries) {
        if (metricEntry.key == 'elapsed_ms') continue;
        final current = metricEntry.value;
        final previous = prevStageData?[metricEntry.key];
        final deltaStr = _formatDelta(current, previous);
        final status = _metricStatus(current, previous);
        final timeStr = firstMetricInStage ? '$elapsedMs' : '—';
        final stageLabel = firstMetricInStage ? _stageLabel(stageKey) : '';
        buf.writeln('| $stageLabel | ${metricEntry.key} | $current | ${previous ?? '—'} | $deltaStr | $timeStr | $status |');
        firstMetricInStage = false;
      }
    }
    buf.writeln();

    // Performance Summary
    buf.writeln('## Performance Summary');
    buf.writeln();
    buf.writeln('| Metric | Value |');
    buf.writeln('|--------|-------|');
    buf.writeln('| Total Duration | ${durationSec.toStringAsFixed(0)}s |');

    final breakdown = performance['stage_breakdown_pct'] as Map<String, dynamic>? ?? {};
    for (final entry in breakdown.entries) {
      buf.writeln('| ${_capitalize(entry.key)} Time | ${entry.value}% |');
    }
    buf.writeln();

    // Item Flow Table
    buf.writeln('## Item Flow (${summary['ground_truth_items']} Ground Truth Items)');
    buf.writeln();
    buf.writeln('| # | Verdict | Description (trunc) | Unit E/A | Amount E/A | \$ Delta |');
    buf.writeln('|---|---------|---------------------|----------|------------|---------|');

    for (final itemEntry in items.entries) {
      final itemData = itemEntry.value as Map<String, dynamic>;
      final gtComp = itemData['gt_comparison'] as Map<String, dynamic>? ?? {};
      final verdict = itemData['verdict'] ?? 'MISS';
      final finalStage = itemData['stage_5_final'] as Map<String, dynamic>?;
      final gt = itemData['ground_truth'] as Map<String, dynamic>?;

      final desc = _truncate(finalStage?['description']?.toString() ?? '—', 20);
      final unitExpected = gt?['unit'] ?? '—';
      final unitActual = finalStage?['unit'] ?? '—';
      final amountExpected = gt?['bid_amount']?.toString() ?? '—';
      final amountActual = finalStage?['bid_amount']?.toString() ?? '—';
      final delta = (finalStage?['bid_amount'] != null && gt?['bid_amount'] != null)
          ? ((finalStage!['bid_amount'] as num).toDouble() - (gt!['bid_amount'] as num).toDouble())
          : null;
      final deltaStr = delta != null ? '\$${delta.toStringAsFixed(0)}' : '—';

      buf.writeln('| ${itemEntry.key} | $verdict | $desc | $unitExpected/$unitActual | $amountExpected/$amountActual | $deltaStr |');
    }
    buf.writeln();

    // Summary footer
    final pass = summary['items_extracted'] as int? ?? 0;
    final matchRate = summary['match_rate'] as double? ?? 0.0;
    final fieldAcc = summary['field_accuracy'] as Map<String, dynamic>? ?? {};
    buf.writeln('## Summary');
    buf.writeln('- Items: $pass / ${summary['ground_truth_items']} GT (${(matchRate * 100).toStringAsFixed(1)}%)');
    buf.writeln('- Checksum: \$${(summary['checksum_extracted'] as num).toStringAsFixed(2)} / \$${(summary['checksum_ground_truth'] as num).toStringAsFixed(2)} GT');

    final accParts = fieldAcc.entries.map((e) =>
      '${e.key} ${((e.value as num).toDouble() * 100).toStringAsFixed(1)}%'
    ).join(' | ');
    buf.writeln('- Field Accuracy: $accParts');
    buf.writeln();

    return buf.toString();
  }

  // --- Private helpers ---

  Map<String, dynamic> _buildStageMetrics(
    List<StageReport> stageReports,
    Map<String, Map<String, dynamic>> stageOutputs,
  ) {
    final metrics = <String, dynamic>{};
    for (final report in stageReports) {
      final key = _stageKeyFromName(report.stageName);
      metrics[key] = {
        'elapsed_ms': report.elapsed.inMilliseconds,
        ...report.metrics,
      };
    }
    return metrics;
  }

  Map<String, dynamic> _buildItemsTrace(
    List<ParsedBidItem> extracted,
    List<ParsedBidItem> groundTruth,
    Map<String, Map<String, dynamic>> stageOutputs,
    ComparisonResult comparison,
  ) {
    final trace = <String, dynamic>{};

    // Build GT lookup
    final gtByNumber = <String, ParsedBidItem>{};
    for (final gt in groundTruth) {
      if (gt.itemNumber != null) gtByNumber[gt.itemNumber!] = gt;
    }

    // Build comparison lookup
    final compByNumber = <String, ItemComparison>{};
    for (final comp in comparison.items) {
      compByNumber[comp.itemNumber] = comp;
    }

    // Trace all GT items
    for (final gt in groundTruth) {
      final itemNum = gt.itemNumber ?? '';
      final comp = compByNumber[itemNum];

      final itemTrace = <String, dynamic>{
        'ground_truth': {
          'description': gt.description,
          'unit': gt.unit,
          'quantity': gt.quantity,
          'unit_price': gt.unitPrice,
          'bid_amount': gt.bidAmount,
        },
      };

      // Add per-stage data from stageOutputs if available
      // NOTE: Stage outputs are raw Map<String, dynamic> from onStageOutput.
      // The report traces what data was available for this item at each stage.
      // Full per-item-per-stage tracing requires parsing each stage's output
      // format, which varies by stage. This is captured as raw data.

      if (comp != null) {
        // GT comparison
        final gtComparison = <String, dynamic>{};
        for (final field in comp.fields) {
          gtComparison[field.fieldName] = field.matches ? 'PASS' : 'FAIL';
          if (!field.matches) {
            gtComparison['${field.fieldName}_expected'] = field.expected;
            gtComparison['${field.fieldName}_actual'] = field.actual;
          }
        }
        itemTrace['gt_comparison'] = gtComparison;
        itemTrace['verdict'] = comp.verdict.name.toUpperCase();
      } else {
        itemTrace['verdict'] = 'MISS';
      }

      trace[itemNum] = itemTrace;
    }

    // Add BOGUS items
    for (final comp in comparison.items.where((c) => c.verdict == ItemVerdict.bogus)) {
      trace[comp.itemNumber] = {
        'verdict': 'BOGUS',
      };
    }

    return trace;
  }

  Map<String, dynamic> _buildPerformance(PipelineResult result) {
    final totalMs = result.totalElapsed.inMilliseconds;
    if (totalMs == 0) {
      return {'total_pipeline_ms': 0, 'stage_breakdown_pct': {}};
    }

    final breakdown = <String, double>{};
    final cpuIntensive = <String>[];

    for (final report in result.stageReports) {
      final key = _stageKeyFromName(report.stageName);
      final pct = (report.elapsed.inMilliseconds / totalMs) * 100;
      breakdown[key] = double.parse(pct.toStringAsFixed(1));
      if (pct > 5.0) cpuIntensive.add(key);
    }

    return {
      'total_pipeline_ms': totalMs,
      'stage_breakdown_pct': breakdown,
      'cpu_intensive_stages': cpuIntensive,
    };
  }

  String _detectPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isAndroid) return _getDeviceModel() ?? 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  String? _getDeviceModel() {
    // FROM SPEC: Platform identifier uses device model slug (e.g., "sm-s938u")
    // On Android, read from system property.
    // NOTE: In integration test context, this will be passed via dart-define
    // or detected from the device.
    final model = const String.fromEnvironment('DEVICE_MODEL', defaultValue: '');
    if (model.isNotEmpty) return model.toLowerCase();

    // Fallback: try to read from Android system properties
    if (Platform.isAndroid) {
      try {
        final result = Process.runSync('getprop', ['ro.product.model']);
        final m = result.stdout.toString().trim().toLowerCase().replaceAll(' ', '-');
        if (m.isNotEmpty) return m;
      } catch (_) {}
    }
    return null;
  }

  String _stageKeyFromName(String stageName) {
    // Convert stage_names.dart constants to report-friendly keys
    return stageName;
  }

  static String _stageLabel(String stageKey) {
    // Truncate for table display
    if (stageKey.length > 25) return '${stageKey.substring(0, 22)}...';
    return stageKey;
  }

  static String _formatDelta(dynamic current, dynamic previous) {
    if (previous == null) return '—';
    if (current is num && previous is num) {
      final delta = current - previous;
      if (delta == 0) return '0';
      return delta > 0 ? '+$delta' : '$delta';
    }
    return current == previous ? '0' : 'changed';
  }

  static String _metricStatus(dynamic current, dynamic previous) {
    if (previous == null) return 'NEW';
    if (current == previous) return 'OK';
    if (current is num && previous is num) {
      return current >= previous ? 'OK' : 'REGRESSED';
    }
    return 'CHANGED';
  }

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen - 3)}...';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
```

**Verification:**
```
pwsh -Command "flutter analyze test/features/pdf/extraction/golden/report_generator.dart"
```
Expected: No errors. Warnings about unused imports are OK at this stage.

### Sub-phase 2.2: Add Report I/O Helpers

**Step 2.2.1:** Add file I/O methods to `ReportGenerator` for saving and loading reports.

Append to `report_generator.dart`:

```dart
// ============================================================================
// Report I/O
// FROM SPEC: "latest-<platform>/ baseline, dated archives, max 20 per platform"
// ============================================================================

class ReportIO {
  /// Base directory for reports.
  /// Desktop: test/features/pdf/extraction/reports/
  /// Android: <app-docs>/extraction_reports/
  final String baseDir;

  ReportIO(this.baseDir);

  /// Save report as latest-<platform>/ and dated archive.
  ///
  /// FROM SPEC: "Saves new report as both latest-<platform>/ (overwrites)
  ///             and dated archive <platform>_<date>_<time>/"
  void saveReport({
    required String platform,
    required Map<String, dynamic> jsonTrace,
    required String scorecard,
  }) {
    // SECURITY: Sanitize platform name to prevent path traversal
    // ignore: parameter_assignments
    platform = platform.replaceAll(RegExp(r'[/\\.]'), '-').toLowerCase();
    final encoder = const JsonEncoder.withIndent('  ');

    // Save to latest-<platform>/
    final latestDir = Directory('$baseDir/latest-$platform');
    if (latestDir.existsSync()) {
      // Overwrite existing
      File('${latestDir.path}/report.json').writeAsStringSync(encoder.convert(jsonTrace));
      File('${latestDir.path}/scorecard.md').writeAsStringSync(scorecard);
    } else {
      latestDir.createSync(recursive: true);
      File('${latestDir.path}/report.json').writeAsStringSync(encoder.convert(jsonTrace));
      File('${latestDir.path}/scorecard.md').writeAsStringSync(scorecard);
    }

    // Save dated archive
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final archiveDir = Directory('$baseDir/${platform}_${dateStr}_$timeStr');
    archiveDir.createSync(recursive: true);
    File('${archiveDir.path}/report.json').writeAsStringSync(encoder.convert(jsonTrace));
    File('${archiveDir.path}/scorecard.md').writeAsStringSync(scorecard);

    // Enforce archive retention: max 20 per platform
    _enforceRetention(platform);
  }

  /// Archive current baseline (for RESET_BASELINE mode).
  void archiveBaseline(String platform) {
    final latestDir = Directory('$baseDir/latest-$platform');
    if (!latestDir.existsSync()) return;

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final archiveName = '${platform}_${dateStr}_${timeStr}_archived';
    final archiveDir = Directory('$baseDir/$archiveName');
    latestDir.renameSync(archiveDir.path);
  }

  /// Load previous report.json for regression comparison.
  Map<String, dynamic>? loadPreviousReport(String platform) {
    final reportFile = File('$baseDir/latest-$platform/report.json');
    if (!reportFile.existsSync()) return null;
    try {
      return jsonDecode(reportFile.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Enforce max 20 dated archives per platform.
  /// FROM SPEC: "Keep the last 20 dated report folders per platform."
  void _enforceRetention(String platform) {
    final baseDirectory = Directory(baseDir);
    if (!baseDirectory.existsSync()) return;

    final archives = baseDirectory
        .listSync()
        .whereType<Directory>()
        .where((d) {
          final name = d.path.split(Platform.pathSeparator).last;
          return name.startsWith('${platform}_') && !name.startsWith('latest-');
        })
        .toList();

    // Sort by name (which includes date/time) ascending
    archives.sort((a, b) => a.path.compareTo(b.path));

    // Delete oldest if more than 20
    while (archives.length > 20) {
      final oldest = archives.removeAt(0);
      try {
        oldest.deleteSync(recursive: true);
      } catch (_) {
        // Ignore deletion failures (e.g., file lock on Windows)
      }
    }
  }
}
```

**Verification:**
```
pwsh -Command "flutter analyze test/features/pdf/extraction/golden/report_generator.dart"
```

---

## Phase 3: Build CLI Entry Point (`tools/pipeline_comparator.dart`)

**Agent:** `qa-testing-agent`
**Why third:** Depends on the comparison library from Phase 1.

### Sub-phase 3.1: Create CLI Tool

**File:** `tools/pipeline_comparator.dart` (NEW)

**Step 3.1.1:** Create the CLI entry point.

```dart
// WHY: Single CLI tool replacing gt_trace.dart, compare_golden.py, compare_stage_dumps.py.
// FROM SPEC: "CLI entry point: imports the library above, parses args, runs comparison."
//
// Usage:
//   dart run tools/pipeline_comparator.dart <report1> <report2>
//   dart run tools/pipeline_comparator.dart --ground-truth <path> <report>
//   dart run tools/pipeline_comparator.dart --cross-device <folder1> <folder2>

import 'dart:convert';
import 'dart:io';

// IMPORTANT: This CLI tool imports from test/ via relative path.
// To run, use: dart run tools/pipeline_comparator.dart
// If the relative import fails, copy pipeline_comparator.dart to a shared location
// or use: dart --packages=.dart_tool/package_config.json tools/pipeline_comparator.dart
//
// ALTERNATIVE: If dart cannot resolve test/ imports, the implementing agent should
// move the core comparison types (ComparisonResult, RegressionResult, etc.) into
// a shared file under lib/ (e.g., lib/features/pdf/services/extraction/testing/)
// that both test/ and tools/ can import. This is a known Dart packaging limitation.
import '../test/features/pdf/extraction/golden/pipeline_comparator.dart';

import 'package:construction_inspector/features/pdf/services/extraction/models/parsed_items.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final groundTruthPath = _extractFlag(args, '--ground-truth');
  final crossDevice = args.remove('--cross-device');

  if (crossDevice) {
    // Cross-device mode: compare two report folders
    if (args.length < 2) {
      stderr.writeln('Error: --cross-device requires two report folder paths');
      exit(1);
    }
    _runCrossDevice(args[0], args[1]);
  } else if (args.length == 1 && groundTruthPath != null) {
    // Single report + ground truth comparison
    _runGtComparison(args[0], groundTruthPath);
  } else if (args.length == 2) {
    // Compare two reports
    _runReportComparison(args[0], args[1]);
  } else {
    _printUsage();
    exit(1);
  }
}

void _runGtComparison(String reportPath, String gtPath) {
  final report = _loadJson('$reportPath/report.json');
  final groundTruth = PipelineComparator.loadGroundTruth(gtPath);
  // Extract items from report
  final items = _extractItemsFromReport(report);

  final comparator = PipelineComparator();
  final result = comparator.compare(items, groundTruth);

  _printComparisonResult(result);
}

void _runReportComparison(String path1, String path2) {
  final report1 = _loadJson('$path1/report.json');
  final report2 = _loadJson('$path2/report.json');

  final gate = RegressionGate();
  final result = gate.evaluate(
    currentReport: report1,
    previousReport: report2,
  );

  print('=== Regression Gate ===');
  print('Passed: ${result.passed}');
  if (result.schemaWarning != null) {
    print('Warning: ${result.schemaWarning}');
  }
  for (final r in result.regressions) {
    print('  REGRESSION: $r');
  }
}

void _runCrossDevice(String folder1, String folder2) {
  final report1 = _loadJson('$folder1/report.json');
  final report2 = _loadJson('$folder2/report.json');

  final meta1 = report1['metadata'] as Map<String, dynamic>? ?? {};
  final meta2 = report2['metadata'] as Map<String, dynamic>? ?? {};
  final summary1 = report1['summary'] as Map<String, dynamic>? ?? {};
  final summary2 = report2['summary'] as Map<String, dynamic>? ?? {};

  print('=== Cross-Device Comparison ===');
  print('');
  print('Platform 1: ${meta1['platform']} (${meta1['date']})');
  print('Platform 2: ${meta2['platform']} (${meta2['date']})');
  print('');
  print('| Metric | ${meta1['platform']} | ${meta2['platform']} | Delta |');
  print('|--------|${'-' * 10}|${'-' * 10}|-------|');

  for (final key in ['items_extracted', 'overall_quality', 'match_rate',
                      'checksum_extracted']) {
    final v1 = summary1[key];
    final v2 = summary2[key];
    final delta = (v1 is num && v2 is num) ? (v1 - v2).toStringAsFixed(3) : '—';
    print('| $key | $v1 | $v2 | $delta |');
  }

  // Field accuracy comparison
  final fa1 = summary1['field_accuracy'] as Map<String, dynamic>? ?? {};
  final fa2 = summary2['field_accuracy'] as Map<String, dynamic>? ?? {};
  for (final field in fa1.keys) {
    final v1 = fa1[field];
    final v2 = fa2[field];
    final delta = (v1 is num && v2 is num) ? (v1 - v2).toStringAsFixed(3) : '—';
    print('| $field accuracy | $v1 | $v2 | $delta |');
  }
}

Map<String, dynamic> _loadJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Error: File not found: $path');
    exit(1);
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

List<ParsedBidItem> _extractItemsFromReport(Map<String, dynamic> report) {
  // Extract final items from report's items section
  final items = report['items'] as Map<String, dynamic>? ?? {};
  final result = <ParsedBidItem>[];
  for (final entry in items.entries) {
    final itemData = entry.value as Map<String, dynamic>;
    final finalStage = itemData['stage_5_final'] as Map<String, dynamic>?;
    if (finalStage != null) {
      result.add(ParsedBidItem(
        itemNumber: finalStage['item_number'] as String?,
        description: finalStage['description'] as String?,
        unit: finalStage['unit'] as String?,
        quantity: (finalStage['quantity'] as num?)?.toDouble(),
        unitPrice: (finalStage['unit_price'] as num?)?.toDouble(),
        bidAmount: (finalStage['bid_amount'] as num?)?.toDouble(),
        confidence: (finalStage['confidence'] as num?)?.toDouble() ?? 0.0,
        fieldsPresent: 6,
      ));
    }
  }
  return result;
}

String? _extractFlag(List<String> args, String flag) {
  final idx = args.indexOf(flag);
  if (idx == -1) return null;
  if (idx + 1 >= args.length) {
    stderr.writeln('Error: $flag requires a value');
    exit(1);
  }
  final value = args[idx + 1];
  args.removeRange(idx, idx + 2);
  return value;
}

void _printComparisonResult(ComparisonResult result) {
  print('=== Ground Truth Comparison ===');
  print('');
  print('PASS: ${result.passCount} | FAIL: ${result.failCount} | '
        'MISS: ${result.missCount} | BOGUS: ${result.bogusCount}');
  print('Items: ${result.extractedCount} / ${result.groundTruthCount} GT '
        '(${(result.matchRate * 100).toStringAsFixed(1)}%)');
  print('Checksum: \$${result.checksumExtracted.toStringAsFixed(2)} / '
        '\$${result.checksumGroundTruth.toStringAsFixed(2)} GT');
  print('');
  print('Field Accuracy:');
  for (final entry in result.fieldAccuracy.entries) {
    print('  ${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%');
  }
}

void _printUsage() {
  print('Usage:');
  print('  dart run tools/pipeline_comparator.dart <report_folder1> <report_folder2>');
  print('  dart run tools/pipeline_comparator.dart --ground-truth <gt.json> <report_folder>');
  print('  dart run tools/pipeline_comparator.dart --cross-device <folder1> <folder2>');
}
```

**Verification:**
```
pwsh -Command "dart analyze tools/pipeline_comparator.dart"
```
Expected: No errors.

---

## Phase 4: Build Integration Test (`springfield_report_test.dart`)

**Agent:** `qa-testing-agent`
**Why fourth:** Depends on both the comparator (Phase 1) and report generator (Phase 2).

### Sub-phase 4.1: Create Integration Test

**File:** `integration_test/springfield_report_test.dart` (NEW)

**Step 4.1.1:** Create the integration test with the full doc header from the spec.

```dart
/// # Springfield Pipeline Report Test
///
/// ## How It Works
/// Runs the full extraction pipeline against the Springfield PDF, capturing
/// output from all 27 stage callbacks (22 data-transforming + 5 metadata-only)
/// for every item. Generates:
/// - JSON trace (report.json): machine-readable, every item at every stage
/// - MD scorecard (scorecard.md): stage statistics table + item flow table
///
/// Multi-attempt handling: Pipeline may run up to 3 attempts. Only the best
/// attempt's stages are captured (selected by item count, matching the fixture
/// generator's behavior). Attempt metadata is recorded in report.json.
///
/// Compares against previous run (regression gate, per-platform baseline).
/// If any metric regresses, the test fails. First run with no previous
/// baseline always passes.
///
/// This test REPLACES generate_golden_fixtures_test.dart — it does everything
/// the fixture generator did plus reporting and regression gating.
///
/// ## Commands
///
/// Windows:
///   flutter test integration_test/springfield_report_test.dart \
///     -d windows --dart-define=SPRINGFIELD_PDF="C:\path\to\springfield.pdf"
///
/// Galaxy S25 Ultra:
///   flutter test integration_test/springfield_report_test.dart \
///     -d R5CY12JTTPX --dart-define=SPRINGFIELD_PDF="/sdcard/springfield.pdf"
///
/// Galaxy S21+:
///   flutter test integration_test/springfield_report_test.dart \
///     -d RFCNC0Y975L --dart-define=SPRINGFIELD_PDF="/sdcard/springfield.pdf"
///
/// Galaxy Tab S10+:
///   flutter test integration_test/springfield_report_test.dart \
///     -d R52X90378YB --dart-define=SPRINGFIELD_PDF="/sdcard/springfield.pdf"
///
/// Exploratory (no regression gate):
///   flutter test integration_test/springfield_report_test.dart \
///     -d windows --dart-define=SPRINGFIELD_PDF="..." --dart-define=NO_GATE=true
///
/// Reset baseline (archive current, establish new):
///   flutter test integration_test/springfield_report_test.dart \
///     -d windows --dart-define=SPRINGFIELD_PDF="..." --dart-define=RESET_BASELINE=true
///
/// Pull reports from Android device:
///   adb -s <serial> shell 'run-as com.fieldguideapp.inspector \
///     cp -r files/extraction_reports/ /sdcard/extraction_reports/'
///   adb -s <serial> pull /sdcard/extraction_reports/ \
///     test/features/pdf/extraction/reports/
///
/// CLI Comparison (any two report folders):
///   dart run tools/pipeline_comparator.dart \
///     reports/latest-windows reports/latest-sm-s938u
///
/// CLI with custom ground truth:
///   dart run tools/pipeline_comparator.dart \
///     --ground-truth path/to/ground_truth.json \
///     reports/latest-windows reports/sm-s938u_2026-03-10
///
/// ## Output Location
/// Desktop: test/features/pdf/extraction/reports/
///   latest-<platform>/  - current run (regression gate baseline, per-platform)
///   <platform>_<date>_<time>/  - dated archive per run (max 20 per platform)
///
/// Android: <app-docs>/extraction_reports/
///   (pull to desktop via adb commands above)
///
/// ## How To Reset Baseline
/// Option A: Delete reports/latest-<platform>/ folder. Next run establishes new baseline.
/// Option B: Use --dart-define=RESET_BASELINE=true (archives current baseline first).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:construction_inspector/features/pdf/services/extraction/models/models.dart';
import 'package:construction_inspector/features/pdf/services/extraction/pipeline/extraction_pipeline.dart';
import 'package:construction_inspector/features/pdf/services/extraction/stages/stage_names.dart';
import 'package:construction_inspector/features/pdf/services/extraction/stages/stage_fixtures.dart';

// NOTE: Importing from test/ into integration_test/ — this works because
// both directories are under the project root and dart resolves relative paths.
import '../test/features/pdf/extraction/golden/pipeline_comparator.dart';
import '../test/features/pdf/extraction/golden/report_generator.dart';

// ============================================================================
// Configuration from dart-define
// ============================================================================

const _springfieldPdfPath = String.fromEnvironment('SPRINGFIELD_PDF');
const _noGate = bool.fromEnvironment('NO_GATE');
const _resetBaseline = bool.fromEnvironment('RESET_BASELINE');

// Ground truth path — fixed location
const _groundTruthPath =
    'test/features/pdf/extraction/fixtures/springfield_ground_truth_items.json';

// Report output base directory (desktop)
const _desktopReportDir = 'test/features/pdf/extraction/reports';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Springfield pipeline report — full trace + regression gate',
    (tester) async {
      // --- Validate inputs ---
      if (_springfieldPdfPath.isEmpty) {
        // ignore: avoid_print
        print('SKIPPED: Set SPRINGFIELD_PDF path via --dart-define');
        // ignore: avoid_print
        print(
          'Usage: flutter test integration_test/springfield_report_test.dart '
          '-d windows --dart-define=SPRINGFIELD_PDF="<path>"',
        );
        return;
      }

      final pdfFile = File(_springfieldPdfPath);
      expect(
        pdfFile.existsSync(),
        isTrue,
        reason: 'PDF not found at $_springfieldPdfPath',
      );
      final pdfBytes = pdfFile.readAsBytesSync();

      // --- Determine platform and report directory ---
      final reportGen = ReportGenerator();
      final platform = _detectPlatform();
      final reportDir = _getReportDir();

      // ignore: avoid_print
      print('Platform: $platform');
      // ignore: avoid_print
      print('Report dir: $reportDir');
      // ignore: avoid_print
      print('PDF: $_springfieldPdfPath (${pdfBytes.length} bytes)');
      // ignore: avoid_print
      print('No-gate: $_noGate | Reset-baseline: $_resetBaseline');
      // ignore: avoid_print
      print('');

      // --- Load ground truth ---
      final groundTruth = _loadGroundTruth();
      // ignore: avoid_print
      print('Ground truth: ${groundTruth.length} items');

      // --- Run pipeline with stage capture ---
      final pipeline = ExtractionPipeline();

      // FROM SPEC: "Capture outputs per attempt, keyed by attempt number"
      final attemptOutputs = <int, Map<String, Map<String, dynamic>>>{};
      int currentAttempt = 0;
      int stageCount = 0;

      final result = await pipeline.extract(
        pdfBytes: Uint8List.fromList(pdfBytes),
        documentId: 'springfield-864130',
        config: const PipelineConfig(),
        onStageOutput: (stageName, output) {
          // Detect new attempt when we see Stage 0 again
          if (stageName == StageNames.documentAnalysis && stageCount > 0) {
            currentAttempt++;
          }
          stageCount++;
          attemptOutputs.putIfAbsent(currentAttempt, () => {});
          attemptOutputs[currentAttempt]![stageName] = Map<String, dynamic>.from(output);
          // ignore: avoid_print
          print('[attempt $currentAttempt] Captured $stageName');
        },
      );

      // --- Select best attempt ---
      // FROM SPEC: "best attempt is identified by item count (most items = best quality)"
      int bestAttempt = 0;
      int bestItems = 0;
      for (final entry in attemptOutputs.entries) {
        final processedData = entry.value[StageNames.postProcessing];
        if (processedData != null) {
          final items = processedData['items'] as List?;
          final count = items?.length ?? 0;
          if (count > bestItems) {
            bestItems = count;
            bestAttempt = entry.key;
          }
        }
      }
      final stageOutputs = attemptOutputs[bestAttempt] ?? {};
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('Selected attempt $bestAttempt with $bestItems items');

      // Cleanup OCR engine
      pipeline.ocrEngine.dispose();

      // --- Set Tesseract version ---
      try {
        // IMPORTANT: This accesses the native FFI binding
        reportGen.tesseractVersion = _getTesseractVersionSafe();
      } catch (_) {
        reportGen.tesseractVersion = 'unknown';
      }

      // --- Generate JSON trace ---
      final reportIO = ReportIO(reportDir);
      final previousReport = reportIO.loadPreviousReport(platform);

      final jsonTrace = reportGen.generateJsonTrace(
        result: result,
        stageOutputs: stageOutputs,
        groundTruth: groundTruth,
        previousReport: previousReport,
        bestAttemptIndex: bestAttempt,
        totalAttempts: result.totalAttempts,
      );

      // --- Run regression gate ---
      final gate = RegressionGate();
      Map<String, dynamic>? baselineForGate = previousReport;

      // Handle RESET_BASELINE mode
      if (_resetBaseline && previousReport != null) {
        reportIO.archiveBaseline(platform);
        baselineForGate = null; // No baseline after archiving
        // ignore: avoid_print
        print('Archived previous baseline for $platform');
      }

      final regressionResult = gate.evaluate(
        currentReport: jsonTrace,
        previousReport: baselineForGate,
      );

      // --- Generate scorecard ---
      final scorecard = reportGen.generateScorecard(
        jsonTrace: jsonTrace,
        previousReport: baselineForGate,
        noGate: _noGate,
        resetBaseline: _resetBaseline,
        regressionResult: regressionResult,
      );

      // --- Save reports ---
      reportIO.saveReport(
        platform: platform,
        jsonTrace: jsonTrace,
        scorecard: scorecard,
      );

      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('=== Report saved to $reportDir/latest-$platform/ ===');
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print(scorecard);

      // --- Assertions (regression gate) ---
      if (!_noGate && !_resetBaseline) {
        if (regressionResult.schemaWarning != null) {
          // ignore: avoid_print
          print('WARNING: ${regressionResult.schemaWarning}');
        }

        expect(
          regressionResult.passed,
          isTrue,
          reason: 'Regression gate failed:\n${regressionResult.regressions.join('\n')}',
        );
      }

      // Basic sanity assertions (always run)
      expect(
        result.processedItems.items.length,
        greaterThan(0),
        reason: 'Pipeline must extract at least 1 item',
      );
      expect(
        result.qualityReport.overallScore,
        greaterThan(0.0),
        reason: 'Quality score must be > 0',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

// ============================================================================
// Helpers
// ============================================================================

String _detectPlatform() {
  if (Platform.isWindows) return 'windows';
  if (Platform.isAndroid) {
    final model = const String.fromEnvironment('DEVICE_MODEL', defaultValue: '');
    if (model.isNotEmpty) return model.toLowerCase();
    try {
      final result = Process.runSync('getprop', ['ro.product.model']);
      final m = result.stdout.toString().trim().toLowerCase().replaceAll(' ', '-');
      if (m.isNotEmpty) return m;
    } catch (_) {}
    return 'android';
  }
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}

String _getReportDir() {
  if (Platform.isAndroid) {
    // FROM SPEC: "On-device: writes to app-accessible storage"
    // Use app documents directory
    // NOTE: path_provider is not available in integration tests without
    // widget binding. Use a known app-writable path.
    return '/data/data/com.fieldguideapp.inspector/files/extraction_reports';
  }
  return _desktopReportDir;
}

List<ParsedBidItem> _loadGroundTruth() {
  if (Platform.isAndroid) {
    // On Android, try app-bundled path first, then sdcard
    for (final path in [
      '/data/data/com.fieldguideapp.inspector/files/$_groundTruthPath',
      '/sdcard/$_groundTruthPath',
      _groundTruthPath,
    ]) {
      final file = File(path);
      if (file.existsSync()) {
        return PipelineComparator.loadGroundTruth(path);
      }
    }
    throw FileSystemException(
      'Ground truth file not found on device. '
      'Push it via: adb push $_groundTruthPath /sdcard/$_groundTruthPath',
    );
  }
  return PipelineComparator.loadGroundTruth(_groundTruthPath);
}

String _getTesseractVersionSafe() {
  try {
    // Access the flusseract Tesseract.version static getter
    // This requires the native library to be loaded
    // IMPORTANT: Import at top of file for this to work
    return 'unknown'; // TODO: Replace with actual Tesseract.version call
    // The implementing agent should add:
    //   import 'package:flusseract/tesseract.dart';
    //   return Tesseract.version;
  } catch (_) {
    return 'unknown';
  }
}
```

**IMPORTANT NOTE FOR IMPLEMENTING AGENT:** The `_getTesseractVersionSafe()` function has a TODO. When implementing, add:
```dart
import 'package:flusseract/tesseract.dart';
```
at the top of the file, and replace the function body with:
```dart
return Tesseract.version;
```
Wrap in try/catch since the native library may not be available in all contexts.

**Verification:**
```
pwsh -Command "flutter analyze integration_test/springfield_report_test.dart"
```
Expected: No errors. The test itself requires a PDF path to run.

---

## Phase 5: Update `.gitignore` and Dependent Files

**Agent:** `qa-testing-agent`
**Why fifth:** Must be done before verification (Phase 6) so reports directory is properly gitignored.

### Sub-phase 5.1: Update `.gitignore`

**File:** `.gitignore`

**Step 5.1.1:** Add the reports directory to `.gitignore`.

Add the following after line 86 (`test/features/pdf/extraction/fixtures/diagnostic_images/`):

```
# Pipeline report outputs (platform-specific, not tracked)
test/features/pdf/extraction/reports/
```

**Verification:** `git status` should not show the reports directory as untracked after a test run.

### Sub-phase 5.2: Update `full_pipeline_integration_test.dart`

**File:** `test/features/pdf/extraction/integration/full_pipeline_integration_test.dart`

**Step 5.2.1:** Update the import on line 27.

Change:
```dart
import '../golden/golden_file_matcher.dart';
```
To:
```dart
import '../golden/pipeline_comparator.dart';
```

**Step 5.2.2:** Update the GoldenFileMatcher usage on lines 471-486.

Change:
```dart
      test('golden file match rate >= 95%', () {
        final matcher = GoldenFileMatcher();
        // Compare golden items against themselves (100% match expected)
        final matchResult = matcher.compare(goldenItems, goldenItems);
        if (hasGoldenItems()) {
          expect(matchResult.matchRate, 1.0);
        } else {
          logFixtureGate(
            'golden file match rate >= 95%',
            'empty-vs-empty matcher semantics define matchRate as 0.0',
          );
          expect(matchResult.matchRate, 0.0);
        }
        expect(matchResult.unmatchedActual, isEmpty);
        expect(matchResult.unmatchedExpected, isEmpty);
      });
```
To:
```dart
      test('golden file match rate >= 95%', () {
        final comparator = PipelineComparator();
        // Compare golden items against themselves (100% match expected)
        final matchResult = comparator.compareCompat(goldenItems, goldenItems);
        if (hasGoldenItems()) {
          expect(matchResult.matchRate, 1.0);
        } else {
          logFixtureGate(
            'golden file match rate >= 95%',
            'empty-vs-empty comparator semantics define matchRate as 0.0',
          );
          expect(matchResult.matchRate, 0.0);
        }
        expect(matchResult.unmatchedActual, isEmpty);
        expect(matchResult.unmatchedExpected, isEmpty);
      });
```

**Verification:**
```
pwsh -Command "flutter test test/features/pdf/extraction/integration/full_pipeline_integration_test.dart"
```
Expected: Tests pass (or skip due to empty fixtures, which is the existing behavior).

---

## Phase 6: Verification

**Agent:** `qa-testing-agent`
**Why sixth:** Must verify the new system works before deleting old files.

### Sub-phase 6.1: Static Analysis

**Step 6.1.1:** Run flutter analyze on all new and modified files.

```
pwsh -Command "flutter analyze test/features/pdf/extraction/golden/pipeline_comparator.dart test/features/pdf/extraction/golden/report_generator.dart integration_test/springfield_report_test.dart test/features/pdf/extraction/integration/full_pipeline_integration_test.dart"
```
Expected: No errors.

### Sub-phase 6.2: Run Existing Tests

**Step 6.2.1:** Verify existing tests still pass with the modified `full_pipeline_integration_test.dart`.

```
pwsh -Command "flutter test test/features/pdf/extraction/"
```
Expected: All existing tests pass (the ones that don't depend on deleted files).

### Sub-phase 6.3: Windows Integration Test (if PDF available)

**Step 6.3.1:** Run the new integration test on Windows.

```
pwsh -Command "flutter test integration_test/springfield_report_test.dart -d windows --dart-define=SPRINGFIELD_PDF='C:\path\to\springfield.pdf'"
```
Expected output:
- Report files created in `test/features/pdf/extraction/reports/latest-windows/`
- `report.json` contains all fields from spec schema
- `scorecard.md` is readable with correct format
- Regression gate passes (first run, no baseline)

**NOTE FOR IMPLEMENTING AGENT:** The PDF path must be replaced with the actual path on the dev machine. If the PDF is not available, this step can be deferred to manual testing.

---

## Phase 7: Delete Old Files

**Agent:** `qa-testing-agent`
**Why last:** FROM SPEC: "Old tests deleted only after new system verified"

### Sub-phase 7.1: Delete Test Files

**Step 7.1.1:** Delete the following files (verify each exists before deleting):

```
test/features/pdf/extraction/golden/stage_trace_diagnostic_test.dart       (4,876 lines)
test/features/pdf/extraction/golden/springfield_golden_test.dart           (630 lines)
test/features/pdf/extraction/golden/springfield_benchmark_test.dart        (280 lines)
test/features/pdf/extraction/golden/golden_file_matcher.dart               (533 lines)
test/features/pdf/extraction/golden/golden_file_matcher_test.dart          (~200 lines)
test/features/pdf/extraction/golden/README.md                              (256 lines)
test/features/pdf/extraction/golden/springfield_benchmark_results.json     (data file)
```

**Step 7.1.2:** Delete the integration test fixture generator:
```
integration_test/generate_golden_fixtures_test.dart                        (260 lines)
```

**Step 7.1.3:** Delete the CLI tools:
```
tools/gt_trace.dart                                                        (218 lines)
tools/compare_golden.py                                                    (156 lines)
tools/compare_stage_dumps.py                                               (223 lines)
```

**Verification after deletion:**
```
pwsh -Command "flutter test test/features/pdf/extraction/"
```
Expected: All tests pass. No import errors from deleted files.

```
pwsh -Command "flutter analyze"
```
Expected: No new analysis errors related to missing imports.

### Sub-phase 7.2: Verify No Broken Imports

**Step 7.2.1:** Search for any remaining references to deleted files.

Search for:
- `golden_file_matcher`
- `stage_trace_diagnostic_test`
- `springfield_golden_test`
- `springfield_benchmark_test`
- `generate_golden_fixtures_test`
- `gt_trace.dart`
- `compare_golden.py`
- `compare_stage_dumps.py`
- `GoldenFileMatcher`
- `MatchResult` (from golden_file_matcher — not the Flutter MatchResult)

Any remaining references in `.claude/` config files are OK (documentation/historical). Any remaining references in Dart code are a BUG that must be fixed.

**Verification:**
```
pwsh -Command "flutter analyze"
```
Expected: 0 errors.

---

## Phase Summary

| Phase | Sub-phases | Steps | Agent | Files Affected |
|-------|-----------|-------|-------|---------------|
| 1. Comparison Library | 4 | 5 | qa-testing-agent | `pipeline_comparator.dart` (NEW) |
| 2. Report Generator | 2 | 3 | qa-testing-agent | `report_generator.dart` (NEW) |
| 3. CLI Entry Point | 1 | 1 | qa-testing-agent | `tools/pipeline_comparator.dart` (NEW) |
| 4. Integration Test | 1 | 1 | qa-testing-agent | `springfield_report_test.dart` (NEW) |
| 5. Update Dependents | 2 | 3 | qa-testing-agent | `.gitignore`, `full_pipeline_integration_test.dart` |
| 6. Verification | 3 | 3 | qa-testing-agent | (no new changes) |
| 7. Delete Old Files | 2 | 5 | qa-testing-agent | 11 files deleted |
| **Total** | **15** | **21** | | **17 files** |

---

## Implementation Notes

### Critical Constraints
1. **NEVER run `flutter clean`** — prohibited by user.
2. **NEVER add "Co-Authored-By"** lines to git commits.
3. **NEVER revert changes** without being asked.
4. **Git Bash silently fails on Flutter** — always use `pwsh -Command "..."`.
5. **DO NOT delete `stage_fixtures.dart`** — still used by MP fixture generator.
6. **Phase 7 (deletion) MUST come last** — only after verification passes.

### Line Count Guardrail
FROM SPEC: "If any file exceeds ~1,500 lines during implementation, it must be decomposed."
- `pipeline_comparator.dart` is the highest risk (~600-800 est.)
- If it exceeds 1,500 lines, split into `pipeline_comparator.dart` (core) + `regression_gate.dart` (baseline logic)

### Android Testing Notes
- Integration tests on Android write to `/data/data/com.fieldguideapp.inspector/files/extraction_reports/`
- Reports must be pulled via `adb` commands documented in the test header
- Ground truth file must be pushed to device before running: `adb push test/.../springfield_ground_truth_items.json /sdcard/...`
- Regression gate works on-device using on-device baselines

### What This Plan Does NOT Cover
- M&P diagnostic test migration (future phase per spec)
- CI/CD integration (separate task)
- Performance benchmarking of the new test vs old tests

---

## Adversarial Review Findings

### Code Review

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| 1 | CRITICAL | `tools/pipeline_comparator.dart` imports from `test/` via relative path. Dart may not resolve `test/` imports from `tools/` since `test/` is not in the package's `lib/` tree. | Added detailed comment in plan with alternative: if import fails, move core types to `lib/.../testing/` shared location. Implementing agent should test `dart run tools/pipeline_comparator.dart` early and fix if needed. |
| 2 | HIGH | `_getTesseractVersionSafe()` in integration test has a TODO placeholder instead of actual `Tesseract.version` call. Could be missed by implementing agent. | Added explicit "IMPORTANT NOTE FOR IMPLEMENTING AGENT" block in Phase 4 with exact code to add. |
| 3 | HIGH | `report_generator.dart` has dead code: `_getTesseractVersion()` standalone function that always returns `'unknown'`. | MEDIUM/LOW priority — implementing agent should either remove it or wire it to actual `Tesseract.version`. The `reportGen.tesseractVersion` setter pattern is the correct approach. |
| 4 | MEDIUM | `compareCompat()` parameter naming: `actual`/`expected` in compat API vs `extracted`/`groundTruth` in `compare()`. Could confuse callers using different lists. | Acceptable for migration since `full_pipeline_integration_test.dart` calls it with identical lists (`goldenItems, goldenItems`). Add a doc comment clarifying parameter semantics. |
| 5 | MEDIUM | Unused `import 'dart:math' show min;` in `pipeline_comparator.dart`. | Remove during implementation. |
| 6 | LOW | `Process.runSync('getprop', ...)` for Android device model detection may fail in restricted environments. | Fallback to `'android'` is already in place. Acceptable. |

### Security Review

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| 1 | LOW | `ReportIO` creates directories based on platform name from `DEVICE_MODEL` dart-define. Path traversal possible if malicious value (`../../`) is passed. | Test-only infrastructure, not production code. Add sanitization in implementation: strip `/`, `\`, `..` from platform name. |
| 2 | INFO | No secrets, auth, or RLS changes. Reports directory correctly gitignored. | No action needed. |
| 3 | INFO | Ground truth file is read-only, loaded from local filesystem. No network access. | No action needed. |

**CRITICAL/HIGH findings (1-3) addressed inline in the plan.**
**MEDIUM findings (4-5) noted — address during implementation.**
**LOW/INFO findings acceptable for test infrastructure.**
