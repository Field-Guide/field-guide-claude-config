# CI Cleanup, Doc Drift Refresh, And Analyzer Issue Remediation

## Summary

- Remove GitHub CI/nightly soak execution paths entirely: no sync soak test, no nightly soak workflow, no backend/RLS soak auto-issue flow.
- Keep fast deterministic sync safety checks that are not soak processes: schema contracts, static sync architecture checks, rollback guards, RLS/schema guards, and normal targeted tests.
- Refresh doc drift around the current maintained doc surface instead of the deleted legacy `.claude/docs/features/*` and `.claude/architecture-decisions/*` tree.
- Fix analyzer issues as real code hygiene work, and fix CI so analyzer failures are reported accurately.
- Preserve current uncommitted Supabase migration cleanup as a separate decision before implementation.

## Todo

- [ ] Review the three existing uncommitted files from the prior CI investigation:
  - `supabase/migrations/20260510160000_security_definer_private_wrappers.sql`
  - `supabase/rollbacks/20260510160000_rollback.sql`
  - `test/features/sync/application/server_hint_plumbing_test.dart`
- [ ] Decide whether to keep them in this branch as the staging schema fix or move them to a separate commit.
- [ ] Do not overwrite or discard them without explicit intent.
- [ ] Delete or fully disable `.github/workflows/nightly-soak.yml`.
- [ ] Remove soak steps from `.github/workflows/quality-gate.yml`.
- [ ] Remove nightly soak support from `tools/ci/github_auto_issue_policy.py`.
- [ ] Update `.github/pull_request_template.md` to remove soak checklist items.
- [ ] Keep normal CI checks that are not soak.
- [ ] Fix analyzer step in `.github/workflows/quality-gate.yml` so `flutter analyze | tee` cannot mask failures.
- [ ] Remove or correct stale `tools/Clear-FlutterTestProcesses.ps1` references if still reachable after soak removal.
- [ ] Fix the staging schema gate migration error by removing stale `debug_emit_sync_hint_self` wrapper references.
- [ ] Keep `staging-schema-gate.yml` unless separately deciding to remove schema hash parity.
- [ ] Regenerate/update `.claude/doc-drift-map.json` to reference maintained docs only.
- [ ] Remove stale doc-drift targets such as deleted `.claude/docs/features/*` and `.claude/architecture-decisions/*`.
- [ ] Add current doc-drift zones for `.github/workflows/**`, `lib/core/router/**`, `lib/core/database/**`, `lib/features/pay_applications/**`, `lib/features/signatures/**`, `lib/features/analytics/**`, `.claude/skills/**`, `.claude/agents/**`, `.claude/rules/**`, and `.codex/**`.
- [ ] Update `doc-drift.yml` so missing mapped docs are reported as map defects, not valid review targets.
- [ ] Update `.claude/skills/implement/references/architecture-guide.md` feature count, router backend, and schema version.
- [ ] Update `docs/DEVELOPER_DOCS.md` schema version and removed soak claims.
- [ ] Update `.claude/skills/audit-docs/SKILL.md` to include selected repo `docs/` in audit scope.
- [ ] Update `.claude/skills/resume-session/SKILL.md` to replace old feature-doc/architecture-decision references with bridge/rules/current-doc model.
- [ ] Replace deprecated `SnackBarHelper` usage with `AppSnackbar`.
- [ ] Replace deprecated `ContextualFeedbackOverlay` usage with `AppContextualFeedback`.
- [ ] Replace deprecated `SearchBarField` usage with `AppSearchBar`.
- [ ] Replace deprecated `tableRows` test/model usage with `responseData.test_rows`.
- [ ] Replace deprecated `dbService` test usage with the current datasource seam.
- [ ] Remove stale unnecessary ignores in `lib/main.dart` and `lib/main_driver.dart`.
- [ ] Investigate and fix the `undefined_lint` source from the GitHub analyzer output.
- [ ] Do not lower analyzer severity to hide issues.
- [ ] Document VS Code versus GitHub analyzer root causes in the PR/checklist.
- [ ] Update developer docs/PR template to tell engineers to run the same command CI runs: `flutter analyze`.
- [ ] Run `flutter analyze`.
- [ ] Run `dart run custom_lint`.
- [ ] Run relevant targeted tests for changed analyzer call sites.
- [ ] Run retained CI helper scripts affected by workflow cleanup.
- [ ] Push branch and verify GitHub checks no longer run soak jobs.
- [ ] Confirm GitHub analyzer failure/pass matches local `flutter analyze`.
- [ ] Confirm doc drift check posts current docs only and does not point to deleted paths.

## Assumptions

- “Get rid of sync soak test, nightly soak, and anything to do with those processes” means remove CI/nightly/auto-issue soak execution, not delete every manual sync diagnostic tool unless it is solely soak-specific.
- Long-running backend/RLS soak is no longer a merge gate.
- Static sync architecture checks and schema/RLS validation remain valuable and should stay.
- Analyzer issues should be fixed in code rather than suppressed.
