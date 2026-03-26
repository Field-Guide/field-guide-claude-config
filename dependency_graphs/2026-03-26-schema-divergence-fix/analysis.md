# Schema Divergence Fix — Dependency Graph

## Direct Changes

### 1. Supabase Migration (NEW)
**File:** `supabase/migrations/20260326100000_schema_alignment.sql`
**Change type:** CREATE
**What:**
- ALTER TABLE project_assignments ADD COLUMN created_by_user_id UUID
- ALTER TABLE project_assignments ADD COLUMN deleted_at TIMESTAMPTZ
- ALTER TABLE project_assignments ADD COLUMN deleted_by UUID
- ALTER TABLE entry_personnel_counts ADD COLUMN created_at TIMESTAMPTZ DEFAULT now()
- Drop stale sync_status columns from daily_entries and photos
- Update RLS UPDATE policy (currently `USING (false)` — needs to allow soft-delete updates)
- Reload PostgREST schema cache

### 2. SQLite Schema: sync_engine_tables.dart
**File:** `lib/core/database/schema/sync_engine_tables.dart:100-112`
**Change type:** MODIFY
**What:** Add `created_by_user_id TEXT`, `deleted_at TEXT`, `deleted_by TEXT` to createProjectAssignmentsTable

### 3. SQLite Migration: database_service.dart
**File:** `lib/core/database/database_service.dart:53` (version bump 40→41)
**File:** `lib/core/database/database_service.dart` (v41 migration block)
**Change type:** MODIFY
**What:**
- Bump version 40→41
- Add v41 migration: _addColumnIfNotExists for project_assignments (created_by_user_id, deleted_at, deleted_by)

### 4. Schema Verifier: schema_verifier.dart
**File:** `lib/core/database/schema_verifier.dart`
**Change type:** MODIFY
**What:**
- Add project_assignments to expectedSchema with all 10 columns
- Add project_id to change_log entry
- Add unassigned_at to synced_projects entry

### 5. ProjectAssignment Model
**File:** `lib/features/projects/data/models/project_assignment.dart:8-76`
**Change type:** MODIFY
**What:** Add `createdByUserId`, `deletedAt`, `deletedBy` fields, update toMap/fromMap/copyWith

### 6. ProjectAssignmentAdapter
**File:** `lib/features/sync/adapters/project_assignment_adapter.dart:10-28`
**Change type:** MODIFY
**What:** Change `supportsSoftDelete => true` (was false)

## Dependent Files (callers/consumers)

| File | Why |
|------|-----|
| `lib/features/projects/data/repositories/project_assignment_repository.dart` | Uses ProjectAssignment.toMap/fromMap — will get new fields automatically |
| `lib/features/projects/presentation/providers/project_assignment_provider.dart` | Creates ProjectAssignment instances — may need createdByUserId param |
| `lib/features/sync/engine/sync_engine.dart:567` (_pushDelete) | Soft-delete routing — now applies to project_assignments |
| `lib/features/sync/engine/integrity_checker.dart:167` (_checkTable) | Already checks adapter.supportsSoftDelete — will work with the change |
| `tools/debug-server/supabase-verifier.js` | verifyCascadeDelete checks project_assignments as hard-deleted — needs update to soft-deleted |
| `test/features/projects/integration/project_lifecycle_integration_test.dart:339` | _createFullSchema — project_assignments schema needs updating |

## Test Files

- `test/features/sync/engine/sync_engine_delete_test.dart` — may need project_assignments soft-delete test
- `test/features/sync/engine/sync_engine_test.dart` — shared helpers
- `test/features/projects/integration/project_lifecycle_integration_test.dart` — schema fixture

## Data Flow

```
ProjectAssignmentProvider.save()
  → ProjectAssignmentRepository.insertAll()
    → SQLite INSERT → change_log trigger
      → SyncEngine._push()
        → _pushUpsert() stamps created_by_user_id
          → upsertRemote() → Supabase (needs column to exist)
        → _pushDelete() stamps deleted_at/deleted_by (NEW for this table)
          → pushDeleteRemote() → Supabase (needs columns to exist)
```

## Blast Radius Summary

- **Direct:** 6 files (1 new SQL, 5 modify)
- **Dependent:** 6 files (may need minor updates)
- **Tests:** 3 files
- **Cleanup:** 0
