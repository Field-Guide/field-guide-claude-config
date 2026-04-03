# 2026-04-03 Entry UI Continuity Codex Spec

## Goal

Bring the contractor, weather/header, export, quantity, PDF-preview, and calendar entry flows into a more uniform and continuous UI without changing the functional purpose of the contractor card or the core entry workflow.

This spec is based on direct code tracing in the current repo state on 2026-04-03.

## Verification Summary

### 1. Contractor card layout is inconsistent

Status: Verified

Evidence:
- `lib/features/entries/presentation/widgets/entry_contractors_section.dart`
- `lib/features/entries/presentation/widgets/contractor_editor_widget.dart`
- `lib/features/entries/presentation/screens/home_screen.dart`
- `lib/features/projects/presentation/screens/project_setup_screen.dart`

Current behavior:
- The same `ContractorEditorWidget` is reused in entry edit mode, calendar preview mode, and project setup mode.
- View mode and edit mode are visually different enough that continuity is weak.
- Personnel uses compact counter controls in one block, while equipment uses a separate chip/toggle block below a divider.
- Spacing rhythm differs between the contractor card container, the internal sections, and the add-contractor affordance.

Conclusion:
- The complaint about poor spacing and lack of continuity is valid.
- This is primarily a layout and visual-structure problem, not a missing capability problem.

### 2. Contractor selection/add flow is inconsistent with the rest of the app

Status: Verified, split across two surfaces

Evidence:
- Entry editor add flow: `lib/features/entries/presentation/screens/report_widgets/report_add_contractor_sheet.dart`
- Entry editor contractor section: `lib/features/entries/presentation/widgets/entry_contractors_section.dart`
- Calendar preview contractor add flow: `lib/features/entries/presentation/screens/home_screen.dart`
- Project setup add flow: `lib/features/projects/presentation/widgets/add_contractor_dialog.dart`
- Project setup contractors tab: `lib/features/projects/presentation/screens/project_setup_screen.dart`

Current behavior:
- Entry editor uses a bottom sheet with plain `ListTile` rows to pick existing contractors.
- Calendar preview duplicates that flow with an inline bottom sheet built directly in `home_screen.dart`.
- Project setup still uses an `OutlinedButton.icon` plus `AddContractorDialog.show(...)`, which is the popup flow the user is objecting to.

Conclusion:
- There is no single contractor-add pattern.
- The popup concern is definitely valid for project setup.
- The entry and calendar flows also need consolidation so one shared add/select component drives both.

### 3. Weather is not auto-populating

Status: Verified

Evidence:
- Current entry editor header only supports manual weather editing:
  - `lib/features/entries/presentation/screens/entry_editor_screen.dart`
  - `lib/features/entries/presentation/screens/report_widgets/report_weather_edit_dialog.dart`
- Old widget with an auto-fetch button exists but is not used anywhere:
  - `lib/features/entries/presentation/widgets/entry_basics_section.dart`
- Repo-wide usage search shows `EntryBasicsSection` is not mounted by the current entry flow.
- Weather service still exists:
  - `lib/features/weather/services/weather_service.dart`

Current behavior:
- Users can manually set weather condition and manually edit temperature.
- No live entry screen currently invokes weather auto-fetch.

Conclusion:
- This is not just a broken button.
- The current production entry flow does not surface weather auto-fetch at all.

### 4. Weather/header card shrinks and hides data

Status: Verified

Evidence:
- `lib/features/entries/presentation/screens/entry_editor_screen.dart`

Current behavior:
- The header uses `_headerExpanded`.
- Once location and weather are set, the header collapses down to a compact row.
- Date, attribution, and temperature move into the collapsible section and are no longer always visible.

Conclusion:
- The user’s complaint maps directly to the current header implementation.
- This is a layout decision that should be reversed or softened.

### 5. Exporting daily entries fails

Status: Partially verified, runtime repro still needed

Evidence:
- Daily entry PDF export path:
  - `lib/features/entries/presentation/screens/entry_editor_screen.dart`
  - `lib/features/entries/presentation/controllers/pdf_data_builder.dart`
  - `lib/features/entries/presentation/screens/report_widgets/report_pdf_actions_dialog.dart`
  - `lib/features/pdf/services/pdf_service.dart`
