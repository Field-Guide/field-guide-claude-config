# Plan Index

## PDF Extraction Replay Authority

The current PDF extraction replay authority is
`2026-05-07-delete-normalized-pdf-replay-restore-ocr-call-cache-todo.md`
together with `test/features/pdf/extraction/PDF_HARDENING.md`.

Current closeout status: normalized/no-render replay remains deleted and
forbidden; the only accepted fast replay path is live-equivalent cached Google
Vision OCR-call replay. The 2026-05-09 full pay-item replay at
`tools/testing/test-results/2026-05-09/pdf-extraction-corpus-233413/summary.json`
reached `row_accuracy=0.9584` and `field_accuracy=0.9892` across 14/14
pay-item PDFs, with no missing or unexpected documents. The matching audit at
`tools/testing/test-results/2026-05-09/pdf-extraction-replay-audit-233436-vision_20260509_232313_full_pay_items_replay_final/audit-summary.md`
reported zero asserted mismatches and zero trace-contract failures. This is
still not a 99% per-PDF pass.

Paw Paw S21 live app proof is now complete for the current extraction code:
`tools/testing/test-results/2026-05-09/s21-pawpaw-live-verification-20260509-232037/S21/23-comparison.json`
records a real S21 project import with 58/58 exact rows and 348/348 exact
fields. The persisted app rows contain item numbers 1-58 only, item 24 quantity
25, and no 60/61/800/66291 extras. Unit comparison is storage-equivalent,
because the app persists `Dollars` as `DLR`.

Older PDF corpus/replay plans from 2026-05-05 and 2026-05-06 are archived
under `.codex/plans/completed/` as historical context only. They must not be
used to re-authorize the deleted replay/cache bypass path, compatibility
OCR-cache lookup, or acceptance evidence that skips live PDF
rendering/preprocessing/OCR request construction.

## Active Codex Plans In `.codex/plans/`
- `2026-05-24-sync-repair-dead-letter-architecture-todo.md`:
  Active implementation tracker for GitHub `#337` / Sentry `FLUTTER-1R`.
  It covers review-status ownership fixes, the daily-entry review-reset residue
  repair, permanent sync rejection repair evidence, custom lint guardrails, and
  S21 Grand Blanc real-auth verification/closeout gates.
- `2026-05-23-aashtoware-document-verification-audit-plan.md`:
  Active one-document-at-a-time verification controller for the AASHTOWare
  research package. It tracks each audit wave, requires focused agent research
  for the active document, and keeps edits owned by Codex after checking
  public AASHTOWare/OpenAPI sources, MDOT APCM sources, and current Field Guide
  code.
- `2026-05-23-aashtoware-openapi-integration-readiness-plan.md`:
  Current controlling research/readiness plan for MDOT AASHTOWare Project
  Construction & Materials through AASHTOWare OpenAPI. It supersedes the older
  Claude backlog plan for current work, keeps real API client implementation
  blocked until authenticated Developer Portal/API catalog and MDOT sandbox
  access exist, and orders future work through access, spec intake,
  auth/connectivity, read-only pull, schema-backed data gaps, draft DWR writes,
  item/material/attachment writes, submit/lock awareness, and MDOT-accepted
  pilot proof.
  Companion package docs live in `docs/integrations/aashtoware/`, with source
  inventory and link-only archive policy under
  `docs/integrations/aashtoware/source-documents/`.
- `2026-05-22-non-project-daily-entry-quantities-materials-todo.md`:
  Active to-do spec for restoring `Pay Items Used` / quantities to
  non-project Daily Entries, making non-project manual pay items entry-owned
  through `bid_items.source_entry_id`, keeping project pay-item behavior
  reusable/project-scoped, and ensuring Plain Text IDR `Materials` uses the
  same scoped quantity data as the Company/PDF IDR.
- `2026-05-22-non-project-contractor-location-leakage-todo.md`:
  Active to-do spec for fixing non-project Daily Entry contractor/equipment
  leakage and Activities location leakage. It scopes non-project
  contractor/equipment rows to their owning `sourceEntryId`, keeps project
  contractors reusable with duplicate-name blocking, hides prior non-project
  rows from fresh IDRs without deleting S21 residue, removes non-project
  Activities location UI in both compact and wide/tablet layouts, and requires
  focused repository/editor/widget tests plus S21 real-auth verification.
- `2026-05-21-non-project-plain-text-idr-export-todo.md`:
  Active to-do spec for adding a non-project-only Plain Text IDR export
  option. It keeps project Daily Entry exports on the existing PDF-only flow,
  prompts non-project Daily Entry exports for PDF IDR versus Plain Text IDR,
  builds text output from `IdrPdfData`, substitutes only the IDR artifact in
  bundle/share actions, records `text/plain` history, and requires focused
  formatter/workflow tests plus S21 Grand Blanc office-technician verification.
- `2026-05-21-non-project-idr-selection-preview-location-todo.md`:
  Active follow-up to move non-project IDR format selection from export time to
  Start New Entry, make the editor Preview action render the selected
  Company/PDF or Plain Text output, and strip stale activity location metadata
  from non-project UI/preview/export because non-project entries have no
  location setup path. Requires focused tests plus live S21 verification of
  Plain Text Dated Bundle, Plain Text IDR Only, Company IDR preview, project
  PDF-only behavior, and clean sync/log state.
