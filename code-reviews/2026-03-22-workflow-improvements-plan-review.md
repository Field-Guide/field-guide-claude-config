# Plan Review: Workflow Improvements

**Plan**: `.claude/plans/2026-03-22-workflow-improvements.md`
**Spec**: `.claude/specs/2026-03-22-workflow-improvements-spec.md`
**Date**: 2026-03-22

---

## Code Review Agent — Initial: REJECT → After fixes: APPROVE

### CRITICAL (3 — all fixed)

1. **3 spec items missing from plan** — .gitignore fixes (P0), bare supabase→npx supabase (P1), BRANCH annotations (P2)
   - **Fix**: Added Sub-phase 1.0 (.gitignore), Sub-phase 1.2b (bare supabase), Sub-phase 1.3b (BRANCH annotations deferred)

2. **V5 constructor blast radius unaccounted** — ProjectRepository constructor change would break main.dart, driver_server.dart, test_harness.dart
   - **Fix**: Added all 3 call sites to Phase 3 file list with explicit instructions to grep for all constructor sites

3. **Spec requires re-audit of catch(_) before fixing; plan skipped it**
   - **Fix**: Added Sub-phase 4.1b with mandatory audit step before any fixes begin

### HIGH (3 — all fixed)

4. **V5 raw SQL still an anti-pattern in repository** — sync_control suppression should eventually be extracted
   - **Fix**: Added TODO comment for SyncControlService extraction

5. **PRAGMA comment removal scope incomplete** — stale text is within larger doc blocks
   - **Fix**: Changed from "remove" to "update to reflect reality", added NOTE about preserving doc blocks

6. **Pre-commit hook PowerShell array issue** — `git diff` output needs `@()` wrapper
   - **Fix**: Changed to `@(git diff ...)` with explanatory comment

### MEDIUM (4 — 2 fixed, 2 noted)

7. catch(_) instance counts are estimates → Fixed by adding re-audit step (4.1b)
8. Phase ordering for forms model audit → Noted, acceptable as-is
9. Phase 7 step granularity too coarse → Noted, implementing agent can split as needed
10. firstWhere default values not specified per-enum → Noted, implementing agent reads context

### LOW (3 — 1 fixed, 2 noted)

11. No commit strategy specified → Noted for implementation
12. Spike skill nested markdown fences → Noted for implementation
13. `flutter analyze` doesn't accept path args → **Fixed**: changed to `pwsh -Command "flutter analyze"`

### KISS Improvement Applied

- Removed unnecessary provider proxy methods (Sub-phase 3.3 deleted). Screen already accesses repository directly via `projectProvider.repository`. Adding pass-through methods was unnecessary indirection.

---

## Security Agent — APPROVE

### MEDIUM (2 — noted)

- SEC-001: Auth exception `.toString()` may leak session metadata past Logger scrubber → Consistent with existing pattern, no change needed
- SEC-003: `undoSubmission()` has no explicit audit event type → change_log + revision_number provides traceability

### LOW (2 — 1 fixed)

- SEC-002: Hook regex false positive risk → Cosmetic, not security gap
- SEC-004: Agent memory should exclude credential examples → **Fixed**: Added security note to Phase 7 header
