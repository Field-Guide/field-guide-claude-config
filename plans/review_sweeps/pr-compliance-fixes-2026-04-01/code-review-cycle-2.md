# Code Review — Cycle 2

**Verdict**: REJECT

## Findings

### [HIGH] DriverSetup.configure() passes wrong type to TestPhotoService
- **Location**: Phase 5, Sub-phase 5.3, Step 5.3.1
- **Issue**: Plan passes `baseDeps.core.photoService` (PhotoService) but TestPhotoService takes PhotoRepository. Actual: `TestPhotoService(baseDeps.feature.photoRepository)`
- **Fix**: Use `baseDeps.feature.photoRepository`

### [HIGH] DriverSetup.configure() calls AppDependencies.copyWith with nonexistent parameter
- **Location**: Phase 5, Sub-phase 5.3, Step 5.3.1
- **Issue**: Plan calls `baseDeps.copyWith(core: patchedCore)` but copyWith only accepts `PhotoService? photoService`
- **Fix**: Use `baseDeps.copyWith(photoService: testPhotoService)`

### [HIGH] DriverSetup.configure() constructs DriverServer with nonexistent API
- **Location**: Phase 5, Sub-phase 5.3, Step 5.3.1
- **Issue**: Plan uses `DriverServer(deps: patchedDeps)` but DriverServer takes individual named parameters (testPhotoService, photoRepository, documentRepository, syncOrchestrator, databaseService, projectLifecycleService)
- **Fix**: Match actual constructor from main_driver.dart:50-57, or keep DriverServer construction inline

### [LOW] Sub-phase numbering gap: 4.1 jumps to 4.3
- **Location**: Phase 4
- **Issue**: No Sub-phase 4.2 after onboarding merge. Cosmetic.
- **Fix**: Renumber phases 4.3→4.2 through 4.9→4.8

### [LOW] avoid_raw_database_delete.dart update would create duplicate
- **Location**: Phase 2, Sub-phase 2.3, Step 2.3.2
- **Issue**: Line 29 already has core/driver path. Updating line 28 to same creates duplicate.
- **Fix**: Remove line 28 instead of updating it.
