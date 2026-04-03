# Entry UI Continuity Codex Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Unify contractor cards, weather/header, export, quantity calculator, PDF preview, and calendar flows into a consistent, continuous UI.
**Spec:** `.claude/specs/2026-04-03-entry-ui-continuity-codex-spec.md`
**Tailor:** `.claude/tailor/2026-04-03-entry-ui-continuity-codex/`

**Architecture:** Refactor ContractorEditorWidget's layout skeleton for mode consistency without changing control types (steppers stay, chips stay). Create a shared contractor selection route/surface using compact contractor cards, not a bottom sheet. Simplify HomeScreen calendar to a read-only day-selection flow with entry pills directly under the calendar. Restore weather auto-fetch. Add in-app PDF preview. Relocate calculator to quantities section.
**Tech Stack:** Flutter/Dart, Provider, AppSectionCard design system, printing package (PdfPreview widget)
**Blast Radius:** 11 direct files, 3 dependent (DI/router), 0 schema changes, 6 dead code removals

---

## Phase 1: Shared Contractor Selection Surface

### Sub-phase 1.1: Create ContractorSelectionScreen

**Files:**
- Create: `lib/features/contractors/presentation/screens/contractor_selection_screen.dart`
- Reference: `lib/features/entries/presentation/screens/report_widgets/report_add_contractor_sheet.dart` (existing pattern)
- Reference: `lib/features/entries/presentation/screens/home_screen.dart:1582-1665` (legacy duplication to remove)

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.1.1: Create shared contractor selection screen/route

```dart
// WHY: Contractor selection must no longer use the current bottom-sheet/list-tile
// pattern. This shared screen/route becomes the canonical entry-flow selection UI.
// FROM SPEC: "Do not use the current popup dialog or the current bottom-sheet
// list-tile pattern as the long-term shared flow"
// FROM SPEC: "Compact selectable contractor cards" and "Contractor name top-most,
// Prime/Sub underneath"
// IMPORTANT: This surface is for selecting WHICH contractor to add to the entry.
// It must NOT show daily personnel counts or daily equipment usage, because those
// change per entry and are configured only after the contractor is selected.

import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
import 'package:construction_inspector/features/contractors/data/models/models.dart';

/// Pushes a contractor-selection screen and returns the chosen contractor.
///
/// Returns the selected [Contractor] or null if dismissed.
Future<Contractor?> showContractorSelectionScreen({
  required BuildContext context,
  required List<Contractor> availableContractors,
  String title = 'Select Contractor',
}) async {
  return Navigator.of(context).push<Contractor>(
    MaterialPageRoute(
      builder: (_) => ContractorSelectionScreen(
        availableContractors: availableContractors,
        title: title,
      ),
      fullscreenDialog: true,
    ),
  );
}

class ContractorSelectionScreen extends StatefulWidget {
  final List<Contractor> availableContractors;
  final String title;

  const ContractorSelectionScreen({
    super.key,
    required this.availableContractors,
    required this.title,
  });

  @override
  State<ContractorSelectionScreen> createState() =>
      _ContractorSelectionScreenState();
}

class _ContractorSelectionScreenState extends State<ContractorSelectionScreen> {
  final _filterController = TextEditingController();
  List<Contractor> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.availableContractors;
    _filterController.addListener(_onFilterChanged);
  }

  void _onFilterChanged() {
    final query = _filterController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.availableContractors
          : widget.availableContractors
              .where((c) => c.name.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(DesignConstants.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.availableContractors.length > 5) ...[
              TextField(
                controller: _filterController,
                decoration: const InputDecoration(
                  hintText: 'Search contractors...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
              const SizedBox(height: DesignConstants.space3),
            ],
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignConstants.space2),
                itemBuilder: (ctx, index) {
                  final contractor = _filtered[index];
                  return _ContractorSelectionCard(
                    contractor: contractor,
                    onTap: () => Navigator.pop(context, contractor),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractorSelectionCard extends StatelessWidget {
  final Contractor contractor;
  final VoidCallback onTap;

  const _ContractorSelectionCard({
    required this.contractor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = FieldGuideColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(DesignConstants.space3),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
          color: fg.surfaceElevated,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contractor.name,
              style: tt.titleSmall!.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: DesignConstants.space1),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: contractor.isPrime
                    ? cs.primary.withValues(alpha: 0.1)
                    : cs.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
              ),
              child: Text(
                contractor.isPrime ? 'Prime' : 'Subcontractor',
                style: tt.labelSmall!.copyWith(
                  color: contractor.isPrime ? cs.primary : cs.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Step 1.1.2: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

---

## Phase 2: Contractor Card Layout Unification

### Sub-phase 2.1: Refactor ContractorEditorWidget Layout Skeleton

**Files:**
- Modify: `lib/features/entries/presentation/widgets/contractor_editor_widget.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 2.1.1: Unify card shell and section ordering

