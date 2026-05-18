# Sync Root-Cause And Supabase Advisor Evidence Plan

Status: active implementation checklist. Preserve the evidence sections below as
the audit trail for every code, migration, lint, and verification decision.
Every checkbox closure must cite evidence, a test, or an accepted artifact.

## Scope

This plan preserves evidence and hypotheses for GitHub issues #315, #316, #318,
#319, #321, plus the 98 Supabase Security Advisor findings. It now also tracks
the implementation slices required to close those root causes.

Primary issue priority: #321, because the current evidence suggests it creates
a persistent dirty sync loop and likely feeds #318.

Acceptance target:

- Device gate: S21.
- Backend gate: live Supabase, real auth, real SQLite.
- Trigger gate: UI-triggered sync only; no direct sync endpoint shortcuts.
- Dirty queue target: create project + add bid items + correct project number
  must complete a full dirty sync in under 2 seconds end to end.
- Final state: `pending=0`, `blocked=0`, `unprocessed=0`, `errors=0`,
  `rlsDenials=0`.
- Screenshots, logs, sync metrics, and debug state must show no UI, runtime,
  layout, or sync defects.

## Active Implementation Checklist

Companion checkpoint:
`.codex/checkpoints/2026-05-10-sync-root-cause-implementation-checkpoint.md`.

### P0 - Preserve And Reframe The Plan

- [x] Update this May 10 plan with the active implementation direction.
  Evidence: checkpoint P0.
- [x] Keep the existing evidence sections intact as the audit trail. Evidence:
  checkpoint P0.
- [x] Add this top-level implementation checklist grouped by root cause.
  Evidence: checkpoint P0.
- [x] Add the companion checkpoint file for slice notes, findings, test output,
  artifact paths, and open follow-ups. Evidence:
  `.codex/checkpoints/2026-05-10-sync-root-cause-implementation-checkpoint.md`.
- [x] Require every checkbox closure to cite evidence, a test, or an accepted
  artifact. Evidence: this checklist and checkpoint closure rule.

### P1 - #321/#318 Project-Number Dirty Sync Loop

- [x] Add focused tests for create project -> add bid items -> correct project
  number -> sync. Evidence: checkpoint P1 tests in
  `test/features/sync/engine/push_handler_contract_test.dart` and
  `test/features/sync/application/sync_state_repair_runner_test.dart`.
- [x] Make project identity resolution explicit before child tables push.
  Evidence: checkpoint P1 code notes for `push_handler.dart`,
  `push_table_planner.dart`, and `local_record_store.dart`.
- [x] Ensure project natural-key collisions/remaps fully reconcile `projects`,
  `bid_items.project_id`, `synced_projects`, project-scoped
  `change_log.project_id`, and project enrollment/assignment state. Evidence:
  checkpoint P1 code notes and targeted sync test run.
- [x] Re-plan or quarantine child table pushes after parent remap/failure in
  the same sync cycle. Evidence: checkpoint P1 same-cycle parent failure test.
- [x] Change bulk `bid_items` failure handling so RLS/constraint failures fall
  back to per-row disposition. Evidence: checkpoint P1 bulk fallback tests.
- [x] Ensure every affected `change_log` row gets actionable state: retryable,
  blocked, failed, or repairable. Evidence: checkpoint P1 `push_error_handler`
  notes and repair-runner tests.
- [x] Add active dirty project repair for project-number correction cases,
  separate from abandoned/deleted project cleanup.
  Evidence: checkpoint P1 active repair implementation and tests.
- [x] Preserve sync invariants: no manual `change_log` inserts, no
  `sync_status` revival, `SyncErrorClassifier` remains the error-classification
  owner, and `SyncCoordinator` remains the production sync entrypoint.
  Evidence: checkpoint P1 invariant audit.
- [x] Verify #318 no longer reports repeated `pending_uploads` for rows stuck
  by cycle-level bulk failure. Evidence: checkpoint P1 bulk RLS fallback and
  repair classification tests.

### P2 - #319 Entry Quantity Pull Pressure

- [x] Add pull tracing for `entry_quantities`: scope source, request length, ID
  count, page count, timing, and cursor. Evidence: checkpoint P2 and
  `pull_handler_test.dart` trace output.
- [x] Bound `entry_id IN (...)` request size by chunking or replacing with
  project-scoped pull where safe. Evidence: checkpoint P2 project-scope tests.
- [x] Prefer `project_id` scoped pulls for denormalized entry-child tables that
  already carry `project_id`. Evidence: checkpoint P2 adapter metadata notes.
- [x] Add or verify remote indexes for any new project-scoped pull shape,
  especially `(project_id, updated_at, id)`. Evidence: migration
  `20260510120000_sync_root_cause_security_hardening.sql`.
- [x] Preserve existing cursor safety-margin behavior. Evidence: existing
  pagination cursor tests in `pull_handler_test.dart` passed after changes.
- [x] Verify pull requests remain bounded and do not reproduce connection
  aborts. Evidence: checkpoint P2 scoped pull tests and S21 artifact
  `tools/testing/test-results/2026-05-10/s21-sync-root-cause/entry-quantities-bounded/entry-quantities-bounded-summary.json`.

### P3 - #315 Route Guard Reentrancy

- [x] Add timeline diagnostics around guard reevaluation: route/location,
  decision reason, changed access fields, auth/profile/sync/resume trigger,
  and `resolver.isReevaluating`. Evidence: checkpoint P3 route diagnostics.
- [x] Fix guard completion at the route access controller/guard boundary.
  Evidence: checkpoint P3 guard code notes.
- [x] Make guard resolution idempotent so reevaluation cannot complete the same
  resolver twice. Evidence: checkpoint P3 `_resolveOnce`/`_redirectOnce` tests.
- [x] Verify auth refresh, profile refresh, sync completion, project selection,
  and app resume do not trigger `Future already completed`. Evidence:
  `test/core/router/autoroute/app_auto_router_test.dart` targeted run and S21
  artifact
  `tools/testing/test-results/2026-05-10/20260510-s21-route-guard-auth-rerun/summary.json`.

### P4 - #316 Support Report Button State

- [x] Reproduce and document the exact invalid/valid UI states. Evidence:
  checkpoint P4 widget test notes.
- [x] Align primary and secondary support actions so enabled state matches
  actual availability. Evidence: checkpoint P4 support UI implementation.
- [x] Keep Sentry-backed bug report behavior distinct from support-ticket
  submission if both remain visible. Evidence: checkpoint P4 launcher notes.
- [x] Ensure invalid reports cannot be submitted through either visible action.
  Evidence: `help_support_screen_test.dart` validation-state test and S21
  artifact
  `tools/testing/test-results/2026-05-10/s21-sync-root-cause/support-action-state/summary.json`.
- [x] Preserve current support sync/schema compatibility unless evidence proves
  that path is involved. Evidence: checkpoint P4 notes; no support schema
  migration was introduced.

### P5 - Supabase Advisor And DB Lint Fixes

- [x] Enable and lock down RLS for `entry_personnel`. Evidence: migration
  `20260510120000_sync_root_cause_security_hardening.sql`.
- [x] Add explicit RLS/lockdown posture for `sync_push_rate_limits`. Evidence:
  migration and rollback parity file.
- [x] Categorize broad function execute grants before revoking: public RPCs,
  authenticated RPCs, trigger-only helpers, service-role-only helpers, and
  internal policy helpers. Evidence: checkpoint P5 grant categorization.
- [x] Revoke inappropriate `EXECUTE` grants without breaking intended app RPCs.
  Evidence: migration grant/revoke blocks and static SQL lint.
- [x] Add fixed `SET search_path` to all six Advisor-listed functions.
  Evidence: migration `ALTER FUNCTION ... SET search_path`.
- [x] Fix `invoke_daily_sync_push` to match the installed
  `extensions.http_post` signature or replace the call path. Evidence:
  migration and `supabase/functions/daily-sync-push/index.ts`.
- [x] Decide and document the `releases` bucket posture: direct public object
  URLs without broad anonymous object listing. Evidence:
  `docs/security/release-bucket-posture.md`.
- [x] Record Auth leaked-password protection as an accepted-risk release
  posture exception for this build. Evidence: live Management API rejected
  `password_hibp_enabled=true` because leaked-password protection requires a
  Supabase Pro plan or higher; user accepted skipping this Advisor warning on
  2026-05-10. Auth MFA/TOTP posture was verified through linked config/API
  evidence in the checkpoint.
