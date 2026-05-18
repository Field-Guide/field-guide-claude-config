# IDR/Form Export Repair To-Do Spec

## Summary

- Replace the split IDR export behavior with one canonical daily export flow launched from the main entry export button, not from PDF Preview.
- Keep PDF Preview read-only: preview can show the generated IDR PDF, but it must not own save/share/export side effects.
- Daily export writes one dated folder for the entry containing the IDR PDF, attached form PDFs, and attached photo PDFs.
- Standalone forms keep a direct single-form export path, including "save copy" and "save in dated folder".
- Signature invalidation after edits must leave the form editable and re-signable, with no frozen UI state.
- All live verification must use the Springfield project on the connected S21. Do not use Soggatuck.

## To-Do Items

- [x] Create one canonical `DailyEntryExportActionOwner` or equivalent production owner used by the main export button in `lib/features/entries/presentation/widgets/entry_editor_app_bar.dart`.
- [x] Change the main IDR export button so it runs the canonical daily export flow directly instead of pushing `EntryPdfPreviewScreen`.
- [x] Make PDF Preview preview-only: remove or disable the preview-owned Save/Share export path currently in `lib/features/entries/presentation/screens/entry_pdf_preview_screen.dart`.
- [x] Retire the old "Export All Forms" entry menu flow in `lib/features/entries/presentation/screens/entry_editor_actions.dart` as a user-facing export path.
- [x] Consolidate the two daily bundle implementations:
  - stop depending on a previously saved `entry_exports.file_path` as the IDR source in `lib/features/entries/domain/usecases/export_entry_use_case.dart`
  - generate the IDR PDF fresh during export
  - write attached forms and photos in the same pass
- [x] Standardize dated folder output:
  - suggested folder name: `MM-dd`
  - collision folder name: `MM-dd_HHmmss`
  - folder contents: IDR PDF, attached form PDFs with response-id-safe filenames, and photo PDFs with photo-id-safe filenames
- [x] Fix photo export so daily export writes photo PDFs generated from the attached photo files.
- [x] Fix duplicate attached-form filename collisions in `lib/features/pdf/services/pdf_export_bundle_writer.dart` by including `formResponse.id` or another stable unique prefix.
- [x] Record one daily `entry_exports` row pointing at the dated folder and per-file `export_artifacts` rows for IDR, forms, and photos.
- [x] Decide in implementation that `export_artifacts` remains local-only for this fix unless a separate storage-sync requirement is opened; current sync config explicitly skips it.

## Form And Signature Fixes

- [x] Keep standalone form export through the shared form export owner, not through entry preview.
- [x] Ensure exported form responses stay editable; exported PDFs are artifacts, not a terminal form state.
- [x] Audit and remove or quarantine old `markAsExported` paths where they can turn an editable form into an uneditable submitted/exported state.
- [x] Add export-busy guards to form export controller/UI so double taps cannot create duplicate rows or freeze dialogs.
- [x] Verify signed 1126 behavior:
  - sign form
  - export form
  - reopen saved form
  - edit a visible signed field/header
  - assert `signature_audit_id` clears
  - re-sign succeeds
  - form remains responsive

## Tests And Verification

- [x] Add unit/widget coverage for the canonical daily export owner:
  - main export button invokes daily export directly
  - preview screen does not save/share/export
  - attached forms and photos create a dated folder
  - duplicate same-type form attachments produce distinct files
- [x] Add repository/use-case coverage for signature invalidation after exported signed-form edits.
- [x] Add controller/widget coverage for form export busy state and double-tap protection.
- [x] Add S21 live E2E flow using Springfield only:
  - select Springfield project
  - create/open an IDR with at least one attached form and one photo
  - tap the main export button
  - choose/export to the dated folder
  - pull the folder from device storage
  - verify IDR PDF, attached form PDF(s), and attached photo PDF(s) exist and are non-empty
  - verify local `entry_exports` and `export_artifacts` rows point to real files
  - verify `runtimeErrors=0`, no layout defects, and app returns from Android DocumentsUI cleanly
- [x] Add S21 signed-form regression:
  - signed/exported form can be edited
  - signature clears
  - re-sign works
  - export works again

## Assumptions

- "Dated folder" means the existing `MM-dd` user-visible folder convention.
- Daily export should include attached photos as photo PDFs.
- `export_artifacts` stays local-only for this repair because the current sync adapters intentionally skip push/pull.
- Springfield is the only accepted live project for this verification pass.
