# Defects: PDF

Active patterns for pdf. Max 5 defects - oldest auto-archives.
Archive: .claude/logs/defects-archive.md

## Active Patterns

### [DATA] 2026-03-09: R2 Plan Gap — First priceContinuation Path Unchecked (Session 527)
**Pattern**: `_isMinorTextContent` fix targets SECOND priceContinuation path (lines 281-298), but "Boy" row hits FIRST path (lines 265-278) because item-column text goes to `itemElements`, not `textPopulated`. First path checks `textPopulated.isEmpty` → true → classifies as priceContinuation before reaching the fix.
**Prevention**: Add `!itemElements.any((e) => e.text.trim().isNotEmpty)` guard to first priceContinuation path (line 267). Both paths must check for item-column text.
**Ref**: @lib/features/pdf/services/extraction/stages/row_classifier_v3.dart:265-278

### [DATA] 2026-03-08: Grid Line Removal Adaptive Threshold — REVERTED, FIX PENDING (Session 528)
**Pattern**: `_adaptiveC = -2.0` with `THRESH_BINARY_INV` included background in mask (77% coverage). Inpainting damaged text.
**Fix**: Was changed to 10.0 in Session 524 (mask 5.3%), but REVERTED by destructive `git checkout -- .` in Session 527. Current code: -2.0. Included in pdfrx parity spec for re-application.
**Ref**: @lib/features/pdf/services/extraction/stages/grid_line_remover.dart:15

### [QUALITY] 2026-03-08: Silent Null bid_amount Pass-Through — 4-Layer Quality Gap
**Pattern**: When OCR fragments a currency value into multiple elements (e.g., "$177.1" + "33.00"), cell extractor joins with space → currency parser rejects → bid_amount=null. Four layers silently pass this through: (1) consistency_checker skips null bid_amount in math validation, (2) no bidAmount=qty×unitPrice inference exists, (3) field confidence gives only 5% penalty (0.95x completeness multiplier), (4) quality gate checksum weight (15%) too low to block autoAccept even with major discrepancy.
**Prevention**: Add bidAmount inference rule in consistency_checker (when qty and unitPrice present). Add quality gate veto layer for major checksum discrepancies. Consider smarter fragment joining in cell_extractor for numeric columns.
**Ref**: @lib/features/pdf/services/extraction/stages/consistency_checker.dart, @lib/features/pdf/services/extraction/stages/quality_validator.dart:59-66

### [DATA] 2026-03-08: _measureContrast Bug — 70% Underreported After 1-Channel Conversion
**Pattern**: After `processed.convert(numChannels: 1)` at line 229, `_measureContrast(processed)` at line 233 calls `img.getLuminance(pixel)` which computes `0.299*r + 0.587*g + 0.114*b`. On a 1-channel image, `g=0` and `b=0`, so it returns `0.299 * r` instead of `r`. The `contrastAfter` metric is systematically underreported by ~70%. Does not affect downstream logic (metric-only), but corrupts diagnostic output.
**Prevention**: Either move `_measureContrast()` before the 1-channel conversion, or use `pixel.r` directly instead of `getLuminance()` (consistent with `_isDarkPixel` in grid_line_detector).
**Ref**: @lib/features/pdf/services/extraction/stages/image_preprocessor_v2.dart:229-233

### [DATA] 2026-03-07: Cross-Platform + Cross-Device Renderer Divergence — CONFIRMED (Session 528)
**Pattern**: `pdfx` delegates to AOSP PdfRenderer which differs between Android versions. Session 528 confirmed: S21+ (Android 15) = 1243 elements/131 items, S25 Ultra (Android 16) = 1238 elements/130 items/$457K gap. Same APK, same PDF, different OS renderer. Also diverges from Windows (Printing.raster/PDFium).
**Prevention**: Replace pdfx with `pdfrx: 2.2.24` (pinned) which bundles PDFium 144.0.7520.0 on ALL platforms. Spec: `.claude/specs/2026-03-09-pdfrx-parity-spec.md`.
**Ref**: @lib/features/pdf/services/extraction/stages/page_renderer_v2.dart:165

### [QUALITY] 2026-03-02: Tesseract x_wconf Unreliable for Dollar Amounts — Root Cause of B1/B2 LOWs
**Pattern**: Tesseract reports 14-52% confidence on perfectly-extracted dollar amounts (e.g., "$860,970.00" at 34% conf, "$4,911.90" at 14%). The 50% OCR weight in `field_confidence_scorer.dart` weighted geometric mean amplifies this into B2 LOW. Also, 5/8 B1 unitPrice correction patterns are comma→period substitution (`european_periods`), not resolution issues.
**Prevention**: Geometry-aware upscaling (2.0→2.71x) confirmed this is NOT a resolution problem. Fixes needed at Tesseract interpretation layer: (1) confidence floor override when format+interpretation both validate, (2) comma-recovery heuristic for european_periods, (3) space-strip for spurious word breaks.
**Ref**: @lib/features/pdf/services/extraction/scoring/field_confidence_scorer.dart:298-306

<!-- Add defects above this line -->
