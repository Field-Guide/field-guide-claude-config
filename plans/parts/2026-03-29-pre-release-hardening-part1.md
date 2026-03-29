# Pre-Release Hardening Implementation Plan — Part 1 (Phases 1-4)

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Add pre-release hardening infrastructure (consent, crash reporting, analytics, signing, about screen overhaul)
**Spec:** `.claude/specs/2026-03-29-pre-release-hardening-spec.md`
**Analysis:** `.claude/dependency_graphs/2026-03-29-pre-release-hardening/`

---

## Phase 1: Dependencies & Configuration
### Sub-phase 1.1: Add packages to pubspec.yaml
**Files:**
- Modify: `pubspec.yaml` (deps at line 30, dev_deps at line 107)
**Agent:** general-purpose

#### Step 1.1.1: Add sentry_flutter for crash reporting
In `pubspec.yaml`, after the `# Utilities` section (line 98-105), add a new comment group before `dev_dependencies`:

```yaml
  # Crash Reporting & Analytics
  sentry_flutter: ^8.13.0
```

**WHY:** Sentry provides crash reporting, performance monitoring, and breadcrumb trails. sentry_flutter is the official Flutter SDK that hooks into Flutter's error handling.

#### Step 1.1.2: Run pub get to validate dependency resolution
```
pwsh -Command "flutter pub get"
```

**NOTE:** If version conflicts arise, check `sentry_flutter` constraints against existing `firebase_core` and `http` versions. Sentry 8.x is compatible with Flutter 3.10+.

### Sub-phase 1.2: Update .env configuration
**Files:**
- Modify: `.env.example`
**Agent:** general-purpose

#### Step 1.2.1: Add Sentry DSN placeholder to .env.example
Append after line 11 (the SUPABASE_ANON_KEY line):

```
# Sentry crash reporting DSN
# Example: https://examplePublicKey@o0.ingest.sentry.io/0
SENTRY_DSN=your-sentry-dsn-here
```

**WHY:** Sentry DSN is the project-specific endpoint for crash reports. Injected via `--dart-define-from-file=.env` (same mechanism as Supabase credentials). Keeping it in .env prevents hardcoding secrets.

**NOTE:** The actual `.env` file is gitignored. Users copy `.env.example` and fill in real values.

### Sub-phase 1.3: Android release signing configuration
**Files:**
- Modify: `android/app/build.gradle.kts` (lines 55-64)
- Create: `android/key.properties.example`
**Agent:** general-purpose

#### Step 1.3.1: Add key.properties loading to build.gradle.kts
In `android/app/build.gradle.kts`, add the key.properties loading block **before** the `android {` block (before line 9). Insert between line 7 (`}` closing plugins) and line 9 (`android {`):

```kotlin
// WHY: Load release signing config from key.properties (gitignored).
// Falls back to debug signing if key.properties is absent (dev machines).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
```

**NOTE:** Kotlin DSL format — NOT Groovy. The `rootProject.file()` resolves relative to `android/` directory.

#### Step 1.3.2: Add signingConfigs block inside android {}
In `android/app/build.gradle.kts`, add a `signingConfigs` block **before** the `buildTypes` block (before line 55). Insert after the `testOptions` closing brace (after line 53):

```kotlin
    signingConfigs {
        create("release") {
            // WHY: Only configure release signing if key.properties exists.
            // This prevents build failures on dev machines without a keystore.
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
```

#### Step 1.3.3: Update release buildType to use release signing config
Replace lines 55-64 in `android/app/build.gradle.kts`:

**Old (lines 55-64):**
```kotlin
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
```

**New:**
```kotlin
    buildTypes {
        release {
            // WHY: Use release signing when key.properties exists, debug otherwise.
            // This allows release builds on CI while keeping dev builds working.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
```

#### Step 1.3.4: Create key.properties.example template
Create `android/key.properties.example`:

```properties
# Android release signing configuration
# Copy this file to key.properties (which is gitignored) and fill in values.
#
# To generate a keystore:
#   keytool -genkey -v -keystore field-guide-release.keystore \
#     -alias field-guide -keyalg RSA -keysize 2048 -validity 10000
#
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=field-guide
storeFile=../field-guide-release.keystore
```

**NOTE:** `.gitignore` already excludes `*.keystore`, `*.jks`, and `key.properties`. The `storeFile` path is relative to `android/app/`.

### Sub-phase 1.4: iOS project directory generation
**Files:**
- Create: `ios/` directory (generated by Flutter)
**Agent:** general-purpose

