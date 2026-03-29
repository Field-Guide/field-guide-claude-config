# Phase 1 (Part B): Atomic Layer + Card Layer Components

> **Depends on:** Phase 1.A (theme tokens) + Phase 1.B (FieldGuideColors) must be complete
> **Blocks:** Phase 1.E (Surface Layer), Phase 2+ (screen migrations)
> **Estimated steps:** 12 discrete steps (7 atomic + 5 card)
> **Quality gate:** `pwsh -Command "flutter analyze"` clean on all new files

---

## Phase 1.C: Build Atomic Layer Components

### Sub-phase 1.C: Atomic Design System Widgets

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
>
> **NOTE:** No `context` parameter on factories — the build method resolves the theme.
> This keeps callsites clean: `AppText.bodyMedium('hello')` instead of passing context twice.

Create `lib/core/design_system/app_text.dart`:

```dart
import 'package:flutter/material.dart';

/// Enforces textTheme slot usage instead of inline TextStyle constructors.
///
/// Usage:
/// ```dart
/// AppText.titleMedium('Section Header')
/// AppText.bodyMedium('Content text', color: fg.textTertiary)
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

---

#### Step 1.C.2: Create AppTextField — glass-styled TextFormField wrapper

> **WHY:** Inherits `inputDecorationTheme` from the active theme. Wrapping TextFormField
> ensures consistent field styling without per-instance InputDecoration boilerplate.
> The component does NOT set colors manually — it relies entirely on the theme.
>
> **NOTE:** `suffixIcon` is a Widget (not IconData) because some fields need animated
> visibility toggles, loading spinners, or clear buttons as suffix actions.

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

---

#### Step 1.C.3: Create AppChip — colored chip with named factories

> **WHY:** ChipTheme provides base styling, but the app uses 6+ color variants for status,
> category, and type indicators. Named factories enforce the color vocabulary.
>
> **NOTE:** Most factories use hardcoded const colors for performance (no context needed).
> Only `.neutral()` requires context because it reads FieldGuideColors for theme-aware
> surface/text colors. This keeps 6 of 7 factories zero-cost const-constructible.

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

  /// Purple chip — special category (e.g., sectionPhotos)
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

  /// Teal chip — info, secondary category (e.g., sectionQuantities)
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

  /// Neutral chip — default/inactive states (requires context for theme colors)
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

---

#### Step 1.C.4: Create AppProgressBar — 4px animated gradient progress bar

> **WHY:** Used in sync progress, upload progress, and budget tracking. A consistent
> animated gradient bar replaces 8+ inline LinearProgressIndicator customizations.
>
> **NOTE:** Includes a custom `AnimatedFractionallySizedBox` because Flutter has no
> built-in implicit animation for FractionallySizedBox.widthFactor. This avoids
> requiring an explicit AnimationController at every callsite.

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
///
/// NOTE: Flutter does not provide an implicit animation for FractionallySizedBox.
/// This is a minimal ImplicitlyAnimatedWidget that tweens widthFactor/heightFactor
/// so callsites don't need explicit AnimationControllers.
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

---

#### Step 1.C.5: Create AppCounterField — +/- stepper for personnel counts

> **WHY:** Personnel count entry appears on 5+ screens (entry personnel, contractor staffing).
> Each implements its own +/- button pair with inconsistent sizing and touch targets.
>
> **NOTE:** Uses `DesignConstants.touchTargetMin` (48dp) for button sizing to meet
> Material accessibility guidelines. Value is clamped to [min, max] on every change.

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

---

#### Step 1.C.6: Create AppToggle — label + subtitle + Switch.adaptive

> **WHY:** Settings screens and entry forms use labeled switches 12+ times. Each constructs
> its own Row/Column + Switch with inconsistent spacing. This inherits switchTheme.
>
> **IMPORTANT:** Does NOT set switch colors manually — relies on theme's switchTheme.
> Switch.adaptive picks the native look per platform (Cupertino on iOS, Material on Android).

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

---

#### Step 1.C.7: Create AppIcon — enum-based icon sizing

> **WHY:** Icon sizes are scattered as magic numbers (18, 20, 24, 28, 32, 48) across
> the codebase. This enum enforces the 4-tier sizing system from DesignConstants.
>
> **NOTE:** The enum stores the pixel value directly, so `AppIconSize.small.value` == 18.0.
> Color is optional — defaults to IconTheme.of(context) when null, which inherits from
> the active theme's iconTheme (dark/light/HC).

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

#### Step 1.D.1: Create AppGlassCard — core T Vivid glassmorphic card

