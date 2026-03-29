# Pre-Release Hardening Implementation Plan — Part 2 (Phases 5-8)

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

---

## Phase 5: Sentry Integration

> **NOTE:** sentry_flutter dependency and SENTRY_DSN .env.example entry are already added in Part 1 Phase 1. Do NOT duplicate them here.

### Sub-phase 5.2: Wrap main() with SentryFlutter.init
**Files:**
- Modify: `lib/main.dart` (lines 109-124)
**Agent:** general-purpose

#### Step 5.2.1: Add sentry_flutter import
Add at the top of `lib/main.dart`, with the other imports:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';
```

#### Step 5.2.2: Replace runZonedGuarded with SentryFlutter.init
Replace the current `main()` function at lines 109-124:

**Old (lines 109-124):**
```dart
Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _runApp();
    },
    (error, stack) {
      Logger.error(
        'Uncaught zone error: $error',
        error: error,
        stack: stack,
      );
    },
    zoneSpecification: Logger.zoneSpec(),
  );
}
```

**New:**
```dart
// WHY: SentryFlutter.init replaces runZonedGuarded — it sets up its own error
// zone internally and captures uncaught errors. The appRunner callback is called
// within Sentry's zone, so all errors propagate to Sentry automatically.
// NOTE: The SENTRY_DSN is injected via --dart-define-from-file=.env at build time.
// When DSN is empty (local dev), Sentry is a no-op.
Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 0.2;
      // WHY: beforeSend scrubs PII before any data leaves the device.
      // Uses the same _scrubString and _scrubSensitive methods as Logger
      // to ensure consistent PII handling across all transports.
      options.beforeSend = _beforeSendSentry;
      // WHY: Disable screenshot capture — construction site photos may contain
      // sensitive project data (addresses, personnel, etc.)
      options.attachScreenshot = false;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      // WHY: Logger.zoneSpec() hooks debugPrint for file logging.
      // SentryFlutter.init already wraps in a zone, so we nest a child zone
      // with our print hooks rather than replacing Sentry's zone.
      await runZonedGuarded(
        () => _runApp(),
        (error, stack) {
          Logger.error(
            'Uncaught zone error: $error',
            error: error,
            stack: stack,
          );
        },
        zoneSpecification: Logger.zoneSpec(),
      );
    },
  );
}
```

> **NOTE:** We keep `runZonedGuarded` inside `appRunner` to preserve Logger's zone-based print capturing. Sentry's outer zone catches unhandled errors; Logger's inner zone captures `debugPrint` output. Both zones work cooperatively.

#### Step 5.2.2b: Create shared Sentry consent flag file
**File:** Create `lib/core/config/sentry_consent.dart`
**Agent:** general-purpose

```dart
/// WHY: Sentry consent flag must be accessible from both main.dart
/// (where _beforeSendSentry reads it) and consent_provider.dart
/// (where acceptConsent() sets it). Extracting to a shared file
/// avoids circular imports.
bool sentryConsentGranted = false;

/// Called by ConsentProvider after consent is accepted.
void enableSentryReporting() {
  sentryConsentGranted = true;
}
```

#### Step 5.2.3: Add _beforeSendSentry function to main.dart
Add this above `main()` in `lib/main.dart` (after the imports, before line 109).
Also add `import 'package:construction_inspector/core/config/sentry_consent.dart';` to main.dart imports.

```dart
/// PII scrubbing for Sentry events before they leave the device.
/// WHY: Security is non-negotiable — no user emails, JWTs, or sensitive
/// data should reach Sentry servers. Uses Logger's existing scrub methods
/// for consistency.
/// Also gates on consent — returns null (drops event) if consent not granted.
SentryEvent? _beforeSendSentry(SentryEvent event, Hint hint) {
  // WHY: Spec says "neither initializes without acceptance". We keep Sentry
  // wrapping main() for infrastructure, but drop all events until consent.
  if (!sentryConsentGranted) return null;

  // Scrub the exception message
  var exceptions = event.exceptions;
  if (exceptions != null) {
    exceptions = exceptions.map((e) {
      final scrubbed = e.value != null ? Logger.scrubString(e.value!) : null;
      return e.copyWith(value: scrubbed);
    }).toList();
  }

  // Scrub breadcrumb messages
  var breadcrumbs = event.breadcrumbs;
  if (breadcrumbs != null) {
    breadcrumbs = breadcrumbs.map((b) {
      final scrubbedMsg = b.message != null ? Logger.scrubString(b.message!) : null;
      return b.copyWith(message: scrubbedMsg);
    }).toList();
  }

  return event.copyWith(
    exceptions: exceptions,
    breadcrumbs: breadcrumbs,
  );
}
```

---

### Sub-phase 5.3: Rename `scrubStringForTest` to `scrubString` (production use case now exists)
**Files:**
- Modify: `lib/core/logging/logger.dart` (line ~701)
**Agent:** backend-data-layer-agent

#### Step 5.3.1: Rename existing scrubStringForTest to scrubString
The existing `scrubStringForTest` method is a public wrapper around `_scrubString`. Now that Sentry's `_beforeSendSentry` in `main.dart` needs it at runtime, rename it to `scrubString` and update any test references that call `scrubStringForTest` to use `scrubString` instead.

Rename in `lib/core/logging/logger.dart`:
```dart
/// Public accessor for PII scrubbing — used by Sentry beforeSend callback
/// and tests.
/// WHY: Sentry PII scrubbing must use the same rules as Logger to prevent
/// inconsistent handling (e.g., emails scrubbed in logs but leaked to Sentry).
static String scrubString(String s) => _scrubString(s);
```

**NOTE:** Search for all usages of `scrubStringForTest` in `test/` and update them to `scrubString`.

---

### Sub-phase 5.4: Add Sentry transport to Logger.error()
**Files:**
- Modify: `lib/core/logging/logger.dart` (line ~228, end of error() method)
**Agent:** backend-data-layer-agent

#### Step 5.4.1: Add Sentry capture call in Logger.error()
Insert before the closing `}` of the `error()` method (after line 227 `_sendHttp(payload);` block, before line 228 `}`):

```dart
    // Sentry transport — send errors to Sentry for crash reporting.
    // WHY: Third transport alongside file and HTTP. Only sends when Sentry
    // is initialized (DSN is non-empty). PII is already scrubbed above.
    // NOTE: We use captureException when we have an actual error object,
    // captureMessage for string-only errors. This gives Sentry proper
    // grouping and stack trace display.
    if (error != null) {
      Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) {
          scope.setTag('category', category);
          if (scrubbedData != null) {
            scope.setContexts('extra', scrubbedData);
          }
        },
      );
    } else {
      Sentry.captureMessage(
        scrubbedMsg,
        level: SentryLevel.error,
        withScope: (scope) {
          scope.setTag('category', category);
        },
      );
    }