#### Step 1.4.1: Generate iOS project scaffold
```
pwsh -Command "flutter create --platforms=ios ."
```

**WHY:** The app currently has no `ios/` directory. This generates the minimal Xcode project structure needed for iOS builds. No signing config is needed at this stage — that will be configured when an Apple Developer account is available.

**NOTE:** This command is safe to run in an existing project — it only adds the `ios/` directory without modifying existing files. If it warns about existing files, that's expected and can be ignored.

#### Step 1.4.2: Verify the generated structure
```
pwsh -Command "Test-Path ios/Runner.xcodeproj"
```

**NOTE:** Should return `True`. The generated project will use the `com.fieldguideapp.inspector` bundle ID from the existing Android config.

### Sub-phase 1.5: Verification
**Agent:** general-purpose

#### Step 1.5.1: Verify dependency resolution and analyze
```
pwsh -Command "flutter pub get"
pwsh -Command "flutter analyze --no-fatal-infos"
```

**WHY:** Ensures all new dependencies resolve without conflicts and existing code still passes analysis.

---

## Phase 2: Database Schema
### Sub-phase 2.1: Create consent_tables.dart schema file
**Files:**
- Create: `lib/core/database/schema/consent_tables.dart`
**Agent:** backend-data-layer-agent

#### Step 2.1.1: Create the ConsentTables schema class
Create `lib/core/database/schema/consent_tables.dart`:

```dart
// WHY: Stores user consent records for privacy policy and terms of service.
// FROM SPEC: Append-only table — users can accept new versions but never
// delete or modify existing consent records. This is a legal/audit requirement.
class ConsentTables {
  static const String tableName = 'user_consent_records';

  static const String createUserConsentRecordsTable = '''
    CREATE TABLE IF NOT EXISTS user_consent_records (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      policy_type TEXT NOT NULL,
      policy_version TEXT NOT NULL,
      accepted_at TEXT NOT NULL,
      app_version TEXT NOT NULL
    )
  ''';

  // NOTE: Index on user_id for quick lookup of a user's consent history.
  // Index on policy_type + policy_version for checking if a specific version was accepted.
  static const List<String> indexes = [
    'CREATE INDEX IF NOT EXISTS idx_user_consent_records_user ON user_consent_records(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_user_consent_records_policy ON user_consent_records(policy_type, policy_version)',
  ];
}
```

**WHY:** `policy_type` is constrained to `'privacy_policy'` or `'terms_of_service'` at the model/datasource layer (not SQL CHECK — SQLite CHECK constraints are harder to migrate). `user_id` references auth.users on the Supabase side but is a plain TEXT locally since the FK target doesn't exist in local SQLite.

### Sub-phase 2.2: Create support_tables.dart schema file
**Files:**
- Create: `lib/core/database/schema/support_tables.dart`
**Agent:** backend-data-layer-agent

#### Step 2.2.1: Create the SupportTables schema class
Create `lib/core/database/schema/support_tables.dart`:

```dart
// WHY: Stores support tickets submitted from within the app.
// FROM SPEC: Users can create and view their own tickets. Status is managed
// server-side (admin updates). Client only does INSERT + SELECT.
class SupportTables {
  static const String tableName = 'support_tickets';

  static const String createSupportTicketsTable = '''
    CREATE TABLE IF NOT EXISTS support_tickets (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      subject TEXT,
      message TEXT NOT NULL,
      app_version TEXT NOT NULL,
      platform TEXT NOT NULL,
      log_file_path TEXT,
      created_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'open'
    )
  ''';

  // NOTE: Index on user_id for listing a user's tickets.
  // Index on status for filtering open/closed tickets.
  static const List<String> indexes = [
    'CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON support_tickets(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status)',
  ];
}
```

### Sub-phase 2.3: Update schema barrel export
**Files:**
- Modify: `lib/core/database/schema/schema.dart` (line 19, end of file)
**Agent:** backend-data-layer-agent

#### Step 2.3.1: Add consent and support table exports
Append after line 19 (`export 'form_export_tables.dart';`):

```dart
export 'consent_tables.dart';
export 'support_tables.dart';
```

### Sub-phase 2.4: Update DatabaseService — version bump and _onCreate
**Files:**
- Modify: `lib/core/database/database_service.dart` (line 53 for version, lines 104-183 for _onCreate)
**Agent:** backend-data-layer-agent

#### Step 2.4.1: Bump database version from 43 to 44
At line 53, change:

```dart
      version: 43,
```

to:

```dart
      version: 44,
```

#### Step 2.4.2: Add consent and support table creation to _onCreate
In `_onCreate`, after the document/export tables block (after line 152, `await db.execute(FormExportTables.createFormExportsTable);`), add:

```dart
    // Consent + support tables (v44)
    await db.execute(ConsentTables.createUserConsentRecordsTable);
    await db.execute(SupportTables.createSupportTicketsTable);
```

#### Step 2.4.3: Add consent and support indexes to _createIndexes
In `_createIndexes`, after the existing index loops (find the last `for (final index in ...Tables.indexes)` block and add after it):

```dart
    // Consent indexes
    for (final index in ConsentTables.indexes) {
      await db.execute(index);
    }

    // Support indexes
    for (final index in SupportTables.indexes) {
      await db.execute(index);
    }
```

**NOTE:** Need to verify the exact location of the last index loop in `_createIndexes`. It should be near the end of the method, after `FormExportTables.indexes`.

### Sub-phase 2.5: Update DatabaseService — _onUpgrade for v44
**Files:**
- Modify: `lib/core/database/database_service.dart` (after line 1861, end of _onUpgrade)
**Agent:** backend-data-layer-agent

#### Step 2.5.1: Add v44 migration block
After line 1861 (the closing `}` of the v43 migration block, before the closing `}` of `_onUpgrade` at line 1862), add:

```dart
    // WHY: v44 adds consent records and support tickets for pre-release hardening.
    // These are new tables — no data migration needed, just CREATE + indexes.
    if (oldVersion < 44) {
      await db.execute(ConsentTables.createUserConsentRecordsTable);
      await db.execute(SupportTables.createSupportTicketsTable);

      for (final index in ConsentTables.indexes) {
        await db.execute(index);
      }
      for (final index in SupportTables.indexes) {
        await db.execute(index);
      }

      Logger.db('v44 migration: added user_consent_records, support_tickets tables');
    }
```

### Sub-phase 2.6: Supabase migration SQL
**Files:**
- Create: `supabase/migrations/20260329000000_consent_and_support_tables.sql`
**Agent:** backend-supabase-agent

#### Step 2.6.1: Create the Supabase migration file
Create `supabase/migrations/20260329000000_consent_and_support_tables.sql`:

```sql
-- WHY: Pre-release hardening — consent records + support tickets.
-- FROM SPEC: Both tables are append-only from the client perspective.
-- RLS: Users can only INSERT and SELECT their own records.

-- =============================================================
-- 1. user_consent_records
-- =============================================================
CREATE TABLE IF NOT EXISTS public.user_consent_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    policy_type TEXT NOT NULL CHECK (policy_type IN ('privacy_policy', 'terms_of_service')),
    policy_version TEXT NOT NULL,
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    app_version TEXT NOT NULL
);

-- NOTE: Index on user_id for RLS filter pushdown.
CREATE INDEX IF NOT EXISTS idx_user_consent_records_user
    ON public.user_consent_records(user_id);
CREATE INDEX IF NOT EXISTS idx_user_consent_records_policy
    ON public.user_consent_records(policy_type, policy_version);

-- RLS: Users can only insert and read their own consent records.
-- No UPDATE or DELETE — consent is immutable once recorded.
ALTER TABLE public.user_consent_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own consent"
    ON public.user_consent_records FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read own consent"
    ON public.user_consent_records FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- =============================================================
-- 2. support_tickets
-- =============================================================
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject TEXT,
    message TEXT NOT NULL,
    app_version TEXT NOT NULL,
    platform TEXT NOT NULL,
    log_file_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'acknowledged', 'resolved'))
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_user
    ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status
    ON public.support_tickets(status);

-- RLS: Users can insert and read their own tickets.
-- No UPDATE or DELETE from client — status managed by admin/backend.
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own tickets"
    ON public.support_tickets FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read own tickets"
    ON public.support_tickets FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- =============================================================
-- 3. support-logs storage bucket
-- =============================================================
-- WHY: Users attach log files to support tickets. Bucket is private —
-- only the uploader and service_role can read.
INSERT INTO storage.buckets (id, name, public)
VALUES ('support-logs', 'support-logs', false)
ON CONFLICT (id) DO NOTHING;

-- RLS: Authenticated users can upload to their own folder.
CREATE POLICY "Users can upload own support logs"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'support-logs'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- RLS: Users can only read their own uploaded logs.
CREATE POLICY "Users can read own support logs"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'support-logs'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
```

**NOTE:** Supabase uses UUID and TIMESTAMPTZ types (Postgres), unlike local SQLite which uses TEXT for everything. The CHECK constraints on `policy_type` and `status` provide server-side validation. The storage bucket uses folder-based RLS where each user's files are in a `{user_id}/` prefix.

