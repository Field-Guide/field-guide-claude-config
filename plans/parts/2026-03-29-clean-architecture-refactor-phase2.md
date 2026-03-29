# Phase 2: Core Domain Infrastructure

> **Goal:** Create shared base classes and patterns that all features will use during Clean Architecture migration. This phase is ADDITIVE ONLY — no existing code is modified or broken.

---

## Sub-phase 2.1: UseCase Base Class
**Files:**
- Create: `lib/shared/domain/use_case.dart`
**Agent**: `backend-data-layer-agent`

### Step 2.1.1: Create the UseCase abstract class

Create `lib/shared/domain/use_case.dart`:

```dart
/// Base class for all use cases in the application.
///
/// WHY: Use cases encapsulate a single business operation, making business logic
/// testable independently of UI and data layers. Each use case is a callable
/// class that takes typed params and returns a typed result.
///
/// Usage:
///   class GetContractors extends UseCase<List<Contractor>, GetContractorsParams> {
///     final ContractorRepository _repo;
///     GetContractors(this._repo);
///
///     @override
///     Future<List<Contractor>> call(GetContractorsParams params) async {
///       return _repo.getByProjectId(params.projectId);
///     }
///   }
abstract class UseCase<Type, Params> {
  /// Execute the use case with the given parameters.
  Future<Type> call(Params params);
}

/// Sentinel class for use cases that don't require parameters.
///
/// WHY: Avoids nullable params or `void` generics. Provides a clear signal
/// that a use case needs no input.
///
/// Usage:
///   class GetAllProjects extends UseCase<List<Project>, NoParams> {
///     @override
///     Future<List<Project>> call(NoParams params) async { ... }
///   }
///   // Invoke: getAllProjects(const NoParams());
class NoParams {
  const NoParams();
}

/// Parameters for project-scoped operations.
///
/// WHY: Most entities in this app are project-scoped. This avoids repeating
/// a `projectId` field in every feature's params class.
class ProjectParams {
  final String projectId;
  const ProjectParams({required this.projectId});
}

/// Parameters for single-entity lookup by ID.
class IdParams {
  final String id;
  const IdParams({required this.id});
}
```

---

## Sub-phase 2.2: UseCaseResult Type
**Files:**
- Create: `lib/shared/domain/use_case_result.dart`
**Agent**: `backend-data-layer-agent`

### Step 2.2.1: Create UseCaseResult as a sealed class

Create `lib/shared/domain/use_case_result.dart`:

```dart
/// Result wrapper for use case outputs.
///
/// WHY: Sealed class gives exhaustive pattern matching at call sites, forcing
/// callers to handle both success and failure. This is safer than RepositoryResult's
/// boolean `isSuccess` check which can be accidentally skipped.
///
/// WHY sealed over RepositoryResult: RepositoryResult uses a boolean flag pattern
/// which works fine for repositories but doesn't enforce exhaustive handling.
/// For use cases (which are the boundary between domain and presentation),
/// we want the compiler to enforce that both cases are handled.
///
/// Usage:
///   final result = await createContractor(params);
///   switch (result) {
///     case Success(:final data):
///       // handle data
///     case Failure(:final error, :final code):
///       // handle error
///   }
sealed class UseCaseResult<T> {
  const UseCaseResult();

  /// Create a success result with data.
  factory UseCaseResult.success(T data) = Success<T>;

  /// Create a failure result with an error.
  factory UseCaseResult.failure(
    String message, {
    ErrorCode code,
  }) = Failure<T>;

  /// Convenience: true if this is a Success.
  bool get isSuccess => this is Success<T>;

  /// Convenience: extract data or null.
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };
}

/// Successful result containing data.
class Success<T> extends UseCaseResult<T> {
  final T data;
  const Success(this.data);
}

/// Failed result containing an error message and optional error code.
class Failure<T> extends UseCaseResult<T> {
  final String error;
  final ErrorCode code;
  const Failure(this.error, {this.code = ErrorCode.unknown});
}

/// Categorized error codes for domain-level failures.
///
/// WHY: String error messages are for humans. Error codes let the presentation
/// layer make decisions (e.g., show a retry button for `network`, redirect to
/// login for `unauthorized`). Keeps domain errors structured without coupling
/// to UI concerns.
enum ErrorCode {
  /// Unknown/uncategorized error.
  unknown,

  /// Entity not found.
  notFound,

  /// Validation failed (e.g., missing required fields).
  validation,

  /// User lacks permission for this operation.
  unauthorized,

  /// Conflict (e.g., duplicate entry, optimistic lock failure).
  conflict,

  /// Network/connectivity error.
  network,

  /// Database/storage error.
  storage,
}
```

