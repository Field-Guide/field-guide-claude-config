# Unified Routing, State, Auth, And Four-Device Live-Testing Reset Spec

Date: 2026-04-20
Status: active controlling integration spec
Checkpoint: `.codex/checkpoints/2026-04-20-unified-routing-state-auth-live-testing-reset-checkpoint.md`

## Decision

Build one standardized app-wide routing, state, auth, driver, and four-device
live-testing integration system.

This is not only an AutoRoute migration and not only a driver hardening lane.
The failures we are seeing are coming from one larger problem: navigation,
auth session state, profile hydration, role policy, sentinel-key posture,
driver readiness, and sync context can still each claim to be the truth at
different times. That is exactly how we end up with blind taps, login screens
that the harness does not recognize, devices sitting on the launcher while the
host thinks they are fine, and route/permission state changing underneath the
driver.

Going forward, app navigation, route access, auth state, screen sentinels,
driver actions, device posture, sync context, and live four-device acceptance
must all consume the same app-owned contract.

## Why The Direction Is Locked

### Router direction

AutoRoute remains the target router, but the durable architecture is not “the
AutoRoute package.” The durable architecture is:

- app-owned route contracts,
- app-owned route-access decisions,
- app-owned screen/sentinel contracts,
- app-owned device state diagnostics,
- app-owned driver-safe action contracts.

GoRouter is not a co-equal long-term path. It is a temporary compatibility
layer that must be marked, tested, and retired behind replacement proof.

### State-management direction

Do **not** switch to Riverpod during this cutover.

The actual problem is not that Provider exists. The problem is that
`AuthProvider` and nearby routing/sync seams still carry too many
responsibilities at once: session, recovery, profile bootstrap, role policy,
freshness, route gating, and sync identity all move together through broad
notifier updates. Replacing Provider with Riverpod right now would create a
second major migration while we still have unresolved app-state boundaries.

The current branch direction is correct:

- keep `provider` / `ChangeNotifier`,
- finish decomposing the current broad state owners,
- make route, auth, sync, and driver consume narrower immutable snapshots,
- revisit Riverpod only after the unified contracts are working and proven on
  all four devices.

### Auth-platform direction

Do **not** replace Supabase Auth in this lane.

The app already depends heavily on Supabase sessions, user identity, and RLS:

- `AuthService` wraps Supabase sign-in, sign-out, recovery, password update,
  and session refresh.
- sync paths resolve `currentSession`, `currentUser`, `companyId`, and role
  from Supabase-backed seams.
- backend access control already assumes Supabase/RLS-style auth context.
- the current goal is stable real-device role testing, not an auth-platform
  migration.

Supabase already supports the future-oriented capabilities we care about:

- stronger password requirements and leaked-password protection,
- MFA in Flutter,
- audit logs,
- hooks for extra checks and claims,
- OAuth 2.1 / OIDC support,
- identity linking,
- federation to external providers later if needed.

That means the correct move now is to harden the app-owned auth boundary on
top of Supabase, not blow up the identity substrate while we are trying to
stabilize four-device live testing.

### What external auth research means for future work

Open-source IdPs like Keycloak or ZITADEL remain valid future options when the
product needs one of these specifically:

- enterprise SSO at scale,
- self-hosted identity ownership,
- broader cross-system IAM,
- directory federation,
- compliance or audit requirements beyond the current app lane.

But that is a future federation or migration spec. It is not the fix for the
current live-device failures.

## Audit Inputs

- `.codex/AGENTS.md`
- `.codex/Context Summary.md`
- `.codex/PLAN.md`
- `.codex/CLAUDE_CONTEXT_BRIDGE.md`
- `.codex/plans/2026-04-20-unified-routing-state-sync-soak-driver-spec.md`
- `.codex/plans/2026-04-20-autoroute-routing-provider-refactor-todo-spec.md`
- `.codex/plans/2026-04-19-four-role-sync-hardening-scale-up-spec.md`
- `.codex/plans/2026-04-18-sync-soak-unified-hardening-todo.md`
- `.codex/research/2026-04-19-router-red-screen-architecture-research.md`
- repo auth audit on 2026-04-20:
  `AuthService`, `AuthProvider`, `LoadProfileUseCase`, `RolePolicy`,
  `ProfileRefreshScheduler`, `RouteAccessSnapshot`, `RouteAccessController`,
  sync bootstrap/runtime auth seams
