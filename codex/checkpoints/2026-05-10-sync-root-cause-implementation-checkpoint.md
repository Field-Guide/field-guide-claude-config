# Sync Root-Cause Implementation Checkpoint

Controlling plan:
`.codex/plans/2026-05-10-sync-root-cause-supabase-advisor-evidence-plan.md`.

## Closure Rule

Every closed checkbox in the controlling plan needs one of these references:

- code evidence with file paths and line-relevant notes
- a local test command and result
- an accepted device/backend artifact path
- an explicitly documented blocker or accepted-risk decision

## Slice Log

### 2026-05-10 - P0 Plan Reframe

- Converted the May 10 evidence plan into the active implementation checklist
  while preserving the existing evidence ledger.
- Added this checkpoint file as the slice-by-slice implementation and
  verification log.

### 2026-05-10 - P1 #321/#318 Project-Number Dirty Sync Loop

- Code:
  - `lib/features/sync/engine/push_handler.dart` now plans and executes pushes
    table-by-table with a shared planning context, so same-cycle parent remaps
    and parent failures are visible before child table push.
  - `lib/features/sync/engine/push_table_planner.dart` consults same-cycle
    parent failures before child rows are considered pushable.
  - `lib/features/sync/engine/push_handler_support.dart` falls back from bulk
    upsert to per-row disposition for RLS, unique, FK, and permanent failures,
    while preserving auth/network/rate-limit/transient rethrow behavior.
  - `lib/features/sync/engine/push_error_handler.dart` marks RLS/FK child
    failures blocked instead of converting them to permanent failed state too
    early.
  - `lib/features/sync/engine/local_record_store.dart` reconciles natural-key
    project remaps across child project IDs, `synced_projects`, project-scoped
    `change_log.project_id`, and assignment/enrollment state.
  - `lib/features/sync/engine/sync_repair_debug_store_queue_residue.dart` and
    `lib/features/sync/application/repairs/repair_sync_state_v2026_05_10_active_project_number_correction.dart`
    add active project-number correction repair separate from abandoned/deleted
    project cleanup.
- Tests:
  - `flutter test test/features/sync/engine/push_handler_contract_test.dart test/features/sync/application/sync_state_repair_runner_test.dart ...`
    passed in the final targeted run.
  - Added contract coverage for natural-key remap before child push,
    same-cycle parent failure blocking, and bulk RLS fallback to per-row
    disposition.
- Invariant audit:
  - No direct production `change_log` inserts were added.
  - No `sync_status` revival was added.
  - Error classification still routes through `SyncErrorClassifier`.
  - `SyncCoordinator` remains the production sync entrypoint.

### 2026-05-10 - P2 #319 Entry Quantity Pull Pressure

- Code:
  - `lib/features/sync/engine/pull_scope_state.dart` supports adapter-declared
    project-scoped pulls for `viaEntry` tables.
  - `lib/features/sync/engine/pull_handler.dart` emits `entry_quantities` pull
    traces with scope source, estimated request length, project/entry ID counts,
    page count, elapsed time, and cursor fields.
  - `lib/features/sync/adapters/table_adapter.dart`,
    `adapter_config.dart`, and `simple_adapters.dart` expose
    `supportsProjectScopedPull`; production `entry_quantities`,
    `entry_contractors`, and `entry_personnel_counts` opt in.
  - `supabase/migrations/20260510120000_sync_root_cause_security_hardening.sql`
    adds the project-scoped `entry_quantities(project_id, updated_at, id)`
    index.
- Tests:
  - `test/features/sync/engine/pull_handler_scope_contracts_test.dart` proves
    `entry_quantities` pulls via `project_id` without materialized entry IDs.
  - Final `pull_handler_test.dart` targeted run passed and retained existing
    cursor/pagination coverage.

### 2026-05-10 - P3 #315 Route Guard Reentrancy

