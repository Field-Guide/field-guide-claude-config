# Pattern: Repository Result Pattern

## How We Do It
Every repository implementation wraps datasource calls in try/catch and returns `RepositoryResult.success()` or `RepositoryResult.failure()`. The pattern is identical across 10+ repositories with 5-20 methods each, differing only in the datasource method and error context string.

## Exemplars

### FormResponseRepositoryImpl (lib/features/forms/data/repositories/form_response_repository.dart:10)

Canonical example — 21 catch violations. Simple methods are pure wrappers:

```dart
Future<RepositoryResult<List<FormResponse>>> getResponsesForForm(String formId) async {
  try {
    final responses = await _localDatasource.getByFormId(formId);
    return RepositoryResult.success(responses);
  } catch (e) {                    // <-- avoid_catches_without_on_clauses
    Logger.db('FormResponseRepository.getResponsesForForm error: $e');
    return RepositoryResult.failure('Error retrieving responses: $e');
  }
}
```

Complex methods add validation before the datasource call:
```dart
Future<RepositoryResult<FormResponse>> createResponse(FormResponse response) async {
  try {
    if (response.formId.trim().isEmpty) {
      return RepositoryResult.failure('Form ID is required');
    }
    if (response.projectId.trim().isEmpty) {
      return RepositoryResult.failure('Project ID is required');
    }
    final created = await _localDatasource.create(response);
    return RepositoryResult.success(created);
  } catch (e) {
    Logger.db('FormResponseRepository.createResponse error: $e');
    return RepositoryResult.failure('Error creating response: $e');
  }
}
```

### RepositoryResult (lib/shared/repositories/base_repository.dart:56)

The result wrapper itself:
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

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `RepositoryResult.success` | base_repository.dart:67 | `factory RepositoryResult.success(T data)` | Wrap successful result |
| `RepositoryResult.failure` | base_repository.dart:71 | `factory RepositoryResult.failure(String error)` | Wrap error with message |
| `RepositoryResult.empty` | base_repository.dart:75 | `factory RepositoryResult.empty()` | Success with no data |
| `Logger.db` | logger.dart (static) | `static void db(String message, {...})` | Log database operations |

## Imports
```dart
import 'package:construction_inspector/shared/repositories/base_repository.dart';
import 'package:construction_inspector/core/logging/logger.dart';
```