- official auth research on 2026-04-20:
  Supabase password security, sessions, MFA, audit logs, auth hooks,
  OAuth/OIDC, API/RLS security, Keycloak guides, ZITADEL docs

## Current Problems This Spec Owns

### Router and driver truth are still fragmented

- The app can select an AutoRoute host, but many app navigation paths still
  rely on GoRouter adapters or compatibility seams.
- Screen, route, sentinel, and action truth is still spread across route
  descriptors, GoRouter, AutoRoute, screen contracts, testing keys, generated
  PowerShell keys, and flow scripts.
- `/driver/ready` can still mean “transport reachable” instead of “the app is
  definitely at the correct interactive screen.”

### The state machine is not yet truly singular

- Dart derives posture in the app while host scripts historically derived
  posture independently.
- `/diagnostics/device_state` is improved, but the state machine still needs
  to be the uncontested posture/readiness source for every acceptance gate.
- Permission surfaces, launcher surfaces, ANR surfaces, consent states, and
  sign-in/post-sign-in limbo are not yet modeled as one canonical posture
  contract.

### Auth state is still too broad and volatile

- `AuthProvider` still behaves like a god seam: session user, password
  recovery, profile bootstrap, company, role booleans, freshness, loading, and
  error state all move through one notifier.
- Some route decisions still depend on broad auth/provider state rather than a
  narrow immutable access snapshot.
- Sync bootstrap and runtime still read presentation-owned auth state directly
  in places where they should read a stable auth/sync context.
- The app can reach transient states where sign-in is partially complete, but
  the router, sync bootstrap, and state machine do not all agree on what that
  means.

### Auth recovery and session validity need explicit modeling

- Password recovery is persisted locally and influences routing, but that
  recovery posture still needs a canonical validation rule so the app cannot be
  trapped by stale recovery state.
- Profile bootstrap, stale-session detection, reauth requirements, and pending
  approval are all route-relevant auth states and must be modeled directly,
  not inferred opportunistically from broad booleans.
- The current system still risks treating “email/password filled in”,
  “Supabase session created”, “profile loaded”, and “route-ready” as loosely
  related instead of ordered auth states.

### Four-device startup and live testing are still not honest enough

- Some invalid runs were allowed to get far enough even though a lane was on
  the launcher, not foregrounded, ANR-blocked, or still sitting at sign-in.
- Device setup has taken too long because lanes have not been forced into a
  concurrent readiness discipline.
- Backend/headless pressure can still be discussed together with UI-device
  evidence even though only device UI proves actual route state, local SQLite,
  `change_log`, sentinel visibility, and interactive correctness.

## Non-Negotiables

- [ ] Real sessions only; no `MOCK_AUTH`.
- [ ] Keep Supabase Auth as the auth platform for this refactor.
- [ ] Keep Provider / ChangeNotifier as the state-management library for this
  refactor.
- [ ] Device sync acceptance uses Sync Dashboard UI sync only.
- [ ] Direct `/driver/sync` is disqualifying for device UI acceptance.
- [ ] Backend/RLS-only success never satisfies device-sync acceptance.
- [ ] Headless app-sync success never satisfies device UI acceptance.
- [ ] Every accepted device action has route, screen, sentinel, auth-state,
  and posture proof.
- [ ] Every accepted run records screenshots, canonical device-state payloads,
  route-state payloads, runtime logs, logcat evidence, queue/conflict state,
  and cleanup obligations.
- [ ] Legacy route/state/driver/auth paths may exist temporarily only with
  explicit deprecation status, replacement, and removal condition.
- [ ] No second co-equal state machine may be introduced in app code or host
  scripts.

## Public Contracts

### Route Contract

- [x] Define `RouteContract` as the single driver-facing route truth.
- [x] Include route id, path template, required params, expected screen
  contract, expected root sentinel, shell/tab placement, access policy,
  backend support, and deprecation status.
- [ ] Expand the contract so every user flow forward/backward is covered:
  auth/onboarding, tabs, projects, entries/reports, forms, pay apps, sync,
  conflicts, trash, exports, settings, admin, help, gallery.
- [ ] Every driver-entered route must map to one app-owned route contract or
  fail loudly with a typed refusal.

### Route Access Contract

- [x] `RouteAccessPolicy` exists and is already shared between GoRouter and the
  AutoRoute slice.
