---
paths:
  - "supabase/**/*"
  - "lib/features/sync/**/*.dart"
---

# SQL Cookbook for Supabase

**PostgreSQL 17** | 57 migrations in `supabase/migrations/`

## Schema Migrations

Create migrations in `supabase/migrations/` with timestamp naming:
```bash
supabase migration new add_caption_to_photos
# Creates: supabase/migrations/20260114000000_add_caption_to_photos.sql
```

Migration file format:
```sql
-- Add column
ALTER TABLE photos ADD COLUMN IF NOT EXISTS caption TEXT;

-- Add index
CREATE INDEX IF NOT EXISTS idx_photos_caption ON photos(caption);

-- Add constraint
ALTER TABLE photos ADD CONSTRAINT check_filename_not_empty
  CHECK (filename IS NOT NULL AND filename != '');
```

## Performance Optimization

```sql
-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM daily_entries WHERE project_id = 'x';

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes ORDER BY idx_scan DESC;

-- Find slow queries
SELECT query, mean_time, calls FROM pg_stat_statements
ORDER BY mean_time DESC LIMIT 10;

-- Check table sizes
SELECT tablename, pg_size_pretty(pg_total_relation_size(tablename::text)) as size
FROM pg_tables WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(tablename::text) DESC;
```

## Row Level Security (RLS)

**CRITICAL**: This project uses multi-tenant **company-scoped** RLS, NOT user-scoped.
All policies gate on `get_my_company_id()`, never on `auth.uid() = user_id`.

### Primary pattern -- tables with `company_id` column

```sql
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- SELECT: users see rows from their company
CREATE POLICY "company_select" ON projects FOR SELECT TO authenticated
  USING (company_id = get_my_company_id());

-- INSERT: users can only insert for their company
CREATE POLICY "company_insert" ON projects FOR INSERT TO authenticated
  WITH CHECK (company_id = get_my_company_id());

-- UPDATE: company-scoped, non-viewers only
CREATE POLICY "company_update" ON projects FOR UPDATE TO authenticated
  USING (company_id = get_my_company_id() AND NOT is_viewer());

-- DELETE: company-scoped, non-viewers only
CREATE POLICY "company_delete" ON projects FOR DELETE TO authenticated
  USING (company_id = get_my_company_id() AND NOT is_viewer());
```

### Child-table pattern -- join through parent to reach `company_id`

Tables without a direct `company_id` column (e.g. `entry_equipment`) join through their parent:

```sql
CREATE POLICY "company_entry_equipment_select" ON entry_equipment
  FOR SELECT TO authenticated
  USING (entry_id IN (
    SELECT id FROM daily_entries WHERE project_id IN (
      SELECT id FROM projects WHERE company_id = get_my_company_id()
    )
  ));
```

### Idempotent migration pattern

Always drop before recreating to avoid duplicate-policy errors:

```sql
DROP POLICY IF EXISTS "company_select" ON projects;
CREATE POLICY "company_select" ON projects FOR SELECT TO authenticated
  USING (company_id = get_my_company_id());
```

> **Note (generic Supabase):** The default Supabase docs show `auth.uid() = user_id` patterns.
> Those are **not used** in this project. Do not introduce user-scoped policies.

## Storage Buckets

```sql
-- Create storage bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('entry-photos', 'entry-photos', false);

-- Storage policy for uploads
CREATE POLICY "Users can upload photos" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'entry-photos' AND auth.role() = 'authenticated');

-- Storage policy for downloads
CREATE POLICY "Users can download own photos" ON storage.objects FOR SELECT
USING (bucket_id = 'entry-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## Useful Indexes

```sql
-- Composite index for common queries
CREATE INDEX idx_entries_project_date ON daily_entries(project_id, date DESC);

-- [REMOVED] Partial index on sync_status -- sync_status columns no longer exist.
-- The sync engine now uses change_log triggers. Do NOT create sync_status indexes.

-- GIN index for full-text search
CREATE INDEX idx_entries_activities_search ON daily_entries USING GIN(to_tsvector('english', activities));
```

## Database Functions

```sql
-- Auto-update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_timestamp BEFORE UPDATE ON daily_entries
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Aggregate function for entry counts
CREATE OR REPLACE FUNCTION get_project_stats(p_project_id TEXT)
RETURNS TABLE(total_entries BIGINT, total_locations BIGINT, total_contractors BIGINT) AS $$
BEGIN
  RETURN QUERY SELECT
    (SELECT COUNT(*) FROM daily_entries WHERE project_id = p_project_id),
    (SELECT COUNT(*) FROM locations WHERE project_id = p_project_id),
    (SELECT COUNT(*) FROM contractors WHERE project_id = p_project_id);
END; $$ LANGUAGE plpgsql;
```

## Custom Helper Functions (used in RLS policies)

| Function | Returns | Purpose |
|----------|---------|---------|
| `get_my_company_id()` | `UUID` | Returns `company_id` for the current `auth.uid()` from `user_profiles` (approved users only). `SECURITY DEFINER`. |
| `is_approved_engineer()` | `BOOLEAN` | True if current user has role `engineer` and status `approved`. `SECURITY DEFINER`. |
| `is_viewer()` | `BOOLEAN` | True if current user has role `viewer` and status `approved`. Used to block write operations. `SECURITY DEFINER`. |
| `is_approved_admin()` | `BOOLEAN` | True if current user has role `admin` and status `approved`. Used in admin-only RPCs. `SECURITY DEFINER`. |

All four are `STABLE`, use `SET search_path = public`, and are defined in migrations under `supabase/migrations/`.

## Edge Function: `daily-sync-push`

Location: `supabase/functions/daily-sync-push/index.ts`

Sends sync-hint notifications to devices in a target company. Dual delivery:

- **FCM silent push** -- sends a data-only message to all registered FCM tokens for the company's users. High priority for targeted hints, normal priority for daily cron.
- **Supabase Realtime broadcast** -- fans out `sync_hint` events to active private channels for the company (via `get_active_sync_hint_channels` RPC).
- **Expired FCM token cleanup** -- deletes tokens that return `UNREGISTERED` or `INVALID_ARGUMENT` from FCM.
- **Authorization** -- service role key only (checked via `Authorization` header or `apikey` header). Returns 401 for all other callers.
- **Company-scoped targeting** -- when `company_id` is provided in the request body, only that company's devices are notified. Without it, all tokens are targeted (daily cron mode).

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `PGRST205` | Table not found | Check spelling, run migration |
| `23503` | FK violation | Ensure parent record exists |
| `23505` | Unique violation | Check for duplicate IDs |
| `42501` | RLS policy denied | Check policies or use service role |
| `42P01` | Undefined table | Run pending migrations |