Refactor the `build()` method of `ContractorEditorWidget` to enforce consistent layout ordering across all modes. **Do NOT change the counter steppers or equipment chips — only the card shell, spacing, and header treatment.**

Changes to make in `contractor_editor_widget.dart`:

1. **Header order** — Contractor name top-most in ALL modes. Move the prime/sub badge to a secondary row directly under the name (currently it may be in the header row action area in some modes).

2. **Section ordering** — Enforce: name → type badge → personnel section → equipment section in all modes (view, edit, setup). Currently this order exists but spacing differs.

3. **Spacing rhythm** — Use consistent `DesignConstants.space3` between sections, `DesignConstants.space2` within sections. Replace any hardcoded pixel values with design constants.

4. **Add affordances** — The "Add Personnel Type" and "Add Equipment" buttons in setup mode should use the same visual treatment (outlined button with icon, consistent padding).

```dart
// WHY: Contractor cards must share one spacing system and one section order
// across project setup and the entry editor.
// NOTE: Calendar is being simplified to a read-only pill flow, so it no longer
// owns an editable contractor-card surface.
// FROM SPEC: "Header order stays the same in all modes: contractor name, mode actions"
// FROM SPEC: "Contractor type badge/status lives on a secondary row directly under the contractor name"
// NOTE: Counter steppers and equipment chips are PRESERVED — only layout/spacing changes.

// In build():
@override
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final fg = FieldGuideColors.of(context);

  return GestureDetector(
    onTap: isEditing ? null : onTap,
    child: Container(
      // IMPORTANT: Consistent container decoration across all modes
      padding: const EdgeInsets.all(DesignConstants.space3),
      decoration: BoxDecoration(
        border: Border.all(
          color: isEditing ? cs.primary : cs.outline.withValues(alpha: 0.3),
          width: isEditing ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
        color: isEditing
            ? cs.primary.withValues(alpha: 0.05)
            : fg.surfaceElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Contractor name (top-most, all modes)
          _buildHeader(context),
          const SizedBox(height: DesignConstants.space1),
          // 2. Prime/Sub badge (secondary row, all modes)
          _buildTypeBadge(context),
          const SizedBox(height: DesignConstants.space3),
          // 3. Personnel section (always before equipment)
          _buildPersonnelSection(context),
          const SizedBox(height: DesignConstants.space3),
          // 4. Equipment section (always after personnel)
          _buildEquipmentSection(context),
          // 5. Mode actions (edit done button, setup management)
          if (isEditing || setupMode) ...[
            const SizedBox(height: DesignConstants.space2),
            _buildModeActions(context),
          ],
        ],
      ),
    ),
  );
}
```

The implementer should extract these helper methods from the existing build method body, preserving the current stepper/chip widget implementations within `_buildPersonnelSection` and `_buildEquipmentSection`.

#### Step 2.1.2: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

### Sub-phase 2.2: Wire Shared Selection into Entry Editor

**Files:**
- Modify: `lib/features/entries/presentation/widgets/entry_contractors_section.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 2.2.1: Replace entry editor contractor selection with shared sheet

In `EntryContractorsSection._showAddContractorDialog` (line 308), replace the call to `showReportAddContractorSheet` with `showContractorSelectionScreen`:

```dart
// WHY: Consolidating to one shared contractor selection pattern
// FROM SPEC: "Add/select contractor flow uses one shared pattern rather than three separate ones"
import 'package:construction_inspector/features/contractors/presentation/screens/contractor_selection_screen.dart';

Future<void> _showAddContractorDialog(BuildContext context) async {
  // ... existing logic to compute availableContractors stays the same ...

  final contractor = await showContractorSelectionScreen(
    context: context,
    availableContractors: availableContractors,
  );

  if (contractor == null || !context.mounted) return;

  // ... existing logic to add contractor to entry stays the same ...
}
```

#### Step 2.2.2: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

### Sub-phase 2.3: Replace Project Setup Contractor Dialog

**Files:**
- Modify: `lib/features/projects/presentation/screens/project_setup_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 2.3.1: Replace popup dialog with create-then-setup flow

Replace `_showAddContractorDialog` (line 818-832) to use a lightweight create step followed by immediate rendering in the contractor card in setup mode.

