# Security Audit: Sync Verification System Plan (V2)

**Plan**: `.claude/plans/2026-03-22-sync-verification-system.md`
**Spec**: `.claude/specs/2026-03-22-sync-verification-system-spec.md`
**Date**: 2026-03-23
**Scope**: Adversarial security review of test infrastructure plan
**Previous Review**: Inline REVIEW FINDING blocks (C1-C4, H1-H6) from code review agent

---

## Verdict: APPROVE WITH CONDITIONS

The plan's security posture is adequate for a dev-only test harness, with one critical exception: the service role key must NOT go into the project root `.env` file, which is consumed by `--dart-define-from-file` and compiled into app binaries. Three conditions must be met before implementation.

**Conditions:**
1. SEC-001 (CRITICAL): Service role key uses separate `.env.test`, NOT root `.env`
2. SEC-005 (HIGH): New driver endpoints include `kReleaseMode` guard
3. SEC-003 (HIGH): SupabaseVerifier validates table names against allowlist

---

## Findings by Severity

### CRITICAL (1)

**SEC-001: Service role key will be compiled into app binaries via `--dart-define-from-file`**
- **Domain**: 1 (Credential Exposure)
- **Location**: Plan line 1662 (`run-tests.js`); spec line 419; `tools/build.ps1:78`
- **Issue**: `run-tests.js` loads credentials via `require('dotenv').config({ path: '../../.env' })` — the project root `.env`. `build.ps1:78` passes this identical file via `--dart-define-from-file=.env` to every Flutter build. ALL key=value pairs from `.env` become compile-time Dart constants, embedded in the binary's constant pool — extractable via `strings` on any APK. If `SUPABASE_SERVICE_ROLE_KEY` is added to `.env` (as both the spec and plan instruct), it will be baked into every debug AND release build.
- **Impact**: Service role key bypasses ALL RLS policies. Anyone decompiling the APK gets full read/write access to every row in Supabase. This is the exact pattern behind CVE-2025-48757 (Lovable incident, 170+ apps exposed).
- **Fix**: Create a separate `tools/debug-server/.env.test` (gitignored) for test-only credentials: `SUPABASE_SERVICE_ROLE_KEY`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `INSPECTOR_EMAIL`, `INSPECTOR_PASSWORD`, `DRIVER_AUTH_TOKEN`, `COMPANY_ID`. Update `run-tests.js` to load from `path.join(__dirname, '.env.test')`. Add `tools/debug-server/.env.test` to `.gitignore`. Root `.env` must contain ONLY `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- **Auto-detectable**: Yes — pre-commit hook rejecting `.env` containing `SERVICE_ROLE_KEY`; CI check `.env` has exactly 2 keys.

---

### HIGH (4)

**SEC-002: PostgREST parameter injection in SupabaseVerifier.queryRecords()**
- **Domain**: 8 (Sync Integrity)
- **Location**: Plan lines 1028-1033 (`supabase-verifier.js`)
- **Issue**: Filter keys and values are string-interpolated into the PostgREST URL without sanitization. A buggy scenario could inject arbitrary PostgREST operators. These requests use the service role key.
- **Fix**: Validate filter keys against `^[a-z_][a-z0-9_]*$`. URL-encode values via `encodeURIComponent()`.

**SEC-003: No table name allowlist on SupabaseVerifier CRUD methods**
- **Domain**: 8 (Sync Integrity)
- **Location**: Plan lines 1016-1109 (`supabase-verifier.js`)
- **Issue**: `getRecord()`, `insertRecord()`, `updateRecord()`, `deleteRecord()` accept arbitrary table names. With service role, test code can read/write ANY table including `auth.users` or `storage.objects`.
- **Fix**: Add a `SYNCED_TABLES` constant (17 tables) and reject unknown tables. `deleteRecord()` is especially dangerous.

**SEC-004: Error responses leak internal state via `e.toString()`**
- **Domain**: 5 (Network Security)
- **Location**: Plan lines 819, 857, 883, 925, 957 (all new driver endpoints)
- **Issue**: Every catch block returns `{'error': e.toString()}`. Dart exceptions include stack traces, file paths, database schema details.
- **Fix**: Return `{'error': 'Internal error', 'type': e.runtimeType.toString()}`. Log full exception via `Logger.error()`.

**SEC-005: New driver endpoints missing `kReleaseMode` defense-in-depth guard**
- **Domain**: 7 (Manifest Security)
- **Location**: Plan lines 806-958 (Phase 2B, all 5 endpoints)
- **Issue**: Existing driver endpoints each have `if (kReleaseMode || kProfileMode)` guards. The 5 new endpoints omit this.
- **Fix**: Add `if (kReleaseMode || kProfileMode) return _jsonResponse(request, 403, ...)` at the top of each handler.

---

### MEDIUM (5)

**SEC-006: `run-tests.js` filter enables ReDoS via user-supplied regex**
- **Location**: Plan line 1547 (`test-runner.js`)
- **Fix**: Wrap in try/catch; reject patterns longer than 100 chars.

**SEC-007: Test data cleanup is best-effort with silent failures**
- **Location**: Plan lines 1440-1449 (`scenario-helpers.js`)
- **Fix**: Add retry with backoff. Add post-run verification query for remaining SYNCTEST- records.

**SEC-008: Column name regex allows SQL reserved words**
- **Location**: Plan lines 911-916 (`/driver/create-record`)
- **Fix**: Validate column names against `PRAGMA table_info({table})` results.

**SEC-009: `makeProject()` hardcodes `'test-company'` despite H6 review finding**
- **Location**: Plan line 1394 (`scenario-helpers.js`)
- **Issue**: Code still has `company_id: 'test-company'`. X8/X9 RLS tests will produce false negatives.
- **Fix**: `company_id: process.env.COMPANY_ID || (() => { throw new Error('COMPANY_ID required'); })()`.

**SEC-010: L3 scenario code still single-device despite C1 review finding**
- **Location**: Plan lines 2164-2758 (Phase 6A)
- **Issue**: All code blocks still use `{ verifier, device }` and implement wrong scenarios. X8/X9 RLS validation cannot work.
- **Fix**: Implementer must follow C1 review finding TEXT, not code blocks.

---

### LOW (2)

**SEC-011: `testPrefix()` returns `test-` not `SYNCTEST-`**
- **Location**: Plan lines 1320-1322
- **Fix**: Implement H3a as stated.

**SEC-012: Debug server `/test-status` stores results in global with no auth**
- **Location**: Plan lines 2808-2812
- **Fix**: None needed — consistent with existing design.

---

## Verification of Previous Review Findings

| Finding | Text Adequate? | Code Updated? | Security Impact |
|---------|---------------|---------------|-----------------|
| C1 (L3 wrong scenarios) | Yes | **NO** | SEC-010: zero RLS validation |
| C2 (L1 wrong file names) | Yes | N/A | None (naming only) |
| C3 (missing per-role JWT) | Yes | N/A (no code yet) | Sound approach |
| C4 (missing remove-from-device) | Yes | N/A | None |
| H1 (S2-S5 semantics wrong) | Yes | N/A | None (correctness) |
| H2 (Phase 7 empty cleanup) | Yes | N/A | None |
| H3a (SYNCTEST- naming) | Yes | **NO** | SEC-011: cleanup unreliable |
| H3b (CLI missing flags) | Yes | N/A | None |
| H4 (column name injection) | Yes | Yes | SEC-008: fragile but safe |
| H5 (no driver auth token) | Yes | N/A (no code yet) | Sound approach |
| H6 (hardcoded company_id) | Yes | **NO** | SEC-009: RLS tests invalid |

**Pattern**: Three review findings (C1, H3a, H6) have correct remediation text but plan code was never updated. Implementer must follow review finding TEXT over code blocks.

---

## OWASP Mobile Top 10 Scorecard (Test Infrastructure)

| # | Risk | Status | Findings |
|---|------|--------|----------|
| M1 | Improper Credential Usage | **FAIL** | SEC-001 |
| M2 | Inadequate Supply Chain | PASS | No new deps |
| M3 | Insecure Auth/Authz | PARTIAL | H5 sound; X8/X9 code broken (SEC-010) |
| M4 | Insufficient Input Validation | PARTIAL | H4 done; SEC-002, SEC-006 open |
| M5 | Insecure Communication | PASS | Loopback + HTTPS |
| M6 | Inadequate Privacy Controls | PASS | Synthetic test data |
| M7 | Insufficient Binary Protections | N/A | Test infra |
| M8 | Security Misconfiguration | PARTIAL | SEC-005 |
| M9 | Insecure Data Storage | PASS | Existing SQLite |
| M10 | Insufficient Cryptography | N/A | No crypto ops |

---

## Positive Observations

1. Five-layer DEBUG_SERVER gate is well-designed defense-in-depth
2. Table allowlists on driver endpoints prevent arbitrary table access
3. Origin header blocking in DriverServer prevents browser CSRF
4. Parameterized queries in `/driver/change-log` use `?` placeholders correctly
5. Existing photo injection has thorough validation
6. `.env` is gitignored and currently contains only publishable credentials

---

## Remediation Priority

1. **Immediate (blocks implementation)**: SEC-001 — separate `.env.test` file
2. **During implementation**: SEC-005, SEC-003, SEC-002
3. **Implementer discipline**: SEC-010, SEC-009, SEC-011 — follow review finding text, not code
4. **Backlog**: SEC-004, SEC-006, SEC-007, SEC-008