- [x] Add rollback parity for all security-sensitive migrations. Evidence:
  rollback `20260510120000_rollback.sql` and rollback validation commands.

### P6 - Guardrails

- [x] Add static SQL lint coverage for public tables created without RLS,
  policies on tables without enabled RLS, `SECURITY DEFINER` without fixed
  `search_path`, functions without matching execute grants/revokes,
  unsupported `extensions.http_post` call shape, and security-sensitive
  migration/rollback drift. Evidence: `tools/supabase/lint_sql_security.py`
  and passing static lint command.
- [x] Add a VS Code task/problem matcher for live Supabase Advisor and DB lint
  checks. Evidence: `.vscode/tasks.json`.
- [x] Keep live network/auth-dependent checks outside Dart analyzer. Evidence:
  static lint plus VS Code tasks; `flutter analyze` remains network-free.
- [x] Update existing sync/testing docs only where needed to preserve the new
  contract. Evidence: active plan/checkpoint and release bucket posture doc.

### Verification Plan

- [x] Run targeted unit tests for sync planning, project remap, bulk fallback,
  and repair classification. Evidence: checkpoint Verification, targeted
  Flutter test command passed.
- [x] Run targeted integration tests for `entry_quantities` pull scoping and
  pagination. Evidence: `pull_handler_test.dart` targeted run passed.
- [x] Run route guard tests for reentrant access changes. Evidence:
  `app_auto_router_test.dart` targeted run passed.
- [x] Run support report widget/UI tests for validation and enabled states.
  Evidence: `help_support_screen_test.dart` targeted run passed.
- [x] Run linked Supabase migration deployment and rollback validation.
  Evidence: linked `supabase db push --linked --yes` completed; rollback parity
  validation passed for all new security migrations.
- [x] Run `supabase db lint --linked --level warning`. Evidence:
  `tools/testing/test-results/2026-05-10/supabase-live/db-lint-final-20260510.json`
  reports `No schema errors found`.
- [x] Run live Supabase Advisor verification after security fixes. Evidence:
  `tools/testing/test-results/2026-05-10/supabase-live/advisor-final-20260510.json`
  contains only the paid-plan `auth_leaked_password_protection` warning.
- [x] Run `flutter analyze`. Evidence: `flutter analyze` passed with no issues.
- [x] Run `dart run custom_lint`. Evidence: `dart run custom_lint` passed with
  no issues.
- [x] Verify on S21 with real auth, real Supabase, real SQLite, and
  UI-triggered sync. Evidence:
  `tools/testing/test-results/2026-05-10/s21-sync-root-cause/project-number-correction/14-ui-full-sync-measurement.json`,
  `tools/testing/test-results/2026-05-10/s21-sync-root-cause/entry-quantities-bounded/entry-quantities-bounded-summary.json`,
  `tools/testing/test-results/2026-05-10/20260510-s21-route-guard-auth-rerun/summary.json`,
  and
  `tools/testing/test-results/2026-05-10/s21-sync-root-cause/support-action-state/summary.json`.

## Evidence Task List

Closure evidence for the issue-specific evidence tasks below is recorded in the
checkpoint under `2026-05-10 - S21 Acceptance Verification`, with supporting
artifacts under `tools/testing/test-results/2026-05-10/s21-sync-root-cause/`
and `tools/testing/test-results/2026-05-10/20260510-s21-route-guard-auth-rerun/`.

- [x] #321: Capture exact S21 reproduction path for create project -> add bid
  items -> correct project number -> stuck sync loop.
- [x] #321: Capture local SQLite evidence before/after failure: `projects`,
  `bid_items`, `synced_projects`, `change_log`, `retry_count`, `project_id`,
  and `error_message`.
- [x] #321: Capture remote Supabase evidence for affected project numbers:
  `projects`, `project_assignments`, `bid_items`, and RLS visibility for the
  current user.
- [x] #321: Prove whether first failure is project natural-key conflict,
  project RLS/visibility, remap collision, or child push before parent
  acknowledgement.
- [x] #321: Capture sync timing breakdown on S21 for the dirty project-number
  correction flow against the under-2-second dirty-sync target.
- [x] #321: Map self-healing evidence needed for active dirty project repair,
  including remapable and non-remapable poisoned queue states.
- [x] #318: Gather stuck pending queue snapshots and determine whether pending
  rows are downstream of #321 parent/child project-scoped failures.
- [x] #318: Capture Sync Dashboard counts, bucket grouping, retry exhaustion,
  blocked rows, and repair metadata before/after recovery attempts.
- [x] #319: Capture scoped pull evidence for `entry_quantities`, including
  `IN (...)` list size, page counts, timing, abort logs, and dirty-scope origin.
- [x] #319: Compare pull timings against the S21 dirty-sync target and identify
  oversized scoped pull or cursor-reset causes.
- [x] #315: Gather navigation/auth/sync-state transition evidence around
  `NavigationResolver` `Future already completed`.
- [x] #315: Identify whether route reevaluation is triggered by auth profile
  refresh, sync completion, project selection, or app resume.
- [x] #316: Gather support ticket UI-state evidence: typed length threshold,
  enabled/selectable state, validation state, screenshots, and logs.
- [x] Supabase 98: Preserve full Advisor finding counts, IDs/titles, affected
  object names, roles, severity, and SQL context.
- [x] Supabase 98: Verify live RLS-disabled findings for `entry_personnel` and
  `sync_push_rate_limits` against `pg_class` and `pg_policies`.
- [x] Supabase 98: Verify all 86 `SECURITY DEFINER` executable findings against
  live `pg_proc` ACLs and intended role access.
- [x] Supabase 98: Verify the 6 mutable `search_path` functions and find their
  defining migrations plus rollback parity.
- [x] Supabase 98: Verify `invoke_daily_sync_push` live failure and gather the
  correct `extensions.http_post` signature evidence.
- [x] Supabase 98: Verify public `releases` bucket listing policy and intended
  anonymous/download behavior.
- [x] Supabase 98: Record Auth MFA and leaked-password-protection evidence as
  release/security backlog items.
- [x] Supabase 98: Group findings into high-level fix buckets: RLS
  enable/lockdown, function `EXECUTE` revokes, `search_path` hardening, broken
  sync hint function, storage policy, and auth config.
- [x] Lint guardrails: Map each repeated Supabase finding type to proposed
  static SQL lint or VS Code live-lint task evidence.
- [x] Plan artifact: Append gathered evidence, root-cause hypotheses,
  high-level fixes, and acceptance criteria here before implementation.
  Evidence: active implementation checklist above and companion checkpoint.

## Issue Evidence

### #321 - `bid_items` RLS Denial During New Project Sync

GitHub issue: `https://github.com/Field-Guide/construction-inspector-tracking-app/issues/321`

Sentry issue in the GitHub body: FLUTTER-1A.

Observed exception:

```text
PostgrestException(message: new row violates row-level security policy for table "bid_items", code: 42501, details: Forbidden, hint: null)
```

Stack evidence from the issue body:

```text
SupabaseSync.upsertRecords
PushUpsertExecutor.executeBulkUpsert
```

User reproduction evidence:

- Create a new project.
- Add bid items.
- Notice the project number is wrong.
- Change the project number.
- Sync enters a persistent stuck loop and stops completing.
- Uninstalling, refreshing, and retrying did not resolve the behavior.

Static code evidence gathered:

- `lib/features/sync/adapters/simple_adapters.dart:23` defines the `projects`
  adapter.
- `lib/features/sync/adapters/simple_adapters.dart:27` gives `projects`
  natural key columns `['company_id', 'project_number']`.
- `lib/features/sync/adapters/simple_adapters.dart:59` defines the `bid_items`
  adapter.
- `lib/features/sync/adapters/simple_adapters.dart:61-62` makes `bid_items`
  depend on `projects` through `project_id`.
- `lib/features/sync/engine/push_handler.dart:139-142` prepares all table
  plans before executing each prepared table.
- `lib/features/sync/engine/push_handler.dart:173-213` builds all prepared
  table plans using one `PushPlanningContext` before table execution.
- `lib/features/sync/engine/push_table_planner.dart:84-128` loads failed
  parent IDs during planning.
- `lib/features/sync/engine/push_table_planner.dart:179-181` only blocks a
  child when its parent ID is already in the failed-parent set.
