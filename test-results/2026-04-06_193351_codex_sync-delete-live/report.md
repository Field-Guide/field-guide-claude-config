# Sync Delete Verification Report — 2026-04-06 19:33:51
Platform: dual (windows:4948 + android-s21:4949)
Run Tag: t138i

## Results
| Flow | Status | Duration | Notes |
|------|--------|----------|-------|
| Entry delete S21 -> Cloud -> Windows | Pass after fix | multi-step | Real UI delete on S21, sender queue drained, Supabase tombstones verified for `daily_entries`/`photos`/`documents`, storage prefixes empty, Windows converged after pull |
| Project delete S21 -> Cloud -> Windows | Pass after fixes | multi-step | Real UI delete on S21, remote RPC tombstoned full subtree including `project_assignments`, sender + Windows now converge on deleted project subtree |

## SQLite Verification
| Flow | Sender Row | Sender Queue | Receiver Row | Receiver Queue | Notes |
|------|------------|--------------|--------------|----------------|-------|
| Entry delete `1a31fc0c-33ef-4f99-8c07-60ebc9825c4e` | deleted entry + deleted photo/document | drained after sync | deleted entry + deleted photo/document | none | Initial live run exposed missing child cascade in `DailyEntryProvider.deleteEntry()`; fixed to use `SoftDeleteService.cascadeSoftDeleteEntry(...)` |
| Project delete `d2bb6a5d-010f-4e9b-adcb-9188ea442391` | deleted project subtree incl. assignments | no pending delete changes; sender still has storage cleanup rows to observe | deleted project subtree incl. assignment tombstone on Windows | none observed | Initial live run exposed local `project_assignments` stale rows after project delete; fixed by adding `project_assignments` to project soft-delete graph |

## Supabase Verification
| Table | Records Created | Records Verified | Cascade Deleted | Notes |
|-------|----------------|-----------------|-----------------|-------|
| `daily_entries` / `photos` / `documents` | 1 entry + 1 photo + 1 document | yes | yes | Entry delete propagated with row tombstones and storage removal |
| `projects` subtree for `VRF-Delete t138i` | 1 project + descendants | yes | yes | Verified remote tombstones for project, contractor, location, personnel types, and both project assignments |

## Cross-Device Sync
| Flow | Windows→Cloud | Cloud→S21 | Latency | Notes |
|------|----------------|-----------|---------|-------|

## Log Anomalies
| Flow | Level | Category | Message | Timestamp |
|------|-------|----------|---------|-----------|

## Bugs Found
- Sync defect fixed: real entry delete UI path only soft-deleted `daily_entries`, leaving active `photos` / `documents` on sender and receiver until code change. Fixed in `DailyEntryProvider.deleteEntry()` by routing through `SoftDeleteService.cascadeSoftDeleteEntry(...)`.
- Sync defect fixed: receiver pull scope dropped deleted parent IDs, so child tombstones for via-entry and via-contractor tables could not arrive after parent deletion. Fixed by retaining materialized deleted parent IDs for pull scope.
- Sync defect fixed: project delete local cascade missed `project_assignments`, leaving stale local assignment rows after remote RPC cascade. Fixed by adding `project_assignments` to the shared project soft-delete graph.

## Post-Run Sweep
| Table | VRF Records Found | Status |
|-------|-------------------|--------|

## Observations
- Delete orchestration needs to stay split across graph, local cascade, remote coordinator, scope-revocation cleanup, and propagation verification. The live failures this run were all graph/scope drift, not generic sync instability.
- `delete-propagation` project snapshots currently include duplicate table rows for some entry/file-backed tables. This does not invalidate the counts used here, but the verifier output should be deduplicated before final release proof.

## Pre-Resume Refactor Checkpoint — 2026-04-07
- Sync dashboard now follows the refactored UI endpoint pattern: a screen-local `SyncDashboardController` is provided via `sync_screen_providers.dart`, and the screen no longer owns inline async diagnostics state.
- `/driver/delete-propagation` is now handled by a dedicated `DriverDeletePropagationHandler` instead of extending `DriverServer` further.
- `DeletePropagationVerifier.inspectProject(...)` now collapses overlapping direct/entry/contractor scope filters into one snapshot row per table, eliminating the duplicate project snapshot output observed in the live run.
- Local proof before resuming device work: targeted sync presentation + delete-verifier tests passed, and `flutter analyze` on the touched sync/driver files passed clean.

