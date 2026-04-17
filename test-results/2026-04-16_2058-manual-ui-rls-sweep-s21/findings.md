# Findings

Run started UTC: 2026-04-17T00:58:13.0220419Z

## S21-001 - Dashboard forward flow opens empty state instead of feature cards

- Severity: high
- Category: missing_control
- Feature: dashboard
- Device: s21
- Role: admin
- Route: `/`
- Screen: `project_dashboard_screen`
- Steps: seed `base_data`; navigate `/`; find `project_dashboard_screen`; tap `dashboard_toolbox_card`
- Expected: seeded project dashboard has dashboard cards/links, including `dashboard_toolbox_card`, and opens `toolbox_home_screen`.
- Actual: root dashboard renders `No Project Selected`; `dashboard_toolbox_card`, `dashboard_entries_card`, `dashboard_new_entry_button`, and other dashboard cards are absent. Only `dashboard_view_projects_button` exists.
- Evidence: `devices/s21/screenshots/dashboard-empty-state-forward-fail.png`; `devices/s21/logs/dashboard-forward_happy.txt`
- Status: open

## S21-002 - S21 sync state is unhealthy during dashboard baseline

- Severity: high
- Category: sync_error
- Feature: dashboard
- Device: s21
- Role: admin
- Route: `/`
- Screen: `project_dashboard_screen`
- Steps: seed `base_data`; wait for dashboard; review debug log server and sync status.
- Expected: seeded baseline does not put sync into stuck/repair state; no blocked harness rows, circuit breaker, or conflict indicators appear during feature UI checks.
- Actual: visible banner says sync items need repair; sync status reports errors/conflicts; debug logs show blocked child rows for `harness-project-001`, `change_log exceeds 1000`, and non-retryable circuit breaker state.
- Evidence: `devices/s21/logs/dashboard-sync-after-forward-fail.txt`; `devices/s21/screenshots/dashboard-empty-state-forward-fail.png`
- Status: open

## S21-003 - Realtime hint registration reports too many active subscriptions

- Severity: high
- Category: sync_error
- Feature: sync_ui
- Device: s21
- Role: admin
- Route: `/projects`
- Screen: `project_list_screen`
- Steps: navigate from dashboard empty state to projects; review sync logs.
- Expected: realtime hint registration is stable during manual UI sweep.
- Actual: debug logs report `register_sync_hint_channel: too many active subscriptions (max 10)` while a quick sync is running.
- Evidence: `devices/s21/logs/project-list-after-dashboard-fail-tree.txt`; `devices/s21/logs/dashboard-sync-after-forward-fail.txt`
- Status: open

## S21-004 - Bottom nav does not return from Projects to Dashboard during dashboard nav-switch flow

- Severity: high
- Category: broken_forward_flow
- Feature: dashboard
- Device: s21
- Role: admin
- Route: `/projects`
- Screen: `project_list_screen`
- Steps: navigate `/`; tap `projects_nav_button`; wait `project_list_screen`; tap `dashboard_nav_button`; wait `project_dashboard_screen`.
- Expected: tapping Dashboard bottom-nav from Projects returns to `project_dashboard_screen` on `/`.
- Actual: `project_dashboard_screen` timed out and current route remained `/projects`.
- Evidence: `devices/s21/logs/dashboard-nav-switch-retest.txt`; `devices/s21/screenshots/dashboard-nav-switch-retest.png`; `devices/s21/logs/dashboard-nav-switch-retest-tree.txt`
- Status: open


## S21-005 - Entry editor route renders without required screen sentinel

- Severity: high
- Category: test_harness_gap
- Feature: entries
- Device: s21
- Role: admin
- Route: `/entry/harness-project-001/2026-04-16`
- Screen: visible entry editor, missing `entry_editor_screen`
- Steps: seed `entry_draft`; navigate `/entries`; wait `entries_list_screen`; tap `entries_list_filter_button`; navigate `/entry/harness-project-001/2026-04-16`; wait `entry_editor_screen`.
- Expected: entry editor exposes `entry_editor_screen` sentinel for flow verification.
- Actual: visible editor rendered, but `entry_editor_screen` is absent; only `entry_editor_scroll` and `report_export_pdf_button` are found.
- Evidence: `devices/s21/screenshots/entries-forward-editor-missing.png`; `devices/s21/logs/entries-forward_happy.txt`; `devices/s21/logs/entries-forward-editor-missing-tree.txt`
- Status: open

