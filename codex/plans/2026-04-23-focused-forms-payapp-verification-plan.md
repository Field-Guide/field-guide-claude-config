# Focused Forms, Pay App, And UI Responsiveness 100 Percent Verification Spec

## Summary

This is the next targeted verification lane. When work resumes, do not run the
full `pre-update-verification` suite first. Stay inside the forms, pay-app, and
UI responsiveness surface until this spec is green.

This plan replaces the prior focused Forms/Pay App verification plan and adds
the UI/UX responsiveness gate as the first required phase. The responsiveness
gate applies across supported phone and tablet device classes, not only the S21.

In scope:

- UI responsiveness, scroll smoothness, transition smoothness, and input responsiveness
- Phone and tablet verification
- Daily Entry / IDR
- MDOT 0582B
- MDOT 1174R
- MDOT 1126
- Pay application export and saved-artifact lifecycle

Out of scope until this spec is complete:

- broad prerelease suite reruns
- unrelated feature forward/backward sweeps
- non-forms/non-pay-app release confidence work
- cosmetic-only performance overlays that do not produce release evidence

## Hard Rules

- [ ] Use real auth only. No `MOCK_AUTH`, mock sessions, or stale builds.
- [ ] Run only targeted flows and focused local tests until this checklist is green.
- [ ] Treat marker-only proof as invalid. Every mapped field/cell must be verified.
- [ ] Treat partial UI fillout as invalid. Each required form must be fillable to full mapped capacity through the real app flow.
- [ ] Treat preview-only proof as invalid. Preview, saved state, export, and reopen all matter.
- [ ] Treat local-only writer proof as supporting evidence, not final acceptance.
- [ ] Fail the lane on any runtime error, layout defect, sync gap, stale artifact, mapping mismatch, repeated frame spike, or device-class responsiveness defect.

## Phase 0: All-Device UI Responsiveness Gate

- [ ] Run targeted responsiveness verification on current phone and tablet builds.
- [ ] Use profile or release-like mode for performance acceptance. Treat debug-mode choppiness as diagnostic only.
- [ ] Capture Flutter frame timing data for every measured action group.
- [ ] Save timing artifacts under `build/perf/` with device class, device model, route/action labels, timestamps, logs, and run ID.
- [ ] Publish a consolidated frame timing scorecard for every Phase 0 run in JSON, Markdown, and CSV with p50/p95/p99/max frame cost, captured cadence, build/raster split, 60 FPS compatibility, and 120 FPS readiness.
- [ ] Treat 60 FPS compatibility as the Phase 0 move-on floor: every action group must have at least 95% of measured frames inside the 16.67ms frame-work budget, with no unresolved runtime/layout defects.
- [ ] Keep 120 FPS readiness visible as the Phase 0 optimization target using an 8.33ms frame-work budget, and preserve all misses in the scorecard for follow-up root-cause work.
- [ ] Flag the likely bottleneck for each failing action group as build, raster, or mixed so fixes are trace-directed.
- [ ] Sort and preserve the worst action groups for every run so Daily Entries tablet jank and any later app-wide regressions are immediately visible without hand-parsing raw JSON.
- [ ] Capture screenshots or screen recordings for any action group that feels choppy during manual review.
- [ ] Verify primary tab switching is smooth across Dashboard, Calendar, Projects, and Settings.
- [ ] Verify full UI-triggered sync remains responsive and records a dedicated full-sync timing window against an explicitly specified project, not the current UI project or actor project index.
- [ ] Verify full UI-triggered sync timing uses a real non-zero pending payload before the sync tap; zero-payload timing is invalid.
- [ ] Verify route transitions into and out of Forms, Pay App, saved exports, previews, and comparison screens are smooth.
- [ ] Verify vertical scrolling is smooth on list-heavy phone and tablet layouts.
- [ ] Use a standardized responsiveness surface catalog for screen/list probes so any trace-proven infrastructure issue can be checked across other affected screens, not only the first repro screen.
- [ ] Capture Springfield Daily Entries list long-scroll timing as the first list-jank repro surface.
- [x] Fix and regress tablet Pay Items/Quantities split-pane detail selection so Measurement & Payment updates when selecting a different pay item, and the detail contract-value row does not overflow.
- [ ] Verify keyboard entry, field focus, section expansion, row add/edit/delete, and bottom-action visibility feel responsive.
- [ ] Verify tablet layouts do not introduce extra rebuild, layout, or scroll jank versus phone layouts.
- [ ] Verify no repeated UI-thread or raster-thread spikes remain during simple tab switches.
- [ ] Verify no unexplained UI-thread or raster-thread spike above 100ms remains in measured flows.
- [ ] Verify at least 95% of measured frames stay within the active device frame budget for each scripted action group.
- [ ] Verify at least 95% of measured frames stay within the 120 FPS readiness budget for each scripted action group, or document a trace-backed device refresh limitation separately from app frame work.
- [ ] Use Flutter DevTools timeline, rebuild profiling, widget tree inspection, and raster stats to diagnose any failed action group.
- [ ] Inspect whether tab switching rebuilds or replaces more shell/UI state than necessary.
- [ ] Inspect provider/listener scope for broad invalidations during tab switches, scrolling, form entry, and pay-app navigation.
- [ ] Inspect expensive `build()` work, repeated formatting, synchronous parsing, oversized image decoding, and non-lazy list rendering.
- [ ] Optimize only trace-proven hot spots.
- [ ] Re-run the same phone and tablet responsiveness flows after fixes.
- [ ] Attach before/after frame timing artifacts when any performance fix is made.
- [ ] Require manual signoff that taps, scrolling, field entry, tab changes, and route transitions feel smooth and enterprise-level on both phone and tablet.