```dart
// WHY: Project setup should create a contractor then immediately bring it into
// the contractor card as the setup surface.
// FROM SPEC: "user enters contractor name and type in a lightweight first step,
// app creates the contractor, app immediately renders that contractor in the
// standard contractor card in setup mode"
// FROM SPEC: "Project setup no longer uses the current contractor popup dialog"

Future<void> _showAddContractorDialog() async {
  final contractorProvider = context.read<ContractorProvider>();

  // Lightweight creation step — name + type only
  final result = await AppDialog.show<({String name, bool isPrime})>(
    context,
    title: 'New Contractor',
    content: _NewContractorForm(),
    // NOTE: Suppress default OK button — _NewContractorForm provides its own
    // submit/cancel buttons with validation logic
    actionsBuilder: (_) => [],
  );

  if (result == null || !mounted) return;

  // Create the contractor
  // NOTE: Contractor model uses `type` field with ContractorType enum, not `isPrime` bool
  final newContractor = Contractor(
    projectId: _projectId!,
    name: result.name,
    type: result.isPrime ? ContractorType.prime : ContractorType.sub,
  );
  await contractorProvider.createContractor(newContractor);
  if (!mounted) return;

  // Seed default personnel types
  final personnelTypeProvider = context.read<PersonnelTypeProvider>();
  final created = contractorProvider.contractors.lastOrNull;
  if (created != null) {
    await personnelTypeProvider.createDefaultTypesForContractor(_projectId!, created.id);
  }

  // The contractor card will now appear in the list in setup mode automatically
  // because ContractorProvider notifies listeners and the list rebuilds.
  // No further navigation needed — user configures personnel/equipment inline.
}
```

The implementer needs to create `_NewContractorForm` as a private StatefulWidget within `project_setup_screen.dart` with a name TextField and a prime/sub toggle, returning the record on submit.

> **SECURITY NOTE:** The `_NewContractorForm` must validate that the name is non-empty after `trim()` before allowing submission. Do not allow blank contractor names to be created.

> **WORKTREE WARNING:** `project_setup_screen.dart` has unrelated modifications in the current worktree. The implementer must preserve those unrelated changes when editing this file. Use surgical edits only — do not rewrite the entire file.

#### Step 2.3.2: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

---

## Phase 3: Calendar View Simplification

### Sub-phase 3.1: Remove Inline Editing from HomeScreen

**Files:**
- Modify: `lib/features/entries/presentation/screens/home_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 3.1.1: Remove editable preview sections and contractor editing

Remove the following methods and their call sites from `_HomeScreenState`:

1. **`_buildEditablePreviewSection`** (lines 1269-1331) — Remove method. Remove 4 call sites at lines 1063, 1139, 1169, 1225.

2. **`_buildContractorsSection`** (lines 1334-1496) — Remove method and its call site.

3. **`_buildContractorEditorRow`** (lines 1498-1580) — Remove method.

4. **`_showAddContractorDialog`** (lines 1582-1665) — Remove method.

5. **Remove the import** of `contractor_editor_widget.dart` from `home_screen.dart` (it will no longer be needed).

6. **Remove unused controller/state** related to inline editing that was only serving these preview sections (e.g., `_editingController` references for the preview sections, if any are calendar-specific).

```dart
// WHY: Calendar page is now read-only. Clicking a day shows entry pills;
// clicking a pill opens the full entry editor.
// FROM SPEC: "Remove inline editing controls from the calendar page"
// FROM SPEC: "Remove the current report-preview editing pane from the calendar page"
```

#### Step 3.1.2: Replace editable preview area with bottom-of-calendar entry pill flow

Where the editable preview sections and lower report pane were rendered, replace them with a compact row of entry pills that sits directly below the calendar section. Tapping a pill navigates to the full entry editor.

```dart
// FROM SPEC: "Selecting a day shows an entry pill at the bottom of the calendar
// when that day has an entry. Clicking that pill opens the full entry editor."
// IMPORTANT: Do not replace the old editable pane with another summary pane.
// The intent is a simpler day-selected state plus entry pill action.

