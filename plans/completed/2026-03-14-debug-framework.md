# Debug Framework Implementation Plan

> **For Claude:** Use the implement skill (`/implement`) to execute this plan.

**Goal:** Build a unified logging, HTTP log server, and debug skill framework
**Spec:** `.claude/specs/2026-03-14-debug-framework-spec.md`
**Analysis:** `.claude/dependency_graphs/2026-03-14-debug-framework/`

**Architecture:** Unified Logger replaces AppLogger + DebugLogger with file transport (always-on) and HTTP transport (debug sessions, compile-time gated). Node.js log server on localhost:3947 collects structured, hypothesis-tagged logs. Redesigned debug skill orchestrates log-first investigation.
**Tech Stack:** Dart/Flutter, Node.js, ADB, Claude Code skills
**Blast Radius:** 12 direct creates, 5 direct modifies, 24 dependent files, 1 test file, 2 cleanup deletes

---

## Phase 1: HTTP Log Server

> **Agent:** `general-purpose`
> **Files:** `tools/debug-server/server.js`, `tools/debug-server/README.md`
> **Dependencies:** None — fully independent

### Sub-phase 1.1: Create server.js

**Agent:** `general-purpose`

#### Step 1.1.1: Create `tools/debug-server/server.js`

**File:** `tools/debug-server/server.js` (CREATE, ~180 lines)

**WHY:** Zero-dependency Node.js server that collects structured logs from the Flutter app over HTTP. Binds to localhost only for security. Stores in memory with caps to prevent runaway growth.

```javascript
#!/usr/bin/env node
// Debug Log Server — collects structured logs from the Flutter app.
// Zero dependencies: uses only Node.js built-in `http` and `fs`.
//
// Usage:  node tools/debug-server/server.js [--port 3947]
// Endpoints:
//   POST /log        — append a log entry
//   POST /clear      — clear all entries
//   GET  /logs       — retrieve entries (filters: hypothesis, category, since, level, last, deviceId)
//   GET  /health     — server health check
//   GET  /categories — list distinct categories seen

'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');

// --- CLI args ---
const args = process.argv.slice(2);
let port = 3947;
const portIdx = args.indexOf('--port');
if (portIdx !== -1 && args[portIdx + 1]) {
  port = parseInt(args[portIdx + 1], 10);
  if (isNaN(port) || port < 1 || port > 65535) {
    console.error('Invalid port. Must be 1-65535.');
    process.exit(1);
  }
}

// --- In-memory storage ---
const MAX_ENTRIES = 30000;
const MAX_MEMORY_BYTES = 100 * 1024 * 1024; // 100 MB
let entries = [];
let currentMemoryEstimate = 0;
let nextId = 1;

function estimateSize(entry) {
  return JSON.stringify(entry).length * 2; // rough char-to-byte estimate
}

function addEntry(entry) {
  // Server-side enrichment
  entry.id = nextId++;
  entry.receivedAt = new Date().toISOString();

  const size = estimateSize(entry);

  // Evict oldest if over caps
  while (
    (entries.length >= MAX_ENTRIES || currentMemoryEstimate + size > MAX_MEMORY_BYTES) &&
    entries.length > 0
  ) {
    const removed = entries.shift();
    currentMemoryEstimate -= estimateSize(removed);
  }

  entries.push(entry);
  currentMemoryEstimate += size;
}

function clearEntries() {
  entries = [];
  currentMemoryEstimate = 0;
  // Don't reset nextId — keeps IDs monotonic across clears
}

// --- Request helpers ---
function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => resolve(Buffer.concat(chunks).toString()));
    req.on('error', reject);
  });
}

function sendJson(res, statusCode, data) {
  const body = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function sendNdjson(res, items) {
  res.writeHead(200, { 'Content-Type': 'application/x-ndjson' });
  for (const item of items) {
    res.write(JSON.stringify(item) + '\n');
  }
  res.end();
}

// --- Route handlers ---
async function handlePostLog(req, res) {
  try {
    const body = await readBody(req);
    const entry = JSON.parse(body);
    addEntry(entry);
    sendJson(res, 200, { ok: true, id: entry.id });
  } catch (e) {
    sendJson(res, 400, { error: 'Invalid JSON', detail: e.message });
  }
}

function handlePostClear(_req, res) {
  clearEntries();
  sendJson(res, 200, { ok: true, cleared: true });
}

function handleGetLogs(req, res) {
  const url = new URL(req.url, `http://127.0.0.1:${port}`);
  const params = url.searchParams;

  let results = entries;

  // Filter: hypothesis
  const hypothesis = params.get('hypothesis');
  if (hypothesis) {
    results = results.filter((e) => e.hypothesis === hypothesis);
  }

  // Filter: category
  const category = params.get('category');
  if (category) {
    results = results.filter((e) => e.category === category);
  }

  // Filter: level
  const level = params.get('level');
  if (level) {
    results = results.filter((e) => e.level === level);
  }

  // Filter: deviceId
  const deviceId = params.get('deviceId');
  if (deviceId) {
    results = results.filter((e) => e.deviceId === deviceId);
  }

  // Filter: since (ISO timestamp)
  const since = params.get('since');
  if (since) {
    const sinceDate = new Date(since);
    results = results.filter((e) => new Date(e.receivedAt) >= sinceDate);
  }

  // Filter: last N entries
  const last = params.get('last');
  if (last) {
    const n = parseInt(last, 10);
    if (!isNaN(n) && n > 0) {
      results = results.slice(-n);
    }
  }

  sendNdjson(res, results);
}

function handleGetHealth(_req, res) {
  const memUsage = process.memoryUsage();
  sendJson(res, 200, {
    status: 'ok',
    entries: entries.length,
    maxEntries: MAX_ENTRIES,
    memoryMB: Math.round(memUsage.heapUsed / 1024 / 1024),
    uptimeSeconds: Math.round(process.uptime()),
  });
}

function handleGetCategories(_req, res) {
  // FROM SPEC: Must return category-to-count map, e.g. {"sync":47,"pdf":12}
  const counts = {};
  entries.forEach((e) => {
    if (e.category) counts[e.category] = (counts[e.category] || 0) + 1;
  });
  sendJson(res, 200, counts);
}

// --- Server ---
const server = http.createServer(async (req, res) => {
  // CORS headers for local dev
  // NOTE: No CORS wildcard — server is accessed via curl only, not browsers.
  // Omitting Access-Control-Allow-Origin prevents browser-based exfiltration.
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const url = new URL(req.url, `http://127.0.0.1:${port}`);
  const pathname = url.pathname;

  try {
    if (req.method === 'POST' && pathname === '/log') {
      await handlePostLog(req, res);
    } else if (req.method === 'POST' && pathname === '/clear') {
      await handlePostClear(req, res);
    } else if (req.method === 'GET' && pathname === '/logs') {
      handleGetLogs(req, res);
    } else if (req.method === 'GET' && pathname === '/health') {
      handleGetHealth(req, res);
    } else if (req.method === 'GET' && pathname === '/categories') {
      handleGetCategories(req, res);
    } else {
      sendJson(res, 404, { error: 'Not found' });
    }
  } catch (e) {
    sendJson(res, 500, { error: 'Internal error', detail: e.message });
  }
});

// --- SIGINT/SIGTERM handler: dump to last-session.ndjson ---
function gracefulShutdown() {
  console.log('\n[debug-server] Shutting down...');
  if (entries.length > 0) {
    const dumpPath = path.join(__dirname, 'last-session.ndjson');
    const lines = entries.map((e) => JSON.stringify(e)).join('\n') + '\n';
    try {
      fs.writeFileSync(dumpPath, lines);
      console.log(`[debug-server] Dumped ${entries.length} entries to ${dumpPath}`);
    } catch (e) {
      console.error(`[debug-server] Failed to dump session: ${e.message}`);
    }
  }
  process.exit(0);
}
process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);

