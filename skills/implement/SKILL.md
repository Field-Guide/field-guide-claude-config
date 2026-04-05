---
name: implement
description: "Execute implementation plans via headless Claude instances with real-time checkpoint visibility and batch-level quality gates."
user-invocable: true
---

# /implement Skill

Execute implementation plans using headless `claude -p` instances. The main conversation IS the orchestrator — it dispatches, monitors, merges state, and reports progress between every batch. The user sees what's happening and can intervene at any point.

## Architecture

```
Main conversation (supervisor + orchestrator)
  |
  +- Reads plan, dependency analysis, groups into batches (max 4 phases/batch)
  +- Initializes/resumes checkpoint
  |
  +- FOR EACH BATCH:
  |     +- Writes prompt files per phase
  |     +- Launches N headless implementers (claude -p, parallel via Bash background)
  |     |     +- Tools: Read, Edit, Write, Glob, Grep (NO Bash)
  |     |     +- Each writes .claude/outputs/phase-N-state.json
  |     +- Waits for all, reads state files, merges into checkpoint, reports
  |     |
  |     +- Runs batch-level lint: flutter analyze + dart run custom_lint
  |     |     +- If violations -> launches headless lint-fixer -> re-lints (max 3 cycles)
  |     |
  |     +- Launches 3xN headless reviewers (all parallel)
  |     |     +- Completeness (opus) + Code Review (opus) + Security (opus)
  |     |     +- Each writes .claude/outputs/phase-N-{type}-findings.json
  |     +- If findings -> launches headless fixer per phase -> re-reviews ALL 3 (max 3 cycles)
  |     |
  |     +- Updates checkpoint, reports batch complete
  |
  +- Final summary
```

## IRON LAW

The main conversation NEVER edits source files directly. It only writes:
- Checkpoint JSON (`.claude/state/implement-checkpoint.json`)
- Prompt files (`.claude/outputs/phase-N-*.md`)
- Output directory files (`.claude/outputs/`)

Allowed tools: Read, Write (checkpoint/prompts only), Bash (headless launches + lint only).

NEVER run `flutter clean`. It is prohibited.

---

## Step 1: Accept & Parse Plan

1. User invokes `/implement <plan-path> [phase-numbers]`
2. If bare filename -> search `.claude/plans/` for the file
3. Read plan, extract phase list (names + file lists)
4. Extract spec path from plan header (`**Spec:**` line)
5. Set checkpoint path: `.claude/state/implement-checkpoint.json`
6. Check for existing checkpoint:
   - File does not exist -> start fresh
   - File exists and `"plan"` matches -> ask: "Resume from checkpoint (phases done: X) or start fresh?"
   - File exists but different plan -> delete and start fresh
7. Present phases to user for confirmation:

```
Plan: [plan filename]
Spec: [spec filename]
Phases:
  Phase 1 — [name]
  Phase 2 — [name]
  ...

Start implementation? (yes / no / adjust)
```

Wait for user confirmation before proceeding.

---

## Step 2: Dependency Analysis & Batching

1. For each phase, extract file lists from plan text (files to create/modify)
2. **Shared file rule**: If two phases touch ANY of these, they go to different batches:
   - `app_providers.dart`
   - `database_service.dart`
   - `app_router.dart`
   - Barrel/index files (any file that only re-exports)
   - `pubspec.yaml`
3. Group into parallel batches:
   - No file overlap within a batch
   - Max 4 phases per batch
4. If a phase's file list cannot be determined -> treat as overlapping with all (sequential fallback)
5. Report batch plan to user:

```
Batch Plan:
  Batch 1: Phases 1, 3 (parallel — no file overlap)
  Batch 2: Phase 2 (sequential — shares app_providers.dart with Phase 1)
  Batch 3: Phases 4, 5, 6 (parallel — no file overlap)
```

---

## Step 3: Initialize Checkpoint

If starting fresh, write the checkpoint JSON to `.claude/state/implement-checkpoint.json` following the structure in `reference/checkpoint-template.json`.

Key fields:
- `plan`: absolute path to plan file
- `spec`: absolute path to spec file
- `batches`: array of batch definitions with phase assignments
- `phases`: object keyed by phase number with status, implementation details, and review results
- `modified_files`: cumulative list across all phases
- `decisions`: cumulative decisions list
- `blocked`: array of blocked items

---

## Step 4: Batch Execution Loop

Process each batch sequentially. Within each batch, phases run in parallel.

### Step 4a: Prepare Prompt Files

For each phase in the batch:
1. Read the full phase text from the plan
2. Write the implementer system prompt to `.claude/outputs/phase-N-prompt.md`
3. Use the implementer template from `reference/prompt-templates.md`
4. Fill in placeholders: `{{PHASE_NUMBER}}`, `{{PLAN_PATH}}`, `{{SPEC_PATH}}`, `{{PHASE_TEXT}}`, `{{STATE_FILE_PATH}}`
5. **All paths MUST be absolute** (Windows path resolution issues with relative paths)

### Step 4b: Launch Implementers

Build headless commands per `reference/headless-commands.md` implementer pattern.

- **Batch size 1**: Run in foreground (`Bash` tool, `timeout: 600000`)
- **Batch size 2-4**: Run each with `Bash` tool, `run_in_background: true`
- Wait for all to complete (background tasks notify on completion)

