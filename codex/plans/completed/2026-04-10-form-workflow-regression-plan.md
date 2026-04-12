# 2026-04-10 Form Workflow Regression Plan

## Scope

This is the active TODO/spec for the latest live-device regressions reported
after the previous 0582B and form-fidelity pass. No item is closed until it is
implemented, covered by focused tests where feasible, rebuilt into a real-auth
Samsung APK, and verified on the physical device.

## Non-Negotiables

- Do not use `MOCK_AUTH`.
- Do not validate against mock-auth builds or mock sessions.
- Do not add test-only runtime hooks.
- Preserve AcroForm fields for export; preview may use a read-only flattened
  copy only when needed to prevent editable/double-rendered viewer fields.
- Verify on Samsung device `RFCNC0Y975L` against a real backend session.

## New TODOs

- [ ] Pay-app/form-filler final completion lane
  - Canonical spec:
    `.codex/plans/2026-04-11-pay-app-form-final-verification-plan.md`.
  - Fix compact pay-app number dialog overflow.
  - Add shared numeric keyboard progression for 0582B, 1126, and 1174R form
    fillers.
  - Replace worksheet-per-pay-app canonical workbook output with a G703-style
    running ledger: one primary worksheet, all bid items for the selected
    project as vertical rows, 20 daily dates and three pay-app groups as
    horizontal columns for the Springfield verification flow, only used items
    populated per date, and bid/quantity-to-date totals inspectable. Production
    must not hard-code Springfield's current 131-item catalog size.
  - Keep quantity tracking single-source: `entry_quantities` is the canonical
    ledger, `bid_items` is the full static catalog, `daily_entries` is date and
    narrative context, and pay-app records are reporting periods only.
  - Add contractor comparison Excel and OCR/PDF fixture parity coverage.
  - Create 20 realistic demo-quality Springfield daily entries with five used
    pay items per entry for the live-device pay-app verification.
  - Re-run final all-form field-fill/preview/export fidelity verification for
    Daily Entry/IDR, 0582B, 1174R, and 1126.
  - Create workstream evidence manifests, self-review every spec bullet as
    `pass`/`fail`/`blocked`, iterate until green, then run completeness-agent
    review before reporting completion.

## Implementation Status - 2026-04-11 Pay-App Ledger Checkpoint

- Canonical source-of-truth rule saved:
  - `entry_quantities` is the project quantity ledger over time.
  - `bid_items` is the selected project's full static contract catalog.
  - `daily_entries` provides date/narrative context only.
  - `pay_applications` provides reporting periods/app numbers only.
- Workbook implementation checkpoint:
  - `BuildProjectPayAppWorkbookUseCase` now loads bid items by `projectId`,
    natural-sorts them, and builds daily ledger postings from
    `EntryQuantityRepository.getDailyPostingsByDateRange`.
  - Production row count is adaptive to the selected project's bid-item catalog;
    Springfield's current `131` rows are a fixture/device acceptance count only,
    not a hard-coded production limit.
  - `PayAppProjectWorkbookBuilder` now writes one `G703 Ledger` worksheet with
    frozen static bid-item columns, quantity/amount to date, percent complete,
    balance to finish, horizontal daily quantity columns, horizontal pay-app
    period groups, formulas, totals, filters, and frozen review panes.
  - Pay-app date range querying no longer converts midnight UTC pay-app period
    dates through local time, preventing Eastern-time off-by-one query windows.
- Pay-app dialog/export checkpoint:
  - `PayAppNumberDialog` action buttons now wrap on compact widths instead of
    overflowing.
  - `AppTextField` no longer duplicates the same key onto its inner
    `TextFormField`, fixing keyed field finders and reducing ambiguous test and
    driver matches.
  - Saving the project workbook from the post-export dialog suppresses the
    intermediate `Saved copy to ...` snackbar so the user sees the final
    `Exported Pay Application #...` completion message.
- Local verification:
  - `flutter test test/features/pay_applications/data/services/pay_app_project_workbook_builder_test.dart test/features/pay_applications/domain/usecases/build_project_pay_app_workbook_use_case_test.dart test/features/pay_applications/domain/usecases/rebuild_project_pay_app_workbook_use_case_test.dart test/core/design_system/app_text_field_test.dart test/features/quantities/presentation/screens/quantities_screen_export_flow_test.dart test/features/quantities/presentation/screens/quantities_screen_pay_app_export_flow_test.dart`:
    green, `18` tests passed.
  - `flutter analyze` over the touched pay-app workbook/usecase, quantity
    ledger, `AppTextField`, pay-app dialog/exporter, export-flow tests, and
    harness files: green, no issues found.
- Remaining gates:
  - Full real-auth Samsung verification and the remaining contractor comparison,
    demo data, and all-form PDF fidelity lanes are still open under the
    canonical spec.

## Implementation Status - 2026-04-11 Numeric Progression Checkpoint

- Compact pay-app dialog checkpoint:
  - Added an explicit phone-width `PayAppNumberDialog` widget regression test
    proving compact action wrapping and successful submit without overflow.
- Form numeric progression checkpoint:
  - `FormRepeatedRowComposer` now owns focus nodes and submit traversal for
    standardized row-entry flows, advancing through fields and committing the
    draft from the last field when possible.
  - 1174R Air/Slump, QA, and Quantity row-entry flows inherit that shared
    traversal.
  - 0582B Quick Test numeric inputs now expose `Next` through the input order
    and `Done` on the final depth-below-grade field, which sends the row when
    the row is valid.
  - 0582B Proctor setup, HMA, standards, and weight-entry numeric fields now
    expose explicit `Next` / `Done` actions where the field owner can determine
    field order.
  - 1126 rainfall inches now exposes `Done` and advances through the weekly
    SESC flow hook when used from the rainfall step.
- Local verification:
  - Focused form progression tests are green for 0582B Quick Test final-field
    submit, 1126 rainfall submit, 1174R row composer next-field traversal, and
    existing 1174R fixed-slot append behavior.
  - Combined focused suite is green: `35` tests passed across pay-app workbook,
    pay-app export, compact pay-app dialog, `AppTextField`, 0582B quick test,
    1126 steps, 1174R form screen, and 0582B proctor widgets.
  - Focused `flutter analyze` across touched pay-app, quantity, design-system,
    and form-progression files is green with no issues.

