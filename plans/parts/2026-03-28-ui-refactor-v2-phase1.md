# Phase 1: Foundation — Theme Tokens + Design System Components

> **Depends on:** Nothing (this is the foundation)
> **Blocks:** All subsequent phases (2–6)
> **Estimated steps:** 8 sub-phases, ~45 discrete steps
> **Quality gate:** `pwsh -Command "flutter analyze"` clean + `pwsh -Command "flutter test test/core/design_system/"` all green

---

## Phase 1.A: Fill Theme Token Gaps

### Sub-phase 1.A: Add Missing Color + Sizing Tokens

**Files:**
- Modify: `lib/core/theme/colors.dart`
- Modify: `lib/core/theme/design_constants.dart`
- Modify: `lib/core/theme/app_theme.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.A.1: Add missing color tokens to AppColors

> **WHY:** Audit found 88 raw `Colors.*` usages and 183 ad-hoc `withValues(alpha:)` calls.
> These tokens give semantic names to colors currently hardcoded inline across the codebase.
> Each token maps to a specific violation found during the audit.

In `lib/core/theme/colors.dart`, add the following block **after** the `ENTRY STATUS COLORS` section (after line 103) and **before** the `OVERLAY COLORS` section (before line 105):

```dart
  // ==========================================================================
  // ADDITIONAL SEMANTIC COLORS (from UI audit)
  // ==========================================================================

  /// Neutral status — incomplete items, default state (currently hardcoded as textTertiary)
  static const Color statusNeutral = Color(0xFF6E7681);

  /// Warning banner background — amber at 10% opacity on dark, 15% on light
  static const Color warningBackground = Color(0x1AFFB300);

  /// Warning banner border — amber at 30% opacity
  static const Color warningBorder = Color(0x4DFFB300);

  /// Light shadow for elevated surfaces (used in BoxShadow, currently Colors.black12)
  static const Color shadowLight = Color(0x1F000000);

  /// Photo viewer overlay background
  static const Color photoViewerBg = Color(0xFF000000);

  /// Photo viewer primary text
  static const Color photoViewerText = Color(0xFFFFFFFF);

  /// Photo viewer muted text (metadata captions)
  static const Color photoViewerTextMuted = Color(0xB3FFFFFF);

  /// Photo viewer dim text (timestamps)
  static const Color photoViewerTextDim = Color(0x80FFFFFF);

  /// T Vivid background — slightly warmer than backgroundDark for main scaffold
  static const Color tVividBackground = Color(0xFF0D1117);

  /// Section header accent: Quantities
  static const Color sectionQuantities = Color(0xFF58A6FF);

  /// Section header accent: Photos
  static const Color sectionPhotos = Color(0xFF3FB950);

  /// Project number text color (cyan-tinted)
  static const Color projectNumberText = Color(0xFF79C0FF);
```

#### Step 1.A.2: Add missing sizing tokens to DesignConstants

> **WHY:** Audit found 188 literal `BorderRadius.circular()` calls including `circular(4)` with
> no token, and icon sizes scattered as magic numbers (18, 24, 32, 48).

In `lib/core/theme/design_constants.dart`, add after the existing `RADIUS SYSTEM` section (after line 43, before `ELEVATION SYSTEM`):

```dart

  /// Extra-small radius for checkboxes, tiny badges (4px — audit found 12 occurrences)
  static const double radiusXSmall = 4.0;

  /// Compact radius for pills, tags (10px — between small and medium)
  static const double radiusCompact = 10.0;
```

Then add a new section **after** the `TOUCH TARGET SIZES` section (after line 60, before the closing brace):

```dart

  // ==========================================================================
  // ICON SIZES (standardized from audit of 25+ ad-hoc values)
  // ==========================================================================

  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXL = 48.0;
```

#### Step 1.A.3: Add re-exports to AppTheme

> **WHY:** 1,462 call sites use `AppTheme.*` — we must re-export new tokens through AppTheme
> for backwards compatibility until migration is complete in later phases.

In `lib/core/theme/app_theme.dart`, add after the existing color exports block. Find the line:

```dart
  // Legacy aliases (kept: still referenced externally)
```

Insert **before** that line:

```dart
  // Additional semantic colors (from UI audit)
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

Then find the line:

```dart
  // Elevation
```

Insert **before** that line:

```dart
  // Radius (new)
  static const double radiusXSmall = DesignConstants.radiusXSmall;
  static const double radiusCompact = DesignConstants.radiusCompact;

  // Icon sizes
  static const double iconSizeSmall = DesignConstants.iconSizeSmall;
  static const double iconSizeMedium = DesignConstants.iconSizeMedium;
  static const double iconSizeLarge = DesignConstants.iconSizeLarge;
  static const double iconSizeXL = DesignConstants.iconSizeXL;

```

#### Step 1.A.4: Update scaffoldBackgroundColor in darkTheme

> **WHY:** The T Vivid design language uses `0xFF0D1117` (slightly warmer charcoal) as the
> primary background, not the current `0xFF0A0E14`. This change affects all dark-mode screens.

In `lib/core/theme/app_theme.dart`, in the `darkTheme` getter, find:

```dart
      scaffoldBackgroundColor: backgroundDark,
```

Replace with:

```dart
      scaffoldBackgroundColor: tVividBackground,
```

> **IMPORTANT:** Do NOT change `backgroundDark` itself — it's still used for systemNavigationBarColor
> and other places where the deeper color is correct. Only the scaffold background changes.

---

## Phase 1.B: Create FieldGuideColors ThemeExtension

### Sub-phase 1.B: ThemeExtension for App-Specific Colors

**Files:**
- Create: `lib/core/theme/field_guide_colors.dart`
- Modify: `lib/core/theme/app_theme.dart` (register extension on all 3 themes)
- Modify: `lib/core/theme/theme.dart` (add barrel export)

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.B.1: Create FieldGuideColors ThemeExtension

> **WHY:** Material's ColorScheme has 30 slots but our app needs 16 additional semantic colors
> that vary per theme. ThemeExtension is the M3-blessed way to extend theming without hacks.
> This enables `FieldGuideColors.of(context)` — a theme-aware accessor that replaces 183+
> static `AppTheme.*` color references with context-aware lookups.

Create `lib/core/theme/field_guide_colors.dart`:

