# IDR PDF Mapping Rebuild & Location-Scoped Activities — Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Fix all incorrect/guessed PDF field mappings via debug-PDF verification, add per-location activities with JSON serialization, and clean up locationId from DailyEntry.
**Spec:** `.claude/specs/2026-04-03-idr-pdf-mapping-and-location-activities-spec.md`
**Tailor:** `.claude/tailor/2026-04-03-idr-pdf-mapping-and-location-activities/`

**Architecture:** DailyEntry.activities column repurposed to store JSON array of `{locationId, locationName, text}` objects. EntryEditingController manages a map of TextEditingControllers keyed by locationId. PdfDataBuilder concatenates location-scoped text with headers for PDF export. All PDF field mappings rebuilt from debug-PDF visual verification.
**Tech Stack:** Flutter/Dart, Syncfusion PDF, SQLite (no schema migration), Python (verification tooling)
**Blast Radius:** 25 direct (incl. router/driver files), 20+ test, 4 new files

---

## Phase 1: Data Model — Remove locationId from DailyEntry

### Sub-phase 1.1: Modify DailyEntry model

**Files:**
- Modify: `lib/features/entries/data/models/daily_entry.dart`

**Agent**: `backend-data-layer-agent`

#### Step 1.1.1: Remove locationId field declaration

```dart
// WHY: locationId moves from entry-level to activities-level (JSON embedded)
// REMOVE: final String? locationId; (line 10)
// Keep: final String? activities; (line 16) — same type, new JSON content
```

Remove `final String? locationId;` from the class fields.

#### Step 1.1.2: Remove locationId from constructor

Remove `this.locationId` from the named constructor parameters.

#### Step 1.1.3: Remove locationId from copyWith

```dart
// REMOVE from copyWith parameters:
//   Object? locationId = _sentinel,
// REMOVE from copyWith body:
//   locationId: identical(locationId, _sentinel) ? this.locationId : locationId as String?,
```

#### Step 1.1.4: Remove locationId from toMap

```dart
// REMOVE from toMap():
//   'location_id': locationId,
```

#### Step 1.1.5: Remove locationId from fromMap

```dart
// REMOVE from fromMap():
//   locationId: map['location_id'] as String?,
```

#### Step 1.1.6: Remove locationId from getMissingFields

```dart
// REMOVE from getMissingFields():
//   if (locationId == null) missing.add('location');
// FROM SPEC: Location is no longer required — it's an optional activities-formatting concern
```

#### Step 1.1.7: Verify compile — flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: Compilation errors in dependent files (expected — fixed in Phase 2-4)

---

## Phase 2: Data & Domain Layer Cleanup

### Sub-phase 2.1: Remove getByLocationId from repositories

**Files:**
- Modify: `lib/features/entries/domain/repositories/daily_entry_repository.dart`
- Modify: `lib/features/entries/data/repositories/daily_entry_repository.dart`

**Agent**: `backend-data-layer-agent`

#### Step 2.1.1: Remove from interface

```dart
// REMOVE from DailyEntryRepository (interface):
//   Future<List<DailyEntry>> getByLocationId(String locationId);
```

#### Step 2.1.2: Remove from implementation

```dart
// REMOVE from DailyEntryRepositoryImpl:
//   @override
//   Future<List<DailyEntry>> getByLocationId(String locationId) =>
//       _localDatasource.getByLocationId(locationId);
```

### Sub-phase 2.2: Remove getByLocationId from datasources

**Files:**
- Modify: `lib/features/entries/data/datasources/local/daily_entry_local_datasource.dart`
- Modify: `lib/features/entries/data/datasources/remote/daily_entry_remote_datasource.dart`

**Agent**: `backend-data-layer-agent`

#### Step 2.2.1: Remove from local datasource

```dart
// REMOVE from DailyEntryLocalDatasource:
//   Future<List<DailyEntry>> getByLocationId(String locationId) async {
//     final db = await _db.database;
//     final maps = await db.query('daily_entries', where: 'location_id = ?', whereArgs: [locationId]);
//     return maps.map((m) => DailyEntry.fromMap(m)).toList();
//   }
```

#### Step 2.2.2: Remove from remote datasource

```dart
// REMOVE from DailyEntryRemoteDatasource:
//   Future<List<DailyEntry>> getByLocationId(String locationId) ...
```

### Sub-phase 2.3: Remove filter chain

**Files:**
- Modify: `lib/features/entries/domain/usecases/filter_entries_use_case.dart`
- Modify: `lib/features/entries/presentation/providers/daily_entry_provider.dart`

**Agent**: `backend-data-layer-agent`

#### Step 2.3.1: Remove byLocation from FilterEntriesUseCase

```dart
// REMOVE (lines 21-22):
//   Future<List<DailyEntry>> byLocation(String locationId) =>
//       _repository.getByLocationId(locationId);
```

#### Step 2.3.2: Remove EntryFilterType.location enum value

```dart
// BEFORE:
enum EntryFilterType { dateRange, location, status }
// AFTER:
enum EntryFilterType { dateRange, status }
```

#### Step 2.3.3: Remove filterByLocation from DailyEntryProvider

```dart
// REMOVE filterByLocation method (lines 409-422)
// Remove all references to EntryFilterType.location in switch/case blocks
```

### Sub-phase 2.4: Remove location FK from sync adapter

**Files:**
- Modify: `lib/features/sync/adapters/daily_entry_adapter.dart`

**Agent**: `backend-supabase-agent`

#### Step 2.4.1: Remove location from FK dependencies

```dart
// BEFORE (line 13):
//   fkDependencies: ['projects', 'locations'],
// AFTER:
//   fkDependencies: ['projects'],

// BEFORE (lines 18-21):
//   fkColumnMap: {'projects': 'project_id', 'locations': 'location_id'},
// AFTER:
//   fkColumnMap: {'projects': 'project_id'},
```

### Sub-phase 2.5: Verify data layer — flutter analyze

**Agent**: `backend-data-layer-agent`

#### Step 2.5.1: Run flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: Remaining errors only in presentation layer files (Phase 3-4 will fix)

---

## Phase 3: EntryEditingController — Per-Location Activities

### Sub-phase 3.1: Add location-activities state and methods

