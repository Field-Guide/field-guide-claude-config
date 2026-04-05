---
paths:
  - "lib/**/*.dart"
---

# Architectural Constraints

Feature-first Clean Architecture with provider-only state management, offline-first SQLite with Supabase sync.

## Hard Constraints

- **Feature-first layers**: Each feature has `data/`, `domain/`, `presentation/`, `di/` sub-directories
- **Provider-only state management**: `ChangeNotifier` via `provider` package (~32 providers) — NOT Riverpod
- **Data flow**: Screen -> Provider -> UseCase -> Repository -> Datasource -> SQLite -> Supabase
- **Provider tier ordering** (tiers 0-5): Forms MUST precede entries in tier 4 (`ExportEntryUseCase` depends on `ExportFormUseCase`)
- **Tiers 1-2 are NOT in widget tree** — created imperatively in `AppInitializer`, passed via typed `*Deps` containers
- **Typed DI containers**: CoreDeps, AuthDeps, ProjectDeps, EntryDeps, FormDeps, SyncDeps, FeatureDeps — composed into `AppDependencies`
- **`is_builtin=1` rows are server-seeded** — triggers skip them, cascade-delete skips them, push skips them
- **Domain layer is pure Dart** — no Flutter imports, no framework dependencies

## Key Anti-Patterns

- No raw SQL in presentation/ or di/ layers
- No hardcoded `Colors.*` — use `Theme.of(context).colorScheme.*` or `FieldGuideColors.of(context).*`
- No raw `Scaffold`, `AlertDialog`, `showDialog`, `showModalBottomSheet` — use design system (`AppScaffold`, `AppDialog.show()`, `AppBottomSheet.show()`)
- No `SnackBarHelper` bypass — use `SnackBarHelper.show*()`
- No inline `TextStyle(` — use `AppText.*` or textTheme slots
- No silent `catch` blocks — always log via `Logger.<category>()`
- Check `mounted` after every async gap before using `context`
- No `debugPrint` in production code — use `Logger`

## Navigation

Uses **go_router** with shell routes (persistent bottom nav) and full-screen routes (wizards, detail views). Path params for required IDs, query params for optional data.

## Offline-First

SQLite triggers auto-populate `change_log` on tracked tables. No per-model `syncStatus` field. Change log drives push to Supabase.

> For code patterns, tier details, color system, and lint rule inventory, see `.claude/skills/implement/reference/architecture-guide.md`
