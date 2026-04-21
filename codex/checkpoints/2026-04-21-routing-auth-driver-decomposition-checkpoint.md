# Routing/Auth/Driver Decomposition Checkpoint

Date: 2026-04-21
Status: complete
Owner: Codex

## Summary

This checkpoint closes the AutoRoute/auth/driver decomposition lane end to end.

What is now true in the codebase:

- AutoRoute is the only live routing backend in app code, driver code, lint
  rules, and current docs.
- `go_router` drift was removed from live surfaces and obsolete go-router lint
  rules were deleted.
- `AuthProvider` is now a coordination shell over extracted runtime, freshness,
  immutable access projection, local reset, and structured logging seams.
- driver contracts are feature-owned instead of living in one monolithic
  registry file.
- the device state machine is split into evaluation/predicate/payload readers
  with bounded posture logging.
- live app code no longer imports `shared/testing_keys/testing_keys.dart`.
- `flutter analyze` and `dart run custom_lint` are both green again.
- the final live four-role device/emulator validation passed against production
  Supabase without the local harness flow.

## CodeMunch Audit Outcome

The targeted CodeMunch audit on auth/router/driver/testing-key surfaces found
the same architectural pressure points that drove this refactor:

- `AuthProvider` was the strongest remaining auth god-class candidate.
- `screen_contract_registry.dart` / `driver_interaction_handler.dart` /
  `driver_diagnostics_handler.dart` / `device_state_machine.dart` were still a
  tightly coupled driver platform.
- testing keys and screen contracts had become shared global schemas.
- route-access was smaller, but router guard lookup and redirect ownership were
  still leaking into the composition root.

Those findings are now addressed in the live code:

- auth runtime and local reset logic are split out of `auth_provider.dart`
- route guard lookup + redirect mapping now live in
  `app_auto_route_access_bridge.dart`
- driver interaction / diagnostics / state-machine responsibilities are split
  into dedicated files
- feature-owned testing-key modules now own live UI key imports

## Verification

Green verification at this checkpoint:

- `flutter analyze`
- `dart run custom_lint`
- `flutter test test/core/router/autoroute/app_auto_router_test.dart --no-pub -j 1`
- `flutter test test/features/auth/presentation/providers/auth_provider_test.dart --no-pub -j 1`

Additional earlier targeted slices remained green during the lane:

- route-access tests
- driver route/state/registry/root-sentinel tests
- auth onboarding / app-shell / project-provider seam tests

## Final Live Validation

Acceptance was completed against live Supabase on:

- physical device `RFCNC0Y975L` (`SM_G996U`) as admin
- `emulator-5554` as engineer
- `emulator-5556` as inspector
- `emulator-5558` as office technician

What was proven in the final round:

- all four actors reported the live backend
  `https://vsqvkxvvmnnhdajtgblj.supabase.co`
- all four actors signed in with real sessions and cleared the consent gate
- all four actors reached `/projects`
- each actor edited a real draft `daily_entries` record through the entry
  editor UI with an actor-specific activity marker
- the sampled entries covered two separate projects:
  - `Springfield DWSRF`
  - `SYNC SOAK ROLE TRAFFIC TEST - DELETE OK`
- each actor then triggered sync through the UI on `/sync/dashboard`
- all four actors drained to zero pending/unprocessed/blocked/conflict counts
- remote `daily_entries` rows contained the actor-specific markers after the
  concurrent sync trigger
- a post-sync local read on the admin actor showed all four markers present,
  confirming convergence back through the app

Acceptance notes:

- no local Supabase harness or sync-soak runner was used for final proof
- this round was an interactive acceptance pass, not a prolonged soak/perf run
- the sampled concurrent sync round stayed interactive and did not exhibit
  conflict churn, route corruption, or change-log backlog
