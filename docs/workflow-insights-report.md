# Field Guide App: Comprehensive Workflow Insights Report

**Date**: 2026-03-22
**Analysis Scope**: Sessions S193-S622, 61 days (Jan 19 - Mar 22, 2026)
**Methodology**: 27-agent analysis (9 Sonnet mapping + 9 Opus analysis + 9 Opus verification)
**Branch**: `feat/sync-engine-rewrite`

---

## Executive Summary

The Field Guide App is an offline-first Flutter construction inspector tool spanning 17 features, orchestrated through 10 agents and 11 skills. Over 61 days of development (430+ sessions), the project achieved several notable milestones: the PDF pipeline reached 131/131 exact-match accuracy through a sustained 55-session effort, a full multi-tenant architecture was designed and implemented in a single marathon day (14 sessions), the sync engine underwent a ground-up rewrite, and end-to-end test coverage reached 86%.

However, the analysis reveals significant risks. The sync branch has diverged 111 commits over 17 days with no merge to main, creating an escalating integration risk. Five confirmed constraint violations were found across the codebase, and 40 defects remain open across feature-specific defect files. The test infrastructure itself was rewritten three times in 16 days, indicating architectural uncertainty in that area.

Process maturity scores at 3.25 out of 5. Documentation practices are excellent — session state files, defect tracking, plan archives, and memory files create a comprehensive knowledge base. But enforcement is entirely manual. No pre-commit hooks validate architecture rules, no CI checks enforce the documented constraints, and no automated gate prevents the patterns that the defect files catalog.

The defining insight of this analysis: the project captures knowledge exceptionally well but enforces none of it at commit time. Every constraint violation found was already documented as a rule — it simply was not checked automatically.

---

## 1. Project Timeline & Velocity

### 1.1 Session History Overview

- 430+ sessions (S193-S622) across 61 days
- Session distribution: ~90 PDF, ~35 sync, ~25 testing, ~20 auth, ~20 0582B/calculator, ~15 project management, ~15 dev infrastructure
- Marathon days: Feb 22 (14 sessions, multi-tenant arch), Mar 21 (10 sessions, E2E bug iteration)
- 22 stub sessions (6.5%) with no productive work

### 1.2 Velocity Analysis (VERIFIED)

- App repo: 567 commits total
  - January: 265 commits (8.55/day) — greenfield buildout
  - February: 169 commits (6.04/day) — stabilized
  - March (22 days): 133 commits (6.05/day) — stable
- .claude repo: 431 commits, but 79% (340) are state file noise
- Velocity is STABLE at 6.0/day (Feb-Mar), not declining
- REFUTED CLAIM: fix:feat ratio was claimed to improve from 0.45 to 0.26 but actual ratio barely changed (0.53 to 0.51)

### 1.3 Feature Time-to-Completion

| Feature | Duration | Sessions |
|---------|----------|----------|
| Multi-tenant auth | ~1 day (marathon) | S444-S456 (14) |
| 0582B form redesign | ~2 days | S424-S443 (8) |
| Project lifecycle | <1 day | S581-S582 (2) |
| PDF OCR accuracy (0 to 131) | ~30 days | ~55 sessions |
| Sync engine rewrite | 18+ days (ongoing) | ~30 sessions |
| E2E testing system | 19+ days | ~20 sessions |

### 1.4 Rework & Regression Analysis

- Marionette UI testing: adopted Feb 19, abandoned Feb 20 (~8 sessions, partial salvage value from bug findings)
- hookify plugin: 44 files built then entirely deleted
- Test system: 3 complete rewrites in 16 days (ADB to HTTP driver+orchestrator to no-agent direct)
- PDF accuracy death march: 55+ sessions, but progression was monotonic (each session improved accuracy)
- 113 plan files deleted (47% of all created) — mostly pre-pipeline era; post-pipeline deletion rate is near-zero

---

## 2. Tool Usage & Error Patterns

### 2.1 Tool Distribution (from 336 sessions)

