## Phase 3: CRUD Features Domain Layer (Batch)

Add domain layer with abstract repository interfaces and pass-through use cases for 9 CRUD-like features. Also add `dispose()` to providers and fix `catch(_)` / `catch (e)` blocks missing Logger calls.

**Pattern per feature:** (A) Create domain interface, (B) Rename concrete repo to `*Impl`, (C) Create pass-through use cases, (D) Update provider to reference interface type, (E) Add `dispose()`, (F) Fix catch blocks, (G) Update barrel exports and feature module wiring.

---

### Sub-phase 3.1: Locations (Reference Implementation)
**Agent:** `backend-data-layer-agent`

This sub-phase establishes the full pattern. All subsequent sub-phases replicate it.

#### Step 3.1.1: Create domain repository interface
**Create:** `lib/features/locations/domain/repositories/location_repository.dart`

```dart
import 'package:construction_inspector/features/locations/data/models/location.dart';
import 'package:construction_inspector/shared/models/paged_result.dart';
import 'package:construction_inspector/shared/repositories/base_repository.dart';

/// Domain interface for location data access.
///
/// Presentation layer depends on this interface, not the concrete implementation.
/// This enables testing with fakes and swapping implementations.
abstract class LocationRepository implements ProjectScopedRepository<Location> {
  // --- inherited from ProjectScopedRepository / BaseRepository ---
  // getById, getAll, getPaged, getCount, save, delete
  // getByProjectId, getByProjectIdPaged, getCountByProject, create, update

  /// Search locations by name within a project.
  Future<List<Location>> search(String projectId, String query);

  /// Update an existing location (named variant, delegates to update()).
  Future<RepositoryResult<Location>> updateLocation(Location location);

  /// Delete all locations for a project.
  Future<void> deleteByProjectId(String projectId);

  /// Insert multiple locations (for seeding/import).
  Future<void> insertAll(List<Location> locations);
}
```

Every public method from the current `LocationRepository` concrete class (15 methods) must appear in the interface. The inherited methods from `ProjectScopedRepository<Location>` cover: `getById`, `getAll`, `getPaged`, `getCount`, `save`, `delete`, `getByProjectId`, `getByProjectIdPaged`, `getCountByProject`, `create`, `update`. The remaining 4 feature-specific methods are declared explicitly.

#### Step 3.1.2: Rename concrete repository to LocationRepositoryImpl
**Rename:** `lib/features/locations/data/repositories/location_repository.dart` -> `lib/features/locations/data/repositories/location_repository_impl.dart`

- Rename class `LocationRepository` -> `LocationRepositoryImpl`
- Add `implements LocationRepository` (the domain interface)
- Add import: `import 'package:construction_inspector/features/locations/domain/repositories/location_repository.dart';`
- Keep all existing code unchanged

#### Step 3.1.3: Create pass-through use cases
**Create:** `lib/features/locations/domain/usecases/get_locations.dart`

```dart
class GetLocations {
  final LocationRepository _repository;
  GetLocations(this._repository);
  Future<List<Location>> call(String projectId) => _repository.getByProjectId(projectId);
}
```

**Create:** `lib/features/locations/domain/usecases/create_location.dart`

```dart
class CreateLocation {
  final LocationRepository _repository;
  CreateLocation(this._repository);
  Future<RepositoryResult<Location>> call(Location location) => _repository.create(location);
}
```

**Create:** `lib/features/locations/domain/usecases/update_location.dart`

```dart
class UpdateLocation {
  final LocationRepository _repository;
  UpdateLocation(this._repository);
  Future<RepositoryResult<Location>> call(Location location) => _repository.update(location);
}
```

**Create:** `lib/features/locations/domain/usecases/delete_location.dart`

```dart
class DeleteLocation {
  final LocationRepository _repository;
  DeleteLocation(this._repository);
  Future<void> call(String id) => _repository.delete(id);
}
```

**Create:** `lib/features/locations/domain/usecases/search_locations.dart`

```dart
class SearchLocations {
  final LocationRepository _repository;
  SearchLocations(this._repository);
  Future<List<Location>> call(String projectId, String query) => _repository.search(projectId, query);
}
```

These are intentionally thin pass-through wrappers. Business logic lives in the repository impl. Use cases exist to establish the pattern for when real cross-cutting concerns (logging, caching, auth checks) are added later.

#### Step 3.1.4: Update provider to use domain interface type
**Edit:** `lib/features/locations/presentation/providers/location_provider.dart`

- Change `BaseListProvider<Location, LocationRepository>` to `BaseListProvider<Location, LocationRepository>` (where `LocationRepository` now imports from the domain interface, not the concrete class)
- Update import from `data/repositories/location_repository.dart` to `domain/repositories/location_repository.dart`

**IMPORTANT:** The `BaseListProvider<T, R extends ProjectScopedRepository<T>>` generic constraint means the domain interface must extend `ProjectScopedRepository<Location>`, which it already does via `implements`.

#### Step 3.1.5: Add dispose() to LocationProvider
**Edit:** `lib/features/locations/presentation/providers/location_provider.dart`

Add at the end of the class:

```dart
@override
void dispose() {
  // Clean up any resources
  super.dispose();
}
```