- [x] 0582B Original column numbering
  - The upper `ORIGINAL` column is effectively the sent test number and must
    start at `1`, never `0`.
  - Semantics:
    - `TEST NUMBER` in the bottom proctor section is the count of proctor tests
      sent to the form.
    - `ORIGINAL` in the upper results section is the count of tests sent from
      the form.
    - If the first sent test passes, the next test is `2`.
    - If a test fails and becomes a recheck, the recheck keeps the original
      test number relationship instead of advancing as a new original.
  - Audit and repair `Original`/`Recheck` mapping separately from bottom
    proctor `TEST NUMBER` mapping.

- [x] 0582B double text regression
  - Re-audit preview/export for duplicate writing after the latest screenshot.
  - Confirm registered fillers do not also receive generic table/field overlay
    writes.
  - Add a regression that fails if the same visible row token is written by
    both the registry filler and a fallback writer.

- [x] 0582B moisture PCF formatting/alignment
  - The `MOISTURE PCF` value in the upper table is visually offset compared to
    nearby values.
  - Compare field formatting against the original template and adjust only the
    field-writing/appearance path necessary to preserve original field
    alignment.

- [x] Projects missing until sync
  - Projects should load from local storage immediately after auth/session
    restoration.
  - The app should land on Projects unless an already-open project was
    backgrounded and restored.
  - Audit whether project list hydration is gated on remote sync completion,
    stale selected-project state, or provider initialization order.

- [x] 1126 report number cutoff
  - The report number field label/value is cut off in the 1126 entry wizard.
  - Fix layout on phone width without regressing tablet/desktop.

- [x] 1126 keyboard focus trap
  - While editing/typing in a 1126 section, tapping outside should dismiss the
    keyboard and allow normal interaction; users should not be forced to press
    keyboard `Done`.

- [x] Form standardization auto-advance
  - Add a reusable way for form workflows to move to the next tab/section
    automatically when the current tab/section becomes complete, without
    requiring a manual tap.
  - Apply where safe to the 1126/1174R standardized workflow surfaces.

- [x] 1126 section chevron reliability
  - Section cards in 1126 do not always close when tapping the chevron.
  - Audit the compact accordion state owner and ensure chevron toggles update
    the intended section deterministically.

- [x] 1126 export must never be blocked
  - Export should be available even when the form is incomplete or the
    signature state is not complete.
  - Repair any completeness gating that blocks preview/export/share.

- [x] 1126 signature save/state propagation
  - Signature does not reliably save back to the form state.
  - The UI can incorrectly believe the section/form is incomplete after a
    signature has been captured.
  - This also blocks attach-to-daily-entry and must be repaired through the
    real state/save path, not a UI-only bypass.

- [x] 1126 attach to daily entry
  - Attaching to a daily entry fails because signature state is broken.
  - Verify attach works after the signature state repair and does not require a
    completed form gate.

- [x] 1126 discard changes black screen
  - Discarding changes from the 1126 flow can black-screen.
  - Audit pop/redirect behavior and ensure discard returns to the correct
    prior route or project form list.

- [x] 1174R header performance and contractor cutoff
  - Scrolling with the first header card open performs poorly because the
    header is too large.
  - The contractor line header is cut off.
  - Stop the header section at the date line and move the remaining header
    fields into a new collapsible section.

- [x] 1174R row-entry standardization
  - Observable rows should not be displayed as five separate rows of cards.
  - Convert observable rows to a sequential test-like entry flow that appends
    to the next row.
  - Apply the same pattern to QA rows.
  - Apply the same pattern to Quantity rows.

- [x] 0582B item-of-work display/export codes
  - Once selected, item-of-work fields must display the item code on the form
    surface and PDF output, not the long descriptive name.
  - The picker/dropdown scroll list should keep the descriptive label so the
    inspector can identify the right item before selecting it.
  - Harden catalog normalization so stored long labels or combined
    code-description labels still export the official code.

- [x] Form workflow bubble-card spacing
  - Device screenshots show the compact phone pill/bubble rows nearly
    overlapping, especially the 0582B top status bubbles and the 1126 workflow
    section bubbles.
  - Widen shared compact pill gaps and internal padding instead of applying
    one-off screen-specific tweaks.
  - Verify on the Samsung device after rebuild that 0582B, 1126, and 1174R
    pill rows no longer appear cramped or overlapping.

- [x] Form field label headroom
  - Device screenshots show floating input labels sitting on or clipped into
    the field boxes after the pill-spacing repair.
  - Add headroom at shared design-system input wrappers so 0582B, 1126, 1174R,
    and Daily Entry form fields inherit the same fix.
  - Verify on the Samsung device after rebuild that field labels no longer
    visually collide with the input boxes.

- [x] Samsung warm-resume and background sync recovery after current rebuild
  - Re-run warm resume on the current installed real-auth APK, not a stale
    prior "final" build.
  - Re-run a >30 second background/resume pass so sync lifecycle recovery is
    exercised after the debounce window.
  - Verify the UI does not resume into sync-failed/connectivity-broken state.

- [x] 0582B Quick Test compact viewport fit
  - The entire Quick Test entry area should fit on a phone screen with the
    `SEND TO FORM` action visible without relying on device-specific hardcoded
    dimensions.
  - Tighten only through design-system breakpoints and spacing tokens.
  - Preserve adaptive behavior for medium/expanded layouts.

## Audit Notes