```

#### Step 5.4.2: Add Sentry import to logger.dart
Add at the top of `lib/core/logging/logger.dart`:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';
```

---

### Sub-phase 5.5: Add SENTRY_DSN to .env (actual value only)
**Files:**
- Modify: `.env`
**Agent:** general-purpose

> **NOTE:** SENTRY_DSN was already added to `.env.example` in Part 1 Phase 1.2. Do NOT duplicate it here.

#### Step 5.5.1: Add SENTRY_DSN to .env
Add the actual DSN value (ask the user for the DSN, or leave empty for now):

```
SENTRY_DSN=
```

> **NOTE:** The DSN is read via `const String.fromEnvironment('SENTRY_DSN')` which is injected by the build script's `--dart-define-from-file=.env`. When empty, Sentry runs in no-op mode.

---

### Sub-phase 5.6: Verification
**Agent:** qa-testing-agent

#### Step 5.6.1: Static analysis
```
pwsh -Command "flutter analyze"
```

#### Step 5.6.2: Run existing tests
```
pwsh -Command "flutter test"
```

> **WHY:** Sentry integration is mostly runtime. Static analysis confirms no import or type errors. Existing tests confirm nothing is broken. Sentry in no-op mode (empty DSN) should not affect any behavior.

---

## Phase 6: Aptabase Integration
### Sub-phase 6.1: Add aptabase_flutter Dependency
**Files:**
- Modify: `pubspec.yaml`
**Agent:** general-purpose

#### Step 6.1.1: Add aptabase_flutter to pubspec.yaml
Add to the dependencies section:

```yaml
# WHY: Privacy-first analytics. Does not collect PII by design.
# App key is injected via --dart-define-from-file=.env.
aptabase_flutter: ^0.1.0
```

#### Step 6.1.2: Run pub get
```
pwsh -Command "flutter pub get"
```

---

### Sub-phase 6.2: Initialize Aptabase in _runApp()
**Files:**
- Modify: `lib/main.dart` (inside `_runApp()`, after PreferencesService.initialize())
**Agent:** general-purpose

#### Step 6.2.1: Add aptabase import
Add at the top of `lib/main.dart`:

```dart
import 'package:aptabase_flutter/aptabase_flutter.dart';
```

#### Step 6.2.2: Add Aptabase init after PreferencesService
Insert after `await preferencesService.initialize();` (line 134) and before `await _initDebugLogging(preferencesService);` (line 136):

```dart
  // WHY: Aptabase analytics init — only when user has accepted consent
  // and the app key is configured. Aptabase is privacy-first (no PII),
  // but we still respect user consent preferences.
  // NOTE: Must be after PreferencesService because consent state is stored there.
  final consentAccepted = preferencesService.getBool('consent_accepted') ?? false;
  final aptabaseKey = const String.fromEnvironment('APTABASE_APP_KEY');
  if (consentAccepted && aptabaseKey.isNotEmpty) {
    await Aptabase.init(aptabaseKey);
    Logger.lifecycle('Aptabase analytics initialized');
  } else {
    Logger.lifecycle('Aptabase analytics skipped (consent=${consentAccepted}, keyConfigured=${aptabaseKey.isNotEmpty})');
  }
```

---