- `2026-05-21-calculator-ux-redesign-todo.md`:
  Active to-do spec for the calculator UX redesign. It requires a Calculator
  Hub with HMA, Area, Trench Layer, and Regular Calculator families; HMA yield
  and weighback modes using the shared shape engine; a multi-shape Area
  Calculator with SF/SY/CF/CY outputs and diagrams; a Trench Layer Calculator
  with depth validation; a Regular Calculator with history and pay-item result
  handoff; a selected-pay-item-first Daily Entry quantity flow with
  user-authored notes only; low-fidelity wireframes, approved colored mockups,
  Flutter implementation, focused tests, and S21/tablet visual verification.
- `2026-05-21-review-comment-legacy-removal-plan.md`:
  Active implementation checklist for removing the legacy Review Comment
  <-> To-Do bridge. It deletes product access to generated review To-Dos,
  removes `legacy_todo_id` schema/sync coupling, adds self-repair for blocked
  review-comment residue caused by immutable legacy todo links, and preserves
  normal manual To-Do behavior.
- `2026-05-21-review-workflow-redesign-todo.md`:
  Active full-stack to-do spec for the project review workflow redesign. It
  separates inspector draft completion from reviewer review, keeps non-project
  completion outside the review enum, replaces the crowded Review Hub action
  cards with tabbed list rows, moves reviewer comments into read-only
  entry/form section headers, removes the redundant Request Changes action,
  defines project workflow states `draft`, `project_completed`,
  `needs_action`, and `approved`, hardens duplicate approval/comment actions,
  and requires Flutter, SQLite, Supabase/RLS, sync, tests, and S21 Grand Blanc
  verification. No wireframes are part of this spec.
- `2026-05-20-non-project-daily-entry-completion-flow-plan.md`:
  Active implementation checklist for the non-project Daily Entry completion
  flow. It adds a non-project action hub, a `completed` status that stays
  owner-editable and is not reviewable/submitted, fresh-start non-project
  drafts that bypass draft reuse, completed status presentation, full focused
  test coverage, and S21 Grand Blanc office-technician verification. Task/test
  checklist copy belongs in Codex planning/evidence only, not product UI.
- `2026-05-20-sync-status-noise-reduction-todo.md`:
  Active implementation checklist for quieting sync status UI by separating
  background sync states from true user-action-required failures. It reserves
  red UI for repair-required or confirmed persistent failure, normalizes overlap
  and deferred auth as non-failures, treats offline and retryable queue work as
  background states, centralizes sync severity projection, fixes stale refresh
  paths and project-card catalog freshness, and requires focused sync/provider/
  widget tests plus S21 Grand Blanc Test verification only.
- `2026-05-12-sentry-only-support-reporting-todo.md`:
  Active implementation checklist for making Sentry the only user-facing Help
  & Support reporting path, preserving the app-owned form, adding scrubbed
  structured diagnostics, extending Sentry report tags/contexts, and removing
  the active legacy `support_tickets` system after S21 Sentry-to-GitHub
  verification while preserving remote live data.
- `2026-05-11-form-entry-flow-redesign-todo.md`:
  Active planning/design todo for the MDOT 1174R and MDOT 1126 compact form
  entry redesign plus the new Water Main Pressure Test Report built-in form.
  It requires a reviewed static wireframe reference before implementation. The
  matching reference is `2026-05-11-form-entry-flow-wireframes.md` and includes
  S21 portrait plus tablet landscape layouts with current user-facing labels
  and field order; S21 short-entry fields are explicitly two-column, with
  full-width reserved for long text/signature surfaces. Pressure Test Report
  scope includes the copied source PDF
  `assets/templates/forms/water_main_pressure_test_report_source.pdf`, a
  required new fillable AcroForm template, semantic field mapping, allowable
  leakage calculations, result-row editing, and full built-in form
  registration/testing. The plan keeps all entered data editable in-app,
  separates user-facing labels from PDF field mapping, and limits MDOT 0582B
  work to targeted `.0` formatting cleanup for chart and operating
  density/moisture fields.
- `2026-05-10-sync-root-cause-supabase-advisor-evidence-plan.md`:
  Active evidence-first root-cause plan for GitHub issues #315, #316, #318,
  #319, #321, and the 98 Supabase Security Advisor findings. It is the durable
  append target before implementation: preserve S21 reproduction evidence,
  local/remote sync-state snapshots, Supabase RLS/function ACL evidence,
  high-level fix buckets, lint guardrail candidates, and the dirty-queue S21
  full-sync acceptance target of under 2 seconds with real auth, real Supabase,
  real SQLite, UI-triggered sync, clean queue state, and clean screenshots/logs.
- `2026-05-07-delete-normalized-pdf-replay-restore-ocr-call-cache-todo.md`:
  Current controlling PDF extraction hardening checklist. It deletes the
  replay bypass lane, restores live-equivalent cached Google Vision OCR-call
  replay as the only accepted fast replay path, requires exact request
  fingerprints and raw OCR-call cache files, blocks cache files containing
  cached OCR elements or extracted stage output, and sets the acceptance
  target to `>= 0.99` exact row accuracy for every individual pay-item PDF
  before S21 live app verification can claim device accuracy.
- `2026-05-04-daily-entry-export-location-fix-plan.md`:
  Current implementation checklist for Daily Entry export workflow and new-entry
  project-location hydration. It locks export ownership to the three-dot Daily
  Entry action, uses per-project Android document-tree folders remembered on
  device, preserves the toolbar PDF button as preview-only, writes IDR-only and
  dated bundle exports through the selected project folder, keeps Android share
  sheet behavior for single and multi-file sharing, and fixes stale
  project-scoped location provider loads so new entries show the correct
  project locations without opening an existing entry first.