---

## Sub-phase 2.3: Domain Barrel Export
**Files:**
- Create: `lib/shared/domain/domain.dart`
**Agent**: `backend-data-layer-agent`

### Step 2.3.1: Create barrel export for domain layer

Create `lib/shared/domain/domain.dart`:

```dart
/// Barrel export for shared domain infrastructure.
///
/// WHY: Single import for all domain base classes. Features import
/// `package:construction_inspector/shared/domain/domain.dart` instead of
/// individual files.
export 'use_case.dart';
export 'use_case_result.dart';
```

---

## Sub-phase 2.4: BaseUseCaseListProvider
**Files:**
- Create: `lib/shared/providers/base_use_case_list_provider.dart`
**Agent**: `backend-data-layer-agent`

### Step 2.4.1: Create BaseUseCaseListProvider as a parallel base class

WHY: We cannot modify `BaseListProvider` without breaking all 5 existing providers.
Instead, create a parallel class that accepts use case callables. During feature
migration (Phase 3+), providers switch from `BaseListProvider` to
`BaseUseCaseListProvider` one at a time. Once all 5 are migrated, the old
`BaseListProvider` gets deleted.

The key design difference: instead of taking a repository instance and calling
its methods directly, this provider takes individual use case functions as
constructor parameters. This inverts the dependency — the provider depends on
abstract operations, not a concrete repository type.

