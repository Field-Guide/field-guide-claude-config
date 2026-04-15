# PDF Extraction Replay Audit

- Run: `.tmp/google_ocr_research/full_corpus_audit_current_20260415_01`
- Generated: 2026-04-15T13:48:59
- Replay failure count: 11
- Asserted mismatch count: 427
- Trace-contract failure count: 2
- Most upstream observed first-bad stage: `text_recognition` via `ocr_source_error`

## Root Cause Totals

| root_cause_bucket | count |
| --- | --- |
| post_normalization_error | 198 |
| row_parsing_error | 125 |
| ocr_source_error | 48 |
| numeric_interpretation_error | 27 |
| field_confidence_error | 15 |
| cell_assignment_error | 14 |

## Field Totals

| field | count |
| --- | --- |
| description | 290 |
| item_number | 50 |
| unit | 45 |
| quantity | 15 |
| fields_present | 15 |
| unit_price | 11 |
| bid_amount | 1 |

## Document Root Causes

| document_key | root_cause_bucket | count |
| --- | --- | --- |
| mdot_2026_03_06_estqua-pay-items | post_normalization_error | 76 |
| mdot_2026_04_03_estqua-pay-items | post_normalization_error | 71 |
| mdot_2025_12_05_estqua-pay-items | post_normalization_error | 44 |
| mdot_2026_04_03_estqua-pay-items | ocr_source_error | 40 |
| mdot_2026_03_06_estqua-pay-items | row_parsing_error | 36 |
| mdot_2026_04_03_estqua-pay-items | row_parsing_error | 35 |
| mdot_2025_12_05_estqua-pay-items | row_parsing_error | 33 |
| mdot_2026_04_03_estqua-pay-items | numeric_interpretation_error | 23 |
| berrien_127449_us12-pay-items | row_parsing_error | 16 |
| mdot_2026_04_03_estqua-pay-items | field_confidence_error | 13 |
| mdot_2026_04_03_estqua-pay-items | cell_assignment_error | 12 |
| mdot_2026_03_06_estqua-pay-items | ocr_source_error | 5 |
| mdot_2025_11_07_estqua-pay-items | row_parsing_error | 5 |
| mdot_2026_04_03_26_04001_bid_tab-pay-items | numeric_interpretation_error | 3 |
| mdot_2025_12_05_estqua-pay-items | ocr_source_error | 3 |
| mdot_2026_03_06_26_03001_bid_tab-pay-items | post_normalization_error | 3 |
| mdot_2026_03_06_26_03002_bid_tab-pay-items | post_normalization_error | 2 |
| mdot_2026_03_06_estqua-pay-items | numeric_interpretation_error | 1 |
| mdot_2026_03_06_26_03001_bid_tab-pay-items | field_confidence_error | 1 |
| mdot_2026_04_03_26_04001_bid_tab-pay-items | field_confidence_error | 1 |
| mdot_2026_04_03_26_04001_bid_tab-pay-items | post_normalization_error | 1 |
| mdot_2026_04_03_26_04003_bid_tab-pay-items | post_normalization_error | 1 |
| mdot_2026_04_03_26_04001_bid_tab-pay-items | cell_assignment_error | 1 |
| mdot_2026_03_06_26_03001_bid_tab-pay-items | cell_assignment_error | 1 |

## Trace Contract Failures

| document_key | trace_error_count |
| --- | --- |
| mdot_2026_03_06_26_03001_bid_tab-pay-items | 10 |
| mdot_2026_04_03_26_04001_bid_tab-pay-items | 8 |

## OCR Source Examples

| document_key | item_number | field | expected_value | actual_value | first_bad_stage |
| --- | --- | --- | --- | --- | --- |
| mdot_2025_12_05_estqua-pay-items | 0070 | description | Non Haz Contaminated Material Handling and Disposal, LM | Non Haz Contaminated Material Handling and D s ɔosal, LM | text_recognition |
| mdot_2025_12_05_estqua-pay-items | 0900 | unit | Dlr | DIR | text_recognition |
| mdot_2025_12_05_estqua-pay-items | 0990 | unit | Dlr | DIR | text_recognition |
| mdot_2026_03_06_estqua-pay-items | 0055 | description | Dr Structure Cover, Adj, Case 2 | Ɔ Structure Cover, Adj, Case 2 | text_recognition |
| mdot_2026_03_06_estqua-pay-items | 0060 | description | Dr Structure Cover, Type B | Ɔ Structure Cover, Type B | text_recognition |
| mdot_2026_03_06_estqua-pay-items | 0065 | description | Dr Structure, Cleaning | Ɔ Structure, Cleaning | text_recognition |
| mdot_2026_03_06_estqua-pay-items | 0095 | description | Dr Structure Cover, Type B | ☐ Structure Cover, Type B | text_recognition |
| mdot_2026_03_06_estqua-pay-items | 0105 | description | Dr Structure, 48 inch dia | ☐ Structure, 48 inch dia | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0005 | description | Mobilization, Max $97,500.00 | Mɔɔilization, Max $9,500.00 | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0005 | unit | LSUM | SJM | final_comparison |
| mdot_2026_04_03_estqua-pay-items | 0010 | description | Erosion Control, Inlet Protection, Fabric Drop | Er on ⚫ntro Ir t 1 abric Dro | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0015 | unit | LSUM | SJM | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0020 | unit | Syd | Sy | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0025 | unit | Ton | TCN | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0030 | unit | Ton | TCN | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0035 | description | Subbase, CIP | Sɩt base, CIP | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0035 | unit | Ton | TCN | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0035 | unit | Ton | ON | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0035 | unit | Ton | TOI | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0040 | unit | Ton | TOL | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0040 | unit | Ton | TCN | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0045 | description | _ Dr Structure Cover, Adj, Case 1, Modified | _ D⚫ Structure Cover, Adj, Case 1, Modified | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0050 | description | Dr Structure Cover, Adj, Case 1 | Ɔ Structure Cover, Adj, Case 1 | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0050 | unit | Ft | ET | text_recognition |
| mdot_2026_04_03_estqua-pay-items | 0055 | description | Dr Structure, Temp Lowering | ○ Structure, Temp Lowering | text_recognition |
