# Documentation Drift Detection & Repair System

**Date**: 2026-04-05
**Status**: Approved
**Branch**: TBD (new branch from main)

---

## Overview

### Purpose
Eliminate documentation drift in `.claude/` by creating a two-layer detection and repair system: a deterministic CI workflow that flags specific drift in every PR, backed by a local CodeMunch-powered skill that performs deep semantic audits and generates fixes.

### Problem Statement
Code changes in PRs (file moves, renames, new patterns, removed features) cause `.claude/` documentation to fall out of sync. Claude then operates on stale instructions, degrading output quality. This is a major time sink requiring manual hunting for stale documentation.

### Philosophy
This is a **hygiene system**, not a mandatory gate. The CI comment is informational, `/audit-docs` suggests but doesn't force, and the user decides what's worth acting on. The goal is awareness and good habits, not bureaucracy.

### Prerequisites (delivered as part of this spec)
1. **CLAUDE.md slimdown** — remove content Claude can discover from the filesystem. Target: ~130-140 lines (down from ~215).
2. **Rules → recognition + procedure split** — trim 10 rule files from 3,051 total lines to ~400 lines of recognition rules. Extract procedures into implementer reference guides.
3. **Agent cleanup** — retire 3 domain-specific agents, fix silently-ignored `specialization:` frontmatter, standardize models, add domain context routing tables.
4. **Rename audit-config → audit-docs** — expanded scope, new skill definition.

### Deliverables
1. **`/audit-docs` skill** — local, CodeMunch-powered. Audits all in-scope `.claude/` files against codebase. Produces a report, proposes fixes, regenerates the path→doc mapping config, surfaces undocumented patterns.
2. **`doc-drift.yml` GitHub Action** — runs on every PR to main. Reads the mapping config, analyzes the PR diff, posts a structured comment identifying specific docs that may need updating. Informational only — never blocks merge.
3. **`.claude/doc-drift-map.json`** — mapping config. Maps codebase path patterns to documentation files that reference them. Generated and refreshed by `/audit-docs`.
4. **Slimmed CLAUDE.md** — ~130-140 lines with zero loss of effective instruction coverage.
5. **Refactored rules** — 30-50 line recognition rules + procedure guides in `skills/implement/references/`.
6. **Domain context routing tables** — in `worker-rules.md` and `reviewer-rules.md` for subagent context loading.

### Success Criteria
- Every PR with structural changes gets a specific, actionable drift comment
- `/audit-docs` run takes under 3 minutes and produces a fix-ready report
- CLAUDE.md is under 150 lines with zero loss of effective instruction coverage
- Zero stale file path references in `.claude/` after initial cleanup
- The mapping config stays current because `/audit-docs` regenerates it
- Subagent workers reliably load domain context via routing table (verified by smoke test)

---

## Doc-Drift Mapping Config (`doc-drift-map.json`)

### Purpose
Bridge between CI workflow and local skill. Maps codebase path patterns to the documentation files that describe those areas.

### Structure

```json
{
  "version": 1,
  "generated_at": "2026-04-05T14:30:00Z",
  "generated_by": "audit-docs",
  "zones": [
    {
      "pattern": "lib/features/sync/**",
      "docs": [
        ".claude/rules/sync/sync-patterns.md",
        ".claude/docs/features/sync-overview.md",
        ".claude/architecture-decisions/sync-constraints.md"
      ],
      "claude_md_sections": ["Sync Architecture"],
      "signals": ["new_file", "deleted_file", "renamed_file", "new_export"]
    },
    {
      "pattern": "lib/core/database/**",
      "docs": [
        ".claude/rules/database/schema-patterns.md",
        ".claude/docs/features/database-overview.md"
      ],
      "claude_md_sections": ["Database"],
      "signals": ["new_file", "deleted_file", "renamed_file"]
    },
    {
      "pattern": "lib/features/*/presentation/**",
      "docs": [
        ".claude/rules/frontend/flutter-ui.md"
      ],
      "claude_md_sections": [],
      "signals": ["new_file", "deleted_file"]
    }
  ],
  "global_checks": {
    "new_feature_dir": {
      "pattern": "lib/features/*/",
      "docs": [".claude/CLAUDE.md"],
      "sections": ["Project Structure"]
    },
    "new_agent_or_skill": {
      "pattern": ".claude/{agents,skills}/**",
      "docs": [".claude/CLAUDE.md"],
      "sections": ["Pointers"]
    },
    "workflow_change": {
      "pattern": ".github/workflows/**",
      "docs": [".claude/rules/ci-cd.md"],
      "sections": []
    }
  },
  "path_references": {
    ".claude/CLAUDE.md": ["lib/core/di/app_providers.dart", "lib/core/bootstrap/app_initializer.dart"],
    ".claude/rules/sync/sync-patterns.md": ["lib/features/sync/engine/sync_engine.dart"],
    ".claude/architecture-decisions/sync-constraints.md": ["lib/features/sync/"]
  }
}
```

