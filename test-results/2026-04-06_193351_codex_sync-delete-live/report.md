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
