# Review Hub And Stale Dashboard Fix To-Do Spec

## Summary

Build a Toolbox Review Hub for submitted daily entries, submitted/exported
forms, review comments, approvals, and optional to-dos. Remove stale cross-user
dashboard behavior so personal dashboard cards only show the current user's own
draft/submitted work, while cross-user submitted work moves into the Review Hub.

## Current Branch Status - 2026-05-20

- [x] Created branch `feature/review-hub-dashboard-scope`.
- [x] Committed baseline implementation as logical commits through
  `feat(review): add toolbox review hub`.
- [x] Added branch audit task list before the audit-fix implementation pass.
- [x] Added custom lint guardrails for review infrastructure:
  - [x] Block new legacy review-comment creation through `todo_items`.
  - [x] Block direct app-layer mutation of review status columns outside the
        review persistence owner.
- [x] Fixed audit findings already selected for this pass:
  - [x] Provider-level reviewer authorization guard for approve/comment/change
        requests.
  - [x] Atomic request-changes write for comment creation plus target review
        status update.
  - [x] Project-scoped review target validation before creating comments.
  - [x] Existing entry review screens now create first-class review comments
        instead of legacy review-comment to-dos.
  - [x] Dashboard project load identity and stale async completion protection.
  - [x] Todo provider stale async completion protection after `clear()`.
  - [x] Review Hub load key includes `canReviewInspectorWork`.
  - [x] Review Hub provider ignores stale async loads and cancels in-flight loads
        before mutations.
  - [x] Review Hub provider missing project/user guards now stay inside
        `SafeAction` failure handling.
  - [x] Review comment form navigation preserves `formType`.
  - [x] Review Hub route/driver/catalog test drift fixed.
  - [x] Sync registry/order tests updated for `review_comments`.
  - [x] Local review hub composite indexes added.
  - [x] Legacy review-comment todo migration made project-scoped and idempotent.
  - [x] Supabase hardening migration added for review status/comment integrity.
  - [x] Supabase review-comment insert policy now requires reviewer authority,
        matching the provider-side guard.
  - [x] Local v68 migration made tolerant of older daily/form schemas missing
        soft-delete columns before Review Hub indexes are created.
- [x] Remaining audit-fix pass before ASH-21 closeout:
  - [x] Incorporate any new findings from the parallel read-only audit agents.
  - [x] Fix audit finding: first-class `review_comments` no longer feed the
        dashboard review-comment attention path that still reads legacy
        `todo_items`.
  - [x] Fix audit finding: local Review Hub hardening was folded into v68
        schema code, so already-v68 devices need a new v69 migration.
  - [x] Fix audit finding: async generation guards prevent stale data
        assignment, but stale `SafeAction` loading/error state and dashboard
        quantity totals can still publish after user/project switches.
  - [x] Fix audit finding: inspector-mode Review Hub shows reviewer-only
        comment controls that now fail via permission guard.
  - [x] Fix audit finding: custom review lint rules need broader bypass
        coverage for raw SQL status writes and direct legacy review-comment
        to-do construction.
  - [x] Fix audit finding: remote daily-entry review-comment insert policy must
        require submitted entries, not just selectable entry content.
  - [x] Fix audit finding: remote hardening migration needs repair/preflight for
        existing cross-project review-comment targets from the first rollout.
  - [x] Fix audit finding: remote unique `legacy_todo_id` index can fail if
        duplicate legacy links already exist, so dedupe before index creation.
  - [x] Fix audit finding: upgraded local SQLite databases need retrofitted
        review-comment target consistency and legacy uniqueness, not only fresh
        schema constraints.
  - [x] Fix audit finding: `SyncEngineTables.triggeredTables` order is stale
        relative to `SyncRegistry.dependencyOrder` for `review_comments` and
        `todo_items`.
  - [x] Fix audit finding: remote `review_comments` update policy lets assigned
        inspectors rewrite comment/assignment fields instead of only resolving.
  - [x] Fix audit finding: local and remote review target eligibility must be
        enforced below UI/provider layers for submitted daily entries and
        submitted/exported forms.
  - [x] Fix audit finding: Review Hub mutation reloads need the same
        generation/project/user/mode validation as normal loads.
  - [x] Fix audit finding: stale entry review button text still says
        `Send to To-Do` even though it creates a review comment.
  - [x] Push Supabase schema updates so ASH-21 is no longer blocked by the
        missing remote `review_comments` table.
  - [x] Re-run ASH-21 Review Hub smoke on Grand Blanc Test project
        `6936f810-ec15-494e-b4aa-280bf3bf15d3` / `12344`.
        Evidence:
        `tools/testing/test-results/2026-05-20/20260520-ash21-review-hub-smoke-clean/summary.json`.
  - [x] Commit this audit-fix pass as logical commits:
        `fix(database): harden review hub persistence`,
        `fix(review): enforce review hub ownership`, and
        `chore(lints): lock review hub boundaries`.
  - [x] Decide whether to fix or backlog the four pre-existing custom-lint
        warnings: fixed `primary_shell_banner_stack.dart` unused parameter;
        backlog the three remaining import-count warnings in
        `app_providers.dart`, `screen_registry.dart`, and
        `project_list_screen_test.dart`.

## Phase 1: Fix Stale Dashboard/User Scope

