# Brainstorming Skill Rewrite Spec

**Work Type:** Feature Modification (significant rewrite of existing dev-tooling skill)
**Date:** 2026-04-09
**Spec Author:** Paired conversation (Claude Opus 4.6 + user)
**Supersedes:** `.claude/skills/brainstorming/skill.md` (current)

---

## Intent

**Problem:** The current brainstorming skill captures user intent inconsistently. It uses a vague 11-section technical template, has no adversarial self-check, no per-work-type tailoring, no explicit gates for Intent/Scope/Vision, no visible snap-back on contradictions, and no codebase grounding before asking questions. The result is specs that either miss critical intent (leading to misaligned implementation plans) or bloat with premature technical decisions that belong in tailor/writing-plans. The user has also explicitly flagged intent capture as "the single most important skill" — making the current drift unacceptable.

**Who feels it:**
- Primarily: the user, each time they invoke `/brainstorming` and end up either over-answering technical questions that don't belong in a brainstorm, or under-answering the genuine intent questions that matter.
- Secondarily: downstream skills (`/tailor`, `/writing-plans`, `/implement`) that inherit wrong assumptions from a spec that captured the wrong things.

**Success criteria (measurable):**
1. Every brainstorm produces a spec file at `.claude/specs/YYYY-MM-DD-<slug>-spec.md` with populated Intent / Scope / Vision sections and a type-specific tail.
2. No spec leaves the skill without passing self-review on 7 checks (placeholder, consistency, scope cohesion, ambiguity, CLAUDE.md constraints, traceability, measurability).
3. No gate passes without explicit user confirmation via structured reply verbs.
4. No mid-stream contradiction is silently swallowed — snap-back is announced in every case.
5. SKILL.md stays under 500 lines per Anthropic best practices.
6. Zero references to deleted agents/skills/docs after rewrite.
7. Every locked decision in this spec is traceable to a specific piece of the rewritten skill.

**Why now:** The user just trimmed the `.claude/` directory and is rebuilding how they work with Claude. The brainstorming skill is the gateway to every other skill in the pipeline (tailor → writing-plans → implement), so getting it right first unblocks the rest of the re-architecture. Additionally, the `obra/superpowers` plugin's brainstorming skill is the structural model the user wants to mirror — adopting its patterns while retaining Field-Guide-specific retention is the stated goal.

---

## Scope

### In scope (v1)

- Full rewrite of `.claude/skills/brainstorming/skill.md` → `SKILL.md` (renamed to match Anthropic convention).
- New reference files under `.claude/skills/brainstorming/references/`:
  - `intent-capture-gates.md` — gate machinery (B/C/D from Q2, adversarial, snap-back)
  - `work-types.md` — 5 primary + 3 secondary types with Intent/Scope/Vision stacks and options content
  - `spec-output.md` — per-type spec templates, self-review checklist, user-review gate
  - `visual-companion.md` — port from `obra/superpowers` with `.claude/brainstorm/` path adaptation
- New scripts directory `.claude/skills/brainstorming/scripts/` ported verbatim from superpowers, adapted for fixed port `5947`:
  - `server.cjs`
  - `start-server.sh`
  - `stop-server.sh`
  - `frame-template.html`
  - `helper.js`
- Delete legacy `.claude/skills/brainstorming/references/question-patterns.md` and `design-sections.md` if present (absorbed or obsolete).
- Edit `.claude/CLAUDE.md` to remove the XS/S sizing-guide escape hatch — every change runs the full pipeline.
- Edit `.gitignore` to exclude `.claude/brainstorm/` (visual companion runtime state).

### Deferred (not v1, not out of scope forever)

- `references/question-patterns.md` as a shared library — only add if per-type stacks show significant duplication after drafting.
- Golden tests for the brainstorming skill flow — tracked separately.
- TaskCreate list template for the skill's workflow phases — included in v1 per Item 5 locked decision.

### Out of scope

- Rewriting `/tailor`, `/writing-plans`, or `/implement` — this spec covers brainstorming only.
- Changing the spec file path convention — `.claude/specs/YYYY-MM-DD-<slug>-spec.md` stays as-is.
- Rewriting the visual companion browser tool from scratch — we port verbatim from superpowers.
- Building CI enforcement for skill quality — the no-bloat / under-500-line constraint is self-policed.
- Implementing decomposition-into-multiple-specs machinery — explicitly killed per Q25 revision.

