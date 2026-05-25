# Non-Project Daily Entry Hub Cleanup And Selected-Entry Export Flow

## Reference Evidence To Preserve

- Keep `tools/testing/test-results/2026-05-20/non-project-export-selection-plan-reference/02-current-daily-entry-hub-has-saved-entries.png`.
- Keep `tools/testing/test-results/2026-05-20/non-project-export-selection-plan-reference/03-entries-list-toolbar-export.png`.

## Non-Project Daily Entry Hub Cleanup

- Remove `Saved Entries` from the Daily Entry action hub opened by the non-project workspace `Daily Entry` card.
- Keep `Start New Entry` in that hub.
- Keep `Continue Draft` in that hub only when a current-user draft exists.
- Do not remove the separate non-project workspace dashboard `Saved Entries` card/log.
- Remove the unused `non_project_workspace_saved_entries_action` testing key if nothing else references it.
- Remove the matching dashboard driver contract action if the key is removed.
- Update widget tests so the Daily Entry hub explicitly does not show `Saved Entries`.
- Keep tests proving the separate dashboard `Saved Entries` card still opens the saved entries log.

## Selected-Entry Export Flow

- Change the existing entries-list multi-report export toolbar icon so it enters selection mode instead of opening a date-range picker.
- Remove the date-range picker from this export flow.
- In selection mode, show the prompt: `Select the entries you would like to export.`
- Add a `Complete` action for selection mode.
- Disable `Complete` until at least one entry is selected.
- Add a `Cancel` action for selection mode.
- Make `Cancel` exit selection mode and clear selected entries.
- Make each visible entry card toggle selected/unselected when tapped in selection mode.
- Highlight selected entry cards clearly.
- Prevent normal entry navigation while in selection mode.
- Keep normal entry tap navigation unchanged outside selection mode.
- Hide or disable delete actions during selection mode.
- On `Complete`, sort selected entries by date ascending.
- Pass only the selected entries to the existing daily entry range export owner.
- After `Complete`, show the existing export action sheet with the current export options, including `Export Dated Bundle` and `Share Dated Bundle`.
- Apply this selected-entry export flow to both project and non-project entries lists.

## Tests To Add Or Update

- Test non-project Daily Entry hub shows `Start New Entry`.
- Test non-project Daily Entry hub shows `Continue Draft` only when a current-user draft exists.
- Test non-project Daily Entry hub does not show `Saved Entries`.
- Test separate non-project dashboard `Saved Entries` card still opens the saved entries log.
- Test entries-list export icon enters selection mode.
- Test entries-list export icon does not open a date-range picker.
- Test selection mode shows `Select the entries you would like to export.`
- Test selection mode shows `Complete` and `Cancel`.
- Test `Complete` is disabled with zero selected entries.
- Test tapping entry cards toggles selected state in selection mode.
- Test selected entry cards are visibly highlighted.
- Test tapping entry cards does not navigate while in selection mode.
- Test `Cancel` exits selection mode and clears selected entries.
- Test `Complete` exports exactly the selected entries.
- Test selected entries are exported in date ascending order.
- Regression-test normal entry tap navigation outside selection mode.
- Regression-test existing export action sheet still appears after selection.
- Regression-test selected-entry export works for non-project entries.
- Regression-test selected-entry export works for project entries.

## S21 Verification To-Do

- Rebuild and install the app on the S21.
- Open the non-project workspace dashboard.
- Open the Daily Entry action hub.
- Verify `Saved Entries` is not present in the Daily Entry hub.
- Verify `Start New Entry` is present.
- Verify `Continue Draft` appears only if a current-user draft exists.
- Verify the separate non-project dashboard `Saved Entries` card still exists.
- Open the entries list from the separate `Saved Entries` card.
- Tap the existing multi-report export icon.
- Verify no date-range picker appears.
- Verify selection mode appears with the prompt.
- Select two entries.
- Verify both entries highlight as selected.
- Tap `Complete`.
- Verify the normal export action sheet appears.
- Repeat or smoke-check the same export-selection flow from a regular project entries list.

## Assumptions

- “This list” means the Daily Entry action hub list, not the non-project workspace dashboard grid.
- The separate non-project workspace `Saved Entries` log/card remains.
- Selected-entry export should reuse the existing daily entry export action sheet and export machinery.
- Draft, completed, and submitted entries remain selectable if visible, matching the current range export behavior.
