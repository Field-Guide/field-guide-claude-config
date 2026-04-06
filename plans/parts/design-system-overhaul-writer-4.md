## Phase 4a: UI Decomposition -- Priority Screens 1-6

**IMPORTANT**: This phase assumes Phases 1-3 are complete. Token ThemeExtensions (`FieldGuideSpacing`, `FieldGuideRadii`, `FieldGuideMotion`, `FieldGuideShadows`) are registered on `ThemeData.extensions` and accessible via `.of(context)`. The `AppResponsiveBuilder` layout widget exists in `lib/core/design_system/layout/`. The design system barrel at `lib/core/design_system/design_system.dart` re-exports all tokens, atoms, molecules, organisms, surfaces, feedback, layout, and animation sub-barrels.

**NOTE**: Each sub-phase follows the 11-step decomposition protocol: (1) component discovery, (2) promote shared patterns, (3) extract private widgets, (4) tokenize, (5) sliver-ify, (6) selector-ify, (7) add motion, (8) responsive layout, (9) close issues, (10) update HTTP driver, (11) update logs. Steps are collapsed where not applicable.

---

### Sub-phase 4.1: entry_editor_screen.dart (1,857 lines -> ~300 + 6 widgets)

**Agent**: `code-fixer-agent`
**File**: `lib/features/entries/presentation/screens/entry_editor_screen.dart`

This is the highest line-count file in the codebase (1,857 lines). It already has 5 extracted section widgets (`EntryActivitiesSection`, `EntryContractorsSection`, `EntryFormsSection`, `EntryPhotosSection`, `EntryQuantitiesSection`). The remaining extractable pieces are: the app bar, the entry header, the safety section card, and the main build orchestration. The screen uses 27 `DesignConstants` references.

#### Step 4.1.1: Component discovery sweep

Read the file and catalog all private `_build*` methods and private classes.

**Action**: Read `lib/features/entries/presentation/screens/entry_editor_screen.dart` in full. Document:

| Symbol | Line | Target |
|--------|------|--------|
| `_buildAppBar()` | 957 | Extract to `entry_editor_app_bar.dart` |
| `_buildEntryHeader(DailyEntry)` | 1059 | Extract to `entry_header_card.dart` |
| `_buildSafetySection(DailyEntry, DailyEntryProvider)` | 1600 | Keep inline (thin wrapper around `_EditableSafetyCard`) |
| `_EditableSafetyCard` | 1635 | Extract to `editable_safety_card.dart` |
| `_EditableSafetyCardState` | 1655 | Moves with `_EditableSafetyCard` |
| `_buildSections()` | 1395 | Stays in main screen (orchestration logic) |

**Verification**: No verification needed -- this is a read-only discovery step.

#### Step 4.1.2: Extract `_EditableSafetyCard` to standalone widget

**Action**: Create `lib/features/entries/presentation/widgets/editable_safety_card.dart`

```dart
// WHY: Extracted from entry_editor_screen.dart:1635-1857 to reduce main screen
// line count. This is a self-contained stateful widget with its own editing state.
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/entries/data/models/daily_entry.dart';
import 'package:construction_inspector/features/entries/presentation/controllers/entry_editing_controller.dart';

// NOTE: Made public by removing underscore prefix. Constructor and fields are
// identical to the private version at entry_editor_screen.dart:1642-1649.
class EditableSafetyCard extends StatefulWidget {
  final DailyEntry entry;
  final EntryEditingController controller;
  final Future<void> Function() onSave;
  final bool isViewer;
  final Future<void> Function()? onCopyFromLast;

  const EditableSafetyCard({
    super.key,
    required this.entry,
    required this.controller,
    required this.onSave,
    this.isViewer = false,
    this.onCopyFromLast,
  });

  @override
  State<EditableSafetyCard> createState() => _EditableSafetyCardState();
}

// NOTE: State class body is copied verbatim from entry_editor_screen.dart:1655-1857.
// Only the class name prefix changes from _ to public. All DesignConstants refs
// are tokenized in step 4.1.5.
class _EditableSafetyCardState extends State<EditableSafetyCard> {
  // ... (copy lines 1656-end from entry_editor_screen.dart verbatim,
  //      replacing _EditableSafetyCard -> EditableSafetyCard in type refs)
}
```

**Action**: In `entry_editor_screen.dart`, delete lines 1627-end (the `_EditableSafetyCard` and its state). Add import:
```dart
import 'package:construction_inspector/features/entries/presentation/widgets/editable_safety_card.dart';
```

**Action**: In `_buildSafetySection` (line 1600-1624), replace `_EditableSafetyCard` with `EditableSafetyCard`.

**Action**: Add export to `lib/features/entries/presentation/widgets/widgets.dart`:
```dart
export 'editable_safety_card.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: No errors related to `EditableSafetyCard` or missing imports.

#### Step 4.1.3: Extract `_buildEntryHeader` to standalone widget

**Action**: Create `lib/features/entries/presentation/widgets/entry_header_card.dart`

```dart
// WHY: Extracted from entry_editor_screen.dart:1059-1309. This 250-line method
// builds the entire entry header card (project name, location, weather, date,
// temperature, copy-from-last button). Standalone extraction enables reuse and
// reduces the main screen to orchestration-only.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
import 'package:construction_inspector/shared/shared.dart';
import 'package:construction_inspector/features/entries/data/models/daily_entry.dart';

/// Displays the entry header card with project name, location, weather, date,
/// and temperature fields. Supports tap-to-edit for location and weather.
class EntryHeaderCard extends StatelessWidget {
  final DailyEntry entry;
  final String? projectName;
  final String? projectNumber;
  final String? locationName;
  final bool isViewer;
  // FROM SPEC: Callbacks for inline editing -- delegated from parent screen state
  final VoidCallback? onEditLocation;
  final VoidCallback? onEditWeather;
  final VoidCallback? onEditDate;
  final Key? sectionKey;

  const EntryHeaderCard({
    super.key,
    required this.entry,
    this.projectName,
    this.projectNumber,
    this.locationName,
    this.isViewer = false,
    this.onEditLocation,
    this.onEditWeather,
    this.onEditDate,
    this.sectionKey,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: Body is the verbatim content of _buildEntryHeader from
    // entry_editor_screen.dart:1059-1309, with `context.read<AuthProvider>()`
    // calls replaced by the `isViewer` parameter passed from parent.
    // All DesignConstants refs tokenized in step 4.1.5.
    final cs = Theme.of(context).colorScheme;
    final fg = FieldGuideColors.of(context);
    final tt = Theme.of(context).textTheme;
    final dateStr = DateFormat('EEEE, MMMM d, y').format(entry.date);

    return Card(
      key: sectionKey,
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (copy lines 1075-1306 from entry_editor_screen.dart,
            //      replacing direct context.read<AuthProvider>() with isViewer,
            //      replacing _showLocationEditDialog with onEditLocation,
            //      replacing _showWeatherDialog with onEditWeather,
            //      replacing _showDatePicker with onEditDate)
          ],
        ),
      ),
    );
  }
}
```

**Action**: In `entry_editor_screen.dart`, replace `_buildEntryHeader(entry)` call at line 1425 with:
```dart
EntryHeaderCard(
  entry: entry,
  projectName: _projectName,
  projectNumber: _projectNumber,
  locationName: _locationName,
  isViewer: !context.read<AuthProvider>().canEditEntry(
    createdByUserId: entry.createdByUserId,
  ),
  onEditLocation: _showLocationEditDialog,
  onEditWeather: () => _showWeatherDialog(entry),
  onEditDate: () => _showDatePicker(entry),
  sectionKey: _sectionKeys['basics'],
),
```

Delete the `_buildEntryHeader` method (lines 1059-1309).

**Action**: Add import and export to barrel:
```dart
// In widgets.dart:
export 'entry_header_card.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.1.4: Extract `_buildAppBar` to standalone widget

**Action**: Create `lib/features/entries/presentation/widgets/entry_editor_app_bar.dart`