### Constraints

- **Anthropic SKILL.md best practices** — under 500 lines, progressive disclosure, reference files one level deep, TOC on reference files >100 lines, third-person description, `name` uses lowercase-hyphen only.
- **User's no-bloat, no-redundancy directive** — every line earns its place; no parallel lists that duplicate machinery.
- **User's lean directive** — skip anti-patterns table, skip Flutter/Construction adaptations block (covered by CLAUDE.md and adversarial check).
- **CodeMunch file-count cap** — already raised to 10,000 via `JCODEMUNCH_MAX_FOLDER_FILES` env var (separate change, already applied).
- **Port 5947 hard-coded** for the visual companion server; must not collide with `3947` (debug-server), `4948` / `4949` (drivers).
- **User handles git** — the skill saves files but never commits; commit verbs absent from user-review gate.

### Non-goals

- Being a technical design tool. Brainstorming captures intent; tailor and writing-plans handle technical mapping and design.
- Being optional. Every code change runs this skill (HARD-GATE, no size exception).
- Being auto-invoked. The skill is `user-invocable: true` with `disable-model-invocation: true` — only fires on explicit `/brainstorming`.
- Being multi-phase-plan aware. Phasing belongs to Scope gate's v1/deferred/out-of-scope buckets and to writing-plans' multi-phase plan output.

---

## Vision

