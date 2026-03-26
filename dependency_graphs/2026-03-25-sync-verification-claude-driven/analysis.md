# Dependency Graph: Sync Verification — Claude-Driven

## Blast Radius Summary
- **Direct changes**: 3 files modified, 1 file created
- **Files deleted**: ~105 files (10 integrity scenarios, ~90 deprecated L2/L3, 3 JS modules)
- **Dependent files**: 0 (all consumers of deleted files are also being deleted)
- **Test files**: 0 (no Dart test changes)
- **Cleanup**: Removal of dead JS infrastructure

## Direct Changes

### DELETE: JS Infrastructure (no remaining consumers)

| File | Symbols | Imported By | Notes |
|------|---------|-------------|-------|
| `tools/debug-server/integrity-runner.js` | IntegrityRunner class (4 methods) | run-tests.js:229 | Being removed from run-tests.js |
| `tools/debug-server/test-runner.js` | TestRunner class | run-tests.js:78 | Being removed from run-tests.js |
| `tools/debug-server/device-orchestrator.js` | DeviceOrchestrator class | integrity-runner.js:6 | Parent also deleted |
| `tools/debug-server/scenario-helpers.js` | TestContext class, 38 functions | 13 files (all being deleted) | No remaining consumers |
| `tools/debug-server/scenarios/integrity/*.js` | 10 scenario files (F1-F6, U1, P1, D1, D2) | integrity-runner.js | Parent deleted |
| `tools/debug-server/scenarios/deprecated/` | ~90 files (L2/L3 old scenarios) | test-runner.js | Parent deleted |

### MODIFY: `tools/debug-server/run-tests.js` (245 lines → ~80 lines)

Current imports:
- Line 78: `const TestRunner = require('./test-runner');` → DELETE
- Line 229: `const IntegrityRunner = require('./integrity-runner');` → DELETE
- Line 205: `const SupabaseVerifier = require('./supabase-verifier');` → KEEP

Sections to remove:
- Lines 78: TestRunner require
- Lines 95-190: parseArgs (replace with minimal version)
- Lines 228-233: `--suite=integrity` block
- Lines 235-238: TestRunner instantiation and run

Sections to keep:
- Lines 62-76: .env.test loader (IIFE)
- Lines 192-210: Env validation + `--cleanup-only` block
- `--clean` flag (simplified)

### MODIFY: `.claude/skills/test/skill.md` (320 lines)

Changes:
- Line 44: `sync` tier alias → update to `S01-S10` reference
- Line 68: `sync → node tools/debug-server/run-tests.js` → update
- Lines 156-166: Sync verification section → replace with Claude-driven S01-S10 description
- Lines 229: Sync row in flow count → update
- Line 287: Sync reference → update
- Add new sections: dual-device setup, Supabase verification, sync-specific compaction

### MODIFY: `.claude/test-flows/registry.md` (284 lines)

Changes:
- Lines 156-166: "Sync Verification System" blockquote → replace with S01-S10 tier table
- Lines 229: Flow count summary → update sync row
- Lines 232-233: Total count → update

### CREATE: `.claude/test-flows/sync-verification-guide.md`

New companion reference document containing:
- Environment setup (dual-device ports, .env.test)
- Supabase query patterns (PostgREST curl)
- Cross-device sync protocol (4-step)
- Pre-run cleanup procedure
- Post-run sweep (leftovers = FAIL)
- Log scanning protocol
- Report protocol
- FK teardown order
- Per-flow detailed steps (S01-S10)
- Checkpoint schema
- Unique per-run data tag generation

## Files That Stay (no changes)

| File | Why |
|------|-----|
| `tools/debug-server/server.js` | Debug server, independent |
| `tools/debug-server/supabase-verifier.js` | Used by `--cleanup-only` in run-tests.js and by nuke-all-data.js |
| `tools/debug-server/nuke-all-data.js` | Emergency wipe utility, independent |
| `tools/debug-server/.env.test` | Credentials, independent |

## Data Flow

```
BEFORE:
  run-tests.js → TestRunner → scenarios/L2/*.js → scenario-helpers.js → supabase-verifier.js
  run-tests.js → IntegrityRunner → scenarios/integrity/*.js → device-orchestrator.js
                                                             → scenario-helpers.js

AFTER:
  run-tests.js → supabase-verifier.js (cleanup-only mode)
  Claude /test sync → curl commands → driver endpoints (4948/4949) + Supabase REST API
```

## Agent Routing

| Phase | Files | Agent |
|-------|-------|-------|
| Phase 1: Delete JS files | tools/debug-server/ | general-purpose |
| Phase 2: Strip run-tests.js | tools/debug-server/run-tests.js | general-purpose |
| Phase 3: Update skill.md + registry.md | .claude/skills/, .claude/test-flows/ | general-purpose |
| Phase 4: Create sync-verification-guide.md | .claude/test-flows/ | general-purpose |

All files are in `.claude/` or `tools/` — no Dart, no presentation, no data layer. Single agent type (general-purpose) throughout.