Create `lib/shared/providers/base_use_case_list_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:construction_inspector/shared/domain/domain.dart';

/// Abstract base provider that works with use cases instead of repositories.
///
/// WHY: BaseListProvider is tightly coupled to ProjectScopedRepository<T>,
/// which means providers must know about the repository type. This class
/// accepts use case callables, decoupling providers from the data layer.
///
/// Migration path:
///   1. Feature creates its use cases (e.g., GetLocations, CreateLocation)
///   2. Feature's provider switches from BaseListProvider to BaseUseCaseListProvider
///   3. Provider constructor takes use cases instead of repository
///   4. Once all features migrate, BaseListProvider is deleted
///
/// Type parameter:
/// - `T`: The domain entity type (e.g., Location, Contractor)
abstract class BaseUseCaseListProvider<T> extends ChangeNotifier {
  /// Use case for loading items by project ID.
  /// WHY: This is the most common operation — every list screen needs it.
  final UseCase<List<T>, ProjectParams> _loadItemsUseCase;

  /// Use case for creating an item. Nullable because some lists are read-only.
  final UseCase<UseCaseResult<T>, T>? _createItemUseCase;

  /// Use case for updating an item. Nullable because some lists are read-only.
  final UseCase<UseCaseResult<T>, T>? _updateItemUseCase;

  /// Use case for deleting an item by ID. Nullable because some lists are read-only.
  final UseCase<UseCaseResult<void>, IdParams>? _deleteItemUseCase;

  BaseUseCaseListProvider({
    required UseCase<List<T>, ProjectParams> loadItems,
    UseCase<UseCaseResult<T>, T>? createItem,
    UseCase<UseCaseResult<T>, T>? updateItem,
    UseCase<UseCaseResult<void>, IdParams>? deleteItem,
  })  : _loadItemsUseCase = loadItems,
        _createItemUseCase = createItem,
        _updateItemUseCase = updateItem,
        _deleteItemUseCase = deleteItem;

  // ---------------------------------------------------------------------------
  // State (mirrors BaseListProvider for drop-in replacement)
  // ---------------------------------------------------------------------------

  List<T> _items = [];
  String? _currentProjectId;
  bool _isLoading = false;
  String? _error;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<T> get items => _items;
  String? get currentProjectId => _currentProjectId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasItems => _items.isNotEmpty;
  int get itemCount => _items.length;

  // ---------------------------------------------------------------------------
  // Abstract Methods (same contract as BaseListProvider)
  // ---------------------------------------------------------------------------

  /// Entity name for error messages (e.g., "location", "contractor").
  String get entityName;

  /// Extract the ID from an item for equality checks.
  String getItemId(T item);

  /// Sort items after modifications. Default: no-op.
  void sortItems() {}

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Load all items for a project via the loadItems use case.
  Future<void> loadItems(String projectId) async {
    _currentProjectId = projectId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _loadItemsUseCase(ProjectParams(projectId: projectId));
      _error = null;
    } catch (e) {
      _error = 'Failed to load ${entityName}s: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload items for current project.
  Future<void> refresh() async {
    if (_currentProjectId != null) {
      await loadItems(_currentProjectId!);
    }
  }

  /// Create a new item via the createItem use case.
  /// Returns true if successful, false if failed (check [error]).
  Future<bool> createItem(T item) async {
    if (_createItemUseCase == null) {
      _error = 'Create not supported for $entityName';
      notifyListeners();
      return false;
    }

    if (!checkWritePermission('create $entityName')) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _createItemUseCase!(item);
      switch (result) {
        case Success(:final data):
          _items.add(data);
          sortItems();
          _error = null;
          _isLoading = false;
          notifyListeners();
          return true;
        case Failure(:final error):
          _error = error;
          _isLoading = false;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _error = 'Failed to create $entityName: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing item via the updateItem use case.
  /// Returns true if successful, false if failed (check [error]).
  Future<bool> updateItem(T item) async {
    if (_updateItemUseCase == null) {
      _error = 'Update not supported for $entityName';
      notifyListeners();
      return false;
    }

    if (!checkWritePermission('update $entityName')) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _updateItemUseCase!(item);
      switch (result) {
        case Success(:final data):
          final index = _items.indexWhere((i) => getItemId(i) == getItemId(data));
          if (index != -1) {
            _items[index] = data;
            sortItems();
          }
          _error = null;
          _isLoading = false;
          notifyListeners();
          return true;
        case Failure(:final error):
          _error = error;
          _isLoading = false;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _error = 'Failed to update $entityName: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete an item by ID via the deleteItem use case.
  Future<bool> deleteItem(String id) async {
    if (_deleteItemUseCase == null) {
      _error = 'Delete not supported for $entityName';
      notifyListeners();
      return false;
    }

    if (!checkWritePermission('delete $entityName')) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _deleteItemUseCase!(IdParams(id: id));
      switch (result) {
        case Success():
          _items.removeWhere((i) => getItemId(i) == id);
          _error = null;
          _isLoading = false;
          notifyListeners();
          return true;
        case Failure(:final error):
          _error = error;
          _isLoading = false;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _error = 'Failed to delete $entityName: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get an item by ID from the local list (no async call).
  T? getById(String id) {
    return _items.where((i) => getItemId(i) == id).firstOrNull;
  }

  /// Clear error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all items and state.
  void clear() {
    _items = [];
    _currentProjectId = null;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Write Permission (same pattern as BaseListProvider)
  // ---------------------------------------------------------------------------

  /// Write permission check callback.
  /// Set by main.dart to `() => authProvider.canEditFieldData`.
  bool Function() canWrite = () => true;

  /// Check write permission and set error if denied.
  bool checkWritePermission(String action) {
    if (!canWrite()) {
      _error = 'You do not have permission to $action';
      notifyListeners();
      return false;
    }
    return true;
  }
}
```

---

## Sub-phase 2.5: Update Barrel Export for Providers
**Files:**
- Modify: `lib/shared/providers/` (add barrel if missing, or update existing)
**Agent**: `backend-data-layer-agent`

### Step 2.5.1: Ensure the new provider base class is exported

If `lib/shared/shared.dart` exists and exports providers, add the new file to it.
If provider-level barrel exports exist, add there too.

Add to `lib/shared/shared.dart` (at the appropriate location among existing exports):

```dart
export 'domain/domain.dart';
export 'providers/base_use_case_list_provider.dart';
```

Do NOT remove any existing exports. This is additive only.

---

## Sub-phase 2.6: Unit Tests for Domain Infrastructure
**Files:**
- Create: `test/shared/domain/use_case_test.dart`
- Create: `test/shared/domain/use_case_result_test.dart`
- Create: `test/shared/providers/base_use_case_list_provider_test.dart`
**Agent**: `qa-testing-agent`

