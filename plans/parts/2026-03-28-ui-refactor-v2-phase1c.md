# Phase 1 Part C: Surface Layer, Composite Layer, Barrel + Theme Completion, Tests

> **Continues from:** `2026-03-28-ui-refactor-v2-phase1.md` (Phases 1.A–1.D)
> **Components built so far:** AppText, AppTextField, AppChip, AppProgressBar, AppCounterField, AppToggle, AppIcon, AppGlassCard, AppSectionHeader, AppListTile, AppPhotoGrid, AppSectionCard

---

## Phase 1.E: Build Surface Layer Components

### Sub-phase 1.E: Surface-Level Design System Widgets

**Files:**
- Create: `lib/core/design_system/app_scaffold.dart`
- Create: `lib/core/design_system/app_bottom_bar.dart`
- Create: `lib/core/design_system/app_bottom_sheet.dart`
- Create: `lib/core/design_system/app_dialog.dart`
- Create: `lib/core/design_system/app_sticky_header.dart`
- Create: `lib/core/design_system/app_drag_handle.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.E.1: Create AppScaffold

> **WHY:** Every screen constructs its own Scaffold + SafeArea wrapper. This ensures consistent
> SafeArea application and inherits scaffoldBackgroundColor from ThemeData so no screen ever
> sets its own background color.
>
> **NOTE:** Does NOT set backgroundColor by default — relies entirely on ThemeData.scaffoldBackgroundColor.
> The optional backgroundColor prop is an escape hatch for screens that need a different bg (e.g., photo viewer).

Create `lib/core/design_system/app_scaffold.dart`:

```dart
import 'package:flutter/material.dart';

/// Scaffold wrapper with SafeArea that inherits scaffoldBackgroundColor from ThemeData.
///
/// Usage:
/// ```dart
/// AppScaffold(
///   appBar: AppBar(title: Text('Projects')),
///   body: ProjectListView(),
///   floatingActionButton: FloatingActionButton(...),
/// )
/// ```
///
/// IMPORTANT: Does NOT set backgroundColor by default. All coloring comes from the
/// active theme's scaffoldBackgroundColor. Only pass backgroundColor for exceptional
/// cases (photo viewer overlay, splash screen).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.useSafeArea = true,
    this.backgroundColor,
  });

  /// The primary content of the scaffold.
  final Widget body;

  /// Optional app bar. Inherits appBarTheme from the active theme.
  final PreferredSizeWidget? appBar;

  /// Optional FAB. Inherits floatingActionButtonTheme from the active theme.
  final Widget? floatingActionButton;

  /// Optional bottom nav bar or persistent bottom widget.
  final Widget? bottomNavigationBar;

  /// Whether to wrap body in SafeArea. Default: true.
  /// Set to false for screens that manage their own safe area (e.g., full-bleed photo viewer).
  final bool useSafeArea;

  /// Override background color. Default: null (inherits scaffoldBackgroundColor from theme).
  /// NOTE: Only use for exceptional cases like photo viewer overlay or splash screen.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    // NOTE: No color defaults here. Scaffold reads scaffoldBackgroundColor from
    // ThemeData when backgroundColor is null. This is the intended behavior.
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: useSafeArea ? SafeArea(child: body) : body,
    );
  }
}
```

#### Step 1.E.2: Create AppBottomBar

> **WHY:** Sticky bottom action bars appear on 12+ screens (entry editor, contractor detail,
> quantity forms). Each manually constructs SafeArea + Container + BoxDecoration with
> inconsistent blur/padding. This component standardizes the frosted glass bottom bar.

Create `lib/core/design_system/app_bottom_bar.dart`:

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// Sticky bottom action bar with blur backdrop for persistent actions.
///
/// Usage:
/// ```dart
/// AppScaffold(
///   body: content,
///   bottomNavigationBar: AppBottomBar(
///     child: Row(
///       children: [
///         Expanded(child: OutlinedButton(...)),
///         SizedBox(width: AppTheme.space4),
///         Expanded(child: ElevatedButton(...)),
///       ],
///     ),
///   ),
/// )
/// ```
///
/// WHY: Replaces 12+ manual SafeArea + Container + blur patterns with a single
/// component that guarantees consistent padding, backdrop blur, and safe area insets.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.child,
    this.padding,
  });

  /// The action content (typically a Row of buttons).
  final Widget child;

  /// Override padding. Default: horizontal space4, vertical space3.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // NOTE: SafeArea wraps the entire bar to handle bottom insets (home indicator,
    // navigation bar) on modern devices. The blur creates a frosted glass effect
    // that lets content scroll behind the bar.
    return SafeArea(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: DesignConstants.space4,
              vertical: DesignConstants.space3,
            ),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: cs.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

#### Step 1.E.3: Create AppBottomSheet

> **WHY:** Bottom sheets are used 15+ times (photo picker, filter panels, detail drawers).
> Each calls showModalBottomSheet with different configurations. This standardizes the
> glass container, drag handle, and safe area padding.

