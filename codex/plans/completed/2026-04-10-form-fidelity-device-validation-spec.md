# Form Fidelity, Device Validation, And Final Re-Verification Spec

## Summary

This spec is the controlling closure plan for the remaining PDF, preview,
routing-through-form-flow, and Samsung validation defects. Implementation is
not complete until all required forms are repaired, verified on-device in both
preview and export flows, independently reviewed after the first verification
pass, and then re-verified end-to-end a second time. The required forms are:

- 0582B
- 1174R
- SESC 1126
- Daily Entries / IDR

## Implementation Changes

- **0582B standards contract**
  - Move standards ownership from Quick Test to Proctor in both the hub
    workflow and standalone form viewer.
  - Replace the current chart standards shape with a two-box range shape:
    - `chart_standards.density_first`
    - `chart_standards.density_second`
    - `chart_standards.moisture_first`
    - `chart_standards.moisture_second`
  - Keep operating standards as single values:
    - `operating_standards.density`
    - `operating_standards.moisture`
  - Maintain backward-compatible hydration for older drafts by loading legacy
    single chart values into the first chart slot and leaving the second blank.
  - Seed new drafts with the new shape and ensure save/update/export paths all
    use the same contract.

- **0582B field mapping**
  - Lock the mapping to the real template contract:
    - `DENSITYRow1` = chart density first box
    - `DENSITYRow2` = chart density second box
    - `MOISTURERow1` = chart moisture first box
    - `MOISTURERow2` = chart moisture second box
    - `DENSITYRow1_2` = operating density
    - `MOISTURERow1_2` = operating moisture
  - Keep F/G/H sourced from the proper proctor/test computation path.
  - Verify that remarks remain isolated and no standards/test data leaks into
    remarks.
  - Treat visible test/proctor row numbers as one-based. Legacy or stale
    draft values of `0`, blank, or invalid row numbers must fall back to the
    one-based PDF row index instead of writing `0` into the form.
  - New 0582B responses must not seed blank `test_rows` or `proctor_rows`.
    Existing blank seed rows must be ignored by parsed row views, PDF mapping,
    and test-number derivation so they cannot create a phantom first row or
    push real values down to row 2.
  - 0582B export must flush the same current draft snapshot used by preview
    before calling the shared export pipeline, so draft-only B-H/proctor values
    cannot appear in preview but disappear from the exported AcroForm PDF.

- **Read-only preview contract**
  - Split preview generation from export generation.
  - Preview must use a filled, flattened copy of the PDF so `SfPdfViewer`
    remains pan/zoom capable but cannot expose live editable AcroForm widgets
    or render a second form-field text layer over the page.
  - Export must remain AcroForm-preserving unless a specific form's existing
    export contract already requires flattening for another reason.
  - Apply the same preview contract to the form preview flow and the daily
    entry / IDR preview flow so all validated forms behave consistently.

- **Cross-form fidelity preservation**
  - Preserve original AcroForm appearance behavior instead of drawing
    substitute overlay text.
  - Protect field placement/alignment/justification contract on 0582B, 1174R,
    1126, and IDR.
  - Use the original provided/debug PDFs as the visual and structural baseline
    where available, and the shipped template assets as the fallback baseline
    where no external original was provided.
  - Save durable fidelity artifacts for all forms so later regressions can be
    checked without rebuilding the baseline from scratch.

- **Live Samsung flows**
  - Use only the real-auth build and real backend session.
  - No mock auth, no test-only runtime bypasses, no "verification" on stale or
    non-production auth states.
  - Re-run the Samsung sync/background-resume lanes after the PDF work lands
    because the app must close with both form fidelity and device-state
    recovery verified.

## Verification Gates

- **Gate 1: code/test green for each slice**
  - For each implementation slice, run touched-file `flutter analyze`.
  - Run targeted tests covering the slice.
  - Do not stack multiple unverified changes and defer testing until the end.

- **Gate 2: artifact-level proof for each form**
  - For each required form, generate and save:
    - baseline source/original template reference
    - fully filled reference PDF
    - generated preview artifact
    - generated export artifact
    - rendered page images for comparison
    - manifest of expected field values
  - For each form, validate:
    - field values are correct
    - values land in the correct AcroForm fields
    - appearance/placement contract is preserved
    - preview output and export output agree