## Current Starting Point

- [ ] Preserve the current ledger summary as the baseline for this spec.
- [ ] Accept that the last full prerelease artifact is still red and is not the gate for this lane.
- [ ] Carry forward the known real fixes already landed:
  - [ ] pay-app stale local artifact recovery
  - [ ] seeded workbook path repair
  - [ ] forms compact-screen snackbar repair
  - [ ] targeted backward-flow manifest repairs
- [ ] Do not claim this lane complete until fresh targeted evidence exists on the current phone and tablet builds.

## Targeted Flow Set Only

- [ ] `forms-supported-forms-proof-ui-flow`
- [ ] `idr-full-capacity-ui-flow`
- [ ] `sync-full-responsiveness-ui-flow`
- [ ] `forms-export-proof-ui-flow`
- [ ] `forms-gallery-ui-flow`
- [ ] `forms-gallery-backward-traversal-ui-flow`
- [ ] `forms-pdf-preview-ui-flow`
- [ ] `forms-save-reload-ui-flow`
- [ ] `pay-app-export-proof-ui-flow`
- [ ] `pay-app-forward-happy-ui-flow`
- [ ] `pay-app-backward-traversal-ui-flow`
- [ ] `settings-saved-exports-ui-flow` and related reopen flows if saved exports remain part of pay-app proof
- [ ] Add focused responsiveness timing windows around tab switches, full sync, list scrolling, form interactions, pay-app navigation, preview open/reopen, and saved export reopen.
- [ ] Bind targeted device runs to the explicit canonical project id used by the lane so wrong-project pathing fails before evidence is accepted.
- [ ] Add `daily-entries-list-scroll-responsiveness-ui-flow` for Springfield Daily Entries long-scroll evidence.
- [ ] Do not run `pre-update-verification` during this lane unless this spec is already green and we explicitly choose to promote it.

## Phase 1: Canonical Verification Contracts

- [x] Define one canonical full-capacity fixture per form type: IDR, 0582B, 1174R, 1126.
- [x] Define one canonical positive-earned pay-app scenario with real non-zero totals.
- [x] For each form, maintain a machine-checkable inventory of:
  - [x] app field path
  - [x] saved local value
  - [x] synced remote value
  - [x] preview expectation
  - [x] exported AcroForm field name or rendered location
  - [x] row/cell identity
  - [x] required versus intentionally blank status
- [x] For pay app, maintain a machine-checkable inventory of:
  - [x] project header values
  - [x] application number and previous-application chain
  - [x] period start/end
  - [x] bid-item rows
  - [x] current period quantities and amounts
  - [x] earned-to-date totals
  - [x] artifact filename/path/hash expectations

Evidence:

- `tools/testing/catalog/CanonicalVerificationContracts.ps1`
- `tools/testing/tests/CanonicalVerificationContracts.Tests.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\testing\Test-TestingHarness.ps1`

## Phase 2: UI Fillability Proof

- [x] Add a machine-checkable fillability proof gate that rejects marker-only, DB-only seeded, partial, preview-only, local-writer-only, row-zero, phantom-row, duplicate-row, missing-device-class, missing-field-id, runtime-error, layout-defect, and missing-timing evidence.
- [ ] Prove each form can be filled through the real UI to the full mapped PDF capacity.
- [ ] Prove UI entry does not depend on DB-only seeding for the actual field values under verification.
- [ ] Prove row add/edit/delete flows work cleanly and do not create phantom, duplicated, or row-zero records.
- [ ] Prove keyboard, scrolling, visibility, and section expansion are reliable on phone and tablet.
- [ ] Prove fillability remains responsive while entering long forms, repeated rows, signatures, photos, and attachments.

