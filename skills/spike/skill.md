---
name: spike
description: Time-boxed research and hypothesis testing. No code ships.
user-invocable: true
---

# /spike — Research & Hypothesis Testing

## Purpose
Investigate a hypothesis or question through targeted codebase exploration, external research, and prototyping. Produces a findings document — never production code.

## Input
- A hypothesis, question, or area of uncertainty
- Optional: time constraint (default: 1-2 sessions max)

## Process

1. **Frame the hypothesis** — What are we trying to learn? What would confirm/deny it?
2. **Research** — Explore codebase, read docs, check dependencies, prototype if needed
3. **Document findings** — Write to `.claude/spikes/YYYY-MM-DD-<topic>.md`
4. **Recommend next step:**
   - **Proceed** — Findings support the hypothesis. Recommend writing a spec.
   - **Park** — Inconclusive. Document what's known, what's missing.
   - **Kill** — Hypothesis disproven or not viable. Document why.

## Output Format

```markdown
# Spike: [Topic]

**Date:** YYYY-MM-DD
**Hypothesis:** [What we're investigating]
**Verdict:** Proceed | Park | Kill

## Findings
[Key discoveries, with evidence]

## Recommendation
[Next steps based on verdict]
```

## Rules
- **No production code ships from a spike.** Prototypes stay in scratch files or get deleted.
- **Time-boxed.** If you haven't found an answer in 2 sessions, write up what you know and Park it.
- **Be honest about uncertainty.** "I don't know" is a valid finding.

## Anti-Patterns
| Anti-Pattern | Why |
|---|---|
| Shipping spike code to production | Spikes are exploratory — not tested, not reviewed |
| Endless research without documenting | Time-box and write up findings |
| Skipping the recommendation | The whole point is to decide: proceed, park, or kill |
