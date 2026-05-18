# Export Naming, Editability, and 0582B Date Spec

## Summary

Fix export behavior through shared export policies instead of per-form patches.

Root causes:
- Form filenames expose `FormResponse.id` / short ids and use underscores.
- Daily bundle attachment filenames prepend ids for collision handling.
- 0582B date is a free-text header field instead of a selected normalized date.
- Preview/export editability needs to remain separated across saved artifacts.
- Android document open/save paths need verification because cached/read-only
  open behavior can make external edits appear saved but not persist.

## To-Do Items

- [x] Add one shared export filename policy for builtin forms, IDR, bundled
      attachments, saved export titles, and history display.
- [x] Use spaces, never underscores, in user-visible exported PDF names.
- [x] Never show internal ids, response ids, hash ids, or UUID fragments in
      exported filenames or saved export titles.
- [x] Use this default form filename shape:
      `<form code> <yyyy-MM-dd> <project number> <initials>.pdf`.
  - Example: `0582B 2026-04-07 864130 RC.pdf`.
  - Other builtin forms use `1126 ...` and `1174R ...`.
- [x] Use this IDR filename shape:
      `IDR <yyyy-MM-dd> <project number> <initials>.pdf`.
- [x] Use this photo PDF filename shape:
      `Photo <yyyy-MM-dd> <project number> <initials>.pdf`.
- [x] Preserve dated bundle folders and bundle rows as date-only names such as
      `05-10`; do not turn them into path-like `date/file` titles.
- [x] Add custom form display names as a readable segment inside the standard
      form filename instead of replacing the standard convention.
- [x] Replace slash-like unsafe project-number characters with hyphens in
      exported PDF filenames.
- [x] Resolve initials from `UserProfile.effectiveInitials`; fallback remains
      `XX` only if the profile has no usable initials/display name.
- [x] Use entry/report date for filenames when the export is entry-attached;
      fallback to today only when no entry date exists.
- [x] Handle same-name collisions with user-friendly suffixes like ` (1)`,
      not ids.

## 0582B Date

- [x] Replace the 0582B header `date` free-text entry with a date picker /
      selected date control.
- [x] Persist the selected value as normalized `yyyy-MM-dd`.
- [x] Default the 0582B date from the attached Daily Entry date; fallback to
      today for standalone creation.
- [x] Ensure 0582B PDF field filling and export naming read the same normalized
      date source.

## Editability Contract

- [x] All forms remain editable in the app at all times, before export and
      after export.
- [x] Exporting never marks a form as final, locked, submitted, read-only, or
      otherwise non-editable.
- [x] Exported PDFs remain externally editable where the PDF template supports
      fields.
- [x] Saved/exported PDF edits must persist after save, close, and reopen.
- [x] Preview may use a read-only rendering only for viewing, but preview
      behavior must never affect the saved form state or exported editable PDF
      bytes.
- [x] Fix Android document open behavior if needed so users do not edit an
      unsaveable cached copy when they expect to edit the exported file.

## Locations

- [x] Update Daily Entry activity formatting so exported location headings
      include a trailing hyphen.
- [x] Format as `Location Name -` followed by the activity text.
- [x] Preserve legacy plain text activities and omit empty locations.

## Test Plan

- [x] Unit tests for filename policy: no underscores, no ids, full
      `yyyy-MM-dd`, project number included immediately before initials,
      initials included, duplicate suffixes friendly.
- [x] Unit/widget tests for 0582B date picker persistence and export filename
      date source.
- [x] Export bundle tests proving IDR, 0582B, 1126, 1174R, and photo PDFs use
      standardized names.
- [x] Regression tests proving export does not change form editability/status.
- [x] PDF tests proving exported bytes remain editable and saved PDF edits
      persist.
- [x] Formatting tests proving location headings export with trailing hyphen.

## S21 Verification Gate

- [x] Run on the connected S21 with real auth and real backend state.
- [x] Create or open a Daily Entry with attached 0582B and at least one
      location activity.
- [x] Select/change the 0582B date through the UI date control.
- [x] Export IDR only and dated bundle.
- [x] Reopen every exported/attached form in the app and verify it is still
      editable.
- [x] Pull or inspect exported files and verify names show no ids/hashes/
      underscores.
- [x] Open exported PDFs on a computer, edit fields, save, close, reopen, and
      verify edits persist.
- [x] Confirm exported activity text shows `Location Name -`.
- [x] Confirm `runtimeErrors=0`, no layout defects, no sync residue, and clean
      S21 debug logs.

## Verification Evidence

- S21 device: `RFCNC0Y975L`; real authenticated admin session.
- Scope: Grand Blanc only, project `6936f810-ec15-494e-b4aa-280bf3bf15d3`.
- Entry: `66322e3e-cf6f-45f5-a8f7-08a6336f6d17`.
- Attached 0582B form: `7ea3be77-758f-47a5-be77-80eb892c0ece`, still
  `status=open` after export and after a post-export edit/save/sync.
- Exported files inspected on device before the project-number correction:
  - `IDR 2026-05-10 RBWS.pdf`
  - date-only bundle folder `05-10`
  - bundled `IDR 2026-05-10 RBWS.pdf`
  - bundled `0582B 2026-05-10 RBWS.pdf`
- Superseded naming correction: future IDR/form/photo PDF exports must include
  the project number immediately before initials, while the dated bundle folder
  itself remains date-only.
- Automated Grand Blanc 0582B date-picker/export flow:
  `20260510-s21-export-regression-mdot0582b-grandblanc-picker2`, passed with
  `runtimeErrors=0`, `layoutDefectCount=0`, and drained queue.
- Standalone date-picker proof exported `0582B 2026-04-07 RBWS.pdf` before the
  project-number correction; the corrected shape is now
  `0582B 2026-04-07 <project number> RBWS.pdf`.
- Manual post-export log window since `2026-05-11T00:31:00Z`: debug server
  reported `errors=0`.
- Final sync status: `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`, no undismissed conflicts.

## Assumptions

- Canonical form names should drop `MDOT` in filenames.
- Project number must appear immediately before initials in IDR, form PDF, and
  photo PDF filenames.
- Entry date is authoritative for entry-attached exports; today is only
  fallback.
- Forms are always editable; export is only artifact generation, never a
  locking/finalization event.

## 2026-05-11 Correction Audit

- [x] Corrected the stale assumption that project number should not appear in
      filenames.
- [x] Updated the shared filename policy so IDR, form PDF, and photo PDF names
      include project number immediately before initials.
- [x] Kept dated bundle folder names and bundle metadata date-only.
- [x] Updated custom form display names so they are inserted into the standard
      filename shape.
- [x] Added hyphen sanitization for unsafe project-number characters such as
      `/`.
- [x] Updated unit/widget/PDF mapping tests for the corrected naming contract.
- [ ] Re-run S21 Grand Blanc export verification after the project-number
      correction if device evidence is required for this follow-up.
