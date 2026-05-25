# AASHTOWare OpenAPI Integration Readiness Plan

Date: 2026-05-23
Owner: Codex research package
Target: MDOT AASHTOWare Project Construction & Materials (APCM) through
AASHTOWare OpenAPI
Status: research/readiness only. Real API client implementation is blocked
until authorized Developer Portal/API catalog access, product/API subscription
access, and MDOT sandbox access exist.

## Scope

This plan replaces reliance on the older
`.claude/backlogged-plans/AASHTOWARE_Implementation_Plan.md` for current work.
That file predates this research package and is historical, non-controlling
background only.

The current objective is to prepare Field Guide for a future APCM integration:

- preserve and use the verified public infrastructure and workflow research
  package,
- identify access/licensing/auth tasks that the user/business owner must
  complete,
- map existing Field Guide data to likely APCM concepts,
- define implementation gates that prevent invented endpoints or schemas,
- keep gated/proprietary API material out of git unless terms allow it.

The gates below are recommended readiness sequencing for Field Guide. They are
not confirmed AASHTOWare/APCM implementation instructions. Public MDOT APCM
workflow pages describe UI/business behavior; they do not prove that matching
OpenAPI endpoints, schemas, write permissions, or MDOT subscriptions exist.

## Non-Goals

- Do not write production API calls without official specs.
- Do not invent endpoint names, request bodies, response schemas, enum values,
  pagination rules, rate limits, or write semantics.
- Do not store subscription keys, tokens, portal screenshots, API catalog page
  copies, full gated docs, complete OpenAPI specs, or generated SDKs unless
  redistribution terms explicitly allow it.
- Do not collect or proxy user MILogin credentials directly.
- Do not write to production or official MDOT contracts until MDOT explicitly
  approves the rollout model and target records.
- Do not make Field Guide payment applications equivalent to APCM payment
  estimates.
- Do not expose APCM approval/rejection/revision, payment-estimate
  creation/approval, or change-order creation/approval actions before MDOT
  confirms role authority, workflow permission, and product scope.

## Controlling Documents

- Research memo:
  `.codex/research/2026-05-23-aashtoware-openapi-research.md`
- Integration overview:
  `docs/integrations/aashtoware/README.md`
- Requirements tracker:
  `docs/integrations/aashtoware/requirements.md`
- MDOT mapping:
  `docs/integrations/aashtoware/mdot-mapping.md`
- External access checklist:
  `docs/integrations/aashtoware/access-checklist.md`
- Source-document archive metadata:
  `docs/integrations/aashtoware/source-documents/README.md`
- Public source inventory:
  `docs/integrations/aashtoware/source-documents/2026-05-23-public-source-inventory.md`
- OpenAPI infrastructure summary:
  `docs/integrations/aashtoware/source-documents/2026-05-23-aashtoware-openapi-infrastructure-summary.md`
- MDOT APCM workflow summary:
  `docs/integrations/aashtoware/source-documents/2026-05-23-mdot-apcm-workflow-summary.md`
- Historical background only:
  `.claude/backlogged-plans/AASHTOWARE_Implementation_Plan.md`

## Verified Baseline

Checked on 2026-05-23:

- AASHTOWare OpenAPI is a gateway/API-management platform. Public DOT
  configuration material says product API implementations are deployed to
  agency AASHTOWare assets, registered with OpenAPI, and routed through the
  gateway; OpenAPI does not host normal agency data or product implementations.
- Public agency configuration dependencies include implementation package
  deployment, root URL registration, AASHTOWare/OpenAPI coordination, and
  firewall allowance from the AASHTOWare OpenAPI gateway public IP
  `20.85.141.79`. MDOT's subscribed APCM API alias, instance value, environment
  URLs, and production/sandbox routing remain unverified.
