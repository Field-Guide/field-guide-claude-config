# Pre-Release Hardening — Dependency Graph Analysis

**Date:** 2026-03-29
**Spec:** `.claude/specs/2026-03-29-pre-release-hardening-spec.md`

## Direct Changes

### New Files to Create

| File | Type | Agent |
|------|------|-------|
| `lib/core/database/schema/support_tables.dart` | Schema (consent + support tables) | backend-data-layer-agent |
| `lib/features/consent/data/models/consent_record.dart` | Model | backend-data-layer-agent |
| `lib/features/consent/data/datasources/consent_local_datasource.dart` | Datasource | backend-data-layer-agent |
| `lib/features/consent/data/repositories/consent_repository.dart` | Repository | backend-data-layer-agent |
| `lib/features/consent/presentation/providers/consent_provider.dart` | Provider | frontend-flutter-specialist-agent |
| `lib/features/consent/presentation/screens/consent_screen.dart` | Screen | frontend-flutter-specialist-agent |
| `lib/features/support/data/models/support_ticket.dart` | Model | backend-data-layer-agent |
| `lib/features/support/data/datasources/support_local_datasource.dart` | Datasource | backend-data-layer-agent |
| `lib/features/support/data/repositories/support_repository.dart` | Repository | backend-data-layer-agent |
| `lib/features/support/presentation/providers/support_provider.dart` | Provider | frontend-flutter-specialist-agent |
| `lib/features/support/presentation/screens/help_support_screen.dart` | Screen | frontend-flutter-specialist-agent |
| `lib/features/settings/presentation/screens/legal_document_screen.dart` | Screen | frontend-flutter-specialist-agent |
| `lib/features/settings/presentation/screens/licenses_screen.dart` | Screen | frontend-flutter-specialist-agent |
| `lib/shared/testing_keys/consent_keys.dart` | Testing keys | backend-data-layer-agent |
| `lib/shared/testing_keys/support_keys.dart` | Testing keys | backend-data-layer-agent |
| `assets/legal/terms_of_service.md` | Asset | general-purpose |
| `assets/legal/privacy_policy.md` | Asset | general-purpose |
| `supabase/migrations/20260329000000_consent_and_support_tables.sql` | Migration | backend-supabase-agent |
| `android/key.properties` | Signing config (gitignored) | general-purpose |

### Existing Files to Modify

| File | Lines | Change | Agent |
|------|-------|--------|-------|
| `lib/main.dart` | 109-124, 126-596 | Add Sentry wrapping in `main()`, Aptabase init in `_runApp()`, ConsentProvider + SupportProvider wiring | general-purpose |
| `lib/core/logging/logger.dart` | 176-228 | Add Sentry transport in `error()` method | backend-data-layer-agent |
| `lib/core/database/database_service.dart` | 53, 104-183, 265+ | Bump version to 44, add new tables in `_onCreate`, add migration in `_onUpgrade` | backend-data-layer-agent |
| `lib/core/database/schema/schema.dart` | barrel | Add export for `support_tables.dart` | backend-data-layer-agent |
| `lib/features/settings/presentation/screens/settings_screen.dart` | 312-346 | Overhaul About section: add build number, legal links, help & support tile; replace `showLicensePage()` | frontend-flutter-specialist-agent |
| `lib/features/auth/presentation/screens/register_screen.dart` | 186-203 | Add ToS/Privacy checkbox before Create Account button | frontend-flutter-specialist-agent |
| `lib/features/auth/presentation/providers/app_config_provider.dart` | 13-106 | Add `currentPolicyVersion` field + getter | frontend-flutter-specialist-agent |
| `lib/core/router/app_router.dart` | 126-204 | Add consent check redirect (after auth, before version gate) | frontend-flutter-specialist-agent |
| `android/app/build.gradle.kts` | 55-64 | Replace debug signing with release signing config | general-purpose |
| `pubspec.yaml` | 30-106 | Add sentry_flutter, aptabase_flutter, oss_licenses_flutter, flutter_markdown | general-purpose |
| `.env.example` | all | Add SENTRY_DSN, APTABASE_APP_KEY | general-purpose |
| `lib/shared/testing_keys/settings_keys.dart` | 97+ | Add new testing keys for legal tiles, about section | backend-data-layer-agent |

## Dependent Files (callers of modified symbols)

| Symbol Modified | Callers |
|----------------|---------|
| `Logger.error()` | 50+ call sites across entire codebase (no changes needed — adding Sentry transport is internal) |
| `main()` | Entry point — no callers |
| `_runApp()` | Called only from `main()` |
| `AppConfigProvider` | `lib/main.dart:553`, router redirect, Settings screen |
| `PreferencesService` | `lib/main.dart:133`, `lib/features/settings/`, `lib/features/entries/` |
| `DatabaseService._onCreate` | Called internally on fresh install |
| `DatabaseService._onUpgrade` | Called internally on version bump |
| `SettingsScreen` | Navigated from router — no code callers |
| `RegisterScreen._handleSignUp` | Called from UI — no code callers |

## Test Files