- [ ] Finish removing direct feature-level route gating that still reaches into
  broad `AuthProvider` reads.
- [ ] Make route access depend on explicit immutable auth/profile/config/
  consent state, not on volatile notifier timing.
- [ ] Add route-access reasons for:
  signed out, authenticating, profile bootstrap pending, pending approval,
  missing display name, missing company, password recovery, force reauth,
  required update, missing consent, insufficient role.

### Auth State Contract

Define one canonical app-owned auth model that every routing, sync, and driver
surface reads.

- [x] Add immutable `AuthSessionState`.
- [x] Add immutable `ProfileState`.
- [x] Add immutable `SyncAuthContext`.
- [x] Expose sanitized auth diagnostics through device state:
  current auth session state, current profile state, route-access-relevant
  changed fields, recovery validity, last profile confirmation time, last
  profile refresh attempt, current company id, current role.

### Device State Contract

- [ ] `/diagnostics/device_state` is the canonical app-owned device state
  endpoint.
- [x] `stateMachine` is already emitted.
- [ ] Keep UI/app/data/sync/auth regions as inputs, but acceptance scripts may
  not re-derive posture from them.
- [ ] Add typed posture and blockers for:
  booting, app not foreground, launcher/home surface, sign-in required,
  sign-in submitting, profile bootstrap pending, consent blocked, permission
  modal blocked, update required, password recovery required, route missing,
  screen id missing, sentinel missing, sentinel not visible, Android surface
  blocked, sync unsafe, errored, tripped, route contract mismatch.
- [ ] Treat system permission prompts as canonical blocker states, not random
  obstacles outside the state machine.

### Driver Readiness Contract

- [ ] Treat `/driver/ready` as transport readiness only, or fold it into a
  richer readiness payload that embeds canonical device state.
- [ ] Startup readiness per lane must require:
  ADB visible, app process running, app foreground, driver reachable, router
  attached, device-state schema valid, expected posture, valid auth posture,
  route contract resolved, screen contract resolved, visible sentinel, clean
  or expected queue/conflict state, sync runtime idle where required, no
  unhandled permission modal, and clean Android surface.
- [ ] A lane that is merely reachable is not ready.
- [x] A lane sitting at sign-in after credentials entry but before completed
  auth/profile bootstrap must be classified explicitly and recoverable.

### Sync Auth Context Contract

- [x] Move sync bootstrap and lifecycle seams off presentation-owned auth
  reads and onto `SyncAuthContext`.
- [ ] Sync must not infer company or role ad hoc from whichever provider is
  easiest to read at that moment.
- [ ] Route reevaluation must not be churned by sync/runtime events unless a
  route-relevant auth/profile field actually changed.

## Ordered Todo

### Phase 0 - Freeze Drift And Reconcile Truth

- [x] Save this controlling spec in `.codex/plans/`.
- [x] Create an append-only checkpoint file for this lane.
- [x] Fold the old routing/provider spec, four-role scale-up spec, and auth
  audit findings into one continuation checklist.
- [x] Record the invalid recent facts that must remain rejected evidence:
  launcher-visible lanes, stale process/build state, ANR-blocked lanes, blind
  taps on the main screen, non-concurrent startup, and sign-in-limbo lanes.
- [x] Freeze new one-off harness features unless they directly serve the
  canonical route/state/auth/device contract.
- [x] Freeze any auth-platform migration discussion as out of scope for this
  lane except as future-facing notes.

### Phase 1 - Full User-Flow And Navigation Model

- [ ] Inventory every user journey forward and backward:
  login, forgot password, recovery, pending approval, company setup, profile
  setup, home/tabs, projects, project setup, daily entry/report, forms, pay
  apps, sync dashboard, conflicts, trash, exports, settings, help, admin.
- [ ] For each journey define:
  route entry, legal back behavior, shell/tab ownership, root sentinel,
  auth prerequisites, profile prerequisites, modal/permission states, driver-
  safe actions, and recovery path if interrupted.
- [ ] Convert the current AutoRoute slice from a package experiment into the
  app-owned route-contract slice.
- [ ] Finish migration by user-flow family instead of random file-by-file
  conversions.

### Phase 2 - One Auth And State Machine

- [x] Split the broad auth seam into smaller immutable runtime snapshots while
  keeping Provider.