- Public Getting Started material confirms Store account/Developer Portal
  sign-in, license ordering, subscription activation, Profile/Subscriptions API
  key generation, and a demo ping using `Ocp-Apim-Subscription-Key`. It does
  not publicly confirm APCM product auth scopes, OAuth flows, bearer-token
  requirements, or MDOT tenant behavior.
- Use the FY 2027 AASHTOWare catalog as the forward-looking catalog for
  licensing/capacity planning. FY 2026 remains the current fiscal-year baseline
  through June 30, 2026 and becomes historical comparison after July 1, 2026.
  Catalog prices and limits are procurement inputs, not implementation
  constants.
- MDOT public APCM pages confirm DWRs, access/roles, change orders, payment
  estimates, materials, attachments/links, and lock/approval concepts. They do
  not confirm OpenAPI endpoint availability or external write authority.
- Current Field Guide code has MDOT mode, AASHTOWare terminology, and project
  fields such as `mdot_contract_id`, but the existing sync engine remains
  Supabase-table oriented. Comments that say MDOT mode syncs to AASHTOWare are
  aspirational; there is no AASHTOWare/APCM OpenAPI client, mapper, transport,
  or outbound operation queue today.
- Existing AASHTOWare references in the PDF extraction pipeline are document
  parsing support for schedules/bid tabs. They are not OpenAPI transport,
  schema, or live APCM integration code.

## Readiness Gates

### Pre-Gate - No-Endpoint Architecture Prep

Allowed before portal/API access, as long as no endpoint names, DTOs, generated
clients, request/response schemas, or write behavior are invented:

- Define the future `aashtoware` module boundary and ownership.
- Identify existing sync/auth/storage modules that must not be coupled to APCM.
- Draft secure-storage, redaction, feature-flag, and operation-queue design
  notes using placeholder names only.
- Inventory current data gaps against public workflow concepts, clearly marked
  as inferred until authenticated schemas confirm them.

Exit criteria:

- Architecture notes are explicitly non-implementation and contain no
  fabricated endpoints, fields, enum values, or schemas.
- Real client, DTO, migration, generated SDK, and API-call work remains blocked
  until Gate 0 and Gate 1 evidence exists.

### Gate 0 - External Access

Required before any real APCM client implementation or sandbox write work:

- MDOT integration owner and AASHTOWare/OpenAPI contact identified.
- Developer Portal account and any AASHTO Identity account required by
  AASHTO/MDOT.
- Legal access path chosen: MDOT-sponsored integration, AASHTO member agency
  partner, Data Alliance/Alliance Program path, or non-member license tier.
- AASHTOWare Store license/subscription activation.
- Exact API product/catalog that exposes AASHTOWare Project/APCM data.
- Product subscription for AASHTOWare Project/APCM APIs, if APCM is exposed as
  a subscribed OpenAPI product for MDOT.
- Subscription keys and rotation policy.
- MDOT sandbox/non-production APCM instance, base URL/path alias, and
  production vs sandbox naming confirmed.
- Confirmation that the agency implementation package/root URL/gateway routing
  are configured for OpenAPI.
- Test users with contract authority for the agreed pilot roles: inspector,
  MobileInspector-like role if needed, office tech, project/construction
  engineer, material admin, and read-only/contractor if in scope.
- Sample contract/project IDs and explicit safe-write targets.
- Written permission for draft DWRs, item postings, material postings,
  attachments/links, and status transitions in sandbox.
- Auth scheme confirmed by AASHTO/MDOT, including whether MILogin is UI-only or
  participates in external API auth.
- Written guidance on what portal/API material can be stored internally:
  OpenAPI specs, generated SDKs, screenshots, sanitized fixtures, schema
  excerpts, and concise portal notes.

Exit criteria:

- `docs/integrations/aashtoware/api-catalog-notes.md` exists with concise
  endpoint/auth/schema/rate-limit notes and portal links.
- Every readiness decision cites the evidence type: public source, portal
  catalog, MDOT confirmation, successful authenticated request, or sandbox UI
  proof.