**Files:**
- Modify: `lib/features/entries/presentation/controllers/entry_editing_controller.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 3.1.1: Replace single activities controller with map + state

```dart
// WHY: Per-location activities require one TextEditingController per location
// NOTE: Matches existing controller pattern — encapsulated with public getters

// REMOVE:
//   final _activitiesController = TextEditingController();

// ADD (at class level, near other controllers):
import 'dart:convert';
import 'package:construction_inspector/features/locations/data/models/location.dart';

Map<String, TextEditingController> _locationActivitiesControllers = {};
Map<String, String?> _locationNames = {};
String _activeLocationId = '';

// Keep existing:
//   final _activitiesFocus = FocusNode();
```

#### Step 3.1.2: Add activitiesController getter (replaces direct field)

```dart
// WHY: Returns the controller for the currently active location
// NOTE: Callers (EntryActivitiesSection) don't need to change — same getter name
TextEditingController get activitiesController =>
    _locationActivitiesControllers[_activeLocationId] ??
    (_locationActivitiesControllers.values.isNotEmpty
        ? _locationActivitiesControllers.values.first
        : (_locationActivitiesControllers[''] = TextEditingController()));

String get activeLocationId => _activeLocationId;
Map<String, TextEditingController> get locationActivitiesControllers =>
    Map.unmodifiable(_locationActivitiesControllers);
Map<String, String?> get locationNames => Map.unmodifiable(_locationNames);
```

#### Step 3.1.3: Add initializeLocations method

```dart
// WHY: Sets up controllers for each project location
// NOTE: Called from EntryActivitiesSection when locations are available
// IMPORTANT: Must be called AFTER loadActivitiesJson so existing text is preserved
void initializeLocations(List<Location> locations) {
  if (locations.length <= 1) {
    // Single or no location — ensure default controller exists
    _locationActivitiesControllers.putIfAbsent(
      locations.isNotEmpty ? locations.first.id : '',
      () => TextEditingController(),
    );
    if (locations.isNotEmpty) {
      _locationNames[locations.first.id] = locations.first.name;
    }
    _activeLocationId = _locationActivitiesControllers.keys.first;
    return;
  }
  // Multi-location — create controllers for each
  for (final loc in locations) {
    _locationActivitiesControllers.putIfAbsent(
      loc.id,
      () => TextEditingController(),
    );
    _locationNames[loc.id] = loc.name;
  }
  _activeLocationId = _locationActivitiesControllers.keys.first;
  notifyListeners();
}
```

#### Step 3.1.4: Add switchLocation method

```dart
// WHY: Swaps visible text field to the selected location
void switchLocation(String locationId) {
  if (_activeLocationId == locationId) return;
  _activeLocationId = locationId;
  notifyListeners();
}
```

#### Step 3.1.5: Add loadActivitiesJson method

```dart
// WHY: Parses JSON array from activities column, or wraps legacy plain text
// FROM SPEC: Backward compat — if not JSON, wrap as single un-located text
void loadActivitiesJson(String? activities) {
  // Dispose existing controllers
  for (final c in _locationActivitiesControllers.values) {
    c.dispose();
  }
  _locationActivitiesControllers.clear();
  _locationNames.clear();

  if (activities == null || activities.trim().isEmpty) {
    // No activities — create default empty controller
    _locationActivitiesControllers[''] = TextEditingController();
    _activeLocationId = '';
    return;
  }

  try {
    final list = jsonDecode(activities) as List;
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final locId = map['locationId'] as String? ?? '';
      final text = map['text'] as String? ?? '';
      _locationActivitiesControllers[locId] = TextEditingController(text: text);
      _locationNames[locId] = map['locationName'] as String?;
    }
    _activeLocationId = _locationActivitiesControllers.keys.first;
  } catch (e) {
    // Legacy plain text — single controller
    Logger.entries('[Activities] JSON parse failed: $e');
    _locationActivitiesControllers[''] = TextEditingController(text: activities);
    _activeLocationId = '';
  }
}
```

#### Step 3.1.6: Add getActivitiesJson method

```dart
// WHY: Serializes all location activities to JSON for storage
// FROM SPEC: Empty locations omitted from output
String? getActivitiesJson() {
  final result = <Map<String, dynamic>>[];
  for (final mapEntry in _locationActivitiesControllers.entries) {
    final text = mapEntry.value.text.trim();
    if (text.isEmpty) continue;
    result.add({
      'locationId': mapEntry.key.isEmpty ? null : mapEntry.key,
      'locationName': _locationNames[mapEntry.key],
      'text': text,
    });
  }
  if (result.isEmpty) return null;
  // Single entry with no location — store as JSON for consistency
  return jsonEncode(result);
}
```

### Sub-phase 3.2: Update populateFrom, buildEntry, dispose

**Files:**
- Modify: `lib/features/entries/presentation/controllers/entry_editing_controller.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 3.2.1: Update populateFrom

```dart
// REPLACE in populateFrom (line ~113):
// OLD: _activitiesController.text = entry.activities ?? '';
// NEW:
loadActivitiesJson(entry.activities);
```

#### Step 3.2.2: Update buildEntry

```dart
// REPLACE in buildEntry (lines ~120-122):
// OLD: activities: _activitiesController.text.trim().isEmpty ? null : _activitiesController.text.trim(),
// NEW:
activities: getActivitiesJson(),
// ALSO REMOVE: locationId reference from copyWith call (if present)
```

#### Step 3.2.3: Update isEmptyDraft

```dart
// REPLACE activities check in isEmptyDraft (line ~221):
// OLD: _activitiesController.text.trim().isEmpty
// NEW:
_locationActivitiesControllers.values.every((c) => c.text.trim().isEmpty)
```

#### Step 3.2.4: Update copyFieldsFrom

```dart
// NOTE: copyFieldsFrom copies non-empty fields from a Map<String, String?>
// The 'activities' key should load via loadActivitiesJson if present
// Check if 'activities' is handled — if so, update to use loadActivitiesJson
```

#### Step 3.2.5: Update dispose

```dart
// REPLACE in dispose (line ~239):
// OLD: _activitiesController.dispose();
// NEW:
for (final c in _locationActivitiesControllers.values) {
  c.dispose();
}
// Keep: _activitiesFocus.dispose();
```

### Sub-phase 3.3: Verify controller — flutter analyze

**Agent**: `frontend-flutter-specialist-agent`

#### Step 3.3.1: Run flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: Clean or only presentation widget errors (fixed in Phase 4)