Note: `BaseListProvider` does not override `dispose()` from `ChangeNotifier`, so subclasses should add it to ensure cleanup if subscriptions/timers are added later.

#### Step 3.1.6: Fix catch blocks in touched files
**Audit:** `location_repository_impl.dart` - No bare `catch(_)` blocks (current code has no try/catch). No changes needed for this feature.

#### Step 3.1.7: Create barrel exports for domain layer
**Create:** `lib/features/locations/domain/domain.dart`

```dart
export 'repositories/location_repository.dart';
export 'usecases/get_locations.dart';
export 'usecases/create_location.dart';
export 'usecases/update_location.dart';
export 'usecases/delete_location.dart';
export 'usecases/search_locations.dart';
```

**Create:** `lib/features/locations/domain/repositories/repositories.dart`

```dart
export 'location_repository.dart';
```

**Create:** `lib/features/locations/domain/usecases/usecases.dart`

```dart
export 'get_locations.dart';
export 'create_location.dart';
export 'update_location.dart';
export 'delete_location.dart';
export 'search_locations.dart';
```

**Edit:** `lib/features/locations/locations.dart` - Add `export 'domain/domain.dart';`

**Edit:** `lib/features/locations/data/repositories/repositories.dart` - Change export from `location_repository.dart` to `location_repository_impl.dart`

#### Step 3.1.8: Update all import references
**Global find-replace** across the codebase:
- Any file importing `features/locations/data/repositories/location_repository.dart` that uses the type `LocationRepository` (not `LocationRepositoryImpl`) should switch to importing from `features/locations/domain/repositories/location_repository.dart`
- Files that construct `LocationRepository(datasource)` must change to `LocationRepositoryImpl(datasource)` and import the impl
- Key files to check: `lib/main.dart`, any feature modules, test files

#### Step 3.1.9: Update existing tests
**Edit:** `test/features/locations/data/repositories/location_repository_test.dart`
- Rename class references from `LocationRepository` to `LocationRepositoryImpl`
- Update imports

#### Step 3.1.10: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/locations/"
```

---

### Sub-phase 3.2: Photos
**Agent:** `backend-data-layer-agent`

#### Step 3.2.1: Create domain repository interface
**Create:** `lib/features/photos/domain/repositories/photo_repository.dart`

```dart
abstract class PhotoRepository implements BaseRepository<Photo> {
  Future<RepositoryResult<Photo>> createPhoto(Photo photo);
  Future<RepositoryResult<Photo>> getPhotoById(String id);
  Future<RepositoryResult<List<Photo>>> getPhotosForEntry(String entryId);
  Future<RepositoryResult<List<Photo>>> getPhotosForProject(String projectId);
  Future<PagedResult<Photo>> getByProjectIdPaged(String projectId, {required int offset, required int limit});
  Future<RepositoryResult<Photo>> updatePhoto(Photo photo);
  Future<RepositoryResult<void>> deletePhoto(String id, {bool deleteFile = true});
  Future<RepositoryResult<void>> deletePhotosForEntry(String entryId, {bool deleteFiles = true});
  Future<RepositoryResult<int>> getPhotoCountForEntry(String entryId);
  Future<RepositoryResult<int>> getPhotoCountForProject(String projectId);
  Future<RepositoryResult<void>> updateEntryId(String photoId, String newEntryId);
}
```

Note: `PhotoRepository` implements `BaseRepository<Photo>` (not `ProjectScopedRepository`) because the existing concrete class does too. All 11 feature-specific methods plus 6 inherited from `BaseRepository`.

#### Step 3.2.2: Rename concrete to PhotoRepositoryImpl
**Rename:** `lib/features/photos/data/repositories/photo_repository.dart` -> `photo_repository_impl.dart`
- Class: `PhotoRepository` -> `PhotoRepositoryImpl implements PhotoRepository`

#### Step 3.2.3: Create pass-through use cases
**Create:** `lib/features/photos/domain/usecases/`
- `get_photos_for_entry.dart` - wraps `getPhotosForEntry`
- `get_photos_for_project.dart` - wraps `getPhotosForProject`
- `create_photo.dart` - wraps `createPhoto`
- `update_photo.dart` - wraps `updatePhoto`
- `delete_photo.dart` - wraps `deletePhoto`

#### Step 3.2.4: Update PhotoProvider to use domain interface
**Edit:** `lib/features/photos/presentation/providers/photo_provider.dart`
- Change `final PhotoRepository _repository;` type to import from domain interface
- Constructor type stays the same name but references the abstract class

#### Step 3.2.5: Add dispose() to PhotoProvider
**Edit:** `lib/features/photos/presentation/providers/photo_provider.dart`

```dart
@override
void dispose() {
  super.dispose();
}
```

#### Step 3.2.6: Fix catch blocks
**Audit** `photo_repository_impl.dart`: All catch blocks already have `Logger.photo(...)` calls. No changes needed.

#### Step 3.2.7: Create barrel exports + update feature module
**Create:** `lib/features/photos/domain/domain.dart`, `repositories/repositories.dart`, `usecases/usecases.dart`
**Edit:** `lib/features/photos/photos.dart` - add `export 'domain/domain.dart';`
**Edit:** `lib/features/photos/data/repositories/repositories.dart` - change to `photo_repository_impl.dart`

#### Step 3.2.8: Update imports across codebase
Key consumers: `PhotoProvider`, `GalleryProvider`, `lib/main.dart`, any screen that constructs `PhotoRepository`.
**CRITICAL:** `GalleryProvider` depends on `PhotoRepository` - must update to import from domain interface.

#### Step 3.2.9: Update tests
No existing `photo_repository_test.dart` found. No test changes needed.

#### Step 3.2.10: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/photos/"
```

