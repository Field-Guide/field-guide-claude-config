# Pay-App, Form Fidelity, And Ordering Verification Spec

## Summary

This is the active completion spec for the pay-app, contractor-comparison,
quantity-ordering, and all-cell form-fidelity lane. Execute with real auth only
on Samsung `RFCNC0Y975L`; do not use `MOCK_AUTH`.

Priority order:

1. Finish pay-app e2e verification.
2. Fix contractor-comparison performance and quantity item-number ordering.
3. Fill every cell/AcroForm field for Daily Entry/IDR, 0582B, 1174R, and 1126
   through the UI and verify preview/export mapping.
4. Append and track the new role/comment/photo/calculator issues as follow-on
   TODOs unless they block the active verification lane.

## Active Fixes

- Contractor comparison must not render all 131 imported rows as heavyweight
  `DataTable` widgets. Use a lazy/bounded review layout that keeps summary,
  manual review, discrepancy details, and export actions reachable after a full
  scroll.
- Quantity/pay item numbers must display in natural human order everywhere, not
  plain string order or import order. Keep item numbers stored as strings, but
  route display/export sorting through the shared natural comparator.
- Before-fix evidence for out-of-order quantity items was captured at
  `.codex/artifacts/2026-04-11/device_screens/current_quantity_order_issue.png`
  and `.codex/artifacts/2026-04-11/device_screens/current_quantity_order_issue.xml`.
- Initial ordering audit found mixed behavior: `BidItemProvider`, the quantity
  screen, G703 workbook builder, and batch import use `naturalCompare`; the
  individual pay-app export use case, contractor-comparison daily rows, and
  contractor-comparison main list used string/import-order behavior.

## Pay-App Verification Gate

- Continue from the existing Springfield state: 20 realistic daily entries,
  100 entry quantities, 131 bid items, Pay Apps #1-#3, and one-sheet
  `G703 Ledger`.
- Import the golden contractor Excel artifact and the OCR/PDF-derived
  contractor artifact through the real app flow.
- Verify both import paths produce the same expected discrepancy set and export
  a comparison report.
- Save screenshots, pulled report/workbook artifacts, DB proof, and parsed
  discrepancy proof under `.codex/artifacts/2026-04-11/contractor_comparison/`.

## All-Cell Form Fidelity Gate

- For Daily Entry/IDR, 0582B, 1174R, and 1126, use the app UI to populate every
  mapped row, cell, checkbox/control, standards cell, remarks/continuation cell,
  and table row capacity.
- For Daily Entry/IDR contractor/equipment capacity proof, Springfield must have
  at least five realistic equipment records under each active contractor before
  the entry row fill/export gate is accepted.
- Verify preview is read-only and usable.
- Verify exports preserve editable AcroForm fields, do not double-write overlay
  text, and land values in the original PDF fields with original formatting.
- Save preview screenshots, exported PDFs, field inventory comparisons, and
  representative filled-value proof under
  `.codex/artifacts/2026-04-11/final_form_fillout/`.

## Appended TODOs

- Add `Office Technician` role. This role can create projects, assign
  inspectors to projects, and review inspector work like engineers.
- Add synced review comments. Engineers and Office Technicians can comment on
  inspector work; comments surface in an inspector TODO tab/list and a
  dashboard notification card until addressed.
- Allow attached photo names to be edited by tapping/clicking the attached name.
- Make the daily-entry contractor personnel-type picker use the same contained
  scroll-list behavior as equipment types.
- Change HMA calculator to `HMA Yield Calculator`, remove density input, assume
  `110 lb / sq yd / 1 inch`, and support multiple length/width segments.
- Add HMA weighback calculator using the last calculated yield by default, or a
  manually entered yield, with remaining length/width to estimate remaining
  tonnage.
- Rename the concrete calculator UI to `Calculator` and make it an interactive
  area/volume calculator with `cft`/`cyd` and `sft`/`syd` switching.

## Tests And Evidence

- Add local regression coverage for contractor comparison row ordering, 131-row
  lazy rendering, Excel/PDF import parity, and report export.
- Add ordering tests with string-sort traps such as `1`, `2`, `10`, `100`,
  `1000`, `10000`, and dotted item numbers.
- Keep workbook, form mapping, pay-app export, and focused analyzer gates green.
- Rebuild with `flutter build apk --debug --dart-define-from-file=.env`,
  install to Samsung `RFCNC0Y975L`, and record APK hash/install time.
- Capture before/after screenshots proving item numbers now appear in natural
  order on affected screens.
