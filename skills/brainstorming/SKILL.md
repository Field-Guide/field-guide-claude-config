---
name: brainstorming
description: "Captures user intent before any feature work, bug fix, UX change, or refactor. Runs a structured Intent/Scope/Vision gating flow with adversarial self-checks, classifies the work type (new feature, feature modification, bug fix, UX polish, or refactor), and outputs an approved spec file for tailor and writing-plans to consume. Use before writing code, modifying behavior, fixing bugs, or restructuring. Required for every change — no size exceptions."
user-invocable: true
disable-model-invocation: true
---

# Brainstorming

Turn an idea into an approved spec at `.claude/specs/YYYY-MM-DD-<slug>-spec.md`.
This skill captures intent first, not technical design. Tailor and writing-plans
handle codebase mapping and implementation structure later.

<HARD-GATE>
Do not write code, invoke implementation skills, or take implementation actions
until the spec is written, self-reviewed, and explicitly approved by the user.
This flow applies to every change. There is no size exception.
</HARD-GATE>

## Reference Files

Load only the file needed for the current step.

- `references/intent-capture-gates.md` — gate mechanics, adversarial checks, reply verbs, snap-back rules
- `references/work-types.md` — work-type classification, checklist additions, type-specific Phase 0 picks, options framing
- `references/spec-output.md` — spec template, self-review checks, user-review gate
- `references/visual-companion.md` — browser companion rules on port `5947`

## Workflow Checklist

At session start, create a TaskCreate list and track these steps:

1. Phase 0 baseline exploration
2. Work-type classification
3. Type-aware deep exploration
4. Visual companion consent, if warranted
5. Intent gate
6. Scope gate
7. Vision gate
8. Options phase
9. Draft spec
10. Self-review
11. User review
12. Terminal state

If a snap-back reopens an earlier gate, move that step back to `in_progress`
before continuing.

## Phase 0

Do this silently before asking questions.

- Use CodeMunch, not broad file browsing.
- Budget 6 to 10 calls.
- Do not read full source files. Use repo outline, symbol search, file outline,
  call hierarchy, related symbols, and coupling data only.
- Always resolve the repo, refresh the index if stale, get the repo outline,
  read `.claude/CLAUDE.md`, and inspect the recent git log.
- After baseline exploration, classify the work type and then run the
  type-specific Phase 0 picks from `references/work-types.md`.

Valid types:
`new feature`, `feature add/mod`, `bug fix`, `ux polish`, `refactor+`,
`security hardening`, `data/schema migration`, `documentation`

## Message Rules

These rules are mandatory. The current session should never feel like a wall of
text questionnaire.

1. Ask exactly one substantive question per message.
2. Prefer multiple choice. Use short A/B/C/D options whenever that is honest.
3. Always include an escape hatch such as `other` or free-text clarification.
4. Ground questions in Phase 0 findings. No fishing questions.
5. Do not paste grouped section questionnaires or long bullet dumps.
6. Keep gate messages short: confirmed bullets, still-unclear bullets, reply verbs.
7. If the user already answered something, do not ask it again unless a snap-back is required.

## Classification Mini-Gate

After baseline Phase 0, propose the work type with a brief rationale and wait
for one of these verbs:

- `confirmed`
- `actually: <type>`
- `unclear: <reason>`

Only after classification is locked should the skill run the type-specific deep
exploration from `references/work-types.md`.

## Visual Companion

Offer the browser companion only when seeing something would beat describing it.
The consent message must stand alone and contain nothing else.

If the user says `yes`, follow `references/visual-companion.md`. If the user says
`no`, do not ask again during that session.

## Gate Pattern

Intent, Scope, and Vision all use the same loop. Detailed checklists live in
`references/intent-capture-gates.md` and `references/work-types.md`.

1. Ask one grounded question at a time until the checklist for that gate is satisfied.
2. When the checklist is clear, fire the gate with this structure:

```markdown
## <Gate> Gate

**Confirmed:**
- ...

**Still unclear:**
- ...

**Reply:** `confirmed` / `fix: <what>` / `reopen: <bullet>`
```

3. If the user confirms, run the adversarial pass for that gate and present it as:

```markdown
## Adversarial Check — <Gate>

1. ...
2. ...

**Reply:** `no concerns` / `fix: <what>` / `reopen: <bullet>`
```

4. Only after the adversarial pass is clean does the skill advance to the next gate.

There is no minimum or maximum question count. Gates fire only when the
checklist is clear.

## Snap-Back Rule

If a later answer changes an earlier locked gate, announce the snap-back in its
own message before doing anything else. Restate what changed, reopen the earlier
gate, rerun its adversarial pass, and only then resume forward progression.
Snap-backs are never silent.

## Options Phase

After Intent, Scope, and Vision are locked, present 2 to 3 options tailored to
the work type. Lead with a recommendation. Each option should have:

- a short name
- one-line rationale
- pros
- cons

Option families come from `references/work-types.md`.

## Draft And Review

1. Write the spec file using `references/spec-output.md`.
2. Copy locked gate content verbatim into the Intent, Scope, and Vision sections.
3. Run the 7 self-review checks from `references/spec-output.md`.
4. Present self-review findings as a numbered changelist with these verbs:
   `approve: 1,3`, `reject: 2`, `skip: 5`, `edit 2: <text>`, `add: <new finding>`
5. Apply approved edits and save the file.
6. Present the saved path for fresh-eye review, even if self-review was clean.
7. User review verbs are:
   `approved`, `fix: <what>`, `reopen: <gate>`

If the user reopens a gate, return to that gate, rerun its adversarial pass,
then re-draft and re-review the affected sections.

## Terminal State

On `approved`, end with exactly:

> Spec approved and saved at `.claude/specs/YYYY-MM-DD-<slug>-spec.md`. Next step: run `/tailor` to map the codebase against this spec before `/writing-plans`.

No auto-invoke. No extra confirmation round trip.

## Iron Laws

1. One question per message.
2. Multiple choice preferred.
3. No fishing questions.
4. Gates fire from checklist completeness, not question count.
5. Snap-backs are always announced.
6. The skill writes the spec but never commits it.
7. Every change runs this flow.
