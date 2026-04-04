# Pattern: PDF Field Mapping

## How We Do It
PDF generation uses a DTO class (`IdrPdfData`) that aggregates all data needed for the template. The `PdfService` loads the template from assets, iterates known field names, and fills them with formatted data. Field names are hard-coded constants (the template has nonsensical names). A debug PDF method fills every field with its index+name for visual discovery.

## Exemplar: PdfService.generateIdrPdf

**File**: `lib/features/pdf/services/pdf_service.dart:79-139`

Key aspects:
- Loads template: `rootBundle.load('assets/templates/idr_template.pdf')`
- Creates `PdfDocument` from bytes, gets `document.form`
- Calls `_setField(form, fieldName, value)` for each mapping
- Contractor sections filled via `_fillContractorSection(form, index, contractor, data)`
- Field maps are `static const Map<int, Map<String, String?>>` and `static const Map<int, List<String>>`
- Template is NEVER modified — all fixes in the Dart mapping code
- `generateDebugPdf()` fills every `PdfTextBoxField` with `"${i+1}:$shortName"` for field discovery

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `generateIdrPdf` | `pdf_service.dart:79` | `Future<Uint8List> generateIdrPdf(IdrPdfData data)` | Main PDF fill entry point |
| `_setField` | `pdf_service.dart:211` | `void _setField(PdfForm form, String fieldName, String value)` | Safe field setter (logs on missing) |
| `_fillContractorSection` | `pdf_service.dart:167` | `void _fillContractorSection(PdfForm form, int index, Contractor contractor, IdrPdfData data)` | Fill one contractor slot |
| `_weatherToString` | `pdf_service.dart:234` | `String _weatherToString(WeatherCondition? weather)` | Enum to display string |
| `_formatTempRange` | `pdf_service.dart:253` | `String _formatTempRange(int? low, int? high)` | Format temp range |
| `_formatMaterials` | `pdf_service.dart:259` | `String _formatMaterials(IdrPdfData data)` | Format quantities as materials list |
| `_formatAttachments` | `pdf_service.dart:274` | `String _formatAttachments(IdrPdfData data)` | Format photos + forms list |
| `generateDebugPdf` | `pdf_service.dart:637` | `Future<Uint8List> generateDebugPdf()` | Fill all fields with index:name for mapping |
| `generateFilename` | `pdf_service.dart:301` | `String generateFilename(IdrPdfData data)` | Generate export filename |

## Imports
```dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/entries/data/models/models.dart';
import 'package:construction_inspector/features/projects/data/models/models.dart';
import 'package:construction_inspector/features/contractors/data/models/models.dart';
import 'package:construction_inspector/features/quantities/data/models/models.dart';
import 'package:construction_inspector/features/photos/data/models/photo.dart';
import 'package:construction_inspector/features/forms/data/models/models.dart';
```
