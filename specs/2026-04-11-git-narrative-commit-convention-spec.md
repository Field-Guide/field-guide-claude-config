# Git Narrative Commit Convention Spec

**Work Type:** Process / Tooling (new convention + enforcement hook)
**Date:** 2026-04-11
**Spec Author:** Paired conversation (Claude Opus 4.6 + user)

---

## Intent

**Problem:** The Field Guide App's git history uses Conventional Commits prefixes (`feat`, `fix`, `refactor`, etc.) but commits are subject-line only - no body, no rationale, no decision context. The "why" behind architectural decisions is lost as soon as the conversation that produced them ends. AI agents reading the history get *what* changed but never *why*, so institutional knowledge evaporates.

**Core intent:** Make git history the durable narrative layer for the codebase. A meaningful commit should tell future maintainers and future AI agents what problem was being solved, what decision was made, what tradeoffs were accepted, and what evidence made the change credible. Active plans and state files can still track in-progress work, but committed history should become the canonical source for durable intent and direction.

**Who feels it:**
- The user, when returning to code months later and needing to understand why a particular approach was chosen.
- AI agents (Claude Code, future tools), which read `git log` and `git blame` for context but find only terse subject lines.
- Any future collaborator who inherits the codebase.

**Success criteria:**
1. Every meaningful codebase change has a narrative body explaining problem, decision, tradeoff, and evidence.
2. `feat`, `fix`, `refactor`, and `perf` commits are always narrative commits and require a body plus `Reason:` trailer (enforced by hook).
3. `test`, `docs`, `chore`, `ci`, and `build` commits may be mechanical-only only when unscoped. A scoped lightweight commit is treated as narrative and must carry a body plus `Reason:` trailer (enforced by hook).
4. `Reason:` is a real git trailer in the trailer block, not a loose text match, so `git log --format='%(trailers:key=Reason)'` remains reliable.
5. Scopes are validated against an extensible allowlist for every scoped commit (enforced by hook).
6. The convention is documented in both Claude-facing and Codex-facing context so different AI agents follow it without being told.
7. Durable intent moves into commit history going forward, reducing reliance on scattered state files for decisions that are already committed.
8. The history becomes queryable: `git log --format='%(trailers:key=Reason)'` returns meaningful data going forward.

**Why now:** The user identified that architectural decisions and nuance are being lost. The project is AI-assisted (Claude Code, Codex, and future tools), and structured commit history is the lowest-friction way to preserve institutional knowledge without maintaining separate documentation for decisions that already belong with the code changes.

---

## Research Summary

### What exists in the ecosystem

| Approach | Source | Key Insight |
|----------|--------|-------------|
| Linux kernel commit style | `Documentation/process/submitting-patches.rst` | Gold standard: problem → root cause → solution → justification |
| Conventional Commits | conventionalcommits.org | Structural skeleton (type/scope/description) — already in use here |
| Git trailers | Native git feature | Machine-parseable metadata via `git interpret-trailers` and `%(trailers)` format |
| commitlint + husky/lefthook | JS/YAML tooling | Enforces message structure via git hooks |
| commitizen | Interactive CLI | Walks developers through structured commit writing |
| git-cliff | Rust binary | Generates changelogs from structured commits |
| ADR (Architecture Decision Records) | Michael Nygard, 2011 | Numbered decision documents in-repo, linked to commits via trailers |
| "My favourite Git commit" (David Thompson) | Blog post, 2019 | Viral example of a GOV.UK commit that documents full reasoning chain |

### Key finding
No purpose-built "AI-readable git history" tool exists. Teams that follow kernel-style conventions with structured bodies and trailers already produce history that AI agents parse well. **The structure is the feature.**

### Quotes worth remembering
- Tim Pope: *"The code tells you how; the commit message tells you why."*
- Chris Beams (7 rules): *"Use the body to explain what and why vs. how."*
- Angular docs: *"The body should include the motivation for the change and contrast this with previous behavior."*

---

## Commit Convention

### Narrative vs. mechanical commits

