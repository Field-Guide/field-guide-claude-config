## Phase 3: Design System Expansion — New Components + Shared Widget Migrations

**Prerequisites**: Phase 2 (token system + sub-directory scaffolding with barrel files) must be complete. The following sub-directory barrel files and token ThemeExtensions must already exist:
- `lib/core/design_system/atoms/atoms.dart`
- `lib/core/design_system/molecules/molecules.dart`
- `lib/core/design_system/organisms/organisms.dart`
- `lib/core/design_system/surfaces/surfaces.dart`
- `lib/core/design_system/feedback/feedback.dart`
- `lib/core/design_system/tokens/tokens.dart` (exporting `FieldGuideSpacing`, `FieldGuideRadii`, `FieldGuideMotion`, `FieldGuideShadows`, `FieldGuideColors`, `DesignConstants`, `AppColors`)
- `lib/core/design_system/design_system.dart` (main barrel re-exporting all sub-barrels)

**Phase 2 token accessors assumed available**:
- `FieldGuideSpacing.of(context)` with fields: `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32), `xxl` (48)
- `FieldGuideRadii.of(context)` with fields: `xs` (4), `sm` (8), `compact` (10), `md` (12), `lg` (16), `xl` (24), `full` (999)
- `FieldGuideMotion.of(context)` with fields: `fast` (150ms), `normal` (300ms), `slow` (500ms), `pageTransition` (350ms), `curveStandard`, `curveDecelerate`
- `FieldGuideShadows.of(context)` with fields: `low`, `medium`, `high`, `modal`

**IMPORTANT**: All new components in this phase continue using `DesignConstants` for spacing/radii (the mass migration to token accessors happens in Phase 4+ decomposition). New components use `DesignConstants` consistently to match existing component style and avoid premature refactoring.

---

### Sub-phase 3.1: New Atoms

**Agent**: `code-fixer-agent`

#### Step 3.1.1: Create `AppButton`

Create `lib/core/design_system/atoms/app_button.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import 'app_icon.dart';
import 'app_mini_spinner.dart';

/// Semantic button with variant-based styling that wraps Material buttons.
///
/// Usage:
/// ```dart
/// AppButton.primary(label: 'Save Entry', onPressed: _save)
/// AppButton.secondary(label: 'Cancel', onPressed: _cancel)
/// AppButton.ghost(label: 'Skip', onPressed: _skip)
/// AppButton.danger(label: 'Delete', onPressed: _delete)
/// AppButton.primary(label: 'Syncing...', onPressed: null, isLoading: true)
/// ```
///
/// FROM SPEC: Replaces raw ElevatedButton/TextButton/OutlinedButton usage with
/// consistent spacing, radii, and loading state. New lint rule `no_raw_button`
/// will enforce this wrapper in presentation layer.
enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  /// Primary — filled elevated button (main CTA)
  const factory AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isExpanded,
  }) = _PrimaryAppButton;

  /// Secondary — outlined button (secondary action)
  const factory AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isExpanded,
  }) = _SecondaryAppButton;

  /// Ghost — text-only button (tertiary action)
  const factory AppButton.ghost({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isExpanded,
  }) = _GhostAppButton;

  /// Danger — error-colored filled button (destructive action)
  const factory AppButton.danger({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isExpanded,
  }) = _DangerAppButton;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Whether the button expands to fill available width.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // WHY: Disable press while loading to prevent double-submit.
    final effectiveOnPressed = isLoading ? null : onPressed;

    // NOTE: Build the child row with optional icon/spinner + label.
    final child = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          AppMiniSpinner(
            color: _spinnerColor(cs),
            size: DesignConstants.iconSizeSmall,
          ),
          const SizedBox(width: DesignConstants.space2),
        ] else if (icon != null) ...[
          AppIcon(icon!, size: AppIconSize.small),
          const SizedBox(width: DesignConstants.space2),
        ],
        Text(label),
      ],
    );

    // WHY: Each variant maps to its Material button wrapper so themes
    // from AppTheme (elevatedButtonTheme, outlinedButtonTheme, etc.)
    // automatically apply without manual color overrides.
    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          child: child,
        );
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        );
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          child: child,
        );
      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          child: child,
        );
    }

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Color _spinnerColor(ColorScheme cs) {
    return switch (variant) {
      AppButtonVariant.primary => cs.onPrimary,
      AppButtonVariant.secondary => cs.primary,
      AppButtonVariant.ghost => cs.primary,
      AppButtonVariant.danger => cs.onError,
    };
  }
}

// NOTE: Private subclasses for const factory constructors. Each simply
// forwards parameters to the base class with the correct variant value.

class _PrimaryAppButton extends AppButton {
  const _PrimaryAppButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isExpanded,
  }) : super(variant: AppButtonVariant.primary);
}

class _SecondaryAppButton extends AppButton {
  const _SecondaryAppButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isExpanded,
  }) : super(variant: AppButtonVariant.secondary);
}

class _GhostAppButton extends AppButton {
  const _GhostAppButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isExpanded,
  }) : super(variant: AppButtonVariant.ghost);
}

class _DangerAppButton extends AppButton {
  const _DangerAppButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isExpanded,
  }) : super(variant: AppButtonVariant.danger);
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_button.dart"
```
Expected: No issues found.

---

#### Step 3.1.2: Create `AppBadge`

Create `lib/core/design_system/atoms/app_badge.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';

