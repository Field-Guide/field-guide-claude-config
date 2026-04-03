# Code Review — Cycle 2

**Verdict: REJECT**

## Cycle 1 Fixes: All verified correct except m2 (import paths)

## New Critical Issues

**NEW-C1.** Phase 4.2.1: `context.read<EntryProvider>()` — class doesn't exist. Actual: `DailyEntryProvider`.

**NEW-C2.** Phase 6.1.1: Wrong import paths. `core/utils/snack_bar_helper.dart` → `shared/utils/snackbar_helper.dart`. `core/utils/logger.dart` → `core/logging/logger.dart`.

**NEW-C3.** Phase 6.0.1: EntryPdfExportUseCase has 5 API mismatches:
1. PdfDataBuilder.generate() is static, not instance. Requires BuildContext + 10 provider params.
2. No `generate(entryId:)` method exists.
3. `generatePdf(pdfData)` → actual: `generateIdrPdf(data)`.
4. `recordExport(entryId:, exportPath:, exportedAt:)` → actual: `create(EntryExport)` with full 13-field object.
5. `pdfData.entryId` → actual: `pdfData.entry.id`.

## New Major Issues

**NEW-M1.** Phase 4.2.1: WeatherData condition values (`'Clear'`, `'Rain'`, etc.) don't match WeatherCondition enum names (`sunny`, `rainy`). `byName()` silently fails in try-catch. Need mapping function.

**NEW-M2.** Phase 2.3: AppDialog.show without `actionsBuilder:` renders default OK button alongside form's own buttons. Fix: Pass `actionsBuilder: (_) => []`.
