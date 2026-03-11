---
name: writing-plans
description: "Use when you have an approved spec for a multi-step task, before touching code. Launches an orchestrator that indexes the codebase, builds dependency graphs, and creates detailed implementation plans by dispatching work to specialized agents."
user-invocable: true
---

# Writing Plans

**Announce at start:** "I'm using the writing-plans skill to launch the plan-writing orchestrator."

## Orchestration Model

This skill does NOT run inline. The main agent spawns a **single orchestrator agent** via the Task tool, which then dispatches sub-tasks to specialized agents.

```
Main Agent (you)
  └─ spawns → Orchestrator (Task tool, subagent_type: general-purpose, model: opus)
                ├─ Phase 1: Read spec + Index codebase (inline, parallel tools)
                ├─ Phase 2: Build dependency graph + blast radius (inline)
                ├─ Phase 3: Write the plan (inline)
                ├─ Phase 4: Adversarial review (dispatches 2 agents in parallel)
                │     ├─ code-review-agent (Task tool)
                │     └─ security-agent (Task tool)
                ├─ Phase 5: Address findings (inline)
                └─ Phase 6: Return plan summary to main agent
```

### What the Main Agent Does

1. Identify the spec file (from user's message or `.claude/specs/`)
2. Spawn the orchestrator with a detailed prompt (see below)
3. Receive the plan summary from the orchestrator
4. Present the summary to the user

### Orchestrator Prompt Template

When spawning the orchestrator, use this prompt structure:

```
You are the plan-writing orchestrator. Your job is to create a comprehensive
implementation plan from an approved spec. You have access to all tools.

**NEVER run `flutter clean`. It is prohibited by the user.**

## Inputs
- Spec file: [path to spec]
- Adversarial review (if exists): [path to adversarial review]

## Your Workflow

### Phase 1: Read Spec + Index Codebase (parallel)
- Read the spec file and extract all requirements
- Also read the adversarial review for NICE-TO-HAVE items
- In parallel: run mcp__jcodemunch__index_folder on the project root
- Then get the repo outline with mcp__jcodemunch__get_repo_outline

### Phase 2: Build Dependency Graph + Blast Radius
- Use CodeMunch search_symbols and get_symbol to trace all affected symbols
- Map callers, callees, cross-cutting concerns (2+ levels deep)
- Categorize impact: DIRECT | DEPENDENT | TEST | CLEANUP
- Save analysis to .claude/dependency_graphs/YYYY-MM-DD-<name>/

### Phase 3: Write the Plan
- Structure as Phase > Sub-phase > Step (see plan format below)
- Assign agents per the routing table
- Include complete code with WHY annotations
- Include verification commands with expected output
- Save to .claude/plans/YYYY-MM-DD-<name>.md

### Phase 4: Adversarial Review (dispatch 2 agents in PARALLEL)
Spawn both agents simultaneously using two Task tool calls in one message:

1. code-review-agent (subagent_type: code-review-agent):
   - Does the plan cover EVERY spec requirement?
   - Are file paths correct? DRY/YAGNI? Test quality?
   - What's missing? What if a step fails?

2. security-agent (subagent_type: security-agent):
   - Security vulnerabilities? Auth gaps? RLS implications? Data exposure?

### Phase 5: Address Findings
- CRITICAL/HIGH: Fix in the plan before returning
- MEDIUM/LOW: Note in plan, address during implementation

### Phase 6: Return Summary
Return a concise summary with:
- Plan file path
- Phase count, sub-phase count, step count
- Files affected (direct, dependent, tests, cleanup)
- Agents involved
- Any unresolved MEDIUM/LOW findings
```

## Plan Format Reference

The orchestrator must follow these standards when writing the plan.

### Plan Document Header

Every plan MUST start with this header:

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** [One sentence]
**Spec:** `.claude/specs/YYYY-MM-DD-<name>-spec.md`
**Analysis:** `.claude/dependency_graphs/YYYY-MM-DD-<name>/`

**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies]
**Blast Radius:** [N direct, N dependent, N tests, N cleanup]

