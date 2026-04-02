# Source Excerpts — By Concern

## Concern 1: Helper Script Creation

### Pattern source: tools/build.ps1 (lines 1-39)
```powershell
<#
.SYNOPSIS
    Build Field Guide app for a target platform and copy the artifact to releases/.
.PARAMETER Platform
    Target platform: android, windows, ios
.PARAMETER BuildType
    Build mode: debug or release (default: release)
.EXAMPLE
    .\tools\build.ps1 -Platform android
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet("android", "windows", "ios")]
    [string]$Platform,

    [ValidateSet("debug", "release")]
    [string]$BuildType = "release",

    [switch]$Clean
)

$ErrorActionPreference = "Stop"
```

### Pattern source: quality-gate.yml (lines 289)
```bash
gh issue create --title "$TITLE" --body "$BODY" --label "lint,tech-debt,automated" 2>/dev/null || true
```

The new `create-defect-issue.ps1` combines the PS1 param validation pattern with the `gh issue create` command pattern.

---

## Concern 2: end-session Defect Writing (lines 42-54, 69, 81, 91-92)

### Current implementation
```markdown
### 3. Update Per-Feature Defect Files
**Directory**: `.claude/defects/`

For each feature where defects were discovered during this session:
1. Open `.claude/defects/_defects-{feature}.md`
2. Add new defect at the top of Active Patterns section:
\```markdown
### [CATEGORY] YYYY-MM-DD: Brief Title
**Pattern**: What to avoid (1 line)
**Prevention**: How to avoid (1-2 lines)
**Ref**: @path/to/file.dart (optional)
\```
3. If >5 defects in that file, move oldest to `.claude/logs/defects-archive.md`
```

### Replacement approach
Replace step 3 entirely: instead of file writes + archive, call `pwsh -File tools/create-defect-issue.ps1` with params. Drop the archive overflow logic. Update step 4 to reference GitHub Issue numbers for blockers.

---

## Concern 3: systematic-debugging Defect Read/Write

### Phase 1.4 — Read (lines 97-99)
```markdown
### 1.4 Check known defects

Read `.claude/defects/_defects-{feature}.md` for the relevant feature. Check categories: `[ASYNC]`, `[SYNC]`, `[DATA]`, `[CONFIG]`, `[SCHEMA]`, `[FLUTTER]`, `[E2E]`, `[MIGRATION]`.

If a known pattern matches: apply documented prevention. May resolve without further investigation.
```

Replace with: `gh issue list --label "{feature}" --state open --json title,body --limit 20`

### Phase 10 — Write (lines 566-582)
```markdown
## Phase 10: DEFECT LOG

**Goal**: Record new patterns for future prevention.

If this bug represents a new pattern not already in the feature's defect file:

1. Identify category: `[ASYNC]`, `[SYNC]`, `[DATA]`, `[CONFIG]`, `[SCHEMA]`, `[FLUTTER]`, `[E2E]`, `[MIGRATION]`
2. Add to `.claude/defects/_defects-{feature}.md`:
...
3. If feature file is at 5 defects, archive the oldest to `.claude/logs/defects-archive.md` first.
```

Replace with: Call `create-defect-issue.ps1`. Drop archive logic.

---

## Concern 4: test Skill Defect Filing

### Current template (output-format.md lines 187-201)
```markdown
## Defect Filing Format

When a flow fails, the wave agent files a defect to `.claude/defects/_defects-{feature}.md`:

\```markdown
### [TEST] {YYYY-MM-DD}: {flow-name} flow failure (auto-test)
**Status**: OPEN
**Source**: Automated test run {run-directory-name}
**Symptom**: {failure description from the flow report}
**Step**: Step {N} -- {step description}
**Logcat**: {relevant error lines, max 5 lines}
**Screenshot**: .claude/test-results/{run-dir}/screenshots/{flow}-{step}-{desc}.png
**Suggested cause**: {assessment based on logs + screenshots + flow context}
\```
```

Replace destination with `create-defect-issue.ps1`. Body template stays the same (smart caller pattern).

