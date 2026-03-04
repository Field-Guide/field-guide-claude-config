# Test Flow Registry

All user flows available for automated ADB-based testing. The test orchestrator reads this file to determine which flows to run and in what order.

## Wave Computation

Flows are organized into waves based on dependency chains. The orchestrator computes waves via topological sort on the `deps` field:

```
Wave 0: [login, register, forgot-password]                    (no deps)
Wave 1: [navigate-tabs, create-project, sync-check,           (dep: login)
          settings-theme, edit-profile, calculator,
          gallery-browse, todos-crud, create-entry-quick,
          create-entry-offline, admin-dashboard,
          profile-setup]
Wave 2: [edit-project, create-entry, add-contractors,          (dep: create-project)
          add-quantities, import-pdf, forms-fill,
          approve-member, company-setup,
          sync-reconnect]
Wave 3: [edit-entry, review-submit, capture-photo,             (dep: create-entry)
          create-entry-day2, add-contractors-entry,
          quantities-check]
```

## Git Diff Auto-Selection

When `/test` runs with no arguments:

1. `git diff main...HEAD --name-only` identifies changed files
2. File paths are mapped to features (see feature-path-map below)
3. All flows matching those features are selected
4. Transitive dependencies are pulled in automatically

### Feature-Path Map

| Feature | Path patterns |
|---------|--------------|
| auth | `lib/features/auth/**` |
| projects | `lib/features/projects/**` |
| entries | `lib/features/entries/**` |
| sync | `lib/features/sync/**`, `lib/services/sync_service.dart` |
| quantities | `lib/features/quantities/**` |
| settings | `lib/features/settings/**` |
| photos | `lib/features/photos/**`, `lib/services/photo_service.dart` |
| dashboard | `lib/features/dashboard/**` |
| contractors | `lib/features/contractors/**` |
| locations | `lib/features/locations/**` |
| weather | `lib/features/weather/**` |
| pdf | `lib/features/pdf/**` |
| database | `lib/core/database/**` |
| router | `lib/core/router/**` |
| toolbox | `lib/features/toolbox/**`, `lib/features/calculator/**`, `lib/features/forms/**`, `lib/features/gallery/**`, `lib/features/todos/**` |
| navigation | `lib/core/router/**`, `lib/shared/widgets/**` |

---

## Smoke Tier Flows (3)

---

### login

- **feature**: auth
- **tier**: smoke
- **timeout**: 60s
- **deps**: []
- **steps**:
  1. Verify the login screen is displayed -- look for `login_screen` (content-desc) or email/password fields
  2. Tap the email field (`login_email_field`) and enter test credentials email via `adb shell input text`
  3. Tap the password field (`login_password_field`) and enter test credentials password
  4. Tap the "Sign In" button (`login_sign_in_button`)
  5. Wait up to 10 seconds for navigation to complete
- **verify**: Dashboard screen is visible -- look for `dashboard_project_title` or `dashboard_entries_card` or `bottom_navigation_bar` in UIAutomator XML
- **key-elements**: [login_screen, login_email_field, login_password_field, login_sign_in_button, dashboard_project_title, dashboard_entries_card, bottom_navigation_bar]
- **notes**: Test credentials should be provided via orchestrator config. If OTP is required, this flow will need manual intervention or a test-mode bypass.

---

### navigate-tabs

- **feature**: navigation
- **tier**: smoke
- **timeout**: 60s
- **deps**: [login]
- **steps**:
  1. Verify bottom navigation bar is visible (`bottom_navigation_bar`)
  2. Tap the "Calendar" tab (`calendar_nav_button`) -- verify calendar/home screen loads (look for `add_entry_fab` or calendar content)
  3. Tap the "Projects" tab (`projects_nav_button`) -- verify projects screen loads (look for `project_create_button` or project list content)
  4. Tap the "Settings" tab (`settings_nav_button`) -- verify settings screen loads (look for `settings_theme_dropdown` or settings section headers)
  5. Tap the "Dashboard" tab (`dashboard_nav_button`) -- verify dashboard loads (look for `dashboard_project_title` or dashboard cards)
- **verify**: All 4 tabs loaded without errors. Dashboard screen is currently visible with `dashboard_project_title` or `dashboard_entries_card`.
- **key-elements**: [bottom_navigation_bar, dashboard_nav_button, calendar_nav_button, projects_nav_button, settings_nav_button, add_entry_fab, project_create_button, settings_theme_dropdown, dashboard_project_title, dashboard_entries_card]
- **notes**: Each tab should load within 5 seconds. Check logcat after each tab switch for Flutter errors.

---

### create-entry-quick

- **feature**: entries
- **tier**: smoke
- **timeout**: 90s
- **deps**: [login]
- **steps**:
  1. Navigate to calendar/home screen -- tap `calendar_nav_button`
  2. Tap the add entry FAB (`add_entry_fab`) or create entry button (`home_create_entry_button`)
  3. Wait for entry editor screen to load -- verify `entry_wizard_scroll_view` is present
  4. The date defaults to today -- no action needed
  5. Tap the save draft button (`entry_wizard_save_draft`)
  6. Wait for navigation back to calendar/home screen