| Tool | Count | Notes |
|------|-------|-------|
| Read | 1,532 | Dominant — plan/state loading |
| Task | 1,433 | Heavy agent orchestration |
| Bash | 1,094 | Always via pwsh wrapper |
| TodoWrite | 278 | Internal task tracking |
| Grep | 277 | Code search |
| Edit | 188 | File edits |
| TaskOutput | 169 | Polling async agents |
| Glob | 167 | File discovery |
| AskUserQuestion | 128 | Approval gates |
| CodeMunch MCP | 201 | Dependency graphs |
| Skill | 97 | 39 implement, 19 writing-plans, 11 debug, 10 test, 7 brainstorm |
| Write | 89 | File creation |

### 2.2 Read:Edit Ratio (8:1) — VERIFIED HEALTHY

The 8:1 ratio is structurally sound, driven by:
- Orchestrator and review agents are read-only by design
- writing-plans skill pre-reads all symbols for subagent prompts
- ~39 reads per implement invocation is consistent with plan + source files + reviews

### 2.3 Error Categories (by session count)

| Error | Sessions | Root Cause | Preventable? |
|-------|----------|------------|--------------|
| Output Too Large | 69 | Tool limitation on large outputs | Partially — scope flutter analyze to changed files |
| Request Interrupted | 64 | User redirecting approach | No — intentional correction |
| Exit Code 1 | 47 | PowerShell/Bash translation, expected test failures | Partially |
| File Too Large | 40 | 462KB+ plan files requiring chunked reads | Yes — split plans |
| Stale Checkpoints | ~39 | Persistent checkpoint between plan executions | Yes — auto-clear on plan mismatch |
| Driver Not Running | ~33 | Flutter driver needs fresh launch each session | Partially |
| Parallel Edit Conflicts | ~30-50 | Concurrent agents editing same file | Yes — file-lock in orchestrator |

### 2.4 Platform-Specific Issues (Windows + Git Bash + PowerShell)

- Git Bash silently fails on Flutter — requires pwsh wrapper (documented, still causes 47 Exit Code 1 errors)
- `tee` output buffering on Windows makes orchestrator progress invisible
- `Stop-Process -Name 'dart'` kills MCP servers (learned hard way, now documented as NEVER-DO)
- 120s default Bash timeout too short for Flutter builds (must use 600000ms)

### 2.5 CodeMunch MCP Assessment

- 201 total calls (get_file_outline: 118, search_symbols: 83)
- VALUE: Justified for writing-plans dependency graphs (10 calls vs ~40 Grep/Read equivalent)
- RISK: Single point of failure (session 559 hang). No fallback mode exists.
- VERDICT: Net positive but needs Grep/Glob fallback for resilience
## 3. Defect Landscape

### 3.1 Open Defect Summary (40 total across 15 features)

| Feature | Open | Severity Mix |
|---------|------|-------------|
| Projects | 7 | 2 BLOCKERS (UNIQUE constraint, FK violations), 1 orphaned draft, permission gaps |
| PDF | 6 | 3 high-impact OCR/grid, 2 DATA, 1 E2E |
| Auth | 5 | 1 SECURITY-BLOCKER (STALE — actually resolved), 2 DATA, 1 ASYNC, 1 CONFIG |
| Entries | 5 | 2 DATA (createdByUserId never set, firstWhere crash), 1 FLUTTER, 1 E2E, 1 DATA |
| Forms | 4 | 1 E2E, 1 FLUTTER, 2 MINOR |
| Database | 4 | 1 BLOCKER (singleton close()), 2 DATA, 1 CONFIG |
| Toolbox | 3 | 1 DATA, 2 FLUTTER |
| Quantities | 2 | Both DATA, 31 days old (neglected) |
| Photos | 2 | 1 ASYNC, 1 E2E |
| Settings | 2 | 2 CONFIG |
| Sync | 0 | All recently resolved in S614 batch |
| Contractors/Dashboard/Locations/Weather | 0 | Empty or defect-free |

Resolution rate: ~70% (40 open, ~95 resolved/archived)

### 3.2 Stale Defect Entries (VERIFIED)

Two defects currently tracked as open are actually resolved in the codebase:

1. **`secure_password_change = false`** (auth BLOCKER, filed Feb 28) — Actually `true` at `supabase/config.toml:207`. Defect tracker never updated.
2. **`PRAGMA foreign_keys never enabled`** (projects/database) — Actually enabled at `database_service.dart:61,83`. Code comment at `project_local_datasource.dart:112` is also stale.

### 3.3 Recurring Anti-Patterns (VERIFIED against source code)

