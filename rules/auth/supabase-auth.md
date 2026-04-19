---
paths:
  - "lib/features/auth/**/*.dart"
  - "lib/features/projects/**/*.dart"
  - "lib/features/settings/**/*.dart"
  - "lib/features/sync/**/*.dart"
  - "lib/core/config/supabase_config.dart"
  - "lib/core/router/**/*.dart"
  - "supabase/migrations/**/*.sql"
---

# Auth

- Keep tokens in `flutter_secure_storage`. Never log credentials or tokens.
- Stay on provider-based auth state management. Do not introduce Riverpod.
- Pop auth dialogs before calling `signOut()` so router redirects do not crash the navigator.
- The auth-state listener that drives sync lifecycle belongs in app bootstrap, not scattered auth screens.
- Build auth services through `AuthDeps` and the existing initializer path, not ad-hoc constructors.
- Keep client-side password validation and Supabase auth expectations aligned.

## Role Policy

- Admin-only: admin dashboard, member approval, role changes, company config.
- Engineer and Office Technician are project/data peers; Inspector writes assigned field data but cannot manage/delete projects.
- Trash is user-scoped for every approved user, not admin-only.