## S21-006 - Harness seed data pushes cross-company project rows under real session

- Severity: high
- Category: sync_error
- Feature: entries
- Device: s21
- Role: admin
- Route: `/entry/harness-project-001/2026-04-16`
- Screen: visible entry editor
- Steps: seed `entry_draft`; navigate entry; review debug sync logs.
- Expected: seeded harness rows match the real logged-in company or remain local without poisoning sync.
- Actual: sync push rejects `projects/harness-project-001` because it has `harness-company-001`, while the logged-in user belongs to company `26fe92cd-7044-4412-9a09-5c5f49a292f9`; child `daily_entries` rows are blocked.
- Evidence: `devices/s21/logs/entries-forward-sync.txt`; `devices/s21/sync/entries-forward-sync-status.json`
- Status: open

## S21-007 - `/review-summary` does not render review summary and lands on dashboard

- Severity: high
- Category: route_mismatch
- Feature: entries
- Device: s21
- Role: admin
- Route: expected `/review-summary`, actual `/`
- Screen: `project_dashboard_screen`
- Steps: navigate `/review-summary`; wait `review_summary_list`.
- Expected: review summary screen renders with `review_summary_list`, then back returns to entries list.
- Actual: `review_summary_list` timed out; current route became `/` and `project_dashboard_screen` was visible.
- Evidence: `devices/s21/screenshots/entries-review-summary-missing.png`; `devices/s21/logs/entries-backward_traversal.txt`
- Status: open

## S21-008 - Entries flow references absent `entry_wizard_save_draft` key

- Severity: medium
- Category: test_harness_gap
- Feature: entries
- Device: s21
- Role: admin
- Route: `/entry/harness-project-001/2026-04-16`
- Screen: visible entry editor
- Steps: navigate entry; wait `entry_editor_scroll`; find `entry_wizard_save_draft`; scroll to `entry_wizard_save`.
- Expected: feature spec action key `entry_wizard_save_draft` exists on the entry editor.
- Actual: `entry_wizard_save_draft` is absent; the live save control uses `entry_wizard_save` and becomes visible after scrolling.
- Evidence: `devices/s21/logs/entries-nav_bar_switch_mid_flow.txt`
- Status: open

## S21-009 - Form response deep link renders viewer instead of expected MDOT hub sentinel

- Severity: high
- Category: route_mismatch
- Feature: forms
- Device: s21
- Role: admin
- Route: `/form/harness-response-001`
- Screen: `form_viewer_screen`
- Steps: seed `form_response_draft`; navigate `/forms`; wait `form_gallery_screen`; navigate `/form/harness-response-001`; wait `mdot_hub_screen`.
- Expected: feature spec forward flow reaches `mdot_hub_screen` and can save through `mdot_hub_save_button`.
- Actual: route renders `form_viewer_screen`; `mdot_hub_screen` is absent.
- Evidence: `devices/s21/screenshots/forms-mdot-hub-missing.png`; `devices/s21/logs/forms-forward_happy.txt`
- Status: open

## S21-010 - Form viewer S21 action labels show duplicated plus copy

- Severity: low
- Category: layout_clipping
- Feature: forms
- Device: s21
- Role: admin
- Route: `/form/harness-response-001`
- Screen: `form_viewer_screen`
- Steps: open seeded form response.
- Expected: action button labels are clean and compact.
- Actual: visible action buttons read like `+ + Test`, `+ Proctor`, and `+ Weights`; the first button duplicates the plus affordance and the title truncates to `MDOT_0...`.
- Evidence: `devices/s21/screenshots/forms-mdot-hub-missing.png`
- Status: open

## S21-011 - Back at `/entries` root strands user on screen without bottom nav

- Severity: high
- Category: broken_back_flow
- Feature: entries
- Device: s21
- Role: admin
- Route: `/entries`
- Screen: `entries_list_screen`
- Steps: navigate `/entries`; wait `entries_list_screen`; press back.
- Expected: back at entries root resolves predictably to dashboard/home or an expected shell destination.
- Actual: driver reports `navigatedBack: false`; route remains `/entries`; `hasBottomNav` is false, so the screen is stranded from bottom navigation.
- Evidence: `devices/s21/logs/entries-back_at_root.txt`
- Status: open

## S21-012 - Entry PDF export logs `PDF generation failed`

