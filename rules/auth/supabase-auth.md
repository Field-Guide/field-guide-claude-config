---
paths:
  - "lib/features/auth/**/*.dart"
  - "lib/core/config/supabase_config.dart"
---

# Auth Service Guidelines

Supabase-based authentication with offline-first token management, multi-tenant company model, and OTP password recovery.

## Hard Constraints

- **Token storage:** Use `flutter_secure_storage` for tokens. Never log tokens or credentials. Clear on sign out.
- **State management:** Uses `provider` package (`ChangeNotifier`). **NOT Riverpod** — never use `ref.read()` or `ref.watch()`.
- **Dialog sign-out safety:** ALWAYS `Navigator.pop(dialogContext)` BEFORE `auth.signOut()`. GoRouter redirect fires synchronously on auth state change — if the dialog is still mounted, the navigator crashes.
- **Auth state listener location:** The auth state listener driving sync lifecycle lives in `AppInitializer` (`lib/core/bootstrap/app_initializer.dart`), NOT in the auth feature. Check both locations when modifying sign-in/sign-out behavior.
- **DI pattern:** Auth dependencies use typed container `AuthDeps` via `AuthInitializer.create(coreDeps)`. Do NOT construct auth services or providers ad-hoc.
- **Password requirements:** Min 8 chars, 1 uppercase, 1 lowercase, 1 digit. Enforced client-side by `PasswordValidator` and mirrored in `supabase/config.toml`.
- **Rate limiting:** Handle 429 errors gracefully from Supabase auth endpoints.

> For screen inventory, code patterns, and flow diagrams, see `.claude/skills/implement/references/auth-patterns-guide.md`
