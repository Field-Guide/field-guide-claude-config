# UI Audit — Theme System, Design Tokens & Hardcoded Values
**Date**: 2026-03-06
**Scope**: Full `lib/features/**/presentation/**/*.dart`
**Purpose**: Baseline for planned full-UI refactor

---

## 1. Current Theme System Architecture

### Structure

```
lib/core/theme/
  app_theme.dart         — Master class: re-exports everything + builds ThemeData
  colors.dart            — AppColors: all Color constants
  design_constants.dart  — DesignConstants: spacing, radius, elevation, touch targets
  theme.dart             — Barrel export (app_theme, colors, design_constants)
```

### Theme Modes

Three complete ThemeData objects are defined:
| Mode | Access | Status |
|------|--------|--------|
| Dark (primary) | `AppTheme.darkTheme` | Complete — all component themes defined |
| Light | `AppTheme.lightTheme` | Complete — mirrors dark with light palette |
| High Contrast | `AppTheme.highContrastTheme` | Complete — accessibility mode, max contrast |

The theme mode is managed via a `ThemeProvider` (settings feature). All three themes are registered via Material 3 (`useMaterial3: true`).

### How Themes Are Applied

- `ThemeData` is applied via `MaterialApp.theme`, `MaterialApp.darkTheme`, `MaterialApp.highContrastTheme`
- Custom colors accessed as `AppTheme.*` static constants (re-exported from `AppColors`)
- Custom spacing accessed as `AppTheme.space*` (re-exported from `DesignConstants`)
- Standard Material colors accessed via `Theme.of(context).colorScheme.*`
- Text styles accessed via `Theme.of(context).textTheme.*`
- Utility gradients and decorations via `AppTheme.getPrimaryGradient()`, `AppTheme.getGlassmorphicDecoration()`

---

## 2. Complete Design Token Inventory

### 2a. Color Tokens (AppColors / AppTheme re-exports)

#### Primary Palette
| Token | Value | Usage |
|-------|-------|-------|
| `AppTheme.primaryCyan` | `#00E5FF` | Primary actions, FAB indicator, focus border |
| `AppTheme.primaryBlue` | `#2196F3` | Light theme primary, secondary accent |
| `AppTheme.primaryDark` | `#0277BD` | Pressed states, containers |
| `AppTheme.primaryLight` | `#80D8FF` | Light theme accents, snackbar action |

#### Accent Palette
| Token | Value | Usage |
|-------|-------|-------|
| `AppTheme.accentAmber` | `#FFB300` | FAB background, secondary accent |
| `AppTheme.accentOrange` | `#FF6F00` | Urgent states |
| `AppTheme.accentGold` | `#FFD54F` | Decorative accents |

#### Semantic Colors
| Token | Value | Usage |
|-------|-------|-------|
| `AppTheme.statusSuccess` | `#4CAF50` | Success/complete states |
| `AppTheme.statusWarning` | `#FF9800` | Caution states |
| `AppTheme.statusError` | `#F44336` | Errors, danger |
| `AppTheme.statusInfo` | `#2196F3` | Info states |

#### Dark Theme Surfaces (6 levels)
| Token | Value | Usage |
|-------|-------|-------|
| `AppTheme.backgroundDark` | `#0A0E14` | Scaffold background |
| `AppTheme.surfaceDark` | `#161B22` | AppBar, NavBar, input fill |
| `AppTheme.surfaceElevated` | `#1C2128` | Cards, dialogs |
| `AppTheme.surfaceHighlight` | `#2D333B` | Borders, dividers, hover |
| `AppTheme.surfaceBright` | `#444C56` | Active elements, disabled |
| `AppTheme.surfaceGlass` | `#99161B22` | Glassmorphic overlays |

#### Dark Theme Text (4 levels)
| Token | Value | Usage |
|-------|-------|-------|
| `AppTheme.textPrimary` | `#F0F6FC` | Primary text |
| `AppTheme.textSecondary` | `#8B949E` | Secondary text, icons |
| `AppTheme.textTertiary` | `#6E7681` | Disabled, hints |
| `AppTheme.textInverse` | `#0A0E14` | Text on primary-colored backgrounds |