- `2026-04-29-sync-state-premerge-review-fix-todo.md`:
  Current premerge fix checklist for branch `sync-state`, created from the
  multi-agent review. It tracks merge blockers across sync status settling,
  Sentry-backed support reports, draft visibility/RLS, delete follow-up sync,
  foreign draft file cleanup, bid-item unit testing keys, M&P/PDF extraction
  regressions, stale lint guardrails, and the final targeted plus live
  Supabase verification gate. It also records the completed hygiene extraction
  of `maintenance_handler.dart` and `generic_local_datasource.dart`.
- `2026-04-28-live-sync-pull-maintenance-performance-todo.md`:
  Current live-only S21 sync performance spec for reducing Sync Dashboard
  full-sync pull and maintenance time. It locks acceptance to live Supabase,
  real auth, real SQLite, and UI-triggered evidence only; sets pull
  `<= 2300ms` and maintenance `<= 3000ms` budgets; requires empty queues,
  `errors=0`, `rlsDenials=0`, per-table pull timing, maintenance subphase
  timing, run classification, storage orphan-scan details, screenshots, and
  debug-log summaries.
- `2026-04-23-focused-forms-payapp-verification-plan.md`:
  Focused next-step verification spec for UI responsiveness, Daily Entry/IDR,
  MDOT 0582B, MDOT 1174R, MDOT 1126, and pay-app export/artifact proof. It
  freezes broad prerelease reruns, puts all-device UI/UX responsiveness first,
  requires full UI-triggered sync responsiveness timing, full UI fillability
  plus all-cell mapping proof across saved state/preview/export/reopen, and
  narrows the next execution lane to targeted forms, pay-app, sync, and
  saved-export flows only. Phase 0 also requires full `flutter analyze` back
  to zero issues and focused architecture guardrails where structure needs to
  be locked down.
- `2026-04-23-preupdate-full-app-bindings-plan.md`:
  Current pre-update verification completion spec. It upgrades the prerelease
  suite from route-smoke confidence to full app verification by requiring
  top-level forward/backward feature bindings, complete form fixture/mapping
  proof across saved state/PDF preview/export, positive-earned pay-app export
  proof, expanded action probes, fail-closed coverage reporting, and S21 plus
  tablet emulator acceptance evidence.
- `2026-04-21-testing-results-and-ui-flow-standardization-spec.md`:
  Current testing-surface standardization spec. It makes
  `tools/testing/test-results/` the canonical runtime result root, replaces the
  mirror-tree output model with the compact `report.md` / `summary.json` /
  `artifacts.json` contract, documents `.claude` as the single maintained
  AI-agent reference system with `.codex` as alias-only, and promotes
  `ui-flow` to the primary verification lane while keeping `sync-flow` as the
  specialized multi-device stress lane.
- `2026-04-20-unified-routing-state-auth-live-testing-reset-plan.md`:
  Current controlling reset spec for routing, auth, state-machine, driver, and
  four-device live testing. It preserves the original unified routing/state
  direction, locks the decision to stay on Provider and Supabase Auth for this
  cutover, adds the auth research findings, and defines the first canonical
  auth-runtime-state implementation lane.
- `2026-04-20-unified-routing-state-sync-soak-driver-spec.md`:
  Current controlling integration spec for the routing/state/driver/sync-soak
  lane. It consolidates the AutoRoute migration, app-owned route contracts,
  sentinel-key state machine, driver interaction readiness, four-device startup
  proof, and backend-pressure acceptance model. It also defines the
  deprecation path for legacy GoRouter-bound driver assumptions, host-side
  posture derivation, `/driver/ready`-only readiness, and legacy soak
  entrypoints.
- `2026-04-20-autoroute-routing-provider-refactor-todo-spec.md`:
  Child routing/red-screen recovery spec under the unified
  routing/state/sync-soak driver lane. It records the AutoRoute migration
  decision, app-owned navigation boundary, route-access snapshot refactor, and
  vertical-slice work, but device acceptance now follows the unified
  route/state/sentinel contract above.
- `2026-04-19-four-role-sync-hardening-scale-up-spec.md`:
  Scale-up input under the unified routing/state/sync-soak driver lane. It
  remains the source for enterprise sync goals such as concurrent role traffic,
  headless app-sync scale, backend/device overlap, operation-history/checker,
  fault/liveness, staging/performance, operational diagnostics, and the
  consistency contract, but four-device acceptance now requires the unified
  route/state/sentinel startup and interaction gates first.
- `2026-04-08-lint-first-enforcement-plan.md`:
  Lint-first implementation queue for the current beta hardening wave,
  covering route-intent ownership, sync repair scaffolding, integrity
  diagnostics removal, bottom-sheet constraints, and the contract-test follow-up
  matrix.
- `2026-04-11-prerelease-central-tracker.md`:
  Canonical pre-release tracker replacing the old beta central tracker. This is
  now the primary source of truth for gate honesty, custom-lint enforcement,
  forms-first S21 validation, Office Technician / review-comment verification,
  pre-release blockers, CodeMunch structural debt, and final evidence gates.
- `2026-04-12-prerelease-final-canonical-tracker.md`:
  Concise current prerelease closeout tracker. Latest state: Google Cloud
  Vision OCR is live behind Supabase Edge Function/company opt-in, full OCR
  readiness passes, `codex-admin-sql` was deleted remotely, and the next active
  lane is PDF corpus hardening plus final tracker reconciliation.
