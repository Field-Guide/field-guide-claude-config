## Code Review

**Plan:** `.claude/plans/2026-04-05-pay-application.md`  
**Spec:** `.claude/specs/2026-04-05-pay-application-spec.md`  
**Verdict:** REJECT

### Findings

severity: HIGH  
category: code-quality  
file: `.claude/plans/2026-04-05-pay-application.md`  
line: 7239  
finding: The plan built the pay-app export machinery but never wired the actual `Export Pay App` entry point from the pay-items screen, so the primary spec flow was not implementable end-to-end.  
fix_guidance: Add the pay-items-screen AppBar action, dialog orchestration, overlap/replace handling, number review, and save/share follow-through.  
spec_reference: Sections 4-5, Pay Application Export Flow / Entry Points

severity: HIGH  
category: code-quality  
file: `.claude/plans/2026-04-05-pay-application.md`  
line: 3235  
finding: Same-range replacement logic partially reused identity but still chained new exports from the wrong baseline and did not clearly constrain chronology for new exports.  
fix_guidance: Reuse the existing pay-app number by default, resolve `previous_application_id` from the prior chronological pay app for the selected range, and block non-replacement ranges that do not continue chronology.  
spec_reference: Sections 1-3, chaining / chronological numbering / replace semantics

severity: MEDIUM  
category: code-quality  
file: `.claude/plans/2026-04-05-pay-application.md`  
line: 2004  
finding: The planned pay-app filename interpolated raw `DateTime` values, which would produce invalid Windows filename characters and break the export path in practice.  
fix_guidance: Format start/end as date-only safe strings before building the `.xlsx` filename.  
spec_reference: Section 4, Generation + Save/Share flow
