# Clean Architecture Refactor — Phase 7: Remaining Features + Cleanup

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Add domain layer scaffolding for dashboard, settings, weather, toolbox, pdf. Fix trash_screen layer violation. Fix remaining `catch(_)` blocks. Dead code removal. Final verification.

---

## Phase 7: Remaining Features + Cleanup

### Sub-phase 7.1: Settings — TrashRepository + Fix Layer Violation
**Files:**
- Create: `lib/features/settings/data/repositories/trash_repository.dart`
- Create: `lib/features/settings/domain/domain.dart` (barrel)
- Modify: `lib/features/settings/presentation/screens/trash_screen.dart`
- Modify: `lib/features/settings/settings.dart` (barrel update)
**Agent:** `backend-data-layer-agent`

#### Step 7.1.1: Create TrashRepository
Create `lib/features/settings/data/repositories/trash_repository.dart` that encapsulates the raw DB queries currently in `trash_screen.dart`.

The repository must expose:
```dart
class TrashRepository {
  final DatabaseService _dbService;
  TrashRepository(this._dbService);

  /// Fetch all soft-deleted records grouped by table name.
  /// [tables] — which tables to scan.
  /// [adminMode] — if false, filters by [userId] (deleted_by).
  Future<Map<String, List<Map<String, dynamic>>>> getDeletedItems({
    required Map<String, String> tables,
    required bool adminMode,
    String? userId,
  });
}
```

**WHY:** `trash_screen.dart:54` and `:68` both call `_dbService.database` directly and run raw `database.query()` from the presentation layer. This violates the architecture rule: "Raw SQL in presentation layer → Move to repository/datasource layer."

Implementation details (extracted from `trash_screen.dart:65-99`):
- For each table key in `tables`, run `database.query(table, where: ..., orderBy: 'deleted_at DESC')`
- Admin mode: `where = 'deleted_at IS NOT NULL'`
- Non-admin mode: `where = 'deleted_at IS NOT NULL AND deleted_by = ?'` with `whereArgs: [userId]`
- Wrap each table query in `try/catch (e) { Logger.db(...) }` — tables may not exist
- Return `Map<String, List<Map<String, dynamic>>>` (only non-empty results)

#### Step 7.1.2: Update trash_screen.dart to use TrashRepository
In `lib/features/settings/presentation/screens/trash_screen.dart`:

1. Remove `import 'package:construction_inspector/core/database/database_service.dart';`
2. Add `import 'package:construction_inspector/features/settings/data/repositories/trash_repository.dart';`
3. Replace field `final _dbService = DatabaseService();` with `late final TrashRepository _trashRepository;`
4. In `_initService()` (line 53-57): replace the `_dbService.database` call with creating a `TrashRepository(DatabaseService())` and assigning to `_trashRepository`. Remove the `SoftDeleteService(database)` init that depends on raw DB — instead get the database from DatabaseService and pass to SoftDeleteService as before, but through the repository or keep SoftDeleteService init separate.

   Revised `_initService()`:
   ```dart
   Future<void> _initService() async {
     final dbService = DatabaseService();
     _trashRepository = TrashRepository(dbService);
     final database = await dbService.database;
     _softDeleteService = SoftDeleteService(database);
     _loadDeletedItems();
   }
   ```

5. In `_loadDeletedItems()` (lines 65-107): replace the entire raw DB query loop with:
   ```dart
   Future<void> _loadDeletedItems() async {
     setState(() => _isLoading = true);
     final auth = context.read<AuthProvider>();
     final grouped = await _trashRepository.getDeletedItems(
       tables: _tableLabels,
       adminMode: auth.isAdmin,
       userId: auth.userId,
     );
     if (mounted) {
       setState(() {
         _groupedItems = grouped;
         _isLoading = false;
       });
     }
   }
   ```

**WHY:** Eliminates both layer violations (lines 54 and 68). The presentation layer now only talks to a repository, never to raw DB.

