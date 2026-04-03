# Ground Truth

## Route Paths

| Literal | Source File | Line | Status |
|---------|-----------|------|--------|
| `name: 'home'` | `lib/core/router/app_router.dart` | 132 | VERIFIED |
| `path: '/entry/:projectId/:date'` | `lib/core/router/routes/entry_routes.dart` | 11 | VERIFIED |
| `path: '/report/:entryId'` | `lib/core/router/routes/entry_routes.dart` | 27 | VERIFIED |
| `ProjectSetupScreen` (no args) | `lib/core/router/routes/project_routes.dart` | 14 | VERIFIED |
| `ProjectSetupScreen` (with args) | `lib/core/router/routes/project_routes.dart` | 23 | VERIFIED |

## Widget Keys

| Key | Source File | Line | Status |
|-----|-----------|------|--------|
| `TestingKeys.reportQuantitiesSection` | `entry_quantities_section.dart` | build() | VERIFIED |
| `TestingKeys.entryBasicsSection` | `entry_basics_section.dart` | build() | VERIFIED |
| `TestingKeys.reportHeaderLocationButton` | `entry_editor_screen.dart` | 976 | VERIFIED |
| `TestingKeys.reportHeaderWeatherButton` | `entry_editor_screen.dart` | 1004 | VERIFIED |
| `TestingKeys.entryDateField` | `entry_editor_screen.dart` | 1050 | VERIFIED |
| `TestingKeys.reportTemperatureSection` | `entry_editor_screen.dart` | ~1100 | VERIFIED |
| `TestingKeys.reportPdfPreviewDialog` | `report_pdf_actions_dialog.dart` | ~20 | VERIFIED |
| `TestingKeys.reportDebugPdfDialog` | `report_debug_pdf_actions_dialog.dart` | ~20 | VERIFIED |
| `TestingKeys.reportPdfPreviewButton` | `report_pdf_actions_dialog.dart` | ~40 | VERIFIED |
| `TestingKeys.reportPdfSaveAsButton` | `report_pdf_actions_dialog.dart` | ~50 | VERIFIED |
| `TestingKeys.reportPdfShareButton` | `report_pdf_actions_dialog.dart` | ~80 | VERIFIED |
| `TestingKeys.calendarReportContractorsSection` | `home_screen.dart` | 1380 | VERIFIED |
| `TestingKeys.calendarReportAddContractorButton` | `home_screen.dart` | 1424/1484 | VERIFIED |
| `TestingKeys.reportAddQuantityButton` | `entry_quantities_section.dart` | build() | VERIFIED |
| `TestingKeys.weatherFetchButton` | `entry_basics_section.dart` | build() | VERIFIED |
| `EntriesTestingKeys.contractorWidget(id)` | `entries_keys.dart` | 438 | VERIFIED |
| `EntriesTestingKeys.reportContractorCard(id)` | `entries_keys.dart` | 274 | VERIFIED |
| `ContractorsTestingKeys.contractorCard(id)` | `contractors_keys.dart` | 28 | VERIFIED |
| `TestingKeys.entryEditButton(section)` | `testing_keys.dart` | uses EntrySection enum | VERIFIED |

## DB Column Names (not directly changed by this spec)

No schema changes proposed.

## Model Field Names

| Field | Model | File | Status |
|-------|-------|------|--------|
| `contractorId` | ContractorEditorWidget | contractor_editor_widget.dart:12 | VERIFIED |
| `contractor` (Contractor?) | ContractorEditorWidget | contractor_editor_widget.dart:13 | VERIFIED |
| `counts` (Map<String,int>) | ContractorEditorWidget | contractor_editor_widget.dart:14 | VERIFIED |
| `isEditing` | ContractorEditorWidget | contractor_editor_widget.dart:18 | VERIFIED |
| `setupMode` | ContractorEditorWidget | contractor_editor_widget.dart:41 | VERIFIED |
| `isPrime` | Contractor model | used in contractor sorting | VERIFIED |
| `isSub` | Contractor model | used in PDF data builder | VERIFIED |
| `_headerExpanded` | _EntryEditorScreenState | entry_editor_screen.dart:92 | VERIFIED |
| `entryId` | QuantityCalculatorScreen | quantity_calculator_screen.dart:37 | VERIFIED |
| `WeatherCondition` (enum) | daily_entry.dart | line 3 | VERIFIED |
| `EntrySection` (enum) | entries_keys.dart | line 4 | VERIFIED |

