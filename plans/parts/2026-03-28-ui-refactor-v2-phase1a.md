# Phase 1: Foundation — Theme Tokens + Design System Components (Part A)

> **Dependency**: None — this is the absolute foundation. Every subsequent phase depends on 1.A and 1.B.

---

## Sub-phase 1.A: Fill Theme Token Gaps

**Files:**
- Modify: `lib/core/theme/colors.dart` (lines 130-170)
- Modify: `lib/core/theme/design_constants.dart` (lines 43-61)
- Modify: `lib/core/theme/app_theme.dart` (lines 60-84, 169)

**Agent**: `frontend-flutter-specialist-agent`

### Step 1.A.1: Add missing color tokens to AppColors

**File:** `lib/core/theme/colors.dart`
**Where:** Insert after line 30 (after `statusInfo`), before the dark theme surfaces section comment at line 32.

```dart
  // WHY: statusNeutral is used for "no status" / "default" states across entry cards,
  // sync badges, and form chips. Currently hardcoded as textSecondary in 12+ places.
  static const Color statusNeutral = Color(0xFF8B949E);
```

**Where:** Insert after line 41 (after `surfaceGlass`), before the dark theme text section comment at line 43.

```dart
  // WHY: Warning-state backgrounds and borders are hardcoded with inline withOpacity()
  // calls in 8+ widgets (sync banner, validation chips, stale-data warnings).
  // Centralizing avoids drift and enables theme-aware variants in FieldGuideColors.
  static const Color warningBackground = Color(0x1AFFB300);  // 10% amber
  static const Color warningBorder = Color(0x33FFB300);       // 20% amber

  // WHY: Shadow color with fixed alpha — used by glassmorphic cards and elevated surfaces.
  // Currently hardcoded as Colors.black.withOpacity(0.1) in 6+ BoxDecoration usages.
  static const Color shadowLight = Color(0x1A000000);         // 10% black
```

**Where:** Insert after line 110 (after `overlayDark`), before the gradient section comment at line 112.

```dart
  // ==========================================================================
  // PHOTO VIEWER COLORS
  // ==========================================================================

  // WHY: Photo viewer overlay uses its own text colors for captions, metadata, and
  // EXIF display. Currently hardcoded as Colors.white / Colors.white70 / Colors.white54
  // across photo_viewer_screen.dart and gallery widgets.
  static const Color photoViewerBg = Color(0xFF000000);
  static const Color photoViewerText = Color(0xFFFFFFFF);
  static const Color photoViewerTextMuted = Color(0xB3FFFFFF);   // 70% white
  static const Color photoViewerTextDim = Color(0x8AFFFFFF);     // 54% white

  // ==========================================================================
  // SPECIALIZED UI COLORS
  // ==========================================================================

  // WHY: The "vivid" dark background is a deeper blue-black used by the new
  // home screen and dashboard. Distinct from backgroundDark to signal premium UI.
  static const Color tVividBackground = Color(0xFF050810);

  // WHY: Section accent colors for entry detail chips (quantities, photos).
  // Currently hardcoded in entry_detail_screen.dart and section_header widgets.
  static const Color sectionQuantities = Color(0xFF26C6DA);     // Cyan 400
  static const Color sectionPhotos = Color(0xFFBA68C8);          // Purple 300

  // WHY: Project number subtitle text on cards. Currently hardcoded as Color(0xFFCCCCCC)
  // in project_card.dart and project_list_tile.dart.
  static const Color projectNumberText = Color(0xFFCCCCCC);
```

### Step 1.A.2: Add missing design constant tokens to DesignConstants

**File:** `lib/core/theme/design_constants.dart`
**Where:** Insert after line 43 (after `radiusFull = 999.0;`), before the elevation section comment at line 45.