#### Step 7.1.3: Create settings domain barrel
Create `lib/features/settings/domain/domain.dart`:
```dart
// Settings domain layer — currently empty (admin use cases stay in provider,
// theme is pure UI state). Placeholder for future use cases.
```

Update `lib/features/settings/settings.dart` barrel to export `domain/domain.dart`.

**WHY:** Every feature gets a `domain/` directory per the Clean Architecture spec, even if initially empty.

---

### Sub-phase 7.2: Dashboard + Toolbox — Empty Domain Scaffolding
**Files:**
- Create: `lib/features/dashboard/domain/domain.dart`
- Create: `lib/features/toolbox/domain/domain.dart`
- Modify: `lib/features/dashboard/dashboard.dart` (barrel update)
- Modify: `lib/features/toolbox/toolbox.dart` (barrel update)
**Agent:** `backend-data-layer-agent`

#### Step 7.2.1: Create dashboard domain barrel
Create `lib/features/dashboard/domain/domain.dart`:
```dart
// Dashboard domain layer — presentation-only feature, reads from other
// feature providers. Placeholder for future dashboard-specific use cases.
```

Update `lib/features/dashboard/dashboard.dart` to export `domain/domain.dart`.

#### Step 7.2.2: Create toolbox domain barrel
Create `lib/features/toolbox/domain/domain.dart`:
```dart
// Toolbox domain layer — hub screen only, delegates to calculator/forms/gallery/todos.
// Placeholder for future cross-feature use cases.
```

Update `lib/features/toolbox/toolbox.dart` to export `domain/domain.dart`.

**WHY:** Future-proofing per spec. Empty domain dirs are low-cost markers that every feature follows the Clean Architecture pattern.

---

### Sub-phase 7.3: Weather — Domain Interface
**Files:**
- Create: `lib/features/weather/domain/domain.dart`
- Create: `lib/features/weather/domain/weather_service_interface.dart`
- Modify: `lib/features/weather/services/weather_service.dart`
- Modify: `lib/features/weather/weather.dart` (barrel update)
**Agent:** `backend-data-layer-agent`

#### Step 7.3.1: Create WeatherServiceInterface
Create `lib/features/weather/domain/weather_service_interface.dart`:
```dart
import '../services/weather_service.dart';

/// Domain contract for weather data retrieval.
/// Allows substitution of mock implementations in tests.
abstract class WeatherServiceInterface {
  Future<WeatherData?> fetchWeatherForCurrentLocation(DateTime date);
  Future<WeatherData?> fetchWeather(double lat, double lon, DateTime date);
}
```

**WHY:** WeatherService has concrete dependencies on `http`, `geolocator`, and test mode config. An interface allows test doubles without the `TestModeConfig` global flag pattern.

#### Step 7.3.2: Implement the interface on WeatherService
In `lib/features/weather/services/weather_service.dart`, add `implements WeatherServiceInterface` to the `WeatherService` class declaration (line 26):

Change:
```dart
class WeatherService {
```
To:
```dart
class WeatherService implements WeatherServiceInterface {
```

No other changes needed — `WeatherService` already has the matching method signatures.

#### Step 7.3.3: Create weather domain barrel
Create `lib/features/weather/domain/domain.dart`:
```dart
export 'weather_service_interface.dart';
```

Update `lib/features/weather/weather.dart` to export `domain/domain.dart`.

---

### Sub-phase 7.4: PDF — Domain Scaffolding
**Files:**
- Create: `lib/features/pdf/domain/domain.dart`
- Modify: `lib/features/pdf/pdf.dart` (barrel update)
**Agent:** `pdf-agent`

#### Step 7.4.1: Create pdf domain barrel
Create `lib/features/pdf/domain/domain.dart`:
```dart
// PDF domain layer — extraction pipeline is already properly layered in services/.
// ExtractionJobRunner stays in services (it IS the domain logic).
// Placeholder for future extraction use case abstractions.
```

