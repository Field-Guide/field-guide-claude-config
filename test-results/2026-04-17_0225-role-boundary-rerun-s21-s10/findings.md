# Findings

Trusted source: `findings-clean.jsonl`. Every open item below is a failed gate for this run.

## Summary

| Device | Category | Status | Count |
|---|---|---:|---:|
| s10 | permission_boundary | open | 7 |
| s10 | runtime_error | fixed | 1 |
| s10 | sync_stale_state | open | 4 |
| s21 | permission_boundary | open | 9 |
| s21 | sync_stale_state | open | 3 |
| s21 | ui_overflow | open | 3 |

## Open Findings

| ID | Severity | Device | Role | Feature | Category | Route | Actual | Evidence |
|---|---|---|---|---|---|---|---|---|
| RB-CLEAN-007 | high | s10 | engineer | settings | permission_boundary | /settings | {"exists":true,"key":"settings_trash_tile","widgetType":"ListTile","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/engineer-settings-role_trash_tile_denied-tree-settings_trash_tile.txt` |
| RB-CLEAN-008 | high | s10 | engineer | settings | permission_boundary | /settings/trash | {"exists":true,"key":"trash_screen","widgetType":"AppScaffold","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/engineer-settings-role_trash_route_denied-tree-trash_screen.txt` |
| RB-CLEAN-003 | high | s10 | inspector | pdf_imports | permission_boundary | /quantities | {"exists":true,"key":"quantities_import_button","widgetType":"_IconAppButton","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/inspector-pdf_imports-role_pdf_import_boundary-tree-quantities_import_button.txt` |
| RB-CLEAN-004 | high | s10 | inspector | settings | permission_boundary | /settings | {"exists":true,"key":"settings_trash_tile","widgetType":"ListTile","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/inspector-settings-role_trash_tile_denied-tree-settings_trash_tile.txt` |
| RB-CLEAN-005 | high | s10 | inspector | settings | permission_boundary | /settings/trash | {"exists":true,"key":"trash_screen","widgetType":"AppScaffold","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/inspector-settings-role_trash_route_denied-tree-trash_screen.txt` |
| RB-CLEAN-010 | high | s10 | office_technician | settings | permission_boundary | /settings | {"exists":true,"key":"settings_trash_tile","widgetType":"ListTile","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/office_technician-settings-role_trash_tile_denied-tree-settings_trash_tile.txt` |
| RB-CLEAN-011 | high | s10 | office_technician | settings | permission_boundary | /settings/trash | {"exists":true,"key":"trash_screen","widgetType":"AppScaffold","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/office_technician-settings-role_trash_route_denied-tree-trash_screen.txt` |
| RB-CLEAN-002 | high | s10 | admin | sync_ui | sync_stale_state | multiple | S10 reported pendingCount around 1680 and unprocessedCount around 1680; debug logs also recorded CIRCUIT BREAKER: change_log exceeds 1000 and quick sync completed with errors=1 | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/admin-sweep-log-summary.json` |
| RB-CLEAN-009 | high | s10 | engineer | sync_ui | sync_stale_state | /settings/trash | pendingCount=1684; unprocessedCount=1684; blockedCount=0 | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/sync/engineer-role-boundary-sync-status.json` |
| RB-CLEAN-006 | high | s10 | inspector | sync_ui | sync_stale_state | /settings/trash | pendingCount=1684; unprocessedCount=1684; blockedCount=0 | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/sync/inspector-role-boundary-sync-status.json` |
| RB-CLEAN-012 | high | s10 | office_technician | sync_ui | sync_stale_state | /settings/trash | pendingCount=1684; unprocessedCount=1684; blockedCount=0 | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/sync/office_technician-role-boundary-sync-status.json` |
| RB-CLEAN-020 | high | s21 | engineer | settings | permission_boundary | /settings | {"exists":true,"key":"settings_trash_tile","widgetType":"ListTile","visible":false} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/engineer-settings-settings_trash_tile.txt` |
| RB-CLEAN-021 | high | s21 | engineer | settings | permission_boundary | /settings/trash | {"exists":true,"key":"trash_screen","widgetType":"AppScaffold","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/engineer-settings-trash_screen.txt` |
| RB-CLEAN-014 | high | s21 | inspector | pay_applications | permission_boundary | /pay-app/harness-pay-app-001 | {"exists":true,"key":"pay_app_detail_screen","widgetType":"SingleChildScrollView","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/inspector-pay_applications-pay_app_detail_screen.txt` |
| RB-CLEAN-015 | high | s21 | inspector | pdf_imports | permission_boundary | /quantities | {"exists":true,"key":"quantities_import_button","widgetType":"_IconAppButton","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/inspector-pdf_imports-quantities_import_button.txt` |
| RB-CLEAN-013 | high | s21 | inspector | projects | permission_boundary | /projects | remove exists | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/inspector-project-tree-valid.txt` |
| RB-CLEAN-016 | high | s21 | inspector | settings | permission_boundary | /settings | {"exists":true,"key":"settings_trash_tile","widgetType":"ListTile","visible":false} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/inspector-settings-settings_trash_tile.txt` |
| RB-CLEAN-017 | high | s21 | inspector | settings | permission_boundary | /settings/trash | {"exists":true,"key":"trash_screen","widgetType":"AppScaffold","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/inspector-settings-trash_screen.txt` |
| RB-CLEAN-024 | high | s21 | office_technician | settings | permission_boundary | /settings | {"exists":true,"key":"settings_trash_tile","widgetType":"ListTile","visible":false} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/office_technician-settings-settings_trash_tile.txt` |
| RB-CLEAN-025 | high | s21 | office_technician | settings | permission_boundary | /settings/trash | {"exists":true,"key":"trash_screen","widgetType":"AppScaffold","visible":true} | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/office_technician-settings-trash_screen.txt` |
| RB-CLEAN-023 | high | s21 | engineer | sync_ui | sync_stale_state | /settings/trash | pendingCount=5; unprocessedCount=88; blockedCount=83 | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/sync/engineer-sync-valid.json` |
| RB-CLEAN-019 | high | s21 | inspector | sync_ui | sync_stale_state | /settings/trash | pendingCount=8; unprocessedCount=84; blockedCount=76 | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/sync/inspector-sync-valid.json` |
| RB-CLEAN-027 | high | s21 | office_technician | sync_ui | sync_stale_state | /settings/trash | pendingCount=9; unprocessedCount=92; blockedCount=83 | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/sync/office_technician-sync-valid.json` |
| RB-CLEAN-022 | high | s21 | engineer | role_boundaries | ui_overflow | /settings/trash | ERRORS: 1 unique (1 total)   03:18:35 [app   ] FlutterError: A RenderFlex overflowed by 139 pixels on the right.  | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/engineer-errors-valid.txt` |
| RB-CLEAN-018 | high | s21 | inspector | role_boundaries | ui_overflow | /settings/trash | ERRORS: 2 unique (4 total)   03:17:37 [app   ] FlutterError: A RenderFlex overflowed by 139 pixels on the right.   03:17:45 [app   ] RLS DENIED (42501): projects/harness-project... | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/inspector-errors-valid.txt` |
| RB-CLEAN-026 | high | s21 | office_technician | role_boundaries | ui_overflow | /settings/trash | ERRORS: 1 unique (1 total)   03:19:32 [app   ] FlutterError: A RenderFlex overflowed by 139 pixels on the right.  | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/office_technician-errors-valid.txt` |

## Fixed Findings

| ID | Severity | Device | Role | Feature | Category | Route | Actual | Evidence |
|---|---|---|---|---|---|---|---|---|
| RB-CLEAN-001 | blocker | s10 | admin | toolbox | runtime_error | /toolbox | At 02:54:18 debug logs recorded Stack Overflow, RenderBox was not laid out assertions, shifted_box child.hasSize assertion, object owner assertion, dirty-widget wrong build scope, duplicate GlobalKeys, and app fell into Flutter ErrorWidg... | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/admin-sweep-log-summary.json` |