#### Light Theme Colors
| Token | Value | Usage |
|-------|-------|-------|
| `AppTheme.lightBackground` | `#F8FAFC` | Scaffold |
| `AppTheme.lightSurface` | `#FFFFFF` | Cards, inputs |
| `AppTheme.lightSurfaceElevated` | `#FFFFFF` | Cards |
| `AppTheme.lightSurfaceHighlight` | `#E2E8F0` | Borders, dividers |
| `AppTheme.lightTextPrimary` | `#1E293B` | Primary text |
| `AppTheme.lightTextSecondary` | `#64748B` | Secondary text |
| `AppTheme.lightTextTertiary` | `#94A3B8` | Hints, disabled |

#### High Contrast Colors (11 tokens)
All prefixed `AppTheme.hc*` — pure/extreme values for accessibility mode.

#### Domain-Specific Colors
| Token | Value | Usage |
|-------|-------|-------|
| `AppTheme.weatherSunny` | `#FFD93D` | Weather icon |
| `AppTheme.weatherCloudy` | `#8B949E` | Weather icon |
| `AppTheme.weatherOvercast` | `#6E7681` | Weather icon |
| `AppTheme.weatherRainy` | `#58A6FF` | Weather icon |
| `AppTheme.weatherSnow` | `#E6EDF3` | Weather icon |
| `AppTheme.weatherWindy` | `#7EE787` | Weather icon |
| `AppTheme.overlayLight` | `#8A000000` | Modal overlays |
| `AppColors.overlayDark` | `#8AFFFFFF` | (NOT re-exported in AppTheme) |
| `AppColors.entryDraft` | `#6E7681` | Entry status color |
| `AppColors.entryComplete` | `#3FB950` | Entry status color |
| `AppColors.entrySubmitted` | `#58A6FF` | Entry status color |
| `AppColors.entrySynced` | `#00E5FF` | Entry status color |

#### Gradient Tokens
| Token | Colors |
|-------|--------|
| `AppTheme.gradientPrimary` | cyan → blue |
| `AppTheme.gradientAccent` | amber → orange |
| `AppColors.gradientSuccess` | green → dark green (NOT re-exported) |

#### Legacy Aliases (kept for backwards compat)
| Alias | Points To |
|-------|-----------|
| `AppTheme.secondaryAmber` | `accentAmber` |
| `AppTheme.success` | `statusSuccess` |
| `AppTheme.warning` | `statusWarning` |
| `AppTheme.error` | `statusError` |

### 2b. Spacing Tokens (DesignConstants / AppTheme re-exports)

| Token | Value | Exported via AppTheme? |
|-------|-------|------------------------|
| `AppTheme.space1` | 4.0 | Yes |
| `AppTheme.space2` | 8.0 | Yes |
| `AppTheme.space3` | 12.0 | Yes |
| `AppTheme.space4` | 16.0 | Yes |
| `AppTheme.space5` | 20.0 | Yes |
| `AppTheme.space6` | 24.0 | Yes |
| `AppTheme.space8` | 32.0 | Yes |
| `AppTheme.space10` | 40.0 | Yes |
| `DesignConstants.space12` | 48.0 | **NOT in AppTheme** |
| `DesignConstants.space16` | 64.0 | **NOT in AppTheme** |

**Note**: `space12` and `space16` are defined in `DesignConstants` but not re-exported in `AppTheme`. Any code needing 48px or 64px spacing has to either import `DesignConstants` directly or use raw numbers.

### 2c. Radius Tokens

| Token | Value | Exported via AppTheme? |
|-------|-------|------------------------|
| `AppTheme.radiusSmall` | 8.0 | Yes |
| `AppTheme.radiusMedium` | 12.0 | Yes |
| `AppTheme.radiusLarge` | 16.0 | Yes |
| `AppTheme.radiusXLarge` | 24.0 | Yes |
| `AppTheme.radiusFull` | 999.0 | Yes |

### 2d. Elevation Tokens

