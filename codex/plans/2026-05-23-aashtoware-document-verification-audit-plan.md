# AASHTOWare Document Verification Audit Plan

Date: 2026-05-23
Owner: Codex
Status: active verification controller

## Purpose

This file is the persistent checklist for the one-document-at-a-time
verification pass over the AASHTOWare research package. Each wave should:

1. Read the current document.
2. Launch the full focused-agent wave for that document only.
3. Check the document against current public AASHTOWare/OpenAPI and MDOT APCM
   sources.
4. Check the document against current Field Guide code where it makes repo
   readiness claims.
5. Edit the document to downgrade unverified claims, add missed facts, and
   preserve blocked questions.
6. Run document hygiene checks before moving to the next wave.

Do not move endpoint/schema details from authenticated portal material into git
unless written terms allow it. Authenticated findings belong in concise notes
with portal links, endpoint names, operation IDs, schema field names, required
headers, rate limits, and implementation decisions.

## Wave Status

| Wave | Document | Status | Notes |
| --- | --- | --- | --- |
| 1 | `.codex/research/2026-05-23-aashtoware-openapi-research.md` | Complete | Three-agent audit completed: external research, local code/schema confirmation, and linear claim triage. Memo updated to soften unverified claims, correct source metadata, add MDOT/API caveats, add OAG risk context, and sharpen repo-readiness facts. |
| 2 | `.codex/plans/2026-05-23-aashtoware-openapi-integration-readiness-plan.md` | Complete | Three-agent audit completed: external research, local code/schema confirmation, and linear claim triage. Plan updated to sharpen access/legal/sandbox blockers, cite source-archive documents, protect Supabase sync boundaries, add no-endpoint architecture prep, soften auth/header assumptions, add code-readiness caveats, and add pilot handoff artifacts. |
| 3 | `docs/integrations/aashtoware/README.md` | Complete | Three-lane audit completed: public AASHTOWare/OpenAPI and MDOT source verification, local code/schema confirmation, and linear README claim triage. README updated to soften direct OpenAPI path claims, add the readiness and verification audit plans plus primary public-source anchors, distinguish Supabase sync from APCM transport, call existing MDOT/AASHTOWare code comments intent-only, and reinforce no-endpoint pre-access limits. |
| 4 | `docs/integrations/aashtoware/requirements.md` | Complete | Three-lane audit completed: public AASHTOWare/OpenAPI and MDOT source verification, local code/schema/sync/test confirmation, and linear requirement-status triage. Tracker updated to soften platform-convention claims, add evidence anchors, expand endpoint/access/network blockers, add legal/source-storage requirements, distinguish Field Guide/Supabase evidence from APCM readiness, and track missing APCM auth, queue, remote-state, material, attachment, signature, audit, and live-verification gaps. |
| 5 | `docs/integrations/aashtoware/mdot-mapping.md` | Complete | Three-lane audit completed: public MDOT/APCM workflow and OpenAPI source verification, local code/schema confirmation, and linear mapping claim triage. Mapping updated to add verification date, current-code evidence, schema-blocked caveats, Daily Diary/contract-time/subcontract/material/ProjectWise/OAG risk facts, signature mismatch warning, and stronger distinctions between local Supabase concepts and APCM remote-state/upload/write behavior. |
| 6 | `docs/integrations/aashtoware/access-checklist.md` | Complete | Three-lane audit completed: public AASHTOWare/OpenAPI and MDOT access/onboarding verification, local code/readiness confirmation, and linear checklist triage. Checklist updated to soften identity/product/path assumptions, add agency onboarding/root URL/firewall and product-entitlement proof, split public smoke from subscribed APCM proof, narrow first write verification to draft DWR only, add role/audit/secret/storage guardrails, and distinguish local/Supabase code from APCM implementation work. |
| 7 | `docs/integrations/aashtoware/source-documents/README.md` | Complete | Three-lane audit completed: public AASHTOWare/OpenAPI legal/catalog/source verification, local source-document directory and code-readiness confirmation, and linear README claim triage. README updated to make the directory a metadata/summary index rather than a document mirror, require written storage guidance before gated notes, expand prohibited artifact examples, add catalog currency and canonical inventory notes, and add narrow `.gitignore` guardrails for source-document payloads. |
| 8 | `docs/integrations/aashtoware/source-documents/2026-05-23-public-source-inventory.md` | Complete | Three-lane audit completed: public AASHTOWare/OpenAPI, catalog, legal, and MDOT source verification; local archive/code-readiness confirmation; and linear inventory claim triage. Inventory updated with verification date, stronger link-only archive posture, stale portal URL quarantine, current Getting Started URL, missing Project C&M product source, catalog currency details, OpenAPI standard numbering correction, and legacy XML resource scope correction. |
| 9 | `docs/integrations/aashtoware/source-documents/2026-05-23-aashtoware-openapi-infrastructure-summary.md` | Complete | Three-lane audit completed: public AASHTOWare/OpenAPI infrastructure, Developer Portal, catalog, standards, legal, and support-source verification; local code/status confirmation; and linear infrastructure-summary claim triage. Summary updated with verification date, source anchors, link-only archive posture, softer identity/catalog wording, corrected path and status-code caveats, catalog-year currency, support split, local code-readiness evidence, and expanded blocked infrastructure questions. |
| 10 | `docs/integrations/aashtoware/source-documents/2026-05-23-mdot-apcm-workflow-summary.md` | Complete | Three-lane audit completed: public MDOT APCM workflow, AASHTOWare Project/OpenAPI boundary, construction-documentation, and OAG audit verification; local code/schema/sync confirmation; and linear workflow-summary claim triage. Summary rewritten with verification findings, source-status table, public-workflow/API boundary warnings, current Field Guide code gaps, softened Mobile Inspector/offline wording, shadow-contract and OAG control context, and expanded blocked MDOT/Developer Portal questions. |
| 11 | `.codex/PLAN.md` and package hygiene | Complete | Three-lane audit completed: public source/package coverage, local repo/package hygiene, and linear PLAN/controller claim triage. Updated PLAN navigation, catalog timing, source-document ignore guardrails, residual external blocker summary, and this Wave 11 checklist. Hygiene checks passed with only expected LF/CRLF warnings. |