- **Gate 3: live-device proof for each form**
  - On the Samsung real-auth build, verify each form in both surfaces:
    - preview
    - exported PDF reopened after export
  - For each form, confirm:
    - preview is read-only
    - pan/zoom still works
    - all entered values appear in the correct places
    - formatting is not degraded relative to the baseline
    - export matches preview
    - no stray values appear in unrelated fields
  - Save evidence for each form:
    - preview screenshot
    - export/reopen screenshot or equivalent rendered proof
    - any failure artifact before repair if reproduced

- **Gate 4: post-verification implementation review**
  - After the first full verification pass is green, perform a deliberate
    review pass over the implementation itself.
  - Review focus:
    - field mapping correctness
    - backward-compat draft hydration
    - preview/export separation
    - no accidental flattening of export path
    - no performance regressions introduced by preview generation
    - no role/flow regressions around navigation into forms
  - Treat this as a code review mindset, not a retest only.

- **Gate 5: final full re-verification**
  - After the review pass, run one more full end-to-end verification of all
    required forms.
  - This second pass must again cover both preview and reopened export on the
    real Samsung device.
  - No form is considered closed until it has passed both the first
    verification pass and the final re-verification pass.

## Per-Form Live Test Scenarios

- **0582B**
  - Enter representative header, proctor, and test data.
  - Enter standards in Proctor:
    - chart density first box
    - chart density second box
    - chart moisture first box
    - chart moisture second box
    - operating density
    - operating moisture
  - Enter the required F/G/H-driving values:
    - B=`8`
    - C=`.0439`
    - D=`4600`
    - E=`2006`
  - Verify in preview:
    - first visible test/proctor row numbers start at 1, never 0
    - all six standards values are in the correct boxes
    - F/G/H populate correctly
    - preview is flattened/read-only and does not double-render text
  - Export, reopen, and verify the same conditions again.

- **1174R**
  - Use a fully populated representative concrete dataset.
  - Verify preview is read-only and all key filled fields align to the
    original form cells.
  - Export, reopen, and verify the same placements and formatting.

- **SESC 1126**
  - Use a representative filled dataset from the real flow.
  - Verify preview is read-only and the filled fields remain in the original
    AcroForm field positions.
  - Export, reopen, and verify the same placement and formatting contract.

- **Daily Entries / IDR**
  - Use a representative real dataset with enough content to exercise
    header/body/remarks-style areas.
  - Verify preview is read-only and structurally correct.
  - Export, reopen, and verify the same output again.

## Acceptance Criteria

- All required forms pass:
  - targeted tests
  - touched-file analysis
  - artifact-level fidelity checks
  - first live-device preview verification
  - first live-device export verification
  - post-verification implementation review
  - final live-device preview re-verification
  - final live-device export re-verification
- 0582B standards are in Proctor, not Quick Test.
- 0582B chart standards use two chart boxes and operating standards use single
  values.
- Preview is flattened/read-only across all required forms and does not
  double-render filled text.
- Exported PDFs preserve the intended AcroForm contract and match preview
  content.
- No mock auth is used anywhere in runtime verification.
- Samsung bad-sync/background recovery and slow warm resume are both
  reproduced, repaired if needed, and verified on the corrected real-auth build
  before final closeout.

## 2026-04-10 Live Device Verification Update

- First-pass all-form real-auth Samsung validation is now complete for the
  seeded project-backed dataset. Data setup was DB-seeded into the real app
  database so every form could be exercised through the real preview/export
  code paths; auth/session/backend sync were not mocked.
- 0582B final focused proof:
  - preview evidence:
    `.codex/artifacts/2026-04-10/device_validation/87_0582b_preview_after_standards_fix.png`
    and `.codex/artifacts/2026-04-10/device_validation/87_0582b_preview_after_standards_fix.xml`
  - exported AcroForm proof:
    `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_seeded_after_standards_fix_device_export.pdf`
  - verified field values:
    `2Row1=1`, `ARow1=1`, `BRow1=8`, `CRow1=.0439`,
    `DRow1=4600`, `ERow1=2006`, `FRow1=2594`, `GRow1=5.72`,
    `HRow1=130.2`, `DENSITYRow1=131.5`, `DENSITYRow2=132.5`,
    `MOISTURERow1=7.5`, `MOISTURERow2=8.5`,
    `DENSITYRow1_2=130.0`, `MOISTURERow1_2=7.5`.
  - preview XML had `EditText` count `0` and no row-zero text hit.
