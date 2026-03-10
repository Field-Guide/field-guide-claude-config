# Blast Radius: 100% Accuracy Fixes

## Summary

**Direct Changes**: 10 files
**Dependent Files**: 4 files
**Tests Needed**: 8 files
**Cleanup Items**: 2 items

### Direct Changes

| File | Fix | Changes | Risk |
|------|-----|---------|------|
| `lib/.../shared/unit_registry.dart` | R1 | Remove alias remapping from normalize(), add isLumpSum() helper | LOW |
| `lib/.../stages/row_parser_v3.dart` | R1, R3 | Lines 179, 207, 247 (LS checks → isLumpSum()), lines 196-198 (validation gate) | LOW |
| `lib/.../shared/post_process_utils.dart` | R1 | Line 305 (LS check → isLumpSum()) | LOW |
| `lib/.../stages/consistency_checker.dart` | R1, R4 | Line 72 (LS check), line 128 (add bidAmount correction branch) | LOW-MOD |
| `lib/.../stages/post_processor_v2.dart` | R1 | Line 724 (LS check → isLumpSum()) | LOW |
| `lib/.../stages/row_classifier_v3.dart` | R2 | Lines 327-334 (_isMinorTextContent → any text in itemNumber col) | MODERATE |
| `lib/.../stages/row_merger.dart` | R2 | Add grid line boundary guard, modify merge() signature | MODERATE |
| `lib/.../stages/grid_line_remover.dart` | R5 | Replace morphological mask-building with position-based masking | MODERATE |
| `lib/.../pipeline/extraction_pipeline.dart` | R2, R5 | Pass GridLineResult to remover and merger | LOW |
| `lib/.../stages/value_normalizer.dart` | R1 | Lines 42-57 — chains to normalize(), verify behavior | VERIFY |

### Dependent Files

| File | Dependency | Action Needed |
|------|------------|---------------|
| `lib/.../shared/confidence_model.dart` | R4 uses kAdjMathBacksolve | VERIFY constant exists |
| `lib/.../models/processed_items.dart` | R4 uses RepairType.mathValidation | VERIFY enum exists |
| `lib/.../shared/extraction_patterns.dart` | R3 uses itemNumberLoose pattern | VERIFY pattern exists |
| `lib/.../models/grid_line_result.dart` | R5 needs line positions + widths | VERIFY model has width data |

### Tests

| File | Status | Action |
|------|--------|--------|
| `test/.../stages/grid_line_remover_test.dart` | EXISTS | UPDATE for position-based approach |
| `test/.../stages/row_classifier_v3_test.dart` | EXISTS | ADD test for non-numeric item-number-column text |
| `test/.../golden/springfield_golden_test.dart` | EXISTS | UPDATE baselines after all fixes |
| `test/.../golden/springfield_benchmark_test.dart` | EXISTS | UPDATE baselines |
| Unit test for UnitRegistry.normalize() | MISSING | CREATE |
| Unit test for UnitRegistry.isLumpSum() | MISSING | CREATE |
| Unit test for ConsistencyChecker bidAmount branch | MISSING | CREATE |
| Unit test for RowMerger grid line guard | MISSING | CREATE |

### Cleanup

| File | Item | Action |
|------|------|--------|
| `lib/.../shared/unit_registry.dart` | unitAliases map (52 entries) | Remove or repurpose |
| `lib/.../stages/grid_line_remover.dart` | Morphological constants (_adaptiveBlockSize, _kernelDivisor, _maskDilateIterations) | Remove |

### Fixture Regeneration

All fixtures in `test/features/pdf/extraction/fixtures/springfield_*.json` must be regenerated after all fixes are applied. This is ~30 files.
