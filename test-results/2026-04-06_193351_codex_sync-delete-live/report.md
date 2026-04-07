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
