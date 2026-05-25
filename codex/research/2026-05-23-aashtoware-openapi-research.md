# AASHTOWare OpenAPI Research - MDOT APCM

Date checked: 2026-05-23
Target: MDOT AASHTOWare Project Construction & Materials (APCM)
Scope: public research, repo readiness, and external-access checklist.
Status: implementation is blocked until authorized Developer Portal/API catalog
and MDOT sandbox access exist.

## Executive Summary

Repo inspection suggests Field Guide has useful foundations for an AASHTOWare
integration, but the public docs do not expose enough authoritative schema
detail to write a production client yet.

Confirmed public facts:

- AASHTOWare OpenAPI is an API gateway/integration platform, not a public data
  repository.
- Product API implementations are deployed against agency AASHTOWare assets and
  registered with the OpenAPI platform.
- Developer Portal sign-in, licensing/subscription activation, API keys, and
  product-specific API documentation are required before real API calls.
- Public examples show the gateway root `https://api.aashtoware.org`, an
  `awapi` path alias, an agency/instance path segment such as `MDOT`, and
  subscription-key usage through `Ocp-Apim-Subscription-Key`; MDOT's actual
  subscribed catalog path and production/sandbox aliases remain unverified.
- Public AASHTOWare API standards favor OpenAPI definitions, JSON, explicit
  security schemes, versioned/deprecated API lifecycle, request tracking,
  pagination, rate-limit headers, ETags for concurrency, and standard HTTP
  status semantics including `409 Conflict` and `423 Locked`.
- MDOT APCM public workflow docs expose enough business concepts to plan
  mappings: contracts, contract authority, DWRs, item postings, materials,
  sample records, attachments/links, daily diaries, change orders, and payment
  estimates.
- AASHTO's public legal/copyright pages restrict reuse, distribution, and
  storage of site material beyond expressly authorized uses. Treat committed
  copies of PDFs, portal pages, diagrams, videos, generated SDKs, schemas, or
  gated API specs as prohibited unless written permission or license terms
  explicitly allow it.

Most important blocked items:

- Product-specific API catalog and OpenAPI specs for AASHTOWare Project/APCM.
- MDOT instance/sandbox URL path and supported environments.
- Auth scheme for MDOT APCM API consumers: AASHTO Identity, API subscription
  key, OAuth2/OpenID, MILogin delegation, service account, or a combination.
- Exact schema fields, identifiers, code lists, status transitions, allowed
  writes, pagination, filtering, rate limits, attachment upload mechanics, and
  concurrency controls.
- MDOT test contract IDs and acceptance criteria for a safe sandbox proof.

## Public Source Inventory

Retrieval date for all sources: 2026-05-23.

### AASHTOWare OpenAPI Platform

