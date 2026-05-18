# Form Entry Flow Redesign Todo

## Summary

Build the planning/design package for the MDOT 1174R and MDOT 1126 entry
redesign, and add the Water Main Pressure Test Report to the same standardized
built-in form workflow. Use MDOT 0582B as the compact flow benchmark. The
redesign intent is to reduce long scrolling, standardize form flow, keep all
entered data editable inside the app, and make future built-in form creation
follow the same compact workflow pattern.

Wireframes are required before implementation. The wireframe artifact is
`.codex/plans/2026-05-11-form-entry-flow-wireframes.md` and must be reviewed
before implementation begins.

## Artifacts

- [x] Save redesign todo plan:
  `.codex/plans/2026-05-11-form-entry-flow-redesign-todo.md`
- [x] Create static wireframe layout reference:
  `.codex/plans/2026-05-11-form-entry-flow-wireframes.md`
- [ ] Do not begin implementation until the wireframe reference is reviewed.
- [x] Copy the supplied Pressure Testing Sheet PDF into the repo as a source
  reference:
  `assets/templates/forms/water_main_pressure_test_report_source.pdf`.
- [ ] Create the final fillable Pressure Test Report template:
  `assets/templates/forms/water_main_pressure_test_report_form.pdf`.
- [ ] Treat the copied source PDF as a visual/source reference only; it is not
  implementation-ready because it has zero AcroForm fields/widgets.

## Shared Form-Entry Standard

- [ ] Define a shared form-entry standard for built-in forms.
- [ ] Use compact section flow modeled after MDOT 0582B.
- [ ] Use two-column layouts for short fields on S21 portrait and larger
  screens.
- [ ] Use full-width fields only for genuinely long text/signature surfaces,
  not as the default compact-phone layout.
- [ ] Keep repeated table entry fast, readable, and editable without leaving
  the app.
- [ ] For any section with multiple printed rows of the same information, show
  one compact app-entry composer that writes to the next available printed row.
- [ ] Show already-added repeated rows as a compact editable mini table.
- [ ] Do not show every printed row as a separate full input group in the app.
- [ ] When a repeated section reaches its printed row capacity, hide the add
  composer and show the user-facing message `printed rows are full`.
- [ ] Keep existing rows editable after printed row capacity is reached.
- [ ] Keep exported PDF field mapping separate from user-facing labels.
- [ ] Standardize new built-in form creation so Pressure Test Report follows
  the same app path as 0582B / 1126 / 1174R:
  - [ ] form type constant.
  - [ ] shipped template asset path.
  - [ ] built-in form registry entry.
  - [ ] initial data factory.
  - [ ] schema/defaults service.
  - [ ] validator.
  - [ ] calculator service when calculations are required.
  - [ ] PDF field filler.
  - [ ] route/screen registration.
  - [ ] widget tests.
  - [ ] template inventory test.
  - [ ] PDF mapping matrix test.
  - [ ] preview/export tests.
  - [ ] save/reopen/edit tests.
  - [ ] live sync proof.
- [ ] Do not accept a built-in PDF template as ready unless every user-entered
  value and every calculated output has a named AcroForm field.

## Static Wireframes Required

- [x] 1174R header section.
- [x] 1174R placement / water / curing / target ranges section.
- [x] 1174R Air / Slump section.
- [x] 1174R QA cylinder section.
- [x] 1174R quantities section.
- [x] 1174R remarks / computations section.
- [x] 1174R closeout section.
- [x] 1126 header section.
- [x] 1126 inspection / rainfall section.
- [x] 1126 measures section.
- [x] 1126 remarks and signature sections.
- [x] Pressure Test Report header section.
- [x] Pressure Test Report pipe/test setup section.
- [x] Pressure Test Report allowable leakage calculator section.
- [x] Pressure Test Report result-of-test section.
- [x] Pressure Test Report remarks / observer section.

## 1174R Todo

- [ ] Redesign 1174R so the whole form is not a long vertical list.
- [ ] Convert short-field sections into compact two-column groups wherever width
  allows.
- [ ] Header:
  - [ ] Group project/contract data together.
  - [ ] Group supplier/report/date data together.
  - [ ] Autofill known project data where reliable.
  - [ ] Keep all fields editable.
- [ ] Placement / water / curing / target ranges:
  - [ ] Use two-column layout for maximum time, structure number, AM/PM weather,
    curing gallons, intended air min/max, and intended slump min/max.
  - [ ] Keep longer fields like water-added reason and beams/cylinders made full
    width only if needed.
  - [ ] Allow intended air/slump values to carry forward from prior 1174R forms
    for the same project when available.