/// Status/count/category badge with color, icon, or letter variants.
///
/// Usage:
/// ```dart
/// AppBadge.count(7, color: cs.primary)
/// AppBadge.icon(Icons.check, color: fg.statusSuccess)
/// AppBadge.letter('A', color: accentColor)
/// AppBadge.dot(color: cs.error)
/// ```
///
/// FROM SPEC: Unified badge component for status indicators, notification counts,
/// category markers. Replaces 15+ inline Container badge patterns.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.foregroundColor,
    this.size = 24.0,
    this.borderRadius,
  });

  /// Count badge — shows a number inside a colored circle.
  factory AppBadge.count(
    int count, {
    Key? key,
    required Color color,
    double size = 24.0,
  }) {
    return AppBadge(
      key: key,
      backgroundColor: color.withValues(alpha: 0.2),
      foregroundColor: color,
      size: size,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  /// Icon badge — shows an icon inside a colored container.
  factory AppBadge.icon(
    IconData icon, {
    Key? key,
    required Color color,
    double size = 24.0,
  }) {
    return AppBadge(
      key: key,
      backgroundColor: color.withValues(alpha: 0.2),
      foregroundColor: color,
      size: size,
      child: Icon(icon, size: size * 0.6, color: color),
    );
  }

  /// Letter badge — shows a single letter in a rounded square.
  /// WHY: Extracted from FormAccordion._LetterBadge pattern (form_accordion.dart:117).
  factory AppBadge.letter(
    String letter, {
    Key? key,
    required Color color,
    double size = 36.0,
  }) {
    return AppBadge(
      key: key,
      backgroundColor: color.withValues(alpha: 0.18),
      foregroundColor: color,
      size: size,
      // NOTE: radiusCompact (10) matches the FormAccordion letter badge pattern.
      borderRadius: DesignConstants.radiusCompact,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  /// Dot badge — small colored dot for status indicators.
  factory AppBadge.dot({
    Key? key,
    required Color color,
    double size = 8.0,
  }) {
    return AppBadge(
      key: key,
      backgroundColor: color,
      foregroundColor: color,
      size: size,
      child: const SizedBox.shrink(),
    );
  }

  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : null,
        // WHY: When no explicit borderRadius, use circle shape for count/icon/dot.
        shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: child,
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_badge.dart"
```
Expected: No issues found.

---

#### Step 3.1.3: Create `AppDivider`

Create `lib/core/design_system/atoms/app_divider.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';

/// Themed divider using design tokens for consistent spacing and color.
///
/// Usage:
/// ```dart
/// AppDivider()
/// AppDivider(indent: DesignConstants.space4)
/// AppDivider.vertical(height: 24)
/// ```
///
/// FROM SPEC: Wraps raw Divider with consistent color/spacing. New lint rule
/// `no_raw_divider` will enforce this wrapper in presentation layer.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.height,
    this.thickness,
    this.color,
  }) : _isVertical = false;

  /// Vertical divider variant.
  const AppDivider.vertical({
    super.key,
    this.height = 24.0,
    this.thickness,
    this.color,
  })  : indent = 0.0,
        endIndent = 0.0,
        _isVertical = true;

  final double indent;
  final double endIndent;
  final double? height;
  final double? thickness;
  final Color? color;
  final bool _isVertical;

  @override
  Widget build(BuildContext context) {
    // NOTE: DividerThemeData from AppTheme controls default color and thickness.
    // We only override when explicitly provided. This ensures theme consistency.
    if (_isVertical) {
      return SizedBox(
        height: height,
        child: VerticalDivider(
          thickness: thickness,
          color: color,
        ),
      );
    }

    return Divider(
      indent: indent,
      endIndent: endIndent,
      height: height ?? DesignConstants.space4,
      thickness: thickness,
      color: color,
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_divider.dart"
```
Expected: No issues found.

---

#### Step 3.1.4: Create `AppAvatar`

Create `lib/core/design_system/atoms/app_avatar.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import '../../theme/field_guide_colors.dart';

/// Circular user avatar with initials fallback.
///
/// Usage:
/// ```dart
/// AppAvatar(initials: 'JS', color: cs.primary)
/// AppAvatar(initials: 'RS', size: AppAvatarSize.large)
/// ```
///
/// FROM SPEC: Token-based sizing with initials fallback for user/inspector
/// identification in personnel lists and entry attribution.
enum AppAvatarSize {
  /// 32px — compact list items
  small(32.0),

  /// 40px — standard list items
  medium(40.0),

  /// 56px — profile headers
  large(56.0);

  const AppAvatarSize(this.value);
  final double value;
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.size = AppAvatarSize.medium,
    this.color,
    this.backgroundColor,
  });

  /// 1-2 character initials to display (e.g., "JS" for John Smith).
  final String initials;

  /// Avatar size tier.
  final AppAvatarSize size;

  /// Foreground text color. Default: colorScheme.onPrimary.
  final Color? color;

  /// Background circle color. Default: colorScheme.primary at 20% alpha.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bgColor = backgroundColor ?? cs.primary.withValues(alpha: 0.2);
    final fgColor = color ?? cs.primary;

    // WHY: Font size scales with avatar size for consistent visual weight.
    final fontSize = size.value * 0.4;

    return Container(
      width: size.value,
      height: size.value,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: tt.labelMedium?.copyWith(
          color: fgColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_avatar.dart"
```
Expected: No issues found.

---

#### Step 3.1.5: Create `AppTooltip`

Create `lib/core/design_system/atoms/app_tooltip.dart`:

```dart
import 'package:flutter/material.dart';

/// Themed tooltip wrapper using design tokens for consistent styling.
///
/// Usage:
/// ```dart
/// AppTooltip(
///   message: 'Sync status: Up to date',
///   child: Icon(Icons.sync),
/// )
/// ```
///
/// FROM SPEC: Wraps raw Tooltip with consistent decoration. New lint rule
/// `no_raw_tooltip` will enforce this wrapper in presentation layer.
class AppTooltip extends StatelessWidget {
  const AppTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = true,
    this.waitDuration,
  });

  final String message;
  final Widget child;
  final bool preferBelow;

  /// How long before the tooltip appears. Default: 500ms (Material default).
  final Duration? waitDuration;

  @override
  Widget build(BuildContext context) {
    // NOTE: Tooltip inherits tooltipTheme from ThemeData. We do NOT set
    // colors or decoration manually. All styling comes from the active theme.
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      waitDuration: waitDuration,
      child: child,
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_tooltip.dart"
```
Expected: No issues found.

---

#### Step 3.1.6: Update atoms barrel with new atoms

Edit `lib/core/design_system/atoms/atoms.dart` to add new atom exports. After Phase 2, this barrel should already exist with the moved atoms. Add the 5 new files:

```dart
// lib/core/design_system/atoms/atoms.dart
// WHY: Sub-directory barrel for all atomic design system components.

// Existing atoms (moved from flat design_system/ in Phase 2)
export 'app_text.dart';
export 'app_icon.dart';
export 'app_chip.dart';
export 'app_toggle.dart';
export 'app_progress_bar.dart';
export 'app_mini_spinner.dart';

// New atoms (Phase 3)
export 'app_button.dart';
export 'app_badge.dart';
export 'app_divider.dart';
export 'app_avatar.dart';
export 'app_tooltip.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/"
```
Expected: No issues found.

---

### Sub-phase 3.2: Move Existing Atoms to `atoms/`

**Agent**: `code-fixer-agent`

**IMPORTANT**: This sub-phase assumes Phase 2 has NOT already moved these files. If Phase 2 already created the atoms/ directory and moved files there, skip this sub-phase entirely. The plan is written defensively.

#### Step 3.2.1: Move `app_text.dart` to `atoms/`

Move `lib/core/design_system/app_text.dart` to `lib/core/design_system/atoms/app_text.dart`.

The file has zero internal design_system imports (it only imports `package:flutter/material.dart`), so no relative import changes needed.

**Action**: Copy content to new path, delete old file.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_text.dart"
```
Expected: No issues found.

---

#### Step 3.2.2: Move `app_icon.dart` to `atoms/`

Move `lib/core/design_system/app_icon.dart` to `lib/core/design_system/atoms/app_icon.dart`.

Update internal import — the file imports `../theme/design_constants.dart`. After the move to `atoms/`, the relative import becomes `../../theme/design_constants.dart`.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_icon.dart"
```
Expected: No issues found.

---

#### Step 3.2.3: Move `app_chip.dart` to `atoms/`

Move `lib/core/design_system/app_chip.dart` to `lib/core/design_system/atoms/app_chip.dart`.

Update internal imports:
- `../theme/colors.dart` becomes `../../theme/colors.dart`
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_chip.dart"
```
Expected: No issues found.

---

#### Step 3.2.4: Move `app_toggle.dart` to `atoms/`

Move `lib/core/design_system/app_toggle.dart` to `lib/core/design_system/atoms/app_toggle.dart`.

Update import: `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_toggle.dart"
```
Expected: No issues found.

---

#### Step 3.2.5: Move `app_progress_bar.dart` to `atoms/`

Move `lib/core/design_system/app_progress_bar.dart` to `lib/core/design_system/atoms/app_progress_bar.dart`.

Update imports:
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_progress_bar.dart"
```
Expected: No issues found.

---

#### Step 3.2.6: Move `app_mini_spinner.dart` to `atoms/`

Move `lib/core/design_system/app_mini_spinner.dart` to `lib/core/design_system/atoms/app_mini_spinner.dart`.

Update import: `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/app_mini_spinner.dart"
```
Expected: No issues found.

---

#### Step 3.2.7: Update atoms barrel (moved files)

Ensure `lib/core/design_system/atoms/atoms.dart` contains all 6 moved + 5 new exports. (This was already done in Step 3.1.6; verify the barrel is correct.)

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/atoms/"
```
Expected: No issues found.

---

### Sub-phase 3.3: New Molecules

**Agent**: `code-fixer-agent`

#### Step 3.3.1: Create `AppDropdown`

Create `lib/core/design_system/molecules/app_dropdown.dart`:

```dart
import 'package:flutter/material.dart';

/// Themed dropdown wrapping DropdownButtonFormField with consistent styling.
///
/// Usage:
/// ```dart
/// AppDropdown<String>(
///   label: 'Entry Type',
///   value: _selectedType,
///   items: types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
///   onChanged: (v) => setState(() => _selectedType = v),
/// )
/// ```
///
/// FROM SPEC: Wraps raw DropdownButtonFormField. New lint rule `no_raw_dropdown`
/// will enforce this wrapper. All styling inherited from inputDecorationTheme.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.isDense = true,
    this.isExpanded = true,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool isDense;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    // NOTE: DropdownButtonFormField inherits inputDecorationTheme from ThemeData.
    // We do NOT set colors manually. Border, fill, and label styles come from theme.
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      isDense: isDense,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/app_dropdown.dart"
```
Expected: No issues found.

---

#### Step 3.3.2: Create `AppDatePicker`

Create `lib/core/design_system/molecules/app_date_picker.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/design_constants.dart';

/// Themed date picker field that wraps showDatePicker with consistent styling.
///
/// Usage:
/// ```dart
/// AppDatePicker(
///   label: 'Entry Date',
///   value: _selectedDate,
///   onChanged: (date) => setState(() => _selectedDate = date),
/// )
/// ```
///
/// FROM SPEC: Wraps date picker with theme tokens. All dialog styling inherited
/// from datePickerTheme in ThemeData.
class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.label,
    required this.onChanged,
    this.value,
    this.firstDate,
    this.lastDate,
    this.dateFormat,
    this.prefixIcon = Icons.calendar_today,
    this.enabled = true,
    this.validator,
  });

  final String label;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? value;

  /// Earliest selectable date. Default: 2 years ago.
  final DateTime? firstDate;

  /// Latest selectable date. Default: 2 years from now.
  final DateTime? lastDate;

  /// Date format string. Default: 'MMM d, yyyy'.
  final String? dateFormat;

  final IconData? prefixIcon;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat(dateFormat ?? 'MMM d, yyyy');
    final displayText = value != null ? formatter.format(value!) : '';

    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: displayText),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: value != null && enabled
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => onChanged(null),
              )
            : null,
      ),
      enabled: enabled,
      validator: validator,
      onTap: enabled
          ? () async {
              // NOTE: datePickerTheme from AppTheme controls all dialog styling.
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 730)),
                lastDate: lastDate ?? DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) {
                onChanged(picked);
              }
            }
          : null,
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/app_date_picker.dart"
```
Expected: No issues found.

---

#### Step 3.3.3: Create `AppTabBar`

Create `lib/core/design_system/molecules/app_tab_bar.dart`:

```dart
import 'package:flutter/material.dart';

