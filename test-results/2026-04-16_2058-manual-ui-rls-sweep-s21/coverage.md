# Coverage

Run started UTC: 2026-04-17T00:58:13.0220419Z
Scope: S21 only

| Feature | Flow | Role | Device | Result | Notes |
|---|---|---|---|---|---|
| dashboard | forward_happy | admin | s21 | FAIL | route: {"route":"/","hasBottomNav":true,"canPop":false}; log: devices/s21/logs/dashboard-forward_happy.txt |
| dashboard | backward_traversal | admin | s21 | PASS | log: devices/s21/logs/dashboard-backward_traversal.txt |
| dashboard | nav_bar_switch_mid_flow | admin | s21 | FAIL | log: devices/s21/logs/dashboard-nav_bar_switch_mid_flow.txt |
| dashboard | back_at_root | admin | s21 | PASS | log: devices/s21/logs/dashboard-back_at_root.txt |
| dashboard | deep_link_entry | admin | s21 | PASS | log: devices/s21/logs/dashboard-deep_link_entry.txt |
| dashboard | orientation_change | admin | s21 | PASS | log: devices/s21/logs/dashboard-orientation_change.txt; screenshot: devices/s21/screenshots/dashboard-orientation-landscape.png |
| projects | forward_happy | admin | s21 | PASS | log: devices/s21/logs/projects-forward_happy.txt |
| projects | backward_traversal_from_create | admin | s21 | PASS | log: devices/s21/logs/projects-backward_traversal_from_create.txt |
| projects | deep_link_entry | admin | s21 | PASS | log: devices/s21/logs/projects-deep_link_entry.txt |
| projects | setup_tabs | admin | s21 | PASS | log: devices/s21/logs/projects-setup_tabs.txt |
| projects | back_at_root | admin | s21 | PASS | log: devices/s21/logs/projects-back_at_root.txt |

