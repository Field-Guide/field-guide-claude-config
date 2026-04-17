# Ground Truth — Sync System Hardening And Harness

All literals below have been verified against the codebase at tailor time. Unverified or missing items are flagged in the "Gaps" section at the end.

## Sync engine — classes, symbols, invariants

- `lib/features/sync/engine/sync_engine.dart` — class `SyncEngine` (lines 33+). Entry methods: `pushAndPull({SyncMode mode = SyncMode.full, bool requireDirtyScopes = false})` at 92, `pushOnly()` at 190, `pullOnly()` at 202. Internal routers: `_executePush(SyncMode)` at 213, `_executePull(SyncMode, {bool onlyDirtyScopes})` at 226. Mutable callback setters: `onPullComplete`, `onCircuitBreakerTrip`, `onNewAssignmentDetected`.
- `lib/features/sync/application/sync_coordinator.dart` — class `SyncCoordinator`. Public entrypoint `syncLocalAgencyProjects({SyncMode mode, bool recordManualTrigger, bool requireDirtyScopes})` at 221. Internal cycle `_doSync(...)` at 241. Transport status accessors `status`, `lastSyncTime`, `statusStore`, `eventSink`, `isSyncing`, `isSupabaseOnline`, `dirtyScopeTracker`. Builder constructor `fromBuilder(...)` at 72. `forTesting(DatabaseService)` at 133.
- `lib/features/sync/engine/sync_error_classifier.dart` — class `SyncErrorClassifier`. Public `classify(Object, {String? tableName, String? recordId, int retryCount})` at 126. Static helpers `isRemoteSchemaCompatibilityError`, `isMissingRemoteTableError`, `remoteSchemaMissingTableMessage`, `isTransientResult`. Internal: `_classifyPostgrestError`, `_classifyErrorMessage`, `_sanitizeForUi`.
- `lib/features/sync/domain/sync_status.dart` — class `SyncStatus` is `@immutable`. Fields: `isUploading`, `isDownloading`, `lastSyncedAt`, `uploadError`, `downloadError`, `isOnline`, `isAuthValid`, `pendingUploadCount`, `downloadProgress`. Derived getters: `isSyncing`, `hasError`, `isHealthy`, `hasPendingChanges`. Companion `ClassifiedSyncErrorSummary` at 178 with `fromClassified` factory.
- `lib/features/sync/engine/sync_registry.dart` — global `registerSyncAdapters({SyncRegistry? registry})` registers 26 adapters in strict FK order. Order is load-bearing. Class `SyncRegistry` with singleton `SyncRegistry.instance`, `registerAdapters(List<TableAdapter>)`, `adapterFor(String)`, `dependencyOrder`, `childFkColumnsFor(String parentTable)`.
- `lib/features/sync/adapters/simple_adapters.dart` — `const simpleAdapters = <AdapterConfig>[...]`. Tables registered: `projects`, `project_assignments`, `locations`, `contractors`, `bid_items`, `personnel_types`, `entry_contractors`, `entry_personnel_counts`, `entry_quantities`, `todo_items`, `calculation_history`, `entry_exports`, `form_exports`, `export_artifacts`, `pay_applications`, `signature_files`, `signature_audit_log`. Complex adapters (separate files): `EquipmentAdapter`, `DailyEntryAdapter`, `PhotoAdapter`, `EntryEquipmentAdapter`, `InspectorFormAdapter`, `FormResponseAdapter`, `DocumentAdapter`, `SupportTicketAdapter`, `ConsentRecordAdapter`.
- `lib/core/database/schema/sync_engine_tables.dart` — `SyncEngineTables.triggeredTables` (24 tables). `tablesWithDirectProjectId`, `tablesWithBuiltinFilter = ['inspector_forms']`, `entryScopedProjectIdTables`, `assignmentScopedPullCursorTables`, `localOnlyExportHistoryTables = ['entry_exports', 'form_exports', 'export_artifacts']`. `sync_control` table seeded with `('pulling', '0')`. `triggersForTable(String)` auto-generates INSERT/UPDATE/DELETE triggers gated on `sync_control.pulling = '0'`.

