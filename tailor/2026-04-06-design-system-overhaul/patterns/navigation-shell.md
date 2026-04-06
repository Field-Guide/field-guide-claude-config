# Pattern: Navigation Shell

## How We Do It
The app uses GoRouter with a `ShellRoute` wrapping `ScaffoldWithNavBar`. The shell provides persistent bottom navigation, banner management (version, stale config, offline, sync errors), and the project switcher. Navigation destinations are hardcoded as `NavigationDestination` widgets.

## Exemplar: ScaffoldWithNavBar (`lib/core/router/scaffold_with_nav_bar.dart`)

Key elements:
- `StatelessWidget` with `final Widget child` from GoRouter shell
- Uses `FieldGuideColors.of(context)` for themed colors
- Uses `Consumer2<SyncProvider, AppConfigProvider>` for banner state
- `NavigationBar` with 4 destinations (Dashboard, Calendar, Projects, Settings)
- Project switcher shown on routes `{'/', '/calendar'}` only
- `_calculateSelectedIndex()` maps route path to nav index
- `_onItemTapped()` uses `context.goNamed()` for navigation

## Responsive Adaptation Target

| Breakpoint | Current | Target |
|------------|---------|--------|
| `compact` (0-599) | `NavigationBar` (bottom) | Same — keep bottom nav |
| `medium` (600-839) | `NavigationBar` (bottom) | `NavigationRail` collapsed (icons only) |
| `expanded` (840-1199) | `NavigationBar` (bottom) | `NavigationRail` expanded (icons + labels) |
| `large` (1200+) | `NavigationBar` (bottom) | `NavigationRail` expanded (icons + labels) |

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `_calculateSelectedIndex` | `scaffold_with_nav_bar.dart:176` | `int _calculateSelectedIndex(BuildContext context)` | Map route to nav index |
| `_onItemTapped` | `scaffold_with_nav_bar.dart:183` | `void _onItemTapped(int index, BuildContext context)` | Handle nav tap |
| `_shellPage` | `app_router.dart:83` | `static Page<void> _shellPage(LocalKey key, Widget child)` | Consistent fade transition for shell routes |
| `_fadeTransition` | `app_router.dart:92` | `static Widget _fadeTransition(...)` | Fade transition builder |

## Imports
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/shared/testing_keys/testing_keys.dart';
```
