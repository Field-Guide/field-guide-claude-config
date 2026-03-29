# UI Refactor v2 — Phases 2-5: Core Screen Rewrites

> **Depends on:** Phase 1 (design system components + FieldGuideColors ThemeExtension)
>
> **Color access pattern (established in Phase 1):**
> ```dart
> final cs = Theme.of(context).colorScheme;    // M3: primary, onSurface, error, outline, etc.
> final tt = Theme.of(context).textTheme;       // Typography: bodyLarge, titleMedium, etc.
> final fg = FieldGuideColors.of(context);      // Custom: surfaceElevated, surfaceGlass, textTertiary, etc.
> ```

---

## Phase 2: Dashboard Rewrite

**Goal:** Migrate `ProjectDashboardScreen` and its 4 dashboard widgets from static `AppTheme.*` tokens + hardcoded `Colors.*` to theme-aware `cs`/`tt`/`fg` tokens. Replace inline `TextStyle` with `textTheme` references.

### Sub-phase 2.A: DashboardStatCard

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_stat_card.dart`
- Test: Existing tests (visual regression only — no logic change)

**Agent:** `frontend-flutter-specialist-agent`

#### Step 2.A.1: Add theme variable declarations

Add at the top of `build()`:
```dart
// WHY: Theme-aware colors enable future dark mode support
final cs = Theme.of(context).colorScheme;
final tt = Theme.of(context).textTheme;
final fg = FieldGuideColors.of(context);
```

#### Step 2.A.2: Replace static color references

**Instances in `dashboard_stat_card.dart`:**
- Line ~44: `AppTheme.surfaceElevated` → `fg.surfaceElevated`
- Line ~45: `AppTheme.surfaceElevated.withValues(alpha: 0.7)` → `fg.surfaceElevated.withValues(alpha: 0.7)`
- Line ~49: `AppTheme.surfaceHighlight.withValues(alpha: 0.5)` → `cs.outline.withValues(alpha: 0.5)`
- Line ~54: `Colors.black.withValues(alpha: 0.15)` → `fg.shadowLight`
- Line ~61: `Colors.transparent` → `Colors.transparent` (keep — theme-independent)

#### Step 2.A.3: Replace inline TextStyle with textTheme

**Pattern:**
```dart
// Before:
TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5)
// After — NOTE: color is a parameter, must stay dynamic via copyWith:
tt.titleLarge!.copyWith(color: color, letterSpacing: -0.5)
```

**Instances:**
- Line ~81: `TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color, ...)` → `tt.titleLarge!.copyWith(color: color, letterSpacing: -0.5)`
- Line ~92: `TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600, ...)` → `tt.labelSmall!.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.3)`

---

### Sub-phase 2.B: BudgetOverviewCard

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/budget_overview_card.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 2.B.1: Add theme variable declarations

Same pattern as 2.A.1 — add `cs`/`tt`/`fg` at top of `build()` in both `BudgetOverviewCard` AND `_BudgetStatBox`.

#### Step 2.B.2: Replace static color references

**Instances in `budget_overview_card.dart`:**
- Line ~23: `EdgeInsets.all(24)` → `EdgeInsets.all(AppTheme.space6)` (NOTE: spacing stays static per rules, but 24 is a magic number — use the token)
- Line ~38: `AppTheme.primaryCyan.withValues(alpha: 0.2)` → `cs.primary.withValues(alpha: 0.2)`
- Line ~47: `AppTheme.surfaceElevated` → `fg.surfaceElevated`
- Line ~67: `AppTheme.textInverse.withValues(alpha: 0.2)` → `fg.textInverse.withValues(alpha: 0.2)`
- Line ~73: `AppTheme.textInverse` → `fg.textInverse`
- Line ~107: `AppTheme.textPrimary` → `cs.onSurface`
- Line ~119: `AppTheme.textTertiary` → `fg.textTertiary`
- Line ~140: `AppTheme.surfaceHighlight` → `cs.outline`
- Line ~143: `AppTheme.statusError` → `cs.error`
- Line ~145: `AppTheme.statusWarning` → `fg.statusWarning`
- Line ~146: `AppTheme.primaryCyan` → `cs.primary`
- Line ~178: `AppTheme.primaryCyan` → `cs.primary`
- Line ~184: `AppTheme.statusSuccess` → `fg.statusSuccess`

#### Step 2.B.3: Replace inline TextStyle with textTheme

**Instances:**
- Line ~79: `TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textInverse, letterSpacing: 1.0)` → `tt.labelLarge!.copyWith(color: fg.textInverse, letterSpacing: 1.0)`
- Line ~104: `TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, ...)` → `tt.displaySmall!.copyWith(color: cs.onSurface, letterSpacing: -1)`
- Line ~117: `TextStyle(fontSize: 11, color: AppTheme.textTertiary, ...)` → `tt.labelSmall!.copyWith(color: fg.textTertiary, letterSpacing: 1.5)`
- Line ~158: `TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ...)` → `tt.titleSmall!.copyWith(color: <dynamic>)`
- Line ~240 (_BudgetStatBox): `TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)` → `tt.titleLarge!.copyWith(color: color)`
- Line ~251 (_BudgetStatBox): `TextStyle(fontSize: 12, color: AppTheme.textSecondary, ...)` → `tt.labelMedium!.copyWith(color: cs.onSurfaceVariant)`

---

### Sub-phase 2.C: TrackedItemRow

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/tracked_item_row.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 2.C.1: Add theme variables + replace colors

**Instances:**
- Line ~24: `AppTheme.statusError` → `cs.error`
- Line ~26: `AppTheme.statusWarning` → `fg.statusWarning`
- Line ~27: `AppTheme.primaryCyan` → `cs.primary`
- Line ~36: `AppTheme.surfaceDark` → `cs.surface`
- Line ~37: `AppTheme.surfaceDark.withValues(alpha: 0.5)` → `cs.surface.withValues(alpha: 0.5)`
- Line ~42: `AppTheme.surfaceHighlight.withValues(alpha: 0.5)` → `cs.outline.withValues(alpha: 0.5)`
- Line ~112: `AppTheme.surfaceHighlight` → `cs.outline`
- Line ~138: `AppTheme.textTertiary` → `fg.textTertiary`

#### Step 2.C.2: Replace inline TextStyle

**Instances:**
- Line ~76: `TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: progressColor)` → `tt.titleMedium!.copyWith(fontWeight: FontWeight.w800, color: progressColor)`
- Line ~93: `TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)` → `tt.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)`
- Line ~122: `TextStyle(fontSize: 11, color: AppTheme.textSecondary, ...)` → `tt.labelSmall!.copyWith(color: cs.onSurfaceVariant)`

---

### Sub-phase 2.D: AlertItemRow

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/alert_item_row.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 2.D.1: Add theme variables + replace hardcoded EdgeInsets/BorderRadius

**Pattern for magic numbers:**
```dart
// Before:
margin: const EdgeInsets.only(bottom: 8),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
borderRadius: BorderRadius.circular(8),
// After:
margin: const EdgeInsets.only(bottom: AppTheme.space2),
padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3, vertical: AppTheme.space2 + 2),
borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
```

**Instances — EdgeInsets:**
- Line ~22: `EdgeInsets.only(bottom: 8)` → `EdgeInsets.only(bottom: AppTheme.space2)`
- Line ~23: `EdgeInsets.symmetric(horizontal: 12, vertical: 10)` → `EdgeInsets.symmetric(horizontal: AppTheme.space3, vertical: AppTheme.space2 + 2)`
- Line ~55: `EdgeInsets.symmetric(horizontal: 8, vertical: 4)` → `EdgeInsets.symmetric(horizontal: AppTheme.space2, vertical: AppTheme.space1)`

**Instances — BorderRadius:**
- Line ~24: `BorderRadius.circular(8)` → `BorderRadius.circular(AppTheme.radiusSmall)`
- Line ~58: `BorderRadius.circular(4)` → `BorderRadius.circular(AppTheme.radiusXSmall)`

**Instances — SizedBox:**
- Line ~42: `SizedBox(width: 10)` → `SizedBox(width: AppTheme.space2 + 2)`

#### Step 2.D.2: Replace static colors

**Instances:**
- Line ~26: `AppTheme.statusError.withValues(alpha: 0.1)` → `cs.error.withValues(alpha: 0.1)`
- Line ~27: `AppTheme.surfaceElevated.withValues(alpha: 0.5)` → `fg.surfaceElevated.withValues(alpha: 0.5)`
- Line ~30: `AppTheme.statusError.withValues(alpha: 0.3)` → `cs.error.withValues(alpha: 0.3)`
- Line ~31: `AppTheme.statusWarning.withValues(alpha: 0.3)` → `fg.statusWarning.withValues(alpha: 0.3)`
- Line ~39: `AppTheme.statusError` → `cs.error`
- Line ~39: `AppTheme.statusWarning` → `fg.statusWarning`
- Line ~49: `AppTheme.textPrimary` → `cs.onSurface`
- Line ~57: `AppTheme.statusError` / `AppTheme.statusWarning` → `cs.error` / `fg.statusWarning`
- Line ~65: `AppTheme.textInverse` → `fg.textInverse`

#### Step 2.D.3: Replace inline TextStyle

**Instances:**
- Line ~48: `TextStyle(fontSize: 13, color: AppTheme.textPrimary)` → `tt.bodyMedium!.copyWith(color: cs.onSurface)`
- Line ~62: `TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textInverse)` → `tt.labelMedium!.copyWith(fontWeight: FontWeight.bold, color: fg.textInverse)`

---

### Sub-phase 2.E: ProjectDashboardScreen

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/project_dashboard_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 2.E.1: Add theme variable declarations

Add at the top of `build()` and every `_build*` method that references theme:
```dart
final cs = Theme.of(context).colorScheme;
final tt = Theme.of(context).textTheme;
final fg = FieldGuideColors.of(context);
```

#### Step 2.E.2: Replace inline TextStyle

**Instances in `project_dashboard_screen.dart`:**
- Line ~102: `TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textInverse, ...)` → `tt.titleMedium!.copyWith(fontWeight: FontWeight.w800, color: fg.textInverse, letterSpacing: 0.2)`
- Line ~115: `TextStyle(fontSize: 12, color: AppTheme.textInverse.withValues(alpha: 0.9), ...)` → `tt.labelSmall!.copyWith(color: fg.textInverse.withValues(alpha: 0.9))`
- Line ~225: `TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)` → `tt.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)`
- Line ~233: `TextStyle(color: AppTheme.textSecondary)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~301: `TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)` → `tt.titleSmall!.copyWith(color: cs.onSurface)`
- Line ~309: `TextStyle(fontSize: 13, color: AppTheme.textSecondary)` → `tt.bodySmall!.copyWith(color: cs.onSurfaceVariant)`
- Line ~523: `TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textInverse, ...)` → `tt.labelLarge!.copyWith(color: fg.textInverse, letterSpacing: 1.0)`
- Line ~549: `TextStyle(fontSize: 12, color: AppTheme.textTertiary, ...)` → `tt.labelSmall!.copyWith(color: fg.textTertiary)`
- Line ~567: `TextStyle(color: AppTheme.textSecondary)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~667: `TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textInverse, ...)` → `tt.labelLarge!.copyWith(color: fg.textInverse, letterSpacing: 1.0)`
- Line ~688: `TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textInverse)` → `tt.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: fg.textInverse)`

#### Step 2.E.3: Replace hardcoded Colors.* (the 4 literal violations)

**Pattern:**
```dart
// Before (budget warning chip):
backgroundColor: Colors.amber.shade50,
side: BorderSide(color: Colors.amber.shade200),
color: Colors.orange.shade800
// After — use AppBudgetWarningChip (Phase 1 component):
AppBudgetWarningChip(
  message: 'Budget values adjusted — unit price discrepancy detected',
)
```

**Instances:**
- Line ~438: `Icon(... color: Colors.orange.shade800, ...)` → `Icon(... color: fg.warningBorder, ...)`
- Line ~443: `backgroundColor: Colors.amber.shade50` → `backgroundColor: fg.warningBackground`
- Line ~444: `side: BorderSide(color: Colors.amber.shade200)` → `side: BorderSide(color: fg.warningBorder)`
- OR better: replace the entire Chip (lines 437-445) with `AppBudgetWarningChip`

#### Step 2.E.4: Replace remaining static colors

**Instances:**
- Line ~104: `AppTheme.textInverse` → `fg.textInverse`
- Line ~138: `AppTheme.accentAmber.withValues(alpha: 0.3)` → `fg.accentAmber.withValues(alpha: 0.3)`
- Line ~159: `Colors.transparent` → `Colors.transparent` (keep)
- Line ~160: `AppTheme.textInverse` → `fg.textInverse`
- Line ~161: `Colors.transparent` → `Colors.transparent` (keep)
- Line ~173: `AppTheme.textInverse` → `fg.textInverse`
- Line ~221: `AppTheme.textTertiary` → `fg.textTertiary`
- Line ~262: `AppTheme.accentAmber.withValues(alpha: 0.5)` → `fg.accentAmber.withValues(alpha: 0.5)`
- Line ~265: `AppTheme.accentAmber.withValues(alpha: 0.08)` → `fg.accentAmber.withValues(alpha: 0.08)`
- Line ~284: `AppTheme.accentAmber.withValues(alpha: 0.15)` → `fg.accentAmber.withValues(alpha: 0.15)`
- Line ~290: `AppTheme.accentAmber` → `fg.accentAmber`
- Line ~319: `AppTheme.textTertiary` → `fg.textTertiary`
- Line ~344: `AppTheme.primaryCyan` → `cs.primary`
- Line ~356: `AppTheme.accentAmber` → `fg.accentAmber`
- Line ~481: `AppTheme.surfaceElevated` → `fg.surfaceElevated`
- Line ~484: `AppTheme.surfaceHighlight.withValues(alpha: 0.5)` → `cs.outline.withValues(alpha: 0.5)`
- Line ~489: `Colors.black.withValues(alpha: 0.1)` → `fg.shadowLight`
- Line ~517: `AppTheme.textInverse` → `fg.textInverse`
- Line ~535: `AppTheme.textInverse` → `fg.textInverse`
- Line ~564: `AppTheme.textTertiary` → `fg.textTertiary`
- Line ~700: `AppTheme.statusWarning.withValues(alpha: 0.05)` → `fg.statusWarning.withValues(alpha: 0.05)`

#### Step 2.E.5: Replace hardcoded padding magic numbers

**Instances:**
- Line ~217: `EdgeInsets.all(32)` → `EdgeInsets.all(AppTheme.space8)`
- Line ~228: `SizedBox(height: 24)` → `SizedBox(height: AppTheme.space6)`
- Line ~236: `SizedBox(height: 12)` → `SizedBox(height: AppTheme.space3)`
- Line ~237: `SizedBox(height: 24)` → `SizedBox(height: AppTheme.space6)`
- Line ~435: `EdgeInsets.symmetric(horizontal: 16, vertical: 4)` → `EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space1)`

### Sub-phase 2.F: Quality Gate

**Agent:** `qa-testing-agent`

```powershell
pwsh -Command "flutter analyze lib/features/dashboard/"
pwsh -Command "flutter test test/features/dashboard/"
```

Verify: no `AppTheme.textPrimary`, `AppTheme.textSecondary`, `AppTheme.textTertiary`, `AppTheme.textInverse`, `AppTheme.surfaceElevated`, `AppTheme.surfaceHighlight`, `AppTheme.surfaceDark`, `AppTheme.primaryCyan`, `AppTheme.statusError`, `AppTheme.statusSuccess`, `AppTheme.statusWarning`, `Colors.black.withValues`, `Colors.amber`, `Colors.orange` remain in dashboard files.

---

## Phase 3: Entry Editor Rewrite

**Goal:** Migrate `EntryEditorScreen` (~1500 lines) and its section widgets from static tokens to theme-aware. This is the most complex screen — approach with patterns, not line-by-line.

### Sub-phase 3.A: EntryEditorScreen Core

**Files:**
- Modify: `lib/features/entries/presentation/screens/entry_editor_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 3.A.1: Add theme variable declarations