## Sync hint contracts

- `lib/features/sync/engine/sync_hint_remote_emitter.dart` — abstract `SyncHintRemoteEmitter.emit({companyId, tableName, scopeType, projectId})`. Concrete `RpcSyncHintRemoteEmitter` calls `supabaseClient.rpc('emit_sync_hint', params: {'p_company_id', 'p_project_id', 'p_table_name', 'p_scope_type'})`. Also `NoopSyncHintRemoteEmitter`.
- `lib/features/sync/application/realtime_hint_handler.dart` — class `RealtimeHintHandler` owns `registerAndSubscribe(String companyId)`, `_handleHint(Map)`, `_triggerQuickSync(...)`, `_drainQueuedQuickSync()`, `deactivateChannelForSignOut(...)`, `rebind(String?)`, `dispose()`. Throttle constant `_minSyncInterval = Duration(seconds: 30)`.
- RPC `public.emit_sync_hint(UUID, UUID, TEXT, TEXT)` defined at `supabase/migrations/20260408160000_sync_hint_final_state.sql:636`. Raises `emit_sync_hint: not authenticated`, `emit_sync_hint: user has no company_id`, `emit_sync_hint: cross-company emit denied`. `REVOKE EXECUTE ... FROM public; GRANT EXECUTE ... TO authenticated`.
- RPC `public.deactivate_sync_hint_channel(p_device_install_id)` called from `RealtimeHintHandler.deactivateChannelForSignOut`.

## Driver / screen contract surface

- `lib/core/driver/screen_registry.dart` — `Map<String, ScreenRegistryEntry> screenRegistryEntries` (39 entries). Derived `screenRegistry` (builders only) at 290 and `screenRegistrySeedArgs` at 294.
- `lib/core/driver/screen_contract_registry.dart` — class `ScreenContract({id, rootKey, routes, seedArgs, actionKeys, stateKeys})`. `toDiagnosticsMap({activeRoute, visibleRootKeys})` at 22. `Map<String, ScreenContract> screenContracts` with 32 screen contracts. `Set<String> screenContractRootKeys`. `ScreenContract? resolveActiveScreenContract({route, visibleRootKeys})` at 380. Private helpers `_serializeKey(Key?)`, `_matchesRoute(route, pattern)`.
- `lib/core/driver/flow_registry.dart` — `Map<String, FlowDefinition> flowRegistry` spread from `formsFlowDefinitions`, `navigationFlowDefinitions`, `verificationFlowDefinitions`.
- `lib/core/driver/driver_diagnostics_handler.dart` — class `DriverDiagnosticsRoutes` exposes routes: `/diagnostics/breakpoint`, `/diagnostics/density`, `/diagnostics/animation`, `/diagnostics/theme`, `/diagnostics/wizards`, `/diagnostics/observable_controllers`, `/diagnostics/screen_contract`, `/diagnostics/sync_transport`, `/diagnostics/sync_runtime`, `/diagnostics/gocr-trace`. Handler is HTTP-based.
- Sync-facing payloads already published by `_handleSyncTransport`: `transportHealth`, `lastRun: {pushed, pulled, errors, rlsDenials, durationMs, completedAt, wasSuccessful}`. `_handleSyncRuntime`: `lastRequestedMode`, `lastRunHadDirtyScopesBeforeSync`, `stateFingerprint`, `dirtyScopes[]`.

## Role, auth, and project assignment plumbing

