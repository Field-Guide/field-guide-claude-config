# Pay App And Form Filler Completion Spec

## Summary

This is the canonical implementation and verification spec for the current
pay-application/form-filler completion lane. Implement against it with real
auth only, no `MOCK_AUTH`, on Samsung `RFCNC0Y975L`.

Completion requires implementation, local verification, live-device
verification, self-review against this spec, iteration on every failed or
blocked item, and then a completeness-agent review until the spec intent and
evidence are fully captured.

## Key Changes

- Fix compact overflow in `PayAppNumberDialog` by making dialog actions
  responsive on phone width.
- Add shared numeric keyboard progression for form fillers so numeric fields in
  0582B, 1126, and 1174R advance to the next field, row, or section through
  `Next` / `Done`.
- Rework the canonical project pay-app workbook into a G703-style running
  ledger, not worksheet-per-pay-app.
- Preserve individual exported pay-app snapshots if needed, but make the
  cumulative project workbook the main same-page ledger.
- Add contractor comparison fixtures: one golden Excel sheet and one
  OCR/PDF-derived import fixture, both verified against the same discrepancy
  manifest.
- Re-run final PDF fidelity for Daily Entry/IDR, 0582B, 1174R, and 1126:
  every field filled, preview verified, export verified, preview read-only,
  exported AcroForm fields preserved.

## Quantity Source Of Truth

- `entry_quantities` is the canonical quantity ledger for project pay-app
  tracking over time.
- `bid_items` is the static contract catalog and must provide every project pay
  item row, including unused items.
- `daily_entries` provides dated parent context and narrative/demo proof only;
  it is not a competing quantity source.
- Pay-application records define reporting periods and app numbers; they must
  not duplicate or replace quantity tracking.

## G703-Style Running Ledger

- One workbook with one primary worksheet for the Springfield project pay-app
  log.
- All bid items for the selected project appear as vertical rows, including
  unused items. Do not hard-code Springfield's item count into production.
- Frozen left columns include line number, item code, description, unit, bid
  quantity, unit price, bid amount, quantity to date, amount to date, percent
  complete, and remaining/balance fields.
- Daily dates run horizontally across the worksheet. The 20 demo daily-entry
  dates each get a visible date column or date column group.
- Only pay items used on a given date are populated in that date's cells;
  unused item/date intersections remain blank or zero per the chosen Excel
  convention.
- Pay App #1, #2, and #3 are represented as sequential horizontal period groups
  on the same worksheet, with period totals traceable from the daily date
  columns.
- The workbook must support real review: frozen headers, frozen item identity
  columns, horizontal date scrolling, vertical item scrolling, formulas/totals,
  and inspectable bid amount / quantity-to-date calculations.
- AASHTOWare/MDOT `Item Posting by Item XLS` and `Project Payment Report XLS`
  informed this structure, but the implementation name for this app is
  G703-style running ledger.

## Demo Data Requirements

- Create 20 realistic Springfield daily entries across 20 different dates.
- Each entry must read like a real field report: plausible weather, crews,
  equipment, locations/stations, work performed, inspection notes, safety
  notes, material activity, delays if applicable, and quantity explanations.
- Each entry uses five different pay items with realistic non-zero quantities
  that match that day's narrative.
- Across the Springfield demo workbook, all 131 Springfield bid items still
  appear as rows; only the used items per day receive values in that date's
  columns.
- Avoid placeholder/demo-looking strings, repeated generic remarks, or
  artificial values.
- Run a demo-data quality review before using the entries for pay apps.

## Verification Gates

- Compact pay-app number dialog widget test proves no overflow and successful
  submit.
- Form workflow tests prove numeric submit advances fields, rows, or sections
  for 0582B, 1126, and 1174R without breaking tap-out dismissal.
- Workbook tests prove one primary G703-style running ledger worksheet, every
  bid item returned for the selected project, horizontal daily/pay-app columns,
  three sequential pay-app groups, correct bid quantities/amounts, correct
  daily populated cells, and totals matching generated pay apps. The
  Springfield fixture should assert 131 rows because Springfield currently has
  131 project bid items.
- Contractor comparison tests prove Excel import and OCR/PDF import produce the
  same discrepancy manifest: item matches, quantity/amount deltas, daily
  discrepancy rows, and exported comparison report.
- Form fidelity tests prove previews are flattened/read-only while exported
  PDFs preserve AcroForm fields.

## Real-Auth Device Gates

- Confirm `.env` has no `MOCK_AUTH`.
- Stop stale Gradle/debug/server processes before build.
- Rebuild after relevant changes with
  `flutter build apk --debug --dart-define-from-file=.env`.
- Install to Samsung `RFCNC0Y975L`.
- Record build hash/install time and confirm the active session is a real
  backend session.
- Use the real admin account to approve the real inspector account for
  Springfield.
- Log in as the real inspector and confirm Springfield is locally available.

## E2E Workflows

- Pay app: create 20 realistic daily entries with five used pay items per
  entry, create three weekly pay apps, extract the canonical workbook, and
  verify the G703-style running ledger structure and totals. Save evidence
  under `.codex/artifacts/2026-04-11/pay_app_e2e/`.
- Contractor comparison: import the golden discrepancy Excel sheet, import the
  OCR/PDF-derived contractor artifact, verify both produce the same expected
  discrepancy set, export the comparison report, and save evidence under
  `.codex/artifacts/2026-04-11/contractor_comparison/`.