| Source | URL | What It Confirms | Confidence |
| --- | --- | --- | --- |
| AASHTOWare OpenAPI product page | https://www.aashtoware.org/openapi/ | OpenAPI is the integration platform for AASHTOWare products; it provides gateway/routing infrastructure, Developer Portal/Store integration, domain-based user management, member and non-member licensing. | High |
| OpenAPI announcement | https://www.aashtoware.org/story/what-is-aashtoware-openapi/ | Platform launched in 2023, uses OpenAPI specifications and an API-management switchboard. AMS can coexist, but future features may be OpenAPI-only. Third parties go through Data Alliance/Alliance Program paths. | High |
| Developer Portal docs landing | https://developer.aashtoware.org/docs | Search-indexed public content says the portal uses Azure API Management documentation tooling and product-specific docs include endpoints, auth/security, examples, and best practices. Direct public retrieval returned 404 during Wave 11 on 2026-05-23; use the Resources and Products pages as current reachable confirmation that full API libraries/catalogs require sign-in. | Low |
| Developer Portal About | https://developer.aashtoware.org/content/html_widgets/mb9tp.html | Gateway/intelligent routing, domain-based user management, testing/production environments, sandbox/testbed references, OAuth2/token-based access, role-issued subscription keys. | High |
| Getting Started | https://developer.aashtoware.org/content/html_widgets/zku5f.html | Account, Store registration, license order, subscription activation, API key generation, and sample ping call with `Ocp-Apim-Subscription-Key`. Older public widget `https://developer.aashtoware.org/content/html_widgets/b7wj5.html` returned 404 during Wave 11 on 2026-05-23; use `zku5f.html` as the current public Getting Started anchor. | High |
| Portal access | https://developer.aashtoware.org/support/portal-access | Search-indexed public content says AASHTO Identity is used for portal access and subscription-key rights may take up to 24 hours after account creation. Direct public retrieval returned 404 during Wave 11 on 2026-05-23; reachable Getting Started content confirms the Store/portal/subscription flow. | Low |
| Resources/API libraries | https://developer.aashtoware.org/content/html_widgets/yexeg.html | Full API libraries require sign-in; non-registered users see restricted demos and samples. Public sample references include AASHTOWare Project AMS Lab, BrM API Lab, and AOAPI Dev Lab Workbench. | High |
| DOT Configuration Guide | https://developer.aashtoware.org/content/html_widgets/nzq08.html | OpenAPI does not host API implementations or persist AASHTOWare app data. Agency implementations are deployed to agency assets. Gateway public IP, URL path conventions, Azure PaaS/iPaaS architecture, monitoring, and security concepts are public. | High |
| Technical standardization guide | https://awapistorage.blob.core.windows.net/portal-content/guides/aoapi-complete-guide.html | API design conventions: metadata, versioning, `x-api-terms`, OAuth2/OpenID preference, header naming, `X-RateLimit-*`, `X-Request-Id`, JSON/XML support, lower snake case resource/entity conventions, ETags, status codes, file upload semantics, and batch/async patterns. | High |
| Data Lab relocation | https://aoapi-datalab.azurewebsites.net/ | The former Data Lab moved into the Developer Portal; docs, specifications, interactive console, subscription management, and API catalogs are now portal-centered. | High |
| Support | https://developer.aashtoware.org/content/html_widgets/h4g97.html | OpenAPI support handles auth, endpoints, pagination/filtering, rate limits/quotas, SDKs, and portal issues. Product support handles data definitions, workflows/states, calculations, roles/permissions, import/export jobs, and data quality. | High |
| FAQ | https://developer.aashtoware.org/content/html_widgets/t2qya.html | Prerequisites are active license, Developer Portal account, authentication credentials, and endpoint network access. Third-party integrations need defined data flow, frequency, least privilege, scalability/performance planning, and non-production environments. All API access transitions to OpenAPI by December 2029. | High |

### AASHTOWare Catalogs, Standards, and Legal

| Source | URL | What It Confirms | Confidence |
| --- | --- | --- | --- |
| FY 2026 Catalog | https://www.aashtoware.org/wp-content/uploads/2025/05/FY-2026-AASHTOWare-Catalog-web.pdf | Current fiscal-year catalog on 2026-05-23, covering July 1, 2025-June 30, 2026. Keep as current-year baseline/comparison; treat as historical only after FY 2027 starts. | Medium |
| FY 2027 Catalog | https://www.aashtoware.org/wp-content/uploads/2026/05/FY-2027-AASHTOWare-Catalog_web.pdf | Latest published/upcoming FY 2027 catalog for July 1, 2026-June 30, 2027. OpenAPI section includes 50,000 transactions/minute ceiling across licenses, member no-cost access, non-member Basic no-cost, Enhanced $12,000, Premium $18,000, request/data limits, sandbox options, and technical support pricing. | High |
| Standards and Guidelines Notebook | https://www.aashtoware.org/wp-content/uploads/2026/04/SG_Notebook_040126.pdf | April 2026 notebook adds a new `2.100S AASHTOWare OpenAPI Standard`. It requires OpenAPI definitions and covers endpoints, data models, security/access/auth methods, responses, schema definitions, pagination, request bodies, testing/validation, usage guidelines, monitoring, lifecycle, deprecation, and API registration. | High |
| Ordering | https://www.aashtoware.org/about/ordering/ | Products are ordered through AASHTOWare processes. Public contact references exist for business operations. | High |
| AASHTOWare legal information | https://www.aashtoware.org/legal-information/ | Public browsing is allowed, but distribution/reuse of site content without written permission is restricted. | High |
| AASHTOWare copyright notice | https://www.aashtoware.org/copyright-notice/ | AASHTOWare marks and site materials are protected. Do not reproduce or store site material except as expressly authorized. | High |
| AASHTOWare Project copyright notice | https://www.aashtowareproject.org/copyright-notice | Project-site documents are similarly constrained. | High |

### MDOT APCM Public Workflow Sources

