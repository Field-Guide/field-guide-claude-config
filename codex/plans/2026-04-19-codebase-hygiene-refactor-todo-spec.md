# Codebase Hygiene Refactor Todo Spec

Date: 2026-04-22
Branch audited: `gocr-integration`
CodeMunch repo: `local/Field_Guide_App-37debbe5`
Indexed snapshot: 2,009 files / 16,592 symbols / avg complexity 3.33
Dependency cycles: 0
Status: active controlling whole-repo hygiene spec
Replaces: the stale 2026-04-19 version

## Purpose

This is the current-tree structural hygiene spec for `gocr-integration` as of
April 22, 2026. It replaces the earlier April 19 draft that still centered
stale GoRouter debt, pre-split logger/database work, and the old shared
testing-key shape.

This spec is the structural companion to the active runtime, sync, and
driver/device hardening work. It is whole-repo in scope, but execution order
is runtime-first:

1. architecture guardrails
2. router/auth and runtime boundary cleanup
3. data/domain purity cleanup
4. live production hotspot refactors
5. whole-repo secondary test/harness/diagnostic cleanup

Append implementation notes to:
`.codex/checkpoints/2026-04-19-codebase-hygiene-refactor-progress.md`

## Current Baseline

### Verified direction

- `AppAutoRouter`, `route_access_*`, `app_route_catalog.dart`, and
  `lib/core/router/autoroute/pages/*` are the current routing surface.
  `app_router.dart` and GoRouter decomposition debt are stale and must not
  drive this plan.
- `Logger` and `DatabaseService` are no longer size-based god files. Follow-up
  work there is limited to boundary ownership and narrow lint cleanup, not a
  second large decomposition.
- `RolePolicy` already exists. The open auth work is migrating router/UI/data
  consumers off direct `AuthProvider` reads where a stable policy or auth
  snapshot seam should be used instead.
- Shared testing keys are already split into feature exports. The remaining
  debt is the large `TestingKeys` facade plus ownership of shared/generated key
  catalogs.
- Generated router files and generated testing-key outputs are excluded from
  direct file-size and hotspot budgets unless a generator-input or
  generator-ownership change is the explicit task.

### Current production hotspots

The runtime hotspot list to use going forward is:

1. `RowMerger.merge`
2. `RowParserDataRowParser.parse`
3. `DailyEntry.copyWith`
4. `ItemDeduplicationWorkflow.deduplicate`
5. `Project.copyWith`
6. `UserProfile.copyWith`
7. `PdfImportWorkflow.importFromPdf`
8. `PushHandler.push`
9. `PushExecutionRouter`

Whole-repo test, integration, soak, and diagnostic hotspots live in a separate
secondary queue and must not be mixed into runtime architectural priorities.

## Scope

### In scope

- Architecture lints and allowlists for core/shared, data, and domain
  boundaries.
- Router/auth boundary cleanup around `RouteAccessSnapshot`,
  `RouteAccessController`, `RolePolicy`, `app_route_catalog.dart`, and
  AutoRoute page adapters.
- Data/domain boundary cleanup:
  `AuthProviderSessionService` replacement,
  `form_seed_service.dart` registration move,
  sync/auth/settings domain purity cleanup.
- Runtime hotspot refactors for PDF extraction, push execution, model
  boilerplate, and narrow logger follow-up.
- Whole-repo secondary cleanup only after runtime seams and lint guardrails are
  stable.

### Out of scope

- Behavioral changes to auth, routing, sync, PDF extraction, or push semantics.
- Driver-owned runtime changes beyond allowlist coordination.
- Manual decomposition of generated router outputs or generated testing-key
  outputs.
- Reopening logger/database transport splits that are already complete.

## Active Constraints

These are active guardrails now, not future ideas:

- `max_file_length`, `max_*_callable_length`, and related production/test
  budgets remain in force.
- Generated router/testing-key outputs are excluded from those budgets by
  default. Fix the source catalogs or generator inputs instead of hand-editing
  generated code.
- `flutter analyze` and `dart run custom_lint` are required on every slice.
- Every hotspot refactor must start with characterization coverage of the
  current behavior.
- No test-only hooks, `MOCK_AUTH`, or fake runtime seams.

