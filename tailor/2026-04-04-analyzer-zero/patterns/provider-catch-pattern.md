# Pattern: Provider Catch Pattern

## How We Do It
Every ChangeNotifier provider wraps async operations in a try/catch/finally block that manages `_isLoading`, `_error`, and `notifyListeners()`. The pattern is identical across 30+ providers with 5-12 methods each, differing only in the repository call and error label.

## Exemplars

### TodoProvider (lib/features/todos/presentation/providers/todo_provider.dart)

Standalone provider (does NOT extend BaseListProvider). Every method follows this pattern:

```dart
Future<void> loadTodos({String? projectId}) async {
  _isLoading = true;
  _error = null;
  _currentProjectId = projectId;
  notifyListeners();

  try {
    if (projectId != null) {
      _todos = await _repository.getByProjectId(projectId);
    } else {
      _todos = await _repository.getAll();
    }
  } catch (e) {                    // <-- avoid_catches_without_on_clauses
    _error = 'Failed to load todos: $e';
    Logger.ui('[Todo] $_error');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

Write operations add `canWrite()` guard:
```dart
Future<bool> createTodo({...}) async {
  if (!canWrite()) {
    Logger.ui('[TodoProvider] createTodo blocked: canWrite returned false');
    return false;
  }
  try {
    // ... create logic
    return true;
  } catch (e) {                    // <-- avoid_catches_without_on_clauses
    _error = 'Failed to create todo: $e';
    Logger.ui('[Todo] $_error');
    notifyListeners();
    return false;
  }
}
```

### BaseListProvider (lib/shared/providers/base_list_provider.dart:14)

Abstract base used by 6 providers. Same pattern in loadItems(), createItem(), updateItem(), deleteItem():

```dart
Future<void> loadItems(String projectId) async {
  _currentProjectId = projectId;
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    _items = await repository.getByProjectId(projectId);
    _error = null;
  } catch (e, stack) {            // <-- avoid_catches_without_on_clauses
    Logger.error('Failed to load ${entityName}s', error: e, stack: stack, category: 'db');
    _error = 'Failed to load ${entityName}s: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `loadItems` | base_list_provider.dart:69 | `Future<void> loadItems(String projectId)` | Load all items for project |
| `createItem` | base_list_provider.dart:92 | `Future<bool> createItem(T item)` | Create with result tracking |
| `updateItem` | base_list_provider.dart:118 | `Future<bool> updateItem(T item)` | Update with result tracking |
| `deleteItem` | base_list_provider.dart:147 | `Future<bool> deleteItem(String id)` | Delete with result tracking |
| `checkWritePermission` | base_list_provider.dart:200 | `bool checkWritePermission(String action)` | Guard write ops |
| `clearError` | base_list_provider.dart:189 | `void clearError()` | Clear error state |

## Imports
```dart
import 'package:flutter/foundation.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/shared/repositories/base_repository.dart';
```
