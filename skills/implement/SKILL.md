---
name: implement
description: "Executes approved implementation plans with Agent-tool dispatch, per-phase completeness review, and a final multi-reviewer quality gate."
user-invocable: true
disable-model-invocation: true
---

# Implement

Execute an approved plan as a thin orchestrator. The main conversation reads
only plan metadata, dispatches all real work through the Agent tool, and
reports progress back to the user.

## Iron Laws

1. The orchestrator never edits source files.
2. The orchestrator never reads a phase body into its own context.
3. The orchestrator never writes a checkpoint or resume file.
4. The orchestrator never launches headless `claude`, JSON-schema harnesses, or parsing pipelines.
5. The orchestrator never runs analyze, tests, build commands, `flutter clean`, or git commands.
6. Every dispatched implementer, reviewer, and fixer uses `model: opus`.
7. Every dispatched agent begins by reading the correct rules file:
   `references/worker-rules.md` for implementers and fixers,
   `references/reviewer-rules.md` for reviewers.

## Allowed Tools

The main conversation may use only:

- `Read` for the plan header region
- `Grep` to find `## Phase N` headings if the header lacks line ranges
- `Agent` for all implementation, review, and fix work
- `Bash` only for `mkdir -p .claude/backlogged_reviews`
- `Write` only for `.claude/backlogged_reviews/<plan-name>.md`

## Plan Intake

1. Accept `/implement <plan-path> [phase-numbers]`.
2. If the user passes a bare filename, resolve it under `.claude/plans/`.
3. Read only the plan header region.
4. Extract:
   - the spec path from `**Spec:**`
   - the phase list
   - per-phase line ranges from the machine-readable header block
5. If the header does not declare ranges, use `Grep` on `## Phase N` headings and
   infer ranges from those heading lines.
6. Present the phase list and ask:

```text
Start implementation? (yes / no / adjust)
```

Do not continue until the user confirms.

## Per-Phase Loop

Run phases strictly in sequence. A phase is not closed until completeness review
returns zero findings of any severity.

### Step 1: Dispatch Implementer

Dispatch a `general-purpose` agent on `model: opus` with an inline prompt that
includes:

- the plan path
- the exact phase line range
- the spec path
- the phase name
- instruction to read `references/worker-rules.md` first
- this reply contract:

```text
STATUS: done | failed | blocked
FILES_CREATED:
- ...
FILES_MODIFIED:
- ...
LINT:
- flutter analyze: clean | failed
- dart run custom_lint: clean | failed
NOTES:
- ...
```

The implementer owns source edits, `flutter analyze`, and `dart run custom_lint`.
The orchestrator only records the reply.

### Step 2: Dispatch Completeness Reviewer

Dispatch `completeness-review-agent` on `model: opus` with:

- `mode: per-phase`
- `spec_path`
- `plan_path`
- `plan_line_range`
- `files_in_scope`
- instruction to read `references/reviewer-rules.md` first

If the reviewer returns zero findings, the phase passes.

### Step 3: Fix Findings

If the completeness reviewer returns any finding at any severity, dispatch a
narrow `general-purpose` fixer on `model: opus` with:

- instruction to read `references/worker-rules.md` first
- the inline findings list only

Do not send the fixer the spec path, plan path, or plan line range. The findings
must already carry the file and fix guidance needed to act.

### Step 4: Cap And Escalation

The per-phase review/fix loop has a hard cap of 3 cycles.

- Cycle 1: review, then fix if needed
- Cycle 2: review, then fix if needed
- Cycle 3: terminal reviewer pass

If cycle 3 still returns findings, escalate in the main conversation with the
remaining findings and ask:

```text
continue / stop / manual fix
```

### Step 5: Per-Phase Status

After a phase closes, print a terse status block with:

- phase name
- review cycle count
- files created count
- files modified count
- lint status

Then move to the next phase.

## Final Gate

After every requested phase passes, run one final quality sweep.

### Final Review Fan-Out

Dispatch these three reviewers in parallel in a single orchestrator message,
all on `model: opus`:

1. `completeness-review-agent` with `mode: final-sweep`
2. `code-review-agent`
3. `security-agent`

The completeness reviewer receives the union of all modified files. The other
reviewers receive the final file set for the whole run.

### Finding Split

Split final findings into two buckets:

- fixer-bound:
  - every completeness finding, regardless of severity
  - CRITICAL, HIGH, and MEDIUM code-review findings
  - CRITICAL, HIGH, and MEDIUM security findings
- backlog-bound:
  - LOW code-review findings
  - LOW security findings

Completeness findings are never backlogged.

### Final Fix Loop

If the fixer-bound bucket is non-empty, dispatch a narrow fixer with
`references/worker-rules.md` plus the inline findings list, then rerun the full
three-reviewer sweep.

The final gate also has a hard cap of 3 cycles. If cycle 3 still returns
fixer-bound findings, escalate with:

```text
stop / manual fix / accept-as-is and backlog
```

## Backlogged Reviews File

At the end of the final gate:

1. Run `mkdir -p .claude/backlogged_reviews`
2. Write `.claude/backlogged_reviews/<plan-name>.md`

That file contains:

- LOW code-review findings
- LOW security findings
- any blockers the user explicitly accepted as-is

It must not contain completeness findings.

## Final Summary

End with a concise summary that includes:

- the plan path
- per-phase cycle counts
- final-gate reviewer statuses
- final-gate fix cycle count
- the backlog file path
- the deduped union of every created or modified file

## Reference Files

- `references/worker-rules.md` — implementer and fixer rules
- `references/reviewer-rules.md` — reviewer rules
- `references/severity-standard.md` — severity and verdict policy
