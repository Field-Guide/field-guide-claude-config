## Phase 4: Auth Domain Layer (Heaviest Extraction)

Break AuthProvider (977 lines, 48 methods) into focused use cases. Fix 4 layer violations where presentation code calls Supabase/SQLite directly.

**Depends on:** Phase 3 (repository pattern established)

---

### Sub-phase 4.1: Create AppConfigRepository (Fix AppConfigProvider violation)

**Files:**
- `lib/features/auth/data/repositories/app_config_repository.dart` (NEW)
- `lib/features/auth/presentation/providers/app_config_provider.dart` (EDIT)
- `lib/main.dart` (EDIT — wire repository into provider)

**Agent:** auth-agent

**What:**
1. Create `AppConfigRepository` in `lib/features/auth/data/repositories/`:
   - Constructor takes `SupabaseClient?` (nullable for offline/unconfigured)
   - Method: `Future<Map<String, String>> fetchConfig({Duration timeout})` — wraps the `Supabase.instance.client.from('app_config').select()` call currently at `app_config_provider.dart:148-156`
   - Returns `Map<String, String>` of key-value pairs (same shape as current `configMap`)
2. Edit `AppConfigProvider`:
   - Add `AppConfigRepository` constructor parameter
   - Replace `Supabase.instance.client.from('app_config').select()` at line 148 with `_repository.fetchConfig(timeout: _fetchTimeout)`
   - Remove `import 'package:supabase_flutter/supabase_flutter.dart'`
   - Remove `import 'package:construction_inspector/core/config/supabase_config.dart'` — move the `isConfigured` check into the repository
3. Wire in `main.dart` — construct `AppConfigRepository` with `Supabase.instance.client` and pass to `AppConfigProvider`

**Verify:** `pwsh -Command "flutter analyze"` — no `Supabase.instance` references in `app_config_provider.dart`

---

### Sub-phase 4.2: Fix SettingsScreen Direct Supabase Calls

**Files:**
- `lib/features/auth/data/repositories/user_profile_repository.dart` (EDIT — add remote update methods)
- `lib/features/auth/data/datasources/remote/user_profile_remote_datasource.dart` (EDIT — add update methods)
- `lib/features/settings/presentation/screens/settings_screen.dart` (EDIT)

**Agent:** frontend-flutter-specialist-agent

**What:**
1. Add to `UserProfileRemoteDatasource`:
   - `Future<void> updateGaugeNumber(String userId, String gaugeNumber)` — wraps the Supabase call at `settings_screen.dart:72-75`
   - `Future<void> updateInitials(String userId, String? initials)` — wraps the call at `settings_screen.dart:118-124`
2. Add `UserProfileRemoteDatasource` as a second constructor parameter to `UserProfileRepository`:
   - `UserProfileRepository(this._localDatasource, {UserProfileRemoteDatasource? remoteDatasource})`
   - Add methods: `updateGaugeNumber(String userId, String gaugeNumber)` and `updateInitials(String userId, String? initials)` — delegate to remote datasource, include `updated_at` timestamp
3. Edit `SettingsScreen`:
   - Add `UserProfileRepository` via `context.read<UserProfileRepository>()` (must be provided in widget tree — check `main.dart`)
   - Replace `_editGaugeNumber` Supabase call (lines 72-75) with `userProfileRepository.updateGaugeNumber(userId, result)`
   - Replace `_editInitials` Supabase call (lines 118-124) with `userProfileRepository.updateInitials(userId, result.isEmpty ? null : result)`
   - Remove `import 'package:supabase_flutter/supabase_flutter.dart'`
4. If `UserProfileRepository` is not already provided in the widget tree, add it to `main.dart`

**SECURITY:** Preserve the `updated_at` timestamp behavior — both current calls set `DateTime.now().toUtc().toIso8601String()`. The repository methods must do the same.

**Verify:** `pwsh -Command "flutter analyze"` — no `Supabase.instance` references in `settings_screen.dart`

---

### Sub-phase 4.3: Fix AuthProvider Company-Switch Direct DB Query