- Forms: fill every field on Daily Entry/IDR, 0582B, 1174R, and 1126 through
  the real app flow. For each form, save preview screenshot, export PDF,
  field-count proof, representative filled-value proof, read-only preview
  proof, and exported AcroForm editability proof under
  `.codex/artifacts/2026-04-11/final_form_fillout/`.
- Exhaustive PDF mapping means every mapped AcroForm cell, table row, row
  group, calculated column, checkbox/control, standards cell, remarks cell, and
  overflow/continuation cell for the form type is populated or intentionally
  asserted blank. Section-level completion is not enough.
- Verification fixtures must include enough rows to cover the full row capacity
  of every mapped table on each form, including 0582B top test rows and proctor
  rows, 1126 rainfall/control-measure rows, 1174R observation/QA/quantity rows,
  and IDR contractor/personnel/equipment/quantity/photo/form-attachment cells.
- The all-cell gate must compare the generated filled export against the
  shipped template field inventory so missing, unmapped, double-written, or
  unexpectedly flattened export fields fail the verification.
- UI verification must prove the form-fillers can create/send enough rows to
  reach the mapped PDF row capacity, not merely that each section can be marked
  complete.

## Completion Review Gate

- Create an evidence manifest per workstream listing commands, test outputs,
  APK hash/install time, account/session proof, artifact paths, workbook paths,
  exported PDFs, parsed inspection outputs, and screenshots.
- Perform a self-review against every bullet in this saved spec, marking each
  item `pass`, `fail`, or `blocked`.
- Iterate on every `fail` or `blocked` item: repair, re-test, re-verify on
  device when relevant, and update the manifest.
- Run a completeness-agent review against the saved spec and artifact folders
  after self-review.
- Do not close or report the work complete until the completeness review finds
  no missing intent, missing proof, or unverified acceptance criteria.
- Final reporting may only claim an item complete if matching evidence exists
  in the manifest; otherwise it remains open.

## Assumptions

- Production must adapt to the selected project's bid-item catalog size. The
  Springfield verification project currently contains 131 bid items, and that
  demo workbook must include every one of them even when unused for the current
  pay period.
- The format name for this implementation is G703-style running ledger.
- Helper/metadata sheets are allowed only if they do not replace the main
  same-page ledger.
- Contractor OCR/PDF fixture may be generated from the golden discrepancy data
  so both import paths compare against the same manifest.
- Exported form PDFs must preserve AcroForm fields; only preview PDFs may be
  flattened/read-only.
- No verification result is acceptable from `MOCK_AUTH`, mock sessions, or
  stale installed builds.

## Local Implementation Checkpoint - 2026-04-11

- Pay-app G703-style running ledger implementation is in place locally and uses
  the selected project's bid-item catalog size, not a hard-coded Springfield
  row count.
- Compact pay-app number dialog has a phone-width widget regression test for
  overflow-free submit.
- Shared form row-entry progression is in place for standardized 1174R row
  composers; 0582B Quick Test/Proctor numeric inputs and 1126 rainfall inches
  now expose explicit `Next` / `Done` keyboard actions.
- Focused local verification is green:
  - `35` focused widget/domain/service tests passed across pay-app workbook,
    pay-app export, pay-app dialog, `AppTextField`, 0582B, 1126, and 1174R.
  - Focused `flutter analyze` over touched implementation and test files found
    no issues.
- Remaining completion evidence must still come from the real-auth Samsung
  build/device flow, contractor comparison fixtures, demo daily-entry/pay-app
  workbook extraction, and all-form PDF preview/export fidelity checks.

## Device Verification Checkpoint - 2026-04-11 00:28 ET

- Real-auth guard: `.env` scan found no `MOCK_AUTH`, `mock_auth`, `USE_MOCK`,
  or `mock` definitions before the device build.
- Samsung build installed on `RFCNC0Y975L` with
  `flutter build apk --debug --dart-define-from-file=.env`; APK SHA-256:
  `ED10D5CA1BAC20F74B81C5DF18C9DDB0459B47EECE922437E40A78302DAEC738`.
- The active device session opened into the real project
  `Live 0582B Verification` with sync status `All synced`.
- Fixed the 0582B staged-draft leak where the next unsent Quick Test draft was
  being exported into row 2 after row 1 had already been sent.
- Local regression proof:
  `flutter test test/features/forms/data/pdf/mdot_0582b_pdf_filler_test.dart`
  passed all `13` tests, including
  `does not map a next quick-test draft that only has carried item data`.
- Focused analyzer proof:
  `flutter analyze lib/features/forms/data/pdf/mdot_0582b_pdf_filler.dart test/features/forms/data/pdf/mdot_0582b_pdf_filler_test.dart`
  reported no issues.
- Device-exported 0582B post-fix PDF evidence:
  `.codex/artifacts/2026-04-11/final_form_fillout/0582b_post_fix/MDOT_0582B_2026-04-11_d334ee30_post_fix.pdf`.
- Post-fix exported PDF field proof:
  `acroform_present=True`, `field_count=270`, `1Row1='1'`,
  `10Row1='135.9'`, `16Row1='SG'`, `FRow1='2809'`, `GRow1='6.19'`,
  `HRow1='141.0'`, `1Row2=None`, `10Row2=None`, `16Row2=None`.
- The non-empty `DENSITYRow2='475.0'` and `MOISTURERow2='502.0'` values in the
  exported proof are the second chart-standard range boxes, not a leaked
  second quick-test row.
