# PR Compliance Fixes — Spec

**Date**: 2026-04-01
**Branch**: `feat/wiring-routing-rewire`
**Parent spec**: `.claude/specs/2026-03-30-wiring-routing-audit-fixes-spec.md`

## Overview

### Purpose
Close the gap between what the wiring-routing spec promised and what was delivered. Fix CI blockers preventing merge, decompose remaining god objects, replace false-confidence tests with real verification, and remove all dead code.

### Success Criteria
- [ ] CI quality gate passes (all 3 jobs green)
- [ ] `AppInitializer.initialize()` ≤ 80 lines — composition only, no business logic
- [ ] `app_router.dart` ≤ 120 lines — composes route modules, owns no route definitions
- [ ] `main.dart` ≤ 50 lines, `main_driver.dart` ≤ 40 lines
- [ ] Zero `Supabase.instance.client` outside DI root + WorkManager isolate (the one accepted exception)
- [ ] Zero source-text tests (`File.readAsString` + `contains`/`indexOf`) in the test suite
- [ ] Zero trivial type-check tests (`isA<Function>`, `isNotNull` with no setup)
- [ ] `lib/test_harness/` deleted, all references updated
- [ ] `InitOptions.isDriverMode` removed
- [ ] All existing 3,769 passing tests still pass
- [ ] `app_redirect_test.dart` (27 tests) untouched — already good

---

## CI Fixes

### AUTOINCREMENT Removal
- **Files**: `lib/core/database/schema/sync_engine_tables.dart` (lines 22, 38, 89), `lib/core/database/schema_verifier.dart` (lines 265, 270, 277)
- **Change**: `INTEGER PRIMARY KEY AUTOINCREMENT` → `INTEGER PRIMARY KEY`
- **Rationale**: Sync engine orders by `changed_at`, not `id`. No code depends on ID non-reuse. Existing databases carry harmless `sqlite_sequence` rows.

### Supabase Grep False Positives
- **File**: `.github/workflows/quality-gate.yml` (line 198)
- **Change**: Add `grep -v "^\s*//"` to exclude comment lines from the singleton audit
- **Rationale**: 7 comment-only matches cause false failure. The AST-based custom lint rule already handles real code violations correctly.

### Flutter Version Bump
- **File**: `.github/workflows/quality-gate.yml` (line 19)
- **Change**: `FLUTTER_VERSION: '3.32.2'` → latest stable shipping Dart ≥3.10.7
- **Rationale**: pubspec requires `sdk: ^3.10.7`, CI's Flutter 3.32.2 ships Dart 3.8.1.

---

## God Object Decomposition — AppInitializer

### New Initializer Modules

| New File | Responsibility | Current Steps |
|----------|---------------|---------------|
| `lib/core/di/initializers/core_services_initializer.dart` | PreferencesService, Aptabase, DatabaseService, TrashRepository, SoftDeleteService | Steps 1-2 |
| `lib/core/di/initializers/platform_initializer.dart` | OCR, Supabase, Firebase (platform-conditional) | Steps 3-4 |
| `lib/core/di/initializers/media_services_initializer.dart` | Photo chain, ImageService, PermissionService, CoreDeps assembly | Step 5 |
| `lib/core/di/initializers/remaining_deps_initializer.dart` | Location, contractor, equipment, personnel type, bid item, entry quantity, calculator history, todo repos | Step 10 |
| `lib/core/di/initializers/startup_gate.dart` | Inactivity timeout, config check, force reauth | Step 9 |

Steps 6 (feature initializer delegation), 7 (sync), and 8 (auth listener) stay inline as one-liner delegations.

### Result
`initialize()` becomes ~60-70 lines of sequenced calls to initializer modules. Each module is a static method or small class returning its products.

---

## God Object Decomposition — AppRouter

### Route Modules

| New File | Routes Owned | Approx Lines |
|----------|-------------|-------------|
| `lib/core/router/routes/auth_routes.dart` | Login, register, password recovery, onboarding | ~50 |
| `lib/core/router/routes/project_routes.dart` | Project list, detail, create, settings, members | ~60 |
| `lib/core/router/routes/entry_routes.dart` | Entry list, detail, create, daily log | ~50 |
| `lib/core/router/routes/form_routes.dart` | Form list, fill, PDF preview + `_mpResultFromJobResult` | ~70 |
| `lib/core/router/routes/toolbox_routes.dart` | Calculator, gallery, todos | ~40 |
| `lib/core/router/routes/sync_routes.dart` | Sync status, conflict resolution | ~30 |
| `lib/core/router/routes/settings_routes.dart` | Settings, profile, admin, about | ~40 |

### Result
`app_router.dart` becomes: class declaration, `_buildRouter()` composing modules, `nonRestorableRoutes`, `isRestorableRoute()`, `setInitialLocation()`. Target ~80-100 lines.

---

## Supabase Singleton Fix

- `BackgroundSyncHandler.initialize()` gains optional `SupabaseClient?` parameter
- `app_initializer.dart` passes `CoreDeps.supabaseClient` at the call site
- `_performDesktopSync` uses stored client instead of `Supabase.instance.client`
- WorkManager isolate (line 49) remains as the one documented exception — fresh isolate cannot access main isolate's DI state

