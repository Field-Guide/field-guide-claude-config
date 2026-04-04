# IDR PDF Mapping Rebuild & Location-Scoped Activities

**Date:** 2026-04-03
**Status:** Approved
**Size:** M (full pipeline)

---

## 1. Overview

### Purpose
Fix incorrect/unverified IDR PDF field mappings and add location-scoped activities so inspectors on multi-location jobs can organize their daily narrative by location, with clean formatting on the exported PDF.

### Scope

**Included:**
- Full debug PDF generation and field-by-field visual verification of all 179 template fields
- Complete rebuild of all PDF field mappings in `pdf_service.dart`
- Inline location selector on the activities section (contractor card pattern)
- JSON serialization of per-location activities in `DailyEntry.activities`
- Formatted concatenation on PDF export
- Removal of `locationId` from `DailyEntry` model and header UI
- Removal of `filterByLocation` (no longer useful with JSON-embedded locations)
- Python verification script + Dart unit test for mapping correctness

**Excluded:**
- New database tables or schema migrations
- Sync changes
- Modifications to `idr_template.pdf` (sacred — source of truth)
- Other entry wizard features

### Success Criteria
- [ ] Every PDF field verified against debug PDF — zero "guessing" comments remain
- [ ] All entry wizard data with a corresponding template field is exported
- [ ] Per-location activities serialize/deserialize losslessly via JSON
- [ ] Single-location entries (majority case) work identically to today — no extra UI friction
- [ ] Python script produces a visually verifiable test PDF
- [ ] Dart unit test asserts all field name mappings, runs in CI
- [ ] No data truncation or overflow in any filled field

---

## 2. Data Model

### Changes to `DailyEntry`

| Field | Change | Notes |
|-------|--------|-------|
| `locationId` | **REMOVE** | No longer needed — locations are scoped to activities |
| `activities` | **REPURPOSE** | Same column, now stores JSON array of location-activity pairs |

### Activities Serialization Format

```json
// Multi-location (2+ locations selected)
[
  {"locationId": "uuid-1", "locationName": "Bridge Deck", "text": "Poured section 3..."},
  {"locationId": "uuid-2", "locationName": "Abutment", "text": "Formed east wall..."}
]

// Single location
[
  {"locationId": "uuid-1", "locationName": "Station 42+00", "text": "Grading work..."}
]

// Legacy entries (plain string, no JSON) — treated as single un-located text
"Grading and compaction work continued on the north side."
```

### Backward Compatibility

- **Existing entries:** If `activities` doesn't parse as JSON array, wrap it as `[{"locationId": null, "locationName": null, "text": "<existing text>"}]` at read time. No data migration needed.
- **`locationId` removal:** Remove from `DailyEntry` model, `copyWith`, `toMap`, `fromMap`, `getMissingFields`. The SQLite column stays (data preservation) but is no longer read or written by the app.

### No Schema Migration Required

The `activities` column is already `TEXT` — JSON strings fit. The `location_id` column stays in SQLite (we just stop reading/writing it). No version bump needed.

### Sync Considerations