---
```

### Plan Hierarchy

**Phase** = Major milestone (e.g., "Data Layer", "UI Components", "Integration")
**Sub-phase** = Coherent unit of work within a phase (e.g., "Entry Model", "Repository")
**Step** = Single atomic action (2-5 minutes)

### Step Granularity

Each step is ONE action:
- "Write the failing test for X" — step
- "Run test to verify it fails" — step
- "Implement the minimal code" — step
- "Run test to verify it passes" — step

### Task Structure Template

````markdown
## Phase N: [Milestone Name]

### Sub-phase N.M: [Component Name]

**Files:**
- Create: `exact/path/to/file.dart`
- Modify: `exact/path/to/existing.dart:123-145`
- Test: `test/exact/path/to/test.dart`

**Agent**: [agent-name from routing table]

#### Step N.M.1: Write failing test for [specific behavior]

```dart
// WHY: This test verifies [specific behavior] because [reason]
void main() {
  test('should [expected behavior]', () {
    final sut = ClassName();
    final result = sut.methodName(input);
    expect(result, expectedValue);
  });
}
```

#### Step N.M.2: Verify test fails

Run: `pwsh -Command "flutter test test/exact/path/test.dart"`
Expected: FAIL with "[specific error message]"

#### Step N.M.3: Implement minimal code

```dart
// WHY: [Business reason]
// NOTE: Matches pattern in [reference file]
ReturnType methodName(ParamType param) {
  return computedValue;
}
```

#### Step N.M.4: Verify test passes

Run: `pwsh -Command "flutter test test/exact/path/test.dart"`
Expected: PASS
````

### Agent Routing Table

| File Pattern | Agent |
|-------------|-------|
| `lib/**/presentation/**` | `frontend-flutter-specialist-agent` |
| `lib/**/data/**` | `backend-data-layer-agent` |
| `lib/core/database/**` | `backend-data-layer-agent` |
| `lib/features/auth/**` | `auth-agent` |
| `lib/features/pdf/**` | `pdf-agent` |
| `lib/features/sync/**` | `backend-supabase-agent` |
| `supabase/**` | `backend-supabase-agent` |
| `test/**`, `integration_test/**` | `qa-testing-agent` |
| Multiple domains or `.claude/` config | `general-purpose` |

### Phase Ordering Rules

1. **Data layer first** — Models, repositories, datasources before UI
2. **Dependencies before dependents** — If Phase 2 uses Phase 1 output, Phase 1 first
3. **Tests alongside implementation** — Every sub-phase includes test steps
4. **Cleanup last** — Dead code removal in final phase
5. **Integration phase** — Wire everything together after all features

---

## Hard Gate (Pre-Flight Check)

<HARD-GATE>
Do NOT write any plan steps until the orchestrator has:
1. Received and read the approved spec from `.claude/specs/`
2. Completed full codebase indexing with CodeMunch
3. Built the dependency graph and blast radius analysis
4. Saved the analysis to `.claude/dependency_graphs/`
</HARD-GATE>

---

## Code Annotation Standards

Every code block in the plan MUST include annotations where logic isn't self-evident:

```dart
// WHY: [Business reason for this code]
// NOTE: [Pattern choice, references existing convention]
// IMPORTANT: [Non-obvious behavior or gotchas]
// FROM SPEC: [References specific spec requirement]
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Do This Instead |
|--------------|----------------|-----------------|
| Running skill inline | Blows up main context | Spawn orchestrator via Task tool |
| Vague steps ("add validation") | Agent has to think | Complete code with annotations |
| Missing file paths | Agent guesses wrong | Exact `path/to/file.dart:line` |
| Skipping tests | Breaks TDD cycle | Every sub-phase has test steps |
| Giant phases | Hard to track | Break into 2-5 min steps |
| No blast radius analysis | Misses side effects | Always run CodeMunch first |
| No agent assignments | Wrong agent gets work | Route by file pattern |
| No cleanup phase | Leaves dead code | Always include cleanup |
| Sequential adversarial review | Wastes time | Always dispatch both in parallel |

---

## Remember

- **Spawn orchestrator** — never run this skill inline in the main conversation
- **Exact file paths** — always, including line numbers for modifications
- **Complete code** — never "add validation here", always the actual code
- **Annotations** — explain WHY, not just WHAT
- **Verification commands** — `pwsh -Command "flutter test ..."` with expected output
- **Zero-context assumption** — implementing agent knows NOTHING about our codebase
- **DRY, YAGNI, TDD** — every step, every phase
- **No commits in plan** — implement first, commit after verification
- **CodeMunch first** — always index before planning
- **Parallel adversarial review** — code-review + security agents dispatched simultaneously

## Save Location

Plans are saved to: `.claude/plans/YYYY-MM-DD-<feature-name>.md`