## Per-Wave Agent Pattern

Launch multiple focused agents for every active document, with non-overlapping
responsibilities:

- External research agent: current public AASHTOWare/OpenAPI, MDOT APCM,
  licensing/legal, and source-link verification as relevant to that document.
- Local code confirmation agent: current Field Guide code, migrations, models,
  sync surfaces, terminology, and schema facts referenced by that document.
- Document claim-audit agent: reads the active document linearly and checks
  every concrete claim for status: confirmed, inferred, blocked, stale,
  missing citation, or should be softened.

Give each agent the exact document path, the repo root, and a read-only mandate
unless explicitly assigning a disjoint edit scope. Ask for concrete findings
grouped as:
  - confirmed as written,
  - unverified or overstated,
  - missing but relevant,
  - local code evidence,
  - source links checked and retrieval date.
- The parent agent owns all edits and final verification.

## Wave 1 Checklist

- [x] Re-read primary research memo.
- [x] Agent: verify AASHTOWare/OpenAPI public platform, standards, support, and
  legal/licensing claims.
- [x] Agent: verify MDOT APCM workflow claims and identify missing public
  workflow sources.
- [x] Agent: verify local Field Guide readiness claims against current code and
  schema.
- [x] Agent: read the memo linearly and classify every concrete claim.
- [x] Parent: integrate agent findings into the research memo.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 2 Checklist

- [x] Re-read readiness plan, Wave 1 research memo, audit controller, and
  companion AASHTOWare docs.
- [x] Agent: verify readiness gates against current public AASHTOWare/OpenAPI
  access, licensing, support, standards, and legal sources.
- [x] Agent: verify local Field Guide architecture, schema, sync, and test
  assumptions against current code.
- [x] Agent: read the readiness plan linearly and classify concrete claims.
- [x] Parent: integrate agent findings into the readiness plan.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 3 Checklist

- [x] Re-read README, Wave 1 research memo, Wave 2 readiness plan, audit
  controller, and companion AASHTOWare docs.
- [x] Agent: verify README navigation, naming, public-source anchors,
  and legal/source-storage warnings against current public AASHTOWare/OpenAPI
  and MDOT APCM sources.
- [x] Agent: verify README current-state claims against local Field
  Guide code, schema, sync, PDF extraction, and repo docs.
- [x] Agent: read the README linearly and classify concrete claims.
- [x] Parent: integrate findings into the README with local code anchors and
  pre-access implementation limits.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 4 Checklist

- [x] Re-read requirements tracker, research memo, readiness plan, README,
  mapping notes, access checklist, and source-document summaries.
- [x] Agent: verify requirements against current public AASHTOWare/OpenAPI,
  catalog, standards, legal, and MDOT APCM workflow sources.
- [x] Agent: verify local-code-facing requirements against Field Guide models,
  schema, sync, storage, auth, tests, and AASHTOWare PDF extraction references.
- [x] Agent: read the tracker linearly and classify concrete requirement rows.
- [x] Parent: integrate findings into the requirements tracker.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 5 Checklist

- [x] Re-read MDOT mapping notes, research memo, readiness plan, README,
  requirements tracker, access checklist, and source-document archive.
- [x] Agent: verify mapping concepts against current public AASHTOWare/OpenAPI,
  MDOT APCM workflow, construction/e-construction, legal, and audit sources.
- [x] Agent: verify Field Guide mapping claims against local project, daily
  entry, quantity, contractor, personnel, forms, attachment, signature,
  pay-app, auth/role, sync, and PDF-extraction code.
- [x] Agent: read the mapping notes linearly and classify concrete claims.
- [x] Parent: integrate findings into the mapping notes.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 6 Checklist

