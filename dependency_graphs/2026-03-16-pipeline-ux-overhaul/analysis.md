# Dependency Graph: Pipeline UX Overhaul

## Direct Changes

### PR1: Architecture — Background Isolate + Progress UX + Project Save

#### 1. Tesseract Re-init Fix
| File | Symbol | Lines | Change |
|------|--------|-------|--------|
| `packages/flusseract/lib/tesseract.dart` | `setPageSegMode()` | 68-71 | Guard: skip if mode unchanged |
| `packages/flusseract/lib/tesseract.dart` | `setWhiteList()` | 83-85 | No change needed (uses `setVariable` hot-path) |
| `lib/features/pdf/services/extraction/ocr/tesseract_engine_v2.dart` | `recognizeCrop()` | 94-139 | Track last PSM/whitelist, skip redundant calls |
| `lib/features/pdf/services/extraction/ocr/tesseract_engine_v2.dart` | `_getTesseractInstance()` | 248-264 | No change needed (creates once) |

**Current `setPageSegMode()`:**
```dart
void setPageSegMode(PageSegMode mode) {
    _pageSegMode = mode;
    _needsInit = true;  // BUG: unconditional, forces Init() every time
}
```

**Current `recognizeCrop()` calls:**
```dart
tess.setPageSegMode(cfg.pageSegMode);  // Called per cell crop
tess.setWhiteList(cfg.whitelist ?? ''); // Called per cell crop
```

#### 2. Background Isolate — New Files
| File | Type | Purpose |
|------|------|---------|
| `lib/features/pdf/services/extraction/runner/extraction_job.dart` | CREATE | Sealed class: BidItemExtractionJob, MpExtractionJob |
| `lib/features/pdf/services/extraction/runner/extraction_result.dart` | CREATE | ExtractionResult wrapper for isolate boundary |
| `lib/features/pdf/services/extraction/runner/extraction_job_runner.dart` | CREATE | Worker isolate management, SendPort/ReceivePort, progress stream |

#### 2. Background Isolate — Modified Files
| File | Symbol | Lines | Change |
|------|--------|-------|--------|
| `lib/features/pdf/presentation/helpers/pdf_import_helper.dart` | `importFromPdf()` | 11-142 | Submit job to ExtractionJobRunner instead of direct PdfImportService call |
| `lib/features/pdf/presentation/helpers/mp_import_helper.dart` | `importMeasurementPayment()` | 17-80 | Submit job to ExtractionJobRunner, add dispose() call |
| `lib/features/pdf/services/pdf_import_service.dart` | `importBidSchedule()` | 128-174 | Adapt for isolate use (receive tessdata path as param) |
| `lib/main.dart` | `_runApp()` | 104+ | Register ExtractionJobRunner as provider |

#### 3. Progress Reporting — Modified Files
| File | Symbol | Lines | Change |
|------|--------|-------|--------|
| `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart` | `_runExtractionStages()` | 371-772 | Replace hardcoded `totalStages=15` with dynamic count; emit per-page/per-cell progress |
| `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart` | `extract()` | 220-366 | Pass new ExtractionProgress model to callback |
| `lib/features/pdf/services/pdf_import_service.dart` | `ExtractionStage` enum | 78-109 | Add `analyzingDocument`; update descriptions |
| `lib/features/pdf/services/pdf_import_service.dart` | `_mapStageToEnum()` | 177-200 | Map new stage names |
| `lib/features/pdf/services/extraction/stages/text_recognizer_v2.dart` | `recognize()` | 168-330 | Add onProgress callback for per-page/per-cell |
| `lib/features/pdf/services/extraction/stages/page_renderer_v2.dart` | `render()` | 107-174 | Add onProgress callback for per-page |
| `lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart` | `preprocess()` | 97-180 | Add onProgress callback for per-page |
| `lib/features/pdf/services/extraction/stages/grid_line_detector.dart` | `detect()` | 25-137 | Add onProgress callback for per-page |
| `lib/features/pdf/services/extraction/stages/grid_line_remover.dart` | `remove()` | 57-315 | Add onProgress callback for per-page |

#### 4. UI — Bottom Banner — New Files
| File | Type | Purpose |
|------|------|---------|
| `lib/features/pdf/presentation/widgets/extraction_banner.dart` | CREATE | Slim banner widget (~48dp) with progress |
| `lib/features/pdf/presentation/widgets/extraction_detail_sheet.dart` | CREATE | Bottom sheet with full stage breakdown + cancel |

