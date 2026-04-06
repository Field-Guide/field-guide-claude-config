## Completeness Review

**Spec:** `.claude/specs/2026-04-05-pay-application-spec.md`  
**Reviewed:** `.claude/plans/2026-04-05-pay-application.md`  
**Verdict:** REJECT

### Findings

severity: CRITICAL  
category: completeness  
file: `.claude/plans/2026-04-05-pay-application.md`  
line: 7239  
finding: The plan did not wire the spec’s primary `Pay Items screen -> Export Pay App` flow. Dialogs, providers, and export use cases existed, but the actual screen entry point was missing.  
fix_guidance: Add the AppBar action on `quantities_screen.dart` and route it through range selection, replace confirmation, number review, export, and save/share.  
spec_reference: Sections 4-5, Entry Points / Pay Application Export Flow

severity: CRITICAL  
category: completeness  
file: `.claude/plans/2026-04-05-pay-application.md`  
line: 7471  
finding: The plan created an exported-history widget but did not integrate it into the real Forms UX, so the spec’s requirement that exported Forms history remain separate from editable saved responses was not captured in the implementation path.  
fix_guidance: Modify `FormGalleryScreen` to load exported artifacts alongside saved responses and surface a distinct exported-history pane/tab.  
spec_reference: Sections 1, 4, 5

severity: HIGH  
category: completeness  
file: `.claude/plans/2026-04-05-pay-application.md`  
line: 709  
finding: The plan treated `ExportArtifactRepository` as if it only read the new `export_artifacts` table, which would drop existing form/entry/photo export records from the unified exported-history browser.  
fix_guidance: Add a compatibility bridge that maps legacy `form_exports`, `entry_exports`, and photo-export records into the exported-history read model until direct convergence is complete.  
spec_reference: Sections 1-2, unified export-history architecture

severity: HIGH  
category: completeness  
file: `.claude/plans/2026-04-05-pay-application.md`  
line: 3235  
finding: The replacement flow did not fully preserve spec intent around same-range identity and chronology. Reused identity was only partially captured, and the plan did not explicitly block out-of-sequence non-replacement ranges.  
fix_guidance: Preserve same-range number by default, chain from the prior chronological pay app for that range, and block non-replacement ranges that do not continue chronology.  
spec_reference: Sections 1-3, same-range replace + chronological rules
