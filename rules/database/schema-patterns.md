---
paths:
  - "lib/core/database/**/*.dart"
---

# Database Schema Patterns

36 tables across 15 schema files. Current version: check `database_service.dart`.

## Hard Constraints

- **Table naming**: plural snake_case (`daily_entries`, `bid_items`). Junction tables: `entry_` prefix.
- **Column naming**: snake_case. FKs: `{entity}_id`. Timestamps: `created_at`, `updated_at`, `synced_at`.
- **ALWAYS** index FK columns and frequently filtered columns.
- **ALWAYS** use `_addColumnIfNotExists` helper for safe ALTER TABLE migrations.
- **ALWAYS** increment database version with schema changes.
- **SchemaVerifier** (`schema_verifier.dart`) must be updated alongside any table/column addition.
- **`sync_status` columns are DEPRECATED** — only `change_log` (trigger-populated) is used.
- **Soft-delete is default**: `deleted_at` / `deleted_by` columns. `delete()` = soft-delete, `hardDelete()` for permanent.
- **`onOpen` resets `sync_control.pulling` to `'0'`** — crash recovery for stuck trigger suppression.
- **PRAGMAs via `rawQuery`** — Android API 36 rejects via `execute()`. Move to `onConfigure` callback.
- **Use parameterized queries** — never hardcoded IDs in SQL strings.
- Schema changes touch 5 files: `database_service.dart`, `schema/*.dart`, `schema_verifier.dart`, + 2 test files.

> For code examples, migration templates, and debugging, see `.claude/skills/implement/references/schema-patterns-guide.md`
