# Security Review v3: Sync Verification System Plan

**Date**: 2026-03-23
**Reviewer**: Security Agent (Opus 4.6)
**Previous**: v2 APPROVE WITH CONDITIONS (1 Critical SEC-001, 4 High, 5 Medium, 2 Low)
**Plan**: `.claude/plans/2026-03-22-sync-verification-system.md` (2935 lines, fully read)
**Cross-referenced**: `lib/core/driver/driver_server.dart`, `tools/debug-server/server.js`, `.env`, `.gitignore`, `tools/build.ps1`

## Verdict: APPROVE WITH CONDITIONS

The plan addressed 7 of 12 v2 security findings directly in code. Five findings have correct remediation text but plan code was NOT updated (pattern: review finding blocks present but implementable code unchanged). Two new issues found. No critical blockers remain IF the implementer follows review finding TEXT where code disagrees.

**Conditions (must be met during implementation):**
1. SEC-013 (MEDIUM): Add `.env.test` to `.gitignore` explicitly
2. SEC-002/SEC-003: Implementer MUST follow review finding text for PostgREST injection and table allowlist
3. SEC-014: Fix `assert` imports in template and L3 scenarios to `verify`

| Severity | v2 Fixed | v2 Still Open | New | Total |
|----------|----------|---------------|-----|-------|
| CRITICAL | 1 | 0 | 0 | 0 |
| HIGH | 2 | 2 | 0 | 2 |
| MEDIUM | 2 | 3 | 2 | 5 |
| LOW | 2 | 0 | 1 | 1 |

---

## Section 1: v2 Fix Verification

| Finding | Status | Evidence |
|---------|--------|----------|
| SEC-001 (CRITICAL): `.env.test` not `.env` | **FIXED** (with caveat) | Plan line 1671: `require('dotenv').config({ path: require('path').join(__dirname, '.env.test') })`. Plan line 1475-1478: review finding text is clear. **Caveat**: `.env.test` is NOT in `.gitignore` — see SEC-013. |
| SEC-002 (HIGH): PostgREST injection | **TEXT FIXED, CODE BROKEN** | Review finding at plan:983-986 says to validate with `^[a-z_][a-z0-9_]*$` and `encodeURIComponent()`. But `queryRecords()` at plan:1026-1032 still does raw `${key}=${val}` interpolation. Implementer must follow finding text. |
| SEC-003 (HIGH): Table name allowlist on SupabaseVerifier | **TEXT FIXED, CODE BROKEN** | Review finding at plan:988-991 says add `SYNCED_TABLES` constant. But `getRecord()` (plan:1014), `insertRecord()` (plan:1092), `updateRecord()` (plan:1104), `deleteRecord()` (plan:1081) accept arbitrary table names. No allowlist in code. Implementer must follow finding text. |
| SEC-004 (HIGH): Sanitized error responses | **FIXED** | All 5 new driver endpoint catch blocks return generic messages: `'Sync failed'` (plan:770), `'Query failed'` (plan:816, 848, 944), `'Insert failed'` (plan:905). Full exception logged via `Logger.sync()` only. |
| SEC-005 (HIGH): `kReleaseMode` guards | **FIXED** | All 5 endpoints have `if (kReleaseMode || kProfileMode)` at plan lines 750, 780, 826, 858, 920. Matches existing pattern from `driver_server.dart:61,658,738`. |
| SEC-006 (MEDIUM): ReDoS on regex filter | **STILL BROKEN** | Plan line 1555: `new RegExp(this.filter).test(s.name)` — no try/catch, no length limit. Same as v2. |
| SEC-007 (MEDIUM): Cleanup retry/verification | **STILL BROKEN** | Plan lines 1443-1453: `cleanup()` still catches and logs with "Best-effort cleanup" — no retry, no post-run verification query. |
| SEC-008 (MEDIUM): Column validation via PRAGMA | **FIXED** | Plan lines 882-895: validates column names against regex `^[a-z_][a-z0-9_]*$` AND `PRAGMA table_info($table)` results. Both checks present. |
| SEC-009 (MEDIUM): company_id from env | **FIXED** | Plan line 1394: `company_id: process.env.COMPANY_ID || (() => { throw new Error('COMPANY_ID env var required'); })()`. Throws if missing. |
| SEC-010 (MEDIUM): L3 multi-device | **TEXT FIXED, CODE BROKEN** | Review finding at plan:2139-2156 is comprehensive and correct. But ALL 10 L3 scenario code blocks (plan:2174-2769) still use `{ verifier, device }` (single device) instead of `{ verifier, adminDevice, inspectorDevice }`. X1-X7 are single-device tests, X8-X9 don't use per-role JWT. Implementer must follow finding text, not code. |
| SEC-011 (LOW): SYNCTEST- prefix | **FIXED** | Plan line 1319: `testPrefix()` returns `SYNCTEST-${scenario}-${table}-${Date.now().toString(36)}`. Plan line 1396: `makeProject` uses `SYNCTEST-` prefix. Plan line 1430: `makeLocation` uses `SYNCTEST-` prefix. |
| SEC-012 (LOW): /test-status global | **ACCEPTED** | Plan line 2819-2823: uses `global._lastTestResults`. Consistent with debug-only server design. No auth needed for loopback. |

