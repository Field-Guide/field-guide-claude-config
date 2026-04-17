# Pattern — Logger + Sentry Transport

## How the repo does it

The `Logger` static class exposes one method per category (`sync`, `auth`, `pdf`, `db`, `ocr`, `nav`, `ui`, `photo`) and severity shortcuts (`error`, `warn`, `info`). Category calls write to per-category rotated log files plus a flat `app_session.log`. Errors additionally route through `LoggerErrorReporter` to the Sentry transport, which is consent-gated via `sentryConsentGranted` and PII-scrubbed via `beforeSendSentry`.

## Exemplars

- `lib/core/logging/logger.dart` — public API (`Logger.sync`, `Logger.auth`, `Logger.error`, etc.).
- `lib/core/logging/logger_sentry_transport.dart` — `LoggerSentryTransport.report(...)` delegates to `Sentry.captureException` / `Sentry.captureMessage`.
- `lib/core/config/sentry_pii_filter.dart` — `beforeSendSentry` scrubs exceptions, breadcrumbs, message, tags, extra; nulls `user`, `request`.
- `lib/main.dart` — `SentryFlutter.init` with `tracesSampleRate: 0.1`, session replay, privacy masking.

## Reusable surface

```dart
// Category logging (file + Sentry on error paths only)
Logger.sync('RealtimeHintHandler: subscribed to channel=$channelName');
Logger.sync('SyncEngine: pull started', data: {'mode': mode.name, 'scopeCount': n});
Logger.auth('AuthProvider: signed out', data: {'userId': userId, 'reason': reason});
Logger.error('PushHandler: unrecoverable failure', error: e, stack: stack);
```

## Extending for the five-layer filter (Phase 4)

The existing transport does not implement log-level filtering, sampling, dedup middleware, rate limiting, or breadcrumb budget. The extension shape the plan writer should follow is a **wrapper transport**, not a rewrite of `Logger`:

```dart
// lib/core/logging/logger_sentry_dedup_middleware.dart (new)
class LoggerSentryDedupMiddleware {
  LoggerSentryDedupMiddleware({
    required Duration fingerprintWindow,       // e.g., 60 seconds
    required int maxEventsPerUserPerDay,       // e.g., 50
    required int maxBreadcrumbsPerEvent,       // e.g., 30
  });

  /// Returns true if the event should be forwarded, false to drop.
  /// Records fingerprint hits, enforces rate limit, trims breadcrumbs.
  bool accept({
    required String fingerprint,               // e.g., 'sync.engine.error:${classifiedKind}'
    required String userId,
    required SentryLevel level,
  });
}
```

Then `LoggerSentryTransport.report` calls `middleware.accept(...)` before `Sentry.captureException`. Layers compose: log-level filter → sampling → dedup → rate limit → breadcrumb trim → PII scrub (existing) → Sentry.

## Ownership boundaries

- PII filter (`beforeSendSentry`) remains the last stop before Sentry. Do not move dedup or rate-limit logic into the filter — keep them separate, composable middlewares.
- Consent gate (`sentryConsentGranted`) is the top-level kill switch. All middlewares become no-ops when consent is not granted.
- `Logger` keeps a simple static API. Middleware plumbing lives in the transport layer, invisible to callers.
- Log file retention is 14 days (`_retentionDays`) with 50 MB size cap (`_maxLogSizeBytes`). Don't change these without a Scope update.
- `tracesSampleRate: 0.1` is transaction-level sampling. It is separate from the log-event sampling layer.

## Imports

```dart
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/core/config/sentry_runtime.dart'; // for consent/reporting flags
import 'package:sentry_flutter/sentry_flutter.dart';                     // only in transport files
```

## What the event-class audit should assert

For every method in the must-log set (defined in the new `log_event_classes.dart`), the audit script must confirm at least one `Logger.<category>` call whose message or `data` map references the event class constant. The audit writes a report listing gaps; CI fails on gap count > 0.
