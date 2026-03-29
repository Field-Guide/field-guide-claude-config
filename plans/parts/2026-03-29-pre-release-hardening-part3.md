# Pre-Release Hardening Implementation Plan — Part 3 (Phases 9-12)

**Created**: 2026-03-29
**Scope**: About screen overhaul, support tickets, legal documents, integration & cleanup
**Agents**: frontend-flutter-specialist-agent (Phases 9, 10, 11 UI), backend-data-layer-agent (Phase 10 data), general-purpose (Phase 11 assets, Phase 12 wiring), qa-testing-agent (Phase 12 tests)

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

---

## Phase 9: About Screen Overhaul
### Sub-phase 9.1: Add Testing Keys & Build Number Getter
**Files:**
- Modify: `lib/shared/testing_keys/settings_keys.dart`
- Modify: `lib/features/auth/presentation/providers/app_config_provider.dart`
**Agent:** frontend-flutter-specialist-agent

#### Step 9.1.1: Add new testing keys for About section tiles
**File:** `lib/shared/testing_keys/settings_keys.dart`

Add the following keys after `settingsLicensesTile` (line 99), inside the `// Settings - Help & About Tiles` section:

```dart
  // WHY: New About section tiles for pre-release hardening (ToS, Privacy, build number, help)
  static const aboutTosTile = Key('about_tos_tile');
  static const aboutPrivacyTile = Key('about_privacy_tile');
  static const aboutBuildNumber = Key('about_build_number');
```

NOTE: `settingsHelpSupportTile` (line 97) already exists — reuse it, do NOT duplicate.

#### Step 9.1.2: Add buildNumber getter to AppConfigProvider
**File:** `lib/features/auth/presentation/providers/app_config_provider.dart`

Add a new field and getter. After `String? _appVersion;` (line 24), add:

```dart
  // WHY: Build number displayed in About section for debugging/support reference
  String? _buildNumber;
```

After the `String? get appVersion => _appVersion;` getter (line 103), add:

```dart
  /// Current app build number string (e.g., "3" from version 0.1.2+3).
  String? get buildNumber => _buildNumber;
```

In `loadAppVersion()` (line 113-121), after `_appVersion = info.version;` (line 116), add:

```dart
      _buildNumber = info.buildNumber;
```

### Sub-phase 9.2: Replace About Section in Settings Screen
**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
**Agent:** frontend-flutter-specialist-agent

#### Step 9.2.1: Add url_launcher import
**File:** `lib/features/settings/presentation/screens/settings_screen.dart`

Add at the top imports section (verify it is not already imported):

```dart
import 'package:url_launcher/url_launcher.dart';
```

NOTE: `url_launcher` is already a dependency in pubspec.yaml (line 96). No pubspec change needed.

#### Step 9.2.2: Replace the entire About section (lines 312-346)
**File:** `lib/features/settings/presentation/screens/settings_screen.dart`

Replace the block from `// ---- 5. ABOUT ----` (line 312) through the closing `const SizedBox(height: 32),` (line 346) with:

```dart
          // ---- 5. ABOUT ----
          // WHY: Enhanced About section for pre-release — version+build, help, ToS, privacy, licenses
          SectionHeader(
            key: TestingKeys.settingsAboutSection,
            title: 'About',
          ),
          // Version tile with build number subtitle
          Consumer<AppConfigProvider>(
            builder: (context, configProvider, _) {
              final version = configProvider.appVersion ?? 'unknown';
              final build = configProvider.buildNumber ?? '?';
              return ListTile(
                key: TestingKeys.settingsVersionTile,
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                // NOTE: Show both version and build for support ticket reference
                subtitle: Text(
                  '$version (build $build)',
                  key: TestingKeys.aboutBuildNumber,
                ),
              );
            },
          ),
          // Help & Support — navigates to support ticket form
          ListTile(
            key: TestingKeys.settingsHelpSupportTile,
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // WHY: Route to support ticket screen added in Phase 10
              context.pushNamed('help-support');
            },
          ),
          // Terms of Service — navigates to legal document viewer
          ListTile(
            key: TestingKeys.aboutTosTile,
            leading: const Icon(Icons.gavel),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // WHY: Route to legal document screen added in Phase 11
              context.pushNamed(
                'legal-document',
                queryParameters: {'type': 'tos'},
              );
            },
          ),
          // Privacy Policy — navigates to legal document viewer
          ListTile(
            key: TestingKeys.aboutPrivacyTile,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.pushNamed(
                'legal-document',
                queryParameters: {'type': 'privacy'},
              );
            },
          ),
          // Licenses — uses Flutter's built-in LicenseRegistry for accurate data
          Consumer<AppConfigProvider>(
            builder: (context, configProvider, _) {
              return ListTile(
                key: TestingKeys.settingsLicensesTile,
                leading: const Icon(Icons.description),
                title: const Text('Open Source Licenses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // WHY: Route to custom licenses screen added in Phase 11.
                  // Replaces showLicensePage() with a custom screen that
                  // renders grouped license entries from LicenseRegistry.
                  context.pushNamed('oss-licenses');
                },
              );
            },
          ),
          const SizedBox(height: 32),
```

### Sub-phase 9.3: Verify Phase 9
**Agent:** frontend-flutter-specialist-agent

#### Step 9.3.1: Run static analysis
```
pwsh -Command "flutter analyze lib/features/settings/presentation/screens/settings_screen.dart lib/features/auth/presentation/providers/app_config_provider.dart lib/shared/testing_keys/settings_keys.dart"
```

NOTE: Analysis will report unresolved routes (`help-support`, `legal-document`, `oss-licenses`) — these are wired in Phase 12. The code compiles but routes are dead until then.