### Sub-phase 6.3: Add trackEvent calls at key user flow points
**Files:**
- Modify: `lib/features/entries/presentation/screens/home_screen.dart`
- Modify: `lib/features/sync/application/sync_orchestrator.dart`
- Modify: `lib/features/pdf/presentation/screens/` (main PDF screen)
- Modify: `lib/features/auth/presentation/providers/auth_provider.dart`
**Agent:** backend-data-layer-agent

#### Step 6.3.1: Create analytics helper
Create `lib/core/analytics/analytics.dart`:

```dart
import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:construction_inspector/core/logging/logger.dart';

/// Thin wrapper around Aptabase for event tracking.
///
/// WHY: Centralizes analytics calls so we can:
/// 1. Add/remove analytics providers without touching feature code
/// 2. Gate all tracking behind a single consent check
/// 3. Catch and log any analytics errors without crashing the app
///
/// NOTE: All event names use snake_case for consistency.
/// No PII is ever passed as a property — only counts, durations, and enum values.
class Analytics {
  Analytics._();

  /// Track a named event with optional properties.
  /// Silently no-ops if Aptabase is not initialized (no consent or no key).
  static void track(String eventName, [Map<String, dynamic>? props]) {
    try {
      Aptabase.instance.trackEvent(eventName, props);
    } catch (e) {
      // WHY: Analytics must never crash the app. Log and move on.
      Logger.lifecycle('Analytics track error: $e');
    }
  }

  // =========================================================================
  // Pre-defined events — use these instead of raw strings for type safety
  // =========================================================================

  /// User signed in successfully
  static void trackSignIn() => track('user_sign_in');

  /// User signed out
  static void trackSignOut() => track('user_sign_out');

  /// User created a new account
  static void trackSignUp() => track('user_sign_up');

  /// User created a new daily entry
  static void trackEntryCreated() => track('entry_created');

  /// User triggered a manual sync
  static void trackManualSync() => track('sync_manual_triggered');

  /// Sync completed successfully
  static void trackSyncCompleted({int? pushCount, int? pullCount}) =>
      track('sync_completed', {
        if (pushCount != null) 'push_count': pushCount,
        if (pullCount != null) 'pull_count': pullCount,
      });

  /// User imported a PDF
  static void trackPdfImported() => track('pdf_imported');

  /// User generated a report
  static void trackReportGenerated() => track('report_generated');

  /// User opened a form
  static void trackFormOpened({required String formType}) =>
      track('form_opened', {'form_type': formType});

  /// User submitted a form
  static void trackFormSubmitted({required String formType}) =>
      track('form_submitted', {'form_type': formType});

  /// App launched (called once per cold start)
  static void trackAppLaunch() => track('app_launch');
}
```

#### Step 6.3.2: Add trackAppLaunch to _runApp()
Insert at the end of `_runApp()` in `lib/main.dart`, just before the `runApp(ConstructionInspectorApp(...))` call:

```dart
  // WHY: Track cold app launch for usage analytics. No PII.
  Analytics.trackAppLaunch();
```

Add import:
```dart
import 'package:construction_inspector/core/analytics/analytics.dart';
```

#### Step 6.3.3: Add trackSignIn to AuthProvider
In `lib/features/auth/presentation/providers/auth_provider.dart`, after a successful sign-in (where `isAuthenticated` is set to true), add:

```dart
// WHY: Track sign-in for session analytics. No PII — just the event name.
Analytics.trackSignIn();
```

Add import:
```dart
import 'package:construction_inspector/core/analytics/analytics.dart';
```

> **NOTE:** Exact insertion point depends on the sign-in method. Look for where `_isAuthenticated = true` or `notifyListeners()` is called after successful auth. Insert the `Analytics.trackSignIn()` call immediately after.

#### Step 6.3.4: Add trackSignOut to AuthProvider
In the sign-out method of `AuthProvider`, add before the state reset:

```dart
Analytics.trackSignOut();
```

#### Step 6.3.5: Add trackManualSync to sync trigger
In `lib/features/sync/application/sync_orchestrator.dart`, at the start of the manual sync method (the one called by the UI sync button), add:

```dart
Analytics.trackManualSync();
```

Add import:
```dart
import 'package:construction_inspector/core/analytics/analytics.dart';
```

---

### Sub-phase 6.4: Add APTABASE_APP_KEY to .env template
**Files:**
- Modify: `.env.example`
- Modify: `.env`
**Agent:** general-purpose

#### Step 6.4.1: Add APTABASE_APP_KEY to .env.example
```
# Aptabase privacy-first analytics key (leave empty to disable)
APTABASE_APP_KEY=
```

#### Step 6.4.2: Add APTABASE_APP_KEY to .env
```
APTABASE_APP_KEY=
```

---

### Sub-phase 6.5: Verification
**Agent:** qa-testing-agent

#### Step 6.5.1: Static analysis
```
pwsh -Command "flutter analyze"
```

#### Step 6.5.2: Run existing tests
```
pwsh -Command "flutter test"
```

---

## Phase 7: Consent UI & Provider
### Sub-phase 7.1: ConsentProvider
**Files:**
- Create: `lib/features/settings/presentation/providers/consent_provider.dart`
**Agent:** backend-data-layer-agent