- `lib/features/auth/presentation/providers/auth_provider.dart` — class `AuthProvider extends ChangeNotifier`. Subscribes to `_authService.authStateChanges` in constructor (line 101). Emits `notifyListeners()` on sign-in, sign-out, `AuthChangeEvent.passwordRecovery`. Role getters: `isAdmin`, `isEngineer`, `isOfficeTechnician`, `isInspector`. Capability getters: `canManageProjects`, `canEditFieldData`, `canManageProjectFieldData`, `canReviewInspectorWork`. Profile freshness windows `_cachedProfileFieldWorkWindow`, `_sharedManagementFreshnessWindow`, `_profileRefreshAttemptInterval`.
- `lib/features/auth/data/models/user_role.dart` — `UserRole` enum used throughout; includes `admin`, `engineer`, `officeTechnician`, `inspector`. Deprecated `viewer` fallback handled in migration `20260317100000_remove_viewer_role.sql`.
- `lib/features/projects/presentation/providers/project_provider_auth_controller.dart` — class `ProjectProviderAuthController.initWithAuth(...)` at 59 wires listener `onAuthChanged`. On auth change: calls `_loadAssignments(newUserId)` when user or role changed, `_loadProjectsByCompany(newCompanyId)` when company changed, triggers `syncCoordinator.syncLocalAgencyProjects(mode: SyncMode.quick)`. On sign-out: nulls user/role, clears screen cache.
- `lib/features/projects/presentation/providers/project_provider.dart` — `ProjectProvider extends ChangeNotifier` composes mixins `ProjectProviderFilters`, `ProjectProviderDataActions`, `ProjectProviderMutations`, `ProjectProviderSelection`, `ProjectProviderAuthInit`. State fields: `_projects`, `_remoteProjects`, `_mergedProjects`, `_assignedProjectIds` (Set<String>), `_assignmentsLoaded` (bool), `_currentUserRole`, `_companyId`, `_companyFilter` (CompanyFilter enum), `_searchQuery`. Part files: `project_provider_auth_init.dart`, `project_provider_data_actions.dart`, `project_provider_filters.dart`, `project_provider_mutations.dart`, `project_provider_selection.dart`.
- `lib/features/projects/presentation/providers/project_assignment_provider.dart` — `ProjectAssignmentProvider extends ChangeNotifier` holds wizard-time mutation plan (`_assignedUserIds`, `_originalAssignedUserIds`, `_lockedUserId`). `buildMutationPlan()` at 99 returns `ProjectAssignmentMutationPlan`. `loadForProject`, `ensureCreatorAssignment`, `toggleAssignment`, `markSaved`, `clear`.
- `lib/features/sync/engine/synced_scope_store.dart` — `SyncedScopeStore.getActiveAssignmentProjectIds` and `LocalSyncStoreScope.getActiveAssignmentProjectIds` return the locally-synced assigned project list — the assignment filter source for pre-first-render render ordering.

## Logging + Sentry current state

