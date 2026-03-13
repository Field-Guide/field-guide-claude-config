# Spec: .claude/ Directory Baseline Audit & Cleanup

**Date**: 2026-03-08
**Status**: Approved (post-adversarial review)
**Type**: Maintenance / Documentation Sync

---

## Overview

### Purpose
Bring the entire `.claude/` configuration directory into sync with the current codebase on `feat/sync-engine-rewrite`. Every file path, class reference, feature description, and cross-reference must accurately reflect what exists in `lib/` today. This is a baseline correction pass — fixing references and facts, not rewriting prose or design philosophy.

### Branch Policy
- **Canonical state**: Working tree on `feat/sync-engine-rewrite` (intended to merge to main)
- Mapper records branch name and commit hash in audit report
- Sync-specific changes tagged with `[BRANCH: feat/sync-engine-rewrite]` so they can be reverted if branch doesn't merge
- Verification phase checks for references to files that exist only on this branch

### Rollback Plan
Before Phase 3 begins:
1. Commit current `.claude/` state in the config repo
2. Tag as `pre-audit-2026-03-08`
3. If verification fails → `git checkout pre-audit-2026-03-08` for full rollback
4. Each worker agent's changes committed separately for surgical rollback

### Scope

**Included:**
- 26 feature docs in `docs/features/` (13 overview + 13 architecture) + README
- 14 PRDs in `prds/`
- 9 agent files in `agents/` + 8 agent memory directories (10 memory files) in `agent-memory/`
- 9 rule files in `rules/`
- 15 architecture-decision files in `architecture-decisions/` (14 constraints + data-validation-rules.md)
- 17 state/tracking JSON files in `state/`
- 9 skills in `skills/` (reference verification)
- CLAUDE.md (single owner agent — see below)
- `docs/` root files (INDEX.md, ui-audit, ui-dependency-map, ui-refactor, pdf-pipeline-audit) — ~6 files
- `docs/guides/` (chunked-sync, pagination-widgets, manual-testing, e2e-test-setup, ui-prototyping, README) — ~6 files
- `hooks/` (post-agent-coding.sh, pre-agent-dispatch.sh) — 2 files
- `autoload/_state.md` — 1 file
- `memory/MEMORY.md` — 1 file (project-level orchestrator memory)
- `defects/` (~15 files) — **path fixes only**, finding content is immutable
- New standalone `/audit-config` skill (deliverable)

**Excluded:**
- App code changes (docs-only pass)
- Historical records: `logs/`, `adversarial_reviews/`, `code-reviews/`, `test-results/`
- Backlogged plans (deliberately future-looking)
- `plans/sections/` (sync engine rewrite plan — deliberately forward-looking)
- Deep prose rewrites (fix facts and references only)

### Feature Count Convention
- **13 top-level features** with documentation: auth, contractors, dashboard, entries, locations, pdf, photos, projects, quantities, settings, sync, toolbox, weather
- **4 sub-features** of toolbox (no separate docs): calculator, forms, gallery, todos
- **17 directories** in `lib/features/` — this is correct; the 4 sub-features exist as directories but are covered by `feature-toolbox-overview.md` and `feature-toolbox.json`
- All docs should use "13 features (plus 4 toolbox sub-features)" for consistency

### Success Criteria
- [ ] Zero broken file paths across all in-scope `.claude/` files
- [ ] All class/model/provider name references match current codebase
- [ ] All feature docs accurately list current files, models, and providers
- [ ] All PRDs reflect what was actually implemented (marked as built)
- [ ] All agent files reference valid context files and paths
- [ ] All state JSONs reflect current feature status
- [ ] `test-wave-agent` added to CLAUDE.md agent table (or removed if obsolete)
- [ ] `test` skill added to CLAUDE.md skills table
- [ ] Orphaned `agent-memory/test-orchestrator-agent/` removed (if it exists) or other orphans identified
- [ ] New `/audit-config` skill functional and documented
- [ ] Security invariants verified unchanged (Phase 4 security check)
- [ ] Verification scan confirms zero remaining broken references

