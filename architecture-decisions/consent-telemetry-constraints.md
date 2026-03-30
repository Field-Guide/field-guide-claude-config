# Consent & Telemetry Constraints

## Hard Rules (Violations = Reject Proposal)

- MUST have active consent before sending ANY telemetry (crash reports or analytics)
- MUST NOT send Sentry crash reports without consent — `sentryConsentGranted` flag in `lib/core/config/sentry_consent.dart` gates all reports via `_beforeSendSentry` callback in `main.dart`
- MUST NOT send Aptabase analytics events without consent — `Analytics._enabled` flag in `lib/core/analytics/analytics.dart` gates all `track()` calls
- MUST gate app access behind consent — `AppRouter` checks `ConsentProvider` and redirects new users to consent screen before any protected route
- MUST immediately stop all telemetry when consent is revoked — `disableSentryReporting()` and `Analytics.disable()` called on revocation
- MUST apply PII scrubbing in release builds — `Logger._scrubString()` redacts emails and JWTs; `Logger._scrubSensitive()` redacts sensitive map keys (passwords, tokens, project names, etc.)
- MUST apply PII scrubbing to Sentry breadcrumbs — breadcrumbs can contain PII even when crash reports are consent-gated; use `Logger.scrubString()` in Sentry `beforeSend`/`beforeBreadcrumb` callbacks
- MUST apply PII filtering in `LogUploadRemoteDatasource` (`lib/features/settings/data/datasources/remote/log_upload_remote_datasource.dart`) before sending support logs to remote
- MUST NOT include PII in analytics event properties — only counts, durations, and enum values (enforced by `Analytics` class convention)

## Soft Guidelines (Violations = Discuss)

- Consent records should be validated server-side (not just trusted from client) to prevent forgery
- Aptabase cannot be un-initialized at runtime; disabling the `_enabled` flag is the current approach — acceptable but note the SDK remains loaded in memory
- Log scrubbing is best-effort, not exhaustive — log files should still be treated as potentially sensitive
- Data retention periods for collected telemetry follow the privacy policy (not hardcoded in app)

## Consent Flow

- `ConsentProvider` (`lib/features/settings/presentation/providers/consent_provider.dart`) manages consent state
- `ConsentScreen` (`lib/features/settings/presentation/screens/consent_screen.dart`) presents Terms of Service and Privacy Policy
- Router redirect logic in `AppRouter` (`lib/core/router/app_router.dart`) enforces the gate — no bypass path exists
- Consent is opt-in by default: no data is sent until the user explicitly accepts

## ConsentRecord Model

**File:** `lib/features/settings/data/models/consent_record.dart`

| Field | Type | Purpose |
|-------|------|---------|
| `id` | `String` (UUID) | Unique record identifier |
| `userId` | `String` | Owning user |
| `policyType` | `ConsentPolicyType` | `privacyPolicy` or `termsOfService` |
| `policyVersion` | `String` | Version of the policy accepted/revoked |
| `acceptedAt` | `DateTime` (UTC) | When consent action occurred |
| `appVersion` | `String` | App version at time of consent |
| `action` | `ConsentAction` | `accepted` or `revoked` |

**Design constraints:**
- Append-only table (`user_consent_records`) — no UPDATE or DELETE, only INSERT
- No `copyWith()` — records are immutable once created
- GDPR audit trail: both grants and withdrawals are recorded as separate rows
- Synced to Supabase via `ConsentRecordAdapter` (`lib/features/sync/adapters/consent_record_adapter.dart`)

## Sentry Integration

**File:** `lib/core/config/sentry_consent.dart`

- Private `_sentryConsentGranted` flag with controlled mutation via `enableSentryReporting()` / `disableSentryReporting()`
- Main-isolate only — background isolates do not share this state
- `_beforeSendSentry` callback in `main.dart` checks the flag and drops events when consent is not active
- `Logger.scrubString()` is exposed as a public accessor so Sentry `beforeSend` can apply the same PII rules as the logging system

## Aptabase Analytics Integration

**File:** `lib/core/analytics/analytics.dart`

- Singleton `Analytics` class with static `enable()` / `disable()` methods
- `track()` silently no-ops when `_enabled` is false
- Async errors from `trackEvent` are caught and logged (never crash the app)
- Initialized by `AppInitializer` only after consent is confirmed

## PII Scrubbing

**File:** `lib/core/logging/logger.dart`

- `_scrubString()`: Regex-based redaction of emails and JWT tokens from log strings
- `_scrubSensitive()`: Key-based redaction of sensitive map fields (passwords, tokens, user IDs, project names, etc.)
- Applied to both file and HTTP transports — scrubbed once, reused by all outputs
- Release builds apply scrubbing to all log levels
- Sentry error reports use `captureMessage` with pre-scrubbed strings (not raw `captureException`) to prevent PII reaching Sentry before `beforeSend` processing