| Source | URL | What It Confirms | Confidence |
| --- | --- | --- | --- |
| MDOT AASHTOWare wiki main page | https://mdotwiki.state.mi.us/aashtoware/index.php/Main_Page | Public MDOT APCM manual, support path, known issues, construction/materials operational context. | High |
| Access and Roles | https://mdotwiki.state.mi.us/aashtoware/index.php/Access_and_Roles | MDOT users access APCM through MILogin. Users can have multiple roles but only one active role at a time. Common roles include `INSPECTOR`, `MobileInspector`, `MDOT_OFFICETECH`, `MDOT_MATADMIN`, read-only contractor/MDOT/local/consultant roles, project engineer, construction engineer, and finance administrator. | High |
| Mobile Applications | https://mdotwiki.state.mi.us/aashtoware/index.php/Mobile_Applications | Mobile Inspector is a PWA/offline DWR/IDR app. Device registration and contract-specific authority under `MobileInspector` are required to sync contract data. | High |
| Contract Administration | https://mdotwiki.state.mi.us/aashtoware/index.php/Contract_Administration | Contract metadata, administrative offices, contract-specific authority, contract/project items, unattached items, subcontracts, contractor items, attention flags, archive/finance-closeout behavior. | High |
| Daily Work Reports | https://mdotwiki.state.mi.us/aashtoware/index.php/Daily_Work_Reports | DWR header fields, remarks, weather/rainfall/temp, contractors, equipment, personnel, item postings, material postings, attachments/links, submit/approve/reject/revise statuses, payment-estimate lock behavior. | High |
| Daily Diaries | https://mdotwiki.state.mi.us/aashtoware/index.php/Daily_Diaries | A daily diary is a per-contract, per-day rollup of DWRs, normally project-manager authored, with DWR management, time charges, remarks, weather, and payment estimate fields. | High |
| Materials Acceptance | https://mdotwiki.state.mi.us/aashtoware/index.php/Materials_Acceptance | Material and acceptance actions are generated from statewide reference material sets. Material sets can be created but not deleted. Sample records, sources, contract item associations, default tests, and test results are tracked. | High |
| Shadow Contracts | https://mdotwiki.state.mi.us/aashtoware/index.php?title=Shadow_Contracts | Publicly reinforces pay-item/material relationships, material quantity tracking, source, acceptance status, specification compliance, and test frequency. | Medium |
| Pay Estimates | https://mdotwiki.state.mi.us/aashtoware/index.php/Pay_Estimates | Payment estimates track contractor payment for contract/project/item work, type/period, exceptions, project vouchers, item and contract adjustments, approval decisions, role approval paths, and statuses. | High |
| Change Orders | https://mdotwiki.state.mi.us/aashtoware/index.php/Change_Orders | Change orders legally alter contracts, quantities, time, final quantities, specs, new/unattached/modified items, approval rounds, revision numbers, and prior approved totals. | High |
| Global Actions | https://mdotwiki.state.mi.us/aashtoware/index.php/Global_Actions | Imports/exports/processes, process history, global attachments, global links, and outbox/email concepts exist. | Medium |
| Standard Naming Convention | https://mdotwiki.state.mi.us/construction/index.php?title=Standard_Naming_Convention | Public naming examples for IDRs, photos/videos, NPDES/SESC 1126, concrete 1174R/1174S, and other records. Useful for export/attachment metadata. | Medium |
| E-Construction | https://mdotwiki.state.mi.us/construction/index.php/E-Construction | MDOT project records may live in ProjectWise/archive systems; local agencies own LAP records. ProjectWise permissions, final-status/no-modification concepts, and broken-link risk matter for attachment/link integration. | Medium |
| Documentation Guide PDF, March 2024 | https://mdotwiki.state.mi.us/images_construction/1/1c/Documentation_Guide_June_2023.pdf | Public construction documentation guidance reinforces pay-quantity support, calculations, measurements, supporting documentation, and VI/material notation. The URL still contains `June_2023`, but the retrieved PDF identifies the guide as March 2024 and includes its own reproduction restrictions. | Medium |
| Progress and Partial Payments | https://mdotwiki.state.mi.us/construction/index.php/109.04_Progress_and_Partial_Payments | Change Orders should be processed promptly, including weekly or threshold-driven over-authorized item handling. Useful for Field Guide warnings. | Medium |
| OAG APCM audit | https://audgen.michigan.gov/wp-content/uploads/2024/01/r591059123-9717.pdf | Public audit confirms APCM documents daily project work and compiles biweekly contractor payments; mentions accessible views, SIGMA payment-voucher interface, access-control weaknesses, effective interface controls, and sufficient construction-record accuracy controls for the tested scope, but not API schemas. | Medium |