Add at the top of `_buildAppBar()`, `_buildEntryHeader()`, and `build()`:
```dart
final cs = Theme.of(context).colorScheme;
final tt = Theme.of(context).textTheme;
final fg = FieldGuideColors.of(context);
```
NOTE: Do NOT add to methods called from `dispose()` or `initState()` — context may be invalid.

#### Step 3.A.2: Replace inline TextStyle pattern

**Pattern applied across the file:**
```dart
// Before:
style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)
// After:
style: tt.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)
```

**Key instances (entry_editor_screen.dart):**
- `_buildAppBar` — title styles already use `Theme.of(context).textTheme` (good)
- `_buildEntryHeader` line ~916: Uses `Theme.of(context).textTheme.titleLarge` (good — already migrated)
- Line ~955: `TextStyle(fontWeight: FontWeight.w600, color: ...)` → `tt.titleSmall!.copyWith(color: ...)`
- Line ~880: `TextStyle(color: AppTheme.statusError)` → `tt.bodyMedium!.copyWith(color: cs.error)`

#### Step 3.A.3: Replace static color references

**Pattern:**
```dart
// Before:
color: AppTheme.primaryCyan
// After:
color: cs.primary
```

**Instances (scan for `AppTheme.` in entry_editor_screen.dart):**
- `AppTheme.statusError` → `cs.error` (SnackBar backgrounds, delete menu icon)
- `AppTheme.statusWarning` → `fg.statusWarning` (permission snackbar, weather prompt color)
- `AppTheme.primaryCyan` → `cs.primary` (location icon, edit icons)
- `AppTheme.textSecondary` → `cs.onSurfaceVariant` (expand_more icon, subtitle text)
- `AppTheme.textInverse` → `fg.textInverse` (submit button foreground)
- `AppTheme.surfaceElevated` → `fg.surfaceElevated` (card backgrounds)