---

## Phase 10: Support Ticket System
### Sub-phase 10.1: Create SupportProvider
**Files:**
- Create: `lib/features/settings/presentation/providers/support_provider.dart`
- Modify: `lib/features/settings/presentation/providers/providers.dart` (barrel export)
**Agent:** frontend-flutter-specialist-agent

#### Step 10.1.1: Create SupportProvider class
**File:** `lib/features/settings/presentation/providers/support_provider.dart` (NEW)

```dart
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:construction_inspector/core/config/supabase_config.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/features/settings/data/repositories/support_repository.dart';
import 'package:construction_inspector/features/settings/data/models/support_ticket.dart';

/// WHY: Handles support ticket submission with optional log bundle upload.
/// Tickets are inserted into LOCAL SQLite via SupportRepository (offline-first).
/// Log files are zipped and uploaded to Supabase Storage `support-logs` bucket.
/// Sync of the support_tickets table to Supabase is deferred (see FIX-12).
class SupportProvider extends ChangeNotifier {
  final SupportRepository _supportRepository;

  SupportProvider({required SupportRepository supportRepository})
      : _supportRepository = supportRepository;
  // Subject categories matching support workflow
  // WHY: Fixed categories allow support team to triage efficiently
  static const List<String> subjectCategories = [
    'Bug Report',
    'Feature Request',
    'General Feedback',
    'Other',
  ];

  String? _selectedSubject;
  String _message = '';
  bool _attachLogs = false;
  bool _isSubmitting = false;
  String? _error;
  bool _submitted = false;

  // Getters
  String? get selectedSubject => _selectedSubject;
  String get message => _message;
  bool get attachLogs => _attachLogs;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get submitted => _submitted;

  /// Whether the form is valid for submission.
  bool get canSubmit =>
      _selectedSubject != null &&
      _message.trim().length >= 10 &&
      !_isSubmitting;

  // Setters
  void setSubject(String? subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  void setMessage(String message) {
    _message = message;
    notifyListeners();
  }

  void setAttachLogs(bool attach) {
    _attachLogs = attach;
    notifyListeners();
  }

  /// Reset form to initial state.
  void reset() {
    _selectedSubject = null;
    _message = '';
    _attachLogs = false;
    _isSubmitting = false;
    _error = null;
    _submitted = false;
    notifyListeners();
  }

  /// Submit the support ticket.
  ///
  /// 1. If attachLogs is true, zip log files and upload to Supabase Storage.
  /// 2. Insert a SupportTicket into LOCAL SQLite via SupportRepository (offline-first).
  /// 3. On failure, set error message but don't throw.
  Future<void> submit({
    required String userId,
    required String? appVersion,
  }) async {
    if (!canSubmit) return;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final ticketId = const Uuid().v4();
      String? logPath;

      // Step 1: Bundle and upload logs if requested
      // NOTE: Log upload still goes directly to Supabase Storage (separate from ticket record)
      if (_attachLogs) {
        logPath = await _uploadLogBundle(userId: userId, ticketId: ticketId);
      }

      // Step 2: Insert ticket into LOCAL SQLite via SupportRepository (offline-first)
      // WHY: Tickets are stored locally first, then synced to Supabase later.
      // This follows the app's offline-first architecture.
      // NOTE: build_number removed (not in schema), platform added, log_file_path corrected.
      final ticket = SupportTicket(
        id: ticketId,
        userId: userId,
        subject: _selectedSubject,
        message: _message.trim(),
        appVersion: appVersion ?? 'unknown',
        platform: defaultTargetPlatform.name,
        logFilePath: logPath,
      );

      await _supportRepository.submitTicket(ticket);
      // TODO: Sync trigger for support_tickets — deferred (see FIX-12)

      _submitted = true;
      Logger.ui('[SupportProvider] Ticket $ticketId submitted successfully');
    } catch (e) {
      Logger.error('[SupportProvider] Ticket submission failed: $e');
      _error = 'Failed to submit ticket. Please try again later.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Zip log files from the current session directory and upload to Supabase Storage.
  /// Returns the remote path on success, null on failure.
  Future<String?> _uploadLogBundle({
    required String userId,
    required String ticketId,
  }) async {
    try {
      final logDir = Logger.logDirectoryPath;
      if (logDir == null) {
        Logger.ui('[SupportProvider] No log directory available, skipping log upload');
        return null;
      }

      final dir = Directory(logDir);
      if (!await dir.exists()) return null;

      // WHY: Collect all .log files from the log directory (not subdirs)
      // to keep bundle size manageable
      final logFiles = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      if (logFiles.isEmpty) return null;

      // Create zip archive
      final archive = Archive();
      for (final file in logFiles) {
        final bytes = await file.readAsBytes();
        final name = file.uri.pathSegments.last;
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) return null;

      // FROM SPEC: "Cap at last N session files or X MB total"
      const maxLogBundleSize = 5 * 1024 * 1024; // 5MB
      if (zipBytes.length > maxLogBundleSize) {
        Logger.ui('Log bundle too large (${zipBytes.length} bytes), skipping upload');
        return null;
      }

      // Upload to Supabase Storage
      final remotePath = '$userId/$ticketId/logs.zip';
      final storage = Supabase.instance.client.storage;
      await storage.from('support-logs').uploadBinary(
        remotePath,
        zipBytes,
        fileOptions: const FileOptions(contentType: 'application/zip'),
      );

      Logger.ui('[SupportProvider] Log bundle uploaded: $remotePath');
      return remotePath;
    } catch (e) {
      // WHY: Log upload failure should NOT block ticket submission
      Logger.error('[SupportProvider] Log bundle upload failed: $e');
      return null;
    }
  }
}
```