| Pattern | Claim | Verified Count | Status |
|---------|-------|---------------|--------|
| `catch (_)` silent swallowing | "55+" | **55 across 28 files** | CONFIRMED |
| `.firstWhere` without `orElse` | "15 across 11 files" | **8 lack orElse** (7 have orElse but should use firstOrNull) | CORRECTED |
| Raw `db.delete()` bypassing soft-delete | "42 across 22 files" | **Inflated** — 83 `.delete()` matches but most are legitimate | CORRECTED |
| Schema drift (SQLite/Dart/Supabase) | Multiple defects | Multiple confirmed instances | CONFIRMED |
| TestingKeys defined but not wired | Recurring | Forms dialog buttons (Mar 21) | CONFIRMED |

### 3.4 Root Cause Taxonomy

| Category | % of Defects | Examples |
|----------|-------------|---------|
| Implementation errors | 45% | firstWhere, catch (_), createdByUserId never set |
| Integration/emergent | 23% | Provider not registered, singleton DB shared across isolates |
| Spec/design flaws | 15% | Toolbox "no persistence" constraint wrong, wrong root cause in spec |
| Plan stage errors | 10% | Wrong table names, wrong method signatures |
| Platform limitations | 7% | BackgroundIsolateBinaryMessenger, Flutter Driver dialog issue |

### 3.5 Defect Flow: Where Knowledge Breaks Down

The `.firstWhere` anti-pattern illustrates the systemic gap:

1. Documented in `rules/architecture.md:129` — loads on every `lib/**/*.dart` session
2. Filed as defect in January 2026, re-filed March 2026
3. 33 instances use the safe `.firstOrNull` pattern (rule IS followed sometimes)
4. 8 instances still violate (all in PDF extraction model deserialization)
5. No lint rule, no pre-commit hook, no CI gate blocks the violation
6. Code review agents do not systematically scan for documented anti-patterns

---

## 4. Constraint Violations (5 Confirmed, 2 Refuted)

### 4.1 Confirmed Violations

**V1: Sync Retry Count (HARD RULE)**
- Constraint: `sync-constraints.md:8` — "max 3 attempts per operation"
- Implementation: `sync_config.dart:7` — `maxRetryCount = 5`
- Impact: Two different retry semantics (orchestrator 3x, engine 5x), neither documented in constraints

**V2: Toolbox Persistence (HARD RULE)**
- Constraint: `toolbox-constraints.md:35-37` — "No data persistence required", "Forms are ephemeral"
- Implementation: 4 persistent tables (`inspector_forms`, `form_responses`, `todo_items`, `calculation_history`) with full CRUD, sync, indexes
- Note: Claimed "7 tables" was corrected to 4

**V3: Sync SHA256 Checksum (HARD RULE)**
- Constraint: `sync-constraints.md:6` — "MUST validate checksum (SHA256) on all synced records"
- Implementation: Uses djb2 hash, not SHA256. Checksum comparison explicitly skipped. Zero `sha256` references in sync code.

**V4: Entry State Reversal (HARD RULE)**
- Constraint: `entries-constraints.md:20-21` — "No reverting COMPLETE or SUBMITTED to DRAFT", "one-way transitions"
- Implementation: `daily_entry_repository.dart:233-250` implements `undoSubmission()` reverting SUBMITTED→DRAFT, with UI button in `submitted_banner.dart:54`

**V5: Raw SQL from Presentation Layer (MANDATORY RULE)**
- Constraint: `data-validation-rules.md:29` — "No raw SQL in Dart code — use repository pattern exclusively"
- Implementation: `project_setup_screen.dart` has 6 direct `db.execute()`/`db.delete()` calls from presentation layer (lines 122, 126, 361, 366-371)

### 4.2 Refuted Violations

**NOT V6: Settings PII in SharedPreferences**
- Claimed PII (inspector name, phone, cert number) stored in SharedPreferences
- Verified: PII already migrated to auth system. `PreferencesService` stores only app settings (theme, gauge_number, navigation state)

**NOT V7: Projects Archive/Unarchive Reverting State**
- Claimed archive/unarchive violates "no reverting project state" constraint
- Verified: `toggleActive()` uses a separate `isActive` boolean flag, NOT the lifecycle state machine (PLANNING→ACTIVE→COMPLETE→ARCHIVED)