- Subagent delegation is active for the requested two-agent split.
- Workflow/UI audit returned concrete findings:
  - `ProjectListScreen` refresh appears to prioritize DNS/quick sync/remote
    fetch before local projects are usable.
  - Inspector project filters depend on local assignment IDs; while assignment
    loading is empty or pending, local projects can be hidden until sync
    completes.
  - `AppFormSection` expanded body has no top padding, which can clip the
    first floating text-field label and matches the 1126 report-number and
    1174R contractor-label cutoff.
  - `FormWorkflowShell` has no shell-level tap-out focus dismissal.
  - Workflow section selection only selects; tapping the already selected
    section does not collapse even though the chevron implies a toggle.
  - `AppTextField` already exposes `textInputAction` and `onFieldSubmitted`;
    this is the right seam for next-field/next-section auto-advance.
  - 1126 export validation is strict and can block export, which conflicts
    with the new "exports never block" rule.
  - 1126 signature save writes through the use case/repository, but
    UI/provider cache is not reliably reloaded after signing, so completion and
    Daily Entry attach can remain stale.
  - 1126 discard uses raw `Navigator.of(context).pop(result)` inside a
    `go_router` route; this is a plausible black-screen source.
  - 1174R first header section includes header fields plus water/beam/curing
    and intended air/slump fields, making it too heavy and consistent with the
    observed scroll jank.
  - 1174R currently seeds and renders all observation, QA, and quantity rows as
    full fixed row cards. This should become a sequential active-row entry flow
    while preserving existing PDF row mapping.
- 0582B local audit finding:
  - The current PDF filler treated the upper `ORIGINAL`/`RECHECK` columns as an
    `O`/`R` marker plus shared `test_number`.
  - This conflicted with the clarified product contract. `1Row*` must carry
    the original-test counter and `2Row*` must carry the recheck counter.
    Lower `ARow*` remains the proctor-test counter.
  - First repair has been applied in `mdot_0582b_pdf_filler.dart`; focused PDF
    mapping tests are green.
- PDF/0582B audit addendum:
  - `FormPdfActionOwner` now uses `generateFilledPreviewPdf(response)` for the
    read-only preview path; stale tests must stub/verify the preview method,
    not `generateFilledPdf(response)`.
  - Pure filler tests no longer show a path that writes upper `ORIGINAL` as
    `0`. If device output still shows `0`, treat it as stale build/data or an
    unverified controller-to-filler send-flow gap.
  - Add controller/send-flow coverage for first sent test `1`, passing second
    test `2`, failing first test then recheck `1`, and lower proctor `ARow*`
    remaining independent from upper `1Row*`/`2Row*`.
  - Add a hub draft de-duplication regression where saved rows and `hub_draft`
    contain equivalent data with different string/number formatting and must
    not append duplicate visible rows.
  - The highest-risk double-text path is AcroForm `/V` preservation plus
    viewer-regenerated appearances. Preview should flatten read-only copies;
    export must preserve fields without overlaying fallback text.
  - Add a 0582B preview/export matrix with unique values in `1Row1`, `2Row1`,
    `7Row1`, `8Row1`, `9Row1`, `FRow1`, `GRow1`, `HRow1`, chart standards,
    and operating standards; assert preview has zero fields and each token
    occurs once.
  - Add alignment/appearance assertions for `8Row1` alongside `7Row1` and
    `9Row1`.

## Verification Plan

- Focused code audit:
  - 0582B numbering/filler/writer/rendering/preview path.
  - 1126 workflow, signature state, export/attach/discard route path.
  - 1174R section composition and row-entry widgets/controllers.
  - project list provider/local-cache hydration path.
- Tests:
  - Add or update targeted unit/widget tests for every repairable logic/UI
    contract.
  - Run touched-file `flutter analyze`.
  - Run focused `flutter test` slices.
- Device:
  - Shut down stale Gradle/debug/test processes before building.
  - Build with `.env` and no mock-auth defines.
  - Install on Samsung `RFCNC0Y975L`.
  - Verify 0582B preview and export row numbering, double-text absence, and
    moisture PCF formatting.
  - Verify projects appear locally before manual sync.
  - Verify 1126 report field, keyboard dismissal, chevrons, export, signature,
    attach-to-daily-entry, and discard.
  - Verify 1174R header performance/contractor visibility and new row-entry
    flows for observable, QA, and Quantity rows.

## Implementation Status - 2026-04-10 19:34 ET

- Code/test status:
  - 0582B `1Row*`/`2Row*`/`ARow*` mapping repaired and covered by direct
    filler tests plus a `MdotHubController.sendTest()` flow regression.
  - 0582B saved-row plus `hub_draft` de-duplication repaired for equivalent
    numeric/string formatting and covered by a filler regression.
  - 0582B F/G/H proctor calculations remain covered by the shipped-template
    mapping tests.
  - Preview path test updated to verify `generateFilledPreviewPdf(response)`;
    Syncfusion preview timer cleanup added to widget tests.
  - Project list refresh now loads local projects and local assignments before
    DNS/quick sync/remote fetch; inspector filters do not hide local projects
    while assignments are not loaded.
  - 1126 export validation policy no longer blocks export; export-entry test
    now proves unsigned 1126 attached to an IDR bundle still exports.
  - 1126 focus dismissal, section toggle behavior, discard pop, attach copy,
    and post-signature response reload changes are in the touched codepath.
  - 1174R header split and sequential observation/QA/quantity row workflow are
    present in the touched codepath and covered by the existing 1174R screen
    test slice.
  - Shared `AppFormSection` top padding and shared `AppButton` text overflow
    fixes are in place to address cutoff/overflow regressions.
  - Provider public APIs promoted for `ProjectProvider`, `SyncProvider`, and
    `AuthProvider.refreshUserProfile()` so tests and widgets exercise real
    instance contracts instead of unmockable extension members.
- Verification completed:
  - `flutter analyze` on touched implementation/test files: green.
  - Focused combined suite: `146` tests passed.
- Remaining gate:
  - Build/install real-auth Samsung APK with no `MOCK_AUTH` define.
  - Complete device verification for all TODOs before marking checkbox items
    done.

## Implementation Status - 2026-04-10 19:51 ET

- Added the 0582B item-of-work code/display requirement to this tracker.
- `AppDropdown` now supports separate selected-item rendering so pickers can
  keep descriptive menu labels while the closed field shows a short code.
- The 0582B item-of-work picker now shows long descriptive labels in the scroll
  list and only the selected code in the form field.
- The 0582B item catalog now normalizes combined picker labels and known
  legacy long labels such as `Aggregate base` to official codes before preview
  or export. Unknown long labels no longer pass through to the PDF field.
