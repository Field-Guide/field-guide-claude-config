# Non-Project IDR Selection, Preview, And Activity Location TODO

## Summary

- [ ] Move non-project Daily Entry IDR format selection from export time to entry creation time.
- [ ] Keep project Daily Entry workflow PDF-only.
- [ ] Rename the editor toolbar action from PDF Preview to Preview.
- [ ] Make Preview render the selected non-project output format.
- [ ] Remove location labels/IDs from non-project activities because non-project entries have no location setup path.
- [ ] Block non-project sync hint RPCs from using synthetic workspace ids as UUID project ids.
- [ ] Keep FCM debug-token auth noise unchanged unless explicitly requested; it is optional transport noise in debug.
- [ ] Gate automatic Sentry SDK transport in debug unless explicitly opted in, while preserving configured support-report DSN data.
- [ ] Fully verify the corrected non-project flows on the connected S21.

## Implementation TODO

- [ ] Prompt after `Daily Entry` -> `Start New Entry` in the non-project workspace.
- [ ] Offer `Company IDR`.
- [ ] Offer `Plain Text IDR`.
- [ ] Persist the selected IDR format for the created draft.
- [ ] Reuse the persisted IDR format for non-project Preview and export.
- [ ] Default project Daily Entries to Company/PDF IDR without prompting.
- [ ] Remove the export-time IDR format prompt.
- [ ] Keep the existing export action sheet after format selection has already happened.
- [ ] Rename the toolbar tooltip/log text to `Preview`.
- [ ] Replace the visible PDF-only toolbar icon with a generic preview icon.
- [ ] Add a text IDR preview surface using `IdrPlainTextFormatter` and `IdrPdfData`.
- [ ] Keep the existing PDF preview for Company IDR and all project entries.
- [ ] Strip non-project activity `locationId` and `locationName` metadata in the editor.
- [ ] Strip non-project activity location headings in PDF/text preview and export data.
- [ ] Preserve project per-location activity formatting.
- [ ] Drop remote sync hints when the resolved project scope is not a UUID.
- [ ] Leave FCM debug initialization unchanged per user direction.
- [ ] Use an explicit debug opt-in for automatic Sentry SDK network transport to avoid noisy 429 verification logs.

## Tests TODO

- [ ] Widget-test non-project Start New Entry shows Company IDR and Plain Text IDR choices.
- [ ] Widget-test choosing Plain Text IDR routes to a force-new entry with the selected format.
- [ ] Widget-test project/new-entry app bar now exposes `Preview`, not `Preview PDF`.
- [ ] Unit-test export owner no longer prompts for non-project format when a format is provided.
- [ ] Unit-test non-project activity JSON with location metadata formats without location headings.
- [ ] Regression-test project activity JSON still formats with location headings.
- [ ] Widget-test non-project activity editor strips location labels from persisted JSON.
- [ ] Widget-test/plain unit-test text preview uses `IdrPlainTextFormatter` output.
- [ ] Unit-test synthetic non-project ids are not sent through the sync hint emitter.
- [ ] Unit-test debug Sentry SDK transport is disabled by default.
- [ ] Run focused dashboard, entry app-bar, activities, preview, and export tests.
- [ ] Run `flutter analyze`.
- [ ] Run `dart run custom_lint`.

## S21 Verification TODO

- [ ] Install a real-auth debug build on S21 `RFCNC0Y975L`.
- [ ] Open the non-project workspace as the real office-technician session.
- [ ] Tap `Daily Entry`.
- [ ] Tap `Start New Entry`.
- [ ] Confirm the format prompt appears before the editor.
- [ ] Choose `Plain Text IDR`.
- [ ] Fill real visible fields: project name, project number, activities, safety/site, SESC, traffic, visitors, extras, contractor/personnel/equipment, and at least one attachment when practical.
- [ ] Confirm the Activities section has no location label.
- [ ] Tap `Preview`.
- [ ] Confirm the preview shows plain text IDR content and no activity location heading.
- [ ] Export `Export Dated Bundle`.
- [ ] Pull/open the exported `.txt` from the dated folder and verify content.
- [ ] Confirm attached PDFs remain in the dated bundle when present.
- [ ] Export `Export IDR Only`.
- [ ] Pull/open the exported `.txt` from the folder root and verify content.
- [ ] Create or open a non-project `Company IDR` entry and confirm Preview remains PDF.
- [ ] Confirm project Daily Entry export/preview remains the current PDF flow.
- [ ] Confirm sync queue remains clean.
- [ ] Capture screenshots/logs showing no UI/runtime/export defects, with FCM debug-token auth noise treated as accepted optional-transport noise per user direction.

## Assumptions

- [ ] `Company IDR` means the existing PDF IDR artifact.
- [ ] Plain Text IDR remains non-project-only.
- [ ] The selected non-project format is a local draft/export preference, not a new project-level setting.
- [ ] Existing non-project entries with stale activity location metadata should display/export without locations.
