# E2E Sync Verification — Dependency Graph Analysis

**Date**: 2026-03-19
**Spec**: `.claude/specs/2026-03-19-e2e-sync-verification-spec.md`

## Direct Changes

### New Files

| File | Purpose | Agent |
|------|---------|-------|
| `lib/shared/testing_keys/sync_keys.dart` | 7 sync dashboard testing keys | `frontend-flutter-specialist-agent` |
| `tools/verify-sync.ps1` | Supabase REST verification helper | `general-purpose` |
| `.claude/test_results/flow_registry.md` | Persistent flow status tracker | `general-purpose` |

### Modified Files

| File | Lines | Change | Agent |
|------|-------|--------|-------|
| `lib/shared/testing_keys/projects_keys.dart` | 6-111 | Add ~24 new project/sync keys (tabs, filters, dialogs, switcher, assignments) | `frontend-flutter-specialist-agent` |
| `lib/shared/testing_keys/testing_keys.dart` | 1-57 | Add `export 'sync_keys.dart'`, import + re-export in facade | `frontend-flutter-specialist-agent` |
| `tools/debug-server/server.js` | 216-255 | Add `POST /sync/status` + `GET /sync/status` routes, sync status state | `general-purpose` |
| `lib/features/sync/engine/sync_engine.dart` | 176-269 | POST sync lifecycle events to debug server in pushAndPull() | `backend-supabase-agent` |
| `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` | 242-270 | Apply sync testing keys to action tiles, status badge, timestamp | `frontend-flutter-specialist-agent` |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | 140-170, 284-348 | Apply dialog, download, tab keys | `frontend-flutter-specialist-agent` |
| `lib/features/projects/presentation/widgets/project_filter_chips.dart` | 6-37 | Apply filter chip keys (All, On Device, Not Downloaded) | `frontend-flutter-specialist-agent` |
| `lib/features/projects/presentation/widgets/project_tab_bar.dart` | 5-73 | Apply tab keys (My Projects, Company, Archived) | `frontend-flutter-specialist-agent` |
| `lib/features/projects/presentation/widgets/removal_dialog.dart` | 8-103 | Apply dialog button keys (Cancel, Sync & Remove, Delete from Device) | `frontend-flutter-specialist-agent` |
| `lib/features/projects/presentation/widgets/assignments_step.dart` | 8-76 | Apply search field + assignment tile keys | `frontend-flutter-specialist-agent` |
| `lib/features/projects/presentation/widgets/project_empty_state.dart` | 19-97 | Apply browse button key | `frontend-flutter-specialist-agent` |
| `.gitignore` | EOF | Add `test_results/` and `.env.secret` | `general-purpose` |

## Dependent Files (callers — 2 levels)

### Testing Keys Consumers
- `testing_keys.dart` is the facade — imported by all test files and widget files that use keys
- Adding new keys to `projects_keys.dart` and new `sync_keys.dart` requires re-export in facade
- No widget files currently import keys directly (they use `TestingKeys.` via facade)

### Debug Server Consumers
- `lib/core/logging/logger.dart:792` — `_postLog()` POSTs to `http://127.0.0.1:3947/log`
- Sync status POST will follow identical pattern (same host, new endpoint)
- No other files interact with port 3947

### Sync Engine Consumers
- `lib/features/sync/data/sync_service.dart` — calls `SyncEngine.pushAndPull()`
- `lib/features/sync/presentation/providers/sync_provider.dart` — calls sync service
- `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` — triggers sync via provider

## Test Files

| Test File | Tests |
|-----------|-------|
| `test/shared/testing_keys/testing_keys_test.dart` | Validates key uniqueness across all key files |
| `test/features/sync/engine/sync_engine_test.dart` | 80+ tests for push/pull/conflict |
| `test/features/projects/presentation/screens/project_list_screen_test.dart` | Project list widget tests |
| `test/features/sync/presentation/screens/sync_dashboard_screen_test.dart` | Sync dashboard widget tests |

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    App (Flutter)                          │
│                                                          │
│  Widget Keys (sync_keys.dart, projects_keys.dart)        │
│    └─> Applied to widgets via Key('...')                  │
│    └─> flutter_driver finds by ValueKey                   │
│                                                          │
│  SyncEngine.pushAndPull()                                │
│    └─> Logger.sync() → POST /log (existing)              │
│    └─> NEW: POST /sync/status → debug server             │
│         {type: "sync_status", state: "started/completed"} │
└──────────────┬───────────────────────────────────────────┘
               │ HTTP POST
               ▼
┌──────────────────────────────────────────────────────────┐
│          Debug Server (Node.js, port 3947)                │
│                                                          │
│  POST /log         → addEntry() (existing)               │
│  POST /sync/status → store latest sync state (NEW)       │
│  GET  /sync/status → return latest sync state (NEW)      │
│  GET  /logs        → filter by category (existing)       │
│  GET  /health      → health check (existing)             │
└──────────────────────────────────────────────────────────┘
               │ Polled by
               ▼
┌──────────────────────────────────────────────────────────┐
│         Test Runner (PowerShell / Claude)                 │
│                                                          │
│  flutter_driver → find keys, tap, type, screenshot       │
│  GET /sync/status → poll until completed                 │
│  verify-sync.ps1 → Supabase REST API verification        │
│    └─> Reads SUPABASE_URL from .env                      │
│    └─> Reads SERVICE_ROLE_KEY from .env.secret            │
│    └─> Invoke-RestMethod to PostgREST                    │
└──────────────────────────────────────────────────────────┘
```

## Blast Radius Summary

| Category | Count |
|----------|-------|
| Direct new files | 3 |
| Direct modified files | 12 |
| Dependent files | 3 (sync_service, sync_provider, logger) |
| Test files affected | 4 |
| Dead code to clean up | 0 |

## Key Patterns to Follow

1. **Testing keys**: `static const keyName = Key('key_name');` and `static Key keyName(String id) => Key('key_name_$id');`
2. **Key facade**: Export in `testing_keys.dart`, re-export class methods in `TestingKeys` facade class
3. **Debug server routes**: `if (req.method === 'POST' && pathname === '/sync/status')` pattern
4. **Logger HTTP POST**: `_sendHttp(payload)` with fire-and-forget `_postLog()` — sync status should use same pattern
5. **Sync engine lifecycle**: Events at start of `pushAndPull()`, after `_push()`, after `_pull()`, in `finally` block