// --- Startup ---
server.listen(port, '127.0.0.1', () => {
  console.log('');
  console.log('========================================');
  console.log('  Field Guide Debug Log Server');
  console.log(`  Listening on http://127.0.0.1:${port}`);
  console.log('  Bound to localhost ONLY (not exposed)');
  console.log('  Max entries: ' + MAX_ENTRIES);
  console.log('  Max memory:  100 MB');
  console.log('========================================');
  console.log('');
  console.log('Endpoints:');
  console.log('  POST /log        Send a log entry');
  console.log('  POST /clear      Clear all entries');
  console.log('  GET  /logs       Retrieve logs (filters: hypothesis, category, since, level, last, deviceId)');
  console.log('  GET  /health     Server health');
  console.log('  GET  /categories List categories');
  console.log('');
  console.log('Waiting for logs...');
});
```

#### Step 1.1.2: Create `tools/debug-server/README.md`

**File:** `tools/debug-server/README.md` (CREATE)

**WHY:** Quick-start instructions for developers using the debug server.

```markdown
# Debug Log Server

Zero-dependency Node.js server that collects structured logs from the Field Guide app during debug sessions.

## Quick Start

```bash
node tools/debug-server/server.js
```

Custom port:
```bash
node tools/debug-server/server.js --port 4000
```

## Connecting the App

Launch the Flutter app with the DEBUG_SERVER flag:

```powershell
pwsh -Command "flutter run -d windows --dart-define=DEBUG_SERVER=true"
```

Or for Android (with ADB port forwarding):

```bash
adb reverse tcp:3947 tcp:3947
pwsh -Command "flutter run -d <device-id> --dart-define=DEBUG_SERVER=true"
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | /log | Send a log entry (JSON body) |
| POST | /clear | Clear all stored entries |
| GET | /logs | Retrieve logs (NDJSON). Filters: `hypothesis`, `category`, `since`, `level`, `last`, `deviceId` |
| GET | /health | Server health (entry count, memory) |
| GET | /categories | List distinct categories seen |

## Examples

```bash
# Check health
curl http://127.0.0.1:3947/health

# Get last 50 sync logs
curl "http://127.0.0.1:3947/logs?category=sync&last=50"

# Get logs for a hypothesis
curl "http://127.0.0.1:3947/logs?hypothesis=H001"

# Clear all logs
curl -X POST http://127.0.0.1:3947/clear
```

## Session Dump

When stopped with Ctrl+C, the server writes all entries to `last-session.ndjson` in this directory.

## Security

- Binds to `127.0.0.1` only (not exposed to network)
- DEBUG_SERVER flag is compile-time gated and blocked in release builds
- Sensitive fields are scrubbed client-side before transmission
```

#### Step 1.1.3: Verify server starts and responds

**Verification:**
```bash
# Start server in background, test health, stop it
node tools/debug-server/server.js &
sleep 1
curl -s http://127.0.0.1:3947/health
# Expected: {"status":"ok","entries":0,...}
curl -s -X POST -H "Content-Type: application/json" -d '{"category":"test","message":"hello"}' http://127.0.0.1:3947/log
# Expected: {"ok":true,"id":1}
curl -s "http://127.0.0.1:3947/logs?last=1"
# Expected: NDJSON with the test entry
kill %1
```

---

## Phase 2: Unified Logger

> **Agent:** `general-purpose`
> **Files:** `lib/core/logging/logger.dart` (CREATE), `lib/core/config/test_mode_config.dart` (MODIFY)
> **Dependencies:** Phase 1 server must exist for HTTP transport testing, but code can be written independently

### Sub-phase 2.1: Add DEBUG_SERVER flag to TestModeConfig

**Agent:** `general-purpose`

#### Step 2.1.1: Add `debugServerEnabled` const to `test_mode_config.dart`

**File:** `lib/core/config/test_mode_config.dart` (MODIFY)
**Location:** After line 103 (after `useMockData` const), before `logStatus()` method at line 106

**WHY:** Centralizes all compile-time flags in one place. The Logger reads this to decide whether to activate the HTTP transport.

**Insert after line 103** (`);` closing `useMockData`):
```dart

  /// Whether the debug HTTP log server transport is enabled.
  ///
  /// When enabled, the Logger sends structured logs to a local Node.js server
  /// at http://127.0.0.1:3947 for real-time inspection during debug sessions.
  ///
  /// SECURITY: Blocked in release builds by tools/build.ps1.
  /// Launch with: --dart-define=DEBUG_SERVER=true
  static const bool debugServerEnabled = bool.fromEnvironment(
    'DEBUG_SERVER',
    defaultValue: false,
  );
```

**Also update `logStatus()`** — add after line 121 (`}` closing `useMockData` check), before closing `}` at line 123:
```dart
      if (debugServerEnabled) {
        debugPrint('[TEST_MODE] Debug HTTP log server transport enabled');
      }
```

**Verification:**
```
pwsh -Command "flutter analyze lib/core/config/test_mode_config.dart"
```

### Sub-phase 2.2: Create the Unified Logger

**Agent:** `general-purpose`

#### Step 2.2.1: Create `lib/core/logging/logger.dart`

**File:** `lib/core/logging/logger.dart` (CREATE, ~350 lines)

**WHY:** Replaces both AppLogger (316 lines) and DebugLogger (287 lines) with a single class that manages both file transport (always-on) and HTTP transport (debug sessions only, compile-time gated). Preserves identical file output format for backward compatibility.

**FROM SPEC:** Logger API with category methods, error method, hypothesis method, init/close/writeReport/isEnabled. File transport matches DebugLogger output format. HTTP transport behind DEBUG_SERVER flag with sensitive data scrubbing and 4KB truncation.

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:construction_inspector/core/config/test_mode_config.dart';

/// Whether file logging is enabled (compile-time flag, default true).
const bool _kFileLoggingEnabled = bool.fromEnvironment(
  'APP_FILE_LOGGING',
  defaultValue: true,
);

/// Unified logger replacing AppLogger and DebugLogger.
///
/// Two transports:
/// 1. **File transport** (always-on): session folder with per-category log files
///    + flat app log file. Matches legacy DebugLogger + AppLogger output exactly.
/// 2. **HTTP transport** (debug sessions only): sends structured JSON to the
///    debug log server at http://127.0.0.1:3947. Compile-time gated via
///    `--dart-define=DEBUG_SERVER=true`. Blocked in release builds.
class Logger {
  // -- Compile-time gate for HTTP transport --
  static const _httpEnabled = bool.fromEnvironment('DEBUG_SERVER');

  // -- State --
  static bool _initialized = false;
  static bool _initializing = false;

  // File transport: session folder (DebugLogger-style)
  static String? _sessionDir;
  static DateTime? _sessionStartTime;
  static final Map<String, IOSink> _categorySinks = {};

  // File transport: flat app log (AppLogger-style)
  static IOSink? _appLogSink;
  static File? _appLogFile;
  static String? _appLogDirPath;
  static Future<void> _writeQueue = Future.value();

  // debugPrint hook
  static DebugPrintCallback? _originalDebugPrint;
  static AppLifecycleLogger? _lifecycleLogger;
  static bool _logWriteFailed = false;

  // HTTP transport
  static HttpClient? _httpClient;

  // Build metadata
  static const String _buildSha =
      String.fromEnvironment('BUILD_SHA', defaultValue: 'unknown');
  static const String _buildBranch =
      String.fromEnvironment('BUILD_BRANCH', defaultValue: 'unknown');
  static const String _buildTime =
      String.fromEnvironment('BUILD_TIME', defaultValue: 'unknown');

  // Category log file names (match DebugLogger exactly)
  static const String _appSessionLog = 'app_session.log';
  static const String _ocrLog = 'ocr.log';
  static const String _pdfImportLog = 'pdf_import.log';
  static const String _syncLog = 'sync.log';
  static const String _databaseLog = 'database.log';
  static const String _authLog = 'auth.log';
  static const String _navigationLog = 'navigation.log';
  static const String _errorLog = 'errors.log';
  static const String _uiLog = 'ui.log';

  // Sensitive data blocklist for HTTP transport
  static const _sensitiveKeys = {
    'access_token', 'refresh_token', 'token', 'jwt', 'password', 'secret',
    'api_key', 'apiKey', 'anon_key', 'anonKey', 'service_role_key',
    'email', 'phone', 'cert_number', 'inspector_name', 'inspector_initials',
  };

