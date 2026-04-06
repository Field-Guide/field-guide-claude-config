## Phase 4b: UI Decomposition -- Priority Screens 7-11 + Additional Screens/Widgets + Remaining Issues

**Prerequisite**: Phase 4a complete (screens 1-6 decomposed, tokenized, sliver-migrated). All new design system components from P2-P3 are available. Token extensions (`FieldGuideSpacing`, `FieldGuideRadii`, `FieldGuideMotion`, `FieldGuideShadows`) are registered on `ThemeData.extensions` and accessible via `.of(context)`.

**Conventions for all sub-phases below**:
- Every `DesignConstants.space*` reference becomes `FieldGuideSpacing.of(context).*` (e.g., `space2` -> `.sm`, `space4` -> `.md`, `space6` -> `.lg`, `space8` -> `.xl`)
- Every `DesignConstants.radius*` reference becomes `FieldGuideRadii.of(context).*`
- Every `DesignConstants.animation*` reference becomes `FieldGuideMotion.of(context).*`
- Every `DesignConstants.elevation*` reference becomes `FieldGuideShadows.of(context).*`
- Every raw `ElevatedButton`/`TextButton`/`OutlinedButton`/`IconButton` becomes `AppButton.*` variant
- Every raw `Divider` becomes `AppDivider`
- Every raw `EdgeInsets.*(N)` with numeric literal becomes token-based spacing
- Every raw `BorderRadius.circular(N)` with numeric literal becomes token-based radius
- Every `Consumer<T>` that only reads 1-2 fields becomes `Selector<T, FieldType>`
- Each sub-phase ends with `flutter analyze` verification

---

### Sub-phase 4.7: todos_screen.dart (891 lines -> ~300 + 3 extracted widgets)

**File**: `lib/features/todos/presentation/screens/todos_screen.dart`
**DesignConstants refs**: 25
**Current structure**: `_TodosScreenState` (main, lines 34-505), `_TodoCard` (lines 508-613), `_DueDateChip` (lines 615-677), `_TodoDialogBody` (lines 678-891)
**Extraction plan**: Move `_TodoCard` -> `todo_card.dart`, `_DueDateChip` -> `todo_due_date_chip.dart`, `_TodoDialogBody` -> `todo_dialog_body.dart`

**Agent**: `code-fixer-agent`

#### Step 4.7.1: Extract TodoCard widget

Create `lib/features/todos/presentation/widgets/todo_card.dart` by extracting `_TodoCard` (lines 508-613) from `todos_screen.dart`. Make class public, tokenize all spacing/radius references.

```dart
// lib/features/todos/presentation/widgets/todo_card.dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/todos/data/models/todo_item.dart';
import 'package:construction_inspector/shared/shared.dart';
import 'todo_due_date_chip.dart';

// FROM SPEC: Extract private widgets from oversized screens into standalone files
// WHY: Decomposition target is <300 lines per file
class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = FieldGuideSpacing.of(context);
    final radii = FieldGuideRadii.of(context);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.sm, // WHY: was DesignConstants.space2 (8.0)
        vertical: spacing.xs, // WHY: was DesignConstants.space1 (4.0)
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.md), // WHY: was DesignConstants.radiusMedium (12.0)
      ),
      // NOTE: Remaining build logic copied from _TodoCard.build, lines 527-613
      // Replace all DesignConstants.space* with spacing.* equivalents
      // Replace all DesignConstants.radius* with radii.* equivalents
      // Replace raw TextButton with AppButton.text
      // Replace raw IconButton with AppButton.icon
      child: InkWell(
        borderRadius: BorderRadius.circular(radii.md),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NOTE: Checkbox + content + actions structure preserved from original
              // Full implementation copies body from lines 534-612
              // replacing every hardcoded constant with token reference
              Checkbox(
                value: todo.isCompleted,
                onChanged: (_) => onToggle(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleSmall(
                      todo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: todo.isCompleted
                          ? const TextStyle(decoration: TextDecoration.lineThrough)
                          : null,
                    ),
                    if (todo.description != null && todo.description!.isNotEmpty) ...[
                      SizedBox(height: spacing.xs),
                      AppText.bodySmall(
                        todo.description!,
                        color: cs.onSurfaceVariant,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (todo.dueDate != null) ...[
                      SizedBox(height: spacing.sm),
                      TodoDueDateChip(dueDate: todo.dueDate!, isCompleted: todo.isCompleted),
                    ],
                  ],
                ),
              ),
              AppButton.icon(
                icon: Icons.delete_outline,
                onPressed: onDelete,
                // WHY: was raw IconButton
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### Step 4.7.2: Extract TodoDueDateChip widget

Create `lib/features/todos/presentation/widgets/todo_due_date_chip.dart` by extracting `_DueDateChip` (lines 615-677). Make public, tokenize.

```dart
// lib/features/todos/presentation/widgets/todo_due_date_chip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';

// FROM SPEC: Extract private widgets to standalone files
class TodoDueDateChip extends StatelessWidget {
  final DateTime dueDate;
  final bool isCompleted;

  const TodoDueDateChip({
    super.key,
    required this.dueDate,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    final radii = FieldGuideRadii.of(context);
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now) && !isCompleted;
    final isDueToday = dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;

    final Color chipColor;
    if (isOverdue) {
      chipColor = cs.error;
    } else if (isDueToday) {
      chipColor = FieldGuideColors.of(context).statusWarning;
    } else {
      chipColor = cs.onSurfaceVariant;
    }

    // NOTE: Full chip rendering logic from lines 621-677 with token replacements
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm, // WHY: was DesignConstants.space2
        vertical: spacing.xs,   // WHY: was DesignConstants.space1
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radii.sm), // WHY: was DesignConstants.radiusSmall
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 14, color: chipColor),
          SizedBox(width: spacing.xs),
          AppText.labelSmall(
            DateFormat('MMM d').format(dueDate),
            color: chipColor,
          ),
        ],
      ),
    );
  }
}
```

#### Step 4.7.3: Extract TodoDialogBody widget

Create `lib/features/todos/presentation/widgets/todo_dialog_body.dart` by extracting `_TodoDialogBody` (lines 678-891). Make public, tokenize.

```dart
// lib/features/todos/presentation/widgets/todo_dialog_body.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/todos/data/models/todo_item.dart';

// FROM SPEC: Extract dialog body for reuse and line count reduction
class TodoDialogBody extends StatefulWidget {
  final TodoItem? existingTodo;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final ValueChanged<DateTime?> onDueDateChanged;
  final ValueChanged<TodoPriority> onPriorityChanged;
  final DateTime? initialDueDate;
  final TodoPriority initialPriority;

  const TodoDialogBody({
    super.key,
    this.existingTodo,
    required this.titleController,
    required this.descriptionController,
    required this.onDueDateChanged,
    required this.onPriorityChanged,
    this.initialDueDate,
    this.initialPriority = TodoPriority.normal,
  });

  @override
  State<TodoDialogBody> createState() => TodoDialogBodyState();
}

class TodoDialogBodyState extends State<TodoDialogBody> {
  DateTime? _dueDate;
  TodoPriority _priority = TodoPriority.normal;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDueDate ?? widget.existingTodo?.dueDate;
    _priority = widget.initialPriority;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    // NOTE: Full dialog body from lines 732-891
    // Replace all DesignConstants.space* with spacing.*
    // Replace raw TextFormField with AppTextField
    // Replace raw TextButton with AppButton.text
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: widget.titleController,
          labelText: 'Title',
          // NOTE: preserved from original
        ),
        SizedBox(height: spacing.md),
        AppTextField(
          controller: widget.descriptionController,
          labelText: 'Description',
          maxLines: 3,
        ),
        SizedBox(height: spacing.md),
        _buildDueDatePicker(),
        SizedBox(height: spacing.md),
        _buildPrioritySelector(),
      ],
    );
  }

  Widget _buildDueDatePicker() {
    // NOTE: Copy from lines 798-836, tokenize
    final spacing = FieldGuideSpacing.of(context);
    final radii = FieldGuideRadii.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(radii.sm),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked != null) {
          setState(() => _dueDate = picked);
          widget.onDueDateChanged(picked);
        }
      },
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            SizedBox(width: spacing.sm),
            Text(_dueDate != null
                ? DateFormat('MMM d, y').format(_dueDate!)
                : 'Set due date'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    // NOTE: Copy from lines 837-891, tokenize
    final spacing = FieldGuideSpacing.of(context);
    return Wrap(
      spacing: spacing.sm,
      children: TodoPriority.values.map((priority) {
        return ChoiceChip(
          label: Text(priority.name),
          selected: _priority == priority,
          onSelected: (selected) {
            if (selected) {
              setState(() => _priority = priority);
              widget.onPriorityChanged(priority);
            }
          },
        );
      }).toList(),
    );
  }
}
```

#### Step 4.7.4: Update todos_screen.dart main file

Rewrite `lib/features/todos/presentation/screens/todos_screen.dart` to import extracted widgets, remove inlined classes, tokenize remaining references. Target: ~300 lines.

```dart
// NOTE: At top of todos_screen.dart, add imports:
import 'package:construction_inspector/features/todos/presentation/widgets/todo_card.dart';
import 'package:construction_inspector/features/todos/presentation/widgets/todo_dialog_body.dart';

