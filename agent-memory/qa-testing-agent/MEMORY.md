# Agent Memory — QA Testing Agent

## Patterns Discovered

### PDF Test Suite Baseline (2026-03-09, post bidAmountInference fix)
- **Total PDF Tests (extraction/ suite)**: 826 passed, 0 failed
- **Pipeline Scorecard**: **68 OK | 3 LOW | 0 BUG** (72 metrics) — confirmed baseline
- **Quality score**: Springfield overall_score 0.9934, QualityStatus.autoAccept
- **Fixture items**: 131 items, $7,882,926.73 total, checksum_validation=1.0
- **Crop upscaler**: DPI-only logic (no kMinCropWidth). `computeScaleFactor` returns 1.0 at >= 600 DPI, else kTargetDpi/renderDpi capped by kMaxScaleFactor and kMaxOutputDimension.
- **kMinCropWidth=500 experiment result**: REGRESSED. Caused item 50 ("Valve & Box, 6\"") to merge → bogus "50 o1", BUG count 0→2, quality 0.993→0.918. Do NOT re-attempt without first investigating item 50 cell boundary geometry.
- **Known flutter_tester.exe lock issue**: Multiple flutter_tester.exe processes linger after test runs. Run `Stop-Process -Name 'flutter_tester' -Force` to unblock.
- Test locations: `test/features/pdf/extraction/` (contracts, golden, integration, models, ocr, pipeline, stages, shared)
- Pipeline report test: `integration_test/springfield_report_test.dart` (requires `-d windows --dart-define=SPRINGFIELD_PDF=<path>`). CLI comparison: `tools/pipeline_comparator.dart`.
- Springfield PDF path: `C:\Users\rseba\OneDrive\Desktop\864130 Springfield DWSRF Water System Improvements CTC [16-23] Pay Items.pdf`
- **3 LOW metrics**: Row Classification headers (17 vs 6 expected), B1 unitPrice 6.2%, B2 bidAmount Δ0.062 — these are stable/expected

### Grid Line Remover v3 Baseline (2026-03-12, post mask position fix)
- **Items extracted**: 35/131 (16.8%) — REGRESSION from pre-v3 baseline of 131/131
- **Quality score**: 0.793, QualityStatus.reviewFlagged
- **Checksum**: $2,138,497.40 / $7,882,926.73 GT
- **OCR elements**: 1601 (was 1625 with text protection enabled)
- **Diagnostic**: 0 excess mask pixels on all 6 pages (mask position fix confirmed working)
- **Mask coverage avg**: 3.37% (was ~25-38% excess in v1/v2)
- **Row classification**: 329 total rows, only 38 data rows (was ~200+ in pre-v3)
- **Diagnostic test**: requires `-d windows` flag — without it, rendering hangs/times out at 30min
- **Root problem**: grid removal is now working (0 excess), but downstream extraction drastically reduced. Row classifier producing only 38 data rows from 329 total (vs 131 expected). Needs investigation.

### pdfrx Migration Quality Fix (2026-03-08, RESOLVED 2026-03-09)
- **Root cause of 0.977→0.918 regression**: Item 96 (`HMA, 4EL`) had `raw_bid_amount = "$177.1 33.00"` — OCR misread `,` as `. ` (period+space). No currency rule handled embedded spaces → null bid_amount → checksum $177,135 short → checksum_validation 0.5 → quality 0.918.
- **Fix**: Added `bidAmountInference` rule to `ConsistencyChecker.applyConsistencyRules` — when `bidAmount == null && qty > 0 && unitPrice > 0` → infer `bidAmount = qty × price`.
- **New RepairType**: `bidAmountInference` added to `processed_items.dart` enum.
- **CONFIRMED**: Fixtures regenerated 2026-03-09 at 15:42/15:43. quality_score=0.9934, checksum_validation=1.0. All 131 items present, $7,882,926.73 total.
- **Items 121/123/130 are description truncations** (not numeric false positives) — bid amounts are all correct.

### Skipped Tests Pattern
TesseractInitializer tests skip when `eng.traineddata` asset not available in test environment. This is expected and acceptable - these tests would run in full integration/E2E scenarios.

### DPI Override Bug Pattern (2026-02-07)
**Symptom**: Tesseract returns "Empty page!!" despite correct DPI being set at Dart level.
**Root Cause**: Native C++ code in `packages/flusseract/src/flusseract.cpp` unconditionally overwrites `user_defined_dpi` with 70 DPI fallback in `SetPixImage()`.
**Fix**: Check if `user_defined_dpi` is set via `GetIntVariable()` before applying fallback.
**Prevention**: When adding Tesseract configuration options, ensure native FFI layer respects variable precedence (user-defined > embedded > fallback).

### Sync Engine Test Patterns (2026-03-13)
- **SyncEngine cannot be unit-tested directly** — requires a real `SupabaseClient` that can't be instantiated in tests.
- **Existing sync tests** test components in isolation: `ChangeTracker`, `ConflictResolver`, `SyncMutex`, adapters — never `SyncEngine.pushOnly()`.
- **Phase 8A pattern**: Test soft-delete routing by verifying SQLite state (change_log `operation='update'` from trigger, `deleted_at != null` on record). Use `SqliteTestHelper.getChangeLogEntries()` + `db.query()`.
- **Phase 8B pattern**: Test `_preCheckUniqueConstraint` logic with an inline injectable mirror function; test the `23505` retryable path via `ChangeTracker.markFailed()` + `hasFailedEntries()`.
- **`SyncEngineConfig.maxRetryCount = 5`** (not 3). `hasFailedEntries` returns true only when `retry_count >= 5`.
- **Test file**: `test/features/sync/engine/sync_engine_test.dart` — 29 tests, all passing as of 2026-03-13.

## Gotchas & Quirks

### Flutter Command Execution
ALWAYS use `pwsh -Command "flutter ..."` wrapper. Git Bash silently fails on Flutter commands on Windows.

### Native Plugin Rebuilds
After modifying native C++ code in `packages/flusseract/`, run `flutter clean && flutter build windows --debug` to force rebuild. The plugin is built as part of the app build, not independently.

## Architectural Decisions

### PR Verification Pattern (2026-02-08)
When verifying multiple related PRs:
1. Add model tests first (unit tests for new types like HeaderAnchor)
2. Extend existing model tests for new fields (e.g., TableRegion.headerAnchors)
3. Run incremental test suites (models → feature → services → full suite)
4. Verify implementation by reading actual code changes (Grep for method names)
5. Run full regression suite at end (all PDF tests: 1431 tests)

## Frequently Referenced Files

### Test Directories
- `test/features/pdf/extraction/stages/` - V2 pipeline stage tests
- `test/features/pdf/extraction/ocr/` - OCR engine and preprocessing tests
- `test/features/pdf/extraction/models/` - Model serialization and validation tests
- `test/features/pdf/extraction/contracts/` - Stage-to-stage contract tests
- `test/features/pdf/extraction/pipeline/` - Pipeline orchestration tests
- `test/features/pdf/extraction/integration/` - End-to-end extraction flows
- `test/features/pdf/extraction/golden/` - Golden file tests