```dart
// WHY: Extracted from entry_editor_screen.dart:957-1053. The app bar has
// conditional logic (PDF export spinner, popup menu, draft title) that is
// self-contained and does not need parent state access beyond callbacks.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/shared/shared.dart';
import 'package:construction_inspector/features/entries/data/models/daily_entry.dart';

class EntryEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DailyEntry? entry;
  final bool isDraftEntry;
  final bool isGeneratingPdf;
  final bool canWrite;
  // FROM SPEC: Callbacks delegated from parent screen state
  final VoidCallback onExportPdf;
  final VoidCallback? onExportForms;
  final VoidCallback? onDelete;
  final VoidCallback onBack;

  const EntryEditorAppBar({
    super.key,
    required this.entry,
    required this.isDraftEntry,
    required this.isGeneratingPdf,
    required this.canWrite,
    required this.onExportPdf,
    this.onExportForms,
    this.onDelete,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = (isDraftEntry || entry == null)
        ? 'New Entry'
        : DateFormat('MMM d, y').format(entry!.date);

    return AppBar(
      title: Text(title, key: TestingKeys.reportScreenTitle),
      leading: BackButton(onPressed: onBack),
      actions: [
        // NOTE: Copy lines 978-1051 from entry_editor_screen.dart verbatim,
        // replacing _isGeneratingPdf -> isGeneratingPdf,
        // replacing _exportPdf -> onExportPdf,
        // replacing _confirmDelete -> onDelete,
        // replacing _entry -> entry
      ],
    );
  }
}
```

**Action**: In `entry_editor_screen.dart`, replace `_buildAppBar()` usage at line 1360 with:
```dart
appBar: EntryEditorAppBar(
  entry: _entry,
  isDraftEntry: _isDraftEntry,
  isGeneratingPdf: _isGeneratingPdf,
  canWrite: context.read<AuthProvider>().canEditEntry(
    createdByUserId: _entry?.createdByUserId,
  ),
  onExportPdf: _exportPdf,
  onExportForms: _entry != null ? () => _exportAllForms() : null,
  onDelete: () => _confirmDelete(),
  onBack: () => safeGoBack(context, fallbackRouteName: 'entries'),
),
```

Delete the `_buildAppBar` method (lines 957-1053).

**Action**: Add export to barrel.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.1.5: Tokenize all DesignConstants references

**Action**: In all files touched in this sub-phase (`entry_editor_screen.dart`, `entry_header_card.dart`, `editable_safety_card.dart`, `entry_editor_app_bar.dart`), replace every `DesignConstants` reference with the corresponding token accessor:

| Old Reference | New Reference |
|---------------|---------------|
| `DesignConstants.space1` | `FieldGuideSpacing.of(context).xs` |
| `DesignConstants.space2` | `FieldGuideSpacing.of(context).sm` |
| `DesignConstants.space3` | `DesignConstants.space3` |
| `DesignConstants.space4` | `FieldGuideSpacing.of(context).md` |
| `DesignConstants.space6` | `FieldGuideSpacing.of(context).lg` |
| `DesignConstants.space8` | `FieldGuideSpacing.of(context).xl` |
| `DesignConstants.radiusSmall` | `FieldGuideRadii.of(context).sm` |
| `DesignConstants.radiusMedium` | `FieldGuideRadii.of(context).md` |

**IMPORTANT**: `space3` (12.0), `space5` (20.0), `space10` (40.0), `space16` (64.0) are NOT mapped to tokens -- they remain as `DesignConstants.space3` etc. per the ground truth. Only the canonical sizes (4, 8, 16, 24, 32, 48) map to tokens.

**NOTE**: Where `DesignConstants.space*` is used inside a `const` constructor (e.g., `const EdgeInsets.all(DesignConstants.space4)`), the `const` must be removed because `FieldGuideSpacing.of(context)` is not const. Replace:
```dart
// Before:
const EdgeInsets.all(DesignConstants.space4)
// After:
EdgeInsets.all(FieldGuideSpacing.of(context).md)
```

**IMPORTANT**: For `SizedBox` spacers that use tokens, convert from const to non-const:
```dart
// Before:
const SizedBox(height: DesignConstants.space4)
// After (still using DesignConstants since SizedBox is often const):
// WHY: Keep SizedBox const where possible for performance. Only convert to
// token accessor when the widget is not in a const context.
SizedBox(height: FieldGuideSpacing.of(context).md)
```

**Action**: Also replace hardcoded `EdgeInsets.fromLTRB(16, 16, 16, 32)` at line 1370 with token-based padding:
```dart
EdgeInsets.fromLTRB(
  FieldGuideSpacing.of(context).md,
  FieldGuideSpacing.of(context).md,
  FieldGuideSpacing.of(context).md,
  FieldGuideSpacing.of(context).xl,
)
```