```dart
  // WHY: radiusXSmall (4.0) is needed for tight chips, badges, and inline tags.
  // Currently hardcoded as BorderRadius.circular(4) in 10+ chip/badge widgets.
  static const double radiusXSmall = 4.0;

  // WHY: radiusCompact (10.0) fills the gap between radiusSmall (8) and radiusMedium (12).
  // Used by bottom sheets and action menus where 8 is too tight and 12 too round.
  static const double radiusCompact = 10.0;

  // ==========================================================================
  // ICON SIZE SYSTEM
  // ==========================================================================

  // WHY: Icon sizes are hardcoded as magic numbers (18, 24, 32, 48) across 40+ widgets.
  // Centralizing enables consistent scaling and accessibility overrides.
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXL = 48.0;
```

### Step 1.A.3: Add re-exports to AppTheme for new tokens

**File:** `lib/core/theme/app_theme.dart`
**Where:** Insert after line 63 (after `static const Color hcTextSecondary = AppColors.hcTextSecondary;`), before the weather colors comment at line 65.

```dart
  // NOTE: Re-exports for new tokens added in 1.A.1. Maintains the pattern where
  // widgets can reference AppTheme.* without importing colors.dart directly.
  static const Color hcSuccess = AppColors.hcSuccess;
  static const Color statusNeutral = AppColors.statusNeutral;
  static const Color warningBackground = AppColors.warningBackground;
  static const Color warningBorder = AppColors.warningBorder;
  static const Color shadowLight = AppColors.shadowLight;
  static const Color photoViewerBg = AppColors.photoViewerBg;
  static const Color photoViewerText = AppColors.photoViewerText;
  static const Color photoViewerTextMuted = AppColors.photoViewerTextMuted;
  static const Color photoViewerTextDim = AppColors.photoViewerTextDim;
  static const Color tVividBackground = AppColors.tVividBackground;
  static const Color sectionQuantities = AppColors.sectionQuantities;
  static const Color sectionPhotos = AppColors.sectionPhotos;
  static const Color projectNumberText = AppColors.projectNumberText;
```

**Where:** Insert after line 113 (after `static const double radiusFull = DesignConstants.radiusFull;`), before the elevation comment at line 115.

```dart
  // NOTE: Re-exports for new design constant tokens added in 1.A.2.
  static const double radiusXSmall = DesignConstants.radiusXSmall;
  static const double radiusCompact = DesignConstants.radiusCompact;
  static const double iconSizeSmall = DesignConstants.iconSizeSmall;
  static const double iconSizeMedium = DesignConstants.iconSizeMedium;
  static const double iconSizeLarge = DesignConstants.iconSizeLarge;
  static const double iconSizeXL = DesignConstants.iconSizeXL;
```

### Step 1.A.4: Update darkTheme scaffoldBackgroundColor

**File:** `lib/core/theme/app_theme.dart`
**Where:** Line 169 — replace `backgroundDark` with `tVividBackground`.

```dart
// BEFORE (line 169):
      scaffoldBackgroundColor: backgroundDark,

// AFTER:
      // WHY: tVividBackground (#050810) is a deeper blue-black that creates stronger
      // contrast with surfaceDark cards. backgroundDark (#0A0E14) remains available
      // for widgets that need the original shade.
      scaffoldBackgroundColor: tVividBackground,
```

### Step 1.A.5: Verify

```bash
pwsh -Command "flutter analyze lib/core/theme/"
```

Expected: 0 issues. All new constants are additive — no existing code breaks.

---

## Sub-phase 1.B: Create FieldGuideColors ThemeExtension

**Files:**
- Create: `lib/core/theme/field_guide_colors.dart`
- Modify: `lib/core/theme/app_theme.dart` (lines 757-758, 1117-1118, 1484-1485)
- Modify: `lib/core/theme/theme.dart` (line 4)

**Agent**: `frontend-flutter-specialist-agent`

### Step 1.B.1: Create FieldGuideColors ThemeExtension class

