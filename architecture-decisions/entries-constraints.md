# Entries Constraints

**Feature**: Entry Management (Daily Inspection Logs)
**Scope**: All code in `lib/features/entries/` and entry lifecycle logic

---

## Hard Rules (Violations = Reject)

### Offline-First Writes
- ✗ No requiring network connection to create/edit entries
- ✓ All entry writes (create, update, delete) must succeed locally first (SQLite)
- ✓ Queued for sync, not immediately pushed to Supabase
- ✗ No "save to draft, upload later" modal — users see success immediately

**Why**: Inspectors work on construction sites with spotty networks; must not block workflow.

### Draft/Submitted Workflow
- ✓ Entry states: DRAFT → SUBMITTED (two states, forward transition only)
- ✓ SUBMITTED → DRAFT is allowed via `undoSubmission()` (intentional reversal for correction workflows)
- ✓ SUBMITTED entries read-only (block all edits in UI)
- ✗ No additional intermediate states

**Why**: Immutable submitted entries prevent audit log corruption; simple two-state workflow prevents confusion.

### Date-Scoped Queries
- ✗ No loading "all entries ever" without date filter
- ✓ All queries must include date range (startDate, endDate) or current_date ±N days
- ✓ Default view: Today's entries only
- ✗ No infinite scroll loading past entries (pagination required)

**Why**: Prevents memory overload and poor UX with 1000+ entries.

### Entry-Project Relationship
- ✗ No moving entry between projects after creation
- ✓ Entry.project_id immutable after creation (set at write time, never updated)
- ✓ Querying entries by project_id must enforce this constraint in repository

**Why**: Prevents sync conflicts and audit trail ambiguity.

### Workflow Metadata
- ✓ Entry must include: id, project_id, location_id (FK), created_at, submitted_at (nullable), status
- ✗ No optional metadata (all fields required for validation)
- ✓ Timestamps in UTC, server-side generated on sync validation
- ✓ location_id is a direct FK to locations table (not a junction table)

**Why**: Audit trail consistency; prevents incomplete state tracking.

---

## Soft Guidelines (Violations = Discuss)

### Performance Targets
- Load today's entries: < 500ms
- Create entry: < 100ms (SQLite write only)
- Transition DRAFT→SUBMITTED: < 200ms
- Querying 30-day window: < 1 second

### Bulk Operations
- If bulk-editing 10+ entries: Show loading indicator, queue edits, confirm completion
- Recommend: Limit UI bulk edit to <= 50 entries per operation

### Test Coverage
- Target: >= 85% for entry workflows
- Scenarios: Draft creation, draft→submitted transition, undo submission, date filtering, offline sync, export

---

## Integration Points

- **Depends on**:
  - `projects` (root entity, entries scoped to projects)
  - `locations` (direct FK via location_id, not a junction table)
  - `sync` (entries synced via change_log, no per-record sync_status)
  - `photos` (entries can attach photos, but photos optional)
  - `contractors` (entries can reference contractor personnel)
  - `quantities` (entries can reference bid items)
  - `forms` (entries can have form attachments)

- **Required by**:
  - `dashboard` (home screen shows recent entries)
  - `quantities` (variance tracking uses entries as source)
  - `sync` (entries primary data entity to sync)
  - `pdf` (entry export to PDF)

- **Capabilities**:
  - Entry export (PDF generation via export use case)
  - Form attachments (entries can reference form submissions)
  - Filtering by date range, project, location, and status

---

## Performance Targets

- Load today's entries: < 500ms
- Create entry: < 100ms (local SQLite)
- State transitions: < 200ms
- Date-range query (7-30 days): < 1 second

---

## Testing Requirements

- >= 85% test coverage for entry workflows
- Unit tests: Two-state workflow transitions (draft/submitted), undo submission, date filtering, immutability
- Integration tests: Offline create→sync→verify in Supabase
- Contract tests: Entry-project relationship immutability, workflow state machine
- Offline scenario: Create 10 entries offline, go online, verify all synced in correct state

---

## Reference

- **Architecture**: `docs/features/feature-entries-architecture.md`
- **Shared Rules**: `architecture-decisions/data-validation-rules.md`
- **Sync Integration**: `architecture-decisions/sync-constraints.md`
