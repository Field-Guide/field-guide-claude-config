# Role Boundary Rerun - Corrected Policy

Run started: 2026-04-17T02:25Z

Use these top-level files first:

- `run-manifest.json` for devices, validation status, and policy assumptions.
- `coverage.md` for pass/fail coverage rows.
- `findings.md` for open and fixed findings.
- `coverage-clean.csv` and `findings-clean.jsonl` as machine-readable trusted inputs.

Invalid/noisy raw attempts were removed from the report artifact set; `_raw/README.md` documents what was discarded and why.

Policy:

- Inspector can view analytics.
- Inspector can edit assigned projects.
- Inspector cannot create, delete, archive, or remove projects.
- Inspector must not see other roles' trash records.
- Engineer and office technician are project-management roles, not account-admin roles.
- Role changes are performed through the real admin account and backend RPC, then verified with real sessions.

Result:

This run is not a full pass. The tablet Gallery/Toolbox crash is fixed and retested on both devices, but role matrix testing still exposes open permission-boundary, sync, RLS-log, and S21 overflow failures.
