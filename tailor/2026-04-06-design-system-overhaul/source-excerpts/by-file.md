# Source Excerpts — By File

## Token/Theme Layer

### `lib/core/theme/app_theme.dart` (1,777 lines)
- `AppTheme` class (line 9): 8 methods — `darkTheme` (173), `lightTheme` (811), `highContrastTheme` (1265), plus deprecated color re-exports
- `darkTheme`: 637 lines building complete ThemeData with all component themes
- `lightTheme`: 453 lines (similar structure, different colors)
- `highContrastTheme`: 512 lines (TO DELETE)
- Full source available via CodeMunch ID: `lib/core/theme/app_theme.dart::AppTheme#class`

### `lib/core/theme/design_constants.dart` (97 lines)
- `DesignConstants` class (line 4): Static constants only, no methods
- Categories: Animation (5 durations + 5 curves), Spacing (10 values), Radii (7 values), Icon sizes (4), Elevation (4), Touch targets (3), Visual effects (1), Mini spinner (2)
- Full source retrieved and verified

### `lib/core/theme/field_guide_colors.dart` (220 lines)
- `FieldGuideColors extends ThemeExtension<FieldGuideColors>` (line 12)
- 16 Color fields, 3 const instances (dark/light/highContrast), `of(context)`, `copyWith`, `lerp`
- Full source retrieved and verified

### `lib/core/theme/colors.dart` (218 lines)
- `AppColors` class (line 5): 60+ static Color constants + 2 helper methods
- Full source retrieved and verified

### `lib/features/settings/presentation/providers/theme_provider.dart` (117 lines)
- `AppThemeMode` enum (line 9): `light`, `dark`, `highContrast`
- `ThemeProvider extends ChangeNotifier` (line 19): Manages theme state, persists to SharedPreferences
- Full source retrieved and verified

## Design System Layer

### `lib/core/design_system/design_system.dart` (39 lines)
- Barrel file exporting 24 components. Full source verified.

### Key Component Summaries (outlines retrieved)
| Component | Lines | Type | Key API |
|-----------|-------|------|---------|
| `AppScaffold` | ~60 | StatelessWidget | `body`, `appBar`, `floatingActionButton`, `bottomNavigationBar`, `useSafeArea`, `backgroundColor` |
| `AppBottomBar` | ~60 | StatelessWidget | `child`, `padding` — blur backdrop bar |
| `AppBottomSheet` | ~80 | Static factory | `show<T>(context, builder:, isScrollControlled:)` |
| `AppDialog` | ~120 | Static factory | `show<T>(...)`, `showCustom<T>(...)` — uses `actionsBuilder:` NOT `actions:` |
| `AppStickyHeader` | ~110 | StatelessWidget | `child`, `height`, `padding` — SliverPersistentHeader delegate |
| `AppGlassCard` | ~120 | StatelessWidget | Glassmorphic card with blur + gradient border |
| `AppSectionCard` | ~150 | StatelessWidget | Expandable section with header + content |
| `AppListTile` | ~120 | StatelessWidget | Themed list tile with consistent spacing |
| `AppEmptyState` | ~90 | StatelessWidget | `icon`, `title`, `subtitle?`, `actionLabel?`, `onAction?` |
| `AppErrorState` | ~60 | StatelessWidget | `message`, `onRetry?`, `retryLabel` |
| `AppInfoBanner` | ~90 | StatelessWidget | `icon`, `message`, `color`, `actionLabel?`, `onAction?` |
| `AppText` | ~200 | StatelessWidget | Factory constructors for text styles |
| `AppTextField` | ~250 | StatefulWidget | Themed text input with validation |

## Router Layer

### `lib/core/router/scaffold_with_nav_bar.dart` (188 lines)
- `ScaffoldWithNavBar extends StatelessWidget` (line 21)
- Full source retrieved. Key: `Consumer2`, `NavigationBar`, 4 destinations, banner management
- Routes with project switcher: `{'/', '/calendar'}`

