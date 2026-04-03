# Blast Radius

## Per-Symbol Impact

### ContractorEditorWidget
- **Risk score**: 1.0 (low — only 2 consumers)
- **Direct dependents**: 2
- **Confirmed consumers**:
  - `entry_contractors_section.dart` (2 references)
  - `project_setup_screen.dart` (1 reference)
- **Test files**: None directly (tested via parent screens)

### EntryContractorsSection
- **Risk score**: 0.0
- **Direct dependents**: 0 via import graph
- **Note**: Used inline in `entry_editor_screen.dart` (same directory, not tracked by import graph because it's in the same presentation/widgets folder and referenced via barrel or direct construction in the screen's build method)

### EntryEditorScreen
- **Risk score**: 0.0 (routed, not imported)
- **Direct dependents**: 0 via import graph
- **Routed from**: `entry_routes.dart` → `/entry/:projectId/:date` and `/report/:entryId`

### HomeScreen
- **Risk score**: 0.0 (routed, not imported)
- **Direct dependents**: 0 via import graph
- **Routed from**: `app_router.dart` → name `'home'`, line 132

### WeatherService
- **Risk score**: Medium (7 importers)
- **Direct dependents**: 7
- **Key consumers**: DI bootstrap, weather_providers.dart, WeatherProvider, dashboard weather card

### showReportPdfActionsDialog
- **Direct dependents**: 0 (called inline in entry_editor_screen.dart)
- **Note**: Called via `_showPdfActionsDialog` wrapper at line 599

### showReportDebugPdfActionsDialog
- **Direct dependents**: 0 (called inline in entry_editor_screen.dart behind kDebugMode)

### EntryExportProvider
- **Direct dependents**: 3
- **Consumers**: entries_providers.dart (DI), entry_editor_screen.dart, test

## Summary Counts

| Category | Count |
|----------|-------|
| Files directly modified | 9 |
| Files with new code | 2 |
| Symbols with dependents | 3 (ContractorEditorWidget, WeatherService, EntryExportProvider) |
| Routed screens (no import dependents) | 3 (EntryEditorScreen, HomeScreen, ProjectSetupScreen) |

## Dead Code Targets

| File/Symbol | Confidence | Action |
|-------------|------------|--------|
| `entry_basics_section.dart` (EntryBasicsSection) | 1.0 | 0 importers — has `onAutoFetchWeather` callback. **Harvest auto-fetch UI pattern before removing.** |
| `report_debug_pdf_actions_dialog.dart` | Will become dead after spec E removal | Remove from active UI, optionally keep file for dev tooling |
| `_buildEditablePreviewSection` in home_screen.dart | N/A — spec H removes all callers | Remove method + 4 call sites (lines 1063, 1139, 1169, 1225) |
| `_buildContractorsSection` in home_screen.dart | N/A — spec H removes it | Remove method (lines 1334-1496) |
| `_showAddContractorDialog` in home_screen.dart | N/A — spec H removes it | Remove method (lines 1582-1665) |
| `_buildContractorEditorRow` in home_screen.dart | N/A — spec H removes it | Remove method (lines 1498-1580) |