## Provider/Service APIs

| Method | Class | File:Line | Status |
|--------|-------|-----------|--------|
| `fetchWeather(lat, lon, date)` | WeatherService | weather_service.dart:111 | VERIFIED |
| `fetchWeatherForCurrentLocation(date)` | WeatherService | weather_service.dart:190 | VERIFIED |
| `fetchWeather({lat, lon, date?})` | WeatherProvider | weather_provider.dart:23 | VERIFIED |
| `previewPdf(bytes)` | PdfService | pdf_service.dart:474 | VERIFIED |
| `generateIdrPdf(data)` | PdfService | pdf_service.dart:79 | VERIFIED |
| `generate({...})` | PdfDataBuilder | pdf_data_builder.dart:38 | VERIFIED |
| `exportAllFormsForEntry(entryId)` | EntryExportProvider | entry_export_provider.dart:33 | VERIFIED |
| `call(entryId)` | ExportEntryUseCase | export_entry_use_case.dart:30 | VERIFIED |
| `showReportPdfActionsDialog({...})` | (top-level) | report_pdf_actions_dialog.dart:13 | VERIFIED |
| `showReportDebugPdfActionsDialog({...})` | (top-level) | report_debug_pdf_actions_dialog.dart:12 | VERIFIED |
| `showReportAddContractorSheet({...})` | (top-level) | report_add_contractor_sheet.dart:10 | VERIFIED |
| `AddContractorDialog.show(context, projectId)` | AddContractorDialog | add_contractor_dialog.dart | VERIFIED |

## File Paths

| Path | Exists | Status |
|------|--------|--------|
| `lib/features/entries/presentation/widgets/contractor_editor_widget.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/widgets/entry_contractors_section.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/screens/home_screen.dart` | Yes | VERIFIED |
| `lib/features/projects/presentation/screens/project_setup_screen.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/screens/entry_editor_screen.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/widgets/entry_basics_section.dart` | Yes | VERIFIED |
| `lib/features/weather/services/weather_service.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/controllers/pdf_data_builder.dart` | Yes | VERIFIED |
| `lib/features/pdf/services/pdf_service.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/widgets/entry_quantities_section.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/screens/report_widgets/report_pdf_actions_dialog.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/screens/report_widgets/report_debug_pdf_actions_dialog.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/screens/report_widgets/report_add_contractor_sheet.dart` | Yes | VERIFIED |
| `lib/features/projects/presentation/widgets/add_contractor_dialog.dart` | Yes | VERIFIED |
| `lib/features/entries/presentation/providers/entry_export_provider.dart` | Yes | VERIFIED |
| `lib/features/entries/domain/usecases/export_entry_use_case.dart` | Yes | VERIFIED |
| `lib/core/design_system/app_section_card.dart` | Yes | VERIFIED |
| `lib/features/quantities/presentation/screens/quantity_calculator_screen.dart` | Yes | VERIFIED |
| `lib/features/forms/presentation/screens/form_viewer_screen.dart` | Yes | VERIFIED |

## Flagged Discrepancies

| Item | Expected | Actual | Impact |
|------|----------|--------|--------|
| `_addCalculatorResultAsQuantity` uses `widget.projectId` | Spec says projectId may be `''` in edit mode | Source at line 723 uses `widget.projectId` in `EntryQuantity(projectId: ...)` — BUT checked source shows it does NOT use `widget.projectId` for the quantity. It uses `_entry!.id` for entryId, and the `EntryQuantity` constructor doesn't take projectId | FLAGGED — spec note about projectId bug appears outdated; verify at runtime |

## Lint Rules for New Files

| Proposed File | Path Pattern Match | Active Rules |
|---------------|-------------------|--------------|
| `lib/features/contractors/presentation/widgets/contractor_selection_sheet.dart` | `*/presentation/*` | A3, A5, A8, A13, A18, A19, A20, A22, A23, D5 |
| `lib/features/entries/presentation/screens/entry_pdf_preview_screen.dart` | `*/presentation/screens/*` | A3, A5, A8, A13, A18, A19, A20, A21, A22, A23, D5 |
