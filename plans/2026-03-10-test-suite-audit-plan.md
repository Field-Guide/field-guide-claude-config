# PDF Extraction Pipeline Test Suite Audit & Overhaul

**Created**: 2026-03-10 | **Status**: READY FOR IMPLEMENTATION

## Context

9 agents reviewed the entire pipeline test suite (benchmark, stage trace, golden/GT trace, fixture generator, GT trace tool, and infrastructure). The renderer was migrated from pdfx to pdfrx (returns BGRA raw pixels instead of PNG). Tesseract upgraded to 5.5.2 on Android — confirmed working with 130 items, quality 0.918, matching Windows exactly.

**Goal**: Fix all broken/outdated tests, expand GT trace to all 131 items, create integrated test runner with dated output, then run 3-way comparison (Windows fixtures vs S25 APK vs S25 flutter-run).

---

## BROKEN (Must Fix)

| # | File | Line(s) | Issue | Fix |
|---|------|---------|-------|-----|
| B1 | `benchmark_test.dart` | 82 | pdfrx needs `path_provider` mock — `getTemporaryDirectory` throws `MissingPluginException`. All configs produce 0 items. | Set `pdfrx.Pdfrx.getCacheDirectory = () => Directory.systemTemp.path;` in `setUpAll` |
| B2 | `benchmark_test.dart` | 125 | `enhancedPreprocess` config field is dead code — nothing consumes it | Remove variant or wire into pipeline |
| B3 | `benchmark_results.json` | entire | Checked-in file with all zeros — misleading | Delete and `.gitignore` |
| B4 | `golden_test.dart` | 524-548 | Bogus detection patterns miss "94 Boy" — reports 0 bogus when 1 exists | Add `RegExp(r'^\d+\s+[A-Za-z]')` pattern |
| B5 | `golden_test.dart` | 345-382 | 79.8% unit accuracy printed but never asserted — regressions invisible | Add `expect(unitAccuracy, >= 0.75)` floor |
| B6 | `rendering_diagnostic_test.dart` | 78 | Writes raw BGRA bytes to `.png` — corrupt output | Use `entry.value.toPngBytes()` |

## OUTDATED (Stale Comments & Values)

| # | File:Line | Says | Should Say |
|---|-----------|------|------------|
| O1 | `golden_test.dart:9` | "131 items with quality ~0.98" | "130 items with quality ~0.918" |
| O2 | `golden_test.dart:419` | "currently 16 extra/bogus items" | "currently 1 extra/bogus item" |
| O3 | `golden_test.dart:449` | "delta is -128 (3 vs 131)" | "delta is -1 (130 vs 131)" |
| O4 | `golden_test.dart:591` | "score is ~0.570" | "score is ~0.918" |
| O5 | `golden_test.dart:594` | threshold `>= 0.40` | tighten to `>= 0.85` (actual is 0.918) |
| O6 | `stage_trace.dart:2404` | "native used 6" | Remove — no "native" path post-pdfrx |
| O7 | `stage_trace.dart:2444` | "currently produces low match rate" | Match rate is 93%+ |
| O8 | `fixture_generator.dart:204` | "14 stages now" + `>= 10` | Pipeline emits ~27 stages; tighten to `>= 20` |
| O9 | `golden_test.dart:528` | `Pice Bids` regex | Typo for `Price Bids`? |

## CODE QUALITY

| # | Issue | Fix |
|---|-------|-----|
| CQ1 | `stage_trace_diagnostic_test.dart` is 4,876 lines | Split: stages, GT trace, scorecard, upstream failure |
| CQ2 | Scorecard `tableRows` is 1,360 lines of hand-built arrays | Refactor to builder pattern |
| CQ3 | Benchmark uses one `test()` with for-loop | Use `group()` + individual `test()` per config |
| CQ4 | `_firstOrNull` extension reimplements Dart 3.0 built-in | Replace with SDK `.firstOrNull` |
| CQ5 | `GoldenFileMatcher` — no LSUM/LS unit normalization | `compare_golden.py` normalizes but Dart matcher doesn't — 26 false unit mismatches |
| CQ6 | `gt_trace.dart:57` — hardcoded `<= 131` loop | Use `gtByNum.keys` to iterate dynamically |
| CQ7 | `gt_trace.dart` — no unit accuracy summary stat | Add "Unit accuracy: X% (N/131)" to summary |

## GT TRACE GAPS

| # | Gap | Fix |
|---|-----|-----|
| GT1 | Only traces 10 of 131 items (hardcoded list) | Loop all 131 GT items; compact for PASS, verbose for deltas |
| GT2 | Missing stages: row merging (4A.5), numeric interpretation (4D.5), field confidence (4E.5), post-processing sub-stages | Add trace points for all fixture stages |
| GT3 | No consolidated summary table | Add: `item# | 4A | 4D | 4E | 5 | price_delta | amount_delta | verdict` |
| GT4 | No backward trace for missing items | Trace backward to find disappearance stage |
| GT5 | No field-level delta reporting | Compare desc/unit/qty/price/amount vs GT at each stage |

## TEST INTEGRATION PLAN

Create `springfield_full_report_test.dart` — one file, one command, dated output.

Runs in sequence:
1. Stage Trace Diagnostics (fixture-based)
2. Full GT Item Trace — all 131 items (fixture-based)
3. Pipeline Scorecard (fixture-based)
4. Golden Regression Tests with assertions (fixture-based)
5. GT Comparison with field accuracy (fixture-based)

Output: `test/features/pdf/extraction/reports/springfield_report_YYYY-MM-DD_HHMMSS.txt`
Run: `pwsh -Command "flutter test test/.../golden/springfield_full_report_test.dart"`

Report includes header: date, git hash, Tesseract version, platform.

## REAL PIPELINE BUGS (Not Test Issues)

The 2 BUG failures in stage trace are real:
1. **Row Parsing Bogus**: Item 95's row misclassified as `descContinuation` of item 94 → produces bogus "94 Boy" (merged items 94+95). Fix is in Stage 4A row classifier.
2. **Checksum FAIL**: Downstream of #1 — items 94 ($253,500) + 95 ($26,656) = $280,156 missing from total. Fix #1 fixes both.

## KEY FILES

| File | Classification | Notes |
|------|---------------|-------|
| `golden/springfield_golden_test.dart` | FIXTURE-based | Runs in `flutter test`, all pass |
| `golden/stage_trace_diagnostic_test.dart` | FIXTURE-based | Runs in `flutter test`, 2 BUG failures (real bugs) |
| `golden/springfield_benchmark_test.dart` | LIVE PIPELINE | Needs pdfrx fix (B1) to run in `flutter test` |
| `golden/golden_file_matcher.dart` | Helper | Pure Dart, no renderer deps |
| `integration_test/generate_golden_fixtures_test.dart` | LIVE PIPELINE | Needs `-d windows`, generates all fixtures |
| `integration_test/rendering_diagnostic_test.dart` | LIVE PIPELINE | BGRA bug (B6) |
| `tools/gt_trace.dart` | CLI tool | Standalone `dart run`, no test framework |

## CROSS-PLATFORM CONVERGENCE (Confirmed 2026-03-10)

| Metric | Windows | S25 APK | S25 flutter-run |
|--------|---------|---------|-----------------|
| Tesseract | 5.5.x (vcpkg) | 5.5.2 | 5.5.2 |
| Items | 130 | 130 | 130 |
| Elements | 1249 | 1249 | 1249 |
| Quality | 0.918 | 0.918 | 0.918 |
| Checksum | $7,602,768.73 | $7,602,768.73 | $7,602,768.73 |
| Repairs | 8 | 8 | 8 |