- Focused verification:
  - `flutter analyze` on touched dropdown/catalog/0582B files and tests:
    green.
  - `flutter test test/core/design_system/molecules/app_dropdown_test.dart
    test/features/forms/data/registries/mdot_0582b_item_of_work_catalog_test.dart
    test/features/forms/data/pdf/mdot_0582b_pdf_filler_test.dart`: green,
    `18` tests passed.
- Real-device verification on Samsung `RFCNC0Y975L`, real-auth build with
  `.env` and no `MOCK_AUTH` define:
  - Picker menu shows descriptive labels such as `AB · Aggregate Base - used
    under HMA Pavement`.
  - Selected item field shows `AB`, not the long label.
  - Preview for the saved legacy row changed from leaking `Aggregate base` to
    showing `AB`.
  - Exported PDF pulled from the app cache preserves AcroForm fields and has
    `16Row1=AB`, `1Row1=1`, `FRow1=2594`, `GRow1=5.72`, `HRow1=130.2`, with
    `270` fields present.
  - Artifacts saved under
    `.codex/artifacts/2026-04-10/item_code_device/`.

## Implementation Status - 2026-04-10 20:05 ET

- Added the form workflow bubble-card spacing regression to this tracker.
- Shared pill/nav implementation status:
  - `AppFormSectionNav` now uses wider density-aware gaps and padding, no
    trailing gap, a 40 px minimum pill height, rounded token radii, and
    one-line ellipsized labels.
  - `StatusPillBar` now matches the wider shared spacing contract for 0582B
    top status bubbles.
- Verification completed:
  - `flutter analyze lib/core/design_system/organisms/app_form_section_nav.dart
    lib/features/forms/presentation/widgets/status_pill_bar.dart
    test/features/forms/presentation/widgets/form_shared_widgets_test.dart`:
    green.
  - `flutter test test/features/forms/presentation/widgets/form_shared_widgets_test.dart`:
    green, `4` tests passed.
  - Rebuilt with `flutter build apk --debug --dart-define-from-file=.env`;
    `.env` had no `MOCK_AUTH` entry.
  - Installed the rebuilt APK on Samsung `RFCNC0Y975L`.
  - Captured post-fix spacing artifacts:
    - `.codex/artifacts/2026-04-10/item_code_device/32_spacing_0582b_after_fix.png`
    - `.codex/artifacts/2026-04-10/item_code_device/35_spacing_1126_after_fix.png`
    - `.codex/artifacts/2026-04-10/item_code_device/37_spacing_1174_after_fix.png`

## Implementation Status - 2026-04-10 20:18 ET

- Added the form field label headroom regression to this tracker.
- Shared input implementation status:
  - `AppTextField`, `AppDropdown`, and `AppDatePicker` now reserve
    density-aware top headroom when rendering labeled fields.
- Focused verification:
  - `flutter analyze lib/core/design_system/molecules/app_text_field.dart
    lib/core/design_system/molecules/app_dropdown.dart
    lib/core/design_system/molecules/app_date_picker.dart
    test/core/design_system/app_text_field_test.dart
    test/core/design_system/molecules/app_dropdown_test.dart`: green.
  - `flutter test test/core/design_system/app_text_field_test.dart
    test/core/design_system/molecules/app_dropdown_test.dart`: green, `10`
    tests passed.
- Remaining verification gate:
  - Complete. Rebuilt/reinstalled the real-auth Samsung APK with no
    `MOCK_AUTH` define and captured updated field-label screenshots:
    - `.codex/artifacts/2026-04-10/item_code_device/41_label_headroom_0582b.png`
    - `.codex/artifacts/2026-04-10/item_code_device/43_label_headroom_1126.png`
    - `.codex/artifacts/2026-04-10/item_code_device/44_label_headroom_1174.png`

## Implementation Status - 2026-04-10 20:20 ET

- Closed 0582B original/recheck numbering after focused and live-device
  verification.
- Focused verification:
  - `flutter analyze lib/features/forms/data/pdf/mdot_0582b_pdf_filler.dart
    test/features/forms/data/pdf/mdot_0582b_pdf_filler_test.dart
    test/features/forms/presentation/controllers/mdot_hub_controller_test.dart`:
    green.
  - `flutter test test/features/forms/data/pdf/mdot_0582b_pdf_filler_test.dart
    test/features/forms/presentation/controllers/mdot_hub_controller_test.dart`:
    green, `13` tests passed.
- Real-auth Samsung verification:
  - Preview artifact `.codex/artifacts/2026-04-10/item_code_device/48_numbering_0582b_preview.png`
    shows the upper Original column starting at `1`.
  - Export artifact `.codex/artifacts/2026-04-10/item_code_device/export_MDOT_0582B_2026-04-10_dbaa1b66_run_as.pdf`
    has `1Row1=1`, `1Row2=2`, and `ARow1=1`.
  - Live recheck lane was exercised by sending a failing original Test #2,
    then a passing recheck. The UI advanced from `Test #2 · Recheck #1` to
    `Test #3`.
  - Recheck export artifact
    `.codex/artifacts/2026-04-10/item_code_device/export_MDOT_0582B_2026-04-10_dbaa1b66_recheck_run_as.pdf`
    has `1Row3=None`, `2Row3=1`, `7Row3=140.0`, `9Row3=0.0`,
    `11Row3=103.0`, and `field_count=270`.

## Implementation Status - 2026-04-10 20:25 ET

- Closed 0582B double-text regression after focused matrix and live-device
  verification.
- Verification:
  - `flutter test test/features/forms/services/form_export_mapping_matrix_test.dart`:
    green, `19` tests passed.
  - The matrix asserts preview PDFs flatten form fields to `0` for IDR,
    MDOT 0582B, MDOT 1126, and MDOT 1174R while exports preserve editable
    AcroForm fields.
  - The matrix also asserts the 0582B preview contains key calculated values
    once and that 0582B export does not inject generic table summaries into
    remarks.
  - Live artifact
    `.codex/artifacts/2026-04-10/item_code_device/63_double_text_0582b_preview_after_recheck.png`
    shows the current Samsung preview after original/recheck sends without the
    earlier double-written field appearance.