- [x] Keep `AuthProvider` temporarily as a compatibility facade so migration
  can be incremental rather than destructive.
- [ ] Remove duplicate sign-in transition ownership so there is one canonical
  source for “auth complete.”
- [ ] Remove duplicate profile bootstrap triggers so there is one canonical
  source for “profile ready.”
- [ ] Make recovery posture explicit and validated. A stale local recovery flag
  must not trap routing.
- [ ] Ensure sign-out, force reauth, stale-session sign-out, and recovery
  completion all use one cleanup/notification contract.
- [ ] Finish the `RolePolicy` extraction so it is a pure stable policy object
  rather than a lightly wrapped snapshot of broad auth state.

### Phase 3 - Route Access And Router Reevaluation Hardening

- [ ] Finish removing volatile route reevaluation triggers such as profile
  loading churn when they are not part of the first auth bootstrap decision.
- [ ] Prevent sync dirty markers and background profile refreshes from causing
  router churn unless route-relevant fields changed.
- [ ] Add route-access diagnostics for previous and next snapshots, changed
  fields, last denial, and reevaluation source.
- [ ] Add hard tests proving route access behaves the same across GoRouter
  compatibility and AutoRoute.

### Phase 4 - Sync/Auth Boundary Cleanup

- [x] Replace direct sync bootstrap reads of presentation `AuthProvider` with
  `SyncAuthContext`.
- [ ] Ensure sync bootstrap, lifecycle runtime, FCM/realtime context, and
  background sync all consume the same stable auth context.
- [ ] Define exactly which auth/profile changes are sync-relevant and which are
  route-relevant, then separate their notifications.
- [ ] Make post-sync profile refresh go through the scheduler and compare
  snapshots before notifying route-facing listeners.

### Phase 5 - Driver Action Discipline And Permission Handling

- [ ] Keep canonical interaction readiness enforced for every mutating action.
- [ ] Add first-failure extraction for:
  guard denial, wrong route, wrong screen, missing sentinel, duplicate key,
  disabled consent action, permission modal blocker, launcher surface, stale
  router identity, stale auth posture, sign-in not completed, dirty build
  scope, red screen, black screen.
- [ ] Make permission prompts part of the canonical state machine and define
  driver-safe recovery actions for them.
- [ ] Ensure contracted scrolling is used where consent or other surfaces
  require it before buttons become enabled.

### Phase 6 - Four-Device Concurrent Startup Contract

- [ ] Startup all four lanes concurrently, not serially.
- [ ] Record a startup manifest per lane:
  build fingerprint, dart-defines hash, Supabase target, device serial, role,
  driver port, expected route, expected screen, expected sentinel, expected
  auth posture, and app-data reset policy.
- [ ] Require every lane to converge to the same expected readiness class at
  roughly the same startup stage before any pressure begins.
- [ ] Explicitly classify these startup outcomes:
  ready, launcher/home, sign-in required, sign-in submitting, auth session
  created but profile pending, pending approval, consent blocked, permission
  blocked, route mismatch, sentinel mismatch, ANR/errored.
- [ ] Refuse pressure start if any lane is outside the accepted readiness set.

### Phase 7 - Full AutoRoute Cutover

- [ ] Convert auth/onboarding routes.
- [ ] Convert primary tabs.
- [ ] Convert project flows.
- [ ] Convert report/editor flows.
- [ ] Convert forms.
- [ ] Convert pay apps.
- [ ] Convert sync/conflicts/trash/export flows.
- [ ] Convert settings/admin/help/legal/profile flows.
- [ ] Remove GoRouter dependency only after route-contract parity, driver
  parity, screenshot proof, and four-device proof pass.
- [ ] Add lints so production features and design-system surfaces do not import
  router packages directly.

### Phase 8 - Live Four-Device Proof Before Scale

- [ ] Run S21, second Samsung/tablet, emulator-5554, and emulator-5556 as
  fixed role lanes with real live accounts from secrets.
- [ ] Prove all four can sign in, complete auth bootstrap, and reach the
  intended ready screens through the same canonical route/auth/state machine.
- [ ] Prove the state machine detects and recovers:
  launcher posture, sign-in screen, partially completed sign-in, pending
  profile bootstrap, consent, and permission prompts.
- [ ] Run no-pressure four-device proof first.
- [ ] Only after that, add backend/headless pressure in parallel while keeping
  evidence layers strictly separated.