- **verify**: Entry appears on today's date. Look for `home_report_preview_section` or an entry card in `home_entry_list_horizontal`. No errors in logcat.
- **key-elements**: [calendar_nav_button, add_entry_fab, home_create_entry_button, entry_wizard_scroll_view, entry_wizard_save_draft, home_report_preview_section, home_entry_list_horizontal]
- **notes**: This is a minimal entry (date only, no location or activities). If no project is selected, the entry wizard may show a project selection prompt first -- handle by selecting the first available project.

---

## Feature Tier Flows (18)

---

### register

- **feature**: auth
- **tier**: feature
- **timeout**: 120s
- **deps**: []
- **steps**:
  1. From the login screen, tap the "Sign Up" button (`login_sign_up_button`)
  2. Wait for registration screen to load -- verify `register_screen_title` is visible
  3. Enter full name in `register_full_name_field` -- use "ADB Test User"
  4. Enter email in `register_email_field` -- use a test email with timestamp
  5. Enter password in `register_password_field` -- use test password
  6. Enter confirm password in `register_confirm_password_field` -- same password
  7. Tap the "Sign Up" button (`register_sign_up_button`)
  8. Wait for navigation (may go to OTP verification or directly to profile setup)
- **verify**: User is navigated away from registration screen. Look for OTP verification screen (`otp_verification_screen_title`) or profile setup. No error snackbars visible.
- **key-elements**: [login_sign_up_button, register_screen_title, register_full_name_field, register_email_field, register_password_field, register_confirm_password_field, register_sign_up_button, otp_verification_screen_title]
- **notes**: Registration may require real email verification. If OTP screen appears, this flow ends at that point. The profile-setup flow continues from there.

---

### forgot-password

- **feature**: auth
- **tier**: feature
- **timeout**: 90s
- **deps**: []
- **steps**:
  1. From the login screen, tap "Forgot Password" link (`forgot_password_link`)
  2. Wait for forgot password screen -- verify `forgot_password_screen_title`
  3. Enter email in `forgot_password_email_field` -- use test email
  4. Tap the send button (`reset_password_send_button`)
  5. Wait for success state or OTP screen
  6. If OTP screen appears (`otp_verification_screen_title`), verify 6 digit fields are visible (`otp_digit_field_0` through `otp_digit_field_5`)
- **verify**: Either a success message is displayed, or the OTP verification screen is visible. No error messages. The `forgot_password_back_button` should be accessible.
- **key-elements**: [forgot_password_link, forgot_password_screen_title, forgot_password_email_field, reset_password_send_button, forgot_password_back_button, forgot_password_try_different_email, otp_verification_screen_title, otp_digit_field_0]
- **notes**: This flow tests the UI path only. Actual OTP entry requires email access. Navigate back after verification.

---

### create-project

- **feature**: projects
- **tier**: feature
- **timeout**: 120s
- **deps**: [login]
- **steps**:
  1. Navigate to projects -- tap `projects_nav_button` in bottom navigation
  2. Tap the create project button (`project_create_button`) or add project FAB (`add_project_fab`)
  3. Wait for project setup screen to load -- look for `project_name_field`
  4. Enter project name in `project_name_field` -- use "ADB Test Project YYYY-MM-DD"
  5. Enter project number in `project_number_field` -- use "ADB-001"
  6. Optionally enter client name in `project_client_field` -- use "Test Client"
  7. Tap the save button (`project_save_button`)
  8. Wait for navigation back to project list or dashboard
- **verify**: The newly created project appears in the project list. Look for a project card containing "ADB Test Project" text. Or dashboard shows `dashboard_project_title` with the new project name.
- **key-elements**: [projects_nav_button, project_create_button, add_project_fab, project_name_field, project_number_field, project_client_field, project_save_button, dashboard_project_title, bottom_navigation_bar]
- **notes**: If a project with the same name already exists, the flow should still pass. Use a timestamped name to avoid confusion.

---

### edit-project

- **feature**: projects
- **tier**: feature
- **timeout**: 120s
- **deps**: [create-project]
- **steps**:
  1. Navigate to projects -- tap `projects_nav_button`
  2. Find the test project card in the list (look for "ADB Test Project" text)
  3. Tap the project card to open it, or find the edit menu item
  4. Wait for project setup screen to load with tabs visible (`project_details_tab`, `project_locations_tab`)
  5. Tap the Locations tab (`project_locations_tab`)
  6. Tap add location button (`project_add_location_button`)
  7. In the location dialog (`location_dialog`), enter name in `location_name_field` -- use "Test Location A"
  8. Tap add button (`location_dialog_add`)
  9. Tap save (`project_save_button`)
  10. Wait for save to complete
- **verify**: Project is saved with the new location. Look for the location name in the project setup or a success indication. No errors in logcat.
- **key-elements**: [projects_nav_button, project_details_tab, project_locations_tab, project_contractors_tab, project_payitems_tab, project_add_location_button, location_dialog, location_name_field, location_dialog_add, project_save_button]
- **notes**: The project setup has tabs for details, locations, contractors, and pay items. This flow tests adding a location.

