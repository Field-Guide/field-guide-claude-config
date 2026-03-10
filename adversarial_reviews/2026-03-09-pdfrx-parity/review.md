# Adversarial Review: pdfrx Parity + Grid Line Threshold Restore

**Spec**: `.claude/specs/2026-03-09-pdfrx-parity-spec.md`
**Date**: 2026-03-09
**Reviewers**: code-review-agent (Opus), security-agent (Opus)

## Holes Found

1. **BGRA breaks 5+ downstream consumers** — `img.decodeImage()` and `cv.imdecode()` expect PNG headers. Raw BGRA buffer has none. However, analysis showed only 3 sites actually need BGRA handling (preprocessor input + 2 fallbacks + diagnostics) since preprocessor outputs PNG to all downstream stages.
2. **PdfImage.dispose() timing** — Use-after-free if pixels not copied before dispose. No Dart stack trace on native crash.
3. **Preprocessor fallback paths pass raw bytes through** — Both catch block and `_createFallbackPage` copy imageBytes unchanged. Must encode BGRA→PNG in fallbacks.
4. **Benchmark test requires Springfield PDF define** — Can't run in CI. Documented as local-only manual step.
5. **Isolate memory doubling** — BGRA bytes copied across isolate boundary: 33MB main + 33MB compute = 66MB per page peak.
6. **architecture.md already (incorrectly) says pdfrx** — Phase 6 should verify, not blindly update.
7. **No grayscale channel-order parity test** — BGRA/RGBA swap would produce wrong luminance values.

## Alternative Approaches

### A1: PNG-in-Renderer (REJECTED by user)
Convert BGRA→PNG inside `PageRendererV2`. Zero downstream changes. Cost: ~1.2-2.4s total. Blast radius: 2 files instead of 6+. User chose raw BGRA for performance.

### A2: Keep Printing.raster on Windows (REJECTED)
Only replace pdfx on Android. Doesn't achieve full 3-device parity goal.

## Codebase Pattern Compliance

**Follows**: Stage isolation via typed I/O, sequential page processing, DI pattern
**Deviates**: Format-aware RenderedPage adds conditional logic to previously clean contract. Mitigated by limiting BGRA awareness to preprocessor + diagnostics only.

## Security Implications

- **Supply chain**: pdfrx bundles PDFium from `bblanchon/pdfium-binaries`. Trusted source (Google Chromium). Pinned to exact version.
- **Memory safety**: PdfImage.dispose() lifecycle critical. Copy-before-dispose pattern mandated.
- **ProGuard/R8**: Currently disabled. Defensive keep rules added for future-proofing.
- **No new permissions, auth, RLS, or network changes.**
- **OWASP M2 (Supply Chain)**: Only category impacted. Accepted trade-off.

## Recommendations

### MUST-FIX (addressed in Rev 1)
- MF-1: Copy pixel buffer before PdfImage.dispose() ✅
- MF-2: try/finally for PdfImage disposal ✅
- MF-3: Validate BGRA buffer length assertion ✅

### SHOULD-CONSIDER (addressed in Rev 1)
- SC-1: PNG-in-renderer (rejected by user, BGRA consumer map added instead)
- SC-2: BGRA→grayscale channel-order test ✅
- SC-3: Benchmark test strategy documented ✅
- SC-4: Isolate memory doubling documented ✅
- SC-5: Mask coverage gate 3%-10% ✅
- SC-3 (sec): Pin pdfrx to exact version ✅
- SC-1 (sec): ProGuard keep rules ✅

### NICE-TO-HAVE
- NH-1: Verify PDFium binary hash against known-good builds (backlog)
- NH-2: Memory pressure monitoring during extraction (backlog)
- NH-3: Strip diagnostic callbacks in release builds (backlog)