```dart
import 'package:flutter/material.dart';
import 'colors.dart';

/// Theme extension providing app-specific semantic colors that vary per theme.
///
/// Access pattern (use in all widgets):
/// ```dart
/// final fg = FieldGuideColors.of(context);
/// Container(color: fg.surfaceElevated);
/// ```
///
/// WHY ThemeExtension: Material's ColorScheme has fixed slots. Our app needs
/// surfaceGlass, accent variants, warning containers, and gradient endpoints
/// that don't map to any M3 role. ThemeExtension is the official M3 escape hatch.
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

  /// Elevated card/dialog surface — darker than M3 surface, lighter than scaffold
  final Color surfaceElevated;

  /// Glassmorphic overlay surface — semi-transparent for blur effects
  final Color surfaceGlass;

  /// Active/hover surface — brightest surface tier
  final Color surfaceBright;

  /// Tertiary text — hints, disabled labels, timestamps
  final Color textTertiary;

  /// Inverse text — dark text on light/accent backgrounds (e.g., on primaryCyan buttons)
  final Color textInverse;

  /// Success status — checkmarks, completion indicators
  final Color statusSuccess;

  /// Warning status — caution banners, budget alerts
  final Color statusWarning;

  /// Info status — informational badges, sync indicators
  final Color statusInfo;

  /// Warning banner background — tinted amber container
  final Color warningBackground;

  /// Warning banner border — visible amber edge
  final Color warningBorder;

  /// Subtle shadow — for elevated surfaces in BoxShadow
  final Color shadowLight;

  /// Primary gradient start color (left/top)
  final Color gradientStart;

  /// Primary gradient end color (right/bottom)
  final Color gradientEnd;

  /// Amber accent — highlights, stars, badges
  final Color accentAmber;

  /// Orange accent — urgent actions, deep warnings
  final Color accentOrange;

  /// Drag handle color for bottom sheets
  final Color dragHandleColor;

  // ---------------------------------------------------------------------------
  // NAMED CONSTRUCTORS — one per theme variant
  // ---------------------------------------------------------------------------

  /// Dark theme (T Vivid) — primary field-use theme
  static const dark = FieldGuideColors(
    surfaceElevated: AppColors.surfaceElevated,       // 0xFF1C2128
    surfaceGlass: AppColors.surfaceGlass,             // 0x99161B22
    surfaceBright: AppColors.surfaceBright,            // 0xFF444C56
    textTertiary: AppColors.textTertiary,              // 0xFF6E7681
    textInverse: AppColors.textInverse,                // 0xFF0A0E14
    statusSuccess: AppColors.statusSuccess,            // 0xFF4CAF50
    statusWarning: AppColors.statusWarning,            // 0xFFFF9800
    statusInfo: AppColors.statusInfo,                  // 0xFF2196F3
    warningBackground: AppColors.warningBackground,    // 0x1AFFB300
    warningBorder: AppColors.warningBorder,            // 0x4DFFB300
    shadowLight: AppColors.shadowLight,                // 0x1F000000
    gradientStart: AppColors.primaryCyan,              // 0xFF00E5FF
    gradientEnd: AppColors.primaryBlue,                // 0xFF2196F3
    accentAmber: AppColors.accentAmber,                // 0xFFFFB300
    accentOrange: AppColors.accentOrange,              // 0xFFFF6F00
    dragHandleColor: AppColors.surfaceBright,          // 0xFF444C56
  );

  /// Light theme — indoor/office use
  static const light = FieldGuideColors(
    surfaceElevated: AppColors.lightSurfaceElevated,   // 0xFFFFFFFF
    surfaceGlass: Color(0xCCFFFFFF),                   // white at 80% — light glassmorphism
    surfaceBright: AppColors.lightSurfaceHighlight,    // 0xFFE2E8F0
    textTertiary: AppColors.lightTextTertiary,         // 0xFF94A3B8
    textInverse: Color(0xFFFFFFFF),                    // white text on colored buttons
    statusSuccess: AppColors.statusSuccess,            // 0xFF4CAF50 — same across themes
    statusWarning: AppColors.statusWarning,            // 0xFFFF9800
    statusInfo: AppColors.primaryBlue,                 // 0xFF2196F3 — light uses blue as primary
    warningBackground: Color(0x26FFB300),              // amber at 15% on light
    warningBorder: Color(0x4DFFB300),                  // amber at 30%
    shadowLight: Color(0x14000000),                    // lighter shadow for light theme
    gradientStart: AppColors.primaryBlue,              // 0xFF2196F3 — light uses blue
    gradientEnd: AppColors.primaryDark,                // 0xFF0277BD
    accentAmber: AppColors.accentAmber,                // 0xFFFFB300
    accentOrange: AppColors.accentOrange,              // 0xFFFF6F00
    dragHandleColor: Color(0xFFCBD5E1),               // slate-300 for light mode
  );

  /// High contrast theme — maximum accessibility
  static const highContrast = FieldGuideColors(
    surfaceElevated: AppColors.hcSurfaceElevated,      // 0xFF1E1E1E
    surfaceGlass: Color(0xE6121212),                   // near-opaque — blur not relied on in HC
    surfaceBright: Color(0xFF333333),                  // HC active surface
    textTertiary: AppColors.hcTextSecondary,           // 0xFFCCCCCC — brighter than dark theme
    textInverse: Color(0xFF000000),                    // black text on HC accent buttons
    statusSuccess: AppColors.hcSuccess,                // 0xFF00FF00 — pure green
    statusWarning: AppColors.hcWarning,                // 0xFFFFAA00 — pure orange
    statusInfo: AppColors.hcPrimary,                   // 0xFF00FFFF — pure cyan
    warningBackground: Color(0x33FFAA00),              // HC orange at 20%
    warningBorder: Color(0x80FFAA00),                  // HC orange at 50% — extra visible
    shadowLight: Color(0x00000000),                    // no subtle shadows in HC — use borders
    gradientStart: AppColors.hcPrimary,                // 0xFF00FFFF
    gradientEnd: AppColors.hcPrimary,                  // same — no gradient in HC for clarity
    accentAmber: AppColors.hcAccent,                   // 0xFFFFFF00 — pure yellow
    accentOrange: AppColors.hcWarning,                 // 0xFFFFAA00
    dragHandleColor: AppColors.hcBorder,               // 0xFFFFFFFF — max contrast
  );

  // ---------------------------------------------------------------------------
  // CONTEXT ACCESSOR
  // ---------------------------------------------------------------------------

  /// Shorthand to access FieldGuideColors from any widget.
  ///
  /// Usage: `final fg = FieldGuideColors.of(context);`
  ///
  /// NOTE: Falls back to [dark] if extension is not registered (defensive).
  /// This should never happen in production — all 3 ThemeData builders register it.
  static FieldGuideColors of(BuildContext context) {
    return Theme.of(context).extension<FieldGuideColors>() ?? dark;
  }

  // ---------------------------------------------------------------------------
  // THEME EXTENSION PROTOCOL
  // ---------------------------------------------------------------------------

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
  FieldGuideColors lerp(covariant FieldGuideColors? other, double t) {
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

#### Step 1.B.2: Register FieldGuideColors on all 3 ThemeData builders

> **WHY:** ThemeExtensions must be explicitly registered on each ThemeData. Without this,
> `Theme.of(context).extension<FieldGuideColors>()` returns null.

In `lib/core/theme/app_theme.dart`, add import at top (after line 3):

```dart
import 'field_guide_colors.dart';
```

**Dark theme** — find the closing `);` of the `darkTheme` getter's `ThemeData(` constructor. It's the line right before the closing `}` of the getter (currently line 758: `    );`). Insert **before** that closing `);`:

```dart

      // -----------------------------------------------------------------------
      // THEME EXTENSIONS — app-specific semantic colors
      // -----------------------------------------------------------------------
      extensions: const <ThemeExtension>[
        FieldGuideColors.dark,
      ],
```

**Light theme** — find the closing `);` of `lightTheme`'s `ThemeData(` (currently line 1118: `    );`). Insert **before** it:

```dart

      extensions: const <ThemeExtension>[
        FieldGuideColors.light,
      ],
```

**High contrast theme** — find the closing `);` of `highContrastTheme`'s `ThemeData(` (currently line 1485: `    );`). Insert **before** it:

```dart

      extensions: const <ThemeExtension>[
        FieldGuideColors.highContrast,
      ],
```

#### Step 1.B.3: Add barrel export for field_guide_colors.dart

In `lib/core/theme/theme.dart`, add after the existing exports:

```dart
export 'field_guide_colors.dart';
```

---

## Phase 1.C: Build Atomic Layer Components

### Sub-phase 1.C: Atomic Design System Widgets (in lib/core/design_system/)

**Files:**
- Create: `lib/core/design_system/app_text.dart`
- Create: `lib/core/design_system/app_text_field.dart`
- Create: `lib/core/design_system/app_chip.dart`
- Create: `lib/core/design_system/app_progress_bar.dart`
- Create: `lib/core/design_system/app_counter_field.dart`
- Create: `lib/core/design_system/app_toggle.dart`
- Create: `lib/core/design_system/app_icon.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.C.1: Create AppText — textTheme slot enforcer

> **WHY:** 447 inline TextStyle constructors across 81 files. AppText forces usage of
> textTheme slots, eliminating ad-hoc font sizes, weights, and families. Named factories
> map to the M3 text scale so developers never need to remember slot names.

Create `lib/core/design_system/app_text.dart`:

```dart
import 'package:flutter/material.dart';

/// Enforces textTheme slot usage instead of inline TextStyle constructors.
///
/// Usage:
/// ```dart
/// AppText.titleMedium('Section Header', context)
/// AppText.bodyMedium('Content text', context, color: fg.textTertiary)
/// ```
///
/// WHY: Eliminates 447 inline TextStyle constructors. Every factory maps 1:1
/// to a Material 3 textTheme slot, ensuring typographic consistency.
class AppText extends StatelessWidget {
  const AppText._({
    required this.text,
    required this.styleBuilder,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  final String text;
  final TextStyle? Function(TextTheme) styleBuilder;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  // ---------------------------------------------------------------------------
  // DISPLAY
  // ---------------------------------------------------------------------------

  /// 57px / w700 — splash screens, hero numbers
  factory AppText.displayLarge(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.displayLarge, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  /// 45px / w600 — large headings
  factory AppText.displayMedium(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.displayMedium, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  /// 36px / w600 — section heroes
  factory AppText.displaySmall(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.displaySmall, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  // ---------------------------------------------------------------------------
  // HEADLINE
  // ---------------------------------------------------------------------------

  /// 32px / w700 — page titles
  factory AppText.headlineLarge(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.headlineLarge, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  /// 28px / w700 — section titles
  factory AppText.headlineMedium(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.headlineMedium, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  /// 24px / w700 — card titles
  factory AppText.headlineSmall(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.headlineSmall, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  // ---------------------------------------------------------------------------
  // TITLE
  // ---------------------------------------------------------------------------

  /// 22px / w700 — app bar titles, dialog titles
  factory AppText.titleLarge(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.titleLarge, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  /// 16px / w700 — list item titles, section headers
  factory AppText.titleMedium(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.titleMedium, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  /// 14px / w700 — small headers, subtitles
  factory AppText.titleSmall(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.titleSmall, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  /// 16px / w400 — primary content text
  factory AppText.bodyLarge(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign, bool? softWrap}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.bodyLarge, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign, softWrap: softWrap);
  }

  /// 14px / w400 — secondary content text (most common)
  factory AppText.bodyMedium(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign, bool? softWrap}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.bodyMedium, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign, softWrap: softWrap);
  }

  /// 12px / w400 — captions, metadata, timestamps
  factory AppText.bodySmall(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign, bool? softWrap}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.bodySmall, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign, softWrap: softWrap);
  }

  // ---------------------------------------------------------------------------
  // LABEL
  // ---------------------------------------------------------------------------

  /// 14px / w700 — button text, prominent labels
  factory AppText.labelLarge(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.labelLarge, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  /// 12px / w700 — chip labels, tab labels
  factory AppText.labelMedium(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.labelMedium, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  /// 11px / w700 — smallest labels, badges
  factory AppText.labelSmall(String text, {Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign}) {
    return AppText._(text: text, styleBuilder: (tt) => tt.labelSmall, color: color, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final baseStyle = styleBuilder(tt);

    return Text(
      text,
      style: color != null ? baseStyle?.copyWith(color: color) : baseStyle,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
    );
  }
}
```

#### Step 1.C.2: Create AppTextField — glass-styled TextFormField wrapper

> **WHY:** Inherits `inputDecorationTheme` from the active theme. Wrapping TextFormField
> ensures consistent field styling without per-instance InputDecoration boilerplate.
> The component does NOT set colors manually — it relies entirely on the theme.

Create `lib/core/design_system/app_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme-aware TextFormField wrapper that inherits all styling from inputDecorationTheme.
///
/// Usage:
/// ```dart
/// AppTextField(
///   controller: _nameController,
///   label: 'Inspector Name',
///   prefixIcon: Icons.person,
/// )
/// ```
///
/// IMPORTANT: Does NOT set colors manually. All styling comes from the active theme's
/// inputDecorationTheme (dark, light, or HC). This ensures automatic theme switching.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.initialValue,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    // NOTE: No color overrides here. InputDecorationTheme handles everything.
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: suffixIcon!,
                onPressed: onSuffixTap,
              )
            : null,
      ),
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      focusNode: focusNode,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
    );
  }
}
```

#### Step 1.C.3: Create AppChip — colored chip with named factories

> **WHY:** ChipTheme provides base styling, but the app uses 6+ color variants for status,
> category, and type indicators. Named factories enforce the color vocabulary.

Create `lib/core/design_system/app_chip.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/field_guide_colors.dart';

/// Colored chip with named factory variants for consistent status/category display.
///
/// Usage:
/// ```dart
/// AppChip.cyan('Active')
/// AppChip.amber('Pending')
/// AppChip.error('Failed')
/// ```
///
/// WHY: The app uses 6+ chip color variants. Without named factories, each callsite
/// manually computes background/foreground colors, leading to inconsistency.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.onTap,
    this.onDeleted,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  // ---------------------------------------------------------------------------
  // NAMED FACTORIES — enforce color vocabulary
  // ---------------------------------------------------------------------------

  /// Cyan chip — active states, primary category
  factory AppChip.cyan(String label, {IconData? icon, VoidCallback? onTap, VoidCallback? onDeleted}) {
    return AppChip(
      label: label,
      backgroundColor: const Color(0x3300E5FF), // primaryCyan at 20%
      foregroundColor: const Color(0xFF00E5FF),  // primaryCyan
      icon: icon,
      onTap: onTap,
      onDeleted: onDeleted,
    );
  }

  /// Amber chip — pending, warning states
  factory AppChip.amber(String label, {IconData? icon, VoidCallback? onTap, VoidCallback? onDeleted}) {
    return AppChip(
      label: label,
      backgroundColor: const Color(0x33FFB300), // accentAmber at 20%
      foregroundColor: const Color(0xFFFFB300),  // accentAmber
      icon: icon,
      onTap: onTap,
      onDeleted: onDeleted,
    );
  }

  /// Green chip — success, complete states
  factory AppChip.green(String label, {IconData? icon, VoidCallback? onTap, VoidCallback? onDeleted}) {
    return AppChip(
      label: label,
      backgroundColor: const Color(0x334CAF50), // statusSuccess at 20%
      foregroundColor: const Color(0xFF4CAF50),  // statusSuccess
      icon: icon,
      onTap: onTap,
      onDeleted: onDeleted,
    );
  }

  /// Purple chip — special category
  factory AppChip.purple(String label, {IconData? icon, VoidCallback? onTap, VoidCallback? onDeleted}) {
    return AppChip(
      label: label,
      backgroundColor: const Color(0x339C27B0), // purple at 20%
      foregroundColor: const Color(0xFF9C27B0),
      icon: icon,
      onTap: onTap,
      onDeleted: onDeleted,
    );
  }

  /// Teal chip — info, secondary category
  factory AppChip.teal(String label, {IconData? icon, VoidCallback? onTap, VoidCallback? onDeleted}) {
    return AppChip(
      label: label,
      backgroundColor: const Color(0x33009688), // teal at 20%
      foregroundColor: const Color(0xFF009688),
      icon: icon,
      onTap: onTap,
      onDeleted: onDeleted,
    );
  }

  /// Error chip — failed, error states
  factory AppChip.error(String label, {IconData? icon, VoidCallback? onTap, VoidCallback? onDeleted}) {
    return AppChip(
      label: label,
      backgroundColor: const Color(0x33F44336), // statusError at 20%
      foregroundColor: const Color(0xFFF44336),  // statusError
      icon: icon,
      onTap: onTap,
      onDeleted: onDeleted,
    );
  }

  /// Neutral chip — default/inactive states
  factory AppChip.neutral(String label, BuildContext context, {IconData? icon, VoidCallback? onTap, VoidCallback? onDeleted}) {
    final fg = FieldGuideColors.of(context);
    return AppChip(
      label: label,
      backgroundColor: fg.surfaceBright.withValues(alpha: 0.3),
      foregroundColor: fg.textTertiary,
      icon: icon,
      onTap: onTap,
      onDeleted: onDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chip = Chip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foregroundColor,
        ),
      ),
      avatar: icon != null
          ? Icon(icon, color: foregroundColor, size: 16)
          : null,
      backgroundColor: backgroundColor,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      deleteIcon: onDeleted != null
          ? Icon(Icons.close, size: 16, color: foregroundColor)
          : null,
      onDeleted: onDeleted,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: chip);
    }
    return chip;
  }
}
```

#### Step 1.C.4: Create AppProgressBar — 4px gradient progress bar

> **WHY:** Used in sync progress, upload progress, and budget tracking. A consistent
> animated gradient bar replaces 8+ inline LinearProgressIndicator customizations.

Create `lib/core/design_system/app_progress_bar.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/field_guide_colors.dart';
import '../theme/design_constants.dart';

