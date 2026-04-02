---
name: tailor
description: "Runs CodeMunch research on a spec, discovers architectural patterns, verifies ground truth, and outputs a structured tailor directory. Prerequisite for writing-plans."
user-invocable: true
---

# Tailor

**Announce at start:** "I'm using the tailor skill to map the codebase for this spec."

## Architecture

```
Main Agent (has MCP access)
  ├─ Phase 1: Accept spec (read spec + adversarial review)
  ├─ Phase 2: CodeMunch research sequence (9 mandatory steps)
  ├─ Phase 3: Pattern discovery (architectural patterns + reusable methods)
  ├─ Phase 4: Ground truth verification (all literals vs codebase)
  ├─ Phase 5: Research agent gap-fill (Agent tool, read-only)
  ├─ Phase 6: Write output directory
  └─ Phase 7: Present summary
```

Only you (the main agent) can call MCP tools. Subagents in Phase 5 are read-only (Read, Grep, Glob).

---

## Your Workflow

### Phase 1: Accept Spec

1. User invokes `/tailor <spec-path>` (or prompted for path if not provided)
2. Do these in PARALLEL:
   - Read the spec file from `.claude/specs/`
   - Read the adversarial review from `.claude/adversarial_reviews/` if it exists
3. Derive the spec-slug from the filename (e.g., `2026-03-31-quality-gates` from `2026-03-31-quality-gates-spec.md`)
4. Create the output directory: `.claude/tailor/YYYY-MM-DD-<spec-slug>/`

### Phase 2: CodeMunch Research Sequence (PRESCRIBED)

All steps are MANDATORY except where noted. Run them in this order:

1. `mcp__jcodemunch__index_folder` on the project root with `incremental: true`, `use_ai_summaries: true`
2. `mcp__jcodemunch__get_file_outline` on EVERY file listed in the spec's "Files to Modify/Create" section — **SKIP** credential-bearing files (`.env*`, `**/google-services.json`, `**/GoogleService-Info.plist`, `**/supabase_config.dart`, any file matching `*secret*` or `*credential*`)
3. `mcp__jcodemunch__get_dependency_graph` for all key files identified in step 2
4. `mcp__jcodemunch__get_blast_radius` for all symbols being changed
5. `mcp__jcodemunch__find_importers` for all symbols being changed (who calls/imports this?)
6. `mcp__jcodemunch__get_class_hierarchy` for all classes involved in the change
7. `mcp__jcodemunch__find_dead_code` to identify cleanup targets
8. `mcp__jcodemunch__search_symbols` for every key symbol mentioned in the spec
9. `mcp__jcodemunch__get_symbol_source` to get full source of each relevant symbol — **SKIP** symbols from credential-bearing files (same blocklist as step 2)

**Optional** (use when additional context prioritization is needed):
10. `mcp__jcodemunch__get_ranked_context`
11. `mcp__jcodemunch__get_context_bundle`

**NOT used:** `index_repo` (fetches from GitHub — freezes), `get_repo_outline` (fetches from GitHub)

### Phase 3: Pattern Discovery

Analyze CodeMunch results to identify how our codebase implements common patterns. For each pattern discovered:

1. **Name and describe** the pattern in 2-3 sentences ("How we do it")
2. **Exemplars**: Include 1-2 real implementations with full source from `get_symbol_source`
3. **Reusable methods table**:

   | Method | File:Line | Signature | When to Use |
   |--------|-----------|-----------|-------------|
   | findById | entry_repository.dart:45 | `Future<Entry?> findById(String id)` | Standard single-record fetch |

4. **Imports**: Exact import statements needed when following this pattern

Organize patterns by concern, matching the spec's sections. Common patterns to look for:
- Repository pattern (data access)
- Provider pattern (state management)
- Model pattern (domain entities)
- Datasource pattern (SQLite/Supabase)
- Sync pattern (change_log, push/pull)
- Presentation pattern (screens, widgets)

### Phase 4: Ground Truth Verification

Verify ALL string literals, file paths, and symbol names discovered during research against the actual codebase.

| Category | Source of Truth |
|----------|----------------|
| Route paths | `lib/core/router/app_router.dart` |
| Widget keys | `lib/shared/testing_keys/*.dart` |
| DB column names | `lib/core/database/database_service.dart` |
| DB table names | `lib/core/database/database_service.dart` |
| Model field names | `lib/features/**/data/models/*.dart` |
| Provider/service APIs | Actual class method signatures |
| RPC function names | `supabase/migrations/*.sql` |
| Enum values | Model files where enums are defined |
| File paths in code | Glob to confirm existence |
| Lint rules per path | `rules/architecture.md` "Lint Rule Path Triggers" table |

Flag any discrepancies. The output directory must contain ONLY verified ground truth.

**New-file lint check:** When the spec proposes creating new files, cross-reference each target path against the "Lint Rule Path Triggers" table in `rules/architecture.md`. Include a "Lint Rules for New Files" section in `ground-truth.md` noting which rules will apply to each new file path.

### Phase 5: Research Agent Gap-Fill

