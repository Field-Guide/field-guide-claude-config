# Code Review: UI Refactor V2 Plan

## Verdict: APPROVE WITH CONDITIONS

## Critical Findings
- [C1] `copyContractorsFromEntry` uses non-existent `upsert` method — actual API is `add(entryId, contractorId)`
- [C2] `fg.surfaceHighlight` referenced in Phase 10.B but not a field on FieldGuideColors — map to `cs.outline` instead

## High Findings
- [H1] Phase 3.5 migration (v43) does not update SchemaVerifier expected columns for daily_entries
- [H2] Sync adapter may not include new repeat_last_* columns in payload
- [H3] `seedFromPrevious` force-unwraps nullable `createdByUserId!` — add null check
- [H4] Phase 3.5.A.3 omits exact insertion location — should go after line 31 in entry_tables.dart
- [H5] AppText factories not const-constructible (informational, acceptable)
- [H6] Phase 9.A.4 import should be field_guide_colors.dart, not colors.dart

## Medium Findings
- [M1] Line numbers will drift during multi-phase implementation
- [M2] AppGlassCard accent strip height unconstrained
- [M3] _StickyHeaderDelegate.shouldRebuild compares by reference
- [M4] Phase 12.B grep will flag design_system files — exclude from pattern
- [M5] AppPhotoGrid uses Image.file without caching
- [M6] seedFromPrevious return value wiring is ambiguous
- [M7] Plan says 25 components but barrel has 24

## Low Findings
- [L1-L5] Various minor improvements (see full review)

28/28 file paths verified against codebase. All correct.
