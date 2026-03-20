# Adversarial Review: Bug Triage Fix Spec

**Spec**: `.claude/specs/2026-03-19-bug-triage-fix-spec.md`
**Date**: 2026-03-19
**Reviewers**: code-review-agent, security-agent

## MUST-FIX (8 items)

### MF-1: BUG-005 root cause is wrong — ScopeType.direct already set
`project_assignment_adapter.dart:17` already declares `ScopeType.direct`. The real deadlock is the orphan cleaner in `_loadSyncedProjectIds()` (sync_engine.dart:1312-1327) deleting freshly enrolled entries before the `projects` adapter runs. BUG-005 and BUG-002 share the same root cause. Fix: reload `_syncedProjectIds` after `project_assignments` pull completes (mirror existing `projects` reload at sync_engine.dart:1068).

### MF-2: Cannot drop `is_viewer()` — 70-96 policy clauses reference it
Dropping `is_viewer()` will break every write policy across 8 migration files. Either: (a) replace function body with `SELECT FALSE` and schedule batch cleanup, or (b) rewrite all clauses in the same migration. Option (a) is safer.

### MF-3: Projects UPDATE policy allows inspector to set is_active, name, dates
The spec only tightens INSERT. The UPDATE policy (`inspector_delete_guard.sql`) allows any non-viewer to UPDATE any field on live project rows. Inspector can archive, rename, or change dates server-side. Migration must also restrict projects UPDATE to `is_admin_or_engineer()` for project-level fields.

### MF-4: `clearSelectedProject()` takes no parameters
Spec describes `clearSelectedProject(projectId)` — method at `project_provider.dart:365` takes no params. Fix: guard externally: `if (projectProvider.selectedProject?.id == projectId) projectProvider.clearSelectedProject()`.

### MF-5: `BaseListProvider.canWrite` injection not in cleanup plan
10 injection sites in `main.dart:782-895` wire `() => authProvider.canWrite` into every field-data provider. Must be updated to `() => authProvider.canEditFieldData` or `() => true`.

### MF-6: Inspector edit button on project card must stay enabled
`project_list_screen.dart:740` gates edit IconButton with `canWrite`. If replaced with `canManageProjects`, inspectors lose access to the edit screen entirely — including contractor/location/pay-item tabs they need. Card-level edit button must stay enabled for all roles; only Details tab is gated.

### MF-7: Route guard must be in top-level GoRouter redirect callback
The spec describes the guard but doesn't specify it must be in the top-level `redirect:` lambda, not just widget-level. Deep links bypass widget guards.

### MF-8: `is_admin()` and `is_engineer()` don't exist as separate SQL functions
Spec's migration uses `is_admin() OR is_engineer()` — these functions don't exist. Use existing `is_admin_or_engineer()` from `20260319100000_create_project_assignments.sql`.

## SHOULD-CONSIDER (9 items)

### SC-1: Merge BUG-002 and BUG-005 — same root cause (orphan cleaner + pull ordering)
### SC-2: BUG-004 — use `Timer` not `Future.delayed` (cancellable), or cut entirely and rely on SyncLifecycleManager
### SC-3: `onPullComplete` is already awaited (sync_engine.dart:1270) — spec's "fire-and-forget" language is wrong
### SC-4: Offline indicator fits in existing `ScaffoldWithNavBar` banner area (app_router.dart:657-700)
### SC-5: Sync engine change_log has no client-side role filter — inspector project mutations hit wire then get RLS-rejected
### SC-6: `canWrite` grep shows ~139 auth-related occurrences, not 102 — implementer should expect more
### SC-7: `user_certifications` and `storage.objects` policies also reference `is_viewer()` — breakage risk
### SC-8: ViewOnlyBanner message needs rewording for inspector on Details tab
### SC-9: Add test: "inspector can tap edit button and reach contractor/location tabs"

## NICE-TO-HAVE (5 items)

### NH-1: Consider server-side trigger rejecting `is_active` changes from non-admin/engineer
### NH-2: Future hardening: SELECT on projects could be scoped to assigned projects for inspector
### NH-3: Remove `canEditProject` dead code before adding new getters (avoids accidental use during migration)
### NH-4: Verify `approve_join_request` RPC rejects viewer role via `npx supabase db diff`
### NH-5: Client-side sync engine guard to skip project-table updates for inspector role
