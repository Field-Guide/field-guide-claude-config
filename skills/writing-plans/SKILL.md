---
name: writing-plans
description: "Reads tailor output and writes implementation plans with machine-readable phase ranges for /implement."
user-invocable: true
disable-model-invocation: true
---

# Writing Plans

Use tailor output to write an implementation plan. The plan must include a
machine-readable phase-range block so `/implement` can execute by phase without
reading plan bodies into orchestrator context.

## Prerequisite

`/tailor` must already have been run for the spec. If the matching tailor output
does not exist, stop and tell the user to run `/tailor <spec-path>` first.

## Workflow

1. Read the spec.
2. Find the matching tailor directory.
3. Load the tailor output as the source of implementation context.
4. Decide whether the main agent writes the plan directly or whether
   `plan-writer-agent` subagents are warranted.
5. Write the plan.
6. Run the three review sweeps.
7. Fix findings and rerun sweeps up to 3 cycles.
8. Present the final plan summary.

## Writer Strategy

- Write directly for small and medium plans.
- Use `plan-writer-agent` only when the plan is genuinely large enough to merit
  a split.
- Multi-writer plans should split on natural phase boundaries, not arbitrary
  file groups.

## Plan Header

Every plan must start with a header like this:

```markdown
# <Feature Name> Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** <one sentence>
**Spec:** `.claude/specs/YYYY-MM-DD-<name>-spec.md`
**Tailor:** `.claude/tailor/YYYY-MM-DD-<spec-slug>/`
**Architecture:** <2-3 sentences>
**Tech Stack:** <key technologies>
**Blast Radius:** <summary>

## Phase Ranges

| Phase | Name | Start | End |
| --- | --- | --- | --- |
| 1 | <phase name> | <line number> | <line number> |
| 2 | <phase name> | <line number> | <line number> |

---
```

The `Phase Ranges` block is mandatory for new plans.

## Phase Range Rules

- Populate the table after the plan body is assembled so the line numbers match
  the saved file.
- `Start` and `End` are 1-based line numbers in the final plan file.
- Each phase row maps to the matching `## Phase N:` section.
- If the line numbers change during review fixes, update the table before the
  final save.

## Plan Body Rules

- Use real file paths, real symbols, and real imports from tailor output.
- Keep steps concrete and executable.
- Include enough detail that an implementer does not need to guess.
- Do not include `flutter test` steps in plans.
- Local verification in plans is limited to `flutter analyze` where appropriate.

## Review Loop

Run these three reviewers every cycle:

- `code-review-agent`
- `security-agent`
- `completeness-review-agent`

Completeness review verifies fidelity to the spec. It does not get to rewrite
the spec.

If any reviewer returns findings:

1. Consolidate them.
2. Dispatch `plan-fixer-agent`.
3. Rerun all three sweeps.

Maximum 3 cycles. If findings still remain, escalate to the user.

## Hard Gates

<HARD-GATE>
Do not write the plan until tailor output is loaded.

Do not present the plan as final until:
1. the header is complete
2. the `Phase Ranges` table is populated
3. the review loop is complete or escalated
</HARD-GATE>

## Save Locations

- Plans: `.claude/plans/YYYY-MM-DD-<feature-name>.md`
- Writer fragments: `.claude/plans/parts/<plan-name>-writer-N.md`
- Review sweeps: `.claude/plans/review_sweeps/<plan-name>-<date>/`