### Step 4c: Verify & Merge State

1. Read each `.claude/outputs/phase-N-state.json`
2. Validate: file exists, valid JSON, required fields present, status is `done`/`failed`/`blocked`
3. If state file missing or malformed -> mark phase as failed
4. Merge into master checkpoint:
   - Set phase status
   - Append `files_created` and `files_modified` to checkpoint's `modified_files` (dedup)
   - Record decisions
5. Report to user:
   ```
   Batch N implementation complete.
     Phase X: 4 files created, 2 modified
     Phase Y: 3 files created, 1 modified
   ```
6. If any phase failed -> ask user: retry / skip / stop

### Step 4d: Batch-Level Lint

1. Run `pwsh -Command "flutter analyze"` (foreground, `timeout: 300000`)
2. If violations -> also run `pwsh -Command "dart run custom_lint"` to check both
3. If any violations from either:
   a. Write lint-fixer prompt to `.claude/outputs/batch-N-lint-fixer-prompt.md` containing:
      - All violation text from both commands
      - List of all files from the batch
      - Instruction: "Fix lint violations only. Do not change behavior."
   b. Launch ONE headless lint-fixer per `reference/headless-commands.md` lint-fixer pattern
   c. After fixer returns, re-run both lint commands
   d. Max 3 cycles -> BLOCKED if still failing
4. If both clean -> proceed to reviews

### Step 4e: Launch Reviews (all parallel)

For each phase in the batch, write 3 reviewer prompt files using templates from `reference/prompt-templates.md`:
- `.claude/outputs/phase-N-review-completeness-prompt.md`
- `.claude/outputs/phase-N-review-code-prompt.md`
- `.claude/outputs/phase-N-review-security-prompt.md`

Include in each:
- The spec path and plan path
- The list of files to review (from phase state's `files_created` + `files_modified`)
- The severity standard from `reference/severity-standard.md`
- The findings output path: `.claude/outputs/phase-N-{type}-findings.json`

Launch 3xN headless reviewer commands (all `run_in_background: true`) per `reference/headless-commands.md` reviewer pattern.

Wait for all to complete.

### Step 4f: Consolidate & Fix Loop (max 3 cycles)

1. Read all findings files: `.claude/outputs/phase-N-{type}-findings.json`
2. Parse JSON, check `verdict` field
3. If ALL verdicts are `"approve"` -> mark reviews passed, continue to Step 4g
4. If ANY findings:
   a. For each phase with findings: write fixer prompt to `.claude/outputs/phase-N-fixer-prompt.md` with consolidated findings from all 3 reviewers for that phase
   b. Launch headless fixer per phase (parallel across phases, since no file overlap in batch) per `reference/headless-commands.md` review-fixer pattern
   c. After fixers complete, re-run batch-level lint (Step 4d logic, single pass)
   d. Re-launch ALL 3 reviewers for ALL phases that had findings (all reviews re-run to catch cross-type regressions)
   e. Check findings again
   f. Max 3 cycles total -> BLOCKED if still failing, show remaining findings to user

### Step 4g: Update Checkpoint

1. Mark all batch phases as `"done"`
2. Record per-phase review results (finding counts, fix cycles)
3. Update batch status and lint_gate
4. Write updated checkpoint to disk
5. Report batch complete to user:

```
Batch N complete.
  Phase X — DONE
    Completeness: PASS | Code Review: PASS | Security: PASS
    Fix cycles: 0
    Files: [list]
  Phase Y — DONE
    Completeness: PASS | Code Review: PASS | Security: PASS
    Fix cycles: 1
    Files: [list]
  Lint gate: PASS

Proceeding to Batch N+1...
```

---

## Step 5: Final Summary

After ALL batches complete, print:

```
## Implementation Complete

**Plan**: [plan filename]
**Batches**: N

### Phases
Phase 1 — DONE
  Completeness: PASS | Code Review: PASS | Security: PASS | Fix cycles: N
  Files: [list]
Phase 2 — DONE
  ...

### Files Modified
[deduped list from checkpoint]

### Decisions Made
[from checkpoint]

Ready to review and commit.
```

Read the final checkpoint to populate this summary. The main conversation does NOT commit or push.

---

## Step 6: Error Handling

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Implementer crash | No state file or malformed JSON | Mark phase failed, ask user |
| Implementer timeout | Bash tool timeout / background never completes | Use `--max-turns 80` as guardrail |
| Lint fix loops | 3 cycles of lint-fix without clean | BLOCKED, show violations to user |
| Review fix loops | 3 cycles of review-fix without clean reviews | BLOCKED, show remaining findings to user |
| Reviewer crash | No findings file or malformed JSON | Re-run that reviewer only |
| Mid-batch partial failure | Some phases done, some failed | Review succeeded phases, ask about failed ones |

---

## Step 7: Troubleshooting

- **`unset CLAUDECODE` not working**: Try `CLAUDECODE= claude -p ...` instead
- **Empty output from headless**: Check `tee` path is absolute
- **Permission denied**: Verify `--permission-mode dontAsk` + `--allowedTools` covers needed tools
- **Rate limits**: Headless retries automatically (up to 10 times). If persistent, reduce parallel count.
- **State file not written**: Implementer may have hit max-turns. Check output JSON for truncation.
