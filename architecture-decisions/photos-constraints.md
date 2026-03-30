# Photos Constraints

**Feature**: Photo Capture & Management
**Scope**: All code in `lib/features/photos/` and photo lifecycle logic

---

## Hard Rules (Violations = Reject)

### Offline Capture + Storage
- ✗ No requiring network to take photos
- ✓ All photos captured to local device storage (Documents/construction-inspector/)
- ✓ Photo metadata (filename, location, timestamp) written to SQLite immediately
- ✗ No preventing photo capture due to network unavailability
- ✓ Sync job processes photos asynchronously (move to Supabase, update status)

**Why**: Inspectors must photograph site conditions regardless of connectivity.

### Sync via change_log (No Per-Record sync_status)
- ✗ No per-record `sync_status` column — sync tracking is handled by the `change_log` table (local-only SQLite)
- ✓ Photo mutations are recorded in `change_log`; the sync engine processes them
- ✓ UI may show sync progress at the session level, not per-photo
- ✓ Retry failed syncs with exponential backoff (1s, 2s, 4s, 8s, max 3 attempts)

**Why**: Centralized change_log simplifies sync; per-record status columns are deprecated.

### File Lifecycle Management
- ✗ No keeping original high-res photo after upload to Supabase
- ✓ After successful sync: Delete local file from device storage
- ✓ Metadata (photo record in SQLite) persists (reference to `remotePath`)
- ✗ No re-uploading if local file deleted

**Why**: Conserves device storage; Supabase is source of truth.

### Photo-Entry Association
- ✗ No orphan photos (photos not attached to entries)
- ✓ Every photo must have entry_id (required, not nullable)
- ✓ Entry can have multiple photos
- ✗ No moving photos between entries after creation (entry_id immutable)

**Why**: Audit trail clarity; photos must be associated with inspection context.

### Metadata Requirements
- ✓ Photo fields: `id`, `entryId`, `projectId`, `filename`, `filePath` (local device path), `remotePath` (Supabase storage path, nullable until synced), `caption` (nullable), `locationId` (nullable FK to locations), `latitude` (nullable), `longitude` (nullable), `capturedAt` (UTC), `createdAt`, `updatedAt`
- ✗ No per-record `sync_status` — use `change_log` instead
- ✓ Geolocation optional (user can capture without GPS)

**Why**: Complete audit trail; `capturedAt` proves when photo taken. `projectId` enables project-scoped queries.

---

## Soft Guidelines (Violations = Discuss)

### Performance Targets
- Photo capture (UI + file write): < 500ms
- Thumbnail generation (150px square): < 100ms
- Sync photo to Supabase: < 5 seconds per photo (on 4G)
- Load photo gallery (20-100 photos): < 1 second

### Image Optimization
- Recommend: Compress photos to max 2MP before upload
- Recommend: Generate thumbnails for gallery view (not full resolution)

### Test Coverage
- Target: >= 85% for photo workflows
- Scenarios: Capture offline, sync online, failed sync retry, delete after sync

---

## Integration Points

- **Depends on**:
  - `entries` (photos must be attached to entries)
  - `sync` (photos queued for synchronization)
  - `locations` (optional: geotag photo with GPS)

- **Required by**:
  - `entries` (photo reference in entries UI)
  - `dashboard` (recent photos preview)
  - `sync` (photos primary data entity to sync)

---

## Performance Targets

- Photo capture: < 500ms
- Thumbnail generation: < 100ms
- Sync per photo: < 5 seconds (4G)
- Gallery load (20-100 photos): < 1 second

---

## Testing Requirements

- >= 85% test coverage for photo workflows
- Unit tests: File lifecycle, metadata validation, change_log recording
- Integration tests: Capture offline→sync online→verify remotePath populated
- Contract tests: Entry-photo relationship immutability, change_log integration
- Offline scenario: Capture 10 photos, lose network, go online, verify all synced and local files deleted

---

## Reference

- **Architecture**: `docs/features/feature-photos-architecture.md`
- **Shared Rules**: `architecture-decisions/data-validation-rules.md`
- **Sync Integration**: `architecture-decisions/sync-constraints.md`
