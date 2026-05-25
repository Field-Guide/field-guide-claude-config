# Sentry Repair, Issue Sweep, and PR Cleanup

## Summary To-Dos

- [ ] Fix the iPhone `form_responses` repair failure from `FLUTTER-1Q` / GitHub `#336`.
- [ ] Reopen and retitle closed GitHub `#294` because linked Sentry group `FLUTTER-10` is still active with 65 events.
- [ ] Sweep GitHub `#322` through `#336`, including PRs `#328` and `#330`.
- [ ] Sweep closed Sentry-linked GitHub issues that are still receiving events.
- [ ] Close/resolve only after there is evidence: passing checks, merged PRs, no fresh matching Sentry events, or a documented duplicate/noise reason.

## Code Fix To-Dos

- [ ] Update `FormResponseAdapter` so `form_responses` declares both dependencies:
  - [ ] `projects` via `project_id`.
  - [ ] `daily_entries` via `entry_id`.
- [ ] Ensure sync push planning blocks `form_responses` behind missing or failed parent `daily_entries`.
- [ ] Add `form_responses` to entry-scoped blocked-row repair coverage so existing `RLS denied (42501)` rows can repair.
- [ ] Add `form_responses` to project cleanup/change-log coverage:
  - [ ] Ensure `change_log.project_id` is populated for `form_responses`.
  - [ ] Add a narrow Supabase migration if trigger regeneration is needed.
  - [ ] Include project-scoped `form_responses` in local eviction cleanup.

## GitHub and Sentry Cleanup To-Dos

- [ ] `#294` / `FLUTTER-10`: reopen, retitle to `RLS DENIED (42501): form_responses`, link to `#336`, keep open until fixed.
- [ ] `#336` / `FLUTTER-1Q`: keep open until the form-response fix lands and no fresh matching Sentry event appears.
- [ ] `#322`-`#327`: verify current status, close only with evidence or leave open with a specific remaining fix.
- [ ] `#328`: already merged on `2026-05-19`; investigate and clear its post-merge failed `Analyze & Test` result before treating it as fully clean.
- [ ] `#329`: fix or verify the `Unexpected query parameter(s) for entries: projectId` regression.
- [ ] `#330`: open, mergeable, blocked by failed `Analyze & Test`; fix the file-size hard-cap failure, rerun checks, then merge.
- [ ] `#331`-`#335`: verify each against current code/Sentry, then close or keep open with a concrete owner.
- [ ] Reopen or update closed GitHub issues whose linked Sentry group is active after close:
  - [ ] `#319` / `FLUTTER-19`, 21 events.
  - [ ] `#315` / `FLUTTER-16`, 21 events.
  - [ ] `#288` / `FLUTTER-W`, 15 events.
  - [ ] `#311` / `FLUTTER-15`, 9 events.
  - [ ] `#318` / `FLUTTER-18`, 4 events.
  - [ ] `#300` / `FLUTTER-12`, 3 events.

## Test To-Dos

- [ ] Add unit coverage for `FormResponseAdapter` dependency and FK mapping.
- [ ] Add push-planner coverage proving `form_responses.entry_id` waits on `daily_entries`.
- [ ] Add repair coverage proving blocked `form_responses` RLS rows are repairable.
- [ ] Add schema/migration verification for `form_responses` `change_log.project_id`.
- [ ] Run the smallest relevant Dart sync/repair test set.
- [ ] Run PR `#330` checks again after fixing the file-size hard-cap failure.
- [ ] Do not use `MOCK_AUTH`.

## Acceptance To-Dos

- [ ] No new `RLS DENIED (42501): form_responses` events after the fix.
- [ ] Existing blocked `form_responses` rows become repairable instead of exhausting retries.
- [ ] `#330` is merged or explicitly closed with a documented reason.
- [ ] `#328` has no unresolved post-merge failure requiring action.
- [ ] Every item from `#322` through `#336` has a final state: merged, closed with evidence, reopened, or left open with a precise fix.
- [ ] Active Sentry groups are not linked only to closed GitHub issues.
