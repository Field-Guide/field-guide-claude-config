# Pressure Test Allowable Leakage Formula Fix Spec

## Summary

Update the Water Main Pressure Test allowable leakage calculation and the
visible formula printed on the generated PDF template to:

`L = D x S x sqrt(P) / 148000`

Where:

- `D` is pipe diameter in inches.
- `S` is pipe section length in feet.
- `P` is `required_test_pressure_psig`.

## Implementation Tasks

- [ ] Update `WaterMainPressureTestCalculator` so each pipe row calculates:
  `diameter * length * sqrt(required_test_pressure_psig) / 148000`.
- [ ] Preserve existing formatting behavior:
  - round each row to 3 decimals.
  - trim trailing zeroes.
  - sum rounded row values into the hourly total.
  - multiply hourly total by test duration.
- [ ] Update `tools/pdf-tools/create_water_main_pressure_template.py` so the
  visible formula box documents:
  - `Allowable Loss =`
  - `Diameter x Length x sqrt(Pressure)`
  - `/ 148,000`
- [ ] Update the template AcroForm JavaScript to read
  `required_test_pressure_psig`, use `Math.sqrt(pressure)`, and divide by
  `148000`.
- [ ] Ensure `required_test_pressure_psig` is present as an editable AcroForm
  field in the shipped template.
- [ ] Regenerate
  `assets/templates/forms/water_main_pressure_test_report_form.pdf`.
- [ ] Update calculator tests for 150 psig expected values:
  - `8 in x 1120 ft = 0.741`
  - `6 in x 480 ft = 0.238`
  - `Total per 1 hr = 0.979`
  - `Default 2 hr total = 1.958`
- [ ] Update PDF filler and export mapping matrix tests for the new values.
- [ ] Assert the shipped PDF text contains the new formula and no longer
  contains `Diameter x Length x 0.083` or `/ 1000`.
- [ ] Assert AcroForm scripts contain `Math.sqrt(pressure)` and `/ 148000`.

## Focused Verification

Run:

```powershell
flutter test test/features/forms/data/services/water_main_pressure_test_calculator_test.dart -d windows
flutter test test/features/forms/data/pdf/water_main_pressure_test_pdf_filler_test.dart -d windows
flutter test test/features/forms/services/form_export_mapping_matrix_test.dart -d windows
flutter test test/features/forms/presentation/screens/water_main_pressure_test_form_screen_test.dart -d windows
```

## Assumptions

- `P` is the existing `required_test_pressure_psig` field.
- The formula note printed on the PDF is authoritative user-facing
  documentation and must change with the math.
- The denominator is exactly `148000`; the displayed formula may show
  `148,000` for readability.