- `2026-04-08-beta-research-inventory.md`:
  Durable Notion + CodeMunch audit artifact backing the central beta tracker,
  including current blocker reconciliation, routing audit results, and
  god-sized file inventory.
- `2026-04-08-codemunch-beta-audit-reference.md`:
  Standing CodeMunch-backed beta reference capturing the Notion export path,
  validated green slices, and the current god-sized decomposition queue.
- `2026-04-08-beta-testing-notes-spec.md`:
  Comprehensive implementation spec for the latest beta testing notes,
  including root-cause classification, contract-test backlog, lint-first
  candidates, and execution order across state ownership, forms, 0582B, trash,
  and resume/restoration issues.
- `2026-04-08-sync-status-merge-resolution-plan.md`:
  Product-direction and implementation plan for keeping `/sync/dashboard` as
  the single user-facing sync status surface while pushing raw diagnostics and
  merge tooling behind internal/debug seams.
- `2026-04-09-export-artifact-contract-plan.md`:
  Export-contract unification plan covering forms, daily entries, and pay
  applications without flattening their attachment and bundling differences.
- `2026-04-09-form-fidelity-standardization-spec.md`:
  Active spec for form export fidelity, shared section-based workflow shells,
  forms gallery restructuring, and the staged 1174R rollout.
- `2026-04-10-0582b-preview-sync-recovery-plan.md`:
  Active repair checklist for the reported 0582B preview/mapping gaps, shared
  PDF preview/navigation fixes, Samsung sync/background recovery proof, and the
  crash-safe resume checkpoint for removing runtime mock auth, re-verifying the
  Samsung device on a real-auth build, and tracking reopened live-device TODOs
  such as the inspector calendar create-project regression and pending
  project-backed 0582B validation.
- `2026-04-10-form-fidelity-device-validation-spec.md`:
  Controlling closure spec for the original-AcroForm fidelity lane, read-only
  preview separation, 0582B standards relocation/remapping, and the required
  two-pass real-auth Samsung verification across 0582B, 1174R, SESC 1126, and
  Daily Entries/IDR.
- `2026-04-10-form-workflow-regression-plan.md`:
  Active reopened regression tracker for the latest 0582B original/recheck
  numbering and double-text proof, SESC 1126 workflow/export/signature/discard
  issues, project-list local hydration, and 1174R performance/header/row-entry
  standardization work.
- `2026-04-11-pay-app-form-final-verification-plan.md`:
  Canonical implementation spec for the current pay-app/form-filler completion
  lane, including the G703-style running ledger workbook, compact pay-app
  dialog repair, form numeric keyboard progression, contractor comparison
  parity fixtures, final all-form fidelity verification, and the required
  self-review plus completeness-agent closeout gate.
- `2026-04-11-pay-app-form-contractor-review-final-verification-spec.md`:
  Current continuation spec for the pay-app e2e, contractor-comparison
  performance/order repair, all-cell AcroForm verification, and appended
  role/comment/photo/calculator TODOs.
- `2026-04-11-final-s21-verification-adaptive-idr-plan.md`:
  Current canonical final S21 completion plan for inspector contractor/equipment
  access, editable adaptive IDR direction, all-form all-cell verification,
  pay-app/contractor comparison closure, and final device evidence. Latest
  addendum: Daily Entry/IDR equipment-row proof requires at least five realistic
  equipment records per active Springfield contractor before acceptance.
- `2026-04-13-pay-app-export-tablet-analytics-spec.md`:
  Current working spec for the pay-app export UI, previous pay-app copy export,
  analytics pay-app/item drilldown, tablet daily-entry/quantities/projects
  layout repairs, quantity calculator styling, and S21 verification checklist.
- `2026-04-13-google-assisted-ocr-provider-plan.md`:
  Active research-backed plan for the Google Assisted OCR provider bakeoff,
  preserving two company-facing pipelines while comparing Vision image OCR,
  Vision raw-PDF OCR, Document AI Enterprise Document OCR, Form Parser, and
  Layout Parser against the prerelease/Springfield gates.
- `2026-04-13-google-assisted-ocr-fast-iteration-spec.md`:
  To-do style implementation spec for the Google Assisted OCR fast iteration
  loop, including the 8-pair Michigan corpus target, MDOT/AASHTOWare stress
  inputs, OCR-cache replay runner, cleanup policy, and final S10 verification
  gate.
- `2026-04-14-gocr-stage-trace-ground-truth-spec.md`:
  Controlling GOCR diagnostics and ground-truth discipline spec. Current
  direction: harden the baseline-plus-MDOT GOCR replay through exact
  comparison and single-endpoint traces. Latest focused MDOT state:
  `mdot_2026_04_03_estqua-pay-items` is at `675/677`; item-number pattern
  failures are resolved; the next implementation queue is the remaining
  `Traf Regulator Control` row collapse, the `Maintenance Gravel` row collapse,
  then a full original-baseline plus MDOT zero-regression replay.
- `2026-04-15-extraction-pipeline-decomposition-trace-spec.md`:
  Active verification gate before further MDOT heuristic iteration. Decompose
  the upstream PDF extraction pipeline in behavior-preserving slices while
  threading the existing `StageTrace`/debug system through every new substage
  with structured inputs, outputs, decisions, mutations, and provenance.
- `2026-04-15-pdf-extraction-heuristic-testing-standard.md`:
  Standing post-decomposition testing and iteration standard for PDF extraction
  heuristic changes, including the current original-four/full-corpus replay
  baselines, all manifest PDFs, canonical replay commands, artifact
  requirements, no-regression gates, and acceptance rules. Durable tracked copy
  lives at `docs/testing/pdf-extraction-heuristic-testing-standard.md`; the
  condensed agent rule lives at
  `.claude/rules/pdf/pdf-extraction-testing.md`.