---

## Phase 4: UI Components

### Sub-phase 4.1: Modify EntryActivitiesSection — location chips + per-location text

**Files:**
- Modify: `lib/features/entries/presentation/widgets/entry_activities_section.dart`
- Modify: `lib/shared/testing_keys/testing_keys.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.1.1: Add locations parameter and LocationProvider import

```dart
// WHY: Section needs project locations to show inline chips
// NOTE: Only shows chips when 2+ locations exist (spec requirement)
import 'package:construction_inspector/features/locations/data/models/location.dart';

// Add to constructor:
//   required this.locations,
final List<Location> locations;
```

#### Step 4.1.2: Add activityLocationChip testing key

```dart
// In testing_keys.dart, add near existing location keys (line ~752):
static Key activityLocationChip(String locationId) =>
    Key('activity_location_chip_$locationId');
```

#### Step 4.1.3: Add location chip row to build method

```dart
// WHY: Inline location selector — only visible when project has 2+ locations
// NOTE: Follows ChoiceChip pattern (single-select), not FilterChip (multi-select)
// FROM SPEC: "inline location chips (like contractor cards)"

// Insert between header and text field, ONLY when locations.length >= 2 OR
// controller has orphaned locations (deleted after activities written):
//
// Build chip list: project locations + orphaned locations from controller
final projectLocationIds = widget.locations.map((l) => l.id).toSet();
final controllerLocationIds = widget.controller.locationActivitiesControllers.keys.toSet();
final orphanedIds = controllerLocationIds.difference(projectLocationIds)
    ..remove(''); // Exclude legacy empty-key entries

final showChips = widget.locations.length >= 2 || orphanedIds.isNotEmpty;

if (showChips) ...[
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Wrap(
      spacing: 8,
      children: [
        // Current project locations
        ...widget.locations.map((loc) {
          final isActive = loc.id == widget.controller.activeLocationId;
          return ChoiceChip(
            key: TestingKeys.activityLocationChip(loc.id),
            label: Text(loc.name),
            selected: isActive,
            onSelected: (_) {
              widget.controller.switchLocation(loc.id);
            },
          );
        }),
        // Orphaned locations — show with name from JSON, styled differently
        // FROM SPEC: "show locationName from JSON (not a live lookup)"
        ...orphanedIds.map((id) {
          final isActive = id == widget.controller.activeLocationId;
          final name = widget.controller.locationNames[id] ?? 'Unknown Location';
          return ChoiceChip(
            key: TestingKeys.activityLocationChip(id),
            label: Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
            selected: isActive,
            onSelected: (_) {
              widget.controller.switchLocation(id);
            },
          );
        }),
      ],
    ),
  ),
],
```

#### Step 4.1.4: Initialize locations in initState or didUpdateWidget

```dart
// WHY: Controller needs to know available locations to manage per-location controllers
// IMPORTANT: Call after populateFrom has run (which calls loadActivitiesJson)
@override
void initState() {
  super.initState();
  widget.controller.initializeLocations(widget.locations);
}

@override
void didUpdateWidget(covariant EntryActivitiesSection oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.locations != oldWidget.locations) {
    widget.controller.initializeLocations(widget.locations);
  }
}
```

#### Step 4.1.5: Fix _startEditing — remove raw JSON copy

```dart
// WHY: _startEditing() currently copies entry.activities (now JSON) directly
// to activitiesController.text, which overwrites the parsed per-location controllers.
// Controllers are already populated via populateFrom → loadActivitiesJson.
// FIX: Remove the raw copy line entirely. Only set _isEditing state.
//
// REMOVE (line ~43):
//   widget.controller.activitiesController.text = entry.activities ?? '';
//
// The method should just toggle editing state — controllers are pre-populated.
```

#### Step 4.1.6: Add static display helper for JSON activities

```dart
// WHY: Multiple screens display entry.activities directly (home_screen:1104,
// entries_list_screen:396, entry_review_screen:169). With JSON, they'd render
// raw JSON text. Need a helper to extract human-readable text.
// FROM SPEC: "Location A -\n\ntext\n\nLocation B -\n\ntext" format
//
// ADD to DailyEntry model (or as extension method on String?):
// static String activitiesDisplayText(String? activities) {
//   if (activities == null || activities.trim().isEmpty) return '';
//   try {
//     final list = jsonDecode(activities) as List;
//     return list
//       .map((item) {
//         final map = item as Map<String, dynamic>;
//         final name = map['locationName'] as String?;
//         final text = (map['text'] as String? ?? '').trim();
//         if (text.isEmpty) return '';
//         return name != null && name.isNotEmpty ? '$name - $text' : text;
//       })
//       .where((s) => s.isNotEmpty)
//       .join('\n');
//   } catch (e) {
//     Logger.entries('[Activities] Display text parse failed: $e');
//     return activities; // Legacy plain text
//   }
// }
//
// NOTE: Apply in all 4 display locations:
//   - home_screen.dart:1104 → DailyEntry.activitiesDisplayText(entry.activities)
//   - entries_list_screen.dart:396 → DailyEntry.activitiesDisplayText(entry.activities!)
//   - entry_review_screen.dart:169 → DailyEntry.activitiesDisplayText(entry.activities)
//   - entry_activities_section.dart:115 (view mode) → same helper
```

#### Step 4.1.7: Listen to controller for location switches

```dart
// WHY: When switchLocation is called, the section must rebuild to show new text
// Add listener in initState:
widget.controller.addListener(_onControllerChanged);

// In dispose:
widget.controller.removeListener(_onControllerChanged);

// Method:
void _onControllerChanged() {
  if (mounted) setState(() {});
}
```

### Sub-phase 4.2: Handle EntryBasicsSection — dead code

**Files:**
- Audit: `lib/features/entries/presentation/widgets/entry_basics_section.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.2.1: Confirm EntryBasicsSection is unused

```dart
// NOTE: EntryBasicsSection has zero instantiations in the codebase (verified via grep).
// The constructor is only defined, never called.
// DECISION: Delete the file if confirmed unused. If it serves as a template or
// reference for future work, skip deletion and add a TODO comment.
// PREFERRED: Delete `entry_basics_section.dart` — dead code adds maintenance burden.
// If deleted, also remove any barrel-file export referencing it.
```

### Sub-phase 4.3: Clean up EntryEditorScreen + route/registry files

