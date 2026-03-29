# UI Refactor v2 — Phases 9–12 (Final Polish)

**Created**: 2026-03-28
**Scope**: Auth screens, bottom sheets/dialogs, performance, cleanup
**Depends on**: Phases 1–8 (design system + all screen rewrites complete)

---

## Phase 9: Auth Screens — Light Refresh

**Goal**: Auth screens are already mostly clean (Theme.of(context).textTheme used correctly). Only fix actual violations: hardcoded AppTheme color tokens and raw TextStyle instances. Do NOT over-engineer — these screens are simple and rarely change.

### Sub-phase 9.A: UpdateRequiredScreen Token Fix

**Files:**
- Modify: `lib/features/auth/presentation/screens/update_required_screen.dart`

**Agent**: `auth-agent`

#### Step 9.A.1: Replace AppTheme color tokens with semantic equivalents

The file has 7 violations across 147 lines. Replace each:

```dart
// WHY: AppTheme.primaryCyan → cs.primary for theme-awareness
// BEFORE (line 38):
color: AppTheme.primaryCyan,
// AFTER:
color: cs.primary,

// BEFORE (line 52):
color: AppTheme.textSecondary,
// AFTER:
color: cs.onSurfaceVariant,

// BEFORE (line 60):
color: AppTheme.primaryCyan.withValues(alpha: 0.1),
// AFTER:
color: cs.primary.withValues(alpha: 0.1),

// BEFORE (line 74):
color: AppTheme.textSecondary,
// AFTER:
color: cs.onSurfaceVariant,

// BEFORE (line 92):
backgroundColor: AppTheme.primaryCyan,
// AFTER:
backgroundColor: cs.primary,

// BEFORE (line 104):
color: AppTheme.textTertiary,
// AFTER:
color: fg.textTertiary,
```

#### Step 9.A.2: Replace raw TextStyle instances with textTheme

```dart
// BEFORE (lines 73-76):
style: TextStyle(
  color: AppTheme.textSecondary,
  fontSize: 13,
),
// AFTER:
style: tt.bodySmall?.copyWith(
  color: cs.onSurfaceVariant,
),

// BEFORE (lines 103-106):
style: TextStyle(
  color: AppTheme.textTertiary,
  fontSize: 13,
),
// AFTER:
style: tt.bodySmall?.copyWith(
  color: fg.textTertiary,
),

// BEFORE (lines 131-134) in _InfoRow:
style: TextStyle(
  color: AppTheme.textSecondary,
  fontSize: 14,
),
// AFTER:
style: tt.bodyMedium?.copyWith(
  color: cs.onSurfaceVariant,
),

// BEFORE (lines 138-141) in _InfoRow:
style: const TextStyle(
  fontWeight: FontWeight.w600,
  fontSize: 14,
),
// AFTER:
style: tt.bodyMedium?.copyWith(
  fontWeight: FontWeight.w600,
),
```

#### Step 9.A.3: Add theme accessors at top of build methods

```dart
// WHY: One-time declarations, used by all replacements above
final cs = Theme.of(context).colorScheme;
final tt = Theme.of(context).textTheme;
final fg = FieldGuideColors.of(context);
```

Add to `UpdateRequiredScreen.build()` (after line 23) and `_InfoRow.build()` (after line 125).

#### Step 9.A.4: Remove unused AppTheme import

After all tokens replaced, remove `import 'package:construction_inspector/core/theme/app_theme.dart';` (line 4) and add `import 'package:construction_inspector/core/theme/colors.dart';` for `FieldGuideColors`.

### Sub-phase 9.B: Auth Screen Token Sweep (remaining 9 screens)

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`
- Modify: `lib/features/auth/presentation/screens/register_screen.dart`
- Modify: `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- Modify: `lib/features/auth/presentation/screens/otp_verification_screen.dart`
- Modify: `lib/features/auth/presentation/screens/update_password_screen.dart`
- Modify: `lib/features/auth/presentation/screens/profile_setup_screen.dart`
- Modify: `lib/features/auth/presentation/screens/company_setup_screen.dart`
- Modify: `lib/features/auth/presentation/screens/pending_approval_screen.dart`
- Modify: `lib/features/auth/presentation/screens/account_status_screen.dart`

**Agent**: `auth-agent`

#### Step 9.B.1: Sweep for remaining AppTheme.textPrimary/textSecondary references