- No secrets or gated docs are committed.

### Gate 1 - Spec Intake and Schema Notebook

Tasks:

- Review authenticated API catalog for contract, DWR, item posting, materials,
  attachments, change orders, payment estimates, payment estimate exceptions,
  daily diaries, contractors/equipment/personnel, categories/project items, and
  code/reference-list endpoints.
- Record operation IDs, read/write capability, required fields, remote
  identifiers, revisions/ETags, lock states, role/action permissions,
  pagination, filtering, errors, and rate limits.
- Classify each operation as read-only, create, update, submit,
  approve/reject/revise, delete/void, or explicitly unavailable. Do not infer
  endpoint support from public MDOT UI workflow pages.
- Decide whether specs, generated SDKs, screenshots, fixtures, and schema
  extracts can be stored or must remain external.
- Create sanitized fixtures only if terms allow it.

Exit criteria:

- Endpoint families and schemas are documented, or externally linked with
  approved concise notes, enough to implement mappers without committing
  prohibited material.
- Legal storage decision is recorded.
- Field Guide data gaps are confirmed against real schemas.

### Gate 2 - Architecture Spike

Tasks:

- Design an isolated `aashtoware` integration module.
- Keep it separate from Supabase table adapters.
- Treat existing `ProjectMode.mdot` comments as intent only; do not assume an
  existing transport path.
- Prove APCM writes do not enter the existing `change_log`, `SyncRegistry`,
  `TableAdapter`, or `SupabaseSync` table-adapter path.
- Define auth provider interface for subscription key, bearer token, and future
  delegated auth.
- Define outbound operation queue shape with idempotency, dependency ordering,
  request IDs, retries, and sanitized errors.
- Define remote-state tables/fields for IDs, revision/ETag, lock/payment state,
  and last verified timestamps.
- Define named secure-storage keys, logout/key-clear behavior, and log/support
  redaction tests for subscription keys, bearer tokens, request IDs, and
  correlation IDs.
- Define feature/config gating so APCM code cannot run for non-MDOT projects,
  non-project private workspaces, or unbound MDOT projects.
- Define fallback architecture for staged export/review/import if MDOT does not
  allow direct API writes.
- Preserve repo testing guardrails: no `MOCK_AUTH`, no test-only hooks, and real
  production seams for auth/sync verification.

Exit criteria:

- Architecture notes identify exact files/modules to add.
- Architecture notes identify existing sync files/modules protected from APCM
  coupling.
- No API endpoint implementation is merged unless backed by authenticated spec.

### Gate 3 - Auth and Connectivity Lab

Tasks:

- Implement a minimal authenticated ping, catalog, status, or other
  MDOT/AASHTO-approved call using real sandbox access.
- Confirm required headers and auth material: subscription key, bearer token,
  `X-Request-Id`, API version header/query parameter, or product-specific
  equivalents.
- Redact keys/tokens from logs and support reports.
- Capture request ID, response correlation identifiers, rate-limit headers, and
  latency where the subscribed API exposes them.
- Exercise token/key expiry, key rotation, wrong instance/path, missing
  contract authority, and forbidden-role behavior if possible.
- Distinguish the public `awdemo/ping` connectivity check from any authenticated
  MDOT/APCM product call.
- Do not collect or proxy MILogin credentials.

Exit criteria:

- Real gateway call succeeds in sandbox.
- Failure states for missing key, bad token, forbidden role, and rate limit are
  distinguishable.
- Evidence is stored without secrets.

### Gate 4 - Read-Only Contract Pull

Tasks:

- Pull contract/project metadata.
- Pull contract items/pay items.
- Pull contractors/vendors if exposed by the authenticated schema.
- Pull DWR list and one DWR detail.
- Pull relevant code/reference lists.
- Pull payment estimate, payment lock, and change-order state needed to block
  unsafe writes.
