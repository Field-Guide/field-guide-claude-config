# Pattern: Theme Builder (Data-Driven)

## How We Do It (Current — to be replaced)
Currently `AppTheme` has 3 giant static getters (`darkTheme`, `lightTheme`, `highContrastTheme`) each duplicating ~600 lines of `ThemeData` construction with copy-pasted component themes. This monolithic approach is error-prone and hard to maintain.

## Current Structure (`lib/core/theme/app_theme.dart`, 1,777 lines)

```
AppTheme class:
  - Line 9: class declaration
  - Line 173-810: darkTheme getter (~637 lines)
  - Line 811-1264: lightTheme getter (~453 lines)
  - Line 1265-1777: highContrastTheme getter (~512 lines, TO DELETE)
```

Each getter builds a complete `ThemeData` including:
- `ColorScheme`
- Component themes: `AppBarTheme`, `CardTheme`, `InputDecorationTheme`, `ElevatedButtonTheme`, `TextButtonTheme`, `OutlinedButtonTheme`, `IconButtonTheme`, `NavigationBarThemeData`, `ChipThemeData`, `BottomSheetThemeData`, `DialogTheme`, `FloatingActionButtonThemeData`, `DividerThemeData`, `ListTileThemeData`, `SwitchThemeData`, `CheckboxThemeData`, `TabBarTheme`, `PopupMenuThemeData`, `SnackBarThemeData`
- `extensions: [FieldGuideColors.dark]` (or `.light`/`.highContrast`)

## Target Pattern: Data-Driven Builder

```dart
class AppTheme {
  static ThemeData build({
    required ColorScheme colorScheme,
    required FieldGuideColors colors,
    required FieldGuideSpacing spacing,
    required FieldGuideRadii radii,
    required FieldGuideMotion motion,
    required FieldGuideShadows shadows,
  }) {
    return ThemeData(
      colorScheme: colorScheme,
      extensions: [colors, spacing, radii, motion, shadows],
      // Component themes use token parameters...
    );
  }

  static ThemeData get darkTheme => build(
    colorScheme: _darkColorScheme,
    colors: FieldGuideColors.dark,
    spacing: FieldGuideSpacing.standard,
    radii: FieldGuideRadii.standard,
    motion: FieldGuideMotion.standard,
    shadows: FieldGuideShadows.standard,
  );

  static ThemeData get lightTheme => build(
    colorScheme: _lightColorScheme,
    colors: FieldGuideColors.light,
    spacing: FieldGuideSpacing.standard,
    radii: FieldGuideRadii.standard,
    motion: FieldGuideMotion.standard,
    shadows: FieldGuideShadows.standard,
  );
}
```

This collapses ~1,777 lines to <400 by eliminating duplication across themes.

## Key Observations
- `ThemeProvider.currentTheme` switch on `AppThemeMode` must be updated from 3 cases to 2
- `ThemeProvider._loadTheme` already has safe deserialization — old `highContrast` values fall back to `dark`
- Test helpers (`testWidgetInAllThemes`) must be updated to test only dark + light
- 26 golden test files reference `AppTheme` directly