#### 4. UI — Bottom Banner — Modified Files
| File | Symbol | Lines | Change |
|------|--------|-------|--------|
| `lib/core/router/app_router.dart` | `ScaffoldWithNavBar.build()` | 562-674 | Add ExtractionBanner overlay above nav bar |
| `lib/features/pdf/presentation/widgets/pdf_import_progress_dialog.dart` | whole file | 9-130 | Deprecate (replaced by banner) |
| `lib/features/pdf/presentation/widgets/pdf_import_progress_manager.dart` | whole file | 20-74 | Deprecate (replaced by ExtractionJobRunner) |

#### 5. Project Save Flow Fix
| File | Symbol | Lines | Change |
|------|--------|-------|--------|
| `lib/features/projects/presentation/screens/project_setup_screen.dart` | `_saveProject()` | 749-878 | After new project save: `selectProject()` + `goNamed('dashboard')` |

**Reference pattern (project_list_screen.dart:511-514):**
```dart
projectProvider.selectProject(project.id);
context.goNamed('dashboard');
```

**Current behavior (project_setup_screen.dart:865-868):**
```dart
if (isEditing) {
  _handleBackNavigation();
}
// For new projects, stay on screen so user can add locations etc.
```

#### 6. Security Fixes
| File | Lines | Change |
|------|-------|--------|
| `android/app/src/main/AndroidManifest.xml` | 28 | Add `android:allowBackup="false"` to `<application>` |
| `android/app/src/main/AndroidManifest.xml` | 20, 26 | Move MANAGE_EXTERNAL_STORAGE + QUERY_ALL_PACKAGES to debug manifest |
| `android/app/src/debug/AndroidManifest.xml` | 1-7 | Add the moved permissions |
| `lib/core/logging/logger.dart` | `_tryAppLogFallback()` 639-659 | Replace `Directory.systemTemp` with `getTemporaryDirectory()` |

---

### PR2: Logger Migration

#### 7A. Release-Safe File Logging
| File | Symbol | Lines | Change |
|------|--------|-------|--------|
| `lib/core/logging/logger.dart` | `_log()` | 482-530 | Add release filter before file write |
| `lib/core/logging/logger.dart` | `_isSensitiveKey()` | 764-773 | Add construction-domain fields: filename, project_name, contractor_name, location_name, site_address, _address, _location |
| `lib/core/logging/logger.dart` | `_scrubSensitive()` | 775-796 | Apply to file transport in release mode |
| `lib/core/logging/logger.dart` | `_sendHttp()` | 678-748 | Fix scrub ordering: _scrubSensitive() before truncation |
| `lib/core/logging/logger.dart` | `init()` / `_doInit()` | 236-345 | Add log retention: delete folders >14 days, cap 50MB |

#### 7B. Migrate 22 DebugLogger Files → Logger
| File | Import Change |
|------|--------------|
| `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart` | DebugLogger.pdf → Logger.pdf |
| `lib/features/pdf/services/extraction/stages/post_processor_v2.dart` | DebugLogger → Logger |
| `lib/features/pdf/services/pdf_import_service.dart` | DebugLogger → Logger |
| `lib/features/pdf/presentation/helpers/pdf_import_helper.dart` | DebugLogger → Logger |
| `lib/features/pdf/services/extraction/stages/grid_line_remover.dart` | DebugLogger → Logger |
| `lib/features/sync/engine/sync_engine.dart` | DebugLogger.sync → Logger.sync |
| `lib/features/sync/application/sync_orchestrator.dart` | DebugLogger → Logger |
| `lib/features/sync/application/sync_lifecycle_manager.dart` | DebugLogger → Logger |
| `lib/features/sync/engine/change_tracker.dart` | DebugLogger → Logger |
| `lib/features/sync/engine/orphan_scanner.dart` | DebugLogger → Logger |
| `lib/features/sync/engine/integrity_checker.dart` | DebugLogger → Logger |
| `lib/core/database/database_service.dart` | DebugLogger.db → Logger.db |
| `lib/core/database/schema_verifier.dart` | DebugLogger → Logger |
| `lib/services/soft_delete_service.dart` | DebugLogger → Logger |
| `lib/services/startup_cleanup_service.dart` | DebugLogger → Logger |
| `lib/features/sync/engine/storage_cleanup.dart` | DebugLogger → Logger |
| `lib/features/projects/data/repositories/project_repository.dart` | DebugLogger → Logger |
| `lib/features/projects/data/datasources/local/project_local_datasource.dart` | DebugLogger → Logger |
| `lib/features/quantities/presentation/providers/bid_item_provider.dart` | DebugLogger → Logger |
| `lib/features/quantities/utils/budget_sanity_checker.dart` | DebugLogger → Logger |
| `lib/shared/datasources/generic_local_datasource.dart` | DebugLogger → Logger |

**Note:** 21 files found (spec says 22 — may have been fixed during prior sessions). Count verified via `grep -r DebugLogger lib/` excluding logger.dart and debug_logger.dart itself.

