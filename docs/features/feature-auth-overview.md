---
feature: auth
type: overview
scope: Authentication, Authorization, Company Management, Profile Management, Onboarding
updated: 2026-04-07
---

# Auth Feature Overview

## Purpose

The auth feature manages Supabase authentication, company membership, profile
hydration, onboarding, and app-config gating. It remains the root feature that
establishes user, company, and role context for the rest of the app.

## Key Responsibilities

- sign-up / sign-in / sign-out
- profile and company hydration
- capability getters used by downstream features
- password recovery and OTP verification
- onboarding flows
- remote config and minimum-version gating

## Current UI Structure

- `auth_providers.dart` owns long-lived auth providers and services
- `auth_screen_providers.dart` owns screen-local controller scopes
- `AuthProvider` is split into focused part files instead of one monolithic implementation
- `AppConfigProvider` keeps versioning logic extracted in `app_config_provider_versioning.dart`

## Key Files

| File | Purpose |
|------|---------|
| `lib/features/auth/di/auth_providers.dart` | Root auth DI wiring |
| `lib/features/auth/di/auth_screen_providers.dart` | Screen-local auth controller scopes |
| `lib/features/auth/presentation/providers/auth_provider.dart` | Root auth state and capabilities |
| `lib/features/auth/presentation/providers/app_config_provider.dart` | Remote config and force-update state |
| `lib/features/auth/presentation/controllers/company_setup_controller.dart` | Company onboarding controller |
| `lib/features/auth/presentation/controllers/otp_verification_controller.dart` | OTP screen controller |

## Integration Points

- Every feature consumes auth capability state through `AuthProvider`
- sync depends on auth context before remote work starts
- settings depends on auth for profile, consent, and sign-out surfaces