- `lib/core/logging/logger.dart` — class `Logger` with category methods: `sync`, `pdf`, `db`, `auth`, `ocr`, `nav`, `ui`, `photo`, plus `error`, `warn`, `info`. Part files: `logger_file_transport.dart`, `logger_http_transport.dart`, `logger_runtime_hooks.dart`. Session dir + per-category log files + flat `app_session.log`. HTTP transport gated on `--dart-define=DEBUG_SERVER=true`. Logs: `ocr.log`, `pdf_import.log`, `sync.log`, `database.log`, `auth.log`, `navigation.log`, `errors.log`, `ui.log`, `app_session.log`. Retention: 14 days. Max size: 50 MB.
- `lib/core/logging/logger_sentry_transport.dart` — class `LoggerSentryTransport.report({message, error, stack, category, data})`. Uses `Sentry.captureException` when error non-null, else `Sentry.captureMessage(message, level: SentryLevel.error)`. Consent-gated via `isSentryReportingEnabled`.
- `lib/core/logging/logger_error_reporter.dart` — class `LoggerErrorReporter` (bridge to PlatformDispatcher error hooks).
- `lib/core/config/sentry_runtime.dart` — `const String sentryDsn = String.fromEnvironment('SENTRY_DSN')`. Flags: `isSentryConfigured`, `isSentryReportingEnabled`, `isSentryFeedbackAvailable`.
- `lib/core/config/sentry_consent.dart` — private `_sentryConsentGranted` flag with getter `sentryConsentGranted`, setters `enableSentryReporting()`, `disableSentryReporting()`.
- `lib/core/config/sentry_pii_filter.dart` — `SentryEvent? beforeSendSentry(SentryEvent, Hint)` scrubs PII in exceptions, breadcrumbs, message, tags, extra; nulls out `user`, `request`. `FutureOr<SentryTransaction?> beforeSendTransaction(...)` drops transactions without consent.
- `lib/main.dart` — `SentryFlutter.init` configured with `tracesSampleRate: 0.1`, `attachScreenshot: false`, `attachViewHierarchy: false`, session replay `sessionSampleRate: 1.0`, `onErrorSampleRate: 1.0`, `privacy.maskAllText: true`, `privacy.maskAllImages: true`. Wraps `runApp` in `SentryWidget`. `runZonedGuarded` catches uncaught async; `Logger.zoneSpec()` routes `print` through the file logger.
- `pubspec.yaml` — `sentry_flutter: ^9.16.0`. No `glados` dependency yet.

## Custom lint rules already enforcing sync invariants

Verified present under `fg_lint_packages/field_guide_lints/lib/`:

- `sync_integrity/rules/push_handler_requires_sync_hint_emitter.dart`
- `sync_integrity/rules/no_sync_hint_rpc_outside_approved_owners.dart`
- `sync_integrity/rules/no_sync_hint_broadcast_subscription_outside_realtime_handler.dart`
- `sync_integrity/rules/no_client_sync_hint_broadcast_http.dart`
- `sync_integrity/rules/no_sync_status_column.dart`
- `sync_integrity/rules/sync_control_inside_transaction.dart`
- `sync_integrity/rules/sync_time_on_success_only.dart`
- `sync_integrity/rules/tomap_includes_project_id.dart`
- `architecture/rules/max_ui_callable_length.dart`
- `architecture/rules/max_ui_file_length.dart`
- `architecture/rules/screen_registry_contract_sync.dart`
- `architecture/rules/single_composition_root.dart`
- `architecture/rules/no_business_logic_in_di.dart`
- `architecture/rules/no_datasource_import_in_presentation.dart`
- `architecture/rules/avoid_supabase_singleton.dart`
- `architecture/rules/no_silent_catch.dart`

## CI, CI scripts, and drift validators

- `.github/workflows/quality-gate.yml` — three jobs: `analyze-and-test`, `architecture-validation`, `security-scanning`. `analyze-and-test` calls `python scripts/verify_live_supabase_schema_contract.py` when `LIVE_SUPABASE_DATABASE_URL` secret is set. `architecture-validation` calls `python scripts/validate_sync_adapter_registry.py`, `python scripts/check_changed_migration_rollbacks.py`, `python scripts/validate_migration_rollbacks.py`, `python scripts/verify_database_schema_platform_parity.py`. `security-scanning` does heuristic greps for Supabase singleton, raw delete, path traversal, `sync_control` boundary, `change_log` cleanup.
- Existing GitHub auto-issue pipeline (in `analyze-and-test`, "Sync lint violations to GitHub Issues" step): fingerprints by `RULE:::FILE`, 1 open issue per rule (not per rule+file), auto-closes when zero violations; labels `lint,tech-debt,automated`. **This pre-existing noise policy is the shape Success criterion 10 extends**, not greenfield.
- `scripts/validate_sync_adapter_registry.py` — validates `SyncEngineTables.triggeredTables` ↔ `simple_adapters.dart` ↔ complex `*_adapter.dart` ↔ `sync_registry.dart` `registerAdapters([...])`. Enforces FK-dependency registration order. Known `LOCAL_ONLY_REGISTRY_TABLES = {'entry_exports', 'export_artifacts', 'form_exports'}`.
- `scripts/verify_live_supabase_schema_contract.py` — queries Supabase (via `supabase db query --db-url`) to confirm: registered tables exist with expected columns, RLS enabled, RLS policy count > 0, storage buckets exist, buckets are private, buckets have policies. Reads `DATABASE_URL` from env or `.env.secret`.
- No `scripts/audit_logging_coverage.ps1` yet. No `scripts/soak_local.ps1` yet. (Both are new deliverables under Scope.)