---

### Sub-phase 3.3: Contractors
**Agent:** `backend-data-layer-agent`

#### Step 3.3.1: Create domain repository interface
**Create:** `lib/features/contractors/domain/repositories/contractor_repository.dart`

```dart
abstract class ContractorRepository implements ProjectScopedRepository<Contractor> {
  Future<Contractor?> getPrimeByProjectId(String projectId);
  Future<List<Contractor>> getSubsByProjectId(String projectId);
  Future<RepositoryResult<Contractor>> updateContractor(Contractor contractor);
  Future<void> deleteByProjectId(String projectId);
  Future<void> insertAll(List<Contractor> contractors);
  Future<List<String>> getMostFrequentIds(String projectId, {int limit = 5});
}
```

Inherited from `ProjectScopedRepository`: `getById`, `getAll`, `getPaged`, `getCount`, `save`, `delete`, `getByProjectId`, `getByProjectIdPaged`, `getCountByProject`, `create`, `update`.

#### Step 3.3.2: Rename concrete to ContractorRepositoryImpl
**Rename:** `lib/features/contractors/data/repositories/contractor_repository.dart` -> `contractor_repository_impl.dart`

#### Step 3.3.3: Create pass-through use cases
**Create:** `lib/features/contractors/domain/usecases/`
- `get_contractors.dart` - wraps `getByProjectId`
- `create_contractor.dart` - wraps `create`
- `update_contractor.dart` - wraps `update`
- `delete_contractor.dart` - wraps `delete`
- `get_frequent_contractor_ids.dart` - wraps `getMostFrequentIds`

#### Step 3.3.4: Update ContractorProvider to domain interface
**Edit:** `lib/features/contractors/presentation/providers/contractor_provider.dart`
- Change `BaseListProvider<Contractor, ContractorRepository>` import to domain interface
- Note: `loadFrequentContractorIds` accesses `repository.getMostFrequentIds` directly - this works because the interface exposes it

#### Step 3.3.5: Add dispose() to ContractorProvider
Already has `clear()` override; add `dispose()`.

#### Step 3.3.6: Fix catch blocks
**Audit** `contractor_provider.dart` line 76: `catch (e)` in `loadFrequentContractorIds` already has `Logger.db(...)`. No changes needed.

#### Step 3.3.7: Barrel exports + feature module
**Create:** `lib/features/contractors/domain/domain.dart`, `repositories/repositories.dart`, `usecases/usecases.dart`
**Edit:** `lib/features/contractors/contractors.dart` - add domain export
**Edit:** `lib/features/contractors/data/repositories/repositories.dart` - change `contractor_repository.dart` to `contractor_repository_impl.dart`

#### Step 3.3.8: Update imports + existing tests
**Edit:** `test/features/contractors/data/repositories/contractor_repository_test.dart` - rename references

#### Step 3.3.9: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/contractors/"
```

---

### Sub-phase 3.4: Equipment
**Agent:** `backend-data-layer-agent`

#### Step 3.4.1: Create domain repository interface
**Create:** `lib/features/contractors/domain/repositories/equipment_repository.dart`

Note: Equipment lives under contractors feature directory.

```dart
abstract class EquipmentRepository implements BaseRepository<Equipment> {
  Future<List<Equipment>> getByContractorId(String contractorId);
  Future<List<Equipment>> getByContractorIds(List<String> contractorIds);
  Future<RepositoryResult<Equipment>> create(Equipment equipment);
  Future<RepositoryResult<Equipment>> updateEquipment(Equipment equipment);
  Future<void> deleteByContractorId(String contractorId);
  Future<int> getCountByContractor(String contractorId);
  Future<List<Equipment>> getByContractorIdSortedByUsage(String contractorId, String projectId);
  Future<Map<String, int>> getUsageCountsByProject(String projectId);
  Future<void> insertAll(List<Equipment> equipment);
}
```

Note: `EquipmentRepository` implements `BaseRepository<Equipment>` (not `ProjectScopedRepository`) matching the existing concrete class.

#### Step 3.4.2: Rename concrete to EquipmentRepositoryImpl
**Rename:** `lib/features/contractors/data/repositories/equipment_repository.dart` -> `equipment_repository_impl.dart`

#### Step 3.4.3: Create pass-through use cases
**Create:** `lib/features/contractors/domain/usecases/`
- `get_equipment_for_contractor.dart`
- `create_equipment.dart`
- `update_equipment.dart`
- `delete_equipment.dart`

#### Step 3.4.4: Update EquipmentProvider to domain interface
**Edit:** `lib/features/contractors/presentation/providers/equipment_provider.dart`
- Change `final EquipmentRepository _repository;` import to domain interface

#### Step 3.4.5: Add dispose() to EquipmentProvider
Add `dispose()` override.

#### Step 3.4.6: Fix catch blocks
**Audit** `equipment_provider.dart`: Multiple `catch (e)` blocks (lines 66, 97, 174, 214, 239, 253) all set `_error` string but do NOT call Logger. **FIX:** Add `Logger.db(...)` call to each catch block:
- Line 66: `Logger.db('[EquipmentProvider] loadEquipmentForContractor error: $e');`
- Line 97-98: `Logger.db('[EquipmentProvider] loadEquipmentForContractors error: $e');`
- Line 132: `Logger.db('[EquipmentProvider] loadEquipmentForContractorsSortedByUsage error: $e');`
- Line 174: `Logger.db('[EquipmentProvider] createEquipment error: $e');`
- Line 214: `Logger.db('[EquipmentProvider] updateEquipment error: $e');`
- Line 239: `Logger.db('[EquipmentProvider] deleteEquipment error: $e');`
- Line 253: `Logger.db('[EquipmentProvider] deleteEquipmentForContractor error: $e');`

#### Step 3.4.7: Barrel exports
**Edit:** `lib/features/contractors/domain/repositories/repositories.dart` - add `equipment_repository.dart` export
**Edit:** `lib/features/contractors/domain/usecases/usecases.dart` - add equipment use case exports
**Edit:** `lib/features/contractors/data/repositories/repositories.dart` - change `equipment_repository.dart` to `equipment_repository_impl.dart`

#### Step 3.4.8: Update imports + tests
**Edit:** `test/features/contractors/data/repositories/equipment_repository_test.dart`

#### Step 3.4.9: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/contractors/"
```