**File:** `lib/core/theme/field_guide_colors.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'colors.dart';

/// WHY: ThemeExtension provides semantic colors that vary per theme (dark/light/HC).
/// This replaces the pattern of checking brightness and picking colors manually,
/// which is scattered across 30+ widgets. With FieldGuideColors.of(context), widgets
/// get the correct color automatically.
///
/// NOTE: Every field here maps to a hardcoded color that currently differs between
/// themes. Static AppColors constants that are the same across all themes (e.g.,
/// statusError, primaryCyan) stay in AppColors and do NOT need to be here.
class FieldGuideColors extends ThemeExtension<FieldGuideColors> {
  const FieldGuideColors({
    required this.surfaceElevated,
    required this.surfaceGlass,
    required this.surfaceBright,
    required this.textTertiary,
    required this.textInverse,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusInfo,
    required this.warningBackground,
    required this.warningBorder,
    required this.shadowLight,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accentAmber,
    required this.accentOrange,
    required this.dragHandleColor,
  });

  /// Elevated surface — cards, dialogs, bottom sheets
  final Color surfaceElevated;

  /// Glassmorphic overlay — frosted panels, floating toolbars
  final Color surfaceGlass;

  /// Active/hover surface — slider tracks, secondary buttons
  final Color surfaceBright;

  /// Tertiary text — hints, disabled labels, timestamps
  final Color textTertiary;

  /// Text on primary-colored backgrounds (buttons, chips)
  final Color textInverse;

  /// Success indicators — checkmarks, completion badges
  final Color statusSuccess;

  /// Warning indicators — stale data, sync delays
  final Color statusWarning;

  /// Informational indicators — tips, sync status
  final Color statusInfo;

  /// Warning banner/chip background (low-alpha)
  final Color warningBackground;

  /// Warning banner/chip border (low-alpha)
  final Color warningBorder;

  /// Subtle shadow for elevated surfaces
  final Color shadowLight;

  /// Primary gradient start color
  final Color gradientStart;

  /// Primary gradient end color
  final Color gradientEnd;

  /// Amber accent — highlights, badges, stars
  final Color accentAmber;

  /// Orange accent — urgent actions, overdue indicators
  final Color accentOrange;

  /// Drag handle / reorder grip color
  final Color dragHandleColor;

  // ===========================================================================
  // THEME INSTANCES
  // ===========================================================================

  /// WHY: const instances enable zero-cost registration on ThemeData.extensions.
  static const dark = FieldGuideColors(
    surfaceElevated: AppColors.surfaceElevated,       // #1C2128
    surfaceGlass: AppColors.surfaceGlass,             // #99161B22
    surfaceBright: AppColors.surfaceBright,            // #444C56
    textTertiary: AppColors.textTertiary,             // #6E7681
    textInverse: AppColors.textInverse,               // #0A0E14
    statusSuccess: AppColors.statusSuccess,           // #4CAF50
    statusWarning: AppColors.statusWarning,           // #FF9800
    statusInfo: AppColors.statusInfo,                 // #2196F3
    warningBackground: AppColors.warningBackground,   // #1AFFB300
    warningBorder: AppColors.warningBorder,           // #33FFB300
    shadowLight: AppColors.shadowLight,               // #1A000000
    gradientStart: AppColors.primaryCyan,             // #00E5FF
    gradientEnd: AppColors.primaryBlue,               // #2196F3
    accentAmber: AppColors.accentAmber,               // #FFB300
    accentOrange: AppColors.accentOrange,             // #FF6F00
    dragHandleColor: AppColors.surfaceHighlight,      // #2D333B
  );

  static const light = FieldGuideColors(
    surfaceElevated: AppColors.lightSurfaceElevated,  // #FFFFFF
    surfaceGlass: Color(0xCCFFFFFF),                  // 80% white
    surfaceBright: AppColors.lightSurfaceHighlight,   // #E2E8F0
    textTertiary: AppColors.lightTextTertiary,        // #94A3B8
    textInverse: Color(0xFFFFFFFF),                   // pure white (on blue primary)
    statusSuccess: AppColors.statusSuccess,           // #4CAF50 (same)
    statusWarning: AppColors.statusWarning,           // #FF9800 (same)
    statusInfo: AppColors.statusInfo,                 // #2196F3 (same)
    warningBackground: Color(0x1AFF9800),             // 10% warning orange
    warningBorder: Color(0x33FF9800),                 // 20% warning orange
    shadowLight: Color(0x0D000000),                   // 5% black (lighter shadow)
    gradientStart: AppColors.primaryBlue,             // #2196F3
    gradientEnd: AppColors.primaryDark,               // #0277BD
    accentAmber: AppColors.accentAmber,               // #FFB300 (same)
    accentOrange: AppColors.accentOrange,             // #FF6F00 (same)
    dragHandleColor: AppColors.lightSurfaceHighlight, // #E2E8F0
  );

  static const highContrast = FieldGuideColors(
    surfaceElevated: AppColors.hcSurfaceElevated,     // #1E1E1E
    surfaceGlass: Color(0xCC121212),                  // 80% hcSurface
    surfaceBright: Color(0xFF333333),                 // bright enough for contrast
    textTertiary: Color(0xFF808080),                  // mid-gray
    textInverse: Color(0xFF000000),                   // pure black (on cyan primary)
    statusSuccess: AppColors.hcSuccess,               // #00FF00
    statusWarning: AppColors.hcWarning,               // #FFAA00
    statusInfo: AppColors.hcPrimary,                  // #00FFFF
    warningBackground: Color(0x1AFFAA00),             // 10% hcWarning
    warningBorder: Color(0x33FFAA00),                 // 20% hcWarning
    shadowLight: Colors.transparent,                  // no subtle shadows in HC
    gradientStart: AppColors.hcPrimary,               // #00FFFF
    gradientEnd: AppColors.hcPrimary,                 // #00FFFF (flat — no gradient in HC)
    accentAmber: AppColors.hcAccent,                  // #FFFF00
    accentOrange: AppColors.hcWarning,                // #FFAA00
    dragHandleColor: Color(0xFFFFFFFF),               // max contrast
  );

  // ===========================================================================
  // CONVENIENCE ACCESSOR
  // ===========================================================================

  /// WHY: Shorthand that mirrors the standard Theme.of(context) pattern.
  /// Usage: `FieldGuideColors.of(context).surfaceElevated`
  /// Falls back to dark theme if extension is somehow missing (defensive).
  static FieldGuideColors of(BuildContext context) {
    return Theme.of(context).extension<FieldGuideColors>() ?? dark;
  }

  // ===========================================================================
  // ThemeExtension OVERRIDES
  // ===========================================================================

  @override
  FieldGuideColors copyWith({
    Color? surfaceElevated,
    Color? surfaceGlass,
    Color? surfaceBright,
    Color? textTertiary,
    Color? textInverse,
    Color? statusSuccess,
    Color? statusWarning,
    Color? statusInfo,
    Color? warningBackground,
    Color? warningBorder,
    Color? shadowLight,
    Color? gradientStart,
    Color? gradientEnd,
    Color? accentAmber,
    Color? accentOrange,
    Color? dragHandleColor,
  }) {
    return FieldGuideColors(
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      surfaceBright: surfaceBright ?? this.surfaceBright,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusWarning: statusWarning ?? this.statusWarning,
      statusInfo: statusInfo ?? this.statusInfo,
      warningBackground: warningBackground ?? this.warningBackground,
      warningBorder: warningBorder ?? this.warningBorder,
      shadowLight: shadowLight ?? this.shadowLight,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      accentAmber: accentAmber ?? this.accentAmber,
      accentOrange: accentOrange ?? this.accentOrange,
      dragHandleColor: dragHandleColor ?? this.dragHandleColor,
    );
  }

  @override
  FieldGuideColors lerp(FieldGuideColors? other, double t) {
    if (other is! FieldGuideColors) return this;
    return FieldGuideColors(
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      surfaceBright: Color.lerp(surfaceBright, other.surfaceBright, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusInfo: Color.lerp(statusInfo, other.statusInfo, t)!,
      warningBackground: Color.lerp(warningBackground, other.warningBackground, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      shadowLight: Color.lerp(shadowLight, other.shadowLight, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
      accentOrange: Color.lerp(accentOrange, other.accentOrange, t)!,
      dragHandleColor: Color.lerp(dragHandleColor, other.dragHandleColor, t)!,
    );
  }
}
```