NOTE: This uses the `archive` package. It must be added to pubspec.yaml in Step 10.1.3.

#### Step 10.1.2: Add barrel export
**File:** `lib/features/settings/presentation/providers/providers.dart`

Add to the exports:

```dart
export 'support_provider.dart';
```

#### Step 10.1.3: Add `archive` dependency to pubspec.yaml
**File:** `pubspec.yaml`

Under the `# Utilities` section (after line 103, near `crypto`), add:

```yaml
  archive: ^4.0.2
```

Then run:
```
pwsh -Command "flutter pub get"
```

### Sub-phase 10.2: Create Testing Keys for Support Screen
**Files:**
- Create: `lib/shared/testing_keys/support_keys.dart`
- Modify: `lib/shared/testing_keys/testing_keys.dart` (barrel export + facade)
**Agent:** frontend-flutter-specialist-agent

#### Step 10.2.1: Create support_keys.dart
**File:** `lib/shared/testing_keys/support_keys.dart` (NEW)

```dart
import 'package:flutter/material.dart';

/// Support ticket screen testing keys.
class SupportTestingKeys {
  SupportTestingKeys._(); // Prevent instantiation

  // WHY: Keys for support ticket form elements, used in integration tests
  static const supportSubjectDropdown = Key('support_subject_dropdown');
  static const supportMessageField = Key('support_message_field');
  static const supportAttachLogs = Key('support_attach_logs');
  static const supportSubmitButton = Key('support_submit_button');
}
```

#### Step 10.2.2: Add barrel export and facade delegation in testing_keys.dart
**File:** `lib/shared/testing_keys/testing_keys.dart`

Add to the export list (after `export 'sync_keys.dart';`):

```dart
export 'support_keys.dart';
```

Add to the import list (after `import 'sync_keys.dart';`):

```dart
import 'support_keys.dart';
```

Add facade delegation inside the `TestingKeys` class body (follow the existing pattern of delegating to feature-specific keys classes). Find the appropriate alphabetical position in the facade and add:

```dart
  // ============================================
  // Support Ticket
  // ============================================
  static const supportSubjectDropdown = SupportTestingKeys.supportSubjectDropdown;
  static const supportMessageField = SupportTestingKeys.supportMessageField;
  static const supportAttachLogs = SupportTestingKeys.supportAttachLogs;
  static const supportSubmitButton = SupportTestingKeys.supportSubmitButton;
```

### Sub-phase 10.3: Create HelpSupportScreen
**Files:**
- Create: `lib/features/settings/presentation/screens/help_support_screen.dart`
- Modify: `lib/features/settings/presentation/screens/screens.dart` (barrel export)
**Agent:** frontend-flutter-specialist-agent

#### Step 10.3.1: Create HelpSupportScreen widget
**File:** `lib/features/settings/presentation/screens/help_support_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/settings/presentation/providers/support_provider.dart';
import 'package:construction_inspector/shared/shared.dart';

/// WHY: Support ticket form screen. Users can report bugs, request features,
/// or send general feedback. Optional log attachment for debugging.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, _) {
          // WHY: Show success state after submission
          if (provider.submitted) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ticket Submitted',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Thank you for your feedback. We\'ll review your ticket and get back to you.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        provider.reset();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subject dropdown
                DropdownButtonFormField<String>(
                  key: TestingKeys.supportSubjectDropdown,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  value: provider.selectedSubject,
                  items: SupportProvider.subjectCategories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: provider.isSubmitting ? null : provider.setSubject,
                  // WHY: Required field — shows validation hint
                  hint: const Text('Select a category'),
                ),
                const SizedBox(height: 16),

                // Message field
                TextFormField(
                  key: TestingKeys.supportMessageField,
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                    hintText: 'Describe your issue or feedback (min 10 characters)',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  maxLength: 2000,
                  enabled: !provider.isSubmitting,
                  onChanged: provider.setMessage,
                ),
                const SizedBox(height: 8),

                // Attach logs toggle
                SwitchListTile(
                  key: TestingKeys.supportAttachLogs,
                  title: const Text('Attach diagnostic logs'),
                  subtitle: const Text(
                    'Includes recent app logs to help diagnose issues',
                  ),
                  value: provider.attachLogs,
                  onChanged: provider.isSubmitting
                      ? null
                      : (value) => provider.setAttachLogs(value),
                ),
                const SizedBox(height: 16),

                // Error message
                if (provider.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit button
                FilledButton.icon(
                  key: TestingKeys.supportSubmitButton,
                  onPressed: provider.canSubmit
                      ? () => _submit(context, provider)
                      : null,
                  icon: provider.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    provider.isSubmitting ? 'Submitting...' : 'Submit Ticket',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context, SupportProvider provider) async {
    final authProvider = context.read<AuthProvider>();
    final configProvider = context.read<AppConfigProvider>();
    final userId = authProvider.userProfile?.id ?? 'anonymous';

    await provider.submit(
      userId: userId,
      appVersion: configProvider.appVersion,
    );
  }
}
```

#### Step 10.3.2: Add barrel export
**File:** `lib/features/settings/presentation/screens/screens.dart`

Add:

```dart
export 'help_support_screen.dart';
```

### Sub-phase 10.4: Verify Phase 10
**Agent:** frontend-flutter-specialist-agent

#### Step 10.4.1: Run static analysis
```
pwsh -Command "flutter analyze lib/features/settings/presentation/"
```

