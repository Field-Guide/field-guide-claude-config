# Dependency Analysis: Debug Skill Driver Integration

## Direct Changes

| File | Change Type | Description |
|------|------------|-------------|
| `.claude/skills/systematic-debugging/SKILL.md` | MODIFY | Add Phase 3.5 (LAUNCH DRIVER), modify Phase 4 (REPRODUCE → autonomous), modify Phase 7 (VERIFY → autonomous), update Phase 3 rebuild commands |
| `.claude/skills/systematic-debugging/references/debug-session-management.md` | MODIFY | Update session lifecycle diagram, add driver setup to server setup checklist |
| `.claude/skills/systematic-debugging/references/driver-integration.md` | CREATE | New reference: driver API, repro-steps.json format, login procedure, assertion patterns, fallback rules |

## Referenced Files (NOT modified)

| File | Relationship |
|------|-------------|
| `tools/start-driver.ps1` | Invoked by new Phase 3.5 to launch app + debug server |
| `tools/wait-for-driver.ps1` | Called by start-driver.ps1 internally |
| `tools/stop-driver.ps1` | Referenced in cleanup guidance |
| `.claude/test-credentials.secret` | Read by skill for login (admin/inspector accounts) |
| `lib/core/driver/driver_server.dart` | Driver server (port 4948) — endpoints used by skill |
| `tools/debug-server/server.js` | Debug log server (port 3947) — hypothesis log collection |
| `lib/shared/testing_keys/*.dart` | 13 key files read by skill for widget identification |
| `.claude/skills/test/SKILL.md` | Pattern source — login procedure, sync polling, error detection |

## Data Flow

```
Skill (SKILL.md)
  ├─ Phase 3.5: start-driver.ps1 → launches app + debug server
  │   ├─ Polls /driver/ready (port 4948)
  │   └─ Polls /health (port 3947)
  │
  ├─ Phase 4: Autonomous Reproduce
  │   ├─ Reads .claude/test-credentials.secret → login via driver
  │   ├─ Reads testing_keys/*.dart → widget key names
  │   ├─ Writes repro-steps.json → debug session folder
  │   ├─ Executes curl commands → driver server (port 4948)
  │   └─ Checks hypothesis logs → debug server (port 3947)
  │
  └─ Phase 7: Autonomous Verify
      ├─ POST /driver/hot-restart → rebuild app state
      ├─ POST /clear → reset debug server logs
      ├─ Re-executes repro-steps.json → driver server
      └─ Asserts hypothesis markers → debug server
```

## Blast Radius

- **3 files changed** (2 modify, 1 create) — all `.claude/` config
- **0 app code changes** — driver/debug server used as-is
- **0 test changes** — no test files affected
- **0 dependent files** — skill files are leaf nodes, nothing imports them