## Supabase local project shape

- `supabase/config.toml` — `project_id = "Field_Guide_App"`. API on port 54321, DB on port 54322. Schemas `public`, `graphql_public`. Extra search path `public, extensions`. `max_rows = 1000`.
- `supabase/migrations/` contains 71 migrations. First: `20260101000000_bootstrap_base_schema.sql`. Latest (as indexed): `20260412150000_add_company_cloud_ocr_config.sql`. Rollbacks in `supabase/rollbacks/`.
- `supabase/seed.sql` currently has only a header comment — **no seeded data yet**. Spec requires ~10-20 user seeded fixture for the harness.
- Edge functions: `daily-sync-push`, `google-cloud-vision-ocr`, `google-document-ai-ocr` — Scope preserves these.

## Existing test fixtures + harness precedent

- `test/helpers/sync/sync_test_data.dart` — `SyncTestData` with static map factories for every synced table: `projectMap`, `projectAssignmentMap`, `locationMap`, `contractorMap`, `equipmentMap`, `bidItemMap`, `personnelTypeMap`, `dailyEntryMap`, `photoMap`, `entryEquipmentMap`, `entryQuantityMap`, `entryContractorMap`, `entryPersonnelCountMap`, `inspectorFormMap`, `formResponseMap`, `todoItemMap`, `calculationHistoryMap`, `formExportMap`, `entryExportMap`, `documentMap`, `exportArtifactMap`, `payApplicationMap`, `supportTicketMap`, `consentRecordMap`. Helper `seedFkGraph(Database)` seeds a full FK-connected graph with triggers suppressed. **This is the established fixture pattern the seeded harness fixture should extend, not replace.**
- `test/helpers/sync/sync_engine_test_helpers.dart`, `sync_test_helpers.dart`, `maintenance_test_helpers.dart`, `fake_supabase_sync.dart`, `test_sync_adapters.dart`, `sqlite_test_helper.dart` — existing helper surface for sync unit + characterization tests. Harness should use these where applicable rather than fork.
- `test/features/sync/characterization/` holds 15 characterization tests for pull cursor, pull conflict, pull dirty scope, pull scope, pull tombstone, pull trigger suppression, pull upsert, push company_id, push delete, push LWW, push skip, push upsert, realtime hint, retry policy, error classification, sync modes, lifecycle trigger, diagnostics, `SyncStatus` contract. **Spec: these coexist with the new harness; delete only when the harness proves the same contract more honestly.**
- `integration_test/` currently contains only PDF / OCR integration tests. No sync-flavored integration tests yet — harness lands as a new family.

## Driver / CI tooling

- PowerShell wrappers: `tools/build.ps1`, `tools/start-driver.ps1`, `tools/stop-driver.ps1`, `tools/wait-for-driver.ps1`, `tools/verify-sync.ps1`, `tools/run_and_tail_logs.ps1`, `tools/run_tests_capture.ps1`.
- Existing driver endpoints (from `DriverInteractionHandler`, `DriverDataSyncHandler`) provide real Flutter client automation; harness can reuse them rather than introducing a new driver.

## Testing Keys

- `lib/shared/testing_keys/testing_keys.dart` — canonical `TestingKeys` registry referenced in `screen_contract_registry.dart`. Spec: never hardcode `Key('...')`. Use these.

---

## Gaps flagged

