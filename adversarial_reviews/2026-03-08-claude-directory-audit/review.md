# Adversarial Review: .claude/ Directory Baseline Audit & Cleanup

**Spec**: `.claude/specs/2026-03-08-claude-directory-audit-spec.md`
**Date**: 2026-03-08
**Reviewers**: code-review-agent, security-agent

---

## Code Review Findings

### MUST-FIX (5)

1. **Branch ambiguity** — Spec didn't define whether to audit against `feat/sync-engine-rewrite` or `main`. **RESOLVED**: Branch policy added — feature branch is truth.

2. **PRD count wrong** — Spec said 15, reality is 14 files. **RESOLVED**: Count corrected to 14.

3. **Agent orphan mismatch** — Spec cited `test-orchestrator-agent/` as orphan but it doesn't exist. Real issues: `test-wave-agent` missing from CLAUDE.md, no memory dir for it. **RESOLVED**: Added to Known Issues.

4. **Missing directories** — 7+ directories with codebase references not assigned to any agent: `docs/guides/`, `docs/` root, `hooks/`, `autoload/`, `memory/`, `defects/`. **RESOLVED**: Added Agent #10 (CLAUDE.md + Misc Config) and Agent #11 (Defects).

5. **Skill count** — `test` skill missing from CLAUDE.md table. **RESOLVED**: Added to Known Issues for Agent #10.

### SHOULD-CONSIDER (7)

1. **Workload imbalance** — Agents #2, #7, #9 significantly heavier than #3, #5, #8. **PARTIALLY ADDRESSED**: CLAUDE.md moved to dedicated Agent #10, Rules standalone.
2. **CLAUDE.md write conflict** — 3 agents needed to modify it. **RESOLVED**: Single owner Agent #10.
3. **Feature count inconsistency** — 13 vs 17 discrepancy. **RESOLVED**: Convention defined in scope.
4. **docs/ root files unassigned** — **RESOLVED**: Added to Agent #10.
5. **CodeMunch single point of failure** — **RESOLVED**: Fallback defined.
6. **No rollback plan** — **RESOLVED**: Phase 0 added.
7. **Defect file:line references** — **RESOLVED**: Agent #11 handles path fixes only.

### NICE-TO-HAVE (6)

1. `plans/sections/` neither included nor excluded → **Excluded** (forward-looking plans).
2. `pdf-agent` memory has extra file `stage-4c-implementation.md` → **Noted** in Known Issues.
3. `docs/INDEX.md` stale (says 30 files, actual ~39) → Agent #10 scope.
4. `/audit-config` skill could reuse mapper logic → **Noted** for skill builder.
5. `outputs/` directory is ephemeral → **Noted**, added .gitignore recommendation.
6. `docs/guides/README.md` and `docs/features/README.md` unassigned → Agent #3 and #10 respectively.

---

## Security Review Findings

### MUST-FIX (5)

1. **MF-1**: Agent #6 can modify security-agent `disallowedTools` → privilege escalation. **RESOLVED**: Security Invariants section — agent capability fields are OUT OF SCOPE.

2. **MF-2**: Agent #7 can weaken security directives in rules and CLAUDE.md. **RESOLVED**: Security Invariants — normative security lines immutable, only file path refs fixable.

3. **MF-3**: Agent #8 can falsify `constraints_summary` and resolve `active_blockers`. **RESOLVED**: Security Invariants — constraints_summary immutable, active_blockers require code verification.

4. **MF-4**: Agent #5 can remove `MUST`/`MUST NOT` hard rules from constraints. **RESOLVED**: Security Invariants — hard rules immutable, only References sections fixable.

5. **MF-5**: Agent #6 can erase security-agent vulnerability history. **RESOLVED**: Security Invariants — findings immutable, only file paths within findings updatable.

### SHOULD-CONSIDER (5)

1. **SC-1**: No security verification in Phase 4. **RESOLVED**: Security invariant check added to Phase 4.
2. **SC-2**: `/audit-config` output exposes project structure. **RESOLVED**: Output marked ephemeral, .gitignore recommendation.
3. **SC-3**: Defect files not protected. **RESOLVED**: Agent #11 with path-only fixes, Security Invariants section.
4. **SC-4**: No per-agent commit isolation. **RESOLVED**: Each agent commits separately.
5. **SC-5**: `permissionMode` at risk. **RESOLVED**: Added to protected frontmatter fields.

### NICE-TO-HAVE (4)

1. **NTH-1**: Add security invariant checks to `/audit-config` skill. **ADOPTED**: Added to skill behavior.
2. **NTH-2**: Supabase project ID in agent file. **NOTED**: Low risk, not critical.
3. **NTH-3**: Verify orphans for security findings before deletion. **NOTED**: Added to cleanup process.
4. **NTH-4**: Seed empty auth-agent memory. **NOTED**: Deferred to future session.

---

## Resolution Status

| Category | Total | Resolved | Deferred |
|----------|-------|----------|----------|
| MUST-FIX | 10 | 10 | 0 |
| SHOULD-CONSIDER | 12 | 12 | 0 |
| NICE-TO-HAVE | 10 | 4 adopted | 6 noted |