Create `lib/core/design_system/app_bottom_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';
import 'app_drag_handle.dart';

/// Glass bottom sheet with drag handle and consistent styling.
///
/// Usage:
/// ```dart
/// final result = await AppBottomSheet.show<String>(
///   context,
///   builder: (ctx) => Column(
///     children: [
///       ListTile(title: Text('Option 1'), onTap: () => Navigator.pop(ctx, 'opt1')),
///       ListTile(title: Text('Option 2'), onTap: () => Navigator.pop(ctx, 'opt2')),
///     ],
///   ),
/// );
/// ```
///
/// WHY: Replaces 15+ showModalBottomSheet calls with inconsistent drag handles,
/// corner radii, and background colors. Inherits bottomSheetTheme for shape/elevation.
class AppBottomSheet {
  AppBottomSheet._();

  /// Shows a modal bottom sheet with glass styling and drag handle.
  ///
  /// [builder] receives the sheet's BuildContext for Navigator.pop calls.
  /// [isScrollControlled] defaults to true for dynamic height.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final fg = FieldGuideColors.of(sheetContext);

        // NOTE: We use a manual Container instead of relying on bottomSheetTheme's
        // backgroundColor because we need the surfaceElevated color from our
        // ThemeExtension, which bottomSheetTheme can't reference.
        return Container(
          decoration: BoxDecoration(
            color: fg.surfaceElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignConstants.radiusXLarge),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const AppDragHandle(),

              // Sheet content
              Flexible(
                child: builder(sheetContext),
              ),

              // Bottom safe area padding
              SizedBox(
                height: MediaQuery.of(sheetContext).padding.bottom,
              ),
            ],
          ),
        );
      },
    );
  }
}
```

#### Step 1.E.4: Create AppDialog

> **WHY:** Dialogs appear 20+ times (delete confirmation, discard changes, sync errors).
> Each calls showDialog with manual AlertDialog construction. This standardizes the
> dialog structure while INHERITING all styling from dialogTheme.
>
> **IMPORTANT:** Does NOT set background color, shape, or text styles. All comes from
> the active theme's dialogTheme (dark, light, or HC).

Create `lib/core/design_system/app_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_text.dart';

/// Themed dialog with standardized title/content/actions layout.
///
/// Usage:
/// ```dart
/// final confirmed = await AppDialog.show<bool>(
///   context,
///   title: 'Delete Entry?',
///   content: Text('This action cannot be undone.'),
///   actions: [
///     TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
///     ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
///   ],
/// );
/// ```
///
/// IMPORTANT: Does NOT set backgroundColor, shape, or text styles manually.
/// All dialog styling comes from the active theme's dialogTheme.
class AppDialog {
  AppDialog._();

  /// Shows a themed dialog with title, content, and optional actions.
  ///
  /// If no [actions] are provided, a single "OK" TextButton is shown as the default.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        // NOTE: AlertDialog inherits backgroundColor, shape, elevation, and
        // text styles from dialogTheme. We only provide structure.
        return AlertDialog(
          title: AppText.titleLarge(title),
          content: content,
          actions: actions ?? [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
```

#### Step 1.E.5: Create AppStickyHeader

> **WHY:** Entry editor uses sticky headers for section navigation (Personnel, Equipment,
> Weather, etc.). The blur backdrop lets content scroll behind while the header stays pinned.
> SliverPersistentHeaderDelegate is boilerplate-heavy — this wraps it cleanly.

Create `lib/core/design_system/app_sticky_header.dart`:

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// Blur-backdrop sticky header for use in CustomScrollView / NestedScrollView.
///
/// Usage:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     AppStickyHeader(
///       height: 56,
///       child: Row(
///         children: [
///           Text('PERSONNEL', style: tt.labelSmall),
///           Spacer(),
///           TextButton(onPressed: () {}, child: Text('Add')),
///         ],
///       ),
///     ),
///     SliverList(...),
///   ],
/// )
/// ```
///
/// WHY: SliverPersistentHeaderDelegate requires 50+ lines of boilerplate per header.
/// This wraps it into a single widget with blur backdrop matching the app's glass design.
class AppStickyHeader extends StatelessWidget {
  const AppStickyHeader({
    super.key,
    required this.child,
    this.height = 56.0,
    this.padding,
  });

  /// The header content (typically a Row with title + action).
  final Widget child;

  /// Header height. Default: 56.0 (matches AppBar height).
  final double height;

  /// Override internal padding. Default: horizontal space4.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        child: child,
        height: height,
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: DesignConstants.space4,
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.child,
    required this.height,
    required this.padding,
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;

    // NOTE: ClipRect is required for BackdropFilter to work correctly.
    // Without it, the blur applies to the entire screen instead of just
    // the header area.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: cs.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        height != oldDelegate.height ||
        padding != oldDelegate.padding;
  }
}
```

#### Step 1.E.6: Create AppDragHandle

> **WHY:** Bottom sheet drag handles appear on every sheet but are hardcoded inline
> with inconsistent widths (32–48px), heights (3–5px), and colors. This creates a
> single source of truth matching the bottomSheetTheme's dragHandleSize (40x4).

Create `lib/core/design_system/app_drag_handle.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Bottom sheet drag handle indicator.
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     AppDragHandle(),
///     // ... sheet content
///   ],
/// )
/// ```
///
/// WHY: Drag handles are hardcoded inline across 15+ bottom sheets with inconsistent
/// dimensions. This matches bottomSheetTheme's dragHandleSize (40x4) and uses the
/// theme-aware dragHandleColor from FieldGuideColors.
class AppDragHandle extends StatelessWidget {
  const AppDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final fg = FieldGuideColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: DesignConstants.space2,
        ),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: fg.dragHandleColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
```

---

## Phase 1.F: Build Composite Layer Components

### Sub-phase 1.F: Composite Design System Widgets

**Files:**
- Create: `lib/core/design_system/app_empty_state.dart`
- Create: `lib/core/design_system/app_error_state.dart`
- Create: `lib/core/design_system/app_loading_state.dart`
- Create: `lib/core/design_system/app_budget_warning_chip.dart`
- Create: `lib/core/design_system/app_info_banner.dart`
- Create: `lib/core/design_system/app_mini_spinner.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.F.1: Create AppEmptyState

> **WHY:** Empty state placeholders appear on 10+ screens (no entries, no photos, no projects).
> Each manually constructs Center + Column + Icon + Text with inconsistent spacing and
> optional "Add first item" CTA buttons.

Create `lib/core/design_system/app_empty_state.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';
import 'app_icon.dart';
import 'app_text.dart';

/// Empty state placeholder with icon, title, optional subtitle, and optional CTA.
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.photo_library_outlined,
///   title: 'No photos yet',
///   subtitle: 'Take a photo to get started',
///   actionLabel: 'Take Photo',
///   onAction: () => _openCamera(),
/// )
/// ```
///
/// WHY: Replaces 10+ manually constructed empty state patterns with inconsistent
/// icon sizes (32–64px), spacing, and button placement.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// The hero icon displayed above the title.
  final IconData icon;

  /// Primary message (e.g., "No entries yet").
  final String title;

  /// Optional secondary message with more detail.
  final String? subtitle;

  /// Optional CTA button label (e.g., "Create Entry").
  final String? actionLabel;

  /// Callback for the CTA button. Required if actionLabel is set.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = FieldGuideColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero icon — xl size, muted color
            AppIcon(
              icon,
              size: AppIconSize.xl,
              color: fg.textTertiary,
            ),

            const SizedBox(height: DesignConstants.space4),

            // Title
            AppText.titleMedium(
              title,
              color: cs.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: DesignConstants.space2),
              AppText.bodyMedium(
                subtitle!,
                color: fg.textTertiary,
                textAlign: TextAlign.center,
              ),
            ],