---

## Entrypoint Slimming

| File | Current | Target | How |
|------|---------|--------|-----|
| `main.dart` (92 lines) | `ConstructionInspectorApp` widget inline | ~50 lines | Extract widget to `lib/core/app_widget.dart` |
| `main_driver.dart` (77 lines) | Test photo service setup inline | ~35 lines | Import shared setup from `core/driver/` |

---

## Dead Code Removal

| Item | Action |
|------|--------|
| `lib/test_harness/` (5 files) | Delete entire directory |
| `InitOptions.isDriverMode` | Remove field, constructor param, doc comment from `init_options.dart` |

---

## Stale Reference Updates

| File | Change |
|------|--------|
| `.claude/rules/testing/patrol-testing.md` | Replace 9 `lib/test_harness/` references with `lib/core/driver/` |
| `fg_lint_packages/.../avoid_raw_database_delete.dart` (line 28) | Update allowlist path |
| `fg_lint_packages/.../no_stale_patrol_references.dart` (lines 29, 31) | Update allowlist paths |

---

## Testing Strategy

### Tests to DELETE (31 tests across 6 files)

| File | Tests | Reason |
|------|-------|--------|
| `app_bootstrap_test.dart` | 9 | All source-text grep tests |
| `app_initializer_test.dart` | 7 | 3 source-text + 4 trivial InitOptions checks |
| `entrypoint_equivalence_test.dart` | 6 | 5 source-text + 1 trivial type check |
| `scaffold_with_nav_bar_test.dart` | 2 | Trivial type checks |
| `background_sync_handler_test.dart` | 3 | Trivial constant/type checks |
| `app_router_test.dart` | 4 | Rewrite (currently constructor-only) |

### Tests to KEEP (untouched)
- `app_redirect_test.dart` — 27 real runtime tests

### New Replacement Tests

**`app_bootstrap_test.dart` (rewrite) — ~6 tests:**
- `configure()` with mocked deps produces valid `AppBootstrapResult` with non-null router, providers
- `configure()` called twice throws `StateError`
- Auth state change authenticated→unauthenticated triggers sign-out cleanup callback
- Auth state change unauthenticated→authenticated triggers deferred audit write callback
- Consent state loads before router construction (verified via mock call ordering)

**`app_initializer_test.dart` (rewrite) — ~5 tests:**
- `initialize()` with all mocked deps returns valid `AppDependencies` with all fields populated
- `initialize()` with Supabase unconfigured returns `AppDependencies` with null supabaseClient
- `initialize()` OCR failure is caught and logged, doesn't crash initialization
- `initialize()` delegates to feature initializers (verified via mock calls)
- `InitOptions.supabaseClientOverride` is passed through to CoreDeps

**`app_router_test.dart` (rewrite) — ~5 tests:**
- Router construction with valid deps produces a `GoRouter` instance
- `isRestorableRoute()` returns true for dashboard, false for auth routes
- All 7 route modules register at least one route (compositional check)
- `setInitialLocation()` changes initial location
- Non-restorable routes set matches expected auth/onboarding paths

**`background_sync_handler_test.dart` (rewrite) — ~3 tests:**
- `initialize()` with injected `SupabaseClient` stores it for desktop sync
- `_performDesktopSync` uses injected client, not `Supabase.instance.client`
- `kBackgroundSyncTaskName` matches WorkManager registration name

**`scaffold_with_nav_bar_test.dart` (rewrite) — ~3 tests:**
- `pumpWidget` renders child widget
- Bottom navigation bar shows expected tab items
- Tab selection triggers correct route navigation

**`entrypoint_equivalence_test.dart` — DELETE entirely:**
Concerns covered by `app_bootstrap_test.dart` rewrites and lint rules.

### Net Change
- **Before**: 58 tests (27 real + 31 fake)
- **After**: ~49 tests (27 existing + 22 new) — all runtime verification

---

## Security Implications

- Tightening Supabase singleton boundary: `_performDesktopSync` uses injected client
- WorkManager isolate remains single documented exception
- CI grep audit hardened against comment false positives
- No new routes, auth gates, RLS policies, or attack surface
- `InitOptions.isDriverMode` removal eliminates dead API surface
- Auth gates in `app_redirect.dart` untouched (27 tests verify full redirect matrix)

---

## Decisions Log

| Decision | Chosen | Rejected | Why |
|----------|--------|----------|-----|
| PR strategy | Everything in one PR (Option C) | Split PR (D), CI-only (A) | User prioritizes quality over merge speed |
| Route grouping | By feature domain (7 modules) | By nav structure (3), by auth boundary (2) | Mirrors `lib/features/` structure, each module stays small |
| Test approach | Hybrid: lint rules + targeted runtime (C) | Pure runtime integration (A), lint-only (B) | Lint covers structural concerns; runtime covers wiring |
| stub_services.dart | Delete with test_harness/ (A) | Migrate to core/driver/ (B) | YAGNI — dead code, mocktail covers future needs |
| InitOptions.isDriverMode | Remove | Wire up | Dead code; structural separation is the actual mechanism |
| WorkManager singleton | Accept as documented exception | Try to eliminate | Impossible — fresh isolate has no access to main DI state |