### Design Decisions
- **`zones`** — maps codebase path globs to doc files that describe that area. Primary detection mechanism.
- **`signals`** — what kind of change triggers a flag. Not every edit matters. New/deleted/renamed files almost always cause drift. Modifications usually don't.
- **`claude_md_sections`** — specific section headers within CLAUDE.md. Allows CI to say "check the Sync Architecture section" not just "check CLAUDE.md."
- **`global_checks`** — structural changes affecting top-level docs (new feature directory, new agent, workflow changes).
- **`path_references`** — explicit file paths mentioned inside doc files. If a referenced file gets deleted or renamed, that's an immediate flag.
- **Generated, not hand-maintained** — `/audit-docs` rebuilds this from scratch each run.

---

## GitHub Action CI Workflow (`doc-drift.yml`)

### Trigger
Runs on every PR to `main`. Lightweight — no Flutter SDK, no API keys, just bash + jq.

### What It Does
1. **Read the mapping** — loads `.claude/doc-drift-map.json` from the PR branch
2. **Get the diff** — `git diff --name-status origin/main...HEAD`
3. **Filter by signals** — only flag files matching configured signals (new, deleted, renamed)
4. **Zone matching** — for each flagged file, find which zones it belongs to and which docs are affected
5. **Path reference check** — grep mapping's `path_references` for deleted/renamed paths
6. **Global checks** — detect new feature directories, new agents/skills, workflow changes
7. **Post PR comment** — structured markdown with findings, or "no drift detected"

### PR Comment Format

