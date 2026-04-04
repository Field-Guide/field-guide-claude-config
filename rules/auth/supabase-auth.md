---
paths:
  - "lib/features/auth/**/*.dart"
  - "lib/core/config/supabase_config.dart"
---

# Auth Service Guidelines

## Common Commands
```bash
npx supabase status               # Check Supabase status
npx supabase db reset             # Reset database (dev only!)
npx supabase functions list       # List edge functions
```

## Auth Screens (10 total)

| # | Screen | Route | Purpose |
|---|--------|-------|---------|
| 1 | `LoginScreen` | `/login` | Email + password sign-in |
| 2 | `RegisterScreen` | `/register` | New account creation |
| 3 | `ForgotPasswordScreen` | `/forgot-password` | Request OTP via email |
| 4 | `OtpVerificationScreen` | `/otp-verification` | Enter 6-digit OTP for password recovery |
| 5 | `UpdatePasswordScreen` | `/update-password` | Set new password after OTP verification |
| 6 | `ProfileSetupScreen` | `/profile-setup` | Name, role — first-time onboarding |
| 7 | `CompanySetupScreen` | `/company-setup` | Create or join a company |
| 8 | `PendingApprovalScreen` | `/pending-approval` | Wait for admin to approve join request |
| 9 | `AccountStatusScreen` | `/account-status` | Blocked/suspended account message |
| 10 | `UpdateRequiredScreen` | `/update-required` | Force-upgrade gate |

## Code Style

### AuthService Pattern
```dart
class AuthService {
  final SupabaseClient _client;

  Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange.map((data) => data.session);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  User? get currentUser => _client.auth.currentUser;
}
```

### AuthProvider Pattern
```dart
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService) {
    _authService.authStateChanges().listen((session) {
      _user = session?.user;
      notifyListeners();
    });
  }

  bool get isAuthenticated => _user != null;
  User? get user => _user;
}
```

## Dependency Injection

Auth dependencies use a **typed DI container**, not direct Provider registration:

1. `AuthInitializer.create(coreDeps)` returns an `AuthDeps` instance (`lib/features/auth/di/auth_initializer.dart`)
2. `AuthDeps` is defined in `lib/core/di/app_dependencies.dart`
3. Contains: `AuthService`, `AuthProvider`, `AppConfigProvider`, `CompanyLocalDatasource`
4. `AuthDeps` is bundled into `AppDependencies` and wired into the provider tree by `buildAppProviders()`

Do NOT construct auth services or providers ad-hoc. Always go through the `AuthDeps` container.

## Use Cases

The auth feature has a use case layer (`lib/features/auth/domain/usecases/`):

| Use Case | Responsibility |
|----------|---------------|
| `SignInUseCase` | Email/password sign-in via AuthService |
| `SignOutUseCase` | Sign-out + preference cleanup |
| `SignUpUseCase` | New account registration |
| `LoadProfileUseCase` | Fetch/cache user profile + company data |
| `CheckInactivityUseCase` | Session timeout detection |
| `MigratePreferencesUseCase` | Legacy preference migration on auth events |

These are injected into `AuthProvider` by `AuthInitializer` -- not created inline.

## State Management

This app uses the `provider` package (`ChangeNotifier` + `context.read` / `context.watch`).
**NOT Riverpod** — do not use `ref.read()` or `ref.watch()` anywhere.

### Provider Access Pattern
```dart
// One-time read / action dispatch (no rebuild)
context.read<AuthProvider>().signOut();

// Reactive — rebuilds widget on change
final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
```

### Auth State Flow
```
App Start -> Check Session ->
  -> Has Session -> Consent gate -> Load User -> Home
  -> No Session -> Login Screen
```

### Protected Routes
```dart
redirect: (context, state) {
  final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
  if (!isAuthenticated && !publicRoutes.contains(state.location)) {
    return '/login';
  }
  return null;
}
```

## Consent Gate

`AppRouter` injects a `ConsentProvider` and checks it in the `redirect` callback **after** the
auth check. If the user is authenticated but has not accepted the current policy version, every
route is redirected to `/consent`.

```
Authenticated? ──No──> /login
     │
    Yes
     │
Consented? ──No──> /consent
     │
    Yes
     │
Normal routing continues
```

Key details:
- `ConsentProvider` lives under **settings**, not auth: `lib/features/settings/presentation/providers/consent_provider.dart`
- `ConsentProvider` is merged into `refreshListenable` so the router re-evaluates on consent change.
- The `/consent` route is in `_onboardingRoutes` so the onboarding check does not block it.
- `ConsentProvider` is optional (constructor default `null`) for backward compatibility with tests.
- Once the user accepts, `ConsentProvider.hasConsented` returns `true` and the router redirects to the intended destination.

## Auth State Listener (App-Level Side Effects)

**CRITICAL:** The auth state listener that drives sync lifecycle lives in `AppInitializer`
(`lib/core/bootstrap/app_initializer.dart`), NOT in the auth feature itself. It is wired via
`authDeps.authProvider.addListener(...)` during initialization.

Side effects by auth event:
- **Sign-out:** clears `AppConfigProvider`, `ProjectSyncHealthProvider`, `ProjectImportRunner`,
  `ProjectAssignmentProvider`; disposes `RealtimeHintHandler`; cancels FCM context
- **Sign-in:** re-initializes `ProjectSettingsProvider` for the user; updates FCM context;
  creates or rebinds `RealtimeHintHandler`; triggers startup sync if auth context is newly ready