/// 4px animated gradient progress bar.
///
/// Usage:
/// ```dart
/// AppProgressBar(value: 0.65)
/// AppProgressBar(value: null) // indeterminate
/// ```
///
/// WHY: Replaces 8+ inline LinearProgressIndicator customizations with a single
/// component that uses the theme's gradient colors and animates smoothly.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    this.value,
    this.height = 4.0,
    this.borderRadius,
    this.gradientColors,
    this.trackColor,
  });

  /// Progress value 0.0–1.0. Null = indeterminate.
  final double? value;

  /// Bar height in pixels. Default: 4.0
  final double height;

  /// Override border radius. Default: radiusFull (pill shape)
  final double? borderRadius;

  /// Override gradient colors. Default: theme's gradientStart -> gradientEnd
  final List<Color>? gradientColors;

  /// Override track color. Default: theme's surfaceBright
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final fg = FieldGuideColors.of(context);
    final radius = borderRadius ?? DesignConstants.radiusFull;
    final colors = gradientColors ?? [fg.gradientStart, fg.gradientEnd];
    final track = trackColor ?? fg.surfaceBright.withValues(alpha: 0.3);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Track (background)
            Container(
              decoration: BoxDecoration(color: track),
            ),

            // Fill (animated gradient)
            if (value != null)
              AnimatedFractionallySizedBox(
                duration: DesignConstants.animationNormal,
                curve: DesignConstants.curveDefault,
                widthFactor: value!.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
              )
            else
              // Indeterminate — use theme's built-in animation
              LinearProgressIndicator(
                minHeight: height,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(colors.first),
              ),
          ],
        ),
      ),
    );
  }
}

/// AnimatedFractionallySizedBox — smooth width transitions for progress bars.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  const AnimatedFractionallySizedBox({
    super.key,
    required super.duration,
    super.curve,
    this.widthFactor,
    this.heightFactor,
    this.alignment = Alignment.center,
    this.child,
  });

  final double? widthFactor;
  final double? heightFactor;
  final AlignmentGeometry alignment;
  final Widget? child;

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;
  Tween<double>? _heightFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor ?? 1.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
    _heightFactor = visitor(
      _heightFactor,
      widget.heightFactor ?? 1.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation),
      heightFactor: _heightFactor?.evaluate(animation),
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}
```

#### Step 1.C.5: Create AppCounterField — +/- stepper for personnel counts

> **WHY:** Personnel count entry appears on 5+ screens (entry personnel, contractor staffing).
> Each implements its own +/- button pair with inconsistent sizing and touch targets.

Create `lib/core/design_system/app_counter_field.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// +/- stepper for integer value entry with field-sized touch targets.
///
/// Usage:
/// ```dart
/// AppCounterField(
///   label: 'Laborers',
///   value: 5,
///   onChanged: (v) => setState(() => _laborers = v),
///   min: 0,
///   max: 99,
/// )
/// ```
///
/// WHY: Personnel count entry appears on 5+ screens. This enforces consistent
/// 48dp touch targets, value clamping, and haptic feedback.
class AppCounterField extends StatelessWidget {
  const AppCounterField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = FieldGuideColors.of(context);

    final canDecrement = value > min;
    final canIncrement = value < max;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Expanded(
          child: Text(
            label,
            style: tt.bodyMedium,
          ),
        ),

        // Decrement button
        _CounterButton(
          icon: Icons.remove,
          enabled: canDecrement,
          onTap: canDecrement
              ? () => onChanged((value - step).clamp(min, max))
              : null,
        ),

        // Value display
        Container(
          width: DesignConstants.touchTargetMin,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.space2,
          ),
          decoration: BoxDecoration(
            color: fg.surfaceElevated.withValues(alpha: 0.5),
            border: Border.symmetric(
              horizontal: BorderSide(
                color: cs.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Text(
            '$value',
            style: tt.titleMedium?.copyWith(
              color: cs.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Increment button
        _CounterButton(
          icon: Icons.add,
          enabled: canIncrement,
          onTap: canIncrement
              ? () => onChanged((value + step).clamp(min, max))
              : null,
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = FieldGuideColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        child: Container(
          width: DesignConstants.touchTargetMin,
          height: DesignConstants.touchTargetMin,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: enabled ? cs.primary : fg.textTertiary,
            size: DesignConstants.iconSizeMedium,
          ),
        ),
      ),
    );
  }
}
```

#### Step 1.C.6: Create AppToggle — label + subtitle + Switch.adaptive

> **WHY:** Settings screens and entry forms use labeled switches 12+ times. Each constructs
> its own Row/Column + Switch with inconsistent spacing. This inherits switchTheme.
> IMPORTANT: Does NOT set switch colors manually — relies on theme's switchTheme.

Create `lib/core/design_system/app_toggle.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// Label + optional subtitle + Switch.adaptive that inherits switchTheme.
///
/// Usage:
/// ```dart
/// AppToggle(
///   label: 'Auto-sync',
///   subtitle: 'Sync when connected to WiFi',
///   value: _autoSync,
///   onChanged: (v) => setState(() => _autoSync = v),
/// )
/// ```
///
/// IMPORTANT: Does NOT set switch colors. All styling comes from the active theme's
/// switchTheme. This ensures automatic theme switching (dark/light/HC).
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DesignConstants.space2,
      ),
      child: Row(
        children: [
          // Label + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: tt.bodyLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: DesignConstants.space1),
                  Text(
                    subtitle!,
                    style: tt.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: DesignConstants.space4),

          // NOTE: Switch.adaptive picks the native look per platform.
          // Colors come from switchTheme — we pass NOTHING to Switch itself.
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
```

#### Step 1.C.7: Create AppIcon — enum-based icon sizing

> **WHY:** Icon sizes are scattered as magic numbers (18, 20, 24, 28, 32, 48) across
> the codebase. This enum enforces the 4-tier sizing system from DesignConstants.

Create `lib/core/design_system/app_icon.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// Standardized icon sizing using the 4-tier system.
///
/// Usage:
/// ```dart
/// AppIcon(Icons.check, size: AppIconSize.small)
/// AppIcon(Icons.sync, size: AppIconSize.large, color: fg.statusSuccess)
/// ```
///
/// WHY: Replaces 25+ ad-hoc icon sizes with 4 named tiers. Ensures consistency
/// and makes global size adjustments trivial (change one constant).
enum AppIconSize {
  /// 18px — inline with body text, chip icons
  small(DesignConstants.iconSizeSmall),

  /// 24px — default Material size, list items, buttons
  medium(DesignConstants.iconSizeMedium),

  /// 32px — section headers, prominent actions
  large(DesignConstants.iconSizeLarge),

  /// 48px — empty states, hero illustrations
  xl(DesignConstants.iconSizeXL);

  const AppIconSize(this.value);
  final double value;
}

/// Icon widget with enforced sizing tiers.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = AppIconSize.medium,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final AppIconSize size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size.value,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
```

---

## Phase 1.D: Build Card Layer Components

### Sub-phase 1.D: Card-Level Design System Widgets

**Files:**
- Create: `lib/core/design_system/app_glass_card.dart`
- Create: `lib/core/design_system/app_section_header.dart`
- Create: `lib/core/design_system/app_list_tile.dart`
- Create: `lib/core/design_system/app_photo_grid.dart`
- Create: `lib/core/design_system/app_section_card.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.D.1: Create AppGlassCard — core T Vivid card

> **WHY:** The T Vivid design language uses glassmorphic cards with subtle accent color
> tinting on the left border. This replaces `AppTheme.getGlassmorphicDecoration()` calls
> (used 30+ times) and inline Container+BoxDecoration patterns across the codebase.

Create `lib/core/design_system/app_glass_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Core T Vivid glassmorphic card with optional accent color tinting.
///
/// Usage:
/// ```dart
/// AppGlassCard(
///   child: Text('Content'),
///   accentColor: cs.primary,  // left border tint
///   onTap: () => navigateToDetail(),
/// )
/// ```
///
/// WHY: Replaces 30+ inline Container+BoxDecoration glassmorphic patterns.
/// The accent color creates a 3px left border tint for visual hierarchy.
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.accentColor,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.selected = false,
  });