- [x] Re-read access checklist, research memo, readiness plan, README,
  requirements tracker, MDOT mapping notes, and source-document archive.
- [x] Agent: verify access/onboarding tasks against current public
  AASHTOWare/OpenAPI, Developer Portal, catalog, legal, and MDOT APCM sources.
- [x] Agent: verify local-code-facing checklist claims against Field Guide
  auth/config, role, sync, attachment, signature, project, and PDF-extraction
  code.
- [x] Agent: read the access checklist linearly and classify concrete claims.
- [x] Parent: integrate findings into the access checklist.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 7 Checklist

- [x] Re-read source-documents README, public source inventory, OpenAPI
  infrastructure summary, MDOT APCM workflow summary, research memo, readiness
  plan, integration README, requirements tracker, MDOT mapping, and access
  checklist.
- [x] Agent: verify source archive policy against current public
  AASHTOWare/OpenAPI, Developer Portal, catalog, legal/copyright, and MDOT
  public-source evidence.
- [x] Agent: verify local source-document directory contents, local markdown
  links, `.gitignore` enforcement, and Field Guide code references that affect
  archival claims.
- [x] Agent: read the source-documents README linearly and classify concrete
  claims.
- [x] Parent: integrate findings into the source-documents README and narrow
  `.gitignore` artifact guardrails.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 8 Checklist

- [x] Re-read public source inventory, source-documents README, audit
  controller, and companion AASHTOWare docs.
- [x] Agent: verify source inventory against current public AASHTOWare/OpenAPI,
  Developer Portal, catalog, legal/copyright, AASHTOWare Project, MDOT APCM,
  construction, audit, and legacy XML sources.
- [x] Agent: verify local source-document directory contents, archive guardrails,
  companion-doc links, and current Field Guide code references affecting source
  inventory claims.
- [x] Agent: read the source inventory linearly and classify concrete source
  rows as current, stale, duplicate, missing, or blocked.
- [x] Parent: integrate findings into the public source inventory.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 9 Checklist

- [x] Re-read OpenAPI infrastructure summary, public source inventory,
  source-documents README, audit controller, and companion AASHTOWare docs.
- [x] Agent: verify infrastructure summary against current public
  AASHTOWare/OpenAPI, Developer Portal, catalog, standards, legal/copyright,
  and support sources.
- [x] Agent: verify local-code-facing infrastructure claims against Field Guide
  project mode, terminology, sync, auth, attachment/signature, PDF extraction,
  `.gitignore`, and source-document contents.
- [x] Agent: read the infrastructure summary linearly and classify concrete
  claims.
- [x] Parent: integrate findings into the OpenAPI infrastructure summary.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 10 Checklist

- [x] Re-read MDOT APCM workflow summary, public source inventory,
  source-documents README, requirements tracker, MDOT mapping notes, access
  checklist, and audit controller.
- [x] Agent: verify workflow summary against current public MDOT APCM workflow,
  construction/e-construction, AASHTOWare Project C&M, OpenAPI boundary, and
  OAG audit sources.
- [x] Agent: verify local-code-facing workflow claims against Field Guide
  project mode, project metadata, daily entries, quantities, contractors,
  equipment/personnel, pay applications, files, signatures, forms, Supabase
  sync, PDF extraction references, and missing APCM implementation seams.
- [x] Agent: read the workflow summary linearly and classify concrete claims.
- [x] Parent: integrate findings into the MDOT APCM workflow summary.
- [x] Parent: run document hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.

## Wave 11 Checklist

- [x] Re-read `.codex/PLAN.md`, this audit controller, the readiness plan,
  research memo, integration docs, source-document summaries, `.gitignore`, and
  current package file tree.
- [x] Agent: verify public AASHTOWare/OpenAPI, catalog, legal, Developer
  Portal, AASHTOWare Project C&M, MDOT APCM workflow, and OAG source coverage
  for the final package index.
- [x] Agent: verify local package hygiene, source-document payload absence,
  `.gitignore` guardrails, local markdown links, and code-readiness claims.
- [x] Agent: read `.codex/PLAN.md` and this audit controller linearly and
  classify stale, missing, or incomplete AASHTOWare index claims.
- [x] Parent: correct catalog timing so FY 2026 remains the current fiscal-year
  baseline through June 30, 2026 and FY 2027 remains forward-looking until July
  1, 2026.
- [x] Parent: add explicit AASHTOWare package navigation to `.codex/PLAN.md`.
- [x] Parent: strengthen `.gitignore` source-document guardrails for SDK,
  generated SDK, secret, token, credential, and certificate payload shapes.
- [x] Parent: preserve the residual external blocker summary: MDOT/AASHTOWare
  contacts, legal/storage guidance, subscription/product access, MDOT sandbox
  test data, auth/role/audit model, endpoint schemas, and MDOT-approved live
  proof remain blocked externally.
- [x] Parent: run package hygiene checks.
- [x] Parent: update this checklist status and the on-screen task list.