**Files:**
- `lib/features/auth/data/repositories/company_repository.dart` (EDIT)
- `lib/features/auth/presentation/providers/auth_provider.dart` (EDIT)

**Agent:** auth-agent

**What:**
1. Add method to `CompanyRepository`:
   - `Future<String?> getCachedCompanyId()` — queries local companies table, returns first company's ID or null
   - Implementation: `final company = await getMyCompany(); return company?.id;`
   - This replaces the raw `db.query('companies', limit: 1)` at `auth_provider.dart:324`
2. Edit `AuthProvider.signIn()` (lines 319-336):
   - Replace `final db = await dbService.database; final cachedCompanies = await db.query('companies', limit: 1);` with `final cachedCompanyId = await _companyRepository?.getCachedCompanyId();`
   - Remove the intermediate `cachedCompanyId` extraction from `cachedCompanies.first['id']`
   - Update the comparison: `if (guardProfile != null && guardProfile.companyId != null && cachedCompanyId != null && guardProfile.companyId != cachedCompanyId)`
   - Remove `_databaseService` usage from signIn — it should only go through repositories

**SECURITY INVARIANT:** The `clear local data BEFORE switching company` logic at line 331 (`AuthService.clearLocalCompanyData(dbService)`) must be preserved exactly. Only the *read* is being moved to repository; the clear still needs `DatabaseService` (it wipes multiple tables).

**Verify:** `pwsh -Command "flutter analyze"`

---

### Sub-phase 4.4: Extract Auth Use Cases (Sign In / Sign Up / Sign Out)

**Files:**
- `lib/features/auth/domain/use_cases/sign_in_use_case.dart` (NEW)
- `lib/features/auth/domain/use_cases/sign_up_use_case.dart` (NEW)
- `lib/features/auth/domain/use_cases/sign_out_use_case.dart` (NEW)
- `lib/features/auth/presentation/providers/auth_provider.dart` (EDIT)

**Agent:** auth-agent

**What:**
1. Create `lib/features/auth/domain/use_cases/` directory
2. **SignInUseCase:**
   - Dependencies: `AuthService`, `CompanyRepository`, `DatabaseService?`
   - Method: `Future<SignInResult> execute({required String email, required String password})`
   - Extract lines 306-365 from `AuthProvider.signIn()` — the actual auth call, company-switch guard, and error handling
   - Return type `SignInResult` (sealed class or simple class with `user`, `guardProfile`, `error` fields)
   - AuthProvider.signIn() becomes: call use case, set state from result, call loadUserProfile
3. **SignUpUseCase:**
   - Dependencies: `AuthService`
   - Method: `Future<SignUpResult> execute({required String email, required String password, String? fullName})`
   - Extract lines 256-289 from `AuthProvider.signUp()`
4. **SignOutUseCase:**
   - Dependencies: `AuthService`, `PreferencesService?`, `FlutterSecureStorage`
   - Method: `Future<bool> execute()`
   - Extract lines 379-400 from `AuthProvider.signOut()` — the actual signOut call, BackgroundSyncHandler.dispose(), secure storage clear
   - Also used by `signOutLocally()` and `forceReauthOnly()` (shared cleanup logic)