The MDOT sources above describe public APCM UI workflows and business concepts.
They do not confirm API endpoint availability, schema fields, write permissions,
or product-specific OpenAPI behavior.

## Confirmed Facts

### Platform and Network

- AASHTOWare OpenAPI is a cloud gateway and API management layer.
- It does not itself store agency AASHTOWare data for normal API scenarios.
- Agency product API implementations are deployed beside or against agency
  AASHTOWare assets and registered into OpenAPI.
- The gateway is public-internet accessible; agency endpoints communicate with
  the dedicated gateway. Agency-side endpoint and firewall configuration still
  depends on MDOT/AASHTO onboarding.
- Public docs list gateway public IP `20.85.141.79`.
- Public diagrams and text show path shape:
  `https://api.aashtoware.org/awapi/{instance}/{product-or-alias}/{operation}`.
  The public example image uses `MDOT` and `awproject/projects`, but this must
  be verified against MDOT's actual catalog.

### Developer Access and Licensing

- AASHTOWare Store registration and Developer Portal sign-in are part of public
  onboarding. Search-indexed portal-access content also refers to AASHTO
  Identity, but direct public retrieval was unreliable on 2026-05-23.
- License/subscription activation is required before API keys are available.
- Member agencies with active AASHTOWare product licenses can receive OpenAPI
  member access at no separate license cost.
- Non-member options include Basic, Enhanced, and Premium. FY 2027 public
  catalog lists Basic as no-cost, Enhanced as $12,000, Premium as $18,000.
- FY 2027 catalog lists OpenAPI request/data limits:
  - all licenses: 50,000 transactions/minute ceiling.
  - Basic: shared sandbox, 1,000 requests/hour, 10,000/day, 100,000/month,
    10 GB/month.
  - Enhanced: shared sandbox, unlimited requests under the global ceiling,
    10 GB/month.
  - Premium: dedicated sandbox available at extra cost, unlimited requests under
    the global ceiling, 25 GB/month, optional bandwidth blocks.
- OpenAPI support and product support are separate. Endpoint availability,
  auth, pagination, rate limits, and portal issues go to OpenAPI support; APCM
  data definitions and business workflows go to product/MDOT support.
- These prices and request/data limits are procurement and planning facts from
  the FY 2027 catalog checked on 2026-05-23, not durable implementation
  constants. Re-verify before contracting or designing rate-limit policy.

### Auth and Headers

- Public getting-started material shows subscription-key calls using
  `Ocp-Apim-Subscription-Key`.
- Public standards reserve `Authorization` for Bearer/Basic credentials and
  recommend OAuth2/OpenID as preferred security schemes.
- Public About material refers to OAuth2/token-based access and subscription
  keys issued per role.
- Public MDOT wiki says APCM end users access the application through MILogin.
  This confirms APCM UI identity, but it does not prove that external API
  consumers authenticate directly with MILogin. Treat MILogin API auth as
  unconfirmed until MDOT/AASHTO confirms the client registration flow.
- Client design should support `X-Request-Id` where required or accepted by the
  subscribed API; responses may include correlation IDs and rate-limit headers.

### API Conventions

- REST APIs use OpenAPI definitions in YAML or JSON.
- API definitions include title, description, contact, version, and
  `x-api-terms`.
- Public standardization material includes versioning guidance; verify the
  exact path-versioning rule against the current standard before treating
  `/v1` avoidance as product-specific.
- JSON must be supported for payload operations; XML may also be supported.
- Common pagination parameters are `page_index`, `page_size`, `page_offset`,
  `page_sortby`, and `page_cursor`.
- Common content controls include `filter_expression`, `fields`, `expand`, and
  `expand_depth`.
- ETags are recommended for resource versioning, caching, and concurrency.
- Important expected status codes include `201 Created`, `202 Accepted`,
  `207 Multi-Status`, `409 Conflict`, and `423 Locked`.
- File uploads should use binary-capable `POST`/`PUT`; metadata changes should
  use PATCH-like operations where supported.
- Treat these as platform standards and conventions until the authenticated
  APCM API spec confirms actual endpoint behavior.

### MDOT/APCM Business Workflow