- Update `.codex/artifacts/2026-04-11/evidence_manifest.md` with commands,
  logs, screenshots, DB pulls, workbook/report/PDF paths, and pass/fail status.
- Completion requires self-review against this spec and a separate completeness
  agent review. If either finds missing intent or missing device evidence,
  continue implementation and repeat the review loop.

## Implementation Checkpoint - 2026-04-11 03:11 ET

- `PASS` Contractor comparison real-app gate is closed for Excel and OCR/PDF
  import parity, lazy bounded rendering, natural row order in the comparison
  details, and report export from both import paths. Evidence is saved under
  `.codex/artifacts/2026-04-11/contractor_comparison/`.
- `PASS` Shared bid-item ordering was moved into `BidItemRepositoryImpl` for
  `getAll`, `getByProjectId`, `search`, `getByProjectIdPaged`, and `getPaged`;
  paged methods now natural-sort before slicing the requested page.
- `PASS` Import deduplication fallback ordering now uses the shared natural
  comparator instead of string compare for alphanumeric item numbers.
- `PASS` Focused local verification passed:
  `flutter test test/features/quantities/data/repositories/bid_item_repository_impl_test.dart test/features/pdf/extraction/stages/item_deduplicator_test.dart test/features/pay_applications/presentation/providers/contractor_comparison_provider_test.dart test/features/pay_applications/presentation/widgets/manual_match_editor_test.dart`
  and focused `flutter analyze` over the impacted implementation/test files.
- `PASS` Latest ordering patch was rebuilt/reinstalled on `RFCNC0Y975L`; APK
  SHA-256 `D03C6405FD32C9E4FFC0F3D9BF61E706646904140AAB9904FE63B91A29E327E2`,
  package `lastUpdateTime=2026-04-11 03:12:53`. The after screenshot/hierarchy
  show the real Springfield Pay Items screen with `131 items` and first visible
  item numbers `1`, `2`, `3`, `4`, `5`.
- `OPEN` Full-capacity all-cell form fidelity verification remains the next
  primary gate after the ordering device screenshot: 0582B, 1174R, 1126, and
  Daily Entry/IDR must each be filled through the app UI to mapped PDF capacity
  and verified in preview/export.

## 0582B Missing-Field Closure - 2026-04-11 09:30 ET

- `PASS` The reported 0582B blank fields were implemented and verified on the
  real-auth Samsung build: agency/company, remarks 1-3, typed signature, and
  all five `20/10` weight cells.
- `PASS` Device UI proof shows the header fields saved through the hub and a
  sixth proctor row appended through the production Proctor section with
  `weights_20_10=["4700","4706","4712","4718","4724"]`.
- `PASS` Export proof is saved at
  `.codex/artifacts/2026-04-11/final_form_fillout/device_0582b_all_cell/MDOT_0582B_2026-04-11_83d288a5_after_missing_fields.pdf`
  with SHA-256
  `5E116D72D193162356EA55431175ECEFEFB590110F4D49FB4C88284B4566C7F4`.
- `PASS` The exported PDF preserves the shipped AcroForm inventory:
  `exportFieldCount=269`, `templateFieldCount=269`, and
  `fieldNamesEqual=true`. Named-field inspection confirms `Signature1` remains
  a `PdfSignatureField`; agency/company, remarks, and `1st`-`5th` weights are
  editable text fields.
- `PASS` Representative no-double-write proof via `pdftotext` recorded exactly
  one occurrence each for the agency/company value, remarks values, five weight
  values, and chart/operating standard values.
- `OPEN` This closes the latest 0582B missing-field report only. The broader
  all-form UI-driven gate remains open for 1126 and Daily Entry/IDR, and 1174R
  still needs a fresh full-capacity rerun after the failed probe cleanup.

## 1126 Rerun Checkpoint - 2026-04-11 09:55 ET

- `FAILED GATE / OPEN` 1126 is not complete.
- `PASS` Added stable 1126 workflow/field keys and fixed the stale-response
  overwrite defect found on device. The fix makes 1126 patch helpers merge
  onto the latest provider response instead of a widget-captured stale response.
- `PASS` Focused local verification is green after the 1126 key and stale-patch
  repairs: targeted analyzer over the 1126 screen/steps and targeted widget
  tests passed.
- `FAILED` Device evidence showed seven SESC measure rows could be created
  through the UI, but a later section patch collapsed the saved response back
  to one row before the stale-patch fix. The exported artifact therefore only
  contains row 1 and must not be accepted.