## Implementation Status - 2026-04-10 20:28 ET

- Closed 0582B moisture PCF formatting/alignment.
- Added explicit regression coverage that `8Row1` moisture PCF preserves the
  shipped template text alignment next to `7Row1` wet density and `9Row1`
  moisture percent.
- Verification:
  - `flutter test test/features/forms/services/form_export_mapping_matrix_test.dart --plain-name "0582B export preserves the template text alignment for mapped fields"`:
    green, `1` test passed.
  - `flutter analyze test/features/forms/services/form_export_mapping_matrix_test.dart`:
    green.
  - Live export artifact
    `.codex/artifacts/2026-04-10/item_code_device/export_MDOT_0582B_2026-04-10_dbaa1b66_recheck_run_as.pdf`
    has `8Row3=140.0` in the recheck row.
  - Live preview artifact
    `.codex/artifacts/2026-04-10/item_code_device/63_double_text_0582b_preview_after_recheck.png`
    shows moisture PCF populated in the expected printed column.

## Implementation Status - 2026-04-10 20:31 ET

- Closed projects-local-hydration regression.
- Verification:
  - `flutter analyze lib/features/projects/presentation/providers/project_provider.dart
    lib/features/projects/presentation/widgets/project_card.dart
    test/features/projects/presentation/screens/project_list_screen_test.dart`:
    green.
  - `flutter test test/features/projects/presentation/screens/project_list_screen_test.dart`:
    green, `31` tests passed.
  - The widget suite verifies screen-open refresh loads local projects before
    DNS reachability, quick sync, and remote fetch.
  - Live real-auth Samsung launch artifact
    `.codex/artifacts/2026-04-10/item_code_device/39_label_headroom_settled.png`
    shows the app landing on Projects with `Live 0582B Verification` available
    locally before manual sync.

## Implementation Status - 2026-04-10 20:33 ET

- Reopened the shared bubble/header overflow gate after fresh user feedback.
- Strengthened the shared headroom fix:
  - `AppTextField`, `AppDropdown`, and `AppDatePicker` now reserve at least
    phone-safe floating-label headroom (`spacing.sm + 8`) instead of the prior
    compact `xs + 4` padding.
  - `AppFormSection` expanded bodies now use density-aware top/bottom padding,
    so the first field in a section is not jammed against the card header.
- Focused verification:
  - `flutter analyze lib/core/design_system/molecules/app_text_field.dart
    lib/core/design_system/molecules/app_dropdown.dart
    lib/core/design_system/molecules/app_date_picker.dart
    lib/core/design_system/organisms/app_form_section.dart
    test/core/design_system/app_text_field_test.dart
    test/core/design_system/molecules/app_dropdown_test.dart
    test/features/forms/presentation/widgets/form_shared_widgets_test.dart`:
    green.
  - `flutter test test/core/design_system/app_text_field_test.dart
    test/core/design_system/molecules/app_dropdown_test.dart
    test/features/forms/presentation/widgets/form_shared_widgets_test.dart`:
    green, `15` tests passed.
- Real-auth Samsung verification:
  - Rebuilt with `flutter build apk --debug --dart-define-from-file=.env`;
    `.env` still has no `MOCK_AUTH` entry.
  - Installed on Samsung `RFCNC0Y975L`.
  - Fresh artifacts show the stronger spacing on current APK:
    - `.codex/artifacts/2026-04-10/item_code_device/81_1126_after_stronger_headroom.png`
    - `.codex/artifacts/2026-04-10/item_code_device/82_1126_report_number_after_headroom.png`
    - `.codex/artifacts/2026-04-10/item_code_device/84_1174_after_stronger_headroom.png`
- Closed 1126 keyboard focus trap:
  - Added a focused 1126 widget regression proving tap-out dismisses the active
    text input without requiring keyboard `Done`.
  - `flutter analyze test/features/forms/presentation/screens/mdot_1126_form_screen_test.dart`:
    green.
  - `flutter test test/features/forms/presentation/screens/mdot_1126_form_screen_test.dart --plain-name "tap outside an active 1126 text field dismisses keyboard"`:
    green, `1` test passed.

## Implementation Status - 2026-04-10 20:36 ET

- Closed form auto-advance:
  - Verified both 1126 and 1174R opt into `FormWorkflowShell(autoAdvanceOnComplete: true)`.
  - Added shared shell regression proving a selected section that transitions
    to complete automatically selects the next incomplete section.
  - `flutter analyze test/features/forms/presentation/widgets/form_shared_widgets_test.dart
    lib/features/forms/presentation/widgets/form_workflow_shell.dart
    lib/features/forms/presentation/screens/mdot_1126_form_screen.dart
    lib/features/forms/presentation/screens/mdot_1174r_form_screen.dart`:
    green.
  - `flutter test test/features/forms/presentation/widgets/form_shared_widgets_test.dart --plain-name "FormWorkflowShell auto-advances to the next incomplete section"`:
    green, `1` test passed.
- Closed 1126 section chevron reliability:
  - Added 1126 screen regression proving tapping the active section header
    collapses to the summary state.
  - `flutter test test/features/forms/presentation/screens/mdot_1126_form_screen_test.dart --plain-name "tapping the active 1126 section header collapses it"`:
    green, `1` test passed.
- Closed 1126 export/signature/attach/discard lane:
  - Corrected stale export-use-case comment to match the current non-blocking
    export policy.
  - Added/ran focused tests proving unsigned 1126 standalone export and
    unsigned attached 1126 IDR-bundle export are not blocked by signature
    validation.
  - Added signature-step regression proving signing reloads provider response
    state before advancing to attach.
  - Added attachment-owner regression proving an unsigned 1126 can attach to a
    daily entry without a signature audit id.
  - Added router-level discard regression proving dirty 1126 discard routes to
    the `forms` fallback instead of leaving an empty stack / black screen.
