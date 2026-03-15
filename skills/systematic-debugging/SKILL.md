---
name: systematic-debugging
description: Log-first root cause analysis framework with HTTP server integration, hypothesis tagging, and structured cleanup gates
user-invocable: true
---

# Systematic Debugging Skill

**Purpose**: Interactive root cause analysis framework with log-first investigation. Investigates bugs WITH the user, never autonomously.

## CRITICAL: This Skill Is Interactive

**This skill runs in the main conversation.** Code changes require explicit user approval.

- **Show progress** at every step — the user must see what you're doing
- **Present findings** after each phase before moving on
- **NEVER write code** without explicit user approval
- **NEVER skip to implementation** — investigation comes first, always
- **Deep mode only**: subagents run for parallel read-only research

## Iron Law

> **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST**

Every fix must be preceded by understanding WHY the bug exists. Guessing wastes time and creates new bugs.

---

## Entry: Choose Debug Mode

**Ask the user before starting:**

> "Quick mode (direct investigation, no server needed) or Deep mode (log server + background research agent)?"

| Mode | Use When | Setup |
|------|----------|-------|
| Quick | Clear repro, no race conditions, obvious error | None |
| Deep | Intermittent bug, state corruption, async timing, unknown origin | Start debug server, launch research agent |

**Deep mode setup** (do before Phase 1):
1. Load reference files (see below)
2. Launch `debug-research-agent` with `run_in_background: true`, passing the issue description and suspected code paths
3. Continue with Phase 1 while agent researches in parallel

**Reference files** (load on entry):
- `@.claude/skills/systematic-debugging/references/log-investigation-and-instrumentation.md`
- `@.claude/skills/systematic-debugging/references/codebase-tracing-paths.md`
- `@.claude/skills/systematic-debugging/references/defects-integration.md`
- `@.claude/skills/systematic-debugging/references/debug-session-management.md`

---

## Phase 1: TRIAGE

**Goal**: Establish clean baseline before touching anything.

### 1.1 Scan for orphaned hypothesis markers

Search for leftover markers from previous sessions:

```bash
# Search entire codebase for hypothesis markers
Grep "hypothesis(" lib/ --output_mode=files_with_matches
```

If any found: list them to the user. Ask if they belong to this session or are orphaned. Orphaned markers MUST be removed before continuing.

### 1.2 Check server health (Deep mode only)

```bash
curl http://127.0.0.1:3947/health
```

Expected response: `{"status":"ok","entries":N,"maxEntries":30000,"memoryMB":N,"uptimeSeconds":N}`

If server not running, prompt user to start it:
```
node tools/debug-server/server.js
```

For Android devices, set up ADB port forwarding:
```
adb reverse tcp:3947 tcp:3947
```

### 1.3 Clear previous session logs (Deep mode only)

```bash
curl -X POST http://127.0.0.1:3947/clear
```

This ensures evidence from this session is not mixed with old data.

### 1.4 Check known defects

Read `.claude/defects/_defects-{feature}.md` for the relevant feature. Check categories: `[ASYNC]`, `[SYNC]`, `[DATA]`, `[CONFIG]`, `[SCHEMA]`, `[FLUTTER]`, `[E2E]`, `[MIGRATION]`.

If a known pattern matches: apply documented prevention. May resolve without further investigation.

**Present triage findings to user before Phase 2.**

---

## Phase 2: COVERAGE CHECK

**Goal**: Understand what the Logger already captures in the relevant code path.

### 2.1 Identify the code path

Use codebase-tracing-paths.md to map the likely flow. Example: "Sync not pushing entries" → SyncProvider → SyncOrchestrator → SyncEngine → TableAdapter.

### 2.2 Assess existing Logger coverage

For each file in the path:
```bash
Grep "Logger\." lib/features/sync/engine/sync_engine.dart --output_mode=content
```

Note: which entry/exit points are already logged? Which boundaries have no coverage?

### 2.3 Identify gaps

List boundaries that have zero Logger calls. These are blind spots where the bug could hide undetected.

**Present coverage map to user before Phase 3.**

---

## Phase 3: INSTRUMENT GAPS

**Goal**: Add targeted instrumentation so the bug leaves evidence.

### 3.1 Add hypothesis markers at key boundaries

Use `Logger.hypothesis()` for temporary markers scoped to this session:

**Auth restriction**: NEVER log tokens, passwords, API keys, or session secrets — even in hypothesis markers. See auth blocklist in log-investigation-and-instrumentation.md.

```dart
Logger.hypothesis('H001', 'sync', 'SyncEngine.push entry point', data: {
  'pendingCount': pendingChanges.length,
  'userId': currentUserId,
});
```

