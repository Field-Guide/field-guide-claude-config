# Session State

**Last Updated**: 2026-03-09 | **Session**: 529

## Current Phase
- **Phase**: Cross-Device Parity — PLAN COMPLETE, READY FOR IMPLEMENT
- **Status**: Full implementation plan written via `/writing-plans`. CodeMunch index (681 files, 5341 symbols). Dual adversarial review (code-review + security, Opus). All CRITICAL/HIGH findings addressed in plan. Next: `/implement .claude/plans/2026-03-09-pdfrx-parity.md`.

## HOT CONTEXT - Resume Here

### What Was Done This Session (529)

1. **Ran `/writing-plans`** on pdfrx parity spec — full CodeMunch index, dependency graph, blast radius
2. **Wrote 7-phase plan** (0-6): pre-flight → contract update → pdfrx swap → grid threshold → fixture regen → 3-device validation → cleanup
3. **Key design: `toPngBytes()` on RenderedPage** — centralizes BGRA→PNG conversion (DRY), avoids leaking `image` package into pipeline orchestrator
4. **Adversarial review by code-review + security agents** (Opus, parallel):
   - Code review: 2 CRITICAL (Size import, pdfrx API unverifiable), 3 HIGH (missing benchmark cleanup, DRY violation, pipeline SoC) — all addressed
   - Security review: 0 CRITICAL, 2 HIGH (assert stripped in release, silent catch blocks) — all addressed
5. **Plan saved**: `.claude/plans/2026-03-09-pdfrx-parity.md`
6. **Dependency graph updated**: `.claude/dependency_graphs/2026-03-09-pdfrx-parity/dependency-graph.md`

### What Needs to Happen Next
1. **Run `/implement .claude/plans/2026-03-09-pdfrx-parity.md`** — Phase 0-6
2. **IMPORTANT**: Step 2.1.3 requires verifying pdfrx API signatures after `pub get` (pdfrx not yet installed)
3. **Three-device validation** (Phase 5): S21+, S25 Ultra, Windows — all must produce 131 items, $0 delta
4. **GATE**: All 3 must match before R1-R5 accuracy work

## Blockers

### BLOCKER-34: Cross-Device Parity — pdfrx migration needed
**Status**: PLAN COMPLETE, READY FOR IMPLEMENT (Session 529)
**Plan**: `.claude/plans/2026-03-09-pdfrx-parity.md`
**Spec**: `.claude/specs/2026-03-09-pdfrx-parity-spec.md`
**Evidence**: S25 Ultra (Android 16) produces 130 items vs 131 on S21+/Windows. $457K checksum gap.

### BLOCKER-33: 100% Accuracy — 34 GT failures
**Status**: DEFERRED — waiting on parity (Session 528)
**Plan**: `.claude/plans/2026-03-09-100pct-accuracy-plan.md`
**Decision**: Re-evaluate R1-R5 after pdfrx parity established on all devices.

### BLOCKER-29: Cannot delete synced data from device — sync re-pushes
**Status**: OPEN — HIGH PRIORITY

### BLOCKER-28: SQLite Encryption (sqlcipher)
**Status**: OPEN — tracked separately.

### BLOCKER-24: SQLite Missing UNIQUE Constraint on Project Number
**Status**: OPEN — HIGH PRIORITY

### BLOCKER-22: Location Field Stuck "Loading"
**Status**: OPEN — HIGH PRIORITY

### BLOCKER-23: Flutter Keys Not Propagating to Android resource-id
**Status**: OPEN — MEDIUM

### BLOCKER-10: Fixture Generator Requires SPRINGFIELD_PDF Runtime Define
**Status**: OPEN (PDF scope only)

## Recent Sessions

### Session 529 (2026-03-09)
**Work**: Ran `/writing-plans` on pdfrx parity spec. CodeMunch index (681 files). Wrote 7-phase plan with full code. Dual adversarial review (code-review + security). All CRITICAL/HIGH addressed: `toPngBytes()` DRY helper, runtime buffer validation, pdfrx API verify step, benchmark cleanup.
**Decisions**: Centralize BGRA→PNG in `RenderedPage.toPngBytes()`. Runtime `if` not `assert` for buffer validation. Verify pdfrx API post-install before coding.
**Next**: `/implement .claude/plans/2026-03-09-pdfrx-parity.md` → three-device validation.