- [ ] Air / Slump:
  - [ ] Place left and right observations side by side.
  - [ ] Keep Time, Atmosphere, Concrete, Air %, Slump, and Cylinders/Beams
    compact.
  - [ ] Avoid forcing the user through a tall stacked field list.
- [ ] QA cylinder section:
  - [ ] Use a compact grid for Lot #, Lot size, Sublot #, Sublot size, Random #,
    QA cylinder, ID, Discrepancy, and Cylinder.
  - [ ] Keep comments editable and visually connected to the QA section.
  - [ ] Show one user-facing Comments field only.
  - [ ] Split long QA comment text into existing PDF/storage line fields behind
    the scenes.
  - [ ] Hydrate the one QA Comments field from existing saved `comments` and
    `comments_continued` data when reopening older forms.
- [ ] Quantities:
  - [ ] Use compact grid layout for short numeric fields.
  - [ ] Let longer station/item/grade fields breathe, but avoid unnecessary
    single-column stacking.
- [ ] Existing / printed rows:
  - [ ] Add a collapsible mini table for rows already added to each repeated
    section.
  - [ ] Use one active Add/Edit row composer for each repeated section instead
    of rendering every printed row as an input group.
  - [ ] Send newly added data to the next available printed row.
  - [ ] Make mini-table cells directly editable in-app.
  - [ ] Keep the collapsed state clean so the screen does not become cluttered.
- [ ] Remarks / Computations:
  - [ ] Replace page/line labels with one user-facing text box.
  - [ ] Split that text into existing PDF fields behind the scenes.
  - [ ] Hydrate the text box from existing saved page-line data when reopening
    older forms.
- [ ] Closeout:
  - [ ] Use two-column layout for technician/date/prepared-by/checked-by/
    closeout-date where possible.
  - [ ] Keep every closeout field editable after save/export/reopen.

## 1126 Todo

- [ ] Keep the current workflow sections, but make them match the shared
  form-entry standard.
- [ ] Header:
  - [ ] Use compact two-column grouping for project data and
    inspector/credential data.
  - [ ] Autofill known project/profile values.
  - [ ] Keep all values editable.
- [ ] Inspection / rainfall:
  - [ ] Keep rainfall rows compact.
  - [ ] Use side-by-side date and inches fields where width allows.
  - [ ] Present rainfall events as one compact Add Rainfall Event composer that
    writes to the next available rainfall row.
  - [ ] Show added rainfall events in a compact editable mini table.
  - [ ] Keep all rainfall rows editable after save/reopen.
- [ ] Measures:
  - [ ] Make measure rows easier to scan and edit.
  - [ ] Avoid tall card stacks when a compact row/table presentation works
    better.
  - [ ] Present measures as one active Add/Edit Measure composer plus a compact
    editable mini table of added measures.
  - [ ] Preserve status controls and corrective-action behavior.
- [ ] Remarks and signature:
  - [ ] Keep remarks simple and editable.
  - [ ] Preserve current signature invalidation rules when signed form data
    changes.

## Water Main Pressure Test Report Todo

- [ ] Add the Water Main Pressure Test Report as a built-in form.
- [ ] Use source/reference PDF:
  `assets/templates/forms/water_main_pressure_test_report_source.pdf`.
- [ ] Build final fillable template:
  `assets/templates/forms/water_main_pressure_test_report_form.pdf`.
- [ ] Preserve the visual layout of the supplied one-page sheet.
- [ ] Create actual named AcroForm text fields; the source PDF currently has an
  empty `/Fields` array and zero page widgets.
- [ ] Use semantic field names instead of arbitrary PDF object names.
- [ ] Keep all source inputs editable after save/reopen/export/sync.
- [ ] Keep all calculations visible in-app and written into the PDF.

### Pressure Test Report App Sections

- [ ] Header.
- [ ] Pipe Section To Be Tested.
- [ ] Allowable Leakage Calculator.
- [ ] Result Of Test.
- [ ] Remarks / Observer.

### Pressure Test Report Daily Entry Attachment Flow

- [ ] Use the same daily-entry attachment flow as every other built-in form.
- [ ] Do not create a Pressure-Test-specific attachment workflow.
- [ ] Let the form be created, attached to a daily entry, saved, reopened,
  synced, previewed, and exported through the existing shared flow.

### Pressure Test Report Header Fields