- Focused regression bundle passed after the device-export repair: `49` tests
  across 0582B PDF mapping, the shipped export mapping matrix, preview action
  ownership, pay-app workbook builder/use cases, pay-app number dialog, and
  `AppTextField`.
- Focused analyzer proof over the same implementation/test lanes reported no
  issues.
- Pay-app workbook coverage was extended with a 20-date Springfield-style
  fixture: 131 adaptive bid-item rows, five used item postings per date,
  exactly three sequential horizontal pay-app groups, one `G703 Ledger`
  worksheet, frozen review panes, and blank unused item/date intersections.
- Contractor comparison import coverage was extended with a shared discrepancy
  manifest proving generated Excel and best-effort PDF import artifacts parse
  to the same item, quantity, amount, and daily-detail rows.
- Pay-app/contractor focused verification passed `15` tests across workbook
  builder/use cases, import parser, contractor comparison provider, and
  discrepancy PDF exporter. Focused analyzer over the new tests and the 0582B
  filler reported no issues.
- Local PDF writer all-row capacity coverage was extended and verified for
  shipped forms: 0582B now fills all 12 top test rows, all 5 proctor rows,
  F/G/H computed columns, chart/operating standards, and remarks; 1126 now
  fills all 7 mapped control-measure rows plus header/remarks; 1174R now fills
  all mapped observation, QA, quantity, remarks, and closeout/signature fields.
  Daily Entry/IDR now fills every mapped contractor/personnel/equipment row
  capacity across all five contractor sections and catches equipment checkbox
  coverage.
- Fixed an IDR writer mapping bug found by the all-cell gate: the writer was
  using `hhhhhhhhhhhwerwer` as both a prime-contractor equipment row and the
  inspector signature target. Field coordinates show it is an equipment row;
  the bad signature write was removed so capacity equipment values are no
  longer overwritten.
- The local gate
  `flutter test test/features/forms/services/form_export_mapping_matrix_test.dart`
  now passes all `24` tests, including exported editable-field structure
  preservation against the shipped 0582B, 1126, and 1174R templates; the
  combined focused regression bundle across 0582B
  filler, the export mapping matrix, G703 workbook use case, and pay-app import
  parser passed all `44` tests; and focused analyzer over the touched form mapping
  test/filler files reported no issues. This is local writer proof only and
  does not replace real-device UI preview/export evidence.
- After the IDR writer fix, ADB was restarted, `.env` was re-scanned with no
  mock-auth matches, and a new real-auth Samsung build was installed without
  `flutter clean`: APK SHA-256
  `7F80909E704D67173725E474CE1D93EBBE3A5CCB7AB844DE3A1ABDB2033CF212`,
  package `com.fieldguideapp.inspector`, `versionCode=3`,
  `versionName=0.1.2`, `lastUpdateTime=2026-04-11 00:49:58`.
- Real-device IDR/DWR preview and export smoke proof was captured from the
  real project on that build. Exported folder:
  `.codex/artifacts/2026-04-11/final_form_fillout/idr_device_post_fix/04-07_005317/`.
  Parsed `DWR_04-07.pdf` proof: `acroform_present=True`, `field_count=179`,
  `Text10='4/7/26'`, `Dropdown16='Tuesday'`, `Text11='LV-0582B-0410'`,
  `Text15='Live 0582B Verification'`, `Namegdzf='Prime Builders'`,
  `ggggssssssssssssssss='Excavator 320'`,
  `3#aaaaaaaaaaa0='Steel Drum Roller'`, and `hhhhhhhhhhhwerwer=None`, proving
  the equipment row is no longer overwritten by the old signature write. This
  is device smoke proof only, not the exhaustive all-cell IDR gate, because the
  existing device entry does not fill every contractor/equipment row.
- A partial 1126 device export from an incomplete signature state saved to
  `/storage/emulated/0/Documents/04-11/04-07/MDOT_1126_2026-04-07_codex-li.pdf`,
  which proves the export action did not hard-block on section completion. This
  artifact is not sufficient for the exhaustive all-cell mapping gate.
- Remaining completion evidence is still open for full 0582B all-field
  preview/read-only verification, all-field 1174R/1126/Daily Entry-IDR
  preview/export fidelity, contractor comparison parity fixtures, the
  Springfield G703-style workbook e2e flow, warm-resume/sync recovery proof,
  and final self-review plus completeness-agent review.

## Current Verification Ledger - 2026-04-11 01:05 ET

Status labels: `PASS` means matching evidence exists, `PARTIAL` means useful
proof exists but does not meet the full spec gate, `OPEN` means not yet
verified, and `BLOCKED` means the next step needs missing real project/account
state or data.

Scope correction: do not collapse this plan to the latest smoke checks. The
remaining completion gate is still the full spec: every mapped field/cell/row
on Daily Entry/IDR, 0582B, 1174R, and 1126; preview and export proof for each;
exported AcroForm field preservation and no double-written overlay text;
Springfield real-auth pay-app setup, demo entries, three pay apps, and the
single-sheet G703-style running ledger; contractor Excel and OCR/PDF comparison
imports; sync/background recovery; and final self-review plus completeness
review. Partial device smoke evidence stays partial until those artifacts
exist.

- `PASS` Real-auth guard: `.env` mock-auth scan was clean before the latest
  Samsung build, and the installed APK hash/install time are recorded above.
- `PASS` Local writer capacity: focused tests now cover full mapped row/cell
  capacity for 0582B, 1126, 1174R, and Daily Entry/IDR PDF writers, including
  0582B F/G/H calculations, IDR equipment-row overwrite regression, and
  exported editable-field structure preservation for the canonical IDR
  template and the shipped 0582B, 1126, and 1174R templates.