---

### Sub-phase 3.5: PersonnelTypes
**Agent:** `backend-data-layer-agent`

#### Step 3.5.1: Create domain repository interface
**Create:** `lib/features/contractors/domain/repositories/personnel_type_repository.dart`

```dart
abstract class PersonnelTypeRepository implements ProjectScopedRepository<PersonnelType> {
  Future<List<PersonnelType>> getByContractor(String projectId, String contractorId);
  Future<RepositoryResult<PersonnelType>> updateType(PersonnelType type);
  Future<void> deleteByProjectId(String projectId);
  Future<void> reorderTypes(String projectId, List<String> orderedIds);
  Future<int> getNextSortOrderForContractor(String projectId, String contractorId);
  Future<int> getNextSortOrder(String projectId);
  Future<void> insertAll(List<PersonnelType> types);
}
```

#### Step 3.5.2: Rename concrete to PersonnelTypeRepositoryImpl
**Rename:** `lib/features/contractors/data/repositories/personnel_type_repository.dart` -> `personnel_type_repository_impl.dart`

#### Step 3.5.3: Create pass-through use cases
**Create:** `lib/features/contractors/domain/usecases/`
- `get_personnel_types.dart`
- `create_personnel_type.dart`
- `update_personnel_type.dart`
- `delete_personnel_type.dart`

#### Step 3.5.4: Update PersonnelTypeProvider to domain interface
**Edit:** `lib/features/contractors/presentation/providers/personnel_type_provider.dart`
- Change `BaseListProvider<PersonnelType, PersonnelTypeRepository>` import to domain interface
- Note: `loadTypesForContractor` and `createDefaultTypesForContractor` access `repository.getByContractor` and `repository.create` - both must be on the interface

#### Step 3.5.5: Add dispose() to PersonnelTypeProvider

#### Step 3.5.6: Fix catch blocks
**Audit** `personnel_type_provider.dart`:
- Line 79: `rethrow;` in `loadTypesForContractor` - acceptable, but the comment says "Error will be handled by calling code". Consider adding `Logger.db(...)` before rethrow.
- Line 227: `catch (e)` in `reorderTypes` - no Logger call. **FIX:** Add `Logger.db('[PersonnelTypeProvider] reorderTypes error: $e');`

#### Step 3.5.7: Barrel exports
**Edit:** `lib/features/contractors/domain/repositories/repositories.dart` - add `personnel_type_repository.dart`
**Edit:** `lib/features/contractors/data/repositories/repositories.dart` - change to `personnel_type_repository_impl.dart`

#### Step 3.5.8: Update imports + tests
**Edit:** `test/features/contractors/data/repositories/personnel_type_repository_test.dart`

