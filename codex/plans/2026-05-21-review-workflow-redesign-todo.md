# Review Workflow Redesign To-Do Spec

## Goal

Replace the current crowded Review Hub action-card flow with a clear project
review workflow:

- Inspectors complete their own draft reports through the existing draft review
  gate.
- Only completed project reports become visible for reviewer review.
- Reviewers open completed reports read-only, leave section comments from the
  report itself, and approve from the bottom of the report.
- Inspector correction work is driven by section comments, not a separate
  "Request Changes" button.

No wireframes are included in this spec. This is the implementation to-do list
and decision record.

## Current Code Trace

- Current Review Hub screen:
  `lib/features/review/presentation/screens/review_hub_screen.dart`
- Current Review Hub card layout:
  `lib/features/review/presentation/screens/review_hub_screen_widgets.dart`
- Current Review Hub provider:
  `lib/features/review/presentation/providers/review_hub_provider.dart`
- Current review repository/data owner:
  `lib/features/review/data/repositories/review_repository_impl.dart`
  and
  `lib/features/review/data/datasources/local/review_comment_local_datasource.dart`
- Current draft pre-submit flow:
  `lib/features/entries/presentation/screens/entry_review_screen.dart`
  to
  `lib/features/entries/presentation/screens/review_summary_screen.dart`
- Current submitted entry open path:
  Review Hub `Open` routes to `/report/:entryId`, which maps to
  `EntryEditorScreen(projectId: '', entryId: entryId)`.
- Current form open path:
  Review Hub `Open` routes to `/form/:responseId` via
  `FormResponseRouteIntents.openResponse`.

Observed implementation problems:

- Review Hub mixes entries, forms, and comments into one sorted feed.
- Review cards show a crowded button cluster: `Open`, `Comment`, `Changes`,
  `Approve`, and comment-level `To-Do` / `Resolve`.
- `Approve` is immediate and can be tapped repeatedly.
- `SafeAction.runSafeAction()` sets loading state but does not prevent re-entry.
- Review Hub buttons do not consume `provider.isLoading`, so repeated taps can
  queue repeated local writes.
- Repeated approve updates `reviewed_at` / `updated_at` again and queues more
  sync work.
- Repeated request-changes creates duplicate `review_comments` rows because
  each comment gets a new UUID.
- Review decisions live on the hub card instead of the read-only report detail,
  so users have to bounce between screens to inspect and approve.

## Product Decisions

- Keep the current inspector draft-review-before-submit flow as the completion
  check. Do not redesign that user flow in this pass.
- The draft review gate is the final check before a project report becomes
  completed and reviewable.
- There is no separate "Submit for Review" action.
- Draft/private work is not visible to reviewers.
- Only project-completed reports are visible to other people for review.
- If an inspector edits a completed or approved project report, it returns to
  private draft state and must be completed again.
- Non-project completion is not part of this project review workflow.
- Non-project completion must stay outside the project review workflow enum.
- Project review state values are:
  - `draft`
  - `project_completed`
  - `needs_action`
  - `approved`
- Reviewer approval sets the canonical project review state to `approved`.
- Reviewer comments are section-level comments, not free-form general report
  comments.
- The separate `Request Changes` action is removed from the reviewer UI.
- Leaving section comments and exiting without approval returns the report to
  the inspector as `needs_action`.
- Leaving comments and approving keeps the report `approved`.
- Approval does not automatically resolve comments.
- To-Dos remain optional reminders only. They are not automatically created by
  review comments.
- Legacy review-comment To-Dos and `legacy_todo_id` links are retired. They
  require no preservation and should be deleted/repaired in favor of
  first-class `review_comments`.
- Either inspector or reviewer can resolve review comments.
- Inspector explicitly marks review comments resolved.
- After inspector resolves comments, the inspector can:
  - mark corrections complete, returning the item to inspector `Completed`
    without reviewer approval, or
  - send it back for re-review, returning it to reviewer `Unreviewed` with a
    compact `Re-review` marker.
- Re-review items sort above brand-new unreviewed items.

## Review Hub UX Requirements

- Review Hub should look and behave more like the All Entries list.
- Review Hub item rows should show:
  - item type: daily entry or form
  - date
  - report/form identity
  - compact project review status
  - compact comment count
  - compact `Re-review` marker when applicable