// Replace the current lower preview area with pill-only content:
Widget _buildReadOnlyEntryPill(DailyEntry entry) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final fg = FieldGuideColors.of(context);

  return InkWell(
    key: TestingKeys.calendarEntryPill(entry.id),
    onTap: () {
      // Navigate to full entry editor
      // NOTE: Use go_router named route for type-safe navigation
      context.pushNamed('report', pathParameters: {'entryId': entry.id});
    },
    borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
    child: Container(
      padding: const EdgeInsets.all(DesignConstants.space3),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
        color: fg.surfaceElevated,
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: cs.primary, size: 20),
          const SizedBox(width: DesignConstants.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall(
                  locationNameFor(entry),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.weather != null)
                  AppText.bodySmall(
                    '${entry.weather!.displayName} · ${entry.tempLow ?? '?'}°F – ${entry.tempHigh ?? '?'}°F',
                    color: cs.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: fg.textTertiary),
        ],
      ),
    ),
  );
}
```

Implementation requirements:
- The pill row should live immediately under the calendar rather than inside a second full report pane.
- If multiple entries exist for the selected day, render multiple pills/compact cards in that same bottom area.
- Remove the old split-view/report-preview structure instead of replacing it with another large preview container.
- Keep the day selection behavior and event indicators already present in the calendar itself.

#### Step 3.1.3: Add TestingKeys.calendarEntryPill if not present

Check `lib/shared/testing_keys/entries_keys.dart` for an existing `calendarEntryPill` key. If not present, add:

```dart
static Key calendarEntryPill(String entryId) => Key('calendar_entry_pill_$entryId');
```

#### Step 3.1.4: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

---

## Phase 4: Weather / Header Rework

### Sub-phase 4.1: Always-Visible Entry Header

**Files:**
- Modify: `lib/features/entries/presentation/screens/entry_editor_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.1.1: Remove header collapse behavior

In `_EntryEditorScreenState`, modify `_buildEntryHeader` (lines 926-1182) to make date, attribution, and temperature always visible:

1. **Remove `_headerExpanded` field** (line 92) and all assignments (lines 331, 501, 525).
2. **Remove the `InkWell` + `AnimatedRotation` toggle** (line 942-960) — the chevron and tap-to-collapse.
3. **Remove `AnimatedSize` + `ClipRect` wrapper** (lines 1041-1049) — the collapsible container.
4. **Keep all content that was inside the collapsible section** — date row, attribution, temperature — but render them unconditionally.

```dart
// WHY: Entry header must not collapse and hide core data.
// FROM SPEC: "Weather, location, date, and temperature remain visible at all times"
// FROM SPEC: "Remove auto-collapse for the entry header"

Widget _buildEntryHeader(DailyEntry entry) {
  final cs = Theme.of(context).colorScheme;
  final fg = FieldGuideColors.of(context);
  final dateStr = DateFormat('EEEE, MMMM d, y').format(entry.date);
  final isViewer = !context.read<AuthProvider>().canEditEntry(
      createdByUserId: entry.createdByUserId);

  return Card(
    key: _sectionKeys['basics'],
    child: Padding(
      padding: const EdgeInsets.all(DesignConstants.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name (always visible, no collapse toggle)
          Text(
            '${_projectName ?? ''} — ${_projectNumber ?? ''}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: DesignConstants.space2),
          // Location + Weather row (always visible, existing logic preserved)
          Row(children: [
            // ... existing location chip (InkWell with _showLocationEditDialog) ...
            // ... existing weather chip (InkWell with _showWeatherEditDialog) ...
          ]),
          const SizedBox(height: DesignConstants.space1),
          // Date (ALWAYS visible now — was in collapsible section)
          Row(
            key: TestingKeys.entryDateField,
            children: [
              Icon(Icons.calendar_today, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: DesignConstants.space1),
              AppText.bodyMedium(dateStr, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: DesignConstants.space1),
          // Attribution (ALWAYS visible now)
          if (entry.createdByUserId != null)
            UserAttributionText(
              userId: entry.createdByUserId,
              prefix: 'Recorded by:',
            ),
          const SizedBox(height: DesignConstants.space1),
          // Temperature inline edit (ALWAYS visible now — existing logic preserved)
          // ... existing ListenableBuilder with temp editing ...
        ],
      ),
    ),
  );
}
```

> **IMPORTANT:** The implementer must preserve ALL existing widget logic (location chip, weather chip, temperature editing, attribution). The only removal is the collapse mechanism (`_headerExpanded`, `AnimatedSize`, `ClipRect`, chevron).

#### Step 4.1.2: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

### Sub-phase 4.2: Restore Weather Auto-Fetch

**Files:**
- Modify: `lib/features/entries/presentation/screens/entry_editor_screen.dart`
- Reference: `lib/features/weather/services/weather_service.dart` (WeatherService.fetchWeatherForCurrentLocation)
- Reference: `lib/features/weather/presentation/providers/weather_provider.dart` (WeatherProvider)
- Reference: `lib/features/entries/presentation/widgets/entry_basics_section.dart` (dead code — harvest pattern)

**Agent**: `frontend-flutter-specialist-agent`

#### Step 4.2.1: Add auto-fetch on entry load/create

In `_EntryEditorScreenState`, add weather auto-fetch logic that triggers when an entry is loaded and weather is empty:

```dart
// WHY: Weather can auto-populate in the live entry flow when enabled.
// FROM SPEC: "On entry load/create, if weather is empty and auto-weather is enabled,
// fetch current-location weather"
// FROM SPEC: "Auto-fetch must never block entry editing"
// NOTE: Pattern harvested from dead EntryBasicsSection.onAutoFetchWeather
// SECURITY: Must check ownership before writing weather data to entry

// Add field:
bool _isFetchingWeather = false;

// Add mapping helper:
// WHY: WeatherService returns human-readable condition strings from Open-Meteo API
// ('Clear', 'Partly Cloudy', 'Rain', etc.) but DailyEntry.weather uses
// WeatherCondition enum (sunny, cloudy, rainy, etc.). byName() would fail for
// every condition. This maps API strings to enum values.
WeatherCondition? _mapWeatherCondition(String apiCondition) {
  const mapping = <String, WeatherCondition>{
    'Clear': WeatherCondition.sunny,
    'Partly Cloudy': WeatherCondition.cloudy,
    'Foggy': WeatherCondition.overcast,
    'Overcast': WeatherCondition.overcast,
    'Drizzle': WeatherCondition.rainy,
    'Rain': WeatherCondition.rainy,
    'Snow': WeatherCondition.snow,
    'Thunderstorm': WeatherCondition.rainy,
  };
  final result = mapping[apiCondition];
  if (result == null) {
    Logger.ui('Unknown weather condition from API: $apiCondition');
  }
  return result;
}

// Add method:
Future<void> _autoFetchWeather() async {
  if (_isFetchingWeather) return;

  // SECURITY: Only auto-fetch weather if user owns this entry
  final authProvider = context.read<AuthProvider>();
  if (!authProvider.canEditEntry(createdByUserId: _entry!.createdByUserId)) return;

  // TODO: If a settings toggle for auto-weather exists (e.g., AppConfigProvider),
  // gate on it here. Currently no such toggle is confirmed — always auto-fetch
  // when weather is null and user owns the entry.

  setState(() => _isFetchingWeather = true);

  try {
    final weatherService = context.read<WeatherService>();
    final weatherData = await weatherService.fetchWeatherForCurrentLocation(
      _entry!.date,
    );

    if (!mounted || weatherData == null) return;

    // Update entry with fetched weather data using copyWith + provider pattern
    // NOTE: WeatherData.condition is a human-readable String from Open-Meteo API
    // (e.g., 'Clear', 'Rain', 'Partly Cloudy') — these do NOT match WeatherCondition
    // enum names (sunny, cloudy, rainy, etc.). Must use mapping function.
    // NOTE: tempLow and tempHigh are non-nullable int fields
    final weatherCondition = _mapWeatherCondition(weatherData.condition);

    final updated = _entry!.copyWith(
      weather: weatherCondition,
      tempLow: weatherData.tempLow,
      tempHigh: weatherData.tempHigh,
    );

    final entryProvider = context.read<DailyEntryProvider>();
    await entryProvider.updateEntry(updated);

    if (mounted) {
      setState(() => _entry = updated);
    }
  } catch (e) {
    Logger.ui('Weather auto-fetch failed: $e');
    // FROM SPEC: "Auto-fetch must never block entry editing" — silently fail
  } finally {
    if (mounted) setState(() => _isFetchingWeather = false);
  }
}
```

Call `_autoFetchWeather()` at the end of entry load (after `_loadEntry` completes) when `entry.weather == null`.

```dart
// In _loadEntry, after populating fields:
if (loadedEntry.weather == null) {
  // Non-blocking — fire and forget
  _autoFetchWeather();
}
```

> **IMPORTANT:** The implementer must verify:
> 1. `WeatherService` is available via Provider/DI in entry_editor_screen (check weather_providers.dart and remaining_deps_initializer.dart)
> 2. `WeatherData` has `condition`, `tempLow`, `tempHigh` fields (check weather models) — `condition` is a String that must be converted to `WeatherCondition` enum via `byName()`
> 3. `EntryProvider` is available via Provider/DI for the `updateEntry(updated)` call
> 4. `AuthProvider.canEditEntry(createdByUserId:)` is used for the ownership check before saving

#### Step 4.2.2: Add manual auto-fetch button in header

Add an auto-fetch affordance in the always-visible header near the weather chip:

```dart
// WHY: Users need a way to manually trigger weather fetch
// FROM SPEC: "Users can still manually override weather and temperatures"
// NOTE: Harvested from dead EntryBasicsSection's OutlinedButton.icon pattern

// In _buildEntryHeader, near the weather chip:
if (!isViewer)
  IconButton(
    icon: _isFetchingWeather
        ? const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.refresh, size: 18),
    onPressed: _isFetchingWeather ? null : _autoFetchWeather,
    tooltip: 'Auto-fetch weather',
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
  ),
```

