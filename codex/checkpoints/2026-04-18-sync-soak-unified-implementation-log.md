# Sync Soak Unified Implementation Log

Date: 2026-04-18
Status: append-only active log
Controlling checklist:
`.codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`

## How To Use This Log

Append one entry per implementation or verification slice. Each entry should
record:

- what changed;
- why it changed;
- exact tests or live gates run;
- artifact paths;
- what stayed open;
- which checklist items were checked off.

Do not treat code changes as complete without artifact-backed evidence when the
checklist requires live device, storage, sync, role, or scale proof.

## 2026-04-18 - Unified Todo Created

Inputs reviewed:

- `.claude/codex/plans/2026-04-18-mdot-1126-typed-signature-sync-soak-plan.md`
- `.claude/codex/plans/2026-04-18-sync-engine-external-hardening-todo.md`
- `.claude/codex/plans/2026-04-18-sync-soak-spec-audit-agent-task-list.md`
- `.claude/codex/reports/2026-04-18-all-test-results-result-index.json`
- `.claude/codex/reports/2026-04-18-enterprise-sync-soak-result-index.json`

Branch audit:

- Current branch: `gocr-integration`.
- Current HEAD: `022a673a`.
- Recent direction: modular sync-soak harness, strict driver failures,
  signature contract repair, S21 form-flow expansion, cleanup replay,
  result-index preservation, and custom lint guardrails.

Agent/result synthesis:

- Full test index: 165 runs, 76 pass, 89 fail.
- Enterprise sync-soak index: 55 runs, 15 pass, 40 fail.
- Current blocker: MDOT 1174R is implemented/wired but not accepted.
- Latest critical run:
  `20260418-s21-mdot1174r-after-ensure-visible-scroll`.
- Latest critical failure: `runtime_log_error`, duplicate `GlobalKey`,
  detached render object assertions, `runtimeErrors=27`, queue residue.
- Recovery proof exists through
  `20260418-s21-mdot1174r-redscreen-residue-recovery-sync-only`, but recovery
  is not mutation acceptance.

Decision recorded:

- PowerSync is a hardening reference, not a migration target for this release.
- Reuse compatible open-source packages/tooling where possible.
- Treat source-available PowerSync Service/CLI internals as design references
  unless licensing is explicitly cleared.
- Jepsen/Elle-style history, generator, nemesis, and checker patterns should
  shape scale testing; use their tooling directly if practical before building
  custom equivalents.
- Reuse discovery must be practical and dismissible: if a candidate does not
  fit licensing, Flutter/Dart/PowerShell harness constraints, Supabase/RLS
  semantics, or real-device evidence, close it as not worth pursuing.

Files changed:

- Added `.codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`.
- Added `.codex/checkpoints/2026-04-18-sync-soak-unified-implementation-log.md`.
- Updated the unified todo with explicit reuse triage and kill criteria after
  user clarification.
- Updated `.codex/PLAN.md` to index the unified todo and implementation log.

Verification:

- Documentation-only change; no app tests run.
- Verified both new files exist and `.codex/PLAN.md` references them.

Open next:

- Start with S10 post-v61 signature drift proof and MDOT 1174R row-section
  key/state ownership.

## 2026-04-18 - Decomposition slice (plumbing, no device)

Controlling spec: `.codex/plans/2026-04-18-sync-soak-decomposition-todo-spec.md`
Progress tracker: `.codex/checkpoints/2026-04-18-sync-soak-decomposition-progress.md`

What changed:

- **P0 device-lab split.** `tools/enterprise-sync-soak-lab.ps1` 2114 -> 144
  lines. Extracted:
  - `tools/sync-soak/ModuleLoader.ps1` (Flow.*.ps1 dot-source order +
    accepted flow catalog)
  - `tools/sync-soak/ResultIndex.ps1` (Write-SoakReadableResultIndex wrapper)
  - `tools/sync-soak/Environment.ps1` (Import-SoakEnvironmentSecrets)
  - `tools/sync-soak/DeviceLab.Arguments.ps1` (Test-SoakDeviceLabArguments)
  - `tools/sync-soak/DeviceLab.RefactoredDispatcher.ps1`
    (Invoke-SoakRefactoredFlow + ConvertTo-SoakActorSpecList)
  - `tools/sync-soak/DeviceLab.Legacy.ps1` (1794 lines, quarantined pre-
    refactor device-lab monolith; loud Write-Warning on entry)
- **FlowRuntime extraction.** Added `tools/sync-soak/FlowRuntime.ps1` (304
  lines) and converted SyncDashboard, Quantity, Photo, Contractors,
  DailyEntryActivity, Mdot0582B, Mdot1126Signature, Mdot1126Expanded, and
  Mdot1174R (summary only) to use shared preflight/final/summary helpers.
  Removed now-obsolete Complete-SoakMdot0582BSummary,
  Complete-SoakMdot1126SignatureSummary, Complete-SoakMdot1174RSummary.
  Net flow duplication reduction: -127 lines across 9 files.
- **Dart split.** `integration_test/sync/soak/soak_driver.dart` 1064 -> 46
  lines via `part`/`part of` into action mix, models, executors interface,
  runner, driver executor, backend/RLS executor, and personas.
- **Lock-in tooling.** Added `scripts/check_sync_soak_file_sizes.ps1` and
  `tools/sync-soak/size-budget-exceptions.json`. Advisory today, can gate
  CI with `-FailOnBlocked`.
- **Harness.** Updated `tools/test-sync-soak-harness.ps1` dot-source list
  and `$labSource` concatenation so existing flow-wiring greps still assert
  against the new decomposed module surface.

Why:

- Executes the P0 and lock-in slices of the sync-soak decomposition spec.
- Creates the foundation for the remaining extractions (MutationTargets,
  StorageProof, FormFlow) without touching accepted flows until the runtime
  seam is proven.

Exact gates run:

- `pwsh tools/test-sync-soak-harness.ps1` - PASSED (PS 7).
- `pwsh tools/enterprise-sync-soak-lab.ps1 -Flow sync-only
  -PrintS10RegressionRunGuide -Actors S10:4949:inspector:1` - printed 6
  ordered operator commands.
- `pwsh scripts/check_sync_soak_file_sizes.ps1 -FailOnBlocked` - exit 0
  (0 blocked without exception, 5 review-band entries).
- `dart analyze integration_test/sync/soak` - No issues found.
- `dart analyze integration_test test/harness` - No issues found.
- All 11 touched PowerShell files parse clean under PS 7 parser.

Known follow-ups (tracked in the decomposition spec):

- P0 item #4 (summary field structural test) still pending.
- P1 MutationTargets, ChangeLogAssertions, Cleanup split, StorageProof,
  FormFlow, ArtifactWriter split, and harness-self-test split are scheduled
  in `size-budget-exceptions.json` with expiresAfter 2026-06-30.
- Mdot1174R stays blocked for broad refactor until S21 acceptance is fixed.
- No S21/S10 live device run executed: this slice is plumbing-only.
  Per-flow acceptance semantics are preserved via opt-in switches
  (`-RequireActionCount`, `-RejectDirectSync`, `-Strict`) so the next
  accepted device run will still honour the same pass rules per flow.

Checklist items completed in this slice:

- Decomposition spec guardrails section.
- Endpoint definition bullets for module loading, argument normalization,
  environment/secret loading, actor conversion, flow runtime, artifact/
  evidence wrappers (preflight/final/summary), result-index export,
  legacy quarantine.
- Dart soak code split per target shape.
- Advisory line-count reporting + exception file.

Artifacts:

- None (no device run).

## 2026-04-18 - P0 MDOT 1174R, S10 regressions, and responsive shell guardrail

What changed:

- Fixed MDOT 1174R repeated-row key ownership by giving the air/slump, QA, and
  quantity row composers stable composer keys and mounting the shared grid key
  only on the first composer group.
- Hardened repeated-row focus lifecycle by unfocusing before draft commit and
  removing the post-save automatic focus request that could race section
  transitions.
- Hardened driver scroll behavior around detached render objects by checking
  `attached`/`hasSize`, catching stale render-object exceptions, and rechecking
  target visibility after `Scrollable.ensureVisible`.
- Added stable section keys in compact, medium, and wide form workflow layouts
  so section ownership remains explicit across responsive rebuilds.
- Fixed the S10 red screen root cause in `_ResponsiveThemeShell`: the shell now
  always returns a `Theme` wrapper and only varies the theme extension list,
  avoiding breakpoint-driven ancestor shape changes around the router subtree.
- Added the architecture lint `no_conditional_root_shell_child_wrapper` and
  wired it into `architectureRules` so root app shells cannot conditionally
  return their child directly on one branch and a wrapper around that same child
  on another.
- Added sync-soak harness hardening:
  - ADB logcat fallback maps driver ports to Android device ids from
    `adb forward --list`;
  - artifact retention policy `compact-duplicate-failures`;
  - specific classifications for state sentinel, auth/RLS denial,
    reconciliation mismatch, and queue liveness failures.
- Fixed S10 regression flow targeting:
  - MDOT 1126 expanded remarks scroll/section sentinel verification;
  - MDOT 0582B medium embedded scroll target and section-control keys.

Why:

- The active blocker combined duplicate GlobalKey ownership, stale render
  object handling, and responsive ancestor instability. Acceptance required
  the MDOT 1174R mutation lane to pass on S21, then S10 to prove the responsive
  regression surface did not reintroduce red screens or sync residue.
- The responsive-theme fix was added to the checklist as a lintable
  architecture pattern so future root-shell changes connect to the existing
  custom lint testing system instead of relying only on device rediscovery.

Device/transport recovery note:

- A later S21 rerun appeared to be "loading" but was actually a silent driver
  transport issue. Flutter had launched the app, but ADB had not created
  `tcp:4948 -> tcp:4948`; `/driver/ready` refused while the app PID existed.
- Recovery was targeted, not a broad reset:
  - stopped only the stale S21 Flutter/control process tree;
  - removed stale S21 forwards;
  - force-stopped `com.fieldguideapp.inspector`;
  - restarted the S21 endpoint;
  - manually restored `adb -s RFCNC0Y975L forward tcp:4948 tcp:4948`;
  - restarted the debug log server on `3947`;
  - restored `adb reverse tcp:3947 tcp:3947` for S21 and S10;
  - restored S10 `tcp:4949 -> tcp:4949` after discovering device-scoped
    `forward --remove-all` had cleared the S10 host forward too.

Exact live gates run:

- `20260418-s21-mdot1174r-recovery-sync-final-drain` - passed queue drain after
  earlier S21 residue.
- `20260418-s21-mdot1174r-after-repeated-row-focus-hardening` - S21
  `mdot1174r-only` passed with `queueDrainResult=drained`,
  `runtimeErrors=0`, `loggingGaps=0`, `blockedRowCount=0`,
  `unprocessedRowCount=0`, and `directDriverSyncEndpointUsed=false`.
- `20260418-s10-post-v61-signature-cross-device-sync-only` - S10 `sync-only`
  passed after pulling schema v61 signature metadata.
- `20260418-s10-mdot1126-expanded-after-verified-remarks-open` - S10
  `mdot1126-expanded-only` passed with drained queue and zero runtime/logging
  gaps.
- `20260418-s10-mdot0582b-after-medium-layout-key-fix` - S10
  `mdot0582b-only` passed with drained queue and zero runtime/logging gaps.
- `20260418-s10-mdot1174r-redscreen-residue-ui-sync-drain` - S10 `sync-only`
  drained the red-screen residue through the Sync Dashboard.
- `20260418-s10-mdot1174r-after-responsive-theme-stability-fix` - S10
  `mdot1174r-only` passed with drained queue, zero runtime/logging gaps, and
  no direct driver sync.
- `20260418-s21-mdot1174r-post-responsive-theme-stability-fix-rerun` - S21
  post-fix rerun passed with drained queue, zero runtime/logging gaps, and no
  direct driver sync.

Focused non-device verification:

- `dart analyze` on touched Dart driver/form/app-widget/lint files - no
  issues.
- `flutter test test/widget_test.dart -r expanded` - passed.
- `flutter test test/features/forms/presentation/screens/mdot_1174r_form_screen_test.dart test/features/forms/presentation/widgets/form_shared_widgets_test.dart test/core/driver/main_driver_screenshot_boundary_contract_test.dart test/core/driver/root_sentinel_entry_form_widget_test.dart -r expanded` - passed.
- `dart test fg_lint_packages/field_guide_lints/test/architecture/no_conditional_root_shell_child_wrapper_test.dart fg_lint_packages/field_guide_lints/test/architecture/no_animated_size_in_form_workflows_test.dart fg_lint_packages/field_guide_lints/test/architecture/form_workflow_sentinel_contract_sync_test.dart fg_lint_packages/field_guide_lints/test/architecture/screen_registry_contract_sync_test.dart` - passed.
- `dart analyze fg_lint_packages/field_guide_lints/lib/architecture/rules/no_conditional_root_shell_child_wrapper.dart fg_lint_packages/field_guide_lints/lib/architecture/architecture_rules.dart fg_lint_packages/field_guide_lints/test/architecture/no_conditional_root_shell_child_wrapper_test.dart` - no issues.
- `pwsh tools/test-sync-soak-harness.ps1` - passed, 9 test files.

Artifact paths:

- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-mdot1174r-after-repeated-row-focus-hardening/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-post-v61-signature-cross-device-sync-only/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-mdot1126-expanded-after-verified-remarks-open/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-mdot0582b-after-medium-layout-key-fix/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-mdot1174r-redscreen-residue-ui-sync-drain/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-mdot1174r-after-responsive-theme-stability-fix/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-mdot1174r-post-responsive-theme-stability-fix-rerun/`

Checklist items completed:

- P0 harness hygiene, artifact retention, and sharper failure classification.
- P0 post-v61 signature drift proof on S10.
- P0 S21 MDOT 1174R acceptance.
- P1 S10 MDOT 1126 expanded, MDOT 0582B, and MDOT 1174R regressions.
- P1 responsive root shell architecture guardrail.

Open next:

- Builtin form export/storage proof remains open. Current inspection found
  export paths and storage proof helpers, but no accepted export-specific soak
  flow and `form_exports`/`export_artifacts` still need sync/acceptance proof.
- Saved-form/gallery lifecycle sweeps remain open. Create/reopen paths exist,
  but gallery lifecycle soak, production delete/cleanup proof, and absence
  proof are not yet artifact-backed.
- File/storage/attachment hardening remains open beyond photos/signatures.
- Role/account/RLS sweeps, sync-engine correctness hardening, failure
  injection, Jepsen-style histories/checkers, scale model, staging release
  gates, diagnostics/alerts, and consistency docs remain open and must not be
  marked complete without new implementation and artifacts.

## 2026-04-18 - Next-wave working checklist created and preflight captured

Controlling checklist: `.claude/codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`

What changed:

- Logged the remaining hardening surface as an in-session task list anchored to
  the open sections of the unified todo: External Pattern Policy reuse triage;
  P1 Builtin Form Export Proof for MDOT 1126, MDOT 0582B, and MDOT 1174R;
  P1 Saved-Form/Gallery Lifecycle sweep; P1 File/Storage/Attachment hardening;
  P1 Role/Scope/Account/RLS sweeps; P1 Sync Engine Correctness (keyset
  pagination, reconciliation probes, write-checkpoint semantics, idempotent
  replay + crash/restart); all P2 sections (Jepsen workload, failure injection,
  backend/device overlap, staging gates, 15-20 actor scale, diagnostics/alerts,
  consistency contract docs); optional P3 PowerSync eval; and the final
  three-consecutive-green full-system streak.

Why:

- The unified todo is the validation/verification spec. The session checklist
  mirrors every open item 1:1 so nothing can be silently dropped as the next
  implementation slices land.

Preflight captured before the next evidence slice:

- ADB devices: S21 `RFCNC0Y975L` (SM-G996U) and S10 `R52X90378YB` (SM-X920)
  both attached.
- Forwards: S21 `tcp:4948 -> tcp:4948` and S21 auxiliary `tcp:57549 ->
  tcp:38509`; S10 `tcp:4949 -> tcp:4949`.
- Reverses (per device): both S21 and S10 have `tcp:3947 -> tcp:3947` for the
  debug log server.
- S21 `/driver/ready`: `{"ready":true,"screen":"/sync/dashboard"}`.
- S10 `/driver/ready`: `{"ready":true,"screen":"/sync/dashboard"}`.
- S21 `/driver/change-log`: `count=0, unprocessedCount=0, blockedCount=0,
  maxRetryCount=0, circuitBreakerTripped=false, grouped=[]`.
- S10 `/driver/change-log`: `count=0, unprocessedCount=0, blockedCount=0,
  maxRetryCount=0, circuitBreakerTripped=false, grouped=[]`.
- S21 `/driver/sync-status`: `isSyncing=false, pendingCount=0, blockedCount=0,
  unprocessedCount=0, circuitBreakerTripped=false,
  lastSyncTime=2026-04-18T19:31:32.114827Z`.
- S10 `/driver/sync-status`: `isSyncing=false, pendingCount=0, blockedCount=0,
  unprocessedCount=0, circuitBreakerTripped=false,
  lastSyncTime=2026-04-18T19:31:19.705644Z`.

Gate check:

- Devices satisfy the P0 harness-hygiene preconditions for the next mutation or
  export proof run. No transport recovery required this cycle.

Open next:

- Scout the existing export and storage-proof surface in `lib/`, `tools/sync-soak/`,
  and `integration_test/` so the P1 Builtin Form Export Proof flow can reuse the
  existing FormFlow/StorageProof/ArtifactWriter seams instead of forking a new
  harness; then design the MDOT 1126 export flow against that surface.

## 2026-04-18 - Export-family architecture finding and scoped proof contract

What was found:

- `lib/features/sync/adapters/simple_adapters.dart:156-172` configures the
  `form_exports` adapter with `skipPush: true, skipPull: true,
  skipIntegrityCheck: true, isFileAdapter: true,
  storageBucket: 'form-exports'`. Same pattern for `export_artifacts` at
  `:174-189`.
- `lib/features/forms/domain/usecases/export_form_use_case.dart:46-97` drives
  `FormPdfService.saveTempPdf()` which writes bytes to the app's **temporary
  directory** (`lib/features/forms/data/services/form_pdf_service.dart:197-211`
  plus `lib/features/pdf/services/pdf_output_service.dart`). The use case then
  creates local `form_exports` + `export_artifacts` rows whose `file_path` /
  `local_path` columns point at the local temp file.
- `lib/features/sync/engine/sync_engine_tables.dart:198,220-221` lists
  `form_exports` and `export_artifacts` in `localOnlyExportHistoryTables`:
  neither table has `change_log` triggers.
- The remote cleanup/orphan infrastructure still treats the buckets as real:
  `lib/features/sync/engine/storage_cleanup_registry.dart:6-17` maps
  `form_exports <-> form-exports` and `export_artifacts <-> export-artifacts`;
  `lib/features/sync/engine/orphan_scanner.dart:22-32` scans both buckets;
  `test/features/sync/engine/cascade_soft_delete_test.dart` asserts cleanup
  queue entries for both buckets on purge;
  `test/features/sync/engine/delete_propagation_verifier_test.dart:81-196` uses
  `form-exports/test-company/{project}/*.pdf` remote paths.
- No direct `storage.from('form-exports').upload(...)` call exists in `lib/`,
  so whether bytes ever cross the wire in the current code is empirical, not
  derivable from grep.

Scope decision for the MDOT 1126 export proof:

- Honor the Unified Todo's "where applicable" and "where bytes are created"
  qualifiers instead of forcing an inapplicable assertion on a local-only
  family.
- Drive the production UI path (`/forms` saved mode -> tap MDOT 1126 ->
  export decision dialog -> "Export As-Is" or "Attach and Export").
- Assert local `form_exports` and `export_artifacts` rows via `/driver/local-record`
  and `/driver/query-records`.
- Assert the local PDF bytes exist at the recorded `file_path`. A small
  `/driver/local-file-head` endpoint will be added so PowerShell can HEAD the
  file size/hash without an `adb shell run-as` dance.
- Empirically probe Supabase Storage via `tools/sync-soak/StorageProof.ps1` at
  `form-exports/{company}/{project}/{filename}`. Record both outcomes as
  artifact-backed fact: "bytes-at-remote = yes/no". Do not fail the run if
  bytes are absent; do fail if they are present and unauthorized download
  succeeds.
- `change_log` proof applies only to `form_responses` during cleanup (soft
  delete) if the cleanup path touches it; export rows themselves emit no
  change_log entries by design.
- Cleanup is ledger-owned: UI/service soft-delete, prove local row absence,
  prove local file absence, and prove storage absence where bytes were
  previously proven.
- Final queue drain gate applies unchanged.
- The empirical "bytes-at-remote" outcome feeds a P1 sync-engine follow-up:
  if bytes never land remotely, the `skipPush=true` on `form_exports` and
  `export_artifacts` needs an explicit design decision (keep local-only vs
  flip to remote-backed) before the consistency contract doc is written.

Open next:

- Template the flow off `tools/sync-soak/Flow.Mdot1126Signature.ps1` and
  `tools/sync-soak/FormFlow.ps1`; add a driver endpoint `/driver/local-file-head`
  for local-file HEAD proofs; wire into `DeviceLab.RefactoredDispatcher.ps1` so
  `-Flow mdot1126-export-only` runs end-to-end on S21.

## 2026-04-18 - Slice A: /driver/local-file-head endpoint landed

What changed:

- Added `DriverDataSyncRoutes.localFileHead = '/driver/local-file-head'` and
  registered it in `isQueryPath` and `matches`
  (`lib/core/driver/driver_data_sync_routes.dart`).
- Wired `GET /driver/local-file-head` into `DriverDataSyncHandler.handle` and
  added `_handleLocalFileHead` forwarding to the new query-routes part
  (`lib/core/driver/driver_data_sync_handler.dart`).
- Implemented `_handleLocalFileHeadRoute`
  (`lib/core/driver/driver_data_sync_handler_query_routes.dart`). Contract:
  - Allowlisted tables: `form_exports` (column `file_path`) and
    `export_artifacts` (column `local_path`). Any other table returns 400.
  - Requires `table` and `id` query params. Optional `sha256=true` to compute
    a SHA-256 hash of the file bytes.
  - Response: `{exists, table, pathColumn, filePath, size, modifiedMillis,
    sha256}` when the row exists; `{exists:false, reason:'no_path_recorded'|
    'file_missing', ...}` when the row exists but bytes do not.
  - Honors `rejectReleaseOrProfile` like the other driver query routes.
  - Uses sync file I/O (`existsSync`, `statSync`, `readAsBytesSync`) to keep
    `avoid_slow_async_io` lint clean.
- Added `crypto` import to `driver_data_sync_handler.dart` so the part file
  can call `sha256.convert`.
- Extended `test/core/driver/driver_data_sync_routes_test.dart` with:
  - coverage for `matches(localFileHead)`;
  - a new `local-file-head is a local-only query path` test that pins the
    exact URL, verifies it is a query path, and verifies it is neither a
    mutation nor maintenance path.

Why:

- Closes the Unified Todo P1 "storage bytes where bytes are created" gap for
  local-only export families (`form_exports`, `export_artifacts`). The soak
  harness can now HEAD the PDF at the exact path recorded in the row without
  an `adb shell run-as` dance, without exposing an arbitrary filesystem
  primitive, and without reading bytes unless the caller explicitly asks for
  a hash.
- Unblocks the rest of the MDOT 1126 export proof flow (slice B onward):
  PowerShell can now call
  `GET /driver/local-file-head?table=form_exports&id={id}&sha256=true`
  during the assertion phase.

Exact gates run:

- `dart analyze lib/core/driver/driver_data_sync_routes.dart
  lib/core/driver/driver_data_sync_handler.dart
  lib/core/driver/driver_data_sync_handler_query_routes.dart` — no issues.
- `flutter test test/core/driver/driver_data_sync_routes_test.dart -r expanded`
  — 3/3 tests passed.

Known deferrals:

- No on-device integration test in this slice. The endpoint lives inside the
  app process, so verifying the live response requires rebuilding and
  reinstalling the debug app on S21 and S10. That rebuild happens with the
  next flow slice when there is a concrete request to exercise end-to-end.

Open next:

- Slice B: scaffold `tools/sync-soak/Flow.Mdot1126Export.ps1` using
  `Flow.Mdot1126Signature.ps1` as the template, extract export-specific
  navigation/assertion helpers into `FormFlow.ps1`, and wire
  `-Flow mdot1126-export-only` through `DeviceLab.RefactoredDispatcher.ps1`.
- Slice C: on-device acceptance run on S21, then S10 regression after
  rebuilding both devices against the new endpoint.

## 2026-04-18 — Task #3 Slice B: `mdot1126-export-only` flow landed + wired (harness-only, not yet device-accepted)

What:

- Created `tools/sync-soak/Flow.Mdot1126Export.ps1` with the export proof
  contract (~450 lines). Key functions:
  - `Invoke-SoakMdot1126ExportTapAndConfirm`: reopens `/form/<id>`, taps
    `form_export_button`, chooses `form_export_export_as_is_button` on the
    `form_export_decision_dialog`, waits for `form_standalone_export_dialog`,
    and dismisses via `form_standalone_export_not_now_button`, each wrapped
    in `Invoke-SoakStateTransition` with route/boolean sentinels.
  - `Wait-SoakMdot1126ExportRows`: polls `form_exports` by
    `form_response_id` and `export_artifacts` by `source_record_id` via
    `/driver/query-records`; asserts active (non-deleted) rows with matching
    `project_id`, `form_type='mdot_1126'`, `artifact_type='form_pdf'`,
    `file_path` non-empty, `file_size_bytes > 0`, and
    `export_artifacts.local_path == form_exports.file_path`.
  - `Assert-SoakMdot1126ExportLocalFileProof`: calls the Slice A endpoint
    `GET /driver/local-file-head?table=form_exports&id=<id>&sha256=true` and
    pins `exists`, `filePath == file_path`, `size == file_size_bytes`, and
    non-empty `sha256`.
  - `Assert-SoakMdot1126ExportChangeLogSkipped`: negative proof — pulls
    `/driver/change-log?table=form_exports` and `table=export_artifacts`,
    fails loudly if either new row id shows up. This is the direct gate on
    `sync_engine_tables.dart:218-222 localOnlyExportHistoryTables` trigger
    suppression.
  - `Invoke-SoakMdot1126ExportLedgerCleanup`: soft-deletes
    `export_artifacts` then `form_exports` via `/driver/update-record` with
    `{deleted_at, deleted_by, updated_at}`, re-runs the change-log-skip
    assertion post-cleanup, then delegates to
    `Invoke-SoakMdot1126SignatureLedgerCleanup` (with
    `-RequireStorageRemotePath`) for the underlying `form_responses` +
    `signature_files` + `signature_audit_log` cascade. The signature
    cleanup also scrubs the `signatures` storage bucket.
  - `Invoke-SoakMdot1126ExportOnlyRun`: the actor/round runner. Reuses
    `New-SoakActorRunContext`, `Invoke-SoakActorPreflightCapture`
    (`-CountLogcatClearAsLoggingGap`), `Write-SoakActorPreflightFailure`,
    `Invoke-SoakActorFinalCapture`, and
    `Complete-SoakDeviceSummary -RejectDirectSync` from `FlowRuntime.ps1`,
    with the mutation body calling `SignatureCreate` → `SignatureSubmit` →
    `Wait-SoakMdot1126SignatureRows` → UI-driven sync dashboard
    (`Invoke-SoakSyncDashboardFlow`) → `Wait-SoakMdot1126SignatureRemotePath`
    → the new export helpers above. Failure path falls back to
    `Invoke-SoakMdot1126DraftFormCleanup` when the mutation ledger entry
    has not been built yet.
- Added `Get-SoakDriverLocalFileHead` to
  `tools/sync-soak/DriverClient.ps1` as the canonical client wrapper so
  later flows (MDOT 0582B, MDOT 1174R) can reuse the same call shape.
- Wired the new flow through the harness surface:
  - `tools/sync-soak/ModuleLoader.ps1`: added
    `Flow.Mdot1126Export.ps1` to `Get-SoakModuleLoadOrder` (after
    `Flow.Mdot1126Signature.ps1`) and mapped
    `mdot1126-export-only => Invoke-SoakMdot1126ExportOnlyRun` in
    `Get-SoakAcceptedFlowFunctions`.
  - `tools/sync-soak/DeviceLab.RefactoredDispatcher.ps1`: added the
    `mdot1126-export-only` switch case + docstring line.
  - `tools/enterprise-sync-soak-lab.ps1`: added `mdot1126-export-only`
    to the `-Flow` `ValidateSet`.
  - `tools/test-sync-soak-harness.ps1`: added the dot-source for
    `Flow.Mdot1126Export.ps1`.
  - `tools/sync-soak/tests/FlowWiring.Tests.ps1`: added four new
    assertions so any regression in dispatcher wiring, UI marker usage,
    row-proof shape, change-log-skip assertion, or cleanup cascade
    trips the harness self-tests.

Why:

- Task #3 MDOT 1126 builtin form export proof requires a runner that
  demonstrates: (1) the UI-driven export writes `form_exports` +
  `export_artifacts` correctly, (2) the file bytes are truly on disk at
  the path the row claims, (3) neither table emits a `change_log` row
  (trigger skip for `localOnlyExportHistoryTables`), and (4) no remote
  push is issued (adapter `skipPush:true` / `skipPull:true`). This slice
  encodes every one of those gates as hard assertions and fails the
  round on any violation.
- Keeping the flow on the refactored envelope (`FlowRuntime` +
  `RejectDirectSync`) preserves acceptance semantics already earned by
  the other MDOT flows.

Exact gates run:

- PowerShell AST parse on six touched files — clean:
  `Flow.Mdot1126Export.ps1`, `DriverClient.ps1`, `ModuleLoader.ps1`,
  `DeviceLab.RefactoredDispatcher.ps1`,
  `tools/enterprise-sync-soak-lab.ps1`,
  `tests/FlowWiring.Tests.ps1`.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` — 9 test files,
  all assertions green. This includes the new export-flow wiring block
  (`mdot1126-export-only` present in lab entrypoint + dispatcher +
  module loader; new UI keys wired; local-file-head proof present;
  change-log skip assertion present; signature cascade cleanup wired).

Known deferrals:

- No on-device acceptance yet. This slice is harness code only. Slice C
  (next) is the S21 acceptance run + S10 regression. That requires
  rebuilding the debug app on both devices against Slice A's new
  `/driver/local-file-head` route (rebuild has not happened yet) and
  then executing
  `pwsh tools/enterprise-sync-soak-lab.ps1 -Flow mdot1126-export-only`
  against each actor.
- The `FlowWiring.Tests.ps1` assertions are *source-shape* gates, not
  behavioral gates — they prove the keys, function names, and wiring
  strings are present, not that the device-driven flow actually works.
  The behavioral gate is Slice C on real hardware.

Open next:

- Slice C: rebuild S21 + S10 debug app, run
  `mdot1126-export-only` on S21, iterate until green; then S10 regression.
  Capture the timeline + mutation ledger as evidence artifacts in
  `.claude/codex/evidence/`.

## 2026-04-18 — Slice C: MDOT 1126 builtin export proof accepted on S21 and S10

What changed:

- Added the existing `TestingKeys.formStandaloneExportDialog` key to the
  `AppDialog.show` call inside `FormStandaloneExportDialog.show()`. This makes
  the actual dialog root driver-visible instead of relying only on an action
  button.
- Hardened `tools/sync-soak/Flow.Mdot1126Export.ps1` for both valid export
  branches:
  - standalone/unattached forms may show `form_export_decision_dialog`, after
    which the flow taps `form_export_export_as_is_button`;
  - report-attached forms skip that decision by design and go straight to PDF
    generation plus `form_standalone_export_dialog`.
- Preserved the same export acceptance assertions after either branch:
  `form_exports` row, `export_artifacts` row, local file size/hash proof via
  `/driver/local-file-head`, negative `change_log` proof for both local-only
  export tables, ledger-owned cleanup, signature cascade cleanup, UI-triggered
  cleanup sync, and final empty queue.

Why:

- The first S21 export attempt proved the app was correctly taking the
  report-attached export branch. `_prepareResponseForExport()` skips the
  attach/export decision when `response.entryId != null`, and the failure step
  captured 74 PDF log entries after tapping `form_export_button`.
- The flow was too narrow: it always waited for
  `form_export_decision_dialog`, which is only valid for standalone forms. The
  harness now matches production behavior without weakening the downstream
  export-row/file/cleanup gates.

Exact local gates run:

- `dart analyze lib/features/forms/presentation/widgets/form_standalone_export_dialog.dart`
  — no issues.
- `flutter test test/features/forms/presentation/widgets/form_standalone_export_dialog_test.dart -r expanded`
  — passed.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` — passed, 9 test
  files.
- PowerShell AST parse on the touched sync-soak flow/wiring files — clean.

Device rebuilds and hygiene:

- Rebuilt/restarted S21 with
  `pwsh -NoProfile -File tools/start-driver.ps1 -Platform android -DeviceId RFCNC0Y975L -DriverPort 4948 -Timeout 240 -ForceRebuild`.
- Rebuilt/restarted S10 with
  `pwsh -NoProfile -File tools/start-driver.ps1 -Platform android -DeviceId R52X90378YB -DriverPort 4949 -Timeout 240 -ForceRebuild`.
- Restored S21 forwarding after S10 startup cleared the host-side S21 forward.
- S21 pre-run queue was empty.
- S10 had one pre-existing `form_responses` update after pulling the S21
  cleanup; it was recovered through UI `sync-only` before the S10 export
  regression.

Exact live gates run:

- `20260418-s21-mdot1126-export-initial` — failed cleanly with
  `widget_wait_timeout` waiting for `form_export_decision_dialog`; final queue
  drained, `runtimeErrors=0`, `loggingGaps=0`,
  `directDriverSyncEndpointUsed=false`.
- `20260418-s21-mdot1126-export-after-attached-branch-fix` — passed
  `mdot1126-export-only` on S21:
  - `form_exports/1db318cb-07ee-41c2-935f-f5a4f4ee2831`;
  - `export_artifacts/0f446168-6e24-4370-b1ba-6533f1c0b736`;
  - local PDF
    `/data/user/0/com.fieldguideapp.inspector/cache/MDOT_1126_2026-04-18_e8eec8b5.pdf`;
  - file size `363465`;
  - SHA-256
    `5b3e002eabcdbd9eba2798375e4cb7bdae287fdd627163e9518509b5e003d142`;
  - export tables absent from `change_log`;
  - signature storage presence/delete/absence proved for the underlying
    signature object;
  - queue drained, `blockedRowCount=0`, `unprocessedRowCount=0`,
    `maxRetryCount=0`, `runtimeErrors=0`, `loggingGaps=0`,
    `directDriverSyncEndpointUsed=false`.
- `20260418-s10-mdot1126-export-preflight-recovery-sync-only` — passed S10
  UI-only queue recovery before regression.
- `20260418-s10-mdot1126-export-after-attached-branch-fix` — passed
  `mdot1126-export-only` on S10:
  - `form_exports/42b68f47-fa72-414d-9e46-724e6d883db9`;
  - `export_artifacts/eb087db2-ef94-4d36-9fc0-b6738bbac5a9`;
  - local PDF
    `/data/user/0/com.fieldguideapp.inspector/cache/MDOT_1126_2026-04-18_ec75d04c.pdf`;
  - file size `363465`;
  - SHA-256
    `72b002f452d7ba354a0ed91ff2e7851f0966cfc5b236949abab55cd1392d8a0d`;
  - export tables absent from `change_log`;
  - signature storage presence/delete/absence proved for the underlying
    signature object;
  - queue drained, `blockedRowCount=0`, `unprocessedRowCount=0`,
    `maxRetryCount=0`, `runtimeErrors=0`, `loggingGaps=0`,
    `directDriverSyncEndpointUsed=false`.

Artifact paths:

- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-mdot1126-export-initial/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-mdot1126-export-after-attached-branch-fix/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-mdot1126-export-preflight-recovery-sync-only/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-mdot1126-export-after-attached-branch-fix/`

Checklist items completed:

- Immediate Slice C MDOT 1126 export proof through S21 acceptance and S10
  regression.
- P1 Builtin Form Export Proof item for `mdot_1126`.

Open next:

- Generalize/reuse the accepted export proof for `mdot0582b-export-only`.
- Then implement `mdot1174r-export-only`.
- Saved-form/gallery lifecycle remains open after export proof.

## 2026-04-18 — MDOT 0582B builtin export proof accepted on S21 and S10

What changed:

- Added `tools/sync-soak/FormExportFlow.ps1` as the shared local-only builtin
  form export proof helper surface:
  - production export tap/confirm path with optional attach/export decision;
  - paired `form_exports` + `export_artifacts` row proof;
  - `/driver/local-file-head` file size/hash proof;
  - negative `change_log` proof for both local-only export tables;
  - local-only export-row cleanup proof.
- Added `tools/sync-soak/Flow.Mdot0582BExport.ps1`, which reuses the accepted
  MDOT 0582B creation/edit/marker proof, syncs the form response through the
  Sync Dashboard, exports through the production `mdot_hub_pdf_button`, proves
  local export rows and bytes, cleans up the local export rows, then cleans up
  the underlying `form_responses` row through the existing generic
  form-response cleanup.
- Wired `mdot0582b-export-only` through:
  - `tools/enterprise-sync-soak-lab.ps1`;
  - `tools/sync-soak/ModuleLoader.ps1`;
  - `tools/sync-soak/DeviceLab.RefactoredDispatcher.ps1`;
  - `tools/test-sync-soak-harness.ps1`;
  - `tools/sync-soak/tests/FlowWiring.Tests.ps1`.
- Expanded `tools/sync-soak/S10Regression.ps1` and its self-test to include
  the current MDOT S10 gates, including `mdot1126-export-only`,
  `mdot1126-expanded-only`, `mdot0582b-only`, `mdot0582b-export-only`, and
  `mdot1174r-only`.

Why:

- The controlling todo required MDOT 0582B export/storage proof to stay
  separate from the previously accepted MDOT 0582B form-response mutation
  proof.
- Current app semantics for `form_exports` and `export_artifacts` are
  local-only (`skipPush/skipPull`), so the export proof asserts local rows,
  on-device bytes, trigger suppression, and cleanup instead of requiring
  non-existent remote export rows.

Exact local gates run:

- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` — passed, 9 test
  files.
- PowerShell AST parse on `FormExportFlow.ps1`, `Flow.Mdot0582BExport.ps1`,
  `S10Regression.ps1`, dispatcher/module/entrypoint wiring, and updated tests
  — clean.
- `pwsh -NoProfile -File tools/enterprise-sync-soak-lab.ps1 -Flow mdot0582b-export-only -PrintS10RegressionRunGuide -Actors S10:4949:inspector:2`
  — printed the expanded 11-gate S10 command guide.

Exact live gates run:

- `20260418-s21-mdot0582b-export-initial` — passed `mdot0582b-export-only` on
  S21:
  - `form_exports/ad06b8f0-570e-4ca6-85bc-04439a7b56ed`;
  - `export_artifacts/64dad3e0-c590-4ac6-bd0f-a608a9dce4bb`;
  - local PDF
    `/data/user/0/com.fieldguideapp.inspector/cache/MDOT_0582B_2026-04-18_cc97fa4a.pdf`;
  - file size `775864`;
  - SHA-256
    `9ce8fd72ae05a844a2dbd665e2fb1db46d99a76807f462ff46735bea0d9d2495`;
  - export tables absent from `change_log`;
  - queue drained, `blockedRowCount=0`, `unprocessedRowCount=0`,
    `maxRetryCount=0`, `runtimeErrors=0`, `loggingGaps=0`,
    `directDriverSyncEndpointUsed=false`.
- `20260418-s10-mdot0582b-export-initial` — passed `mdot0582b-export-only` on
  S10:
  - `form_exports/b9e3cf93-757e-492c-beb8-7e04acc0d845`;
  - `export_artifacts/b09df381-9f0e-43a9-8c4c-15d6e36f0c82`;
  - local PDF
    `/data/user/0/com.fieldguideapp.inspector/cache/MDOT_0582B_2026-04-18_84b38b4f.pdf`;
  - file size `775865`;
  - SHA-256
    `6b52096ec3cee301e5c6c5e8718479134047e45839663741e2de0ab0d2cf0534`;
  - export tables absent from `change_log`;
  - queue drained, `blockedRowCount=0`, `unprocessedRowCount=0`,
    `maxRetryCount=0`, `runtimeErrors=0`, `loggingGaps=0`,
    `directDriverSyncEndpointUsed=false`.

Artifact paths:

- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-mdot0582b-export-initial/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-mdot0582b-export-initial/`

Checklist items completed:

- P1 Builtin Form Export Proof item for `mdot_0582b`.
- Shared export proof helper extraction for the remaining builtin form export
  lanes.

Open next:

- Implement and accept `mdot1174r-export-only`.
- Then continue saved-form/gallery lifecycle sweeps.

## 2026-04-18 — MDOT 1174R builtin export proof accepted on S21 and S10

What changed:

- Added `tools/sync-soak/Flow.Mdot1174RExport.ps1`, which reuses the accepted
  MDOT 1174R create/open/edit/marker proof, syncs the form response through
  the Sync Dashboard, exports through the production `form_export_button`,
  proves local export rows and bytes through `FormExportFlow.ps1`, cleans up
  the local-only export rows, then cleans up the underlying `form_responses`
  row through the generic form-response cleanup.
- Wired `mdot1174r-export-only` through:
  - `tools/enterprise-sync-soak-lab.ps1`;
  - `tools/sync-soak/ModuleLoader.ps1`;
  - `tools/sync-soak/DeviceLab.RefactoredDispatcher.ps1`;
  - `tools/test-sync-soak-harness.ps1`;
  - `tools/sync-soak/tests/FlowWiring.Tests.ps1`;
  - `tools/sync-soak/S10Regression.ps1`;
  - `tools/sync-soak/tests/S10RegressionGuide.Tests.ps1`.

Why:

- The controlling todo required the MDOT 1174R export proof to complete the
  generic builtin-form export lane after MDOT 1126 and MDOT 0582B were accepted.
- Current app semantics for `form_exports` and `export_artifacts` are
  local-only (`skipPush/skipPull`), so this proof asserts local rows,
  on-device bytes, trigger suppression, and cleanup instead of remote export
  rows or storage objects.

Exact local gates run:

- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` — passed, 9 test
  files.
- PowerShell AST parse on `Flow.Mdot1174RExport.ps1`,
  `S10Regression.ps1`, dispatcher/module/entrypoint wiring, and updated tests
  — clean.

Exact live gates run:

- `20260418-s21-mdot1174r-export-initial` — passed
  `mdot1174r-export-only` on S21:
  - `form_responses/5609da9b-1749-4d71-a061-a7da46f41a45`;
  - `form_exports/bb038620-8bda-4f12-8ff3-12f766d1cd10`;
  - `export_artifacts/e6aa8fa6-5285-458f-af1d-1258b65e12bf`;
  - local PDF
    `/data/user/0/com.fieldguideapp.inspector/cache/MDOT_1174R_2026-04-18_5609da9b.pdf`;
  - file size `75508`;
  - SHA-256
    `cea5eb3ef9cad81bb6c14d784b6f184d40a681e3bdfe439ca15e382eef521c46`;
  - export tables absent from `change_log`;
  - queue drained, `blockedRowCount=0`, `unprocessedRowCount=0`,
    `maxRetryCount=0`, `runtimeErrors=0`, `loggingGaps=0`,
    `directDriverSyncEndpointUsed=false`.
- `20260418-s10-mdot1174r-export-initial` — passed
  `mdot1174r-export-only` on S10:
  - `form_responses/18fb00f6-5fb9-4337-8095-ea591da4e4bb`;
  - `form_exports/e40ff8ed-7ae3-45a1-a719-4115e777c190`;
  - `export_artifacts/a5b86437-0437-47fb-94a0-9b06da0c9232`;
  - local PDF
    `/data/user/0/com.fieldguideapp.inspector/cache/MDOT_1174R_2026-04-18_18fb00f6.pdf`;
  - file size `75508`;
  - SHA-256
    `abad92554598729f225309d4601e005cd6b31106376808bd9509339b0c06b2ce`;
  - export tables absent from `change_log`;
  - queue drained, `blockedRowCount=0`, `unprocessedRowCount=0`,
    `maxRetryCount=0`, `runtimeErrors=0`, `loggingGaps=0`,
    `directDriverSyncEndpointUsed=false`.

Artifact paths:

- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-mdot1174r-export-initial/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-mdot1174r-export-initial/`

Checklist items completed:

- P1 Builtin Form Export Proof item for `mdot_1174r`.
- Generic builtin form export proof for the current local-only
  `form_exports` / `export_artifacts` contract across MDOT 1126, MDOT 0582B,
  and MDOT 1174R.

Open next:

- Saved-form/gallery lifecycle sweeps for MDOT 1126, MDOT 0582B, and
  MDOT 1174R.
- Broader file/storage/attachment hardening remains open because form exports
  are currently local-only and do not yet prove remote storage objects.

## 2026-04-18 - Saved-form/gallery lifecycle accepted on S21 and S10

What changed:

- Added the refactored `form-gallery-lifecycle-only` flow in
  `tools/sync-soak/Flow.FormGalleryLifecycle.ps1`.
- Wired the flow through the lab entrypoint, module loader, refactored
  dispatcher, S10 regression guide, and harness self-tests.
- Hardened the production UI and driver surfaces needed by the lifecycle lane:
  - `/forms?projectId=...` routing for project-scoped gallery entry;
  - post-frame form-gallery document loading to avoid build-time notifier
    mutations;
  - disposed-controller guards for async Sync Dashboard reload/repair paths;
  - explicit saved-response trailing action key while keeping the whole tile
    tappable for normal users;
  - report attached-form delete confirm/cancel keys;
  - driver tap callback dispatch for visible tappable descendants;
  - GoRouter route inspection for pushed `/form/:id` routes;
  - MDOT 0582B expanded-layout `mdot_hub_scroll_view` key.

Why:

- The controlling todo required a production lifecycle proof that creates an
  attached saved form, reopens it from the gallery, edits and saves the same
  response, exercises export, deletes through report UI/service seams, syncs
  through the Sync Dashboard, and proves remote soft delete/absence after
  cleanup.
- The flow keeps the same acceptance envelope as the other refactored soak
  lanes: real sessions, no `MOCK_AUTH`, UI-triggered sync, mutation ledgers,
  final queue drain, and `directDriverSyncEndpointUsed=false`.

Exact local gates run:

- `dart analyze` on the touched Dart driver/router/form/sync files and focused
  tests - no issues.
- `flutter test` on:
  - `test/features/forms/presentation/screens/form_gallery_screen_test.dart`;
  - `test/features/entries/presentation/widgets/entry_forms_section_test.dart`;
  - `test/features/sync/presentation/controllers/sync_dashboard_controller_test.dart`;
  - `test/core/driver/driver_widget_inspector_test.dart`;
  - `test/core/driver/driver_interaction_routes_test.dart`.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` - passed, 9 test
  files.

Diagnostic recovery before final acceptance:

- S21 had failed-run residue
  `form_responses/a8d0b240-86a6-4c34-9fad-fc230b17de9d` with an empty
  `deleted_by`.
- Correct actor context was read through `/diagnostics/actor_context`; the row
  was repaired with real user `d1ca900e-d880-4915-9950-e29ba180b028`.
- `20260418-s21-gallery-lifecycle-residue-userid-fix-sync-only` then passed
  through UI `sync-only` with final empty change-log.

Exact live gates run:

- `20260418-s21-form-gallery-lifecycle-final-build` - passed
  `form-gallery-lifecycle-only` on S21 with `queueDrainResult=drained`,
  `failedActorRounds=0`, `runtimeErrors=0`, `loggingGaps=0`,
  `blockedRowCount=0`, `unprocessedRowCount=0`, `maxRetryCount=0`, and
  `directDriverSyncEndpointUsed=false`.
- `20260418-s10-form-gallery-lifecycle-after-expanded-hub-key` - passed
  `form-gallery-lifecycle-only` on S10 with the same queue, runtime, logging,
  and direct-sync gates.

Accepted S21 ledger IDs:

- `mdot_1126`:
  `form_responses/0daa8349-cc23-4eaa-895e-bbcef8b7e2e7`,
  `form_exports/8486fcf4-1fa9-427e-9e53-70e105a94cab`,
  `export_artifacts/614d8cc7-0da6-4406-aaa4-dedbc1149a12`,
  file size `364015`.
- `mdot_0582b`:
  `form_responses/9685c4a9-ba17-4701-bf25-bc4147870571`,
  `form_exports/11553762-bf4b-4ac1-871e-0f2967f0bdcd`,
  `export_artifacts/47b03535-8b71-4b09-b4e2-a7eeac35dd9a`,
  file size `775864`.
- `mdot_1174r`:
  `form_responses/7a8f2c49-0c4f-4b7d-9ba3-4afb81f2da66`,
  `form_exports/a40effdf-ad6c-4a5a-b2cd-e114aec0c9a7`,
  `export_artifacts/167600f5-8e97-4ca1-88cc-cd617284a922`,
  file size `75508`.

Accepted S10 ledger IDs:

- `mdot_1126`:
  `form_responses/99a2fb1c-38fe-4817-b01d-694d522ade7b`,
  `form_exports/fcd57aed-6cd7-4a63-acf8-bf3ccbd2abab`,
  `export_artifacts/c71c18f2-0b3c-4f59-a642-81935dd80e38`,
  file size `364015`.
- `mdot_0582b`:
  `form_responses/5aed14a2-273d-4e7f-b512-c109b9a8d74f`,
  `form_exports/fa373a7a-c2de-4f6c-9b87-37bf50f03ecd`,
  `export_artifacts/4692fc6f-c7f8-4007-877b-9ada6b9ea317`,
  file size `775864`.
- `mdot_1174r`:
  `form_responses/aac12ea1-6cee-476a-becc-717b99d92d9b`,
  `form_exports/7ba1c210-2289-43fd-8741-50bab02cc13e`,
  `export_artifacts/1a1b8d52-e2c8-4322-ab5f-728d9ba43d8a`,
  file size `75508`.

Artifact paths:

- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-gallery-lifecycle-residue-userid-fix-sync-only/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-form-gallery-lifecycle-final-build/`
- `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-form-gallery-lifecycle-after-expanded-hub-key/`

Checklist items completed:

- P1 Saved-Form And Gallery Lifecycle for MDOT 1126, MDOT 0582B, and
  MDOT 1174R on S21/S10.
- The persistent live task list now records the accepted lifecycle evidence in
  `.codex/checkpoints/2026-04-18-sync-soak-unified-live-task-list.md`.

Open next:

- File/storage/attachment hardening beyond the current local-only form export
  contract.
- Role/account/RLS sweeps.
- Sync-engine correctness hardening.
- P2 workload, failure-injection, staging, scale, diagnostics, and consistency
  docs remain open.

## 2026-04-18 - Resume checkpoint after lifecycle acceptance

What was refreshed:

- Re-read `.codex/AGENTS.md`, `.codex/Context Summary.md`,
  `.codex/PLAN.md`, `.codex/CLAUDE_CONTEXT_BRIDGE.md`, the sync rules, this
  implementation log, the controlling unified todo, and the persistent live
  task list.
- Reviewed the working tree before continuing. Tracked dirty files are limited
  to the unified todo and this implementation log; the visible live task list
  remains intentionally ignored but present at
  `.codex/checkpoints/2026-04-18-sync-soak-unified-live-task-list.md`.

Current accepted state:

- P0 device/harness hygiene, post-v61 signature proof, MDOT 1174R S21
  acceptance, S10 form regressions, responsive root-shell guardrail, builtin
  form export proof, and saved-form/gallery lifecycle proof are recorded as
  accepted in the controlling todo.
- Latest device lifecycle evidence remains:
  `20260418-s21-form-gallery-lifecycle-final-build` and
  `20260418-s10-form-gallery-lifecycle-after-expanded-hub-key`, both with
  drained queues, zero runtime/logging gaps, and
  `directDriverSyncEndpointUsed=false`.

Current open gate:

- The next unchecked P1 lane is File, Storage, And Attachment Hardening. The
  first step is to inventory the production file-backed table families,
  storage buckets, cleanup queues, and existing proof helpers, then implement
  the next smallest evidence-backed hardening slice.

Checklist status:

- Updated the live task list with a new visible "Current Focus - P1 File,
  Storage, And Attachment Hardening" section so the next session can resume
  without inferring state from older export/lifecycle details.

## 2026-04-18 - Sync engine keyset pagination and phase-log hardening

What changed:

- Fixed file sync phase logging so a phase 2 metadata upsert failure is
  reported as "Phase 2 metadata upsert failed" with `failed_phase: 2`,
  `table_name`, `record_id`, and `remote_path` fields instead of the old
  misleading phase 3 bookmark message.
- Replaced production pull pagination with stable keyset pagination ordered by
  `updated_at` and `id`; `SupabaseSync.fetchPage` now uses the
  `updated_at/id` boundary and `limit(pageSize)` rather than range/offset for
  production pulls.
- Added durable pull page checkpoint storage in `sync_metadata` via
  `PullPageCheckpoint`, `readPullPageCheckpoint`, `writePullPageCheckpoint`,
  and `clearPullPageCheckpoint`.
- Updated `PullHandler` to resume from the stored keyset checkpoint and persist
  the checkpoint only after a full page has been applied. Final partial pages
  still rely on the table cursor being advanced after successful completion.
- Updated fake sync support and contract tests to exercise keyset boundaries.

Local evidence:

- `dart analyze lib/features/sync/engine/file_sync_three_phase_workflow.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 16 tests.
- `dart analyze lib/features/sync/engine/sync_metadata_store.dart lib/features/sync/engine/local_sync_store_metadata.dart lib/features/sync/engine/pull_handler.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/pull_handler_contract_test.dart test/features/sync/engine/supabase_sync_contract_test.dart -r expanded`
  passed 79 tests.

Checklist updates:

- Closed the stable keyset/checkpoint pagination item.
- Closed equal-`updated_at` page-boundary and concurrent-remote-insert tests.
- Closed the misleading file-sync phase logging item.
- Recorded restart after a stored full-page keyset checkpoint as covered.

Still open:

- Long-offline pull evidence.
- Crash/restart after a partial final page.
- Per-scope reconciliation, write checkpoint semantics, freshness gating,
  realtime hint/fallback behavior, idempotent replay, crash/restart matrix, and
  domain-specific conflict strategy.
- File/storage/attachment hardening remains the next P1 implementation lane
  after the current local hygiene and device status probes are recorded.

Device hygiene after local sync-engine slice:

- S21 `http://127.0.0.1:4948`: `/driver/ready` returned ready on
  `/sync/dashboard`; `/driver/change-log` returned `count=0`,
  `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`; and
  `/driver/sync-status` returned `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`.
- S10 `http://127.0.0.1:4949`: `/driver/ready` returned ready on
  `/sync/dashboard`; `/driver/change-log` returned `count=0`,
  `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`; and
  `/driver/sync-status` returned `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`.

## 2026-04-18 - Image fixture storage hardening

Inventory outcome:

- Production file-backed families found in adapters/schema/harness: photos
  (`entry-photos`), signature files (`signatures`), documents
  (`entry-documents`), entry exports (`entry-exports`), form exports
  (`form-exports`), export artifacts (`export-artifacts`), and
  pay-application rows that reference export artifacts.
- Existing harness helpers already cover local file head checks and storage
  object proof for accepted photo/signature lanes and local-only form export
  proofs. Entry documents, entry exports, pay-app export storage proof,
  unauthorized storage denial, cross-device preview/download, and broader
  cleanup retry assertions remain open.

What changed:

- Added generated small, normal, large, and GPS-EXIF JPEG fixtures to
  `file_sync_handler_test.dart`.
- Drove those fixtures through both `FileSyncHandler.stripExifGps` and the
  production phase-1 upload path, proving uploaded JPEG bytes remain decodable
  and do not retain GPS EXIF.
- Fixed the GPS stripping implementation: `Image.from(image)` copied the
  source EXIF, including the GPS sub-IFD, before the allowed EXIF directories
  were copied. The workflow now resets EXIF and removes the GPS subdirectory
  and GPS pointer before encoding.

Local evidence:

- `dart analyze lib/features/sync/engine/file_sync_three_phase_workflow.dart test/features/sync/engine/file_sync_handler_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 18 tests.

Checklist updates:

- Closed P1 "Add small, normal, large, and GPS-EXIF image fixtures."

Still open:

- Storage object proof beyond photos/signatures.
- Unauthorized storage access denial for each bucket/path family.
- Cross-device download/preview for uploaded objects.
- Delete/restore/purge storage cleanup queue assertions beyond current local
  export-artifact coverage.
- Durable attachment/file states and crash/retry cases.
- PowerSync attachment-helper reuse triage.

## 2026-04-18 - Storage cleanup queue purge hardening

What changed:

- `GenericLocalDatasource.purgeExpired` now runs in a transaction, loads remote
  storage paths for file-backed rows before deletion, hard-deletes the expired
  rows, then queues storage cleanup with reason `purge`.
- Existing soft-delete and restore behavior remains unchanged: soft-delete
  queues cleanup with reason `soft_delete`, and restore cancels matching
  pending cleanup.
- Added export-artifact datasource coverage that asserts all three paths:
  soft-delete queueing, restore cancellation, and purge queueing before
  hard-delete.

Local evidence:

- `dart analyze lib/shared/datasources/generic_local_datasource.dart test/features/pay_applications/data/datasources/local/export_artifact_local_datasource_test.dart`
  passed with no issues.
- `flutter test test/features/pay_applications/data/datasources/local/export_artifact_local_datasource_test.dart -r expanded`
  passed 4 tests.

Checklist updates:

- Closed P1 "`storage_cleanup_queue` assertions for delete/restore/purge
  paths."

Still open:

- Live storage-object absence proof after cleanup for entry documents, entry
  exports, form exports, and pay-app exports.
- Cleanup retry/failure injection around storage delete failures.

## 2026-04-18 - Long-offline and partial-page pull restart coverage

What changed:

- Added a long-offline pull test that drains 1,005 project rows across 11
  keyset pages and proves the first/last rows, page boundaries, result count,
  and cleared checkpoint.
- Added a pull restart test that simulates an apply-time crash on the second
  row of a partial final page.
- The test proves the last completed full-page checkpoint remains as the
  restart boundary, the already-applied partial-page row can be replayed, the
  missing row is applied on restart, the table cursor advances, and the
  checkpoint is cleared after successful completion.

Local evidence:

- `dart analyze test/features/sync/engine/pull_handler_test.dart` passed with
  no issues.
- `flutter test test/features/sync/engine/pull_handler_test.dart -r expanded`
  passed 21 tests.

Checklist updates:

- Closed P1 "Test long-offline pull."
- Closed P1 "Test restart after partial page."

Still open:

- Per-scope reconciliation, write-checkpoint semantics, freshness gating,
  realtime hint/fallback behavior, idempotent replay, broader crash/restart
  matrix, and domain-specific conflict strategy.

Final local sweep for this session:

- `git diff --check` passed.
- `dart analyze lib/features/sync/engine/file_sync_three_phase_workflow.dart lib/features/sync/engine/sync_metadata_store.dart lib/features/sync/engine/local_sync_store_metadata.dart lib/features/sync/engine/pull_handler.dart lib/features/sync/engine/supabase_sync.dart lib/shared/datasources/generic_local_datasource.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/supabase_sync_contract_test.dart test/features/pay_applications/data/datasources/local/export_artifact_local_datasource_test.dart test/helpers/sync/fake_supabase_sync.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/pull_handler_contract_test.dart test/features/sync/engine/supabase_sync_contract_test.dart test/features/pay_applications/data/datasources/local/export_artifact_local_datasource_test.dart -r expanded`
  passed 103 tests.

Final device hygiene probes:

- S21 `http://127.0.0.1:4948`: `/driver/change-log` returned `count=0`,
  `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`; and
  `/driver/sync-status` returned `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`.
- S10 `http://127.0.0.1:4949`: `/driver/change-log` returned `count=0`,
  `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`; and
  `/driver/sync-status` returned `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`.

## 2026-04-18 - Reconciliation probe primitive and device endpoint proof

What changed:

- Added the read-only debug route
  `/driver/local-reconciliation-snapshot`.
- The route returns local SQLite reconciliation facts for an allowed table:
  selected columns, total row count, hashed row count, bounded limit,
  truncation state, hash scope, stable `id ASC` order, SHA-256 hash, sample
  ids, and sample rows.
- Added `Get-SoakDriverLocalReconciliationSnapshot` to
  `tools/sync-soak/DriverClient.ps1`.
- Added `tools/sync-soak/Reconciliation.ps1` with:
  - canonical JSON and SHA-256 helpers;
  - Supabase REST remote snapshot support;
  - local/remote comparison classification for unavailable remote snapshots,
    truncated snapshots, row-count mismatches, and row-hash mismatches;
  - `New-SoakProjectReconciliationTableSpecs`, covering the required
    project-scope tables from the todo;
  - `Invoke-SoakReconciliationProbe`, which writes a probe artifact.
- Wired the new module into `ModuleLoader.ps1` and the local harness self-test
  runner.
- Added Dart route/handler tests and PowerShell reconciliation tests.

Why:

- The todo requires per-scope reconciliation probes after sync. Queue drain is
  necessary but not enough: a lane also needs artifact-backed row counts,
  stable hashes, local/remote samples, and mismatch classification.
- This slice lands the reusable primitive and proves the app-side endpoint on
  both physical devices. The post-sync flow artifact gate remains open until
  the probe is wired into the accepted flow summaries and required to pass
  local/remote comparison.

Local evidence:

- `dart analyze lib/core/driver/driver_data_sync_handler.dart lib/core/driver/driver_data_sync_handler_query_routes.dart lib/core/driver/driver_data_sync_routes.dart test/core/driver/driver_data_sync_handler_test.dart test/core/driver/driver_data_sync_routes_test.dart`
  passed with no issues.
- `flutter test test/core/driver/driver_data_sync_handler_test.dart test/core/driver/driver_data_sync_routes_test.dart -r expanded`
  passed 10 tests.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 10
  PowerShell harness test files.
- `git diff --check` passed.

Device evidence:

- Rebuilt/restarted S21 with:
  `pwsh -NoProfile -File tools/start-driver.ps1 -Platform android -DeviceId RFCNC0Y975L -DriverPort 4948 -Timeout 180 -ForceRebuild`.
- Rebuilt/restarted S10 with:
  `pwsh -NoProfile -File tools/start-driver.ps1 -Platform android -DeviceId R52X90378YB -DriverPort 4949 -Timeout 180 -ForceRebuild`.
- S21:
  - `/driver/ready` returned ready on `/projects`;
  - `/driver/change-log` returned `count=0`, `unprocessedCount=0`,
    `blockedCount=0`, `maxRetryCount=0`;
  - `/driver/sync-status` returned `isSyncing=false`, `pendingCount=0`,
    `blockedCount=0`, `unprocessedCount=0`,
    `lastSyncTime=2026-04-18T23:38:26.792802Z`;
  - `/driver/local-reconciliation-snapshot?table=projects&limit=100&sampleLimit=3&select=id,updated_at`
    returned `totalCount=7`, `hashedCount=7`, `truncated=false`,
    `hashScope=full`, and row hash
    `a7f5fec5ff4ad0c1019091b4f5388aadc94175bc4152cb36f945a40f3dca4ce5`.
- S10:
  - `/driver/ready` returned ready on `/projects`;
  - `/driver/change-log` returned `count=0`, `unprocessedCount=0`,
    `blockedCount=0`, `maxRetryCount=0`;
  - `/driver/sync-status` returned `isSyncing=false`, `pendingCount=0`,
    `blockedCount=0`, `unprocessedCount=0`,
    `lastSyncTime=2026-04-18T23:38:24.798705Z`;
  - `/driver/local-reconciliation-snapshot?table=projects&limit=100&sampleLimit=3&select=id,updated_at`
    returned `totalCount=6`, `hashedCount=6`, `truncated=false`,
    `hashScope=full`, and row hash
    `490b4159fb71fa06c618e068e17966d5e54d21871a54cb8d760c873d10125aa3`.

Checklist updates:

- Added checked sub-items under the P1 per-scope reconciliation probe item for
  the local driver endpoint, harness comparison primitive, and S21/S10 endpoint
  proof.
- Left the top-level reconciliation item open because accepted post-sync flow
  artifacts do not yet require passing local/remote reconciliation.

Still open:

- Wire `Invoke-SoakReconciliationProbe` into covered post-sync flow artifacts.
- Decide the explicit local-only table handling for current
  `form_exports`/`export_artifacts` semantics before using those tables as a
  remote mismatch gate.
- Run a live post-sync lane with remote reconciliation output and fail the
  lane on count/hash mismatch.

## 2026-04-18 - Duplicate pull replay coverage

What changed:

- Added a focused PullHandler test for duplicate pull page replay and duplicate
  row apply.
- The test pulls a page of projects once, then replays the exact same page
  through a fresh handler against the same local SQLite store.
- The replay must leave exactly one local row per id, return `pulled=0`, report
  no errors, and clear any pull-page checkpoint.

Why:

- The idempotent replay matrix in the controlling todo explicitly calls out
  duplicate pull page replay and duplicate row apply. The keyset pagination
  work covered restart boundaries; this test covers the direct "same remote
  page appears again" replay case.

Local evidence:

- `dart analyze test/features/sync/engine/pull_handler_test.dart` passed with
  no issues.
- `flutter test test/features/sync/engine/pull_handler_test.dart -r expanded`
  passed 22 tests.

Checklist updates:

- Added a checked sub-item under the idempotent replay matrix for duplicate
  pull page replay and duplicate row apply.
- Verified and indexed existing replay evidence for already-absent remote rows:
  `sync_engine_delete_test.dart` covers empty-response soft-delete replay, and
  `supabase_sync_contract_test.dart` covers hard-delete 404/not-found as
  idempotent success.
- Verified and indexed existing storage duplicate evidence:
  `file_sync_handler_test.dart` covers storage 409/already-exists continuing
  to phase 2 metadata upsert.
- Left the top-level replay matrix open because duplicate push, duplicate
  soft-delete, duplicate upload, row-upsert replay, bookmark replay, and other
  classes still need explicit indexed coverage.

Additional local evidence:

- `dart analyze test/features/sync/engine/sync_engine_delete_test.dart test/features/sync/engine/supabase_sync_contract_test.dart test/features/sync/engine/file_sync_handler_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/sync_engine_delete_test.dart test/features/sync/engine/supabase_sync_contract_test.dart test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 44 tests.

Final focused sweep after reconciliation and replay updates:

- `git diff --check` passed.
- `dart analyze lib/core/driver/driver_data_sync_handler.dart lib/core/driver/driver_data_sync_handler_query_routes.dart lib/core/driver/driver_data_sync_routes.dart test/core/driver/driver_data_sync_handler_test.dart test/core/driver/driver_data_sync_routes_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/sync_engine_delete_test.dart test/features/sync/engine/supabase_sync_contract_test.dart test/features/sync/engine/file_sync_handler_test.dart`
  passed with no issues.
- `flutter test test/core/driver/driver_data_sync_handler_test.dart test/core/driver/driver_data_sync_routes_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/sync_engine_delete_test.dart test/features/sync/engine/supabase_sync_contract_test.dart test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 76 tests.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 10
  PowerShell harness test files.

Final device hygiene after the focused sweep:

- S21 `/driver/change-log`: `count=0`, `unprocessedCount=0`,
  `blockedCount=0`, `maxRetryCount=0`; `/driver/sync-status`:
  `isSyncing=false`, `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`, `lastSyncTime=2026-04-18T23:38:26.792802Z`.
- S10 `/driver/change-log`: `count=0`, `unprocessedCount=0`,
  `blockedCount=0`, `maxRetryCount=0`; `/driver/sync-status`:
  `isSyncing=false`, `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`, `lastSyncTime=2026-04-18T23:38:24.798705Z`.

## 2026-04-18 - Post-sync reconciliation gate wired and device-proven

What changed:

- Added the read-only debug route
  `/driver/remote-reconciliation-snapshot`.
- The remote route mirrors the local reconciliation snapshot contract but reads
  through the app's real Supabase device session. This avoids host
  service-role credentials and keeps reconciliation evidence under the same
  real-session/RLS posture as the device flow.
- Normalized timestamp values in reconciliation rows before hashing so local
  SQLite offsets and Supabase UTC strings compare by instant, not by string
  representation.
- Added `excludeDeleted=true` support to local and remote reconciliation
  snapshots.
- Updated `tools/sync-soak/Reconciliation.ps1` so required project-table specs
  compare active row membership by stable `id`/`project_id` hashes.
- Kept `form_exports`, `export_artifacts`, and `entry_exports` in the
  reconciliation artifact, but marked them `comparisonMode=local_only` because
  the current adapters are intentionally `skipPush`/`skipPull` local export
  history tables.
- Added `-RequireReconciliation` and `-ReconciliationProjectIds` to
  `tools/enterprise-sync-soak-lab.ps1`. When enabled, the dispatcher runs
  `Invoke-SoakSummaryReconciliationGate` after the refactored flow and forces
  the summary to fail on any local/remote count/hash mismatch.

Why:

- The previous primitive could produce standalone snapshots, but accepted flow
  summaries did not yet fail on reconciliation mismatch. The unified todo
  requires post-sync local/remote row counts, stable hashes, samples, mismatch
  classification, and an acceptance gate.
- The first full probe intentionally failed on historical remote tombstones,
  which showed the gate was too broad for normal convergence. Active-row
  reconciliation now proves the sync-visible data set while tombstone retention
  and cleanup stay in delete/cleanup-specific gates.

Local evidence:

- `dart analyze lib/core/driver/driver_data_sync_handler.dart lib/core/driver/driver_data_sync_handler_query_routes.dart lib/core/driver/driver_data_sync_routes.dart test/core/driver/driver_data_sync_handler_test.dart test/core/driver/driver_data_sync_routes_test.dart`
  passed with no issues.
- `flutter test test/core/driver/driver_data_sync_handler_test.dart test/core/driver/driver_data_sync_routes_test.dart -r expanded`
  passed 13 tests.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 10
  PowerShell harness test files.
- `git diff --check` passed before the final doc update.

Device and artifact evidence:

- Rebuilt/restarted S21 and S10 driver apps so the running devices included
  `/driver/remote-reconciliation-snapshot` and the `excludeDeleted` query
  parameter.
- Direct S21/S10 project probes for
  `/driver/remote-reconciliation-snapshot?table=projects&whereColumn=id&whereValue=75ae3283-d4b2-4035-ba2f-7b4adb018199&select=id,updated_at`
  returned `authMode=device_session`, matching row count/hash, and full,
  non-truncated samples.
- `20260418-s21-sync-only-reconciliation-gate` failed as intended on
  reconciliation while all queue/runtime/logging/direct-sync gates were clean:
  `queueDrainResult=drained`, `runtimeErrors=0`, `loggingGaps=0`,
  `blockedRowCount=0`, `unprocessedRowCount=0`, `maxRetryCount=0`,
  `directDriverSyncEndpointUsed=false`, `reconciliationFailedCount=6`.
  The failure was caused by remote soft-deleted tombstones and timestamp/hash
  comparison strictness, proving the gate can fail an otherwise clean flow.
- After the active-row reconciliation contract landed, S21
  `20260418-s21-sync-only-active-reconciliation-gate-rerun` passed:
  `queueDrainResult=drained`, `runtimeErrors=0`, `loggingGaps=0`,
  `blockedRowCount=0`, `unprocessedRowCount=0`, `maxRetryCount=0`,
  `directDriverSyncEndpointUsed=false`, `reconciliationProjectCount=1`,
  `reconciliationTableCount=13`, and `reconciliationFailedCount=0`.
- The accepted reconciliation artifact covered:
  `projects`, `project_assignments`, `daily_entries`, `entry_quantities`,
  `photos`, `form_responses`, `signature_files`, `signature_audit_log`,
  `documents`, `pay_applications`, plus local-only `form_exports`,
  `export_artifacts`, and `entry_exports`.

Device hygiene after proof:

- S21 `/driver/change-log`: `count=0`, `unprocessedCount=0`,
  `blockedCount=0`, `maxRetryCount=0`; `/driver/sync-status`:
  `isSyncing=false`, `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:19:41.161132Z`.
- S10 `/driver/change-log`: `count=0`, `unprocessedCount=0`,
  `blockedCount=0`, `maxRetryCount=0`; `/driver/sync-status`:
  `isSyncing=false`, `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:18:47.159255Z`.

Checklist updates:

- Closed the P1 per-scope reconciliation probe item and the minimum required
  table-membership sub-item in the controlling todo.
- Updated the persistent live task list with the green S21 gate and preserved
  the earlier failed reconciliation gate as negative evidence.

Still open:

- Write-checkpoint semantics, sync freshness gating, realtime hint fallback
  proof, remaining idempotent replay classes, broader crash/restart cases,
  domain-specific conflict strategy, file/storage/attachment expansion,
  role/RLS sweeps, and all P2/P3 scale/staging/diagnostics/docs gates.

## 2026-04-18 - Idempotent replay matrix continuation started

Resume point:

- The accepted S21 active-row reconciliation gate remains the latest device
  proof for the sync-correctness lane.
- The next active P1 slice is the remaining idempotent replay matrix:
  duplicate local push after remote upsert succeeds, duplicate soft-delete
  push, duplicate upload, row-upsert replay, and bookmark replay.
- Existing indexed coverage already covers duplicate pull page replay,
  duplicate row apply, already-absent remote row replay, hard-delete
  not-found replay, and storage 409/already-exists replay.

Planned evidence before checking off the matrix:

- Focused Dart analyzer coverage for touched sync/file tests and helpers.
- Focused Flutter test coverage for the replay matrix files.
- `git diff --check`.
- S21/S10 driver hygiene probes when the running debug drivers are reachable.

## 2026-04-18 - Idempotent replay matrix completed locally

What changed:

- Added explicit PushHandler replay coverage for duplicate local push after a
  remote upsert succeeds. The test replays the pending change after the first
  successful push and proves the second idempotent upsert is processed cleanly.
- Added explicit PushHandler replay coverage for duplicate soft-delete push.
  The first push returns a tombstone row and the replay returns an empty
  response, matching the "remote already gone" path; both finish without queue
  residue.
- Added FileSyncHandler coverage for duplicate upload replay after storage
  already has the object. A 409-style `uploadFile=false` result proceeds to
  metadata upsert and bookmarks the local `remote_path`.
- Added FileSyncHandler coverage for row-upsert replay when local metadata
  already has `remote_path` but the local file is gone. The replay skips
  upload, re-upserts metadata, and leaves the bookmark stable.
- Added LocalSyncStore coverage for bookmark replay. Calling
  `bookmarkRemotePath` twice with the same object path stays idempotent,
  restores trigger state, and does not create `change_log` rows.

Local evidence:

- `dart analyze test/features/sync/engine/push_handler_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/sync_engine_delete_test.dart test/features/sync/engine/supabase_sync_contract_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/push_handler_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/sync_engine_delete_test.dart test/features/sync/engine/supabase_sync_contract_test.dart -r expanded`
  passed 118 tests.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/ready`: ready on `/sync/dashboard`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:19:41.161132Z`.
- S10 `/driver/ready`: ready on `/projects`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:18:47.159255Z`.

Checklist updates:

- Closed the remaining idempotent replay matrix under P1 Sync Engine
  Correctness Hardening.

Still open:

- Write-checkpoint semantics, sync freshness gating, realtime hint fallback
  proof, crash/restart tests, domain-specific conflict strategy,
  file/storage/attachment expansion, role/RLS sweeps, and all P2/P3
  scale/staging/diagnostics/docs gates.

## 2026-04-18 - Write-checkpoint freshness guard started

What changed:

- Added a `SyncEngine` freshness proof before `last_sync_time` is written.
- A sync run that otherwise has no push/pull errors now still refuses to mark
  sync fresh when `countPendingUploads()` reports remaining local changes after
  the run.
- A sync run that pushed local writes now refuses to mark sync fresh if no
  follow-up pull path ran in the same cycle. This closes the obvious
  pushed-without-pull freshness hole in strict quick-sync flows.
- Added focused engine tests for both guard failures.

Why:

- The previous coordinator wrote `last_sync_time` whenever the aggregate
  push/pull result had no errors. That allowed freshness to advance without a
  final queue-drain proof, and allowed a pushed write to look fresh if a quick
  sync skipped pull.
- This is a first write-checkpoint hardening slice. It proves queue drain and
  pull-path participation before freshness advances. It does not yet prove
  per-record server visibility and final local visibility for each
  acknowledged write; that remains open in the controlling todo.

Local evidence:

- `dart analyze lib/features/sync/engine/sync_engine.dart lib/features/sync/engine/sync_run_lifecycle.dart test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/sync_engine_mode_plumbing_test.dart test/features/sync/engine/sync_engine_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/sync_engine_mode_plumbing_test.dart -r expanded`
  passed 11 tests.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/ready`: ready on `/sync/dashboard`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:19:41.161132Z`.
- S10 `/driver/ready`: ready on `/projects`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:18:47.159255Z`.

Checklist updates:

- Checked off queue-drain proof under write-checkpoint semantics.
- Checked off follow-up pull path proof for pushed-write cycles.
- Left full write-checkpoint semantics open for per-record remote write proof
  and final local proof through the server/pull path.

Still open:

- Per-record write-checkpoint proof, sync freshness proof through actual
  server/pull visibility, realtime hint fallback proof, crash/restart tests,
  domain-specific conflict strategy, file/storage/attachment expansion,
  role/RLS sweeps, and all P2/P3 scale/staging/diagnostics/docs gates.

## 2026-04-18 - Per-record write-checkpoint proof completed locally

What changed:

- Added `AcknowledgedWrite` and `RemoteLocalWriteCheckpointVerifier`.
- `PushHandler` now carries per-record acknowledged write identities in
  `PushResult` without changing aggregate push counts.
- `PushExecutionRouter` now reports proof-worthy server acknowledgements for:
  - normal upserts;
  - insert-only rows;
  - file metadata upserts;
  - soft deletes, including the idempotent "remote already absent" case.
- Skipped adapter work, out-of-scope work, and LWW-only skips remain counted
  according to the existing push semantics but do not enter the remote-write
  proof set.
- `SyncEngineResult` now carries acknowledged writes across push batches.
- `SyncEngine` now verifies each acknowledged write before writing
  `last_sync_time`, after the existing queue-drain and follow-up-pull guards.
- The verifier proves:
  - remote visibility through `SupabaseSync.fetchRecord()`;
  - expected delete state or acceptable remote absence for soft deletes;
  - final local visibility through `LocalSyncStore.readLocalRecord()` after
    the follow-up pull path;
  - non-deleted writes are still active locally/remotely;
  - matching `updated_at` instants when both local and remote rows expose them.

Why:

- The previous freshness guard proved final queue drain and pull-path
  participation, but still allowed `last_sync_time` to advance without proving
  that each acknowledged local write was visible through the server and final
  local store. This slice closes the remaining write-checkpoint semantics in
  the P1 Sync Engine Correctness lane.

Local evidence:

- `dart analyze lib/features/sync/engine/sync_write_checkpoint_proof.dart lib/features/sync/engine/sync_engine_result.dart lib/features/sync/engine/push_execution_router.dart lib/features/sync/engine/push_handler.dart lib/features/sync/engine/sync_engine.dart lib/features/sync/application/sync_engine_factory.dart test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/push_handler_test.dart test/features/sync/engine/sync_write_checkpoint_proof_test.dart test/features/sync/application/sync_coordinator_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/push_handler_test.dart test/features/sync/engine/sync_write_checkpoint_proof_test.dart test/features/sync/application/sync_coordinator_test.dart -r expanded`
  passed 41 tests.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/ready`: ready on `/sync/dashboard`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:19:41.161132Z`.
- S10 `/driver/ready`: ready on `/projects`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:18:47.159255Z`.

Checklist updates:

- Closed remote write proof under write-checkpoint semantics.
- Closed final local proof that acknowledged writes are visible after the
  server/pull path.
- Closed "Do not mark sync fresh until the local write is visible through the
  server/pull path."

Still open:

- Realtime hint fallback proof, crash/restart tests, domain-specific conflict
  strategy, file/storage/attachment expansion, role/RLS sweeps, and all P2/P3
  scale/staging/diagnostics/docs gates.

## 2026-04-18 - Crash/restart sync-engine coverage closed locally

What changed:

- Added a PullHandler path test proving a local-wins conflict inserts an
  unprocessed manual `change_log` update so the winning local row is re-pushed
  after pull.

Existing coverage verified and indexed for this checklist item:

- `local_sync_store_contract_test.dart`: stale `sync_control.pulling = '1'`
  is reset through `resetPullingFlag()`.
- `sync_run_state_store_test.dart`: crash recovery clears both advisory
  `sync_lock` and stale `pulling=1`.
- `sync_mutex_test.dart`: held-lock rejection, stale lock expiry, heartbeat
  expiry, clear-any-lock, release, and reacquire behavior.
- `pull_handler_test.dart`: keyset cursor advancement, page-two failure cursor
  preservation, stored full-page checkpoint restart, and partial-final-page
  replay after apply-time crash.
- `push_handler_test.dart`: 401 auth refresh success retries push and emits
  `SyncAuthRefreshed`; refresh failure leaves the row pending.
- `sync_background_retry_scheduler_test.dart`: background retry scheduling,
  cancel, no-session skip, DNS deferral/reschedule, retryable-result
  reschedule, and permanent-error stop.

Local evidence:

- `dart analyze test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/sync_run_state_store_test.dart test/features/sync/engine/sync_mutex_test.dart test/features/sync/application/sync_background_retry_scheduler_test.dart test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/push_handler_test.dart test/features/sync/engine/sync_write_checkpoint_proof_test.dart lib/features/sync/engine/pull_handler.dart lib/features/sync/application/sync_background_retry_scheduler.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/sync_run_state_store_test.dart test/features/sync/engine/sync_mutex_test.dart test/features/sync/application/sync_background_retry_scheduler_test.dart test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/push_handler_test.dart test/features/sync/engine/sync_write_checkpoint_proof_test.dart -r expanded`
  passed 117 tests.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/ready`: ready on `/sync/dashboard`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:19:41.161132Z`.
- S10 `/driver/ready`: ready on `/projects`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:18:47.159255Z`.

Checklist updates:

- Closed the crash/restart tests item under P1 Sync Engine Correctness
  Hardening, including `pulling=1`, held `sync_lock`, cursor update/restart,
  manual conflict re-push insertion, auth refresh, and background retry
  scheduling.

Still open:

- Realtime hint fallback proof, domain-specific conflict strategy,
  file/storage/attachment expansion, role/RLS sweeps, and all P2/P3
  scale/staging/diagnostics/docs gates.

## 2026-04-18 - Realtime hints proved advisory locally

What changed:

- Added realtime-handler tests proving duplicate realtime broadcasts are
  idempotent dirty scopes: the second duplicate is throttled, but the dirty
  marker remains for the next quick pull.
- Added realtime-handler tests proving out-of-order realtime broadcasts retain
  both dirty scopes even when the second hint is throttled.
- Added realtime-handler coverage proving cross-company realtime hints do not
  dirty scopes or trigger sync.

Existing coverage verified and indexed for this checklist item:

- Failed realtime registration starts fallback polling quick syncs, covering
  missed realtime hints.
- Hints that arrive while a sync is running are queued and trigger a follow-up
  quick sync after the in-flight sync completes, covering delayed hints.
- FCM foreground hints mark dirty scopes before sync, and throttled FCM hints
  still retain dirty scopes.
- FCM background hints persist a pending flag and bounded payload queue so
  resume can consume the missed hint and stay on the quick-sync path.
- Cross-company FCM hints are rejected before they mark dirty scopes or consume
  throttle windows.
- Scope revocation cleaner tests prove revoked project scope is fully evicted
  locally, including shell rows and local files.

Local evidence:

- `dart analyze test/features/sync/application/realtime_hint_handler_test.dart test/features/sync/application/fcm_handler_test.dart test/features/sync/application/sync_lifecycle_manager_test.dart test/features/sync/engine/dirty_scope_tracker_test.dart test/features/sync/engine/pull_scope_state_test.dart test/features/sync/engine/scope_revocation_cleaner_test.dart lib/features/sync/application/realtime_hint_handler.dart lib/features/sync/application/realtime_hint_transport_controller.dart lib/features/sync/engine/dirty_scope_tracker.dart`
  passed with no issues.
- `flutter test test/features/sync/application/realtime_hint_handler_test.dart test/features/sync/application/fcm_handler_test.dart test/features/sync/application/sync_lifecycle_manager_test.dart test/features/sync/engine/dirty_scope_tracker_test.dart test/features/sync/engine/pull_scope_state_test.dart test/features/sync/engine/scope_revocation_cleaner_test.dart -r expanded`
  passed 60 tests.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/ready`: ready on `/sync/dashboard`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:19:41.161132Z`.
- S10 `/driver/ready`: ready on `/projects`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:18:47.159255Z`.

Checklist updates:

- Closed the realtime hints item under P1 Sync Engine Correctness Hardening:
  missed, delayed, duplicate, out-of-order, fallback polling convergence, and
  revocation/no-unauthorized-scope local proof are now covered.

Still open:

- Domain-specific conflict strategy, file/storage/attachment expansion,
  role/RLS sweeps, and all P2/P3 scale/staging/diagnostics/docs gates.

## 2026-04-18 - Domain-specific conflict strategy closed locally

What changed:

- Refactored `ConflictResolver` so deterministic LWW remains the default
  winner selection, with narrow domain preservation hooks for signed and
  audit-sensitive rows.
- Added signed-form preservation: a locally signed `form_responses` row with a
  `signature_audit_id` is kept over a newer unsigned pulled row.
- Added signature file preservation: immutable fingerprint fields
  (`sha256`, size, mime type, creator, create time, project/company ids) keep
  the local row when a full pulled row disagrees.
- Kept signature file `remote_path` propagation LWW when immutable fingerprint
  fields match, so remote upload metadata still flows back to the device.
- Added signature audit preservation: immutable audit-chain fields keep the
  local row when a full pulled row disagrees.
- Left quantities and narrative records on LWW, with changed-column
  `conflict_log` diffs as the documented preservation mechanism for discarded
  quantities, notes, and narrative text.
- Guarded preservation rules from sparse push-skip audit rows so the
  `LwwChecker` server-timestamp path still logs and behaves as LWW.

Local evidence:

- `dart analyze lib/features/sync/engine/conflict_resolver.dart test/features/sync/engine/conflict_resolver_domain_policy_test.dart test/features/sync/engine/conflict_clock_skew_test.dart test/features/sync/property/sync_invariants_property_test.dart test/features/sync/engine/sync_engine_lww_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/conflict_resolver_domain_policy_test.dart test/features/sync/engine/conflict_clock_skew_test.dart test/features/sync/property/sync_invariants_property_test.dart test/features/sync/engine/sync_engine_lww_test.dart -r expanded`
  passed 24 tests.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/ready`: ready on `/sync/dashboard`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:19:41.161132Z`.
- S10 `/driver/ready`: ready on `/projects`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:18:47.159255Z`.

Checklist updates:

- Closed the domain-specific conflict strategy item under P1 Sync Engine
  Correctness Hardening.

Still open:

- File/storage/attachment expansion, role/RLS sweeps, and all P2/P3
  scale/staging/diagnostics/docs gates.

## 2026-04-18 - File/attachment durable phase evidence added locally

What changed:

- Added `file_sync_state_log` as a local diagnostic table for durable
  file-backed sync phase evidence. This is not a second production sync queue;
  `change_log` and row `remote_path` remain the sync truth.
- Bumped the local schema to v62 and wired the new table through fresh
  bootstrap, upgrade migration, schema metadata, and SQLite test helpers.
- Added `FileSyncStateStore` and wired `FileSyncHandler` /
  `FileSyncThreePhaseWorkflow` to record:
  upload started/succeeded/failed, row upsert succeeded/failed, local bookmark
  succeeded/failed, stale object cleanup succeeded/queued.
- Changed stale remote-object cleanup after file replacement so a removal
  failure now queues `storage_cleanup_queue` with bucket and remote path
  instead of only logging a possible leak.
- Wired `StorageCleanup` to record cleanup retry success/failure state events.
- Added `signature_files` / `signatures` to storage cleanup and orphan-scan
  registries.
- Ran PowerSync attachment-helper triage. Current docs mark the old Dart
  `powersync_attachments_helper` package deprecated and recommend built-in SDK
  attachment helpers. Direct adoption is not a release fit because it couples
  to the PowerSync database/queue substrate; the reusable pattern is local-only
  attachment state, explicit queue states, retry/cleanup, and verification,
  which is now being ported into the existing Field Guide sync engine.

Local evidence:

- `dart analyze lib/core/database/schema/sync_engine_tables.dart lib/core/database/database_bootstrap.dart lib/core/database/database_late_migration_steps.dart lib/core/database/database_service.dart lib/core/database/database_schema_metadata.dart lib/features/sync/application/sync_engine_factory.dart lib/features/sync/engine/file_sync_handler.dart lib/features/sync/engine/file_sync_state_store.dart lib/features/sync/engine/file_sync_three_phase_workflow.dart lib/features/sync/engine/storage_cleanup.dart lib/features/sync/engine/storage_cleanup_registry.dart lib/features/sync/engine/orphan_scanner.dart test/helpers/sync/sqlite_test_helper.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart -r expanded`
  passed 102 tests.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/ready`: ready on `/sync/dashboard`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:19:41.161132Z`.
- S10 `/driver/ready`: ready on `/projects`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:18:47.159255Z`.

Checklist updates:

- Closed the durable attachment/file state subitem under P1 File, Storage, And
  Attachment Hardening.
- Closed the PowerSync attachment-helper triage subitem with a pattern-port
  decision and direct-adoption rejection for this release.

Still open:

- Broader storage object proof beyond photos/signatures, unauthorized storage
  access denial proof, cross-device download/preview proof, remaining
  crash/retry cases, role/RLS sweeps, and all P2/P3 scale/staging/diagnostics
  docs gates.

## 2026-04-18 - File-backed row/object adapter contract covered locally

What changed:

- Added registry-level contract coverage for every file-backed adapter:
  `photos`, `documents`, `entry_exports`, `form_exports`,
  `export_artifacts`, and `signature_files`.
- The contract asserts each file-backed family declares its bucket, local path
  column, local-only path stripping, storage cleanup registry mapping, and a
  valid generated storage path.
- The contract also asserts local-only export history adapters still skip both
  pull and push, keeping `entry_exports`, `form_exports`, and
  `export_artifacts` out of remote sync truth.
- The test exposed that the generalized storage path validator rejected the
  actual nested `export_artifacts` path shape. Updated validation to allow
  nested safe directory prefixes while preserving extension allowlists.

Local evidence:

- `dart analyze lib/features/sync/engine/file_sync_three_phase_workflow.dart test/features/sync/engine/adapter_integration_test.dart lib/features/sync/engine/storage_cleanup_registry.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart -r expanded`
  passed 133 tests.

Checklist updates:

- Closed the local row/object consistency contract test subitem for
  file-backed families.

Still open:

- Device/remote storage object proof beyond photos/signatures, unauthorized
  storage access denial proof, cross-device download/preview proof, remaining
  crash/retry cases, role/RLS sweeps, and all P2/P3 scale/staging/diagnostics
  docs gates.

## 2026-04-18 - Stale file cache and storage-family artifact diagnostics

What changed:

- Added stale local file cache invalidation coverage for file-backed pull
  changes:
  - remote path changes delete the stale local file and clear the local path;
  - remote deletes remove the local cached file and clear the local path;
  - unchanged remote paths preserve the local file.
- Added `storage-family-diagnostics.json` and matching summary fields to the
  post-sync reconciliation gate. The artifact now records which storage
  families require remote object proof and which families are local-only
  byte/history proof under the current adapter contract.
- Classified photos, signatures, and entry documents as remote-object proof
  families.
- Classified `entry_exports`, `form_exports`, `export_artifacts`, and
  pay-application exports as local-only byte/history families while the
  adapters remain `skipPush`/`skipPull`.
- Added `Assert-SoakStorageUnauthorizedDenied` and a pure response classifier
  so live flows can prove unauthorized bucket/path access denial against
  proven-present objects without broad auth/RLS inference.

Local evidence:

- `dart analyze lib/features/sync/engine/stale_file_cache_invalidator.dart test/features/sync/engine/stale_file_cache_invalidator_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/stale_file_cache_invalidator_test.dart -r expanded`
  passed 3 tests.
- `flutter test test/features/sync/engine/stale_file_cache_invalidator_test.dart test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart -r expanded`
  passed 138 tests.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 11 test
  files after the storage diagnostics and denial-proof helper changes.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/ready`: ready on `/sync/dashboard`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`.
- S10 `/driver/ready`: ready on `/projects`; `/driver/change-log`: `count=0`,
  `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`.

Checklist updates:

- Closed the Slice J stale local cache invalidation subitem.
- Closed the Slice J decision on local-only export artifact diagnostics by
  adding explicit soak artifact fields.
- Left unauthorized storage access denial proof open until live flow artifacts
  exercise the helper per proven-present bucket/path family.

Still open:

- Live storage object proof beyond photos/signatures for synced families,
  live unauthorized storage denial proof, cross-device download/preview proof,
  remaining file crash/retry cases, role/RLS sweeps, and all P2 scale,
  staging, diagnostics, and docs gates.

## 2026-04-18 - File-sync crash/retry matrix closed locally

What changed:

- Tightened `LocalRecordStore.bookmarkRemotePath()` so phase 3 now throws a
  `StateError` if the local row update affects zero rows.
- Added local-store contract coverage proving the missing bookmark target
  fails and trigger suppression is restored to `pulling=0`.
- Added file-sync workflow coverage for a remote row-upsert success followed
  by a missing local bookmark target. The workflow now records
  `local_bookmark_failed`, emits the phase-3 failure, and does not treat the
  file push as successful.
- Added bookmark-completed replay coverage for the crash window after local
  bookmark but before `change_log` processing. The replay starts with
  `remote_path` already bookmarked and the queue row still unprocessed, skips
  duplicate upload, re-upserts/bookmarks idempotently, creates no extra
  `change_log`, and drains when the original change is marked processed.

Why:

- The crash/retry checklist required proof around the window after row upsert
  but before local bookmark. Before this change, an unexpected zero-row local
  bookmark update could be silently accepted, which would weaken the per-file
  row/object consistency proof.

Local evidence:

- `dart analyze lib/features/sync/engine/local_record_store.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/file_sync_handler_test.dart`
  passed with no issues.
- Initial targeted Flutter run correctly failed while the zero-row check was
  accidentally placed on server-timestamp writeback instead of
  `bookmarkRemotePath()`. The test failure confirmed the phase-3 gap and was
  fixed before acceptance.
- `flutter test test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 58 tests.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart -r expanded`
  passed 59 tests after adding the bookmark-before-`change_log`-processed
  replay proof.
- Broader file/storage regression sweep passed:
  `flutter test test/features/sync/engine/stale_file_cache_invalidator_test.dart test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart test/features/sync/engine/local_sync_store_contract_test.dart -r expanded`
  passed 172 tests.
- Final broader file/storage sweep after adding the
  bookmark-before-`change_log` proof passed:
  `flutter test test/features/sync/engine/stale_file_cache_invalidator_test.dart test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart test/features/sync/engine/local_sync_store_contract_test.dart -r expanded`
  passed 173 tests.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 11 test
  files.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/change-log`: `count=0`, `unprocessedCount=0`,
  `blockedCount=0`, `maxRetryCount=0`.
- S10 `/driver/change-log`: `count=0`, `unprocessedCount=0`,
  `blockedCount=0`, `maxRetryCount=0`.
- Final device hygiene after the 173-test sweep: S21 ready on
  `/sync/dashboard`, S10 ready on `/projects`, both `/driver/change-log`
  responses had `count=0`, `unprocessedCount=0`, `blockedCount=0`, and
  `maxRetryCount=0`.

Checklist updates:

- Marked file crash/retry coverage done for:
  - after upload before row upsert;
  - after row upsert before bookmark;
  - after bookmark before `change_log` processed;
  - after storage delete failure before cleanup retry.
- Closed the file crash/retry parent under P1 File, Storage, And Attachment
  Hardening.

Still open:

- Live storage object proof beyond photos/signatures, live unauthorized
  storage denial proof, cross-device download/preview proof, role/RLS sweeps,
  and P2 scale/staging/diagnostics/docs gates.

## 2026-04-18 - File-backed replay matrix broadened locally

What changed:

- Added document coverage through the real `DocumentAdapter`: local file upload,
  metadata upsert, local `remote_path` bookmark, and durable phase-state log.
- Added signature file replay coverage through the registered
  `signature_files` adapter: an existing `remote_path` with absent
  `local_path` skips upload and replays metadata/bookmark idempotently.
- Existing photo coverage continues to prove duplicate upload replay, storage
  409, row-upsert replay with existing `remote_path`, missing local file with
  existing `remote_path`, upload timeout, and phase-2 cleanup.
- Existing export-artifact coverage proves `local_path` handling, storage path
  changes, stale remote removal, and stale cleanup retry queueing.

Local evidence:

- `dart analyze test/features/sync/engine/file_sync_handler_test.dart` passed
  with no issues.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 24 tests.
- `flutter test test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart -r expanded`
  passed 135 tests.
- `git diff --check` passed with line-ending warnings only.

Device hygiene after proof:

- S21 `/driver/ready`: ready on `/sync/dashboard`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:19:41.161132Z`.
- S10 `/driver/ready`: ready on `/projects`; `/driver/change-log`:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status`: `isSyncing=false`, `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`,
  `lastSyncTime=2026-04-19T00:18:47.159255Z`.

Checklist updates:

- Closed the local upload replay / metadata replay / storage 409 /
  missing-object recovery subitem for photos, documents, signature files, and
  export artifacts.

Still open:

- Device/remote storage object proof beyond photos/signatures, unauthorized
  storage access denial proof, cross-device download/preview proof, remaining
  crash/retry cases, role/RLS sweeps, and all P2/P3 scale/staging/diagnostics
  docs gates.

## 2026-04-18 - Entry-document live storage proof accepted

What changed:

- Added the `documents-only` refactored soak flow and wired it through the
  module loader, dispatcher, lab entrypoints, concurrent soak entrypoint, and
  harness self-tests.
- Wired production entry-document creation for device proof by letting
  `DocumentService.attachDocument()` consume injected driver files before the
  native picker for supported document extensions.
- Added document UI testing keys and screen-contract actions for the
  report-entry document subsection.
- Added document local download/cache support through `SyncFileAccessService`,
  `ManageDocumentsUseCase`, `DocumentProvider`, and
  `EntryDocumentsSubsection`, with trigger-suppressed local cache path writes.
- Extended `/driver/local-file-head` to read document local paths for later
  local/cross-device visibility proof.
- Tightened the storage unauthorized-denial classifier so private bucket
  responses of HTTP 400 with `Bucket not found` are accepted only when the
  caller opts into `-TreatNotFoundAsDenied`.

Why:

- The P1 file/storage lane still needed a synced non-photo/non-signature object
  family proven end-to-end. Entry documents are a remote-object family under
  the current adapter contract, unlike local-only export history tables.
- The first live run proved the row/object path but exposed a too-narrow
  denial classifier for Supabase private buckets. The fix keeps the proof
  fail-closed on successful downloads while accepting the expected hidden
  bucket response from invalid credentials.

Local evidence:

- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 11 test
  files after adding the hidden-bucket classifier case.
- Earlier focused gates for the document flow were already green in this
  slice:
  - `dart analyze` on touched document service/provider/repository/driver
    route files and tests passed with no issues.
  - `flutter test test/services/document_service_test.dart test/features/forms/presentation/providers/document_provider_test.dart test/features/entries/presentation/widgets/entry_forms_section_test.dart test/core/driver/driver_data_sync_routes_test.dart test/core/driver/driver_data_sync_handler_test.dart -r expanded`
    passed 28 tests.
  - `git diff --check` passed with line-ending warnings only.

Live device evidence:

- Preflight before the accepted rerun:
  S21 `/driver/ready` ready on `/sync/dashboard`; `/driver/change-log` empty
  with `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`;
  `/driver/sync-status` idle with `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`.
- Diagnostic first run:
  `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-documents-entry-object-proof-initial/`
  failed only at unauthorized-denial classification. It still proved local
  document mutation, pre-sync `change_log`, UI-triggered sync, remote row,
  authorized storage bytes/hash, cleanup sync, storage delete/absence, empty
  queues, zero runtime/logging gaps, and no direct driver sync.
- Accepted rerun:
  `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-documents-entry-object-proof-after-denial-classifier/`
  passed with `queueDrainResult=drained`, `failedActorRounds=0`,
  `runtimeErrors=0`, `loggingGaps=0`, `blockedRowCount=0`,
  `unprocessedRowCount=0`, `maxRetryCount=0`, and
  `directDriverSyncEndpointUsed=false`.
- Accepted row/object proof:
  `documents/b4efc514-b14f-41e4-a257-b5ef0989ed5a`, entry
  `f14d87c1-d870-444e-ba2b-bca5762aa485`, remote path
  `docs/26fe92cd-7044-4412-9a09-5c5f49a292f9/f14d87c1-d870-444e-ba2b-bca5762aa485/enterprise_soak_doc_S21_round_1_214458.pdf`,
  bucket `entry-documents`, 48 bytes, SHA-256
  `d7aacd14db7ca489d86ca71c834ac5513f54cbfbab168d7929c086b6a7e61dc6`.
- Unauthorized proof for the same bucket/path passed with HTTP 400
  `Bucket not found` under `-TreatNotFoundAsDenied`.
- Cleanup proof passed: ledger-owned soft delete, UI-triggered cleanup sync,
  storage delete, and storage absence.

Checklist updates:

- Checked off entry-document object proof in the live task list and recorded
  the accepted artifact in the controlling todo.
- Marked entry-document unauthorized-denial live proof complete, while leaving
  the broader bucket/path-family denial parent open until photo/signature
  accepted flows are rerun with the new denial helper and cross-device
  download/preview is proven.

Still open:

- Rerun live photo/signature bucket-path families with the denial helper.
- Prove cross-device download/preview of uploaded objects.
- Role/RLS sweeps and all P2 scale/staging/diagnostics/docs gates remain open.

## 2026-04-18 - Remote object denial and cross-device document download accepted

What changed:

- Added `documents-cross-device-only`, a two-actor refactored flow that:
  creates an entry document on the source actor;
  syncs the source through the Sync Dashboard;
  proves the remote row, storage object, and unauthorized denial;
  syncs the receiver through the Sync Dashboard;
  opens the pulled document tile on the receiver to force download/cache;
  proves receiver local bytes with `/driver/local-file-head`;
  performs source ledger cleanup;
  syncs the receiver cleanup pull; and
  verifies receiver soft-delete visibility.
- Wired the flow through `tools/enterprise-sync-soak-lab.ps1`,
  `tools/enterprise-sync-concurrent-soak.ps1`,
  `tools/sync-soak/DeviceLab.RefactoredDispatcher.ps1`,
  `tools/sync-soak/ModuleLoader.ps1`, and `FlowWiring.Tests.ps1`.
- Reused the document creation/download app changes from the prior slice and
  rebuilt S10 so the receiver had the document download/cache path.

Local evidence:

- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 11 test
  files after adding `documents-cross-device-only` wiring and assertions.

Device setup and recovery notes:

- S21 `photo-only` and `mdot1126-signature-only` were rerun after the denial
  helper was wired.
- S10 rebuild removed the S21 host forward; S21 was rebuilt/restarted on port
  4948 and S10's port 4949/debug reverse were restored.
- S10 had three unprocessed signature cleanup rows after observing the S21
  signature cleanup. `20260418-s10-post-signature-denial-residue-sync-only`
  drained those rows through the Sync Dashboard before cross-device proof.
- Final cross-device preflight showed S21 and S10 both idle with empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, and
  `unprocessedCount=0`.

Accepted live evidence:

- Photo remote-object denial:
  `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-photo-storage-denial-proof/`
  passed with `photos/799779ce-b41f-4ea0-bea2-f92e72bc14ed`, bucket
  `entry-photos`, remote path
  `entries/26fe92cd-7044-4412-9a09-5c5f49a292f9/f14d87c1-d870-444e-ba2b-bca5762aa485/enterprise_soak_S21_round_1_214730.jpg`,
  authorized object 68 bytes, SHA-256
  `1dae93d61eceabd7ce356b2be0acf0d2b813bf595f5cbae775a88582fd4ad278`,
  and unauthorized HTTP 400 `Bucket not found` for the same path.
- Signature remote-object denial:
  `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-mdot1126-signature-storage-denial-proof/`
  passed with `signature_files/a5d373fd-4096-4ea5-8406-476db56196f0`,
  bucket `signatures`, remote path
  `signatures/26fe92cd-7044-4412-9a09-5c5f49a292f9/75ae3283-d4b2-4035-ba2f-7b4adb018199/a5d373fd-4096-4ea5-8406-476db56196f0.png`,
  authorized object 5193 bytes, SHA-256
  `95c0ab2bfc32859719ec0de97ebaf4710e2dfb605fc5751cd54e90a398912755`,
  and unauthorized HTTP 400 `Bucket not found` for the same path.
- S10 residue drain:
  `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s10-post-signature-denial-residue-sync-only/`
  passed with final clean queue.
- Cross-device document download:
  `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-s10-documents-cross-device-download-proof/`
  passed with `queueDrainResult=drained`, `failedActorRounds=0`,
  `runtimeErrors=0`, `loggingGaps=0`, `blockedRowCount=0`,
  `unprocessedRowCount=0`, `maxRetryCount=0`,
  `directDriverSyncEndpointUsed=false`, and final clean queues on both
  actors.
- Cross-device row/object details:
  `documents/b8f80b06-9e14-4ff4-9e38-0be0e7cbf8f1`, remote path
  `docs/26fe92cd-7044-4412-9a09-5c5f49a292f9/f14d87c1-d870-444e-ba2b-bca5762aa485/enterprise_soak_cross_device_doc_S21_to_S10_round_1_215611.pdf`,
  bucket `entry-documents`, authorized object 48 bytes, SHA-256
  `d7aacd14db7ca489d86ca71c834ac5513f54cbfbab168d7929c086b6a7e61dc6`,
  and unauthorized HTTP 400 `Bucket not found`.
- Receiver proof:
  S10 pulled the row through UI sync, tapped
  `document_tile_b8f80b06-9e14-4ff4-9e38-0be0e7cbf8f1`,
  `/driver/local-file-head?table=documents&id=b8f80b06-9e14-4ff4-9e38-0be0e7cbf8f1&sha256=true`
  returned `exists=true`, 48 bytes, and the same SHA-256 as storage, then S10
  pulled the cleanup and observed `deleted_at`.

Checklist updates:

- Closed live unauthorized denial proof for all applicable remote-object
  families: photos, signatures, and entry documents.
- Closed cross-device download/preview proof for uploaded objects with the
  S21-to-S10 entry-document artifact.
- Closed the broader file/storage object-proof item under the current adapter
  contract: photos/signatures/documents are remote-object families; export and
  pay-app artifact families are local-only byte/history families with accepted
  local proof and diagnostics, not remote object families.

Still open:

- P1 Role/Scope/Account/RLS sweeps.
- P2 reuse triage, Jepsen-style workload/history/checkers, failure injection
  and liveness, backend/device overlap, staging gates, 15-20 actor scale,
  diagnostics/alerts, consistency contract docs, and final green-streak gates.

## 2026-04-18 - Role/RLS diagnostics and live fixture inventory started

What changed:

- Extended `/diagnostics/actor_context` to include the resolved
  `AuthProvider` role context:
  provider availability, provider user id, company id, role wire name,
  membership status, approval/admin/engineer/office technician/inspector
  booleans, project-management and field-edit permission booleans, and profile
  freshness timestamps.

Why:

- The P1 role/RLS sweep cannot rely on actor labels such as `inspector` in the
  PowerShell actor spec. It must prove the active real session and provider
  permission state from the app under test.

Local evidence:

- `dart format lib/core/driver/driver_diagnostics_handler.dart`.
- `dart analyze lib/core/driver/driver_diagnostics_handler.dart test/core/driver/driver_diagnostics_routes_test.dart`
  passed with no issues.
- `flutter test test/core/driver/driver_diagnostics_routes_test.dart -r expanded`
  passed 2 tests.

Live device evidence:

- Rebuilt/restarted S21 on port 4948 and S10 on port 4949 with the new
  diagnostics fields.
- S21 `/diagnostics/actor_context` returned a real session for
  `userId=d1ca900e-d880-4915-9950-e29ba180b028`, company
  `26fe92cd-7044-4412-9a09-5c5f49a292f9`, role `office_technician`, status
  `approved`, `canManageProjects=true`, `canEditFieldData=true`,
  `canManageProjectFieldData=true`, and `canCreateProject=true`.
- S10 returned the same real user/company/role/permission state.
- S21 and S10 `/driver/change-log` were clean after rebuild:
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0`.

Fixture inventory:

- Local harness metadata already defines deterministic admin, engineer,
  office technician, inspector, and 15-project fixture ids in
  `integration_test/sync/harness/harness_fixture_cursor.dart`.
- The live device environment currently exposes only the single E2E app
  credential pair used by both S21 and S10. No separate admin, engineer,
  inspector, or office-technician credential set is present for same-device
  account switching or full role sweeps.

Checklist updates:

- Added an Immediate Slice M task list to the live checklist.
- Kept the P1 role/account/RLS parent items open until separate real role
  credentials or staging harness personas are provisioned and accepted on
  devices.

Still open:

- Provision or expose real admin, engineer, inspector, and office technician
  device credentials without `MOCK_AUTH`.
- Run role sweeps and same-device account switching with real sessions.
- Prove denied routes/hidden controls, stale scope eviction, grants, and
  revocations through device artifacts.

## 2026-04-18 - Admin/inspector role sweep accepted

What changed:

- Added `role-sweep-only` as a refactored soak flow and wired it through the
  module loader, dispatcher, lab entrypoint, concurrent entrypoint, and local
  harness tests.
- Hardened `Assert-SoakActorSessionSentinel` so the harness asserts the real
  nested provider role from `/diagnostics/actor_context` instead of trusting
  the actor label.
- Added route/control proof for admin and inspector boundaries:
  admin dashboard, trash, project creation, inspector project-create denial,
  inspector pay-app detail denial, and inspector PDF import denial.
- Hardened the shared Sync Dashboard flow with bounded UI tap retry while
  preserving the no-direct-driver-sync rule.
- Fixed a reproducible S10 settings-screen semantics assertion by replacing
  theme `RadioListTile` options with stable `ListTile` plus trailing `Radio`
  controls.

Diagnostic failed attempts preserved:

- `20260418-s21-s10-role-sweep-admin-inspector-initial` failed before
  acceptance due to an over-strict floating-action-button enabled proof and
  the S10 settings semantics assertion.
- `20260418-s21-s10-role-sweep-admin-inspector-after-fab-proof-fix`,
  `20260418-s21-s10-role-sweep-admin-inspector-after-sync-tap-hardening`,
  `20260418-s21-s10-role-sweep-admin-inspector-after-frame-settle`,
  `20260418-s10-role-sweep-inspector-isolated`, and
  `20260418-s10-role-sweep-inspector-after-restart` remained diagnostic
  attempts while the S10 semantics and Sync Dashboard tap behavior were being
  isolated.

Local evidence:

- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed after the
  role-sweep wiring and sentinel changes.
- `dart analyze lib/features/settings/presentation/widgets/theme_section.dart test/features/settings/presentation/screens/settings_screen_test.dart`
  passed with no issues.
- `flutter test test/features/settings/presentation/screens/settings_screen_test.dart -r expanded`
  passed 23 tests.
- `git diff --check` passed with line-ending warnings only.

Live device evidence:

- S21 on port 4948 resolved as a real approved admin session for company
  `26fe92cd-7044-4412-9a09-5c5f49a292f9`, with
  `canCreateProject=true`, `canManageProjects=true`, and clean queue state.
- S10 on port 4949 resolved as a real approved inspector session for the same
  company, with `canCreateProject=false`, `canManageProjects=false`, and
  clean queue state.
- Rebuilt/restarted the S10 Android driver app with
  `tools/start-driver.ps1 -Platform android -DeviceId R52X90378YB -DriverPort 4949 -ForceRebuild`
  so the settings semantics fix was present on the device. Restored the S21
  ADB forward after the S10 rebuild changed device forwards.
- Accepted artifact:
  `20260418-s21-s10-role-sweep-admin-inspector-after-sync-tap-retry`.
  It passed with `failedActorRounds=0`, `runtimeErrors=0`, `loggingGaps=0`,
  `queueDrainResult=drained`, `blockedRowCount=0`, `unprocessedRowCount=0`,
  `maxRetryCount=0`, `actionCount=2`, 16 screenshots, 18 log captures,
  UI-triggered sync, and `directDriverSyncEndpointUsed=false`.

Checklist updates:

- Added Immediate Slice N to the live task list and checked off the accepted
  admin/inspector subset.
- Kept the P1 Role/Scope/Account/RLS parent open for engineer and
  office-technician role sweeps, same-device account switching, stale
  account/project/realtime/local-scope eviction, and grant/revocation proof.

Still open:

- Verify the engineer and office-technician accounts on devices or emulators
  without logging credentials.
- Decide whether to run all four roles simultaneously with S21, S10, and two
  Android emulators or to rotate accounts through same-device switching.
- Implement/accept the remaining role route-control matrix and stale-scope
  proofs with real sessions.

## 2026-04-18 - Engineer/office account-switch role sweep accepted

What changed:

- Added `RoleAccounts.ps1` to parse role account credentials from
  `.env.secret` without printing values. It supports repeated
  `EMAIL`/`PASSWORD` pairs with inline role notes after the email token, plus
  named role keys, and verifies each account through Supabase anon auth and
  the account's own `user_profiles` row.
- Added `role-account-switch-only` as a refactored flow. It performs real UI
  sign-out/sign-in, accepts the first-run consent gate by scrolling the policy
  pane to enable the button, proves the new real role through
  `/diagnostics/actor_context`, runs the role route/control sweep, and ends
  through Sync Dashboard UI sync.
- Redacted `/driver/text` request bodies in `DriverClient.ps1` failure output
  so credential entry errors cannot write email/password text into soak
  artifacts.
- Fixed the compact S21 sign-out dialog overflow by replacing fixed-width
  action `Row`s with wrapping action layouts in `sign_out_dialog.dart`.

Diagnostic failed attempts preserved:

- `20260418-s21-s10-role-account-switch-engineer-office-initial` proved the
  secret-backed account resolver and real UI login for S21 engineer and S10
  office technician, but failed because both first-run accounts stopped at
  `/consent`.
- `20260418-s21-s10-role-account-switch-engineer-office-after-consent` and
  `20260418-s21-s10-role-account-switch-engineer-office-after-consent-scroll`
  isolated the consent-button enablement requirement.
- `20260418-s21-s10-role-account-switch-engineer-office-after-consent-route-proof`
  reduced the remaining failure to a real S21 compact-layout
  `RenderFlex overflowed by 139 pixels` runtime error in the sign-out dialog.

Local evidence:

- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 12 test
  files after account parser, account switch flow, consent handling, and
  redaction coverage were added.
- `dart analyze lib/features/settings/presentation/widgets/sign_out_dialog.dart lib/features/settings/presentation/widgets/theme_section.dart test/features/settings/presentation/screens/settings_screen_test.dart`
  passed with no issues.
- `flutter test test/features/settings/presentation/screens/settings_screen_test.dart -r expanded`
  passed 23 tests.
- `git diff --check` passed with line-ending warnings only.

Live device evidence:

- Rebuilt/restarted S21 on port 4948 with the sign-out dialog overflow fix
  and restored S10 port 4949 after the rebuild cleared the ADB forward.
- Accepted artifact:
  `20260418-s21-s10-role-account-switch-engineer-office-after-signout-wrap`.
  It passed with `failedActorRounds=0`, `runtimeErrors=0`, `loggingGaps=0`,
  `queueDrainResult=drained`, `blockedRowCount=0`, `unprocessedRowCount=0`,
  `maxRetryCount=0`, `actionCount=2`, 14 screenshots, 20 log captures,
  UI-triggered sync, and `directDriverSyncEndpointUsed=false`.
- S21 resolved as approved `engineer` for company
  `26fe92cd-7044-4412-9a09-5c5f49a292f9`, with
  `canCreateProject=true`, `canManageProjects=true`, and clean final queue.
- S10 resolved as approved `office_technician` for the same company, with
  `canCreateProject=true`, `canManageProjects=true`, and clean final queue.
- Account-switch artifact summaries redacted email and password values while
  retaining only source line metadata, role, user id, company id, and status.

Checklist updates:

- Closed engineer and office-technician real-session role sweeps in the live
  task list and controlling todo.
- Kept same-device account switching open because the accepted artifact does
  not yet prove the explicit required transitions `admin -> inspector` and
  `inspector -> office_technician`.
- Kept stale provider/project/realtime/local-scope eviction and grant/revocation
  proof open.

Still open:

- Run an accepted transition sequence that ends with explicit
  `admin -> inspector` and `inspector -> office_technician` same-device
  evidence.
- Add before/after stale-scope assertions across account changes.
- Add real grant/revocation sync-change proof.

## 2026-04-18 - Required same-device role transitions accepted

What changed:

- Reused the secret-safe `role-account-switch-only` flow to rotate the two
  physical devices through the exact same-device transition sequence required
  by the P1 role/account checklist.

Accepted evidence:

- Setup artifact:
  `20260418-s21-s10-role-account-switch-admin-inspector-setup` passed with
  `failedActorRounds=0`, `runtimeErrors=0`, `loggingGaps=0`,
  `queueDrainResult=drained`, `blockedRowCount=0`,
  `unprocessedRowCount=0`, `maxRetryCount=0`, and
  `directDriverSyncEndpointUsed=false`.
- Required transition artifact:
  `20260418-s21-s10-role-account-switch-required-transitions` passed with
  `failedActorRounds=0`, `runtimeErrors=0`, `loggingGaps=0`,
  `queueDrainResult=drained`, `blockedRowCount=0`,
  `unprocessedRowCount=0`, `maxRetryCount=0`, `actionCount=2`, 16
  screenshots, 22 log captures, UI-triggered sync, and
  `directDriverSyncEndpointUsed=false`.
- S21 same-device transition:
  before `role=admin`, `userId=88054934-9cc5-4af3-b1c6-38f262a7da23`,
  `canCreateProject=true`, `canManageProjects=true`; after
  `role=inspector`, `userId=6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`,
  `canCreateProject=false`, `canManageProjects=false`.
- S21 post-switch route/control proof included admin dashboard denied, trash
  denied, project-new denied, project create control hidden, pay-app detail
  denied, and PDF import denied.
- S10 same-device transition:
  before `role=inspector`, `userId=6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`,
  `canCreateProject=false`, `canManageProjects=false`; after
  `role=office_technician`,
  `userId=d1ca900e-d880-4915-9950-e29ba180b028`,
  `canCreateProject=true`, `canManageProjects=true`.
- S10 post-switch route/control proof included admin dashboard denied, trash
  denied, project-new allowed, and project create control visible.

Checklist updates:

- Checked off the required `admin -> inspector` and
  `inspector -> office_technician` same-device account-switch bullets in the
  controlling todo and live task list.
- Kept active-user-to-revoked-user, revoked-user-back-to-allowed-user,
  stale provider/project/realtime/local-scope eviction, and grant/revocation
  sync-change proof open.

Still open:

- Add device proof for revoked/allowed account transitions.
- Add dedicated stale-scope assertions across account changes.
- Add real grant/revocation sync-change proof.

## 2026-04-19 - Stale account/scope proof accepted and role lane reframed

User clarification:

- Same-device switching is useful confirmation, but it should not dominate the
  role-security lane because most users will use their own devices.
- The remaining role hardening should focus on separate real accounts, no
  bleed-through between accounts, route/action permission gates, RLS denial,
  and real grant/revocation propagation.

Accepted evidence:

- Artifact:
  `.claude/test-results/2026-04-18/enterprise-sync-soak/20260418-s21-s10-role-account-switch-required-transitions-stale-scope/`.
- Summary gates: `failedActorRounds=0`, `runtimeErrors=0`,
  `loggingGaps=0`, `queueDrainResult=drained`, `blockedRowCount=0`,
  `unprocessedRowCount=0`, `maxRetryCount=0`, `actionCount=2`, 16
  screenshots, 22 log captures, UI-triggered sync, and
  `directDriverSyncEndpointUsed=false`.
- S21 stale-scope proof:
  - before user: admin `88054934-9cc5-4af3-b1c6-38f262a7da23`;
  - final user: inspector `6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`;
  - final route: `/sync/dashboard`;
  - selected project: `null`;
  - dirty scope count: `0`;
  - transport company: `26fe92cd-7044-4412-9a09-5c5f49a292f9`;
  - realtime channel active: `true`.
- S10 stale-scope proof:
  - before user: inspector `6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`;
  - final user: office technician `d1ca900e-d880-4915-9950-e29ba180b028`;
  - final route: `/sync/dashboard`;
  - selected project: `null`;
  - dirty scope count: `0`;
  - transport company: `26fe92cd-7044-4412-9a09-5c5f49a292f9`;
  - realtime channel active: `true`.

Checklist updates:

- Closed the stale provider/project/realtime/local-scope account-switch proof
  in the live task list and controlling todo.
- Reframed same-device switching as regression coverage.
- Kept the P1 role/RLS lane open for separate-device account isolation,
  export/download/storage-preview controls, real non-admin RLS denial checks,
  and real grant/revocation sync-change proof.

Open next:

- Implement a secret-safe role/RLS admin-action helper that uses real Supabase
  anon sessions, never service-role credentials for denial assertions.
- Prove non-admin accounts cannot call admin-only role/status RPCs.
- Deactivate/revoke the target account through a real admin session, drive the
  target device through the normal app refresh/sync path, prove
  `/account-status` and `membershipStatus=deactivated`, then restore/reactivate
  and prove the approved role gates return.

## 2026-04-19 - Revocation recovery login hardening in progress

Diagnostic evidence:

- `20260418-s21-s10-role-revocation-admin-inspector-initial` reached the real
  grant/revocation lane far enough to deactivate the S10 inspector account,
  drive the device to account-status, sign the target out, and restore the
  account in the flow's cleanup path.
- The run then failed during recovery sign-in because `login_sign_in_button`
  was below the visible S10 viewport after credential entry.

What changed:

- Added `auth_shell_scroll_view` to the shared auth responsive shell and the
  login screen contract.
- Hardened `Invoke-SoakUiSignInAsRole` so account-switch and revocation
  recovery sign-ins scroll to `login_sign_in_button` before tapping.

Local evidence:

- `dart analyze lib/features/auth/presentation/widgets/auth_responsive_shell.dart lib/features/auth/presentation/screens/login_screen.dart lib/shared/testing_keys/auth_keys.dart lib/shared/testing_keys/testing_keys.dart lib/core/driver/screen_contract_registry.dart`
  passed.
- `flutter test test/core/driver/root_sentinel_auth_widget_test.dart test/core/driver/registry_alignment_test.dart -r expanded`
  passed 8 tests.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 12 test
  files.

Still open:

- Rebuild S10 with the new key, sign it back in as inspector, and rerun the
  S21 admin / S10 inspector `role-revocation-only` proof.

## 2026-04-19 - Role hardening lane reset to collaboration stress

User correction:

- The role-hardening lane should not focus on live admin deactivation. The app
  is currently one company account with multiple real role accounts, and the
  hardening target is the seams between those roles while they collaborate on
  the same project.
- Future role runs must stress the system: inspector writes, office technician
  review/edit paths, project-scoped sync visibility, storage placement,
  ownership/updater fields, RLS negative writes, stale local cache, and UI/log
  defects under real two-device sync.

Diagnostic artifacts preserved:

- `20260418-s21-s10-role-revocation-admin-inspector-initial` is retained as a
  UI-flow diagnostic. It exposed `widget_tap_not_found` for
  `login_sign_in_button` after target sign-out, with clean queue/runtime/logging
  counters.
- `20260418-s10-inspector-login-after-auth-scroll-key` accepted the login
  scroll-key hardening on S10 with `failedActorRounds=0`, `runtimeErrors=0`,
  `loggingGaps=0`, `queueDrainResult=drained`, and
  `directDriverSyncEndpointUsed=false`.
- `20260418-s21-s10-role-revocation-admin-inspector-after-auth-scroll-key`
  passed and restored the inspector account to `approved`, but it is not the
  forward role-hardening model.

Plan reset:

- Removed live account deactivation as a required checklist item.
- Added a same-project multi-role collaboration stress flow as the next P1
  slice.
- Added non-destructive RLS/permission-boundary probes using real non-admin
  anon sessions.
- Added storage/local-placement assertions so files and pulled cache are proven
  to live under the intended project/account scope.
- Every accepted run must still be audited for `runtimeErrors=0`,
  `loggingGaps=0`, drained queues, screenshots/widget trees without UI defects,
  and `directDriverSyncEndpointUsed=false`.

## 2026-04-19 - Beta role traffic scope clarified

User correction:

- The current beta target is a one-company internal tool. Live account
  deactivation/revocation is not a useful hardening lane right now.
- The next useful evidence is true live user traffic across the real roles:
  admin, engineer, office technician, and inspector. Each role's permissions,
  allowed workflows, denied workflows, sync visibility, storage placement, and
  local cache boundaries need to be stressed and verified.
- After role traffic and permission seams are verified, the next major lane is
  at-scale sync soak.

Updated direction:

- Removed live account-status mutation from the active role checklist.
- Retained existing revocation artifacts only as diagnostics and proof that the
  account was restored, not as beta readiness criteria.
- The next implementation slice is a same-company/same-project role traffic
  stress flow: inspector field writes, office-technician review/visibility,
  engineer/admin management permissions, non-destructive denied operations,
  storage placement checks, and log/screenshot/runtime auditing.
- The scale soak lane starts only after the role traffic gates have artifact
  backed proof.

## 2026-04-19 - Initial role collaboration stress flow implemented

What changed:

- Added `role-collaboration-stress-only` as a refactored sync-soak flow.
- The first slice composes existing real UI/sync proof seams:
  - inspector daily-entry activity edit through the report UI;
  - inspector Sync Dashboard UI sync;
  - remote `daily_entries` proof for project id, creator, activity marker,
    delete state, and updated metadata;
  - office-technician Sync Dashboard UI pull;
  - office-technician local visibility proof for the inspector-created entry;
  - office-technician review-comment write through the report menu UI;
  - remote `todo_items` proof for entry id, project id, creator,
    assigned-to inspector, `source_type=review_comment`, delete state, and
    description marker;
  - inspector final Sync Dashboard UI pull and local visibility proof for the
    review comment;
  - ledger cleanup for the review-comment todo and daily-entry activity marker.
- Wired the flow through `ModuleLoader.ps1`,
  `DeviceLab.RefactoredDispatcher.ps1`, `enterprise-sync-soak-lab.ps1`,
  `enterprise-sync-concurrent-soak.ps1`, and the local harness test loader.

Local evidence:

- `Flow.RoleCollaboration.ps1` parsed cleanly with the PowerShell parser.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 12 test
  files.

Live fixture audit:

- S21 currently resolves as approved `admin` with 8 projects, 4 sampled local
  projects, 4 sampled project assignments, 1 sampled daily entry, 2 sampled
  locations, and clean dirty scope state.
- S10 currently resolves as approved `inspector`, but has
  `projectCount=0`, `project_assignments=0`, `daily_entries=0`,
  `locations=0`, and `bid_items=0`.
- Because the inspector account has no shared project data on-device, the new
  collaboration stress flow should not be accepted yet. The next step is to
  create or select a real shared beta project fixture with inspector and
  office-technician access, then run the flow.

## 2026-04-19 - Controlled Supabase cleanup and soak fixture lane opened

User direction:

- Preserve the Springfield DWSRF project because it is demo seed data for the
  company.
- Treat all other existing Supabase project data as junk unless the inventory
  proves it is part of the disposable soak fixture.
- Create one clearly named project for role-boundary and at-scale sync soak
  traffic:
  `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`
  (`SOAK-ROLE-TRAFFIC-20260418`).
- Use that project to verify all four real roles, then move to scale soak.

Implementation guardrails:

- Do not print or persist Supabase credentials.
- Snapshot the remote delete set and row counts before applying cleanup.
- Do not delete auth users, user profiles, companies, or company join records.
- Preserve Springfield DWSRF project-scoped rows and only remove storage
  objects whose non-Springfield project ownership is proven by table rows.
- After cleanup/seed, drive S21/S10 through real UI Sync Dashboard pull and
  accept only with clean runtime/logging/queue evidence and no stale UI scope.

## 2026-04-19 - Springfield pay-item pull defect and pull-echo race

User-visible symptom:

- On S21, Springfield DWSRF opened with no pay items even though Sync Dashboard
  had reported completion.

What was verified:

- Remote Springfield DWSRF was intact. The project
  `75ae3283-d4b2-4035-ba2f-7b4adb018199` still had 131 active remote
  `bid_items`.
- S21 local state before repair had `bid_items=0` for Springfield while sync
  was idle with no pending queue.
- A forced integrity reset plus UI-triggered sync did not immediately recover
  the local pay items.
- After the app/driver was restarted, S21 recovered 131 local Springfield
  `bid_items`; the local reconciliation hash was
  `cf1a37c9447e01fdb571de73cf4bef71d38cde8a288a1cf8a15a4a7289022540`.

Root cause class:

- Pull/backfill writes generated outbound local `change_log` rows while
  trigger suppression was disabled.
- Code inspection found `SyncEngine.pushAndPull()` resetting the pulling flag
  before acquiring the sync mutex. A concurrent or duplicate sync attempt that
  failed to acquire the mutex could still set `sync_control.pulling=0`,
  disabling trigger suppression for the active pull.

Implemented hardening:

- Moved `resetPullingFlag()` to run only after successful mutex acquisition in
  `lib/features/sync/engine/sync_engine.dart`.
- Added regression coverage in
  `test/features/sync/engine/sync_engine_status_test.dart` proving a lock
  failure does not reset trigger suppression and does not run push/pull work.

Local evidence:

- `dart analyze lib\features\sync\engine\sync_engine.dart test\features\sync\engine\sync_engine_status_test.dart`
- `flutter test test\features\sync\engine\sync_engine_status_test.dart -r expanded`

Still open:

- Existing S21 pull-echo residue must be drained through real UI Sync
  Dashboard sync only. Latest live check on 2026-04-19 showed
  `pendingCount=251`, `unprocessedCount=251`, `blockedCount=0`,
  `isSyncing=false`.
- Remaining residue groups were Springfield `daily_entries=35`,
  `entry_quantities=145`, `personnel_types=9`, `photos=11`, and
  `form_responses=51` with null `project_id`.
- The post-fix drain artifact
  `20260419-s21-springfield-bid-items-drain-after-mutex-fix` failed because
  `sync_now_full_button` was not tappable while resume/sync actions existed.
  That is a harness/UI-state defect and remains part of the P0 closeout.

## 2026-04-19 - Springfield pull-echo P0 hardening continued

Answer to the role/shared-project question:

- It is unlikely that legitimate multi-role edits on the same project created
  the Springfield pay-item outage or the 662/1051 conflict buildup by
  themselves.
- It is likely that role/project scope changes exposed the defect. The device
  was moving between visible project scopes while pull cursors were tracked
  globally per table. Rows older than a table cursor could be skipped when a
  project entered scope later.
- The large conflict wave had the pull-echo fingerprint: remote-wins conflicts
  for rows that had matching processed local `insert` change-log entries and
  no pending local work. That is not the shape of office-tech/admin/inspector
  users independently editing the same records.

Additional fixes:

- Full sync now treats integrity cursor repair as a same-run repair gate. When
  housekeeping clears a pull cursor, the engine immediately runs a second pull
  before reporting completion.
- Conflict-only results now fail the clean-success path and surface an
  attention-needed state instead of updating freshness metadata as if
  everything was clean.
- Added `repair_sync_state_v2026_04_19_pull_echo_conflicts`, a targeted
  startup repair that dismisses only verified pull-echo residue:
  remote winner, matching processed local `insert`, no pending record work,
  and conflict detection inside the pull-echo time window.

Local evidence:

- `dart analyze lib\features\sync\engine\sync_repair_debug_store.dart lib\features\sync\engine\local_sync_store_metadata.dart lib\features\sync\application\sync_state_repair_runner.dart lib\features\sync\application\repairs\repair_sync_state_v2026_04_19_pull_echo_conflicts.dart test\features\sync\application\sync_state_repair_runner_test.dart`
  passed with no issues.
- `flutter test test\features\sync\application\sync_state_repair_runner_test.dart -r expanded`
  passed 12 tests.
- `flutter test test\features\sync\engine\sync_engine_status_test.dart -r expanded`
  passed 15 tests.

Live S21 evidence:

- Hot restart on S21 ran repair catalog `2026-04-19.1`.
- `sync_repair_job::repair_sync_state_v2026_04_19_pull_echo_conflicts`
  applied at `2026-04-19T04:34:35.414531Z` and dismissed 992 conflict rows.
- Remaining undismissed conflicts: 59 rows:
  24 `signature_audit_log` remote-wins, 24 `signature_files` remote-wins,
  5 `documents` remote-wins, 4 `personnel_types` remote-wins,
  1 `signature_audit_log` local-win, and 1 `signature_files` local-win.
- S21 local Springfield DWSRF still has 131 `bid_items`.
- S21 Sync Dashboard UI run
  `20260419-s21-springfield-pull-echo-after-repair-ui-sync` passed with
  `directDriverSyncEndpointUsed=false`, `runtimeErrors=0`, `loggingGaps=0`,
  queue drained, and no failed actor rounds.

Still open:

- Classify the 59 remaining conflicts before calling the S21 conflict lane
  clean. They are no longer the large pull-echo wave, but they should be
  reviewed or explicitly baselined.
- S10 is still logged in as inspector with zero local/assigned projects. Role
  collaboration stress cannot be accepted until S10 has the shared fixture
  project in scope.

## 2026-04-19 - Supabase cleanup and S10 provider visibility gate

Cleanup result:

- Wrote pre-cleanup inventory:
  `.claude/test-results/2026-04-19/supabase-cleanup/pre-cleanup-inventory.json`.
- Preserved Springfield DWSRF project
  `75ae3283-d4b2-4035-ba2f-7b4adb018199`.
- Soft-deleted six active junk projects through `admin_soft_delete_project`.
- Created disposable test project
  `a3433d2f-11b2-5866-bed8-010f8c41c325`
  (`SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`,
  `SOAK-ROLE-TRAFFIC-20260418`).
- Assigned the four live role accounts from local secrets to the disposable
  project: admin, engineer, inspector, and office technician.
- Seeded the disposable project with two locations, one contractor, one
  equipment row, two bid items, three personnel types, and one inspector-owned
  draft daily entry graph.
- Wrote post-cleanup verification:
  `.claude/test-results/2026-04-19/supabase-cleanup/post-cleanup-verification.json`.
  It shows exactly two active company projects: Springfield DWSRF and the
  disposable soak project.

S21/S10 UI pull after cleanup:

- Ran Sync Dashboard UI flow:
  `20260419-s21-s10-after-supabase-cleanup-seed-ui-pull`.
- Harness summary reported `passed=true`, `queueDrainResult=drained`,
  `runtimeErrors=0`, `loggingGaps=0`, `screenshotsCaptured=6`, and
  `directDriverSyncEndpointUsed=false`.
- This run is **not accepted**. Manual post-run diagnostics showed the harness
  was missing a UI/provider visibility gate:
  - S10 `/driver/local-reconciliation-snapshot?table=projects` had two active
    local projects: Springfield DWSRF and the disposable soak project.
  - S10 `project_assignments` had the expected local assignments.
  - S10 `bid_items` had the disposable project bid items.
  - S10 `/diagnostics/actor_context` still reported `projectCount=0`,
    `activeProjectCount=0`, `myProjectsCount=0`, and
    `companyProjectsCount=0`.

Implementation response:

- Began patching `SyncProviders` so sync completion refreshes
  `ProjectProvider` from local project and assignment tables, not only
  `ProjectSyncHealthProvider`.
- Began expanding `/diagnostics/actor_context` to include project samples so
  the harness can prove which project IDs the provider/UI actually sees.
- Began adding a Sync Dashboard sentinel that fails when local active projects
  exist but `ProjectProvider` reports no visible projects.

Acceptance gate:

- The previous S21/S10 run must remain classified as a caught harness gap.
- The next accepted run must be rebuilt on the patched app and must show local
  SQLite project rows and actor-context provider project samples converging
  after a UI-triggered Sync Dashboard pull.

## 2026-04-19 - Conflict diagnostics and deleted-project residue repair

Provider visibility rerun review:

- Ran S21/S10 Sync Dashboard UI flow:
  `20260419-s21-s10-after-provider-refresh-sentinel-ui-pull`.
- Provider/local visibility was fixed on both devices: actor context project
  samples and local reconciliation samples both included Springfield DWSRF and
  the disposable soak project.
- This run is still **not accepted**. Manual screenshot and data review found
  the S10 Sync Dashboard showing grouped conflict history and S21 carrying
  undismissed `bid_items` conflicts for the soft-deleted junk project
  `465c9311-6e1d-4b41-a019-576a547621dc`.
- The previous dashboard/harness "0 conflicts" result was misleading because
  the user-facing attention count was filtered by
  `sync_conflict_attention_cutoff`. Acceptance now needs a raw undismissed
  conflict-log gate, not only a dashboard cutoff.

What changed:

- `/driver/sync-status` now includes raw `conflict_log` diagnostics:
  total rows, dismissed rows, undismissed physical rows, undismissed logical
  conflict count, grouped counts by table/winner, and recent undismissed
  samples.
- The Sync Dashboard soak flow now runs a conflict sentinel that fails when
  any undismissed conflicts remain, so historical or cutoff-hidden conflict
  residue cannot be misclassified as green.
- Added `repair_sync_state_v2026_04_19_deleted_project_conflicts`, a targeted
  startup repair for cleanup-created tombstone residue. It only dismisses
  remote-wins conflicts when:
  - the local record is already soft-deleted;
  - the owning local `projects` row is already soft-deleted;
  - no pending local `change_log` row exists for that table/record;
  - any `lost_data.project_id` present in the conflict row matches the local
    record project.
- Bumped the local repair catalog to `2026-04-19.2`.

Local evidence:

- `dart analyze lib\features\sync\engine\sync_repair_debug_store.dart lib\features\sync\engine\local_sync_store_metadata.dart lib\features\sync\application\sync_state_repair_runner.dart lib\features\sync\application\repairs\repair_sync_state_v2026_04_19_deleted_project_conflicts.dart test\features\sync\application\sync_state_repair_runner_test.dart`
  passed with no issues.
- `flutter test test\features\sync\application\sync_state_repair_runner_test.dart -r expanded`
  passed 15 tests, including:
  - deleted-project tombstone conflicts are dismissed after convergence;
  - active-project conflicts remain undismissed;
  - pending local work blocks dismissal.
- `flutter test test\core\driver\driver_data_sync_handler_test.dart -r expanded`
  passed 9 tests, including raw conflict diagnostics.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`
  passed 12 test files, including provider visibility and no-undismissed-
  conflicts sentinels.

Still open:

- Rebuild/restart S21 and S10 so the devices run the provider refresh,
  conflict diagnostics, conflict sentinel, and `2026-04-19.2` repair catalog.
- Rerun S21/S10 Sync Dashboard UI pull. Acceptance requires
  `directDriverSyncEndpointUsed=false`, clean runtime/logging state, drained
  queue, provider-visible Springfield + soak project samples, and
  `undismissedConflictCount=0`.
- S10's active-project Springfield signature/document/form conflicts are not
  covered by the deleted-project repair and must still be classified or
  explicitly reviewed before role seam traffic is accepted.

## 2026-04-19 - Semantic timestamp conflict hardening

Conflict classification:

- The remaining active S21/S10 conflict rows were classified before accepting
  another UI pull gate.
- Most active `documents`, `signature_files`, and `signature_audit_log`
  conflicts were not role-bleed or legitimate multi-user edit conflicts. They
  were semantic no-ops: the current local row and remote row matched, while
  `lost_data` retained equivalent timestamp instants rendered with different
  offsets (`+00:00` versus `-04:00`).
- Remaining local-missing/remote-tombstone rows, including some
  `personnel_types`, `documents`, and `form_responses`, are still review
  candidates and are not covered by the semantic repair.

What changed:

- `ConflictResolver` now compares parseable timestamp strings as UTC instants
  before selecting the LWW winner.
- `ConflictResolver` now computes `lost_data` with semantic timestamp
  equality, so equivalent offset strings do not create noisy diffs.
- If a conflict diff has no real changed field after semantic comparison, the
  resolver returns the deterministic winner without inserting a `conflict_log`
  row.
- Added `repair_sync_state_v2026_04_19_semantic_conflicts`, a conservative
  startup repair that dismisses only existing undismissed conflicts whose
  `lost_data` currently matches the local row semantically and whose record has
  no pending local `change_log` work.
- Bumped the repair catalog to `2026-04-19.3`.

Local evidence:

- `dart analyze lib\features\sync\engine\conflict_resolver.dart lib\features\sync\engine\sync_repair_debug_store.dart lib\features\sync\engine\local_sync_store_metadata.dart lib\features\sync\application\sync_state_repair_runner.dart lib\features\sync\application\repairs\repair_sync_state_v2026_04_19_semantic_conflicts.dart lib\features\sync\application\repairs\repair_sync_state_v2026_04_19_deleted_project_conflicts.dart test\features\sync\engine\conflict_clock_skew_test.dart test\features\sync\application\sync_state_repair_runner_test.dart`
  passed with no issues.
- `flutter test test\features\sync\engine\conflict_resolver_domain_policy_test.dart test\features\sync\engine\conflict_clock_skew_test.dart test\features\sync\engine\conflict_resolver_test.dart test\features\sync\application\sync_state_repair_runner_test.dart -r expanded`
  passed 54 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 12 test
  files.
- `git diff --check` passed, with line-ending warnings only.

Still open:

- Rebuild/restart S21 and S10 so the devices run repair catalog
  `2026-04-19.3`.
- Re-query `/driver/sync-status` on both devices and verify whether the
  semantic repair dismisses the timestamp-only rows.
- Explicitly classify any remaining local-missing/remote-tombstone conflict
  residue before the raw conflict sentinel can pass.
- Only after both devices report `undismissedConflictCount=0`, rerun the
  S21/S10 Sync Dashboard UI pull and accept it only with UI-triggered sync,
  no direct driver sync endpoint, clean queue/runtime/logging state, provider
  project samples, screenshots, and debug evidence.

## 2026-04-19 - Cleanup/visibility/conflict gate accepted

Device rebuild:

- Rebuilt/reinstalled S21 `RFCNC0Y975L` on driver port `4968` with the patched
  app and repair catalog `2026-04-19.3`.
- Rebuilt/reinstalled S10 `R52X90378YB` on driver port `4949` with the patched
  app and repair catalog `2026-04-19.3`.
- Restored device debug-log reverse and driver forwards before probing.

Post-repair status:

- Wrote status artifacts:
  `.claude/test-results/2026-04-19/post-semantic-repair-status/S21-status.json`
  and
  `.claude/test-results/2026-04-19/post-semantic-repair-status/S10-status.json`.
- S21: project provider saw two active projects, queues were clean, and
  semantic repair reduced undismissed conflicts from 59 to 6.
- S10: project provider saw two active projects, queues were clean, and
  semantic repair reduced undismissed conflicts from 54 to 6.

Remaining conflict classification:

- Wrote per-record review artifacts:
  `.claude/test-results/2026-04-19/remaining-conflict-review/S21-remaining-conflicts.json`
  and
  `.claude/test-results/2026-04-19/remaining-conflict-review/S10-remaining-conflicts.json`.
- S21 six-row residue:
  - four `personnel_types` rows: local missing, remote already soft-deleted,
    stale lost-data preserved active payload;
  - one `signature_files` and one `signature_audit_log` row: local and remote
    both already soft-deleted.
- S10 six-row residue:
  - three `documents` rows: local missing, remote already soft-deleted;
  - one `signature_files` and one `signature_audit_log` row: local and remote
    both already soft-deleted;
  - one `form_responses` row was different and remained active remotely while
    missing locally, so it was not dismissed as cleanup residue.

Reviewed UI dismissal:

- Used the app's Conflict Viewer UI, not direct SQLite updates, to dismiss
  reviewed historical tombstone residue. Screenshots and status artifacts live
  under:
  `.claude/test-results/2026-04-19/reviewed-conflict-ui-dismissal/`.
- Dismissed S21 conflict ids: `950`, `949`, `942`, `941`, `940`, `939`.
- Dismissed S10 tombstone conflict ids: `374`, `373`, `372`, `369`, `368`.
- Forced an integrity check on S10 and ran diagnostic UI sync:
  `20260419-s10-active-form-response-repull-diagnostic`.
  It failed correctly on the raw conflict sentinel, but proved the active
  remote `form_responses/966c6f36-e434-4873-801c-9dac71201ad7` row became
  locally visible through the server/pull path with clean queue/runtime/logging
  evidence.
- After local visibility proof, dismissed reviewed S10 conflict id `234`
  through the Conflict Viewer UI. S10 then reported
  `undismissedConflictCount=0`.

Accepted gate:

- Accepted two-device cleanup/visibility/conflict sentinel run:
  `20260419-s21-s10-cleanup-visibility-conflict-sentinel-accepted`.
- Summary:
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=6`;
  - `triggeredThroughUi=true` in both actor measurements;
  - `directDriverSyncEndpointUsed=false`;
  - raw conflict sentinels passed on S21 and S10 with
    `undismissedConflictCount=0`;
  - project-provider/local visibility sentinels passed on S21 and S10 with
    Springfield DWSRF plus the disposable soak project in provider samples.

Open next:

- Resume role seam hardening on the disposable project:
  `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`
  (`a3433d2f-11b2-5866-bed8-010f8c41c325`).
- The next role run must use separate real accounts/devices and must prove
  per-record remote write, server/pull local visibility, clean raw conflicts,
  clean logs/screenshots, and no role/project/provider bleed-through.

## 2026-04-19 - Role-collaboration first failure classified and patched

Live failure reviewed:

- Ran `role-collaboration-stress-only` with S10 as inspector and S21 as
  office technician:
  `20260419-s10-s21-role-collaboration-soak-project-initial`.
- The run is **not accepted**. It failed on
  `role-collab-inspector-entry-navigate-report` while waiting for
  `entry_editor_scroll`.
- Raw log review showed the missing scroll key was a symptom, not the root
  cause. S10 logcat captured:
  `Invalid argument (name): No enum value with that name: "Clear"` from
  `DailyEntry.fromMap` while loading
  `daily_entries/743eb51d-8ff9-5a82-b291-ca3a7c977c40`.
- Because the editor load threw before `EntryEditorBody` mounted, the driver
  saw only the screen root/loading state and timed out on the scrollable.

What changed:

- `DailyEntry.fromMap` now parses stored weather values through
  `DailyEntry.parseWeatherCondition` instead of throwing on
  `WeatherCondition.values.byName`.
- The parser accepts canonical enum names plus current weather-service display
  strings such as `Clear`, `Partly Cloudy`, `Foggy`, `Drizzle`, `Rain`,
  `Snow`, and `Thunderstorm`.
- `EntryEditorRuntimeHelpers.autoFetchWeather` now reuses the same parser so
  persisted API weather labels and local enum names cannot drift again.
- Added regression coverage that `weather: "Clear"` deserializes as
  `WeatherCondition.sunny` and unknown weather values are treated as absent
  data instead of crashing the editor.

Local evidence:

- `dart analyze lib\features\entries\data\models\daily_entry.dart lib\features\entries\presentation\screens\entry_editor_runtime_helpers.dart test\data\models\daily_entry_test.dart`
  passed with no issues.
- `flutter test test\data\models\daily_entry_test.dart -r expanded` passed
  14 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 12 test
  files.
- `git diff --check` passed with line-ending warnings only.

Open next:

- Rebuild/restart S10 and S21 with this patch.
- Rerun the role-collaboration flow and require real inspector write,
  office-technician pull/review, inspector final pull, per-record remote/local
  proof through the server/pull path, raw conflict cleanliness, and
  runtime/logging/screenshot review before accepting the role seam.

## 2026-04-19 - Role pull-convergence conflict hardening

Live failure reviewed:

- Rebuilt/restarted S10 `R52X90378YB` and S21 `RFCNC0Y975L` with the weather
  parser patch, restored driver forwards and debug-log reverses, and verified
  the S10 editor mounted `entry_editor_scroll` for
  `daily_entries/743eb51d-8ff9-5a82-b291-ca3a7c977c40`.
- Ran `role-collaboration-stress-only` with S10 as inspector and S21 as
  office technician:
  `20260419-s10-s21-role-collaboration-after-weather-parser`.
- The run is **not accepted**. It failed with
  `Office technician collaboration pull failed: unknown_sync_measurement_failure`.
- The weather crash was fixed. S10 completed the inspector edit and UI sync,
  and the remote `daily_entries/743eb51d-8ff9-5a82-b291-ca3a7c977c40` row
  contained the inspector activity marker.
- S21 then pulled the inspector update through the UI path but created an
  undismissed `conflict_log` row for the same `daily_entries` record. S21 had
  no pending local `change_log` work for that record, so this was normal
  stale-local convergence being misclassified as a conflict.
- The final summary correctly failed the run:
  `queueDrainResult=residue_detected`, `unprocessedRowCount=1`,
  `runtimeErrors=0`, `loggingGaps=0`, `screenshotsCaptured=10`, and
  `directDriverSyncEndpointUsed=false`.

What changed:

- Added `ChangeTracker.hasPendingRecordChange(tableName, recordId)`.
- Updated `PullRecordApplicator` so an existing local row with a different
  `updated_at` is only sent to `ConflictResolver` when this device has an
  unprocessed local `change_log` row for that same table and record.
- If there is no pending local work, pull now applies the remote row as normal
  convergence and logs:
  `Pull remote update accepted without conflict (no pending local change)`.
- Remote-authoritative overwrite and remote-wins conflict paths now share the
  same helper for file-cache invalidation, local row update, and deletion
  notification behavior.
- Added PullHandler regression coverage proving a remote update from another
  device applies without inserting `conflict_log` when the receiver has no
  pending local change.
- Adjusted the local-wins re-push and circuit-breaker tests to seed an actual
  pending local `change_log` row before expecting conflict behavior.

Local evidence:

- `dart analyze lib\features\sync\engine\change_tracker.dart lib\features\sync\engine\pull_record_applicator.dart test\features\sync\engine\pull_handler_test.dart`
  passed with no issues.
- `flutter test test\features\sync\engine\pull_handler_test.dart -r expanded`
  passed 24 tests.
- `flutter test test\features\sync\engine\sync_engine_e2e_test.dart -r expanded`
  passed 24 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 12 test
  files.
- `git diff --check` passed with line-ending warnings only.

Open next:

- Rebuild/restart S10 and S21 with the pull-classifier patch.
- Recover the reviewed residue from the failed run without hiding it:
  S10 has one unprocessed `daily_entries` cleanup row, and S21 has the reviewed
  stale remote-wins conflict for `daily_entries/743eb51d-8ff9-5a82-b291-ca3a7c977c40`.
- Rerun `role-collaboration-stress-only` and require inspector remote write
  proof, office-technician server/pull local visibility, office-technician
  review write proof, inspector final pull visibility, raw conflict
  cleanliness, clean logs/screenshots, and no role/project/provider
  bleed-through before accepting the role seam.

## 2026-04-19 - Inspector/office daily-entry role seam accepted

Device reruns and failures preserved:

- Rebuilt S10 and S21 with the pull-classifier patch.
- Dismissed the historical S21 stale remote-wins conflict through the app's
  Conflict Viewer UI after confirming local/remote convergence and no pending
  local work. Artifacts:
  `.claude/test-results/2026-04-19/reviewed-stale-role-conflict-dismissal/`.
- Reran role collaboration:
  `20260419-s10-s21-role-collaboration-after-pull-classifier`.
  This is **not accepted**. The no-pending-local conflict was gone, but S21
  failed on `runtime_log_error` while saving the office review-comment dialog:
  Flutter logged a `Duplicate GlobalKey` / `InheritedGoRouter` assertion. The
  failed attempt left one real `todo_items` insert, which was not ignored.
- Patched the dialog save path to release text focus before popping and ran:
  `20260419-s10-s21-role-collaboration-after-review-dialog-focus-fix`.
  This is also **not accepted**. It still failed with the same
  `Duplicate GlobalKey` route/runtime signature.
- Classified the route timing: the review-comment dialog was opened directly
  from the report popup-menu selection path, so popup-route teardown and dialog
  route focus/keyboard changes could overlap under GoRouter.

What changed:

- `EntryEditorAppBar` now delays `onReviewComment` by one theme animation
  after the popup-menu item is selected, so the popup route has finished
  tearing down before the dialog route is pushed.
- `EntryEditorReviewComment` and the entry review screen now release text
  focus and yield a frame before popping/saving review-comment dialogs.

Local evidence:

- `dart analyze lib\features\entries\presentation\widgets\entry_editor_app_bar.dart lib\features\entries\presentation\screens\entry_editor_review_comment.dart lib\features\entries\presentation\screens\entry_review_screen.dart`
  passed with no issues.
- `flutter test test\core\driver\root_sentinel_entry_form_widget_test.dart -r expanded`
  passed 2 tests.
- `git diff --check` passed with line-ending warnings only.

Residue cleanup:

- Soft-deleted failed-run review todo
  `todo_items/33a8316e-1ec8-4f24-83a1-66fe1bbc799e`, then ran UI sync-only
  recovery:
  `20260419-s21-s10-cleanup-after-review-dialog-runtime-failure`.
- Soft-deleted failed-run review todo
  `todo_items/981fc280-5f26-459b-8df6-c5fd874f3dfc`, then ran UI sync-only
  recovery:
  `20260419-s21-s10-cleanup-after-review-popup-route-fix`.
- Both recovery runs passed with UI-triggered sync, drained queues, zero raw
  undismissed conflicts, and no direct `/driver/sync` use.

Accepted role seam:

- Accepted S10 inspector + S21 office-technician role-collaboration run:
  `20260419-s10-s21-role-collaboration-after-popup-route-delay`.
- Summary:
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=20`;
  - `directDriverSyncEndpointUsed=false`.
- Proof highlights:
  - S10 inspector wrote daily-entry activity marker
    `role-collab inspector activity S10 round 1 022328`.
  - Inspector UI sync produced remote `daily_entries` proof for
    `743eb51d-8ff9-5a82-b291-ca3a7c977c40`.
  - S21 office technician pulled through Sync Dashboard UI and saw the
    inspector marker locally without generating conflict residue.
  - S21 created review todo `todo_items/c7dbc777-bd9d-4b26-a73a-ea99b04c681f`
    with `created_by_user_id=d1ca900e-d880-4915-9950-e29ba180b028` and
    `assigned_to_user_id=6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`.
  - S21 UI sync produced remote `todo_items` proof.
  - S10 inspector final UI pull proved the office-created review todo was
    locally visible to the assigned inspector.
  - Ledger cleanup soft-deleted the review todo and restored the daily-entry
    activity text; final S10/S21 `/driver/sync-status` showed zero pending,
    zero blocked, zero unprocessed, and zero undismissed conflicts.

Open next:

- The accepted artifact closes only the first inspector/office daily-entry and
  review-comment collaboration seam. Broader role hardening remains open:
  allowed quantity/photo/document/form actions, denied role UI/actions,
  Supabase/RLS denial probes, storage/local placement, and admin/engineer
  visibility.
- Four-account emulator/headless expansion should wait until the next
  physical-device role-denial/storage seams are similarly clean, or be used
  only as additive signal with separate artifacts.

## 2026-04-19 - Strict inspector/office role sweep accepted

Live failures preserved:

- Ran S10 inspector + S21 office-technician `role-sweep-only` after the
  accepted collaboration seam:
  `20260419-s10-s21-role-sweep-inspector-office-physical`.
  The harness returned green, but manual artifact review found S21 provider
  state contained an extra blank project ID after the `/project/new` route
  check while local active `projects` still contained only Springfield plus
  the disposable soak project. This run is **not accepted**.
- Hardened `Assert-SoakProjectProviderLocalVisibilitySentinel` to require
  provider/local active project count equality and to fail on
  `providerOnlyIds`.
- Reran strict role sweeps:
  `20260419-s10-s21-role-sweep-inspector-office-provider-strict`,
  `20260419-s10-s21-role-sweep-inspector-office-provider-repaired`, and
  `20260419-s10-s21-role-sweep-inspector-office-sync-surface-repaired`.
  All are **not accepted**. They correctly failed on provider-only blank draft
  project IDs at the final sync acceptance point. Queues, raw undismissed
  conflicts, runtime errors, and logging gaps were clean; the defect was stale
  provider/project scope.

What changed:

- `ProjectProvider.discardDraft` already had been repaired to remove discarded
  drafts from in-memory provider state, not only from the repository.
- `ProjectSetupController.discardDraft` now records discard intent before a
  draft row exists. If the eager suppressed draft insert completes after a
  direct route replacement has begun, the controller immediately discards that
  draft instead of leaving it visible in provider state.
- `ProjectSetupScreen.dispose` now calls
  `discardBlankDraftIfNeeded()` so blank new-project routes are cleaned up
  even when driver or app navigation uses direct `router.go()` and bypasses
  `ProjectSetupBackHandler`.
- Added controller regression coverage for inserted blank drafts, typed drafts
  that must be preserved, and the in-flight eager-insert discard race.

Local evidence:

- `dart analyze lib\features\projects\presentation\controllers\project_setup_controller.dart lib\features\projects\presentation\screens\project_setup_screen.dart test\features\projects\presentation\controllers\project_setup_controller_test.dart`
  passed with no issues.
- `flutter test test\features\projects\presentation\controllers\project_setup_controller_test.dart -r expanded`
  passed 3 tests.
- `flutter test test\features\projects\presentation\providers\project_provider_test.dart -r expanded`
  passed 18 tests.
- `flutter test test\core\driver\root_sentinel_project_widget_test.dart -r expanded`
  passed 1 test.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 12 test
  files.
- `git diff --check` passed with line-ending warnings only.

Accepted device evidence:

- Rebuilt/restarted S21 `RFCNC0Y975L` on port `4968` and S10 `R52X90378YB`
  on port `4949`, restored S21 ADB reverse/forward, and verified both drivers
  ready.
- Pre-run actor context:
  - S10 resolved to inspector
    `6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`;
  - S21 resolved to office technician
    `d1ca900e-d880-4915-9950-e29ba180b028`;
  - both were in company `26fe92cd-7044-4412-9a09-5c5f49a292f9`;
  - both exposed only Springfield DWSRF plus
    `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`;
  - both had zero pending, blocked, unprocessed, and undismissed conflict
    rows.
- Accepted S10/S21 role sweep:
  `20260419-s10-s21-role-sweep-inspector-office-draft-dispose-cleanup`.
- Summary:
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=16`;
  - `logsCaptured=18`;
  - `debugServerEvidenceCaptured=18`;
  - `adbLogcatEvidenceCaptured=18`;
  - `directDriverSyncEndpointUsed=false`.
- S10 inspector proof:
  admin dashboard, trash, `/project/new`, project-create control, pay-app
  detail, and PDF import probes were denied or hidden as expected.
- S21 office-technician proof:
  admin dashboard and trash were denied; `/project/new` and project-create
  control were visible/allowed as expected. Logcat captured:
  `Draft discarded: d310380b-578a-48de-ab4a-03c91c9d7e70`.
- Final provider/local project proof:
  - S10 and S21 `projectVisibilitySentinel.passed=true`;
  - local active project snapshots had `totalCount=2`;
  - provider project IDs matched Springfield plus the disposable soak project;
  - `providerOnlyIds=[]` on both devices;
  - direct post-run `/driver/local-reconciliation-snapshot` confirmed both
    devices still had only those two active project rows.

Open next:

- Expand role seam hardening beyond route/project visibility: inspector
  quantity/photo/document/form actions, office-technician review/edit scope,
  storage bucket/path/local-cache placement, Supabase/RLS denial probes with
  real anon tokens, and admin/engineer same-project visibility.
- Keep four-account emulator/headless expansion additive until the physical
  role seams are clean enough to use as the reference behavior.

## 2026-04-19 - Inspector/office document storage seam accepted after fail-loud fix

Rejected diagnostic run:

- Ran S10 inspector -> S21 office-technician `documents-cross-device-only`:
  `20260419-s10-s21-inspector-office-document-storage-cross-device`.
  The summary was green, but raw S21 adb logcat showed a real UI flow failure
  when opening the pulled document tile:
  `_openDocument error: PlatformException(android.os.FileUriExposedException...)`.
  This run is **not accepted**. The defect mattered for two reasons: Android
  was exposing an app-private `file://` URI, and the harness summary missed the
  failure because it was logged as a UI info line rather than a runtime/error
  signal.

What changed:

- `EntryDocumentsSubsection` now opens Android documents through a platform
  channel instead of handing `url_launcher` an app-private `file://` URI.
- Android registers an app `FileProvider` scoped to cache
  `document_open/`, copies the private document to that share cache path,
  builds a content URI, and grants read permission to the external viewer.
- Document-open failures are now logged through `Logger.error` so the next
  occurrence is visible to raw log/error gates instead of being hidden as a UI
  info line.

Local evidence:

- `dart analyze lib\features\entries\presentation\widgets\entry_documents_subsection.dart test\features\entries\presentation\widgets\entry_forms_section_test.dart`
  passed with no issues.
- `flutter test test\features\entries\presentation\widgets\entry_forms_section_test.dart -r expanded`
  passed 7 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 12 test
  files.
- `android\gradlew.bat :app:assembleDebug` passed.
- `git diff --check` passed with line-ending warnings only.

Accepted device evidence:

- Rebuilt/restarted S21 and S10 with the FileProvider patch, restored S21
  ADB reverse/forward, and verified both drivers ready.
- Pre-run state was clean on both devices: correct role contexts, only
  Springfield plus `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK` visible as
  active projects, and zero pending, blocked, unprocessed, or undismissed
  conflict rows.
- Accepted S10/S21 document/storage seam:
  `20260419-s10-s21-inspector-office-document-storage-fileprovider`.
- Summary:
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=14`;
  - `logsCaptured=18`;
  - `debugServerEvidenceCaptured=18`;
  - `adbLogcatEvidenceCaptured=18`;
  - `directDriverSyncEndpointUsed=false`.
- Proof highlights:
  - S10 inspector created document
    `documents/7327af1b-953c-49aa-9000-57cb3cb3db9e` for entry
    `743eb51d-8ff9-5a82-b291-ca3a7c977c40` on project
    `a3433d2f-11b2-5866-bed8-010f8c41c325`.
  - S10 UI sync produced remote row proof with `file_type=pdf`, `file_size=48`,
    `deleted_at=null`, and remote path
    `docs/26fe92cd-7044-4412-9a09-5c5f49a292f9/743eb51d-8ff9-5a82-b291-ca3a7c977c40/enterprise_soak_cross_device_doc_S10_to_S21_round_1_025942.pdf`.
  - Authorized storage proof for bucket `entry-documents` returned 48 bytes,
    HTTP 200, SHA-256
    `d7aacd14db7ca489d86ca71c834ac5513f54cbfbab168d7929c086b6a7e61dc6`.
  - Unauthorized storage proof returned denied/not-found shape for the same
    bucket/path and passed the configured denial classifier.
  - S21 office-technician pulled through the Sync Dashboard UI, tapped the
    pulled document tile, and cached a local file under the soak project/entry
    path. `/driver/local-file-head` returned the same 48-byte size and SHA-256
    as the storage proof.
  - Cleanup soft-deleted the document with
    `deleted_by=6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`, deleted the storage
    object, proved storage absence, and S21 pulled the deletion through the UI.
- Raw artifact review:
  - no `_openDocument error`;
  - no `FileUriExposedException`;
  - no app-specific runtime/error signatures such as `runtime_log_error`,
    `RenderFlex`, overflow, or duplicate `GlobalKey`;
  - direct sync endpoint remained unused.

Open next:

- Photos and forms still need the same S10 inspector -> S21
  office-technician remote-write/pull/local-visibility/cleanup proof.
- RLS denial probes with real non-admin anon sessions remain open.
- Admin and engineer same-project visibility and permission differences remain
  open.

## 2026-04-19 - Inspector/office quantity seam accepted

What changed:

- Added `quantity-cross-device-only` to the refactored soak flow set.
- The new flow requires an inspector source actor and an office-technician
  receiver actor, records distinct real user/company context, creates the
  quantity through the source UI, syncs through Sync Dashboard, proves the
  remote `entry_quantities` row, pulls through the receiver Sync Dashboard,
  proves receiver local visibility, then performs ledger-owned cleanup and
  receiver cleanup pull.
- Added harness wiring coverage so the flow must stay reachable from
  `enterprise-sync-soak-lab.ps1`, the refactored dispatcher, and the module
  loader, and must retain source remote proof, receiver pull proof, cleanup
  pull, and no direct sync endpoint use.

Local evidence:

- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 12 test
  files.
- `git diff --check` passed with line-ending warnings only.

Accepted device evidence:

- Pre-run `/driver/sync-status` was clean on both devices:
  - S10: zero pending, blocked, unprocessed, and undismissed conflict rows;
  - S21: zero pending, blocked, unprocessed, and undismissed conflict rows.
- Accepted S10/S21 quantity seam:
  `20260419-s10-s21-inspector-office-quantity-cross-device`.
- Summary:
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=13`;
  - `logsCaptured=18`;
  - `debugServerEvidenceCaptured=18`;
  - `adbLogcatEvidenceCaptured=18`;
  - `directDriverSyncEndpointUsed=false`.
- Proof highlights:
  - S10 inspector created
    `entry_quantities/f2efafa7-6987-4854-9e79-4a775f6b610a` for entry
    `743eb51d-8ff9-5a82-b291-ca3a7c977c40`, project
    `a3433d2f-11b2-5866-bed8-010f8c41c325`, bid item
    `b40c3b0b-7f1e-5a5b-9ca4-2749a95d248d`, quantity `3.0`, notes
    `role quantity cross-device S10 to S21 round 1 030819`.
  - S10 UI sync produced remote row proof with
    `created_by_user_id=6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`,
    matching project/entry/bid item/quantity/notes, and `deleted_at=null`.
  - S21 office technician pulled through Sync Dashboard UI and local
    `entry_quantities/f2efafa7-6987-4854-9e79-4a775f6b610a` matched the
    source project, entry, bid item, quantity, notes, and inspector creator.
  - S10 cleanup soft-deleted the quantity with
    `deleted_by=6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`, synced through the UI,
    and proved the remote soft-delete.
  - S21 pulled cleanup through Sync Dashboard UI and local
    `receiverDeletedProof` showed the same row soft-deleted.
  - Post-run live `/driver/sync-status` on S10 and S21 remained at zero
    pending, blocked, unprocessed, and undismissed conflict rows.
  - Direct local project reconciliation after the run showed both devices
    still had exactly two active projects: Springfield DWSRF and
    `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`.
  - App-specific raw log scan found no `I/flutter [ERROR]`, `E/flutter`,
    `AndroidRuntime`, `PlatformException`, `RenderFlex` overflow, duplicate
    `GlobalKey`, or document-open signatures.

Open next:

- Photos and forms still need the same S10 inspector -> S21 office-technician
  remote-write/pull/local-visibility/cleanup proof. Photo is currently in
  rerun after fixing receiver local-cache proof.
- RLS denial probes with real non-admin anon sessions remain open.
- Admin and engineer same-project visibility and permission differences remain
  open.

## 2026-04-19 - Photo seam rejected twice, local-cache fix in progress

Rejected runs:

- `20260419-s10-s21-inspector-office-photo-cross-device` was **not
  accepted**. S10 inspector created, synced, and cleaned up the photo row/object,
  but proof failed because `/driver/local-file-head` did not support the
  `photos` table.
- `20260419-s10-s21-inspector-office-photo-cross-device-local-file-head-photos`
  was also **not accepted**. The new driver route worked, S10 created
  `photos/2c294d6e-ff13-415c-926f-d83df0297f53`, storage proof returned 68
  bytes with SHA-256
  `1dae93d61eceabd7ce356b2be0acf0d2b813bf595f5cbae775a88582fd4ad278`, S21
  pulled the row and opened the photo UI, but S21's `photos.file_path` stayed
  null. That means the receiver had metadata visibility but no durable local
  cached file to prove against storage.

Cleanup evidence:

- `20260419-s21-cleanup-after-photo-cross-device-local-file-head-gap` pulled the
  first failed-run cleanup on S21 through Sync Dashboard UI. The row
  `photos/73eba1b3-86cb-48f2-8949-93f72651d4ed` is locally soft-deleted and
  S21 has zero pending, blocked, unprocessed, or undismissed conflict rows.
- The second failed run cleaned up on S10, but S21 still needs a cleanup pull
  after the next rebuild before another accepted photo attempt.

What changed:

- `/driver/local-file-head` now supports `photos.file_path`.
- `SyncFileAccessService` now exposes `downloadEntryPhoto()`.
- `PhotoService.ensureLocalPhoto()` downloads remote-backed photos from
  `entry-photos`, writes an app-local cache file, and stores `photos.file_path`
  through a trigger-suppressed repository method.
- `PhotoThumbnail` now lazily calls `ensureLocalPhoto()` when the local path is
  missing but `remote_path` exists, so UI-open proof can also produce durable
  local-file proof.

Local evidence:

- Focused `dart analyze` on the photo cache path passed with no issues.
- `flutter test test\services\photo_service_test.dart test\features\photos\presentation\providers\photo_provider_count_test.dart -r expanded`
  passed 21 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 12 test
  files.
- `git diff --check` passed with line-ending warnings only.

## 2026-04-19 - Inspector/office photo seam accepted after visual fail-loud hardening

Device recovery and rejected evidence:

- S10 initially returned premature/empty driver responses after the photo cache
  patch install. Relaunch through `tools\start-driver.ps1` rebuilt/reinstalled
  the current debug APK and restored S10 on `/projects` as inspector with clean
  queue/conflict state.
- S21 then lost its ADB forward when restoring the two-device lab. Manual
  forward restoration proved the app was still alive; this was transport
  instability, not an app crash.
- `20260419-s21-cleanup-after-photo-cache-gap` pulled the prior rejected photo
  cleanup on S21 through Sync Dashboard UI. Local
  `photos/2c294d6e-ff13-415c-926f-d83df0297f53` is soft-deleted and S21 had
  zero pending, blocked, unprocessed, or undismissed conflict rows.
- `20260419-s10-s21-inspector-office-photo-cross-device-local-cache` proved the
  app-side local-cache fix worked: S21 downloaded
  `photos/ca435e95-9f5f-4a66-ba46-a17775621e27`, and local-file-head matched
  the 68-byte storage SHA-256. The run was rejected because S21's ADB forward
  disappeared before final receiver cleanup proof.
- `20260419-s10-s21-inspector-office-photo-cross-device-local-cache-forward-retry`
  passed byte proof and cleanup after harness forward-retry hardening, but
  screenshot review showed the S21 thumbnail still rendered `Image unavailable`.
  That run is rejected as a visual/UI proof failure.

What changed:

- `DriverClient.ps1` now treats connection refused / premature response end as
  retryable transport failures, restores the actor's ADB forward from the cached
  Android device-state mapping, and retries once before failing with structured
  restore details.
- `Flow.Photo.ps1` now injects a real decodable JPEG test image instead of a
  68-byte PNG renamed to `.jpg`.
- `WidgetTreeClassifier.ps1` and `EvidenceBundle.ps1` now classify
  `photo_missing_image_*` / `Image unavailable` as a runtime/UI defect, so a
  future green summary cannot hide a missing photo thumbnail.

Local evidence:

- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 13 test
  files, including the new driver-forward retry contract and missing-image
  widget-tree classification.
- `git diff --check` passed with line-ending warnings only.

Accepted device evidence:

- Accepted S10 inspector -> S21 office-technician photo/storage/local-cache/
  visual seam:
  `20260419-s10-s21-inspector-office-photo-cross-device-real-jpeg-visual-gate`.
- Summary:
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=15`;
  - `logsCaptured=19`;
  - `debugServerEvidenceCaptured=19`;
  - `adbLogcatEvidenceCaptured=19`;
  - `directDriverSyncEndpointUsed=false`.
- Proof highlights:
  - S10 inspector created
    `photos/539b8816-b31e-4ffb-9930-357d8cd01817` for entry
    `743eb51d-8ff9-5a82-b291-ca3a7c977c40`, project
    `a3433d2f-11b2-5866-bed8-010f8c41c325`.
  - S10 UI sync produced remote row proof with
    `created_by_user_id=6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`,
    `deleted_at=null`, and remote path
    `entries/26fe92cd-7044-4412-9a09-5c5f49a292f9/743eb51d-8ff9-5a82-b291-ca3a7c977c40/role_photo_cross_S10_to_S21_round_1_035244.jpg`.
  - Authorized storage proof for bucket `entry-photos` returned 841 bytes,
    HTTP 200, SHA-256
    `59727940411ccb79f860aeb581f233a985051dc01fe020f920e81df2187af4b9`.
  - Unauthorized storage proof for the same bucket/path passed the invalid
    bearer denial classifier.
  - S21 office technician pulled through Sync Dashboard UI, opened the photo
    thumbnail, and cached a local file under the app photo cache path.
    `/driver/local-file-head?table=photos&sha256=true` returned the same
    841-byte size and SHA-256 as the storage proof.
  - Manual screenshot review of
    `S21\steps\step-004-photo-cross-receiver-open-open-photo-thumbnail-after.png`
    showed an actual rendered photo thumbnail, not `Image unavailable`.
  - S10 cleanup soft-deleted the photo, deleted the storage object, proved
    storage absence, and S21 pulled the deletion through Sync Dashboard UI.
    S21 local `receiverDeletedProof` showed the row soft-deleted by the
    inspector.
- Raw artifact review:
  - no `photo_missing_image_visible`, `Image unavailable`, or
    `photo_missing_image_*` hits;
  - no app-specific runtime/error signatures such as `I/flutter [ERROR]`,
    `E/flutter`, `AndroidRuntime`, `PlatformException`, `RenderFlex`
    overflow, duplicate `GlobalKey`, or `FileUriExposedException`;
  - final live `/driver/sync-status` on S10 and S21 remained at zero pending,
    blocked, unprocessed, and undismissed conflict rows.

Open next:

- Forms remain open in the inspector -> office-technician role traffic seam.
- Broader office review/edit scope, inspector final pull of office changes,
  real non-admin RLS denial probes, admin/engineer same-project visibility, and
  scale soak remain open.

## 2026-04-19 - MDOT 0582B cross-device form false-conflict hardening

Rejected device evidence:

- `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form` is **not
  accepted**.
- It used the correct evidence surface (`directDriverSyncEndpointUsed=false`)
  and S10 ended with zero pending/blocked/unprocessed rows, but the source
  Sync Dashboard proof failed on five undismissed `form_responses` conflicts.
- Artifact review showed this was not cross-role bleed-through. S10 created
  one MDOT 0582B `form_responses/8825e27f-b7ae-418a-8163-c92a9663c5a6`, then
  produced one insert plus five update `change_log` rows while filling the
  form. The first queued row pushed the current local form state; the remaining
  duplicate rows ran the LWW pre-check against the just-written remote row and
  logged false remote-wins conflicts.
- The false conflicts were visible only because the new raw conflict sentinel
  rejects undismissed `conflict_log` rows even when the app says sync is idle.

What changed:

- `PushTablePlanner` now coalesces superseded local `change_log` rows for the
  same table/record before remote I/O. The latest queued change still executes,
  while older local burst rows are marked processed with an explicit
  `Push coalesced superseded local change` sync log line.
- `InspectorFormProvider.createResponse` now stamps missing
  `created_by_user_id` from the real current session before saving the local
  form response, so role ownership proof is present locally and remotely.

Local evidence:

- `dart analyze lib\features\sync\engine\push_table_planner.dart lib\features\sync\engine\push_handler.dart lib\features\forms\presentation\providers\inspector_form_provider_response_actions.dart test\features\sync\engine\push_handler_test.dart test\features\forms\presentation\providers\inspector_form_provider_test.dart`
  passed with no issues.
- `flutter test test\features\sync\engine\push_handler_test.dart test\features\forms\presentation\providers\inspector_form_provider_test.dart -r expanded`
  passed 21 tests.

Open next:

- Clean or dismiss the rejected-run S10 form conflict residue through a
  reviewed path, rebuild/restart S10 and S21, and rerun
  `mdot0582b-cross-device-only` until it proves source remote write, S21
  pull/local UI-open visibility, cleanup, raw conflict cleanliness, and
  `directDriverSyncEndpointUsed=false`.

## 2026-04-19 - MDOT 0582B duplicate-change rerun rejected on stale route sentinel

Rejected device evidence:

- `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form-after-coalescing`
  is **not accepted**.
- The app-side duplicate-change hardening held under real UI sync:
  S10 started with six pending `form_responses` rows for one MDOT 0582B
  response, synced through Sync Dashboard only, ended with zero pending,
  blocked, unprocessed, and undismissed conflict rows, and
  `directDriverSyncEndpointUsed=false`.
- S21 office technician pulled the form through Sync Dashboard UI, local proof
  matched the expected header/proctor/test-row markers, and screenshot review
  of `S21\steps\step-004-mdot0582b-cross-receiver-open-attached-form-after.png`
  showed real MDOT 0582B content with `mdot_hub_screen`.
- The failure was a harness contract defect: `Flow.Mdot0582B.ps1` expected
  `/form-fill/<responseId>`, but the app route registry and live route are
  `/form/<responseId>`.

What changed:

- `Invoke-SoakMdot0582BOpenAttachedForm` now asserts
  `/form/<responseId>` while still requiring `mdot_hub_screen`.
- `FlowWiring.Tests.ps1` now checks that the MDOT 0582B cross-device flow
  contains the `/form/<responseId>` sentinel contract.

Open next:

- Run the harness self-tests, then rerun `mdot0582b-cross-device-only` on S10
  and S21. Do not accept until the route fix proves the complete source
  remote-write, receiver pull/local/UI-open, cleanup, raw-log, queue/conflict,
  and no-direct-sync evidence chain.

## 2026-04-19 - Inspector to office-technician MDOT 0582B form seam accepted

Local/harness evidence:

- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 13 harness
  test files after the route-sentinel fix.
- `git diff --check` passed with line-ending warnings only.

Accepted device evidence:

- Accepted run:
  `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form-route-sentinel`.
- Summary:
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=16`;
  - `logsCaptured=17`;
  - `debugServerEvidenceCaptured=17`;
  - `adbLogcatEvidenceCaptured=17`;
  - `directDriverSyncEndpointUsed=false`.
- S10 inspector created `form_responses/85075bae-a469-43dd-9d39-398b82a243b8`
  on the disposable soak project through the daily-entry attached-form UI,
  with local markers including job number `0582B-JOB-outesentinel-1`, route
  `Soak Route 1`, HMA GMM `2.45`, max density `152.88`, wet density `145.2`,
  station `12+50`, and `created_by_user_id=6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`.
- S10 synced through Sync Dashboard UI only. The six pending
  `form_responses` change rows coalesced/drained without logging any
  undismissed conflicts, proving the duplicate-change false-conflict patch
  under live traffic.
- S21 office technician pulled through Sync Dashboard UI, local proof matched
  the expected header/proctor/test-row markers, and the open-form sentinel
  passed on `/form/85075bae-a469-43dd-9d39-398b82a243b8` with
  `mdot_hub_screen`.
- Screenshot review of
  `S21\steps\step-004-mdot0582b-cross-receiver-open-attached-form-after.png`
  showed real MDOT 0582B content, including the Header/Proctor/Quick Test
  sections and the expected test values.
- S10 normal cleanup soft-deleted the form response and synced through the UI;
  S21 pulled the cleanup through Sync Dashboard UI.

Raw artifact review:

- Recursive artifact scan found no `I/flutter [ERROR]`, `E/flutter`,
  `AndroidRuntime`, `PlatformException`, `RenderFlex` overflow,
  `Duplicate GlobalKey`, `FileUriExposedException`, missing-image signatures,
  state-sentinel failures, logging gaps, or direct-driver-sync evidence.
- Final live S10 and S21 `/driver/sync-status` both reported
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`, and
  `undismissedConflictCount=0`.
- Final S10 and S21 actor contexts still showed distinct real users/roles,
  the same company, and exactly the two expected active projects:
  Springfield DWSRF plus `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`.

Open next:

- Continue the role seam hardening beyond the now accepted daily-entry/review,
  quantity, document/storage, photo/storage/local-cache, and MDOT 0582B form
  seams: broader office review/edit scope, inspector final pull of office
  changes, real non-admin RLS denial probes, admin/engineer visibility, and
  signature/local-placement coverage.

## 2026-04-19 - Fresh emulator admin sweep rejected on pull-echo residue

Setup evidence:

- `.env.secret` contains four real approved role accounts for the same
  company, resolved through `RoleAccounts.ps1` without printing secrets:
  admin, engineer, office technician, and inspector.
- Android SDK has one AVD, `Pixel_7_API_36`.
- Two read-only emulator instances were attempted from that AVD. Only
  `emulator-5556` survived boot; `emulator-5554` disappeared from adb during
  boot.
- `tools\start-driver.ps1` installed the current debug driver APK on
  `emulator-5556`, but host port `4970` is excluded by Windows. Manual forward
  `tcp:4971 -> tcp:4970` proved `/driver/ready` on `/login`.

Rejected device evidence:

- `20260419-emulator-admin-role-account-switch-sweep` is **not accepted**.
- The role/account portion worked:
  - admin signed in through the UI;
  - actor context resolved user `88054934-9cc5-4af3-b1c6-38f262a7da23`,
    role `admin`, approved status, company
    `26fe92cd-7044-4412-9a09-5c5f49a292f9`;
  - provider/local project scope showed only Springfield DWSRF plus
    `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`;
  - admin dashboard, trash, project-new, and project-create-control checks
    reached the expected surfaces;
  - runtime/logging counts were zero and `directDriverSyncEndpointUsed=false`.
- The run failed for a real sync reason: fresh-device UI sync produced outbound
  pull-echo residue. Final emulator `/driver/sync-status` reported
  `pendingCount=360`, `unprocessedCount=360`, `blockedCount=0`,
  `undismissedConflictCount=0`, and `lastSyncTime=null`.
- The grouped residue was all local `insert` change-log rows for pulled data,
  including `photos=11`, `entry_equipment=40`, `entry_quantities=146`,
  `form_responses=51`, `documents=5`, `signature_files=25`,
  `signature_audit_log=25`, plus smaller support/history rows. This means the
  remaining pull-echo hardening must cover fresh local stores, not only
  repaired historical S21 residue.

Harness gap also found:

- The account-switch wrapper reported `The property 'passed' cannot be found`
  after `roleSweep.syncMeasurement.queueSentinel` was null. That is secondary
  to the real app residue, but the wrapper should fail with the explicit
  sync-measurement failure instead of a missing-property exception.

Open next:

- Patch the fresh-store pull/apply suppression path so remote rows cannot
  create outbound `change_log` inserts.
- Add focused tests that simulate a fresh pull of affected tables and assert
  the local apply does not create unprocessed change-log rows.
- Patch the account-switch proof to preserve the underlying role-sweep sync
  failure instead of throwing a missing-property error.
- Rebuild/reinstall the emulator and rerun the admin role-account sweep before
  attempting engineer/four-role expansion.

## 2026-04-19 - Fresh-store pull-echo suppression patch and local proof

Root cause carried forward from the rejected emulator sweep:

- The fresh emulator showed that pulled remote rows could echo into outbound
  `change_log` on a clean local store. The artifact contained overlapping
  trigger-suppression windows and sync lock skips during first pull.
- `PullHandler` already wrapped remote apply in trigger suppression, but other
  production helpers opened their own raw `sync_control.pulling=1/0` windows.
  An inner helper could restore `pulling=0` while the outer pull was still
  applying later remote rows. Later rows then fired normal local change
  triggers and became outbound inserts.

What changed:

- `lib/features/sync/engine/trigger_state_store.dart` now owns nested
  suppression depth per active database object. It writes `pulling=1` only at
  the outermost suppressor and restores `pulling=0` only when the final owner
  exits. `resetPullingFlag` now skips while a suppression owner is active.
- `lib/features/sync/engine/sync_control_service.dart`,
  `lib/features/sync/engine/orphan_purger.dart`,
  `lib/services/soft_delete_purge_support.dart`, and
  `lib/features/pay_applications/data/datasources/local/export_artifact_local_datasource.dart`
  now route suppression through `TriggerStateStore` instead of direct
  `sync_control` writes.
- `lib/features/sync/application/sync_coordinator.dart` now checks the sync
  gate before entering `SyncRunExecutor` and records an explicit failed
  `SyncResult` when another sync is already active, so overlapping sync
  attempts fail loudly instead of looking like a normal run.
- `tools/sync-soak/Flow.RoleAccountSwitch.ps1` now handles a missing
  `queueSentinel` without masking the underlying sync failure with
  `The property 'passed' cannot be found`.

Local evidence:

- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 13 harness
  test files.
- `dart analyze lib\features\sync\engine\trigger_state_store.dart lib\features\sync\engine\sync_control_service.dart lib\features\sync\engine\orphan_purger.dart lib\services\soft_delete_purge_support.dart lib\features\pay_applications\data\datasources\local\export_artifact_local_datasource.dart lib\features\sync\application\sync_coordinator.dart test\features\sync\application\sync_coordinator_test.dart test\features\sync\engine\local_sync_store_contract_test.dart test\features\sync\engine\pull_handler_test.dart`
  passed with no issues.
- `flutter test test\features\sync\engine\local_sync_store_contract_test.dart test\features\sync\engine\pull_handler_test.dart test\features\sync\application\sync_coordinator_test.dart -r expanded`
  passed 67 tests.
- `git diff --check` passed with line-ending warnings only.

Open next:

- Clear or reinstall the contaminated emulator app state and rerun
  `role-account-switch-only` for the admin account through UI sync only.
- Do not accept the rerun unless raw artifacts prove
  `directDriverSyncEndpointUsed=false`, `runtimeErrors=0`, `loggingGaps=0`,
  no layout/runtime signatures, and final queue state with zero pending,
  blocked, unprocessed, and undismissed conflict rows.

## 2026-04-19 - Fresh emulator admin role sweep accepted after harness and hint cleanup

Rejected reruns preserved:

- `20260419-emulator-admin-role-account-switch-after-trigger-depth` is **not
  accepted**. It proved the fresh pull-echo patch locally on device state
  (`pendingCount=0`, `unprocessedCount=0`, zero conflicts after a 615-row
  fresh pull), but the harness tapped `sync_now_full_button` while the Sync
  Dashboard correctly showed an in-progress disabled state.
- `20260419-emulator-admin-role-account-switch-after-sync-idle-gate` is **not
  accepted**. It exposed a live operational issue: the admin account could not
  register realtime hint transport because `register_sync_hint_channel` hit
  `too many active subscriptions (max 10)`, then fell back to polling.
- `20260419-emulator-admin-role-account-switch-after-hint-cleanup` and
  `20260419-emulator-admin-role-account-switch-accepted-candidate` are **not
  accepted**. Their app-side role, realtime, project-scope, and sync sentinels
  were clean, but the account-switch wrapper misread in-memory ordered
  dictionaries while aggregating the role-sweep queue sentinel and stale-scope
  sentinel list.

What changed:

- `tools/sync-soak/Flow.SyncDashboard.ps1` now waits for
  `sync_now_full_button` to exist, be visible, be enabled, and for
  `/driver/sync-status.isSyncing=false` before tapping. The flow still uses
  the UI button, not the direct sync endpoint.
- `tools/sync-soak/Flow.RoleAccountSwitch.ps1` now reads values from both
  ordered dictionaries and JSON-shaped objects when extracting nested
  `syncMeasurement`, `queueSentinel`, and sentinel `passed` values.
- `tools/sync-soak/tests/FlowWiring.Tests.ps1` now checks both wrapper
  hardening paths.
- Live admin sync-hint cleanup removed stale active/non-revoked admin
  subscription rows through the admin account's own authenticated RLS path.
  No account status mutation or admin deactivation was run.

Local evidence:

- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 13 harness
  test files after each wrapper patch.

Accepted device evidence:

- Accepted run:
  `20260419-emulator-admin-role-account-switch-accepted`.
- Summary:
  - `flow=role-account-switch-only`;
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=7`;
  - `logsCaptured=10`;
  - `debugServerEvidenceCaptured=10`;
  - `adbLogcatEvidenceCaptured=10`;
  - `directDriverSyncEndpointUsed=false`.
- Fresh emulator started from `/login` after `pm clear`, resolved admin user
  `88054934-9cc5-4af3-b1c6-38f262a7da23` in company
  `26fe92cd-7044-4412-9a09-5c5f49a292f9`, and saw exactly Springfield DWSRF
  plus `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`.
- Admin route/control proof reached admin dashboard, trash, project-new, and
  project-create control surfaces.
- Fresh pull through app/UI path pulled 615 rows without outbound pull-echo
  residue, then the Sync Dashboard UI tap ran a no-op quick sync.
- Stale-scope proof passed final user, role, selected-project-cleared,
  `/sync/dashboard`, dirty-scope-cleared, transport-company, realtime-active,
  and final-sync-drained sentinels.
- Final live emulator `/driver/sync-status` reported `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`, and
  `undismissedConflictCount=0`.

Raw artifact review:

- Text-log scan found no `I/flutter [ERROR]`, `E/flutter`, `AndroidRuntime`,
  `PlatformException`, `RenderFlex` overflow, duplicate `GlobalKey`,
  `FileUriExposedException`, missing-image signatures, state-sentinel
  failures, logging gaps, direct-driver-sync evidence, stale wrapper
  `The property 'passed'` errors, realtime cap failures, fallback polling, or
  tappability failures.
- Screenshot review of the final Sync Dashboard step showed the expected sync
  surface with `Pending Uploads (0 total)` while the UI-triggered sync was in
  progress; final live status proved it completed cleanly.

Open next:

- Add a durable operational cleanup/alert gate for stale
  `sync_hint_subscriptions` so a beta account cannot silently fall back to
  polling because old device installs consumed the active channel cap.
- Continue the expanded role lane with the engineer account on the emulator
  and keep the S10/S21 inspector/office-technician physical-device lane active.

## 2026-04-19 - Fresh emulator engineer role sweep accepted

Setup:

- Queried active sync-hint subscription counts for all four real role accounts
  without printing credentials. Engineer had zero active rows before the run.
- Removed the admin hint row left by the accepted admin emulator run through
  the admin account's own authenticated RLS path before clearing the emulator.
- Cleared emulator app data and restarted the debug driver on port `4972`.

Accepted device evidence:

- Accepted run:
  `20260419-emulator-engineer-role-account-switch`.
- Summary:
  - `flow=role-account-switch-only`;
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=7`;
  - `logsCaptured=10`;
  - `debugServerEvidenceCaptured=10`;
  - `adbLogcatEvidenceCaptured=10`;
  - `directDriverSyncEndpointUsed=false`.
- Fresh emulator resolved engineer user
  `9085cf2a-ca96-4350-a23a-87d493f9e086` in company
  `26fe92cd-7044-4412-9a09-5c5f49a292f9`.
- Engineer permission proof:
  - admin dashboard denied to `/settings`;
  - trash denied to `/settings`;
  - `/project/new` allowed;
  - `project_create_button` visible on `/projects`.
- Stale-scope proof passed final user, role, selected-project-cleared,
  `/sync/dashboard`, dirty-scope-cleared, transport-company, realtime-active,
  and final-sync-drained sentinels.
- Final live emulator `/driver/sync-status` reported `pendingCount=0`,
  `blockedCount=0`, `unprocessedCount=0`, and
  `undismissedConflictCount=0`.

Raw artifact review:

- Text-log scan found no app/runtime/layout/direct-sync/signature failures,
  no realtime cap or fallback polling failures, and no tappability errors.
- Engineer screenshots covered denied admin/trash routes, project-new allowed,
  project-create visible, and Sync Dashboard UI sync.

Checklist impact:

- Closed the admin + engineer emulator route/control subset.
- Closed the admin + engineer stale selected-project/provider/local-cache/Sync
  Dashboard subset.
- Kept the true simultaneous four-role run open because admin and engineer
  currently share the single stable emulator sequentially.

## 2026-04-19 - Sync-hint subscription cleanup and fail-loud preflight

Why this mattered:

- The accepted admin emulator lane exposed a real operational failure mode:
  stale `sync_hint_subscriptions` can exhaust the live private-channel cap and
  push the app into fallback polling. That must be visible before beta traffic,
  not discovered after a role run looks otherwise clean.
- This cleanup did not mutate user status, roles, or project membership. It
  used each real role account's own anon-authenticated RLS path.

What changed:

- Added `tools/sync-soak/SyncHintSubscriptions.ps1`.
- The role-account switch flow now runs a sync-hint preflight before UI login:
  - query active own `sync_hint_subscriptions` for the target role;
  - delete only stale own rows older than 24 hours;
  - write a redacted `round-<n>-sync-hint-subscription-preflight.json`;
  - fail the run if stale rows remain or the account is near the active cap.
- Added local harness coverage in
  `tools/sync-soak/tests/SyncHintSubscriptions.Tests.ps1` and wiring checks in
  `tools/sync-soak/tests/FlowWiring.Tests.ps1`.
- Fixed a harness bug found during cleanup: zero visible subscription rows are
  now treated as a valid clean report instead of a null-row failure.

Local evidence:

- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14 harness
  test files after the new sync-hint preflight was wired.

Live cleanup evidence:

- First maintenance attempt wrote
  `.claude/test-results/2026-04-19/sync-hint-maintenance-20260419T091648Z/`;
  it successfully removed stale office-technician rows but also exposed the
  zero-row report-builder bug for admin.
- Final maintenance attempt wrote
  `.claude/test-results/2026-04-19/sync-hint-maintenance-20260419T091739Z/summary.json`
  and passed for all four roles:
  - admin: `beforeActive=0`, `afterActive=0`;
  - engineer: `beforeActive=1`, `afterActive=1`;
  - office technician: `beforeActive=1`, `afterActive=1`;
  - inspector: `beforeActive=1`, `afterActive=1`;
  - all roles: `afterStale=0`, `nearCap=false`.

Open next:

- Add a backend/staging scheduled alert or dashboard for stale
  `sync_hint_subscriptions`. The soak harness now fails loudly, but beta
  operations still need a server-side alarm independent of test runs.
- Continue the four-role lane with physical S10/S21 plus the emulator, then
  move back to the broader role-seam checklist and at-scale sync soak.

## 2026-04-19 - Three-actor role-account gate accepted with sync-hint preflight

Device setup:

- Restarted/reinstalled S10 `R52X90378YB` on driver port `4949`.
- Restarted/reinstalled S21 `RFCNC0Y975L` on driver port `4968`.
- Restored ADB forwards/reverses for S10, S21, and `emulator-5556` after
  `start-driver.ps1` cleared the global forward table.
- Final pre-run actor state was clean:
  - S10 inspector: two visible projects, empty queue, zero undismissed
    conflicts;
  - S21 office technician: two visible projects, empty queue, zero undismissed
    conflicts;
  - emulator engineer: two visible projects, empty queue, zero undismissed
    conflicts.

Second emulator attempt:

- Started a second read-only `Pixel_7_API_36` instance on `emulator-5558`
  for a possible fourth simultaneous UI actor.
- It did not become ADB-visible after five minutes, so it was stopped and the
  true four-role simultaneous gate remains open.
- Artifact:
  `.claude/test-results/2026-04-19/emulator-capacity-attempt-20260419T0921Z/summary.json`.

Rejected harness-contract run:

- Run:
  `20260419-three-actor-role-account-switch-sync-hint-preflight`.
- This is **not accepted**. It failed all three actors on
  `account-switch-user-changed-or-started-logged-out`.
- Classification: harness contract defect. Each actor signed out and back into
  the same target account, so requiring the user id to change was wrong for
  same-role reauthentication. The role sweeps, UI sync, queues/conflicts, raw
  runtime/logging counters, and screenshots were otherwise clean.

What changed:

- `Flow.RoleAccountSwitch.ps1` now records `userTransitionKind` and accepts
  `same_target_user_reauthenticated` as a valid transition while still
  requiring final user, role, company, route, dirty-scope, realtime, and queue
  sentinels.
- Added a harness wiring assertion so the stale
  `account-switch-user-changed-or-started-logged-out` sentinel cannot return.

Local evidence:

- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14 harness
  test files after the reauthentication patch.

Accepted run:

- Run:
  `20260419-three-actor-role-account-switch-sync-hint-preflight-after-reauth-fix`.
- Summary:
  - `flow=role-account-switch-only`;
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=23`;
  - `logsCaptured=32`;
  - `debugServerEvidenceCaptured=32`;
  - `adbLogcatEvidenceCaptured=32`;
  - `directDriverSyncEndpointUsed=false`.
- Sync-hint preflight proof:
  - S10 inspector: `beforeActive=1`, `afterActive=1`, `afterStale=0`,
    `nearCap=false`;
  - S21 office technician: `beforeActive=1`, `afterActive=1`,
    `afterStale=0`, `nearCap=false`;
  - emulator engineer: `beforeActive=1`, `afterActive=1`, `afterStale=0`,
    `nearCap=false`.
- Raw text-log scan found no app/runtime/layout/direct-sync/storage/photo
  signature failures, no realtime cap or fallback polling failures, and no
  tappability failures.
- Final live `/driver/sync-status` recheck on all three actors reported
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `undismissedConflictCount=0`, and `isSyncing=false`.

Open next:

- The accepted three-actor gate does not close the true four-role simultaneous
  gate because admin still shares the single stable emulator.
- Continue the broader role-seam checklist, especially real non-admin RLS
  denial probes, admin same-project visibility, and then at-scale sync soak.

## 2026-04-19 - Real non-admin RLS denial probes accepted

Implementation:

- Added `Invoke-SoakRoleRlsDenialProbeSuite` to
  `tools/sync-soak/RoleAccounts.ps1`.
- The helper uses real Supabase anon sessions resolved from `.env.secret`,
  writes redacted proof artifacts, and records `usesServiceRole=false`.
- The probe set is intentionally non-destructive:
  - `update_member_role` with the caller as target and current role;
  - `approve_join_request` with an all-zero request id;
  - `admin_set_company_app_config` with a valid config key/value;
  - inspector-only `admin_upsert_project_assignment` against the disposable
    soak project, which fails at the role gate before any assignment mutation.

Local evidence:

- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14 harness
  test files after adding the denial suite.

Accepted backend/RLS evidence:

- Artifact:
  `.claude/test-results/2026-04-19/rls-denial-probes-20260419T0935Z/summary.json`.
- Result: `passed=true`, `failedCount=0`.
- Inspector denials:
  - `update_member_role`: `Only admins can change roles`;
  - `approve_join_request`: `Only admins can approve requests`;
  - `admin_set_company_app_config`: `Not an approved admin`;
  - `admin_upsert_project_assignment`: `Only admins or engineers can manage project assignments`.
- Office-technician denials:
  - `update_member_role`: `Only admins can change roles`;
  - `approve_join_request`: `Only admins can approve requests`;
  - `admin_set_company_app_config`: `Not an approved admin`.
- Engineer denials:
  - `update_member_role`: `Only admins can change roles`;
  - `approve_join_request`: `Only admins can approve requests`;
  - `admin_set_company_app_config`: `Not an approved admin`.
- Post-probe live device status for S10, S21, and emulator remained clean:
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `undismissedConflictCount=0`, `isSyncing=false`.

Open next:

- Add any remaining non-destructive wrong-owner/wrong-project probes that can
  be proven to fail before mutation.
- Continue role-seam stress through UI flows, then move to at-scale sync soak.

## 2026-04-19 - Admin emulator role re-proved with sync-hint preflight

Accepted run:

- Run:
  `20260419-emulator-admin-role-account-switch-with-sync-hint-preflight`.
- Purpose: re-run admin through the new sync-hint preflight after the earlier
  admin lane exposed active-subscription cap exhaustion.
- Summary:
  - `passed=true`;
  - `failedActorRounds=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `screenshotsCaptured=7`;
  - `logsCaptured=10`;
  - `debugServerEvidenceCaptured=10`;
  - `adbLogcatEvidenceCaptured=10`;
  - `directDriverSyncEndpointUsed=false`.
- Sync-hint preflight:
  - `beforeActive=0`;
  - `beforeStale=0`;
  - `staleRowsDeleted=0`;
  - `afterActive=0`;
  - `afterStale=0`;
  - `nearCap=false`.
- Final live emulator actor context resolved admin user
  `88054934-9cc5-4af3-b1c6-38f262a7da23`, role `admin`, two visible
  projects, and clean sync status:
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `undismissedConflictCount=0`, `isSyncing=false`.
- Raw text-log scan found no runtime/layout/direct-sync/realtime-cap/fallback
  or tappability signatures.

Open next:

- Admin is now clean sequentially on the single stable emulator. The true
  simultaneous four-role gate remains open until another UI actor is available
  for admin or engineer.

## 2026-04-19 - Role policy and user-scoped Trash corrected

Changed:

- Condensed the role policy into `.codex/AGENTS.md` and
  `.codex/role-permission-matrix.md`; mirrored the same short rule in
  `.claude/rules/auth/supabase-auth.md`.
- Corrected Trash from admin-only to current-user scoped in route, tile, badge
  count, load, and empty-trash paths.
- Corrected office technician to match engineer for own-project delete gates;
  added Supabase migration `20260419090000_align_project_manager_role_policy.sql`
  for project delete/restore RPC ownership.
- Added regression coverage for the role matrix and Trash user scope.

Verification:

- `dart analyze` focused touched Dart/test files: passed.
- `flutter test test\features\settings\presentation\screens\trash_screen_test.dart test\features\settings\presentation\screens\settings_screen_test.dart test\features\sync\engine\cascade_soft_delete_test.dart test\features\auth\data\models\user_role_test.dart test\features\auth\presentation\providers\auth_provider_test.dart test\features\projects\presentation\providers\project_provider_test.dart -r expanded`: passed.
- `flutter test test\features\projects\presentation\screens\project_setup_screen_ui_state_test.dart test\features\projects\presentation\screens\project_list_screen_test.dart -r expanded`: passed.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`: passed 14 test files.

Open next:

- Continue role seam UI stress beyond the accepted daily-entry/review slice:
  quantities, photos/files, documents/forms, denied actions, remaining
  wrong-owner/wrong-project probes, and admin/engineer same-project visibility.

## 2026-04-19 - Emulator capacity re-check and scale topology correction

What happened:

- Rechecked the local device pool before trying to claim four simultaneous
  role proof.
- Physical devices were already running driver apps:
  - S10/tablet `R52X90378YB` on port `4949`;
  - S21 `RFCNC0Y975L` on port `4968`.
- First emulator attempt on `emulator-5556` did not become ADB-visible within
  four minutes.
- A fresh `Pixel_7_API_36` emulator on `emulator-5554` booted and the driver
  app reached `/login` on port `4972`.
- A second read-only instance on `emulator-5556` was rejected because the
  already-running `emulator-5554` instance had not been started read-only.
  Emulator output said: `Another emulator instance is running. Please close it
  or run all emulators with -read-only flag.`
- Starting the emulator cleared the host ADB forwards for the physical
  devices; restored S10 `4949` and S21 `4968` forwards and rechecked both on
  `/sync/dashboard`.

Artifact:

- `.claude/test-results/2026-04-19/emulator-capacity-attempt-20260419T080603Z/summary.json`.

Decision:

- Do not treat "four UI devices" as the only scale path. The next clean
  emulator capacity attempt is to stop the current emulator and launch both
  emulator instances read-only from the start, then install driver apps on
  separate ports.
- For beta sync stress, keep UI proof and scale pressure separated:
  - UI proof: S10 + S21 + one stable emulator now, plus a fourth UI actor only
    if the read-only two-emulator gate is clean.
  - Scale pressure: headless app-sync actors with isolated local stores, plus
    backend/RLS actors for remote pressure only.
  - Backend/RLS pressure must not be claimed as device-sync proof.

## 2026-04-19 - Headless app-sync actor path started

User correction:

- The beta account pool has four real Supabase accounts, not 10-20
  email-backed identities. The scale model must not require the user to create
  20 real inbox-backed accounts before useful sync stress can begin.

Decision:

- Keep four real role accounts as the role-seam truth source.
- For scale, fan out multiple isolated app actors over those accounts. Each
  headless actor must still own an isolated local database/store and use a real
  Supabase session plus the production sync engine.
- Treat "10-20 unique identities" as a separate staging/local fixture gate,
  not as a blocker for the first beta soak.

Implementation started:

- Added `HeadlessAppSyncActionExecutor` under `integration_test/sync/soak/`.
- Added `SoakDriver.forHeadlessAppSync`.
- Added gated smoke test
  `test/harness/headless_app_sync_actor_test.dart`.
- Added local wrapper `scripts/soak_headless_app_sync.ps1`.

Acceptance still open:

- Run the headless app-sync smoke against local Supabase and require isolated
  SQLite actor stores, real auth sessions, real `SyncEngine`, local
  `change_log` creation, remote write proof, zero errors/conflicts, and a
  retained summary artifact before counting this toward scale.

Verification so far:

- `dart analyze integration_test\sync\soak\soak_driver.dart test\harness\headless_app_sync_actor_test.dart`: passed.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`: passed 14 test files.
- `flutter test test\harness\headless_app_sync_actor_test.dart -r expanded`: skipped as designed without `RUN_HEADLESS_APP_SYNC=true`.
- Live local run attempted with
  `scripts\soak_headless_app_sync.ps1 -DurationSeconds 1 -UserCount 4 -Concurrency 1 -ActionDelayMilliseconds 50`, but local Supabase startup was blocked because Docker Desktop was not running:
  `open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified`.

Documentation:

- Added `docs/sync-scale-hardening-playbook.md` with actor/account/evidence
  layer rules.

## 2026-04-19 - Headless app-sync live smoke accepted and role-visible enrollment fixed

Failure found:

- After Docker came up, the first live local headless app-sync smoke reached
  local Supabase and initialized isolated SQLite stores, but actor 0 could not
  update the seeded `daily_entries` row.
- Raw sync logs showed the same failure class as the live Springfield report:
  project rows were visible, but child project-scoped tables were skipped with
  no loaded `synced_projects` scope. Admin had no `project_assignments`, so
  the SyncEngine pulled project shells and then skipped locations,
  contractors, bid items, daily entries, photos, and related child tables.

Fix:

- Threaded the current user's role into foreground/background
  `SyncEngineFactory` creation.
- Updated `EnrollmentHandler` so only inspectors are assignment-scoped.
  Admin, engineer, and office technician now enroll all locally visible
  projects into `synced_projects`, while still respecting user-scoped manual
  remove-from-device markers.
- Kept inspector revocation cleanup assignment-based and prevented
  non-inspector data roles from unenrolling visible projects simply because
  assignment rows are absent or partial.
- Updated the headless app-sync persona order so the first four actors are
  role-balanced: admin, engineer, office technician, inspector.

Verification:

- `dart analyze` on focused sync enrollment/factory/resolver/headless files:
  passed.
- `flutter test test\features\sync\engine\enrollment_handler_test.dart test\features\sync\engine\enrollment_handler_contract_test.dart test\features\sync\engine\pull_scope_state_test.dart -r expanded`:
  passed 32 tests.
- `flutter test test\harness\headless_app_sync_actor_test.dart -r expanded --dart-define=RUN_HEADLESS_APP_SYNC=true --dart-define=RUN_LOCAL_HARNESS=true --dart-define=SOAK_DURATION_SECONDS=3 --dart-define=SOAK_USER_COUNT=4 --dart-define=SOAK_CONCURRENCY=4 --dart-define=SOAK_ACTION_DELAY_MS=50`:
  passed.
- Accepted headless summary:
  `build/soak/headless-app-sync-summary.json`.
- Accepted role-balanced actor manifest:
  `build/soak/headless-app-sync-2026-04-19T123748507173Z/actors.json`.
- Accepted run had `actorReportCount=4`, `actions=8`,
  `failedActions=0`, `errors=0`, `rlsDenials=0`,
  `syncEngineExercised=true`, and isolated local stores for admin, engineer,
  office technician, and inspector.

Open next:

- Promote from the 4-actor smoke to the 10-20 actor app-sync soak, then layer
  physical-device UI flows on top without claiming headless pressure as UI
  proof.

## 2026-04-19 - Repaired headless app-sync scale fanout accepted

User-facing topology decision:

- Do not model SQLite as a shared Docker backend. SQLite remains the
  per-device embedded store.
- Docker is useful for the shared local Supabase backend and, if needed, as an
  isolation wrapper around multiple app actors. The correct scale simulation is
  many actors/processes, each with its own SQLite file and real auth session,
  all pointed at the same Supabase backend.

Rejected evidence preserved:

- The first 12-actor mixed local headless run failed and is not accepted. It
  exposed two harness defects:
  - extra inspector personas were assigned to projects that did not have
    seeded child rows, so the harness attempted edits those actors could not
    locally see;
  - concurrent actors could overwrite shared seeded records between remote
    write and proof.
- The next post-patch four-role mixed run failed on
  `photos/90000000-0000-0000-0000-000000000302`. Direct local Supabase review
  showed the row was still soft-deleted from the failed delete/restore run:
  project 3 had 19 active seeded photos instead of 20.

Fix:

- Reduced headless app-sync fanout to the four real beta role personas:
  admin, engineer, office technician, and inspector. Higher actor counts now
  fan out over those roles with isolated local stores instead of requiring
  more email-backed accounts.
- Serialized per-record proof actions so a second actor cannot invalidate a
  marker before the first actor verifies its remote write.
- Added deterministic mutable-fixture repair before actor pulls. It restores
  seeded harness photos through a real authenticated admin Supabase session,
  writes `fixture_repair.json`, and fails loudly if any seeded photo remains
  soft-deleted. No service role and no mock auth are used.
- Updated `docs/sync-scale-hardening-playbook.md` to lock the Docker/SQLite
  topology rule.

Verification:

- Focused analyzer:
  `dart analyze integration_test\sync\soak\headless_app_sync_action_executor.dart test\harness\headless_app_sync_actor_test.dart scripts\soak_headless_app_sync.ps1`
  passed.
- Repaired four-role mixed smoke:
  `RUN_HEADLESS_APP_SYNC=true`, 4 virtual users, 4 concurrent workers, 25/25
  actions, zero failures, zero errors, zero RLS denials. Artifact:
  `build/soak/headless-app-sync-2026-04-19T124750636961Z/actors.json`; repair
  artifact showed `deletedBefore=1`, `deletedAfter=0`.
- Accepted 12-actor local app-sync scale proof:
  `RUN_HEADLESS_APP_SYNC=true`, 12 virtual users, 6 concurrent workers,
  four real role personas fanned across isolated SQLite stores, real sessions,
  real `SyncEngine`, 174/174 actions, zero failures, zero errors, zero RLS
  denials. Summary:
  `build/soak/headless-app-sync-summary.json`; actor/repair artifact:
  `build/soak/headless-app-sync-2026-04-19T124822914052Z/actors.json`.
- Post-run local Supabase check found `0` seeded harness photos still
  soft-deleted.

Open next:

- Layer S21/S10 UI role traffic over the accepted headless app-sync pressure
  without counting headless pressure as UI proof.
- Continue remaining role seams: broader office/admin/engineer same-project
  review/edit flows, non-destructive wrong-owner/wrong-project probes, and
  production/staging observability for stale sync-hint subscriptions.

## 2026-04-19 - Four-role UI gate resumed; stale Trash expectation and Android surface gaps patched

Rejected evidence preserved:

- Run `20260419-four-role-ui-endpoint-wiring` is rejected harness evidence.
  S21 admin passed, but S10 inspector, emulator engineer, and emulator
  office-technician failed on `role-sweep-trash-denied` because the harness
  still expected non-admins to be redirected away from `/settings/trash`.
- This was not a valid role-policy failure. The controlling role matrix says
  Trash is user-scoped for every approved user, not admin-only.

What changed:

- `Flow.RoleSweep.ps1` now keeps admin dashboard admin-only, but runs
  `trash-user-scoped-allowed` for every approved role and requires
  `/settings/trash` plus `trash_screen`.
- Added `tools/sync-soak/AndroidSurface.ps1`.
- `FlowRuntime.ps1` now runs Android surface preflight before normal
  preflight capture: it resolves the actor's Android device, captures
  UIAutomator XML, collapses notification shade overlays, tries to grant or
  dismiss notification/permission prompts, and fails with
  `system_overlay_blocked` if Android still covers the app.
- `EvidenceBundle.ps1` now captures Android UIAutomator XML with every
  evidence bundle and converts blocking Android overlay classifications into
  runtime evidence.
- `FailureClassification.ps1` now has a dedicated `system_overlay_blocked`
  category so emulator notification/permission surfaces are named defects.
- `start-driver.ps1` remains patched from the interrupted run to remove only
  the current actor's ADB forward/reverse entries instead of clearing the
  whole device-lab forward table.

Local verification:

- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14 harness
  test files.
- `git diff --check` passed with line-ending warnings only.

Live endpoint preflight:

- ADB devices visible: S10 `R52X90378YB`, S21 `RFCNC0Y975L`,
  `emulator-5554`, and `emulator-5556`.
- ADB forwards intact:
  `4949`, `4968`, `4972`, and `4973`.
- Driver status:
  - S10 `4949`: `/settings/trash`, empty queue, zero undismissed conflicts.
  - S21 `4968`: `/sync/dashboard`, empty queue, zero undismissed conflicts.
  - emulator `4972`: `/settings/trash`, empty queue, zero undismissed
    conflicts.
  - emulator `4973`: `/settings/trash`, empty queue, zero undismissed
    conflicts.

Open next:

- Clear the debug server, rerun the true simultaneous four-role UI
  role-account gate, and accept it only if all four roles have clean actor
  context, screenshots, debug-server logs, ADB logcat, Android surface
  evidence, empty queues/conflicts, and `directDriverSyncEndpointUsed=false`.

## 2026-04-19 - Four-role rerun failed loudly on router GlobalKey red screen; guardrail patched

Rejected evidence preserved:

- Run:
  `20260419-four-role-ui-endpoint-wiring-after-trash-surface-fix`.
- Artifact:
  `.claude/test-results/2026-04-19/enterprise-sync-soak/20260419-four-role-ui-endpoint-wiring-after-trash-surface-fix/summary.json`.
- Result:
  - `passed=false`;
  - `failedActorRounds=4`;
  - `runtimeErrors=48`;
  - `loggingGaps=0`;
  - `queueDrainResult=drained`;
  - no final queue residue.
- Classification:
  - stale non-admin Trash denial was fixed;
  - Android notification/permission overlay blockers were not present;
  - S21 and one emulator had visible red screens;
  - S10 and the other emulator failed during `account-switch-sign-out`;
  - runtime evidence included GoRouter `Duplicate GlobalKey`,
    `GlobalObjectKey`, `InheritedGoRouter`, `_elements.contains(element)`,
    and detached render-object assertions.

Root cause:

- The app shell and shell child pages reused `state.pageKey`. During auth
  redirects and account-switch sign-out, GoRouter can keep the old shell
  subtree alive while a full-screen auth route is mounting. That briefly
  duplicates GoRouter-owned global-key state under `InheritedGoRouter`.
- The sign-out dialog was already popping before auth mutation, but it did not
  wait for the dialog route teardown before notifying auth listeners and
  triggering the router redirect.

What changed:

- `lib/core/router/app_router.dart` now uses stable local `ValueKey<String>`
  values for the shell container and the four shell child pages. The production
  routing sweep now finds no `state.pageKey` use except comments.
- `lib/features/settings/presentation/widgets/sign_out_dialog.dart` waits one
  `kThemeAnimationDuration` after popping the dialog before calling
  `AuthProvider.signOut()`.
- Added architecture lint
  `no_go_router_state_page_key_in_shell_routes` and registered it in
  `architectureRules`. It now applies to the whole production
  `lib/core/router/` surface so future split route files cannot reintroduce
  `state.pageKey`.
- The routing/global-key sweep found remaining production `GlobalKey` usage
  limited to local form/state keys and the router navigator keys, not reused
  GoRouter page keys.

Local verification:

- `dart analyze lib\core\router\app_router.dart lib\features\settings\presentation\widgets\sign_out_dialog.dart fg_lint_packages\field_guide_lints\lib\architecture\rules\no_go_router_state_page_key_in_shell_routes.dart fg_lint_packages\field_guide_lints\lib\architecture\architecture_rules.dart fg_lint_packages\field_guide_lints\test\architecture\no_go_router_state_page_key_in_shell_routes_test.dart`:
  passed.
- `dart test fg_lint_packages\field_guide_lints\test\architecture\no_go_router_state_page_key_in_shell_routes_test.dart fg_lint_packages\field_guide_lints\test\architecture\no_conditional_root_shell_child_wrapper_test.dart fg_lint_packages\field_guide_lints\test\architecture\no_immediate_dialog_controller_dispose_in_screens_test.dart`:
  passed 11 tests.
- `flutter test test\core\router\app_router_test.dart test\core\router\scaffold_with_nav_bar_test.dart test\features\settings\presentation\screens\settings_screen_test.dart -r expanded`:
  passed 44 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`:
  passed 14 harness test files.
- `git diff --check`:
  passed with line-ending warnings only.

Open next:

- Rebuild/restart S10, S21, `emulator-5554`, and `emulator-5556` on this
  patched app, then rerun the four-role UI gate. Acceptance still requires
  clean actor context, screenshots, debug-server logs, ADB logcat, Android
  surface evidence, empty queues/conflicts, zero runtime/logging gaps, and
  `directDriverSyncEndpointUsed=false`.

## 2026-04-19 - Second four-role rerun exposed AppLockGate root-wrapper instability

Rejected evidence preserved:

- Run:
  `20260419-four-role-ui-endpoint-wiring-after-router-key-fix`.
- Artifact:
  `.claude/test-results/2026-04-19/enterprise-sync-soak/20260419-four-role-ui-endpoint-wiring-after-router-key-fix/summary.json`.
- Result:
  - `passed=false`;
  - `failedActorRounds=4`;
  - `runtimeErrors=47`;
  - `loggingGaps=0`;
  - `queueDrainResult=drained`;
  - `directDriverSyncEndpointUsed=false`.
- Failure evidence:
  - GoRouter `Duplicate GlobalKey` / `InheritedGoRouter` assertions remained;
  - Android surface evidence had no blocking overlay classifications;
  - final change-log queues were empty on all four actors.

Root cause update:

- The prior patch removed `state.pageKey` from shell pages, but another root
  wrapper still violated the same Flutter invariant. `AppLockGate` sometimes
  returned the router child directly and sometimes returned `Stack(children:
  [child, lock overlay])`. That can reparent the router-owned global-key
  subtree when auth/account-switch and app-lock state rebuilds overlap.

What changed:

- `lib/features/settings/presentation/widgets/app_lock_gate.dart` now always
  returns a stable `Stack` around the router child and only toggles the lock
  overlay child.
- `no_conditional_root_shell_child_wrapper` now applies to
  `app_lock_gate.dart` in addition to `app_widget.dart` and `main.dart`.
- Added unit coverage that the lint applies to all three root router-wrapper
  files.

Local verification:

- `dart analyze lib\features\settings\presentation\widgets\app_lock_gate.dart lib\core\app_widget.dart fg_lint_packages\field_guide_lints\lib\architecture\rules\no_conditional_root_shell_child_wrapper.dart fg_lint_packages\field_guide_lints\test\architecture\no_conditional_root_shell_child_wrapper_test.dart`:
  passed.
- `dart test fg_lint_packages\field_guide_lints\test\architecture\no_conditional_root_shell_child_wrapper_test.dart fg_lint_packages\field_guide_lints\test\architecture\no_go_router_state_page_key_in_shell_routes_test.dart`:
  passed 8 tests.
- `flutter test test\features\settings\presentation\screens\app_lock_settings_screen_test.dart test\core\router\app_router_test.dart test\core\router\scaffold_with_nav_bar_test.dart -r expanded`:
  passed 23 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`:
  passed 14 harness test files.
- `git diff --check`:
  passed with line-ending warnings only.

Open next:

- Rebuild/restart all four UI actors again because `AppLockGate` changed, then
  rerun `role-account-switch-only`. If this closes the red-screen class, the
  next checklist item is user-scoped Trash/RLS boundary proof across the four
  accounts before layering headless app-sync pressure.

## 2026-04-19 - Third rerun exposed shell navigator key plus blank-surface blind spot

Rejected evidence preserved:

- Run:
  `20260419-four-role-ui-endpoint-wiring-after-app-lock-stable-wrapper`.
- Artifact:
  `.claude/test-results/2026-04-19/enterprise-sync-soak/20260419-four-role-ui-endpoint-wiring-after-app-lock-stable-wrapper/summary.json`.
- Result:
  - `passed=false`;
  - `failedActorRounds=4`;
  - `runtimeErrors=52`;
  - `loggingGaps=0`;
  - `queueDrainResult=drained`;
  - `directDriverSyncEndpointUsed=false`.
- Failure evidence:
  - GoRouter `Duplicate GlobalKey` / `InheritedGoRouter` assertions remained;
  - live screenshots showed S21 and `emulator-5554` on blank black app
    surfaces;
  - UIAutomator XML for those two actors was only an empty full-screen app
    view hierarchy, with no text, hints, controls, or Flutter semantics.

Root cause update:

- The shell route still held an app-owned `_shellNavigatorKey`. During
  shell-to-auth transitions, that can preserve the old shell navigator while
  the login route attaches a new `InheritedGoRouter`, reproducing the same
  global-key failure even after page keys and root wrappers were stabilized.
- The soak harness saw Android overlays, Flutter widget-tree errors, logcat,
  and debug-server errors, but did not yet classify a blank app-owned Android
  surface as a runtime failure. That let black-screen evidence be visible to a
  human before it was a named harness category.

What changed:

- `lib/core/router/app_router.dart` no longer passes a `navigatorKey` to
  `ShellRoute`; go_router now owns the shell navigator key. The app still owns
  `_rootNavigatorKey` for full-screen parent routes such as user-scoped Trash.
- Added and registered architecture lint
  `no_explicit_shell_route_navigator_key`.
- `AndroidSurface.ps1` now classifies `android_app_blank_surface` when the
  Field Guide app owns the foreground surface but exposes no readable
  semantics or interactive native widgets.
- `FlowRuntime.ps1`, `EvidenceBundle.ps1`, and `FailureClassification.ps1` now
  turn that into `[blank_app_surface]` / `blank_app_surface` fail-loud evidence.

Local verification:

- `dart analyze lib\core\router\app_router.dart fg_lint_packages\field_guide_lints\lib\architecture\rules\no_explicit_shell_route_navigator_key.dart fg_lint_packages\field_guide_lints\lib\architecture\architecture_rules.dart fg_lint_packages\field_guide_lints\test\architecture\no_explicit_shell_route_navigator_key_test.dart`:
  passed.
- `dart test fg_lint_packages\field_guide_lints\test\architecture\no_explicit_shell_route_navigator_key_test.dart fg_lint_packages\field_guide_lints\test\architecture\no_go_router_state_page_key_in_shell_routes_test.dart fg_lint_packages\field_guide_lints\test\architecture\no_conditional_root_shell_child_wrapper_test.dart`:
  passed 12 tests.
- `flutter test test\core\router\app_router_test.dart test\core\router\scaffold_with_nav_bar_test.dart test\features\settings\presentation\screens\settings_screen_test.dart test\features\settings\presentation\screens\app_lock_settings_screen_test.dart -r expanded`:
  passed 46 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`:
  passed 14 harness test files.
- `git diff --check`:
  passed with line-ending warnings only.

Open next:

- Rebuild/restart S10, S21, `emulator-5554`, and `emulator-5556`, then rerun
  the four-role UI gate. If this still fails, preserve the artifact and keep
  iterating on the next concrete red/blank-screen cause before moving to
  user-scoped Trash/RLS proof.

## 2026-04-19 - Fourth rerun exposed root theme wrapper and logcat attribution gaps

Rejected evidence preserved:

- Run:
  `20260419-four-role-ui-endpoint-wiring-after-shell-key-blank-surface-fix`.
- Artifact:
  `.claude/test-results/2026-04-19/enterprise-sync-soak/20260419-four-role-ui-endpoint-wiring-after-shell-key-blank-surface-fix/summary.json`.
- Result:
  - `passed=false`;
  - `failedActorRounds=4`;
  - `runtimeErrors=45`;
  - `loggingGaps=0`;
  - `queueDrainResult=drained`;
  - `directDriverSyncEndpointUsed=false`.
- Failure evidence:
  - emulator actors reached real black app surfaces classified as
    `android_app_blank_surface` / `blank_app_surface`;
  - S21/S10 step evidence was polluted by earlier ADB logcat lines and benign
    UIAutomator `AndroidRuntime` launcher logs, so the harness was failing
    loudly but not attributing all runtime lines tightly enough.

Root cause update:

- One mutable inherited wrapper still lived under `MaterialApp.router.builder`:
  `_ResponsiveThemeShell` wrapped GoRouter's child in a `Theme`. That builder
  receives the router child, so inherited theme updates there can coincide with
  GoRouter auth/navigation transitions and reparent router-owned GlobalKeys.
- The ADB runtime scanner treated any `AndroidRuntime` log tag as fatal, but
  `uiautomator dump` emits normal `D/I AndroidRuntime` process-launch lines.

What changed:

- Responsive density now feeds `ThemeProvider.currentTheme(spacing: ...)`
  above `MaterialApp.router`; the builder is limited to the stable
  `AppLockGate` overlay slot.
- Added and registered architecture lint
  `no_material_app_router_builder_theme_wrapper`.
- `FlowRuntime.ps1` clears ADB logcat before Android surface preflight.
- `StepRunner.ps1` clears ADB logcat at each step start before per-step
  evidence.
- `RuntimeErrorScanner.ps1` ignores benign UIAutomator `D/I AndroidRuntime`
  launcher noise while still catching `FATAL EXCEPTION` / fatal Android runtime
  lines.

Local verification:

- Focused `dart analyze`: passed.
- Focused architecture lint tests: passed 16 tests.
- Focused app/router/settings Flutter tests: passed 47 tests.
- `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`: passed 14 harness
  test files.

Open next:

- Rebuild/restart all four UI actors on the root-theme/logcat attribution
  patch and rerun the simultaneous four-role UI gate. Acceptance still requires
  screenshots, debug-server logs, ADB logcat, Android surface evidence, clean
  queues/conflicts, and `directDriverSyncEndpointUsed=false`.

## 2026-04-19 - Pause handoff

Current state:

- Work paused before any device rebuild/restart on the root-theme/logcat
  attribution patch.
- Local verification is complete for the patch:
  - focused `dart analyze`: passed;
  - focused architecture lint tests: passed 16 tests;
  - focused app/router/settings Flutter tests: passed 47 tests;
  - `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`: passed 14
    harness test files;
  - `git diff --check`: passed with line-ending warnings only.
- The latest four-role UI device artifact is still rejected, not accepted:
  `.claude/test-results/2026-04-19/enterprise-sync-soak/20260419-four-role-ui-endpoint-wiring-after-shell-key-blank-surface-fix/summary.json`.
- That rejected run had drained queues and no direct driver sync use, but it
  failed loudly on runtime evidence and blank app surface evidence.
- The local patch after that run:
  - moved responsive theme/density above `MaterialApp.router`;
  - added `no_material_app_router_builder_theme_wrapper`;
  - clears ADB logcat before preflight and every step;
  - ignores benign UIAutomator `D/I AndroidRuntime` lines while preserving
    fatal Android runtime detection.

Next exact action:

1. Rebuild/restart S10 `R52X90378YB` port `4949`, S21 `RFCNC0Y975L` port
   `4968`, `emulator-5554` port `4972`, and `emulator-5556` port `4973`.
2. Clear debug-server logs and confirm `/driver/ready`, `/driver/context`,
   screenshots, Android foreground package, and Android surface XML for each
   actor before running a flow.
3. Rerun `role-account-switch-only` with actors
   `S21:4968:admin:1`, `S10:4949:inspector:2`,
   `EMU1:4972:engineer:3`, `EMU2:4973:office_technician:4`.
4. Accept only if the summary has `passed=true`, `runtimeErrors=0`,
   `loggingGaps=0`, `queueDrainResult=drained`, clean final queues/conflicts,
   Android surface evidence with no overlays/blank surfaces, screenshots, and
   `directDriverSyncEndpointUsed=false`.
