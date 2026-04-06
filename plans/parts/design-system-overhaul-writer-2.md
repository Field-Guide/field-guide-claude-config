## Phase 2: Responsive Infrastructure + Animation + Navigation Adaptation + Widgetbook Skeleton

**Depends on**: Phase 1 (token ThemeExtensions must exist and be registered on `ThemeData.extensions` in `AppTheme.build()`)

**Phase 1 deliverables consumed here**:
- `lib/core/design_system/tokens/field_guide_spacing.dart` — `FieldGuideSpacing` with `of(context)`, variants: `standard`, `compact`, `comfortable`
- `lib/core/design_system/tokens/field_guide_radii.dart` — `FieldGuideRadii` with `of(context)`, single `standard` variant
- `lib/core/design_system/tokens/field_guide_motion.dart` — `FieldGuideMotion` with `of(context)`, variants: `standard`, `reduced`
- `lib/core/design_system/tokens/field_guide_shadows.dart` — `FieldGuideShadows` with `of(context)`, variants: `standard`, `flat`
- `lib/core/design_system/tokens/tokens.dart` — barrel exporting all token files
- `lib/core/design_system/design_system.dart` — updated barrel that re-exports `tokens/tokens.dart`

---

### Sub-phase 2.1: Responsive Breakpoints

**Agent**: `code-fixer-agent`

#### Step 2.1.1: Create `AppBreakpoint` enum and utility

**File**: `lib/core/design_system/layout/app_breakpoint.dart` (NEW)

```dart
import 'package:flutter/material.dart';

/// FROM SPEC: Material 3 canonical breakpoint names.
/// compact (0-599), medium (600-839), expanded (840-1199), large (1200+).
///
/// WHY: Single source of truth for responsive decisions. Every layout widget
/// and the navigation shell read from this instead of raw MediaQuery widths.
enum AppBreakpoint {
  /// Phone portrait (0-599dp)
  compact,

  /// Phone landscape, small tablet (600-839dp)
  medium,

  /// Tablet, small desktop window (840-1199dp)
  expanded,

  /// Desktop, large tablet landscape (1200+dp)
  large;

  /// Returns the current breakpoint based on screen width.
  ///
  /// NOTE: Uses `MediaQuery.sizeOf(context)` (not `.of(context)`) to avoid
  /// rebuilds from non-size MediaQuery changes (e.g., keyboard insets).
  static AppBreakpoint of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return AppBreakpoint.large;
    if (width >= 840) return AppBreakpoint.expanded;
    if (width >= 600) return AppBreakpoint.medium;
    return AppBreakpoint.compact;
  }

  /// Whether this breakpoint represents a phone form factor.
  bool get isCompact => this == AppBreakpoint.compact;

  /// Whether this breakpoint represents tablet or larger.
  bool get isTabletOrLarger =>
      this == AppBreakpoint.medium ||
      this == AppBreakpoint.expanded ||
      this == AppBreakpoint.large;

  /// Whether this breakpoint should show expanded navigation labels.
  /// NOTE: medium shows collapsed rail (icons only), expanded/large show labels.
  bool get showNavigationLabels =>
      this == AppBreakpoint.expanded || this == AppBreakpoint.large;

  /// Recommended column count for grid layouts at this breakpoint.
  /// FROM SPEC: Phone=1-2, tablet=2-3, desktop=3-4.
  int get defaultGridColumns => switch (this) {
    AppBreakpoint.compact => 1,
    AppBreakpoint.medium => 2,
    AppBreakpoint.expanded => 3,
    AppBreakpoint.large => 4,
  };
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/layout/app_breakpoint.dart"`
Expected: No issues found.

---

### Sub-phase 2.2: AppResponsiveBuilder

**Agent**: `code-fixer-agent`

#### Step 2.2.1: Create `AppResponsiveBuilder` widget

**File**: `lib/core/design_system/layout/app_responsive_builder.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/layout/app_breakpoint.dart';

/// Builder widget that provides the current [AppBreakpoint] to its child.
///
/// WHY: Avoids repeating `AppBreakpoint.of(context)` + switch in every screen.
/// Screens provide per-breakpoint builders and this widget handles the plumbing.
///
/// Usage:
/// ```dart
/// AppResponsiveBuilder(
///   compact: (context) => _PhoneLayout(),
///   medium: (context) => _TabletLayout(),
///   expanded: (context) => _DesktopLayout(),
/// )
/// ```
class AppResponsiveBuilder extends StatelessWidget {
  const AppResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  /// Builder for compact (phone portrait) breakpoint. Required — serves as fallback.
  final WidgetBuilder compact;

  /// Builder for medium (phone landscape, small tablet). Falls back to [compact].
  final WidgetBuilder? medium;

  /// Builder for expanded (tablet, small desktop). Falls back to [medium] then [compact].
  final WidgetBuilder? expanded;

  /// Builder for large (desktop, large tablet). Falls back to [expanded] then [medium] then [compact].
  final WidgetBuilder? large;