#### Step 3.A.4: Replace hardcoded EdgeInsets

**Instances:**
- Line ~902: `EdgeInsets.all(16)` → `EdgeInsets.all(AppTheme.space4)`
- Line ~930: `SizedBox(height: 8)` → `SizedBox(height: AppTheme.space2)`

---

### Sub-phase 3.B: Entry Section Widgets

**Files:**
- Modify: `lib/features/entries/presentation/widgets/entry_basics_section.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_activities_section.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_photos_section.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_contractors_section.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_quantities_section.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_forms_section.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_status_section.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_action_bar.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 3.B.1: Apply theme migration pattern to all section widgets

For each widget file, apply the same 3-step pattern:
1. Add `cs`/`tt`/`fg` at top of `build()`
2. Replace all `AppTheme.textPrimary` → `cs.onSurface`, `AppTheme.textSecondary` → `cs.onSurfaceVariant`, etc.
3. Replace inline `TextStyle(fontSize: N, ...)` with nearest `textTheme` match

**textTheme mapping guide:**
| Inline fontSize | textTheme token |
|----------------|-----------------|
| 10-11 | `tt.labelSmall` |
| 12 | `tt.labelMedium` or `tt.bodySmall` |
| 13-14 | `tt.bodyMedium` |
| 15-16 | `tt.titleSmall` or `tt.bodyLarge` |
| 18 | `tt.titleMedium` |
| 20 | `tt.titleLarge` |
| 24 | `tt.headlineSmall` |
| 28+ | `tt.headlineMedium` |

---

### Sub-phase 3.C: ContractorEditorWidget (50 violations)

**Files:**
- Modify: `lib/features/entries/presentation/widgets/contractor_editor_widget.dart`
- Modify: `lib/features/entries/presentation/widgets/contractor_summary_widget.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 3.C.1: Bulk replace static color tokens

NOTE: This widget has ~50 violations. Use `replace_all` for mechanical find/replace:

```dart
// Bulk replacements (order matters — more specific first):
AppTheme.textPrimary    → cs.onSurface
AppTheme.textSecondary  → cs.onSurfaceVariant
AppTheme.textTertiary   → fg.textTertiary
AppTheme.textInverse    → fg.textInverse
AppTheme.primaryCyan    → cs.primary
AppTheme.surfaceElevated → fg.surfaceElevated
AppTheme.surfaceHighlight → cs.outline
AppTheme.statusError    → cs.error
AppTheme.statusWarning  → fg.statusWarning
AppTheme.statusSuccess  → fg.statusSuccess
```

WARNING: Must add `final cs = Theme.of(context).colorScheme;` etc. FIRST — otherwise these replacements break compilation.

#### Step 3.C.2: Replace inline TextStyle instances

Apply the textTheme mapping guide from 3.B.1 to all `TextStyle(fontSize: N, ...)` instances.

---

### Sub-phase 3.D: Shared Entry Widgets