**Files:**
- Modify: `lib/features/entries/presentation/screens/entry_editor_screen.dart`
- Modify: `lib/core/router/routes/entry_routes.dart`
- Modify: `lib/core/driver/flow_registry.dart`
- Modify: `lib/core/driver/screen_registry.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.3.1: Remove location-related state and params

```dart
// REMOVE: Location-related state variables (selectedLocationId, etc.)
// REMOVE: Location-related params passed to EntryBasicsSection
// ADD: Pass locations list to EntryActivitiesSection:
//   locations: locations,  // from LocationProvider
```

#### Step 4.3.1b: Remove locationId from entry_routes.dart

```dart
// In lib/core/router/routes/entry_routes.dart:
// REMOVE (line 16): final locationId = state.uri.queryParameters['locationId'];
// REMOVE (line 21): locationId: locationId,
// Remove locationId from EntryEditorScreen constructor call
```

#### Step 4.3.1c: Remove locationId from flow_registry.dart

```dart
// In lib/core/driver/flow_registry.dart:
// REMOVE (line 179): final locationId = state.uri.queryParameters['locationId'];
// REMOVE (line 184): locationId: locationId,
```

#### Step 4.3.1d: Remove locationId from screen_registry.dart

```dart
// In lib/core/driver/screen_registry.dart:
// REMOVE (line 42): locationId: data['locationId'] as String?,
// REMOVE (lines 49-50): locationId: (data['locationId'] as String?) ?? HarnessSeedData.defaultLocationId,
```

#### Step 4.3.2: Remove locationId check from _isEmptyDraft

```dart
// In entry_editor_screen.dart at line 699:
// REMOVE: if (entry.locationId != null) return false;
// WHY: locationId removed from DailyEntry — this check would fail to compile.
// Also remove the locationId color check at line 990:
//   if (entry.locationId == null) ? fg.statusWarning : ...
// ALSO FIX: The activities check at line ~704 uses activitiesController (active location only).
// After per-location changes, this would miss text in non-active locations → silent deletion.
// REPLACE line ~704:
//   OLD: if (_editingController.activitiesController.text.trim().isNotEmpty) return false;
//   NEW: if (!_editingController.isEmptyDraft) return false;
// This delegates to the controller's isEmptyDraft which checks ALL location controllers.
```

#### Step 4.3.3: Update EntryBasicsSection call site

```dart
// Remove location-related named parameters:
//   locations: ...,
//   selectedLocationId: ...,
//   onLocationChanged: ...,
//   onAddLocation: ...,
```

#### Step 4.3.4: Update EntryActivitiesSection call site

```dart
// ADD locations parameter:
EntryActivitiesSection(
  entry: entry,
  controller: controller,
  entryProvider: entryProvider,
  alwaysEditing: alwaysEditing,
  locations: locations,  // NEW — pass project locations
),
```

### Sub-phase 4.4: Clean up list screens — HomeScreen, EntriesListScreen, DraftsListScreen

**Files:**
- Modify: `lib/features/entries/presentation/screens/home_screen.dart`
- Modify: `lib/features/entries/presentation/screens/entries_list_screen.dart`
- Modify: `lib/features/entries/presentation/screens/drafts_list_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.4.1: HomeScreen — remove _locationNameCache + fix activities display

```dart
// REMOVE: _locationNameCache map and all references
// REMOVE: Location name display in entry list tiles
// Keep: All other entry tile content (date, status, etc.)
// FIX: At line 1104, replace raw `entry.activities ?? 'No activities recorded'`
//   with `DailyEntry.activitiesDisplayText(entry.activities)` (from Step 4.1.6)
//   or fallback: `DailyEntry.activitiesDisplayText(entry.activities).isEmpty
//                  ? 'No activities recorded' : DailyEntry.activitiesDisplayText(entry.activities)`
```

#### Step 4.4.2: EntriesListScreen — remove location display + fix activities display

```dart
// REMOVE: Location name/badge from entry list items
// If the file references entry.locationId, remove those references
// FIX: At line 396, replace raw `entry.activities!`
//   with `DailyEntry.activitiesDisplayText(entry.activities!)` (from Step 4.1.6)
```

#### Step 4.4.3: DraftsListScreen — remove location display

```dart
// REMOVE: Location display from draft list items
// Same pattern as EntriesListScreen
```

### Sub-phase 4.5: Clean up review screens

**Files:**
- Modify: `lib/features/entries/presentation/screens/entry_review_screen.dart`
- Modify: `lib/features/entries/presentation/screens/review_summary_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.5.1: EntryReviewScreen — remove _canMarkReady location check + fix activities display

```dart
// REMOVE: entry.locationId != null check from _canMarkReady (line 280)
// FROM SPEC: Location is no longer a submission requirement
// FIX: At line 169, replace raw `entry.activities` value display
//   with `DailyEntry.activitiesDisplayText(entry.activities)` (from Step 4.1.6)
```

#### Step 4.5.2: ReviewSummaryScreen — remove location display

```dart
// REMOVE: Location display from review summary
```

### Sub-phase 4.6: Verify UI — flutter analyze

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.6.1: Run flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: Clean (all locationId references resolved)

---

## Phase 5: PDF Mapping Rebuild

### Sub-phase 5.1: Generate debug PDF and render to images

**Files:**
- Read: `lib/features/pdf/services/pdf_service.dart` (generateDebugPdf at line 637)
- Use: `.claude/skills/pdf-processing/scripts/convert_pdf_to_images.py`

**Agent**: `pdf-agent`

#### Step 5.1.1: Generate debug PDF via app or script

```dart
// WHY: Debug PDF fills every field with "${i+1}:$shortName" for visual identification
// The generateDebugPdf() method (pdf_service.dart:637) already exists
// Option A: Call from test harness
// Option B: Use Python fill_fillable_fields.py to fill with numbered labels
```

Run: `python .claude/skills/pdf-processing/scripts/fill_pdf_form_with_annotations.py assets/templates/idr_template.pdf --output debug_idr_output.pdf`

#### Step 5.1.2: Render debug PDF to images

Run: `python .claude/skills/pdf-processing/scripts/convert_pdf_to_images.py debug_idr_output.pdf --output-dir debug_images/`

#### Step 5.1.3: Extract field info for reference

