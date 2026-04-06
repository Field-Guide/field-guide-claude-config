# Source Excerpts — By Spec Concern

## Concern 1: Token System (Spec Section 2)

### Existing ThemeExtension — FieldGuideColors
**File**: `lib/core/theme/field_guide_colors.dart` (220 lines)
**Full source in**: `patterns/theme-extension.md`
**Key elements**: 16 color fields, `dark`/`light`/`highContrast` const instances, `of(context)` accessor, sentinel-based `copyWith`, Color-typed `lerp`

### Static Constants — DesignConstants
**File**: `lib/core/theme/design_constants.dart` (97 lines)
**Full source in**: `patterns/theme-extension.md` (DesignConstants symbol source)
**Key elements**: Spacing (space1-space16), Radii (radiusXSmall-radiusFull), Animation (animationFast-animationSlow + curves), Elevation (elevationLow-elevationModal), Touch targets, Visual effects (blurSigma), Mini spinner defaults

### Static Colors — AppColors
**File**: `lib/core/theme/colors.dart` (218 lines)
**Key elements**: 60+ static Color constants across categories: primary (4), accent (3), semantic (5), dark surfaces (8), dark text (4), light surfaces (4), light text (3), HC (13 — TO DELETE), weather (6), entry status (4), overlay (2), photo viewer (4), specialized (3), gradients (3 lists), helpers (2 methods)

## Concern 2: Responsive Layout (Spec Section 3)

### Current Shell — ScaffoldWithNavBar
**File**: `lib/core/router/scaffold_with_nav_bar.dart` (188 lines)
**Full source in**: `patterns/navigation-shell.md`
**Key insight**: Currently hardcoded `NavigationBar` at bottom. Must adapt to `NavigationRail` at medium+ breakpoints. Banner management (version, stale, offline, sync error) must work in both layouts.

### Router Structure
**File**: `lib/core/router/app_router.dart` (~500+ lines)
**Key elements**: `_buildRouter()` creates GoRouter with ShellRoute wrapping ScaffoldWithNavBar. `_shellPage()` and `_fadeTransition()` provide consistent transitions. Routes include nested ShellRoutes for feature areas.

## Concern 3: Performance (Spec Section 4)

### Consumer Pattern (to replace with Selector)
ScaffoldWithNavBar uses `Consumer2<SyncProvider, AppConfigProvider>` — rebuilds entire banner + body column on any sync or config change. Target: split into specific selectors.

### Existing Sliver Usage
`AppStickyHeader` already uses `SliverPersistentHeaderDelegate` — good pattern for sliver migration.

## Concern 4: Animation (Spec Section 5)

### Current Transitions
- `_shellPage` uses fade transition (200ms) via `FadeTransition`
- `_fadeTransition` in `app_router.dart` used for tab switches
- `AppSectionCard` uses `AnimatedContainer` for expand/collapse
- No staggered list animations exist currently

## Concern 5: Screen Decomposition (Spec Section 6)

### MdotHubScreen Structure
**File**: `lib/features/forms/presentation/screens/mdot_hub_screen.dart` (1,198 lines)
**Contains**: MdotHubScreen + FormFillScreen + QuickTestEntryScreen + ProctorEntryScreen + WeightsEntryScreen + FormPdfPreviewScreen — 5 screen classes in one file
**Already extracted**: hub_header_content (119), hub_quick_test_content (239), hub_proctor_content (486)
**Still to extract**: 5 screen classes into separate files, hub_proctor_content to decompose further

### EntryEditorScreen Structure
**File**: `lib/features/entries/presentation/screens/entry_editor_screen.dart` (1,857 lines)
**Highest line count in codebase**, 27 DesignConstants references
**Already extracted sections**: entry_contractors_section, entry_forms_section, entry_photos_section, entry_quantities_section, entry_activities_section
**Still monolithic**: Main screen orchestration + remaining _build* methods

### ProjectSetupScreen Structure
**File**: `lib/features/projects/presentation/screens/project_setup_screen.dart` (1,436 lines)
**30 DesignConstants references**, fixes #165 (RenderFlex)
**Already extracted**: project_details_form, assignments_step, various dialogs
**Still monolithic**: Setup wizard orchestration + step management

## Concern 6: Design System Expansion (Spec Section 7)

### Current Barrel
**File**: `lib/core/design_system/design_system.dart` (39 lines)
24 exports in flat structure. See `patterns/barrel-export.md` for target.

### Shared Widgets to Migrate
- `SnackBarHelper` (6 methods: showSuccess, showError, showErrorWithAction, showInfo, showWarning, showWithAction) → `AppSnackbar`
- `SearchBarField` (StatefulWidget, controller+hint+onChanged+onClear+autofocus) → `AppSearchBar`
- `ContextualFeedbackOverlay` (static show/dismiss, overlay-based positioned feedback) → `AppContextualFeedback`
- `EmptyStateWidget` (icon+title+subtitle+actionButton) → merge into `AppEmptyState`
- `showConfirmationDialog` (3 functions) → merge into `AppDialog.showConfirmation()`
- `StaleConfigWarning` (onRetry callback) → recompose from `AppBanner`
- `VersionBanner` (message+onDismiss) → recompose from `AppBanner`

## Concern 7: HC Theme Removal (Spec Section 9)

### Files with HC references (lib)
1. `app_theme.dart:1265-1777` — `highContrastTheme` getter (~500 lines)
2. `colors.dart:111-125` — 13 `hc*` Color constants
3. `field_guide_colors.dart:131-146` — `highContrast` const instance
4. `theme_provider.dart:9-13` — `AppThemeMode.highContrast` enum value
5. `theme_provider.dart:42,115` — `isHighContrast` getter, `setHighContrast()` method
6. `theme_section.dart` — HC option in theme selection UI

### Files with HC references (test)
12 test files — see `blast-radius.md` for complete list.

## Concern 8: New Lint Rules (Spec Section 4)

### Existing Rule Template
All new rules follow the `NoHardcodedColors` / `NoRawScaffold` pattern.
See `patterns/lint-rule.md` for complete exemplar source.

### Registration Point
`fg_lint_packages/field_guide_lints/lib/architecture/architecture_rules.dart:27` — `architectureRules` list.
New rules must be added here and imported at top of file.

### Spec note on `no_raw_snackbar` vs existing `no_direct_snackbar`
The spec lists `no_raw_snackbar` catching `ScaffoldMessenger.of(context).showSnackBar(`. The existing `no_direct_snackbar` already catches `showSnackBar` method invocations. Evaluate whether to rename/extend the existing rule or create a separate one. Recommend extending existing rule and renaming.
