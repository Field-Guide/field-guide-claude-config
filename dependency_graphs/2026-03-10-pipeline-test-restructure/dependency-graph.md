# Dependency Graph: Pipeline Test Suite Restructure

**Generated**: 2026-03-10 | **Spec**: `.claude/specs/2026-03-10-pipeline-test-restructure-spec.md`

## Symbol Dependency Map

### Pipeline Infrastructure (CONSUMED by new code — READ-ONLY)

| Symbol | File:Line | Used By |
|--------|-----------|---------|
| `ExtractionPipeline` | `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart:143` | `springfield_report_test.dart` (calls `extract()`) |
| `ExtractionPipeline.extract()` | `:220` | Integration test — `onStageOutput`, `onDiagnosticImage` callbacks |
| `ExtractionPipeline._selectBest()` | `:848` | Internal: best-attempt selection by quality score |
| `PipelineResult` | `:17` | `report_generator.dart` — items, quality, stage reports, timing |
| `PipelineResult.processedItems` | `:19` | Report generator — `items`, `checksum`, `repairLog` |
| `PipelineResult.qualityReport` | `:20` | Report generator — `overallScore`, `status` |
| `PipelineResult.stageReports` | `:21` | Report generator — per-stage `elapsed`, `metrics` |
| `PipelineResult.totalAttempts` | `:24` | Report metadata — attempt count |
| `PipelineResult.totalElapsed` | `:25` | Report metadata — total duration |
| `PipelineResult.toMap()` | `:70` | Not used directly; we access fields individually |
| `StageNames` (27 constants) | `lib/features/pdf/services/extraction/stages/stage_names.dart:5` | All new files — stage identification constants |
| `StageReport` | `lib/features/pdf/services/extraction/models/stage_report.dart:4` | `report_generator.dart` — `elapsed`, `metrics`, `inputCount`, `outputCount`, `stageName` |
| `StageReport.toMap()` | `:63` | Report generator — serializing stage data to JSON |
| `ProcessedItems` | `lib/features/pdf/services/extraction/models/processed_items.dart:93` | Report generator — `items`, `checksum`, `repairLog`, `repairStats` |
| `ProcessedItems.checksum` | `:101` | Report generator — `DocumentChecksum.computedTotal`, `extractedDocumentTotal` |
| `ParsedBidItem` | `lib/features/pdf/services/extraction/models/parsed_items.dart:7` | `pipeline_comparator.dart` — field comparison (itemNumber, description, unit, quantity, unitPrice, bidAmount, confidence) |
| `QualityReport` | `lib/features/pdf/services/extraction/models/quality_report.dart:21` | Report generator — `overallScore`, `status` |
| `QualityReport.toMap()` | (method) | Report generator — serializing quality data |
| `QualityStatus` | `lib/features/pdf/services/extraction/models/quality_report.dart:9` | Report generator — status enum values |
| `DocumentChecksum` | `lib/features/pdf/services/extraction/models/document_checksum.dart:12` | Report generator — `computedTotal`, `extractedDocumentTotal` |
| `PipelineConfig` | `lib/features/pdf/services/extraction/models/pipeline_config.dart:7` | Integration test — default config for pipeline |
| `stageToFilename` | `lib/features/pdf/services/extraction/stages/stage_fixtures.dart:6` | Integration test — maps 26 stage names to filenames (reuse for stage identification in `onStageOutput` callback) |
| `Tesseract.version` | `packages/flusseract/lib/tesseract.dart:304` | `report_generator.dart` — version metadata |

### Files Being DELETED (DIRECT impact)