Run: `python .claude/skills/pdf-processing/scripts/extract_form_field_info.py assets/templates/idr_template.pdf --output field_info.json`

### Sub-phase 5.2: Visual field identification (CHECKPOINT)

**Agent**: `pdf-agent`

#### Step 5.2.1: Map every field to its visual position

```
// CHECKPOINT: Visual inspection of debug PDF images
// For each of the 179 fields, record:
//   - Field index (from debug fill)
//   - Field name (from PDF form)
//   - Visual position (page, row, column, label)
//   - Current mapping in code (correct/incorrect/unmapped)
//
// Known issues to verify:
//   - asfdasdfWER → is this really Site Safety? (marked "guessing")
//   - HJTYJH → is this really SESC Measures? (marked "guessing")
//   - 8olyk,l → is this really Materials? (marked "guessing")
//   - Text3 → Activities (verify position)
//   - Text4 → Activities overflow (not yet used — verify position)
//   - projectRep → find the field (currently unmapped)
//   - yio → Extras & Overruns (currently not populated)
//   - hhhhhhhhhhhwerwer → Signature (verify position)
```

### Sub-phase 5.3: Rebuild field mappings in pdf_service.dart

**Files:**
- Modify: `lib/features/pdf/services/pdf_service.dart`

**Agent**: `pdf-agent`

#### Step 5.3.1: Update header field mappings

```dart
// WHY: Ensure all header fields map to correct visual positions
// FROM SPEC: All "guessing" comments must be resolved

// Current mappings (verify each, fix if wrong):
_setField(form, 'Text10', DateFormat('M/d/yy').format(data.entry.date));       // Date
_setField(form, 'Text11', data.project.projectNumber);                          // Project #
_setField(form, 'Text15', data.project.name);                                   // Project Name
_setField(form, 'Text12', _weatherToString(data.entry.weather));                 // Weather
_setField(form, 'Text13', _formatTempRange(data.entry.tempLow, data.entry.tempHigh)); // Temp Range

// ADD: Project Rep (currently unmapped)
// NOTE: Field name determined in Step 5.2.1 visual inspection
_setField(form, '<projectRepFieldName>', data.inspectorName);  // Project Rep
```

#### Step 5.3.2: Verify/fix narrative field mappings

```dart
// Current (all marked "guessing" or unverified):
_setField(form, 'asfdasdfWER', data.entry.siteSafety ?? '');        // Site Safety
_setField(form, 'HJTYJH', data.entry.sescMeasures ?? '');           // SESC Measures
_setField(form, 'Text5#loioliol0', data.entry.trafficControl ?? ''); // Traffic Control
_setField(form, 'iol8ol', data.entry.visitors ?? '');                // Visitors

// FIX: Update field names based on Step 5.2.1 visual verification
// FIX: Add extrasOverruns (currently not populated):
_setField(form, 'yio', data.entry.extrasOverruns ?? '');  // Extras & Overruns
```

#### Step 5.3.3: Verify contractor and equipment field maps

```dart
// WHY: Verify all 5 contractor slots and 25 equipment slots
// The _contractorFieldMap and _equipmentFieldMap are already defined
// Verify each field name maps to the correct visual position
// NOTE: Sub 1 (index 1) confirmed to have no personnel fields — verify this is correct
```

#### Step 5.3.4: Update activities field for multi-location

```dart
// WHY: Activities may now be JSON with multiple locations
// FROM SPEC: Concatenated format "Location A -\n\ntext\n\nLocation B -\n\ntext"
// NOTE: The concatenation happens in PdfDataBuilder (Sub-phase 5.4), not here
// PdfService just receives a pre-formatted string and fills Text3 + Text4

// IMPORTANT: Add Text4 overflow handling
final activitiesText = data.entry.activities ?? '';
// NOTE: PdfDataBuilder will pass pre-formatted text via entry.activities
// FROM SPEC: "No data truncation or overflow in any filled field"
//
// Split at ~2000 chars (conservative estimate for Text3 bounding box).
// Split at a natural boundary: last paragraph break (\n\n) before limit,
// or last newline, or hard cut at limit.
const text3Limit = 2000;
String text3;
String text4 = '';
if (activitiesText.length <= text3Limit) {
  text3 = activitiesText;
} else {
  // Find last paragraph break before limit
  var splitIdx = activitiesText.lastIndexOf('\n\n', text3Limit);
  if (splitIdx < text3Limit ~/ 2) {
    // No good paragraph break — try last newline
    splitIdx = activitiesText.lastIndexOf('\n', text3Limit);
  }
  if (splitIdx < text3Limit ~/ 2) {
    splitIdx = text3Limit; // Hard cut
  }
  text3 = activitiesText.substring(0, splitIdx).trimRight();
  text4 = activitiesText.substring(splitIdx).trimLeft();
}
_setField(form, 'Text3', text3);
if (text4.isNotEmpty) {
  _setField(form, 'Text4', text4);
}
```

#### Step 5.3.5: Verify materials, attachments, signature — with truncation safety

```dart
// FROM SPEC Section 6 Step 4: "Handle overflow for long-text fields (activities, materials, attachments)"
// NOTE: Materials (8olyk,l) and Attachments (Text6) are single-field boxes with limited capacity.
// Apply truncation with "..." if text exceeds estimated field capacity.

const materialsLimit = 1500; // Estimate based on bounding box — verify in Step 5.2
const attachmentsLimit = 1500;

// Materials:
String materialsText = _formatMaterials(data);
if (materialsText.length > materialsLimit) {
  materialsText = '${materialsText.substring(0, materialsLimit - 3)}...';
}
_setField(form, '8olyk,l', materialsText);  // Verify field name

// Attachments:
String attachmentsText = _formatAttachments(data);
if (attachmentsText.length > attachmentsLimit) {
  attachmentsText = '${attachmentsText.substring(0, attachmentsLimit - 3)}...';
}
_setField(form, 'Text6', attachmentsText);  // Already verified

// Signature:
// NOTE: Preserve existing fallback — user-entered signature takes priority over inspector name
_setField(form, 'hhhhhhhhhhhwerwer', data.entry.signature ?? data.inspectorName);  // Verify position

// NOTE: Verify truncation limits visually during Step 5.2 inspection.
// Adjust materialsLimit / attachmentsLimit to match actual bounding box capacity.
```

### Sub-phase 5.4: Update PdfDataBuilder — activities JSON concatenation