#### Step 7.1.1: Create ConsentProvider
```dart
import 'package:flutter/foundation.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/shared/services/preferences_service.dart';
import 'package:construction_inspector/features/settings/data/repositories/consent_repository.dart';
import 'package:construction_inspector/features/settings/data/models/consent_record.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/core/config/sentry_consent.dart';

/// Manages user consent state for analytics and crash reporting.
///
/// WHY: GDPR/privacy compliance requires explicit user consent before
/// collecting any telemetry data. This provider tracks:
/// 1. Whether the user has accepted the current policy version
/// 2. Which policy version was accepted (for re-consent on policy updates)
///
/// NOTE: Consent state is stored in SharedPreferences for quick sync checks
/// AND in ConsentRepository (SQLite) for audit trail / legal compliance.
class ConsentProvider extends ChangeNotifier {
  final PreferencesService _prefs;
  final ConsentRepository _consentRepository;
  final AuthProvider _authProvider;

  /// Current policy version. Bump this when ToS/Privacy Policy changes
  /// to force re-consent.
  /// WHY: Hardcoded initially. Can be fetched from app_config table later
  /// when remote policy versioning is needed.
  static const String currentPolicyVersion = '1.0.0';

  // Preference keys
  static const String _keyConsentAccepted = 'consent_accepted';
  static const String _keyConsentPolicyVersion = 'consent_policy_version';
  static const String _keyConsentTimestamp = 'consent_timestamp';

  bool _hasConsented = false;
  String? _consentedPolicyVersion;

  ConsentProvider({
    required PreferencesService preferencesService,
    required ConsentRepository consentRepository,
    required AuthProvider authProvider,
  })  : _prefs = preferencesService,
        _consentRepository = consentRepository,
        _authProvider = authProvider;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Whether the user has accepted the CURRENT policy version.
  /// WHY: Returns false if they accepted an older version — forces re-consent
  /// when the policy is updated (bump currentPolicyVersion).
  bool get hasConsented =>
      _hasConsented && _consentedPolicyVersion == currentPolicyVersion;

  /// Whether the user has ever consented (any version).
  bool get hasEverConsented => _hasConsented;

  /// The policy version the user consented to (null if never consented).
  String? get consentedPolicyVersion => _consentedPolicyVersion;

  /// Whether the user needs to re-consent due to a policy update.
  bool get needsReconsent =>
      _hasConsented && _consentedPolicyVersion != currentPolicyVersion;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Load consent state from SharedPreferences. Call once at startup.
  void loadConsentState() {
    _hasConsented = _prefs.getBool(_keyConsentAccepted) ?? false;
    _consentedPolicyVersion = _prefs.getString(_keyConsentPolicyVersion);

    Logger.lifecycle(
      'Consent state loaded: accepted=$_hasConsented, '
      'version=$_consentedPolicyVersion, '
      'current=$currentPolicyVersion, '
      'valid=$hasConsented',
    );
  }

  /// Record user acceptance of the current policy version.
  /// WHY: Stores the exact version and timestamp for audit trail.
  /// Writes to BOTH SharedPreferences (quick checks) AND ConsentRepository
  /// (SQLite audit records). Two ConsentRecord rows are inserted: one for
  /// privacy_policy and one for terms_of_service.
  Future<void> acceptConsent({String? appVersion}) async {
    await _prefs.setBool(_keyConsentAccepted, true);
    await _prefs.setString(_keyConsentPolicyVersion, currentPolicyVersion);
    await _prefs.setString(
      _keyConsentTimestamp,
      DateTime.now().toUtc().toIso8601String(),
    );

    // WHY: Insert audit records into SQLite via ConsentRepository.
    // Two rows: one for privacy_policy, one for terms_of_service.
    // This is the legal audit trail — prefs alone are not sufficient.
    final userId = _authProvider.userId;
    if (userId == null) {
      Logger.error('Cannot record consent: no authenticated user');
      return;
    }
    final resolvedAppVersion = appVersion ?? 'unknown';

    await _consentRepository.recordConsent(ConsentRecord(
      userId: userId,
      policyType: ConsentPolicyType.privacyPolicy,
      policyVersion: currentPolicyVersion,
      appVersion: resolvedAppVersion,
    ));
    await _consentRepository.recordConsent(ConsentRecord(
      userId: userId,
      policyType: ConsentPolicyType.termsOfService,
      policyVersion: currentPolicyVersion,
      appVersion: resolvedAppVersion,
    ));

    // Enable Sentry reporting now that consent is granted
    enableSentryReporting();

    _hasConsented = true;
    _consentedPolicyVersion = currentPolicyVersion;

    Logger.lifecycle('User accepted consent for policy v$currentPolicyVersion');
    notifyListeners();
  }

  /// Revoke consent (e.g., from settings screen).
  /// WHY: Users must be able to withdraw consent at any time (GDPR right).
  Future<void> revokeConsent() async {
    await _prefs.setBool(_keyConsentAccepted, false);
    // NOTE: Keep the policy version and timestamp for audit — only flip the bool.

    _hasConsented = false;

    Logger.lifecycle('User revoked consent');
    notifyListeners();
  }

  /// Clear all consent state on sign-out.
  /// WHY: Consent is per-user. When a different user signs in on the same
  /// device, they must give their own consent.
  Future<void> clearOnSignOut() async {
    await _prefs.setBool(_keyConsentAccepted, false);
    // NOTE: We could also remove the keys entirely, but setting to false
    // is safer — avoids null-check edge cases on next load.
    _hasConsented = false;
    _consentedPolicyVersion = null;
    notifyListeners();
  }
}
```