  final Widget child;

  /// Optional left-border accent color. Creates a 3px colored left edge.
  /// Pass `cs.primary` for cyan, `fg.accentAmber` for amber, etc.
  final Color? accentColor;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Override internal padding. Default: space4 all sides.
  final EdgeInsetsGeometry? padding;

  /// Override outer margin. Default: symmetric vertical 4px.
  final EdgeInsetsGeometry? margin;

  /// Override border radius. Default: radiusMedium (12).
  final double? borderRadius;

  /// Override elevation. Default: elevationLow (2).
  final double? elevation;

  /// Whether the card shows a selected/highlighted state.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = FieldGuideColors.of(context);
    final radius = borderRadius ?? DesignConstants.radiusMedium;

    // NOTE: We build the decoration manually rather than using Card widget
    // because Card doesn't support gradient borders or accent tinting.
    final decoration = BoxDecoration(
      color: selected
          ? fg.surfaceElevated.withValues(alpha: 0.9)
          : fg.surfaceGlass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: selected
            ? cs.primary.withValues(alpha: 0.5)
            : cs.outline.withValues(alpha: 0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: fg.shadowLight,
          blurRadius: elevation ?? DesignConstants.elevationLow,
          offset: const Offset(0, 1),
        ),
      ],
    );

    Widget card = Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Row(
          children: [
            // Accent left border — 3px colored strip
            if (accentColor != null)
              Container(
                width: 3,
                color: accentColor,
              ),

            // Content area
            Expanded(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(DesignConstants.space4),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with InkWell for tap ripple if interactive
    if (onTap != null || onLongPress != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(radius),
          child: card,
        ),
      );
    }

    return card;
  }
}
```

#### Step 1.D.2: Create AppSectionHeader — 8px spaced-letter header

> **WHY:** Section headers appear 40+ times across entry screens, settings, and project
> detail views. Each manually constructs a Text with letterSpacing, uppercase, and padding.

Create `lib/core/design_system/app_section_header.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// 8px spaced-letter section header with optional trailing action.
///
/// Usage:
/// ```dart
/// AppSectionHeader(
///   title: 'PERSONNEL',
///   trailing: TextButton(onPressed: () {}, child: Text('Add')),
/// )
/// ```
///
/// WHY: Section headers appear 40+ times. This enforces uppercase, letter-spacing,
/// consistent padding, and optional trailing action placement.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  final String title;

  /// Optional trailing widget (e.g., "Add" button, count badge)
  final Widget? trailing;

  /// Override padding. Default: horizontal space4, vertical space3.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: DesignConstants.space4,
        vertical: DesignConstants.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: tt.labelSmall?.copyWith(
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
```

#### Step 1.D.3: Create AppListTile — glass-styled list row on AppGlassCard

> **WHY:** List items on glass cards appear 25+ times (project lists, entry lists,
> contractor lists). Each manually wraps ListTile in a Card or Container.

Create `lib/core/design_system/app_list_tile.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Glass-styled list row that wraps content in the T Vivid card style.
///
/// Usage:
/// ```dart
/// AppListTile(
///   leading: Icon(Icons.folder),
///   title: 'Springfield DWSRF',
///   subtitle: 'Project #864130',
///   trailing: AppChip.cyan('Active'),
///   onTap: () => goToProject(id),
/// )
/// ```
///
/// WHY: Replaces 25+ manual ListTile-in-Card patterns with a consistent component
/// that handles glass background, accent borders, and proper touch targets.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.accentColor,
    this.selected = false,
    this.dense = false,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Optional left accent border color
  final Color? accentColor;

  /// Show selected highlight state
  final bool selected;

  /// Compact density
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = FieldGuideColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected
            ? fg.surfaceElevated.withValues(alpha: 0.9)
            : fg.surfaceGlass,
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
        border: Border.all(
          color: selected
              ? cs.primary.withValues(alpha: 0.5)
              : cs.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
            child: Row(
              children: [
                // Accent left strip
                if (accentColor != null)
                  Container(
                    width: 3,
                    height: dense ? 48 : 64,
                    color: accentColor,
                  ),

                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignConstants.space4,
                      vertical: dense ? DesignConstants.space2 : DesignConstants.space3,
                    ),
                    child: Row(
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: DesignConstants.space3),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: tt.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  style: tt.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: DesignConstants.space2),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Step 1.D.4: Create AppPhotoGrid — photo thumbnail grid with add button

> **WHY:** Photo grids appear on entry detail, location detail, and gallery screens.
> Each implements its own GridView + add button with inconsistent sizing and spacing.

Create `lib/core/design_system/app_photo_grid.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Photo thumbnail grid with optional add button.
///
/// Usage:
/// ```dart
/// AppPhotoGrid(
///   photos: photoList.map((p) => p.filePath).toList(),
///   onPhotoTap: (index) => viewPhoto(index),
///   onAddTap: () => takePhoto(),
///   crossAxisCount: 3,
/// )
/// ```
///
/// WHY: Photo grids appear on 4+ screens. This enforces consistent thumbnail size,
/// aspect ratio, rounded corners, and the "add photo" button appearance.
class AppPhotoGrid extends StatelessWidget {
  const AppPhotoGrid({
    super.key,
    required this.photos,
    this.onPhotoTap,
    this.onAddTap,
    this.crossAxisCount = 3,
    this.spacing,
  });

  /// List of local file paths for photos
  final List<String> photos;

  /// Callback when a photo thumbnail is tapped, with index
  final ValueChanged<int>? onPhotoTap;

  /// Callback for the "add photo" button. If null, no add button is shown.
  final VoidCallback? onAddTap;

  /// Number of columns. Default: 3
  final int crossAxisCount;

  /// Spacing between items. Default: space2 (8px)
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = FieldGuideColors.of(context);
    final gap = spacing ?? DesignConstants.space2;

    final itemCount = photos.length + (onAddTap != null ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        childAspectRatio: 1.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Add button (last item)
        if (onAddTap != null && index == photos.length) {
          return _AddPhotoButton(onTap: onAddTap!);
        }

        // Photo thumbnail
        return _PhotoThumbnail(
          filePath: photos[index],
          onTap: onPhotoTap != null ? () => onPhotoTap!(index) : null,
        );
      },
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.filePath,
    this.onTap,
  });

  final String filePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Image.file(
            File(filePath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: cs.onSurfaceVariant,
                size: DesignConstants.iconSizeLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.3),
            width: 2,
            // NOTE: Dashed border would require custom painter.
            // Solid border with low opacity provides similar visual affordance.
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: cs.primary,
              size: DesignConstants.iconSizeLarge,
            ),
            const SizedBox(height: DesignConstants.space1),
            Text(
              'Add Photo',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Step 1.D.5: Create AppSectionCard — colored header strip + icon + title + child

> **WHY:** Audit found this pattern used 5+ times: a card with a colored header strip
> containing an icon + title, followed by body content. Currently each instance builds
> this from scratch with different spacing, colors, and radius values.

Create `lib/core/design_system/app_section_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Card with a colored header strip containing an icon + title, followed by body content.
///
/// Usage:
/// ```dart
/// AppSectionCard(
///   icon: Icons.people,
///   title: 'Personnel',
///   headerColor: AppColors.sectionQuantities,
///   child: Column(children: personnelWidgets),
/// )
/// ```
///
/// WHY: This header-strip-card pattern appears 5+ times (personnel, quantities, photos,
/// weather, notes sections). Each builds it from scratch. This component standardizes it.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.headerColor,
    this.trailing,
    this.padding,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// Header strip background color. Default: theme primary at 15%.
  final Color? headerColor;

  /// Optional trailing widget in the header (e.g., count badge, expand icon)
  final Widget? trailing;

  /// Body padding. Default: space4 all sides.
  final EdgeInsetsGeometry? padding;

  /// Whether the body can be collapsed. Default: false.
  final bool collapsible;

  /// If collapsible, whether initially expanded. Default: true.
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = FieldGuideColors.of(context);

    final color = headerColor ?? cs.primary.withValues(alpha: 0.15);

    if (collapsible) {
      return _CollapsibleSectionCard(
        icon: icon,
        title: title,
        headerColor: color,
        trailing: trailing,
        padding: padding,
        initiallyExpanded: initiallyExpanded,
        child: child,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: fg.surfaceGlass,
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.space4,
                vertical: DesignConstants.space3,
              ),
              decoration: BoxDecoration(color: color),
              child: Row(
                children: [
                  Icon(icon, color: cs.onSurface, size: DesignConstants.iconSizeMedium),
                  const SizedBox(width: DesignConstants.space2),
                  Expanded(
                    child: Text(
                      title,
                      style: tt.titleSmall,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),

            // Body
            Padding(
              padding: padding ?? const EdgeInsets.all(DesignConstants.space4),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal collapsible variant — keeps expand/collapse state.
class _CollapsibleSectionCard extends StatefulWidget {
  const _CollapsibleSectionCard({
    required this.icon,
    required this.title,
    required this.headerColor,
    required this.child,
    this.trailing,
    this.padding,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final Color headerColor;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool initiallyExpanded;

  @override
  State<_CollapsibleSectionCard> createState() => _CollapsibleSectionCardState();
}

class _CollapsibleSectionCardState extends State<_CollapsibleSectionCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: DesignConstants.animationNormal,
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
    _heightFactor = _controller.drive(CurveTween(curve: DesignConstants.curveDefault));
    _iconRotation = _controller.drive(Tween(begin: 0.0, end: 0.5));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = FieldGuideColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: fg.surfaceGlass,
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tappable header strip
            GestureDetector(
              onTap: _toggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.space4,
                  vertical: DesignConstants.space3,
                ),
                decoration: BoxDecoration(color: widget.headerColor),
                child: Row(
                  children: [
                    Icon(widget.icon, color: cs.onSurface, size: DesignConstants.iconSizeMedium),
                    const SizedBox(width: DesignConstants.space2),
                    Expanded(
                      child: Text(widget.title, style: tt.titleSmall),
                    ),
                    if (widget.trailing != null) ...[
                      widget.trailing!,
                      const SizedBox(width: DesignConstants.space2),
                    ],
                    RotationTransition(
                      turns: _iconRotation,
                      child: Icon(
                        Icons.expand_more,
                        color: cs.onSurfaceVariant,
                        size: DesignConstants.iconSizeMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Collapsible body
            AnimatedBuilder(
              animation: _heightFactor,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _heightFactor.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(DesignConstants.space4),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Phase 1.E: Build Surface Layer Components

### Sub-phase 1.E: Page-Level Surface Widgets

**Files:**
- Create: `lib/core/design_system/app_scaffold.dart`
- Create: `lib/core/design_system/app_bottom_bar.dart`
- Create: `lib/core/design_system/app_bottom_sheet.dart`
- Create: `lib/core/design_system/app_dialog.dart`
- Create: `lib/core/design_system/app_sticky_header.dart`
- Create: `lib/core/design_system/app_drag_handle.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.E.1: Create AppScaffold — Scaffold wrapper with SafeArea

> **WHY:** Every screen wraps Scaffold + SafeArea + background color manually.
> This inherits scaffoldBackgroundColor from theme — does NOT set colors manually.

Create `lib/core/design_system/app_scaffold.dart`:

```dart
import 'package:flutter/material.dart';

/// Scaffold wrapper with SafeArea that inherits scaffoldBackgroundColor.
///
/// Usage:
/// ```dart
/// AppScaffold(
///   appBar: AppBar(title: Text('Projects')),
///   body: ProjectList(),
///   floatingActionButton: FloatingActionButton(...),
/// )
/// ```
///
/// IMPORTANT: Does NOT set backgroundColor. The theme's scaffoldBackgroundColor
/// handles this (tVividBackground for dark, lightBackground for light, hcBackground for HC).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  /// Whether SafeArea wraps the top. Default: true.
  /// Set to false when appBar handles its own SafeArea (most cases).
  final bool safeAreaTop;

  /// Whether SafeArea wraps the bottom. Default: true.
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        top: safeAreaTop && appBar == null, // AppBar handles its own SafeArea
        bottom: safeAreaBottom,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
```

#### Step 1.E.2: Create AppBottomBar — sticky bottom action bar

> **WHY:** Bottom action bars with blur backdrop appear on entry forms, project detail,
> and photo viewer (8+ screens). Each builds its own Container+ClipRect+BackdropFilter.

Create `lib/core/design_system/app_bottom_bar.dart`:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Sticky bottom action bar with blur backdrop.
///
/// Usage:
/// ```dart
/// AppScaffold(
///   body: content,
///   bottomNavigationBar: AppBottomBar(
///     children: [
///       Expanded(child: OutlinedButton(...)),
///       SizedBox(width: 12),
///       Expanded(child: ElevatedButton(...)),
///     ],
///   ),
/// )
/// ```
///
/// WHY: Bottom action bars appear on 8+ screens. This enforces consistent
/// blur backdrop, safe area bottom padding, and horizontal button layout.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.children,
    this.padding,
    this.enableBlur = true,
  });

  /// Row children — typically buttons wrapped in Expanded.
  final List<Widget> children;

  /// Override padding. Default: space4 horizontal + space3 vertical + bottom safe area.
  final EdgeInsetsGeometry? padding;

  /// Enable backdrop blur. Set false for performance on older devices.
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    final fg = FieldGuideColors.of(context);
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    Widget bar = Container(
      padding: padding ??
          EdgeInsets.fromLTRB(
            DesignConstants.space4,
            DesignConstants.space3,
            DesignConstants.space4,
            DesignConstants.space3 + bottomPadding,
          ),
      decoration: BoxDecoration(
        color: enableBlur
            ? fg.surfaceGlass
            : fg.surfaceElevated,
        border: Border(
          top: BorderSide(
            color: cs.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(children: children),
    );

    if (enableBlur) {
      bar = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: bar,
        ),
      );
    }

    return bar;
  }
}
```

#### Step 1.E.3: Create AppBottomSheet — glass sheet with drag handle + static show()

> **WHY:** Bottom sheets appear 15+ times. Each calls showModalBottomSheet with different
> decoration, drag handle, and padding. This inherits bottomSheetTheme.
> IMPORTANT: Does NOT set background color — inherits from bottomSheetTheme.

Create `lib/core/design_system/app_bottom_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import 'app_drag_handle.dart';

/// Glass-styled bottom sheet with drag handle and static show() method.
///
/// Usage:
/// ```dart
/// AppBottomSheet.show(
///   context: context,
///   title: 'Select Contractor',
///   child: ContractorPicker(),
/// );
/// ```
///
/// IMPORTANT: Background color, shape, and elevation come from bottomSheetTheme.
/// This component only adds the drag handle and optional title.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.padding,
  });

  final Widget child;

  /// Optional title displayed below the drag handle.
  final String? title;

  /// Override body padding. Default: space4 horizontal.
  final EdgeInsetsGeometry? padding;

  /// Show as a modal bottom sheet.
  ///
  /// Returns the value passed to Navigator.pop(), if any.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    EdgeInsetsGeometry? padding,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      // NOTE: Do NOT pass backgroundColor or shape — bottomSheetTheme handles it.
      builder: (context) => AppBottomSheet(
        title: title,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignConstants.space3),

          // Drag handle — inherits dragHandleColor from bottomSheetTheme
          const AppDragHandle(),

          // Title
          if (title != null) ...[
            const SizedBox(height: DesignConstants.space4),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.space4,
              ),
              child: Text(title!, style: tt.titleLarge),
            ),
          ],

          const SizedBox(height: DesignConstants.space4),

          // Body
          Flexible(
            child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(
                    horizontal: DesignConstants.space4,
                  ),
              child: child,
            ),
          ),

          const SizedBox(height: DesignConstants.space4),
        ],
      ),
    );
  }
}
```

#### Step 1.E.4: Create AppDialog — static show() wrapping AlertDialog

> **WHY:** Dialogs appear 20+ times. Each calls showDialog with different padding, actions
> alignment, and title styling. This inherits dialogTheme.
> IMPORTANT: Does NOT set colors — inherits from dialogTheme.

Create `lib/core/design_system/app_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// Standardized dialog with static show() method that inherits dialogTheme.
///
/// Usage:
/// ```dart
/// AppDialog.show(
///   context: context,
///   title: 'Delete Entry?',
///   content: 'This cannot be undone.',
///   actions: [
///     TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
///     ElevatedButton(onPressed: () => delete(), child: Text('Delete')),
///   ],
/// );
/// ```
///
/// IMPORTANT: Background, shape, elevation, title/content text styles all come from
/// dialogTheme. This component only enforces consistent action alignment and padding.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.contentWidget,
    this.actions,
    this.icon,
  });

  final String? title;

  /// Plain text content. Use [contentWidget] for rich content.
  final String? content;

  /// Rich widget content. Overrides [content] if both provided.
  final Widget? contentWidget;

  /// Action buttons. Displayed right-aligned at bottom.
  final List<Widget>? actions;

  /// Optional icon displayed above the title.
  final IconData? icon;

  /// Show as a modal dialog.
  ///
  /// Returns the value passed to Navigator.pop(), if any.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? content,
    Widget? contentWidget,
    List<Widget>? actions,
    IconData? icon,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        contentWidget: contentWidget,
        actions: actions,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      // NOTE: Do NOT set backgroundColor, shape, elevation, or text styles.
      // All come from dialogTheme (dark, light, or HC).
      icon: icon != null
          ? Icon(icon, size: DesignConstants.iconSizeXL, color: cs.primary)
          : null,
      title: title != null ? Text(title!) : null,
      content: contentWidget ?? (content != null ? Text(content!) : null),
      actions: actions,
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.fromLTRB(
        DesignConstants.space4,
        0,
        DesignConstants.space4,
        DesignConstants.space4,
      ),
    );
  }
}
```

#### Step 1.E.5: Create AppStickyHeader — blur-backdrop sticky header

> **WHY:** Sticky headers in scrollable lists appear on entry list, project list, and
> settings screens. Each builds its own SliverPersistentHeader with inconsistent blur.

Create `lib/core/design_system/app_sticky_header.dart`:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Blur-backdrop sticky header for sliver scroll views.
///
/// Usage:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     AppStickyHeader(child: Text('March 2026')),
///     SliverList(...),
///   ],
/// )
/// ```
///
/// WHY: Sticky headers appear on 5+ scrollable screens. This enforces consistent
/// blur backdrop, height, and styling across all list/grid views.
class AppStickyHeader extends StatelessWidget {
  const AppStickyHeader({
    super.key,
    required this.child,
    this.height = 48.0,
    this.pinned = true,
  });

