# Plan Review: Debug Framework

**Plan:** `.claude/plans/2026-03-14-debug-framework.md`
**Date:** 2026-03-14
**Reviewers:** code-review-agent (opus), security-agent (opus)

## Code Review Verdict: REJECT → fixed inline
## Security Review Verdict: APPROVE WITH CONDITIONS → fixed inline

## CRITICAL (fixed in plan)

1. **`/categories` returns wrong format** — Plan returned sorted array, spec requires `{"sync":47,"pdf":12}` count map. Fixed.
2. **Case-sensitive scrubbing** — Plan missing `.toLowerCase()` on key comparison. Fixed to match spec.
3. **Double logging via debugPrint hook** — `_log()` calls `debugPrint()` which is hooked to write to app log sink, creating circular/double writes. Fixed: `_log()` now uses `Zone.root.print()` for console output instead of `debugPrint()`.

## HIGH (fixed in plan)

4. **Research agent model: sonnet → opus** — Spec explicitly requires Opus. Fixed.
5. **`assert(!kReleaseMode)` missing from `_sendHttp()`** — Added to cover all call paths.
6. **Missing `.claude/debug-sessions/` creation + gitignore step** — Added to Phase 5.
7. **CORS wildcard on server** — Changed from `*` to empty/removed.
8. **SIGTERM handler missing** — Added alongside SIGINT.
9. **File change summary counts** — Reconciled.

## MEDIUM (noted for implementation)

- Background sync handler runs in separate isolate — Logger static state is per-isolate
- Line numbers are approximate — implementing agent should locate methods by name
- Existing `debug_logger_test.dart` may need updates after forwarding
- `kill %1` doesn't work on Windows — use PowerShell Stop-Process

## LOW (deferred)

- Server startup banner format differs from spec (functional, not blocking)
- `_handleAppLogFailure` recursion guard is per-call only