- `activities` syncs as before — it's still a text column on `daily_entries`
- `location_id` stops syncing (removed from the adapter's column list)
- No new sync adapters needed

---

## 3. User Flow

### Entry Points
Same as today — create or edit an entry from the home screen or entries list.

### Activities Section Flow

**Single-location job (most inspectors, most of the time):**
```
Open entry → Activities section shows one text field (no location selector visible)
→ Type activities → Save → Done
```
The location selector only appears when the project has 2+ locations. If the project has 0-1 locations, the section looks exactly like it does today.

**Multi-location job:**
```
Open entry → Activities section shows inline location chips (like contractor cards)
→ Tap "Bridge Deck" chip → Text field shows Bridge Deck activities → Type
→ Tap "Abutment" chip → Text field switches to Abutment activities → Type
→ Save → JSON serialized to activities column
```

### PDF Export Flow
```
Tap Export PDF → PdfDataBuilder loads activities JSON
→ Deserializes → Concatenates with location headers
→ Fills Text3 (and Text4 overflow if needed)
→ Preview screen → Save/Share
```

### Key Interactions

| Action | Result |
|--------|--------|
| Project has 0-1 locations | No location chips shown, plain text field (today's UX) |
| Project has 2+ locations | Inline location chips appear above activities field |
| Tap location chip | Activities field switches to that location's text |
| No location selected yet | Show first location by default |
| Export PDF | Concatenated: `"Location A -\n\ntext\n\nLocation B -\n\ntext"` |
| Open legacy entry | Plain text displayed as-is, no location association |

### Removed Interactions

| Removed | Reason |
|---------|--------|
| Location dropdown in header card | Locations now scoped to activities section only |

---

## 4. UI Components

### Modified Widgets

| Widget | File | Change |
|--------|------|--------|
| `EntryActivitiesSection` | `lib/features/entries/presentation/widgets/entry_activities_section.dart` | Add inline location chips above text field, manage per-location text switching |
| `EntryBasicsSection` | `lib/features/entries/presentation/widgets/entry_basics_section.dart` | Remove location dropdown |
| `EntryEditingController` | `lib/features/entries/presentation/controllers/entry_editing_controller.dart` | Replace single `activitiesController` with `Map<String, TextEditingController>` keyed by locationId |

### No New Widgets

The inline location selector reuses the same chip/tile pattern from `ContractorEditorWidget`. No new shared widgets needed.

### Activities Section Layout

```
+------------------------------------------+
| Activities                          [?]  |
+------------------------------------------+
| [Bridge Deck] [Abutment] [Station 42]   |  ← location chips (only if 2+ locations)
+------------------------------------------+
| ┌──────────────────────────────────────┐ |
| │ Poured section 3 of bridge deck.    │ |
| │ Concrete tested at 4000 PSI.        │ |
| │                                      │ |
| └──────────────────────────────────────┘ |
+------------------------------------------+
```

Single-location projects show just the text field — no chips, no extra chrome.

### TestingKeys Required

- `TestingKeys.activityLocationChip` — for tapping location chips in E2E tests
- Existing `TestingKeys.activitiesField` stays as-is

---

## 5. State Management

### EntryEditingController Changes

**Current:** One `TextEditingController` for activities, one `FocusNode`.

**New:**
- `Map<String, TextEditingController> _locationActivitiesControllers` — keyed by locationId
- `String? _activeLocationId` — which location's text field is showing
- Methods: `switchLocation(locationId)`, `getActivitiesJson()`, `loadActivitiesJson(String?)`

**Serialization on save:**
```
controllers map → List<Map> → JSON string → DailyEntry.activities column
```

**Deserialization on load:**
```
DailyEntry.activities string → try JSON parse → populate controllers map
                             → if not JSON → single controller with raw text (legacy)
```

### No New Providers

- `LocationProvider` already exists and loads locations for the project
- `EntryEditingController` handles the per-location state internally
- `PdfDataBuilder` reads the serialized JSON at export time — no new provider interaction

### Data Flow

```
Location chips (UI) → switchLocation() → swap visible controller
Save button → getActivitiesJson() → JSON string → DailyEntry.activities → SQLite → Supabase
Export PDF → PdfDataBuilder reads activities JSON → concatenates with headers → PdfService
```

### Error Handling
- Invalid JSON in `activities` column → treat as legacy plain text
- Location deleted from project after activities written → preserve the text, show locationName from JSON (not a live lookup)
- Empty text for a location → omit from PDF output (don't print blank location headers)

---

## 6. PDF Mapping Rebuild

### Step 1: Generate Debug PDF
Run `generateDebugPdf()` to fill all 179 fields with `"<index>:<fieldName>"`. Use Python script to render each page as an image.

### Step 2: Visual Identification
Walk every field on every page, recording which visual position (e.g., "Project Name box on page 1") corresponds to which field name. Build a complete mapping reference.

### Step 3: Rebuild Mappings

**Header fields** — verify/fix all:
`date`, `projectNumber`, `projectName`, `weather`, `tempRange`, `projectRep` (currently unmapped)

**Contractor fields** — verify/fix all 5 slots:
`name`, `foremanCount`, `operatorCount`, `laborerCount` per slot. Confirm whether Sub 1 truly has no personnel fields or if they were just never found.

**Equipment fields** — verify/fix all 25 slots (5 per contractor):
Confirm each equipment name field visually.

**Narrative fields** — verify/fix all (currently "guessing"):
`siteSafety`, `sescMeasures`, `trafficControl`, `visitors`, `extrasOverruns` (currently unmapped)

**Materials/Quantities** — verify the correct field.

**Attachments** — verify `Text6`.

**Signature** — verify `hhhhhhhhhhhwerwer`.

**Activities** — verify `Text3` and `Text4` (overflow). Implement concatenation format for multi-location entries.

### Step 4: Fix Formatting
For each mapped field, check the field's bounding box size and ensure data is formatted to fit. Handle overflow for long-text fields (activities, materials, attachments).

### Step 5: Verification Tooling

**Python script (`verify_idr_mapping.py`):**
- Fills template with labeled test data (e.g., `"PROJECT_NAME"` in the project name field)
- Renders to PNG images
- Visual inspection confirms each label is in the correct position

**Dart unit test (`pdf_field_mapping_test.dart`):**
- Asserts every expected field name exists in the template
- Asserts the mapping constants match expected field names
- Asserts formatting helpers produce correctly bounded output
- Runs in CI

---

## 7. Migration/Cleanup

### `locationId` Removal

| Layer | File | Change |
|-------|------|--------|
| Model | `daily_entry.dart` | Remove `locationId` field, `copyWith`, `toMap`, `fromMap` |
| Model | `daily_entry.dart` | Update `getMissingFields()` — remove location check |
| Basics widget | `entry_basics_section.dart` | Remove location dropdown |
| Editor screen | `entry_editor_screen.dart` | Remove location-related params and logic |
| Review screen | `entry_review_screen.dart` | Remove `_canMarkReady` location check |
| Home screen | `home_screen.dart` | Remove location name cache/display |
| Entries list | `entries_list_screen.dart` | Remove location display |
| Drafts list | `drafts_list_screen.dart` | Remove location display |
| Review summary | `review_summary_screen.dart` | Remove location display |
| Sync adapter | `daily_entry_adapter.dart` | Remove `location_id` from column mapping |
| Filter use case | `filter_entries_use_case.dart` | Remove `byLocation` |
| Provider | `daily_entry_provider.dart` | Remove `filterByLocation` |
| Local datasource | `daily_entry_local_datasource.dart` | Remove `getByLocationId` |
| Remote datasource | `daily_entry_remote_datasource.dart` | Remove `getByLocationId` |
| Repository | interface + impl | Remove `getByLocationId` |
| Harness | `harness_seed_data.dart` | Remove location seeding on entry |

### SQLite Column
`location_id` column **stays in the table** — we just stop reading/writing it. No destructive migration.

### Filter by Location
**Removed entirely.** Location filtering on entries was marginal value with the old model and becomes unreliable with JSON. Easy to add back if needed later.

### Dead Code Removal
- `getByLocationId` across all datasource/repository layers
- Location-related params in `EntryBasicsSection`
- Location display logic in 4 list screens
- `filterByLocation` and `byLocation` filter type

### No Backward Compatibility Hacks
Existing entries with a `location_id` value in SQLite keep it — we just ignore it. Existing `activities` plain text is handled by the JSON parse fallback.

---

## 8. Testing Strategy

| Test | Focus | Priority |
|------|-------|----------|
| `pdf_field_mapping_test.dart` | Assert all 179 field names exist in template, mapping constants correct | HIGH |
| `activities_serialization_test.dart` | JSON round-trip: serialize → deserialize, legacy plain text fallback, empty locations omitted | HIGH |
| `verify_idr_mapping.py` | Visual verification — fill with labeled data, render to PNG | HIGH (manual, rerun when mappings change) |
| Formatting helpers | `_formatTempRange`, `_formatMaterials`, `_formatAttachments` produce bounded output | MED |

CI runs the Dart tests. Python script is a manual verification tool.

---

## 9. Performance

No concerns. JSON parsing a handful of location-activity pairs is negligible. PDF generation time unchanged — same number of fields filled.

---

## 10. Security

No impact. No new tables, no new RLS policies, no new data exposure. Activities column contains the same kind of data it always has — just structured differently. Sync behavior unchanged.

---

## Decisions Log

| Decision | Chosen | Rejected | Rationale |
|----------|--------|----------|-----------|
| Location-activities storage | JSON in existing `activities` column | New junction table | Same UX, ~5-8 files vs ~50 files. No schema/sync changes needed |
| Serialization format | JSON array | Delimited text, flat concatenation | Only format that guarantees clean round-trips |
| `locationId` on DailyEntry | Remove (stop read/write, keep SQLite column) | Keep as primary | Locations are purely an activities-formatting concern now |
| Filter by location | Remove entirely | Rewrite to JSON search | Marginal value, unreliable with JSON. Easy to add back |
| Verification tooling | Python script + Dart unit test | App-only verification | Python for visual confirmation, Dart for CI regression |
| PDF template | Untouchable — source of truth | Modify field names | Template is built into the app, must not be altered |