- Discover daily diary read behavior if exposed.
- Store remote IDs and read-only state without altering local project behavior.
- If authenticated catalog review shows APCM endpoints are absent or read-only
  for our subscription, stop this direct-client path and document the approved
  fallback: staged export/import, attachment-only, or reviewed handoff.

Exit criteria:

- Field Guide can bind a local MDOT project to an APCM sandbox contract.
- Read-only imported data is traceable to request IDs and remote revisions.
- Pagination, filtering, and revision/ETag handling are proven for the pulled
  endpoint families.
- Mapper tests cover contract/pay-item/reference parsing.

### Gate 5 - Data Model Gap Patch

Only after schema confirmation, add missing local fields/models such as:

- DWR remote ID/status/revision/ETag/lock/payment estimate state. Current
  `daily_entries.revision_number` is a local workflow revision and must not be
  treated as an APCM remote version token.
- Official DWR status values, entered/approved metadata, approver identifiers,
  and payment estimate number/status.
- Rainfall amount and APCM weather/code-list values.
- Contractor/equipment/personnel APCM row IDs and granular hours/counts.
- Item posting remote IDs, contract line IDs, material set IDs, measured/interim
  flags, station/offset/location fields, plan sheet references.
- Contract/project item IDs, category IDs, change-order number/status, material
  source/facility IDs, sample IDs, and test IDs where schemas require them.
- Material set/source/sample/test models if approved.
- Attachment/link remote IDs, upload status, remote version/ETag, checksum, and
  parent association fields.
- Remote error/rejection state, server validation messages, retry/repair
  status, and last attempted operation metadata for APCM operations.
- Pay-application to APCM payment-estimate awareness fields only if MDOT wants
  Field Guide to display estimate state. Existing `pay_applications` stores
  local application totals and export linkage, not APCM estimate line lifecycle.
- Signature evidence handling must account for the current local mismatch where
  SQLite allows nullable `signature_files.local_path` for remote pulls while the
  Dart model still treats the field as required.

Exit criteria:

- Migrations are schema-backed.
- Migrations are not inferred from public MDOT UI/workflow docs alone.
- Existing non-MDOT and Supabase sync behavior remains unchanged.
- Focused repository and mapper tests pass.

### Gate 6 - Draft DWR Write in Sandbox

Only if authenticated APCM schemas and MDOT permissions explicitly support DWR
draft writes from Field Guide:

Tasks:

- Enter only after MDOT approves sandbox write permission for the chosen test
  contract/user.
- Create or update a DWR draft only.
- Include basic header fields and remarks.
- Do not push public MDOT DWR notes as official DWR content.
- Validate required fields against the authenticated schema before create/update.
- Read back server state and persist remote ID/revision/ETag.
- Validate idempotency or approved read-after-write duplicate detection.
- Exercise stale revision and locked-record failure behavior.
- Keep production writes blocked by feature/config flags.

Exit criteria:

- A sandbox draft DWR can be created/updated and read back.
- Duplicate push does not create duplicate official records.
- Local repair state is clear when the server rejects a write.

### Gate 7 - Contractors, Item Postings, and Materials

Only if authenticated schemas and MDOT scope explicitly support these writes:

Tasks:

- Create or associate the required contractor record before item postings,
  according to the authenticated schema.
- Add equipment and personnel where schemas permit.
- Add item postings with contract line, contractor, quantity, location,
  measured/interim flag, material set, plan sheet, and comments.
- Add material posting metadata only if MDOT approves.
- Do not create or mutate material sets unless MDOT approves that workflow;
  public MDOT docs indicate material sets can be created but not deleted.
- Pull server state after write and compare to local projection.

Exit criteria:

- Sandbox item posting writes are idempotent and auditable.
- Material behavior is either implemented with schemas or explicitly deferred.
- Mapper tests cover required-field omissions and validation errors.
- Mapper tests cover units, source/facility, acceptance method, sample IDs, and
  overrun/change-order-related validation where schemas expose them.

