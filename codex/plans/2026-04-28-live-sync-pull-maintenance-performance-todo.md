# Live Sync Pull And Maintenance Performance Todo

Date: 2026-04-28
Status: implementation complete; live S21 acceptance evidence pending
Owner: Codex
Related:

- `.codex/plans/2026-04-22-sync-performance-metrics-and-tuning-plan.md`
- `.codex/plans/2026-04-17-sync-soak-ui-rls-implementation-todo.md`
- `.claude/rules/sync/sync-patterns.md`
- `lib/features/sync/engine/pull_handler.dart`
- `lib/features/sync/engine/maintenance_handler.dart`
- `lib/features/sync/application/sync_coordinator.dart`

## Goal

Tune the live Supabase Sync Dashboard full-sync path on S21 so the warm,
standard UI-triggered run meets these budgets without weakening sync
correctness or diagnostics:

- Pull: `<= 2300ms`
- Maintenance: `<= 3000ms`

This spec is live-sync only. Acceptance evidence must come from the live app,
live Supabase, real auth, real SQLite, and the Sync Dashboard UI trigger.

Invalid evidence:

- local Supabase timing
- mocked auth or mocked data
- direct `/driver/sync`
- backend-only soak

## Baseline

Current dirty S21 full sync:

- total: `16573ms`
- push: `8ms`
- pull: `3314ms`
- maintenance: `12281ms`

Current clean repeat S21 full sync:

- total: `5749ms`
- push: `2ms`
- pull: `4801ms`
- maintenance: `18ms`

Both baseline runs were live Supabase, real auth, UI-triggered, and had:

- `errors=0`
- `rlsDenials=0`
- queue `pending=0`
- queue `blocked=0`
- queue `unprocessed=0`

## Acceptance Contract

- [ ] S21 full sync is triggered only through the Sync Dashboard UI.
- [ ] The app is connected to live Supabase.
- [ ] Authentication uses a real Supabase session.
- [ ] SQLite is the real app database, not a mocked store.
- [ ] Pull median across accepted post-change runs is `<= 2300ms`.
- [ ] Maintenance median across accepted post-change runs is `<= 3000ms`.
- [ ] No single dirty maintenance run exceeds `3000ms` unless the artifact
  classifies the reason and records why it is outside the standard warm/full
  budget.
- [ ] Final queue state is:
  - `pending=0`
  - `blocked=0`
  - `unprocessed=0`
- [ ] Sync errors are `0`.
- [ ] RLS denials are `0`.
- [ ] Screenshots and debug-log summary show no UI, runtime, sync, or layout
  defect.

## Required Timing Artifacts

- [x] Add per-table pull timings sorted by duration.
- [x] Add maintenance subphase timings for:
  - change-log pruning
  - conflict pruning
  - scope repair
  - integrity check
  - storage orphan scan
  - local orphan purge
  - storage cleanup queue
  - post-sync hooks
- [x] Record the run class:
  - exhaustive
  - scoped-full
  - dirty-scope
  - repair-triggered
- [x] Record whether the storage orphan scan ran.
- [x] Record which buckets were scanned when storage orphan scan runs.
- [ ] Keep screenshots and a debug-log summary with `errors=0`.

## Maintenance Optimization Todo

- [x] Optimize dirty maintenance first, because the current dirty baseline is
  dominated by maintenance.
- [x] Cadence-gate recursive storage orphan scanning.
- [x] Prefer exact `storage_cleanup_queue` paths over broad bucket scans.
- [x] Scan only buckets touched by recent file-backed sync or delete work.
- [x] Defer broad orphan purge unless one of these conditions requires it:
  - integrity drift
  - stale scope
  - delete activity
- [x] Remove integrity checksum ID fetch unless count or max-timestamp drift is
  detected.
- [x] Preserve cleanup safety: do not delete storage objects without ledger or
  scope evidence that makes the deletion accountable.

## Pull Fan-Out Optimization Todo

- [x] Reduce no-op and warm full-sync adapter round trips.
- [x] Keep only root scope tables active in scoped warm full sync unless the
  device is dirty or the exhaustive cadence is due.
- [x] Add live schema indexes matching pull filters:
  - scope column
  - `updated_at`
  - `id`
  - follow-up audit closed missing `inspector_forms(project_id, updated_at, id)`
    index in `20260428161000_add_inspector_forms_sync_pull_index.sql`
- [x] Evaluate a scoped live RPC that returns per-table changed flags and max
  timestamps before fetching pages.
- [x] Preserve FK-safe apply order if fetch preloading becomes parallel by
  dependency layer.
- [x] Keep `SyncRegistry` ordering load-bearing for apply behavior.

Scoped live RPC evaluation:

- Decision: do not add the RPC as part of this iteration.
- Reason: one summary RPC can reduce no-op page fetches, but it becomes a new
  live server contract that must preserve per-table RLS semantics, scope
  filtering, timestamp precision, and failure diagnostics. The lower-risk first
  pass is to keep the existing scoped pull path, add matching live indexes, and
  expose per-table timings so the next live S21 artifact shows whether RPC
  work is still justified.
- Follow-up trigger: implement the RPC only if post-index live S21 evidence
  still shows warm/no-op pull time dominated by unchanged table probes.

## Test Plan

- [ ] Run S21 only against live Supabase with real auth.
- [ ] Trigger full sync only through the Sync Dashboard UI.
- [ ] After each optimization, capture at least three live runs:
  - clean no-op full sync
  - dirty sync with row-backed change
  - dirty sync with file/delete-backed maintenance work
- [ ] For each run, capture:
  - total duration
  - push duration
  - pull duration
  - maintenance duration
  - per-table pull timing sorted by duration
  - maintenance subphase timing
  - run class
  - storage orphan scan status and scanned buckets
  - final queue state
  - debug-log summary
  - Sync Dashboard screenshot evidence
- [ ] Accept the iteration only if:
  - pull median is `<= 2300ms`
  - maintenance median is `<= 3000ms`
  - no unclassified dirty maintenance run exceeds budget
  - final queue is empty
  - logs show no sync or runtime errors

## Assumptions

- Local Supabase performance numbers are not acceptance evidence.
- Backend/RLS soak is not sync performance evidence.
- Correctness, RLS boundaries, storage cleanup safety, and diagnostics honesty
  take priority over raw speed.
- The target applies to standard warm/full UI sync on live Supabase.
- First-install bulk hydration and deliberate deep-repair runs are outside this
  budget unless separately classified.
