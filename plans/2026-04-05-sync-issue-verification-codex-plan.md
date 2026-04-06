# Sync Issue Verification Tracker

Date: 2026-04-05
Branch: `sync-engine-refactor`
Author: Codex

## Goal

Verify every open sync-related GitHub issue against the current branch before
doing more fixes, then work only from issues that are still real.

## Current Verdict

### Verified Fixed, Needs Issue Close-Out

- [x] `#204` Inspector full sync fails integrity verification and clears cursors
  - Verified by `.claude/test-results/2026-04-05_2300_codex_sync-reverify/verification-summary.md`
  - Current evidence: tolerated drift no longer resets cursors; no new cursor poisoning observed.

- [x] `#205` Realtime sync hint RPC registration fails because required Supabase functions are missing
  - Verified fixed for registration + teardown semantics by the same reverify summary.
  - Current evidence: live private-channel subscription succeeds; teardown/rebind works after sign-out ordering fix.

- [x] `#224` Android resume quick sync does not catch up remote entry changes
  - Verified fixed at the sync/pull layer by the same reverify summary.
  - Important nuance: the already-open report UI still stayed stale until one route refresh, so this issue overlaps with `#212`.

- [x] `#167` `verify-sync.ps1` cannot verify Supabase state because loaded API key is invalid
  - Verified fixed on 2026-04-05 by running `pwsh -File tools/verify-sync.ps1 -Table projects -CountOnly`
  - Current evidence: script now returns `projects count: 9` against real Supabase credentials.
  - Root cause `H-167-A` confirmed: PowerShell/PostgREST count path was broken by `HEAD + Range: 0-0`.
  - Root cause `H-167-B` confirmed: PowerShell's default browser-like user agent is rejected by Supabase secret keys unless overridden.

## Still Open, Needs Root-Cause Work

- [ ] `#212` Foreground inspector does not auto-catch-up after admin sync
  - Status: root cause fixed in code, needs runtime reverify
  - Evidence: reverify run shows stale already-open report after foreground mutation and after channel rebind.
  - Root cause `H-212-A` confirmed: the sync layer can catch up, but `EntryEditorScreen` held a stale in-memory entry snapshot and never reloaded after sync completion.
  - Hypothesis `H-212-B`: realtime quick-sync is not always being triggered after foreground remote mutations, especially after rebind, so both transport and UI refresh may be involved.
  - Fix applied: open report screens now listen for completed sync cycles and reload their entry/related providers when a new successful sync snapshot arrives and no local edits are in progress.
  - Verification so far: targeted `dart analyze` clean; `flutter test test/features/entries/presentation/screens/entry_editor_report_test.dart` passed.
  - Next step: runtime reverify the foreground/rebind scenario to confirm whether `H-212-B` still exists independently of the UI staleness bug.

- [ ] `#211` Inspector does not show deletion notification banner after synced project removal
  - Status: root cause fixed in code, needs runtime reverify
  - Evidence: `ProjectListScreen` renders `DeletionNotificationBanner`, but unassignment only marked `synced_projects.unassigned_at` and never created a `deletion_notifications` row; banner also loaded once and stayed dismissed for the widget lifetime.
  - Root cause `H-211-A` confirmed: project unassignment/removal path did not create a deletion notification.
  - Root cause `H-211-B` confirmed: banner did not refresh after later sync completions and would stay dismissed even when new unseen notifications arrived.
  - Fix applied: `SyncEnrollmentService` now creates a project-level deletion notification on assignment removal; banner now reloads after sync completion and clears dismissal when new unseen notifications exist.
  - Verification so far: targeted `dart analyze` clean; `flutter test test/features/sync/application/sync_enrollment_service_test.dart` passed.
  - Next step: runtime reverify the inspector project-removal flow and then close the issue if the banner appears.

- [ ] `#206` Inspector report can get stuck on Loading after sync and throws a Null-to-String cast error
  - Status: root cause fixed in code, needs runtime reverify
  - Evidence: `Photo.fromMap()` was casting `file_path` to non-null `String`, while synced remote-only photos can legitimately have null/empty `file_path` and only a `remote_path`.
  - Root cause `H-206-A` confirmed: nullable synced photo field was still modeled as non-null and crashed the report route.
  - Fix applied: photo model now accepts nullable `filePath`; thumbnail/detail/gallery/pdf paths now fail soft when no local file exists.
  - Verification so far: targeted `dart analyze` clean; `flutter test test/data/models/photo_test.dart test/services/photo_service_test.dart` passed.
  - Next step: runtime reverify synced-photo report flow before closing the GitHub issue.

- [ ] `#225` Settings trash count stays stale after deleting trash and syncing
  - Status: likely already fixed in current branch
  - Evidence: `SettingsScreen` now awaits return from `/settings/trash` and calls `_loadTrashCount()` on navigation return.
  - Hypothesis `H-225-A` disproved for current source: the stale-count-on-return path appears to have already been patched.
  - Next step: do one manual/runtime verification pass before closing the issue.

- [ ] `#164` Startup sync pushes daily entry into Supabase RLS denial
  - Status: not yet reverified on current refactored branch
  - Evidence: issue ref points at removed `sync_orchestrator.dart`, so the issue is partly stale on its face.
  - Hypothesis `H-164-A`: already fixed by refactor plus LWW/skip logic, and only needs live repro to clear.
  - Hypothesis `H-164-B`: current push eligibility still allows an out-of-scope `daily_entries` row into the push queue under some startup/auth timing.
  - Next step: verify by code-path audit first, then runtime repro only if static proof is insufficient.

## Tooling / Tech-Debt Items Touching Sync

- [ ] `#226` Lint: `no_silent_catch`
  - Status: open sync-adjacent tech debt
  - Sync-relevant site: `lib/features/sync/engine/file_sync_handler.dart:183`

- [ ] `#227` Lint: `path_traversal_guard`
  - Status: open sync test debt
  - Sync-relevant sites are in sync adapter/characterization tests.

- [ ] `#228` Lint: `copywith_nullable_sentinel`
  - Status: open sync code debt
  - Sync-relevant site: `lib/features/sync/engine/integrity_checker.dart:42`

## Deferred / Out Of Scope For This Pass

- [ ] `#129` Remote signed URL fallback for synced documents
  - Enhancement, not a current defect. Keep out of the bulletproof defect pass unless requested.

## Work Queue

1. Close verified fixed issues with concrete evidence: `#204`, `#205`, `#224`, `#167`.
2. Reverify `#206`, `#211`, and `#212` at runtime now that their confirmed root causes are patched.
3. Runtime-check `#225` so it can be either closed or left open with concrete evidence.
4. Reassess `#164` after static audit; only do a live repro if the code remains ambiguous.
