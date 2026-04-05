---
paths:
  - "lib/features/pdf/**/*.dart"
  - "assets/templates/**/*.pdf"
---

# PDF Generation & Extraction

PDF template filling (Syncfusion) and bid-item extraction (OCR pipeline).

## Hard Constraints

- **OCR-ONLY pipeline** — native text extraction is OFF (CMap corruption). Do NOT suggest native/hybrid.
- **flusseract** (Tesseract 5) — embedded FFI plugin at `packages/flusseract/`. Drives Android minSdk 31.
- **Binarization deliberately removed** — destroyed 92% of image data on clean PDFs.
- Templates: `assets/templates/*.pdf`. Field mappings: `lib/features/pdf/services/pdf_service.dart`.
- `ExtractionJobRunner` is the pipeline entry point (~17KB orchestrator).
- `QualityThresholds` is the 5th most imported file (89 importers via models barrel).
- `opencv_dart` v2.2.1+3 for grid line removal (inpainting on grid pages only).
- Low-confidence threshold: **0.80**. Items below counted in `items_below_0_80`.
- Math backsolve: derives `unitPrice = bidAmount / qty` when round-trips within $0.02. Penalty: -0.03.
- **Always run pipeline report test after any extraction stage code changes.**
- Re-extraction loop: up to 2 retries at 400 DPI (PSM 3 then PSM 6). Best result by `overallScore` kept.

> For pipeline stages, code patterns, and debugging, see `.claude/skills/implement/reference/pdf-generation-guide.md`