- `FAILED` The saved record had a `signature_audit_id`, but the phone UI still
  showed the Signature section as `Not Started`; rerun must verify state reaches
  back to the UI before accepting 1126.
- `OPEN` Rerun 1126 on a fresh response after the stale-patch repair: fill
  header/context, create and fill all seven SESC measure rows, sign, verify the
  UI reports the signature complete, preview, export, and inspect every row
  against the shipped 1126 template.

## Implementation Checkpoint - 2026-04-11 03:43 ET

- `PASS` Real-auth driver-enabled Samsung build was created without
  `MOCK_AUTH`/`MOCK_DATA`; APK SHA-256
  `81A2D9DA5E55597510ACF74652FEE5B64842DD4F7D30385C977725288BE97943`,
  package `lastUpdateTime=2026-04-11 03:26:45`, `versionCode=3`,
  `versionName=0.1.2`. The debug driver server fell back to port `45045`
  because device port `4948` was occupied; host forwarding was corrected with
  `adb forward tcp:45045 tcp:45045`, and `/driver/ready` reported
  `{"ready":true,"screen":"/projects"}`.
- `PARTIAL` 0582B real-device UI path is verified for one proctor and one test
  row through the production form route
  `/form/d7700c3d-2550-49ea-ad1c-137d1d8c9bb0`: header, chart-density range
  boxes, chart-moisture range boxes, single operating standards, weights,
  quick-test item selection, send-to-form, preview, and export all executed on
  the Samsung build. Evidence is under
  `.codex/artifacts/2026-04-11/final_form_fillout/`, including
  `device_driver_0582b_preview.png`,
  `device_driver_0582b_after_send_test.png`, and pulled export
  `MDOT_0582B_2026-04-11_driver_export.pdf` with SHA-256
  `999B775FCC3EA16145DCDD244A81BEEC6AE551F926BF45C3A613364EF4D6B4B8`.
- `PASS` 0582B log proof from preview/export shows AcroForm `/V` writes rather
  than overlay text for the tested row and standards cells, including
  `1Row1=1`, `3Row1=12`, `4Row1=275`, `5Row1=258`, `6Row1=327.0`,
  `7Row1=425.0`, `8Row1=401.7`, `9Row1=5.8`, `10Row1=121.7`,
  `11Row1=330.1`, `12Row1=55+85`, `13Row1=15`, `15Row1=1`, `16Row1=SG`,
  `ARow1=1`, `BRow1=8`, `CRow1=.0439`, `DRow1=4608`, `ERow1=2006`,
  `FRow1=2602`, `GRow1=5.74`, `HRow1=130.7`, `IRow1=121.7`, `JRow1=11.4`,
  range cells `DENSITYRow1=425.0`, `DENSITYRow2=475.0`,
  `MOISTURERow1=450.0`, `MOISTURERow2=502.0`, and operating cells
  `DENSITYRow1_2=325.0`, `MOISTURERow1_2=327.0`.
- `PASS` Local full-capacity mapping matrix was refreshed with
  `flutter test --dart-define=WRITE_PDF_ARTIFACTS=true test/features/forms/services/form_export_mapping_matrix_test.dart`;
  all `24` tests passed and regenerated full-capacity editable exports plus
  read-only previews for `0582B`, `1126`, `1174R`, and `IDR` under
  `.codex/artifacts/2026-04-11/final_form_fillout/local_all_cell/`.
- `OPEN` Device full-capacity form gate remains incomplete. The local matrix
  proves field mapping/export seams, but the spec still requires UI-driven
  full-capacity validation on Samsung for every mapped cell/row in 0582B,
  1174R, 1126, and Daily Entry/IDR, followed by preview/export proof for each.

## Implementation Checkpoint - 2026-04-11 03:50 ET

- `PASS` IDR local mapping regression was expanded so the all-cell matrix now
  asserts all five contractor sections, personnel counts, mapped used-equipment
  rows and checkboxes, long-activity `Text3`/`Text4` split, quantities,
  photo/form attachment text, and sparse-clear behavior. This remains local
  writer/export proof, not a replacement for Samsung UI-driven full-capacity
  validation.
- `PARTIAL` Calculator TODO implementation started: HMA now presents as
  `HMA Yield Calculator`, removes the density field from the dedicated and
  entry quantity calculator UIs, and calculates using the standard
  `110 lb / sq yd / inch` yield assumption. The old `density_pcf` input remains
  readable only for saved-history compatibility and is ignored by the current
  calculation.