- Separate "Export All Forms" path:
  - `lib/features/entries/presentation/providers/entry_export_provider.dart`
  - `lib/features/entries/domain/usecases/export_entry_use_case.dart`
- Attempted test execution was blocked by a Flutter tool crash:
  - `PathExistsException` while copying `sqlite3.x64.windows.dll`

Observed architecture:
- Main daily entry PDF export bypasses `EntryExportProvider` and calls `PdfService` directly.
- The `EntryExportProvider`/`ExportEntryUseCase` stack only exports attached forms, not the main IDR entry PDF.
- The daily entry export path requests storage permission before opening the export flow, which can block preview/share unnecessarily on Android.
- The PDF action dialog offers preview/save/share, but save may export a folder when photos/forms exist rather than a single obvious "daily entry PDF" artifact.

Conclusion:
- There is definitely export-path fragmentation and a likely UX failure source.
- I have not yet reproduced the exact user-facing failure because Flutter test execution is currently blocked by the environment, not by the app code.
- This item should remain high priority, but the first implementation pass should include an explicit runtime repro and logging pass.

### 6. Remove the Debug IDR button

Status: Verified

Evidence:
- `lib/features/entries/presentation/screens/entry_editor_screen.dart`
- `lib/features/entries/presentation/screens/report_widgets/report_debug_pdf_actions_dialog.dart`

Current behavior:
- `PopupMenuButton` includes `Debug IDR PDF` behind `kDebugMode`.

Conclusion:
- The button is already debug-only, but it still exists in development builds.
- Removing it from the active UI is straightforward and low risk.

### 7. Quantity calculator button should be in the quantities/pay items card

Status: Verified

Evidence:
- Current entry screen app bar menu:
  - `lib/features/entries/presentation/screens/entry_editor_screen.dart`
- Quantities card:
  - `lib/features/entries/presentation/widgets/entry_quantities_section.dart`

Current behavior:
- Quantity calculator is only reachable from the app bar overflow menu.
- The quantities card has no direct calculator affordance.

Conclusion:
- The requested move matches the current UX gap.
- This is a good continuity fix because the calculator result writes back into quantities.

Additional implementation note:
- `_addCalculatorResultAsQuantity()` currently uses `widget.projectId` when creating the quantity row.
- In edit mode, `EntryEditorScreen` is documented to receive `projectId: ''`, so this should be corrected to use `_entry!.projectId` when the button move is implemented.

### 8. Missing PDF preview for entries

Status: Partially verified, needs product clarification

Evidence:
- Entry export action dialog already includes Preview:
  - `lib/features/entries/presentation/screens/report_widgets/report_pdf_actions_dialog.dart`
- Preview delegates to system/printing preview:
  - `lib/features/pdf/services/pdf_service.dart`
- Forms already have dedicated in-app preview screens:
  - `lib/features/forms/presentation/screens/form_viewer_screen.dart`
  - `lib/features/forms/presentation/screens/mdot_hub_screen.dart`

Current behavior:
- Entry PDF export has a preview action, but it is not a dedicated in-app preview screen.
- There is no persistent entry-level PDF preview surface equivalent to the forms flow.

Conclusion:
- If the requirement is "there is no preview at all," that is not accurate.
- If the requirement is "entries need the same kind of dedicated preview experience forms have," then the gap is real.

### 9. Calendar view should remove inline editing

Status: Verified

Evidence:
- `lib/features/entries/presentation/screens/home_screen.dart`

Current behavior:
- Calendar day selection shows entry pills/cards for that day.
- Tapping a non-selected entry card selects it and shows preview content below.
- Tapping the selected card navigates to full report/editor.
- The preview itself supports inline editing for weather, activities, safety, visitors, and contractors via `_buildEditablePreviewSection(...)` and the contractor editor controls.

Conclusion:
- The requested change is valid and clearly scoped.
- The current implementation already has the day -> pill -> full editor pattern; the spec should preserve that and remove editing from the preview pane.

## Product Direction

### Primary UX direction

The app should use:
- Read-only preview surfaces in calendar mode
- Direct-edit surfaces in the entry editor
- One consistent contractor card language across setup, entry editing, and calendar preview
- One consistent add/select contractor pattern across entry and project setup flows