- `PASS` Local all-cell artifact generation: exported and preview PDFs for
  IDR, 0582B, 1126, and 1174R were regenerated under
  `.codex/artifacts/2026-04-11/final_form_fillout/local_all_cell/` with
  `WRITE_PDF_ARTIFACTS=true`; `syncfusion_parsed_field_proof.txt` records that
  previews are flattened/read-only locally while exports preserve populated
  AcroForm fields, including 0582B row 12, 1126 row 7, 1174R final observation/
  QA/quantity rows, and the IDR equipment row previously mistaken for a
  signature field. This is local writer/artifact proof only and does not close
  any real-device UI full-capacity gate.
- `PASS` Local workbook shape: focused tests cover the adaptive G703-style
  running ledger with 131 Springfield-style fixture bid-item rows, 20 demo date
  columns, five postings per date, blank unused intersections, formulas, frozen
  panes, and three horizontal pay-app groups on one worksheet.
- `PASS` Local contractor parser parity: focused tests cover generated Excel
  and best-effort PDF/OCR-style artifacts parsing into the same discrepancy
  manifest.
- `PASS` Local form-filler UI regression: `23` focused widget tests passed for
  1174R row composers appending to the next blank PDF slot, disabling at PDF
  capacity, using compact two-column layout, and advancing on field submit;
  shared `AppFormSection` collapsed bodies; and 1126 header/signature/attach
  widget lanes. This supports the full-capacity UI design but does not replace
  real-device all-form fillout proof.
- `PASS` Additional local 0582B/1126 UI regression: `16` focused widget/
  controller tests passed for 0582B original/recheck/proctor numbering,
  compact Quick Test keeping the Send action in the initial viewport, Proctor
  soil/HMA modes, and 1126 preview/export/tap-out/collapse/signature-attach/
  discard behavior. This is local UI proof only and does not replace
  real-device all-form fillout proof.
- `PASS` Consolidated focused local regression: the combined writer/workbook/
  parser/UI command passed `83` tests and is saved at
  `.codex/artifacts/2026-04-11/focused_form_payapp_ui_regression_latest.log`.
- `PASS` Targeted 0582B device export: the post-fix real-device PDF proves row
  1 values, F/G/H values, row 2 quick-test blanks, AcroForm presence, and chart
  standards in their range boxes.
- `PARTIAL` Daily Entry/IDR device preview/export: the latest device export
  proves AcroForm preservation and the removed signature/equipment overwrite,
  but it does not fill every mapped IDR contractor/personnel/equipment/
  quantity/photo/form-attachment cell.
- `PARTIAL` 1126 device export: a device export from an incomplete signature
  state proves export was not hard-blocked, but it does not prove all mapped
  1126 cells, signature completion state, attachment flow, or exported field
  fidelity.
- `OPEN` 0582B full-capacity UI gate: use the real app flow to create/send
  enough quick-test/proctor/standards rows to cover every mapped 0582B PDF row
  and cell, then verify read-only preview and exported editable AcroForm.
- `OPEN` 1174R full-capacity UI gate: use the real app flow to fill every
  mapped observation, QA, quantity, remarks, closeout, and signature field,
  then verify read-only preview and exported editable AcroForm.
- `PARTIAL` 1174R real-device reachability/UI smoke: the latest real-auth
  Samsung build opened 1174R from the live project Toolbox, and the Air/Slump
  composer exposed the clarified next-blank-row instruction and `Rows used: 0
  of 5`. This does not close the full-capacity 1174R gate.
- `OPEN` 1126 full-capacity UI gate: use the real app flow to fill every
  mapped rainfall/control-measure/header/remarks/signature field, confirm the
  signature state reaches the UI, confirm daily-entry attachment works, and
  verify read-only preview plus exported editable AcroForm.
- `OPEN` Daily Entry/IDR full-capacity UI gate: use the real app flow to fill
  every mapped contractor/personnel/equipment/quantity/photo/form-attachment/
  continuation field, then verify read-only preview and exported editable
  AcroForm.
- `OPEN` All-form no-double-write gate: compare all real-device exports against
  the shipped template field inventory so any duplicate text overlay, missing
  AcroForm value, unexpected flattening, or formatting drift fails the gate.
- `PASS` Springfield project access and catalog backfill: real admin approval
  assigned the real inspector account to Springfield, the stale child-cursor
  sync defect was repaired, and the repaired real-auth Samsung build installed
  at `2026-04-11 01:45:22` with APK SHA-256
  `7EDD251015547DFC5C34824A27DE429CB5DEAD889A6B344C9A5DBD8A0B58AC13`.
  Device UI proof shows `Springfield DWSRF`, `131 Pay Items`, and
  `TOTAL CONTRACT $7,882,928`; DB proof under
  `.codex/artifacts/2026-04-11/admin_springfield/device_db_after_cursor_repair/query_proof.json`
  shows the active assignment and `springfield_bid_count.count=131`.
- `BLOCKED` Current device DB proof: the 2026-04-11 01:08 ET pull under
  `.codex/artifacts/2026-04-11/device_db/current/` contains `projects=1`,
  `bid_items=2`, `daily_entries=2`, `entry_quantities=3`,
  `pay_applications=1`; the only project is `Live 0582B Verification`, not
  Springfield, and one submitted 2026-04-10 entry contains gibberish draft
  content that must not be used for demo pay-app evidence.