This convention is based on intent, not just type.

**Narrative commits** preserve the durable story of meaningful work. They
explain the problem, decision, tradeoff, and evidence. These commits require a
body and `Reason:` trailer.

**Mechanical-only commits** are changes where no meaningful product,
architecture, process, or test-strategy decision was made. Examples:
lockfile refreshes, formatting-only changes, generated file refreshes, typo-only
docs edits, or pure version bumps. These commits may stay terse.

`feat`, `fix`, `refactor`, and `perf` are always narrative. `test`, `docs`,
`chore`, `ci`, and `build` can be mechanical-only only when unscoped. Adding a
scope to a lightweight type marks it as narrative and opts into the body and
`Reason:` trailer requirement.

### Format

```
<type>(<scope>): <subject — imperative mood, ≤72 chars>

<body — explain WHY, not just WHAT. 1-3 sentences minimum.
Describe the problem or need, the decision/approach chosen, the
tradeoff or rejected alternative when relevant, and the verification
evidence. Wrap at 72 characters.>

[optional explicit body shape]
Problem: <what forced the change>
Decision: <what changed and why this approach was chosen>
Tradeoff: <what was rejected or accepted>
Evidence: <tests, device proof, reproduction, review, logs>

Reason: <one-line motivation — the forcing function>
Decision: <optional one-line durable choice>
Tradeoff: <optional one-line accepted/rejected tradeoff>
Evidence: <optional test/device/review evidence>
Follow-up: <optional known remaining work>
Refs: #<issue> | ADR-<number> | <url>
BREAKING CHANGE: <description if applicable>
```

### Rules by commit type

| Type | Narrative required? | Body required? | `Reason:` required? | Scope required? | When to use |
|------|---------------------|----------------|---------------------|-----------------|-------------|
| `feat` | Always | Yes | Yes | Yes | New capability |
| `fix` | Always | Yes | Yes | Yes | Bug fix |
| `refactor` | Always | Yes | Yes | Yes | Structural change, no behavior change |
| `perf` | Always | Yes | Yes | Yes | Performance improvement |
| `test` | When scoped | When scoped | When scoped | No | Test additions/changes |
| `docs` | When scoped | When scoped | When scoped | No | Documentation only |
| `chore` | When scoped | When scoped | When scoped | No | Build, deps, config, process |
| `ci` | When scoped | When scoped | When scoped | No | CI/CD changes |
| `build` | When scoped | When scoped | When scoped | No | Build system changes |

Mechanical-only examples that can stay terse:

```
chore: update dependency lockfile
docs: fix typo in setup note
build: regenerate plugin registrant
```

Non-mechanical examples that should use narrative form even though the type is
normally lightweight:

```
chore(git): add narrative commit enforcement hook
test(sync): lock cursor reset behavior after reassignment
docs(sync): document assignment-scoped pull cursor contract
ci(lints): block direct sync status mutation in quality gate
```

### Scope enforcement

Scopes are **enforced but extensible**. The hook validates any provided scope against a one-scope-per-line file at `scripts/git/valid-scopes.txt`. To add a new scope, add it to this file in the same commit that introduces the new area. This prevents typos and drift without being a bottleneck.

**Initial scope list:**
```
auth
calculator
ci
core
dashboard
database
deps
docs
entries
forms
git
lints
pay-applications
pdf
projects
quantities
router
scripts
shared
sync
tests
tooling
```

### Examples

**Full narrative commit (feat/fix/refactor/perf and non-mechanical work):**

```
fix(sync): clear assignment-scoped pull cursors on enrollment change

When a driver is re-enrolled to a different project, stale cursors from
the previous assignment cause the sync engine to skip records that should
be pulled. Clearing cursors on enrollment change forces a full re-pull
scoped to the new assignment.

Considered resetting all cursors globally, but that would re-download
unchanged data for unaffected tables.

Reason: field-reported data loss after project reassignment
Evidence: targeted sync cursor regression test plus S21 reassignment proof
Refs: #287
```

**Narrative lightweight commit (non-mechanical test/docs/chore/ci/build):**

