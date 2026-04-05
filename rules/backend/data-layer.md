---
paths:
  - "lib/features/**/data/**/*.dart"
  - "lib/core/database/**/*.dart"
  - "lib/services/**/*.dart"
---

# Backend/Data Layer — Constraints

Data layer follows feature-first organization with offline-first sync via SQLite triggers.

## Hard Constraints

- **Feature-first**: all data layer code lives in `lib/features/[feature]/data/`
- **`lib/data/` is EMPTY** — legacy directory, no files
- **Database path**: `lib/core/database/database_service.dart` (NOT `lib/services/`)
- **Soft-delete is the default**: `delete()` = soft-delete (sets `deleted_at`), `hardDelete()` for permanent removal. All reads auto-filter `deleted_at IS NULL`.
- **change_log is trigger-only**: 20 tables have SQLite triggers gated by `sync_control.pulling='0'`. Never manually INSERT into change_log. No per-model `syncStatus` field.
- **Typed DI containers** (CoreDeps, AuthDeps, etc.) — no ad-hoc construction of datasources/repos
- **Provider tiers 1-2 are NOT in widget tree** — created in AppInitializer. Only tiers 0, 0.5, 3-5 are widget-tree providers.
- **No raw SQL in `presentation/` or `di/`** (lint-enforced: `no_raw_sql_in_presentation`)
- **No datasource imports in `presentation/`** (lint-enforced: `no_datasource_in_presentation`)
- **SchemaVerifier must be updated** with any schema change (tables or columns)
- **Schema changes touch 5 files**: database_service, schema/*.dart, schema_verifier, + 2 test files
- **PRAGMAs via `rawQuery`** — Android API 36 rejects PRAGMA via `execute()`
- **`is_builtin=1` rows are server-seeded** — triggers skip them, cascade-delete skips them, push skips them

> For code patterns, templates, and examples, see `.claude/skills/implement/reference/data-layer-guide.md`
