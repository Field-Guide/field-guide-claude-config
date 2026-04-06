# Pattern: Design System Component

## How We Do It
Design system components are `StatelessWidget` or `StatefulWidget` classes in `lib/core/design_system/`. They import tokens directly (relative paths), accept semantic parameters, and wrap raw Flutter widgets. They are exported through the `design_system.dart` barrel. Components use `DesignConstants` for spacing/sizing and `FieldGuideColors.of(context)` for theme-aware colors.

## Exemplar: AppInfoBanner (`lib/core/design_system/app_info_banner.dart`)

```dart
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) { ... }
}
```

## Exemplar: AppDialog (`lib/core/design_system/app_dialog.dart`)

Static factory pattern — no public constructor:
```dart
class AppDialog {
  AppDialog._(); // Private constructor

  static Future<T?> show<T>(BuildContext context, {
    required String title,
    required Widget content,
    List<Widget> Function(BuildContext dialogContext)? actionsBuilder,
    // ...
  }) { ... }

  static Future<T?> showCustom<T>(BuildContext context, {
    required WidgetBuilder builder,
    // ...
  }) { ... }
}
```

**Note**: Uses `actionsBuilder:` NOT `actions:`. Pop dialog BEFORE `auth.signOut()`.

## Exemplar: AppBottomSheet (`lib/core/design_system/app_bottom_sheet.dart`)

```dart
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(BuildContext context, {
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = true,
  }) { ... }
}
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `AppDialog.show` | `app_dialog.dart:61` | `static Future<T?> show<T>(...)` | Standard dialog with title/content/actions |
| `AppDialog.showCustom` | `app_dialog.dart:37` | `static Future<T?> showCustom<T>(...)` | Fully custom dialog widget |
| `AppBottomSheet.show` | `app_bottom_sheet.dart:30` | `static Future<T?> show<T>(...)` | Modal bottom sheet with glass styling |
| `AppEmptyState` constructor | `app_empty_state.dart:23` | `const AppEmptyState({icon, title, subtitle?, actionLabel?, onAction?})` | Empty state placeholder |
| `AppErrorState` constructor | `app_error_state.dart:19` | `const AppErrorState({message, onRetry?, retryLabel?})` | Error state with retry |
| `AppLoadingState` constructor | `app_loading_state.dart:16` | `const AppLoadingState({label?})` | Full-screen loading |

## Imports
```dart
import 'package:construction_inspector/core/design_system/design_system.dart';
```
Single barrel import gives access to all components.

## New Components to Create (following same patterns)

### Static factory pattern (like AppDialog/AppBottomSheet):
- `AppButton` — primary/secondary/ghost/danger variants via named constructors or factory
- `AppDropdown` — wraps `DropdownButton` with consistent styling
- `AppDatePicker` — wraps date picker with theme tokens

### Widget pattern (like AppInfoBanner/AppEmptyState):
- `AppBadge` — color/icon/letter variants
- `AppDivider` — themed divider
- `AppAvatar` — user avatar with fallback
- `AppTooltip` — themed tooltip wrapper
- `AppStatCard` — dashboard stat card
- `AppActionCard` — tappable card with action
- `AppBanner` — generic composable banner (replaces StaleConfigWarning, VersionBanner)
- `AppTabBar` — themed tab bar

### Form editor organisms:
- `AppFormSection` — collapsible section (extracted from `FormAccordion`)
- `AppFormSectionNav` — section navigator (extracted from hub)
- `AppFormStatusBar` — form status (extracted from `StatusPillBar`)
- `AppFormFieldGroup` — field grouping
- `AppFormSummaryTile` — read-only display (extracted from `SummaryTiles`)
- `AppFormThumbnail` — mini preview (extracted from `FormThumbnail`)