**Pattern observed**: 3 of 12 findings have correct review finding TEXT but the actual code blocks below them were never updated (SEC-002, SEC-003, SEC-010). The implementer must prioritize review finding text over code blocks in these cases.

---

## Section 2: New Security Issues

### SEC-013 (MEDIUM): `.env.test` not covered by `.gitignore`
- **Domain**: 1 (Credential Exposure)
- **Severity**: MEDIUM
- **Location**: `.gitignore` lines 53-55; plan line 1478 instructs adding to `.gitignore`
- **Issue**: Current `.gitignore` has `.env` (matches root `.env`), `*.env` (matches `foo.env`), `*.env.local` (matches `foo.env.local`). None of these patterns match `tools/debug-server/.env.test` because that file ends in `.test`, not `.env`. If the implementer creates `.env.test` with the service role key and forgets to add a gitignore entry, it could be committed.
- **Impact**: Service role key committed to git. Not as severe as SEC-001 (APK embedding) but still exposes full RLS bypass credentials in repo history.
- **Fix**: Add `**/.env.test` or `*.env.*` to `.gitignore` in Phase 7A. The plan's review finding at line 1478 mentions "Add `tools/debug-server/.env.test` to `.gitignore`" but Phase 7A steps (plan:2810-2814) don't include this action.

### SEC-014 (MEDIUM): Template and L3 scenarios import `assert` which doesn't exist
- **Domain**: 4 (Data Integrity)
- **Severity**: MEDIUM
- **Location**: Plan lines 2070, 2314, 2443, 2489, 2579, 2642
- **Issue**: Six code blocks destructure `assert` from `scenario-helpers.js`, but the module exports `verify` (not `assert`). Destructuring a non-existent named export in Node.js yields `undefined`. Any call to `assert(condition, message)` will throw `TypeError: assert is not a function` — BUT only at the point of the assertion call, not at import time. If a code path skips the assertion call (e.g., happy path), the test passes without actually validating anything.
- **Impact**: Test scenarios that import `assert` instead of `verify` will either crash on first assertion (false positive — looks like a test failure, not a bug) or silently skip validation if the assertion is in an error branch. Either way, it undermines test reliability.
- **Fix**: Replace `assert` with `verify` in all import destructurings. The template at plan:2070 is especially important since it generates 79 files.

### SEC-015 (LOW): DeviceOrchestrator has no auth token header (H5 code not implemented)
- **Domain**: 5 (Network Security)
- **Severity**: LOW (loopback only, defense-in-depth)
- **Location**: Plan line 1262
- **Issue**: The H5 review finding (plan:1161-1164) instructs adding `X-Driver-Token` to DeviceOrchestrator `_request()` headers and DriverServer. The code at plan:1262 still only has `Content-Type`. This is defense-in-depth (DriverServer binds to loopback), but any local process could send commands.
- **Fix**: Implementer should follow H5 review finding text.

---

## Section 3: Observations (Not Findings)

**Port inconsistency** (correctness, not security): `DeviceOrchestrator` constructor defaults to port 3948 (plan:1181, per spec), but `TestRunner` overrides to 4948 (plan:1513). The spec says 3948 for Windows and 3949 for Samsung. The implementer should follow the spec.

**Existing driver_server.dart catch-all** (pre-existing): `driver_server.dart:129` has `{'error': e.toString()}` in the global catch handler. This pre-dates the plan and should be addressed separately, but all NEW endpoints in this plan correctly sanitize their error responses.

**SupabaseVerifier `_request` error messages** (low risk): Plan line 1137 includes the full Supabase response body in error messages: `Supabase ${method} ${parsed.pathname}: ${res.statusCode} ${data}`. This runs server-side in Node.js (not client-facing), so it's acceptable for debug infrastructure. Schema details could appear in console output but not in test reports.