## Resume Wave — 2026-04-07
- Windows driver bootstrap initially failed because `lib/core/app_widget.dart` had a `ThemeExtension` collection typing error that only surfaced during `flutter run -d windows`. The compile break was fixed, then both drivers were relaunched successfully (`4948` Windows, `4949` S21).
- UI absence proof is now explicit on both devices:
  - Windows `/projects`: `project_card_d2bb6a5d-010f-4e9b-adcb-9188ea442391` not found
  - S21 `/projects`: `project_card_d2bb6a5d-010f-4e9b-adcb-9188ea442391` not found
  - Windows `/entries`: `entries_list_entry_tile_1a31fc0c-33ef-4f99-8c07-60ebc9825c4e` not found
  - S21 `/entries`: `entries_list_entry_tile_1a31fc0c-33ef-4f99-8c07-60ebc9825c4e` not found
- Project-delete storage cleanup is now explicit for the deleted subtree. Using the desktop app’s persisted Supabase session, remote storage list queries returned zero matches for every surviving deleted-project `remote_path` in `entry-photos` and `entry-documents`.
- This closes the previously open `project-delete-storage-and-ui-verification` gate.

## Restore Retest Wave — 2026-04-07
- First restore retest exposed a real restore-scope defect: restoring the project from Trash only revived the local `projects` row, leaving `project_assignments` tombstoned. Windows could not pull the restored project because scope never came back.
- Fixes landed before the next live retest:
  - local `SoftDeleteService.restoreWithCascade('projects', ...)` now restores the project subtree instead of only the parent row
  - project restore from Trash now uses a remote-first `admin_restore_project` Supabase RPC and suppresses local restore sync logging
  - remote migration `20260407120000_add_project_restore_rpc.sql` restores the project subtree server-side and handles `project_assignments` restore without reopening general client-side assignment updates
- Live retest after the client + remote changes:
  - S21 delete from `/projects` tombstoned `projects` + `project_assignments` again
  - S21 restore from `/settings/trash` revived `projects`, `project_assignments`, `daily_entries`, `photos`, and `documents` locally with matching `updated_at`
  - Supabase rows for `projects`, `project_assignments`, `daily_entries`, `photos`, and `documents` all returned `deleted_at = null`
  - Windows pull reported `pulled: 13` and the restored subtree is now active in receiver SQLite, including `synced_projects`, `project_assignments`, `daily_entries`, `photos`, and `documents`
- Remaining blocker after the successful restore convergence:
  - S21 `/projects` now shows `project_card_d2bb6a5d-010f-4e9b-adcb-9188ea442391`
  - Windows `/projects` still does not show `project_card_d2bb6a5d-010f-4e9b-adcb-9188ea442391` even though the project row is active locally and `synced_projects` contains the project
  - Windows receiver UI visibility therefore remains open before the hard-delete / revocation overlap lane can continue
- Additional note:
  - a `driver/sync` call issued while S21 remained on Trash returned a widget lifecycle error (`Looking up a deactivated widget's ancestor is unsafe`). The restore itself had already converged remotely and on Windows, so this did not block the restore proof, but the screen-level sync invocation path needs follow-up.

## Restore Visibility + Idempotence Wave — 2026-04-07
- The earlier Windows `/projects` visibility blocker is closed. After route/tab interaction and a clean rebuild, both devices now surface:
  - restored project card `project_card_d2bb6a5d-010f-4e9b-adcb-9188ea442391`
  - restored entry tile `entries_list_entry_tile_1a31fc0c-33ef-4f99-8c07-60ebc9825c4e`
- A real repeat-sync blocker was then isolated on S21:
  - pull cursors only advanced when a fetched row changed locally, so already-matching rows inside the safety window could be re-fetched indefinitely
  - `support_tickets` remote schema had gained `updated_at`, but local SQLite and the model had not, causing a permanent support-ticket pull/conflict loop on Android
- Fixes landed before the next live rerun:
  - `PullHandler` now advances its cursor to the newest remote `updated_at` seen in the fetched page, even when the row already matches locally
  - local `support_tickets` schema/model now include `updated_at`, with a migration/backfill so the local row can retain the remote sync timestamp
  - regression coverage was added for pull cursor advancement on already-matching rows and for the `support_tickets` schema/model shape
- Live rerun after those fixes:
  - Android migration initially failed because SQLite rejects `ALTER TABLE ... ADD COLUMN` with a non-constant default; the migration was corrected to add `updated_at` without that default and backfill from `created_at`
  - after reinstall/relaunch, both Windows and S21 returned `{"success":true,"pushed":0,"pulled":0,"errors":[]}` on the first full sync rerun
  - both Windows and S21 returned the same `pushed: 0, pulled: 0` result on a second consecutive full sync rerun
- This closes the restore visibility + restore-state idempotence gate. The next live lane is hard-delete / revocation overlap.