---

### create-entry

- **feature**: entries
- **tier**: feature
- **timeout**: 180s
- **deps**: [create-project]
- **steps**:
  1. Navigate to calendar/home screen -- tap `calendar_nav_button`
  2. Tap the add entry FAB (`add_entry_fab`) or create entry button (`home_create_entry_button`)
  3. Wait for entry editor screen -- verify `entry_wizard_scroll_view`
  4. Date defaults to today -- no action needed
  5. If location dropdown is visible (`entry_wizard_location_dropdown`), tap it and select the first available location
  6. Enter activities text in the activities field (`entry_wizard_activities`) -- use "ADB test activities - full entry"
  7. Scroll down to see more sections -- use swipe gesture
  8. Enter site safety text in `entry_wizard_site_safety` -- use "All clear"
  9. Tap the save draft button (`entry_wizard_save_draft`)
  10. Wait for navigation back to calendar/home screen
- **verify**: Entry appears on today's date in the calendar. Look for `home_report_preview_section` or an entry card. Draft status is indicated.
- **key-elements**: [calendar_nav_button, add_entry_fab, home_create_entry_button, entry_wizard_scroll_view, entry_wizard_location_dropdown, entry_wizard_activities, entry_wizard_site_safety, entry_wizard_save_draft, home_report_preview_section, home_entry_list_horizontal]
- **notes**: Location dropdown may show a loading state. Wait up to 5s for it to populate. If no locations exist, skip location selection.

---

### edit-entry

- **feature**: entries
- **tier**: feature
- **timeout**: 120s
- **deps**: [create-entry]
- **steps**:
  1. Navigate to calendar/home screen -- tap `calendar_nav_button`
  2. Verify today's entry is visible in `home_entry_list_horizontal` or preview
  3. Tap the entry to open it -- may need to tap entry card then tap `home_view_full_report_button` or `entry_edit_button`
  4. Wait for report/editor screen to load -- verify `report_screen_title` or `entry_wizard_scroll_view`
  5. If in report view, tap edit button (`entry_edit_button`) to enter edit mode
  6. Modify the activities field (`report_activities_field` or `entry_wizard_activities`) -- append " - edited via ADB"
  7. Tap save (`entry_wizard_save_draft` or `entry_wizard_save`)
  8. Wait for save to complete and navigation back
- **verify**: Entry is saved with modified content. The activities field should now contain the appended text. No errors in logcat.
- **key-elements**: [calendar_nav_button, home_entry_list_horizontal, home_view_full_report_button, entry_edit_button, report_screen_title, entry_wizard_scroll_view, report_activities_field, entry_wizard_activities, entry_wizard_save_draft, entry_wizard_save]
- **notes**: The entry may open in report view first, requiring a tap on the edit button to enter edit mode.

---

### review-submit

- **feature**: entries
- **tier**: feature
- **timeout**: 120s
- **deps**: [create-entry]
- **steps**:
  1. Navigate to dashboard -- tap `dashboard_nav_button`
  2. Look for the review drafts card (`review_drafts_card`) and tap it
  3. Wait for drafts list screen (`drafts_list_screen`) to load
  4. Tap "Select All" button (`select_all_drafts_button`)
  5. Tap "Review Selected" button (`review_selected_button`)
  6. Wait for review screen (`review_screen`) to load
  7. Tap "Mark Ready" button (`mark_ready_button`) to mark current entry as ready
  8. If more entries to review, repeat mark ready; otherwise wait for review summary (`review_summary_screen`)
  9. On review summary screen, tap "Submit Batch" button (`submit_batch_button`)
  10. Wait for submission to complete
- **verify**: Entries are submitted. Look for `undo_submission_button` in a submitted banner, or status changes on the entries. No errors in logcat.
- **key-elements**: [dashboard_nav_button, review_drafts_card, drafts_list_screen, select_all_drafts_button, review_selected_button, review_screen, mark_ready_button, skip_review_button, review_summary_screen, submit_batch_button, undo_submission_button]
- **notes**: If no drafts exist, the review drafts card may not appear. This flow depends on create-entry having created at least one draft.

---

### add-contractors

- **feature**: contractors
- **tier**: feature
- **timeout**: 120s
- **deps**: [create-project]
- **steps**:
  1. Navigate to projects -- tap `projects_nav_button`
  2. Open the test project (tap project card with "ADB Test Project" text)
  3. Wait for project setup screen, tap Contractors tab (`project_contractors_tab`)
  4. Tap add contractor button (`contractor_add_button`)
  5. In contractor dialog, enter name in `contractor_name_field` -- use "Prime Contractor Inc."
  6. Tap contractor type dropdown (`contractor_type_dropdown`) and select Prime (`contractor_type_prime`)
  7. Tap save (`contractor_save_button`)
  8. Wait for contractor to appear in list
  9. Tap add contractor again (`contractor_add_button`)
  10. Enter "Sub Contractor LLC" in `contractor_name_field`, select Sub type (`contractor_type_sub`)
  11. Tap save (`contractor_save_button`)
  12. Tap project save (`project_save_button`)