- APCM DWRs are close to Field Guide Daily Entries/IDRs but have additional
  official state, authority, payment, material, and lock semantics.
- DWRs include weather, rainfall, low/high temperature, remarks, entered and
  approved metadata, payment estimate number/status, attachment and work-item
  indicators.
- Contractor presence is required before item postings to that contractor.
- DWR equipment tracks count on site, count used, hours used, idle hours, and
  comments.
- DWR personnel tracks count on site, total hours, and comments.
- Item postings use contract line numbers and include contractor, posted
  quantity, station/offset from-to, location, measured/interim flag, material
  set, plan sheet page, and comments.
- Material rows derive from material sets and include installed quantity, units,
  source ID, VI/accepted state, and comments.
- Attachments include files such as documents, spreadsheets, PDFs, photos, and
  graphics; links may point to ProjectWise URNs.
- Public MDOT workflow docs show DWR status concepts such as Draft, Pending,
  Pending Approval, Approved, and Rejected. Exact API enum values and transition
  rules remain blocked on MDOT/API catalog confirmation. The public workflow
  docs state that the DWR creator cannot approve their own DWR, and approved
  DWRs that are picked up by an estimate are locked from future changes.
- DWR notes are not part of the official DWR and should not be used for
  official record content.
- Daily Diaries roll up DWRs per contract/day and can carry time charges and
  approval/authorization activity.
- Payment Estimates include period end date, exceptions, project vouchers,
  item/contract adjustments, approval tracking, Draft/Pending Approval/Approved/
  Rejected statuses, and role-based approval sequences.
- Change Orders are the route for legally changing contract quantities, items,
  time, final quantities, and specs. Unattached items can be tracked on DWRs but
  are not payable until added through an approved change order.
- The January 2024 OAG APCM audit reported access-control weaknesses and
  observed self-approved DWRs during the audit period. Treat public role and
  approval notes as current workflow indicators, not sufficient proof of
  current MDOT segregation-of-duty behavior or API permission enforcement.

## Repo Readiness Facts

These are current repo observations from the 2026-05-23 inspection.

- `lib/features/projects/data/models/project_mode.dart` already includes MDOT
  mode terminology.
- `lib/core/config/app_terminology.dart` already maps IDR to DWR, Bid Item to
  Pay Item, and Contract Modification to Change Order when MDOT terminology is
  active.
- `projects` already has `mode`, `mdot_contract_id`, `mdot_project_code`,
  `mdot_county`, `mdot_district`, `control_section_id`, `route_street`, and
  `construction_eng`.
- `daily_entries` already has core DWR-like fields: date, weather, temperature,
  activities, safety/SESC/traffic/visitors/extras, signature, completion/review
  workflow, revision number, and soft delete.
- Missing first-class `daily_entries` DWR header fields likely include rainfall
  amount, remote DWR ID, MDOT submission/approval identifiers, payment estimate
  number/status, and official lock state. MDOT 1126 form responses already
  capture `rainfall_events`, but that is not a DWR header column.
- `entry_equipment` exists but does not currently store count on site/count
  used/hours used/idle hours/comments at the APCM granularity.
- `entry_personnel_counts` exists but does not currently store total hours or
  APCM-specific comments.
- `bid_items` and `entry_quantities` cover local pay-item and quantity
  tracking, including measurement/payment text and entry-local non-project item
  scoping.
- There is no first-class material set/material source/sample record model.
  Current supporting evidence can live in pay items, quantities, generic form
  responses, documents, photos, and signature-backed form exports, but those
  are not substitutes for APCM material records.
- Generic `documents` already exist for entry attachments with local/remote
  path, file type, size, notes, and sync support.
- `photos`, `signature_files`, and `signature_audit_log` already provide strong
  attachment/audit primitives. `signature_files.local_path` is nullable locally,
  which supports cross-device signature metadata pulls.
- The sync engine is trigger/change-log based and Supabase-oriented today.
  `SyncRegistry` and `SupabaseSync` are table-name/Supabase-table abstractions.
  AASHTOWare should be added as a separate operation-level adapter/transport
  path with remote IDs/status/ETags; do not bend the Supabase table-adapter
  registry into a hard-coded APCM client.

## Inferred Requirements

These are strong inferences from public docs, but must be validated against
Developer Portal schemas and MDOT sandbox behavior.

### Access and Environment

- Need both AASHTOWare OpenAPI access and MDOT APCM agency-instance access.
- Need at least one non-production MDOT/APCM test instance with safe write
  permissions.