### Sub-phase 2.7: Verification
**Agent:** qa-testing-agent

#### Step 2.7.1: Run static analysis
```
pwsh -Command "flutter analyze --no-fatal-infos"
```

#### Step 2.7.2: Run existing database tests to verify no regressions
```
pwsh -Command "flutter test test/core/database/ --no-pub"
```

**NOTE:** If no database-specific tests exist yet, verify with a broader test run:
```
pwsh -Command "flutter test --no-pub"
```

---

## Phase 3: Consent Data Layer
### Sub-phase 3.1: ConsentRecord model
**Files:**
- Create: `lib/features/settings/data/models/consent_record.dart`
- Modify: `lib/features/settings/data/models/models.dart` (barrel export, if it exists)
**Agent:** backend-data-layer-agent

#### Step 3.1.1: Create ConsentRecord model
Create `lib/features/settings/data/models/consent_record.dart`:

```dart
import 'package:uuid/uuid.dart';

// WHY: Consent records track user acceptance of privacy policy and ToS.
// FROM SPEC: Append-only — once created, never updated or deleted.
// This model is used both for local SQLite and Supabase sync.

/// Valid policy types for consent records.
enum ConsentPolicyType {
  privacyPolicy,
  termsOfService;

  /// Convert to database string format.
  String toDbString() {
    switch (this) {
      case ConsentPolicyType.privacyPolicy:
        return 'privacy_policy';
      case ConsentPolicyType.termsOfService:
        return 'terms_of_service';
    }
  }

  /// Parse from database string format.
  static ConsentPolicyType fromDbString(String value) {
    switch (value) {
      case 'privacy_policy':
        return ConsentPolicyType.privacyPolicy;
      case 'terms_of_service':
        return ConsentPolicyType.termsOfService;
      default:
        throw ArgumentError('Unknown policy type: $value');
    }
  }
}

class ConsentRecord {
  final String id;
  final String userId;
  final ConsentPolicyType policyType;
  final String policyVersion;
  final DateTime acceptedAt;
  final String appVersion;

  /// Table name constant for datasource usage.
  static const String tableName = 'user_consent_records';

  ConsentRecord({
    String? id,
    required this.userId,
    required this.policyType,
    required this.policyVersion,
    DateTime? acceptedAt,
    required this.appVersion,
  })  : id = id ?? const Uuid().v4(),
        acceptedAt = acceptedAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'policy_type': policyType.toDbString(),
      'policy_version': policyVersion,
      'accepted_at': acceptedAt.toUtc().toIso8601String(),
      'app_version': appVersion,
    };
  }

  factory ConsentRecord.fromMap(Map<String, dynamic> map) {
    return ConsentRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      policyType: ConsentPolicyType.fromDbString(map['policy_type'] as String),
      policyVersion: map['policy_version'] as String,
      acceptedAt: DateTime.parse(map['accepted_at'] as String),
      appVersion: map['app_version'] as String,
    );
  }

  // NOTE: No copyWith() — consent records are immutable once created.
  // FROM SPEC: Append-only table, no UPDATE allowed.
}
```

**WHY:** The enum uses explicit `toDbString()`/`fromDbString()` instead of `.name`/`.byName()` because the DB values use snake_case (`privacy_policy`) while the Dart enum uses camelCase (`privacyPolicy`).

#### Step 3.1.2: Create or update barrel export
Check if `lib/features/settings/data/models/models.dart` exists. If so, add:

```dart
export 'consent_record.dart';
```

If it does not exist, create `lib/features/settings/data/models/models.dart`:

```dart
export 'consent_record.dart';
```

### Sub-phase 3.2: ConsentLocalDatasource
**Files:**
- Create: `lib/features/settings/data/datasources/consent_local_datasource.dart`
**Agent:** backend-data-layer-agent

#### Step 3.2.1: Create ConsentLocalDatasource
Create `lib/features/settings/data/datasources/consent_local_datasource.dart`:

```dart
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import '../models/consent_record.dart';

// WHY: Datasource for consent records. Does NOT extend GenericLocalDatasource
// because consent records are append-only (no update, no delete, no soft-delete filter).
// FROM SPEC: Only INSERT and SELECT operations allowed.

class ConsentLocalDatasource {
  final DatabaseService _dbService;

  ConsentLocalDatasource(this._dbService);

  /// Insert a new consent record.
  /// NOTE: No upsert — each acceptance creates a new row (append-only).
  Future<void> insert(ConsentRecord record) async {
    final db = await _dbService.database;
    await db.insert(ConsentRecord.tableName, record.toMap());
    Logger.db('INSERT ${ConsentRecord.tableName} id=${record.id} '
        'type=${record.policyType.toDbString()} v=${record.policyVersion}');
  }

  /// Get all consent records for a user, ordered by acceptance time (newest first).
  Future<List<ConsentRecord>> getByUserId(String userId) async {
    final db = await _dbService.database;
    final results = await db.query(
      ConsentRecord.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'accepted_at DESC',
    );
    return results.map((row) => ConsentRecord.fromMap(row)).toList();
  }

  /// Check if a user has accepted a specific policy version.
  /// Returns true if at least one record exists for this policy type + version.
  Future<bool> hasAccepted({
    required String userId,
    required ConsentPolicyType policyType,
    required String policyVersion,
  }) async {
    final db = await _dbService.database;
    final results = await db.query(
      ConsentRecord.tableName,
      where: 'user_id = ? AND policy_type = ? AND policy_version = ?',
      whereArgs: [userId, policyType.toDbString(), policyVersion],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Get the latest consent record for a specific policy type.
  /// Returns null if the user has never accepted this policy.
  Future<ConsentRecord?> getLatest({
    required String userId,
    required ConsentPolicyType policyType,
  }) async {
    final db = await _dbService.database;
    final results = await db.query(
      ConsentRecord.tableName,
      where: 'user_id = ? AND policy_type = ?',
      whereArgs: [userId, policyType.toDbString()],
      orderBy: 'accepted_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ConsentRecord.fromMap(results.first);
  }
}
```

### Sub-phase 3.3: ConsentRepository
**Files:**
- Create: `lib/features/settings/data/repositories/consent_repository.dart`
**Agent:** backend-data-layer-agent

#### Step 3.3.1: Create ConsentRepository
Create `lib/features/settings/data/repositories/consent_repository.dart`:

```dart
import '../datasources/consent_local_datasource.dart';
import '../models/consent_record.dart';

// WHY: Thin wrapper around ConsentLocalDatasource.
// Does NOT implement BaseRepository because consent records are
// append-only with a non-standard API (no getAll, no delete, no save).

class ConsentRepository {
  final ConsentLocalDatasource _localDatasource;

  ConsentRepository(this._localDatasource);

  /// Record user acceptance of a policy version.
  Future<void> recordConsent(ConsentRecord record) {
    return _localDatasource.insert(record);
  }

  /// Get all consent records for a user.
  Future<List<ConsentRecord>> getConsentHistory(String userId) {
    return _localDatasource.getByUserId(userId);
  }

  /// Check if a user has accepted a specific policy version.
  Future<bool> hasAcceptedPolicy({
    required String userId,
    required ConsentPolicyType policyType,
    required String policyVersion,
  }) {
    return _localDatasource.hasAccepted(
      userId: userId,
      policyType: policyType,
      policyVersion: policyVersion,
    );
  }

  /// Get the latest consent record for a policy type.
  Future<ConsentRecord?> getLatestConsent({
    required String userId,
    required ConsentPolicyType policyType,
  }) {
    return _localDatasource.getLatest(
      userId: userId,
      policyType: policyType,
    );
  }
}
```

### Sub-phase 3.4: Consent model unit tests
**Files:**
- Create: `test/features/settings/data/models/consent_record_test.dart`
**Agent:** qa-testing-agent