NOTE: `archive` package may need import adjustment. The package exports `Archive`, `ArchiveFile`, and `ZipEncoder` from `package:archive/archive.dart`. Verify the import path compiles.

---

## Phase 11: Legal Documents
### Sub-phase 11.1: Create Legal Document Assets
**Files:**
- Create: `assets/legal/terms_of_service.md`
- Create: `assets/legal/privacy_policy.md`
- Modify: `pubspec.yaml` (register assets)
**Agent:** general-purpose

#### Step 11.1.1: Create Terms of Service markdown
**File:** `assets/legal/terms_of_service.md` (NEW)

```markdown
# Field Guide — Terms of Service

**Effective Date:** March 29, 2026
**Last Updated:** March 29, 2026

## 1. Acceptance of Terms

By downloading, installing, or using Field Guide ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree, do not use the App.

## 2. Description of Service

Field Guide is a construction inspection tracking application that enables inspectors to:
- Record daily inspection entries and field observations
- Track quantities, contractors, and project personnel
- Capture and organize construction site photographs
- Generate professional PDF inspection reports
- Fill out and manage standardized inspection forms (e.g., MDOT 0582B)
- Synchronize data across devices via cloud services

## 3. Account Registration

You must register an account to use the App. You agree to:
- Provide accurate, current, and complete registration information
- Maintain and promptly update your registration information
- Maintain the security of your password and accept responsibility for all activities under your account
- Immediately notify us of unauthorized use of your account

## 4. User Content

You retain ownership of all content you create in the App, including inspection entries, photos, reports, and form submissions ("User Content"). By using the App, you grant us a limited license to store, process, and transmit your User Content solely for the purpose of providing the service.

## 5. Acceptable Use

You agree not to:
- Use the App for any unlawful purpose
- Upload malicious content or attempt to compromise the system
- Share your account credentials with unauthorized users
- Circumvent any access controls or security measures
- Attempt to access data belonging to other users or organizations

## 6. Data Retention

Construction inspection records may be subject to regulatory retention requirements. The App retains your data for a minimum of 7 years to comply with typical construction industry record-keeping requirements. You may request data export at any time.

## 7. Service Availability

We strive to maintain high availability but do not guarantee uninterrupted service. The App is designed for offline-first operation; core features work without an internet connection. Cloud synchronization requires connectivity.

## 8. Intellectual Property

The App, including its design, code, and documentation, is protected by copyright and other intellectual property laws. You may not copy, modify, distribute, or reverse-engineer the App.

## 9. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE APP.

The App generates reports and records based on user input. Accuracy of inspection records is the responsibility of the inspector. The App does not replace professional judgment.

## 10. Termination

We may suspend or terminate your access to the App at any time for violation of these Terms. Upon termination, your right to use the App ceases immediately. Your data will be retained per Section 6.

## 11. Changes to Terms

We may modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the modified Terms. We will notify users of material changes via the App.

## 12. Contact

For questions about these Terms, contact us through the Help & Support section in the App.
```

#### Step 11.1.2: Create Privacy Policy markdown
**File:** `assets/legal/privacy_policy.md` (NEW)

```markdown
# Field Guide — Privacy Policy

**Effective Date:** March 29, 2026
**Last Updated:** March 29, 2026

## 1. Introduction

This Privacy Policy describes how Field Guide ("the App," "we," "our") collects, uses, and protects your information. We are committed to protecting the privacy of construction inspectors and their organizations.

## 2. Information We Collect

### 2.1 Account Information
- Name, email address, and professional initials
- Organization/company affiliation
- Role (Inspector, Engineer, Admin)

### 2.2 Inspection Data
- Daily inspection entries and field observations
- Contractor and personnel records
- Quantity tracking and bid item data
- Form submissions (e.g., MDOT 0582B soil density reports)

### 2.3 Photographs
- Construction site photographs captured through the App
- **Photo EXIF metadata**, including GPS coordinates, timestamps, and camera settings
- GPS/location data is embedded in photos for geo-tagging inspection evidence

### 2.4 Device Information
- Device model and operating system version (for crash reporting)
- App version and build number

### 2.5 Usage Analytics
- Anonymous usage patterns via **Aptabase** (privacy-focused analytics)
- **No personally identifiable information (PII)** is sent to analytics
- Analytics help us improve the App experience

## 3. How We Process Your Data

### 3.1 On-Device Processing
- **OCR (Optical Character Recognition)** is performed entirely on-device using Tesseract
- No document images or OCR text are sent to external servers
- PDF generation occurs locally on your device

### 3.2 Cloud Synchronization
- Data is synchronized to our cloud backend via **Supabase** (hosted on AWS)
- Synchronization enables multi-device access and team collaboration
- Data is encrypted in transit (TLS 1.2+) and at rest
- Row-Level Security (RLS) ensures users can only access data belonging to their organization

### 3.3 Local Storage
- A local database caches your data on-device for offline access
- Local data is stored in a local database within the app's private storage directory
- Uninstalling the App removes all local data

## 4. Crash Reporting

We use **Sentry** for anonymous crash reporting:
- Stack traces and error messages (no PII)
- Device model and OS version
- App version and build number
- Crash reports help us identify and fix bugs quickly

## 5. Data Sharing

- **We do not sell your data to third parties**
- Data is shared only with your organization's team members (as configured by your Admin)
- We may disclose data if required by law or legal process
- Service providers (Supabase, Sentry, Aptabase) process data on our behalf under strict data processing agreements

## 6. Data Retention

- Inspection records are retained for a minimum of **7 years** to comply with construction industry record-keeping requirements
- You may request data export at any time through your organization's Admin
- Account deletion requests will be processed within 30 days, subject to retention requirements
- Diagnostic logs are retained for 30 days and automatically purged

## 7. Data Security

- All cloud data is protected by Row-Level Security (RLS) policies
- Authentication is handled via Supabase Auth with secure token management
- Sensitive credentials are stored using platform-secure storage (Keychain/Keystore)
- Regular security reviews and dependency updates

## 8. Your Rights

Depending on your jurisdiction, you may have the right to:
- Access your personal data
- Correct inaccurate data
- Request deletion of your data (subject to retention requirements)
- Export your data in a portable format
- Object to certain processing activities

## 9. Children's Privacy

The App is not intended for use by individuals under 18 years of age. We do not knowingly collect personal information from children.

## 10. Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of material changes via the App. Continued use of the App after changes constitutes acceptance.

## 11. Contact

For privacy-related questions or to exercise your rights, contact us through the Help & Support section in the App.
```