### Resolved Design Decisions

- Contractor cards use a vertical layout only. No device-specific side-by-side contractor layout for now.
- Contractor editing remains inline. Do not move contractor editing into a separate screen or separate detail flow.
- Contractor name sits at the top of the card.
- Prime/Sub status moves under the contractor name rather than living on the top row.
- Project setup should create a contractor, then immediately bring that contractor into the contractor card as the setup surface.
- Calendar should be read-only. Clicking a day with entries shows a pill at the bottom of the calendar, and clicking that pill opens the entry editor.
- Entry PDFs need a true preview experience that non-technical users can trust before save/share.

### Non-goals

- Do not change contractor card business logic.
- Do not change what contractor data is captured.
- Do not introduce new contractor states or workflow rules.
- Do not expand calendar editing capability.

## Proposed Changes

### A. Contractor Card Unification

Create a single visual system for contractor cards with mode-specific behavior:
- View mode: clean summary card with fixed internal spacing, consistent header, explicit personnel summary row, explicit equipment summary row, and uniform affordances.
- Edit mode: same card shell and section order as view mode, but with editable controls in place.
- Setup mode: same shell, same section order, management controls for contractor metadata, personnel types, and equipment.

Required continuity rules:
- Header order stays the same in all modes: contractor name, mode actions.
- Contractor type badge/status lives on a secondary row directly under the contractor name.
- Personnel section always appears before equipment section.
- Equipment section always uses the same alignment, label treatment, and selection styling as the rest of the card.
- Add affordances inside the card should look like card actions, not unrelated floating controls.
- Layout remains vertical on all device sizes for now.

Implementation direction:
- Refactor `ContractorEditorWidget` so it has a stable layout skeleton and mode-specific content slots.
- Stop duplicating contractor add/select UI logic between `entry_contractors_section.dart` and `home_screen.dart`.

### B. Contractor Add / Select Flow Redesign

Replace mixed popup/list-tile flows with a shared contractor selection surface and a unified setup flow.

Desired behavior:
- Entry editor: "Add Contractor" opens one shared contractor selection flow.
- Calendar preview: no contractor editing surface remains there after the calendar simplification.
- Project setup: replace the current contractor popup dialog with a create-then-setup flow that lands directly in the contractor card.

Recommended UX shape:
- Shared selection route/surface with:
  - title
  - search/filter if contractor count is high
  - clickable contractor items/cards
  - prime/sub badge
  - optional short secondary text
- Project setup add flow:
  - user taps `Add Contractor`
  - user enters contractor name and type in a lightweight first step
  - app creates the contractor
  - app immediately renders that contractor in the standard contractor card in setup mode
  - user configures personnel types and equipment inline on that card

Implementation constraint:
- Do not use the current popup dialog or the current bottom-sheet list-tile pattern as the long-term shared flow.

### C. Weather/Header Rework

Restore weather auto-population to the live entry workflow.

Required behavior:
- On entry load/create, if weather is empty and auto-weather is enabled, fetch current-location weather.
- Users can still manually override weather and temperatures.
- Auto-fetch must never block entry editing.

Header behavior change:
- Remove auto-collapse for the entry header, or replace it with a compact mode that still leaves date, location, weather, and temperature visible at all times.
- The weather/location/header card must not "shrink away" once values are present.

Recommended layout:
- Always-visible summary rows:
  - Date
  - Location
  - Weather
  - Temperature
  - Recorded by
- Manual edit actions can remain inline or in a compact action row.

### D. Daily Entry Export Consolidation

Unify the export model so the main daily entry export is treated as a first-class export, not as an unrelated direct `PdfService` action.

Required changes:
- Define one canonical daily entry export path.
- Ensure entry PDF export can be previewed, saved, and optionally shared without unnecessary permission gating before preview.
- Persist export metadata if the product expects export history or sync visibility.
- Instrument failures so runtime export issues can be diagnosed.

Recommended implementation direction:
- Route main entry export through an entry-level export coordinator/use case rather than bypassing domain state.
- Split preview generation from save/export permission checks.
- Keep folder export only when attachments require it, but make that behavior obvious in the UI.

### E. Debug PDF Action Removal

