# Sync Soak Unified Live Task List

Date: 2026-04-18
Status: active session checklist
Controlling spec: `.codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`
Implementation log: `.codex/checkpoints/2026-04-18-sync-soak-unified-implementation-log.md`

## Current Rule

Check off an item only after the implementation exists and the required local
or device evidence has been recorded in the implementation log. Device lanes
must use real sessions, the refactored flow path, UI-triggered sync, and
`directDriverSyncEndpointUsed=false`.

## Role Permission Reference

- [x] Saved the controlling role matrix at
  `.codex/role-permission-matrix.md` after user correction on 2026-04-19.
- [x] Locked the role-testing interpretation:
  - admin is the only company/member/admin-surface role;
  - engineer and office technician are project-management peers;
  - inspector is field-data capable but not project-management capable;
  - all approved roles can edit field data unless a specific workflow narrows
    it;
  - office technician must not be tested as a restricted reviewer;
  - Trash is user-scoped for every approved user, not admin-only.
- [x] Corrected the stale `UserProfile.canManageProjects` comment to include
  office technician.
- [x] Corrected the in-progress role visibility helper so office technician is
  grouped with admin/engineer for company-wide project-assignment visibility;
  only inspector is expected to see own assignment rows only.
- [x] Corrected the Trash role rule after user clarification:
  - removed Trash from admin-only role documentation;
  - opened the Settings Trash tile and `/settings/trash` route to approved
    users;
  - forced Trash screen loads and badge counts through current-user
    `deleted_by` scope so admins do not see other users' trash by default.

## Current Focus - P1 Role, Account, Scope, And RLS Hardening

- [x] Re-read the controlling todo, implementation log, live task list, and
  working tree before continuing this role/RLS iteration.
- [x] Record the accepted stale account/scope proof artifact and update the
  checklist without over-weighting same-device switching.
- [x] Reframe same-device account switching as a regression check, not the
  primary role-security model.
- [x] Stop treating live account deactivation as a required role-hardening
  gate. Do not run live admin deactivation/revocation as part of this beta
  readiness lane.
- [x] Keep S21/S10 on separate real accounts for the next proof. Account
  rotation is only a setup fallback, not the primary model.
- [x] Choose one real shared beta project and record the expected participant
  map: admin, engineer, office technician, inspector, company id, project id,
  assignment rows, and intended role capabilities.
  - [x] Resolved the prior live blocker by seeding and accepting the disposable
    soak fixture. S10 inspector and S21 office technician both saw Springfield
    plus `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK` after the accepted
    cleanup/visibility/conflict sentinel run.
- [ ] Prove same-project account isolation before role traffic:
  - [x] S10/S21 physical inspector/office-technician lane resolves each
    device to its own user id, role, company id, membership status,
    permission booleans, clean queue state, and clean project/provider scope
    after the accepted strict role sweep
    `20260419-s10-s21-role-sweep-inspector-office-draft-dispose-cleanup`.
  - [ ] each device resolves to its own user id, role, company id, membership
    status, permission booleans, selected-project state, realtime channel
    state, and clean queue state for all four roles in the expanded lane;
    - [x] Physical inspector and office-technician subsets accepted on S10/S21.
    - [x] Emulator admin subset accepted in
      `20260419-emulator-admin-role-account-switch-accepted`.
    - [x] Emulator engineer subset accepted in
      `20260419-emulator-engineer-role-account-switch`.
    - [ ] True simultaneous four-role run remains open. A second read-only
      `Pixel_7_API_36` attempt on `emulator-5558` did not become ADB-visible
      after five minutes and was stopped; artifact:
      `.claude/test-results/2026-04-19/emulator-capacity-attempt-20260419T0921Z/summary.json`.
  - [x] S10/S21 physical inspector/office-technician lane proved no stale
    selected project, provider scope, local active project cache, or Sync
    Dashboard residue at acceptance time; both devices had provider/local
    equality with `providerOnlyIds=[]`.
  - [x] repeat stale selected-project/provider/local-cache/Sync Dashboard
    checks for admin and engineer in the expanded four-role lane.
    - [x] Admin emulator subset accepted in
      `20260419-emulator-admin-role-account-switch-accepted`.
    - [x] Engineer emulator subset accepted in
      `20260419-emulator-engineer-role-account-switch`.
  - [x] Verified four real role accounts are present in `.env.secret` without
    printing secret values: admin, engineer, office technician, and inspector
    all resolve to approved users in company
    `26fe92cd-7044-4412-9a09-5c5f49a292f9`.
  - [x] Booted one usable Android emulator actor (`emulator-5556`) and mapped
    host port `4972` after Windows excluded the earlier host port; a second
    read-only instance did not survive boot, so the current machine can supply
    three concurrent UI actors unless another AVD is added.
  - [x] Preserve
    `20260419-emulator-admin-role-account-switch-sweep` as rejected evidence,
    not accepted admin proof. Admin login and route/control checks worked, but
    fresh-device UI sync ended with 360 unprocessed pull-echo `change_log`
    rows, proving a remaining sync suppression defect on fresh local stores.
  - [x] Patched the fresh-store pull/apply trigger-suppression path and the
    role-account wrapper failure reporting locally after the rejected emulator
    run. The remaining acceptance gate is a clean emulator reinstall/clear and
    UI-driven admin sweep with no outbound pull-echo residue.
  - [x] Rerun the fresh-emulator admin role sweep until a fresh login/pull
    through the UI produces project/provider visibility without outbound
    pull-echo residue. Accepted
    `20260419-emulator-admin-role-account-switch-accepted`.
    It proved admin UI login, admin route/control access, active realtime
    hint transport, provider/local project visibility for Springfield plus
    the disposable soak project, UI Sync Dashboard sync, empty queues, zero
    undismissed conflicts, clean raw text logs, and
    `directDriverSyncEndpointUsed=false`.
  - [x] Rerun the fresh-emulator engineer subset with the same UI-only
    account-switch gate. Accepted
    `20260419-emulator-engineer-role-account-switch`; it proved engineer
    login, admin/trash denial, project-new/project-create access, active
    realtime hint transport, stale-scope cleanup, clean raw logs, empty
    queues/conflicts, and `directDriverSyncEndpointUsed=false`.
  - [x] Add fail-loud sync-hint subscription maintenance to the role-account
    harness so stale realtime rows cannot silently force fallback polling:
    role preflight now queries the real account's own RLS-visible
    `sync_hint_subscriptions`, deletes only stale own rows, writes a redacted
    proof, and fails the role run if stale rows remain or the account is near
    the active-channel cap.
    - [x] Local harness gate:
      `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14
      test files.
    - [x] Live cleanup/report:
      `.claude/test-results/2026-04-19/sync-hint-maintenance-20260419T091739Z/summary.json`
      passed for admin, engineer, office technician, and inspector. The
      earlier cleanup pass removed stale office-technician rows through that
      role's own RLS path; the final report showed zero stale active rows and
      no near-cap account.
    - [ ] Add a backend/staging scheduled alert or dashboard for stale
      `sync_hint_subscriptions`; the harness now fails loudly, but production
      still needs an operational alarm outside soak runs.
  - [x] Verify the new sync-hint preflight on all currently reachable UI
    actors. Preserve
    `20260419-three-actor-role-account-switch-sync-hint-preflight` as a
    rejected harness-contract run: it exposed that same-user reauthentication
    was incorrectly rejected by
    `account-switch-user-changed-or-started-logged-out` even though the role
    sweeps, queues, conflicts, logs, and screenshots were clean.
  - [x] Patch same-user reauthentication handling and accept the three-actor
    UI role-account gate:
    `20260419-three-actor-role-account-switch-sync-hint-preflight-after-reauth-fix`.
    S10 inspector, S21 office technician, and emulator engineer each passed
    sync-hint preflight, same-target-user reauth, route/control checks,
    UI-triggered Sync Dashboard sync, stale-scope sentinels, empty
    queues/conflicts, zero runtime/logging gaps, 23 screenshots, 32 debug/adb
    captures, and `directDriverSyncEndpointUsed=false`.
  - [x] Re-prove the emulator admin role with the new sync-hint preflight:
    `20260419-emulator-admin-role-account-switch-with-sync-hint-preflight`.
    Admin preflight had `beforeActive=0`, `afterActive=0`,
    `afterStale=0`, and `nearCap=false`; the UI role sweep passed with
    clean logs, empty queues/conflicts, two visible projects, and
    `directDriverSyncEndpointUsed=false`.
- [ ] Stress the inspector -> office-technician beta traffic seam:
  - [x] inspector creates/edits a daily entry on the shared project;
    accepted in
    `20260419-s10-s21-role-collaboration-after-popup-route-delay`.
  - [ ] inspector adds quantities, photos/documents/forms where the role is
    allowed;
    - [x] quantities subset accepted in
      `20260419-s10-s21-inspector-office-quantity-cross-device`;
    - [x] documents/storage subset accepted in
      `20260419-s10-s21-inspector-office-document-storage-fileprovider`;
    - [x] photos/storage/local-cache/visual subset accepted in
      `20260419-s10-s21-inspector-office-photo-cross-device-real-jpeg-visual-gate`;
    - [x] forms subset accepted in
      `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form-route-sentinel`.
      - [x] Preserve rejected form proof
        `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form`.
        It used UI-triggered Sync Dashboard sync and drained the queue, but
        S10 logged five undismissed remote-wins `form_responses` conflicts on
        the source device after pushing one insert plus five update
        `change_log` rows for the same MDOT 0582B record.
      - [x] Patch the false-conflict source: push planning now coalesces
        superseded local `change_log` rows for the same table/record into one
        remote write, and form creation through `InspectorFormProvider`
        stamps the local `created_by_user_id` from the real session before
        sync.
      - [x] Rebuild/restart S10 and S21 on the duplicate-change coalescing
        patch and rerun `mdot0582b-cross-device-only` as
        `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form-after-coalescing`.
        Preserve it as rejected evidence: source UI sync drained the six form
        rows to zero with zero undismissed conflicts, S21 pulled the form
        locally, and the screenshot showed real MDOT 0582B content, but the
        harness still expected stale route `/form-fill/<responseId>` while
        the app's registered route is `/form/<responseId>`.
      - [x] Patch the MDOT 0582B open-form route sentinel to assert
        `/form/<responseId>` while still requiring `mdot_hub_screen`, and add
        a harness wiring check for that route contract.
      - [x] Accepted `mdot0582b-cross-device-only` after the route-sentinel
        fix in
        `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form-route-sentinel`.
        It proved S10 inspector source local/remote MDOT 0582B markers, S21
        office-technician UI pull/local form visibility, `/form/<responseId>`
        open proof with `mdot_hub_screen`, normal cleanup, S21 cleanup pull,
        empty queues, zero raw undismissed conflicts, clean logs/screenshots,
        and `directDriverSyncEndpointUsed=false`.
  - [ ] inspector syncs through the UI and produces remote write proof for
    every changed table/storage object;
    - [x] daily-entry remote proof accepted in
      `20260419-s10-s21-role-collaboration-after-popup-route-delay`;
    - [x] document row plus `entry-documents` storage bytes/hash proof
      accepted in
      `20260419-s10-s21-inspector-office-document-storage-fileprovider`;
    - [x] quantity remote `entry_quantities` proof accepted in
      `20260419-s10-s21-inspector-office-quantity-cross-device`;
    - [x] photo remote row plus `entry-photos` storage bytes/hash proof
      accepted in
      `20260419-s10-s21-inspector-office-photo-cross-device-real-jpeg-visual-gate`;
    - [x] form remote proof accepted in
      `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form-route-sentinel`.
  - [ ] office technician pulls through the UI and proves local visibility of
    only the expected inspector-created records;
    - [x] daily-entry visibility accepted in
      `20260419-s10-s21-role-collaboration-after-popup-route-delay`;
    - [x] document row/tile/local cached-file visibility accepted in
      `20260419-s10-s21-inspector-office-document-storage-fileprovider`.
    - [x] quantity pull/local visibility accepted in
      `20260419-s10-s21-inspector-office-quantity-cross-device`.
    - [x] photo row/tile/local cached-file visibility accepted in
      `20260419-s10-s21-inspector-office-photo-cross-device-real-jpeg-visual-gate`.
    - [x] form response row/UI-open visibility accepted in
      `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form-route-sentinel`.
  - [ ] office technician reviews/edits only the fields/actions intended for
    that role;
    - [x] review todo/comment subset accepted in
      `20260419-s10-s21-role-collaboration-after-popup-route-delay`;
    - [ ] broader office review/edit scope remains open.
  - [ ] inspector pulls the office-technician changes and proves no unrelated
    admin/project-management data bled into the inspector scope.
- [ ] Stress engineer/admin/office-technician/inspector permission differences:
  - [x] office technician can reach expected project-create/project-management
    entry controls without leaking blank drafts after direct route
    replacement.
  - [x] inspector is denied project-new, hidden from project-create control,
    and denied current pay-app/PDF import route probes.
  - [x] admin and engineer can reach expected project-management flows in the
    same disposable-project lane;
    - [x] Admin route/control subset accepted on fresh emulator in
      `20260419-emulator-admin-role-account-switch-accepted`.
    - [x] Engineer route/control subset accepted on fresh emulator in
      `20260419-emulator-engineer-role-account-switch`.
  - [ ] office technician can perform intended office/project review work
    beyond the accepted review-todo slice;
  - [ ] inspector can perform intended field data work beyond the accepted
    daily-entry slice;
  - [ ] each role is denied or hidden from actions outside its beta role across
    the full role matrix.
- [ ] Stress forbidden seams with real non-admin sessions without mutating
  account status:
  - [ ] inspector cannot create/edit project setup, assignments, bid items,
    admin surfaces, trash, or restricted pay-app/PDF import surfaces;
  - [ ] office technician cannot access admin-only member/company surfaces;
  - [x] non-admin RPC/write attempts against admin-only or wrong-owner/wrong
    project operations are denied by Supabase/RLS using real anon tokens.
    `rls-denial-probes-20260419T0935Z` proved inspector, office technician,
    and engineer are denied by admin-only member/app-config/join-request RPCs;
    inspector is also denied by project-assignment mutation RPC before any
    mutation. No service-role credentials or account-status mutation were used.
- [ ] Verify storage and local placement:
  - [ ] uploaded photos/documents/signatures land in the expected bucket/path
    for the creating account/project;
    - [x] entry document subset accepted: S10 inspector wrote
      `documents/7327af1b-953c-49aa-9000-57cb3cb3db9e` to bucket
      `entry-documents`, path
      `docs/26fe92cd-7044-4412-9a09-5c5f49a292f9/743eb51d-8ff9-5a82-b291-ca3a7c977c40/enterprise_soak_cross_device_doc_S10_to_S21_round_1_025942.pdf`;
    - [x] entry photo subset accepted: S10 inspector wrote
      `photos/539b8816-b31e-4ffb-9930-357d8cd01817` to bucket
      `entry-photos`, path
      `entries/26fe92cd-7044-4412-9a09-5c5f49a292f9/743eb51d-8ff9-5a82-b291-ca3a7c977c40/role_photo_cross_S10_to_S21_round_1_035244.jpg`;
    - [ ] signatures in this same role lane remain open.
  - [ ] pulled files cache locally only for the receiving account/project
    scope;
    - [x] S21 office-technician pulled and cached the S10-created document,
      48 bytes, SHA-256
      `d7aacd14db7ca489d86ca71c834ac5513f54cbfbab168d7929c086b6a7e61dc6`;
    - [x] S21 office-technician pulled and cached the S10-created photo,
      841 bytes, SHA-256
      `59727940411ccb79f860aeb581f233a985051dc01fe020f920e81df2187af4b9`;
    - [ ] repeat for signatures and account-switch stale preview checks
      remains open.
  - [ ] sign-out/account switch leaves no visible stale tiles, previews, or
    selected-project state.
- [ ] Verify logs before accepting every run:
  - [ ] `runtimeErrors=0`;
  - [ ] `loggingGaps=0`;
  - [ ] `queueDrainResult=drained`;
  - [ ] `blockedRowCount=0`;
  - [ ] `unprocessedRowCount=0`;
  - [ ] `maxRetryCount=0`;
  - [ ] screenshots and widget-tree evidence show no overflow/red-screen/UI
    flow defects;
  - [ ] `directDriverSyncEndpointUsed=false`.
  - [x] Document/storage rerun
    `20260419-s10-s21-inspector-office-document-storage-fileprovider`
    satisfied all listed gates after raw artifact review.
  - [x] Quantity cross-device run
    `20260419-s10-s21-inspector-office-quantity-cross-device` satisfied all
    listed gates after raw artifact review.
  - [x] Rejected photo local-file proof run
    `20260419-s10-s21-inspector-office-photo-cross-device` because
    `/driver/local-file-head` did not support `photos`; patched route to use
    `photos.file_path`.
  - [x] Rejected photo local-cache run
    `20260419-s10-s21-inspector-office-photo-cross-device-local-file-head-photos`
    because S21 pulled/opened the photo but `photos.file_path` stayed null.
    Patched remote-backed thumbnail caching to download from `entry-photos`
    and persist local-only `photos.file_path` with triggers suppressed.
  - [x] Rejected photo visual gate run
    `20260419-s10-s21-inspector-office-photo-cross-device-local-cache-forward-retry`
    even though byte proof passed, because screenshot review showed the
    thumbnail still rendered `Image unavailable`; patched the flow to inject a
    real JPEG and the widget-tree classifier to fail on
    `photo_missing_image_visible`.
  - [x] Accepted photo seam
    `20260419-s10-s21-inspector-office-photo-cross-device-real-jpeg-visual-gate`
    after S21 cached-file SHA-256 matched storage, the screenshot rendered an
    actual thumbnail, the missing-image classifier had no hits, and both
    devices pulled cleanup through Sync Dashboard UI.
  - [x] Rejected MDOT 0582B cross-device form run
    `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form` because
    the source S10 sync created five undismissed `form_responses` conflicts
    despite an empty final queue. Raw proof showed the conflicts were
    self-inflicted duplicate local change-log rows for the same record, not
    cross-role bleed-through.
  - [x] Local duplicate-change hardening passed focused analyzer/tests:
    `dart analyze` on push planner/handler, form provider stamping, and
    focused tests; `flutter test test\features\sync\engine\push_handler_test.dart test\features\forms\presentation\providers\inspector_form_provider_test.dart -r expanded`.
  - [x] Rejected MDOT 0582B rerun
    `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form-after-coalescing`
    because the state sentinel expected `/form-fill/<responseId>` even though
    the app opened the registered `/form/<responseId>` route and the widget
    tree/screenshot contained `mdot_hub_screen`. This is preserved as a
    harness contract defect, not accepted app evidence.
  - [x] Accepted MDOT 0582B form seam
    `20260419-s10-s21-inspector-office-mdot0582b-cross-device-form-route-sentinel`
    after raw artifact review: `passed=true`, `queueDrainResult=drained`,
    `runtimeErrors=0`, `loggingGaps=0`, `blockedRowCount=0`,
    `unprocessedRowCount=0`, `maxRetryCount=0`, 16 screenshots, 17 debug/adb
    log captures, no app/runtime/layout/error signatures, final live S10/S21
    `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
    `undismissedConflictCount=0`, and `directDriverSyncEndpointUsed=false`.
  - [x] Rejected earlier green summary
    `20260419-s10-s21-inspector-office-document-storage-cross-device` because
    adb logcat showed `_openDocument error: FileUriExposedException`; this is
    preserved as a logging/sentinel gap and not accepted evidence.
