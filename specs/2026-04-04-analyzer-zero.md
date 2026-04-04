# Spec: Analyzer Zero — Eliminate All 1054 Remaining Lint Violations

## Goal

Reduce `flutter analyze` from 1054 violations to **zero** on the `fix/analyzer-zero` branch. Track 1 (`dart fix --apply`) already eliminated 1214 mechanical violations. This spec covers Track 2: the 1054 remaining violations that require architectural patterns, manual fixes, and policy decisions.

## Context

- **Branch**: `fix/analyzer-zero` (created from `main`)
- **Starting point**: `dart fix --apply` already applied (334 files, 1214 fixes)
- **Remaining**: 1054 violations across 35 rules, 460 files
- **All violations are built-in Dart/Flutter rules** enabled in `analysis_options.yaml` tiers 1-5. Zero from the 49 custom lint rules (those run via `custom_lint` separately).
- **Distribution**: 72% in `lib/`, 23% in `test/`, 5% in `integration_test/`

## Hotspot Map

| Feature | lib/ | test/ | Total | % of all |
|---------|------|-------|-------|----------|
| PDF | 517 | 135 | 652 | 29% |
| Sync | 152 | 133 | 285 | 13% |
| Entries | 131 | 36 | 167 | 7% |
| Forms | 127 | 20 | 147 | 7% |
| Everything else | 693 | 199 | 892 | 44% |

## Top 5 Worst Files

| File | Violations | Dominant Issue |
|------|-----------|----------------|
| `database_service.dart` | 81 | SQLite row cast patterns |
| `extraction_schema_migration_test.dart` | 48 | Type annotations + dynamic calls |
| `sync_engine.dart` | 46 | Bare catch clauses |
| `logger.dart` | 42 | `$runtimeType` in log strings |
| `driver_server.dart` | 40 | Bare catches + casts |

---

## Phase 1: Policy Decisions (~108 violations)

### 1A: Suppress `do_not_use_environment` rule (42 violations)

All 42 violations are legitimate `static const` uses of `String.fromEnvironment()`, `bool.fromEnvironment()`, and `int.fromEnvironment()` — the intended Dart `--dart-define` compile-time configuration pattern.

**Files affected**: `test_mode_config.dart` (13), `supabase_config.dart` (2), `logger.dart` (5), `main.dart` (2), `main_driver.dart` (1), `core_services_initializer.dart` (1), `driver_server.dart` (1), `sync_engine.dart` (1), integration tests (13), test files (3).

**Action**: Disable `do_not_use_environment` in `analysis_options.yaml`. These are all correct usage of Dart's compile-time constant mechanism and the rule produces only false positives in this codebase.

### 1B: Exclude test/ and integration_test/ from `avoid_catches_without_on_clauses` (65 violations)

Test mocks and helpers mirror production catch patterns intentionally. The project's custom lint rules already exclude test paths for similar rules (D3, D11, S1, S3, S4). Maintaining separate lint compliance for test mock catch clauses is pure toil with no safety benefit.

**Files affected**: `mock_providers.dart` (22), `mock_repositories.dart` (2), `daily_entry_provider_test.dart` (6), various test helpers and integration tests.

**Action**: Add per-file or per-directory exclusion for `avoid_catches_without_on_clauses` in test/ and integration_test/ paths in `analysis_options.yaml`.

### 1C: Remove `strict_raw_type` from analysis_options.yaml (1 violation)

The `strict_raw_type` rule is not recognized by the current Dart analyzer version. It produces a warning in `analysis_options.yaml` itself.

**Action**: Remove the `strict_raw_type` line from the linter rules section.

---

## Phase 2: Mechanical Fixes (~503 violations)

These are search-and-replace patterns that don't require new abstractions.

### 2A: `catch (e)` → `on Exception catch (e)` (~177 violations)

The remaining bare catches in production code fall into:
- **Best-effort / fire-and-forget** (~100): sync engine, lifecycle manager, logger, soft-delete service
- **JSON decode fallbacks** (~15): `form_response.dart`, `inspector_form.dart`, `calculation_history.dart` — should be `on FormatException` or `on Exception`
- **Infrastructure error boundaries** (~45): `driver_server.dart` (19), `logger.dart` (22), `database_service.dart` (3), bootstrap files (5)
- **Auth fallback catches** (~17): `auth_provider.dart`, `company_setup_screen.dart` — already have specific `on AuthException` catches, the bare `catch` is the fallback

**Pattern**: Every `catch (e)` → `on Exception catch (e)`, every `catch (e, stack)` → `on Exception catch (e, stack)`, every `catch (_)` → `on Exception catch (_)`. No pattern in the codebase catches `Error` intentionally, and none should — `Error` subtypes (`StackOverflowError`, `OutOfMemoryError`) should always propagate.

