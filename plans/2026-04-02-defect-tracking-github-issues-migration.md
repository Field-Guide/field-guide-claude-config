# Defect Tracking Migration to GitHub Issues — Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Eliminate local `.claude/defects/` file-based defect tracking and make GitHub Issues the single source of truth.
**Spec:** `.claude/specs/2026-04-01-defect-tracking-github-issues-migration-spec.md`
**Tailor:** `.claude/tailor/2026-04-01-defect-tracking-github-issues-migration/`

**Architecture:** Thin helper script (`create-defect-issue.ps1`) handles label validation and `gh issue create`. Each caller formats its own body markdown. Readers simply drop defect file references — no replacement needed.
**Tech Stack:** PowerShell, GitHub CLI (`gh`), Markdown config files
**Blast Radius:** 1 created, 19 deleted, 22 updated, 0 Dart code changes

---

## Phase 1: Setup — Labels & Helper Script

### Sub-phase 1.1: Create GitHub Labels

**Files:**
- None (GitHub API only)

**Agent**: `general-purpose`

#### Step 1.1.1: Create feature labels

Run the following to create all 17 feature labels. Skip any that already exist (`defect` label exists from `sync-defects.yml`).

```bash
# WHY: 17 feature labels for multi-dimensional issue tracking
# NOTE: gh label create is idempotent — errors on duplicates are harmless
$features = @("auth", "contractors", "dashboard", "database", "entries", "forms", "locations", "pdf", "photos", "projects", "quantities", "settings", "sync", "toolbox", "weather", "tooling", "core")
foreach ($f in $features) {
    gh label create $f --repo RobertoChavez2433/construction-inspector-tracking-app --color "C2E0C6" --description "Feature: $f" --force 2>$null
}
```

Run: `pwsh -Command '<above script>'`

#### Step 1.1.2: Create type labels

```bash
# WHY: 4 type labels to categorize issue severity/nature
$types = @(
    @{name="defect"; color="D73A4A"; desc="Type: defect"},
    @{name="blocker"; color="B60205"; desc="Type: blocker"},
    @{name="security"; color="E11D48"; desc="Type: security finding"},
    @{name="cosmetic"; color="FEF2C0"; desc="Type: cosmetic issue"}
)
foreach ($t in $types) {
    gh label create $t.name --repo RobertoChavez2433/construction-inspector-tracking-app --color $t.color --description $t.desc --force 2>$null
}
```

Run: `pwsh -Command '<above script>'`

#### Step 1.1.3: Create priority labels

```bash
# WHY: 5 priority labels for triage
$priorities = @(
    @{name="critical"; color="B60205"; desc="Priority: critical"},
    @{name="high"; color="D93F0B"; desc="Priority: high"},
    @{name="medium"; color="FBCA04"; desc="Priority: medium"},
    @{name="low"; color="0E8A16"; desc="Priority: low"},
    @{name="parked"; color="D4C5F9"; desc="Priority: parked (not actively worked)"}
)
foreach ($p in $priorities) {
    gh label create $p.name --repo RobertoChavez2433/construction-inspector-tracking-app --color $p.color --description $p.desc --force 2>$null
}
```

Run: `pwsh -Command '<above script>'`

#### Step 1.1.4: Create layer labels

```bash
# WHY: 10 architectural layer labels for cross-cutting categorization
$layers = @(
    @{name="layer:app-wiring"; color="1D76DB"; desc="Layer: startup, routing, DI, bootstrap"},
    @{name="layer:state"; color="1D76DB"; desc="Layer: providers, state management"},
    @{name="layer:presentation"; color="1D76DB"; desc="Layer: screens, navigation, UX"},
    @{name="layer:services"; color="1D76DB"; desc="Layer: cross-cutting services, integrations"},
    @{name="layer:shared-ui"; color="1D76DB"; desc="Layer: shared widgets, cross-cutting hygiene"},
    @{name="layer:data"; color="1D76DB"; desc="Layer: repositories, datasources, models"},
    @{name="layer:database"; color="1D76DB"; desc="Layer: SQLite schema, migrations"},
    @{name="layer:sync"; color="1D76DB"; desc="Layer: sync engine, conflict resolution, Supabase"},
    @{name="layer:auth"; color="1D76DB"; desc="Layer: authentication, sessions, RLS"},
    @{name="layer:tests-tooling"; color="1D76DB"; desc="Layer: tests, tooling, quality gates"}
)
foreach ($l in $layers) {
    gh label create $l.name --repo RobertoChavez2433/construction-inspector-tracking-app --color $l.color --description $l.desc --force 2>$null
}
```

Run: `pwsh -Command '<above script>'`

#### Step 1.1.5: Verify labels created

Run: `pwsh -Command "gh label list --repo RobertoChavez2433/construction-inspector-tracking-app --limit 50"`
Expected: All 36 labels visible (17 feature + 4 type + 5 priority + 10 layer)

---

### Sub-phase 1.2: Create Helper Script

**Files:**
- Create: `tools/create-defect-issue.ps1`

**Agent**: `general-purpose`

#### Step 1.2.1: Write the helper script