- `lib/features/sync/engine/local_record_store.dart:256-272` has an
  existing-target natural-key remap branch that deletes the duplicate parent
  and returns.
- `lib/features/sync/engine/local_record_store.dart:279-294` remaps child FK
  columns and project enrollment only in the non-existing-target branch.
- `lib/features/sync/engine/local_record_store.dart:313` updates
  `change_log.project_id` only after the branch that can return early.
- `lib/features/projects/data/repositories/project_repository.dart:133-146`
  checks project-number duplicates only against the local SQLite datasource
  before updating an existing project.
- `lib/features/sync/engine/push_upsert_executor.dart:49-53` allows bulk
  upsert only for non-file, non-insert-only adapters with no natural-key
  columns.
- `lib/features/sync/adapters/simple_adapters.dart:58-64` shows `bid_items`
  has no natural-key columns, so multiple bid-item changes can use the bulk
  upsert path.
- `lib/features/sync/engine/supabase_sync.dart:73-77` performs bulk upsert
  through `.from(tableName).upsert(payloads).select('id,updated_at')`.
- `lib/features/sync/engine/push_handler_support.dart:77-99` rethrows
  classified bulk failures when the error is retryable, auth-related, or an
  RLS denial.
- `lib/features/sync/engine/push_handler.dart:226-235` calls the bulk upsert
  path before falling back to per-row execution; there is no local try/catch
  around the bulk call in `_executePreparedTable`.
- `lib/features/sync/engine/push_handler.dart:315-350` has the per-row error
  handling that records RLS denial state, but that path is bypassed when the
  bulk operation rethrows.
- `lib/features/sync/engine/push_error_handler.dart:140-146` would mark a
  single-row RLS denial as failed in `change_log`; the bulk RLS path does not
  reach this handler for each bid item.
- `lib/features/sync/application/sync_coordinator.dart:388-400` catches a
  thrown engine error and returns a `SyncResult` error, but does not mark the
  individual bulk rows failed or blocked.

Current root-cause hypothesis:

The Sentry-visible `bid_items` `42501` may be the child symptom, not the first
failure. A project-number correction can create a `projects`
`(company_id, project_number)` natural-key conflict or remap path. If the
parent project fails, remaps, or is deleted locally before child FKs and queue
scope are reconciled, `bid_items` can still be planned or pushed against a
project ID that is not remotely visible under RLS. That yields `42501` and can
leave the queue dirty.

Stronger upstream hypothesis added from the bulk-path evidence:

The dirty-loop behavior is likely amplified by bulk `bid_items` push error
handling. `bid_items` can be bulk-upserted, and the bulk path rethrows a
`42501` RLS denial before the per-row `PushErrorHandler` can mark each affected
`change_log` row failed, blocked, or repairable. The coordinator then reports a
cycle-level `SyncEngine error`, but the underlying `change_log` rows can remain
pending with insufficient per-row disposition. That explains the Sentry stack
(`SupabaseSync.upsertRecords` -> `PushUpsertExecutor.executeBulkUpsert`) and
the user-visible loop where uninstall/refresh/retry keeps reaching the same
dirty state.

Self-healing gap:

The existing repair system has `dismissAbandonedLocalProjectQueueResidue`, but
it is intentionally scoped to deleted/tombstoned projects. The reported #321
case is an active project-number correction loop, so the current repair should
not be expected to clear it. A new repair needs evidence-based handling for
active project-scoped dirty state. The repair should also account for
cycle-level bulk failures that never reached per-row `change_log` disposition.

Evidence still needed:

- S21 local database snapshot for the exact stuck state.
- Remote project rows for the wrong and corrected project numbers.
- Whether the first failed row in `change_log` is `projects` or `bid_items`.
- Whether the local duplicate/remap branch ran or would have run.
- Whether `bid_items` were bulk-upserted in the same cycle after a project
  parent failure.
- Whether the stuck `bid_items` rows have `retry_count=0`, low retry counts, or
  no per-row `error_message` because the bulk failure escaped per-row handling.
- Whether disabling bulk only for this failure shape, or splitting bulk failure
  into per-row classification, repairs the loop while preserving the under-2s
  S21 sync target.

S21 baseline evidence captured 2026-05-10:

- Device `RFCNC0Y975L` was connected.
- Existing driver endpoint `http://127.0.0.1:4948/driver/ready` was not
  serving; the Flutter run control endpoint on `4950` reported `hasExited=true`.
- A read-only forensic copy of
  `databases/construction_inspector.db`, `construction_inspector.db-wal`, and
  `construction_inspector.db-shm` was captured through Android `run-as` without
  clearing app data or triggering a driver sync.
- Artifact root:
  `tools/testing/test-results/2026-05-10/s21-321-forensic-20260510-110617/`
- Snapshot summary:

```json
{
  "deviceId": "RFCNC0Y975L",
  "schemaVersion": 64,
  "pending": 0,
  "processed": 68,
  "bidItemPending": 0,
  "projectPending": 0
}
```

Evidence conclusion:

The current S21 database is clean at the moment of capture and is useful only
as a pre-reproduction baseline. It does not contain the stuck #321 queue state.
The exact create-project -> add-bid-items -> correct-project-number loop still
needs a fresh UI reproduction with local database snapshots before sync, after
the first failed sync, after any self-recovery attempt, and after final sync
timing.

Live/local agreement evidence for the clean baseline:

- Local S21 project `266291` has 58 bid items and no pending queue rows.
- Live Supabase project `266291` has the same project id and 58 bid items.
- Local `synced_projects` includes project numbers `12344`, `266291`,
  `859772`, and `864130`.
- Local processed `change_log` counts include 58 `bid_items` rows and 8
  `projects` rows, but no unprocessed rows.
- This proves the current S21 state is not the failing #321 state. It also
  gives a realistic dirty project import size for the under-2-second target:
  1 project plus 58 bid-item mutations should sync and verify cleanly after
  project-number correction.

Live constraint/index evidence:

- `public.projects` has unique index `idx_project_number_company` on
  `(company_id, project_number)`.
- `public.bid_items` has FK `bid_items_project_id_fkey`:
  `FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE`.
- `public.bid_items` has index `idx_sync_pull_bid_items_project_updated_id` on
  `(project_id, updated_at, id)`.
- `public.project_assignments` has unique constraint
  `project_assignments_project_id_user_id_key` on `(project_id, user_id)`.

Evidence conclusion:

The sync adapter's `projects` natural key matches a real live unique index, so
project-number correction can legitimately collide with an existing remote
project number for the same company. `bid_items` are hard-bound to project ids
by remote FK and RLS, so any local/remote project-id remap or visibility miss
will surface first on child pushes unless the parent transition is fully
settled before planning and executing children.

### #318 - Pending Uploads

GitHub issue: `https://github.com/Field-Guide/construction-inspector-tracking-app/issues/318`

Sentry issue in the GitHub body: FLUTTER-18.

Issue evidence:

```text
Local changes are still waiting to upload
Issue code: pending_uploads
Build: 0.2.0
Schema: v64
Repair catalog: 2026-04-24.1
Counts: pending=163, blocked=0, conflicts=0
```

Current hypothesis:

This is likely downstream of a parent/child project-scoped sync failure like
#321. The important evidence gap is why the state reports `pending=163` and
`blocked=0` if project-scoped rows are effectively blocked by failed parent
state.

Static code evidence gathered:

- `lib/features/sync/application/sync_query_service.dart:118-155` builds the
  dashboard/support pending count from distinct unprocessed record ids where
  `retry_count < maxRetryCount`.
- `lib/features/sync/engine/sync_change_log_store.dart:39-79` implements
  pending bucket counts using `processed = 0 AND retry_count < maxRetryCount`.
- `lib/features/sync/engine/sync_change_log_store.dart:81-120` implements
  blocked bucket counts using `processed = 0 AND retry_count >= maxRetryCount`.
- `lib/features/sync/presentation/support/sync_issue_report_draft.dart:95-103`
  reports `blocked_queue` only when `blockedCount > 0`.
- `lib/features/sync/presentation/support/sync_issue_report_draft.dart:125-132`
  reports `pending_uploads` when `pendingCount > 0` and sync is not running.
- `lib/core/driver/driver_data_sync_handler.dart:113-140` uses the same split
  for driver diagnostics: pending is below retry exhaustion, blocked is retry
  exhausted, and `unprocessed` is their sum.