#### Step 3.4.1: Create ConsentRecord model tests
Create `test/features/settings/data/models/consent_record_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/settings/data/models/consent_record.dart';

void main() {
  group('ConsentRecord', () {
    test('creates with auto-generated ID and UTC timestamp', () {
      final record = ConsentRecord(
        userId: 'user-1',
        policyType: ConsentPolicyType.privacyPolicy,
        policyVersion: '1.0.0',
        appVersion: '0.1.2+3',
      );
      expect(record.id, isNotEmpty);
      expect(record.userId, 'user-1');
      expect(record.policyType, ConsentPolicyType.privacyPolicy);
      expect(record.acceptedAt.isUtc, isTrue);
    });

    test('toMap produces correct keys and values', () {
      final record = ConsentRecord(
        id: 'test-id',
        userId: 'user-1',
        policyType: ConsentPolicyType.termsOfService,
        policyVersion: '2.0.0',
        appVersion: '0.1.2+3',
      );
      final map = record.toMap();
      expect(map['id'], 'test-id');
      expect(map['user_id'], 'user-1');
      expect(map['policy_type'], 'terms_of_service');
      expect(map['policy_version'], '2.0.0');
      expect(map['app_version'], '0.1.2+3');
      expect(map.containsKey('accepted_at'), isTrue);
    });

    test('fromMap round-trips correctly', () {
      final original = ConsentRecord(
        id: 'test-id',
        userId: 'user-1',
        policyType: ConsentPolicyType.privacyPolicy,
        policyVersion: '1.0.0',
        appVersion: '0.1.2+3',
      );
      final restored = ConsentRecord.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.policyType, original.policyType);
      expect(restored.policyVersion, original.policyVersion);
      expect(restored.appVersion, original.appVersion);
      // NOTE: Millisecond precision may differ after ISO8601 round-trip
      expect(
        restored.acceptedAt.difference(original.acceptedAt).inSeconds,
        0,
      );
    });

    test('fromMap handles privacy_policy type string', () {
      final map = {
        'id': 'test-id',
        'user_id': 'user-1',
        'policy_type': 'privacy_policy',
        'policy_version': '1.0.0',
        'accepted_at': '2026-03-29T12:00:00.000Z',
        'app_version': '0.1.2+3',
      };
      final record = ConsentRecord.fromMap(map);
      expect(record.policyType, ConsentPolicyType.privacyPolicy);
    });

    test('fromMap handles terms_of_service type string', () {
      final map = {
        'id': 'test-id',
        'user_id': 'user-1',
        'policy_type': 'terms_of_service',
        'policy_version': '1.0.0',
        'accepted_at': '2026-03-29T12:00:00.000Z',
        'app_version': '0.1.2+3',
      };
      final record = ConsentRecord.fromMap(map);
      expect(record.policyType, ConsentPolicyType.termsOfService);
    });

    test('fromDbString throws on unknown policy type', () {
      expect(
        () => ConsentPolicyType.fromDbString('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('ConsentPolicyType', () {
    test('toDbString returns correct snake_case strings', () {
      expect(
        ConsentPolicyType.privacyPolicy.toDbString(),
        'privacy_policy',
      );
      expect(
        ConsentPolicyType.termsOfService.toDbString(),
        'terms_of_service',
      );
    });
  });
}
```

### Sub-phase 3.5: Verification
**Agent:** qa-testing-agent

#### Step 3.5.1: Run consent model tests
```
pwsh -Command "flutter test test/features/settings/data/models/consent_record_test.dart --no-pub"
```

#### Step 3.5.2: Run static analysis
```
pwsh -Command "flutter analyze --no-fatal-infos"
```

---

## Phase 4: Support Data Layer
### Sub-phase 4.1: SupportTicket model
**Files:**
- Create: `lib/features/settings/data/models/support_ticket.dart`
- Modify: `lib/features/settings/data/models/models.dart` (barrel export)
**Agent:** backend-data-layer-agent

#### Step 4.1.1: Create SupportTicket model
Create `lib/features/settings/data/models/support_ticket.dart`:

```dart
import 'package:uuid/uuid.dart';

// WHY: Support tickets let users report issues from within the app.
// FROM SPEC: Client can INSERT and SELECT. Status is read-only from client
// (updated by admin via Supabase dashboard or backend function).

/// Status values for support tickets.
/// FROM SPEC: open, acknowledged, resolved (3 states only).
enum SupportTicketStatus {
  open,
  acknowledged,
  resolved;

  /// Convert to database string format.
  String toDbString() {
    switch (this) {
      case SupportTicketStatus.open:
        return 'open';
      case SupportTicketStatus.acknowledged:
        return 'acknowledged';
      case SupportTicketStatus.resolved:
        return 'resolved';
    }
  }

  /// Parse from database string format.
  static SupportTicketStatus fromDbString(String value) {
    switch (value) {
      case 'open':
        return SupportTicketStatus.open;
      case 'acknowledged':
        return SupportTicketStatus.acknowledged;
      case 'resolved':
        return SupportTicketStatus.resolved;
      default:
        throw ArgumentError('Unknown ticket status: $value');
    }
  }
}

class SupportTicket {
  final String id;
  final String userId;
  final String? subject;
  final String message;
  final String appVersion;
  final String platform;
  final String? logFilePath;
  final DateTime createdAt;
  final SupportTicketStatus status;

  /// Table name constant for datasource usage.
  static const String tableName = 'support_tickets';

  SupportTicket({
    String? id,
    required this.userId,
    this.subject,
    required this.message,
    required this.appVersion,
    required this.platform,
    this.logFilePath,
    DateTime? createdAt,
    this.status = SupportTicketStatus.open,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'message': message,
      'app_version': appVersion,
      'platform': platform,
      'log_file_path': logFilePath,
      'created_at': createdAt.toUtc().toIso8601String(),
      'status': status.toDbString(),
    };
  }

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      subject: map['subject'] as String?,
      message: map['message'] as String,
      appVersion: map['app_version'] as String,
      platform: map['platform'] as String,
      logFilePath: map['log_file_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: SupportTicketStatus.fromDbString(map['status'] as String),
    );
  }

  // NOTE: No copyWith() — tickets are created by the client and status is
  // managed server-side. If we need to display updated status from sync,
  // we create a new SupportTicket from the synced map data.
}
```