- `PARTIAL` Concrete calculator naming was adjusted so the user-facing tab
  presents as `Calculator`/`Area / Volume Calculator` instead of `Concrete`.
  Remaining calculator work still open: multi-segment HMA input, HMA weighback
  calculator, and fuller unit switching for `cft`/`cyd` and `sft`/`syd`.
- `PASS` Focused local verification passed after the patch:
  `flutter test test/features/calculator/services/calculator_service_test.dart test/features/calculator/presentation/screens/calculator_screen_test.dart test/features/forms/services/form_export_mapping_matrix_test.dart`
  completed `67` tests with `All tests passed!`.
- `PASS` Focused analyzer over the changed calculator, quantity calculator,
  and form mapping test files reported `No issues found`.

### Calculator Follow-Up - 2026-04-11 03:54 ET

- `PASS` Dedicated HMA calculator now supports multiple length/width segments
  and a weighback estimate card. Weighback uses the last calculated HMA
  tons/SY yield by default or a manually entered tons/SY yield, plus remaining
  length and width, to estimate remaining tons.
- `PASS` Focused calculator verification after the multi-segment/weighback UI
  patch: `flutter test test/features/calculator/services/calculator_service_test.dart test/features/calculator/presentation/screens/calculator_screen_test.dart`
  passed `43` tests, and focused analyzer over the HMA tab, calculator service,
  and calculator tests reported `No issues found`.
- `OPEN` Calculator device verification remains pending on the next Samsung
  build/install; the implementation is locally green but not yet verified on
  device.

### Concrete Calculator Follow-Up - 2026-04-11 04:05 ET

- `PASS` Dedicated concrete calculator now behaves as a general
  area/volume `Calculator`: users enter length, width, and thickness, then
  choose area output units (`SY`/`SF`) and volume output units (`CY`/`CF`).
  Changing units after a calculation recomputes the visible result without
  requiring the user to re-enter dimensions.
- `PASS` Focused calculator verification after the unit-switching patch:
  `flutter test test/features/calculator/services/calculator_service_test.dart test/features/calculator/presentation/screens/calculator_screen_test.dart`
  passed `43` tests, and `flutter analyze
  lib/features/calculator/presentation/widgets/concrete_calculator_tab.dart`
  reported `No issues found`.
- `OPEN` Calculator device verification remains pending on the next Samsung
  build/install; the implementation is locally green but not yet verified on
  device.

## Daily Entry UX Checkpoint - 2026-04-11 03:58 ET

- `PASS` Attached photo name/caption text now opens the same photo detail edit
  flow as tapping the thumbnail image, so users can tap the visible attached
  name to edit filename/details after attachment.
- `PASS` Daily-entry contractor personnel type management now uses the same
  bounded scroll container pattern as equipment management, including keyboard-
  aware max height, scroll hint, decorated contained list, scrollbar, and
  `ListView.separated`.
- `PASS` Focused analyzer over
  `lib/features/photos/presentation/widgets/photo_thumbnail.dart` and
  `lib/features/entries/presentation/widgets/personnel_type_manager_dialog.dart`
  reported `No issues found`.
- `OPEN` These UX changes still need inclusion in the next real-device
  build/install and Samsung verification pass.

## Office Technician Role Checkpoint - 2026-04-11 04:00 ET

- `PASS` Local app model/UI implementation added `UserRole.officeTechnician`
  with wire value `office_technician`, display label `Office Technician`, and
  project-management permissions through `canManageProjects`.
- `PASS` Admin role assignment surfaces now include Office Technician in
  approval and member role-change UI, and assignment role badges render the
  role label.
- `PASS` Supabase migration
  `supabase/migrations/20260411040000_add_office_technician_role.sql` updates
  the `user_profiles` role check constraint, lets admins assign/update the
  role, and expands `is_admin_or_engineer()` to treat `office_technician` as a
  project/assignment manager while keeping admin-only account controls admin
  gated.
- `PASS` Focused tests:
  `flutter test test/features/auth/data/models/user_role_test.dart test/features/projects/presentation/providers/project_assignment_provider_test.dart`
  passed `32` tests.
- `PASS` Focused analyzer over the touched auth/settings/project role files
  reported `No issues found`.
- `OPEN` Backend migration application and real-device role verification remain
  pending.

## Review Comments/TODO Checkpoint - 2026-04-11 04:10 ET

- `PASS` Local implementation added synced review comments as typed
  `todo_items` rows instead of a parallel comment table. Review comments use
  `source_type='review_comment'`, `source_id`, and `assigned_to_user_id`, so
  they reuse existing project-scoped TODO sync, RLS, soft-delete, and inspector
  completion/addressing behavior.