```powershell
# WHY: Centralized defect issue creation with validated labels
# NOTE: Follows param validation pattern from tools/build.ps1
# FROM SPEC: Thin Script + Smart Callers — callers format their own body
<#
.SYNOPSIS
    Create a GitHub Issue with validated defect tracking labels.
.DESCRIPTION
    Validates all parameters against allowed label values, then runs
    gh issue create with the correct labels. Returns the issue URL on stdout.
.PARAMETER Title
    Brief description of the defect
.PARAMETER Feature
    One of the 17 feature names (auth, contractors, dashboard, etc.)
.PARAMETER Type
    defect | blocker | security | cosmetic
.PARAMETER Priority
    critical | high | medium | low | parked
.PARAMETER Layer
    One or more of the 10 layer labels (layer:app-wiring, layer:state, etc.)
.PARAMETER Body
    Markdown body (caller formats this)
.PARAMETER Ref
    File path reference, appended to body
.EXAMPLE
    .\tools\create-defect-issue.ps1 -Title "Sync fails on sign-out" -Feature sync -Type defect -Priority high -Layer @("layer:sync") -Body "## Details`nSync push fails..." -Ref "lib/features/sync/engine/sync_engine.dart:142"
#>
param(
    [Parameter(Mandatory)]
    [string]$Title,

    [Parameter(Mandatory)]
    [ValidateSet("auth", "contractors", "dashboard", "database", "entries", "forms", "locations", "pdf", "photos", "projects", "quantities", "settings", "sync", "toolbox", "weather", "tooling", "core")]
    [string]$Feature,

    [Parameter(Mandatory)]
    [ValidateSet("defect", "blocker", "security", "cosmetic")]
    [string]$Type,

    [Parameter(Mandatory)]
    [ValidateSet("critical", "high", "medium", "low", "parked")]
    [string]$Priority,

    [Parameter(Mandatory)]
    [ValidateSet("layer:app-wiring", "layer:state", "layer:presentation", "layer:services", "layer:shared-ui", "layer:data", "layer:database", "layer:sync", "layer:auth", "layer:tests-tooling")]
    [string[]]$Layer,

    [Parameter(Mandatory)]
    [string]$Body,

    [Parameter(Mandatory)]
    [string]$Ref
)

$ErrorActionPreference = "Stop"

# Build label list
$labels = @($Feature, $Type, $Priority) + $Layer
$labelString = $labels -join ","

# Append ref to body
$fullBody = "$Body`n`n**Ref**: ``$Ref``"

# Create issue
Write-Host "[defect-issue] Creating issue: $Title" -ForegroundColor Cyan
$issueUrl = gh issue create `
    --repo RobertoChavez2433/construction-inspector-tracking-app `
    --title "$Title" `
    --label "$labelString" `
    --body "$fullBody"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create GitHub Issue"
    exit 1
}

Write-Host "[defect-issue] Created: $issueUrl" -ForegroundColor Green
Write-Output $issueUrl
```

Write to: `tools/create-defect-issue.ps1`

#### Step 1.2.2: Verify script runs with --help

Run: `pwsh -Command "Get-Help ./tools/create-defect-issue.ps1 -Detailed"`
Expected: Shows parameter help including all ValidateSet values

---

## Phase 2: Migration — Audit & Create Issues

### Sub-phase 2.1: Audit Active Defects

**Files:**
- Read: `.claude/defects/` (18 files)
- Read: `.claude/autoload/_state.md` (blockers section)

**Agent**: `general-purpose`

#### Step 2.1.1: Read all 18 defect files and catalog active entries

Read every file in `.claude/defects/`:
- `_defects-auth.md`
- `_defects-contractors.md`
- `_defects-dashboard.md`
- `_defects-database.md`
- `_defects-entries.md`
- `_defects-forms.md`
- `_defects-locations.md`
- `_defects-pdf.md`
- `_defects-photos.md`
- `_defects-projects.md`
- `_defects-quantities.md`
- `_defects-settings.md`
- `_defects-sync.md`
- `_defects-sync-verification.md`
- `_defects-toolbox.md`
- `_defects-tooling.md`
- `_defects-weather.md`
- `_deferred-sv3-sv6-context.md`

For each file, list all active defect entries (title, category, date, pattern/prevention).

#### Step 2.1.2: Verify each defect against current codebase

For each active defect entry:
1. Check if the referenced file/code still exists
2. Check if the pattern is still relevant (hasn't been fixed)
3. Mark as MIGRATE (still relevant) or SKIP (already fixed or obsolete)

#### Step 2.1.3: Read active blockers from _state.md

Read `.claude/autoload/_state.md` lines 36-56 (Blockers section). Identify active blockers:
- BLOCKER-37: Agent Write/Edit Permission Inheritance — MITIGATED
- BLOCKER-34: Item 38 Superscript — OPEN (parked, cosmetic)
- BLOCKER-36: Item 130 Whitewash — OPEN (parked, cosmetic)
- BLOCKER-28: SQLite Encryption — OPEN
- BLOCKER-23: Flutter Keys — OPEN

Resolved blockers (38, 39) do NOT get migrated.

---

### Sub-phase 2.2: Create GitHub Issues for Active Defects

**Files:**
- Read: `.claude/defects/_defects-*.md` (for body content)

**Agent**: `general-purpose`

#### Step 2.2.1: Create issues for each MIGRATE-marked defect

For each defect marked MIGRATE in Step 2.1.2, call:

```bash
pwsh -File tools/create-defect-issue.ps1 `
    -Title "[CATEGORY] Brief Title" `
    -Feature "{feature}" `
    -Type "defect" `
    -Priority "{assessed priority}" `
    -Layer @("{assessed layer}") `
    -Body "{pattern + prevention text from defect file}" `
    -Ref "{original ref from defect entry}"
```

<!-- WHY: Each defect becomes a trackable GitHub Issue with proper labels -->
<!-- NOTE: Assess priority based on defect severity — most historical defects are medium/low -->

Record the issue URL and number returned by each call.

#### Step 2.2.2: Create issues for active blockers

For each active blocker (BLOCKER-28, 23, 34, 36, 37), call:

```bash
# WHY: Blockers get the "blocker" type label for distinct filtering
pwsh -File tools/create-defect-issue.ps1 `
    -Title "BLOCKER-NN: Title" `
    -Feature "{assessed feature}" `
    -Type "blocker" `
    -Priority "{assessed priority}" `
    -Layer @("{assessed layer}") `
    -Body "## Blocker`n`n**Status**: {status from _state.md}`n`n{additional context}" `
    -Ref ".claude/autoload/_state.md"
```

Example mappings:
| Blocker | Feature | Priority | Layer |
|---------|---------|----------|-------|
| BLOCKER-28 (SQLite Encryption) | database | critical | layer:database |
| BLOCKER-23 (Flutter Keys) | core | medium | layer:tests-tooling |
| BLOCKER-34 (Superscript) | pdf | parked | layer:services |
| BLOCKER-36 (Whitewash) | pdf | parked | layer:services |
| BLOCKER-37 (Agent Permissions) | tooling | low | layer:tests-tooling |

Record issue numbers for each blocker.

---

### Sub-phase 2.3: Update State & Archive

**Files:**
- Modify: `.claude/autoload/_state.md` (blocker entries)
- Modify: `.claude/logs/defects-archive.md` (append migrated entries)

**Agent**: `general-purpose`

#### Step 2.3.1: Update blocker entries in _state.md with issue numbers

For each blocker that got a GitHub Issue, add `(#NN)` to the header:

```markdown
# WHY: Dual-tracking — _state.md for session context, GitHub Issues for external visibility
# FROM SPEC: Blocker Format Change section

### BLOCKER-37: Agent Write/Edit Permission Inheritance (#NN)
**Status**: MITIGATED

### BLOCKER-34: Item 38 — Superscript `th` → `"` (Tesseract limitation) (#NN)
**Status**: OPEN (parked, cosmetic)

### BLOCKER-36: Item 130 — Whitewash destroys `y` descender (#NN)
**Status**: OPEN (parked, cosmetic)

### BLOCKER-28: SQLite Encryption (sqlcipher) (#NN)
**Status**: OPEN — production readiness blocker

### BLOCKER-23: Flutter Keys Not Propagating to Android resource-id (#NN)
**Status**: OPEN — MEDIUM
```

Replace `#NN` with actual issue numbers from Step 2.2.2.

#### Step 2.3.2: Append migrated defects to archive

For each MIGRATE-marked defect, append to `.claude/logs/defects-archive.md`:

```markdown
## Migrated to GitHub Issues (2026-04-02)

### [CATEGORY] Title (from _defects-{feature}.md → GitHub Issue #NN)
**Pattern**: ...
**Prevention**: ...
**Ref**: ...
```

#### Step 2.3.3: Verify migration count before cleanup

Count all defect entries across all 18 files that were marked MIGRATE in Step 2.1.2. Track the expected count as you create issues in Steps 2.2.1 and 2.2.2 (count both defect-type AND blocker-type issues). After all issues are created, verify:

```bash
# Count defect-type issues
pwsh -Command "(gh issue list --repo RobertoChavez2433/construction-inspector-tracking-app --label 'defect' --state open --json number --limit 200 | ConvertFrom-Json).Count"
# Count blocker-type issues
pwsh -Command "(gh issue list --repo RobertoChavez2433/construction-inspector-tracking-app --label 'blocker' --state open --json number --limit 200 | ConvertFrom-Json).Count"
```

<!-- WHY: Safety gate — abort Phase 5 deletion if migrated issue count diverges from source defect count -->
<!-- NOTE: Must count both defect and blocker types — blockers use a different type label -->

Sum both counts and compare to the total MIGRATE count. If counts diverge, do NOT proceed to Phase 5. Investigate missing entries first.

---

## Phase 3: Writer Updates

### Sub-phase 3.1: Update end-session Skill

**Files:**
- Modify: `.claude/skills/end-session/SKILL.md`

**Agent**: `general-purpose`

#### Step 3.1.1: Replace Step 3 (defect file writes → script calls)

Replace the entire "### 3. Update Per-Feature Defect Files" section (lines 42-54) and the "### Categories" section (lines 56-64) with:

```markdown
### 3. File Defects to GitHub Issues

For each feature where defects were discovered during this session, create a GitHub Issue:

```bash
pwsh -File tools/create-defect-issue.ps1 `
    -Title "[CATEGORY] YYYY-MM-DD: Brief Title" `
    -Feature "{feature}" `
    -Type "defect" `
    -Priority "{critical|high|medium|low|parked}" `
    -Layer @("{layer:...}") `
    -Body "**Pattern**: What to avoid (1 line)`n**Prevention**: How to avoid (1-2 lines)" `
    -Ref "@path/to/file.dart"
```

### Categories
| Category | Use For |
|----------|---------|
| [ASYNC] | Context safety, dispose, mounted checks |
| [E2E] | Patrol testing patterns |
| [FLUTTER] | Widget, Provider, state patterns |
| [DATA] | Repository, collection, model patterns |
| [CONFIG] | Supabase, credentials, environment |
```

<!-- WHY: Replaces local file writes with GitHub Issue creation -->
<!-- NOTE: Body format stays in the skill — "smart callers" pattern from spec -->

#### Step 3.1.2: Update Step 4 (blocker tracking)

In the "### 4. Update JSON State Files" section, update the `active_blockers` bullet (line 69) to also update GitHub Issues:

Replace:
```markdown
- Update `active_blockers` if blockers were resolved or discovered
```

With:
```markdown
- Update `active_blockers` if blockers were resolved or discovered
- If a blocker was resolved: `gh issue close <number> --comment "Resolved in session N"` and update `_state.md` status
- If a new blocker was discovered: create via `create-defect-issue.ps1` with `-Type blocker`, add `(#NN)` to `_state.md`
```

#### Step 3.1.3: Update Step 5 display and Rules section

In Step 5 (line 83), change:
```markdown
- Defects logged (if any)
```
To:
```markdown
- Defects filed to GitHub Issues (if any, with issue URLs)
```

In the Rules section, replace lines 93-94:
```markdown
- Updates per-feature defect files in `.claude/defects/`
- Defect tracking uses per-feature files in `.claude/defects/_defects-{feature}.md`
```
With:
```markdown
- Files defects to GitHub Issues via `tools/create-defect-issue.ps1`
- Defect tracking uses GitHub Issues with feature/type/priority/layer labels
```

---

### Sub-phase 3.2: Update systematic-debugging Skill

**Files:**
- Modify: `.claude/skills/systematic-debugging/SKILL.md`
- Modify: `.claude/skills/systematic-debugging/references/defects-integration.md`

**Agent**: `general-purpose`

#### Step 3.2.1: Update Phase 1.4 (defect read → gh issue list)

Replace lines 97-101 in SKILL.md:

```markdown
### 1.4 Check known defects

Read `.claude/defects/_defects-{feature}.md` for the relevant feature. Check categories: `[ASYNC]`, `[SYNC]`, `[DATA]`, `[CONFIG]`, `[SCHEMA]`, `[FLUTTER]`, `[E2E]`, `[MIGRATION]`.

If a known pattern matches: apply documented prevention. May resolve without further investigation.
```

With:

```markdown
### 1.4 Check known defects

Query GitHub Issues for the relevant feature:

```bash
gh issue list --repo RobertoChavez2433/construction-inspector-tracking-app --label "{feature}" --state open --json number,title,body --limit 20
```

Scan issue titles and bodies for categories: `[ASYNC]`, `[SYNC]`, `[DATA]`, `[CONFIG]`, `[SCHEMA]`, `[FLUTTER]`, `[E2E]`, `[MIGRATION]`.

If a known pattern matches: apply documented prevention. May resolve without further investigation.
```

<!-- WHY: GitHub Issues replaces local defect files as the source of truth -->

#### Step 3.2.2: Update Phase 10 (defect write → script call)

Replace lines 568-584 in SKILL.md:

```markdown
## Phase 10: DEFECT LOG

**Goal**: Record new patterns for future prevention.

If this bug represents a new pattern not already in the feature's defect file:

1. Identify category: `[ASYNC]`, `[SYNC]`, `[DATA]`, `[CONFIG]`, `[SCHEMA]`, `[FLUTTER]`, `[E2E]`, `[MIGRATION]`
2. Add to `.claude/defects/_defects-{feature}.md`:

```markdown
### [SYNC] 2026-03-14: Brief Title
**Pattern**: What caused the issue
**Prevention**: How to avoid it next time
**Ref**: lib/features/sync/engine/sync_engine.dart:142
```

3. If feature file is at 5 defects, archive the oldest to `.claude/logs/defects-archive.md` first.
```

With:

```markdown
## Phase 10: DEFECT LOG

**Goal**: Record new patterns for future prevention.

If this bug represents a new pattern not already in GitHub Issues for this feature:

1. Identify category: `[ASYNC]`, `[SYNC]`, `[DATA]`, `[CONFIG]`, `[SCHEMA]`, `[FLUTTER]`, `[E2E]`, `[MIGRATION]`
2. Create a GitHub Issue:

```bash
pwsh -File tools/create-defect-issue.ps1 `
    -Title "[CATEGORY] YYYY-MM-DD: Brief Title" `
    -Feature "{feature}" `
    -Type "defect" `
    -Priority "{priority}" `
    -Layer @("{layer:...}") `
    -Body "**Pattern**: What caused the issue`n**Prevention**: How to avoid it next time" `
    -Ref "lib/features/sync/engine/sync_engine.dart:142"
```
```

<!-- WHY: Eliminates local file writes and archive overflow logic -->

#### Step 3.2.3: Rewrite defects-integration.md for GitHub Issues

Full rewrite of `.claude/skills/systematic-debugging/references/defects-integration.md` (208 lines → ~120 lines):

```markdown
# Defects Integration

How to use and create GitHub Issues for defect tracking during debugging. Integrates with the Logger-based investigation workflow.

## Before Debugging

**ALWAYS check GitHub Issues for the relevant feature first.**

The bug you're looking at might be a known pattern.

### Check Process

1. Query open issues for the feature:
   ```bash
   gh issue list --repo RobertoChavez2433/construction-inspector-tracking-app --label "{feature}" --state open --json number,title,body --limit 20
   ```
2. Search for related categories in issue titles: `[ASYNC]`, `[SYNC]`, `[DATA]`, `[CONFIG]`, `[SCHEMA]`, `[FLUTTER]`, `[E2E]`, `[MIGRATION]`
3. If pattern exists, apply the documented prevention from the issue body

### Example Check

Debugging: "Sync adapter pushing wrong column data"

1. `gh issue list --label "sync" --state open --json number,title --limit 20`
2. Find: `#42 [SYNC] Type Converter Mismatch`
3. Read issue body: `gh issue view 42 --json body`
4. Check: Does the adapter's toSupabaseMap() strip local-only columns?
5. Apply: Verify TypeConverters alignment

## During Debugging

### Pattern Recognition

As you investigate, note patterns that match existing issues:

```markdown
**Observed**: setState called after await
**Matches**: GitHub Issue #NN [ASYNC] Async Context Safety
**Prevention applied**: Added mounted check
```

### New Pattern Discovery

If you discover a pattern NOT in existing GitHub Issues:

1. Document the pattern immediately (even before fixing)
2. Create the issue after fix is confirmed (Phase 10)

## After Fix

**ALWAYS create a GitHub Issue for new patterns.**

### Creating Defect Issues

```bash
pwsh -File tools/create-defect-issue.ps1 `
    -Title "[CATEGORY] YYYY-MM-DD: Brief Title" `
    -Feature "{feature}" `
    -Type "defect" `
    -Priority "{priority}" `
    -Layer @("{layer:...}") `
    -Body "**Pattern**: What causes the issue`n**Prevention**: How to avoid it`n**Logger signal**: {relevant Logger call}" `
    -Ref "@path/to/relevant/file.dart"
```

### Categories

| Category | Use For |
|----------|---------|
| `[ASYNC]` | Context safety, dispose issues, Future handling |
| `[E2E]` | ADB/UIAutomator testing patterns, TestingKeys, waits |
| `[FLUTTER]` | Widget lifecycle, Provider, setState |
| `[DATA]` | Repository, collection access, null safety |
| `[CONFIG]` | Supabase, environment, credentials |
| `[SYNC]` | SyncEngine, adapters, change tracker, conflict resolution |
| `[MIGRATION]` | Schema versions, migration steps, DatabaseService upgrades |
| `[SCHEMA]` | FK constraints, trigger behavior, table structure, SchemaVerifier |

## Defect Lifecycle

```
1. DISCOVER during debugging
   └─> Note pattern immediately

2. VERIFY fix works
   └─> Create GitHub Issue via create-defect-issue.ps1

3. PREVENT in future
   └─> Reference in code reviews
   └─> Check via gh issue list before similar work

4. CLOSE when resolved
   └─> gh issue close <number> --comment "Fixed in session N"
```

## Quick Reference

```bash
# List all open defects for a feature
gh issue list --repo RobertoChavez2433/construction-inspector-tracking-app --label "{feature}" --state open

# List all open blockers
gh issue list --repo RobertoChavez2433/construction-inspector-tracking-app --label "blocker" --state open

# View a specific issue
gh issue view <number> --repo RobertoChavez2433/construction-inspector-tracking-app

# Close a resolved issue
gh issue close <number> --repo RobertoChavez2433/construction-inspector-tracking-app --comment "Resolved"

# Create a new defect
pwsh -File tools/create-defect-issue.ps1 -Title "..." -Feature "..." -Type defect -Priority medium -Layer @("layer:...") -Body "..." -Ref "..."
```

---

## Log Server Integration

When using the debug server during investigation, cross-reference log evidence with GitHub Issues.

### Connecting defects to log evidence

When the server returns an error log entry, check if it matches a known defect pattern:

```bash
curl "http://127.0.0.1:3947/logs?category=error&last=20"
```

If the error message matches a known `[CATEGORY]` pattern in an open GitHub Issue, apply the documented prevention rather than starting fresh investigation.

### Logger categories map to defect categories

| Logger Category | Defect Category |
|-----------------|-----------------|
| `Logger.sync()` | `[SYNC]` |
| `Logger.db()` | `[SCHEMA]`, `[MIGRATION]`, `[DATA]` |
| `Logger.auth()` | `[CONFIG]` |
| `Logger.error()` | Any category |
| `Logger.lifecycle()` | `[ASYNC]` |

### Recording log patterns in defect issues

When creating a new defect issue, include the Logger call that would have caught it earlier in the body:

```
**Logger signal**: Logger.sync('SyncEngine.push.skipped') missing from error log when pendingCount > 0
```
```

Write to: `.claude/skills/systematic-debugging/references/defects-integration.md`

#### Step 3.2.4: Update debug-session-management.md references

**File:** `.claude/skills/systematic-debugging/references/debug-session-management.md`

1. **Lines 148-149**: Replace references to "DEFECT LOG" and "defect file" with GitHub Issues terminology:
   - Change "DEFECT LOG" to "DEFECT LOG (GitHub Issues)"
   - Change "defect file" to "GitHub Issue"

2. **Line 205**: Replace:
   ```markdown
   - Related defects found in `.claude/defects/`
   ```
   With:
   ```markdown
   - Related defects found in GitHub Issues
   ```

<!-- WHY: debug-session-management.md references local defect directory that will be deleted -->

---

### Sub-phase 3.3: Update test Skill

**Files:**
- Modify: `.claude/skills/test/references/output-format.md`

**Agent**: `general-purpose`

#### Step 3.3.1: Update summary table defects reference (line 67)

Replace:
```markdown
- **Defects filed**: {count} -> .claude/defects/_defects-{feature}.md
```

With:
```markdown
- **Defects filed**: {count} -> GitHub Issues
```

#### Step 3.3.2: Update Defects Filed table header reference (lines 71-75)

No change needed — the table structure is generic. Only the destination changes.

#### Step 3.3.3: Update Defect Filing Format section (lines 188-201)

Replace:
```markdown
## Defect Filing Format

When a flow fails, the wave agent files a defect to `.claude/defects/_defects-{feature}.md`:
```

With:
```markdown
## Defect Filing Format

When a flow fails, the wave agent files a defect via GitHub Issues:

```bash
pwsh -File tools/create-defect-issue.ps1 `
    -Title "[TEST] {YYYY-MM-DD}: {flow-name} flow failure (auto-test)" `
    -Feature "{feature}" `
    -Type "defect" `
    -Priority "high" `
    -Layer @("{assessed layer}") `
    -Body "<body below>" `
    -Ref ".claude/test-results/{run-dir}/screenshots/{flow}-{step}-{desc}.png"
```

Body format: The existing markdown template block that follows this line in the source file (Status, Source, Symptom, Step, Logcat, Screenshot, Suggested cause — lines 193-200) MUST be preserved as-is. That template becomes the `-Body` parameter value for the script call above.
```

<!-- WHY: Destination changes from local file to GitHub Issue, body template stays the same -->
<!-- NOTE: The markdown template block (Status, Source, Symptom, etc.) stays as-is — it becomes the -Body param -->

#### Step 3.3.4: Update chat summary format (line 226)

Replace:
```markdown
Defects filed: N new ({feature1}, {feature2})
```

With:
```markdown
Defects filed: N new GitHub Issues ({feature1}, {feature2})
```

---

### Sub-phase 3.4: Update security-agent

**Files:**
- Modify: `.claude/agents/security-agent.md`

**Agent**: `general-purpose`

#### Step 3.4.1: Update description (line 3)

Replace:
```markdown
description: Security auditor for the Construction Inspector App. Scans for credential exposure, RLS policy gaps, insecure data storage, PII leaks, manifest misconfigurations, sync integrity issues, and OWASP Mobile Top 10 compliance. Read-only — produces reports and defect files, never modifies code.
```

With:
```markdown
description: Security auditor for the Construction Inspector App. Scans for credential exposure, RLS policy gaps, insecure data storage, PII leaks, manifest misconfigurations, sync integrity issues, and OWASP Mobile Top 10 compliance. Read-only — produces reports and GitHub Issues, never modifies code.
```

#### Step 3.4.2: Update context_loading frontmatter (lines 21-22)

Remove these two lines from the context_loading block:
```markdown
    - defects/_defects-auth.md (known auth issues)
    - defects/_defects-sync.md (known sync issues)
```

<!-- WHY: Security agent no longer pre-loads local defect files -->

#### Step 3.4.3: Update body description (line 32)

Replace:
```markdown
Read-only security auditor that scans the entire codebase for vulnerabilities, misconfigurations, and data protection gaps. Produces structured reports and logs findings into per-feature defect files so implementation agents automatically see them.
```

With:
```markdown
Read-only security auditor that scans the entire codebase for vulnerabilities, misconfigurations, and data protection gaps. Produces structured reports and files findings as GitHub Issues so they are visible and trackable.
```

#### Step 3.4.4: Update Iron Law paragraph (line 46)

Replace:
```markdown
This agent is strictly read-only. It identifies and documents — it does not fix. Fixes are delegated to implementation agents via defect files.
```

With:
```markdown
This agent is strictly read-only. It identifies and documents — it does not fix. Fixes are delegated to implementation agents via GitHub Issues.
```

#### Step 3.4.5: Update Scan Execution Order (lines 227, 238)

Replace line 227:
```markdown
1. **Read baseline context** (state files, defect files, constraint files)
```
With:
```markdown
1. **Read baseline context** (state files, constraint files)
```

Replace line 238:
```markdown
12. **Write report** and **update defect files**
```
With:
```markdown
12. **Write report** and **file GitHub Issues**
```

#### Step 3.4.6: Replace Defect File Updates section (lines 293-316)

Replace the entire "## Defect File Updates" section with:

```markdown
## GitHub Issue Filing

After producing the main report, create GitHub Issues for each finding:

```bash
pwsh -File tools/create-defect-issue.ps1 `
    -Title "[SEC-NNN] Finding title" `
    -Feature "{feature from mapping below}" `
    -Type "security" `
    -Priority "{severity as priority}" `
    -Layer @("{assessed layer}") `
    -Body "- **Severity**: CRITICAL/HIGH/MEDIUM/LOW`n- **Category**: SECURITY`n- **Location**: ``file:line```n- **Description**: [1-2 sentences]`n- **Remediation**: [Recommended fix]`n- **Discovered**: YYYY-MM-DD (security-agent audit)" `
    -Ref "file:line"
```

Feature mapping:
| Finding affects... | Feature label |
|--------------------|---------------|
| Auth flows, tokens, deep links | `auth` |
| Sync queue, company_id trust | `sync` |
| Photo EXIF, GPS, storage | `photos` |
| PDF PII embedding | `pdf` |
| SQLite encryption, schema | `database` |
| Android manifest, build config | `core` |
| Project-wide (credentials, deps) | `core` |
```

#### Step 3.4.7: Update Verification section (lines 356-359)

Replace:
```markdown
1. **Defect files** — Findings logged to `.claude/defects/_defects-{feature}.md` for implementation agents to pick up
2. **Code review reports** — Full audit saved to `.claude/code-reviews/` for tracking
3. **Implementation agents** — Fix code based on defect file entries during their next task
```

With:
```markdown
1. **GitHub Issues** — Findings filed as GitHub Issues with security/feature/priority labels
2. **Code review reports** — Full audit saved to `.claude/code-reviews/` for tracking
3. **Implementation agents** — Fix code based on GitHub Issue entries during their next task
```

---

### Sub-phase 3.5: Update qa-testing-agent

**Files:**
- Modify: `.claude/agents/qa-testing-agent.md`

**Agent**: `general-purpose`

#### Step 3.5.1: Remove defect file from context_loading (line 27)

Remove this line from the context_loading block:
```markdown
    - defects/_defects-{name}.md (known issues and patterns to avoid)
```

#### Step 3.5.2: Replace Defect Logging section (lines 225-227)

Replace:
```markdown
## Defect Logging

When finding issues, log to `.claude/defects/_defects-{feature}.md` using format from `/end-session`.
```

With:
```markdown
## Defect Logging

When finding issues, create a GitHub Issue:

```bash
pwsh -File tools/create-defect-issue.ps1 `
    -Title "[CATEGORY] YYYY-MM-DD: Brief Title" `
    -Feature "{feature}" `
    -Type "defect" `
    -Priority "{priority}" `
    -Layer @("{layer:...}") `
    -Body "**Pattern**: ...`n**Prevention**: ..." `
    -Ref "file:line"
```
```

#### Step 3.5.3: Update Debugging Methodology section (lines 233-235)

Replace:
```markdown
- Check `defects/_defects-{feature}.md` for known patterns FIRST
- Follow 4-phase framework: Investigate -> Analyze -> Hypothesize -> Implement
- Log new patterns to `defects/_defects-{feature}.md` after fix
```

With:
```markdown
- Check `gh issue list --label "{feature}" --state open` for known patterns FIRST
- Follow 4-phase framework: Investigate -> Analyze -> Hypothesize -> Implement
- Create GitHub Issue for new patterns after fix via `create-defect-issue.ps1`
```

#### Step 3.5.4: Update Historical Reference (line 257)

Replace:
```markdown
- Past test issues: `.claude/logs/defects-archive.md`
```

With:
```markdown
- Past test issues: `gh issue list --label "{feature}" --state closed`
```

---

### Sub-phase 3.6: Update code-review-agent

**Files:**
- Modify: `.claude/agents/code-review-agent.md`

**Agent**: `general-purpose`

#### Step 3.6.1: Remove defect file from context_loading (line 22)

Remove this line from the context_loading block:
```markdown
    - defects/_defects-{name}.md (known issues and patterns to avoid)
```

#### Step 3.6.2: Replace Defect Logging section (lines 173-175)

Replace:
```markdown
## Defect Logging

When finding issues, log to `.claude/defects/_defects-{feature}.md` using format from `/end-session`.
```

With:
```markdown
## Defect Logging

When finding issues, create a GitHub Issue:

```bash
pwsh -File tools/create-defect-issue.ps1 `
    -Title "[CATEGORY] YYYY-MM-DD: Brief Title" `
    -Feature "{feature}" `
    -Type "defect" `
    -Priority "{priority}" `
    -Layer @("{layer:...}") `
    -Body "**Pattern**: ...`n**Prevention**: ..." `
    -Ref "file:line"
```
```

#### Step 3.6.3: Update Historical Reference (lines 192-194)

Replace:
```markdown
## Historical Reference
- Past sessions: `.claude/logs/state-archive.md`
- Past defects: `.claude/logs/defects-archive.md`
```

With:
```markdown
## Historical Reference
- Past sessions: `.claude/logs/state-archive.md`
- Past defects: `gh issue list --label "{feature}" --state closed`
```

---

## Phase 4: Reader Simplifications

### Sub-phase 4.1: Remove Defect References from Reader Agents

**Files:**
- Modify: `.claude/agents/debug-research-agent.md`
- Modify: `.claude/agents/auth-agent.md`
- Modify: `.claude/agents/frontend-flutter-specialist-agent.md`
- Modify: `.claude/agents/pdf-agent.md`
- Modify: `.claude/agents/backend-data-layer-agent.md`
- Modify: `.claude/agents/backend-supabase-agent.md`

**Agent**: `general-purpose`

#### Step 4.1.1: Update debug-research-agent.md

Remove/update these references:

1. **Line 17**: Remove `4. Check recent git history for related changes (read `.claude/defects/` files)`
   Replace with: `4. Check recent git history for related changes`

2. **Line 18**: Remove `5. Cross-reference with `.claude/defects/` for known issues matching the symptom`
   Replace with: (delete line entirely, renumber subsequent items)

3. **Lines 39-40**: Remove the "Related Defects Found" section from the report format:
   ```markdown
   ### Related Defects Found
   - [CATEGORY] defect title from .claude/defects/ — why it's related
   - (none found) if no matches
   ```
   Replace with: (delete entire section)

4. **Line 67**: Remove `5. Read `.claude/defects/` files for the affected feature (1-2 calls)`
   Replace with: (delete line, renumber subsequent items)

<!-- WHY: debug-research-agent no longer reads local defect files -->

#### Step 4.1.2: Update auth-agent.md

1. **Line 19**: Remove from context_loading frontmatter:
   ```markdown
       - defects/_defects-{name}.md (known issues and patterns to avoid)
   ```

2. **Line 115**: Remove from Security Checklist:
   ```markdown
   2. Check `.claude/defects/_defects-auth.md` for past issues
   ```
   Renumber remaining items.

#### Step 4.1.3: Update frontend-flutter-specialist-agent.md

**Line 45**: Remove from context_loading frontmatter:
```markdown
    - defects/_defects-{name}.md (known issues and patterns to avoid)
```

#### Step 4.1.4: Update pdf-agent.md

**Line 24**: Remove from context_loading frontmatter:
```markdown
    - defects/_defects-{name}.md (known issues and patterns to avoid)
```

#### Step 4.1.5: Update backend-data-layer-agent.md

**Line 39**: Remove from context_loading frontmatter:
```markdown
    - defects/_defects-{name}.md (known issues and patterns to avoid)
```

#### Step 4.1.6: Update backend-supabase-agent.md

**Line 29**: Remove from context_loading frontmatter:
```markdown
    - defects/_defects-{name}.md (known issues and patterns to avoid)
```

---

### Sub-phase 4.2: Remove Defect References from Skills & Rules

**Files:**
- Modify: `.claude/skills/brainstorming/skill.md`
- Modify: `.claude/skills/audit-config/SKILL.md`
- Modify: `.claude/rules/testing/patrol-testing.md`

**Agent**: `general-purpose`

#### Step 4.2.1: Update brainstorming skill

**Line 27** (checklist item): Replace:
```markdown
1. **Explore project context** — check files, docs, recent commits, defects
```
With:
```markdown
1. **Explore project context** — check files, docs, recent commits, GitHub Issues
```

**Line 79** (Phase 1 step 2): Replace:
```markdown
2. Check `.claude/defects/_defects-{feature}.md` for related past issues
```
With:
```markdown
2. Check `gh issue list --label "{feature}" --state open` for related past issues
```

#### Step 4.2.2: Update audit-config skill

**Line 47**: Remove from the file scan list:
```markdown
- `defects/` (~15 files)
```

**Line 67**: Remove from security invariant checks:
```markdown
- [ ] `active_blockers` in PROJECT-STATE.json count is consistent
```

Replace with:
```markdown
- [ ] Blocker entries in `_state.md` reference GitHub Issue numbers
```

<!-- WHY: audit-config no longer validates local defects directory -->

#### Step 4.2.3: Update patrol-testing rule

**Line 369**: Remove:
```markdown
- Defects to Avoid: `.claude/defects/_defects-{feature}.md` (per-feature defect files)
```

Replace with:
```markdown
- Defects to Avoid: `gh issue list --label "{feature}" --state open` (GitHub Issues)
```

#### Step 4.2.4: Update resume-session skill

**File:** `.claude/skills/resume-session/SKILL.md`

1. **Line 50**: Replace:
   ```markdown
   - If they want to debug → agents load defects and constraints as needed
   ```
   With:
   ```markdown
   - If they want to debug → agents load GitHub Issues and constraints as needed
   ```

2. **Line 61**: Replace:
   ```markdown
   - **Defects**: `defects/_defects-{name}.md`
   ```
   With:
   ```markdown
   - **Defects**: GitHub Issues (gh issue list --label "{feature}")
   ```

<!-- WHY: resume-session references local defect files that will no longer exist -->
<!-- NOTE: Line 22 (defects-archive.md pointer) stays as-is — archive still exists -->

---

## Phase 5: Cleanup & Documentation

### Sub-phase 5.1: Delete Obsolete Files

**Files:**
- Delete: `.claude/defects/` (entire directory, 18 files)
- Delete: `.github/workflows/sync-defects.yml`

**Agent**: `general-purpose`

#### Step 5.1.1: Verify archive was completed

Read `.claude/logs/defects-archive.md` and confirm the migration date stamp from Phase 2 is present.

#### Step 5.1.2: Delete defect files directory

```bash
# WHY: All active defects have been migrated to GitHub Issues in Phase 2
# NOTE: Archive was populated in Step 2.3.2 — safe to delete
Remove-Item -Path ".claude/defects" -Recurse -Force
```

Run: `pwsh -Command 'Remove-Item -Path ".claude/defects" -Recurse -Force'`

#### Step 5.1.3: Delete sync-defects workflow

```bash
# WHY: sync-defects.yml synced local defect files to GitHub Issues — no longer needed
# NOTE: quality-gate.yml is NOT deleted — it handles lint violations, not defects
Remove-Item -Path ".github/workflows/sync-defects.yml" -Force
```

Run: `pwsh -Command 'Remove-Item -Path ".github/workflows/sync-defects.yml" -Force'`

---

### Sub-phase 5.2: Update CLAUDE.md & Logs Documentation

**Files:**
- Modify: `.claude/CLAUDE.md`
- Modify: `.claude/logs/README.md`
- Modify: `.claude/logs/archive-index.md`

**Agent**: `general-purpose`

#### Step 5.2.1: Update Session & Workflow line (line 79)

Replace:
```markdown
- State: `.claude/autoload/_state.md` | Defects: `.claude/defects/_defects-{feature}.md` (max 5 per feature)
```

With:
```markdown
- State: `.claude/autoload/_state.md` | Defects: GitHub Issues (labeled by feature/type/priority/layer)
```

#### Step 5.2.2: Update Archives pointer (line 94)

Replace:
```markdown
| Archives | `.claude/logs/state-archive.md`, `.claude/logs/defects-archive.md` |
```

With:
```markdown
| Archives | `.claude/logs/state-archive.md` |
```

#### Step 5.2.3: Update logs/README.md

Remove or update any references to the `.claude/defects/` directory in `.claude/logs/README.md`. Replace defect-directory references with GitHub Issues pointers.

<!-- WHY: logs/README.md documents the defect directory which will no longer exist -->

#### Step 5.2.4: Update logs/archive-index.md

Update defect file navigation pointers in `.claude/logs/archive-index.md` to reference GitHub Issues instead of local defect files.

<!-- WHY: archive-index.md has navigation links to defect files that will be deleted -->

---

## Summary

| Phase | Sub-phases | Steps | Files Affected |
|-------|-----------|-------|----------------|
| 1. Setup | 2 | 7 | 1 created (script) + GitHub labels |
| 2. Migration | 3 | 8 | 2 modified (_state.md, archive) + GitHub Issues created |
| 3. Writer Updates | 6 | 25 | 9 modified (3 skills, 3 agents, 2 reference files) |
| 4. Reader Simplifications | 2 | 10 | 10 modified (6 agents, 3 skills, 1 rule) |
| 5. Cleanup | 2 | 7 | 19 deleted + 3 modified (CLAUDE.md, logs/README.md, logs/archive-index.md) |
| **Total** | **15** | **57** | **1 created, 19 deleted, 22 updated** |

**Agents involved**: `general-purpose` (all phases — no Dart code, all config/tooling)

**No Dart code changes. No tests required. No flutter test or flutter analyze needed.**
