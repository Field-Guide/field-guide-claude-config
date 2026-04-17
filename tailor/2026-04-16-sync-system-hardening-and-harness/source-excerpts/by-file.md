# Source Excerpts — By File

Only the snippets the plan writer is likely to need. For full files, use `Read` directly with the paths shown.

## `lib/features/sync/engine/sync_engine.dart` (key entrypoints)

```dart
class SyncEngine {
  SyncEngine({
    required PushHandler pushHandler,
    required PullHandler pullHandler,
    required MaintenanceHandler maintenanceHandler,
    required SyncMutex mutex,
    required LocalSyncStore localStore,
    SyncRunLifecycle? runLifecycle,
    SyncStatusStore? statusStore,
    SyncEventSink? eventSink,
    required this.lockedBy,
    DirtyScopeTracker? dirtyScopeTracker,
  });

  // Line 70
  set onPullComplete(Future<void> Function(String, int)? callback);
  // Line 74
  set onCircuitBreakerTrip(void Function(String, String, int)? callback);
  // Line 81
  set onNewAssignmentDetected(void Function(String)? callback);

  // Line 92 — the single mode router
  Future<SyncEngineResult> pushAndPull({
    SyncMode mode = SyncMode.full,
    bool requireDirtyScopes = false,
  });

  Future<SyncEngineResult> pushOnly();   // line 190 — test-only
  Future<SyncEngineResult> pullOnly();   // line 202 — test-only
}
```

## `lib/features/sync/application/sync_coordinator.dart` (public entry)

```dart
class SyncCoordinator {
  // Line 72
  SyncCoordinator.fromBuilder({
    required DatabaseService dbService,
    SupabaseClient? supabaseClient,
    required SyncEngineFactory engineFactory,
    required ({String? companyId, String? userId}) Function() syncContextProvider,
    DirtyScopeTracker? dirtyScopeTracker,
    ConnectivityProbe? connectivityProbe,
    SyncRetryPolicy? retryPolicy,
    PostSyncHooks? postSyncHooks,
    SyncQueryService? queryService,
    SyncStatusStore? statusStore,
    SyncEventSink? eventSink,
    Duration? authContextMaxWait,
    Duration? authContextPollInterval,
  });

  // Line 174 — transport getters
  SyncAdapterStatus get status;
  DateTime? get lastSyncTime;
  SyncStatusStore get statusStore;
  SyncEventSink get eventSink;
  bool get isSyncing;
  bool get isSupabaseOnline;
  DirtyScopeTracker? get dirtyScopeTracker;

  // Line 187
  Future<bool> isSyncGateActive();
  Future<void> initialize();   // line 193

  // Line 221 — the public sync entrypoint
  Future<SyncResult> syncLocalAgencyProjects({
    SyncMode mode = SyncMode.full,
    bool recordManualTrigger = false,
    bool requireDirtyScopes = false,
  });
}
```

## `lib/features/sync/engine/sync_error_classifier.dart` (classification contract)

```dart
class SyncErrorClassifier {
  const SyncErrorClassifier();

  // Line 37
  static bool isRemoteSchemaCompatibilityError(Object error, {String? tableName, String? columnName});

  // Line 75
  static bool isMissingRemoteTableError(Object error, {String? tableName});

  // Line 112
  static String remoteSchemaMissingTableMessage(String tableName);

  // Line 126 — the single classify entrypoint
  static ClassifiedSyncError classify(
    Object error, {
    String? tableName,
    String? recordId,
    int retryCount = 0,
  });

  // Line 397
  static bool isTransientResult(SyncResult result);
}
```

RLS denial (`42501`) handling lives in `_classifyPostgrestError` (line 189). Do not regress the non-retryable classification.

## `lib/features/sync/domain/sync_status.dart` (immutable state contract)

```dart
@immutable
class SyncStatus {
  const SyncStatus({
    this.isUploading = false,
    this.isDownloading = false,
    this.lastSyncedAt,
    this.uploadError,
    this.downloadError,
    this.isOnline = true,
    this.isAuthValid = true,
    this.pendingUploadCount = 0,
    this.downloadProgress,
  });

  bool get isSyncing;            // isUploading || isDownloading
  bool get hasError;             // uploadError != null || downloadError != null
  bool get isHealthy;            // isOnline && isAuthValid && !hasError
  bool get hasPendingChanges;    // pendingUploadCount > 0

  SyncStatus copyWith({ /* sentinel-pattern nullable fields */ });
}

@immutable
class ClassifiedSyncErrorSummary {
  const ClassifiedSyncErrorSummary({
    required this.kind,
    required this.userSafeMessage,
    required this.retryable,
  });

  factory ClassifiedSyncErrorSummary.fromClassified(ClassifiedSyncError error);
}
```

## `lib/features/sync/engine/sync_hint_remote_emitter.dart` (full file, 49 lines)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SyncHintRemoteEmitter {
  const SyncHintRemoteEmitter();
  Future<void> emit({
    required String companyId,
    required String tableName,
    required String scopeType,
    String? projectId,
  });
}

