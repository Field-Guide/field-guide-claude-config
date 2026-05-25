# Local Trash And Non-Project Workspace Saved Work TODO Spec

## Summary

Make Trash local-only in SQLite and stop syncing Trash state to Supabase. Add clear Non-Project Workspace dashboard cards for saved daily entries and saved forms so users can reopen, review, and export them later with the same workflows used in project work.

## Phase 1: Save Spec And Baseline

- [ ] Save this spec to `.codex/plans/2026-05-20-local-trash-non-project-workspace-hub-todo.md`.
- [ ] Confirm current branch and clean/dirty worktree before edits.
- [ ] Record current Trash behavior:
  - [ ] Which tables write `deleted_at/deleted_by`.
  - [ ] Which delete paths enqueue sync.
  - [ ] Which Trash UI queries read synced soft-deleted rows.
- [ ] Record current Non-Project Workspace behavior:
  - [ ] Dashboard cards available.
  - [ ] Existing daily entry paths.
  - [ ] Existing Form Gallery saved mode paths.

## Phase 2: Local-Only Trash Data Model

- [ ] Add local SQLite table `local_trash_items`.
- [ ] Include:
  - [ ] `id`
  - [ ] `user_id`
  - [ ] `table_name`
  - [ ] `record_id`
  - [ ] `project_id`
  - [ ] `deleted_at`
  - [ ] `expires_at`
  - [ ] `display_name`
  - [ ] `payload_json`
  - [ ] Optional cascade/group metadata.
- [ ] Keep `local_trash_items` out of sync adapters.
- [ ] Keep `local_trash_items` out of Supabase migrations.
- [ ] Add migration tests for fresh install and upgrade.

## Phase 3: Trash Behavior Change

- [ ] Change "move to Trash" to copy active row payload into `local_trash_items`.
- [ ] Remove the active local row after trash snapshot is created.
- [ ] Sync the delete as a real remote hard delete.
- [ ] Stop pushing Trash `deleted_at/deleted_by` tombstones to Supabase.
- [ ] Change Trash screen/counts to read only from `local_trash_items`.
- [ ] Keep Trash user-scoped by current signed-in user.
- [ ] Keep Trash device-local; do not pull Trash from Supabase.
- [ ] Preserve local restore.
- [ ] On restore, recreate active local rows from `payload_json`.
- [ ] Sync restored rows back to Supabase as active data.
- [ ] Preserve permanent purge from local Trash.

## Phase 4: Delete/Sync Infrastructure

- [ ] Add explicit user-trash hard-delete sync path.
- [ ] Ensure project eviction/scope revocation remains separate from user Trash.
- [ ] Remove Trash follow-up sync assumptions from soft-delete service paths.
- [ ] Audit delete graph registry for tables that should no longer be Trash-backed by synced soft deletes.
- [ ] Keep legacy `deleted_at/deleted_by` columns only for compatibility until a separate removal plan.
- [ ] Add custom lint guardrails:
  - [ ] No Trash UI/repository reads from synced `deleted_at IS NOT NULL` as user Trash.
  - [ ] No Trash delete path pushes `deleted_at/deleted_by` to Supabase.
  - [ ] `local_trash_items` must not be registered as a sync table.

## Phase 5: Non-Project Workspace Saved Work Cards

- [ ] Add dashboard card for saved daily entries.
- [ ] Add dashboard card for saved forms.
- [ ] Keep existing Daily Entry create card.
- [ ] Keep existing Forms create card.
- [ ] Saved daily entries card opens a non-project scoped entries list.
- [ ] Saved forms card opens Form Gallery in saved mode for the non-project workspace project id.
- [ ] Include drafts, submitted entries, open forms, submitted forms, and exported forms.
- [ ] Reuse existing view/export workflows.
- [ ] Do not create a separate Toolbox hub for v1.
- [ ] Do not merge export history into this hub for v1.

## Phase 6: Tests

- [ ] Test local Trash migration.
- [ ] Test move-to-Trash writes `local_trash_items`.
- [ ] Test move-to-Trash removes active local row.
- [ ] Test move-to-Trash syncs remote hard delete, not soft delete.
- [ ] Test Trash screen only shows current user's local Trash.
- [ ] Test restore recreates active local row.
- [ ] Test restore syncs active row back to Supabase.
- [ ] Test permanent purge removes only local Trash payload.
- [ ] Test Non-Project Workspace saved daily entries card navigation.
- [ ] Test Non-Project Workspace saved forms card navigation.
- [ ] Test saved cards use the correct synthetic non-project workspace id.
- [ ] Test entry/form export workflows still work from saved non-project work.

## Phase 7: Verification

- [ ] Run `dart analyze`.
- [ ] Run `dart run custom_lint`.
- [ ] Run focused Trash tests.
- [ ] Run focused Non-Project Workspace dashboard tests.
- [ ] Run focused sync hard-delete tests.
- [ ] Verify on ASH-21:
  - [ ] Create non-project daily entry.
  - [ ] Reopen it from saved daily entries card.
  - [ ] Export it.
  - [ ] Create non-project form.
  - [ ] Reopen it from saved forms card.
  - [ ] Export it.
  - [ ] Move synced item to Trash.
  - [ ] Confirm Supabase does not store Trash tombstone.
  - [ ] Confirm local Trash shows the item.
  - [ ] Restore item and confirm it syncs as active data.
  - [ ] Confirm sync queue drains cleanly.

## Assumptions

- "Trash should not be stored in our database" means Supabase; SQLite remains the local Trash store.
- Moving synced data to Trash should delete it remotely, not keep a hidden live row in Supabase.
- Restoring from Trash recreates and syncs the active row.
- V1 non-project saved work hub is dashboard-card based, not a new Toolbox route.