### `lib/core/router/app_router.dart` (~500+ lines)
- `AppRouter` class (line 41): 8 methods including `_buildRouter()`, `_shellPage()`, `_fadeTransition()`
- Uses `GoRouter` with shell routes

## Shared Widgets (to be moved/merged)

### `lib/shared/utils/snackbar_helper.dart` (140 lines)
- `SnackBarHelper` class: 6 static methods (showSuccess, showError, showErrorWithAction, showInfo, showWarning, showWithAction)
- 3 direct importers: `pdf_data_builder.dart`, `consent_screen.dart`, `legal_document_screen.dart`

### `lib/shared/widgets/search_bar_field.dart` (~100 lines)
- `SearchBarField extends StatefulWidget`: controller, hintText, onChanged, onClear, autofocus, fieldKey
- Barrel-exported only (0 direct importers)

### `lib/shared/widgets/contextual_feedback_overlay.dart` (~130 lines)
- `ContextualFeedbackOverlay`: static show/dismiss, overlay-based positioned feedback popup
- Barrel-exported only (0 direct importers)

### `lib/shared/widgets/empty_state_widget.dart` (~60 lines)
- `EmptyStateWidget extends StatelessWidget`: icon, title, subtitle, actionButton
- Barrel-exported only, overlaps with `AppEmptyState`

### `lib/shared/widgets/confirmation_dialog.dart` (~150 lines)
- 4 functions: `showConfirmationDialog`, `showDeleteConfirmationDialog`, `_getConfirmButtonKey`, `showUnsavedChangesDialog`
- Barrel-exported only

### `lib/shared/widgets/stale_config_warning.dart` (~40 lines)
- `StaleConfigWarning extends StatelessWidget`: onRetry callback
- Used directly in `scaffold_with_nav_bar.dart`

### `lib/shared/widgets/version_banner.dart` (~60 lines)
- `VersionBanner extends StatefulWidget`: message, onDismiss
- Used directly in `scaffold_with_nav_bar.dart`

## Lint Package

### `fg_lint_packages/field_guide_lints/lib/field_guide_lints.dart`
- Plugin entry point: `createPlugin()` → `_FieldGuideLintPlugin.getLintRules()`
- Returns combined list from `architectureRules`, `dataSafetyRules`, `syncIntegrityRules`, `testQualityRules`

### `fg_lint_packages/field_guide_lints/lib/architecture/architecture_rules.dart`
- `architectureRules` constant list — all architecture rules instantiated here
- New rules must be added to this list

## Form Editor Widgets

### `lib/features/forms/presentation/widgets/form_accordion.dart` (~180 lines)
- `FormAccordion`, `HubSectionStatus` enum, `_LetterBadge`, `_StatusBadge`
- Extraction source for `AppFormSection`

### `lib/features/forms/presentation/widgets/status_pill_bar.dart` (~90 lines)
- `StatusPillItem`, `StatusPillBar`, `_StatusPill`
- Extraction source for `AppFormStatusBar`

### `lib/features/forms/presentation/widgets/summary_tiles.dart` (~50 lines)
- `SummaryTileData`, `SummaryTiles`
- Extraction source for `AppFormSummaryTile`

### `lib/features/forms/presentation/widgets/form_thumbnail.dart` (~130 lines)
- `FormThumbnail` with `_buildStatusBadge`, `_buildDeleteButton`
- Extraction source for `AppFormThumbnail`

## Dashboard Widgets

### `lib/features/dashboard/presentation/widgets/dashboard_stat_card.dart` (~80 lines)
- `DashboardStatCard`: label, value, icon, color, onTap
- Extraction source for `AppStatCard`

### `lib/features/dashboard/presentation/widgets/budget_overview_card.dart` (~200 lines)
- `BudgetOverviewCard` + `_BudgetStatBox`
- 21 DesignConstants refs — high tokenization target

## Settings Widgets

### `lib/features/settings/presentation/widgets/theme_section.dart` (~60 lines)
- `ThemeSection extends StatelessWidget`
- Must update for 2-theme system (remove HC option)