## Hard Delete Wave — 2026-04-07
- Sender setup:
  - S21 re-deleted project `d2bb6a5d-010f-4e9b-adcb-9188ea442391` through the production `/projects` delete path and confirmed the project trash controls were present
  - S21 Trash `Delete Forever` removed the project trash actions immediately
  - S21 `/driver/delete-propagation` then reported `target_exists: false`, `synced_project_enrolled: false`, and zero remaining subtree rows across the registered project graph
- Immediate sender result:
  - S21 local `projects` and `daily_entries` rows for the test subtree were no longer found through `/driver/local-record`
  - sender full sync reported `{"success":true,"pushed":1,"pulled":0,"errors":[]}`
- Receiver result without maintenance:
  - Windows full sync reported `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
  - Windows still retained the active project subtree immediately after that normal pull, so hard delete did not converge through the ordinary pull path alone
- Receiver result with forced maintenance:
  - after `POST /driver/reset-integrity-check` and another full sync, Windows soft-deleted the stale project subtree as `deleted_by = system_orphan_purge`
  - Windows `/projects` and `/entries` no longer surface the project card or restored entry tile after that maintenance-assisted cleanup
- Remaining hard-delete gaps:
  - receiver cleanup currently depends on integrity/orphan purge rather than a first-class hard-delete propagation path
  - Windows `synced_projects` remained enrolled for the project even after the subtree was orphan-purged
  - S21 `/projects` still showed a stale project card immediately after local hard delete despite `/driver/local-record` proving the row was gone; that looks like a screen refresh/UI issue, not a local SQLite failure
- Audit conclusion before the next patch:
  - the current client hard-delete path (`hardDeleteWithSync` -> change_log `delete` -> `pushHardDelete`) is structurally unsafe for multi-device convergence because it physically removes the remote soft-delete tombstone before lagging receivers can pull it
  - the safer contract is to treat Trash `Delete Forever` as a local purge of an already-soft-deleted record while leaving remote tombstones for normal receiver convergence and server-side retention purge
  - `synced_projects` cleanup also lags one cycle because pull finalization runs before maintenance/orphan purge mutates the local subtree

## Shared Delete-Contract Audit — 2026-04-07
- The hard-delete bug is a shared sync-contract problem, not just a Trash-screen problem.
- Runtime paths fall into three categories:
  - Soft-delete lifecycle paths: standard deletes update local rows with tombstones and are still sync-safe.
  - Local-only eviction paths: `removeFromDevice` and scope-revocation eviction intentionally suppress triggers and clear local change tracking so they do not mutate Supabase. These are different by contract and are not the root cause of the hard-delete drift.
  - Local purge paths that still emit sync deletes: Trash `Delete Forever`, retention purge, and any future local purge built on the same pattern were unsafe because once the sender physically removed the local row, push escalated to remote physical delete for a soft-delete table.
- Shared fix landed before the next live rerun:
  - local hard purge now preserves the final tombstone payload in `change_log.metadata`
  - push now replays that preserved soft-delete when the local row is already gone instead of remote-hard-deleting the row
  - maintenance now cleans stale `synced_projects` in the same cycle after orphan purge soft-deletes a project shell
- Targeted local proof after the patch:
  - `flutter test test/features/sync/engine/push_handler_test.dart test/features/sync/engine/maintenance_handler_contract_test.dart test/features/sync/engine/cascade_soft_delete_test.dart`
  - `flutter analyze` on the touched sync/delete files
- Additional audit follow-up that remains open:
  - legacy `BaseRemoteDatasource.delete()` style APIs still exist and should be treated as footguns until their runtime usage is fully constrained
  - `support_tickets.updated_at` no longer causes repeat-pull churn, but upgraded SQLite installs still log schema drift because migration v53 does not yet match the canonical `NOT NULL DEFAULT` shape

## Fresh Fixture Hard-Delete Revalidation — 2026-04-07
- The original proof project `d2bb6a5d-010f-4e9b-adcb-9188ea442391` was no longer restorable remotely, so a fresh live fixture was created on S21 through the production project-create UI:
  - project `b28afcd0-501f-463c-a255-8f61469a2ba5`
  - name `VRF HardDelete t138i-b`
- New-fixture setup notes:
  - the project row pushed remotely under the admin account (`created_by_user_id = 88054934-9cc5-4af3-b1c6-38f262a7da23`)
  - to give the Windows device a legitimate receiver scope, a remote `project_assignments` row was inserted for the Windows account (`d1ca900e-d880-4915-9950-e29ba180b028`)
  - after that assignment landed, Windows ordinary sync pulled the project row and assignment, and local `delete-propagation` showed `target_exists: true`, `target_deleted: false`, `synced_project_enrolled: true`
- Fresh-fixture soft-delete proof:
  - S21 deleted the project through the real `/projects` delete sheet + confirm-dialog flow
  - S21 local state: project tombstoned, both project assignments tombstoned, `synced_project_enrolled: false`
  - Supabase state: project row tombstoned and both assignment rows tombstoned with matching `deleted_at` / `updated_at`
  - Windows ordinary sync pulled `2` rows and converged to the same hidden tombstone state
  - Windows UI absence was explicit again: `project_card_b28afcd0-501f-463c-a255-8f61469a2ba5` not found
- Fresh-fixture hard-delete proof:
  - S21 Trash `Delete Forever` removed the local project shell immediately: `target_exists: false`, no remaining project-assignment rows, one pending delete change, then sender sync reported `{"success":true,"pushed":1,"pulled":0,"errors":[]}`
  - the first normal Windows sync after that sender push reported `{"success":true,"pushed":0,"pulled":0,"errors":[]}` and kept the local tombstoned shell
  - after forcing the Windows integrity cadence, the next sync pulled `1` row and updated the local tombstone metadata, but the receiver still intentionally remained a hidden tombstone rather than locally purging the shell
  - remote Supabase state after the sender hard-delete push stayed on a soft tombstone, with `updated_at` advanced to `2026-04-07T13:12:15.940163-04:00`
- Idempotence after the fresh-fixture hard delete is now explicit:
  - S21 consecutive sync: `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
  - Windows consecutive sync: `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
  - S21 `change_log?table=projects` returned zero pending entries
- Architecture conclusion from the fresh fixture:
  - the shared delete-contract fix did close the data-loss/drift class where sender hard delete could physically remove the remote soft-delete tombstone before lagging receivers saw it
  - the current contract is now: sender `Delete Forever` locally purges the sender shell, preserves/replays the remote tombstone, and receivers converge to a hidden tombstone state until a later server-side retention purge removes the remote row
  - under that contract, the old expectation that Windows should immediately drop the local tombstone shell on ordinary pull is no longer the correct success condition

## Revocation + Overlap Wave — 2026-04-07
- Simple revocation cleanup proof used a fresh remote-seeded fixture:
  - project `4825141a-7b6b-44f9-9ef1-ba5e89dc39fd`
  - name `VRF Revocation t138i-d`
- Revocation-only result:
  - both devices first pulled the active project and assignment scope from Supabase
  - the Windows assignment row was then soft-deleted remotely while the project itself remained active in Supabase
  - the next ordinary Windows sync fully evicted the local project scope: `/driver/local-record` returned `Record not found`, `/driver/delete-propagation` reported `target_exists: false`, `synced_project_enrolled: false`, zero remaining `project_assignments`, and Windows `change_log` stayed empty
  - the remote project row stayed active (`deleted_at = null`), and S21 remained enrolled on the same project with one active assignment and one deleted assignment after its next pull
  - repeated sync after that revocation settled at `{"success":true,"pushed":0,"pulled":0,"errors":[]}` on Windows
- Delete-plus-revocation overlap proof used a second remote-seeded fixture:
  - project `c55c4b2f-1c9a-4ca3-a0fc-1a209f9c57a3`
  - name `VRF RevocationOverlap t138i-e`
- Overlap result:
  - both devices first pulled the active project and assignments
  - the server-side `admin_soft_delete_project` RPC was then executed remotely, which tombstoned the project row and both assignment rows together
  - the next ordinary pull on both devices converged to a hidden tombstone state: the project row remained locally with `deleted_at` populated, `synced_project_enrolled: false`, and `project_assignments` showed only deleted rows
  - both `/projects` UIs no longer surfaced the project card (`project_card_c55c4b2f-1c9a-4ca3-a0fc-1a209f9c57a3` not found on Windows or S21)
  - repeated sync after the overlap settled immediately at `{"success":true,"pushed":0,"pulled":0,"errors":[]}` on both devices
- Architecture conclusion from the revocation wave:
  - plain scope revocation of an active project now fully evicts the revoked receiver cache without mutating the still-active remote project
  - when delete tombstones and assignment revocation arrive together, delete currently wins over full local eviction: receivers keep a hidden project tombstone with `synced_project_enrolled: false` rather than dropping the row entirely
- New blocker isolated while closing this wave:
  - S21 still carries two exhausted `project_assignments` update retries in `change_log` with `RLS denied (42501)` even though the corresponding assignment IDs are no longer present locally or remotely
  - code audit points at the current assignment wizard path as the architectural footgun: `ProjectAssignmentProvider.save()` still writes `project_assignments` locally through `ProjectAssignmentRepository`, even though the sync adapter marks that table `skipPush: true` and the intended ownership model treats it as pull-only
  - release closeout now needs a remote-first assignment mutation boundary (or equivalent suppression/ownership fix) plus a clean-device re-proof that assignment flows no longer create local `project_assignments` sync residue

## Project Assignment Mutation Contract Wave — 2026-04-07
- First rerun exposed invalid live evidence: the S21 was still on a stale build. Android app logs still contained the removed string `Immediate push triggered after project creation`, so both drivers were rebuilt and relaunched before re-running the lane.
- Fresh-build UI state on S21 proved the assignment screen itself was no longer stale:
  - route `/project/4825141a-7b6b-44f9-9ef1-ba5e89dc39fd/edit?tab=4` showed the Windows inspector unchecked and only the admin selected
  - this removed the earlier suspicion that the screen was still reading stale local assignment state after revocation
- Client-side ownership fix:
  - `ProjectAssignmentMutationService` now diffs against the active remote baseline only by filtering `project_assignments.deleted_at IS NULL`
  - this closes the bug where a soft-deleted remote assignment row was incorrectly treated as already active, producing `added=0 removed=0` and skipping the restore mutation
- Server-side restore-contract fix:
  - existing trigger immutability logic still blocked reactivating a soft-deleted `project_assignments` row during the mutation flow
  - migration `20260407143000_allow_assignment_restore_rpc.sql` now lets `admin_upsert_project_assignment` set the sanctioned `app.restore_project_assignment` flag before restoring an existing assignment row
- Targeted local validation passed before the live rerun:
  - `flutter test test/features/projects/data/services/project_assignment_mutation_service_test.dart`
  - `flutter analyze lib/features/projects/data/services/project_assignment_mutation_service.dart test/features/projects/data/services/project_assignment_mutation_service_test.dart`
  - `npx supabase db push --include-all`
- Final live proof on fresh builds:
  - S21 save from `/project/4825141a-7b6b-44f9-9ef1-ba5e89dc39fd/edit?tab=4` logged `ProjectAssignmentMutationService: project=4825141a-7b6b-44f9-9ef1-ba5e89dc39fd added=1 removed=0`
  - S21 `delete-propagation` for the same project then showed `project_assignments total_count: 2`, `active_count: 2`, `deleted_count: 0`
  - S21 `change_log?table=project_assignments` stayed at the same two historical exhausted retries; no new local assignment sync rows were created by the new save path
  - Windows ordinary full sync pulled the restored assignment truth, kept `synced_project_enrolled: true`, and `/projects` rendered `project_card_4825141a-7b6b-44f9-9ef1-ba5e89dc39fd`
  - repeated full sync then settled at `{"success":true,"pushed":0,"pulled":0,"errors":[]}` on both S21 and Windows
- Architecture conclusion from the lane:
  - assignment mutation is now correctly remote-first for `project_assignments`
  - restore-capable soft-delete tables need an explicit sanctioned RPC/trigger path, not ad hoc row updates
  - executor diff logic must query the active remote baseline (`deleted_at IS NULL`) rather than raw rows that include tombstones
- Remaining blockers after this proof:
  - upgraded SQLite installs still log `support_tickets.updated_at` schema drift because migration v53 does not yet match the canonical `NOT NULL DEFAULT` shape
  - S21 still carries two old exhausted `project_assignments` retries from the pre-fix contract breach, so release closeout still needs a legacy residue decision or cleanup proof

## Upgraded-Install Repair Wave — 2026-04-07
- The next live blocker after assignment-contract proof was upgraded-device state, not fresh-install state.
- Source audit confirmed the mismatch:
  - canonical SQLite DDL already defines `support_tickets.updated_at` as `TEXT NOT NULL DEFAULT strftime(...)`
  - migration v53 only added `updated_at TEXT`, which stopped the repeat-pull loop but left permanent SchemaVerifier drift on upgraded installs
- Fixes landed before the next live rerun:
  - migration v55 rebuilds `support_tickets` to the canonical schema shape and replays existing ticket rows through the rebuilt table
  - migration v56 purges pending `change_log` residue for pull-only `project_assignments`, because any local pending row for that table is invalid by contract
  - regression coverage was added for both repairs: canonical `support_tickets` rebuild and pull-only `project_assignments` residue purge
- Targeted local validation passed:
  - `flutter test test/features/sync/schema/support_ticket_schema_test.dart test/core/database/project_assignment_changelog_repair_test.dart`
  - `flutter analyze` on the touched database/support-ticket test files
- Final live proof on rebuilt Windows + S21:
  - S21 startup log now reports `Migration v55: rebuilt support_tickets with canonical updated_at schema`
  - S21 startup log then reports `SchemaVerifier: verified 40 tables in 80ms — SchemaReport(drift=0, missing_cols=0, missing_tables=0)`
  - after v56, S21 startup log reports `Migration v56: purged 2 invalid project_assignments change_log entries`
  - S21 `/driver/change-log?table=project_assignments` now returns `count: 0`
  - ordinary full sync still settles cleanly after both repairs: Windows `{"success":true,"pushed":0,"pulled":0,"errors":[]}` and S21 `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