### Phase 9 - Auth Security Hardening Inside This Lane

- [ ] Audit current Supabase Auth project settings against the app’s actual
  posture:
  password strength, leaked-password protection, session lifetime, inactivity
  timeout, single-session behavior, audit-log availability.
- [ ] Decide and document the intended session policy for real-device testing
  so test instability is not caused by unclear auth expiration rules.
- [ ] Add audit-log checks to the auth debugging/evidence flow where useful.
- [ ] Keep MFA as a planned additive feature after four-device stability, not a
  precondition to this reset.
- [ ] Document the future path for OAuth/OIDC federation through Supabase if
  enterprise auth becomes an active requirement later.

### Phase 10 - Pressure, Faults, And Release-Hardening

- [ ] Reintroduce backend/headless pressure only after four-device no-pressure
  proof is green.
- [ ] Add backend-to-device marker proof after deterministic route/auth/device
  state passes.
- [ ] Add concurrent backend/RLS and headless app-sync pressure while device UI
  actors run real flows.
- [ ] Add offline/reconnect, force-stop restart, auth-refresh, and expected
  denial windows.
- [ ] Add final quiescence and reconciliation checks.
- [ ] Require clean evidence separation across device UI, backend/RLS, and
  headless app-sync layers.

## Test Plan

- [ ] Route-contract tests for all user-flow families.
- [ ] Route-access tests across signed-out, authenticating, authenticated,
  recovery, reauth, pending approval, missing company, missing display name,
  insufficient role, and consent/update-required states.
- [ ] Auth-state tests for canonical session transitions.
- [ ] Recovery tests proving stale local recovery state cannot trap routing.
- [ ] Sign-in tests proving one canonical post-login bootstrap path.
- [ ] Sign-out tests proving one canonical cleanup path.
- [ ] Profile/bootstrap tests proving route reevaluation only changes on
  route-relevant fields.
- [ ] Sync/auth integration tests proving sync consumes only `SyncAuthContext`.
- [ ] PowerShell/device-state schema tests for canonical posture consumption.
- [ ] Driver behavior tests for permission modal blockers, consent blockers,
  sign-in-limbo classification, and launcher classification.
- [ ] S21 physical route/auth/state smoke.
- [ ] Second physical Samsung/tablet route/auth/state smoke.
- [ ] Two-emulator route/auth/state smoke.
- [ ] Four-device concurrent no-pressure live proof.
- [ ] Four-device concurrent live proof with backend/headless pressure after
  the no-pressure gate is accepted.

## Auth Research Addendum - 2026-04-20

### Confirmed current auth shape

- `AuthService` is the Supabase transport owner.
- `AuthProvider` still combines too many responsibilities.
- `LoadProfileUseCase` already contains useful stale-session and offline-cache
  behavior, but its output still feeds broad notifier updates.
- `RolePolicy` and `ProfileRefreshScheduler` are directionally correct, but the
  extraction is not complete enough yet.
- route access is partly centralized, but direct feature-level auth reads still
  exist.
- sync still depends on auth state through multiple broad seams.

### Research-backed decisions

- [x] Do not migrate to Riverpod now.
- [x] Do not replace Supabase Auth now.
- [x] Harden the app-owned auth/session/profile/role boundary now.
- [x] Preserve the future option to add OAuth/OIDC federation through Supabase
  later if enterprise SSO becomes active.
- [x] Preserve the future option to evaluate Keycloak or ZITADEL only when
  enterprise identity requirements genuinely outrun Supabase Auth.

### Sources

- [Supabase Password Security](https://supabase.com/docs/guides/auth/password-security)
- [Supabase Sessions](https://supabase.com/docs/guides/auth/sessions)
- [Supabase Flutter MFA](https://supabase.com/docs/reference/dart/auth-mfa-api)
- [Supabase OAuth 2.1 / OIDC](https://supabase.com/docs/guides/auth/oauth-server/oauth-flows)
- [Supabase Auth Hooks](https://supabase.com/docs/guides/auth/auth-hooks)
- [Supabase Audit Logs](https://supabase.com/docs/guides/auth/audit-logs)
- [Supabase API Security / RLS](https://supabase.com/docs/guides/api/securing-your-api)
- [Keycloak Guides](https://www.keycloak.org/guides)
- [ZITADEL Docs](https://zitadel.com/docs)
