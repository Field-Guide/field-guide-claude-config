# Testing — Procedure Guide

> Loaded on-demand by workers. For constraints and invariants, see .claude/rules/testing/testing.md

---

## HTTP Test Driver (Primary E2E Mechanism)

Full HTTP server for external test automation, replacing the removed Patrol stack.

**Entrypoint:** `lib/main_driver.dart` (NOT `lib/main.dart`)

### Architecture (`lib/core/driver/`)

| File | Purpose |
|------|---------|
| `driver_server.dart` | HTTP server -- tap widgets, enter text, scroll, take screenshots |
| `driver_setup.dart` | Wiring and initialization for driver mode |
| `flow_registry.dart` | Multi-screen journey definitions |
| `harness_seed_data.dart` | Inject test data via HTTP |
| `screen_registry.dart` | Maps screen keys to widget builders |
| `stub_router.dart` | Lightweight router for isolated screen testing |
| `test_db_factory.dart` | In-memory SQLite for test isolation |
| `test_photo_service.dart` | Stub photo service for offline testing |

### Security (5 layers)

1. **Compile-time flag** -- driver code stripped from release builds
2. **Release mode check** -- server refuses to start in release mode
3. **Loopback-only binding** -- listens on 127.0.0.1 only
4. **Custom entrypoint** -- `main_driver.dart` is never the production entrypoint
5. **build.ps1 gate** -- build tooling prevents driver entrypoint in release artifacts

### Lifecycle Scripts

```powershell
pwsh -File tools/start-driver.ps1    # Launch app in driver mode
pwsh -File tools/stop-driver.ps1     # Tear down driver process
pwsh -File tools/wait-for-driver.ps1 # Block until server is ready
```

---

## Unit Tests

### Run Commands

```powershell
# All unit tests
pwsh -Command "flutter test"

# Specific test file
pwsh -Command "flutter test test/features/pdf/extraction/some_test.dart"

# Specific test by name
pwsh -Command "flutter test test/features/pdf/extraction/ --name 'stage trace'"
```

---

## Widget Test Harness (Isolated Screen Testing)

Purpose: render one screen at a time with real providers backed by in-memory SQLite for faster, lower-load UI testing than full-app launch.

### Launch Sequence

1. Write `harness_config.json` at project root:
   ```json
   {"screen":"ProctorEntryScreen","data":{"responseId":"test-response-001"}}
   ```
2. `pwsh -Command "flutter run -d windows -t lib/test_harness.dart"`
3. Interact with the rendered screen manually or via the HTTP test driver

### Config Fields

- `screen` (required): registry key from `lib/core/driver/screen_registry.dart`
- `data` (optional): per-screen constructor/seed inputs

### Adding a New Screen to Harness

1. Add a registry entry in `lib/core/driver/screen_registry.dart`
2. Add `ValueKey` coverage for interactive elements in the screen widget
3. Add/update keys in `lib/shared/testing_keys/testing_keys.dart`
4. If the screen needs extra context, extend harness seeding via `harness_config.json` `data`

### Flow Mode (Multi-Screen Journey Testing)

Wires up real GoRouter routes so screens navigate naturally without relaunching the app per screen.

