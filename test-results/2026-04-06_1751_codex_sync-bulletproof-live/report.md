# Sync Verification Report
Platform: Windows + S21

## Scope Revocation Live

Status: PASS for stale project-shell cleanup

Before the fix, the S21 project list still showed three stale local projects that were already out of remote scope: `Codex Sync Verify 214446`, `E2E PayApp Sync 20260406-132310`, and `E2E PayApp Sync 20260406-132811`. A live SQLite dump confirmed those shells were no longer in `synced_projects`, which is why the first revocation-only cleanup path never touched them.

After adding the historical scope-repair pass and rerunning full sync on both clients, the repair logs showed `ScopeRevocationCleaner` evicting stale local project shells on both devices. The S21 UI now shows only `Springfield DWSRF` and `VRF-Oakridge aun53`, and a fresh SQLite dump confirmed:
- `projects` count dropped from 5 to 2
- stale project IDs `41088ce9-0eda-4211-b4ea-45c30c99b5a7`, `7b096ba8-e53c-43e6-bb4c-d5485bb2dad6`, and `c75a8278-8faa-49e4-bfde-0bc59ef6ebf4` are gone
- stale `pay_applications` / `export_artifacts` tied to `c75a8278-8faa-49e4-bfde-0bc59ef6ebf4` are gone

Windows also repaired its stale local shells; the project UI now shows only `VRF-Oakridge aun53` for that user scope, and direct driver SQLite checks confirm the old stale project IDs are missing.

## Regression Spot Check

Active in-scope pay-app tombstones survived the cleanup on both devices:
- `pay_applications/03c165e4-fb0f-4eec-813e-3e0562a787ab`
- `export_artifacts/ff83c403-a024-4b3b-aaaa-a10557ead837`

## Remaining Drift

The stale-scope class is fixed, but integrity drift still remains for:
- `entry_equipment`
- `entry_quantities`
- `entry_contractors`
- `inspector_forms`

Those are the next sync defects to isolate and verify.