Naming convention: `H001`, `H002`, etc. (reset each session).

### 3.2 Fill permanent Logger gaps

If a code boundary has no Logger coverage at all (not just missing hypothesis markers), add a permanent Logger call using the appropriate category:

```dart
Logger.sync('SyncEngine.push', data: {'table': tableName, 'operation': op});
```

These are KEPT after the session (they fill genuine coverage gaps).

### 3.3 Rebuild app

Deep mode (Android):
```
pwsh -Command "flutter run -d <device> --dart-define=DEBUG_SERVER=true"
```

Windows:
```
pwsh -Command "flutter run -d windows --dart-define=DEBUG_SERVER=true"
```

**Do NOT use `--dart-define=DEBUG_SERVER=true` in release builds.**

---

## Phase 4: REPRODUCE

**Goal**: Get clean, reliable reproduction with logs flowing.

### 4.1 User interview

Ask the user these five questions before they reproduce:

1. What exact steps trigger the bug?
2. How often does it happen (always, intermittent, first-launch only)?
3. What device/platform?
4. When did this last work correctly?
5. What changed since it last worked (commits, data, permissions)?

### 4.2 ADB health check (Android only)

```bash
adb devices
adb reverse tcp:3947 tcp:3947
```

Confirm device is listed and port forwarding is active.

### 4.3 Guide reproduction

Have the user follow the exact steps. Watch for any app crash output in the terminal. Confirm log entries are flowing to the server:

```bash
curl "http://127.0.0.1:3947/logs?last=5"
```

If no entries appear: the app is not reaching the server. Check ADB forwarding, DEBUG_SERVER flag, and server status.

---

## Phase 5: EVIDENCE ANALYSIS

**Goal**: Read log evidence to form a data-driven hypothesis.

### 5.1 Fetch hypothesis-tagged logs

```bash
curl "http://127.0.0.1:3947/logs?hypothesis=H001&last=100"
curl "http://127.0.0.1:3947/logs?hypothesis=H002&last=100"
```

### 5.2 Fetch by category

```bash
curl "http://127.0.0.1:3947/logs?category=sync&last=50"
curl "http://127.0.0.1:3947/logs?category=error&last=20"
```

### 5.3 Check available categories

```bash
curl http://127.0.0.1:3947/categories
```

### 5.4 Read agent research (Deep mode)

If the research agent has completed, read its output. Integrate its findings with the log evidence.

### 5.5 Identify the failure point

The failure point is where expected log entries STOP appearing or where values diverge from expected. Document:
- Last correct log entry (file:line, hypothesis ID, value)
- First incorrect/missing log entry
- Any error entries in the error category

### 5.6 Quick mode investigation

Without a log server, use:
```bash
# ADB logcat for Android
adb logcat -s flutter | grep -i error

# Flutter console (terminal running flutter run)
# Look for exceptions and stack traces
```

---

## Phase 6: ROOT CAUSE REPORT

**Goal**: Present findings for user approval before touching any code.

### Report format

Present a structured report:

```
ROOT CAUSE ANALYSIS

Bug: [one-sentence description]

Evidence:
- H001 fired at sync_engine.dart:142 with pendingCount=3
- H002 never fired → push() not reached
- Error log: "FK constraint failed" at 14:23:05.441

Root Cause:
The sync engine is not calling push() when pendingCount > 0 because [specific condition].
The upstream origin is [file:line] where [condition] prevents the call.

Proposed Fix:
[Describe the fix — do NOT implement yet]

Files that would change:
- lib/features/sync/engine/sync_engine.dart (line ~142)

Risk: Low / Medium / High — [reason]
```

### USER GATE — stop here

**STOP. Present the report. Wait for user approval.**

User options:
- "Approved" → proceed to Phase 7
- "Investigate more" → return to Phase 5
- "Wrong direction" → return to Phase 2
- "Defer" → skip to Phase 9 (cleanup only)

**NEVER auto-proceed to implementation.**

---

## Phase 7: FIX

**Goal**: Implement the approved fix and verify it resolves the bug.

### 7.1 Implement fix

Apply the approved changes. One change at a time.

### 7.2 Clear logs

```bash
curl -X POST http://127.0.0.1:3947/clear
```

### 7.3 Verify fix

Have the user reproduce the original steps. Confirm:
- Bug no longer occurs
- Hypothesis markers show the new correct flow
- No new errors in error category

```bash
curl "http://127.0.0.1:3947/logs?category=error&last=20"
```

### 7.4 Check for regressions

