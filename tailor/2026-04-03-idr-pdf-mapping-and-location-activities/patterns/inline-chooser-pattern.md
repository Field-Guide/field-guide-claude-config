# Pattern: Inline Chooser (Chip Selection)

## How We Do It
Inline selection widgets are used when the user needs to pick from a small set of project-scoped items directly within a card or section — no navigation to a separate screen. The pattern uses a list of selectable tiles with check icons, wrapped in a container with Done/Cancel actions.

## Exemplar: _InlineContractorChooser

**File**: `lib/features/entries/presentation/widgets/entry_contractors_section.dart:454-585`

Key aspects:
- `availableContractors` list + `selectedIds` set + `onToggle` callback
- Each item rendered as an `InkWell` with conditional border/background for selected state
- Check icon shown when selected: `Icon(Icons.check_circle, color: cs.primary, size: 20)`
- Done/Cancel action row at bottom
- Uses `DesignConstants` for spacing, `FieldGuideColors.of(context)` for accent colors
- Keyed with `TestingKeys` for E2E automation

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| `_InlineContractorChooser` | `entry_contractors_section.dart:454` | `class _InlineContractorChooser extends StatelessWidget` | Exemplar for any inline multi-select within a card |
| `ContractorsTestingKeys.contractorEquipmentChip` | `contractors_keys.dart:61` | `static Key contractorEquipmentChip(String equipmentId)` | Pattern for dynamic testing keys |

## Imports
```dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/shared/testing_keys/testing_keys.dart';
```

## Adaptation for Location Selector
The location chooser will be simpler than the contractor chooser:
- Single-select (not multi-select) — only one location active at a time
- `FilterChip` or `ChoiceChip` instead of full tile cards (locations are just names, no subtypes)
- Shown inline above the activities text field, not in a separate container
- Only appears when project has 2+ locations