- [ ] After role traffic gates pass, move to sync-system stress:
  - [ ] multi-round UI sync soak with real role accounts;
  - [ ] concurrent writer/reader traffic on the shared project;
  - [ ] queue liveness and final quiescence gates;
  - [ ] local/remote reconciliation for covered project tables;
  - [ ] storage object/row consistency for file-backed traffic;
  - [ ] explicit defect log for every runtime/UI/logging/sync anomaly.

## Immediate P0 - Fresh-Device Pull Echo Defect

- [x] Discovered during the first emulator admin role sweep:
  `20260419-emulator-admin-role-account-switch-sweep`.
- [x] Classified the role portion as partially proven but not accepted:
  admin resolved to user `88054934-9cc5-4af3-b1c6-38f262a7da23`, saw only
  Springfield plus the disposable soak project, reached admin dashboard/trash/
  project-new/project-create controls, and had clean runtime/logging artifacts.
- [x] Classified the blocker as sync-state contamination: after fresh login
  and UI sync, the emulator reported `pendingCount=360`,
  `unprocessedCount=360`, `blockedCount=0`, `undismissedConflictCount=0`,
  and grouped `change_log` insert residue for pulled rows including
  `photos`, `entry_equipment`, `entry_quantities`, `form_responses`,
  `documents`, `signature_files`, and `signature_audit_log`.
- [x] Patch fresh-store pull/apply trigger suppression so remote rows cannot
  echo into outbound `change_log`.
  - `TriggerStateStore` now tracks nested suppression ownership per active
    database object and only restores `sync_control.pulling=0` when the
    outermost owner exits.
  - `SyncControlService`, orphan purge, soft-delete purge, and export-artifact
    local rewrites now route through `TriggerStateStore` instead of opening
    independent raw `sync_control` suppression windows.
  - `SyncCoordinator.syncLocalAgencyProjects` now fails loudly when another
    sync gate is active instead of presenting a second overlapping sync as a
    normal run.
- [x] Add a focused regression test for fresh-store pull/apply suppression on
  affected tables.
  - Focused local gates passed:
    `dart analyze` on the touched sync/applicator/purger/export/coordinator
    files and focused tests;
    `flutter test test\features\sync\engine\local_sync_store_contract_test.dart test\features\sync\engine\pull_handler_test.dart test\features\sync\application\sync_coordinator_test.dart -r expanded`
    passed 67 tests;
    `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 13
    harness test files;
    `git diff --check` passed with line-ending warnings only.
- [x] Patch the account-switch proof wrapper so a missing queue sentinel
  preserves the underlying sync failure instead of throwing a
  missing-property exception.
- [x] Patch Sync Dashboard flow automation to wait for the Sync Now action to
  be visible, enabled, and idle before tapping. Rejected
  `20260419-emulator-admin-role-account-switch-after-trigger-depth` because
  the app was correctly syncing and the harness tapped a disabled button.
- [x] Patch role-account switch stale-scope aggregation to handle in-memory
  ordered dictionaries as well as JSON-shaped objects. Rejected
  `20260419-emulator-admin-role-account-switch-after-hint-cleanup` and
  `20260419-emulator-admin-role-account-switch-accepted-candidate` preserved
  the harness-shape failures while their app-side sentinels were clean.
- [x] Clean stale sync-hint subscription rows through each real role account's
  own authenticated RLS path after `register_sync_hint_channel` hit the live
  active-subscription cap.
- [x] Recover or reinstall the emulator after the patch and rerun the admin
  role-account sweep through UI sync.
  - Accepted:
    `20260419-emulator-admin-role-account-switch-accepted`.
  - Final live emulator `/driver/sync-status`: `pendingCount=0`,
    `blockedCount=0`, `unprocessedCount=0`,
    `undismissedConflictCount=0`.
  - Harness follow-up closed: role-account preflight now deletes stale own
    rows, writes a redacted proof, and fails near-cap accounts before the UI
    run can be misclassified.
  - Backend follow-up remains open: add a staging/production alert for stale
    `sync_hint_subscriptions` outside soak runs.

## Immediate P0 - Springfield Pull Echo Defect

- [x] User-reported symptom recorded: S21 showed no Springfield DWSRF pay
  items after Sync Dashboard reported completion.
- [x] Verified this was not backend data loss: remote Springfield DWSRF still
  had 131 active `bid_items`.
- [x] Verified the local defect state on S21 before repair: local
  Springfield `bid_items=0` with sync idle and no pending queue.
- [x] Ran forced integrity reset and UI-triggered sync; first pass completed
  without runtime/logging gaps but did not immediately restore local pay
  items.
- [x] Restarted the S21 app/driver after the second pull attempt lost the
  driver/app process.
- [x] Verified S21 local Springfield pay items recovered:
  `bid_items=131`, hash
  `cf1a37c9447e01fdb571de73cf4bef71d38cde8a288a1cf8a15a4a7289022540`.
- [x] Diagnosed the deeper defect: remote pull/backfill produced outbound
  local `change_log` inserts while trigger suppression was disabled.
- [x] Patched the sync mutex race so a lock-failed sync attempt cannot reset
  the active pull's trigger-suppression flag.
- [x] Added unit regression proof for lock-failure suppression ownership.
- [x] Ran local gates:
  - `dart analyze lib\features\sync\engine\sync_engine.dart test\features\sync\engine\sync_engine_status_test.dart`
  - `flutter test test\features\sync\engine\sync_engine_status_test.dart -r expanded`
- [ ] Drain the existing S21 pull-echo residue through real UI Sync Dashboard
  sync only.
  - Current evidence: `/driver/sync-status` on 2026-04-19 showed
    `pendingCount=251`, `unprocessedCount=251`, `blockedCount=0`,
    `isSyncing=false`.
  - Remaining grouped rows: Springfield `daily_entries=35`,
    `entry_quantities=145`, `personnel_types=9`, `photos=11`, plus
    `form_responses=51` with null `project_id`.
- [ ] Fix or harden the Sync Dashboard harness/UI state that left
  `sync_now_full_button` non-tappable while resume/sync actions existed.
- [ ] Accept the incident closed only after S21 proves:
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `queueDrainResult=drained`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - Springfield `bid_items=131` still visible locally;
  - `directDriverSyncEndpointUsed=false`.

## Immediate Slice T - Controlled Supabase Cleanup And Soak Fixture

- [x] User direction recorded: keep Springfield DWSRF as company demo seed
  data, remove junk non-Springfield project data, and create one obvious
  disposable project for role-boundary and scale soak testing.
- [x] Review the working tree before making backend changes.
- [x] Inventory remote Supabase projects and project-scoped row counts through
  service credentials without printing or persisting credentials.
- [x] Identify the exact Springfield DWSRF project row and preserve it.
- [x] Write a redacted pre-cleanup snapshot artifact listing preserved project,
  delete candidates, per-table counts, and storage-object candidates.
- [x] Choose and record the disposable soak project identity:
  - name: `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`;
  - project number: `SOAK-ROLE-TRAFFIC-20260418`;
  - company: current one-company beta company;
  - participants: admin, engineer, office technician, inspector.
- [x] Delete or soft-delete all non-Springfield, non-soak project-scoped junk
  rows using the production project lifecycle semantics selected after the
  inventory.
- [ ] Remove non-Springfield storage objects only when their project/table row
  ownership is proven by the snapshot.
- [x] Seed the soak project with enough real data for role traffic:
  - [x] project row;
  - [x] assignments for all four verified role accounts;
  - [x] at least two locations;
  - [x] bid items for quantity traffic;
  - [x] contractor, equipment, and personnel rows for daily-entry stress;
  - [x] inspector-owned draft daily entry for collaboration bootstrap.
- [x] Verify via remote counts that only Springfield plus the disposable soak
  project remain active in the beta company.
- [x] Drive S21 and S10 through UI Sync Dashboard pull after cleanup/seed.
- [x] Verify S21 and S10 logs after pull:
  - [x] `runtimeErrors=0`;
  - [x] `loggingGaps=0`;
  - [x] `queueDrainResult=drained`;
  - [x] `blockedRowCount=0`;
  - [x] `unprocessedRowCount=0`;
  - [x] `maxRetryCount=0`;
  - [x] screenshots/widget trees show no overflow, stale project, or bad UI
    flow.
- [x] Verify S10 inspector now sees the soak project and has local
  `project_assignments`, `daily_entries`, `locations`, and `bid_items`.
- [ ] Run `role-collaboration-stress-only` against the soak project and accept
  it only with per-record remote write proof plus final local visibility proof
  through server/pull.

## Immediate Slice S - Role Traffic Stress Plan Reset

- [x] Preserve the failed initial revocation artifact as diagnostic evidence:
  `20260418-s21-s10-role-revocation-admin-inspector-initial` reached target
  deactivation/account-status/sign-out recovery, then failed because the S10
  login sign-in button was below the visible viewport.
- [x] Add a stable auth shell scroll key and make the role account sign-in
  helper scroll to `login_sign_in_button` before tapping.
- [x] Run local focused gates:
  - `dart analyze lib/features/auth/presentation/widgets/auth_responsive_shell.dart lib/features/auth/presentation/screens/login_screen.dart lib/shared/testing_keys/auth_keys.dart lib/shared/testing_keys/testing_keys.dart lib/core/driver/screen_contract_registry.dart`.
  - `flutter test test/core/driver/root_sentinel_auth_widget_test.dart test/core/driver/registry_alignment_test.dart -r expanded`.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1`.
- [x] Rebuild S10 so the device has the auth shell scroll key.
- [x] Sign S10 back in as inspector through the real UI using the hardened
  login path.
  Accepted setup artifact:
  `20260418-s10-inspector-login-after-auth-scroll-key`.
