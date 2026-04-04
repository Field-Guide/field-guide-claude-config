# Debug Server & Logs Reference

The debug server (port 3947) provides structured log collection and querying. It is the agent's primary observation tool — eyes into the app without screenshots.

Use the right endpoint for the job — **prefer the plain-text convenience endpoints** which require zero parsing.

## Quick Reference — Which Endpoint to Use

| Task | Endpoint | Output |
|------|----------|--------|
| **"Any errors since tier started?"** | `GET /logs/errors?since=<ISO>` | Plain text, deduplicated |
| **"Show me recent log activity"** | `GET /logs?format=text&last=20` | Plain text, formatted |
| **"Checkpoint stats for report"** | `GET /logs/summary?since=<ISO>` | JSON: `{total, errors, byLevel, byCategory}` |
| **"Sync logs only"** | `GET /logs?category=sync&format=text&since=<ISO>` | Plain text, filtered |
| **"Need structured data"** | `GET /logs?format=json&level=error` | JSON array (standard) |
| **"Raw streaming (30K entries)"** | `GET /logs?last=N` | NDJSON (default, legacy) |
| **"Is sync done?"** | `GET /sync/status` | JSON: `{state, ...}` |
| **"Server alive?"** | `GET /health` | JSON: `{status, entries, ...}` |

## /logs/errors (primary testing endpoint)

Returns error-level logs as pre-formatted, deduplicated plain text. **This is the main endpoint to use after every tier.**

```bash
# One curl, no parsing, done.
curl -s "http://127.0.0.1:3947/logs/errors?since=2026-04-03T10:00:00Z"
# Output:
# OK: 0 errors
# — or —
# ERRORS: 2 unique (5 total)
#   10:05:12 [sync  ] pullCompanyMembers failed: no such column: deleted_at
#   10:05:12 [app   ] SchemaVerifier: 1 missing columns detected
```

## /logs/summary (checkpoint reporting)

Returns counts by level and category. Useful for writing the stats line in `report.md`.

```bash
curl -s "http://127.0.0.1:3947/logs/summary?since=2026-04-03T10:00:00Z"
# {"total":47,"byLevel":{"info":44,"error":3},"byCategory":{"sync":20,"nav":15,"db":12},"errors":3,"since":"2026-04-03T10:00:00Z"}
```

## /logs?format=text (human-readable activity)

Returns all matching logs as formatted plain text lines. Good for debugging a specific flow.

```bash
curl -s "http://127.0.0.1:3947/logs?format=text&category=sync&last=10"
# 10:05:12 INFO  sync   Sync started
# 10:05:14 ERROR sync   pullCompanyMembers failed: no such column: deleted_at
# 10:05:15 INFO  sync   Sync cycle: pushed=0 pulled=0 errors=1
```

## /logs?format=json (structured data)

Returns a standard JSON array. Use when you need to programmatically inspect log entries.

```bash
curl -s "http://127.0.0.1:3947/logs?format=json&level=error&last=5"
# Standard JSON array — use json.load(sys.stdin) safely
```

## /logs (default — NDJSON)

Legacy format. Returns newline-delimited JSON. **Prefer `?format=text` or `?format=json` instead** — they avoid the python parsing boilerplate that NDJSON requires.

## Filter Parameters (apply to all /logs variants)

| Parameter | Type | Behavior |
|-----------|------|----------|
| `category` | string | Exact match: `sync`, `nav`, `db`, `auth`, `ui`, `pdf`, `ocr` |
| `level` | string | Exact match: `info`, `error`, `hypothesis` |
| `since` | ISO 8601 | Entries received after this timestamp |
| `last` | integer | Return only last N entries (applied after other filters) |
| `hypothesis` | string | Exact match on hypothesis tag (e.g., `H001`) |
| `deviceId` | string | Exact match on device ID |
| `format` | string | Output format: `text`, `json`, or omit for NDJSON |

## Hot Restart Log Delay

After `POST /driver/hot-restart`, the Logger HTTP transport takes 3-5 seconds to reconnect. **Do not assume the transport is broken if logs are empty immediately after restart.** Trigger a UI action (e.g., tap a nav button) and check for log entries before investigating further.