---

## 5. Planning Pipeline Analysis

### 5.1 Pipeline Structure

```
brainstorming → spec (adversarial review) → writing-plans (code+security review) → implement
```

### 5.2 Pipeline Effectiveness (VERIFIED)

| Domain | Specs | Plans | Implemented | Rate |
|--------|-------|-------|-------------|------|
| App/Sync | 9 | 9 | 8 | 89% |
| PDF/OCR | 7 | ~2 | ~2 | 29% |
| Testing/DX | 3 | 3 | 3 | 100% |
| **Overall** | **19** | **14** | **13** | **68%** |

### 5.3 Pipeline ROI (PARTIALLY VERIFIED)

- Investment: ~40-60 hours in pipeline overhead
- Bugs caught pre-implementation: 12 security, 8 architectural, ~50 medium-severity
- Highest-value catch: Bug triage adversarial review found WRONG ROOT CAUSE in spec — would have shipped a no-op fix
- ROI estimate: ~3:1 (lower bound defensible, upper bound 7:1 is speculative)

### 5.4 Pipeline Bottlenecks

1. **PDF/OCR specs stall** — 5 of 7 never reached plan stage. Research work needs a different process.
2. **Wrong code targets in 40% of reviews** — Specs reference phantom tables, wrong method signatures, wrong file paths. Specs are written from memory, not verified against codebase.
3. **Every plan gets REJECT before APPROVE** — Adds a full iteration cycle. ~40% of findings are wrong-code-target errors that could be caught earlier.
4. **No lightweight path** — Binary choice: full pipeline or ad-hoc. No process for XS/S changes.
5. **Spec-writing outpaces implementation** — 1.3 specs/day vs slower implementation velocity.

### 5.5 Review Finding Patterns

| Category | Frequency | Impact |
|----------|-----------|--------|
| Wrong code targets (phantom tables, wrong signatures) | 40% of reviews | Wastes reviewer cycles |
| Security gaps (assert() in release, spoofable fields, missing RLS) | Every review | Prevents production vulnerabilities |
| Race conditions and ordering bugs | 60% of sync reviews | Prevents data corruption |
| Missing scope sections | Common | Prevents incomplete implementations |
| Wrong architecture / deadlocks | Infrastructure reviews | Prevents production crashes |
## 6. Configuration Health

### 6.1 Staleness Audit Summary
| Status | Count | % |
|--------|-------|---|
| CURRENT | 19 files | 50% |
| STALE | 16 files | 42% |
| CRITICALLY-STALE | 3 files | 8% |

**CRITICALLY-STALE (P0):**
- `implement-orchestrator.md:89` — checkpoint-writer uses `model: haiku` (violates "sonnet minimum" preference)
- `implement/skill.md` — inherits the haiku violation
- `sync-constraints.md:8` — says "max 3 retries" but code uses 5

**STALE items by category:**
- 11 `debugPrint` instances across 5 rules files (should be `Logger.*()`)
- 15 `supabase` commands without `npx` prefix in backend-supabase-agent.md
- 5 files say "13 features" (should be 17)
- 2 files say "9 agents" (should be 10)
- 7 `[BRANCH: feat/sync-engine-rewrite]` annotations in sync-patterns.md (will stale after merge)
- 6 bare `flutter`/`dart` commands without `pwsh -Command` wrapper in rules

**Estimated remediation: ~4 hours**

### 6.2 Agent Memory Health
| Agent | Memory Size | Quality |
|-------|-----------|---------|
| code-review-agent | 8,183 bytes | Excellent — 7 patterns, 5 arch decisions, 8 gotchas |
| pdf-agent | 11,362 bytes | Excellent — PSM patterns, OCR quirks, scorecard baseline |
| qa-testing-agent | 6,575 bytes | Excellent — test patterns, baselines, gotchas |
| security-agent | 2,235 bytes | Good — baseline audit, CVEs, file references |
| frontend-flutter-specialist | 921 bytes | Minimal but relevant |
| **backend-supabase-agent** | **134 bytes** | **EMPTY** — template headers only |
| **auth-agent** | **134 bytes** | **EMPTY** — template headers only |
| **backend-data-layer-agent** | **148 bytes** | **EMPTY** — template headers only |

The 3 empty memories are the most-used data-path agents. Estimated cost: 15-25 minutes wasted per session on rediscovery.

