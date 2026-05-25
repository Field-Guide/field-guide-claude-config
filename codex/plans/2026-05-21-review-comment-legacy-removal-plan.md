# Review Comment Legacy Removal And Self-Repair To-Do Spec

## Goal

Remove the legacy Review Comment <-> To-Do bridge and make sync self-repair
blocked review-comment residue so users do not see persistent stuck repair
messages after the review workflow redesign.

This plan supersedes the older intent to preserve migrated To-Do linkage with
`legacy_todo_id`. First-class `review_comments` remain; legacy generated
To-Dos and legacy link columns/queue entries do not need preservation.

## Product Direction

- First-class `review_comments` are the only review-comment system going
  forward.
- Legacy generated review To-Dos require no preservation and should be deleted
  or ignored in favor of first-class review comments.
- Manual, non-review `todo_items` remain in scope and must keep normal
  behavior.
- Blocked sync rows caused by the removed legacy link are repairable local
  residue, not user-action-required sync failures.

## Implementation To-Dos

- [ ] Remove the legacy review-comment To-Do bridge from product behavior.
  - [ ] Delete or deprecate `createTodoFromComment` UI/provider/use-case access.
  - [ ] Remove Review Hub "create review to-do" actions and tests.
  - [ ] Keep normal manual `todo_items` behavior unrelated to review comments.
- [ ] Add sync repair catalog entry `2026-05-21.2`.
  - [ ] Detect blocked `review_comments` insert/update rows whose error
        includes `Review comment legacy todo link is immutable`.
  - [ ] Treat those rows as repairable residue, not user-action-required
        failures.
  - [ ] Soft-delete or purge local generated duplicate comments matching
        `review-review-todo-*`.
  - [ ] Null any local `legacy_todo_id` values on retained first-class comments.
  - [ ] Mark matching blocked `change_log` rows processed after local state is
        normalized.
  - [ ] Purge generated `todo_items` rows matching `review-todo-*` when they
        point at review comments.
- [ ] Remove legacy schema coupling from new/current schema.
  - [ ] Rebuild local `review_comments` without `legacy_todo_id`, its unique
        constraint, and its FK to `todo_items`.
  - [ ] Add a Supabase migration that removes `legacy_todo_id`, drops the unique
        index, and updates integrity triggers so legacy link immutability no
        longer exists.
  - [ ] Remove `todo_items` from `review_comments` FK dependency maps and sync
        ordering where it exists only for `legacy_todo_id`.
- [ ] Harden sync diagnostics.
  - [ ] Keep blocked rows visible only when no repair rule can safely classify
        them.
  - [ ] Ensure the sync dashboard/support report says repaired/clean after this
        residue is normalized.
  - [ ] Do not hide unrelated `review_comments` errors such as target mismatch,
        permissions, or missing parent records.
- [ ] Update the active review workflow plan.
  - [ ] Record that legacy review-comment To-Dos require no preservation and
        must be deleted in favor of the new first-class review system.

## Test Plan

- [ ] Local migration test: upgrading a DB with `legacy_todo_id`, generated
      `review-todo-*` rows, and `review-review-todo-*` duplicates leaves only
      valid first-class `review_comments`.
- [ ] Sync repair test: blocked `review_comments` rows with
      `P0001: Review comment legacy todo link is immutable` are repaired and no
      longer counted as blocked.
- [ ] Negative repair test: unrelated blocked `review_comments` errors remain
      blocked.
- [ ] Schema test: `review_comments` no longer depends on `todo_items`.
- [ ] Provider/widget tests: no Review Hub or review detail UI exposes "create
      review to-do".
- [ ] Live S21 verification on Grand Blanc Test: run real sync after upgrade,
      confirm queue drains, blocked count is `0`, and Sentry/support diagnostics
      no longer report the stale blocked table.

## Acceptance Notes

- Do not use `MOCK_AUTH`.
- Default live verification target is Grand Blanc Test,
  `6936f810-ec15-494e-b4aa-280bf3bf15d3`, project number `12344`, with the
  office technician role unless a later request explicitly changes role scope.
