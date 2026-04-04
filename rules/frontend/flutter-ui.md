---
paths:
  - "lib/features/**/presentation/**/*.dart"
  - "lib/core/theme/**/*.dart"
  - "lib/core/router/**/*.dart"
  - "lib/core/design_system/**/*.dart"
---

# Frontend Guidelines

## Common Commands
```bash
pwsh -Command "flutter run -d windows"          # Run on Windows
pwsh -Command "flutter run"                     # Run on connected device
pwsh -Command "flutter analyze"                 # Check for issues
pwsh -Command "flutter test"                    # Test all
```

## Code Style

### Screen Structure
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    // Cleanup subscriptions, controllers
    super.dispose();
  }
}
```

### Theme Colors

`AppTheme.*` color constants are **deprecated** — they do not adapt across dark/light/high-contrast themes.

Use the correct color lookup pattern based on semantic meaning:

| Color Need | Correct Pattern |
|------------|----------------|
| Primary brand color | `Theme.of(context).colorScheme.primary` |
| Error / destructive | `Theme.of(context).colorScheme.error` |
| Primary text | `Theme.of(context).colorScheme.onSurface` |
| Secondary / hint text | `Theme.of(context).colorScheme.onSurfaceVariant` |
| Success indicators | `FieldGuideColors.of(context).statusSuccess` |
| Warning indicators | `FieldGuideColors.of(context).statusWarning` |
| Info indicators | `FieldGuideColors.of(context).statusInfo` |
| Elevated surface | `FieldGuideColors.of(context).surfaceElevated` |
| Glass/frosted overlay | `FieldGuideColors.of(context).surfaceGlass` |
| Tertiary text (hints, timestamps) | `FieldGuideColors.of(context).textTertiary` |

- NEVER hardcode `Colors.*` values
- NEVER use `AppTheme.*` color constants (deprecated)

### Navigation
```dart
context.pushNamed('route', pathParameters: {'id': id});
context.goNamed('route');  // Replace
context.pop();             // Back
```

## State Management

### Provider Pattern
```dart
// Read once (actions)
context.read<MyProvider>().doAction();

// Watch for rebuilds
Consumer<MyProvider>(
  builder: (context, provider, child) => Widget(),
);
```

### Async Safety
```dart
await asyncOperation();
if (!mounted) return;  // ALWAYS check
context.read<Provider>().update();
```

## UI Guidelines

### Responsive Breakpoints
- Mobile: < 600px
- Tablet: 600-1200px
- Desktop: > 1200px

### Card-Based Lists
- Leading icon/avatar
- Title and subtitle
- Trailing action/status

### Forms
- Validate before advancing
- Show loading during submit

## Error Handling
```dart
try {
  await operation();
} catch (e) {
  if (!mounted) return;
  SnackBarHelper.showError(context, 'Error: $e');
}
```

## Logging
```dart
Logger.ui('INFO: $message');  // Development only
```

## Pull Request Template
```markdown
## UI Changes
- [ ] Screens affected:
- [ ] Theme colors used (no hardcoding)
- [ ] Responsive tested (mobile/tablet/desktop)
- [ ] Dark mode verified