- `PASS` Springfield admin/inspector gate: approved the real inspector account
  for Springfield from the real admin account, launched the real-auth Samsung
  app as the inspector, synced, and proved Springfield plus the full 131-item
  bid catalog are locally available.
- `PASS` Springfield demo data gate: real-auth inspector data now contains 20
  realistic Springfield daily entries with 100 quantity rows, exactly five used
  pay items per entry, over dates 2026-03-16 through 2026-04-05 except the
  intentionally unused Sunday 2026-03-29. Manifest:
  `.codex/artifacts/2026-04-11/pay_app_e2e/springfield_realistic_20_entry_dataset_manifest.json`.
- `PASS` Springfield pay-app workbook e2e: on the real Samsung build, created
  active Pay Apps #1, #2, and #3 for 2026-03-16..2026-03-22,
  2026-03-23..2026-03-29, and 2026-03-30..2026-04-05. Pulled DB proof under
  `.codex/artifacts/2026-04-11/device_db/after_pay_app3_export/` confirms
  sequential active app numbers, previous-app links, and totals matching the
  100 `entry_quantities` rows. Pulled workbook
  `.codex/artifacts/2026-04-11/pay_app_e2e/final_device_exports/75ae3283_d4b2_4035_ba2f_7b4adb018199_Springfield_DWSRF_pay_applications.xlsx`
  is a one-sheet `G703 Ledger` with 131 bid-item rows, 20 daily quantity
  columns, and Pay App #1/#2/#3 period summary columns.
- `PASS` Contractor comparison real app gate: imported the golden discrepancy
  Excel artifact and OCR/PDF-derived contractor artifact through the real app
  flow, confirmed both produced `131` contractor rows, `131` automatic matches,
  `2` flagged discrepancy rows, and `-$155.50` period variance, then exported
  comparison reports from both import paths.
- `OPEN` Sync/background recovery gate: reproduce bad-sync/background resume
  and slow warm-resume lanes on the latest real-auth build and save screenshot
  plus log evidence.
- `PARTIAL` Warm-resume smoke: a shallow 3-second HOME/background HOT resume
  on the latest real-auth build reported `LaunchState=HOT`, `TotalTime=60`,
  and `WaitTime=69`, with screenshot/hierarchy saved under
  `.codex/artifacts/2026-04-11/device_screens/`; this does not reproduce or
  close the longer bad-sync/background recovery lane.
- `PARTIAL` Longer warm-resume smoke: a 60-second HOME/background HOT resume
  on the same real-auth Samsung build reported `LaunchState=HOT`,
  `TotalTime=126`, and `WaitTime=127`, with screenshot/hierarchy/logcat saved
  under `.codex/artifacts/2026-04-11/device_screens/`; this still does not
  reproduce or close the bad-sync/background recovery lane.
- `PARTIAL` Sync UI smoke: tapping Settings -> `Sync Now` on the latest
  real-auth build produced app sync logs with `0 errors`, `0 conflicts`,
  `0 skippedFk`, and `duration=2228ms`, with screenshot/hierarchy/logcat saved
  under `.codex/artifacts/2026-04-11/device_screens/`; this does not reproduce
  or close the bad-sync/background-resume defect.
- `OPEN` Evidence manifest gate: create/update per-workstream manifests with
  commands, test outputs, APK hash/install time, account/session proof,
  artifact paths, workbook paths, exported PDFs, parsed inspection outputs, and
  screenshots.
- `OPEN` Final review gate: perform a spec self-review, iterate every failed or
  blocked line item, then run completeness-agent review against this saved
  spec and artifact folders before reporting completion.

## Springfield Pay-App Ledger Verification - 2026-04-11 02:29 ET

- `PASS` Pay-app numbering repair: the Samsung device still had deleted
  Springfield Pay App #1-#4 tombstones locally, and the UI initially suggested
  Pay App #5. Fixed `PayApplicationLocalDatasource.getNextApplicationNumber`
  to ignore `deleted_at IS NOT NULL`, then rebuilt and installed a real-auth
  debug APK with SHA-256
  `A29679FA4A82CFB38AD10164DC5ACDA4F8037C6DF59DFDF172313DD62C8221F8` and
  package `lastUpdateTime=2026-04-11 02:21:14`.
- `PASS` Local verification for the repair: targeted datasource test
  `flutter test test/features/pay_applications/data/datasources/local/pay_application_local_datasource_test.dart`
  passed, and focused analyzer over the touched datasource/test reported no
  issues.
- `PASS` Real-device numbering verification: with the same stale deleted local
  pay-app tombstones still present, the real Samsung UI suggested Pay App #1
  for 2026-03-16..2026-03-22, then #2 for 2026-03-23..2026-03-29, then #3 for
  2026-03-30..2026-04-05.
- `PASS` Real-device DB verification: pulled DB proof
  `.codex/artifacts/2026-04-11/device_db/after_pay_app3_export/pay_app3_db_and_workbook_verification.json`
  confirms active Pay Apps #1-#3, ranges above, `previous_application_id` chain
  #2 -> #1 and #3 -> #2, and totals matching recomputation from
  `daily_entries`, `entry_quantities`, and `bid_items`: #1 `$181,026.80`, #2
  `$304,746.85` this period / `$485,773.65` to date, and #3 `$145,942.98`
  this period / `$631,716.63` to date.