- `2026-04-15-pdf-extraction-post-decomposition-todo.md`:
  Active to-do style tracker for the post-decomposition extraction iteration
  loop. Current evidence: fresh original-four replay reproduced the Berrien
  `16` mismatch baseline, fresh full-corpus replay reproduced `427` asserted
  mismatches plus `2` trace-contract failures, compact replay audit output now
  lands under `tools/testing/test-results/<date>/`, and the most upstream
  confirmed first-bad stage is `text_recognition` via `ocr_source_error`.
  Priority 0 is now source/provider/rendering: prove a Vision table-region OCR
  route against the current full-page Vision cache before adding more
  downstream canonicalization. Existing notes show the previously tested
  Document AI processor underperformed Vision image OCR on Berrien/Huron/Grand
  Blanc, so Document AI is not the next retry unless a new processor/config
  hypothesis is defined.
- `2026-04-16-pdf-extraction-post-100-decomposition-trace-todo.md`:
  Active post-100% structural hardening tracker for the PDF extraction
  pipeline. It preserves the zero-mismatch/zero-trace-contract baseline while
  splitting new post-processing heuristics, row-data parsing, provenance, and
  test counterparts away from god-class/god-test shapes.
- `2026-04-16-external-pdf-heldout-validation.md`:
  Held-out first-try validation record for three PDFs outside the original
  four-plus-eight training corpus: Baraga municipal bid form, MDOT ESTQ&A
  schedule, and MDOT bid tab. Latest Windows Google capture and cache replay
  both ran `ocr_only` and passed count/item-number structural checks with zero
  expected failures, but native-text proxy evidence is explicitly not accepted
  as field-level truth. Current artifacts include rendered visual review pages,
  OCR candidate review ledgers, raw-to-final mutation CSVs, and S21
  `/sdcard/Download/FieldGuide_HeldOut_OCR_20260416/` device staging.
- `2026-04-16-heldout-ocr-generalization-hardening-spec.md`:
  To-do style follow-on spec for hardening OCR generalization after the first
  three held-out PDFs. It locks those three PDFs as baseline, expands the next
  iteration set to nine additional PDFs across the same three layout families,
  keeps exact no-normalization visual comparison as the acceptance rule, and
  tracks raw visual token preservation, confidence/auto-accept fidelity gaps,
  trace-token audits, app-level S21 verification, and the final baseline retry.
- `2026-04-16-android-codemagic-firebase-cicd-plan.md`:
  Active Android CI/CD setup plan for using GitHub release tags as the
  controlled beta switch, Codemagic as the single build/distribution system,
  Firebase App Distribution as the Android TestFlight equivalent, and
  `field-guide-beta-v<version>+<build>` as the shared iOS/Android beta label.
- `2026-04-16-manual-ui-rls-testing-checklist-plan.md`:
  Corrective checklist for the UI E2E feature-harness refactor, replacing
  route-only runner passes with manually driven S21/S10 bug-discovery sweeps,
  organized test-result artifacts, debug-log/sync review, and first-class
  RLS/role-boundary coverage.
- `2026-04-17-sync-system-hardening-implementation-checklist.md`:
  Codex working checklist for the seven-phase sync hardening and harness plan,
  deriving actionable gates from
  `.claude/plans/2026-04-16-sync-system-hardening-and-harness.md` and the
  controlling spec.
- `2026-04-17-sync-system-hardening-remaining-work.md`:
  Final handoff tracker for the sync hardening plan after implementation and
  commit split, covering historical Phase 7 staging, observability,
  CI-history, and pre-alpha tag gates. Nightly soak and backend/RLS soak
  automation are retired.
- `2026-04-17-sync-hardening-ui-rls-closeout-todo-spec.md`:
  Comprehensive to-do style closeout spec combining sync hardening remaining
  work with S21/S10 manual UI, role-boundary, RLS, sync-state, staging, and
  release-gate defects from the April 16-17 test artifacts.
- `2026-04-17-gocr-integration-branch-verification-remaining-work.md`:
  Branch-level verification closeout tracker for `gocr-integration`, capturing
  historical hard blockers found after reviewing UI E2E, sync/auth hardening,
  Android Codemagic/Firebase, staging, and GitHub CI evidence. Current policy
  retires backend fixture shortcuts and backend/RLS soak as maintained tooling;
  use live backend/device verification instead. Current S21/S10 one-device UI sync and the
  S21+S10 local device-lab wrapper passed on 2026-04-17 after fixing harness
  seed residue, fresh-backlog circuit breaker behavior, bounded full-sync push
  draining, and previous-user consent residue. Remaining work is GitHub run
  proof after push, staging schema/perf proof, expanded UI-driven device
  mutations, and beta-tag distribution proof.
- `2026-04-17-enterprise-sync-soak-hardening-spec.md`:
  Historical implementation spec from the retired soak lane. Keep it only as
  provenance for why backend-only pressure was rejected as device-sync proof.
  Current work should use live backend/device verification, real local
  `change_log` writes, file/storage bytes, role revocation, auth switching,
  realtime dirty scopes, failure injection, and complete triage artifacts.