- [ ] Client.
- [ ] Date.
- [ ] Project Name.
- [ ] Project No.
- [ ] Contractor.
- [ ] Description of Pipe Material.
- [ ] Manufacturer.
- [ ] Type of Joint.
- [ ] Autofill known project/date/contractor values where reliable.
- [ ] Keep every value editable.

### Pressure Test Report Pipe Section Fields

- [ ] Required Test Pressure, psig.
  - [ ] Default to `150`.
  - [ ] Keep editable.
- [ ] Test Duration, hrs.
  - [ ] Default to `2`.
  - [ ] Keep editable.
- [ ] Test Equip. at Location.
- [ ] Pipe section rows, matching the printed three-row capacity:
  - [ ] Diameter (in.).
  - [ ] Length (feet).
  - [ ] Calculated allowable leakage for that pipe section.
- [ ] Present pipe section rows as one compact app entry composer that sends
  values to the next available printed row.
- [ ] Show already-added pipe rows as a compact editable mini table.
- [ ] Do not render three repeated pipe-row entry groups at once.
- [ ] When all three printed pipe rows are filled, hide the pipe row composer
  and show `printed rows are full`.
- [ ] Keep all three existing pipe rows editable from the mini table after the
  composer is hidden.
- [ ] Keep pipe rows compact on S21 with two-column input for Diameter and
  Length.
- [ ] Keep existing pipe rows editable in-app without editing the PDF.

### Pressure Test Report Allowable Leakage Calculator

- [ ] Use the printed factor:
  `0.083 gal/inch of diameter/1000 ft. pipe/hour`.
- [ ] Calculate each row's one-hour allowable leakage:
  `diameter_inches * length_feet / 1000 * 0.083`.
- [ ] Calculate Total gal / 1 hr. as the sum of row hourly leakage values.
- [ ] Calculate Total gal / selected test duration as:
  `total_gal_per_1_hr * test_duration_hours`.
- [ ] Default selected test duration to 2 hours so the printed `gal/ 2 hrs.`
  line is filled by default.
- [ ] Store calculated row values and totals in response data.
- [ ] Write calculated row values and totals into AcroForm fields.
- [ ] Mark calculated fields as calculated in the UI.
- [ ] Recalculate immediately when Diameter, Length, or Test Duration changes.
- [ ] Required Test Pressure stays editable and is exported, but it does not
  change the allowable leakage formula.
- [ ] Always use the printed `0.083` factor regardless of Required Test Pressure.

### Pressure Test Report Result Of Test Fields

- [ ] Use six result rows to match the printed sheet.
- [ ] Each result row has:
  - [ ] Time.
  - [ ] Initial pressure.
  - [ ] Final pressure.
  - [ ] Meter Reading, gal.
- [ ] Keep result rows compact in scan mode.
- [ ] Present result rows as one compact app entry composer that sends values to
  the next available printed row.
- [ ] Show already-added result rows as a compact editable mini table.
- [ ] Do not render six repeated result-row entry groups at once.
- [ ] When all six printed result rows are filled, hide the result row composer
  and show `printed rows are full`.
- [ ] Let users reopen and edit any result row in-app.
- [ ] Elapsed Time.
- [ ] Total loss, gallons.
- [ ] Calculate Total loss from previously entered Meter Reading, gal values
  when enough readings are available.
- [ ] Keep Total loss directly editable even when the app has calculated a
  value.
- [ ] Preserve a user-edited Total loss after save/reopen/export unless the user
  clears it or explicitly recalculates from meter readings.

### Pressure Test Report Remarks / Observer Fields

- [ ] Show one user-facing Remarks field.
- [ ] Split Remarks into printed PDF line fields behind the scenes if needed.
- [ ] Hydrate the one Remarks field from printed PDF line fields when reopening
  older saved data.
- [ ] Observer.

### Pressure Test Report Planned AcroForm Field Map

The source PDF has no fields. The final template must be authored with at least
these semantic AcroForm names.

