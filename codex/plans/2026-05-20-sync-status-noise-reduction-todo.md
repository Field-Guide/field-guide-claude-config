# Sync Status Noise Reduction Todo

Created: 2026-05-20

Status: Implemented and S21 Grand Blanc verified on 2026-05-20. Manual device
evidence is under
`tools/testing/test-results/2026-05-19/s21-sync-status-noise-manual/`.

## Summary

Create a quieter, background-first sync experience by separating true
user-action-required failures from normal background states like syncing,
queued work, offline retry, overlap, and partial progress. Red status should
mean "sync needs attention," not "sync has not finished yet."

## 1. Normalize Sync Result Semantics

- [ ] Change "another sync is already in progress" from an error result to a
  non-error skipped/queued result.
- [ ] Treat auth-context-not-ready during startup/resume as a deferred sync
  state unless the user is blocked from saving.
- [ ] Add an explicit non-failure state for "sync still has pending work"
  instead of converting remaining pending uploads into `downloadError`.
- [ ] Preserve hard failures for RLS, permission, schema, missing remote proof,
  and unrecoverable database exceptions.
- [ ] Update sync result tests so overlap, deferred auth, and partial queue
  drain do not increment consecutive failure counts.

## 2. Fix Offline And Retry Classification

- [ ] Classify DNS/connectivity probe failures as offline/retryable, not generic
  permanent sync failure.
- [ ] Remove the final-settle behavior that forces `isOnline: true` after a
  failed run.
- [ ] Ensure offline state shows the offline banner/status and schedules
  background retry without red failure UI.
- [ ] Add tests for DNS unreachable, timeout, and offline-to-online retry
  recovery.

## 3. Rework Pending, Failed, And Blocked Queue States

- [ ] Keep fresh pending rows as neutral/amber "sync pending," not red.
- [ ] Stop transient network/rate-limit failures from exhausting per-record
  retry count into repair-required state.
- [ ] Reserve blocked/repair-required state for permanent row-level failures or
  verified unrecoverable records.
- [ ] Ensure generic permanent push errors either block immediately with a clear
  reason or retry only when truly retryable.
- [ ] Deduplicate blocked counts by logical record where user-facing counts are
  shown.
- [ ] Add tests for healthy large backlog, transient retry, permanent row
  failure, and blocked-count deduping.

## 4. Centralize UI Sync Severity

- [ ] Introduce one sync-status projection model used by app bar, dashboard,
  settings, banners, and status text.
- [ ] Define severity order as: syncing > offline/retrying > pending > conflict
  > repair-required > persistent failure > synced/idle, with red only for
  repair-required or confirmed persistent failure.
- [ ] Make a single stored `uploadError`/`downloadError` insufficient to turn
  the main icon red.
- [ ] Keep first-time or transient failures quiet/amber unless repeated and
  still unresolved.
- [ ] Update `SyncStatusIcon`, dashboard summary, settings sync section, and
  shell banners to consume the centralized projection.
- [ ] Remove duplicate getter/status logic between `SyncProvider` and sync
  provider extension files.

## 5. Fix Stale State Refresh Paths

- [ ] Route all sync-surface refreshes through one serialized/generation-guarded
  path in `SyncProvider`.
- [ ] Refresh sync surface state after recovery/repair even when no full sync
  follows.
- [ ] Refresh dashboard diagnostics when provider queue counts change, or make
  dashboard read provider-owned counts for summary state.
- [ ] Refresh project sync health after partial sync/recovery where local queue
  state may have changed.
- [ ] Clear or downgrade stale `lastError` when a newer run is syncing, pending,
  offline retrying, or no-freshness but non-error.
- [ ] Add tests for stale blocked count clearing, repair success clearing red
  UI, and no-freshness preserving neutral state.

## 6. Clean Up Project Card Red Status

- [ ] Treat project-card `isLocalOnly` as catalog freshness/availability, not
  transport sync failure.
- [ ] Only render project-card red warning when local-only status is based on a
  fresh/proven catalog.
- [ ] Show stale/unknown catalog state as neutral or amber.
- [ ] Refresh or invalidate project catalog state after sync recovery and
  catalog fetch failures.
- [ ] Add tests for stale catalog, fresh catalog local-only, and normal Grand
  Blanc project display.

## 7. Saved Diagnostics And User Messaging

- [ ] Replace generic "Sync failed" messaging with specific labels: "Sync
  pending," "Offline, retrying," "Sync already running," "Items need repair,"
  or "Sync needs attention."
- [ ] Keep detailed technical errors in the sync dashboard/issue report, not the
  primary app chrome.
- [ ] Ensure repair-required messages explain that other sync can still run.
- [ ] Update existing widget/provider tests that currently expect one error to
  show red.

## Test Plan

- [ ] Run focused sync engine tests for overlap, offline, pending backlog,
  retryable push failures, permanent row failures, and freshness proof.
- [ ] Run sync provider/widget tests for severity projection, red icon
  threshold, banner behavior, stale count clearing, and dashboard summary.
- [ ] Run project card/provider tests for stale catalog versus confirmed
  local-only.
- [ ] Run sync lifecycle/recovery tests proving repair and recovery refresh UI
  state without requiring a successful full sync.
- [ ] Verify on S21 with real auth against Grand Blanc Test only: create/edit
  IDR, add form/photo/file, trigger sync, interrupt/connectivity retry where
  feasible, reopen app, confirm red appears only for real repair-required or
  persistent failure states.
- [ ] Do not test under Saugatuck or Paw Paw.

## Assumptions

- Red UI is reserved for user-action-required repair or confirmed persistent
  failure.
- Pending uploads, active sync, background retry, offline retry, and sync
  overlap are normal background states.
- No schema migration is required for the first pass unless implementation
  proves retry classification cannot be corrected without adding queue metadata.
- Grand Blanc Test remains the only live project used for verification.