#### Step 3.5.9: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/contractors/"
```

---

### Sub-phase 3.6: BidItems (Quantities)
**Agent:** `backend-data-layer-agent`

#### Step 3.6.1: Extract domain types from provider
**Move** `DuplicateStrategy` enum and `ImportBatchResult` class from `lib/features/quantities/presentation/providers/bid_item_provider.dart` to:
**Create:** `lib/features/quantities/domain/models/import_batch_result.dart`

These are domain concepts (import strategy, batch result) that do not belong in the presentation layer. The provider file keeps using them via import.

#### Step 3.6.2: Create domain repository interface
**Create:** `lib/features/quantities/domain/repositories/bid_item_repository.dart`

```dart
abstract class BidItemRepository implements ProjectScopedRepository<BidItem> {
  Future<BidItem?> getByItemNumber(String projectId, String itemNumber);
  Future<List<BidItem>> search(String projectId, String query);
  Future<RepositoryResult<BidItem>> updateBidItem(BidItem bidItem);
  Future<void> deleteByProjectId(String projectId);
  Future<void> insertAll(List<BidItem> bidItems);
}
```

#### Step 3.6.3: Rename concrete to BidItemRepositoryImpl
**Rename:** `lib/features/quantities/data/repositories/bid_item_repository.dart` -> `bid_item_repository_impl.dart`

#### Step 3.6.4: Create pass-through use cases
**Create:** `lib/features/quantities/domain/usecases/`
- `get_bid_items.dart`
- `create_bid_item.dart`
- `update_bid_item.dart`
- `delete_bid_item.dart`
- `search_bid_items.dart`
- `import_bid_items.dart` - wraps `insertAll` (batch import)

#### Step 3.6.5: Update BidItemProvider
**Edit:** `lib/features/quantities/presentation/providers/bid_item_provider.dart`
- Change `BaseListProvider<BidItem, BidItemRepository>` import to domain interface
- Replace inline `DuplicateStrategy`/`ImportBatchResult` with import from domain models
- Remove the class/enum definitions from this file (moved in 3.6.1)

#### Step 3.6.6: Add dispose() to BidItemProvider
Override `dispose()` with `super.dispose()`.

#### Step 3.6.7: Fix catch blocks
**Audit** `bid_item_provider.dart`:
- Line 274: `catch (e, stack)` in `importBatch` insertAll - already has `Logger.error(...)`. OK.
- Line 288: `catch (e)` in importBatch replace loop - no Logger. **FIX:** Add `Logger.db('[BidItemProvider] importBatch replace error: $e');`
- Line 339: `catch (e)` in `loadItemsPaged` - no Logger. **FIX:** Add `Logger.db('[BidItemProvider] loadItemsPaged error: $e');`
- Line 402: `catch (e)` in `loadMoreItems` - no Logger. **FIX:** Add `Logger.db('[BidItemProvider] loadMoreItems error: $e');`

#### Step 3.6.8: Barrel exports + feature module
**Create:** `lib/features/quantities/domain/domain.dart`, `repositories/repositories.dart`, `models/models.dart`, `usecases/usecases.dart`
**Edit:** `lib/features/quantities/quantities.dart` - add domain export
**Edit:** `lib/features/quantities/data/repositories/repositories.dart` - change to `bid_item_repository_impl.dart`

#### Step 3.6.9: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/quantities/"
```

---

### Sub-phase 3.7: EntryQuantities
**Agent:** `backend-data-layer-agent`

#### Step 3.7.1: Create domain repository interface
**Create:** `lib/features/quantities/domain/repositories/entry_quantity_repository.dart`

```dart
abstract class EntryQuantityRepository implements BaseRepository<EntryQuantity> {
  Future<List<EntryQuantity>> getByEntryId(String entryId);
  Future<List<EntryQuantity>> getByBidItemId(String bidItemId);
  Future<double> getTotalUsedForBidItem(String bidItemId);
  Future<Map<String, double>> getTotalUsedByProject(String projectId);
  Future<RepositoryResult<EntryQuantity>> create(EntryQuantity quantity);
  Future<RepositoryResult<EntryQuantity>> updateQuantity(EntryQuantity quantity);
  Future<void> deleteByEntryId(String entryId);
  Future<void> deleteByBidItemId(String bidItemId);
  Future<int> getCountByEntry(String entryId);
  Future<void> insertAll(List<EntryQuantity> quantities);
  Future<RepositoryResult<void>> saveQuantitiesForEntry(String entryId, List<EntryQuantity> quantities);
}
```

Note: Implements `BaseRepository<EntryQuantity>` (not `ProjectScopedRepository`) matching existing.

#### Step 3.7.2: Rename concrete to EntryQuantityRepositoryImpl
**Rename:** `lib/features/quantities/data/repositories/entry_quantity_repository.dart` -> `entry_quantity_repository_impl.dart`

#### Step 3.7.3: Create pass-through use cases
**Create:** `lib/features/quantities/domain/usecases/`
- `get_entry_quantities.dart` - wraps `getByEntryId`
- `save_entry_quantities.dart` - wraps `saveQuantitiesForEntry`
- `get_total_used_by_project.dart` - wraps `getTotalUsedByProject`

#### Step 3.7.4: Update EntryQuantityProvider to domain interface
**Edit:** `lib/features/quantities/presentation/providers/entry_quantity_provider.dart`
- Change `final EntryQuantityRepository _repository;` import to domain interface

#### Step 3.7.5: Add dispose() to EntryQuantityProvider

#### Step 3.7.6: Fix catch blocks
**Audit** `entry_quantity_provider.dart`: Multiple `catch (e)` blocks (lines 63, 81, 121, 164, 199, 219, 265). All set `_error` but none call Logger. **FIX all:**
- Add `Logger.db('[EntryQuantityProvider] <methodName> error: $e');` to each catch block

#### Step 3.7.7: Barrel exports
**Edit:** `lib/features/quantities/domain/repositories/repositories.dart` - add `entry_quantity_repository.dart`
**Edit:** `lib/features/quantities/data/repositories/repositories.dart` - change to `entry_quantity_repository_impl.dart`