- 1126 first-pass proof:
  - preview evidence:
    `.codex/artifacts/2026-04-10/device_validation/92_1126_seed_preview.png`
    and `.codex/artifacts/2026-04-10/device_validation/92_1126_seed_preview.xml`
  - export required the real typed-signature flow. The real profile name
    `E2E Test Inspector` was signed in-app, creating local signature audit/file
    rows before export.
  - exported AcroForm proof:
    `.codex/artifacts/2026-04-10/device_validation/MDOT_1126_seeded_signed_device_export.pdf`
  - verified fields include `CONTROL SECTION=CS-1126`,
    `JOB NUMBER=LV-0582B-0410`, `INSPECTION DATE=2026-04-07`,
    `INSPECTOR NAME Please print=E2E Test Inspector`,
    `TYPE OF CONTROLRow1=Silt fence`, and
    `CORRECTIVE ACTION REQUIRED See Note 5Row2=Remove accumulated sediment`.
- 1174R first-pass proof:
  - preview evidence:
    `.codex/artifacts/2026-04-10/device_validation/112_1174r_preview.png`
    and `.codex/artifacts/2026-04-10/device_validation/112_1174r_preview.xml`
  - exported AcroForm proof:
    `.codex/artifacts/2026-04-10/device_validation/MDOT_1174R_seeded_device_export.pdf`
  - verified fields include `Prime Concrete`, `US-31 Bridge Rehab`,
    `1174-7`, `2026-04-09`, `Great Lakes Ready Mix`, `M-53`,
    `All placement conditions acceptable.`, and
    `Continued observations on page 2`; preview XML had `EditText` count `0`.
- Daily Entry / IDR first-pass proof:
  - preview evidence:
    `.codex/artifacts/2026-04-10/device_validation/124_idr_pdf_preview.png`
    and `.codex/artifacts/2026-04-10/device_validation/124_idr_pdf_preview.xml`
  - exported artifact folder:
    `.codex/artifacts/2026-04-10/device_validation/idr_04-07_172657/`
  - verified `DWR_04-07.pdf` has 179 AcroForm fields and contains the seeded
    project, inspector, contractor, equipment, activity, and safety values in
    fields; preview XML had `EditText` count `0`.
- Post-verification review and final full live-device re-verification are still
  required by Gate 4 and Gate 5 before closing this spec.

## 2026-04-10 Double-Text / Row-Zero Regression Update

- User-reported regression:
  - 0582B still appeared double-written in preview/export.
  - A visible test number appeared as `0`; 0582B test/proctor rows must start
    at `1`.
- Code repair:
  - registry-backed PDF fillers now own their write path exclusively in
    `form_pdf_rendering_service.dart`; the generic field/table fallback is
    skipped for registered forms so 0582B/1126/1174R cannot receive a second
    generic text-writing pass over the form-specific writer output.
  - 0582B row-number formatting now treats blank, invalid, or stale `0`
    values as the one-based PDF row fallback in the PDF filler and hub/form
    display widgets.
  - the synthetic fidelity seed no longer includes an unrelated offset zero
    in the same proof artifact, so a real row-number regression cannot be
    hidden by a valid `14Row1` distance value.
- Verification:
  - `flutter analyze` on touched 0582B/PDF/widget files: green.
  - targeted tests for 0582B filler, numbering, export matrix, and PDF field
    writer: green.
  - regenerated PDF fidelity artifacts with
    `.codex/scripts/generate_pdf_fidelity_artifacts_test.dart`: green.
  - synthetic preview artifact
    `.codex/artifacts/2026-04-10/pdf_fidelity_verification/generated/preview_0582b_business_values_read_only.pdf`
    has no AcroForm fields, no literal zero row number, and exactly one
    occurrence each of the proof tokens `2594`, `5.72`, and `130.2`.
  - real-auth Samsung build installed from
    `build/app/outputs/flutter-apk/app-debug.apk` with SHA256
    `5A4C802CAE87A1320C436F9E431FA94AF3746DA2C7789BB2CE776CDB05828D4E`.
  - after force-stopping stale restored state, the app opened through the real
    project-backed path and regenerated 0582B preview proof at
    `.codex/artifacts/2026-04-10/device_validation/142_0582b_preview_after_double_text_row_zero_fix.png`
    and `.codex/artifacts/2026-04-10/device_validation/142_0582b_preview_after_double_text_row_zero_fix.xml`.
  - pulled real-device export proof:
    `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_after_double_text_row_zero_fix_device_export.pdf`.
  - exported AcroForm inspection shows `2Row1=1`, `ARow1=1`,
    `BRow1=8`, `CRow1=.0439`, `DRow1=4600`, `ERow1=2006`,
    `FRow1=2594`, `GRow1=5.72`, `HRow1=130.2`,
    chart standards in `DENSITYRow1/DENSITYRow2` and
    `MOISTURERow1/MOISTURERow2`, and operating standards in
    `DENSITYRow1_2/MOISTURERow1_2`.
  - exported AcroForm inspection found no `2Row*` or `ARow*` field with value
    `0`, and no generic `Test Results:` page text.