### Gate 8 - Attachments and Links

Only if authenticated schemas and MDOT scope explicitly support attachment or
link writes:

Tasks:

- Implement binary upload or link creation according to API schema.
- Keep upload state separate from DWR/item posting metadata.
- Preserve filename, MIME, size, checksum, description, visibility/confidential
  flags, parent ID, remote attachment/link ID, and upload request IDs.
- Confirm ProjectWise URN/link rules, MDOT naming conventions, antivirus/scan
  behavior, retention/records policy, and ACL/visibility fields.
- Support a link-only fallback if binary upload is not permitted.
- Test timeout/retry/read-after-write behavior.

Exit criteria:

- Harmless sandbox attachment uploads and/or links succeed.
- Duplicate retry does not create uncontrolled duplicates.
- Failed uploads can be repaired without corrupting DWR metadata.

### Gate 9 - Submit and Lock Awareness

Only if authenticated schemas and MDOT role permissions explicitly support DWR
submit from Field Guide:

Tasks:

- Submit DWR only when user explicitly chooses submit and role/state permits.
- Do not expose approve/reject/revise unless MDOT explicitly approves that
  Field Guide scope.
- Pull payment estimate and lock state after submit.
- Block local push attempts to approved/paid/locked records.
- Verify current sandbox segregation-of-duty enforcement. Public workflow docs
  say creators cannot approve their own DWRs, while the Wave 1 memo records
  historical OAG audit risk around self-approved DWRs.
- Do not expose payment-estimate creation/approval or change-order actions
  unless separately approved by MDOT.

Exit criteria:

- Submit is proven in sandbox with real role authority.
- Creator-cannot-approve and lock behavior are correctly surfaced.
- Payment-estimate inclusion prevents unsafe mutation attempts.

### Gate 10 - Pilot Verification

Tasks:

- Run MDOT-approved verification script.
- Capture sanitized evidence: Field Guide local state, outbound queue state,
  request IDs, API response summaries, APCM UI confirmation, screenshots, and
  logs.
- Validate cleanup/reset or test-record labeling.
- Confirm support escalation path for each failure class.
- Produce handoff artifacts: runbook, sanitized evidence index,
  support/escalation matrix, configuration/feature-flag notes, secret rotation
  procedure, cleanup/reset procedure, known limitations, and accepted pilot
  scope.

Exit criteria:

- MDOT/AASHTO contact accepts the evidence for the agreed pilot scope.
- Production rollout remains behind explicit configuration and access control.

## Test Strategy

- Schema-backed client/contract tests from official specs or authorized
  sanitized examples.
- Mapper tests for Daily Entry -> DWR, quantities -> item postings, materials,
  attachments, and lock/status projection.
- Retry/idempotency tests for timeout, duplicate push, `409`, `423`, `429`, and
  partial success where the authenticated API uses those states.
- Auth/environment tests for `401`, `403`, `404`, `5xx`, token expiry, wrong
  instance/path, and role without contract authority.
- Secure-storage and support-report redaction tests proving subscription keys,
  bearer tokens, auth headers, and secrets do not leak.
- Role/capability tests for Field Guide roles mapped to MDOT/APCM roles:
  inspector, office tech, project/construction engineer, material admin, and
  read-only/contractor behavior only if those scenarios are in the approved
  integration scope.
- Live sandbox verification with real auth and real APCM state.
- Existing repo rules remain: no `MOCK_AUTH` for auth/sync verification, no
  test-only production hooks, and real behavior over mock-only proof.
- Do not treat local-only tests, fake role state, fixture-only backend state, or
  the historical backend soak that does not exercise the device sync engine as
  APCM integration acceptance evidence.

## Risk Register