#### Step 4.2.3: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

---

## Phase 5: Quantity Calculator Relocation

### Sub-phase 5.1: Move Calculator to Quantities Section

**Files:**
- Modify: `lib/features/entries/presentation/widgets/entry_quantities_section.dart`
- Modify: `lib/features/entries/presentation/screens/entry_editor_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 5.1.1: Add calculator affordance to EntryQuantitiesSection header

Modify `EntryQuantitiesSection` to accept a calculator callback and show it in the section header:

```dart
// WHY: Quantity calculator should be reachable from the quantities/pay items card
// FROM SPEC: "Add a visible secondary action in the quantities/pay items card header"
// FROM SPEC: "Right side of the quantities card header as 'Calculator' or 'Open Calculator'"

// Add to EntryQuantitiesSection:
class EntryQuantitiesSection extends StatefulWidget {
  final DailyEntry entry;
  final EntryQuantityProvider quantityProvider;
  final BidItemProvider bidItemProvider;
  final VoidCallback? onOpenCalculator;  // NEW

  const EntryQuantitiesSection({
    super.key,
    required this.entry,
    required this.quantityProvider,
    required this.bidItemProvider,
    this.onOpenCalculator,  // NEW
  });
  // ...
}

// In _EntryQuantitiesSectionState.build(), modify the header Row:
Row(
  children: [
    Icon(Icons.inventory_2_outlined, color: cs.primary),
    const SizedBox(width: 8),
    Text(
      'Pay Items Used',
      style: tt.titleSmall!.copyWith(fontWeight: FontWeight.bold),
    ),
    const Spacer(),
    // NEW: Calculator button
    if (widget.onOpenCalculator != null)
      TextButton.icon(
        onPressed: widget.onOpenCalculator,
        icon: const Icon(Icons.calculate_outlined, size: 18),
        label: const Text('Calculator'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
  ],
),
```

#### Step 5.1.2: Wire calculator callback from EntryEditorScreen

In `entry_editor_screen.dart`, where `EntryQuantitiesSection` is constructed, pass the calculator callback:

```dart
// WHY: Calculator result maps back into a chosen pay item correctly
// NOTE: Existing _addCalculatorResultAsQuantity at line 695 handles result → quantity

EntryQuantitiesSection(
  entry: _entry!,
  quantityProvider: _quantityProvider!,
  bidItemProvider: context.read<BidItemProvider>(),
  onOpenCalculator: () async {
    // Navigate to calculator screen, get result
    // NOTE: Use go_router for navigation consistency across the app
    final result = await context.push<QuantityCalculatorResult>(
      '/quantity-calculator/${_entry!.id}',
    );
    if (result != null && mounted) {
      await _addCalculatorResultAsQuantity(result);
    }
  },
),
```

#### Step 5.1.3: Remove calculator from app bar overflow menu

In `entry_editor_screen.dart`, remove the "Quantity Calculator" `PopupMenuItem` from the `PopupMenuButton` items list and remove the corresponding case in the `onSelected` handler. The calculator is now accessible only from the quantities section.

```dart
// WHY: Calculator is now in the quantities section — no longer needed in overflow
// FROM SPEC: "Move the calculator entry point from the app bar overflow into EntryQuantitiesSection"
```

#### Step 5.1.4: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

---

## Phase 6: Entry PDF Preview and Export

### Sub-phase 6.0: Create EntryPdfExportUseCase

**Files:**
- Create: `lib/features/entries/domain/usecases/entry_pdf_export_use_case.dart`
- Reference: `lib/features/entries/domain/usecases/export_entry_use_case.dart` (existing form export pattern)
- Reference: `lib/features/entries/presentation/controllers/pdf_data_builder.dart` (current direct caller)

**Agent**: `frontend-flutter-specialist-agent`

#### Step 6.0.1: Create EntryPdfExportUseCase

```dart
// WHY: Spec section D requires routing main entry export through an export
// coordinator/use case rather than bypassing domain state via direct PdfService calls.
// FROM SPEC: "Route main entry export through an entry-level export coordinator/use case
// rather than bypassing domain state"
// FROM SPEC: "Persist export metadata if the product expects export history or sync visibility"
//
// NOTE: PdfDataBuilder.generate() is a static method requiring BuildContext + 10 provider
// params, making it inherently UI-layer. This use case therefore only handles the metadata
// persistence part (recording exports after save). PDF generation stays with
// PdfDataBuilder.generate() called from the UI, which already exists and works.
// This still satisfies the spec: the coordinator records exports and ensures metadata
// is persisted, while the UI handles PDF generation which requires BuildContext.

import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/entries/data/models/entry_export.dart';
import 'package:construction_inspector/features/entries/data/repositories/entry_export_repository.dart';

class EntryPdfExportUseCase {
  final EntryExportRepositoryImpl _exportRepository;

  EntryPdfExportUseCase({
    required EntryExportRepositoryImpl exportRepository,
  }) : _exportRepository = exportRepository;

  /// Records export metadata after a successful PDF save.
  ///
  /// Call this after PdfService.saveEntryExport returns a non-null path.
  /// Uses EntryExportRepositoryImpl.create(EntryExport) which validates
  /// filename and persists to SQLite.
  Future<void> recordExport({
    required String entryId,
    required String projectId,
    required String exportPath,
    required String filename,
    int? fileSizeBytes,
    String? createdByUserId,
  }) async {
    final export = EntryExport(
      entryId: entryId,
      projectId: projectId,
      filePath: exportPath,
      filename: filename,
      fileSizeBytes: fileSizeBytes,
      createdByUserId: createdByUserId,
    );

    final result = await _exportRepository.create(export);
    if (!result.isSuccess) {
      Logger.pdf('[EntryPdfExportUseCase] Failed to record export: ${result.error}');
    }
  }
}
```

> **IMPLEMENTER NOTE:** `EntryExportRepositoryImpl` and `EntryExport` model already exist. The `create` method accepts a full `EntryExport` object and validates filename (rejects path traversal). No schema changes needed.
>
> **IMPLEMENTER NOTE (DI):** Register `EntryPdfExportUseCase` in `app_providers.dart` (or the appropriate DI location), injecting `EntryExportRepositoryImpl`.
>
> **IMPLEMENTER NOTE (folder export):** When the entry has photo attachments or form attachments, `PdfService` may produce a folder export instead of a single PDF file. The implementer should surface this distinction in the UI — e.g., show "Exported folder" vs "Exported PDF" in the success snackbar so users understand what was produced.

#### Step 6.0.2: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

### Sub-phase 6.1: Create In-App Entry PDF Preview Screen

**Files:**
- Create: `lib/features/entries/presentation/screens/entry_pdf_preview_screen.dart`
- Reference: `lib/features/forms/presentation/screens/form_viewer_screen.dart:599-616` (exemplar)

**Agent**: `frontend-flutter-specialist-agent`

#### Step 6.1.1: Create EntryPdfPreviewScreen

```dart
// WHY: Entry PDFs need a true preview experience that non-technical users can trust
// FROM SPEC: "Users can preview the generated entry PDF inside the app"
// FROM SPEC: "The preview is clear enough for non-technical users to verify"
// NOTE: Follows exact pattern from form_viewer_screen.dart:_PdfPreviewScreen

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/shared/utils/snackbar_helper.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/pdf/services/pdf_service.dart';
import 'package:construction_inspector/features/entries/domain/usecases/entry_pdf_export_use_case.dart';

/// In-app PDF preview with save/share actions branching from the preview.
/// FROM SPEC: "Save/share/export actions should branch from that preview experience"
class EntryPdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final IdrPdfData pdfData;
  final PdfService pdfService;
  final EntryPdfExportUseCase exportUseCase;

  const EntryPdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.pdfData,
    required this.pdfService,
    required this.exportUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(pdfService.generateFilename(pdfData)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save As',
            onPressed: () => _savePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowSharing: false,   // NOTE: suppress PdfPreview's built-in share — we have our own in AppBar
        allowPrinting: false,  // NOTE: suppress PdfPreview's built-in print — we have our own actions
        build: (_) async => pdfBytes,
      ),
    );
  }

  Future<void> _savePdf(BuildContext context) async {
    try {
      final savedPath = await pdfService.saveEntryExport(
        pdfData,
        context: context,
      );
      if (savedPath != null) {
        // Record export metadata via use case for sync visibility / export history
        final filename = pdfService.generateFilename(pdfData);
        await exportUseCase.recordExport(
          entryId: pdfData.entry.id,
          projectId: pdfData.project.id,
          exportPath: savedPath,
          filename: filename,
        );
        if (context.mounted) {
          SnackBarHelper.showSuccess(context, 'Saved to: $savedPath');
        }
      }
    } catch (e) {
      Logger.pdf('[PDF Export] Error saving: $e');
      if (context.mounted) {
        SnackBarHelper.showError(context, 'An error occurred. Please try again.');
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      await pdfService.sharePdf(
        pdfBytes,
        pdfService.generateFilename(pdfData),
      );
    } catch (e) {
      Logger.pdf('[PDF Export] Error sharing: $e');
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Failed to share PDF. Please try again.');
      }
    }
  }
}
```

#### Step 6.1.2: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

### Sub-phase 6.2: Update Export Flow to Preview-First

**Files:**
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_pdf_actions_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/entry_editor_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 6.2.1: Update _showPdfActionsDialog to navigate to preview

Replace `_showPdfActionsDialog` (line 599-611) to navigate to the new preview screen instead of showing the dialog:

```dart
// WHY: Preview is now the primary experience, with save/share branching from it
// FROM SPEC: "Save/share/export actions should branch from that preview experience
// rather than making preview feel secondary"
// NOTE: The dialog is kept as a fallback but preview is the default path

