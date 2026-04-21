# Testing Results And UI Verification Standardization To-Do Spec

## Summary

This spec standardizes all testing outputs into one repo-owned results surface,
removes `.claude/test-results` as a runtime artifact location, reduces result
sprawl to a compact readable contract, and splits the testing program into two
clear lanes:

- `ui-flow`: forward/backward app verification, widget/button reachability,
  auth/routing correctness, form fidelity, PDF preview, and export validation.
- `sync-flow`: multi-device sync, concurrency, and contention stress only.

The maintained AI-agent source of truth remains the Claude directory. `.codex`
continues to exist only as a filesystem alias to `.claude/codex`, not as a
second maintained context system.

## To-Do Checklist

### 1. Audit And Reference Docs

- [x] Write a compact audit markdown to
  `.codex/reports/2026-04-21-testing-output-audit.md`.
- [x] Include current output-volume findings:
  - `tools/testing/runs` currently contains about `19,043` files / `3.88 GB`.
  - `.claude/test-results` currently contains about `15,038` files / `1.41 GB`.
  - Combined runtime result sprawl is about `34,081` files / `5.29 GB`.
- [x] Include current root causes:
  - mirror-tree publication under `actors/`, `logs/`, `screenshots/`,
    `records/local`, `records/remote`
  - per-step sidecar explosion
  - repeated summary/timeline/index duplication across root, actor, and phase
    paths
  - mixed human and raw machine artifacts in the same folders
- [x] Include recent live-run findings worth preserving before cleanup:
  - role-sweep contract mismatch
  - collaboration preflight metric mismatch
  - contention `conflict_log` query issue
  - photo proof timing / change-log proof fragility
- [x] Write this todo spec to
  `.codex/plans/2026-04-21-testing-results-and-ui-flow-standardization-spec.md`.

### 2. Context Bridge And Source-Of-Truth Cleanup

- [x] Audit the current `.codex` bridge and document the final policy.
- [x] Preserve `.claude/codex` as the maintained Codex content target.
- [x] Preserve `.codex` only as a symlink/junction alias to `.claude/codex`.
- [x] Remove workflow/docs/process language that implies `.codex` is a separate
  maintained source of truth from the live bridge docs.
- [x] Standardize the bridge docs to say:
  - Claude directory is the single maintained AI-agent reference system.
  - `.codex` is a compatibility alias only.
- [x] Consolidate agent-instruction and bridge language to one authoritative
  maintained location: `.claude/codex`, reached through `.codex`.

### 3. Results Directory Standardization

- [x] Deprecate `tools/testing/runs/`.
- [x] Create the new canonical runtime results root:
  `tools/testing/test-results/`.
- [x] Stop all new writes to `.claude/test-results/`.
- [x] Stop all new writes to `tools/testing/runs/`.
- [x] Update the main testing entrypoints to resolve outputs into
  `tools/testing/test-results/`.
- [x] Make `tools/testing/test-results/` the only repo-owned runtime
  test-results directory.
- [x] Remove `.claude/test-results/` after the audit artifacts are created and
  retained.
- [x] Clean out legacy runtime results from `tools/testing/runs/` after
  migration is in place.
- [x] Ensure future runtime outputs stay inside the canonical repo-owned results
  root only.

### 4. Compact Output Contract

- [x] Replace the top-level artifact sprawl with one compact per-run contract.
- [x] Keep only these top-level files by default:
  - `report.md`
  - `summary.json`
  - `artifacts.json`
  - `manifest.json` when needed for multi-actor/lab context
- [x] Make `report.md` the main human-readable output.
- [x] Make `summary.json` the machine-readable contract.
- [x] Make `artifacts.json` the canonical retained-evidence manifest.
- [x] Default successful compact runs to contract-only retention.
- [x] Keep retained raw evidence under `raw/` only when the run fails, warns,
  or explicitly requests broader retention.

### 5. Artifact Retention And De-Duplication