Per grep results, these auth screens still reference old tokens:
- `login_screen.dart` — 2 `AppTheme.textPrimary/textSecondary`
- `register_screen.dart` — 1 `AppTheme.textSecondary`
- `forgot_password_screen.dart` — 1 `AppTheme.textSecondary`
- `otp_verification_screen.dart` — 1 `AppTheme.textSecondary`
- `update_password_screen.dart` — 1 `AppTheme.textSecondary`
- `profile_setup_screen.dart` — 1 `AppTheme.textSecondary`
- `company_setup_screen.dart` — 2 `AppTheme.textSecondary`
- `pending_approval_screen.dart` — 1 `AppTheme.textSecondary`
- `account_status_screen.dart` — 1 `AppTheme.textSecondary`

Apply the standard mapping:
- `AppTheme.textPrimary` → `cs.onSurface`
- `AppTheme.textSecondary` → `cs.onSurfaceVariant`

NOTE: Only touch color tokens. Do NOT restructure layout, extract widgets, or add design-system components. These screens are clean otherwise.

### Sub-phase 9.K: Quality Gate

**Agent**: `qa-testing-agent`

#### Step 9.K.1: Run analysis and tests
```
pwsh -Command "flutter analyze lib/features/auth/"
pwsh -Command "flutter test test/features/auth/"
```

#### Step 9.K.2: Verify zero remaining violations in auth screens
Grep for `AppTheme\.text` in `lib/features/auth/presentation/screens/`. Expected: 0 matches.

---

## Phase 10: Bottom Sheets + Dialogs

**Goal**: Migrate all bottom sheets and dialogs to use semantic theme tokens. Wrap existing content with consistent patterns — do NOT rewrite dialog logic or change behavior.

### Sub-phase 10.A: Shared Confirmation Dialogs

**Files:**
- Modify: `lib/shared/widgets/confirmation_dialog.dart`
- Modify: `lib/shared/widgets/permission_dialog.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 10.A.1: Migrate `confirmation_dialog.dart` (3 functions)

Replace AppTheme tokens in all three dialog functions:

```dart
// WHY: Dialogs inherit theme from context. Use cs/fg for consistency.

// showConfirmationDialog (line 25):
// BEFORE: Icon(icon, color: iconColor ?? AppTheme.primaryCyan)
// AFTER:  Icon(icon, color: iconColor ?? Theme.of(dialogContext).colorScheme.primary)

// showConfirmationDialog (lines 43-44):
// BEFORE: backgroundColor: AppTheme.statusError, foregroundColor: AppTheme.textInverse,
// AFTER:  backgroundColor: Theme.of(dialogContext).colorScheme.error, foregroundColor: Theme.of(dialogContext).colorScheme.onError,

// showDeleteConfirmationDialog (line 70):
// BEFORE: Icon(Icons.delete_outline, color: AppTheme.statusError)
// AFTER:  Icon(Icons.delete_outline, color: Theme.of(dialogContext).colorScheme.error)

// showDeleteConfirmationDialog (lines 86-87):
// BEFORE: backgroundColor: AppTheme.statusError, foregroundColor: AppTheme.textInverse,
// AFTER:  backgroundColor: Theme.of(dialogContext).colorScheme.error, foregroundColor: Theme.of(dialogContext).colorScheme.onError,

// showUnsavedChangesDialog (line 145):
// BEFORE: foregroundColor: AppTheme.statusError
// AFTER:  foregroundColor: Theme.of(dialogContext).colorScheme.error
```

NOTE: These functions use `dialogContext` from the builder, not `context` from the caller. Use `Theme.of(dialogContext)` throughout.

#### Step 10.A.2: Migrate `permission_dialog.dart`

Replace 8 AppTheme tokens:

| Line | Old | New |
|------|-----|-----|
| 105 | `AppTheme.primaryCyan` | `cs.primary` |
| 139 | `AppTheme.primaryCyan.withValues(alpha: 0.1)` | `cs.primary.withValues(alpha: 0.1)` |
| 142 | `AppTheme.primaryCyan.withValues(alpha: 0.3)` | `cs.primary.withValues(alpha: 0.3)` |
| 156 | `TextStyle(fontSize: 13)` | `tt.bodySmall` |
| 167 | `AppTheme.statusWarning.withValues(alpha: 0.15)` | `fg.statusWarning.withValues(alpha: 0.15)` |
| 170 | `AppTheme.statusWarning.withValues(alpha: 0.3)` | `fg.statusWarning.withValues(alpha: 0.3)` |
| 177 | `AppTheme.statusWarning` | `fg.statusWarning` |
| 182 | `TextStyle(fontSize: 13)` | `tt.bodySmall` |
| 202, 212, 222 | `AppTheme.primaryBlue` | `cs.primary` |

Add `final cs = Theme.of(context).colorScheme;` and `final tt = Theme.of(context).textTheme;` at the top of `_StoragePermissionDialogState.build()`.

NOTE: `FieldGuideColors` access needed for `statusWarning` — add `final fg = FieldGuideColors.of(context);`.

### Sub-phase 10.B: Bottom Sheet Token Migration

**Files:**
- Modify: `lib/features/entries/presentation/widgets/bid_item_picker_sheet.dart`
- Modify: `lib/features/photos/presentation/widgets/photo_source_dialog.dart`
- Modify: `lib/features/quantities/presentation/widgets/bid_item_detail_sheet.dart`
- Modify: `lib/features/pdf/presentation/widgets/extraction_detail_sheet.dart`
- Modify: `lib/features/projects/presentation/widgets/project_switcher.dart`
- Modify: `lib/features/projects/presentation/widgets/project_delete_sheet.dart`
- Modify: `lib/features/settings/presentation/widgets/member_detail_sheet.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_add_contractor_sheet.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 10.B.1: BidItemPickerSheet (bid_item_picker_sheet.dart)