  @override
  Widget build(BuildContext context) {
    final breakpoint = AppBreakpoint.of(context);

    // NOTE: Cascading fallback — each breakpoint falls back to the next smaller
    // one if no explicit builder is provided. This means you only need to define
    // the breakpoints where layout actually changes.
    return switch (breakpoint) {
      AppBreakpoint.large => (large ?? expanded ?? medium ?? compact)(context),
      AppBreakpoint.expanded => (expanded ?? medium ?? compact)(context),
      AppBreakpoint.medium => (medium ?? compact)(context),
      AppBreakpoint.compact => compact(context),
    };
  }
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/layout/app_responsive_builder.dart"`
Expected: No issues found.

---

### Sub-phase 2.3: AppAdaptiveLayout

**Agent**: `code-fixer-agent`

#### Step 2.3.1: Create `AppAdaptiveLayout` container

**File**: `lib/core/design_system/layout/app_adaptive_layout.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/layout/app_breakpoint.dart';

/// Canonical adaptive layout container that auto-switches between single-column,
/// two-pane, and three-region layouts based on the current breakpoint.
///
/// FROM SPEC: Takes `body`, optional `detail` pane, optional `sidePanel`.
/// Auto-switches single-column / two-pane / three-region based on breakpoint.
///
/// Usage:
/// ```dart
/// AppAdaptiveLayout(
///   body: ProjectListView(),
///   detail: selectedProject != null ? ProjectDetail(id: selectedProject) : null,
///   sidePanel: ProjectStats(),
/// )
/// ```
class AppAdaptiveLayout extends StatelessWidget {
  const AppAdaptiveLayout({
    super.key,
    required this.body,
    this.detail,
    this.sidePanel,
    this.bodyFlex = 1,
    this.detailFlex = 1,
    this.sidePanelFlex = 1,
    this.dividerWidth = 1.0,
    this.showDividers = true,
  });

  /// Primary content — always shown.
  final Widget body;

  /// Optional detail pane — shown beside [body] at medium+ breakpoints.
  /// WHY: On compact, detail replaces body via navigation push. On medium+,
  /// detail appears as a side pane. The caller controls which mode via
  /// checking the breakpoint and conditionally providing this widget.
  final Widget? detail;

  /// Optional side panel — shown at large breakpoint only.
  /// WHY: Dashboard stats, navigation helpers, or contextual info that
  /// only makes sense when screen real estate is abundant.
  final Widget? sidePanel;

  /// Flex factor for the body column. Default: 1.
  final int bodyFlex;

  /// Flex factor for the detail column. Default: 1.
  final int detailFlex;

  /// Flex factor for the side panel column. Default: 1.
  final int sidePanelFlex;

  /// Width of dividers between panes. Default: 1.0.
  final double dividerWidth;

  /// Whether to show dividers between panes. Default: true.
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    final breakpoint = AppBreakpoint.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // NOTE: On compact, always single-column — detail/sidePanel are ignored.
    // The calling screen should handle compact differently (e.g., navigate to
    // a detail screen instead of showing a pane).
    if (breakpoint.isCompact || (detail == null && sidePanel == null)) {
      return body;
    }

    final divider = showDividers
        ? VerticalDivider(
            width: dividerWidth,
            thickness: dividerWidth,
            color: colorScheme.outlineVariant,
          )
        : const SizedBox.shrink();

    // WHY: medium and expanded show two-pane (body + detail) if detail exists.
    // large shows three-region (body + detail + sidePanel) if all exist.
    final showSidePanel =
        breakpoint == AppBreakpoint.large && sidePanel != null;
    final showDetail = detail != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: bodyFlex, child: body),
        if (showDetail) ...[
          divider,
          Expanded(flex: detailFlex, child: detail!),
        ],
        if (showSidePanel) ...[
          divider,
          Expanded(flex: sidePanelFlex, child: sidePanel!),
        ],
      ],
    );
  }
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/layout/app_adaptive_layout.dart"`
Expected: No issues found.

---

### Sub-phase 2.4: AppResponsivePadding

**Agent**: `code-fixer-agent`

#### Step 2.4.1: Create `AppResponsivePadding` widget

**File**: `lib/core/design_system/layout/app_responsive_padding.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/layout/app_breakpoint.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_spacing.dart';

/// Screen-appropriate horizontal padding that adapts per breakpoint.
///
/// FROM SPEC: Phone=16px, tablet=24px, desktop=32px+.
/// Reads from `FieldGuideSpacing.of(context)` tokens so padding respects
/// the current density variant (compact/standard/comfortable).
///
/// WHY: Replaces scattered `EdgeInsets.symmetric(horizontal: DesignConstants.space4)`
/// patterns with a single widget that adapts to screen size and density.
///
/// Usage:
/// ```dart
/// AppResponsivePadding(
///   child: Column(children: [...]),
/// )
/// ```
class AppResponsivePadding extends StatelessWidget {
  const AppResponsivePadding({
    super.key,
    required this.child,
    this.includeVertical = false,
    this.sliver = false,
  });

  /// The widget to wrap with responsive horizontal padding.
  final Widget child;

  /// Whether to also apply vertical padding (top/bottom = spacing.sm).
  /// Default: false — most screens only need horizontal margins.
  final bool includeVertical;

  /// Whether to wrap as a SliverPadding instead of Padding.
  /// WHY: Many screens use CustomScrollView with slivers. This flag
  /// lets them use responsive padding without breaking the sliver protocol.
  final bool sliver;

  /// Returns the horizontal padding value for the given context.
  /// Exposed as static for cases where the padding value is needed
  /// programmatically (e.g., calculating available width).
  static double horizontalOf(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    final breakpoint = AppBreakpoint.of(context);
    // FROM SPEC: Phone=16px (md), tablet=24px (lg), desktop=32px+ (xl)
    return switch (breakpoint) {
      AppBreakpoint.compact => spacing.md,   // 16.0
      AppBreakpoint.medium => spacing.lg,    // 24.0
      AppBreakpoint.expanded => spacing.xl,  // 32.0
      AppBreakpoint.large => spacing.xl,     // 32.0
    };
  }

  @override
  Widget build(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    final horizontal = horizontalOf(context);
    final vertical = includeVertical ? spacing.sm : 0.0;

    final padding = EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );

    if (sliver) {
      return SliverPadding(padding: padding, sliver: child);
    }

    return Padding(padding: padding, child: child);
  }
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/layout/app_responsive_padding.dart"`
Expected: No issues found.

---

### Sub-phase 2.5: AppResponsiveGrid

