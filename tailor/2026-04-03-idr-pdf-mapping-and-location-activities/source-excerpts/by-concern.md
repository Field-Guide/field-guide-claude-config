# Source Excerpts by Concern

## Concern 1: PDF Field Mapping (rebuild)

### IdrPdfData class (pdf_service.dart:34-64)
```dart
class IdrPdfData {
  final DailyEntry entry;
  final Project project;
  final Contractor? primeContractor;
  final List<Contractor> subcontractors;
  final Map<String, EntryPersonnel> personnelByContractorId;
  final Map<String, List<Equipment>> equipmentByContractorId;
  final Map<String, List<String>> usedEquipmentIdsByContractorId;
  final List<EntryQuantity> quantities;
  final Map<String, BidItem> bidItemsById;
  final List<Photo> photos;
  final String inspectorName;
  final List<FormAttachment> formAttachments;
  // constructor omitted — see source-excerpts/by-file.md
}
```

### generateIdrPdf — Current field mappings (pdf_service.dart:79-139)
Header: Text10=date, Text11=projectNumber, Text15=projectName, Text12=weather, Text13=tempRange
Activities: Text3=activities (Text4 reserved overflow)
Safety: asfdasdfWER=siteSafety(guessing), HJTYJH=sescMeasures(guessing), Text5#loioliol0=trafficControl, iol8ol=visitors
Materials: 8olyk,l=materials(guessing)
Attachments: Text6=attachments, yio=extrasOverruns(unused)
Signature: hhhhhhhhhhhwerwer=signature

### _contractorFieldMap (pdf_service.dart:143-149)
5 entries (index 0-4), each: {name, foreman, operator, laborer}
Sub 1 (index 1) has null for all personnel fields.

### _equipmentFieldMap (pdf_service.dart:153-164)
5 entries (index 0-4), each: List<String> of 5 field names.

### generateDebugPdf (pdf_service.dart:637-665)
Loads template, iterates all PdfTextBoxField, fills with "${i+1}:$shortName" (truncated to 15 chars).

### Helper methods
- `_setField(form, name, value)` — safe setter with logging (line 211)
- `_weatherToString(weather)` — enum to title-case string (line 234)
- `_formatTempRange(low, high)` — "$low - $high" or empty (line 253)
- `_formatMaterials(data)` — iterate quantities, format as "description - qty unit" (line 259)
- `_formatAttachments(data)` — photos + forms, newline-joined (line 274)

---

## Concern 2: Location-Scoped Activities (new feature)

### Current EntryActivitiesSection (entry_activities_section.dart:15-144)
- StatefulWidget with `entry`, `controller`, `entryProvider`, `alwaysEditing` params
- Single `AppTextField` bound to `controller.activitiesController`
- Tap-to-edit with auto-save on focus loss
- Card layout with "Activities" header

### Current EntryEditingController — activities handling (entry_editing_controller.dart)
- `_activitiesController = TextEditingController()` (line 27)
- `activitiesController` getter (line 63)
- `_activitiesFocus = FocusNode()` (line 39)
- `populateFrom`: `_activitiesController.text = entry.activities ?? ''` (line 113)
- `buildEntry`: `activities: _activitiesController.text.trim().isEmpty ? null : _activitiesController.text.trim()` (lines 120-122)
- `isEmptyDraft`: checks `_activitiesController.text.trim().isEmpty` (line 221)
- `dispose`: `_activitiesController.dispose()` + `_activitiesFocus.dispose()` (lines 239, 247)

### LocationProvider (location_provider.dart)
- `locations` getter — returns list of Location for current project
- `getLocationById(String id)` — returns Location? via `getById(id)` (line 84)
- Extends `BaseListProvider<Location, LocationRepository>`

### _InlineContractorChooser exemplar (entry_contractors_section.dart:454-585)
- Props: `availableContractors`, `selectedIds`, `onToggle`, `onDone`, `onCancel`
- Renders selectable tiles with conditional styling for selected state
- Done/Cancel action row
- Uses `DesignConstants` spacing, `FieldGuideColors.of(context)`

---

## Concern 3: locationId Removal (cleanup)

### DailyEntry.locationId
- Field: `final String? locationId` (line 10)
- In copyWith: `Object? locationId = _sentinel` (line 65)
- In toMap: `'location_id': locationId` (line 114)
- In fromMap: `locationId: map['location_id'] as String?` (line 162)
- In getMissingFields: `if (locationId == null) missing.add('location')` (line 143)

### EntryBasicsSection — location dropdown
- Constructor takes: `required this.locations`, `required this.selectedLocationId`, `required this.onLocationChanged`, `this.onAddLocation`
- Renders DropdownButtonFormField<String> for location selection

### Sync adapter (daily_entry_adapter.dart)
- FK deps: `['projects', 'locations']` (line 13)
- fkColumnMap: `{'projects': 'project_id', 'locations': 'location_id'}` (lines 18-21)
- After removal: drop `'locations'` from both

### Filter chain (to remove entirely)
- `DailyEntryProvider.filterByLocation(locationId)` → `FilterEntriesUseCase.byLocation(locationId)` → `DailyEntryRepository.getByLocationId(locationId)` → `DailyEntryLocalDatasource.getByLocationId(locationId)` which queries `WHERE location_id = ?`

### Entry screens showing location
- `home_screen.dart` — `_locationNameCache` map, displays location name in entry tiles
- `entries_list_screen.dart` — location display in list items
- `drafts_list_screen.dart` — location display
- `entry_review_screen.dart` — `_canMarkReady` checks `entry.locationId != null`
- `review_summary_screen.dart` — location display

---

## Concern 4: Verification Tooling (new)

### Existing Python scripts
Located at `.claude/skills/pdf-processing/scripts/`:
- `extract_form_field_info.py` — extracts all field names from PDF
- `fill_fillable_fields.py` — fills specific fields to test mapping
- `convert_pdf_to_images.py` — renders pages as images
- `fill_pdf_form_with_annotations.py` — fills with visual annotations
- `check_fillable_fields.py` — lists fillable fields
- `check_bounding_boxes.py` — checks field bounding boxes
- `create_validation_image.py` — creates validation images

### Existing test helper
- `test/services/pdf_service_test.dart` — has `_createTestPdfData()` helper (line 916) that creates IdrPdfData with test data
- This will need updating when IdrPdfData changes

### Template location
- `assets/templates/idr_template.pdf` — declared in pubspec.yaml line 157
- 179 form fields, loaded via `rootBundle.load('assets/templates/idr_template.pdf')`

---

## Concern 5: PdfDataBuilder (activities JSON parsing)

### PdfDataBuilder.generate (pdf_data_builder.dart:37-196)
- Static method, takes all providers as explicit params
- Assembles IdrPdfData from multiple providers
- Currently passes `entry` directly (which includes raw `activities` string)
- Will need to: parse activities JSON, concatenate with location headers, store formatted text for PDF
- The concatenation should happen HERE (in the builder), not in PdfService — PdfService just fills fields