void _showPdfActionsDialog(
  Uint8List pdfBytes,
  IdrPdfData data,
  PdfService pdfService,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EntryPdfPreviewScreen(
        pdfBytes: pdfBytes,
        pdfData: data,
        pdfService: pdfService,
        exportUseCase: context.read<EntryPdfExportUseCase>(),
      ),
    ),
  );
}
```

#### Step 6.2.2: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

---

## Phase 7: Debug PDF Action Removal

### Sub-phase 7.1: Remove Debug IDR from Active UI

**Files:**
- Modify: `lib/features/entries/presentation/screens/entry_editor_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 7.1.1: Remove Debug IDR PDF menu item

In `entry_editor_screen.dart`, remove the `PopupMenuItem(value: 'debug_pdf', ...)` at line ~899-905 and its corresponding handler in the `onSelected` switch/if block.

```dart
// WHY: Debug IDR button should be removed from active UI
// FROM SPEC: "Remove Debug IDR PDF from the active entry UI"
// NOTE: Keep report_debug_pdf_actions_dialog.dart file — it may be needed by developers
// via other non-UI paths. Only remove the PopupMenuItem trigger.
```

Do NOT delete `report_debug_pdf_actions_dialog.dart` — only remove the menu item that triggers it.

#### Step 7.1.2: Verify with flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