- Release-status conclusion after this wave:
  - the assignment mutation contract is no longer a live blocker
  - upgraded-install schema drift for `support_tickets.updated_at` is no longer a live blocker
  - legacy `project_assignments` retry residue is no longer a live blocker
  - the branch is still not fully release-proven because major proof lanes remain open: remove-from-device/fresh-pull parity, file-backed flows, support-ticket and consent live flows, restart/retry chaos lanes, and the final mixed-flow soak

## Remove-From-Device / Fresh-Pull Parity Wave — 2026-04-07
- The first remove-from-device rerun exposed two separate defects:
  - `removeFromDevice` mutated local project scope outside the shared sync mutex, so a local-only eviction could race an in-flight sync on S21
  - local-only eviction deleted project-scoped rows without resetting pull cursors, so a later "fresh pull" could miss older remote rows and rematerialize only part of the scope
- Fixes landed before the final rerun:
  - `ProjectLifecycleService.removeFromDevice(...)` now acquires the shared SQLite sync mutex before mutating local scope and refuses to run while sync already owns the lock
  - when the project metadata shell is intentionally preserved for re-download, `removeFromDevice(...)` now clears the pull cursors for the project-scoped sync tables so the next healthy cycle performs a true fresh pull instead of relying on stale table cursors
  - targeted local validation passed:
    - `flutter test test/features/projects/data/services/project_lifecycle_service_test.dart`
    - `flutter analyze lib/features/projects/data/services/project_lifecycle_service.dart test/features/projects/data/services/project_lifecycle_service_test.dart`
