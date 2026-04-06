# Pattern: Screen Decomposition

## How We Do It
Large screens (>300 lines) are decomposed by extracting private `_build*` methods into standalone widget files in the feature's `presentation/widgets/` directory. The main screen file retains state management, lifecycle, and orchestration. Extracted widgets receive data via constructor parameters.

## Priority Screens (by line count)

| # | Screen | Lines | Methods in State | Files to Extract |
|---|--------|-------|-----------------|-----------------|
| 1 | `entry_editor_screen.dart` | 1,857 | ~40+ | ~6 widgets |
| 2 | `project_setup_screen.dart` | 1,436 | ~30+ | ~5 widgets |
| 3 | `home_screen.dart` | 1,270 | ~25+ | ~4 widgets |
| 4 | `mdot_hub_screen.dart` | 1,198 | 37 methods, 5 screen classes | ~5 screens + form primitives |
| 5 | `project_list_screen.dart` | 1,196 | ~20+ | ~4 widgets |
| 6 | `contractor_editor_widget.dart` | 1,099 | ~20+ | ~3 widgets + 2 dialogs |
| 7 | `todos_screen.dart` | 891 | ~15+ | ~3 widgets |
| 8 | `calculator_screen.dart` | 712 | ~15+ | ~3 widgets |
| 9 | `project_dashboard_screen.dart` | 696 | ~12+ | ~3 widgets |
| 10 | `quantity_calculator_screen.dart` | 656 | ~10+ | ~2 widgets |
| 11 | `form_viewer_screen.dart` | 636 | ~10+ | ~2 widgets |

## Decomposition Protocol

1. **Component discovery sweep** — grep for private `_*Card`, `_*Tile`, `_*Row`, `_*Badge`, `_*Banner`, `_*Dialog`, `_*Sheet` classes
2. **Promote shared patterns** — patterns in 2+ features → design system
3. **Extract private widgets** — `_build*` methods → standalone widget files
4. **Tokenize** — replace all magic numbers, hardcoded colors, inline styles
5. **Sliver-ify** — convert scrolling to `CustomScrollView` + slivers
6. **Selector-ify** — replace `Consumer` with `Selector`
7. **Add motion** — staggered entrances, tap feedback, transitions
8. **Responsive layout** — `AppResponsiveBuilder` / canonical layout
9. **Close issues** — fix GitHub issues touching this screen
10. **Update HTTP driver** — driver endpoints and testing keys
11. **Update logs** — new components log via `Logger`

## Existing Decomposed Examples

### Form widgets (already extracted from mdot_hub_screen):
- `hub_header_content.dart` (119 lines) — field display
- `hub_quick_test_content.dart` (239 lines) — quick test form
- `hub_proctor_content.dart` (486 lines — still oversized, target: ~250)
- `form_accordion.dart` — collapsible section with status
- `status_pill_bar.dart` — section status indicators
- `summary_tiles.dart` — compact read-only values
- `form_thumbnail.dart` — mini preview card

### Dashboard widgets (already extracted):
- `dashboard_stat_card.dart` — animated stat card
- `weather_summary_card.dart` — weather display
- `budget_overview_card.dart` — budget overview with stat boxes
- `todays_entry_card.dart` — today's entry CTA
- `alert_item_row.dart` — alert row
- `tracked_item_row.dart` — tracked item row

## Imports for Extracted Widgets
```dart
// Extracted widget imports the design system barrel
import 'package:construction_inspector/core/design_system/design_system.dart';
// Plus feature-specific imports as needed
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
```
