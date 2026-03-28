# Defects: Entries

Active patterns for entries. Max 5 defects - oldest auto-archives.
Archive: .claude/logs/defects-archive.md

## Active Patterns

### [ASYNC] 2026-03-28: Cache provider refs for pop/lifecycle callbacks
**Pattern**: Using `context.read<Provider>()` inside `onPopInvokedWithResult` or `didChangeAppLifecycleState` can throw if the InheritedWidget is no longer in the ancestor chain during widget deactivation.
**Prevention**: Cache provider refs as nullable fields in `didChangeDependencies()`. Use cached refs in all pop/lifecycle callbacks. Follow the `_entryProvider` pattern already established in EntryEditorScreen.
**Ref**: @lib/features/entries/presentation/screens/entry_editor_screen.dart:102-105,169-173

### [DATA] 2026-03-28: Custom raw queries must include deleted_at IS NULL
**Pattern**: `getPaged()` and `getCount()` bypassed `GenericLocalDatasource._notDeletedFilter` by querying `database.query()` directly, returning soft-deleted entries in paged results and inflated counts.
**Prevention**: Any method that queries the database directly (not via GenericLocalDatasource helpers) MUST include `WHERE deleted_at IS NULL`. Grep for `database.query` and `rawQuery` to audit.
**Ref**: @lib/features/entries/data/repositories/daily_entry_repository.dart:140,169

### [E2E] 2026-03-26: Driver scroll fails — scrollable widgets need ValueKey (not GlobalKey)
**Pattern**: `/driver/scroll` endpoint uses `_findByValueKey()` to locate the scrollable widget. If the scrollable has a `GlobalKey` or no key, the handler returns 404 silently and the page doesn't scroll.
**Prevention**: All scrollable widgets that E2E tests need to scroll must have `const ValueKey('descriptive_name')`. Add keys to `CustomScrollView`, `SingleChildScrollView`, `ListView` — never to their children. 12 keys were added in S655.
**Ref**: `lib/core/driver/driver_server.dart:354` (`_handleScroll`), `lib/core/driver/driver_server.dart:1094` (`_findByValueKey`)

### [E2E] 2026-03-22: Tap-to-edit sections require explicit section tap before field interaction
**Pattern**: Activities, safety, and temperature sections in the entry editor use tap-to-edit mode (`alwaysEditing: false`). TextFields only render after tapping the section card.
**Prevention**: E2E flows must tap the section card key and wait for the field key before attempting text input.
**Ref**: `lib/features/entries/presentation/screens/entry_editor_screen.dart`

### [DATA] 2026-03-21: createdByUserId never set on entry creation
**Pattern**: `DailyEntry` constructor in entry wizard omitted `createdByUserId`, so all entries had null attribution.
**Prevention**: When adding attribution/ownership fields to models, grep all creation sites to ensure the field is populated.
**Ref**: `lib/features/entries/presentation/screens/entry_editor_screen.dart:364`

<!-- RESOLVED 2026-03-21 S619: [SECURITY] Inspectors can edit other users' entries — Fixed: canEditEntry() now denies ALL non-creators. Null createdByUserId = read-only. Ref: auth_provider.dart:192-196 -->

<!-- Add defects above this line -->
