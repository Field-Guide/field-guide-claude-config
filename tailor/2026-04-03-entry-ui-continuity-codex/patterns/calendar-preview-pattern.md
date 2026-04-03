# Pattern: Calendar Report Preview (to be simplified)

## How We Do It
`HomeScreen` shows a calendar with entry pills. When a day with entries is selected, inline editable preview sections render below the calendar. Each section uses `_buildEditablePreviewSection()` which renders a tap-to-edit container with view/edit child slots. The contractors section (`_buildContractorsSection`) is a full editor with add/remove/edit capabilities including its own `_showAddContractorDialog()` and `_buildContractorEditorRow()`.

**The spec removes ALL of this inline editing and replaces it with read-only pills that navigate to the full editor.**

## Exemplars

### _buildEditablePreviewSection (home_screen.dart:1269-1331)
Generic inline editing container used 4 times for weather, activities, safety, and visitors:
```dart
Widget _buildEditablePreviewSection({
  required EntrySection section,
  required String sectionKey,
  required String title,
  required IconData icon,
  required DailyEntry entry,
  required int delay,
  required Widget viewChild,
  required Widget editChild,
}) {
  // GestureDetector toggles editing
  // AnimatedContainer shows editing border
  // isEditing ? editChild : viewChild
}
```
Called at lines: 1063, 1139, 1169, 1225

### _buildContractorsSection (home_screen.dart:1334-1496)
Full contractor editing section with:
- Personnel/equipment summary
- ContractorEditorWidget for each contractor
- Add contractor button
- Inline sort (prime first, then by name)

### _showAddContractorDialog (home_screen.dart:1582-1665)
Inline bottom sheet with ListTile rows for contractor selection (duplicates `showReportAddContractorSheet` logic).

## Methods to Remove (spec H)

| Method | File:Line | Reason |
|--------|-----------|--------|
| _buildEditablePreviewSection | home_screen.dart:1269 | No inline editing in calendar |
| _buildContractorsSection | home_screen.dart:1334 | No contractor editing in calendar |
| _buildContractorEditorRow | home_screen.dart:1498 | No contractor editing in calendar |
| _showAddContractorDialog | home_screen.dart:1582 | No contractor adding in calendar |

## Imports
```dart
import 'package:construction_inspector/features/entries/presentation/widgets/contractor_editor_widget.dart';
// ^ This import can be REMOVED from home_screen.dart after spec H
```