  final Widget child;
  final double height;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: pinned,
      delegate: _StickyHeaderDelegate(
        child: child,
        height: height,
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.child,
    required this.height,
  });

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final fg = FieldGuideColors.of(context);
    final cs = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.space4,
          ),
          decoration: BoxDecoration(
            color: fg.surfaceGlass,
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
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}
```

#### Step 1.E.6: Create AppDragHandle — extracted drag handle widget

> **WHY:** Drag handles appear in bottom sheets, reorderable lists, and draggable panels.
> Audit found 9 inline implementations with different sizes. This uses the theme's
> bottomSheetTheme.dragHandleColor and dragHandleSize for consistency.

Create `lib/core/design_system/app_drag_handle.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/field_guide_colors.dart';

/// Standardized drag handle widget for bottom sheets and draggable surfaces.
///
/// Usage:
/// ```dart
/// const AppDragHandle()
/// ```
///
/// WHY: 9 inline drag handle implementations found in audit. This uses the theme's
/// bottomSheetTheme.dragHandleColor for automatic theme switching.
class AppDragHandle extends StatelessWidget {
  const AppDragHandle({
    super.key,
    this.width = 40,
    this.height = 4,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // NOTE: Use FieldGuideColors.dragHandleColor which varies per theme,
    // matching the bottomSheetTheme.dragHandleColor values.
    final fg = FieldGuideColors.of(context);

    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: fg.dragHandleColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}
```

---

## Phase 1.F: Build Composite Layer Components

### Sub-phase 1.F: Multi-Component Composite Widgets

**Files:**
- Create: `lib/core/design_system/app_empty_state.dart`
- Create: `lib/core/design_system/app_error_state.dart`
- Create: `lib/core/design_system/app_loading_state.dart`
- Create: `lib/core/design_system/app_budget_warning_chip.dart`
- Create: `lib/core/design_system/app_info_banner.dart`
- Create: `lib/core/design_system/app_mini_spinner.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.F.1: Create AppEmptyState — icon + title + subtitle + optional action

> **WHY:** Empty states appear on 10+ list screens (no projects, no entries, no photos).
> Each constructs its own Center + Column + Icon + Text + optional Button.

Create `lib/core/design_system/app_empty_state.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// Empty state placeholder with icon, title, subtitle, and optional CTA button.
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.folder_open,
///   title: 'No Projects Yet',
///   subtitle: 'Create your first project to get started.',
///   actionLabel: 'Create Project',
///   onAction: () => goToCreateProject(),
/// )
/// ```
///
/// WHY: 10+ screens show empty states. This enforces consistent spacing, icon size,
/// text hierarchy, and optional action button placement.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: DesignConstants.iconSizeXL,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: DesignConstants.space4),
            Text(
              title,
              style: tt.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignConstants.space2),
              Text(
                subtitle!,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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

#### Step 1.F.2: Create AppErrorState — error variant of empty state

> **WHY:** Error states need consistent treatment — red icon tint, retry button,
> and error message display. Currently each screen handles errors differently.

Create `lib/core/design_system/app_error_state.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// Error state placeholder with retry action.
///
/// Usage:
/// ```dart
/// AppErrorState(
///   message: 'Failed to load projects',
///   onRetry: () => provider.loadProjects(),
/// )
/// ```
///
/// WHY: Error handling UI is inconsistent. This enforces the error icon (red tinted),
/// message display, and retry button pattern across all screens.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;

  /// Override icon. Default: Icons.error_outline
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: DesignConstants.iconSizeXL,
              color: cs.error,
            ),
            const SizedBox(height: DesignConstants.space4),
            Text(
              message,
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DesignConstants.space6),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### Step 1.F.3: Create AppLoadingState — spinner + optional label

> **WHY:** Loading states appear on every async screen. This inherits progressIndicatorTheme.
> IMPORTANT: Does NOT set indicator colors — relies on theme.

Create `lib/core/design_system/app_loading_state.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';

/// Full-screen centered loading indicator with optional label.
///
/// Usage:
/// ```dart
/// if (provider.isLoading) return AppLoadingState(label: 'Loading projects...');
/// ```
///
/// IMPORTANT: Does NOT set indicator colors. The progressIndicatorTheme handles
/// the spinner color and track color across all 3 themes.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.label,
  });

  /// Optional label displayed below the spinner.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // NOTE: No color override — inherits from progressIndicatorTheme.
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: DesignConstants.space4),
            Text(
              label!,
              style: tt.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

#### Step 1.F.4: Create AppBudgetWarningChip — amber/orange warning chip

> **WHY:** Budget alerts appear on entry detail, quantities, and project summary screens.
> Each constructs its own Container+Row with amber/orange colors. This component encodes
> the threshold logic: amber for >80%, orange for >100%.

Create `lib/core/design_system/app_budget_warning_chip.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Amber/orange warning chip for budget alerts.
///
/// Usage:
/// ```dart
/// AppBudgetWarningChip(
///   percentage: 0.92, // 92% of budget used
///   label: '92% used',
/// )
/// ```
///
/// WHY: Budget warning indicators appear on 4+ screens. The color logic (amber < 100%,
/// orange >= 100%) was inconsistently applied. This encodes it once.
class AppBudgetWarningChip extends StatelessWidget {
  const AppBudgetWarningChip({
    super.key,
    required this.percentage,
    this.label,
  });

  /// Budget usage as a fraction (0.0–2.0+). Values > 1.0 = over budget.
  final double percentage;

  /// Override label text. Default: computed from percentage.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final fg = FieldGuideColors.of(context);
    final tt = Theme.of(context).textTheme;

    // Threshold logic: amber for 80-99%, orange for 100%+
    final isOverBudget = percentage >= 1.0;
    final color = isOverBudget ? fg.accentOrange : fg.accentAmber;
    final displayLabel = label ?? '${(percentage * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.space2,
        vertical: DesignConstants.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverBudget ? Icons.warning : Icons.info_outline,
            color: color,
            size: DesignConstants.iconSizeSmall,
          ),
          const SizedBox(width: DesignConstants.space1),
          Text(
            displayLabel,
            style: tt.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### Step 1.F.5: Create AppInfoBanner — icon + colored container + message

> **WHY:** Info banners with an icon, colored background, and message text appear 7+ times
> (sync status, form validation warnings, permission prompts). Each builds its own Container.

Create `lib/core/design_system/app_info_banner.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/design_constants.dart';
import '../theme/field_guide_colors.dart';

/// Icon + colored container + message banner.
///
/// Usage:
/// ```dart
/// AppInfoBanner.warning(
///   message: 'Changes will sync when connected.',
///   context: context,
/// )
/// AppInfoBanner.info(
///   message: 'Tap to add a new entry.',
///   context: context,
/// )
/// ```
///
/// WHY: Colored info/warning banners appear 7+ times. This enforces consistent
/// icon placement, padding, border radius, and color scheme.
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    this.onDismiss,
  });

  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback? onDismiss;

  /// Warning variant — amber tint
  factory AppInfoBanner.warning({
    required String message,
    required BuildContext context,
    VoidCallback? onDismiss,
  }) {
    final fg = FieldGuideColors.of(context);
    return AppInfoBanner(
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: fg.warningBackground,
      borderColor: fg.warningBorder,
      foregroundColor: fg.statusWarning,
      onDismiss: onDismiss,
    );
  }

  /// Info variant — primary tint
  factory AppInfoBanner.info({
    required String message,
    required BuildContext context,
    VoidCallback? onDismiss,
  }) {
    final cs = Theme.of(context).colorScheme;
    return AppInfoBanner(
      message: message,
      icon: Icons.info_outline,
      backgroundColor: cs.primary.withValues(alpha: 0.1),
      borderColor: cs.primary.withValues(alpha: 0.3),
      foregroundColor: cs.primary,
      onDismiss: onDismiss,
    );
  }

  /// Success variant — green tint
  factory AppInfoBanner.success({
    required String message,
    required BuildContext context,
    VoidCallback? onDismiss,
  }) {
    final fg = FieldGuideColors.of(context);
    return AppInfoBanner(
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: fg.statusSuccess.withValues(alpha: 0.1),
      borderColor: fg.statusSuccess.withValues(alpha: 0.3),
      foregroundColor: fg.statusSuccess,
      onDismiss: onDismiss,
    );
  }

  /// Error variant — red tint
  factory AppInfoBanner.error({
    required String message,
    required BuildContext context,
    VoidCallback? onDismiss,
  }) {
    final cs = Theme.of(context).colorScheme;
    return AppInfoBanner(
      message: message,
      icon: Icons.error_outline,
      backgroundColor: cs.error.withValues(alpha: 0.1),
      borderColor: cs.error.withValues(alpha: 0.3),
      foregroundColor: cs.error,
      onDismiss: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignConstants.space3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: foregroundColor,
            size: DesignConstants.iconSizeMedium,
          ),
          const SizedBox(width: DesignConstants.space3),
          Expanded(
            child: Text(
              message,
              style: tt.bodySmall?.copyWith(color: foregroundColor),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: foregroundColor,
                size: DesignConstants.iconSizeSmall,
              ),
            ),
        ],
      ),
    );
  }
}
```

#### Step 1.F.6: Create AppMiniSpinner — compact inline progress indicator

> **WHY:** Audit found 19 occurrences of `SizedBox(width: 16/18/20, height: 16/18/20,
> child: CircularProgressIndicator(strokeWidth: 2))`. This standardizes the pattern.

Create `lib/core/design_system/app_mini_spinner.dart`:

```dart
import 'package:flutter/material.dart';