- `PASS` Engineers/admins/Office Technicians can add a review comment from the
  entry review flow. The resulting item appears in To-Do's with a review badge
  and a dedicated `Review Comments` query chip; inspectors can mark it complete
  when addressed.
- `PASS` Dashboard now loads project TODOs with dashboard data and shows a
  notification card while open review comments exist; tapping it opens To-Do's.
- `PASS` Local schema and Supabase migration coverage added review-comment
  metadata columns to `todo_items`; database version advanced to `60`.
  Rollback coverage now passes for enforced migrations, including the prior
  pay-application/support-ticket migrations that were missing rollback files.
- `PASS` Focused verification:
  `flutter test test/features/todos/data/models/todo_item_test.dart test/features/todos/presentation/providers/todo_provider_filter_test.dart test/features/todos/presentation/screens/todos_screen_test.dart test/core/database/database_service_test.dart`
  passed `130` tests; `flutter test
  test/features/todos/data/datasources/todo_item_local_datasource_test.dart`
  passed `35` tests; focused analyzer over touched TODO/dashboard/entry/database
  files reported `No issues found`; `python
  scripts/validate_migration_rollbacks.py` passed.
- `OPEN` Backend migration application and real-device review-comment
  verification remain pending.

## Review Comment TODO Checkpoint - 2026-04-11 04:10 ET

- `PASS` Local app implementation now uses synced `todo_items` rows for
  review comments instead of a parallel comments table. Review-comment TODOs
  carry `assigned_to_user_id`, `source_type = review_comment`, and
  `source_id = entryId`, keeping project sync/RLS/soft-delete behavior on the
  existing TODO surface.
- `PASS` Engineers and Office Technicians now have
  `AuthProvider.canReviewInspectorWork`; when viewing another user's daily
  entry, the report app-bar exposes `Add Review Comment` and creates a
  high-priority review-comment TODO assigned to the entry creator.
- `PASS` Inspector-facing surfaces now include a `Review Comments` TODO filter
  chip and a project-dashboard notification card while unresolved review
  comments are loaded for the active project.
- `PASS` Local DB v60 migration and fresh schema add the review-comment TODO
  metadata columns and indexes; remote migration file
  `supabase/migrations/20260411040500_todo_review_comment_metadata.sql` was
  added.
- `PASS` Local verification: focused analyzer over the database, TODO, entry
  app-bar/screen, dashboard, and auth provider slices reported `No issues
  found`; focused TODO tests passed `138` tests; schema verifier tests passed
  `11` tests.
- `OPEN` Remote Supabase application is blocked: `supabase migration list`
  failed with `password authentication failed` for the linked Postgres pooler
  user, and no `SUPABASE_DB_PASSWORD`, `PGPASSWORD`, or `DATABASE_URL` is set
  in this shell. This must be applied before real synced review comments can
  be verified on the Samsung device against remote state.
- `OPEN` Remote schema absence was also confirmed via anon REST: selecting
  `assigned_to_user_id`, `source_type`, and `source_id` from `todo_items`
  returned Postgres `42703` because `assigned_to_user_id` does not exist.
  Do not install a sync-validating Samsung build with the review-comment TODO
  metadata enabled until the backend migration is applied.
- `OPEN` Real-device review-comment verification remains pending on the next
  Samsung build/install after backend migration credentials are restored.

## Latest Real-Auth Samsung Build Checkpoint - 2026-04-11 04:15 ET

- `PASS` Stale device transports were cleared before install with
  `adb -s RFCNC0Y975L reverse --remove-all`, `adb -s RFCNC0Y975L forward
  --remove-all`, and app force-stop.
- `PASS` Driver-enabled real-auth APK was built without `MOCK_AUTH` using
  `flutter build apk --debug --target=lib/main_driver.dart
  --dart-define=DEBUG_SERVER=true --dart-define-from-file=.env`; APK SHA-256
  `DF2159E48E84BB310E80E92D5A02CE2E8C6A9F7933A53F4474634D2562E5A75A`.
- `PASS` APK installed to Samsung `RFCNC0Y975L`; package
  `com.fieldguideapp.inspector`, `versionCode=3`, `versionName=0.1.2`,
  authoritative `lastUpdateTime=2026-04-11 04:12:44`.
- `PASS` Clean launch reached driver route `/projects` with the real session
  showing `Springfield DWSRF`; driver port `4948` returned
  `{ "ready": true, "screen": "/projects" }`.