### Step 2.6.1: Test UseCase base class and params

Create `test/shared/domain/use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/shared/domain/domain.dart';

/// Concrete test implementation of UseCase.
class AddNumbers extends UseCase<int, AddNumbersParams> {
  @override
  Future<int> call(AddNumbersParams params) async {
    return params.a + params.b;
  }
}

class AddNumbersParams {
  final int a;
  final int b;
  const AddNumbersParams(this.a, this.b);
}

/// Test UseCase with NoParams.
class GetConstant extends UseCase<String, NoParams> {
  @override
  Future<String> call(NoParams params) async => 'constant_value';
}

void main() {
  group('UseCase', () {
    test('can be called with typed params', () async {
      final useCase = AddNumbers();
      final result = await useCase(AddNumbersParams(2, 3));
      expect(result, 5);
    });

    test('works with NoParams', () async {
      final useCase = GetConstant();
      final result = await useCase(const NoParams());
      expect(result, 'constant_value');
    });
  });

  group('ProjectParams', () {
    test('holds projectId', () {
      const params = ProjectParams(projectId: 'proj-123');
      expect(params.projectId, 'proj-123');
    });
  });

  group('IdParams', () {
    test('holds id', () {
      const params = IdParams(id: 'item-456');
      expect(params.id, 'item-456');
    });
  });
}
```

### Step 2.6.2: Test UseCaseResult sealed class

Create `test/shared/domain/use_case_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/shared/domain/domain.dart';

void main() {
  group('UseCaseResult', () {
    test('Success holds data', () {
      final result = UseCaseResult<String>.success('hello');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 'hello');
    });

    test('Failure holds error message', () {
      final result = UseCaseResult<String>.failure('something broke');
      expect(result.isSuccess, isFalse);
      expect(result.dataOrNull, isNull);
      expect((result as Failure<String>).error, 'something broke');
    });

    test('Failure has default unknown error code', () {
      final result = UseCaseResult<int>.failure('oops');
      final failure = result as Failure<int>;
      expect(failure.code, ErrorCode.unknown);
    });

    test('Failure can carry specific error code', () {
      final result = UseCaseResult<int>.failure(
        'not found',
        code: ErrorCode.notFound,
      );
      final failure = result as Failure<int>;
      expect(failure.code, ErrorCode.notFound);
    });

    test('exhaustive pattern matching works', () {
      final result = UseCaseResult<int>.success(42);
      final message = switch (result) {
        Success(:final data) => 'got $data',
        Failure(:final error) => 'err: $error',
      };
      expect(message, 'got 42');
    });

    test('exhaustive pattern matching on failure', () {
      final result = UseCaseResult<int>.failure('bad', code: ErrorCode.validation);
      final message = switch (result) {
        Success(:final data) => 'got $data',
        Failure(:final error, :final code) => 'err: $error ($code)',
      };
      expect(message, 'err: bad (ErrorCode.validation)');
    });
  });

  group('ErrorCode', () {
    test('all codes exist', () {
      expect(ErrorCode.values, containsAll([
        ErrorCode.unknown,
        ErrorCode.notFound,
        ErrorCode.validation,
        ErrorCode.unauthorized,
        ErrorCode.conflict,
        ErrorCode.network,
        ErrorCode.storage,
      ]));
    });
  });
}
```

### Step 2.6.3: Test BaseUseCaseListProvider

