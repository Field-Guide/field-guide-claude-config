# OCR Vendor Decision - 2026-04-12

## Decision

Use Google Cloud Vision as the first cloud OCR path. Keep the local Tesseract
pipeline as the default and fallback until the Google path beats the local
pipeline on the prerelease corpus without regressing Springfield.

## Why Google First

- Google Cloud Vision / Document AI have the clearest enterprise posture for
  this use case: customer OCR content is not used to train Google models without
  permission/instruction.
- Pricing is small enough for the expected volume that operational correctness
  matters more than per-page cost.
- Cloud Vision is a cleaner fit than Document AI for v1 because we can keep the
  current row/region/pay-item parser and only swap the OCR engine.
- A company-owned Google Cloud project lets an admin own billing, credentials,
  auditability, and vendor enablement without putting Google secrets in the app.

## Options Reviewed

- Google Cloud Vision / Document AI: first choice. Use Vision first; move to
  Document AI only if raw Vision OCR/layout output is not enough.
- Mistral OCR: good second bake-off candidate if Google underperforms on the six
  prerelease PDFs.
- Azure Document Intelligence: viable if the company already standardizes on
  Azure, but not the first pilot.
- AWS Textract: lower priority unless AWS Organizations AI-service opt-out is
  explicitly configured and proven.
- ABBYY / Nanonets: secondary enterprise alternatives, not first pilot.

## Standard Test Path

Every OCR vendor must run through the same PDF hardening harness, one document
at a time:

- Springfield baseline goldens.
- The six prerelease PDFs in
  `test/features/pdf/extraction/fixtures/pre_release_pdf_corpus_manifest.json`.
- Compare item count, item-number ordering, total amount, M&P enrichment match
  rate, stage trace, elapsed time, and failure reason.

Do not create one-off vendor harnesses. Provider adapters must return the same
`OcrElement` contract consumed by the existing extraction pipeline.

## Official Sources

- Google Cloud Vision data usage: https://docs.cloud.google.com/vision/docs/data-usage
- Google Cloud Vision pricing: https://cloud.google.com/vision/pricing
- Google Document AI security: https://docs.cloud.google.com/document-ai/docs/security
- Google Document AI pricing: https://cloud.google.com/document-ai/pricing
- Mistral OCR announcement/pricing: https://mistral.ai/news/mistral-ocr
- Mistral data training policy: https://help.mistral.ai/en/articles/347617-do-you-use-my-user-data-to-train-your-artificial-intelligence-models
- AWS AI opt-out policy: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html
- AWS service terms: https://aws.amazon.com/service-terms/
