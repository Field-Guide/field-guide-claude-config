---
paths:
  - "lib/core/database/**/*.dart"
---

# Database Schema

- Use plural snake_case table names and snake_case column names.
- Index foreign keys and other columns that drive frequent filters or joins.
- Use `_addColumnIfNotExists` for additive migration safety.
- Increment the database version with schema changes.
- Update `schema_verifier.dart` and the relevant schema tests with every table or column change.
- Keep `sync_status` deprecated; `change_log` remains the sync tracker.
- Use parameterized SQL and keep `PRAGMA` handling on the `rawQuery` path.