**Files:**
- Modify: `lib/features/entries/presentation/widgets/status_badge.dart`
- Modify: `lib/features/entries/presentation/widgets/submitted_banner.dart`
- Modify: `lib/features/entries/presentation/widgets/draft_entry_tile.dart`
- Modify: `lib/features/entries/presentation/widgets/review_field_row.dart`
- Modify: `lib/features/entries/presentation/widgets/review_missing_warning.dart`
- Modify: `lib/features/entries/presentation/widgets/simple_info_row.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 3.D.1: Apply standard migration pattern

Same 3-step pattern as 3.B.1. These widgets are smaller (10-50 lines each), so the migration is mechanical.

---

### Sub-phase 3.E: Report Widgets (9 dialog files)

**Files:**
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_add_contractor_sheet.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_add_personnel_type_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_add_quantity_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_debug_pdf_actions_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_delete_personnel_type_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_location_edit_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_weather_edit_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_photo_detail_dialog.dart`
- Modify: `lib/features/entries/presentation/screens/report_widgets/report_pdf_actions_dialog.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 3.E.1: Apply standard migration pattern to all 9 dialog files

NOTE for dialogs: `Theme.of(context)` inside `showDialog` builder uses the dialog's context, which inherits the app theme. This is correct — no special handling needed.

---

### Sub-phase 3.F: Quality Gate

**Agent:** `qa-testing-agent`

```powershell
pwsh -Command "flutter analyze lib/features/entries/"
pwsh -Command "flutter test test/features/entries/"
```

Verify: no static `AppTheme.text*`, `AppTheme.surface*`, `AppTheme.primaryCyan`, `AppTheme.status*` remain in entry feature files. `AppTheme.space*`, `AppTheme.radius*`, `AppTheme.animation*`, `AppTheme.curve*`, `AppTheme.iconSize*` are OK (theme-independent).

---

## Phase 3.5: Safety Repeat-Last Toggles (NEW FEATURE)

**Goal:** Add "repeat last" toggles to daily entries. When creating a new entry, if enabled, seed location, weather, and contractors from the most recent entry for that project.

> **SECURITY NOTE:** This feature only copies from entries created by the same user (enforced at query level). No cross-user data leakage.

### Sub-phase 3.5.A: Database Migration (v43)

**Files:**
- Modify: `lib/core/database/database_service.dart`

**Agent:** `backend-data-layer-agent`

#### Step 3.5.A.1: Bump database version

```dart
// Before:
version: 42,
// After:
version: 43,
```

NOTE: Both `_initDatabase()` and `_initInMemoryDatabase()` must be updated.

#### Step 3.5.A.2: Add migration block

Add after the `if (oldVersion < 42)` block in `_onUpgrade`:

```dart
// WHY: Phase 3.5 — Repeat-Last Toggles. Per-entry opt-in for seeding location,
// weather, and contractors from the previous entry in the same project.
// Defaults to 0 (off) so existing entries are unaffected.
if (oldVersion < 43) {
  await db.execute('ALTER TABLE daily_entries ADD COLUMN repeat_last_location INTEGER DEFAULT 0');
  await db.execute('ALTER TABLE daily_entries ADD COLUMN repeat_last_weather INTEGER DEFAULT 0');
  await db.execute('ALTER TABLE daily_entries ADD COLUMN repeat_last_contractors INTEGER DEFAULT 0');
}
```

#### Step 3.5.A.3: Update table creation SQL

In the `daily_entries` CREATE TABLE statement (used for fresh installs), add:
```sql
repeat_last_location INTEGER DEFAULT 0,
repeat_last_weather INTEGER DEFAULT 0,
repeat_last_contractors INTEGER DEFAULT 0
```

---

### Sub-phase 3.5.B: Model Changes

**Files:**
- Modify: `lib/features/entries/data/models/daily_entry.dart`

**Agent:** `backend-data-layer-agent`

#### Step 3.5.B.1: Add fields to DailyEntry

```dart
// Add to class fields:
final bool repeatLastLocation;
final bool repeatLastWeather;
final bool repeatLastContractors;

// Add to constructor parameters (with defaults):
this.repeatLastLocation = false,
this.repeatLastWeather = false,
this.repeatLastContractors = false,
```

#### Step 3.5.B.2: Update copyWith

```dart
// Add parameters:
bool? repeatLastLocation,
bool? repeatLastWeather,
bool? repeatLastContractors,

// Add to return body:
repeatLastLocation: repeatLastLocation ?? this.repeatLastLocation,
repeatLastWeather: repeatLastWeather ?? this.repeatLastWeather,
repeatLastContractors: repeatLastContractors ?? this.repeatLastContractors,
```

#### Step 3.5.B.3: Update toMap

```dart
'repeat_last_location': repeatLastLocation ? 1 : 0,
'repeat_last_weather': repeatLastWeather ? 1 : 0,
'repeat_last_contractors': repeatLastContractors ? 1 : 0,
```

#### Step 3.5.B.4: Update fromMap

```dart
repeatLastLocation: (map['repeat_last_location'] as int? ?? 0) == 1,
repeatLastWeather: (map['repeat_last_weather'] as int? ?? 0) == 1,
repeatLastContractors: (map['repeat_last_contractors'] as int? ?? 0) == 1,
```

---

### Sub-phase 3.5.C: Repository — getMostRecentEntry

**Files:**
- Modify: `lib/features/entries/data/repositories/daily_entry_repository.dart`

**Agent:** `backend-data-layer-agent`

#### Step 3.5.C.1: Add getMostRecentEntry method

```dart
/// Returns the most recent entry for [projectId] created by [userId],
/// excluding the entry with [excludeId] (the one being created).
/// WHY: Used by repeat-last-toggles to seed new entries from prior data.
/// SECURITY: Scoped to same user — no cross-user data leakage.
Future<DailyEntry?> getMostRecentEntry(
  String projectId, {
  required String userId,
  String? excludeId,
}) async {
  final db = await _dbService.database;
  final results = await db.query(
    'daily_entries',
    where: 'project_id = ? AND created_by_user_id = ? AND deleted_at IS NULL'
        '${excludeId != null ? ' AND id != ?' : ''}',
    whereArgs: [projectId, userId, if (excludeId != null) excludeId],
    orderBy: 'date DESC',
    limit: 1,
  );
  if (results.isEmpty) return null;
  return DailyEntry.fromMap(results.first);
}
```

---

### Sub-phase 3.5.D: Provider — seedFromPrevious

**Files:**
- Modify: `lib/features/entries/presentation/providers/daily_entry_provider.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 3.5.D.1: Add seedFromPrevious method

```dart
/// Seeds a newly created entry with fields from the most recent entry,
/// based on the repeat-last toggles of the previous entry.
/// Returns the updated entry if seeding occurred, null otherwise.
/// WHY: Saves inspectors from re-entering location/weather/contractors each day.
Future<DailyEntry?> seedFromPrevious(DailyEntry newEntry) async {
  final previous = await repository.getMostRecentEntry(
    newEntry.projectId,
    userId: newEntry.createdByUserId!,
    excludeId: newEntry.id,
  );
  if (previous == null) return null;

  DailyEntry seeded = newEntry;
  bool changed = false;

  if (previous.repeatLastLocation && previous.locationId != null) {
    seeded = seeded.copyWith(locationId: previous.locationId);
    changed = true;
  }
  if (previous.repeatLastWeather && previous.weather != null) {
    // NOTE: Only seed weather type — temperature should be fresh each day
    seeded = seeded.copyWith(weather: previous.weather);
    changed = true;
  }
  // NOTE: repeatLastContractors is handled by the ContractorEditingController
  // after the entry is created — it copies personnel assignments from previous entry.
  // The flag is read by the UI, not by this provider.

  if (changed) {
    await repository.update(seeded);
    return seeded;
  }
  return null;
}
```