// WHY: Replace all 25 DesignConstants refs in the main screen body:
// - DesignConstants.space2 -> spacing.sm
// - DesignConstants.space3 -> 12.0 (keep as DesignConstants.space3 — fallback value)
// - DesignConstants.space4 -> spacing.md
// - DesignConstants.space6 -> spacing.lg
// - DesignConstants.space8 -> spacing.xl

// NOTE: Replace ListView.builder with CustomScrollView for sliver migration
// Replace Consumer<TodoProvider> with Selector where only specific fields are needed
// Replace inline _TodoCard with TodoCard, _DueDateChip with TodoDueDateChip, _TodoDialogBody with TodoDialogBody
// Delete classes _TodoCard, _DueDateChip, _TodoDialogBody from this file
```

Key changes in the main screen:
1. Add `final spacing = FieldGuideSpacing.of(context);` at top of `build()`
2. Replace `ListView.builder` with `CustomScrollView` + `SliverList`
3. Replace `Consumer<TodoProvider>` with `Selector<TodoProvider, ({bool isLoading, bool hasError, List<TodoItem> todos})>`
4. Replace all `_TodoCard(` with `TodoCard(`
5. Replace `_buildNoQueryMatchState` empty Column with `AppEmptyState`
6. Replace `_buildNoMatchingState` empty Column with `AppEmptyState`
7. Replace raw `TextButton` in `_buildNoMatchingState` with `AppButton.text`
8. Replace raw `ElevatedButton` in FAB area (if any) with `AppButton.primary`

#### Step 4.7.5: Create widgets barrel for todos feature

Create `lib/features/todos/presentation/widgets/widgets.dart`:

```dart
// lib/features/todos/presentation/widgets/widgets.dart
// WHY: Barrel file for extracted todo widgets
export 'todo_card.dart';
export 'todo_dialog_body.dart';
export 'todo_due_date_chip.dart';
```

#### Step 4.7.6: Verify todos_screen decomposition

```
pwsh -Command "flutter analyze lib/features/todos/"
```

Expected: 0 errors, 0 warnings in `lib/features/todos/`.

---

### Sub-phase 4.8: calculator_screen.dart (712 lines -> ~300 + 3 extracted widgets)

**File**: `lib/features/calculator/presentation/screens/calculator_screen.dart`
**DesignConstants refs**: 26
**Current structure**: `_CalculatorScreenState` (lines 23-91), `_HmaCalculator` (lines 93-292), `_ConcreteCalculator` (lines 293-491), `_CalculatorResultCard` (lines 492-580), `_CalculatorHistorySection` (lines 581-617), `_HistoryTile` (lines 618-712)
**Extraction plan**: Move `_HmaCalculator` -> `hma_calculator_tab.dart`, `_ConcreteCalculator` -> `concrete_calculator_tab.dart`, `_CalculatorResultCard` + `_CalculatorHistorySection` + `_HistoryTile` -> `calculator_result_card.dart` + `calculator_history_section.dart`

**Agent**: `code-fixer-agent`

#### Step 4.8.1: Extract HmaCalculatorTab widget

Create `lib/features/calculator/presentation/widgets/hma_calculator_tab.dart` by extracting `_HmaCalculator` (lines 93-292). Make public, tokenize all 26 DesignConstants refs.

```dart
// lib/features/calculator/presentation/widgets/hma_calculator_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/calculator/data/services/calculator_service.dart';
import 'package:construction_inspector/features/calculator/presentation/providers/calculator_provider.dart';
import 'calculator_result_card.dart';

// FROM SPEC: Extract tab content into standalone widget
class HmaCalculatorTab extends StatefulWidget {
  final CalculatorProvider provider;

  const HmaCalculatorTab({super.key, required this.provider});

  @override
  State<HmaCalculatorTab> createState() => _HmaCalculatorTabState();
}

class _HmaCalculatorTabState extends State<HmaCalculatorTab> {
  // NOTE: Copy controllers and state from _HmaCalculatorState (lines 100-178)
  // Tokenize all spacing/radius:
  // - DesignConstants.space2 -> spacing.sm
  // - DesignConstants.space4 -> spacing.md
  // - DesignConstants.radiusMedium -> radii.md
  // Replace all AppTextField usages (already compliant)
  // Replace raw ElevatedButton with AppButton.primary
  // Replace raw TextButton with AppButton.text

  @override
  Widget build(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    // NOTE: Full build from lines 179-292, tokenized
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input fields, calculate button, result card
          // All copied from original with token replacements
        ],
      ),
    );
  }
}
```

#### Step 4.8.2: Extract ConcreteCalculatorTab widget

Create `lib/features/calculator/presentation/widgets/concrete_calculator_tab.dart` by extracting `_ConcreteCalculator` (lines 293-491). Same tokenization pattern as Step 4.8.1.

#### Step 4.8.3: Extract CalculatorResultCard and CalculatorHistorySection

Create `lib/features/calculator/presentation/widgets/calculator_result_card.dart` (from lines 492-580) and `lib/features/calculator/presentation/widgets/calculator_history_section.dart` (from lines 581-712, includes `_HistoryTile`). Tokenize all spacing/radius.

#### Step 4.8.4: Update calculator_screen.dart main file

Rewrite `lib/features/calculator/presentation/screens/calculator_screen.dart` to import extracted widgets, keep only `CalculatorScreen` + `_CalculatorScreenState` with TabController management and top-level build. Target: ~100 lines.

```dart
// NOTE: Main screen becomes thin orchestrator:
// - TabController setup
// - AppScaffold with AppTabBar
// - TabBarView with HmaCalculatorTab and ConcreteCalculatorTab
// All DesignConstants.space* replaced with FieldGuideSpacing.of(context).*
```

#### Step 4.8.5: Create widgets barrel for calculator feature

Create `lib/features/calculator/presentation/widgets/widgets.dart`:

```dart
// lib/features/calculator/presentation/widgets/widgets.dart
export 'calculator_history_section.dart';
export 'calculator_result_card.dart';
export 'concrete_calculator_tab.dart';
export 'hma_calculator_tab.dart';
```

#### Step 4.8.6: Verify calculator_screen decomposition

```
pwsh -Command "flutter analyze lib/features/calculator/"
```

Expected: 0 errors, 0 warnings.

---

### Sub-phase 4.9: project_dashboard_screen.dart (696 lines -> ~300 + 3 widgets)

**File**: `lib/features/dashboard/presentation/screens/project_dashboard_screen.dart`
**DesignConstants refs**: 51 (highest per-file count)
**Fixes**: #200 (Review Drafts tile-card style), #207 (empty-state button contrast), #208 (gradient out of place), #233 (button consistency)
**Current structure**: `_ProjectDashboardScreenState` (lines 30-696) with `_buildNoProjectSelected` (line 236), `_buildDraftsPill` (line 271), `_buildTodaysEntryCard` (line 294), `_buildQuickStats` (line 320), `_buildBudgetOverview` (line 383), `_buildTrackedItems` (line 431), `_buildApproachingLimit` (line 550)
**Already extracted**: `dashboard_stat_card.dart`, `weather_summary_card.dart`, `budget_overview_card.dart`, `todays_entry_card.dart`
**Extraction plan**: Move `_buildDraftsPill` -> `drafts_pill.dart`, `_buildTrackedItems` + `_buildApproachingLimit` -> `budget_items_section.dart`, inline `_buildQuickStats` stays (short)

**Agent**: `code-fixer-agent`

#### Step 4.9.1: Extract DraftsPill widget

Create `lib/features/dashboard/presentation/widgets/drafts_pill.dart` by extracting `_buildDraftsPill` (lines 271-293). Tokenize, fix #200 (Review Drafts tile-card style).

```dart
// lib/features/dashboard/presentation/widgets/drafts_pill.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/entries/presentation/providers/daily_entry_provider.dart';
import 'package:construction_inspector/shared/shared.dart';

// FROM SPEC: Fix #200 — Review Drafts should use card style, not pill
// WHY: Consistent with other dashboard sections
class DraftsPill extends StatelessWidget {
  final String projectId;