  static const int _maxHttpDataBytes = 4096;

  // ======================== PUBLIC API ========================

  /// Whether file logging is enabled.
  static bool get isEnabled => _kFileLoggingEnabled;

  /// Whether the logger has been initialized.
  static bool get isInitialized => _initialized;

  /// Current session directory path (DebugLogger-style).
  static String? get sessionDirectory => _sessionDir;

  /// App log directory path (AppLogger-style).
  static String? get logDirectoryPath => _appLogDirPath;

  /// App log file path.
  static String? get logFilePath => _appLogFile?.path;

  // -- Category methods --

  static void sync(String msg, {Map<String, dynamic>? data}) {
    _log('SYNC', 'sync', msg, _syncLog, data: data);
  }

  static void pdf(String msg, {Map<String, dynamic>? data}) {
    _log('PDF', 'pdf', msg, _pdfImportLog, data: data);
  }

  static void db(String msg, {Map<String, dynamic>? data}) {
    _log('DB', 'db', msg, _databaseLog, data: data);
  }

  static void auth(String msg, {Map<String, dynamic>? data}) {
    _log('AUTH', 'auth', msg, _authLog, data: data);
  }

  static void ocr(String msg, {Map<String, dynamic>? data}) {
    _log('OCR', 'ocr', msg, _ocrLog, data: data);
  }

  static void nav(String msg, {Map<String, dynamic>? data}) {
    _log('NAV', 'nav', msg, _navigationLog, data: data);
  }

  static void ui(String msg, {Map<String, dynamic>? data}) {
    _log('UI', 'ui', msg, _uiLog, data: data);
  }

  /// Log an error. Default category 'app' for backward compat with AppLogger.
  static void error(String msg, {
    Object? error,
    StackTrace? stack,
    String category = 'app',
    Map<String, dynamic>? data,
  }) {
    final timestamp = _formatTimestamp(DateTime.now());
    final logLine = '[$timestamp] [ERROR] $msg';

    // Use Zone.root to avoid circular debugPrint hook
    if (_originalDebugPrint != null) {
      Zone.root.run(() {
        _originalDebugPrint?.call(logLine);
        if (error != null) _originalDebugPrint?.call('  Error: $error');
        if (stack != null) _originalDebugPrint?.call('  Stack: $stack');
      });
    } else {
      Zone.root.print(logLine);
      if (error != null) Zone.root.print('  Error: $error');
      if (stack != null) Zone.root.print('  Stack: $stack');
    }

    if (!_initialized) return;

    final lines = <String>[logLine];
    if (error != null) lines.add('  Error: $error');
    if (stack != null) {
      lines.add('  Stack trace:');
      lines.addAll(stack.toString().split('\n').map((l) => '    $l'));
    }
    lines.add('');

    _writeToSink(_errorLog, lines);

    // HTTP transport
    if (_httpEnabled) {
      final payload = <String, dynamic>{
        'category': category,
        'level': 'error',
        'message': msg,
      };
      if (error != null) payload['error'] = error.toString();
      if (stack != null) payload['stack'] = stack.toString();
      if (data != null) payload['data'] = data;
      _sendHttp(payload);
    }
  }

  /// Debug session only — HTTP transport only, compiles out in production.
  ///
  /// Used to tag log entries with a hypothesis ID for filtering in the debug server.
  static void hypothesis(String id, String category, String msg, {
    Map<String, dynamic>? data,
  }) {
    if (!_httpEnabled) return; // NOTE: compiles to no-op when DEBUG_SERVER is false

    assert(!kReleaseMode, 'hypothesis() must not be called in release mode');

    final payload = <String, dynamic>{
      'hypothesis': id,
      'category': category,
      'level': 'hypothesis',
      'message': msg,
      'timestamp': DateTime.now().toIso8601String(),
    };
    if (data != null) payload['data'] = data;
    _sendHttp(payload);
  }

  // -- Lifecycle --

  /// Initialize both transports. Call once at app startup.
  ///
  /// [baseDir] overrides the app log directory (for testing).
  static Future<void> init({Directory? baseDir}) async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      // --- File transport: session folder (DebugLogger-style) ---
      _sessionStartTime = DateTime.now();
      final docDir = await _getBaseDirectory();
      final sessionName =
          'session_${_formatTimestampForFolder(_sessionStartTime!)}';
      _sessionDir = path.join(
        docDir,
        'Troubleshooting',
        'Detailed App Wide Logs',
        sessionName,
      );

      final sessionFolder = Directory(_sessionDir!);
      if (!await sessionFolder.exists()) {
        await sessionFolder.create(recursive: true);
      }

      // Open category sinks
      for (final logFile in [
        _appSessionLog, _ocrLog, _pdfImportLog, _syncLog,
        _databaseLog, _authLog, _navigationLog, _errorLog, _uiLog,
      ]) {
        final file = File(path.join(_sessionDir!, logFile));
        _categorySinks[logFile] = file.openWrite(mode: FileMode.append);
      }

      // Write session header
      final headerSink = _categorySinks[_appSessionLog];
      if (headerSink != null) {
        final headerLines = [
          '=== Field Guide App Debug Session ===',
          'Session started: ${_sessionStartTime!.toIso8601String()}',
          'Session folder: $_sessionDir',
          'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
          'Dart version: ${Platform.version}',
          'Build SHA: $_buildSha',
          'Build Branch: $_buildBranch',
          'Build Time: $_buildTime',
          'CPU cores: ${Platform.numberOfProcessors}',
          '=====================================',
          '',
        ];
        for (final line in headerLines) {
          headerSink.writeln(line);
        }
        await headerSink.flush();
      }