- Fixture note:
  - the earlier S21 rerun against `4825141a-7b6b-44f9-9ef1-ba5e89dc39fd` turned out to be contaminated, not a new enrollment bug; direct SQLite inspection showed that project was only actively assigned to the Windows inspector account after the revocation proof, so it was not a valid S21 admin fresh-pull fixture anymore
  - the clean shared fixture for final proof was project `e7dde2a2-8662-4d5a-ad32-3e167ad5576d` (`VRF-Oakridge aun53`)
- Final live proof on the patched builds:
  - Windows remove-from-device on `e7dde2a2-8662-4d5a-ad32-3e167ad5576d` reduced local state to a preserved project shell with `synced_project_enrolled = false`, zero descendant rows, and zero local `change_log`; S21 stayed fully active on the same project throughout
  - the next ordinary Windows sync rematerialized the full subtree (`pulled: 21`), including `locations`, `contractors`, `daily_entries`, `entry_*` tables, `equipment`, `bid_items`, `personnel_types`, and the active `project_assignments` row; the second consecutive Windows sync settled at `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
  - S21 remove-from-device on the same project reduced local state to the same preserved project shell with `synced_project_enrolled = false`, zero descendant rows, and zero local `change_log`; Windows stayed fully active on the same project throughout
  - after the cursor-reset fix, the next healthy S21 sync rematerialized the full subtree and both active assignment rows; once an overlapping auto-sync finished, the next consecutive S21 sync settled at `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
