# Research: Springfield Pipeline 100% Accuracy

**Created**: 2026-03-09 | **Session**: 525
**Status**: Research complete. Ready for implementation planning (R1-R4 confirmed, R5 needs investigation).

## Current Baseline

| Metric | Value |
|--------|-------|
| Quality Score | 0.918 (autoAccept) |
| Pipeline Items | 130 |
| Ground Truth Items | 131 |
| GT Matched | 129/131 (98.5%) |
| Pipeline Total | $7,602,768.73 |
| GT Total | $7,882,926.73 |
| Delta | $280,158.00 (3.55%) |
| Bogus/Extra Items | 1 ("94 Boy") |

### Quality Score Breakdown

| Component | Score |
|-----------|-------|
| Completeness | 0.995 |
| Coherence | 1.000 |
| Math Validation | 1.000 |
| Median Confidence | 0.973 |
| Structural Score | 0.975 |
| Checksum Validation | 0.500 (drags overall down) |

### Field Accuracy (129 matched items)

| Field | Accuracy | Pass/Total |
|-------|----------|------------|
| description | 94.6% | 122/129 |
| unit | 79.8% | 103/129 |
| quantity | 100.0% | 129/129 |
| unitPrice | 100.0% | 129/129 |
| bidAmount | 99.2% | 128/129 |

---

## Full GT Trace — 34 Failures

### Category 1: MISSING Items (2 items — $280,156 of delta)

| Item | GT bidAmount | Status |
|------|-------------|--------|
| #94 | $253,500.00 | MISSING — merged into bogus "94 Boy" |
| #95 | $26,656.00 | MISSING — OCR read "95" as "Boy" (0.49 conf) |

### Category 2: Unit Normalization Wrong (26 items)

Pipeline normalizes long forms to short forms. GT uses long forms (confirmed correct by user).

| Pattern | Pipeline | GT (correct) | Items |
|---------|----------|--------------|-------|
| LS vs LSUM | LS | LSUM | #1, #2, #3, #4, #25, #36, #37, #38 |
| SY vs SYD | SY | SYD | #9, #13, #14, #15, #17, #18, #102, #118 |
| CY vs CYD | CY | CYD | #22, #23, #24, #26, #93 |
| SF vs SFT | SF | SFT | #103, #104, #105 |
| HR vs HOUR | HR | HOUR | #27 |

Raw OCR (`raw_unit`) reads long forms correctly (LSUM, SYD, etc.). Pipeline then normalizes them away via `UnitRegistry.normalize()`.

### Category 3: Description OCR Errors (7 items)

| Item | Pipeline | GT | Sim | Root Cause |
|------|----------|-----|-----|------------|
| #26 | "randing And Contaminated Mater..." | "Non-Hazardous Contaminated Mat..." | 0.479 | Leading text entirely lost from OCR |
| #68 | "Bena. 11.25deg, 8"" | "Bend, 11.25deg, 8"" | 0.875 | OCR char error: d,->a. |
| #99 | "HMA, SEML" | "HMA, 5EML" | 0.889 | OCR char error: 5->S |
| #121 | "te Property Landscape Repair..." | "Private Property Landscape Rep..." | 0.680 | First line of multi-line desc lost ("Priva") |
| #123 | "pavt es Waterborne, 2nd Applic..." | "Pavt Mrkg, Waterborne, 2nd App..." | 0.735 | "Mrkg," lost; cross-item text bleed |
| #125 | "Dav Mig. Waterborne, 2nd Appli..." | "Pavt Mrkg, Waterborne, 2nd App..." | 0.771 | "Pavt Mrkg," OCR'd as "Dav Mig." |
| #130 | "i Mrkg, Polyurea, Thru and Rt..." | "Pavt Mrkg, Polyurea, Thru and..." | 0.830 | "Pavt" OCR'd as "i" |

### Category 4: bidAmount Error (1 item)

| Item | Pipeline | GT | Delta |
|------|----------|-----|-------|
| #96 | $177,133.00 | $177,135.00 | $2.00 |

OCR reads `$177.133.00` (European periods). Parser correctly interprets as 177133 but digit '5' was misread as '3'.

### Category 5: Bogus Item (1 item)

| Item# | Description | Source |
|-------|-------------|--------|
| "94 Boy" | "Aggregate Aggregate Base, Base, 6" 8"" | Garbled merge of items 94+95 |

---

## Proposed Fixes — Verified by Opus Agents

### R1: Stop Unit Normalization (keep raw OCR output)

**Verdict**: NEEDS REVISION from original (was "reverse canonical direction")
**Items fixed**: 26
**Risk**: LOW

