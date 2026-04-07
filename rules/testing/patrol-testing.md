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

Testing infrastructure for unit, golden, widget harness, and HTTP driver E2E
tests.

## Hard Constraints

- **CI is the primary test runner.** Use `gh run view --log-failed` for failure details.
- **Always** use `pwsh -Command "..."` wrapper. Never run `flutter` or `dart` directly in Git Bash.
- **NEVER** `Stop-Process -Name 'dart'` because that can kill MCP servers. Only kill `construction_inspector`.
- **Never** use hardcoded `Key('...')`. Use `TestingKeys` from `lib/shared/testing_keys/`.
- **Lint rule T6** blocks `patrol` and `flutter_driver` imports. Do not add Patrol-style code.
- Sync-relevant screens must remain inspectable through driver contracts, not widget-tree scraping.

## Testing Strategy

1. **Unit and widget tests** live under `test/`.
2. **Golden tests** live under `test/golden/`.
3. **Widget harness** uses `lib/test_harness.dart` for isolated screen interaction.
4. **HTTP driver E2E** uses `lib/main_driver.dart` plus `lib/core/driver/`.

## Driver Surface

| File | Purpose |
|------|---------|
| `lib/main_driver.dart` | HTTP driver entrypoint |
| `lib/test_harness.dart` | Widget harness entrypoint |
| `lib/core/driver/screen_registry.dart` | Bootstrappable screen builders |
| `lib/core/driver/screen_contract_registry.dart` | Stable screen verification contracts |
| `lib/core/driver/flow_registry.dart` | Declarative multi-screen journeys |
| `lib/core/driver/driver_diagnostics_handler.dart` | Diagnostics endpoints including `/diagnostics/screen_contract` |

## Contract Expectations

When a sync-relevant screen changes, update all of the following together:
- root `TestingKeys`
- `screen_registry.dart`
- `screen_contract_registry.dart`
- `flow_registry.dart`
- any targeted driver/widget tests

The preferred runtime inspection endpoint is `/diagnostics/screen_contract`
because it exposes the active route, screen id, root sentinel, and contract
metadata in one payload.
