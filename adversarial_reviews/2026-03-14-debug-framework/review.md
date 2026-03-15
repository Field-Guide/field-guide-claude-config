# Adversarial Review: Debug Framework

**Spec**: `.claude/specs/2026-03-14-debug-framework-spec.md`
**Date**: 2026-03-14
**Reviewers**: code-review-agent (opus), security-agent (opus)

---

## MUST-FIX (spec is broken without these)

### 1. `-ExtraDefines` doesn't exist in build script (Code Review)
The spec references `pwsh -File tools/build.ps1 -ExtraDefines "DEBUG_SERVER=true"` but `tools/build.ps1` only accepts `-Platform` and `-BuildType`. Either add the parameter or use `flutter run --dart-define=DEBUG_SERVER=true --dart-define-from-file=.env` directly.

### 2. Orphaned marker recovery on session start (Code Review)
If a Claude session crashes mid-debug, `#region debug-hypothesis` markers are left in code. Phase 1 (Triage) must scan for orphaned markers from previous interrupted sessions before starting.

### 3. Memory cap on server, not just entry count (Code Review)
A single log entry's `data` map could be 100KB+ (PDF pipeline, full row maps). 30k such entries = gigabytes. Need either per-entry size cap (~4KB) or total memory cap (~100MB).

### 4. Add `deviceId` field to log schema (Code Review)
With two Android devices (S21+, S25 Ultra), logs from both arrive at the same server with no way to distinguish. Add a `deviceId` field — costs nothing, prevents ambiguity.

### 5. Remove or qualify `source` field (Code Review)
Dart has no `__FILE__`/`__LINE__` macros. `StackTrace.current` is expensive. Specify that `source` is manually provided at call sites, or remove it from the schema.

### 6. Sensitive data filter on HTTP transport (Security)
**CRITICAL.** The `data` map is arbitrary — Claude will naturally log auth tokens, user PII, Supabase keys during debugging. Must add a blocklist filter scrubbing sensitive keys (`access_token`, `password`, `email`, `phone`, `cert_number`, etc.) before HTTP transport sends.

### 7. WiFi mode security contradiction (Both)
Spec says server binds `127.0.0.1` but WiFi mode requires `0.0.0.0`. Plaintext HTTP on shared WiFi = sniffable PII/tokens. **Recommendation: remove WiFi mode entirely.** ADB USB is sufficient.

### 8. Add `assert(!kReleaseMode)` to HTTP transport (Security)
Defense-in-depth against build misconfiguration enabling HTTP transport in release.

### 9. Block `DEBUG_SERVER` in build script for release builds (Security)
`.env` file could accidentally contain `DEBUG_SERVER=true`. Build script should check and fail for release builds.

### 10. Add `.claude/debug-sessions/` to config repo `.gitignore` (Security)
`.claude/` is tracked in `field-guide-claude-config`. Session logs with PII/tokens must not be committed.

---

## SHOULD-CONSIDER (better approach exists)

### 11. Quantify bare `debugPrint` migration (Code Review)
380 `debugPrint` calls across 50 files. Spec says "migrate feature by feature" but doesn't scope the work. Priority: providers first (29 of 30 use bare debugPrint).

### 12. Make research agent actually parallel (Code Review)
Spec says `run_in_background: false` but diagrams show "PARALLEL" — misleading. Either use `run_in_background: true` or acknowledge it's sequential.

### 13. Add SIGINT handler to server (Code Review)
Dump logs to `last-session.ndjson` on Ctrl-C. ~5 lines, prevents total log loss.

### 14. ADB reconnection check in Phase 4 (Code Review)
After user says "done reproducing," check `/health` before reading logs. Guide reconnection if ADB dropped.

### 15. `Logger.error()` default category for deprecation forwarding (Code Review)
Current `DebugLogger.error()` has no category. Forwarding layer needs a default (e.g., `'app'`).

### 16. Align `writeReport` signature (Code Review)
Current uses named params; spec uses positional. Need consistent API for deprecation forwarding.

### 17. Session log scrubber (Security)
Apply same sensitive key filter to session logs before writing to disk.

### 18. Cap `data` map size per entry (Security)
4KB serialized limit — truncate with `_truncated: true` and key list.

### 19. Document auth logging restrictions (Security)
`instrumentation-patterns.md` must explicitly ban logging session objects, user profiles, auth responses.

### 20. Session log retention policy (Security)
Prune sessions older than 30 days to prevent indefinite accumulation.

---

## NICE-TO-HAVE (optimization opportunities)

### 21. Add log level parameter to category methods (Code Review)
`Logger.sync('msg', level: Level.warning)` — maps to existing `level` field in schema.

### 22. Add `/export` NDJSON endpoint (Code Review)
30k entries as JSON array = 10MB+. NDJSON streams better.

### 23. Cap debug session directory (Code Review)
Keep only last 20 sessions.

### 24. Add `--port` CLI arg to server (Code Review)
`const port = parseInt(process.argv[2]) || 3947` — one line.

### 25. Consider combining reference files 1 and 3 (Code Review)
"Log-first investigation" and "instrumentation patterns" overlap. 4 files instead of 5.

### 26. Server startup security banner (Security)
Print binding info and sensitive data warning on start.

### 27. `--no-http` flag for file-only debugging (Security)
Allow opting out of HTTP transport when network is undesirable.

---

## Positive Observations

- Compile-time gating via `bool.fromEnvironment` with tree-shaking is correct and matches existing patterns
- Hypothesis tagging with region markers is a clever instrumentation lifecycle solution
- Coverage gap analysis is honest and accurately audited against codebase
- Security table is thorough for the primary (USB) use case
- Architecture reference in Section 7 is accurate and will prevent stale-reference problems
- Node.js server choice is correct — simpler than Dart alternative, zero dependencies
