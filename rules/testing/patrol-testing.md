---
paths:
  - "integration_test/**/*.dart"
  - "test/**/*.dart"
  - "lib/shared/testing_keys/**"
  - "lib/core/driver/**"
  - "lib/test_harness.dart"
  - "lib/main_driver.dart"
---

# Testing Constraints

Testing infrastructure for unit, golden, widget harness, and HTTP driver E2E tests.

## Hard Constraints

- **CI is the primary test runner.** Use `gh run view --log-failed` for failure details.
- **Always** use `pwsh -Command "..."` wrapper. Never run `flutter` or `dart` directly in Git Bash -- it silently fails.
- **NEVER** `Stop-Process -Name 'dart'` -- kills MCP servers. Only kill `construction_inspector`.
- **Never** use hardcoded `Key('...')` -- always use `TestingKeys` classes from `lib/shared/testing_keys/`.
- **Lint rule T6** blocks `patrol` and `flutter_driver` imports. Do not copy Patrol-style code.

## Testing Strategy (4-Tier)

1. **Unit tests** -- `test/` for models, repositories, providers, and services
2. **Golden tests** -- `test/golden/` for pixel-level visual regression (~95 baselines)
3. **Widget harness** -- `lib/test_harness.dart` + `harness_config.json` for isolated screen interaction
4. **HTTP driver E2E** -- `lib/main_driver.dart` + `lib/core/driver/` for full integration automation

## Key Entry Points

| File | Purpose |
|------|---------|
| `lib/main_driver.dart` | HTTP test driver entrypoint (NOT production) |
| `lib/test_harness.dart` | Widget harness entrypoint |
| `lib/core/driver/screen_registry.dart` | Screen key -> widget builder mapping |
| `lib/core/driver/flow_registry.dart` | Multi-screen journey definitions |

> For run commands, harness setup, and flow details, see `.claude/skills/implement/references/testing-guide.md`