      // --- File transport: flat app log (AppLogger-style) ---
      if (_kFileLoggingEnabled) {
        final rootDir = baseDir ?? await _getDefaultAppLogDir();
        final logDir = baseDir == null
            ? Directory(path.join(rootDir.path, 'field_guide_logs'))
            : rootDir;
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }
        _appLogDirPath = logDir.path;
        final ts = _timestampForFile();
        _appLogFile = File(path.join(logDir.path, 'app_log_$ts.txt'));
        _appLogSink = _appLogFile!.openWrite(mode: FileMode.append);
        _installDebugPrintHook();
        await _writeAppLogHeader();
      }

      // --- HTTP transport ---
      if (_httpEnabled) {
        assert(!kReleaseMode, 'DEBUG_SERVER must not be enabled in release builds');
        _httpClient = HttpClient();
      }

      _initialized = true;
      debugPrint('[Logger] Initialized. Session: $_sessionDir');
    } catch (e, stack) {
      debugPrint('[Logger] Initialization failed: $e');
      debugPrint('[Logger] Stack: $stack');
      // Fallback: try app log only
      _tryAppLogFallback();
    } finally {
      _initializing = false;
    }
  }

  /// Close all sinks and the HTTP client.
  static Future<void> close() async {
    // Close category sinks
    for (final sink in _categorySinks.values) {
      try {
        await sink.flush();
        await sink.close();
      } catch (e) {
        debugPrint('[Logger] Error closing category sink: $e');
      }
    }
    _categorySinks.clear();

    // Close app log sink
    try {
      await _appLogSink?.flush();
      await _appLogSink?.close();
    } catch (e) {
      debugPrint('[Logger] Error closing app log sink: $e');
    }
    _appLogSink = null;

    // Close HTTP client
    _httpClient?.close(force: true);
    _httpClient = null;

    _initialized = false;
  }

  /// Write a structured JSON report to the log directory.
  /// Backward-compatible with AppLogger.writeJsonReport().
  static Future<String?> writeReport({
    required String prefix,
    required Map<String, dynamic> data,
  }) async {
    if (!_kFileLoggingEnabled) return null;
    if (!_initialized) await init();

    final dirPath = _appLogDirPath;
    if (dirPath == null) return null;

    final ts = _timestampForFile();
    final file = File(path.join(dirPath, '${prefix}_$ts.json'));
    final payload = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(payload);
    _logToAppSink('Wrote report: ${file.path}', level: 'INFO');
    return file.path;
  }

  /// Log a message to the flat app log file.
  /// Backward-compatible with AppLogger.log().
  static void log(
    String message, {
    String level = 'INFO',
    Object? error,
    StackTrace? stack,
  }) {
    if (!_kFileLoggingEnabled) return;
    _logToAppSink(message, level: level, error: error, stack: stack);
  }

  /// Attach global error handlers.
  static void installErrorHandlers() {
    if (!_kFileLoggingEnabled) return;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      log(
        'FlutterError: ${details.exceptionAsString()}',
        level: 'ERROR',
        error: details.exception,
        stack: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (e, s) {
      log('Platform error: $e', level: 'ERROR', error: e, stack: s);
      return true;
    };
  }

  /// Zone specification for capturing print statements.
  static ZoneSpecification zoneSpec() {
    if (!_kFileLoggingEnabled) return const ZoneSpecification();
    return ZoneSpecification(
      print: (self, parent, zone, line) {
        log(line, level: 'PRINT');
        parent.print(zone, line);
      },
    );
  }

  /// Install lifecycle observer.
  static void installLifecycleLogger() {
    if (!_kFileLoggingEnabled) return;
    _lifecycleLogger ??= AppLifecycleLogger();
    WidgetsBinding.instance.addObserver(_lifecycleLogger!);
  }

  // ======================== PRIVATE ========================

  /// Core log method for category-based logging.
  static void _log(
    String categoryTag,
    String httpCategory,
    String message,
    String logFile, {
    Map<String, dynamic>? data,
  }) {
    final timestamp = _formatTimestamp(DateTime.now());
    String dataStr = '';
    if (data != null && data.isNotEmpty) {
      try {
        final safeData = _makeJsonSafe(data);
        dataStr = ' ${jsonEncode(safeData)}';
      } catch (e) {
        dataStr =
            ' {error: "JSON encoding failed: $e", rawData: "${data.toString()}"}';
      }
    }
    final logLine = '[$categoryTag] [$timestamp] $message$dataStr';

    // Console — use Zone.root.print to avoid circular call through debugPrint hook
    // IMPORTANT: debugPrint is hooked by _installDebugPrintHook() which writes to
    // the app log sink. Calling debugPrint here would create double-writes or recursion.
    if (_originalDebugPrint != null) {
      Zone.root.run(() => _originalDebugPrint?.call(logLine));
    } else {
      Zone.root.print(logLine);
    }

    // File transport
    if (_initialized) {
      _writeToSinkSync(logFile, logLine);
    }

    // HTTP transport
    if (_httpEnabled) {
      final payload = <String, dynamic>{
        'category': httpCategory,
        'level': 'info',
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };
      if (data != null) payload['data'] = data;
      _sendHttp(payload);
    }
  }

  // --- File transport helpers ---

  static void _writeToSinkSync(String filename, String line) {
    final sink = _categorySinks[filename];
    if (sink == null) return;
    try {
      sink.writeln(line);
    } catch (e) {
      debugPrint('[Logger] Failed to write to $filename: $e');
    }
  }

  static Future<void> _writeToSink(String filename, List<String> lines) async {
    final sink = _categorySinks[filename];
    if (sink == null) return;
    try {
      for (final line in lines) {
        sink.writeln(line);
      }
      await sink.flush();
    } catch (e) {
      debugPrint('[Logger] Failed to write to $filename: $e');
    }
  }

  static void _logToAppSink(String message, {
    String level = 'INFO',
    Object? error,
    StackTrace? stack,
  }) {
    if (!_initialized && !_logWriteFailed) {
      _tryAppLogFallback();
    }
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp][$level] $message';
    final lines = <String>[logLine];
    if (error != null) lines.add('[$timestamp][$level] error: $error');
    if (stack != null) lines.add('[$timestamp][$level] stack: $stack');
    _enqueueAppLogWrite(lines, onErrorMessage: logLine);
  }

  static Future<void> _enqueueAppLogWrite(
    List<String> lines, {
    required String onErrorMessage,
  }) {
    _writeQueue = _writeQueue.catchError((_) {}).then((_) async {
      try {
        for (final line in lines) {
          _appLogSink?.writeln(line);
        }
        await _appLogSink?.flush();
      } catch (e) {
        _handleAppLogFailure(e, onErrorMessage);
      }
    });
    return _writeQueue;
  }

  static void _handleAppLogFailure(Object? e, String message) {
    if (_logWriteFailed) return;
    _logWriteFailed = true;
    try {
      _appLogSink = null;
      Zone.root.print('Logger app log failed: $e');
      Zone.root.print('Logger dropped log: $message');
    } finally {
      _logWriteFailed = false;
    }
  }

  static Future<void> _writeAppLogHeader() async {
    final timestamp = DateTime.now().toIso8601String();
    await _enqueueAppLogWrite(
      [
        '=== Field Guide App Log ===',
        'Started: $timestamp',
        'Log file: ${_appLogFile?.path ?? 'unknown'}',
        'OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'Dart: ${Platform.version}',
        'CPU: ${Platform.numberOfProcessors}',
        'Memory: rss=${ProcessInfo.currentRss} maxRss=${ProcessInfo.maxRss}',
        '===========================',
      ],
      onErrorMessage: 'log header',
    );
  }

  static void _installDebugPrintHook() {
    if (_originalDebugPrint != null) return;
    _originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        try {
          _logToAppSink(message, level: 'DEBUG');
        } catch (_) {
          _handleAppLogFailure(null, message);
        }
      }
      if (_originalDebugPrint != null) {
        Zone.root.run(() {
          _originalDebugPrint?.call(message, wrapWidth: wrapWidth);
        });
      }
    };
  }

  static void _tryAppLogFallback() {
    if (_appLogSink != null) return;
    try {
      final logDir = Directory(
        path.join(Directory.systemTemp.path, 'field_guide_logs'),
      );
      if (!logDir.existsSync()) logDir.createSync(recursive: true);
      _appLogDirPath = logDir.path;
      final ts = _timestampForFile();
      _appLogFile = File(path.join(logDir.path, 'app_log_$ts.txt'));
      _appLogSink = _appLogFile!.openWrite(mode: FileMode.append);
      _initialized = true;
      _installDebugPrintHook();
      unawaited(_writeAppLogHeader());
    } catch (_) {
      // Give up silently
    }
  }

  // --- HTTP transport helpers ---

  static void _sendHttp(Map<String, dynamic> payload) {
    if (!_httpEnabled || _httpClient == null) return;
    // FROM SPEC: defense-in-depth — catch any build misconfiguration
    assert(!kReleaseMode, 'DEBUG_SERVER must not be enabled in release builds');

    // Add deviceId
    try {
      payload['deviceId'] = Platform.localHostname;
    } catch (_) {
      payload['deviceId'] = 'unknown';
    }

    // Scrub sensitive data
    if (payload.containsKey('data') && payload['data'] is Map) {
      payload['data'] = _scrubSensitive(
        Map<String, dynamic>.from(payload['data'] as Map),
      );
    }

    // Truncate data to 4KB
    if (payload.containsKey('data')) {
      final dataJson = jsonEncode(payload['data']);
      if (dataJson.length > _maxHttpDataBytes) {
        final keys = payload['data'] is Map
            ? (payload['data'] as Map).keys.toList()
            : <String>[];
        payload['data'] = {
          '_truncated': true,
          '_size': dataJson.length,
          '_keys': keys,
        };
      }
    }

    // Fire-and-forget POST
    unawaited(_postLog(payload));
  }

  static Future<void> _postLog(Map<String, dynamic> payload) async {
    try {
      final request = await _httpClient!
          .postUrl(Uri.parse('http://127.0.0.1:3947/log'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      await response.drain<void>();
    } catch (_) {
      // Swallow — server may not be running, fire-and-forget
    }
  }

  static Map<String, dynamic> _scrubSensitive(Map<String, dynamic> data) {
    return data.map((key, value) {
      // FROM SPEC: case-insensitive matching via k.toLowerCase()
      if (_sensitiveKeys.contains(key.toLowerCase())) {
        return MapEntry(key, '[REDACTED]');
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _scrubSensitive(value));
      } else if (value is Map) {
        return MapEntry(
          key,
          _scrubSensitive(Map<String, dynamic>.from(value)),
        );
      }
      return MapEntry(key, value);
    });
  }

  // --- JSON safety ---

  static Map<String, dynamic> _makeJsonSafe(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Enum) {
        return MapEntry(key, value.name);
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _makeJsonSafe(value));
      } else if (value is List) {
        return MapEntry(
            key, value.map((e) => e is Enum ? e.name : e).toList());
      }
      return MapEntry(key, value);
    });
  }

  // --- Formatting ---

  static String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$hour:$minute:$second.$ms';
  }

  static String _formatTimestampForFolder(DateTime dt) {
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$year-$month-${day}_$hour-$minute-$second';
  }

  static String _timestampForFile() {
    return DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
  }

  static Future<String> _getBaseDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path;
  }

  static Future<Directory> _getDefaultAppLogDir() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  /// Verify a directory is writable (used by main.dart during init).
  static Future<bool> verifyWritableDirectory(Directory dir) async {
    try {
      if (!await dir.exists()) await dir.create(recursive: true);
      final testFile = File(
        path.join(
          dir.path,
          '.fg_write_test_${DateTime.now().microsecondsSinceEpoch}.tmp',
        ),
      );
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      Zone.root.print('Logger verifyWritableDirectory failed: $e');
      return false;
    }
  }
}

