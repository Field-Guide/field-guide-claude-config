# Completeness Review — Cycle 1

**Verdict**: REJECT

## Findings

### [HIGH] main_driver.dart slimming completely missing
- **Spec reference**: Entrypoint Slimming table — main_driver.dart (77 lines) → ~35 lines
- **Issue**: Plan sub-phase 5.2.3 only updates a single import line. Does not extract driver setup logic to reduce to ≤40 lines.
- **Fix**: Add a sub-phase to extract TestPhotoService/DriverServer setup into `lib/core/driver/driver_setup.dart`, reducing main_driver.dart to ≤40 lines.

### [HIGH] Route modules: 8 created instead of spec's 7
- **Spec reference**: AppRouter decomposition — 7 route modules
- **Issue**: Plan creates separate onboarding_routes.dart that spec doesn't specify. Spec's auth module includes onboarding.
- **Fix**: Merge onboarding_routes.dart into auth_routes.dart to match spec's 7-module design.

### [MEDIUM] startup_gate.dart absorbs Step 8 which spec says stays inline
- **Spec reference**: "Steps 6, 7, and 8 stay inline as one-liner delegations"
- **Issue**: Plan's startup_gate.dart covers Steps 8-9 together. Spec says Step 8 (auth listener) stays inline.
- **Fix**: Keep Step 8 inline in app_initializer.dart. startup_gate.dart handles only Step 9.

### [MEDIUM] no_stale_patrol_references.dart: lines 11 and 23 not addressed
- **Spec reference**: Ground truth shows 4 references at lines 11, 23, 29, 31
- **Issue**: Plan only addresses lines 29 and 31 per spec, but lines 11 and 23 also reference test_harness.
- **Fix**: Add lines 11 and 23 to step 2.3.2.

### [MEDIUM] scaffold_with_nav_bar_test: test 3 is a trivial type check
- **Spec reference**: Test 3 should be "Tab selection triggers correct route navigation"
- **Issue**: Plan substitutes a trivial type check which contradicts spec's "zero trivial type-check tests" criterion.
- **Fix**: Replace with spec's test: tab selection triggers correct route navigation.

### [MEDIUM] background_sync_handler_test: spec test 2 dropped
- **Spec reference**: Test 2: "_performDesktopSync uses injected client"
- **Issue**: Plan substitutes kBackgroundSyncTaskName constant check (trivial). Spec's test verifies the core Supabase singleton fix.
- **Fix**: Restore spec's test 2 — verify injected client is used via mock verification.