- `PASS` Workbook extraction and structure verification: pulled artifacts in
  `.codex/artifacts/2026-04-11/pay_app_e2e/final_device_exports/` include the
  three individual pay-app workbooks and the canonical Springfield project
  workbook. `workbook_structure_detail.json` confirms one sheet named
  `G703 Ledger`, 131 item rows (`rows 4..134`), daily quantity columns
  `3/16/26` through `4/5/26`, fixed columns for bid quantity/unit price/bid
  amount/qty-to-date/amount-to-date/balance, and summary columns for Pay App
  #1, #2, and #3 period quantities and period amounts.
- `PASS` Remaining related gate: contractor comparison real-app Excel and
  OCR/PDF import parity verification plus comparison report export are closed;
  supporting evidence is recorded in
  `.codex/artifacts/2026-04-11/evidence_manifest.md`.

## Contractor Comparison And Item Ordering Verification - 2026-04-11 03:11 ET

- `PASS` Contractor comparison performance/order repair: the real Samsung app
  imported both golden contractor artifacts, rendered comparison/detail rows in
  bounded lazy lists, kept export actions reachable, and exported report PDFs
  from both import paths. Saved evidence includes
  `.codex/artifacts/2026-04-11/contractor_comparison/after_xlsx_file_select.png`,
  `.codex/artifacts/2026-04-11/contractor_comparison/after_pdf_file_select.png`,
  the pulled report PDFs, and logcat files with no `FlutterError`,
  `RenderTable`, `SemanticsNode`, fatal exception, or assertion matches.
- `PASS` Shared bid-item ordering repair: `BidItemRepositoryImpl` now natural-
  sorts `getAll`, `getByProjectId`, `search`, `getByProjectIdPaged`, and
  `getPaged`, paging after natural sorting instead of after SQLite string
  ordering. This keeps the project catalog adaptive while preventing item
  order such as `1`, `10`, `100`, `2` from leaking into screens that use paged
  or repository-backed pay-item lists.
- `PASS` Import fallback ordering repair: `ItemDeduplicator` now uses the
  shared natural comparator for non-numeric item-number fallback ordering.
- `PASS` Focused local proof: `flutter test
  test/features/quantities/data/repositories/bid_item_repository_impl_test.dart
  test/features/pdf/extraction/stages/item_deduplicator_test.dart
  test/features/pay_applications/presentation/providers/contractor_comparison_provider_test.dart
  test/features/pay_applications/presentation/widgets/manual_match_editor_test.dart`
  passed `11` tests, and focused `flutter analyze` over the impacted
  implementation/test files reported no issues.
- `PASS` Remaining device proof: rebuilt and reinstalled the latest ordering
  patch on `RFCNC0Y975L`; APK SHA-256
  `D03C6405FD32C9E4FFC0F3D9BF61E706646904140AAB9904FE63B91A29E327E2`,
  package `lastUpdateTime=2026-04-11 03:12:53`. The after screenshot and
  hierarchy under `.codex/artifacts/2026-04-11/device_screens/` show the real
  Springfield Pay Items screen with `131 items` and visible item-number
  sequence `1`, `2`, `3`, `4`, `5`.

## Live Sync Assignment Repair Checkpoint - 2026-04-11 01:43 ET

- `PASS` Admin assignment gate setup: the real admin account approved the real
  inspector account for the real Springfield project using the production
  `admin_upsert_project_assignment` RPC. Redacted proof is saved under
  `.codex/artifacts/2026-04-11/admin_springfield/`.
- `PASS` Root-cause proof: after the assignment, the real Samsung inspector
  session could see Springfield locally, but the device DB still had
  `springfield_bid_items=0` because existing child-table pull cursors were newer
  than Springfield's older bid-item catalog rows.
- `PASS` Local sync repair implementation: new-assignment enrollment and the
  one-time sync repair runner now clear assignment-scoped child pull cursors so
  newly available projects backfill older child records such as `bid_items`.
- `PASS` Local sync repair verification: targeted sync repair and enrollment
  tests passed, and focused analyzer over the touched sync files reported no
  issues.
- `IN_PROGRESS` Real-device sync repair verification: rebuild/install the
  real-auth Samsung APK without `MOCK_AUTH`, launch on `RFCNC0Y975L`, let the
  repair run, sync, pull the device DB, and verify Springfield has all project
  bid items locally before creating demo entries and pay apps.

## Live Sync Assignment Repair Verification - 2026-04-11 01:48 ET

- `PASS` Controlled incremental build: `flutter build apk --debug
  --dart-define-from-file=.env` completed without `flutter clean`; APK
  SHA-256 is `7EDD251015547DFC5C34824A27DE429CB5DEAD889A6B344C9A5DBD8A0B58AC13`.
- `PASS` Real Samsung install: the APK installed to `RFCNC0Y975L` with
  `adb -s RFCNC0Y975L install -r --no-streaming`; package
  `com.fieldguideapp.inspector`, `versionCode=3`, `versionName=0.1.2`,
  `lastUpdateTime=2026-04-11 01:45:29`.
- `PASS` Real-device repair execution: device `sync_metadata` records
  `sync_repair_job::repair_sync_state_v2026_04_11_assignment_scope_cursors`
  with `rows_affected=17` and summary `Cleared assignment-scoped pull cursors
  for project backfill`.
- `PASS` Real-device Springfield backfill: pulled Samsung DB proof shows
  Springfield project `75ae3283-d4b2-4035-ba2f-7b4adb018199` locally available
  with `springfield_bid_items=131`; dashboard screenshot/hierarchy also shows
  `Springfield DWSRF`, `131 Pay Items`, and total contract `$7,882,928`.