- **verify**: Two contractors visible in the contractors list -- one Prime and one Sub. Project saves without errors.
- **key-elements**: [projects_nav_button, project_contractors_tab, contractor_add_button, contractor_name_field, contractor_type_dropdown, contractor_type_prime, contractor_type_sub, contractor_save_button, contractor_cancel_button, project_save_button]
- **notes**: Equipment and personnel can be added per contractor but are not tested in this flow.

---

### add-quantities

- **feature**: quantities
- **tier**: feature
- **timeout**: 120s
- **deps**: [create-project]
- **steps**:
  1. Navigate to projects -- tap `projects_nav_button`
  2. Open the test project
  3. Tap Pay Items tab (`project_payitems_tab`)
  4. Tap add pay item button (`project_add_pay_item_button`)
  5. In pay item source dialog (`pay_item_source_dialog`), select manual entry (`pay_item_source_manual`)
  6. In pay item dialog (`pay_item_dialog`), enter item number in `pay_item_number_field` -- use "101"
  7. Enter description in `pay_item_description_field` -- use "HMA Surface Course"
  8. Enter quantity in `pay_item_quantity_field` -- use "500"
  9. Tap unit dropdown (`pay_item_unit_dropdown`) and select "TON"
  10. Tap save (`pay_item_dialog_save`)
  11. Tap project save (`project_save_button`)
- **verify**: Pay item "101 - HMA Surface Course" appears in the pay items list. Quantity shows 500. No errors in logcat.
- **key-elements**: [projects_nav_button, project_payitems_tab, project_add_pay_item_button, pay_item_source_dialog, pay_item_source_manual, pay_item_dialog, pay_item_number_field, pay_item_description_field, pay_item_quantity_field, pay_item_unit_dropdown, pay_item_dialog_save, project_save_button]
- **notes**: The pay item source dialog offers Manual, PDF Import, and M&P enrichment options. This flow uses manual entry.

---

### import-pdf

- **feature**: pdf
- **tier**: feature
- **timeout**: 180s
- **deps**: [create-project]
- **steps**:
  1. Navigate to projects -- tap `projects_nav_button`
  2. Open the test project
  3. Tap Pay Items tab (`project_payitems_tab`)
  4. Tap add pay item button (`project_add_pay_item_button`)
  5. In pay item source dialog (`pay_item_source_dialog`), select PDF import (`pay_item_source_pdf`)
  6. Wait for system file picker -- this requires a PDF file to be available on device
  7. If file picker appears, select a test PDF or cancel if no PDF available
  8. If PDF import preview screen loads (`pdf_preview_select_all_button` visible), tap Select All
  9. Tap Import button (`pdf_preview_import_button`)
  10. Wait for import to complete
- **verify**: Imported bid items appear in the pay items list, or if no PDF was available, the flow gracefully handled the cancellation. Check logcat for extraction errors.
- **key-elements**: [projects_nav_button, project_payitems_tab, project_add_pay_item_button, pay_item_source_dialog, pay_item_source_pdf, pdf_preview_select_all_button, pdf_preview_cancel_button, pdf_preview_import_button]
- **notes**: PDF import requires a test PDF file on the device. If none available, this flow should mark as SKIP rather than FAIL. The extraction pipeline may take 30-60 seconds.

---

### capture-photo

- **feature**: photos
- **tier**: feature
- **timeout**: 90s
- **deps**: [create-entry]
- **steps**:
  1. Navigate to calendar/home screen -- tap `calendar_nav_button`
  2. Open today's entry (tap entry card, then `home_view_full_report_button` or `entry_edit_button`)
  3. Wait for report screen or entry editor
  4. Find attachments section (`report_attachments_section`) -- may need to scroll down
  5. Tap add photo button (`report_add_photo_button`) or entry wizard add photo (`entry_wizard_add_photo`)
  6. Photo source dialog (`photo_source_dialog`) appears -- tap Camera option (`photo_capture_camera`) or Gallery (`photo_capture_gallery`)
  7. If camera launches, take a photo via system camera UI
  8. If photo name dialog appears (`photo_name_dialog`), enter filename in `photo_name_filename_field`
  9. Tap save (`photo_name_save`)
- **verify**: Photo appears in the attachments section. Look for a photo thumbnail. No errors in logcat.
- **key-elements**: [calendar_nav_button, entry_edit_button, home_view_full_report_button, report_attachments_section, report_add_photo_button, entry_wizard_add_photo, photo_source_dialog, photo_capture_camera, photo_capture_gallery, photo_name_dialog, photo_name_filename_field, photo_name_save]
- **notes**: Camera interaction requires real device hardware. If permission dialog appears (`permission_dialog`), tap grant (`permission_dialog_grant`). The camera app is a system app -- use vision to find the shutter button.

---

### sync-check