Create `test/shared/providers/base_use_case_list_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/shared/domain/domain.dart';
import 'package:construction_inspector/shared/providers/base_use_case_list_provider.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _FakeItem {
  final String id;
  final String name;
  const _FakeItem(this.id, this.name);
}

class _LoadItemsUseCase extends UseCase<List<_FakeItem>, ProjectParams> {
  List<_FakeItem> items;
  bool shouldThrow;
  _LoadItemsUseCase({this.items = const [], this.shouldThrow = false});

  @override
  Future<List<_FakeItem>> call(ProjectParams params) async {
    if (shouldThrow) throw Exception('load failed');
    return items;
  }
}

class _CreateItemUseCase extends UseCase<UseCaseResult<_FakeItem>, _FakeItem> {
  UseCaseResult<_FakeItem>? result;
  bool shouldThrow;
  _CreateItemUseCase({this.result, this.shouldThrow = false});

  @override
  Future<UseCaseResult<_FakeItem>> call(_FakeItem params) async {
    if (shouldThrow) throw Exception('create failed');
    return result ?? UseCaseResult.success(params);
  }
}

class _UpdateItemUseCase extends UseCase<UseCaseResult<_FakeItem>, _FakeItem> {
  UseCaseResult<_FakeItem>? result;
  _UpdateItemUseCase({this.result});

  @override
  Future<UseCaseResult<_FakeItem>> call(_FakeItem params) async {
    return result ?? UseCaseResult.success(params);
  }
}

class _DeleteItemUseCase extends UseCase<UseCaseResult<void>, IdParams> {
  UseCaseResult<void>? result;
  _DeleteItemUseCase({this.result});

  @override
  Future<UseCaseResult<void>> call(IdParams params) async {
    return result ?? UseCaseResult.success(null as void);
  }
}

class _TestProvider extends BaseUseCaseListProvider<_FakeItem> {
  _TestProvider({
    required super.loadItems,
    super.createItem,
    super.updateItem,
    super.deleteItem,
  });

  @override
  String get entityName => 'fake_item';

  @override
  String getItemId(_FakeItem item) => item.id;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BaseUseCaseListProvider', () {
    late _LoadItemsUseCase loadUseCase;
    late _CreateItemUseCase createUseCase;
    late _UpdateItemUseCase updateUseCase;
    late _DeleteItemUseCase deleteUseCase;
    late _TestProvider provider;

    setUp(() {
      loadUseCase = _LoadItemsUseCase(items: [
        const _FakeItem('1', 'Alpha'),
        const _FakeItem('2', 'Beta'),
      ]);
      createUseCase = _CreateItemUseCase();
      updateUseCase = _UpdateItemUseCase();
      deleteUseCase = _DeleteItemUseCase();
      provider = _TestProvider(
        loadItems: loadUseCase,
        createItem: createUseCase,
        updateItem: updateUseCase,
        deleteItem: deleteUseCase,
      );
    });

    test('initial state is empty', () {
      expect(provider.items, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.currentProjectId, isNull);
    });

    test('loadItems populates items', () async {
      await provider.loadItems('proj-1');
      expect(provider.items.length, 2);
      expect(provider.currentProjectId, 'proj-1');
      expect(provider.error, isNull);
    });

    test('loadItems sets error on failure', () async {
      loadUseCase.shouldThrow = true;
      await provider.loadItems('proj-1');
      expect(provider.error, contains('Failed to load'));
      expect(provider.items, isEmpty);
    });

    test('createItem adds to list on success', () async {
      await provider.loadItems('proj-1');
      final created = await provider.createItem(const _FakeItem('3', 'Gamma'));
      expect(created, isTrue);
      expect(provider.items.length, 3);
    });

    test('createItem sets error on use case failure', () async {
      createUseCase.result = UseCaseResult.failure('validation error');
      final created = await provider.createItem(const _FakeItem('3', 'Gamma'));
      expect(created, isFalse);
      expect(provider.error, 'validation error');
    });

    test('createItem sets error on exception', () async {
      createUseCase.shouldThrow = true;
      final created = await provider.createItem(const _FakeItem('3', 'Gamma'));
      expect(created, isFalse);
      expect(provider.error, contains('Failed to create'));
    });

    test('updateItem replaces item in list on success', () async {
      await provider.loadItems('proj-1');
      final updated = await provider.updateItem(const _FakeItem('1', 'Alpha Updated'));
      expect(updated, isTrue);
      expect(provider.items.first.name, 'Alpha Updated');
    });

    test('updateItem sets error on use case failure', () async {
      await provider.loadItems('proj-1');
      updateUseCase.result = UseCaseResult.failure('conflict');
      final updated = await provider.updateItem(const _FakeItem('1', 'X'));
      expect(updated, isFalse);
      expect(provider.error, 'conflict');
    });

    test('deleteItem removes from list on success', () async {
      await provider.loadItems('proj-1');
      final deleted = await provider.deleteItem('1');
      expect(deleted, isTrue);
      expect(provider.items.length, 1);
      expect(provider.items.first.id, '2');
    });

    test('deleteItem sets error on use case failure', () async {
      await provider.loadItems('proj-1');
      deleteUseCase.result = UseCaseResult.failure('cannot delete');
      final deleted = await provider.deleteItem('1');
      expect(deleted, isFalse);
      expect(provider.error, 'cannot delete');
    });

    test('write guard blocks create when canWrite is false', () async {
      provider.canWrite = () => false;
      final created = await provider.createItem(const _FakeItem('3', 'Gamma'));
      expect(created, isFalse);
      expect(provider.error, contains('permission'));
    });

    test('write guard blocks update when canWrite is false', () async {
      provider.canWrite = () => false;
      final updated = await provider.updateItem(const _FakeItem('1', 'X'));
      expect(updated, isFalse);
      expect(provider.error, contains('permission'));
    });

    test('write guard blocks delete when canWrite is false', () async {
      provider.canWrite = () => false;
      final deleted = await provider.deleteItem('1');
      expect(deleted, isFalse);
      expect(provider.error, contains('permission'));
    });

    test('returns false for create when use case is null', () async {
      final readOnlyProvider = _TestProvider(loadItems: loadUseCase);
      final created = await readOnlyProvider.createItem(const _FakeItem('3', 'Gamma'));
      expect(created, isFalse);
      expect(readOnlyProvider.error, contains('not supported'));
    });

    test('refresh reloads current project', () async {
      await provider.loadItems('proj-1');
      loadUseCase.items = [const _FakeItem('1', 'Alpha Refreshed')];
      await provider.refresh();
      expect(provider.items.length, 1);
      expect(provider.items.first.name, 'Alpha Refreshed');
    });

    test('clear resets all state', () async {
      await provider.loadItems('proj-1');
      provider.clear();
      expect(provider.items, isEmpty);
      expect(provider.currentProjectId, isNull);
      expect(provider.error, isNull);
    });

    test('clearError only clears error', () async {
      loadUseCase.shouldThrow = true;
      await provider.loadItems('proj-1');
      expect(provider.error, isNotNull);
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('getById returns item from local list', () async {
      await provider.loadItems('proj-1');
      final item = provider.getById('2');
      expect(item?.name, 'Beta');
    });

    test('getById returns null for missing item', () async {
      await provider.loadItems('proj-1');
      expect(provider.getById('999'), isNull);
    });
  });
}
```

