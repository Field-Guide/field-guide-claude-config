---
name: brainstorming
description: "Captures user intent before any feature work, bug fix, UX change, or refactor. Runs a structured Intent/Scope/Vision gating flow with adversarial self-checks, classifies the work type (new feature, feature modification, bug fix, UX polish, or refactor), and outputs an approved spec file for tailor and writing-plans to consume. Use before writing code, modifying behavior, fixing bugs, or restructuring. Required for every change — no size exceptions."
user-invocable: true
disable-model-invocation: true
---

# Brainstorming Ideas Into Specs

Turn an idea into an approved spec by running a structured Intent → Scope → Vision gating flow with adversarial self-checks, per-work-type tailoring, and a codebase-grounded Phase 0. The output is a file at `.claude/specs/YYYY-MM-DD-<slug>-spec.md` that `/tailor` and `/writing-plans` will consume.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until the spec file has been written, self-reviewed, and approved by the user via the `approved` verb. This applies to EVERY change regardless of perceived simplicity. There is no size exception.
</HARD-GATE>

## Reference Files (progressive disclosure)

- `references/intent-capture-gates.md` — baseline checklists, gate presentation format, reply verbs, the four-hunt adversarial check, and the snap-back rule
- `references/work-types.md` — classification signals, per-type checklist stacks, CodeMunch Phase 0 picks, and options-phase framings (5 primary + 3 secondary types)
- `references/spec-output.md` — shared spine + per-type tail templates, the 7-check self-review, changelist presentation, user review gate
- `references/visual-companion.md` — browser-based mockup companion (fixed port `5947`, state under `.claude/brainstorm/<session>/`)

Read a reference file when you reach the phase it covers. Do not pre-load all of them.

## Workflow Checklist

At the start of every session, create a TaskCreate list with the following items so the user can see progress at a glance. Flip each one from `pending → in_progress → completed` as you advance.

1. Phase 0 — Resolve CodeMunch index + baseline exploration
2. Classify work type (mini-gate)
3. Type-aware Phase 0 deep exploration
4. Offer Visual Companion (if the work type suggests visual questions) — own message, session-scoped consent
5. Intent gate — checklist → gate → adversarial
6. Scope gate — checklist → gate → adversarial
7. Vision gate — checklist → gate → adversarial
8. Options phase — 2-3 type-specific options, user picks one
9. Draft spec file (spine + per-type tail)
10. Self-review — 7 checks → changelist → apply approved fixes
11. User review gate — fresh-eye file review
12. Terminal state — one-line pointer to `/tailor`

Never start a later step before the earlier step is marked completed. If a snap-back fires, flip earlier steps back to `in_progress` before reopening them.

## Phase 0 — Codebase Grounding (silent)

Run this before asking any questions. Use CodeMunch, not glob/grep. Budget: 6-10 calls, no full file reads (outlines only).

**Always:**
1. `mcp__jcodemunch__resolve_repo` to confirm the active repo handle
2. `mcp__jcodemunch__index_folder` on `lib/` if the index is stale (AI summaries ON; see global feedback)
3. `mcp__jcodemunch__get_repo_outline` for the baseline architectural snapshot
4. Read `.claude/CLAUDE.md` for constraints and recent git log (last ~20 commits on the current branch) to detect in-flight work

**Then classify** (see below), and layer type-specific CodeMunch calls from `work-types.md`.

**Do not read full source files.** Outlines, symbol searches, and call hierarchies only. Deep reading belongs to `/tailor`.

## Classification Mini-Gate

Propose a work-type classification immediately after baseline Phase 0, drawn from the user's opening message + outline + git log. Present with reasoning, take `confirmed` / `actually: <type>` / `unclear: <reason>` verbs. Full format and signals are in `references/work-types.md`.

Valid types: `new feature`, `feature add/mod`, `bug fix`, `ux polish`, `refactor+`, `security hardening`, `data/schema migration`, `documentation`.

Once classified, run the type-specific Phase 0 deep exploration from `work-types.md` before starting Intent questioning.

## Visual Companion — Consent (own message, session-scoped)

If the classification and opening message suggest visual questions ahead (UX Polish is the primary earn-your-keep case, but any type may qualify), send a standalone consent message **containing nothing but the offer**:

> "Some of what we're working on might be easier to see than to read. I can open a browser companion and push mockups, diagrams, or visual comparisons as we go. It's token-intensive, and runs locally on `http://localhost:5947`. Want to enable it for this session? (reply `yes` / `no`)"

**Rules:**
- Never combine the offer with a clarifying question or status update
- Ask once per session; on `no`, never re-ask
- On `yes`, follow `references/visual-companion.md` for launch + loop mechanics
- Even with consent, decide **per question** whether the browser beats the terminal — most Intent/Scope/Vision questions stay in the terminal; visual use peaks in the Options phase for UX Polish

## The Three Gates — Intent → Scope → Vision

Run each gate through the same pattern. Full machinery in `references/intent-capture-gates.md`; full per-type checklist additions in `references/work-types.md`.

### Pattern

