# PDF Generation — Procedure Guide

> Loaded on-demand by workers. For constraints and invariants, see `.claude/rules/pdf/pdf-generation.md`

## Key Files
```
lib/features/pdf/
├── data/
│   ├── models/          # PDF-related models
│   └── datasources/     # Local data sources
├── services/            # PDF generation + extraction services
│   ├── extraction/      # V2 pipeline (~81 Dart files)
│   │   ├── models/      # Extraction data models
│   │   ├── ocr/         # OCR engine (TesseractEngineV2)
│   │   ├── pipeline/    # Pipeline orchestration
│   │   ├── rules/       # Extraction rules
│   │   ├── runner/      # ExtractionJobRunner (entry point)
│   │   ├── shared/      # QualityThresholds, shared utilities
│   │   └── stages/      # Pipeline stage implementations
│   ├── mp/              # MP extraction (MpExtractionService)
│   └── ocr/             # OCR engine helpers
└── presentation/
    ├── screens/         # Preview screens
    └── widgets/         # PDF-related widgets
```

## PDF Template Field Mapping

### Field Naming Conventions
**DO:** `project_name`, `contractor_1_name`, `foreman_count_1`
**DON'T:** `Text10`, `ggggsssssssssss`, `Name_3234234`

### Syncfusion PDF Pattern
```dart
final bytes = await rootBundle.load('assets/templates/form.pdf');
final document = PdfDocument(inputBytes: bytes.buffer.asUint8List());
final form = document.form;
final field = form.fields[fieldName] as PdfTextBoxField;
field.text = value;
final outputBytes = await document.save();
document.dispose();
```

### Field Mapping Best Practices
```dart
class FormFieldMappings {
  static const Map<String, String> dailyReport = {
    'project_name': 'projectName',
    'date': 'date',
    'weather': 'weatherConditions',
    'contractor_1_name': 'primeContractor',
  };
}
```

## PDF Parsing (Bid Items)

### ParsedBidItem Model
```dart
class ParsedBidItem {
  final String itemNumber;
  final String description;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double confidence;  // 0.0 - 1.0
  final List<String> warnings;
}
```

### Confidence Handling
```dart
if (confidence < 0.6) return UserValidationRequired(value, confidence);
else if (confidence < 0.8) return ExtractedWithWarning(value, confidence);
else return ExtractedValue(value);
```

## PDF Extraction Pipeline (V2 — Current)

### Stage Overview

| Stage | Class | Purpose |
|-------|-------|---------|
| 0 | `DocumentQualityProfiler` | Detect scan vs native PDF, char count |
| 2B-i | `PageRendererV2` | Rasterize pages to PNG (adaptive DPI: ≤10 pages→300, 11-25→250, >25→200) |
| 2B-ii | `ImagePreprocessorV2` | Grayscale + adaptive contrast (no binarization) |
| 2B-ii.5 | `GridLineDetector` | Detect table grid lines (normalized positions) |
| 2B-ii.6 | `GridLineRemover` | Remove grid lines via OpenCV inpainting (grid pages only) |
| 2B-iii | `TextRecognizerV2` | Cell-level OCR (grid pages) or full-page PSM 4 (non-grid) |
| 3 | `ElementValidator` | Coordinate normalization + element filtering |
| 4A | `RowClassifierV3` | Row classification (provisional then final) |
| 4B | `RegionDetectorV2` | Table region detection (two-pass) |
| 4C | `ColumnDetectorV2` | Column boundary detection |
| 4D | `CellExtractorV2` | Extract text per grid cell |
| 4D.5 | `NumericInterpreter` | Parse numeric/currency values |
| 4E | `RowParserV3` | Map cells to ParsedBidItem fields |
| 4E.5 | `FieldConfidenceScorer` | Per-field confidence (weighted geometric mean) |
| 5 | `PostProcessorV2` | Normalization, deduplication, math backsolve |
| 6 | `QualityValidator` | Overall quality check; triggers re-extraction if below threshold |

### Key Extraction Classes