---

## Approach: Scan-First Pipeline

**Selected**: 1 Opus mapper agent scans first, then 11 Opus worker agents fix in parallel.

**Why this approach**: The mapper creates a single source of truth (audit report) that all workers reference. Prevents inconsistent findings from independent scanning.

**Rejected alternatives**:
- Domain-Parallel: All agents scan independently → risk of inconsistent findings
- Two-Wave: More complex coordination for marginal speed gain

---

## Agent Assignment

### Phase 0: Rollback Safety

Commit and tag current `.claude/` state before any changes.

### Phase 1: Mapper Agent (Opus)

| Item | Detail |
|------|--------|
| **Tool** | CodeMunch MCP (index_folder + search). Fallback: Glob + Grep + Read if CodeMunch unavailable |
| **Input** | Full `lib/` codebase + all `.claude/` files |
| **Output** | `.claude/outputs/audit-report-2026-03-08.md` |
| **Branch** | Records `feat/sync-engine-rewrite` + commit hash |

**Audit report sections:**
1. **Codebase Snapshot** — All classes, files, providers, DB tables, routes (with branch + commit hash)
2. **Broken References** — Per-file list of paths/names that don't resolve
3. **Stale Content** — Descriptions of removed features/code
4. **Orphaned Files** — Config files with no codebase counterpart
5. **Cross-Reference Map** — Inter-file references within `.claude/`
6. **Branch-Only Files** — Files that exist on this branch but not on main (for sync-related changes)

### Phase 2: User Review

User reviews audit report and approves/adjusts fix scope before any changes.

### Phase 3: Worker Agents (11 × Opus, parallel)

| # | Agent | Scope | Files |
|---|-------|-------|-------|
| 1 | **Feature Docs A** | auth, contractors, dashboard, entries, locations (overview + arch) | 10 |
| 2 | **Feature Docs B** | pdf, photos, projects, quantities, settings (overview + arch) | 10 |
| 3 | **Feature Docs C** | sync, toolbox, weather (overview + arch) + docs/features/README | 7 |
| 4 | **PRDs** | All 14 PRD files | 14 |
| 5 | **Arch-Decisions** | All 15 architecture-decision files | 15 |
| 6 | **Agents + Memories** | 9 agent files + 10 memory files across 8 dirs | 19 (9 logical pairs + extras) |
| 7 | **Rules** | 9 rule files | 9 |
| 8 | **State JSONs** | 17 state/tracking JSON files | 17 |
| 9 | **Skills + Audit Skill** | Verify 9 existing skills + build new `/audit-config` skill | 10 + new |
| 10 | **CLAUDE.md + Misc Config** | CLAUDE.md (single owner) + docs/INDEX.md + docs/ root files + docs/guides/ + hooks/ + autoload/ + memory/ | ~17 |
| 11 | **Defects** | ~15 defect files — **path fixes only** (findings are immutable) | ~15 |

**CLAUDE.md Ownership**: Agent #10 is the sole writer for CLAUDE.md. All other agents that discover CLAUDE.md issues (e.g., Agent #6 finds missing `test-wave-agent` in agent table, Agent #9 finds missing `test` skill) report them in their output. Agent #10 applies all CLAUDE.md changes.

### Phase 4: Verification

1. Re-run audit scan to confirm zero broken references
2. **Security invariant check**: Diff all modified `.claude/` files and confirm:
   - No `tools`/`disallowedTools`/`permissionMode` fields changed in agent files
   - No `MUST`/`MUST NOT` hard rules removed from constraint files
   - CLAUDE.md HARD CONSTRAINT line unchanged
   - `active_blockers` not incorrectly resolved in state JSONs
   - Security-agent MEMORY.md findings preserved
   - Defect file findings unchanged (only paths updated)
3. Present change summary to user

---

## What Each Agent Does (Baseline Correction)

Each worker agent receives the mapper's audit report and:

1. **Reads** its assigned `.claude/` files
2. **Reads** the corresponding `lib/features/{name}/` code (models, repos, providers, screens)
3. **Fixes** broken file paths to point to current locations
4. **Updates** class/model/provider names that were renamed
5. **Removes** references to deleted code (entry_personnel, legacy migrations, etc.)
6. **Adds** references to new code that's missing from docs
7. **Corrects** stale status/completion markers in state JSONs
8. **Does NOT** rewrite prose, design philosophy, or architecture rationale

---

## Security Invariants (Immutable During Audit)

The following content MUST NOT be modified by any worker agent. These are normative rules, not descriptive references.

### Agent Files (Agent #6)
- `tools`, `disallowedTools`, `model`, `permissionMode` YAML frontmatter fields — OUT OF SCOPE
- Security-agent Iron Law section ("NEVER MODIFY CODE. REPORT ONLY.")
- Any field that defines agent capabilities or permissions

### Rule Files (Agent #7)
- Lines containing security directives: token storage, logging prohibitions, RLS patterns, PKCE requirements
- Example immutable lines:
  - "Use `flutter_secure_storage` for tokens / Never log tokens or credentials"
  - "Do not add custom deep link handlers" (PKCE enforcement)
  - RLS policy patterns using `auth.uid() = user_id`
- Only file paths and class/model name references within rules may be updated

### CLAUDE.md (Agent #10)
- HARD CONSTRAINT line: "Security is non-negotiable..." — **IMMUTABLE**

### Constraint Files (Agent #5)
- Lines prefixed with `MUST` or `MUST NOT` (hard rules labeled "Violations = Reject Proposal")
- Only file path references and class names in References sections may be updated

### State JSONs (Agent #8)
- `constraints_summary` arrays — these are normative, not descriptive. Do NOT modify.
- `active_blockers` in PROJECT-STATE.json — may NOT be moved to resolved without code verification against merged main

### Agent Memory (Agent #6)
- Security-agent MEMORY.md findings: update file paths within findings, NEVER delete findings
- Finding descriptions, severity, and CVE references are immutable

### Defect Files (Agent #11)
- Finding descriptions, severity, status, and root cause analysis — IMMUTABLE
- Only file path and line number references may be updated

---

## `/audit-config` Skill Design

### Purpose
Repeatable one-command health check of `.claude/` against the codebase.

### Invocation
`/audit-config`

### Behavior
1. Index codebase with CodeMunch (or use existing index if recent)
2. Scan every `.claude/` file for file path references (`lib/**`, `*.dart`, class names)
3. Validate each reference against what exists on disk
4. Check class/model names mentioned in docs against actual class definitions
5. Verify security invariants:
   - Agent files still have expected `tools`/`disallowedTools` fields
   - Constraint files contain all `MUST`/`MUST NOT` rules (count check)
   - CLAUDE.md HARD CONSTRAINT line present
   - `active_blockers` count consistent with resolved entries
6. Produce structured report:
   - **Broken paths** — file doesn't exist at referenced location
   - **Stale references** — class/model renamed or removed
   - **Orphaned config** — `.claude/` files with no matching codebase feature
   - **Missing coverage** — codebase features with no `.claude/` docs
   - **Security invariant status** — pass/fail for each invariant check
7. Present report to user with recommended fixes
8. Optionally invoke brainstorming if changes are significant

### Output
`.claude/outputs/audit-report-YYYY-MM-DD.md` (ephemeral — add to `.gitignore` in config repo)

### Skill File Location
`.claude/skills/audit-config/SKILL.md`

---

## Execution Flow

