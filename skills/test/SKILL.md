---
name: test
description: "Build, install, and run automated user flows on a USB-connected Android device using ADB, UIAutomator, and Claude vision. Supports 4-tier flag system, per-feature targeting, and structured output."
user-invocable: true
---

# /test Skill

Automated ADB-based testing for the Field Guide App. Builds the APK, installs on a connected Android device, and runs user flows with visual verification. Produces structured output with screenshots, logcat, and per-flow reports.

## Iron Laws

> 1. **ORCHESTRATOR STAYS THIN.** Dispatches wave agents in background. Never processes raw screenshots, XML, or verbose agent output.
> 2. **LOGCAT AFTER EVERY INTERACTION.** Wave agents check `adb logcat` after every ADB action -- catches Flutter errors and transient snackbars.
> 3. **DISK-FIRST OUTPUT.** Wave agents write full results to disk (flow reports, defects, screenshots). Return only a 1-line-per-flow status to orchestrator.
> 4. **READ DISK ON DEMAND ONLY.** Orchestrator never pre-reads flow reports. Only reads from disk when user asks to investigate a specific failure.

## CLI Interface

```
/test --<flag> [--<flag> ...]
/test <flow-name> [<flow-name> ...]
```

## Tier Flags

| Flag | What runs | Est. time |
|------|-----------|-----------|
| `--smoke` | 3 smoke flows (login, navigate-tabs, create-entry-quick) | ~2-3 min |
| `--feature` | All 18 feature flows | ~20-30 min |
| `--journey` | All 12 journeys | ~40-60 min |
| `--full` | All flows + all journeys (deduped) | ~60-90 min |

## Feature Flags (run specific feature flows)

| Flag | Flows triggered |
|------|----------------|
| `--auth` | login, register, forgot-password |
| `--projects` | create-project, edit-project |
| `--entries` | create-entry, edit-entry, review-submit |
| `--contractors` | add-contractors |
| `--quantities` | add-quantities |
| `--pdf` | import-pdf |
| `--photos` | capture-photo |
| `--sync` | sync-check |
| `--settings` | settings-theme, edit-profile |
| `--toolbox` | calculator, forms-fill, gallery-browse, todos-crud |

## Journey Flags (run specific journeys)

| Flag | Journey |
|------|---------|
| `--onboarding` | register -> profile-setup -> company-setup |
| `--daily-work` | login -> create-project -> create-entry -> add-quantities -> review-submit -> sync-check |
| `--project-setup` | login -> create-project -> edit-project -> import-pdf -> add-contractors |
| `--field-documentation` | login -> create-entry -> capture-photo -> forms-fill -> add-quantities |
| `--offline-sync` | login -> create-entry-offline -> sync-reconnect |
| `--admin-flow` | login -> admin-dashboard -> approve-member |
| `--budget-tracking` | login -> create-project -> import-pdf -> add-quantities -> quantities-check |
| `--entry-lifecycle` | login -> create-entry -> edit-entry -> capture-photo -> review-submit |
| `--multi-day` | login -> create-entry -> create-entry-day2 -> review-submit |
| `--contractor-mgmt` | login -> create-project -> add-contractors -> create-entry -> add-contractors-entry |
| `--settings-personalization` | login -> settings-theme -> edit-profile -> todos-crud |
| `--data-recovery` | login -> create-entry-offline -> sync-reconnect -> edit-entry -> sync-check |

## Combining Flags

```
/test --smoke --entries          # Smoke flows + entries feature flows
/test --daily-work --sync        # daily-work journey + sync feature flows
/test --auth --projects          # Auth + projects feature flows
```

## Special Flags

| Flag | Behavior |
|------|----------|
| `--all` | Alias for `--full` |
| `--list` | Print available flows/journeys, don't run |
| `--dry-run` | Parse flags, show what would run, don't execute |

## Named Flow Arguments

```
/test login                      # Run login flow only
/test create-entry               # Runs login + create-project + create-entry (deps auto-resolved)
/test login create-project       # Run both flows + deps
```

## Auto-Selection (no args)

```
/test                            # Auto-select from git diff
```

Maps `git diff main...HEAD` to features, selects matching flows + transitive dependencies.

## Flag Resolution Logic

When the orchestrator receives flags, it resolves them to a concrete flow list:

1. **Parse all flags** from the invocation
2. **Expand tier flags**: `--smoke` -> 3 smoke flows, `--feature` -> all 18 feature flows, etc.
3. **Expand feature flags**: `--entries` -> [create-entry, edit-entry, review-submit], etc.
4. **Expand journey flags**: `--daily-work` -> [login, create-project, create-entry, add-quantities, review-submit, sync-check]
5. **Union all expanded flows** (deduplicate)
6. **Resolve transitive deps**: For each flow, add all flows listed in its `deps` field, recursively
7. **Deduplicate again** after dep resolution
8. **Topological sort**: Order flows by dependency depth (no-dep flows first)

Priority order when flags conflict: the union is always taken (flags are additive, never subtractive).

## How It Works