- Severity: high
- Category: runtime_error
- Feature: entries
- Device: s21
- Role: admin
- Route: `/report/harness-entry-001`
- Screen: visible report/editor surface
- Steps: seed `entry_submitted`; navigate `/report/harness-entry-001`; tap `report_export_pdf_button`; review debug logs.
- Expected: export succeeds or presents a recoverable user-facing error without runtime error logs.
- Actual: debug log records `ERROR app PDF generation failed` immediately after the export tap.
- Evidence: `devices/s21/logs/entries-export_verification.txt`; `devices/s21/screenshots/entries-export-after-tap.png`
- Status: open

## S21-013 - Form response deep link is stranded; back does not return to gallery

- Severity: high
- Category: broken_back_flow
- Feature: forms
- Device: s21
- Role: admin
- Route: `/form/harness-response-001`
- Screen: `form_viewer_screen`
- Steps: navigate `/form/harness-response-001`; press back.
- Expected: back returns to `form_gallery_screen` or another intuitive form entry surface.
- Actual: driver reports `navigatedBack: false`; route remains `/form/harness-response-001`; `hasBottomNav` is false.
- Evidence: `devices/s21/logs/forms-backward_traversal.txt`; `devices/s21/screenshots/forms-mdot-hub-missing.png`
- Status: open

## S21-014 - Back at `/forms` root strands user without bottom nav

- Severity: high
- Category: broken_back_flow
- Feature: forms
- Device: s21
- Role: admin
- Route: `/forms`
- Screen: `form_gallery_screen`
- Steps: navigate `/forms`; wait `form_gallery_screen`; press back.
- Expected: back at forms root resolves predictably or bottom nav remains available.
- Actual: driver reports `navigatedBack: false`; route remains `/forms`; `hasBottomNav` is false.
- Evidence: `devices/s21/logs/forms-back_at_root.txt`
- Status: open

## S21-015 - Form PDF preview opens without `form_pdf_preview_screen` sentinel

- Severity: high
- Category: test_harness_gap
- Feature: forms
- Device: s21
- Role: admin
- Route: `/form/harness-response-001`
- Screen: visible PDF Preview
- Steps: open seeded form response; tap `form_preview_pdf_button`; find `form_pdf_preview_screen`.
- Expected: visible PDF preview exposes `form_pdf_preview_screen` for driver verification.
- Actual: screenshot shows PDF Preview, but `form_pdf_preview_screen` is absent and `form_viewer_screen` still reports true.
- Evidence: `devices/s21/screenshots/forms-preview-after-tap.png`; `devices/s21/logs/forms-preview_verification.txt`
- Status: open

## S21-016 - Form export dialog is visible but missing expected driver keys

- Severity: high
- Category: test_harness_gap
- Feature: forms
- Device: s21
- Role: admin
- Route: `/form/harness-response-001`
- Screen: visible Export Form dialog
- Steps: open form viewer; tap `form_export_button`; find `form_export_dialog` and action keys.
- Expected: export dialog exposes `form_export_dialog`, `form_export_preview_button`, `form_export_save_button`, and `form_export_share_button` keys.
- Actual: dialog is visible, but all expected export dialog/action keys are absent.
- Evidence: `devices/s21/screenshots/forms-export-after-tap.png`; `devices/s21/logs/forms-export_verification.txt`
- Status: open

## S21-017 - Pay app comparison opens with missing export file error

- Severity: high
- Category: runtime_error
- Feature: pay_applications
- Device: s21
- Role: admin
- Route: `/pay-app/harness-pay-app-001`
- Screen: `contractor_comparison_screen`
- Steps: seed `pay_app_draft`; navigate `/pay-app/harness-pay-app-001`; tap `pay_app_compare_button`.
- Expected: contractor comparison opens without red error banners and loads the saved pay app context.
- Actual: comparison screen shows `PathNotFoundException: Cannot open file, path = 'C:/harness/export/harness-pay-app.xlsx'`; debug logs include `[ContractorComparisonProvider] loadPayApp failed`.
- Evidence: `devices/s21/screenshots/pay-app-forward-comparison.png`; `devices/s21/logs/pay-applications-forward_happy.txt`
- Status: open

## S21-018 - Back at pay app detail root strands user without bottom nav

