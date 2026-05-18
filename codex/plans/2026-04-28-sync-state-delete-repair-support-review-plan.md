# Sync State Repair, Delete Follow-Up, Support Cleanup, and Entry Review Privacy

## Summary

Fix stale/confusing sync state by broadening repair coverage and making all
sync-backed user-visible deletes request a full sync. Also remove the
deprecated support-ticket submission path and prevent draft daily entries from
being visible or commentable by other users.

## Key Changes

- Create branch `sync-state` before implementation.
- Replace Help & Support with Sentry-only reporting.
  - Keep `/help-support`, remove the deprecated Submit Ticket UI path.
  - Route sync issue code/title/message/log context through Sentry.
  - Leave existing `support_tickets` schema/adapter compatibility unless a
    later cleanup migration is approved.
- Expand sync repair coverage.
  - Run bounded recovery before quick, full, maintenance, startup/resume, and
    manual dashboard sync.
  - Refresh sync diagnostics and project sync health after every sync
    completion before final UI status settles.
- Add centralized delete follow-up sync.
  - Any sync-backed user-visible delete requests `SyncMode.full`.
  - Cover entries/drafts, photos, forms, documents, todos/review comments, pay
    apps/export artifacts, project setup data, project delete, and Trash
    restore/delete paths when they mutate sync-backed state.
  - Exclude local-only cleanup: caches, temp files, generated export files,
    previews, and “remove from this device.”
  - Coalesce burst deletes and queue one full sync if another sync is already
    running.
- Lock draft entry privacy.
  - RLS: users can select their own drafts; non-creators can select only
    submitted entries.
  - Apply the same visibility boundary to draft-attached child data that
    exposes draft content.
  - Add local repair to purge already-pulled foreign drafts and their
    draft-scoped child rows.
  - Local queries show current-user drafts plus submitted entries.
  - Review/comment actions require `EntryStatus.submitted`.

## Test Plan

- Unit: sync recovery runs before every sync mode and clears stale gate/failed
  repair/blocked residue states.
- Unit: delete follow-up service triggers one full sync for sync-backed
  deletes, coalesces bursts, and ignores local-only deletes.
- Widget: Help & Support exposes Sentry-only reporting and no Submit Ticket
  fallback.
- Integration/widget: representative entry/photo/form/todo/project-setup
  deletes trigger full sync and refresh visible state.
- RLS/local sync: foreign drafts are not pulled or are purged; submitted
  entries remain visible.
- Entry UI: review comment appears only for submitted non-owned entries.

## Assumptions

- “All deletes” means all sync-backed user-visible domain deletes, not
  local-only file/cache cleanup.
- Full sync is the correct delete follow-up because it runs broad pull,
  housekeeping, cursor repair, storage cleanup, and diagnostic refresh.
- Existing support-ticket storage remains for compatibility, but no new
  user-facing submissions use it.
