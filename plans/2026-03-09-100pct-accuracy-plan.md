# Springfield 100% Accuracy — Implementation Plan

## Revision History
- **Rev 1 (2026-03-09)**: Addressed 3 CRITICAL + 3 HIGH findings from adversarial review
  - C1: Added `_rescueBoilerplateRows` guard for item-column text
  - C2: Added R2c sub-phase (2.1b) for downstream item 95 rescue
  - C3: Fixed R3 to use `skippedRows.add()` pattern instead of non-existent `excludedCount`
  - H1: Changed merger grid lines from flat `List<double>` to per-page `Map<int, List<double>>`
  - H2: Reused existing `_EuropeanPeriodsCurrencyRule._pattern` regex from `currency_rules.dart`
  - H3: Added `isLumpSum()` guard to unknown unit warning in row_parser_v3.dart

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Raise Springfield extraction from 97 OK / 34 failures to ~129-131 OK / 0-2 failures
**Spec:** `.claude/specs/2026-03-09-100pct-accuracy-spec.md`
**Analysis:** `.claude/dependency_graphs/2026-03-09-100pct-accuracy/`

**Architecture:** Five targeted fixes (R1-R5) modify 10 source files across the extraction pipeline's shared utilities, row classification, row merging, consistency checking, and grid line removal stages. Each fix is surgically scoped: R1 stops destructive unit alias remapping (26 items), R2 fixes row classifier + merger to recover items 94/95 ($280K), R3 adds a validation gate (defense-in-depth), R4 extends math backsolve to correct bidAmount (1 item), R5 replaces morphological grid line removal with position-based masking (5-8 description items).

**Blast Radius:** 10 direct files, 4 dependent (verify-only), 8 test files, 2 cleanup items

---

## Phase 0: Verification Gate (Pre-flight)

### Step 0.1: Run existing tests to establish green baseline

**Agent:** `qa-testing-agent`

**Action:** Run the full test suite to confirm all tests pass before making changes.

```bash
pwsh -Command "flutter test"
```

**Expected outcome:** All tests pass (green baseline). If any tests fail, investigate and fix before proceeding.

### Step 0.2: Verify current GT trace score

**Agent:** `qa-testing-agent`

**Action:** Run the ground truth trace to confirm the current baseline of 97 OK / 34 failures.

```bash
pwsh -Command "dart run tools/gt_trace.dart"
```

**Expected outcome:** Output shows 97 OK, 34 failures, quality score ~0.918. Record exact numbers for comparison.

---

## Phase 1: R1 — Unit Normalization (26 items)

### Sub-phase 1.1: Add isLumpSum() helper to UnitRegistry

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/shared/unit_registry.dart`
**Lines:** After line 84 (end of `normalize()` method), before the closing `}` of the class at line 85

**WHY:** Five places in the pipeline check `== 'LS'` to detect lump sum items. After we stop normalizing LSUM->LS, these checks will break. A centralized helper ensures both `LS` and `LSUM` are recognized as lump sum.

**Code — add before the closing `}` of the class (before line 85):**

```dart
  /// Returns true if [unit] represents a Lump Sum unit.
  ///
  /// Recognizes both short ('LS') and long ('LSUM') forms, plus
  /// OCR-corrupted variants that start with 'LS'.
  static bool isLumpSum(String unit) {
    final upper = unit.toUpperCase().trim();
    return upper == 'LS' || upper == 'LSUM' || (upper.startsWith('LS') && upper.length > 2);
  }
```

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/shared/unit_registry_test.dart"
```
(Test file created in sub-phase 1.4)

---

### Sub-phase 1.2: Make normalize() cleanup-only

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/shared/unit_registry.dart`
**Lines:** 73-84 (the entire `normalize()` method body)

**WHY:** `normalize()` currently maps long forms to short forms (LSUM->LS, SYD->SY, etc.). OCR correctly reads long forms. GT expects long forms. By removing alias remapping, we preserve the raw OCR output which is already correct.

**Replace the `normalize()` method body (lines 73-84) with:**

```dart
  static String normalize(String text) {
    if (text.isEmpty) return '';
    // Cleanup only: strip accents and trim. No alias remapping.
    final cleaned = text.replaceAll(RegExp(r'[ÉÈ]'), 'E').trim();
    return cleaned.toUpperCase();
  }
```

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/shared/unit_registry_test.dart"
```

---

### Sub-phase 1.3: Update 5 hardcoded LS checks

**Agent:** `pdf-agent`

All five changes replace exact-match `== 'LS'` checks with `UnitRegistry.isLumpSum()` calls.

#### 1.3a: row_parser_v3.dart line 207

**File:** `lib/features/pdf/services/extraction/stages/row_parser_v3.dart`
**Line:** 207

**Current code:**
```dart
        if (unit != 'LS') {
```

**Replace with:**
```dart
        if (!UnitRegistry.isLumpSum(unit)) {
```

**WHY:** After R1.2, lump sum units will remain as 'LSUM' instead of being normalized to 'LS'. This check gates the "Missing or invalid quantity" warning -- lump sum items legitimately have null/zero quantity.

<!-- REVISED: H3 fix — LS-prefix fallback removal causes unknown unit warnings -->
#### 1.3a-ii: row_parser_v3.dart lines 200-203 (unknown unit warning)

**File:** `lib/features/pdf/services/extraction/stages/row_parser_v3.dart`
**Lines:** 200-203

**WHY (H3 FIX):** After R1.2 removes alias remapping, `normalize()` becomes cleanup-only (uppercase + trim). The current `normalize()` had a `startsWith('LS')` fallback that caught OCR-corrupted LS variants like `LSUIVI` and mapped them to `LS`. Without that fallback, `LSUIVI` passes through normalize() as-is. Since `LSUIVI` is not in `knownUnits`, the check at line 202 triggers a spurious "Unknown unit: LSUIVI" warning.

The fix: add `!UnitRegistry.isLumpSum(unit)` to the unknown unit condition so OCR-corrupted LS variants don't trigger false warnings. The `isLumpSum()` helper (added in Sub-phase 1.1) catches these via its `upper.startsWith('LS') && upper.length > 2` branch.

**Current code (lines 200-203):**
```dart
      if (unit.isEmpty) {
        itemWarnings.add('Missing unit');
      } else if (!UnitRegistry.knownUnits.contains(unit)) {
        itemWarnings.add('Unknown unit: $unit');
      }
```

**Replace with:**
```dart
      if (unit.isEmpty) {
        itemWarnings.add('Missing unit');
      } else if (!UnitRegistry.knownUnits.contains(unit) &&
          !UnitRegistry.isLumpSum(unit)) {
        itemWarnings.add('Unknown unit: $unit');
      }
```

**Context:** `unit` is already uppercased at this point (line 179: `UnitRegistry.normalize(...)` returns uppercased text). `knownUnits` contains the standard forms (`LS`, `LSUM`, etc.) but NOT every possible OCR corruption. `isLumpSum()` catches the corrupted variants via its prefix check.

#### 1.3b: row_parser_v3.dart line 247

**File:** `lib/features/pdf/services/extraction/stages/row_parser_v3.dart`
**Line:** 247

**Current code:**
```dart
          quantity: quantity ?? (unit == 'LS' ? 1.0 : null),
```

**Replace with:**
```dart
          quantity: quantity ?? (UnitRegistry.isLumpSum(unit) ? 1.0 : null),
```

**WHY:** Lump sum items default to quantity=1.0 when no quantity is parsed. Must recognize both LS and LSUM.

#### 1.3c: post_process_utils.dart line 305

**File:** `lib/features/pdf/services/extraction/shared/post_process_utils.dart`
**Line:** 305

**Current code:**
```dart
    if (normalizedUnit == 'LS') {
```

**Replace with:**
```dart
    if (UnitRegistry.isLumpSum(normalizedUnit)) {
```

**WHY:** `isValidQuantity()` allows zero/null quantity for lump sum units. Must recognize LSUM.

**ALSO:** Add import at top of file if not already present:
```dart
import 'unit_registry.dart';
```

**Verify import:** Check if `unit_registry.dart` is already imported in `post_process_utils.dart`. The `_normalizeUnitInternal` method at line 284 calls `UnitRegistry.normalize()`, so the import should already exist. If not, add it.

#### 1.3d: consistency_checker.dart line 72

**File:** `lib/features/pdf/services/extraction/stages/consistency_checker.dart`
**Line:** 72

**Current code:**
```dart
    if (current.unit?.toUpperCase() == 'LS') {
```

**Replace with:**
```dart
    if (current.unit != null && UnitRegistry.isLumpSum(current.unit!)) {
```

**WHY:** The LS-specific inference branch sets quantity=1 and unitPrice=bidAmount for lump sum items. Must recognize LSUM.

**ALSO:** Add import at top of file:
```dart
import '../shared/unit_registry.dart';
```

#### 1.3e: post_processor_v2.dart line 724

**File:** `lib/features/pdf/services/extraction/stages/post_processor_v2.dart`
**Line:** 724

**Current code:**
```dart
      final isLumpSum = item.unit?.toUpperCase() == 'LS';
```

**Replace with:**
```dart
      final isLumpSum = item.unit != null && UnitRegistry.isLumpSum(item.unit!);
```

**WHY:** Quality scoring gives lump sum items partial credit for large quantities. Must recognize LSUM.

**ALSO:** Add import at top of file if not already present:
```dart
import '../shared/unit_registry.dart';
```

**Verification for all 1.3 changes:**
```bash
pwsh -Command "flutter test"
```
Expected: All tests pass. Unit values in fixtures will now retain long forms.

---

### Sub-phase 1.4: Unit tests for normalize() and isLumpSum()

**Agent:** `qa-testing-agent`
**File:** `test/features/pdf/extraction/shared/unit_registry_test.dart` (NEW FILE)

**WHY:** No tests existed for UnitRegistry. These tests verify the new cleanup-only normalize() and the isLumpSum() helper.

**Create file with content:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/pdf/services/extraction/shared/unit_registry.dart';