- Caveat:
  - `14Row1=0` may still exist in older/user-entered live records as a valid
    right-offset/distance value; it is not a test/proctor row number.
  - all-form final closeout remains open until the post-verification
    implementation review and final all-form real-device re-verification pass
    are completed.

## 2026-04-10 Post-Review Fixes And Final Form Re-Verification

- Post-verification implementation review findings:
  - no remaining confirmed double-writer path was found for registered forms;
    `form_pdf_rendering_service.dart` now keeps registered fillers on the
    form-specific writer path and skips the generic field/table fallback.
  - confirmed stale-preview risk: form preview cache keys did not include
    parsed header data, so header-only edits could reuse an old preview.
  - confirmed 0582B stale-row risk: proctor rows with `test_number=0` and only
    legacy `weights_20_10` values no longer wrote literal `0`, but could still
    be normalized into a duplicate visible proctor row `1` and shift the real
    proctor data to row 2.
  - residual test coverage gap: 1126 and 1174R used the shared preview
    transformer path but did not have explicit preview-flattening tests.
- Additional repairs:
  - preview cache hashing now includes `response.parsedHeaderData`.
  - 0582B parsed/model/PDF filler logic now drops stale zero-number,
    weights-only proctor rows while preserving positive-number weight rows and
    zero-number rows that contain substantive proctor values.
  - explicit preview-flattening tests now cover 1126 and 1174R in the export
    mapping matrix.
- Verification after the review fixes:
  - `flutter analyze` on the touched cache/model/filler/test files: green.
  - `flutter test test\features\forms\services\form_state_hasher_test.dart test\features\forms\data\models\form_response_test.dart test\features\forms\data\pdf\mdot_0582b_pdf_filler_test.dart test\features\forms\services\form_export_mapping_matrix_test.dart`:
    green (`+66`).
  - `.codex/scripts/generate_pdf_fidelity_artifacts_test.dart`: green; log at
    `.codex/artifacts/2026-04-10/pdf_fidelity_verification/artifact_generator_run_after_review_fixes.log`.
  - rebuilt and installed real-auth Samsung APK with SHA256
    `CE55975FBA7084B728AEAB6EB67E38E12D144F2C05A97C6B32C152045E3C45AE`;
    package dump showed `lastUpdateTime=2026-04-10 17:52:33`.
- Final all-form real-device re-verification on the fresh APK:
  - 0582B preview:
    `.codex/artifacts/2026-04-10/device_validation/159_0582b_preview_after_review_fix.png`
    and `.codex/artifacts/2026-04-10/device_validation/159_0582b_preview_after_review_fix.xml`;
    preview XML had `EditText=0`, no `Test Results:`, no `Test #0`, and
    expected 0582B values present.
  - 0582B export:
    `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_after_review_fix_device_export.pdf`;
    exported AcroForm had `2Row1=1`, `ARow1=1`, `ARow2/BRow2/FRow2/GRow2/HRow2`
    empty, `B/C/D/E=8/.0439/4600/2006`, `F/G/H=2594/5.72/130.2`, chart
    standards `131.5/132.5` and `7.5/8.5`, operating standards `130.0` and
    `7.5`, and no zero-valued `2Row*`/`ARow*` fields.
  - 1126 preview:
    `.codex/artifacts/2026-04-10/device_validation/164_1126_preview_after_review_fix.png`
    and `.codex/artifacts/2026-04-10/device_validation/164_1126_preview_after_review_fix.xml`;
    preview XML had `EditText=0` and expected `CS-1126`,
    `LV-0582B-0410`, `E2E Test Inspector`, `Silt fence`, and
    `Remove accumulated sediment` values.
  - 1126 export:
    `.codex/artifacts/2026-04-10/device_validation/MDOT_1126_after_review_fix_device_export.pdf`;
    exported AcroForm preserved fields and wrote `CONTROL SECTION=CS-1126`,
    `JOB NUMBER=LV-0582B-0410`, `INSPECTION DATE=2026-04-07`,
    `INSPECTOR NAME Please print=E2E Test Inspector`,
    `TYPE OF CONTROLRow1=Silt fence`, and
    `CORRECTIVE ACTION REQUIRED See Note 5Row2=Remove accumulated sediment`.
  - 1174R preview:
    `.codex/artifacts/2026-04-10/device_validation/168_1174r_preview_after_review_fix.png`
    and `.codex/artifacts/2026-04-10/device_validation/168_1174r_preview_after_review_fix.xml`;
    preview XML had `EditText=0` and expected concrete values including
    `Prime Concrete`, `US-31 Bridge Rehab`, `1174-7`,
    `All placement conditions acceptable.`, and
    `Continued observations on page 2`.
  - 1174R export:
    `.codex/artifacts/2026-04-10/device_validation/MDOT_1174R_after_review_fix_device_export.pdf`;
    exported AcroForm preserved fields and wrote `Text1.0.0=Prime Concrete`,
    `Text1.0.1=US-31 Bridge Rehab`, `Text4=1174-7`,
    `Text5=2026-04-09`, `Text35=All placement conditions acceptable.`, and
    `Text52.0=Continued observations on page 2`.
  - Daily Entry / IDR preview:
    `.codex/artifacts/2026-04-10/device_validation/173_idr_pdf_preview_after_review_fix.png`
    and `.codex/artifacts/2026-04-10/device_validation/173_idr_pdf_preview_after_review_fix.xml`;
    preview XML had `EditText=0` and expected daily-entry values visible.
  - Daily Entry / IDR export:
    `.codex/artifacts/2026-04-10/device_validation/idr_04-07_180017/DWR_04-07.pdf`;
    exported AcroForm had 179 fields and expected values including
    `Text10=4/7/26`, `Dropdown16=Tuesday`,
    `Text11=LV-0582B-0410`, `Text15=Live 0582B Verification`,
    `Text14=E2E Test Inspector`, `Namegdzf=Prime Builders`, and
    the seeded daily activity in `Text3`.