## Lane 0: Architecture Guardrails

Land guardrails before deeper runtime refactors.

### Required lints

- `core_must_not_import_feature_presentation`
  - blocks `lib/core/**` and `lib/shared/**` from importing
    `features/*/presentation/**`
- `data_must_not_import_presentation`
  - blocks `features/*/data/**` from importing
    `features/*/presentation/**`
- `domain_must_be_pure_dart`
  - blocks Flutter/plugin imports from `features/*/domain/**`

### Explicit allowlist model

Permanent composition-root exceptions:

- `lib/core/di/*`
- startup/bootstrap registration seams that must wire feature providers or
  provider-owned runtime flows
- app/root shell seams such as `lib/core/app_widget.dart`

Temporary debt exceptions to remove:

- `route_access_*` while the snapshot/controller split is incomplete
- shell adapter seams such as `scaffold_with_nav_bar.dart` if they still read
  presentation providers directly
- any driver-owned core file until the driver decomposition spec removes the
  presentation dependency

Legitimate route/page adapter seams:

- `lib/core/navigation/app_route_catalog.dart`
- `lib/core/router/autoroute/pages/*`
- `lib/core/router/autoroute/primary_shell_auto_route_page.dart`

These route/page adapter seams may import presentation route/page definitions,
but they must not read presentation provider state directly unless the seam is
explicitly documented as a shell adapter debt item.

## Lane 1: Router/Auth Boundary Split

### Target state

- `RouteAccessSnapshot` is the router-facing access contract.
- `RouteAccessController` listens to stable snapshot-oriented seams, not raw
  provider classes.
- `RolePolicy` remains the permission/capability read seam for widgets and
  routing decisions.

### Required work

- Refactor `route_access_snapshot.dart` to capture from stable auth/config/
  consent snapshot interfaces instead of reading provider classes directly.
- Refactor `route_access_controller.dart` to listen to snapshot-oriented seams
  rather than `AuthProvider`, `AppConfigProvider`, and `ConsentProvider`
  concrete types.
- Remove direct `AuthProvider` reads from
  `lib/core/router/autoroute/pages/pdf_auto_route_pages.dart`; use route-access
  capability seams or rely on guard ownership instead of page-level provider
  reads.
- Remove direct provider coupling from `scaffold_with_nav_bar.dart` where
  possible. If a shell adapter still needs feature UI widgets, isolate that
  adapter and document it.
- Treat `app_route_catalog.dart` and `autoroute/pages/*` as the current routing
  ownership surface. Delete stale spec language that still assumes
  `form_routes.dart`-style decomposition is the controlling path.

### Required verification

- `test/core/router/route_access_snapshot_test.dart`
- `test/core/router/route_access_controller_test.dart`
- `test/core/router/route_access_policy_test.dart`
- `test/core/router/autoroute/app_auto_router_test.dart`
- shell/navigation widget tests proving dashboard/projects fallback and tab
  gating behavior

## Lane 2: Data and Domain Boundary Cleanup

### Data-layer boundary fixes

- Replace `AuthProviderSessionService` with a session adapter backed by
  `AuthAccessSnapshot` or `AuthSyncContext` so data services no longer import
  presentation providers.
- Move form screen registration out of `form_seed_service.dart` and into a
  UI/DI registration seam. Keep builtin form seeding itself in data.

### Domain purity fixes

- Remove `flutter/foundation.dart` imports from sync domain models/types/status/
  error/event/metrics/diagnostics. Use `package:meta/meta.dart` and pure-Dart
  collection helpers instead.
- Replace auth secure-storage plugin imports in domain use cases with an
  injected gateway interface.
- Remove Flutter platform imports from
  `submit_support_ticket_use_case.dart`; pass platform data in from a
  presentation or DI seam.
- No behavior changes are allowed in these moves.

### Required verification

- narrow unit tests around the new auth/session gateway seams
- existing auth-provider and support-provider tests
- targeted sync-domain model tests where equality or serialization helpers
  change

## Lane 3: Live Production Hotspots

### PDF extraction

- Decompose `RowMerger.merge` into row-type handlers plus a continuation
  accumulator. Leave `row_merger_rules.dart` intact.