| File | Lines | Symbols | Consumers |
|------|-------|---------|-----------|
| `test/.../golden/stage_trace_diagnostic_test.dart` | 4,876 | 35 | None (standalone test) |
| `test/.../golden/springfield_golden_test.dart` | 630 | 5 | None (standalone test) |
| `test/.../golden/springfield_benchmark_test.dart` | 280 | 7 | None (standalone test) |
| `test/.../golden/golden_file_matcher.dart` | 533 | 32 | `full_pipeline_integration_test.dart:27`, `springfield_golden_test.dart:19`, `springfield_benchmark_test.dart:11`, `golden_file_matcher_test.dart:5` |
| `test/.../golden/golden_file_matcher_test.dart` | ~200 | 1 | None (tests golden_file_matcher) |
| `test/.../golden/README.md` | 256 | 0 | None (documentation) |
| `test/.../golden/springfield_benchmark_results.json` | (data) | 0 | `springfield_benchmark_test.dart` (loaded at runtime) |
| `integration_test/generate_golden_fixtures_test.dart` | 260 | 5 | None (standalone integration test) |
| `tools/gt_trace.dart` | 218 | 8 | None (CLI tool) |
| `tools/compare_golden.py` | 156 | 2 | None (CLI tool) |
| `tools/compare_stage_dumps.py` | 223 | 9 | None (CLI tool) |

### Files Being CREATED (NEW)

| File | Location | Est. Lines | Depends On |
|------|----------|------------|------------|
| `pipeline_comparator.dart` (library) | `test/features/pdf/extraction/golden/` | 600-800 | `ParsedBidItem`, `StageNames`, `QualityReport`, `dart:convert`, `dart:io` |
| `pipeline_comparator.dart` (CLI) | `tools/` | 80-120 | Library above, `dart:io` |
| `report_generator.dart` | `test/features/pdf/extraction/golden/` | 500-700 | `PipelineResult`, `StageReport`, `StageNames`, `ProcessedItems`, `QualityReport`, `DocumentChecksum`, `Tesseract.version`, `dart:convert`, `dart:io` |
| `springfield_report_test.dart` | `integration_test/` | 400-500 | `ExtractionPipeline`, `PipelineConfig`, `report_generator.dart`, `pipeline_comparator.dart`, `stageToFilename`, `StageNames` |

### Files Being MODIFIED (DEPENDENT)

| File | Line | Change | Reason |
|------|------|--------|--------|
| `test/.../integration/full_pipeline_integration_test.dart` | 27 | Update import: `golden_file_matcher.dart` -> `pipeline_comparator.dart` | `golden_file_matcher.dart` deleted |
| `test/.../integration/full_pipeline_integration_test.dart` | 472-486 | Update `GoldenFileMatcher()` usage -> `PipelineComparator()` equivalent | API replacement |
| `.gitignore` | (append) | Add `test/features/pdf/extraction/reports/` | Reports directory gitignored per spec |

### Cross-Reference: `golden_file_matcher.dart` Consumers

All files importing `golden_file_matcher.dart`:
1. `test/.../golden/springfield_golden_test.dart:19` — DELETED (no migration needed)
2. `test/.../golden/springfield_benchmark_test.dart:11` — DELETED (no migration needed)
3. `test/.../golden/golden_file_matcher_test.dart:5` — DELETED (no migration needed)
4. `test/.../integration/full_pipeline_integration_test.dart:27` — **MUST UPDATE** import + usage at line 472
5. `test/.../golden/README.md` — DELETED (no migration needed)

### `stageToFilename` Map (26 entries in `stage_fixtures.dart:6`)

This map provides the definitive stage-name-to-filename mapping. The new `springfield_report_test.dart` uses the same `onStageOutput` callback mechanism but stores data in-memory for the report generator, NOT as files.

**NOT DELETED**: `stage_fixtures.dart` is still used by `generate_mp_fixtures_test.dart` and `tool/generate_springfield_fixtures.dart`.

### Key API Surface for `pipeline_comparator.dart` Migration

`full_pipeline_integration_test.dart:471-486` uses:
- `GoldenFileMatcher()` constructor
- `matcher.compare(actual, expected)` -> returns `MatchResult`
- `MatchResult.matchRate` (double 0.0-1.0)
- `MatchResult.unmatchedActual` (list)
- `MatchResult.unmatchedExpected` (list)

The new `PipelineComparator` must expose an equivalent API for this migration.