5 violations:
- Line 43: `AppTheme.surfaceHighlight` → `fg.surfaceHighlight`
- Line 57-59: raw `TextStyle(fontSize: 18, fontWeight: FontWeight.bold)` → `tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)`
- Line 109: `AppTheme.textSecondary` → `cs.onSurfaceVariant`
- Line 121: `TextStyle(fontSize: 13)` → `tt.bodySmall`
- Line 125: `TextStyle(fontSize: 11)` → `tt.labelSmall`

NOTE: This file uses `StatefulBuilder` inside `showModalBottomSheet`. Theme access must go inside the builder where context is available.

#### Step 10.B.2: PhotoSourceDialog (photo_source_dialog.dart)

Already clean — no AppTheme tokens, uses default ListTile styling. **Skip.**

#### Step 10.B.3: BidItemDetailSheet (bid_item_detail_sheet.dart) — heaviest migration

14 raw TextStyle, 9 AppTheme color references. This is the most violation-dense file.

Pattern — replace ALL `AppTheme.*` color tokens:
- `AppTheme.textTertiary` → `fg.textTertiary` (lines 55, 301)
- `AppTheme.primaryCyan` → `cs.primary` (lines 68, 69, 71, 80, 153, 267)
- `AppTheme.textPrimary` → `cs.onSurface` (lines 91, 127, 245)
- `AppTheme.textSecondary` → `cs.onSurfaceVariant` (lines 107, 139, 215, 238, 259, 317)
- `AppTheme.surfaceElevated` → `fg.surfaceElevated` (lines 115, 224)
- `AppTheme.surfaceHighlight` → `fg.surfaceHighlight` (lines 118, 228)
- `AppTheme.statusSuccess` → `fg.statusSuccess` (lines 163, 189, 201)
- `AppTheme.statusError` → `cs.error` (lines 171, 189, 201)
- `AppTheme.statusWarning` → `fg.statusWarning` (line 171)
- `AppTheme.surfaceBright` → `fg.surfaceBright` (line 187)

Pattern — replace ALL raw TextStyle with textTheme:
- `TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryCyan)` → `tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)`
- `TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)` → `tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)`
- `TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)` → `tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)`
- `TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5)` → `tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.5)`
- `TextStyle(fontSize: 11, color: AppTheme.textTertiary)` → `tt.labelSmall?.copyWith(color: fg.textTertiary)`
- `TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)` → `tt.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color)`
- `TextStyle(fontSize: 12, color: AppTheme.textSecondary)` → `tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)`
- `TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ...)` → `tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: ...)`
- `TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)` → `tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)`
- `TextStyle(color: AppTheme.textSecondary)` → `tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)`
- `TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)` → `tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)`
- `TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)` → `tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)`

Add theme accessors in `build()` after line 32 and pass `tt`/`cs`/`fg` to `_buildDetailQuantityCard`.

#### Step 10.B.4: ExtractionDetailSheet (extraction_detail_sheet.dart)

5 `AppTheme.textPrimary/textSecondary` references. Apply standard mapping. Also has raw TextStyle instances — migrate to `tt.*`.

#### Step 10.B.5: ProjectSwitcherSheet (project_switcher.dart)

2 `Colors.*` references (in `BoxShadow`). Replace:
- `Colors.black.withValues(alpha: ...)` → `cs.shadow.withValues(alpha: ...)`

Also fix hardcoded `BorderRadius.circular(16)` → `BorderRadius.circular(AppTheme.radiusLarge)`.

#### Step 10.B.6: ProjectDeleteSheet (project_delete_sheet.dart) — 6 Colors.* violations