```
Phase 0: ROLLBACK SAFETY
├── Commit current .claude/ state in config repo
└── Tag as pre-audit-2026-03-08

Phase 1: SCAN (Mapper Agent — Opus)
├── Index codebase with CodeMunch (fallback: Glob + Grep + Read)
├── Record branch (feat/sync-engine-rewrite) + commit hash
├── Cross-reference all .claude/ paths against lib/
├── Generate audit-report-2026-03-08.md
└── Present report to user for review

Phase 2: USER REVIEW
├── User reviews audit report
└── Approves/adjusts scope of fixes

Phase 3: FIX (11 Worker Agents — Opus, parallel)
├── Feature Docs A (10 files)
├── Feature Docs B (10 files)
├── Feature Docs C (7 files)
├── PRDs (14 files)
├── Arch-Decisions (15 files)
├── Agents + Memories (19 files)
├── Rules (9 files)
├── State JSONs (17 files)
├── Skills + build audit skill (10 + new)
├── CLAUDE.md + Misc Config (17 files — single CLAUDE.md owner)
└── Defects (15 files — path fixes only)
Each agent commits separately for surgical rollback capability.

Phase 4: VERIFY
├── Re-run audit scan → confirm zero broken refs
├── Security invariant check → confirm no normative content changed
└── Present summary of all changes to user
```

**Hard constraint**: Phase 3 does not start until user approves the Phase 1 audit report.

---

## Known Issues to Investigate

Based on initial scan + adversarial review:
- `test-wave-agent` exists as agent file but missing from CLAUDE.md agent table and has no memory dir
- `test` skill exists but missing from CLAUDE.md skills table
- `agent-memory/test-orchestrator-agent/` — verify if it exists on disk (review flagged it may not)
- `pdf-agent` memory has extra file: `stage-4c-implementation.md` alongside MEMORY.md
- Entry personnel references — removed in commit `8551571`
- Sync engine — entirely new architecture on `feat/sync-engine-rewrite`
- Provider updates — commit `ad486c0` changed provider/screen patterns
- Most docs dated Feb 13 — ~3 weeks of changes unaccounted for
- `docs/INDEX.md` claims 30 files, actual count is ~39
- Feature count inconsistency: CLAUDE.md says "17 features", architecture.md says "13 feature modules"
- `contractors/data/models/entry_personnel.dart` may still exist on disk despite schema removal — verify if dead code

---

## Decisions Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Doc purpose | As-built | Docs should describe what code IS, not aspirational |
| PRD handling | Update in-place | Preserves file history, marks implemented/descoped |
| Stale content | Report first, then clean | Two-pass: nothing deleted without user review |
| Audit skill | Standalone `/audit-config` | Keeps resume-session fast, audit thorough |
| Agent models | All Opus | Quality matters for accuracy of reference fixes |
| Agent count | 1 mapper + 11 workers | Max ~15 files per agent, expanded from 9 after review found missing directories |
| Depth | Baseline correction | Fix references and facts only, no prose rewrites |
| Branch policy | Feature branch is truth | Audit against `feat/sync-engine-rewrite` working tree |
| CLAUDE.md ownership | Single agent (#10) | Eliminates 3-way write conflict between agents #6, #7, #9 |
| Rollback | Commit + tag before changes | `pre-audit-2026-03-08` tag for full or surgical rollback |
| Defect files | Include, path fixes only | Finding content is immutable; only file path references updated |
| Security invariants | Explicit do-not-touch list | Prevents accidental weakening of security rules, constraints, agent permissions |

---

## Adversarial Review Summary

Reviews conducted by `code-review-agent` and `security-agent` on 2026-03-08.
Full reports saved to `.claude/adversarial_reviews/2026-03-08-claude-directory-audit/`.

**MUST-FIX (10)**: All addressed in this updated spec.
- 5 code review: branch ambiguity, PRD count, agent orphan mismatch, missing directories, skill count
- 5 security: agent capability protection, rule file protection, state JSON protection, constraint protection, security memory protection

**SHOULD-CONSIDER (adopted)**:
- CLAUDE.md single owner → Agent #10
- Rollback plan → Phase 0
- Security verification → Phase 4 sub-step
- Defect file protection → Security Invariants section
- CodeMunch fallback → Glob + Grep + Read
- Feature count convention → defined in scope

**NICE-TO-HAVE (noted for audit skill)**:
- Security invariant checks built into `/audit-config` skill
- `docs/outputs/` added to config repo `.gitignore`
- Seed empty auth-agent memory with known security patterns
