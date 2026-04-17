# Source Excerpts — By Concern

Cross-cutting snippets keyed to the seven-phase sequencing.

## Concern: how the harness identifies the active screen (Phase 2)

`lib/core/driver/screen_contract_registry.dart:380`:

```dart
ScreenContract? resolveActiveScreenContract({
  required String? route,
  required Set<String> visibleRootKeys,
}) {
  final candidates = screenContracts.values
      .where((contract) {
        final rootKey = _serializeKey(contract.rootKey);
        return rootKey != null && visibleRootKeys.contains(rootKey);
      })
      .toList(growable: false);

  if (route != null) {
    for (final contract in candidates) {
      if (contract.routes.any((pattern) => _matchesRoute(route, pattern))) {
        return contract;
      }
    }
  }
  if (candidates.isNotEmpty) return candidates.first;
  if (route == null) return null;
  for (final contract in screenContracts.values) {
    if (contract.routes.any((pattern) => _matchesRoute(route, pattern))) {
      return contract;
    }
  }
  return null;
}
```

The harness should reuse `GET /diagnostics/screen_contract` for visibility assertions rather than re-implement this resolver in test code.

## Concern: role-visibility assertion (Phase 3)

`lib/features/sync/engine/synced_scope_store.dart`:

```dart
// SyncedScopeStore.getActiveAssignmentProjectIds — returns the list of
// projectIds that the local device is currently enrolled to sync.
// Tests can call this (via harness) to assert "inspector X's assignment
// list matches the projects they see".
```

Harness test skeleton for flashing repro (Phase 3, defects a/b/e):

```dart
testWidgets('inspector never sees unassigned projects on refresh', (tester) async {
  await harnessAuth.signIn(role: UserRole.inspector, userId: 'inspector-a');
  await harnessDriver.pullToRefresh(screen: 'ProjectListScreen');

  // Assert at every frame while the refresh is in-flight:
  final frames = await harnessDriver.captureFrames(duration: Duration(seconds: 5));
  for (final frame in frames) {
    expect(frame.projectListState.projectIds, containsAll(inspectorAAssignments));
    expect(frame.projectListState.projectIds.toSet().difference(inspectorAAssignments.toSet()),
           isEmpty, reason: 'phantom project visible in frame at ${frame.timestamp}');
  }
});
```

## Concern: RLS denial detection (Phase 4)

`lib/features/sync/engine/sync_error_classifier.dart:189`:

```dart
static ClassifiedSyncError _classifyPostgrestError(
  PostgrestException error,
  String context,
  int retryCount,
) {
  // 42501 = insufficient_privilege (RLS denial)
  // Classified as non-retryable, surfaced to logging event class
  // 'sync.rls.denied' in Phase 4.
}
```

Phase 4 must add `Logger.sync(LogEventClasses.rlsDenial, data: {...})` at the site where `_classifyPostgrestError` detects `42501`. The current call path already raises a user-safe message; the new log call is additive.

## Concern: Sentry dedup middleware boundary (Phase 4)

Current boundary: `Logger.error` → `LoggerErrorReporter` → `LoggerSentryTransport.report` → `Sentry.captureException`. The PII filter runs inside the Sentry SDK via `beforeSend`.

New boundary for Phase 4:

```
Logger.error
  → log-level filter                          (drop < warning)
  → sampling filter                           (drop 90% of sync.* info, 0% of errors)
  → dedup middleware                          (drop repeat fingerprints in 60s window)
  → rate limit                                (drop if user already hit 50 events today)
  → breadcrumb budget                         (trim breadcrumbs to 30)
  → LoggerSentryTransport.report               (existing)
  → Sentry SDK beforeSendSentry (PII scrub)    (existing, unchanged)
  → Sentry servers
```

Each middleware is composable. Each short-circuits to no-op when consent not granted.

## Concern: soak driver action mix (Phase 5)