**Files:**
- Modify: `lib/features/entries/presentation/controllers/pdf_data_builder.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 5.4.1: Add activities formatting helper

```dart
// WHY: PdfDataBuilder must concatenate per-location activities for PDF export
// FROM SPEC: Format as "Location A -\n\ntext\n\nLocation B -\n\ntext"
// NOTE: Empty locations omitted (spec requirement)
import 'dart:convert';

/// Formats activities JSON into a single string for PDF export.
/// Legacy plain text passes through unchanged.
static String _formatActivitiesForPdf(String? activities) {
  if (activities == null || activities.trim().isEmpty) return '';

  try {
    final list = jsonDecode(activities) as List;
    final buffer = StringBuffer();
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final locationName = map['locationName'] as String?;
      final text = (map['text'] as String? ?? '').trim();
      if (text.isEmpty) continue;

      if (buffer.isNotEmpty) buffer.write('\n\n');
      if (locationName != null && locationName.isNotEmpty) {
        buffer.write('$locationName -\n\n');
      }
      buffer.write(text);
    }
    return buffer.toString();
  } catch (e) {
    // Legacy plain text — return as-is
    Logger.pdf('[PDF] Activities JSON parse failed: $e');
    return activities;
  }
}
```

#### Step 5.4.2: Use formatter in generate method

```dart
// In PdfDataBuilder.generate, before creating IdrPdfData:
// WHY: Pass pre-formatted activities text to PdfService
// NOTE: Create a modified entry with formatted activities for the PDF data object

final formattedActivities = _formatActivitiesForPdf(entry.activities);
// Pass to IdrPdfData via a modified entry or add formattedActivities to IdrPdfData
// Option A: entry.copyWith(activities: formattedActivities)
// Option B: Add formattedActivities field to IdrPdfData
// Prefer Option A — simpler, no IdrPdfData changes needed
final pdfEntry = entry.copyWith(activities: formattedActivities);
// Use pdfEntry instead of entry when constructing IdrPdfData
```

### Sub-phase 5.5: Verify PDF — flutter analyze

**Agent**: `pdf-agent`

#### Step 5.5.1: Run flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: Clean

---

## Phase 6: Verification Tooling & Tests

### Sub-phase 6.1: Create Python verification script

**Files:**
- Create: `tools/verify_idr_mapping.py`

**Agent**: `pdf-agent`

#### Step 6.1.1: Write verification script

```python
#!/usr/bin/env python3
"""
Fills IDR template with labeled test data and renders to PNG for visual verification.
Usage: python tools/verify_idr_mapping.py [--output-dir OUTPUT_DIR]
"""
# WHY: Visual verification that each field maps to the correct position
# FROM SPEC: "Fills template with labeled test data, renders to PNG images"

# Uses existing scripts from .claude/skills/pdf-processing/scripts/
# 1. Fill template with labeled data (e.g., "PROJECT_NAME" in project name field)
# 2. Render filled PDF to PNG images
# 3. Output images for manual inspection

# Field data map — each value is a human-readable label:
FIELD_DATA = {
    'Text10': 'DATE_2026-04-03',
    'Text11': 'PROJECT_NUM_12345',
    'Text15': 'PROJECT_NAME_TEST',
    'Text12': 'WEATHER_SUNNY',
    'Text13': 'TEMP_60-80',
    'Text3': 'ACTIVITIES_MAIN_TEXT',
    'Text4': 'ACTIVITIES_OVERFLOW',
    'asfdasdfWER': 'SITE_SAFETY',
    'HJTYJH': 'SESC_MEASURES',
    'Text5#loioliol0': 'TRAFFIC_CONTROL',
    'iol8ol': 'VISITORS',
    '8olyk,l': 'MATERIALS',
    'Text6': 'ATTACHMENTS',
    'yio': 'EXTRAS_OVERRUNS',
    'hhhhhhhhhhhwerwer': 'INSPECTOR_SIGNATURE',
    # Contractor fields...
    'Namegdzf': 'PRIME_NAME',
    'QntyForeman': 'PRIME_FOREMAN_3',
    'QntyOperator': 'PRIME_OPERATOR_5',
    'QntyLaborer': 'PRIME_LABORER_8',
    # ... (all 5 contractor slots + 25 equipment slots)
}

# Implementation uses PyPDF2 or pikepdf to fill fields
# Then calls convert_pdf_to_images.py for rendering
```

### Sub-phase 6.2: Create Dart field mapping unit test

**Files:**
- Create: `test/services/pdf_field_mapping_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.2.1: Write field mapping test