- `2026-04-17-sync-soak-ui-rls-implementation-todo.md`:
  Historical implementation checklist for the two April 17 sync specs. Current
  policy retires its backend/RLS soak and nightly automation paths; retain the
  device-facing findings only. The device-lab runner captures per-device
  UI-sync artifacts without
  `POST /driver/sync`, best-effort debug-log snippets and actor context
  snapshots are captured for local device-lab actors, driver change-log
  diagnostics now group blocked rows by table/operation/retry
  count/project/error, and the lab runner has optional true UI daily-entry
  activity mutation, host-side failure-injection, and Supabase Storage
  object-proof inputs. The S21 refactored `combined` gate is now green through
  daily-entry, quantity, and photo sequential mutate/sync/cleanup phases, S21
  `contractors-only` now proves the contractor/personnel/equipment graph, S10
  refactored regression is green through isolated daily-entry, quantity,
  photo, contractor, combined, and MDOT 1126 typed-signature flows, and S21
  `cleanup-only` live replay is green against accepted combined, contractor,
  and MDOT signature ledgers. The MDOT 1126 typed-signature and expanded
  fields/rows form-backed lanes are accepted on S21. The MDOT 0582B
  form-response mutation lane is also accepted on S21; export/storage proof for
  MDOT 0582B remains open. The MDOT 1174R lane is implemented/wired but not
  accepted; latest S21 diagnostics are blocked on compact workflow
  section/body proof while opening Quantities after QA edits, with cleanup and
  final queue drain proven.
  Remaining work starts with accepting MDOT 1174R, builtin form exports,
  saved-form/gallery lifecycles, S10 regression for newly accepted form lanes,
  role churn, broader storage/failure modes on S21/S10, staging proof, and
  backend actors running concurrently with device actors. Latest
  hardening: MDOT signature cleanup now fails closed on missing
  or mismatched storage `remotePath`, local database v61 makes
  `signature_files.local_path` nullable to match Supabase so cross-device
  signature metadata can pull, and S21 post-v61 signature backlog sync-only
  proof is green. MDOT 1126 expanded fields/rows are now S21-accepted through
  `20260418-s21-mdot1126-expanded-after-signature-ready-or-nav`, covering
  rainfall, SESC measures/status/corrective action, remarks, typed signature,
  storage proof, ledger cleanup, storage absence, and final empty queue.
- `2026-04-17-s21-soak-harness-audit-and-recovery-plan.md`:
  Focused pause-and-recover plan after repeated S21 all-modes failures. It
  audits the 2026-04-17 device-lab failure groups, records that the current
  monolithic soak script is too long and too generic for acceptance work, and
  defines the S21-first path: strict fail-loud harness gates, flow-level
  artifacts, mutation ledger/cleanup proof, single-flow S21 gates, then only
  later S10 and scale-up. The latest addendum audits the existing app-side HTTP
  driver server and host debug log server and records the no-third-server
  decision: the refactor should build thin client/orchestrator modules around
  the existing driver/debug surfaces, startup scripts, sync measurement script,
  and Dart soak/harness models. The scale-up model is S21 + S10 real-device
  proof, optional emulator if stable, headless app-sync actors for 10-20 app
  users, and backend/RLS virtual actors for remote pressure. Latest progress:
  the module split is live under `tools/testing/flows/sync/`; the S21 `sync-only`,
  `daily-entry-only`, `quantity-only`, and `photo-only` state-machine paths are
  green as isolated single-flow gates; quantity and photo both use
  ledger-owned cleanup with UI-triggered cleanup sync; and photo now proves
  storage object download, delete, and absence against Supabase Storage.
  Cleanup hardening attempts ledger-owned restore/delete after post-mutation
  failures before recording a failed round, and the harness has reusable state
  sentinels for exact local/remote cleanup proof. Three-pass S21 confidence is
  now closed for `quantity-only` and `photo-only`; the refactored S21
  `combined` gate is green through the new module; S10 refactored regression is
  now green through the implemented flows; S21 cleanup-only replay is green
  against accepted ledgers; MDOT 1126 typed-signature form proof is green on
  S21, cleanup-only replay, and S10; and MDOT 1126 expanded fields/rows are
  green on S21. The MDOT 0582B mutation gate is now green on S21, with
  export/storage proof still open. The MDOT 1174R flow is wired and has live
  non-acceptance diagnostics. Current hardening moved the expanded-section
  sentinel onto the mounted body, made driver text entry visible/editable-only,
  removed the section-body `AnimatedSize`, kept repeated-row composer state
  alive while mounted, and added `Scrollable.ensureVisible` to the driver
  scroll route. That scroll-route patch is not accepted yet:
  `20260418-s21-mdot1174r-after-ensure-visible-scroll` failed loudly on a red
  screen during `mdot1174r-fields-and-rows` with duplicate GlobalKey/detached
  render-object runtime errors and local `form_responses` queue residue. The
  next mutation gate is recovering S21 through UI-triggered sync only, then
  fixing MDOT 1174R row-section key/state ownership before another S21
  acceptance attempt. After 1174R acceptance, continue to form exports and
  saved form/gallery lifecycles. The legacy all-modes runner is not a
  substitute.