- [x] Preserve the later successful revocation run only as diagnostic evidence,
  not as the forward role-hardening model:
  `20260418-s21-s10-role-revocation-admin-inspector-after-auth-scroll-key`.
- [ ] Replace the next implementation slice with a same-project
  inspector/office-technician collaboration stress flow and artifact-backed
  RLS/visibility/storage assertions.
- [ ] Do not continue the revocation/deactivation flow for beta readiness.
- [x] Implement initial `role-collaboration-stress-only` harness slice:
  inspector daily-entry UI edit, inspector UI sync, remote daily-entry proof,
  office-technician UI pull/local visibility, office-technician review comment
  UI write, remote `todo_items` proof, inspector final pull/local visibility,
  cleanup, and strict log/queue/direct-sync gates.
- [ ] Create or select a real shared beta project fixture with inspector and
  office-technician access before running the new collaboration flow.

## Current Focus - P1 Sync Engine Reconciliation Probe

- [x] Re-read the controlling todo, implementation log, live task list, and
  working tree before continuing.
- [x] Add `/driver/local-reconciliation-snapshot` as a read-only debug route.
- [x] Return per-table row counts, selected-column stable SHA-256 hash,
  sample ids, sample rows, truncation state, and hash scope from local SQLite.
- [x] Add `tools/sync-soak/Reconciliation.ps1` with local/remote snapshot
  comparison and mismatch classification.
- [x] Add `/driver/remote-reconciliation-snapshot` so remote snapshots use the
  app's real Supabase device session instead of host service-role credentials.
- [x] Add required project-scope table spec helper covering projects,
  assignments, daily entries, quantities, photos, form responses, signatures,
  documents, pay applications, and export artifact families.
- [x] Treat `form_exports`, `export_artifacts`, and `entry_exports` as
  included local-only export-history snapshots; do not remote-compare those
  tables while the adapters remain `skipPush`/`skipPull`.
- [x] Compare active row membership for synced tables by stable IDs/project
  IDs; tombstone retention/cleanup stays in the delete/cleanup gates.
- [x] Add focused Dart route/handler tests and PowerShell harness tests.
- [x] Run focused local gates:
  - `dart analyze` on the touched driver route/handler files and tests.
  - `flutter test test/core/driver/driver_data_sync_handler_test.dart test/core/driver/driver_data_sync_routes_test.dart -r expanded`.
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1`.
  - `git diff --check`.
- [x] Rebuild/restart S21 and S10 debug driver apps so the running devices
  include the new route.
- [x] Device-probe S21 and S10:
  - `/driver/ready` returned ready.
  - `/driver/change-log` returned `count=0`, `unprocessedCount=0`,
    `blockedCount=0`, `maxRetryCount=0`.
  - `/driver/sync-status` returned idle with `pendingCount=0`,
    `blockedCount=0`, `unprocessedCount=0`.
  - `/driver/local-reconciliation-snapshot?table=projects&select=id,updated_at&limit=100`
    returned full, non-truncated hashes.
- [x] Wire the reconciliation probe into accepted post-sync flow artifacts and
  fail covered lanes on local/remote count/hash mismatches.
- [x] Prove the gate on S21:
  `20260418-s21-sync-only-active-reconciliation-gate-rerun` passed with
  `queueDrainResult=drained`, `runtimeErrors=0`, `loggingGaps=0`,
  `blockedRowCount=0`, `unprocessedRowCount=0`, `maxRetryCount=0`,
  `directDriverSyncEndpointUsed=false`, `reconciliationProjectCount=1`,
  `reconciliationTableCount=13`, and `reconciliationFailedCount=0`.
- [x] Preserve the first failing gate artifact:
  `20260418-s21-sync-only-reconciliation-gate` failed only on reconciliation
  (`reconciliationFailedCount=6`) while queue/runtime/logging/direct-sync
  gates were clean, proving the gate fails covered lanes on mismatch.

## Current Focus - P1 File, Storage, And Attachment Hardening

- [x] Resume point captured after accepted saved-form/gallery lifecycle proof.
- [x] Working tree reviewed before continuing: only the unified todo and
  implementation log are modified in tracked files; this live task list is
  intentionally ignored but persisted on disk.
- [x] Inventory current production file-backed families, storage buckets,
  cleanup queues, and harness/device proof helpers.
- [x] Identify which P1 file/storage items can be closed by existing
  production evidence versus which require new implementation.
- [x] Implement the next smallest hardening slice without weakening the
  real-session/refactored-flow/UI-sync acceptance rules.
- [x] Run focused local gates for the changed code.
- [x] Verify the slice on device where the checklist requires live storage or
  cross-device evidence. The image-fixture slice is local-engine coverage; S21
  and S10 driver hygiene probes were still recorded after the local change.
- [x] Update the controlling todo and implementation log only after evidence
  exists.

## Immediate Slice C - MDOT 1126 Export Proof

- [x] Review working tree before continuing the interrupted run.
- [x] Verify Slice A/B code and harness still pass after resuming:
  - `/driver/local-file-head` route and tests;
  - `Flow.Mdot1126Export.ps1`;
  - `Get-SoakDriverLocalFileHead`;
  - `mdot1126-export-only` dispatcher/module/entrypoint wiring.
- [x] Rebuild/restart the S21 debug driver app so `/driver/local-file-head`
  is available in the running app.
- [x] Rebuild/restart the S10 debug driver app so `/driver/local-file-head`
  is available in the running app.
- [x] Confirm S21 `/driver/ready`, `/driver/change-log`, and
  `/driver/sync-status` are clean before mutation.
- [x] Confirm S10 `/driver/ready`, `/driver/change-log`, and
  `/driver/sync-status` are clean before regression.
- [x] Run S21 `mdot1126-export-only` initial attempt:
  `20260418-s21-mdot1126-export-initial` failed cleanly with
  `widget_wait_timeout`, final queue drained, `runtimeErrors=0`,
  `loggingGaps=0`, and `directDriverSyncEndpointUsed=false`.
- [x] Fix the initial export-flow blocker by accepting the report-attached
  export branch that skips `form_export_decision_dialog` and waits for the
  standalone export dialog.
- [x] Rebuild/restart S21 after the report-attached export branch fix.
- [x] Rerun S21 `mdot1126-export-only`:
  `20260418-s21-mdot1126-export-after-attached-branch-fix` passed with
  local export rows, local file size/hash proof, no export-table
  `change_log`, ledger cleanup, signature storage cleanup, final queue drain,
  `runtimeErrors=0`, `loggingGaps=0`, and
  `directDriverSyncEndpointUsed=false`.
- [x] Accept S21 only if the artifact proves:
  - report-attached saved form source;
  - local `form_exports` row;
  - local `export_artifacts` row;
  - local file exists at the row path with expected size/hash;
  - `form_exports` and `export_artifacts` do not emit `change_log` rows;
  - signature remote path/storage proof still holds for the underlying form;
  - ledger-owned cleanup;
  - UI-triggered cleanup sync;
  - final empty queue;
  - `runtimeErrors=0`;
  - `loggingGaps=0`;
  - `blockedRowCount=0`;
  - `unprocessedRowCount=0`;
  - `maxRetryCount=0`;
  - `directDriverSyncEndpointUsed=false`.
- [x] S21 failure recovery was not needed after the accepted rerun; preserve
  the clean initial failure artifact as diagnostic evidence.
- [x] Rebuild/restart S10 after the report-attached export branch fix.
- [x] Recover S10 through UI `sync-only` if the pre-existing
  `form_responses` queue row is still present.
- [x] Run S10 `mdot1126-export-only` regression after S21 acceptance:
  `20260418-s10-mdot1126-export-after-attached-branch-fix` passed with local
  export rows, local file size/hash proof, no export-table `change_log`,
  ledger cleanup, signature storage cleanup, final queue drain,
  `runtimeErrors=0`, `loggingGaps=0`, and
  `directDriverSyncEndpointUsed=false`.
- [x] Record accepted artifact paths in the implementation log.
- [x] Check off the `mdot_1126` item under P1 Builtin Form Export Proof in the
  controlling spec only after S21 and S10 evidence are accepted.

## P1 Builtin Form Export Proof

- [x] Generalize the MDOT 1126 export proof helpers only after the first
  accepted run proves the contract.
- [x] Implement/refactor `mdot0582b-export-only`.
- [x] Accept `mdot0582b-export-only` on S21:
  `20260418-s21-mdot0582b-export-initial` passed with local export rows,
  local file size/hash proof, no export-table `change_log`, cleanup, final
  queue drain, `runtimeErrors=0`, `loggingGaps=0`, and
  `directDriverSyncEndpointUsed=false`.
- [x] Run `mdot0582b-export-only` S10 regression:
  `20260418-s10-mdot0582b-export-initial` passed with the same export,
  cleanup, queue, runtime, logging, and direct-sync gates.
- [x] Implement/refactor `mdot1174r-export-only`.
- [x] Accept `mdot1174r-export-only` on S21:
  `20260418-s21-mdot1174r-export-initial` passed with local export rows,
  local file size/hash proof, no export-table `change_log`, cleanup, final
  queue drain, `runtimeErrors=0`, `loggingGaps=0`, and
  `directDriverSyncEndpointUsed=false`.
- [x] Run `mdot1174r-export-only` S10 regression:
  `20260418-s10-mdot1174r-export-initial` passed with the same export,
  cleanup, queue, runtime, logging, and direct-sync gates.
- [x] Update the controlling todo with exact artifact IDs for every accepted
  export lane.

## P1 Saved-Form And Gallery Lifecycle

- [x] Add or wire a refactored saved-form/gallery lifecycle flow.
- [x] Create saved form from `/report/:entryId`.
- [x] Reopen the saved form from the form gallery.
- [x] Edit and save the previously created form.
- [x] Exercise the export decision path.
- [x] Delete/cleanup through production UI/service seams.
- [x] Prove local and remote absence after cleanup.
- [x] Accept lifecycle sweep for `mdot_1126` on S21 and S10.
- [x] Accept lifecycle sweep for `mdot_0582b` on S21 and S10.
- [x] Accept lifecycle sweep for `mdot_1174r` on S21 and S10.

Accepted evidence:

- S21 `20260418-s21-form-gallery-lifecycle-final-build` passed with
  `queueDrainResult=drained`, `failedActorRounds=0`, `runtimeErrors=0`,
  `loggingGaps=0`, `blockedRowCount=0`, `unprocessedRowCount=0`,
  `maxRetryCount=0`, and `directDriverSyncEndpointUsed=false`.
- S10 `20260418-s10-form-gallery-lifecycle-after-expanded-hub-key` passed
  with the same queue, runtime, logging, and direct-sync gates.
- S21 ledger rows:
  `mdot_1126` `form_responses/0daa8349-cc23-4eaa-895e-bbcef8b7e2e7`,
  `mdot_0582b` `form_responses/9685c4a9-ba17-4701-bf25-bc4147870571`,
  and `mdot_1174r`
  `form_responses/7a8f2c49-0c4f-4b7d-9ba3-4afb81f2da66`.
- S10 ledger rows:
  `mdot_1126` `form_responses/99a2fb1c-38fe-4817-b01d-694d522ade7b`,
  `mdot_0582b` `form_responses/5aed14a2-273d-4e7f-b512-c109b9a8d74f`,
  and `mdot_1174r`
  `form_responses/aac12ea1-6cee-476a-becc-717b99d92d9b`.

## P1 File, Storage, And Attachment Hardening

- [x] Extend object proof beyond photos/signatures to form exports under the
  current adapter contract: form-export families are local-only byte/history,
  with accepted local row/file/hash proof instead of remote object proof.
- [x] Extend object proof to entry documents.
- [x] Extend object proof to entry exports under the current adapter contract:
  entry exports are local-only history and included in local-only diagnostics.
- [x] Extend object proof to pay-app exports under the current adapter
  contract: pay-app export artifacts are local file/history rows with cleanup
  queue coverage.
- [x] Add unauthorized storage access denial proof for each applicable remote
  bucket/path family.
- [x] Add image fixture coverage for small, normal, large, and GPS-EXIF files.
- [x] Prove cross-device download/preview of uploaded objects.
- [x] Add `storage_cleanup_queue` assertions for delete/restore/purge paths.
- [x] Add durable attachment state assertions for upload, row upsert, local
  bookmark, stale-object cleanup, and cleanup retries.
- [x] Add crash/retry cases around upload, row upsert, bookmark, change-log
  processing, and storage delete failure.
  - [x] After upload before row upsert: phase-2 failure cleans up the newly
    uploaded object and rethrows the phase-2 error.
  - [x] After row upsert before bookmark: missing local bookmark target now
    fails phase 3 and records `local_bookmark_failed`.
  - [x] After bookmark before `change_log` processed: replay with
    `remote_path` already bookmarked and `change_log` still pending skips
    duplicate upload, creates no extra `change_log`, and drains after
    `markProcessed`.
  - [x] After storage delete failure before cleanup retry: stale object delete
    failure queues `storage_cleanup_queue` and records durable cleanup state.
- [x] Complete PowerSync attachment-helper reuse triage before implementing new
  attachment queue primitives.

Accepted local and device hygiene evidence:

- File-backed inventory: photos `entry-photos`, signatures `signatures`,
  documents `entry-documents`, entry exports `entry-exports`, form exports
  `form-exports`, export artifacts `export-artifacts`, and pay-application
  artifact references.
- `dart analyze lib/features/sync/engine/file_sync_three_phase_workflow.dart test/features/sync/engine/file_sync_handler_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 18 tests, including small, normal, large, and GPS-EXIF JPEG upload
  fixtures.
- `dart analyze lib/shared/datasources/generic_local_datasource.dart test/features/pay_applications/data/datasources/local/export_artifact_local_datasource_test.dart`
  passed with no issues.
- `flutter test test/features/pay_applications/data/datasources/local/export_artifact_local_datasource_test.dart -r expanded`
  passed 4 tests covering local path caching, soft-delete cleanup queueing,
  restore cleanup cancellation, and purge cleanup queueing.
- S21 driver hygiene after the slice: ready on `/sync/dashboard`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.
- S10 driver hygiene after the slice: ready on `/sync/dashboard`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.

## Immediate Slice K - Entry Document Live Storage Proof

- [x] Resume from the failed S21 entry-document object proof and inspect the
  retained diagnostic artifact.
- [x] Patch unauthorized-storage denial classification for private buckets that
  return HTTP 400 with `Bucket not found` when invalid credentials cannot see
  the bucket.
