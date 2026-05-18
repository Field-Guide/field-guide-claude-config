---
name: resume-session
description: Fast session resume - load state, display summary, ready to work
user-invocable: true
disable-model-invocation: true
---

# Resume Session

Fast context load. No questions — just read state and display summary.

**CRITICAL**: NO git commands anywhere in this skill.

## Actions

### Step 1: Read HOT Context (2 files only)
1. `.claude/memory/MEMORY.md` - Key learnings and patterns
2. `.claude/autoload/_state.md` - Current state

**DO NOT READ** (lazy load only when needed):
- `.claude/logs/state-archive.md`
- `.claude/logs/defects-archive.md`
- `.claude/logs/archive-index.md`
- Any rules, docs, constraints, or state JSON files

### Step 2: Display Summary

Print this compact format:

```
**Phase**: [From _state.md]
**Status**: [From _state.md]
**Last Session**: [1-line summary from most recent session entry]

**Next Tasks**:
1. [From _state.md "What Needs to Happen Next"]
2. [...]
3. [...]

Ready — what are we working on?
```

That's it. No questions. No context loading. The user's first message IS the intent.

### Step 3: Return Control

Wait for the user to say what they want. Their message determines what happens next:
- If they name a feature -> load the smallest relevant slice through `.codex/CLAUDE_CONTEXT_BRIDGE.md`, current `.claude/rules/`, active plans/specs, and repo code.
- If they ask about status -> prefer `.codex/PLAN.md`, `.claude/autoload/_state.md`, and only then deeper state files if needed.
- If they want to debug -> use the relevant rules, active plans/specs, GitHub Issues, and current code paths as needed.

**Do NOT pre-load any feature context, rules, constraints, or docs.**

## Context Loading Reference (for agents, not this skill)

When agents are invoked, they load only the matching current surface:
- **Bridge**: `.codex/CLAUDE_CONTEXT_BRIDGE.md`
- **Rules**: `.claude/rules/**` by domain
- **Plans/specs**: `.codex/PLAN.md`, matching `.codex/plans/`, `.claude/plans/`, `.claude/specs/`, or `.claude/tailor/`
- **State**: `.claude/autoload/_state.md`, `.claude/memory/MEMORY.md`, and `.claude/state/PROJECT-STATE.json` only when status depth requires it
- **Defects**: GitHub Issues or current code evidence when the task requires live triage

## Rules
- **NO git commands** — not `git status`, not `git log`, not any git operation
- **NO questions** — display summary and wait
- **NO pre-loading** — agents handle their own context
- Agent names must match actual filenames in `.claude/agents/`
