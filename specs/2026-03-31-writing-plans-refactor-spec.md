# Writing-Plans Skill Refactor Spec

**Date**: 2026-03-31
**Status**: APPROVED

---

## 1. Overview

### Purpose
Refactor the writing-plans skill to use headless `claude --agent` for plan writing, replacing the Agent tool subagent approach that suffers from permission inheritance failures. The research and review phases stay as-is (main agent + Agent tool subagents respectively).

### Scope
- **IN**: New plan-writer-agent, completeness-review-agent, plan-fixer-agent, code-fixer-agent definitions. Full rewrite of writing-plans skill.md. Updated CodeMunch research sequence. Context bundle staging workflow. Fix → re-review loop. Implement skill updates for new agents.
- **OUT**: No changes to brainstorming skill. No changes to existing review agents (code-review, security). No changes to plan format template.

### Success Criteria
- Headless plan writers can produce and save complete plan files without permission failures
- Multi-writer plans concatenate cleanly with structural consistency
- All 3 review sweeps run and the fix loop iterates until pass (max 3 cycles)
- Ground truth verification happens in both research phase and code-review sweep
- Completeness reviewer catches spec drift
- Implement skill uses completeness-review-agent and code-fixer-agent

---

## 2. Architecture

### Flow
```
Main Agent (has MCP access)
  ├─ Phase 1: Read spec
  ├─ Phase 2: CodeMunch research sequence (prescribed)
  │     index_folder → get_file_outline (all spec files) → get_dependency_graph →
  │     get_blast_radius → find_importers → get_class_hierarchy →
  │     find_dead_code → search_symbols → get_symbol_source
  │     (optional: get_ranked_context, get_context_bundle)
  ├─ Phase 3: Ground truth verification (verify all symbols/paths found in research)
  ├─ Phase 4: Save consolidated analysis.md to .claude/dependency_graphs/
  ├─ Phase 5: Build context bundle in .claude/plans/staging/
  │     (spec + analysis + source excerpts + plan format template + routing table)
  ├─ Phase 6: Determine writer count + split strategy from dependency graph
  │     (parallel by default, sequential when cross-phase deps require it)
  ├─ Phase 7: Launch headless plan writer(s) via Bash
  │     claude --agent plan-writer-agent --print --permission-mode acceptEdits
  │     Each writer reads context bundle, writes their section
  ├─ Phase 8: Concatenate + structural check (numbering, file dedup)
  ├─ Phase 9: 3 review sweeps in parallel (Agent tool subagents)
  │     ├─ code-review-agent (includes ground truth double-check)
  │     ├─ security-agent
  │     └─ completeness-review-agent (spec guardian)
  │     Reports saved to .claude/plans/review_sweeps/<plan-name>-<date>/
  ├─ Phase 10: Plan fixer agent (Agent tool subagent) addresses ALL findings
  │     unless they stray from spec intent
  └─ Phase 11: Loop → full 3-sweep re-review → fix → max 3 cycles → escalate
```

### Key Boundaries
- Only the main agent touches CodeMunch MCP tools
- Only headless agents write plan files (via Bash tool, `claude --agent plan-writer-agent --print`)
- Review agents are Agent tool subagents (read-only, no permission issue)
- Fixer agent is Agent tool subagent (Read/Edit/Grep/Glob — edits existing plan)
- Ground truth verification happens in BOTH research phase (main agent) AND code-review sweep (double-check)
- Completeness reviewer treats the spec as sacred source of truth — catches drift, gaps, and lazy shortcuts

### Writer Split Strategy
- Main agent determines split from dependency graph analysis
- Split by natural boundaries in the dependency graph (the main agent decides cut points)
- Parallel by default, sequential only when cross-phase dependencies require it
- Single writer for smaller plans, multiple writers when the dependency graph shows natural boundaries

---

## 3. CodeMunch Research Sequence

Prescribed sequence — ALL steps mandatory except where noted:

1. `mcp__jcodemunch__index_folder` — project root, `incremental: true`, `use_ai_summaries: true`
2. `mcp__jcodemunch__get_file_outline` — every file listed in "Files to Modify" in the spec
3. `mcp__jcodemunch__get_dependency_graph` — for all key files identified
4. `mcp__jcodemunch__get_blast_radius` — for all symbols being changed
5. `mcp__jcodemunch__find_importers` — for all symbols being changed (who calls this?)
6. `mcp__jcodemunch__get_class_hierarchy` — for classes involved in the change
7. `mcp__jcodemunch__find_dead_code` — identify cleanup targets
8. `mcp__jcodemunch__search_symbols` — for every key symbol mentioned in the spec
9. `mcp__jcodemunch__get_symbol_source` — full source of each relevant symbol
10. *(Optional)* `mcp__jcodemunch__get_ranked_context` — when additional context prioritization is needed
11. *(Optional)* `mcp__jcodemunch__get_context_bundle` — when bundled context would help

**NOT used**: `get_repo_outline` (fetches from GitHub), `index_repo` (fetches from GitHub — freezes)

---

## 4. Analysis Report

Single consolidated file saved to `.claude/dependency_graphs/YYYY-MM-DD-<name>/analysis.md`:

- Direct changes (files, symbols, line ranges, change type)
- Dependent files (callers, consumers — 2+ levels via find_importers)
- Dependency graph (upstream deps via get_dependency_graph)
- Blast radius summary (via get_blast_radius)
- Class hierarchy (via get_class_hierarchy)
- Dead code to clean up (via find_dead_code)
- Import chains (via find_importers)
- Method signatures and reusable logic patterns (via get_symbol_source)
- Verified ground truth (all string literals, paths, symbols cross-referenced against codebase)
- Data flow diagram (ASCII)
- Blast radius summary counts

---

## 5. Context Bundle

Single file saved to `.claude/plans/staging/YYYY-MM-DD-<name>-context.md`. This is the ONLY file the headless plan writer reads.

Contents:
- Full spec content (pasted inline from `.claude/specs/`)
- Full analysis.md content (pasted inline from `.claude/dependency_graphs/`)
- Verified source excerpts (key symbol sources organized by file)
- Plan format template (phase/sub-phase/step hierarchy, code annotations, verification commands)
- Agent routing table (file pattern → agent mapping for the implement orchestrator)
- Writer instructions (output path, phase assignment, multi-writer coordination notes)

The context bundle is ephemeral — deleted after the plan is finalized.

---

## 6. Headless Plan Writer Invocation

```bash
unset CLAUDECODE && claude --agent plan-writer-agent --print --permission-mode acceptEdits \
  --output-format text \
  "Read the context bundle at <path>. Write the implementation plan to <output-path>. Follow the plan format template exactly. Include complete code for every step with WHY/NOTE/FROM SPEC annotations." \
  2>&1 | tee .claude/outputs/plan-writer-N-output.txt
```

- `unset CLAUDECODE` — bypasses nested-session protection
- `--print` — non-interactive headless mode
- `--permission-mode acceptEdits` — auto-approves file writes
- `--output-format text` — plain text output
- `| tee` — capture output to file AND display
- `run_in_background: true` — always run as background Bash task

For multi-writer: each writer gets a separate context bundle with its phase assignment. All launched in parallel (or sequentially when deps require it). Main agent concatenates outputs after all complete.

---

## 7. Review Sweeps

3 review agents dispatched in parallel via Agent tool after plan concatenation:

| Agent | subagent_type | model | Focus |
|-------|--------------|-------|-------|
| Code Review | `code-review-agent` | opus | Code quality, DRY/KISS, correctness, ground truth verification (double-check all literals against codebase) |
| Security | `security-agent` | opus | Security vulnerabilities, auth gaps, RLS implications, data exposure |
| Completeness | `completeness-review-agent` | opus | Spec guardian — does the plan fully capture the spec's intent? Flags drift, gaps, lazy shortcuts, missing requirements |

Reports saved to `.claude/plans/review_sweeps/<plan-name>-<date>/`:
- `code-review.md`
- `security-review.md`
- `completeness-review.md`

---

## 8. Fix → Re-Review Loop

1. After review sweeps complete, consolidate ALL findings
2. Dispatch `plan-fixer-agent` (Agent tool subagent) with all findings
   - Fixes ALL findings unless they stray from spec intent
   - Surgical edits — finds the right place in the plan, adds/removes/modifies
   - Never rewrites the entire plan
3. After fixer completes, run ALL 3 review sweeps again (full re-review)
4. Max 3 cycles — if still failing after 3 rounds, escalate to user
5. Each cycle's reports saved to the same review_sweeps directory (suffixed with cycle number)

---