### Session 528 (2026-03-09)
**Work**: Two-phone extraction test (S21+ vs S25 Ultra) confirmed cross-device divergence. Full test suite 906/906 pass. Audited all 3 plans. Brainstormed unified pdfrx parity spec. Adversarial review + CodeMunch blast radius.
**Decisions**: Parity first (pdfrx + threshold), accuracy fixes deferred. Raw BGRA through pipeline. Pin pdfrx to exact 2.2.24. Mask coverage gate 3%-10%.
**Next**: `/writing-plans` → `/implement` → three-device validation.

### Session 527 (2026-03-09)
**Work**: Tested `/implement` skill on 100% accuracy plan. Orchestrator violated protocol. Full pipeline regression 130→43 items. Reverted all changes. Recovered files. Recreated 6 sync test files.
**Decisions**: `/implement` needs major fixes. Plan must be reworked. Fixes one-at-a-time with GT trace.
**Next**: Fix plan. Implement one fix at a time.

### Session 526 (2026-03-09)
**Work**: 6 Opus research agents deep-traced all 34 GT failures. Wrote spec, dependency graph, implementation plan (7 phases). Adversarial review found 3 CRITICAL + 3 HIGH issues.
**Decisions**: Position-based grid line removal replaces morphological approach. `_rescueBoilerplateRows` must be guarded.
**Next**: Implement via `/implement`.

### Session 525 (2026-03-09)
**Work**: Full GT trace (34 failures). 7 research agents + 2 Opus verification. Found 3/5 original fixes had wrong root causes. Revised to R1-R5 plan.
**Decisions**: Opus verification before implementation. GT unit abbreviations are correct — pipeline normalization is wrong.
**Next**: Write formal plan.

## Active Plans

### pdfrx Parity + Grid Line Threshold — PLAN COMPLETE (Session 529)
- **Plan**: `.claude/plans/2026-03-09-pdfrx-parity.md`
- **Spec**: `.claude/specs/2026-03-09-pdfrx-parity-spec.md`
- **Review**: `.claude/adversarial_reviews/2026-03-09-pdfrx-parity/review.md`
- **Dependency Graph**: `.claude/dependency_graphs/2026-03-09-pdfrx-parity/dependency-graph.md`
- **Blast Radius**: `.claude/dependency_graphs/2026-03-09-pdfrx-parity/blast-radius.md`
- **Status**: Plan finalized + adversarial review addressed. Ready for `/implement`.

### 100% Accuracy R1-R5 — DEFERRED (Session 528)
- **Plan**: `.claude/plans/2026-03-09-100pct-accuracy-plan.md`
- **Status**: Deferred until pdfrx parity established. Will re-evaluate after three-device validation.

### UI Refactor — PLAN REVIEWED + HARDENED (Session 512)
- **Plan**: `.claude/plans/2026-03-06-ui-refactor-comprehensive.md`
- **Status**: 12 phases + Phase 3.5. Reviewed by 3 agents.

## Reference
- **pdfrx Parity Plan**: `.claude/plans/2026-03-09-pdfrx-parity.md`
- **pdfrx Parity Spec**: `.claude/specs/2026-03-09-pdfrx-parity-spec.md`
- **Adversarial Review (spec)**: `.claude/adversarial_reviews/2026-03-09-pdfrx-parity/review.md`
- **Dependency Graph**: `.claude/dependency_graphs/2026-03-09-pdfrx-parity/dependency-graph.md`
- **Blast Radius**: `.claude/dependency_graphs/2026-03-09-pdfrx-parity/blast-radius.md`
- **Device Baselines**: `test/features/pdf/extraction/device-baselines/`
- **100% Accuracy Plan**: `.claude/plans/2026-03-09-100pct-accuracy-plan.md`
- **Grid Line Fix Plan**: `.claude/plans/2026-03-08-grid-line-threshold-fix.md`
- **pdfrx Migration Plan (old)**: `.claude/plans/2026-03-07-pdfrx-renderer-migration.md`
- **Defects**: `.claude/defects/_defects-pdf.md`, `_defects-sync.md`, `_defects-projects.md`
- **Archive**: `.claude/logs/state-archive.md`