- Decompose `RowParserDataRowParser.parse` into field extraction, artifact
  filtering, sequence rescue, and assembly stages.
- Keep the formal stage-interface lane centered on
  `extraction_pipeline_facade.dart` and `stage_registry.dart`, not the old
  `extraction_pipeline.dart` ownership model.
- Externalize truly data-driven OCR dictionary/rule data, starting with
  `construction_description_ocr_word_fixes.dart`, then audit
  `description_artifact_cleaner.dart`.

### Sync push

- Reduce `PushHandler.push` to orchestration only.
- Split `PushExecutionRouter` into smaller execution helpers covering delete,
  upsert, bulk-upsert preparation, and scope/hint emission.
- Preserve existing push-handler public contracts and semantics.

### Model boilerplate

- Migrate the highest manual `copyWith` hotspots first:
  `DailyEntry`, `Project`, `UserProfile`, `TodoItem`, `PipelineConfig`, then
  the next remaining models by score.
- Keep the migration behavior-preserving and characterization-test-backed.

### Logger follow-up

- Do not reopen the completed transport split.
- Narrow the remaining file-wide `no_silent_catch` suppressions to local
  ignores where feasible.
- Only reduce logger API blast radius if a compatibility-preserving codemod is
  genuinely narrow.

## Lane 4: Whole-Repo Secondary Queue

This queue starts only after runtime seams and lint guardrails are stable.

- Oversized integration diagnostics
- soak and harness helpers
- route/router tests that still mirror stale architecture
- oversized shared/generated testing-key facade ownership

Rules:

- Preserve current artifact contracts and bug-discovery value.
- Do not hand-decompose generated router or generated testing-key outputs.
- If generated outputs remain a problem, fix the source catalogs or generator
  ownership seams instead.

## Interfaces and Types

These are the intended steady-state seams:

- `RouteAccessSnapshot`
  - router-facing access contract
  - must not require direct presentation-provider imports
- `RolePolicy`
  - permission and capability read seam for UI and routing decisions
- `AuthAccessSnapshot` / `AuthSyncContext` / domain `SessionService`
  - preferred auth/session read seams for runtime consumers
- PDF extraction stage contract
  - converges on explicit stage ownership around `stage_registry.dart` and
    `extraction_pipeline_facade.dart`
- Push execution collaborators
  - smaller helpers under the existing `PushHandler` public entrypoint

## Verification Plan

- Land characterization coverage before each hotspot refactor.
- Keep `flutter analyze` and `dart run custom_lint` green on each slice.
- Router/auth work must preserve and update:
  - `test/core/router/route_access_policy_test.dart`
  - `test/core/router/route_access_snapshot_test.dart`
  - `test/core/router/route_access_controller_test.dart`
  - `test/core/router/autoroute/app_auto_router_test.dart`
  - shell/navigation widget tests
- PDF extraction work requires fixture-backed regression tests or goldens before
  splitting methods.
- Push refactors keep existing push-handler contract tests unchanged and extend
  them only around extracted helpers.
- Domain/data boundary cleanup adds narrow unit coverage around gateway and
  snapshot seams.
- Secondary whole-repo cleanup must preserve current test/harness result
  contracts.

## Sequencing

1. Ship architecture lints and allowlists.
2. Finish the router/auth boundary split.
3. Clean remaining data/domain purity violations.
4. Refactor live production hotspots.
5. Only then start the whole-repo secondary queue.

Runtime production code ships before test/harness cleanup even though this spec
is whole-repo in scope.

## Assumptions and Defaults

- No functionality changes are allowed.
- Driver-owned files remain out of scope except where they must be called out in
  allowlists or ownership notes.
- Generated files are excluded from file-length debt unless a generator-input or
  ownership change is the explicit target.
- `DatabaseService` is not a priority refactor target in this pass unless a new
  audit shows fresh structural regression.

## Cross-links

- `.codex/plans/2026-04-20-unified-routing-state-auth-live-testing-reset-plan.md`
- `.codex/plans/2026-04-20-unified-routing-state-sync-soak-driver-spec.md`
- `.codex/plans/2026-04-20-autoroute-routing-provider-refactor-todo-spec.md`
- `.codex/plans/2026-04-19-four-role-sync-hardening-scale-up-spec.md`
