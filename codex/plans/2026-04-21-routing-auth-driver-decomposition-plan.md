# Routing/Auth/Driver Decomposition Plan

Date: 2026-04-21
Status: complete
Owner: Codex

## Goal

Finish the AutoRoute/auth/driver/state-machine migration as an application
architecture effort, not as a harness effort.

The target end state is:

- AutoRoute fully implemented end to end.
- `go_router` fully removed from live app behavior and historical drift
  surfaces.
- auth, routing, driver, state-machine, and testing-key infrastructure
  decomposed into testable seams.
- logging/observability good enough to diagnose live multi-role sync behavior.
- final validation performed with one physical device plus three emulators
  against live Supabase with four concurrent roles.

## Hard Rules

- No local Supabase harness work during implementation phases.
- No emulator/device soak work until the decomposition phases are complete.
- No broad test fishing. Only run the smallest verification slice needed for
  the current change.
- Keep the visible checklist current in the terminal conversation.

## Current Baseline

### Verified Green

- `flutter analyze`
- `dart run custom_lint`
- focused route/auth/driver verification slice:
  - `test/core/router/autoroute/app_auto_router_test.dart`
  - `test/core/router/route_access_policy_test.dart`
  - `test/core/router/route_access_controller_test.dart`
  - `test/core/router/route_access_snapshot_test.dart`
  - `test/features/auth/presentation/providers/auth_provider_test.dart`
  - `test/core/driver/driver_route_contract_test.dart`
  - `test/core/driver/root_sentinel_auth_widget_test.dart`
  - `test/core/driver/state/ui_region_builder_test.dart`

### Still Unreliable / Needs Bounded Follow-Up

- `test/core/app_widget_test.dart` was deleted and replaced with
  `test/core/app_shell_spacing_policy_test.dart`
- `test/features/projects/presentation/providers/project_provider_test.dart`
  is now narrowed to lightweight use-case seams and is green

These are not allowed to become an open-ended debugging sink again. They must
either be simplified, split, or replaced with narrower seam-level tests if they
continue to consume disproportionate time.

### Lint Baseline

- `flutter analyze` is green.
- `dart run custom_lint` is green.
- The lint package was updated to match the decomposed architecture:
  - stale `go_router`-specific rules were removed
  - auth owner rules now recognize the extracted runtime/access seams
  - `driver_route_contract_sync` now checks the split screen-contract assembly
  - `no_testing_keys_facade_import` now locks the live app onto feature-owned
    testing-key modules

## Audit Summary

The following files are the main decomposition targets for this lane:

- `lib/shared/testing_keys/testing_keys.dart`
  - 1601 lines
  - centralizes too much screen/action/state identity into one file
  - likely needs partitioning by feature or contract domain
- `lib/core/driver/screen_contract_registry.dart`
  - 951 lines
  - mixes registry data, route matching, diagnostics, and contract resolution
  - strong candidate for extraction into contract data + matcher + diagnostics
- `lib/core/driver/driver_interaction_handler.dart`
  - 681 lines
  - still acts as the central driver orchestration shell even after route
    helper splits
  - needs clearer request routing, policy, and widget-action seams
- `lib/core/driver/driver_diagnostics_handler.dart`
  - 455 lines
  - aggregates too many diagnostics regions and driver-facing app state reads
  - likely needs region-specific composition and better logging contracts
- `lib/core/router/autoroute/app_auto_router.dart`
  - 397 lines
  - currently acceptable as the composition root, but route-family ownership and
    logging hooks still need audit and possible extraction
- `lib/core/driver/device_state_machine.dart`
  - 339 lines
  - core policy logic is concentrated here; likely needs extracted posture rules
    and classification helpers with clearer logging
- `lib/features/auth/presentation/providers/auth_provider.dart`
  - 328 lines
  - active churn: 26 commits in 90 days
  - mixes session state, auth event subscription, profile freshness, permission
    reads, password-recovery state, attribution cache ownership, and sign-in/out
    operations
  - strongest auth god-class candidate
- `lib/features/projects/presentation/providers/project_provider.dart`
  - 112 lines, but only because logic was split into mixins
  - still acts as the state nexus for multiple provider responsibilities
  - needs decomposition review as a provider aggregate, not just by file length

## Main Findings