- **feature**: sync
- **tier**: feature
- **timeout**: 60s
- **deps**: [login]
- **steps**:
  1. Navigate to settings -- tap `settings_nav_button`
  2. Scroll to find the sync section (`settings_sync_section`)
  3. Look for the sync status indicator (`sync_status_indicator`)
  4. Tap the manual sync button (`settings_sync_button`)
  5. Wait up to 15 seconds for sync to complete
  6. Check the sync status indicator again
  7. Verify `last_sync_timestamp` shows a recent time
- **verify**: Sync status shows success (not error). No `sync_error_message` visible. `last_sync_timestamp` is updated. No errors in logcat.
- **key-elements**: [settings_nav_button, settings_sync_section, sync_status_indicator, settings_sync_button, last_sync_timestamp, sync_error_message]
- **notes**: If the device is offline, this flow should be marked as SKIP rather than FAIL. Check connectivity first via `adb shell ping -c 1 google.com`.

---

### settings-theme

- **feature**: settings
- **tier**: feature
- **timeout**: 60s
- **deps**: [login]
- **steps**:
  1. Navigate to settings -- tap `settings_nav_button`
  2. Find the appearance section (`settings_appearance_section`)
  3. Locate the theme dropdown (`settings_theme_dropdown`)
  4. Tap the theme dropdown to reveal options
  5. Select "Dark" theme (`settings_theme_dark`)
  6. Wait for theme to apply (1-2 seconds)
  7. Take screenshot to verify dark theme is active
  8. Tap theme dropdown again, select "Light" (`settings_theme_light`)
  9. Wait for theme to apply
- **verify**: Theme changes are visually reflected (use vision to confirm dark/light backgrounds). No errors or crashes during theme switching.
- **key-elements**: [settings_nav_button, settings_appearance_section, settings_theme_dropdown, settings_theme_dark, settings_theme_light, settings_theme_high_contrast]
- **notes**: Theme change should be instant. If the app crashes during theme switch, this is a P0 defect.

---

### edit-profile

- **feature**: settings
- **tier**: feature
- **timeout**: 60s
- **deps**: [login]
- **steps**:
  1. Navigate to settings -- tap `settings_nav_button`
  2. Find the user section (`settings_user_section`)
  3. Tap inspector name tile (`settings_inspector_name_tile`)
  4. Wait for edit dialog (`edit_inspector_name_dialog`)
  5. Clear existing text in `settings_inspector_name_field` and enter "ADB Test Inspector"
  6. Tap save (`edit_inspector_name_save`)
  7. Wait for dialog to close
  8. Tap inspector initials tile (`settings_inspector_initials_tile`)
  9. Wait for edit initials dialog (`edit_initials_dialog`)
  10. Clear existing text in `settings_inspector_initials_field` and enter "ATI"
  11. Tap save (`edit_initials_save`)
- **verify**: Inspector name shows "ADB Test Inspector" and initials show "ATI" in the settings user section. No errors in logcat.
- **key-elements**: [settings_nav_button, settings_user_section, settings_inspector_name_tile, edit_inspector_name_dialog, settings_inspector_name_field, edit_inspector_name_save, edit_inspector_name_cancel, settings_inspector_initials_tile, edit_initials_dialog, settings_inspector_initials_field, edit_initials_save, edit_initials_cancel, edit_initials_reset_to_auto]
- **notes**: The initials field has an auto-generate feature. "Reset to Auto" button is available but not tested here.

---

### calculator

- **feature**: toolbox
- **tier**: feature
- **timeout**: 60s
- **deps**: [login]
- **steps**:
  1. Navigate to dashboard -- tap `dashboard_nav_button`
  2. Tap the Toolbox card (`dashboard_toolbox_card`)
  3. Wait for toolbox screen (`toolbox_home_screen`)
  4. Tap the Calculator card (`toolbox_calculator_card`)
  5. Wait for calculator screen (`calculator_screen`) to load
  6. Verify calculator tabs are visible (`calculator_tabs`)
  7. Tap the HMA tab (`calculator_hma_tab`)
  8. Enter area in `calculator_hma_area` -- use "1000"
  9. Enter thickness in `calculator_hma_thickness` -- use "2"
  10. Enter density in `calculator_hma_density` -- use "145"
  11. Tap calculate button (`calculator_hma_calculate_button` or `calculator_calculate_button`)
  12. Verify result card appears (`calculator_result_card`)
- **verify**: Calculation result is displayed in the result card. The result should be a reasonable tonnage value. No errors in logcat.
- **key-elements**: [dashboard_nav_button, dashboard_toolbox_card, toolbox_home_screen, toolbox_calculator_card, calculator_screen, calculator_tabs, calculator_hma_tab, calculator_hma_area, calculator_hma_thickness, calculator_hma_density, calculator_hma_calculate_button, calculator_calculate_button, calculator_result_card]
- **notes**: Calculator has multiple tabs (HMA, Concrete, Area, Volume, Linear). This flow tests HMA only.

---

### forms-fill