```dart
// integration_test/sync/soak/soak_driver.dart (new)
class SoakDriver {
  SoakDriver({
    required this.userCount,          // 20
    required this.duration,           // 5, 10, 15 minutes
    required this.actionMix,          // weighted
  });

  static const defaultMix = ActionMix(
    readWeight: 30,
    entryMutationWeight: 30,
    photoUploadWeight: 15,
    deleteRestoreWeight: 20,
    roleAssignmentWeight: 5,
  );

  Future<SoakResult> run() async {
    // For each virtual user:
    //   - authenticate with a seeded fixture user
    //   - loop: pick a weighted action, execute it via the driver client
    //   - collect metrics from /diagnostics/sync_transport every minute
    //   - on 42501 or other errors: classify, record, continue
  }
}
```

Target metrics:
- Cold-start full sync ≤ 2 seconds
- Foreground unblock ≤ 500ms warm / ≤ 2s cold (with empty-state placeholder)
- +10% regression gate against baseline

## Concern: fixture seeding with triggers off (Phase 1)

`test/helpers/sync/sync_test_data.dart:664` (client-side pattern — mirror in server-side seed.sql):

```
UPDATE sync_control SET value = '1' WHERE key = 'pulling';  -- suppress triggers
INSERT INTO companies (...) VALUES (...);
INSERT INTO projects (...) VALUES (...);
-- FK-ordered inserts
UPDATE sync_control SET value = '0' WHERE key = 'pulling';  -- restore triggers
```

For **server-side** `supabase/seed.sql`: the `sync_control` table is local-only (SQLite). Server-side seeding bypasses RLS via service role credentials. No trigger suppression is needed server-side because the triggers in `sync_engine_tables.dart` do not exist on Postgres — they are local SQLite only.

## Concern: staging schema-hash gate (Phase 7)

Pattern extension of `scripts/verify_live_supabase_schema_contract.py`. The new gate compares **three** schema hashes:

- Local Docker Supabase (hashed from `supabase/migrations/` applied to a throwaway local DB).
- Staging Supabase (hashed from the live staging via `supabase db query`).
- Production Supabase (hashed the same way, when `PROD_SUPABASE_DATABASE_URL` is set).

Failure mode: a migration applied to staging but not prod **blocks the prod apply step**. A migration that fails on staging **blocks merge**. The existing `verify_live_supabase_schema_contract.py` queries schema columns + RLS state; the new script adds a stable schema hash (e.g., SHA-256 of normalized `information_schema.columns` + `pg_policies` output ordered by table/column/policy name).

## Concern: in-app "Report a problem" flow (Phase 4)

Current surface:
- `lib/core/config/sentry_feedback_launcher.dart` — class `SentryFeedbackLauncher`.
- `lib/features/settings/presentation/screens/help_support_screen.dart:200` — `_openSentryFeedback()` method.

Extend to capture:
- Last 30 breadcrumbs (already configured via breadcrumb budget).
- Recent logs from the session directory (`Logger.sessionDirectory`).
- User id (scrubbed of email).
- Project id (current selection).
- Device info via `device_info_plus` (already a dependency).

## Concern: keeping existing characterization tests green during rewrite (Phase 6)

`test/features/sync/characterization/` has 15 files. These are frozen-truth tests of current behavior. Rewrite must not regress them until the harness replaces a specific contract. Example coexistence rule:

- If `characterization_pull_cursor_test.dart` still asserts the current cursor-advance behavior, the rewrite must either (a) keep it green, or (b) delete it with the same commit that replaces it with a more honest harness assertion.
- Do not bulk-delete characterization tests. Delete case-by-case with a commit message that cites the harness test replacing it.

## Concern: auto-issue policy generalization (Phase 7)

Current lint auto-issue shape (in `quality-gate.yml`):
```
rule -> FILE_LINE mapping -> one issue per rule (not per rule+file)
auto-updates on every push, auto-closes when zero violations
```

New shared policy extends with:
```
fingerprint = rule | sentry-fingerprint | soak-regression-id
rate limit  = 1 issue per fingerprint per 24h
threshold   = ≥2 distinct users OR ≥5 occurrences in 15 minutes
auto-close  = 7 days with zero new events
severity    = fatal (immediate), error (threshold), warning (digest only)
stability   = 3-night grace before nightly soak can auto-file
```

All of lint, Sentry error dedup, and nightly soak regressions flow through the same `scripts/github_auto_issue_policy.py` to keep behavior consistent and user-friendly.