**Specific JSON decode cases**: Where the only possible exception is `FormatException` from `jsonDecode`, use `on FormatException catch (e)` for precision.

### 2B: Add `@immutable` annotation (70 violations across 35 classes)

All 35 affected classes already have only `final` fields — they ARE immutable but lack the `@immutable` annotation.

**Two sub-patterns**:
- **PDF extraction models** (~25 classes, ~48 violations): Pure value objects with `const` constructors. All in `lib/features/pdf/services/extraction/models/`.
- **Data models** (~10 classes, ~22 violations): Entity models mapping to SQLite/Supabase. In `auth/data/models/`, `forms/data/models/`, `settings/data/models/`, `todos/data/models/`, `calculator/data/models/`, `core/database/schema_verifier.dart`.

**Action**: Add `import 'package:meta/meta.dart';` (if not already imported) and `@immutable` above each class declaration.

### 2C: Replace `$runtimeType` with `StageNames.*` constants (42 violations in 18 files)

100% of these are in PDF extraction pipeline stage classes, used exclusively in `Logger.pdf()` structured logging:
```dart
Logger.pdf('STAGE_START stage=$runtimeType');
Logger.pdf('STAGE_COMPLETE stage=$runtimeType elapsed=${stopwatch.elapsedMilliseconds}ms');
```

`StageNames` constants already exist at `lib/features/pdf/services/extraction/stages/stage_names.dart` and are already used in `StageReport` creation.

**Action**: In each of the 18 stage classes, replace `$runtimeType` with the corresponding `StageNames.*` constant. Example: `CellExtractorV2` uses `StageNames.cellExtraction`.

### 2D: Wrap with `unawaited()` (~90 violations of `discarded_futures`)

Categorized fire-and-forget patterns:
- **Navigation calls** (~38): `context.pushNamed(...)` / `context.goNamed(...)` in `onTap`/`onPressed` callbacks
- **Dialog/Sheet shows** (~20): `AppDialog.show()`, `AppBottomSheet.show()` where result is unused
- **Platform channels** (~10): `HapticFeedback.lightImpact()`, `Clipboard.setData()`
- **Lifecycle methods** (~12): `didChangeAppLifecycleState` calling async helpers — can't be made async
- **Logger internals** (6): Fire-and-forget by design in `logger.dart`
- **Sync debug** (1): `response.drain<void>()` in debug HTTP post

**Action**: Add `import 'dart:async' show unawaited;` to affected files. Wrap each fire-and-forget call with `unawaited(...)`.

### 2E: Make methods `async` + `await` (~30 violations of `discarded_futures`)

Provider load methods called from `addPostFrameCallback` that SHOULD be awaited:
- `_loadTodos()`, `_loadData()`, `_applyQueryFilter()` etc.
- These are `void` methods calling async provider methods without await.

**Action**: Convert from `void _loadX() { provider.loadX(); }` to `Future<void> _loadX() async { await provider.loadX(); }`. The callers (`addPostFrameCallback`) accept `void Function()` which is compatible with `Future<void> Function()`.

### 2F: Fix `missing_whitespace_between_adjacent_strings` (54 violations)

Adjacent string literals missing a space between them. All in `lib/` production code.

**Action**: Add missing space characters in string concatenation. Manual review needed per-instance.

### 2G: Add `// reason` to `// ignore:` comments (42 violations of `document_ignores`)

Every `// ignore:` and `// ignore_for_file:` needs a reason explaining why the diagnostic is suppressed.

**Distribution**: Integration tests (8, `avoid_print` for test output), production code (7, experimental APIs and deprecated field usage), test files (27, various suppressed diagnostics).

**Action**: Add concise reason text: `// ignore: avoid_print, diagnostic output for test runner` etc.

### 2H: Fix `avoid_dynamic_calls` in test code (~78 violations)

83% of `avoid_dynamic_calls` are in test files. Root causes:
- **SQLite query results** (39): `tables.first['name']` returns `Object?` — need `as String` cast
- **JSON decoded lists** (22): `jsonDecode()` returns `dynamic` — need `as List<Map<String, dynamic>>` cast
- **Untyped map chains** (16): Test assertions accessing nested dynamic maps

**Action**: Add explicit type casts at access points. Concentrated in just 6-8 test files.

### 2I: Fix `avoid_dynamic_calls` in production code (~8 violations)

- **Supabase `PostgrestList`** (4): `sync_engine.dart` (3), `orphan_scanner.dart` (1) — cast to typed list
- **Supabase RPC response** (3): `company_members_repository.dart` — replace `List<dynamic>.from()` with typed cast
- **Repository result generic** (1): `export_entry_use_case.dart` — ensure proper generic type flow

