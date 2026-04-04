# Blast Radius Analysis

## Per-Symbol Impact

### `DailyEntry.locationId` (REMOVE)
- **Direct dependents**: 42 files (22 production + 20 test)
- **Risk**: HIGH — deeply woven into model, datasource, repository, provider, 5+ screens, sync adapter, router, harness
- **Mitigation**: Keep SQLite column (stop read/write), sentinel pattern in copyWith handles null gracefully

### `DailyEntry.activities` (REPURPOSE)
- **Direct dependents**: 13 files reference activities field
- **Risk**: MEDIUM — same column, new content format (JSON). Backward compat via parse fallback.
- **Key consumers**: EntryEditingController, EntryActivitiesSection, PdfDataBuilder, PdfService, entry_review_screen, harness

### `generateIdrPdf` (REWRITE)
- **Direct dependents**: 0 external importers (called via PdfService instance)
- **Risk**: LOW — self-contained within pdf_service.dart, called only from PdfDataBuilder
- **Note**: No files directly import just this method; they import PdfService

### `getByLocationId` (REMOVE — 6 definitions)
- **Definitions**: interface, impl, local datasource, remote datasource, 2 test mocks
- **Callers**: FilterEntriesUseCase.byLocation → DailyEntryProvider.filterByLocation
- **Risk**: LOW — clean chain with no other callers

### `filterByLocation` (REMOVE)
- **Callers**: No UI code calls this directly (verified via grep)
- **Risk**: LOW — unused feature, safe to remove

### `EntryFilterType.location` (REMOVE)
- **Used by**: DailyEntryProvider.filterByLocation only
- **Risk**: LOW — remove enum value and all references together

## Files Requiring Changes by Layer

### Model Layer (2 files)
- `daily_entry.dart` — Remove locationId, update copyWith/toMap/fromMap/getMissingFields

### Data Layer (5 files)
- `daily_entry_local_datasource.dart` — Remove getByLocationId
- `daily_entry_remote_datasource.dart` — Remove getByLocationId
- `daily_entry_repository.dart` (impl) — Remove getByLocationId
- `daily_entry_repository.dart` (interface) — Remove getByLocationId
- `daily_entry_adapter.dart` — Remove location FK dep

### Domain Layer (1 file)
- `filter_entries_use_case.dart` — Remove byLocation

### Presentation Layer (12 files)
- `daily_entry_provider.dart` — Remove filterByLocation, EntryFilterType.location
- `entry_editing_controller.dart` — Replace activities controller with map
- `entry_activities_section.dart` — Add location chips, per-location text
- `entry_basics_section.dart` — Remove location dropdown
- `entry_editor_screen.dart` — Remove location params
- `home_screen.dart` — Remove location name cache
- `entries_list_screen.dart` — Remove location display
- `drafts_list_screen.dart` — Remove location display
- `entry_review_screen.dart` — Remove _canMarkReady location check
- `review_summary_screen.dart` — Remove location display
- `pdf_data_builder.dart` — Parse activities JSON for PDF
- `pdf_service.dart` — Rebuild all field mappings

### Infrastructure (1 file)
- `harness_seed_data.dart` — Remove locationId seeding

### Test Layer (20+ files)
- All test files referencing `locationId` or `getByLocationId` need updates
- Key tests: `daily_entry_test.dart`, `entry_editing_controller_test.dart`, `filter_entries_use_case_test.dart`, `daily_entry_provider_filter_test.dart`

## Dead Code Targets

After removing `locationId` from DailyEntry:
- `DailyEntryLocalDatasource.getByLocationId()`
- `DailyEntryRemoteDatasource.getByLocationId()`
- `DailyEntryRepositoryImpl.getByLocationId()`
- `DailyEntryRepository.getByLocationId()` (interface)
- `FilterEntriesUseCase.byLocation()`
- `DailyEntryProvider.filterByLocation()`
- `EntryFilterType.location` enum value
- `MockDailyEntryRepository.getByLocationId()` (test mock)
- `_MockDailyEntryDatasource.getByLocationId()` (test mock)
- Location-related parameters in `EntryBasicsSection` constructor
- `_locationNameCache` in `home_screen.dart`

## Summary Counts

| Category | Count |
|----------|-------|
| Production files changed | ~21 |
| Test files changed | ~20 |
| Methods removed | 9+ |
| Methods modified | 15+ |
| Methods added | 5+ |
| Enum values removed | 1 |
| New files created | 3 |