/// Themed tab bar using design tokens for consistent styling.
///
/// Usage:
/// ```dart
/// AppTabBar(
///   controller: _tabController,
///   tabs: [
///     Tab(text: 'Active'),
///     Tab(text: 'Archived'),
///   ],
/// )
/// ```
///
/// FROM SPEC: Wraps raw TabBar with consistent styling. All colors and indicator
/// styling inherited from tabBarTheme in ThemeData.
class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.onTap,
  });

  final List<Widget> tabs;
  final TabController? controller;
  final bool isScrollable;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    // NOTE: TabBar inherits tabBarTheme from ThemeData. We do NOT set
    // indicator color, label color, etc. manually. Theme consistency.
    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable,
      onTap: onTap,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/app_tab_bar.dart"
```
Expected: No issues found.

---

#### Step 3.3.4: Update molecules barrel with new molecules

Edit `lib/core/design_system/molecules/molecules.dart`:

```dart
// lib/core/design_system/molecules/molecules.dart
// WHY: Sub-directory barrel for all molecule-level design system components.

// Existing molecules (moved from flat design_system/ in Phase 2)
export 'app_text_field.dart';
export 'app_counter_field.dart';
export 'app_list_tile.dart';
export 'app_section_header.dart';

// New molecules (Phase 3)
export 'app_dropdown.dart';
export 'app_date_picker.dart';
export 'app_tab_bar.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/"
```
Expected: No issues found.

---

### Sub-phase 3.4: Move Existing Molecules + Migrate SearchBar

**Agent**: `code-fixer-agent`

**IMPORTANT**: Same note as 3.2 — if Phase 2 already moved these, skip the move steps and proceed to 3.4.5 (SearchBar migration).

#### Step 3.4.1: Move `app_text_field.dart` to `molecules/`

Move `lib/core/design_system/app_text_field.dart` to `lib/core/design_system/molecules/app_text_field.dart`.

The file only imports `package:flutter/material.dart` and `package:flutter/services.dart` — no relative import changes needed.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/app_text_field.dart"
```
Expected: No issues found.

---

#### Step 3.4.2: Move `app_counter_field.dart` to `molecules/`

Move `lib/core/design_system/app_counter_field.dart` to `lib/core/design_system/molecules/app_counter_field.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/app_counter_field.dart"
```
Expected: No issues found.

---

#### Step 3.4.3: Move `app_list_tile.dart` to `molecules/`

Move `lib/core/design_system/app_list_tile.dart` to `lib/core/design_system/molecules/app_list_tile.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`
- `app_glass_card.dart` becomes `../organisms/app_glass_card.dart`

**NOTE**: `app_glass_card.dart` will be in `organisms/` after sub-phase 3.5. If 3.5 has not yet run, use `../app_glass_card.dart` temporarily and update after 3.5. Alternatively, ensure phases run in order: 3.4 before 3.5, and use the barrel import instead:

```dart
// WHY: Use barrel import to avoid fragile relative paths across subdirectories.
import '../organisms/app_glass_card.dart';
```

If the move ordering makes this tricky, the safer approach is to import from the main barrel:
```dart
import 'package:construction_inspector/core/design_system/design_system.dart';
```
But this creates a circular barrel dependency. The correct approach: use a direct relative import to the organisms sub-directory.

**IMPORTANT**: The implementing agent must check whether `app_glass_card.dart` has already been moved to `organisms/` before writing this import. If not yet moved, use `'../app_glass_card.dart'` and flag for update in Step 3.5.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/app_list_tile.dart"
```
Expected: No issues found.

---

#### Step 3.4.4: Move `app_section_header.dart` to `molecules/`

Move `lib/core/design_system/app_section_header.dart` to `lib/core/design_system/molecules/app_section_header.dart`.

Update import: `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/app_section_header.dart"
```
Expected: No issues found.

---

#### Step 3.4.5: Migrate `SearchBarField` to `AppSearchBar`

Create `lib/core/design_system/molecules/app_search_bar.dart` based on `lib/shared/widgets/search_bar_field.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import 'app_text_field.dart';

/// Reusable search bar for filtering lists with consistent styling.
///
/// Usage:
/// ```dart
/// AppSearchBar(
///   controller: _searchController,
///   hintText: 'Search projects...',
///   onChanged: (query) => _filterResults(query),
/// )
/// ```
///
/// FROM SPEC: Migrated from lib/shared/widgets/search_bar_field.dart. Class renamed
/// from SearchBarField to AppSearchBar for design system naming consistency.
/// Original had 0 direct importers (barrel-exported only via widgets.dart).
class AppSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final Key? fieldKey;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.fieldKey,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // WHY: Delegates to AppTextField for consistent input decoration theme.
    return AppTextField(
      key: widget.fieldKey,
      controller: widget.controller,
      autofocus: widget.autofocus,
      hint: widget.hintText,
      prefixIcon: Icons.search,
      suffixIcon: widget.controller.text.isNotEmpty
          ? const Icon(Icons.clear)
          : null,
      onSuffixTap: widget.controller.text.isNotEmpty
          ? () {
              widget.controller.clear();
              widget.onClear?.call();
              widget.onChanged?.call('');
            }
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.space4,
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Backward-compatibility typedef for consumers still using SearchBarField.
/// WHY: Allows gradual migration without breaking existing code.
@Deprecated('Use AppSearchBar instead')
typedef SearchBarField = AppSearchBar;
```

Delete `lib/shared/widgets/search_bar_field.dart` after creation.

Update molecules barrel — add `export 'app_search_bar.dart';` to `lib/core/design_system/molecules/molecules.dart`.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/app_search_bar.dart"
```
Expected: No issues found.

---

### Sub-phase 3.5: Move Existing Organisms to `organisms/`

**Agent**: `code-fixer-agent`

#### Step 3.5.1: Move `app_glass_card.dart` to `organisms/`

Move `lib/core/design_system/app_glass_card.dart` to `lib/core/design_system/organisms/app_glass_card.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_glass_card.dart"
```
Expected: No issues found.

---

#### Step 3.5.2: Move `app_section_card.dart` to `organisms/`

Move `lib/core/design_system/app_section_card.dart` to `lib/core/design_system/organisms/app_section_card.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_section_card.dart"
```
Expected: No issues found.

---

#### Step 3.5.3: Move `app_photo_grid.dart` to `organisms/`

Move `lib/core/design_system/app_photo_grid.dart` to `lib/core/design_system/organisms/app_photo_grid.dart`.

Update import:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_photo_grid.dart"
```
Expected: No issues found.

---

#### Step 3.5.4: Move `app_info_banner.dart` to `organisms/`

Move `lib/core/design_system/app_info_banner.dart` to `lib/core/design_system/organisms/app_info_banner.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `app_icon.dart` becomes `../atoms/app_icon.dart`
- `app_text.dart` becomes `../atoms/app_text.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_info_banner.dart"
```
Expected: No issues found.

---

#### Step 3.5.5: Update `app_list_tile.dart` cross-reference

After `app_glass_card.dart` is moved to `organisms/`, update `lib/core/design_system/molecules/app_list_tile.dart` import:

Change `app_glass_card.dart` import to:
```dart
import '../organisms/app_glass_card.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/molecules/app_list_tile.dart"
```
Expected: No issues found.

---

#### Step 3.5.6: Update organisms barrel

Edit `lib/core/design_system/organisms/organisms.dart`:

```dart
// lib/core/design_system/organisms/organisms.dart
// WHY: Sub-directory barrel for all organism-level design system components.

// Existing organisms (moved from flat design_system/)
export 'app_glass_card.dart';
export 'app_section_card.dart';
export 'app_photo_grid.dart';
export 'app_info_banner.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/"
```
Expected: No issues found.

---

### Sub-phase 3.6: New Organisms — General

**Agent**: `code-fixer-agent`

#### Step 3.6.1: Create `AppStatCard`

Create `lib/core/design_system/organisms/app_stat_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';
import 'app_glass_card.dart';

/// Animated stat card for dashboard quick stats and summary displays.
///
/// Usage:
/// ```dart
/// AppStatCard(
///   label: 'Active Entries',
///   value: '12',
///   icon: Icons.description,
///   color: cs.primary,
///   onTap: () => navigateToEntries(),
/// )
/// ```
///
/// FROM SPEC: Generalized from DashboardStatCard (dashboard_stat_card.dart).
/// Reusable across dashboard, project summary, and sync dashboard screens.
/// WHY: DashboardStatCard is feature-specific but the pattern repeats across
/// 3+ features. Promoting to design system eliminates duplication.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.animate = true,
  });

  /// Descriptive label (e.g., "Active Entries", "Photos Taken").
  final String label;

  /// Display value (e.g., "12", "$4,500", "92%").
  final String value;

  /// Leading icon.
  final IconData icon;

  /// Accent color for icon background and value text.
  final Color color;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// Whether to animate entrance. Default: true.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget card = AppGlassCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WHY: Circle icon container with 15% alpha background matches
          // the DashboardStatCard pattern from dashboard_stat_card.dart.
          Container(
            padding: const EdgeInsets.all(DesignConstants.space2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: AppIcon(icon, size: AppIconSize.medium, color: color),
          ),
          const SizedBox(height: DesignConstants.space2),
          AppText.titleLarge(
            value,
            color: color,
          ),
          const SizedBox(height: DesignConstants.space1),
          AppText.labelSmall(
            label,
            color: cs.onSurfaceVariant,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (!animate) return card;

    // WHY: TweenAnimationBuilder provides a one-shot entrance animation
    // matching the existing DashboardStatCard scale+fade pattern.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: DesignConstants.animationNormal,
      curve: DesignConstants.curveSpring,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * animValue),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: RepaintBoundary(child: child),
          ),
        );
      },
      child: card,
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_stat_card.dart"
```
Expected: No issues found.

---

#### Step 3.6.2: Create `AppActionCard`

Create `lib/core/design_system/organisms/app_action_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';
import 'app_glass_card.dart';