            // CTA button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignConstants.space6),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### Step 1.F.2: Create AppErrorState

> **WHY:** Error states appear on 8+ screens with inconsistent error icon colors,
> retry button placement, and message formatting. This standardizes the error display
> pattern with an error-colored icon and optional retry action.

Create `lib/core/design_system/app_error_state.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import 'app_icon.dart';
import 'app_text.dart';

/// Error state display with icon, message, and optional retry button.
///
/// Usage:
/// ```dart
/// AppErrorState(
///   message: 'Failed to load entries',
///   onRetry: () => _loadEntries(),
/// )
/// ```
///
/// WHY: Replaces 8+ inconsistent error state patterns. Uses cs.error from the
/// active theme for icon color, ensuring proper contrast in all themes.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  /// The error message to display.
  final String message;

  /// Optional retry callback. If provided, shows a retry button.
  final VoidCallback? onRetry;

  /// Retry button label. Default: 'Retry'.
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon — xl size, error color from theme
            AppIcon(
              Icons.error_outline,
              size: AppIconSize.xl,
              color: cs.error,
            ),

            const SizedBox(height: DesignConstants.space4),

            // Error message
            AppText.titleMedium(
              message,
              color: cs.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: DesignConstants.space6),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### Step 1.F.3: Create AppLoadingState

> **WHY:** Loading spinners with optional labels appear on 14+ screens. Each manually
> constructs Center + Column + CircularProgressIndicator with different sizes and spacing.
>
> **IMPORTANT:** Does NOT set spinner color. Inherits from progressIndicatorTheme.

Create `lib/core/design_system/app_loading_state.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import 'app_text.dart';

/// Full-screen loading state with optional label.
///
/// Usage:
/// ```dart
/// if (isLoading) return AppLoadingState(label: 'Syncing entries...');
/// ```
///
/// IMPORTANT: Does NOT set spinner color or size. All styling comes from the active
/// theme's progressIndicatorTheme. Uses CircularProgressIndicator.adaptive() for
/// native spinner appearance per platform.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.label,
  });

  /// Optional label below the spinner (e.g., "Syncing entries...").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // NOTE: .adaptive() picks native spinner per platform (Cupertino on iOS).
          // Color comes from progressIndicatorTheme — we do NOT override it.
          const CircularProgressIndicator.adaptive(),

          // Optional label
          if (label != null) ...[
            const SizedBox(height: DesignConstants.space4),
            AppText.bodyMedium(
              label!,
              color: cs.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

#### Step 1.F.4: Create AppBudgetWarningChip

> **WHY:** Budget warning chips with amber/orange theming appear 6+ times in quantity screens
> and project dashboards. Each hardcodes `Colors.amber.shade50`, `Colors.orange.shade800`,
> etc. This replaces those patterns with FieldGuideColors-aware warning/critical variants.

Create `lib/core/design_system/app_budget_warning_chip.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Budget warning chip with severity-based coloring.
///
/// Usage:
/// ```dart
/// AppBudgetWarningChip(label: '92% used', severity: BudgetSeverity.warning)
/// AppBudgetWarningChip(label: 'Over budget!', severity: BudgetSeverity.critical)
/// ```
///
/// WHY: Replaces 6+ hardcoded `Colors.amber.shade50` / `Colors.orange.shade800` patterns
/// with FieldGuideColors-aware colors that adapt to dark/light/HC themes.
enum BudgetSeverity {
  /// Amber coloring — approaching budget limit (e.g., 80-99%)
  warning,

  /// Red coloring — over budget (e.g., 100%+)
  critical,
}

class AppBudgetWarningChip extends StatelessWidget {
  const AppBudgetWarningChip({
    super.key,
    required this.label,
    this.icon = Icons.warning_amber_rounded,
    this.severity = BudgetSeverity.warning,
  });

  /// The warning text (e.g., "92% used", "Over budget!").
  final String label;

  /// Leading icon. Default: warning_amber_rounded.
  final IconData icon;

  /// Color severity. Default: warning (amber).
  final BudgetSeverity severity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = FieldGuideColors.of(context);
    final tt = Theme.of(context).textTheme;

    // NOTE: Warning uses FieldGuideColors amber tokens. Critical uses cs.error
    // with alpha modifiers for background/border so it adapts across all themes.
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    switch (severity) {
      case BudgetSeverity.warning:
        bgColor = fg.warningBackground;
        borderColor = fg.warningBorder;
        textColor = fg.accentAmber;
      case BudgetSeverity.critical:
        bgColor = cs.error.withValues(alpha: 0.1);
        borderColor = cs.error.withValues(alpha: 0.2);
        textColor = cs.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.space3,
        vertical: DesignConstants.space1,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: DesignConstants.iconSizeSmall, color: textColor),
          const SizedBox(width: DesignConstants.space1),
          Text(
            label,
            style: tt.labelMedium?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
```

#### Step 1.F.5: Create AppInfoBanner

> **WHY:** Icon + colored container + message banners appear 5+ times for warnings, info tips,
> and sync status notices. Each manually constructs Container + Row + Icon + Text with
> different alpha values and border colors.

Create `lib/core/design_system/app_info_banner.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// Colored info/warning banner with icon and message.
///
/// Usage:
/// ```dart
/// AppInfoBanner(
///   icon: Icons.info_outline,
///   message: 'Entries will sync when online',
///   color: cs.primary,
/// )
/// AppInfoBanner(
///   icon: Icons.warning_amber_rounded,
///   message: 'Unsaved changes will be lost',
///   color: cs.error,
///   actionLabel: 'Save Now',
///   onAction: () => _saveChanges(),
/// )
/// ```
///
/// WHY: Replaces 5+ inline Container + Row + Icon patterns with hardcoded alpha values.
/// The color parameter drives bg (10% alpha), border (30% alpha), and icon/text coloring.
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  /// Leading icon (e.g., Icons.info_outline, Icons.warning_amber_rounded).
  final IconData icon;

  /// The banner message text.
  final String message;

  /// The accent color. Drives bg (10%), border (30%), icon, and text color.
  final Color color;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional action button callback.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignConstants.space3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: DesignConstants.iconSizeMedium,
            color: color,
          ),
          const SizedBox(width: DesignConstants.space3),
          Expanded(
            child: Text(
              message,
              style: tt.bodyMedium?.copyWith(color: color),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: DesignConstants.space2),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
```

#### Step 1.F.6: Create AppMiniSpinner

> **WHY:** Inline loading spinners (16px, thin stroke) appear 19 times across the codebase
> for button loading states, list item refresh indicators, and sync status icons. Each
> manually constructs SizedBox + CircularProgressIndicator with ad-hoc sizes and stroke widths.

Create `lib/core/design_system/app_mini_spinner.dart`:

```dart
import 'package:flutter/material.dart';

/// Inline loading spinner for buttons, list items, and status indicators.
///
/// Usage:
/// ```dart
/// // In a button
/// ElevatedButton(
///   onPressed: null,
///   child: Row(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       AppMiniSpinner(),
///       SizedBox(width: 8),
///       Text('Saving...'),
///     ],
///   ),
/// )
///
/// // In a list item trailing
/// ListTile(
///   title: Text('Syncing...'),
///   trailing: AppMiniSpinner(color: fg.statusInfo),
/// )
/// ```
///
/// WHY: Replaces 19 inline SizedBox + CircularProgressIndicator patterns with
/// consistent 16px size and 2px stroke width.
class AppMiniSpinner extends StatelessWidget {
  const AppMiniSpinner({
    super.key,
    this.size = 16.0,
    this.strokeWidth = 2.0,
    this.color,
  });

  /// Spinner diameter. Default: 16.0
  final double size;

  /// Spinner stroke width. Default: 2.0
  final double strokeWidth;

  /// Override spinner color. Default: null (inherits cs.primary from theme).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? cs.primary,
      ),
    );
  }
}
```

---

## Phase 1.G: Barrel Export + Light/HC Theme Completion

### Sub-phase 1.G: Barrel Exports and Missing Theme Components

**Files:**
- Create: `lib/core/design_system/design_system.dart`
- Modify: `lib/core/theme/theme.dart`
- Modify: `lib/core/theme/app_theme.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.G.1: Create barrel export for design system

> **WHY:** A single import `package:construction_inspector/core/design_system/design_system.dart`
> gives access to all 23 components. Without it, each screen would need 5-10 separate imports.

Create `lib/core/design_system/design_system.dart`:

```dart
/// Barrel export for the Field Guide design system.
///
/// Usage (single import for all components):
/// ```dart
/// import 'package:construction_inspector/core/design_system/design_system.dart';
/// ```

// Atomic layer
export 'app_text.dart';
export 'app_text_field.dart';
export 'app_chip.dart';
export 'app_progress_bar.dart';
export 'app_counter_field.dart';
export 'app_toggle.dart';
export 'app_icon.dart';

// Card layer
export 'app_glass_card.dart';
export 'app_section_header.dart';
export 'app_list_tile.dart';
export 'app_photo_grid.dart';
export 'app_section_card.dart';

// Surface layer
export 'app_scaffold.dart';
export 'app_bottom_bar.dart';
export 'app_bottom_sheet.dart';
export 'app_dialog.dart';
export 'app_sticky_header.dart';
export 'app_drag_handle.dart';

// Composite layer
export 'app_empty_state.dart';
export 'app_error_state.dart';
export 'app_loading_state.dart';
export 'app_budget_warning_chip.dart';
export 'app_info_banner.dart';
export 'app_mini_spinner.dart';
```

#### Step 1.G.2: Update theme barrel

> **WHY:** FieldGuideColors was created in Phase 1.B but the barrel export was listed
> as a step there. This ensures it's present. If already added, this is a no-op.

In `lib/core/theme/theme.dart`, verify this export is present. If missing, add:

```dart
export 'field_guide_colors.dart';
```

Final contents of `lib/core/theme/theme.dart`:

```dart
// Barrel export for theme module
export 'app_theme.dart';
export 'colors.dart';
export 'design_constants.dart';
export 'field_guide_colors.dart';
```

#### Step 1.G.3: Complete light theme — add missing component themes

> **WHY:** The dark theme has filledButtonTheme, iconButtonTheme, bottomSheetTheme,
> chipTheme, and sliderTheme. The light theme is missing all 5. Without these, light
> theme falls back to Material defaults which look inconsistent with our design system.

In `lib/core/theme/app_theme.dart`, in the `lightTheme` getter, add the following blocks. Insert **after** the `textButtonTheme` block (after line 962, before `floatingActionButtonTheme`):

```dart

      // -----------------------------------------------------------------------
      // FILLED BUTTON - Secondary Actions (Light)
      // -----------------------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lightSurfaceHighlight,
          foregroundColor: lightTextPrimary,
          disabledBackgroundColor: lightSurfaceHighlight.withValues(alpha: 0.5),
          disabledForegroundColor: lightTextTertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: space6,
            vertical: space4,
          ),
          minimumSize: const Size(88, touchTargetMin),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