**User journey (from the developer's perspective):**

1. Developer invokes `/brainstorming` with an opening message describing what they want.
2. Skill responds with a visible TaskCreate list of workflow phases that will flip as the skill progresses — the developer can see where they are at all times.
3. Skill silently runs Phase 0: resolves/refreshes the CodeMunch index, pulls a baseline repo outline, reads `CLAUDE.md` and recent git log.
4. Skill proposes a work-type classification ("This looks like a Bug Fix because…") with reasoning drawn from the outline. Developer confirms or reclassifies with a verb reply.
5. Skill runs type-aware deep exploration via CodeMunch (`search_symbols`, `get_file_outline`, `get_call_hierarchy`, etc. — picked per type). Budget 6-10 calls, no full file reads.
6. Skill begins asking Intent questions, one at a time, multiple choice when possible. Questions are grounded in what the outline revealed.
7. When the internal checklist for Intent has no "still unclear" items, the skill fires the **Intent gate** — a restate with `Confirmed` / `Still unclear` sections and three reply verbs. No arbitrary minimum or maximum question count; the checklist is the sole trigger.
8. Developer replies `confirmed` / `fix: <what>` / `reopen: <bullet>`.
9. On confirmation, skill runs an **adversarial pass** (misinterpretation hunt + contradiction hunt + unknown-unknowns hunt + scope creep hunt, all four at once) and surfaces concerns as a labeled "Adversarial check — Intent" message. Developer replies with clarifications or "no concerns."
10. Skill advances to Scope questions. Same flow — checklist → gate → verbs → adversarial.
11. Skill advances to Vision questions. Same flow.
12. **Snap-back rule:** if any later gate surfaces a contradiction with an earlier one, the skill announces the snap-back in its own message ("I thought we had Intent locked, but your answer just changed my understanding — snapping back to re-confirm Intent"), restates the earlier gate, and resumes forward progression.
13. After all three gates pass, skill runs the **options phase** — 2-3 *scope/UX/fix-shape options* tailored to the work type (scope options for New Feature, change-depth for Feature Add/Mod, fix-shape for Bug Fix, visual directions for UX Polish, refactor-ambition for Refactor+). Developer picks one.
14. **Visual companion** is available throughout, any work type. Lazy trigger: only fires when the model hits a question where visual beats text. Consent offer is its own standalone message, session-scoped, never re-asked. If accepted, server runs on port `5947` serving HTML fragments from `.claude/brainstorm/<session>/content/`.
15. Skill drafts the spec file using the per-type template (shared Intent/Scope/Vision spine + type-specific tail).
16. Skill runs **self-review** against the written file — 7 checks. Surfaces findings as a numbered changelist with reasoning.
17. Developer approves per finding via verbs: `approve: 1,3,4` / `reject: 2` / `skip: 5` / `edit 2: <text>` / `add: <new finding>`.
18. Skill applies approved edits, saves the file (no commit — developer handles git).
19. Skill presents the saved file path for fresh-eye review.
20. Developer replies `approved` / `fix: <what>` / `reopen: <gate>`.
21. On `approved`, skill ends cleanly with a one-line pointer to `/tailor` as the documented next step. **No auto-invoke, no confirmation round trip.**

**Key interactions:**

- **One question per message**, multiple choice preferred, structured reply verbs throughout.
- **Visible machinery**: TaskCreate phase list, labeled adversarial check messages, announced snap-backs, changelist-based self-review findings — nothing happens silently.
- **No ceremony on happy paths**: clean self-review → no findings → straight to fresh-eye file review with one sentence.
- **User-controlled checkpoints** at every gate, not arbitrary question counts.

**Acceptance-by-feel:**

- The developer finishes a brainstorm knowing the spec captures what they actually wanted — not a diluted version.
- The developer can trust that the skill caught contradictions before writing anything to disk.
- The developer never feels like they "already said that" — snap-backs only fire when genuinely warranted, and are explicitly announced.
- The developer can audit the skill's reasoning at every step — nothing is silently inferred, nothing is silently fixed.
- The developer feels the friction is *earning* its cost. If they skip a question, they know why. If they answer a clarifying question, they know it wasn't a fishing expedition.

---

## Selected Shape

**Option:** Structural adoption of the `obra/superpowers` brainstorming format with selective retention of Field-Guide-specific behaviors (Q1 = B).

**What gets adopted from superpowers:**
- Flat checklist workflow (rather than phase-numbered structure)
- HARD-GATE wording style (but with XS/S exception deleted)
- Self-review step (with 7 checks instead of superpowers' 4)
- User-reviews-spec gate
- Visual companion with browser-based mockup tool (literal port, not a rewrite)
- Progressive disclosure via reference files
- Third-person description field

**What gets retained from the current skill / added new:**
- `.claude/specs/` spec path (not `docs/superpowers/specs/`)
- Zero-ambiguity intent gate (strengthened into Gate B+C+D)
- Per-work-type classification and tailored gate content (5 primary + 3 secondary types)
- Internal checklist with baseline + type-specific stacks, failures surface as "Still unclear"
- Linear gate sequencing with announced snap-back
- Adversarial self-check after each gate (all four hunts: misinterpretation, contradiction, unknown-unknowns, scope creep)
- CodeMunch-based Phase 0 exploration (not glob/grep)
- TaskCreate-based visible workflow tracking
- Per-finding self-review changelist approval (stronger than superpowers' silent-fix pattern)
- Fixed port `5947` for visual companion (not ephemeral)
- No git commit — user handles git
- No tailor handoff offer — clean terminal state
- `disable-model-invocation: true` — user-invocable only

**Why not the other options:** Full replacement (Q1 option A) would lose the zero-ambiguity focus and the per-type tailoring that makes intent capture actually work for this user's stated priority. Light touch (Q1 option C) would miss the structural wins of superpowers' flat-checklist format and would leave the 11-section technical template in place.

---

## Current Behavior (Feature Modification tail section)

`.claude/skills/brainstorming/skill.md` exists today with:
- Phase 1 / Phase 2 / Phase 3 structure
- 11-section spec template covering technical concerns (data model, state management, migration, etc.)
- `HARD-GATE` with XS/S exception
- No adversarial pass, no per-type tailoring, no classification step, no Phase 0 exploration, no visual companion
- No CodeMunch integration
- Single generic intent gate (restate + ask confirm, once)
- References `question-patterns.md` and `design-sections.md` (one or both may no longer exist)
- `user-invocable: true` but also has "You MUST use this" language that triggers auto-invocation
- Terminal state offers `/tailor` handoff with confirmation round trip

## New Behavior (Feature Modification tail section)

After the rewrite, `.claude/skills/brainstorming/SKILL.md` will have:

- **Flat checklist workflow** driven by TaskCreate, replacing Phase 1/2/3 structure.
- **Classification mini-gate** (Q7 = B+E): Claude infers work type from opening message + baseline outline, presents with reasoning, user confirms with verbs. Mid-stream reclassification allowed with announced snap-back.
- **Phase 0 CodeMunch exploration** (Q10 + Q11 = B): resolve/refresh index (auto-refresh stale), baseline `get_repo_outline`, classify, then type-aware semantic search (`search_symbols` + `get_file_outline` + `get_call_hierarchy` etc. per type), ranked context, `CLAUDE.md` + git log. Budget 6-10 CodeMunch calls, no full file reads. Deeper mapping deferred to `/tailor`.
- **Three gates** (Intent / Scope / Vision) with the Q3 definitions:
  - Intent = problem / who feels it / measurable success criteria / why now
  - Scope = in scope / deferred / out of scope / constraints / non-goals
  - Vision = user journey / key interactions / acceptance-by-feel
- **Gate machinery** (Q4 + Q5 + Q8):
  - Linear sequencing with explicit announced snap-back on contradiction (Q4 = D)
  - Presentation format: structured correction verbs (`confirmed` / `fix: <what>` / `reopen: <bullet>`) + explicit `Still unclear` section (Q5 = F)
  - Internal checklist = baseline + type-specific stacks (Q8a = C); internal visibility with failures surfacing as "Still unclear" (Q8b = C)
  - No floor, no ceiling — checklist is sole gate trigger (Q13 = A)
- **Adversarial self-check after each gate** (Q9):
  - Fires after Intent, Scope, Vision each (Q9a = B)
  - Runs all four hunts combined internally: misinterpretation, contradiction, unknown-unknowns, scope creep (Q9b = E)
  - Surfaces findings as labeled "Adversarial check — <gate>" message with numbered concerns and reply instructions (Q9c = B)
- **Options phase** after all three gates pass (Q12 = B):
  - 2-3 options tailored to work type
  - New Feature → scope options (minimal v1 / full / phased)
  - Feature Add/Mod → change-depth options (surgical / variant / replace-and-deprecate)
  - Bug Fix → fix-shape options (symptom / underlying / restructure)
  - UX Polish → visual directions (visual companion earns its keep here)
  - Refactor+ → refactor-ambition (minimum / single class / whole subsystem)
- **Per-type spec output template** (Q14 = B):
  - Shared Intent/Scope/Vision spine
  - Type-specific tail sections per Q14 option B
- **Spec draft flow** (Q15 revised + Q17):
  - Write whole spec → run self-review → present findings as changelist → user approves per finding → apply approved edits → save (no commit) → present file path → fresh-eye user review → `approved` proceeds
- **Self-review 7 checks** (Q16 = B revised):
  - (a) Placeholder scan
  - (b) Internal consistency
  - (c) Scope cohesion (conflation, not phasing — phasing belongs to Scope gate and writing-plans)
  - (d) Ambiguity check
  - (e) CLAUDE.md constraint check
  - (f) Traceability / anti-invention (every bullet traceable to user confirmation)
  - (g) Success criteria measurability
- **User-review gate** (Q17 revised):
  - 17a = A: fresh-eye file review even when self-review is clean
  - 17b = D: per-finding verbs including `approve: N,M` / `reject: N` / `skip: N` / `edit N: <text>` / `add: <new finding>`
  - 17c: save spec, no commit, present file path — user handles git
  - No `decompose` verb (Q25 kill)
- **Terminal state** (Q18 = C): clean end, one-line pointer to `/tailor` as documented next step, no auto-invoke, no confirmation round trip.
- **Visual companion** (Q19):
  - Literal port from `obra/superpowers/skills/brainstorming/scripts/` (Q19 = A)
  - Available for any work type, per-question decision based on "would user understand better by seeing than reading" (Q19a = D)
  - Lazy trigger + session-scoped consent (Q19b = B+E)
  - State directory: `.claude/brainstorm/<session>/` (adapted from `.superpowers/brainstorm/`)
  - Fixed port: **5947** (not ephemeral; `server.cjs` and `start-server.sh` need minor modification)
- **File structure** (Q20 = D):
  - `SKILL.md` (workflow + cross-references, lean)
  - `references/intent-capture-gates.md` (gate machinery)
  - `references/work-types.md` (5 primary + 3 secondary types with Intent/Scope/Vision stacks and options content)
  - `references/spec-output.md` (per-type templates, self-review, user review gate)
  - `references/visual-companion.md` (ported from superpowers)
  - `scripts/` (ported server + helpers)
  - NO `question-patterns.md` by default (add only if duplication emerges)
- **HARD-GATE** (Q21 = E): no size exceptions; CLAUDE.md escape hatch also deleted.
- **Description field** (Q22 = A) with `disable-model-invocation: true`:
  > "Captures user intent before any feature work, bug fix, UX change, or refactor. Runs a structured Intent/Scope/Vision gating flow with adversarial self-checks, classifies the work type (new feature, feature modification, bug fix, UX polish, or refactor), and outputs an approved spec file for tailor and writing-plans to consume. Use before writing code, modifying behavior, fixing bugs, or restructuring. Required for every change — no size exceptions."
- **Anti-patterns table deleted** (Q23 = B).
- **Flutter/Construction adaptations section deleted** (Q24 = B).
- **Secondary work types** (Security Hardening, Data/Schema Migration, Documentation) use a generic gate template — to be drafted in `references/work-types.md`.

## Migration (Feature Modification tail section)

- Delete legacy `.claude/skills/brainstorming/skill.md` (replaced by `SKILL.md`).
- Delete legacy `.claude/skills/brainstorming/references/question-patterns.md` and `design-sections.md` if present.
- Delete legacy Phase 1/2/3 text, 11-section template, and anti-patterns/Flutter adaptation blocks.
- Preserve: nothing substantive. This is a full rewrite.
- `.claude/brainstorm/` directory will be created on first visual-companion invocation.
- `.gitignore` must be updated to exclude `.claude/brainstorm/`.
- `.claude/CLAUDE.md` must be edited to rewrite the sizing guide (remove XS/S escape hatch) — every change runs the full pipeline now.

---

## Files Affected

**Created:**
- `.claude/skills/brainstorming/SKILL.md`
- `.claude/skills/brainstorming/references/intent-capture-gates.md`
- `.claude/skills/brainstorming/references/work-types.md`
- `.claude/skills/brainstorming/references/spec-output.md`
- `.claude/skills/brainstorming/references/visual-companion.md`
- `.claude/skills/brainstorming/scripts/server.cjs`
- `.claude/skills/brainstorming/scripts/start-server.sh`
- `.claude/skills/brainstorming/scripts/stop-server.sh`
- `.claude/skills/brainstorming/scripts/frame-template.html`
- `.claude/skills/brainstorming/scripts/helper.js`

**Modified:**
- `.claude/skills/brainstorming/skill.md` → renamed to `SKILL.md` with full rewrite
- `.claude/CLAUDE.md` → sizing guide rewrite (delete XS/S escape hatch)
- `.gitignore` → add `.claude/brainstorm/`

**Deleted:**
- `.claude/skills/brainstorming/references/question-patterns.md` (if present)
- `.claude/skills/brainstorming/references/design-sections.md` (if present)

---

## Open Questions / Deferred to Implementation

These were explicitly deferred during brainstorming (Q26 = handle during spec drafting/implementation via inline review):

1. **Baseline Intent / Scope / Vision checklist items** — the generic baseline that all work types inherit. Will be drafted inline in `references/intent-capture-gates.md` during implementation and surfaced for user approval.
2. **Per-type checklist stacks** — 5 primary types × 3 gates = 15 checklists. Drafted inline in `references/work-types.md` and surfaced per type for user approval.
3. **Per-type options phase content** — concrete framings of the 2-3 options for each type. Drafted inline in `references/work-types.md`.
4. **Secondary type generic template** — the shared gate template for Security Hardening, Data/Schema Migration, and Documentation. Drafted inline in `references/work-types.md`.
5. **`start-server.sh` and `server.cjs` port modification** — superpowers uses ephemeral ports; we need a minor patch to accept/default port `5947`. Applied during the `scripts/` port step.
6. **`visual-companion.md` path adaptation** — rewrite `.superpowers/brainstorm/` references to `.claude/brainstorm/` throughout.

---

## Success Criteria (repeated for traceability)

1. Every brainstorm produces a spec file at `.claude/specs/YYYY-MM-DD-<slug>-spec.md` with populated Intent / Scope / Vision sections and type-specific tail.
2. No spec leaves the skill without passing self-review on 7 checks.
3. No gate passes without explicit user confirmation via structured reply verbs.
4. No mid-stream contradiction is silently swallowed — snap-back announced in every case.
5. `SKILL.md` stays under 500 lines per Anthropic best practices.
6. Zero references to deleted agents/skills/docs after rewrite.
7. Every locked decision in this spec is traceable to a specific piece of the rewritten skill.
8. Visual companion server runs on port `5947` and doesn't collide with `3947`/`4948`/`4949`.
9. CLAUDE.md sizing guide no longer has an XS/S escape hatch.
10. The `disable-model-invocation: true` frontmatter prevents auto-firing; only `/brainstorming` triggers the skill.
