# Dependency Graph

## Direct Changes — Core Token/Theme Files

### `lib/core/theme/app_theme.dart` (1,777 lines → <400)
- **Symbols**: `AppTheme` class with `darkTheme`, `lightTheme`, `highContrastTheme` static getters
- **Change type**: Major refactor — collapse to data-driven builder, delete `highContrastTheme` (~500 lines)
- **Direct importers**: 29 files (3 lib + 26 test)
- **Lib importers**: `budget_overview_card.dart`, `project_dashboard_screen.dart`, `theme_provider.dart`
- **Test importers**: All golden tests, design system tests, `field_guide_colors_test.dart`

### `lib/core/theme/design_constants.dart` (97 lines)
- **Symbols**: `DesignConstants` class — static spacing, radius, animation, elevation, touch target constants
- **Change type**: Move to `design_system/tokens/`, keep as static fallback
- **Direct importers**: **123 files** (highest blast radius in entire codebase)
- **Key lib dependents**: ALL design system components, ALL feature screens, ALL feature widgets, `app_router.dart`, `contextual_feedback_overlay.dart`, `search_bar_field.dart`, `empty_state_widget.dart`

### `lib/core/theme/field_guide_colors.dart` (220 lines)
- **Symbols**: `FieldGuideColors extends ThemeExtension<FieldGuideColors>` with 16 fields, `dark`/`light`/`highContrast` const instances, `of(context)` accessor
- **Change type**: Move to `design_system/tokens/`, delete `highContrast` instance, absorb remaining `AppColors` semantic colors that vary per theme
- **Direct importers**: 89 files
- **Key lib dependents**: 10 design system components, `scaffold_with_nav_bar.dart`, 40+ feature screens/widgets

### `lib/core/theme/colors.dart` (218 lines)
- **Symbols**: `AppColors` class — 60+ static `Color` constants, `hc*` constants (12), weather colors, entry status colors, gradients, helpers
- **Change type**: Move to `design_system/tokens/app_colors.dart`, delete `hc*` constants
- **Direct importers**: 16 files (2 lib + 14 test)
- **Lib importers**: `app_chip.dart`, `weather_helpers.dart`

### `lib/core/theme/theme.dart` (barrel)
- **Change type**: Delete — replaced by `design_system/tokens/tokens.dart` barrel

## Direct Changes — Design System Barrel

### `lib/core/design_system/design_system.dart`
- **Current exports**: 24 components in flat structure
- **Importer count**: **114 files** (second-highest blast radius)
- **Change type**: Restructure to atomic subdirectories, update barrel to re-export from subdirectory barrels
- **Key insight**: Barrel re-export strategy means most consumers won't need import changes IF the barrel path stays the same and re-exports everything

## Dependency Graph (2-hop) — Data Flow

```
design_constants.dart ──────────────────────── 123 direct dependents
  ├── ALL design_system/*.dart (19 components)
  ├── ALL feature presentation screens (~50 files)
  ├── ALL feature presentation widgets (~40 files)
  ├── app_router.dart
  └── shared/widgets/ (3 files)

field_guide_colors.dart ────────────────────── 89 direct dependents
  ├── 10 design_system components
  ├── scaffold_with_nav_bar.dart
  ├── 40+ feature screens/widgets
  └── form widgets (accordion, hub content, etc.)

design_system.dart (barrel) ────────────────── 114 direct dependents
  ├── ALL feature presentation screens
  ├── ALL feature presentation widgets
  ├── report_widgets/ (7 files)
  └── router routes (pay_app_routes, sync_routes)

app_theme.dart ─────────────────────────────── 29 direct dependents
  ├── theme_provider.dart → app_widget.dart, settings_providers.dart
  ├── budget_overview_card.dart
  ├── project_dashboard_screen.dart
  └── 26 test files

colors.dart (AppColors) ──────────────────��── 16 direct dependents
  ├── app_chip.dart → driver_server.dart, tests
  ├── weather_helpers.dart → draft_entry_tile.dart, entry_review_screen.dart
  └── 14 test files (all golden tests)
```

## File Move Impact

| From | To | Import Update Strategy |
|------|-----|----------------------|
| `lib/core/theme/field_guide_colors.dart` | `lib/core/design_system/tokens/field_guide_colors.dart` | Barrel re-export from tokens barrel + main barrel |
| `lib/core/theme/design_constants.dart` | `lib/core/design_system/tokens/design_constants.dart` | Barrel re-export; `dart fix --apply` per batch |
| `lib/core/theme/colors.dart` | `lib/core/design_system/tokens/app_colors.dart` | Barrel re-export; small consumer set |
| `lib/shared/utils/snackbar_helper.dart` | `lib/core/design_system/feedback/app_snackbar.dart` | 3 direct importers + barrel-exported via widgets.dart |
| `lib/shared/widgets/search_bar_field.dart` | `lib/core/design_system/molecules/app_search_bar.dart` | Barrel-exported only (0 direct importers) |
| `lib/shared/widgets/contextual_feedback_overlay.dart` | `lib/core/design_system/feedback/app_contextual_feedback.dart` | Barrel-exported only (0 direct importers) |

## Shared Widgets Barrel (`lib/shared/widgets/widgets.dart`)

Current exports:
```dart
export 'confirmation_dialog.dart';
export 'contextual_feedback_overlay.dart';
export 'empty_state_widget.dart';
export 'permission_dialog.dart';
export 'search_bar_field.dart';
export 'stale_config_warning.dart';
export 'version_banner.dart';
```

After migration: `confirmation_dialog.dart`, `empty_state_widget.dart`, `stale_config_warning.dart`, `version_banner.dart` deleted (merged into design system). `search_bar_field.dart`, `contextual_feedback_overlay.dart` moved. Only `permission_dialog.dart` remains.

## Navigation Shell — Key for Responsive Adaptation

`ScaffoldWithNavBar` (`lib/core/router/scaffold_with_nav_bar.dart`, 188 lines):
- Currently uses `NavigationBar` (bottom nav) for all breakpoints
- Uses `Consumer2<SyncProvider, AppConfigProvider>` for banner management
- References: `FieldGuideColors.of(context)`, `VersionBanner`, `StaleConfigWarning`, `ExtractionBanner`, `SnackBarHelper`, `ProjectSwitcher`, `SyncStatusIcon`
- Must be refactored to switch between `NavigationBar` (compact) and `NavigationRail` (medium/expanded/large)
