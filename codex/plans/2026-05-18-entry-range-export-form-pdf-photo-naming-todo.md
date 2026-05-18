# Entry Range Export, Editable Form PDFs, Form Back Save, And Photo Naming Todo

## Audit Status - 2026-05-18

- Implementation is committed on `fix/entry-range-export-form-pdf-photo-naming`
  in five logical commits:
  - `f58427a0` documents the office-technician / Grand Blanc Test default.
  - `26a7c467` adds range exports and preserves user-entered photo names.
  - `c29a273a` keeps exported form PDFs editable and back-saves meaningful
    open form data.
  - `c984207c` keeps local-only export rows out of orphan purge.
  - `b10fa3ca` aligns the Entry editor driver contract with the existing photo
    delete overlay key used during live cleanup.
- Static and targeted automated verification are complete:
  - `flutter analyze`
  - `dart run custom_lint`
  - targeted entry export/photo naming tests
  - targeted form PDF/date/back-navigation tests
  - targeted sync orphan-purge test
- Desktop direct-save PDF verification is complete on the pulled Grand Blanc
  exported Water Main Pressure Test PDF: Microsoft Edge edited an AcroForm
  field, normal Save wrote back to the same file, and a reopen/raw-field read
  confirmed the new value persisted.
- Live S21 verification is complete with the required default target: real
  office technician auth/session on Grand Blanc Test project
  `6936f810-ec15-494e-b4aa-280bf3bf15d3` / project number `12344`.
- Final live proof includes range export, on-device MM-dd folders, editable
  exported form fields/date values, Android-back filled-form auto-save,
  Android-back blank-form prompt/discard, named photo attachment/export, manual
  full sync with `errors=0`, and clean app-only log scans.

## Summary
- [x] Preserve the current dirty Water Main Pressure Test work before starting this new work.
- [x] Add multi-day export from the project dashboard Entries flow by batching the existing daily-entry export output.
- [x] Ensure exported form PDFs keep editable AcroForm fields that persist desktop edits after save/reopen.
- [x] Fix date-picker PDF fields so app data is written into the actual PDF field value, not pasted as overlay text.
- [x] Auto-save nonblank in-progress forms on back navigation without showing the keep/save/discard prompt.
- [x] Standardize photo/attachment naming and include the user-added name in daily entry attachments and exports.

## Git Prep
- [x] Review current dirty tree on `main`.
- [x] Commit tracked Water Main Pressure Test changes in logical commit(s).
- [x] Exclude generated/temp artifacts from those commits:
  - `tmp/`
  - `tmp-device-state*.json`
  - `tools/pdf-tools/__pycache__/`
- [x] Create a new feature branch after the tree is preserved.
- [x] Use a branch name like `fix/entry-range-export-form-pdf-photo-naming`.

## Multi-Day Entry Export
- [x] Add a range export action to the Entries screen reached from the project dashboard Entries card/tab.
- [x] Use a date-range picker for selecting multiple days.
- [x] Export each matching entry using the existing single-entry daily bundle output.
- [x] Keep output shape unchanged: `MM-dd` folders under the selected project export folder.
- [x] Reuse the existing project export folder store and Android SAF document service.
- [x] Reuse the existing dated-folder exists behavior: replace, create copy, or cancel.
- [x] Add batch progress/final feedback showing successful days and failed days.
- [x] Avoid creating a combined PDF or a new folder structure.

## Editable Form PDFs
- [x] Keep preview PDFs flattened/read-only.
- [x] Keep exported PDFs unflattened with AcroForm fields preserved.
- [x] Update field-writing logic so writable template fields remain writable after export.
- [x] Preserve template read-only state only for fields that were already read-only/calculated.
- [x] Add reopen/save/reopen tests proving desktop-style PDF edits persist.
- [x] Verify daily entry bundles use the editable export bytes for attached forms, not flattened preview bytes.

## PDF Date Picker Fields
- [x] Trace date fields in shipped templates, especially MDOT 1126, MDOT 1174R, and Water Main Pressure Test.
- [x] Detect/handle PDF date-picker text fields by writing the actual AcroForm `/V` value.
- [x] Preserve field formatting, validation, and JavaScript actions where templates define them.
- [x] Normalize app date values to the format expected by the PDF field.
- [x] Add tests that reopen exported PDFs and verify date field values are stored in the actual field.

## Form Back Navigation
- [x] Create a shared "has meaningful form data" helper.
- [x] Treat blank open forms as prompt-worthy.
- [x] Treat open forms with any meaningful user-entered data as auto-save-on-back.
- [x] Apply this shared behavior to:
  - MDOT 0582B
  - MDOT 1126
  - MDOT 1174R
  - Water Main Pressure Test
  - generic Form Viewer
- [x] Keep attach-to-daily-entry behavior available where relevant.
- [x] Add tests for blank prompt, filled auto-save, and reopened saved data.

## Photo Naming
- [x] Refactor photo naming into one shared naming policy.
- [x] Keep the "name this photo/attachment" dialog as the standard approach.
- [x] Remove the description option from new-photo naming.
- [x] Remove description editing from the report photo detail dialog.
- [x] Keep optional location selection.
- [x] Save the user-entered name in `Photo.filename`.
- [x] Update daily entry attachment filename policy to include the user-added name.
- [x] Fix example behavior:
  - `Photo Removals 2026-05-18 RBWS.jpg`
  - exports/displays as `Photo Removals 2026-05-18 RBWS.pdf`
- [x] Update thumbnail/detail display so names match the saved filename.

## Tests
- [x] Add unit/widget tests for Entries range export.
- [x] Add tests for per-day folder conflict behavior during batch export.
- [x] Add tests for partial batch export success/failure feedback.
- [x] Add form PDF tests for editable exported fields.
- [x] Add form PDF tests for date-picker field persistence.
- [x] Add form back-navigation tests for blank versus filled forms.
- [x] Add photo dialog tests proving no description field is shown.
- [x] Add photo attachment filename tests proving user-added names appear.
- [x] Run `flutter analyze`.
- [x] Run `dart run custom_lint`.
- [x] Run targeted entry export, form PDF, form exit, and photo naming tests.

## S21 Live Verification
- [x] Use real auth/session and real backend state.
- [x] Do not use `MOCK_AUTH`.
- [x] From the Entries flow, select a date range and export multiple days.
- [x] Verify output folders/files on the S21.
- [x] Pull/open exported form PDFs on a computer.
- [x] Edit fields in the exported PDF, save, close, reopen, and confirm changes persist.
- [x] Verify date-picker fields behave as actual PDF fields.
- [x] Start a form, enter data, hit back, reopen, and confirm no prompt plus saved data.
- [x] Start a blank form, hit back, and confirm the prompt still appears.
- [x] Take/name a photo and verify the daily entry attachment list includes the added name.
- [x] Export the daily bundle and verify the photo PDF filename includes the added name.
- [x] Confirm sync queue, screenshots, and debug logs show no runtime/sync/UI defects.

## Assumptions
- [x] Multi-day export means batching the existing daily export output, not creating one combined PDF.
- [x] Exported form PDFs must remain editable in external PDF software.
- [x] Preview PDFs remain read-only to prevent double-rendering in the app viewer.
- [x] Photo naming is name-only plus optional location; description is out of scope.
- [x] Existing dirty Water Main work is unrelated and should be preserved before this branch begins.
