# Flutter UI — Procedure Guide

> Loaded on-demand by workers. For constraints and invariants, see `.claude/rules/frontend/flutter-ui.md`

## Common Commands
```bash
pwsh -Command "flutter run -d windows"          # Run on Windows
pwsh -Command "flutter run"                     # Run on connected device
pwsh -Command "flutter analyze"                 # Check for issues
pwsh -Command "flutter test"                    # Test all
```

## Screen Structure
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

## Theme Colors

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
| Tertiary text | `FieldGuideColors.of(context).textTertiary` |

## Navigation
```dart
context.pushNamed('route', pathParameters: {'id': id});
context.goNamed('route');  // Replace
context.pop();             // Back
```

## State Management

### Provider Pattern
```dart
context.read<MyProvider>().doAction();       // One-time read

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

## Error Handling
```dart
try {
  await operation();
} catch (e) {
  if (!mounted) return;
  SnackBarHelper.showError(context, 'Error: $e');
}
```

## Design System Components (24)

| Component | Component | Component | Component |
|-----------|-----------|-----------|-----------|
| AppBottomBar | AppBottomSheet | AppBudgetWarningChip | AppChip |
| AppCounterField | AppDialog | AppDragHandle | AppEmptyState |
| AppErrorState | AppGlassCard | AppIcon | AppInfoBanner |
| AppListTile | AppLoadingState | AppMiniSpinner | AppPhotoGrid |
| AppProgressBar | AppScaffold | AppSectionCard | AppSectionHeader |
| AppStickyHeader | AppText | AppTextField | AppToggle |

### Lint Rules Enforcing Design System

| Rule | Constraint |
|------|-----------|
| A18 | No raw `AlertDialog` — use `AppDialog.show()` |
| A19 | No raw `showDialog` — use `AppDialog.show()` |
| A20 | No raw `showModalBottomSheet` — use `AppBottomSheet.show()` |
| A21 | No raw `Scaffold` in screens — use `AppScaffold` |
| A22 | No direct `ScaffoldMessenger` — use `SnackBarHelper.show*()` |
| A23 | No inline `TextStyle` — use `AppText.*` |
| A24 | No raw `Text()` with manual style — use `AppText.*` |

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
```

### Pop-Before-SignOut Rule
```dart
// CORRECT
Navigator.pop(dialogContext);
await ref.read(authProvider).signOut();

// WRONG — crash: redirect fires while dialog is mounted
await ref.read(authProvider).signOut();
Navigator.pop(dialogContext);
```

## UI Patterns

### Split View / Master-Detail
Used in Calendar screen. Track `_selectedEntryId` state. Entry list: horizontal `ListView.builder` with 140px cards. Right panel: scrollable report preview driven by selection.

Reference: `lib/features/entries/presentation/screens/home_screen.dart`

### Form Organization
`EntryEditorScreen` uses unified single-scroll layout (not Stepper). All sections visible at once. Header auto-expands when fields empty. Inline tap-to-edit. Draft tracking replaces create/edit mode.

### Clickable Stat Cards
```dart
DashboardStatCard(
  label: 'Entries',
  value: '12',
  icon: Icons.assignment,
  color: Theme.of(context).colorScheme.primary,
  onTap: () => _navigateToEntries(),
)
```

## Accessibility
- Touch targets: minimum 48dp × 48dp
- Semantics labels on all icons and images
- Color contrast: use theme tokens (designed for contrast)
- Dark mode testing: verify in dark, light, and high-contrast themes

## Color System (Enforced by A12, A13)
Colors MUST use the three-tier system. Exception: `AppColors` weather tag constants.

## PR Template
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
