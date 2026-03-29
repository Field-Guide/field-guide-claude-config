# UI Refactor V2 — Dependency Graph Analysis

**Date**: 2026-03-28
**Scope**: Full UI refactor to T Vivid design system across 40 screens, 80+ widgets, 30+ dialogs, 8 bottom sheets

## Blast Radius Summary

| Category | Count |
|----------|-------|
| Direct changes (new files) | ~25 (design system components + ThemeExtension) |
| Direct changes (modify) | ~130 (all presentation files) |
| Dependent files | ~16 (repositories/services referenced by UI) |
| Test files | ~15 (existing) + ~20 (new design system tests) |
| Cleanup | ~5 (deprecated widgets, unused imports) |

## Critical Dependency Chain

```
FieldGuideColors (ThemeExtension) ← registered in app_theme.dart ThemeData builders
    ↑
    ├── All 20+ design system components use FieldGuideColors.of(context)
    │   ├── AppGlassCard ← used by ~60% of screens
    │   ├── AppText ← replaces 447 inline TextStyle constructors
    │   ├── AppChip ← replaces 6+ StatusBadge/StatusChip patterns
    │   ├── AppBottomSheet ← wraps 8 bottom sheets
    │   ├── AppDialog ← wraps 30+ dialogs
    │   └── ... (20 total components)
    │
    ├── All 40 screens migrate from AppTheme.* static → Theme.of(context) dynamic
    │   ├── home_screen.dart (79 violations — heaviest)
    │   ├── project_dashboard_screen.dart (48 violations)
    │   ├── contractor_editor_widget.dart (50 violations)
    │   └── ...
    │
    └── ThemeProvider.currentTheme already returns correct ThemeData
        └── main.dart MaterialApp already wired to ThemeProvider
```

## File Categories

### CREATE (new files)
- `lib/core/theme/field_guide_colors.dart` — ThemeExtension<FieldGuideColors>
- `lib/core/design_system/app_text.dart`
- `lib/core/design_system/app_text_field.dart`
- `lib/core/design_system/app_chip.dart`
- `lib/core/design_system/app_progress_bar.dart`
- `lib/core/design_system/app_counter_field.dart`
- `lib/core/design_system/app_toggle.dart`
- `lib/core/design_system/app_icon.dart`
- `lib/core/design_system/app_glass_card.dart`
- `lib/core/design_system/app_section_header.dart`
- `lib/core/design_system/app_list_tile.dart`
- `lib/core/design_system/app_photo_grid.dart`
- `lib/core/design_system/app_scaffold.dart`
- `lib/core/design_system/app_bottom_bar.dart`
- `lib/core/design_system/app_bottom_sheet.dart`
- `lib/core/design_system/app_dialog.dart`
- `lib/core/design_system/app_sticky_header.dart`
- `lib/core/design_system/app_empty_state.dart`
- `lib/core/design_system/app_error_state.dart`
- `lib/core/design_system/app_loading_state.dart`
- `lib/core/design_system/app_budget_warning_chip.dart`
- `lib/core/design_system/app_section_card.dart` (NEW — from audit)
- `lib/core/design_system/app_mini_spinner.dart` (NEW — from audit)
- `lib/core/design_system/app_info_banner.dart` (NEW — from audit)
- `lib/core/design_system/app_drag_handle.dart` (NEW — from audit)
- `lib/core/design_system/design_system.dart` (barrel export)

### MODIFY (theme files)
- `lib/core/theme/colors.dart` — add missing color tokens
- `lib/core/theme/design_constants.dart` — add radiusXSmall, radiusCompact, icon sizes
- `lib/core/theme/app_theme.dart` — register FieldGuideColors, add re-exports, complete light/HC themes
- `lib/core/theme/theme.dart` — add FieldGuideColors export

### MODIFY (all 40 screens — see audit for full list)
- Replace inline TextStyle → textTheme references
- Replace literal EdgeInsets → AppTheme.space* tokens
- Replace literal BorderRadius → AppTheme.radius* tokens
- Replace Colors.* → cs.*/fg.* theme-aware references
- Replace ad-hoc withValues(alpha:) → defined opacity tokens or fg.* colors
- Adopt design system components where applicable

### MODIFY (80+ widgets)
- Same token migration as screens
- Adopt design system components for shared patterns

### MODIFY (30+ dialogs, 8 bottom sheets)
- Wrap with AppDialog.show() / AppBottomSheet.show()
- Standardize styling

### DATA LAYER (Safety Repeat-Last Toggles — new feature)
- `lib/core/database/database_service.dart` — v43 migration for repeat_last_* columns
- `lib/features/entries/data/models/daily_entry.dart` — add repeat fields
- `lib/features/entries/data/repositories/daily_entry_repository.dart` — seed from previous entry
- `lib/features/entries/presentation/providers/daily_entry_provider.dart` — toggle state
- Entry editor UI — toggle switches in basics section

## Key Source Excerpts

### AppColors (57 constants) — lib/core/theme/colors.dart:5-171
See full source in audit. Key groups: Primary (4), Accent (3), Semantic (4), Dark surfaces (6), Dark text (4), Light surfaces (4), Light text (3), HC (10), Weather (6), Entry status (4), Overlays (2), Gradients (3).

### DesignConstants — lib/core/theme/design_constants.dart:4-61
Animation: animationFast(150ms), animationNormal(300ms), animationSlow(500ms), animationPageTransition(350ms)
Curves: curveDefault, curveDecelerate, curveAccelerate, curveBounce, curveSpring
Spacing (4px grid): space1(4) through space16(64) — 10 values
Radius: radiusSmall(8), radiusMedium(12), radiusLarge(16), radiusXLarge(24), radiusFull(999)
Elevation: elevationLow(2), elevationMedium(4), elevationHigh(8), elevationModal(16)
Touch targets: touchTargetMin(48), touchTargetComfortable(56), touchTargetLarge(64)

### AppTheme facade — lib/core/theme/app_theme.dart:8-1540
Re-exports all AppColors + DesignConstants as static constants.
3 ThemeData builders: darkTheme(line 130), lightTheme(line 765), highContrastTheme(line 1125).
Helper methods: getPrimaryGradient, getAccentGradient, getGlassmorphicDecoration, getWeatherColor, getEntryStatusColor.
Dark theme configures: colorScheme, scaffoldBackgroundColor, appBarTheme, cardTheme, inputDecorationTheme, elevatedButtonTheme, filledButtonTheme, outlinedButtonTheme, textButtonTheme, iconButtonTheme, floatingActionButtonTheme, navigationBarTheme, dialogTheme, bottomSheetTheme, snackBarTheme, dividerTheme, progressIndicatorTheme, textTheme, listTileTheme, chipTheme, switchTheme, checkboxTheme, sliderTheme.
Light theme MISSING: filledButtonTheme, iconButtonTheme, bottomSheetTheme, chipTheme, sliderTheme.
HC theme MISSING: same as light + additional gaps.

### ThemeProvider — lib/features/settings/presentation/providers/theme_provider.dart:17-114
ChangeNotifier with AppThemeMode enum (dark/light/highContrast). Persists to SharedPreferences.
currentTheme getter returns AppTheme.darkTheme/lightTheme/highContrastTheme.

### ThemeData wiring — lib/main.dart
MaterialApp uses Consumer<ThemeProvider>(builder: (_, theme, __) => MaterialApp.router(theme: theme.currentTheme, ...))