| App field | Planned AcroForm field |
| --- | --- |
| Client | `client` |
| Date | `report_date` |
| Project Name | `project_name` |
| Project No. | `project_number` |
| Contractor | `contractor_name` |
| Description of Pipe Material | `pipe_material_description` |
| Manufacturer | `manufacturer` |
| Type of Joint | `joint_type` |
| Required Test Pressure | `required_test_pressure_psig` |
| Test Duration | `test_duration_hours` |
| Test Equip. at Location | `test_equipment_location` |
| Pipe row 1 Diameter | `pipe_section_1_diameter_inches` |
| Pipe row 1 Length | `pipe_section_1_length_feet` |
| Pipe row 1 Allowable Leakage | `pipe_section_1_allowable_leakage_gal_per_hr` |
| Pipe row 2 Diameter | `pipe_section_2_diameter_inches` |
| Pipe row 2 Length | `pipe_section_2_length_feet` |
| Pipe row 2 Allowable Leakage | `pipe_section_2_allowable_leakage_gal_per_hr` |
| Pipe row 3 Diameter | `pipe_section_3_diameter_inches` |
| Pipe row 3 Length | `pipe_section_3_length_feet` |
| Pipe row 3 Allowable Leakage | `pipe_section_3_allowable_leakage_gal_per_hr` |
| Total gal / 1 hr. | `allowable_leakage_total_gal_per_1_hr` |
| Total gal / test duration | `allowable_leakage_total_gal_for_duration` |
| Result row 1 Time | `test_result_1_time` |
| Result row 1 Initial pressure | `test_result_1_initial_pressure_psig` |
| Result row 1 Final pressure | `test_result_1_final_pressure_psig` |
| Result row 1 Meter Reading, gal | `test_result_1_meter_reading_gallons` |
| Result row 2 Time | `test_result_2_time` |
| Result row 2 Initial pressure | `test_result_2_initial_pressure_psig` |
| Result row 2 Final pressure | `test_result_2_final_pressure_psig` |
| Result row 2 Meter Reading, gal | `test_result_2_meter_reading_gallons` |
| Result row 3 Time | `test_result_3_time` |
| Result row 3 Initial pressure | `test_result_3_initial_pressure_psig` |
| Result row 3 Final pressure | `test_result_3_final_pressure_psig` |
| Result row 3 Meter Reading, gal | `test_result_3_meter_reading_gallons` |
| Result row 4 Time | `test_result_4_time` |
| Result row 4 Initial pressure | `test_result_4_initial_pressure_psig` |
| Result row 4 Final pressure | `test_result_4_final_pressure_psig` |
| Result row 4 Meter Reading, gal | `test_result_4_meter_reading_gallons` |
| Result row 5 Time | `test_result_5_time` |
| Result row 5 Initial pressure | `test_result_5_initial_pressure_psig` |
| Result row 5 Final pressure | `test_result_5_final_pressure_psig` |
| Result row 5 Meter Reading, gal | `test_result_5_meter_reading_gallons` |
| Result row 6 Time | `test_result_6_time` |
| Result row 6 Initial pressure | `test_result_6_initial_pressure_psig` |
| Result row 6 Final pressure | `test_result_6_final_pressure_psig` |
| Result row 6 Meter Reading, gal | `test_result_6_meter_reading_gallons` |
| Elapsed Time | `elapsed_time` |
| Total loss, gallons | `total_loss_gallons` |
| Remarks line 1 | `remarks_line_1` |
| Remarks line 2 | `remarks_line_2` |
| Remarks line 3 | `remarks_line_3` |
| Observer | `observer_name` |

### Pressure Test Report Code Integration

- [ ] Add form type constant, for example
  `kFormTypeWaterMainPressureTestReport`.
- [ ] Add template constant for
  `assets/templates/forms/water_main_pressure_test_report_form.pdf`.
- [ ] Add built-in form registry metadata.
- [ ] Add schema/default data service.
- [ ] Add calculator service for allowable leakage and total loss.
- [ ] Add PDF filler mapping app response data to the planned AcroForm field
  names.
- [ ] Add non-blocking validation/format warnings for numeric inputs.
- [ ] Add responsive form screen using the shared compact section workflow.
- [ ] Add quick action / create flow entry as appropriate for built-in forms.
- [ ] Use the existing daily-entry attachment flow for attaching this form to a
  daily entry.
- [ ] Add testing keys for driver/widget coverage.
- [ ] Add export filename policy behavior if needed.

### Pressure Test Report Validation / Export Behavior

- [ ] Never block export for missing Pressure Test Report fields.
- [ ] Missing fields export as blanks.
- [ ] Missing or invalid calculation inputs leave calculated outputs blank and
  show in-app warnings only.
- [ ] Validate Diameter, Length, Test Pressure, Test Duration, Meter Reading,
  Elapsed Time, and Total Loss as numeric/time-compatible values where
  applicable.
- [ ] Surface calculation blockers in the UI as warnings instead of preventing
  preview/export.
- [ ] Keep draft saving, preview, export, and final submission permissive for
  this form.

## 0582B Minimal Todo