#### Step 11.1.3: Register legal assets in pubspec.yaml
**File:** `pubspec.yaml`

After the line `    - assets/tessdata/` (line 154), add:

```yaml
    - assets/legal/
```

### Sub-phase 11.2: Add flutter_markdown Dependency
**Files:**
- Modify: `pubspec.yaml`
**Agent:** general-purpose

#### Step 11.2.1: Add flutter_markdown to pubspec.yaml
**File:** `pubspec.yaml`

Under the `# URL Launching` section (after `url_launcher: ^6.3.1`, line 96), add:

```yaml

  # Legal / Markdown rendering
  flutter_markdown: ^0.7.6
```

Then run:
```
pwsh -Command "flutter pub get"
```

### Sub-phase 11.3: Create LegalDocumentScreen
**Files:**
- Create: `lib/features/settings/presentation/screens/legal_document_screen.dart`
- Modify: `lib/features/settings/presentation/screens/screens.dart` (barrel export)
**Agent:** frontend-flutter-specialist-agent

#### Step 11.3.1: Create LegalDocumentScreen widget
**File:** `lib/features/settings/presentation/screens/legal_document_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:construction_inspector/core/logging/logger.dart';

/// WHY: Renders bundled markdown legal documents (ToS, Privacy Policy).
/// Supports "open in browser" for external viewing.
/// The `type` parameter selects which document to display:
/// - 'tos' -> assets/legal/terms_of_service.md
/// - 'privacy' -> assets/legal/privacy_policy.md
class LegalDocumentScreen extends StatefulWidget {
  final String type;

  const LegalDocumentScreen({super.key, required this.type});

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  String? _markdownContent;
  String? _error;

  /// Map document type to asset path and display title.
  static const _documents = {
    'tos': (
      asset: 'assets/legal/terms_of_service.md',
      title: 'Terms of Service',
    ),
    'privacy': (
      asset: 'assets/legal/privacy_policy.md',
      title: 'Privacy Policy',
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final doc = _documents[widget.type];
    if (doc == null) {
      setState(() => _error = 'Unknown document type: ${widget.type}');
      return;
    }

    try {
      final content = await rootBundle.loadString(doc.asset);
      if (!mounted) return;
      setState(() => _markdownContent = content);
    } catch (e) {
      Logger.error('[LegalDocumentScreen] Failed to load ${doc.asset}: $e');
      if (!mounted) return;
      setState(() => _error = 'Failed to load document.');
    }
  }

  String get _title {
    return _documents[widget.type]?.title ?? 'Legal Document';
  }

  /// WHY: Hosted URLs for legal documents — placeholder until GitHub Pages is set up.
  static const _hostedUrls = {
    'tos': 'https://fieldguideapp.com/terms',
    'privacy': 'https://fieldguideapp.com/privacy',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        // WHY: Spec requires "Open in browser button in app bar to view hosted version"
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in browser',
            onPressed: () async {
              final url = _hostedUrls[widget.type] ?? _hostedUrls['tos']!;
              try {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to open browser. Check your internet connection.'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_markdownContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Markdown(
      data: _markdownContent!,
      selectable: true,
      // WHY: Handle taps on links in the markdown content
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(
            Uri.parse(href),
            mode: LaunchMode.externalApplication,
          );
        }
      },
    );
  }
}
```

#### Step 11.3.2: Add barrel export
**File:** `lib/features/settings/presentation/screens/screens.dart`

Add:

```dart
export 'legal_document_screen.dart';
```

### Sub-phase 11.4: Create OssLicensesScreen
**Files:**
- Create: `lib/features/settings/presentation/screens/oss_licenses_screen.dart`
- Modify: `lib/features/settings/presentation/screens/screens.dart` (barrel export)
**Agent:** frontend-flutter-specialist-agent

#### Step 11.4.1: Create OssLicensesScreen widget
**File:** `lib/features/settings/presentation/screens/oss_licenses_screen.dart` (NEW)

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// WHY: Custom open-source licenses screen that reads from Flutter's built-in
/// LicenseRegistry. Replaces the default showLicensePage() with a more
/// polished and navigable experience. Groups licenses by package name.
///
/// NOTE: We intentionally use LicenseRegistry (built into Flutter) instead of
/// a third-party oss_licenses package. This ensures accuracy since
/// LicenseRegistry is populated directly from pubspec.lock at build time.
class OssLicensesScreen extends StatefulWidget {
  const OssLicensesScreen({super.key});

  @override
  State<OssLicensesScreen> createState() => _OssLicensesScreenState();
}

class _OssLicensesScreenState extends State<OssLicensesScreen> {
  late Future<Map<String, List<LicenseEntry>>> _licensesFuture;

  @override
  void initState() {
    super.initState();
    _licensesFuture = _loadLicenses();
  }

