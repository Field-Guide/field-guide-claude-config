# Dependency Graph: Debug Framework

## Direct Changes

### CREATE — New files

| File | Type | Agent |
|------|------|-------|
| `tools/debug-server/server.js` | Node.js HTTP log server (~180 lines) | `general-purpose` |
| `tools/debug-server/README.md` | Setup docs | `general-purpose` |
| `lib/core/logging/logger.dart` | Unified Logger class with file + HTTP transports | `backend-data-layer-agent` |
| `lib/core/logging/http_log_transport.dart` | HTTP transport (fire-and-forget, scrubbing) | `backend-data-layer-agent` |
| `lib/core/logging/file_log_transport.dart` | File transport (matching current DebugLogger output) | `backend-data-layer-agent` |
| `lib/core/logging/sensitive_data_filter.dart` | Blocklist scrubber for HTTP transport | `backend-data-layer-agent` |
| `.claude/skills/systematic-debugging/SKILL.md` | Rewritten skill (~350 lines) | `general-purpose` |
| `.claude/skills/systematic-debugging/references/log-investigation-and-instrumentation.md` | Combined reference | `general-purpose` |
| `.claude/skills/systematic-debugging/references/codebase-tracing-paths.md` | Audited tracing paths | `general-purpose` |
| `.claude/skills/systematic-debugging/references/defects-integration.md` | Updated defects workflow | `general-purpose` |
| `.claude/skills/systematic-debugging/references/debug-session-management.md` | Session lifecycle | `general-purpose` |
| `.claude/agents/debug-research-agent.md` | Agent definition | `general-purpose` |

### MODIFY — Existing files

| File | Change | Lines | Agent |
|------|--------|-------|-------|
| `lib/core/config/test_mode_config.dart` | Add `DEBUG_SERVER` const | 21-124 | `backend-data-layer-agent` |
| `lib/main.dart` | Replace `AppLogger`/`DebugLogger` init with `Logger.init()` | 95-481 | `backend-data-layer-agent` |
| `lib/core/logging/app_route_observer.dart` | Replace `AppLogger.log()` with `Logger.nav()` | 7-42 | `backend-data-layer-agent` |
| `lib/core/router/app_router.dart` | Replace `AppLogger.isEnabled` with `Logger.isEnabled` | 86 | `backend-data-layer-agent` |
| `tools/build.ps1` | Add DEBUG_SERVER guard for release builds | 33-41 | `general-purpose` |

### DELETE — After full migration (Phase 3, P4)

| File | Reason |
|------|--------|
| `lib/core/logging/app_logger.dart` | Replaced by `Logger` |
| `lib/core/logging/debug_logger.dart` | Replaced by `Logger` |

### DEPRECATION FORWARDING — Temporary (Phase 3 start)

Both old files get forwarding stubs that delegate to `Logger.*()` until all call sites are migrated.

## Dependent Files (Import `DebugLogger`)

22 files import `debug_logger.dart`:

| File | Category | Usage Count |
|------|----------|-------------|
| `lib/core/database/database_service.dart` | db | 11 calls |
| `lib/core/database/schema_verifier.dart` | db | 4 calls |
| `lib/features/pdf/presentation/helpers/pdf_import_helper.dart` | pdf | 8 calls |
| `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart` | pdf | 20+ calls |
| `lib/features/pdf/services/extraction/stages/grid_line_remover.dart` | pdf | 2 calls |
| `lib/features/pdf/services/extraction/stages/post_processor_v2.dart` | pdf | 11 calls |
| `lib/features/pdf/services/pdf_import_service.dart` | pdf | ? |
| `lib/features/projects/data/datasources/local/project_local_datasource.dart` | db | ? |
| `lib/features/projects/data/repositories/project_repository.dart` | db | ? |
| `lib/features/quantities/presentation/providers/bid_item_provider.dart` | ui | Only provider using DebugLogger |
| `lib/features/quantities/utils/budget_sanity_checker.dart` | db | ? |
| `lib/features/sync/application/sync_lifecycle_manager.dart` | sync | ? |
| `lib/features/sync/application/sync_orchestrator.dart` | sync | ? |
| `lib/features/sync/engine/change_tracker.dart` | sync | ? |
| `lib/features/sync/engine/integrity_checker.dart` | sync | ? |
| `lib/features/sync/engine/orphan_scanner.dart` | sync | ? |
| `lib/features/sync/engine/storage_cleanup.dart` | sync | ? |
| `lib/features/sync/engine/sync_engine.dart` | sync | ? |
| `lib/main.dart` | both | AppLogger + DebugLogger init |
| `lib/services/soft_delete_service.dart` | db | ? |
| `lib/services/startup_cleanup_service.dart` | db | ? |
| `lib/shared/datasources/generic_local_datasource.dart` | db | Every CRUD op |

4 files import `app_logger.dart`:

| File | Usage |
|------|-------|
| `lib/core/logging/app_route_observer.dart` | 4 `AppLogger.log()` calls |
| `lib/core/router/app_router.dart` | `AppLogger.isEnabled` check |
| `lib/main.dart` | Init, zoneSpec, error handlers, lifecycle |

1 file imports `app_route_observer.dart`:

| File | Usage |
|------|-------|
| `lib/core/router/app_router.dart` | Observer registration |

## Test Files

| File | Tests |
|------|-------|
| `test/core/logging/debug_logger_test.dart` | Existing — must update to test `Logger` |

No existing tests for `AppLogger` or `AppRouteObserver`.

## Data Flow Diagram

```
┌─────────────── NEW ────────────────┐    ┌─────── EXISTING ────────┐
│                                     │    │                          │
│  tools/debug-server/server.js       │    │  22 files importing      │
│       ▲                             │    │  DebugLogger             │
│       │ POST /log                   │    │       │                  │
│       │                             │    │       │ deprecation      │
│  lib/core/logging/                  │    │       │ forwarding       │
│  ├── logger.dart ◄──────────────────┼────┤       ▼                  │
│  │   ├── file_log_transport.dart    │    │  Logger.sync/pdf/db/...  │
│  │   ├── http_log_transport.dart    │    │                          │
│  │   └── sensitive_data_filter.dart │    │  4 files importing       │
│  │                                  │    │  AppLogger               │
│  └── test_mode_config.dart (mod)    │    │       │ forwarding       │
│       + DEBUG_SERVER const          │    │       ▼                  │
│                                     │    │  Logger.nav/ui/error/... │
│  .claude/skills/                    │    │                          │
│  └── systematic-debugging/          │    │  main.dart               │
│       ├── SKILL.md (rewrite)        │    │       │ direct migration │
│       └── references/ (4 files)     │    │       ▼                  │
│                                     │    │  Logger.init()           │
│  .claude/agents/                    │    │                          │
│  └── debug-research-agent.md        │    └──────────────────────────┘
│                                     │
│  tools/build.ps1 (mod)              │
│       + DEBUG_SERVER release guard  │
└─────────────────────────────────────┘
```

## Blast Radius Summary

| Category | Count |
|----------|-------|
| **Direct creates** | 12 files |
| **Direct modifies** | 5 files |
| **Dependent** (import DebugLogger/AppLogger) | 24 unique files |
| **Test files** | 1 existing + new Logger tests |
| **Cleanup** (delete after migration) | 2 files |
| **Total blast radius** | 43 files |