- Severity: high
- Category: broken_back_flow
- Feature: pay_applications
- Device: s21
- Role: admin
- Route: `/pay-app/harness-pay-app-001`
- Screen: `pay_app_detail_screen`
- Steps: navigate pay app detail; press back.
- Expected: back at pay app detail returns to an intuitive feature entry route or dashboard.
- Actual: driver reports `navigatedBack: false`; route remains `/pay-app/harness-pay-app-001`; `hasBottomNav` is false.
- Evidence: `devices/s21/logs/pay-applications-back_at_root.txt`
- Status: open

## S21-019 - Quantities opens to `No Project Selected` despite seeded project data

- Severity: high
- Category: missing_control
- Feature: quantities
- Device: s21
- Role: admin
- Route: `/quantities`
- Screen: `quantities_screen`
- Steps: seed entry/project data; navigate `/quantities`; wait `quantities_screen`; tap sort.
- Expected: quantities/pay items surface opens with the seeded or selected project context available.
- Actual: visible screen says `No Project Selected` and asks to select a project; the seeded harness context is not selected for the feature flow.
- Evidence: `devices/s21/screenshots/quantities-forward-sort.png`; `devices/s21/logs/quantities-forward_happy.txt`
- Status: open

## S21-020 - Back from quantity calculator does not return to quantities

- Severity: high
- Category: broken_back_flow
- Feature: quantities
- Device: s21
- Role: admin
- Route: `/quantity-calculator/harness-entry-001`
- Screen: `quantity_calculator_screen`
- Steps: navigate quantity calculator; press back.
- Expected: back returns to `quantities_screen`.
- Actual: driver reports `navigatedBack: false`; route remains `/quantity-calculator/harness-entry-001`; `hasBottomNav` is false.
- Evidence: `devices/s21/logs/quantities-backward_traversal.txt`; `devices/s21/screenshots/quantities-calculator.png`
- Status: open

## S21-021 - Quantities root has no bottom nav for nav-switch flow

- Severity: high
- Category: broken_forward_flow
- Feature: quantities
- Device: s21
- Role: admin
- Route: `/quantities`
- Screen: `quantities_screen`
- Steps: navigate `/quantities`; tap `projects_nav_button`.
- Expected: nav switch from quantities root works or the feature provides an expected shell return path.
- Actual: `projects_nav_button` is absent because `/quantities` is outside the bottom-nav shell.
- Evidence: `devices/s21/logs/quantities-nav_bar_switch_mid_flow.txt`
- Status: open

## S21-022 - Quantities export action does not open export hub from empty project state

- Severity: medium
- Category: broken_forward_flow
- Feature: quantities
- Device: s21
- Role: admin
- Route: `/quantities`
- Screen: `quantities_screen`
- Steps: open `/quantities` in `No Project Selected` state; tap `pay_app_export_button`.
- Expected: export action either opens the export hub or presents a clear disabled/blocked explanation.
- Actual: tap returns success but the screen remains `/quantities`; `pay_app_export_hub_list` and `pay_app_export_hub_create_new` are absent.
- Evidence: `devices/s21/screenshots/quantities-export-after-tap.png`; `devices/s21/logs/quantities-export_verification.txt`
- Status: open

## S21-023 - Back at analytics root strands user without bottom nav

- Severity: high
- Category: broken_back_flow
- Feature: analytics
- Device: s21
- Role: admin
- Route: `/analytics/harness-project-001`
- Screen: `project_analytics_screen`
- Steps: navigate analytics deep link; close date filter if open; press back.
- Expected: back returns to dashboard/project context.
- Actual: driver reports `navigatedBack: false`; route remains `/analytics/harness-project-001`; `hasBottomNav` is false.
- Evidence: `devices/s21/logs/analytics-back_at_root.txt`; `devices/s21/screenshots/analytics-deep-link.png`
- Status: open

## S21-024 - Injected PDF import extracts successfully but preview screen is not driver-visible

- Severity: high
- Category: route_mismatch
- Feature: pdf
- Device: s21
- Role: admin
- Route: driver reports `/quantities`; logs show `import-preview` push
- Screen: screenshot shows `project_list_screen`; driver also reports both `project_list_screen` and `quantities_screen` true
- Steps: select real project; navigate `/quantities`; inject `springfield_864130_pay_items.pdf`; tap `quantities_import_button`; wait for processing; find `pdf_preview_screen`.
- Expected: after extraction completes, app displays PDF import preview with `pdf_preview_screen`, `pdf_preview_select_all_button`, and `pdf_preview_import_button`.
- Actual: logs show extraction success with 131 items and `Route push: import-preview`, but `pdf_preview_screen` never appears. Screenshot shows Projects list while current route reports `/quantities`; both `project_list_screen` and `quantities_screen` report true, indicating route/sentinel state confusion.
- Evidence: `devices/s21/logs/pdf-import-after-inject.txt`; `devices/s21/screenshots/pdf-import-after-wait.png`
- Status: open