> **WHY:** The T Vivid design language uses glassmorphic cards with subtle accent color
> tinting on the left border. This replaces `AppTheme.getGlassmorphicDecoration()` calls
> (used 30+ times) and inline Container+BoxDecoration patterns across the codebase.
>
> **NOTE:** We build the decoration manually rather than using Flutter's Card widget
> because Card doesn't support accent left-border tinting or gradient borders.
> The accent strip is a 3px colored Container on the left edge via Row.

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

---

#### Step 1.D.2: Create AppSectionHeader — 8px spaced-letter header

> **WHY:** Section headers appear 40+ times across entry screens, settings, and project
> detail views. Each manually constructs a Text with letterSpacing, uppercase, and padding.
>
> **NOTE:** `title.toUpperCase()` is applied inside the build method so callers don't need
> to remember to uppercase. letterSpacing 1.2 follows the M3 overline pattern.

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

---

#### Step 1.D.3: Create AppListTile — glass-styled list row

> **WHY:** List items on glass cards appear 25+ times (project lists, entry lists,
> contractor lists). Each manually wraps ListTile in a Card or Container.
>
> **NOTE:** Does NOT compose AppGlassCard internally — builds its own decoration
> to avoid double-margin/padding issues. The decoration mirrors AppGlassCard but
> with list-specific tweaks (thinner margin, fixed accent strip height).

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

---

#### Step 1.D.4: Create AppPhotoGrid — photo thumbnail grid with add button

> **WHY:** Photo grids appear on entry detail, location detail, and gallery screens.
> Each implements its own GridView + add button with inconsistent sizing and spacing.
>
> **NOTE:** Uses `Image.file` with `errorBuilder` to gracefully handle missing/corrupt
> photos (common when files haven't synced yet). `NeverScrollableScrollPhysics` + `shrinkWrap`
> allows the grid to live inside a scrollable parent without nested scroll issues.

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

---

#### Step 1.D.5: Create AppSectionCard — colored header strip + icon + title + child

> **WHY:** Audit found this pattern used 5+ times: a card with a colored header strip
> containing an icon + title, followed by body content. Currently each instance builds
> this from scratch with different spacing, colors, and radius values.
>
> **NOTE:** The `collapsible` flag switches between two implementations: a simple
> static card (most common) and a `_CollapsibleSectionCard` StatefulWidget with
> AnimationController for smooth expand/collapse. This avoids StatefulWidget overhead
> for the 80% case that doesn't need collapsing.

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
///
/// NOTE: Separated as a StatefulWidget to avoid forcing all AppSectionCard
/// instances to carry AnimationController overhead. Only created when
/// `collapsible: true` is passed.
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

## File Manifest

| Step | File | Action | Lines (approx) |
|------|------|--------|----------------|
| 1.C.1 | `lib/core/design_system/app_text.dart` | Create | 140 |
| 1.C.2 | `lib/core/design_system/app_text_field.dart` | Create | 80 |
| 1.C.3 | `lib/core/design_system/app_chip.dart` | Create | 130 |
| 1.C.4 | `lib/core/design_system/app_progress_bar.dart` | Create | 120 |
| 1.C.5 | `lib/core/design_system/app_counter_field.dart` | Create | 115 |
| 1.C.6 | `lib/core/design_system/app_toggle.dart` | Create | 70 |
| 1.C.7 | `lib/core/design_system/app_icon.dart` | Create | 55 |
| 1.D.1 | `lib/core/design_system/app_glass_card.dart` | Create | 110 |
| 1.D.2 | `lib/core/design_system/app_section_header.dart` | Create | 50 |
| 1.D.3 | `lib/core/design_system/app_list_tile.dart` | Create | 120 |
| 1.D.4 | `lib/core/design_system/app_photo_grid.dart` | Create | 130 |
| 1.D.5 | `lib/core/design_system/app_section_card.dart` | Create | 210 |

**Total: 12 new files, ~1,330 lines**

## Dependency Graph

```
Phase 1.A (tokens) + 1.B (FieldGuideColors)
    |
    v
Phase 1.C (atomic: AppText, AppTextField, AppChip, AppProgressBar,
           AppCounterField, AppToggle, AppIcon)
    |
    v
Phase 1.D (cards: AppGlassCard, AppSectionHeader, AppListTile,
           AppPhotoGrid, AppSectionCard)
    |
    v
Phase 1.E (surfaces) + Phase 1.F (composites)
    |
    v
Phase 1.G (barrel export + quality gate)
```

> **NOTE:** 1.C and 1.D can technically be implemented in parallel since no 1.D component
> depends on a 1.C component (e.g., AppListTile builds its own text rather than using
> AppText). However, executing 1.C first establishes the pattern for the agent.
