# Non-Project Plain-Text IDR Export TODO

## Summary

- [x] Add a non-project-only Plain Text IDR export format.
- [x] Keep the existing Daily Entry export workflow unchanged except for choosing the IDR format first.
- [x] Use the existing `IdrPdfData` source so the text export contains the same daily-entry information as the current IDR.
- [x] Leave project Daily Entry exports unchanged.

## Implementation TODO

- [x] Add an IDR export format choice for non-project Daily Entries:
  - [x] Prompt every time after tapping `Export Daily Entry`.
  - [x] Offer `PDF IDR`.
  - [x] Offer `Plain Text IDR`.
  - [x] Continue to the existing export action sheet after the format is selected.
- [x] Keep project Daily Entries on the current PDF-only export flow.
- [x] Add a plain-text IDR formatter service near the existing PDF export services.
- [x] Build the text report from `IdrPdfData`.
- [x] Match the existing IDR section order:
  - [x] Header
  - [x] Contractors, personnel, and equipment
  - [x] Activities
  - [x] Site safety
  - [x] SESC measures
  - [x] Traffic control
  - [x] Visitors
  - [x] Materials
  - [x] Attachments
  - [x] Extras / overruns
- [x] Keep every section in the text export.
- [x] Write `N/A` for empty sections.
- [x] Format materials like the current IDR PDF: description, quantity, and unit.
- [x] List attached form/photo filenames in the Attachments section.
- [x] Use the current IDR filename stem with `.txt`, for example `IDR 2026-05-21 12344 RS.txt`.

## Export Workflow TODO

- [x] For `PDF IDR`, preserve all current behavior.
- [x] For `Plain Text IDR`, substitute only the IDR artifact:
  - [x] `Export Dated Bundle` writes the IDR `.txt` plus attached form PDFs and photo PDFs into the `MM-dd` folder.
  - [x] `Export IDR Only` writes only the IDR `.txt`.
  - [x] `Share Dated Bundle` shares the IDR `.txt` plus attached PDFs.
  - [x] `Share IDR Only` shares only the IDR `.txt`.
- [x] Reuse the existing remembered project-folder flow.
- [x] Reuse the existing dated-folder conflict behavior.
- [x] Reuse `Change Project Folder`.
- [x] Overwrite same-name IDR `.txt` files in the chosen destination.
- [x] Extend the document output service to write/share generic files with filename, bytes, and MIME type.
- [x] Record text IDR exports in export history with `mimeType: text/plain`.

## Tests TODO

- [x] Unit-test text formatter section order.
- [x] Unit-test `N/A` output for empty sections.
- [x] Unit-test activities formatting.
- [x] Unit-test contractor/personnel/equipment text output.
- [x] Unit-test material line formatting.
- [x] Unit-test attachment filename listing.
- [x] Widget-test non-project export shows the format prompt.
- [x] Widget-test project export does not show the format prompt.
- [x] Test Plain Text `Export IDR Only` writes a `.txt`.
- [x] Test Plain Text `Export Dated Bundle` writes `.txt` plus attached PDFs.
- [x] Test Plain Text share actions use `text/plain` for IDR-only and support mixed bundle sharing.
- [x] Regression-test existing PDF IDR export behavior.
- [x] Run focused export tests.
- [x] Run `flutter analyze`.
- [x] Run `dart run custom_lint`.

## S21 Verification TODO

- [x] Verify with real office-technician auth on Grand Blanc Test.
- [x] Create or open a non-project Daily Entry.
- [x] Export as Plain Text IDR through `Export Dated Bundle`.
- [x] Confirm the `MM-dd` folder contains the IDR `.txt`.
- [x] Confirm attached form/photo PDFs remain in the bundle when present.
- [x] Export as Plain Text IDR through `Export IDR Only`.
- [x] Confirm sharing Plain Text IDR opens the Android chooser.
- [x] Confirm project Daily Entry exports still use the current PDF flow.
- [x] Confirm sync queue remains clean.
- [x] Confirm screenshots/logs show no UI/runtime/export defects.

S21 verification completed on connected device `RFCNC0Y975L` with real
office-technician auth. Evidence is under
`tools/testing/test-results/2026-05-21/s21-live-non-project-plain-text-idr/`.

## Assumptions

- [x] Plain Text IDR is only for non-project workspace entries.
- [x] The toolbar PDF button remains preview-only.
- [x] Plain Text IDR changes only the IDR artifact, not attached form/photo export formats.
- [x] The text output is optimized for copy/paste readability, not fixed-width form fidelity.
