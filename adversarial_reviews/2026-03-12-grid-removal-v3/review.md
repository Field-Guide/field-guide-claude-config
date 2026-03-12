# Adversarial Review: Grid Removal v3

**Spec**: `.claude/specs/2026-03-12-grid-removal-v3-spec.md`
**Date**: 2026-03-12
**Reviewers**: code-review-agent (Opus), security-agent (Opus)

## Holes Found

1. **Mat memory leak**: Original spec created ~16 Mats per page with no disposal plan (~134 MB peak per page). On 6-page PDF with no disposal = ~756 MB leaked. OOM crash on mobile.
2. **Text protection at intersections**: At H/V intersections, gridMask is a filled rectangle. Text pixels there are classified as grid and removed. Intersection zones are ~15px area.
3. **Security guards dropped**: maxDim=8000, pathological line count >50, defensive re-sort (S11) were not mentioned in the original spec.
4. **HoughLinesP segments unbounded**: No cap on returned segments. Pathological input could return thousands.
5. **GridLine model changes were YAGNI**: No downstream consumer uses pixel coordinates.

## Alternative Approaches Considered

- **Simplify to 5 steps (KISS)**: Merged width-measurement into existing step, reduced from 8 to 6 steps.
- **Use morphological mask directly as removal mask**: Simpler but less precise than HoughLinesP coordinates.
- **Adaptive threshold instead of global 128**: Deferred -- global 128 matches detector, add `foreground_fraction` metric to detect problems.

## Codebase Pattern Compliance

- Memory management follows existing try/finally pattern from grid_line_remover.dart:217-445
- StageReport metrics updated to match new algorithm (morph/hough metrics replace matched-filter metrics)
- Diagnostic image naming follows existing convention (no extension in callback name)
- Contract test naming follows existing pattern in test/features/pdf/extraction/contracts/

## Security Implications

- OWASP M4 (Insufficient Input Validation): maxDim, line count, and segment count guards address this
- Native memory management is the primary security concern (FFI-backed Mats)
- Peak memory ~134 MB at typical resolution, ~1 GB at maxDim=8000. May need maxDim reduction.
- Diagnostic images in production could exhaust storage (36 PNGs per PDF)

## Recommendations

### MUST-FIX (all addressed in updated spec)
1. Complete Mat disposal inventory with try/finally pattern -- **FIXED**
2. Preserve maxDim=8000 guard -- **FIXED**
3. Preserve pathological line count guard -- **FIXED**
4. Cap HoughLinesP segments at 500/axis -- **FIXED**
5. Increase cross-reference tolerance from 10px to 15px -- **FIXED**
6. Define replacement StageReport metrics -- **FIXED**
7. Clarify fallback uses straight lines WITHOUT matched filter -- **FIXED**

### SHOULD-CONSIDER (adopted in updated spec)
1. Drop GridLine model changes (YAGNI) -- **ADOPTED**
2. Simplify algorithm from 8 to 6 steps -- **ADOPTED** (partially)
3. Increase text protection dilation from 3x3 to 5x5 -- **ADOPTED**
4. Add channel count assertion -- **ADOPTED**
5. Preserve defensive re-sort (S11) -- **ADOPTED**
6. Derive kernel size from detector grid boundaries -- **ADOPTED**

### NICE-TO-HAVE (noted for implementation)
1. Add foreground_fraction metric for threshold health check
2. Consider maxDim reduction to 6000 if OOM on mobile
3. Guard diagnostic image emission behind debug flag
4. Add intersection-corner test case to synthetic tests
5. Track hough_fallback_lines count for quality monitoring