- Need sample contract/project IDs with contract authority for the test users.
- Need role coverage matching the pilot scope, likely including inspector,
  office tech, project engineer/construction engineer, material admin, and
  read-only/contractor scenarios if those workflows are in scope.
- Need a portal-supported path for product API specs and generated SDKs.

### Auth and Secret Handling

- Treat subscription keys as secrets. Store outside source control and redact
  logs.
- Build a pluggable auth provider that can support subscription-key-only demo
  endpoints, OAuth2/OpenID bearer token flows, and any MDOT-confirmed MILogin
  delegation.
- Do not assume user MILogin credentials can be collected by Field Guide.
  Use proper OAuth2/OIDC delegation if MDOT exposes it.
- Token refresh, key rotation, and session expiry must be first-class.

### API Client

- Generate or validate client models from the official OpenAPI spec when
  available.
- Support request IDs/correlation IDs, ETags, rate-limit headers, pagination,
  retry/backoff, and idempotency keys/client transaction IDs where available.
  If APCM does not expose idempotency support, the adapter will need
  client-side replay protection and read-after-write duplicate detection.
- Start with read-only catalog/contract/DWR retrieval before enabling writes.
- Treat `409`, `423`, `401`, `403`, `404`, `429`, and `5xx` responses as
  distinct product states, not a generic sync failure bucket.

### Data Model

- Store remote identifiers separately from local IDs.
- Track remote revision/version/ETag and lock/payment state.
- Track DWR status and approval metadata without collapsing it into Field
  Guide's local review enum.
- Preserve contract line number, project item line number, item ID, category,
  vendor/contractor ID, material code, material source/facility, sample ID,
  payment estimate number, change-order number, and attachment/link IDs.
- Preserve Field Guide calculations and supporting evidence for quantities,
  rather than only pushing final posted quantity.

### Sync

- Keep Field Guide offline-first capture.
- Add a dedicated AASHTOWare outbound queue/adapter layer that can map local
  mutations into APCM operations without coupling Supabase table names to APCM
  endpoints.
- Push idempotently; every outbound write must be replay-safe.
- Pull authoritative lock/revision/payment state before write attempts.
- Do not overwrite an approved/paid/locked DWR. Surface repair instructions.
- Support partial success/multi-status responses for batches.
- Keep attachments and binary upload state separate from DWR/item posting
  metadata.

### Product Workflow

- Treat MDOT mode as an official-contract workflow with stricter validation and
  role/authority constraints.
- Field Guide should probably support at least three modes:
  - Local Agency/Supabase projects.
  - MDOT/APCM official contracts.
  - Non-project private workspace, which must not attempt APCM writes.
- Field Guide may need a "stage package for APCM" path if direct DWR creation
  is not allowed.
- Pay application exports are not equivalent to APCM payment estimates. The
  integration likely needs payment-estimate awareness before any pay-related
  write support.

## Blocked Questions

### Developer Portal / AASHTO

- Which API product exposes AASHTOWare Project Construction & Materials data?
- Is the public AASHTOWare Project AMS Lab enough for early client proving, or
  is APCM access separate?
- Which endpoints are available for contracts, contract project items, DWRs,
  item postings, materials, attachments, change orders, and payment estimates?
- Which operations are read-only versus create/update/submit/approve?
- Are generated SDKs available, and are they licensed for repo use?
- What are exact auth schemes per API product?
- Are both `Ocp-Apim-Subscription-Key` and bearer tokens required for
  production APIs?
- What are exact rate limits for the subscribed product tier and MDOT instance?
- What are exact pagination/filtering conventions for APCM endpoints?
- What are terms for storing internal notes from portal docs?

### MDOT

- Is Field Guide expected to become a direct APCM system-of-record writer, or a
  field capture/staging tool used by MDOT staff to review/import/attach?
- Does MDOT permit a third-party/mobile companion app to create or submit DWRs
  directly, or only attach, stage, export, or import reviewed data?
- Which agency instance path should be used for MDOT sandbox and production?
- What non-production environment can be used without touching production
  contracts?
- Which test contract IDs, project IDs, contract line numbers, material sets,
  users, and roles can be used?