  /// Collects all license entries from LicenseRegistry and groups by package.
  Future<Map<String, List<LicenseEntry>>> _loadLicenses() async {
    final Map<String, List<LicenseEntry>> grouped = {};

    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        grouped.putIfAbsent(package, () => []).add(entry);
      }
    }

    // Sort package names alphabetically
    final sorted = Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Source Licenses'),
      ),
      body: FutureBuilder<Map<String, List<LicenseEntry>>>(
        future: _licensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load licenses: ${snapshot.error}'),
            );
          }

          final licenses = snapshot.data!;

          return ListView.builder(
            itemCount: licenses.length,
            itemBuilder: (context, index) {
              final package = licenses.keys.elementAt(index);
              final entries = licenses[package]!;

              return ExpansionTile(
                title: Text(package),
                subtitle: Text(
                  '${entries.length} license${entries.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                children: entries.map((entry) {
                  // WHY: LicenseEntry.paragraphs yields LicenseParagraph objects.
                  // Each has `text` and `indent` properties.
                  final paragraphText = entry.paragraphs
                      .map((p) => p.text)
                      .join('\n\n');

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      paragraphText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
```

#### Step 11.4.2: Add barrel export
**File:** `lib/features/settings/presentation/screens/screens.dart`

Add:

```dart
export 'oss_licenses_screen.dart';
```

### Sub-phase 11.5: Verify Phase 11
**Agent:** frontend-flutter-specialist-agent

#### Step 11.5.1: Run pub get and static analysis
```
pwsh -Command "flutter pub get && flutter analyze lib/features/settings/presentation/screens/legal_document_screen.dart lib/features/settings/presentation/screens/oss_licenses_screen.dart"
```

---

## Phase 12: Integration Testing & Cleanup
### Sub-phase 12.1: Wire Routes in AppRouter
**Files:**
- Modify: `lib/core/router/app_router.dart`
**Agent:** general-purpose

#### Step 12.1.1: Add import for new screens
**File:** `lib/core/router/app_router.dart`

Verify that `lib/features/settings/presentation/screens/screens.dart` is already imported (it is, via line 20: `import '...settings/presentation/screens/screens.dart';`). No new import needed — the barrel export handles it.

#### Step 12.1.2: Add routes for help-support, legal-document, and oss-licenses
**File:** `lib/core/router/app_router.dart`

Find the route block for `/admin-dashboard` (around line 426-428). After that GoRoute block, add three new routes:

```dart
      // WHY: Help & Support ticket form — Phase 10
      GoRoute(
        path: '/help-support',
        name: 'help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      // WHY: Legal document viewer — Phase 11
      // Query param 'type' selects document: 'tos' or 'privacy'
      GoRoute(
        path: '/legal-document',
        name: 'legal-document',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'tos';
          return LegalDocumentScreen(type: type);
        },
      ),
      // WHY: Open source licenses screen — Phase 11
      GoRoute(
        path: '/oss-licenses',
        name: 'oss-licenses',
        builder: (context, state) => const OssLicensesScreen(),
      ),
```

### Sub-phase 12.2: Wire SupportProvider in main.dart
**Files:**
- Modify: `lib/main.dart`
**Agent:** general-purpose

#### Step 12.2.1: Add SupportProvider to ConstructionInspectorApp
**File:** `lib/main.dart`

This is a two-part change:

**Part A:** In the `_runApp()` function, create the repository and provider. The repository should be created alongside other repositories (after DatabaseService init). The provider should be created before the `runApp(` call:

```dart
  // Create alongside other repositories after DatabaseService init:
  final supportLocalDatasource = SupportLocalDatasource(dbService);
  final supportRepository = SupportRepository(supportLocalDatasource);

  // Create before runApp():
  final supportProvider = SupportProvider(supportRepository: supportRepository);
```

Add the imports at the top of the file:

```dart
import 'package:construction_inspector/features/settings/presentation/providers/support_provider.dart';
import 'package:construction_inspector/features/settings/data/datasources/support_local_datasource.dart';
import 'package:construction_inspector/features/settings/data/repositories/support_repository.dart';
```

**Part B:** Pass it into `ConstructionInspectorApp`. Add to the constructor call (after `documentService: documentService,` on line 593):

```dart
      supportProvider: supportProvider,
```

**Part C:** Add the field and constructor parameter to `ConstructionInspectorApp` class.

After `final DocumentService documentService;` (around line 769), add:

```dart
  final SupportProvider supportProvider;
```

After `required this.documentService,` in the constructor (around line 807), add:

```dart
    required this.supportProvider,
```

**Part D:** Add to the MultiProvider providers list. Find an appropriate spot in the providers list (after `ChangeNotifierProvider.value(value: appConfigProvider),` around line 816), add:

```dart
        ChangeNotifierProvider.value(value: supportProvider),
```

### Sub-phase 12.3: Create Integration Test Stubs
**Files:**
- Create: `test/features/settings/about_section_test.dart`
**Agent:** qa-testing-agent

#### Step 12.3.1: Create unit test for SupportProvider
**File:** `test/features/settings/about_section_test.dart` (NEW)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:construction_inspector/features/settings/data/repositories/support_repository.dart';
import 'package:construction_inspector/features/settings/presentation/providers/support_provider.dart';

@GenerateMocks([SupportRepository])
import 'about_section_test.mocks.dart';

/// WHY: Unit tests for SupportProvider validation logic.
/// Integration tests for full form submission require Supabase mocking
/// and are deferred to the E2E test suite.
void main() {
  group('SupportProvider', () {
    late MockSupportRepository mockSupportRepo;
    late SupportProvider provider;

    setUp(() {
      mockSupportRepo = MockSupportRepository();
      provider = SupportProvider(supportRepository: mockSupportRepo);
    });

    test('initial state is valid', () {
      expect(provider.selectedSubject, isNull);
      expect(provider.message, isEmpty);
      expect(provider.attachLogs, isFalse);
      expect(provider.isSubmitting, isFalse);
      expect(provider.error, isNull);
      expect(provider.submitted, isFalse);
      expect(provider.canSubmit, isFalse);
    });

    test('canSubmit requires subject and message >= 10 chars', () {
      // No subject, no message
      expect(provider.canSubmit, isFalse);

      // Subject only
      provider.setSubject('Bug Report');
      expect(provider.canSubmit, isFalse);

      // Subject + short message
      provider.setMessage('short');
      expect(provider.canSubmit, isFalse);

      // Subject + valid message
      provider.setMessage('This is a valid bug report message');
      expect(provider.canSubmit, isTrue);
    });

    test('reset clears all state', () {
      provider.setSubject('Bug Report');
      provider.setMessage('Some message text');
      provider.setAttachLogs(true);

      provider.reset();

      expect(provider.selectedSubject, isNull);
      expect(provider.message, isEmpty);
      expect(provider.attachLogs, isFalse);
      expect(provider.submitted, isFalse);
    });

    test('subjectCategories has expected values', () {
      expect(SupportProvider.subjectCategories, [
        'Bug Report',
        'Feature Request',
        'General Feedback',
        'Other',
      ]);
    });
  });
}
```

### Sub-phase 12.4: ConsentProvider Unit Tests
**Files:**
- Create: `test/features/settings/presentation/providers/consent_provider_test.dart`
**Agent:** qa-testing-agent

#### Step 12.4.1: Create ConsentProvider unit tests
**File:** `test/features/settings/presentation/providers/consent_provider_test.dart` (NEW)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:construction_inspector/features/settings/presentation/providers/consent_provider.dart';
import 'package:construction_inspector/features/settings/data/repositories/consent_repository.dart';
import 'package:construction_inspector/features/settings/data/models/consent_record.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/shared/services/preferences_service.dart';

@GenerateMocks([ConsentRepository, AuthProvider, PreferencesService])
import 'consent_provider_test.mocks.dart';

void main() {
  late ConsentProvider provider;
  late MockConsentRepository mockConsentRepo;
  late MockAuthProvider mockAuthProvider;
  late MockPreferencesService mockPrefs;

  setUp(() {
    mockConsentRepo = MockConsentRepository();
    mockAuthProvider = MockAuthProvider();
    mockPrefs = MockPreferencesService();

    provider = ConsentProvider(
      preferencesService: mockPrefs,
      consentRepository: mockConsentRepo,
      authProvider: mockAuthProvider,
    );
  });

  group('loadConsentState', () {
    test('reads prefs and returns correct state when consent exists', () {
      when(mockPrefs.getBool('consent_accepted')).thenReturn(true);
      when(mockPrefs.getString('consent_policy_version'))
          .thenReturn(ConsentProvider.currentPolicyVersion);

      provider.loadConsentState();

      expect(provider.hasConsented, isTrue);
      expect(provider.hasEverConsented, isTrue);
      expect(provider.needsReconsent, isFalse);
    });

    test('reads prefs and returns false when no consent', () {
      when(mockPrefs.getBool('consent_accepted')).thenReturn(null);
      when(mockPrefs.getString('consent_policy_version')).thenReturn(null);

      provider.loadConsentState();

      expect(provider.hasConsented, isFalse);
      expect(provider.hasEverConsented, isFalse);
    });
  });

  group('acceptConsent', () {
    test('writes prefs AND inserts 2 ConsentRecords via repository', () async {
      when(mockPrefs.setBool(any, any)).thenAnswer((_) async {});
      when(mockPrefs.setString(any, any)).thenAnswer((_) async {});
      when(mockAuthProvider.userId).thenReturn('test-user-id');
      when(mockConsentRepo.recordConsent(any)).thenAnswer((_) async {});

      await provider.acceptConsent(appVersion: '0.1.0');

      // Verify prefs were written
      verify(mockPrefs.setBool('consent_accepted', true)).called(1);
      verify(mockPrefs.setString(
        'consent_policy_version',
        ConsentProvider.currentPolicyVersion,
      )).called(1);

      // Verify 2 ConsentRecord rows inserted (privacy_policy + terms_of_service)
      final captured = verify(mockConsentRepo.recordConsent(captureAny))
          .captured;
      expect(captured.length, 2);
      expect(
        (captured[0] as ConsentRecord).policyType,
        ConsentPolicyType.privacyPolicy,
      );
      expect(
        (captured[1] as ConsentRecord).policyType,
        ConsentPolicyType.termsOfService,
      );
    });
  });

  group('hasConsented', () {
    test('returns true after acceptance', () async {
      when(mockPrefs.setBool(any, any)).thenAnswer((_) async {});
      when(mockPrefs.setString(any, any)).thenAnswer((_) async {});
      when(mockAuthProvider.userId).thenReturn('test-user-id');
      when(mockConsentRepo.recordConsent(any)).thenAnswer((_) async {});

      await provider.acceptConsent(appVersion: '0.1.0');

      expect(provider.hasConsented, isTrue);
    });
  });

  group('needsReconsent', () {
    test('returns true when version mismatch', () {
      when(mockPrefs.getBool('consent_accepted')).thenReturn(true);
      when(mockPrefs.getString('consent_policy_version'))
          .thenReturn('0.9.0'); // old version

      provider.loadConsentState();

      expect(provider.needsReconsent, isTrue);
      expect(provider.hasConsented, isFalse); // current version not accepted
      expect(provider.hasEverConsented, isTrue);
    });
  });
}
```

NOTE: Run `pwsh -Command "flutter pub run build_runner build --delete-conflicting-outputs"` to generate the `.mocks.dart` file before running these tests.

### Sub-phase 12.5: Remove Dead Code (moved from old 12.4)
**Files:**
- Verify: `lib/features/settings/presentation/screens/settings_screen.dart`
**Agent:** general-purpose

#### Step 12.5.1: Verify showLicensePage is no longer used
The `showLicensePage()` call was in the old About section (lines 337-341) and was fully replaced in Phase 9 Step 9.2.2. Verify that no other references to `showLicensePage` exist in the codebase:

```
pwsh -Command "flutter analyze"
```

Search for any remaining `showLicensePage` references. If the import `import 'package:flutter/material.dart'` includes it implicitly (it does — it's part of material), that's fine. Just verify no call sites remain.

### Sub-phase 12.6: Final Verification
**Agent:** general-purpose

#### Step 12.6.1: Run full test suite
```
pwsh -Command "flutter test"
```

#### Step 12.6.2: Run full static analysis
```
pwsh -Command "flutter analyze"
```

#### Step 12.6.3: Verify assets are bundled
```
pwsh -Command "flutter pub get"
```

Confirm no errors about missing assets in `assets/legal/`.

### Sub-phase 12.8: Add Sync Deferral TODOs
**Agent:** general-purpose

#### Step 12.8.1: Add TODO comments for sync deferral
Add TODO comments in the following files to explicitly mark where sync integration would go:

**File:** `lib/features/settings/data/repositories/consent_repository.dart`
After the class declaration, add a comment:
```dart
// TODO: Sync integration for user_consent_records is deferred.
// This table is INSERT-only and upload-only (no pull/conflict resolution needed).
// When ready, add a SyncAdapter that pushes new consent records to Supabase
// on each sync cycle. See SyncOrchestrator for the pattern.
```

**File:** `lib/features/settings/data/repositories/support_repository.dart`
After the class declaration, add a comment:
```dart
// TODO: Sync integration for support_tickets is deferred.
// This table is INSERT-only from the client and upload-only (no bidirectional sync).
// Status updates come from the server side (admin dashboard).
// When ready, add a SyncAdapter that:
// 1. Pushes new local tickets to Supabase
// 2. Pulls status updates for existing tickets
```

**File:** `lib/features/settings/presentation/providers/support_provider.dart`
The `// TODO: Sync trigger for support_tickets` comment was already added in FIX-2.

> **NOTE:** Both `user_consent_records` and `support_tickets` are insert-only from the client perspective. This makes sync significantly simpler than bidirectional tables (no conflict resolution needed). Sync implementation is deferred to a follow-up plan.

---

## Summary of All New/Modified Files

### New Files (9)
| File | Phase | Agent |
|------|-------|-------|
| `lib/features/settings/presentation/providers/support_provider.dart` | 10 | frontend-flutter-specialist-agent |
| `lib/features/settings/presentation/screens/help_support_screen.dart` | 10 | frontend-flutter-specialist-agent |
| `lib/features/settings/presentation/screens/legal_document_screen.dart` | 11 | frontend-flutter-specialist-agent |
| `lib/features/settings/presentation/screens/oss_licenses_screen.dart` | 11 | frontend-flutter-specialist-agent |
| `lib/shared/testing_keys/support_keys.dart` | 10 | frontend-flutter-specialist-agent |
| `assets/legal/terms_of_service.md` | 11 | general-purpose |
| `assets/legal/privacy_policy.md` | 11 | general-purpose |
| `test/features/settings/about_section_test.dart` | 12 | qa-testing-agent |
| `test/features/settings/presentation/providers/consent_provider_test.dart` | 12 | qa-testing-agent |

### Modified Files (8)
| File | Phase | Change |
|------|-------|--------|
| `lib/shared/testing_keys/settings_keys.dart` | 9 | Add aboutTosTile, aboutPrivacyTile, aboutBuildNumber keys |
| `lib/shared/testing_keys/testing_keys.dart` | 10 | Add support_keys barrel export + facade |
| `lib/features/auth/presentation/providers/app_config_provider.dart` | 9 | Add buildNumber getter |
| `lib/features/settings/presentation/screens/settings_screen.dart` | 9 | Replace About section |
| `lib/features/settings/presentation/providers/providers.dart` | 10 | Add support_provider barrel export |
| `lib/features/settings/presentation/screens/screens.dart` | 10-11 | Add 3 barrel exports |
| `lib/core/router/app_router.dart` | 12 | Add 3 routes |
| `lib/main.dart` | 12 | Wire SupportProvider |
| `pubspec.yaml` | 10-11 | Add archive, flutter_markdown deps + legal assets |

### Dependencies Added
| Package | Version | Purpose |
|---------|---------|---------|
| `archive` | ^4.0.2 | Zip log files for support ticket attachment |
| `flutter_markdown` | ^0.7.6 | Render legal document markdown |

### Supabase Requirements (migration in Part 1 Phase 2.6)
- `support_tickets` table: id, user_id, subject, message, app_version, platform, log_file_path, created_at, status
- `user_consent_records` table: id, user_id, policy_type, policy_version, accepted_at, app_version
- `support-logs` Storage bucket with RLS policy (user can only upload to their own path)
- Sync for both tables is deferred — insert-only / upload-only (see Sub-phase 12.8)
