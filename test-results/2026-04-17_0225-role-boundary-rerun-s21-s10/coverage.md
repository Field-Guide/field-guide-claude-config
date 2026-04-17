# Coverage

Trusted source: `coverage-clean.csv`. Invalid and noisy raw attempts were removed from the trusted artifact set; see `_raw/README.md`.

## Summary

| Device | Role | Result | Count |
|---|---|---:|---:|
| s10 | admin | PASS | 1 |
| s10 | engineer | FAIL | 1 |
| s10 | engineer | PASS | 1 |
| s10 | inspector | FAIL | 1 |
| s10 | inspector | PASS | 1 |
| s10 | office_technician | FAIL | 1 |
| s10 | office_technician | PASS | 1 |
| s21 | current | PASS | 1 |
| s21 | engineer | FAIL | 1 |
| s21 | inspector | FAIL | 1 |
| s21 | office_technician | FAIL | 1 |

## Rows

| Device | Role | Feature | Flow | Route | Screen | Result | Evidence |
|---|---|---|---|---|---|---:|---|
| s10 | admin | toolbox | gallery_calculator_retest_after_fix | /calculator | calculator_screen | PASS | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/toolbox-gallery-calculator-retest-after-fix.json` |
| s10 | inspector | role_boundaries | role_matrix | /settings/trash | multiple | FAIL | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/rls/by-role/inspector.md` |
| s10 | engineer | role_boundaries | role_matrix | /settings/trash | multiple | FAIL | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/rls/by-role/engineer.md` |
| s10 | office_technician | role_boundaries | role_matrix | /settings/trash | multiple | FAIL | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/rls/by-role/office_technician.md` |
| s10 | inspector | projects | targeted_project_edit_recheck | /projects | project_list_screen | PASS | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/inspector-project-tree-targeted-recheck.txt` |
| s10 | engineer | pay_applications | targeted_pay_app_recheck | /pay-app/harness-pay-app-001 | pay_app_detail_screen | PASS | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/engineer-pay-app-targeted-recheck.txt` |
| s10 | office_technician | pay_applications | targeted_pay_app_recheck | /pay-app/harness-pay-app-001 | pay_app_detail_screen | PASS | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s10/logs/office_technician-pay-app-targeted-recheck.txt` |
| s21 | current | toolbox | gallery_calculator_retest_after_fix | /calculator | calculator_screen | PASS | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/devices/s21/logs/toolbox-gallery-calculator-retest-after-fix.json` |
| s21 | inspector | role_boundaries | role_matrix | /settings/trash | multiple | FAIL | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/rls/by-role/inspector-s21.md` |
| s21 | engineer | role_boundaries | role_matrix | /settings/trash | multiple | FAIL | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/rls/by-role/engineer-s21.md` |
| s21 | office_technician | role_boundaries | role_matrix | /settings/trash | multiple | FAIL | `.claude/test-results/2026-04-17_0225-role-boundary-rerun-s21-s10/rls/by-role/office_technician-s21.md` |