- Remove inline action buttons from Review Hub item rows.
- Tapping a row opens the full read-only review detail.
- Reviewer tabs:
  - `Unreviewed`
  - `Needs Inspector Action`
  - `Approved`
- Inspector tabs:
  - `Needs Action`
  - `Completed`
  - `Approved`
- Tab counts show item totals only, not unresolved comment counts.
- Comments must be grouped under the entry/form they belong to, not mixed into
  the top-level list as standalone cards.
- Reviewer `Needs Inspector Action` remains visible to reviewers so returned
  work can be tracked.
- Inspector dashboard should show a summary card like
  `2 completed reports have comments`; tapping it opens Review Hub.

## Read-Only Review Detail Requirements

- Opening a Review Hub item shows the matching daily entry or form in read-only
  review mode.
- Reviewers can preview/export from read-only review detail.
- Reviewers cannot edit or save from read-only review detail.
- The bottom primary action for reviewers is `Reviewed and Approved`.
- `Reviewed and Approved` is always available at the bottom.
- Tapping `Reviewed and Approved` shows a concise confirmation:
  `Approve this report?`
- After approval, return to Review Hub.
- If a reviewer added comments and tries to leave without approving, show a
  concise exit confirmation explaining that leaving comments without approval
  returns the report to the inspector for review.
- Confirmed exit with comments and no approval sets state to `needs_action` and
  returns to Review Hub.
- Reviewer detail section comments:
  - section headers get a small comment icon or badge
  - tapping the badge opens a dismissible dialog
  - badge/count alone is enough; do not add large section highlighting
- Daily Entry commentable sections for this pass:
  - activities
  - contractors
  - safety and site conditions
  - pay items
  - photos
  - forms
- Forms must support the same review style:
  - daily entry can open attached forms
  - form review is read-only
  - form sections expose the same compact comment badge/dialog behavior

## Inspector Correction Requirements

- Inspector `Needs Action` shows completed reports returned by reviewers.
- Returned reports show section comment badges in the same sections reviewers
  used.
- Inspector can open the comment dialog and mark comments resolved.
- Inspector can edit the returned report, but any edit keeps/returns it to
  private draft or correction state until they complete it again.
- Inspector completion after comments provides two paths:
  - `Corrections Complete`: comments resolved, item returns to inspector
    `Completed`, not reviewer-approved.
  - `Send for Re-review`: item returns to reviewer `Unreviewed` with a compact
    `Re-review` marker and sorts above brand-new unreviewed work.

## Data Model To-Dos

- [ ] Add one canonical project review workflow field to project daily entries.
      Preferred persisted values:
      - `draft`
      - `project_completed`
      - `needs_action`
      - `approved`
- [ ] Add the same canonical project review workflow field to form responses.
- [ ] Keep non-project completion outside this project review enum.
- [ ] Add project completion metadata on daily entries and form responses:
      - completed by user id
      - completed at
      - completion revision or cycle number if needed for audit/sync ordering
- [ ] Add approval metadata on daily entries and form responses:
      - reviewed by user id
      - reviewed at
- [ ] Add return/correction metadata where needed:
      - returned by user id
      - returned at
      - latest review cycle id or integer
      - re-review requested marker/timestamp
- [ ] Decide exact column names during implementation, but keep the product
      state language above stable.
- [ ] Migrate existing project `submitted` daily entries to
      `project_completed` unless already approved/needs-action data proves a
      different state.
- [ ] Migrate existing `review_status = approved` rows to project workflow
      state `approved`.
- [ ] Migrate existing `review_status = changes_requested` rows to
      `needs_action`.
- [ ] Keep export artifact history separate from review workflow state.

## Review Comment Model To-Dos

- [ ] Continue using the existing `review_comments` model/table.
- [ ] Use `target_type` and `target_id` for entry/form targeting.
- [ ] Use `section_key` and `section_label` for section-level comments.
- [ ] Require section targeting for new review comments created from the review
      detail UI.
- [ ] Preserve `open` / `resolved` comment status.
- [ ] Do not preserve optional To-Do creation from a comment in this review
      workflow; manual To-Dos remain available through the normal To-Do
      feature.