- Contract conclusion from the wave:
  - remove-from-device is a local-only scope eviction, not a UI disappearance contract; the project shell can remain visible as the re-downloadable metadata card while the synced subtree and `synced_projects` enrollment are removed
  - the actual correctness gate is now proven: local-only eviction no longer mutates Supabase, the other device stays active, the evicted device recreates the same active scope on the next healthy sync, and repeat sync returns to `0/0`

## File-Backed Live Wave — 2026-04-07
- Shared file-backed fixture:
  - project `e7dde2a2-8662-4d5a-ad32-3e167ad5576d`
  - entry `4e35a00d-26d7-44b7-9f5d-c67c9e6f2f91`
  - document `e645a8b1-7d32-4a1d-80ad-945fd93b5193`
  - photo `86e4f663-5663-471e-b939-1b252f853159`
  - entry export `7f32b8f6-cfbb-4b75-8d4d-3ec09fe8d901`
  - form export `4d31540d-9a2c-4d52-8d4e-f2b72423655e`
- Create/push/pull proof on S21 -> Cloud -> Windows:
  - S21 staged a new proof entry plus one live `documents`, `photos`, `entry_exports`, and `form_exports` row each
  - pre-push S21 `delete-propagation` for the entry showed exactly one active row in each of the four file-backed tables and `pending_change_count: 7`
  - sender full sync reported `{"success":true,"pushed":7,"pulled":0,"errors":[]}`
  - Windows full sync then reported `{"success":true,"pushed":0,"pulled":5,"errors":[]}`
  - repeated full sync immediately settled at `{"success":true,"pushed":0,"pulled":0,"errors":[]}` on both S21 and Windows
