# Source Excerpts by File

## contractor_editor_widget.dart (10-557)

**ContractorEditorWidget** — 547 lines, StatelessWidget. Full source in persisted tool result `toolu_01MRe1BwqB4BMnXCdzu69fL3.json`.

Key fields:
```dart
final String contractorId;
final Contractor? contractor;
final Map<String, int> counts;           // typeId -> count
final List<String> equipmentNames;
final List<PersonnelType> personnelTypes;
final List<Equipment> contractorEquipment;
final bool isEditing;
final Set<String> editingEquipmentIds;
final Map<String, int> editingCounts;
final VoidCallback onTap;
final VoidCallback onDone;
final void Function(String typeId, int count) onCountChanged;
final void Function(String equipmentId, bool selected) onEquipmentChanged;
final Future<void> Function(String name)? onAddPersonnelType;
final Future<void> Function(String typeId)? onDeletePersonnelType;
final Future<void> Function()? onAddEquipment;
final bool setupMode;
final VoidCallback? onEditContractor;
final VoidCallback? onDeleteContractor;
```

## entry_contractors_section.dart (21-*)

**EntryContractorsSection** — StatelessWidget, wraps ContractorEditorWidget list. 0 importers (used inline). Full source in persisted tool result.

Constructor:
```dart
const EntryContractorsSection({
  required this.controller,
  required this.entryId,
  required this.projectId,
  this.createdByUserId,
  required this.contractorProvider,
  required this.equipmentProvider,
  required this.personnelTypeProvider,
  required this.contractorsRepository,
  this.onContractorSaved,
})
```

Key method: `_showAddContractorDialog(BuildContext context)` at line 308.

## entry_editor_screen.dart

### _buildEntryHeader (926-1182)
256-line method. Full source retrieved via get_symbol_source. Key: uses `_headerExpanded`, `AnimatedSize`, `ClipRect`. Always-visible: project name, location chip, weather chip. Collapsible: date, attribution, temperature.

### _addCalculatorResultAsQuantity (695-740)
45-line method. Prompts user to pick bid item via `showBidItemPickerSheet`, creates `EntryQuantity`, saves via `_quantityProvider`.

### _showPdfActionsDialog (599-611)
13-line wrapper. Delegates to `showReportPdfActionsDialog()`.

### Debug IDR menu item (line 899-905)
```dart
PopupMenuItem(
  value: 'debug_pdf',
  child: ListTile(
    leading: Icon(Icons.bug_report),
    title: Text('Debug IDR PDF'),
    contentPadding: EdgeInsets.zero,
  ),
),
```
Behind `kDebugMode` check.

## home_screen.dart

### _buildEditablePreviewSection (1269-1331)
63-line method. GestureDetector + AnimatedContainer. Tap toggles editing. Used 4 times (weather, activities, safety, visitors).

### _buildContractorsSection (1334-1496)
163-line method. Full contractor editor section with personnel summary, ContractorEditorWidget per contractor, add button.

### _buildContractorEditorRow (1498-1580)
83-line method. Creates ContractorEditorWidget with full callbacks for calendar preview editing.

### _showAddContractorDialog (1582-1665)
84-line method. Inline AppBottomSheet with ListTile rows. Duplicates logic from `showReportAddContractorSheet`.

## project_setup_screen.dart

### _showAddContractorDialog (818-832)
15-line method. Calls `AddContractorDialog.show(context, _projectId!)`, then seeds default personnel types for newly created contractors.

## entry_basics_section.dart (11-209) — DEAD CODE

199-line StatelessWidget. Has location dropdown, weather dropdown, temperature fields, and auto-fetch button. 0 importers — not used by any live screen. Contains the `onAutoFetchWeather` callback pattern needed for spec C.

## entry_quantities_section.dart (16-492)

477-line StatefulWidget. Manages inline editing of quantities with per-quantity TextEditingControllers. Uses Card + Row header (not AppSectionCard). The header has icon + title but no calculator affordance.

## report_pdf_actions_dialog.dart (13-93)

81-line top-level function. `AppDialog.show` with Preview/Save As/Share buttons. Preview calls `pdfService.previewPdf(bytes)` (system viewer).

## report_debug_pdf_actions_dialog.dart (12-82)

71-line top-level function. Similar to above but for debug PDFs. Uses hardcoded filename `'DEBUG_IDR_field_map.pdf'`.

## report_add_contractor_sheet.dart (10-*)

Top-level function returning `Future<Contractor?>`. Bottom sheet with ListTile rows showing contractor name + prime/sub badge.

## add_contractor_dialog.dart

Static `AddContractorDialog.show(context, projectId)`. Creates dialog body with name field + prime/sub toggle. Creates contractor via ContractorProvider.

## pdf_data_builder.dart (28-197)

170-line class. Static `generate()` method. Gathers all data from providers (project, contractors, equipment, personnel, quantities, forms, photos) and calls `pdfService.generateIdrPdf()`. Checks Android storage permission first.

## pdf_service.dart

### previewPdf (474-478)
```dart
Future<void> previewPdf(Uint8List bytes) async {
  await Printing.layoutPdf(onLayout: (format) async => bytes);
}
```

### generateIdrPdf (79-*)
Fills company PDF template with IdrPdfData.

## weather_service.dart

### fetchWeatherForCurrentLocation (190-196)
Gets GPS position, delegates to `fetchWeather(lat, lon, date)`.

## form_viewer_screen.dart

### _PdfPreviewScreen (599-616)
In-app preview using `PdfPreview` widget from `printing` package. **Exemplar for new entry PDF preview.**

## entry_export_provider.dart (11-91)

ChangeNotifier wrapping `ExportEntryUseCase`. Only exports attached forms, NOT the main daily entry PDF.

## export_entry_use_case.dart (13-79)

Domain use case. Fetches form responses for entry, exports each via `ExportFormUseCase`, creates `EntryExport` metadata row.