/// Logs app lifecycle and system events.
class AppLifecycleLogger extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Logger.log('Lifecycle state: $state', level: 'LIFECYCLE');
  }

  @override
  void didHaveMemoryPressure() {
    Logger.log('Memory pressure signal received', level: 'LIFECYCLE');
  }

  @override
  void didChangeMetrics() {
    Logger.log('Metrics changed', level: 'LIFECYCLE');
  }

  @override
  void didChangePlatformBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    Logger.log('Platform brightness changed: $brightness', level: 'LIFECYCLE');
  }

  @override
  void didChangeTextScaleFactor() {
    final scale =
        WidgetsBinding.instance.platformDispatcher.textScaleFactor;
    Logger.log('Text scale factor changed: $scale', level: 'LIFECYCLE');
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    Logger.log('Locales changed: $locales', level: 'LIFECYCLE');
  }

  @override
  void didChangeAccessibilityFeatures() {
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    Logger.log('Accessibility features changed: $features',
        level: 'LIFECYCLE');
  }
}
```

**Verification:**
```
pwsh -Command "flutter analyze lib/core/logging/logger.dart"
```

---

## Phase 3: Build Script Guard

> **Agent:** `general-purpose`
> **Files:** `tools/build.ps1` (MODIFY)
> **Dependencies:** None

### Sub-phase 3.1: Add DEBUG_SERVER release guard

**Agent:** `general-purpose`

#### Step 3.1.1: Add security check to `tools/build.ps1`

**File:** `tools/build.ps1` (MODIFY)
**Location:** After line 41 (after the `.env` loading block, before the version parsing)

**WHY:** Prevents DEBUG_SERVER from being accidentally included in release builds. The HTTP transport would expose a network listener and bypass sensitive data protections that are only safe in debug mode.

**Insert after line 41** (`}`):
```powershell

# --- Security: block DEBUG_SERVER in release builds ---
if ($BuildType -ne "debug") {
    if (Test-Path $dartDefineFile) {
        $envContent = Get-Content $dartDefineFile -Raw
        if ($envContent -match "DEBUG_SERVER") {
            Write-Error "SECURITY: DEBUG_SERVER must not be set in .env for release builds. Remove it from $dartDefineFile"
            exit 1
        }
    }
}
```

**Verification:**
```bash
# Create a temp .env with DEBUG_SERVER and verify build script rejects it
# (manual verification — just ensure the script parses correctly)
pwsh -Command "Get-Content tools/build.ps1 | Select-Object -First 55"
```

---

## Phase 4: Logger Migration

> **Agent:** `general-purpose`
> **Files:** `lib/core/logging/debug_logger.dart` (MODIFY), `lib/core/logging/app_logger.dart` (MODIFY), `lib/main.dart` (MODIFY), `lib/core/logging/app_route_observer.dart` (MODIFY), `lib/core/router/app_router.dart` (MODIFY), `lib/features/sync/application/background_sync_handler.dart` (MODIFY)
> **Dependencies:** Phase 2 (Logger must exist)

### Sub-phase 4.1: Add deprecation forwarding to DebugLogger

**Agent:** `general-purpose`

#### Step 4.1.1: Add deprecation forwarding to `debug_logger.dart`

**File:** `lib/core/logging/debug_logger.dart` (MODIFY)

**WHY:** The 22 files importing DebugLogger continue to work unchanged. Each method forwards to Logger with a `@Deprecated` annotation so developers migrate incrementally. No existing call site breaks.

**Add import at top of file** (after line 7, before the class declaration at line 16):
```dart
import 'package:construction_inspector/core/logging/logger.dart';
```

**Replace each public method body** to forward to Logger. Add `@Deprecated` annotation to each:

For `initialize()` at line 40:
```dart
  @Deprecated('Use Logger.init() instead')
  static Future<void> initialize() async {
    // Forward to unified Logger — it handles session folder creation
    await Logger.init();
    _initialized = Logger.isInitialized;
    _sessionDir = Logger.sessionDirectory;
  }
```

For `ocr()` at line 95:
```dart
  @Deprecated('Use Logger.ocr() instead')
  static void ocr(String message, {Map<String, dynamic>? data}) {
    Logger.ocr(message, data: data);
  }
```

For `pdf()` at line 100:
```dart
  @Deprecated('Use Logger.pdf() instead')
  static void pdf(String message, {Map<String, dynamic>? data}) {
    Logger.pdf(message, data: data);
  }
```

For `sync()` at line 105:
```dart
  @Deprecated('Use Logger.sync() instead')
  static void sync(String message, {Map<String, dynamic>? data}) {
    Logger.sync(message, data: data);
  }
```

For `db()` at line 110:
```dart
  @Deprecated('Use Logger.db() instead')
  static void db(String message, {Map<String, dynamic>? data}) {
    Logger.db(message, data: data);
  }
```

For `auth()` at line 115:
```dart
  @Deprecated('Use Logger.auth() instead')
  static void auth(String message, {Map<String, dynamic>? data}) {
    Logger.auth(message, data: data);
  }
```

For `nav()` at line 120:
```dart
  @Deprecated('Use Logger.nav() instead')
  static void nav(String message, {Map<String, dynamic>? data}) {
    Logger.nav(message, data: data);
  }
```

For `ui()` at line 125:
```dart
  @Deprecated('Use Logger.ui() instead')
  static void ui(String message, {Map<String, dynamic>? data}) {
    Logger.ui(message, data: data);
  }
```

For `error()` at line 130:
```dart
  @Deprecated('Use Logger.error() instead')
  static void error(String message, {Object? error, StackTrace? stack}) {
    Logger.error(message, error: error, stack: stack);
  }
```

For `close()` at line 239:
```dart
  @Deprecated('Use Logger.close() instead')
  static Future<void> close() async {
    await Logger.close();
    _initialized = false;
  }
```

Keep `sessionDirectory` and `isInitialized` getters forwarding:
```dart
  @Deprecated('Use Logger.sessionDirectory instead')
  static String? get sessionDirectory => Logger.sessionDirectory;

  @Deprecated('Use Logger.isInitialized instead')
  static bool get isInitialized => Logger.isInitialized;