- Local materialization proof after the create wave:
  - S21 local records for all four file-backed tables now carried non-null `remote_path` values
  - Windows local records for the same four rows materialized with matching `remote_path` values and the expected receiver-side `file_path = null` cache shape
  - both S21 and Windows `change_log` endpoints returned `count: 0` for `daily_entries`, `documents`, `photos`, `entry_exports`, and `form_exports` after the create wave settled
- Remote row + storage proof after the create wave:
  - authenticated Supabase REST queries returned all five remote rows (`daily_entries`, `documents`, `photos`, `entry_exports`, `form_exports`) with `deleted_at = null`
  - authenticated storage checks returned `200` for the exact object paths in `entry-documents`, `entry-photos`, `entry-exports`, and `form-exports`
- Real entry-delete proof for the file-backed subtree:
  - S21 navigated to `/report/4e35a00d-26d7-44b7-9f5d-c67c9e6f2f91`, used the shipped report-menu delete path, and returned to `/entries`
  - pre-sync S21 `delete-propagation` for the entry showed the entry plus all four file-backed rows tombstoned locally, with `queued_cleanup_count: 1` on each file-backed table
  - sender full sync then reported `{"success":true,"pushed":6,"pulled":0,"errors":[]}`
  - Windows full sync reported `{"success":true,"pushed":0,"pulled":5,"errors":[]}`
  - repeated sync again settled immediately at `{"success":true,"pushed":0,"pulled":0,"errors":[]}` on both devices
- Delete convergence proof after the delete wave:
  - S21 and Windows `delete-propagation` for the same entry now match exactly: entry tombstoned, all four file-backed tables tombstoned, `pending_change_count: 0`, `pending_delete_change_count: 0`, and `queued_cleanup_count: 0` everywhere
  - both `/entries` UIs explicitly hide the deleted fixture entry: `entries_list_entry_tile_4e35a00d-26d7-44b7-9f5d-c67c9e6f2f91` not found on S21 or Windows
  - S21 `change_log` returned `count: 0` for `documents`, `photos`, `entry_exports`, and `form_exports` after the delete wave settled
- Remote row + storage proof after the delete wave:
  - authenticated Supabase REST queries returned all five remote rows with `deleted_at` populated and matching post-delete `updated_at`
  - authenticated storage download checks for the exact four object paths now return Supabase `not_found`, confirming remote storage cleanup for `entry-documents`, `entry-photos`, `entry-exports`, and `form-exports`
- Harness note:
  - `/driver/inject-document-direct` still advertises `csv` as an allowed extension while `DocumentRepository` correctly rejects it; that mismatch is a driver-fixture issue, not a sync-engine issue, so the live proof used a real PDF document fixture instead
- Conclusion from the wave:
  - the file-backed live lane is now closed for create, push, pull, delete, remote row convergence, remote storage cleanup, receiver convergence, and repeat-sync idempotence across `documents`, `photos`, `entry_exports`, and `form_exports`

## Integrity / Maintenance Wave — 2026-04-07
- Baseline before the forced rerun:
  - both drivers were healthy and idle: Windows `/driver/sync-status` reported `pendingCount: 0`, `lastSyncTime: 2026-04-07T20:24:03.313271Z`; S21 `/driver/sync-status` reported `pendingCount: 0`, `lastSyncTime: 2026-04-07T20:23:59.669645Z`
  - both devices already had persisted integrity metadata from earlier maintenance cycles
- Controlled orphan fixture on Windows:
  - active shared project: `e7dde2a2-8662-4d5a-ad32-3e167ad5576d`
  - seeded directly into live Windows SQLite with trigger suppression / no pending sync residue:
    - `export_artifacts/d333298f-dddd-479f-a774-54eac7bf6114`
    - `pay_applications/a554c947-0641-4088-a62c-3fea463f180e`
  - both rows were active locally (`deleted_at = null`, `deleted_by = null`)
  - Windows `change_log` had zero rows for those IDs after seeding
  - authenticated Supabase REST queries confirmed both IDs were absent remotely (`[]` for both tables)