void main() {
  group('UnitRegistry.normalize', () {
    test('returns empty string for empty input', () {
      expect(UnitRegistry.normalize(''), '');
    });

    test('uppercases input', () {
      expect(UnitRegistry.normalize('ft'), 'FT');
      expect(UnitRegistry.normalize('syd'), 'SYD');
      expect(UnitRegistry.normalize('lsum'), 'LSUM');
    });

    test('strips accented E characters', () {
      expect(UnitRegistry.normalize('ÉA'), 'EA');
      expect(UnitRegistry.normalize('ÈACH'), 'EACH');
    });

    test('preserves long unit forms (no alias remapping)', () {
      expect(UnitRegistry.normalize('LSUM'), 'LSUM');
      expect(UnitRegistry.normalize('SYD'), 'SYD');
      expect(UnitRegistry.normalize('CYD'), 'CYD');
      expect(UnitRegistry.normalize('SFT'), 'SFT');
      expect(UnitRegistry.normalize('HOUR'), 'HOUR');
    });

    test('preserves short unit forms', () {
      expect(UnitRegistry.normalize('LS'), 'LS');
      expect(UnitRegistry.normalize('SY'), 'SY');
      expect(UnitRegistry.normalize('CY'), 'CY');
      expect(UnitRegistry.normalize('SF'), 'SF');
      expect(UnitRegistry.normalize('HR'), 'HR');
    });

    test('trims whitespace', () {
      expect(UnitRegistry.normalize('  FT  '), 'FT');
    });
  });

  group('UnitRegistry.isLumpSum', () {
    test('recognizes LS', () {
      expect(UnitRegistry.isLumpSum('LS'), isTrue);
      expect(UnitRegistry.isLumpSum('ls'), isTrue);
    });

    test('recognizes LSUM', () {
      expect(UnitRegistry.isLumpSum('LSUM'), isTrue);
      expect(UnitRegistry.isLumpSum('lsum'), isTrue);
    });

    test('recognizes OCR-corrupted LS variants', () {
      expect(UnitRegistry.isLumpSum('LSUIVI'), isTrue);
      expect(UnitRegistry.isLumpSum('LSUMI'), isTrue);
    });

    test('rejects non-lump-sum units', () {
      expect(UnitRegistry.isLumpSum('FT'), isFalse);
      expect(UnitRegistry.isLumpSum('EA'), isFalse);
      expect(UnitRegistry.isLumpSum('SY'), isFalse);
      expect(UnitRegistry.isLumpSum(''), isFalse);
    });
  });

  group('UnitRegistry.knownUnits', () {
    test('contains both long and short forms', () {
      expect(UnitRegistry.knownUnits, contains('LS'));
      expect(UnitRegistry.knownUnits, contains('LSUM'));
      expect(UnitRegistry.knownUnits, contains('SY'));
      expect(UnitRegistry.knownUnits, contains('SYD'));
      expect(UnitRegistry.knownUnits, contains('CY'));
      expect(UnitRegistry.knownUnits, contains('CYD'));
      expect(UnitRegistry.knownUnits, contains('SF'));
      expect(UnitRegistry.knownUnits, contains('SFT'));
      expect(UnitRegistry.knownUnits, contains('HR'));
      expect(UnitRegistry.knownUnits, contains('HOUR'));
    });
  });
}
```

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/shared/unit_registry_test.dart"
```
Expected: All tests pass.

---

### Sub-phase 1.5: Verify Phase 1

**Agent:** `qa-testing-agent`

```bash
pwsh -Command "flutter test"
```

Expected: All tests pass. Golden test baselines may need updating in Phase 6 due to unit changes (LS->LSUM in fixture output), but existing tests should still pass because the golden test uses ranges/closeTo matchers.

---

## Phase 2: R2 — Row Classifier Fix (2 MISS + 1 BOGUS)

### Sub-phase 2.1: Fix _isMinorTextContent

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart`
**Lines:** 320-343 (the `_isMinorTextContent` method)

**WHY:** Currently, `_isMinorTextContent` checks if text in the item-number column matches a numeric pattern. "Boy" (OCR-corrupted "95") doesn't match, so the method returns TRUE (minor text), allowing the row to be classified as priceContinuation. The fix: ANY text in the item-number column is a structural signal that the row is NOT minor text content, regardless of whether it matches a number pattern. A priceContinuation row should never have content in the item-number column.

**Replace the entire `_isMinorTextContent` method (lines 320-343) with:**

```dart
  bool _isMinorTextContent(List<OcrElement> textElements, _ZoneContext zones) {
    if (textElements.isEmpty) {
      return true;
    }

    final itemNumberColumn = zones.itemNumberColumn;
    if (itemNumberColumn != null) {
      // ANY text in the item-number column is a structural signal — the row
      // likely represents a data row, not a price/desc continuation.
      // Previously this only checked for numeric-pattern matches, which
      // missed OCR-corrupted item numbers like "Boy" (should be "95").
      final hasItemColumnText = textElements.any(
        (element) =>
            element.boundingBox.left >= itemNumberColumn.startX &&
            element.boundingBox.right <= itemNumberColumn.endX &&
            element.text.trim().isNotEmpty,
      );
      if (hasItemColumnText) {
        return false;
      }
    }

    final totalChars = textElements.fold<int>(
      0,
      (sum, element) => sum + element.text.trim().length,
    );
    return totalChars <= kMinorTextCharThreshold;
  }
```

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/stages/row_classifier_v3_test.dart"
```
Expected: Existing tests pass. The row with "Boy" in the item-number column will now NOT fall through to `_isMinorTextContent` -> `priceContinuation`.

---

<!-- REVISED: C1 fix — _rescueBoilerplateRows undoes Sub-phase 2.1 -->
### Sub-phase 2.1a: Guard `_rescueBoilerplateRows` against rows with item-column text

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart`
**Lines:** 345-402 (the `_rescueBoilerplateRows` method)

**WHY:** After Sub-phase 2.1, the `_isMinorTextContent` fix causes row 214 ("Boy" + prices) to fall through to `boilerplate` (line 317). However, `_rescueBoilerplateRows` runs AFTER initial classification (called at ~line 103) and rescues boilerplate rows with price content back to `priceContinuation`. The rescue function at line 375-379 only skips rows where the item-column text matches `_itemNumberPattern` (numeric pattern). "Boy" is non-numeric, so the rescue proceeds, and line 401 changes the row back to `priceContinuation` — completely undoing the Sub-phase 2.1 fix.

The fix: add a guard that checks for ANY text in the item-number column (not just numeric text). If item-column text exists, the row is structurally a data row, not a price continuation, and must NOT be rescued.

**Current code (lines 372-379):**
```dart
      final itemElements = zones.itemNumberColumn == null
          ? const <OcrElement>[]
          : _zoneElements(elementsByColumn, [zones.itemNumberColumn!]);
      if (itemElements.any(
        (element) => _itemNumberPattern.hasMatch(element.text.trim()),
      )) {
        continue;
      }
```

**Replace with:**
```dart
      final itemElements = zones.itemNumberColumn == null
          ? const <OcrElement>[]
          : _zoneElements(elementsByColumn, [zones.itemNumberColumn!]);
      // C1 fix: Check for ANY text in the item-number column, not just
      // numeric patterns. A boilerplate row with item-column text is likely
      // a data row with OCR-corrupted item number (e.g., "Boy" instead of "95"),
      // not a price continuation. Rescuing it to priceContinuation would cause
      // the downstream item to absorb this row's prices incorrectly.
      if (itemElements.any(
        (element) => element.text.trim().isNotEmpty,
      )) {
        continue;
      }
```

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/stages/row_classifier_v3_test.dart"
```
Expected: Row 214 ("Boy" + prices) is classified as `boilerplate` and stays `boilerplate` after rescue pass. It is NOT rescued to `priceContinuation`.

---

<!-- REVISED: C2 fix — R2c missing from plan, item 95 not recovered -->
### Sub-phase 2.1b: Add R2c rescue pass — classify data-like boilerplate rows as `data`

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart`
**Lines:** After `_rescueBoilerplateRows` (after line 402), add a new method AND call it from the `classify` method.

**WHY:** After Sub-phase 2.1 and 2.1a, row 214 ("Boy" + prices) correctly stays as `boilerplate`. But the spec requires R2c: "if a row has item-number-column content + price columns, treat as data with reduced confidence." Without this, item 95 ($26,656) is LOST — there is no path for row 214 to become a data row that produces a parsed item.

The best insertion point is a new rescue pass that runs AFTER `_rescueBoilerplateRows`. This pass targets boilerplate rows that have:
1. Text in the item-number column (even non-numeric, like "Boy")
2. Elements in price columns (unitPrice or bidAmount)
3. NOT already classified as data/continuation

These rows are reclassified as `data` with reduced confidence (0.65) to signal downstream stages that the item number needs special handling.

**Step 1: Add new method after `_rescueBoilerplateRows` (after line 402):**

```dart
  /// R2c: Rescue boilerplate rows that have both item-column text AND price
  /// content. These are likely data rows with OCR-corrupted item numbers
  /// (e.g., "Boy" instead of "95"). Classified as data with reduced confidence.
  void _rescueDataLikeBoilerplateRows({
    required List<ClassifiedRow> rows,
    required ColumnMap columnMap,
  }) {
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.type != RowType.boilerplate || row.elements.isEmpty) {
        continue;
      }

      final pageColumns = columnMap.columnsForPage(row.pageIndex);
      final zones = _computeZones(pageColumns);
      if (zones.priceColumns.isEmpty || zones.itemNumberColumn == null) {
        continue;
      }

      final elementsByColumn = _mapElementsToColumns(row.elements, pageColumns);

      // Check 1: Row must have text in the item-number column.
      final itemElements =
          _zoneElements(elementsByColumn, [zones.itemNumberColumn!]);
      final hasItemColumnText =
          itemElements.any((element) => element.text.trim().isNotEmpty);
      if (!hasItemColumnText) {
        continue;
      }

      // Check 2: Row must have price-like content in price columns.
      final priceElements = _zoneElements(elementsByColumn, zones.priceColumns);
      if (priceElements.isEmpty || !_hasPriceText(priceElements)) {
        continue;
      }

      // This row has both item-column text and prices — it's a data row
      // with an OCR-corrupted item number.
      rows[i] = row.copyWith(type: RowType.data, confidence: 0.65);
    }
  }
