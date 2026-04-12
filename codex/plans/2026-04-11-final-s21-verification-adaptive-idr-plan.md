# Final S21 Verification And Editable Adaptive IDR Plan

## Summary

This is the current canonical completion plan for the pay-app, form-fidelity,
Daily Entry/IDR, and contractor-access lane. Execute only with real auth and
real backend state on Samsung `RFCNC0Y975L`; do not use `MOCK_AUTH`.

## Locked Requirements

- Inspectors can add and edit project field data, including contractors,
  equipment, and personnel types.
- Inspectors cannot create, delete, archive, or manage the lifecycle of
  projects.
- Daily Entry/IDR adaptive export must remain editable after export. Do not
  flatten fields and do not make overlay text the only data source.
- Springfield Daily Entry/IDR full-capacity verification data must have at
  least five realistic equipment records for each active contractor before
  validating the contractor/equipment PDF rows.
- Keep the official fixed-template IDR AcroForm export as the fidelity baseline
  until an editable adaptive path is proven.
- Continue preserving editable exported fields, original field formatting, and
  no double-written text for 0582B, 1126, 1174R, and Daily Entry/IDR.

## Existing TODOs Carried Forward

- Finish Daily Entry/IDR full-capacity all-cell verification: activity
  continuation, all contractor sections, personnel rows, equipment rows and
  checks, quantities/materials, attachments, signature, extras, preview, export,
  and exported editability.
- Reconfirm 0582B, 1126, and 1174R on the final S21 build: every mapped
  cell/row/control filled through UI, read-only preview, editable export,
  original formatting, no double text.
- Finish Springfield pay-app verification: 20 realistic daily entries, 100
  entry quantities, all project bid items, G703-style single-sheet running
  ledger, contractor comparison Excel/OCR import parity, report export, and
  natural item ordering evidence.
- Preserve natural item-number ordering anywhere quantity/pay items are shown or
  exported.
- Complete Office Technician role verification: can create projects, assign
  inspectors, and review inspector entries.
- Complete review-comment TODO verification after backend migration: comments
  land in inspector TODOs/dashboard, assigned-user filtering is correct, and
  sync works remotely.
- Verify attached photo-name editing, the bounded daily-entry personnel-type
  picker, HMA Yield Calculator, HMA weighback calculator, and concrete area /
  volume Calculator on the final S21 build.

## Implementation Plan

- Add a field-data project setup permission backed by approved
  `canEditFieldData`; keep project lifecycle controls on `canManageProjects`.
- Allow inspectors through assigned project setup field-data tabs and enable
  contractor/equipment/personnel CRUD through the existing production providers.
- Keep project details read-only and assignment/project lifecycle actions
  inaccessible for inspectors.
- Add or spike an editable adaptive IDR export path separately from the current
  official fixed-template writer; if exact fixed artwork conflicts with dynamic
  row reflow, keep the official export as fallback and use an editable generated
  or variant AcroForm for compact adaptive output.
- Rebuild/install a real-auth driver APK and execute the final S21 e2e gates.
- Expand Springfield contractor setup data so each active contractor has at
  least five pieces of realistic equipment, sync cleanly, then use those
  records in the IDR equipment-row validation.

## Verification Gate

- Local: focused analyzer, role/route/provider tests, all-form PDF mapping
  matrix, IDR editable-field tests, pay-app workbook/comparison tests,
  ordering tests, calculator tests.
- Device: fill/export/inspect 0582B, 1126, 1174R, and Daily Entry/IDR through
  UI on Samsung `RFCNC0Y975L`.
- Evidence: save APK hash, install time, screenshots, exported PDFs/workbooks,
  field inventories, parsed value proof, DB proof, and sync-status logs under
  `.codex/artifacts/2026-04-11/`.
- Close only after self-review and a separate completeness-agent review confirm
  the spec intent and S21 evidence are complete.

## Progress Checkpoint - 2026-04-11 12:09 ET

- `PASS` Local inspector field-data permission work is implemented behind
  `canManageProjectFieldData`; project lifecycle actions remain gated by
  `canManageProjects`.
- `PASS` Local Daily Entry contractor card now supports creating a project
  contractor through production providers from the entry workflow.
- `PASS` Editable adaptive IDR spike preserves the official fixed-template
  export path and only removes the unused continuation page when all page-three
  fields are empty. It does not replace the official fixed-template baseline.
- `PASS` Repaired a regression in the local IDR capacity map:
  `hhhhhhhhhhhwerwer` remains a prime-contractor equipment field while the
  visible signature writes to the actual `Signature` field.
- `PASS` Local gates passed:
  `flutter test test\features\forms\services\form_export_mapping_matrix_test.dart`;
  `flutter test test\core\router\app_redirect_test.dart test\features\auth\data\models\user_role_test.dart test\features\projects\presentation\screens\project_setup_screen_test.dart`;
  focused analyzer over the touched auth/project/entry/PDF files.
- `OPEN` Final real-auth S21 build/install and e2e device proof are still
  required before closure.

## Device Checkpoint - 2026-04-11 12:19 ET

- `PASS` Fresh real-auth Samsung driver build installed without `MOCK_AUTH`:
  APK SHA-256
  `1B773247A30F6787993570C9381045419AAADB4F40039560BDB3EB6CA834A3EB`,
  `lastUpdateTime=2026-04-11 12:11:30`, `/driver/ready` on port `4948`
  returned `/projects`.
- `PASS` Inspector account can open assigned Springfield project edit route:
  `/project/75ae3283-d4b2-4035-ba2f-7b4adb018199/edit`.
- `PASS` Inspector account remains blocked from project creation:
  navigating to `/project/new` redirects back to `/projects`.
- `PASS` Inspector created Springfield contractors through the real project
  contractor UI and synced them cleanly: `Miller Trucking` and
  `River City Restoration`.
- `PASS` Inspector created equipment through the real project contractor UI
  and synced it cleanly: `Tri-Axle Dump Truck` for Miller Trucking and
  `Skid Steer Loader` for River City Restoration.
- `PASS` S21 DB proof in
  `.codex/artifacts/2026-04-11/s21_121925_construction_inspector.db` shows
  five active Springfield contractors and pending change-log count `0`;
  `/driver/sync-status` reports pending/blocked/unprocessed all `0`.
- `OPEN` Remaining gates still need device execution: IDR full-capacity
  all-cell UI fill/export with the now-available five contractors; final
  0582B/1126/1174R reverification on this build; Springfield pay-app workbook
  and contractor-comparison verification; calculator/photo/comment follow-ups.

## Device Checkpoint - 2026-04-11 12:40 ET

- `PASS` Rebuilt and reinstalled the real-auth driver APK after adding
  `equipment` to the existing debug create-record allowlist; this remains a
  real-auth build and does not use `MOCK_AUTH`.
- `PASS` APK SHA-256
  `69A6518CA06A3A2D5AC6798FA4A8D5505C991E23118692C85FCDD2F8B2F325E9`,
  `lastUpdateTime=2026-04-11 12:36:03`, `/driver/ready` returned `/projects`.
- `PASS` Springfield contractor setup data now satisfies the new realism gate:
  five active contractors and five active equipment records under each
  contractor. DB proof is saved at
  `.codex/artifacts/2026-04-11/s21_1240_equipment_five_each.db`.
- `PASS` `/driver/sync` pushed the 17 newly added equipment records and settled
  with pending/blocked/unprocessed all `0`.
- `OPEN` Continue IDR full-capacity contractor/equipment UI row verification
  using the expanded equipment data.