```dart
// WHY: CI regression test — ensures all expected field names exist in template
// FROM SPEC: "Asserts every expected field name exists in template"
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IDR PDF Field Mapping', () {
    late PdfDocument document;
    late Set<String> templateFieldNames;

    setUpAll(() async {
      final bytes = await rootBundle.load('assets/templates/idr_template.pdf');
      document = PdfDocument(inputBytes: bytes.buffer.asUint8List());
      templateFieldNames = <String>{};
      for (int i = 0; i < document.form.fields.count; i++) {
        templateFieldNames.add(document.form.fields[i].name ?? '');
      }
    });

    tearDownAll(() => document.dispose());

    test('header fields exist in template', () {
      expect(templateFieldNames, contains('Text10'));  // Date
      expect(templateFieldNames, contains('Text11'));  // Project #
      expect(templateFieldNames, contains('Text15'));  // Project Name
      expect(templateFieldNames, contains('Text12'));  // Weather
      expect(templateFieldNames, contains('Text13'));  // Temp Range
    });

    test('activities fields exist in template', () {
      expect(templateFieldNames, contains('Text3'));   // Activities
      expect(templateFieldNames, contains('Text4'));   // Activities overflow
    });

    test('narrative fields exist in template', () {
      expect(templateFieldNames, contains('asfdasdfWER'));       // Site Safety
      expect(templateFieldNames, contains('HJTYJH'));            // SESC Measures
      expect(templateFieldNames, contains('Text5#loioliol0'));   // Traffic Control
      expect(templateFieldNames, contains('iol8ol'));            // Visitors
    });

    test('contractor name fields exist in template', () {
      expect(templateFieldNames, contains('Namegdzf'));          // Prime
      expect(templateFieldNames, contains('sfdasd'));             // Sub 1
      expect(templateFieldNames, contains('Name_3dfga'));         // Sub 2
      expect(templateFieldNames, contains('Name_31345145'));      // Sub 3
      expect(templateFieldNames, contains('Name_3234523'));       // Sub 4
    });

    test('prime contractor personnel fields exist', () {
      expect(templateFieldNames, contains('QntyForeman'));
      expect(templateFieldNames, contains('QntyOperator'));
      expect(templateFieldNames, contains('QntyLaborer'));
    });

    test('sub 2-4 contractor personnel fields exist', () {
      for (final suffix in ['_3', '_4', '_5']) {
        expect(templateFieldNames, contains('QntyForeman$suffix'));
        expect(templateFieldNames, contains('QntyOperator$suffix'));
        expect(templateFieldNames, contains('QntyLaborer$suffix'));
      }
    });

    test('equipment fields exist in template', () {
      // Prime equipment
      for (final name in ['ggggsssssssssss', '3#aaaaaaaaaaa0', '3#0asfdasfd', '4', '3ggggggg']) {
        expect(templateFieldNames, contains(name));
      }
      // Sub 1 equipment
      for (final name in ['8888888888888', r'\\\\\\\\\\\\', "'''''''''''", '[[[[[[[[[[[[[', 'vvvvvvvvvvvv']) {
        expect(templateFieldNames, contains(name));
      }
      // Sub 2-4 equipment (spot check)
      expect(templateFieldNames, contains('4_3234'));
      expect(templateFieldNames, contains('12431243'));
      expect(templateFieldNames, contains('4_53674'));
    });

    test('signature and utility fields exist', () {
      expect(templateFieldNames, contains('hhhhhhhhhhhwerwer'));  // Signature
      expect(templateFieldNames, contains('8olyk,l'));            // Materials
      expect(templateFieldNames, contains('Text6'));              // Attachments
      expect(templateFieldNames, contains('yio'));                // Extras & Overruns
    });

    test('template has expected field count', () {
      // NOTE: Exact count from debug PDF — update if template changes
      expect(document.form.fields.count, greaterThanOrEqualTo(170));
    });

    test('pdf_service _setField string literals match template fields', () {
      // WHY: Cross-reference the actual field name strings used in pdf_service.dart
      // against the template to catch typos or stale mappings.
      // NOTE: These are the string literals passed to _setField in pdf_service.dart.
      // Update this list whenever mappings are changed in Step 5.3.
      final mappingConstants = <String>[
        'Text10', 'Text11', 'Text15', 'Text12', 'Text13', // Header
        'Text3', 'Text4',                                   // Activities
        'asfdasdfWER', 'HJTYJH', 'Text5#loioliol0', 'iol8ol', // Narrative
        '8olyk,l', 'Text6', 'yio', 'hhhhhhhhhhhwerwer',     // Materials, Attachments, Extras, Signature
        // Contractor name fields
        'Namegdzf', 'sfdasd', 'Name_3dfga', 'Name_31345145', 'Name_3234523',
        // Prime personnel
        'QntyForeman', 'QntyOperator', 'QntyLaborer',
        // Sub 2-4 personnel
        'QntyForeman_3', 'QntyOperator_3', 'QntyLaborer_3',
        'QntyForeman_4', 'QntyOperator_4', 'QntyLaborer_4',
        'QntyForeman_5', 'QntyOperator_5', 'QntyLaborer_5',
      ];
      for (final name in mappingConstants) {
        expect(templateFieldNames, contains(name),
            reason: 'Mapping constant "$name" not found in template');
      }
    });
  });
}
```

### Sub-phase 6.3: Create activities serialization test

**Files:**
- Create: `test/features/entries/presentation/controllers/activities_serialization_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.3.1: Write serialization round-trip test

```dart
// WHY: Verify JSON round-trip: serialize → deserialize, legacy fallback, empty handling
// FROM SPEC: "JSON round-trip: serialize → deserialize, legacy plain text fallback, empty locations omitted"
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/entries/presentation/controllers/entry_editing_controller.dart';
import 'package:construction_inspector/features/locations/data/models/location.dart';

