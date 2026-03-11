---
name: implement
description: "Spawn an orchestrator agent to autonomously implement a plan file phase-by-phase using specialized agents, with quality gates, checkpoint recovery, and context handoff support."
user-invocable: true
---

# /implement Skill

Autonomous plan execution via `claude --agent implement-orchestrator`. The supervisor (this conversation) manages the checkpoint, launches the orchestrator as a separate headless process, monitors progress, and handles results.

## Architecture

```
This conversation (supervisor)
  │
  ├─ Initializes checkpoint JSON
  ├─ Launches: claude --agent implement-orchestrator --print (via Bash)
  ├─ Monitors: reads checkpoint file for phase-by-phase progress
  ├─ Reads: orchestrator output (captured to file)
  └─ Handles: DONE → summary, HANDOFF → re-launch, BLOCKED → user prompt
```

The orchestrator runs as a **separate main-thread CLI process** (not a subagent). This gives it:
- Task tool access (can dispatch implementers, reviewers, fixers)
- Its own context window (doesn't consume ours)
- Behavioral self-restriction from its system prompt (won't use Edit/Write/Bash directly)
- `permissionMode: bypassPermissions` (no interactive prompts)

---

## IRON LAW (Supervisor)

NEVER use Edit or Write on source files. The ONLY file you may Write is `.claude/state/implement-checkpoint.json`. Allowed tools: Read, Write (checkpoint only), Bash (orchestrator launch only), and asking the user questions.

NEVER run `flutter clean`. It is prohibited.

---

## Supervisor Workflow

### Step 1: Accept the Plan

1. The user invokes `/implement <plan-path>`. If no path is provided, ask for it.
2. If the user gave a bare filename (e.g. `my-plan.md`), search `.claude/plans/` for the file.
3. Read the plan file. Extract the phase list (names only) so you can present them to the user.
4. Check for an existing checkpoint at `.claude/state/implement-checkpoint.json`:
   - File does not exist → start fresh.
   - File exists and `"plan"` matches the requested plan path → ask the user: "Resume from checkpoint (phases already done: X) or start fresh?"
   - File exists but `"plan"` is a different plan → delete it and start fresh.
5. If starting fresh, initialize the checkpoint now (Write the file):

```json
{
  "plan": "<plan file path>",
  "phases": [
    {
      "name": "Phase N title",
      "status": "pending",
      "reviews": {
        "completeness": {
          "status": "pending",
          "critical": 0, "high": 0, "medium": 0, "low": 0,
          "tests_verified": false,
          "fix_cycles": 0
        },
        "code_review": {
          "status": "pending",
          "critical": 0, "high": 0, "medium": 0, "low": 0,
          "fix_cycles": 0
        },
        "security": {
          "status": "pending",
          "critical": 0, "high": 0, "medium": 0, "low": 0,
          "fix_cycles": 0
        }
      }
    }
  ],
  "modified_files": [],
  "build": "pending",
  "analyze_and_test": "pending",
  "integration_reviews": {
    "completeness": {"status": "pending", "critical": 0, "high": 0, "medium": 0, "low": 0, "fix_cycles": 0},
    "code_review": {"status": "pending", "critical": 0, "high": 0, "medium": 0, "low": 0, "fix_cycles": 0},
    "security": {"status": "pending", "critical": 0, "high": 0, "medium": 0, "low": 0, "fix_cycles": 0}
  },
  "decisions": [],
  "fix_attempts": [],
  "blocked": []
}
```

6. Present the phase list to the user and ask for confirmation before starting:

```
Plan: [plan filename]
Phases:
  1. [Phase 1 name]
  2. [Phase 2 name]
  ...

Start implementation? (yes / no / adjust)
```

Wait for user confirmation before proceeding.

---

### Step 2: Launch the Orchestrator

Build and execute the orchestrator command via Bash:

```bash
unset CLAUDECODE && claude --agent implement-orchestrator --print --output-format text "Execute the implementation plan.

PLAN_PATH: <absolute path to plan file>
CHECKPOINT_PATH: <absolute path to checkpoint JSON>

Read the plan and checkpoint, then implement all pending phases following your Implementation Loop. For each phase: dispatch implementer, run build, run reviews, fix issues, update checkpoint. After all phases, run quality gates. Return your termination status (DONE/HANDOFF/BLOCKED)." 2>&1 | tee /tmp/implement-orchestrator-output.txt
```

**Important launch parameters:**
- `unset CLAUDECODE` — required to bypass nested-session protection
- `--print` — non-interactive headless mode
- `--output-format text` — plain text output (parseable)
- `| tee /tmp/implement-orchestrator-output.txt` — capture output to file AND display
- `timeout: 600000` — 10 minute timeout per Bash call. For multi-phase runs, use `run_in_background: true` instead (no timeout limit) and poll checkpoint for progress
- `run_in_background: true` — run as background task so we can monitor

After launching, immediately tell the user:
```
Orchestrator launched. Monitoring progress via checkpoint file.
I'll check in periodically and report status.
```

---

### Step 3: Monitor Progress

While the orchestrator is running (background task):

1. **Poll the checkpoint file** every time you want to check status — read `.claude/state/implement-checkpoint.json`
2. Report to the user which phases are done, which is in-progress
3. If the user asks for status, read the checkpoint and summarize

When the background task completes, read the output:
- Read `/tmp/implement-orchestrator-output.txt` for the full orchestrator output
- Parse the first line for the termination status

---

### Step 4: Handle the Orchestrator Result

Inspect the output for one of three termination states:

| Status | Action |
|--------|--------|
| `STATUS: DONE` | Go to Step 5 (final summary). |
| `STATUS: HANDOFF` | Log the handoff. Re-launch the orchestrator (Step 2 again) with the same plan/checkpoint paths. The checkpoint preserves progress. |
| `STATUS: BLOCKED` | Present the blocked issue to the user. Ask: "Fix it manually and continue, skip this phase, or adjust the plan?" Wait for response, then either re-launch or stop. |

**Handoff loop**: keep re-launching (Step 2) until status is DONE or the user chooses to stop.

---

### Step 5: Final Summary

Print this summary when STATUS: DONE is received:

```
## Implementation Complete

**Plan**: [plan filename]
**Orchestrator cycles**: N (M handoffs)

### Phases
1. [Phase name] — DONE
   - Completeness: PASS (C:0, H:0, M:0, L:0) | Tests verified
   - Code Review:  PASS (C:0, H:0, M:0, L:0)
   - Security:     PASS (C:0, H:0, M:0, L:0)
   - Fix cycles: N
2. [Phase name] — DONE
   ...

### Files Modified
- [file list from checkpoint]

### Integration Gates
- Build:              PASS
- Analyze + Test:     PASS
- Integration Reviews:
  - Completeness: PASS (C:0, H:0, M:0, L:0)
  - Code Review:  PASS (C:0, H:0, M:0, L:0)
  - Security:     PASS (C:0, H:0, M:0, L:0)

### Decisions Made
- [list]

Ready to review and commit.
```

Read the final checkpoint to populate this summary. The supervisor does NOT commit or push.

---

## Troubleshooting

### Orchestrator uses Edit/Write directly instead of dispatching
The orchestrator's system prompt behaviorally restricts it to Read/Glob/Grep/Task. If it violates this, the agent file at `.claude/agents/implement-orchestrator.md` needs prompt strengthening.

### Orchestrator can't find agents
Custom agents must exist in `.claude/agents/`. Verify the files exist with Glob.

### Output file empty
Check that `unset CLAUDECODE` is included in the Bash command. Without it, the nested session check blocks the launch.

### Timeout
A single phase can take 30-60 minutes (implement + build + reviews + fix cycles). **Always use `run_in_background: true`** for the Bash call — background tasks have no timeout. Monitor progress by polling the checkpoint file. For very large plans, instruct the orchestrator: "Execute only Phase N, then return HANDOFF."