| Risk | Mitigation |
| --- | --- |
| Public MDOT workflow pages are mistaken for API proof. | Keep all endpoint/schema/write claims blocked until authenticated catalog or MDOT/AASHTO confirmation. |
| Product APIs expose less write capability than desired. | Keep staged/export/review path as viable fallback. |
| APCM APIs are absent, read-only, differently named, or unavailable under MDOT's subscription. | Add a stop gate after catalog intake and document the approved fallback path before writing code. |
| Auth requires agency-specific delegated identity. | Use pluggable auth provider and do not collect MILogin credentials directly. |
| MDOT MILogin roles do not map directly to OpenAPI auth scopes. | Confirm API identity, scopes, and role claims separately from APCM UI access. |
| MDOT agency implementation/routing is not deployed or gateway-reachable. | Confirm package deployment, root URL registration, gateway IP allowance, sandbox URL, and support owner before client work. |
| API docs cannot be stored in repo. | Store concise internal notes and portal links only. |
| DWR writes can lock official payment records. | Start draft-only, read lock/payment state before writes, leave submit last. |
| Materials/sample workflows are deeper than Field Guide models. | Phase materials after reference import and MDOT-approved scope. |
| Attachments have strict size/MIME/ACL/antivirus rules. | Separate upload state and verify in sandbox before product UI enablement. |
| Rate limits conflict with offline replay bursts. | Queue with backoff, batching only where approved, and per-operation throttle. |
| Existing Supabase sync gets coupled to APCM. | Build a separate AASHTOWare adapter/queue and keep local capture unchanged. |
| Current LWW/Supabase conflict semantics are too weak for APCM state transitions. | Use APCM revisions/ETags/server validation and explicit repair states instead of last-write-wins for official records. |
| Existing code comments imply AASHTOWare sync is already live. | Treat them as intent labels until an authenticated OpenAPI transport and mapper are implemented and verified. |
| Portal/catalog access is delayed or never granted. | Keep work limited to research, access checklist, and non-client architecture notes. |
| MDOT disallows direct writes. | Preserve staged export/review/import as the supported fallback. |
| Legal terms prohibit storing specs, SDKs, screenshots, or fixtures. | Keep authoritative material external and store only approved concise notes plus links. |
| APCM schema or API version changes after implementation. | Generate/validate from authorized specs and keep version/operation IDs in audit logs. |
| MILogin/OIDC delegation is more complex than subscription-key samples. | Use a pluggable auth provider and never collect user MILogin credentials directly. |
| Secrets leak into logs, support reports, or screenshots. | Centralize redaction and review support bundles before sharing. |
| Sandbox records cannot be cleaned up safely. | Use MDOT-approved test labels, cleanup scripts/runbooks, and explicit reset rules. |
| Role or segregation-of-duty behavior differs from public workflow docs. | Verify every role/action in sandbox before enabling UI actions. |

## Immediate Next Actions

1. Identify the MDOT integration owner and AASHTOWare/OpenAPI contact who can
   authorize third-party/mobile companion access.
2. Choose the legal/licensing/sponsorship route for Field Guide access.
3. User/business owner completes the access checklist: account, license/order,
   product subscription, activation, subscription keys, key rotation policy, and
   storage/legal guidance.
4. Obtain written storage/legal guidance before creating repo-held API notes
   beyond approved summaries and links.
5. Confirm with MDOT/AASHTO that APCM OpenAPI support exists for the intended
   scope, including agency implementation deployment, root URL registration,
   gateway/firewall readiness, sandbox URL, sample contract IDs, test users,
   allowed write targets, and API role model.
6. After portal access, create `api-catalog-notes.md` with concise endpoint,
   operation ID, auth, schema, rate-limit, environment, and portal-link notes
   where storage terms permit.
7. Confirm the first read-only verification script and whether direct DWR/item
   posting/material/attachment writes are allowed, read-only, or deferred.
8. Continue only the pre-gate no-endpoint architecture prep until access exists.
   Schema-backed client/mapper work, migrations, real API calls, DTOs,
   generated SDKs, and endpoint constants stay blocked until specs and access
   exist.
