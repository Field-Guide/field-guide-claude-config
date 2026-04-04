# Source Excerpts by File

## lib/shared/repositories/base_repository.dart

### BaseRepository (line 7)
```dart
abstract class BaseRepository<T> {
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<void> save(T item);
  Future<void> delete(String id);
  Future<int> getCount();
  Future<PagedResult<T>> getPaged({required int offset, required int limit});
}
```

### ProjectScopedRepository (line 34)
```dart
abstract class ProjectScopedRepository<T> extends BaseRepository<T> {
  Future<List<T>> getByProjectId(String projectId);
  Future<RepositoryResult<T>> create(T item);
  Future<RepositoryResult<T>> update(T item);
  Future<PagedResult<T>> getByProjectIdPaged(String projectId, {required int offset, required int limit});
}
```

### RepositoryResult (line 56)
```dart
class RepositoryResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const RepositoryResult._({this.data, this.error, required this.isSuccess});
  factory RepositoryResult.success(T data) => RepositoryResult._(data: data, isSuccess: true);
  factory RepositoryResult.failure(String error) => RepositoryResult._(error: error, isSuccess: false);
  factory RepositoryResult.empty() => const RepositoryResult._(isSuccess: true);
}
```

## lib/shared/providers/base_list_provider.dart (line 14, full source)

See patterns/provider-catch-pattern.md for annotated source. Key fields:
- `_items`, `_currentProjectId`, `_isLoading`, `_error`
- Methods: `loadItems`, `createItem`, `updateItem`, `deleteItem`, `getById`, `clearError`, `clear`, `checkWritePermission`
- `canWrite` callback (set by main.dart)
- 4 catch violations (lines 75, 105, 131, 156)

## lib/features/pdf/services/extraction/stages/stage_names.dart (line 5, full source)

See patterns/stage-names-pattern.md for complete constant listing. 30 constants total.

## lib/features/todos/presentation/providers/todo_provider.dart (line 33)

Full standalone provider with 12 catch violations. See patterns/provider-catch-pattern.md for annotated exemplar.

Key methods with catches: `loadTodos`, `createTodo`, `updateTodo`, `toggleComplete`, `deleteTodo`, `deleteCompleted`, `getByEntryId`, `loadByPriority`, `loadOverdue`, `loadDueToday`, `getIncompleteCount`, `deleteByProject`

## lib/features/forms/data/repositories/form_response_repository.dart (line 10)

Full repository with 21 catch violations. See patterns/repository-result-pattern.md for annotated exemplar.

Key methods with catches: `createResponse`, `getResponseById`, `getResponsesForForm`, `getResponsesForEntry`, `getResponsesForProject`, `getResponsesByStatus`, `getResponsesByProjectAndStatus`, `updateResponse`, `submitResponse`, `markAsExported`, `deleteResponse`, `deleteResponsesForEntry`, `getResponseCountForForm`, `getResponseCountForEntry`, `getResponseCountForProject`, `getRecentResponses`, `getAll`, `save`, `getCount`, `getPaged`, `getFormTypeForResponse`

## lib/features/locations/data/models/location.dart (line 32)

CopyWith sentinel exemplar. See patterns/copywith-sentinel-pattern.md.
