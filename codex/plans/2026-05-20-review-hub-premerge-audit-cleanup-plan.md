# Review Hub Pre-Merge Audit Cleanup Plan

## Goal

Clean up the remaining merge risk on `feature/review-hub-dashboard-scope`
before merge by finishing the branch audit refactors, removing stale paths and
dead expectations, and bringing the full Flutter test suite back to a useful
signal.

## Live Task List

- [ ] Preserve existing audit refactors already in the working tree.
- [x] Fix test files that are named `*_test.dart` but have no `main()` because
  they are intended as part files or fixtures.
- [ ] Fix stale fixture expectations, including schema-version and driver
  diagnostic shape drift.
- [ ] Fix stale GOCR fixture paths and PDF hardening manifest documentation
  expectations.
- [ ] Fix PDF extraction corpus drift and expectation drift.
- [ ] Fix sync coordinator expectations around deferred auth, lock
  contention, and shared sync gates.
- [ ] Fix sync diagnostic expectations around background/non-error skip states.
- [ ] Fix sync error-classifier contracts for `already in progress` behavior.
- [ ] Fix delete/tombstone verification and local-trash test fixtures affected
  by review-comment delete graph additions.
- [ ] Fix form-response repository expectation drift for exported/editable and
  submitted/locked response behavior.
- [ ] Fix export fixture drift for Water Main Pressure Test static PDF fields.
- [ ] Fix PDF extraction quality, row parser, row merger, grid, and repair-log
  stale expectations only where they reflect current intended behavior.
- [ ] Fix stale package patch contract test so it validates the current local
  `printing` patch accurately.
- [ ] Rerun targeted failing groups after each fix slice.
- [ ] Rerun `flutter analyze`, `dart run custom_lint`, migration rollback
  validation, diff checks, and the full Windows Flutter test suite.

## Guardrails

- Do not use `MOCK_AUTH`.
- Do not change product functionality for this cleanup pass.
- Treat failures as stale fixtures, stale paths, discovery/naming problems, or
  test-helper drift unless code review proves a real branch regression.
- Production-code edits are limited to behavior-preserving refactors or fixing
  branch-caused implementation defects already introduced by this branch.
- Prefer production seams and real behavior over test-only hooks.
- Do not change PDF extraction truth data based on row math or checksum
  evidence.
- Keep branch cleanup scoped to stale fixtures, real code quality issues, and
  branch-caused regressions.