## 9. Implement Skill Updates

Changes to `.claude/agents/implement-orchestrator.md` and `.claude/skills/implement/skill.md`:

### Agent Catalog Updates

| Role | Current | New |
|------|---------|-----|
| Completeness reviewer | `general-purpose`, sonnet | `completeness-review-agent`, opus |
| Fixer | `general-purpose`, sonnet | `code-fixer-agent`, sonnet |

The review/fix loop structure (max 3 cycles, parallel dispatch, severity standard) remains the same. Only the agent references change.

---

## 10. New Agent Definitions

### plan-writer-agent.md
- **Model**: Opus
- **Tools**: Read, Write, Glob, Grep
- **permissionMode**: acceptEdits
- **Purpose**: Reads context bundle, writes plan sections following the plan format template exactly. Headless only — never dispatched via Agent tool.

### completeness-review-agent.md
- **Model**: Opus
- **Tools**: Read, Grep, Glob
- **Purpose**: Spec guardian. Reads spec + plan + codebase + analysis report. Verifies every spec requirement is captured in the plan. Flags drift, gaps, lazy shortcuts, missing requirements. Treats the spec as the sacred source of truth for user intent.

### plan-fixer-agent.md
- **Model**: Sonnet
- **Tools**: Read, Edit, Grep, Glob
- **permissionMode**: acceptEdits
- **Purpose**: Surgical edits to plan documents based on review findings. Finds the correct location in the plan, adds/removes/modifies content. Never rewrites entire plans.

### code-fixer-agent.md
- **Model**: Sonnet
- **Tools**: Read, Edit, Write, Bash, Grep, Glob
- **permissionMode**: acceptEdits
- **Purpose**: Fixes implemented code based on review findings. Used by the implement orchestrator during the review/fix loop.

---

## 11. File Manifest

### New Files to CREATE

| File | Purpose |
|------|---------|
| `.claude/agents/plan-writer-agent.md` | Headless plan writer agent definition |
| `.claude/agents/completeness-review-agent.md` | Spec guardian reviewer agent definition |
| `.claude/agents/plan-fixer-agent.md` | Plan document fixer agent definition |
| `.claude/agents/code-fixer-agent.md` | Code fixer agent definition (for implement skill) |

### Files to MODIFY

| File | Change |
|------|--------|
| `.claude/skills/writing-plans/skill.md` | Full rewrite — headless plan writers, prescribed CodeMunch sequence, context bundle, review/fix loop |
| `.claude/agents/implement-orchestrator.md` | Swap completeness reviewer to completeness-review-agent opus, swap fixer to code-fixer-agent sonnet |
| `.claude/skills/implement/skill.md` | Update agent catalog references to match orchestrator changes |

### New Directories

| Directory | Purpose |
|-----------|---------|
| `.claude/plans/staging/` | Ephemeral context bundles for plan writers |
| `.claude/plans/review_sweeps/` | Review reports organized per plan |

### No Changes To
- `.claude/agents/code-review-agent.md`
- `.claude/agents/security-agent.md`
- `.claude/skills/brainstorming/skill.md`
- Plan format template (phase/sub-phase/step hierarchy, annotations, verification commands)

---

## Decisions Made

1. **Headless mode for plan writers** — bypasses the Agent tool subagent permission inheritance bug entirely by running as a fresh top-level process
2. **Agent tool for reviewers** — reviewers are read-only, no permission issue, faster to dispatch in parallel
3. **Agent tool for fixers** — plan-fixer uses Edit (not Write), code-fixer needs full tool access
4. **Context bundle as single file** — consolidates all research into one read for the headless writer
5. **Prescribed CodeMunch sequence** — mandatory steps ensure consistent, thorough research every time
6. **Ground truth verification in both research AND review** — catches assumed names at two points
7. **Completeness reviewer as dedicated agent** — spec is sacred, drift detection is a first-class concern
8. **Separate plan-fixer and code-fixer** — clean separation of concerns, different tool needs
9. **Full 3-sweep re-review after each fix cycle** — no shortcuts, max 3 cycles before escalation
10. **Writer split from dependency graph** — natural boundaries, parallel by default, sequential when deps require it
11. **`use_ai_summaries: true`** — per user feedback memory, always use AI summaries when indexing
12. **No `get_repo_outline` or `index_repo`** — both fetch from GitHub, only local indexing via `index_folder`