```
chore(git): add narrative commit enforcement hook

Agent handoffs keep losing the rationale behind completed work once
the active state file rolls forward. Enforcing narrative bodies and
trailers makes git history the durable source for committed decisions
without adding another documentation stream.

Reason: preserve codebase decision context in the history agents already read
Decision: use a repo-local commit-msg hook instead of a separate Claude hook
Tradeoff: local hook setup is per-clone, but it applies to every commit source
```

**Mechanical-only commit:**

```
chore: update dependency lockfile
```

---

## Enforcement Mechanism

### Approach: Git `commit-msg` hook

A single git `commit-msg` hook fires on every commit regardless of source (Claude Code, manual, IDE). No separate Claude Code hook needed.

### File locations

| File | Purpose |
|------|---------|
| `scripts/git/commit-msg` | Hook script (tracked in repo) |
| `scripts/git/valid-scopes.txt` | Extensible scope allowlist (tracked in repo) |
| `.git/hooks/commit-msg` | Symlink or copy of the above (not tracked, one-time setup) |

### Hook validation rules

1. **Subject format**: Must match `<type>(<scope>): <description>` or `<type>: <description>`
2. **Valid types**: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `ci`, `build`
3. **Scope required** for substantive types (`feat`, `fix`, `refactor`, `perf`)
4. **Scope validated** against `scripts/git/valid-scopes.txt` for every scoped commit, including lightweight types
5. **Body required** for narrative commits: substantive types plus scoped lightweight commits (min 20 non-whitespace chars, excluding comments and trailers)
6. **`Reason:` trailer required** for narrative commits and parsed as a real git trailer via `git interpret-trailers`
7. **Subject length warning** if >72 chars (warning, not rejection)
8. **Passthrough** for merge commits and Git-generated reverts
9. **Passthrough** for `fixup!` and `squash!` autosquash commits during local rebase workflows
10. **Scoped lightweight commits are narrative** and require body plus `Reason:` trailer

### Setup

```bash
cp scripts/git/commit-msg .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg
git config commit.template .gitmessage
```

On Windows, copying the hook is the default setup path. A symlink is acceptable
only when the local clone and Git configuration support it reliably.

---

## CLAUDE.md Rules

Add a `## Git Commits` section:

```markdown
## Git Commits

- Treat commit history as the durable narrative layer for committed decisions.
- Active state files track in-progress work; git history preserves lasting intent.
- Follow Conventional Commits: `<type>(<scope>): <subject>`
- Valid types: feat, fix, refactor, perf, test, docs, chore, ci, build
- Scopes are enforced — see `scripts/git/valid-scopes.txt` for the current list
- Scope is required for feat, fix, refactor, perf commits
- Subject line: imperative mood, ≤72 chars, no period
- **Body required** for feat, fix, refactor, perf
- **Body required** for any scoped test, docs, chore, ci, or build commit
- Mechanical-only lightweight commits may stay unscoped and terse only when no meaningful product, architecture, process, or test-strategy decision was made
- Body explains WHY: problem/need → decision/approach → tradeoff → evidence
- **`Reason:` trailer required** for narrative commits — one-line forcing function parsed as a real git trailer
- Optional trailers: `Decision:`, `Tradeoff:`, `Evidence:`, `Follow-up:`, `Refs:`
- Wrap body at 72 characters
```

Add a compact pointer in `.codex/AGENTS.md` as well so Codex follows the same
durable-history convention directly instead of relying on Claude-only context.

---

## Commit Message Template

`.gitmessage` at repo root:

```
# <type>(<scope>): <subject — imperative mood, ≤72 chars>
#
# Types: feat | fix | refactor | perf | test | docs | chore | ci | build
# Scopes: see scripts/git/valid-scopes.txt
#
# --- NARRATIVE BODY ---
# Required for feat/fix/refactor/perf.
# Required for scoped test/docs/chore/ci/build commits.
# Mechanical-only lightweight commits can stay unscoped and terse only when no meaningful decision was made.
#
# Problem: What forced this change?
# Decision: What approach was chosen and why?
# Tradeoff: What was rejected or accepted?
# Evidence: What proves the change is credible? Tests, device proof, logs, review?
#
# --- TRAILERS ---
# Reason: <one-line forcing function — required for narrative commits>
# Decision: <optional one-line durable choice>
# Tradeoff: <optional one-line accepted/rejected tradeoff>
# Evidence: <optional test/device/review evidence>
# Follow-up: <optional known remaining work>
# Refs: #<issue> | ADR-<number>
# BREAKING CHANGE: <if applicable>
```

---

## Queryability

Once in place, the history becomes a searchable knowledge base:

```bash
# All reasons behind sync changes
git log --all --grep="Reason:" -- lib/core/sync/ --format="%h %s%n%(trailers:key=Reason)%n"

# Why did this file change?
git log --follow --format="%h %s%n%b%n---" -- lib/core/database/database_service.dart

# All architectural decisions
git log --grep="^feat\|^refactor" --format="%h %s%n%b%n---" -20

# AI agent context dump
git log --format="%h %s%n%b%n%(trailers)%n---" -30
```

---

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `scripts/git/commit-msg` | Create | Hook validation script |
| `scripts/git/valid-scopes.txt` | Create | Extensible scope allowlist |
| `.gitmessage` | Create | Commit message template |
| `.claude/CLAUDE.md` | Edit | Add Git Commits convention section |
| `.codex/AGENTS.md` | Edit | Add compact Git Commits pointer for Codex agents |

---

## Verification Plan

| Test | Input | Expected |
|------|-------|----------|
| Missing body on feat | `feat(sync): add thing` (no body) | Rejected: "body explaining WHY" |
| Missing Reason on fix | `fix(sync): fix thing` + body, no trailer | Rejected: "Reason: trailer" |
| Unknown scope | `feat(badscope): add thing` | Rejected: "Unknown scope" |
| Unknown lightweight scope | `docs(gitt): update convention` | Rejected: "Unknown scope" |
| Missing scope on refactor | `refactor: rename thing` | Rejected: "require a scope" |
| Valid chore, no body | `chore: update deps` | Passes |
| Valid narrative chore | `chore(git): add narrative commit hook` + body + `Reason:` | Passes |
| Scoped test without Reason | `test(forms): add coverage` + body, no trailer | Rejected: "Reason: trailer" |
| Valid scoped test | `test(forms): add coverage` + body + `Reason:` | Passes |
| Full valid feat | subject + body + `Reason:` + valid scope | Passes |
| Merge commit | `Merge branch 'main'` | Passes (passthrough) |
| Git-generated revert | `Revert "fix(sync): clear pull cursor"` | Passes (passthrough) |
| Autosquash fixup | `fixup! fix(sync): clear pull cursor` | Passes (passthrough) |
| Loose Reason text only | Body mentions `Reason:` outside trailer block | Rejected for narrative commits |

---

## Decisions Made During Brainstorm

1. **Scopes: enforced but extensible** — validated against `scripts/git/valid-scopes.txt`, easy to add new scopes in the same commit.
2. **`Reason:` trailer: required (hard reject)** — AI agents skip optional things; the whole point is to force rationale capture.
3. **Hook delivery: git `commit-msg` hook only** — fires on all commits regardless of source. No separate Claude Code hook needed.
4. **No retroactive rewriting** — apply going forward only.
5. **No external toolchain dependencies** — pure bash hook, no Node/Python/Rust tools needed.
6. **Git history becomes the durable intent layer** — active state files still track in-progress work, but committed decisions should live with the commits that made them.
7. **Narrative vs. mechanical is the real split** — `feat`, `fix`, `refactor`, and `perf` are always narrative; lightweight types are exempt only when unscoped and genuinely mechanical.
8. **Scopes validate whenever present** — a typo in `docs(gitt)` should fail just like a typo in `fix(snyc)`.
9. **Windows setup uses copy by default** — hook symlinks are allowed only when the local clone supports them reliably.