---

### Sub-phase 7.2: ConsentScreen
**Files:**
- Create: `lib/features/settings/presentation/screens/consent_screen.dart`
- Create: `lib/shared/testing_keys/consent_keys.dart`
**Agent:** frontend-flutter-specialist-agent

#### Step 7.2.1: Create testing keys for consent screen
Create `lib/shared/testing_keys/consent_keys.dart`:

```dart
import 'package:flutter/material.dart';

/// Testing keys for the consent / Terms of Service screen.
///
/// WHY: E2E tests need stable keys to interact with the consent flow.
class ConsentTestingKeys {
  ConsentTestingKeys._();

  /// The scrollable body containing the ToS/Privacy Policy text
  static const consentScrollView = Key('consent_scroll_view');

  /// The "I Accept" button (enabled only after scrolling to bottom)
  static const consentAcceptButton = Key('consent_accept_button');

  /// The full consent screen scaffold
  static const consentScreen = Key('consent_screen');

  /// Checkbox on the registration screen for ToS agreement
  static const registerTosCheckbox = Key('register_tos_checkbox');
}
```

#### Step 7.2.2: Create ConsentScreen
Create `lib/features/settings/presentation/screens/consent_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/settings/presentation/providers/consent_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';
import 'package:construction_inspector/shared/testing_keys/consent_keys.dart';

/// Full-screen blocking consent screen.
///
/// WHY: Users must explicitly accept Terms of Service and Privacy Policy
/// before using the app. This screen:
/// 1. Blocks navigation until accepted (enforced by router redirect)
/// 2. Requires scrolling to the bottom before the Accept button enables
/// 3. Records acceptance with policy version for audit trail
///
/// NOTE: This screen is shown:
/// - On first launch (new users)
/// - After policy version bump (existing users, re-consent)
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isAccepting = false;
  String? _tosText;
  String? _privacyText;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPolicyTexts();
  }

  /// WHY: Load policy text from bundled markdown assets (single source of truth).
  /// Same assets used by LegalDocumentScreen in Phase 11.
  Future<void> _loadPolicyTexts() async {
    try {
      final tos = await rootBundle.loadString('assets/legal/terms_of_service.md');
      final privacy = await rootBundle.loadString('assets/legal/privacy_policy.md');
      if (!mounted) return;
      setState(() {
        _tosText = tos;
        _privacyText = privacy;
      });
    } catch (e) {
      Logger.error('Failed to load policy text from assets', error: e);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasScrolledToBottom) return;
    // WHY: Check if user has scrolled to within 50px of the bottom.
    // Small threshold accounts for different screen sizes / font scaling.
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 50) {
      setState(() => _hasScrolledToBottom = true);
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);

    try {
      final appVersion = context.read<AppConfigProvider>().appVersion;
      await context.read<ConsentProvider>().acceptConsent(appVersion: appVersion);
      if (!mounted) return;
      // WHY: After consent, go to root — the router redirect will handle
      // routing to the correct screen (onboarding, dashboard, etc.)
      context.go('/');
    } catch (e) {
      Logger.error('Failed to save consent', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consentProvider = context.watch<ConsentProvider>();

    return Scaffold(
      key: ConsentTestingKeys.consentScreen,
      appBar: AppBar(
        title: Text(
          consentProvider.needsReconsent
              ? 'Updated Terms of Service'
              : 'Terms of Service',
        ),
        automaticallyImplyLeading: false, // WHY: No back button — blocking screen
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header text
              Text(
                consentProvider.needsReconsent
                    ? 'Our Terms of Service and Privacy Policy have been updated. '
                      'Please review and accept to continue.'
                    : 'Please review our Terms of Service and Privacy Policy '
                      'to continue.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppTheme.space4),

              // Scrollable policy summary + links to full documents
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: SingleChildScrollView(
                    key: ConsentTestingKeys.consentScrollView,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary text
                        Text(
                          'By accepting, you agree to our Terms of Service and Privacy Policy. '
                          'Key points:',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppTheme.space3),
                        Text(
                          '• Your inspection data remains your property\n'
                          '• Data is stored locally and synced to cloud when connected\n'
                          '• With your consent, anonymous crash reports and usage analytics help improve the app\n'
                          '• You can revoke consent at any time in Settings\n'
                          '• No personally identifiable information is sent to analytics',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.space4),

                        // Full Terms of Service text (loaded from bundled asset)
                        Text(
                          'Terms of Service',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space3),
                        Text(
                          _tosText ?? 'Loading...',
                          style: theme.textTheme.bodyMedium,
                        ),
                        // Tappable link to full document viewer
                        GestureDetector(
                          onTap: () => context.pushNamed(
                            'legal-document',
                            queryParameters: {'type': 'tos'},
                          ),
                          child: Text(
                            'View full Terms of Service',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space6),

                        // Full Privacy Policy text (loaded from bundled asset)
                        Text(
                          'Privacy Policy',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space3),
                        Text(
                          _privacyText ?? 'Loading...',
                          style: theme.textTheme.bodyMedium,
                        ),
                        // Tappable link to full document viewer
                        GestureDetector(
                          onTap: () => context.pushNamed(
                            'legal-document',
                            queryParameters: {'type': 'privacy'},
                          ),
                          child: Text(
                            'View full Privacy Policy',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          'Policy version: ${ConsentProvider.currentPolicyVersion}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space3),

              // Scroll hint (hidden once scrolled to bottom)
              if (!_hasScrolledToBottom)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space2),
                  child: Text(
                    'Scroll to the bottom to enable the Accept button',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Accept button
              ElevatedButton(
                key: ConsentTestingKeys.consentAcceptButton,
                // WHY: Disabled until user scrolls to bottom — ensures they
                // have at least seen the full text.
                onPressed: _hasScrolledToBottom && !_isAccepting
                    ? _handleAccept
                    : null,
                child: _isAccepting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('I Accept'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// NOTE: Policy text is no longer hardcoded here.
// It is loaded from bundled markdown assets (assets/legal/terms_of_service.md
// and assets/legal/privacy_policy.md) via rootBundle.loadString() in initState.
// This maintains a single source of truth — the same assets are rendered
// by LegalDocumentScreen (Phase 11).
```