- Closed 1174R header and row-entry lane:
  - Moved `Maximum time`, `Structure number`, `Weather A.M.`, and
    `Weather P.M.` out of the 1174R Header section and into the Placement
    details section.
  - Header completion status now only counts top header/date fields; placement
    status owns the lower detail fields.
  - Air/Slump, QA, and Quantity row groups remain sequential single-active-row
    flows for blank initial data.
  - `flutter analyze lib/features/forms/presentation/screens/mdot_1174r_sections.dart
    lib/features/forms/presentation/screens/mdot_1174r_form_screen.dart
    test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart`:
    green.
  - `flutter test test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart`:
    green, `4` tests passed.
- Remaining gate:
  - Rebuild/reinstall real-auth Samsung APK after the 1174R app-code changes.
  - Re-verify 1126 and 1174R live-device flows from the rebuilt APK.

## Implementation Status - 2026-04-10 20:45 ET

- Final focused local gate after the 1174R code changes:
  - `flutter test test/core/design_system/app_text_field_test.dart
    test/core/design_system/molecules/app_dropdown_test.dart
    test/features/forms/presentation/widgets/form_shared_widgets_test.dart
    test/features/forms/presentation/screens/mdot_1126_form_screen_test.dart
    test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart
    test/features/forms/presentation/support/form_entry_attachment_owner_test.dart
    test/features/entries/domain/usecases/export_entry_use_case_test.dart`:
    green, `39` tests passed.
  - Touched-file `flutter analyze` across the same implementation/test areas:
    green.
- Rebuilt/reinstalled the current real-auth Samsung APK:
  - `MOCK_AUTH` was not present in `.env`.
  - `.\android\gradlew.bat --stop` was run before build.
  - `flutter build apk --debug --dart-define-from-file=.env`: green.
  - `adb -s RFCNC0Y975L install -r build\app\outputs\flutter-apk\app-debug.apk`:
    success.
- Current-build Samsung visual verification:
  - 1126 report-number/label headroom artifact:
    `.codex/artifacts/2026-04-10/item_code_device/90_post_rebuild_1126_report_number.png`.
  - 1174R header split artifact:
    `.codex/artifacts/2026-04-10/item_code_device/93_post_rebuild_1174_header_split.png`.
  - 1174R moved placement-detail fields artifact:
    `.codex/artifacts/2026-04-10/item_code_device/96_post_rebuild_1174_placement_top_max_time.png`.
  - 1174R sequential Air/Slump row artifact:
    `.codex/artifacts/2026-04-10/item_code_device/97_post_rebuild_1174_air_row.png`.
- Current-build Samsung resume/sync verification:
  - Warm resume evidence:
    `.codex/artifacts/2026-04-10/item_code_device/98_post_rebuild_warm_resume.png`,
    `.codex/artifacts/2026-04-10/item_code_device/98_post_rebuild_warm_resume.xml`,
    `.codex/artifacts/2026-04-10/item_code_device/98_post_rebuild_warm_resume_am_start.txt`,
    and
    `.codex/artifacts/2026-04-10/item_code_device/98_post_rebuild_warm_resume_log_excerpt.txt`.
  - Warm resume result: `LaunchState: HOT`, `TotalTime=78ms`,
    `WaitTime=86ms`, PowerShell wall time `198ms`, and the UI remained on
    `MDOT 1174R` without sync-failed/connectivity-broken text.
  - >30 second background/resume evidence:
    `.codex/artifacts/2026-04-10/item_code_device/99_post_rebuild_background_resume.png`,
    `.codex/artifacts/2026-04-10/item_code_device/99_post_rebuild_background_resume.xml`,
    `.codex/artifacts/2026-04-10/item_code_device/99_post_rebuild_background_resume_am_start.txt`,
    `.codex/artifacts/2026-04-10/item_code_device/99_post_rebuild_background_resume_log_excerpt.txt`,
    and
    `.codex/artifacts/2026-04-10/item_code_device/99_post_rebuild_background_resume_log_excerpt_2.txt`.
  - Background resume result: `LaunchState: HOT`, `TotalTime=154ms`,
    `WaitTime=156ms`, PowerShell wall time `301ms`; logs showed
    `Reachability check passed (HTTP 401)`, `quick push complete: 1 pushed,
    0 errors`, `quick pull complete: 0 pulled, 0 errors`, and
    `Sync cycle (quick): pushed=1 pulled=0 errors=0 conflicts=0`.


## Implementation Status - 2026-04-10 21:00 ET

- Closed PDF preview left-inset mismatch reported on the 1126 inches / 1174R curing-compound areas:
  - Confirmed exports were already preserving the original AcroForm field geometry and native renderer inset.
  - Confirmed read-only flattened previews were losing Syncfusion's native 2 pt left inset for left-aligned AcroForm text fields.
  - Updated `PdfPreviewTransformer` to apply a preview-only 2 pt left-origin inset before flattening, without reducing field width and without changing exported AcroForm fields.
  - Added `test/features/pdf/services/pdf_preview_transformer_test.dart` to cover the preview-only native left inset.
- Verification:
  - `flutter analyze lib/features/pdf/services/pdf_preview_transformer.dart test/features/pdf/services/pdf_preview_transformer_test.dart`: green.
  - `flutter test test/features/pdf/services/pdf_preview_transformer_test.dart`: green.
  - `flutter test test/features/forms/services/form_export_mapping_matrix_test.dart`: green, `19` tests passed.
  - `flutter test .codex/scripts/generate_pdf_fidelity_artifacts_test.dart`: green.
  - Regenerated PDF fidelity artifacts under `.codex/artifacts/2026-04-10/pdf_fidelity_verification/`.
  - Real-template coordinate sanity check after regeneration:
    - 1174R generated export `Text9`/curing value left x: `518.654`.
    - 1174R generated preview curing value left x: `518.650`.
    - 1126 generated export last-precipitation inches summary left x: `25.720`.
    - 1126 generated preview last-precipitation inches summary left x: `25.720`.
  - Visual crop artifacts:
    - `.codex/artifacts/2026-04-10/pdf_spacing_question/1174_generated_preview_after_inset_curing.png`
    - `.codex/artifacts/2026-04-10/pdf_spacing_question/1126_generated_preview_after_inset_inches.png`
  - Real-auth Samsung build/install gate:
    - Verified `.env` has no `MOCK_AUTH`.
    - Ran `.\android\gradlew.bat --stop`.
    - Ran `flutter build apk --debug --dart-define-from-file=.env`: green.
    - Ran `adb -s RFCNC0Y975L install -r build\app\outputs\flutter-apk\app-debug.apk`: success.
    - Launched `com.fieldguideapp.inspector` on Samsung `RFCNC0Y975L`; settled on the real project dashboard with no mock-auth build define.
    - Device evidence:
      - `.codex/artifacts/2026-04-10/pdf_spacing_question/100_pdf_preview_inset_post_install.png`
      - `.codex/artifacts/2026-04-10/pdf_spacing_question/101_pdf_preview_inset_launch.png`
      - `.codex/artifacts/2026-04-10/pdf_spacing_question/102_pdf_preview_inset_launch_settled.png`