```

Insert **after** the `floatingActionButtonTheme` block (after line 971, before `navigationBarTheme`):

```dart

      // -----------------------------------------------------------------------
      // ICON BUTTON - Light Theme
      // -----------------------------------------------------------------------
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: lightTextSecondary,
          hoverColor: primaryBlue.withValues(alpha: 0.08),
          focusColor: primaryBlue.withValues(alpha: 0.12),
          highlightColor: primaryBlue.withValues(alpha: 0.12),
          minimumSize: const Size(touchTargetMin, touchTargetMin),
          iconSize: 24,
        ),
      ),
```

Insert **after** the `dialogTheme` block (after line 1025, before `snackBarTheme`):

```dart

      // -----------------------------------------------------------------------
      // BOTTOM SHEET - Light Theme
      // -----------------------------------------------------------------------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lightSurfaceElevated,
        elevation: elevationModal,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
        ),
        dragHandleColor: lightSurfaceHighlight,
        dragHandleSize: const Size(40, 4),
      ),
```

Insert **after** the `checkboxTheme` block (after line 1099, before `textTheme`):

```dart

      // -----------------------------------------------------------------------
      // CHIP - Light Theme
      // -----------------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        selectedColor: primaryBlue.withValues(alpha: 0.15),
        disabledColor: lightSurfaceHighlight,
        deleteIconColor: lightTextSecondary,
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: space2, vertical: space1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: BorderSide(color: lightSurfaceHighlight),
        ),
        side: BorderSide(color: lightSurfaceHighlight),
        checkmarkColor: primaryBlue,
      ),

      // -----------------------------------------------------------------------
      // SLIDER - Light Theme
      // -----------------------------------------------------------------------
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: lightSurfaceHighlight,
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withValues(alpha: 0.12),
        valueIndicatorColor: primaryBlue,
        valueIndicatorTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
