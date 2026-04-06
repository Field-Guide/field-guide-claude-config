# Blast Radius Analysis

## Per-Symbol Impact

### `DesignConstants` — HIGHEST RISK (0.91)
- **Direct dependents**: 123 files
- **Total at 2 hops**: 160 files
- **Hottest consumers** (by reference count):
  - `project_dashboard_screen.dart`: 51 refs
  - `home_screen.dart`: 47 refs
  - `contractor_editor_widget.dart`: 37 refs
  - `form_viewer_screen.dart`: 35 refs
  - `project_setup_screen.dart`: 30 refs
  - `entry_editor_screen.dart`: 27 refs
  - `calculator_screen.dart`: 26 refs
  - `todos_screen.dart`: 25 refs
  - `bid_item_detail_sheet.dart`: 25 refs
  - `entries_list_screen.dart`: 24 refs
  - `gallery_screen.dart`: 24 refs
  - `budget_overview_card.dart`: 21 refs
- **Migration implication**: Every `DesignConstants.space*` → `FieldGuideSpacing.of(context).*`, every `DesignConstants.radius*` → `FieldGuideRadii.of(context).*`, every `DesignConstants.animation*` → `FieldGuideMotion.of(context).*`. This is the highest-volume mechanical change. Must tokenize during decomposition to avoid double-touch.

### `FieldGuideColors` — HIGH RISK (via file-level graph)
- **Direct importers**: 89 files
- **Pattern**: Already uses `ThemeExtension.of(context)` — existing pattern exemplar
- **HC deletion**: Remove `highContrast` const instance + all `hc*` references in `AppColors`
- **Expansion**: Absorb remaining `AppColors` fields that vary per theme

### `AppTheme` — MODERATE RISK (0.95)
- **Direct dependents**: 29 files (mostly tests)
- **Lib dependents**: Only 3 (theme_provider, budget_overview_card, project_dashboard_screen)
- **HC theme deletion**: ~500 lines removed from `app_theme.dart` (lines 1265-1777)
- **Test impact**: `high_contrast_theme_test.dart` deleted entirely, `test_helpers.dart` updated (removes `testWidgetInAllThemes` HC variant)

### `AppColors` — MODERATE RISK (0.92)
- **Direct dependents**: 16 files (2 lib + 14 test)
- **HC constants to delete**: `hcBackground`, `hcSurface`, `hcSurfaceElevated`, `hcBorder`, `hcPrimary`, `hcAccent`, `hcSuccess`, `hcError`, `hcWarning`, `hcTextPrimary`, `hcTextSecondary`, `hcDisabledBackground`, `hcDisabledForeground` (13 constants)
- **Golden test impact**: 12 test files reference `AppColors` directly

### `design_system.dart` barrel — HIGH RISK (scope)
- **Direct importers**: 114 files
- **Migration strategy**: Keep barrel path, restructure internal exports → consumers don't change imports

## HC Theme Removal — Full File List

### Lib files (5):
1. `lib/core/theme/app_theme.dart` — Delete `highContrastTheme` getter (~500 lines)
2. `lib/core/theme/colors.dart` — Delete 13 `hc*` constants
3. `lib/core/theme/field_guide_colors.dart` — Delete `highContrast` const instance
4. `lib/features/settings/presentation/providers/theme_provider.dart` — Remove `highContrast` from `AppThemeMode` enum, `isHighContrast` getter, `setHighContrast()` method, update `cycleTheme()`, `currentTheme`, `themeName`
5. `lib/features/settings/presentation/widgets/theme_section.dart` — Update theme selection UI (remove HC option)

### Test files (12):
1. `test/golden/themes/high_contrast_theme_test.dart` — Delete entirely
2. `test/golden/test_helpers.dart` — Remove HC theme from `testWidgetInAllThemes`
3. `test/core/theme/field_guide_colors_test.dart` — Remove HC test cases
4. `test/golden/components/dashboard_widgets_test.dart` — Remove HC variants
5. `test/golden/components/form_fields_test.dart` — Remove HC variants
6. `test/golden/components/quantity_cards_test.dart` — Remove HC variants
7. `test/golden/states/empty_state_test.dart` — Remove HC variants
8. `test/golden/states/error_state_test.dart` — Remove HC variants
9. `test/golden/states/loading_state_test.dart` — Remove HC variants
10. `test/golden/widgets/confirmation_dialog_test.dart` — Remove HC variants
11. `test/golden/widgets/entry_card_test.dart` — Remove HC variants
12. `test/golden/widgets/project_card_test.dart` — Remove HC variants

## Dead Code Targets

### Spec-mandated deletions:
| Code | Location | Action |
|------|----------|--------|
| `AppTheme.highContrastTheme` | `app_theme.dart:1265-1777` | Delete ~500 lines |
| `FieldGuideColors.highContrast` | `field_guide_colors.dart:131-146` | Delete instance |
| `AppColors.hc*` (13 constants) | `colors.dart:111-125` | Delete |
| `AppThemeMode.highContrast` | `theme_provider.dart:12` | Remove enum value |
| `ThemeProvider.isHighContrast` | `theme_provider.dart:42` | Delete getter |
| `ThemeProvider.setHighContrast()` | `theme_provider.dart:115-117` | Delete method |
| `AppTheme` deprecated re-exports | `app_theme.dart` (scattered) | Delete ~20 fields |
| `EmptyStateWidget` | `shared/widgets/empty_state_widget.dart` | Merge into `AppEmptyState`, delete |
| `showConfirmationDialog` functions | `shared/widgets/confirmation_dialog.dart` | Merge into `AppDialog.showConfirmation()`, delete |
| `StaleConfigWarning` | `shared/widgets/stale_config_warning.dart` | Recompose from `AppBanner`, delete |
| `VersionBanner` | `shared/widgets/version_banner.dart` | Recompose from `AppBanner`, delete |

### CodeMunch dead code findings:
- Dead code analysis returned extensive results (saved to tool-results). Key theme: many private `_build*` methods in oversized screens will be extracted during decomposition, and HC-specific symbols will be removed.