- **feature**: toolbox
- **tier**: feature
- **timeout**: 120s
- **deps**: [create-project]
- **steps**:
  1. Navigate to dashboard -- tap `dashboard_nav_button`
  2. Tap the Toolbox card (`dashboard_toolbox_card`)
  3. Wait for toolbox screen (`toolbox_home_screen`)
  4. Tap the Forms card (`toolbox_forms_card`)
  5. Wait for forms list screen (`forms_list_screen`)
  6. If forms are available, tap the first form card
  7. Wait for form viewer/hub screen to load
  8. Fill in available fields -- specific fields depend on which form is loaded
  9. Tap save button (`form_save_button` or `mdot_hub_save_button`)
  10. Wait for save to complete
- **verify**: Form is saved successfully. No error snackbars. If no forms available (`forms_list_empty`), mark as SKIP.
- **key-elements**: [dashboard_nav_button, dashboard_toolbox_card, toolbox_home_screen, toolbox_forms_card, forms_list_screen, forms_list_empty, save_button, mdot_hub_screen, mdot_hub_save_button]
- **notes**: Form fields are dynamic and depend on the form template. The wave agent should use vision to identify fillable fields. If no forms are configured for the project, this should SKIP.

---

### gallery-browse

- **feature**: toolbox
- **tier**: feature
- **timeout**: 60s
- **deps**: [login]
- **steps**:
  1. Navigate to dashboard -- tap `dashboard_nav_button`
  2. Tap the Toolbox card (`dashboard_toolbox_card`)
  3. Wait for toolbox screen (`toolbox_home_screen`)
  4. Tap the Gallery card (`toolbox_gallery_card`)
  5. Wait for gallery screen (`gallery_screen`) to load
  6. Check if photos exist -- look for `gallery_grid` or `gallery_empty_state`
  7. If photos exist, verify the grid displays photo thumbnails
  8. If filter button visible (`gallery_filter_button`), tap it and verify filter options load
- **verify**: Gallery screen loaded successfully. Either photos are displayed in a grid, or empty state is shown. No crashes or errors.
- **key-elements**: [dashboard_nav_button, dashboard_toolbox_card, toolbox_home_screen, toolbox_gallery_card, gallery_screen, gallery_grid, gallery_empty_state, gallery_filter_button, gallery_filter_all, gallery_filter_today]
- **notes**: Gallery may be empty if no photos have been taken in the project. Empty state is acceptable.

---

### todos-crud

- **feature**: toolbox
- **tier**: feature
- **timeout**: 60s
- **deps**: [login]
- **steps**:
  1. Navigate to dashboard -- tap `dashboard_nav_button`
  2. Tap the Toolbox card (`dashboard_toolbox_card`)
  3. Wait for toolbox screen (`toolbox_home_screen`)
  4. Tap the Todos card (`toolbox_todos_card`)
  5. Wait for todos screen (`todos_screen`) to load
  6. Tap add button (`todos_add_button`)
  7. Wait for todo dialog (`todos_dialog`)
  8. Enter title in `todos_title_field` -- use "ADB Test Todo"
  9. Optionally enter description in `todos_description_field`
  10. Tap save (`todos_save_button`)
  11. Wait for todo to appear in list (`todos_list`)
  12. Find the todo card and tap it to open edit dialog
  13. Tap save or complete the todo
- **verify**: Todo "ADB Test Todo" appears in the todos list. CRUD operations work without errors.
- **key-elements**: [dashboard_nav_button, dashboard_toolbox_card, toolbox_home_screen, toolbox_todos_card, todos_screen, todos_list, todos_add_button, todos_dialog, todos_title_field, todos_description_field, todos_save_button, todos_cancel_button, todos_empty_state]
- **notes**: Todo completion can be tested by tapping the checkbox on the todo card.

---

## Additional Feature Flows (9, for journey support)

---

### profile-setup

- **feature**: auth
- **tier**: feature
- **timeout**: 90s
- **deps**: [register]
- **steps**:
  1. After registration, user should be on profile setup or prompted to complete profile
  2. Look for profile setup fields (inspector name, title) -- use settings keys as fallback
  3. Enter inspector name if prompted -- use "ADB New Inspector"
  4. Enter any other required profile fields
  5. Tap save/continue button
- **verify**: Profile is completed. User is navigated to the next onboarding step (company setup) or dashboard. No error messages.
- **key-elements**: [settings_inspector_name_field, settings_inspector_initials_field, settings_inspector_phone_field, settings_inspector_cert_field]
- **notes**: Profile setup flow may vary. Use vision to identify the current screen and fill in visible fields. This flow is tightly coupled with the registration flow.

---

### company-setup

- **feature**: auth
- **tier**: feature
- **timeout**: 90s
- **deps**: [profile-setup]
- **steps**:
  1. After profile setup, user should be on company selection/creation screen
  2. Look for company-related fields or a company list
  3. If creating a company: enter company name -- use "ADB Test Company"
  4. If joining a company: select from list or enter company code
  5. Tap save/join/continue button
- **verify**: User has a company associated. Dashboard becomes accessible. No error messages.
- **key-elements**: []
- **notes**: Company setup UI elements may not have dedicated TestingKeys yet. Use text-based and vision-based element finding. This flow completes the onboarding journey.

