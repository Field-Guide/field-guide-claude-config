# Dependency Graph: Table-Bounded Text Protection Dilation

**Date**: 2026-03-12
**Source**: Pre-completed blast radius analysis (CodeMunch) + code verification (2 Sonnet agents)

## Affected Files

### Direct Changes (1 file)
| File | Change Type | Lines Affected |
|------|-------------|----------------|
| `lib/features/pdf/services/extraction/stages/grid_line_remover.dart` | Modify | ~482-488 (insert table bounds logic before dilate) |

### No API Surface Changes
- `GridLine` model: unchanged
- `GridLineResult` model: unchanged
- `GridLines` model: unchanged
- `remove()` public method signature: unchanged
- `_GridRemovalResult` fields: unchanged (textProtectionPixels already exists)

### No Pipeline Changes
- `extraction_pipeline.dart`: unchanged
- No new stages, no reordering

## Data Flow

```
GridLineResult.horizontalLines (sortedH) ──┐
GridLineResult.verticalLines (sortedV)   ──┤
                                            ▼
                               [Table Bounds Computation]
                               tableTop/Bottom/Left/Right
                                            │
                                            ▼
                               [tableBoundsMask: Mat zeros + filled rect]
                                            │
                                            ▼
textPixels (binary & ~gridMask) ──────────► AND with tableBoundsMask
                                            │
                                            ▼
                               [Bounded textPixels]
                                            │
                                            ▼
                               dilate(boundedTextPixels, 5x5)
                                            │
                                            ▼
                               textProtection (used to subtract from removalMask)
```

## Blast Radius Categorization

| Category | Count | Details |
|----------|-------|---------|
| Direct source changes | 1 | grid_line_remover.dart |
| Dependent source changes | 0 | No API surface change |
| Test files to verify | 6 | grid_line_remover_test, grid_line_remover_morph_test, stage_2b5_to_2b6_contract_test, stage_2b6_to_2biii_contract_test, grid_removal_diagnostic_test, springfield_report_test |
| New test files | 0 | None |
| Cleanup tasks | 0 | None |

## Variables Available at Insertion Point (~line 482-487)

| Variable | Type | Source |
|----------|------|--------|
| `sortedH` | `List<GridLine>` | Re-sorted at line 359 |
| `sortedV` | `List<GridLine>` | Re-sorted at line 360 |
| `rows` | `int` | gray.rows (line 328) |
| `cols` | `int` | gray.cols (line 329) |
| `textPixels` | `cv.Mat` | Computed at line 482 |
| `binary` | `cv.Mat` | Threshold at line 365-366 |
| `gridMask` | `cv.Mat` | hMask | vMask at line 478 |
| `notGridMask` | `cv.Mat` | bitwiseNOT at line 481 |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Boilerplate inside table bounds | Medium | Low | Option C reduces external noise; doesn't eliminate internal boilerplate |
| Degenerate grid (<2 lines) | Low | None | Guard falls back to global protection |
| Mat leak (new tableBoundsMask) | Low | Medium | Must add to try/finally disposal chain |
| cv.rectangle not available | Medium | None | Use cv.line with thick line as fill strategy |