- [ ] Add helper APIs for:
      - comments by target grouped by section
      - unresolved comment count by target
      - resolve comment from inspector or reviewer
      - comments added during the current review session

## Flutter UI To-Dos

- [ ] Rename/copy internal labels so "draft review" and "submitted/project
      review" are not conflated.
- [ ] Keep `EntryReviewScreen` and `ReviewSummaryScreen` as the inspector
      completion gate.
- [ ] Update the completion gate submit action to set project workflow state to
      `project_completed`, not reviewer approval.
- [ ] Rework Review Hub body from mixed feed cards to tabbed list rows.
- [ ] Remove `Comment`, `Changes`, `Approve`, `To-Do`, and `Resolve` button
      clusters from Review Hub list rows.
- [ ] Add reviewer tabs:
      - `Unreviewed`
      - `Needs Inspector Action`
      - `Approved`
- [ ] Add inspector tabs:
      - `Needs Action`
      - `Completed`
      - `Approved`
- [ ] Add row status/comment count rendering similar to the All Entries list.
- [ ] Route row taps to read-only review detail.
- [ ] Add read-only daily entry review mode:
      - edit controls hidden
      - save hidden
      - preview/export retained
      - section comment badge/dialog on supported sections
      - bottom `Reviewed and Approved` button for reviewers
- [ ] Add read-only form review mode:
      - edit controls hidden
      - save hidden
      - preview/export retained
      - section comment badge/dialog on form sections
      - usable from an entry's forms section
- [ ] Add approval confirmation dialog with text `Approve this report?`.
- [ ] Add exit confirmation for comments-without-approval.
- [ ] Add inspector returned-comment UI:
      - dashboard summary card
      - inspector Review Hub `Needs Action`
      - entry/form section badges
      - explicit mark-resolved action
      - `Corrections Complete`
      - `Send for Re-review`
- [ ] Keep S21 portrait ergonomics as a primary layout target.

## Mutation And Duplicate-Action Hardening To-Dos

- [ ] Add item-level in-flight guards for review detail actions.
- [ ] Disable or show loading on `Reviewed and Approved` while approval is in
      progress.
- [ ] Make approval idempotent:
      - if already `approved`, do not write another update
      - do not refresh `reviewed_at` on duplicate taps
      - do not queue extra change-log work
- [ ] Make comment save single-submit:
      - disable save while creating a comment
      - do not create duplicate rows from repeated taps
- [ ] Make resolve idempotent:
      - if already resolved, do not write another update
- [ ] Remove or deprecate UI access to provider-level `requestChanges`.
- [ ] Keep lower-level request/return APIs only if needed for migration or
      compatibility, but do not expose the redundant action to users.

## Local SQLite To-Dos

- [ ] Add migration for the new project review workflow columns and metadata.
- [ ] Add indexes for project review list queries:
      - project id + workflow state + updated/review cycle ordering
      - creator id + workflow state for inspector tabs
      - re-review marker sorting
- [ ] Add or update constraints for legal enum values.
- [ ] Add migration repair for existing review status values.
- [ ] Add local query methods for reviewer tabs.
- [ ] Add local query methods for inspector tabs.
- [ ] Add grouped section-comment queries.
- [ ] Ensure local triggers produce correct `change_log` rows for workflow
      state and review comment mutations.

## Supabase And RLS To-Dos

- [ ] Add matching Supabase migration for workflow state and metadata columns.
- [ ] Add constraints/checks for legal project workflow enum values.
- [ ] Update RLS so:
      - project draft entries/forms remain creator-private
      - project-completed entries/forms are visible to approved reviewers
      - needs-action entries/forms are visible to the creator and reviewers
      - approved entries/forms are visible to the creator and reviewers
      - non-project completion remains outside reviewer visibility
- [ ] Update review comment policies so section comments are visible to:
      - the target creator
      - approved reviewers on the project
      - assigned/related users already allowed by current policy
- [ ] Ensure reviewers cannot mutate inspector content fields through review
      routes.
- [ ] Ensure approved reviewer roles remain admin, engineer, and office
      technician.