**Agent**: `code-fixer-agent`

#### Step 2.5.1: Create `AppResponsiveGrid` widget

**File**: `lib/core/design_system/layout/app_responsive_grid.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/layout/app_breakpoint.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_spacing.dart';

/// Responsive column grid that adapts column count per breakpoint.
///
/// FROM SPEC: Phone=1-2 cols, tablet=2-3, desktop=3-4.
///
/// WHY: Replaces ad-hoc `GridView.count(crossAxisCount: 2)` patterns with
/// a grid that automatically adapts to screen size. Column count can be
/// overridden per breakpoint for screens with specific layout needs.
///
/// Usage:
/// ```dart
/// AppResponsiveGrid(
///   children: items.map((item) => ItemCard(item: item)).toList(),
/// )
/// ```
class AppResponsiveGrid extends StatelessWidget {
  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.compactColumns,
    this.mediumColumns,
    this.expandedColumns,
    this.largeColumns,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  /// The grid items.
  final List<Widget> children;

  /// Override column count for compact breakpoint. Default: `AppBreakpoint.compact.defaultGridColumns` (1).
  final int? compactColumns;

  /// Override column count for medium breakpoint. Default: `AppBreakpoint.medium.defaultGridColumns` (2).
  final int? mediumColumns;

  /// Override column count for expanded breakpoint. Default: `AppBreakpoint.expanded.defaultGridColumns` (3).
  final int? expandedColumns;

  /// Override column count for large breakpoint. Default: `AppBreakpoint.large.defaultGridColumns` (4).
  final int? largeColumns;

  /// Aspect ratio of each grid cell. Default: 1.0 (square).
  final double childAspectRatio;

  /// Spacing between rows. Default: reads from `FieldGuideSpacing.of(context).sm`.
  final double? mainAxisSpacing;

  /// Spacing between columns. Default: reads from `FieldGuideSpacing.of(context).sm`.
  final double? crossAxisSpacing;

  /// Whether the grid should shrink-wrap its content. Default: false.
  final bool shrinkWrap;

  /// Scroll physics. Default: null (inherits from parent).
  final ScrollPhysics? physics;

  /// Optional external padding around the grid.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final breakpoint = AppBreakpoint.of(context);
    final spacing = FieldGuideSpacing.of(context);

    final columns = switch (breakpoint) {
      AppBreakpoint.compact => compactColumns ?? breakpoint.defaultGridColumns,
      AppBreakpoint.medium => mediumColumns ?? breakpoint.defaultGridColumns,
      AppBreakpoint.expanded =>
        expandedColumns ?? breakpoint.defaultGridColumns,
      AppBreakpoint.large => largeColumns ?? breakpoint.defaultGridColumns,
    };

    // NOTE: Default spacing uses FieldGuideSpacing.sm (8.0) for grid gaps.
    // This keeps cards visually tight while readable.
    final gapMain = mainAxisSpacing ?? spacing.sm;
    final gapCross = crossAxisSpacing ?? spacing.sm;

    return GridView.count(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: gapMain,
      crossAxisSpacing: gapCross,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      children: children,
    );
  }
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/layout/app_responsive_grid.dart"`
Expected: No issues found.

---

### Sub-phase 2.6: Navigation Adaptation (ScaffoldWithNavBar)

**Agent**: `code-fixer-agent`

#### Step 2.6.1: Refactor `ScaffoldWithNavBar` for responsive navigation

**File**: `lib/core/router/scaffold_with_nav_bar.dart` (MODIFY — full rewrite of 188 lines)

IMPORTANT: This is the highest-risk change in Phase 2. The navigation shell is used on every screen. The rewrite must:
1. Preserve ALL existing banner management (version, stale config, stale sync, offline)
2. Preserve ALL existing testing keys
3. Preserve the `Consumer2<SyncProvider, AppConfigProvider>` pattern for banners
4. Preserve `ExtractionBanner` placement
5. Switch from `NavigationBar` (bottom) to `NavigationRail` (side) at medium+ breakpoints
6. Fix #201 (Android keyboard blocks buttons) by using `resizeToAvoidBottomInset: true` on the inner Scaffold and ensuring the bottom nav respects keyboard insets