- `PASS` Device screenshot proof saved at
  `.codex/artifacts/2026-04-11/device_screens/post_review_comment_build_projects.png`
  with SHA-256
  `6B9BEB54A1B152FED022EE34BD26697B88CC23211C3061D15B638CB29A116073`.
- `PARTIAL` Launch/resume performance remains open: clean app start reported
  `LaunchState=COLD`, `TotalTime=5103`, `WaitTime=5105`, so the slow open
  lane is not closed.
- `OPEN` This build must not be used to validate remote review-comment sync
  until the Supabase review-comment TODO metadata migration is applied; local
  schema is version `60`, while remote anon REST still reports missing
  `todo_items.assigned_to_user_id`.

## Review Comment Privacy/Permission Follow-Up - 2026-04-11 04:22 ET

- `PASS` Completeness-agent review found two spec-capture risks and no file
  edits: review-comment TODO queries/counts were project-scoped instead of
  assigned-inspector scoped, and `EntryReviewScreen` used broad
  `canManageProjects`.
- `PASS` Local implementation now passes `currentUserId()` into review-comment
  query/count use cases and filters by `assigned_to_user_id` at the datasource
  seam. Reviewer-created comments assigned to another inspector no longer get
  injected into the reviewer TODO state.
- `PASS` `EntryReviewScreen` now matches `EntryEditorScreen`: review comments
  require `AuthProvider.canReviewInspectorWork` and the entry must belong to a
  different user.
- `PASS` Focused verification:
  `flutter analyze` over the touched TODO/entry review files reported `No
  issues found`; `flutter test
  test/features/todos/presentation/providers/todo_provider_filter_test.dart
  test/features/todos/presentation/screens/todos_screen_test.dart` passed `61`
  tests.
- `OPEN` Latest Samsung APK installed at `2026-04-11 04:12:44` predates this
  follow-up patch, so review-comment device validation requires another
  real-auth rebuild/install.

## Current Real-Auth Samsung Rebuild - 2026-04-11 04:25 ET

- `PASS` Rebuilt and reinstalled the review-comment privacy/permission patch
  on Samsung `RFCNC0Y975L` without `MOCK_AUTH`.
- `PASS` Build command:
  `flutter build apk --debug --target=lib/main_driver.dart
  --dart-define=DEBUG_SERVER=true --dart-define-from-file=.env`; incremental
  build completed in about `17` seconds.
- `PASS` Installed APK SHA-256:
  `012940247128654116592E86F5FA7E2F61435ED2AAF0F13F260E484C0400C607`.
- `PASS` Package proof: `com.fieldguideapp.inspector`, `versionCode=3`,
  `versionName=0.1.2`, `lastUpdateTime=2026-04-11 04:23:59`.
- `PASS` Driver proof: port `4948`, `/driver/ready` returned ready at
  `/projects`; screenshot proof saved at
  `.codex/artifacts/2026-04-11/device_screens/post_review_privacy_build_projects.png`
  with SHA-256
  `8C823C60107AB213BAA0C5976861AB5CCB214DD155035CF7A33236C9A51AD1D7`.
- `PASS` Sync queue proof: `/driver/sync-status` returned `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`, `isSyncing=false`, and
  `lastSyncTime=2026-04-11T08:24:13.948229Z`.
- `PASS` Current-device calculator/TODO smoke proof after the rebuild:
  `current_calculator_hma_after_review_privacy_build.png`,
  `current_calculator_concrete_after_review_privacy_build.png`, and
  `current_todos_after_review_privacy_build.png`; the TODO chip find result
  confirms `queryFilter_reviewComments` exists and is visible.
- `PARTIAL` Launch/resume performance remains open: clean launch still reported
  `LaunchState=COLD`, `TotalTime=4875`, `WaitTime=4878`.
- `PARTIAL` A 10-second HOME/background warm-resume smoke on the current build
  was fast (`LaunchState=HOT`, `TotalTime=78`, `WaitTime=80`) with clean sync
  queue counts, but the longer bad-sync/background resume gate remains open.
- `OPEN` Remote Supabase review-comment sync validation remains blocked until
  the pending migrations are applied.

## 1174R Device Automation Probe - 2026-04-11 04:34 ET

- `PARTIAL / FAILED GATE` A current-build Samsung probe created a production
  1174R response via `/form/new/mdot_1174r` and reached the live row-composer
  UI.