### 2J: Fix remaining small rules (~28 violations)

- `matching_super_parameters` (25): Rename super parameters to match parent constructor
- `close_sinks` (3): Ensure `StreamController`s are properly closed
- `parameter_assignments` (3): Don't reassign method parameters
- `curly_braces_in_flow_control_structures` (3): Add braces to single-line if/else
- `use_if_null_to_convert_nulls_to_bools` (remaining after dart fix): Use `?? false` pattern
- `avoid_catching_errors` (7): Replace `catch` of `Error` with proper type
- `avoid_implementing_value_types` (2): Don't implement value types in test mocks
- `unreachable_from_main` (12): Remove dead code or make private
- Other singles: `unnecessary_import`, `avoid_unused_constructor_parameters`, `no_adjacent_strings_in_list`, `no_literal_bool_comparisons`

---

## Phase 3: `SafeRow` Extension + SQLite Cast Fixes (~120 violations)

### 3A: Create `SafeRow` extension

Create `lib/shared/utils/safe_row.dart`:

```dart
/// Type-safe accessors for SQLite query result rows.
///
/// SQLite queries return `Map<String, Object?>`. This extension provides
/// null-checked, type-cast accessors that eliminate `cast_nullable_to_non_nullable`
/// lint violations and produce descriptive errors on type mismatches.
extension SafeRow on Map<String, Object?> {
  String requireString(String key) {
    final value = this[key];
    if (value == null) throw StateError('Column "$key" is null');
    return value as String;
  }

  int requireInt(String key) {
    final value = this[key];
    if (value == null) throw StateError('Column "$key" is null');
    return value as int;
  }

  // Also: requireBool, optionalString, optionalInt, etc.
}
```

The `!` operator on `Object?` produces `Object`, and casting `Object` to `String` is not a nullable-to-non-nullable cast, eliminating the lint.

### 3B: Apply `SafeRow` across codebase

Replace patterns like:
- `row['project_id'] as String` → `row.requireString('project_id')`
- `result.first['cnt'] as int` → `result.first.requireInt('cnt')`

**Files**: `database_service.dart` (20), `sync_engine.dart` (9), `change_tracker.dart` (6), `integrity_checker.dart`, `schema_verifier.dart`, `driver_server.dart`, `project_lifecycle_service.dart`, various datasources and test files.

### 3C: Add query convenience helpers (optional)

For the most repeated aggregate patterns:
```dart
Future<int> queryCount(Database db, String table, {String? where, List<Object?>? whereArgs});
Future<List<String>> queryColumnStrings(Database db, String sql, [List<Object?>? args]);
```

---

## Phase 4: `SafeAction` Mixin + Provider Refactor (~170 violations)

### 4A: Create `SafeAction` mixin

Create `lib/shared/providers/safe_action_mixin.dart`:

```dart
/// Mixin for ChangeNotifier providers that provides standardized
/// error handling, loading state, and notification patterns.
///
/// Eliminates the duplicated try/catch/finally + _isLoading/_error/notifyListeners
/// block that appears across 30+ providers in the codebase.
mixin SafeAction on ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Wraps an async action with loading state, error handling, and notification.
  Future<bool> safeAction(String label, Future<void> Function() fn) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await fn();
      return true;
    } on Exception catch (e) {
      _error = 'Failed to $label: $e';
      Logger.error('[${runtimeType}] $label failed', error: e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Variant for actions that return a value.
  Future<T?> safeGet<T>(String label, Future<T> Function() fn) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await fn();
      return result;
    } on Exception catch (e) {
      _error = 'Failed to $label: $e';
      Logger.error('[${runtimeType}] $label failed', error: e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 4B: Refactor providers to use `SafeAction`

Each of the 30+ providers that currently has the pattern:
```dart
_isLoading = true; _error = null; notifyListeners();
try {
  _items = await _repository.getAll();
} catch (e) {
  _error = 'Failed to load items: $e';
  Logger.ui('[Provider] $_error');
} finally {
  _isLoading = false; notifyListeners();
}
```

Becomes:
```dart
await safeAction('load items', () async {
  _items = await _repository.getAll();
});
```

**Affected providers**: `todo_provider.dart` (12), `daily_entry_provider.dart` (11), `project_provider.dart` (10), `admin_provider.dart` (9), `entry_quantity_provider.dart` (11), `auth_provider.dart` (12), `equipment_provider.dart` (7), `bid_item_provider.dart` (4), `base_list_provider.dart` (4), `consent_provider.dart` (4), `photo_provider.dart`, `settings_provider.dart`, `gallery_provider.dart`, `calculator_provider.dart`, and more.

**Note**: Providers that have existing `_isLoading`/`_error` fields will need to be audited — the mixin provides these, so remove the duplicate declarations. Some providers have multiple loading states (e.g., `_isLoadingList` + `_isSaving`) — these may need variants or the mixin may only apply to a subset of their methods.

---

## Phase 5: `RepositoryResult.safeCall()` + Repository Refactor (~90 violations)

### 5A: Add `safeCall` to `RepositoryResult`

```dart
/// Wraps a datasource call in standardized error handling.
static Future<RepositoryResult<T>> safeCall<T>(
  Future<T> Function() fn,
  String context,
) async {
  try {
    return RepositoryResult.success(await fn());
  } on Exception catch (e) {
    Logger.db('$context error: $e');
    return RepositoryResult.failure('Error in $context: $e');
  }
}
```

### 5B: Refactor repositories

Each repository method currently:
```dart
Future<RepositoryResult<FormResponse>> create(FormResponse item) async {
  try {
    final result = await _localDatasource.create(item);
    return RepositoryResult.success(result);
  } catch (e) {
    Logger.db('FormResponseRepository.create error: $e');
    return RepositoryResult.failure('Error creating form response: $e');
  }
}
```

Becomes:
```dart
Future<RepositoryResult<FormResponse>> create(FormResponse item) =>
  RepositoryResult.safeCall(
    () => _localDatasource.create(item),
    'FormResponseRepository.create',
  );