**ExtractionJobRunner** (`lib/features/pdf/services/extraction/runner/extraction_job_runner.dart`)
- Main orchestrator for the extraction pipeline (~17KB)
- Entry point for PDF form extraction

**QualityThresholds** (`lib/features/pdf/services/extraction/shared/quality_thresholds.dart`)
- Central class for extraction quality scoring constants
- 5th most imported file in the codebase (89 importers via its models barrel)

### MP Document Extraction
`MpExtractionService` reuses stages 0, 2B-i, 2B-ii, and 2B-iii but applies MP-specific page header detection and maps to `MpLineItem` models.

### Image Preprocessing (Stage 2B-ii)
Steps: Decode PNG → Measure contrast → Grayscale → Adaptive contrast → Convert to 1-channel → Encode PNG.
**REMOVED**: Binarization. **NOT IMPLEMENTED**: Deskewing (hardcoded to 0.0).

### Grid Line Removal (Stage 2B-ii.6)
Only runs on grid-flagged pages. Steps: Grayscale Mat → Adaptive threshold → Morphological open (H+V) → Combine + dilate → Inpaint (TELEA, radius=2.0).

### OCR Engine + Cell PSM Selection (Stage 2B-iii)
- **Grid pages**: cell-level cropping. PSM per cell: header → PSM 6, tall rows → PSM 6, data → PSM 7. CropUpscaler targets 600 DPI.
- **Non-grid pages**: full page with PSM 4.
- Re-OCR fallback: numeric columns with all elements < 0.50 confidence and no digits → PSM 8 + numeric whitelist.

### Confidence Scoring (Stage 4E.5)
Weighted geometric mean: OCR confidence (50%), Format validation (30%), Interpretation confidence (20%).
Zero-conf sentinel: `x_wconf == 0.0` but non-empty text → 0.50 neutral prior.

### Math Backsolve (Stage 5)
When `qty × unitPrice ≠ bidAmount`: derives `unitPrice = bidAmount / qty` (round-trips within $0.02). Penalty: -0.03.

## Common Issues

### Field Not Found
```dart
// GOOD - handle missing fields gracefully
final fieldIndex = form.fields.indexOf(form.fields
    .cast<PdfField?>()
    .firstWhere((f) => f?.name == fieldName, orElse: () => null));
if (fieldIndex == -1) {
  Logger.pdf('[PDF] Field not found: $fieldName');
  return;
}
```

### Page Breaks
- Don't split related content across pages
- Use conditional page breaks before large sections
- Test with maximum data to verify layout

## Debugging
```dart
for (var i = 0; i < form.fields.count; i++) {
  final field = form.fields[i];
  Logger.pdf('Field $i: ${field.name} (${field.runtimeType})');
}
```

## Testing
```dart
test('fills project name field', () async {
  final bytes = await File('test/fixtures/template.pdf').readAsBytes();
  final result = await pdfService.fillTemplate(bytes, {'project_name': 'Test'});
  final doc = PdfDocument(inputBytes: result);
  final field = doc.form.fields['project_name'] as PdfTextBoxField;
  expect(field.text, 'Test');
  doc.dispose();
});
```

## Verification Tooling
- `tools/verify_idr_mapping.py` — Python script for IDR template field verification
- `test/golden/pdf/` — Golden tests for PDF rendering

## Quality Checklist
- [ ] All fields map to correct visual positions
- [ ] No `[PDF] Field not found` errors in console
- [ ] Data appears in expected format
- [ ] Page breaks don't split content awkwardly
- [ ] Maximum content tested (no overflow)
- [ ] Scorecard regenerated (if extraction pipeline changed)

## PR Template
```markdown
## PDF Changes
- [ ] Template affected: [template name]
- [ ] Fields modified: [list]
- [ ] Pipeline stage(s) modified: [e.g., Stage 4E RowParserV3]

## Testing
- [ ] Preview verified with sample data
- [ ] Maximum content tested (no overflow)
- [ ] Field mapping validated
- [ ] Scorecard regenerated (if extraction pipeline changed)
```
