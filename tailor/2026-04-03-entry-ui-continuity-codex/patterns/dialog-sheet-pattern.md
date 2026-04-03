# Pattern: Dialog / Bottom Sheet Functions

## How We Do It
Dialogs and bottom sheets are exposed as top-level `Future<T?> showXxx({required BuildContext context, ...})` functions. They use `AppDialog.show()` or `AppBottomSheet.show()` from the design system. Each function encapsulates its own UI and returns a result. This pattern is enforced by lint rules A19 (no raw showDialog) and A20 (no raw showModalBottomSheet).

## Exemplars

### showReportPdfActionsDialog (report_pdf_actions_dialog.dart:13-93)
```dart
Future<void> showReportPdfActionsDialog({
  required BuildContext context,
  required Uint8List pdfBytes,
  required IdrPdfData pdfData,
  required PdfService pdfService,
  required PermissionService permissionService,
}) async {
  await AppDialog.show<void>(
    context,
    title: 'PDF Generated',
    dialogKey: TestingKeys.reportPdfPreviewDialog,
    content: Column(...),
    actionsBuilder: (ctx) => [
      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
      TextButton.icon(onPressed: () async { Navigator.pop(ctx); await pdfService.previewPdf(pdfBytes); }, ...),
      // Save As, Share buttons...
    ],
  );
}
```

### showReportAddContractorSheet (report_add_contractor_sheet.dart:10)
```dart
Future<Contractor?> showReportAddContractorSheet({
  required BuildContext context,
  required List<Contractor> availableContractors,
})
```
Returns the selected Contractor or null.

### AddContractorDialog.show (add_contractor_dialog.dart)
```dart
class AddContractorDialog {
  AddContractorDialog._();
  static Future<void> show(BuildContext context, String projectId) async {
    await AppDialog.show<void>(context, title: '...', content: _AddContractorDialogBody(...));
  }
}
```

## Three Current Add-Contractor Patterns (to be unified)

| Surface | Pattern | Code Location |
|---------|---------|---------------|
| Entry editor | `showReportAddContractorSheet` (bottom sheet, ListTile rows) | report_add_contractor_sheet.dart |
| Calendar preview | Inline `AppBottomSheet.show` with ListTile rows | home_screen.dart:1582-1665 |
| Project setup | `AddContractorDialog.show` (dialog with name+type fields) | add_contractor_dialog.dart |

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| AppDialog.show | design_system.dart (barrel) | `static Future<T?> show<T>(BuildContext, {title, content, actionsBuilder, dialogKey})` | Any dialog |
| AppBottomSheet.show | design_system.dart (barrel) | `static void show(BuildContext, {builder})` | Any bottom sheet |
| showReportAddContractorSheet | report_add_contractor_sheet.dart:10 | `Future<Contractor?> showReportAddContractorSheet({context, availableContractors})` | Entry editor contractor selection |

## Imports
```dart
import 'package:construction_inspector/core/design_system/design_system.dart';
```
