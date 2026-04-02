# Source Excerpts — By File

## .github/workflows/sync-defects.yml (DELETE — full source for reference)

98 lines. Full source captured for reference before deletion.

Key structure:
- Triggers on push to `main` when `.claude/defects/**` changes
- Parses `_defects-*.md` files, splits on `## ` headers
- Creates issues with labels `defect,{feature}`
- Auto-closes issues when defect entries are removed
- Uses `actions/github-script@v7` for GitHub API

## tools/build.ps1 (PATTERN — exemplar for new script)

196 lines. Key sections for pattern:
- Lines 1-18: Comment-based help (`<# .SYNOPSIS ... #>`)
- Lines 19-37: `param()` block with `[Parameter(Mandatory)]`, `[ValidateSet()]`
- Line 39: `$ErrorActionPreference = "Stop"`
- Lines 54-58: Validation logic with `Write-Error` + `exit 1`
- Lines 188-195: Summary output with `Write-Host -ForegroundColor`

## .claude/skills/end-session/SKILL.md

95 lines. Defect-related sections:

**Step 3 (lines 42-54)**: "Update Per-Feature Defect Files"
- Opens `.claude/defects/_defects-{feature}.md`
- Adds new defect at top of Active Patterns
- Template: `### [CATEGORY] YYYY-MM-DD: Brief Title` + Pattern/Prevention/Ref
- Archives overflow to `defects-archive.md` when >5

**Step 4 (lines 65-71)**: Updates `active_blockers` in PROJECT-STATE.json

**Line 81**: Display summary includes "Defects logged (if any)"
**Lines 91-92**: Rules reference `.claude/defects/` and `_defects-{feature}.md`

## .claude/skills/systematic-debugging/SKILL.md

642 lines. Defect-related sections:

**Line 50**: Reference file `defects-integration.md`
**Lines 97-99**: Phase 1.4 — reads `_defects-{feature}.md`, checks categories
**Lines 566-582**: Phase 10 — DEFECT LOG, writes to `_defects-{feature}.md`, archives overflow

## .claude/skills/systematic-debugging/references/defects-integration.md

208 lines. ENTIRE FILE is defect-related — needs full rewrite for GitHub Issues.

Key sections:
- Lines 5-34: "Before Debugging" — check defect file first, example workflow
- Lines 35-53: "During Debugging" — pattern recognition against known defects
- Lines 55-90: "After Fix" — log new patterns, standard format with Logger signal
- Lines 91-106: Defect lifecycle diagram
- Lines 108-120: Using defects in code review
- Lines 122-130: Defects limit (max 5, auto-archive)
- Lines 132-169: Quick reference — all 15 file paths, common commands
- Lines 173-208: Log server integration — connecting defects to log evidence

## .claude/skills/test/references/output-format.md

228 lines. Defect-related sections:

**Lines 59, 67, 71-75**: Run summary table with Defects column and "Defects filed" counter
**Lines 187-201**: Defect filing format — `[TEST]` category template with Status, Source, Symptom, Step, Logcat, Screenshot, Suggested cause
**Line 226**: Chat summary format "Defects filed: N new"

## .claude/skills/brainstorming/skill.md

210 lines. Defect-related sections:

**Line 32**: Checklist item — "check files, docs, recent commits, defects"
**Line 77**: Phase 1 step 2 — "Check `.claude/defects/_defects-{feature}.md` for related past issues"

## .claude/agents/security-agent.md

370 lines. Defect-related sections:

**Line 3**: Description mentions "defect files"
**Lines 21-22**: Context loading reads `_defects-auth.md` and `_defects-sync.md`
**Line 32**: Summary mentions "defect files"
**Line 46**: Iron law references delegation via defect files
**Line 227**: Scan order step 1 reads defect files
**Line 238**: Scan order step 12 updates defect files
**Lines 293-316**: "Defect File Updates" section — 7 feature-to-file mappings + SEC-NNN template
**Lines 357-359**: Verification section — defect files for implementation agent pickup

## .claude/agents/qa-testing-agent.md

258 lines. Defect-related sections:

**Line 27**: Context loading reads `defects/_defects-{name}.md`
**Lines 225-227**: Defect logging — write to `_defects-{feature}.md`
**Lines 233-235**: Debugging methodology — check defects FIRST, log after fix
**Line 257**: Historical reference — `defects-archive.md`

## .claude/agents/code-review-agent.md

195 lines. Defect-related sections:

**Line 22**: Context loading reads `defects/_defects-{name}.md`
**Lines 173-175**: Defect logging — write to `_defects-{feature}.md`
**Lines 192-194**: Historical reference — `state-archive.md`, `defects-archive.md`

## Reader Agents (6 files — minimal changes)

All share the same frontmatter pattern:
```
    - defects/_defects-{name}.md (known issues and patterns to avoid)
```

| File | Line to Remove |
|------|---------------|
| `debug-research-agent.md` | Lines 16, 17, 39-40, 67 (multiple references) |
| `auth-agent.md` | Line 19 (frontmatter) + line 114 (security checklist) |
| `frontend-flutter-specialist-agent.md` | Line 45 (frontmatter) |
| `pdf-agent.md` | Line 24 (frontmatter) |
| `backend-data-layer-agent.md` | Line 39 (frontmatter) |
| `backend-supabase-agent.md` | Line 29 (frontmatter) |

## Other Files

| File | Line(s) | Change |
|------|---------|--------|
| `audit-config/SKILL.md` | 47, 67 | Remove `defects/` from audit scope, update `active_blockers` check |
| `patrol-testing.md` | 369 | Remove "Defects to Avoid" resource line |
| `CLAUDE.md` | 79, 94 | Update defect references |
| `_state.md` | 29-49 | Add issue numbers to blocker entries |
