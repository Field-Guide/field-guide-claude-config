# Non-Project Daily Entry Completion Flow Plan

## Summary

- Add an explicit non-project Daily Entry launcher.
- Add a `completed` status for non-project Daily Entries.
- Let completed non-project entries remain editable.
- Preserve all project Daily Entry submit/review behavior.
- Keep task/test tracking in this plan and test evidence only; do not add
  implementation checklists to product UI.

## Implementation To-Do

- [ ] Add `EntryStatus.completed`.
- [ ] Update Daily Entry serialization/deserialization for `completed`.
- [ ] Keep unknown status fallback to `draft`.
- [ ] Add `completeEntry(id)` repository/provider flow.
- [ ] Make `completeEntry` set `status = completed`.
- [ ] Do not set `submitted_at`, `signature`, or `signed_at` for completed entries.
- [ ] Keep completed entries editable by the owner.
- [ ] Keep completed entries owner-scoped, like drafts.
- [ ] Keep `submitted` as the only reviewable/project-submission status.

## Non-Project UI To-Do

- [ ] Change the non-project dashboard `Daily Entry` card to open an action hub.
- [ ] Add `Start New Entry` action.
- [ ] Add `Continue Draft` action when a current-user draft exists.
- [ ] Add `Saved Entries` action.
- [ ] Make `Start New Entry` create a fresh draft for today every time.
- [ ] Make `Start New Entry` bypass existing draft reuse.
- [ ] Add an entry route/query mode such as `mode=new`.
- [ ] In the editor, show `Complete Entry` for non-project draft entries.
- [ ] On `Complete Entry`, save pending edits, mark completed, show success, and return to dashboard.
- [ ] Show `Completed` status in entry cards, badges, and saved-entry list rows.

## Project Flow Guardrails

- [ ] Do not change project Daily Entry launch behavior.
- [ ] Do not change project draft review.
- [ ] Do not change batch submit behavior.
- [ ] Do not include `completed` entries in Review Hub.
- [ ] Do not allow reviewer comments on `completed` entries.
- [ ] Do not treat `completed` as `submitted`.

## Tests To-Do

- [ ] Test `completed` status maps to/from `completed`.
- [ ] Test `completeEntry` marks a draft completed.
- [ ] Test `completeEntry` does not set submission/signature fields.
- [ ] Test completed entries are excluded from draft queries.
- [ ] Test completed entries remain editable.
- [ ] Test non-project `Daily Entry` opens the action hub.
- [ ] Test `Start New Entry` creates a new entry when today already has a draft.
- [ ] Test `Start New Entry` creates a new entry when today already has a completed entry.
- [ ] Test `Continue Draft` appears only when a draft exists.
- [ ] Test `Complete Entry` returns to the non-project dashboard.
- [ ] Test Saved Entries displays completed entries.
- [ ] Regression-test project Daily Entry resume behavior.
- [ ] Regression-test project review/batch submit still uses `submitted`.
- [ ] Regression-test Review Hub ignores completed entries.
- [ ] Regression-test that implementation/task checklist copy is not present in
      the non-project product UI.

## S21 Verification To-Do

- [ ] Verify with real auth as office technician on Grand Blanc Test project `6936f810-ec15-494e-b4aa-280bf3bf15d3`, project number `12344`.
- [ ] Verify the non-project Daily Entry card opens the action hub.
- [ ] Verify the non-project action hub does not display implementation/test
      checklist copy.
- [ ] Verify `Start New Entry` creates a fresh draft when a draft already exists today.
- [ ] Verify `Start New Entry` creates a fresh draft when a completed entry already exists today.
- [ ] Verify `Continue Draft` appears only when a current-user draft exists.
- [ ] Verify completing a non-project draft saves pending edits, marks it `Completed`, returns to the non-project dashboard, and leaves it editable from saved entries.
- [ ] Verify project Daily Entry resume, draft review, batch submit, and Review Hub behavior still use only `submitted` for review.

## Assumptions

- [ ] `completed` is only for non-project Daily Entries.
- [ ] Completed entries remain editable.
- [ ] New non-project entries default to today.
- [ ] Completing an entry returns to the non-project dashboard.