```dart
// BEFORE (line 58): color: Colors.orange.shade50,
// AFTER:  color: fg.statusWarning.withValues(alpha: 0.1),

// BEFORE (line 60): border: Border.all(color: Colors.orange.shade200),
// AFTER:  border: Border.all(color: fg.statusWarning.withValues(alpha: 0.3)),

// BEFORE (line 64): Icon(Icons.warning_amber, color: Colors.orange.shade700),
// AFTER:  Icon(Icons.warning_amber, color: fg.statusWarning),

// BEFORE (line 69): TextStyle(color: Colors.orange.shade900),
// AFTER:  style: tt.bodyMedium?.copyWith(color: fg.statusWarning),

// BEFORE (line 139): backgroundColor: _deleteFromDatabase ? Colors.red : null,
// AFTER:  backgroundColor: _deleteFromDatabase ? cs.error : null,

// BEFORE (line 140): foregroundColor: _deleteFromDatabase ? Colors.white : null,
// AFTER:  foregroundColor: _deleteFromDatabase ? cs.onError : null,
```

Also replace hardcoded `EdgeInsets.all(16)` with `EdgeInsets.all(AppTheme.space4)` and `SizedBox(height: 8/12/16)` with `SizedBox(height: AppTheme.space2/space3/space4)`.

#### Step 10.B.7: MemberDetailSheet (member_detail_sheet.dart) — 10+ violations

Key replacements:
- `Colors.grey[300]` (line 54) → `cs.outlineVariant`
- `Colors.grey` (lines 229, 247) → `cs.onSurfaceVariant`
- `AppTheme.primaryCyan` (lines 65, 69) → `cs.primary`
- `AppTheme.success` (lines 195, 200, 206, 244) → `fg.statusSuccess`
- `AppTheme.statusError` (lines 196, 201, 209, 311, 333) → `cs.error`
- Raw `TextStyle(fontSize: 13)` (lines 233, 236) → `tt.bodySmall`
- Raw `TextStyle(fontSize: 11)` (line 260) → `tt.labelSmall`
- Raw `TextStyle(fontSize: 18)` (line 72) → `tt.titleMedium`
- Hardcoded `EdgeInsets` (lines 37-41, 251) → `AppTheme.space4`
- Hardcoded `BorderRadius.circular(2/12)` → `AppTheme.radiusSmall`/`AppTheme.radiusMedium`

Also migrate 4 `ScaffoldMessenger.of(context).showSnackBar` calls (lines 303, 308, 351, 368) to `SnackBarHelper`:
```dart
// BEFORE:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Role updated to ${_selectedRole.displayName}')),
);
// AFTER:
SnackBarHelper.showSuccess(context, 'Role updated to ${_selectedRole.displayName}');

// BEFORE:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(adminProvider.error ?? 'Failed to update role'),
    backgroundColor: AppTheme.statusError,
  ),
);
// AFTER:
SnackBarHelper.showError(context, adminProvider.error ?? 'Failed to update role');
```

#### Step 10.B.8: ReportAddContractorSheet (report_add_contractor_sheet.dart)

Light touch — replace any hardcoded `EdgeInsets.all(16)` → `AppTheme.space4`. Check for AppTheme color tokens.

### Sub-phase 10.C: Shared Dialogs — Remaining Widgets

**Files:**
- Modify: `lib/shared/widgets/empty_state_widget.dart`
- Modify: `lib/shared/widgets/search_bar_field.dart`
- Modify: `lib/shared/widgets/contextual_feedback_overlay.dart`
- Modify: `lib/shared/widgets/stale_config_warning.dart`
- Modify: `lib/shared/widgets/version_banner.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 10.C.1: EmptyStateWidget (empty_state_widget.dart)

3 violations:
```dart
// BEFORE (line 36): color: AppTheme.textTertiary,
// AFTER:  color: FieldGuideColors.of(context).textTertiary,