Per-form fillability:

- [ ] IDR: fill header, remarks/activity, all contractor sections, personnel rows, equipment rows/checks, quantities/materials, attachments/photos/forms, signature, and overflow/continuation content.
- [ ] 0582B: fill header, all mapped quick-test rows, all mapped proctor rows, chart standards, operating standards, F/G/H-driving inputs, remarks, and numbering starting at 1.
- [ ] 1174R: fill header, observation rows, QA rows, quantity rows, air/slump or equivalent repeated rows, remarks, closeout, and signature fields.
- [ ] 1126: fill header, rainfall, all mapped control-measure rows, status/corrective-action cells, remarks, and typed signature.

Evidence so far:

- `Get-TestingCanonicalFormFillabilityContract`
- `Test-TestingCanonicalFormFillabilityProof`
- `Invoke-TestingUiValidateFormGalleryLifecycleFillability`
- `tools/testing/test-results/2026-04-24/phase2e-idr-full-capacity-phone-tablet-20260424-0105/summary.json` is now republished with `passed=true`, `queueDrainGateApplied=false`, `failedActionCount=0`, `runtimeErrors=0`, and `loggingGaps=0`, which preserves the green S21 + S10Tablet IDR full-capacity device actions while keeping queue residue visible as later-phase sync evidence rather than a Phase 2 blocker.
- `test/features/quantities/presentation/screens/quantities_screen_test.dart` covers tablet Pay Items/Quantities split-pane detail reselection and contract-value overflow regression.
- `lib/features/quantities/di/quantity_screen_providers.dart` now recreates the tablet split-pane bid-item detail controller when selection changes, which fixes the stale Measurement & Payment panel on reselection.
- `lib/features/quantities/presentation/widgets/bid_item_contract_value_section.dart` now keeps the split-pane contract-value row within bounds on tablet widths.
- `tools/testing/flows/sync/Flow.FormGalleryLifecycle.ps1` now emits an explicit marker-sized partial proof, so the current gallery lifecycle cannot satisfy Phase 2 until full-capacity UI fill actions replace it.
- `lib/core/driver/seed/harness_seed_data.dart` preserves seeded project child rows such as locations during entry-draft seeding, which fixes wrong-project / missing-location IDR targeting during real UI runs.
- `tools/testing/flows/sync/Flow.DailyEntryActivity.ps1` now explicitly opens the IDR weather dropdown before selecting the target option.
- `tools/testing/flows/sync/FlowRuntime.ps1` now performs preflight UI normalization so stale modal/dropdown residue from a failed prior run does not contaminate the next device pass.
- `tools/testing/tests/CanonicalVerificationContracts.Tests.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\testing\Test-TestingHarness.ps1`

Current open Phase 2 blocker:

- [ ] IDR full-capacity phone/tablet execution is no longer blocked on `report_header_weather_dropdown`; the remaining IDR closure work is to prove any still-open signature-specific contract and then carry the same full-capacity standard through 0582B, 1174R, and 1126.

## Phase 3: Saved State And Sync Proof

- [ ] Save each fully filled form and reopen it from the real gallery flow.
- [ ] Verify local `form_responses` data matches the canonical fixture field by field.
- [ ] Verify remote synced `form_responses` data matches the same canonical fixture where remote sync is part of the flow.
- [ ] Verify gallery tiles, reopen routes, and selected form identity are correct.
- [ ] Verify no stale preview cache, stale draft state, or stale row ordering survives after save/reopen.
- [ ] Verify cleanup and reruns do not rely on residue from earlier attempts.

## Phase 4: Preview Fidelity Proof

- [ ] Prove every form preview is generated from the latest saved state.
- [ ] Prove preview is read-only where the product contract requires read-only preview.
- [ ] Verify every mapped AcroForm cell or rendered text position, not just marker strings.
- [ ] Fail on blank, shifted, stale, duplicated, flattened-when-editable, or wrong-field output.
- [ ] Save preview screenshots, parsed field/value proof, and any rendered page comparisons.

Per-form preview fidelity:

- [ ] IDR preview proves all mapped contractor/personnel/equipment/activity/quantity/photo/form-attachment cells and signature-related output.
- [ ] 0582B preview proves all mapped test rows, proctor rows, standards boxes, F/G/H values, remarks, and no row-zero or duplicate-write output.
- [ ] 1174R preview proves all mapped observation, QA, quantity, remarks, and closeout cells.
- [ ] 1126 preview proves rainfall, control-measure rows, status/corrective-action cells, remarks, and signature/name/date output.

