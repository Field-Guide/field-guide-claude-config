# Pattern: Repository

## How We Do It
Repositories wrap one or more datasources behind a domain API. They live in `features/<feature>/data/repositories/` for implementations and `features/<feature>/domain/repositories/` for interfaces. Constructor injection of datasources. Registered in the feature's DI initializer and provided via Provider.

## Exemplars

### ContractorRepository (`lib/features/contractors/domain/repositories/contractor_repository.dart`)
Interface pattern — abstract class in domain/, impl in data/:
```dart
abstract class ContractorRepository {
  Future<List<Contractor>> getByProjectId(String projectId);
  Future<Contractor?> getById(String id);
  Future<void> save(Contractor contractor);
  Future<void> delete(String id);
}
```

### FormResponseRepositoryImpl (`lib/features/forms/data/repositories/form_response_repository.dart`)
Implementation wrapping local + remote datasources:
```dart
class FormResponseRepositoryImpl implements FormResponseRepository {
  final FormResponseLocalDatasource _localDatasource;
  final FormResponseRemoteDatasource? _remoteDatasource;

  FormResponseRepositoryImpl({
    required FormResponseLocalDatasource localDatasource,
    FormResponseRemoteDatasource? remoteDatasource,
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource;
  // ... domain methods that delegate to datasources
}
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `getByProjectId` | varies per repository | `Future<List<T>> getByProjectId(String projectId)` | Standard project-scoped fetch |
| `save` / `upsert` | varies per repository | `Future<void> save(T item)` | Create or update |

## Imports
```dart
import 'package:construction_inspector/features/<feature>/domain/repositories/<name>_repository.dart';
import 'package:construction_inspector/features/<feature>/data/datasources/local/<name>_local_datasource.dart';
```