- Form fidelity closeout state:
  - post-verification implementation review is complete.
  - final all-form preview/export re-verification is complete on the
    real-auth Samsung build.
  - the remaining overall beta plan gates were the non-form Samsung
    bad-sync/background recovery and warm-resume lanes.

## 2026-04-10 Samsung Resume / Sync Recovery Re-Verification

- Warm resume on the final real-auth APK:
  - evidence:
    `.codex/artifacts/2026-04-10/device_validation/178_warm_resume_after_review_fix.png`,
    `.codex/artifacts/2026-04-10/device_validation/178_warm_resume_after_review_fix.xml`,
    and
    `.codex/artifacts/2026-04-10/device_validation/178_warm_resume_after_review_fix_log_excerpt.txt`.
  - `am start -W` reported `LaunchState: HOT`, `TotalTime=57ms`, and
    `WaitTime=61ms`; the PowerShell-measured command wall time was `161ms`.
  - app log showed `SyncLifecycleManager: Skipping resume sync trigger`, so
    this warm-resume pass did not block on auth or sync startup.
- Bad-sync/background recovery on the final real-auth APK:
  - evidence:
    `.codex/artifacts/2026-04-10/device_validation/179_background_sync_resume_after_review_fix.png`,
    `.codex/artifacts/2026-04-10/device_validation/179_background_sync_resume_after_review_fix.xml`,
    and
    `.codex/artifacts/2026-04-10/device_validation/179_background_sync_resume_after_review_fix_log_excerpt.txt`.
  - device was backgrounded for more than the 30-second sync debounce window.
  - background quick sync initially hit a real DNS reachability failure:
    `Failed host lookup` and `DNS unreachable before attempt 1/3`.
  - the same real-auth session recovered on retry after resume:
    `Reachability check passed (HTTP 401)`,
    `quick push complete: 0 pushed, 0 errors`,
    `quick pull complete: 0 pulled, 0 errors`, and
    `Sync cycle (quick): pushed=0 pulled=0 errors=0 conflicts=0`.
  - resumed UI XML had no `Sync failed`, `sync failed`, `Connectivity`, or
    `broken` text and remained on the read-only IDR preview (`EditText=0`).
- Overall state:
  - no mock auth was used in these checks.
  - form fidelity, final all-form device re-verification, warm resume, and
    bad-sync/background recovery have all been re-run on the final installed
    Samsung build.

## Assumptions And Defaults

- The two chart boxes are treated in reading order as `first` and `second` to
  avoid embedding an unsupported semantic label into the data contract.
- Preview flattening is a preview-only transformation to avoid `SfPdfViewer`
  double-rendering AcroForm widgets; export remains the fidelity-preserving
  AcroForm output path.
- The active Codex plan file and the 2026-04-10 tracker will be updated to
  mirror this spec as soon as implementation begins.