## Phase 5: Export Fidelity Proof

- [ ] Export each form from the current fully filled state.
- [ ] Verify exported PDFs preserve editability where the contract expects editable AcroForm output.
- [ ] Verify every mapped AcroForm field value and every rendered cell/row position.
- [ ] Compare the export against the shipped template field inventory so missing, unmapped, shifted, or double-written fields fail loudly.
- [ ] Reopen exported artifacts and confirm they match preview content.

## Phase 6: Pay App End-To-End Proof

- [ ] Use a positive-earned pay application only. Zero-earned proof is invalid.
- [ ] Verify the saved pay-app detail can recover from stale or missing local artifact paths.
- [ ] Verify replacement/rebuild semantics update the existing pay app instead of creating the wrong duplicate workflow.
- [ ] Verify workbook export uses a real local file with fresh hash, size, path, and timestamp.
- [ ] Verify the workbook contains the correct project, application number, period dates, bid-item rows, per-item values, and summary totals.
- [ ] Verify earned-this-period and earned-to-date values are non-zero and correct.
- [ ] Verify saved export copy/share/open actions operate on the rebuilt current artifact, not stale residue.
- [ ] Reopen the saved export path from Settings if that remains part of the shipped user flow.
- [ ] Verify Pay App detail, export, saved artifact, and contractor comparison interactions remain responsive on phone and tablet.
- [ ] If contractor comparison is still a release-facing pay-app surface, either:
  - [ ] verify its import/export parity here, or
  - [ ] explicitly mark it out of scope before execution begins.

## Phase 7: Focused Local Safety Net

- [ ] Extend focused tests for canonical field inventories and row/cell mapping assertions.
- [ ] Extend PDF contract probing so named fields and structured row/cell expectations are asserted directly.
- [ ] Add or reuse a focused performance harness that records frame timings for labeled UI action groups.
- [ ] Keep targeted widget/domain tests for stale-artifact recovery, preview caching, and row-capacity mapping green.
- [ ] Keep `flutter analyze` clean on every touched slice before device reruns.
- [ ] Bring full `flutter analyze` back to zero issues as part of Phase 0 before device acceptance.
- [ ] Add focused lint/static checks only when they lock in verified architecture boundaries or expose a real binding gap.

## Phase 8: Two-Pass Device Verification

- [ ] Pass 1: targeted focused runs on current phone and tablet builds.
- [ ] Include responsiveness timing artifacts in Pass 1.
- [ ] Perform a deliberate review pass over code, frame timing data, screenshots, exports, sync proof, and evidence after the first green run.
- [ ] Fix any measured UI responsiveness regression before Pass 2.
- [ ] Pass 2: rerun the same targeted flows to prove the first pass was not residue-dependent.
- [ ] Include responsiveness timing artifacts in Pass 2.
- [ ] Capture exact run IDs, timestamps, screenshots, exported PDFs, exported workbooks, parsed inspections, sync-status output, DB proof, frame timing JSON, and logs needed to explain correctness.
- [ ] Keep Android rebuilds sequential when a fresh on-device build is required.

## Release Gate For This Lane

- [ ] Phone responsiveness gate is green.
- [ ] Tablet responsiveness gate is green.
- [ ] Tab switches, scrolling, form entry, preview open/reopen, pay-app navigation, and saved-export reopen feel smooth and responsive.
- [ ] Full UI-triggered sync has dedicated timing artifacts and no unresolved responsiveness spikes.
- [ ] Frame timing artifacts show no unresolved repeated spikes or major dips.
- [ ] Every in-scope form is fully fillable through the UI.
- [ ] Every mapped AcroForm cell is filled with the correct information or intentionally asserted blank.
- [ ] Every mapping is correct in saved state, preview, export, and reopen.
- [ ] No runtime errors, layout defects, sync gaps, stale artifacts, wrong-route reopen behavior, or responsiveness defects remain.
- [ ] Full `flutter analyze` is clean and any newly added architecture guardrails are green.
- [ ] Pay-app export is positive-earned, fresh, reopenable, responsive, and numerically correct.
- [ ] Both verification passes are green on the current phone and tablet builds.
- [ ] Evidence is saved in the canonical test-results/artifact locations and linked back to this spec.
- [ ] Only after this targeted spec is green do we consider promoting back to a broader prerelease sweep.

## Assumptions

- This should be saved as a new replacement plan file, not appended to the old file.
- The new plan keeps the original focused Forms and Pay App scope intact.
- The responsiveness gate applies to all supported device classes, with explicit phone and tablet evidence.
- No user-visible performance overlay is required for release acceptance.