When drift is detected:
```markdown
## Documentation Drift Check

**3 potential drift signals detected in this PR.**

### Zone: `lib/features/sync/**`
| Signal | File | Docs to check |
|--------|------|---------------|
| New file | `lib/features/sync/engine/trigger_state_store.dart` | `rules/sync/sync-patterns.md`, `docs/features/sync-overview.md` |
| New file | `lib/features/sync/application/sync_coordinator.dart` | `rules/sync/sync-patterns.md`, `architecture-decisions/sync-constraints.md` |

### Stale References
| Doc file | References | Status |
|----------|-----------|--------|
| `architecture-decisions/sync-constraints.md` | `lib/features/sync/engine/old_file.dart` | Deleted in this PR |

### Action
Run `/audit-docs` locally for deep analysis and fix suggestions.

---
*Generated by doc-drift.yml from `.claude/doc-drift-map.json`*
```

When clean:
```markdown
## Documentation Drift Check
No structural drift signals detected.
```

### Properties
- **Runner**: `ubuntu-latest` — no Flutter needed
- **Permissions**: `contents: read`, `pull-requests: write`
- **Dependencies**: `jq` only (pre-installed)
- **Runtime**: <30 seconds
- **Cost**: $0 (no API keys, no LLM calls)
- **Idempotent**: Updates existing comment on re-push
- **Non-blocking**: Informational only, never blocks merge

### Edge Cases
- If `doc-drift-map.json` doesn't exist: warning comment "run `/audit-docs` to generate"
- If mapping >30 days old: staleness warning in comment
- If >15 signals: collapse zone details into `<details>` tags, lead with summary
- PR touching only test files: still runs, usually produces clean result

---

## `/audit-docs` Skill

### Purpose
Intelligent local counterpart to CI. Uses CodeMunch for semantic analysis that bash can't do — class renames, hierarchy changes, pattern drift, missing coverage. Produces fix-ready report and regenerates mapping config.

### Replaces
`/audit-config` — renamed and expanded. Existing security invariant checks preserved as Phase 5.

### Invocation
```
/audit-docs              # Full audit
/audit-docs --regen-map  # Just regenerate doc-drift-map.json
```

### Phase 1: Index
- `mcp__jcodemunch__index_folder` with AI summaries
- Reuse recent index if <1 hour old

### Phase 2: Structural Scan
- `get_file_tree` → current codebase structure
- Grep all in-scope `.claude/` files for file path references
- Compare every referenced path against disk — flag broken ones
- `search_symbols` for class/model names mentioned in docs — flag missing ones

### Phase 3: Semantic Analysis
- `get_class_hierarchy` for key domain classes → compare against architecture-decisions
- `get_file_outline` for files referenced in rules → do rules still describe actual structure?
- `find_dead_code` → are docs referencing deprecated/dead symbols?
- `get_blast_radius` on recently changed files → did changes ripple to uncovered areas?

### Phase 3.5: Pattern Discovery
Targeted anomaly detection to surface non-obvious codebase patterns that should be documented:

1. **Convention deviation scan** — find patterns where 90% of usage follows one convention but a few callsites don't. Flag as potential gotchas. Example: "All 35 datasources use `execute()` for SQL, but `database_service.dart` uses `rawQuery()` for 3 calls."
2. **Coupling scan** — `get_dependency_graph` + `get_blast_radius` on core files. When file A has 15+ dependents, verify A's behavior is documented proportionally to its blast radius.
3. **Guard clause scan** — grep for `// WHY:`, `// HACK:`, `// IMPORTANT:`, `// NOTE:`, `// WORKAROUND:` comments. If code has a `// WHY:` but no corresponding gotcha in docs, flag it.
4. **Ordering dependency scan** — look for code where declaration order matters (provider registrations, migration sequences, DI tiers).

Output:
```markdown
## Potential Undocumented Patterns
| Location | Pattern | Deviation | Documented? |
|----------|---------|-----------|-------------|
| database_service.dart:142 | rawQuery for PRAGMA | 3/480 SQL calls | CLAUDE.md Gotchas |
| sync_engine.dart:203 | // WHY: mutex release | No convention match | Not documented |
```

### Phase 4: Coverage Check
- For each `lib/features/*/` directory: matching `docs/features/`, `architecture-decisions/`, and rule zone?
- For each agent: do `@` import references resolve to existing files?
- For each agent: do layer scope paths in body match existing directories?
- For each agent: is model set to opus?
- For each memory entry: is referenced behavior still accurate? (flag for manual review)
- Verify routing tables in `worker-rules.md` and `reviewer-rules.md` cover all `lib/` directories
- No two agents claim ownership of overlapping paths

### Phase 5: Security Invariants (preserved from audit-config)
- Agent tool permissions correct
- Security-agent is read-only (`disallowedTools: Write, Edit, Bash`)
- Security-agent body contains "NEVER MODIFY CODE. REPORT ONLY."
- CLAUDE.md contains "Security is non-negotiable"
- Constraint files have expected MUST/MUST NOT counts
- Auth and sync rule files contain RLS/token storage sentinel strings

### Phase 6: Regenerate Mapping
- Build fresh `doc-drift-map.json` from phases 2-4
- Zones from: which doc files reference which codebase paths
- Path references from: grep of all doc files for `lib/` paths
- Write to `.claude/doc-drift-map.json`

### Phase 7: Report
Save to `.claude/outputs/audit-docs-report-YYYY-MM-DD.md`:

```markdown
# Documentation Audit — YYYY-MM-DD

**Index**: [N] files, [N] symbols
**Scanned**: [N] .claude/ files

## Broken References (auto-fixable)
| Doc file | Line | Reference | Status | Suggested fix |
|----------|------|-----------|--------|---------------|

## Stale Content (needs review)
| Doc file | Issue | Details |
|----------|-------|---------|

## Missing Coverage
| Codebase area | Missing doc |
|---------------|-------------|

## Undocumented Patterns
| Location | Pattern | Deviation | Documented? |
|----------|---------|-----------|-------------|

## Security Invariants
[PASS/FAIL per check]

## Agent Health
[Per-agent: imports valid, model correct, no stale references]