These are spec-acknowledged new deliverables, not drift. Listed here so writing-plans does not assume they already exist:

1. **No `glados` dependency.** `pubspec.yaml` at `dev_dependencies` does not include `glados`. Adding it is Phase 5 (PBT).
2. **`supabase/seed.sql` is empty.** Only a header comment. Seeded fixture (~10–20 users × multi-project) is a Phase 1 deliverable.
3. **No staging Supabase project provisioned.** Spec requires a dedicated Pro-plan staging project for Log Drains. Not in tree; external provisioning step.
4. **No `scripts/audit_logging_coverage.ps1`.** Must be created in Phase 4 (logging event-class audit). Spec names the exact path.
5. **No `scripts/soak_local.ps1`.** Must be created in Phase 5 (soak driver). Spec names the exact path.
6. **No harness skeleton directory.** No `integration_test/sync/` or `test/harness/` tree yet. Phase 2 creates it.
7. **Sentry filter is partial.** `main.dart` has consent gate + PII scrubber + session replay config. The five-layer filter (log-level / sampling / dedup / rate-limit / breadcrumb budget) is not yet wired. Phase 4 extends current hooks.
8. **No Supabase Log Drain webhook.** The `google-cloud-vision-ocr` / `daily-sync-push` edge functions exist but no dedicated Log Drain sink. Phase 4 deliverable.
9. **GitHub auto-issue noise policy is rule-keyed only.** The current CI step does per-rule dedup + auto-close for lint violations. Success criterion 10 generalizes this to all auto-filers (RLS denials, retry exhaustion, nightly soak) with fingerprint grouping, rate limit 1/fingerprint/24h, ≥2-user threshold, severity routing. Phase 7 generalizes the existing shape.
10. **Logger has no `LoggerSentryLogsTransport` or dedup middleware.** Current `LoggerSentryTransport` reports directly via `Sentry.captureException` / `captureMessage`. Dedup middleware + rate-limit + breadcrumb budget must be added in Phase 4 — probably as a wrapper transport.
11. **No event-class registry file.** Spec's "locked must-log event classes" list is not yet declared anywhere in code. Phase 4 should add an owner file (e.g. `lib/core/logging/log_event_classes.dart`) that the audit script reads.

## Non-obvious invariants worth flagging to the plan writer

- `simpleByTable` lookup in `sync_registry.dart` is `simpleByTable['<table>']!` — sentinel `!` means the registry will crash at boot if `simple_adapters.dart` loses a key. Any rewrite must keep both files in lockstep.
- `screenContracts` and `screenRegistryEntries` are two separate maps. Screen registry is for driver-built test harness shells; screen contract registry is for `/diagnostics/screen_contract` inspection. **The harness in this initiative writes to both.** `screen_registry_contract_sync` lint rule enforces parity.
- Foreground / background sync parity: `background_sync_handler.dart` calls `registerSyncAdapters()` from `sync_registry.dart` so both paths share the adapter list. CI "Sync bootstrap parity" step in `quality-gate.yml` guards this. Harness must not call `registerSyncAdapters` on a second registry; use `SyncRegistry.instance`.
- `sync_control.pulling = '1'` suppresses triggers. Harness seed / restore code must bracket inserts with `UPDATE sync_control SET value = '1'` / `'0'` (see `SyncTestData.seedFkGraph` lines 665–748 for the canonical pattern).
- RLS policy PostgreSQL error code `42501` is classified as non-retryable (security boundary) by `SyncErrorClassifier`; plan must not regress this.
- `is_builtin = 1` rows on `inspector_forms` are skipped by triggers (see `tablesWithBuiltinFilter` at `sync_engine_tables.dart:321`). Harness seed data must not introduce client-visible builtins.
- `tracesSampleRate: 0.1` is already set in `main.dart`. The five-layer filter's "sampling" layer is partially there for transactions. Errors are currently all-through (consent-gated). The log-level filter layer must not regress this for existing `Logger.error` calls.