#### Step 4.1.2: Update barrel export
Add to `lib/features/settings/data/models/models.dart`:

```dart
export 'support_ticket.dart';
```

### Sub-phase 4.2: SupportLocalDatasource
**Files:**
- Create: `lib/features/settings/data/datasources/support_local_datasource.dart`
**Agent:** backend-data-layer-agent

#### Step 4.2.1: Create SupportLocalDatasource
Create `lib/features/settings/data/datasources/support_local_datasource.dart`:

```dart
import 'package:construction_inspector/core/database/database_service.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import '../models/support_ticket.dart';

// WHY: Datasource for support tickets. Does NOT extend GenericLocalDatasource
// because support tickets have no soft-delete, no update from client side,
// and use a non-standard query pattern (user-scoped, status-filtered).

class SupportLocalDatasource {
  final DatabaseService _dbService;

  SupportLocalDatasource(this._dbService);

  /// Insert a new support ticket.
  Future<void> insert(SupportTicket ticket) async {
    final db = await _dbService.database;
    await db.insert(SupportTicket.tableName, ticket.toMap());
    Logger.db('INSERT ${SupportTicket.tableName} id=${ticket.id} '
        'subject=${ticket.subject ?? "(none)"}');
  }

  /// Get all tickets for a user, ordered by creation time (newest first).
  Future<List<SupportTicket>> getByUserId(String userId) async {
    final db = await _dbService.database;
    final results = await db.query(
      SupportTicket.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((row) => SupportTicket.fromMap(row)).toList();
  }

  /// Get a single ticket by ID.
  Future<SupportTicket?> getById(String id) async {
    final db = await _dbService.database;
    final results = await db.query(
      SupportTicket.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SupportTicket.fromMap(results.first);
  }

  /// Get tickets filtered by status for a user.
  Future<List<SupportTicket>> getByStatus({
    required String userId,
    required SupportTicketStatus status,
  }) async {
    final db = await _dbService.database;
    final results = await db.query(
      SupportTicket.tableName,
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, status.toDbString()],
      orderBy: 'created_at DESC',
    );
    return results.map((row) => SupportTicket.fromMap(row)).toList();
  }

  /// Update ticket status (used when syncing server-side status changes).
  /// NOTE: This is only called by the sync layer, not by user actions.
  Future<void> updateStatus(String id, SupportTicketStatus status) async {
    final db = await _dbService.database;
    await db.update(
      SupportTicket.tableName,
      {'status': status.toDbString()},
      where: 'id = ?',
      whereArgs: [id],
    );
    Logger.db('UPDATE ${SupportTicket.tableName} id=$id status=${status.toDbString()}');
  }
}
```

### Sub-phase 4.3: SupportRepository
**Files:**
- Create: `lib/features/settings/data/repositories/support_repository.dart`
**Agent:** backend-data-layer-agent

#### Step 4.3.1: Create SupportRepository
Create `lib/features/settings/data/repositories/support_repository.dart`:

```dart
import '../datasources/support_local_datasource.dart';
import '../models/support_ticket.dart';

// WHY: Thin wrapper around SupportLocalDatasource.
// Does NOT implement BaseRepository — non-standard API (user-scoped, append-only).

class SupportRepository {
  final SupportLocalDatasource _localDatasource;

  SupportRepository(this._localDatasource);

  /// Submit a new support ticket.
  Future<void> submitTicket(SupportTicket ticket) {
    return _localDatasource.insert(ticket);
  }

  /// Get all tickets for the current user.
  Future<List<SupportTicket>> getTickets(String userId) {
    return _localDatasource.getByUserId(userId);
  }

  /// Get a specific ticket by ID.
  Future<SupportTicket?> getTicketById(String id) {
    return _localDatasource.getById(id);
  }

  /// Get tickets with a specific status.
  Future<List<SupportTicket>> getTicketsByStatus({
    required String userId,
    required SupportTicketStatus status,
  }) {
    return _localDatasource.getByStatus(
      userId: userId,
      status: status,
    );
  }

  /// Update ticket status from sync.
  Future<void> updateTicketStatus(String id, SupportTicketStatus status) {
    return _localDatasource.updateStatus(id, status);
  }
}
```