- [x] Add PowerShell harness coverage for the hidden-bucket denial response.
- [x] Run `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1`.
- [x] Confirm S21 preflight is clean before rerun:
  - `/driver/ready` ready on `/sync/dashboard`;
  - `/driver/change-log` empty with `unprocessedCount=0`,
    `blockedCount=0`, `maxRetryCount=0`;
  - `/driver/sync-status` idle with `pendingCount=0`,
    `blockedCount=0`, `unprocessedCount=0`.
- [x] Rerun S21 `documents-only` through the refactored flow and UI-triggered
  Sync Dashboard sync.
- [x] Accept only if the artifact proves local document row creation,
  pre-sync `change_log`, post-sync remote row, authorized storage bytes/hash,
  unauthorized denial for the same bucket/path, ledger-owned cleanup,
  storage delete/absence, final queue drain, `runtimeErrors=0`,
  `loggingGaps=0`, and `directDriverSyncEndpointUsed=false`.

Accepted evidence:

- Diagnostic first run:
  `20260418-s21-documents-entry-object-proof-initial` failed only because the
  denial classifier did not yet accept Supabase's private-bucket HTTP 400
  `Bucket not found` shape. The same run proved document row sync,
  authorized storage bytes, cleanup sync, storage delete/absence, and clean
  queue/runtime/direct-sync gates.
- Accepted rerun:
  `20260418-s21-documents-entry-object-proof-after-denial-classifier` passed
  with `queueDrainResult=drained`, `failedActorRounds=0`, `runtimeErrors=0`,
  `loggingGaps=0`, `blockedRowCount=0`, `unprocessedRowCount=0`,
  `maxRetryCount=0`, and `directDriverSyncEndpointUsed=false`.
- Accepted row/object proof:
  `documents/b4efc514-b14f-41e4-a257-b5ef0989ed5a`,
  remote path
  `docs/26fe92cd-7044-4412-9a09-5c5f49a292f9/f14d87c1-d870-444e-ba2b-bca5762aa485/enterprise_soak_doc_S21_round_1_214458.pdf`,
  bucket `entry-documents`, 48 bytes, SHA-256
  `d7aacd14db7ca489d86ca71c834ac5513f54cbfbab168d7929c086b6a7e61dc6`,
  authorized storage HTTP 200.
- Unauthorized proof for that same bucket/path passed with HTTP 400
  `{"statusCode":"404","error":"Bucket not found","message":"Bucket not found"}`.
- Ledger cleanup passed with UI-triggered cleanup sync, storage delete passed,
  and storage absence proof passed.

## Immediate Slice L - Remote Object Denial And Cross-Device Download

- [x] Run S21 `photo-only` after wiring unauthorized storage denial proof.
- [x] Run S21 `mdot1126-signature-only` after wiring unauthorized storage
  denial proof.
- [x] Restore S21/S10 driver reachability after device rebuilds changed ADB
  forwards.
- [x] Drain S10 residual signature cleanup rows through UI-triggered
  `sync-only` before cross-device proof.
- [x] Add `documents-cross-device-only` as a refactored flow.
- [x] Wire `documents-cross-device-only` through the lab entrypoint,
  dispatcher, module loader, concurrent soak entrypoint, and harness tests.
- [x] Run `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` after the
  new flow wiring.
- [x] Rebuild/restart S10 with document download/cache code and restore S21.
- [x] Confirm S21 and S10 preflight queues are clean.
- [x] Run S21-to-S10 `documents-cross-device-only` and accept only with:
  source UI-created document, source UI-triggered sync, remote row/object
  proof, unauthorized denial, receiver UI-triggered pull, receiver document
  tile tap, receiver local file hash matching storage hash, source
  ledger-owned cleanup, receiver cleanup pull, final clean queues, zero
  runtime/logging gaps, and `directDriverSyncEndpointUsed=false`.

Accepted evidence:

- S21 photo denial proof:
  `20260418-s21-photo-storage-denial-proof` passed with
  `photos/799779ce-b41f-4ea0-bea2-f92e72bc14ed`, bucket `entry-photos`,
  remote path
  `entries/26fe92cd-7044-4412-9a09-5c5f49a292f9/f14d87c1-d870-444e-ba2b-bca5762aa485/enterprise_soak_S21_round_1_214730.jpg`,
  68 bytes, SHA-256
  `1dae93d61eceabd7ce356b2be0acf0d2b813bf595f5cbae775a88582fd4ad278`,
  and unauthorized HTTP 400 `Bucket not found` denial.
- S21 signature denial proof:
  `20260418-s21-mdot1126-signature-storage-denial-proof` passed with
  `signature_files/a5d373fd-4096-4ea5-8406-476db56196f0`, bucket
  `signatures`, remote path
  `signatures/26fe92cd-7044-4412-9a09-5c5f49a292f9/75ae3283-d4b2-4035-ba2f-7b4adb018199/a5d373fd-4096-4ea5-8406-476db56196f0.png`,
  5193 bytes, SHA-256
  `95c0ab2bfc32859719ec0de97ebaf4710e2dfb605fc5751cd54e90a398912755`,
  and unauthorized HTTP 400 `Bucket not found` denial.
- S10 residue drain:
  `20260418-s10-post-signature-denial-residue-sync-only` passed through the
  Sync Dashboard with final clean queue after S10 observed the signature
  cleanup rows.
- S21-to-S10 cross-device download proof:
  `20260418-s21-s10-documents-cross-device-download-proof` passed with
  `queueDrainResult=drained`, `failedActorRounds=0`, `runtimeErrors=0`,
  `loggingGaps=0`, `blockedRowCount=0`, `unprocessedRowCount=0`,
  `maxRetryCount=0`, `directDriverSyncEndpointUsed=false`, and final clean
  queues on both actors.
- Cross-device document:
  `documents/b8f80b06-9e14-4ff4-9e38-0be0e7cbf8f1`, bucket
  `entry-documents`, remote path
  `docs/26fe92cd-7044-4412-9a09-5c5f49a292f9/f14d87c1-d870-444e-ba2b-bca5762aa485/enterprise_soak_cross_device_doc_S21_to_S10_round_1_215611.pdf`,
  48 bytes, SHA-256
  `d7aacd14db7ca489d86ca71c834ac5513f54cbfbab168d7929c086b6a7e61dc6`.
- Receiver proof:
  S10 pulled the row via UI sync, tapped
  `document_tile_b8f80b06-9e14-4ff4-9e38-0be0e7cbf8f1`, cached a local file,
  and `/driver/local-file-head` returned `exists=true`, 48 bytes, and the same
  SHA-256 as the source storage proof. S10 then pulled the source cleanup and
  observed `deleted_at`.

## P1 Role, Scope, Account, And RLS Sweeps

- [x] Inventory real account fixtures and UI keys for admin, inspector,
  engineer, and office technician.
  - [x] User confirmed four real role accounts are now saved in
    `.env.secret`; do not print or persist credential values.
  - [x] Verified live S21 actor context as a real approved admin session.
  - [x] Verified live S10 actor context as a real approved inspector session.
  - [x] Verified engineer and office-technician sessions through real
    secret-backed UI sign-in on S21/S10.
- [ ] Run role sweeps with real sessions and no `MOCK_AUTH`.
  - [x] Run the admin/inspector subset through the refactored
    `role-sweep-only` flow with UI-triggered Sync Dashboard sync and
    `directDriverSyncEndpointUsed=false`.
  - [x] Run engineer subset with a verified real session.
  - [x] Run office-technician subset with a verified real session.
  - [x] Run the current physical inspector/office-technician subset on S10/S21
    with strict provider/local project equality:
    `20260419-s10-s21-role-sweep-inspector-office-draft-dispose-cleanup`.
- [ ] Prove denied routes and hidden controls for project management, PDF
  import, pay-app management, trash, admin, export/download, and previews.
  - [x] Admin/inspector subset proved admin dashboard/trash/project-create
    allow/deny behavior plus inspector denial for project create, pay-app
    detail, and PDF import.
  - [x] Engineer and office-technician subset proved admin/trash denial and
    project-create allowed behavior under real sessions.
  - [x] Current S10/S21 physical subset proved inspector project-new denial,
    project-create hidden, pay-app detail denial, PDF import denial, and
    office-technician project-new/project-create visibility without provider
    or local active-project bleed-through.
  - [ ] Extend remaining export/download/storage-preview role checks if the
    next role matrix exposes role-specific controls beyond the current route
    gates.
- [x] Same-device account switching regression coverage.
  - [x] Accepted setup transition run to place S21 on admin and S10 on
    inspector.
  - [x] Accepted S21 same-device admin to inspector transition.
  - [x] Accepted S10 same-device inspector to office-technician transition.
  - Same-device switching is useful regression evidence, but the remaining
    security gate is separate-account/device role isolation plus
    grant/revocation proof.
- [x] Defer live revoked/deactivated account mutation out of the beta
  hardening lane per user direction. Do not run admin deactivation/revocation
  as a required gate for this one-company internal beta.
- [x] Prove providers, selected project, realtime channels, local scope cache,
  Sync Dashboard state, screenshots, and logs do not leak stale account data.
  - [x] `20260418-s21-s10-role-account-switch-required-transitions-stale-scope`
    proved final user id, role, selected project cleared, dirty scopes cleared,
    Sync Dashboard route, transport company, active realtime channel, drained
    queue, screenshots/logs, zero runtime/logging gaps, and
    `directDriverSyncEndpointUsed=false` for S21 and S10 after account changes.
  - [x] `20260419-s10-s21-role-sweep-inspector-office-draft-dispose-cleanup`
    proved provider/local project equality at the role-sweep acceptance point
    after a previous strict sentinel failure exposed a provider-only blank
    draft from `/project/new`.
- [ ] Future non-beta lane: treat grants and revocations as sync changes
  without making live admin deactivation a blocker for the current role/seam
  and sync-soak work.

## Immediate Slice N - Admin/Inspector Role Sweep

- [x] Rechecked worktree and P1 role/scope checklist before continuing.
- [x] Verified S21 on port 4948 is logged in as a real admin session with
  clean queue state.
- [x] Verified S10 on port 4949 is logged in as a real inspector session with
  clean queue state.
- [x] Hardened the actor-session sentinel to assert the nested real provider
  role from `/diagnostics/actor_context`.
- [x] Added and wired `role-sweep-only` through the refactored soak module
  loader, dispatcher, lab entrypoint, concurrent entrypoint, and harness tests.
- [x] Added route/control assertions for admin and inspector permission
  boundaries.
- [x] Fixed the S10 settings semantics runtime assertion by replacing theme
  `RadioListTile` options with stable `ListTile` plus trailing `Radio`
  controls.
- [x] Hardened Sync Dashboard UI tap retry for real UI-triggered sync without
  using `/driver/sync`.