#### Flow `harness_config.json` Format
```json
{
  "flow": "0582b-forms",
  "startAt": "/forms",
  "data": {
    "responseId": "harness-response-001"
  }
}
```
- `flow`: key into `lib/core/driver/flow_registry.dart` (triggers flow mode instead of single-screen mode).
- `startAt`: optional initial route path (defaults to flow's `defaultInitialLocation`).
- `data`: shared seed data, same as single-screen mode.

#### Available Flows
| Flow Key | Start | Screens |
|----------|-------|---------|
| `0582b-forms` | `/forms` | FormsListScreen, FormViewerScreen, QuickTestEntryScreen, ProctorEntryScreen, WeightsEntryScreen, ToolboxHomeScreen |

#### Add a New Flow
1. Add a `FlowDefinition` entry in `lib/core/driver/flow_registry.dart`.
2. Copy needed `GoRoute` entries from `app_router.dart` (without auth redirects/shell routes).
3. Include fallback routes used by `safeGoBack` in the flow's screens.
4. List seed screen names in `seedScreens`.

---

## Widget Keys — TestingKeys

16 feature-specific key files in `lib/shared/testing_keys/`, re-exported via barrel `testing_keys.dart`.

**Pattern:** `FeatureTestingKeys.widgetName` assigned via `key:` parameter.

### Key Rules

1. **Never** use hardcoded `Key('...')` strings in widgets or tests
2. **Always** reference keys from the appropriate `*Keys` class
3. **Import** via: `import 'package:construction_inspector/shared/shared.dart';`
4. **Add new keys** to the feature-specific file (e.g., `entries_keys.dart`, `photos_keys.dart`)

### Adding New Keys

```dart
// 1. Add to the feature-specific file, e.g. lib/shared/testing_keys/entries_keys.dart
class EntriesTestingKeys {
  static const myNewButton = Key('entries_my_new_button');
}

// 2. Use in widget
ElevatedButton(
  key: EntriesTestingKeys.myNewButton,
  onPressed: _handlePress,
  child: Text('Press Me'),
)
```

### Key Files

`auth_keys.dart`, `common_keys.dart`, `consent_keys.dart`, `contractors_keys.dart`, `documents_keys.dart`, `entries_keys.dart`, `locations_keys.dart`, `navigation_keys.dart`, `photos_keys.dart`, `projects_keys.dart`, `quantities_keys.dart`, `settings_keys.dart`, `support_keys.dart`, `sync_keys.dart`, `testing_keys.dart` (barrel + legacy keys), `toolbox_keys.dart`

---

## Process Management

- **NEVER** `Stop-Process -Name 'dart'` -- can kill background Dart processes
- **SAFE kill**: `Stop-Process -Name 'construction_inspector' -Force -ErrorAction SilentlyContinue`

---

## Golden Tests

Visual regression tests comparing widget renders against baseline PNGs.

- **Location:** `test/golden/` -- ~95 baseline PNGs in `test/golden/goldens/`
- **PDF goldens:** `test/golden/pdf/` (failures dir; baselines pending)
- **Helper:** `tools/build_golden_from_run.dart` -- rebuild baselines from CI artifacts

### Organization

```
test/golden/
├── themes/       # light_theme, dark_theme, high_contrast_theme
├── components/   # form_fields, photo_grid, quantity_cards, dashboard_widgets
├── states/       # empty_state, error_state, loading_state
├── widgets/      # confirmation_dialog, entry_card, project_card, weather_widget
├── pdf/          # PDF rendering goldens (failures/)
├── goldens/      # Baseline PNGs (all themes/components/states/widgets)
└── test_helpers.dart
```

### Run Commands

```powershell
# Run all golden tests
pwsh -Command "flutter test test/golden/"

# Update baselines (after intentional visual changes)
pwsh -Command "flutter test test/golden/ --update-goldens"
```

---

## Sync Testing (Debug Server)

Sync-specific tests run via unit tests for Layer 1. Use this command:

```bash
# Layer 1: Unit tests (fast, no device)
pwsh -Command "flutter test test/features/sync/engine/"
```

### Layer 2 & Layer 3 Sync Testing

Sync integration testing is Claude-driven via test flows. See `.claude/test-flows/sync/framework.md` and the flow files in `.claude/test-flows/sync/` for the current workflow.

> **Note:** The previous `run-tests.js --layer L2/L3` CLI commands have been removed. Use the Claude-driven verification guide instead.

---

## PDF Extraction Stage Trace Testing

### Run Commands

```powershell
# Stage trace tests
pwsh -Command "flutter test test/features/pdf/extraction/ --name 'stage trace'"

# All PDF tests
pwsh -Command "flutter test test/features/pdf/"

# With diagnostics
pwsh -Command "flutter test test/features/pdf/ --dart-define=PDF_PARSER_DIAGNOSTICS=true"

# Specific test file
pwsh -Command "flutter test test/features/pdf/services/<test_file>.dart"
```

### Current Baseline (snapshot -- may be stale)

> Values below are a point-in-time snapshot. Run the pipeline report test to get current numbers.

- **68 OK / 3 LOW / 0 BUG**
- Quality: **0.993**
- Ground truth coverage: **131/131 GT matched**

Validates the PDF extraction pipeline end-to-end against ground truth fixtures.

### Springfield Pipeline Report Workflow

**CRITICAL: Always run the pipeline report test after any pipeline stage code changes.**
This generates a JSON trace + MD scorecard and runs a regression gate against the previous baseline.

Run command (substitute your Springfield PDF path):

```powershell
pwsh -Command "flutter test integration_test/springfield_report_test.dart -d windows --dart-define='SPRINGFIELD_PDF=<your-local-path-to-springfield-pdf>'"
```

Takes ~2 minutes on Windows. Reports saved to `test/features/pdf/extraction/reports/latest-<platform>/`.

Variants:
- `--dart-define=NO_GATE=true` — exploratory run, skip regression gate
- `--dart-define=RESET_BASELINE=true` — archive current baseline, establish new one

CLI comparison (any two report folders):
```powershell
pwsh -Command "dart run tools/pipeline_comparator.dart reports/latest-windows reports/latest-sm-s938u"
```

### Key Test Files

| File | Purpose |
|------|---------|
| `integration_test/springfield_report_test.dart` | Full pipeline report + regression gate |
| `test/features/pdf/extraction/golden/pipeline_comparator.dart` | Comparison library (replaces 3 old tools) |
| `test/features/pdf/extraction/golden/report_generator.dart` | JSON trace + MD scorecard generator |
| `tools/pipeline_comparator.dart` | CLI entry point for cross-platform comparison |

### Report Output

- **Desktop**: `test/features/pdf/extraction/reports/` (gitignored)
  - `latest-<platform>/` — current baseline (regression gate compares against this)
  - `<platform>_<date>_<time>/` — dated archives (max 20 per platform)
- **Android**: `<app-docs>/extraction_reports/` (pull via adb)

### Scorecard Display Format

The report test generates a scorecard automatically. When presenting results, use the generated scorecard MD directly. Key sections: Stage Statistics table, Item Flow table, Summary.

---

## Test Monitoring Rules

- Report total pass/fail counts from output
- Quote specific failure messages (assertion text, expected vs actual values)
- Group failures by feature/file
- Never say "tests passed" without reading the runner output
- If no output for 60s -- kill the process and report as timeout

---

## Resources

- TestingKeys: `lib/shared/testing_keys/` (16 files, barrel: `testing_keys.dart`)
- HTTP Driver: `lib/core/driver/` (8 files, entrypoint: `lib/main_driver.dart`)
- Golden Baselines: `test/golden/goldens/` (~95 PNGs)
- Pipeline Reports: `test/features/pdf/extraction/reports/` (gitignored, per-platform baselines)
- Defects to Avoid: `gh issue list --label "{feature}" --state open` (GitHub Issues)
- Screen Registry: `lib/core/driver/screen_registry.dart`

---

## Legacy: Deprecated Testing Stacks

| Stack | Status | Replacement |
|-------|--------|-------------|
| Patrol | Removed | HTTP test driver + unit/widget/golden tests |
| flutter_driver | Removed | HTTP test driver + unit/widget/golden tests |
