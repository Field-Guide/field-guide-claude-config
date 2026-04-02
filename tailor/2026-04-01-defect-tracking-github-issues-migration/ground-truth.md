# Ground Truth

All file paths, line numbers, and strings verified against codebase as of 2026-04-01.

## Files to Create

| File | Purpose | Verified |
|------|---------|----------|
| `tools/create-defect-issue.ps1` | Helper script for creating GitHub Issues | VERIFIED — `tools/` dir exists with 17 existing PS1 scripts |

## Files to Delete

| File | Exists | Verified |
|------|--------|----------|
| `.github/workflows/sync-defects.yml` | Yes (98 lines) | VERIFIED |
| `.claude/defects/` directory (18 files) | Yes | VERIFIED |

## Files to Update — Writer Skills

| File | Lines | Defect Lines | Verified |
|------|-------|-------------|----------|
| `.claude/skills/end-session/SKILL.md` | 95 | 22, 39, 42-54, 69, 81, 91-92 | VERIFIED |
| `.claude/skills/systematic-debugging/SKILL.md` | 642 | 50, 97-99, 566-582 | VERIFIED |
| `.claude/skills/systematic-debugging/references/defects-integration.md` | 208 | ENTIRE FILE (rewrite) | VERIFIED |
| `.claude/skills/test/references/output-format.md` | 228 | 59, 67, 71-75, 187-201, 226 | VERIFIED |
| `.claude/skills/brainstorming/skill.md` | 210 | 32, 77 | VERIFIED |

## Files to Update — Writer Agents

| File | Lines | Defect Lines | Verified |
|------|-------|-------------|----------|
| `.claude/agents/security-agent.md` | 370 | 3, 21-22, 32, 46, 227, 238, 293-316, 357-359 | VERIFIED |
| `.claude/agents/qa-testing-agent.md` | 258 | 27, 225-227, 233-235, 257 | VERIFIED |
| `.claude/agents/code-review-agent.md` | 195 | 22, 173-175, 192-194 | VERIFIED |

## Files to Update — Readers (drop defect references)

| File | Lines | Defect Line(s) | Verified |
|------|-------|----------------|----------|
| `.claude/agents/debug-research-agent.md` | 71 | 16, 17, 39-40, 67 | VERIFIED |
| `.claude/agents/auth-agent.md` | 151 | 19, 114 | VERIFIED |
| `.claude/agents/frontend-flutter-specialist-agent.md` | 191 | 45 | VERIFIED |
| `.claude/agents/pdf-agent.md` | 202 | 24 | VERIFIED |
| `.claude/agents/backend-data-layer-agent.md` | 200 | 39 | VERIFIED |
| `.claude/agents/backend-supabase-agent.md` | 192 | 29 | VERIFIED |
| `.claude/skills/audit-config/SKILL.md` | 123 | 47, 67 | VERIFIED |
| `.claude/rules/testing/patrol-testing.md` | 381 | 369 | VERIFIED |

## Files to Update — Project Config

| File | Lines | Defect Lines | Verified |
|------|-------|-------------|----------|
| `.claude/CLAUDE.md` | ~110 | 79, 94 | VERIFIED |
| `.claude/autoload/_state.md` | 99 | Blockers section (lines 29-49) | VERIFIED |

## Exact Strings to Match (for plan writer edits)

### CLAUDE.md line 79
```
- State: `.claude/autoload/_state.md` | Defects: `.claude/defects/_defects-{feature}.md` (max 5 per feature)
```

### CLAUDE.md line 94
```
| Archives | `.claude/logs/state-archive.md`, `.claude/logs/defects-archive.md` |
```

### Frontmatter defect line (shared by 5 reader agents)
```
    - defects/_defects-{name}.md (known issues and patterns to avoid)
```
Appears in: auth-agent (line 19), frontend-flutter-specialist (line 45), pdf-agent (line 24), backend-data-layer (line 39), backend-supabase (line 29)

### Security agent frontmatter (lines 21-22)
```
    - defects/_defects-auth.md (known auth issues)
    - defects/_defects-sync.md (known sync issues)
```

### Patrol-testing line 369
```
- Defects to Avoid: `.claude/defects/_defects-{feature}.md` (per-feature defect files)
```

### Brainstorming skill line 77
```
2. Check `.claude/defects/_defects-{feature}.md` for related past issues
```

## GitHub Repo Reference

| Item | Value | Verified |
|------|-------|----------|
| Repo URL | `https://github.com/RobertoChavez2433/construction-inspector-tracking-app` | VERIFIED (from CLAUDE.md) |
| Existing labels | `defect`, `lint`, `tech-debt`, `automated` + feature labels from sync-defects.yml | VERIFIED (from workflow files) |
| `gh` auth | Available (quality-gate.yml uses `gh issue` commands in CI) | VERIFIED |

## Lint Rules for New Files

| New File | Applicable Lint Rules |
|----------|----------------------|
| `tools/create-defect-issue.ps1` | None — PS1 files not covered by Dart lint rules |

No new Dart files are being created, so no lint path triggers apply.
