# Daily Entry Export and New Entry Locations Fix TODO

## Summary

Fix Daily Entry export so it matches intended field workflow, and fix new-entry location state so locations appear without needing to open an existing entry first.

Export rules:
- PDF preview is preview only.
- Three-dot menu owns export workflow.
- First export for a project asks the user to pick/create that project's export folder.
- The chosen folder is remembered per project on that device.
- After folder selection, and on future exports for that project, show an action sheet with export/share choices.
- No repeated folder picker unless the user changes project folder or the saved folder is unavailable.

## Daily Entry Export TODO

- [x] Keep toolbar PDF button preview-only.
- [x] Keep export workflow under three-dot `Export Daily Entry`.
- [x] Remove the forced folder-name dialog from the beginning of export.
- [x] On first export for a project, open Android folder picker so the user picks/creates the desired project export folder.
- [x] Persist the selected project export folder per `projectId`.
- [x] On repeat export for the same project, skip folder selection and show the export action sheet.
- [x] Add `Change Project Folder` action to replace the remembered folder for that project.
- [x] If remembered folder permission/path is unavailable, explain the issue and prompt the user to reselect the project export folder.
- [x] After folder selection or lookup, show action sheet with:
  - `Export Dated Bundle`
  - `Export IDR Only`
  - `Share Dated Bundle`
  - `Share IDR Only`
  - `Change Project Folder`
  - `Cancel`
- [x] `Export Dated Bundle` writes a dated folder inside the project export folder.
- [x] Dated folder name is `MM-dd`.
- [x] Dated bundle contains individual PDF files:
  - IDR PDF
  - attached form PDFs
  - attached photo PDFs
- [x] Do not include original photo image files.
- [x] `Export IDR Only` saves the IDR PDF directly in the project export folder root.
- [x] If dated folder already exists, ask user:
  - replace/update contents
  - create timestamped copy
  - cancel
- [x] `Share Dated Bundle` generates/updates the dated folder first, then opens Android share sheet with all files in that dated folder as multiple attachments.
- [x] `Share IDR Only` generates the IDR PDF and opens the normal Android share sheet for that single PDF.
- [x] Preserve Android options such as Bluetooth, email, Drive, etc. through the system share sheet.
- [x] Keep saved export/history records useful for generated daily-entry PDFs and bundle files.

## Android/File System TODO

- [x] Add Android document-tree support to existing `field_guide/documents` channel.
- [x] Use `ACTION_OPEN_DOCUMENT_TREE` for project export folder selection.
- [x] Persist URI permissions for selected project folders.
- [x] Validate remembered folder access before export/share actions.
- [x] Create child dated folders through Android SAF when needed.
- [x] Write PDFs through `ContentResolver` for SAF destinations.
- [x] Keep local app-managed staging files where needed for artifact history and share sheet compatibility.
- [x] Share dated bundle files as multiple attachments; do not zip unless Android multi-file share proves impossible.

## Locations TODO

- [x] Fix new-entry location state so locations load for the entry's project without opening an existing entry first.
- [x] Guard project-scoped provider loads so stale async loads cannot overwrite current project state.
- [x] Ensure entry editor uses locations matching `entry.projectId`.
- [x] New entry with zero project locations shows no location UI.
- [x] New entry with one project location shows that location.
- [x] New entry with multiple project locations shows all locations.
- [x] Existing entry saved activity JSON can still display saved location context, but must not mask provider load bugs.
- [x] Verify locations are not soft-deleted or orphan-purged unexpectedly during reproduction.

## Verification TODO

- [x] Unit/widget test: first project export prompts for project folder selection before action sheet.
- [x] Unit/widget test: repeat export skips folder picker and opens action sheet.
- [x] Unit/widget test: `Change Project Folder` updates only that project's remembered folder.
- [x] Unit/widget test: IDR-only export writes to project folder root.
- [x] Unit/widget test: dated bundle writes to `MM-dd`.
- [x] Unit/widget test: existing dated folder asks replace/copy/cancel.
- [x] Unit/widget test: Share IDR Only invokes single-PDF share.
- [x] Unit/widget test: Share Dated Bundle invokes multi-file share with generated bundle files.
- [x] Unit/widget test: unavailable remembered folder prompts reselect.
- [x] Unit/widget test: stale location loads cannot overwrite active project locations.
- [x] Unit/widget test: one project location is visible in new-entry Activities.
- [x] Unit/widget test: zero project locations shows no location UI.
- [x] Local checks: `flutter analyze`.
- [x] Local checks: `dart run custom_lint`.
- [x] Local targeted export/location tests.
- [x] S21 live verification with real office technician session:
  - [x] select Springfield project export folder once
  - [x] export dated bundle and verify folder/file output
  - [x] repeat export goes directly to action sheet
  - [x] Share Dated Bundle opens Android chooser with multiple files
  - [x] Share IDR Only opens Android chooser with one PDF
  - [x] create new entry and verify locations appear without opening existing entry first
  - [x] verify sync pending/blocked/conflict counts stay zero
  - [x] verify logcat has no severe Flutter/Android runtime errors
- [ ] Start Codemagic builds only after S21 proof passes.
  - Pending because the verified changes are still local; starting Codemagic now
    would build the remote commit, not this patch.

## Locked Assumptions

- "Share folder" means Android multi-file share of the dated folder contents, not a preserved folder tree.
- Do not zip the dated bundle unless multi-file Android share is proven unusable.
- Photo output remains photo PDFs only.
- Remembered export destination is device-local and project-specific.
- Dated folder format is `MM-dd`.
- Existing dated folder behavior is user choice: replace, timestamped copy, or cancel.