### 6.3 Cross-Reference Integrity
- CLAUDE.md outbound references: All valid except agent count (says 9, actual 10)
- Agent → rules references: All valid
- Agent → memory paths: All exist (3 empty)
- Orphaned files: `skills/test/references/output-format.md` (227 lines, not referenced by active config)
- `.gitignore` critical bug: patterns cover `test-results/` (hyphen) but actual dir is `test_results/` (underscore)
- Hooks: `block-orchestrator-writes.sh` uses `grep -oP` (Perl regex) — may not work on Windows Git Bash

### 6.4 Repository Health
- Total size: **46 MB** (23 MB working tree + 24 MB .git/) — corrected from original 70 MB claim
- test_results/: 17 MB, 285 files, growing unsustainably (projected 150 MB in 3 months)
- plans/completed/: 101 files, write-once read-never, no retention policy
- 79% of commits (340/431) are state file updates — pure noise
- Commit velocity declining in .claude repo (226→143→62/month) — healthy stabilization

---

## 7. Architecture Evolution

### 7.1 Stability Assessment
**STABLE decisions** (made once, never changed): Feature-first directory structure, Provider+ChangeNotifier, go_router, SQLite local-first, Supabase backend, CLAUDE.md pointer-only design, per-feature defect files, rules with paths: frontmatter

**UNSTABLE decisions** (changed 2+ times): Test infrastructure (3 generations, 16 days), implement skill architecture (changed within 2 days), systematic debugging (8 commits, 3 rewrites), agent directory structure (restructured twice), planning pipeline (agent→skill triad)

**Key insight**: App architecture is rock-stable. ALL instability is in the Claude meta-layer (how Claude is configured to work on the app). Decisions depending on Claude's runtime capabilities are unstable; decisions mapping to application domain are stable.

### 7.2 Churn Cost
- Test infrastructure: ~7-9 sessions, of which 3-4 were pure waste on orchestration layers deleted
- Implement skill: ~4 sessions, ~2 were waste (subagent→CLI forced by capability limitation)
- hookify: ~3-5 sessions, 44 files built and deleted
- Total churn waste: ~8-12 sessions (~8-24 hours)
- Root cause: Architecture committed before testing core capability assumptions

### 7.3 CLAUDE.md Design
- Peak: 243 lines → Current: 108 lines (leanest ever)
- Pointer-based design is optimal for context efficiency
- All pointer targets verified to exist
- Risk: discoverability — context only loads when explicitly requested

---

## 8. Process Maturity Assessment

### 8.1 Maturity Scores (Verified & Adjusted)
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Planning Discipline | 4.0/5 | Strong pipeline with adversarial reviews. Bottleneck on PDF/research work. |
| Code Review Effectiveness | 3.5/5 | Catches real bugs. Does not enforce anti-pattern tables from defect files. |
| Defect Management | 4.0/5 | Well-structured per-feature tracking. Stale entries persist (2 confirmed). |
| Testing Coverage | 3.0/5 | 41% file ratio (230 test/562 source). E2E at 86%. No CI. |
| Security Posture | 3.0/5 | Strong review process. Unencrypted SQLite, no pre-commit security gates. |
| Configuration Management | 3.0/5 | 42% stale files. 79% commit noise. .gitignore bug. |
| Knowledge Retention | 3.0/5 | Rules documented but not enforced. 3 empty agent memories. Anti-patterns recur. |
| Developer Experience | 3.5/5 | Impressive tooling. Windows friction. Heavy pipeline for small changes. |
| **Overall** | **3.25/5** | |

### 8.2 Comparison to Best Practices
**Exceeds** for solo developer with AI:
- Adversarial review rigor (most solo projects have none)
- Security agent with OWASP coverage
- Per-feature defect tracking
- Session state management

**Below** best practices:
- No CI/CD pipeline (standard even for solo projects)
- No automated anti-pattern enforcement
- No branch protection or automated test gate
- No SQLite encryption for offline-first app with PII

---

## 9. Verified Optimization Roadmap

