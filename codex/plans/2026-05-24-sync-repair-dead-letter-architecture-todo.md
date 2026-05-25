# Sync Repair Dead-Letter Architecture To-Do

## Summary

- Fix GitHub `#337` / Sentry `FLUTTER-1R`: blocked `daily_entries update` caused by `Permanent (P0001): Reviewers cannot manually reset items to completed`.
- Add architecture guardrails so permanent sync failures cannot regress into user-visible blocked rows without policy-owned repair/dead-letter handling.
- Verify on S21 with real auth against Grand Blanc Test project `6936f810-ec15-494e-b4aa-280bf3bf15d3`.

## Implementation To-Dos

- [x] Fix the upstream review workflow bug.
  - [x] Audit reviewer and correction flows that write `review_status`.
  - [x] Ensure reviewer paths only write `approved` or `needs_action`.
  - [x] Ensure only the target inspector/creator can write `needs_action -> project_completed`.
  - [x] Remove reviewer-owned `completed_by_user_id` writes for `project_completed`.

- [x] Repair existing `#337` residue.
  - [x] Add `repair_sync_state_v2026_05_24_daily_entry_review_reset_residue`.
  - [x] Match only blocked `daily_entries` rows with `%Reviewers cannot manually reset items to completed%`.
  - [x] Reconcile local row from remote authoritative state or clear the invalid local review reset.
  - [x] Mark the stale queue row resolved instead of resetting retry count.

- [x] Add dead-letter/permanent rejection architecture.
  - [x] Add `sync_repair_events` or `sync_failures` local table.
  - [x] Add failure classes: `transient_retry`, `permanent_domain_rejection`, `rls_or_permission_rejection`, `developer_dead_letter`, `scope_rehydrate_required`.
  - [x] Route permanent domain rejections through a policy owner that writes repair evidence and resolves/acknowledges the `change_log` row.
  - [x] Keep schema/invariant failures blocked and visible.

- [x] Lock the architecture with custom lints.
  - [x] Add sync-integrity lint: `sync_permanent_rejection_requires_repair_event`.
  - [x] Add sync-integrity lint: `no_direct_change_log_dead_letter_resolution_outside_policy_owner`.
  - [x] Add architecture lint: `no_direct_review_status_project_completed_outside_review_owner`.
  - [x] Register rules in `fg_lint_packages/field_guide_lints/lib/sync_integrity/sync_integrity_rules.dart` or architecture rules as appropriate.
  - [x] Add focused lint tests under `fg_lint_packages/field_guide_lints/test/sync_integrity/` and `test/architecture/`.

## Test And Verification To-Dos

- [x] Run focused unit tests for review status transitions.
- [x] Run focused sync repair tests for the new daily-entry review-reset residue repair.
- [x] Run `dart test fg_lint_packages/field_guide_lints/test/...` for new lint rules.
- [x] Run `dart run custom_lint`.
- [x] Run `flutter analyze`.
- [x] S21 live verification:
  - [x] Use real office-technician session, no `MOCK_AUTH`.
  - [x] Reproduce or seed equivalent `#337` review-state residue.
  - [x] Run UI-triggered Sync Dashboard repair/sync.
  - [x] Confirm `pending=0`, `blocked=0`, no runtime/layout/sync defects.
  - [x] Capture screenshots, sync state, and debug logs.

## GitHub/Sentry Closeout To-Dos

- [x] Update GitHub `#337` with root cause, fix commit, S21 evidence path, and exact verification summary.
- [x] Query Sentry `FLUTTER-1R` after verification and confirm no fresh matching event.
- [x] Close GitHub `#337` only after the fix is merged or otherwise present on the tested build and S21 evidence is attached.
- [x] Resolve or annotate Sentry `FLUTTER-1R` according to the repo's Sentry issue policy.
- [x] Do not close older related Sentry/GitHub issues unless each has matching evidence.

## Assumptions

- Current custom sync engine remains in place for this release.
- PowerSync-style patterns are adopted as hardening principles: permanent validation failures must not deadlock upload queues, and repair handling must be explicit and policy-owned.
- Remote state is authoritative for the already-rejected reviewer reset unless diagnostics prove the inspector authored the correction.
