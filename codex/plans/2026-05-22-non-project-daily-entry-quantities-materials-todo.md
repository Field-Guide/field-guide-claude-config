# Non-Project Daily Entry Quantities / Materials TODO

## Summary

- [ ] Restore `Pay Items Used` / quantities to the non-project Daily Entry editor.
- [ ] Keep the workflow unchanged except for selected IDR output format.
- [ ] Make non-project manual pay items entry-owned, not workspace-owned.
- [ ] Ensure Plain Text IDR `Materials` is filled from the same quantity data as the Company/PDF IDR.
- [ ] Prevent the contractor/location leakage problem from repeating for pay items.

## Storage And Scoping TODO

- [ ] Add nullable `source_entry_id` to `bid_items` in local SQLite and Supabase.
- [ ] Treat `bid_items.source_entry_id == null` as reusable project pay items.
- [ ] Treat `bid_items.source_entry_id == daily_entries.id` as non-project IDR-local pay items.
- [ ] For project Daily Entries, load only reusable project pay items where `source_entry_id IS NULL`.
- [ ] For non-project Daily Entries, load only pay items where `source_entry_id == current entry id`.
- [ ] Do not expose prior non-project manual pay items in a fresh non-project IDR.
- [ ] Do not delete existing contaminated/residue pay-item rows; hide them from unrelated entries by scope.
- [ ] Block duplicate manual pay-item numbers inside the same non-project entry.
- [ ] Allow the same manual pay-item number/description across different non-project entries.
- [ ] Keep project duplicate pay-item validation unchanged.

## Implementation TODO

- [ ] Show `EntryQuantitiesSection` for non-project Daily Entries.
- [ ] Always load `entry_quantities` for the open entry.
- [ ] For project entries, keep the current saved-pay-item picker flow.
- [ ] For non-project entries, replace the empty "No pay items in this project" dead end with manual pay-item entry.
- [ ] Manual non-project pay-item fields:
  - pay item name
  - unit dropdown using the same allowed pay-item units as project pay items
  - quantity
  - optional quantity notes
- [ ] When saving a manual non-project pay item:
  - create `BidItem(projectId: workspaceProjectId, sourceEntryId: entry.id, ...)`
  - create linked `EntryQuantity(entryId: entry.id, bidItemId: manualBidItem.id, projectId: entry.projectId, ...)`
  - refresh only the current entry's scoped quantity/pay-item state
- [ ] Ensure edit/delete for a non-project quantity only affects that current entry's quantity row and its entry-scoped pay item when appropriate.
- [ ] Keep `PdfDataBuilder` building `IdrPdfData.quantities` and `bidItemsById` from the scoped rows for the current entry.
- [ ] Keep Company/PDF IDR material formatting unchanged.
- [ ] Keep Plain Text IDR material formatting sourced from `IdrPdfData`, so manual non-project quantities appear under `Materials`.

## Sync / Data Safety TODO

- [ ] Update the `bid_items` sync adapter FK dependencies to include `daily_entries` through `source_entry_id`.
- [ ] Ensure non-project manual pay items sync only after their parent daily entry exists remotely.
- [ ] Ensure pull/refresh does not hydrate entry-scoped bid items into reusable project pay-item lists.
- [ ] Update delete/soft-delete graph behavior so deleting a non-project entry cleans or hides its entry-scoped pay items and quantities without touching reusable project pay items.
- [ ] Verify RLS allows the current user to manage their own non-project entry-scoped bid items under the private non-project workspace rules.
- [ ] Add a repair/hiding path for old non-project pay items that lack correct scope if they appear during live verification.

## Tests TODO

- [ ] Widget-test non-project Daily Entry shows `Pay Items Used`.
- [ ] Widget-test non-project `Add Pay Item` opens manual pay-item entry when no saved pay items exist.
- [ ] Widget-test manual pay-item save creates both `bid_items` and `entry_quantities`.
- [ ] Widget-test a fresh non-project IDR does not show a prior IDR's manual pay items.
- [ ] Repository-test duplicate item numbers are blocked within the same non-project entry.
- [ ] Repository-test the same item number is allowed across two different non-project entries.
- [ ] Regression-test project duplicate pay-item validation remains project-wide.
- [ ] Regression-test project Daily Entry still uses the saved-pay-item picker.
- [ ] Data-builder test non-project `IdrPdfData.bidItemsById` includes only current-entry manual pay items.
- [ ] Formatter/export test Plain Text IDR `Materials` includes the manual pay item description, quantity, and unit.
- [ ] PDF regression test Company/PDF IDR materials still render from the same data.
- [ ] Sync adapter test `bid_items.source_entry_id` FK ordering is honored.
- [ ] Run focused quantity/editor/export/sync tests.
- [ ] Run `flutter analyze`.
- [ ] Run `dart run custom_lint`.

## Live Verification TODO

- [ ] Use real office-technician auth in the non-project workspace.
- [ ] Start non-project Daily Entry A.
- [ ] Add manual pay item `X` with quantity and notes.
- [ ] Preview Plain Text IDR and confirm `Materials` includes `X`.
- [ ] Export Plain Text IDR Only and confirm the `.txt` includes `X`.
- [ ] Export Plain Text Dated Bundle and confirm the `.txt` includes `X`.
- [ ] Start non-project Daily Entry B.
- [ ] Confirm Entry A's manual pay item is not offered or shown in Entry B.
- [ ] Add manual pay item `X` again in Entry B and confirm no duplicate error from Entry A.
- [ ] Reopen Entry A and confirm its manual pay item is still tied to Entry A.
- [ ] Open a project Daily Entry and confirm project pay-item behavior is unchanged.
- [ ] Confirm sync queue drains cleanly and logs/screenshots show no leakage, runtime, export, or sync defects.

## Assumptions

- [ ] Non-project manual pay items are saved IDR content tied to one daily entry, not reusable workspace catalog data.
- [ ] `Materials` means the existing IDR materials section sourced from Daily Entry quantities.
- [ ] Existing project quantities, pay-item import, analytics, and pay-app behavior must not change.