| Token | Value | Exported via AppTheme? |
|-------|-------|------------------------|
| `AppTheme.elevationLow` | 2.0 | Yes |
| `AppTheme.elevationMedium` | 4.0 | Yes |
| `AppTheme.elevationHigh` | 8.0 | Yes |
| `AppTheme.elevationModal` | 16.0 | Yes |

### 2e. Touch Target Tokens

| Token | Value | Exported via AppTheme? |
|-------|-------|------------------------|
| `AppTheme.touchTargetMin` | 48.0 | Yes |
| `AppTheme.touchTargetComfortable` | 56.0 | Yes |
| `AppTheme.touchTargetLarge` | 64.0 | Yes |

### 2f. Animation Tokens

| Token | Value | Exported via AppTheme? |
|-------|-------|------------------------|
| `AppTheme.animationFast` | 150ms | Yes |
| `AppTheme.animationNormal` | 300ms | Yes |
| `AppTheme.animationSlow` | 500ms | Yes |
| `AppTheme.curveDefault` | easeInOutCubic | Yes |
| `AppTheme.curveSpring` | easeOutBack | Yes |
| `DesignConstants.animationPageTransition` | 350ms | **NOT in AppTheme** |
| `DesignConstants.curveDecelerate` | easeOut | **NOT in AppTheme** |
| `DesignConstants.curveAccelerate` | easeIn | **NOT in AppTheme** |
| `DesignConstants.curveBounce` | elasticOut | **NOT in AppTheme** |

### 2g. Text Theme (Material 3 standard slots — all defined in all 3 themes)

| Slot | Dark Size/Weight | Usage Intent |
|------|-----------------|--------------|
| `displayLarge` | 57/w700 | Hero text |
| `displayMedium` | 45/w600 | Large display |
| `displaySmall` | 36/w600 | Medium display |
| `headlineLarge` | 32/w700 | Screen titles |
| `headlineMedium` | 28/w700 | Major section heads |
| `headlineSmall` | 24/w700 | Minor section heads |
| `titleLarge` | 22/w700 | Card/dialog titles |
| `titleMedium` | 16/w700 | List titles |
| `titleSmall` | 14/w700 | Small section labels |
| `bodyLarge` | 16/w400 | Primary content |
| `bodyMedium` | 14/w400 | Secondary content |
| `bodySmall` | 12/w400 | Captions |
| `labelLarge` | 14/w700 | Buttons, tags |
| `labelMedium` | 12/w700 | Labels |
| `labelSmall` | 11/w700 | Mini tags |

All text theme slots baked in with **Roboto** font, letterSpacing, and height values.

---

## 3. Hardcoded Colors (Features — Presentation Layer)