// BEFORE (line 48): color: AppTheme.textSecondary,
// AFTER:  color: Theme.of(context).colorScheme.onSurfaceVariant,
```

Also replace `EdgeInsets.all(32)` → `EdgeInsets.all(AppTheme.space8)`.

#### Step 10.C.2: SearchBarField (search_bar_field.dart)

Already clean — uses `AppTheme.radiusMedium` and `AppTheme.space4` properly. **Skip.**

#### Step 10.C.3: ContextualFeedbackOverlay (contextual_feedback_overlay.dart)

3 violations:
- Line 47: `Colors.transparent` — OK, leave as-is (Material scaffold pattern)
- Line 68: `AppTheme.statusSuccess`/`AppTheme.statusError` → `fg.statusSuccess`/`cs.error`
- Line 72: `Colors.black.withValues(alpha: 0.2)` → pass shadow color via parameter or use `cs.shadow`
- Line 83: `AppTheme.textInverse` → `cs.onPrimary`
- Line 91: `AppTheme.textInverse` → `cs.onPrimary`

NOTE: This widget takes `context` but builds in an OverlayEntry. Theme access via `Theme.of(context)` works because the overlay shares the same Theme ancestor. Add `final cs`, `final fg` inside the `OverlayEntry` builder.

#### Step 10.C.4: StaleConfigWarning + VersionBanner

StaleConfigWarning — 3 violations:
- `AppTheme.statusWarning` (lines 20, 21) → `fg.statusWarning`
- `AppTheme.textPrimary` (line 24 via TextStyle) → `cs.onSurface`
- `TextStyle(fontSize: 13)` → `tt.bodySmall`

VersionBanner — 3 violations:
- `AppTheme.statusInfo` (lines 31, 32) → `fg.statusInfo`
- `AppTheme.textPrimary` (line 36 via TextStyle) → `cs.onSurface`
- `TextStyle(fontSize: 13)` → `tt.bodySmall`

### Sub-phase 10.D: Feature Dialogs

**Files:**
- Modify: `lib/features/entries/presentation/widgets/add_equipment_dialog.dart`
- Modify: `lib/features/entries/presentation/widgets/add_personnel_type_dialog.dart`
- Modify: `lib/features/entries/presentation/widgets/form_selection_dialog.dart`
- Modify: `lib/features/entries/presentation/widgets/photo_detail_dialog.dart`
- Modify: `lib/features/photos/presentation/widgets/photo_name_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/add_location_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/add_equipment_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/add_contractor_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/bid_item_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/removal_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/pay_item_source_dialog.dart`
- Modify: `lib/features/settings/presentation/widgets/sign_out_dialog.dart`
- Modify: `lib/features/settings/presentation/widgets/clear_cache_dialog.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 10.D.1: Sweep all feature dialogs for AppTheme tokens

For each dialog file, apply the standard mapping:
- `AppTheme.primaryCyan` → `cs.primary`
- `AppTheme.textPrimary` → `cs.onSurface`
- `AppTheme.textSecondary` → `cs.onSurfaceVariant`
- `AppTheme.textTertiary` → `fg.textTertiary`
- `AppTheme.statusError` → `cs.error`
- `AppTheme.statusSuccess` → `fg.statusSuccess`
- `AppTheme.textInverse` → `cs.onError` (when used with error background)
- `AppTheme.surfaceElevated` → `fg.surfaceElevated`
- Raw `TextStyle(fontSize: N)` → appropriate `tt.*` token

NOTE: Each dialog uses `dialogContext` or `context` from `showDialog` builder. Use `Theme.of(dialogContext)` — NOT the outer context.

### Sub-phase 10.E: Report Dialogs

**Files:**
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_add_quantity_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_photo_detail_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_weather_edit_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_location_edit_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_pdf_actions_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_debug_pdf_actions_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_add_personnel_type_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_delete_personnel_type_dialog.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 10.E.1: Apply standard token mapping to all 8 report dialogs

Same pattern as 10.D.1. These files are in `report_widgets/` — each gets the standard AppTheme → cs/fg/tt replacement.

Also migrate any `ScaffoldMessenger.of(context).showSnackBar` to `SnackBarHelper.*`:
- `report_pdf_actions_dialog.dart` — 3 SnackBar calls
- `report_debug_pdf_actions_dialog.dart` — 2 SnackBar calls

### Sub-phase 10.F: Inline AlertDialog Extraction

