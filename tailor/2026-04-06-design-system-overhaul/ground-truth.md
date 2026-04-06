# Ground Truth — Verified Literals

## Route Paths (from `lib/core/router/app_router.dart`)

| Route | Path | Verified |
|-------|------|----------|
| Dashboard | `/` (named: `dashboard`) | VERIFIED |
| Calendar/Home | `/calendar` (named: `home`) | VERIFIED |
| Projects | `/projects` (named: `projects`) | VERIFIED |
| Settings | `/settings` (named: `settings`) | VERIFIED |
| Sync Dashboard | `/sync/dashboard` | VERIFIED |
| Project Setup | `/projects/:id/setup` | VERIFIED |
| Entry Editor | `/entries/:id` | VERIFIED |

## Testing Keys (from `lib/shared/testing_keys/*.dart`)

| Key | File | Verified |
|-----|------|----------|
| `TestingKeys.bottomNavigationBar` | Used in `scaffold_with_nav_bar.dart:152` | VERIFIED |
| `TestingKeys.dashboardNavButton` | Used in `scaffold_with_nav_bar.dart:154` | VERIFIED |
| `TestingKeys.calendarNavButton` | Used in `scaffold_with_nav_bar.dart:159` | VERIFIED |
| `TestingKeys.projectsNavButton` | Used in `scaffold_with_nav_bar.dart:164` | VERIFIED |
| `TestingKeys.settingsNavButton` | Used in `scaffold_with_nav_bar.dart:169` | VERIFIED |

## Design Constants (from `lib/core/theme/design_constants.dart`)

### Spacing
| Constant | Value | Token Target |
|----------|-------|-------------|
| `space1` | 4.0 | `FieldGuideSpacing.xs` |
| `space2` | 8.0 | `FieldGuideSpacing.sm` |
| `space4` | 16.0 | `FieldGuideSpacing.md` |
| `space6` | 24.0 | `FieldGuideSpacing.lg` |
| `space8` | 32.0 | `FieldGuideSpacing.xl` |
| `space12` | 48.0 | `FieldGuideSpacing.xxl` |
| `space3` | 12.0 | Between sm and md — keep in DesignConstants as fallback |
| `space5` | 20.0 | Between md and lg — keep in DesignConstants as fallback |
| `space10` | 40.0 | Between xl and xxl — keep in DesignConstants as fallback |
| `space16` | 64.0 | Beyond xxl — keep in DesignConstants as fallback |

### Radii
| Constant | Value | Token Target |
|----------|-------|-------------|
| `radiusXSmall` | 4.0 | `FieldGuideRadii.xs` |
| `radiusSmall` | 8.0 | `FieldGuideRadii.sm` |
| `radiusCompact` | 10.0 | `FieldGuideRadii.compact` |
| `radiusMedium` | 12.0 | `FieldGuideRadii.md` |
| `radiusLarge` | 16.0 | `FieldGuideRadii.lg` |
| `radiusXLarge` | 24.0 | `FieldGuideRadii.xl` |
| `radiusFull` | 999.0 | `FieldGuideRadii.full` |

### Animation
| Constant | Value | Token Target |
|----------|-------|-------------|
| `animationFast` | 150ms | `FieldGuideMotion.fast` |
| `animationNormal` | 300ms | `FieldGuideMotion.normal` |
| `animationSlow` | 500ms | `FieldGuideMotion.slow` |
| `animationPageTransition` | 350ms | `FieldGuideMotion.pageTransition` |
| `curveDefault` | `Curves.easeInOutCubic` | `FieldGuideMotion.curveStandard` |
| `curveDecelerate` | `Curves.easeOut` | `FieldGuideMotion.curveDecelerate` |

### Elevation
| Constant | Value | Token Target |
|----------|-------|-------------|
| `elevationLow` | 2.0 | `FieldGuideShadows.low` |
| `elevationMedium` | 4.0 | `FieldGuideShadows.medium` |
| `elevationHigh` | 8.0 | `FieldGuideShadows.high` |
| `elevationModal` | 16.0 | `FieldGuideShadows.modal` |

## FieldGuideColors Fields (from `lib/core/theme/field_guide_colors.dart`)