- Code:
  - `lib/core/router/route_access_controller.dart` records changed access
    fields and inferred trigger source.
  - `lib/core/router/route_access_controller.dart` now records the route
    location/name and reevaluation flag attached to the last guard decision.
  - `lib/core/router/autoroute/app_auto_route_access_bridge.dart` and
    `app_auto_router.dart` log route, location, decision reason, trigger
    source, changed fields, resolver resolved state, and
    `resolver.isReevaluating`.
  - Guard completion now uses idempotent `_resolveOnce` and `_redirectOnce`
    helpers and avoids completing an already resolved resolver during
    reevaluation.
  - `lib/core/driver/state/ui_region_builder.dart` exposes route-scoped guard
    decision diagnostics, and
    `lib/core/driver/device_state_machine_predicates.dart` ignores stale
    redirect decisions recorded for a previous visible route.
- Tests:
  - `flutter test test/core/router/route_access_controller_test.dart test/core/router/autoroute/app_auto_router_test.dart test/core/driver/device_state_machine_test.dart test/core/driver/state/ui_region_builder_test.dart --reporter compact`
    passed after the stale-redirect fix.
  - Final combined targeted run including support tests also passed.
- S21 verification:
  - First S21 route-auth run exposed stale
    `pendingGuardRedirect=/projects` while `/sync/dashboard` was already
    visible.
  - After the route-scoped guard diagnostic fix, rerun artifact
    `tools/testing/test-results/2026-05-10/20260510-s21-route-guard-auth-rerun/summary.json`
    passed with `runtimeErrors=0`, `layoutDefectCount=0`, and final
    `pendingGuardRedirect=null`.
  - Log scan over that rerun found no `Future already`, `NavigationResolver`,
    `already completed`, duplicate-completion, or
    `route_guard_redirect_pending` matches.

### 2026-05-10 - P4 #316 Support Report Button State

- Code:
  - `lib/features/settings/presentation/screens/help_support_screen.dart` and
    `help_support_form.dart` align the primary support report action and
    secondary Sentry bug reporter action on the same validation/availability
    state.
  - Sentry-backed bug reporting remains separate from support-ticket
    submission.
- Tests:
  - `test/features/settings/presentation/screens/help_support_screen_test.dart`
    passed in the final targeted run, including invalid-state coverage for the
    visible bug reporter action.
- S21 verification:
  - Artifact
    `tools/testing/test-results/2026-05-10/s21-sync-root-cause/support-action-state/summary.json`
    passed on the S21 against real auth/backend state.
  - Invalid `Send Report` was refused with `409 target_not_enabled`.
  - The visible `Open Bug Reporter` control was disabled on-screen; a
    user-level coordinate tap left the route on `/help-support`, kept
    `HelpSupportScreen` visible, and created no `support_tickets` change-log
    rows.

### 2026-05-10 - P5 Supabase Advisor And DB Lint Fixes

- Code and migration:
  - `supabase/migrations/20260510120000_sync_root_cause_security_hardening.sql`
    enables/locks down RLS for `entry_personnel` and
    `sync_push_rate_limits`, categorizes function execute grants, revokes broad
    inappropriate execute access, sets fixed `search_path` for the six
    Advisor-listed functions, fixes `invoke_daily_sync_push` for the installed
    `extensions.http_post(uri, data jsonb)` signature, and adds the
    `entry_quantities` pull index.
  - `supabase/rollbacks/20260510120000_rollback.sql` provides rollback parity
    for the security-sensitive migration. It intentionally preserves
    `entry_personnel` RLS rather than disabling a baseline security posture.
  - `supabase/functions/daily-sync-push/index.ts` accepts the service-role key
    in the JSON body for the database `http_post(uri,jsonb)` path.
  - `supabase/config.toml` disables JWT verification for the edge function
    because the installed database `http_post` overload cannot send headers.
  - `docs/security/release-bucket-posture.md` documents the public releases
    bucket posture: public object URLs are allowed, broad anonymous object
    listing is not.