## S21-025 - Gallery shows photo placeholders instead of thumbnails

- Severity: medium
- Category: layout_clipping
- Feature: gallery
- Device: s21
- Role: admin
- Route: `/gallery`
- Screen: `gallery_screen`
- Steps: navigate `/gallery`; review visible grid.
- Expected: gallery thumbnails render actual photo previews or clear missing-image state.
- Actual: screen says `4 of 4 photos`, but every tile displays a generic placeholder image icon.
- Evidence: `devices/s21/screenshots/gallery-root.png`; `devices/s21/screenshots/gallery-filter-after-tap.png`
- Status: open

## S21-026 - Back/nav switch from gallery root is stranded

- Severity: high
- Category: broken_back_flow
- Feature: gallery
- Device: s21
- Role: admin
- Route: `/gallery`
- Screen: `gallery_screen`
- Steps: navigate `/gallery`; open/close filter; press back at root; check bottom nav.
- Expected: back returns to toolbox/dashboard or bottom nav is available.
- Actual: root back returns `navigatedBack: false`; `hasBottomNav` is false; bottom nav keys such as `settings_nav_button` are absent.
- Evidence: `devices/s21/logs/gallery-backward_traversal.txt`; `devices/s21/screenshots/gallery-root.png`
- Status: open

## S21-027 - Back/nav switch from toolbox root is stranded

- Severity: high
- Category: broken_back_flow
- Feature: toolbox
- Device: s21
- Role: admin
- Route: `/toolbox`
- Screen: `toolbox_home_screen`
- Steps: navigate `/toolbox`; press back at root; check bottom nav.
- Expected: toolbox root returns to dashboard or has bottom nav available.
- Actual: back returns `navigatedBack: false`; `settings_nav_button` is absent on toolbox root.
- Evidence: `devices/s21/screenshots/toolbox-root.png`; `devices/s21/logs/toolbox-back_at_root.txt`
- Status: open

## S21-028 - Back/nav switch from calculator root is stranded

- Severity: high
- Category: broken_back_flow
- Feature: calculator
- Device: s21
- Role: admin
- Route: `/calculator`
- Screen: `calculator_screen`
- Steps: navigate `/calculator`; switch tabs; press back; check bottom nav.
- Expected: calculator root returns to toolbox/dashboard or has bottom nav available.
- Actual: back returns `navigatedBack: false`; route remains `/calculator`; `hasBottomNav` is false.
- Evidence: `devices/s21/screenshots/calculator-root.png`; `devices/s21/logs/calculator-back_at_root.txt`
- Status: open

## S21-029 - New To-Do dialog is clipped on S21

- Severity: high
- Category: layout_clipping
- Feature: todos
- Device: s21
- Role: admin
- Route: `/todos`
- Screen: New To-Do dialog
- Steps: navigate `/todos`; tap `todos_add_button`.
- Expected: create/edit dialog fits the S21 viewport with priority controls and actions visible or scrollable.
- Actual: dialog bottom is clipped; the priority row/action area is cut off in the viewport.
- Evidence: `devices/s21/screenshots/todos-add-after-tap.png`; `devices/s21/logs/todos-forward_happy.txt`
- Status: open

## S21-030 - Back/nav switch from todos root is stranded

- Severity: high
- Category: broken_back_flow
- Feature: todos
- Device: s21
- Role: admin
- Route: `/todos`
- Screen: `todos_screen`
- Steps: dismiss add dialog; press back at todos root; check bottom nav.
- Expected: back returns to toolbox/dashboard or bottom nav is available.
- Actual: back returns `navigatedBack: false`; `/todos` has no bottom nav and `settings_nav_button` is absent.
- Evidence: `devices/s21/logs/todos-back_at_root.txt`; `devices/s21/screenshots/todos-root.png`
- Status: open

## S21-031 - Edit Profile opens without `edit_profile_screen` sentinel