---

### Sub-phase 3.5.E: UI — Toggle Switches in Entry Basics

**Files:**
- Modify: `lib/features/entries/presentation/screens/entry_editor_screen.dart`
- Modify: `lib/features/entries/presentation/widgets/entry_basics_section.dart` (if toggles belong in basics)

**Agent:** `frontend-flutter-specialist-agent`

#### Step 3.5.E.1: Add repeat-last toggles to entry basics section

In `_buildEntryHeader` (or `EntryBasicsSection`), add after the weather row inside the collapsible area:

```dart
// WHY: Repeat-last toggles let inspectors carry forward location/weather/contractors
// to the next day's entry. Displayed in basics section because they affect entry creation.
if (_isDraftEntry && _entry != null) ...[
  const Divider(height: AppTheme.space6),
  Text('Repeat on next entry', style: tt.titleSmall!.copyWith(color: cs.onSurface)),
  const SizedBox(height: AppTheme.space2),
  AppToggle(
    label: 'Location',
    value: _entry!.repeatLastLocation,
    onChanged: (v) => _updateRepeatToggle(repeatLastLocation: v),
  ),
  AppToggle(
    label: 'Weather type',
    value: _entry!.repeatLastWeather,
    onChanged: (v) => _updateRepeatToggle(repeatLastWeather: v),
  ),
  AppToggle(
    label: 'Contractors',
    value: _entry!.repeatLastContractors,
    onChanged: (v) => _updateRepeatToggle(repeatLastContractors: v),
  ),
],
```

#### Step 3.5.E.2: Add _updateRepeatToggle helper

```dart
Future<void> _updateRepeatToggle({
  bool? repeatLastLocation,
  bool? repeatLastWeather,
  bool? repeatLastContractors,
}) async {
  final entry = _entry;
  if (entry == null) return;

  final updated = entry.copyWith(
    repeatLastLocation: repeatLastLocation,
    repeatLastWeather: repeatLastWeather,
    repeatLastContractors: repeatLastContractors,
  );
  await context.read<DailyEntryProvider>().updateEntry(updated);
  if (mounted) setState(() => _entry = updated);
}
```

#### Step 3.5.E.3: Wire seeding into entry creation flow

In `_loadEntryData`, after the draft is persisted (line ~266), add:

```dart
// WHY: Seed from previous entry based on repeat-last toggles
if (_isDraftEntry && created != null) {
  final seeded = await entryProvider.seedFromPrevious(created);
  if (seeded != null) entry = seeded;
}
```

---

### Sub-phase 3.5.F: Contractor Repeat-Last

**Files:**
- Modify: `lib/features/entries/presentation/controllers/contractor_editing_controller.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 3.5.F.1: Add copyContractorsFromEntry method

```dart
/// Copies contractor assignments (entry_contractors rows) from [sourceEntryId]
/// to [targetEntryId]. Used by repeat-last-contractors toggle.
/// WHY: Avoids re-selecting the same contractors every day.
Future<void> copyContractorsFromEntry(String sourceEntryId, String targetEntryId) async {
  final sourceContractors = await _contractorsDatasource.getByEntryId(sourceEntryId);
  for (final ec in sourceContractors) {
    await _contractorsDatasource.upsert(
      EntryContractor(
        entryId: targetEntryId,
        contractorId: ec.contractorId,
      ),
    );
  }
}
```

#### Step 3.5.F.2: Wire into entry creation

In `entry_editor_screen.dart`, after seeding (Step 3.5.E.3), add:

```dart
// WHY: Seed contractors from previous entry if repeat-last-contractors enabled
if (previous != null && previous.repeatLastContractors) {
  await _contractorController?.copyContractorsFromEntry(previous.id, entry!.id);
}
```

NOTE: `previous` needs to be available here — adjust the seeding flow to return the previous entry reference.

---

### Sub-phase 3.5.G: Tests

**Files:**
- Create: `test/features/entries/data/repeat_last_toggles_test.dart`

**Agent:** `qa-testing-agent`

#### Step 3.5.G.1: Test cases

1. **Default off**: New entry has all repeat toggles = false
2. **Seed location**: Previous entry with repeat_last_location=true seeds locationId
3. **Seed weather**: Previous entry with repeat_last_weather=true seeds weather type (not temp)
4. **No cross-user**: Previous entry by user A does not seed user B's entry
5. **Toggle persistence**: Toggling repeat flags persists to database
6. **Model serialization**: toMap/fromMap round-trip preserves boolean toggles

---

### Sub-phase 3.5.H: Quality Gate

**Agent:** `qa-testing-agent`

```powershell
pwsh -Command "flutter analyze"
pwsh -Command "flutter test test/features/entries/"
```

---

## Phase 4: Calendar/Home Screen Rewrite

**Goal:** Migrate `HomeScreen` (~1800 lines) — the TOP VIOLATOR with 38 TextStyle, 31 EdgeInsets, 9 BorderRadius violations. Also migrate the inline `_AnimatedDayCell` and `_ModernEntryCard` private widgets.

### Sub-phase 4.A: HomeScreen — Top-level build + state methods

**Files:**
- Modify: `lib/features/entries/presentation/screens/home_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 4.A.1: Add theme variable declarations

Add at the top of `build()` and every `_build*` helper method:
```dart
final cs = Theme.of(context).colorScheme;
final tt = Theme.of(context).textTheme;
final fg = FieldGuideColors.of(context);
```

NOTE: Do NOT add to `_handleReportScroll`, `_setupFocusListeners`, `_saveIfEditing`, `_saveIfEditingContractor`, `dispose()` — these don't render widgets.

#### Step 4.A.2: Replace inline TextStyle — empty/select states

**Instances in `_buildNoProjectsState` (~line 443-476):**
- Line ~454: `TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)` → `tt.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)`
- Line ~463: `TextStyle(color: AppTheme.textSecondary)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`

**Instances in `_buildSelectProjectState` (~line 479-512):**
- Line ~489: `TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)` → `tt.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)`
- Line ~498: `TextStyle(color: AppTheme.textSecondary)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`

**Instances in `_buildEmptyState` (~line 927-961):**
- Line ~943: `TextStyle(color: AppTheme.textSecondary, fontSize: 14)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`

#### Step 4.A.3: Replace static colors — empty/select states

**Instances:**
- Line ~450: `AppTheme.textTertiary` → `fg.textTertiary`
- Line ~486: `AppTheme.textTertiary` → `fg.textTertiary`
- Line ~938: `AppTheme.textTertiary` → `fg.textTertiary`

---

### Sub-phase 4.B: HomeScreen — Project header + calendar

**Agent:** `frontend-flutter-specialist-agent`

#### Step 4.B.1: Replace _buildProjectHeader colors + styles

