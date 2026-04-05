---
paths:
  - "supabase/**/*"
  - "lib/features/sync/**/*.dart"
---

# Supabase SQL

PostgreSQL 17 | 57 migrations in `supabase/migrations/`

## Hard Constraints

- **RLS is company-scoped, NOT user-scoped.** All policies gate on `get_my_company_id()`, never `auth.uid() = user_id`.
- **Idempotent migrations**: always `DROP POLICY IF EXISTS` before `CREATE POLICY`.
- **Child-table RLS**: join through parent chain to reach `company_id` (e.g., `entry_equipment` → `daily_entries` → `projects`).
- **No `sync_status` indexes** — deprecated. Sync engine uses `change_log` triggers.
- Helper functions: `get_my_company_id()`, `is_approved_engineer()`, `is_viewer()`, `is_approved_admin()` — all `SECURITY DEFINER`, `STABLE`.
- Edge function `daily-sync-push`: service-role-only, company-scoped FCM + Realtime broadcast.

## Common Errors

| Code | Meaning | Fix |
|------|---------|-----|
| `42501` | RLS denial | Check policies or use service role |
| `23503` | FK violation | Ensure parent record exists |
| `23505` | Unique violation | Check for duplicate IDs |
| `PGRST205` | Table not found | Run pending migration |

> For migration patterns, RLS templates, storage buckets, and functions, see `.claude/skills/implement/references/supabase-sql-guide.md`
