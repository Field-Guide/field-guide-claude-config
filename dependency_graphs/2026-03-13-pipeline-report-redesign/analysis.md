# Dependency Graph: Pipeline Report Redesign

## Direct Changes (1 file)

### `test/features/pdf/extraction/helpers/report_generator.dart`

| Symbol | Lines | Change |
|--------|-------|--------|
| `generateScorecard()` | 126-346 | REWRITE: Replace Stage Statistics (multi-row) + Performance Summary + Cell Extraction Detail (`<details>`) with Stage Summary (one-row-per-stage) + Clean Grid (per page) + OCR Grid (per page). Keep Header, Regressions, Item Flow, Summary Footer. |
| `_buildStageMetrics()` | 350-362 | MODIFY: Add `input_count`, `output_count`, `excluded_count` from StageReport to each stage entry |
| `_metricStatus()` | 575-582 | KEEP — reused by Stage Summary Status column |
| `_truncate()` | 584-587 | KEEP — used by Clean Grid (40 chars) and Item Flow (20 chars) |
| `_stageLabel()` | 556-560 | DELETE — Stage Summary uses full stageName |
| `_formatDelta()` | 562-570 | DELETE — no per-metric delta in new layout |
| `_capitalize()` | 589-592 | KEEP — used by Performance Summary (kept per user decision) |

**New symbols:**
- `_escapePipe(String)` — escape `|` to `\|` and replace newlines with spaces
- `_clampConfidence(num)` — clamp to 0.0-1.0 range
- `_kRowTypeAbbrev` — const map for type abbreviations (hdr, data, cont-p, cont-d, boil, sect, totl, blnk)

## Dependent Files (0 code changes needed)

| File | Relationship | Impact |
|------|-------------|--------|
| `integration_test/springfield_report_test.dart:225` | Caller of `generateScorecard()` | Signature UNCHANGED — zero changes |
| `lib/features/pdf/services/extraction/models/stage_report.dart` | Data source | Has `inputCount`, `outputCount`, `excludedCount` already. No changes. |
| `test/features/pdf/extraction/helpers/pipeline_comparator.dart` | Provides `RegressionResult` | Unchanged |

## Test Files (0 additional)

No unit tests for `ReportGenerator`. Verification via `springfield_report_test.dart` (integration test).

## Key Model Facts

### StageReport (`lib/.../models/stage_report.dart:4-105`)
- Fields: `stageName`, `elapsed`, `stageConfidence`, `inputCount`, `outputCount`, `excludedCount`, `warnings`, `metrics`, `completedAt`
- `inputCount`/`outputCount`/`excludedCount` exist on model but NOT serialized by `_buildStageMetrics()` (line 356 only spreads `report.metrics`)

### cell_grid JSON structure (built by `_buildCellGrid()` lines 458-504)
- Array of: `{ row_index, type, page_index?, cells[] }`
- Each cell: `{ column, value, confidence, element_count, elements[] }`
- Each element: `{ text, confidence }`
- 6 columns: item_number, description, unit, quantity, unit_price, bid_amount

### RowType abbreviation mapping
- header -> hdr, data -> data, priceContinuation -> cont-p, descContinuation -> cont-d
- blank -> blnk, boilerplate -> boil, sectionHeader -> sect, total -> totl

## Data Flow

```
StageReport ──> _buildStageMetrics() ──> JSON['stage_metrics'] ──> Stage Summary (Section 2)
                (adds input_count, output_count, excluded_count)

_buildCellGrid() ──> JSON['cell_grid'] ──> Clean Grid (Section 3) + OCR Grid (Section 4)
                                            cells[].value             cells[].elements[].text/.confidence
```

## Blast Radius

- **1 file modified** (report_generator.dart)
- **2 methods rewritten** (generateScorecard, _buildStageMetrics)
- **2 methods deleted** (_stageLabel, _formatDelta)
- **3 new helpers** (_escapePipe, _clampConfidence, _kRowTypeAbbrev)
- **0 dependent file changes**
- **0 test file changes**