- `OPEN` Springfield demo pay-app data: the device has existing Springfield
  entries, but `springfield_entry_quantities=0` and `springfield_pay_apps=0`.
  The spec still requires 20 realistic entries with five quantity rows each and
  three generated weekly pay apps before workbook extraction can close.

## All-Cell Form Fidelity Checkpoint - 2026-04-11 03:43 ET

- `PASS` A real-auth driver-enabled Samsung debug build was installed for the
  form-fidelity lane without `MOCK_AUTH`/`MOCK_DATA`: APK SHA-256
  `81A2D9DA5E55597510ACF74652FEE5B64842DD4F7D30385C977725288BE97943`,
  package `lastUpdateTime=2026-04-11 03:26:45`.
- `PARTIAL` 0582B was filled through the app UI for one proctor row and one
  quick-test row. Preview and export completed, and the pulled export is saved
  at `.codex/artifacts/2026-04-11/final_form_fillout/MDOT_0582B_2026-04-11_driver_export.pdf`
  with SHA-256
  `999B775FCC3EA16145DCDD244A81BEEC6AE551F926BF45C3A613364EF4D6B4B8`.
- `PASS` 0582B preview/export log proof showed AcroForm `/V` writes for the
  tested row and standards fields, including chart range, operating standards,
  F/G/H autofill, item of work `SG`, and test-number row `1`.
- `PASS` Local full-capacity mapping matrix passed:
  `flutter test --dart-define=WRITE_PDF_ARTIFACTS=true test/features/forms/services/form_export_mapping_matrix_test.dart`
  passed `24` tests and regenerated editable exports plus read-only previews
  for `0582B`, `1126`, `1174R`, and `IDR` under
  `.codex/artifacts/2026-04-11/final_form_fillout/local_all_cell/`.
- `OPEN` Remaining all-cell gate: complete UI-driven full-capacity fillout on
  Samsung for every mapped cell/row in `0582B`, `1174R`, `1126`, and Daily
  Entry/IDR; verify read-only preview, editable exported fields, no double
  writing, original formatting, and saved artifact proof for each.

## Calculator And IDR Regression Checkpoint - 2026-04-11 03:50 ET

- `PASS` IDR all-cell local regression is now broader and table-driven,
  covering all five contractor sections, all mapped personnel/equipment cells,
  checkboxes, long activity overflow, quantities, photo/form attachments, and
  sparse clear behavior.
- `PARTIAL` HMA calculator now uses `110 lb / sq yd / inch` and no longer
  exposes density in the dedicated calculator tab or entry quantity calculator
  config. Remaining HMA items are multi-segment entry and weighback.
- `PARTIAL` Concrete calculator user-facing naming changed to
  `Calculator`/`Area / Volume Calculator`; remaining work is interactive
  `cft`/`cyd` and `sft`/`syd` switching.
- `PASS` Focused tests:
  `flutter test test/features/calculator/services/calculator_service_test.dart test/features/calculator/presentation/screens/calculator_screen_test.dart test/features/forms/services/form_export_mapping_matrix_test.dart`
  passed `67` tests.
- `PASS` Focused analyzer over the touched calculator/quantity/form mapping
  files reported `No issues found`.

## Concrete Calculator Follow-Up - 2026-04-11 04:05 ET

- `PASS` Dedicated calculator now supports interactive area/volume unit
  switching: `SY`/`SF` for area and `CY`/`CF` for volume. Unit changes
  recompute the visible result from existing dimensions after calculation.
- `PASS` Focused tests:
  `flutter test test/features/calculator/services/calculator_service_test.dart test/features/calculator/presentation/screens/calculator_screen_test.dart`
  passed `43` tests.
- `PASS` Focused analyzer for
  `lib/features/calculator/presentation/widgets/concrete_calculator_tab.dart`
  reported `No issues found`.
- `OPEN` Device verification remains pending on the next real-auth Samsung
  build/install.

## Review Comments/TODO Checkpoint - 2026-04-11 04:10 ET

- `PASS` Review comments now reuse `todo_items` with metadata
  `source_type='review_comment'`, `source_id`, and `assigned_to_user_id`.
  This keeps inspector review work in the TODO flow instead of creating a
  second comments/task source of truth.
- `PASS` Entry review flow can create review comments for managers, the To-Do
  screen includes a `Review Comments` filter and badge, and the dashboard shows
  an attention card while open review comments exist.
- `PASS` Local DB schema/version and Supabase migration/rollback files were
  updated. Rollback validation passes for enforced migrations.
- `PASS` Focused TODO/dashboard/database tests and analyzer passed locally.
- `OPEN` Backend migration application and Samsung verification remain pending.

## Review Comment TODO Follow-Up - 2026-04-11 04:10 ET

- `PASS` Local review-comment TODO implementation now reuses synced
  `todo_items` with metadata rather than introducing a second comments store.
  Engineers and Office Technicians can add a high-priority review comment from
  another user's daily-entry report, and unresolved comments surface through a
  `Review Comments` TODO filter plus a dashboard notification card.
- `PASS` Focused analyzer passed over the touched database, TODO, auth,
  dashboard, and entry screen/app-bar files. Focused TODO tests passed `138`
  tests and schema verifier tests passed `11` tests.