- [ ] Do not redesign the MDOT 0582B flow broadly.
- [ ] Fix trailing `.0` formatting only for:
  - [ ] Chart density.
  - [ ] Chart moisture.
  - [ ] Operating density.
  - [ ] Operating moisture.
- [ ] Apply this cleanup in app display and PDF preview/export.
- [ ] Do not change decimal formatting in other MDOT 0582B sections.

## Testing Todo

- [ ] Add widget tests for 1174R two-column field layout behavior.
- [ ] Add widget tests for editable collapsible printed-row mini tables.
- [ ] Add tests for 1174R QA one-field Comments hydration and PDF line
  splitting.
- [ ] Add tests for 1174R single remarks text box hydration and PDF line
  splitting.
- [ ] Add 1126 widget tests for compact header and editable repeated sections.
- [ ] Add Pressure Test Report widget tests for:
  - [ ] S21 two-column header and pipe setup layout.
  - [ ] Tablet layout.
  - [ ] Pipe section single-entry composer, add-to-next-row behavior, and
    scan/edit mini table.
  - [ ] Pipe section full-capacity behavior: composer hidden, message
    `printed rows are full`, existing rows still editable.
  - [ ] Result row single-entry composer, add-to-next-row behavior, and
    scan/edit mini table.
  - [ ] Result row full-capacity behavior: composer hidden, message
    `printed rows are full`, existing rows still editable.
  - [ ] Calculated allowable leakage display.
  - [ ] Editable calculated Total loss behavior.
- [ ] Add Pressure Test Report daily-entry attachment flow test using the same
  path as other built-in forms.
- [ ] Add Pressure Test Report calculator tests for:
  - [ ] Single-row hourly leakage.
  - [ ] Multi-row one-hour total.
  - [ ] Selected-duration total.
  - [ ] Default two-hour total.
  - [ ] Recalculation when source inputs change.
  - [ ] Total-loss inference from meter readings.
- [ ] Add Pressure Test Report template inventory test proving named AcroForm
  fields exist.
- [ ] Add Pressure Test Report PDF mapping matrix tests proving every mapped
  field is populated in export.
- [ ] Add Pressure Test Report preview test proving preview is flattened and
  export preserves AcroForm fields.
- [ ] Add 0582B tests proving only the targeted chart/operating fields drop
  `.0`.
- [ ] Preserve existing PDF mapping tests for 1174R, 1126, and 0582B.
- [ ] Run live form checks that prove users can fill, save, reopen, edit,
  preview, export, and sync without editing PDFs outside the app.

## Assumptions

- "1126 UE" means the current MDOT 1126 Weekly SESC form flow.
- MDOT 0582B is the benchmark, not a redesign target.
- MDOT 1174R storage remains compatible with existing response fields.
- The Pressure Test Report source PDF is not a usable production template until
  a fillable AcroForm version is created.
- Pressure Test Report allowable leakage always uses the printed `0.083` factor.
- Required Test Pressure is an editable/exported field but does not affect the
  allowable leakage formula.
- Pressure Test Report `Initial` and `Final` result columns mean initial
  pressure and final pressure.
- Pressure Test Report has three printed pipe-section rows and six printed
  result-of-test rows.
- Default values stay conservative: known project/profile/date data, report
  number starting at `001`, and prior project values only for stable fields like
  intended air/slump ranges.

## Resolved Pressure Test Report Decisions

- [x] Required Test Pressure does not change the allowable leakage formula.
- [x] The allowable leakage formula always uses the printed `0.083` factor.
- [x] `Initial` means initial pressure.
- [x] `Final` means final pressure.
- [x] Total loss is calculated from previously entered Meter Reading, gal values
  when possible, but remains directly editable.
- [x] Match the printed form capacity: three pipe-section rows and six result
  rows.
- [x] No Pressure Test Report field blocks export.

## Resolved Wireframe Decisions

- [x] Device references: include both S21 portrait and tablet landscape.
- [x] 0582B relationship: borrow compact density and flow only; do not copy the
  exact 0582B layout because 1174R and 1126 differ.
- [x] S21 portrait field density: short, precise data-entry fields must use
  two-column layouts; do not default S21 to one-column stacking.
- [x] Repeated-row editability: keep existing/repeated rows compact when edits
  are not needed, and make rows editable in the app when opened for editing.
- [x] Field order: preserve the current optimized field order unless
  implementation finds a concrete defect.
- [x] Wireframe specificity: include final user-facing label text and field
  order so the layout reference is readable before implementation.