## Testing
- [ ] Widget tests added
- [ ] Manual testing on target device
```

## Detailed UI Patterns

### Split View / Master-Detail Pattern

Used in Calendar screen for entry list + report preview:

```
┌─────────────────────────────────────────────────┐
│ [Calendar Header + Month View]                  │
├─────────────────────────────────────────────────┤
│ Entry List (horizontal scroll)  │  Report Preview (flex)    │
│ ┌────────────────┐  ┌──────────┐ │ ┌───────────────────────┐ │
│ │ ▶ Location A   │  │Location B│ │ │ Weather: Sunny        │ │
│ │   Draft        │  │ Complete │ │ │ Activities: ...       │ │
│ │                │  │          │ │ │ Safety: ...           │ │
│ └────────────────┘  └──────────┘ │ │ [Edit] buttons        │ │
│                                  │ └───────────────────────┘ │
└─────────────────────────────────────────────────┘
```

Implementation pattern (Reference: `lib/features/entries/presentation/screens/home_screen.dart` — `_buildEntryList` method):
- Track `_selectedEntryId` state for highlighting
- Entry list: Horizontal `ListView.builder` with fixed-width cards (140px each)
- Right panel: Scrollable report preview driven by `_selectedEntryId`
- Selection state updates preview via `setState()`
- Edit buttons pass section identifier as query parameter

### Form Organization (Detailed)

`EntryEditorScreen` uses a unified single-scroll layout (not a Stepper). All sections are visible at once:
- Header (location, date, weather) — auto-expands when fields are empty, collapses when set
- Inline tap-to-edit for each section
- Draft tracking replaces create/edit mode bifurcation

Reference: `lib/features/entries/presentation/screens/entry_editor_screen.dart` — `EntryEditorScreen` class

### Theming Pattern

Centralized theme with brand colors. Reference: `lib/core/theme/app_theme.dart` and `lib/core/theme/field_guide_colors.dart`

#### Color Naming

- Primary brand colors: resolved via `Theme.of(context).colorScheme.primary`
- Semantic colors: `statusSuccess`, `statusWarning` via `FieldGuideColors.of(context)`
- Domain-specific: `sunny`, `rainy`, `overcast` (weather tags — use `AppColors` constants)

#### Theme Usage

Always access via `Theme.of(context).colorScheme.*` or `FieldGuideColors.of(context).*`. Never call `AppTheme.*` color constants directly — they are deprecated and do not adapt to dark/light/high-contrast themes.

### Clickable Stat Cards Pattern

Dashboard stat cards use the `DashboardStatCard` widget (located at `lib/features/dashboard/presentation/widgets/dashboard_stat_card.dart`). It wraps an `InkWell` with an `onTap` parameter:

```dart
DashboardStatCard(
  label: 'Entries',
  value: '12',
  icon: Icons.assignment,
  color: Theme.of(context).colorScheme.primary,
  onTap: () => _navigateToEntries(),
)
```

Reference: `lib/features/dashboard/presentation/screens/project_dashboard_screen.dart` — stat card usage


## Accessibility

- **Touch targets**: Minimum 48dp x 48dp for all interactive elements
- **Semantics labels**: All icons and images must have `Semantics` or `semanticLabel`
- **Color contrast**: Use theme tokens (three-tier system) which are designed for contrast
- **Dark mode testing**: All UI must be verified in dark, light, and high-contrast themes

## Color System (Enforced by A12, A13)

Colors MUST use the three-tier system. Violations are blocked by custom lint rules.
See spec Section 3 for the full tier mapping.

**Exception:** `AppColors` weather tag constants (`sunny`, `rainy`, `overcast`, etc.) are an allowed exception for domain-specific color semantics. These are not hardcoded colors -- they are named constants for weather classification tags.

## Design System Components (Enforced by A18-A24)

24 components in `lib/core/design_system/` (barrel: `design_system.dart`):

| Component | Component | Component | Component |
|-----------|-----------|-----------|-----------|
| AppBottomBar | AppBottomSheet | AppBudgetWarningChip | AppChip |
| AppCounterField | AppDialog | AppDragHandle | AppEmptyState |
| AppErrorState | AppGlassCard | AppIcon | AppInfoBanner |
| AppListTile | AppLoadingState | AppMiniSpinner | AppPhotoGrid |
| AppProgressBar | AppScaffold | AppSectionCard | AppSectionHeader |
| AppStickyHeader | AppText | AppTextField | AppToggle |

### Lint Rules Enforcing Design System Usage

| Rule | Constraint |
|------|-----------|
| A18 | No raw `AlertDialog` -- use `AppDialog.show()` |
| A19 | No raw `showDialog` -- use `AppDialog.show()` |
| A20 | No raw `showModalBottomSheet` -- use `AppBottomSheet.show()` |
| A21 | No raw `Scaffold` in screens -- use `AppScaffold` |
| A22 | No direct `ScaffoldMessenger` -- use `SnackBarHelper.show*()` |
| A23 | No inline `TextStyle` -- use `AppText.*` |
| A24 | No raw `Text()` with manual style -- use `AppText.*` |

### AppDialog actionsBuilder Pattern

```dart
// CORRECT: actionsBuilder provides dialog's own BuildContext
AppDialog.show(
  context: context,
  title: 'Confirm',
  actionsBuilder: (dialogContext) => [
    TextButton(
      onPressed: () => Navigator.pop(dialogContext),
      child: const Text('Cancel'),
    ),
  ],
);

// WRONG: actions: uses parent context, causes wrong-context pop
```

### Pop-Before-SignOut Rule (CRITICAL)

ALWAYS pop the dialog BEFORE calling `auth.signOut()`. GoRouter's redirect fires synchronously on auth state change -- if the dialog is still mounted, the route stack empties and crashes.

```dart
// CORRECT
Navigator.pop(dialogContext);
await ref.read(authProvider).signOut();

// WRONG -- crash: redirect fires while dialog is mounted
await ref.read(authProvider).signOut();
Navigator.pop(dialogContext);
```