```

Remove all private methods (`_log`, `_makeJsonSafe`, `_openSink`, `_writeToSink`, `_writeToSinkSync`, `_getBaseDirectory`, `_formatTimestamp`, `_formatTimestampForFolder`) and private state fields — they are no longer needed since everything forwards to Logger. Keep the class shell and log file name constants for reference.

**NOTE:** The exact edit is large. The implementing agent should replace the entire file content with the deprecation-forwarding version, keeping the class signature and doc comments.

**Verification:**
```
pwsh -Command "flutter analyze lib/core/logging/debug_logger.dart"
```

#### Step 4.1.2: Add deprecation forwarding to `app_logger.dart`

**File:** `lib/core/logging/app_logger.dart` (MODIFY)

**WHY:** The 4 files importing AppLogger continue to work. Each method forwards to Logger.

**Add import** at top:
```dart
import 'package:construction_inspector/core/logging/logger.dart';
```

**Replace each public method** to forward to Logger with `@Deprecated`:

- `isEnabled` → `Logger.isEnabled`
- `init()` → `Logger.init()`
- `log()` → `Logger.log()`
- `writeJsonReport()` → `Logger.writeReport()`
- `installErrorHandlers()` → `Logger.installErrorHandlers()`
- `zoneSpec()` → `Logger.zoneSpec()`
- `installLifecycleLogger()` → `Logger.installLifecycleLogger()`
- `logDirectoryPath` → `Logger.logDirectoryPath`
- `logFilePath` → `Logger.logFilePath`
- `verifyWritableDirectory()` → `Logger.verifyWritableDirectory()`

Keep `kAppFileLoggingEnabled` const and `AppLifecycleLogger` class but mark as deprecated.

**NOTE:** The implementing agent should replace the entire file with the forwarding version.

**Verification:**
```
pwsh -Command "flutter analyze lib/core/logging/app_logger.dart"
```

### Sub-phase 4.2: Migrate priority call sites

**Agent:** `general-purpose`

#### Step 4.2.1: Migrate `main.dart` — P1

**File:** `lib/main.dart` (MODIFY)

**WHY:** main.dart initializes both loggers. Migrate to Logger.init() which handles both transports in one call.

**Changes:**

1. **Line 14**: Change import
   - OLD: `import 'package:construction_inspector/core/logging/app_logger.dart';`
   - NEW: `import 'package:construction_inspector/core/logging/logger.dart';`

2. **Line 15**: Change import
   - OLD: `import 'package:construction_inspector/core/logging/debug_logger.dart';`
   - NEW: Remove this line entirely (Logger handles both)

3. **Lines 94-100**: Replace `AppLogger.log(...)` with `Logger.ui(...)`
   - OLD:
     ```dart
     (error, stack) {
       AppLogger.log(
         'Uncaught zone error: $error',
         level: 'ERROR',
         error: error,
         stack: stack,
       );
     },
     ```
   - NEW:
     ```dart
     (error, stack) {
       Logger.error(
         'Uncaught zone error: $error',
         error: error,
         stack: stack,
       );
     },
     ```

4. **Line 102**: Replace `AppLogger.zoneSpec()` with `Logger.zoneSpec()`

5. **Lines 107-109**: Replace DebugLogger init
   - OLD:
     ```dart
     await DebugLogger.initialize();
     DebugLogger.ocr('Application starting...');
     ```
   - NEW:
     ```dart
     // Logger.init() is called in _initDebugLogging() below
     Logger.ocr('Application starting...');
     ```
   **NOTE:** Actually, `Logger.init()` is called in `_initDebugLogging()`. The early `DebugLogger.initialize()` call can be removed, and the `Logger.ocr()` call will buffer until init completes. Or keep a minimal `Logger.init()` call here. The implementing agent should ensure Logger is initialized before the first log call by moving init up.

6. **Lines 429-481**: Replace `_initDebugLogging()` function
   - OLD: Calls both `AppLogger.init()` and handles log directory selection
   - NEW: Call `Logger.init()` with the same directory logic, remove `AppLogger`-specific calls

   Replace the function body:
   ```dart
   Future<void> _initDebugLogging(PreferencesService preferencesService) async {
     if (!Logger.isEnabled) return;

     String? logDir = kAppLogDirOverride.isNotEmpty
         ? kAppLogDirOverride
         : preferencesService.debugLogDir;

     if (logDir != null && logDir.isNotEmpty) {
       final canWrite = await _ensureLogDirectoryWritable(logDir);
       if (canWrite) {
         await preferencesService.setDebugLogDir(logDir);
       } else {
         debugPrint('[INIT] Selected log folder not writable: $logDir');
         await preferencesService.setDebugLogDir('');
         logDir = null;
       }
     } else if (Platform.isAndroid || Platform.isIOS) {
       try {
         final selectedDir = await FilePicker.platform.getDirectoryPath(
           dialogTitle: 'Select folder for debug logs',
         );
         if (selectedDir != null && selectedDir.isNotEmpty) {
           final canWrite = await _ensureLogDirectoryWritable(selectedDir);
           if (canWrite) {
             await preferencesService.setDebugLogDir(selectedDir);
             logDir = selectedDir;
           } else {
             debugPrint('[INIT] Selected log folder not writable: $selectedDir');
             await preferencesService.setDebugLogDir('');
           }
         }
       } catch (e) {
         debugPrint('[INIT] Debug log folder picker failed: $e');
       }
     }

     try {
       if (logDir != null && logDir.isNotEmpty) {
         await Logger.init(baseDir: Directory(logDir));
       } else {
         await Logger.init();
       }
     } catch (e) {
       debugPrint('[INIT] Logger init failed: $e');
       await Logger.init();
     }

     Logger.log(
       'Debug logging enabled. Log dir: ${Logger.logDirectoryPath}',
       level: 'INIT',
     );
     Logger.installErrorHandlers();
     Logger.installLifecycleLogger();
   }
   ```

**Verification:**
```
pwsh -Command "flutter analyze lib/main.dart"
```

#### Step 4.2.2: Migrate `app_route_observer.dart` — P2

**File:** `lib/core/logging/app_route_observer.dart` (MODIFY)

**WHY:** Replace AppLogger.log(level: 'NAV') with cleaner Logger.nav() calls.

**Changes:**

1. **Line 2**: Change import
   - OLD: `import 'package:construction_inspector/core/logging/app_logger.dart';`
   - NEW: `import 'package:construction_inspector/core/logging/logger.dart';`

2. **Lines 8-11**: Replace `AppLogger.log(..., level: 'NAV')` with `Logger.nav(...)`
   - OLD: `AppLogger.log('Route push: ${_describe(route)} (from ${_describe(previousRoute)})', level: 'NAV',);`
   - NEW: `Logger.nav('Route push: ${_describe(route)} (from ${_describe(previousRoute)})');`

3. **Lines 17-20**: Same pattern for didPop
   - NEW: `Logger.nav('Route pop: ${_describe(route)} (to ${_describe(previousRoute)})');`

4. **Lines 26-29**: Same pattern for didRemove
   - NEW: `Logger.nav('Route remove: ${_describe(route)} (from ${_describe(previousRoute)})');`

5. **Lines 35-38**: Same pattern for didReplace
   - NEW: `Logger.nav('Route replace: ${_describe(oldRoute)} -> ${_describe(newRoute)}');`

**Verification:**
```
pwsh -Command "flutter analyze lib/core/logging/app_route_observer.dart"
```

#### Step 4.2.3: Migrate `app_router.dart` — P3

**File:** `lib/core/router/app_router.dart` (MODIFY)

**WHY:** Replace AppLogger.isEnabled reference with Logger.isEnabled.

**Changes:**

1. **Line 7**: Change import
   - OLD: `import 'package:construction_inspector/core/logging/app_logger.dart';`
   - NEW: `import 'package:construction_inspector/core/logging/logger.dart';`

2. **Line 86**: Replace `AppLogger.isEnabled` with `Logger.isEnabled`
   - OLD: `observers: AppLogger.isEnabled ? [AppRouteObserver()] : const [],`
   - NEW: `observers: Logger.isEnabled ? [AppRouteObserver()] : const [],`

**Verification:**
```
pwsh -Command "flutter analyze lib/core/router/app_router.dart"
```

#### Step 4.2.4: Migrate `background_sync_handler.dart` — P4

**File:** `lib/features/sync/application/background_sync_handler.dart` (MODIFY)

**WHY:** Replace bare debugPrint calls with Logger.sync() for structured logging. Background sync runs in an isolate where Logger file transport may not be initialized, but the debugPrint output is still captured.

**Changes:**

1. Add import at top:
   ```dart
   import 'package:construction_inspector/core/logging/logger.dart';
   ```

2. Replace all `debugPrint('[BACKGROUND_SYNC] ...')` calls with `Logger.sync('...')`:
   - Line 22: `debugPrint('[BACKGROUND_SYNC] Task started: $task')` → `Logger.sync('Background task started: $task')`
   - Line 32: `debugPrint('[BACKGROUND_SYNC] Supabase not configured, aborting')` → `Logger.sync('Supabase not configured, aborting background sync')`
   - Line 50 and similar: replace all remaining `debugPrint('[BACKGROUND_SYNC]...')` with `Logger.sync(...)`

**NOTE:** Background sync runs in a separate isolate where Logger.init() hasn't been called. The Logger.sync() calls will still call debugPrint (which is always available) even when `_initialized` is false. The file transport just won't write. This is acceptable — the key improvement is structured logging when running in the main isolate.

**Verification:**
```
pwsh -Command "flutter analyze lib/features/sync/application/background_sync_handler.dart"
```

### Sub-phase 4.3: Full analysis verification

#### Step 4.3.1: Run full project analysis

**WHY:** Ensure no regressions across the 26 dependent files.

**Verification:**
```
pwsh -Command "flutter analyze"
```

---

## Phase 5: Debug Skill

> **Agent:** `general-purpose`
> **Files:** `.claude/skills/systematic-debugging/SKILL.md` (REWRITE), `.claude/skills/systematic-debugging/references/` (4 files — REWRITE), `.claude/agents/debug-research-agent.md` (CREATE)
> **Dependencies:** None — can be done in parallel with Phase 4
> **NOTE:** These are Claude Code config files, not Dart code. No flutter analyze needed.

### Sub-phase 5.1: Rewrite SKILL.md

**Agent:** `general-purpose`

#### Step 5.1.1: Rewrite `.claude/skills/systematic-debugging/SKILL.md`

**File:** `.claude/skills/systematic-debugging/SKILL.md` (REWRITE, ~350 lines)

**WHY:** The current debug skill lacks log-first investigation, hypothesis tagging, HTTP server integration, and structured cleanup gates. The rewrite adds 10 phases with hard gates, server lifecycle management, and deep debug mode.

**Content:** Full systematic debugging workflow with these phases:
1. **Entry**: Ask Quick vs Deep mode
2. **Phase 1 TRIAGE**: Scan orphaned markers, check server health (`curl http://127.0.0.1:3947/health`), POST /clear
3. **Phase 2 COVERAGE CHECK**: Identify code path, assess Logger coverage in relevant files
4. **Phase 3 INSTRUMENT GAPS**: Add `Logger.hypothesis('H001', ...)` calls at key points, fill permanent Logger gaps
5. **Phase 4 REPRODUCE**: User interview questions, reproduction guidance, ADB health check (`adb devices`)
6. **Phase 5 EVIDENCE ANALYSIS**: `curl "http://127.0.0.1:3947/logs?hypothesis=H001&last=100"` with filters
7. **Phase 6 ROOT CAUSE REPORT**: Present findings with log evidence, ask USER GATE for approval to fix
8. **Phase 7 FIX**: Implement fix, POST /clear, verify with reproduction
9. **Phase 8 INSTRUMENTATION REVIEW**: Justify keep/remove per hypothesis marker
10. **Phase 9 CLEANUP HARD GATE**: Remove all `Logger.hypothesis()` markers, global search `hypothesis(`, write session log (scrubbed), prune 30-day retention in session logs
11. **Phase 10 DEFECT LOG**: Record in `.claude/defects/`

