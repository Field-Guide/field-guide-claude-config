---
paths:
  - "lib/features/**/presentation/**/*.dart"
  - "lib/core/theme/**/*.dart"
  - "lib/core/router/**/*.dart"
  - "lib/core/design_system/**/*.dart"
---

# Frontend / Flutter UI

## Hard Constraints

- **`AppTheme.*` color constants are DEPRECATED** — do not adapt across themes.
- Use `Theme.of(context).colorScheme.*` or `FieldGuideColors.of(context).*` for all colors.
- **NEVER** hardcode `Colors.*` values in presentation code.
- **Always** check `mounted` after async operations before using context.
- **Provider only**: `context.read<T>()` for actions, `Consumer<T>` / `context.watch<T>()` for rebuilds. NOT Riverpod.

## Design System (24 components in `lib/core/design_system/`)

Lint rules A18–A23 enforce design system usage:
- No raw `AlertDialog` / `showDialog` — use `AppDialog.show()`
- No raw `showModalBottomSheet` — use `AppBottomSheet.show()`
- No raw `Scaffold` in screens — use `AppScaffold`
- No direct `ScaffoldMessenger` — use `SnackBarHelper.show*()`
- No inline `TextStyle` / raw `Text()` with manual style — use `AppText.*`

## Critical Gotchas

- **`AppDialog` uses `actionsBuilder:`** — NOT `actions:`. Provides dialog's own BuildContext.
- **Pop dialog BEFORE `auth.signOut()`** — GoRouter redirect fires synchronously on auth state change; mounted dialog crashes the navigator.
- `AppColors` weather tag constants (`sunny`, `rainy`, etc.) are an allowed exception.

## Responsive Breakpoints
- Mobile: < 600px | Tablet: 600–1200px | Desktop: > 1200px

> For code patterns, UI examples, and component inventory, see `.claude/skills/implement/references/flutter-ui-guide.md`