```

**Step 2: Call the new method in `classify()`.** Find where `_rescueBoilerplateRows` is called (around line 103-107). After the existing rescue call, add:

**Current code (around lines 103-107):**
```dart
    // Rescue validation pass: recover boilerplate rows that actually contain
    // price content in header-derived price columns.
    _rescueBoilerplateRows(
      rows: rows,
      columnMap: columnMap,
      medianHeight: medianHeight,
    );
```

**Replace with:**
```dart
    // Rescue validation pass: recover boilerplate rows that actually contain
    // price content in header-derived price columns.
    _rescueBoilerplateRows(
      rows: rows,
      columnMap: columnMap,
      medianHeight: medianHeight,
    );

    // R2c rescue pass: promote boilerplate rows with item-column text + prices
    // to data. These are OCR-corrupted data rows (e.g., "Boy" instead of "95").
    _rescueDataLikeBoilerplateRows(
      rows: rows,
      columnMap: columnMap,
    );
```

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/stages/row_classifier_v3_test.dart"
```
Expected: Row 214 ("Boy" + prices) is now classified as `data` with confidence 0.65. It will produce a parsed item for item 95 in downstream stages.

---

<!-- REVISED: H1 fix — merger grid-line guard mixes pages -->
### Sub-phase 2.2: Add grid line boundary guard to RowMerger (per-page)

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/stages/row_merger.dart`

**WHY:** Defense-in-depth. Even if the classifier correctly identifies a row, the merger should refuse to merge continuation rows that cross a horizontal grid line boundary. Grid lines physically separate items on the PDF page.

**H1 FIX:** The original plan used a flat `List<double>` for grid lines, which mixes Y positions from all pages. Since grid line Y positions are normalized per-page (0.0-1.0), a line at Y=0.30 on page 2 is indistinguishable from Y=0.30 on page 1, causing false merge-blocking on multi-page PDFs. The fix uses `Map<int, List<double>>` keyed by page index and filters by the base row's `pageIndex` in `_crossesGridLine`. If the base and continuation rows are on different pages, the merge is always blocked (cross-page merges are never valid).

**Replace the entire file content with:**

```dart
import 'dart:math';

import '../models/models.dart';
import 'stage_names.dart';

/// Stage 4A.5: Merge physical classified rows into logical item rows.
class RowMerger {
  (MergedRows, StageReport) merge({
    required ClassifiedRows classifiedRows,
    required ColumnMap columnMap,
    Map<int, List<double>> horizontalGridLines = const {},
  }) {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];
    final mergedRows = <MergedRow>[];

    int unattachedContinuations = 0;
    int attachedContinuations = 0;
    int gridLineBlocked = 0;
    int i = 0;

    while (i < classifiedRows.rows.length) {
      final row = classifiedRows.rows[i];

      switch (row.type) {
        case RowType.data:
          final priceContinuations = <ClassifiedRow>[];
          final descContinuations = <ClassifiedRow>[];
          int j = i + 1;

          while (j < classifiedRows.rows.length) {
            final next = classifiedRows.rows[j];
            if (next.type == RowType.priceContinuation ||
                next.type == RowType.descContinuation) {
              // Guard: refuse to merge if a grid line separates the base row
              // from this continuation row.
              if (_crossesGridLine(row, next, horizontalGridLines)) {
                gridLineBlocked++;
                warnings.add(
                  'Grid line guard: blocked ${next.type.name} merge at '
                  'page ${next.pageIndex}, row ${next.rowIndex}',
                );
                break;
              }

              if (next.type == RowType.priceContinuation) {
                priceContinuations.add(next);
              } else {
                descContinuations.add(next);
              }
              j++;
              continue;
            }
            break;
          }

          mergedRows.add(
            MergedRow(
              base: row,
              priceContinuations: priceContinuations,
              descContinuations: descContinuations,
            ),
          );
          i = j;
          break;
        case RowType.header:
        case RowType.sectionHeader:
        case RowType.total:
          mergedRows.add(MergedRow(base: row, type: row.type));
          i++;
          break;
        case RowType.priceContinuation:
        case RowType.descContinuation:
          if (mergedRows.isNotEmpty && mergedRows.last.type == RowType.data) {
            // Guard: refuse to merge if a grid line separates
            if (_crossesGridLine(
                mergedRows.last.base, row, horizontalGridLines)) {
              gridLineBlocked++;
              warnings.add(
                'Grid line guard: blocked orphan ${row.type.name} merge at '
                'page ${row.pageIndex}, row ${row.rowIndex}',
              );
              mergedRows.add(
                MergedRow(
                  base: row.copyWith(
                    type: RowType.boilerplate,
                    confidence: min(row.confidence, 0.4),
                  ),
                  type: RowType.boilerplate,
                ),
              );
            } else {
              attachedContinuations++;
              final last = mergedRows.removeLast();
              if (row.type == RowType.priceContinuation) {
                mergedRows.add(
                  last.copyWith(
                    priceContinuations: [...last.priceContinuations, row],
                  ),
                );
              } else {
                mergedRows.add(
                  last.copyWith(
                    descContinuations: [...last.descContinuations, row],
                  ),
                );
              }
            }
          } else {
            unattachedContinuations++;
            warnings.add(
              'Orphan ${row.type.name} at page ${row.pageIndex}, '
              'row ${row.rowIndex} had no preceding data row',
            );
            mergedRows.add(
              MergedRow(
                base: row.copyWith(
                  type: RowType.boilerplate,
                  confidence: min(row.confidence, 0.4),
                ),
                type: RowType.boilerplate,
              ),
            );
          }
          i++;
          break;
        case RowType.blank:
        case RowType.boilerplate:
          i++;
          break;
      }
    }

    final dataRowsWithPrice = mergedRows
        .where(
          (row) =>
              row.type == RowType.data && row.priceContinuations.isNotEmpty,
        )
        .length;
    final dataRowsWithDesc = mergedRows
        .where(
          (row) => row.type == RowType.data && row.descContinuations.isNotEmpty,
        )
        .length;

    final merged = MergedRows(
      documentId: classifiedRows.documentId,
      rows: mergedRows,
      totalPhysicalRows: classifiedRows.rows.length,
      totalMergedRows: mergedRows.length,
      dataRowsWithPrice: dataRowsWithPrice,
      dataRowsWithDesc: dataRowsWithDesc,
      orphanContinuations: unattachedContinuations,
      mergedAt: DateTime.now(),
    );

    final inputCount = classifiedRows.rows.length;
    final outputCount = mergedRows.length;
    final excludedCount = max(0, inputCount - outputCount);
    final stageConfidence = inputCount == 0
        ? 1.0
        : (1.0 - (unattachedContinuations / inputCount)).clamp(0.0, 1.0);

    stopwatch.stop();
    final report = StageReport(
      stageName: StageNames.rowMerging,
      elapsed: stopwatch.elapsed,
      stageConfidence: stageConfidence,
      inputCount: inputCount,
      outputCount: outputCount,
      excludedCount: excludedCount,
      warnings: warnings,
      metrics: {
        'column_count': columnMap.columns.length,
        'total_physical_rows': inputCount,
        'total_merged_rows': outputCount,
        'data_rows_with_price': dataRowsWithPrice,
        'data_rows_with_desc': dataRowsWithDesc,
        'attached_continuations': attachedContinuations,
        'orphan_continuations': unattachedContinuations,
        'grid_line_blocked': gridLineBlocked,
      },
      completedAt: DateTime.now(),
    );

    return (merged, report);
  }

  /// Returns true if a horizontal grid line exists between [base] and [cont],
  /// OR if the two rows are on different pages (cross-page merges are invalid).
  ///
  /// Uses the Y-center of each row's bounding box. A grid line is "between"
  /// if its normalized Y position falls strictly between the two centers.
  /// Grid lines are looked up by page index to avoid cross-page contamination.
  bool _crossesGridLine(
    ClassifiedRow base,
    ClassifiedRow cont,
    Map<int, List<double>> horizontalGridLines,
  ) {
    // H1 fix: rows on different pages must never merge.
    if (base.pageIndex != cont.pageIndex) return true;

    if (horizontalGridLines.isEmpty) return false;
    if (base.elements.isEmpty || cont.elements.isEmpty) return false;

    // H1 fix: only use grid lines for the base row's page.
    final pageLines = horizontalGridLines[base.pageIndex];
    if (pageLines == null || pageLines.isEmpty) return false;

    // Compute Y-center of each row from its elements' bounding boxes.
    final baseMinY = base.elements
        .map((e) => e.boundingBox.top)
        .reduce(min);
    final baseMaxY = base.elements
        .map((e) => e.boundingBox.bottom)
        .reduce(max);
    final baseCenter = (baseMinY + baseMaxY) / 2;

    final contMinY = cont.elements
        .map((e) => e.boundingBox.top)
        .reduce(min);
    final contMaxY = cont.elements
        .map((e) => e.boundingBox.bottom)
        .reduce(max);
    final contCenter = (contMinY + contMaxY) / 2;

    final yTop = min(baseCenter, contCenter);
    final yBottom = max(baseCenter, contCenter);

    return pageLines.any((line) => line > yTop && line < yBottom);
  }
}
```

**Verification:**
```bash
pwsh -Command "flutter test"
```

---

<!-- REVISED: H1 fix — pipeline wiring uses per-page Map -->
### Sub-phase 2.3: Pipeline wiring — pass grid lines to merger (per-page)

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`
**Lines:** 698-703 (the row merger call)

**WHY:** The merger now accepts horizontal grid line positions as a per-page `Map<int, List<double>>` to enforce the grid line boundary guard. The pipeline must build this map from the `GridLines` object.

**H1 FIX:** The original plan flattened all pages' grid lines into a single `List<double>`, which loses page-index information. Since Y positions are normalized per-page (0.0-1.0), a line at Y=0.30 on page 2 would incorrectly block merges at Y=0.30 on page 1. The fix builds a `Map<int, List<double>>` keyed by page index.