```

**Affected repositories**: `form_response_repository.dart` (21), `inspector_form_repository.dart` (13), `photo_repository_impl.dart` (12), `document_repository.dart`, `entry_export_repository.dart`, `form_export_repository.dart`, and others.

---

## Phase 6: `Value<T>` copyWith Wrapper (~220 violations)

### Decision Required: `Value<T>` wrapper vs `freezed` code generation

**Option A: `Value<T>` wrapper (manual)**
- Create `lib/shared/models/value.dart` with a simple `Value<T>` class
- Rewrite all `copyWith()` methods to use `Value<T>?` parameters instead of `Object? _sentinel`
- Call sites change from `copyWith(name: 'new')` to `copyWith(name: Value('new'))`
- Pro: No dependencies, incremental, full control
- Con: More verbose call sites, touches every model AND every call site

**Option B: `freezed` code generation**
- Add `freezed`, `freezed_annotation`, `build_runner` dependencies
- Convert models to `@freezed` classes with generated `copyWith`, `==`, `hashCode`, `toString`
- Pro: Eliminates copyWith violations AND equals/hashCode violations AND generates `toString`
- Con: Major dependency, changes model authoring pattern, requires `build_runner` in CI

**Option C: Suppress `cast_nullable_to_non_nullable` for copyWith methods only**
- Add `// ignore: cast_nullable_to_non_nullable` inline in each copyWith
- Pro: Zero behavioral change, lowest effort
- Con: 220 ignore comments, doesn't improve code quality

**Recommendation**: Option A (`Value<T>`) for models that are actively edited. Option C (suppress) for stable PDF extraction models that rarely change. This hybrid approach balances effort with value.

### 6A: Create `Value<T>` class

```dart
/// Wrapper to distinguish "parameter not passed" from "passed as null"
/// in copyWith methods. Eliminates the unsafe Object?-sentinel-as-T cast.
class Value<T> {
  final T value;
  const Value(this.value);
}
```

### 6B: Migrate copyWith methods (incremental, feature by feature)

Priority order based on edit frequency:
1. Core data models (entries, projects, forms, auth) — high edit frequency
2. PDF extraction models — stable, low edit frequency (suppress instead)

---

## Verification

After each phase:
1. Run `pwsh -Command "flutter analyze 2>&1"` and confirm violation count decreases by expected amount
2. Run `pwsh -Command "flutter test 2>&1"` (or CI) to confirm no behavioral regressions

**Target**: 0 issues found.

## Constraints

- **No behavior changes**: All fixes must preserve exact runtime behavior. The only exception is the `SafeAction` mixin (Phase 4) which standardizes error messages — acceptable since these are UI strings.
- **No new dependencies** unless Phase 6 Option B (freezed) is chosen.
- **CI-first testing**: Use CI as primary test runner per project preferences.
- **No lint rule suppression** except for the 3 policy decisions in Phase 1 which are justified false positives.
- **All existing tests must pass** after each phase.

## Out of Scope

- Custom lint rules (run via `custom_lint`, not `flutter analyze`)
- New test coverage for the helpers/mixins introduced
- Refactoring beyond what's needed to fix violations