| Field | Dark Value | Light Value | Verified |
|-------|-----------|-------------|----------|
| `surfaceElevated` | `AppColors.surfaceElevated` (#1C2128) | `AppColors.lightSurfaceElevated` (#FFFFFF) | VERIFIED |
| `surfaceGlass` | `AppColors.surfaceGlass` (#99161B22) | `Color(0xCCFFFFFF)` | VERIFIED |
| `surfaceBright` | `AppColors.surfaceBright` (#444C56) | `AppColors.lightSurfaceHighlight` (#E2E8F0) | VERIFIED |
| `textTertiary` | `AppColors.textTertiary` (#6E7681) | `AppColors.lightTextTertiary` (#94A3B8) | VERIFIED |
| `textInverse` | `AppColors.textInverse` (#0A0E14) | `Color(0xFFFFFFFF)` | VERIFIED |
| `statusSuccess` | `AppColors.statusSuccess` (#4CAF50) | Same | VERIFIED |
| `statusWarning` | `AppColors.statusWarning` (#FF9800) | Same | VERIFIED |
| `statusInfo` | `AppColors.statusInfo` (#2196F3) | Same | VERIFIED |
| `warningBackground` | `AppColors.warningBackground` (#1AFFB300) | `Color(0x1AFF9800)` | VERIFIED |
| `warningBorder` | `AppColors.warningBorder` (#33FFB300) | `Color(0x33FF9800)` | VERIFIED |
| `shadowLight` | `AppColors.shadowLight` (#1A000000) | `Color(0x0D000000)` | VERIFIED |
| `gradientStart` | `AppColors.primaryCyan` (#00E5FF) | `AppColors.primaryBlue` (#2196F3) | VERIFIED |
| `gradientEnd` | `AppColors.primaryBlue` (#2196F3) | `AppColors.primaryDark` (#0277BD) | VERIFIED |
| `accentAmber` | `AppColors.accentAmber` (#FFB300) | Same | VERIFIED |
| `accentOrange` | `AppColors.accentOrange` (#FF6F00) | Same | VERIFIED |
| `dragHandleColor` | `AppColors.surfaceHighlight` (#2D333B) | `AppColors.lightSurfaceHighlight` (#E2E8F0) | VERIFIED |

## AppThemeMode Enum (from `lib/features/settings/presentation/providers/theme_provider.dart:9-13`)

```dart
enum AppThemeMode {
  light,
  dark,
  highContrast,  // DELETE
}
```
Persisted via `SharedPreferences` as string key `'app_theme_mode'`. Safe deserialization uses `.where().firstOrNull ?? AppThemeMode.dark` — old `highContrast` values will safely fallback to `dark`.

## AppColors HC Constants (from `lib/core/theme/colors.dart:111-125`)

| Constant | Value | Action |
|----------|-------|--------|
| `hcBackground` | `#000000` | DELETE |
| `hcSurface` | `#121212` | DELETE |
| `hcSurfaceElevated` | `#1E1E1E` | DELETE |
| `hcBorder` | `#FFFFFF` | DELETE |
| `hcPrimary` | `#00FFFF` | DELETE |
| `hcAccent` | `#FFFF00` | DELETE |
| `hcSuccess` | `#00FF00` | DELETE |
| `hcError` | `#FF0000` | DELETE |
| `hcWarning` | `#FFAA00` | DELETE |
| `hcTextPrimary` | `#FFFFFF` | DELETE |
| `hcTextSecondary` | `#CCCCCC` | DELETE |
| `hcDisabledBackground` | `#333333` | DELETE |
| `hcDisabledForeground` | `#666666` | DELETE |

## Existing Lint Rules (from `fg_lint_packages/field_guide_lints/lib/`)

### Architecture Rules (verified in `architecture_rules.dart:27`)
| Rule Class | Code Name | Pattern |
|------------|-----------|---------|
| `NoHardcodedColors` | `no_hardcoded_colors` | `addPrefixedIdentifier` → `Colors.*` |
| `NoInlineTextStyle` | `no_inline_text_style` | `addInstanceCreationExpression` → `TextStyle` |
| `NoRawScaffold` | `no_raw_scaffold` | `addInstanceCreationExpression` → `Scaffold` |
| `NoRawAlertDialog` | `no_raw_alert_dialog` | `addInstanceCreationExpression` → `AlertDialog` |
| `NoRawShowDialog` | `no_raw_show_dialog` | `addMethodInvocation` → `showDialog` |
| `NoRawBottomSheet` | `no_raw_bottom_sheet` | `addMethodInvocation` → `showModalBottomSheet` |
| `NoDirectSnackbar` | `no_direct_snackbar` | `addMethodInvocation` → `showSnackBar` |
| `NoRawTextField` | `no_raw_text_field` | `addInstanceCreationExpression` → `TextField`/`TextFormField` |

### Common Lint Rule Patterns (verified from source)
1. **Path gating**: `filePath.replaceAll('\\', '/')` then `contains('/presentation/')` or `contains('/lib/')`
2. **Test exclusion**: `contains('/test/')` or `contains('/integration_test/')`
3. **Design system allowlist**: `contains('/core/design_system/')`
4. **Shell allowlist**: `contains('scaffold_with_nav_bar')`
5. **Severity**: All use `ErrorSeverity.WARNING`

## Lint Rules for New Files

### New token files in `lib/core/design_system/tokens/`
| File | Lint Rules That Apply |
|------|---------------------|
| `field_guide_spacing.dart` | None — inside `design_system/` allowlist |
| `field_guide_radii.dart` | None — inside `design_system/` allowlist |
| `field_guide_motion.dart` | None — inside `design_system/` allowlist |
| `field_guide_shadows.dart` | None — inside `design_system/` allowlist |

### New layout files in `lib/core/design_system/layout/`
| File | Lint Rules That Apply |
|------|---------------------|
| `app_breakpoint.dart` | None — inside `design_system/` allowlist |
| `app_responsive_builder.dart` | None — inside `design_system/` allowlist |
| `app_adaptive_layout.dart` | None — inside `design_system/` allowlist |
| `app_responsive_padding.dart` | None — inside `design_system/` allowlist |
| `app_responsive_grid.dart` | None — inside `design_system/` allowlist |

### New animation files in `lib/core/design_system/animation/`
| File | Lint Rules That Apply |
|------|---------------------|
| All animation files | None — inside `design_system/` allowlist |

### New lint rules in `fg_lint_packages/field_guide_lints/lib/architecture/rules/`
| File | Notes |
|------|-------|
| `no_raw_button.dart` | Catches `ElevatedButton`, `TextButton`, `OutlinedButton`, `IconButton` |
| `no_raw_divider.dart` | Catches `Divider` |
| `no_raw_tooltip.dart` | Catches `Tooltip` |
| `no_raw_dropdown.dart` | Catches `DropdownButton`, `DropdownButtonFormField` |
| `no_raw_snackbar.dart` | Catches `ScaffoldMessenger.of(context).showSnackBar(` — overlaps with existing `no_direct_snackbar`, evaluate if merge or separate |
| `no_hardcoded_spacing.dart` | Catches `EdgeInsets.all(N)`, `SizedBox(width: N)` with literal |
| `no_hardcoded_radius.dart` | Catches `BorderRadius.circular(N)` with literal |
| `no_hardcoded_duration.dart` | Catches `Duration(milliseconds: N)` in presentation |
| `no_raw_navigator.dart` | Catches `Navigator.push(`, `Navigator.pop(` — info severity |
| `prefer_design_system_banner.dart` | Catches feature banners not composing `AppBanner` |

## Design System Barrel Path (verified)

Package import: `package:construction_inspector/core/design_system/design_system.dart`
Relative import (from core/): `../design_system/design_system.dart`

## Navigator Shell Routes (verified from `scaffold_with_nav_bar.dart`)

| Index | Route Name | Icon | Label |
|-------|-----------|------|-------|
| 0 | `dashboard` | `Icons.dashboard_outlined` / `Icons.dashboard` | Dashboard |
| 1 | `home` | `Icons.calendar_today_outlined` / `Icons.calendar_today` | Calendar |
| 2 | `projects` | `Icons.folder_outlined` / `Icons.folder` | Projects |
| 3 | `settings` | `Icons.settings_outlined` / `Icons.settings` | Settings |

Project switcher routes: `{'/', '/calendar'}`