| entries | forward_happy | admin | s21 | FAIL | ntry_editor_screen sentinel missing on visible editor; log: devices/s21/logs/entries-forward_happy.txt |
| entries | backward_traversal | admin | s21 | FAIL | /review-summary redirects/lands at dashboard; log: devices/s21/logs/entries-backward_traversal.txt |
| entries | nav_bar_switch_mid_flow | admin | s21 | FAIL | spec key ntry_wizard_save_draft absent; actual visible save key is ntry_wizard_save; log: devices/s21/logs/entries-nav_bar_switch_mid_flow.txt |
| forms | forward_happy | admin | s21 | FAIL | /form/harness-response-001 renders form_viewer_screen, not mdot_hub_screen; log: devices/s21/logs/forms-forward_happy.txt |
| entries | deep_link_entry | admin | s21 | FAIL | ntry_editor_screen sentinel missing; linked finding S21-005; log: devices/s21/logs/entries-deep_link_entry.txt |
| entries | back_at_root | admin | s21 | FAIL | back at /entries did nothing and bottom nav is absent; log: devices/s21/logs/entries-back_at_root.txt |
| entries | export_verification | admin | s21 | FAIL | export tap logs PDF generation failed; log: devices/s21/logs/entries-export_verification.txt |
| entries | orientation_change | admin | s21 | FAIL | ntry_editor_screen sentinel absent before/after orientation; linked finding S21-005 |
| entries | role_restriction | inspector | s21 | BLOCKED | deferred to role-boundary/RLS account switch section |
| forms | backward_traversal | admin | s21 | FAIL | /form response is stranded on form_viewer_screen; back does nothing; log: devices/s21/logs/forms-backward_traversal.txt |
| forms | back_at_root | admin | s21 | FAIL | back at /forms did nothing and bottom nav is absent; log: devices/s21/logs/forms-back_at_root.txt |
| forms | export_verification_preview | admin | s21 | FAIL | visible PDF Preview opens but orm_pdf_preview_screen sentinel is absent; log: devices/s21/logs/forms-preview_verification.txt |
| forms | export_verification | admin | s21 | FAIL | export dialog is visible but expected orm_export_* keys are absent; log: devices/s21/logs/forms-export_verification.txt |
| forms | deep_link_entry | admin | s21 | FAIL | /form/harness-response-001 renders orm_viewer_screen, not mdot_hub_screen; linked S21-009 |
| forms | nav_bar_switch_mid_flow | admin | s21 | FAIL | mdot_hub_save_button absent because route renders viewer, not hub; linked S21-009 |
| forms | tab_switch_mid_edit | admin | s21 | FAIL | mdot_hub_save_button absent because route renders viewer, not hub; linked S21-009 |
| forms | orientation_change | admin | s21 | FAIL | mdot_hub_screen absent before orientation; linked S21-009 |
| forms | form_completeness | admin | s21 | FAIL | target mdot_hub_screen absent; cannot credit MDOT hub completeness; linked S21-009 |
| pay_applications | forward_happy | admin | s21 | FAIL | comparison screen opens with visible PathNotFound export-file error and debug provider error; log: devices/s21/logs/pay-applications-forward_happy.txt |
| pay_applications | backward_traversal | admin | s21 | PASS | back from comparison returned to pay_app_detail_screen; log: devices/s21/logs/pay-applications-backward_traversal.txt |
| pay_applications | back_at_root | admin | s21 | FAIL | back at pay app detail did nothing and bottom nav is absent; log: devices/s21/logs/pay-applications-back_at_root.txt |
| pay_applications | deep_link_entry | admin | s21 | PASS | detail deep link exposes pay_app_detail_screen; log: devices/s21/logs/pay-applications-deep_link_entry.txt |
| pay_applications | nav_bar_switch_mid_flow | admin | s21 | FAIL | compare path opens with PathNotFound error before nav switch; linked S21-017 |
| pay_applications | orientation_change | admin | s21 | PASS | pay_app_detail_screen sentinel visible on S21 before orientation; no new errors in flow window |
| pay_applications | export_verification | admin | s21 | FAIL | comparison/export path has missing XLSX file; linked S21-017 |
| pay_applications | role_restriction | inspector | s21 | BLOCKED | deferred to role-boundary/RLS account switch section |
| quantities | forward_happy | admin | s21 | FAIL | screen/sort controls exist but visible state is No Project Selected after seeded data; log: devices/s21/logs/quantities-forward_happy.txt |
| quantities | deep_link_entry | admin | s21 | PASS | quantity_calculator_screen opens; log: devices/s21/logs/quantities-deep_link_entry.txt |
| quantities | backward_traversal | admin | s21 | FAIL | back from quantity calculator did nothing; log: devices/s21/logs/quantities-backward_traversal.txt |
| quantities | nav_bar_switch_mid_flow | admin | s21 | FAIL | /quantities has no bottom nav; projects_nav_button absent; log: devices/s21/logs/quantities-nav_bar_switch_mid_flow.txt |
| quantities | back_at_root | admin | s21 | FAIL | back/root issue already proven for calculator and /quantities outside bottom nav; linked S21-021 |
| quantities | tab_switch_mid_edit | admin | s21 | PASS | calculator screen and calculate button visible; no new debug errors before input; log: devices/s21/logs/quantities-deep_link_entry.txt |
| quantities | orientation_change | admin | s21 | PASS | quantity_calculator_screen rendered on S21 without overflow in checkpoint screenshot |
| quantities | export_verification | admin | s21 | FAIL | export tap from No Project Selected state does not open export hub; log: devices/s21/logs/quantities-export_verification.txt |
| analytics | forward_happy | admin | s21 | PASS | analytics screen and date filter opened without debug errors; screenshots saved |
| analytics | deep_link_entry | admin | s21 | PASS | /analytics/harness-project-001 exposes project_analytics_screen |
| analytics | export_verification | admin | s21 | PASS | date-filter/export-adjacent action opened visible date range UI without debug errors |
| analytics | back_at_root | admin | s21 | FAIL | back at analytics root did nothing and bottom nav is absent; log: devices/s21/logs/analytics-back_at_root.txt |
| analytics | backward_traversal | admin | s21 | FAIL | same root back behavior; linked S21-023 |
| analytics | nav_bar_switch_mid_flow | admin | s21 | BLOCKED | dashboard analytics card absent while dashboard has No Project Selected; linked S21-001 |
| analytics | orientation_change | admin | s21 | PASS | analytics screen rendered on S21 without overflow in screenshot |
| analytics | role_restriction | inspector | s21 | BLOCKED | deferred to role-boundary/RLS account switch section |
| dashboard | select_existing_project_recovery | admin | s21 | PASS | selecting real Springfield project restores dashboard cards; screenshot: devices/s21/screenshots/project-selected-dashboard.png |
| pdf | forward_happy | admin | s21 | FAIL | injected PDF extracted 131 items, but pdf_preview_screen never became driver-visible; screenshot shows Projects while route reports /quantities; log: devices/s21/logs/pdf-import-after-inject.txt |
| pdf | deep_link_entry | admin | s21 | BLOCKED | preview routes require state.extra; validated through injected import instead |
| pdf | backward_traversal | admin | s21 | FAIL | preview screen not reachable after injected import; cannot back from preview; linked S21-024 |
| pdf | back_at_root | admin | s21 | FAIL | preview screen not reachable after injected import; linked S21-024 |
| pdf | orientation_change | admin | s21 | FAIL | preview screen not reachable after injected import; linked S21-024 |
| pdf | export_verification | admin | s21 | FAIL | preview import button not reachable because preview sentinel absent; linked S21-024 |
| pdf | role_restriction | inspector | s21 | BLOCKED | deferred to role-boundary/RLS account switch section |
| gallery | forward_happy | admin | s21 | FAIL | gallery/filter opens, but photo thumbnails render as placeholders; screenshots saved |
| gallery | deep_link_entry | admin | s21 | PASS | /gallery exposes gallery_screen |
| gallery | backward_traversal | admin | s21 | FAIL | back at gallery root does nothing and bottom nav absent; log: devices/s21/logs/gallery-backward_traversal.txt |
| gallery | back_at_root | admin | s21 | FAIL | same root back failure; linked S21-026 |
| gallery | nav_bar_switch_mid_flow | admin | s21 | FAIL | settings_nav_button absent on /gallery; linked S21-026 |
| gallery | orientation_change | admin | s21 | FAIL | visual thumbnail placeholders present on S21; linked S21-025 |
| toolbox | forward_happy | admin | s21 | PASS | root cards visible and calculator/todos cards open target screens |
| toolbox | deep_link_entry | admin | s21 | PASS | /toolbox exposes 	oolbox_home_screen |
| toolbox | backward_traversal | admin | s21 | PASS | back from calculator/todos returns to toolbox root |
| toolbox | back_at_root | admin | s21 | FAIL | back at toolbox root does nothing and bottom nav absent; log: devices/s21/logs/toolbox-back_at_root.txt |
| toolbox | nav_bar_switch_mid_flow | admin | s21 | FAIL | settings_nav_button absent on toolbox root; linked S21-027 |
| toolbox | orientation_change | admin | s21 | PASS | toolbox cards fit S21 screenshot without overflow |
| calculator | forward_happy | admin | s21 | PASS | calculator root renders HMA fields and calculate button without overflow |
| calculator | deep_link_entry | admin | s21 | PASS | /calculator exposes calculator_screen |
| calculator | tab_switch_mid_edit | admin | s21 | PASS | HMA/concrete tab taps succeed without debug errors |
| calculator | orientation_change | admin | s21 | PASS | S21 calculator screenshot fits controls without overflow |
| calculator | back_at_root | admin | s21 | FAIL | back at calculator root does nothing and bottom nav absent; log: devices/s21/logs/calculator-back_at_root.txt |
| calculator | backward_traversal | admin | s21 | FAIL | direct calculator route cannot back to toolbox; linked S21-028 |
| calculator | nav_bar_switch_mid_flow | admin | s21 | FAIL | settings_nav_button absent on calculator root; linked S21-028 |
| todos | forward_happy | admin | s21 | FAIL | add dialog opens but bottom of dialog/action area is clipped; log: devices/s21/logs/todos-forward_happy.txt |
| todos | deep_link_entry | admin | s21 | PASS | /todos exposes 	odos_screen |
| todos | tab_switch_mid_edit | admin | s21 | FAIL | add dialog layout clipped; linked S21-029 |
| todos | back_at_root | admin | s21 | FAIL | back at todos root does nothing and bottom nav absent; log: devices/s21/logs/todos-back_at_root.txt |
| todos | backward_traversal | admin | s21 | FAIL | direct /todos route cannot back to toolbox; linked S21-030 |
| todos | nav_bar_switch_mid_flow | admin | s21 | FAIL | settings_nav_button absent on /todos; linked S21-030 |
| todos | orientation_change | admin | s21 | FAIL | add dialog clipped on S21; linked S21-029 |
| settings | forward_happy | admin | s21 | FAIL | Edit Profile opens visibly but dit_profile_screen sentinel is absent; log: devices/s21/logs/settings-forward_happy.txt |
| settings | admin_dashboard | admin | s21 | FAIL | visible Admin Dashboard opens but dmin_dashboard_screen sentinel is absent |
| settings | app_lock | admin | s21 | PASS | settings_app_lock_tile opens pp_lock_settings_screen |
| settings | sync_dashboard | admin | s21 | PASS | settings_sync_dashboard_tile opens sync_dashboard_screen |
| settings | saved_exports | admin | s21 | FAIL | tile did not expose settings_saved_exports_screen and route landed /projects; screenshot saved |
| settings | trash | admin | s21 | FAIL | tapping visible trash tile does not open 	rash_screen; route stays /settings; screenshot saved |
| settings | backward_traversal | admin | s21 | PASS | back from App Lock/Admin/Sync subroutes returned to Settings |
| settings | back_at_root | admin | s21 | PASS | settings root has bottom nav and route remains in shell |
| settings | deep_link_entry | admin | s21 | FAIL | saved exports deep-link/tile path failed; linked S21-033 |
| settings | role_restriction | inspector | s21 | BLOCKED | deferred to role-boundary/RLS account switch section |
| sync_ui | forward_happy | admin | s21 | FAIL | UI shows 9 blocked repair items while debug sync status reports 0 errors/conflicts; log: devices/s21/sync/sync-dashboard-status.json |
| sync_ui | view_projects_tile | admin | s21 | PASS | sync dashboard View Synced Projects reached project_list_screen during manual tile check; log: devices/s21/logs/sync-ui-view-projects-wait.json |
| sync_ui | conflicts_deep_link | admin | s21 | PASS | /sync/conflicts exposes conflict_viewer_screen; log: devices/s21/logs/sync-ui-conflicts-deeplink-wait.json |
| sync_ui | conflict_back_flow | admin | s21 | FAIL | back from /sync/conflicts returned navigatedBack=false and stayed on /sync/conflicts; linked S21-036 |
| sync_ui | full_sync_button | admin | s21 | PASS | Full Sync Now completed with errors=0/conflicts=0 after 11116ms; log: devices/s21/sync/sync-after-full-sync-button-12s.json |
| sync_ui | repair_blocked_queue | admin | s21 | PASS | repair action ran known repair jobs and cleared sync_repair_banner; log: devices/s21/logs/sync-ui-repair-blocked-logs.txt |
| contractors | forward_happy | admin | s21 | PASS | project contractors tab rendered real contractor cards; edit, personnel dialog, and equipment dialog opened; logs: devices/s21/logs/contractors-after-tab-tree.json |
| contractors | edit_contractor | admin | s21 | PASS | contractor_editor_edit_mode and contractor_name_field visible after tapping contractor edit; log: devices/s21/logs/contractors-edit-first-keyscan.json |
| contractors | personnel_dialog | admin | s21 | PASS | personnel type dialog opened with name/cancel/add controls; log: devices/s21/logs/contractors-personnel-dialog-keyscan.json |
| contractors | equipment_dialog | admin | s21 | PASS | equipment dialog opened with equipment_name_field/equipment_dialog_add/equipment_dialog_cancel; log: devices/s21/logs/contractors-equipment-dialog-tree.json |
| contractors | back_at_root | admin | s21 | FAIL | project setup contractors route has no bottom nav and back returns navigatedBack=false; linked S21-037 |
| contractors | nav_bar_switch_mid_flow | admin | s21 | FAIL | settings_nav_button absent on project setup route; linked S21-037 |
| role_boundaries | inspector_projects_visibility | inspector | s21 | PASS | assigned Springfield project is visible to inspector; log: devices/s21/logs/rls-inspector-corrected-projects-keyscan.json |
| role_boundaries | inspector_project_edit | inspector | s21 | PASS | inspector can open project edit screen and contractor tab per clarified policy; log: devices/s21/logs/rls-inspector-corrected-project-edit-keyscan.json |
| role_boundaries | inspector_project_create_delete | inspector | s21 | FAIL | project_create_button, project_remove, and archive toggle are visible to inspector; linked S21-038 |
| role_boundaries | inspector_analytics | inspector | s21 | PASS | analytics opens for inspector per clarified policy; log: devices/s21/logs/rls-inspector-corrected-analytics-keyscan.json |
| role_boundaries | inspector_pdf_import | inspector | s21 | FAIL | quantities_import_button is visible to inspector; linked S21-039 |
| role_boundaries | inspector_pay_applications | inspector | s21 | PASS | pay app detail/compare/delete controls are not exposed on S21 inspector route; log: devices/s21/logs/rls-inspector-corrected-pay-app-keyscan.json |
| role_boundaries | inspector_admin_settings | inspector | s21 | PASS | admin dashboard and personnel type settings are hidden for inspector; log: devices/s21/logs/role-probe-after-s21-restart-settings.json |
| role_boundaries | engineer_role | engineer | s21 | BLOCKED | no real engineer login credentials found in .claude/test-credentials.secret |
| role_boundaries | office_technician_role | officeTechnician | s21 | BLOCKED | no real officeTechnician login credentials found in .claude/test-credentials.secret |
| role_boundaries | admin_projects | admin | s10 | PASS | admin project create/remove/archive controls visible on tablet; log: devices/s10/logs/admin-projects-keyscan.json |
| role_boundaries | admin_project_edit | admin | s10 | PASS | admin project edit screen opens on tablet; log: devices/s10/logs/admin-project-edit-keyscan.json |
| role_boundaries | admin_analytics | admin | s10 | PASS | admin analytics opens on tablet; log: devices/s10/logs/admin-analytics-keyscan.json |
| role_boundaries | admin_pdf_import | admin | s10 | PASS | admin quantities import button visible on tablet; log: devices/s10/logs/admin-quantities-keyscan.json |
| sync_ui | baseline | admin | s10 | FAIL | tablet logs show circuit breaker/full sync errors, sync-lock contention, and FCM FIS_AUTH_ERROR; linked S10-001 |
| role_boundaries | inspector_projects_visibility | inspector | s10 | PASS | assigned Springfield project visible to inspector on tablet; log: devices/s10/logs/inspector-projects-create-delete-keyscan-retry.json |
| role_boundaries | inspector_project_edit | inspector | s10 | PASS | inspector can open project edit on tablet per clarified policy; screenshot: devices/s10/screenshots/inspector-project-edit-missing-tabs.png |
| role_boundaries | inspector_project_create_delete | inspector | s10 | FAIL | project_create_button, project_remove, and archive toggle are visible to inspector on tablet; linked S10-002 |
| role_boundaries | inspector_analytics | inspector | s10 | PASS | analytics opens for inspector on tablet per clarified policy; log: devices/s10/logs/inspector-analytics-keyscan-retry.json |
| role_boundaries | inspector_pdf_import | inspector | s10 | FAIL | quantities_import_button is visible to inspector on tablet; linked S10-004 |
| role_boundaries | inspector_pay_applications | inspector | s10 | FAIL | pay_app_detail_screen, compare, and delete controls are visible to inspector on tablet; linked S10-003 |
| role_boundaries | inspector_admin_settings | inspector | s10 | PASS | admin dashboard and personnel type settings are hidden for inspector on tablet; log: devices/s10/logs/inspector-settings-keyscan-retry.json |
| role_boundaries | engineer_role | engineer | s10 | BLOCKED | no real engineer login credentials found in .claude/test-credentials.secret |
| role_boundaries | office_technician_role | officeTechnician | s10 | BLOCKED | no real officeTechnician login credentials found in .claude/test-credentials.secret |