- [x] Make dashboard project load identity include `projectId + userId + role`.
- [x] Clear or reload project-scoped providers when auth user/role changes.
- [x] Update Today's Entry dashboard card to consider only the current user's own entries.
- [x] Keep foreign submitted entries out of personal dashboard CTAs.
- [x] Keep submitted entries available for review surfaces.
- [x] Ensure draft counts only reflect current-user visible drafts after user switches.

## Phase 2: Add Review Data Model

- [x] Add local SQLite schema for `review_comments`.
- [x] Add Supabase migration for `review_comments`.
- [x] Add review status columns to `daily_entries`:
  - `review_status`
  - `reviewed_by_user_id`
  - `reviewed_at`
- [x] Add review status columns to `form_responses`:
  - `review_status`
  - `reviewed_by_user_id`
  - `reviewed_at`
- [x] Support `review_status` values:
  - `unreviewed`
  - `approved`
  - `changes_requested`
- [x] Add `review_comments` sync adapter and registry wiring.
- [x] Add RLS so:
  - drafts/open forms stay creator-private
  - submitted entries are visible to reviewers
  - submitted/exported forms are visible to reviewers
  - inspectors see comments assigned to their work
- [x] Migrate existing `todo_items.source_type = review_comment` rows into `review_comments`.
- [x] Preserve migrated to-do linkage with `legacy_todo_id`.

## Phase 3: Review Domain/API Layer

- [x] Add review comment model.
- [x] Add review repository and local datasource.
- [x] Add review provider/controller for hub state.
- [x] Add queries for reviewer hub:
  - submitted entries
  - submitted/exported forms
  - open comments
  - action-required items
  - approved items
- [x] Add queries for inspector hub:
  - assigned/open comments
  - submitted own work
  - approved own work
  - resolved comments
- [x] Add actions:
  - create comment
  - resolve comment
  - approve entry/form
  - mark changes requested
  - create optional to-do from review item

## Phase 4: Add Toolbox Review Hub

- [x] Add `AppRouteId.reviewHub` at `/toolbox/review`.
- [x] Add route descriptor in toolbox route catalog.
- [x] Add AutoRoute page and route wiring.
- [x] Add Review Hub card to Toolbox.
- [x] Build reviewer hub view for approved non-inspectors:
  - admin
  - engineer
  - office technician
- [x] Build inspector hub view for inspectors.
- [x] Use tabs/filters:
  - All
  - Entries
  - Forms
  - Action Required
  - Approved
  - Resolved
- [x] Support item-level comments.
- [x] Support optional section key/label for comments.
- [x] Add separate "Create To-Do" action from review comments.
- [x] Show approval status to inspectors and reviewers.
- [x] Keep approval informational only; do not lock content.

## Phase 5: Integrate Existing Screens

- [x] Keep existing draft review flow as inspector pre-submit review.
- [x] Route submitted daily entry review from hub to read-only entry view.
- [x] Route submitted/exported forms from hub to read-only form view.
- [x] Prevent reviewers from editing inspector submitted content through hub routes.
- [x] Keep To-Do's available as optional task tracking.
- [x] Stop using dashboard review-comment card as the primary review entry point once hub exists.
- [x] Preserve existing To-Do review-comment display until migration is proven.

## Phase 6: Tests

- [x] Add dashboard test: foreign submitted entry does not show as current user's Today's Entry.
- [x] Add dashboard test: same-project user switch clears stale drafts/cards.
- [x] Add provider test: current-user entries are separated from project reviewable entries.
- [x] Add migration test for `review_comments`.
- [x] Add migration test for review status columns.
- [x] Add migration test importing legacy review-comment to-dos.
- [ ] Add RLS/sync tests for draft privacy.
- [x] Add RLS/sync tests for submitted reviewer visibility.
- [ ] Add Review Hub widget tests for reviewer role view.
- [ ] Add Review Hub widget tests for inspector role view.
- [x] Add tests for comment creation, approval, changes requested, resolve, and optional to-do creation.

## Phase 7: Live Verification

- [x] Verify with office technician on Grand Blanc Test project:
  - project id `6936f810-ec15-494e-b4aa-280bf3bf15d3`
  - project number `12344`
- [ ] Submit daily entry as inspector.
- [ ] Confirm office/admin/engineer can see submitted entry in Review Hub.
  - [x] Current evidence covers office technician on ASH-21.
  - [ ] Admin/engineer remain useful follow-up role coverage.
- [ ] Confirm reviewer can comment, approve, and create optional to-do.
- [ ] Confirm inspector sees comment/approval in Inspector Hub.
- [ ] Confirm inspector does not see another user's stale draft/dashboard card.
- [ ] Confirm open form drafts stay creator-private.
- [ ] Confirm submitted/exported forms appear for reviewers.
- [x] Confirm sync queue drains cleanly with no RLS denials.

## Assumptions

- Reviewer side means all approved non-inspector roles: admin, engineer, office technician.
- Inspector side means the inspector sees their own submitted work and comments assigned to their work.
- Comments are first-class review records, not always to-dos.
- To-dos remain optional actions created separately from comments.
- Approval is informational and visible to inspectors, but does not lock content.
- V1 supports whole-item and section-level comments, not field-level comments.