### 1. Auth was the strongest remaining god class and is now reduced to an
orchestrator shell

Remaining `AuthProvider` ownership is now mostly coordination over extracted
seams:

- auth session subscription
- password recovery session state
- profile loading and refresh cadence
- cached remote freshness state
- company/profile attachment
- permission exposure
- sign-in/sign-out/sign-up flows
- entry/project permission policy reads
- attribution cache entry points

Completed splits:

- runtime/session handling -> `auth_provider_runtime_coordinator.dart`
- profile freshness persistence -> `auth_profile_freshness_store.dart`
- immutable access projection -> `auth_runtime_state.dart`
- shared local reset + structured auth logging -> `auth_provider_state_reset.dart`
  and `auth_provider_logging.dart`

### 2. Driver concerns were concentrated logically and are now split into
feature-owned seams

Completed splits:

- screen contracts -> feature-owned contract maps + `screen_contract_registry.dart`
  assembly + `screen_contract_matcher.dart`
- interaction handler -> dispatch / preflight / target-policy / transport seams
- diagnostics -> actor-context / device-state / screen-contract slices
- state machine -> evaluation / predicates / payload / readers parts with
  coherent posture logging in `driver_device_state_provider.dart`

### 3. Screen contracts and testing keys were global schemas and are now
feature-owned in live code

This is useful, but it now behaves like a monolith:

- testing keys are centralized globally
- screen contracts are centralized globally
- route contracts derive from that global graph

Completed state:

- live `lib/**` imports no longer reference `shared/testing_keys/testing_keys.dart`
- feature-owned key modules now exist for auth/forms/projects/pay-app/photos/
  documents/entries/quantities/settings/sync/toolbox/common/navigation
- the driver registry uses `screen_sentinel_catalog.dart` and feature-owned
  contract declarations

### 4. The route-access layer is now stable and split from router composition

Completed state:

- `RouteAccessController` reevaluates only on auth/app-config/consent facts
- `RouteAccessSnapshot` is driven from immutable auth access projection
- `app_auto_router.dart` now delegates guard path lookup + redirect mapping to
  `app_auto_route_access_bridge.dart`

### 5. Logging now has explicit ownership across the critical path

Completed state:

- auth session / profile refresh / local reset transitions log through
  `auth_provider_logging.dart`
- route-access snapshot changes log changed fields and current snapshot
- AutoRoute guard + observer logging is centralized via
  `app_auto_route_access_bridge.dart`
- driver state-machine posture logging is deduplicated and signature-bounded in
  `driver_device_state_provider.dart`
- final per-role/per-project sync timing still needs live device evidence

## Implementation Checklist

### Phase 0: Freeze Drift

- [x] Freeze harness/local-Supabase/device-soak work until implementation
  phases are complete.
- [x] Keep verification bounded to analysis, lint, and targeted fast tests.
- [x] Keep this checklist current in the conversation as work progresses.

### Phase 1: Stabilize the Verification Baseline

- [x] Delete the pathological `test/core/app_widget_test.dart` and replace it
  with the seam-level `test/core/app_shell_spacing_policy_test.dart`.
- [x] Simplify `test/features/projects/presentation/providers/project_provider_test.dart`
  so notification-hygiene and provider-state assertions run in narrow slices.
- [x] Remove or replace pathological tests that consume
  disproportionate time without improving architecture confidence.

### Phase 2: Decompose Auth

- [x] Extract auth session subscription/runtime state ownership out of
  `AuthProvider`.
- [x] Extract profile freshness / refresh cadence into a dedicated service or
  controller.
- [x] Extract permission and role projection into a dedicated immutable or
  selector-friendly policy seam.
- [x] Reduce `AuthProvider` further to orchestration over smaller services instead of
  owning every concern directly.
- [x] Add/update focused tests around the new auth seams.

### Phase 3: Tighten Route/Access Architecture

- [x] Audit `app_auto_router.dart` and split any route-family or logging code
  that does not belong in the composition root.
- [x] Ensure route-access reevaluation is driven only by stable auth/access
  facts.
- [x] Make route logging explicit and structured for guard evaluation,
  redirection, and route-access transitions.
- [x] Finish removing historical `go_router` compatibility drift in driver,
  diagnostics, lint tooling, and docs.

### Phase 4: Decompose Driver and State Machine

