# Blast Radius: Grid Line Threshold Fix

## Summary

**Direct Changes**: 1 file
**Dependent Files**: 0 code changes (behavior improves automatically)
**Tests Needed**: 2 files (1 modify, 1 verify)
**Fixture Regen**: 30+ JSON files
**Cleanup Items**: 0

## Direct Changes

| File | Changes | Risk |
|------|---------|------|
| `lib/features/pdf/services/extraction/stages/grid_line_remover.dart:15` | Change `_adaptiveC` from `-2.0` to `+2.0` | LOW — single constant, existing tests cover edge cases |

## Dependent Files (no code changes)

| File | Dependency | Action Needed |
|------|------------|---------------|
| `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart:508` | Calls `GridLineRemover.remove()` | VERIFY — improved OCR quality propagates |

## Tests

| File | Status | Action |
|------|--------|--------|
| `test/features/pdf/extraction/stages/grid_line_remover_test.dart` | EXISTS (4 tests) | ADD mask coverage sanity test |
| `test/features/pdf/extraction/golden/springfield_benchmark_test.dart` | EXISTS | VERIFY — scorecard should improve |
| `test/features/pdf/extraction/golden/stage_trace_diagnostic_test.dart` | EXISTS | VERIFY — checksum should improve |
| `test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart` | EXISTS | NOT AFFECTED (uses MockGridLineRemover) |
| `test/features/pdf/extraction/pipeline/re_extraction_loop_test.dart` | EXISTS | NOT AFFECTED (uses MockGridLineRemover) |

## Fixtures to Regenerate

All `test/features/pdf/extraction/fixtures/springfield_*.json` (30+ files) via:
```
integration_test/generate_golden_fixtures_test.dart
```

## Cleanup

None required.