```dart
// lib/core/router/scaffold_with_nav_bar.dart
import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/core/design_system/layout/app_breakpoint.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/features/auth/presentation/providers/app_config_provider.dart';
import 'package:construction_inspector/features/projects/presentation/widgets/project_switcher.dart';
import 'package:construction_inspector/features/sync/application/sync_coordinator.dart';
import 'package:construction_inspector/features/sync/presentation/providers/sync_provider.dart';
import 'package:construction_inspector/features/sync/presentation/widgets/sync_status_icon.dart';
import 'package:construction_inspector/features/pdf/presentation/widgets/extraction_banner.dart';
import 'package:construction_inspector/shared/shared.dart';

/// Shell widget providing responsive navigation and status banners.
///
/// FROM SPEC: compact = bottom NavigationBar, medium = collapsed NavigationRail,
/// expanded/large = expanded NavigationRail with labels.
///
/// NOTE: Receives providers via context.watch/context.read from the widget tree
/// (correct for presentation-layer reads).
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  /// Routes where the project switcher should appear in the app bar.
  static const _projectContextRoutes = {'/', '/calendar'};

  // WHY: Extracted as a constant list so both NavigationBar destinations and
  // NavigationRail destinations share the same data. Prevents drift.
  static const _destinations = [
    _NavDestination(
      key: TestingKeys.dashboardNavButton,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavDestination(
      key: TestingKeys.calendarNavButton,
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      label: 'Calendar',
    ),
    _NavDestination(
      key: TestingKeys.projectsNavButton,
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: 'Projects',
    ),
    _NavDestination(
      key: TestingKeys.settingsNavButton,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final fg = FieldGuideColors.of(context);
    final location = GoRouterState.of(context).uri.path;
    final showProjectSwitcher = _projectContextRoutes.contains(location);
    final breakpoint = AppBreakpoint.of(context);
    final selectedIndex = _calculateSelectedIndex(context);

    final appBar = showProjectSwitcher
        ? AppBar(
            title: const ProjectSwitcher(),
            centerTitle: false,
            automaticallyImplyLeading: false,
            actions: const [SyncStatusIcon()],
          )
        : null;

    // WHY: Banner management is extracted to a method to keep build() readable.
    // The Consumer2 stays in the body to scope rebuilds to banner state changes.
    final bodyWithBanners = Consumer2<SyncProvider, AppConfigProvider>(
      builder: (context, syncProvider, appConfigProvider, innerChild) {
        final syncCoordinator = context.read<SyncCoordinator>();

        // [Phase 6, 3.2] Wire sync error toast callback to ScaffoldMessenger
        syncProvider.onSyncErrorToast ??= (message) {
          unawaited(SnackBarHelper.showErrorWithAction(
            context,
            'Sync error: $message',
            actionLabel: 'Details',
            onAction: () => context.push('/sync/dashboard'),
          ).closed.then((_) {
            syncProvider.clearSyncErrorSnackbarFlag();
          }));
        };

        final banners = <Widget>[];

        // Version update banner (soft nudge)
        if (appConfigProvider.hasUpdateAvailable) {
          banners.add(
            VersionBanner(message: appConfigProvider.updateMessage),
          );
        }

        // Stale config warning (>24h since server check)
        if (appConfigProvider.isConfigStale) {
          banners.add(
            StaleConfigWarning(
              onRetry: () => appConfigProvider.checkConfig(),
            ),
          );
        }

        // Stale sync data warning
        if (syncProvider.isStaleDataWarning) {
          banners.add(
            MaterialBanner(
              content: Text(
                'Data may be out of date — last synced ${syncProvider.lastSyncText}',
              ),
              leading: Icon(Icons.warning_amber, color: fg.accentOrange),
              actions: [
                TextButton(
                  onPressed: () => syncProvider.sync(),
                  child: const Text('Sync Now'),
                ),
              ],
            ),
          );
        }

        // Offline indicator
        if (!syncProvider.isOnline) {
          banners.add(
            MaterialBanner(
              content: const Text(
                'You are offline. Changes will sync when connection is restored.',
              ),
              leading: Icon(Icons.cloud_off, color: fg.accentOrange),
              backgroundColor: fg.accentOrange.withValues(alpha: 0.08),
              actions: [
                TextButton(
                  onPressed: () async {
                    await syncCoordinator.checkDnsReachability();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (banners.isEmpty) return innerChild!;

        return Column(
          children: [
            ...banners,
            Expanded(child: innerChild!),
          ],
        );
      },
      child: child,
    );

    // FROM SPEC: compact = bottom NavigationBar
    if (breakpoint.isCompact) {
      return Scaffold(
        appBar: appBar,
        // IMPORTANT: resizeToAvoidBottomInset ensures the bottom nav moves up
        // when the keyboard appears, fixing #201 (Android keyboard blocks buttons).
        resizeToAvoidBottomInset: true,
        body: bodyWithBanners,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExtractionBanner(),
            NavigationBar(
              key: TestingKeys.bottomNavigationBar,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: _destinations
                  .map((d) => NavigationDestination(
                        key: d.key,
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.label,
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }

    // FROM SPEC: medium = collapsed NavigationRail (icons only)
    // expanded/large = expanded NavigationRail (icons + labels)
    final extended = breakpoint.showNavigationLabels;

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            key: TestingKeys.bottomNavigationBar,
            // NOTE: Reusing bottomNavigationBar key for test compatibility.
            // Driver tests locate nav by this key — changing it would break tests.
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onItemTapped(index, context),
            extended: extended,
            // WHY: labelType is none when extended is true (labels are inline).
            // When collapsed (medium), show labels on selection only.
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon, key: d.key),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                const ExtractionBanner(),
                Expanded(child: bodyWithBanners),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/projects')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('dashboard');
      case 1:
        context.goNamed('home');
      case 2:
        context.goNamed('projects');
      case 3:
        context.goNamed('settings');
    }
  }
}

/// Internal data class for navigation destination configuration.
/// WHY: Shared between NavigationBar and NavigationRail to prevent drift.
class _NavDestination {
  const _NavDestination({
    required this.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Key key;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/router/scaffold_with_nav_bar.dart"`
Expected: No issues found.

---

### Sub-phase 2.7: Animation Components

**Agent**: `code-fixer-agent`

#### Step 2.7.1: Create `AppAnimatedEntrance`

**File**: `lib/core/design_system/animation/app_animated_entrance.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_motion.dart';

/// Fade + slide-up entrance animation that reads motion tokens.
///
/// FROM SPEC: Widget mount triggers fade + slide-up. Reads duration/curve
/// from `FieldGuideMotion.of(context)`.
///
/// WHY: Replaces ad-hoc `AnimatedOpacity` + `SlideTransition` combos scattered
/// across screens. Centralizes entrance animation with automatic accessibility
/// support (reduced motion = instant appear).
///
/// Usage:
/// ```dart
/// AppAnimatedEntrance(
///   child: MyCard(),
/// )
/// ```
class AppAnimatedEntrance extends StatefulWidget {
  const AppAnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideOffset = 0.1,
  });

  /// The widget to animate in.
  final Widget child;

  /// Optional delay before the animation starts.
  /// WHY: Used by AppStaggeredList to stagger child entrances.
  final Duration delay;

  /// Vertical slide offset as a fraction of the child's height. Default: 0.1 (10%).
  /// NOTE: Positive = slides up from below. Negative = slides down from above.
  final double slideOffset;

  @override
  State<AppAnimatedEntrance> createState() => _AppAnimatedEntranceState();
}