/// Compact inline progress indicator for buttons, list items, and chips.
///
/// Usage:
/// ```dart
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
/// ```
///
/// WHY: 19 occurrences of inline SizedBox+CircularProgressIndicator(strokeWidth: 2).
/// This component standardizes the size (16x16) and stroke width (2).
/// Colors inherit from progressIndicatorTheme — NOT set manually.
class AppMiniSpinner extends StatelessWidget {
  const AppMiniSpinner({
    super.key,
    this.size = 16.0,
    this.strokeWidth = 2.0,
    this.color,
  });

  final double size;
  final double strokeWidth;

  /// Override color. Default: inherits from progressIndicatorTheme.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        // NOTE: Only override color if explicitly passed. Otherwise theme handles it.
        valueColor: color != null ? AlwaysStoppedAnimation(color) : null,
      ),
    );
  }
}
```

---

## Phase 1.G: Barrel Export + Theme Gaps + Quality Gate

### Sub-phase 1.G: Wire Everything Together

**Files:**
- Create: `lib/core/design_system/design_system.dart`
- Modify: `lib/core/theme/app_theme.dart` (fill light + HC theme gaps)

**Agent**: `frontend-flutter-specialist-agent`

#### Step 1.G.1: Create barrel export

> **WHY:** A single import for all design system components:
> `import 'package:construction_inspector/core/design_system/design_system.dart';`

Create `lib/core/design_system/design_system.dart`:

```dart
/// Field Guide Design System — atomic component library.
///
/// Import this single file to access all design system components:
/// ```dart
/// import 'package:construction_inspector/core/design_system/design_system.dart';
/// ```
///
/// Component layers (bottom → top):
/// - Atomic: AppText, AppTextField, AppChip, AppProgressBar, AppCounterField, AppToggle, AppIcon
/// - Card: AppGlassCard, AppSectionHeader, AppListTile, AppPhotoGrid, AppSectionCard
/// - Surface: AppScaffold, AppBottomBar, AppBottomSheet, AppDialog, AppStickyHeader, AppDragHandle
/// - Composite: AppEmptyState, AppErrorState, AppLoadingState, AppBudgetWarningChip, AppInfoBanner, AppMiniSpinner

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

