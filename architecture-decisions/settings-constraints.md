# Settings Constraints

**Feature**: App Settings, Consent, Support, Admin, Trash, Legal, Profile
**Scope**: All code in `lib/features/settings/` and user preference persistence

---

## Feature Scope

The settings feature is the app's configuration and account hub. It encompasses far more than theme/language preferences:

| Sub-feature | Key Components | Purpose |
|-------------|---------------|---------|
| **Theme & Preferences** | `ThemeProvider`, `ThemeSection` | Light/dark mode, language, notifications |
| **Consent** | `ConsentScreen`, `ConsentRecord`, `ConsentProvider`, `ConsentRepository` | ToS/privacy acceptance tracking with versioned records |
| **Support** | `HelpSupportScreen`, `SupportTicket`, `SupportProvider`, `SupportRepository` | Bug reports, help requests. `LogUploadRemoteDatasource` sends diagnostic logs to remote |
| **Admin** | `AdminDashboardScreen`, `AdminProvider`, `AdminRepository` | Role-based admin tools (personnel types, member management) |
| **Trash** | `TrashScreen`, `TrashRepository` | Soft-delete recovery (view and restore deleted items) |
| **Legal** | `LegalDocumentScreen` | Display ToS, privacy policy, and other legal documents |
| **OSS Licenses** | `OssLicensesScreen` | Third-party license attribution display |
| **Edit Profile** | `EditProfileScreen` | User profile editing (name, certifications) |
| **Sync Controls** | `SyncSection` widget | Manual sync trigger, sync status display |
| **Cache Management** | `ClearCacheDialog` | Clear local caches with confirmation |
| **Sign Out** | `SignOutDialog` | Sign-out flow with confirmation |

### Directory Layout

```
lib/features/settings/
├── data/
│   ├── datasources/
│   │   ├── consent_local_datasource.dart
│   │   ├── support_local_datasource.dart
│   │   ├── local/
│   │   │   └── user_certification_local_datasource.dart
│   │   └── remote/
│   │       └── log_upload_remote_datasource.dart    # Sends data remotely
│   ├── models/
│   │   ├── consent_record.dart
│   │   ├── support_ticket.dart
│   │   └── user_certification.dart
│   └── repositories/
│       ├── admin_repository_impl.dart
│       ├── consent_repository.dart
│       ├── support_repository.dart
│       └── trash_repository.dart
├── di/
│   ├── settings_providers.dart
│   └── consent_support_factory.dart
├── domain/
│   └── repositories/
│       └── admin_repository.dart
└── presentation/
    ├── providers/
    │   ├── admin_provider.dart
    │   ├── consent_provider.dart
    │   ├── support_provider.dart
    │   └── theme_provider.dart
    ├── screens/
    │   ├── settings_screen.dart          # Main settings hub
    │   ├── admin_dashboard_screen.dart
    │   ├── consent_screen.dart
    │   ├── edit_profile_screen.dart
    │   ├── help_support_screen.dart
    │   ├── legal_document_screen.dart
    │   ├── oss_licenses_screen.dart
    │   ├── personnel_types_screen.dart
    │   └── trash_screen.dart
    └── widgets/
        ├── clear_cache_dialog.dart
        ├── member_detail_sheet.dart
        ├── section_header.dart
        ├── sign_out_dialog.dart
        ├── sync_section.dart
        └── theme_section.dart
```

---

## Hard Rules (Violations = Reject)

### Theme/Preference Storage Is Local-Only
- Settings stored locally in SQLite + SharedPreferences only
- Supported preferences: theme (light/dark), language (en/es), notification_enabled (bool)
- No syncing user preferences to Supabase
- No storing sensitive data (passwords, tokens) in settings feature

**Why**: Settings are device-specific; each device has independent preferences.

### Consent Records Must Be Versioned and Immutable
- `ConsentRecord` tracks which version of ToS/privacy policy was accepted and when
- Consent records are insert-only (no updates or deletes)
- Consent must be obtained before the user can proceed past onboarding
- No bypassing consent checks regardless of user role

