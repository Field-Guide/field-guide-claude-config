# Blast Radius Analysis: Auth/Onboarding Bugfix

## Bug 1: Flash of Project Screen After Registration

### Root Cause
`app_router.dart:128` redirects authenticated users off auth routes to `/` BEFORE the `isLoadingProfile` guard at line 170 is evaluated. During sign-up, the sequence is:
1. `signUp()` sets `_currentUser` (isAuthenticated = true)
2. Calls `loadUserProfile()` which sets `_isLoadingProfile = true` + `notifyListeners()`
3. Router evaluates: line 128 sees `isAuthenticated && isAuthRoute` -> returns `/`
4. User briefly sees ProjectDashboardScreen before profile loads and router re-evaluates

### Affected Symbols

| Symbol | File:Line | Category |
|--------|-----------|----------|
| `AppRouter._buildRouter` redirect closure | `lib/core/router/app_router.dart:88-220` | DIRECT |
| `AuthProvider.isLoadingProfile` | `lib/features/auth/presentation/providers/auth_provider.dart:149` | DEPENDENT (read) |
| `AuthProvider.signUp` | `lib/features/auth/presentation/providers/auth_provider.dart:205-252` | DEPENDENT (trigger) |
| `AuthProvider.signIn` | `lib/features/auth/presentation/providers/auth_provider.dart:255-297` | DEPENDENT (same pattern) |
| `AuthProvider.loadUserProfile` | `lib/features/auth/presentation/providers/auth_provider.dart:453-555` | DEPENDENT (sets flag) |

### Call Chain
```
RegisterScreen -> AuthProvider.signUp() -> _currentUser = user -> loadUserProfile()
  -> _isLoadingProfile = true -> notifyListeners()
  -> Router redirect evaluates:
     L128: isAuthenticated(true) && isAuthRoute(true) -> return '/' [BUG: fires before L170]
     L170: _authProvider.isLoadingProfile -> return null [NEVER REACHED]
```

---

## Bug 2: Company Search Returns No Results

### Root Cause
`search_companies` SQL RPC returns `TABLE (id UUID, name TEXT)` — only 2 columns.
`Company.fromJson()` at `company.dart:68` calls `DateTime.parse(json['created_at'] as String)` where `created_at` is null (not in response), causing `TypeError` on `as String` cast. The error is silently swallowed by `catch (_)` at `company_setup_screen.dart:173`.

### Affected Symbols

| Symbol | File:Line | Category |
|--------|-----------|----------|
| `search_companies` SQL function | `supabase/migrations/20260305000000_schema_alignment_and_security.sql:735-750` | DIRECT |
| `Company.fromJson` | `lib/features/auth/data/models/company.dart:63-71` | DEPENDENT (consumer) |
| `CompanyRemoteDatasource.search` | `lib/features/auth/data/datasources/remote/company_remote_datasource.dart:33-43` | DEPENDENT (caller) |
| `AuthService.searchCompanies` | `lib/features/auth/services/auth_service.dart:226-230` | DEPENDENT (passthrough) |
| `CompanySetupScreen._performSearch` | `lib/features/auth/presentation/screens/company_setup_screen.dart:160-176` | DEPENDENT (UI caller) |

### Call Chain
```
CompanySetupScreen._onSearchChanged -> _performSearch()
  -> AuthService.searchCompanies()
    -> CompanyRemoteDatasource.search()
      -> supabase.rpc('search_companies') [returns {id, name} ONLY]
      -> Company.fromJson() [expects created_at, updated_at] -> TypeError
  -> catch (_) silently swallows -> _searchResults = [] (empty)
```

### SQL Comparison
| RPC | Returns | Works? |
|-----|---------|--------|
| `create_company` | `RETURNS companies` (full row) | Yes |
| `search_companies` | `RETURNS TABLE (id UUID, name TEXT)` | No — missing `created_at`, `updated_at` |

---

## Summary

| Category | Count | Files |
|----------|-------|-------|
| DIRECT | 2 | `app_router.dart`, new SQL migration |
| DEPENDENT | 6 | `auth_provider.dart`, `company.dart`, `company_remote_datasource.dart`, `auth_service.dart`, `company_setup_screen.dart` |
| TEST | 2 | `auth_provider_test.dart`, `auth_service_test.dart` |
| CLEANUP | 1 | `company_setup_screen.dart` (add error logging) |

## Existing Tests
- `test/features/auth/presentation/providers/auth_provider_test.dart` — mock-based AuthProvider tests
- `test/features/auth/services/auth_service_test.dart` — AuthService unit tests
- No router tests exist
