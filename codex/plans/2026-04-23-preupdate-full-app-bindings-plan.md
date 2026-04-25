# Pre-Update Verification Completion To-Do Spec

## Summary

The prerelease suite must become a full app verification gate, not a route-smoke suite. Existing flows passed on S21 and tablet emulator, but the suite is still blocked by missing top-level feature bindings. Two proof gaps must be fixed before this can be trusted: pay-app export proof cannot use `$0 earned` applications, and forms proof must fully fill every supported form and verify every mapped row/cell in saved state, PDF preview, and exported PDFs.

## Phase 0: Save And Commit Current Work

- [ ] Save this plan as `.codex/plans/2026-04-23-preupdate-full-app-bindings-plan.md`.
- [ ] Update `.codex/PLAN.md` to reference the saved plan.
- [ ] Refresh CodeMunch index after saving.
- [ ] Review the dirty working tree before new implementation.
- [ ] Split existing completed work into logical commits:
  - [ ] Prerelease suite runner and manifest.
  - [ ] Pay-app UI flow catalog and lifecycle runner.
  - [ ] Router/auth/test-harness fixes.
  - [ ] Docs/tests for prerelease contracts.
- [ ] Each commit body must include problem, decision, tradeoff, evidence, and `Reason:` trailer.

## Phase 1: Fix Forms Proof Fidelity

- [ ] Treat partial form completion as invalid prerelease proof.
- [ ] For every supported form type, define a complete canonical fixture that fills every required field, every optional field that maps to the PDF, every repeatable row, every signature/name/date field, every checkbox/radio/select, and every table cell that should render.
- [ ] Replace marker-only validation with full field-map validation.
- [ ] For each supported form, maintain an expected mapping contract:
  - [ ] Form type.
  - [ ] App field key/path.
  - [ ] Expected stored value.
  - [ ] Expected PDF AcroForm field name or rendered text location.
  - [ ] Expected preview value.
  - [ ] Expected export value.
  - [ ] Required/optional status.
  - [ ] Row/cell identity for table fields.
- [ ] During form lifecycle creation, fill the complete fixture, not a small marker subset.
- [ ] During save/reload validation, verify every expected stored field in local and remote `form_responses`.
- [ ] During gallery reopen, verify the correct saved tile and correct form screen open.
- [ ] During PDF preview validation:
  - [ ] Prove preview opens on `form_pdf_preview_screen`.
  - [ ] Prove the preview is generated from the current fully-filled state.
  - [ ] Probe every expected field/cell value, not just a few marker strings.
  - [ ] Fail if any field is blank, stale, shifted, duplicated, or in the wrong mapped field.
- [ ] During PDF export validation:
  - [ ] Verify file exists and is fresh for the run.
  - [ ] Require editable AcroForm where the contract expects editable fields.
  - [ ] Verify every expected AcroForm field value.
  - [ ] Verify every expected rendered text value.
  - [ ] Verify every expected row/cell position for table data.
  - [ ] Fail if any mapping is missing, stale, in the wrong place, or exported from an older saved state.
- [ ] Extend `pdf_contract_probe.dart` so it can assert named field values and structured row/cell expectations, not only `contains(text)`.
- [ ] Add failure classifications:
  - [ ] `form_incomplete_fixture`
  - [ ] `form_saved_data_incorrect`
  - [ ] `form_preview_mapping_incorrect`
  - [ ] `form_export_mapping_incorrect`
  - [ ] `form_pdf_field_missing`
  - [ ] `form_pdf_cell_shifted`
- [ ] Add tests with intentionally broken PDFs/fixtures:
  - [ ] Missing required field fails.
  - [ ] Blank optional mapped field fails.
  - [ ] Wrong AcroForm field value fails.
  - [ ] Wrong table row/cell fails.
  - [ ] Preview stale value fails.
  - [ ] Export stale value fails.
  - [ ] Missing editable AcroForm fails when required.

## Phase 2: Fix Pay-App Export Proof Honesty

- [ ] Treat `$0 earned` pay-app exports as invalid prerelease proof.
- [ ] Select or seed pay-app data with real positive earned values.
- [ ] Require at least two representative pay item rows.
- [ ] Require positive current-period earned amount.
- [ ] Require positive earned-to-date total.
- [ ] Require non-zero scheduled/contract value.
- [ ] Require period start/end dates, project name/number, contract identifiers, application number, item rows, and summary totals.
- [ ] Fail with `pay_app_zero_earned_invalid_proof` when all earned values are zero.
- [ ] Update XLSX validation to inspect numeric values, formulas/results, row content, and totals, not only text markers.
- [ ] Verify saved export artifact linkage, dated folder path, filename, file existence, non-empty size/hash, and workbook freshness.
- [ ] Do not claim Excel preview proof unless a real in-app Excel preview/open path is exercised.
- [ ] If there is no in-app Excel preview surface, explicitly report workbook contract validation instead of preview validation.
- [ ] If contractor comparison PDF export is part of pay-app release confidence, add a separate PDF export/preview proof with positive totals and mapped contractor/pay-item markers.
- [ ] Add tests for `$0 earned`, missing file, wrong folder, unreadable workbook, missing sheet, missing positive earned value, stale workbook, and artifact/path mismatch.

## Phase 3: Implement Missing Top-Level Flow Bindings

- [ ] Add mandatory `auth` flows:
  - [ ] `auth-forward-happy-ui-flow`: `/login` -> `login_screen` -> `login_sign_up_button` -> `register_screen`.
  - [ ] `auth-backward-traversal-ui-flow`: `/login` -> `forgot_password_link` -> `forgot_password_screen` -> back/cancel to `login_screen`.