---

### Sub-phase 7.3: Add ConsentProvider to main.dart initialization
**Files:**
- Modify: `lib/main.dart` (inside `_runApp()`, before `runApp()`)
- Modify: `lib/main.dart` (`ConstructionInspectorApp` constructor and MultiProvider)
**Agent:** general-purpose

#### Step 7.3.1: Create ConsentProvider in _runApp()
Insert after `final preferencesService = PreferencesService();` and `await preferencesService.initialize();` (line 133-134), and after the Aptabase init block added in Phase 6:

```dart
  // WHY: ConsentProvider must be created after repositories are built because
  // it needs ConsentRepository (for audit trail) and AuthProvider (for userId).
  // 1. Aptabase init (above) checks consent via PreferencesService directly
  // 2. The router needs ConsentProvider for the consent gate redirect
  // 3. The ConsentScreen needs it to display state and record acceptance
  final consentProvider = ConsentProvider(
    preferencesService: preferencesService,
    consentRepository: consentRepository,  // built earlier in _runApp with other repositories
    authProvider: authProvider,             // built earlier in _runApp
  );
  consentProvider.loadConsentState();

  // WHY: Set the Sentry consent gate flag so _beforeSendSentry allows events.
  // Until this point, all Sentry events are dropped (see sentryConsentGranted).
  // NOTE: Uses enableSentryReporting() from lib/core/config/sentry_consent.dart
  if (consentProvider.hasConsented) {
    enableSentryReporting();
  }
```

**NOTE:** `consentRepository` must be created earlier in `_runApp()` alongside the other repositories (after DatabaseService is initialized). Add:
```dart
  final consentLocalDatasource = ConsentLocalDatasource(dbService);
  final consentRepository = ConsentRepository(consentLocalDatasource);
```

#### Step 7.3.2: Add ConsentProvider to ConstructionInspectorApp constructor
In the `ConstructionInspectorApp` class (line 733+), add `consentProvider` as a constructor parameter:

```dart
final ConsentProvider consentProvider;
```

And in the constructor parameter list, add:

```dart
required this.consentProvider,
```

#### Step 7.3.3: Add ConsentProvider to MultiProvider
In the `ConstructionInspectorApp.build()` method, inside the `MultiProvider.providers` list, add:

```dart
ChangeNotifierProvider.value(value: consentProvider),
```

#### Step 7.3.4: Pass consentProvider in runApp() call
In the `runApp(ConstructionInspectorApp(...))` call inside `_runApp()`, add:

```dart
consentProvider: consentProvider,
```

#### Step 7.3.5: Add imports for ConsentProvider and dependencies in main.dart
```dart
import 'package:construction_inspector/features/settings/presentation/providers/consent_provider.dart';
import 'package:construction_inspector/features/settings/data/datasources/consent_local_datasource.dart';
import 'package:construction_inspector/features/settings/data/repositories/consent_repository.dart';
```

---

### Sub-phase 7.4: Add ToS checkbox to registration screen
**Files:**
- Modify: `lib/features/auth/presentation/screens/register_screen.dart` (line 186-189)
**Agent:** frontend-flutter-specialist-agent

#### Step 7.4.1: Add state variable for ToS checkbox
Add to the `_RegisterScreenState` class fields:

```dart
bool _tosAccepted = false;
```

#### Step 7.4.2: Insert ToS checkbox between spacer and Create Account button
Insert between `const SizedBox(height: AppTheme.space6),` (line 186) and `// Create Account Button` (line 188):

