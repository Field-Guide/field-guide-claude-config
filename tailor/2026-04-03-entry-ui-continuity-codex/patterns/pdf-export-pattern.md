# Pattern: PDF Generation and Export

## How We Do It
Entry PDF export uses a two-step pattern: (1) `PdfDataBuilder.generate()` gathers all data from providers and generates PDF bytes, (2) `showReportPdfActionsDialog()` presents Preview/Save/Share options. The main daily entry export bypasses `EntryExportProvider` (which only handles form bundle exports). `PdfService.previewPdf()` delegates to the system print layout viewer via the `printing` package, not an in-app preview.

## Exemplars

### PdfDataBuilder (pdf_data_builder.dart:28-197)
Static `generate()` method that:
1. Checks Android storage permission
2. Loads project, contractors, equipment, personnel types, quantities, forms
3. Assembles `IdrPdfData` record
4. Calls `pdfService.generateIdrPdf(pdfData)`
5. Returns `(bytes: pdfBytes, data: pdfData)` record

### Entry Editor Export Flow (entry_editor_screen.dart)
```dart
// Triggered from PopupMenuButton
_showPdfActionsDialog(pdfBytes, data, pdfService) {
  showReportPdfActionsDialog(
    context: context,
    pdfBytes: pdfBytes,
    pdfData: data,
    pdfService: pdfService,
    permissionService: context.read<PermissionService>(),
  );
}
```

### PdfService.previewPdf (pdf_service.dart:474-478)
```dart
Future<void> previewPdf(Uint8List bytes) async {
  await Printing.layoutPdf(onLayout: (format) async => bytes);
}
```
This is NOT an in-app preview — it opens the system print dialog/viewer.

### Forms In-App Preview (_PdfPreviewScreen in form_viewer_screen.dart:599-616)
```dart
class _PdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  const _PdfPreviewScreen({required this.bytes});
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
**This is the exemplar for the new entry PDF preview screen.**

### EntryExportProvider (entry_export_provider.dart:11-91)
Only exports attached forms via `ExportEntryUseCase.call(entryId)`. Does NOT handle the main daily entry PDF.

## Two Export Paths (fragmentation)

| Path | What it exports | Entry point |
|------|----------------|-------------|
| PdfDataBuilder → showReportPdfActionsDialog | Main daily entry IDR PDF | Entry editor PopupMenuButton |
| EntryExportProvider → ExportEntryUseCase | All attached form responses as individual PDFs | Entry editor "Export All Forms" |

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| PdfDataBuilder.generate | pdf_data_builder.dart:38 | `static Future<PdfGenerationResult?> generate({context, entry, pdfService, ...})` | Generate entry PDF bytes |
| PdfService.previewPdf | pdf_service.dart:474 | `Future<void> previewPdf(Uint8List bytes)` | System print preview (NOT in-app) |
| PdfService.generateIdrPdf | pdf_service.dart:79 | `Future<Uint8List> generateIdrPdf(IdrPdfData data)` | Generate IDR PDF bytes from data |
| PdfService.saveEntryExport | pdf_service.dart | `Future<String?> saveEntryExport(IdrPdfData, {context})` | Save PDF to filesystem |
| PdfService.sharePdf | pdf_service.dart | `Future<void> sharePdf(Uint8List bytes, String filename)` | Share PDF via system share sheet |
| PdfService.generateFilename | pdf_service.dart | `String generateFilename(IdrPdfData data)` | Generate standard filename |

## Imports
```dart
import 'package:construction_inspector/features/entries/presentation/controllers/pdf_data_builder.dart';
import 'package:construction_inspector/features/pdf/services/pdf_service.dart';
import 'package:construction_inspector/services/permission_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
```
