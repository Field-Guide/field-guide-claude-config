# Pattern: Contractor Editor Widget

## How We Do It
`ContractorEditorWidget` is a shared StatelessWidget used in three contexts: entry editing (via `EntryContractorsSection`), calendar preview (inline in `HomeScreen`), and project setup (`ProjectSetupScreen` with `setupMode=true`). The widget takes mode flags (`isEditing`, `setupMode`) and callback closures to handle personnel count changes, equipment selection, and personnel type management. The parent manages all state and passes it down.

## Exemplars

### ContractorEditorWidget (lib/features/entries/presentation/widgets/contractor_editor_widget.dart:10-557)
Key constructor parameters:
```dart
const ContractorEditorWidget({
  required this.contractorId,
  required this.contractor,        // Contractor? model
  required this.counts,            // Map<String, int> typeId -> count
  required this.equipmentNames,    // List<String> display names
  required this.personnelTypes,    // List<PersonnelType>
  required this.contractorEquipment, // List<Equipment>
  required this.isEditing,         // view vs edit mode
  required this.editingEquipmentIds, // Set<String>
  required this.editingCounts,     // Map<String, int>
  required this.onTap,             // start editing
  required this.onDone,            // finish editing
  required this.onCountChanged,    // (typeId, count)
  required this.onEquipmentChanged, // (equipmentId, selected)
  this.onAddPersonnelType,         // setup mode only
  this.onDeletePersonnelType,      // setup mode only
  this.onAddEquipment,             // setup mode only
  this.setupMode = false,          // project setup vs entry editing
  this.onEditContractor,           // optional edit metadata
  this.onDeleteContractor,         // optional delete
})
```

### Usage in EntryContractorsSection (entry_contractors_section.dart)
The section widget wraps ContractorEditorWidget for each contractor, managing state via `EntryContractorsController`.

### Usage in ProjectSetupScreen (project_setup_screen.dart)
```dart
ContractorEditorWidget(
  // ... same params but with setupMode: true
  setupMode: true,
  onAddPersonnelType: (name) async { /* creates type */ },
  onDeletePersonnelType: (typeId) async { /* deletes type */ },
  onAddEquipment: () async { /* shows equipment dialog */ },
)
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| ContractorEditorWidget constructor | contractor_editor_widget.dart:44 | See above | Render contractor card in any mode |
| _buildContractorEditorRow | home_screen.dart:1498 | `Widget _buildContractorEditorRow(String contractorId, Map<String, dynamic> data)` | Calendar report preview (TO BE REMOVED) |

## Imports
```dart
import 'package:construction_inspector/features/entries/presentation/widgets/contractor_editor_widget.dart';
import 'package:construction_inspector/features/contractors/data/models/models.dart';
```