#### Step 3.7.8: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/quantities/"
```

---

### Sub-phase 3.8: Todos
**Agent:** `backend-data-layer-agent`

This feature has NO repository - the provider talks directly to the datasource. We must create both a repository and domain interface.

#### Step 3.8.1: Create concrete TodoItemRepository
**Create:** `lib/features/todos/data/repositories/todo_item_repository_impl.dart`

```dart
class TodoItemRepositoryImpl implements TodoItemRepository {
  final TodoItemLocalDatasource _localDatasource;
  TodoItemRepositoryImpl(this._localDatasource);

  Future<TodoItem?> getById(String id) => _localDatasource.getById(id);
  Future<List<TodoItem>> getAll() => _localDatasource.getAll();
  Future<List<TodoItem>> getByProjectId(String projectId) => _localDatasource.getByProjectId(projectId);
  Future<List<TodoItem>> getByEntryId(String entryId) => _localDatasource.getByEntryId(entryId);
  Future<List<TodoItem>> getIncomplete({String? projectId}) => _localDatasource.getIncomplete(projectId: projectId);
  Future<List<TodoItem>> getCompleted({String? projectId}) => _localDatasource.getCompleted(projectId: projectId);
  Future<List<TodoItem>> getByPriority(TodoPriority priority, {String? projectId}) =>
      _localDatasource.getByPriority(priority, projectId: projectId);
  Future<List<TodoItem>> getOverdue({String? projectId}) => _localDatasource.getOverdue(projectId: projectId);
  Future<List<TodoItem>> getDueToday({String? projectId}) => _localDatasource.getDueToday(projectId: projectId);
  Future<TodoItem> create(TodoItem todo) => _localDatasource.create(todo);
  Future<void> save(TodoItem item) async {
    final existing = await _localDatasource.getById(item.id);
    if (existing == null) {
      await _localDatasource.insert(item);
    } else {
      await _localDatasource.update(item);
    }
  }
  Future<void> update(TodoItem todo) => _localDatasource.update(todo);
  Future<TodoItem> toggleComplete(String id) => _localDatasource.toggleComplete(id);
  Future<void> delete(String id) => _localDatasource.deleteTodo(id);
  Future<int> deleteByProjectId(String projectId) => _localDatasource.deleteByProjectId(projectId);
  Future<int> deleteCompleted({String? projectId}) => _localDatasource.deleteCompleted(projectId: projectId);
  Future<int> getIncompleteCount({String? projectId}) => _localDatasource.getIncompleteCount(projectId: projectId);
  // BaseRepository stubs
  Future<int> getCount() => _localDatasource.getCount();
  Future<PagedResult<TodoItem>> getPaged({required int offset, required int limit}) =>
      _localDatasource.getPaged(offset: offset, limit: limit);
}
```

#### Step 3.8.2: Create domain repository interface
**Create:** `lib/features/todos/domain/repositories/todo_item_repository.dart`

```dart
abstract class TodoItemRepository {
  Future<TodoItem?> getById(String id);
  Future<List<TodoItem>> getAll();
  Future<List<TodoItem>> getByProjectId(String projectId);
  Future<List<TodoItem>> getByEntryId(String entryId);
  Future<List<TodoItem>> getIncomplete({String? projectId});
  Future<List<TodoItem>> getCompleted({String? projectId});
  Future<List<TodoItem>> getByPriority(TodoPriority priority, {String? projectId});
  Future<List<TodoItem>> getOverdue({String? projectId});
  Future<List<TodoItem>> getDueToday({String? projectId});
  Future<TodoItem> create(TodoItem todo);
  Future<void> save(TodoItem item);
  Future<void> update(TodoItem todo);
  Future<TodoItem> toggleComplete(String id);
  Future<void> delete(String id);
  Future<int> deleteByProjectId(String projectId);
  Future<int> deleteCompleted({String? projectId});
  Future<int> getIncompleteCount({String? projectId});
}
```

Note: Does NOT extend `BaseRepository` or `ProjectScopedRepository` since the existing datasource API doesn't match those patterns (e.g., `create` returns `TodoItem`, not `RepositoryResult`). Keep it simple; upgrade to `ProjectScopedRepository` in a future phase if needed.

#### Step 3.8.3: Create pass-through use cases
**Create:** `lib/features/todos/domain/usecases/`
- `get_todos.dart` - wraps `getByProjectId`
- `create_todo.dart` - wraps `create`
- `toggle_todo.dart` - wraps `toggleComplete`
- `delete_todo.dart` - wraps `delete`

#### Step 3.8.4: Update TodoProvider to use repository
**Edit:** `lib/features/todos/presentation/providers/todo_provider.dart`
- Change `final TodoItemLocalDatasource _datasource;` to `final TodoItemRepository _repository;`
- Replace all `_datasource.xxx()` calls with `_repository.xxx()` method calls
- Update constructor: `TodoProvider(this._repository);`
- The method signatures on the interface match the datasource, so the call sites inside the provider are 1:1 renames

#### Step 3.8.5: Add dispose() to TodoProvider

#### Step 3.8.6: Fix catch blocks
**Audit** `todo_provider.dart`: All `catch (e)` blocks already have `Logger.ui(...)` calls. No changes needed.

#### Step 3.8.7: Barrel exports + feature module
**Create:** `lib/features/todos/data/repositories/repositories.dart` (new - didn't exist before)

```dart
export 'todo_item_repository_impl.dart';
```

**Create:** `lib/features/todos/domain/domain.dart`, `repositories/repositories.dart`, `usecases/usecases.dart`
**Edit:** `lib/features/todos/todos.dart` - add domain and data/repositories exports, remove direct datasource export from barrel (provider no longer uses it directly)

#### Step 3.8.8: Update main.dart and wiring
Where `TodoProvider(todoItemLocalDatasource)` is constructed, change to `TodoProvider(TodoItemRepositoryImpl(todoItemLocalDatasource))`.

#### Step 3.8.9: Update tests
**Edit:** `test/features/todos/data/datasources/todo_item_local_datasource_test.dart` - no changes (tests datasource directly)
May need to create `test/features/todos/data/repositories/todo_item_repository_impl_test.dart` if coverage requirements demand it - but since it is pure pass-through, defer to a future phase.

#### Step 3.8.10: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/todos/"
```

