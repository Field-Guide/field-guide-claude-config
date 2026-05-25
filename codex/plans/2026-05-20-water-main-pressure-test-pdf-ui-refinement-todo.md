# Water Main Pressure Test PDF/UI Refinement Todo

## Summary

- [ ] Update the Water Main Pressure Test Report app and exported PDF so the
  form has one clear leakage equation, calculated allowable fluid ounces, and
  calculated pass/fail.
- [ ] Keep the current formula:
  `Allowable Loss = Diameter x Length x sqrt(Pressure) / 148,000`.
- [ ] Remove the legacy visible source-PDF wording:
  `0.083 gal/inch of diameter/1000 ft. pipe/hour`.
- [ ] Export all new calculated values into the PDF.

## Full PDF Wireframe Mockup

```text
+--------------------------------------------------------------------------------+
|                               WATER MAIN                                       |
|                         PRESSURE TEST REPORT                                   |
|                                                                                |
| Client: [City of Grand Blanc____________________] Date: [2026-05-20____]       |
|                                                                                |
| Project Name: [Grand Blanc Test_________________] Project No.: [12344____]     |
|                                                                                |
| Contractor: [Ajax Paving______________________________________________]        |
|                                                                                |
| Description of Pipe Material: [DIP CL 52______________________________]        |
|                                                                                |
| Manufacturer: [US Pipe____________________] Type of Joint: [Push-on____]       |
|                                                                                |
|                         PIPE SECTION TO BE TESTED                              |
|                                                                                |
| Required Test Pressure: [150__] psig       Test Duration: [2__] hrs.           |
|                                                                                |
| Test Equip. at                                                                 |
| Location: [Hydrant at Sta. 12+50____________________________________]          |
|                                                                                |
| +------------+-------------+---------------------+---------------------------+ |
| | Diameter   | Length      | Allowable Leakage   | Allowable Loss =         | |
| | (in.)      | (feet)      | gal / 1 hr          | Diameter x Length x      | |
| |            |             |                     | sqrt(Pressure) / 148,000 | |
| +------------+-------------+---------------------+---------------------------+ |
| | [8_____]   | [1120____]  | [0.741__________]   |                           | |
| | [6_____]   | [480_____]  | [0.238__________]   |                           | |
| | [_____]    | [________]  | [_______________]   |                           | |
| +------------+-------------+---------------------+---------------------------+ |
|                                                                                |
| Total: [0.979________________] gal / 1 hr.                                      |
|        [1.958________________] gal / 2 hrs.       [250.6____] fluid oz.        |
|                                                                                |
|                               RESULT OF TEST                                   |
|                                                                                |
| +------------+----------------+----------------+----------------------------+ |
| | Time       | Initial        | Final          | Meter Reading, gal        | |
| +------------+----------------+----------------+----------------------------+ |
| | [8:00__]   | [150______]    | [150______]    | [12.0________________]    | |
| | [10:00_]   | [148______]    | [148______]    | [13.2________________]    | |
| | [______]   | [_________]    | [_________]    | [____________________]    | |
| | [______]   | [_________]    | [_________]    | [____________________]    | |
| | [______]   | [_________]    | [_________]    | [____________________]    | |
| | [______]   | [_________]    | [_________]    | [____________________]    | |
| +------------+----------------+----------------+----------------------------+ |
|                                                                                |
| Elapsed Time: [2:00____________]                                                |
| Total loss:  [1.2___________] gallons       Result: [Pass____]                 |
|                                                                                |
| Remarks: [Test held two hours. No visible leaks._______________________]       |
|          [_____________________________________________________________]       |
|          [_____________________________________________________________]       |
|                                                                                |
| Observer: [Maria Lopez________________________________________]                 |
|                                                                    (Name)      |
+--------------------------------------------------------------------------------+
```

## App Wireframe Mockup