Run targeted tests for the affected feature:
```bash
pwsh -Command "flutter test test/features/{feature}/"
```

---

## Phase 8: INSTRUMENTATION REVIEW

**Goal**: Decide which markers to keep and which to remove.

### For each hypothesis marker added in Phase 3:

| Decision | Criteria |
|----------|----------|
| REMOVE | Temporary hypothesis tag (H001, H002, etc.) — always remove |
| KEEP | Fills a genuine permanent coverage gap with no other Logger call at that boundary |

Present a table to the user:

```
Marker  | File:Line           | Decision | Reason
H001    | sync_engine.dart:142 | REMOVE   | Hypothesis confirmed, gap now covered by H002's permanent replacement
H002    | sync_engine.dart:198 | KEEP     | No other Logger.sync() at this push() entry point
```

Wait for user confirmation on any "KEEP" decisions.

---

## Phase 9: CLEANUP HARD GATE

**This phase is MANDATORY. It cannot be skipped.**

### 9.1 Remove ALL hypothesis markers

For every marker marked REMOVE in Phase 8:

1. Find and delete the `Logger.hypothesis()` call
2. Verify the file compiles (no dangling variables)

### 9.2 Global search — no markers left behind

```bash
Grep "hypothesis(" lib/ --output_mode=files_with_matches
```

**If this returns ANY results: stop. Remove remaining markers. Re-run search.**

Zero results required to proceed.

### 9.3 Write session log

Create a scrubbed session log at `.claude/debug-sessions/YYYY-MM-DD_{bug-slug}.md`:

```markdown
# Debug Session: {bug-slug}
Date: YYYY-MM-DD
Duration: ~Xh
Mode: Quick / Deep

## Bug
[One-sentence description]

## Root Cause
[Finding, with file:line references]

## Fix Applied
[What was changed and why]

## Markers Added (Permanent)
- Logger.sync() at sync_engine.dart:198 — push() entry coverage

## Markers Removed
- H001, H002 — hypothesis confirmed and removed
```

**Scrubbing rules**: No user data, no actual log values that could contain PII, no credentials.

### 9.4 Prune 30-day retention

Check `.claude/debug-sessions/` for session logs older than 30 days. List any found and ask user to confirm deletion.

---

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

---

## Red Flags — STOP and Return to Phase 1

These thought patterns mean you're off-track:

- "Let me just try one more thing…"
- "I think I see the problem" (before log evidence confirms it)
- "This is probably caused by…" (without data)
- "The fix didn't work but the next one will"
- Starting to modify code before you can explain WHY the bug exists

## Stop Conditions

**STOP and reassess if:**
- 3+ failed fix attempts — likely architectural issue
- Fix requires changing 5+ files — scope too broad, needs plan
- You can't explain root cause in one sentence — go back to Phase 5
- "Fix" suppresses symptoms without addressing cause

## User Signals

| User says | Your response |
|-----------|---------------|
| "Stop guessing" | Return to Phase 5. State evidence you have and what's unknown. |
| "Ultrathink this" | Reason through full system before touching code. |
| "Walk me through it" | Explain data flow from log evidence, not assumption. |
| "You've been on this too long" | Summarize hypotheses, what's ruled out, ask for guidance. |

## Rationalization Prevention

| If You Think... | Stop And... |
|-----------------|-------------|
| "Let me just try this quick fix" | Form a hypothesis first, check Phase 5 |
| "I'll add a retry and see if it helps" | Find the root cause |
| "The tests are flaky, I'll skip them" | Find why they're flaky |
| "One more fix and it'll work" | Count attempts — if ≥ 3, STOP |
| "I see the problem" | Verify with log evidence before touching code |
| "The pattern is too long to trace fully" | That's exactly when you must trace it |

## Quick Reference

| Phase | Goal | Hard Gate |
|-------|------|-----------|
| Entry | Choose mode, load refs | Ask user |
| 1 TRIAGE | Clean baseline | Present findings |
| 2 COVERAGE CHECK | Map Logger coverage | Present coverage map |
| 3 INSTRUMENT GAPS | Add hypothesis markers | Auth restriction enforced |
| 4 REPRODUCE | Get clean repro | User confirms repro |
| 5 EVIDENCE ANALYSIS | Read log data | Identify failure point |
| 6 ROOT CAUSE REPORT | Present findings | USER GATE — wait for approval |
| 7 FIX | Implement approved fix | Verify + regression check |
| 8 INSTRUMENTATION REVIEW | Keep vs remove decision | User confirms keeps |
| 9 CLEANUP | Remove ALL hypothesis() | Global search must return zero |
| 10 DEFECT LOG | Record new patterns | — |