/// Tappable card with icon, title, subtitle, and optional trailing widget.
///
/// Usage:
/// ```dart
/// AppActionCard(
///   icon: Icons.add_circle_outline,
///   title: 'New Entry',
///   subtitle: 'Start a daily inspection report',
///   onTap: () => createEntry(),
/// )
/// ```
///
/// FROM SPEC: Generic tappable action card for CTAs, quick actions,
/// and navigation cards. Uses AppGlassCard for consistent glass styling.
class AppActionCard extends StatelessWidget {
  const AppActionCard({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.trailing,
    this.accentColor,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;

  /// Optional trailing widget (e.g., chevron icon, badge).
  final Widget? trailing;

  /// Optional left accent border color.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppGlassCard(
      accentColor: accentColor,
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            // WHY: Icon in a colored circle container for visual hierarchy,
            // consistent with AppStatCard and DashboardStatCard patterns.
            Container(
              padding: const EdgeInsets.all(DesignConstants.space2),
              decoration: BoxDecoration(
                color: (accentColor ?? cs.primary).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                icon!,
                size: AppIconSize.medium,
                color: accentColor ?? cs.primary,
              ),
            ),
            const SizedBox(width: DesignConstants.space3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.titleSmall(title),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  AppText.bodySmall(
                    subtitle!,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: DesignConstants.space2),
            trailing!,
          ] else ...[
            const SizedBox(width: DesignConstants.space2),
            AppIcon(
              Icons.chevron_right,
              size: AppIconSize.medium,
              color: cs.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_action_card.dart"
```
Expected: No issues found.

---

#### Step 3.6.3: Update organisms barrel with general organisms

Add to `lib/core/design_system/organisms/organisms.dart`:

```dart
export 'app_stat_card.dart';
export 'app_action_card.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/"
```
Expected: No issues found.

---

### Sub-phase 3.7: New Organisms — Form Editor Primitives

**Agent**: `code-fixer-agent`

#### Step 3.7.1: Create `AppFormSection`

Create `lib/core/design_system/organisms/app_form_section.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import '../../theme/field_guide_colors.dart';
import '../atoms/app_badge.dart';

/// Status enum for form section completion tracking.
///
/// WHY: Generalized from HubSectionStatus (form_accordion.dart:5).
/// Uses generic terms instead of form-specific terminology.
enum FormSectionStatus {
  /// Section not yet started.
  notStarted,

  /// Section in progress.
  inProgress,

  /// Section complete/submitted.
  complete,
}

/// Collapsible form section with status indicator, letter badge, and title.
///
/// Usage:
/// ```dart
/// AppFormSection(
///   letter: 'A',
///   title: 'Header Information',
///   subtitle: '3 of 5 fields complete',
///   accentColor: Colors.blue,
///   status: FormSectionStatus.inProgress,
///   expanded: _expandedSection == 'A',
///   onTap: () => setState(() => _expandedSection = 'A'),
///   expandedChild: HeaderFormFields(),
/// )
/// ```
///
/// FROM SPEC: Generalized from FormAccordion (form_accordion.dart).
/// Removes form-specific terminology, uses design tokens.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.letter,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.status,
    required this.expanded,
    required this.onTap,
    required this.expandedChild,
    this.collapsedChild,
    this.headerKey,
    this.badgeKey,
  });

  /// Single letter identifier (e.g., 'A', 'B', 'C').
  final String letter;

  /// Section title.
  final String title;

  /// Subtitle text (e.g., "3 of 5 fields complete").
  final String subtitle;

  /// Accent color for letter badge and status indicators.
  final Color accentColor;

  /// Current completion status.
  final FormSectionStatus status;

  /// Whether this section is currently expanded.
  final bool expanded;

  /// Tap handler to toggle expansion.
  final VoidCallback onTap;

  /// Widget shown when section is expanded.
  final Widget expandedChild;

  /// Optional widget shown when collapsed.
  final Widget? collapsedChild;

  /// Optional key for header (testing).
  final Key? headerKey;

  /// Optional key for badge (testing).
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    final fg = FieldGuideColors.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // WHY: Left border visibility animates with expansion state,
    // matching the FormAccordion pattern.
    final borderColor = expanded
        ? accentColor.withValues(alpha: 0.3)
        : Colors.transparent;

    return AnimatedContainer(
      duration: DesignConstants.animationNormal,
      curve: DesignConstants.curveDefault,
      decoration: BoxDecoration(
        color: fg.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
        border: Border(left: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tappable header
          InkWell(
            key: headerKey,
            borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: DesignConstants.touchTargetComfortable,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.space3,
                  vertical: DesignConstants.space2,
                ),
                child: Row(
                  children: [
                    // WHY: AppBadge.letter reuses the same pattern as
                    // FormAccordion._LetterBadge.
                    AppBadge.letter(letter, color: accentColor),
                    const SizedBox(width: DesignConstants.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      key: badgeKey,
                      status: status,
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: DesignConstants.space1),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Collapsible body
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignConstants.space3,
              0,
              DesignConstants.space3,
              DesignConstants.space3,
            ),
            child: AnimatedCrossFade(
              firstChild: collapsedChild ?? const SizedBox.shrink(),
              secondChild: expandedChild,
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: DesignConstants.animationNormal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal status badge widget.
/// WHY: Extracted from FormAccordion._StatusBadge (form_accordion.dart:144).
/// Uses generalized FormSectionStatus enum instead of HubSectionStatus.
class _StatusBadge extends StatelessWidget {
  final FormSectionStatus status;
  final Color accentColor;

  const _StatusBadge({
    super.key,
    required this.status,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = FieldGuideColors.of(context);
    final cs = Theme.of(context).colorScheme;
    final (text, color) = switch (status) {
      FormSectionStatus.notStarted => ('Not Started', cs.onSurfaceVariant),
      FormSectionStatus.inProgress => ('In Progress', accentColor),
      FormSectionStatus.complete => ('Complete', fg.statusSuccess),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.space2,
        vertical: DesignConstants.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DesignConstants.radiusFull),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_form_section.dart"
```
Expected: No issues found.

---

#### Step 3.7.2: Create `AppFormSectionNav`

Create `lib/core/design_system/organisms/app_form_section_nav.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import '../../theme/field_guide_colors.dart';
import 'app_form_section.dart';

/// Data class for a section navigation item.
class FormSectionNavItem {
  const FormSectionNavItem({
    required this.id,
    required this.label,
    required this.status,
    required this.accentColor,
    this.key,
  });

  final String id;
  final String label;
  final FormSectionStatus status;
  final Color accentColor;
  final Key? key;
}

/// Section navigator with completion status pills.
///
/// Usage:
/// ```dart
/// AppFormSectionNav(
///   items: sections.map((s) => FormSectionNavItem(
///     id: s.id, label: s.letter, status: s.status, accentColor: s.color,
///   )).toList(),
///   selectedId: _currentSectionId,
///   onSelected: (id) => _scrollToSection(id),
/// )
/// ```
///
/// FROM SPEC: Generalized from StatusPillBar (status_pill_bar.dart).
/// Provides horizontal scrollable pill navigation with status indicators.
/// WHY: StatusPillBar is tightly coupled to HubSectionStatus. This generalized
/// version uses FormSectionStatus and supports optional onSelected callback.
class AppFormSectionNav extends StatelessWidget {
  const AppFormSectionNav({
    super.key,
    required this.items,
    this.selectedId,
    this.onSelected,
  });

  final List<FormSectionNavItem> items;

  /// Currently selected section ID. If null, no pill is highlighted.
  final String? selectedId;

  /// Callback when a pill is tapped.
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            _NavPill(
              item: item,
              isSelected: item.id == selectedId,
              onTap: onSelected != null ? () => onSelected!(item.id) : null,
            ),
            const SizedBox(width: DesignConstants.space2),
          ],
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final FormSectionNavItem item;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NavPill({
    required this.item,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = FieldGuideColors.of(context);
    final cs = Theme.of(context).colorScheme;

    // WHY: Color logic mirrors StatusPillBar._StatusPill (status_pill_bar.dart:51).
    final color = switch (item.status) {
      FormSectionStatus.notStarted => cs.onSurfaceVariant,
      FormSectionStatus.inProgress => item.accentColor,
      FormSectionStatus.complete => fg.statusSuccess,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: item.key,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.space3,
          vertical: DesignConstants.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : fg.surfaceElevated,
          borderRadius: BorderRadius.circular(DesignConstants.space5),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: DesignConstants.space2),
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_form_section_nav.dart"
```
Expected: No issues found.

---

#### Step 3.7.3: Create `AppFormStatusBar`

Create `lib/core/design_system/organisms/app_form_status_bar.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import '../../theme/field_guide_colors.dart';
import '../atoms/app_text.dart';
import 'app_form_section.dart';

/// Form-level completion status bar with validation summary.
///
/// Usage:
/// ```dart
/// AppFormStatusBar(
///   completedCount: 3,
///   totalCount: 5,
///   label: '3 of 5 sections complete',
/// )
/// ```
///
/// FROM SPEC: Generalized from StatusPillBar for form-level completion display.
/// Shows a progress indicator with count and optional validation messages.
class AppFormStatusBar extends StatelessWidget {
  const AppFormStatusBar({
    super.key,
    required this.completedCount,
    required this.totalCount,
    this.label,
    this.validationErrors = const [],
  });

  /// Number of completed sections/fields.
  final int completedCount;

  /// Total number of sections/fields.
  final int totalCount;

  /// Optional label override. Default: "{completed} of {total} complete".
  final String? label;

  /// Optional list of validation error messages.
  final List<String> validationErrors;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = FieldGuideColors.of(context);

    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final isComplete = completedCount >= totalCount;
    final displayLabel = label ?? '$completedCount of $totalCount complete';

    // WHY: Green for complete, primary for in-progress matches status patterns.
    final statusColor = isComplete ? fg.statusSuccess : cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              isComplete ? Icons.check_circle : Icons.pending,
              color: statusColor,
              size: DesignConstants.iconSizeSmall,
            ),
            const SizedBox(width: DesignConstants.space2),
            Expanded(
              child: AppText.labelMedium(
                displayLabel,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.space2),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignConstants.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: fg.surfaceBright.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
        ),
        // Validation errors
        if (validationErrors.isNotEmpty) ...[
          const SizedBox(height: DesignConstants.space2),
          for (final error in validationErrors)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 14),
                  const SizedBox(width: DesignConstants.space1),
                  Expanded(
                    child: AppText.bodySmall(error, color: cs.error),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_form_status_bar.dart"
```
Expected: No issues found.

---

#### Step 3.7.4: Create `AppFormFieldGroup`

Create `lib/core/design_system/organisms/app_form_field_group.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import '../atoms/app_text.dart';

/// Groups related form fields with label, optional help text, and layout.
///
/// Usage:
/// ```dart
/// AppFormFieldGroup(
///   label: 'Location Details',
///   helpText: 'Enter the intersection or landmark',
///   children: [
///     AppTextField(label: 'Street', controller: _streetCtrl),
///     AppTextField(label: 'City', controller: _cityCtrl),
///   ],
/// )
/// ```
///
/// FROM SPEC: Extracts the common form field grouping pattern from hub content
/// screens. Groups fields with a label header and consistent spacing.
class AppFormFieldGroup extends StatelessWidget {
  const AppFormFieldGroup({
    super.key,
    required this.label,
    required this.children,
    this.helpText,
    this.spacing,
  });

  /// Group label text.
  final String label;

  /// Child widgets (form fields).
  final List<Widget> children;

  /// Optional help text shown below the label.
  final String? helpText;

  /// Spacing between child fields. Default: space3 (12px).
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fieldSpacing = spacing ?? DesignConstants.space3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Group label
        AppText.labelMedium(
          label.toUpperCase(),
          color: cs.onSurfaceVariant,
        ),
        if (helpText != null) ...[
          const SizedBox(height: DesignConstants.space1),
          AppText.bodySmall(
            helpText!,
            color: cs.onSurfaceVariant,
          ),
        ],
        const SizedBox(height: DesignConstants.space2),
        // Fields with spacing
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) SizedBox(height: fieldSpacing),
        ],
      ],
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_form_field_group.dart"
```
Expected: No issues found.

---

#### Step 3.7.5: Create `AppFormSummaryTile`

Create `lib/core/design_system/organisms/app_form_summary_tile.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';

/// Data class for a summary tile entry.
class FormSummaryTileData {
  const FormSummaryTileData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

/// Compact read-only display of completed field values in a horizontal row.
///
/// Usage:
/// ```dart
/// AppFormSummaryTile(
///   tiles: [
///     FormSummaryTileData(label: 'Temperature', value: '72F'),
///     FormSummaryTileData(label: 'Moisture', value: '45%'),
///     FormSummaryTileData(label: 'Density', value: '98.2%'),
///   ],
/// )
/// ```
///
/// FROM SPEC: Generalized from SummaryTiles (summary_tiles.dart).
/// Same layout pattern: horizontal row of label:value pairs with equal spacing.
class AppFormSummaryTile extends StatelessWidget {
  const AppFormSummaryTile({
    super.key,
    required this.tiles,
  });

  final List<FormSummaryTileData> tiles;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // WHY: Row layout with Expanded children matches SummaryTiles pattern
    // (summary_tiles.dart:19-49). Equal-width tiles with consistent styling.
    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.space2,
                vertical: DesignConstants.space2,
              ),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(DesignConstants.radiusCompact),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tiles[i].value,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tiles[i].label,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          if (i != tiles.length - 1)
            const SizedBox(width: DesignConstants.space2),
        ],
      ],
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_form_summary_tile.dart"
```
Expected: No issues found.

---

#### Step 3.7.6: Create `AppFormThumbnail`

Create `lib/core/design_system/organisms/app_form_thumbnail.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import '../../theme/field_guide_colors.dart';

/// Status enum for form thumbnails.
/// WHY: Decoupled from FormResponseStatus to avoid feature-layer dependency.
/// Feature code maps its domain status to this enum when constructing thumbnails.
enum FormThumbnailStatus { open, submitted, exported }

/// Mini preview card for form selection in attachment grids.
///
/// Usage:
/// ```dart
/// AppFormThumbnail(
///   name: '0582B Proctor',
///   status: FormThumbnailStatus.submitted,
///   onTap: () => openForm(response.id),
///   onDelete: () => deleteResponse(response.id),
/// )
/// ```
///
/// FROM SPEC: Generalized from FormThumbnail (form_thumbnail.dart).
/// Removes dependency on FormResponse/InspectorForm domain models.
/// Feature code provides primitive parameters instead.
class AppFormThumbnail extends StatelessWidget {
  const AppFormThumbnail({
    super.key,
    required this.name,
    required this.status,
    this.icon = Icons.description,
    this.onTap,
    this.onDelete,
  });

  /// Display name for the form.
  final String name;

  /// Form completion status.
  final FormThumbnailStatus status;

  /// Center icon. Default: Icons.description.
  final IconData icon;

  /// Tap handler to open the form.
  final VoidCallback? onTap;

  /// Delete handler. If null, delete button is hidden.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Stack(
                children: [
                  // Center icon
                  Center(
                    child: Icon(
                      icon,
                      size: DesignConstants.iconSizeXL,
                      color: cs.primary,
                    ),
                  ),
                  // Status badge (top-right)
                  Positioned(
                    top: DesignConstants.space1,
                    right: DesignConstants.space1,
                    child: _buildStatusBadge(context),
                  ),
                  // Delete button (top-left)
                  if (onDelete != null)
                    Positioned(
                      top: DesignConstants.space1,
                      left: DesignConstants.space1,
                      child: _buildDeleteButton(context),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.space1),
        Text(
          name,
          style: tt.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = FieldGuideColors.of(context);

    // WHY: Color/icon mapping matches FormThumbnail._buildStatusBadge
    // (form_thumbnail.dart:84-91).
    final (color, statusIcon) = switch (status) {
      FormThumbnailStatus.open => (cs.primary, Icons.edit),
      FormThumbnailStatus.submitted => (fg.statusSuccess, Icons.check),
      FormThumbnailStatus.exported => (cs.tertiary, Icons.download_done),
    };

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignConstants.radiusXSmall),
      ),
      child: Icon(statusIcon, size: 14, color: color),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onDelete,
      child: Container(
        padding: const EdgeInsets.all(DesignConstants.space1),
        decoration: BoxDecoration(
          color: cs.scrim.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(DesignConstants.radiusXSmall),
        ),
        child: Icon(
          Icons.close,
          size: 14,
          color: cs.onInverseSurface,
        ),
      ),
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/app_form_thumbnail.dart"
```
Expected: No issues found.

---

#### Step 3.7.7: Update organisms barrel with form editor primitives

Add to `lib/core/design_system/organisms/organisms.dart`:

```dart
// Form editor organisms (Phase 3.7)
export 'app_form_section.dart';
export 'app_form_section_nav.dart';
export 'app_form_status_bar.dart';
export 'app_form_field_group.dart';
export 'app_form_summary_tile.dart';
export 'app_form_thumbnail.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/organisms/"
```
Expected: No issues found.

---

### Sub-phase 3.8: Move Existing Surfaces to `surfaces/`

**Agent**: `code-fixer-agent`

#### Step 3.8.1: Move `app_scaffold.dart` to `surfaces/`

Move `lib/core/design_system/app_scaffold.dart` to `lib/core/design_system/surfaces/app_scaffold.dart`.

The file only imports `package:flutter/material.dart` — no relative import changes needed.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/surfaces/app_scaffold.dart"
```
Expected: No issues found.

---

#### Step 3.8.2: Move `app_bottom_bar.dart` to `surfaces/`

Move `lib/core/design_system/app_bottom_bar.dart` to `lib/core/design_system/surfaces/app_bottom_bar.dart`.

Update import: `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/surfaces/app_bottom_bar.dart"
```
Expected: No issues found.

---

#### Step 3.8.3: Move `app_bottom_sheet.dart` to `surfaces/`

Move `lib/core/design_system/app_bottom_sheet.dart` to `lib/core/design_system/surfaces/app_bottom_sheet.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`
- `app_drag_handle.dart` becomes `app_drag_handle.dart` (same directory after move)

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/surfaces/app_bottom_sheet.dart"
```
Expected: No issues found.

---

#### Step 3.8.4: Move `app_dialog.dart` to `surfaces/`

Move `lib/core/design_system/app_dialog.dart` to `lib/core/design_system/surfaces/app_dialog.dart`.

Update import: `app_text.dart` becomes `../atoms/app_text.dart`.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/surfaces/app_dialog.dart"
```
Expected: No issues found.

---

#### Step 3.8.5: Move `app_sticky_header.dart` to `surfaces/`

Move `lib/core/design_system/app_sticky_header.dart` to `lib/core/design_system/surfaces/app_sticky_header.dart`.

Update import: `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/surfaces/app_sticky_header.dart"
```
Expected: No issues found.

---

#### Step 3.8.6: Move `app_drag_handle.dart` to `surfaces/`

Move `lib/core/design_system/app_drag_handle.dart` to `lib/core/design_system/surfaces/app_drag_handle.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/surfaces/app_drag_handle.dart"
```
Expected: No issues found.

---

#### Step 3.8.7: Update surfaces barrel

Edit `lib/core/design_system/surfaces/surfaces.dart`:

```dart
// lib/core/design_system/surfaces/surfaces.dart
// WHY: Sub-directory barrel for all surface-level design system components.

export 'app_scaffold.dart';
export 'app_bottom_bar.dart';
export 'app_bottom_sheet.dart';
export 'app_dialog.dart';
export 'app_sticky_header.dart';
export 'app_drag_handle.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/surfaces/"
```
Expected: No issues found.

---

### Sub-phase 3.9: Move Existing Feedback + Migrations + New Banner

**Agent**: `code-fixer-agent`

#### Step 3.9.1: Move `app_empty_state.dart` to `feedback/`

Move `lib/core/design_system/app_empty_state.dart` to `lib/core/design_system/feedback/app_empty_state.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`
- `app_icon.dart` becomes `../atoms/app_icon.dart`
- `app_text.dart` becomes `../atoms/app_text.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/feedback/app_empty_state.dart"
```
Expected: No issues found.

---

#### Step 3.9.2: Move `app_error_state.dart` to `feedback/`

Move `lib/core/design_system/app_error_state.dart` to `lib/core/design_system/feedback/app_error_state.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `app_icon.dart` becomes `../atoms/app_icon.dart`
- `app_text.dart` becomes `../atoms/app_text.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/feedback/app_error_state.dart"
```
Expected: No issues found.

---

#### Step 3.9.3: Move `app_loading_state.dart` to `feedback/`

Move `lib/core/design_system/app_loading_state.dart` to `lib/core/design_system/feedback/app_loading_state.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `app_text.dart` becomes `../atoms/app_text.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/feedback/app_loading_state.dart"
```
Expected: No issues found.

---

#### Step 3.9.4: Move `app_budget_warning_chip.dart` to `feedback/`

Move `lib/core/design_system/app_budget_warning_chip.dart` to `lib/core/design_system/feedback/app_budget_warning_chip.dart`.

Update imports:
- `../theme/design_constants.dart` becomes `../../theme/design_constants.dart`
- `../theme/field_guide_colors.dart` becomes `../../theme/field_guide_colors.dart`
- `app_icon.dart` becomes `../atoms/app_icon.dart`
- `app_text.dart` becomes `../atoms/app_text.dart`

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/feedback/app_budget_warning_chip.dart"
```
Expected: No issues found.

---

#### Step 3.9.5: Migrate `SnackBarHelper` to `AppSnackbar`

Create `lib/core/design_system/feedback/app_snackbar.dart` based on `lib/shared/utils/snackbar_helper.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/field_guide_colors.dart';

/// Centralized snackbar helper with consistent type-specific styling.
///
/// Usage:
/// ```dart
/// AppSnackbar.showSuccess(context, 'Entry saved');
/// AppSnackbar.showError(context, 'Failed to sync');
/// AppSnackbar.showInfo(context, 'Syncing...');
/// AppSnackbar.showWarning(context, 'Offline mode active');
/// AppSnackbar.showWithAction(context, 'Deleted', 'Undo', () => restore());
/// ```
///
/// FROM SPEC: Migrated from lib/shared/utils/snackbar_helper.dart (140 lines).
/// 3 direct importers to update: pdf_data_builder.dart, consent_screen.dart,
/// legal_document_screen.dart.
///
/// WHY: SnackBarHelper belongs in design system feedback layer, not shared/utils.
/// Class renamed to AppSnackbar for design system naming consistency.
class AppSnackbar {
  AppSnackbar._();

  /// Show a success snackbar with green background.
  ///
  /// Used for completed actions like save, delete, sync, etc.
  static void showSuccess(BuildContext context, String message) {
    final fgc = FieldGuideColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: fgc.textInverse),
        ),
        backgroundColor: fgc.statusSuccess,
      ),
    );
  }

  /// Show an error snackbar with red background.
  ///
  /// Used for failures, validation errors, network errors, etc.
  /// Optional [duration] overrides the default snackbar duration.
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: cs.onError),
        ),
        backgroundColor: cs.error,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  /// Show an error snackbar with an action button, returning the controller.
  ///
  /// Used when the caller needs to chain on the snackbar's [closed] future,
  /// e.g. to reset a dedup flag after dismissal.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showErrorWithAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final cs = Theme.of(context).colorScheme;
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: cs.onError),
        ),
        backgroundColor: cs.error,
        duration: duration,
        action: SnackBarAction(
          label: actionLabel,
          textColor: cs.onError,
          onPressed: onAction,
        ),
      ),
    );
  }

  /// Show an informational snackbar with blue background.
  ///
  /// Used for neutral notifications, status updates, etc.
  static void showInfo(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: cs.onPrimary),
        ),
        backgroundColor: cs.primary,
      ),
    );
  }

  /// Show a warning snackbar with orange background.
  ///
  /// Used for caution messages, partial completion, pending issues, etc.
  static void showWarning(BuildContext context, String message) {
    final fgc = FieldGuideColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: fgc.textInverse),
        ),
        backgroundColor: fgc.statusWarning,
      ),
    );
  }

  /// Show a snackbar with a custom action button.
  ///
  /// Used when user can take immediate action on the notification.
  /// Example: "Deleted project" with "Undo" action.
  static void showWithAction(
    BuildContext context,
    String message,
    String actionLabel,
    VoidCallback onAction,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
        ),
      ),
    );
  }
}