- [x] Ran local gates:
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1`;
  - `dart analyze lib/features/settings/presentation/widgets/theme_section.dart test/features/settings/presentation/screens/settings_screen_test.dart`;
  - `flutter test test/features/settings/presentation/screens/settings_screen_test.dart -r expanded`;
  - `git diff --check`.
- [x] Rebuilt/restarted the S10 Android driver app and restored the S21 ADB
  forward after the rebuild changed device forwards.
- [x] Accepted combined S21/S10 role sweep artifact:
  `20260418-s21-s10-role-sweep-admin-inspector-after-sync-tap-retry`.

Accepted evidence:

- S21 resolved `expectedRole=admin`, `resolvedRole=admin`,
  `isAdmin=true`, `canCreateProject=true`, and `canManageProjects=true`.
- S10 resolved `expectedRole=inspector`, `resolvedRole=inspector`,
  `isAdmin=false`, `canCreateProject=false`, and
  `canManageProjects=false`.
- The accepted run passed with `failedActorRounds=0`, `runtimeErrors=0`,
  `loggingGaps=0`, `queueDrainResult=drained`, `blockedRowCount=0`,
  `unprocessedRowCount=0`, `maxRetryCount=0`, 16 screenshots, 18 log
  captures, UI-triggered sync, and `directDriverSyncEndpointUsed=false`.

Still open for this P1 lane:

- Add same-device account switching coverage.
- Prove stale provider/project/realtime/local-scope eviction across account
  changes.
- Treat grant and revocation updates as sync changes with device evidence.

## Immediate Slice O - Engineer/Office Account Switch Role Sweep

- [x] Added secret-safe role account parsing for `.env.secret`:
  repeated `EMAIL`/`PASSWORD` pairs are parsed without logging values, inline
  role notes after email tokens are stripped, and accounts are verified
  through Supabase anon auth plus the account's own user-profile read.
- [x] Added `role-account-switch-only` as a refactored flow that uses real UI
  sign-out/sign-in, first-run consent acceptance, actor-context role proof,
  role sweep, and UI-triggered Sync Dashboard sync.
- [x] Redacted `/driver/text` request bodies in driver-client failure output
  so password entry failures cannot persist credentials.
- [x] Fixed the compact S21 sign-out dialog overflow by wrapping dialog
  action buttons instead of forcing them into one row.
- [x] Ran local gates:
  - `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1`;
  - `dart analyze lib/features/settings/presentation/widgets/sign_out_dialog.dart lib/features/settings/presentation/widgets/theme_section.dart test/features/settings/presentation/screens/settings_screen_test.dart`;
  - `flutter test test/features/settings/presentation/screens/settings_screen_test.dart -r expanded`;
  - `git diff --check`.
- [x] Rebuilt/restarted S21 Android driver app with the sign-out dialog fix
  and restored the S10 ADB forward.
- [x] Accepted S21/S10 engineer/office role-account switch artifact:
  `20260418-s21-s10-role-account-switch-engineer-office-after-signout-wrap`.

Accepted evidence:

- S21 resolved `targetRole=engineer`, `resolvedRole=engineer`,
  `isEngineer=true`, `canCreateProject=true`, and `canManageProjects=true`.
- S10 resolved `targetRole=office_technician`,
  `resolvedRole=office_technician`, `isOfficeTechnician=true`,
  `canCreateProject=true`, and `canManageProjects=true`.
- Both account summaries redacted email/password values and retained only
  role, status, user id, company id, and source line metadata.
- The accepted run passed with `failedActorRounds=0`, `runtimeErrors=0`,
  `loggingGaps=0`, `queueDrainResult=drained`, `blockedRowCount=0`,
  `unprocessedRowCount=0`, `maxRetryCount=0`, 14 screenshots, 20 log
  captures, UI-triggered sync, and `directDriverSyncEndpointUsed=false`.

Still open for this P1 lane:

- Prove stale provider/project/realtime/local-scope eviction across account
  changes with dedicated before/after assertions.
- Treat grant and revocation updates as sync changes with device evidence.

## Immediate Slice P - Required Same-Device Role Transitions

- [x] Ran accepted setup transition:
  `20260418-s21-s10-role-account-switch-admin-inspector-setup`.
- [x] Ran accepted required transition proof:
  `20260418-s21-s10-role-account-switch-required-transitions`.
- [x] S21 proved before role `admin` and after role `inspector` on the same
  physical device/session store.
- [x] S10 proved before role `inspector` and after role `office_technician`
  on the same physical device/session store.
- [x] Both devices ran the role route/control sweep after the switch.
- [x] Both devices ended through Sync Dashboard UI sync with
  `directDriverSyncEndpointUsed=false`.

Accepted evidence:

- Setup run passed with `failedActorRounds=0`, `runtimeErrors=0`,
  `loggingGaps=0`, `queueDrainResult=drained`, and
  `directDriverSyncEndpointUsed=false`.
- Required transition run passed with `failedActorRounds=0`,
  `runtimeErrors=0`, `loggingGaps=0`, `queueDrainResult=drained`,
  `blockedRowCount=0`, `unprocessedRowCount=0`, `maxRetryCount=0`, 16
  screenshots, 22 log captures, UI-triggered sync, and
  `directDriverSyncEndpointUsed=false`.
- S21 before context: `role=admin`, `currentUserId` ending in
  `88054934-9cc5-4af3-b1c6-38f262a7da23`, `canCreateProject=true`,
  `canManageProjects=true`.
- S21 after context: `role=inspector`, `currentUserId` ending in
  `6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`, `canCreateProject=false`,
  `canManageProjects=false`, project create control hidden, project-new
  denied, pay-app detail denied, and PDF import denied.
- S10 before context: `role=inspector`, `currentUserId` ending in
  `6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`, `canCreateProject=false`,
  `canManageProjects=false`.
- S10 after context: `role=office_technician`, `currentUserId` ending in
  `d1ca900e-d880-4915-9950-e29ba180b028`, `canCreateProject=true`,
  `canManageProjects=true`, and project create control visible.

Still open for this P1 lane:

- Treat grant and revocation updates as sync changes with device evidence.
- Add broader separate-device role isolation and RLS denial proof beyond the
  already-accepted same-device regression checks.

## Immediate Slice Q - Stale Account/Scope Proof Accepted

- [x] Inspected latest stale-scope summary:
  `20260418-s21-s10-role-account-switch-required-transitions-stale-scope`.
- [x] S21 proof: before user was admin
  `88054934-9cc5-4af3-b1c6-38f262a7da23`; final user was inspector
  `6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`; final route
  `/sync/dashboard`; selected project `null`; dirty scope count `0`;
  transport company `26fe92cd-7044-4412-9a09-5c5f49a292f9`; realtime active.
- [x] S10 proof: before user was inspector
  `6fc4e6cb-9b63-43d0-ab11-32dca39eb6ff`; final user was
  office technician `d1ca900e-d880-4915-9950-e29ba180b028`; final route
  `/sync/dashboard`; selected project `null`; dirty scope count `0`;
  transport company `26fe92cd-7044-4412-9a09-5c5f49a292f9`; realtime active.
- [x] Summary gates: `failedActorRounds=0`, `runtimeErrors=0`,
  `loggingGaps=0`, `queueDrainResult=drained`, `blockedRowCount=0`,
  `unprocessedRowCount=0`, `maxRetryCount=0`, 16 screenshots, 22 log
  captures, UI-triggered sync, and `directDriverSyncEndpointUsed=false`.
- [x] Updated this task list and the controlling todo so same-device
  switching remains recorded as a regression, while the next security work
  targets separate-account/device isolation, RLS denial, and grant/revocation
  sync-change proof.

## Immediate Slice R - Real Role/RLS Denial Proof

- [x] Implement a secret-safe role/RLS admin-action harness helper that uses
  real Supabase anon sessions and never service-role credentials for denial
  checks.
- [x] Prove non-admin real accounts cannot call admin-only role/status RPCs
  without mutating account status:
  `.claude/test-results/2026-04-19/rls-denial-probes-20260419T0935Z/summary.json`.
- [x] Remove live account deactivation/revocation from this beta readiness
  lane per user direction. Do not run admin deactivation as part of the
  current role-seam hardening.
- [ ] Add any remaining non-destructive wrong-owner/wrong-project write probes
  that can be proven to fail before mutation.
- [x] Record exact artifacts and update the implementation log after the
  accepted denial run.

## Immediate Slice M - Role/RLS Diagnostics And Fixture Inventory

- [x] Inspect existing role-policy docs, harness fixtures, auth keys, route
  contracts, and current device actor context.
- [x] Add resolved role, membership status, company id, and permission
  booleans to `/diagnostics/actor_context` so live role sweeps can prove the
  real session state instead of trusting actor labels.
- [x] Run focused local gates:
  - `dart format lib/core/driver/driver_diagnostics_handler.dart`;
  - `dart analyze lib/core/driver/driver_diagnostics_handler.dart test/core/driver/driver_diagnostics_routes_test.dart`;
  - `flutter test test/core/driver/driver_diagnostics_routes_test.dart -r expanded`.
- [x] Rebuild/restart S21 and S10 so the running driver apps expose the new
  actor-context fields.
- [x] Probe live S21 and S10 actor context and queues after rebuild.
- [x] Add/provision real device credentials or staging harness personas for
  admin, engineer, inspector, and office technician before claiming role
  sweeps. User confirmed four real role accounts are saved in `.env.secret`;
  values must remain out of logs and docs.

Current inventory facts:

- Existing local harness fixture metadata defines admin, two engineers, one
  office technician, eight inspectors, and 15 project ids in
  `integration_test/sync/harness/harness_fixture_cursor.dart`.
- Existing auth testing keys cover login, register, OTP, profile setup,
  company setup, pending approval, and account status screens.
- Existing screen contracts expose the role-sensitive surfaces that must be
  swept: project create/remove/delete, PDF import preview, pay-app
  detail/compare, trash, admin dashboard, export/download, and document/photo
  previews.
- `.env.secret` now has four real role accounts according to the user. Treat
  it as secret material: inspect key names only when needed and never print
  values into artifacts.
- Live S21 now resolves as a real approved admin session for company
  `26fe92cd-7044-4412-9a09-5c5f49a292f9`.
- Live S10 now resolves as a real approved inspector session for company
  `26fe92cd-7044-4412-9a09-5c5f49a292f9`.
- S21 and S10 post-rebuild queues are clean: `/driver/change-log` returned
  `count=0`, `unprocessedCount=0`, `blockedCount=0`, `maxRetryCount=0` on
  both devices.

## P1 Sync Engine Correctness Hardening

- [x] Replace offset/range pull pagination with stable keyset/checkpoint
  pagination.
- [x] Add equal-`updated_at`, concurrent insert, long-offline pull, and partial
  page restart tests.
  - [x] Equal `updated_at` rows continue across page boundaries by `id`.
  - [x] Remote inserts during a pull are visible after the keyset boundary.
  - [x] Long-offline pull drains many keyset pages.
  - [x] Restart resumes after a stored full-page keyset checkpoint.
  - [x] Restart replays a partial final page after an apply-time crash.
- [x] Add per-scope reconciliation probes for required sync tables.
  - [x] Local driver snapshot endpoint implemented and device-proven on
    S21/S10.
  - [x] Remote driver snapshot endpoint implemented with real device-session
    Supabase reads.
  - [x] Sync-soak harness comparison primitive implemented with count/hash
    mismatch classification.
  - [x] Post-sync flow artifact wiring and remote comparison acceptance gate
    proven on S21 with 13 table specs and zero reconciliation failures.
- [x] Add write-checkpoint semantics: queue drain, remote proof, next-pull
  proof, and final local proof.
  - [x] Queue-drain proof blocks `last_sync_time` advancement when pending
    local changes remain after sync.
  - [x] Remote write proof now verifies each per-record acknowledged write.
  - [x] Follow-up pull path proof blocks freshness when a cycle pushed local
    writes but skipped pull.
  - [x] Final local proof verifies per-record visibility through the
    server/pull path.
- [x] Keep sync freshness false until the local write is visible through the
  server/pull path.
  - [x] Freshness is now blocked when the final queue is not drained.
  - [x] Freshness is now blocked when pushed writes did not get a follow-up
    pull path.
  - [x] Per-record server/pull visibility proof is implemented and covered.
- [x] Prove realtime hints are only hints with missed, delayed, duplicate, and
  out-of-order hint cases plus fallback polling.
- [x] Add idempotent replay tests for duplicate pushes, duplicate pulls,
  duplicate applies, duplicate deletes, absent rows, storage 409s, row upsert
  replay, and bookmark replay.
  - [x] Duplicate pull page replay and duplicate row apply are covered in
    `pull_handler_test.dart`; replayed pages leave a single row per id and
    produce `pulled=0` when `updated_at` matches.
  - [x] Already-absent remote row replay is verified through
    `sync_engine_delete_test.dart` and `supabase_sync_contract_test.dart`.
  - [x] Storage 409/already-exists replay is verified through
    `file_sync_handler_test.dart`.
  - [x] Remaining replay classes have explicit indexed coverage in
    `push_handler_test.dart`, `file_sync_handler_test.dart`, and
    `local_sync_store_contract_test.dart`.
- [x] Add crash/restart tests around `pulling=1`, sync locks, cursors,
  conflict re-push, auth refresh, and background retry scheduling.
- [x] Split conflict strategy by domain.
- [x] Fix misleading file-sync phase logging.

## Immediate Slice D - Idempotent Replay Matrix Completion

- [x] Resume from the accepted S21 active-row reconciliation gate and refresh
  the working tree before continuing.
- [x] Inspect existing push, soft-delete, upload, row-upsert, and bookmark
  replay tests before adding new coverage.
- [x] Add or verify explicit replay coverage for duplicate local push after
  remote upsert succeeds.
- [x] Add or verify explicit replay coverage for duplicate soft-delete push.
- [x] Add or verify explicit replay coverage for duplicate upload.
- [x] Add or verify explicit replay coverage for row upsert replay.
- [x] Add or verify explicit replay coverage for bookmark replay.
- [x] Run focused `dart analyze` for touched sync/file tests and helpers.
- [x] Run focused `flutter test` for the replay matrix files.
- [x] Run `git diff --check`.
- [x] Probe S21 and S10 driver hygiene after local gates if the running
  devices are reachable.
- [x] Update the controlling todo and implementation log only after evidence
  exists.

Accepted local evidence:

- Added replay matrix coverage in:
  - `push_handler_test.dart` for duplicate local push after remote upsert and
    duplicate soft-delete push when the remote row is already gone.
  - `file_sync_handler_test.dart` for duplicate upload replay where storage
    already has the object and row-upsert replay with an existing
    `remote_path`.
  - `local_sync_store_contract_test.dart` for idempotent bookmark replay with
    trigger suppression and no `change_log` pollution.
- `dart analyze test/features/sync/engine/push_handler_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/sync_engine_delete_test.dart test/features/sync/engine/supabase_sync_contract_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/push_handler_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/sync_engine_delete_test.dart test/features/sync/engine/supabase_sync_contract_test.dart -r expanded`
  passed 118 tests.
- `git diff --check` passed with line-ending warnings only.
- S21 driver hygiene after the slice: `/driver/ready` ready on
  `/sync/dashboard`, empty `change_log`, `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`, `isSyncing=false`.
- S10 driver hygiene after the slice: `/driver/ready` ready on `/projects`,
  empty `change_log`, `pendingCount=0`, `blockedCount=0`,
  `unprocessedCount=0`, `isSyncing=false`.

## Immediate Slice E - Write-Checkpoint Freshness Guard

- [x] Inspect current `last_sync_time` / freshness code path.
- [x] Persist an engine-level guard that blocks fresh sync metadata when the
  final local queue is not drained.
- [x] Persist an engine-level guard that blocks fresh sync metadata when local
  writes were pushed but no follow-up pull path ran in the same cycle.
- [x] Add focused engine status tests for queue-drain proof failure.
- [x] Add focused engine status tests for pushed-without-pull freshness
  failure.
- [x] Run focused `dart analyze` for the changed engine/test files.
- [x] Run focused `flutter test` for the engine freshness tests.
- [x] Run `git diff --check`.
- [x] Probe S21 and S10 driver hygiene after local gates if reachable.
- [x] Update the controlling todo and implementation log only after evidence
  exists.

Accepted local evidence:

- `SyncEngine` now verifies freshness before writing `last_sync_time`:
  final pending upload/change count must be zero, and any cycle with pushed
  writes must have attempted a pull path.
- `sync_engine_status_test.dart` now covers queue residue after an otherwise
  clean push/pull and pushed writes during strict quick sync with no pull.
- `dart analyze lib/features/sync/engine/sync_engine.dart lib/features/sync/engine/sync_run_lifecycle.dart test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/sync_engine_mode_plumbing_test.dart test/features/sync/engine/sync_engine_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/sync_engine_mode_plumbing_test.dart -r expanded`
  passed 11 tests.
- `git diff --check` passed with line-ending warnings only.
- S21 driver hygiene after the slice: ready on `/sync/dashboard`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.
- S10 driver hygiene after the slice: ready on `/projects`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.

## Immediate Slice F - Per-Record Write Checkpoint Proof

- [x] Re-read the controlling todo, implementation log, live task list, sync
  rules, and working tree before continuing.
- [x] Carry per-record acknowledged write identities out of the push path.
- [x] Preserve aggregate push semantics while excluding skipped/LWW-only work
  from remote-write proof.
- [x] Add a write-checkpoint verifier that reads the app's real Supabase
  boundary for each acknowledged row before freshness metadata advances.
- [x] Verify final local visibility after the follow-up pull path for each
  acknowledged row.
- [x] Fail freshness instead of writing `last_sync_time` when remote proof is
  missing, stale, deleted unexpectedly, or locally invisible after pull.
- [x] Add focused push/engine tests for acknowledged-write propagation,
  remote proof failure, local visibility failure, and successful proof.
- [x] Run focused `dart analyze` for changed sync engine files and tests.
- [x] Run focused `flutter test` for changed sync engine tests.
- [x] Run `git diff --check`.
- [x] Probe S21 and S10 driver hygiene after local gates if reachable.
- [x] Update the controlling todo and implementation log only after evidence
  exists.

Accepted local and device hygiene evidence:

- `PushResult` and `SyncEngineResult` now carry `acknowledgedWrites` for
  server-acknowledged upserts, insert-only rows, file metadata upserts, and
  soft deletes.
- `RemoteLocalWriteCheckpointVerifier` verifies each acknowledged write
  through `SupabaseSync.fetchRecord()` and `LocalSyncStore.readLocalRecord()`
  after the follow-up pull path before `last_sync_time` can advance.
- Skipped adapter/out-of-scope/LWW-only work preserves aggregate push counts
  but does not enter the remote-write proof set.
- Focused local gates passed:
  - `dart analyze lib/features/sync/engine/sync_write_checkpoint_proof.dart lib/features/sync/engine/sync_engine_result.dart lib/features/sync/engine/push_execution_router.dart lib/features/sync/engine/push_handler.dart lib/features/sync/engine/sync_engine.dart lib/features/sync/application/sync_engine_factory.dart test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/push_handler_test.dart test/features/sync/engine/sync_write_checkpoint_proof_test.dart test/features/sync/application/sync_coordinator_test.dart`
  - `flutter test test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/push_handler_test.dart test/features/sync/engine/sync_write_checkpoint_proof_test.dart test/features/sync/application/sync_coordinator_test.dart -r expanded`
    passed 41 tests.
  - `git diff --check` passed with line-ending warnings only.
- S21 driver hygiene after the slice: ready on `/sync/dashboard`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.
- S10 driver hygiene after the slice: ready on `/projects`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.

## Immediate Slice G - Crash/Restart Coverage

- [x] Resume after per-record write-checkpoint proof and refresh the open
  sync-engine correctness checklist.
- [x] Inspect existing coverage for `sync_control.pulling = '1'`, held
  `sync_lock`, cursor restart, manual conflict re-push, auth refresh, and
  background retry scheduling.
- [x] Add or verify focused tests for stale `pulling=1` recovery.
- [x] Add or verify focused tests for held `sync_lock` behavior.
- [x] Add or verify focused tests for cursor update/restart behavior.
- [x] Add or verify focused tests for manual conflict re-push insertion after
  local-wins conflict.
- [x] Add or verify focused tests for auth refresh retry behavior.
- [x] Add or verify focused tests for background retry scheduling.
- [x] Run focused `dart analyze` for changed sync-engine files and tests.
- [x] Run focused `flutter test` for changed sync-engine tests.
- [x] Run `git diff --check`.
- [x] Probe S21 and S10 driver hygiene after local gates if reachable.
- [x] Update the controlling todo and implementation log only after evidence
  exists.

Accepted local and device hygiene evidence:

- Existing `local_sync_store_contract_test.dart` verifies stale
  `sync_control.pulling = '1'` reset through `resetPullingFlag()`.
- Existing `sync_run_state_store_test.dart` verifies crash recovery clears both
  advisory `sync_lock` and stale `pulling=1`.
- Existing `sync_mutex_test.dart` verifies held-lock rejection, stale lock
  expiry, heartbeat expiry, clear-any-lock, release, and reacquire behavior.
- Existing `pull_handler_test.dart` verifies keyset cursor advancement,
  page-two failure cursor preservation, stored full-page checkpoint restart,
  and partial-final-page replay after apply-time crash.
- New `pull_handler_test.dart` coverage verifies a local-wins pull conflict
  inserts an unprocessed manual `change_log` update for re-push.
- Existing `push_handler_test.dart` verifies 401 auth refresh success retries
  the push and emits `SyncAuthRefreshed`; refresh failure leaves the row
  pending.
- Existing `sync_background_retry_scheduler_test.dart` verifies retry
  scheduling, cancel, no-session skip, DNS deferral/reschedule, retryable
  result reschedule, and permanent-error stop.
- Focused local gates passed:
  - `dart analyze test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/sync_run_state_store_test.dart test/features/sync/engine/sync_mutex_test.dart test/features/sync/application/sync_background_retry_scheduler_test.dart test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/push_handler_test.dart test/features/sync/engine/sync_write_checkpoint_proof_test.dart lib/features/sync/engine/pull_handler.dart lib/features/sync/application/sync_background_retry_scheduler.dart`
  - `flutter test test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/sync_run_state_store_test.dart test/features/sync/engine/sync_mutex_test.dart test/features/sync/application/sync_background_retry_scheduler_test.dart test/features/sync/engine/sync_engine_status_test.dart test/features/sync/engine/push_handler_test.dart test/features/sync/engine/sync_write_checkpoint_proof_test.dart -r expanded`
    passed 117 tests.
  - `git diff --check` passed with line-ending warnings only.
- S21 driver hygiene after the slice: ready on `/sync/dashboard`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.
- S10 driver hygiene after the slice: ready on `/projects`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.

## Immediate Slice H - Realtime Hints Are Only Hints

- [x] Resume after crash/restart coverage and refresh the open realtime-hint
  checklist.
- [x] Inspect realtime hint handler, transport controller, dirty-scope tracker,
  fallback polling, and existing tests.
- [x] Add or verify missed-hint fallback polling convergence coverage.
- [x] Add or verify delayed-hint behavior coverage.
- [x] Add or verify duplicate-hint idempotence coverage.
- [x] Add or verify out-of-order hint behavior coverage.
- [x] Add or verify role-revocation/no-unauthorized-project-flash coverage.
- [x] Run focused `dart analyze` for changed realtime/sync files and tests.
- [x] Run focused `flutter test` for changed realtime/sync tests.
- [x] Run `git diff --check`.
- [x] Probe S21 and S10 driver hygiene after local gates if reachable.
- [x] Update the controlling todo and implementation log only after evidence
  exists.

Accepted local and device hygiene evidence:

- `realtime_hint_handler_test.dart` now verifies duplicate realtime broadcasts
  dedupe to one dirty scope, keep the quick-sync throttle, and do not drop the
  dirty marker.
- `realtime_hint_handler_test.dart` now verifies out-of-order realtime
  broadcasts retain both dirty scopes for the next quick pull.
- `realtime_hint_handler_test.dart` verifies failed realtime registration
  starts fallback polling quick syncs, covering missed realtime hints.
- Existing queued-follow-up coverage verifies delayed hints arriving mid-sync
  run after the in-flight sync completes.
- Existing FCM tests verify throttled foreground hints still mark dirty scopes,
  background hint persistence, background queue bounds, cross-company
  rejection, and cooldown behavior.
- Existing scope revocation cleaner coverage verifies revoked project scope is
  fully evicted locally, including shell rows and local files; cross-company
  realtime/FCM hints are rejected before dirtying scopes or syncing.
- Focused local gates passed:
  - `dart analyze test/features/sync/application/realtime_hint_handler_test.dart test/features/sync/application/fcm_handler_test.dart test/features/sync/application/sync_lifecycle_manager_test.dart test/features/sync/engine/dirty_scope_tracker_test.dart test/features/sync/engine/pull_scope_state_test.dart test/features/sync/engine/scope_revocation_cleaner_test.dart lib/features/sync/application/realtime_hint_handler.dart lib/features/sync/application/realtime_hint_transport_controller.dart lib/features/sync/engine/dirty_scope_tracker.dart`
  - `flutter test test/features/sync/application/realtime_hint_handler_test.dart test/features/sync/application/fcm_handler_test.dart test/features/sync/application/sync_lifecycle_manager_test.dart test/features/sync/engine/dirty_scope_tracker_test.dart test/features/sync/engine/pull_scope_state_test.dart test/features/sync/engine/scope_revocation_cleaner_test.dart -r expanded`
    passed 60 tests.
  - `git diff --check` passed with line-ending warnings only.
- S21 driver hygiene after the slice: ready on `/sync/dashboard`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.
- S10 driver hygiene after the slice: ready on `/projects`, empty
  `change_log`, `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.