#### 7C. Migrate 49 debugPrint Files → Logger
49 files use `debugPrint()` directly. Each gets mapped to appropriate Logger category.

#### 7D. Add Logging to 16 Dark Pipeline Stages
Critical: DocumentQualityProfiler, RowClassifierV3, RowParserV3, FieldConfidenceScorer, ItemDeduplicator
Important: CellExtractorV2, ColumnDetectorV2, RegionDetectorV2, NumericInterpreter, ElementValidator
Remaining: HeaderDetector, RowMerger, ValueNormalizer, AnchorCorrector, ConsistencyChecker, OcrEngineV2/OcrTextExtractor

#### 7E. Delete Deprecated Wrappers
| File | Action |
|------|--------|
| `lib/core/logging/debug_logger.dart` | DELETE |
| `lib/core/logging/app_logger.dart` | DELETE (only used by logger.dart comments) |

---

## Dependent Files (Callers/Consumers — 2+ levels)

| File | Dependency | Impact |
|------|-----------|--------|
| `lib/features/projects/presentation/screens/project_setup_screen.dart` | Calls `PdfImportHelper.importFromPdf()` at line 734 | Indirectly affected by import helper changes |
| `lib/features/pdf/presentation/screens/pdf_import_preview_screen.dart` | Receives `PdfImportResult` from helper | No change if result format preserved |
| `lib/features/pdf/presentation/screens/mp_import_preview_screen.dart` | Receives M&P result | No change if result format preserved |
| `lib/features/pdf/services/mp/mp_extraction_service.dart` | M&P pipeline (parallel to bid) | Needs isolate integration |

## Test Files

| Test File | Tests |
|-----------|-------|
| `test/features/pdf/extraction/pipeline/extraction_pipeline_test.dart` | Pipeline progress callbacks, stage branching |
| `test/features/pdf/extraction/pipeline/re_extraction_loop_test.dart` | Re-extraction loop |
| `test/features/pdf/presentation/widgets/pdf_import_progress_dialog_test.dart` | Progress dialog widget (DEPRECATE) |
| `test/features/pdf/presentation/widgets/pdf_import_progress_manager_test.dart` | Progress manager (DEPRECATE) |
| `integration_test/springfield_report_test.dart` | Uses ExtractionPipeline directly |
| `integration_test/cell_crop_diagnostic_test.dart` | Uses ExtractionPipeline directly |
| `test/core/logging/` | Logger tests (33 existing tests) |

## Data Flow Diagram

```
User taps "Import PDF"
    │
    ▼
PdfImportHelper / MpImportHelper
    │ ← picks file, shows background warning dialog
    │
    ▼
ExtractionJobRunner (NEW)  ← provider registered in main.dart
    │ ← spawns worker isolate lazily
    │ ← sends job via SendPort
    │
    ├── Worker Isolate ──────────────────────────────────┐
    │   PdfImportService.importBidSchedule()             │
    │       │                                            │
    │       ▼                                            │
    │   ExtractionPipeline.extract()                     │
    │       │                                            │
    │       ├── Stage 0: DocumentQualityProfiler         │
    │       ├── Stage 2B-i: PageRendererV2               │
    │       ├── Stage 2B-ii: ImagePreprocessorV2         │
    │       ├── Stage 2B-ii.5: GridLineDetector          │
    │       ├── Stage 2B-ii.6: GridLineRemover           │
    │       ├── Stage 2B-iii: TextRecognizerV2 ← Tesseract (FFI)
    │       ├── Stage 3: ElementValidator                │
    │       ├── Stage 4A-E: Classification + Parsing     │
    │       └── Stage 5-6: Post-processing + Quality     │
    │                                                    │
    │   ← progress via SendPort ─────────────────────────┘
    │
    ▼
ExtractionBanner (NEW) ← root-level overlay in ScaffoldWithNavBar
    │ ← listens to ExtractionJobRunner state
    │ ← shows stage + progress + elapsed time
    │ ← tappable → ExtractionDetailSheet
    │
    ▼
On complete: "Import complete! Tap to review"
    │ ← navigates to import-preview / mp-import-preview
```

## Blast Radius Summary

| Category | Count |
|----------|-------|
| Direct (create) | 5 new files |
| Direct (modify) | ~20 files (PR1) |
| Direct (modify) | ~75 files (PR2 — logger migration) |
| Direct (deprecate) | 2 files (progress dialog/manager) |
| Direct (delete) | 2 files (debug_logger, app_logger) |
| Dependent | 4 files |
| Test (modify) | 4 test files |
| Test (new) | 3+ test files (job runner, banner, progress model) |
| Test (deprecate) | 2 test files (progress dialog/manager tests) |