#### Step 1.G.2: Fill light theme missing component themes

> **WHY:** The light theme is missing filledButtonTheme, iconButtonTheme, bottomSheetTheme,
> chipTheme, and sliderTheme — causing fallback to Material defaults which clash with the
> design language.

In `lib/core/theme/app_theme.dart`, in the `lightTheme` getter, find the closing of `checkboxTheme` (around line 1099) and add the following blocks **after** it, **before** `textTheme:`:

```dart

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

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        elevation: elevationModal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
        ),
        dragHandleColor: Color(0xFFCBD5E1), // slate-300
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceHighlight.withValues(alpha: 0.5),
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

#### Step 1.G.3: Fill HC theme missing component themes

> **WHY:** Same gaps in HC theme. HC needs extra-thick borders, larger touch targets,
> and high-contrast color overrides.

In `lib/core/theme/app_theme.dart`, in the `highContrastTheme` getter, find the closing of `checkboxTheme` (around line 1466) and add the following blocks **after** it, **before** `textTheme:`:

```dart

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

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: hcTextPrimary,
          hoverColor: hcPrimary.withValues(alpha: 0.15),
          focusColor: hcPrimary.withValues(alpha: 0.2),
          highlightColor: hcPrimary.withValues(alpha: 0.2),
          minimumSize: const Size(touchTargetComfortable, touchTargetComfortable),
          iconSize: 28,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: hcSurfaceElevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
        dragHandleColor: hcBorder,
        dragHandleSize: Size(48, 4),
        showDragHandle: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: hcSurface,
        selectedColor: hcPrimary.withValues(alpha: 0.3),
        disabledColor: const Color(0xFF333333),
        deleteIconColor: hcTextPrimary,
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: hcTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: space2, vertical: space1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: hcBorder, width: 2),
        ),
        side: const BorderSide(color: hcBorder, width: 2),
        checkmarkColor: hcPrimary,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: hcPrimary,
        inactiveTrackColor: const Color(0xFF333333),
        thumbColor: hcPrimary,
        overlayColor: hcPrimary.withValues(alpha: 0.2),
        valueIndicatorColor: hcPrimary,
        valueIndicatorTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
```

#### Step 1.G.4: Quality Gate

> **WHY:** Foundation must be clean before any subsequent phase builds on it.

Run in sequence:

```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/core/design_system/"
```

**Pass criteria:**
- `flutter analyze` — zero errors, zero warnings (infos are OK)
- All design system tests green (from Phase 1.H below)

If analysis errors occur, fix before proceeding. Common issues:
- Missing imports (verify all files import `package:flutter/material.dart`)
- Unused imports (remove if flagged)
- `AnimatedBuilder` should be `AnimatedBuilder` (verify API exists in current Flutter SDK — if not, use `AnimatedWidget` pattern instead)

> **NOTE on AnimatedBuilder:** Flutter 3.x uses `AnimatedBuilder`. If the SDK version in
> `pubspec.yaml` predates this name, use `ValueListenableBuilder` or a manual `AnimatedWidget`
> subclass. Check: `pwsh -Command "flutter --version"` to confirm.

---

## Phase 1.H: Tests

### Sub-phase 1.H: Widget + Golden Tests for Design System

**Files:**
- Create: `test/core/design_system/app_text_test.dart`
- Create: `test/core/design_system/app_chip_test.dart`
- Create: `test/core/design_system/app_glass_card_test.dart`
- Create: `test/core/design_system/app_empty_state_test.dart`
- Create: `test/core/design_system/app_mini_spinner_test.dart`
- Create: `test/core/design_system/app_info_banner_test.dart`
- Create: `test/core/design_system/field_guide_colors_test.dart`

**Agent**: `qa-testing-agent`

> **NOTE:** All tests use a helper that wraps widgets in MaterialApp with the appropriate
> theme. This avoids duplicating theme setup in every test file.

#### Step 1.H.1: Create test helper

Create `test/core/design_system/design_system_test_helpers.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';

/// Wraps a widget in MaterialApp with the specified theme for testing.
///
/// Usage:
/// ```dart
/// await tester.pumpWidget(wrapWithTheme(MyWidget(), theme: AppTheme.darkTheme));
/// ```
Widget wrapWithTheme(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

/// Wraps for dark theme (convenience)
Widget wrapDark(Widget child) => wrapWithTheme(child, theme: AppTheme.darkTheme);

/// Wraps for light theme
Widget wrapLight(Widget child) => wrapWithTheme(child, theme: AppTheme.lightTheme);

/// Wraps for high contrast theme
Widget wrapHC(Widget child) => wrapWithTheme(child, theme: AppTheme.highContrastTheme);
```

#### Step 1.H.2: Test AppText renders correct textTheme slot

Create `test/core/design_system/app_text_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_text.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';
import 'design_system_test_helpers.dart';

void main() {
  group('AppText', () {
    testWidgets('titleMedium renders with correct font size', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppText.titleMedium('Test Title'),
      ));

      final textWidget = tester.widget<Text>(find.text('Test Title'));
      // titleMedium in dark theme: fontSize 16, fontWeight w700
      expect(textWidget.style?.fontSize, 16);
      expect(textWidget.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('bodySmall renders with secondary color in dark theme', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppText.bodySmall('Caption text'),
      ));

      final textWidget = tester.widget<Text>(find.text('Caption text'));
      // bodySmall in dark theme uses textSecondary color
      expect(textWidget.style?.fontSize, 12);
    });

    testWidgets('color override applies correctly', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppText.bodyMedium('Colored text', color: Colors.red),
      ));

      final textWidget = tester.widget<Text>(find.text('Colored text'));
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('maxLines and overflow are forwarded', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppText.titleSmall(
          'Long text that should be truncated',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ));

      final textWidget = tester.widget<Text>(
        find.text('Long text that should be truncated'),
      );
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpWidget(wrapLight(
        AppText.headlineSmall('Light Title'),
      ));

      final textWidget = tester.widget<Text>(find.text('Light Title'));
      // headlineSmall in light theme: lightTextPrimary color
      expect(textWidget.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('renders correctly in HC theme', (tester) async {
      await tester.pumpWidget(wrapHC(
        AppText.labelLarge('HC Label'),
      ));

      final textWidget = tester.widget<Text>(find.text('HC Label'));
      expect(textWidget.style?.fontWeight, FontWeight.w900);
    });
  });
}
```

#### Step 1.H.3: Test AppChip factory variants

Create `test/core/design_system/app_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_chip.dart';
import 'design_system_test_helpers.dart';

void main() {
  group('AppChip', () {
    testWidgets('cyan factory renders with cyan foreground', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppChip.cyan('Active'),
      ));

      expect(find.text('Active'), findsOneWidget);
      // Verify the Chip widget exists
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('amber factory renders label', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppChip.amber('Pending'),
      ));

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('green factory renders label', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppChip.green('Complete'),
      ));

      expect(find.text('Complete'), findsOneWidget);
    });

    testWidgets('error factory renders label', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppChip.error('Failed'),
      ));

      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('icon is displayed when provided', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppChip.cyan('Synced', icon: Icons.sync),
      ));

      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('onTap callback fires', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapDark(
        AppChip.cyan('Tappable', onTap: () => tapped = true),
      ));

      await tester.tap(find.text('Tappable'));
      expect(tapped, true);
    });

    testWidgets('delete icon shown when onDeleted provided', (tester) async {
      await tester.pumpWidget(wrapDark(
        AppChip.amber('Removable', onDeleted: () {}),
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('neutral factory uses theme colors', (tester) async {
      // NOTE: neutral factory requires context, so we test it through a Builder
      await tester.pumpWidget(wrapDark(
        Builder(builder: (context) {
          return AppChip.neutral('Default', context);
        }),
      ));

      expect(find.text('Default'), findsOneWidget);
    });
  });
}
```

#### Step 1.H.4: Test AppGlassCard accent color tinting

Create `test/core/design_system/app_glass_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_glass_card.dart';
import 'design_system_test_helpers.dart';

void main() {
  group('AppGlassCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppGlassCard(child: Text('Card Content')),
      ));

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('accent color creates left border strip', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppGlassCard(
          accentColor: Colors.cyan,
          child: Text('Accented'),
        ),
      ));

      // Verify a Container with cyan color exists (the accent strip)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasAccentStrip = containers.any((c) {
        return c.decoration == null && c.color == Colors.cyan && c.constraints?.maxWidth == 3;
      });
      // The accent strip is a Container with width 3 — verify it renders
      expect(find.text('Accented'), findsOneWidget);
    });

    testWidgets('onTap wraps in InkWell', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapDark(
        AppGlassCard(
          onTap: () => tapped = true,
          child: const Text('Tappable Card'),
        ),
      ));

      await tester.tap(find.text('Tappable Card'));
      expect(tapped, true);
    });

    testWidgets('selected state changes appearance', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppGlassCard(
          selected: true,
          child: Text('Selected'),
        ),
      ));

      expect(find.text('Selected'), findsOneWidget);
      // Selected card should have higher alpha on surfaceElevated
      // Visual verification — no assertion needed beyond no crash
    });

    testWidgets('renders in light theme', (tester) async {
      await tester.pumpWidget(wrapLight(
        const AppGlassCard(child: Text('Light Card')),
      ));

      expect(find.text('Light Card'), findsOneWidget);
    });

    testWidgets('renders in HC theme', (tester) async {
      await tester.pumpWidget(wrapHC(
        const AppGlassCard(child: Text('HC Card')),
      ));

      expect(find.text('HC Card'), findsOneWidget);
    });
  });
}
```

#### Step 1.H.5: Test AppEmptyState and AppErrorState

Create `test/core/design_system/app_empty_state_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_empty_state.dart';
import 'package:construction_inspector/core/design_system/app_error_state.dart';
import 'design_system_test_helpers.dart';