## Immediate Slice I - Domain-Specific Conflict Strategy

- [x] Resume after realtime-hint proof and refresh the open conflict-policy
  checklist.
- [x] Inspect `ConflictResolver`, sync adapters, signed form responses,
  signature files, signature audit rows, quantities, and narrative fields.
- [x] Define which domains may use LWW and which require preservation or
  documented stronger behavior.
- [x] Add or verify focused tests for signatures and signature audit rows.
- [x] Add or verify focused tests for signed form responses.
- [x] Add or verify focused tests for quantities and narrative fields.
- [x] Run focused `dart analyze` for changed conflict/sync files and tests.
- [x] Run focused `flutter test` for changed conflict/sync tests.
- [x] Run `git diff --check`.
- [x] Probe S21 and S10 driver hygiene after local gates if reachable.
- [x] Update the controlling todo and implementation log only after evidence
  exists.

Slice I accepted behavior:

- Default product records still use deterministic LWW.
- Sparse push-skip audit rows still use LWW, so `LwwChecker` logging does not
  falsely report local preservation when the remote row only carries a server
  timestamp.
- Signed local `form_responses` are preserved over newer unsigned pulled rows.
- `signature_files` preserve local immutable fingerprint metadata when a full
  pulled row disagrees, while still accepting newer `remote_path` updates when
  the immutable fingerprint matches.
- `signature_audit_log` preserves the local immutable audit chain when a full
  pulled row disagrees.
- `entry_quantities` and narrative records remain LWW, with discarded
  quantity, notes, and narrative text retained in changed-column conflict-log
  diffs.

Slice I evidence:

- `dart analyze lib/features/sync/engine/conflict_resolver.dart test/features/sync/engine/conflict_resolver_domain_policy_test.dart test/features/sync/engine/conflict_clock_skew_test.dart test/features/sync/property/sync_invariants_property_test.dart test/features/sync/engine/sync_engine_lww_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/conflict_resolver_domain_policy_test.dart test/features/sync/engine/conflict_clock_skew_test.dart test/features/sync/property/sync_invariants_property_test.dart test/features/sync/engine/sync_engine_lww_test.dart -r expanded`
  passed 24 tests.
- `git diff --check` passed with line-ending warnings only.
- S21 driver hygiene: ready on `/sync/dashboard`, empty `change_log`,
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.
- S10 driver hygiene: ready on `/projects`, empty `change_log`,
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.

## Immediate Slice J - File, Storage, And Attachment Hardening

- [x] Resume after conflict-policy proof and refresh the open
  file/storage/attachment checklist.
- [x] Inventory production file-backed families, storage buckets, local-only
  tables, cleanup queues, and existing proof helpers.
- [x] Verify or add tests that every file-backed row has a durable row/object
  consistency contract.
- [x] Verify or add tests for upload replay, metadata replay, storage 409, and
  missing-object recovery across photos, documents, signature files, and export
  artifacts.
- [x] Verify or add tests for orphan cleanup and stale local cache
  invalidation.
- [x] Decide whether local-only export artifact tables need clearer
  diagnostics or soak artifact fields before P1 closure.
- [x] Add durable file-sync phase state logging for upload start/success, row
  upsert success/failure, local bookmark success/failure, stale cleanup queued,
  and cleanup retry success/failure.
- [x] Add signatures bucket coverage to cleanup/orphan registries.
- [x] Run focused `dart analyze` for changed file/storage sync files and tests.
- [x] Run focused `flutter test` for changed file/storage sync tests.
- [x] Run `git diff --check`.
- [x] Probe S21 and S10 driver hygiene after local gates if reachable.
- [x] Update the controlling todo and implementation log only after evidence
  exists for the completed subitems.

Slice J partial evidence:

- `dart analyze lib/core/database/schema/sync_engine_tables.dart lib/core/database/database_bootstrap.dart lib/core/database/database_late_migration_steps.dart lib/core/database/database_service.dart lib/core/database/database_schema_metadata.dart lib/features/sync/application/sync_engine_factory.dart lib/features/sync/engine/file_sync_handler.dart lib/features/sync/engine/file_sync_state_store.dart lib/features/sync/engine/file_sync_three_phase_workflow.dart lib/features/sync/engine/storage_cleanup.dart lib/features/sync/engine/storage_cleanup_registry.dart lib/features/sync/engine/orphan_scanner.dart test/helpers/sync/sqlite_test_helper.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart -r expanded`
  passed 102 tests.
- `dart analyze lib/features/sync/engine/file_sync_three_phase_workflow.dart test/features/sync/engine/adapter_integration_test.dart lib/features/sync/engine/storage_cleanup_registry.dart`
  passed with no issues after widening storage path validation for nested
  artifact directories.
- `flutter test test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart -r expanded`
  passed 133 tests.
- `dart analyze test/features/sync/engine/file_sync_handler_test.dart` passed
  with no issues after adding the document/signature replay matrix.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 24 tests.
- `flutter test test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart -r expanded`
  passed 135 tests.
- `dart analyze lib/features/sync/engine/stale_file_cache_invalidator.dart test/features/sync/engine/stale_file_cache_invalidator_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/stale_file_cache_invalidator_test.dart -r expanded`
  passed 3 tests.
- Combined file/storage sweep with stale-cache coverage passed:
  `flutter test test/features/sync/engine/stale_file_cache_invalidator_test.dart test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart -r expanded`
  passed 138 tests.
- Reconciliation summary artifacts now write `storage-family-diagnostics.json`
  and summary fields that classify photos, signatures, and entry documents as
  remote-object proof families, while `entry_exports`, `form_exports`,
  `export_artifacts`, and pay-application exports are recorded as local-only
  byte/history families under the current adapter contract.
- Added `Assert-SoakStorageUnauthorizedDenied` plus harness classifier tests
  so the next live object proof can record unauthorized storage denial per
  bucket/path family.
- `pwsh -NoProfile -File tools/test-sync-soak-harness.ps1` passed 11 test
  files after the storage diagnostics and denial-proof helper changes.
- `dart analyze lib/features/sync/engine/local_record_store.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/file_sync_handler_test.dart`
  passed with no issues after tightening phase-3 bookmark semantics.
- `flutter test test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 58 tests, including missing-bookmark-target failure, durable
  `local_bookmark_failed` state logging, upload-before-upsert cleanup, and
  stale storage cleanup retry queueing.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart -r expanded`
  passed 59 tests after adding the bookmark-before-`change_log`-processed
  replay/drain proof.
- Broader file/storage regression sweep passed:
  `flutter test test/features/sync/engine/stale_file_cache_invalidator_test.dart test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart test/features/sync/engine/local_sync_store_contract_test.dart -r expanded`
  passed 172 tests.
- Final file/storage crash-matrix sweep passed after closing the
  bookmark-before-`change_log` case:
  `flutter test test/features/sync/engine/stale_file_cache_invalidator_test.dart test/features/sync/engine/adapter_integration_test.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/storage_cleanup_test.dart test/features/sync/schema/sync_schema_test.dart test/features/sync/adapters/adapter_config_test.dart test/features/sync/engine/orphan_scanner_test.dart test/features/sync/engine/local_sync_store_contract_test.dart -r expanded`
  passed 173 tests.
