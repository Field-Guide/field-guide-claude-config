# Test Skill Information Architecture Restructure

**Date:** 2026-04-04
**Status:** Approved
**Size:** M (multi-file restructure, no app code changes)

## Problem

The `/test` skill loads ~41k tokens (~2,480 lines) into context on every invocation regardless of what's being tested:
- `SKILL.md` (781 lines, ~11.6k tokens) — monolithic skill definition
- `sync-verification-guide.md` (1,385 lines, ~18k tokens) — monolithic sync guide
- `registry.md` (314 lines, ~11.3k tokens) — unified flow registry

Issues:
1. **Massive duplication** — scrollable keys, navigation map, android keyboard rules, sync protocol, debug server endpoints all appear in both SKILL.md and sync-verification-guide.md
2. **No lazy loading** — running `/test auth` loads all 19 sync flow protocols and every tier's registry entries
3. **Sync guide is two things** — shared framework (setup, patterns, protocol) jammed together with 19 step-by-step flow protocols
4. **Registry status columns are unused/inconsistent** — SKILL.md says "don't update registry during runs" but registry has Status/Last Run columns

## Decisions

1. **Tier files are static reference docs** — no Status/Last Run/Notes columns. Runtime tracking lives in `checkpoint.json`, `report.md`, and GitHub Issues.
2. **Debug server gets its own reference file** — it's the agent's primary observation tool (eyes into the app without screenshots), distinct from driver interaction.
3. **Sync flows grouped by compaction pause** — natural resume boundaries.
4. **Tier grouping by affinity** — related tiers share a file (setup+auth, entries+lifecycle, etc.)
5. **SKILL.md is the router** — always loaded, contains a routing table mapping each `/test <tier>` command to the exact files to read.

## Target Structure

```
skills/test/
├── SKILL.md                           # Core: rules, execution model, router (~350 lines)
├── references/
│   ├── driver-and-navigation.md       # Driver endpoints, scrollable keys, sentinels, nav, gotchas, recovery (~180 lines)
│   └── debug-server-and-logs.md       # Debug server endpoints, log formats, filters, hot-restart delay (~100 lines)

test-flows/
├── tiers/
│   ├── setup-and-auth.md              # Tier 0 + Tier 1 (T01-T14)
│   ├── entry-crud.md                  # Tier 2 + Tier 3 (T15-T30)
│   ├── toolbox-and-pdf.md             # Tier 4 + Tier 5 (T31-T43)
│   ├── settings-and-admin.md          # Tier 6 + Tier 7 (T44-T58)
│   ├── mutations.md                   # Tier 8 + Tier 9 (T59-T77)
│   ├── verification.md               # Tier 11 + Tier 12 (T85-T96)
│   └── manual-flows.md               # M01-M13
├── sync/
│   ├── framework.md                   # Setup, supabase patterns, sync protocol, FK teardown, checkpoint, resume (~350 lines)
│   ├── flows-S01-S03.md              # Project + entry + photos [compaction pause]
│   ├── flows-S04-S06.md              # Forms + todos + calculator [compaction pause]
│   ├── flows-S07-S10.md              # Update + PDF + delete + cleanup [compaction pause after S09]
│   └── flows-S11-S19.md             # Advanced: documents, realtime, FCM, dirty-scope, channels
├── flow-dependencies.md              # Dependency chain + flow count summary
```

## File Contents Mapping

### SKILL.md (~350 lines) — always loaded

