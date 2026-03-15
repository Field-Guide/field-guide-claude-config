# Log Investigation and Instrumentation

Reference for reading logs from the debug server and adding instrumentation during debugging sessions.

---

## Reading Logs: curl Commands

The debug server runs at `http://127.0.0.1:3947` when started via `node tools/debug-server/server.js`.

### Health check
```bash
curl http://127.0.0.1:3947/health
# Response: {"status":"ok","entries":42,"maxEntries":30000,"memoryMB":12,"uptimeSeconds":120}
```

### Fetch recent logs (all categories)
```bash
curl "http://127.0.0.1:3947/logs?last=20"
```

### Fetch by hypothesis tag
```bash
curl "http://127.0.0.1:3947/logs?hypothesis=H001&last=100"
curl "http://127.0.0.1:3947/logs?hypothesis=H002&last=50"
```

### Fetch by category
```bash
curl "http://127.0.0.1:3947/logs?category=sync&last=50"
curl "http://127.0.0.1:3947/logs?category=error&last=20"
curl "http://127.0.0.1:3947/logs?category=pdf&last=30"
curl "http://127.0.0.1:3947/logs?category=db&last=30"
```

### Combine filters
```bash
curl "http://127.0.0.1:3947/logs?category=sync&hypothesis=H001&last=20"
```

### List active categories
```bash
curl http://127.0.0.1:3947/categories
# Response: {"sync":47,"pdf":12,"error":3,"db":8,"lifecycle":2}
```

### Clear all logs (start of session)
```bash
curl -X POST http://127.0.0.1:3947/clear
```

---

## NDJSON Parsing

Server returns NDJSON (one JSON object per line). Each entry has:

```json
{"ts":"14:23:05.441","category":"sync","message":"SyncEngine.push","data":{"table":"entries","count":3},"hypothesis":"H001"}
```

Fields:
- `ts` — timestamp `HH:MM:SS.mmm`
- `category` — Logger category (see guide below)
- `message` — log message string
- `data` — optional map of key/value context
- `hypothesis` — hypothesis tag if set (omitted otherwise)

Reading the log sequence: look for where expected entries STOP appearing or where `data` values diverge from expected.

---

## Instrumentation Patterns

### Region markers (permanent coverage)

Use at significant entry/exit points in a code path. These stay after the debug session.

```dart
// Entry of a public method
Logger.sync('SyncEngine.push', data: {'table': tableName, 'pendingCount': count});

// Exit with result
Logger.sync('SyncEngine.push.complete', data: {'pushed': successCount, 'failed': failCount});
```

### Hypothesis markers (temporary, session-scoped)

Use to answer a specific question: "Does execution reach this point? With what data?"

```dart
Logger.hypothesis('H001', 'sync', 'SyncEngine.push entry', data: {
  'pendingCount': pendingChanges.length,
  'isAuthenticated': isAuthenticated,
});
```

Naming:
- Reset numbering each session: H001, H002, H003...
- Use the same tag for all markers in one hypothesis chain
- Use a new tag when investigating a different question

**ALL hypothesis markers MUST be removed in Phase 9 cleanup.**

### Permanent gap filling

If a code boundary has NO Logger call at all and this is the kind of important boundary that should always be logged (method entry, error handler, state change), add a permanent call:

```dart
// In a sync adapter
Logger.sync('${runtimeType}.toSupabaseMap', data: {'table': tableName});

// In error handler
Logger.error('AuthProvider._handleError', data: {'code': error.code});
```

These are NOT tagged with hypothesis IDs. They fill the coverage gap permanently.

---

## Category Guide

| Feature / Context | Logger Method | Category string |
|-------------------|---------------|-----------------|
| Sync flow | `Logger.sync()` | `sync` |
| PDF import/extraction | `Logger.pdf()` | `pdf` |
| Database / SQLite | `Logger.db()` | `db` |
| Navigation / routing | `Logger.nav()` | `nav` |
| Authentication | `Logger.auth()` | `auth` |
| Photos / images | `Logger.photo()` | `photo` |
| App lifecycle | `Logger.lifecycle()` | `lifecycle` |
| Errors / exceptions | `Logger.error()` | `error` |
| Background tasks | `Logger.bg()` | `bg` |
| UI / forms | `Logger.ui()` | `ui` |
| Hypothesis (temp) | `Logger.hypothesis()` | `hypothesis` |

---

## Auth Restrictions — Never Log These

The following must NEVER appear in any log call, including hypothesis markers:

- Auth tokens (JWT, refresh tokens, access tokens)
- Passwords or PINs
- Supabase service keys or anon keys
- API keys for any external service
- User PII beyond a truncated user ID (e.g., first 8 chars of UUID is OK)
- Email addresses in full form
- Phone numbers

**Safe alternatives:**
```dart
// WRONG
Logger.auth('login', data: {'token': jwtToken, 'email': user.email});

// CORRECT
Logger.auth('login', data: {'userId': userId.substring(0, 8), 'hasToken': jwtToken != null});
```

---

## Example Hypothesis Investigation Workflow

**Question**: "Why is sync not pushing entries after offline period?"

1. Add H001 at sync entry point:
   ```dart
   Logger.hypothesis('H001', 'sync', 'SyncOrchestrator.syncAll called', data: {
     'isOnline': isOnline,
     'pendingCount': pending,
   });
   ```

2. Add H002 at the decision branch:
   ```dart
   Logger.hypothesis('H002', 'sync', 'SyncEngine.push decision', data: {
     'shouldPush': shouldPush,
     'reason': reason,
   });
   ```

3. Reproduce. Fetch evidence:
   ```bash
   curl "http://127.0.0.1:3947/logs?hypothesis=H001&last=10"
   curl "http://127.0.0.1:3947/logs?hypothesis=H002&last=10"
   ```

4. Read result: H001 fires with `pendingCount=3`, H002 never fires.

5. Conclusion: `SyncEngine.push()` is not being called from `SyncOrchestrator.syncAll()`.

6. Root cause: check the condition guard between the two call sites.
