## Phase 5: Property-Based Concurrency + Soak

### Goal

Prove sync invariants hold under generated concurrent scenarios, and sustain a 10-minute CI soak (pre-merge gate) plus a 15-minute nightly soak against local Docker Supabase (and, after Phase 7 provisioning, against staging). Invariants under test: Last-Write-Wins resolution, cursor advancement monotonicity, assignment-scope enrollment/teardown correctness, and tombstone propagation across soft-delete.

### Prerequisites

- Phase 1 seeded fixture (`supabase/seed.sql` with ~10–20 users across ≥5 projects, assignment matrix with inspectors both on and off specific projects) is in place and `pwsh -File tools/supabase_local_reset.ps1` boots cleanly.
- Phase 2 harness skeleton is merged: `integration_test/sync/harness/harness_auth.dart`, `harness_driver_client.dart`, `harness_assertions.dart`, `harness_fixture_cursor.dart` exist and can authenticate each of the four roles against local Docker.
- Phase 3 correctness matrix has landed under `integration_test/sync/matrix/`, including the failing repros for defects (a), (b), (c), (d), (e). These repros stay failing through Phase 5.
- Phase 4 logging event-class audit + Sentry dedup middleware is green. Soak metrics rely on Phase 4's RLS-denial event class (`LogEventClasses.rlsDenial`) and the transport diagnostics already published at `/diagnostics/sync_transport` and `/diagnostics/sync_runtime`.
- `glados` is not yet a repo dependency (per ground-truth gap #1). This phase adds it.
- `scripts/soak_local.ps1` does not yet exist (per ground-truth gap #5). This phase creates it.
- Existing 60+ sync unit tests under `test/features/sync/**` and 15 characterization tests under `test/features/sync/characterization/` stay green; this phase does not modify them.

### Files Created

- `integration_test/sync/concurrency/glados_invariants_test.dart`
- `integration_test/sync/concurrency/table_driven_fallback_test.dart`
- `integration_test/sync/soak/soak_driver.dart`
- `integration_test/sync/soak/soak_metrics_collector.dart`
- `integration_test/sync/soak/soak_ci_10min_test.dart`
- `integration_test/sync/soak/soak_nightly_15min_test.dart`
- `scripts/soak_local.ps1`
- `.github/workflows/nightly-soak.yml`

### Files Modified

- `pubspec.yaml` — add `glados` under `dev_dependencies`.
- `.github/workflows/quality-gate.yml` — add `Soak test (10-min)` step gated on sync-touching PRs via a path filter.

### Files Preserved (Must Not Regress)

- All 26 adapters registered in `lib/features/sync/engine/sync_registry.dart` and their FK-dependency order.
- `lib/features/sync/engine/sync_error_classifier.dart` classification contract — `42501` stays non-retryable when the soak driver encounters an RLS denial.
- `lib/features/sync/domain/sync_status.dart` as the single source of truth for transport state; soak metrics read from it via `/diagnostics/sync_transport`, not by probing internals.
- `lib/features/sync/application/sync_coordinator.dart` `syncLocalAgencyProjects(...)` remains the only sync entrypoint the soak driver calls.
- `lib/features/sync/engine/sync_engine_tables.dart` trigger behavior: `sync_control.pulling = '1'` remains the only trigger-suppression bracket; soak fixture never inserts into `change_log` manually.
- `RealtimeHintHandler._minSyncInterval = Duration(seconds: 30)` stays as-is in this phase (Phase 6 may revisit only if profiling forces it).
- The existing "Sync lint violations to GitHub Issues" step in `.github/workflows/quality-gate.yml` — the nightly-soak workflow created here stays separate until Phase 7 unifies it under `scripts/github_auto_issue_policy.py`.
- All 15 characterization tests under `test/features/sync/characterization/`.

### Step-by-step Implementation

1. **Add `glados` as a dev dependency.**
   - Edit `pubspec.yaml`. Under `dev_dependencies:` add `glados: ^1.1.6` (or the latest 1.x compatible with the repo's Dart SDK constraint already declared in `pubspec.yaml`).
   - Run `pwsh -Command "flutter pub get"`.
   - Confirm `flutter analyze` and `dart run custom_lint` stay green.

2. **Create `integration_test/sync/concurrency/glados_invariants_test.dart`.**
   - Import `package:glados/glados.dart`, the harness (`integration_test/sync/harness/harness_auth.dart`, `harness_driver_client.dart`, `harness_assertions.dart`), and `package:construction_inspector/features/sync/engine/sync_error_classifier.dart`.
   - Define four property-based tests:
     - **LWW property**: generate pairs of competing mutations with varying `updated_at` deltas, push both, assert the winner at the server matches the later `updated_at`. Cross-check against `SyncErrorClassifier.classify` so any unexpected classification surfaces. Target sites: `lib/features/sync/engine/push_handler.dart` (LWW winner selection) and `SyncErrorClassifier` contract.
     - **Cursor advancement monotonicity**: generate sequences of pulls interleaved with local mutations, assert the cursor recorded by `lib/features/sync/engine/change_tracker.dart` only advances and never rewinds.
     - **Assignment-scope enrollment/teardown**: generate add/remove sequences against `project_assignments` for a given user; assert `lib/features/sync/engine/enrollment_handler.dart` plus `lib/features/sync/engine/pull_scope_state.dart` converge to the correct scope set regardless of ordering, and that `SyncedScopeStore.getActiveAssignmentProjectIds` reflects the final state.
     - **Tombstone propagation**: generate soft-delete + restore sequences, assert tombstones propagate to every subscribed device's local DB with no ghost rows and no double-deletes.
   - Each property reads sync state only via `/diagnostics/sync_transport` and `/diagnostics/sync_runtime` or via `SyncCoordinator.status` / `SyncCoordinator.statusStore` — never by reaching into `SyncEngine` directly.
   - Use `TestingKeys` for any UI-driven setup; never hardcode `Key('...')`.

3. **Create `integration_test/sync/concurrency/table_driven_fallback_test.dart`.**
   - For invariants `glados` cannot express cleanly (e.g., scenarios that require specific real-time timing from `RealtimeHintHandler._handleHint` plus a throttle window), enumerate a small static table of scenarios — each row a `(setup, action sequence, expected invariant)` triple.
   - Drive each row through the harness. Keep this file time-boxed: if the PBT coverage above already exercises the scenario, delete the row.

4. **Create `integration_test/sync/soak/soak_metrics_collector.dart`.**
   - Class `SoakMetricsCollector` with a `sample()` method that issues HTTP GETs against the driver's `/diagnostics/sync_transport` and `/diagnostics/sync_runtime` endpoints (paths sourced from `lib/core/driver/driver_diagnostics_handler.dart`'s `DriverDiagnosticsRoutes`).
   - From `/diagnostics/sync_transport` capture the `lastRun` payload: `pushed`, `pulled`, `errors`, `rlsDenials`, `durationMs`, `completedAt`, `wasSuccessful`, and the `transportHealth` map.
   - From `/diagnostics/sync_runtime` capture: `lastRequestedMode`, `lastRunHadDirtyScopesBeforeSync`, `stateFingerprint`, `dirtyScopeCount`, `dirtyScopes`.
   - Expose `Stream<SoakSample>` for per-minute sampling and a `SoakSummary finalize()` for end-of-run totals.
   - No mutation; pure read over the existing driver HTTP surface.

5. **Create `integration_test/sync/soak/soak_driver.dart`.**
   - Class `SoakDriver` with fields `userCount` (default `20`), `duration` (passed in — 5 / 10 / 15 minutes), and `actionMix` with default weights `readWeight: 30`, `entryMutationWeight: 30`, `photoUploadWeight: 15`, `deleteRestoreWeight: 20`, `roleAssignmentWeight: 5`.
   - Authenticate each of the 20 virtual users against a seeded fixture user (from Phase 1's `supabase/seed.sql`). Reuse `integration_test/sync/harness/harness_auth.dart`; do not introduce a second auth path.
   - Per virtual user, loop until `duration` elapses: pick a weighted action; execute it through `harness_driver_client.dart` against the real Flutter client; every 60s, sample metrics via `SoakMetricsCollector`.
   - On error: call `SyncErrorClassifier.classify(error, tableName: ..., recordId: ..., retryCount: ...)`. If the resulting kind is RLS denial (`42501` path), increment `rlsDenials` and continue. For any transient classification, continue. Never swallow the error; always record it in the summary.
   - `run()` returns a `SoakResult` containing per-minute samples, aggregate counters, and the `SoakSummary`.
   - No new call into `SyncEngine` or `SyncCoordinator` internals; all sync work goes through `SyncCoordinator.syncLocalAgencyProjects(...)` via the driver.

6. **Create `integration_test/sync/soak/soak_ci_10min_test.dart`.**
   - Single test that constructs `SoakDriver(duration: Duration(minutes: 10), userCount: 20, actionMix: SoakDriver.defaultMix)`, calls `run()`, and asserts:
     - `result.summary.wasSuccessful == true` on the final `lastRun`.
     - `result.summary.errors` (excluding classified-RLS denials) is zero.
     - No sample reports `lastRun.rlsDenials` exceeding the per-minute ceiling defined by the seeded fixture's legitimate denial rate (the fixture has known-unassigned inspectors, so some RLS denials are expected and legitimate — the assertion is rate-bounded, not zero).
   - Wire into `.github/workflows/quality-gate.yml` in step 8.

7. **Create `integration_test/sync/soak/soak_nightly_15min_test.dart`.**
   - Same shape as the 10-min CI test, with `duration: Duration(minutes: 15)`.
   - Stricter assertion: records a metrics snapshot to a workflow artifact for trend analysis (fed into Phase 7's auto-issue policy once stability is reached).

8. **Modify `.github/workflows/quality-gate.yml`: add `Soak test (10-min)` step.**
   - Add a `paths` filter at the job level (or a per-step `if` using `dorny/paths-filter`) that runs the new step only when the PR touches any of:
     - `lib/features/sync/**`
     - `lib/core/driver/**`
     - `supabase/migrations/**`
     - `supabase/seed.sql`
     - `lib/features/sync/adapters/**`
   - The step name is `Soak test (10-min)`. It runs after the existing `analyze-and-test` job's test steps and before architecture validation. Invocation uses the PowerShell wrapper pattern: `pwsh -Command "flutter test integration_test/sync/soak/soak_ci_10min_test.dart --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=..."`.
   - Until three consecutive green CI runs are observed, mark the step `continue-on-error: true`. Remove that flag in the commit that declares the gate official.

9. **Create `scripts/soak_local.ps1`.**
   - PowerShell wrapper for local developers. Accepts `-DurationMinutes` (default 5), `-UserCount` (default 20). Boots local Docker Supabase via `tools/supabase_local_start.ps1` if not already running, then runs `integration_test/sync/soak/soak_ci_10min_test.dart` with the supplied duration.
   - Emits a readable summary to stdout from the test's `SoakResult`.
   - Not a CI gate. Document this with a leading comment block: `# Local developer utility; not invoked by CI.`

10. **Create `.github/workflows/nightly-soak.yml`.**
    - Trigger: `schedule: - cron: '0 7 * * *'` (nightly UTC) and `workflow_dispatch`.
    - Job runs `integration_test/sync/soak/soak_nightly_15min_test.dart` against local Docker Supabase spun up inside the runner (using the Phase 1 reset/start wrappers).
    - On failure, upload the `SoakMetricsCollector` samples as a workflow artifact.
    - Do NOT wire auto-issue creation here in Phase 5. Leave a `TODO(phase-7)` comment marker — wait; instead of a TODO, add a plain YAML comment: `# auto-issue creation wired in phase 7 via scripts/github_auto_issue_policy.py after three-night stability`. No runtime TODO markers.
    - Three consecutive green nights are the gate before Phase 7 allows this workflow to auto-file issues.

11. **Run `flutter analyze`, `dart run custom_lint`, and `python scripts/validate_sync_adapter_registry.py` locally.** All three must be green — this phase adds no production code, so the custom-lint-baseline must not grow.

### Exit Criteria

- `glados` is present under `dev_dependencies` in `pubspec.yaml` and `flutter pub get` succeeds.
- All four properties in `glados_invariants_test.dart` pass on the local harness before being added to CI.
- `integration_test/sync/concurrency/table_driven_fallback_test.dart` passes locally.
- `integration_test/sync/soak/soak_ci_10min_test.dart` runs green three consecutive CI runs; the `continue-on-error` flag in `.github/workflows/quality-gate.yml` is removed in the commit that declares the soak step the official pre-merge gate.
- `.github/workflows/nightly-soak.yml` runs green three consecutive nights before Phase 7 wires auto-issue filing.
- `flutter analyze` and `dart run custom_lint` stay green; `python scripts/validate_sync_adapter_registry.py` stays green.
- No changes to the 60+ sync unit tests or 15 characterization tests; they remain green.

### Local Verification

- `pwsh -Command "flutter pub get"`
- `pwsh -Command "flutter analyze"`
- `pwsh -Command "dart run custom_lint"`
- `pwsh -File tools/supabase_local_reset.ps1`
- `pwsh -File scripts/soak_local.ps1 -DurationMinutes 5`
- `python scripts/validate_sync_adapter_registry.py`

---

## Phase 6: Sync Engine Rewrite (Targeted Hotspots + Flashing Fix)

### Goal

Hit the 2-second full-sync ceiling on the Phase 1 seeded fixture (cold start, empty SQLite, fresh auth, all tables). Hit the foreground unblock ceilings (warm ≤ 500ms, cold empty-state placeholder ≤ 500ms plus fill ≤ 2s). Fix the five enumerated defects — (a), (b), (c), (d), (e) — so their Phase 3 failing repros now pass. Preserve every sync invariant; do not invoke the architectural-rewrite escape clause unless profiling against the seeded fixture demonstrates the targeted rewrite cannot clear the 2s ceiling.

### Prerequisites

- Phase 1 seeded fixture is the profiling fixture; `pwsh -File tools/supabase_local_reset.ps1` is deterministic.
- Phase 3 correctness matrix is merged; every failing repro for defects (a)–(e) is committed and stays failing until this phase fixes them.
- Phase 5 PBT + 10-min CI soak are stable on main so regressions introduced here surface immediately.
- A profiling methodology has been chosen and recorded (see step 1) — tool, fixture size, and measurement procedure are written down in a sibling doc referenced by the PR description. This is an explicit implementer decision made at the start of the phase; it is not deferred past this step.

### Files Created

None.

### Files Modified

**Sync engine hotspot rewrite:**

- `lib/features/sync/engine/pull_handler.dart`
- `lib/features/sync/engine/change_tracker.dart`
- `lib/features/sync/engine/pull_scope_state.dart`
- `lib/features/sync/application/realtime_hint_handler.dart`
- `lib/features/sync/application/realtime_hint_transport_controller.dart`
- `lib/features/sync/engine/enrollment_handler.dart`
- `lib/features/sync/engine/fk_rescue_handler.dart`
- `lib/features/sync/engine/pull_fk_violation_resolver.dart`

**Flashing fix (defects a, b, e):**

- `lib/features/projects/presentation/providers/project_provider_auth_controller.dart`
- `lib/features/projects/presentation/providers/project_provider_auth_init.dart`
- `lib/features/projects/presentation/screens/project_list_screen.dart`
- `lib/features/projects/presentation/providers/project_provider_filters.dart`

**Download-on-click fix (defect d):**

- The exact file path is not confirmed at tailor time. The implementer runs `pwsh -Command "rg -n 'downloadProject|onDownloadPressed' lib/features/projects/presentation/"` (using the repo's Grep tooling equivalent) to identify the current click handler site, then applies the fix at the identified site. Blast radius names `lib/features/projects/presentation/providers/project_download_controller.dart` as a likely candidate, but the implementer confirms before editing. Do not guess the path.

**Escape-clause candidates (only if profiling forces it):**

- `lib/features/sync/application/sync_coordinator.dart` (public surface) — allowed only under the escape clause and only when the escape-clause preservation list below is upheld.
- `lib/features/sync/engine/sync_engine.dart` (public surface) — same gate.

### Files Preserved (Must Not Regress)

- `lib/features/sync/engine/sync_registry.dart` and the 26-adapter FK-ordered `registerAdapters([...])` call. `scripts/validate_sync_adapter_registry.py` stays green.
- `lib/features/sync/engine/sync_error_classifier.dart` — `42501` stays non-retryable; `_classifyPostgrestError` path unchanged.
- `lib/features/sync/domain/sync_status.dart` — `SyncStatus` remains the single source of truth for transport state.
- `lib/features/sync/application/sync_coordinator.dart` — `syncLocalAgencyProjects(...)` at line 221 remains the sole public sync entrypoint (modifiable only under the escape clause, with the preservation list intact).
- `change_log` is trigger-owned; `sync_control.pulling = '1'`/`'0'` stays the only trigger-suppression bracket.
- `lib/features/sync/engine/sync_hint_remote_emitter.dart` — `emit_sync_hint` RPC ownership stays on `RpcSyncHintRemoteEmitter`.
- `lib/features/sync/application/realtime_hint_handler.dart` subscription lifecycle ownership stays with `RealtimeHintHandler`; `_minSyncInterval = Duration(seconds: 30)` stays unless profiling proves it blocks the 2s ceiling (see step 4 — explicit flag, not silent change).
- RLS company-scope via `get_my_company_id()` in all migrations under `supabase/migrations/**`.
- `SyncEngineTables.tablesWithBuiltinFilter = ['inspector_forms']`; `is_builtin = 1` skip behavior stays intact.
- Driver contract parity: `lib/core/driver/screen_registry.dart` and `lib/core/driver/screen_contract_registry.dart` stay in lockstep; `screen_registry_contract_sync` lint stays green.
- Custom lint rules: `push_handler_requires_sync_hint_emitter`, `no_sync_hint_rpc_outside_approved_owners`, `no_sync_hint_broadcast_subscription_outside_realtime_handler`, `no_client_sync_hint_broadcast_http`, `no_sync_status_column`, `sync_control_inside_transaction`, `sync_time_on_success_only`, `tomap_includes_project_id`, `max_ui_callable_length`, `max_ui_file_length`, `screen_registry_contract_sync`. No ignore comments added; no allowlist widening; no rule weakening.
- `ProjectRestoreFailureHandler` typedef and its callback signature on `ProjectProviderAuthController` (per `patterns/provider-changenotifier.md`).
- All 15 characterization tests under `test/features/sync/characterization/` stay green; deletions of individual characterization tests happen only when the Phase 3 harness matrix proves the same contract more honestly, each in a dedicated commit citing the replacement.

### Step-by-step Implementation

1. **Record profiling methodology.**
   - Choose the profiling tool (e.g., Dart DevTools timeline, `dart --observe`, `flutter --profile` + captured traces). Document the choice.
   - Use the Phase 1 seeded fixture as the sole profiling fixture — 1 company, 10–20 users, ≥5 projects, assignment matrix, FK chain. Document the row counts from the actual seeded fixture.
   - Document the measurement procedure: cold-start sequence (empty SQLite, fresh auth, first launch), three runs per condition, median reported. Warm-foreground-unblock and cold-empty-state-placeholder measurements use the same fixture with the app resumed vs. cold-launched.
   - Write this down in a sibling doc referenced by the PR description (not in `CLAUDE.md`, not as a spec edit, not in `.claude/memory/`). The doc lives in the PR body or in `docs/` if the implementer prefers a committed record.

2. **Capture baseline measurements.**
   - Run the profiling procedure against `main` (or the branch point) on the seeded fixture. Record cold-start full-sync duration, warm foreground unblock duration, and cold empty-state placeholder timing.
   - Also run the Phase 3 matrix repros for defects (a)–(e) and capture their current failure signatures. These are the regression guards.

3. **Parallelize `pull_handler.dart` where FK safety allows.**
   - In `lib/features/sync/engine/pull_handler.dart`, group tables into independent-subgraphs using `SyncRegistry.instance.dependencyOrder` and `childFkColumnsFor(...)`. FK parents still come before FK children; siblings that share no parent can pull in parallel.
   - Bound parallelism per subgraph to avoid saturating the local SQLite writer.
   - Do not change the adapter order in `sync_registry.dart`. Do not reorder `simpleAdapters` in `lib/features/sync/adapters/simple_adapters.dart`.
   - Re-run `python scripts/validate_sync_adapter_registry.py` after the change; it must stay green.

4. **Optimize `change_tracker.dart` cursor advancement.**
   - In `lib/features/sync/engine/change_tracker.dart`, profile the cursor-advance path during a full sync. If batching cursor writes (one write per table, not one per record) clears the hotspot without weakening monotonicity, apply that.
   - Verify the monotonicity property from Phase 5's `glados_invariants_test.dart` still passes.

5. **Optimize `pull_scope_state.dart` enrollment efficiency.**
   - In `lib/features/sync/engine/pull_scope_state.dart`, eliminate redundant re-reads of `SyncedScopeStore.getActiveAssignmentProjectIds` per table during a single pull. Cache the scope set for the duration of one `_executePull(...)` cycle in `SyncEngine`.
   - Confirm `LocalSyncStoreScope.getActiveAssignmentProjectIds` is not shadowed — presentation code must still see the same scope set.

6. **Fix defect (c): new-user-to-old-project assignment propagation.**
   - In `lib/features/sync/engine/enrollment_handler.dart`, ensure that when a new assignment row lands during a pull, the pull extends scope to include the newly-assigned project within the same run (not deferred to the next cycle). Coordinate with `SyncedScopeStore` so the enrollment takes effect before the first record for that project is pulled.
   - The Phase 3 repro in `integration_test/sync/matrix/assignments_matrix_test.dart` must now pass.

7. **Harden `fk_rescue_handler.dart` and `pull_fk_violation_resolver.dart`.**
   - Ensure integrity + propagation: when a child record arrives before its parent, rescue-fetch the parent in-cycle rather than dropping or deferring. Log every rescue via `Logger.sync(LogEventClasses.fkRescue, data: {...})` (Phase 4 event class).
   - No manual inserts into `change_log`; any state mutation goes through normal adapter write paths with `sync_control.pulling = '1'` where triggers must be suppressed.

8. **Tune realtime-hint fan-out.**
   - In `lib/features/sync/application/realtime_hint_handler.dart` and `lib/features/sync/application/realtime_hint_transport_controller.dart`, profile `_handleHint(Map)` + `_triggerQuickSync(...)` + `_drainQueuedQuickSync()` for fan-out latency.
   - **Explicit flag — do not change silently**: if profiling shows `_minSyncInterval = Duration(seconds: 30)` is the binding constraint on the 2s ceiling, the change to that constant is a scope-impacting modification. Call it out in the PR description; flag it as a deliberate tuning decision; do not bury it inside a hotspot commit. If profiling does not show it as the binding constraint, leave it at 30 seconds.
   - Subscription lifecycle ownership and `deactivate_sync_hint_channel` RPC calls stay with `RealtimeHintHandler`; do not relocate.

9. **Flashing fix — atomic `_loadAssignments` + `_loadProjectsByCompany`.**
   - In `lib/features/projects/presentation/providers/project_provider_auth_controller.dart`, replace the two independent `unawaited(...)` calls in `onAuthChanged` (and the initial-load path in `initWithAuth`) with a single awaited `Future.wait([...])` barrier before `_setInitializing(false)` and before the first `notifyListeners()` call on this auth transition. Follow the exact shape in `source-excerpts/by-concern.md`:

     ```dart
     if ((userOrRoleChanged && newUserId != null) ||
         (newCompanyId != null && newCompanyId != lastLoadedCompanyId)) {
       lastLoadedCompanyId = newCompanyId;
       _setInitializing(true);
       await Future.wait([
         if (userOrRoleChanged && newUserId != null) _loadAssignments(newUserId),
         if (newCompanyId != null) _loadProjectsByCompany(newCompanyId),
       ]);
       _setInitializing(false);
       unawaited(syncCoordinator.syncLocalAgencyProjects(mode: SyncMode.quick));
     }
     ```

   - Preserve the `ProjectRestoreFailureHandler` typedef and the callback signature on the controller. Do not rename or retype it.
   - Do not introduce a skeleton-then-filter pattern; per Scope, the first render must see the filtered list.

10. **Flashing fix — initial state application.**
    - In `lib/features/projects/presentation/providers/project_provider_auth_init.dart`, ensure the initial assignment filter is applied to the initial state BEFORE the first `notifyListeners()` call fires. Read `_assignedProjectIds` at the point of initial list materialization; do not populate `_projects` first and filter later.

11. **Flashing fix — screen first-frame guarantee.**
    - In `lib/features/projects/presentation/screens/project_list_screen.dart`, confirm the first render path consumes the filtered list exposed by `ProjectProviderFilters.visibleProjects` (or equivalent getter), not `_projects` directly. If the screen currently references the unfiltered list in any branch, switch it to the filtered getter. `mounted` checks after async gaps stay intact.

12. **Flashing fix — defense-in-depth client filter.**
    - In `lib/features/projects/presentation/providers/project_provider_filters.dart`, confirm the client filter already applied by `visibleProjects` remains authoritative on the presentation side. RLS is the hard boundary; the client filter is defense-in-depth for the server-to-client propagation window (per Scope "Concurrent-mutation source of truth"). Do not weaken either.

13. **Fix defect (d): download-on-click.**
    - Run `pwsh -Command "rg -n 'downloadProject|onDownloadPressed' lib/features/projects/presentation/"` (or the repo Grep equivalent) to identify the current click handler site.
    - Confirm the identified file. If `lib/features/projects/presentation/providers/project_download_controller.dart` is the match, modify there. If the handler is elsewhere, modify there.
    - Apply the fix at the confirmed site so the download initiates on click (not deferred behind a state change that never fires). Log `LogEventClasses.downloadInitiate`, `downloadComplete`, `downloadFail` per Phase 4 event classes.
    - Confirm the Phase 3 `integration_test/sync/matrix/download_on_click_test.dart` repro now passes.

14. **Re-run profiling against the rewritten code.**
    - Execute the same measurement procedure from step 1 against the seeded fixture. Capture: cold-start full-sync duration, warm foreground unblock, cold empty-state placeholder + fill.
    - If any of the three ceilings is missed, iterate on steps 3–8. The escape clause (step 15) is available only after targeted iteration has been exhausted.

15. **Escape clause gate (conditional).**
    - Only if profiling after step 14 shows the 2s ceiling cannot be reached by targeted hotspot rewrite, consider contract-level changes to `SyncCoordinator.syncLocalAgencyProjects` or `SyncEngine.pushAndPull` public surface.
    - Even under the escape clause, preserve: `SyncRegistry` adapter-registration order and the 26-adapter FK sequence; `scripts/validate_sync_adapter_registry.py` stays green; all custom lint rules stay green; `SyncErrorClassifier` ownership of classification and `42501` non-retryable; `SyncStatus` as state of truth; `change_log` trigger ownership; `sync_control.pulling` bracket; `is_builtin = 1` skip. Document the contract change explicitly in the PR description; the change is not silent.

16. **Re-run Phase 3 matrix and Phase 5 PBT/soak locally.**
    - All five defect repros now pass. No matrix regression for non-defect flows.
    - `glados_invariants_test.dart` stays green (LWW, cursor monotonicity, enrollment/teardown, tombstone propagation).
    - Local 10-min soak via `scripts/soak_local.ps1` stays green.

17. **Run all lint + validator checks locally before PR.**
    - `flutter analyze`, `dart run custom_lint`, `python scripts/validate_sync_adapter_registry.py`, `python scripts/verify_database_schema_platform_parity.py`. All green. No custom-lint-baseline growth.

### Exit Criteria

- Cold-start full sync completes ≤ 2 seconds on the Phase 1 seeded fixture (median of three runs).
- Foreground unblock warm path completes ≤ 500ms.
- Cold empty-state placeholder renders ≤ 500ms with fill completing ≤ 2s.
- All five enumerated defect repros committed in Phase 3 now pass:
  - (a) flashing on refresh — `integration_test/sync/matrix/flashing_repro_test.dart`
  - (b) flashing on app resume — `integration_test/sync/matrix/flashing_repro_test.dart`
  - (c) new-user-to-old-project assignment — `integration_test/sync/matrix/assignments_matrix_test.dart`
  - (d) download-on-click — `integration_test/sync/matrix/download_on_click_test.dart`
  - (e) flashing on auth transition — `integration_test/sync/matrix/flashing_repro_test.dart`
- No new lint violations; `flutter analyze` and `dart run custom_lint` green; custom-lint-baseline file unchanged or shrunk, never grown.
- `python scripts/validate_sync_adapter_registry.py` green; adapter registration order unchanged.
- All 15 characterization tests under `test/features/sync/characterization/` still green (or deleted case-by-case with commits citing the replacing harness test).
- The Phase 5 `glados` properties and 10-min soak stay green.
- Profiling methodology + baseline and post-rewrite numbers are recorded in the PR description.

### Local Verification

- `pwsh -Command "flutter analyze"`
- `pwsh -Command "dart run custom_lint"`
- `python scripts/validate_sync_adapter_registry.py`
- `python scripts/verify_database_schema_platform_parity.py`
- `pwsh -File tools/supabase_local_reset.ps1`
- `pwsh -File scripts/soak_local.ps1 -DurationMinutes 10`
- `python scripts/audit_logging_coverage.py` (or `pwsh -File scripts/audit_logging_coverage.ps1`) to confirm Phase 4 coverage still passes against the rewritten files.

---

## Phase 7: Staging Supabase + CI Gate + GitHub Auto-Issue Policy

### Goal

Make harness-green the mergeable gate for every sync-touching PR. Make the Sentry → GitHub pipeline the triage gate. Ship MVP to pre-alpha users when all five ship-bar conditions hold simultaneously: correctness matrix green (Phase 3), all five enumerated defects fixed (Phase 6), soak green (Phases 5 + 7), 2-second full-sync met (Phase 6), logging/Sentry/GitHub pipeline live (Phases 4 + 7).

### Prerequisites

- Phase 5 10-min CI soak has run green three consecutive CI runs and is no longer `continue-on-error: true`.
- Phase 5 nightly 15-min soak has run green three consecutive nights.
- Phase 6 is merged: 2s ceiling met, all five defect repros pass, lint + validators green.
- Phase 4 Sentry dedup middleware + event-class audit are live.
- External provisioning (outside repo — called out here as explicit ops steps, not code changes):
  - Dedicated staging Supabase project provisioned on Pro plan ($25/month).
  - Secrets populated in GitHub Actions repository secrets and Codemagic env-var groups: `STAGING_SUPABASE_DATABASE_URL`, `STAGING_SUPABASE_URL`, `STAGING_SUPABASE_ANON_KEY`, `STAGING_SUPABASE_SERVICE_ROLE_KEY`.
  - Sentry Log Drain ingestion endpoint wired in coordination with the Phase 4 sink decision.
  - Sentry → GitHub webhook configured at the Sentry project level; webhook target is the repository's `Issues` API scoped to a GitHub App with minimum-required permissions.

### Files Created

- `.github/workflows/staging-schema-gate.yml`
- `scripts/hash_schema.py`
- `scripts/github_auto_issue_policy.py`

### Files Modified

- `.github/workflows/quality-gate.yml`
- `.github/workflows/nightly-soak.yml` (created in Phase 5)

### Files Preserved (Must Not Regress)

- The existing `Sync lint violations to GitHub Issues` step behavior in `.github/workflows/quality-gate.yml` — the new shared policy generalizes it, it does not replace the fingerprint-by-rule dedup the step currently implements.
- Every CI job currently green stays green: `analyze-and-test`, `architecture-validation`, `security-scanning`.
- `python scripts/validate_sync_adapter_registry.py`, `python scripts/check_changed_migration_rollbacks.py`, `python scripts/validate_migration_rollbacks.py`, `python scripts/verify_database_schema_platform_parity.py`, `python scripts/verify_live_supabase_schema_contract.py` all stay green on their existing triggers.
- `lib/features/sync/application/sync_coordinator.dart` as the single sync entrypoint; the new gates exercise it, they do not bypass it.
- Adapter-registration order in `lib/features/sync/engine/sync_registry.dart`.
- `SyncErrorClassifier` ownership, `SyncStatus` authority, `change_log` trigger ownership, `sync_control.pulling` bracket, RLS company-scope via `get_my_company_id()`, `42501` non-retryable, `is_builtin = 1` skip.
- Existing custom lint rules; no ignore comments; no allowlist widening.
- PowerShell wrappers under `tools/` remain canonical for local developer flows.

### Step-by-step Implementation

1. **Capture external provisioning as explicit ops steps in the PR description.**
   - Staging Supabase project on Pro plan provisioned (owner, region, cost attribution recorded).
   - Repository and workflow secrets populated: `STAGING_SUPABASE_DATABASE_URL`, `STAGING_SUPABASE_URL`, `STAGING_SUPABASE_ANON_KEY`, `STAGING_SUPABASE_SERVICE_ROLE_KEY`. Codemagic env-var groups updated in parallel.
   - Sentry Log Drain endpoint live and healthy on the staging Supabase project console (inherits Phase 4's sink decision).
   - Sentry → GitHub webhook configured at the Sentry project level; target is the GitHub App-gated Issues API path.
   - These are not code changes; they block the code changes below from going live.

2. **Create `scripts/hash_schema.py`.**
   - Stdlib-only per `patterns/python-ci-validator.md`; zero pip installs.
   - Takes `--db-url` (repeatable) arguments for each database to hash (local Docker, staging, and prod when `PROD_SUPABASE_DATABASE_URL` is set).
   - For each database, queries via `supabase db query --db-url ...` (same invocation pattern as `scripts/verify_live_supabase_schema_contract.py`) to fetch:
     - Normalized `information_schema.columns` rows for `public` schema, ordered by `table_name`, `column_name`.
     - `pg_policies` rows for `public` schema, ordered by `tablename`, `policyname`.
   - Computes a SHA-256 of the concatenated normalized output for each DB. Emits one line per DB: `<db-label>: <hash>`.
   - Exit code 1 on drift between any two DBs; exit code 0 only when all provided DBs hash identically.
   - Hand-rolled parsing only; no third-party SQL libraries. Follow the `validate() → list[str]` / `main()` pattern in `patterns/python-ci-validator.md`.

3. **Create `.github/workflows/staging-schema-gate.yml`.**
   - Triggers: `pull_request` on branches touching `supabase/migrations/**` or `lib/core/database/schema/**`, plus `workflow_dispatch`.
   - Steps:
     - Install `supabase` CLI.
     - Spin up local Docker Supabase via `tools/supabase_local_reset.ps1` to capture the local hash.
     - Run `python scripts/hash_schema.py --db-url <local> --db-url <staging> --db-url <prod-if-set>`.
     - On nonzero exit, append the failure summary to `$GITHUB_STEP_SUMMARY` per the shape in `patterns/python-ci-validator.md` and exit 1.
   - **Migration-promotion rule**: the job fails (blocking prod apply) on any commit where the prod hash lags behind staging's hash — i.e., prod has a migration not applied cleanly on staging, or staging has a migration not yet applied to prod that the commit intends to promote. This enforces Scope success criterion 9.

4. **Create `scripts/github_auto_issue_policy.py`.**
   - Stdlib-only per `patterns/python-ci-validator.md`.
   - Exposes a callable interface invoked by CI: reads input events from stdin (JSON lines), writes decisions to stdout, exits 0.
   - Input event shape (minimum): `{source: 'lint'|'sentry'|'nightly-soak', fingerprint: <stable string>, severity: 'fatal'|'error'|'warning', userIds: [...], occurrences: N, firstSeen: ISO8601, lastSeen: ISO8601}`.
   - Policy implemented per Scope success criterion 10:
     - **Fingerprint grouping**: dedup by `(source, fingerprint)`.
     - **Rate limit**: 1 issue per fingerprint per 24 hours (no reopen spam).
     - **Creation threshold**: create an issue only when `distinct userIds ≥ 2` OR `occurrences ≥ 5 within 15 minutes`.
     - **Auto-close**: close 7 days after the last event if zero new events.
     - **Severity routing**: `fatal` creates immediately (bypasses threshold); `error` follows threshold; `warning` is digest-only (no individual issue).
     - **Stability grace**: for `source: 'nightly-soak'`, require three consecutive green nights before the policy is allowed to auto-file for that source. Reject (no-op) events from that source until the three-night flag is flipped. Store the flag in a repo-scoped state file (e.g., a committed `scripts/.auto_issue_policy_state.json` or a workflow-level GitHub Actions repository variable) — document the choice in the file header.
   - Labels on created issues: `automated`. Additional source-specific labels: `lint,tech-debt` for lint; `sentry,triage` for Sentry; `soak,regression` for nightly soak.
   - Dedup must not conflict with existing lint issues created by the current `Sync lint violations to GitHub Issues` step — the policy generalizes the existing shape rather than replacing it, so pre-existing open issues are honored and deduped against.

5. **Modify `.github/workflows/quality-gate.yml`.**
   - Extend the existing `Sync lint violations to GitHub Issues` step: pipe its per-rule FILE-LINE enumeration into `scripts/github_auto_issue_policy.py` as `source: 'lint'` events. The script becomes the issue-creation author; the current inline logic is replaced by the script delegation. Existing per-rule dedup behavior is preserved because the new policy generalizes fingerprinting.
   - Add a `Harness matrix + PBT + 10-min soak (staging)` step that runs on sync-touching PRs only. Use the same path filter declared in Phase 5:
     - `lib/features/sync/**`
     - `lib/core/driver/**`
     - `supabase/migrations/**`
     - `supabase/seed.sql`
     - `lib/features/sync/adapters/**`
   - The step authenticates against the staging Supabase project (using `STAGING_SUPABASE_*` secrets) rather than local Docker, so PRs are gated against real staging RLS and a real network path.
   - Add a `Staging schema-hash gate` step that invokes the new `.github/workflows/staging-schema-gate.yml` workflow (via `uses:` or an equivalent reusable-workflow call) so migration drift blocks merge.

6. **Modify `.github/workflows/nightly-soak.yml`.**
   - Wire the nightly soak output through `scripts/github_auto_issue_policy.py` as `source: 'nightly-soak'` events.
   - The policy's stability grace prevents auto-filing until three consecutive green nights have been recorded after the policy goes live; remove the plain YAML comment placed in Phase 5 step 10 now that the wiring exists.

7. **Wire Sentry webhook events into the policy.**
   - The Sentry → GitHub webhook configured in step 1 posts payloads to a small receiver (a GitHub Actions workflow triggered on `repository_dispatch`, or the GitHub App's webhook endpoint).
   - Receiver normalizes Sentry payloads into the `scripts/github_auto_issue_policy.py` input shape as `source: 'sentry'` events.
   - The policy's severity routing maps Sentry event `level: fatal | error | warning` directly.

8. **Run the ship-bar conjunctive check.**
   - Before cutting the pre-alpha user release, confirm in the PR description (as a checklist) that ALL FIVE conditions below hold simultaneously:
     - Correctness matrix green (Phase 3).
     - All five enumerated defects fixed (Phase 6).
     - Soak green (Phases 5 + 7; CI 10-min pre-merge + nightly 15-min both passing).
     - 2-second full-sync met (Phase 6).
     - Logging/Sentry/GitHub pipeline live (Phases 4 + 7).
   - If any condition fails, do not cut the release. Do not ship partial.

9. **Cut the pre-alpha user release.**
   - Tag the commit that satisfies the ship-bar. The delivery mechanism for pre-alpha users is explicitly handled outside this spec per Open Questions — this step simply marks the commit as ship-eligible.

10. **Local + CI verification.**
    - Run the new workflows end-to-end in a test PR and confirm: staging schema hash gate blocks merge on a synthetic drift; the shared auto-issue policy creates, dedups, and auto-closes correctly for a synthetic lint event, a synthetic Sentry event, and a synthetic nightly-soak event.

### Exit Criteria

- Every sync-touching PR (per the path filter) runs the harness matrix + PBT + 10-min soak against staging before merge.
- The staging schema-hash gate blocks any prod migration on a commit whose migration is not already applied cleanly on staging.
- `scripts/github_auto_issue_policy.py` is the single auto-issue author for lint, Sentry, and nightly-soak sources; it enforces fingerprint grouping, 1-issue-per-fingerprint-per-24h rate limit, ≥2-user-or-≥5-occurrences-in-15-min creation threshold, 7-day auto-close on zero new events, severity routing (`fatal` immediate / `error` threshold / `warning` digest-only), and a three-night stability grace for nightly-soak.
- All pre-existing CI jobs stay green. `scripts/validate_sync_adapter_registry.py`, `check_changed_migration_rollbacks.py`, `validate_migration_rollbacks.py`, `verify_database_schema_platform_parity.py`, and `verify_live_supabase_schema_contract.py` continue to pass on their existing triggers.
- All five ship-bar conditions hold simultaneously; the pre-alpha release tag is cut from the commit where they all hold.
- `flutter analyze` and `dart run custom_lint` remain green; no custom-lint-baseline growth.

### Local Verification

- `pwsh -Command "flutter analyze"`
- `pwsh -Command "dart run custom_lint"`
- `python scripts/hash_schema.py --db-url "$env:STAGING_SUPABASE_DATABASE_URL"` (with local Docker running alongside for comparison)
- `python scripts/github_auto_issue_policy.py < test/fixtures/auto_issue_policy_sample_events.jsonl` (implementer supplies a local fixture file of synthetic events; not committed unless useful as a regression seed)
- `python scripts/validate_sync_adapter_registry.py`
- `python scripts/verify_database_schema_platform_parity.py`
- `python scripts/verify_live_supabase_schema_contract.py` (when `LIVE_SUPABASE_DATABASE_URL` is set locally)
