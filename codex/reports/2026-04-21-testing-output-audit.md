# Testing Output Audit

Date: `2026-04-21`

## Scope

This audit preserves the current testing-output state before the runtime result
surface is standardized around `tools/testing/test-results/`.

## Output Volume

- `tools/testing/runs/` currently contains about `19,043` files / `3.88 GB`.
- `.claude/test-results/` currently contains about `15,038` files / `1.41 GB`.
- Combined runtime result sprawl is about `34,081` files / `5.29 GB`.

## Root Causes

- Mirror-tree publication under `actors/`, `logs/`, `screenshots/`,
  `records/local`, and `records/remote`.
- Per-step sidecar explosion from step JSON, evidence JSON, log extracts,
  widget trees, and screenshots landing as siblings for the same operation.
- Repeated summary, timeline, and index duplication across root, actor, and
  phase paths.
- Mixed human-readable and raw machine artifacts sharing the same folders.

## Preserved Live-Run Findings

- Role-sweep contract mismatch.
- Collaboration preflight metric mismatch.
- Same-record contention `conflict_log` query issue.
- Photo proof timing and change-log proof fragility.

## Final Policy

- The Claude directory is the single maintained AI-agent reference system.
- `.claude/codex` remains the maintained Codex content target.
- `.codex` remains only a compatibility alias to `.claude/codex`.
- `tools/testing/test-results/` is the only canonical repo-owned runtime
  testing-results directory.
- `.claude/test-results/` and `tools/testing/runs/` are deprecated runtime
  artifact roots and should not receive new writes.

## Cleanup Intent

- Preserve this audit and the new todo spec before deleting legacy runtime
  result trees.
- Replace mirror publication with `report.md`, `summary.json`,
  `artifacts.json`, and `manifest.json` when multi-actor context requires it.
- Default standard runs to compact retention.