Include:
- Deep debug mode: launch `debug-research-agent` with `run_in_background: true` at Phase 1
- Reference file loading instructions
- ADB port forwarding reminder for Android: `adb reverse tcp:3947 tcp:3947`
- Auth restriction: never log tokens/credentials even in hypothesis markers
- Stop conditions for deep mode agent

**Verification:** Manual review — no compilation step for .md files.

#### Step 5.1.2: Rewrite reference file `log-investigation-and-instrumentation.md`

**File:** `.claude/skills/systematic-debugging/references/log-investigation-and-instrumentation.md` (CREATE — replaces `root-cause-tracing.md`)

**WHY:** New reference covering how to read logs from the debug server, instrumentation patterns with `Logger.hypothesis()`, category guide mapping features to Logger categories, and auth restrictions on what must never be logged.

**Content outline:**
- How to read logs: `curl` commands with filter combinations
- NDJSON parsing tips
- Instrumentation patterns: region markers, hypothesis tagging, permanent gap-filling
- Category guide: sync→Logger.sync(), pdf→Logger.pdf(), db→Logger.db(), etc.
- Auth restrictions: never log sensitive keys (reference the blocklist from Logger)
- Example hypothesis investigation workflow

#### Step 5.1.3: Rewrite reference file `codebase-tracing-paths.md`

**File:** `.claude/skills/systematic-debugging/references/codebase-tracing-paths.md` (CREATE — replaces `condition-based-waiting.md`)

**WHY:** 10 audited tracing paths showing the exact class names and files for the most common debugging scenarios.

**Content outline:**
- Sync flow: SyncProvider → SyncOrchestrator → SyncEngine → TableAdapter → Supabase
- PDF import flow: PdfImportHelper → PdfImportService → ExtractionPipeline → stages
- Auth flow: AuthProvider → Supabase auth → profile checks
- Database flow: Repository → LocalDatasource → DatabaseService → SQLite
- Navigation flow: GoRouter → redirect → AuthProvider state
- Photo flow: PhotoService → ImageService → file system / Supabase storage
- Background sync: WorkManager → backgroundSyncCallback → SyncEngine
- Error flow: FlutterError.onError → Logger → error.log
- Lifecycle flow: AppLifecycleLogger → Logger → app_session.log
- Form/calculator flow: ToolboxHub → feature providers → local datasources

#### Step 5.1.4: Update reference file `defects-integration.md`

**File:** `.claude/skills/systematic-debugging/references/defects-integration.md` (MODIFY)

**WHY:** Update to reference Logger instead of DebugLogger, and add log server integration.

#### Step 5.1.5: Create reference file `debug-session-management.md`

**File:** `.claude/skills/systematic-debugging/references/debug-session-management.md` (CREATE — replaces `defense-in-depth.md`)

**WHY:** Covers server setup, session lifecycle, cleanup gate rules, deep mode agent management, stop conditions, and interview questions.

**Content outline:**
- Server setup checklist: `node tools/debug-server/server.js`, ADB reverse for Android
- App launch: `pwsh -Command "flutter run -d <device> --dart-define=DEBUG_SERVER=true"`
- Session lifecycle: start → triage → instrument → reproduce → analyze → fix → cleanup
- Cleanup gate: must remove ALL hypothesis markers, global search pattern
- Deep mode: when to launch, how to read agent output, stop conditions
- Interview questions for reproduction (5 standard questions)
- 30-day retention pruning for session log folders

### Sub-phase 5.2: Create debug-research-agent

**Agent:** `general-purpose`

#### Step 5.2.1: Create `.claude/agents/debug-research-agent.md`

**File:** `.claude/agents/debug-research-agent.md` (CREATE)

**WHY:** Background agent that performs deep codebase analysis during debug sessions. Launched with `run_in_background: true` in deep debug mode to parallelize research while the user reproduces the bug.

**Content outline:**
```markdown
---
model: opus
---

# Debug Research Agent

You are a background research agent for deep debugging sessions. You run in parallel while the user reproduces a bug.

## Your Job

1. Receive a hypothesis and affected code paths
2. Trace the code paths end-to-end using CodeMunch and file reading
3. Identify potential failure points, race conditions, state corruption
4. Check recent git history for related changes
5. Cross-reference with `.claude/defects/` for known issues
6. Produce a research report with:
   - Code path trace (file:line references)
   - Potential root causes ranked by likelihood
   - Related defects found
   - Suggested Logger.hypothesis() instrumentation points

## Constraints

- NEVER modify any files
- NEVER run flutter commands
- Read-only research only
- Use CodeMunch repo: `local/Field_Guide_App-37debbe5`
- Max 15 tool calls before producing report
- Report format: bullet points, file:line references, no code blocks over 10 lines
```