- [ ] Keep inspector from approving through reviewer-only paths.
- [ ] Keep optional To-Do creation explicitly user-triggered.

## Sync To-Dos

- [ ] Register new/changed review workflow columns in local and remote sync
      mapping.
- [ ] Verify `daily_entries`, `form_responses`, and `review_comments` push in
      dependency order.
- [ ] Verify review comments keep direct project scoping for pull/push.
- [ ] Verify duplicate approve does not queue repeated pending updates.
- [ ] Verify comment creation and resolution drain cleanly.
- [ ] Verify returned `needs_action` state syncs to the inspector device.
- [ ] Verify approved state syncs to the inspector device.
- [ ] Verify re-review marker syncs and sorts above new unreviewed items.

## Test To-Dos

- [ ] Provider tests for state transitions:
      - draft to project_completed
      - project_completed to approved
      - project_completed to needs_action on comment-exit-without-approval
      - needs_action to project_completed through Corrections Complete
      - needs_action to project_completed plus re-review marker through Send
        for Re-review
      - approved edit clears approval and returns to draft/private
- [ ] Provider tests for duplicate-action guards:
      - duplicate approve is a no-op after first write
      - duplicate comment save does not create duplicate comments
      - duplicate resolve is a no-op
- [ ] Repository/datasource tests for:
      - reviewer tab filters
      - inspector tab filters
      - section comment grouping
      - state migration from existing `submitted` / `review_status`
      - non-project completion excluded from review workflow
- [ ] Widget tests for reviewer Review Hub tabs and list-row layout.
- [ ] Widget tests for inspector Review Hub tabs.
- [ ] Widget tests for read-only entry review detail:
      - no edit/save
      - preview/export retained
      - section comment badge/dialog
      - bottom Reviewed and Approved action
      - comments-without-approval exit confirmation
- [ ] Widget tests for read-only form review detail.
- [ ] RLS/sync tests for:
      - draft privacy
      - project_completed reviewer visibility
      - needs_action visibility
      - approved visibility
      - non-project completion not reviewable
- [ ] Custom lint/guardrail follow-up if direct workflow-state writes need to
      stay inside review persistence owners.

## Live S21 Verification To-Dos

- [ ] Use real auth and real backend state. Do not use `MOCK_AUTH`.
- [ ] Default project:
      - Grand Blanc Test
      - project id `6936f810-ec15-494e-b4aa-280bf3bf15d3`
      - project number `12344`
- [ ] Verify inspector draft completion:
      - draft is private before completion
      - completion sets project workflow state to `project_completed`
      - completed report appears in reviewer Review Hub
- [ ] Verify reviewer entry review:
      - reviewer opens read-only entry
      - reviewer adds section comment
      - reviewer exits without approval
      - item moves to `needs_action`
      - inspector dashboard summary appears
- [ ] Verify inspector correction:
      - inspector opens Needs Action
      - inspector sees section comments
      - inspector marks comments resolved
      - inspector chooses Corrections Complete
      - item returns to inspector Completed, not Approved
- [ ] Verify re-review:
      - inspector sends item for re-review
      - reviewer sees it in Unreviewed with Re-review marker
      - re-review sorts above new unreviewed work
- [ ] Verify approval:
      - reviewer opens read-only detail
      - preview/export remains available
      - reviewer taps Reviewed and Approved
      - confirmation says `Approve this report?`
      - approval returns to Review Hub
      - inspector sees item under Approved
- [ ] Verify edit-after-approval:
      - inspector edit clears approval
      - item returns to private draft/completion-needed state
- [ ] Verify forms:
      - attached form opens read-only from reviewed entry
      - reviewer can add section comments
      - reviewer can approve report after form review
      - form review state syncs and remains consistent with entry review flow
- [ ] Verify sync:
      - queue drains
      - no RLS denials
      - no duplicate queued approvals from repeated taps
      - screenshots show no crowded old Review Hub button clusters

## Deferred Or Explicitly Out Of Scope

- No new wireframe artifact in this spec.
- No general free-form report comment widget.
- No automatic To-Do creation from review comments.
- No separate `Request Changes` reviewer button.
- No reviewer card-level approve/comment button cluster.
- No admin/Saugatuck default verification unless explicitly requested later.