**Files:**
- Modify: `lib/features/entries/presentation/widgets/contractor_editor_widget.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_forms_section.dart`
- Modify: `lib/features/settings/presentation/widgets/member_detail_sheet.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 10.F.1: ContractorEditorWidget inline dialogs (lines ~484, ~523)

Two inline `AlertDialog` instances: `_showAddTypeDialog` and `_showDeleteTypeDialog`. Apply token migration in-place:
- Replace any `AppTheme.statusError` → `cs.error`
- Replace raw TextStyle → `tt.*`

NOTE: Do NOT extract to separate files — these are tightly coupled to the editor's state.

#### Step 10.F.2: EntryFormsSection._confirmDeleteForm (line ~101)

Inline delete confirmation. Replace `AppTheme.statusError` → `Theme.of(context).colorScheme.error` if present.

#### Step 10.F.3: MemberDetailSheet._handleDeactivate (line ~319)

Already addressed in 10.B.7. Verify the inline AlertDialog at line 321 also gets token migration:
```dart
// BEFORE (line 333):
backgroundColor: AppTheme.statusError,
// AFTER:
backgroundColor: Theme.of(ctx).colorScheme.error,
```

### Sub-phase 10.G: SnackBar Migration — Batch

**Files:** 39 files with 102 total `ScaffoldMessenger.of(context).showSnackBar` calls (minus 5 inside `snackbar_helper.dart` itself = 97 callsites to migrate)

**Agent**: `general-purpose`

#### Step 10.G.1: Categorize each SnackBar call by type

For each of the 97 callsites, determine the correct `SnackBarHelper` method:
- Has `backgroundColor: AppTheme.statusError` or error context → `SnackBarHelper.showError(context, message)`
- Has `backgroundColor: AppTheme.statusSuccess` or success context → `SnackBarHelper.showSuccess(context, message)`
- Has `backgroundColor: AppTheme.statusWarning` → `SnackBarHelper.showWarning(context, message)`
- Has `backgroundColor: AppTheme.primaryBlue` or info context → `SnackBarHelper.showInfo(context, message)`
- Has `action:` parameter → `SnackBarHelper.showWithAction(context, message, label, callback)`
- Plain `SnackBar(content: Text(...))` with no color → `SnackBarHelper.showInfo(context, message)`

#### Step 10.G.2: Apply mechanical replacement across all 39 files

```dart
// BEFORE:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Entry saved successfully'),
    backgroundColor: AppTheme.statusSuccess,
  ),
);
// AFTER:
SnackBarHelper.showSuccess(context, 'Entry saved successfully');

// BEFORE (with action):
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Deleted'),
    action: SnackBarAction(label: 'Undo', onPressed: _undo),
  ),
);
// AFTER:
SnackBarHelper.showWithAction(context, 'Deleted', 'Undo', _undo);
```

Add `import 'package:construction_inspector/shared/utils/snackbar_helper.dart';` to each file that doesn't already import it.

#### Step 10.G.3: Update SnackBarHelper to use theme tokens

**File:** `lib/shared/utils/snackbar_helper.dart`

Replace AppTheme static colors with semantic theme tokens:
```dart
// WHY: SnackBarHelper itself needs to use theme tokens
// BEFORE:
backgroundColor: AppTheme.statusSuccess,
// AFTER:
backgroundColor: FieldGuideColors.of(context).statusSuccess,

// Apply same pattern for statusError, primaryBlue, statusWarning
```

### Sub-phase 10.H: Quality Gate

**Agent**: `qa-testing-agent`

#### Step 10.H.1: Run full analysis
```
pwsh -Command "flutter analyze lib/shared/widgets/"
pwsh -Command "flutter analyze lib/features/entries/presentation/widgets/"
pwsh -Command "flutter analyze lib/features/projects/presentation/widgets/"
pwsh -Command "flutter analyze lib/features/settings/presentation/widgets/"
pwsh -Command "flutter analyze lib/features/photos/presentation/widgets/"
pwsh -Command "flutter analyze lib/features/quantities/presentation/widgets/"
pwsh -Command "flutter analyze lib/features/pdf/presentation/widgets/"
```

#### Step 10.H.2: Run tests
```
pwsh -Command "flutter test"
```

#### Step 10.H.3: Verify SnackBar migration completeness
Grep for `ScaffoldMessenger\.of.*showSnackBar` outside of `snackbar_helper.dart`. Expected: 0 matches in `lib/` except `snackbar_helper.dart`.

---

## Phase 11: Performance Pass

**Goal**: Add targeted performance optimizations to known-expensive subtrees. No speculative optimization — only address measurable or architecturally obvious hotspots.

### Sub-phase 11.A: RepaintBoundary Placement

**Files:**
- Modify: `lib/features/entries/presentation/screens/home_screen.dart`
- Modify: `lib/features/photos/presentation/widgets/photo_thumbnail.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_stat_card.dart`
- Modify: `lib/features/entries/presentation/screens/entries_list_screen.dart`
- Modify: `lib/features/entries/presentation/widgets/draft_entry_tile.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 11.A.1: Calendar day cells in HomeScreen

`home_screen.dart` uses `table_calendar` which renders 42 day cells per month view. Wrap the `calendarBuilders` default/selected/today builders in `RepaintBoundary`:

```dart
// WHY: Calendar cells rebuild on every selectedDay change. RepaintBoundary
// prevents repainting cells whose content hasn't changed.
// NOTE: table_calendar's CalendarBuilders accept Widget Function() builders.
// Wrap the return value of each builder:
calendarBuilders: CalendarBuilders(
  defaultBuilder: (context, day, focusedDay) => RepaintBoundary(
    child: _buildDayCell(day, focusedDay),
  ),
  // same for selectedBuilder, todayBuilder, markerBuilder
),
```