**Instances (~line 515-559):**
- Line ~517: `AppTheme.primaryCyan.withValues(alpha: 0.1)` → `cs.primary.withValues(alpha: 0.1)`
- Line ~524: `AppTheme.primaryCyan` → `cs.primary`
- Line ~532: `TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)` → `tt.titleSmall!.copyWith(color: cs.onSurface)`
- Line ~542: `TextStyle(fontSize: 12, color: AppTheme.textSecondary)` → `tt.bodySmall!.copyWith(color: cs.onSurfaceVariant)`

#### Step 4.B.2: Replace _buildCalendarFormatToggle colors + styles

**Instances (~line 584-661):**
- Line ~590: `AppTheme.surfaceDark` → `cs.surface`
- Line ~641: `AppTheme.primaryCyan` → `cs.primary`
- Line ~642: `AppTheme.surfaceElevated` → `fg.surfaceElevated`
- Line ~645: `AppTheme.primaryCyan` → `cs.primary`
- Line ~646: `AppTheme.surfaceHighlight` → `cs.outline`
- Line ~653: `TextStyle(fontSize: 13, fontWeight: FontWeight.w600, ...)` → `tt.labelLarge!.copyWith(color: isSelected ? fg.textInverse : cs.onSurface)`
- Line ~656: `AppTheme.textInverse` → `fg.textInverse`
- Line ~656: `AppTheme.textPrimary` → `cs.onSurface`

#### Step 4.B.3: Replace _buildCalendar headerStyle + calendarStyle

**Instances (~line 663-811):**
- Line ~802: `TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)` → `tt.titleSmall!.copyWith(color: cs.onSurface)`

---

### Sub-phase 4.C: HomeScreen — Selected day content + report preview

**Agent:** `frontend-flutter-specialist-agent`

#### Step 4.C.1: Replace _buildSelectedDayContent styles

**Instances (~line 822-924):**
- Line ~888: `TextStyle(color: AppTheme.textSecondary, fontSize: 12)` → `tt.bodySmall!.copyWith(color: cs.onSurfaceVariant)`

#### Step 4.C.2: Replace _buildReportContent styles (largest block)

**Instances (~line 1010-1281):**
- Line ~1031: `AppTheme.primaryCyan` → `cs.primary`
- Line ~1040: `TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryCyan)` → `tt.titleSmall!.copyWith(fontWeight: FontWeight.bold, color: cs.primary)`
- Line ~1049: `TextStyle(fontSize: 12, color: AppTheme.textSecondary)` → `tt.bodySmall!.copyWith(color: cs.onSurfaceVariant)`
- Line ~1076: `TextStyle(fontSize: 14, color: AppTheme.textPrimary)` → `tt.bodyMedium!.copyWith(color: cs.onSurface)`
- Line ~1086: `TextStyle(fontSize: 14, color: AppTheme.textSecondary)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~1092: `TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)`
- Line ~1113: `TextStyle(fontSize: 13)` → `tt.bodyMedium`
- Line ~1133: `TextStyle(fontSize: 13)` → `tt.bodyMedium`
- Line ~1150: `TextStyle(fontSize: 14, height: 1.4, ...)` → `tt.bodyMedium!.copyWith(height: 1.4, color: ...)`
- Line ~1169: `TextStyle(fontSize: 14, height: 1.4)` → `tt.bodyMedium!.copyWith(height: 1.4)`
- Line ~1203: `TextStyle(fontSize: 13)` → `tt.bodyMedium`
- Line ~1247: `TextStyle(fontSize: 14, height: 1.4, ...)` → `tt.bodyMedium!.copyWith(height: 1.4, color: ...)`
- Line ~1270: `TextStyle(fontSize: 14)` → `tt.bodyMedium`

#### Step 4.C.3: Replace _buildEditablePreviewSection styles + colors

**Instances (~line 1283-1346):**
- Line ~1306: `AppTheme.primaryCyan` → `cs.primary`
- Line ~1306: `AppTheme.surfaceHighlight.withValues(alpha: 0.3)` → `cs.outline.withValues(alpha: 0.3)`
- Line ~1310: `AppTheme.primaryCyan.withValues(alpha: 0.05)` → `cs.primary.withValues(alpha: 0.05)`
- Line ~1310: `AppTheme.surfaceElevated` → `fg.surfaceElevated`
- Line ~1317: `AppTheme.primaryCyan` → `cs.primary`
- Line ~1322: `TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)` → `tt.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)`
- Line ~1334: `AppTheme.textTertiary` → `fg.textTertiary`

---

### Sub-phase 4.D: HomeScreen — Contractors section + dialogs

**Agent:** `frontend-flutter-specialist-agent`

#### Step 4.D.1: Replace _buildContractorsSection styles + colors

**Instances (~line 1348-1511):**
- Line ~1397: `AppTheme.surfaceHighlight.withValues(alpha: 0.3)` → `cs.outline.withValues(alpha: 0.3)`
- Line ~1400: `AppTheme.surfaceElevated` → `fg.surfaceElevated`
- Line ~1407: `AppTheme.primaryCyan` → `cs.primary`
- Line ~1412: `TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)` → `tt.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)`
- Line ~1421: `TextStyle(fontSize: 11, color: AppTheme.textSecondary)` → `tt.labelSmall!.copyWith(color: cs.onSurfaceVariant)`
- Line ~1438: `AppTheme.surfaceHighlight` → `cs.outline`
- Line ~1444: `AppTheme.textTertiary` → `fg.textTertiary`
- Line ~1448: `TextStyle(fontSize: 13, color: AppTheme.textTertiary, fontStyle: FontStyle.italic)` → `tt.bodyMedium!.copyWith(color: fg.textTertiary, fontStyle: FontStyle.italic)`
- Line ~1496: `AppTheme.primaryCyan` → `cs.primary`
- Line ~1500: `TextStyle(fontSize: 13, color: AppTheme.primaryCyan, ...)` → `tt.bodyMedium!.copyWith(color: cs.primary, fontWeight: FontWeight.w500)`

#### Step 4.D.2: Replace _showAddContractorDialog + _showDeleteEntryDialog styles

**Instances (~line 1598-1807):**
- Line ~1637: `TextStyle(fontWeight: FontWeight.bold, fontSize: 16)` → `tt.titleMedium` (no color override needed — uses default)
- Line ~1714: `AppTheme.statusError` → `cs.error`
- Line ~1741: `TextStyle(color: AppTheme.textSecondary, fontSize: 13)` → `tt.bodySmall!.copyWith(color: cs.onSurfaceVariant)`
- Line ~1759: `TextStyle(color: AppTheme.statusError, fontSize: 12)` → `tt.bodySmall!.copyWith(color: cs.error)`
- Line ~1776: `AppTheme.statusError` → `cs.error`
- Line ~1777: `AppTheme.textInverse` → `fg.textInverse`

---

### Sub-phase 4.E: _AnimatedDayCell + _ModernEntryCard (private widgets)

**Agent:** `frontend-flutter-specialist-agent`

#### Step 4.E.1: Replace _AnimatedDayCell styles + colors

NOTE: These private widgets have `context` available in `build()`.

**Instances (~line 1814-1917):**
- Line ~1893: `AppTheme.primaryCyan` → `cs.primary`
- Line ~1895: `AppTheme.primaryCyan.withValues(alpha: 0.08)` → `cs.primary.withValues(alpha: 0.08)`
- Line ~1898: `AppTheme.primaryCyan.withValues(alpha: 0.5)` → `cs.primary.withValues(alpha: 0.5)`
- Line ~1905: `TextStyle(fontSize: 14, fontWeight: ..., color: ...)` → `tt.bodyMedium!.copyWith(fontWeight: ..., color: ...)`
- Line ~1909: `AppTheme.textInverse` → `fg.textInverse`
- Line ~1910: `AppTheme.textPrimary` → `cs.onSurface`

#### Step 4.E.2: Replace _ModernEntryCard styles + colors

**Instances (~line 1920-end):**
- Line ~1966: `AppTheme.primaryCyan.withValues(alpha: 0.12)` → `cs.primary.withValues(alpha: 0.12)`
- Line ~1967: `AppTheme.surfaceElevated` → `fg.surfaceElevated`
- Line ~1970: `AppTheme.primaryCyan` → `cs.primary`
- Line ~1970: `AppTheme.surfaceHighlight.withValues(alpha: 0.3)` → `cs.outline.withValues(alpha: 0.3)`
- Line ~1988: `AppTheme.primaryCyan` → `cs.primary`
- Line ~1993: `TextStyle(fontWeight: FontWeight.bold, fontSize: 12, ...)` → `tt.labelMedium!.copyWith(fontWeight: FontWeight.bold, color: ...)`
- Line ~1995: `AppTheme.primaryCyan` → `cs.primary`
- Line ~1995: `AppTheme.textPrimary` → `cs.onSurface`
- All remaining `AppTheme.statusInfo` → `fg.statusInfo` (entry status colors stay custom per rules — these are domain colors, BUT verify if FieldGuideColors has statusInfo. If not, keep as `AppTheme.statusInfo`.)
- Line ~2003 and below: Continue pattern for status text, timestamp, attribution text

---

### Sub-phase 4.F: Quality Gate

**Agent:** `qa-testing-agent`

```powershell
pwsh -Command "flutter analyze lib/features/entries/presentation/screens/home_screen.dart"
pwsh -Command "flutter test test/features/entries/"
```

Verify: Grep for remaining violations:
```powershell
pwsh -Command "Select-String -Path 'lib/features/entries/presentation/screens/home_screen.dart' -Pattern 'AppTheme\.(textPrimary|textSecondary|textTertiary|textInverse|surfaceElevated|surfaceHighlight|surfaceDark|primaryCyan|statusError|statusWarning|statusSuccess)' | Measure-Object"
```
Target: 0 matches.

---

## Phase 5: List Screens Batch

**Goal:** Migrate 8 list/settings screens in a single phase. These are smaller screens with lower violation counts.

### Sub-phase 5.A: ProjectListScreen

**Files:**
- Modify: `lib/features/projects/presentation/screens/project_list_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 5.A.1: Add theme variables + replace Colors.* violations