### Step 1.B.2: Register FieldGuideColors on all three ThemeData builders

**File:** `lib/core/theme/app_theme.dart`

First, add the import at the top of the file.

**Where:** After line 4 (`import 'design_constants.dart';`), insert:

```dart
import 'field_guide_colors.dart';
```

Then register the extension on each theme's ThemeData. The `.copyWith(extensions:)` pattern is used because the ThemeData constructors don't have an `extensions` parameter — we must chain `.copyWith()`.

**Dark theme — line 758** (the `);` closing the ThemeData return)

Replace:
```dart
    );
  }
```
with:
```dart
    // NOTE: Register FieldGuideColors extension so widgets can use
    // FieldGuideColors.of(context) to get theme-aware semantic colors.
    ).copyWith(extensions: const [FieldGuideColors.dark]);
  }
```

> WHY: ThemeData constructor does not accept `extensions` directly. The `.copyWith(extensions:)` pattern is the standard Flutter approach for registering ThemeExtension instances.

**Light theme — line 1118** (the `);` closing the ThemeData return)

Replace:
```dart
    );
  }
```
with:
```dart
    ).copyWith(extensions: const [FieldGuideColors.light]);
  }
```

**High contrast theme — line 1485** (the `);` closing the ThemeData return)

Replace:
```dart
    );
  }
```
with:
```dart
    ).copyWith(extensions: const [FieldGuideColors.highContrast]);
  }
```

