---
paths:
  - "lib/features/sync/**/*.dart"
---

# Sync Architecture — Constraints & Invariants

5-layer sync system: Presentation > Application > Engine > Adapters > Domain. Entry point is `SyncCoordinator`. Engine is slim (~214 lines) with I/O delegated to `SupabaseSync` (Supabase) and `LocalSyncStore` (SQLite).

## Hard Constraints

- **change_log is trigger-only** — 20 tables have SQLite triggers gated by `sync_control.pulling='0'`. Never manually INSERT into change_log.
- **Trigger suppression MUST use try/finally** — set `pulling='1'` before pull, reset to `'0'` in finally. Owned by `LocalSyncStore` via `TriggerStateStore`.
- **SyncErrorClassifier is the single source of truth** for error classification. No Postgres code matching anywhere else.
- **SyncStatus is the single SOT** for transport state (isUploading, isDownloading, lastSyncedAt, errors, isOnline).
- **SyncDiagnosticsSnapshot** is point-in-time, fetched by `SyncQueryService` — it does NOT stream.
- **SyncRegistry order is load-bearing** — defines FK dependency order for push. Parents before children.
- **is_builtin=1 rows are server-seeded** — triggers skip them, push skips them, cascade-delete skips them.
- **No sync_status column** — only change_log is used for tracking pending changes.
- **SyncOrchestrator no longer exists** — use `SyncCoordinator`.

## Error Classification (Security-Critical)

| SyncErrorKind | Postgres/Network Pattern | Retryable |
|---------------|-------------------------|-----------|
| `rlsDenial` | 42501 | No (permanent) |
| `fkViolation` | 23503 | No (permanent) |
| `uniqueViolation` | 23505 | Yes (up to 2, TOCTOU race) |
| `rateLimited` | 429, 503 | Yes (with backoff) |
| `authExpired` | 401, PGRST301, JWT | Yes (after token refresh) |
| `networkError` | SocketException, Timeout, DNS | Yes (with backoff) |
| `transient` | Other retryable | Yes |
| `permanent` | Other non-retryable | No |

RLS denials (42501) are permanent and MUST NOT be retried — they indicate a security boundary violation.

## Enforced Invariants (Lint Rules)

- **S1**: `ConflictAlgorithm.ignore` MUST have rowId==0 fallback (check return value, UPDATE on 0)
- **S2**: change_log cleanup MUST be conditional on RPC success (never unconditional DELETE)
- **S3**: sync_control flag MUST be inside transaction (set pulling='1' inside try/finally)
- **S4**: No sync_status column (deprecated pattern, only change_log)
- **S5**: `toMap()` MUST include project_id for synced child models
- **S8**: `_lastSyncTime` only updated in success path

## Key Flows (Summary)

- **Push**: Local write -> SQLite trigger -> change_log -> ChangeTracker -> PushHandler (FK-ordered) -> SupabaseSync
- **Pull**: SyncEngine -> PullHandler (FK-ordered) -> suppress triggers -> SupabaseSync paginated SELECT -> ConflictResolver -> LocalSyncStore -> restore triggers
- **Request**: Trigger source -> SyncTriggerPolicy -> SyncCoordinator -> ConnectivityProbe -> SyncEngine.run(mode) -> PostSyncHooks

## Gotchas

- Adapters are pure config+conversion — handlers do all I/O
- `pulling` flag reset to `'0'` on every app startup in `DatabaseService.onOpen` to recover from crash-during-pull
- `inspector_forms` triggers have additional `AND NEW.is_builtin != 1` guard
- Never use raw SQL or direct change_log inserts for test data — use app UI (triggers won't fire otherwise)
- SyncProvider no longer exposes `get orchestrator` — use `SyncQueryService` for dashboard data

> For detailed diagrams, class inventories, and procedures, see .claude/skills/implement/reference/sync-patterns-guide.md