- Forced maintenance rerun:
  - `POST /driver/reset-integrity-check` returned success on both Windows and S21
  - the next ordinary full sync on both devices settled at `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
- Windows maintenance proof after the forced rerun:
  - persisted integrity metadata for the staged orphan tables recorded the expected pre-purge drift:
    - `integrity_export_artifacts`: `drift_detected: true`, `cursor_reset_recommended: true`, `local_count: 1`, `remote_count: 0`
    - `integrity_pay_applications`: `drift_detected: true`, `cursor_reset_recommended: true`, `local_count: 1`, `remote_count: 0`
  - the same maintenance cycle then soft-deleted both staged rows locally:
    - `export_artifacts/d333298f-dddd-479f-a774-54eac7bf6114` -> `deleted_by = system_orphan_purge`
    - `pay_applications/a554c947-0641-4088-a62c-3fea463f180e` -> `deleted_by = system_orphan_purge`
  - Windows `change_log` still returned zero rows for those two IDs after the purge
- S21 maintenance proof after the forced rerun:
  - persisted integrity metadata stayed clean for the same table family:
    - `integrity_export_artifacts`: `drift_detected: false`, `local_count: 0`, `remote_count: 0`
    - `integrity_pay_applications`: `drift_detected: false`, `local_count: 0`, `remote_count: 0`
- Repeat-sync / no-recurring-drift proof:
  - the next repeated full sync on Windows again settled at `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
  - the next repeated full sync on S21 again settled at `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
- Conclusion from the wave:
  - integrity reruns are now explicitly live-proven on both devices
  - maintenance-assisted orphan purge now has direct live evidence on pay-app / file-backed tables, not just project-entry tables
  - after maintenance repairs the local-only orphan state, the branch returns immediately to `0/0` repeat-sync behavior with no new `change_log` residue

## Support Ticket Wave — 2026-04-07
- User-scoped proof setup note:
  - `support_tickets` is scoped by `user_id`, not project or company
  - the S21 and Windows apps in this validation run are different user identities, so cross-device materialization is NOT expected for this table
- Real UI submission on S21:
  - navigated to `/help-support`
  - used the shipped support form with message `Support sync proof 2026-04-07T20:45:30Z from S21 live validation.`
  - local SQLite inserted ticket `833518ea-f187-4c54-ba6b-bce95f1a3e0e` with `status = open`, `log_file_path = null`
  - local `change_log` showed exactly one pending `support_tickets` insert for that ticket
- New blocker surfaced while closing the lane:
  - the first manual S21 sync after submission returned `pushed: 1` but also surfaced branch-wide remote schema errors:
    - `signature_files: Remote sync schema is missing table signature_files`
    - `signature_audit_log: Remote sync schema is missing table signature_audit_log`
  - root cause: the branch had already registered both signature tables locally, but Supabase had not yet applied `supabase/migrations/20260408000000_signature_tables.sql`
- Remote fix applied during the live run:
  - ran `npx supabase db push --include-all`
  - remote migration `20260408000000_signature_tables.sql` applied successfully
  - authenticated Supabase REST checks then returned `[]` for both `signature_files` and `signature_audit_log` instead of 404
- Final support-ticket proof after the remote fix:
  - authenticated Supabase REST returned the new support ticket row:
    - `833518ea-f187-4c54-ba6b-bce95f1a3e0e`
    - `user_id = 88054934-9cc5-4af3-b1c6-38f262a7da23`
    - `status = open`
  - after rerunning S21 sync, the support-ticket lane settled cleanly:
    - one successful sync reported `{"success":true,"pushed":1,"pulled":1,"errors":[]}`
    - the next repeated sync reported `{"success":true,"pushed":0,"pulled":0,"errors":[]}`
  - direct SQLite inspection on S21 showed:
    - no pending `support_tickets` `change_log` entries
    - `last_sync_time = 2026-04-07T20:53:25.592578Z`
- Harness note:
  - tapping the support success-screen `Done` path through the driver triggered a framework-locked provider reset (`SupportProvider.reset`) and destabilized the Android driver process
  - that is a driver/UI stability issue, not a support-ticket sync defect; the proof was completed after relaunching the S21 driver app and re-running sync
- Conclusion from the wave:
  - the dedicated support-ticket live flow is now proven on the correct user-scoped path: real UI submit on S21, remote row creation in Supabase, and repeat-sync return to `0/0`
  - the live run also closed a broader branch-level blocker by deploying the missing remote signature-table migration required by the current sync registry
