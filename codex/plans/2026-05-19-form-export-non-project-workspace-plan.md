# Form Export Fixes And Synced Non-Project IDR Mode

Date: 2026-05-19
Status: completed and verified
Verification target: S21 with real auth, Grand Blanc Test project
(`6936f810-ec15-494e-b4aa-280bf3bf15d3`, project number `12344`)

## Form Naming Bug

- [x] Trace the current attached-form rename flow from daily entry card to persisted `attachment_display_name`.
- [x] Confirm where the naming convention is applied for daily-entry preview and export.
- [x] Change rename behavior so the dialog is seeded from the raw user-entered custom name, not the resolved export filename.
- [x] Store only the user-entered name as custom data.
- [x] Keep `.pdf` extension and convention-based filename formatting in output/display policy only.
- [x] Verify existing default filenames remain unchanged when no custom name exists.
- [x] Add tests for default naming, renamed forms, and renamed forms that already include `.pdf`.

## Standalone Form Export Bug

- [x] Reproduce/export-trace a single form response with `entryId == null`.
- [x] Identify the earliest owner that incorrectly assumes the form is attached to a daily entry.
- [x] Fix that owner without changing attached-entry export behavior.
- [x] Ensure standalone export still records export metadata and saved export artifact history.
- [x] Verify preview, share, save-copy, and dated-folder actions still work.
- [x] Add tests proving unattached form export succeeds and attached form export remains unchanged.

## Non-Project Workspace

- [x] Add a project-context abstraction that supports real project mode and non-project workspace mode.
- [x] Add “Non-Project Workspace” as a selectable item in the project switcher.
- [x] Add synced per-user backend storage/RLS for non-project IDRs, forms, entry-attached files/photos, and export artifacts.
- [x] Ensure non-project workspace records are private to the signed-in user.
- [x] Route non-project mode into the normal daily-entry/IDR workflow.
- [x] Leave project-backed auto-fill fields blank and editable in non-project mode.
- [x] Keep bid items, project contractor master lists, pay apps, and project analytics project-only for this release.
- [x] Support contractor/equipment rows added directly on a non-project IDR.
- [x] Store non-project contractor/equipment rows only on that IDR, not as reusable master records.
- [x] Sync those IDR-local contractor/equipment rows with the non-project IDR.
- [x] Show non-project exports in Saved Exports as personal workspace history.

## Verification

- [x] Run focused unit tests for form naming policy.
- [x] Run focused export tests for attached and unattached form responses.
- [x] Run non-project IDR tests for create, edit, reopen, preview, export, and saved export history.
- [x] Run sync verification with real auth and real Supabase state.
- [x] Verify Grand Blanc Test project mode still works unchanged.
- [x] Verify non-project mode works for the same signed-in user without `MOCK_AUTH`.

## Assumptions

- [x] Non-project data is synced per user, not shared company-wide.
- [x] Non-project mode is entered through the project switcher.
- [x] First release scope is IDR, forms, preview/export, saved exports, and IDR-local contractor/equipment rows.
- [x] Broader project-only surfaces remain out of scope until a later release.