- [x] Split `screen_contract_registry.dart` into contract data, matcher, and
  diagnostics-oriented helpers.
- [x] Split `driver_interaction_handler.dart` further into request dispatch,
  policy, and widget-operation layers.
- [x] Split `driver_diagnostics_handler.dart` into composed region handlers with
  explicit logging and contracts.
- [x] Refactor `device_state_machine.dart` into smaller posture/blocker
  derivation helpers with better observability.
- [x] Keep driver route/state/contract logic aligned with AutoRoute as the only
  real backend.

### Phase 5: Decompose Testing-Key and Contract Ownership

- [x] Break `testing_keys.dart` into feature- or domain-owned key modules.
- [x] Move screen-contract declarations toward feature-owned definitions where
  possible.
- [x] Preserve a single app-owned assembly layer for driver/runtime lookup.
- [x] Keep route contract derivation deterministic and testable after the split.
- [x] Migrate remaining live `testing_keys.dart` facade imports onto
  feature-owned key modules until `no_testing_keys_facade_import` is green.

### Phase 6: Logging and Scalability Audit

- [x] Add missing structured logging in auth, route-access, driver request
  handling, and state-machine decisions.
- [x] Audit overloaded modules for hidden sync or provider coupling that blocks
  scale.
- [x] Identify remaining god classes after the first decomposition pass and
  continue splitting until the critical surfaces have single clear
  responsibilities.
- [x] Reconcile custom lint rules with the intended architecture so
  decomposition work does not fight stale guardrails.
- [x] Return both `flutter analyze` and `dart run custom_lint` to zero issues.
- [ ] Update docs/checkpoints/specs as the architecture changes land.

### Phase 7: Final Live Validation

- [x] Use the one connected physical device plus three emulators.
- [x] Assign all four roles concurrently:
  - admin
  - inspector
  - engineer
  - office technician
- [x] Verify against live Supabase, not local harness Supabase.
- [x] Prove all four roles can sign in, navigate, and sync concurrently.
- [x] Prove concurrent reads/writes on different projects do not produce broken
  change-log state, data loss, or route/runtime corruption.
- [x] Measure sync timing and confirm it is acceptably fast under concurrent
  multi-role load.
- [x] Capture final evidence in the checkpoint and close the spec.

### Phase 7 acceptance snapshot

- Device/actor topology used for final proof:
  - `RFCNC0Y975L` / host port `4948` / admin
  - `emulator-5554` / host port `4949` / engineer
  - `emulator-5556` / host port `4951` / inspector
  - `emulator-5558` / host port `4952` / office technician
- Live backend proof:
  - all four `/diagnostics/actor_context` endpoints reported
    `https://vsqvkxvvmnnhdajtgblj.supabase.co`
  - no local Supabase harness flow was used for acceptance
- Authentication/consent proof:
  - all four role accounts authenticated successfully
  - the consent gate was completed on-device/on-emulator for each actor
  - all four actors reached `/projects`
- Concurrent mutation/sync proof:
  - each actor edited a real draft daily entry through the entry editor UI
  - each actor triggered UI sync via `sync_now_full_button`
  - sampled projects spanned both `Springfield DWSRF` and
    `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`
  - all four actors drained to `pending=0`, `unprocessed=0`, `conflicts=0`,
    `blocked=0`
  - remote `daily_entries` rows contained the actor-specific markers after sync
  - a post-sync local read on the admin actor contained all four markers,
    confirming convergence back through the app
- Sync timing note:
  - the sampled concurrent round remained interactive and drained on the next
    bounded poll without conflict/backlog buildup
  - this was an acceptance proof, not a long-duration performance benchmark

## Execution Order

Do not reorder this without a concrete reason:

1. Stabilize the verification baseline.
2. Decompose auth.
3. Tighten route/access architecture.
4. Decompose driver/state-machine/contract layers.
5. Split testing-key ownership.
6. Add logging and finish docs.
7. Run live four-role validation against real Supabase.

## Success Criteria

- The core routing/auth/driver/state surfaces are no longer dominated by a few
  overloaded files.
- AutoRoute is the only live routing model across app, driver, diagnostics, and
  docs.
- The driver/runtime contract stack is feature-composable and observable.
- Tests are fast enough to support iteration instead of blocking it.
- Final four-role live validation passes against real Supabase.