void main() {
  group('Activities JSON Serialization', () {
    late EntryEditingController controller;

    setUp(() {
      controller = EntryEditingController();
    });

    tearDown(() => controller.dispose());

    test('multi-location round-trip preserves data', () {
      final json = jsonEncode([
        {'locationId': 'loc-1', 'locationName': 'Bridge Deck', 'text': 'Poured section 3'},
        {'locationId': 'loc-2', 'locationName': 'Abutment', 'text': 'Formed east wall'},
      ]);
      controller.loadActivitiesJson(json);

      final result = controller.getActivitiesJson();
      expect(result, isNotNull);
      final parsed = jsonDecode(result!) as List;
      expect(parsed, hasLength(2));
      expect(parsed[0]['text'], 'Poured section 3');
      expect(parsed[1]['locationName'], 'Abutment');
    });

    test('single location round-trip', () {
      final json = jsonEncode([
        {'locationId': 'loc-1', 'locationName': 'Station 42+00', 'text': 'Grading work'},
      ]);
      controller.loadActivitiesJson(json);

      final result = controller.getActivitiesJson();
      final parsed = jsonDecode(result!) as List;
      expect(parsed, hasLength(1));
      expect(parsed[0]['text'], 'Grading work');
    });

    test('legacy plain text handled as fallback', () {
      controller.loadActivitiesJson('Grading and compaction continued.');
      final result = controller.getActivitiesJson();
      final parsed = jsonDecode(result!) as List;
      expect(parsed, hasLength(1));
      expect(parsed[0]['locationId'], isNull);
      expect(parsed[0]['text'], 'Grading and compaction continued.');
    });

    test('null activities returns null', () {
      controller.loadActivitiesJson(null);
      expect(controller.getActivitiesJson(), isNull);
    });

    test('empty text locations omitted from output', () {
      final json = jsonEncode([
        {'locationId': 'loc-1', 'locationName': 'Bridge', 'text': 'Work done'},
        {'locationId': 'loc-2', 'locationName': 'Abutment', 'text': ''},
      ]);
      controller.loadActivitiesJson(json);

      final result = controller.getActivitiesJson();
      final parsed = jsonDecode(result!) as List;
      expect(parsed, hasLength(1));
      expect(parsed[0]['locationId'], 'loc-1');
    });

    test('initializeLocations creates controllers for new locations', () {
      controller.loadActivitiesJson(null);
      final locations = [
        Location(id: 'loc-1', name: 'Bridge', projectId: 'p1'),
        Location(id: 'loc-2', name: 'Road', projectId: 'p1'),
      ];
      controller.initializeLocations(locations);

      expect(controller.locationActivitiesControllers.keys, containsAll(['loc-1', 'loc-2']));
    });

    test('switchLocation changes active controller', () {
      final json = jsonEncode([
        {'locationId': 'loc-1', 'locationName': 'Bridge', 'text': 'Bridge text'},
        {'locationId': 'loc-2', 'locationName': 'Road', 'text': 'Road text'},
      ]);
      controller.loadActivitiesJson(json);

      controller.switchLocation('loc-1');
      expect(controller.activitiesController.text, 'Bridge text');

      controller.switchLocation('loc-2');
      expect(controller.activitiesController.text, 'Road text');
    });
  });
}
```

### Sub-phase 6.3b: Create formatting helper tests

**Files:**
- Create: `test/features/pdf/services/pdf_formatting_helpers_test.dart`

**Agent**: `qa-testing-agent`

#### Step 6.3b.1: Write formatting helper tests

```dart
// WHY: Spec Section 8 requires _formatTempRange, _formatMaterials,
// _formatAttachments produce bounded output (MED priority)
// FROM SPEC: "Formatting helpers produce correctly bounded output"
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PDF Formatting Helpers', () {
    // NOTE: These test the static/private helpers. If helpers are private,
    // test them indirectly via PdfService or extract to a utility class.

    test('_formatTempRange produces bounded output', () {
      // Verify format: "60°F - 80°F" or similar
      // Verify null inputs produce empty/fallback string
      // Verify extreme values don't overflow
    });

    test('_formatMaterials truncates at limit', () {
      // Verify that materials text exceeding ~1500 chars is truncated with "..."
      // Verify normal-length text passes through unchanged
    });

    test('_formatAttachments truncates at limit', () {
      // Verify that attachments text exceeding ~1500 chars is truncated with "..."
      // Verify normal-length text passes through unchanged
    });

    test('_formatActivitiesForPdf handles multi-location', () {
      // Verify concatenated format: "Location A -\n\ntext\n\nLocation B -\n\ntext"
      // Verify empty locations omitted
      // Verify legacy plain text passes through
    });

    test('_formatActivitiesForPdf handles overflow split', () {
      // Verify text > 2000 chars splits into Text3/Text4 boundary
      // Verify split happens at paragraph break when possible
    });
  });
}
```

### Sub-phase 6.4: Update existing tests — locationId removal

**Files:**
- Modify: `test/services/pdf_service_test.dart` (update `_createTestPdfData`)
- Modify: All test files referencing `locationId` on DailyEntry

**Agent**: `qa-testing-agent`

#### Step 6.4.1: Update pdf_service_test.dart helper

```dart
// In _createTestPdfData (line 916):
// Remove locationId from DailyEntry constructor call (if present)
// No other changes needed — IdrPdfData doesn't have a locationId field
```

#### Step 6.4.2: Update DailyEntry test factories across test suite

```dart
// Search all test files for DailyEntry( or DailyEntry.fromMap( containing locationId
// Remove locationId parameter from each call site
// Files to check (from blast radius): ~20 test files
// Pattern: Remove `locationId: 'some-id',` from DailyEntry constructors
```

#### Step 6.4.3: Remove filter-by-location tests

```dart
// Remove or update tests for:
// - DailyEntryProvider.filterByLocation
// - FilterEntriesUseCase.byLocation
// - DailyEntryRepository.getByLocationId
// - EntryFilterType.location enum usage
```

### Sub-phase 6.5: Update harness seed data

**Files:**
- Modify: `lib/core/driver/harness_seed_data.dart`

**Agent**: `qa-testing-agent`

#### Step 6.5.1: Remove locationId from entry seeding

```dart
// REMOVE: locationId parameter from DailyEntry construction in seed data
// The harness creates test entries — remove any location assignment
```

### Sub-phase 6.6: Verify all tests compile — flutter analyze

**Agent**: `qa-testing-agent`

#### Step 6.6.1: Run flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues

---

## Phase 7: Final Cleanup

### Sub-phase 7.1: Dead code audit

**Files:**
- Audit all files modified in Phases 1-6

**Agent**: `general-purpose`

#### Step 7.1.1: Verify all dead code removed

Check that these are fully removed (no orphan references):
- `DailyEntryLocalDatasource.getByLocationId()`
- `DailyEntryRemoteDatasource.getByLocationId()`
- `DailyEntryRepositoryImpl.getByLocationId()`
- `DailyEntryRepository.getByLocationId()` (interface)
- `FilterEntriesUseCase.byLocation()`
- `DailyEntryProvider.filterByLocation()`
- `EntryFilterType.location`
- `_locationNameCache` in home_screen.dart
- `EntryBasicsSection` file itself (dead code — zero instantiations)
- Location display in 4 list/review screens
- `locationId` references in DailyEntry and all call sites

#### Step 7.1.2: Verify no unused imports

```dart
// Check each modified file for unused imports after removals
// Common: location model imports in files that no longer reference locations
```

### Sub-phase 7.2: Final verification

**Agent**: `general-purpose`

#### Step 7.2.1: Run flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: 0 issues — plan complete

---

## Summary

| Metric | Count |
|--------|-------|
| Phases | 7 |
| Sub-phases | 22 |
| Steps | ~55 |
| Production files modified | 25 |
| Test files modified | ~20 |
| New files created | 4 |
| Methods removed | 9+ |
| Methods added | 8 |
| Methods modified | 15+ |

| Phase | Agent | Focus |
|-------|-------|-------|
| 1 | `backend-data-layer-agent` | DailyEntry model |
| 2 | `backend-data-layer-agent` + `backend-supabase-agent` | Data/domain cleanup |
| 3 | `frontend-flutter-specialist-agent` | Controller per-location |
| 4 | `frontend-flutter-specialist-agent` | UI components + screens |
| 5 | `pdf-agent` + `frontend-flutter-specialist-agent` | PDF mapping rebuild |
| 6 | `qa-testing-agent` + `pdf-agent` | Tests + verification tooling |
| 7 | `general-purpose` | Dead code + final verify |