Update `lib/features/pdf/pdf.dart` to export `domain/domain.dart`.

**WHY:** PDF's `ExtractionJobRunner` (17,360 bytes) and pipeline stages are already properly layered in `services/`. No refactoring needed — just the domain directory marker. `catch(_)` fixes in PDF extraction stages are explicitly OUT OF SCOPE per spec.

---

### Sub-phase 7.5: Fix Remaining `catch(_)` Blocks
**Files:**
- Modify: `lib/services/soft_delete_service.dart` (lines 108, 121, 142, 511)
- Modify: `lib/services/image_service.dart` (lines 155, 174, 188)
- Modify: `lib/shared/services/preferences_service.dart` (line 130)
- Modify: `lib/shared/utils/field_formatter.dart` (lines 56, 60)
- Modify: `lib/core/config/config_validator.dart` (line 90)
- Modify: `lib/core/driver/driver_server.dart` (lines 194, 253, 568, 587, 594, 628, 1347, 1572, 1693)
- Modify: `lib/features/auth/presentation/screens/pending_approval_screen.dart` (lines 94, 113)
- Modify: `lib/features/settings/presentation/screens/trash_screen.dart` (lines 96, 284, 298) — if any remain after 7.1
**Agent:** `backend-data-layer-agent`

#### Step 7.5.1: Fix pattern — convert `catch(_)` to `catch(e)` with Logger
For every `catch(_)` in the files listed above, apply this transformation:

**Pattern A** — catch that silently swallows (most cases):
```dart
// BEFORE
} catch (_) {
  // comment or empty
}

// AFTER
} catch (e) {
  Logger.<category>('[ClassName] <method> error: $e');
}
```

**Pattern B** — catch that returns a fallback value (field_formatter, config_validator, preferences_service):
```dart
// BEFORE
} catch (_) {
  return null;  // or return false, etc.
}

// AFTER
} catch (e) {
  Logger.log('[ClassName] <method> parse error: $e', level: 'WARN');
  return null;
}
```

**Pattern C** — nested catch in image_service (lines 155, 174, 188) where the catch wraps a Logger call:
```dart
// These are `try { Logger.photo(...) } catch (_) {}` — the Logger call itself is wrapped.
// Convert to: `try { Logger.photo(...) } catch (e) { /* Logger failed, no safe fallback */ }`
// These are acceptable as-is since they're guarding against Logger failures.
// SKIP these — they are catch-around-logger patterns, not swallowed errors.
```

**Logger category mapping:**
| File | Logger category |
|------|----------------|
| `soft_delete_service.dart` | `Logger.db()` |
| `image_service.dart` | SKIP (catch-around-logger) |
| `preferences_service.dart` | `Logger.log(..., level: 'WARN')` |
| `field_formatter.dart` | `Logger.log(..., level: 'WARN')` |
| `config_validator.dart` | `Logger.log(..., level: 'WARN')` |
| `driver_server.dart` | `Logger.log()` |
| `pending_approval_screen.dart` | `Logger.auth()` |
| `trash_screen.dart` | Already fixed in 7.1 (repository handles logging) |

**WHY:** Architecture anti-pattern rule: "`catch(_)` without logging — Silently swallows errors, makes debugging impossible." Every catch must log or have an explicit documented reason.

**IMPORTANT:** For `field_formatter.dart` lines 56 and 60 (the nested date parsing catch blocks), these are parse-fallback patterns. Add `Logger.log` only to the **outer** catch. The inner `catch(_)` on `DateTime.parse` fallback is acceptable since the outer catch already handles the failure path. However, for consistency, convert both to `catch (e)` and log only the outer one.

**IMPORTANT:** For `driver_server.dart` — this file has 9 `catch(_)` blocks. Many are in test-driver HTTP handler code. Apply the same pattern but use `Logger.log('[DriverServer] ...')`. Since this is test infrastructure, logging is still valuable for debugging E2E test failures.