- Validation:
  - `python tools/supabase/validate_migration_rollbacks.py` passed.
  - `python tools/supabase/check_changed_migration_rollbacks.py supabase/migrations/20260510120000_sync_root_cause_security_hardening.sql`
    passed.
  - `supabase db advisors --linked --type security --level warn --output json`
    is the correct live Advisor command and was captured before linked
    deployment to
    `tools/testing/test-results/2026-05-10/supabase-live/advisor-before-20260510-sync-root-cause.json`.
  - Early linked DB lint captured the `invoke_daily_sync_push` `http_post`
    signature finding before deployment; the final linked lint artifact below
    shows that finding is closed.
  - Linked/live deployment completed through `supabase db push --linked --yes`
    for:
    - `20260510120000_sync_root_cause_security_hardening.sql`
    - `20260510160000_security_definer_private_wrappers.sql`
    - `20260510163000_fix_integrity_rpc_out_vars.sql`
  - Edge function deployment completed with
    `supabase functions deploy daily-sync-push --use-api --no-verify-jwt`.
  - Final linked DB lint artifact
    `tools/testing/test-results/2026-05-10/supabase-live/db-lint-final-20260510.json`
    reports `No schema errors found`.
  - Final linked Advisor artifact
    `tools/testing/test-results/2026-05-10/supabase-live/advisor-final-20260510.json`
    has one remaining warning: `auth_leaked_password_protection`.
  - Management API verification showed `password_hibp_enabled=false`; PATCHing
    `password_hibp_enabled=true` was rejected because leaked-password
    protection requires a Supabase Pro plan or higher. This is the remaining
    plan-tier posture warning, and the user accepted skipping it for this
    build on 2026-05-10.
  - Function wrapper verification artifact
    `tools/testing/test-results/2026-05-10/supabase-live/function-wrapper-verification-20260510.json`
    reports `public_executable_security_definer_count=0`.

### 2026-05-10 - S21 Acceptance Verification

- #321/#318 project-number correction:
  - Artifact directory:
    `tools/testing/test-results/2026-05-10/s21-sync-root-cause/project-number-correction/`.
  - User-visible flow on S21 created project
    `COD321-WRONG-20260510133125`, added bid item
    `321-20260510133125`, corrected the project number to
    `COD321-FIX-20260510133125`, then triggered full sync from the Sync
    Dashboard.
  - `14-ui-full-sync-measurement.json` reports
    `triggeredThroughUi=true`, `directDriverSyncEndpointUsed=false`, and
    final `pending=0`, `blocked=0`, `unprocessed=0`, `conflicts=0`,
    `rlsDenials=0`, `errors=0`.
  - Dirty queue drained by the sample at 1589 ms; total user-facing full sync
    completion was 4528 ms because the full dashboard action includes
    exhaustive pull/post-sync work.
  - Final remote evidence shows one project with corrected project number and
    one remote bid item.
- #319 entry quantity pull pressure:
  - Artifact directory:
    `tools/testing/test-results/2026-05-10/20260510-s21-entry-quantities-bounded/`.
  - Trace evidence copied to
    `tools/testing/test-results/2026-05-10/s21-sync-root-cause/entry-quantities-bounded/entry-quantities-pull-trace-logcat.txt`.
  - The `entry_quantities` pull used `scopeSource=project_id`,
    `projectIdCount=1`, `entryIdCount=0`, `pageCount=1`, and bounded
    estimated request length 191 to 259.
  - Summary reports `passed=true`, `directDriverSyncEndpointUsed=false`,
    `runtimeErrors=0`, `loggingGaps=0`, and final queue count 0.

### 2026-05-10 - P6 Guardrails

- Code:
  - `tools/supabase/lint_sql_security.py` adds static SQL coverage for public
    tables without final RLS, policies on tables without final RLS, security
    definer functions without fixed search path, missing post-cutoff function
    grant/revoke posture, unsupported named `extensions.http_post` shapes, and
    migration/rollback drift.
  - `.vscode/tasks.json` adds tasks for static Supabase security lint, linked
    DB lint, and linked Advisor verification through `supabase db advisors`.
  - `fg_lint_packages/field_guide_lints/lib/sync_integrity/rules/no_pull_only_sync_table_local_writes.dart`
    recognizes the queue-residue repair owner path.
- Validation:
  - `python tools/supabase/lint_sql_security.py` passed.
  - `python -m json.tool .vscode/tasks.json` passed.
  - `git diff --check` passed with line-ending warnings only.

### 2026-05-10 - Analyzer Gate Cleanup

