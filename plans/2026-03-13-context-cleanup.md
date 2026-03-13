# Context Cleanup Plan

**Goal**: Slash auto-loaded token cost, resolve dual MEMORY.md confusion, fix stale references, clean disk.

---

## Phase 1: Resolve Dual MEMORY.md (eliminate confusion)

**Problem**: Two MEMORY.md files with different content and a wrong "CRITICAL" note saying to use the wrong one.

| File | Auto-loaded? | Lines | Last Modified |
|------|-------------|-------|---------------|
| `~/.claude/projects/.../memory/MEMORY.md` | YES (first 200 lines) | 102 | Today |
| `.claude/memory/MEMORY.md` | NO (never) | 125 | Mar 4 |

**Actions**:
1. **Auto-memory** (`~/.claude/projects/.../memory/MEMORY.md`): Strip down to ~30 lines. Keep ONLY:
   - User Preferences (NEVER revert, NEVER flutter clean, NEVER act without asking) — 4 lines
   - Build gotcha (pwsh wrapper, never run flutter directly in Git Bash) — 2 lines
   - NEVER delete gradle caches — 1 line
   - NEVER run Stop-Process dart — 1 line
   - CodeMunch repo identifier — 1 line
   - Pointer: "Detailed project knowledge in `.claude/memory/MEMORY.md`" — 1 line
   - Springfield PDF path — 1 line
   - Device serial numbers (3 devices) — 3 lines

   Everything else gets deleted or merged into the project memory file.

2. **Project memory** (`.claude/memory/MEMORY.md`): Keep as the detailed knowledge base. Remove the incorrect "CRITICAL: Memory File Location" note at bottom. This file is loaded on-demand by agents/skills, not auto-loaded — which is fine for reference material.
   - Trim resolved/superseded content (disproven hypotheses, old session archaeology)
   - Keep: PDF pipeline deep knowledge, ADB testing, one-point chart algorithm, build lifecycle, agent patterns

**Result**: Auto-loaded memory drops from ~3,556 tokens → ~400 tokens.

---

## Phase 2: Restructure CLAUDE.md as Pure Pointer

**Current**: 239 lines, ~3,139 tokens. Mix of pointers and inline content.
**Target**: ~120 lines. Pure index/pointer with only essential guardrails inline.

**Keep inline** (these MUST be in every session):
- Project description + hard constraint (security) — 4 lines
- Project Structure tree — 8 lines
- Key Files table — 6 lines
- Domain Rules table (explains lazy-loading) — 14 lines
- Data Flow diagram — 3 lines
- Quick Reference Commands (build/test/run) — 16 lines
- Common Mistakes (the 6 bullet points) — 8 lines
- Session management (`/resume-session`, `/end-session`) — 4 lines
- Context Efficiency rules (subagent usage, hygiene) — 10 lines
- Git Workflow (feature branch, never main) — 3 lines
- Repositories table — 4 lines

**Remove entirely**:
- Line 122: `flutter clean` command (contradicts MEMORY.md rule)
- Audit System block (lines 185-206): 22 lines of "not yet implemented". Replace with 1-line pointer to backlogged plan.
- Pre-commit hook section: doesn't exist yet, no value loading every session

**Collapse to 1-2 line pointers**:
- Agents table → "See `.claude/agents/` — 9 agent definitions with skills: frontmatter"
- Skills table → "See `.claude/skills/` — loaded on-demand via agent frontmatter or user invocation"
- Directory Reference → "See `.claude/docs/directory-reference.md`" (create this file)
- Documentation System → merge into the directory reference doc
- UI Prototyping → "See `rules/frontend/ui-prototyping.md` (auto-loads for mockups/)"
- Testing → "See `rules/testing/patrol-testing.md` (auto-loads for test files)"
- Development Tools → "See `tools/README.md`" (if exists) or collapse to 2 lines
- Platform Requirements → already just a pointer, keep as-is (1 line)

**Estimated result**: ~120 lines, ~1,800 tokens (down from 3,139).

---

## Phase 3: Fix architecture.md

**File**: `.claude/rules/architecture.md` (lazy-loaded only for `lib/**/*.dart`)

**Fixes**:
- Line 22: "13 feature modules" → "17 feature modules" (auth, calculator, contractors, dashboard, entries, forms, gallery, locations, pdf, photos, projects, quantities, settings, sync, todos, toolbox, weather)
- Line 26: Add note that calculator/forms/gallery/todos are toolbox sub-features

No other structural issues found — the patterns, anti-patterns, and package list are accurate.

---

## Phase 4: .claude/ Directory Cleanup

### Move completed plans to `plans/completed/`:
1. `plans/2026-03-13-pipeline-report-redesign.md` — checkpoint shows all phases done
2. `plans/2026-03-13-auth-onboarding-bugfix.md` — `_state.md` says DONE
3. `plans/2026-03-12-table-bounded-text-protection.md` — approach disproven, reverted

### Archive superseded specs:
Create `specs/archived/` and move:
4. `specs/2026-03-11-grid-removal-fix-spec.md` — superseded by v2, then v3
5. `specs/2026-03-11-grid-removal-v2-spec.md` — superseded by v3
6. `specs/2026-03-09-pdfrx-parity-spec.md` — migration complete
7. `specs/2026-03-08-claude-directory-audit-spec.md` — prior audit done

### Rotate defects:
8. `defects/_defects-pdf.md`: 7 entries (max 5). Move 2 oldest to `logs/defects-archive.md`

### Update stale metadata:
9. `logs/archive-index.md`: Update session range (currently says 427-431, now at 560)
10. `state/AGENT-FEATURE-MAPPING.json`: Add test-wave-agent, security-agent, implement-orchestrator
11. Remove completed plans from `autoload/_state.md` Active Plans section

### Delete orphaned files:
12. `outputs/audit-report-2026-03-08.md` — old audit output
13. `outputs/agent-6-claude-md-issues.md` — old audit output
14. `outputs/agent-9-claude-md-issues.md` — old audit output
15. `logs/2026-02-19-marionette-findings.md` — Marionette superseded by Patrol, no inbound refs

### Create directory reference doc:
16. `docs/directory-reference.md` — receives the Directory Reference table + Documentation System block from CLAUDE.md

---

## Phase 5: Disk Cleanup

### Delete old conversation logs:
17. All `.jsonl` files in `~/.claude/projects/C--Users-rseba-Projects-Field-Guide-App/` older than 7 days

### Delete temp files:
18. Scan for and remove any `.tmp`, `~` files, stale tool-results in the projects directory

---

## Token Impact Summary

| Source | Before | After | Savings |
|--------|--------|-------|---------|
| Project CLAUDE.md | ~3,139 | ~1,800 | −1,339 |
| Auto-memory MEMORY.md | ~3,556 | ~400 | −3,156 |
| autoload/_state.md | ~1,986 | ~1,700 | −286 |
| Global CLAUDE.md | ~23 | ~23 | 0 |
| **Total** | **~8,704** | **~3,923** | **−4,781 (55%)** |

---

## Verification

After all changes:
- Run `/resume-session` and verify context loads correctly
- Check that rules files still lazy-load (test by reading a `lib/**/*.dart` file)
- Verify no broken references in remaining active files
- Confirm agents can still find their documentation via the pointer structure