- `git diff --check` passed with line-ending warnings only.
- S21 driver hygiene: ready on `/sync/dashboard`, empty `change_log`,
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.
- S10 driver hygiene: ready on `/projects`, empty `change_log`,
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`,
  `isSyncing=false`.

PowerSync attachment-helper triage result:

- Current PowerSync docs say the old Dart `powersync_attachments_helper`
  package is deprecated and attachment functionality has moved into built-in
  SDK helpers. The reusable pattern is local-only attachment metadata, explicit
  upload/download/delete states, retries, verification/repair, and cleanup.
- Direct adoption is not a release fit because it couples to PowerSync
  database/queue APIs and would introduce a second sync substrate. The current
  local implementation ports the useful pattern into Field Guide's existing
  SQLite/Supabase sync engine with `file_sync_state_log` as diagnostic phase
  evidence rather than a second production queue.

Accepted local evidence:

- `dart analyze lib/features/sync/engine/file_sync_three_phase_workflow.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/file_sync_handler_test.dart -r expanded`
  passed 16 tests.
- `dart analyze lib/features/sync/engine/sync_metadata_store.dart lib/features/sync/engine/local_sync_store_metadata.dart lib/features/sync/engine/pull_handler.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart`
  passed with no issues.
- `flutter test test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/pull_handler_contract_test.dart test/features/sync/engine/supabase_sync_contract_test.dart -r expanded`
  passed 79 tests.
- `dart analyze test/features/sync/engine/pull_handler_test.dart` passed with
  no issues after adding the partial-final-page restart test.
- `flutter test test/features/sync/engine/pull_handler_test.dart -r expanded`
  passed 21 tests.
- Final combined sweep passed:
  - `git diff --check`
  - `dart analyze lib/features/sync/engine/file_sync_three_phase_workflow.dart lib/features/sync/engine/sync_metadata_store.dart lib/features/sync/engine/local_sync_store_metadata.dart lib/features/sync/engine/pull_handler.dart lib/features/sync/engine/supabase_sync.dart lib/shared/datasources/generic_local_datasource.dart test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/supabase_sync_contract_test.dart test/features/pay_applications/data/datasources/local/export_artifact_local_datasource_test.dart test/helpers/sync/fake_supabase_sync.dart`
  - `flutter test test/features/sync/engine/file_sync_handler_test.dart test/features/sync/engine/local_sync_store_contract_test.dart test/features/sync/engine/pull_handler_test.dart test/features/sync/engine/pull_handler_contract_test.dart test/features/sync/engine/supabase_sync_contract_test.dart test/features/pay_applications/data/datasources/local/export_artifact_local_datasource_test.dart -r expanded`
    passed 103 tests.

## Immediate P0 - Springfield Cursor/Pull-Echo Defect

- [x] Prove remote Springfield DWSRF still has 131 active `bid_items`.
- [x] Prove S21 local Springfield was missing pay items while sync reported
  clean/idle.
- [x] Classify the cause: same-company multi-role access likely exposed the
  defect, but legitimate edits from different roles on the same project are
  not the direct cause. The direct failure was global table-level pull cursors
  combined with dynamic project scope, followed by pull-applied rows echoing
  into `change_log`.
- [x] Patch trigger suppression ownership so a sync attempt that fails to
  acquire the mutex cannot reset another active pull's `pulling` flag.
- [x] Patch full sync to run an immediate repair pull when integrity clears
  pull cursors.
- [x] Patch conflict-only sync results so they do not mark sync successful or
  fresh and are surfaced to users as attention-needed state.
- [x] Add a targeted startup repair for verified pull-echo conflict residue.
  The repair only dismisses remote-wins conflicts when the same record has a
  processed local `insert` change-log row, no pending change-log row, and the
  conflict was detected within the pull-echo window.
- [x] Run focused local tests:
  - `dart analyze lib\features\sync\engine\sync_repair_debug_store.dart lib\features\sync\engine\local_sync_store_metadata.dart lib\features\sync\application\sync_state_repair_runner.dart lib\features\sync\application\repairs\repair_sync_state_v2026_04_19_pull_echo_conflicts.dart test\features\sync\application\sync_state_repair_runner_test.dart`
  - `flutter test test\features\sync\application\sync_state_repair_runner_test.dart -r expanded`
  - `flutter test test\features\sync\engine\sync_engine_status_test.dart -r expanded`
- [x] Hot-restart S21 patched build and verify the repair ran on-device:
  `sync_repair_job::repair_sync_state_v2026_04_19_pull_echo_conflicts`
  affected 992 rows.
- [x] Verify S21 Springfield local pay items after repair:
  131 Springfield `bid_items` remain present.
- [x] Verify S21 queue after repair:
  `pendingCount=0`, `blockedCount=0`, `unprocessedCount=0`.
- [x] Run S21 Sync Dashboard UI acceptance:
  `20260419-s21-springfield-pull-echo-after-repair-ui-sync` passed with
  `directDriverSyncEndpointUsed=false`, `runtimeErrors=0`,
  `loggingGaps=0`, queue drained, and 3 screenshots captured.
- [ ] Classify or intentionally baseline the 59 remaining S21 conflicts that
  were not pull-echo residue:
  24 `signature_audit_log` remote-wins, 24 `signature_files` remote-wins,
  5 `documents` remote-wins, 4 `personnel_types` remote-wins,
  1 `signature_audit_log` local-win, and 1 `signature_files` local-win.
- [ ] Fix the remaining fixture problem before role-collaboration acceptance:
  S10 is logged in as inspector but currently has zero local/assigned projects,
  so it cannot prove same-project inspector/office-tech/admin boundaries yet.

## P2 And Exit Gates

- [ ] Run external reuse triage for Jepsen, Elle, and lightweight local
  checker approaches.
- [ ] Add seedable operation scheduler and operation history.
- [ ] Add checker actors and invariant checks.
- [ ] Add failure injection and explicit quiescence.
- [ ] Run backend/RLS pressure concurrently with device flows while keeping
  evidence layers separate.
- [ ] Provision and prove staging harness credentials, schema parity, and
  RLS/storage policy parity.
- [ ] Expand deterministic fixtures to 15 projects and 10-20 users.
- [x] Add headless app-sync actors with isolated local stores.
- [ ] Add operational diagnostics and alert contracts.
- [ ] Write `docs/sync-consistency-contract.md`.
- [x] Write `docs/sync-scale-hardening-playbook.md`.
- [ ] Collect three consecutive green full-system staging or
  staging-equivalent sync-soak runs.

## 2026-04-19 - Active Lane: Cleanup, Visibility, Role Seams, Soak

- [x] Snapshot Supabase cleanup delete set before mutation:
  `.claude/test-results/2026-04-19/supabase-cleanup/pre-cleanup-inventory.json`.
- [x] Soft-delete all active non-Springfield junk projects through
  `admin_soft_delete_project`; do not delete users, companies, memberships, or
  Springfield DWSRF.
- [x] Seed disposable role/soak project
  `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`
  (`SOAK-ROLE-TRAFFIC-20260418`) with all four live role accounts assigned.
- [x] Write post-cleanup verification artifact:
  `.claude/test-results/2026-04-19/supabase-cleanup/post-cleanup-verification.json`.
  It shows exactly two active projects for the company: Springfield DWSRF and
  the disposable soak project.
- [x] Run S21/S10 through Sync Dashboard UI after cleanup:
  `20260419-s21-s10-after-supabase-cleanup-seed-ui-pull`.
- [x] Treat that S21/S10 run as **not accepted** despite the green harness
  summary. S10 pulled the local rows, but `/diagnostics/actor_context` still
  showed `projectCount=0`, `myProjectsCount=0`, and
  `companyProjectsCount=0`.
- [x] Patch the app so a UI-triggered sync completion refreshes
  `ProjectProvider` from the local project and assignment tables.
- [x] Patch diagnostics so `/diagnostics/actor_context` exposes project ID/name
  samples, not only counts.
- [x] Patch the soak harness so Sync Dashboard acceptance fails loudly when
  local active projects exist but `ProjectProvider` still reports no visible
  projects.
- [x] Add conflict-log diagnostics to `/driver/sync-status` and a Sync
  Dashboard sentinel that fails on any undismissed conflicts, because the
  dashboard attention cutoff hid historical conflict residue during the last
  run review.
- [x] Add targeted startup repair
  `repair_sync_state_v2026_04_19_deleted_project_conflicts` for junk-project
  tombstone residue only. It does not dismiss active Springfield conflicts and
  refuses records with pending local work.
- [x] Classify the largest remaining active conflict group as semantic
  timestamp-offset residue, not role-bleed:
  `documents`, `signature_files`, and `signature_audit_log` rows matched
  locally/remotely except for equivalent timestamp strings rendered with
  different offsets.
- [x] Patch semantic conflict handling:
  - parse timestamp keys as UTC instants before LWW comparison;
  - suppress no-op conflict rows when semantic `lost_data` contains no real
    changed field;
  - add `repair_sync_state_v2026_04_19_semantic_conflicts` for already logged
    semantically converged residue with no pending local work;
  - bump repair catalog to `2026-04-19.3`.
- [x] Run local gates for semantic conflict hardening:
  - `dart analyze` on conflict resolver, repair store, repair runner, and
    focused tests;
  - `flutter test test\features\sync\engine\conflict_resolver_domain_policy_test.dart test\features\sync\engine\conflict_clock_skew_test.dart test\features\sync\engine\conflict_resolver_test.dart test\features\sync\application\sync_state_repair_runner_test.dart -r expanded`
    passed 54 tests;
  - `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 12 test
    files;
  - `git diff --check` passed with line-ending warnings only.
- [x] Rebuild/restart S10 and S21 on the patched app, rerun the UI-only S21/S10
  cleanup pull, and accept only when:
  `triggeredThroughUi=true`, `directDriverSyncEndpointUsed=false`,
  queues/conflicts/logging/runtime sentinels are clean, S10/S21 actor context
  shows the soak project through provider/UI state, and `/driver/sync-status`
  reports `undismissedConflictCount=0`.
- [x] Treat
  `20260419-s21-s10-after-provider-refresh-sentinel-ui-pull` as **not
  accepted** until a rebuilt run proves the new conflict sentinel. Provider
  visibility was green, but manual review found undismissed conflict rows
  hidden by dashboard baseline logic.
- [x] Re-query both devices after repair catalog `2026-04-19.3` runs and
  classify any remaining local-missing/remote-tombstone conflicts. Do not
  baseline them silently; fix, dismiss through a reviewed repair, or log a
  named defect before acceptance.
- [x] Accepted cleanup/visibility/conflict sentinel run:
  `20260419-s21-s10-cleanup-visibility-conflict-sentinel-accepted`.
  Both devices passed UI-triggered Sync Dashboard sync with
  `directDriverSyncEndpointUsed=false`, drained queues, zero raw undismissed
  conflicts, zero runtime/logging gaps, and provider samples containing
  Springfield plus the disposable soak project.
- [x] Preserved reviewed conflict artifacts:
  - post-repair status:
    `.claude/test-results/2026-04-19/post-semantic-repair-status/`;
  - per-conflict local/remote review:
    `.claude/test-results/2026-04-19/remaining-conflict-review/`;
  - Conflict Viewer UI dismissal screenshots/status:
    `.claude/test-results/2026-04-19/reviewed-conflict-ui-dismissal/`;
  - S10 diagnostic active form-response repull:
    `20260419-s10-active-form-response-repull-diagnostic`.
- [ ] Resume role seam hardening on the disposable soak project:
  inspector creates field data, office technician reviews without unauthorized
  bleed-through, engineer/admin visibility is correct, role-specific UI actions
  and RLS denials match permissions, and all proof comes through UI flows with
  debug artifacts.
  - [x] Preserve the first role-collaboration run as a real failure, not an
    accepted role proof:
    `20260419-s10-s21-role-collaboration-soak-project-initial`.
  - [x] Review its raw log evidence and classify the actual failure:
    S10 never mounted `entry_editor_scroll` because `DailyEntry.fromMap`
    crashed on the synced weather value `"Clear"` while loading
    `daily_entries/743eb51d-8ff9-5a82-b291-ca3a7c977c40`.
  - [x] Patch `DailyEntry.fromMap` to parse both canonical enum names and
    weather-service display strings without throwing.
  - [x] Run local evidence for the weather parsing hardening:
    focused `dart analyze`, `flutter test test\data\models\daily_entry_test.dart -r expanded`,
    `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`, and
    `git diff --check`.
  - [x] Rebuild/restart S10 and S21 with the weather parsing patch.
  - [x] Preserve the second role-collaboration run as a real sync-seam
    failure, not accepted evidence:
    `20260419-s10-s21-role-collaboration-after-weather-parser`.
  - [x] Classify the second failure from raw artifacts: S10 inspector wrote
    `daily_entries/743eb51d-8ff9-5a82-b291-ca3a7c977c40` and pushed it
    through UI sync with remote write proof, but S21 office technician logged
    an undismissed remote-wins conflict while only pulling that inspector
    update and while S21 had no pending local `change_log` for the record.
  - [x] Patch pull classification so stale local rows are overwritten without
    `conflict_log` when `change_log` has no pending work for that table/record.
  - [x] Run local evidence for the no-pending-local pull classifier:
    focused `dart analyze`, `flutter test test\features\sync\engine\pull_handler_test.dart -r expanded`,
    `flutter test test\features\sync\engine\sync_engine_e2e_test.dart -r expanded`,
    `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1`, and
    `git diff --check`.
  - [x] Rebuild/restart S10 and S21 with the pull-classifier patch.
  - [x] Recover S10's one-row cleanup residue and S21's reviewed stale
    conflict through UI/repair-reviewed paths only, then rerun.
  - [x] Preserve
    `20260419-s10-s21-role-collaboration-after-pull-classifier` as a real
    UI-runtime failure, not accepted evidence. The pull classifier was fixed,
    but S21 logged a `Duplicate GlobalKey` / `InheritedGoRouter` assertion
    while saving the office review comment.
  - [x] Patch the review-comment dialog save path to release text focus before
    popping, then preserve
    `20260419-s10-s21-role-collaboration-after-review-dialog-focus-fix` as a
    second real UI-runtime failure because the same route assertion remained.
  - [x] Patch the report popup-menu review-comment action so dialog creation is
    delayed until the popup route finishes tearing down.
  - [x] Recover failed-run review todo residue through targeted soft delete
    plus UI-triggered Sync Dashboard recovery runs:
    `20260419-s21-s10-cleanup-after-review-dialog-runtime-failure` and
    `20260419-s21-s10-cleanup-after-review-popup-route-fix`.
  - [x] Accepted S10 inspector + S21 office-technician daily-entry/review
    seam:
    `20260419-s10-s21-role-collaboration-after-popup-route-delay`.
    It proved inspector remote write, office-technician UI pull/local
    visibility, office-technician review todo remote write, inspector final UI
    pull/local visibility, raw queue/conflict cleanliness, zero runtime/logging
    gaps, screenshots, and `directDriverSyncEndpointUsed=false`.
  - [x] Preserve strict role-sweep/provider-local failures as real defects,
    not accepted evidence:
    `20260419-s10-s21-role-sweep-inspector-office-physical`,
    `20260419-s10-s21-role-sweep-inspector-office-provider-strict`,
    `20260419-s10-s21-role-sweep-inspector-office-provider-repaired`, and
    `20260419-s10-s21-role-sweep-inspector-office-sync-surface-repaired`.
    The first run exposed a missing sentinel; the later strict runs correctly
    failed on provider-only blank project drafts created by the
    office-technician `/project/new` check while local active projects stayed
    Springfield plus the soak project.
  - [x] Harden the project visibility sentinel to fail on provider-only
    projects and on provider/local active project count mismatch.
  - [x] Patch project draft cleanup so blank suppressed drafts are removed
    from provider memory and discarded even when direct route replacement
    bypasses the project-setup back handler while the eager draft insert is
    still in flight.
  - [x] Accepted S10 inspector + S21 office-technician strict role sweep:
    `20260419-s10-s21-role-sweep-inspector-office-draft-dispose-cleanup`.
    It proved S10 inspector route/control denial, S21 office-technician
    project-create visibility, S21 `Draft discarded:
    d310380b-578a-48de-ab4a-03c91c9d7e70`, provider/local active project
    equality on both devices, `providerOnlyIds=[]`, drained queues, zero raw
    undismissed conflicts, zero runtime/logging gaps, screenshots/logs/debug
    artifacts, and `directDriverSyncEndpointUsed=false`.
  - [x] Cement the corrected role policy concisely in `.codex/AGENTS.md` and
    `.codex/role-permission-matrix.md`: admin-only company/member surfaces;
    engineer and office technician are project/data peers; inspector cannot
    manage/delete projects; Trash is user-scoped, not admin-only.
  - [x] Patch role/trash gates to match: Trash route/tile/count/load use the
    current user scope; office technician can delete own projects like
    engineer; Supabase migration `20260419090000_align_project_manager_role_policy.sql`
    aligns delete/restore RPC ownership.
  - [x] Verification: `dart analyze` focused touched files; focused
    Settings/Trash/Cascade/Auth/ProjectProvider Flutter tests passed; project
    setup/list touched tests passed; sync-soak harness passed 14 test files.
  - [ ] Expand role seam hardening beyond the accepted daily-entry/review
    slice: quantities, photos/files, documents/forms, denied role UI actions,
    RLS denial probes, storage/local placement, admin/engineer visibility, and
    no cross-account/project/provider bleed-through.
