# Source Excerpts by Concern

## Concern A: Contractor Card Unification

### Current ContractorEditorWidget (contractor_editor_widget.dart:10-557)
- Fields: contractorId, contractor, counts, equipmentNames, personnelTypes, contractorEquipment, isEditing, setupMode, editingEquipmentIds, editingCounts
- Mode behavior: `isEditing` toggles view/edit; `setupMode` adds personnel type management
- Layout: contractor name top, prime/sub in header row, personnel section, equipment section below divider
- **Problem**: Personnel uses counter steppers, equipment uses chip/toggle — visually inconsistent

### EntryContractorsSection (entry_contractors_section.dart:21-*)
- Wraps list of ContractorEditorWidget instances
- Manages state via EntryContractorsController
- Has its own `_showAddContractorDialog` at line 308 (uses `showReportAddContractorSheet`)

### ProjectSetupScreen contractor usage (project_setup_screen.dart)
- Uses ContractorEditorWidget with `setupMode: true`
- `_showAddContractorDialog` at line 818 calls `AddContractorDialog.show()`
- After creation, seeds default personnel types

## Concern B: Contractor Add/Select Flow

### Three current implementations:

**1. Entry editor** (entry_contractors_section.dart:308)
```dart
// Uses showReportAddContractorSheet — bottom sheet with ListTile rows
Future<void> _showAddContractorDialog(BuildContext context) async {
  final contractor = await showReportAddContractorSheet(context: context, availableContractors: available);
  if (contractor != null) { /* add to entry */ }
}
```

**2. Calendar preview** (home_screen.dart:1582-1665)
```dart
// Inline AppBottomSheet.show with ListTile rows — duplicates logic
void _showAddContractorDialog() {
  AppBottomSheet.show(context, builder: (ctx) => /* ListView.builder with ListTile */);
}
```

**3. Project setup** (project_setup_screen.dart:818-832)
```dart
// Uses AddContractorDialog.show — dialog with name+type creation
Future<void> _showAddContractorDialog() async {
  await AddContractorDialog.show(context, _projectId!);
  // Seeds default personnel types for new contractors
}
```

### AddContractorDialog body (add_contractor_dialog.dart:40-*)
Creates a contractor with name + prime/sub toggle. Uses `ContractorProvider.createContractor()`.

## Concern C: Weather/Header Rework

### Current header collapse behavior (entry_editor_screen.dart)
- `_headerExpanded` bool at line 92, defaults to `true`
- Auto-collapse logic at lines 331, 501, 525: `_headerExpanded = entry.locationId == null || entry.weather == null`
- Collapsible section includes: date, attribution, temperature
- Always visible: project name, location chip, weather chip

### Dead auto-fetch widget (entry_basics_section.dart:11-209)
- Has `onAutoFetchWeather` VoidCallback
- Shows `OutlinedButton.icon` with loading spinner
- Has `isFetchingWeather` bool for state

### WeatherService API
- `fetchWeatherForCurrentLocation(DateTime date)` — gets GPS, fetches weather
- Returns `WeatherData?`
- `WeatherProvider.fetchWeather({lat, lon, date?})` — ChangeNotifier wrapper

### Current weather editing (entry_editor_screen.dart)
- Tappable weather chip opens `_showWeatherEditDialog()` (report_weather_edit_dialog.dart)
- Manual condition selection + temperature fields
- No auto-fetch path exists in the current entry flow

## Concern D: Daily Entry Export Consolidation

### Current export architecture (two paths):

**Path 1: Main IDR PDF** (entry_editor_screen.dart → pdf_data_builder.dart → pdf_service.dart)
```
PopupMenuButton → PdfDataBuilder.generate() → showReportPdfActionsDialog()
                                                  ├── Preview (Printing.layoutPdf — system viewer)
                                                  ├── Save As (pdfService.saveEntryExport)
                                                  └── Share (pdfService.sharePdf)
```
- Bypasses EntryExportProvider entirely
- Permission check happens in PdfDataBuilder.generate() before any work

**Path 2: Form bundle export** (entry_export_provider.dart → export_entry_use_case.dart)
```
EntryExportProvider.exportAllFormsForEntry() → ExportEntryUseCase.call()
  → FormResponseRepository.getResponsesForEntry()
  → ExportFormUseCase.call() per response
  → EntryExportRepository.create() metadata
```
- Only exports attached forms, NOT the main daily entry PDF

### PdfService.previewPdf (pdf_service.dart:474-478)
```dart
await Printing.layoutPdf(onLayout: (format) async => bytes);
```
System print dialog — NOT in-app preview.

### Forms in-app preview exemplar (form_viewer_screen.dart:599-616)
Uses `PdfPreview` widget from printing package in an `AppScaffold`.

## Concern E: Debug PDF Removal

### Debug IDR menu item (entry_editor_screen.dart:899-905)
- `PopupMenuItem(value: 'debug_pdf', child: ListTile(title: Text('Debug IDR PDF')))`
- Behind `kDebugMode` check in the PopupMenuButton
- Triggers `showReportDebugPdfActionsDialog()` with separate debug-specific dialog

## Concern F: Quantity Calculator Relocation

### Current location (entry_editor_screen.dart)
- Calculator in PopupMenuButton overflow menu
- `_addCalculatorResultAsQuantity()` at line 695: prompts bid item picker, creates EntryQuantity

### QuantityCalculatorScreen (quantity_calculator_screen.dart)
```dart
class QuantityCalculatorScreen extends StatefulWidget {
  final String entryId;
  final String? initialType;
  // Returns QuantityCalculatorResult via Navigator.pop
}
```

### EntryQuantitiesSection header (entry_quantities_section.dart)
Current header is a simple `Row(children: [Icon, Text('Pay Items Used')])`. No trailing widget for calculator affordance.

**Target**: Add calculator button as `trailing` in the section header or as a secondary action.

## Concern G: Entry PDF Preview

### Current behavior
Preview in `showReportPdfActionsDialog` calls `pdfService.previewPdf(bytes)` which opens system Printing.layoutPdf — a print dialog, not a viewing experience.

### Exemplar from forms (form_viewer_screen.dart:599-616)
```dart
class _PdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('PDF Preview')),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        build: (_) async => bytes,
      ),
    );
  }
}
```
**Duplicate exists** in mdot_hub_screen.dart:1102 with identical implementation.

## Concern H: Calendar View Simplification

### Methods to remove from home_screen.dart
1. `_buildEditablePreviewSection` (1269-1331) — 4 call sites at lines 1063, 1139, 1169, 1225
2. `_buildContractorsSection` (1334-1496) — builds full contractor editor
3. `_buildContractorEditorRow` (1498-1580) — creates ContractorEditorWidget
4. `_showAddContractorDialog` (1582-1665) — inline contractor selection

### What to keep
- Calendar widget (`_buildCalendar` at 662)
- Entry pills/cards for selected day
- Navigation to full entry editor on pill tap

### Current entry card in calendar (home_screen.dart)
Entry pills are rendered via `_buildCalendarSection` at line 561. The pill tap handler selects the entry and shows the preview. Double-tap or tap-when-selected navigates to the full editor.
