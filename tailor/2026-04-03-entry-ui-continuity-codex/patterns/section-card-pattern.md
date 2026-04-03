# Pattern: Section Card

## How We Do It
Entry editor sections use `AppSectionCard` from the design system for consistent header-strip cards with icon + title + body content. The card supports collapsible mode and trailing widgets. All section cards in the entry editor use this pattern or a local Card + header Row equivalent.

## Exemplars

### AppSectionCard (lib/core/design_system/app_section_card.dart:19-144)
```dart
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.headerColor,
    this.headerGradient,
    this.trailing,
    this.padding,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });
  // ...builds Container with colored header strip + body
}
```

### EntryQuantitiesSection (lib/features/entries/presentation/widgets/entry_quantities_section.dart:32-492)
Uses a local Card + icon/title Row instead of AppSectionCard — this is the inconsistency the spec targets.
```dart
Card(
  key: TestingKeys.reportQuantitiesSection,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Row(children: [
        Icon(Icons.inventory_2_outlined, color: cs.primary),
        const SizedBox(width: 8),
        Text('Pay Items Used', style: tt.titleSmall!.copyWith(fontWeight: FontWeight.bold)),
      ]),
      const Divider(height: 24),
      // ... quantities list
    ]),
  ),
)
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| AppSectionCard constructor | app_section_card.dart:20 | `const AppSectionCard({icon, title, child, headerColor?, trailing?, collapsible?, initiallyExpanded?})` | Any section card with colored header strip |
| AppSectionCard._buildHeader | app_section_card.dart:107 | `static Widget _buildHeader({icon, title, headerColor, headerGradient?, trailing?, cs, tt})` | Reusable header strip widget |

## Imports
```dart
import 'package:construction_inspector/core/design_system/design_system.dart';
```
