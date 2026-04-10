---
paths:
  - "integration_test/**/*.dart"
  - "test/**/*.dart"
  - "lib/shared/testing_keys/**"
  - "lib/core/driver/**"
  - "lib/test_harness.dart"
  - "lib/main_driver.dart"
---

# Testing

- Test real behavior, not mock presence.
- Do not add test-only methods or lifecycle hooks to production classes.
- Mock only after understanding the real dependency chain and required side effects.
- Prefer real production seams over large mock stacks.
- Use `TestingKeys`, not hardcoded `Key('...')` values.
- Keep sync-visible UI inspectable through the existing driver contracts instead of widget-tree scraping.
- When a sync-relevant screen contract changes, update the driver registry, contract registry, flows, and targeted tests in the same change.
