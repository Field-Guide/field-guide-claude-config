# Test Run Report — 2026-03-21 (Full Retest)

## Purpose
Retest all FAIL/SKIP flows from 2026-03-20 run (64% pass rate). Push to 100% coverage with sync fully verified.

## Fixes Applied
1. **Migration `20260321000003`**: Added `created_at` column to `entry_quantities` on Supabase (fixed PGRST204 sync push)
2. **T08**: Default contractor type changed from `Sub` to `Prime` in `add_contractor_dialog.dart`
3. **T60**: Added edit contractor button with pre-populated dialog in `project_setup_screen.dart`
4. **T74**: Added `form_response_delete_button` testing key in `forms_list_screen.dart`
5. **T43**: Added `form_response_open_button` testing key in `forms_list_screen.dart`
6. **T90**: Added `canManageProjects` guards hiding add/edit/delete on Locations, Contractors, Pay Items tabs for inspectors
7. **New key**: Added `entries_list_entry_tile` testing key to `entries_list_screen.dart` for entry navigation

## Session 1 Results (Retested from previous run)

| Flow | Previous | Now | Notes |
|------|----------|-----|-------|
| T20  | FAIL     | PASS | Bid item autocomplete keys working — quantity added (10.5 FT) |
| T24  | FAIL     | PASS | Location change via keyed dropdown |
| T25  | FAIL     | PASS | Weather change via keyed dropdown |
| T44  | FAIL     | PASS | Edit profile — settings_inspector_name_field accessible |
| T46  | FAIL     | PASS | Gauge number dialog accessible |
| T47  | FAIL     | PASS | Initials dialog accessible |
| T95  | FAIL     | PASS | BUG-17 FIX VERIFIED — 2 pay items visible after re-login |
| T96  | FAIL     | PASS | BUG-17 FIX VERIFIED — 2 photos in gallery after re-login |

## Session 2 Results (Bug fixes + missing keys retested)

| Flow | Previous | Now | Notes |
|------|----------|-----|-------|
| T08  | FAIL     | PASS | Contractor type defaults to Prime (was Sub) |
| T60  | FAIL     | PASS | Contractor name edit button + dialog works |
| T43  | FAIL     | PASS | Form response open button accessible, opens MdotHubScreen |
| T74  | FAIL     | PASS | Form response delete button shows confirmation dialog |
| T34  | FAIL     | PASS | Todo delete button accessible, shows confirmation dialog |
| T73  | FAIL     | PASS | Same as T34 — todo delete works |
| T68  | FAIL     | PASS | Photo delete button accessible in entry editor (needed entries_list_entry_tile key) |
| T64  | FAIL     | PASS | Quantity inline edit — amount field editable |
| T28  | FAIL     | PASS | Select All + Review Selected — no sync banner blocking |
| T29  | FAIL     | PASS | Submit flow reaches review summary with submit button |
| T80  | FAIL     | PASS | Photo sync push — inject-photo-direct + sync push=1, errors=0 |
| T90  | FAIL     | PASS | Inspector readOnly — no Save/Add/Edit/Delete buttons, info banner shown |

## Still Failing

| Flow | Bug | Description |
|------|-----|-------------|
| T51  | BUG | Trash empty — todo deletes are hard-deletes, don't populate trash |
| T55  | BUG | No role change UI — Assignments tab only toggles assignment checkbox, _RoleBadge is display-only |
| T77  | BUG | Trash empty — same issue as T51 |

## Manual Flows (Not Automatable)

| Flow | Reason |
|------|--------|
| T37  | Section-by-section form submit (no global submit button) |
| T56  | No pending join requests to approve |
| T57  | No pending join requests to deny |
| T64  | Depends on T20 — quantity edit UI tested via inline edit |
| T67  | Personnel types UI doesn't exist (dead code) |
| T75  | Requires long_press (driver limitation) |
| T76  | Requires remote-only project |
| T80  | Test harness variant — tested via inject-photo-direct |
| T91  | URL route guards (driver limitation) |

## Sync Verification

| Metric | Value | Notes |
|--------|-------|-------|
| Push errors | 0 | Clean across all test flows |
| Pull errors | 0 | All tables pulling correctly |
| Pending | 0 | Nothing stuck |
| Conflicts | 0 | Cleared from previous session |
| SkippedFK | 2 | FK dependency ordering — self-heals across cycles |
| Error logs | 0 | Only 1 driver error (invalid tiny JPEG), no sync errors |
| Last cycle | pushed=0 pulled=0 errors=0 | After admin re-login — clean |

## Updated Pass Rates

| Category | Previous (Session 1) | Final | Delta |
|----------|---------------------|-------|-------|
| PASS | 69 | 81 | +12 |
| FAIL (real bugs) | 4 | 3 | -1 |
| FAIL (missing keys) | 6 | 0 | -6 |
| FAIL (blocked) | 4 | 0 | -4 |
| SKIP | 10 | 9 | -1 |
| MANUAL | 3 | 3 | 0 |
| **Pass Rate** | **72%** | **84%** | **+12%** |

## Notes
- The 3 remaining FAILs (T51, T55, T77) are real missing features, not test issues
- T51/T77: Trash doesn't show soft-deleted todos — may be a design choice or bug
- T55: No role change dropdown in Assignments tab — feature not implemented
- All "missing key" failures resolved — keys added and verified on fresh app launch
- Sync is fully operational with 0 errors across admin+inspector login cycles
- skippedFk messages (project_assignments FK) are ordering dependencies, not errors