### Summary references (lines 59, 67, 226)
```
| # | Flow | Status | Duration | Defects | Notes |
...
Defects filed: {count} -> .claude/defects/_defects-{feature}.md
...
Defects filed: N new ({feature1}, {feature2})
```

Update path reference from `.claude/defects/_defects-{feature}.md` to "GitHub Issues".

---

## Concern 5: Security Agent Defect Writing

### Current mapping (lines 293-316)
```markdown
## Defect File Updates

After producing the main report, update per-feature defect files:

| Finding affects... | Update defect file |
|--------------------|--------------------|
| Auth flows, tokens, deep links | `_defects-auth.md` |
| Sync queue, company_id trust | `_defects-sync.md` |
| Photo EXIF, GPS, storage | `_defects-photos.md` |
| PDF PII embedding | `_defects-pdf.md` |
| SQLite encryption, schema | `_defects-database.md` (create if needed) |
| Android manifest, build config | `_defects-platform.md` (create if needed) |
| Project-wide (credentials, deps) | `_defects-core.md` (create if needed) |

Use the standard defect format:
\```markdown
### [SEC-NNN] Finding title
- **Severity**: CRITICAL/HIGH/MEDIUM/LOW
- **Category**: SECURITY
- **Location**: `file:line`
- **Description**: [1-2 sentences]
- **Remediation**: [Recommended fix]
- **Discovered**: YYYY-MM-DD (security-agent audit)
\```
```

Replace: Feature-to-file mapping becomes feature label on the GitHub Issue. SEC-NNN template becomes the `-Body` param. "Create if needed" is irrelevant (GitHub Issues always exist as a namespace).

---

## Concern 6: defects-integration.md Full Rewrite

This 208-line file needs a complete rewrite. Every section references local defect files. The new version should:
1. "Before Debugging" → `gh issue list --label "{feature}" --state open`
2. "During Debugging" → pattern matching against issue bodies
3. "After Fix" → call `create-defect-issue.ps1`
4. Lifecycle diagram → Discover → Create Issue → Close when fixed
5. Quick reference → `gh` commands instead of file paths
6. Log server integration → unchanged (defect format in issue body, not file)

---

## Concern 7: Reader Agent Simplification

### Shared frontmatter pattern (5 agents)
```yaml
  context_loading: |
    Before starting work, identify the feature(s) from your task.
    Then read ONLY these files for each relevant feature:
    - state/feature-{name}.json (feature state and constraints summary)
    - defects/_defects-{name}.md (known issues and patterns to avoid)
    - architecture-decisions/{name}-constraints.md (hard rules, if needed)
```

Remove the `defects/_defects-{name}.md` line. Keep the rest.

### debug-research-agent (unique pattern)
Lines 16-17 and 67 reference `.claude/defects/` for cross-referencing. Lines 39-40 have a "Related Defects Found" section in the report format. Remove all defect references and the report section.

### auth-agent (unique additional reference)
Line 114: `2. Check .claude/defects/_defects-auth.md for past issues` in Security Checklist. Remove this line.

---

## Concern 8: Blocker Format in _state.md

### Current format (lines 30-49)
```markdown
### BLOCKER-39: Data Loss — Sessions 697-698 Destroyed
**Status**: RESOLVED

### BLOCKER-38: Sign-Out Data Wipe Bug
**Status**: RESOLVED

### BLOCKER-37: Agent Write/Edit Permission Inheritance
**Status**: MITIGATED

### BLOCKER-34: Item 38 — Superscript `th` → `"` (Tesseract limitation)
**Status**: OPEN (parked, cosmetic)

### BLOCKER-36: Item 130 — Whitewash destroys `y` descender
**Status**: OPEN (parked, cosmetic)

### BLOCKER-28: SQLite Encryption (sqlcipher)
**Status**: OPEN — production readiness blocker

### BLOCKER-23: Flutter Keys Not Propagating to Android resource-id
**Status**: OPEN — MEDIUM
```

Add `(#NN)` to each that gets a GitHub Issue (active blockers only — BLOCKER-28, 23, 34, 36, 37).