---

## Phase 8: Dead Code Cleanup

### Sub-phase 8.1: Remove Dead Code

**Files:**
- Assess: `lib/features/entries/presentation/widgets/entry_basics_section.dart` (0 importers)
- Assess: `lib/features/entries/presentation/screens/report_widgets/report_add_contractor_sheet.dart` (replaced by shared sheet)

**Agent**: `frontend-flutter-specialist-agent`

#### Step 8.1.1: Assess and remove dead imports

After all prior phases are complete:

1. **`entry_basics_section.dart`** — Confirmed 0 importers. The auto-fetch pattern has been harvested into Phase 4. This file can be deleted.

2. **`report_add_contractor_sheet.dart`** — Check if any remaining callers exist after Phase 2. If `showReportAddContractorSheet` is still called anywhere, keep it. If fully replaced by `showContractorSelectionScreen`, delete it.

3. **`add_contractor_dialog.dart`** — Check if `AddContractorDialog.show` is still called anywhere after Phase 2.3. If fully replaced by the inline creation flow, delete it.

4. **Remove unused imports** from all modified files (e.g., `contractor_editor_widget.dart` import from `home_screen.dart` after Phase 3).

```dart
// WHY: Dead code removal — verified 0 importers during tailor analysis
// NOTE: Only delete after verifying no remaining callers via flutter analyze
```

#### Step 8.1.2: Final flutter analyze

Run: `pwsh -Command "flutter analyze"`
Expected: No issues

---

## Phase Summary

| Phase | Concern | Files Created | Files Modified | Agent |
|-------|---------|--------------|----------------|-------|
| 1 | B: Shared contractor selection surface | 1 | 0 | frontend-flutter-specialist-agent |
| 2 | A+B: Card unification + selection wiring | 0 | 3 | frontend-flutter-specialist-agent |
| 3 | H: Calendar simplification | 0 | 1 (+1 testing keys) | frontend-flutter-specialist-agent |
| 4 | C: Weather/header rework | 0 | 1 | frontend-flutter-specialist-agent |
| 5 | F: Calculator relocation | 0 | 2 | frontend-flutter-specialist-agent |
| 6 | D+G: Export use case + PDF preview + export | 2 | 2 | frontend-flutter-specialist-agent |
| 7 | E: Debug removal | 0 | 1 | frontend-flutter-specialist-agent |
| 8 | Cleanup: Dead code | 0 | 0 (up to 3 deletions) | frontend-flutter-specialist-agent |

**Total**: 3 new files, 9 modified files, up to 3 deleted files
**All phases**: `frontend-flutter-specialist-agent` (all changes are presentation layer)