- `2026-04-18-sync-soak-spec-audit-agent-task-list.md`:
  Current audit/task-list addendum mapping the remaining sync-soak and UI/RLS
  spec intent into parallel implementation-agent lanes. S10 regression, S21
  cleanup replay, and the first MDOT 1126 typed-signature form/signature lane
  are now artifact-backed; signature integrity-drift root cause is fixed in
  local schema v61 and S21 post-v61 backlog drain proof is artifact-backed,
  while S10 post-v61 cross-device proof remains open. MDOT 1126 expanded
  fields/rows and the MDOT 0582B mutation lane are accepted on S21; MDOT 1174R
  is implemented/wired but awaiting S21 acceptance after compact section/body
  and row-section state failures. Latest status: `visible-text-only` failed
  cleanly on Air/Slump scroll visibility and the follow-up
  `after-ensure-visible-scroll` failed loudly on duplicate GlobalKey/detached
  render-object runtime errors with queue residue. S21 was recovered afterward
  through the refactored Sync Dashboard `sync-only` flow and the live queue was
  empty. Current architectural guardrail work added custom lints for mounted
  form-section sentinels and for banning animated form body wrappers around
  keyed editable content. Next form-backed work is accepting MDOT 1174R,
  exports/gallery, role/account sweeps, storage/failure expansion, S10
  regression for newly accepted form lanes, and release/staging/scale gates.
- `reports/2026-04-18-enterprise-sync-soak-result-index.md` and
  `reports/2026-04-18-enterprise-sync-soak-result-index.json`:
  Compact human/machine audit of the 2026-04-18 enterprise sync-soak raw
  artifacts before cleanup. The index covers 55 runs, 15 passes, 40 failures,
  the MDOT 1174R red-screen/runtime failure, and the UI-only recovery run that
  drained the S21 queue.
- `reports/2026-04-18-all-test-results-result-index.md` and
  `reports/2026-04-18-all-test-results-result-index.json`:
  Full raw test-results audit before pruning. The index covers 165 runs, 76
  passes, 89 failures, and records every distinct failure class that must stay
  on the regression checklist. After this index was written, duplicate ignored
  raw output under the former `.claude/test-results/2026-04-18/` tree, local
  build caches, debug APKs, and exact generated S21 Download artifacts were
  cleaned. Tracked historical
  evidence remains; S10 app data/Downloads were not bulk-cleared.
- `2026-04-18-mdot-1126-typed-signature-sync-soak-plan.md`:
  Active implementation plan for the MDOT 1126 typed-signature sync-soak lane.
  It defines the isolated `mdot1126-signature-only` refactored flow, report
  attached form creation, local `change_log` proof for `form_responses`,
  `signature_files`, and `signature_audit_log`, signature storage download,
  ledger-owned cleanup, cleanup-only replay readiness, and the S21/S10
  acceptance sequence before role, RLS, failure-injection, staging, and scale
  expansion. Latest evidence: S21 isolated MDOT 1126, S21 cleanup-only replay
  of the accepted MDOT ledger, S10 isolated MDOT 1126, and S21 MDOT 1126
  expanded fields/rows and MDOT 0582B form-response mutation lanes are green.
  The next form-backed lane is accepting the already-wired MDOT 1174R flow,
  then builtin form exports and saved-form/gallery lifecycle sweeps.
- `2026-04-18-sync-engine-external-hardening-todo.md`:
  External sync-engine review addendum translating the PowerSync/Electric/
  WatermelonDB/RxDB/CouchDB/Syncable and local-first survey findings into a
  Field Guide hardening todo list. Current decision: do not replace the custom
  sync engine before the current release gates; run a bounded PowerSync spike
  later, with likely near-term adoption focused on checkpoints, scoped
  reconciliation, attachment queues, idempotent replay, and consistency
  contract documentation.
- `2026-04-18-sync-soak-unified-hardening-todo.md`:
  Current controlling unified sync-soak hardening checklist. It consolidates
  the April 18 MDOT 1126, sync-engine external hardening, sync-soak audit
  task-list, and compact result-index evidence into one ordered todo. It keeps
  the release path on the current custom sync engine, treats PowerSync/Jepsen
  as reusable hardening references rather than migration requirements, starts
  with S10 post-v61 signature proof and MDOT 1174R S21 acceptance, then moves
  through form exports/gallery, role/RLS/failure/staging, and 15-20 actor
  scale-up.
- `2026-04-18-sync-soak-decomposition-todo-spec.md`:
  Structural debt companion for the sync-soak hardening lane. It audits the
  full soak/device-lab surface, including the 1,922-line
  the legacy device-lab flow surface, the largest `tools/testing/flows/sync/Flow.*`
  modules, and the 998-line Dart `soak_driver.dart`, then orders
  behavior-preserving extraction into device-lab dispatch, shared flow runtime,
  mutation targets, cleanup/ledger helpers, storage proof, form-flow helpers,
  focused self-tests, and later 15-20 actor orchestration.

## Active Codex Research In `.codex/research/`

- `2026-05-23-aashtoware-openapi-research.md`:
  Durable public-source research memo for MDOT AASHTOWare Project Construction
  & Materials through AASHTOWare OpenAPI. It captures source inventory,
  confirmed facts, inferred requirements, portal/API catalog limitations, auth
  and URL/header conventions, repo readiness, access checklist, and blocked
  questions requiring AASHTOWare/MDOT access.
- `2026-04-19-router-red-screen-architecture-research.md`:
  Durable routing-architecture memo for the duplicate-`GlobalKey` / red-screen
  investigation. It captures the failure matrix, rejected partial fixes,
  root-cause hypothesis, current app-wide `go_router` rules, upstream
  `go_router` versus `auto_route` package research, upgrade rationale, and the
  threshold for opening a real `auto_route` migration spike.
- `2026-04-17-sync-soak-gap-research.md`:
  Research and code-audit memo explaining why the clean 12,368-action
  backend/RLS soak does not prove device sync. It records external references
  from Microsoft load-testing docs, Android testing strategy, SQLite WAL,
  Supabase RLS, Supabase Storage RLS, and Supabase Realtime limits, then maps
  those expectations to the current app sync gaps.