```dart
                // WHY: Users must agree to ToS before creating an account.
                // This does NOT replace the full ConsentScreen — it's a
                // quick acknowledgment during registration. The full consent
                // screen handles detailed policy review + scroll-to-accept.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      key: ConsentTestingKeys.registerTosCheckbox,
                      value: _tosAccepted,
                      onChanged: (value) {
                        setState(() => _tosAccepted = value ?? false);
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tosAccepted = !_tosAccepted),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space3),
```

#### Step 7.4.3: Write consent records after successful registration
In `_handleSignUp`, after the success block (where sign-up succeeds and the user is created), add:

```dart
      // WHY: Create consent records at registration time since the user
      // checked the ToS checkbox. This writes to both SharedPreferences
      // AND ConsentRepository (SQLite audit trail) via acceptConsent().
      final consentProvider = context.read<ConsentProvider>();
      final appVersion = context.read<AppConfigProvider>().appVersion;
      await consentProvider.acceptConsent(appVersion: appVersion);
```

Add import if not already present:
```dart
import 'package:construction_inspector/features/settings/presentation/providers/consent_provider.dart';
```

#### Step 7.4.4: Gate Create Account button on ToS acceptance
Modify the Create Account button's `onPressed` (line 193). Change:

```dart
onPressed: authProvider.isLoading ? null : _handleSignUp,
```

To:

```dart
// WHY: Button is disabled when ToS not accepted OR when loading.
onPressed: authProvider.isLoading || !_tosAccepted ? null : _handleSignUp,
```

#### Step 7.4.5: Add import for ConsentTestingKeys
Add to `register_screen.dart`:

```dart
import 'package:construction_inspector/shared/testing_keys/consent_keys.dart';
```

---

### Sub-phase 7.5: Export new files via barrel exports
**Files:**
- Modify: `lib/shared/testing_keys/testing_keys.dart` (if barrel exists)
- Modify: `lib/features/settings/presentation/providers/providers.dart` (if barrel exists)
- Modify: `lib/features/settings/presentation/screens/screens.dart` (if barrel exists)
**Agent:** general-purpose

#### Step 7.5.1: Add consent_keys export
Check if `lib/shared/testing_keys/testing_keys.dart` exists and add:

```dart
export 'consent_keys.dart';
```

If no barrel exists, add the direct import in files that need it.

#### Step 7.5.2: Add consent_provider export
Check if a providers barrel exists at `lib/features/settings/presentation/providers/providers.dart` and add:

```dart
export 'consent_provider.dart';
```

#### Step 7.5.3: Add consent_screen export
Check if `lib/features/settings/presentation/screens/screens.dart` exists and add:

```dart
export 'consent_screen.dart';
```

---

### Sub-phase 7.6: Verification
**Agent:** qa-testing-agent

#### Step 7.6.1: Static analysis
```
pwsh -Command "flutter analyze"
```

#### Step 7.6.2: Run existing tests
```
pwsh -Command "flutter test"
```

---

## Phase 8: Router Integration
### Sub-phase 8.1: Add consent route to GoRouter
**Files:**
- Modify: `lib/core/router/app_router.dart` (routes list, around line 303)
**Agent:** frontend-flutter-specialist-agent

#### Step 8.1.1: Add ConsentScreen import
Add at the top of `lib/core/router/app_router.dart`:

```dart
import 'package:construction_inspector/features/settings/presentation/screens/consent_screen.dart';
```

#### Step 8.1.2: Add '/consent' to _kNonRestorableRoutes
Modify the `_kNonRestorableRoutes` set (line 52-61) to include `/consent`:

**Old:**
```dart
const _kNonRestorableRoutes = {
  '/profile-setup',
  '/company-setup',
  '/pending-approval',
  '/account-status',
  '/edit-profile',
  '/admin-dashboard',
  '/update-password',
  '/update-required',
};
```

**New:**
```dart
// WHY: '/consent' added — app must never deep-link into the consent screen
// on next launch. The router redirect will send users there if needed.
const _kNonRestorableRoutes = {
  '/profile-setup',
  '/company-setup',
  '/pending-approval',
  '/account-status',
  '/edit-profile',
  '/admin-dashboard',
  '/update-password',
  '/update-required',
  '/consent',
};
```

#### Step 8.1.3: Add '/consent' to _kOnboardingRoutes
Modify the `_kOnboardingRoutes` set (line 41-48) to include `/consent`:

**Old:**
```dart
const _kOnboardingRoutes = {
  '/profile-setup',
  '/company-setup',
  '/pending-approval',
  '/account-status',
  '/update-password',
  '/update-required',
};
```

**New:**
```dart
// WHY: '/consent' is exempt from profile-check redirect — users must
// accept consent before any profile routing happens.
const _kOnboardingRoutes = {
  '/profile-setup',
  '/company-setup',
  '/pending-approval',
  '/account-status',
  '/update-password',
  '/update-required',
  '/consent',
};
```

#### Step 8.1.4: Add GoRoute for consent screen
Insert after the `/update-required` route definition in the routes list (around line 340-350, in the authentication routes section):