### Sub-phase 4.4: Support model unit tests
**Files:**
- Create: `test/features/settings/data/models/support_ticket_test.dart`
**Agent:** qa-testing-agent

#### Step 4.4.1: Create SupportTicket model tests
Create `test/features/settings/data/models/support_ticket_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/features/settings/data/models/support_ticket.dart';

void main() {
  group('SupportTicket', () {
    test('creates with auto-generated ID, UTC timestamp, and open status', () {
      final ticket = SupportTicket(
        userId: 'user-1',
        subject: 'App crash',
        message: 'The app crashed when I tapped sync',
        appVersion: '0.1.2+3',
        platform: 'android',
      );
      expect(ticket.id, isNotEmpty);
      expect(ticket.userId, 'user-1');
      expect(ticket.status, SupportTicketStatus.open);
      expect(ticket.createdAt.isUtc, isTrue);
    });

    test('toMap produces correct keys and values', () {
      final ticket = SupportTicket(
        id: 'test-id',
        userId: 'user-1',
        subject: 'Bug report',
        message: 'Something is broken',
        appVersion: '0.1.2+3',
        platform: 'windows',
        logFilePath: '/path/to/log.txt',
      );
      final map = ticket.toMap();
      expect(map['id'], 'test-id');
      expect(map['user_id'], 'user-1');
      expect(map['subject'], 'Bug report');
      expect(map['message'], 'Something is broken');
      expect(map['app_version'], '0.1.2+3');
      expect(map['platform'], 'windows');
      expect(map['log_file_path'], '/path/to/log.txt');
      expect(map['status'], 'open');
      expect(map.containsKey('created_at'), isTrue);
    });

    test('toMap handles null subject and logFilePath', () {
      final ticket = SupportTicket(
        id: 'test-id',
        userId: 'user-1',
        message: 'No subject ticket',
        appVersion: '0.1.2+3',
        platform: 'android',
      );
      final map = ticket.toMap();
      expect(map['subject'], isNull);
      expect(map['log_file_path'], isNull);
    });

    test('fromMap round-trips correctly', () {
      final original = SupportTicket(
        id: 'test-id',
        userId: 'user-1',
        subject: 'Test subject',
        message: 'Test message body',
        appVersion: '0.1.2+3',
        platform: 'android',
        logFilePath: '/logs/debug.log',
        status: SupportTicketStatus.acknowledged,
      );
      final restored = SupportTicket.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.subject, original.subject);
      expect(restored.message, original.message);
      expect(restored.appVersion, original.appVersion);
      expect(restored.platform, original.platform);
      expect(restored.logFilePath, original.logFilePath);
      expect(restored.status, original.status);
      expect(
        restored.createdAt.difference(original.createdAt).inSeconds,
        0,
      );
    });

    test('fromMap handles all status values', () {
      final baseMap = {
        'id': 'test-id',
        'user_id': 'user-1',
        'message': 'test',
        'app_version': '0.1.2+3',
        'platform': 'android',
        'created_at': '2026-03-29T12:00:00.000Z',
      };

      for (final entry in {
        'open': SupportTicketStatus.open,
        'acknowledged': SupportTicketStatus.acknowledged,
        'resolved': SupportTicketStatus.resolved,
      }.entries) {
        final map = {...baseMap, 'status': entry.key};
        final ticket = SupportTicket.fromMap(map);
        expect(ticket.status, entry.value,
            reason: 'Failed for status: ${entry.key}');
      }
    });

    test('fromDbString throws on unknown status', () {
      expect(
        () => SupportTicketStatus.fromDbString('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('SupportTicketStatus', () {
    test('toDbString returns correct snake_case strings', () {
      expect(SupportTicketStatus.open.toDbString(), 'open');
      expect(SupportTicketStatus.acknowledged.toDbString(), 'acknowledged');
      expect(SupportTicketStatus.resolved.toDbString(), 'resolved');
    });
  });
}
```

### Sub-phase 4.5: Verification
**Agent:** qa-testing-agent

#### Step 4.5.1: Run all new model tests
```
pwsh -Command "flutter test test/features/settings/data/models/ --no-pub"
```

#### Step 4.5.2: Run full static analysis
```
pwsh -Command "flutter analyze --no-fatal-infos"
```

#### Step 4.5.3: Run full test suite to check for regressions
```
pwsh -Command "flutter test --no-pub"
```