**Root cause**: `UnitRegistry.normalize()` in `unit_registry.dart:8-60` maps long forms to short forms (LSUM->LS, SYD->SY, etc.). OCR correctly reads long forms. Pipeline normalizes them away.

**Correct approach**: Remove normalization, keep raw OCR output.

**Code changes needed**:
- `unit_registry.dart` — Either remove the alias map or change canonical direction
- `row_parser_v3.dart:179` — Stop calling `UnitRegistry.normalize()` (or make it preserve long forms)
- `value_normalizer.dart:42-57` — Stop re-normalizing via `PostProcessUtils.normalizeUnit()`

**CRITICAL — 4 hardcoded `== 'LS'` checks that WILL BREAK**:
1. `row_parser_v3.dart:247` — default quantity=1.0 for Lump Sum
2. `post_process_utils.dart:305` — `isValidQuantity` LS check
3. `consistency_checker.dart:72` — LS unit detection
4. `post_processor_v2.dart:724` — LS lump sum detection

All must be updated to use a helper like `UnitRegistry.isLumpSum(unit)` that accepts both 'LS' and 'LSUM'.

**Also update**: `bid_item.dart:8` comment says `// EA, FT, SY, CY, etc.` — update to reflect long forms.

**knownUnits set** (`unit_registry.dart:63-66`) already contains all keys AND values, so validation still passes.

---

### R2: Fix Row Classifier/Merger for Items 94/95

**Verdict**: NEEDS REVISION from original (was "split merged cell grid rows")
**Items fixed**: 2 MISS + 1 BOGUS removed = recovers $280,156
**Risk**: HIGH (affects all row classification globally)

**Root cause (Opus-verified)**:

The original diagnosis was WRONG. The cell extractor is NOT the problem. The actual failure chain:

1. OCR reads "95" as "Boy" (confidence 0.49)
2. Row classifier (`row_classifier_v3.dart:244-256`) checks if row has item number matching `^\d+(\.\d+)?$`. "Boy" does NOT match -> row is NOT classified as `data`
3. Row 214 falls through to `priceContinuation` classification (it has price elements: "$11.90", "$26,656.00")
4. Row merger (`row_merger.dart:29-42`) blindly attaches row 214 as priceContinuation of row 211 (item 94)
5. Cell extractor processes the merged row -> concatenated values: "94 Boy", "30,000 2,240", "$253,500.00 $26,656.00"

**Key finding**: Horizontal grid lines DO correctly separate items 94/95 (y=0.26358 and y=0.29274). The row classifier correctly groups elements into separate rows. The problem is CLASSIFICATION of row 214's type, not element grouping.

**Correct fix — two options**:

**Option A (fix classifier)**: If a row has elements in the item-number column (even if they don't match the number pattern) AND elements in price columns, consider it as a potential data row rather than priceContinuation. A priceContinuation should NOT have elements in the item-number column.

**Option B (fix merger)**: Add a guard in `row_merger.dart` that refuses to merge a continuation row when its elements span a grid line boundary. Pass grid line positions to the merger.

**`_splitRowWithMultipleItemNumbers` already exists** (`row_classifier_v3.dart:651-711`) but fails because "Boy" doesn't match the item number pattern, so only "94" is detected as an anchor. With only 1 anchor, split is not triggered (line 675: `if (itemNumberElements.length < 2) return [row]`).

**Classified rows fixture evidence** (`springfield_classified_rows.json`):
- Row 211: type=data (item 94, correct)
- Row 212: type=priceContinuation (contains "$8.45", "$253,500.00" — item 94's prices, correct)
- Row 213: type=descContinuation (item 95 description elements)
- Row 214: type=priceContinuation (contains "Boy", "$11.90", "$26,656.00" — SHOULD BE data)

---

### R3: Item Number Validation Gate (defense-in-depth)

**Verdict**: INSUFFICIENT ALONE — secondary defense after R2
**Items fixed**: 0 alone (prevents bogus items from reaching output)
**Risk**: LOW

**Current behavior**: `row_parser_v3.dart:196-198` adds warning "Invalid item number format: 94 Boy" but continues outputting the item.

**Fix**: Convert warning to `continue` (skip the item). BUT this alone would lose both items 94 AND 95 (net data loss). Only useful after R2 properly splits the row.

**Pattern concern**: `^\d+(\.\d+)?$` may be too strict for other PDFs with alpha-suffixed items (e.g., "101A", "2-1", "SP-1"). The `ExtractionPatterns.itemNumberLoose` pattern (`^\d+(\.\d+)?[A-Za-z]?\.?$`) already exists for broader matching.

---

### R4: Extend Math Backsolve for bidAmount Correction

**Verdict**: CONFIRMED (with caveats)
**Items fixed**: 1 (#96, $2 delta)
**Risk**: MODERATE

**Root cause (code-verified)**:

`consistency_checker.dart:92-138`:
1. Detects discrepancy: `qty * unitPrice = $177,135 != bidAmount $177,133` (diff=$2)
2. Tries unitPrice backsolve: `backsolved = bidAmount/qty = 177133/2410 = $73.498... -> rounded $73.50`
3. Round-trip check: `2410 * 73.50 = $177,135`. Diff from bidAmount = $2. Since $2 > $0.01 tolerance, backsolve REJECTED
4. Falls through to warning: "Math validation: calculated amount ($177135.00) does not match bid amount ($177133.00)"
5. **Code NEVER attempts to correct bidAmount** — only tries to fix unitPrice

**Fix**: Add a branch after unitPrice backsolve fails (line 128, the else branch):
```
if qty * unitPrice produces exact integer result
AND relative error < 0.5% of bidAmount
AND bidAmount was matched via correction pattern (e.g., european_periods)
THEN correct bidAmount = qty * unitPrice
```

**CRITICAL CAVEAT**: The proposed confidence comparison (bidAmount conf < qty AND unitPrice conf) WILL NOT WORK for item 96:
- bidAmount OCR conf = 0.77
- quantity OCR conf = 0.62 (LOWER than bidAmount)
- unitPrice OCR conf = 0.96

Must use **pattern-based detection** instead: if bidAmount's `matchedPattern` is a correction pattern (like `european_periods`, `corrupted_symbol`, `missing_decimals`), that's stronger evidence of OCR error than raw confidence scores.

**Item 96 field confidence** (`springfield_field_confidence.json`):
- bidAmount: value=177133.0, matched_pattern=`european_periods`, ocr_conf=0.77, weighted_score=0.849
- unitPrice: value=73.5, ocr_conf=0.96
- quantity: value=2410.0, ocr_conf=0.62

**Confidence penalty**: Use existing `kAdjMathBacksolve = -0.03` (from `confidence_model.dart:27`).
**RepairType**: Use existing `RepairType.mathValidation`.

---

### R5: Description Accuracy Improvements

**Verdict**: NEEDS FURTHER INVESTIGATION
**Items affected**: 5-7 (some may be unfixable)
**Risk**: UNKNOWN

**Original F2 diagnosis was WRONG** (Opus-verified):

The original claim was that priceContinuation rows contain description text that isn't flowing through. **This is false** — description text in priceContinuation rows IS already flowing through to the description cell via x-coordinate column assignment in the cell extractor.

**Actual root causes (per item)**:

| Item | Actual Root Cause | Fixable? |
|------|-------------------|----------|
| #26 | "Non-Hazardous" entirely missing from OCR. "randing" is desc continuation, "And" is in price row. Text IS flowing through but original text was never OCR'd. | UNCLEAR — may need crop investigation |
| #68 | Pure OCR char error: "Bend," -> "Bena." | NO (OCR accuracy limit) |
| #99 | Pure OCR char error: "5EML" -> "SEML" | NO (OCR accuracy limit) |
| #121 | "Priva" from first line of multi-line desc is on previous physical row, lost during row grouping. "te Property" IS captured via priceCont x-coordinate mapping. | UNCLEAR — needs row grouping investigation |
| #123 | "Pavt Mrkg," OCR'd as "pavt es" in priceContinuation. Text IS captured but OCR corrupted it. The word "Yellow" (end of desc) is in PREVIOUS item's (122) data row — cross-item text bleed. | PARTIAL — OCR corruption unfixable, but "Yellow" recovery may be possible |
| #125 | "Pavt Mrkg," OCR'd as "Dav Mig." — OCR corruption. "White" (end of desc) in previous item's row. | PARTIAL — same as 123 |
| #130 | "Pavt" OCR'd as "i". "Sym" (end of desc) in previous item's row. | PARTIAL — same as 123 |

**Key insight from Opus**: For items 123, 125, 130, the trailing words ("Yellow", "White", "Sym") belong to the current item but appear in the PREVIOUS item's data row. This is a cross-item text bleed problem where multi-line descriptions span across what the classifier considers two separate items.

**Investigation needed**:
1. How does `_groupElementsByRow` (row_classifier_v3.dart:612-649) determine row boundaries?
2. What is the adaptive Y-threshold for grouping elements into rows?
3. For items 121, 123, 125, 130 — where exactly are the description first-line elements in the unified_elements fixture? What are their y-coordinates relative to the grid lines?
4. Could tightening the Y-threshold help, or would it break legitimate multi-line text within a single row?
5. For the text IN priceContinuation rows (e.g., "te Property" for item 121) — is it being placed in the correct position within the description string (prepended vs appended)?

**Separate concern — OCR crop boundaries**:
One Opus agent investigated the text_recognizer's padding/unmapping logic (`text_recognizer_v2.dart:636-651`) and found asymmetric padding unmapping that could cause leading-character truncation. This may explain items 121, 123, 125, 130 where leading characters are lost. But this theory needs more concrete evidence — the description column is wide, so padding effects should be minimal.

---

## Test Coverage Gaps

| Component | Test File | Status |
|-----------|----------|--------|
| UnitRegistry.normalize() | None | NO tests |
| row_classifier_v3 | `row_classifier_v3_test.dart` | EXISTS |
| cell_extractor_v2 | None | NO tests |
| consistency_checker | None | NO tests |
| row_parser | `row_parser_semantic_mapping_test.dart` | EXISTS |
| row_splitter | None | NO tests |

---

## Expected Impact

### With R1-R4 implemented:
- Unit accuracy: 79.8% -> 100% (+26 items)
- Items matched: 129/131 -> 131/131 (+2 items)
- Bogus items: 1 -> 0
- Dollar delta: $280,158 -> ~$0
- Quality score: 0.918 -> ~0.99+
- Overall: 97 OK -> ~126 OK out of 131

### With R5 (if achievable):
- Description accuracy: 94.6% -> ~98-100%
- Overall: ~126 OK -> ~129-131 OK out of 131
- 2 items (#68, #99) may remain as unfixable OCR char errors

---

## Implementation Order

1. **R2** (row classifier/merger) — prerequisite for R3, highest impact ($280K)
2. **R1** (unit normalization) — independent, safe, 26 items fixed
3. **R3** (validation gate) — defense-in-depth after R2
4. **R4** (bidAmount backsolve) — independent, 1 item fixed
5. **R5** (descriptions) — needs more research first

---

## Files Reference

| File | Role in Fixes |
|------|---------------|
| `lib/features/pdf/services/extraction/shared/unit_registry.dart` | R1: alias map, normalize(), knownUnits |
| `lib/features/pdf/services/extraction/stages/row_parser_v3.dart` | R1: normalize call (line 179), R3: validation (lines 196-198) |
| `lib/features/pdf/services/extraction/stages/value_normalizer.dart` | R1: re-normalize (lines 42-57) |
| `lib/features/pdf/services/extraction/shared/post_process_utils.dart` | R1: normalizeUnit(), isValidQuantity LS check (line 305) |
| `lib/features/pdf/services/extraction/stages/row_classifier_v3.dart` | R2: classification logic (lines 244-291), _splitRowWithMultipleItemNumbers (lines 651-711) |
| `lib/features/pdf/services/extraction/stages/row_merger.dart` | R2: blind merge (lines 29-42) |
| `lib/features/pdf/services/extraction/stages/cell_extractor_v2.dart` | R2: _buildCell (line 531) |
| `lib/features/pdf/services/extraction/rules/numeric_rules.dart` | R3: ItemNumberCleanupRule (lines 5-30) |
| `lib/features/pdf/services/extraction/stages/consistency_checker.dart` | R4: backsolve logic (lines 92-138) |
| `lib/features/pdf/services/extraction/stages/post_processor_v2.dart` | R1: LS check (line 724), R3: warning reconciliation (lines 758-759) |
| `lib/features/pdf/services/extraction/shared/field_format_validator.dart` | R3: validateItemNumber (lines 14-17) |
| `lib/features/pdf/services/extraction/stages/text_recognizer_v2.dart` | R5: padding unmapping (lines 636-651), cell crops (lines 308-332) |

## Fixture Files (for stage tracing)

All in `test/features/pdf/extraction/fixtures/`:
- `springfield_unified_elements.json` — raw OCR elements
- `springfield_cell_grid.json` — cell-level grid
- `springfield_classified_rows.json` — row types
- `springfield_merged_rows.json` — merged rows
- `springfield_interpreted_grid.json` — semantic interpretation
- `springfield_parsed_items.json` — parsed bid items
- `springfield_field_confidence.json` — per-field confidence
- `springfield_ocr_metrics.json` — OCR quality metrics
- `springfield_processed_items.json` — final output
- `springfield_ground_truth_items.json` — verified GT (131 items)
- `springfield_quality_report.json` — quality score breakdown

## Tools Created This Session

- `tools/gt_trace.dart` — Full per-item GT comparison script (run with `dart run tools/gt_trace.dart`)