## Mapping Regenerated
Updated .claude/doc-drift-map.json ([N] zones, [N] path references)
```

### Phase 8: Present & Gotcha Graduation
Display summary, then offer:
- A) Apply auto-fixes (reference updates only — never rewrites prose or architectural decisions)
- B) Open report for manual review
- C) Just regenerate mapping, skip fixes

Then prompt: "Did you encounter any non-obvious behaviors during this session that aren't captured above? Describe in one sentence and I'll add it to the right place."

### Constraints
- Auto-fixes limited to reference updates (path renames, symbol renames)
- Semantic findings always flagged for manual review
- Security invariants are read-only report only
- CodeMunch unavailable: fall back to Glob + Grep + Read for structural scan; skip semantic analysis and pattern discovery with warning

---

## CLAUDE.md Slimdown

### Sections Removed (discoverable by Claude)
- **Feature Inventory table** (~22 lines) — `ls lib/features/` gets this
- **Key Files table** (~10 lines) — Claude finds these naturally
- **Domain Rules table** (~12 lines) — rules auto-load via `paths:` frontmatter
- **Repositories table** (~5 lines) — moved to memory entry

### Sections Moved
- **CI/CD details** (~10 lines) — moved to new path-scoped rule `.claude/rules/ci-cd.md` triggered by `.github/workflows/**`

### Sections Trimmed
- **Project Structure** — keep top-level tree only, remove subdirectory detail
- **Pointers table** — remove rows for things Claude discovers via skills/agents auto-loading

### Sections Kept (not discoverable)
- App Identity, Data Flow, Sync Architecture, Gotchas, Custom Lint, Database, Quick Reference Commands, Common Mistakes, Session & Workflow, Context Efficiency

### Target: ~130-140 lines (down from ~215)

---

## Rules → Recognition + Procedure Split

### Principle
- **Keep in rule (30-50 lines)**: constraints, naming conventions, invariants, gotchas — what Claude needs on every file touch
- **Move to procedure guide**: step-by-step procedures, templates, code examples, checklists — what Claude needs only when building something new
- **Pointer line at bottom of each rule**: "For implementation templates, see `.claude/skills/implement/references/<name>-guide.md`"

### Split Plan

| Rule file | Current | Recognition (keep) | Procedure (extract) |
|-----------|---------|-------------------|-------------------|
| `sync/sync-patterns.md` | 448 lines | ~50 lines | ~400 lines → `sync-patterns-guide.md` |
| `auth/supabase-auth.md` | 350 lines | ~40 lines | ~310 lines → `auth-patterns-guide.md` |
| `testing/patrol-testing.md` | 329 lines | ~40 lines | ~290 lines → `testing-guide.md` |
| `backend/data-layer.md` | 326 lines | ~40 lines | ~286 lines → `data-layer-guide.md` |
| `architecture.md` | 305 lines | ~60 lines | ~245 lines → `architecture-guide.md` |
| `pdf/pdf-generation.md` | 279 lines | ~30 lines | ~249 lines → `pdf-generation-guide.md` |
| `frontend/flutter-ui.md` | 272 lines | ~40 lines | ~232 lines → `flutter-ui-guide.md` |
| `platform-standards.md` | 260 lines | ~30 lines | ~230 lines → `platform-standards-guide.md` |
| `database/schema-patterns.md` | 248 lines | ~40 lines | ~208 lines → `schema-patterns-guide.md` |
| `backend/supabase-sql.md` | 186 lines | ~30 lines | ~156 lines → `supabase-sql-guide.md` |
| `frontend/ui-prototyping.md` | 48 lines | **Keep as-is** | — |

**New rule**: `.claude/rules/ci-cd.md` (~20 lines, path-scoped on `.github/workflows/**`)

### Result
- **Before**: 3,051 lines of path-loaded rules
- **After**: ~430 lines of recognition rules + ~2,600 lines in procedure guides (loaded only during implementation)
- Procedure guides stored at: `.claude/skills/implement/references/`

---

## Domain Context Routing Tables

### Purpose
Enable subagent workers and reviewers to load the right domain context from slimmed rule files based on what files they're working on. Placed in `worker-rules.md` and `reviewer-rules.md`.

### Routing Table

```markdown
## Domain Context Loading
Before starting work, read the applicable rule files based on the files you will modify:

| File pattern | Read before working |
|-------------|-------------------|
| lib/**/data/** | .claude/rules/backend/data-layer.md |
| lib/core/database/** | .claude/rules/database/schema-patterns.md |
| lib/**/presentation/**, lib/shared/widgets/** | .claude/rules/frontend/flutter-ui.md |
| lib/features/sync/** | .claude/rules/sync/sync-patterns.md |
| lib/features/auth/** | .claude/rules/auth/supabase-auth.md |
| lib/features/pdf/** | .claude/rules/pdf/pdf-generation.md |
| test/**, integration_test/** | .claude/rules/testing/patrol-testing.md |
| .github/workflows/** | .claude/rules/ci-cd.md |
| lib/core/di/**, lib/core/bootstrap/**, lib/core/router/** | .claude/rules/architecture.md |
| supabase/** | .claude/rules/backend/supabase-sql.md |
| android/**, ios/**, windows/** | .claude/rules/platform-standards.md |

This is mandatory. Read the matching files before writing any code.
```

### Verification
- Phase 2 smoke test: worker outputs "Domain context loaded: [filenames]" (temporary debug line, removed after verification)
- `/audit-docs` Phase 4 verifies routing table covers all `lib/` directories
- Escape hatch: if routing table compliance is unreliable, migrate to `skills:` wrapper approach (mechanical, ~2 hours)

---

## Agent Restructure

### Design Principle
Agents are **role-based** (what they do), not **domain-based** (what they know). Domain knowledge lives in `.claude/rules/` and is loaded via routing tables.

### Retired Agents
| Agent | Reason | Knowledge Migration |
|-------|--------|-------------------|
| `backend-data-layer-agent` | Domain → rules, role → implementer workers | Rules: `data-layer.md`, `schema-patterns.md`, `architecture.md` |
| `backend-supabase-agent` | Domain → rules, role → implementer workers | Rules: `supabase-sql.md`, `sync-patterns.md` |
| `frontend-flutter-specialist-agent` | Domain → rules, role → implementer workers | Rules: `flutter-ui.md`, `architecture.md` |

Memory files for retired agents archived to `agent-memory/retired/`.

### Kept Agents (10 total)

| Agent | Role | Model | Read-Only | Updates Needed |
|-------|------|-------|-----------|----------------|
| auth-agent | Auth flows (security-sensitive) | opus | No | Fix frontmatter, add routing table ref |
| pdf-agent | PDF pipeline (specialized domain) | opus | No | Fix frontmatter, fix model |
| code-review-agent | Code quality review | opus | Yes | Add routing table ref |
| security-agent | Security audit | opus | Yes | Add routing table ref |
| completeness-review-agent | Spec compliance | opus | Yes | Fix model if needed |
| code-fixer-agent | Fix review findings | opus | No | Add routing table ref, fix model |
| qa-testing-agent | Write/run tests | opus | No | Add routing table ref, fix model |
| plan-writer-agent | Write plans | opus | Write-only | Already correct |
| plan-fixer-agent | Fix plans | opus | Edit-only | Fix model |
| debug-research-agent | Research bugs | opus | Yes | Fix model |

### All Agent Updates
- Remove `specialization:` from YAML frontmatter (silently ignored by Claude Code)
- Move any useful specialization content to markdown body
- Set `model: opus` on all agents
- Add domain context routing table reference to body of implementation/review agents
- Verify all `@` imports resolve to existing files

---

## Implementation Phasing

### Phase 1: CLAUDE.md Slimdown (Size: S)
- Remove Feature Inventory, Key Files, Domain Rules table, Repositories
- Move CI/CD to new path-scoped rule
- Trim Project Structure and Pointers table
- Target: ~130-140 lines

### Phase 2: Rules Split + Agent Cleanup (Size: M)
- Split 10 rule files into recognition (30-50 lines) + procedure guides
- Create domain context routing tables in worker-rules.md and reviewer-rules.md
- Retire 3 domain agents, archive their memory files
- Update all remaining agents (frontmatter fixes, model standardization, routing table refs)
- Smoke test: verify worker loads domain context via routing table
- Escape hatch: if smoke test fails, create skills wrappers instead

### Phase 3: `/audit-docs` Skill (Size: M)
- Rename audit-config → audit-docs, implement all 8 phases
- Pattern discovery (Phase 3.5) and gotcha graduation prompt
- First run generates initial `doc-drift-map.json`
- First run produces baseline audit report

### Phase 4: `doc-drift.yml` GitHub Action (Size: S)
- Lightweight bash + jq workflow
- Reads mapping, analyzes PR diff, posts comment
- Informational only — never blocks merge
- Test with a real PR

---

## Edge Cases & Risks

### Mapping Staleness
- **Risk**: `doc-drift-map.json` goes stale if `/audit-docs` not run for a while
- **Mitigation**: CI checks `generated_at`, warns if >30 days old

### False Positives
- **Risk**: CI flags irrelevant changes
- **Mitigation**: Signal filtering (only new/deleted/renamed, not modified). Informational only — costs 5 seconds of reading.

### False Negatives
- **Risk**: Semantic changes (class renames) slip through CI
- **Mitigation**: CI is cheap first layer. `/audit-docs` with CodeMunch catches semantic drift.

### Pattern Discovery Noise
- **Risk**: Too many false anomalies
- **Mitigation**: Improves over time as real gotchas are promoted. Could add `.claude/doc-drift-ignore.json` if needed.

### Agent Context Loading Failure
- **Risk**: Workers don't reliably read routing table
- **Mitigation**: Smoke test during Phase 2. Escape hatch: migrate to `skills:` wrappers (~2 hours).

### CodeMunch Unavailability
- **Risk**: MCP server down or hangs
- **Mitigation**: Fall back to Glob + Grep + Read. Skip semantic analysis and pattern discovery with warning.

### Large PR Overwhelm
- **Risk**: 50+ file PR produces noisy comment
- **Mitigation**: Group by zone, collapse details into `<details>` tags if >15 signals.

---

## Security Implications

### Preserved Invariants
- Security-agent remains read-only (`disallowedTools: Write, Edit, Bash`)
- Security-agent body contains "NEVER MODIFY CODE. REPORT ONLY."
- CLAUDE.md contains "Security is non-negotiable"
- Auth/sync rules contain RLS and token storage sentinel strings (verified post-split)

### New Considerations
- `doc-drift.yml` needs `pull-requests: write` for comments, `contents: read` only. No API keys.
- `/audit-docs` auto-fixes limited to reference updates. Never rewrites security rules or architectural decisions.
- Routing table is advisory, not a security boundary. Write permissions enforced by agent `tools`/`disallowedTools`.

No new attack surfaces. No credential exposure. No RLS changes.

---

## Testing Strategy

| Component | Test Method | Phase |
|-----------|-----------|-------|
| CLAUDE.md slimdown | Manual review — no information loss | 1 |
| Rules split | `/implement` smoke test — worker loads correct files | 2 |
| Worker routing table | Debug line — "Domain context loaded: [files]" | 2 |
| Agent frontmatter fixes | Verify no `specialization:` in YAML, all models opus | 2 |
| `/audit-docs` structural scan | Run against codebase, verify broken refs detected | 3 |
| `/audit-docs` semantic analysis | Run with CodeMunch, verify class rename detection | 3 |
| `/audit-docs` mapping generation | Verify valid JSON with correct zones | 3 |
| `/audit-docs` pattern discovery | Run once, verify anomaly candidates surfaced | 3 |
| `doc-drift.yml` — drift detected | Test PR with new file → comment appears | 4 |
| `doc-drift.yml` — clean PR | Test PR with bug fix only → "no drift" comment | 4 |
| `doc-drift.yml` — stale mapping | Set old `generated_at` → staleness warning | 4 |
| End-to-end | Push branch → CI flags → `/audit-docs` → fixes → CI clean | 4 |

---

## Decisions Log

| Decision | Choice | Alternatives Rejected | Rationale |
|----------|--------|----------------------|-----------|
| CI approach | Deterministic script (no LLM) | Full LLM CI action, no CI | Free, fast, no API key needed |
| Local tool | CodeMunch-powered skill | Manual review only | Semantic analysis catches what scripts miss |
| Mapping maintenance | Generated by skill, consumed by CI | Hand-maintained, no mapping | Self-healing, single source of truth |
| Auto-fix scope | Reference updates only | Full auto-rewrite, no auto-fix | Safe — never changes intent or prose |
| Rules architecture | Merged recognition rules serve main + subagents | Separate layers/ directory, skills wrappers | Single source of truth, minimal maintenance |
| Agent philosophy | Role-based (10 agents) | Domain-based (16 agents), current (13) | Cleaner boundaries, domain context decoupled |
| Subagent context loading | Read-based routing table | skills: frontmatter wrapping | Selective loading, no wrapper maintenance |
| CLAUDE.md content | Remove discoverable content | Keep everything, separate file | Reduces always-loaded overhead, improves quality |
| Historical artifacts | Keep in place | Archive or delete | No context pollution (on-demand only) |
| Merge blocking | Never — informational only | Required gate, optional gate | Encourages habits without bureaucracy |