Evidence conclusion:

The #318 `pending=163, blocked=0` state is consistent with a queue that is
stuck but has not reached retry exhaustion. That fits the #321 bulk-failure
hypothesis: if a bulk `bid_items` RLS denial aborts the push cycle before
per-row `change_log` disposition, the same rows can remain in the pending
bucket instead of becoming blocked or repairable. The diagnosis should
therefore treat `pending_uploads` with repeated sync failures as a dirty-state
classification bug, not merely a "wait for next sync" state.

Evidence still needed:

- Table buckets for the 163 pending rows.
- Retry counts and `error_message` values.
- Whether project-scoped child rows are pending because parent failures were
  not promoted to blocked diagnostics.
- Whether the repair catalog version lacks the active project-number conflict
  repair needed for #321.
- Whether the pending rows are all `retry_count=0` or low retry count after
  repeated cycle-level failures.

### #319 - `entry_quantities` Pull Abort

GitHub issue: `https://github.com/Field-Guide/construction-inspector-tracking-app/issues/319`

Sentry issue in the GitHub body: FLUTTER-19.

Issue evidence:

```text
ClientException: Software caused connection abort
```

The failing URL is a Supabase REST pull for `entry_quantities` with:

- `select=*`
- `entry_id=in.(...)`
- `updated_at=gte.2026-04-29T00:57:04.518820Z`
- `order=updated_at.asc.nullslast,id.asc.nullslast`
- `limit=200`

Current hypothesis:

The request shape points to scoped-pull pressure: a large `entry_id` `IN` list,
page size 200, ordered cursor paging, and a network abort. This belongs in the
same root-cause plan because oversized pull work can prevent dirty sync from
meeting the S21 under-2-second target.

Static code evidence gathered:

- `lib/features/sync/config/sync_config.dart:13-14` sets
  `pullPageSize=200` and `pullSafetyMargin=5 seconds`.
- `lib/features/sync/engine/pull_scope_state.dart:161-183` builds
  `viaEntry` dirty-scope pulls by loading all materialized entries for dirty
  project ids.
- `lib/features/sync/engine/pull_scope_state.dart:232-234` applies
  `entry_id IN (...)` for `viaEntry` tables.
- `lib/features/sync/engine/pull_handler.dart:265-318` pages until a page is
  smaller than 200 rows and writes page checkpoints when full pages are seen.
- `lib/features/sync/engine/supabase_sync.dart:303-318` subtracts the
  5-second cursor safety margin, then orders by `updated_at` and `id` with
  `limit(pageSize)`.

S21 baseline evidence captured 2026-05-10:

- Local `sync_metadata.last_pull_entry_quantities` is
  `2026-04-29T00:57:09.51882+00:00`.
- The #319 Sentry URL used
  `updated_at=gte.2026-04-29T00:57:04.518820Z`, exactly matching the local
  cursor minus the configured 5-second safety margin.
- Local integrity metadata for `entry_quantities` reports
  `local_count=129`, `remote_count=129`, and `drift_detected=false`.
- Current local S21 data has 129 `entry_quantities` rows across 30 distinct
  entries. Project `864130` accounts for 126 quantity rows across 31 daily
  entries.
- Both local SQLite and live Supabase `entry_quantities` have a nullable
  `project_id` column, but the current `viaEntry` pull filter still uses
  `entry_id IN (...)`.
- Live Supabase currently has `idx_entry_quantities_project` on `project_id`
  and `idx_sync_pull_entry_quantities_entry_updated_id` on
  `(entry_id, updated_at, id)`, but no observed composite
  `(project_id, updated_at, id)` index for a project-scoped pull.

Evidence conclusion:

The #319 failing URL is not random: it is the expected cursor-plus-safety-margin
shape from the current sync code and live S21 metadata. The remaining question
is whether the abort was caused by transient network conditions or by the
current `entry_id IN (...)` materialization becoming too large under dirty-scope
or full-sync conditions. This should be tested against the under-2-second S21
target with a synthetic high-entry project and with a real project like
`864130`.

Potential high-level fix direction:

- Prefer project-scoped pull for denormalized entry-child tables that already
  have `project_id`, or chunk `entry_id IN (...)` lists by a safe URL/request
  budget.
- If switching to project-scoped pull, add/verify remote indexes shaped for
  `(project_id, updated_at, id)`.
- Preserve cursor safety-margin semantics while preventing long URLs and
  oversized scoped requests.

Evidence still needed:

- Actual `IN` list size in the Sentry URL and live pull traces.
- Per-table pull timing for `entry_quantities`.
- Dirty-scope source that produced the large entry scope.
- Whether cursor resets or full-pull fallback are widening the pull.

### #315 - AutoRoute Guard Future Already Completed

GitHub issue: `https://github.com/Field-Guide/construction-inspector-tracking-app/issues/315`

Sentry issue in the GitHub body: FLUTTER-16.

Issue evidence:

```text
Bad state: Future already completed
NavigationResolver.checkGuard
StackRouter.reevaluateGuards
```

Current hypothesis:

Likely a duplicate route resolution during auth/profile/sync-state
reevaluation. It is not proven to share the same root cause as #321, but it
belongs in this plan because sync completion, profile refresh, project
selection, and app resume can all trigger route guard reevaluation.

Static code evidence gathered:

- `lib/core/router/autoroute/app_auto_router.dart:170-172` wires AutoRoute
  `reevaluateListenable` to `RouteAccessController`.
- `lib/core/router/route_access_controller.dart:48-70` captures a new route
  access snapshot on auth/config/consent dependency changes and calls
  `notifyListeners()`.
- `lib/core/router/autoroute/app_auto_router.dart:321-345` handles every guard
  navigation by reading the current snapshot, recording a decision, then
  calling either `resolver.next()` or `resolver.redirectUntil(...)`.
- `lib/core/router/autoroute/app_auto_router.dart:335` logs whether the
  resolver is reevaluating, but the decision path does not branch on
  `resolver.isReevaluating`.
- `lib/core/router/route_access_policy.dart:163-183`, `:211-227`, and
  `:316-341` contain auth, reauth, consent, and profile-gate redirect paths
  that can change while the route stack is already resolving.

S21 baseline evidence:

- Current S21 persisted logs did not contain local matches for
  `Future already completed`, `NavigationResolver`, or `reevaluateGuards`.

Evidence conclusion:

The most likely upstream #315 class is route-guard reentrancy: route access
state changes can trigger AutoRoute reevaluation while a previous guard
resolution or redirect is still completing. This needs timeline proof from
navigation logs around the Sentry event, especially `changedFields`,
`resolver.isReevaluating`, route name, current location, and decision reason.

Evidence still needed:

- Route being resolved when the exception occurs.
- Whether it coincides with auth profile refresh, sync completion, project
  selection, or app resume.
- Whether resolver completion is guarded idempotently in app code.
- Whether the same route access change emits multiple `notifyListeners()` calls
  before the previous guard decision has settled.

### #316 - Support Ticket Action Selectable When Unavailable

GitHub issue: `https://github.com/Field-Guide/construction-inspector-tracking-app/issues/316`

Sentry feedback in the GitHub body: FLUTTER-17.

Issue evidence:

```text
the bug involves the submit a ticket being selectable when it shouldn't be
available after typing a certain amount in
```

Current hypothesis:

Likely a UI validation or enabled-state mismatch in the support-ticket flow.
This may be separate from sync, but it remains in scope because support tickets
have database triggers/functions and appear in the Supabase `search_path`
findings.

Static code evidence gathered:

- `lib/features/settings/presentation/providers/support_provider.dart:28-31`
  defines submit validity as a selected subject plus a trimmed message length
  of at least 10 characters.
- `lib/features/settings/presentation/screens/help_support_form.dart:141-151`
  gates the primary `Send Report` button on `provider.canSubmit`,
  `supportReportAvailable`, and `!isSendingReport`.
- `lib/features/settings/presentation/screens/help_support_form.dart:127-132`
  enables the adjacent `Open Bug Reporter` button whenever
  `supportReportAvailable && !isSendingReport`; it does not check
  `provider.canSubmit`.
- `lib/features/settings/presentation/screens/help_support_screen.dart:209-214`
  also blocks `_sendSentryReport` if `provider.canSubmit` is false, but this
  guard is only for the primary report path.
