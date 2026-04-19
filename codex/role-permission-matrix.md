# Field Guide Role Policy

Date: 2026-04-19
Status: controlling role-seam reference

- Admin-only surfaces: admin dashboard, member approval, role changes, company config.
- Admin can manage all projects/data; engineer and office technician are project/data peers.
- Engineer and office technician can manage projects/assignments and delete/restore their own projects where backend ownership allows.
- Inspector can write assigned field data, but cannot create, assign, archive, restore, or delete projects.
- Trash is not admin-only: every approved user can open Trash and sees only rows where `deleted_by` is their own user id.
- Do not run live admin deactivation/revocation as a beta role-hardening gate.

Code anchors: `UserRole.canManageProjects`, `AuthProvider.canDeleteProject`,
`settings_routes.dart`, `trash_screen_widgets.dart`, and Supabase migration
`20260419090000_align_project_manager_role_policy.sql`.