  const DraftsPill({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    final radii = FieldGuideRadii.of(context);

    return Selector<DailyEntryProvider, int>(
      // WHY: Selector instead of Consumer — only needs draft count
      selector: (_, p) => p.draftCount,
      builder: (context, draftCount, _) {
        if (draftCount == 0) return const SizedBox.shrink();

        // FROM SPEC: #200 — Use AppSectionCard style instead of raw Container
        return AppSectionCard(
          onTap: () => context.push('/entries?filter=draft&projectId=$projectId'),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: FieldGuideColors.of(context).statusWarning),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: AppText.bodyMedium(
                    '$draftCount draft${draftCount == 1 ? '' : 's'} pending review',
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

#### Step 4.9.2: Extract BudgetItemsSection widget

Create `lib/features/dashboard/presentation/widgets/budget_items_section.dart` by extracting `_buildTrackedItems` (lines 431-549) and `_buildApproachingLimit` (lines 550-696). These are closely related budget item displays.

```dart
// lib/features/dashboard/presentation/widgets/budget_items_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/quantities/presentation/providers/bid_item_provider.dart';
import 'package:construction_inspector/features/quantities/presentation/providers/entry_quantity_provider.dart';
import 'package:construction_inspector/shared/shared.dart';

// FROM SPEC: Extract oversized _build methods into standalone widgets
class TrackedItemsSection extends StatelessWidget {
  const TrackedItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    final radii = FieldGuideRadii.of(context);
    final fg = FieldGuideColors.of(context);
    // NOTE: Full implementation from lines 431-549, tokenized
    // Replace all DesignConstants.space* with spacing.*
    // Replace all DesignConstants.radius* with radii.*
    // Replace raw Container decorations with AppSectionCard
    // Replace raw TextButton with AppButton.text
    return const SizedBox.shrink(); // placeholder — full code in implementation
  }
}

class ApproachingLimitSection extends StatelessWidget {
  const ApproachingLimitSection({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    final fg = FieldGuideColors.of(context);
    // NOTE: Full implementation from lines 550-696, tokenized
    return const SizedBox.shrink(); // placeholder — full code in implementation
  }
}
```

#### Step 4.9.3: Update project_dashboard_screen.dart with fixes

Rewrite `lib/features/dashboard/presentation/screens/project_dashboard_screen.dart`:

1. Import extracted `DraftsPill`, `TrackedItemsSection`, `ApproachingLimitSection`
2. Tokenize all 51 `DesignConstants` references
3. Fix #207: Replace `_buildNoProjectSelected` empty-state button with `AppButton.primary` for contrast
4. Fix #208: Remove gradient decoration from `_buildNoProjectSelected` (was `AppTheme` import for gradient — remove that import)
5. Fix #233: Ensure all buttons use `AppButton.*` variants consistently
6. Already uses `CustomScrollView` with slivers — keep that structure, just tokenize
7. Replace `Consumer` patterns with `Selector` where specific fields needed

```dart
// IMPORTANT: Fix #207 in _buildNoProjectSelected:
// Replace raw ElevatedButton with:
AppButton.primary(
  key: TestingKeys.dashboardViewProjectsButton,
  label: 'View Projects',
  icon: Icons.folder_outlined,
  onPressed: () => context.goNamed('projects'),
  // WHY: #207 — old ElevatedButton had poor contrast on empty state background
),

// IMPORTANT: Fix #208 — remove gradient container:
// Delete the Container with BoxDecoration gradient wrapping the SliverAppBar flexibleSpace
// Replace with simple themed background from FieldGuideColors.of(context)

// IMPORTANT: Fix #233 — button consistency:
// All buttons in dashboard must use AppButton.* variants
// Replace: ElevatedButton.icon -> AppButton.primary
// Replace: TextButton -> AppButton.text
// Replace: OutlinedButton -> AppButton.secondary
```

#### Step 4.9.4: Remove AppTheme import from project_dashboard_screen.dart

```dart
// WHY: #208 — the gradient was sourced from AppTheme directly
// Remove this import:
// import 'package:construction_inspector/core/theme/app_theme.dart';
// The gradient is now removed entirely, or if still needed, use FieldGuideColors.of(context).gradientStart/gradientEnd
```

#### Step 4.9.5: Verify project_dashboard decomposition

```
pwsh -Command "flutter analyze lib/features/dashboard/"
```

Expected: 0 errors, 0 warnings. Issues #200, #207, #208, #233 addressed.

---

### Sub-phase 4.10: quantity_calculator_screen.dart (656 lines -> ~300 + 2 widgets)

**File**: `lib/features/quantities/presentation/screens/quantity_calculator_screen.dart`
**DesignConstants refs**: 13
**Current structure**: `QuantityCalculatorResult` (lines 16-28), `QuantityCalculatorScreen` (lines 34-168), `_FieldConfig` (lines 170-188), `_CalculatorTabConfig` (lines 189-383), `_CalculatorTab` (lines 384-533), `_FormulaCard` (lines 534-576), `_ResultCard` (lines 577-656)
**Extraction plan**: Move `_CalculatorTab` + `_FieldConfig` + `_CalculatorTabConfig` -> `quantity_calculator_tab.dart`, `_FormulaCard` + `_ResultCard` -> `quantity_calculator_cards.dart`

**Agent**: `code-fixer-agent`

#### Step 4.10.1: Extract QuantityCalculatorTab widget

Create `lib/features/quantities/presentation/widgets/quantity_calculator_tab.dart` by extracting `_CalculatorTab` (lines 384-533), `_FieldConfig` (lines 170-188), `_CalculatorTabConfig` (lines 189-383). Tokenize all DesignConstants refs.

```dart
// lib/features/quantities/presentation/widgets/quantity_calculator_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/calculator/data/services/calculator_service.dart';
import 'quantity_calculator_cards.dart';

// FROM SPEC: Extract tab + config into reusable widget
class FieldConfig {
  // NOTE: made public, copy from lines 170-188
  final String label;
  final String hint;
  final String unit;
  final TextInputType keyboardType;
  final TextEditingController controller;

  const FieldConfig({
    required this.label,
    required this.hint,
    required this.unit,
    required this.keyboardType,
    required this.controller,
  });
}

// NOTE: CalculatorTabConfig and CalculatorTab extracted with full implementations
// Tokenize: DesignConstants.space* -> FieldGuideSpacing.of(context).*
// Replace raw AppTextField usages (already compliant)
// Replace raw ElevatedButton with AppButton.primary
```

#### Step 4.10.2: Extract QuantityCalculatorCards

Create `lib/features/quantities/presentation/widgets/quantity_calculator_cards.dart` from `_FormulaCard` (lines 534-576) and `_ResultCard` (lines 577-656).

#### Step 4.10.3: Update quantity_calculator_screen.dart

Slim main file to ~150 lines. Keep `QuantityCalculatorResult` and `QuantityCalculatorScreen` with tab controller. Import extracted widgets. Tokenize remaining refs.

#### Step 4.10.4: Verify quantity_calculator decomposition

```
pwsh -Command "flutter analyze lib/features/quantities/"
```

Expected: 0 errors, 0 warnings.

---

### Sub-phase 4.11: form_viewer_screen.dart (636 lines -> ~300 + 2 widgets)

**File**: `lib/features/forms/presentation/screens/form_viewer_screen.dart`
**DesignConstants refs**: 35
**Current structure**: `_FormViewerScreenState` (lines 31-636) with `_buildQuickActionBar` (line 332), `_buildHeaderSection` (line 373), `_buildTestsSection` (line 398), `_buildProctorsSection` (line 450), `_buildStandardsSection` (line 496), `_buildRemarksSection` (line 530)
**Extraction plan**: Extract `_buildQuickActionBar` -> `form_viewer_action_bar.dart`, group `_buildTestsSection` + `_buildProctorsSection` + `_buildStandardsSection` + `_buildRemarksSection` -> `form_viewer_sections.dart`

**Agent**: `code-fixer-agent`

#### Step 4.11.1: Extract FormViewerActionBar widget

Create `lib/features/forms/presentation/widgets/form_viewer_action_bar.dart` by extracting `_buildQuickActionBar` (lines 332-372). Tokenize.

```dart
// lib/features/forms/presentation/widgets/form_viewer_action_bar.dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/forms/data/registries/form_quick_action_registry.dart';
import 'package:construction_inspector/features/forms/data/models/models.dart';

// FROM SPEC: Extract action bar for line count reduction
class FormViewerActionBar extends StatelessWidget {
  final FormResponse response;
  final Map<String, dynamic> responseData;
  final VoidCallback onAutoFill;
  final VoidCallback onPreview;
  final VoidCallback onSave;
  final bool saving;
  final bool dirty;

  const FormViewerActionBar({
    super.key,
    required this.response,
    required this.responseData,
    required this.onAutoFill,
    required this.onPreview,
    required this.onSave,
    required this.saving,
    required this.dirty,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    // NOTE: Full quick action bar from lines 332-372, tokenized
    // Replace raw IconButton with AppButton.icon
    // Replace raw TextButton with AppButton.text
    // Replace DesignConstants.space* with spacing.*
    return const SizedBox.shrink(); // placeholder
  }
}
```

#### Step 4.11.2: Extract FormViewerSections widget

Create `lib/features/forms/presentation/widgets/form_viewer_sections.dart` by extracting `_buildTestsSection`, `_buildProctorsSection`, `_buildStandardsSection`, `_buildRemarksSection` (lines 398-636). These all follow the same pattern and use `AppFormSection` organisms from P3.

```dart
// lib/features/forms/presentation/widgets/form_viewer_sections.dart
import 'package:flutter/material.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import 'package:construction_inspector/features/forms/data/models/models.dart';

// FROM SPEC: Form viewer sections use AppFormSection organism
class FormViewerTestsSection extends StatelessWidget {
  final Map<String, dynamic> responseData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;

  const FormViewerTestsSection({
    super.key,
    required this.responseData,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = FieldGuideSpacing.of(context);
    // NOTE: Copy from _buildTestsSection, use AppFormSection organism
    return const SizedBox.shrink();
  }
}

// NOTE: Similar pattern for ProctorsSection, StandardsSection, RemarksSection
// Each receives responseData + onDataChanged callback
// Each uses AppFormSection from design system organisms
```

#### Step 4.11.3: Update form_viewer_screen.dart

Slim to ~300 lines. Keep state management (loading, saving, dirty tracking), lifecycle, and `_load()`/`_save()` methods. Import extracted widgets.

#### Step 4.11.4: Verify form_viewer decomposition

```
pwsh -Command "flutter analyze lib/features/forms/"
```

Expected: 0 errors, 0 warnings.

---

### Sub-phase 4.12: Additional Screens Tokenization + Decomposition

**Agent**: `code-fixer-agent`

#### Step 4.12.1: Tokenize gallery_screen.dart (614 lines, 24 DesignConstants refs)

**File**: `lib/features/gallery/presentation/screens/gallery_screen.dart`

Extract `_FilterSheet` (lines 305-467) -> `lib/features/gallery/presentation/widgets/gallery_filter_sheet.dart`.
Extract `_PhotoViewerScreen` (lines 468-614) -> `lib/features/gallery/presentation/widgets/gallery_photo_viewer.dart`.
Tokenize main screen (lines 21-304): all 24 `DesignConstants` -> token equivalents.

```dart
// WHY: gallery_screen has 3 classes in one file
// _FilterSheet -> GalleryFilterSheet (public)
// _PhotoViewerScreen -> GalleryPhotoViewer (public)
// Main screen stays at ~200 lines after extraction
// Replace all DesignConstants.space* -> FieldGuideSpacing.of(context).*
// Replace all DesignConstants.radius* -> FieldGuideRadii.of(context).*
// Replace raw TextButton in filter chips with AppButton.text
```

#### Step 4.12.2: Tokenize pdf_import_preview_screen.dart (631 lines, 14 DesignConstants refs)

**File**: `lib/features/pdf/presentation/screens/pdf_import_preview_screen.dart`

Extract `_BidItemPreviewCard` (lines 350-506) -> `lib/features/pdf/presentation/widgets/bid_item_preview_card.dart`.
Extract `_BidItemEditDialogBody` (lines 507-631) -> `lib/features/pdf/presentation/widgets/bid_item_edit_dialog_body.dart`.
Tokenize main screen. Target: ~250 lines.

#### Step 4.12.3: Tokenize + decompose entries_list_screen.dart (554 lines, 24 DesignConstants refs)

**File**: `lib/features/entries/presentation/screens/entries_list_screen.dart`

Extract `_buildDateGroup` + `_buildEntryCard` (lines 303-554) -> `lib/features/entries/presentation/widgets/entry_list_card.dart` + `lib/features/entries/presentation/widgets/entry_date_group.dart`.
Sliver migration: current `ListView` -> `CustomScrollView` with `SliverList`.
Tokenize all 24 refs.

```dart
// FROM SPEC: entries_list canonical layout: list (phone) -> list-detail (tablet)
// Wrap with AppResponsiveBuilder:
// - compact: full-width list
// - medium+: list on left (40%), detail on right (60%)
```

#### Step 4.12.4: Tokenize quantities_screen.dart (520 lines, 8 DesignConstants refs) + Fix #202, #203

**File**: `lib/features/quantities/presentation/screens/quantities_screen.dart`

Tokenize 8 `DesignConstants` refs.

```dart
// FROM SPEC: Fix #202 — Quantity picker search not cleared on selection
// In the bid item picker/search widget, call searchController.clear() after selection

// FROM SPEC: Fix #203 — Quantities + button workflow
// The "+" button should open the quantity calculator directly, not a picker dialog first
// Simplify the add-quantity flow to reduce taps
```

#### Step 4.12.5: Tokenize admin_dashboard_screen.dart (435 lines, 9 DesignConstants refs)

**File**: `lib/features/settings/presentation/screens/admin_dashboard_screen.dart`

Extract `_ApproveButton` (lines 412-435) -> inline or keep (small).
Tokenize 9 refs. Replace raw `ElevatedButton` in `_ApproveButton` with `AppButton.primary`.
Extract `_buildSectionHeader`, `_buildRequestTile`, `_buildMemberTile`, `_buildRoleBadge`, `_buildSyncIndicator` into a separate `admin_dashboard_widgets.dart` if total remains >300 lines.

#### Step 4.12.6: Tokenize settings_screen.dart (420 lines, 1 DesignConstants ref)

**File**: `lib/features/settings/presentation/screens/settings_screen.dart`

Tokenize the 1 ref. Add canonical layout:

```dart
// FROM SPEC: settings canonical layout: single column (phone) -> left nav + content (tablet)
// Wrap with AppResponsiveBuilder:
// - compact: single scrollable column with sections
// - medium+: NavigationRail on left with section names, content on right
```

Decompose `_buildCertificationsSection` (lines 125-155) if screen exceeds 300 lines after layout wrapper.

#### Step 4.12.7: Tokenize company_setup_screen.dart (442 lines, 17 DesignConstants refs)

**File**: `lib/features/auth/presentation/screens/company_setup_screen.dart`

Extract `_SectionCard` (lines 408-442) — evaluate if it should use `AppSectionCard` from design system instead. If yes, replace all `_SectionCard` usages with `AppSectionCard`. Tokenize 17 refs.

#### Step 4.12.8: Verify all additional screens

```
pwsh -Command "flutter analyze lib/features/gallery/ lib/features/pdf/ lib/features/entries/ lib/features/quantities/ lib/features/settings/ lib/features/auth/"
```

Expected: 0 errors, 0 warnings across all touched features.

---

### Sub-phase 4.13: Additional Widgets Tokenization

**Agent**: `code-fixer-agent`

#### Step 4.13.1: Tokenize entry_contractors_section.dart (585 lines, 17 DesignConstants refs)

**File**: `lib/features/entries/presentation/widgets/entry_contractors_section.dart`

Extract `_InlineContractorChooser` (lines 454-585) -> `lib/features/entries/presentation/widgets/inline_contractor_chooser.dart`.
Tokenize 17 refs in main section. Replace `Consumer` with `Selector` where only contractor list/count needed.
Replace raw `ElevatedButton`/`TextButton`/`IconButton` with `AppButton.*` variants.

#### Step 4.13.2: Tokenize entry_quantities_section.dart (508 lines, 0 DesignConstants refs but uses raw spacing)

**File**: `lib/features/entries/presentation/widgets/entry_quantities_section.dart`

Even though 0 explicit `DesignConstants` refs, scan for raw `EdgeInsets.*(N)`, `SizedBox(width: N)`, `BorderRadius.circular(N)` with numeric literals. Replace with token equivalents. Extract sub-widgets if >300 lines after tokenization.

#### Step 4.13.3: Decompose hub_proctor_content.dart (486 lines, 16 DesignConstants refs -> ~250)

**File**: `lib/features/forms/presentation/widgets/hub_proctor_content.dart`

This is a single `HubProctorContent` class (line 7). Decompose by extracting the main build sections into helper widgets:
- Extract proctor data entry fields -> `proctor_data_fields.dart`
- Extract proctor result display -> `proctor_result_display.dart`
Tokenize 16 refs. Target: ~250 lines in main file.

#### Step 4.13.4: Tokenize entry_forms_section.dart (356 lines, 9 DesignConstants refs)

**File**: `lib/features/entries/presentation/widgets/entry_forms_section.dart`

Tokenize 9 refs. File is near target (356 vs 300) — extract any private widget class if present to bring under 300.

#### Step 4.13.5: Tokenize photo_detail_dialog.dart (328 lines)

**File**: `lib/features/entries/presentation/widgets/photo_detail_dialog.dart`

Tokenize all spacing/radius literals. Replace raw button types with `AppButton.*`.

#### Step 4.13.6: Tokenize member_detail_sheet.dart (334 lines, 8 DesignConstants refs)

**File**: `lib/features/settings/presentation/widgets/member_detail_sheet.dart`

Tokenize 8 refs. Extract sub-widget if >300 lines after.

#### Step 4.13.7: Tokenize entry_photos_section.dart (310 lines)

**File**: `lib/features/entries/presentation/widgets/entry_photos_section.dart`

Tokenize all spacing/radius literals. Minor — near target already.

#### Step 4.13.8: Tokenize photo_name_dialog.dart (297 lines)

**File**: `lib/features/photos/presentation/widgets/photo_name_dialog.dart`

Already under 300 lines. Tokenize any remaining raw literals.

#### Step 4.13.9: Verify all additional widgets

```
pwsh -Command "flutter analyze lib/features/entries/ lib/features/forms/ lib/features/settings/ lib/features/photos/"
```

Expected: 0 errors, 0 warnings.

---

### Sub-phase 4.14: Remaining GitHub Issues

**Agent**: `code-fixer-agent`

#### Step 4.14.1: Fix #209 — Forms list internal ID visible

**File**: `lib/features/forms/presentation/screens/forms_list_screen.dart` (302 lines, 5 DesignConstants refs)

Tokenize the 5 DesignConstants refs. Fix #209 by removing internal ID display from form list tiles:

```dart
// FROM SPEC: Fix #209 — forms_list_screen shows internal form response ID in subtitle
// Find the ListTile or AppListTile that displays the form response
// Remove or hide the internal UUID from the subtitle
// Replace with a meaningful display: form type name, date created, or status
// WHY: Internal IDs are not user-facing information
```

#### Step 4.14.2: Fix #238 — no_inline_text_style 6 violations in pay apps

Scan pay application files for `TextStyle(` in presentation layer:

```
pwsh -Command "flutter analyze lib/features/ 2>&1 | Select-String 'no_inline_text_style'"
```

For each violation found in pay app files, replace inline `TextStyle(` with `AppText.*` factory constructors or `Theme.of(context).textTheme.*` slots.

```dart
// FROM SPEC: Fix #238 — 6 no_inline_text_style violations in pay apps
// Find: TextStyle(fontSize: N, fontWeight: ..., color: ...)
// Replace with: AppText.bodyMedium(...), AppText.titleSmall(...), etc.
// Or use textTheme slots: Theme.of(context).textTheme.bodyMedium
// WHY: Lint rule enforces consistent text styling through design system
```

#### Step 4.14.3: Verify remaining issues fixed

```
pwsh -Command "flutter analyze lib/features/forms/ lib/features/"
```

Expected: 0 errors, 0 warnings. Issues #209, #238 addressed.

---

### Sub-phase 4.15: Shared Widget Replacements

**Agent**: `code-fixer-agent`

#### Step 4.15.1: Replace StaleConfigWarning with AppBanner composition

**File to update**: `lib/core/router/scaffold_with_nav_bar.dart` (line 72)

Replace `StaleConfigWarning(onRetry: ...)` with an `AppBanner` composition:

```dart
// FROM SPEC: Replace StaleConfigWarning with AppBanner composition
// In scaffold_with_nav_bar.dart, replace:
//   banners.add(StaleConfigWarning(onRetry: () => appConfigProvider.checkConfig()));
// With:
banners.add(
  AppBanner(
    // WHY: AppBanner is the new composable banner from design system
    icon: Icons.wifi_off,
    message: 'Last server check was over 24 hours ago. Connect to verify your account status.',
    severity: AppBannerSeverity.warning,
    actionLabel: 'Retry',
    onAction: () => appConfigProvider.checkConfig(),
  ),
);
```

#### Step 4.15.2: Replace VersionBanner with AppBanner composition

**File to update**: `lib/core/router/scaffold_with_nav_bar.dart` (line 64)

Replace `VersionBanner(message: ...)` with `AppBanner`:

```dart
// FROM SPEC: Replace VersionBanner with AppBanner composition
// Replace:
//   banners.add(VersionBanner(message: appConfigProvider.updateMessage));
// With:
banners.add(
  AppBanner(
    icon: Icons.system_update,
    message: appConfigProvider.updateMessage ??
        'A new version is available. Please update when convenient.',
    severity: AppBannerSeverity.info,
    dismissible: true, // WHY: VersionBanner was dismissible via StatefulWidget
  ),
);
```

#### Step 4.15.3: Replace inline MaterialBanner instances in scaffold_with_nav_bar.dart

Replace the stale sync data banner (lines 81-93) and offline indicator (lines 98-114) with `AppBanner`:

```dart
// Stale sync data:
banners.add(
  AppBanner(
    icon: Icons.warning_amber,
    message: 'Data may be out of date \u2014 last synced ${syncProvider.lastSyncText}',
    severity: AppBannerSeverity.warning,
    actionLabel: 'Sync Now',
    onAction: () => syncProvider.sync(),
  ),
);

// Offline indicator:
banners.add(
  AppBanner(
    icon: Icons.cloud_off,
    message: 'You are offline. Changes will sync when connection is restored.',
    severity: AppBannerSeverity.warning,
    actionLabel: 'Retry',
    onAction: () async {
      await syncCoordinator.checkDnsReachability();
    },
  ),
);
```

#### Step 4.15.4: Remove StaleConfigWarning import and delete file

1. Remove `import` of `StaleConfigWarning` from `scaffold_with_nav_bar.dart` (via `shared.dart` barrel)
2. Delete `lib/shared/widgets/stale_config_warning.dart`
3. Remove `export 'stale_config_warning.dart';` from `lib/shared/widgets/widgets.dart`

#### Step 4.15.5: Remove VersionBanner import and delete file

1. Remove `import` of `VersionBanner` from `scaffold_with_nav_bar.dart` (via `shared.dart` barrel)
2. Delete `lib/shared/widgets/version_banner.dart`
3. Remove `export 'version_banner.dart';` from `lib/shared/widgets/widgets.dart`

#### Step 4.15.6: Update shared widgets barrel

Update `lib/shared/widgets/widgets.dart` to reflect deletions:

```dart
// lib/shared/widgets/widgets.dart
library;

// WHY: confirmation_dialog.dart, empty_state_widget.dart already deleted in P2
// contextual_feedback_overlay.dart, search_bar_field.dart moved to design system in P2
// stale_config_warning.dart, version_banner.dart deleted in this sub-phase
export 'permission_dialog.dart';
// NOTE: Only permission_dialog remains — evaluate if this barrel is still needed
```

#### Step 4.15.7: Verify shared widget replacements

```
pwsh -Command "flutter analyze lib/core/router/ lib/shared/"
```

Expected: 0 errors, 0 warnings. No references to deleted files remain.

---

## Phase 5: Performance

**Prerequisite**: Phase 4 (all sub-phases) complete. All screens decomposed, tokenized, sliver-migrated.

---

### Sub-phase 5.1: Profiling Protocol

**Agent**: `general-purpose`

#### Step 5.1.1: Document pre-optimization baseline

Create `lib/core/design_system/_performance_baseline.md` (temporary tracking file, deleted in P6):

```markdown
# Performance Baseline

## Profiling Protocol
1. Build Windows debug: `pwsh -Command "flutter run -d windows --profile"`
2. Open Flutter DevTools Performance tab
3. Navigate to each screen, perform standard interactions
4. Record: avg frame build time, avg frame render time, worst frame time, rebuild count

## Target Screens (5 worst expected)
| Screen | Avg Build (ms) | Avg Render (ms) | Worst Frame (ms) | Rebuild Count |
|--------|---------------|-----------------|-------------------|---------------|
| entry_editor | TBD | TBD | TBD | TBD |
| project_setup | TBD | TBD | TBD | TBD |
| home | TBD | TBD | TBD | TBD |
| project_list | TBD | TBD | TBD | TBD |
| mdot_hub | TBD | TBD | TBD | TBD |
```

#### Step 5.1.2: Profile entry_editor_screen

Run the app in profile mode. Navigate to entry editor with test data. Record frame times in the baseline doc. Identify any >16ms frames and their widget source.

```
pwsh -Command "flutter run -d windows --profile" -timeout 600000
```

#### Step 5.1.3: Profile remaining 4 screens

Profile `project_setup_screen`, `home_screen`, `project_list_screen`, `mdot_hub_screen`. Record baselines.

#### Step 5.1.4: Identify rebuild storms

Use Widget Rebuild Tracker in DevTools to find widgets rebuilding more than expected. Document the top 5 rebuild offenders per screen.

---

### Sub-phase 5.2: RepaintBoundary Placement

**Agent**: `code-fixer-agent`

#### Step 5.2.1: Add RepaintBoundary to scrolling list items

For each screen that uses `SliverList` or `ListView.builder`, wrap each item builder's return value with `RepaintBoundary`:

```dart
// WHY: RepaintBoundary prevents list item repaints from propagating to siblings
// Apply to: todos_screen (TodoCard), entries_list_screen (EntryListCard),
//           project_list_screen (ProjectCard), gallery_screen (photo grid items),
//           quantities_screen (bid item tiles)

// Pattern:
itemBuilder: (context, index) {
  return RepaintBoundary(
    // NOTE: Each list item gets its own repaint boundary
    child: TodoCard(
      todo: todos[index],
      // ...
    ),
  );
},
```

Files to modify:
- `lib/features/todos/presentation/screens/todos_screen.dart`
- `lib/features/entries/presentation/screens/entries_list_screen.dart`
- `lib/features/projects/presentation/screens/project_list_screen.dart`
- `lib/features/gallery/presentation/screens/gallery_screen.dart`
- `lib/features/quantities/presentation/screens/quantities_screen.dart`

#### Step 5.2.2: Add RepaintBoundary to AppBottomBar

**File**: `lib/core/design_system/atoms/app_bottom_bar.dart` (or wherever AppBottomBar lives after P2 restructure)

```dart
// WHY: AppBottomBar uses BackdropFilter which is expensive
// Wrap the entire AppBottomBar build output with RepaintBoundary
@override
Widget build(BuildContext context) {
  return RepaintBoundary(
    // NOTE: Isolates blur computation from body repaints
    child: ClipRect(
      child: BackdropFilter(
        // ... existing blur + content
      ),
    ),
  );
}
```

#### Step 5.2.3: Add RepaintBoundary to AppGlassCard

**File**: `lib/core/design_system/surfaces/app_glass_card.dart` (or wherever after P2 restructure)

```dart
// WHY: AppGlassCard uses BackdropFilter — expensive repaint
@override
Widget build(BuildContext context) {
  return RepaintBoundary(
    // NOTE: Isolates glass blur from surrounding repaints
    child: ClipRRect(
      // ... existing blur + gradient border
    ),
  );
}
```

#### Step 5.2.4: Add RepaintBoundary to animated widgets

Wrap widgets using `AnimationController` or `AnimatedBuilder`:
- `DashboardStatCard` (animated counter)
- Any widget using `FieldGuideMotion` with `AnimatedContainer`

```dart
// WHY: Animation-driven repaints should not propagate to static siblings
return RepaintBoundary(
  child: AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      // ...
    },
  ),
);
```

#### Step 5.2.5: Add RepaintBoundary to ScaffoldWithNavBar body vs navigation

**File**: `lib/core/router/scaffold_with_nav_bar.dart`

```dart
// WHY: Body content changes should not repaint the navigation bar
body: RepaintBoundary(
  // NOTE: Isolates body repaints from nav bar
  child: Consumer2<SyncProvider, AppConfigProvider>(
    // ... existing banner + body logic
  ),
),
bottomNavigationBar: RepaintBoundary(
  // NOTE: Isolates nav bar repaints from body
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const ExtractionBanner(),
      NavigationBar(
        // ... existing nav
      ),
    ],
  ),
),
```

#### Step 5.2.6: Verify RepaintBoundary placement

```
pwsh -Command "flutter analyze"
```

Expected: 0 errors across entire codebase.

---

### Sub-phase 5.3: Re-profile and Document

**Agent**: `general-purpose`

#### Step 5.3.1: Re-profile all 5 target screens

Run profile mode again. Navigate to same screens. Record post-optimization frame times.

#### Step 5.3.2: Update baseline document with results

Update `lib/core/design_system/_performance_baseline.md` with "After" columns. Document improvements.

#### Step 5.3.3: Address any remaining >16ms frames

If any screens still show >16ms frames after RepaintBoundary pass:
1. Check for unnecessary `Selector` that returns complex objects (should return primitives)
2. Check for `setState` calls that rebuild too broadly
3. Consider `const` constructors on static sub-widgets
4. Consider `AutomaticKeepAliveClientMixin` for tab views

#### Step 5.3.4: Delete temporary baseline file

Delete `lib/core/design_system/_performance_baseline.md` — it was only for tracking during this phase.

---

## Phase 6: Polish

**Prerequisite**: Phase 5 complete. All screens performant, decomposed, tokenized.

---

### Sub-phase 6.1: Desktop Hover + Focus States

**Agent**: `code-fixer-agent`

#### Step 6.1.1: Add hover states to AppButton

**File**: `lib/core/design_system/atoms/app_button.dart` (or actual path after P2)

```dart
// FROM SPEC: Desktop hover states + focus indicators on all interactive components
// WHY: Desktop users expect visual feedback on hover

// In AppButton, add MaterialStateProperty-based styling:
style: ButtonStyle(
  overlayColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.hovered)) {
      return cs.primary.withValues(alpha: 0.08);
    }
    if (states.contains(WidgetState.focused)) {
      return cs.primary.withValues(alpha: 0.12);
    }
    return null;
  }),
  // NOTE: Focus indicator via side property
  side: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.focused)) {
      return BorderSide(color: cs.primary, width: 2.0);
    }
    return null;
  }),
),
```

#### Step 6.1.2: Add hover states to AppListTile

**File**: `lib/core/design_system/molecules/app_list_tile.dart` (or actual path)

```dart
// WHY: List tiles should highlight on hover for desktop UX
// Wrap content with Material + InkWell that responds to hover:
return Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: onTap,
    hoverColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
    focusColor: cs.primary.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(radii.md),
    child: // ... existing content
  ),
);
```

#### Step 6.1.3: Add hover states to AppSectionCard

**File**: `lib/core/design_system/surfaces/app_section_card.dart` (or actual path)

Add hover elevation change and subtle color shift when `onTap` is non-null.

#### Step 6.1.4: Add hover states to AppChip

**File**: `lib/core/design_system/atoms/app_chip.dart` (or actual path)

Chips should show hover highlight on desktop.

#### Step 6.1.5: Add focus indicators globally via ThemeData

In `AppTheme.build()`, ensure focus-related properties are set:

```dart
// In the AppTheme.build method:
focusColor: colors.gradientStart.withValues(alpha: 0.12),
hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
// WHY: Global fallback for any widget that doesn't have explicit hover/focus
```

#### Step 6.1.6: Verify hover + focus states

```
pwsh -Command "flutter analyze"
```

Expected: 0 errors.

---

### Sub-phase 6.2: Widgetbook Completion

**Agent**: `code-fixer-agent`

#### Step 6.2.1: Set up Widgetbook package

Create `widgetbook/` directory at project root with Widgetbook app:

```dart
// widgetbook/lib/main.dart
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// NOTE: Import the app's design system
import 'package:construction_inspector/core/design_system/design_system.dart';

// WHY: Widgetbook catalogs all design system components with knobs
void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        // NOTE: Organized by atomic design layer
        WidgetbookFolder(
          name: 'Tokens',
          children: [
            // Color swatches, spacing scale, radius scale, motion demos
          ],
        ),
        WidgetbookFolder(
          name: 'Atoms',
          children: [
            // AppButton, AppText, AppChip, AppDivider, AppBadge, AppAvatar, AppTooltip
          ],
        ),
        WidgetbookFolder(
          name: 'Molecules',
          children: [
            // AppTextField, AppSearchBar, AppListTile, AppDropdown, AppDatePicker, AppTabBar
          ],
        ),
        WidgetbookFolder(
          name: 'Organisms',
          children: [
            // AppFormSection, AppFormStatusBar, AppFormSectionNav, AppFormFieldGroup,
            // AppFormSummaryTile, AppFormThumbnail
          ],
        ),
        WidgetbookFolder(
          name: 'Surfaces',
          children: [
            // AppSectionCard, AppGlassCard, AppActionCard, AppStatCard
          ],
        ),
        WidgetbookFolder(
          name: 'Feedback',
          children: [
            // AppDialog, AppBottomSheet, AppSnackbar, AppBanner, AppEmptyState,
            // AppErrorState, AppLoadingState, AppContextualFeedback, AppInfoBanner
          ],
        ),
        WidgetbookFolder(
          name: 'Layout',
          children: [
            // AppScaffold, AppBottomBar, AppStickyHeader, AppResponsiveBuilder,
            // AppAdaptiveLayout, AppResponsivePadding, AppResponsiveGrid
          ],
        ),
      ],
      addons: [
        // Theme addon: dark + light
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Dark', data: AppTheme.darkTheme),
            WidgetbookTheme(name: 'Light', data: AppTheme.lightTheme),
          ],
        ),
        // Device addon: phone, tablet, desktop sizes
        DeviceFrameAddon(
          devices: [
            Devices.ios.iPhone13,
            Devices.ios.iPadPro11Inches,
            Devices.windows.wideMonitor,
          ],
        ),
      ],
    );
  }
}
```

#### Step 6.2.2: Create Widgetbook pubspec.yaml

```yaml
# widgetbook/pubspec.yaml
name: field_guide_widgetbook
description: Widgetbook for Field Guide design system
publish_to: 'none'

environment:
  sdk: ^3.10.7

dependencies:
  flutter:
    sdk: flutter
  widgetbook: ^3.10.0
  widgetbook_annotation: ^3.2.0
  construction_inspector:
    path: ..

dev_dependencies:
  widgetbook_generator: ^3.10.0
  build_runner: ^2.4.0
```

#### Step 6.2.3: Add use cases for Atoms layer

Create individual use case files in `widgetbook/lib/atoms/`:

```dart
// widgetbook/lib/atoms/app_button_use_case.dart
// FROM SPEC: Widgetbook catalog covering all design system components
// Each component gets knobs for all configurable properties

WidgetbookComponent(
  name: 'AppButton',
  useCases: [
    WidgetbookUseCase(
      name: 'Primary',
      builder: (context) => AppButton.primary(
        label: context.knobs.string(label: 'Label', initialValue: 'Submit'),
        icon: Icons.check,
        onPressed: context.knobs.boolean(label: 'Enabled', initialValue: true)
            ? () {}
            : null,
      ),
    ),
    WidgetbookUseCase(
      name: 'Secondary',
      builder: (context) => AppButton.secondary(
        label: context.knobs.string(label: 'Label', initialValue: 'Cancel'),
        onPressed: () {},
      ),
    ),
    WidgetbookUseCase(
      name: 'Ghost',
      builder: (context) => AppButton.ghost(
        label: context.knobs.string(label: 'Label', initialValue: 'Skip'),
        onPressed: () {},
      ),
    ),
    WidgetbookUseCase(
      name: 'Danger',
      builder: (context) => AppButton.danger(
        label: context.knobs.string(label: 'Label', initialValue: 'Delete'),
        onPressed: () {},
      ),
    ),
  ],
),
```

#### Step 6.2.4: Add use cases for Molecules, Organisms, Surfaces, Feedback, Layout

Create use case files for each remaining layer. Each component gets at least one use case with relevant knobs.

#### Step 6.2.5: Verify Widgetbook builds

```
pwsh -Command "cd widgetbook; flutter pub get; flutter analyze"
```

Expected: Widgetbook compiles and runs without errors.

---

### Sub-phase 6.3: Documentation Updates

**Agent**: `general-purpose`

#### Step 6.3.1: Update .claude/CLAUDE.md

Update the project structure section, component count, and design system description:

```markdown
# Changes to .claude/CLAUDE.md:

## Project Structure — update core/ description:
# Before:
# core/       # Cross-cutting: bootstrap, config, database (v50, 36 tables), design_system (24 components), di, driver, logging, router, theme
# After:
# core/       # Cross-cutting: bootstrap, config, database (v50, 36 tables), design_system (56 components, atomic design), di, driver, logging, router, theme

## Add new section after "Data Flow":
## Design System
# ```
# lib/core/design_system/
# +-- tokens/     # FieldGuideColors, FieldGuideSpacing, FieldGuideRadii, FieldGuideMotion, FieldGuideShadows, AppColors, DesignConstants
# +-- atoms/      # AppButton, AppText, AppChip, AppDivider, AppBadge, AppAvatar, AppTooltip
# +-- molecules/  # AppTextField, AppSearchBar, AppListTile, AppDropdown, AppDatePicker, AppTabBar
# +-- organisms/  # AppFormSection, AppFormStatusBar, AppFormSectionNav, AppFormFieldGroup, AppFormSummaryTile, AppFormThumbnail
# +-- surfaces/   # AppSectionCard, AppGlassCard, AppActionCard, AppStatCard
# +-- feedback/   # AppDialog, AppBottomSheet, AppSnackbar, AppBanner, AppEmptyState, AppErrorState, AppLoadingState, AppContextualFeedback, AppInfoBanner
# +-- layout/     # AppScaffold, AppBottomBar, AppStickyHeader, AppResponsiveBuilder, AppAdaptiveLayout, AppResponsivePadding, AppResponsiveGrid, AppBreakpoint
# +-- animation/  # AppStaggeredList, AppFadeIn, AppSlideIn, AppScaleIn
# ```
# Token access: `FieldGuideSpacing.of(context).md`, `FieldGuideRadii.of(context).lg`, etc.
# 2 themes: dark + light (high contrast removed)

## Update Gotchas:
# Add: **Density is automatic** -- selected by breakpoint, no user toggle. Widgetbook has knobs for QA.
# Add: **AppBanner replaces StaleConfigWarning + VersionBanner** -- use AppBanner compositions in scaffold_with_nav_bar.dart
# Update custom lint count from 52 to 62 (10 new rules)

## Update Custom Lint Package:
# `fg_lint_packages/field_guide_lints/` -- 62 rules in 4 categories: architecture (33), data safety (11), sync integrity (10), test quality (8)
```

#### Step 6.3.2: Update .claude/docs/directory-reference.md

Add the new `design_system/` subdirectory structure with all folders and files.

#### Step 6.3.3: Update architecture guide

**File**: `.claude/skills/implement/references/architecture-guide.md`

Add token system documentation, responsive layout patterns, and updated component inventory.

#### Step 6.3.4: Update worker-rules.md

**File**: `.claude/skills/implement/references/worker-rules.md`

Add rules for:
- Always use `FieldGuideSpacing.of(context)` instead of `DesignConstants.space*`
- Always use `AppButton.*` instead of raw Flutter buttons
- Always use `AppBanner` instead of raw `MaterialBanner`
- Always wrap list items with `RepaintBoundary`
- Screen files must stay under 300 lines

#### Step 6.3.5: Update reviewer-rules.md

**File**: `.claude/skills/implement/references/reviewer-rules.md`

Add review checks for:
- Token usage (no magic numbers in presentation)
- Component compliance (no raw widgets where design system wrapper exists)
- File size limits (300 lines)
- RepaintBoundary on list items and expensive widgets

#### Step 6.3.6: Update .claude/rules/architecture.md

Add new anti-patterns to the "Key Anti-Patterns" section:

```markdown
# Add to Key Anti-Patterns:
- No raw `ElevatedButton`, `TextButton`, `OutlinedButton`, `IconButton` -- use `AppButton.*`
- No raw `Divider` -- use `AppDivider`
- No raw `Tooltip` -- use `AppTooltip`
- No raw `DropdownButton` -- use `AppDropdown`
- No raw `MaterialBanner` -- use `AppBanner`
- No hardcoded `EdgeInsets.*(N)` with numeric literals -- use `FieldGuideSpacing.of(context).*`
- No hardcoded `BorderRadius.circular(N)` with numeric literals -- use `FieldGuideRadii.of(context).*`
- No hardcoded `Duration(milliseconds: N)` in presentation -- use `FieldGuideMotion.of(context).*`
- No `Navigator.push`/`Navigator.pop` -- use GoRouter
```

---

### Sub-phase 6.4: HTTP Driver + Logging Updates

**Agent**: `code-fixer-agent`

#### Step 6.4.1: Add TestingKeys for new design system components

**File**: `lib/shared/testing_keys/common_keys.dart` (or create `design_system_keys.dart`)

```dart
// lib/shared/testing_keys/design_system_keys.dart
import 'package:flutter/material.dart';

// FROM SPEC: TestingKeys for all new design system components
class DesignSystemKeys {
  DesignSystemKeys._();

  // Buttons
  static const Key primaryButton = Key('ds_primary_button');
  static const Key secondaryButton = Key('ds_secondary_button');
  static const Key ghostButton = Key('ds_ghost_button');
  static const Key dangerButton = Key('ds_danger_button');

  // Banners
  static const Key appBanner = Key('ds_app_banner');
  static const Key appBannerDismiss = Key('ds_app_banner_dismiss');
  static const Key appBannerAction = Key('ds_app_banner_action');

  // Layout
  static const Key navigationRail = Key('ds_navigation_rail');
  static const Key responsiveBuilder = Key('ds_responsive_builder');

  // Form organisms
  static const Key formSection = Key('ds_form_section');
  static const Key formStatusBar = Key('ds_form_status_bar');
  static const Key formSectionNav = Key('ds_form_section_nav');
}
```

Then add `export 'design_system_keys.dart';` to `lib/shared/testing_keys/testing_keys.dart`.

#### Step 6.4.2: Update HTTP driver screen test flows

**File**: `lib/core/driver/routes/` (relevant route files)

Update any test flows that reference decomposed screen structures. For example, if driver tests tap on specific widgets that were renamed during decomposition, update the key references.

#### Step 6.4.3: Add responsive testing endpoints to driver

```dart
// WHY: HTTP driver needs endpoints to test responsive behavior
// Add to driver route registration:

// GET /diagnostics/breakpoint — returns current breakpoint info
// GET /diagnostics/navigation-mode — returns 'bottom_nav' or 'rail'
// GET /diagnostics/density — returns current density mode

// NOTE: These read from the responsive layout state to verify
// correct breakpoint/density in automated tests
```

#### Step 6.4.4: Add Logger.ui category for component lifecycle

```dart
// WHY: New logging category for UI component lifecycle events
// In lib/core/logging/ — add or extend Logger:

// Log responsive breakpoint changes:
Logger.ui('Breakpoint changed: compact -> medium');

// Log density switches:
Logger.ui('Density switched: standard -> compact');

// Log animation overrides:
Logger.ui('Motion reduced: accessibility setting detected');
```

#### Step 6.4.5: Verify driver + logging updates

```
pwsh -Command "flutter analyze lib/core/driver/ lib/core/logging/ lib/shared/testing_keys/"
```

Expected: 0 errors.

---

### Sub-phase 6.5: Golden Test Updates

**Agent**: `qa-testing-agent`

#### Step 6.5.1: Delete high contrast golden baselines

Delete `test/golden/themes/high_contrast_theme_test.dart` entirely (if not already deleted in P1).

Remove HC variants from golden test files:
- `test/golden/components/dashboard_widgets_test.dart`
- `test/golden/components/form_fields_test.dart`
- `test/golden/components/quantity_cards_test.dart`
- `test/golden/states/empty_state_test.dart`
- `test/golden/states/error_state_test.dart`
- `test/golden/states/loading_state_test.dart`
- `test/golden/widgets/confirmation_dialog_test.dart`
- `test/golden/widgets/entry_card_test.dart`
- `test/golden/widgets/project_card_test.dart`

```dart
// WHY: HC theme removed — golden tests should only cover dark + light
// In each file, find and remove test cases like:
//   testGolden('widget - high contrast', ...);
// or blocks gated by AppThemeMode.highContrast
```

#### Step 6.5.2: Regenerate golden baselines for updated components

```
pwsh -Command "flutter test --update-goldens test/golden/"
```

This regenerates all `.png` baselines to reflect the tokenized, decomposed UI.

#### Step 6.5.3: Add golden baselines for new design system components

Create new golden test files for key new components:

```dart
// test/golden/design_system/app_button_test.dart
// FROM SPEC: Add baselines for new components across dark/light and phone/tablet

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_inspector/core/design_system/design_system.dart';
import '../test_helpers.dart';

void main() {
  testWidgetInAllThemes('AppButton primary - dark/light', (tester, theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: AppButton.primary(
              label: 'Submit',
              icon: Icons.check,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/app_button_primary_${theme.brightness.name}.png'),
    );
  });

  // NOTE: Add similar tests for secondary, ghost, danger variants
  // Add tests for AppBanner, AppSearchBar, AppDivider, AppBadge
}
```

#### Step 6.5.4: Verify golden tests pass

```
pwsh -Command "flutter test test/golden/"
```

Expected: All golden tests pass with updated baselines.

---

### Sub-phase 6.6: Flip Lint Rules to Error Severity

**Agent**: `code-fixer-agent`

#### Step 6.6.1: Verify zero violations at WARNING severity

Before flipping to ERROR, confirm zero violations exist:

```
pwsh -Command "flutter analyze 2>&1 | Select-String 'no_raw_button|no_raw_divider|no_raw_tooltip|no_raw_dropdown|no_hardcoded_spacing|no_hardcoded_radius|no_hardcoded_duration|no_raw_navigator|prefer_design_system_banner'"
```

Expected: 0 matches. If any violations remain, fix them first.

#### Step 6.6.2: Update all 10 new lint rules to ERROR severity

For each of the 10 new lint rules in `fg_lint_packages/field_guide_lints/lib/architecture/rules/`:

```dart
// Change in each rule file:
// Before:
static const _code = LintCode(
  name: 'no_raw_button',
  problemMessage: '...',
  correctionMessage: '...',
  errorSeverity: ErrorSeverity.WARNING, // WHY: was WARNING during migration
);

// After:
static const _code = LintCode(
  name: 'no_raw_button',
  problemMessage: '...',
  correctionMessage: '...',
  errorSeverity: ErrorSeverity.ERROR, // FROM SPEC: flip to ERROR after zero violations confirmed
);
```

Files to update (10 rules):
1. `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_button.dart`
2. `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_divider.dart`
3. `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_tooltip.dart`
4. `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_dropdown.dart`
5. `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_spacing.dart`
6. `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_radius.dart`
7. `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_duration.dart`
8. `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_navigator.dart`
9. `fg_lint_packages/field_guide_lints/lib/architecture/rules/prefer_design_system_banner.dart`
10. `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_snackbar.dart` (if separate from existing `no_direct_snackbar`)

#### Step 6.6.3: Verify zero violations at ERROR severity

```
pwsh -Command "flutter analyze"
```

Expected: 0 errors, 0 warnings. All new lint rules now enforced at ERROR level.

---

### Sub-phase 6.7: Final Cleanup Checklist

**Agent**: `general-purpose`

#### Step 6.7.1: Full analyzer pass

```
pwsh -Command "flutter analyze"
```

Expected: 0 errors, 0 warnings across entire codebase.

#### Step 6.7.2: Verify no orphaned files

Check that all moved/deleted files have been properly handled:

```dart
// Files that should be DELETED:
// - lib/shared/widgets/stale_config_warning.dart
// - lib/shared/widgets/version_banner.dart
// - lib/shared/widgets/empty_state_widget.dart (merged into AppEmptyState in P2)
// - lib/shared/widgets/confirmation_dialog.dart (merged into AppDialog in P2)
// - test/golden/themes/high_contrast_theme_test.dart

// Files that should be MOVED (originals deleted):
// - lib/core/theme/field_guide_colors.dart -> lib/core/design_system/tokens/
// - lib/core/theme/design_constants.dart -> lib/core/design_system/tokens/
// - lib/core/theme/colors.dart -> lib/core/design_system/tokens/app_colors.dart
// - lib/shared/widgets/search_bar_field.dart -> lib/core/design_system/molecules/
// - lib/shared/widgets/contextual_feedback_overlay.dart -> lib/core/design_system/feedback/
// - lib/shared/utils/snackbar_helper.dart -> lib/core/design_system/feedback/app_snackbar.dart
```

Verify none of the original files still exist at old paths.

#### Step 6.7.3: Verify barrel files reflect current exports

Check:
- `lib/core/design_system/design_system.dart` — exports all sub-barrels
- `lib/core/design_system/tokens/tokens.dart` — exports all token files
- `lib/core/design_system/atoms/atoms.dart` — exports all atoms
- `lib/core/design_system/molecules/molecules.dart` — exports all molecules
- `lib/core/design_system/organisms/organisms.dart` — exports all organisms
- `lib/core/design_system/surfaces/surfaces.dart` — exports all surfaces
- `lib/core/design_system/feedback/feedback.dart` — exports all feedback components
- `lib/core/design_system/layout/layout.dart` — exports all layout components
- `lib/core/design_system/animation/animation.dart` — exports all animation components
- `lib/shared/widgets/widgets.dart` — only exports `permission_dialog.dart`

#### Step 6.7.4: Verify all imports updated after file moves

```
pwsh -Command "flutter analyze"
```

If any "uri doesn't exist" or "undefined class" errors appear, fix the imports. The barrel re-export strategy should prevent most breakage, but verify.

#### Step 6.7.5: Verify all 11 GitHub issues addressed

| Issue | Fix Location | Status |
|-------|-------------|--------|
| #165 | project_setup_screen.dart (P4a) | Verify fixed |
| #200 | project_dashboard_screen.dart DraftsPill (P4.9) | Verify fixed |
| #202 | quantities_screen.dart search clear (P4.12.4) | Verify fixed |
| #203 | quantities_screen.dart + button workflow (P4.12.4) | Verify fixed |
| #207 | project_dashboard_screen.dart empty-state button (P4.9) | Verify fixed |
| #208 | project_dashboard_screen.dart gradient removal (P4.9) | Verify fixed |
| #209 | forms_list_screen.dart internal ID (P4.14.1) | Verify fixed |
| #233 | project_dashboard_screen.dart button consistency (P4.9) | Verify fixed |
| #238 | pay apps TextStyle violations (P4.14.2) | Verify fixed |
| Additional issues from P4a | Verify in P4a plan | Verify fixed |

#### Step 6.7.6: Final analyze confirmation

```
pwsh -Command "flutter analyze"
```

Expected: 0 errors, 0 warnings. Design system overhaul complete.