#### Step 11.A.2: Photo thumbnails in grids

`photo_thumbnail.dart` renders images that are expensive to composite. Wrap the outermost widget in the `build()` method:

```dart
// WHY: Photo thumbnails contain Image widgets with BoxFit.cover.
// When the parent list scrolls, these get unnecessarily repainted.
@override
Widget build(BuildContext context) {
  return RepaintBoundary(
    child: /* existing widget tree */,
  );
}
```

#### Step 11.A.3: Dashboard stat cards

`dashboard_stat_card.dart` uses gradient or shadow decorations. Wrap in RepaintBoundary:

```dart
// WHY: Stat cards have BoxDecoration with shadows — expensive to paint.
// Dashboard rebuilds frequently as data loads.
```

#### Step 11.A.4: Entry list items

In `entries_list_screen.dart` and `draft_entry_tile.dart`, wrap each list item in `RepaintBoundary`:

```dart
// WHY: List items with status chips, date formatting, and badges
// get repainted during scroll even when content is unchanged.
itemBuilder: (context, index) => RepaintBoundary(
  child: _buildEntryTile(entries[index]),
),
```

### Sub-phase 11.B: Scroll Physics Consistency

**Files:**
- Modify: Any screen using `ListView`, `CustomScrollView`, or `SingleChildScrollView` that doesn't specify `physics`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 11.B.1: Audit and standardize scroll physics

Grep for `ListView.builder`, `CustomScrollView`, `SingleChildScrollView` across `lib/features/`. For each:
- If no `physics` specified, add `physics: const ClampingScrollPhysics()` (Android default)
- This ensures consistent scroll feel across all screens

NOTE: Do NOT change screens that already have explicit physics set. Do NOT use `BouncingScrollPhysics` — this is an Android-primary app.

### Sub-phase 11.C: Page Transition Consistency

**Files:**
- Modify: `lib/core/router/app_router.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 11.C.1: Verify all GoRoute entries use consistent transitions

Check that `pageBuilder` uses `AppTheme.animationPageTransition` duration for `CustomTransitionPage`. If any routes use default `MaterialPage` while others use custom transitions, standardize.

NOTE: Only touch routes that are inconsistent. If all routes already use the same pattern, skip this step.

### Sub-phase 11.E: Quality Gate

**Agent**: `qa-testing-agent`

#### Step 11.E.1: Run full test suite
```
pwsh -Command "flutter test"
```

#### Step 11.E.2: Verify no regressions
```
pwsh -Command "flutter analyze"
```

---

## Phase 12: Cleanup

**Goal**: Remove dead code, verify zero remaining violations, and ensure the refactor is complete. This phase is the final gatekeeper — nothing ships until all grep checks pass.

### Sub-phase 12.A: Delete Unused Widgets

**Files:**
- Delete: `lib/features/pdf/presentation/widgets/pdf_import_progress_dialog.dart` (marked `@Deprecated`)

**Agent**: `general-purpose`

#### Step 12.A.1: Verify PdfImportProgressDialog has zero importers

Grep for `PdfImportProgressDialog` and `pdf_import_progress_dialog.dart` across the entire codebase. The only references should be:
- The file itself
- `pdf_import_progress_manager.dart` (which replaced it)

If `pdf_import_progress_manager.dart` still imports it, remove that import and any references first.

#### Step 12.A.2: Delete the deprecated file

```
rm lib/features/pdf/presentation/widgets/pdf_import_progress_dialog.dart
```

#### Step 12.A.3: Scan for other dead widgets

Grep for `@Deprecated` or `// DEPRECATED` across `lib/`. Delete any fully-replaced widgets after verifying zero importers.

### Sub-phase 12.B: Final Token Sweep

**Agent**: `general-purpose`

#### Step 12.B.1: Hardcoded Color constructors

```
Grep pattern: Color\(0x
Path: lib/ (excluding lib/core/theme/)
Expected: 0 matches
```

If matches found, replace with semantic theme token per the mapping table.

#### Step 12.B.2: Direct Colors.* usage

```
Grep pattern: Colors\.
Path: lib/ (excluding lib/core/theme/)
Expected: Only Colors.transparent (acceptable in Material scaffold pattern)
```

Acceptable exceptions:
- `Colors.transparent` — used for Material overlay backgrounds
- `Colors.white`/`Colors.black` inside theme definition files only

All other `Colors.*` must be replaced with semantic tokens.

#### Step 12.B.3: Raw TextStyle without textTheme

```
Grep pattern: TextStyle\(
Path: lib/ (excluding lib/core/theme/, test/)
Expected: Only inside custom widget constructors where style is a parameter
```