---

### admin-dashboard

- **feature**: settings
- **tier**: feature
- **timeout**: 60s
- **deps**: [login]
- **steps**:
  1. Navigate to settings -- tap `settings_nav_button`
  2. Look for admin panel or company management section
  3. If admin features are visible, tap to open admin dashboard
  4. Verify admin panel loads with member management options
- **verify**: Admin dashboard is accessible and displays member/request information. If user is not admin, mark as SKIP.
- **key-elements**: [settings_nav_button, settings_account_section]
- **notes**: Admin features are only available to company admins. If the test user is not an admin, this flow should SKIP. Admin-specific TestingKeys may need to be added in a future update.

---

### approve-member

- **feature**: settings
- **tier**: feature
- **timeout**: 60s
- **deps**: [admin-dashboard]
- **steps**:
  1. From admin dashboard, look for pending member requests
  2. If a pending request exists, tap to view it
  3. Tap approve button
  4. Wait for approval to complete
- **verify**: Member request is approved. The request no longer appears in pending list. No errors in logcat.
- **key-elements**: []
- **notes**: This flow requires a pending member request to exist. If none exist, mark as SKIP. Admin-specific TestingKeys may need to be added.

---

### quantities-check

- **feature**: quantities
- **tier**: feature
- **timeout**: 60s
- **deps**: [add-quantities]
- **steps**:
  1. Navigate to dashboard -- tap `dashboard_nav_button`
  2. Look for pay items card (`dashboard_pay_items_card`) or quantities overview
  3. Tap to open quantities screen
  4. Verify quantities screen loads (`quantities_search_field` or `quantities_sort_button` visible)
  5. Look for the bid item added in add-quantities flow ("101 - HMA Surface Course")
  6. Verify budget tracking shows correct totals
- **verify**: Quantities screen displays bid items with correct quantities. Budget tracking data is visible and consistent. No errors.
- **key-elements**: [dashboard_nav_button, dashboard_pay_items_card, dashboard_view_all_quantities_button, quantities_search_field, quantities_sort_button, quantities_import_button]
- **notes**: This flow verifies the data created by add-quantities is correctly displayed in the quantities overview screen.

---

### create-entry-day2

- **feature**: entries
- **tier**: feature
- **timeout**: 120s
- **deps**: [create-entry]
- **steps**:
  1. Navigate to calendar/home screen -- tap `calendar_nav_button`
  2. Navigate to a different date -- tap `calendar_prev_month` or `calendar_next_month`, or tap a different day
  3. Tap the add entry FAB (`add_entry_fab`) or create entry button (`home_create_entry_button`)
  4. Wait for entry editor -- verify `entry_wizard_scroll_view`
  5. Enter activities text in `entry_wizard_activities` -- use "ADB test day 2 activities"
  6. Tap save draft (`entry_wizard_save_draft`)
  7. Wait for save to complete
- **verify**: A second entry exists on a different date. Calendar shows entries on both days. No errors.
- **key-elements**: [calendar_nav_button, calendar_prev_month, calendar_next_month, add_entry_fab, home_create_entry_button, entry_wizard_scroll_view, entry_wizard_activities, entry_wizard_save_draft]
- **notes**: Navigate to yesterday's date for predictability. The calendar day key is dynamic: `calendar_day_YYYY-MM-DD`.

---

### create-entry-offline

- **feature**: entries
- **tier**: feature
- **timeout**: 120s
- **deps**: [login]
- **steps**:
  1. Disable WiFi and mobile data via ADB:
     ```
     adb shell svc wifi disable
     adb shell svc data disable
     ```
  2. Wait 3 seconds for connectivity change to propagate
  3. Verify offline indicator is visible (`offline_indicator`) -- or check via `adb shell ping -c 1 google.com` fails
  4. Navigate to calendar/home screen -- tap `calendar_nav_button`
  5. Tap add entry FAB (`add_entry_fab`)
  6. Wait for entry editor -- verify `entry_wizard_scroll_view`
  7. Enter activities in `entry_wizard_activities` -- use "Offline entry via ADB"
  8. Tap save draft (`entry_wizard_save_draft`)
  9. Verify entry saved locally without sync errors
- **verify**: Entry created successfully while offline. No crash, no sync error dialog. Entry appears in calendar with pending sync status. Logcat shows offline-aware behavior.
- **key-elements**: [calendar_nav_button, add_entry_fab, entry_wizard_scroll_view, entry_wizard_activities, entry_wizard_save_draft, offline_indicator, home_report_preview_section]
- **notes**: CRITICAL -- Re-enable connectivity after this flow or in sync-reconnect flow. If connectivity is not restored, subsequent flows will fail. The offline indicator should appear in the app shell.

---

### add-contractors-entry