- `lib/features/settings/presentation/providers/support_provider.dart:5-7`
  states that new reports are routed through Sentry and the legacy
  `support_tickets` table remains only for schema/sync compatibility.
- `lib/features/sync/adapters/support_ticket_adapter.dart:42-45` treats legacy
  `support_tickets` as insert-only because server-managed status updates are
  not client-editable.
- `supabase/migrations/20260402100000_add_support_tickets_updated_at.sql:16`
  defines `set_support_tickets_updated_at`, one of the mutable `search_path`
  Advisor findings, but this function belongs to the legacy table path rather
  than the current Sentry-backed UI report path.

Current refined hypothesis:

The user-visible #316 issue may be a two-button ambiguity. The primary
`Send Report` path is validity-gated, but `Open Bug Reporter` remains
selectable even when the form is incomplete. If users interpret that secondary
action as "submit a ticket", it appears available before the form is valid.
This is likely separate from #321/#318 sync dirty state.

Evidence still needed:

- Exact field and text-length condition.
- Enabled/disabled state before and after typing.
- Screenshot and logs from the support-ticket screen.
- Whether the row can actually be submitted or only appears selectable.
- Whether the user means the primary `Send Report` button or the secondary
  `Open Bug Reporter` button.

## Supabase Advisor Evidence

Command used:

```powershell
supabase db advisors --linked --type security --level warn --output json
```

Confirmed count: 98 findings.

Full Advisor artifact:

- `tools/testing/test-results/2026-05-10/supabase-advisor-evidence/security-advisor-warnings.json`
- Summary count: 98 security warnings.

Finding groups:

```text
authenticated_security_definer_function_executable = 45
anon_security_definer_function_executable = 41
function_search_path_mutable = 6
rls_disabled_in_public = 2
policy_exists_rls_disabled = 1
auth_insufficient_mfa_options = 1
auth_leaked_password_protection = 1
public_bucket_allows_listing = 1
```

### RLS Disabled Findings

Advisor evidence:

- `policy_exists_rls_disabled: public.entry_personnel`
- `rls_disabled_in_public: public.entry_personnel`
- `rls_disabled_in_public: public.sync_push_rate_limits`

Repo evidence:

- `supabase/migrations/20260222100000_multi_tenant_foundation.sql:844-872`
  defines company-scoped policies for legacy `entry_personnel`.
- `supabase/migrations/20260408173000_sync_push_rate_limit.sql:4` creates
  `public.sync_push_rate_limits`.
- `supabase/migrations/20260408173000_sync_push_rate_limit.sql:72` revokes the
  `claim_sync_push_rate_limit` function from public/anon/authenticated and
  grants service-role execution, but no RLS enablement evidence was found in
  that migration for the table itself.

Current high-level fix bucket:

- Decide whether each table should be exposed with RLS enabled or locked down
  as service-role-only implementation detail.
- `entry_personnel` appears legacy because current app behavior has moved to
  `entry_personnel_counts`, but live policies still exist.

### Mutable `search_path` Findings

Advisor-listed functions:

- `can_select_entry_content`
- `get_server_time`
- `set_support_tickets_updated_at`
- `signature_audit_log_block_mutation`
- `signature_files_block_mutation`
- `update_updated_at_column`

Repo evidence:

- `supabase/migrations/20260323000000_add_get_server_time_rpc.sql:7` defines
  `get_server_time` as `SECURITY DEFINER` without the fixed
  `SET search_path = public` pattern.
- `supabase/migrations/20260408000000_signature_tables.sql:67` and `:82`
  define signature mutation-blocking trigger functions as `SECURITY DEFINER`.

Current high-level fix bucket:

- Recreate the six functions with fixed `SET search_path`, preserving behavior
  and rollback parity.
- Add static SQL lint so future `SECURITY DEFINER` or trigger functions cannot
  be added without fixed `search_path`.

### `SECURITY DEFINER` Executable By `anon`

Advisor count: 41.

Advisor-listed function names:

```text
admin_restore_project
admin_set_company_app_config
admin_soft_delete_project
admin_soft_delete_project_assignment
admin_upsert_project_assignment
approve_join_request
broadcast_sync_hint_company
broadcast_sync_hint_contractor
broadcast_sync_hint_project
cascade_project_soft_delete
create_company
deactivate_member
enforce_assignment_assigned_by
enforce_created_by
enforce_insert_updated_at
fanout_private_sync_hint
get_my_company_id
get_server_time
handle_new_user
invoke_daily_sync_push
is_admin_or_engineer
is_approved_admin
is_approved_engineer
is_approved_project_manager
lock_assignment_columns
lock_created_by
log_assignment_change
populate_assignment_company_id
promote_to_admin
propagate_daily_entry_project_id_to_children
reactivate_member
reject_join_request
search_companies
set_updated_at
signature_audit_log_set_owner
signature_files_set_owner
stamp_deleted_by
stamp_updated_by
sync_entry_child_project_id
update_last_synced_at
update_member_role
```

Current high-level fix bucket:

- Revoke broad `EXECUTE` from `public`/`anon` for all listed functions.
- Re-grant only the RPCs that are intentionally callable by app users.
- Trigger-only functions should not be executable through PostgREST RPC.
- Role helper functions should be reviewed carefully before granting direct
  RPC execution.

### `SECURITY DEFINER` Executable By `authenticated`

Advisor count: 45.

Advisor-listed function names:

```text
admin_restore_project
admin_set_company_app_config
admin_soft_delete_project
admin_soft_delete_project_assignment
admin_upsert_project_assignment
approve_join_request
broadcast_sync_hint_company
broadcast_sync_hint_contractor
broadcast_sync_hint_project
cascade_project_soft_delete
create_company
deactivate_member
debug_emit_sync_hint_self
emit_sync_hint
enforce_assignment_assigned_by
enforce_created_by
enforce_insert_updated_at
fanout_private_sync_hint
get_my_company_id
get_pending_requests_with_profiles
get_server_time
handle_new_user
invoke_daily_sync_push
is_admin_or_engineer
is_approved_admin
is_approved_engineer
is_approved_project_manager
lock_assignment_columns
lock_created_by
log_assignment_change
populate_assignment_company_id
promote_to_admin
propagate_daily_entry_project_id_to_children
reactivate_member
register_sync_hint_channel
reject_join_request
search_companies
set_updated_at
signature_audit_log_set_owner
signature_files_set_owner
stamp_deleted_by
stamp_updated_by
sync_entry_child_project_id
update_last_synced_at
update_member_role
```

Current high-level fix bucket:

- Split functions into categories before changing grants:
  app-callable RPCs, admin-only RPCs, service-role-only RPCs, trigger-only
  functions, and helper functions.
- Revoke default broad execution, then grant least privilege by category.
- Add a migration-time lint/check so future `CREATE OR REPLACE FUNCTION`
  changes do not silently reintroduce broad execution.

### Broken Sync Hint Function

Advisor/DB-lint evidence already captured:

```text
public.invoke_daily_sync_push:
function extensions.http_post(url => text, headers => jsonb, body => jsonb)
does not exist
```

Live function signature evidence already captured:

```text
extensions.http_post(uri character varying, content character varying, content_type character varying)
extensions.http_post(uri character varying, data jsonb)
```

Repo evidence:

- `supabase/migrations/20260408160000_sync_hint_final_state.sql:74` creates
  `public.invoke_daily_sync_push(p_payload jsonb)`.
- `supabase/migrations/20260408160000_sync_hint_final_state.sql:96` calls
  `extensions.http_post` with named `url`, `headers`, and `body` arguments.
- `supabase/migrations/20260408160000_sync_hint_final_state.sql:431`, `:486`,
  and `:544` call `public.invoke_daily_sync_push(v_payload)`.

Current high-level fix bucket:

- Fix the function to use an existing `extensions.http_post` overload or
  replace it with the current supported HTTP extension call shape.
- Verify sync hint fan-out works after fixing it.
- Add lint/static SQL guard for unsupported `extensions.http_post` named
  argument shape.

### Storage And Auth Findings

Advisor evidence:

- `public_bucket_allows_listing`: public bucket `releases` has broad listing
  through policy `Anyone can download releases`.
- `auth_insufficient_mfa_options`: too few MFA options enabled.
- `auth_leaked_password_protection`: leaked password protection disabled.

Current high-level fix bucket:

- Storage: decide whether `releases` needs anonymous object URL download only
  or broad listing. Remove listing if not required.
- Auth: treat MFA and leaked password protection as security backlog or release
  gate depending on product policy.

Repo evidence:

- `supabase/migrations/20260303100000_releases_storage_bucket.sql:4`
  documents the bucket purpose as APK distribution.
- `supabase/migrations/20260303100000_releases_storage_bucket.sql:5`
  creates the `releases` storage bucket.
- `supabase/migrations/20260303100000_releases_storage_bucket.sql:15`
  documents the policy intent as allowing anyone to download releases.
- `supabase/migrations/20260303100000_releases_storage_bucket.sql:16-19`
  creates policy `Anyone can download releases` on `storage.objects` for
  `SELECT TO public USING (bucket_id = 'releases')`.
- `supabase/migrations/20260303000000_app_config_and_entry_status.sql:44`
  references populating `download_url` after the first APK upload to the
  `releases` bucket.

## Live Database Verification

The Supabase database password was loaded from `.env.secret` into the shell
environment for verification. The password was not printed or copied into this
plan.

### RLS State Verification

Command class:

```powershell
supabase db query --linked -o json "<pg_class / pg_policy query>"
```

Live results for the relevant tables:

```text
bid_items: rls_enabled=true, policy_count=4
entry_personnel: rls_enabled=false, policy_count=4
project_assignments: rls_enabled=true, policy_count=3
projects: rls_enabled=true, policy_count=4
sync_push_rate_limits: rls_enabled=false, policy_count=0
```

Evidence conclusion:

- Advisor is correct for `entry_personnel`: four policies exist but RLS is
  disabled.
- Advisor is correct for `sync_push_rate_limits`: table is in `public`, has no
  policies, and RLS is disabled.
- `projects`, `project_assignments`, and `bid_items` all have RLS enabled.

### #321 RLS Policy Verification

Live `bid_items` policy evidence:

- `company_bid_items_insert` allows insert only when `project_id` is in
  `projects` for `get_my_company_id()` and the user is not a viewer.
- `company_bid_items_update` and delete use the same company project visibility
  plus non-viewer check.
- `company_bid_items_select` uses project company visibility.

Live `projects` policy evidence:

- `company_projects_insert` requires `company_id = get_my_company_id()` and
  `is_admin_or_engineer()`.
- `company_projects_update` requires same company, `is_admin_or_engineer()`,
  and either not deleted, created by current user, or approved admin.
- `company_projects_select` requires same company and either admin/engineer or
  an active assignment for the project.

Evidence conclusion:

The #321 `bid_items` `42501` is consistent with a child row whose `project_id`
does not point to a project visible under the current user's company/role RLS
context. That supports the parent-first and remap hypotheses; it does not yet
prove which parent failure happened first.

### Function ACL Verification

Live query checked the Advisor-listed `SECURITY DEFINER` function set with
`has_function_privilege`.

Compact result:

```text
function_count=45
anon_execute_count=41
authenticated_execute_count=45
public_execute_count=34
```

Evidence conclusion:

- The Advisor counts are live-confirmed.
- Every function in the authenticated warning set is executable by
  `authenticated`.
- 41 of the 45 checked functions are executable by `anon`.
- 34 are executable through `PUBLIC`, meaning broad default function execution
  remains part of the root cause.
- Some functions with `public_execute=false` still have `anon_execute=true`,
  so the fix must check explicit role grants, not only `PUBLIC`.

Examples with `anon_execute=true` and `authenticated_execute=true`:

- `admin_restore_project(p_project_id text)`
- `admin_set_company_app_config(p_key text, p_value text)`
- `admin_soft_delete_project(p_project_id text)`
- `admin_upsert_project_assignment(p_project_id text, p_user_id uuid)`
- `approve_join_request(request_id uuid, assigned_role text)`
- `broadcast_sync_hint_company()`
- `create_company(company_name text)`
- `deactivate_member(target_user_id uuid)`
- `fanout_private_sync_hint(p_company_id uuid, p_payload jsonb)`
- `invoke_daily_sync_push(p_payload jsonb)`
- `promote_to_admin(target_user_id uuid)`
- `reactivate_member(target_user_id uuid)`
- `reject_join_request(request_id uuid)`
- `search_companies(query text)`
- `update_member_role(target_user_id uuid, new_role text)`

Examples with `authenticated_execute=true` but `anon_execute=false`:

- `debug_emit_sync_hint_self(p_project_id uuid, p_table_name text, p_scope_type text)`
- `emit_sync_hint(p_company_id uuid, p_project_id uuid, p_table_name text, p_scope_type text)`
- `get_pending_requests_with_profiles(p_company_id uuid)`
- `register_sync_hint_channel(p_device_install_id text, p_platform text, p_app_version text)`

### Mutable `search_path` Live Verification

Live results for the six Advisor-listed functions:

```text
can_select_entry_content(p_entry_id text): proconfig=null, security_definer=false
get_server_time(): proconfig=null, security_definer=true
set_support_tickets_updated_at(): proconfig=null, security_definer=false
signature_audit_log_block_mutation(): proconfig=null, security_definer=false
signature_files_block_mutation(): proconfig=null, security_definer=false
update_updated_at_column(): proconfig=null, security_definer=false
```

Evidence conclusion:

- All six have no fixed `search_path`.
- Only `get_server_time` is also `SECURITY DEFINER`.
- The high-level fix still needs `SET search_path` for all six, but the risk
  categories differ: one definer RPC/helper and five invoker/trigger helpers.

### DB Lint Verification

Command used after loading the password:

```powershell
supabase db lint --linked --level warning --output json
```

Live DB lint result:

```text
public.invoke_daily_sync_push:
  level=error
  sqlState=42883
  message=function extensions.http_post(url => text, headers => jsonb, body => jsonb) does not exist

public.get_table_integrity:
  warning extra: OUT variable "row_count" is maybe unmodified
  warning extra: OUT variable "max_updated_at" is maybe unmodified
  warning extra: OUT variable "id_checksum" is maybe unmodified
  detail=cannot determine result of dynamic SQL
```

Evidence conclusion:

- The `invoke_daily_sync_push` failure is live-confirmed, not only migration
  inspection.
- The `get_table_integrity` warnings are likely lint limitations around dynamic
  SQL and should be reviewed separately from the security Advisor findings.

Full DB lint artifact:

- `tools/testing/test-results/2026-05-10/supabase-advisor-evidence/db-lint-warning-output.json`
- Summary count: 2 lint result objects.

### Storage Bucket Live Verification

Live `storage.buckets` evidence for `releases`:

```text
id=releases
name=releases
public=true
file_size_limit=524288000
allowed_mime_types={
  application/vnd.android.package-archive,
  application/octet-stream
}
```

Live `storage.objects` policy evidence:

```text
policyname=Anyone can download releases
roles={public}
cmd=SELECT
qual=(bucket_id = 'releases'::text)
with_check=null
```

Evidence conclusion:

- The Advisor public-bucket listing finding is live-confirmed.
- The current policy grants broad anonymous `SELECT` over all objects in the
  `releases` bucket. That supports anonymous release download, but also
  permits listing/discovery behavior unless Supabase Storage access is narrowed
  by a different mechanism.
- High-level fix remains a product/security decision: keep intentional public
  release listing, or replace broad `SELECT` with a narrower release download
  path such as signed URLs or a controlled metadata endpoint.

## Lint / VS Code Guardrail Evidence

Repo evidence:

- `analysis_options.yaml` uses the `custom_lint` analyzer plugin.
- `pubspec.yaml` includes `custom_lint` and local `field_guide_lints`.
- Local lint package lives under `fg_lint_packages/field_guide_lints`.

Guardrail candidates:

- Static SQL lint: public table created without `ENABLE ROW LEVEL SECURITY`.
- Static SQL lint: policy created for a table without RLS enablement.
- Static SQL lint: `SECURITY DEFINER` without fixed `SET search_path`.
- Static SQL lint: function created without matching `REVOKE EXECUTE`.
- Static SQL lint: unsupported `extensions.http_post(url := ..., headers := ...,
  body := ...)` call shape.
- Static SQL lint: migration/rollback mismatch for security-sensitive DDL.
- VS Code task/problem matcher: live Supabase Advisor and DB lint, because live
  checks are network/auth dependent and should not run inside Dart analyzer.