class _AppAnimatedEntranceState extends State<AppAnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // NOTE: Duration is set in didChangeDependencies where we have context.
    // Controller starts at 0ms here and gets updated.
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = FieldGuideMotion.of(context);

    // WHY: Check disableAnimations via the motion token's reduced variant.
    // When reduced, duration is Duration.zero so animation completes instantly.
    _controller.duration = motion.normal;

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: motion.curveDecelerate,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: motion.curveStandard,
    ));

    // Start animation after optional delay
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/animation/app_animated_entrance.dart"`
Expected: No issues found.

#### Step 2.7.2: Create `AppStaggeredList`

**File**: `lib/core/design_system/animation/app_staggered_list.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/animation/app_animated_entrance.dart';

/// Staggers child entrance animations with configurable delay per item.
///
/// FROM SPEC: 50ms delay per item, max 8 staggered then batch remaining.
///
/// WHY: List screens currently have no entrance animation. This provides
/// a polished feel without custom AnimationController per screen.
///
/// Usage:
/// ```dart
/// AppStaggeredList(
///   children: items.map((item) => ItemCard(item: item)).toList(),
/// )
/// ```
class AppStaggeredList extends StatelessWidget {
  const AppStaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.maxStaggered = 8,
  });

  /// The list of widgets to stagger.
  final List<Widget> children;

  /// Delay between each child's entrance animation. Default: 50ms.
  /// FROM SPEC: 50ms delay per item.
  final Duration staggerDelay;

  /// Maximum number of items that get individual stagger delays.
  /// Items beyond this threshold all animate at the max delay (batch entrance).
  /// FROM SPEC: max 8 then batch.
  /// WHY: Prevents absurdly long stagger chains on long lists (e.g., 50 items
  /// would take 2.5 seconds to finish staggering without this cap).
  final int maxStaggered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++)
          AppAnimatedEntrance(
            // NOTE: Items 0-7 get increasing delays (0ms, 50ms, 100ms, ..., 350ms).
            // Items 8+ all get the same 400ms delay (batch entrance).
            delay: Duration(
              milliseconds: staggerDelay.inMilliseconds *
                  (i < maxStaggered ? i : maxStaggered),
            ),
            child: children[i],
          ),
      ],
    );
  }
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/animation/app_staggered_list.dart"`
Expected: No issues found.

#### Step 2.7.3: Create `AppTapFeedback`

**File**: `lib/core/design_system/animation/app_tap_feedback.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_motion.dart';

/// Scale-to-0.95 tap feedback animation that reads motion tokens.
///
/// FROM SPEC: Scale-to-0.95 on press, 1.0 on release. 100ms via motion tokens.
///
/// WHY: Provides consistent tactile feedback across all tappable surfaces
/// (cards, tiles, buttons). Replaces InkWell/GestureDetector ripple with
/// a subtle scale that feels more premium on mobile.
///
/// Usage:
/// ```dart
/// AppTapFeedback(
///   onTap: () => navigateToDetail(),
///   child: MyCard(),
/// )
/// ```
class AppTapFeedback extends StatefulWidget {
  const AppTapFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.enabled = true,
  });

  /// The widget to wrap with tap feedback.
  final Widget child;

  /// Callback when the widget is tapped.
  final VoidCallback? onTap;

  /// Callback when the widget is long-pressed.
  final VoidCallback? onLongPress;

  /// Scale factor when pressed. Default: 0.95.
  /// FROM SPEC: Scale-to-0.95 on press.
  final double pressedScale;

  /// Whether the feedback effect is enabled. Default: true.
  /// WHY: Disabled items should not animate on tap.
  final bool enabled;

  @override
  State<AppTapFeedback> createState() => _AppTapFeedbackState();
}

