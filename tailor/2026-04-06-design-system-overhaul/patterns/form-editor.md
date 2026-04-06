# Pattern: Form Editor Components

## How We Do It
Form editor UI is built from composable widgets: `FormAccordion` for collapsible sections with status indicators, `StatusPillBar` for section navigation, `SummaryTiles` for read-only value display, and `FormThumbnail` for mini previews. These are currently in `features/forms/presentation/widgets/` — the spec promotes generic versions to `design_system/organisms/`.

## Exemplar: FormAccordion (`lib/features/forms/presentation/widgets/form_accordion.dart`)

```dart
enum HubSectionStatus { notStarted, inProgress, complete, locked }

class FormAccordion extends StatelessWidget {
  const FormAccordion({
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
  // ... build method with _LetterBadge and _StatusBadge private widgets
}
```

Private widgets to extract: `_LetterBadge` (line 117), `_StatusBadge` (line 144)

## Exemplar: StatusPillBar (`lib/features/forms/presentation/widgets/status_pill_bar.dart`)

```dart
class StatusPillItem {
  const StatusPillItem({
    required this.id,
    required this.label,
    required this.status,
    required this.accentColor,
    this.key,
  });
}

class StatusPillBar extends StatelessWidget {
  const StatusPillBar({super.key, required this.items});
  final List<StatusPillItem> items;
  // ... builds horizontal scrollable pill list
}
```

## Exemplar: SummaryTiles (`lib/features/forms/presentation/widgets/summary_tiles.dart`)

```dart
class SummaryTileData {
  const SummaryTileData({required this.label, required this.value});
}

class SummaryTiles extends StatelessWidget {
  const SummaryTiles({super.key, required this.tiles});
  final List<SummaryTileData> tiles;
  // ... builds grid of label:value pairs
}
```

## Promotion Plan

| Current Widget | Design System Target | Changes |
|---------------|---------------------|---------|
| `FormAccordion` | `AppFormSection` (organism) | Generalize: remove form-specific terminology, use tokens |
| StatusPillBar section nav | `AppFormSectionNav` (organism) | Add sidebar variant for tablet, pills for phone |
| `StatusPillBar` | `AppFormStatusBar` (organism) | Generalize completion/validation summary |
| Hub field grouping pattern | `AppFormFieldGroup` (organism) | Extract pattern: label, help text, responsive columns |
| `SummaryTiles` | `AppFormSummaryTile` (organism) | Generalize read-only display |
| `FormThumbnail` | `AppFormThumbnail` (organism) | Keep API, move + tokenize |

## Imports
```dart
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
```
