# Defects: PDF

Active patterns for pdf. Max 5 defects - oldest auto-archives.
Archive: .claude/logs/defects-archive.md

## Active Patterns

### [DATA] 2026-03-09: BLOCKER-35 — Cross-Device Checksum Divergence $500K (Session 530)
**Pattern**: After pdfrx migration, both Windows and S25 Ultra extract 130 items (item count parity achieved), but computed checksums diverge by $500K: Windows=$7,602,768.73, S25=$8,102,768.73. OCR element counts also differ slightly (1249 vs 1246). Specific differences: item 94 normalized as "Boy" (Windows) vs "Bey" (S25), item 108 qty changed on Windows but not S25.
**Root Cause**: Unknown. pdfrx uses same bundled PDFium on both platforms — pixel output should be identical. Hypotheses: (1) Tesseract OCR non-determinism across platforms, (2) preprocessing timing differences causing different image quality, (3) subtle pixel differences despite same PDFium (different CPU architecture, float precision). Need pixel-by-pixel comparison of rendered images + element-by-element OCR diff.
**Prevention**: Compare rendered page images byte-for-byte between devices. If pixels differ, root cause is in PDFium/platform. If pixels match, root cause is in Tesseract/preprocessing.
**Ref**: `test/features/pdf/extraction/device-baselines/post-migration/COMPARISON-REPORT.md`

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

<!-- Add defects above this line -->