---

### Sub-phase 3.9: Calculator
**Agent:** `backend-data-layer-agent`

Same pattern as Todos - no repository exists, provider uses datasource directly.

#### Step 3.9.1: Create concrete CalculationHistoryRepository
**Create:** `lib/features/calculator/data/repositories/calculation_history_repository_impl.dart`

```dart
class CalculationHistoryRepositoryImpl implements CalculationHistoryRepository {
  final CalculationHistoryLocalDatasource _localDatasource;
  CalculationHistoryRepositoryImpl(this._localDatasource);

  Future<CalculationHistory?> getById(String id) => _localDatasource.getById(id);
  Future<List<CalculationHistory>> getAll() => _localDatasource.getAll();
  Future<List<CalculationHistory>> getByProjectId(String projectId) => _localDatasource.getByProjectId(projectId);
  Future<List<CalculationHistory>> getByEntryId(String entryId) => _localDatasource.getByEntryId(entryId);
  Future<List<CalculationHistory>> getByType(CalculationType type) => _localDatasource.getByType(type);
  Future<List<CalculationHistory>> getRecent({int limit = 10}) => _localDatasource.getRecent(limit: limit);
  Future<CalculationHistory> create(CalculationHistory calculation) => _localDatasource.create(calculation);
  Future<void> save(CalculationHistory item) async {
    final existing = await _localDatasource.getById(item.id);
    if (existing == null) {
      await _localDatasource.insert(item);
    } else {
      await _localDatasource.update(item);
    }
  }
  Future<void> delete(String id) async { await _localDatasource.deleteCalculation(id); }
  Future<int> deleteByProjectId(String projectId) => _localDatasource.deleteByProjectId(projectId);
}
```

#### Step 3.9.2: Create domain repository interface
**Create:** `lib/features/calculator/domain/repositories/calculation_history_repository.dart`

```dart
abstract class CalculationHistoryRepository {
  Future<CalculationHistory?> getById(String id);
  Future<List<CalculationHistory>> getAll();
  Future<List<CalculationHistory>> getByProjectId(String projectId);
  Future<List<CalculationHistory>> getByEntryId(String entryId);
  Future<List<CalculationHistory>> getByType(CalculationType type);
  Future<List<CalculationHistory>> getRecent({int limit = 10});
  Future<CalculationHistory> create(CalculationHistory calculation);
  Future<void> save(CalculationHistory item);
  Future<void> delete(String id);
  Future<int> deleteByProjectId(String projectId);
}
```

#### Step 3.9.3: Create pass-through use cases
**Create:** `lib/features/calculator/domain/usecases/`
- `get_calculation_history.dart` - wraps `getByProjectId` / `getRecent`
- `save_calculation.dart` - wraps `create`
- `delete_calculation.dart` - wraps `delete`

#### Step 3.9.4: Update CalculatorProvider to use repository
**Edit:** `lib/features/calculator/presentation/providers/calculator_provider.dart`
- Change `final CalculationHistoryLocalDatasource _datasource;` to `final CalculationHistoryRepository _repository;`
- Replace all `_datasource.xxx()` calls with `_repository.xxx()`
- Update constructor

#### Step 3.9.5: Add dispose() to CalculatorProvider

#### Step 3.9.6: Fix catch blocks
**Audit** `calculator_provider.dart`: All `catch (e)` blocks already have `Logger.ui(...)` calls. No changes needed.

#### Step 3.9.7: Barrel exports + feature module
**Create:** `lib/features/calculator/data/repositories/repositories.dart`
**Create:** `lib/features/calculator/domain/domain.dart`, `repositories/repositories.dart`, `usecases/usecases.dart`
**Edit:** `lib/features/calculator/calculator.dart` - add domain and data/repositories exports

#### Step 3.9.8: Update main.dart wiring
Change `CalculatorProvider(calculationHistoryLocalDatasource)` to `CalculatorProvider(CalculationHistoryRepositoryImpl(calculationHistoryLocalDatasource))`.

