---
feature: auth
type: architecture
scope: User Authentication & Session Management
updated: 2026-04-07
---

# Auth Feature Architecture

## Directory Structure

```text
lib/features/auth/
├── di/
│   ├── auth_providers.dart
│   └── auth_screen_providers.dart
├── services/
├── data/
├── domain/
└── presentation/
    ├── providers/
    │   ├── auth_provider.dart
    │   ├── auth_provider_auth_actions.dart
    │   ├── auth_provider_company_profile_actions.dart
    │   ├── auth_provider_mock_actions.dart
    │   ├── auth_provider_recovery_actions.dart
    │   ├── auth_provider_security_actions.dart
    │   ├── app_config_provider.dart
    │   └── app_config_provider_versioning.dart
    ├── controllers/
    │   ├── company_setup_controller.dart
    │   └── otp_verification_controller.dart
    ├── screens/
    └── widgets/
```

## Root DI vs Screen DI

### `di/auth_providers.dart`

Root feature/provider wiring:
- `AuthProvider`
- `AppConfigProvider`
- `AuthService`
- auth-gated admin wiring owned by settings/auth startup composition

### `di/auth_screen_providers.dart`

Screen-local controller scopes:
- `CompanySetupControllerScope`
- `OtpVerificationControllerScope`

The screen scope files are the composition roots for short-lived UI state.
Screens should consume these scopes instead of constructing controllers inline.

## Providers

### AuthProvider

`AuthProvider` remains the root auth state owner, but it is no longer a single
monolithic file. Responsibilities are split across focused part files:
- auth actions
- company/profile actions
- mock-auth actions
- recovery actions
- security actions

Core responsibilities:
- session and current-user state
- user profile and company hydration
- role/capability getters (`canManageProjects`, `canEditFieldData`, etc.)
- sign-in, sign-up, sign-out, and recovery flows
- inactivity-check integration

### AppConfigProvider

`AppConfigProvider` now keeps versioning/force-update logic in
`app_config_provider_versioning.dart` so remote config loading and version gate
behavior do not collapse back into one god class.

## Controllers

Screen-local state now lives in dedicated controllers rather than being pushed
down into large auth screens:
- `CompanySetupController`
- `OtpVerificationController`

This keeps onboarding screens thin and keeps controller APIs easy to expose
through screen-level composition roots.

## Key Patterns

### Capability Callbacks

Downstream features still depend on auth through capability callbacks such as:
- `canManageProjects`
- `canEditFieldData`
- `canEditEntry`
- `canDeleteProject`

That preserves authorization without leaking auth-state internals into domain
or presentation peers.

### Company Context

`AuthProvider` remains the source of truth for user/company context. Feature
reloads and sync enrollment decisions should still respond to auth/company
changes from this provider rather than querying auth state ad hoc.

### Screen Composition

Controllers that exist only for a single auth screen belong in
`auth_screen_providers.dart`, not in `auth_providers.dart`. The root provider
file is reserved for long-lived feature services and providers.

## Key Files

- `lib/features/auth/di/auth_providers.dart`
- `lib/features/auth/di/auth_screen_providers.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/auth/presentation/providers/app_config_provider.dart`
- `lib/features/auth/presentation/controllers/company_setup_controller.dart`
- `lib/features/auth/presentation/controllers/otp_verification_controller.dart`
- `lib/features/auth/services/auth_service.dart`
- `lib/features/auth/domain/usecases/load_profile_use_case.dart`
