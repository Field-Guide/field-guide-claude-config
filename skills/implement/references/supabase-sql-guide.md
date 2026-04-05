# Supabase SQL — Procedure Guide

> Loaded on-demand by workers. For constraints and invariants, see `.claude/rules/backend/supabase-sql.md`

## Schema Migrations

```bash
supabase migration new add_caption_to_photos
# Creates: supabase/migrations/20260114000000_add_caption_to_photos.sql
```

```sql
ALTER TABLE photos ADD COLUMN IF NOT EXISTS caption TEXT;
CREATE INDEX IF NOT EXISTS idx_photos_caption ON photos(caption);
```

## RLS Patterns

### Primary pattern — tables with `company_id`
```sql
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "company_select" ON projects FOR SELECT TO authenticated
  USING (company_id = get_my_company_id());

CREATE POLICY "company_insert" ON projects FOR INSERT TO authenticated
  WITH CHECK (company_id = get_my_company_id());

CREATE POLICY "company_update" ON projects FOR UPDATE TO authenticated
  USING (company_id = get_my_company_id() AND NOT is_viewer());

CREATE POLICY "company_delete" ON projects FOR DELETE TO authenticated
  USING (company_id = get_my_company_id() AND NOT is_viewer());
```

### Child-table pattern — join through parent
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
```sql
DROP POLICY IF EXISTS "company_select" ON projects;
CREATE POLICY "company_select" ON projects FOR SELECT TO authenticated
  USING (company_id = get_my_company_id());
```

## Custom Helper Functions

| Function | Returns | Purpose |
|----------|---------|---------|
| `get_my_company_id()` | `UUID` | Company ID for current user (approved only). `SECURITY DEFINER`. |
| `is_approved_engineer()` | `BOOLEAN` | True if role=engineer, status=approved. |
| `is_viewer()` | `BOOLEAN` | True if role=viewer. Blocks write operations. |
| `is_approved_admin()` | `BOOLEAN` | True if role=admin. Admin-only RPCs. |

All are `STABLE`, use `SET search_path = public`.

## Performance Optimization

```sql
EXPLAIN ANALYZE SELECT * FROM daily_entries WHERE project_id = 'x';

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes ORDER BY idx_scan DESC;

-- Find slow queries
SELECT query, mean_time, calls FROM pg_stat_statements
ORDER BY mean_time DESC LIMIT 10;
```

## Storage Buckets

```sql
INSERT INTO storage.buckets (id, name, public) VALUES ('entry-photos', 'entry-photos', false);

CREATE POLICY "Users can upload photos" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'entry-photos' AND auth.role() = 'authenticated');
```

## Useful Indexes

```sql
CREATE INDEX idx_entries_project_date ON daily_entries(project_id, date DESC);

-- GIN for full-text search
CREATE INDEX idx_entries_activities_search ON daily_entries
  USING GIN(to_tsvector('english', activities));
```

## Database Functions

```sql
CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_timestamp BEFORE UPDATE ON daily_entries
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

## Edge Function: `daily-sync-push`

Location: `supabase/functions/daily-sync-push/index.ts`

- FCM silent push to registered tokens for company
- Supabase Realtime broadcast to active channels
- Expired FCM token cleanup (UNREGISTERED/INVALID_ARGUMENT)
- Service role key only (401 for others)
- Company-scoped targeting via `company_id` in request body

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `PGRST205` | Table not found | Check spelling, run migration |
| `23503` | FK violation | Ensure parent record exists |
| `23505` | Unique violation | Check for duplicate IDs |
| `42501` | RLS policy denied | Check policies or use service role |
| `42P01` | Undefined table | Run pending migrations |