- **feature**: contractors
- **tier**: feature
- **timeout**: 90s
- **deps**: [create-entry, add-contractors]
- **steps**:
  1. Navigate to calendar/home screen -- tap `calendar_nav_button`
  2. Open today's entry (tap entry card, then `home_view_full_report_button`)
  3. Wait for report screen -- verify `report_screen_title`
  4. Scroll to contractors section (`calendar_report_contractors_section`)
  5. Tap add contractor button (`calendar_report_add_contractor_button` or `report_add_contractor_button`)
  6. Wait for add contractor sheet (`report_add_contractor_sheet`)
  7. Select the prime contractor from the list
  8. Tap save (`report_save_contractor_button`)
  9. Verify contractor appears in the entry's contractors section
- **verify**: Contractor is added to the entry. Contractor card visible in the report contractors section. No errors in logcat.
- **key-elements**: [calendar_nav_button, home_view_full_report_button, report_screen_title, calendar_report_contractors_section, calendar_report_add_contractor_button, report_add_contractor_button, report_add_contractor_sheet, report_save_contractor_button, report_cancel_contractor_button]
- **notes**: This flow depends on both create-entry (entry exists) and add-contractors (contractors exist in project). The add contractor sheet shows project-level contractors available to add to the entry.

---

### sync-reconnect

- **feature**: sync
- **tier**: feature
- **timeout**: 90s
- **deps**: [create-entry-offline]
- **steps**:
  1. Re-enable WiFi and mobile data:
     ```
     adb shell svc wifi enable
     adb shell svc data enable
     ```
  2. Wait 5 seconds for connectivity to restore
  3. Verify connectivity: `adb shell ping -c 1 google.com`
  4. Navigate to settings -- tap `settings_nav_button`
  5. Scroll to sync section (`settings_sync_section`)
  6. Tap manual sync button (`settings_sync_button`)
  7. Wait up to 15 seconds for sync to complete
  8. Check sync status (`sync_status_indicator`) and last sync timestamp (`last_sync_timestamp`)
- **verify**: Sync completes successfully. The offline entry is synced. `last_sync_timestamp` is updated. No `sync_error_message` visible. Logcat shows successful sync.
- **key-elements**: [settings_nav_button, settings_sync_section, sync_status_indicator, settings_sync_button, last_sync_timestamp, sync_error_message]
- **notes**: CRITICAL -- This flow MUST re-enable connectivity. If create-entry-offline disabled it, this flow restores it. Verify both WiFi and data are re-enabled.

---

## Journey Tier (12 journeys)

---

### J1: onboarding

- **tier**: journey
- **flows**: [register, profile-setup, company-setup]
- **description**: New user signup through dashboard access. Tests the complete onboarding funnel from registration to having a company associated.

---

### J2: daily-work

- **tier**: journey
- **flows**: [login, create-project, create-entry, add-quantities, review-submit, sync-check]
- **description**: Full inspector daily workflow. Login, set up a project, create a detailed entry, log quantities, review and submit, then sync to cloud.

---

### J3: project-setup

- **tier**: journey
- **flows**: [login, create-project, edit-project, import-pdf, add-contractors]
- **description**: Complete project configuration. Create a project, add locations, import bid items from PDF, and add contractors.

---

### J4: field-documentation

- **tier**: journey
- **flows**: [login, create-entry, capture-photo, forms-fill, add-quantities]
- **description**: Entry with all documentation attachments. Create an entry, capture a photo, fill out a form, and log quantities.

---

### J5: offline-sync

- **tier**: journey
- **flows**: [login, create-entry-offline, sync-reconnect]
- **description**: Offline-first verification. Create an entry while offline, reconnect, and verify it syncs successfully.

---

### J6: admin-flow

- **tier**: journey
- **flows**: [login, admin-dashboard, approve-member]
- **description**: Admin member management. Login as admin, access admin dashboard, approve a pending member request.

---

### J7: budget-tracking

- **tier**: journey
- **flows**: [login, create-project, import-pdf, add-quantities, quantities-check]
- **description**: Budget tracking end-to-end. Set up a project, import bid items, log quantities, and verify budget tracking shows correct totals.

---

### J8: entry-lifecycle

- **tier**: journey
- **flows**: [login, create-entry, edit-entry, capture-photo, review-submit]
- **description**: Single entry lifecycle from draft to submitted. Create, edit, attach a photo, then review and submit.

---

### J9: multi-day

- **tier**: journey
- **flows**: [login, create-entry, create-entry-day2, review-submit]
- **description**: Batch work across multiple days. Create entries for different dates, then batch review and submit them.

---

### J10: contractor-mgmt

- **tier**: journey
- **flows**: [login, create-project, add-contractors, create-entry, add-contractors-entry]
- **description**: Contractor setup and entry usage. Set up contractors at the project level, create an entry, then add contractors to the entry.

---

### J11: settings-personalization

- **tier**: journey
- **flows**: [login, settings-theme, edit-profile, todos-crud]
- **description**: Inspector customization. Change theme, edit profile (name and initials), and create/manage todos.

---

### J12: data-recovery

- **tier**: journey
- **flows**: [login, create-entry-offline, sync-reconnect, edit-entry, sync-check]
- **description**: Offline data recovery cycle. Create an entry offline, reconnect and sync, edit the synced entry, then sync again to verify round-trip integrity.