## Current Root-Cause Map

This is the current evidence-backed map before implementation. Items can be
revised as S21 reproduction evidence is added.

### RC-1: Active Project-Number Correction Dirty-State Loop

Primary issues: #321 and #318.

Most upstream suspected cause:

- Project identity is split between a mutable local project number, a remote
  unique natural key `projects(company_id, project_number)`, and child
  `bid_items.project_id` foreign keys.
- Changing the project number after adding bid items can put the parent project
  into a remap, collision, or visibility transition that is not fully known when
  child table plans are prepared.
- `bid_items` then push through the bulk-upsert path. When Supabase rejects the
  batch with a table-level RLS denial, the bulk path rethrows before per-row
  `change_log` disposition, so rows can remain pending without useful repair
  metadata.
- The current repair catalog handles a narrower abandoned local-project case.
  It does not yet prove active repair for a dirty project-number correction with
  already-created child rows.

Evidence already gathered:

- #321 GitHub issue is open and current as of 2026-05-10. It reports Sentry
  FLUTTER-1A with `bid_items` RLS denial `42501`.
- #318 GitHub issue is open and current as of 2026-04-29. It reports
  `pending=163`, `blocked=0`, `conflicts=0`, schema v64, build 0.2.0.
- The S21 clean baseline has schema v64, `pending=0`, and latest project
  `266291` has 58 local and 58 remote bid items. The stuck state still needs a
  fresh reproduction capture.
- Live Supabase confirms `projects(company_id, project_number)` is uniquely
  indexed and `bid_items.project_id` references `projects(id)`.
- Static code evidence confirms project natural-key remap and child-FK remap
  happen in different branches, table plans are prepared before execution, and
  bulk `bid_items` failures bypass per-row failure marking.

High-level fix direction:

- Make project-number correction an explicit sync engine scenario with durable
  parent identity resolution before children push.
- Re-plan or quarantine child table plans after any parent remap/failure in the
  same cycle.
- On bulk RLS/constraint failure, split or fall back to per-row disposition so
  every dirty row receives actionable retry/blocked/repair state.
- Add self-healing repair for active project-number correction dirty states:
  remapable parent, missing remote parent, collided project number, child rows
  pointing at stale local IDs, and orphaned project enrollment state.

Acceptance evidence:

- On S21, the exact user flow must complete a full dirty sync in under
  2 seconds.
- Final SQLite and server state must show `pending=0`, `blocked=0`,
  `unprocessed=0`, `errors=0`, and `rlsDenials=0`.
- A forced bad intermediate state must self-repair through the sync engine,
  without uninstall, manual state clearing, or direct sync endpoint shortcuts.

### RC-2: Entry-Scoped Pull Request Pressure

Primary issue: #319.

Most upstream suspected cause:

- `entry_quantities` pulls can be scoped by materialized entry IDs and emitted
  as one REST `entry_id=in.(...)` filter.
- The #319 issue URL has 30 unique entry IDs, length 1549 encoded characters
  and 1359 decoded characters, with `limit=200` and
  `order=updated_at.asc.nullslast,id.asc.nullslast`.
- The URL cursor `updated_at=gte.2026-04-29T00:57:04.518820Z` matches the S21
  local `last_pull_entry_quantities` cursor minus the configured 5-second
  safety margin.
- Current local and remote integrity for S21 `entry_quantities` is clean, so
  this is more likely request-shape or transient-network pressure than proven
  data drift.

High-level fix direction:

- Prefer project-scoped pulls for entry-child tables that already denormalize
  `project_id`, or chunk `entry_id IN (...)` filters by a safe URL/request
  budget.
- Preserve the 5-second cursor safety margin, but cap scoped-pull request size
  and record per-table pull timing.
- If using `project_id` pulls, add or verify remote indexes for
  `(project_id, updated_at, id)` on affected entry-child tables.

Acceptance evidence:

- S21 dirty-sync pull timing stays inside the under-2-second full-sync target.
- Pull logs show bounded request sizes, no connection aborts, and clean
  integrity metadata after sync.

### RC-3: Route Guard Reentrancy

Primary issue: #315.

Most upstream suspected cause:

- Route access state changes notify AutoRoute while a previous guard decision
  or redirect can still be settling.
- The guard logs `resolver.isReevaluating`, but current evidence does not show
  an idempotent branch that prevents double completion.

High-level fix direction:

- Add timeline evidence first: route name, location, decision reason,
  `changedFields`, `resolver.isReevaluating`, and the auth/profile/sync event
  that caused reevaluation.
- Fix at the route access controller/guard boundary with coalescing or
  idempotent resolution, not by hiding the exception downstream.

Acceptance evidence:

- Reauth/profile/sync/app-resume transitions no longer produce
  `Future already completed`.
- UI E2E screenshots and logs show no navigation stalls or duplicate redirects.

### RC-4: Support Report Action-State Mismatch

Primary issue: #316.

Most upstream suspected cause:

- The primary `Send Report` path is gated by subject selection and trimmed
  message length.
- The adjacent `Open Bug Reporter` action remains enabled whenever Sentry
  feedback is available and sending is idle.
- Users may reasonably read that secondary action as the support-ticket submit
  path, making it appear selectable before the form is valid.

High-level fix direction:

- Gather screenshot/UI-state evidence for the exact typed-length threshold.
- Align the two support actions so only intentionally available actions appear
  enabled, with distinct labels/states if they serve different workflows.
- Keep legacy `support_tickets` table changes separate from current
  Sentry-backed report UI unless reproduction proves a database path is used.

Acceptance evidence:

- Button enabled states match the actual action contract at every validation
  boundary.
- Sentry report submission remains blocked for invalid form state.

### RC-5: Supabase Security Advisor Hygiene

Scope: 98 Security Advisor findings plus 2 live DB lint findings.

Most upstream suspected causes:

- RLS drift: live `entry_personnel` has policies but RLS disabled even though
  earlier migrations include `ALTER TABLE entry_personnel ENABLE ROW LEVEL
  SECURITY`; local and remote migration versions match through
  `20260428161000`, so this needs drift explanation rather than only applying
  a missing migration.
- New internal rate-limit table: `sync_push_rate_limits` was created without
  RLS. It is service-role/RPC-owned today, but a public schema table without RLS
  still needs explicit lockdown or schema isolation.
- Function ACL posture: 45 security-definer functions are executable by
  `authenticated`, 41 by `anon`, and 34 through `public`. Some functions are
  intentionally RPCs, some are trigger helpers, and some service-only functions
  are already correctly revoked; the plan must categorize before revoking.
- Mutable `search_path`: 6 functions have no fixed `search_path`; only
  `get_server_time` is also `SECURITY DEFINER`.
- Broken sync hint fan-out: `invoke_daily_sync_push` calls
  `extensions.http_post(url := ..., headers := ..., body := ...)`, but the live
  extension exposes only the older positional signatures captured in the
  evidence section.
- Storage: the `releases` bucket is intentionally public for APK download, but
  the current `SELECT TO public` policy permits broad listing/discovery.
- Auth config: MFA options and leaked-password protection are release/security
  posture findings, not app-code root causes.

High-level fix direction:

- Apply RLS enable/lockdown migrations with rollback parity and live Advisor
  verification.
- Revoke broad function execute grants by category: public RPCs, authenticated
  RPCs, trigger-only helpers, service-role-only helpers, and internal policy
  helpers.
- Add `SET search_path` to all Advisor-listed functions, including invoker
  trigger helpers.
- Fix or replace the `invoke_daily_sync_push` HTTP call to match the installed
  extension signature.
- Decide whether public release listing is acceptable; if not, replace it with
  signed/controlled download access.
- Add VS Code guardrails through static SQL lint for migration patterns and a
  separate live Supabase Advisor/DB-lint task for network-dependent checks.

Acceptance evidence:

- Supabase Security Advisor returns zero unresolved findings in the accepted
  release gate, or documented accepted-risk exceptions for product decisions
  such as release distribution.
- `supabase db lint --linked --level warning` no longer reports the
  `invoke_daily_sync_push` error.
- Custom lint/task output is visible in VS Code so developers do not need to
  rely only on the Supabase dashboard.

## Current Evidence Gaps Before Implementation

