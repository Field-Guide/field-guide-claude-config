# Dependency Graph

## Direct Changes (Files to Modify)

| File | Key Symbols | Change Type |
|------|-------------|-------------|
| `lib/features/entries/presentation/widgets/contractor_editor_widget.dart` | ContractorEditorWidget (10-557) | Refactor: mode-based layout skeleton |
| `lib/features/entries/presentation/widgets/entry_contractors_section.dart` | EntryContractorsSection (21-*) | Refactor: use shared contractor selection |
| `lib/features/entries/presentation/screens/home_screen.dart` | HomeScreen, _HomeScreenState (33-*) | Simplify: remove inline editing, remove contractor editor |
| `lib/features/projects/presentation/screens/project_setup_screen.dart` | ProjectSetupScreen (818-832) | Refactor: replace popup dialog with create-then-setup flow |
| `lib/features/entries/presentation/screens/entry_editor_screen.dart` | _EntryEditorScreenState (50-*) | Modify: header rework, calculator relocation, debug removal |
| `lib/features/entries/presentation/widgets/entry_quantities_section.dart` | EntryQuantitiesSection (16-492) | Add: calculator affordance in header |
| `lib/features/entries/presentation/screens/report_widgets/report_pdf_actions_dialog.dart` | showReportPdfActionsDialog (13-93) | Modify: preview-first flow |
| `lib/features/entries/presentation/screens/report_widgets/report_debug_pdf_actions_dialog.dart` | showReportDebugPdfActionsDialog (12-82) | Remove from active UI |
| `lib/features/entries/presentation/widgets/entry_basics_section.dart` | EntryBasicsSection (11-209) | Dead code: 0 importers, has auto-fetch button |

## New Files (Proposed)

| File | Purpose |
|------|---------|
| `lib/features/contractors/presentation/widgets/contractor_selection_sheet.dart` | Shared contractor selection bottom sheet |
| `lib/features/entries/presentation/screens/entry_pdf_preview_screen.dart` | In-app PDF preview screen for entries |

## Dependency Graph: ContractorEditorWidget

```
ContractorEditorWidget (contractor_editor_widget.dart)
  IMPORTS:
    ├── design_system.dart
    ├── design_constants.dart
    ├── field_guide_colors.dart
    ├── contractors/data/models/models.dart (Contractor, Equipment, PersonnelType)
    └── shared/shared.dart
  IMPORTED BY:
    ├── entry_contractors_section.dart (2 references)
    └── project_setup_screen.dart (1 reference)
```

## Dependency Graph: EntryEditorScreen (100 nodes, 153 edges at depth 2)

```
EntryEditorScreen (entry_editor_screen.dart)
  KEY IMPORTS:
    ├── entry_contractors_section.dart → contractor_editor_widget.dart
    ├── entry_quantities_section.dart
    ├── report_pdf_actions_dialog.dart
    ├── report_debug_pdf_actions_dialog.dart
    ├── pdf_data_builder.dart → pdf_service.dart
    ├── entry_export_provider.dart → export_entry_use_case.dart
    ├── weather/services/weather_service.dart (NOT directly imported)
    ├── calculator/presentation/providers/calculator_provider.dart
    └── quantities/presentation/screens/quantity_calculator_screen.dart
  IMPORTED BY:
    └── (via router: entry_routes.dart, not direct import)
```

## Dependency Graph: HomeScreen (70 nodes, 97 edges at depth 2)

```
HomeScreen (home_screen.dart)
  KEY IMPORTS:
    ├── contractor_editor_widget.dart (for calendar report preview)
    ├── entry_contractors_section.dart (NOT imported — duplicates logic inline)
    ├── report_add_contractor_sheet.dart (NOT imported — duplicates inline)
    ├── daily_entry_provider.dart
    ├── calendar_format_provider.dart
    └── contractor controller types (ContractorProvider, EquipmentProvider, etc.)
  IMPORTED BY:
    └── (via router: name 'home', line 132 of app_router.dart)
```

## Dependency Graph: ProjectSetupScreen (77 nodes, 118 edges at depth 2)

```
ProjectSetupScreen (project_setup_screen.dart)
  KEY IMPORTS:
    ├── contractor_editor_widget.dart (1 reference, setupMode=true)
    ├── add_contractor_dialog.dart → AddContractorDialog.show()
    ├── contractor models (contractor.dart, equipment.dart, personnel_type.dart)
    └── providers (ContractorProvider, EquipmentProvider, PersonnelTypeProvider)
  IMPORTED BY:
    └── (via router: project_routes.dart, lines 14, 23)
```

## Dependency Graph: PdfService (18 nodes, 23 edges at depth 2)

```
PdfService (pdf_service.dart)
  IMPORTS:
    ├── logger.dart
    ├── entries/data/models/models.dart
    ├── projects/data/models/models.dart
    ├── contractors/data/models/models.dart
    ├── quantities/data/models/models.dart
    ├── photos/data/models/photo.dart
    ├── forms/data/models/models.dart
    ├── forms/data/services/form_pdf_service.dart
    ├── photo_pdf_service.dart
    ├── permission_service.dart
    └── app_terminology.dart
```

## Data Flow Diagram

```
┌──────────────────┐     ┌───────────────────────┐     ┌──────────────────────┐
│   HomeScreen     │     │  EntryEditorScreen     │     │ ProjectSetupScreen   │
│ (calendar view)  │     │  (entry editing)       │     │ (project config)     │
│                  │     │                        │     │                      │
│ _buildEditable   │     │ _buildEntryHeader()    │     │ _showAddContractor   │
│ PreviewSection() │     │ EntryContractors       │     │   Dialog() →         │
│ _buildContractors│     │   Section              │     │   AddContractor      │
│   Section()      │     │ EntryQuantities        │     │   Dialog.show()      │
│ _showAddContrac  │     │   Section              │     │                      │
│   torDialog()    │     │ _showPdfActions        │     │ ContractorEditor     │
│                  │     │   Dialog()             │     │   Widget(setupMode)  │
│ ContractorEditor │     │                        │     │                      │
│   Widget         │     │ ContractorEditor       │     └──────────────────────┘
│   (inline)       │     │   Widget (via section) │
└──────────────────┘     └───────────────────────┘
         │                        │                           │
         ▼                        ▼                           ▼
┌──────────────────────────────────────────────────────────────────┐
│              ContractorEditorWidget (shared)                     │
│  - View mode (isEditing=false)                                  │
│  - Edit mode (isEditing=true)                                   │
│  - Setup mode (setupMode=true)                                  │
└──────────────────────────────────────────────────────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌──────────────────────┐
│ Contractor      │    │ Personnel/Equipment  │
│ Models          │    │ Providers            │
└─────────────────┘    └──────────────────────┘
```

## WeatherService Import Chain

```
WeatherService (weather_service.dart)
  IMPORTED BY:
    ├── remaining_deps_initializer.dart (DI bootstrap)
    ├── app_dependencies.dart (DI container)
    ├── weather_summary_card.dart (dashboard widget)
    ├── weather_providers.dart (DI)
    ├── weather_service_interface.dart (domain interface)
    ├── weather_provider.dart (state management)
    └── dashboard_widgets_test.dart (test)
  NOT IMPORTED BY:
    └── entry_editor_screen.dart (weather auto-fetch NOT wired)
```