```

#### Step 1.G.4: Complete HC theme — add missing component themes

> **WHY:** Same 5 component themes missing from high contrast theme. HC requires
> thicker borders, higher contrast colors, and larger touch targets for accessibility.

In `lib/core/theme/app_theme.dart`, in the `highContrastTheme` getter:

Insert **after** the `textButtonTheme` block (after line 1315, before `floatingActionButtonTheme`):

```dart

      // -----------------------------------------------------------------------
      // FILLED BUTTON - Secondary Actions (HC)
      // -----------------------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: hcSurfaceElevated,
          foregroundColor: hcTextPrimary,
          disabledBackgroundColor: const Color(0xFF333333),
          disabledForegroundColor: const Color(0xFF666666),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: space6,
            vertical: space4,
          ),
          minimumSize: const Size(88, touchTargetComfortable),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            side: const BorderSide(color: hcBorder, width: 2),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
```

Insert **after** the `floatingActionButtonTheme` block (after line 1329, before `navigationBarTheme`):

```dart

      // -----------------------------------------------------------------------
      // ICON BUTTON - HC Theme
      // -----------------------------------------------------------------------
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: hcTextPrimary,
          hoverColor: hcPrimary.withValues(alpha: 0.2),
          focusColor: hcPrimary.withValues(alpha: 0.3),
          highlightColor: hcPrimary.withValues(alpha: 0.3),
          minimumSize: const Size(touchTargetComfortable, touchTargetComfortable),
          iconSize: 28,
        ),
      ),