- Reason: `flutter analyze` and `dart run custom_lint` were acceptance gates
  and initially failed on unrelated PDF analyzer/custom-lint issues.
- Code:
  - Added Logger calls for PDF silent catches.
  - Added missing row-merger test feature defaults.
  - Applied mechanical analyzer cleanups in PDF extraction code/tests.
- Validation:
  - `flutter analyze` passed with no issues.
  - `dart run custom_lint` passed with no issues.
  - Touched PDF tests passed:
    `sequence_gap_continuation_promotion_rule_evaluator_test.dart`,
    `pdf_math_validation_only_guardrail_test.dart`, and the named
    `row_parser_stage_test.dart` row-type case.
  - Broad `row_parser_stage_test.dart` still has an unrelated existing
    behavior failure: `parses OCR single-period quantity thousands values`
    expects `1360.0` and receives `1.36`.

## Verification Commands

- Passed:
  - `flutter test test/features/sync/engine/push_handler_contract_test.dart test/features/sync/application/sync_state_repair_runner_test.dart test/features/sync/engine/pull_handler_test.dart test/core/router/autoroute/app_auto_router_test.dart test/features/settings/presentation/screens/help_support_screen_test.dart --reporter compact`
  - `flutter test test/core/router/route_access_controller_test.dart test/core/router/autoroute/app_auto_router_test.dart test/core/driver/device_state_machine_test.dart test/core/driver/state/ui_region_builder_test.dart test/features/settings/presentation/screens/help_support_screen_test.dart --reporter compact`
  - `flutter test test/features/pdf/extraction/stages/row_merger/sequence_gap_continuation_promotion_rule_evaluator_test.dart test/features/pdf/extraction/contracts/pdf_math_validation_only_guardrail_test.dart --reporter compact`
  - `flutter test test/features/pdf/extraction/stages/row_parser_stage_test.dart --plain-name "Parses complete pay item payload embedded in header row" --reporter compact`
  - `flutter analyze`
  - `dart run custom_lint`
  - `python tools/supabase/lint_sql_security.py`
  - `python tools/supabase/validate_migration_rollbacks.py`
  - `python tools/supabase/check_changed_migration_rollbacks.py supabase/migrations/20260510120000_sync_root_cause_security_hardening.sql`
  - `python tools/supabase/check_changed_migration_rollbacks.py supabase/migrations/20260510160000_security_definer_private_wrappers.sql supabase/migrations/20260510163000_fix_integrity_rpc_out_vars.sql`
  - `python -m json.tool .vscode/tasks.json`
  - `git diff --check`
  - `supabase db push --linked --dry-run`
  - `supabase db push --linked --yes`
  - `supabase db lint --linked --level warning`
  - `supabase db advisors --linked --type security --level warn --output json`
  - `pwsh -NoProfile -File tools/driver/start-driver.ps1 -Platform android -DeviceId RFCNC0Y975L -DriverPort 4948 -Timeout 240 -ForceRebuild -AllowSignInReady`
  - `pwsh -NoProfile -File tools/testing/Invoke-UIFlow.ps1 -Actors "S21:4948:admin:1" -Flow sync-dashboard-route-auth-ui-flow -RunId 20260510-s21-route-guard-auth-rerun -RetentionMode forensic -DeviceClass phone -DeviceModel S21`
  - `pwsh -NoProfile -File tools/testing/Invoke-SyncFlow.ps1 -Actors "S21:4948:admin:1" -ActorCount 1 -Flow quantity-sync-flow -Rounds 1 -RunId 20260510-s21-entry-quantities-bounded -TimeoutSeconds 300 -PollIntervalMilliseconds 250`
- Blocked or unavailable:
  - `deno` is not installed, so Deno-based edge-function linting was not run.
  - Supabase leaked-password protection cannot be enabled on the current plan;
    Management API returned that HaveIBeenPwned leaked-password protection is
    available on Pro plans and up.

## Open Follow-Ups

- Leaked-password protection is explicitly accepted as a release/security
  posture exception for this build because the linked project plan does not
  support it.
- Install `deno` if edge-function linting needs to be part of the local gate.