Remove `Debug IDR PDF` from the active entry UI.

Implementation note:
- Keep the underlying debug helper only if it is still needed by developers.
- If retained, move it behind a non-user path or a dedicated internal developer action.

### F. Quantity Calculator Relocation

Move the calculator entry point from the app bar overflow into `EntryQuantitiesSection`.

Desired behavior:
- Add a visible secondary action in the quantities/pay items card header.
- Keep the existing calculator result flow of selecting a pay item and writing back to entry quantities.

Recommended placement:
- Right side of the quantities card header as `Calculator` or `Open Calculator`.

### G. Entry PDF Preview Experience

Add a dedicated in-app entry PDF preview experience before save/share.

Required behavior:
- Users can preview the generated entry PDF inside the app.
- The preview is clear enough for non-technical users to verify the form content visually.
- Save/share/export actions should branch from that preview experience rather than making preview feel secondary.

### H. Calendar View Simplification

Make calendar preview read-only.

Required behavior:
- Selecting a day shows an entry pill at the bottom of the calendar when that day has an entry.
- Clicking that pill opens the full entry editor.
- Remove inline editing controls from the calendar page.
- Remove the current report-preview editing pane from the calendar page.

Recommended UI:
- Keep the day selection and entry-presence signal in the calendar.
- Replace the current editable preview area with a simpler day-selected state and entry pill action.

## Acceptance Criteria

### Contractor
- Contractor cards share one spacing system and one section order across setup, entry editor, and calendar preview.
- Personnel and equipment sections no longer feel like different components stitched together.
- Add/select contractor flow uses one shared pattern rather than three separate ones.
- Project setup no longer uses the current contractor popup dialog.
- After creating a contractor in project setup, the user is dropped directly into that contractor’s setup card.
- Contractor name is top-most and Prime/Sub appears underneath it.

### Weather/Header
- Weather can auto-populate in the live entry flow when enabled.
- Users can manually override weather data.
- Entry header does not collapse in a way that hides core data.
- Weather, location, date, and temperature remain visible at all times in the entry editor.

### Export/PDF
- Daily entry export can be generated reliably from the entry editor.
- Preview does not depend on storage permission.
- Export failure paths surface actionable user feedback and emit logs.
- Entry PDF preview behavior is explicitly defined, in-app, and easy for non-technical users to trust.

### Quantities
- Quantity calculator is reachable from the quantities/pay items card.
- Calculator result still maps back into a chosen pay item correctly.

### Calendar
- Calendar page is read-only.
- Clicking a day with an entry shows an entry pill at the bottom of the calendar.
- Clicking that pill opens the full entry editor.
- No inline editing remains on the calendar page.

## Implementation Notes / Dependencies

- A shared contractor selection component should be introduced before touching both `entry_contractors_section.dart` and `home_screen.dart`.
- `project_setup_screen.dart` is already modified in the worktree; any implementation must preserve unrelated user changes there.
- Weather auto-fetch should respect the Settings auto-weather toggle if that setting is still the intended product source of truth.
- Export verification is currently blocked by a local Flutter test-tool crash on Windows native asset copying, so runtime verification should be part of implementation.

## Remaining Open Question

### Contractor selection visual style

One item still needs product direction:

- When the user is selecting an existing contractor to add to an entry, should those selectable items visually resemble:
  - the full contractor cards already used in the entry/setup flow, just in a more compact selectable state
  - or a simpler compact card/pill row that is lighter-weight than the full contractor card

Recommendation:
- Use compact selectable contractor cards that borrow the same typography, spacing, and status treatment as the main contractor card, but are simpler than the full editable card.

## Recommended Order

1. Contractor card shell + shared contractor selection flow
2. Calendar preview simplification
3. Weather/header restoration and always-visible header layout
4. Quantity calculator relocation
5. Entry PDF preview/export consolidation
6. Debug IDR action removal

## Verification Notes

- Code tracing completed across the active entry, contractor, weather, calendar, quantity, and PDF paths.
- `flutter test` verification is currently blocked by a Flutter tool crash on Windows:
  - `PathExistsException` copying `build/native_assets/windows/sqlite3.x64.windows.dll`
- Because of that tooling issue, runtime export failure remains partially verified rather than fully reproduced.