**Current code (lines 698-703):**
```dart
    // Stage 4A.5: Row Merging
    DebugLogger.pdf('[Pipeline] Stage 4A.5: Row Merging');
    final (mergedRows, rowMergeReport) = rowMerger.merge(
      classifiedRows: consolidatedFinal,
      columnMap: columnMap,
    );
```

**Replace with:**
```dart
    // Stage 4A.5: Row Merging
    DebugLogger.pdf('[Pipeline] Stage 4A.5: Row Merging');
    // H1 fix: Build per-page horizontal grid line map for the merger's
    // grid-line guard. Keyed by page index to avoid cross-page contamination.
    final horizontalGridLinesByPage = <int, List<double>>{
      for (final entry in gridLines.pages.entries)
        if (entry.value.hasGrid && entry.value.horizontalLines.isNotEmpty)
          entry.key: entry.value.horizontalLines,
    };
    final (mergedRows, rowMergeReport) = rowMerger.merge(
      classifiedRows: consolidatedFinal,
      columnMap: columnMap,
      horizontalGridLines: horizontalGridLinesByPage,
    );
```

**NOTE:** The variable `gridLines` is already in scope at this point in the pipeline (declared at line 494). The `GridLines` model has `pages` as `Map<int, GridLineResult>`, and each `GridLineResult` has `horizontalLines: List<double>` (normalized Y positions) and `hasGrid: bool`.

**Verification:**
```bash
pwsh -Command "flutter test"
```

---

### Sub-phase 2.4: Unit tests for R2

**Agent:** `qa-testing-agent`

#### 2.4a: Add test to row_classifier_v3_test.dart

**File:** `test/features/pdf/extraction/stages/row_classifier_v3_test.dart`

**WHY:** Verify that non-numeric text in the item-number column causes `_isMinorTextContent` to return false (preventing priceContinuation classification).

**Add the following test inside the existing `main()` group.** The implementing agent should find the appropriate location within the existing test structure. If the test file uses a specific helper for creating OcrElements and zones, adapt accordingly. The key assertion is:

```dart
  // Add within appropriate group in existing test file
  test('non-numeric item column text prevents priceContinuation', () {
    // A row with "Boy" in item-number column should NOT be classified
    // as priceContinuation, even though "Boy" doesn't match numeric pattern.
    // This verifies the fix for items 94/95 where OCR read "95" as "Boy".
    //
    // The implementing agent should construct the appropriate test fixture
    // with an OcrElement having text="Boy" positioned within the item-number
    // column bounds, plus price elements. The expected classification should
    // NOT be priceContinuation.
  });
```

**NOTE TO IMPLEMENTING AGENT:** Read the existing `row_classifier_v3_test.dart` file fully to understand its helper functions and test patterns. Create a concrete test that constructs a row with elements in the item-number column containing non-numeric text ("Boy") plus price columns, and verify it does NOT classify as `priceContinuation`.

#### 2.4b: Unit test for RowMerger grid line guard

**File:** `test/features/pdf/extraction/stages/row_merger_test.dart` (NEW FILE)

**WHY:** Verify that the merger refuses to merge continuation rows across grid line boundaries.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/pdf/services/extraction/models/models.dart';
import 'package:construction_inspector/features/pdf/services/extraction/stages/stages.dart';

void main() {
  group('RowMerger', () {
    late RowMerger merger;

    setUp(() {
      merger = RowMerger();
    });

    test('merges continuation rows when no grid lines present', () {
      final rows = ClassifiedRows(
        documentId: 'test',
        rows: [
          _makeRow(0, 0, RowType.data, yCenter: 0.10),
          _makeRow(0, 1, RowType.priceContinuation, yCenter: 0.12),
        ],
        stats: _makeStats(2),
        classifiedAt: DateTime.utc(2026),
      );
      final columnMap = _makeColumnMap();

      final (merged, report) = merger.merge(
        classifiedRows: rows,
        columnMap: columnMap,
      );

      expect(merged.rows.length, 1);
      expect(merged.rows[0].priceContinuations.length, 1);
      expect(report.metrics['grid_line_blocked'], 0);
    });

    // REVISED: H1 fix — horizontalGridLines is now Map<int, List<double>>
    test('blocks merge when grid line separates base and continuation', () {
      final rows = ClassifiedRows(
        documentId: 'test',
        rows: [
          _makeRow(0, 0, RowType.data, yCenter: 0.10),
          _makeRow(0, 1, RowType.priceContinuation, yCenter: 0.20),
        ],
        stats: _makeStats(2),
        classifiedAt: DateTime.utc(2026),
      );
      final columnMap = _makeColumnMap();

      final (merged, report) = merger.merge(
        classifiedRows: rows,
        columnMap: columnMap,
        horizontalGridLines: {0: [0.15]}, // Grid line between rows on page 0
      );

      // Continuation should be blocked — appears as separate row
      expect(merged.rows.length, greaterThan(1));
      expect(report.metrics['grid_line_blocked'], 1);
    });

    test('allows merge when grid line is NOT between rows', () {
      final rows = ClassifiedRows(
        documentId: 'test',
        rows: [
          _makeRow(0, 0, RowType.data, yCenter: 0.10),
          _makeRow(0, 1, RowType.priceContinuation, yCenter: 0.12),
        ],
        stats: _makeStats(2),
        classifiedAt: DateTime.utc(2026),
      );
      final columnMap = _makeColumnMap();

      final (merged, report) = merger.merge(
        classifiedRows: rows,
        columnMap: columnMap,
        horizontalGridLines: {0: [0.05]}, // Grid line ABOVE both rows on page 0
      );

      expect(merged.rows.length, 1);
      expect(merged.rows[0].priceContinuations.length, 1);
      expect(report.metrics['grid_line_blocked'], 0);
    });

    // H1 fix: Grid line on different page should NOT block merge on page 0
    test('ignores grid lines from other pages', () {
      final rows = ClassifiedRows(
        documentId: 'test',
        rows: [
          _makeRow(0, 0, RowType.data, yCenter: 0.10),
          _makeRow(0, 1, RowType.priceContinuation, yCenter: 0.20),
        ],
        stats: _makeStats(2),
        classifiedAt: DateTime.utc(2026),
      );
      final columnMap = _makeColumnMap();

      final (merged, report) = merger.merge(
        classifiedRows: rows,
        columnMap: columnMap,
        horizontalGridLines: {1: [0.15]}, // Grid line on PAGE 1, not page 0
      );

      // Should merge normally — grid line is on a different page
      expect(merged.rows.length, 1);
      expect(merged.rows[0].priceContinuations.length, 1);
      expect(report.metrics['grid_line_blocked'], 0);
    });

    // H1 fix: Cross-page merges always blocked regardless of grid lines
    test('blocks cross-page merges', () {
      final rows = ClassifiedRows(
        documentId: 'test',
        rows: [
          _makeRow(0, 0, RowType.data, yCenter: 0.90),
          _makeRow(1, 1, RowType.priceContinuation, yCenter: 0.05),
        ],
        stats: _makeStats(2),
        classifiedAt: DateTime.utc(2026),
      );
      final columnMap = _makeColumnMap();

      final (merged, report) = merger.merge(
        classifiedRows: rows,
        columnMap: columnMap,
        // No grid lines at all — still should block cross-page merge
      );

      expect(merged.rows.length, greaterThan(1));
      expect(report.metrics['grid_line_blocked'], greaterThanOrEqualTo(1));
    });
  });
}

ClassifiedRow _makeRow(
  int pageIndex,
  int rowIndex,
  RowType type, {
  required double yCenter,
}) {
  // Create a minimal OcrElement positioned at the given yCenter
  return ClassifiedRow(
    pageIndex: pageIndex,
    rowIndex: rowIndex,
    type: type,
    elements: [
      OcrElement(
        text: type == RowType.data ? '42' : '\$100.00',
        confidence: 0.9,
        boundingBox: BoundingBox(
          left: 0.1,
          top: yCenter - 0.005,
          right: 0.2,
          bottom: yCenter + 0.005,
        ),
      ),
    ],
    confidence: 0.9,
  );
}

ClassificationStats _makeStats(int totalRows) {
  return ClassificationStats(
    totalRows: totalRows,
    countsByType: {for (final t in RowType.values) t: 0},
    averageConfidence: 0.9,
    unknownCount: 0,
  );
}

ColumnMap _makeColumnMap() {
  return ColumnMap(
    documentId: 'test',
    columns: [
      ColumnDef(headerText: 'item', startX: 0.0, endX: 0.1),
      ColumnDef(headerText: 'description', startX: 0.1, endX: 0.5),
      ColumnDef(headerText: 'unit', startX: 0.5, endX: 0.6),
      ColumnDef(headerText: 'quantity', startX: 0.6, endX: 0.7),
      ColumnDef(headerText: 'unitPrice', startX: 0.7, endX: 0.85),
      ColumnDef(headerText: 'bidAmount', startX: 0.85, endX: 1.0),
    ],
    detectedAt: DateTime.utc(2026),
  );
}
```

**NOTE TO IMPLEMENTING AGENT:** The `OcrElement` and `BoundingBox` constructors above are approximations. Read the actual model files in `lib/features/pdf/services/extraction/models/` to verify constructor signatures and adapt as needed. The key test logic is correct — the helper functions may need minor adjustments to match actual model APIs.

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/stages/row_merger_test.dart"
```

---

### Sub-phase 2.5: Verify Phase 2

**Agent:** `qa-testing-agent`

```bash
pwsh -Command "flutter test"
```

Expected: All tests pass. Row 214 (with "Boy") no longer merges into item 94. Items 94 and 95 should now be separately parseable once fixtures are regenerated.

---

## Phase 3: R3 — Validation Gate (defense-in-depth)

