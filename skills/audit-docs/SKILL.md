---
description: "Deep semantic audit of .claude/ docs against the current codebase. Validates paths, class references, security invariants, and generates .claude/doc-drift-map.json."
---

# /audit-docs

One-command deep audit of `.claude/` configuration against the live codebase. Replaces the simpler `/audit-config`.

## Flags

- `--regen-map` — Skip phases 2-5 and jump directly to phase 6 (regenerate mapping only)

## Iron Law

This skill NEVER modifies security rules or architectural decisions. Auto-fixes are limited to reference updates (paths, class names). All other changes require user approval.

---

## Phase 1: Index

```
mcp__jcodemunch__index_folder(path: ".", use_ai_summaries: true, max_files: 2000)
```

Reuse existing index if < 1 hour old (check `mcp__jcodemunch__get_session_stats()`).

**Fallback**: If CodeMunch unavailable, use Glob + Grep + Read. Skip semantic analysis (phases 3 + 3.5) with warning.

---

## Phase 2: Structural Scan

1. `mcp__jcodemunch__get_file_tree(path: ".")` — get current codebase structure
2. Grep all `.claude/` files for explicit `lib/` paths — validate each against disk
3. `mcp__jcodemunch__search_symbols(query: "<className>")` for PascalCase class names found in docs
4. Check for renamed/moved files by searching for basename matches

**Output**: List of broken paths and stale class references with file:line locations.

---

## Phase 3: Semantic Analysis

For each rule file and agent definition:
1. `mcp__jcodemunch__get_class_hierarchy(class_name: "<name>")` — verify inheritance claims
2. `mcp__jcodemunch__get_file_outline(path: "<file>")` — verify method/property claims
3. `mcp__jcodemunch__find_dead_code()` — check for docs referencing removed code
4. `mcp__jcodemunch__get_blast_radius(symbol: "<name>")` — verify impact claims

**Skip if**: CodeMunch unavailable. Print `[WARN] Semantic analysis skipped — CodeMunch not available`.

---

## Phase 3.5: Pattern Discovery

1. **Convention deviation scan** — check if documented patterns (naming, structure) match actual codebase conventions
2. **Coupling scan** — verify documented dependency relationships against actual imports
3. **Guard clause scan** — find `// WHY:`, `// HACK:`, `// FROM SPEC:` comments that may need documentation
4. **Ordering dependency scan** — verify documented ordering constraints (e.g., tier ordering) against actual code

---

## Phase 4: Coverage Check

1. **Feature dir coverage** — every `lib/features/*/` dir should have matching rule coverage
2. **Agent `@` import validation** — verify `@.claude/` references in agent bodies resolve
3. **Agent model verification** — all agents must have `model: opus`
4. **Memory accuracy flags** — check `.claude/memory/` entries against current codebase state
5. **Routing table coverage** — verify worker-rules.md routing table covers all `lib/` subdirectories

---

## Phase 5: Security Invariants

These checks are **immutable** — they cannot be auto-fixed, only reported.

- [ ] `security-agent.md` has `disallowedTools: Write, Edit, Bash`
- [ ] `security-agent.md` body contains "NEVER MODIFY CODE. REPORT ONLY."
- [ ] CLAUDE.md contains "Security is non-negotiable"
- [ ] `sync-patterns.md` contains RLS sentinels (`rlsDenial`, `42501`)
- [ ] `supabase-auth.md` contains token storage sentinels (`flutter_secure_storage`, "Never log tokens")
- [ ] `supabase-sql.md` contains company-scoped RLS sentinel (`get_my_company_id`)
- [ ] All rule files with `paths:` frontmatter have valid glob patterns

---

## Phase 6: Regenerate Mapping

Build fresh `.claude/doc-drift-map.json` from scan results:

1. Read existing `.claude/doc-drift-map.json` (if present)
2. Rebuild `zones` from routing table + discovered patterns
3. Rebuild `path_references` by grepping `.claude/` docs for explicit `lib/` paths
4. Rebuild `global_checks` (new feature dirs, new agents/skills, workflow changes)
5. Write to `.claude/doc-drift-map.json`

If `--regen-map` flag: skip phases 2-5, jump here directly.

---

## Phase 7: Report + Gotcha Graduation

1. Save report to `.claude/outputs/audit-docs-report-YYYY-MM-DD.md`
2. Present summary to user
3. **Auto-fix offer** — reference updates only (broken paths, renamed classes). Never prose or architectural decisions.
4. **Gotcha graduation prompt** — for any undocumented patterns discovered in phase 3.5, ask user if they should be added to the appropriate rule file's Gotchas section.

### Report Format

```markdown
# Doc Drift Audit — YYYY-MM-DD

**Branch**: [current branch]
**Commit**: [commit hash]

## Summary
- Broken paths: [N]
- Stale class references: [N]
- Missing coverage: [N]
- Security invariants: [PASS/FAIL]
- Undocumented patterns: [N]

## Broken Paths
[file:line — broken reference — suggested fix]

## Stale References
[file:line — class name — status]

## Coverage Gaps
[feature dir — missing rule coverage]

## Security Invariants
[PASS/FAIL for each of 7 checks]

## Undocumented Patterns
[pattern — location — suggested gotcha text]

## .claude/doc-drift-map.json
[regenerated/unchanged — zone count — path_references count]
```

---

## Scope Exclusions

Not scanned:
- `logs/` (historical archives)
- `adversarial_reviews/` (historical reviews)
- `code-reviews/` (historical reviews)
- `test-results/` (historical test data)
- `backlogged-plans/` (future-looking)
- `plans/completed/` (historical plans)
- `plans/parts/` (in-progress plan fragments)