## Implementation Status - 2026-04-10 21:20 ET

- Reopened and repaired the 1174R row-entry/performance lane after follow-up
  feedback that sections C/D/E still lacked explicit add-row controls and
  1174R scrolling remained poor.
- 1174R row-entry implementation status:
  - Air/Slump, QA, and Quantity repeated row sections now expose explicit
    buttons to add the next printed row: `Add observation row`, `Add QA row`,
    and `Add quantity row`.
  - Row rendering is bounded to the inspector-opened printed rows instead of
    relying on the seeded blank-row heuristic.
  - Edits persist only visible/opened printed rows, preventing seeded trailing
    blanks from driving unnecessary UI and save churn.
- Shared form workflow performance guard:
  - `AppFormSection` and legacy `FormAccordion` no longer use
    `AnimatedCrossFade`; collapsed section bodies now use lazy visible-body
    rendering via `AnimatedSize`.
  - Added custom lint rule
    `no_animated_crossfade_in_form_workflows` under
    `fg_lint_packages/field_guide_lints` so standardized form workflow
    surfaces cannot reintroduce the hidden-heavy-body pattern.
- Focused verification:
  - `flutter analyze lib/features/forms/presentation/screens/mdot_1174r_sections.dart
    lib/core/design_system/organisms/app_form_section.dart
    lib/features/forms/presentation/widgets/form_accordion.dart
    lib/shared/testing_keys/toolbox_keys.dart
    lib/shared/testing_keys/testing_keys.dart
    test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart
    test/features/forms/presentation/widgets/form_shared_widgets_test.dart`:
    green.
  - `flutter test test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart
    test/features/forms/presentation/widgets/form_shared_widgets_test.dart`:
    green, `12` tests passed.
  - Lint-package focused analyze/test for
    `no_animated_crossfade_in_form_workflows`: green.
  - `dart run custom_lint` currently reports only six existing unrelated
    warnings; this change set adds no custom-lint violations and the new
    `AnimatedCrossFade` rule does not report against the repaired form
    workflow files.
- Remaining gate:
  - Complete remaining live-device spot check for 1174R QA and Quantity row
    add buttons from the rebuilt APK.
  - The rebuilt APK is already installed on Samsung `RFCNC0Y975L` with no
    `MOCK_AUTH` define; Air/Slump live row-add proof is complete.

## Implementation Status - 2026-04-10 21:32 ET

- Real-auth Samsung build/install gate after the 1174R row-add/lint repair:
  - Verified `.env` had no `MOCK_AUTH` entry.
  - Ran `.\android\gradlew.bat --stop`.
  - `flutter build apk --debug --dart-define-from-file=.env`: green.
  - `adb -s RFCNC0Y975L install -r build\app\outputs\flutter-apk\app-debug.apk`:
    success.
- Live-device verification completed:
  - App launched into the real project list with `Live 0582B Verification`
    locally available.
  - Opened the real project, Toolbox, Forms, and started a real 1174R workflow
    on the installed APK.
  - Verified the 1174R Air/Slump section exposes `Add observation row` and
    tapping it opens `Observation Row 2`.
  - Device evidence saved under
    `.codex/artifacts/2026-04-10/1174_row_add_performance/`, including:
    - `01_post_install_launch.png/xml`
    - `05_after_1174_start.png/xml`
    - `08_air_slump_add_button_lower.png/xml`
    - `09_air_slump_after_add_tap.png/xml`
    - `11_scroll_after_air_rows.png/xml`
- Remaining gate:
  - QA and Quantity add-button live-device verification is still pending.
    Focused widget coverage for those buttons is green, but I have not yet
    captured device proof for those two sections.

## Implementation Status - 2026-04-10 22:05 ET

- Corrected the 1174R row-entry interpretation after user feedback:
  - The repeated-row CTA is not supposed to reveal more printed-row UI cards.
  - The wizard is supposed to be a compact data-entry composer that writes the
    current entry into the next fixed PDF row slot, matching the 0582B/SESC
    workflow intent.
- Current implementation shape:
  - `FormRepeatedRowComposer` is the shared form-wizard row composer.
  - 1174R Air/Slump, QA, and Quantity sections use a single `Current entry`
    composer and `Add ... row` CTA.
  - The CTA writes into the first blank row inside the fixed PDF-backed list;
    seeded blank slots are replaced in place and row lists stay capped at the
    printed PDF capacity.
  - The composer clears after successful save, tracks the last printed row
    written, disables when all printed rows are used, and lays out as one
    column on compact screens / two columns at medium+ widths without using
    dense 3-4 column packing.
  - Commits patch the latest response from `InspectorFormProvider` before
    writing, so sequential commits across Air/Slump, QA, and Quantity do not
    overwrite each other with stale widget response data.
- Focused verification:
  - `flutter analyze lib/features/forms/presentation/screens/mdot_1174r_sections.dart
    lib/features/forms/presentation/widgets/form_repeated_row_composer.dart
    lib/shared/testing_keys/toolbox_keys.dart
    lib/shared/testing_keys/testing_keys.dart
    test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart`:
    green.
  - `flutter test test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart`:
    green, `7` tests passed.
- Remaining gate:
  - Rebuild/install a real-auth APK and recapture live-device 1174R evidence
    for the corrected fixed-slot composer behavior. Do not use `MOCK_AUTH`.