<!-- REVISED: C3 fix — R3 uses non-existent excludedCount variable -->
### Sub-phase 3.1: Convert warning to skip in RowParserV3

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/stages/row_parser_v3.dart`
**Lines:** 196-198

**WHY:** After R2 fixes the classifier/merger, any item that reaches the parser with an invalid item number format (like "94 Boy") is genuinely bogus. Converting the warning to `continue` skips the bogus item instead of outputting it. We use `itemNumberLoose` (which allows alpha suffixes like "42A") to avoid being too strict.

**C3 FIX:** The original plan used `excludedCount++; continue;` which would crash at runtime because `excludedCount` does not exist as a local variable in `RowParserV3.parse()`. Additionally, just calling `continue` without adding to `skippedRows` would violate the stage report invariant (`outputCount + excludedCount == inputCount`), causing a `StateError`.

The correct pattern (seen at lines 103-112, 138-147, and 166-175 in row_parser_v3.dart) is to call `skippedRows.add(SkippedRow(...))` before `continue`. The `skippedRows` list is already declared at line 25 and is used to compute `excludedCount` in the stage report.

**Current code (lines 196-198):**
```dart
      if (!_itemNumberPattern.hasMatch(itemNumber)) {
        itemWarnings.add('Invalid item number format: $itemNumber');
      }
```

**Replace with:**
```dart
      if (!ExtractionPatterns.itemNumberLoose.hasMatch(itemNumber)) {
        skippedRows.add(
          SkippedRow(
            pageIndex: metadataRow.pageIndex,
            rowIndex: rowIndex,
            reason: 'invalid_item_number',
            rawCells: _extractRawElements(metadataRow),
            confidence: 0.3,
          ),
        );
        warnings.add(
          'Skipped item with invalid item number format: $itemNumber',
        );
        continue;
      }
```

**Context for implementing agent:** In `row_parser_v3.dart`, the loop runs `for (var rowIndex = 0; rowIndex < interpretedGrid.rows.length; rowIndex++)` (line 67). Inside the loop:
- `metadataRow` is declared at line 69 as `rowMetadata.rows[rowIndex]`
- `skippedRows` is the `List<SkippedRow>` declared at line 25
- `warnings` is the stage-level `List<String>` declared at line 23
- `_extractRawElements(metadataRow)` is a helper method at line 351 that extracts all OcrElements from the row
- `SkippedRow` requires: `pageIndex`, `rowIndex`, `reason`, `rawCells`, `confidence` (see model at `models/parsed_items.dart:166-179`)
- `ExtractionPatterns.itemNumberLoose` is `RegExp(r'^\d+(\.\d+)?[A-Za-z]?\.?$')` (at `shared/extraction_patterns.dart:24`) — matches "42", "1.01", "42A", "42."

**ALSO:** The `_itemNumberPattern` (which is `ExtractionPatterns.itemNumberStrict` - `^\d+(\.\d+)?$`) should remain at line 14. We are only changing the gate at line 196 to use the looser pattern and convert to a skip.

**Verification:**
```bash
pwsh -Command "flutter test"
```

---

### Sub-phase 3.2: Verify Phase 3

**Agent:** `qa-testing-agent`

```bash
pwsh -Command "flutter test"
```

Expected: All tests pass. Any garbled items that survive R2 (e.g., "94 Boy") will now be dropped at the parser gate.

---

## Phase 4: R4 — bidAmount Backsolve (1 item)

### Sub-phase 4.1: Add bidAmount correction branch

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/stages/consistency_checker.dart`
**Lines:** 128-134 (the `else` branch after unitPrice backsolve fails)

**WHY:** Item 96 has `qty=2410`, `unitPrice=73.50`, `bidAmount=177133` (OCR read `$177.133.00` with European periods, digit '5' misread as '3'). The unitPrice backsolve fails because `177133/2410 = 73.498` rounds to `73.50` but `2410*73.50 = 177135 != 177133`. The correct fix: when `qty * unitPrice` produces an exact integer and the relative error vs bidAmount is tiny (<0.5%), correct bidAmount. Gate on: rawBidAmount matches a European-periods-like pattern (periods as thousands separators).

**Current code (lines 128-134):**
```dart
            } else {
              warnings.add(
                'Math validation: calculated amount (\$${calculated.toStringAsFixed(2)}) '
                'does not match bid amount (\$${current.bidAmount!.toStringAsFixed(2)}) '
                'for item $itemId',
              );
            }
```

**Replace with:**
```dart
            } else {
              // R4: Try correcting bidAmount when unitPrice backsolve fails.
              // Gate: qty * unitPrice gives clean result AND relative error
              // is tiny AND rawBidAmount shows OCR corruption signs.
              // REVISED: H2 fix — use abs() on relativeError (security M2)
              final relativeError = (diff / current.bidAmount!).abs();
              final rawBid = current.rawBidAmount ?? '';
              // REVISED: H2 fix — reuse the existing european periods pattern
              // from _EuropeanPeriodsCurrencyRule in currency_rules.dart:125.
              // The existing pattern is: RegExp(r'^\$?\d{1,3}(\.\d{3})+\.\d{2}$')
              // which already handles "$177.133.00" and similar.
              // Import currency_rules.dart and reference the pattern via a
              // shared accessor (see Step 2 below).
              final hasOcrCorruption = _europeanPeriodsPattern.hasMatch(
                rawBid.trim(),
              );

              if (relativeError < 0.005 && hasOcrCorruption) {
                // The computed amount (qty * unitPrice) is more trustworthy
                // than the OCR'd bidAmount when corruption is detected.
                final before = {'bidAmount': current.bidAmount};
                current = current.copyWith(bidAmount: calculated);
                repairNotes.add(
                  RepairEntry(
                    itemId: itemId,
                    type: RepairType.mathValidation,
                    before: before,
                    after: {'bidAmount': calculated},
                    confidenceAdjustment: ConfidenceConstants.kAdjMathBacksolve,
                    reason:
                        'bidAmount correction: qty(${current.quantity}) × price(${current.unitPrice}) = '
                        'amount($calculated). Raw OCR "$rawBid" shows european period corruption. '
                        'Original bidAmount was ${before['bidAmount']}.',
                    appliedAt: now,
                  ),
                );
              } else {
                warnings.add(
                  'Math validation: calculated amount (\$${calculated.toStringAsFixed(2)}) '
                  'does not match bid amount (\$${current.bidAmount!.toStringAsFixed(2)}) '
                  'for item $itemId',
                );
              }
            }
```

<!-- REVISED: H2 fix — expose european periods pattern for reuse -->
**H2 prerequisite: Expose the european periods pattern for reuse.**

The pattern `RegExp(r'^\$?\d{1,3}(\.\d{3})+\.\d{2}$')` already exists in `_EuropeanPeriodsCurrencyRule._pattern` at `lib/features/pdf/services/extraction/rules/currency_rules.dart:125`. It is currently `static final` on a private class, so it cannot be imported directly.

**Option A (preferred): Add the pattern to `ExtractionPatterns`.**

**File:** `lib/features/pdf/services/extraction/shared/extraction_patterns.dart`
**Action:** Add the following static field inside the `ExtractionPatterns` class:

```dart
  /// European periods currency pattern: "$177.133.00" — periods used as
  /// thousands separators. Reused from _EuropeanPeriodsCurrencyRule in
  /// currency_rules.dart to avoid DRY violations.
  static final europeanPeriods = RegExp(r'^\$?\d{1,3}(\.\d{3})+\.\d{2}$');
```

Then in `consistency_checker.dart`, add a field to the class or a top-level constant:

```dart
static final RegExp _europeanPeriodsPattern = ExtractionPatterns.europeanPeriods;
```

And add the import at the top of `consistency_checker.dart`:
```dart
import '../shared/extraction_patterns.dart';
```

**Optionally**, also update `currency_rules.dart:125` to reference `ExtractionPatterns.europeanPeriods` instead of defining its own copy:
```dart
// In _EuropeanPeriodsCurrencyRule:
static final RegExp _pattern = ExtractionPatterns.europeanPeriods;
```

This ensures both the consistency checker and the currency rule use the exact same pattern.

**Verification:**
```bash
pwsh -Command "flutter test"
```

---

### Sub-phase 4.2: Unit tests for bidAmount correction

**Agent:** `qa-testing-agent`
**File:** `test/features/pdf/extraction/stages/consistency_checker_test.dart` (NEW FILE)

**WHY:** Verify the new bidAmount correction branch triggers correctly and is gated properly.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/pdf/services/extraction/models/models.dart';
import 'package:construction_inspector/features/pdf/services/extraction/stages/consistency_checker.dart';

void main() {
  group('ConsistencyChecker.applyConsistencyRules', () {
    final config = PipelineConfig(enableInference: true);

    test('corrects bidAmount when european period corruption detected', () {
      // Item 96 scenario: qty=2410, unitPrice=73.50, bidAmount=177133
      // rawBidAmount shows "$177.133.00" (european periods)
      // Correct bidAmount = 2410 * 73.50 = 177135
      final item = ParsedBidItem(
        itemNumber: '96',
        description: 'Test item',
        unit: 'EA',
        quantity: 2410.0,
        unitPrice: 73.50,
        bidAmount: 177133.0,
        confidence: 0.8,
        fieldsPresent: 6,
        rawBidAmount: '\$177.133.00',
      );

      final result = ConsistencyChecker.applyConsistencyRules(item, config);

      expect(result.item.bidAmount, 177135.0,
          reason: 'bidAmount should be corrected to qty * unitPrice');
      expect(result.repairNotes, isNotEmpty);
      expect(result.repairNotes.last.type, RepairType.mathValidation);
      expect(
        result.repairNotes.last.reason,
        contains('bidAmount correction'),
      );
    });

    test('does NOT correct bidAmount without european period pattern', () {
      // Same math discrepancy but rawBidAmount is clean — don't correct
      final item = ParsedBidItem(
        itemNumber: '96',
        description: 'Test item',
        unit: 'EA',
        quantity: 2410.0,
        unitPrice: 73.50,
        bidAmount: 177133.0,
        confidence: 0.8,
        fieldsPresent: 6,
        rawBidAmount: '\$177,133.00', // Normal comma format — no corruption
      );

      final result = ConsistencyChecker.applyConsistencyRules(item, config);

      expect(result.item.bidAmount, 177133.0,
          reason: 'bidAmount should NOT be corrected without corruption signal');
      expect(result.warnings, isNotEmpty);
    });

    test('does NOT correct bidAmount when relative error is too large', () {
      // Large discrepancy — should not auto-correct
      final item = ParsedBidItem(
        itemNumber: '99',
        description: 'Test item',
        unit: 'EA',
        quantity: 100.0,
        unitPrice: 50.0,
        bidAmount: 4000.0, // 5000 vs 4000 = 20% error
        confidence: 0.8,
        fieldsPresent: 6,
        rawBidAmount: '\$4.000.00',
      );

      final result = ConsistencyChecker.applyConsistencyRules(item, config);

      expect(result.item.bidAmount, 4000.0,
          reason: 'bidAmount should NOT be corrected when error is large');
    });

    test('LS unit inference still works after isLumpSum change', () {
      final item = ParsedBidItem(
        itemNumber: '1',
        description: 'Test lump sum',
        unit: 'LSUM',
        quantity: 0.0,
        unitPrice: null,
        bidAmount: 5000.0,
        confidence: 0.8,
        fieldsPresent: 5,
      );

      final result = ConsistencyChecker.applyConsistencyRules(item, config);

      expect(result.item.quantity, 1.0,
          reason: 'LSUM items should get quantity=1');
      expect(result.item.unitPrice, 5000.0,
          reason: 'LSUM items should get unitPrice=bidAmount');
    });
  });
}
```

**NOTE TO IMPLEMENTING AGENT:** The `PipelineConfig` constructor may require additional parameters. Read the `PipelineConfig` model to verify the constructor signature and provide any required fields. The `enableInference: true` parameter is critical — without it, the consistency checker skips all rules.

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/stages/consistency_checker_test.dart"
```

