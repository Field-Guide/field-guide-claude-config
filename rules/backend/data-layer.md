---
paths:
  - "lib/features/**/data/**/*.dart"
  - "lib/core/database/**/*.dart"
  - "lib/services/**/*.dart"
---

# Data Layer

- Keep data-layer code in feature `data/` folders or the shared database/services owners that already exist.
- Default deletes are soft deletes. Hard delete must stay explicit.
- `change_log` is trigger-owned. Never insert into it manually and do not reintroduce `sync_status` tracking.
- Build datasources and repositories through the typed dependency containers, not ad-hoc constructors in feature code.
- Keep raw SQL out of `presentation/` and `di/`.
- Update `SchemaVerifier` and migration coverage with every schema change.
- Use `rawQuery` for `PRAGMA` calls.
