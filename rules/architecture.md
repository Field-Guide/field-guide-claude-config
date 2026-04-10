---
paths:
  - "lib/**/*.dart"
---

# Architecture

- Keep the feature-first split: `data/`, `domain/`, `presentation/`, `di/`.
- Use `provider` and `ChangeNotifier` only. Do not introduce Riverpod or a second state-management system.
- Preserve the app flow: screen -> provider -> use case -> repository -> datasource.
- Keep domain code pure Dart. No Flutter imports in `domain/`.
- Build datasources, repositories, and providers through the typed dependency containers in app bootstrap. No ad-hoc wiring.
- Keep raw SQL and datasource imports out of `presentation/`.
- Long-edit screens must expose real screen state through a screen-local controller plus `WizardActivityTracker`, not ad-hoc global flags.
- Prefer existing lint-enforced architecture and ownership rules over adding local exceptions.