class RpcSyncHintRemoteEmitter extends SyncHintRemoteEmitter {
  final SupabaseClient _supabaseClient;
  const RpcSyncHintRemoteEmitter(this._supabaseClient);

  @override
  Future<void> emit({/* ... */}) {
    return _supabaseClient.rpc(
      'emit_sync_hint',
      params: {
        'p_company_id': companyId,
        'p_project_id': projectId,
        'p_table_name': tableName,
        'p_scope_type': scopeType,
      },
    );
  }
}

class NoopSyncHintRemoteEmitter extends SyncHintRemoteEmitter {
  const NoopSyncHintRemoteEmitter();
  @override
  Future<void> emit({/* ... */}) async {}
}
```

## `lib/features/sync/application/realtime_hint_handler.dart` (throttle + sign-out)

```dart
class RealtimeHintHandler {
  static const Duration _minSyncInterval = Duration(seconds: 30);
  static const Duration _defaultFallbackPollInterval = Duration(seconds: 20);

  factory RealtimeHintHandler({
    required SupabaseClient supabaseClient,
    required SyncCoordinator syncCoordinator,
    String? companyId,
    String? deviceInstallId,
    String? appVersion,
    SyncEventSink? eventSink,
    Duration fallbackPollInterval = _defaultFallbackPollInterval,
    void Function(Map<String, dynamic> status)? onTransportHealthChanged,
  });

  static Future<void> deactivateChannelForSignOut({
    required SupabaseClient supabaseClient,
    required String deviceInstallId,
  });

  Future<void> registerAndSubscribe(String companyId);
  Future<void> rebind(String? companyId);
  Future<void> dispose();
}
```

## `lib/features/auth/presentation/providers/auth_provider.dart` (role + state-change shape)

```dart
class AuthProvider extends ChangeNotifier {
  // Line 101 — state change subscription
  _authSubscription = _authService.authStateChanges.listen((state) {
    if (state.event == AuthChangeEvent.passwordRecovery) { /* recovery path */ }
    final incoming = state.session?.user;
    final wasAuthenticated = _currentUser != null;
    _currentUser = incoming;
    if (_currentUser == null) {
      // sign-out path: clear profile, company, recovery state, attribution cache
      _notifyStateChanged();
      return;
    }
    if (!_isPasswordRecovery && !wasAuthenticated && _userProfile == null && !_isLoadingProfile) {
      unawaited(loadUserProfile());
      return;
    }
    _notifyStateChanged();
  });

  // Role getters (line 151+)
  bool get isAdmin             => _userProfile?.role == UserRole.admin;
  bool get isEngineer          => _userProfile?.role == UserRole.engineer;
  bool get isOfficeTechnician  => _userProfile?.role == UserRole.officeTechnician;
  bool get isInspector         => _userProfile?.role == UserRole.inspector;

  // Capability getters
  bool get canManageProjects       => isApproved && (_userProfile?.canManageProjects ?? false) && hasFreshProfileForSharedManagement;
  bool get canEditFieldData        => isApproved && (_userProfile?.canEditFieldData ?? false) && hasUsableProfileForFieldWork;
  bool get canManageProjectFieldData => isApproved && (_userProfile?.canManageProjectFieldData ?? false) && hasUsableProfileForFieldWork;
  bool get canCreateProject        => canManageProjects;
  bool get canReviewInspectorWork  => isApproved && (isEngineer || isOfficeTechnician) && hasFreshProfileForSharedManagement;
}
```

## `lib/features/projects/presentation/providers/project_provider_auth_controller.dart` (flashing-fix target)

```dart
VoidCallback initWithAuth({
  required AuthProvider authProvider,
  required ProjectSettingsProvider settingsProvider,
  required SyncCoordinator syncCoordinator,
  required AppConfigProvider appConfigProvider,
}) {
  _setSettingsProvider(settingsProvider);

  final initialCompanyId = authProvider.userProfile?.companyId;
  final initialUserId    = authProvider.userId;
  final initialRole      = authProvider.userProfile?.role;
  _setCurrentUserId(initialUserId);
  _setCurrentUserRole(initialRole);
  if (initialUserId != null) {
    unawaited(_loadAssignments(initialUserId));   // <-- independent future
  }
  unawaited(
    _loadProjectsForCompanyAndRestoreSelection(initialCompanyId, settingsProvider),  // <-- independent future
  );

  // Listener with same independent-future pattern in onAuthChanged(). Phase 6 fix: await both.
}
```

## `lib/core/driver/driver_diagnostics_handler.dart` (sync-facing diagnostic shape)

```dart
class DriverDiagnosticsRoutes {
  static const screenContract = '/diagnostics/screen_contract';
  static const syncTransport  = '/diagnostics/sync_transport';
  static const syncRuntime    = '/diagnostics/sync_runtime';
  // ... other routes
}

// _handleSyncTransport payload shape (line 245):
{
  'available': true,
  'transportHealth': queryService.transportHealth,  // Map<String, dynamic>
  'lastRun': {
    'pushed': lastRun.pushed,
    'pulled': lastRun.pulled,
    'errors': lastRun.errors,
    'rlsDenials': lastRun.rlsDenials,
    'durationMs': lastRun.duration.inMilliseconds,
    'completedAt': lastRun.completedAt.toIso8601String(),
    'wasSuccessful': lastRun.wasSuccessful,
  },
}