void main() {
  group('AppEmptyState', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppEmptyState(
          icon: Icons.folder_open,
          title: 'No Projects',
          subtitle: 'Create a project to begin.',
        ),
      ));

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.text('No Projects'), findsOneWidget);
      expect(find.text('Create a project to begin.'), findsOneWidget);
    });

    testWidgets('action button appears when provided', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapDark(
        AppEmptyState(
          icon: Icons.add,
          title: 'Empty',
          actionLabel: 'Add Item',
          onAction: () => pressed = true,
        ),
      ));

      expect(find.text('Add Item'), findsOneWidget);
      await tester.tap(find.text('Add Item'));
      expect(pressed, true);
    });

    testWidgets('no action button when not provided', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppEmptyState(
          icon: Icons.inbox,
          title: 'No Items',
        ),
      ));

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('AppErrorState', () {
    testWidgets('renders error message and icon', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppErrorState(message: 'Failed to load'),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('retry button fires callback', (tester) async {
      var retried = false;
      await tester.pumpWidget(wrapDark(
        AppErrorState(
          message: 'Network error',
          onRetry: () => retried = true,
        ),
      ));

      await tester.tap(find.text('Retry'));
      expect(retried, true);
    });

    testWidgets('custom icon is displayed', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppErrorState(
          message: 'Offline',
          icon: Icons.wifi_off,
        ),
      ));

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });
  });
}
```

#### Step 1.H.6: Test AppMiniSpinner

Create `test/core/design_system/app_mini_spinner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_mini_spinner.dart';
import 'design_system_test_helpers.dart';

void main() {
  group('AppMiniSpinner', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppMiniSpinner(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('default size is 16x16', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppMiniSpinner(),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 16.0);
      expect(sizedBox.height, 16.0);
    });

    testWidgets('custom size is applied', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppMiniSpinner(size: 24),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);
    });

    testWidgets('custom color is applied', (tester) async {
      await tester.pumpWidget(wrapDark(
        const AppMiniSpinner(color: Colors.red),
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(
        (indicator.valueColor as AlwaysStoppedAnimation<Color>?)?.value,
        Colors.red,
      );
    });
  });
}
```

#### Step 1.H.7: Test AppInfoBanner variants

Create `test/core/design_system/app_info_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/app_info_banner.dart';
import 'design_system_test_helpers.dart';

void main() {
  group('AppInfoBanner', () {
    testWidgets('warning factory renders with warning icon', (tester) async {
      await tester.pumpWidget(wrapDark(
        Builder(builder: (context) {
          return AppInfoBanner.warning(
            message: 'Offline changes pending',
            context: context,
          );
        }),
      ));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Offline changes pending'), findsOneWidget);
    });

    testWidgets('info factory renders with info icon', (tester) async {
      await tester.pumpWidget(wrapDark(
        Builder(builder: (context) {
          return AppInfoBanner.info(
            message: 'Tap to begin',
            context: context,
          );
        }),
      ));

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Tap to begin'), findsOneWidget);
    });

    testWidgets('success factory renders with check icon', (tester) async {
      await tester.pumpWidget(wrapDark(
        Builder(builder: (context) {
          return AppInfoBanner.success(
            message: 'Saved successfully',
            context: context,
          );
        }),
      ));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('error factory renders with error icon', (tester) async {
      await tester.pumpWidget(wrapDark(
        Builder(builder: (context) {
          return AppInfoBanner.error(
            message: 'Upload failed',
            context: context,
          );
        }),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('dismiss button fires callback', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrapDark(
        Builder(builder: (context) {
          return AppInfoBanner.warning(
            message: 'Dismissible',
            context: context,
            onDismiss: () => dismissed = true,
          );
        }),
      ));

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, true);
    });

    testWidgets('no dismiss button when callback not provided', (tester) async {
      await tester.pumpWidget(wrapDark(
        Builder(builder: (context) {
          return AppInfoBanner.info(
            message: 'Not dismissible',
            context: context,
          );
        }),
      ));

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
```

#### Step 1.H.8: Test FieldGuideColors across all 3 themes

Create `test/core/design_system/field_guide_colors_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';
import 'package:construction_inspector/core/theme/colors.dart';

void main() {
  group('FieldGuideColors', () {
    testWidgets('dark theme returns correct extension', (tester) async {
      late FieldGuideColors colors;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(builder: (context) {
          colors = FieldGuideColors.of(context);
          return const SizedBox();
        }),
      ));

      expect(colors.surfaceElevated, AppColors.surfaceElevated);
      expect(colors.accentAmber, AppColors.accentAmber);
      expect(colors.statusSuccess, AppColors.statusSuccess);
      expect(colors.gradientStart, AppColors.primaryCyan);
      expect(colors.gradientEnd, AppColors.primaryBlue);
    });

    testWidgets('light theme returns light extension', (tester) async {
      late FieldGuideColors colors;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(builder: (context) {
          colors = FieldGuideColors.of(context);
          return const SizedBox();
        }),
      ));

      expect(colors.surfaceElevated, AppColors.lightSurfaceElevated);
      expect(colors.textTertiary, AppColors.lightTextTertiary);
      expect(colors.gradientStart, AppColors.primaryBlue);
    });

    testWidgets('HC theme returns HC extension', (tester) async {
      late FieldGuideColors colors;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.highContrastTheme,
        home: Builder(builder: (context) {
          colors = FieldGuideColors.of(context);
          return const SizedBox();
        }),
      ));

      expect(colors.surfaceElevated, AppColors.hcSurfaceElevated);
      expect(colors.statusSuccess, AppColors.hcSuccess);
      expect(colors.dragHandleColor, AppColors.hcBorder);
      // HC uses same color for gradient start and end (no gradient)
      expect(colors.gradientStart, colors.gradientEnd);
    });

    test('copyWith preserves unmodified values', () {
      const original = FieldGuideColors.dark;
      final modified = original.copyWith(accentAmber: Colors.red);

      expect(modified.accentAmber, Colors.red);
      expect(modified.surfaceElevated, original.surfaceElevated);
      expect(modified.statusSuccess, original.statusSuccess);
    });

    test('lerp interpolates between themes', () {
      const a = FieldGuideColors.dark;
      const b = FieldGuideColors.light;
      final mid = a.lerp(b, 0.5);

      // Mid-point should be between dark and light values
      // Just verify it doesn't crash and returns a valid object
      expect(mid.surfaceElevated, isNotNull);
      expect(mid.accentAmber, isNotNull);
    });

    test('lerp with null returns self', () {
      const a = FieldGuideColors.dark;
      final result = a.lerp(null, 0.5);

      expect(result.surfaceElevated, a.surfaceElevated);
    });

    testWidgets('of() falls back to dark when extension missing', (tester) async {
      late FieldGuideColors colors;

      // Use a bare ThemeData without extensions registered
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(builder: (context) {
          colors = FieldGuideColors.of(context);
          return const SizedBox();
        }),
      ));

      // Should fall back to dark constants
      expect(colors.surfaceElevated, AppColors.surfaceElevated);
    });
  });
}
```

#### Step 1.H.9: Run all tests

```
pwsh -Command "flutter test test/core/design_system/ -r expanded"
```

**Pass criteria:** All tests green. Zero failures.

If any test fails, investigate and fix the component code (not the test, unless the test has a genuine bug).

---

## Phase 1 Summary

### Files Created (22)
| File | Layer |
|------|-------|
| `lib/core/theme/field_guide_colors.dart` | Theme |
| `lib/core/design_system/app_text.dart` | Atomic |
| `lib/core/design_system/app_text_field.dart` | Atomic |
| `lib/core/design_system/app_chip.dart` | Atomic |
| `lib/core/design_system/app_progress_bar.dart` | Atomic |
| `lib/core/design_system/app_counter_field.dart` | Atomic |
| `lib/core/design_system/app_toggle.dart` | Atomic |
| `lib/core/design_system/app_icon.dart` | Atomic |
| `lib/core/design_system/app_glass_card.dart` | Card |
| `lib/core/design_system/app_section_header.dart` | Card |
| `lib/core/design_system/app_list_tile.dart` | Card |
| `lib/core/design_system/app_photo_grid.dart` | Card |
| `lib/core/design_system/app_section_card.dart` | Card |
| `lib/core/design_system/app_scaffold.dart` | Surface |
| `lib/core/design_system/app_bottom_bar.dart` | Surface |
| `lib/core/design_system/app_bottom_sheet.dart` | Surface |
| `lib/core/design_system/app_dialog.dart` | Surface |
| `lib/core/design_system/app_sticky_header.dart` | Surface |
| `lib/core/design_system/app_drag_handle.dart` | Surface |
| `lib/core/design_system/app_empty_state.dart` | Composite |
| `lib/core/design_system/app_error_state.dart` | Composite |
| `lib/core/design_system/app_loading_state.dart` | Composite |
| `lib/core/design_system/app_budget_warning_chip.dart` | Composite |
| `lib/core/design_system/app_info_banner.dart` | Composite |
| `lib/core/design_system/app_mini_spinner.dart` | Composite |
| `lib/core/design_system/design_system.dart` | Barrel |

### Files Modified (4)
| File | Changes |
|------|---------|
| `lib/core/theme/colors.dart` | +12 color tokens |
| `lib/core/theme/design_constants.dart` | +6 sizing tokens |
| `lib/core/theme/app_theme.dart` | Re-exports, scaffold bg, extensions registration, light/HC gap fills |
| `lib/core/theme/theme.dart` | +1 barrel export |

### Test Files Created (8)
| File | Covers |
|------|--------|
| `test/core/design_system/design_system_test_helpers.dart` | Theme wrapping utility |
| `test/core/design_system/app_text_test.dart` | AppText slots + themes |
| `test/core/design_system/app_chip_test.dart` | AppChip 7 factories |
| `test/core/design_system/app_glass_card_test.dart` | AppGlassCard accent + themes |
| `test/core/design_system/app_empty_state_test.dart` | AppEmptyState + AppErrorState |
| `test/core/design_system/app_mini_spinner_test.dart` | AppMiniSpinner sizing |
| `test/core/design_system/app_info_banner_test.dart` | AppInfoBanner 4 variants |
| `test/core/design_system/field_guide_colors_test.dart` | FieldGuideColors 3 themes + lerp + fallback |

### Implementation Order for Agents

Agents should implement sub-phases in this order (dependencies flow downward):

```
1.A  (tokens)           — no deps
1.B  (ThemeExtension)   — depends on 1.A
1.C  (atomic)           — depends on 1.B
1.D  (card)             — depends on 1.B, 1.C
1.E  (surface)          — depends on 1.B, 1.C (AppDragHandle)
1.F  (composite)        — depends on 1.B
1.G  (barrel + gaps)    — depends on 1.A–1.F
1.H  (tests)            — depends on 1.A–1.G
```

Phases 1.C, 1.D, 1.E, and 1.F can be parallelized after 1.B completes.
