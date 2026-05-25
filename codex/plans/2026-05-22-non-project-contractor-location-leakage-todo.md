# Non-Project Contractor And Location Leakage TODO

## Summary

- [x] Treat non-project Daily Entry contractors/equipment as entry-owned IDR data only.
- [x] Allow the same contractor name across different non-project IDRs.
- [x] Block duplicate contractor names inside the same non-project IDR.
- [x] Preserve project workspace behavior: contractors persist and duplicate names stay blocked.

## Implementation TODO

- [x] Update contractor duplicate-name validation.
- [x] For reusable project contractors, compare only against rows where `sourceEntryId == null`.
- [x] For non-project entry-owned contractors, compare only against rows with the same `sourceEntryId`.
- [x] Ensure old non-project contractor/equipment rows stay available only to their original IDR.
- [x] Do not delete existing S21 non-project contractor/equipment residue.
- [x] Ensure fresh non-project IDRs do not offer prior IDR contractors as reusable choices.
- [x] Ensure non-project contractor creation does not show "already exists in this project" because of another IDR.
- [x] Pass the non-project location-disabled flag through the wide/tablet Activities section path.
- [x] Keep compact non-project Activities location-free.
- [x] Keep all project location and contractor persistence behavior unchanged.

## Tests TODO

- [x] Test project duplicate contractor names are still rejected.
- [x] Test two non-project contractors with the same name but different `sourceEntryId`s are accepted.
- [x] Test two non-project contractors with the same name and the same `sourceEntryId` are rejected.
- [x] Test project contractor creation ignores entry-owned non-project rows during duplicate validation.
- [x] Test a fresh non-project IDR can create a contractor with the same name as a prior non-project IDR.
- [x] Test prior non-project IDR contractors are hidden from new non-project IDRs.
- [x] Test non-project Activities has no location UI in compact layout.
- [x] Test non-project Activities has no location UI in wide/tablet layout.
- [x] Run focused contractor repository, contractor editing, and activities/editor tests.
- [x] Run `flutter analyze`.
- [x] Run `dart run custom_lint`.

## Physical S21 Verification Status

- [x] Attempted S21 real-auth verification.
- [x] Confirmed `RFCNC0Y975L` remained ADB `offline`.
- [x] Replaced the blocked physical S21 pass with real-auth emulator verification per user direction.

## Emulator Verification TODO

- [x] Use real auth on emulator.
- [x] Open the non-project workspace.
- [x] Create or keep an existing non-project draft with contractor `X`.
- [x] Start New Entry.
- [x] Add contractor `X` again.
- [x] Confirm no duplicate-name error appears.
- [x] Confirm contractor `X` from the prior IDR is not offered as reusable.
- [x] Confirm non-project Activities shows no location UI in compact layout.
- [x] Confirm non-project Activities shows no location UI in wide/tablet layout.
- [x] Confirm non-project save/reopen keeps only the current IDR's contractor data.
- [x] Open Grand Blanc Test project `6936f810-ec15-494e-b4aa-280bf3bf15d3`.
- [x] Confirm project contractors still persist.
- [x] Confirm duplicate project contractor names are still blocked.

## Assumptions

- [x] Non-project contractors/equipment may persist only as entry-owned saved IDR content.
- [x] Non-project workspace must never expose entry-owned rows as reusable workspace/project contractors.
- [x] Existing contaminated S21 rows should be hidden from unrelated entries, not deleted.