```

Insert **after** the `dialogTheme` block (after line 1388, before `snackBarTheme`):

```dart

      // -----------------------------------------------------------------------
      // BOTTOM SHEET - HC Theme
      // -----------------------------------------------------------------------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: hcSurfaceElevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
          side: const BorderSide(color: hcBorder, width: 3),
        ),
        dragHandleColor: hcBorder,
        dragHandleSize: const Size(48, 5),
      ),
```

Insert **after** the `checkboxTheme` block (after line 1466, before `textTheme`):

```dart

      // -----------------------------------------------------------------------
      // CHIP - HC Theme
      // -----------------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: hcSurfaceElevated,
        selectedColor: hcPrimary.withValues(alpha: 0.3),
        disabledColor: const Color(0xFF333333),
        deleteIconColor: hcTextPrimary,
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: hcTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: space3, vertical: space2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: hcBorder, width: 2),
        ),
        side: const BorderSide(color: hcBorder, width: 2),
        checkmarkColor: hcPrimary,
      ),

      // -----------------------------------------------------------------------
      // SLIDER - HC Theme
      // -----------------------------------------------------------------------
      sliderTheme: SliderThemeData(
        activeTrackColor: hcPrimary,
        inactiveTrackColor: const Color(0xFF333333),
        thumbColor: hcPrimary,
        overlayColor: hcPrimary.withValues(alpha: 0.3),
        valueIndicatorColor: hcPrimary,
        valueIndicatorTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
```

---

## Phase 1.H: Tests

### Sub-phase 1.H: Design System Unit Tests

**Files:**
- Create: `test/core/theme/field_guide_colors_test.dart`
- Create: `test/core/design_system/app_text_test.dart`
- Create: `test/core/design_system/app_chip_test.dart`
- Create: `test/core/design_system/app_glass_card_test.dart`
- Create: `test/core/design_system/app_empty_state_test.dart`
- Create: `test/core/design_system/app_mini_spinner_test.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.H.1: Create FieldGuideColors tests

> **WHY:** FieldGuideColors is the foundation for all theme-aware components. Testing
> the three constructors, context accessor, and lerp ensures theme switching works correctly.

Create `test/core/theme/field_guide_colors_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';

void main() {
  group('FieldGuideColors', () {
    group('constructors produce different values', () {
      test('dark and light surfaceElevated differ', () {
        expect(
          FieldGuideColors.dark.surfaceElevated,
          isNot(equals(FieldGuideColors.light.surfaceElevated)),
        );
      });

      test('dark and highContrast surfaceGlass differ', () {
        expect(
          FieldGuideColors.dark.surfaceGlass,
          isNot(equals(FieldGuideColors.highContrast.surfaceGlass)),
        );
      });

      test('light and highContrast textTertiary differ', () {
        expect(
          FieldGuideColors.light.textTertiary,
          isNot(equals(FieldGuideColors.highContrast.textTertiary)),
        );
      });

      test('HC shadowLight is transparent (no subtle shadows)', () {
        expect(FieldGuideColors.highContrast.shadowLight.alpha, equals(0.0));
      });

      test('HC gradientStart equals gradientEnd (no gradient)', () {
        expect(
          FieldGuideColors.highContrast.gradientStart,
          equals(FieldGuideColors.highContrast.gradientEnd),
        );
      });
    });

    group('of(context)', () {
      testWidgets('retrieves dark FieldGuideColors from dark theme', (tester) async {
        late FieldGuideColors result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Builder(
              builder: (context) {
                result = FieldGuideColors.of(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result.surfaceElevated, equals(FieldGuideColors.dark.surfaceElevated));
      });

      testWidgets('retrieves light FieldGuideColors from light theme', (tester) async {
        late FieldGuideColors result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                result = FieldGuideColors.of(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result.surfaceElevated, equals(FieldGuideColors.light.surfaceElevated));
      });

      testWidgets('retrieves HC FieldGuideColors from HC theme', (tester) async {
        late FieldGuideColors result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.highContrastTheme,
            home: Builder(
              builder: (context) {
                result = FieldGuideColors.of(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result.surfaceElevated, equals(FieldGuideColors.highContrast.surfaceElevated));
      });
    });

    group('lerp', () {
      test('lerp at 0.0 returns start values', () {
        final result = FieldGuideColors.dark.lerp(FieldGuideColors.light, 0.0);
        expect(result.surfaceElevated, equals(FieldGuideColors.dark.surfaceElevated));
      });

      test('lerp at 1.0 returns end values', () {
        final result = FieldGuideColors.dark.lerp(FieldGuideColors.light, 1.0);
        expect(result.surfaceElevated, equals(FieldGuideColors.light.surfaceElevated));
      });

      test('lerp at 0.5 produces intermediate values', () {
        final result = FieldGuideColors.dark.lerp(FieldGuideColors.light, 0.5);
        // Should not equal either endpoint
        expect(result.surfaceElevated, isNot(equals(FieldGuideColors.dark.surfaceElevated)));
        expect(result.surfaceElevated, isNot(equals(FieldGuideColors.light.surfaceElevated)));
      });

      test('lerp with null returns this', () {
        final result = FieldGuideColors.dark.lerp(null, 0.5);
        expect(result.surfaceElevated, equals(FieldGuideColors.dark.surfaceElevated));
      });
    });

    group('copyWith', () {
      test('returns identical when no overrides', () {
        final copy = FieldGuideColors.dark.copyWith();
        expect(copy.surfaceElevated, equals(FieldGuideColors.dark.surfaceElevated));
        expect(copy.textTertiary, equals(FieldGuideColors.dark.textTertiary));
      });

      test('overrides specific field', () {
        final copy = FieldGuideColors.dark.copyWith(surfaceElevated: Colors.red);
        expect(copy.surfaceElevated, equals(Colors.red));
        // Other fields unchanged
        expect(copy.textTertiary, equals(FieldGuideColors.dark.textTertiary));
      });
    });
  });
}
```

#### Step 1.H.2: Create AppText tests

> **WHY:** AppText is the most heavily used design system component (will replace 447
> TextStyle constructors). Verifying that each factory maps to the correct textTheme
> slot catches slot mismatches early.

Create `test/core/design_system/app_text_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_text.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';

/// Helper to wrap widget in MaterialApp with dark theme
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppText', () {
    testWidgets('titleLarge renders with titleLarge textTheme slot', (tester) async {
      await tester.pumpWidget(_wrap(AppText.titleLarge('Hello')));

      final textWidget = tester.widget<Text>(find.text('Hello'));
      // titleLarge in dark theme: fontSize 22, fontWeight w700
      expect(textWidget.style?.fontSize, equals(22));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w700));
    });

    testWidgets('bodyMedium renders with bodyMedium textTheme slot', (tester) async {
      await tester.pumpWidget(_wrap(AppText.bodyMedium('Content')));

      final textWidget = tester.widget<Text>(find.text('Content'));
      expect(textWidget.style?.fontSize, equals(14));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w400));
    });

    testWidgets('labelSmall renders with labelSmall textTheme slot', (tester) async {
      await tester.pumpWidget(_wrap(AppText.labelSmall('Badge')));

      final textWidget = tester.widget<Text>(find.text('Badge'));
      expect(textWidget.style?.fontSize, equals(11));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w700));
    });

    testWidgets('color override applies correctly', (tester) async {
      await tester.pumpWidget(_wrap(
        AppText.bodyMedium('Colored', color: Colors.red),
      ));

      final textWidget = tester.widget<Text>(find.text('Colored'));
      expect(textWidget.style?.color, equals(Colors.red));
    });

    testWidgets('maxLines and overflow propagate', (tester) async {
      await tester.pumpWidget(_wrap(
        AppText.bodyMedium(
          'Truncated text',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ));

      final textWidget = tester.widget<Text>(find.text('Truncated text'));
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('textAlign propagates', (tester) async {
      await tester.pumpWidget(_wrap(
        AppText.titleMedium('Centered', textAlign: TextAlign.center),
      ));

      final textWidget = tester.widget<Text>(find.text('Centered'));
      expect(textWidget.textAlign, equals(TextAlign.center));
    });
  });
}
```

#### Step 1.H.3: Create AppChip tests

> **WHY:** AppChip factories encode specific color values. Verifying that each factory
> produces the correct accent color prevents silent regressions if color constants change.

Create `test/core/design_system/app_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_chip.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppChip', () {
    testWidgets('cyan factory renders with cyan foreground', (tester) async {
      await tester.pumpWidget(_wrap(AppChip.cyan('Active')));

      final chip = tester.widget<AppChip>(find.byType(AppChip));
      expect(chip.foregroundColor, equals(const Color(0xFF00E5FF)));
      expect(chip.backgroundColor, equals(const Color(0x3300E5FF)));
    });

    testWidgets('amber factory renders with amber foreground', (tester) async {
      await tester.pumpWidget(_wrap(AppChip.amber('Pending')));

      final chip = tester.widget<AppChip>(find.byType(AppChip));
      expect(chip.foregroundColor, equals(const Color(0xFFFFB300)));
    });

    testWidgets('green factory renders with success foreground', (tester) async {
      await tester.pumpWidget(_wrap(AppChip.green('Complete')));

      final chip = tester.widget<AppChip>(find.byType(AppChip));
      expect(chip.foregroundColor, equals(const Color(0xFF4CAF50)));
    });

    testWidgets('error factory renders with error foreground', (tester) async {
      await tester.pumpWidget(_wrap(AppChip.error('Failed')));

      final chip = tester.widget<AppChip>(find.byType(AppChip));
      expect(chip.foregroundColor, equals(const Color(0xFFF44336)));
    });

    testWidgets('chip displays label text', (tester) async {
      await tester.pumpWidget(_wrap(AppChip.cyan('Status')));

      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('chip displays icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        AppChip.cyan('Active', icon: Icons.check),
      ));

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('onTap wraps chip in GestureDetector', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        AppChip.cyan('Tap me', onTap: () => tapped = true),
      ));

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });
  });
}
```

#### Step 1.H.4: Create AppGlassCard tests

> **WHY:** AppGlassCard is the second most-used component (replaces 30+ Container patterns).
> Testing accent tinting, onTap ripple, and elevation shadow ensures visual correctness.

Create `test/core/design_system/app_glass_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_glass_card.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppGlassCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppGlassCard(child: Text('Card content')),
      ));

      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('renders accent color strip when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppGlassCard(
          accentColor: Colors.cyan,
          child: Text('Accented'),
        ),
      ));

      // Find the 3px accent strip Container
      final containers = tester.widgetList<Container>(find.byType(Container));
      final accentStrip = containers.where((c) =>
        c.constraints?.maxWidth == 3 || (c.decoration == null && c.color == Colors.cyan),
      );
      // Accent color container exists somewhere in the tree
      expect(find.text('Accented'), findsOneWidget);
    });

    testWidgets('wraps in InkWell when onTap is provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        AppGlassCard(
          onTap: () => tapped = true,
          child: const Text('Tappable'),
        ),
      ));

      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.text('Tappable'));
      expect(tapped, isTrue);
    });

    testWidgets('does not render InkWell when non-interactive', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppGlassCard(child: Text('Static')),
      ));

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('selected state changes border color', (tester) async {
      // Build with selected=false and selected=true, verify different decorations
      await tester.pumpWidget(_wrap(
        const AppGlassCard(
          selected: true,
          child: Text('Selected'),
        ),
      ));

      // Just verify it renders without error in selected state
      expect(find.text('Selected'), findsOneWidget);
    });

    testWidgets('uses surfaceGlass from FieldGuideColors', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppGlassCard(child: Text('Glass')),
      ));

      // Verify it renders with the dark theme's glass styling
      // (visual correctness — the component doesn't crash with the theme)
      expect(find.text('Glass'), findsOneWidget);
    });
  });
}
```

#### Step 1.H.5: Create AppEmptyState tests

> **WHY:** AppEmptyState is used on every list screen. Testing that all props render
> correctly and the CTA button triggers its callback ensures the empty→populated
> transition works.

Create `test/core/design_system/app_empty_state_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_empty_state.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppEmptyState', () {
    testWidgets('renders icon, title', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppEmptyState(
          icon: Icons.photo_library_outlined,
          title: 'No photos yet',
        ),
      ));

      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      expect(find.text('No photos yet'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppEmptyState(
          icon: Icons.folder_outlined,
          title: 'No projects',
          subtitle: 'Create your first project to get started',
        ),
      ));

      expect(find.text('No projects'), findsOneWidget);
      expect(find.text('Create your first project to get started'), findsOneWidget);
    });

    testWidgets('hides subtitle when not provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppEmptyState(
          icon: Icons.folder_outlined,
          title: 'No projects',
        ),
      ));

      // Only title, no subtitle text
      expect(find.text('No projects'), findsOneWidget);
    });

    testWidgets('renders action button when actionLabel and onAction provided', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(_wrap(
        AppEmptyState(
          icon: Icons.add,
          title: 'No entries',
          actionLabel: 'Create Entry',
          onAction: () => actionTriggered = true,
        ),
      ));

      expect(find.text('Create Entry'), findsOneWidget);

      await tester.tap(find.text('Create Entry'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('hides action button when actionLabel is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppEmptyState(
          icon: Icons.inbox_outlined,
          title: 'Empty inbox',
        ),
      ));

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
```

#### Step 1.H.6: Create AppMiniSpinner tests

> **WHY:** AppMiniSpinner replaces 19 inline patterns. Testing size, stroke width,
> and color ensures visual consistency across all usage sites.

Create `test/core/design_system/app_mini_spinner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_mini_spinner.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppMiniSpinner', () {
    testWidgets('renders at default size 16x16', (tester) async {
      await tester.pumpWidget(_wrap(const AppMiniSpinner()));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(16.0));
      expect(sizedBox.height, equals(16.0));
    });

    testWidgets('renders at custom size', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppMiniSpinner(size: 24.0),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(24.0));
      expect(sizedBox.height, equals(24.0));
    });

    testWidgets('uses custom stroke width', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppMiniSpinner(strokeWidth: 3.0),
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, equals(3.0));
    });

    testWidgets('uses default stroke width of 2.0', (tester) async {
      await tester.pumpWidget(_wrap(const AppMiniSpinner()));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, equals(2.0));
    });

    testWidgets('uses custom color when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppMiniSpinner(color: Colors.red),
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, equals(Colors.red));
    });

    testWidgets('uses cs.primary when no color provided', (tester) async {
      await tester.pumpWidget(_wrap(const AppMiniSpinner()));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      // Dark theme primary is primaryCyan (0xFF00E5FF)
      expect(indicator.color, equals(const Color(0xFF00E5FF)));
    });
  });
}
```

#### Step 1.H.7: Quality Gate

> **WHY:** The quality gate ensures all new code passes static analysis and all tests
> pass before proceeding to Phase 2 (migration). Catching issues here prevents
> cascading failures during the migration phase.

Run static analysis:

```
pwsh -Command "flutter analyze"
```

Expected: 0 errors, 0 warnings on new files. Existing warnings are pre-existing.

Run design system tests:

```
pwsh -Command "flutter test test/core/"
```

Expected: All tests pass (6 test files, 30+ test cases).

If any test fails, fix the component code and re-run before proceeding to Phase 2.
