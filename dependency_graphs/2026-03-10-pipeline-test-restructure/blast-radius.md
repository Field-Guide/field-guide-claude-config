# Blast Radius: Pipeline Test Suite Restructure

**Generated**: 2026-03-10

## Impact Summary

| Category | Count | Files |
|----------|-------|-------|
| DIRECT (new files) | 4 | `pipeline_comparator.dart` (lib), `pipeline_comparator.dart` (CLI), `report_generator.dart`, `springfield_report_test.dart` |
| DEPENDENT (modified) | 2 | `full_pipeline_integration_test.dart`, `.gitignore` |
| TEST (deleted) | 8 | `stage_trace_diagnostic_test.dart`, `springfield_golden_test.dart`, `springfield_benchmark_test.dart`, `golden_file_matcher.dart`, `golden_file_matcher_test.dart`, `golden/README.md`, `springfield_benchmark_results.json`, `generate_golden_fixtures_test.dart` |
| CLEANUP (deleted tools) | 3 | `gt_trace.dart`, `compare_golden.py`, `compare_stage_dumps.py` |
| **Total** | **17** | |

## Lines of Code

| Action | Lines |
|--------|-------|
| Deleted | ~7,632 + ~50 (benchmark JSON) |
| Created | ~1,580-2,120 |
| Modified | ~15 (import change + API update + gitignore entry) |
| **Net delta** | **-5,500 to -6,050** |

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| `full_pipeline_integration_test.dart` import breaks | HIGH | Update import + API before deleting `golden_file_matcher.dart` |
| Report JSON schema evolves later | LOW | `schema_version` field enables forward compatibility |
| Android file I/O path incorrect | MEDIUM | Test on device; doc header includes adb pull commands |
| `stage_fixtures.dart` deleted by mistake | HIGH | Verified: NOT in deletion list; used by MP fixture generator |
| Archive retention deletes wrong folders | LOW | Folder naming pattern is deterministic (`<platform>_<date>_<time>`) |
| `pipeline_comparator.dart` exceeds 1,500 lines | MEDIUM | Spec guardrail: split into `pipeline_comparator.dart` + `regression_gate.dart` if needed |
| Ground truth file missing on Android | MEDIUM | Doc header documents both bundling options (asset vs adb push) |

## Unchanged Pipeline Infrastructure (READ-ONLY Dependencies)

These files are consumed but NOT modified:
- `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`
- `lib/features/pdf/services/extraction/stages/stage_names.dart`
- `lib/features/pdf/services/extraction/stages/stage_fixtures.dart`
- `lib/features/pdf/services/extraction/models/stage_report.dart`
- `lib/features/pdf/services/extraction/models/parsed_items.dart`
- `lib/features/pdf/services/extraction/models/processed_items.dart`
- `lib/features/pdf/services/extraction/models/quality_report.dart`
- `lib/features/pdf/services/extraction/models/document_checksum.dart`
- `lib/features/pdf/services/extraction/models/pipeline_config.dart`
- `lib/features/pdf/services/extraction/models/sidecar.dart`
- `packages/flusseract/lib/tesseract.dart`