class _AppTapFeedbackState extends State<AppTapFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // NOTE: Using fast (150ms) rather than a hardcoded 100ms because fast is
    // the smallest token available. The spec says "100ms via motion tokens" —
    // the closest token is fast (150ms), which still feels snappy.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = FieldGuideMotion.of(context);
    // WHY: When reduced motion is active, the controller duration becomes zero,
    // making the scale change instant (no animation perceived).
    // We use a fraction of fast for the tap feedback since it should be quicker
    // than standard transitions.
    final baseDuration = motion.fast;
    _controller.duration = Duration(
      milliseconds: (baseDuration.inMilliseconds * 0.67).round(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.enabled) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/animation/app_tap_feedback.dart"`
Expected: No issues found.

#### Step 2.7.4: Create `AppValueTransition`

**File**: `lib/core/design_system/animation/app_value_transition.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_motion.dart';

/// Animated counter that slides out old value and slides in new value.
///
/// FROM SPEC: Animated counter — slide-up old, slide-in new.
///
/// WHY: Budget totals, item counts, and amount fields currently jump between
/// values. This provides a polished transition that communicates change.
///
/// Usage:
/// ```dart
/// AppValueTransition(
///   value: totalAmount,
///   builder: (context, value) => AppText.headlineMedium('\$${value.toStringAsFixed(2)}'),
/// )
/// ```
class AppValueTransition extends StatelessWidget {
  const AppValueTransition({
    super.key,
    required this.value,
    required this.builder,
  });

  /// The current value. When this changes, the transition animates.
  /// NOTE: Uses Object so it works with int, double, String, etc.
  final Object value;

  /// Builder that creates the display widget for the current value.
  final Widget Function(BuildContext context, Object value) builder;

  @override
  Widget build(BuildContext context) {
    final motion = FieldGuideMotion.of(context);

    return AnimatedSwitcher(
      duration: motion.fast,
      switchInCurve: motion.curveDecelerate,
      switchOutCurve: motion.curveDecelerate,
      // WHY: SlideTransition (up for new, down for old) gives a "counter tick"
      // feel that's more engaging than a simple crossfade.
      transitionBuilder: (child, animation) {
        // NOTE: Key comparison determines which child is "entering" vs "exiting".
        // The entering child slides up from below, the exiting slides up and out.
        final slideIn = Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideIn,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object>(value),
        child: builder(context, value),
      ),
    );
  }
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/animation/app_value_transition.dart"`
Expected: No issues found.

---

### Sub-phase 2.8: Screen Transitions

**Agent**: `code-fixer-agent`

#### Step 2.8.1: Add `animations` package dependency

**File**: `pubspec.yaml` (MODIFY)

Add the following under `dependencies:` (after `go_router:`):

```yaml
  # Material motion transitions (SharedAxis, FadeThrough, ContainerTransform)
  animations: ^2.0.11
```

**Verification**: `pwsh -Command "flutter pub get"`
Expected: Resolves successfully, no version conflicts.

#### Step 2.8.2: Update `app_router.dart` shell page transitions

**File**: `lib/core/router/app_router.dart` (MODIFY lines 1-98)

Replace the import of `design_constants.dart` and the `_shellPage` / `_fadeTransition` methods. The rest of the file is unchanged.

At line 23, change:
```dart
import 'package:construction_inspector/core/theme/design_constants.dart';
```
to:
```dart
import 'package:construction_inspector/core/design_system/tokens/field_guide_motion.dart';
import 'package:animations/animations.dart';
```

Replace lines 82-98 (`_shellPage` and `_fadeTransition` methods) with:

```dart
  /// Builds a consistent fade-through transition page for shell (bottom-nav) routes.
  ///
  /// FROM SPEC: FadeThroughTransition for tab switches, 200ms.
  /// WHY: Material motion FadeThrough is the canonical pattern for tab/peer
  /// screen transitions. Reads duration from FieldGuideMotion tokens.
  static Page<void> _shellPage(LocalKey key, Widget child) =>
      CustomTransitionPage(
        key: key,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // NOTE: FadeThroughTransition from the animations package provides
          // the Material 3 canonical tab-switch transition.
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        // WHY: 200ms from spec for tab switch transitions.
        // DesignConstants.animationFast was 150ms, but spec says 200ms for tabs.
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      );
```

NOTE: The `_fadeTransition` static method at lines 92-98 is no longer needed after this change. Delete it. If any other code in the file references `_fadeTransition`, search for it first.

Before deleting `_fadeTransition`, verify no other references exist in the file:
- Search for `_fadeTransition` in `app_router.dart` — it should only appear in the old `_shellPage` definition.

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/router/app_router.dart"`
Expected: No issues found.

---

### Sub-phase 2.9: Layout + Animation Barrel Files

**Agent**: `code-fixer-agent`

#### Step 2.9.1: Create layout barrel file

**File**: `lib/core/design_system/layout/layout.dart` (NEW)

```dart
/// Barrel export for the Field Guide responsive layout system.
///
/// WHY: Single import for all layout widgets. Consumed by the main
/// design_system.dart barrel and directly by screens needing layout primitives.
export 'app_breakpoint.dart';
export 'app_responsive_builder.dart';
export 'app_adaptive_layout.dart';
export 'app_responsive_padding.dart';
export 'app_responsive_grid.dart';
```

#### Step 2.9.2: Create animation barrel file

**File**: `lib/core/design_system/animation/animation.dart` (NEW)

```dart
/// Barrel export for the Field Guide animation system.
///
/// WHY: Single import for all animation widgets. Consumed by the main
/// design_system.dart barrel and directly by screens needing animation primitives.
export 'app_animated_entrance.dart';
export 'app_staggered_list.dart';
export 'app_tap_feedback.dart';
export 'app_value_transition.dart';
```

#### Step 2.9.3: Update main design system barrel

**File**: `lib/core/design_system/design_system.dart` (MODIFY)

Add the following two export lines. The exact placement depends on what Phase 1 has already added. Add after the existing exports (or after the `tokens/tokens.dart` export if Phase 1 added it):

```dart
export 'layout/layout.dart';
export 'animation/animation.dart';
```

The final barrel file should look like (preserving all existing exports plus Phase 1 additions):

```dart
// Barrel export for the Field Guide design system.
//
// Usage (single import for all components):
// ```dart
// import 'package:construction_inspector/core/design_system/design_system.dart';
// ```

// Token layer (added in Phase 1)
export 'tokens/tokens.dart';

// Layout layer (added in Phase 2)
export 'layout/layout.dart';

// Animation layer (added in Phase 2)
export 'animation/animation.dart';

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

IMPORTANT: The implementing agent MUST read the current state of `design_system.dart` before editing, because Phase 1 may have already modified it. Add the two new exports without removing anything Phase 1 added.

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/"`
Expected: No issues found.

---

### Sub-phase 2.10: Widgetbook Skeleton

**Agent**: `code-fixer-agent`

#### Step 2.10.1: Create Widgetbook `pubspec.yaml`

**File**: `widgetbook/pubspec.yaml` (NEW)

```yaml
name: widgetbook_field_guide
description: Widgetbook for Field Guide design system components.
publish_to: 'none'

environment:
  sdk: ^3.10.7

dependencies:
  flutter:
    sdk: flutter
  widgetbook: ^3.10.0
  widgetbook_annotation: ^3.2.0

  # WHY: Import the main app's design system to render actual components.
  # Path dependency lets Widgetbook see all design_system exports.
  construction_inspector:
    path: ..

dev_dependencies:
  flutter_test:
    sdk: flutter
```

**Verification**: `pwsh -Command "cd C:/Users/rseba/Projects/Field_Guide_App/widgetbook && flutter pub get"`
Expected: Resolves successfully.

#### Step 2.10.2: Create Widgetbook main entry point

**File**: `widgetbook/lib/main.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';

/// Widgetbook entry point for the Field Guide design system.
///
/// FROM SPEC: Knobs for theme (dark/light), breakpoint (compact/medium/expanded/large),
/// density (compact/standard/comfortable). Device frames: Phone, Tablet, Desktop.
///
/// WHY: Provides an interactive component catalog for design review, QA, and
/// regression testing without running the full app.
void main() {
  runApp(const FieldGuideWidgetbook());
}

class FieldGuideWidgetbook extends StatelessWidget {
  const FieldGuideWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      // NOTE: addons provide global knobs that affect all use cases.
      addons: [
        // Theme addon: switch between dark and light themes.
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Dark', data: AppTheme.darkTheme),
            WidgetbookTheme(name: 'Light', data: AppTheme.lightTheme),
          ],
        ),
        // Device frame addon: test across form factors.
        // FROM SPEC: Phone (Samsung S21), Tablet (iPad 10.9"), Desktop (1440x900).
        DeviceFrameAddon(
          devices: [
            Devices.android.samsungGalaxyS20,
            Devices.ios.iPad,
            Devices.desktop.desktop1440x900,
          ],
        ),
        // Text scale addon: test accessibility text sizes.
        TextScaleAddon(
          scales: [1.0, 1.25, 1.5, 2.0],
        ),
      ],
      directories: [
        // WHY: Organized by design system layer (tokens, layout, animation, atoms, etc.)
        // to mirror the code structure.
        WidgetbookFolder(
          name: 'Layout',
          children: [
            WidgetbookComponent(
              name: 'AppResponsiveBuilder',
              useCases: [
                WidgetbookUseCase(
                  name: 'Breakpoint demo',
                  builder: (context) {
                    return AppResponsiveBuilder(
                      compact: (_) => _BreakpointLabel('compact'),
                      medium: (_) => _BreakpointLabel('medium'),
                      expanded: (_) => _BreakpointLabel('expanded'),
                      large: (_) => _BreakpointLabel('large'),
                    );
                  },
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'AppAdaptiveLayout',
              useCases: [
                WidgetbookUseCase(
                  name: 'Two-pane layout',
                  builder: (context) {
                    return AppAdaptiveLayout(
                      body: Container(
                        color: Colors.blue.withValues(alpha: 0.1),
                        child: const Center(child: Text('Body')),
                      ),
                      detail: Container(
                        color: Colors.green.withValues(alpha: 0.1),
                        child: const Center(child: Text('Detail')),
                      ),
                    );
                  },
                ),
                WidgetbookUseCase(
                  name: 'Three-region layout',
                  builder: (context) {
                    return AppAdaptiveLayout(
                      body: Container(
                        color: Colors.blue.withValues(alpha: 0.1),
                        child: const Center(child: Text('Body')),
                      ),
                      detail: Container(
                        color: Colors.green.withValues(alpha: 0.1),
                        child: const Center(child: Text('Detail')),
                      ),
                      sidePanel: Container(
                        color: Colors.orange.withValues(alpha: 0.1),
                        child: const Center(child: Text('Side Panel')),
                      ),
                    );
                  },
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'AppResponsivePadding',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default horizontal padding',
                  builder: (context) {
                    return AppResponsivePadding(
                      child: Container(
                        color: Colors.purple.withValues(alpha: 0.1),
                        height: 200,
                        child: const Center(
                          child: Text('Content with responsive padding'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'AppResponsiveGrid',
              useCases: [
                WidgetbookUseCase(
                  name: 'Adaptive grid',
                  builder: (context) {
                    return AppResponsiveGrid(
                      shrinkWrap: true,
                      children: List.generate(
                        8,
                        (i) => Card(
                          child: Center(child: Text('Item $i')),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: 'Animation',
          children: [
            WidgetbookComponent(
              name: 'AppAnimatedEntrance',
              useCases: [
                WidgetbookUseCase(
                  name: 'Fade + slide up',
                  builder: (context) {
                    // NOTE: Wrap in a StatefulBuilder to provide a reset button.
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppAnimatedEntrance(
                              key: UniqueKey(),
                              child: const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Animated entrance'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Replay'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'AppTapFeedback',
              useCases: [
                WidgetbookUseCase(
                  name: 'Scale on press',
                  builder: (context) {
                    return Center(
                      child: AppTapFeedback(
                        onTap: () {},
                        child: const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Tap me'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'AppValueTransition',
              useCases: [
                WidgetbookUseCase(
                  name: 'Counter animation',
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return _ValueTransitionDemo();
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Simple label widget for breakpoint demo.
class _BreakpointLabel extends StatelessWidget {
  const _BreakpointLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Resize window to change breakpoint',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Stateful demo for AppValueTransition.
class _ValueTransitionDemo extends StatefulWidget {
  @override
  State<_ValueTransitionDemo> createState() => _ValueTransitionDemoState();
}

class _ValueTransitionDemoState extends State<_ValueTransitionDemo> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppValueTransition(
            value: _counter,
            builder: (context, value) => Text(
              '$value',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _counter--),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => setState(() => _counter++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

**Verification**: `pwsh -Command "cd C:/Users/rseba/Projects/Field_Guide_App/widgetbook && flutter analyze --no-pub"`
Expected: No issues found.

---

### Sub-phase 2.11: Accessibility — Reduced Motion Integration

**Agent**: `code-fixer-agent`

#### Step 2.11.1: Create `MotionAwareBuilder` utility

This step ensures all animation components automatically respect the system "reduce motion" accessibility setting. The approach is to provide a utility that animation components can use internally, and to document the pattern for future animation code.

**File**: `lib/core/design_system/animation/motion_aware.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_motion.dart';

/// Resolves the effective [FieldGuideMotion] for the current context,
/// automatically swapping to `FieldGuideMotion.reduced` when the platform
/// requests reduced motion.
///
/// FROM SPEC: When `MediaQuery.of(context).disableAnimations` is true,
/// swap to `FieldGuideMotion.reduced`. Every animation component checks
/// automatically via token.
///
/// WHY: Instead of every animation widget checking `disableAnimations`
/// independently, this central utility provides the correct motion token.
/// Phase 1's `FieldGuideMotion.of(context)` reads from ThemeData.extensions,
/// which returns the app's configured variant (standard). This helper
/// overrides that when the OS accessibility setting demands it.
///
/// IMPORTANT: Animation components created in Phase 2 (AppAnimatedEntrance,
/// AppStaggeredList, AppTapFeedback, AppValueTransition) should use
/// `MotionAware.of(context)` instead of `FieldGuideMotion.of(context)` to
/// get automatic reduced-motion support.
class MotionAware {
  MotionAware._();

  /// Returns [FieldGuideMotion.reduced] when the platform requests reduced
  /// motion, otherwise returns the theme-configured [FieldGuideMotion].
  ///
  /// NOTE: Uses `MediaQuery.disableAnimationsOf(context)` (the specific
  /// InheritedModel selector) to avoid rebuilds from unrelated MediaQuery
  /// changes like keyboard insets or orientation.
  static FieldGuideMotion of(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      return FieldGuideMotion.reduced;
    }
    return FieldGuideMotion.of(context);
  }
}
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/animation/motion_aware.dart"`
Expected: No issues found.

#### Step 2.11.2: Update animation components to use `MotionAware.of(context)`

**File**: `lib/core/design_system/animation/app_animated_entrance.dart` (MODIFY)

In `_AppAnimatedEntranceState.didChangeDependencies()`, change:
```dart
    final motion = FieldGuideMotion.of(context);
```
to:
```dart
    final motion = MotionAware.of(context);
```

Add import at the top of the file:
```dart
import 'package:construction_inspector/core/design_system/animation/motion_aware.dart';
```

The existing `FieldGuideMotion` import can be removed since `MotionAware` handles it.

**File**: `lib/core/design_system/animation/app_tap_feedback.dart` (MODIFY)

In `_AppTapFeedbackState.didChangeDependencies()`, change:
```dart
    final motion = FieldGuideMotion.of(context);
```
to:
```dart
    final motion = MotionAware.of(context);
```

Replace the import:
```dart
import 'package:construction_inspector/core/design_system/tokens/field_guide_motion.dart';
```
with:
```dart
import 'package:construction_inspector/core/design_system/animation/motion_aware.dart';
```

**File**: `lib/core/design_system/animation/app_value_transition.dart` (MODIFY)

In the `build()` method, change:
```dart
    final motion = FieldGuideMotion.of(context);
```
to:
```dart
    final motion = MotionAware.of(context);
```

Replace the import:
```dart
import 'package:construction_inspector/core/design_system/tokens/field_guide_motion.dart';
```
with:
```dart
import 'package:construction_inspector/core/design_system/animation/motion_aware.dart';
```

#### Step 2.11.3: Update animation barrel to include `motion_aware.dart`

**File**: `lib/core/design_system/animation/animation.dart` (MODIFY)

Add:
```dart
export 'motion_aware.dart';
```

Final barrel contents:
```dart
/// Barrel export for the Field Guide animation system.
export 'app_animated_entrance.dart';
export 'app_staggered_list.dart';
export 'app_tap_feedback.dart';
export 'app_value_transition.dart';
export 'motion_aware.dart';
```

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/animation/"`
Expected: No issues found.

---

### Sub-phase 2.12: Full Phase 2 Verification

**Agent**: `general-purpose`

#### Step 2.12.1: Run full analyzer on design system and router

**Verification**: `pwsh -Command "flutter analyze --no-pub lib/core/design_system/ lib/core/router/"`
Expected: No issues found.

#### Step 2.12.2: Run full analyzer on widgetbook

**Verification**: `pwsh -Command "cd C:/Users/rseba/Projects/Field_Guide_App/widgetbook && flutter analyze --no-pub"`
Expected: No issues found.

---

### Phase 2 File Summary

**New files created (14)**:
1. `lib/core/design_system/layout/app_breakpoint.dart`
2. `lib/core/design_system/layout/app_responsive_builder.dart`
3. `lib/core/design_system/layout/app_adaptive_layout.dart`
4. `lib/core/design_system/layout/app_responsive_padding.dart`
5. `lib/core/design_system/layout/app_responsive_grid.dart`
6. `lib/core/design_system/layout/layout.dart`
7. `lib/core/design_system/animation/app_animated_entrance.dart`
8. `lib/core/design_system/animation/app_staggered_list.dart`
9. `lib/core/design_system/animation/app_tap_feedback.dart`
10. `lib/core/design_system/animation/app_value_transition.dart`
11. `lib/core/design_system/animation/motion_aware.dart`
12. `lib/core/design_system/animation/animation.dart`
13. `widgetbook/pubspec.yaml`
14. `widgetbook/lib/main.dart`

**Files modified (3)**:
1. `lib/core/router/scaffold_with_nav_bar.dart` — responsive navigation (NavigationBar -> NavigationRail at medium+), #201 fix
2. `lib/core/router/app_router.dart` — FadeThroughTransition for shell pages, remove DesignConstants import
3. `lib/core/design_system/design_system.dart` — add layout/layout.dart and animation/animation.dart exports

**Dependency added (1)**:
1. `pubspec.yaml` — `animations: ^2.0.11`
