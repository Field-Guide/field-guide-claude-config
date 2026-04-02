# Spec: Migrate Defect/Blocker Tracking to GitHub Issues

**Date**: 2026-04-01
**Status**: Approved
**Size**: M (18 files updated, 1 script created, 1 workflow deleted, 1 directory deleted)

---

## Overview

### Purpose
Eliminate local `.claude/defects/` file-based defect tracking and make GitHub Issues the single source of truth for all defects, bugs, and blockers. Gives the user direct visibility and filtering without needing a Claude session.

### Scope
- **In**: Helper script, 6 writer updates (3 skills + 3 agents), 6 reader simplifications (drop defect loading), blocker linking in `_state.md`, one-time migration, `sync-defects.yml` removal, CLAUDE.md and doc updates
- **Out**: No changes to architecture rules, lint system, CI quality gate, or the existing lint-violation issue automation in `quality-gate.yml`

### Success Criteria
- [ ] `tools/create-defect-issue.ps1` creates properly labeled issues with validated params
- [ ] All 6 writers create GitHub Issues instead of writing local files
- [ ] 6 read-only agents no longer reference defect files
- [ ] `_state.md` blocker section references GitHub Issue numbers
- [ ] All still-relevant active defects migrated to GitHub Issues
- [ ] `.claude/defects/` directory deleted
- [ ] `.github/workflows/sync-defects.yml` removed
- [ ] CLAUDE.md and all skill/agent docs updated

---

## Approach

**Thin Script + Smart Callers**: A centralized `create-defect-issue.ps1` handles label logic and `gh issue create`. Each caller (skill/agent) formats its own body markdown, since body formats differ meaningfully across callers (test skill has Logcat/Screenshot, security-agent has SEC-NNN/Severity, end-session has Pattern/Prevention).

**Alternatives rejected**:
- *Fat Script + Dumb Callers*: Body formats differ too much across callers. Lowest-common-denominator problem.
- *Script Suite (create/close/update)*: Over-engineered. Closing/updating can use `gh issue close`/`gh issue edit` directly.

---

## Label Scheme

Three tracking dimensions plus architectural layer labels:

### Feature Labels
`auth`, `contractors`, `dashboard`, `database`, `entries`, `forms`, `locations`, `pdf`, `photos`, `projects`, `quantities`, `settings`, `sync`, `toolbox`, `weather`, `tooling`, `core`

### Type Labels
`defect`, `blocker`, `security`, `cosmetic`

### Priority Labels
`critical`, `high`, `medium`, `low`, `parked`

### Layer Labels
| Label | Covers |
|-------|--------|
| `layer:app-wiring` | Startup, routing, DI, bootstrap |
| `layer:state` | Providers, state management |
| `layer:presentation` | Screens, navigation, UX |
| `layer:services` | Cross-cutting services, integrations |
| `layer:shared-ui` | Shared widgets, cross-cutting hygiene |
| `layer:data` | Repositories, datasources, models |
| `layer:database` | SQLite schema, migrations |
| `layer:sync` | Sync engine, conflict resolution, Supabase |
| `layer:auth` | Authentication, sessions, RLS |
| `layer:tests-tooling` | Tests, tooling, quality gates |

---

## Helper Script Design

### `tools/create-defect-issue.ps1`

**Parameters**:
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `-Title` | string | Yes | Brief description |
| `-Feature` | string | Yes | One of the 17 feature names |
| `-Type` | string | Yes | `defect` \| `blocker` \| `security` \| `cosmetic` |
| `-Priority` | string | Yes | `critical` \| `high` \| `medium` \| `low` \| `parked` |
| `-Layer` | string[] | Yes | One or more of the 10 layer labels. All that apply. |
| `-Body` | string | Yes | Markdown body (caller formats this) |
| `-Ref` | string | Yes | File path reference, appended to body |

**Behavior**:
1. Validates all params against allowed values
2. Runs `gh issue create --repo <app-repo> --title "$Title" --label "$Feature,$Type,$Priority,$Layer1,$Layer2,..." --body "$Body"`
3. Returns issue URL on stdout
4. Exit code 0 on success, 1 on failure

No close/update helper scripts — skills use `gh issue close` and `gh issue edit` directly when needed.

---

## Writer Updates

| Writer | Currently Does | Changes To |
|--------|---------------|------------|
| **end-session skill** | Writes to `_defects-{feature}.md`, archives overflow, updates `active_blockers` in PROJECT-STATE.json | Calls `create-defect-issue.ps1`. Updates `_state.md` blocker section with issue numbers. Drops archive logic. |
| **systematic-debugging skill** | Reads defects Phase 1.4, writes Phase 10, archives overflow | Phase 1.4: runs `gh issue list --label "{feature}" --state open` to check known issues. Phase 10: calls `create-defect-issue.ps1`. Drops archive logic. |
| **test skill** | Auto-files `[TEST]` defects with rich template | Calls `create-defect-issue.ps1` with its own body format (Symptom, Step, Logcat, Screenshot). Body formatting stays in the skill. |
| **security-agent** | Writes SEC-NNN findings, creates new defect files | Calls `create-defect-issue.ps1` with security body format (Severity, SEC-NNN, Remediation). Drops file creation. |
| **qa-testing-agent** | Reads known defects, writes new ones | Drops pre-read. Calls `create-defect-issue.ps1` for new findings. |
| **code-review-agent** | Reads known defects, writes new ones | Drops pre-read. Calls `create-defect-issue.ps1` for new findings. |

