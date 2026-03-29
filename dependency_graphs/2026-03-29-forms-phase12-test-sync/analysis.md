# Dependency Graph: Phase 12 — Test & Sync Verification Updates

## Direct Changes

### 1. Storage Cleanup (multi-bucket generalization)
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/features/sync/engine/storage_cleanup.dart` | `StorageCleanup` | 10-70 | Replace hardcoded `_bucket = 'entry-photos'` with bucket-from-queue pattern |
| `lib/services/soft_delete_service.dart` | `purgeExpiredRecords` | 353-440 | Extend `if (table == 'photos')` block to also queue form_exports, entry_exports, documents |
| `lib/services/soft_delete_service.dart` | `_childToParentOrder` | 15-31 | Add 3 new tables before their parents |
| `lib/services/soft_delete_service.dart` | `_projectChildTables` | 34-44 | Add 3 new tables + inspector_forms with guard |
| `lib/services/soft_delete_service.dart` | `cascadeSoftDeleteProject` | 55-170 | Add form_exports, entry_exports, documents to entry child cascade (step 3) |
| `lib/core/database/schema/sync_engine_tables.dart` | `createStorageCleanupQueueTable` | 85-95 | Add `bucket` column |
| `lib/core/config/supabase_config.dart` | `SupabaseConfig` | 8-31 | Add 3 bucket constants |

### 2. Driver Infrastructure
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/core/driver/driver_server.dart` | `DriverServer` | 47 | Add DocumentRepository constructor param |
| `lib/core/driver/driver_server.dart` | `_handleRequest` | 97+ | Add `/driver/inject-document-direct` route |
| `lib/core/driver/driver_server.dart` | NEW | — | Add `_handleInjectDocumentDirect` method |
| `lib/core/driver/driver_server.dart` | `_allowedFileExtensions` | 1568 | Expand to include doc types |
| `lib/main_driver.dart` | DriverServer constructor call | 518 | Add documentRepository param |

### 3. Testing Keys
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/shared/testing_keys/documents_keys.dart` | NEW | — | Create DocumentsTestingKeys class |
| `lib/shared/testing_keys/testing_keys.dart` | TestingKeys | 1-15 | Add export + import for documents_keys.dart |

### 4. Unit Tests
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `test/helpers/sync/sqlite_test_helper.dart` | `_onCreate` | 26-127 | Add FormExportTables, EntryExportTables, DocumentTables |
| `test/helpers/sync/sync_test_data.dart` | `SyncTestData` | 8+ | Add formExportMap, entryExportMap, documentMap factories |
| `test/helpers/sync/sync_test_data.dart` | `seedFkGraph` | 418-468 | Add form_export, entry_export, document to graph |
| `test/features/sync/engine/cascade_soft_delete_test.dart` | `main` | 6-155 | Extend cascade test + add entry cascade test |

### 5. Sync Flow Config Files
| File | Change |
|------|--------|
| `.claude/test-flows/registry.md` | Update S04/S07/S08/S09/S10 table lists, add S11, update counts |
| `.claude/test-flows/sync-verification-guide.md` | Update checkpoint ctx, FK teardown, post-run sweep, add S11 protocol, storage verify pattern |
| `.claude/skills/test/skill.md` | Expand sync range to S01-S11 |

### 6. ProjectLifecycleService
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/features/projects/data/services/project_lifecycle_service.dart` | `_directChildTables` | 21-31 | Add form_exports, entry_exports, documents |

## Dependent Files (callers affected)

| File | Why |
|------|-----|
| `lib/features/sync/engine/sync_engine.dart` | Calls StorageCleanup — API change if method renames |
| `lib/core/database/database_service.dart` | v43 migration already adds bucket column (per plan Phase 1) |
| `lib/core/database/schema_verifier.dart` | Must add bucket column to storage_cleanup_queue schema |
| `lib/features/auth/services/auth_service.dart` | Wipe list — add 3 new tables |

## Blast Radius

- **Direct**: 12 files modified, 1 file created
- **Dependent**: 4 files need updates
- **Tests**: 4 test files modified
- **Config**: 3 config/doc files updated

## Current State Summary

### _childToParentOrder (15 tables):
entry_quantities, entry_equipment, entry_personnel_counts, entry_contractors, photos, form_responses, todo_items, calculation_history, equipment, personnel_types, bid_items, daily_entries, contractors, locations, projects

### _projectChildTables (9 tables):
locations, contractors, daily_entries, bid_items, personnel_types, photos, form_responses, todo_items, calculation_history

### storage_cleanup_queue schema:
id INTEGER PK AUTOINCREMENT, remote_path TEXT NOT NULL, reason TEXT NOT NULL, created_at (default), attempts INTEGER DEFAULT 0, last_error TEXT
**NO bucket column** — currently hardcoded to 'entry-photos'

### SupabaseConfig buckets:
- photoBucket = 'entry-photos'
- releasesBucket = 'releases'
**Missing**: formExportsBucket, entryExportsBucket, documentsBucket

### DriverServer constructor:
testPhotoService, photoRepository, syncOrchestrator, databaseService, projectLifecycleService
**Missing**: documentRepository (or datasource)

### Testing keys files (13):
auth, common, contractors, entries, locations, navigation, photos, projects, quantities, settings, sync, testing_keys (barrel), toolbox
**Missing**: documents_keys.dart

### SyncTestData factories (16):
project, location, contractor, equipment, bidItem, personnelType, dailyEntry, photo, entryEquipment, entryQuantity, entryContractor, entryPersonnelCount, inspectorForm, formResponse, todoItem, calculationHistory
**Missing**: formExport, entryExport, document

### SqliteTestHelper._onCreate tables:
Core (5), Contractor (2), Quantity (1), Entry (3), Personnel (2), Quantity junction (1), Photo (1), Sync (1), Toolbox (4), Extraction (2), Sync engine (7+triggers)
**Missing**: FormExportTables, EntryExportTables, DocumentTables