---

### Sub-phase 4.3: Verify Phase 4

**Agent:** `qa-testing-agent`

```bash
pwsh -Command "flutter test"
```

Expected: All tests pass. Item 96's bidAmount will be corrected from 177133 to 177135 in pipeline output.

---

## Phase 5: R5 — Position-Based Grid Line Removal

### Sub-phase 5.1: Read GridLineResult model and verify available data

**Agent:** `pdf-agent`

**Action:** Verify the GridLineResult model at `lib/features/pdf/services/extraction/models/grid_lines.dart`.

**Already verified during planning:** The model contains:
- `horizontalLines`: `List<double>` — normalized Y positions (0-1)
- `verticalLines`: `List<double>` — normalized X positions (0-1)
- `horizontalLineWidths`: `List<int>` — pixel widths (parallel to each horizontal line)
- `verticalLineWidths`: `List<int>` — pixel widths (parallel to each vertical line)
- `hasGrid`: `bool`

The width lists may be empty (default `const []`). The implementing agent must handle empty width lists by using a sensible default (e.g., 3px).

---

### Sub-phase 5.2: Rewrite mask-building in GridLineRemover

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/stages/grid_line_remover.dart`

**WHY:** The current morphological approach (adaptive threshold + morph open + dilate) re-detects grid lines from scratch, creating a damage zone of ~3-5px beyond each line that corrupts adjacent text. The GridLineDetector has already computed exact line positions and widths. By drawing masks directly from those positions, we eliminate overshoot entirely and reduce the inpaint radius.

**Replace the ENTIRE file content with:**

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:opencv_dart/opencv.dart' as cv;

import '../models/models.dart';
import 'image_preprocessor_v2.dart';
import 'stage_names.dart';

/// Default line width in pixels when GridLineResult doesn't provide widths.
const int _defaultLineWidthPx = 3;

/// Telea inpainting radius in pixels.
/// Reduced from 2.0 to 1.5 — position-based masks are more precise than
/// morphological detection, so a smaller inpaint radius suffices.
const double _inpaintRadius = 1.5;

/// Stage 2B-ii.6: Grid line removal using position-based masking + inpainting.
///
/// Instead of re-detecting grid lines via morphological operations (which
/// creates a damage zone around each line), this stage draws masks directly
/// from the GridLineDetector's already-computed line positions and widths.
class GridLineRemover {
  Future<(Map<int, PreprocessedPage>, StageReport)> remove({
    required Map<int, PreprocessedPage> preprocessedPages,
    required GridLines gridLines,
    void Function(String name, Uint8List pngBytes)? onDiagnosticImage,
  }) async {
    final startTime = DateTime.now();
    if (preprocessedPages.isEmpty) {
      final completedAt = DateTime.now();
      final report = StageReport(
        stageName: StageNames.gridLineRemoval,
        elapsed: completedAt.difference(startTime),
        stageConfidence: 1.0,
        inputCount: 0,
        outputCount: 0,
        excludedCount: 0,
        metrics: const {
          'pages_total': 0,
          'pages_processed': 0,
          'pages_passthrough': 0,
          'pages_failed': 0,
          'mask_pixels_total': 0,
          'mask_coverage_ratio_avg': 0.0,
        },
        completedAt: completedAt,
      );
      return (<int, PreprocessedPage>{}, report);
    }

    final warnings = <String>[];
    final cleanedPages = <int, PreprocessedPage>{};
    final perPageMetrics = <String, Map<String, dynamic>>{};
    final orderedEntries = preprocessedPages.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    var processedPages = 0;
    var passthroughPages = 0;
    var failedPages = 0;
    var totalMaskPixels = 0;
    var totalMaskCoverage = 0.0;

    for (final entry in orderedEntries) {
      final pageIndex = entry.key;
      final page = entry.value;
      final gridPage = gridLines.pages[pageIndex];
      final hasGrid = gridPage?.hasGrid == true;

      if (!hasGrid || gridPage == null) {
        cleanedPages[pageIndex] = page;
        passthroughPages++;
        perPageMetrics['$pageIndex'] = const {
          'has_grid': false,
          'processed': false,
          'mask_pixels': 0,
          'mask_coverage_ratio': 0.0,
          'inpaint_applied': false,
        };
        continue;
      }

      try {
        final processed = _removeGridLines(page.enhancedImageBytes, gridPage);
        cleanedPages[pageIndex] = PreprocessedPage(
          enhancedImageBytes: processed.cleanedBytes,
          enhancedSizePixels: Size(
            processed.width.toDouble(),
            processed.height.toDouble(),
          ),
          pageIndex: page.pageIndex,
          stats: page.stats,
          preprocessingApplied: page.preprocessingApplied,
        );

        processedPages++;
        totalMaskPixels += processed.maskPixels;
        totalMaskCoverage += processed.maskCoverage;
        perPageMetrics['$pageIndex'] = {
          'has_grid': true,
          'processed': true,
          'mask_pixels': processed.maskPixels,
          'mask_coverage_ratio': processed.maskCoverage,
          'horizontal_lines': gridPage.horizontalLines.length,
          'vertical_lines': gridPage.verticalLines.length,
          'inpaint_applied': true,
        };

        onDiagnosticImage?.call(
          'page_${pageIndex}_grid_line_mask',
          processed.maskBytes,
        );
        onDiagnosticImage?.call(
          'page_${pageIndex}_grid_line_removed',
          processed.cleanedBytes,
        );
      } catch (error) {
        cleanedPages[pageIndex] = page;
        failedPages++;
        warnings.add('Page ${pageIndex + 1}: grid line removal failed: $error');
        perPageMetrics['$pageIndex'] = const {
          'has_grid': true,
          'processed': false,
          'mask_pixels': 0,
          'mask_coverage_ratio': 0.0,
          'inpaint_applied': false,
        };
      }
    }

    final inputCount = preprocessedPages.length;
    final outputCount = cleanedPages.length;
    if (outputCount != inputCount) {
      throw StateError(
        'Grid line removal stage contract violated: input=$inputCount, output=$outputCount',
      );
    }

    final completedAt = DateTime.now();
    final report = StageReport(
      stageName: StageNames.gridLineRemoval,
      elapsed: completedAt.difference(startTime),
      stageConfidence: failedPages == 0
          ? 1.0
          : (inputCount - failedPages) / inputCount,
      inputCount: inputCount,
      outputCount: outputCount,
      excludedCount: 0,
      warnings: warnings,
      metrics: {
        'pages_total': inputCount,
        'pages_processed': processedPages,
        'pages_passthrough': passthroughPages,
        'pages_failed': failedPages,
        'mask_pixels_total': totalMaskPixels,
        'mask_coverage_ratio_avg': processedPages == 0
            ? 0.0
            : totalMaskCoverage / processedPages,
        'per_page': perPageMetrics,
      },
      completedAt: completedAt,
    );

    return (cleanedPages, report);
  }
}

class _GridRemovalResult {
  final Uint8List cleanedBytes;
  final Uint8List maskBytes;
  final int width;
  final int height;
  final int maskPixels;
  final double maskCoverage;

  const _GridRemovalResult({
    required this.cleanedBytes,
    required this.maskBytes,
    required this.width,
    required this.height,
    required this.maskPixels,
    required this.maskCoverage,
  });
}

/// Build a mask from known grid line positions and inpaint to remove them.
_GridRemovalResult _removeGridLines(
  Uint8List inputBytes,
  GridLineResult gridPage,
) {
  final sourceGray = cv.imdecode(inputBytes, cv.IMREAD_GRAYSCALE);
  cv.Mat? mask;
  cv.Mat? inpainted;

  try {
    if (sourceGray.isEmpty || sourceGray.rows <= 0 || sourceGray.cols <= 0) {
      throw StateError('Unable to decode image bytes into grayscale Mat');
    }

    final imgHeight = sourceGray.rows;
    final imgWidth = sourceGray.cols;

    // Create blank mask (all zeros = no masking)
    mask = cv.Mat.zeros(imgHeight, imgWidth, cv.MatType.CV_8UC1);

    // Draw horizontal lines
    for (var i = 0; i < gridPage.horizontalLines.length; i++) {
      final normalizedY = gridPage.horizontalLines[i];
      final lineWidth = i < gridPage.horizontalLineWidths.length
          ? gridPage.horizontalLineWidths[i]
          : _defaultLineWidthPx;

      final centerY = (normalizedY * imgHeight).round();
      final halfWidth = math.max(1, lineWidth ~/ 2);
      final y1 = math.max(0, centerY - halfWidth);
      final y2 = math.min(imgHeight - 1, centerY + halfWidth);

      // Draw filled rectangle spanning full image width
      cv.rectangle(
        mask,
        cv.Point(0, y1),
        cv.Point(imgWidth - 1, y2),
        cv.Scalar(255, 0, 0, 0),
        thickness: cv.FILLED,
      );
    }

    // Draw vertical lines
    for (var i = 0; i < gridPage.verticalLines.length; i++) {
      final normalizedX = gridPage.verticalLines[i];
      final lineWidth = i < gridPage.verticalLineWidths.length
          ? gridPage.verticalLineWidths[i]
          : _defaultLineWidthPx;

      final centerX = (normalizedX * imgWidth).round();
      final halfWidth = math.max(1, lineWidth ~/ 2);
      final x1 = math.max(0, centerX - halfWidth);
      final x2 = math.min(imgWidth - 1, centerX + halfWidth);

      // Draw filled rectangle spanning full image height
      cv.rectangle(
        mask,
        cv.Point(x1, 0),
        cv.Point(x2, imgHeight - 1),
        cv.Scalar(255, 0, 0, 0),
        thickness: cv.FILLED,
      );
    }

    // Inpaint using the position-based mask
    inpainted = cv.inpaint(
      sourceGray,
      mask,
      _inpaintRadius,
      cv.INPAINT_TELEA,
    );

    final (cleanedOk, cleanedBytes) = cv.imencode('.png', inpainted);
    final (maskOk, maskBytes) = cv.imencode('.png', mask);
    if (!cleanedOk || !maskOk) {
      throw StateError('Failed to encode OpenCV output as PNG');
    }

    final maskPixels = cv.countNonZero(mask);
    final maskCoverage = maskPixels / (imgHeight * imgWidth);

    return _GridRemovalResult(
      cleanedBytes: cleanedBytes,
      maskBytes: maskBytes,
      width: inpainted.cols,
      height: inpainted.rows,
      maskPixels: maskPixels,
      maskCoverage: maskCoverage.clamp(0.0, 1.0),
    );
  } finally {
    inpainted?.dispose();
    mask?.dispose();
    sourceGray.dispose();
  }
}
```