## Implementation Status - 2026-04-10 22:24 ET

- Real-auth build/install after corrected 1174R composer workflow:
  - Confirmed `.env` contains no `MOCK_AUTH` entry.
  - Confirmed Samsung device `RFCNC0Y975L` is connected.
  - `flutter build apk --debug --dart-define-from-file=.env`: green.
  - `adb -s RFCNC0Y975L install -r build\app\outputs\flutter-apk\app-debug.apk`:
    success.
- Live-device spot check:
  - Launched the installed app into the real `Live 0582B Verification` project
    context, not mock auth.
  - Navigated Dashboard -> Toolbox -> Forms -> MDOT 1174R.
  - Captured the corrected 1174R Air/Slump UI showing `Current entry`,
    `Rows used: 0 of 5`, left/right observation composer copy, and no
    `Observation Row 1` / `Observation Row 2` expanded-row cards.
  - Device evidence saved under
    `.codex/artifacts/2026-04-10/1174_fixed_slot_composer/`:
    `01_post_install_launch.*` through `06_air_slump_add_button.*`.
- Remaining gate:
  - The device proof is a composer-shape proof, not a full on-device append
    proof. QA/Quantity fixed-slot append still needs live-device entry proof
    in a follow-up pass if required.

## Implementation Status - 2026-04-10 22:45 ET

- Current 1174R/1126 copy and compact-entry follow-up:
  - `FormRepeatedRowComposer` now labels the active editor as `Next row entry`
    instead of `Current entry`.
  - The repeated-row composer now enables two-column field layout at compact
    phone widths when the available row width is at least `340dp`, while still
    falling back to one column on narrower surfaces.
  - 1174R Air/Slump, QA, and Quantity instructions now explicitly say to fill
    one row and tap the matching `Add ... row` button to place it in the next
    blank table row on the form.
  - 1174R quantity label now uses the requested `Measured sq/cu yards` copy.
  - 1174R and 1126 workflow headers no longer use ambiguous
    `workflow-only` / `attachment tools` language.
- Verification gate:
  - Focused stale-copy search over `lib/features/forms`: green; no
    production `workflow-only`, old attachment-tool copy, `Current entry`, or
    old measured-yards label remains.
  - `flutter analyze lib/features/forms/presentation/widgets/form_repeated_row_composer.dart
    lib/features/forms/presentation/screens/mdot_1174r_sections.dart
    lib/features/forms/presentation/screens/mdot_1174r_form_screen.dart
    lib/features/forms/presentation/screens/mdot_1126_form_screen.dart
    test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart`:
    green.
  - `flutter test test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart`:
    green, `7` tests passed.
  - Any new device proof must come from a rebuilt real-auth APK with no
    `MOCK_AUTH`.

## Implementation Status - 2026-04-10 23:20 ET

- 0582B Quick Test compact viewport repair:
  - `HubQuickTestContent` now uses `AppBreakpoint.of(context).isCompact` plus
    `FieldGuideSpacing` tokens to reduce compact-only vertical density.
  - Compact Quick Test now shows one condensed proctor/test line, collapses the
    item-of-work explanation into a two-line hint, pairs `Moisture PCF` with
    `Station`, and keeps the old roomier description card on non-compact
    layouts.
  - Text fields use compact `AppTextField` density and token-based compact
    content padding; no device-specific screen dimensions were added to
    production code.
- 1174 copy follow-up:
  - The 1174 workflow header is now `1174 Form Filler` instead of
    `Concrete Placement Workflow`.
- Focused verification:
  - `flutter analyze lib/features/forms/presentation/widgets/hub_quick_test_content.dart
    lib/features/forms/presentation/screens/mdot_1174r_form_screen.dart
    test/features/forms/presentation/widgets/hub_quick_test_content_test.dart
    test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart`:
    green.
  - `flutter test test/features/forms/presentation/widgets/hub_quick_test_content_test.dart
    test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart`:
    green, `8` tests passed.
- Remaining gate:
  - Rebuild/install the real-auth APK and capture Samsung evidence that the
    0582B Quick Test screen includes `SEND TO FORM` in the visible section.

## Implementation Status - 2026-04-10 23:35 ET

- 0582B Quick Test compact spacing follow-up:
  - Compact Quick Test now uses a smaller token-based gutter between adjacent
    entry controls so the text-entry boxes reclaim unused horizontal space.
  - `AppTextField` and `AppDropdown` now accept optional `labelTopPadding` /
    `contentPadding` overrides, preserving the default shared design-system
    behavior while allowing dense form-entry sections to reduce only their
    compact floating-label headroom.
  - The 0582B selectors and text entries use the compact overrides; no
    device-specific dimensions or `MOCK_AUTH` paths were introduced.
- Focused verification:
  - `.env` contains no `MOCK_AUTH` entry.
  - `flutter analyze lib/core/design_system/molecules/app_text_field.dart
    lib/core/design_system/molecules/app_dropdown.dart
    lib/features/forms/presentation/widgets/hub_quick_test_content.dart
    test/features/forms/presentation/widgets/hub_quick_test_content_test.dart
    test/features/forms/widgets/hub_proctor_content_test.dart`: green.
  - `flutter test test/features/forms/presentation/widgets/hub_quick_test_content_test.dart
    test/features/forms/widgets/hub_proctor_content_test.dart`: green, `4`
    tests passed.
  - `flutter analyze lib test/features/forms`: green.
  - Full `flutter analyze` still fails on vendored `third_party` patched package
    examples/tests that are outside this compact-layout change.
- Real-auth Samsung status:
  - Stopped Gradle daemons, rebuilt with
    `flutter build apk --debug --dart-define-from-file=.env`, and installed on
    Samsung `RFCNC0Y975L`; install succeeded.
  - Captured evidence under
    `.codex/artifacts/2026-04-10/0582b_compact_entry_spacing/`.
  - The installed app launched to Projects with `Live 0582B Verification`
    locally available and opened a saved 0582B draft, but the reached Quick
    Test section was locked with `Requires proctor before test entry`; compact
    unlocked Quick Test visual proof remains pending.