- [ ] Add emulator/four-account lane only after the two physical-device
  visibility gate is green, then log all four real role accounts and collect
  per-role actor context, local/remote reconciliation, screenshots, runtime
  logs, and queue/conflict evidence.
  - [x] Preserve `20260419-four-role-ui-endpoint-wiring` as rejected harness
    evidence, not role-policy failure. S21 admin passed, but S10 inspector,
    emulator engineer, and emulator office-technician failed because the
    harness still expected `/settings/trash` to be denied for non-admins.
    Current policy says Trash is user-scoped for every approved user.
  - [x] Patch the role sweep so Trash is asserted as
    `trash-user-scoped-allowed` for all approved roles while admin-dashboard
    remains admin-only.
  - [x] Add Android system-surface preflight/evidence to the state-machine
    harness. Each actor now captures UIAutomator XML, collapses notification
    shade overlays, tries to clear runtime permission prompts, and classifies
    remaining Android overlays as `system_overlay_blocked`.
  - [x] Local harness evidence:
    `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14 test
    files; `git diff --check` passed with line-ending warnings only.
  - [x] Current four endpoint preflight after the patch: S10 `4949`, S21
    `4968`, emulator `4972`, and emulator `4973` are ADB-visible with driver
    forwards intact and all four report `pendingCount=0`, `blockedCount=0`,
    `unprocessedCount=0`, `undismissedConflictCount=0`.
  - [x] Preserve
    `20260419-four-role-ui-endpoint-wiring-after-trash-surface-fix` as a
    fail-loud UI-runtime rejection, not accepted role evidence. The stale
    Trash expectation was gone and Android surface evidence was clean, but the
    four-role run failed with S21/emulator red screens and GoRouter
    `Duplicate GlobalKey` / `InheritedGoRouter` assertions during account
    switching.
  - [x] Classify the red-screen root cause as router key ownership plus auth
    teardown overlap: shell child pages reused `state.pageKey`, which can
    duplicate GoRouter-owned `GlobalObjectKey` state while full-screen auth
    routes and the old shell subtree tear down.
  - [x] Patch the router/sign-out guardrail:
    - shell container and shell child pages now use stable local `ValueKey`
      values instead of `state.pageKey`;
    - the sign-out dialog waits one theme animation after popping the dialog
      before mutating auth state;
    - `no_go_router_state_page_key_in_shell_routes` now lint-guards the whole
      `lib/core/router/` production surface.
  - [x] Proactively sweep the app routing/global-key surface:
    production `state.pageKey` now appears only in comments; remaining
    `GlobalKey` hits are local form/state-owned keys or the router navigator
    keys.
  - [x] Local red-screen hardening evidence:
    focused `dart analyze` passed; focused router/settings Flutter tests
    passed 44 tests; focused architecture lint tests passed 11 tests;
    `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14 test
    files; `git diff --check` passed with line-ending warnings only.
  - [x] Preserve
    `20260419-four-role-ui-endpoint-wiring-after-router-key-fix` as a second
    fail-loud UI-runtime rejection. It still failed on GoRouter
    `Duplicate GlobalKey` / `InheritedGoRouter` evidence, proving the first
    router key patch was incomplete. Queues drained and Android surface
    evidence stayed clean.
  - [x] Patch the next root-wrapper cause: `AppLockGate` no longer sometimes
    returns the router child directly and sometimes wraps it in a `Stack`; it
    now always returns a stable `Stack` shape and only toggles the lock overlay
    child.
  - [x] Expand `no_conditional_root_shell_child_wrapper` so it guards
    `app_lock_gate.dart` in addition to `app_widget.dart` and `main.dart`.
  - [x] Local AppLock/router hardening evidence:
    focused `dart analyze` passed; focused architecture lint tests passed 8
    tests; focused app-lock/router Flutter tests passed 23 tests;
    `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14 test
    files; `git diff --check` passed with line-ending warnings only.
  - [x] Preserve
    `20260419-four-role-ui-endpoint-wiring-after-app-lock-stable-wrapper` as
    a third fail-loud UI-runtime rejection. It still produced GoRouter
    `Duplicate GlobalKey` / `InheritedGoRouter` evidence, and live inspection
    showed S21 plus `emulator-5554` stuck on blank black app surfaces.
  - [x] Patch the remaining shell key ownership hazard: the production
    `ShellRoute` no longer holds an app-owned `navigatorKey`; go_router owns
    the shell navigator while the app keeps only `_rootNavigatorKey` for
    full-screen parent routes.
  - [x] Add `no_explicit_shell_route_navigator_key` to the architecture lint
    package so future router edits cannot reintroduce an explicit
    `ShellRoute(navigatorKey: ...)` in production router files.
  - [x] Promote blank black app surfaces into first-class soak evidence:
    Android UIAutomator snapshots now classify `android_app_blank_surface`,
    preflight throws `[blank_app_surface]`, evidence bundles emit runtime
    lines, and failure classification reports `blank_app_surface`.
  - [x] Local shell-key/blank-surface hardening evidence:
    focused `dart analyze` passed; focused architecture lint tests passed 12
    tests; focused router/settings/app-lock Flutter tests passed 46 tests;
    `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14 test
    files; `git diff --check` passed with line-ending warnings only.
  - [x] Preserve
    `20260419-four-role-ui-endpoint-wiring-after-shell-key-blank-surface-fix`
    as a fourth fail-loud UI-runtime rejection. It proved the
    blank-app-surface sentinel works on emulator black screens and exposed
    harness evidence pollution from benign UIAutomator `AndroidRuntime`
    logcat lines.
  - [x] Patch the remaining root inherited-wrapper hazard:
    responsive density now changes `ThemeData` above `MaterialApp.router`; the
    router builder no longer wraps GoRouter's child in `Theme` or a responsive
    inherited theme shell.
  - [x] Add `no_material_app_router_builder_theme_wrapper` to lint-lock that
    root architecture rule.
  - [x] Patch evidence attribution: preflight and every step clear ADB logcat
    before their evidence windows, and runtime scanning ignores benign
    UIAutomator `D/I AndroidRuntime` launcher noise while retaining fatal
    Android runtime detection.
  - [x] Local root-theme/logcat attribution evidence:
    focused `dart analyze` passed; focused architecture lint tests passed 16
    tests; focused app/router/settings Flutter tests passed 47 tests; and
    `pwsh -NoProfile -File tools\test-sync-soak-harness.ps1` passed 14 test
    files.
  - [ ] Rebuild/restart S10, S21, and both emulator driver apps on the
    root-theme/logcat attribution patch, then rerun the true simultaneous
    four-role UI account/role gate. Acceptance still requires per-role actor
    context, screenshots, debug-server logs, ADB logcat, Android surface
    evidence, clean queues/conflicts, and `directDriverSyncEndpointUsed=false`.
  - [ ] PAUSED HANDOFF 2026-04-19: do not treat any four-role UI device
    evidence as accepted yet. The latest completed four-role run is the
    rejected
    `20260419-four-role-ui-endpoint-wiring-after-shell-key-blank-surface-fix`
    artifact. Local code/harness fixes after that run are implemented and
    locally verified, but S10, S21, `emulator-5554`, and `emulator-5556` have
    not yet been rebuilt/restarted on this patch. Last known live issue before
    the patch was emulator black app surfaces plus reported red/black flashes;
    next session starts with device rebuild/restart, fresh logcat/debug-server
    clear, Android surface preflight, then the simultaneous four-role UI gate.
- [ ] Scale topology decision and proof gates:
  - [x] Rechecked local device capacity on 2026-04-19. One emulator is usable:
    `emulator-5554` on driver port `4972`, currently `/login`.
  - [x] Recorded the failed second-emulator attempt at
    `.claude/test-results/2026-04-19/emulator-capacity-attempt-20260419T080603Z/summary.json`.
  - [x] Classified the latest second-emulator blocker: it is not proven that
    the host can only run one emulator; the immediate blocker is that the
    first emulator was launched writable, and this emulator build requires all
    same-AVD multi-instances to start with `-read-only`.
  - [x] Restored S10/S21 driver forwards after emulator setup cleared them:
    S10 `4949` and S21 `4968` are reachable on `/sync/dashboard`; emulator
    `4972` is reachable on `/login`.
  - [ ] Optional clean capacity retry: stop the current emulator and launch two
    read-only emulator instances from the start, then install driver apps on
    distinct ports.
    - [x] Clean retry succeeded after stopping the old emulator and launching
      both `Pixel_7_API_36` instances read-only from the start. Current usable
      UI pool is S10 `4949`, S21 `4968`, `emulator-5554` `4972`, and
      `emulator-5556` `4973`.
  - [x] Do not block the whole scale plan on four full UI devices. Use three
    UI actors for real role seams while adding headless app-sync actors with
    isolated local stores and backend/RLS actors for pressure only.
  - [x] Clarified account scaling: the beta role seam needs the four real role
    accounts; the 10-20 actor soak can fan out multiple isolated app instances
    across those role accounts. It does not require 10-20 email-backed
    Supabase identities unless the gate is explicitly "unique identity/RLS
    scale."
  - [x] Added the first headless app-sync implementation path:
    `HeadlessAppSyncActionExecutor`, `SoakDriver.forHeadlessAppSync`,
    `test/harness/headless_app_sync_actor_test.dart`, and
    `scripts/soak_headless_app_sync.ps1`.
  - [x] Added `docs/sync-scale-hardening-playbook.md` to lock the actor,
    account, and evidence-layer model.
  - [x] Static/gated verification passed:
    focused `dart analyze`, sync-soak harness self-tests, and the gated
    headless app-sync Flutter test skip path.
  - [x] Preserved the first failed live attempt after Docker startup as a real
    defect: admin/manager project shells were visible, but child-table pulls
    stayed empty because sync enrollment depended on `project_assignments`.
  - [x] Patched role-aware sync enrollment so admin, engineer, and office
    technician materialize all locally visible projects, while inspector stays
    assignment-scoped. This hardens the "project visible but no pay
    items/children" failure class.
  - [x] Live headless app-sync smoke passed against local Supabase:
    `RUN_HEADLESS_APP_SYNC=true`, 4 virtual users, 4 concurrent actors,
    role-balanced admin/engineer/office-technician/inspector ordering,
    isolated SQLite stores, real sessions, real `SyncEngine`, 8/8 successful
    local-change/push/pull actions, zero errors, zero RLS denials, zero
    failures. Summary:
    `build/soak/headless-app-sync-summary.json`; actor manifest:
    `build/soak/headless-app-sync-2026-04-19T123748507173Z/actors.json`.
  - [x] Verify the headless app-sync actor path before calling
    the 10-20 actor soak real sync-engine scale proof.
  - [x] Preserve the rejected first 12-actor mixed headless run as useful
    failure evidence: it exposed invalid inspector fixture coverage for seeded
    child rows and shared-record proof collisions after concurrent writes.
  - [x] Patch the headless app-sync harness for beta scale reality:
    fan out over the four real role personas, serialize per-record proof
    actions, and repair mutable seeded photo soft-delete residue through a
    real authenticated admin session before actors pull.
  - [x] Accepted repaired four-role mixed headless smoke:
    `build/soak/headless-app-sync-2026-04-19T124750636961Z/actors.json`
    plus `fixture_repair.json`; 25/25 actions, zero failures/errors/RLS
    denials, and one previously poisoned seeded photo restored before pull.
  - [x] Accepted 12-actor local app-sync scale proof:
    `RUN_HEADLESS_APP_SYNC=true`, 12 virtual users, 6 concurrent workers,
    four real role personas fanned across isolated local SQLite stores,
    real sessions, real `SyncEngine`, 174/174 actions, zero failures/errors/
    RLS denials. Summary: `build/soak/headless-app-sync-summary.json`;
    actor/repair artifact:
    `build/soak/headless-app-sync-2026-04-19T124822914052Z/actors.json`.
    Post-run local Supabase query found zero seeded harness photos still
    soft-deleted.
- [ ] Move to at-scale sync soak only after role seams pass on the disposable
  fixture with fail-loud sentinels.