- `OPEN` Supabase remote migration application is blocked by invalid/missing
  remote DB credentials in this shell; `supabase migration list` fails with
  pooler password authentication failure. A PostgREST schema probe also
  returned Postgres `42703` for `todo_items.assigned_to_user_id`, confirming
  the remote schema is not migrated. Real-device synced review-comment
  validation remains open until the migration is applied, and the current
  review-comment build should not be used for sync validation before that.

## Latest Real-Auth Samsung Build Checkpoint - 2026-04-11 04:15 ET

- `PASS` Driver-enabled real-auth APK built without `MOCK_AUTH` using
  `flutter build apk --debug --target=lib/main_driver.dart
  --dart-define=DEBUG_SERVER=true --dart-define-from-file=.env`.
- `PASS` Installed APK SHA-256:
  `DF2159E48E84BB310E80E92D5A02CE2E8C6A9F7933A53F4474634D2562E5A75A`.
- `PASS` Samsung package proof: `RFCNC0Y975L`,
  `com.fieldguideapp.inspector`, `versionCode=3`, `versionName=0.1.2`,
  `lastUpdateTime=2026-04-11 04:12:44`.
- `PASS` Driver proof: host forward `tcp:4948`; `/driver/ready` returned
  ready at route `/projects`, and the visible real session shows
  `Springfield DWSRF`.
- `PASS` Screenshot proof:
  `.codex/artifacts/2026-04-11/device_screens/post_review_comment_build_projects.png`,
  SHA-256
  `6B9BEB54A1B152FED022EE34BD26697B88CC23211C3061D15B638CB29A116073`.
- `PARTIAL` Slow launch/resume lane remains open: clean launch reported
  `LaunchState=COLD`, `TotalTime=5103`, `WaitTime=5105`.
- `OPEN` Remote review-comment sync validation remains blocked until the
  Supabase migration adds `todo_items.assigned_to_user_id`, `source_type`, and
  `source_id`; local/device smoke checks may continue, but synced review
  comments must not be marked verified yet.

## Review Comment Privacy/Permission Follow-Up - 2026-04-11 04:22 ET

- `PASS` Completeness-agent review found two open review-comment risks:
  inspector-facing TODO counts/lists needed assignment scoping, and one review
  screen used `canManageProjects` instead of the narrower review permission.
- `PASS` Review-comment queries/counts now accept `assignedToUserId` and apply
  `assigned_to_user_id = currentUserId()` in the datasource/repository/use-case
  path; reviewer-created comments assigned to another inspector are not shown
  in the reviewer TODO list.
- `PASS` `EntryReviewScreen` now requires `canReviewInspectorWork` and a
  different entry owner before exposing `Add Review Comment`.
- `PASS` Verification: focused analyzer passed over the touched TODO/entry
  files, and focused TODO provider/screen tests passed `61` tests.
- `OPEN` The installed Samsung APK predates this follow-up; rebuild/reinstall
  is required before marking review-comment UI/device verification current.

## Current Real-Auth Samsung Rebuild - 2026-04-11 04:25 ET

- `PASS` Review-comment privacy/permission patch was rebuilt and reinstalled
  on Samsung `RFCNC0Y975L` without `MOCK_AUTH`.
- `PASS` Installed APK SHA-256:
  `012940247128654116592E86F5FA7E2F61435ED2AAF0F13F260E484C0400C607`;
  package `lastUpdateTime=2026-04-11 04:23:59`, `versionCode=3`,
  `versionName=0.1.2`.
- `PASS` Driver proof: port `4948`, route `/projects`, screenshot
  `.codex/artifacts/2026-04-11/device_screens/post_review_privacy_build_projects.png`,
  SHA-256
  `8C823C60107AB213BAA0C5976861AB5CCB214DD155035CF7A33236C9A51AD1D7`.
- `PASS` Sync queue proof: `/driver/sync-status` returned
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`, and
  `isSyncing=false`.
- `PASS` Current-device calculator/TODO UI smoke remains green after the
  rebuild; `queryFilter_reviewComments` exists and is visible on the To-Do
  route.
- `PARTIAL` Slow launch lane remains open: launch still reported
  `LaunchState=COLD`, `TotalTime=4875`, `WaitTime=4878`.
- `PARTIAL` Current 10-second warm-resume smoke is fast: `LaunchState=HOT`,
  `TotalTime=78`, `WaitTime=80`, route `/todos`, and sync queue
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`. This does not
  close the longer bad-sync/background resume gate.
- `OPEN` Remote review-comment sync validation remains blocked until Supabase
  migration credentials are available and the pending migrations are applied.

## 1174R Device Automation Probe - 2026-04-11 04:34 ET

- `PARTIAL / FAILED GATE` A production 1174R form was created on the current
  Samsung build via `/form/new/mdot_1174r`, redirecting to
  `/form/f387e636-a571-41cd-8f59-abedde7470cd`.
- `PARTIAL` The UI row composer successfully wrote Air/Slump rows into the live
  `form_responses.response_data.air_slump_pairs` record, proving the add-row
  button path reaches persisted form data on-device.
- `FAILED` This pass cannot close the full-capacity 1174R gate: automation
  produced one invalid timestamp (`08:80`) and only three of five Air/Slump rows
  were populated in the device DB probe. It must be rerun from a fresh response
  with per-row DB verification after each Add tap before export.
- `PASS` Cleanup completed before sync: the failed probe response
  `f387e636-a571-41cd-8f59-abedde7470cd` and its change-log rows were removed
  from the local Samsung DB while the app was stopped. After relaunch,
  `/driver/sync-status` settled at `pendingCount=0`, `blockedCount=0`, and
  `unprocessedCount=0`.