Keeps:
- Hard rules (per-flow checklist, per-tier checklist, sync flow hard rules)
- Credentials + special characters warning
- Bash tool constraints (vars don't persist, wait-then-act, dialog reopen pattern)
- Execution model (setup, checkpoint format, per-flow execution, per-tier wrap-up)
- Pre-run data verification + decision tree
- Failure detection table + screenshot rules
- Compaction protocol
- Missing-key protocol
- Role handling + post-login state normalization
- Report format
- Key reference table (testing_keys file map)
- Finding E2E projects by name
- Test data safety
- Teardown
- Error handling (driver unreachable, crash detection)
- Windows bash constraints
- **Routing table** (new — maps tier aliases to files)

Removes (moves to reference files):
- HTTP driver endpoints table → `references/driver-and-navigation.md`
- Scrollable keys table → `references/driver-and-navigation.md`
- Screen sentinels + state confusion protocol → `references/driver-and-navigation.md`
- Bottom nav destinations → `references/driver-and-navigation.md`
- Common navigation patterns → `references/driver-and-navigation.md`
- Project key disambiguation → `references/driver-and-navigation.md`
- Android gotchas (keyboard, snackbar, toolbox depth) → `references/driver-and-navigation.md`
- Error recovery protocol → `references/driver-and-navigation.md`
- Debug server endpoints + filter params → `references/debug-server-and-logs.md`
- /logs/errors, /logs/summary, /logs?format=text, /logs?format=json, /logs (NDJSON) → `references/debug-server-and-logs.md`
- Quick reference table (which endpoint to use) → `references/debug-server-and-logs.md`
- Hot restart log delay → `references/debug-server-and-logs.md`
- Sync verification section (lines 617-670) → `test-flows/sync/framework.md`
- Flow dependencies section → `test-flows/flow-dependencies.md`

### references/driver-and-navigation.md (~180 lines)

Content sourced from SKILL.md (deduplicated — remove copies from sync guide):
- HTTP driver endpoints table (method, endpoint, body/params)
- Scrollable keys table (screen, scroll key, notes) + usage examples
- Screen sentinels table + state confusion protocol (4-step)
- Bottom nav destinations table (key, destination, sentinel)
- Common navigation patterns table (action, sequence)
- Project key disambiguation table
- Android gotchas: keyboard blocking, snackbar blocking, toolbox navigation depth
- Error recovery protocol: tap-but-nothing-happens, widget-not-found, sync-appears-to-fail

### references/debug-server-and-logs.md (~100 lines)

Content sourced from SKILL.md:
- Quick reference table (task → endpoint → output format)
- /logs/errors — primary testing endpoint, usage example
- /logs/summary — checkpoint reporting, usage example
- /logs?format=text — human-readable activity
- /logs?format=json — structured data
- /logs (default NDJSON) — legacy note
- Filter parameters table (category, level, since, last, hypothesis, deviceId, format)
- Hot restart log delay warning

### test-flows/tiers/*.md — static flow definitions

Each file contains:
- Tier name, range, and description header
- Prerequisite note (what must exist before this tier runs)
- Flow table: `ID | Flow | Table(s) | Driver Steps | Verify-Logs | Notes`
- NO Status/Last Run columns (tracking is in checkpoint.json + report.md + GitHub Issues)

Groupings:
- **setup-and-auth.md**: Tier 0 (T01-T04) + Tier 1 (T05-T14) — auth is prerequisite for project setup
- **entry-crud.md**: Tier 2 (T15-T23) + Tier 3 (T24-T30) — entry creation + lifecycle
- **toolbox-and-pdf.md**: Tier 4 (T31-T40) + Tier 5 (T41-T43) — content creation + export
- **settings-and-admin.md**: Tier 6 (T44-T52) + Tier 7 (T53-T58) — app management
- **mutations.md**: Tier 8 (T59-T67) + Tier 9 (T68-T77) — edit + delete operations
- **verification.md**: Tier 11 (T85-T91) + Tier 12 (T92-T96) — permissions + navigation checks
- **manual-flows.md**: M01-M13 — flows requiring capabilities the HTTP driver lacks

### test-flows/sync/framework.md (~350 lines)

Content sourced from sync-verification-guide.md lines 1-358 + report/edge-case sections:
- Environment setup (devices, credentials, supabase access, per-run unique tag)
- Pre-run cleanup
- Supabase query patterns (read, filters, hard-delete)
- Scrollable keys reference (sync-relevant subset, or pointer to driver-and-navigation.md)
- Navigation map (bottom nav, canonical sync-via-UI sequence, toolbox nav)
- Android keyboard rule
- Cross-device sync protocol (4-step UI-driven pattern)
- Log scanning patterns
- FK teardown order (20-table delete sequence)
- Checkpoint schema (JSON structure with ctx object)
- Compaction pauses (after S03, S06, S09)
- Resume protocol (5-step device restore)
- Storage bucket verification pattern
- Report protocol (8-section format)
- Edge cases (ADB flakiness, device disconnects, sync errors, already logged in, context exhaustion)

**Deduplication:** Where sync framework content overlaps with driver-and-navigation.md (scrollable keys, nav map, keyboard rule), the framework should either:
- Include only sync-specific additions (e.g., canonical sync-via-UI sequence) and reference the driver file for shared content
- Or include the sync-specific copy if it adds sync-relevant context (e.g., dual-port navigation)

Decision: **Include sync-specific versions** (they reference dual ports 4948/4949) and add a note pointing to driver-and-navigation.md for the full reference. This avoids cross-file reads during sync execution.

### test-flows/sync/flows-*.md — step-by-step protocols

Content sourced from sync-verification-guide.md "Flow Protocols" section:
- **flows-S01-S03.md**: S01 (Project Setup ~175 lines), S02 (Daily Entry ~100 lines), S03 (Photos ~25 lines). Compaction pause after S03.
- **flows-S04-S06.md**: S04 (Forms ~30 lines), S05 (Todos ~35 lines), S06 (Calculator ~42 lines). Compaction pause after S06.
- **flows-S07-S10.md**: S07 (Update All ~100 lines), S08 (PDF Export ~35 lines), S09 (Delete Cascade ~58 lines), S10 (Unassignment + Cleanup ~76 lines). Compaction pause after S09.
- **flows-S11-S19.md**: S11 (Documents ~62 lines), S12-S19 (advanced flows ~20-40 lines each).

Each file includes:
- Header with flow range and compaction pause note
- Per-flow: tables affected, dependencies, admin/inspector steps with curl examples, supabase verify steps, checkpoint ctx updates

### test-flows/flow-dependencies.md (~80 lines)

Content sourced from registry.md:
- Full dependency chain (ASCII tree showing T01→T05→T06→T15→... etc.)
- Sync dependency chain (S01→S02→S03 [COMPACTION] → ...)
- Flow count summary table (tier, range, count, description)

## Routing Table (in SKILL.md)

```markdown
## Reference Loading

Before executing, read the files mapped to your command:

| Command | Files to Read |
|---|---|
| Any tier (first use) | `skills/test/references/driver-and-navigation.md` + `skills/test/references/debug-server-and-logs.md` |
| `auth`, `project-setup` | `test-flows/tiers/setup-and-auth.md` |
| `entries`, `lifecycle` | `test-flows/tiers/entry-crud.md` |
| `toolbox`, `pdf` | `test-flows/tiers/toolbox-and-pdf.md` |
| `settings`, `admin` | `test-flows/tiers/settings-and-admin.md` |
| `edits`, `deletes` | `test-flows/tiers/mutations.md` |
| `permissions`, `navigation` | `test-flows/tiers/verification.md` |
| `sync` or `S01-S19` | `test-flows/sync/framework.md` + relevant `test-flows/sync/flows-*.md` |
| Single flow (e.g., `T15`) | Tier file containing that flow |
| `full` or `--resume` | `test-flows/flow-dependencies.md` + tier files as you reach each tier |
| Manual flows | `test-flows/tiers/manual-flows.md` |
```

## Token Impact

| Scenario | Before | After | Savings |
|---|---|---|---|
| `/test auth` | ~41k | ~9k (SKILL + refs + setup-and-auth) | **78%** |
| `/test entries` | ~41k | ~9k (SKILL + refs + entry-crud) | **78%** |
| `/test sync` (full run) | ~41k | ~17k (SKILL + refs + framework + flow groups progressively) | **59%** |
| `/test S07` (single flow) | ~41k | ~13k (SKILL + refs + framework + flows-S07-S10) | **68%** |
| `/test full` | ~41k | ~6k initially, loads tiers progressively | **85%+ initially** |

## Migration / Cleanup

1. Create all new files with content extracted from the three source files
2. Delete `test-flows/registry.md` (replaced by tier files + flow-dependencies.md)
3. Delete `test-flows/sync-verification-guide.md` (replaced by sync/ directory)
4. Rewrite `skills/test/SKILL.md` (trimmed core + routing table)
5. Verify no other files reference the old paths (check CLAUDE.md, other skills, memory files)

## Success Criteria

1. **No content loss** — every piece of information from the 3 source files exists in exactly one place in the new structure
2. **No duplication** — content that appeared in multiple source files appears in exactly one target file (with cross-references where needed)
3. **SKILL.md < 400 lines** — down from 781
4. **Routing table is complete** — every `/test` command variant maps to specific files
5. **Tier files have no Status/Last Run columns** — static reference only
6. **Old files deleted** — registry.md and sync-verification-guide.md removed