```dart
      GoRoute(
        path: '/consent',
        name: 'consent',
        builder: (context, state) => const ConsentScreen(),
      ),
```

---

### Sub-phase 8.2: Add consent check in router redirect
**Files:**
- Modify: `lib/core/router/app_router.dart` (redirect function, after version gate ~line 202)
**Agent:** frontend-flutter-specialist-agent

#### Step 8.2.1: Add ConsentProvider import
Add at the top of `lib/core/router/app_router.dart`:

```dart
import 'package:construction_inspector/features/settings/presentation/providers/consent_provider.dart';
```

#### Step 8.2.2: Insert consent gate after version gate
Insert after the version gate block (after line 202, before the onboarding route check at line 204). The consent check goes between the `try/catch` for AppConfigProvider and the `// If on an onboarding route` comment:

**Insert after line 202 (the closing `}` of the AppConfigProvider try/catch):**

```dart
      // Consent gate: block on /consent when user hasn't accepted current policy.
      // WHY: Placed AFTER version gate (force-update takes priority) and
      // AFTER auth (unauthenticated users don't need consent yet — they'll
      // see the registration checkbox and full consent screen after sign-up).
      // NOTE: Uses try/catch like AppConfigProvider above — provider may not
      // be available in test mode.
      try {
        final consent = context.read<ConsentProvider>();
        if (!consent.hasConsented) {
          if (location == '/consent') return null;
          return '/consent';
        }
      } catch (e) {
        Logger.nav('ConsentProvider not available in router: $e');
      }
```

> **IMPORTANT:** This block must be placed:
> - AFTER the version gate (line 186-202) — so force-update takes priority
> - BEFORE the onboarding route check (line 204) — so consent is checked before profile routing
> - Only runs when `isAuthenticated` is true (it's inside the `if (isAuthenticated)` block that starts at line 186)

---

### Sub-phase 8.3: Add refreshListenable for ConsentProvider
**Files:**
- Modify: `lib/core/router/app_router.dart` (GoRouter constructor, line 126-130)
**Agent:** frontend-flutter-specialist-agent

#### Step 8.3.1: Update AppRouter to accept ConsentProvider
Modify the `AppRouter` class to accept an optional `ConsentProvider`:

**Old (line 63-73):**
```dart
class AppRouter {
  final AuthProvider _authProvider;

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();

  String _initialLocation = '/';
  GoRouter? _router;

  AppRouter({required AuthProvider authProvider})
      : _authProvider = authProvider;
```

**New:**
```dart
class AppRouter {
  final AuthProvider _authProvider;
  final ConsentProvider? _consentProvider;

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();

  String _initialLocation = '/';
  GoRouter? _router;

  // WHY: ConsentProvider is optional for backward compatibility with tests
  // that don't set up consent. When null, the consent gate in redirect is
  // skipped (context.read will throw, caught by the try/catch).
  AppRouter({
    required AuthProvider authProvider,
    ConsentProvider? consentProvider,
  })  : _authProvider = authProvider,
       _consentProvider = consentProvider;
```

#### Step 8.3.2: Add ConsentProvider as refreshListenable
The GoRouter currently uses `refreshListenable: _authProvider` (line 130). To listen to both AuthProvider and ConsentProvider, we need a `Listenable.merge`:

**Old (line 130):**
```dart
    refreshListenable: _authProvider,
```

**New:**
```dart
    // WHY: Router must re-evaluate redirects when consent state changes
    // (e.g., user accepts consent on ConsentScreen). Listenable.merge
    // triggers redirect re-evaluation when either provider notifies.
    refreshListenable: _consentProvider != null
        ? Listenable.merge([_authProvider, _consentProvider])
        : _authProvider,
```

---

### Sub-phase 8.4: Pass ConsentProvider to AppRouter in main.dart
**Files:**
- Modify: `lib/main.dart` (where AppRouter is created)
**Agent:** general-purpose

#### Step 8.4.1: Find AppRouter instantiation and add consentProvider
Search `lib/main.dart` for `AppRouter(` and add the consentProvider parameter:

**Old:**
```dart
AppRouter(authProvider: authProvider)
```

**New:**
```dart
// WHY: ConsentProvider passed to AppRouter so the router can gate
// navigation behind consent acceptance.
AppRouter(authProvider: authProvider, consentProvider: consentProvider)
```

---

### Sub-phase 8.5: Verification
**Agent:** qa-testing-agent

#### Step 8.5.1: Static analysis
```
pwsh -Command "flutter analyze"
```

#### Step 8.5.2: Run existing tests
```
pwsh -Command "flutter test"
```

#### Step 8.5.3: Manual verification checklist
Verify the following flow manually:
1. Fresh install → sign up → ToS checkbox required → consent screen after auth → dashboard
2. Existing user without consent → login → consent screen → dashboard
3. Policy version bump → existing consented user → consent screen on next launch
4. Accept consent → navigates to dashboard (or onboarding if profile incomplete)
5. Sentry DSN empty → no errors, Sentry is no-op
6. APTABASE_APP_KEY empty → no errors, analytics skipped