- Severity: high
- Category: test_harness_gap
- Feature: settings
- Device: s21
- Role: admin
- Route: `/settings`
- Screen: visible Edit Profile
- Steps: navigate `/settings`; tap `settings_edit_profile_tile`; wait `edit_profile_screen`.
- Expected: edit profile screen exposes `edit_profile_screen` for driver verification.
- Actual: visible Edit Profile form opens, but `edit_profile_screen` is absent and `settings_screen` still reports true.
- Evidence: `devices/s21/screenshots/settings-edit-profile-missing.png`; `devices/s21/logs/settings-forward_happy.txt`
- Status: open

## S21-032 - Admin Dashboard opens without `admin_dashboard_screen` sentinel

- Severity: high
- Category: test_harness_gap
- Feature: settings
- Device: s21
- Role: admin
- Route: `/settings`
- Screen: visible Admin Dashboard
- Steps: tap `settings_admin_dashboard_tile`; wait `admin_dashboard_screen`.
- Expected: Admin Dashboard exposes `admin_dashboard_screen` for driver verification.
- Actual: visible Admin Dashboard opens, but `admin_dashboard_screen` is absent and route still reports `/settings`.
- Evidence: `devices/s21/screenshots/settings-admin-dashboard.png`
- Status: open

## S21-033 - Saved Exports settings tile does not open saved exports screen

- Severity: high
- Category: route_mismatch
- Feature: settings
- Device: s21
- Role: admin
- Route: expected `/settings/saved-exports`, actual `/projects`
- Screen: project list after tap
- Steps: tap `settings_saved_exports_tile`; wait `settings_saved_exports_screen`.
- Expected: saved exports route opens and exposes `settings_saved_exports_screen`.
- Actual: sentinel is absent and current route becomes `/projects`.
- Evidence: `devices/s21/screenshots/settings-saved-exports-route-fail.png`
- Status: open

## S21-034 - Trash settings tile does not open trash screen

- Severity: high
- Category: broken_forward_flow
- Feature: settings
- Device: s21
- Role: admin
- Route: `/settings`
- Screen: `settings_screen`
- Steps: scroll to/tap visible `settings_trash_tile`; wait `trash_screen`.
- Expected: Trash opens and exposes `trash_screen`.
- Actual: `trash_screen` remains absent and route stays `/settings`.
- Evidence: `devices/s21/screenshots/settings-trash.png`
- Status: open

## S21-035 - Sync Dashboard UI disagrees with debug sync status

- Severity: high
- Category: sync_error
- Feature: sync_ui
- Device: s21
- Role: admin
- Route: `/sync/dashboard`
- Screen: `sync_dashboard_screen`
- Steps: navigate `/sync/dashboard`; compare visible sync UI with debug `/sync/status`.
- Expected: UI status and debug sync status agree on blocked/error/conflict state.
- Actual: UI says `9 items need repair` and `9 blocked`; debug `/sync/status` reports completed quick sync with `errors: 0` and `conflicts: 0`.
- Evidence: `devices/s21/screenshots/sync-dashboard.png`; `devices/s21/sync/sync-dashboard-status.json`
- Status: open

## S21-036 - Conflict viewer route has no working back path

- Severity: high
- Category: broken_back_flow
- Feature: sync_ui
- Device: s21
- Role: admin
- Route: `/sync/conflicts`
- Screen: `conflict_viewer_screen`
- Steps: navigate `/sync/conflicts`; wait for `conflict_viewer_screen`; press driver back.
- Expected: back returns to Sync Dashboard or a stable previous screen.
- Actual: `/driver/back` returns `navigatedBack: false`; route remains `/sync/conflicts`; bottom nav is absent.
- Evidence: `devices/s21/logs/sync-ui-conflicts-deeplink-wait.json`; `devices/s21/logs/sync-ui-conflicts-deeplink-back.json`; `devices/s21/logs/sync-ui-conflicts-deeplink-after-back-route.json`
- Status: open

## S21-037 - Project contractor setup route is stranded

- Severity: high
- Category: broken_back_flow
- Feature: contractors
- Device: s21
- Role: admin
- Route: `/project/75ae3283-d4b2-4035-ba2f-7b4adb018199/edit`
- Screen: `project_setup_screen`
- Steps: open project edit; switch to Contractors; open/cancel contractor dialogs; press back; attempt bottom-nav switch.
- Expected: back or shell navigation returns to Projects/Settings/Dashboard.
- Actual: back returns `navigatedBack: false`; route remains project edit; `hasBottomNav` is false and `settings_nav_button` is absent.
- Evidence: `devices/s21/logs/contractors-back-from-setup-route.json`; `devices/s21/logs/contractors-nav-switch-settings-route.json`; `devices/s21/screenshots/contractors-after-tab.png`
- Status: open