- **Company change (while authenticated):** rebinds `RealtimeHintHandler` to the new company channel;
  triggers a follow-up sync

When modifying sign-out or sign-in behavior, check BOTH the auth feature code AND
`app_initializer.dart` for stateful wiring.

## Multi-Tenant Company Flow

New users go through a linear onboarding sequence after account creation:

```
Register -> ProfileSetupScreen -> CompanySetupScreen
                                        │
                        ┌───────────────┴────────────────┐
                        │                                │
               Create new company               Search & join existing
                        │                                │
                   Immediately                   PendingApprovalScreen
                   enters app                  (polls with exponential
                                                backoff: 5s → 60s max)
                                                         │
                                              Admin approves in dashboard
                                                         │
                                                    Enters app
```

### CompanySetupScreen
- Allows creating a new company (user becomes admin) or searching for an existing company to join.
- On create: submits company registration, user is granted admin role, proceeds to home.
- On join: submits a join request, routes to `PendingApprovalScreen` with `requestId` + `companyName`.

### PendingApprovalScreen
- Receives `requestId` and `companyName` as route parameters.
- Polls join-request status using exponential backoff (starts at 5 s, doubles, caps at 60 s).
- On approval: router detects updated auth state and redirects to home.
- On denial: shows rejection message with option to try another company.

### Admin Approval Flow
- Admins see pending join requests in the Settings / Company management section.
- Approval/denial is written to Supabase; `PendingApprovalScreen` polling detects the change.
- RLS ensures only company admins can approve requests for their own company.

## OTP Verification Flow

Password-recovery uses a 6-digit OTP code rather than a magic link, so it works in environments
where deep links may not be intercepted by the app.

```
ForgotPasswordScreen  ──submits email──>  Supabase sends OTP email
        │
        └──routes to──> OtpVerificationScreen(email: ...)
                                │
                    User enters 6-digit code
                                │
              AuthProvider.verifyRecoveryOtp() called
                                │
                   Supabase fires passwordRecovery event
                                │
                  Router detects _isPasswordRecovery == true
                                │
                  Redirects to UpdatePasswordScreen
```

### OtpVerificationScreen details
- Accepts `email` as a required constructor parameter (passed via route extra).
- Renders 6 individual digit fields with auto-focus progression.
- 60-second cooldown timer before "Resend code" is available.
- Calls `AuthProvider.verifyRecoveryOtp(email, otp)` on auto-submit when all 6 digits are filled.

### PASSWORD_RECOVERY Event Pattern
```dart
// In AuthProvider — listen for recovery event BEFORE updating _currentUser
_authSubscription = _authService.authStateChanges.listen((state) {
  if (state.event == AuthChangeEvent.passwordRecovery) {
    _isPasswordRecovery = true;
    _currentUser = state.session?.user;
    notifyListeners();
    return; // Skip profile load — user must update password first
  }
  // ... normal auth state handling
});
```

## Deep Linking

### Callback URL
```
com.fieldguideapp.inspector://login-callback
```

> **Important**: Deep link token exchange is handled by `supabase_flutter` when
> `AuthFlowType.pkce` is configured. Do not add custom deep link handlers.
> The library intercepts the deep link, exchanges the PKCE code for tokens,
> and fires the appropriate `AuthChangeEvent` (e.g., `passwordRecovery`).

## Security

### Token Storage
- Use `flutter_secure_storage` for tokens
- Never log tokens or credentials
- Clear on sign out

### Password Requirements
- Enforced client-side by `PasswordValidator` (`lib/features/auth/services/password_validator.dart`)
- Rules: min 8 chars, at least 1 uppercase, 1 lowercase, 1 digit
- Mirrors `supabase/config.toml` settings (`password_requirements = "lower_upper_letters_digits"`)
- Use `PasswordValidator.validate(value)` in form fields; do NOT rely on Supabase-side validation alone

### Dialog Sign-Out Safety

**CRITICAL:** When signing out from inside a dialog, ALWAYS `Navigator.pop(dialogContext)` BEFORE
calling `auth.signOut()`. GoRouter's redirect fires synchronously on auth state change. If the
dialog is still mounted when the route stack is replaced, the navigator crashes. Pattern:

```dart
Navigator.pop(dialogContext);
context.read<AuthProvider>().signOut();
```

Never reverse this order.

### Rate Limiting
- Configure in Supabase dashboard
- Handle 429 errors gracefully

## Error Handling
```dart
try {
  await _authService.signIn(email, password);
} on AuthException catch (e) {
  _error = _parseAuthError(e.message);
  notifyListeners();
}

String _parseAuthError(String message) {
  if (message.contains('Invalid login')) return 'Invalid email or password';
  if (message.contains('Email not confirmed')) return 'Please verify your email';
  return 'Authentication failed';
}
```

## Logging
```dart
Logger.auth('AUTH: User signed in: ${user?.email}');
// NEVER log passwords or tokens
```

## Debugging
```dart
// Check current session
Logger.auth('Session: ${Supabase.instance.client.auth.currentSession}');
// Check user
Logger.auth('User: ${Supabase.instance.client.auth.currentUser?.email}');
```

## Pull Request Template
```markdown
## Auth Changes
- [ ] Auth flow affected: Login/Register/Reset/Logout
- [ ] Deep linking tested
- [ ] Token handling secure
- [ ] Error messages user-friendly

## Security Checklist
- [ ] No credentials in logs
- [ ] No hardcoded secrets
- [ ] Rate limiting considered
- [ ] Session handling correct
```