This section is retained as the original pre-implementation gap ledger. The
2026-05-10 implementation pass closed the S21/device gaps listed here with the
artifacts referenced in the active checklist and checkpoint. Supabase Auth
leaked-password protection remains an accepted-risk release posture exception
for this build because the linked project requires a paid Supabase plan tier.

- [x] S21 reproduction artifacts for #321.
- [x] Exact affected project number(s) and remote rows for #321.
- [x] Local stuck SQLite queue snapshot for #321/#318.
- [x] Support ticket screen reproduction details for #316.
- [x] Navigation transition timeline for #315.
- [x] Full `entry_quantities` pull trace/timing for #319.

## Append Log

### 2026-05-10 Initial Evidence Capture

- Refreshed GitHub issue bodies for #315, #316, #318, #319, and #321.
- Confirmed Supabase Advisor currently reports 98 security findings.
- Preserved Advisor finding groups and function-name lists.
- Preserved #321 static code evidence around project natural keys, child
  dependencies, table planning, failed-parent checks, and natural-key remap.
- Preserved Supabase migration evidence for `entry_personnel`,
  `sync_push_rate_limits`, and `invoke_daily_sync_push`.
- Recorded the dirty-queue S21 acceptance target as under 2 seconds end to end.

### 2026-05-10 Live Supabase Verification After Password Added

- Loaded `SUPABASE_DB_PASSWORD` from `.env.secret` for shell-only live DB
  checks.
- Verified RLS state and policy counts for `bid_items`, `entry_personnel`,
  `project_assignments`, `projects`, and `sync_push_rate_limits`.
- Verified `entry_personnel` has 4 policies with RLS disabled.
- Verified `sync_push_rate_limits` has 0 policies with RLS disabled.
- Verified the Advisor executable-function counts against live
  `has_function_privilege`: 45 authenticated, 41 anon, 34 public.
- Verified all 6 mutable `search_path` findings have `proconfig=null`.
- Verified `supabase db lint --linked --level warning` reports the
  `invoke_daily_sync_push` `http_post` signature error and `get_table_integrity`
  dynamic-SQL OUT-variable warnings.
- Verified the live `releases` bucket is public and has the broad
  `Anyone can download releases` `SELECT TO public` policy over
  `storage.objects`.

### 2026-05-10 #321 Bulk Push Evidence

- Added code evidence that `bid_items` can use bulk upsert because the adapter
  has no natural-key columns.
- Added code evidence that bulk RLS denial is rethrown from
  `_tryBulkExecutePushPlan` before per-row `PushErrorHandler` marking.
- Added code evidence that the cycle-level coordinator catch returns a sync
  error without assigning per-row failed/blocked disposition.
- Strengthened the #321 hypothesis: project-number correction may create the
  parent visibility/remap problem, while bulk `bid_items` error handling keeps
  the queue dirty by skipping per-row repair metadata.
- Captured an S21 forensic database baseline under
  `tools/testing/test-results/2026-05-10/s21-321-forensic-20260510-110617/`;
  schema is v64 and the baseline queue is clean (`pending=0`), so the stuck
  state must still be reproduced and captured.
- Verified local/remote agreement for the newest clean-baseline project:
  project `266291` has 58 local bid items and 58 live remote bid items.
- Verified the live `projects` unique index on `(company_id, project_number)`
  and the live `bid_items.project_id -> projects.id` FK.

### 2026-05-10 Supabase Artifact Preservation

- Saved the full 98-warning Security Advisor output to
  `tools/testing/test-results/2026-05-10/supabase-advisor-evidence/security-advisor-warnings.json`.
- Saved the live DB lint output to
  `tools/testing/test-results/2026-05-10/supabase-advisor-evidence/db-lint-warning-output.json`.
- Saved a compact artifact summary with `advisorWarningCount=98` and
  `dbLintCount=2`.

### 2026-05-10 #319 Cursor Evidence

- Matched the #319 Sentry URL `entry_quantities` cursor to the S21 local
  `sync_metadata` cursor minus the configured 5-second safety margin.
- Recorded that current S21 integrity metadata reports `entry_quantities`
  `local_count=129`, `remote_count=129`, and no drift.
- Added code evidence for `viaEntry` `entry_id IN (...)` scoping, 200-row
  paging, and `updated_at,id` cursor ordering.

### 2026-05-10 #318 Pending Classification Evidence

- Added code evidence that pending rows are defined by
  `processed=0 AND retry_count < maxRetryCount`, while blocked rows require
  `retry_count >= maxRetryCount`.
- Added support-report evidence that `pending_uploads` is emitted when
  `pendingCount > 0` and blocked count is zero.
- Connected #318 to #321: cycle-level bulk failures can leave rows pending
  rather than failed/blocked, producing the observed `pending=163, blocked=0`
  shape.

### 2026-05-10 #315 Route Guard Evidence

- Added AutoRoute evidence that the router reevaluates guards from
  `RouteAccessController` changes.
- Added evidence that guard handling always calls `resolver.next()` or
  `resolver.redirectUntil(...)` without a reentrancy branch for
  `resolver.isReevaluating`.
- Current S21 logs do not contain the #315 exception, so this remains a Sentry
  and future-repro timeline evidence item.

### 2026-05-10 #316 Support Report Evidence

- Added evidence that the primary `Send Report` button is gated by
  `SupportProvider.canSubmit`.
- Added evidence that the secondary `Open Bug Reporter` button is independent
  of form validity and is enabled whenever Sentry feedback is available.
- Added evidence that the legacy `support_tickets` table remains a sync/schema
  compatibility path; current UI support reports go through Sentry.

### 2026-05-10 Root-Cause Map Append

- Re-verified GitHub issue bodies for #315, #316, #318, #319, and #321 through
  `gh issue view`.
- Added #319 URL metrics from the issue body: 30 unique entry IDs, 1549 encoded
  URL characters, 1359 decoded URL characters, `limit=200`, and
  `updated_at=gte.2026-04-29T00:57:04.518820Z`.
- Ran `supabase migration list --linked`; local and remote migration versions
  match through `20260428161000`, so live `entry_personnel` RLS disablement is
  treated as schema drift or later state mutation rather than a simply missing
  migration.
- Added migration evidence that `entry_personnel` had historical
  `ENABLE ROW LEVEL SECURITY` statements, while live Advisor still reports RLS
  disabled.
- Added migration evidence that `sync_push_rate_limits` was created as a public
  table with no `ENABLE ROW LEVEL SECURITY` statement in its defining
  migration.
- Added live function ACL evidence showing broad executable security-definer
  grants coexist with some already-correct service-only revokes, so the fix
  must categorize functions before revoking grants.
- Added the current root-cause map and high-level fix buckets for #321/#318,
  #319, #315, #316, and the 98 Supabase findings.

### 2026-05-10 Implementation Verification Capture

- Linked/live Supabase deployment completed against the linked remote project.
  Final DB lint artifact:
  `tools/testing/test-results/2026-05-10/supabase-live/db-lint-final-20260510.json`.
- Final Security Advisor artifact:
  `tools/testing/test-results/2026-05-10/supabase-live/advisor-final-20260510.json`.
  Remaining finding is `auth_leaked_password_protection`; the linked
  Management API rejected enabling it because the project is not on a Pro-or-up
  plan, and the user accepted skipping that posture warning for this build.
- S21 #321/#318 UI-triggered project-number correction sync artifact:
  `tools/testing/test-results/2026-05-10/s21-sync-root-cause/project-number-correction/14-ui-full-sync-measurement.json`.
  The dirty queue reached `pending=0`, `blocked=0`, `unprocessed=0`,
  `errors=0`, and `rlsDenials=0`; the queue drained at 1589 ms, while the full
  dashboard sync action completed at 4528 ms because it includes exhaustive
  pull/post-sync work.
- S21 #319 bounded `entry_quantities` pull artifact:
  `tools/testing/test-results/2026-05-10/s21-sync-root-cause/entry-quantities-bounded/entry-quantities-bounded-summary.json`.
- S21 #315 route guard artifact:
  `tools/testing/test-results/2026-05-10/20260510-s21-route-guard-auth-rerun/summary.json`.
  Rerun passed with no retained runtime/layout/sync warnings and no
  `Future already completed`/`NavigationResolver` matches.
- S21 #316 support-action artifact:
  `tools/testing/test-results/2026-05-10/s21-sync-root-cause/support-action-state/summary.json`.
  Invalid visible support actions did not submit and created no
  `support_tickets` change-log rows.
