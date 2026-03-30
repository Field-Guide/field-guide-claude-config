# Auth Offline Behavior Constraints

## Hard Rules (Violations = Reject Proposal)
- ✗ MUST cache tokens in encrypted secure storage (Secure Storage, NOT SharedPreferences)
- ✗ MUST NOT refresh tokens while offline
- ✗ MUST maintain session atomicity (sign-in success = token + user stored together)
- ✗ MUST NOT allow sign-in attempts without network (graceful "offline mode" message)
- ✗ MUST clear tokens on sign-out (regardless of network state)

## Soft Guidelines (Violations = Discuss)
- ⚠ Cache tokens with 24-hour validity window (for offline session recovery)
- ⚠ Attempt token refresh immediately on network return
- ⚠ Log auth transitions (offline → online, refresh success/fail)
- ⚠ Performance target: sign-in < 3 seconds (network), sign-out < 500ms (offline-capable)

## Consent Gate
- Router checks `ConsentProvider` before granting access to protected routes
- Users must accept Terms of Service / Privacy Policy before proceeding past auth

## Multi-Tenant Company Flow
- `CompanySetupScreen`: new users create or join a company after sign-up
- `PendingApprovalScreen`: users awaiting admin approval see a blocking screen
- Admin approval required before a user can access company data
- `SwitchCompanyUseCase`: allows users belonging to multiple companies to change active company

## Security Hard Rules (Multi-Tenant)
- **company_id MUST come from JWT `app_metadata`, NEVER from client payload** — client-supplied company_id enables tenant impersonation
- **Admin approval status MUST be validated server-side via RLS/functions, not just client-side provider state** — client-only checks can be bypassed
- **Company switching MUST trigger session refresh to update JWT claims** — stale JWT after switch = wrong tenant context in RLS policies

## Integration Points
- **Depends on**: None (foundational)
- **Required by**: All features (gating auth state via AuthProvider), ConsentProvider (consent gate)

## Performance Targets
- Sign-in (online): < 3 seconds
- Sign-out (offline or online): < 500ms
- Token cache retrieval: < 50ms
- Session recovery on reconnect: < 2 seconds

## Testing Requirements
- >= 85% test coverage
- Unit tests: token caching, encryption, session lifecycle
- Integration tests: offline sign-out, reconnect recovery, failed refresh
- Edge case: expired cache on reconnect (should refresh or force re-login)
- Edge case: network loss during sign-in (rollback local state)

## References
- See `feature-auth-architecture.md` for session management details
- See `feature-auth-overview.md` for deep linking flows
- See `auth-supabase-auth.md` for Supabase SDK integration