- What contract authority is required for external/mobile integrations?
- Is MILogin part of external API auth, or only APCM UI auth?
- Which DWR fields and item posting fields are required by MDOT configuration?
- What exact DWR status values and transitions are configured?
- What lock rules apply to DWRs included in payment estimates?
- What attachment limits, antivirus, MIME, ProjectWise URN, and ACL flags apply?
- Which materials/sample record workflows are required for initial integration?
- Which payment estimate and change-order states must Field Guide read to warn
  about overrun, insufficient materials, or locked records?

### Field Guide Product Decisions

- Should first release be read-only contract/pay-item import, DWR write, or
  staged export package?
- Should we support material sample records in-app, or only material posting
  metadata on DWR item postings?
- Should APCM approval actions ever be exposed in Field Guide, or should Field
  Guide stop at draft/submit and leave approvals in APCM?
- How should conflict repair be presented when APCM locks or rejects a write?
- Should current pay application features be linked to APCM estimate awareness
  only, or integrated with estimate creation/adjustment later?

## Access Checklist For The User / Business Owner

These tasks cannot be completed by implementation code alone.
They are access assumptions derived from public onboarding/workflow docs and
must be confirmed by MDOT/AASHTO.

1. Identify the integration owner at MDOT and the AASHTOWare/OpenAPI contact.
2. Create or verify the required AASHTOWare Store, Developer Portal, and, if
   confirmed by AASHTO/MDOT, AASHTO Identity account using the proper
   organizational email.
3. Determine whether Field Guide will access OpenAPI as an AASHTO member agency
   partner, Data Alliance member, non-member Basic/Enhanced/Premium licensee, or
   MDOT-sponsored integration.
4. Complete license/subscription steps in the AASHTOWare Store.
5. Obtain Developer Portal access with the product/API subscriptions needed for
   AASHTOWare Project/APCM.
6. Obtain subscription keys and confirm key rotation policy.
7. Request access to a non-production MDOT APCM/OpenAPI environment.
8. Obtain test users and role assignments: inspector, MobileInspector-like sync
   role if needed, office tech, project/construction engineer, material admin,
   and read-only/contractor if in scope.
9. Obtain sample contract/project IDs and explicit permission to write test DWRs,
   item postings, material postings, attachments, and status transitions.
10. Ask MDOT/AASHTO to confirm whether external API auth uses MILogin, AASHTO
    Identity, OAuth2/OpenID, client credentials, service accounts, subscription
    key only for demos, or another delegated model.
11. Ask for API catalog/spec export or portal links for:
    - contracts/projects/categories/contract items,
    - DWRs and daily diaries,
    - contractors, equipment, personnel,
    - item postings,
    - material sets/material postings/sample records,
    - attachments and links,
    - change orders,
    - payment estimates and exceptions,
    - reference/code lists.
12. Ask for MDOT-specific code lists and validation rules:
    weather, remark types, offset types, units, material source/facility,
    acceptance methods, sample types, DWR statuses, estimate statuses,
    change-order types/reasons, role/action permissions.
13. Ask for allowed production rollout model: direct writes, staged review,
    import package, partner app, or MDOT-only approved client.
14. Ask for written guidance on what portal/API docs may be stored internally.

## Research Rules Going Forward

- Public sources may be summarized and linked.
- Do not commit full AASHTOWare/AASHTO PDFs, HTML pages, diagrams, videos,
  generated SDKs, schemas, or gated API docs unless written terms allow it.
- For authenticated material, write concise internal notes with endpoint names,
  operation IDs, schema field names, auth schemes, rate limits, portal links,
  and implementation decisions only where portal/API terms permit internal
  storage of those notes.
- Do not paste long excerpts from proprietary/gated docs into repo files.
- Keep all subscription keys, OAuth client secrets, bearer tokens, refresh
  tokens, screenshots showing secrets, and portal account details out of git.
- MDOT construction PDFs such as the Documentation Guide also include
  reproduction restrictions; store link/metadata/summary only unless permission
  allows more.

## Initial Implementation Direction

This is recommended sequencing, not confirmed AASHTOWare/APCM implementation
guidance.

1. Finish research and external access.
2. Add a read-only OpenAPI lab spike if public/demo API access permits it.
3. Build an internal `aashtoware` integration module only after specs exist.
4. Start with schema-backed mappers and read-only contract/pay-item pull.
5. Add DWR draft/create/update in sandbox after lock and idempotency contracts
   are proven.
6. Add attachments and material postings only after binary upload and material
   source/schema rules are proven.
7. Add submit/approval/payment-estimate-aware behavior last, and only under
   real MDOT sandbox role constraints.