**Key changes from the original:**
1. **Removed:** `_adaptiveBlockSize`, `_adaptiveC`, `_kernelDivisor`, `_maskDilateIterations` constants
2. **Removed:** `adaptiveThreshold`, `morphologyEx`, `dilate`, `getStructuringElement` calls
3. **Added:** Position-based mask drawing using `cv.rectangle` with `FILLED` thickness
4. **Added:** `GridLineResult` parameter to `_removeGridLines` (was previously self-contained)
5. **Reduced:** inpaint radius from 2.0 to 1.5
6. **Simplified:** `_GridRemovalResult` (removed `horizontalKernelWidth`, `verticalKernelHeight` fields)
7. **Changed:** per-page metrics keys from `horizontal_kernel_width`/`vertical_kernel_height` to `horizontal_lines`/`vertical_lines` (counts)

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/stages/grid_line_remover_test.dart"
```

---

### Sub-phase 5.3: Update pipeline wiring (already done)

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`

**Action:** Verify no changes needed. The pipeline already passes the full `GridLines` object to `gridLineRemover.remove()` at line 508-511:
```dart
    final (cleanedPages, stage2Bii6Report) = await gridLineRemover.remove(
      preprocessedPages: preprocessedPages,
      gridLines: gridLines,
      onDiagnosticImage: onDiagnosticImage,
    );
```

The `remove()` method signature hasn't changed — it still receives `GridLines gridLines`. The internal change is that `_removeGridLines` now uses the `GridLineResult` from `gridLines.pages[pageIndex]` to build position-based masks. **No pipeline wiring changes needed for R5.**

---

### Sub-phase 5.4: Update grid_line_remover_test.dart

**Agent:** `qa-testing-agent`
**File:** `test/features/pdf/extraction/stages/grid_line_remover_test.dart`

**WHY:** The existing tests create synthetic images with grid lines but don't pass line widths in `GridLineResult`. The new position-based approach needs accurate line positions to create masks. Tests should now also pass `horizontalLineWidths` and `verticalLineWidths` to verify position-based masking.

**Replace the ENTIRE file content with:**

```dart
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:construction_inspector/features/pdf/services/extraction/models/models.dart';
import 'package:construction_inspector/features/pdf/services/extraction/stages/stages.dart';

void main() {
  group('GridLineRemover', () {
    late GridLineRemover remover;

    setUp(() {
      remover = GridLineRemover();
    });

    test('returns valid empty report when no pages provided', () async {
      final (pages, report) = await remover.remove(
        preprocessedPages: const {},
        gridLines: GridLines(pages: const {}, detectedAt: DateTime.utc(2026)),
      );

      expect(pages, isEmpty);
      expect(report.stageName, StageNames.gridLineRemoval);
      expect(report.inputCount, 0);
      expect(report.outputCount, 0);
      expect(report.metrics['pages_total'], 0);
      expect(report.metrics['pages_processed'], 0);
      expect(report.metrics['pages_failed'], 0);
    });

    test('passes through non-grid pages unchanged', () async {
      final pageBytes = _createGridImage(
        horizontalYs: const [0.20, 0.80],
        verticalXs: const [0.20, 0.80],
      );
      final page = _page(pageBytes, pageIndex: 0);

      final (cleaned, report) = await remover.remove(
        preprocessedPages: {0: page},
        gridLines: GridLines(
          pages: {
            0: const GridLineResult(
              pageIndex: 0,
              horizontalLines: [],
              verticalLines: [],
              hasGrid: false,
              confidence: 0.0,
            ),
          },
          detectedAt: DateTime.utc(2026, 2, 19),
        ),
      );

      expect(cleaned[0]!.enhancedImageBytes, pageBytes);
      expect(report.metrics['pages_passthrough'], 1);
      expect(report.metrics['pages_processed'], 0);
      expect(report.metrics['pages_failed'], 0);
    });

    test(
      'falls back to original bytes when grid-page processing fails',
      () async {
        final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4]);
        final page = _page(invalidBytes, pageIndex: 0);

        final (cleaned, report) = await remover.remove(
          preprocessedPages: {0: page},
          gridLines: GridLines(
            pages: {
              0: const GridLineResult(
                pageIndex: 0,
                horizontalLines: [0.2, 0.8],
                verticalLines: [0.2, 0.8],
                horizontalLineWidths: [3, 3],
                verticalLineWidths: [3, 3],
                hasGrid: true,
                confidence: 1.0,
              ),
            },
            detectedAt: DateTime.utc(2026, 2, 19),
          ),
        );

        expect(cleaned[0]!.enhancedImageBytes, invalidBytes);
        expect(report.metrics['pages_failed'], 1);
        expect(report.warnings, isNotEmpty);
      },
    );

    test('processes grid pages with position-based masking', () async {
      final sourceBytes = _createGridImage(
        horizontalYs: const [0.15, 0.30, 0.45, 0.60, 0.75],
        verticalXs: const [0.2, 0.5, 0.8],
      );
      final page = _page(sourceBytes, pageIndex: 0);
      final diagnostics = <String, Uint8List>{};

      final (cleaned, report) = await remover.remove(
        preprocessedPages: {0: page},
        gridLines: GridLines(
          pages: {
            0: const GridLineResult(
              pageIndex: 0,
              horizontalLines: [0.15, 0.30, 0.45, 0.60, 0.75],
              verticalLines: [0.2, 0.5, 0.8],
              horizontalLineWidths: [3, 3, 3, 3, 3],
              verticalLineWidths: [3, 3, 3],
              hasGrid: true,
              confidence: 1.0,
            ),
          },
          detectedAt: DateTime.utc(2026, 2, 19),
        ),
        onDiagnosticImage: (name, bytes) {
          diagnostics[name] = bytes;
        },
      );

      expect(cleaned[0], isNotNull);
      expect(cleaned[0]!.enhancedImageBytes, isNotEmpty);
      expect(report.metrics['pages_processed'], 1);
      expect(report.metrics['pages_failed'], 0);
      expect(report.metrics['mask_pixels_total'], greaterThan(0));
      expect(
        diagnostics.keys,
        containsAll(['page_0_grid_line_mask', 'page_0_grid_line_removed']),
      );
    });

    // WHY: Position-based masking should produce TIGHTER coverage than
    // morphological detection. 5h + 3v lines of 3px width on 800x1000:
    // H: 5 * 3 * 800 = 12,000px, V: 3 * 3 * 1000 = 9,000px
    // Total: ~21,000px out of 800,000 = ~2.6%. No dilation overshoot.
    test('mask coverage is tight for position-based masking', () async {
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
              horizontalLineWidths: [3, 3, 3, 3, 3],
              verticalLineWidths: [3, 3, 3],
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
      // Position-based masks: expected ~2.6%. No dilation. Allow up to 8%.
      expect(coverage, greaterThan(0.005),
          reason: 'Mask should detect grid lines (not be empty)');
      expect(coverage, lessThan(0.08),
          reason: 'Position-based mask should be tighter than morphological');
    });

    test('uses default line width when widths list is empty', () async {
      final sourceBytes = _createGridImage(
        horizontalYs: const [0.50],
        verticalXs: const [0.50],
      );
      final page = _page(sourceBytes, pageIndex: 0);

      final (cleaned, report) = await remover.remove(
        preprocessedPages: {0: page},
        gridLines: GridLines(
          pages: {
            0: const GridLineResult(
              pageIndex: 0,
              horizontalLines: [0.50],
              verticalLines: [0.50],
              // Empty width lists — should use default 3px
              horizontalLineWidths: [],
              verticalLineWidths: [],
              hasGrid: true,
              confidence: 1.0,
            ),
          },
          detectedAt: DateTime.utc(2026, 2, 19),
        ),
      );

      expect(cleaned[0], isNotNull);
      expect(report.metrics['pages_processed'], 1);
      expect(report.metrics['pages_failed'], 0);
    });
  });
}

PreprocessedPage _page(Uint8List bytes, {required int pageIndex}) {
  return PreprocessedPage(
    enhancedImageBytes: bytes,
    enhancedSizePixels: const Size(800, 1000),
    pageIndex: pageIndex,
    stats: const PreprocessingStats(
      skewAngle: 0.0,
      contrastBefore: 0.5,
      contrastAfter: 0.8,
      borderRemoved: false,
      fellBackToOriginal: false,
    ),
    preprocessingApplied: true,
  );
}

Uint8List _createGridImage({
  int width = 800,
  int height = 1000,
  List<double> horizontalYs = const [],
  List<double> verticalXs = const [],
  int lineThickness = 3,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));

  for (final y in horizontalYs) {
    final pixelY = (y * height).round();
    for (var dy = 0; dy < lineThickness; dy++) {
      final row = pixelY + dy;
      if (row < 0 || row >= height) {
        continue;
      }
      for (var x = 0; x < width; x++) {
        image.setPixel(x, row, img.ColorRgb8(0, 0, 0));
      }
    }
  }

  for (final x in verticalXs) {
    final pixelX = (x * width).round();
    for (var dx = 0; dx < lineThickness; dx++) {
      final col = pixelX + dx;
      if (col < 0 || col >= width) {
        continue;
      }
      for (var y = 0; y < height; y++) {
        image.setPixel(col, y, img.ColorRgb8(0, 0, 0));
      }
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}
```

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/stages/grid_line_remover_test.dart"
```

---

### Sub-phase 5.5: Verify Phase 5

**Agent:** `qa-testing-agent`

```bash
pwsh -Command "flutter test"
```

Expected: All tests pass. Grid line removal now uses position-based masking with no morphological overshoot.

---

## Phase 6: Fixture Regeneration & Golden Test Update

### Sub-phase 6.1: Regenerate all fixtures

**Agent:** `qa-testing-agent`

**WHY:** All five fixes (R1-R5) change pipeline output. Fixtures must be regenerated from the actual Springfield PDF to capture the new behavior.

**Action:** Run the rendering diagnostic integration test with `SPRINGFIELD_PDF` define to regenerate all stage fixtures.

```bash
pwsh -Command "flutter test integration_test/rendering_diagnostic_test.dart -d windows --dart-define=SPRINGFIELD_PDF='C:\path\to\springfield.pdf'" -Timeout 600000
```

**NOTE TO IMPLEMENTING AGENT:** Ask the user for the Springfield PDF path. The integration test writes stage output to fixture files. If the test doesn't automatically regenerate all fixture files, the implementing agent must identify the fixture generation mechanism and run it.

**Expected outcome:** All `test/features/pdf/extraction/fixtures/springfield_*.json` files are updated with new pipeline output.

---

### Sub-phase 6.2: Update golden test baselines

**Agent:** `qa-testing-agent`
**File:** `test/features/pdf/extraction/golden/springfield_golden_test.dart`

**WHY:** After R1-R5, the pipeline output has changed. The golden test baselines must be updated to reflect the new expected values.

**Action:** Update the following assertions in the golden test:

1. **Line 164** — Quality score: Change `closeTo(0.918, 0.02)` to `closeTo(0.99, 0.02)` (or whatever the new score is after fixture regeneration)
2. **Line 149** — Item count range: The range `inInclusiveRange(10, 131)` should still pass (131 items expected)
3. Any other hardcoded baseline values that reference the old pipeline output

**NOTE TO IMPLEMENTING AGENT:** After regenerating fixtures (6.1), read the new `springfield_quality_report.json` and `springfield_processed_items.json` to determine exact values. Update golden test assertions to match the new baseline. The key metrics to update:
- Overall quality score
- Quality status (should now be autoAccept with higher score)
- Item count
- Any specific field values used in assertions

**Verification:**
```bash
pwsh -Command "flutter test test/features/pdf/extraction/golden/springfield_golden_test.dart"
```

---

### Sub-phase 6.3: Run GT trace — verify improvements

**Agent:** `qa-testing-agent`

```bash
pwsh -Command "dart run tools/gt_trace.dart"
```

**Expected outcome:**
- Unit accuracy: 79.8% -> 100% (26 items fixed by R1)
- Items matched: 129/131 -> 131/131 (items 94+95 recovered by R2)
- Bogus items: 1 -> 0 (R2+R3)
- Dollar delta: $280,158 -> ~$0 (R2 recovers $280,156, R4 corrects $2)
- bidAmount accuracy: 99.2% -> 100% (R4 fixes item 96)
- Description accuracy: ~94.6% -> improved (R5 reduces OCR damage at grid lines)
- Overall OK count: 97 -> ~129-131

---

## Phase 7: Cleanup

### Sub-phase 7.1: Remove dead morphological constants

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/stages/grid_line_remover.dart`