- [x] Remove default mirror publication into:
  - `actors/`
  - `logs/`
  - `screenshots/`
  - `records/local`
  - `records/remote`
- [x] Replace mirror trees with references in `artifacts.json`.
- [x] Add a compact post-run compaction step before a run is considered
  complete.
- [x] Default standard runs to compact mode.
- [x] Add an explicit forensic/archival mode that preserves expanded raw
  evidence by request across every runner.
- [x] Collapse the remaining per-step raw sidecars further inside the sync-flow
  internals.

### 6. Output-Writing Architecture Refactor

- [x] Introduce one canonical output-contract module for the runners.
- [x] Update entrypoint path plumbing to use the new contract/root helpers.
- [x] Refactor result publication so it builds summaries/manifests instead of
  copied artifact trees.
- [x] Make launcher, UI Flow, Sync Flow, and live-soak surfaces write under the
  same canonical results root.
- [x] Keep `timeline.html` optional, not default top-level output.
- [x] Ensure every compacted run is understandable from `report.md` without
  opening dozens of sidecar files.

### 7. UI-Flow Program Expansion

- [x] Promote `ui-flow` to the primary verification lane in the testing docs.
- [x] Preserve the existing Sync Dashboard flow as the first canonical `ui-flow`
  entrypoint.
- [x] Expand the concrete implemented UI flows beyond the current
  Sync Dashboard coverage.
- [x] Organize feature UI flows by `forward_happy`, `backward_traversal`,
  route/auth checks, and fidelity/export subflows.

### 8. Forms, PDF, And Export Verification

- [x] Add form-specific UI flows for open/save/reload fidelity.
- [x] Add PDF preview verification flows for open/render/back navigation.
- [x] Add export verification flows for reachability, completion, file
  existence, readability, and mapped-data correctness.
- [x] Treat broken mapping or stale preview/export data as first-class failures.

### 9. Sync Harness As A Separate Lane

- [x] Keep the current sync harness as the specialized stress/concurrency lane.
- [x] Define `sync-flow` as the stress/concurrency lane in the testing docs.
- [x] Add actor-count modifiers so runs can explicitly target 1, 2, 3, or 4
  devices from the main sync entrypoint.
- [x] Keep sync outputs under the same compact canonical output contract.

### 10. Cleanup Execution Plan

- [x] Preserve only the audit markdown and todo spec before cleanup.
- [x] Remove `.claude/test-results/`.
- [x] Remove legacy `tools/testing/runs/`.
- [x] Re-home any intentionally retained historical summaries into
  `tools/testing/test-results/` only if truly needed.
- [x] Do not retain raw legacy artifact sprawl by default going forward.
- [x] Add ignore/retention guidance so future runtime results do not recreate
  the current explosion.

## Acceptance Criteria

- [x] One canonical runtime results root exists: `tools/testing/test-results/`.
- [x] `.claude/test-results/` is no longer used for new writes.
- [x] No new run creates mirrored `actors/logs/screenshots/records` trees by
  default.
- [x] A standard successful run is understandable from `report.md` and
  `summary.json`.
- [x] A standard failed run retains raw evidence through `artifacts.json` and
  `raw/`.
- [x] `.claude/codex` is the maintained Codex context source; `.codex` is
  alias-only in the bridge docs.
- [x] `ui-flow` is documented as the primary verification lane.
- [x] `sync-flow` remains available as a separate specialized stress lane.
- [x] Forms, PDF preview, export, and mapping fidelity are implemented as
  concrete UI flows, not just backlog intent.

## Defaults Chosen

- [x] Canonical results path: `tools/testing/test-results/`
- [x] Default retention mode: compact
- [x] Human primary artifact: `report.md`
- [x] Machine primary artifact: `summary.json`
- [x] Claude directory remains the single maintained AI-agent source of truth
- [x] `ui-flow` is the primary future verification lane
- [x] `sync-flow` continues as a specialized multi-device stress lane