#### Step 3.9.9: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/calculator/"
```

---

### Sub-phase 3.10: Gallery (Cross-Feature Consumer)
**Agent:** `backend-data-layer-agent`

Gallery has no datasource or repository of its own. It consumes `PhotoRepository` and `DailyEntryRepository` from other features. The domain layer here consists of use cases only.

#### Step 3.10.1: Create gallery-specific use cases
**Create:** `lib/features/gallery/domain/usecases/get_gallery_photos.dart`

```dart
class GetGalleryPhotos {
  final PhotoRepository _photoRepository;
  GetGalleryPhotos(this._photoRepository);
  Future<RepositoryResult<List<Photo>>> call(String projectId) =>
      _photoRepository.getPhotosForProject(projectId);
}
```

**Create:** `lib/features/gallery/domain/usecases/get_gallery_entries.dart`

```dart
class GetGalleryEntries {
  final DailyEntryRepository _entryRepository;
  GetGalleryEntries(this._entryRepository);
  Future<List<DailyEntry>> call(String projectId) =>
      _entryRepository.getByProjectId(projectId);
}
```

Note: `DailyEntryRepository` is not being refactored in this phase (it's in the entries feature and not one of the 9 CRUD features). The gallery use case references the existing concrete type. When entries gets its domain layer in a future phase, this import will update.

#### Step 3.10.2: Update GalleryProvider
**Edit:** `lib/features/gallery/presentation/providers/gallery_provider.dart`
- Change `PhotoRepository` import to domain interface (from sub-phase 3.2)
- `DailyEntryRepository` stays as-is (concrete, not refactored this phase)

#### Step 3.10.3: Add dispose() to GalleryProvider

#### Step 3.10.4: Fix catch blocks
**Audit** `gallery_provider.dart`:
- Line 74: `catch (e)` in `loadPhotosForProject` - has Logger call. OK.

No additional fixes needed.

#### Step 3.10.5: Barrel exports
**Create:** `lib/features/gallery/domain/domain.dart`, `usecases/usecases.dart`
**Edit:** `lib/features/gallery/gallery.dart` - add domain export

#### Step 3.10.6: Verify
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test"
```

---

### Sub-phase 3.11: Final Integration Verification
**Agent:** `backend-data-layer-agent`

#### Step 3.11.1: Full static analysis
```
pwsh -Command "flutter analyze"
```
Fix any remaining import errors, type mismatches, or missing exports.

#### Step 3.11.2: Full test suite
```
pwsh -Command "flutter test"
```
Fix any test failures caused by renamed types or changed imports.

#### Step 3.11.3: Verify BaseListProvider generic constraint compatibility
Confirm that all `BaseListProvider<T, R>` subclasses still compile with `R` being the domain interface (which extends/implements `ProjectScopedRepository<T>`):
- `LocationProvider<Location, LocationRepository>` (domain interface)
- `ContractorProvider<Contractor, ContractorRepository>` (domain interface)
- `PersonnelTypeProvider<PersonnelType, PersonnelTypeRepository>` (domain interface)
- `BidItemProvider<BidItem, BidItemRepository>` (domain interface)

The key constraint is `R extends ProjectScopedRepository<T>` on `BaseListProvider`. The domain interfaces must all extend/implement `ProjectScopedRepository<T>` for this to work. Equipment and EntryQuantity providers do NOT use `BaseListProvider` (they extend `ChangeNotifier` directly), so they are unaffected.

---

### Summary of new files created (per feature):

| Feature | domain/repositories/ | domain/usecases/ | domain/models/ | data/repositories/ (renamed) |
|---------|---------------------|-------------------|----------------|------------------------------|
| locations | `location_repository.dart` | 5 use cases | - | `location_repository_impl.dart` |
| photos | `photo_repository.dart` | 5 use cases | - | `photo_repository_impl.dart` |
| contractors | `contractor_repository.dart` | 5 use cases | - | `contractor_repository_impl.dart` |
| equipment | `equipment_repository.dart` | 4 use cases | - | `equipment_repository_impl.dart` |
| personnel_types | `personnel_type_repository.dart` | 4 use cases | - | `personnel_type_repository_impl.dart` |
| bid_items | `bid_item_repository.dart` | 6 use cases | `import_batch_result.dart` | `bid_item_repository_impl.dart` |
| entry_quantities | `entry_quantity_repository.dart` | 3 use cases | - | `entry_quantity_repository_impl.dart` |
| todos | `todo_item_repository.dart` | 4 use cases | - | `todo_item_repository_impl.dart` (NEW) |
| calculator | `calculation_history_repository.dart` | 3 use cases | - | `calculation_history_repository_impl.dart` (NEW) |
| gallery | - | 2 use cases | - | - (no repo) |

**Total new files:** ~9 interfaces + ~41 use cases + 1 extracted model + ~9 renamed impls + ~27 barrel files = ~87 files
**Total modified files:** ~9 providers + ~4 test files + barrel exports + main.dart wiring = ~20 files

### Catch block fixes summary:
| File | Fixes needed |
|------|-------------|
| `equipment_provider.dart` | 7 catch blocks missing Logger |
| `entry_quantity_provider.dart` | 7 catch blocks missing Logger |
| `bid_item_provider.dart` | 2 catch blocks missing Logger |
| `personnel_type_provider.dart` | 1 catch block missing Logger |