### Phase 1: Pre-Flight
1. **ADB check**: `adb devices -l` -- verify device connected
2. **Device info**: Collect model, Android version for report header
3. **Build check**: If debug APK is >1 hour old or missing, rebuild via `pwsh -File tools/build.ps1 -Platform android -BuildType debug`
4. **Install**: `adb install -r releases/android/debug/app-debug.apk`
5. **Launch**: Force stop, clear logcat, start app, wait 5s
6. **Create run directory**: `.claude/test-results/YYYY-MM-DD_HHmm_{descriptor}/` with `screenshots/`, `logs/`, `flows/` subdirs
7. **Cleanup**: Delete oldest run if >5 exist
8. **Write report header**: Initialize `run-summary.md` with metadata

### Phase 2: Wave Computation
1. Build dependency graph from `deps` fields
2. Topological sort into wave groups
3. Flows in the same wave have no mutual deps and can run in parallel

### Phase 3: Wave Dispatch (Background, Context-Efficient)
For each wave (sequential):
1. Check for SKIPs: if any flow depends on a FAILed flow, mark SKIP
2. Dispatch `test-wave-agent` via Task tool with **`run_in_background: true`**:
   - Flow definitions (steps, key-elements, verify)
   - Run directory paths (screenshots/, logs/, flows/)
   - Device info and workarounds
   - Previous wave results (1-line-per-flow status only — NOT full details)
3. Wait for agent using `TaskOutput(task_id, block=true)` — **call exactly once**
4. Agent returns **1-line-per-flow status** (see wave agent Return Format). Do NOT request or process anything beyond this.
5. Record pass/fail/skip per flow from the status lines. That's it — no further parsing.

### Phase 4: Finalize
1. Compile `run-summary.md` from the 1-line status results already in memory — **do NOT re-read flow reports from disk**
2. Capture full session logcat to `logs/full-session.log`
3. Report to user using the Chat Summary Format from output-format.md (pass/fail/skip counts, failure one-liners, report path)
4. **Only read `flows/{flow}.md` from disk if the user asks** to investigate a specific failure

## Data Flow

```
Orchestrator (top-level)              Wave Agent (background)
    |                                      |
    |-- create run directory               |
    |-- write run-summary.md header        |
    |-- dispatch wave 0                    |
    |   (Task, run_in_background=true) --->|
    |                                      |-- execute flow steps
    |                                      |-- check logcat after every step
    |                                      |-- write flows/{flow}.md to DISK
    |                                      |-- save screenshots to DISK
    |                                      |-- save logcat to DISK
    |                                      |-- file defects on failure to DISK
    |   <-- 1-line-per-flow status ------- |  (minimal return, ~3-5 lines total)
    |   (TaskOutput, block=true, once)     |
    |                                      |
    |-- dispatch wave 1 (same pattern) --->|
    |   ...                                |
    |                                      |
    |-- compile run-summary.md             |
    |   (from status lines in memory,      |
    |    NOT by re-reading disk)           |
    |-- report to user (chat summary)      |
    |                                      |
    |   User asks "what failed in X?" ---> |
    |-- THEN read flows/X.md from disk     |
```

## Output Structure

See `.claude/skills/test/references/output-format.md` for complete format documentation.

```
.claude/test-results/
  YYYY-MM-DD_HHmm_{descriptor}/
    run-summary.md
    screenshots/{flow}-{step:02d}-{desc}.png
    logs/{flow}-logcat.log
    logs/full-session.log
    flows/{flow}.md
```

## Device Workarounds (Baked In)

These are passed to every wave agent automatically:

| Issue | Workaround |
|-------|------------|
| Android 15 screencap broken | `adb exec-out screencap -p > local.png` (not `/sdcard/`) |
| Git Bash `/sdcard/` mangling | `MSYS_NO_PATHCONV=1` prefix on all ADB commands with `/sdcard/` |
| Flutter Keys -> no resource-id | Use `content-desc` / `text` attributes; vision fallback |
| Samsung ENTER key | Avoid `KEYCODE_ENTER`; tap buttons directly |

## Reference Documents

| Document | Location |
|----------|----------|
| Flow Registry | `.claude/test-flows/registry.md` |
| Output Format | `.claude/skills/test/references/output-format.md` |
| ADB Commands | `.claude/skills/test/references/adb-commands.md` |
| UIAutomator Parsing | `.claude/skills/test/references/uiautomator-parsing.md` |
| Wave Agent | `.claude/agents/test-wave-agent.md` |

## Model Selection

| Agent | Model | Rationale |
|-------|-------|-----------|
| Top-level orchestrator | Opus (inherited) | Parses complex flag logic, coordinates waves |
| Wave agents | Haiku | Fast, cheap, sufficient for ADB commands + vision |

## Prerequisites

- USB-connected Android device with USB debugging enabled
- `adb` available in PATH
- Flutter SDK available (for APK build)
- `pwsh` available (for Flutter build commands)

## Retention

Only the 5 most recent test run directories are kept. The orchestrator deletes older runs at the start of each invocation.