**Why**: Legal compliance requires an auditable trail of what the user agreed to and when.

### Support Ticket Log Uploads Are the Only Remote Data Path
- `LogUploadRemoteDatasource` is the only component in settings that sends data to a remote endpoint
- Support tickets and diagnostic logs sent remotely must not include user credentials or auth tokens
- All other settings data remains local

**Why**: Support needs diagnostic data for triage, but the remote surface must be minimal and scrubbed.

### Admin Access Is Role-Gated
- `AdminDashboardScreen` and `AdminProvider` must enforce role checks before rendering
- No privilege escalation paths (e.g., modifying own role via admin tools)
- `AdminRepository` queries must respect RLS policies on Supabase

**Why**: Security is non-negotiable. Admin tools manage personnel and project membership.

### Trash Restores Must Respect Ownership
- `TrashRepository` only surfaces items owned by the current user (or admin for team items)
- Restore operations must validate that the parent entity still exists (e.g., restoring an entry requires its project to exist)
- Hard-delete from trash is permanent and requires confirmation

**Why**: Prevents data leaks across users and avoids orphaned records on restore.

### No Remote Sync for Settings
- No settings sync orchestration in sync feature
- Settings remain local and independent across devices
- If user logs in on 2 devices, each has independent theme/notification settings

**Why**: Simplifies sync logic; users typically have device-specific preferences.

### Current Project Tracking
- Settings stores: current_project_id (which project user last viewed)
- Used on app boot to auto-select project
- Updated whenever user switches projects
- No persisting "project history" beyond current selection

**Why**: Session continuity; users expect app to remember last context.

---

## Soft Guidelines (Violations = Discuss)

### Performance Targets
- Load settings screen: < 100ms
- Update setting (theme change): < 100ms
- Consent check on boot: < 50ms
- Trash listing: < 200ms (may query multiple tables)
- No disk I/O blocking UI (use background task if needed)

### Storage Limits
- SharedPreferences: < 10 KB (theme, language, flags only)
- Consent records: Unbounded but small (one row per acceptance event)
- Support tickets: Stored locally until submitted, then may be pruned

### Test Coverage
- Target: >= 80% for preferences (simple CRUD)
- Target: >= 90% for consent (legal compliance path)
- Target: >= 80% for admin (role-gating validation)
- Scenarios: Theme toggle, consent acceptance, support ticket submission, trash restore, admin role check

---

## Integration Points

- **Depends on**:
  - `projects` (current_project_id, trash restore targets)
  - `auth` (user_id for per-user settings, role for admin gating, profile data for EditProfileScreen)
  - `sync` (SyncSection triggers sync, displays status)
  - `core/database` (SQLite tables for consent, support, trash)
  - `core/logging` (Logger provides diagnostic data for log uploads)

- **Required by**:
  - `auth` (offline mode preference, consent gate on onboarding)
  - `sync` (offline mode respected, sync controls)
  - `dashboard` (theme applied globally)
  - `core/router` (consent gate may redirect unapproved users)

---

## Testing Requirements

- Unit tests: CRUD operations, type safety (theme enum not string), consent version matching
- Unit tests: Admin role-gating logic (provider rejects non-admin users)
- Unit tests: Trash restore validation (parent exists, ownership check)
- Integration tests: Theme change propagates to all widgets
- Integration tests: Consent screen blocks navigation until accepted
- Integration tests: Support ticket submission with log upload
- Edge cases: Settings file corrupted (fallback to defaults), missing keys (use fallback values)
- Edge cases: Consent version mismatch (new ToS version requires re-acceptance)
- Edge cases: Trash restore when parent entity was also deleted

---

## Reference

- **Architecture**: `docs/features/feature-settings-architecture.md`
- **Shared Rules**: `architecture-decisions/data-validation-rules.md`
- **Consent/Support adapters**: Added in S677 (pre-release hardening)