Every `TextStyle(fontSize: N)` in a build method should be `tt.bodyMedium?.copyWith(...)` or similar.

#### Step 12.B.4: Remaining AppTheme.textPrimary/textSecondary

```
Grep pattern: AppTheme\.textPrimary|AppTheme\.textSecondary
Path: lib/ (excluding lib/core/theme/)
Expected: 0 matches
```

Current baseline: 228 occurrences across 70 files. After Phase 12, this must be 0.

#### Step 12.B.5: Remaining AppTheme.primaryCyan

```
Grep pattern: AppTheme\.primaryCyan
Path: lib/ (excluding lib/core/theme/)
Expected: 0 matches
```

#### Step 12.B.6: Remaining AppTheme.statusError/statusSuccess

```
Grep pattern: AppTheme\.statusError|AppTheme\.statusSuccess|AppTheme\.statusWarning|AppTheme\.statusInfo
Path: lib/ (excluding lib/core/theme/)
Expected: 0 matches
```

#### Step 12.B.7: Remaining AppTheme.surfaceElevated/surfaceHighlight

```
Grep pattern: AppTheme\.surfaceElevated|AppTheme\.surfaceHighlight|AppTheme\.surfaceBright
Path: lib/ (excluding lib/core/theme/)
Expected: 0 matches
```

### Sub-phase 12.C: SnackBar Consistency Verification

**Agent**: `qa-testing-agent`

#### Step 12.C.1: Verify zero direct ScaffoldMessenger.showSnackBar calls

```
Grep pattern: ScaffoldMessenger\.of\(.*\)\.showSnackBar
Path: lib/ (excluding lib/shared/utils/snackbar_helper.dart)
Expected: 0 matches
```

Current baseline: 97 callsites across 38 files (excluding snackbar_helper.dart itself).

#### Step 12.C.2: Verify SnackBarHelper uses theme tokens

```
Grep pattern: AppTheme\.
Path: lib/shared/utils/snackbar_helper.dart
Expected: 0 matches
```

### Sub-phase 12.D: Legacy Cleanup

**Agent**: `general-purpose`

#### Step 12.D.1: Identify removable AppTheme static re-exports

Check `lib/core/theme/app_theme.dart` for static color constants that are now fully replaced by `FieldGuideColors` extension or `ColorScheme`:

Candidates for removal (only if zero references remain outside `app_theme.dart`):
- `AppTheme.textPrimary`
- `AppTheme.textSecondary`
- `AppTheme.textTertiary`
- `AppTheme.textInverse`
- `AppTheme.primaryCyan`
- `AppTheme.primaryBlue`
- `AppTheme.statusError`
- `AppTheme.statusSuccess`
- `AppTheme.statusWarning`
- `AppTheme.statusInfo`
- `AppTheme.surfaceElevated`
- `AppTheme.surfaceHighlight`
- `AppTheme.surfaceBright`
- `AppTheme.success`

For each: grep the entire `lib/` directory. If 0 references outside theme files, add `@Deprecated` annotation with migration note. Do NOT delete yet — mark deprecated so any new code gets a warning.

```dart
// WHY: Marked deprecated (not deleted) so existing code compiles
// but new code gets IDE warnings pointing to the replacement.
@Deprecated('Use Theme.of(context).colorScheme.primary instead')
static const Color primaryCyan = Color(0xFF00BCD4);
```

#### Step 12.D.2: Remove unused imports

Run `flutter analyze` — it will flag unused imports after token migration. Fix all warnings.

### Sub-phase 12.E: Final Quality Gate

**Agent**: `qa-testing-agent`

#### Step 12.E.1: Full test suite

```
pwsh -Command "flutter test"
```

All tests must pass. Zero skips allowed.

#### Step 12.E.2: Static analysis — zero warnings

```
pwsh -Command "flutter analyze"
```

Must report 0 issues (or only pre-existing issues unrelated to this refactor).

#### Step 12.E.3: Final violation count report

Run all grep patterns from 12.B and produce a summary table:

| Pattern | Expected | Actual |
|---------|----------|--------|
| `Color(0x` outside theme | 0 | ? |
| `Colors.` outside theme (non-transparent) | 0 | ? |
| `AppTheme.textPrimary\|textSecondary` outside theme | 0 | ? |
| `AppTheme.primaryCyan` outside theme | 0 | ? |
| `AppTheme.status*` outside theme | 0 | ? |
| `AppTheme.surface*` outside theme | 0 | ? |
| `ScaffoldMessenger.showSnackBar` outside helper | 0 | ? |

If any pattern has non-zero actual count, fix before merging.

#### Step 12.E.4: Commit with summary

Commit message should include the violation count table showing before/after across the entire refactor.
