# Blast Radius

## RepositoryResult (Phase 5: Adding safeCall)

**Risk Score**: 0.79 (high — 111 total importers)

Adding a static method (`safeCall`) is **additive only** — zero blast radius for existing code. No existing call sites change. New call sites adopt it during repository refactor.

| Category | Count |
|----------|-------|
| Direct importers (confirmed name ref) | 49 |
| Potential importers (barrel/wildcard) | 62 |
| **Total** | **111** |

### Confirmed References by Feature

| Feature | Files | References |
|---------|-------|-----------|
| forms | 12 | 144 |
| entries | 10 | 46 |
| photos | 3 | 77 |
| contractors | 6 | 28 |
| quantities | 4 | 23 |
| projects | 2 | 9 |
| locations | 2 | 9 |
| tests | 10 | 163 |

### Repositories That Will Adopt safeCall (Phase 5)

| Repository | File | Current catch count |
|------------|------|:---:|
| FormResponseRepositoryImpl | `form_response_repository.dart` | 21 |
| InspectorFormRepositoryImpl | `inspector_form_repository.dart` | 13 |
| PhotoRepositoryImpl | `photo_repository_impl.dart` | 12 |
| ContractorRepositoryImpl | `contractor_repository_impl.dart` | ~8 |
| EquipmentRepositoryImpl | `equipment_repository_impl.dart` | ~7 |
| PersonnelTypeRepositoryImpl | `personnel_type_repository_impl.dart` | ~9 |
| EntryExportRepositoryImpl | `entry_export_repository.dart` | ~5 |
| DocumentRepository | `document_repository.dart` | ~6 |
| LocationRepositoryImpl | `location_repository_impl.dart` | ~4 |
| BidItemRepositoryImpl | `bid_item_repository_impl.dart` | ~4 |
| EntryQuantityRepositoryImpl | `entry_quantity_repository_impl.dart` | ~5 |

## BaseListProvider (Phase 4: Catch fixes)

**Risk Score**: Low — only 6 descendants, all extend via inheritance.

Changing `catch (e, stack)` to `on Exception catch (e, stack)` in BaseListProvider methods affects:
- `loadItems()` line 75
- `createItem()` line 105
- `updateItem()` line 131
- `deleteItem()` line 156

All 6 descendants inherit these methods. Behavioral change: zero (Exception is a superset of what these methods encounter).

## @immutable Annotation (Phase 2B: 35 classes)

**Risk Score**: Zero — adding `@immutable` is metadata-only. No runtime behavior change. All classes already have only `final` fields.

## StageNames Replacement (Phase 2C: 18 files)

**Risk Score**: Zero — replacing `$runtimeType` with string constant in log messages. Output changes from `CellExtractorV2` to `cell_extraction` (matching existing StageReport names). No functional impact.

## Dead Code (unreachable_from_main: 12 violations)

CodeMunch dead code analysis found extensive results (saved to temp file). The 12 `unreachable_from_main` violations from the analyzer need individual review — they may be public APIs only used from tests, or genuinely dead code to remove.