// _handleSyncRuntime payload shape (line 274):
{
  'available': queryService != null || tracker != null,
  'lastRequestedMode': queryService?.lastRequestedMode?.name,
  'lastRunHadDirtyScopesBeforeSync': queryService?.lastRunHadDirtyScopesBeforeSync ?? false,
  'stateFingerprint': { /* appVersion, schemaVersion, repairCatalogVersion, ... */ },
  'dirtyScopeCount': scopes.length,
  'dirtyScopes': [ { 'projectId', 'tableName', 'markedAt' }, ... ],
}
```

## `lib/main.dart` (Sentry init shape)

```dart
await SentryFlutter.init((options) {
  options.dsn = sentryDsn;
  options.tracesSampleRate = 0.1;
  options.beforeSendTransaction = beforeSendTransaction;
  options.beforeSend = beforeSendSentry;
  options.attachScreenshot = false;
  options.attachViewHierarchy = false;
  options.replay.sessionSampleRate = 1.0;
  options.replay.onErrorSampleRate = 1.0;
  options.privacy.maskAllText = true;
  options.privacy.maskAllImages = true;
});

runApp(SentryWidget(child: ConstructionInspectorApp(...)));

// Phase 4: add log-level filter + dedup middleware hook. Suggested shape:
// options.beforeBreadcrumb = loggerBreadcrumbBudget;
// LoggerSentryTransport uses dedup middleware before Sentry.captureException.
```

## `lib/core/logging/logger_sentry_transport.dart` (full file, 50 lines)

```dart
class LoggerSentryTransport {
  static Future<void> report({
    required String message,
    required Object? error,
    required StackTrace? stack,
    required String category,
    required Map<String, dynamic>? data,
  }) async {
    if (!isSentryReportingEnabled) return;

    if (error != null) {
      await Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) async {
          await scope.setTag('category', category);
          await scope.setContexts('logger_message', {'value': message});
          if (data != null && data.isNotEmpty) {
            await scope.setContexts('extra', data);
          }
        },
      );
      return;
    }
    await Sentry.captureMessage(
      message,
      level: SentryLevel.error,
      withScope: (scope) async {
        await scope.setTag('category', category);
        if (data != null && data.isNotEmpty) {
          await scope.setContexts('extra', data);
        }
        if (stack != null) {
          await scope.setContexts('stack_trace', {'value': stack.toString()});
        }
      },
    );
  }
}
```

## `lib/features/sync/engine/sync_registry.dart` (registration order)

```dart
void registerSyncAdapters({SyncRegistry? registry}) {
  final simpleByTable = {
    for (final config in simpleAdapters) config.table: config.toAdapter(),
  };

  final targetRegistry = registry ?? SyncRegistry.instance;
  targetRegistry.registerAdapters([
    simpleByTable['projects']!,
    simpleByTable['project_assignments']!,
    simpleByTable['locations']!,
    simpleByTable['contractors']!,
    EquipmentAdapter(),
    simpleByTable['bid_items']!,
    simpleByTable['personnel_types']!,
    DailyEntryAdapter(),
    PhotoAdapter(),
    EntryEquipmentAdapter(),
    simpleByTable['entry_quantities']!,
    simpleByTable['entry_contractors']!,
    simpleByTable['entry_personnel_counts']!,
    InspectorFormAdapter(),
    FormResponseAdapter(),
    simpleByTable['form_exports']!,
    simpleByTable['export_artifacts']!,
    simpleByTable['pay_applications']!,
    simpleByTable['entry_exports']!,
    DocumentAdapter(),
    simpleByTable['todo_items']!,
    simpleByTable['calculation_history']!,
    SupportTicketAdapter(),
    ConsentRecordAdapter(),
    simpleByTable['signature_files']!,
    simpleByTable['signature_audit_log']!,
  ]);
}
```

Any rewrite must not reorder. FK dependencies require this sequence.

## `test/helpers/sync/sync_test_data.dart` (triggers-off seed pattern)

```dart
static Future<Map<String, String>> seedFkGraph(Database db) async {
  await db.execute("UPDATE sync_control SET value = '1' WHERE key = 'pulling'");

  final companyId = _uuid.v4();
  final projectId = _uuid.v4();
  final locationId = _uuid.v4();
  // ... 11 more IDs up front

  await db.insert('companies', {
    'id': companyId, 'name': 'Test Co',
    'created_at': _ts(), 'updated_at': _ts(),
  });
  await db.insert('projects',      projectMap(id: projectId, companyId: companyId));
  await db.insert('locations',     locationMap(id: locationId, projectId: projectId));
  await db.insert('daily_entries', dailyEntryMap(id: entryId, projectId: projectId, locationId: locationId));
  // ... FK-ordered inserts for contractors, equipment, bid_items, personnel_types ...
  // ... plus form_responses, form_exports, entry_exports, documents ...

  await db.execute("UPDATE sync_control SET value = '0' WHERE key = 'pulling'");
  return { /* id map */ };
}
```