- [ ] Add mandatory `dashboard` flows:
  - [ ] Forward: `/` -> `project_dashboard_screen` -> `dashboard_toolbox_card` -> `toolbox_home_screen`.
  - [ ] Backward: `/toolbox` -> back to `project_dashboard_screen`.
- [ ] Add mandatory `projects` flows:
  - [ ] Forward: `/projects` -> `project_list_screen` -> `project_create_button` -> project setup sentinel.
  - [ ] Backward: `/project/harness-project-001/edit` -> back to `project_list_screen`.
- [ ] Add mandatory `entries` flows:
  - [ ] Forward: `/entries` -> `entries_list_screen` -> filter/open seeded entry editor.
  - [ ] Backward: seeded entry editor -> back to entries/calendar parent sentinel.
- [ ] Add mandatory `quantities` flows:
  - [ ] Forward: `/quantities` -> sort menu -> `quantities_sort_item_number`.
  - [ ] Backward: `/quantity-calculator/harness-entry-001` -> back to `quantities_screen`.
- [ ] Add mandatory `analytics`, `pdf`, `gallery`, `toolbox`, `calculator`, `todos`, `settings`, and `contractors` forward/backward flows.
- [ ] Use `screen_journey` where a route plus tap sequence is needed.
- [ ] Use a dedicated lifecycle runner instead of route probe when production route `extra` or seeded state is required.

## Phase 4: Add Deeper Feature Validators

- [ ] Add `entries-lifecycle-proof-ui-flow`.
- [ ] Add `quantities-lifecycle-proof-ui-flow`.
- [ ] Add `projects-lifecycle-proof-ui-flow`.
- [ ] Add `settings-lifecycle-proof-ui-flow`.
- [ ] Add `pdf-import-lifecycle-proof-ui-flow`.
- [ ] Keep forms proof as complete full-form mapping validation.
- [ ] Keep pay-app proof as positive-earned workbook/PDF artifact validation.
- [ ] Ensure every lifecycle proof cleans up or reopens cleanly so reruns do not rely on residue.

## Phase 5: Expand Action Probe Coverage

- [ ] Expand `PreUpdateVerification.ActionProbeManifest.ps1` to all critical screens.
- [ ] Use declared `TestingKeys` only.
- [ ] Do not blind-tap arbitrary widgets.
- [ ] For destructive actions, only prove dialog opens, cancel works, and confirm control exists.
- [ ] For navigation actions, require expected route and sentinel.
- [ ] For modal actions, require dialog/progress sentinel.
- [ ] For export actions, require real artifact proof with mapped current data.
- [ ] Cover auth, dashboard, projects, entries, forms, pay apps, quantities, PDF import, gallery, toolbox, calculator, todos, settings, contractors, saved exports, and sync dashboard.

## Phase 6: Update Suite Manifest And Reporting

- [ ] Add every new child flow to the prerelease manifest.
- [ ] Remove blocking reasons only after concrete flows resolve and pass.
- [ ] Keep `family = "ui-flow"`.
- [ ] Keep `flowId = "pre-update-verification"`.
- [ ] Keep fail-closed behavior.
- [ ] Report `coverageStatus = complete` only when every top-level feature has forward/backward bindings and required lifecycle/export validators pass.
- [ ] Update report wording so it never claims full app verification when any coverage is partial or blocked.
- [ ] Ensure `artifacts.json` links forms full-mapping artifacts, pay-app workbook/PDF artifacts, and all retained lifecycle ledgers.

## Phase 7: Tests

- [ ] Extend prerelease tests so every top-level feature has concrete forward/backward bindings.
- [ ] Extend UI flow catalog tests so every new flow resolves and uses an allowed mode.
- [ ] Add form fixture/mapping tests for complete field coverage.
- [ ] Add PDF contract probe tests for named field values and table cell mappings.
- [ ] Add pay-app export validator tests for positive earned values and non-zero totals.
- [ ] Keep existing catalog/runtime/output contract tests green.

## Phase 8: Live Verification Iterations

- [ ] Rebuild Android driver after implementation.
- [ ] Restart S21 driver.
- [ ] Restart tablet emulator driver.
- [ ] Run each new child flow independently on both actors.
- [ ] Run forms proof independently and confirm every supported form is fully filled and fully mapped in save/reload, preview, and export.
- [ ] Run pay-app export proof independently and confirm positive-earned workbook/PDF proof.
- [ ] Run full prerelease suite on both actors.
- [ ] Actively monitor child summaries and evidence timestamps.
- [ ] Final acceptance requires:
  - [ ] All child flows PASS.
  - [ ] `coverageStatus = complete`.
  - [ ] `missingCoverageFailures = []`.
  - [ ] No runtime errors.
  - [ ] No layout defects.
  - [ ] No sync/logging gaps.
  - [ ] Every supported form fully filled and fully mapped.
  - [ ] Forms PDF preview and export mappings correct.
  - [ ] Pay-app positive-earned export proof passes.
  - [ ] Canonical `report.md`, `summary.json`, and `artifacts.json` published.

## Assumptions And Defaults

- `$0 earned` pay applications are invalid as export proof.
- Forms marker sampling is insufficient; complete field and cell mapping is required.
- If no production Excel preview exists, the suite must not claim Excel preview coverage.
- Device acceptance remains S21 plus tablet emulator unless intentionally narrowed.
- Any route requiring production `extra` must use a real seeded runner, not a fake route probe.