| Test File | Exercises |
|-----------|-----------|
| `test/features/auth/presentation/providers/auth_provider_test.dart` | AuthProvider.signUp |
| `test/core/logging/logger_test.dart` | Logger.error, scrubbing |
| `test/features/settings/` | Settings screen (if exists) |

## Key Source Excerpts (for plan-writer)

### Current DB version: 43

### PreferencesService keys pattern
```dart
static const String keyGaugeNumber = 'gauge_number';
static const String keyLastRoute = 'last_route_location';
// Generic: getString(key), setString(key, value), getBool(key), setBool(key, value)
```

### Settings screen About section (lines 312-346)
```dart
// ---- 5. ABOUT ----
SectionHeader(key: TestingKeys.settingsAboutSection, title: 'About'),
Consumer<AppConfigProvider>(
  builder: (context, configProvider, _) {
    final version = configProvider.appVersion ?? 'unknown';
    return ListTile(
      key: TestingKeys.settingsVersionTile,
      leading: const Icon(Icons.info_outline),
      title: const Text('Version'),
      subtitle: Text(version),
    );
  },
),
Consumer<AppConfigProvider>(
  builder: (context, configProvider, _) {
    final version = configProvider.appVersion ?? '1.0.0';
    return ListTile(
      key: TestingKeys.settingsLicensesTile,
      leading: const Icon(Icons.description),
      title: const Text('Licenses'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showLicensePage(
          context: context,
          applicationName: 'Field Guide',
          applicationVersion: version,
        );
      },
    );
  },
),
```

### Register screen signup handler (lines 34-62)
```dart
Future<void> _handleSignUp() async {
  if (!_formKey.currentState!.validate()) return;
  final authProvider = context.read<AuthProvider>();
  final success = await authProvider.signUp(
    email: _emailController.text.trim(),
    password: _passwordController.text,
    fullName: _nameController.text.trim(),
  );
  if (!mounted) return;
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created! Check your email to verify.'), backgroundColor: AppTheme.statusSuccess),
    );
    context.go('/login');
  }
}
```

### Router redirect flow (lines 126-204)
Order: password recovery → auth routes → version gate → onboarding → profile check → dashboard
Consent check should go AFTER version gate, BEFORE onboarding/profile check.

### Logger.error() transport pattern (lines 176-228)
Two transports: file (_writeToSink) + HTTP (_sendHttp)
Sentry becomes third transport: add after HTTP block.
PII scrubbing already applied to msg, error, stack, data before any transport.

### build.gradle.kts signing (lines 55-64)
```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
        proguardFiles(...)
    }
}
```

### Existing testing keys (settings_keys.dart)
```dart
static const settingsAboutSection = Key('settings_about_section');
static const settingsHelpSupportTile = Key('settings_help_support_tile');
static const settingsVersionTile = Key('settings_version_tile');
static const settingsLicensesTile = Key('settings_licenses_tile');
```

### Schema file pattern (e.g., core_tables.dart)
```dart
class CoreTables {
  static const String createProjectsTable = '''
    CREATE TABLE IF NOT EXISTS projects (...)
  ''';
}
```

### _runApp initialization order
1. PreferencesService.initialize()
2. _initDebugLogging()
3. DatabaseService.initializeFfi() + database init
4. Tesseract OCR init
5. Supabase.initialize()
6. Firebase.initializeApp() (mobile only)
7. BackgroundSyncHandler.initialize()
8. Datasources + Repositories
9. SyncOrchestrator
10. AuthProvider
11. AppConfigProvider
12. FCM (mobile only)
13. runApp(ConstructionInspectorApp(...))

Sentry should wrap `main()` (runZonedGuarded → SentryFlutter.init).
Aptabase should init after PreferencesService (needs consent check).
ConsentProvider should be created before runApp, passed to ConstructionInspectorApp.

### .env pattern
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
# New:
SENTRY_DSN=...
APTABASE_APP_KEY=...
```

## Blast Radius Summary

| Category | Count |
|----------|-------|
| Direct (new files) | 19 |
| Direct (modified files) | 12 |
| Dependent files | ~5 (no API changes to existing symbols) |
| Test files (new) | ~8 |
| Cleanup | 1 (remove showLicensePage call) |

## Data Flow Diagram

```
App Launch
    │
    ├─ SentryFlutter.init() wraps main()
    │
    ├─ _runApp()
    │   ├─ PreferencesService.initialize()
    │   ├─ Check consent_accepted pref
    │   │   ├─ If accepted: init Sentry + Aptabase
    │   │   └─ If not: defer init until consent given
    │   ├─ ... existing init ...
    │   ├─ ConsentProvider (check version, gate app)
    │   └─ runApp(...)
    │
    ├─ Router redirect
    │   ├─ Auth check
    │   ├─ Version gate
    │   ├─ Consent check ← NEW
    │   │   └─ If needs consent → /consent
    │   └─ Normal flow
    │
    └─ Settings > About
        ├─ Version + Build Number
        ├─ Licenses (oss_licenses)
        ├─ Terms of Service → LegalDocumentScreen
        ├─ Privacy Policy → LegalDocumentScreen
        └─ Help & Support → HelpSupportScreen
            └─ Submit → SupportProvider → SQLite → Supabase sync
                └─ Optional: log files → Supabase Storage
```
