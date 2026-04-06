# Pattern: ThemeExtension Token

## How We Do It
Token sets are implemented as `ThemeExtension<T>` subclasses with const variant instances (one per theme), a `copyWith()` using sentinel pattern, a `lerp()` for animated transitions, and a static `of(context)` convenience accessor. Registered on `ThemeData.extensions` in `AppTheme`.

## Exemplar: FieldGuideColors (`lib/core/theme/field_guide_colors.dart`)

```dart
class FieldGuideColors extends ThemeExtension<FieldGuideColors> {
  const FieldGuideColors({
    required this.surfaceElevated,
    required this.surfaceGlass,
    // ... 16 fields total
  });

  final Color surfaceElevated;
  final Color surfaceGlass;
  // ...

  // Const variant instances
  static const dark = FieldGuideColors(
    surfaceElevated: AppColors.surfaceElevated,
    // ...
  );
  static const light = FieldGuideColors(
    surfaceElevated: AppColors.lightSurfaceElevated,
    // ...
  );

  // Convenience accessor
  static FieldGuideColors of(BuildContext context) {
    return Theme.of(context).extension<FieldGuideColors>() ?? dark;
  }

  // Sentinel-based copyWith
  static const _sentinel = Object();
  @override
  FieldGuideColors copyWith({
    Object? surfaceElevated = _sentinel,
    // ...
  }) {
    return FieldGuideColors(
      surfaceElevated: identical(surfaceElevated, _sentinel)
          ? this.surfaceElevated
          : surfaceElevated! as Color,
      // ...
    );
  }

  // Animated lerp
  @override
  FieldGuideColors lerp(FieldGuideColors? other, double t) {
    if (other is! FieldGuideColors) return this;
    return FieldGuideColors(
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      // ...
    );
  }
}
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `FieldGuideColors.of` | `field_guide_colors.dart:149` | `static FieldGuideColors of(BuildContext context)` | Access semantic colors in any widget |
| `FieldGuideColors.copyWith` | `field_guide_colors.dart:159` | `FieldGuideColors copyWith({...})` | Override specific fields for variant |
| `FieldGuideColors.lerp` | `field_guide_colors.dart:196` | `FieldGuideColors lerp(FieldGuideColors? other, double t)` | Theme animation interpolation |

## Imports
```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/theme/colors.dart'; // for AppColors references
```

## New Extensions to Create (same pattern)

| Extension | Field Types | Variant Strategy |
|-----------|------------|-----------------|
| `FieldGuideSpacing` | `double` fields | `lerp` uses `lerpDouble` |
| `FieldGuideRadii` | `double` fields | Single variant (no density change) |
| `FieldGuideMotion` | `Duration` + `Curve` fields | `reduced` variant: durations=zero, curves=linear |
| `FieldGuideShadows` | `List<BoxShadow>` fields | `flat` variant: all empty lists |