The file has 6 `Colors.*` violations. Add `cs`/`tt`/`fg` to `build()` and key helper methods.

**Pattern:**
```dart
// Before:
Colors.grey → cs.onSurfaceVariant  (for text/icons)
Colors.grey → cs.outline           (for borders/dividers)
```

**Instances to fix (scan for `Colors.grey`, `Colors.black`, etc.):**
- Replace all `Colors.grey` with `cs.onSurfaceVariant` (icon/text) or `cs.outline` (border)
- Replace any `AppTheme.text*` / `AppTheme.surface*` / `AppTheme.primary*` per the standard mapping table

---

### Sub-phase 5.B: EntriesListScreen

**Files:**
- Modify: `lib/features/entries/presentation/screens/entries_list_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 5.B.1: Replace inline TextStyle (16 violations)

**Instances:**
- Line ~146: `TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)` → `tt.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)`
- Line ~155: `TextStyle(color: AppTheme.textSecondary)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~204: `TextStyle(fontSize: 13, color: AppTheme.textSecondary)` → `tt.bodySmall!.copyWith(color: cs.onSurfaceVariant)`
- Line ~250: `TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)` → `tt.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)`
- Line ~258: `TextStyle(color: AppTheme.textSecondary)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~300: `TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)` → `tt.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)`
- Line ~308: `TextStyle(color: AppTheme.textSecondary)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~364: `TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan, ...)` → `tt.titleSmall!.copyWith(fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 0.5)`
- Line ~423: `TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)` → `tt.titleSmall!.copyWith(color: cs.onSurface)`
- Line ~438: `TextStyle(fontSize: 14, color: AppTheme.textSecondary)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~457: `TextStyle(fontSize: 12, color: AppTheme.textTertiary)` → `tt.bodySmall!.copyWith(color: fg.textTertiary)` (multiple instances)
- Line ~472: same pattern

#### Step 5.B.2: Replace EdgeInsets violations (10 violations)

**Instances:**
- Line ~138: `EdgeInsets.all(32)` → `EdgeInsets.all(AppTheme.space8)`
- Line ~143: `SizedBox(height: 16)` → `SizedBox(height: AppTheme.space4)`
- Line ~158: `SizedBox(height: 24)` → `SizedBox(height: AppTheme.space6)`
- Line ~196: `EdgeInsets.all(12)` → `EdgeInsets.all(AppTheme.space3)`
- Line ~201: `SizedBox(width: 8)` → `SizedBox(width: AppTheme.space2)`
- Line ~216: `EdgeInsets.all(16)` → `EdgeInsets.all(AppTheme.space4)`
- Line ~242: `EdgeInsets.all(32)` → `EdgeInsets.all(AppTheme.space8)`
- Line ~247: `SizedBox(height: 24)` → `SizedBox(height: AppTheme.space6)`
- Line ~256: `SizedBox(height: 12)` → `SizedBox(height: AppTheme.space3)`
- Line ~361: `EdgeInsets.only(left: 4, top: 8, bottom: 8)` → `EdgeInsets.only(left: AppTheme.space1, top: AppTheme.space2, bottom: AppTheme.space2)`
- Line ~373: `SizedBox(height: 8)` → `SizedBox(height: AppTheme.space2)`
- Line ~388: `EdgeInsets.only(bottom: 8)` → `EdgeInsets.only(bottom: AppTheme.space2)`
- Line ~393: `BorderRadius.circular(12)` → `BorderRadius.circular(AppTheme.radiusMedium)`
- Line ~395: `EdgeInsets.all(16)` → `EdgeInsets.all(AppTheme.space4)`
- Line ~401: `EdgeInsets.all(12)` → `EdgeInsets.all(AppTheme.space3)`
- Line ~403: `BorderRadius.circular(12)` → `BorderRadius.circular(AppTheme.radiusMedium)`
- Line ~410: `SizedBox(width: 16)` → `SizedBox(width: AppTheme.space4)`

#### Step 5.B.3: Replace static color references

**Instances:**
- All `AppTheme.statusError` → `cs.error`
- All `AppTheme.primaryCyan` → `cs.primary`
- All `AppTheme.textPrimary` → `cs.onSurface`
- All `AppTheme.textSecondary` → `cs.onSurfaceVariant`
- All `AppTheme.textTertiary` → `fg.textTertiary`
- All `AppTheme.surfaceElevated` → `fg.surfaceElevated`

---

### Sub-phase 5.C: DraftsListScreen

**Files:**
- Modify: `lib/features/entries/presentation/screens/drafts_list_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 5.C.1: Apply standard migration