**Key decisions:**
- AuthProvider remains the ChangeNotifier state holder — use cases are stateless operation objects
- Mock auth branching stays in AuthProvider (it's a test concern, not domain logic)
- Use cases do NOT call `notifyListeners()` — AuthProvider does that after calling the use case
- `_parseAuthError` and `_parseOtpError` stay on AuthProvider (presentation-layer error mapping)

**Verify:** `pwsh -Command "flutter analyze"`

---

### Sub-phase 4.5: Extract Profile & Company Use Cases

**Files:**
- `lib/features/auth/domain/use_cases/load_profile_use_case.dart` (NEW)
- `lib/features/auth/domain/use_cases/switch_company_use_case.dart` (NEW)
- `lib/features/auth/domain/use_cases/migrate_preferences_use_case.dart` (NEW)
- `lib/features/auth/presentation/providers/auth_provider.dart` (EDIT)

**Agent:** auth-agent

**What:**
1. **LoadProfileUseCase:**
   - Dependencies: `AuthService`, `CompanyRepository`, `PreferencesService?`, `DatabaseService?`
   - Method: `Future<LoadProfileResult> execute(String userId, {UserProfile? preloadedProfile})`
   - Extract lines 554-685 from `loadUserProfile()` — remote fetch, legacy migration, company persistence, offline fallback
   - Return type includes: `userProfile`, `company`, `shouldSignOut` (for stale session detection)
   - AuthProvider.loadUserProfile() becomes: call use case, set `_userProfile`/`_company` from result, cache in attributionRepository
2. **SwitchCompanyUseCase:**
   - Dependencies: `CompanyRepository`, `DatabaseService`, `AuthService`
   - Method: `Future<bool> detectAndHandle(String userId, UserProfile? guardProfile)`
   - Extract the company-switch guard from signIn (lines 319-343) into a reusable check
   - **SECURITY:** `AuthService.clearLocalCompanyData(dbService)` MUST execute before any profile is set. The use case returns `true` if a switch was detected (caller discards guardProfile)
3. **MigratePreferencesUseCase:**
   - Dependencies: `AuthService`, `PreferencesService`
   - Method: `Future<UserProfile> execute(UserProfile remoteProfile)`
   - Extract lines 570-615 from loadUserProfile — the cert/phone/name migration logic
   - Returns the (possibly migrated) profile

**SECURITY INVARIANTS:**
- SwitchCompanyUseCase: clear MUST happen before profile set — enforced by returning a result that the caller acts on
- LoadProfileUseCase: stale session detection triggers signOut — use case returns `shouldSignOut: true`, AuthProvider calls signOut()
- Offline fallback: if remote fetch fails, use case queries local DB — preserves admin permissions for offline cold start

**Verify:** `pwsh -Command "flutter analyze"`

---

### Sub-phase 4.6: Extract Inactivity & Mock Auth Use Cases

**Files:**
- `lib/features/auth/domain/use_cases/check_inactivity_use_case.dart` (NEW)
- `lib/features/auth/presentation/providers/auth_provider.dart` (EDIT)

**Agent:** auth-agent

**What:**
1. **CheckInactivityUseCase:**
   - Dependencies: `FlutterSecureStorage`
   - Method: `Future<bool> execute()` — returns true if timeout exceeded (caller should sign out)
   - Method: `Future<void> updateLastActive()` — updates timestamp
   - Extract lines 884-916 from AuthProvider
   - Static `inactivityThreshold` of 7 days stays as a constant
   - **SECURITY:** The use case only *checks*. AuthProvider calls `signOut()` if result is true. This preserves the "force sign-out" guarantee without the use case needing auth dependencies.
2. **Mock auth stays on AuthProvider** — it's purely a test/development concern (gated by `TestModeConfig.useMockAuth`). The 4 mock methods (`_initMockAuth`, `_mockSignIn`, `_mockSignOut`, `_mockSignUp`, `_mockResetPassword`) total ~100 lines and are already well-isolated with the `if (TestModeConfig.useMockAuth)` guards. Extracting them into a strategy object adds indirection without architectural benefit since they only exist in debug builds.
3. Update AuthProvider:
   - Replace `checkInactivityTimeout()` body with: `final timedOut = await _checkInactivityUseCase.execute(); if (timedOut) await signOut(); return timedOut;`
   - Replace `updateLastActive()` body with delegation to use case
   - Remove `_secureStorage` field and `_inactivityThreshold` constant from AuthProvider (moved to use case)
   - Keep `_clearSecureStorageOnSignOut()` on AuthProvider since it's called from multiple sign-out paths and is 5 lines

**Verify:** `pwsh -Command "flutter analyze"`

---

### Sub-phase 4.7: Wire Use Cases in main.dart & Update AuthProvider Constructor

**Files:**
- `lib/main.dart` (EDIT)
- `lib/features/auth/presentation/providers/auth_provider.dart` (EDIT)

**Agent:** auth-agent

**What:**
1. Update `AuthProvider` constructor to accept use cases:
   ```dart
   AuthProvider(
     this._authService, {
     PreferencesService? preferencesService,
     DatabaseService? databaseService,
     CompanyRepository? companyRepository,
     SignInUseCase? signInUseCase,
     SignOutUseCase? signOutUseCase,
     SignUpUseCase? signUpUseCase,
     LoadProfileUseCase? loadProfileUseCase,
     CheckInactivityUseCase? checkInactivityUseCase,
   })
   ```
   - Use cases are optional for backwards compatibility with existing tests
   - When null, AuthProvider falls back to inline implementation (migration path)
2. Wire in `main.dart`:
   - Construct use cases with their dependencies
   - Pass to AuthProvider
3. Final AuthProvider line count target: ~450-550 lines (down from 977)
   - State fields + getters: ~100 lines (unchanged)
   - Auth methods (thin delegation): ~150 lines
   - Mock auth: ~100 lines
   - Constructor + listener + helpers: ~100 lines

**Verify:** `pwsh -Command "flutter analyze"` and `pwsh -Command "flutter test"`

---

### Sub-phase 4.8: Unit Tests for Use Cases

**Files:**
- `test/features/auth/domain/use_cases/sign_in_use_case_test.dart` (NEW)
- `test/features/auth/domain/use_cases/sign_out_use_case_test.dart` (NEW)
- `test/features/auth/domain/use_cases/check_inactivity_use_case_test.dart` (NEW)
- `test/features/auth/domain/use_cases/load_profile_use_case_test.dart` (NEW)
- `test/features/auth/presentation/providers/auth_provider_test.dart` (EDIT — update for new constructor)

**Agent:** qa-testing-agent

**What:**
1. **SignInUseCase tests:**
   - Happy path: valid credentials return user + null guardProfile
   - Company switch detected: returns guardProfile = null (cleared)
   - AuthException: returns error message
   - Network error: returns generic error
2. **SignOutUseCase tests:**
   - Happy path: calls authService.signOut, disposes BackgroundSyncHandler, clears secure storage
   - Error: returns false, does not throw
3. **CheckInactivityUseCase tests:**
   - No stored timestamp (first launch): writes timestamp, returns false
   - Within 7 days: returns false
   - Beyond 7 days: returns true (caller signs out)
   - Parse error: returns false (fail open)
4. **LoadProfileUseCase tests:**
   - Remote profile loaded: returns profile + company
   - Legacy migration triggered: returns migrated profile
   - Remote fails, local fallback succeeds: returns cached profile
   - Stale session (profile null, user exists): returns shouldSignOut = true
5. **Update existing auth_provider_test.dart:**
   - Update AuthProvider construction to pass mock use cases (or null to use inline fallback)
   - Ensure existing tests still pass

**Verify:** `pwsh -Command "flutter test test/features/auth/"`

---

### Summary: Layer Violations Fixed

| # | Location | Violation | Fixed In |
|---|----------|-----------|----------|
| 1 | `auth_provider.dart:323` | Raw `db.query('companies')` | Sub-phase 4.3 — CompanyRepository.getCachedCompanyId() |
| 2 | `app_config_provider.dart:148` | `Supabase.instance.client.from('app_config')` | Sub-phase 4.1 — AppConfigRepository.fetchConfig() |
| 3 | `settings_screen.dart:72` | `Supabase.instance.client.from('user_profiles').update(gauge)` | Sub-phase 4.2 — UserProfileRepository.updateGaugeNumber() |
| 4 | `settings_screen.dart:118` | `Supabase.instance.client.from('user_profiles').update(initials)` | Sub-phase 4.2 — UserProfileRepository.updateInitials() |

### Execution Order

Sub-phases 4.1, 4.2, 4.3 are independent (can run in parallel).
Sub-phases 4.4, 4.5, 4.6 depend on 4.3 (company repository method used by use cases).
Sub-phase 4.7 depends on 4.4-4.6 (wires all use cases).
Sub-phase 4.8 depends on 4.7 (tests the final wired state).

```
4.1 ─────────────────────────┐
4.2 ─────────────────────────┤
4.3 ──┬─────────────────────┤
      │                      │
      ├── 4.4 ──┐            │
      ├── 4.5 ──┼── 4.7 ── 4.8
      └── 4.6 ──┘
```
