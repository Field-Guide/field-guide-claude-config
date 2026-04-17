# Role Boundary Matrix - S21 And S10

Run: `2026-04-16_2058-manual-ui-rls-sweep-s21`

Policy corrections applied during run:

- Inspectors can view analytics.
- Inspectors can edit assigned projects.
- Inspectors cannot create, delete, or archive projects.
- Inspectors should not see other roles' trash records.

Available real app login credentials:

- `admin`: tested on S21 and S10.
- `inspector`: tested on S21 and S10.
- `engineer`: BLOCKED, no real login credentials found.
- `officeTechnician`: BLOCKED, no real login credentials found.

## S21

| Role | Area | Result | Evidence | Notes |
| --- | --- | --- | --- | --- |
| admin | Sync dashboard | FAIL | `devices/s21/sync/sync-dashboard-status.json` | UI showed blocked repair items while debug status reported clean. |
| admin | Sync conflict viewer | FAIL | `devices/s21/logs/sync-ui-conflicts-deeplink-back.json` | Conflict route opens, but back is stranded. |
| admin | Contractors | FAIL | `devices/s21/logs/contractors-back-from-setup-route.json` | Contractor edit/dialogs work; route has broken back/nav flow. |
| inspector | Assigned project visible | PASS | `devices/s21/logs/rls-inspector-corrected-projects-keyscan.json` | Springfield project visible. |
| inspector | Project edit allowed | PASS | `devices/s21/logs/rls-inspector-corrected-project-edit-keyscan.json` | Project setup and Contractors tab visible. |
| inspector | Project create/delete/archive denied | FAIL | `devices/s21/logs/rls-inspector-corrected-projects-keyscan.json` | Create, remove, and archive controls are visible. |
| inspector | Analytics allowed | PASS | `devices/s21/logs/rls-inspector-corrected-analytics-keyscan.json` | Analytics screen opens. |
| inspector | PDF import denied | FAIL | `devices/s21/logs/rls-inspector-corrected-quantities-keyscan.json` | Import button is visible. |
| inspector | Pay apps denied | PASS | `devices/s21/logs/rls-inspector-corrected-pay-app-keyscan.json` | Pay app detail/compare/delete absent on tested route. |
| inspector | Admin settings denied | PASS | `devices/s21/logs/role-probe-after-s21-restart-settings.json` | Admin dashboard and personnel settings hidden. |
| inspector | Trash cross-role isolation | BLOCKED | `devices/s21/logs/role-probe-after-s21-restart-settings.json` | Trash tile visibility alone is not enough to prove cross-role record isolation. |

## S10 Tablet

| Role | Area | Result | Evidence | Notes |
| --- | --- | --- | --- | --- |
| admin | Sync baseline | FAIL | `devices/s10/logs/admin-role-logs.txt` | Circuit breaker, sync-lock contention, full sync errors, and FCM FIS_AUTH_ERROR. |
| admin | Project controls | PASS | `devices/s10/logs/admin-projects-keyscan.json` | Create/remove/archive controls visible as expected. |
| admin | Project edit | PASS | `devices/s10/logs/admin-project-edit-keyscan.json` | Project setup opens. |
| admin | Analytics | PASS | `devices/s10/logs/admin-analytics-keyscan.json` | Analytics screen opens. |
| admin | PDF import | PASS | `devices/s10/logs/admin-quantities-keyscan.json` | Import button visible as expected. |
| inspector | Assigned project visible | PASS | `devices/s10/logs/inspector-projects-create-delete-keyscan-retry.json` | Springfield project visible. |
| inspector | Project edit allowed | PASS | `devices/s10/screenshots/inspector-project-edit-missing-tabs.png` | Tablet uses a left rail; edit route opens. |
| inspector | Project create/delete/archive denied | FAIL | `devices/s10/logs/inspector-projects-create-delete-keyscan-retry.json` | Create, remove, and archive controls are visible. |
| inspector | Analytics allowed | PASS | `devices/s10/logs/inspector-analytics-keyscan-retry.json` | Analytics screen opens. |
| inspector | PDF import denied | FAIL | `devices/s10/logs/inspector-quantities-keyscan-retry.json` | Import button is visible. |
| inspector | Pay apps denied | FAIL | `devices/s10/logs/inspector-pay-app-keyscan-retry.json` | Detail, compare, and delete controls are visible. |
| inspector | Admin settings denied | PASS | `devices/s10/logs/inspector-settings-keyscan-retry.json` | Admin dashboard and personnel settings hidden. |
| inspector | Trash cross-role isolation | BLOCKED | `devices/s10/logs/inspector-settings-keyscan-retry.json` | Trash tile visibility alone is not enough to prove cross-role record isolation. |

## Blocked Role Coverage

| Role | Device | Result | Reason |
| --- | --- | --- | --- |
| engineer | S21 | BLOCKED | No real engineer credential in `.claude/test-credentials.secret`. |
| engineer | S10 | BLOCKED | No real engineer credential in `.claude/test-credentials.secret`. |
| officeTechnician | S21 | BLOCKED | No real officeTechnician credential in `.claude/test-credentials.secret`. |
| officeTechnician | S10 | BLOCKED | No real officeTechnician credential in `.claude/test-credentials.secret`. |