- `PARTIAL` The Air/Slump add-row button persisted data into
  `form_responses.response_data.air_slump_pairs`, confirming the row composer
  appends to the form row data on-device.
- `FAILED` This specific run is not accepted as all-cell verification: one
  generated time value was invalid and only three of five Air/Slump rows were
  populated. Re-run from a fresh response and verify device DB row counts after
  every row append before exporting.
- `PASS` Failed-probe cleanup completed before sync: the response and its
  change-log rows were removed from the local Samsung DB, and settled
  `/driver/sync-status` returned `pendingCount=0`, `blockedCount=0`, and
  `unprocessedCount=0`.

## 1126 Full-Capacity Closure - 2026-04-11 10:12 ET

- `PASS` 1126 full-capacity device verification is closed for the current response `205a035e-5cc3-4e5a-8e14-9e55023b87e0`.
- `PASS` Device rerun found and repaired two production issues: signature state was not force-reloading after the signing use case updated storage, and blank SESC measure rows were being considered complete because the section status ignored type/location fields.
- `PASS` Real Samsung UI proof shows seven populated SESC rows persisted after signing, the Signature card reports `Complete`, preview is read-only, and export preserves the 62-field shipped AcroForm inventory with all seven SESC row values editable in the exported PDF.
- `OPEN` Continue the all-form gate with 1174R and Daily Entry/IDR; 0582B and 1126 now have current device-export evidence, but the final all-form/spec-completeness review remains open.

## 1174R Full-Capacity Closure - 2026-04-11 10:37 -04:00
- CLOSED/PASS for 1174R all-cell device lane using response 51d0a2de-a671-41eb-a42b-029c84c7d515.
- Production fixes included stale scalar patch protection in mdot_1174r_sections.dart and full-capacity row/remarks status completion in mdot_1174r_form_screen.dart.
- Targeted verification green: lutter analyze lib/features/forms/presentation/screens/mdot_1174r_form_screen.dart lib/features/forms/presentation/screens/mdot_1174r_sections.dart; lutter test test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart; exported-device PDF inspection via .codex/tmp/inspect_device_pdf_test.dart.
- Evidence is recorded in .codex/artifacts/2026-04-11/final_form_fillout/device_1174r_all_cell/.

## Daily Entry / IDR Device Checkpoint - 2026-04-11 11:30 -04:00
- `PARTIAL / OPEN` Daily Entry/IDR is not closed as full-capacity all-cell
  verification yet. Current UI-driven entry `73410791-f5ca-47df-8860-834a56e6a40c`
  exports correctly for the data available in the current inspector session,
  but it only has three active Springfield contractors, so contractor blocks
  four and five remain blank.
- `PASS` A real defect was found and fixed in
  `lib/features/pdf/services/idr_pdf_template_writer.dart`: the visible IDR
  signature is a `PdfSignatureField` named `Signature` on page 3, while
  `hhhhhhhhhhhwerwer` is a page 1 equipment text field. The writer now stamps
  the actual signature field bounds and no longer writes inspector text into
  the equipment row.
- `PASS` Latest real-auth Samsung build without `MOCK_AUTH` installed at
  `2026-04-11 11:27:23`; APK SHA-256
  `64E753FD33D7948A78727D06FEFA8F6ED02B4F80CE55FC28FEE105829E676095`.
- `PASS` Current device export evidence:
  `.codex/artifacts/2026-04-11/final_form_fillout/device_idr_all_cell/device_export_folder_after_signature_stamp/03-31-signature-stamp/IDR_03-31.pdf`,
  SHA-256 `D884214673D450B575E941F8FC445374F613118BBC367B22CEAD2EF73F6B8BDA`.
  Inspection shows `exportFieldCount=179`, `templateFieldCount=179`,
  `fieldNamesEqual=true`, and the `Signature` field remains a
  non-read-only `PdfSignatureField`.
- `PASS` Preview read-only proof for the patched build is saved at
  `.codex/artifacts/2026-04-11/final_form_fillout/device_idr_all_cell/preview_input_state_after_signature_stamp.txt`
  with `mInputShown=false` and `mServedInputConnection=null`.
- `OPEN` Remaining IDR full-capacity blockers: `Text4` continuation is blank
  because the current UI-entered activity narrative does not overflow, and
  contractor sections 4-5 are blank because project edit/add-contractor setup
  is role-blocked in this inspector session. Do not count IDR as fully closed
  until a real admin/Office Technician setup path adds sufficient project
  contractors/equipment or a fresh project-backed verification entry is created
  with five active contractors and overflow activity text through the UI.
