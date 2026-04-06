# Pattern: Provider State Management

## How We Do It
State management uses `ChangeNotifier` via the `provider` package. Providers extend `ChangeNotifier`, expose getters with guard-based `notifyListeners()`, and are consumed in widgets via `Consumer`, `context.watch`, or `context.read`. The spec targets replacing broad `Consumer<Provider>` with `Selector<Provider, T>` for surgical rebuilds.

## Exemplar: ThemeProvider (`lib/features/settings/presentation/providers/theme_provider.dart`)

```dart
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  AppThemeMode _themeMode = AppThemeMode.dark;
  bool _isLoading = true;

  ThemeProvider() {
    unawaited(_loadTheme());
  }

  AppThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDark => _themeMode == AppThemeMode.dark;

  ThemeData get currentTheme {
    switch (_themeMode) {
      case AppThemeMode.light: return AppTheme.lightTheme;
      case AppThemeMode.dark: return AppTheme.darkTheme;
      case AppThemeMode.highContrast: return AppTheme.highContrastTheme;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;  // Guard: no-op if unchanged
    _themeMode = mode;
    notifyListeners();
    // Persist...
  }
}
```

## Target Pattern: Selector-based Consumption

**Current (broad rebuild):**
```dart
Consumer<DashboardProvider>(
  builder: (context, provider, _) {
    return Column(children: [
      Text(provider.projectName),  // Only needs this
      // ... 200 lines of UI
    ]);
  },
)
```

**Target (surgical rebuild):**
```dart
Selector<DashboardProvider, String>(
  selector: (_, p) => p.projectName,
  builder: (context, projectName, child) {
    return Text(projectName);
  },
)
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `ThemeProvider.setThemeMode` | `theme_provider.dart:88` | `Future<void> setThemeMode(AppThemeMode mode)` | Change theme with persistence |
| `ThemeProvider.cycleTheme` | `theme_provider.dart:103` | `Future<void> cycleTheme()` | Cycle through available themes |
| Guard pattern | Any provider setter | `if (value == _value) return;` | Prevent unnecessary rebuilds |

## Imports
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
```