---

## Sub-phase 2.7: Verify
**Files:** (none modified)
**Agent**: `backend-data-layer-agent`

### Step 2.7.1: Run static analysis

```
pwsh -Command "flutter analyze"
```

Expect zero new warnings/errors from the files created in this phase.

### Step 2.7.2: Run tests

```
pwsh -Command "flutter test test/shared/domain/ test/shared/providers/base_use_case_list_provider_test.dart"
```

All tests must pass. If any fail, fix before proceeding.

### Step 2.7.3: Run full test suite to confirm no regressions

```
pwsh -Command "flutter test"
```

Since this phase is additive-only, zero existing tests should break.

---

## Summary of Created Files

| File | Purpose |
|------|---------|
| `lib/shared/domain/use_case.dart` | UseCase, NoParams, ProjectParams, IdParams base classes |
| `lib/shared/domain/use_case_result.dart` | Sealed UseCaseResult, Success, Failure, ErrorCode |
| `lib/shared/domain/domain.dart` | Barrel export for domain layer |
| `lib/shared/providers/base_use_case_list_provider.dart` | Parallel base provider accepting use cases |
| `test/shared/domain/use_case_test.dart` | Tests for UseCase base + param classes |
| `test/shared/domain/use_case_result_test.dart` | Tests for sealed result + pattern matching |
| `test/shared/providers/base_use_case_list_provider_test.dart` | Tests for provider CRUD + write guard |

## Migration Notes for Phase 3+

When migrating a feature (e.g., locations):
1. Create feature use cases: `lib/features/locations/domain/use_cases/get_locations.dart`
2. Each use case takes the existing abstract repository interface (e.g., `LocationRepository`)
3. Switch `LocationProvider` from `extends BaseListProvider<Location, LocationRepository>` to `extends BaseUseCaseListProvider<Location>`
4. Update provider constructor in `main.dart` to pass use case instances
5. Rename concrete repository to `LocationRepositoryImpl`, keep abstract as the interface
6. Repeat for all 5 providers, then delete `BaseListProvider`
