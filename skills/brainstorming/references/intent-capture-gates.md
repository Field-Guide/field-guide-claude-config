# Intent Capture Gates — Machinery

How Intent / Scope / Vision gates work end-to-end: baseline checklists, trigger conditions, presentation format, adversarial self-check, and the snap-back rule.

## Table of Contents

- [The Three Gates](#the-three-gates)
- [Internal Checklists](#internal-checklists)
- [Baseline Checklist Items](#baseline-checklist-items)
- [Gate Trigger Rule (No Floor, No Ceiling)](#gate-trigger-rule-no-floor-no-ceiling)
- [Gate Presentation Format](#gate-presentation-format)
- [Reply Verbs](#reply-verbs)
- [Adversarial Self-Check](#adversarial-self-check)
- [Snap-Back Rule](#snap-back-rule)
- [Question Style Rules](#question-style-rules)

## The Three Gates

Every brainstorm clears three gates in order: **Intent → Scope → Vision**. Each gate has a fixed definition of what it captures. Do not conflate them — each gate's checklist items must stay in its own bucket.

| Gate | Definition | Captures |
|------|------------|----------|
| **Intent** | Why this exists at all | Problem, who feels it, measurable success criteria, why now |
| **Scope** | What is and isn't in this specific effort | In scope (v1), deferred, out of scope, constraints, non-goals |
| **Vision** | How it should feel to use when done | User journey, key interactions, acceptance-by-feel |

If a question doesn't map cleanly to one of these, it belongs in `/tailor` (technical mapping) or `/writing-plans` (implementation strategy), **not** in brainstorming.

## Internal Checklists

Each gate has an **internal checklist** of items that must be answered before the gate can fire. The checklist has two layers:

1. **Baseline items** — apply to every work type (see below)
2. **Type-specific items** — loaded from `work-types.md` per the classification decided in Phase 0

The checklist is internal to the model. Items are never listed verbatim to the user in the question stream — they drive which question to ask next. However, **unsatisfied items are surfaced in the `Still unclear` section of the gate restate** so the user can see what's still missing.

## Baseline Checklist Items

### Intent baseline (applies to every work type)

- [ ] **Problem statement** — what's broken or missing? One sentence, concrete.
- [ ] **Felt by whom** — the inspector in the field? The office user? A downstream consumer (sync, export, PDF)?
- [ ] **Current pain cost** — how bad is it today? How often does it hurt? Lost work, wasted time, wrong data, compliance risk?
- [ ] **Success criterion #1** — one measurable outcome the user would accept as "done".
- [ ] **Success criterion #2** — at least one more; ideally different flavor (quantitative + qualitative).
- [ ] **Why now** — what changed that makes this the right moment? Is there an external deadline, a prior-session dependency, or a blocking bug?
- [ ] **Non-solution framing check** — has the user accidentally described a solution instead of a problem? If yes, rewind them.

### Scope baseline

- [ ] **In scope for v1** — concrete list of what's shipping in this effort
- [ ] **Deferred** — things we'll do later but not now (not forever)
- [ ] **Out of scope forever** — explicit rejections to prevent creep
- [ ] **Hard constraints** — security invariants, offline-first requirements, schema version locks, API limits, vendor SDK caps, existing lint bans
- [ ] **Non-goals** — behaviors this effort must *not* introduce (e.g., "no new auth mode")
- [ ] **Interference check** — does anything here collide with other in-flight work? (Check `git log` + recent specs.)
- [ ] **Security boundary check** — touches auth / RLS / sync / PII / device enrollment? If yes, note it so the adversarial pass catches it.

### Vision baseline

- [ ] **Primary user journey** — step-by-step from trigger to outcome, through the user's eyes
- [ ] **Key interactions** — the 2-5 moments that define whether it feels right
- [ ] **Acceptance-by-feel** — how the user recognizes "yes, this is what I wanted" without running a test suite
- [ ] **Failure modes the user should see** — what must be visible when things go wrong (offline, conflict, permission denied, schema mismatch)
- [ ] **Field conditions sanity check** — does this work with gloves, in bright sun, mid-sync, offline, on a slow device?

For per-type additions layered on top of these baselines, see `work-types.md`.

## Gate Trigger Rule (No Floor, No Ceiling)

A gate fires **when and only when** the internal checklist has zero unsatisfied items. There is no minimum question count and no maximum — the checklist is the sole trigger.

- If the user volunteers answers to multiple items in one message, cross them off. The gate may fire on the next turn.
- If a question is stuck in ambiguity, keep the item open and ask a sharper question. Do not fire the gate to "make progress".
- If an item is genuinely non-applicable (e.g., "why now" for a purely speculative feature), note it as `n/a` with a one-line reason *in the gate restate* so the user can override.

## Gate Presentation Format

When a gate fires, send a single message in this shape:

```
## <Gate name> Gate

**Confirmed:**
- <bullet 1 restating user's answer in our words>
- <bullet 2 ...>
- <bullet N>

**Still unclear:**
- <checklist item we could not satisfy>      ← empty section if nothing unclear
- <another>

**Reply:**
- `confirmed` — advance to the adversarial check
- `fix: <what>` — correct a specific Confirmed bullet
- `reopen: <bullet or item>` — reopen a Still unclear item with more detail
```

If `Still unclear` is empty, the gate is ready to fire cleanly. If it's non-empty, the user must reopen those items before the gate passes.

## Reply Verbs

Only these three verbs advance a gate:

- **`confirmed`** — every Confirmed bullet is exactly right; advance
- **`fix: <what>`** — correct a specific bullet; skill rewrites it and re-presents the gate
- **`reopen: <bullet or item>`** — pull an item back into active questioning

Any other reply is treated as free text clarification; the skill interprets it, updates the gate restate, and re-presents.

## Adversarial Self-Check

After each gate passes, before advancing to the next, run an **adversarial pass** that surfaces concerns in a labeled message. All four hunts run internally in parallel; their outputs merge into one numbered list.

### The Four Hunts

1. **Misinterpretation** — Am I restating what the user actually said, or have I paraphrased away a nuance?
2. **Contradiction** — Does any Confirmed bullet contradict another, or contradict `CLAUDE.md` constraints, or contradict an earlier gate?
3. **Unknown unknowns** — What would a hostile reviewer ask that I haven't? Examples: offline-first implications, sync conflict scenarios, PDF export path, RLS exposure, schema version coupling, multi-tenant boundaries, field-condition edge cases.
4. **Scope creep** — Did the user or I just quietly widen the scope beyond the Scope gate's v1 list? Did an Intent bullet grow an implementation detail?

### Presentation Format

```
## Adversarial Check — <Gate name>

I looked at what we just locked and found the following concerns:

1. <hunt type>: <concern> → <suggested clarification>
2. <hunt type>: <concern> → <suggested clarification>
...

**Reply:**
- `no concerns` — proceed to the next gate
- `<number>: <clarification text>` — address a specific concern
- `ignore <number>: <reason>` — dismiss a concern (with reasoning, so we capture the decision)
```

If all four hunts come up empty, send:

```
## Adversarial Check — <Gate name>

No misinterpretation, contradiction, unknown-unknowns, or scope creep detected. Ready to advance.

**Reply:** `proceed` to continue, or any text to reopen.
```

## Snap-Back Rule

If any gate's adversarial check — or the *next* gate's questioning — surfaces a contradiction with an **earlier** locked gate, do not silently fold the contradiction into the current gate. Announce a snap-back in its own message:

```
## Snap-back: re-confirming <earlier gate>

While working on <current gate>, your answer just changed my understanding of <earlier gate>.
Specifically: <what shifted>.

I'm snapping back to re-confirm <earlier gate> before we continue.
```

Then re-present the earlier gate's restate with the updated bullet(s), run its adversarial check again, and only resume forward progression after the user re-confirms. This is the only mechanism for editing a locked gate — everything else is forward-only.

**Snap-back is never silent.** If you update an earlier gate without telling the user, you've broken the rule. Even a trivial-seeming update must produce a snap-back message so the user sees the causal chain.

## Question Style Rules

While a gate's checklist has open items, each question must obey:

1. **One question per message.** No stacking, no "also, while you're here".
2. **Prefer multiple choice when feasible.** Offer A/B/C options with short labels, and always include a `D: none of these / other` escape hatch.
3. **Ground questions in what Phase 0 revealed.** "I see `MdotHubController` already exposes `hydrate()` — does this new behavior run inside that hydrate pass, or outside it?" beats "where should this run?"
4. **Never fish for permission.** Don't ask "can I check X?" — just check it silently as part of Phase 0.
5. **Never ask the same thing twice.** If the user already answered an item, cross it off; do not re-ask for confirmation until the gate fires.
6. **Never propose solutions inside a question.** Intent/Scope/Vision gates capture *what* and *why*, not *how*. Solution shaping belongs to the Options phase.
7. **Never dump a questionnaire.** A question turn is short markdown with one heading, one question, and one reply path.

Use this default question shape:

```markdown
## <Intent|Scope|Vision>

<one-sentence setup tied to the missing checklist item>

<single question>?

- A. <option>
- B. <option>
- C. <option>
- D. Other

**Reply:** `A`, `B`, `C`, or `D: <answer>`
```
