# Dependency Graph

## Overview

This is a config/tooling change — no Dart code dependencies. The graph shows which `.claude/` files reference defect tracking and how they connect.

## File Dependency Map

```
tools/create-defect-issue.ps1 (NEW)
  ← called by: end-session skill
  ← called by: systematic-debugging skill
  ← called by: test skill
  ← called by: security-agent
  ← called by: qa-testing-agent
  ← called by: code-review-agent

.github/workflows/sync-defects.yml (DELETE)
  → reads: .claude/defects/_defects-*.md
  → writes: GitHub Issues (label: defect,{feature})

.github/workflows/quality-gate.yml (NO CHANGE — reference only)
  → writes: GitHub Issues (label: lint,tech-debt,automated)
  → uses: gh issue list, gh issue create, gh issue edit, gh issue close
```

## Writer Dependencies

```
end-session/SKILL.md
  ├── currently writes: .claude/defects/_defects-{feature}.md
  ├── currently writes: .claude/logs/defects-archive.md
  ├── currently writes: state/PROJECT-STATE.json (active_blockers)
  └── changes to: tools/create-defect-issue.ps1 + gh issue close/edit

systematic-debugging/SKILL.md
  ├── currently reads: .claude/defects/_defects-{feature}.md (Phase 1.4)
  ├── currently writes: .claude/defects/_defects-{feature}.md (Phase 10)
  ├── currently writes: .claude/logs/defects-archive.md
  ├── references: defects-integration.md
  └── changes to: gh issue list (Phase 1.4) + tools/create-defect-issue.ps1 (Phase 10)

test/references/output-format.md
  ├── currently writes: .claude/defects/_defects-{feature}.md
  └── changes to: tools/create-defect-issue.ps1

security-agent.md
  ├── currently reads: defects/_defects-auth.md, defects/_defects-sync.md
  ├── currently writes: _defects-{feature}.md (7 feature mappings)
  ├── currently creates: new _defects-*.md files
  └── changes to: tools/create-defect-issue.ps1

qa-testing-agent.md
  ├── currently reads: defects/_defects-{name}.md
  ├── currently writes: .claude/defects/_defects-{feature}.md
  ├── currently reads: .claude/logs/defects-archive.md
  └── changes to: tools/create-defect-issue.ps1 (write), drop reads

code-review-agent.md
  ├── currently reads: defects/_defects-{name}.md
  ├── currently writes: .claude/defects/_defects-{feature}.md
  ├── currently reads: .claude/logs/defects-archive.md
  └── changes to: tools/create-defect-issue.ps1 (write), drop reads
```

## Reader Dependencies (all DROP their defect references)

```
debug-research-agent.md    → reads .claude/defects/ (lines 16, 17, 67)
auth-agent.md              → reads defects/_defects-{name}.md (line 19), _defects-auth.md (line 114)
frontend-flutter-specialist-agent.md → reads defects/_defects-{name}.md (line 45)
pdf-agent.md               → reads defects/_defects-{name}.md (line 24)
backend-data-layer-agent.md → reads defects/_defects-{name}.md (line 39)
backend-supabase-agent.md  → reads defects/_defects-{name}.md (line 29)
brainstorming/skill.md     → reads .claude/defects/_defects-{feature}.md (line 77)
audit-config/SKILL.md      → validates defects/ directory (line 47), active_blockers (line 67)
patrol-testing.md          → references .claude/defects/_defects-{feature}.md (line 369)
```

## CLAUDE.md References

```
CLAUDE.md line 79: "Defects: `.claude/defects/_defects-{feature}.md` (max 5 per feature)"
CLAUDE.md line 94: "Archives | `.claude/logs/state-archive.md`, `.claude/logs/defects-archive.md`"
```

## Dart Code References (NO CHANGES NEEDED)

BLOCKER- appears in code comments and test names as historical documentation:
- `sync_engine.dart:574` — comment: "BLOCKER-29"
- `sync_engine.dart:865` — comment: "BLOCKER-24"
- `sync_engine.dart:1014` — comment: "BLOCKER-24"
- `sync_engine_test.dart:288,291` — test group: "BLOCKER-38"
- `sync_engine_test.dart:656,664` — test group: "BLOCKER-29"
- `sync_engine_test.dart:777,789` — test group: "BLOCKER-24"
- `sync_engine_e2e_test.dart:270` — comment: "BLOCKER-38"
- `no_skip_without_issue_ref.dart:28` — regex: `BLOCKER-\d+`

These are historical references documenting WHY code exists. They do NOT need to change.