### 9.1 Immediate (Zero Risk, This Session)
| # | Action | Impact |
|---|--------|--------|
| 1 | Fix `.gitignore`: add `test_results/` (underscore) | Stops 17MB binary bloat |
| 2 | Gitignore `autoload/_state.md` and `state/*.json` | Eliminates 79% commit noise |
| 3 | Fix haiku→sonnet in `implement-orchestrator.md:89` | User preference compliance |
| 4 | Mark 2 stale defects as RESOLVED | Prevents wasted investigation |
| 5 | Fix CLAUDE.md: "9 agents" → "10 agents" | Accuracy |

### 9.2 This Sprint (High Confidence, Verified Feasible)
| # | Action | Impact | Feasibility |
|---|--------|--------|-------------|
| 6 | Create `/spike` skill for PDF/OCR research | Unblocks 5 stalled specs | FEASIBLE |
| 7 | Add code verification pass to brainstorming | Eliminates 40% REJECT cycles | FEASIBLE |
| 8 | Fold checkpoint-writer into last reviewer | Eliminates haiku dispatches | FEASIBLE |
| 9 | Populate 3 empty agent memories | Saves 15-25 min/session | FEASIBLE |
| 10 | Reconcile 5 constraint violations | Aligns docs with code | FEASIBLE |
| 11 | Update 11 debugPrint→Logger in rules | Correct agent guidance | FEASIBLE |
| 12 | Update 15 supabase→npx supabase in agent | Correct CLI instructions | FEASIBLE |

### 9.3 This Month (Strategic, Requires Design)
| # | Action | Impact | Feasibility |
|---|--------|--------|-------------|
| 13 | Merge sync branch (111 commits, 17 days) | Reduces merge risk | Requires testing |
| 14 | Lightweight process path for XS/S changes | Unblocks 40% of work | Requires careful design (brainstorming hard-gate) |
| 15 | Pre-commit grep hook for anti-patterns | Automated enforcement | Moderate (PowerShell-based for Windows) |
| 16 | Tiered review mode | Reduce review overhead ~30% | Moderate |
| 17 | SQLite encryption (sqlcipher) | Production readiness | Significant (not drop-in, needs migration + key mgmt) |
| 18 | GitHub Actions CI | Automated test + lint gate | Moderate |

### 9.4 Refuted/Adjusted Optimizations
| Original Claim | Verdict | Correction |
|---------------|---------|------------|
| Persistent driver saves 2-3 hours | INFLATED | Saves minutes — app needs rebuild after code changes |
| Slim plan format saves 2-3 hours | INFLATED | Real benefit is context efficiency, not read time |
| flutter-cmd.sh wrapper | NOT FEASIBLE | Root cause is agent non-compliance, not missing wrapper |
| Dart custom lint rules | NOT FEASIBLE | Anti-patterns are in agent prompts, not Dart source code |
| Checkpoint-writer saves 100 min | INFLATED | Saves 10-20 min/plan, not 100 min total |
| SQLite encryption is "drop-in" | INFLATED | Requires migration strategy, key management, cross-platform testing |

---

## 10. Contradictions Resolved

The verification wave found 2 true contradictions between analysis reports:

1. **secure_password_change**: Defect tracker says BLOCKER (23 days open). Actual code says RESOLVED (`config.toml:207 = true`). **Resolution**: Defect tracker is stale.

2. **PRAGMA foreign_keys**: One report says "never enabled." Actual code has `PRAGMA foreign_keys=ON` at `database_service.dart:61,83`. **Resolution**: Report that checked source files is correct.

Both favor reports that verified claims against actual source code over reports that relied on stale documentation.

---

## 11. The Defining Insight

> **The project has built world-class knowledge documentation but has zero automated enforcement.**

Anti-patterns are documented in rules, filed in defects, tracked in agent memories — yet they persist in code because no lint rule, pre-commit hook, or CI gate actually blocks them. The `.firstWhere` anti-pattern was documented in January 2026 and still has 8 violations in March 2026.

The fix is not more documentation — it is automation:
- Pre-commit grep hooks that block known anti-patterns
- CI gates that run `flutter analyze` + `flutter test` on every push
- `.gitignore` corrections that prevent accidental binary commits
- Agent memory population that prevents cold-start rediscovery

The single highest-leverage transformation is closing the loop from **"knowledge captured"** to **"knowledge enforced at commit time."**

---

*Report generated 2026-03-22 by 27-agent analysis (9 Sonnet mapping + 9 Opus analysis + 9 Opus verification)*