## S21-038 - Inspector can see project create/delete/archive controls

- Severity: critical
- Category: permission_boundary
- Feature: role_boundaries
- Device: s21
- Role: inspector
- Route: `/projects`
- Screen: `project_list_screen`
- Steps: sign in as inspector; navigate `/projects`; scan project create/remove/archive controls.
- Expected: inspector can view and edit assigned projects, but cannot create, delete, or archive projects.
- Actual: `project_create_button`, `project_remove_75ae3283-d4b2-4035-ba2f-7b4adb018199`, and `project_archive_toggle_75ae3283-d4b2-4035-ba2f-7b4adb018199` are all visible.
- Evidence: `devices/s21/logs/rls-inspector-corrected-projects-keyscan.json`; `devices/s21/logs/rls-inspector-create-delete-keyscan-final.json`
- Status: open

## S21-039 - Inspector can see PDF import control

- Severity: high
- Category: permission_boundary
- Feature: role_boundaries
- Device: s21
- Role: inspector
- Route: `/quantities`
- Screen: `quantities_screen`
- Steps: sign in as inspector; navigate `/quantities`; scan PDF import controls.
- Expected: inspector should not be able to access PDF import management.
- Actual: `quantities_import_button` is visible to inspector.
- Evidence: `devices/s21/logs/rls-inspector-corrected-quantities-keyscan.json`
- Status: open

## S10-001 - Tablet sync starts unhealthy with circuit breaker and FCM errors

- Severity: high
- Category: sync_error
- Feature: sync_ui
- Device: s10
- Role: admin
- Route: startup and sync dashboard related flows
- Screen: `/projects`
- Steps: start S10 driver; observe debug server logs and sync status during admin role baseline.
- Expected: tablet sync starts cleanly or reports actionable UI state without background sync failures.
- Actual: logs show `CIRCUIT BREAKER: change_log exceeds 1000`, sync-lock contention, quick/full sync `errors=1`, and FCM `FIS_AUTH_ERROR`.
- Evidence: `devices/shared-latest-logs-after-s10-start.txt`; `devices/s10/logs/admin-role-logs.txt`; `devices/s10/sync/admin-role-sync-status.json`
- Status: open

## S10-002 - Inspector can see project create/delete/archive controls on tablet

- Severity: critical
- Category: permission_boundary
- Feature: role_boundaries
- Device: s10
- Role: inspector
- Route: `/projects`
- Screen: `project_list_screen`
- Steps: sign in as inspector on S10; navigate `/projects`; scan project create/remove/archive controls.
- Expected: inspector can view and edit assigned projects, but cannot create, delete, or archive projects.
- Actual: `project_create_button`, `project_remove_75ae3283-d4b2-4035-ba2f-7b4adb018199`, and `project_archive_toggle_75ae3283-d4b2-4035-ba2f-7b4adb018199` are all visible.
- Evidence: `devices/s10/logs/inspector-projects-create-delete-keyscan-retry.json`
- Status: open

## S10-003 - Inspector can access pay application management on tablet

- Severity: high
- Category: permission_boundary
- Feature: role_boundaries
- Device: s10
- Role: inspector
- Route: `/pay-app/harness-pay-app-001`
- Screen: `pay_app_detail_screen`
- Steps: sign in as inspector on S10; navigate pay-app detail; scan pay-app management controls.
- Expected: inspector should be denied pay application management.
- Actual: `pay_app_detail_screen`, `pay_app_compare_button`, and `pay_app_delete_button` are visible.
- Evidence: `devices/s10/logs/inspector-pay-app-keyscan-retry.json`
- Status: open

## S10-004 - Inspector can see PDF import control on tablet

- Severity: high
- Category: permission_boundary
- Feature: role_boundaries
- Device: s10
- Role: inspector
- Route: `/quantities`
- Screen: `quantities_screen`
- Steps: sign in as inspector on S10; navigate `/quantities`; scan PDF import controls.
- Expected: inspector should not be able to access PDF import management.
- Actual: `quantities_import_button` is visible to inspector.
- Evidence: `devices/s10/logs/inspector-quantities-keyscan-retry.json`
- Status: open