---

## Reader Simplifications

Remove all `.claude/defects/_defects-{feature}.md` references from context-loading frontmatter. No replacement needed.

| Agent/Skill | Change |
|-------------|--------|
| `debug-research-agent` | Drop defect file reads |
| `auth-agent` | Drop defect file read from security checklist |
| `frontend-flutter-specialist-agent` | Drop defect file from context loading |
| `pdf-agent` | Drop defect file from context loading |
| `backend-data-layer-agent` | Drop defect file from context loading |
| `backend-supabase-agent` | Drop defect file from context loading |
| `brainstorming` skill | Remove Phase 1 defect file check |
| `audit-config` skill | Remove defects directory validation |
| `patrol-testing` rule | Remove defect file reference |

---

## Blocker Format Change

**Current `_state.md` format:**
```
### BLOCKER-NN: Title
**Status**: RESOLVED | OPEN | MITIGATED | OPEN (parked, cosmetic)
```

**New format:**
```
### BLOCKER-NN: Title (#issue-number)
**Status**: RESOLVED | OPEN | MITIGATED | OPEN (parked, cosmetic)
```

`end-session` skill updates both: closes/updates the GitHub Issue via `gh` AND updates the status line in `_state.md`.

---

## Migration Strategy

### Phase 0: Audit & Migrate (before any code changes)
1. Read all 17 active defect files + `_state.md` blockers
2. For each non-resolved entry, verify against current codebase whether it's still relevant
3. Create GitHub Issues for verified-active defects via `gh issue create`
4. Create GitHub Issues for active blockers (BLOCKER-28, 23, 34, 36, 37) with `blocker` type label
5. Update `_state.md` blocker entries to include issue number references
6. Archive local defect files to `.claude/logs/defects-archive.md` (append active entries that were migrated, with migration date stamp)
7. Delete `.claude/defects/` directory

### Label Setup (one-time, before migration)
Create all labels in the GitHub repo:
- 17 feature labels
- 4 type labels
- 5 priority labels
- 10 layer labels

---

## Implementation Order

### Phase 1: Setup
- Create GitHub labels (feature, type, priority, layer)
- Create `tools/create-defect-issue.ps1`

### Phase 2: Migration
- Audit all 17 defect files + 5 active blockers against current codebase
- Create GitHub Issues for verified-active defects
- Create GitHub Issues for active blockers
- Update `_state.md` blocker entries with issue numbers
- Append migrated entries to `defects-archive.md`

### Phase 3: Writer Updates
- Update 3 skills (end-session, systematic-debugging, test)
- Update 3 agents (security, qa-testing, code-review)

### Phase 4: Reader Simplifications
- Remove defect file references from 6 agents + 2 skills + 1 rule

### Phase 5: Cleanup
- Delete `.claude/defects/` directory
- Delete `.github/workflows/sync-defects.yml`
- Update `.claude/CLAUDE.md`

---

## Files Changed

### Created
- `tools/create-defect-issue.ps1`

### Deleted
- `.claude/defects/` (entire directory — 18 files)
- `.github/workflows/sync-defects.yml`

### Updated
- `.claude/autoload/_state.md` — blocker format adds issue numbers
- `.claude/skills/end-session/SKILL.md` — replace defect file writes with script calls
- `.claude/skills/systematic-debugging/SKILL.md` — Phase 1.4 uses `gh issue list`, Phase 10 uses script
- `.claude/skills/systematic-debugging/references/defects-integration.md` — rewrite for GitHub Issues
- `.claude/skills/test/references/output-format.md` — replace defect filing with script calls
- `.claude/skills/brainstorming/skill.md` — remove defect file check from Phase 1
- `.claude/skills/audit-config/SKILL.md` — remove defects validation
- `.claude/agents/security-agent.md` — replace file writes with script calls
- `.claude/agents/qa-testing-agent.md` — drop pre-read, add script calls
- `.claude/agents/code-review-agent.md` — drop pre-read, add script calls
- `.claude/agents/debug-research-agent.md` — drop defect file reads
- `.claude/agents/auth-agent.md` — drop defect file read
- `.claude/agents/frontend-flutter-specialist-agent.md` — drop defect file read
- `.claude/agents/pdf-agent.md` — drop defect file read
- `.claude/agents/backend-data-layer-agent.md` — drop defect file read
- `.claude/agents/backend-supabase-agent.md` — drop defect file read
- `.claude/CLAUDE.md` — update defect references
- `.claude/rules/testing/patrol-testing.md` — remove defect file reference