**Verification:** Manual review.

### Sub-phase 5.3: Create debug-sessions directory and gitignore

**Agent:** `general-purpose`

#### Step 5.3.1: Create `.claude/debug-sessions/` directory

```bash
mkdir -p .claude/debug-sessions
```

**WHY:** FROM SPEC section 6 — session logs are preserved here for institutional memory. Must exist before the skill can write to it.

#### Step 5.3.2: Add `debug-sessions/` to config repo `.gitignore`

**WHY:** FROM SPEC section 10 — session logs may reference sensitive data even after scrubbing. Must not be committed to the `field-guide-claude-config` repository.

Add to the config repo's `.gitignore`:
```
debug-sessions/
```

**Verification:** Confirm `debug-sessions/` is gitignored.

---

## Phase 6: Tests

> **Agent:** `qa-testing-agent`
> **Files:** `test/core/logging/logger_test.dart` (CREATE)
> **Dependencies:** Phase 2 (Logger must exist)

### Sub-phase 6.1: Create Logger unit tests

**Agent:** `qa-testing-agent`

#### Step 6.1.1: Create `test/core/logging/logger_test.dart`

**File:** `test/core/logging/logger_test.dart` (CREATE)

**WHY:** Verify the unified Logger's file transport, sensitive data scrubbing, JSON safety, and API surface. HTTP transport is hard to unit test (needs server), so focus on the scrubbing and formatting logic.

**Test cases:**
1. `_scrubSensitive` redacts all sensitive keys
2. `_scrubSensitive` handles nested maps
3. `_scrubSensitive` passes through non-sensitive keys
4. `_makeJsonSafe` converts enums to `.name`
5. `_makeJsonSafe` handles nested maps and lists
6. `_formatTimestamp` produces correct format `HH:MM:SS.mmm`
7. `_formatTimestampForFolder` produces correct format `YYYY-MM-DD_HH-MM-SS`
8. Logger category methods don't throw when uninitialized
9. `Logger.init()` creates session folder and sinks (use temp directory)
10. `Logger.writeReport()` creates JSON file with correct content
11. `Logger.close()` cleans up sinks without error
12. `Logger.isEnabled` reflects compile-time flag

**NOTE:** Since `_scrubSensitive`, `_makeJsonSafe`, and format methods are private, the test either needs to:
- Use `@visibleForTesting` annotations on those methods, OR
- Test them indirectly through the public API

The implementing agent should add `@visibleForTesting` to the helper methods that need direct testing, or test through integration (init → log → verify file content).

**Verification:**
```
pwsh -Command "flutter test test/core/logging/logger_test.dart"
```

---

## Phase 7: Validation

> **Agent:** `qa-testing-agent`
> **Dependencies:** All previous phases

### Sub-phase 7.1: End-to-end validation

#### Step 7.1.1: Run full test suite

**Verification:**
```
pwsh -Command "flutter test"
```

**WHY:** Ensure no regressions across the entire test suite from the Logger migration.

#### Step 7.1.2: Run full static analysis

**Verification:**
```
pwsh -Command "flutter analyze"
```

**WHY:** Catch any type errors, missing imports, or deprecation issues across all 26 dependent files.

#### Step 7.1.3: Manual smoke test — server + app

**Steps (manual, for developer):**
1. Start debug server: `node tools/debug-server/server.js`
2. Launch app: `pwsh -Command "flutter run -d windows --dart-define=DEBUG_SERVER=true"`
3. Navigate around the app
4. Check server received logs: `curl "http://127.0.0.1:3947/logs?last=10"`
5. Check categories: `curl http://127.0.0.1:3947/categories`
6. Verify session folder created in Documents/Troubleshooting/...
7. Verify flat app log created in Documents/field_guide_logs/...
8. Stop app, check `curl http://127.0.0.1:3947/health` shows entry count
9. Ctrl+C server, verify `last-session.ndjson` created

#### Step 7.1.4: Verify release build rejects DEBUG_SERVER

**Verification:**
```bash
# Temporarily add DEBUG_SERVER=true to .env, try release build
# Expected: build.ps1 exits with SECURITY error
# Then remove DEBUG_SERVER from .env
```

---

## File Change Summary

### Creates (12)
| File | Lines | Agent |
|------|-------|-------|
| `tools/debug-server/server.js` | ~180 | general-purpose |
| `tools/debug-server/README.md` | ~60 | general-purpose |
| `lib/core/logging/logger.dart` | ~500 | general-purpose |
| `.claude/skills/systematic-debugging/SKILL.md` | ~350 | general-purpose |
| `.claude/skills/systematic-debugging/references/log-investigation-and-instrumentation.md` | ~120 | general-purpose |
| `.claude/skills/systematic-debugging/references/codebase-tracing-paths.md` | ~150 | general-purpose |
| `.claude/skills/systematic-debugging/references/debug-session-management.md` | ~100 | general-purpose |
| `.claude/agents/debug-research-agent.md` | ~30 | general-purpose |
| `test/core/logging/logger_test.dart` | ~150 | qa-testing-agent |

### Modifies (5)
| File | Change | Agent |
|------|--------|-------|
| `lib/core/config/test_mode_config.dart` | Add `debugServerEnabled` const + log line | general-purpose |
| `tools/build.ps1` | Add DEBUG_SERVER release guard | general-purpose |
| `lib/core/logging/debug_logger.dart` | Deprecation forwarding to Logger | general-purpose |
| `lib/core/logging/app_logger.dart` | Deprecation forwarding to Logger | general-purpose |
| `lib/main.dart` | Replace AppLogger/DebugLogger with Logger | general-purpose |
| `lib/core/logging/app_route_observer.dart` | Replace AppLogger with Logger | general-purpose |
| `lib/core/router/app_router.dart` | Replace AppLogger with Logger | general-purpose |
| `lib/features/sync/application/background_sync_handler.dart` | Replace debugPrint with Logger.sync() | general-purpose |

### Deletes (2 — replaced by new reference files)
| File | Replaced By |
|------|-------------|
| `.claude/skills/systematic-debugging/references/root-cause-tracing.md` | `log-investigation-and-instrumentation.md` |
| `.claude/skills/systematic-debugging/references/condition-based-waiting.md` | `codebase-tracing-paths.md` |
| `.claude/skills/systematic-debugging/references/defense-in-depth.md` | `debug-session-management.md` |

### Dependent Files (22 — no changes needed, forwarding handles them)
All 22 files importing `debug_logger.dart` continue working via deprecation forwarding:
- `lib/core/database/database_service.dart`
- `lib/core/database/schema_verifier.dart`
- `lib/features/pdf/presentation/helpers/pdf_import_helper.dart`
- `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`
- `lib/features/pdf/services/extraction/stages/grid_line_remover.dart`
- `lib/features/pdf/services/extraction/stages/post_processor_v2.dart`
- `lib/features/pdf/services/pdf_import_service.dart`
- `lib/features/projects/data/datasources/local/project_local_datasource.dart`
- `lib/features/projects/data/repositories/project_repository.dart`
- `lib/features/quantities/presentation/providers/bid_item_provider.dart`
- `lib/features/quantities/utils/budget_sanity_checker.dart`
- `lib/features/sync/application/sync_lifecycle_manager.dart`
- `lib/features/sync/application/sync_orchestrator.dart`
- `lib/features/sync/engine/change_tracker.dart`
- `lib/features/sync/engine/integrity_checker.dart`
- `lib/features/sync/engine/orphan_scanner.dart`
- `lib/features/sync/engine/storage_cleanup.dart`
- `lib/features/sync/engine/sync_engine.dart`
- `lib/services/soft_delete_service.dart`
- `lib/services/startup_cleanup_service.dart`
- `lib/shared/datasources/generic_local_datasource.dart`
- `test/core/logging/debug_logger_test.dart`
