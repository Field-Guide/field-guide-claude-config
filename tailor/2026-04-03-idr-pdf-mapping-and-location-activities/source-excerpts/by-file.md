# Source Excerpts by File

## lib/features/pdf/services/pdf_service.dart

### IdrPdfData (lines 34-64)
Full class with all fields and constructor. See by-concern.md Concern 1.

### generateIdrPdf (lines 79-139)
Full method — loads template, fills header (Text10-Text15), contractors via _fillContractorSection, activities (Text3), safety fields (asfdasdfWER, HJTYJH, Text5#loioliol0, iol8ol), materials (8olyk,l), attachments (Text6), signature (hhhhhhhhhhhwerwer). See patterns/pdf-field-mapping-pattern.md for full source.

### _fillContractorSection (lines 167-208)
Reads _contractorFieldMap[index] and _equipmentFieldMap[index], sets name/personnel/equipment fields.

### _setField (line 211)
Safe field setter — iterates form.fields, matches by name, sets PdfTextBoxField.text, logs misses.

### _weatherToString (lines 234-250)
Maps WeatherCondition enum to "Sunny", "Cloudy", etc. Returns '' for null.

### _formatTempRange (lines 253-256)
Returns "$low - $high" or '' if either null.

### _formatMaterials (lines 259-271)
Iterates quantities, looks up bidItem, formats "description - qty unit".

### _formatAttachments (lines 274-298)
Photos: "filename (caption)". Forms: "formName (status)". Joined by newlines.

### generateDebugPdf (lines 637-665)
Fills every PdfTextBoxField with "${i+1}:$shortName". Used for field discovery.

---

## lib/features/entries/presentation/controllers/entry_editing_controller.dart

Full class (lines 19-254). 8 TextEditingControllers, 8 FocusNodes, dirty tracking, editing section state. Key methods: populateFrom, buildEntry, save, markDirty, copyFieldsFrom, isEmptyDraft, dispose. See patterns/editing-controller-pattern.md for full source.

---

## lib/features/entries/presentation/widgets/entry_activities_section.dart

Full widget (lines 15-144). StatefulWidget with tap-to-edit pattern. See patterns/activities-section-pattern.md for full source.

---

## lib/features/entries/data/models/daily_entry.dart

### Fields (lines 7-36)
locationId: String?, activities: String?, plus 15 other fields.

### copyWith (lines 64-108)
Sentinel-based, returns new DailyEntry with overridden fields.

### toMap (lines 110-135)
Maps to snake_case: location_id, activities, etc.

### fromMap (lines 153-189)
Factory constructor reading snake_case keys.

### getMissingFields (lines 141-151)
Checks locationId null, activities empty, sescMeasures empty.

---

## lib/features/entries/presentation/controllers/pdf_data_builder.dart

### PdfDataBuilder.generate (lines 37-196)
Static method. Takes 15+ params (providers, entry, photos). Loads contractors, equipment, personnel counts, quantities, bid items, forms. Synthesizes EntryPersonnel from PersonnelTypeProvider counts. Assembles IdrPdfData. Calls pdfService.generateIdrPdf. Returns (bytes, data) record.

---

## lib/features/entries/presentation/widgets/entry_basics_section.dart

### Constructor (lines 23-35)
Params: locations, selectedLocationId, weather, tempLowController, tempHighController, isFetchingWeather, onLocationChanged, onWeatherChanged, onAutoFetchWeather, onAddLocation.

Location dropdown to be removed — weather/temp fields stay.

---

## lib/features/sync/adapters/daily_entry_adapter.dart

35 lines total. ScopeType.viaProject. FK deps: [projects, locations]. fkColumnMap: {projects→project_id, locations→location_id}. userStampColumns: {updated_by_user_id→current}. localOnlyColumns: empty.

---

## lib/features/entries/presentation/widgets/entry_contractors_section.dart

### _InlineContractorChooser (lines 454-585)
Exemplar for inline selection pattern. See patterns/inline-chooser-pattern.md for full source.

---

## lib/features/entries/domain/usecases/filter_entries_use_case.dart

### byLocation (lines 21-22)
```dart
Future<List<DailyEntry>> byLocation(String locationId) =>
    _repository.getByLocationId(locationId);
```

---

## lib/features/entries/presentation/providers/daily_entry_provider.dart

### EntryFilterType enum (line 14)
```dart
enum EntryFilterType { dateRange, location, status }
```

### filterByLocation (lines 409-422)
Sets _filterLoading, _activeFilter to location, calls _filterEntriesUseCase.byLocation, catches errors.

---

## test/services/pdf_service_test.dart

### _createTestPdfData (lines 916-929)
Creates IdrPdfData with empty contractors/equipment/quantities/photos and "John Doe" inspector. Needs updating when IdrPdfData changes.