Scan for `AppTheme.*` static tokens, hardcoded `EdgeInsets`, `Colors.black`. Apply the standard mapping. This is a small screen (~200 lines) — violations are mostly in padding and the one `Colors.black` reference.

---

### Sub-phase 5.D: FormsListScreen

**Files:**
- Modify: `lib/features/forms/presentation/screens/forms_list_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 5.D.1: Apply standard migration

Mostly uses `AppTheme.*` tokens already. Replace `AppTheme.text*` / `AppTheme.surface*` / `AppTheme.primary*` with theme-aware equivalents per the mapping table.

---

### Sub-phase 5.E: TodosScreen

**Files:**
- Modify: `lib/features/todos/presentation/screens/todos_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 5.E.1: Apply standard migration

Scan for literal `BorderRadius` and `AppTheme.*` tokens. Replace per mapping table.

**Known instances:**
- Line ~80: `AppTheme.primaryBlue` → `cs.primary` (filter icon active color)
- Any `AppTheme.textTertiary` → `fg.textTertiary`

---

### Sub-phase 5.F: TrashScreen

**Files:**
- Modify: `lib/features/settings/presentation/screens/trash_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 5.F.1: Replace hardcoded fontSize violations

**Instances:**
- Line ~144: `TextStyle(fontSize: 18, color: AppTheme.textTertiary)` → `tt.titleMedium!.copyWith(color: fg.textTertiary)`
- Line ~150: `TextStyle(fontSize: 14, color: AppTheme.textTertiary)` → `tt.bodyMedium!.copyWith(color: fg.textTertiary)`
- Line ~176: `TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)` → `tt.titleSmall!.copyWith(color: cs.onSurfaceVariant)`
- Line ~207: `TextStyle(fontSize: 12)` → `tt.bodySmall`
- Line ~210: `TextStyle(fontSize: 12)` → `tt.bodySmall`
- Line ~215: `TextStyle(fontSize: 12, ...)` → `tt.bodySmall!.copyWith(color: cs.error, fontWeight: FontWeight.w600)`

#### Step 5.F.2: Replace hardcoded EdgeInsets

**Instances:**
- Line ~143: `SizedBox(height: 16)` → `SizedBox(height: AppTheme.space4)`
- Line ~148: `SizedBox(height: 8)` → `SizedBox(height: AppTheme.space2)`
- Line ~165: `SizedBox(height: 32)` → `SizedBox(height: AppTheme.space8)`
- Line ~173: `EdgeInsets.fromLTRB(16, 16, 16, 4)` → `EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space4, AppTheme.space4, AppTheme.space1)`

#### Step 5.F.3: Replace static color references

- All `AppTheme.statusError` → `cs.error`
- All `AppTheme.primaryCyan` → `cs.primary`
- All `AppTheme.textSecondary` → `cs.onSurfaceVariant`
- All `AppTheme.textTertiary` → `fg.textTertiary`

---

### Sub-phase 5.G: PersonnelTypesScreen

**Files:**
- Modify: `lib/features/settings/presentation/screens/personnel_types_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 5.G.1: Apply standard migration

Mostly clean file. Replace:
- Line ~64: `AppTheme.textTertiary` → `fg.textTertiary`
- Line ~69: `TextStyle(fontSize: 18, color: AppTheme.textSecondary)` → `tt.titleMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~75: `TextStyle(color: AppTheme.textTertiary)` → `tt.bodyMedium!.copyWith(color: fg.textTertiary)`
- Line ~67: `SizedBox(height: 16)` → `SizedBox(height: AppTheme.space4)`
- Line ~73: `SizedBox(height: 8)` → `SizedBox(height: AppTheme.space2)`

---

### Sub-phase 5.H: AdminDashboardScreen

**Files:**
- Modify: `lib/features/settings/presentation/screens/admin_dashboard_screen.dart`

**Agent:** `frontend-flutter-specialist-agent`

#### Step 5.H.1: Replace Colors.grey violations (6 instances)

**Instances:**
- Line ~63: `Colors.grey` (cloud_off icon) → `cs.onSurfaceVariant`
- Line ~71: `TextStyle(color: Colors.grey)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~131: `TextStyle(color: Colors.grey)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Line ~150: `TextStyle(color: Colors.grey)` → `tt.bodyMedium!.copyWith(color: cs.onSurfaceVariant)`
- Any remaining `Colors.grey` → `cs.onSurfaceVariant`

#### Step 5.H.2: Replace remaining static tokens

- `AppTheme.statusError` → `cs.error`
- Replace hardcoded `SizedBox(height: 16)` → `SizedBox(height: AppTheme.space4)` etc.
- Replace `EdgeInsets.symmetric(horizontal: 16, vertical: 24)` → `EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space6)`

---

### Sub-phase 5.I: Quality Gate

**Agent:** `qa-testing-agent`

#### Step 5.I.1: Static analysis

```powershell
pwsh -Command "flutter analyze"
```

Must pass with zero errors. Warnings acceptable if pre-existing.

#### Step 5.I.2: Run all tests

```powershell
pwsh -Command "flutter test"
```

Must pass. If any test fails due to hardcoded color assertions, update the test to use theme-aware lookups.

#### Step 5.I.3: Violation audit

Run a final grep across all modified files to confirm zero remaining violations:

```powershell
# Check for remaining static color tokens that should be theme-aware
pwsh -Command "Select-String -Path 'lib/features/dashboard/**/*.dart','lib/features/entries/**/*.dart','lib/features/projects/presentation/screens/project_list_screen.dart','lib/features/forms/presentation/screens/forms_list_screen.dart','lib/features/todos/presentation/screens/todos_screen.dart','lib/features/settings/presentation/screens/*.dart' -Pattern 'AppTheme\.(textPrimary|textSecondary|textTertiary|textInverse|surfaceElevated|surfaceHighlight|surfaceDark|primaryCyan|statusError|statusWarning|statusSuccess|primaryBlue|statusInfo|accentAmber)' -Recurse | Measure-Object"
```

Target: 0 matches (except in test files or intentionally static references like entry status colors / weather colors that remain static per design rules).

#### Step 5.I.4: Manual smoke test

Build and run on Android device:
```powershell
pwsh -File tools/build.ps1 -Platform android -BuildType debug -Driver
```

Verify:
1. Dashboard loads — stat cards, budget card, tracked items, approaching limit all render
2. Calendar screen loads — day cells colored, format toggle works, entry cards render
3. Entry editor loads — all sections render, inline editing works
4. Create new entry — repeat-last toggles visible, toggling persists
5. All list screens load without visual regressions
6. No white/invisible text on any screen