/// Backward-compatibility typedef for consumers still using SnackBarHelper.
/// WHY: 3 direct importers + barrel-exported. Gradual migration path.
@Deprecated('Use AppSnackbar instead')
typedef SnackBarHelper = AppSnackbar;
```

Now update the 3 direct importers. Change their import from:
```dart
import 'package:construction_inspector/shared/utils/snackbar_helper.dart';
```
to:
```dart
import 'package:construction_inspector/core/design_system/design_system.dart';
```

Files to update:
1. `lib/features/entries/presentation/controllers/pdf_data_builder.dart` — change `SnackBarHelper.showError(` to `AppSnackbar.showError(`
2. `lib/features/settings/presentation/screens/consent_screen.dart` — change all `SnackBarHelper.*` to `AppSnackbar.*`
3. `lib/features/settings/presentation/screens/legal_document_screen.dart` — change all `SnackBarHelper.*` to `AppSnackbar.*`

Delete `lib/shared/utils/snackbar_helper.dart` after all consumers are updated.

**NOTE**: Also check if `lib/shared/utils/utils.dart` barrel exports `snackbar_helper.dart` and remove that export line.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/feedback/app_snackbar.dart"
```
Expected: No issues found.

---

#### Step 3.9.6: Migrate `ContextualFeedbackOverlay` to `AppContextualFeedback`

Create `lib/core/design_system/feedback/app_contextual_feedback.dart` based on `lib/shared/widgets/contextual_feedback_overlay.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';
import '../../theme/field_guide_colors.dart';
import '../atoms/app_text.dart';

/// Shows an animated contextual feedback popup anchored near a screen position.
///
/// Used for transient action feedback (delete confirmations, status changes)
/// that dismisses automatically after 2 seconds. Avoids snackbars when an
/// action originates from a specific location on screen (e.g. long-press).
///
/// Usage:
/// ```dart
/// AppContextualFeedback.show(
///   context: context,
///   message: 'Entry deleted',
///   isSuccess: true,
///   anchorPosition: _lastLongPressPosition,
///   mounted: () => mounted,
/// );
/// ```
///
/// FROM SPEC: Migrated from lib/shared/widgets/contextual_feedback_overlay.dart.
/// Original had 0 direct importers (barrel-exported only via widgets.dart).
class AppContextualFeedback {
  AppContextualFeedback._();

  static OverlayEntry? _currentOverlay;

  /// Show a feedback toast anchored to [anchorPosition].
  ///
  /// [mounted] is a callback that returns the calling widget's `mounted` state,
  /// used to safely remove the overlay on the auto-dismiss timer.
  static void show({
    required BuildContext context,
    required String message,
    required bool isSuccess,
    required Offset anchorPosition,
    required bool Function() mounted,
  }) {
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (overlayContext) {
        final cs = Theme.of(overlayContext).colorScheme;
        final fg = FieldGuideColors.of(overlayContext);
        final textIconColor = isSuccess ? cs.onPrimary : cs.onError;
        return Positioned(
          left: DesignConstants.space5,
          right: DesignConstants.space5,
          top: anchorPosition.dy - 50,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: DesignConstants.animationFast,
                builder: (overlayContext, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(overlayContext).width -
                        (DesignConstants.space5 * 2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.space4,
                    vertical: DesignConstants.space3,
                  ),
                  decoration: BoxDecoration(
                    color: isSuccess ? fg.statusSuccess : cs.error,
                    borderRadius:
                        BorderRadius.circular(DesignConstants.radiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.2),
                        blurRadius: DesignConstants.elevationHigh,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: textIconColor,
                        size: 20,
                      ),
                      const SizedBox(width: DesignConstants.space2),
                      Flexible(
                        child: AppText.labelLarge(
                          message,
                          color: textIconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_currentOverlay!);

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentOverlay != null && mounted()) {
        _currentOverlay!.remove();
        _currentOverlay = null;
      }
    });
  }

  /// Immediately remove the overlay without waiting for the timer.
  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

/// Backward-compatibility typedef for consumers still using ContextualFeedbackOverlay.
@Deprecated('Use AppContextualFeedback instead')
typedef ContextualFeedbackOverlay = AppContextualFeedback;
```

Delete `lib/shared/widgets/contextual_feedback_overlay.dart` after creation.

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/feedback/app_contextual_feedback.dart"
```
Expected: No issues found.

---

#### Step 3.9.7: Create `AppBanner`

Create `lib/core/design_system/feedback/app_banner.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/field_guide_colors.dart';

/// Generic composable banner for status messages, warnings, and notifications.
///
/// Usage:
/// ```dart
/// AppBanner(
///   icon: Icons.wifi_off,
///   message: 'Last server check was over 24 hours ago.',
///   color: fg.statusWarning,
///   actions: [
///     TextButton(onPressed: _retry, child: Text('Retry')),
///   ],
/// )
/// AppBanner(
///   icon: Icons.system_update,
///   message: 'A new version is available.',
///   color: fg.statusInfo,
///   dismissible: true,
///   onDismiss: () => setState(() => _dismissed = true),
/// )
/// ```
///
/// FROM SPEC: Generic composable banner that replaces StaleConfigWarning
/// and VersionBanner (shared/widgets/). Those will be recomposed from AppBanner
/// in Phase 4 (screen decomposition).
///
/// WHY: StaleConfigWarning and VersionBanner are nearly identical — both use
/// MaterialBanner with an icon, message, and optional action. This unifies them
/// into a single parameterized component.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    this.actions = const [],
    this.dismissible = false,
    this.onDismiss,
    this.testingKey,
  });

  /// Leading icon.
  final IconData icon;

  /// Banner message text.
  final String message;

  /// Accent color for icon and background tinting.
  final Color color;

  /// Action buttons (e.g., Retry, Dismiss).
  final List<Widget> actions;

  /// Whether the banner can be dismissed. If true and no explicit dismiss
  /// action is in [actions], a "Dismiss" button is auto-added.
  final bool dismissible;

  /// Called when the banner is dismissed.
  final VoidCallback? onDismiss;

  /// Optional testing key for E2E test automation.
  final Key? testingKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // WHY: Build effective actions list. If dismissible and no actions provided,
    // add a default "Dismiss" button for consistent UX.
    final effectiveActions = [
      ...actions,
      if (dismissible && actions.isEmpty)
        TextButton(
          onPressed: onDismiss,
          child: const Text('Dismiss'),
        ),
    ];

    // NOTE: MaterialBanner handles layout, padding, and divider automatically.
    // We only provide semantic parameters.
    return MaterialBanner(
      key: testingKey,
      backgroundColor: color.withValues(alpha: 0.08),
      leading: Icon(icon, color: color),
      content: Text(
        message,
        style: tt.bodySmall?.copyWith(color: cs.onSurface),
      ),
      actions: effectiveActions.isEmpty
          ? [const SizedBox.shrink()]
          : effectiveActions,
    );
  }
}
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/feedback/app_banner.dart"
```
Expected: No issues found.

---

#### Step 3.9.8: Merge `EmptyStateWidget` into `AppEmptyState`

`AppEmptyState` already exists (moved to `feedback/` in Step 3.9.1). `EmptyStateWidget` (`lib/shared/widgets/empty_state_widget.dart`) has the same purpose with slightly different API.

Differences:
- `EmptyStateWidget` uses `subtitle` as required String, `actionButton` as Widget
- `AppEmptyState` uses `subtitle` as optional String, `actionLabel`/`onAction` as separate params

The `AppEmptyState` API is already a superset. No code changes to `AppEmptyState` needed.

**Action**: Delete `lib/shared/widgets/empty_state_widget.dart`. The `ContextualFeedbackOverlay` backward-compat typedef and barrel update handle the transition.

**Verification**: Handled in Step 3.10 (barrel update).

---

#### Step 3.9.9: Merge `showConfirmationDialog` functions into `AppDialog`

Add confirmation dialog static methods to `lib/core/design_system/surfaces/app_dialog.dart`. Edit the file to add these methods after the existing `show<T>` method:

```dart
  /// Shows a confirmation dialog with customizable title, message, and actions.
  ///
  /// Returns true if confirmed, false if cancelled or dismissed.
  ///
  /// FROM SPEC: Migrated from lib/shared/widgets/confirmation_dialog.dart.
  /// TestingKeys preserved for E2E test automation.
  ///
  /// IMPORTANT: This method needs access to TestingKeys. Import path:
  /// import 'package:construction_inspector/shared/testing_keys/testing_keys.dart';
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
  }) async {
    final result = await show<bool>(
      context,
      title: title,
      content: Text(message),
      icon: icon,
      iconColor: iconColor,
      dialogKey: TestingKeys.confirmationDialog,
      actionsBuilder: (ctx) => [
        TextButton(
          key: TestingKeys.cancelDialogButton,
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          key: _getConfirmButtonKey(confirmText),
          onPressed: () => Navigator.pop(ctx, true),
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
    return result ?? false;
  }

  /// Shows a delete confirmation dialog.
  ///
  /// Specialized version for delete operations.
  static Future<bool> showDeleteConfirmation(
    BuildContext context, {
    required String itemName,
    String? customMessage,
  }) async {
    final result = await show<bool>(
      context,
      title: 'Delete $itemName?',
      content: Text(customMessage ?? 'This action cannot be undone.'),
      icon: Icons.delete_outline,
      iconColor: Theme.of(context).colorScheme.error,
      dialogKey: TestingKeys.confirmationDialog,
      actionsBuilder: (ctx) => [
        TextButton(
          key: TestingKeys.confirmationDialogCancel,
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: TestingKeys.deleteConfirmButton,
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
    return result ?? false;
  }

  /// Shows an unsaved changes dialog with Save/Discard/Cancel options.
  ///
  /// Returns: true = Save, false = Discard, null = Cancel.
  static Future<bool?> showUnsavedChanges(
    BuildContext context, {
    bool isEditMode = false,
  }) async {
    return show<bool?>(
      context,
      title: isEditMode ? 'Save Changes?' : 'Save Entry?',
      content: Text(isEditMode
          ? 'Would you like to save your changes before leaving?'
          : 'Would you like to save this entry as a draft before leaving?'),
      dialogKey: TestingKeys.unsavedChangesDialog,
      actionsBuilder: (ctx) => [
        TextButton(
          key: TestingKeys.unsavedChangesCancel,
          onPressed: () => Navigator.pop(ctx, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: TestingKeys.entryWizardSaveDraft,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(isEditMode ? 'Save' : 'Save Draft'),
        ),
        TextButton(
          key: TestingKeys.discardDialogButton,
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Discard'),
        ),
      ],
    );
  }

  /// Helper function to determine the correct key for confirm buttons.
  static Key _getConfirmButtonKey(String confirmText) {
    switch (confirmText.toLowerCase()) {
      case 'confirm':
        return TestingKeys.confirmDialogButton;
      case 'archive':
        return TestingKeys.archiveConfirmButton;
      default:
        return Key('confirmation_dialog_${confirmText.toLowerCase().replaceAll(' ', '_')}');
    }
  }
```

**IMPORTANT**: The `app_dialog.dart` file (now in `surfaces/`) must add this import at the top:
```dart
import 'package:construction_inspector/shared/testing_keys/testing_keys.dart';
```

After adding these methods, delete `lib/shared/widgets/confirmation_dialog.dart`.

**NOTE**: Any file that currently calls `showConfirmationDialog(...)` (the top-level function from confirmation_dialog.dart) must be updated to call `AppDialog.showConfirmation(...)`. Search for usages:

```
pwsh -Command "flutter analyze lib/core/design_system/surfaces/app_dialog.dart"
```
Expected: No issues found.

---

#### Step 3.9.10: Update feedback barrel

Edit `lib/core/design_system/feedback/feedback.dart`:

```dart
// lib/core/design_system/feedback/feedback.dart
// WHY: Sub-directory barrel for all feedback-level design system components.

// Existing feedback components (moved from flat design_system/)
export 'app_empty_state.dart';
export 'app_error_state.dart';
export 'app_loading_state.dart';
export 'app_budget_warning_chip.dart';

// New/migrated feedback components (Phase 3)
export 'app_snackbar.dart';
export 'app_contextual_feedback.dart';
export 'app_banner.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/core/design_system/feedback/"
```
Expected: No issues found.

---

### Sub-phase 3.10: Update Shared Widgets Barrel

**Agent**: `code-fixer-agent`

#### Step 3.10.1: Update `lib/shared/widgets/widgets.dart`

After all migrations and deletions from Phase 3, the barrel should contain only `permission_dialog.dart`:

```dart
library;

// WHY: All other widgets migrated to lib/core/design_system/ in Phase 3.
// - confirmation_dialog.dart -> AppDialog.showConfirmation() (surfaces/)
// - contextual_feedback_overlay.dart -> AppContextualFeedback (feedback/)
// - empty_state_widget.dart -> merged into AppEmptyState (feedback/)
// - search_bar_field.dart -> AppSearchBar (molecules/)
// - stale_config_warning.dart -> retained here until P4 recomposes from AppBanner
// - version_banner.dart -> retained here until P4 recomposes from AppBanner

export 'permission_dialog.dart';
export 'stale_config_warning.dart';
export 'version_banner.dart';
```

**NOTE**: `stale_config_warning.dart` and `version_banner.dart` are NOT deleted in Phase 3. Per the spec, they will be recomposed from `AppBanner` in Phase 4 (screen decomposition). They remain in shared/widgets for now to avoid breaking `scaffold_with_nav_bar.dart` which directly imports them. Phase 4 will recompose them as thin wrappers around `AppBanner` and then delete the originals.

**Verification**:
```
pwsh -Command "flutter analyze lib/shared/widgets/"
```
Expected: No issues found.

---

#### Step 3.10.2: Update shared utils barrel

Check if `lib/shared/utils/utils.dart` exports `snackbar_helper.dart` and remove that export line.

**Verification**:
```
pwsh -Command "flutter analyze lib/shared/"
```
Expected: No issues found.

---

### Sub-phase 3.11: Full Barrel Update + Analyze

**Agent**: `code-fixer-agent`

#### Step 3.11.1: Update main design_system barrel

Replace `lib/core/design_system/design_system.dart` with the new sub-barrel structure:

```dart
// Barrel export for the Field Guide design system.
//
// Usage (single import for all components):
// ```dart
// import 'package:construction_inspector/core/design_system/design_system.dart';
// ```
//
// WHY: Restructured from flat 24-export barrel to atomic sub-directory barrels.
// Consumer imports remain unchanged because this barrel re-exports everything.

// Token layer (Phase 2)
export 'tokens/tokens.dart';

// Atomic layer — smallest building blocks
export 'atoms/atoms.dart';

// Molecule layer — composed atomic elements
export 'molecules/molecules.dart';

// Organism layer — complex composed widgets
export 'organisms/organisms.dart';

// Surface layer — layout scaffolding
export 'surfaces/surfaces.dart';

// Feedback layer — states, errors, notifications
export 'feedback/feedback.dart';
```

**NOTE**: `layout/` and `animation/` sub-barrels are added in Phase 2 (layout) and Phase 5 (animation). If Phase 2 already added them, include:
```dart
// Layout layer (Phase 2, if present)
// export 'layout/layout.dart';

// Animation layer (Phase 5, not yet created)
// export 'animation/animation.dart';
```

The implementing agent must check which sub-barrels actually exist and include only those that are ready.

---

#### Step 3.11.2: Run `dart fix --apply` for import cleanup

```
pwsh -Command "dart fix --apply --code=directives_ordering lib/core/design_system/"
```

This sorts and cleans up import directives in all moved/new files.

---

#### Step 3.11.3: Full analyzer verification

```
pwsh -Command "flutter analyze"
```

Expected: Zero analyzer errors. Warnings from existing code (not introduced by Phase 3) are acceptable.

If analyzer errors appear:
1. Check for missing imports in moved files (relative path depth changed from `../` to `../../`)
2. Check for circular barrel imports (no sub-barrel should import from the main barrel)
3. Check that deleted files are no longer referenced anywhere
4. Check that the `intl` package dependency exists in `pubspec.yaml` for `AppDatePicker` (it already does — used by other features)

---

#### Step 3.11.4: Verify barrel exports cover all files

Run a quick sanity check that all files in each sub-directory are exported:

```
pwsh -Command "flutter analyze lib/core/design_system/design_system.dart"
```

Expected: No issues found. If there are "unused import" warnings, a file was missed from a barrel.

---

### Phase 3 Summary

**Files created** (20 new):
- `lib/core/design_system/atoms/app_button.dart`
- `lib/core/design_system/atoms/app_badge.dart`
- `lib/core/design_system/atoms/app_divider.dart`
- `lib/core/design_system/atoms/app_avatar.dart`
- `lib/core/design_system/atoms/app_tooltip.dart`
- `lib/core/design_system/molecules/app_dropdown.dart`
- `lib/core/design_system/molecules/app_date_picker.dart`
- `lib/core/design_system/molecules/app_tab_bar.dart`
- `lib/core/design_system/molecules/app_search_bar.dart`
- `lib/core/design_system/organisms/app_stat_card.dart`
- `lib/core/design_system/organisms/app_action_card.dart`
- `lib/core/design_system/organisms/app_form_section.dart`
- `lib/core/design_system/organisms/app_form_section_nav.dart`
- `lib/core/design_system/organisms/app_form_status_bar.dart`
- `lib/core/design_system/organisms/app_form_field_group.dart`
- `lib/core/design_system/organisms/app_form_summary_tile.dart`
- `lib/core/design_system/organisms/app_form_thumbnail.dart`
- `lib/core/design_system/feedback/app_snackbar.dart`
- `lib/core/design_system/feedback/app_contextual_feedback.dart`
- `lib/core/design_system/feedback/app_banner.dart`

**Files moved** (18 from flat to sub-dirs):
- 6 atoms: `app_text.dart`, `app_icon.dart`, `app_chip.dart`, `app_toggle.dart`, `app_progress_bar.dart`, `app_mini_spinner.dart`
- 4 molecules: `app_text_field.dart`, `app_counter_field.dart`, `app_list_tile.dart`, `app_section_header.dart`
- 4 organisms: `app_glass_card.dart`, `app_section_card.dart`, `app_photo_grid.dart`, `app_info_banner.dart`
- 6 surfaces: `app_scaffold.dart`, `app_bottom_bar.dart`, `app_bottom_sheet.dart`, `app_dialog.dart`, `app_sticky_header.dart`, `app_drag_handle.dart`
- 4 feedback: `app_empty_state.dart`, `app_error_state.dart`, `app_loading_state.dart`, `app_budget_warning_chip.dart`

**Files deleted** (4):
- `lib/shared/widgets/search_bar_field.dart` (migrated to AppSearchBar)
- `lib/shared/widgets/contextual_feedback_overlay.dart` (migrated to AppContextualFeedback)
- `lib/shared/widgets/empty_state_widget.dart` (merged into AppEmptyState)
- `lib/shared/widgets/confirmation_dialog.dart` (merged into AppDialog static methods)
- `lib/shared/utils/snackbar_helper.dart` (migrated to AppSnackbar)

**Files modified** (6):
- `lib/core/design_system/design_system.dart` (main barrel restructured)
- `lib/core/design_system/surfaces/app_dialog.dart` (added confirmation methods)
- `lib/shared/widgets/widgets.dart` (removed migrated exports)
- `lib/features/entries/presentation/controllers/pdf_data_builder.dart` (SnackBarHelper -> AppSnackbar)
- `lib/features/settings/presentation/screens/consent_screen.dart` (SnackBarHelper -> AppSnackbar)
- `lib/features/settings/presentation/screens/legal_document_screen.dart` (SnackBarHelper -> AppSnackbar)

**Barrel files updated** (7):
- `lib/core/design_system/atoms/atoms.dart`
- `lib/core/design_system/molecules/molecules.dart`
- `lib/core/design_system/organisms/organisms.dart`
- `lib/core/design_system/surfaces/surfaces.dart`
- `lib/core/design_system/feedback/feedback.dart`
- `lib/core/design_system/design_system.dart`
- `lib/shared/widgets/widgets.dart`

**NOT deleted in Phase 3** (deferred to Phase 4):
- `lib/shared/widgets/stale_config_warning.dart` (will be recomposed from AppBanner)
- `lib/shared/widgets/version_banner.dart` (will be recomposed from AppBanner)