### Step 1.B.3: Update barrel export

**File:** `lib/core/theme/theme.dart`
**Where:** After line 4 (`export 'design_constants.dart';`), append:

```dart
export 'field_guide_colors.dart';
```

### Step 1.B.4: Verify

```bash
pwsh -Command "flutter analyze lib/core/theme/"
```

Expected: 0 issues. The ThemeExtension is registered but not consumed yet — no widgets change in this phase.

Additional validation:

```bash
pwsh -Command "flutter test test/ --tags theme 2>&1; exit 0"
```

> NOTE: If no tests are tagged `theme`, this exits cleanly. The real validation is `flutter analyze` — it catches type errors, missing imports, and const violations.

---

## Verification Checklist

After both 1.A and 1.B are complete:

| Check | Command | Expected |
|-------|---------|----------|
| Static analysis clean | `pwsh -Command "flutter analyze lib/core/theme/"` | 0 issues |
| Full test suite passes | `pwsh -Command "flutter test"` | All green (no regressions) |
| FieldGuideColors accessible | Spot-check: `FieldGuideColors.of(context).surfaceElevated` resolves | Type-safe Color |
| All 3 themes have extension | `darkTheme.extension<FieldGuideColors>()` is non-null | true |
| New tokens compile as const | All `AppColors.*` and `DesignConstants.*` additions are `static const` | Compile-time const |

---

## Line Number Reference (pre-edit)

| File | Key Lines |
|------|-----------|
| `colors.dart` | 30: statusInfo, 41: surfaceGlass, 110: overlayDark, 170: closing `}` |
| `design_constants.dart` | 43: radiusFull, 61: closing `}` |
| `app_theme.dart` | 4: last import, 63: hcTextSecondary re-export, 84: legacy aliases end, 113: radiusFull re-export, 169: scaffoldBackgroundColor, 758: darkTheme `);`, 1118: lightTheme `);`, 1485: highContrastTheme `);` |
| `theme.dart` | 4: last export |
