# Security Review: Springfield 100% Accuracy Implementation Plan

**Date**: 2026-03-09
**Reviewer**: security-agent (Opus)
**Scope**: Plan at `.claude/plans/2026-03-09-100pct-accuracy-plan.md`
**Files Reviewed**: 14 source files, 1 plan, 1 spec

## Executive Summary

1 HIGH, 3 MEDIUM, 3 LOW. No CRITICAL vulnerabilities. All regex patterns are ReDoS-safe. Numeric backsolve is sound. Position-based mask replacement is memory-safe (70% fewer Mat allocations than current approach).

## HIGH

### H1: R3 Validation Gate Will Crash at Runtime (StateError)

**Location**: Plan Sub-phase 3.1, targeting `row_parser_v3.dart:196-198`

The plan instructs replacing the warning with `continue` + `excludedCount++`. Two problems:
1. `excludedCount` does not exist as a local variable in `RowParserV3.parse()`
2. The `continue` skips both `items.add()` and `skippedRows.add()`, violating the stage report invariant `outputCount + excludedCount == inputCount` which triggers `throw StateError`

**Fix**: Add `skippedRows.add(SkippedRow(..., reason: 'invalid_item_number'))` before `continue`. Remove `excludedCount++`.

## MEDIUM

### M1: Cross-Page Grid Line Contamination in Merger Guard (R2)

The plan flattens horizontal grid lines from ALL pages into a single list. Grid line Y positions are normalized per-page (0-1). A line at Y=0.30 on page 2 is indistinguishable from Y=0.30 on page 1, causing false merge-blocking.

**Fix**: Pass per-page grid line lists and filter by `ClassifiedRow.pageIndex` inside `_crossesGridLine`.

### M2: R4 bidAmount Backsolve Missing Guard on Negative bidAmount

`relativeError = diff / current.bidAmount!` — if bidAmount is negative, relativeError is negative, satisfying `< 0.005`.

**Fix**: Use `relativeError.abs() < 0.005` or add `bidAmount > 0` guard.

### M3: R1 Removes LS-Prefix Fallback Without Updating knownUnits

Current `normalize()` catches OCR-corrupted LS variants like `LSUIVI` via a startsWith('LS') fallback. The plan removes this, causing "Unknown unit" warnings.

**Fix**: Add `!UnitRegistry.isLumpSum(unit)` to the unknown unit check at `row_parser_v3.dart:202`.

## LOW

- **L1**: Test helpers use non-existent constructor parameters (tests won't compile as written)
- **L2**: R4 European periods regex narrowly scoped (intentionally conservative, no fix needed)
- **L3**: Inpaint radius reduction may leave minor grid line residue (verify visually)

## Remediation Priority

1. **Blocks implementation**: H1 (runtime crash)
2. **Before merge**: M1 (cross-page regression), M3 (spurious warnings)
3. **Nice-to-have**: M2 (negative bidAmount edge case)