```text
+------------------------------------------------+
| C Allowable Leakage                         ^ |
| 1.958 gal / duration - 250.6 fl oz             |
+------------------------------------------------+
| Allowable Loss = Diameter x Length x sqrt(P)   |
|                  / 148,000                     |
+------------------------------------------------+
| Row | Dia. | Length | Gal / 1 hr               |
| 1   | 8    | 1120   | 0.741                    |
| 2   | 6    | 480    | 0.238                    |
+-----------------------+------------------------+
| Total gal / 1 hr.     | Total gal / duration   |
| [0.979 calculated]    | [1.958 calculated]     |
+-----------------------+------------------------+
| Allowable fluid oz.   |                        |
| [250.6 calculated]    |                        |
+------------------------------------------------+

+------------------------------------------------+
| D Result Of Test                            ^ |
| 2 result rows - loss 1.2 gal - Pass            |
+-----------------------+------------------------+
| Elapsed Time          | Total loss, gallons    |
| [2:00............]    | [1.2 calc/editable]    |
+-----------------------+------------------------+
| Result                |                        |
| [Pass calculated]     |                        |
+------------------------------------------------+
```

## Implementation Todo

- [ ] Add schema fields:
  - [ ] `allowable_leakage_total_fluid_ounces`
  - [ ] `test_result_pass_fail`
- [ ] Update `WaterMainPressureTestCalculator`:
  - [ ] Convert selected-duration allowable leakage gallons to fluid ounces with
    `gallons * 128`.
  - [ ] Format fluid ounces to 1 decimal.
  - [ ] Set pass/fail blank when total loss or duration allowable leakage is
    missing.
  - [ ] Set `Pass` when
    `total_loss_gallons <= allowable_leakage_total_gal_for_duration`.
  - [ ] Set `Fail` when
    `total_loss_gallons > allowable_leakage_total_gal_for_duration`.
  - [ ] Keep manual total-loss override behavior intact.
- [ ] Update the in-app Leakage section:
  - [ ] Remove any old `0.083` language from visible UI.
  - [ ] Show the current equation plainly, not inside a boxed equation card.
  - [ ] Add small calculated `Allowable fluid oz.` field.
- [ ] Update the in-app Result section:
  - [ ] Add small calculated `Result` field near `Total loss, gallons`.
  - [ ] Show blank until both values needed for comparison exist.
- [ ] Update `tools/pdf-tools/create_water_main_pressure_template.py`:
  - [ ] Cover/remove the source PDF's `0.083.../1000...` wording.
  - [ ] Draw the current equation in that same area without the box.
  - [ ] Add AcroForm field `allowable_leakage_total_fluid_ounces`.
  - [ ] Add AcroForm field `test_result_pass_fail`.
  - [ ] Regenerate
    `assets/templates/forms/water_main_pressure_test_report_form.pdf`.
- [ ] Update PDF field mapping:
  - [ ] Export `allowable_leakage_total_fluid_ounces`.
  - [ ] Export `test_result_pass_fail`.
  - [ ] Update the Water Main template inventory expected field count.

## Testing Todo

- [ ] Calculator tests:
  - [ ] Fluid-ounce conversion from duration total.
  - [ ] One-decimal fluid-ounce formatting.
  - [ ] Pass when loss is less than allowable.
  - [ ] Pass when loss equals allowable.
  - [ ] Fail when loss exceeds allowable.
  - [ ] Blank result when comparison values are incomplete.
- [ ] Widget tests:
  - [ ] Leakage section shows current equation and fluid-ounce field.
  - [ ] Result section shows calculated pass/fail.
  - [ ] Manual total-loss edit recalculates pass/fail.
- [ ] PDF tests:
  - [ ] Template text no longer contains `0.083`.
  - [ ] Template text no longer contains `/ 1000`.
  - [ ] Template text contains the current equation.
  - [ ] Template field inventory includes both new semantic fields.
  - [ ] Export writes fluid ounces and pass/fail.
- [ ] Run:
  - [ ] `flutter test test/features/forms/data/services/water_main_pressure_test_calculator_test.dart -d windows`
  - [ ] `flutter test test/features/forms/data/pdf/water_main_pressure_test_pdf_filler_test.dart -d windows`
  - [ ] `flutter test test/features/forms/services/form_export_mapping_matrix_test.dart -d windows`
  - [ ] `flutter test test/features/forms/presentation/screens/water_main_pressure_test_form_screen_test.dart -d windows`
- [ ] Verify on the S21 against the office technician role on Grand Blanc Test
  project (`6936f810-ec15-494e-b4aa-280bf3bf15d3`, project number `12344`).

## Assumptions

- [ ] `Pass` is inclusive: total loss equal to allowable leakage passes.
- [ ] Fluid ounces convert from the selected-duration allowable leakage total.
- [ ] Pass/fail is calculated and exported, not manually selected.
- [ ] Pass/fail stays blank until data is entered.
