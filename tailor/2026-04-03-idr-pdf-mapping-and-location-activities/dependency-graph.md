# Dependency Graph

## Direct Changes

| File | Symbols Changed | Change Type |
|------|----------------|-------------|
| `lib/features/pdf/services/pdf_service.dart` | `IdrPdfData`, `generateIdrPdf`, `_contractorFieldMap`, `_equipmentFieldMap`, `_fillContractorSection`, `_formatTempRange`, `_formatMaterials`, `_formatAttachments`, `generateDebugPdf` | MODIFY |
| `lib/features/entries/data/models/daily_entry.dart` | `DailyEntry.locationId` (REMOVE), `DailyEntry.activities` (REPURPOSE), `copyWith`, `toMap`, `fromMap`, `getMissingFields` | MODIFY |
| `lib/features/entries/presentation/controllers/entry_editing_controller.dart` | `_activitiesController` (replace with map), `populateFrom`, `buildEntry`, `dispose` | MODIFY |
| `lib/features/entries/presentation/widgets/entry_activities_section.dart` | `EntryActivitiesSection`, `_EntryActivitiesSectionState` | MODIFY |
| `lib/features/entries/presentation/widgets/entry_basics_section.dart` | `EntryBasicsSection` (remove location dropdown) | MODIFY |
| `lib/features/entries/presentation/controllers/pdf_data_builder.dart` | `PdfDataBuilder.generate` (activities JSON concatenation) | MODIFY |
| `lib/features/entries/presentation/providers/daily_entry_provider.dart` | `filterByLocation` (REMOVE), `EntryFilterType.location` (REMOVE) | MODIFY |
| `lib/features/entries/domain/usecases/filter_entries_use_case.dart` | `byLocation` (REMOVE) | MODIFY |
| `lib/features/entries/data/datasources/local/daily_entry_local_datasource.dart` | `getByLocationId` (REMOVE) | MODIFY |
| `lib/features/entries/data/datasources/remote/daily_entry_remote_datasource.dart` | `getByLocationId` (REMOVE) | MODIFY |
| `lib/features/entries/data/repositories/daily_entry_repository.dart` | `getByLocationId` (REMOVE) | MODIFY |
| `lib/features/entries/domain/repositories/daily_entry_repository.dart` | `getByLocationId` (REMOVE) | MODIFY |
| `lib/features/sync/adapters/daily_entry_adapter.dart` | Remove `'locations': 'location_id'` from fkColumnMap, remove `'locations'` from FK deps | MODIFY |
| `lib/features/entries/presentation/screens/entry_editor_screen.dart` | Remove location params/logic | MODIFY |
| `lib/features/entries/presentation/screens/home_screen.dart` | Remove location name cache | MODIFY |
| `lib/features/entries/presentation/screens/entries_list_screen.dart` | Remove location display | MODIFY |
| `lib/features/entries/presentation/screens/drafts_list_screen.dart` | Remove location display | MODIFY |
| `lib/features/entries/presentation/screens/entry_review_screen.dart` | Remove `_canMarkReady` location check | MODIFY |
| `lib/features/entries/presentation/screens/review_summary_screen.dart` | Remove location display | MODIFY |
| `lib/core/driver/harness_seed_data.dart` | Remove locationId seeding on entries | MODIFY |

## New Files

| File | Purpose |
|------|---------|
| `tools/verify_idr_mapping.py` | Python verification script — fills template, renders to PNG |
| `test/services/pdf_field_mapping_test.dart` | Dart unit test — asserts field names in template |
| `test/features/entries/presentation/controllers/activities_serialization_test.dart` | Activities JSON round-trip test |

## Upstream Dependencies of pdf_service.dart

```
pdf_service.dart
├── entries/data/models/models.dart (DailyEntry, EntryPersonnel)
├── projects/data/models/models.dart (Project)
├── contractors/data/models/models.dart (Contractor, Equipment)
├── quantities/data/models/models.dart (EntryQuantity, BidItem)
├── photos/data/models/photo.dart (Photo)
├── forms/data/models/models.dart (FormAttachment)
├── forms/data/services/form_pdf_service.dart
├── pdf/services/photo_pdf_service.dart
├── core/logging/logger.dart
├── core/design_system/design_system.dart
├── core/config/app_terminology.dart
├── services/permission_service.dart
└── shared/shared.dart
```

## Importers of entry_editing_controller.dart

```
entry_editing_controller.dart
├── entry_editor_screen.dart (main consumer)
├── home_screen.dart (create-mode shortcut)
├── entry_activities_section.dart (binds controllers)
└── test: entry_editing_controller_test.dart
```

## Importers of daily_entry.dart (42 files)

Production: 22 files across model, datasource, repository, use case, provider, controller, widget, screen, router, sync adapter, harness layers.

Test: 20 files across unit, widget, integration test layers.

## Data Flow Diagram

```
                         ┌─────────────────────┐
                         │  LocationProvider    │
                         │  .locations          │
                         └──────────┬───────────┘
                                    │ location list
                         ┌──────────▼───────────┐
                         │ EntryActivitiesSection│
                         │ (location chips + text│
                         │  fields per location) │
                         └──────────┬───────────┘
                                    │ on save
                         ┌──────────▼───────────┐
                         │EntryEditingController │
                         │ getActivitiesJson()   │
                         │ → JSON string         │
                         └──────────┬───────────┘
                                    │ JSON in activities column
                         ┌──────────▼───────────┐
                         │   DailyEntry          │
                         │   .activities (TEXT)   │
                         └──────────┬───────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              ┌──────────┐  ┌──────────────┐  ┌──────────┐
              │  SQLite   │  │  Supabase    │  │PdfData   │
              │  (local)  │  │  (sync)      │  │Builder   │
              └───────────┘  └──────────────┘  └────┬─────┘
                                                    │ parse JSON, concatenate
                                               ┌────▼─────┐
                                               │PdfService│
                                               │ fill Text3│
                                               └──────────┘
```
