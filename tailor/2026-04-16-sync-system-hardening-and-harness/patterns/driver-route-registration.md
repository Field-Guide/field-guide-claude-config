# Pattern — Driver Route + Screen Contract Registration

## How the repo does it

Sync-visible UI is inspectable through a three-level contract: (1) `screenRegistryEntries` maps a screen name → widget factory for harness-built shells; (2) `screenContracts` maps the same screen name → routes + TestingKeys + action/state keys for diagnostic inspection; (3) `flowRegistry` composes multi-step user flows for driver-driven verification. An HTTP driver handler serves the composed state at `/diagnostics/screen_contract`. The custom lint rule `screen_registry_contract_sync` enforces parity between (1) and (2).

## Exemplars

- `lib/core/driver/screen_registry.dart` — 39 screen builders.
- `lib/core/driver/screen_contract_registry.dart` — 32 `ScreenContract` entries + `resolveActiveScreenContract(route, visibleRootKeys)`.
- `lib/core/driver/flow_registry.dart` — merges `formsFlowDefinitions`, `navigationFlowDefinitions`, `verificationFlowDefinitions`.
- `lib/core/driver/driver_diagnostics_handler.dart` — HTTP handler; `_handleScreenContract` composes breakpoint/density/animation/theme/screen payload.

## Reusable surface

```dart
// Add a new screen contract
'NewHarnessScreen': const ScreenContract(
  id: 'NewHarnessScreen',
  rootKey: TestingKeys.newHarnessScreen,          // add to TestingKeys first
  routes: ['/harness/new/:id'],
  seedArgs: ['id'],
  actionKeys: ['new_harness_save_button', 'new_harness_cancel_button'],
  stateKeys: ['new_harness_screen', 'new_harness_list'],
);

// Add a matching registry entry in screenRegistryEntries
'NewHarnessScreen': ScreenRegistryEntry(
  seedArgs: const ['id'],
  builder: (data) => NewHarnessScreen(
    id: (data['id'] as String?) ?? HarnessSeedData.defaultProjectId,
  ),
),
```

### Adding a new diagnostic route (avoid unless truly needed)

```dart
// In DriverDiagnosticsRoutes:
static const myNewEndpoint = '/diagnostics/my_new_endpoint';

// Extend matches(path) + switch(path) in handle().
// Add _handleMyNewEndpoint that returns a JSON payload via _sendJson.
```

## Ownership boundaries

- `TestingKeys` is the only source of key values. Never hardcode `Key('...')`.
- A screen contract change requires: contract registry update + driver registry update + TestingKeys update + any targeted test update — all in the same PR.
- `resolveActiveScreenContract` is what `/diagnostics/screen_contract` uses to decide which contract the driver is "currently on". It prefers a visible-root-key match; falls back to route pattern.
- Don't add business logic to the diagnostics handler. It reports state; it does not mutate.

## Imports

```dart
import 'package:construction_inspector/core/driver/screen_contract_registry.dart';
import 'package:construction_inspector/shared/testing_keys/testing_keys.dart';
```

## What the harness uses

- `GET /diagnostics/screen_contract` → `{route, rootPresent, actions, states, seedArgs, ...}`
- `GET /diagnostics/sync_transport` → `{transportHealth, lastRun: {pushed, pulled, errors, rlsDenials, durationMs, ...}}`
- `GET /diagnostics/sync_runtime` → `{lastRequestedMode, dirtyScopes, stateFingerprint, ...}`

All three are read-only; the harness uses them for assertions, not for setup.