- `PASS` Follow-up sync repair fixed the blocked photo upload caused by
  `Sta_55+00.jpg`: `PhotoAdapter` now sanitizes storage-validator unsafe
  filename characters and
  `RepairSyncStateV20260411PhotoStoragePaths` resets exhausted rows for retry.
  Latest real-auth Samsung build installed at `2026-04-11 11:36:12`; APK
  SHA-256 `09A55D1CC8989F1ED9E0B8B6C5D0715A3B334DDC8D4AFC62B7BD4D190EF90B05`.
  `/driver/sync-status` stayed clean for ten checks with `pendingCount=0`,
  `blockedCount=0`, and `unprocessedCount=0`.

## Final S21 / Editable Adaptive IDR Addendum - 2026-04-11

- `OPEN` Inspectors must be able to add/edit project field data, including
  contractors, equipment, and personnel types. Inspectors must still be blocked
  from project create/delete/archive/lifecycle actions.
- `OPEN` Daily Entry/IDR adaptive export must remain editable after export.
  Do not flatten fields and do not make overlay-only text the accepted export
  path.
- `OPEN` Keep the official fixed-template IDR AcroForm export as the fidelity
  baseline until an editable adaptive variant/generated AcroForm path is proven.
- `OPEN` Continue carrying all previous TODOs forward into the final S21 gate:
  Daily Entry/IDR full-capacity all-cell verification; 0582B, 1126, and 1174R
  final all-cell reverification; Springfield pay-app workbook/contractor
  comparison verification; natural item ordering; Office Technician role;
  review-comment TODO sync; photo-name editing; bounded personnel-type picker;
  HMA Yield and weighback calculators; concrete area/volume Calculator.
- `OPEN` Canonical final plan saved at
  `.codex/plans/2026-04-11-final-s21-verification-adaptive-idr-plan.md`.

## Final S21 Addendum Local Checkpoint - 2026-04-11 12:09 ET

- `PASS` Field-data permission split is locally implemented: inspectors can
  access project field-data editing surfaces, while project lifecycle actions
  stay on `canManageProjects`.
- `PASS` Daily Entry contractor card can create and add project contractors
  through the existing production contractor/personnel-entry providers.
- `PASS` Editable adaptive IDR spike is guarded and preserves editable
  AcroForm behavior; the official fixed-template export remains the baseline.
- `PASS` IDR full-capacity local mapping now keeps
  `hhhhhhhhhhhwerwer` as an equipment field and uses the actual `Signature`
  field for visible signing.
- `PASS` Local tests/analyzer passed for the touched role/route/project,
  entry-contractor, and PDF mapping surfaces. This is not device closure; final
  real-auth Samsung verification remains open.

## Final S21 Addendum Device Checkpoint - 2026-04-11 12:19 ET

- `PASS` Fresh real-auth driver build installed on Samsung `RFCNC0Y975L` with
  APK SHA-256
  `1B773247A30F6787993570C9381045419AAADB4F40039560BDB3EB6CA834A3EB`;
  `/driver/ready` returned `/projects` on port `4948`.
- `PASS` Inspector role can open assigned Springfield project field-data edit
  route and cannot open `/project/new`, which redirects to `/projects`.
- `PASS` Inspector role created two Springfield contractors via real UI:
  `Miller Trucking` and `River City Restoration`.
- `PASS` Inspector role created equipment via real UI:
  `Tri-Axle Dump Truck` and `Skid Steer Loader`.
- `PASS` Sync pushed the contractor/equipment changes and returned clean:
  pending/blocked/unprocessed `0`.
- `OPEN` This removes the IDR blocker for insufficient active contractors, but
  it does not close IDR all-cell proof; that full UI-driven fill/preview/export
  verification remains next.
- `OPEN` New realism requirement: expand each active Springfield contractor to
  at least five equipment records before accepting the IDR contractor/equipment
  row proof.

## Springfield Equipment Realism Checkpoint - 2026-04-11 12:40 ET

- `PASS` Each active Springfield contractor now has five realistic active
  equipment records on the S21: Hoffman Brothers, Lakeland Asphalt, Miller
  Trucking, River City Restoration, and T&D Concrete.
- `PASS` The new records were persisted through the app driver's SQLite
  create-record path and synced successfully: `/driver/sync` pushed `17` rows
  and `/driver/sync-status` returned pending/blocked/unprocessed all `0`.
- `OPEN` Use this expanded equipment data in the pending IDR all-cell
  contractor/equipment preview/export proof.