#### Step 7.5.2: Add Logger import where missing
Files that may not already import Logger:
- `lib/shared/utils/field_formatter.dart` — check and add `import 'package:construction_inspector/core/logging/logger.dart';`
- `lib/core/config/config_validator.dart` — check and add import
- `lib/features/auth/presentation/screens/pending_approval_screen.dart` — check and add import

**NOTE:** `soft_delete_service.dart` and `driver_server.dart` likely already import Logger. Verify before adding duplicates.

---

### Sub-phase 7.6: Dead Code Removal
**Files:**
- Modify: `lib/main.dart` — remove unused imports (audit after phases 1-6 changes)
- Any files modified in phases 1-6 that have leftover unused imports
**Agent:** `backend-data-layer-agent`

#### Step 7.6.1: Run flutter analyze to find dead code
```
pwsh -Command "flutter analyze"
```

Review output for:
- `unused_import` warnings in any modified files
- `unused_local_variable` warnings
- `dead_code` warnings

#### Step 7.6.2: Fix all analyzer warnings from phase 1-6 changes
For each warning, remove the unused import/variable/code.

**IMPORTANT:** Do NOT touch files that were not modified in this refactor. Only clean up dead code introduced or exposed by the refactoring work.

#### Step 7.6.3: Verify main.dart state
After phases 1-6, `main.dart` should have been simplified. If `_runApp()` body and `ConstructionInspectorApp` constructor still have 37+ parameters, that is expected — main.dart simplification was a Phase 1 aspiration, not a hard requirement. Document current state.

**NOTE:** `main.dart` is currently 731 lines with 37 constructor params on `ConstructionInspectorApp`. Full simplification (service locator pattern) is a separate refactor. Do not attempt here.

---

### Sub-phase 7.7: Final Verification Sweep
**Files:** All modified files from phases 1-7
**Agent:** `qa-testing-agent`

#### Step 7.7.1: Run static analysis
```
pwsh -Command "flutter analyze"
```
Must pass with zero errors. Warnings are acceptable only if pre-existing (not introduced by this refactor).

#### Step 7.7.2: Run test suite
```
pwsh -Command "flutter test"
```
All tests must pass.

#### Step 7.7.3: Verify success criteria checklist
Run these verification checks:

1. **Zero `Supabase.instance.client` in presentation layer:**
   Search `lib/**/presentation/` for `Supabase.instance.client` — must return zero hits.

2. **Zero raw `dbService.database` in presentation layer:**
   Search `lib/**/presentation/` for `dbService.database` or `_dbService.database` — must return zero hits.

3. **Every feature has `domain/` directory:**
   Verify these directories exist:
   - `lib/features/dashboard/domain/`
   - `lib/features/settings/domain/`
   - `lib/features/weather/domain/`
   - `lib/features/toolbox/domain/`
   - `lib/features/pdf/domain/`
   - (Plus any from earlier phases: sync already has one)

4. **Zero `catch(_)` in refactored files (sync/pdf excluded):**
   Search all files modified in this phase for `catch (_)` — must return zero hits (excluding `lib/features/sync/` and `lib/features/pdf/services/extraction/`).

5. **`flutter analyze` clean:**
   Already verified in 7.7.1.

6. **`flutter test` passes:**
   Already verified in 7.7.2.

#### Step 7.7.4: Document any deferred items
If any success criteria cannot be met, document the specific items and why in a comment block at the top of this plan file. Do NOT silently skip criteria.

---

## Dispatch Groups

| Group | Sub-phases | Parallelizable | Notes |
|-------|-----------|----------------|-------|
| A | 7.1, 7.2, 7.3, 7.4 | Yes — all independent | Domain scaffolding + trash fix |
| B | 7.5 | After A (trash_screen catch blocks depend on 7.1) | catch(_) sweep |
| C | 7.6 | After B (need all changes landed) | Dead code cleanup |
| D | 7.7 | After C (final verification) | Analyze + test + checklist |

## Commands
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test"
pwsh -Command "flutter pub get"
```