**Action:** Already handled in Sub-phase 5.2. The full file rewrite removed `_adaptiveBlockSize`, `_adaptiveC`, `_kernelDivisor`, `_maskDilateIterations`, and all morphological operation code. No additional cleanup needed.

---

### Sub-phase 7.2: Remove unused unitAliases entries (if applicable)

**Agent:** `pdf-agent`
**File:** `lib/features/pdf/services/extraction/shared/unit_registry.dart`

**WHY:** After R1.2, `unitAliases` is no longer used by `normalize()`. However, `knownUnits` (line 63-66) still derives its values from `unitAliases.keys` and `unitAliases.values`. The `knownUnits` set is used for unit validation in `row_parser_v3.dart:200-203`.

**Decision:** KEEP `unitAliases` for now. It serves as the single source of truth for `knownUnits`. Removing it would require manually maintaining the `knownUnits` set. The map is inert (never queried for remapping after R1.2) but structurally useful.

**Action:** Add a doc comment to clarify its current role:

In `lib/features/pdf/services/extraction/shared/unit_registry.dart`, update the doc comment on line 6-7:

**Current:**
```dart
  /// Known unit aliases mapped to canonical forms.
  /// Keys are uppercase for case-insensitive lookups.
```

**Replace with:**
```dart
  /// Unit alias catalog — maps alternate forms to canonical forms.
  ///
  /// NOTE: normalize() no longer uses this map for remapping (cleanup-only
  /// since R1). The map is retained as the source of truth for [knownUnits]
  /// validation set. Both keys (aliases) and values (canonical forms) are
  /// included in [knownUnits].
```

---

### Sub-phase 7.3: Final test suite run

**Agent:** `qa-testing-agent`

```bash
pwsh -Command "flutter test"
```

**Expected outcome:** ALL tests pass. This is the final verification that all changes are consistent and no regressions were introduced.

```bash
pwsh -Command "dart run tools/gt_trace.dart"
```

**Expected outcome:** GT trace shows ~129-131 OK out of 131 items. Quality score ~0.99+.

---

## Dependency & Ordering Summary

```
Phase 0 ─── Pre-flight (must pass before any changes)
   │
   ├── Phase 1 (R1: Unit Normalization) ──── independent
   │
   ├── Phase 2 (R2: Row Classifier/Merger) ── must precede Phase 3
   │     └── Phase 3 (R3: Validation Gate) ── depends on Phase 2
   │
   ├── Phase 4 (R4: bidAmount Backsolve) ──── independent
   │
   └── Phase 5 (R5: Grid Line Removal) ────── independent
         │
         Phase 6 ─── Fixture Regeneration (after ALL R1-R5)
         │
         Phase 7 ─── Cleanup & Final Verification
```

Phases 1, 2, 4, and 5 are independent and can execute in any order (or in parallel).
Phase 3 MUST follow Phase 2.
Phase 6 MUST follow all of Phases 1-5.
Phase 7 MUST follow Phase 6.

---

## Files Modified Summary

<!-- REVISED: Updated for C1, C2, C3, H1, H2, H3 fixes -->
| File | Phase | Changes |
|------|-------|---------|
| `lib/features/pdf/services/extraction/shared/unit_registry.dart` | 1, 7 | Add `isLumpSum()`, make `normalize()` cleanup-only, update doc |
| `lib/features/pdf/services/extraction/stages/row_parser_v3.dart` | 1, 3 | LS checks -> `isLumpSum()`, **H3**: `isLumpSum()` guard on unknown unit warning, **C3**: validation gate with `skippedRows.add()` |
| `lib/features/pdf/services/extraction/shared/post_process_utils.dart` | 1 | LS check -> `isLumpSum()` |
| `lib/features/pdf/services/extraction/stages/consistency_checker.dart` | 1, 4 | LS check -> `isLumpSum()`, **H2**: bidAmount correction with shared `europeanPeriods` pattern |
| `lib/features/pdf/services/extraction/stages/post_processor_v2.dart` | 1 | LS check -> `isLumpSum()` |
| `lib/features/pdf/services/extraction/shared/extraction_patterns.dart` | 4 | **H2**: NEW `europeanPeriods` pattern (shared with currency_rules.dart) |
| `lib/features/pdf/services/extraction/rules/currency_rules.dart` | 4 | **H2**: Optionally updated to reference `ExtractionPatterns.europeanPeriods` |
| `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart` | 2 | `_isMinorTextContent` fix, **C1**: `_rescueBoilerplateRows` item-text guard, **C2**: NEW `_rescueDataLikeBoilerplateRows` method |
| `lib/features/pdf/services/extraction/stages/row_merger.dart` | 2 | **H1**: Grid line boundary guard with per-page `Map<int, List<double>>` |
| `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart` | 2 | **H1**: Pass per-page grid line map to merger |
| `lib/features/pdf/services/extraction/stages/grid_line_remover.dart` | 5 | Position-based masking rewrite |
| `test/features/pdf/extraction/shared/unit_registry_test.dart` | 1 | NEW -- unit tests |
| `test/features/pdf/extraction/stages/row_merger_test.dart` | 2 | NEW -- **H1**: grid line guard tests with per-page Map + cross-page tests |
| `test/features/pdf/extraction/stages/consistency_checker_test.dart` | 4 | NEW -- bidAmount correction tests |
| `test/features/pdf/extraction/stages/grid_line_remover_test.dart` | 5 | Updated for position-based approach |
| `test/features/pdf/extraction/stages/row_classifier_v3_test.dart` | 2 | Added non-numeric item column test, **C2**: R2c rescue test |
| `test/features/pdf/extraction/golden/springfield_golden_test.dart` | 6 | Updated baselines |
| `test/features/pdf/extraction/fixtures/springfield_*.json` | 6 | Regenerated (~30 files) |
