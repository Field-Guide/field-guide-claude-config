# Spec Output — Templates, Self-Review, User Review

How to draft the spec file, run the 7-check self-review, and drive the user review gate.

## Table of Contents

- [Output Path](#output-path)
- [Shared Spine (Intent / Scope / Vision)](#shared-spine-intent--scope--vision)
- [Per-Type Tail Sections](#per-type-tail-sections)
- [Self-Review — 7 Checks](#self-review--7-checks)
- [Presenting the Changelist](#presenting-the-changelist)
- [User Review Gate](#user-review-gate)
- [Terminal State](#terminal-state)

## Output Path

Save specs to:

```
.claude/specs/YYYY-MM-DD-<slug>-spec.md
```

- `YYYY-MM-DD` — today's date (resolve relative dates; e.g., "today" → current date)
- `<slug>` — short kebab-case topic slug derived from the opening message and work type (e.g., `sync-engine-refactor`, `pay-application-feature`, `mdot-1126-weekly-sesc`)
- Suffix is **always** `-spec.md`; never `-design.md` or `-plan.md`

The skill **saves** the file. **It never commits.** The user handles git.

## Shared Spine (Intent / Scope / Vision)

Every spec, regardless of type, opens with this spine. The content is drawn directly from the locked gate restates — do not re-paraphrase, do not invent new bullets.

```markdown
# <Topic Title>

**Work Type:** <primary type>  (optionally: "(+ <secondary>)")
**Date:** YYYY-MM-DD
**Spec Author:** Paired conversation (<model name> + user)
**Supersedes:** <path to prior spec if any, else omit>

---

## Intent

**Problem:** <one-paragraph restatement, drawn verbatim from Intent gate Confirmed bullets>

**Who feels it:** <bullets>

**Success criteria (measurable):**
1. <criterion 1>
2. <criterion 2>
...

**Why now:** <one paragraph>

---

## Scope

### In scope (v1)
- <bullet>
- <bullet>

### Deferred (not v1, not out of scope forever)
- <bullet>

### Out of scope
- <bullet>

### Constraints
- <bullet>

### Non-goals
- <bullet>

---

## Vision

**User journey:**
1. <step>
2. <step>
...

**Key interactions:**
- <bullet>

**Acceptance-by-feel:**
- <bullet>

---
```

## Per-Type Tail Sections

After the spine, append the tail section(s) matching the work type.

### New Feature tail

```markdown
## Selected Shape

**Option:** <Minimal v1 | Full v1 | Phased>
**Why this over the others:** <one paragraph>

## User Stories (one-liners)

- As a <role>, I want <capability> so that <outcome>.

## Entry Point & Empty State

- **Entry point:** <where the user encounters this first>
- **Empty state:** <first-run screen before any data exists>

## Sync & Data Surface

- **New tables:** <list or "none">
- **New columns on existing tables:** <list or "none">
- **Builtin vs user-created:** <which flag, if any>
- **Offline-first on day one:** <yes/no + why>

## Open Questions / Deferred to Tailor

- <open question>
```

### Feature Add/Mod tail

```markdown
## Current Behavior

<one paragraph describing how it works today, drawn from Phase 0 exploration>

## New Behavior

<one paragraph describing the target behavior, drawn from Vision gate>

## Change Shape

**Option:** <Surgical | Variant | Replace-and-deprecate>
**Why this over the others:** <one paragraph>

## Migration

- **Backwards compatibility:** <required? how>
- **Data repair:** <required? scope>
- **Feature flag:** <yes/no>

## Files Likely Affected (for tailor)

- <path>
- <path>

## Open Questions / Deferred to Tailor

- <open question>
```

### Bug Fix tail

```markdown
## Reproduction

1. <step>
2. <step>

**Observed:** <what actually happens>
**Expected:** <what should happen>

## Fix Shape

**Option:** <Symptom | Root-cause | Restructure>
**Why this over the others:** <one paragraph>

## Suspected Location(s)

- <file:line or symbol reference from Phase 0>

## Data Repair

- **Existing wrong records:** <scope + strategy, or "none">

## Regression Guard

- **Test level:** <unit | widget | driver | sync-verification>
- **Signal that locks the fix:** <what the test asserts>

## Open Questions / Deferred to Tailor

- <open question>
```

### UX Polish tail

```markdown
## Target Screens

- <screen or widget path>

## Selected Direction

**Option:** <Direction A name | Direction B name | Direction C name>
**Why this over the others:** <one paragraph>
**Visual companion artifacts:** <list of HTML files pushed during the session, if any>

## Token / Component Scope

- **Design tokens touched:** <FieldGuideSpacing, FieldGuideColors, ... or "none">
- **Component changes:** <structural edits needed, or "token-only">
- **Lint rules engaged:** <no_hardcoded_spacing, no_raw_button, ... or "none">

## Acceptance-by-feel

- <bullet from Vision gate>

## Open Questions / Deferred to Tailor

- <open question>
```

### Refactor+ tail

```markdown
## Pain Point

<one paragraph describing what hurts today, drawn from Intent gate>

## Target Shape

<one paragraph describing the new shape, drawn from Vision gate>

## Ambition Level

**Option:** <Minimum | Single class/file | Whole subsystem>
**Why this over the others:** <one paragraph>
**Phase scope:** <"this spec covers phase N of M; later phases get their own specs" if applicable>

## Blast Radius Budget

- **Files touched:** <cap>
- **Behavior changes allowed:** <none | specific exceptions>
- **Rollback strategy:** <single PR | multi-PR | feature flag>

## Test Coverage Floor

- <what must exist before the refactor lands>

## Open Questions / Deferred to Tailor

- <open question>
```

### Security Hardening, Data/Schema Migration, Documentation tails

These use a short generic tail:

```markdown
## Selected Shape

**Option:** <option chosen from the type's generic options>
**Why this over the others:** <one paragraph>

## Constraints & Invariants

- <constraint from Scope gate>

## Validation / Rollout

- <how we know it worked; what the user sees>

## Open Questions / Deferred to Tailor

- <open question>
```

## Self-Review — 7 Checks

After writing the whole spec, run all 7 checks internally. Every finding becomes a numbered item in the changelist the skill presents to the user.

| # | Check | What to look for |
|---|-------|------------------|
| a | **Placeholder scan** | Any `TBD`, `TODO`, `...`, `<fill in>`, empty bullets, "more later", or template tokens left in? |
| b | **Internal consistency** | Does any section contradict another? Do tail options match the Selected Shape? Does the work type in the header match the tail section used? |
| c | **Scope cohesion** | Is everything in scope genuinely part of *one* effort, or is there conflation? (Phasing is not conflation — phasing belongs in Scope's deferred bucket and in writing-plans' multi-phase plan output.) |
| d | **Ambiguity check** | Could any requirement be interpreted two different ways? If so, pick one and make it explicit, or flag it in Open Questions. |
| e | **CLAUDE.md constraint check** | Does anything violate documented constraints? (Offline-first, RLS invariants, sync integrity, design tokens, lint rules, schema-change footprint, Bash vs pwsh, etc.) |
| f | **Traceability / anti-invention** | Every bullet must trace to a user confirmation (Intent/Scope/Vision gate answers or Options phase pick). Anything the skill invented without explicit confirmation is flagged. |
| g | **Success criteria measurability** | Is every success criterion in Intent stated in a way a human could verify without asking "what does that mean"? If not, propose a sharper version. |

## Presenting the Changelist

Present findings as a single numbered list with reasoning per item. Do not silently edit the file.

```
## Self-review findings

I ran the 7 checks on the draft at `.claude/specs/<filename>.md`. Here's what came back:

1. **(c) Scope cohesion** — "Users can also export to CSV" snuck into In Scope, but it was never discussed in Intent or Scope gates. Suggest moving to Deferred with a one-line note.
2. **(d) Ambiguity** — Success criterion #3 says "performance should be acceptable". Suggest: "initial screen render under 250ms on a Pixel 6".
3. **(f) Traceability** — "Offline conflict shows red banner" appears in the Vision journey but wasn't in any gate answer. Suggest removing or asking the user to confirm.
...

**Reply per finding:**
- `approve: 1,3` — apply those fixes as proposed
- `reject: 2` — leave that bullet as-is, with a short reason if you want to log it
- `skip: 5` — defer this one (I'll note it in Open Questions)
- `edit 2: <text>` — apply a different fix than the one I proposed
- `add: <new finding>` — you noticed something I missed; I'll add it and propose a fix

Or: `approve all`, `reject all`, or `no changes needed` as shortcuts.
```

If the 7 checks come up empty, present:

```
## Self-review findings

All 7 checks passed: no placeholders, consistent, scope-cohesive, unambiguous, CLAUDE.md-compliant, fully traceable, measurable.

Moving on to your fresh-eye review.
```

Apply approved fixes to the file, then move to the user review gate.

## User Review Gate

Present the saved spec path and ask for a fresh-eye review — **always**, even when self-review came up empty (that's the spec's `17a = A` rule).

```
## Spec saved for your review

Path: `.claude/specs/YYYY-MM-DD-<slug>-spec.md`

Please give it a fresh-eye read and let me know how you want to proceed.

**Reply:**
- `approved` — proceed to terminal state
- `fix: <what>` — point me at what to change; I'll edit and re-present
- `reopen: <gate>` — reopen Intent, Scope, or Vision; I'll snap back and rerun that gate + its adversarial check
```

Note the verbs: there is **no `decompose` verb** (decomposition into multiple specs was explicitly killed). If the user asks to split the work, they can start a new brainstorm for the second spec after this one lands.

## Terminal State

When the user replies `approved`:

```
Spec approved and saved at `.claude/specs/YYYY-MM-DD-<slug>-spec.md`.

Next step: run `/tailor` to map the codebase against this spec before `/writing-plans`.
```

**Do not** offer to auto-invoke `/tailor`. **Do not** ask "shall I proceed?". The user drives the pipeline from here. The skill ends cleanly with that one-line pointer and nothing else.
