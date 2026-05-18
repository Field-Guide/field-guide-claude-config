# Sentry-Only Support Reporting TODO

## Goal
- [x] Make Sentry the only user-facing bug/support reporting path.
- [x] Remove the confusing two-button/two-UI Help & Support flow.
- [x] Preserve the current reporting options users need: subject, message, issue code prefill, attach diagnostics/logs, and receipt/report ID.
- [x] Send enough scrubbed diagnostics to Sentry/GitHub that field issues can be debugged without needing the exact device in hand.
- [x] Fully remove the legacy active `support_tickets` system after S21 verification, while preserving existing local rows in an archive migration and not deleting remote live data in this code change.

## 2026-05-12 Sentry Research Addendum
- [x] Verified payload decisions against official Sentry docs before finalizing event shape.
- [x] Sentry envelope ingestion currently allows 200 MiB decompressed envelopes, but event items are limited to 1 MiB.
- [x] Sentry attachment docs allow larger per-event diagnostic/log attachments: 20 MB compressed request and 100 MB uncompressed attachments per event, with SDK default `maxAttachmentSize` of 20 MiB.
- [x] Sentry tags must stay searchable and small: keys are limited to 32 characters and values to 200 characters/no newlines.
- [x] Sentry contexts are visible on events but not searchable; use tags for lookup fields.
- [x] Sentry contexts are point-in-time event metadata and are not a good place for large log history.
- [x] Attachment bytes are not protected by `beforeSend`, so app code must scrub diagnostics/log attachments before creating them.
- [x] Updated implementation direction: keep `support_diagnostics_v1` as a compact context/manifest, attach full scrubbed diagnostics/log tails as `support_diagnostics_v1.json`, and keep the GitHub issue useful through the captured message summary.

## UI And Reporting Flow
- [x] Update Help & Support to show one form and one primary submit button: `Send Report`.
- [x] Remove the `Open Bug Reporter` button.
- [x] Remove usage of `SentryFeedbackWidget` from Help & Support.
- [x] Keep the app-owned form as the single UI because it lets us attach structured diagnostics reliably.
- [x] Keep existing fields:
  - [x] subject/category
  - [x] message
  - [x] initial issue code/title/message prefill from sync dashboard
  - [x] diagnostic logs option
  - [x] success state with support report ID
- [x] Route every submission through `SentryFeedbackLauncher.captureProblemReport`.
- [x] Make the success text clear that the report went through Sentry and can be correlated by report ID.

## Diagnostics Payload
- [x] Add a production `SupportDiagnosticsCollector`.
- [x] Collector output is JSON-safe and scrubbed before Sentry capture.
- [x] Attach compact diagnostics under a versioned Sentry context: `support_diagnostics_v1`.
- [x] Include app/runtime facts:
  - [x] app version/build
  - [x] release/dist/environment when available
  - [x] platform, OS version, device model
  - [x] current route/screen if available
  - [x] local database schema version
  - [x] logger session/report timestamp
- [x] Include safe auth/user context:
  - [x] hashed reporter ref
  - [x] role
  - [x] membership/status
  - [x] company/project identifiers only as redacted or hashed values unless already intentionally public
- [x] Include sync diagnostics:
  - [x] pending count
  - [x] blocked count
  - [x] conflict count
  - [x] pending bucket breakdowns
  - [x] blocked bucket breakdowns
  - [x] last sync time/result
  - [x] last sync pushed/pulled/errors/RLS denial counts
  - [x] transport health
  - [x] sync lock and pulling flag state
- [x] Include repair diagnostics:
  - [x] repair catalog version
  - [x] applied repair count
  - [x] latest applied repair job ID/time
  - [x] failed repair count
  - [x] all failed repair job IDs
  - [x] all failed repair timestamps
  - [x] scrubbed failure errors for each failed job
- [x] Include local queue/debug clues:
  - [x] grouped blocked rows by table/bucket
  - [x] representative blocked entries with table, operation, retry count, and scrubbed error
  - [x] conflict summaries without raw sensitive payloads
- [x] Include recent logs:
  - [x] prioritize `errors.log`, `sync.log`, `database.log`, `auth.log`, `navigation.log`, and `ui.log`
  - [x] cap lines/bytes per category
  - [x] suppress or heavily cap lifecycle noise
  - [x] scrub every line before attaching
  - [x] include log category names so Sentry/GitHub evidence is readable

## Sentry Event Shape
- [x] Extend `captureProblemReport` to accept structured diagnostics.
- [x] Add searchable Sentry tags:
  - [x] `category=feedback`
  - [x] `support_report_id`
  - [x] `reporter_ref`
  - [x] `subject`
  - [x] `issue_code`
  - [x] `app_version`
  - [x] `schema_version`
  - [x] `blocked_count`
  - [x] `failed_repair_count`
  - [x] `latest_failed_repair_job`
- [x] Keep a compact diagnostic summary in the captured message so GitHub issues are useful even before opening Sentry.
- [x] Attach full diagnostics as a scrubbed Sentry attachment and attach only a compact manifest in contexts.
- [x] Ensure `beforeSendSentry` keeps support correlation fields but redacts sensitive IDs/secrets.
- [x] Do not create a direct GitHub issue path in the app; GitHub remains downstream of Sentry.