**Action**: Replace hardcoded `const SizedBox(height: 16)` spacers in `_buildSections()` (lines 1426, 1438, 1454, 1461, 1480, 1494, 1505) and `const SizedBox(height: 8)` (line 1422, 1513) with token-based:
```dart
SizedBox(height: FieldGuideSpacing.of(context).md), // was 16
SizedBox(height: FieldGuideSpacing.of(context).sm), // was 8
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors. No remaining `DesignConstants.space[1248]` or `DesignConstants.radius*` references in the touched files (check with grep).

#### Step 4.1.6: Responsive layout with AppResponsiveBuilder

**Action**: In `entry_editor_screen.dart`, wrap the `build` method body to support tablet/desktop layout. The current screen already uses `CustomScrollView` with slivers -- no sliver migration needed.

In the `build` method, after the `PopScope` and `AppScaffold`, wrap the body content:

```dart
// FROM SPEC: Canonical layout -- Single column (phone) -> Body + detail pane (tablet/desktop)
// WHY: On tablet, the entry header stays pinned in the left pane while
// sections scroll in the right pane. This uses the list-detail canonical layout.
body: AppResponsiveBuilder(
  compact: (context) => Column(
    children: [
      Expanded(
        child: CustomScrollView(
          key: TestingKeys.entryEditorScroll,
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                FieldGuideSpacing.of(context).md,
                FieldGuideSpacing.of(context).md,
                FieldGuideSpacing.of(context).md,
                FieldGuideSpacing.of(context).xl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(_buildSections()),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
  medium: (context) => Row(
    children: [
      // NOTE: Left pane -- entry header pinned
      SizedBox(
        width: 360,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(FieldGuideSpacing.of(context).md),
          child: EntryHeaderCard(
            entry: _entry!,
            projectName: _projectName,
            projectNumber: _projectNumber,
            locationName: _locationName,
            isViewer: !context.read<AuthProvider>().canEditEntry(
              createdByUserId: _entry?.createdByUserId,
            ),
            onEditLocation: _showLocationEditDialog,
            onEditWeather: () => _showWeatherDialog(_entry!),
            onEditDate: () => _showDatePicker(_entry!),
            sectionKey: _sectionKeys['basics'],
          ),
        ),
      ),
      const VerticalDivider(width: 1),
      // NOTE: Right pane -- scrollable sections (without header, since it's in left pane)
      Expanded(
        child: CustomScrollView(
          key: TestingKeys.entryEditorScroll,
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(FieldGuideSpacing.of(context).md),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _buildSectionsWithoutHeader(),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
```

**Action**: Add `_buildSectionsWithoutHeader()` method that returns `_buildSections()` minus the `EntryHeaderCard` and the first `SizedBox` spacer.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.1.7: Add Logger calls to extracted widgets

**Action**: In `entry_header_card.dart`, `editable_safety_card.dart`, and `entry_editor_app_bar.dart`, add Logger import and log at key interaction points:

```dart
import 'package:construction_inspector/core/logging/logger.dart';

// In EntryHeaderCard.build:
// WHY: Component-level logging for decomposed widgets
// (No build-time logging needed -- parent logs lifecycle events)

// In EditableSafetyCard._startEditing:
Logger.ui('[EditableSafetyCard] Started editing safety section');

// In EditableSafetyCard._done:
Logger.ui('[EditableSafetyCard] Finished editing safety section');
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

---

### Sub-phase 4.2: project_setup_screen.dart (1,436 lines -> ~300 + 5 widgets)

**Agent**: `code-fixer-agent`
**File**: `lib/features/projects/presentation/screens/project_setup_screen.dart`

This screen has 5 tabs (Details, Locations, Contractors, Pay Items, Assignments). Tabs 1-2 are already extracted (`ProjectDetailsForm`, `AssignmentsStep`). The remaining `_build*Tab` methods for Locations, Contractors, and Pay Items are 120-570 lines each and contain nested `Consumer` widgets. The file has 30 `DesignConstants` references and fixes GitHub issue #165 (RenderFlex overflow).

#### Step 4.2.1: Component discovery sweep

**Action**: Read `lib/features/projects/presentation/screens/project_setup_screen.dart` in full. Catalog:

| Symbol | Line | Target |
|--------|------|--------|
| `_buildDetailsTab()` | 409 | Keep -- thin wrapper around `ProjectDetailsForm` (already extracted) |
| `_buildLocationsTab()` | 466 | Extract to `project_locations_tab.dart` |
| `_buildContractorsTab()` | 590 | Extract to `project_contractors_tab.dart` |
| `_buildBidItemsTab()` | 768 | Extract to `project_bid_items_tab.dart` |
| `_InlineContractorCreationCard` | 1356 | Move to `project_contractors_tab.dart` (private helper for that tab) |

**Verification**: Read-only step.

#### Step 4.2.2: Extract `_buildLocationsTab` to standalone widget

**Action**: Create `lib/features/projects/presentation/widgets/project_locations_tab.dart`

```dart
// WHY: Extracted from project_setup_screen.dart:466-584. Self-contained tab
// content with Consumer<LocationProvider> and location CRUD operations.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
import 'package:construction_inspector/shared/shared.dart';
import 'package:construction_inspector/features/locations/presentation/providers/location_provider.dart';
import 'package:construction_inspector/features/locations/data/models/location.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import '../widgets/widgets.dart';

class ProjectLocationsTab extends StatelessWidget {
  final String projectId;

  const ProjectLocationsTab({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final canManageProjects = context.watch<AuthProvider>().canManageProjects;
    // NOTE: Body is verbatim from project_setup_screen.dart:469-583,
    // with _projectId replaced by projectId parameter,
    // and _showAddLocationDialog / _confirmDeleteLocation replaced by
    // local methods or callbacks.
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        // ... (copy lines 470-583)
      },
    );
  }

  // NOTE: Location dialog and delete confirmation methods moved here
  // from project_setup_screen.dart
}
```

**Action**: In `project_setup_screen.dart`, replace `_buildLocationsTab()` body with:
```dart
Widget _buildLocationsTab() {
  return ProjectLocationsTab(projectId: _projectId!);
}
```

Or inline the widget directly in the `TabBarView`. Delete the `_buildLocationsTab` method body (lines 466-584) and the `_confirmDeleteLocation` and `_showAddLocationDialog` methods if they only serve this tab.

**Action**: Add export to `lib/features/projects/presentation/widgets/widgets.dart`:
```dart
export 'project_locations_tab.dart';
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.2.3: Extract `_buildContractorsTab` to standalone widget

**Action**: Create `lib/features/projects/presentation/widgets/project_contractors_tab.dart`

```dart
// WHY: Extracted from project_setup_screen.dart:590-766. Contains Consumer3
// with ContractorProvider, EquipmentProvider, PersonnelTypeProvider. Also
// includes the _InlineContractorCreationCard (lines 1356+) as a private widget.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
import 'package:construction_inspector/shared/shared.dart';
import 'package:construction_inspector/features/contractors/presentation/providers/contractor_provider.dart';
import 'package:construction_inspector/features/contractors/presentation/providers/equipment_provider.dart';
import 'package:construction_inspector/features/contractors/presentation/providers/personnel_type_provider.dart';
import 'package:construction_inspector/features/contractors/data/models/contractor.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/entries/presentation/widgets/contractor_editor_widget.dart';

class ProjectContractorsTab extends StatefulWidget {
  final String projectId;

  const ProjectContractorsTab({super.key, required this.projectId});

  @override
  State<ProjectContractorsTab> createState() => _ProjectContractorsTabState();
}

class _ProjectContractorsTabState extends State<ProjectContractorsTab> {
  String? _editingContractorId;
  bool _isCreatingContractor = false;
  final _contractorNameController = TextEditingController();
  ContractorType _editingContractorType = ContractorType.prime;

  @override
  void dispose() {
    _contractorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: Body from project_setup_screen.dart:593-766 verbatim,
    // with state fields moved to this widget's State class.
    // _InlineContractorCreationCard (line 1356) is also moved here.
    return Consumer3<ContractorProvider, EquipmentProvider, PersonnelTypeProvider>(
      builder: (context, contractorProvider, equipmentProvider, personnelTypeProvider, _) {
        // ... (copy lines 598-766)
      },
    );
  }
}

// NOTE: Moved from project_setup_screen.dart:1356
class _InlineContractorCreationCard extends StatelessWidget {
  // ... (copy lines 1356-end of class)
}
```

**Action**: In `project_setup_screen.dart`:
- Remove contractor-specific state fields (`_editingContractorId`, `_isCreatingContractor`, `_contractorNameController`, `_editingContractorType`) from `_ProjectSetupScreenState`
- Replace `_buildContractorsTab()` with `ProjectContractorsTab(projectId: _projectId!)`
- Delete `_InlineContractorCreationCard` class (lines 1356+)
- Delete contractor CRUD methods that only served this tab

**Action**: Add export to widgets barrel.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.2.4: Extract `_buildBidItemsTab` to standalone widget

**Action**: Create `lib/features/projects/presentation/widgets/project_bid_items_tab.dart`

```dart
// WHY: Extracted from project_setup_screen.dart:768-1354. This is the largest
// tab (~586 lines) with Consumer<BidItemProvider>, inline editing, CSV import,
// and complex list management.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
import 'package:construction_inspector/shared/shared.dart';
import 'package:construction_inspector/features/quantities/presentation/providers/bid_item_provider.dart';
import 'package:construction_inspector/features/quantities/data/models/bid_item.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';
import 'package:construction_inspector/features/pdf/presentation/helpers/mp_import_helper.dart';
import 'package:construction_inspector/features/pdf/presentation/helpers/pdf_import_helper.dart';
import '../widgets/widgets.dart';

class ProjectBidItemsTab extends StatefulWidget {
  final String projectId;

  const ProjectBidItemsTab({super.key, required this.projectId});

  @override
  State<ProjectBidItemsTab> createState() => _ProjectBidItemsTabState();
}

class _ProjectBidItemsTabState extends State<ProjectBidItemsTab> {
  // NOTE: Bid item editing state moved from _ProjectSetupScreenState.
  // Copy all bid-item-related state fields and methods.

  @override
  Widget build(BuildContext context) {
    return Consumer<BidItemProvider>(
      builder: (context, bidItemProvider, _) {
        // ... (copy lines 771-1354)
      },
    );
  }
}
```

**Action**: In `project_setup_screen.dart`, replace bid-item tab content, remove bid-item state fields and methods.

**Action**: Add export to widgets barrel.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.2.5: Tokenize all DesignConstants references

**Action**: Across all files touched in this sub-phase, apply the same tokenization mapping as step 4.1.5:

| Old | New |
|-----|-----|
| `DesignConstants.space1` | `FieldGuideSpacing.of(context).xs` |
| `DesignConstants.space2` | `FieldGuideSpacing.of(context).sm` |
| `DesignConstants.space4` | `FieldGuideSpacing.of(context).md` |
| `DesignConstants.space6` | `FieldGuideSpacing.of(context).lg` |
| `DesignConstants.space8` | `FieldGuideSpacing.of(context).xl` |
| `DesignConstants.radiusSmall` | `FieldGuideRadii.of(context).sm` |
| `DesignConstants.radiusMedium` | `FieldGuideRadii.of(context).md` |
| `DesignConstants.radiusLarge` | `FieldGuideRadii.of(context).lg` |

**IMPORTANT**: `DesignConstants.space3` stays as-is (no token mapping for 12.0).

Also tokenize hardcoded literal numbers:
- `const EdgeInsets.all(16)` -> `EdgeInsets.all(FieldGuideSpacing.of(context).md)`
- `const SizedBox(height: 8)` -> `SizedBox(height: FieldGuideSpacing.of(context).sm)`
- `BorderRadius.circular(12)` -> `BorderRadius.circular(FieldGuideRadii.of(context).md)`

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.2.6: Fix GitHub issue #165 -- RenderFlex overflow

**Action**: The RenderFlex overflow in project_setup_screen occurs when tab content exceeds available height. The fix is to ensure each extracted tab widget uses `Expanded` + `ListView`/`SingleChildScrollView` properly and does not have unbounded `Column` children inside `Flexible` parents.

In each extracted tab widget, verify the root structure follows:
```dart
// WHY: #165 -- RenderFlex overflow fix. Each tab must have a bounded height
// via Expanded wrapping, and internal content must scroll.
return Column(
  children: [
    // Fixed header content (if any)
    Expanded(
      child: ListView.builder(
        // Scrollable content
      ),
    ),
    // Fixed footer content (if any, e.g., Add button)
  ],
);
```

**IMPORTANT**: Check `_buildDetailsTab` too -- the `ProjectDetailsForm` is inside `Expanded` (line 437), which is correct. But if the `UserAttributionText` padding above it grows, it could overflow. Wrap in a `Column` with `Expanded` for the form.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors. The RenderFlex issue is a runtime bug verified by visual testing.

#### Step 4.2.7: Consumer -> Selector conversions

**Action**: In `project_locations_tab.dart`, the `Consumer<LocationProvider>` rebuilds the entire tab on any location change. Convert to `Selector` where possible:

```dart
// Before (in project_locations_tab.dart):
Consumer<LocationProvider>(
  builder: (context, locationProvider, _) {
    final locations = locationProvider.locations;
    // ...
  },
)

// After:
// WHY: Selector rebuilds only when the locations list identity changes,
// not on every notifyListeners() from LocationProvider.
Selector<LocationProvider, List<Location>>(
  selector: (_, p) => p.locations,
  builder: (context, locations, _) {
    // ...
  },
)
```

**Action**: In `project_contractors_tab.dart`, the `Consumer3` is harder to convert. Keep it as-is initially -- the three-provider Consumer is already the minimal set needed. Add a `// TODO: Evaluate Selector3 for surgical rebuilds` comment.

**Action**: In `project_bid_items_tab.dart`, convert `Consumer<BidItemProvider>`:
```dart
Selector<BidItemProvider, List<BidItem>>(
  selector: (_, p) => p.bidItems,
  builder: (context, bidItems, _) {
    // ...
  },
)
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.2.8: Responsive layout with AppResponsiveBuilder

**Action**: In `project_setup_screen.dart`, the wizard uses a `TabController` with 5 tabs. On tablet/desktop, convert to a side navigation + content layout:

```dart
// FROM SPEC: Canonical layout -- Single column wizard (phone) ->
// Left section nav + content (tablet)
body: AppResponsiveBuilder(
  compact: (context) => Column(
    children: [
      // Existing TabBarView with 5 tabs
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(),
            ProjectLocationsTab(projectId: _projectId!),
            ProjectContractorsTab(projectId: _projectId!),
            ProjectBidItemsTab(projectId: _projectId!),
            const AssignmentsStep(),
          ],
        ),
      ),
    ],
  ),
  medium: (context) => Row(
    children: [
      // WHY: NavigationRail-style section nav for tablet layout
      SizedBox(
        width: 220,
        child: NavigationRail(
          selectedIndex: _tabController.index,
          onDestinationSelected: (index) {
            _tabController.animateTo(index);
          },
          extended: true,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.info_outline),
              label: Text('Details'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.location_on_outlined),
              label: Text('Locations'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.group_outlined),
              label: Text('Contractors'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: Text('Pay Items'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.assignment_ind_outlined),
              label: Text('Assignments'),
            ),
          ],
        ),
      ),
      const VerticalDivider(width: 1),
      Expanded(
        child: AnimatedSwitcher(
          duration: FieldGuideMotion.of(context).fast,
          child: _buildCurrentTabContent(),
        ),
      ),
    ],
  ),
),
```

**Action**: Add `_buildCurrentTabContent()` that switches on `_tabController.index` and returns the corresponding tab widget.

**NOTE**: The `AppBar.bottom: ProjectTabBar(...)` should be hidden in the medium+ layout since the NavigationRail replaces it. Wrap with `AppResponsiveBuilder` or conditionally null the `bottom` property based on `MediaQuery.sizeOf(context).width`.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

---

### Sub-phase 4.3: home_screen.dart (1,270 lines -> ~300 + 4 widgets)

**Agent**: `code-fixer-agent`
**File**: `lib/features/entries/presentation/screens/home_screen.dart`

This screen has the second-highest `DesignConstants` reference count (47). It contains a calendar section, day cell animation, project header, empty states, and entry list. It has 3 `Consumer` widgets and 2 private widget classes (`_AnimatedDayCell`, `_ModernEntryCard`).

#### Step 4.3.1: Component discovery sweep

| Symbol | Line | Target |
|--------|------|--------|
| `_buildNoProjectsState()` | 324 | Extract to `home_no_projects_state.dart` |
| `_buildSelectProjectState()` | 362 | Merge into `home_no_projects_state.dart` as variant |
| `_buildProjectHeader(Project)` | 400 | Extract to `home_project_header.dart` |
| `_buildCalendarSection(DailyEntryProvider)` | 442 | Extract to `home_calendar_section.dart` |
| `_buildCalendarFormatToggle(CalendarFormatProvider)` | 464 | Move into `home_calendar_section.dart` |
| `_buildFormatButton(...)` | 503 | Move into `home_calendar_section.dart` |
| `_buildCalendar(...)` | 541 | Move into `home_calendar_section.dart` |
| `_buildSelectedDayContent(...)` | 716 | Extract to `home_day_content.dart` |
| `_buildEmptyState()` | 786 | Move into `home_day_content.dart` |
| `_buildEntryList(...)` | 845 | Move into `home_day_content.dart` |
| `_AnimatedDayCell` | 1017 | Extract to `animated_day_cell.dart` |
| `_ModernEntryCard` | 1130 | Extract to `home_entry_card.dart` |

#### Step 4.3.2: Extract `_AnimatedDayCell` and `_ModernEntryCard`

**Action**: Create `lib/features/entries/presentation/widgets/animated_day_cell.dart`

```dart
// WHY: Extracted from home_screen.dart:1017-1128. Self-contained animated
// widget for calendar day cells with entry indicators.
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';

// NOTE: Made public by removing underscore prefix.
class AnimatedDayCell extends StatefulWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasEntries;
  final int entryCount;

  const AnimatedDayCell({
    super.key,
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasEntries,
    required this.entryCount,
  });

  @override
  State<AnimatedDayCell> createState() => _AnimatedDayCellState();
}

// NOTE: State body copied from home_screen.dart:1036-1128
class _AnimatedDayCellState extends State<AnimatedDayCell>
    with SingleTickerProviderStateMixin {
  // ... (copy verbatim, replacing _AnimatedDayCell -> AnimatedDayCell)
}
```

**Action**: Create `lib/features/entries/presentation/widgets/home_entry_card.dart`

```dart
// WHY: Extracted from home_screen.dart:1130-1270. Entry card for the calendar
// day view list. Contains tap-to-navigate, status badge, location display.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/features/entries/data/models/daily_entry.dart';

// NOTE: Made public, renamed from _ModernEntryCard to HomeEntryCard.
class HomeEntryCard extends StatelessWidget {
  final DailyEntry entry;
  final String? locationName;
  final VoidCallback? onTap;

  const HomeEntryCard({
    super.key,
    required this.entry,
    this.locationName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ... (copy from home_screen.dart:1130-end, making public)
  }
}
```

**Action**: Add exports to `lib/features/entries/presentation/widgets/widgets.dart`:
```dart
export 'animated_day_cell.dart';
export 'home_entry_card.dart';
```

**Action**: In `home_screen.dart`, delete both private classes and import the new files. Update all references from `_AnimatedDayCell` to `AnimatedDayCell` and `_ModernEntryCard` to `HomeEntryCard`.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.3.3: Extract calendar section

**Action**: Create `lib/features/entries/presentation/widgets/home_calendar_section.dart`

```dart
// WHY: Extracted from home_screen.dart:442-714. Contains calendar widget,
// format toggle, and all calendar-related _build methods.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
import 'package:construction_inspector/features/entries/data/models/daily_entry.dart';
import 'package:construction_inspector/features/entries/presentation/providers/daily_entry_provider.dart';
import 'package:construction_inspector/features/entries/presentation/providers/calendar_format_provider.dart';
import 'package:construction_inspector/features/entries/presentation/widgets/animated_day_cell.dart';

class HomeCalendarSection extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<DailyEntry> entries;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  const HomeCalendarSection({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.entries,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: Contains _buildCalendarSection, _buildCalendarFormatToggle,
    // _buildFormatButton, and _buildCalendar logic.
    // Moved from home_screen.dart:442-714.
  }
}
```

**Action**: Add export to widgets barrel.

**Action**: In `home_screen.dart`, replace the calendar `Flexible` section in `build` (lines 281-288) with:
```dart
Flexible(
  fit: FlexFit.loose,
  child: HomeCalendarSection(
    focusedDay: _focusedDay,
    selectedDay: _selectedDay,
    entries: context.read<DailyEntryProvider>().entries,
    onDaySelected: (day) {
      setState(() {
        _selectedDay = day;
        _focusedDay = day;
      });
      context.read<DailyEntryProvider>().setSelectedDate(day);
    },
    onPageChanged: (focusedDay) {
      setState(() => _focusedDay = focusedDay);
    },
  ),
),
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.3.4: Extract selected day content

**Action**: Create `lib/features/entries/presentation/widgets/home_day_content.dart`

```dart
// WHY: Extracted from home_screen.dart:716-1015. Contains _buildSelectedDayContent,
// _buildEmptyState, and _buildEntryList. Self-contained widget that shows
// entries for the selected day with create FAB.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
import 'package:construction_inspector/shared/shared.dart';
import 'package:construction_inspector/features/entries/data/models/daily_entry.dart';
import 'package:construction_inspector/features/entries/presentation/widgets/home_entry_card.dart';
import 'package:construction_inspector/features/locations/data/models/location.dart';

class HomeDayContent extends StatelessWidget {
  final DateTime? selectedDay;
  final List<DailyEntry> entries;
  final List<Location> locations;
  final String? projectId;
  final VoidCallback? onCreateEntry;
  // FROM SPEC: Callbacks for inline editing (tap-to-edit on entries)
  final void Function(DailyEntry entry)? onTapEntry;

  const HomeDayContent({
    super.key,
    this.selectedDay,
    required this.entries,
    required this.locations,
    this.projectId,
    this.onCreateEntry,
    this.onTapEntry,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: Body from home_screen.dart:716-1015
  }
}
```

**Action**: Add export. Update `home_screen.dart` to use `HomeDayContent` in place of `_buildSelectedDayContent`.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.3.5: Tokenize all 47 DesignConstants references

**Action**: Apply the standard tokenization mapping across all files in this sub-phase. The 47 references include `space1` through `space8` and `radius*` variants.

Same mapping table as step 4.1.5. Also tokenize hardcoded literals:
- `const EdgeInsets.all(32)` -> `EdgeInsets.all(FieldGuideSpacing.of(context).xl)`
- `BorderRadius.circular(8)` -> `BorderRadius.circular(FieldGuideRadii.of(context).sm)`
- Hardcoded `SizedBox(height: N)` -> token equivalent

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.3.6: Consumer -> Selector conversions

**Action**: In `home_screen.dart` main build method:

```dart
// Before (line 254):
Consumer<ProjectProvider>(
  builder: (context, projectProvider, _) {
    // Uses: selectedProject, isInitializing, isRestoringProject, projects
  },
)

// After:
// WHY: Selector rebuilds only when the project selection/loading state changes,
// not on every ProjectProvider notification (e.g., search query changes).
Selector<ProjectProvider, ({Project? selected, bool isLoading, bool isEmpty})>(
  selector: (_, p) => (
    selected: p.selectedProject,
    isLoading: p.isInitializing || p.isRestoringProject,
    isEmpty: p.projects.isEmpty,
  ),
  builder: (context, state, _) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.isEmpty) return _buildNoProjectsState();
    if (state.selected == null) return _buildSelectProjectState();
    // ...
  },
)
```

**Action**: Convert inner `Consumer<DailyEntryProvider>` (line 283) and `Consumer2<DailyEntryProvider, LocationProvider>` (line 294) similarly:

```dart
// WHY: The calendar section only needs the entries list, not all provider fields.
Selector<DailyEntryProvider, List<DailyEntry>>(
  selector: (_, p) => p.entries,
  builder: (context, entries, _) {
    return HomeCalendarSection(
      // ...
      entries: entries,
    );
  },
)
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.3.7: Responsive layout with AppResponsiveBuilder

**Action**: In `home_screen.dart`, wrap the body to support tablet layout:

```dart
// FROM SPEC: Canonical layout -- Single column calendar + preview (phone) ->
// Calendar/list + preview pane (tablet)
body: AppResponsiveBuilder(
  compact: (context) => _buildCompactLayout(projectState),
  medium: (context) => Row(
    children: [
      // Left pane: Calendar + entry list
      SizedBox(
        width: 400,
        child: Column(
          children: [
            _buildProjectHeader(selectedProject),
            Flexible(
              fit: FlexFit.loose,
              child: HomeCalendarSection(/* ... */),
            ),
            const Divider(height: 1),
            Expanded(child: HomeDayContent(/* ... */)),
          ],
        ),
      ),
      const VerticalDivider(width: 1),
      // Right pane: Entry detail/preview (if entry selected)
      Expanded(
        child: _selectedEntryId != null
            ? _buildEntryPreview(_selectedEntryId!)
            : Center(
                child: AppEmptyState(
                  icon: Icons.article_outlined,
                  title: 'Select an entry',
                  subtitle: 'Choose an entry from the list to preview',
                ),
              ),
      ),
    ],
  ),
),
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

---

### Sub-phase 4.4: mdot_hub_screen.dart (1,198 lines -> ~300 + 5 screens)

**Agent**: `code-fixer-agent`
**File**: `lib/features/forms/presentation/screens/mdot_hub_screen.dart`

This file contains 6 classes: `MdotHubScreen` (main), `_PdfPreviewScreen`, `FormFillScreen`, `QuickTestEntryScreen`, `ProctorEntryScreen`, `WeightsEntryScreen`. The main hub is already partially decomposed with extracted widgets (`hub_header_content`, `hub_quick_test_content`, `hub_proctor_content`). The task is to split the 5 secondary screen classes into separate files and decompose the main hub further.

#### Step 4.4.1: Extract 5 screen classes to separate files

**Action**: Create `lib/features/forms/presentation/screens/form_fill_screen.dart`:

```dart
// WHY: Extracted from mdot_hub_screen.dart:1153-1163. FormFillScreen delegates
// to MdotHubScreen -- separate file for clean routing imports.
import 'package:flutter/material.dart';
import 'package:construction_inspector/features/forms/presentation/screens/mdot_hub_screen.dart';

class FormFillScreen extends StatelessWidget {
  final String responseId;

  const FormFillScreen({super.key, required this.responseId});

  @override
  // WHY: FormFillScreen is the full-form entry point. The MdotHubScreen
  // already implements the complete fill experience.
  Widget build(BuildContext context) => MdotHubScreen(responseId: responseId);
}
```

**Action**: Create `lib/features/forms/presentation/screens/quick_test_entry_screen.dart`:

```dart
// WHY: Extracted from mdot_hub_screen.dart:1165-1175.
import 'package:flutter/material.dart';
import 'package:construction_inspector/features/forms/presentation/screens/mdot_hub_screen.dart';

class QuickTestEntryScreen extends StatelessWidget {
  final String responseId;

  const QuickTestEntryScreen({super.key, required this.responseId});

  @override
  // WHY: Quick Test Entry jumps directly to the test section.
  Widget build(BuildContext context) =>
      MdotHubScreen(responseId: responseId, initialSection: 2);
}
```

**Action**: Create `lib/features/forms/presentation/screens/proctor_entry_screen.dart`:

```dart
// WHY: Extracted from mdot_hub_screen.dart:1177-1186.
import 'package:flutter/material.dart';
import 'package:construction_inspector/features/forms/presentation/screens/mdot_hub_screen.dart';

class ProctorEntryScreen extends StatelessWidget {
  final String responseId;

  const ProctorEntryScreen({super.key, required this.responseId});

  @override
  // WHY: Proctor Entry jumps directly to the proctor section.
  Widget build(BuildContext context) =>
      MdotHubScreen(responseId: responseId, initialSection: 1);
}
```

**Action**: Create `lib/features/forms/presentation/screens/weights_entry_screen.dart`:

```dart
// WHY: Extracted from mdot_hub_screen.dart:1188-1198.
import 'package:flutter/material.dart';
import 'package:construction_inspector/features/forms/presentation/screens/mdot_hub_screen.dart';

class WeightsEntryScreen extends StatelessWidget {
  final String responseId;

  const WeightsEntryScreen({super.key, required this.responseId});

  @override
  // WHY: Weights entry is part of the proctor workflow (section 1).
  Widget build(BuildContext context) =>
      MdotHubScreen(responseId: responseId, initialSection: 1);
}
```

**Action**: Create `lib/features/forms/presentation/screens/form_pdf_preview_screen.dart`:

```dart
// WHY: Extracted from mdot_hub_screen.dart:1134-1151. The PDF preview was a
// private class (_PdfPreviewScreen) -- now public for direct routing.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';

class FormPdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;

  const FormPdfPreviewScreen({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('PDF Preview')),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        build: (_) => bytes,
      ),
    );
  }
}
```

**Action**: In `mdot_hub_screen.dart`, delete all 5 classes after `_MdotHubScreenState` (lines 1133-1199). Update any internal navigation that pushed `_PdfPreviewScreen` to use `FormPdfPreviewScreen` instead.

**Action**: Update any router files that import these screens from `mdot_hub_screen.dart` to import from their new files. Search for imports:
```
grep -r "mdot_hub_screen" lib/core/router/
```
Update import paths accordingly.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/forms/ lib/core/router/"
```
Expected: Zero analyzer errors.

#### Step 4.4.2: Tokenize DesignConstants references

**Action**: The mdot_hub_screen has only 6 `DesignConstants` references. Apply standard tokenization mapping.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/forms/"
```
Expected: Zero analyzer errors.

#### Step 4.4.3: Responsive layout with AppResponsiveBuilder

**Action**: In `mdot_hub_screen.dart`, the hub uses accordion sections with `_expanded` state tracking which section is open. On tablet, convert to a two-pane layout:

```dart
// FROM SPEC: Canonical layout -- Single column accordion (phone) ->
// Two-pane section nav left + content right (tablet)
body: AppResponsiveBuilder(
  compact: (context) => _buildCompactLayout(),
  medium: (context) => Row(
    children: [
      // WHY: Section navigator in left pane for tablet layout.
      // Uses StatusPillBar items rendered vertically.
      SizedBox(
        width: 200,
        child: _buildSectionNav(),
      ),
      const VerticalDivider(width: 1),
      Expanded(
        child: _buildExpandedSectionContent(),
      ),
    ],
  ),
),
```

**Action**: Add `_buildSectionNav()` method that renders navigation items for Header, Proctor, Test sections. Add `_buildExpandedSectionContent()` that renders the currently selected section's content without the accordion wrapper.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/forms/"
```
Expected: Zero analyzer errors.

---

### Sub-phase 4.5: project_list_screen.dart (1,196 lines -> ~300 + 4 widgets)

**Agent**: `code-fixer-agent`
**File**: `lib/features/projects/presentation/screens/project_list_screen.dart`

This screen has no `DesignConstants` imports but has 26 hardcoded spacing literals. It uses `Consumer<ProjectProvider>`, `Consumer<ProjectImportRunner>`, and `Consumer<ProjectSyncHealthProvider>`. The `_buildProjectCard` method is 227 lines (816-1043) and should be extracted.

#### Step 4.5.1: Component discovery sweep

| Symbol | Line | Target |
|--------|------|--------|
| `_buildTabBody(...)` | 401 | Keep in main screen (orchestration) |
| `_buildMyProjectsTab(...)` | 432 | Extract to `project_my_projects_tab.dart` |
| `_buildCompanyTab(...)` | 475 | Extract to `project_company_tab.dart` |
| `_buildArchivedTab(...)` | 550 | Extract to `project_archived_tab.dart` |
| `_buildSyncStatusIcon(...)` | 775 | Move into project card widget |
| `_buildProjectCard(...)` | 816 | Extract to `project_card.dart` (227 lines) |
| `_buildSearchField()` | 1064 | Keep (thin wrapper around `SearchBarField`) |
| `_buildErrorState(...)` | 1076 | Keep (small) |
| `_buildLocationBadge(...)` | 1118 | Move into project card |
| `_buildLifecycleBadge(...)` | 1133 | Move into project card |
| `_buildBadge(...)` | 1163 | Move into project card |

#### Step 4.5.2: Extract `_buildProjectCard` to standalone widget

**Action**: Create `lib/features/projects/presentation/widgets/project_card.dart`

```dart
// WHY: Extracted from project_list_screen.dart:816-1043. The largest method
// in the file (227 lines). Self-contained card with sync status, badges,
// download CTA, and action buttons.
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/shared/shared.dart';
import 'package:construction_inspector/features/projects/data/models/merged_project_entry.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_sync_health_provider.dart';

class ProjectCard extends StatelessWidget {
  final MergedProjectEntry entry;
  final ProjectSyncHealthProvider healthProvider;
  final bool canManageProjects;
  final bool canEditFieldData;
  final bool canDownload;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onDownload;
  final VoidCallback? onEdit;
  final VoidCallback? onArchiveToggle;

  const ProjectCard({
    super.key,
    required this.entry,
    required this.healthProvider,
    required this.canManageProjects,
    required this.canEditFieldData,
    this.canDownload = true,
    required this.now,
    this.onTap,
    this.onRemove,
    this.onDownload,
    this.onEdit,
    this.onArchiveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = FieldGuideColors.of(context);
    final project = entry.project;
    final isRemoteOnly = entry.isRemoteOnly;

    return Card(
      key: TestingKeys.projectCard(project.id),
      // NOTE: Body from project_list_screen.dart:843-1043
      // with _handleSelectProject -> onTap callback,
      // _showDownloadConfirmation -> onDownload callback,
      // _buildSyncStatusIcon -> _buildSyncStatusIcon local method,
      // _buildLocationBadge/_buildLifecycleBadge/_buildBadge -> local methods
    );
  }

  // NOTE: Helper methods _buildSyncStatusIcon, _buildLocationBadge,
  // _buildLifecycleBadge, _buildBadge moved from project_list_screen.dart
}
```

**Action**: In `project_list_screen.dart`, replace all `_buildProjectCard(...)` calls with `ProjectCard(...)`, passing callbacks for `onTap`, `onRemove`, `onDownload`, `onEdit`, `onArchiveToggle`.

Delete methods: `_buildProjectCard`, `_buildSyncStatusIcon`, `_buildLocationBadge`, `_buildLifecycleBadge`, `_buildBadge`.

**Action**: Add export to widgets barrel.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.5.3: Extract tab content methods

**Action**: Create `lib/features/projects/presentation/widgets/project_tab_content.dart` containing the three tab builders. Each tab is structurally similar (filter entries, build list of `ProjectCard`s).

```dart
// WHY: Extracted from project_list_screen.dart. Three tab bodies (~120 lines each)
// are structurally identical: filter entries, build RefreshIndicator + ListView
// of ProjectCard widgets.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/projects/data/models/merged_project_entry.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_provider.dart';
import 'package:construction_inspector/features/projects/presentation/providers/project_sync_health_provider.dart';
import 'package:construction_inspector/features/projects/presentation/widgets/project_card.dart';
import 'package:construction_inspector/features/auth/presentation/providers/auth_provider.dart';

class ProjectTabContent extends StatelessWidget {
  final List<MergedProjectEntry> entries;
  final Future<void> Function() onRefresh;
  final void Function(String id) onSelectProject;
  final void Function(MergedProjectEntry entry) onDownload;
  final void Function(String projectId) onRemoveFromDevice;
  final void Function(MergedProjectEntry entry) onRemoteDelete;
  final Widget? emptyState;

  const ProjectTabContent({
    super.key,
    required this.entries,
    required this.onRefresh,
    required this.onSelectProject,
    required this.onDownload,
    required this.onRemoveFromDevice,
    required this.onRemoteDelete,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: Shared tab structure from the three _build*Tab methods.
    // Each tab uses the same list-building pattern with ProjectCard.
    final healthProvider = context.watch<ProjectSyncHealthProvider>();
    final authProvider = context.watch<AuthProvider>();
    final now = DateTime.now();

    if (entries.isEmpty) {
      return emptyState ?? const Center(child: Text('No projects'));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.all(FieldGuideSpacing.of(context).md),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ProjectCard(
            entry: entry,
            healthProvider: healthProvider,
            canManageProjects: authProvider.canManageProjects,
            canEditFieldData: authProvider.canEditFieldData,
            now: now,
            onTap: entry.isRemoteOnly
                ? () => onDownload(entry)
                : () => onSelectProject(entry.project.id),
            onRemove: () => onRemoveFromDevice(entry.project.id),
            onDownload: () => onDownload(entry),
          );
        },
      ),
    );
  }
}
```

**Action**: In `project_list_screen.dart`, replace `_buildMyProjectsTab`, `_buildCompanyTab`, `_buildArchivedTab` with `ProjectTabContent` instances, each passing the appropriate filtered entries list.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.5.4: Tokenize hardcoded spacing literals

**Action**: In `project_card.dart` and `project_list_screen.dart`, replace all hardcoded spacing:

| Hardcoded | Token |
|-----------|-------|
| `EdgeInsets.all(16)` | `EdgeInsets.all(FieldGuideSpacing.of(context).md)` |
| `EdgeInsets.only(bottom: 12)` | `EdgeInsets.only(bottom: FieldGuideSpacing.of(context).sm + 4)` |
| `SizedBox(width: 10)` | `SizedBox(width: FieldGuideSpacing.of(context).sm + 2)` |
| `SizedBox(width: 6)` | `SizedBox(width: FieldGuideSpacing.of(context).xs + 2)` |
| `SizedBox(height: 12)` | `SizedBox(height: DesignConstants.space3)` |
| `SizedBox(height: 8)` | `SizedBox(height: FieldGuideSpacing.of(context).sm)` |
| `SizedBox(width: 16)` | `SizedBox(width: FieldGuideSpacing.of(context).md)` |
| `SizedBox(width: 8)` | `SizedBox(width: FieldGuideSpacing.of(context).sm)` |
| `BorderRadius.circular(12)` | `BorderRadius.circular(FieldGuideRadii.of(context).md)` |

**NOTE**: For spacings that do not map cleanly to tokens (6, 10, 12), use `DesignConstants.space3` for 12 and leave small gaps (6, 10) as hardcoded for now -- they are visual polish values, not semantic tokens.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.5.5: Consumer -> Selector conversions

**Action**: In `project_list_screen.dart`, the outer `Consumer<ProjectProvider>` (line 339) rebuilds the entire screen on any project change. Convert:

```dart
// Before:
Consumer<ProjectProvider>(
  builder: (context, provider, _) {
    return AppScaffold(/* ... */);
  },
)

// After:
// WHY: The AppScaffold only needs tab counts and the filtered project lists,
// not every provider field. Use Selector for surgical rebuilds.
Selector<ProjectProvider, ({int myCount, int companyCount, int archivedCount, bool isLoading, String? error})>(
  selector: (_, p) => (
    myCount: p.myProjectsCount,
    companyCount: p.companyProjectsCount,
    archivedCount: p.archivedProjectsCount,
    isLoading: p.isLoading,
    error: p.error,
  ),
  builder: (context, state, _) {
    return AppScaffold(
      appBar: AppBar(
        // ...
        bottom: ProjectTabBar(
          controller: _tabController,
          myProjectsCount: state.myCount,
          companyCount: state.companyCount,
          archivedCount: state.archivedCount,
        ),
      ),
      // ...
    );
  },
)
```

**Action**: Convert `Consumer<ProjectImportRunner>` (line 373):
```dart
Selector<ProjectImportRunner, bool>(
  selector: (_, r) => r.isImporting,
  builder: (context, isImporting, _) {
    if (!isImporting) return const SizedBox.shrink();
    return ProjectImportBanner(runner: context.read<ProjectImportRunner>());
  },
)
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.5.6: Sliver migration

**Action**: In `project_list_screen.dart`, the current layout uses `Column` with `Expanded(child: TabBarView(...))`. Inside each tab, `ListView.builder` is used. Convert the tab content to use `CustomScrollView` with slivers:

```dart
// FROM SPEC: Sliver migration -- Mixed Column/ListView -> CustomScrollView
// with sliver sections
// NOTE: This is done inside ProjectTabContent.build:
return RefreshIndicator(
  onRefresh: onRefresh,
  child: CustomScrollView(
    slivers: [
      SliverPadding(
        padding: EdgeInsets.all(FieldGuideSpacing.of(context).md),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = entries[index];
              return ProjectCard(/* ... */);
            },
            childCount: entries.length,
          ),
        ),
      ),
    ],
  ),
);
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

#### Step 4.5.7: Responsive layout with AppResponsiveBuilder

**Action**: In `project_list_screen.dart`, the canonical layout for a list screen on tablet is list-detail:

```dart
// FROM SPEC: Canonical layout -- Single column list (phone) -> List-detail (tablet)
body: AppResponsiveBuilder(
  compact: (context) => Column(
    children: [
      Consumer<ProjectImportRunner>(/* ... */),
      const DeletionNotificationBanner(),
      Expanded(child: _buildTabBody(provider, authProvider)),
    ],
  ),
  medium: (context) => Row(
    children: [
      // Left: project list (narrower)
      SizedBox(
        width: 400,
        child: Column(
          children: [
            Consumer<ProjectImportRunner>(/* ... */),
            const DeletionNotificationBanner(),
            Expanded(child: _buildTabBody(provider, authProvider)),
          ],
        ),
      ),
      const VerticalDivider(width: 1),
      // Right: project detail/dashboard preview
      Expanded(
        child: _selectedProjectId != null
            ? _buildProjectDetail(_selectedProjectId!)
            : Center(
                child: AppEmptyState(
                  icon: Icons.folder_outlined,
                  title: 'Select a project',
                  subtitle: 'Choose a project to see details',
                ),
              ),
      ),
    ],
  ),
),
```

**NOTE**: This requires adding `_selectedProjectId` state and updating `_handleSelectProject` to set it on tablet instead of navigating away.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/projects/"
```
Expected: Zero analyzer errors.

---

### Sub-phase 4.6: contractor_editor_widget.dart (1,099 lines -> ~300 + 3 widgets + 2 dialogs)

**Agent**: `code-fixer-agent`
**File**: `lib/features/entries/presentation/widgets/contractor_editor_widget.dart`

This file has 37 `DesignConstants` references and contains the main `ContractorEditorWidget` plus two dialog classes (`_PersonnelTypeManagerDialog`, `_EquipmentManagerDialog`). It also has many `_build*` methods for the card internals.

#### Step 4.6.1: Component discovery sweep

| Symbol | Line | Target |
|--------|------|--------|
| `ContractorEditorWidget` | 12 | Keep as main widget, reduce to orchestration |
| `_buildHeader(...)` | 141 | Extract to `contractor_card_header.dart` |
| `_buildPersonnelHeader(...)` | 228 | Move into `contractor_personnel_section.dart` |
| `_buildSectionLabel(...)` | 249 | Keep (utility, 12 lines) |
| `_buildPersonnelSection(...)` | 261 | Extract to `contractor_personnel_section.dart` |
| `_buildSetupPersonnelTypes(...)` | 318 | Move into `contractor_personnel_section.dart` |
| `_buildEquipmentHeader(...)` | 350 | Move into `contractor_equipment_section.dart` |
| `_buildEquipmentSection(...)` | 368 | Extract to `contractor_equipment_section.dart` |
| `_buildTypeBadge(...)` | 440 | Move into header widget |
| `_buildPersonnelCounterCard(...)` | 462 | Extract to `personnel_counter_card.dart` |
| `_buildCounterButton(...)` | 531 | Move into `personnel_counter_card.dart` |
| `_buildHeaderActionButton(...)` | 560 | Move into header widget |
| `_buildHeaderMenu(...)` | 628 | Move into header widget |
| `_PersonnelTypeManagerDialog` | 664 | Extract to `personnel_type_manager_dialog.dart` |
| `_EquipmentManagerDialog` | 824 | Extract to `equipment_manager_dialog.dart` |

#### Step 4.6.2: Extract dialog classes to separate files

**Action**: Create `lib/features/entries/presentation/widgets/personnel_type_manager_dialog.dart`

```dart
// WHY: Extracted from contractor_editor_widget.dart:664-822. Self-contained
// StatefulWidget dialog for managing personnel types (add/delete).
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
import 'package:construction_inspector/features/contractors/data/models/models.dart';

class PersonnelTypeManagerDialog extends StatefulWidget {
  final List<PersonnelType> types;
  final Future<PersonnelType?> Function(String name) onAdd;
  final Future<bool> Function(String typeId) onDelete;

  const PersonnelTypeManagerDialog({
    super.key,
    required this.types,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<PersonnelTypeManagerDialog> createState() =>
      _PersonnelTypeManagerDialogState();
}

class _PersonnelTypeManagerDialogState
    extends State<PersonnelTypeManagerDialog> {
  // NOTE: Body from contractor_editor_widget.dart:680-822
}
```

**Action**: Create `lib/features/entries/presentation/widgets/equipment_manager_dialog.dart`

```dart
// WHY: Extracted from contractor_editor_widget.dart:824-1099. Self-contained
// StatefulWidget dialog for managing equipment (add/delete).
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';
import 'package:construction_inspector/features/contractors/data/models/models.dart';

class EquipmentManagerDialog extends StatefulWidget {
  final List<Equipment> equipment;
  final Future<Equipment?> Function(String name, String? description) onAdd;
  final Future<bool> Function(String equipmentId) onDelete;

  const EquipmentManagerDialog({
    super.key,
    required this.equipment,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<EquipmentManagerDialog> createState() => _EquipmentManagerDialogState();
}

class _EquipmentManagerDialogState extends State<EquipmentManagerDialog> {
  // NOTE: Body from contractor_editor_widget.dart:841-end
}
```

**Action**: In `contractor_editor_widget.dart`, delete both dialog classes (lines 664-end). Import the new files. Update any `showDialog` calls that reference the old private classes to use the new public names.

**Action**: Add exports to widgets barrel.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.6.3: Extract `_buildPersonnelCounterCard` to standalone widget

**Action**: Create `lib/features/entries/presentation/widgets/personnel_counter_card.dart`

```dart
// WHY: Extracted from contractor_editor_widget.dart:462-529. The personnel
// counter is a self-contained unit with increment/decrement buttons and count
// display. It's the core interaction element in the contractor editor.
// IMPORTANT: Keep the stepper controls -- see feedback_keep_contractor_controls.md
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/core/theme/field_guide_colors.dart';
import 'package:construction_inspector/core/theme/design_constants.dart';

class PersonnelCounterCard extends StatelessWidget {
  final String typeName;
  final int count;
  final bool isEditing;
  final ValueChanged<int>? onCountChanged;

  const PersonnelCounterCard({
    super.key,
    required this.typeName,
    required this.count,
    this.isEditing = false,
    this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: Body from contractor_editor_widget.dart:462-529
    // including _buildCounterButton (531-558) as a local method
  }
}
```

**Action**: Update `contractor_editor_widget.dart` to use `PersonnelCounterCard`.

**Action**: Add export to widgets barrel.

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.6.4: Tokenize all 37 DesignConstants references

**Action**: Apply standard tokenization mapping across all files in this sub-phase. Same mapping table as step 4.1.5.

Key references in `contractor_editor_widget.dart`:
- `DesignConstants.radiusMedium` at line 98 -> `FieldGuideRadii.of(context).md`
- `DesignConstants.space3` at line 100 -> stays as `DesignConstants.space3` (no token for 12.0)
- All `DesignConstants.space2`, `space4` etc. -> token equivalents

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

#### Step 4.6.5: Add Logger calls

**Action**: In each extracted widget, add Logger import and log at interaction points:

```dart
// In PersonnelTypeManagerDialog, on add:
Logger.ui('[PersonnelTypeManagerDialog] Added type: $name');

// In EquipmentManagerDialog, on add:
Logger.ui('[EquipmentManagerDialog] Added equipment: $name');

// In PersonnelCounterCard, on count change:
// NOTE: No logging needed -- parent handles business logic logging
```

**Verification**:
```
pwsh -Command "flutter analyze lib/features/entries/"
```
Expected: Zero analyzer errors.

---

### Sub-phase 4.7: Final verification and GitHub issue closure

**Agent**: `general-purpose`

#### Step 4.7.1: Full analysis pass

**Action**: Run analyzer across all modified feature directories:
```
pwsh -Command "flutter analyze lib/features/entries/ lib/features/projects/ lib/features/forms/"
```
Expected: Zero errors, zero warnings from touched files.

#### Step 4.7.2: Verify line count reduction

**Action**: Check that the main screen files are now under target:

| File | Before | Target | Check |
|------|--------|--------|-------|
| `entry_editor_screen.dart` | 1,857 | ~300 | Grep for line count |
| `project_setup_screen.dart` | 1,436 | ~300 | Grep for line count |
| `home_screen.dart` | 1,270 | ~300 | Grep for line count |
| `mdot_hub_screen.dart` | 1,198 | ~300 | Grep for line count |
| `project_list_screen.dart` | 1,196 | ~300 | Grep for line count |
| `contractor_editor_widget.dart` | 1,099 | ~300 | Grep for line count |

**Verification**: Read each file and confirm line count. If any file exceeds 400 lines, identify remaining `_build*` methods that can be extracted.

#### Step 4.7.3: Verify no broken imports

**Action**: Run full project analysis:
```
pwsh -Command "flutter analyze"
```
Expected: No new errors introduced by this phase. Pre-existing warnings are acceptable.

#### Step 4.7.4: Close GitHub issue #165

**Action**: Verify that the RenderFlex overflow fix in sub-phase 4.2.6 addresses issue #165. The fix ensures all tab content in `project_setup_screen.dart` uses proper `Expanded` + scrollable patterns. Mark issue as resolved in the PR description:

```
Fixes #165 -- RenderFlex overflow in project setup screen resolved by decomposing
tab content into standalone widgets with proper Expanded + ListView/ScrollView bounds.
```