Spawn read-only Agent tool subagents for anything CodeMunch couldn't resolve:

- Missing symbol sources that `get_symbol_source` didn't return
- Ambiguous dependency chains not fully captured by `get_dependency_graph`
- Cross-feature interactions not in the graph

**Constraints:**
- Read-only tools only: Read, Grep, Glob
- Model: opus (never haiku)
- Max 3 research agents
- Each agent gets ONE specific question, returns structured findings

Skip this phase if CodeMunch resolved everything.

### Phase 6: Write Output Directory

Write the structured directory:

```
.claude/tailor/YYYY-MM-DD-<spec-slug>/
├── manifest.md
├── dependency-graph.md
├── ground-truth.md
├── blast-radius.md
├── patterns/
│   └── <pattern-name>.md
└── source-excerpts/
    ├── by-file.md
    └── by-concern.md
```

#### manifest.md

```markdown
# Tailor Manifest

**Spec**: `.claude/specs/YYYY-MM-DD-<name>-spec.md`
**Created**: YYYY-MM-DD HH:MM
**Files analyzed**: N
**Patterns discovered**: N
**Methods mapped**: N
**Ground truth**: N verified, N flagged

## Contents
- [dependency-graph.md](dependency-graph.md) — Import chains, upstream/downstream deps
- [ground-truth.md](ground-truth.md) — Verified literals table
- [blast-radius.md](blast-radius.md) — Impact analysis + importers
- [patterns/](patterns/) — Architectural patterns with exemplars and methods
- [source-excerpts/](source-excerpts/) — Full source organized by file and by concern
```

#### dependency-graph.md
- Direct changes: files, symbols, line ranges, change type
- Dependency graph: upstream deps via `get_dependency_graph` (2+ levels)
- Import chains via `find_importers`
- Data flow diagram (ASCII)

#### ground-truth.md
- Verified literals table organized by category
- Each entry: literal value, source file, line number, verification status (VERIFIED / FLAGGED)
- Flagged items include the discrepancy found

#### blast-radius.md
- Per-symbol blast radius from `get_blast_radius`
- Summary counts: direct, dependent, tests, cleanup
- Dead code targets from `find_dead_code`

#### patterns/<pattern-name>.md

```markdown
# Pattern: [Pattern Name]

## How We Do It
[2-3 sentences describing the pattern in our codebase]

## Exemplars

### [ClassName] ([file path])
[Full source of key methods with annotations]

### [ClassName] ([file path])
[Full source of key methods]

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| ... | ... | ... | ... |

## Imports
[Exact import statements needed when following this pattern]
```

#### source-excerpts/by-file.md
Full source of relevant symbols, organized by file path. For each file: path, then all symbols from that file with their complete source.

#### source-excerpts/by-concern.md
Same source reorganized by spec concern. For each section of the spec, the relevant source code from existing files that the plan writer needs to see.

**Security:** Exclude content from `.env`, `supabase_config.dart`, or any credential-bearing files. Include method signatures and structure only, never credential values.

### Phase 7: Present Summary

Display to the user:

```
Tailor complete.

  Output: .claude/tailor/YYYY-MM-DD-<spec-slug>/
  Patterns: N discovered (repository, provider, ...)
  Methods: N mapped with full signatures
  Files: N analyzed
  Ground truth: N verified, N flagged
  Research gaps: N (filled by N agents) | or "None"

Run /writing-plans when ready.
```

---

## Hard Gate

<HARD-GATE>
Do NOT write the output directory (Phase 6) until you have:
1. Completed the full CodeMunch research sequence (Phase 2 — all 9 mandatory steps)
2. Completed pattern discovery (Phase 3)
3. Verified all ground truth (Phase 4)
4. Resolved all research gaps (Phase 5) or confirmed none exist
</HARD-GATE>

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Do This Instead |
|--------------|----------------|-----------------|
| Skipping CodeMunch steps | Incomplete analysis → bad plans | Run ALL 9 mandatory steps |
| Using `index_repo` or `get_repo_outline` | Fetches from GitHub, freezes | Use `index_folder` (local) only |
| Using haiku for research agents | Insufficient analysis quality | Always opus |
| Patterns without exemplars | Writer has to guess implementation | Every pattern needs 1-2 real implementations with full source |
| Skipping ground truth verification | Unverified literals → runtime failures | Verify ALL literals against codebase |
| Using `use_ai_summaries: false` | Misses context | Always `use_ai_summaries: true` |
| Credential values in output | Security risk | Method signatures only, never credential values |

---

## Remember

- **You drive all CodeMunch research** — subagents cannot use MCP tools
- **Pattern + method layering** — patterns give the "why", methods give the "what" for copy-paste accuracy
- **Ground truth is non-negotiable** — every literal verified against the actual codebase
- **Research agents are read-only** — opus, max 3, one question each
- **Output persists** — tailor directories are NOT deleted after writing-plans consumes them
- **Decoupled from writing-plans** — tailor never invokes writing-plans; the user chains them

## Save Location

Tailor output: `.claude/tailor/YYYY-MM-DD-<spec-slug>/`
