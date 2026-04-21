# Testing Cleanup Inventory

Generated: 2026-04-21

## Preserved Compact Results

These compact result/index artifacts were retained as the durable local summary
surface before deleting bulky generated output:

- `.codex/reports/2026-04-18-all-test-results-result-index.md`
- `.codex/reports/2026-04-18-all-test-results-result-index.json`
- `.codex/reports/2026-04-18-enterprise-sync-soak-result-index.md`
- `.codex/reports/2026-04-18-enterprise-sync-soak-result-index.json`
- `.codex/reports/2026-04-21-testing-output-audit.md`
- `.codex/plans/2026-04-21-testing-results-and-ui-flow-standardization-spec.md`

## Deleted Generated Artifacts

The cleanup removed cold generated build/test residue and debug APK output after
confirming the canonical runtime results root was already clean:

- `.dart_tool/hooks_runner/shared/dartcv4/build`
  - `37,736` files
  - about `5,616.00 MB`
- `.dart_tool/flutter_build`
  - `118` files
  - about `953.17 MB`
- `build`
  - `3,877` files
  - about `4,149.17 MB`
- `packages/flusseract/android/.cxx`
  - `12,806` files
  - about `1,401.26 MB`
- `releases/android/debug/*.apk`
  - `4` files
  - about `1,128.22 MB`
- `releases/android/debug/driver-build-manifest.json`
  - `1` file
- `releases/android/debug/device-state/*.json`
  - `5` files

Approximate reclaimed total:

- `54,547` files
- about `12.94 GB`

## Canonical Results State

- `tools/testing/test-results/` exists and remains the only repo-owned runtime
  test-results root.
- `.claude/test-results/` does not exist.
- `tools/testing/runs/` does not exist.

## Intentionally Not Deleted

- `test/features/pdf/extraction/**`
  - tracked fixtures/baselines, not runtime junk
- `.dart_tool/` core metadata outside the deleted build subtrees
  - active editor/tooling state
- `android/.gradle/`
  - active Gradle daemon cache, not a testing results root
- `.claude/logs/`
  - agent/archive notes, not runtime test-results output