**Total files with `Colors.*` in presentation/**: 35+ files

### Critical violations (non-transparent, non-semantic uses):

| File | Line(s) | Value | Context |
|------|---------|-------|---------|
| `gallery/screens/gallery_screen.dart` | 549-623 | `Colors.black`, `Colors.white`, `Colors.white54`, `Colors.white70`, `Colors.black87` | Fullscreen photo viewer overlay — intentional for photo viewer dark context |
| `sync/widgets/sync_status_icon.dart` | 34-36 | `Colors.red`, `Colors.amber`, `Colors.green` | Sync status icon color — should use `AppTheme.statusError/Warning/Success` |
| `sync/screens/sync_dashboard_screen.dart` | 161-164, 384 | `Colors.red`, `Colors.amber`, `Colors.green`, `Colors.orange` | Status indicators — should use semantic tokens |
| `sync/screens/sync_dashboard_screen.dart` | 208, 395 | `Colors.grey` | Labels — should use `AppTheme.textSecondary` |
| `sync/screens/conflict_viewer_screen.dart` | 188, 232, 261, 277 | `Colors.green`, `Colors.orange`, `Colors.grey`, `Colors.grey.shade100` | Resolution state colors — should be semantic tokens |
| `dashboard/screens/project_dashboard_screen.dart` | 427, 432-433, 477 | `Colors.orange.shade800`, `Colors.amber.shade50`, `Colors.amber.shade200`, `Colors.black.withValues` | Warning chips — should use `AppTheme.statusWarning` variants |
| `quantities/screens/quantities_screen.dart` | 173, 178-179 | Same amber/orange warning chip pattern | Duplicates dashboard pattern exactly |
| `settings/widgets/member_detail_sheet.dart` | 53, 227, 245 | `Colors.grey[300]`, `Colors.grey` | Section divider and icon — should use `AppTheme.textSecondary/surfaceHighlight` |
| `settings/screens/admin_dashboard_screen.dart` | 90, 109, 148, 265, 281 | `Colors.grey`, `Colors.white` | User list items |
| `entries/screens/review_summary_screen.dart` | 91, 167, 187 | `Colors.red`, `Colors.black.withValues`, `Colors.white` | Error states, shadows, text on primary |
| `auth/screens/*.dart` | various | `Colors.white` | Text on primary buttons — should use `AppTheme.textInverse` |
| `settings/screens/settings_screen.dart` | 223 | `Colors.white` | Text on primary |
| `entries/screens/home_screen.dart` | 774-776, 1954 | `Colors.transparent` | Calendar widget overrides — acceptable |
| `projects/widgets/project_switcher.dart` | 133, 226 | `Colors.grey[300]`, `Colors.grey` | Divider and unselected icon |
| `sync/screens/project_selection_screen.dart` | 146, 213 | `Colors.red`, `Colors.grey` | Error icon and unsynced indicator |
| `dashboard/widgets/dashboard_stat_card.dart` | 54, 61 | `Colors.black.withValues(alpha: 0.15)`, `Colors.transparent` | Shadow and button background |
| `entries/screens/entry_review_screen.dart` | 230 | `Colors.black.withValues(alpha: 0.1)` | Shadow |
| `entries/screens/drafts_list_screen.dart` | 219 | `Colors.black.withValues(alpha: 0.1)` | Shadow |
| `forms/widgets/form_accordion.dart` | 38 | `Colors.transparent` | Unselected background — acceptable |
| `dashboard/widgets/tracked_item_row.dart` | 46 | `Colors.transparent` | Background — acceptable |

**Acceptable uses** (Colors.transparent, Colors.black as shadow with `withValues`, and photo-viewer overlays) should be preserved. The truly problematic ones are semantic-color replacements.

**No `Color(0x...)` hex literals** were found anywhere in `lib/features/` — the custom hex values are all in `lib/core/theme/colors.dart`. This is good.

---

## 4. Hardcoded Dimensions

### 4a. BorderRadius violations (raw numbers instead of tokens)

Unique non-token values found across presentation files:

| Value | Count | Token Equivalent | Files |
|-------|-------|-----------------|-------|
| `BorderRadius.circular(4)` | ~12 | None (token gap — smaller than `radiusSmall`) | contractor_editor_widget, photo_thumbnail, conflict_viewer, admin_dashboard |
| `BorderRadius.circular(6)` | ~4 | None (token gap) | project_list_screen, pay_item_source_dialog |
| `BorderRadius.circular(8)` | ~20+ | `AppTheme.radiusSmall` | photo_thumbnail, photo_name_dialog, entry_action_bar, photo_detail_dialog, pay_item_source_dialog, etc. |
| `BorderRadius.circular(10)` | ~10 | None (token gap) | forms widgets, project_list_screen, hub_header_content |
| `BorderRadius.circular(12)` | ~15+ | `AppTheme.radiusMedium` | todos_screen, settings_screen, form_selection_dialog, entries_list_screen, project_list_screen |
| `BorderRadius.circular(14)` | ~2 | None (token gap) | form_accordion |
| `BorderRadius.circular(20)` | ~1 | None (between radiusLarge/XLarge) | status_pill_bar |
| `BorderRadius.circular(999)` | ~3 | `AppTheme.radiusFull` | hub_proctor_content, hub_header_content, form_accordion |

**Gap summary for radius**: The 8px and 12px values simply need to use existing tokens (`radiusSmall`, `radiusMedium`). The 4, 6, 10, 14, 20 values are either inline visual choices or need new tokens.

### 4b. SizedBox spacing violations

Unique raw values used for vertical spacing:

| Value | AppTheme Token | Files (sample) |
|-------|---------------|----------------|
| 2 | None (sub-pixel, intentional) | summary_tiles, member_detail_sheet, form_accordion |
| 3 | None (sub-pixel) | hub_proctor_content |
| 4 | `AppTheme.space1` | photo_thumbnail, draft_entry_tile, entries_list_screen |
| 6 | None (token gap — between space1 and space2) | hub_proctor_content, contractor_editor_widget, hub_header_content |
| 8 | `AppTheme.space2` | Very widespread (50+ instances) across all features |
| 10 | None (between space2 and space3) | hub_quick_test_content, mdot_hub_screen |
| 12 | `AppTheme.space3` | Very widespread (40+ instances) |
| 16 | `AppTheme.space4` | Extremely widespread (50+ instances) |
| 24 | `AppTheme.space6` | Widespread (~20 instances) |
| 32 | `AppTheme.space8` | settings_screen, admin_dashboard_screen |

**The raw values 8, 12, 16, 24 are the highest-volume violations.** These directly map to existing tokens (`space2`, `space3`, `space4`, `space6`) but are written as literals throughout.

### 4c. EdgeInsets raw number violations

**179 total instances** across 58 files of `EdgeInsets` with raw numbers. The pattern is universal — essentially every screen and widget in the app.

The dominant values mirror the spacing violations: 8, 12, 16, 24 are the most common. Tokens exist for all of them.

### 4d. Icon size violations

**150 icon `size:` literal values** across 55 files. Most common values: `18`, `20`, `24`, `28`, `32`, `48`. No icon size tokens are defined anywhere in the theme system.

---

## 5. Text Style Analysis

### 5a. Theme-based text styles (`Theme.of(context).textTheme.*`)

**33 total usages** across 17 files. This is low — the textTheme is heavily defined but barely consumed via `Theme.of(context).textTheme`.

Files with the most theme-based text style usage:
- `auth/screens/otp_verification_screen.dart` — 3 uses
- `auth/screens/login_screen.dart` — 2 uses
- `entries/screens/home_screen.dart` — 1 use
- `entries/screens/entry_editor_screen.dart` — 1 use

### 5b. Inline `TextStyle(` usage — the dominant pattern

**179+ instances** across 58+ files. Every feature uses inline `TextStyle()` with raw `fontSize` values instead of `Theme.of(context).textTheme.*`.

Most common inline font sizes used:
| fontSize | Nearest textTheme slot | Count |
|----------|----------------------|-------|
| 10 | labelSmall (11) | ~8 |
| 11 | labelSmall | ~15 |
| 12 | bodySmall | ~35+ |
| 13 | bodyMedium (14) | ~20+ |
| 14 | bodyMedium / labelLarge | ~25+ |
| 15 | bodyLarge (16) — unofficial size | ~10 |
| 16 | bodyLarge / titleMedium | ~20+ |
| 18 | headlineSmall (24) — gap | ~8 |
| 20 | displaySmall (36) — gap | ~8 |
| 22 | titleLarge | ~3 |
| 36 | displaySmall | ~1 |

### 5c. Duplicate text style definitions

Multiple features define nearly identical text styles inline. Common duplicated patterns:

1. **Secondary caption**: `TextStyle(fontSize: 12, color: AppTheme.textSecondary)` — appears in contractor_editor_widget, photo_detail_dialog, entries_list_screen, photo_name_dialog, etc. (8+ instances)
2. **Bold section header**: `TextStyle(fontWeight: FontWeight.bold, fontSize: 16)` — appears in entry_contractors_section, entry_quantities_section, entry_photos_section, entry_editor_screen, report_add_contractor_sheet (5+ instances)
3. **Tertiary hint**: `TextStyle(fontSize: 12, color: AppTheme.textTertiary)` — photo_detail_dialog, report_photo_detail_dialog (4 instances)
4. **Small badge label**: `TextStyle(fontSize: 11, color: AppTheme.textSecondary)` — contractor_editor_widget, hub_quick_test_content, entry_action_bar (4 instances)

### 5d. Mixed usage problem

Many `TextStyle()` calls use `AppTheme.*` for colors but hardcode `fontSize`. Example: `TextStyle(color: AppTheme.textSecondary, fontSize: 12)` — partially tokenized.

---

## 6. Spacing Consistency Analysis

### Token adoption rate by feature

| Feature | AppTheme.space* uses | Raw number uses | Adoption |
|---------|---------------------|-----------------|---------|
| `auth` | High | Medium | ~60% |
| `calculator` | High | Medium | ~65% |
| `dashboard` | High | High | ~50% |
| `entries` (home_screen) | Very High (66 uses) | Very High | ~55% |
| `entries` (widgets) | Medium | Very High | ~35% |
| `forms` | Low | Very High | ~20% |
| `gallery` | High | Medium | ~55% |
| `quantities` | High | Medium | ~55% |
| `settings` | Medium | High | ~40% |
| `sync` | Low | High | ~20% |
| `todos` | High | High | ~50% |
| `toolbox` | High | Low | ~75% |

**The `forms`, `sync`, and `entries/widgets` directories are the least consistent.** The `toolbox` and `auth` features have the best adoption.

### Missing spacing tokens

The token at `6px` has no name — but it appears throughout the codebase. Between `space1` (4px) and `space2` (8px), a `space1_5` or `spaceXs` token would be useful.

The token at `10px` also appears frequently (notably in `mdot_hub_screen`, `hub_quick_test_content`). Between `space2` (8px) and `space3` (12px), this is a gap.

---

## 7. Icon and Asset Patterns

### Icon usage

**458 total `Icons.*` references** across 80 files. All icons use the standard Material `Icons.*` constants — no custom icon sets or SVGs were found.

**Icon sizes**: 150 raw `size:` values across 55 files. No icon size tokens exist. Common sizes:
- `18` — small inline icons
- `20` — medium icons
- `24` — standard (matches Material default)
- `28` — selected nav icons (used in theme)
- `32` — large icons in high contrast
- `48` — empty-state icons

**The absence of icon size tokens is a clear gap.** The theme defines `iconSize: 24` in IconThemeData and `28` for selected nav icons, but there are no accessible constants for other sizes.

### Asset paths

No hardcoded image asset paths were found in presentation files (images are loaded via providers/services). No SVG usage found.

---

## 8. Gap Analysis — Missing Tokens

### Missing from the design system that SHOULD be added:

| Token Name (suggested) | Value | Rationale |
|------------------------|-------|-----------|
| `AppTheme.space12` | 48.0 | Defined in `DesignConstants` but NOT re-exported via `AppTheme` |
| `AppTheme.space16` | 64.0 | Defined in `DesignConstants` but NOT re-exported via `AppTheme` |
| `AppTheme.iconSizeSmall` | 18.0 | Very common, no token |
| `AppTheme.iconSizeMedium` | 24.0 | The Material default, should be explicit |
| `AppTheme.iconSizeLarge` | 32.0 | Common for large states |
| `AppTheme.iconSizeXL` | 48.0 | Empty state and hero icons |
| `AppTheme.radiusXSmall` | 4.0 | Very common inline — chips, badges, small elements |
| `AppTheme.radiusXSMedium` or `radiusCompact` | 6.0 or 10.0 | Used in project list cards and widget headers |
| `AppTheme.overlayDark` | `Color(0x8AFFFFFF)` | Defined in `AppColors` but NOT re-exported |
| `AppColors.gradientSuccess` | green gradient | Defined in `AppColors` but NOT re-exported |
| `AppTheme.statusNeutral` | maps to `textSecondary` | Needed for "never synced" / inactive states |
| `AppTheme.warningBackground` | amber.shade50 equivalent | Warning chip background (used in 2 places identically) |
| `AppTheme.warningBorder` | amber.shade200 equivalent | Warning chip border (same 2 places) |
| `AppTheme.animationPageTransition` | 350ms | In `DesignConstants` but NOT in `AppTheme` |
| `AppTheme.curveDecelerate` | Curves.easeOut | In `DesignConstants` but NOT in `AppTheme` |
| `AppTheme.curveAccelerate` | Curves.easeIn | In `DesignConstants` but NOT in `AppTheme` |
| `AppTheme.curveBounce` | Curves.elasticOut | In `DesignConstants` but NOT in `AppTheme` |

### Missing text style shortcuts

The textTheme is well defined but practically unused. The highest-value addition would be a few named helpers:

| Suggested helper | Equivalent |
|-----------------|------------|
| `AppTheme.captionStyle(context)` | `textTheme.bodySmall` (12sp secondary) |
| `AppTheme.labelStyle(context)` | `textTheme.labelSmall.copyWith(color: textSecondary)` |
| `AppTheme.sectionHeaderStyle(context)` | `textTheme.titleMedium` (16sp bold) |

---

## 9. Recommendations for Refactor

### Priority 1 — Token Gaps (Add to design system first)

1. Add `space12`, `space16` re-exports to `AppTheme` (they exist in `DesignConstants` already)
2. Add `radiusXSmall = 4.0` token to fill the badge/chip gap
3. Add icon size tokens: `iconSizeSmall`, `iconSizeMedium`, `iconSizeLarge`, `iconSizeXL`
4. Add `overlayDark` re-export to `AppTheme`
5. Add animation curve/duration re-exports for `pageTransition`, `curveDecelerate`, `curveAccelerate`, `curveBounce`
6. Add `warningBackground` and `warningBorder` semantic color tokens (the amber chip pattern appears in at least 2 features identically)
7. Define `statusNeutral` color alias for the "never synced / grey" state

### Priority 2 — Color Violations (Most impactful fixes)

Replace the following 6 specific patterns everywhere:
1. `Colors.red` → `AppTheme.statusError`
2. `Colors.green` → `AppTheme.statusSuccess`
3. `Colors.amber` / `Colors.orange` → `AppTheme.statusWarning` / `AppTheme.accentAmber`
4. `Colors.grey` → `AppTheme.textSecondary` or `AppTheme.textTertiary`
5. `Colors.white` (on primary button) → `AppTheme.textInverse`
6. `Colors.black.withValues(alpha: 0.1)` → Keep as-is or create a `shadowColorLight` token

### Priority 3 — Text Style Migration

1. Replace `TextStyle(fontSize: 12, color: AppTheme.textSecondary)` → `Theme.of(context).textTheme.bodySmall` — 35+ instances
2. Replace `TextStyle(fontWeight: FontWeight.bold, fontSize: 16)` → `Theme.of(context).textTheme.titleMedium` — 5+ instances
3. Replace `TextStyle(fontSize: 11/12, color: AppTheme.textSecondary)` → `Theme.of(context).textTheme.labelSmall` — 15+ instances

### Priority 4 — Spacing and Radius Standardization

The raw `SizedBox(height: 8/12/16/24)` and `EdgeInsets` with matching values should be `AppTheme.space2/3/4/6`. This is high volume (~150+ instances) but mechanical — could be handled by a search-replace script with careful review.

### Priority 5 — Architecture

Consider adding a `lib/core/theme/app_text_styles.dart` extension class with named helpers that wrap `Theme.of(context).textTheme.*` calls to make them discoverable and reduce repeated `.copyWith()` boilerplate.

---

## 10. Quick Statistics

| Metric | Count |
|--------|-------|
| Files with `Colors.*` violations (non-transparent) | ~25 |
| Files with hardcoded `fontSize:` values | 58 |
| Files with `BorderRadius.circular(raw)` | 35+ |
| Files with `SizedBox(height: raw)` | 60+ |
| Files using `Theme.of(context).textTheme` | 17 |
| Files using `AppTheme.*` color tokens | 91 |
| Files using `AppTheme.space*` tokens | 31 |
| Files using `Icons.*` (standard — expected) | 80 |
| Total `AppTheme.*` references | 1,330+ |
| Total inline `TextStyle(` usages | 179+ |
| Total raw `SizedBox(height:)` usages | 200+ |
| Total `EdgeInsets` raw number usages | 179 |
| Features with ZERO `Colors.*` violations | calculator, locations, photos (mostly), weather |