1. **Questioning** — one question per message, multiple choice preferred, grounded in Phase 0 findings. Baseline checklist items + type-specific items drive *which* question to ask next. No fishing questions; no pre-announcing the checklist.
2. **Gate firing** — when the internal checklist has zero unsatisfied items, send the gate restate message with `## <Gate name> Gate`, `**Confirmed:**` bullets, `**Still unclear:**` bullets (empty if clean), and `**Reply:**` verbs.
3. **Gate reply verbs** — `confirmed` / `fix: <what>` / `reopen: <bullet>`. Any other reply is interpreted as free-text clarification.
4. **Adversarial self-check** — after the gate passes, run all four hunts (misinterpretation, contradiction, unknown-unknowns, scope creep) and surface concerns as a numbered `## Adversarial Check — <Gate>` message.
5. **Advance** — only after adversarial returns `no concerns` (or the user addresses each concern) does the skill move to the next gate.

### No Floor, No Ceiling

There is no minimum or maximum question count per gate. The only gate trigger is an empty internal checklist.

### Snap-Back

If at any later point — mid-gate, mid-adversarial, or mid-options — an answer contradicts an earlier locked gate, **announce a snap-back in its own message** before doing anything else:

> "Snap-back: re-confirming <earlier gate>. While working on <current gate>, your answer just changed my understanding of <earlier gate>. Specifically: <what shifted>. I'm snapping back to re-confirm before we continue."

Then re-present the earlier gate's restate with the updated bullet(s), re-run its adversarial check, and only resume forward progression after the user re-confirms. Snap-backs are **never silent**.

## Options Phase (after all three gates pass)

After Vision is locked, present **2-3 options tailored to the work type**. Full per-type framings in `references/work-types.md`:

- **New Feature** → scope options (Minimal v1 / Full v1 / Phased)
- **Feature Add/Mod** → change-depth (Surgical / Variant / Replace-and-deprecate)
- **Bug Fix** → fix-shape (Symptom / Root-cause / Restructure)
- **UX Polish** → visual directions (push cards to the browser if the companion is active)
- **Refactor+** → refactor-ambition (Minimum / Single class / Whole subsystem)
- **Security Hardening** → defense depth (Tight patch / Layered / Policy change)
- **Data/Schema Migration** → migration shape (Additive / Additive+backfill / Destructive+rollback)
- **Documentation** → doc shape (Tight edit / Restructure / New doc)

Present each option with a one-line name, a short rationale, pros, cons, and whether it's the recommended option (lead with your recommendation). User picks one with a verb; any other reply is treated as free-text to adjust the options.

## Draft + Self-Review + User Review

Once the option is picked, write the spec file.

1. **Draft** the file at `.claude/specs/YYYY-MM-DD-<slug>-spec.md` using the shared spine + per-type tail from `references/spec-output.md`. Pull Intent/Scope/Vision content **verbatim** from the locked gate restates — do not re-paraphrase.
2. **Self-review** — run the 7 checks internally: placeholder scan, internal consistency, scope cohesion, ambiguity, CLAUDE.md constraints, traceability/anti-invention, success-criteria measurability.
3. **Present findings as a changelist** — numbered, with reasoning per item, and per-finding verbs (`approve: 1,3` / `reject: 2` / `skip: 5` / `edit 2: <text>` / `add: <new finding>`). If all 7 checks pass, say so and move on.
4. **Apply approved fixes** to the file, then **save** (no commit — the user handles git).
5. **User review gate** — present the saved path and ask for a fresh-eye read, **even if self-review was clean**. Reply verbs: `approved` / `fix: <what>` / `reopen: <gate>`. There is **no `decompose` verb**.

If the user replies `reopen: <gate>`, snap back to that gate's questioning phase, rerun its adversarial check, then re-draft and re-self-review the affected sections.

## Terminal State

When the user replies `approved`:

> "Spec approved and saved at `.claude/specs/YYYY-MM-DD-<slug>-spec.md`. Next step: run `/tailor` to map the codebase against this spec before `/writing-plans`."

That is the entire terminal message. **No auto-invoke**, no "shall I proceed?", no confirmation round-trip. The skill ends cleanly and the user drives the pipeline from here.

## Iron Laws

1. **One question per message.** Multiple choice preferred.
2. **No fishing questions.** Phase 0 is silent — never ask permission to look something up.
3. **Gates fire on empty checklists, not question counts.**
4. **Snap-backs are announced in their own messages.** Never silently fold a contradiction.
5. **The skill writes the file but never commits it.** The user handles git.
6. **Terminal state is clean.** One line pointing to `/tailor`. No hand-off round-trip.
7. **No size exceptions.** Every change — XS through XL — runs this flow.

## Required Tool Use

- `TaskCreate` for the workflow checklist at session start
- `mcp__jcodemunch__*` for Phase 0 exploration (resolve_repo, index_folder, get_repo_outline, search_symbols, get_file_outline, get_call_hierarchy, get_coupling_metrics, get_related_symbols, get_symbol_complexity, get_extraction_candidates — pick per work type)
- `Read` on `.claude/CLAUDE.md` and recent git log (via `Bash: git log --oneline -20 HEAD`)
- `Write` for the final spec file
- `Edit` for applying self-review fixes and snap-back edits
- `Bash` + `run_in_background: true` for `scripts/start-server.sh` when the visual companion is enabled
