# Code Review: Grid Line Threshold Fix Plan

**Plan**: `.claude/plans/2026-03-08-grid-line-threshold-fix.md`
**Date**: 2026-03-08
**Reviewer**: code-review-agent
**Verdict**: APPROVE with minor revisions.

## CRITICAL: None

## HIGH (2)

1. **Invalid `-timeout` pwsh argument** — Plan lines 180/220 append `-timeout 600000` after `pwsh -Command "..."`. PowerShell doesn't accept `-timeout`. Use Bash tool `timeout:` parameter instead.
2. **Add lower-bound coverage assertion** — New test should also assert `greaterThan(0.005)` to guard against the opposite failure (grid lines not detected at all).

## MEDIUM (2)

3. **Phase 5 tuning direction reversed** — "C=2.0 too aggressive" is misleading. Larger C = more aggressive. Reword guidance.
4. **Single-document validation** — All verification against Springfield only. Acceptable for this fix, but note as limitation.

## LOW (2)

5. New test duplicates setup from existing test — consider merging assertions.
6. Minor comment inaccuracy about double negation.

## NICE-TO-HAVE (4)

7-10: Named constant for 0.15, baseline drift note, diagnostic dump, Gaussian alternative.

## Devil's Advocate: All clear
- C=+2.0 cannot miss grid lines (intensity gap ~200 levels)
- Morphological kernels are the real discriminator, not C value
- Inpainting on ~2% is strictly better than on ~77%
