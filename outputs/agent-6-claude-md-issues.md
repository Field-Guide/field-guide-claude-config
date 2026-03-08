# CLAUDE.md Issues Found by Agent #6 (Agents + Memories)

## Issues

1. **test-wave-agent missing from CLAUDE.md agent table**: `agents/test-wave-agent.md` exists on disk but is not listed in the Agents table in CLAUDE.md. Add it or document it as deprecated.

2. **Orphaned agent-memory directory deleted**: `agent-memory/test-orchestrator-agent/` was an empty directory with no matching agent file. It has been deleted.

3. **security-agent.md updated**: Fixed `entry_personnel` to `entry_personnel_counts` in multi-tenant table list. Fixed `sync_service.dart` reference to new engine path.