---

## OWASP Mobile Top 10 Scorecard (Test Infrastructure)

| # | Risk | Status | Findings |
|---|------|--------|----------|
| M1 | Improper Credential Usage | **PASS** | SEC-001 FIXED (`.env.test`). SEC-013 is gitignore gap, not credential misuse. |
| M2 | Inadequate Supply Chain | PASS | No new dependencies |
| M3 | Insecure Auth/Authz | PARTIAL | H5 auth token not in code; SEC-010 RLS tests still single-device |
| M4 | Insufficient Input Validation | PARTIAL | SEC-008 FIXED; SEC-002, SEC-006 still open |
| M5 | Insecure Communication | PASS | Loopback binding + HTTPS to Supabase |
| M6 | Inadequate Privacy Controls | PASS | Synthetic test data with SYNCTEST- prefix |
| M7 | Insufficient Binary Protections | PASS | SEC-005 FIXED (kReleaseMode guards) |
| M8 | Security Misconfiguration | PASS | SEC-004 FIXED (sanitized errors) |
| M9 | Insecure Data Storage | PASS | Test data only, existing SQLite |
| M10 | Insufficient Cryptography | N/A | No crypto operations |

---

## Positive Observations

1. SEC-001 remediation is architecturally sound — complete separation of test credentials from build credentials
2. All 5 new driver endpoints have consistent `kReleaseMode || kProfileMode` guards matching existing patterns
3. Error responses are properly sanitized with generic messages + server-side logging
4. Column validation on `/driver/create-record` uses both regex AND PRAGMA — defense in depth
5. `makeProject()` throws on missing `COMPANY_ID` instead of falling back to a hardcoded value
6. `testPrefix()` correctly generates `SYNCTEST-` prefixed identifiers for data isolation
7. Junction table `/driver/create-record` has a tight 4-table allowlist (not the full 17)
8. Plan correctly uses `deleted_at`/`deleted_by` throughout (not the incorrect `is_deleted`)

---

## Remediation Priority

1. **During implementation** (implementer discipline):
   - SEC-002: Add input validation to `queryRecords()` per review finding text
   - SEC-003: Add `SYNCED_TABLES` allowlist to SupabaseVerifier per review finding text
   - SEC-010: Rewrite L3 scenarios with two-device signatures per C1 review finding text
   - SEC-013: Add `**/.env.test` to `.gitignore`
   - SEC-014: Fix `assert` to `verify` in template and 6 L3 scenario files

2. **This sprint** (backlog):
   - SEC-006: Wrap `new RegExp(this.filter)` in try/catch with 100-char length limit
   - SEC-007: Add retry logic to `cleanup()` + post-run verification query
   - SEC-015: Add `X-Driver-Token` header per H5 finding

---

## Automated Detection Opportunities

| Finding | Detectable? | Method |
|---------|------------|--------|
| SEC-001 (`.env.test` in root `.env`) | Yes | Pre-commit hook: reject `.env` containing `SERVICE_ROLE_KEY` |
| SEC-002 (PostgREST injection) | Yes | ESLint custom rule: flag template literals in URL construction without `encodeURIComponent` |
| SEC-003 (table allowlist) | Partial | Code review: grep for `rest/v1/${table}` without prior allowlist check |
| SEC-006 (ReDoS) | Yes | ESLint: flag `new RegExp(userInput)` without try/catch |
| SEC-013 (`.env.test` gitignored) | Yes | CI check: `git ls-files --cached '*.env.*'` should return empty |
| SEC-014 (`assert` import) | Yes | `grep -rn "assert," tools/debug-server/scenarios/` — any match is a bug |

---

## Files Referenced

| File | Relevance |
|------|-----------|
| `.claude/plans/2026-03-22-sync-verification-system.md` | Plan under review (2935 lines, fully read) |
| `lib/core/driver/driver_server.dart` | Existing driver patterns, kReleaseMode guards, catch-all handler |
| `tools/debug-server/server.js` | Existing debug server patterns, loopback binding |
| `.env` | Root env file (currently safe: 2 keys only) |
| `.gitignore` | Missing `.env.test` pattern |
| `tools/build.ps1` | `--dart-define-from-file=.env` at line 78 |
| `.claude/code-reviews/2026-03-23-sync-verification-plan-v2-security-review.md` | Previous v2 security review |
| `.claude/code-reviews/2026-03-23-sync-verification-plan-v2-code-review.md` | Previous v2 code review |