## Legacy `support_tickets` Decommission
- [x] Immediate fix:
  - [x] stop all user-facing creation paths for `support_tickets`
  - [x] remove active local schema, adapter registration, sync triggers, metadata, driver allowlist, lint allowlists, and active tests for `support_tickets`
  - [x] add tests proving Help & Support no longer writes local support tickets
- [x] User-requested full active-code removal after S21 verification:
  - [x] delete `SupportTicketAdapter`
  - [x] delete local `support_tables` schema helper
  - [x] remove `support_tickets` from active sync registration and trigger coverage
  - [x] remove fresh local DB creation of `support_tickets`
  - [x] add v65 local retirement migration that archives existing rows into `legacy_support_reports_archive`
  - [x] drop local `support_tickets` table, local triggers, local support cursor, and queued change-log residue during v65
  - [x] keep historical Supabase migrations/rollbacks only as applied migration history; do not add a direct app path back to the old table
- [x] Do not purge remote live project data or remote legacy support-ticket data in this immediate code change.

## Tests
- [x] Widget test: Help & Support shows one reporting button and no `Open Bug Reporter`.
- [x] Widget test: seeded sync issue still prefills issue code/title/message and logs option.
- [x] Widget test: submit calls Sentry capture exactly once.
- [x] Widget test: success state shows the support report ID.
- [x] Unit test: diagnostics collector includes all failed repair jobs, including an 8-failure fixture.
- [x] Unit test: diagnostics collector includes blocked/pending/conflict counts and bucket breakdowns.
- [x] Unit test: log collector reads prioritized category logs and avoids lifecycle flooding.
- [x] Unit test: PII filter redacts raw user/company/project IDs, email, tokens, JWTs, passwords, and API keys.
- [x] Unit test: Sentry tags include searchable counts and latest failed repair job.
- [x] Regression test: report payload remains JSON-safe when diagnostic values include dates, enums, exceptions, or non-serializable objects.
- [x] Regression test: v65 archives local legacy support rows and removes active local `support_tickets` table/triggers/cursors/change-log residue.

## S21 Verification Evidence
- [x] Verified on S21 device `RFCNC0Y975L` using the real Help & Support flow.
- [x] Verified final support report ID: `59fd8346-66b8-4bb9-8150-7fcad87b0f1d`.
- [x] Verified final Sentry event ID: `f57f11d7b5de480199bd32d29c13b8f1`.
- [x] Verified Sentry issue: `FLUTTER-1D`, group `7477020550`, `https://field-guide.sentry.io/issues/7477020550/`.
- [x] Verified Sentry created GitHub issue: `Field-Guide/construction-inspector-tracking-app#324`.
- [x] Verified payload stayed inside researched Sentry limits: event item `8508` bytes, diagnostics attachment manifest size `15400` bytes.
- [x] Verified Sentry event included `problem_report` and `support_diagnostics_v1` contexts, support correlation tags, app/runtime facts, schema version `65`, sync counts/buckets, repair counts, transport health, sync gate state, and prioritized log category summaries.
- [x] Verified GitHub issue body includes the support report ID, Sentry issue link, compact diagnostic summary, sync counts/buckets, log evidence, and diagnostics attachment size.
- [x] Verified local S21 DB after migration has `legacy_support_reports_archive`, four archived rows, and `user_version` `65`, with no active `support_tickets` table/triggers.
- [x] Evidence directory: `tools/testing/test-results/2026-05-12/s21-sentry-direct-envelope-final-20260512-164502/`.

## Acceptance Criteria
- [x] A field user has exactly one Help & Support reporting path.
- [x] A submitted report creates one Sentry event with a support report ID.
- [x] The Sentry event contains enough structured data to identify the same class of issue as the current S25 eight failed repair jobs.
- [x] GitHub issues created from Sentry contain a useful summary and link back to the detailed Sentry event.
- [x] No report payload leaks raw credentials or sensitive user data.
- [x] No live project data or remote legacy support-ticket data is deleted by this immediate code change.

## Verification Commands
- [x] `flutter analyze`
- [x] `flutter test test/core/config/sentry_feedback_launcher_test.dart test/core/config/sentry_pii_filter_test.dart test/features/settings/application/support_diagnostics_collector_test.dart test/features/settings/presentation/screens/help_support_screen_test.dart test/core/database/database_schema_metadata_test.dart test/core/database/late_migration_versions_test.dart test/core/database/migration_v65_support_tickets_retirement_test.dart --reporter expanded`
- [x] `dart run custom_lint` was run; remaining failures are unrelated pre-existing lint findings in form widgets/tests, not in the Sentry/support-ticket change set.

## Official Sources Used
- [x] Sentry envelopes: `https://develop.sentry.dev/sdk/foundations/transport/envelopes/`
- [x] Sentry event payloads: `https://develop.sentry.dev/sdk/data-model/event-payloads/`
- [x] Sentry contexts: `https://develop.sentry.dev/sdk/foundations/transport/event-payloads/contexts/`
- [x] Sentry Flutter attachments: `https://docs.sentry.io/platforms/dart/guides/flutter/enriching-events/attachments/`
- [x] Sentry event lookup API: `https://docs.sentry.io/api/organizations/resolve-an-event-id/`
- [x] Sentry issue alert rules API: `https://docs.sentry.io/api/alerts/list-a-projects-issue-alert-rules/`
- [x] Sentry integration issue links API: `https://docs.sentry.io/api/integration/retrieve-custom-integration-issue-links-for-the-given-sentry-issue/`