## Active Integration Docs

- `docs/integrations/aashtoware/README.md`:
  Navigation root for the AASHTOWare integration research package. It links the
  research memo, readiness plan, requirements tracker, mapping notes, access
  checklist, source-document metadata, and verification controller.
- `docs/integrations/aashtoware/requirements.md`:
  Living requirement tracker for access/licensing, auth, API client boundary,
  data mapping, offline sync, permissions, attachments, auditability, tests, and
  live verification. Requirements are marked `Confirmed`, `Inferred`, or
  `Blocked on Portal/MDOT`.
- `docs/integrations/aashtoware/mdot-mapping.md`:
  Field Guide to MDOT/APCM concept map for contracts, DWRs, item postings,
  materials, attachments, change orders, payment estimates, and current local
  schema gaps.
- `docs/integrations/aashtoware/access-checklist.md`:
  External checklist for MDOT/AASHTO access, legal/storage guidance,
  subscription/product access, sandbox/test data, auth/role/audit model,
  endpoint schemas, and MDOT-approved live proof.
- `docs/integrations/aashtoware/user-startup-checklist.md`:
  Simplified user-facing kickoff checklist for accounts, subscriptions, MDOT
  contacts, sandbox test data, API catalog access, auth/legal confirmations,
  and the secure handoff package needed before implementation can start.
- `docs/integrations/aashtoware/source-documents/README.md`:
  Link-and-summary archive policy for public source metadata. It keeps copied
  PDFs, portal snapshots, gated specs, screenshots, generated SDKs, secrets, and
  raw API payloads out of git unless written storage terms allow them.
- `docs/integrations/aashtoware/source-documents/2026-05-23-public-source-inventory.md`:
  Public-source inventory with retrieval dates, link-only archive posture,
  current/stale source notes, and local-code relevance.
- `docs/integrations/aashtoware/source-documents/2026-05-23-aashtoware-openapi-infrastructure-summary.md`:
  Public OpenAPI infrastructure summary covering gateway posture, Developer
  Portal access, subscription-key samples, agency implementation routing,
  catalog/standardization caveats, and local code-readiness gaps.
- `docs/integrations/aashtoware/source-documents/2026-05-23-mdot-apcm-workflow-summary.md`:
  Public MDOT APCM workflow summary for roles, contracts, DWRs, daily diaries,
  materials, payment estimates, change orders, attachments, links, and audit
  controls. It is workflow evidence, not API endpoint/schema proof.

## Supporting Historical Codex Research In `.codex/research/`

- `2026-04-13-aashtoware-pay-item-alignment.md`:
  Historical supporting research for aligning Field Guide pay-item concepts
  with AASHTOWare terminology. Use it only as background; the 2026-05-23
  research/readiness package is the current source for integration planning.

## Active Codex Checkpoints In `.codex/checkpoints/`

- `2026-04-19-four-role-sync-hardening-scale-up-checkpoint.md`:
  Active checkpoint for the consolidated four-role sync hardening scale-up
  lane. Use this going forward instead of appending remaining-work notes to the
  older unified live task list or 5,000-line implementation log.
- `2026-04-17-sync-soak-implementation-checkpoints.md`:
  Append-only checkpoint log for the enterprise sync soak and UI/RLS closeout
  implementation. Use this for slice-by-slice notes about what was found, what
  changed, what was verified, and what must stay open while the specs remain
  the actual verification gates.
- `2026-04-18-sync-soak-unified-implementation-log.md`:
  Append-only implementation log for the unified sync-soak hardening todo.
  Use it to record each implementation/verification slice, exact artifacts,
  test evidence, checklist items closed, and any external-tool reuse candidates
  accepted or rejected.

## Archived Codex Plans

Older Codex-authored plans and handoffs now live under
`.codex/plans/completed/` so the active folder stays focused on the live
tracker plus its supporting research artifact.

## Active Upstream Plans In `.claude/plans/`

- `2026-02-28-password-reset-token-hash-fix.md`:
  Current auth/password-recovery follow-up.
- `2026-02-22-testing-strategy-overhaul.md`:
  Open testing strategy blocker.
- `2026-02-22-project-based-architecture-plan.md`:
  Deployed architecture baseline and source of current multi-tenant rules.
- `2026-02-27-password-reset-deep-linking.md`:
  Prior password-reset implementation baseline.

## Codex Planning Policy

- Store new Codex-authored plans in `.codex/plans/`.
- Use `YYYY-MM-DD-<topic>-plan.md`.
- Reference existing `.claude/plans/` work from this index instead of
  duplicating it unless a Codex-specific addendum is needed.
- Keep `.claude/` as the deep reference library, not the default planning home
  for new Codex-authored plans.

## Historical Noise To Avoid

- `.claude/backlogged-plans/AASHTOWARE_Implementation_Plan.md`
  is historical-only background for AASHTOWare. Current research/readiness work
  is in `.codex/research/2026-05-23-aashtoware-openapi-research.md`,
  `.codex/plans/2026-05-23-aashtoware-openapi-integration-readiness-plan.md`,
  `.codex/plans/2026-05-23-aashtoware-document-verification-audit-plan.md`,
  `docs/integrations/aashtoware/README.md`, and
  `docs/integrations/aashtoware/source-documents/README.md`.
- `.claude/plans/completed/*`
- `.claude/backlogged-plans/*`

Load those only when a task depends on historical design rationale.
